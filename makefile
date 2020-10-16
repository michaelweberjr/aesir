# Windows makefile for building libchess, aesir and 

# Debug flags
DFLAGS= -debug -g -unittest -w -property
# Release flags
RFLAGS= -release -O -inline -boundscheck=off

# libchess files
SRC_LC= libchess\board.d libchess\hash.d libchess\bitboard.d libchess\defs.d libchess\piece.d \
    libchess\validate.d libchess\move.d libchess\perft.d libchess\pieces\pawn.d libchess\pieces\knight.d \
    libchess\pieces\bishop.d libchess\pieces\rook.d libchess\pieces\queen.d libchess\pieces\king.d

# aesir files
SRC_AESIR= aesir\aesir.d aesir\search.d aesir\evaluate.d aesir\io.d aesir\position.d

debug: libchessd.lib aesird.exe


aesird.exe: libchessd.lib $(SRC_AESIR)
	dmd $(DFLAGS) -ofaesird.exe libchessd.lib $(SRC_AESIR)

libchessd.lib : $(SRC_LC)
	dmd $(DFLAGS) -oflibchessd.lib -lib $(SRC_LC)


release: libchess.lib aesir.exe


aesir.exe: libchess.lib $(SRC_AESIR)
	dmd $(RFLAGS) -ofaesir.exe libchess.lib $(SRC_AESIR)

libchess.lib: $(SRC_LC)
	dmd $(RFLAGS) -oflibchess.lib -lib $(SRC_LC)

clean:
	del *.exe
	del *.lib
	del *.obj

