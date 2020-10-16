module aesir.io;

import libchess.move;
import aesir.position;

interface IO
{
    void loop(Position pos);
    void postMove(Move move);
    void postThinking(int bestScore, int currentDepth, Position pos);
}
