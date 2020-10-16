/**
This module provides a basic non-blocking message protacal

Source: $(PHOBOSSRC aesir/_messagepool.d)

Copyright: Copyright Michael Weber Jr.
License:   $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors:   Michael Weber JR.
 */

module aesir.messagepool;

import std.concurrency;

private Tid poolTid;

private enum
{
    MSG_PEEK,
    MSG_GET,
    MSG_SEND,
    MSG_QUIT
}

class MessagePoolException : Exception
{
    this(string msg)
    {
        super(msg);
    }
}

// This function is called by createMessagePool() with a new thread that manages any messages
private void messagePoolLoop()
{
    struct Queue(U)
    {
        U[] data;

        this(U u) pure
        {
            data ~= u;
        }

        int length() @property @nogc pure nothrow
        {
            return data.length;
        }

        U front() @property @nogc pure nothrow
        {
            return data[0];
        }

        void popFront() pure nothrow
        {
            data = data[1..$];
        }

        bool empty() pure nothrow @property @nogc
        {
            return data.length == 0;
        }

        void pushBack(U u) pure
        {
            data ~= u;
        }
    }

    Queue!(int)[Tid] messages;
import std.stdio;
    while(true)
    {
        auto msg = receiveOnly!(int, Tid, int)();
        writeln("received message");
        final switch(msg[0])
        {
            MSG_PEEK:
                if(msg[1] in messages)
                    send(msg[1], messages[msg[1]].empty());
                else send(msg[1], false);
                break;
            MSG_GET:
                if(msg[1] in messages)
                {
                    if(messages[msg[1]].empty())
                        throw new MessagePoolException("Message queue is empty");
                    else
                    {
                        send(msg[1], messages[msg[1]].front);
                        messages[msg[1]].popFront();
                    }
                }
                else throw new MessagePoolException("Message queue is empty");
                break;
            MSG_SEND:
                if(msg[1] in messages)
                    messages[msg[1]].pushBack(msg[2]);
                else messages[msg[1]] = Queue!int(msg[2]);
                break;
            case MSG_QUIT: return;
        }
    }
}

void createMessagePool()
{
    poolTid = spawn(&messagePoolLoop);
}

bool peekMessage()
{
    send(poolTid, MSG_PEEK, thisTid, 0);
    return receiveOnly!bool();
}

int receiveMessage()
{
    send(poolTid, MSG_GET, thisTid, 0);
    return receiveOnly!int();
}

void sendMessage(Tid receiver, int value)
{
    send(poolTid, MSG_SEND, receiver, value);
}

void quitMessagePool()
{
    send(poolTid, MSG_QUIT, thisTid, 0);
}

private void spawner(void function() fn)
{
    poolTid = receiveOnly!Tid();
    fn();
}

Tid spawnPoolThread(void function() fn)
{
    Tid newThread = spawn(&spawner, fn);
    send(newThread, poolTid);
    return newThread;
}

version(unittest)
{
    import std.stdio;

    void test()
    {
        while(true)
        {
            writeln("here");
            if(peekMessage())
            {
                assert(receiveMessage() == 5);
                sendMessage(ownerTid, 22);
                break;
            }
        }
    }
}

unittest
{
    import core.thread;

    createMessagePool();
    writeln(poolTid);
    scope(exit) quitMessagePool();

    auto tid = spawnPoolThread(&test);
    //Thread.sleep(dur!("seconds")(1));
    sendMessage(tid, 5);
    while(true)
    {
        if(peekMessage())
        {
            assert(receiveMessage() == 22);
            break;
        }
    }
}
