/**
This module provides a faculty to perform perft testing.

Source: $(PHOBOSSRC libchess/_perft.d)

Copyright: Copyright Michael Weber Jr.
License:   $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors:   Michael Weber JR.
 */

module libchess.perft;

import std.stdio;
import std.range;
import std.conv;
import std.datetime.systime;
import std.datetime.stopwatch;
import std.algorithm;
import std.concurrency;
import core.memory;

import libchess.defs;
import libchess.board;
import libchess.move;

long leafNodes;

ulong perft(Move move, int depth, Board board) //@nogc
{
    ulong nodes;

    if(board.makeMove(move))
    {
        if(depth == 1) nodes = 1;
        else nodes = reduce!((a, b) => a + b.perft(depth-1, board))(0UL, board.generateAllMoves());
        board.takeMove();
    }

    /+MoveList list;
    board.generateAllMoves(list);

    int moveNum = 0;
	for(moveNum = 0; moveNum < list.count; ++moveNum)
    {
        if(!board.makeMove(list.moves[moveNum])) continue;
        nodes += perft(depth - 1, board);
        board.takeMove();
    }+/

    return nodes;
}

private void perftThread()
{
    auto msg = receiveOnly!(string, int, int)();
    Board newBoard = new Board(msg[0]);
    ulong result = reduce!((a, b) => a + b.perft(msg[1]-1, newBoard))(0UL, newBoard.generateAllMoves());
    send(ownerTid, msg[2], result);
}

void perftTest(string fileName, Board board, int max_depth = 6)
{
    int current_char;
    int pass = 0;
    int fail = 0;
    int i;
    int depth = max_depth;
    ulong requiredNodes;
    StopWatch sw;
    auto input = new File(fileName, "r");
    auto output = new File("perf_tests_results.txt", "w");

    writeln("Starting Perf Tests");
    output.writefln("Starting Perf Tests");

    auto totalTime = Clock.currTime();

    foreach(line; input.byLine())
    {
        board.parseFen(line.idup);

        writefln("\nTesting %d: %s", i+1, line);
        output.writefln("\nTesting %d: %s", i+1, line);
        i++;
        current_char = 0;

        while(true)
        {
            while(current_char < line.length)
            {
                if(line[current_char] == ';')
                {
                    depth = line[current_char + 2] - '0';
                    if(depth > max_depth)
                    {
                        current_char++;
                        break;
                    }

                    current_char += 4;
                    char[] number;
                    int digits = 0;
                    while(current_char < line.length && line[current_char] != ' ')
                        number ~= line[current_char++];
                    requiredNodes = to!ulong(number);
                    break;
                }
                current_char++;
            }

            sw.reset();
            sw.start();
            ulong leafNodes;

            GC.disable();
            foreach(move; board.generateAllMoves())
            {
                if(board.makeMove(move))
                {
                    if(depth == 1) leafNodes++;
                    else leafNodes += reduce!((a, b) => a + b.perft(depth-1, board))(0UL, board.generateAllMoves());
                    board.takeMove();
                }
            }
            GC.enable();

            if(leafNodes == requiredNodes) pass++;
            else fail++;

            sw.stop();

            writeln("\tDepth ", depth, " (", sw.peek().split!"msecs".msecs, " ms):", leafNodes, "\t", requiredNodes, "\t", leafNodes == requiredNodes ? "PASS" : "FAIL");
            output.writeln("\tDepth ", depth, " (", sw.peek().split!"msecs".msecs, " ms):", leafNodes, "\t", requiredNodes, "\t", leafNodes == requiredNodes ? "PASS" : "FAIL");

            if(depth >= max_depth) break;
        }
    }

    writefln("\n Perf Tests Complete\nPass:%d Fail: %d", pass, fail);
    output.writefln("\n Perf Tests Complete\nPass:%d Fail: %d", pass, fail);
    writeln("Time to complete: ", (Clock.currTime() - totalTime).split!"msecs".msecs, "ms");
}

void perftTestThreaded(string fileName, Board board, int max_depth = 6, int max_threads = -1)
{
    int current_char;
    int pass = 0;
    int fail = 0;
    int i;
    int depth = max_depth;
    ulong requiredNodes;
    StopWatch sw;
    auto input = new File(fileName, "r");
    auto output = new File("perf_tests_results.txt", "w");

    writeln("Starting Perf Tests");
    writeln("Max depth: ", max_depth);
    writeln("Number of threads: ", max_threads);
    output.writefln("Starting Perf Tests");

    auto totalTime = Clock.currTime();

    foreach(line; input.byLine())
    {
        board.parseFen(line.idup);

        writefln("\nTesting %d: %s", i+1, line);
        output.writefln("\nTesting %d: %s", i+1, line);
        i++;
        current_char = 0;

        while(true)
        {
            while(current_char < line.length)
            {
                if(line[current_char] == ';')
                {
                    depth = line[current_char + 2] - '0';
                    if(depth > max_depth)
                    {
                        current_char++;
                        break;
                    }

                    current_char += 4;
                    char[] number;
                    int digits = 0;
                    while(current_char < line.length && line[current_char] != ' ')
                        number ~= line[current_char++];
                    requiredNodes = to!ulong(number);
                    break;
                }
                current_char++;
            }

            sw.reset();
            sw.start();
            ulong leafNodes;
            //bool[] threads;
            //threads.length = board.generateAllMoves().length;
            auto moves = board.generateAllMoves();
            int threads_running;
            int threads_remaining = moves.length;

            GC.disable();
            int t;
            while(threads_remaining > 0)
            {
                int threads_to_take = (max_threads == -1 || threads_remaining < max_threads) ? threads_remaining : max_threads;
                threads_remaining -= threads_to_take;
                threads_running = threads_to_take;
                auto movesRunning = moves.take(threads_to_take);
                foreach(dontGiveAFuck; 0..threads_to_take) moves.popFront();

                foreach(move; movesRunning)
                {
                    if(board.makeMove(move))
                    {
                        if(depth == 1) leafNodes++;
                        else
                        {
                            auto tid = spawn(&perftThread);
                            send(tid, board.generateFen(), depth, t++);
                        }
                        board.takeMove();
                    }
                    else threads_running--;
                }

                while(true && depth > 1)
                {
                    auto msg = receiveOnly!(int, ulong)();
                    leafNodes += msg[1];
                    if(--threads_running == 0) break;
                }
            }
            GC.enable();

            if(leafNodes == requiredNodes) pass++;
            else fail++;

            sw.stop();

            writeln("\tDepth ", depth, " (", sw.peek().split!"msecs".msecs, " ms):", leafNodes, "\t", requiredNodes, "\t", leafNodes == requiredNodes ? "PASS" : "FAIL");
            output.writeln("\tDepth ", depth, " (", sw.peek().split!"msecs".msecs, " ms):", leafNodes, "\t", requiredNodes, "\t", leafNodes == requiredNodes ? "PASS" : "FAIL");

            if(depth >= max_depth) break;
        }
    }

    writefln("\n Perf Tests Complete\nPass:%d Fail: %d", pass, fail);
    output.writefln("\n Perf Tests Complete\nPass:%d Fail: %d", pass, fail);
    writeln("Time to complete: ", (Clock.currTime() - totalTime).split!"msecs".msecs, "ms");
}
