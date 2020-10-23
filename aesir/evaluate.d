module aesir.evaluate;

import std.algorithm;

import libchess.defs;
import libchess.board;
import libchess.move;
import libchess.piece;
import libchess.bitboard;
import libchess.validate;

import aesir.position;

enum int INFINITE = 30000;
enum int ISMATE = (INFINITE - MAXDEPTH);

enum int[13] PieceVal = [ 0, 100, 325, 325, 550, 1000, 50000, 100, 325, 325, 550, 1000, 50000 ];
private enum int PawnIsolated = -10;
private enum int[8] PawnPassed = [ 0, 5, 10, 20, 35, 60, 100, 200 ];
private enum int RookOpenFile = 10;
private enum int RookSemiOpenFile = 5;
private enum int QueenOpenFile = 5;
private enum int QueenSemiOpenFile = 3;
private enum int BishopPair = 30;

private enum int[64] PawnTable = [
    0	,	0	,	0	,	0	,	0	,	0	,	0	,	0	,
    10	,	10	,	0	,	-10	,	-10	,	0	,	10	,	10	,
    5	,	0	,	0	,	5	,	5	,	0	,	0	,	5	,
    0	,	0	,	10	,	20	,	20	,	10	,	0	,	0	,
    5	,	5	,	5	,	10	,	10	,	5	,	5	,	5	,
    10	,	10	,	10	,	20	,	20	,	10	,	10	,	10	,
    20	,	20	,	20	,	30	,	30	,	20	,	20	,	20	,
    0	,	0	,	0	,	0	,	0	,	0	,	0	,	0
];

private enum int[64] KnightTable = [
    0	,	-10	,	0	,	0	,	0	,	0	,	-10	,	0	,
    0	,	0	,	0	,	5	,	5	,	0	,	0	,	0	,
    0	,	0	,	10	,	10	,	10	,	10	,	0	,	0	,
    0	,	0	,	10	,	20	,	20	,	10	,	5	,	0	,
    5	,	10	,	15	,	20	,	20	,	15	,	10	,	5	,
    5	,	10	,	10	,	20	,	20	,	10	,	10	,	5	,
    0	,	0	,	5	,	10	,	10	,	5	,	0	,	0	,
    0	,	0	,	0	,	0	,	0	,	0	,	0	,	0
];

private enum int[64] BishopTable = [
    0	,	0	,	-10	,	0	,	0	,	-10	,	0	,	0	,
    0	,	0	,	0	,	10	,	10	,	0	,	0	,	0	,
    0	,	0	,	10	,	15	,	15	,	10	,	0	,	0	,
    0	,	10	,	15	,	20	,	20	,	15	,	10	,	0	,
    0	,	10	,	15	,	20	,	20	,	15	,	10	,	0	,
    0	,	0	,	10	,	15	,	15	,	10	,	0	,	0	,
    0	,	0	,	0	,	10	,	10	,	0	,	0	,	0	,
    0	,	0	,	0	,	0	,	0	,	0	,	0	,	0
];

private enum int[64] RookTable = [
    0	,	0	,	5	,	10	,	10	,	5	,	0	,	0	,
    0	,	0	,	5	,	10	,	10	,	5	,	0	,	0	,
    0	,	0	,	5	,	10	,	10	,	5	,	0	,	0	,
    0	,	0	,	5	,	10	,	10	,	5	,	0	,	0	,
    0	,	0	,	5	,	10	,	10	,	5	,	0	,	0	,
    0	,	0	,	5	,	10	,	10	,	5	,	0	,	0	,
    25	,	25	,	25	,	25	,	25	,	25	,	25	,	25	,
    0	,	0	,	5	,	10	,	10	,	5	,	0	,	0
];

private enum int[64] KingE = [
	-50	,	-10	,	0	,	0	,	0	,	0	,	-10	,	-50	,
	-10,	0	,	10	,	10	,	10	,	10	,	0	,	-10	,
	0	,	10	,	20	,	20	,	20	,	20	,	10	,	0	,
	0	,	10	,	20	,	40	,	40	,	20	,	10	,	0	,
	0	,	10	,	20	,	40	,	40	,	20	,	10	,	0	,
	0	,	10	,	20	,	20	,	20	,	20	,	10	,	0	,
	-10,	0	,	10	,	10	,	10	,	10	,	0	,	-10	,
	-50	,	-10	,	0	,	0	,	0	,	0	,	-10	,	-50
];

private enum int[64] KingO = [
	0	,	5	,	5	,	-10	,	-10	,	0	,	10	,	5	,
	-30	,	-30	,	-30	,	-30	,	-30	,	-30	,	-30	,	-30	,
	-50	,	-50	,	-50	,	-50	,	-50	,	-50	,	-50	,	-50	,
	-70	,	-70	,	-70	,	-70	,	-70	,	-70	,	-70	,	-70	,
	-70	,	-70	,	-70	,	-70	,	-70	,	-70	,	-70	,	-70	,
	-70	,	-70	,	-70	,	-70	,	-70	,	-70	,	-70	,	-70	,
	-70	,	-70	,	-70	,	-70	,	-70	,	-70	,	-70	,	-70	,
	-70	,	-70	,	-70	,	-70	,	-70	,	-70	,	-70	,	-70
];

private enum int[64] Mirror64 = [
    56	,	57	,	58	,	59	,	60	,	61	,	62	,	63	,
    48	,	49	,	50	,	51	,	52	,	53	,	54	,	55	,
    40	,	41	,	42	,	43	,	44	,	45	,	46	,	47	,
    32	,	33	,	34	,	35	,	36	,	37	,	38	,	39	,
    24	,	25	,	26	,	27	,	28	,	29	,	30	,	31	,
    16	,	17	,	18	,	19	,	20	,	21	,	22	,	23	,
    8	,	9	,	10	,	11	,	12	,	13	,	14	,	15	,
    0	,	1	,	2	,	3	,	4	,	5	,	6	,	7
];

private BitBoard[8] FileBBMask;
private BitBoard[8] RankBBMask;

private BitBoard[64] BlackPassedMask;
private BitBoard[64] WhitePassedMask;
private BitBoard[64] IsolatedMask;

static this()
{
    int sq, tsq, r, f;

	for(sq = 0; sq < 64; ++sq)
    {
		tsq = sq + 8;

        while(tsq < 64)
        {
            WhitePassedMask[sq] |= (1UL << tsq);
            tsq += 8;
        }

        tsq = sq - 8;
        while(tsq >= 0)
        {
            BlackPassedMask[sq] |= (1UL << tsq);
            tsq -= 8;
        }

        if(FilesBrd[SQ120(sq)] > FILE_A)
        {
            IsolatedMask[sq] |= FileBBMask[FilesBrd[SQ120(sq)] - 1];

            tsq = sq + 7;
            while(tsq < 64)
            {
                WhitePassedMask[sq] |= (1UL << tsq);
                tsq += 8;
            }

            tsq = sq - 9;
            while(tsq >= 0)
            {
                BlackPassedMask[sq] |= (1UL << tsq);
                tsq -= 8;
            }
        }

        if(FilesBrd[SQ120(sq)] < FILE_H)
        {
            IsolatedMask[sq] |= FileBBMask[FilesBrd[SQ120(sq)] + 1];

            tsq = sq + 9;
            while(tsq < 64)
            {
                WhitePassedMask[sq] |= (1UL << tsq);
                tsq += 8;
            }

            tsq = sq - 7;
            while(tsq >= 0)
            {
                BlackPassedMask[sq] |= (1UL << tsq);
                tsq -= 8;
            }
        }
	}
}

private int abs(int x)
{
    return x < 0 ? -x : x;
}

// sjeng 11.2
int materialDraw(Board pos)
{
    if(!pos.pceNum[wR] && !pos.pceNum[bR] && !pos.pceNum[wQ] && !pos.pceNum[bQ])
    {
        if(!pos.pceNum[bB] && !pos.pceNum[wB])
        {
            if(pos.pceNum[wN] < 3 && pos.pceNum[bN] < 3) return true;
        }
        else if (!pos.pceNum[wN] && !pos.pceNum[bN])
        {
            if (abs(pos.pceNum[wB] - pos.pceNum[bB]) < 2) return true;
        }
        else if ((pos.pceNum[wN] < 3 && !pos.pceNum[wB]) || (pos.pceNum[wB] == 1 && !pos.pceNum[wN]))
        {
            if ((pos.pceNum[bN] < 3 && !pos.pceNum[bB]) || (pos.pceNum[bB] == 1 && !pos.pceNum[bN]))  return true;
        }
	}
	else if (!pos.pceNum[wQ] && !pos.pceNum[bQ])
    {
        if (pos.pceNum[wR] == 1 && pos.pceNum[bR] == 1)
        {
            if ((pos.pceNum[wN] + pos.pceNum[wB]) < 2 && (pos.pceNum[bN] + pos.pceNum[bB]) < 2)	return true;
        }
        else if (pos.pceNum[wR] == 1 && !pos.pceNum[bR])
        {
            if ((pos.pceNum[wN] + pos.pceNum[wB] == 0) && (((pos.pceNum[bN] + pos.pceNum[bB]) == 1) || ((pos.pceNum[bN] + pos.pceNum[bB]) == 2))) return true;
        }
        else if (pos.pceNum[bR] == 1 && !pos.pceNum[wR])
        {
            if ((pos.pceNum[bN] + pos.pceNum[bB] == 0) && (((pos.pceNum[wN] + pos.pceNum[wB]) == 1) || ((pos.pceNum[wN] + pos.pceNum[wB]) == 2))) return true;
        }
    }

    return false;
}

private enum int ENDGAME_MAT  = (1 * PieceVal[wR] + 2 * PieceVal[wN] + 2 * PieceVal[wP] + PieceVal[wK]);

private enum int[13] VictimScore = [ 0, 100, 200, 300, 400, 500, 600, 100, 200, 300, 400, 500, 600 ];
private int[13][13] MvvLvaScores;

static this()
{
    int Attacker;
    int Victim;
    for(Attacker = wP; Attacker <= bK; ++Attacker) {
        for(Victim = wP; Victim <= bK; ++Victim) {
            MvvLvaScores[Victim][Attacker] = VictimScore[Victim] + 6 - ( VictimScore[Attacker] / 100);
        }
    }
}

auto assignBasicEval(R)(R range, Position pos)
{
    struct MoveListScore
    {
        private
        {
            EvalMove[MAXGAMEMOVES] list;

            int count;
            int frontIndex;
        }

        void addMove(Move m, int s) pure nothrow @nogc
        {
            list[count].move = m;
            list[count++].score = s;
        }

        bool empty() pure nothrow @nogc @property
        {
            return frontIndex == count;
        }

        EvalMove front() pure nothrow @nogc @property
        {
            return list[frontIndex];
        }

        void popFront() pure nothrow @nogc
        {
            if(frontIndex < count) frontIndex++;
        }

        int length() pure nothrow @nogc @property
        {
            return count;
        }

        EvalMove opIndex(int i) pure @nogc
        {
            assert(i < 0 || i >= count);
            return list[i];
        }
    }

    MoveListScore list;

    foreach(move; range)
    {
        if(pos.makeMove(move))
        {
            if(move.flag(MFLAGCAP))
            {
                list.addMove(move, MvvLvaScores[move.captured()][pos.pieces[move.fromsq()].type()]);
            }
            if(move.flag(MFLAGEP))
            {
                list.addMove(move, 105 + 1000000);
            }
            else
            {
                if(pos.searchKillers[0][pos.ply] == move)
                    list.addMove(move, 900000);
                else if(pos.searchKillers[1][pos.ply] == move)
                    list.addMove(move, 800000);
                else
                    list.addMove(move, pos.searchHistory[pos.pieces[move.fromsq()].type()][move.tosq()]);
            }
            pos.takeMove();
        }
    }

    foreach(i; 0..list.length-1)
    {
        if(list.list[i].score < list.list[i+1].score)
        {
            auto t = list.list[i];
            list.list[i] = list.list[i+1];
            list.list[i+1] = t;
        }
        if(i > 0 && list.list[i].score > list.list[i-1].score)
        {
            auto t = list.list[i];
            list.list[i] = list.list[i-1];
            list.list[i-1] = t;
        }
    }

    return list;
}


int evalPosition(Position pos)
{
	int pce;
	int pceNum;
	int sq;
	int score = pos.material[WHITE] - pos.material[BLACK];

	if(!pos.pceNum[wP] && !pos.pceNum[bP] && materialDraw(pos)) return 0;

	pce = wP;
	for(pceNum = 0; pceNum < pos.pceNum[pce]; ++pceNum)
    {
		sq = pos.pList[pce][pceNum].sq();
		assert(SqOnBoard(sq));
		assert(SQ64(sq) >= 0 && SQ64(sq) <= 63);
		score += PawnTable[SQ64(sq)];

		if((IsolatedMask[SQ64(sq)] & pos.pawns[WHITE]) == 0) score += PawnIsolated;

		if((WhitePassedMask[SQ64(sq)] & pos.pawns[BLACK]) == 0) score += PawnPassed[RanksBrd[sq]];
	}

	pce = bP;
	for(pceNum = 0; pceNum < pos.pceNum[pce]; ++pceNum)
    {
		sq = pos.pList[pce][pceNum].sq();
		assert(SqOnBoard(sq));
		assert(Mirror64[SQ64(sq)] >= 0 && Mirror64[SQ64(sq)] <= 63);
		score -= PawnTable[Mirror64[SQ64(sq)]];

		if((IsolatedMask[SQ64(sq)] & pos.pawns[BLACK]) == 0) score -= PawnIsolated;

		if((BlackPassedMask[SQ64(sq)] & pos.pawns[WHITE]) == 0) score -= PawnPassed[7 - RanksBrd[sq]];
	}

	pce = wN;
	for(pceNum = 0; pceNum < pos.pceNum[pce]; ++pceNum)
    {
		sq = pos.pList[pce][pceNum].sq();
		assert(SqOnBoard(sq));
		assert(SQ64(sq)>=0 && SQ64(sq)<=63);
		score += KnightTable[SQ64(sq)];
	}

	pce = bN;
	for(pceNum = 0; pceNum < pos.pceNum[pce]; ++pceNum)
    {
		sq = pos.pList[pce][pceNum].sq();
		assert(SqOnBoard(sq));
		assert(Mirror64[SQ64(sq)]>=0 && Mirror64[SQ64(sq)]<=63);
		score -= KnightTable[Mirror64[SQ64(sq)]];
	}

	pce = wB;
	for(pceNum = 0; pceNum < pos.pceNum[pce]; ++pceNum)
    {
		sq = pos.pList[pce][pceNum].sq();
		assert(SqOnBoard(sq));
		assert(SQ64(sq)>=0 && SQ64(sq)<=63);
		score += BishopTable[SQ64(sq)];
	}

	pce = bB;
	for(pceNum = 0; pceNum < pos.pceNum[pce]; ++pceNum)
    {
		sq = pos.pList[pce][pceNum].sq();
		assert(SqOnBoard(sq));
		assert(Mirror64[SQ64(sq)]>=0 && Mirror64[SQ64(sq)]<=63);
		score -= BishopTable[Mirror64[SQ64(sq)]];
	}

	pce = wR;
	for(pceNum = 0; pceNum < pos.pceNum[pce]; ++pceNum) {
		sq = pos.pList[pce][pceNum].sq();
		assert(SqOnBoard(sq));
		assert(SQ64(sq)>=0 && SQ64(sq)<=63);
		score += RookTable[SQ64(sq)];

		assert(FileRankValid(FilesBrd[sq]));

		if(!(pos.pawns[BOTH] & FileBBMask[FilesBrd[sq]])) score += RookOpenFile;
		else if(!(pos.pawns[WHITE] & FileBBMask[FilesBrd[sq]])) score += RookSemiOpenFile;
	}

	pce = bR;
	for(pceNum = 0; pceNum < pos.pceNum[pce]; ++pceNum) {
		sq = pos.pList[pce][pceNum].sq();
		assert(SqOnBoard(sq));
		assert(Mirror64[SQ64(sq)]>=0 && Mirror64[SQ64(sq)]<=63);
		score -= RookTable[Mirror64[SQ64(sq)]];

		assert(FileRankValid(FilesBrd[sq]));

		if(!(pos.pawns[BOTH] & FileBBMask[FilesBrd[sq]])) score -= RookOpenFile;
		else if(!(pos.pawns[BLACK] & FileBBMask[FilesBrd[sq]])) score -= RookSemiOpenFile;
	}

	pce = wQ;
	for(pceNum = 0; pceNum < pos.pceNum[pce]; ++pceNum) {
		sq = pos.pList[pce][pceNum].sq();
		assert(SqOnBoard(sq));
		assert(SQ64(sq)>=0 && SQ64(sq)<=63);
		assert(FileRankValid(FilesBrd[sq]));
		if(!(pos.pawns[BOTH] & FileBBMask[FilesBrd[sq]])) score += QueenOpenFile;
		else if(!(pos.pawns[WHITE] & FileBBMask[FilesBrd[sq]])) score += QueenSemiOpenFile;
	}

	pce = bQ;
	for(pceNum = 0; pceNum < pos.pceNum[pce]; ++pceNum) {
		sq = pos.pList[pce][pceNum].sq();
		assert(SqOnBoard(sq));
		assert(SQ64(sq)>=0 && SQ64(sq)<=63);
		assert(FileRankValid(FilesBrd[sq]));
		if(!(pos.pawns[BOTH] & FileBBMask[FilesBrd[sq]])) score -= QueenOpenFile;
		else if(!(pos.pawns[BLACK] & FileBBMask[FilesBrd[sq]])) score -= QueenSemiOpenFile;
	}

	pce = wK;
	sq = pos.pList[pce][0].sq();
	assert(SqOnBoard(sq));
	assert(SQ64(sq)>=0 && SQ64(sq)<=63);

	if((pos.material[BLACK] <= ENDGAME_MAT)) score += KingE[SQ64(sq)];
	else score += KingO[SQ64(sq)];

	pce = bK;
	sq = pos.pList[pce][0].sq();
	assert(SqOnBoard(sq));
	assert(Mirror64[SQ64(sq)]>=0 && Mirror64[SQ64(sq)]<=63);

	if((pos.material[WHITE] <= ENDGAME_MAT)) score -= KingE[Mirror64[SQ64(sq)]];
	else score -= KingO[Mirror64[SQ64(sq)]];

	if(pos.pceNum[wB] >= 2) score += BishopPair;
	if(pos.pceNum[bB] >= 2) score -= BishopPair;

	if(pos.side == WHITE) return score;
	else return -score;
}

struct EvalMove
{
    Move move;
    int score;
}
