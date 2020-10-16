/**
This module provides functions to ensure the library or client code is behaving.

Source: $(PHOBOSSRC libchess/_validate.d)

Copyright: Copyright Michael Weber Jr.
License:   $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors:   Michael Weber JR.
 */

module libchess.validate;

import libchess.defs;

/*int MoveListOk(const S_MOVELIST[] list,  S_BOARD pos) {
	if(list->length >= MAXPOSITIONMOVES) return false;

	int MoveNum;
	int from = 0;
	int to = 0;
	for(MoveNum = 0; MoveNum < list->count; ++MoveNum) {
		to = TOSQ(list->moves[MoveNum].move);
		from = FROMSQ(list->moves[MoveNum].move);
		if(!SqOnBoard(to) || !SqOnBoard(from)) {
			return FALSE;
		}
		if(!PieceValid(pos->pieces[from])) {
			PrintBoard(pos);
			return FALSE;
		}
	}

	return TRUE;
}*/

bool SqIs120(const int sq) @nogc nothrow pure
{
	return sq >= 0 && sq < 120;
}

bool PceValidEmptyOffbrd(const int pce) @nogc nothrow pure
{
	return PieceValidEmpty(pce) || pce == OFFBOARD;
}
bool SqOnBoard(const int sq) @nogc nothrow
{
	return FilesBrd[sq] != OFFBOARD;
}

bool SideValid(const int side) @nogc nothrow pure
{
	return side == WHITE || side == BLACK;
}

bool FileRankValid(const int fr) @nogc nothrow pure
{
	return fr >= 0 && fr <= 7;
}

int PieceValidEmpty(const int pce) @nogc nothrow pure
{
	return pce >= EMPTY && pce <= bK;
}

int PieceValid(const int pce) @nogc nothrow pure
{
	return pce >= wP && pce <= bK;
}

/*void DebugAnalysisTest(S_BOARD *pos, S_SEARCHINFO *info) {

	FILE *file;
    file = fopen("lct2.epd","r");
    char lineIn [1024];

	info->depth = MAXDEPTH;
	info->timeset = TRUE;
	int time = 1140000;


    if(file == NULL) {
        printf("File Not Found\n");
        return;
    }  else {
        while(fgets (lineIn , 1024 , file) != NULL) {
			info->starttime = GetTimeMs();
			info->stoptime = info->starttime + time;
			ClearHashTable(pos->HashTable);
            ParseFen(lineIn, pos);
            printf("\n%s\n",lineIn);
			printf("time:%d start:%d stop:%d depth:%d timeset:%d\n",
				time,info->starttime,info->stoptime,info->depth,info->timeset);
			SearchPosition(pos, info);
            memset(&lineIn[0], 0, sizeof(lineIn));
        }
    }
}



void MirrorEvalTest(S_BOARD *pos) {
    FILE *file;
    file = fopen("mirror.epd","r");
    char lineIn [1024];
    int ev1 = 0; int ev2 = 0;
    int positions = 0;
    if(file == NULL) {
        printf("File Not Found\n");
        return;
    }  else {
        while(fgets (lineIn , 1024 , file) != NULL) {
            ParseFen(lineIn, pos);
            positions++;
            ev1 = EvalPosition(pos);
            MirrorBoard(pos);
            ev2 = EvalPosition(pos);

            if(ev1 != ev2) {
                printf("\n\n\n");
                ParseFen(lineIn, pos);
                PrintBoard(pos);
                MirrorBoard(pos);
                PrintBoard(pos);
                printf("\n\nMirror Fail:\n%s\n",lineIn);
                getchar();
                return;
            }

            if( (positions % 1000) == 0)   {
                printf("position %d\n",positions);
            }

            memset(&lineIn[0], 0, sizeof(lineIn));
        }
    }
}*/
