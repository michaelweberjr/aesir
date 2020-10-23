module aesir.aesir;

import std.conv;
import std.stdio;

import libchess.perft;

import aesir.position;

enum string NAME = "Aesir";
enum string VERSION = "0.1";

int main(string[] args)
{
    Position pos = new Position();

    CmdLineArgs cla;
    try
    {
        if(args.length > 1) parseCmdLine(cla, args[1..$]);
    }
    catch(Exception e)
    {
        writeln(e.msg);
        return 1;
    }

    if(cla.help)
    {
        showHelp();
        return 0;
    }
    else if(cla.perft)
    {
        perftTest(cla.perftFile, pos);
        return 0;
    }
    else if(cla.perftThreaded)
    {
        perftTestThreaded(cla.perftFile, pos, 6, cla.threadCount);
        return 0;
    }

    return 0;
}

void showHelp()
{
    writeln("Aesir Chess Enginer v", VERSION, " by Michael Weber");
    writeln("Command Line Arguments:");
    writeln("\t-help or -h\tPrints this message.");
    writeln("\t-book <file>\tSets the opening book to <file>.");
    writeln("\t-fen <string>\tStarts the engine in console mode at the position given by <string>.");
    writeln("\t-perft <file>\tRuns a perft test on the given <file>.");
    writeln("\t-perft-threaded <file>\tSame as -perft but uses multi-threading.");
    writeln("\t-threads <count>\tThe maximum number of threads the engine will create.");
}

void parseCmdLine(ref CmdLineArgs cla, string[] args)
{
    switch(args[0])
    {
        case "-book":
            if(args.length <2)
                throw new Exception("Book file name not included");
            cla.bookFile = args[1];
            break;
        case "-fen":
            if(args.length <2)
                throw new Exception("FEN string not included");
            cla.fen = true;
            cla.fenString = args[1];
            break;
        case "-perft":
            if(args.length <2)
                throw new Exception("perft file name not included");
            cla.perft = true;
            cla.perftFile = args[1];
            break;
        case "-perft-threaded":
            if(args.length <2)
                throw new Exception("perft file name not included");
            cla.perftThreaded = true;
            cla.perftFile = args[1];
            break;
        case "-threads":
            if(args.length <2)
                throw new Exception("Thread count not included");
            cla.threadCount = args[1].to!int();
            break;
        case "-help":
            cla.help = true;
            args = args[1..$];
            if(args.length > 0) parseCmdLine(cla, args);
            return;
        case "-h":
            goto case "-help";
        default:
            throw new Exception("Unknown command line argument: " ~ args[0]);
    }
    args = args[2..$];
    if(args.length > 0) parseCmdLine(cla, args);
    return;
}

struct CmdLineArgs
{
    bool perft;
    string perftFile;
    bool perftThreaded;
    string bookFile = "openingbook.bin";
    bool fen;
    string fenString;
    int threadCount = -1;
    bool help;
}
