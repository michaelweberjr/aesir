module libchess.move;

/**
The chess move structure defines how a move is represented by the library.

Source: $(PHOBOSSRC libchess/_board.d)

Copyright: Copyright Michael Weber Jr.
License:   $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors:   Michael Weber JR.
 */

import libchess.defs;

/++
    This is how a move is stored:
    0000 0000 0000 0000 0000 0111 1111 -> From 0x7F
    0000 0000 0000 0011 1111 1000 0000 -> To >> 7, 0x7F
    0000 0000 0011 1100 0000 0000 0000 -> Captured >> 14, 0xF
    0000 0000 0100 0000 0000 0000 0000 -> EP 0x40000
    0000 0000 1000 0000 0000 0000 0000 -> Pawn Start 0x80000
    0000 1111 0000 0000 0000 0000 0000 -> Promoted Piece >> 20, 0xF
    0001 0000 0000 0000 0000 0000 0000 -> Castle 0x1000000
+/

alias uint Move;

Move constructMove(uint from, uint to, uint captured, uint promotion, uint flags) @nogc pure nothrow
{
    return cast(Move)(from | (to << 7) | (captured << 14 ) | (promotion << 20 ) | flags);
}

bool flag(Move move, uint flag) @nogc nothrow pure
{
    return (move & flag) > 0;
}

int fromsq(Move move) @nogc nothrow pure
{
    return move & 0x7F;
}

int tosq(Move move) @nogc nothrow pure
{
    return (move >> 7) & 0x7F;
}

int captured(Move move) @nogc nothrow pure
{
    return (move >> 14) & 0xF;
}

int promoted(Move move) @nogc nothrow pure
{
    return (move >> 20) & 0xF;
}

string toString(Move m)
{
    static char[5] moveStr;

    moveStr[0] = cast(char)(FilesBrd[m.fromsq()] + 'a');
    moveStr[1] = cast(char)(RanksBrd[m.fromsq()] + '1');
    moveStr[2] = cast(char)(FilesBrd[m.tosq()] + 'a');
    moveStr[3] = cast(char)(RanksBrd[m.tosq()] + '1');

    int promoted = m.promoted();

    if(promoted)
    {
        if(promoted == wN || promoted == bN) moveStr[4] = 'n';
        else if(promoted == wB || promoted == bB) moveStr[4] = 'b';
        else if(promoted == wR || promoted == bR) moveStr[4] = 'r';
        else moveStr[4] = 'q';
    }
    else
    {
        moveStr[4] = '\0';
    }

    return moveStr.idup;
}

static enum uint MFLAGEP = 0x40000;
static enum uint MFLAGPS = 0x80000;
static enum uint MFLAGCA = 0x1000000;

static enum uint MFLAGCAP = 0x7C000;
static enum uint MFLAGPROM = 0xF00000;

static enum Move NOMOVE = constructMove(0, 0, 0, 0, 0);
