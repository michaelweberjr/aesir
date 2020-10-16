/**
Each board position can identified using a hash value which is calculated using $(D generatePosKey).

Source: $(PHOBOSSRC libchess/_hash.d)

Copyright: Copyright Michael Weber Jr.
License:   $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors:   Michael Weber JR.
 */

module libchess.hash;

import std.random;
import libchess.defs;
import libchess.board;
import libchess.piece;
import libchess.validate;

private
{
    ulong[120][13] PieceKeys;
    ulong SideKey;
    ulong[16] CastleKeys;
}

static this()
{
    auto rng = Random();
    ulong gen()
    {
        ulong next = rng.front();
        next <<= 31;
        rng.popFront();
        next |= rng.front();
        return next;
    }

	for(int i = 0; i < 13; i++)
		for(int j = 0; j < 120; j++)
			PieceKeys[i][j] = gen();

	SideKey = gen();

	for(int i = 0; i < 16; i++)
		CastleKeys[i] = gen();
}

ulong generatePosKey(const Board pos) @nogc
{
	ulong finalKey = 0;

	// pieces
	for(int sq = 0; sq < BRD_SQ_NUM; sq++) {
		auto piece = pos.pieces[sq];
		if(piece !is null)
			finalKey ^= PieceKeys[piece.type()][sq];
	}

	if(pos.side == WHITE)
		finalKey ^= SideKey;

	if(pos.enPas != NO_SQ)
    {
		assert(pos.enPas >= 0 && pos.enPas < BRD_SQ_NUM);
		assert(SqOnBoard(pos.enPas));
		assert(RanksBrd[pos.enPas] == RANK_3 || RanksBrd[pos.enPas] == RANK_6);
		finalKey ^= PieceKeys[EMPTY][pos.enPas];
	}

	assert(pos.castlePerm >= 0 && pos.castlePerm <= 15);

	finalKey ^= CastleKeys[pos.castlePerm];

	return finalKey;
}

ulong hashPiece(Piece pce, int sq) @nogc nothrow
{
    return PieceKeys[pce.type()][sq];
}

ulong hashCastle(ubyte castlePerm) @nogc nothrow
{
    return CastleKeys[castlePerm];
}

ulong hashSide() @nogc nothrow
{
    return SideKey;
}

ulong hashEP(int sq) @nogc nothrow
{
    return PieceKeys[EMPTY][sq];
}
