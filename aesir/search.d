module aesir.search;

import std.concurrency;
import std.datetime.systime;
import std.datetime;
import std.algorithm;

import libchess.defs;
import libchess.move;
import libchess.board;

import aesir.io;
import aesir.position;
import aesir.evaluate;

int rootDepth;

private int abs(int x)
{
    return x < 0 ? -x : x;
}

private int isRepetition(Board pos)
{
    int index = 0;

	for(index = pos.hisPly - pos.fiftyMove; index < pos.hisPly-1; ++index)
    {
		assert(index >= 0 && index < MAXGAMEMOVES);
		if(pos.posKey == pos.history[index].posKey) return true;
	}

	return false;
}

private int quiescence(int alpha, int beta, Position pos)
{
	assert(beta > alpha);

	if(pos.info.stop) return alpha;

	if((pos.info.nodes & 2047) == 0)
    {
		if(Clock.currTime().fracSecs.split!"msecs".msecs > pos.info.stopTime)
        {
            pos.info.stop = true;
        }
        else if(receiveTimeout(dur!"hnsecs"(0), (string s) { if(s == "quit") pos.info.stop = true; }))
        {
            return alpha;
        }
	}

	pos.info.nodes++;

	if(isRepetition(pos) || pos.fiftyMove >= 100) return 0;

	if(pos.ply > MAXDEPTH - 1) return evalPosition(pos);

	int score = evalPosition(pos);

	assert(score > -INFINITE && score < INFINITE);

	if(score >= beta) return beta;

	if(score > alpha) alpha = score;

	auto list = pos.generateAllCaps().assignBasicEval(pos);

    int moveNum = 0;
	int legal = false;
	score = -INFINITE;

	foreach(move; list)
	{
		legal++;
		pos.makeMove(move.move);
		score = -quiescence(-beta,-alpha, pos);
		pos.takeMove();

		if(pos.info.stop) return 0;

		if(score > alpha)
        {
			if(score >= beta)
            {
				if(legal==1) pos.info.fhf++;
				pos.info.fh++;
				return beta;
			}
			alpha = score;
		}
    }

	//assert(alpha >= oldAlpha);

	return alpha;
}

private int alphaBeta(int alpha, int beta, int depth, Position pos, int doNull = false)
{
	assert(beta>alpha);
	assert(depth>=0);

	if(depth <= 0)
    {
		return quiescence(alpha, beta, pos);
	}

	if(pos.info.stop) return alpha;

	if((pos.info.nodes & 2047) == 0)
    {
		if(Clock.currTime().fracSecs.split!"msecs".msecs > pos.info.stopTime)
        {
            pos.info.stop = true;
        }
        else if(receiveTimeout(dur!"hnsecs"(0), (string s) { if(s == "quit") pos.info.stop = true; }))
        {
            return alpha;
        }
	}

	pos.info.nodes++;

	if((isRepetition(pos) || pos.fiftyMove >= 100) && pos.ply > 0) return 0;

	if(pos.ply > MAXDEPTH - 1) return evalPosition(pos);

    bool inCheck = pos.inCheck();
	if(inCheck) depth++;

	int score = -INFINITE;
	int pvMove = NOMOVE;

	/*if(ProbeHashEntry(pos, &PvMove, &Score, alpha, beta, depth) == TRUE )
    {
		pos->HashTable->cut++;
		return Score;
	}*/

	if(doNull && !inCheck && pos.ply > 0 && pos.bigPce[pos.side] > 0 && depth >= 4)
    {
		pos.makeNullMove();
		score = -alphaBeta( -beta, -beta + 1, depth-4, pos);
		pos.takeNullMove();

		if(pos.info.stop) return 0;

		if(score >= beta && abs(score) < ISMATE)
        {
			pos.info.nullCut++;
			return beta;
		}
	}

    auto list = pos.generateAllMoves().assignBasicEval(pos);

	int legal = 0;
	int oldAlpha = alpha;
	int bestMove = NOMOVE;

	int bestScore = -INFINITE;

	score = -INFINITE;

	if(pvMove != NOMOVE)
		foreach(move; list)
			if(move.move == pvMove)
			{
				move.score = 2000000;
				break;
			}

	foreach(move; list)
    {
		legal++;
        pos.makeMove(move.move);
		score = -alphaBeta(-beta, -alpha, depth-1, pos, true);
		pos.takeMove();

		if(pos.info.stop) return 0;

		if(score > bestScore) {
			bestScore = score;
			bestMove = move.move;

			if(score > alpha)
            {
				if(score >= beta)
                {
					if(legal == 1) pos.info.fhf++;
					pos.info.fh++;

					if(!(move.move & MFLAGCAP))
                    {
						pos.searchKillers[1][pos.ply] = pos.searchKillers[0][pos.ply];
						pos.searchKillers[0][pos.ply] = move.move;
					}

					//storeHashEntry(pos, BestMove, beta, HFBETA, depth);

					return beta;
				}

				alpha = score;

				if(!(move.move & MFLAGCAP))
					pos.searchHistory[pos.pieces[bestMove.fromsq()].type()][bestMove.tosq()] += depth;
			}
		}
    }

	if(legal == 0)
    {
		if(inCheck)	return -INFINITE + pos.ply;
		else return 0;
	}

	assert(alpha>=oldAlpha);

	/*if(alpha != OldAlpha)
		StoreHashEntry(pos, BestMove, BestScore, HFEXACT, depth);
	else
		StoreHashEntry(pos, BestMove, alpha, HFALPHA, depth);*/

	return alpha;
}

void search(IO io, Position pos) {

	int bestMove = NOMOVE;
	int bestScore = -INFINITE;
	int currentDepth = 0;
	int pvMoves = 0;
	int pvNum = 0;

	//ClearForSearch(pos, info);

	//if(pos.info.useBook)
        //bestMove = getBookMove(pos);

	// iterative deepening
	if(bestMove == NOMOVE)
    {
        for(currentDepth = 1; currentDepth <= pos.info.depth; ++currentDepth )
        {
                                // alpha	 beta
            rootDepth = currentDepth;
            bestScore = alphaBeta(-INFINITE, INFINITE, currentDepth, pos, true);

            if(pos.info.stop) break;

            //pvMoves = getPvLine(currentDepth, pos);
            bestMove = pos.pvArray[0];

            //pvMoves = getPvLine(currentDepth, pos);
            io.postThinking(bestScore, currentDepth, pos);

            //writefln("Hits:%d Overwrite:%d NewWrite:%d Cut:%d\nOrdering %.2f NullCut:%d\n",pos->HashTable->hit,pos->HashTable->overWrite,pos->HashTable->newWrite,pos->HashTable->cut,
            //(info->fhf/info->fh)*100,info->nullCut);
        }
    }

    //io.postMove(prMove(move));
    io.postMove(bestMove);
}
