module aesir.console;

import std.stdio;

import aesir.io;
import aesir.search;
import aesir.position;

final class Console : IO
{
    override void Console_Loop(Possition pos)
    {
        //printf("Welcome to Vice In Console Mode!\n");
        //printf("Type help for commands\n\n");

        info->GAME_MODE = CONSOLEMODE;
        info->POST_THINKING = TRUE;
        setbuf(stdin, NULL);
        setbuf(stdout, NULL);

        int depth = MAXDEPTH, movetime = 3000;
        int engineSide = BOTH;
        int move = NOMOVE;
        char inBuf[80], command[80];

        engineSide = BLACK;
        ParseFen(START_FEN, pos);

        while(TRUE) {

            fflush(stdout);

            if(pos->side == engineSide && checkresult(pos) == FALSE) {
                info->starttime = GetTimeMs();
                info->depth = depth;

                if(movetime != 0) {
                    info->timeset = TRUE;
                    info->stoptime = info->starttime + movetime;
                }

                SearchPosition(pos, info);
            }

            printf("\nVice > ");

            fflush(stdout);

            memset(&inBuf[0], 0, sizeof(inBuf));
            fflush(stdout);
            if (!fgets(inBuf, 80, stdin))
            continue;

            sscanf(inBuf, "%s", command);

            if(!strcmp(command, "help")) {
                printf("Commands:\n");
                printf("quit - quit game\n");
                printf("force - computer will not think\n");
                printf("print - show board\n");
                printf("post - show thinking\n");
                printf("nopost - do not show thinking\n");
                printf("new - start new game\n");
                printf("go - set computer thinking\n");
                printf("depth x - set depth to x\n");
                printf("time x - set thinking time to x seconds (depth still applies if set)\n");
                printf("view - show current depth and movetime settings\n");
                printf("setboard x - set position to fen x\n");
                printf("** note ** - to reset time and depth, set to 0\n");
                printf("enter moves using b7b8q notation\n\n\n");
                continue;
            }

            if(!strcmp(command, "mirror")) {
                engineSide = BOTH;
                MirrorEvalTest(pos);
                continue;
            }

            if(!strcmp(command, "eval")) {
                PrintBoard(pos);
                printf("Eval:%d",EvalPosition(pos));
                MirrorBoard(pos);
                PrintBoard(pos);
                printf("Eval:%d",EvalPosition(pos));
                continue;
            }

            if(!strcmp(command, "setboard")){
                engineSide = BOTH;
                ParseFen(inBuf+9, pos);
                continue;
            }

            if(!strcmp(command, "quit")) {
                info->quit = TRUE;
                break;
            }

            if(!strcmp(command, "post")) {
                info->POST_THINKING = TRUE;
                continue;
            }

            if(!strcmp(command, "print")) {
                PrintBoard(pos);
                continue;
            }

            if(!strcmp(command, "nopost")) {
                info->POST_THINKING = FALSE;
                continue;
            }

            if(!strcmp(command, "force")) {
                engineSide = BOTH;
                continue;
            }

            if(!strcmp(command, "view")) {
                if(depth == MAXDEPTH) printf("depth not set ");
                else printf("depth %d",depth);

                if(movetime != 0) printf(" movetime %ds\n",movetime/1000);
                else printf(" movetime not set\n");

                continue;
            }

            if(!strcmp(command, "depth")) {
                sscanf(inBuf, "depth %d", &depth);
                if(depth==0) depth = MAXDEPTH;
                continue;
            }

            if(!strcmp(command, "time")) {
                sscanf(inBuf, "time %d", &movetime);
                movetime *= 1000;
                continue;
            }

            if(!strcmp(command, "new")) {
                ClearHashTable(pos->HashTable);
                engineSide = BLACK;
                ParseFen(START_FEN, pos);
                continue;
            }

            if(!strcmp(command, "go")) {
                engineSide = pos->side;
                continue;
            }

            if(!strcmp(command, "option book=true"))
            {
                EngineOpetions->useBook = TRUE;
                continue;
            }

            if(!strcmp(command, "option book=false"))
            {
                EngineOpetions->useBook = FALSE;
                continue;
            }

            if(!strcmp(command, "option book"))
            {
                printf("book=%s\n", EngineOpetions->useBook ? "true" : "false");
                continue;
            }

            move = ParseMove(inBuf, pos);
            if(move == NOMOVE) {
                printf("Command unknown:%s\n",inBuf);
                continue;
            }
            MakeMove(pos, move);
            pos->ply=0;
        }
    }

    override void postMove(Move move);
    override void postThinking(int bestScore, int currentDepth, Position pos);
}
