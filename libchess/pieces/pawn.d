/**
Pawn class for defining it's behavior.

Source: $(PHOBOSSRC libchess/pieces/_pawn.d)

Copyright: Copyright Michael Weber Jr.
License:   $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors:   Michael Weber JR.
 */

module libchess.pieces.pawn;

import libchess.piece;
import libchess.defs;

class Pawn : Piece
{
    this(int Color)
    {
        super(Color == WHITE ? wP : bP, Color);
    }

    override string toString() pure nothrow @nogc
    {
        return Color == WHITE ? "P" : "p";
    }

    override bool isMajor() pure nothrow @nogc const
    {
        return false;
    }

    override bool isMinor() pure nothrow @nogc const
    {
        return false;
    }

    override bool isBig() pure nothrow @nogc const
    {
         return false;
    }

    override bool isPawn() pure nothrow @nogc
    {
        return true;
    }

    override bool isKnight() pure nothrow @nogc
    {
        return false;
    }

    override bool isKing() pure nothrow @nogc
    {
        return false;
    }

    override bool isRQ() pure nothrow @nogc
    {
        return false;
    }

    override bool isBQ() pure nothrow @nogc
    {
        return false;
    }

    override bool slides() pure nothrow @nogc
    {
        return false;
    }

    static int[8] getDir() pure nothrow @nogc
    {
        return [ 0, 0, 0, 0, 0, 0, 0, 0 ];
    }
}
