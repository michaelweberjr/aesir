/**
LibChess provides the basic options for playing a chess game. Most everything flows through the $(D Board) class defined
in this file.

Source: $(PHOBOSSRC libchess/_board.d)

Copyright: Copyright Michael Weber Jr.
License:   $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors:   Michael Weber JR.
 */

module libchess.board;

import std.conv : to;
import libchess.piece;
import libchess.bitboard;
import libchess.hash;
import libchess.move;
import libchess.defs;
import libchess.validate;


class Board
{
    Piece[BRD_SQ_NUM] pieces;
	BitBoard[3] pawns;

	int[2] KingSq;

	int side = WHITE;
	int enPas = NO_SQ;
	int fiftyMove;

	int ply;
	int hisPly;

	ubyte castlePerm;

	ulong posKey;

	int[13] pceNum;
	int[2] bigPce;
	int[2] majPce;
	int[2] minPce;

	Undo[MaxGameMoves] history;

	// piece list
	Piece[10][13] pList;

	this(string fen = "")
    {
        // create the objects for the pieces
        foreach(i; 0..10)
        {
            pList[wP][i] = new Pawn(WHITE);
            pList[bP][i] = new Pawn(BLACK);
            pList[wN][i] = new Knight(WHITE);
            pList[bN][i] = new Knight(BLACK);
            pList[wB][i] = new Bishop(WHITE);
            pList[bB][i] = new Bishop(BLACK);
            pList[wR][i] = new Rook(WHITE);
            pList[bR][i] = new Rook(BLACK);
            pList[wQ][i] = new Queen(WHITE);
            pList[bQ][i] = new Queen(BLACK);
            pList[wK][i] = new King(WHITE);
            pList[bK][i] = new King(BLACK);
            posKey = generatePosKey(this);
        }

        if(fen.length > 0)
        {
            parseFen(fen);
        }
    }

	// Used in check board to make sure everthing is okay
	const private bool pceListOk() @nogc nothrow
	{
        for(int pce = wP; pce <= bK; ++pce)
            if(pceNum[pce] < 0 || pceNum[pce] >= 10)
                return false;

        if(pceNum[wK] != 1 || pceNum[bK] != 1) return false;

        for(int pce = wP; pce <= bK; ++pce)
            for(int num = 0; num < pceNum[pce]; ++num)
            {
                int sq = pList[pce][num].sq();
                if(!SqOnBoard(sq)) return false;
            }
        return true;
    }

    const private int check() @nogc
    {
        int[13] t_pceNum = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ];
        int[2] t_bigPce = [ 0, 0 ];
        int[2] t_majPce = [ 0, 0 ];
        int[2] t_minPce = [ 0, 0 ];
        int[2] t_material = [ 0, 0 ];

        int sq64, t_piece, t_pce_num, sq120, color, pcount;
        //const(Piece) piece;

        BitBoard[3] t_pawns;

        t_pawns[WHITE] = pawns[WHITE];
        t_pawns[BLACK] = pawns[BLACK];
        t_pawns[BOTH] = pawns[BOTH];

        // check piece lists
        for(t_piece = wP; t_piece <= bK; ++t_piece)
            for(t_pce_num = 0; t_pce_num < pceNum[t_piece]; ++t_pce_num)
            {
                sq120 = pList[t_piece][t_pce_num].sq();
                assert(pieces[sq120].type() == t_piece);
            }

        // check piece count and other counters
        for(sq64 = 0; sq64 < 64; ++sq64)
        {
            sq120 = SQ120(sq64);
            auto piece = pieces[sq120];
            if(piece is null) continue;
            t_pceNum[piece.type()]++;
            color = piece.color();
            if(piece.isBig()) t_bigPce[color]++;
            if(piece.isMinor()) t_minPce[color]++;
            if(piece.isMajor()) t_majPce[color]++;

            //t_material[color] += PieceVal[t_piece];
        }

        for(t_piece = wP; t_piece <= bK; ++t_piece)
            assert(t_pceNum[t_piece] == pceNum[t_piece]);

        // check bitboards count
        pcount = t_pawns[WHITE].count();
        assert(pcount == pceNum[wP]);
        pcount = t_pawns[BLACK].count();
        assert(pcount == pceNum[bP]);
        pcount = t_pawns[BOTH].count();
        assert(pcount == pceNum[bP] + pceNum[wP]);

        // check bitboards squares
        while(t_pawns[WHITE] > 0)
        {
            sq64 = t_pawns[WHITE].pop();
            assert(pieces[SQ120(sq64)].type() == wP);
        }

        while(t_pawns[BLACK] > 0)
        {
            sq64 = t_pawns[BLACK].pop();
            assert(pieces[SQ120(sq64)].type() == bP);
        }

        while(t_pawns[BOTH] > 0)
        {
            sq64 = t_pawns[BOTH].pop();
            assert((pieces[SQ120(sq64)].type() == bP) || (pieces[SQ120(sq64)].type() == wP));
        }

        //assert(t_material[WHITE]==pos->material[WHITE] && t_material[BLACK]==pos->material[BLACK]);
        assert(t_minPce[WHITE] == minPce[WHITE] && t_minPce[BLACK] == minPce[BLACK]);
        assert(t_majPce[WHITE] == majPce[WHITE] && t_majPce[BLACK] == majPce[BLACK]);
        assert(t_bigPce[WHITE] == bigPce[WHITE] && t_bigPce[BLACK] == bigPce[BLACK]);

        assert(side == WHITE || side == BLACK);
        assert(generatePosKey(this) == posKey);

        assert(enPas == NO_SQ || (RanksBrd[enPas] == RANK_6 && side == WHITE) || (RanksBrd[enPas] == RANK_3 && side == BLACK));

        assert(pieces[KingSq[WHITE]].type() == wK);
        assert(pieces[KingSq[BLACK]].type() == bK);

        assert(castlePerm >= 0 && castlePerm <= 15);

        assert(pceListOk());

        return true;
    }

    invariant
    {
        //assert(check());
    }

    private void updateListsMaterial() @nogc
    {
        int sq,index,color;
        Piece piece;

        for(index = 0; index < BRD_SQ_NUM; ++index)
        {
            sq = index;
            piece = pieces[index];
            if(piece is null) continue;
            assert(PceValidEmptyOffbrd(piece.type()));

            if(piece.sq() != OFFBOARD && piece.sq() != EMPTY)
            {
                color = piece.color();
                assert(SideValid(color));

                if(piece.isBig()) bigPce[color]++;
                if(piece.isMinor()) minPce[color]++;
                if(piece.isMajor()) majPce[color]++;

                //material[color] += piece.value();

                assert(pceNum[piece.type()] < 10 && pceNum[piece.type()] >= 0);

                // not needed
                //pList[piece.sq()][pceNum[piece.type()]] = sq;
                //pceNum[piece.type()]++;


                if(piece.type() == wK) KingSq[WHITE] = sq;
                if(piece.type() == bK) KingSq[BLACK] = sq;

                if(piece.type() == wP)
                {
                    pawns[WHITE].set(SQ64(sq));
                    pawns[BOTH].set(SQ64(sq));
                }
                else if(piece.type() == bP)
                {
                    pawns[BLACK].set(SQ64(sq));
                    pawns[BOTH].set(SQ64(sq));
                }
            }
        }
    }

    void parseFen(string fen)
    {
        assert(fen.length > 0);

        int  rank = RANK_8;
        int  file = FILE_A;
        int  piece = 0;
        int  count = 0;
        int  i = 0;
        int  sq64 = 0;
        int  sq120 = 0;
        int currentChar;

        reset();

        while((rank >= RANK_1) && currentChar < fen.length)
        {
            count = 1;
            switch(fen[currentChar])
            {
                case 'p': piece = bP; break;
                case 'r': piece = bR; break;
                case 'n': piece = bN; break;
                case 'b': piece = bB; break;
                case 'k': piece = bK; break;
                case 'q': piece = bQ; break;
                case 'P': piece = wP; break;
                case 'R': piece = wR; break;
                case 'N': piece = wN; break;
                case 'B': piece = wB; break;
                case 'K': piece = wK; break;
                case 'Q': piece = wQ; break;

                case '1':
                case '2':
                case '3':
                case '4':
                case '5':
                case '6':
                case '7':
                case '8':
                    piece = EMPTY;
                    count = fen[currentChar] - '0';
                    break;

                case '/':
                case ' ':
                    rank--;
                    file = FILE_A;
                    currentChar++;
                    continue;

                default:
                    throw new ChessException("FEN error \n");
            }

            for (i = 0; i < count; i++)
            {
                sq64 = rank * 8 + file;
                sq120 = SQ120(sq64);
                if (piece != EMPTY)
                {
                    pieces[sq120] = pList[piece][pceNum[piece]];
                    pList[piece][pceNum[piece]++].setSQ(sq120);
                }
                file++;
            }
            currentChar++;
        }

        assert(fen[currentChar] == 'w' || fen[currentChar] == 'b');

        side = (fen[currentChar] == 'w') ? WHITE : BLACK;
        currentChar += 2;

        for (i = 0; i < 4; i++)
        {
            if (fen[currentChar] == ' ') break;

            switch(fen[currentChar])
            {
                case 'K': castlePerm |= WKCA; break;
                case 'Q': castlePerm |= WQCA; break;
                case 'k': castlePerm |= BKCA; break;
                case 'q': castlePerm |= BQCA; break;
                default:
                    break;
            }
            currentChar++;
        }
        currentChar++;

        assert(castlePerm>=0 && castlePerm <= 15);

        if(fen[currentChar] != '-')
        {
            file = fen[currentChar] - 'a';
            rank = fen[currentChar + 1] - '1';

            assert(file>=FILE_A && file <= FILE_H);
            assert(rank>=RANK_1 && rank <= RANK_8);

            enPas = FR2SQ(file, rank);
        }

        posKey = generatePosKey(this);

        updateListsMaterial();
    }

    void reset()
    {
        int index = 0;

        for(index = 0; index < BRD_SQ_NUM; ++index) pieces[index] = null;

        for(index = 0; index < 64; ++index) pieces[SQ120(index)] = null;

        for(index = 0; index < 10; index++)
            for(int j = 1; j < 13; j++)
                pList[j][index].setSQ(OFFBOARD);

        for(index = 0; index < 2; ++index)
        {
            bigPce[index] = 0;
            majPce[index] = 0;
            minPce[index] = 0;
        }

        for(index = 0; index < 3; ++index) pawns[index] = 0UL;

        for(index = 0; index < 13; ++index) pceNum[index] = 0;

        KingSq[WHITE] = KingSq[BLACK] = NO_SQ;

        side = BOTH;
        enPas = NO_SQ;
        fiftyMove = 0;

        ply = 0;
        hisPly = 0;

        castlePerm = 0;

        posKey = 0UL;

    }

    string generateFen() nothrow
    {
        int count;
        enum int[8] reverse = [7, 6, 5, 4, 3, 2, 1];
        string result;
        foreach(i; RANK_1..RANK_8+1)
        {
            count = 0;
            foreach(j; FILE_A..FILE_H+1)
            {
                int sq = FR2SQ(j, reverse[i]);
                if(pieces[sq] !is null)
                {
                    if(count > 0)
                    {
                        result ~= to!string(count);
                        count = 0;
                    }
                    result ~= pieces[sq].toString();
                }
                else count++;
            }
            if(count > 0)
            {
                result ~= to!string(count);
            }
            if(i != RANK_8) result ~= '/';
        }

        result ~= side == WHITE ? " w " : " b ";
        if(castlePerm & WKCA) result ~= "K";
        if(castlePerm & WQCA) result ~= "Q";
        if(castlePerm & BKCA) result ~= "k";
        if(castlePerm & BQCA) result ~= "q";
        if(castlePerm == 0) result ~= "-";

        result ~= " ";

        if(enPas != NO_SQ)
        {
            result ~= cast(char)(FilesBrd[enPas] + 'a');
            result ~= cast(char)(RanksBrd[enPas] + '1') ~ " ";
        }
        else result ~= "- ";

        result ~= to!string(hisPly) ~ " " ~ to!string(ply);

        return result;
    }

    unittest
    {
        auto board = new Board();
        board.parseFen(startFen);
        assert(board.makeMove(constructMove(FR2SQ(FILE_E, RANK_2), FR2SQ(FILE_E, RANK_4), 0, 0, MFLAGPS)));
        assert(board.generateFen() == "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 1 1", board.generateFen());
    }

    override string toString()
    {
        string board;
        int sq,file,rank;
        Piece piece;

        board ~= "\nGame Board:\n\n";

        for(rank = RANK_8; rank >= RANK_1; rank--)
        {
            board ~= to!string(rank+1) ~ "  ";
            for(file = FILE_A; file <= FILE_H; file++)
            {
                sq = FR2SQ(file,rank);
                piece = pieces[sq];
                if(piece is null) board ~= "  .";
                else board ~= "  " ~ piece.toString();
            }
            board ~= "\n";
        }

        board ~= "\n   ";
        for(file = FILE_A; file <= FILE_H; file++) board ~= "  " ~ cast(char)('a'+file);

        board ~= "\n\n";
        board ~= "side:" ~ (side == WHITE ? "w" : "b") ~ "\n";
        board ~= "enPas:" ~ to!string(enPas) ~ "\n";
        board ~= "castle:";
        board ~= (castlePerm & WKCA) ? 'K' : '-';
        board ~= (castlePerm & WQCA) ? 'Q' : '-';
        board ~= (castlePerm & BKCA) ? 'k' : '-';
        board ~= (castlePerm & BQCA) ? 'q' : '-';
        board ~= "\nPosKey:" ~ to!string(posKey) ~ "\n";

        return board;
    }

    // used to quickly determine what the castle permitions change when a piece moves
    private static const int[120] CastlePerm = [
        15, 15, 15, 15, 15, 15, 15, 15, 15, 15,
        15, 15, 15, 15, 15, 15, 15, 15, 15, 15,
        15, 13, 15, 15, 15, 12, 15, 15, 14, 15,
        15, 15, 15, 15, 15, 15, 15, 15, 15, 15,
        15, 15, 15, 15, 15, 15, 15, 15, 15, 15,
        15, 15, 15, 15, 15, 15, 15, 15, 15, 15,
        15, 15, 15, 15, 15, 15, 15, 15, 15, 15,
        15, 15, 15, 15, 15, 15, 15, 15, 15, 15,
        15, 15, 15, 15, 15, 15, 15, 15, 15, 15,
        15,  7, 15, 15, 15,  3, 15, 15, 11, 15,
        15, 15, 15, 15, 15, 15, 15, 15, 15, 15,
        15, 15, 15, 15, 15, 15, 15, 15, 15, 15
    ];

    void clearPiece(const int sq) @nogc
    {
        assert(SqOnBoard(sq));

        auto pce = pieces[sq];

        assert(pce !is null);

        int col = pce.color();
        int index = 0;
        int t_pceNum = -1;

        assert(SideValid(col));

        posKey ^= hashPiece(pce, sq);

        pieces[sq] = null;
        //material[col] -= PieceVal[pce];

        if(pce.isBig())
        {
            bigPce[col]--;
            if(pce.isMajor()) majPce[col]--;
            else minPce[col]--;
        }
        else
        {
            pawns[col].clear(SQ64(sq));
            pawns[BOTH].clear(SQ64(sq));
        }

        for(index = 0; index < pceNum[pce.type()]; ++index)
            if(pList[pce.type()][index] is pce)
            {
                t_pceNum = index;
                break;
            }

        assert(t_pceNum != -1);
        assert(t_pceNum >= 0 && t_pceNum < 10);

        pList[pce.type()][t_pceNum].setSQ(OFFBOARD);
        pceNum[pce.type()]--;

        pList[pce.type()][t_pceNum] = pList[pce.type()][pceNum[pce.type()]];
        pList[pce.type()][pceNum[pce.type()]] = pce;
    }


    void addPiece(const int sq, int pceType) @nogc
    {
        assert(PieceValid(pceType));
        assert(SqOnBoard(sq));

        Piece pce;
        if(pceType == wP) pce = pList[wP][pceNum[wP]++];
        else if(pceType == bP) pce = pList[bP][pceNum[bP]++];
        else if(pceType == wN) pce = pList[wN][pceNum[wN]++];
        else if(pceType == bN) pce = pList[bN][pceNum[bN]++];
        else if(pceType == wB) pce = pList[wB][pceNum[wB]++];
        else if(pceType == bB) pce = pList[bB][pceNum[bB]++];
        else if(pceType == wR) pce = pList[wR][pceNum[wR]++];
        else if(pceType == bR) pce = pList[bR][pceNum[bR]++];
        else if(pceType == wQ) pce = pList[wQ][pceNum[wQ]++];
        else if(pceType == bQ) pce = pList[bQ][pceNum[bQ]++];
        else assert(false, "Illegal piece type");
        pce.setSQ(sq);

        int col = pce.color();
        assert(SideValid(col));

        posKey ^= hashPiece(pce, sq);

        pieces[sq] = pce;

        if(pce.isBig())
        {
            bigPce[col]++;
            if(pce.isMajor()) majPce[col]++;
            else minPce[col]++;
        }
        else
        {
            pawns[col].set(SQ64(sq));
            pawns[BOTH].set(SQ64(sq));
        }

        //material[col] += PieceVal[pce];
    }

    void movePiece(const int from, const int to) @nogc
    {
        assert(SqOnBoard(from));
        assert(SqOnBoard(to));

        int index = 0;
        auto pce = pieces[from];
        int col = pce.color();
        assert(SideValid(col));
        assert(PieceValid(pce.type()));

        posKey ^= hashPiece(pce, from);
        pieces[from] = null;

        posKey ^= hashPiece(pce, to);
        pieces[to] = pce;

        if(!pce.isBig())
        {
            pawns[col].clear(SQ64(from));
            pawns[BOTH].clear(SQ64(from));
            pawns[col].set(SQ64(to));
            pawns[BOTH].set(SQ64(to));
        }

        for(index = 0; index < pceNum[pce.type()]; ++index)
            if(pList[pce.type()][index].sq() == from)
            {
                pList[pce.type()][index].setSQ(to);
                break;
            }
    }

    bool makeMove(Move move) @nogc
    {
        int from = move.fromsq();
        int to = move.tosq();

        assert(SqOnBoard(from));
        assert(SqOnBoard(to));
        assert(SideValid(side));
        assert(pieces[from] !is null);
        assert(hisPly >= 0 && hisPly < MAXGAMEMOVES);
        assert(ply >= 0 && ply < MAXDEPTH);

        history[hisPly].posKey = posKey;

        if(move.flag(MFLAGEP))
        {
            if(side == WHITE) clearPiece(to-10);
            else clearPiece(to+10);
        }
        else if(move.flag(MFLAGCA))
        {
            switch(to)
            {
                case C1:
                    movePiece(A1, D1);
                    break;
                case C8:
                    movePiece(A8, D8);
                    break;
                case G1:
                    movePiece(H1, F1);
                    break;
                case G8:
                    movePiece(H8, F8);
                    break;
                default: assert(false);
            }
        }

        if(enPas != NO_SQ) posKey ^= hashEP(enPas);
        posKey ^= hashCastle(castlePerm);

        history[hisPly].move = move;
        history[hisPly].fiftyMove = fiftyMove;
        history[hisPly].enPas = enPas;
        history[hisPly].castlePerm = castlePerm;

        castlePerm &= CastlePerm[from];
        castlePerm &= CastlePerm[to];
        enPas = NO_SQ;

        posKey ^= hashCastle(castlePerm);

        int captured = move.captured();
        fiftyMove++;

        if(captured != EMPTY)
        {
            assert(PieceValid(captured));
            clearPiece(to);
            fiftyMove = 0;
        }

        hisPly++;
        ply++;

        assert(hisPly >= 0 && hisPly < MAXGAMEMOVES);
        assert(ply >= 0 && ply < MAXDEPTH);

        if(pieces[from].isPawn())
        {
            fiftyMove = 0;
            if(move.flag(MFLAGPS))
            {
                if(side == WHITE)
                {
                    enPas = from+10;
                    assert(RanksBrd[enPas] == RANK_3);
                }
                else
                {
                    enPas= from-10;
                    assert(RanksBrd[enPas] == RANK_6);
                }
                posKey ^= hashEP(enPas);
            }
        }

        movePiece(from, to);

        int prPce = move.promoted();
        if(prPce != EMPTY)
        {
            assert(PieceValid(prPce));
            clearPiece(to);
            addPiece(to, prPce);
        }

        if(pieces[to].isKing())
            KingSq[side] = to;

        side ^= 1;
        posKey ^= hashSide();

        assert(check());

        if(sqAttacked(KingSq[side^1], side))
        {
            takeMove();
            return false;
        }

        return true;

    }

    void takeMove() @nogc
    {
        hisPly--;
        ply--;

        assert(hisPly >= 0 && hisPly < MAXGAMEMOVES);
        assert(ply >= 0 && ply < MAXDEPTH);

        Move move = history[hisPly].move;
        int from = move.fromsq();
        int to = move.tosq();

        assert(SqOnBoard(from));
        assert(SqOnBoard(to));

        if(enPas != NO_SQ) posKey ^= hashEP(enPas);
        posKey ^= hashCastle(castlePerm);

        castlePerm = history[hisPly].castlePerm;
        fiftyMove = history[hisPly].fiftyMove;
        enPas = history[hisPly].enPas;

        if(enPas != NO_SQ) posKey ^= hashEP(enPas);
        posKey ^= hashCastle(castlePerm);

        side ^= 1;
        posKey ^= hashSide();

        if(move.flag(MFLAGEP))
        {
            if(side == WHITE) addPiece(to-10, bP);
            else addPiece(to+10, wP);
        }
        else if(move.flag(MFLAGCA))
        {
            switch(to)
            {
                case C1: movePiece(D1, A1); break;
                case C8: movePiece(D8, A8); break;
                case G1: movePiece(F1, H1); break;
                case G8: movePiece(F8, H8); break;
                default: assert(false);
            }
        }

        movePiece(to, from);

        if(pieces[from].isKing()) KingSq[side] = from;

        int captured = move.captured();
        if(captured != EMPTY)
        {
            assert(PieceValid(captured));
            addPiece(to, captured);
        }

        if(move.promoted() != EMPTY)
        {
            assert(PieceValid(move.promoted()));
            clearPiece(from);
            addPiece(from, move.promoted() < bP ? wP : bP);
        }

        assert(check());

    }


    void makeNullMove() @nogc
    {
        assert(!sqAttacked(KingSq[side], side^1));

        ply++;
        history[hisPly].posKey = posKey;

        if(enPas != NO_SQ) posKey ^= hashEP(enPas);

        history[hisPly].move = NOMOVE;
        history[hisPly].fiftyMove = fiftyMove;
        history[hisPly].enPas = enPas;
        history[hisPly].castlePerm = castlePerm;
        enPas = NO_SQ;

        side ^= 1;
        hisPly++;
        posKey ^= hashSide();

        assert(check());
        assert(hisPly >= 0 && hisPly < MAXGAMEMOVES);
        assert(ply >= 0 && ply < MAXDEPTH);
    }

    void takeNullMove() @nogc
    {
        assert(check());

        hisPly--;
        ply--;

        if(enPas != NO_SQ) posKey ^= hashEP(enPas);

        castlePerm = history[hisPly].castlePerm;
        fiftyMove = history[hisPly].fiftyMove;
        enPas = history[hisPly].enPas;

        if(enPas != NO_SQ) posKey ^= hashEP(enPas);
        side ^= 1;
        posKey ^= hashSide();

        assert(check());
        assert(hisPly >= 0 && hisPly < MAXGAMEMOVES);
        assert(ply >= 0 && ply < MAXDEPTH);
    }

    bool sqAttacked(const int sq, const int side) @nogc
    {
        int index, t_sq, dir;
        int[8] mov;
        Piece pce;

        assert(SqOnBoard(sq));
        assert(SideValid(side));

        // pawns
        if(side == WHITE)
        {
            if((pieces[sq-11] !is null && pieces[sq-11].type() == wP) || (pieces[sq-9] !is null && pieces[sq-9].type() == wP))
                return true;
        }
        else
        {
            if((pieces[sq+11] !is null && pieces[sq+11].type() == bP) || (pieces[sq+9] !is null && pieces[sq+9].type() == bP))
                return true;
        }

        // knights
        mov = Knight.getDir();
        for(index = 0; index < 8; ++index)
        {
            pce = pieces[sq + mov[index]];
            if(pce is null) continue;
            if(pce.sq() != OFFBOARD && pce.isKnight() && pce.color() == side)
                return true;
        }

        // rooks, queens
        mov = Rook.getDir();
        for(index = 0; index < 4; ++index)
        {
            dir = mov[index];
            t_sq = sq;
            assert(SqIs120(t_sq));
            while(true)
            {
                t_sq += dir;
                assert(SqIs120(t_sq));
                if(!SqOnBoard(t_sq)) break;
                pce = pieces[t_sq];
                if(pce is null) continue;
                else
                {
                    if(pce.isRQ() && pce.color() == side) return true;
                    break;
                }
            }
        }

        // bishops, queens
        mov = Bishop.getDir();
        for(index = 0; index < 4; ++index)
        {
            dir = mov[index];
            t_sq = sq;
            assert(SqIs120(t_sq));
            while(true)
            {
                t_sq += dir;
                assert(SqIs120(t_sq));
                if(!SqOnBoard(t_sq)) break;
                pce = pieces[t_sq];
                if(pce is null) continue;
                else
                {
                    if(pce.isBQ() && pce.color() == side) return true;
                    break;
                }
            }
        }

        // kings
        mov = King.getDir();
        for(index = 0; index < 8; ++index)
        {
            pce = pieces[sq + mov[index]];
            if(pce is null) continue;
            if(pce.isKing() && pce.color() == side) return true;
        }

        return false;
    }

    bool inCheck()
    {
        return sqAttacked(KingSq[side], side^1);
    }

    bool staleMate()
    {
        return !inCheck() && generateAllMoves().length == 0;
    }

    bool checkMate()
    {
        return inCheck() && generateAllMoves().length == 0;
    }

    auto generateAllMoves() @nogc
    {
        struct MoveList
        {
            private
            {
                Move[MAXPOSITIONMOVES] moves;
                int count;
                int frontIndex;
            }

            void addMove(Move m) pure nothrow @nogc
            {
                moves[count++] = m;
            }

            bool empty() pure nothrow @nogc @property
            {
                return frontIndex == count;
            }

            Move front() pure nothrow @nogc @property
            {
                return moves[frontIndex];
            }

            void popFront() pure nothrow @nogc
            {
                if(frontIndex < count) frontIndex++;
            }

            int length() pure nothrow @nogc @property
            {
                return count;
            }

            Move opIndex(int i) pure @nogc
            {
                assert(i < 0 || i >= count);
                return moves[i];
            }
        }

        MoveList list;

        list.count = 0;

        Piece pce;
        int t_sq;
        int sq;
        int pceNum;
        int dir;
        int index;

        if(side == WHITE)
        {
            for(pceNum = 0; pceNum < this.pceNum[wP]; ++pceNum)
            {
                sq = pList[wP][pceNum].sq();
                assert(SqOnBoard(sq));

                if(pieces[sq + 10] is null)
                {
                    if(RanksBrd[sq] != RANK_7) list.addMove(constructMove(sq, sq+10, 0, 0, 0));
                    else
                    {
                        list.addMove(constructMove(sq, sq+10, 0, wN, 0));
                        list.addMove(constructMove(sq, sq+10, 0, wB, 0));
                        list.addMove(constructMove(sq, sq+10, 0, wR, 0));
                        list.addMove(constructMove(sq, sq+10, 0, wQ, 0));
                    }

                    if(RanksBrd[sq] == RANK_2 && pieces[sq + 20] is null)
                    {
                        list.addMove(constructMove(sq, sq+20, 0, 0, MFLAGPS));
                    }
                }

                if(FilesBrd[sq + 9] != OFFBOARD && pieces[sq + 9] !is null && pieces[sq + 9].color() == BLACK)
                {
                    if(RanksBrd[sq] != RANK_7) list.addMove(constructMove(sq, sq + 9, pieces[sq + 9].type(), 0, 0));
                    else
                    {
                        list.addMove(constructMove(sq, sq+9, pieces[sq + 9].type(), wN, 0));
                        list.addMove(constructMove(sq, sq+9, pieces[sq + 9].type(), wB, 0));
                        list.addMove(constructMove(sq, sq+9, pieces[sq + 9].type(), wR, 0));
                        list.addMove(constructMove(sq, sq+9, pieces[sq + 9].type(), wQ, 0));
                    }
                }

                if(!FilesBrd[sq + 11] != OFFBOARD && pieces[sq + 11] !is null && pieces[sq + 11].color() == BLACK)
                {
                    if(RanksBrd[sq] != RANK_7) list.addMove(constructMove(sq, sq + 11, pieces[sq + 11].type(), 0, 0));
                    else
                    {
                        list.addMove(constructMove(sq, sq+11, pieces[sq + 11].type(), wN, 0));
                        list.addMove(constructMove(sq, sq+11, pieces[sq + 11].type(), wB, 0));
                        list.addMove(constructMove(sq, sq+11, pieces[sq + 11].type(), wR, 0));
                        list.addMove(constructMove(sq, sq+11, pieces[sq + 11].type(), wQ, 0));
                    }
                }

                if(enPas != NO_SQ)
                {
                    if(sq + 9 == enPas)
                        list.addMove(constructMove(sq, sq + 9, 0, 0, MFLAGEP));
                    if(sq + 11 == enPas)
                        list.addMove(constructMove(sq, sq + 11, 0, 0, MFLAGEP));
                }
            }

            if(castlePerm & WKCA)
                if(pieces[F1] is null && pieces[G1] is null)
                    if(!sqAttacked(E1, BLACK) && !sqAttacked(F1, BLACK))
                        list.addMove(constructMove(E1, G1, EMPTY, EMPTY, MFLAGCA));

            if(castlePerm & WQCA)
                if(pieces[D1] is null && pieces[C1] is null && pieces[B1] is null)
                    if(!sqAttacked(E1, BLACK) && !sqAttacked(D1, BLACK))
                        list.addMove(constructMove(E1, C1, EMPTY, EMPTY, MFLAGCA));
        }
        else
        {
            for(pceNum = 0; pceNum < this.pceNum[bP]; ++pceNum)
            {
                sq = pList[bP][pceNum].sq();
                assert(SqOnBoard(sq));

                if(pieces[sq - 10] is null)
                {
                    if(RanksBrd[sq] != RANK_2) list.addMove(constructMove(sq, sq-10, 0, 0, 0));
                    else
                    {
                        list.addMove(constructMove(sq, sq-10, 0, bN, 0));
                        list.addMove(constructMove(sq, sq-10, 0, bB, 0));
                        list.addMove(constructMove(sq, sq-10, 0, bR, 0));
                        list.addMove(constructMove(sq, sq-10, 0, bQ, 0));
                    }

                    if(RanksBrd[sq] == RANK_7 && pieces[sq - 20] is null)
                    {
                        list.addMove(constructMove(sq, sq-20, 0, 0, MFLAGPS));
                    }
                }

                if(FilesBrd[sq - 9] != OFFBOARD && pieces[sq - 9] !is null && pieces[sq - 9].color() == WHITE)
                {
                    if(RanksBrd[sq] != RANK_2) list.addMove(constructMove(sq, sq - 9, pieces[sq - 9].type(), 0, 0));
                    else
                    {
                        list.addMove(constructMove(sq, sq-9, pieces[sq - 9].type(), bN, 0));
                        list.addMove(constructMove(sq, sq-9, pieces[sq - 9].type(), bB, 0));
                        list.addMove(constructMove(sq, sq-9, pieces[sq - 9].type(), bR, 0));
                        list.addMove(constructMove(sq, sq-9, pieces[sq - 9].type(), bQ, 0));
                    }
                }

                if(FilesBrd[sq - 11] != OFFBOARD && pieces[sq - 11] !is null && pieces[sq - 11].color() == WHITE)
                {
                    if(RanksBrd[sq] != RANK_2) list.addMove(constructMove(sq, sq - 11, pieces[sq - 11].type(), 0, 0));
                    else
                    {
                        list.addMove(constructMove(sq, sq-11, pieces[sq - 11].type(), bN, 0));
                        list.addMove(constructMove(sq, sq-11, pieces[sq - 11].type(), bB, 0));
                        list.addMove(constructMove(sq, sq-11, pieces[sq - 11].type(), bR, 0));
                        list.addMove(constructMove(sq, sq-11, pieces[sq - 11].type(), bQ, 0));
                    }
                }

                if(enPas != NO_SQ)
                {
                    if(sq - 9 == enPas)
                        list.addMove(constructMove(sq, sq - 9, 0, 0, MFLAGEP));
                    if(sq - 11 == enPas)
                        list.addMove(constructMove(sq, sq - 11, 0, 0, MFLAGEP));
                }
            }

            if(castlePerm & BKCA)
                if(pieces[F8] is null && pieces[G8] is null)
                    if(!sqAttacked(E8, WHITE) && !sqAttacked(F8, WHITE))
                        list.addMove(constructMove(E8, G8, EMPTY, EMPTY, MFLAGCA));

            if(castlePerm & BQCA)
                if(pieces[D8] is null && pieces[C8] is null && pieces[B8] is null)
                    if(!sqAttacked(E8, WHITE) && !sqAttacked(D8, WHITE))
                        list.addMove(constructMove(E8, C8, EMPTY, EMPTY, MFLAGCA));
        }

        foreach(i; 1..bK+1)
        {
            foreach(j; 0..this.pceNum[i])
            {
                pce = pList[i][j];
                if(pce.color() != side || pce.isPawn()) continue;
                assert(SqOnBoard(pce.sq()));

                if(pce.slides())
                {
                    auto mov = pce.getDir(pce.type());
                    for(index = 0; index < 8; index++)
                    {
                        dir = mov[index];
                        if(dir == 0) continue;
                        t_sq = pce.sq() + dir;
                        while(FilesBrd[t_sq] != OFFBOARD)
                        {
                            if(pieces[t_sq] !is null)
                            {
                                if(pieces[t_sq].color() == (side ^ 1))
                                    list.addMove(constructMove(pce.sq(), t_sq, pieces[t_sq].type(), 0, 0));
                                break;
                            }
                            list.addMove(constructMove(pce.sq(), t_sq, 0, 0, 0));
                            t_sq += dir;
                        }
                    }
                }
                else
                {
                    auto mov = pce.getDir(pce.type());
                    for(index = 0; index < 8; index++)
                    {
                        dir = mov[index];
                        t_sq = pce.sq() + dir;
                        if(dir == 0 || FilesBrd[t_sq] == OFFBOARD) continue;
                        if(pieces[t_sq] !is null)
                        {
                            if(pieces[t_sq].color() == (side ^ 1))
                                list.addMove(constructMove(pce.sq(), t_sq, pieces[t_sq].type(), 0, 0));
                        }
                        else list.addMove(constructMove(pce.sq(), t_sq, 0, 0, 0));
                    }
                }
            }
        }

        //ASSERT(MoveListOk(list,pos));
        return list;
    }

    auto generateAllCaps() @nogc
    {
        struct MoveList
        {
            private
            {
                Move[MAXPOSITIONMOVES] moves;
                int count;
                int frontIndex;
            }

            void addMove(Move m) pure nothrow @nogc
            {
                moves[count++] = m;
            }

            bool empty() pure nothrow @nogc @property
            {
                return frontIndex == count;
            }

            Move front() pure nothrow @nogc @property
            {
                return moves[frontIndex];
            }

            void popFront() pure nothrow @nogc
            {
                if(frontIndex < count) frontIndex++;
            }

            int length() pure nothrow @nogc @property
            {
                return count;
            }

            Move opIndex(int i) pure @nogc
            {
                assert(i < 0 || i >= count);
                return moves[i];
            }
        }

        MoveList list;
        list.count = 0;

        Piece pce;
        int t_sq;
        int sq;
        int pceNum;
        int dir;
        int index;

        if(side == WHITE)
        {
            for(pceNum = 0; pceNum < this.pceNum[wP]; ++pceNum)
            {
                sq = pList[wP][pceNum].sq();
                assert(SqOnBoard(sq));

                if(FilesBrd[sq + 9] != OFFBOARD && pieces[sq + 9] !is null && pieces[sq + 9].color() == BLACK)
                {
                    if(RanksBrd[sq] != RANK_7) list.addMove(constructMove(sq, sq + 9, pieces[sq + 9].type(), 0, 0));
                    else
                    {
                        list.addMove(constructMove(sq, sq+9, pieces[sq + 9].type(), wN, 0));
                        list.addMove(constructMove(sq, sq+9, pieces[sq + 9].type(), wB, 0));
                        list.addMove(constructMove(sq, sq+9, pieces[sq + 9].type(), wR, 0));
                        list.addMove(constructMove(sq, sq+9, pieces[sq + 9].type(), wQ, 0));
                    }
                }

                if(FilesBrd[sq + 11] != OFFBOARD && pieces[sq + 11] !is null && pieces[sq + 11].color() == BLACK)
                {
                    if(RanksBrd[sq] != RANK_7) list.addMove(constructMove(sq, sq + 11, pieces[sq + 11].type(), 0, 0));
                    else
                    {
                        list.addMove(constructMove(sq, sq+11, pieces[sq + 11].type(), wN, 0));
                        list.addMove(constructMove(sq, sq+11, pieces[sq + 11].type(), wB, 0));
                        list.addMove(constructMove(sq, sq+11, pieces[sq + 11].type(), wR, 0));
                        list.addMove(constructMove(sq, sq+11, pieces[sq + 11].type(), wQ, 0));
                    }
                }

                if(enPas != NO_SQ)
                {
                    if(sq + 9 == enPas)
                        list.addMove(constructMove(sq, sq + 9, 0, 0, MFLAGEP));
                    if(sq + 11 == enPas)
                        list.addMove(constructMove(sq, sq + 11, 0, 0, MFLAGEP));
                }
            }
        }
        else
        {
            for(pceNum = 0; pceNum < this.pceNum[bP]; ++pceNum)
            {
                sq = pList[bP][pceNum].sq();
                assert(SqOnBoard(sq));

                if(FilesBrd[sq - 9] != OFFBOARD && pieces[sq - 9] !is null && pieces[sq - 9].color() == WHITE)
                {
                    if(RanksBrd[sq] != RANK_2) list.addMove(constructMove(sq, sq - 9, pieces[sq - 9].type(), 0, 0));
                    else
                    {
                        list.addMove(constructMove(sq, sq-9, pieces[sq - 9].type(), bN, 0));
                        list.addMove(constructMove(sq, sq-9, pieces[sq - 9].type(), bB, 0));
                        list.addMove(constructMove(sq, sq-9, pieces[sq - 9].type(), bR, 0));
                        list.addMove(constructMove(sq, sq-9, pieces[sq - 9].type(), bQ, 0));
                    }
                }

                if(FilesBrd[sq - 11] != OFFBOARD && pieces[sq - 11] !is null && pieces[sq - 11].color() == WHITE)
                {
                    if(RanksBrd[sq] != RANK_2) list.addMove(constructMove(sq, sq - 11, pieces[sq - 11].type(), 0, 0));
                    else
                    {
                        list.addMove(constructMove(sq, sq-11, pieces[sq - 11].type(), bN, 0));
                        list.addMove(constructMove(sq, sq-11, pieces[sq - 11].type(), bB, 0));
                        list.addMove(constructMove(sq, sq-11, pieces[sq - 11].type(), bR, 0));
                        list.addMove(constructMove(sq, sq-11, pieces[sq - 11].type(), bQ, 0));
                    }
                }

                if(enPas != NO_SQ)
                {
                    if(sq - 9 == enPas)
                        list.addMove(constructMove(sq, sq + 9, 0, 0, MFLAGEP));
                    if(sq - 11 == enPas)
                        list.addMove(constructMove(sq, sq + 11, 0, 0, MFLAGEP));
                }
            }
        }

        foreach(i; 1..bK)
        {
            foreach(j; 0..this.pceNum[i])
            {
                pce = pList[i][j];
                if(pce.color() != side) continue;
                assert(SqOnBoard(pce.sq()));

                if(pce.slides())
                {
                    for(index = 0; index < 8; index++)
                    {
                        dir = pce.getDir(pce.type())[index];
                        if(dir == 0) continue;
                        t_sq = pce.sq() + dir;
                        while(FilesBrd[t_sq] != OFFBOARD)
                        {
                            if(pieces[t_sq] !is null)
                            {
                                if(pieces[t_sq].color() == (side ^ 1))
                                    list.addMove(constructMove(pce.sq(), t_sq, pieces[t_sq].type(), 0, 0));
                                break;
                            }
                            t_sq += dir;
                        }
                    }
                }
                else
                {
                    for(index = 0; index < 8; index++)
                    {
                        dir = pce.getDir(pce.type())[index];
                        t_sq = pce.sq() + dir;
                        if(dir == 0 || FilesBrd[t_sq] == OFFBOARD) continue;
                        if(pieces[t_sq] !is null)
                        {
                            if(pieces[t_sq].color() == (side ^ 1))
                                list.addMove(constructMove(pce.sq(), t_sq, pieces[t_sq].type(), 0, 0));
                        }
                    }
                }
            }
        }

        //ASSERT(MoveListOk(list,pos));

        return list;
    }

    Move parseMove(string newMove)
    {
        if(newMove[1] > '8' || newMove[1] < '1') return NOMOVE;
        if(newMove[3] > '8' || newMove[3] < '1') return NOMOVE;
        if(newMove[0] > 'h' || newMove[0] < 'a') return NOMOVE;
        if(newMove[2] > 'h' || newMove[2] < 'a') return NOMOVE;

        int from = FR2SQ(newMove[0] - 'a', newMove[1] - '1');
        int to = FR2SQ(newMove[2] - 'a', newMove[3] - '1');

        assert(SqOnBoard(from) && SqOnBoard(to));

        int promPce = EMPTY;

        foreach(move; generateAllMoves())
        {
            if(move.fromsq() == from && move.tosq() ==to)
            {
                promPce = move.promoted();
                if(promPce != EMPTY && (newMove[4] == 'r' || newMove[4] == 'b' || newMove[4] == 'q'|| newMove[4] == 'n'))
                {
                    if((promPce == wR || promPce == bR) && newMove[4] == 'r')
                        return move;
                    else if((promPce == wB || promPce == bB) && newMove[4] == 'b')
                        return move;
                    else if((promPce == wN || promPce == bN) && newMove[4] == 'n')
                        return move;
                    else if((promPce == wQ || promPce == bQ) && newMove[4] == 'q')
                        return move;

                    continue;
                }
                return move;
            }
        }

        return NOMOVE;
    }
}

struct Undo
{
	Move move;
	ubyte castlePerm;
	int enPas;
	int fiftyMove;
	ulong posKey;
}
