module aesir.position;

import libchess.board;
import libchess.move;
import libchess.defs;

import aesir.evaluate;

final class Position : Board
{
    //Hashtable hTable[1];
	Move[MaxDepth] pvArray;

	Move[BRD_SQ_NUM][13] searchHistory;
	Move[MaxDepth][2] searchKillers;

	int[2] material;

	SearchInfo info;

	this(string fen = "")
	{
	    super(fen);
	}

	override bool makeMove(Move move)
	{
	    if(super.makeMove(move))
        {
            if(move.flag(MFLAGCAP))
            {
                material[side^1] -= PieceVal[move.captured()];
            }
            if(move.flag(MFLAGPROM))
            {
                material[side] -= PieceVal[wP];
                material[side] += PieceVal[move.promoted()];
            }
            if(move.flag(MFLAGEP))
            {
                material[side^1] -= PieceVal[wP];
            }

            return true;
        }
        else return false;
	}

	override void takeMove()
	{
	    auto move = history[hisPly-1].move;

	    if(move.flag(MFLAGCAP))
        {
            material[side] += PieceVal[move.captured()];
        }
        if(move.flag(MFLAGPROM))
        {
            material[side^1] += PieceVal[wP];
            material[side^1] -= PieceVal[move.promoted()];
        }
        if(move.flag(MFLAGEP))
        {
            material[side] += PieceVal[wP];
        }

        super.takeMove();
	}

	override void parseFen(string fen)
	{
	    material[WHITE] = 0;
	    material[BLACK] = 0;

	    super.parseFen(fen);

	    foreach(i; 0..BRD_SQ_NUM)
            if(pieces[i] !is null)
                material[pieces[i].color()] += PieceVal[pieces[i].type()];
	}
}

struct SearchInfo
{
	int startTime;
	int stopTime;
	int depth;
	bool timeSet;
	int movesToGo;

	ulong nodes;

	bool quit;
	bool stop;

	float fh;
	float fhf;
	int nullCut;

    bool useBook;
}
