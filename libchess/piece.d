/**
Pieces are represented by a single heirchy Piece class which is defined here. It is likely that this will be condensed to just a single class.

Source: $(PHOBOSSRC libchess/_piece.d)

Copyright: Copyright Michael Weber Jr.
License:   $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors:   Michael Weber JR.
 */

module libchess.piece;

import libchess.defs;
public import libchess.pieces.pawn,
              libchess.pieces.knight,
              libchess.pieces.bishop,
              libchess.pieces.rook,
              libchess.pieces.queen,
              libchess.pieces.king;

abstract class Piece
{
    protected
    {
        int Sq;
        int Type;
        int Color;
        //int[8] moveDir;
        //int[8] dir;
    }

    protected this(int Type, int Color)
    {
        this.Sq = Sq = OFFBOARD;
        this.Type = Type;
        this.Color = Color;
    }

    bool isMajor() pure nothrow @nogc const;
    bool isMinor() pure nothrow @nogc const;
    bool isBig() pure nothrow @nogc const;
    bool isPawn() pure nothrow @nogc;
    bool isKnight() pure nothrow @nogc;
    bool isKing() pure nothrow @nogc;
    bool isRQ() pure nothrow @nogc;
    bool isBQ() pure nothrow @nogc;
    bool slides() pure nothrow @nogc;
    override string toString() pure nothrow @nogc;

    static int[8] getDir(int type) pure nothrow @nogc
    {
        switch(type)
        {
            case wP: return Pawn.getDir();
            case bP: return Pawn.getDir();
            case wN: return Knight.getDir();
            case bN: return Knight.getDir();
            case wB: return Bishop.getDir();
            case bB: return Bishop.getDir();
            case wR: return Rook.getDir();
            case bR: return Rook.getDir();
            case wQ: return Queen.getDir();
            case bQ: return Queen.getDir();
            case wK: return King.getDir();
            case bK: return King.getDir();
            default: assert(false);
        }
    }

    int color() pure nothrow @nogc const
    {
        return Color;
    }

    int type() pure nothrow @nogc const
    {
        return Type;
    }

    int sq() pure nothrow @nogc const
    {
        return Sq;
    }

    void setSQ(int n_sq) pure nothrow @nogc
    {
        Sq = n_sq;
    }
}
