10 DEF FN AT$ (X,Y)     = CHR$(27) + "[" + MID$(STR$(Y),2) + ";" + MID$(STR$(X),2) + "H"
20 DEF FN ATR$ (ATR)    = CHR$(27) + "[" + MID$(STR$(ATR),2) + "m"
30 DEF FN CLS$ (DUMMY)  = CHR$(27) + "c"
40 DEF FN HOME$ (DUMMY) = CHR$(27) + "[H"
50 DEF FN RST$ (DUMMY)  = CHR$(27) + "[2J" + CHR$(27) + "[H" + CHR$(27) + "[40;32;0m"

90 PRINT FN CLS$(0);
100 PRINT FN ATR$(1);
110 FOR Q = 1 TO 100
115 PRINT FN ATR$(INT(RND*8)+30);
120 PRINT FN AT$(INT(RND*81), INT(RND*26)) + "*";
130 NEXT Q

150 PRINT FN RST$(0);
200 END

9000 PRINT FN ATR$(40);
9010 PRINT FN ATR$(32);
9020 PRINT FN ATR$(1);
9030 PRINT FN HOME$(0);