                .ORG    07FE0h
            
STARTADR        EQU     06700h
TARGTADR        EQU     0DC00h
ENDADR			EQU		07FFFh
LNG             EQU     01900h

            LXI     H, STARTADR
            LXI     D, TARGTADR
            LXI     B, LNG
            
LOADER:
            MOV     A, M
            INX     H
            XCHG
            MOV     M, A
            INX     H
            XCHG
            DCX     B
            MVI     A, 00
            CMP     B
            JNZ     LOADER
            MVI     A, 00
            CMP     C
            JNZ     LOADER
            JMP     0F200h 
