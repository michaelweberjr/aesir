/**
BitBoard structure to manipulate a 64 bit chess board.

Source: $(PHOBOSSRC libchess/_bitboard.d)

Copyright: Copyright <ichael Weber Jr.
License:   $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors:   Michael Weber JR.
 */

module libchess.bitboard;

import libchess.defs;

alias ulong BitBoard;

static private int[64] BitTable = [
    63, 30, 3, 32, 25, 41, 22, 33, 15, 50, 42, 13, 11, 53, 19, 34, 61, 29, 2,
    51, 21, 43, 45, 10, 18, 47, 1, 54, 9, 57, 0, 35, 62, 31, 40, 4, 49, 5, 52,
    26, 60, 6, 23, 44, 46, 27, 56, 16, 7, 39, 48, 24, 59, 14, 12, 55, 38, 28,
    58, 20, 37, 17, 36, 8
];

int pop(ref BitBoard bb) @nogc nothrow
{
    ulong b = bb ^ (bb - 1);
    uint fold = cast(uint)((b & 0xffffffff) ^ (b >> 32));
    bb &= (bb - 1);
    return BitTable[(fold * 0x783a9b23) >> 26];
}

int count(BitBoard bb) @nogc nothrow pure
{
    ulong c = bb;
    int r;
    for(r = 0; c; r++) c &= c - 1;

    return r;
}

string toString(BitBoard bb)
{
    ulong shiftMe = 1UL;

    int rank = 0;
    int file = 0;
    int sq = 0;
    int sq64 = 0;
    string board;

    for(rank = RANK_8; rank >= RANK_1; --rank) {
        for(file = FILE_A; file <= FILE_H; ++file) {
            sq = FR2SQ(file,rank);	// 120 based
            sq64 = SQ64(sq); // 64 based

            if((shiftMe << sq64) & bb)
                board ~= "X";
            else
                board ~= "-";
        }
        board ~= "\n";
    }

    return board;
}

void clear(ref BitBoard bb, int sq) @nogc nothrow
{
    bb &= ClearMask[sq];
}

void set(ref BitBoard bb, int sq) @nogc nothrow
{
    bb |= SetMask[sq];
}

private
{
    static ulong[64] SetMask;
    static ulong[64] ClearMask;

    static this()
    {
        for(int i = 0; i < 64; i++)
        {
            SetMask[i] = 0UL;
            ClearMask[i] = 0UL;
        }

        for(int i = 0; i < 64; i++)
        {
            SetMask[i] |= (1UL << i);
            ClearMask[i] = ~SetMask[i];
        }
    }
}
