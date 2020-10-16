/**
King class for defining it's behavior.

Source: $(PHOBOSSRC libchess/pieces/_king.d)

Copyright: Copyright Michael Weber Jr.
License:   $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors:   Michael Weber JR.
 */

module libchess.pieces.king;

import libchess.piece;
import libchess.defs;

class King : Piece
{
    this(int Color)
    {
        super(Color == WHITE ? wK : bK, Color);
    }

    override string toString() pure nothrow @nogc
    {
        return Color == WHITE ? "K" : "k";
    }

    override bool isMajor() pure nothrow @nogc const
    {
        return true;
    }

    override bool isMinor() pure nothrow @nogc const
    {
        return false;
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
        return true;
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
        return [ -1, -10, 1, 10, -9, -11, 11, 9 ];
    }
}
