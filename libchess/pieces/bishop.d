/**
Bishop class for defining it's behavior.

Source: $(PHOBOSSRC libchess/pieces/_bishop.d)

Copyright: Copyright Michael Weber Jr.
License:   $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors:   Michael Weber JR.
 */

module libchess.pieces.bishop;

import libchess.piece;
import libchess.defs;

class Bishop : Piece
{
    this(int Color)
    {
        super(Color == WHITE ? wB : bB, Color);
    }

    override string toString() pure nothrow @nogc
    {
        return Color == WHITE ? "B" : "b";
    }

    override bool isMajor() pure nothrow @nogc const
    {
        return false;
    }

    override bool isMinor() pure nothrow @nogc const
    {
        return true;
    }

    override bool isBig() pure nothrow @nogc const
    {
         return true;
    }

    override bool isPawn() pure nothrow @nogc
    {
        return false;
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
        return true;
    }

    override bool slides() pure nothrow @nogc
    {
        return true;
    }

    static int[8] getDir() pure nothrow @nogc
    {
        return [ -9, -11, 11, 9, 0, 0, 0, 0 ];
    }
}
