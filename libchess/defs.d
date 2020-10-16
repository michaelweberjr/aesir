/**
A list of constants and utility functions for LibChess.

Source: $(PHOBOSSRC libchess/_defs.d)

Copyright: Copyright Michael Weber Jr.
License:   $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors:   Michael Weber JR.
 */

module libchess.defs;

import libchess.validate;

class ChessException : Exception
{
    this(string msg)
    {
        super(msg);
    }
}

enum int MAXGAMEMOVES = 2048;
enum int MAXDEPTH = 64;
enum int MAXPOSITIONMOVES = 256;

enum { EMPTY, wP, wN, wB, wR, wQ, wK, bP, bN, bB, bR, bQ, bK  };
enum { FILE_A, FILE_B, FILE_C, FILE_D, FILE_E, FILE_F, FILE_G, FILE_H, FILE_NONE };
enum { RANK_1, RANK_2, RANK_3, RANK_4, RANK_5, RANK_6, RANK_7, RANK_8, RANK_NONE };

enum { WHITE, BLACK, BOTH };
enum { UCIMODE, XBOARDMODE, CONSOLEMODE };

// This the 120 board notation
enum int BRD_SQ_NUM = 120;
// The value of each square based on 120 notation
enum {
  A1 = 21, B1, C1, D1, E1, F1, G1, H1,
  A2 = 31, B2, C2, D2, E2, F2, G2, H2,
  A3 = 41, B3, C3, D3, E3, F3, G3, H3,
  A4 = 51, B4, C4, D4, E4, F4, G4, H4,
  A5 = 61, B5, C5, D5, E5, F5, G5, H5,
  A6 = 71, B6, C6, D6, E6, F6, G6, H6,
  A7 = 81, B7, C7, D7, E7, F7, G7, H7,
  A8 = 91, B8, C8, D8, E8, F8, G8, H8, NO_SQ, OFFBOARD
};

enum { WKCA = 1, WQCA = 2, BKCA = 4, BQCA = 8 };

enum int MaxGameMoves = 2048;
enum int MaxDepth = 64;
enum string startFen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

int FR2SQ(int f, int r) @nogc nothrow pure
{
    return (21 + f) + (r * 10);
}

private
{
    // Conversion arrays to convert from square 120 notation to 64 notation
    int [BRD_SQ_NUM]Sq120ToSq64;
    int [64]Sq64ToSq120;
}

// Returns the file or rank of the square
int FilesBrd[BRD_SQ_NUM];
int RanksBrd[BRD_SQ_NUM];

// Initializes the conversion arrays
static this()
{
    // Square 120 and 64 conversions
	int sq = A1;
	int sq64 = 0;

	for(int i = 0; i < BRD_SQ_NUM; i++)
		Sq120ToSq64[i] = 65;

	for(int i = 0; i < 64; i++)
		Sq64ToSq120[i] = 120;

	for(int rank = RANK_1; rank <= RANK_8; ++rank)
		for(int file = FILE_A; file <= FILE_H; ++file)
		{
			sq = FR2SQ(file, rank);
			assert(SqOnBoard(sq));
			Sq64ToSq120[sq64] = sq;
			Sq120ToSq64[sq] = sq64;
			sq64++;
		}

    // Files and Ranks Board
	sq = A1;

	for(int i = 0; i < BRD_SQ_NUM; i++)
    {
		FilesBrd[i] = OFFBOARD;
		RanksBrd[i] = OFFBOARD;
	}

	for(int rank = RANK_1; rank <= RANK_8; ++rank)
		for(int file = FILE_A; file <= FILE_H; ++file)
        {
			sq = FR2SQ(file, rank);
			FilesBrd[sq] = file;
			RanksBrd[sq] = rank;
		}
}

// This function converts a square from 120 notation to 64 notation
int SQ64(int sq120) @nogc nothrow
{
    return Sq120ToSq64[(sq120)];
}

// This function converts a square from 64 notation to 120 notation
int SQ120(int sq64) @nogc nothrow
{
    return Sq64ToSq120[(sq64)];
}
