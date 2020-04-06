            .ORG    3230h 
; 
; 
            STARTADR    EQU         0000h ;32A0H - 428FH
            ENDADR      EQU         00FEFh
            BUFFADR     EQU         8040H		
            LNG         EQU         END - STARTMOVE

            LXI     H, STARTMOVE
            LXI     D, BUFFADR
            MVI     C, LNG
            
LOADER:
            MOV     A, M
            INX     H
            XCHG
            MOV     M, A
            INX     H
            XCHG
            DCR     C
            JNZ     LOADER
            JMP     BUFFADR

DB 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00 
            ;.ORG BUFFADR
STARTMOVE:
            LXI     H, STARTADR
            LXI     B, ENDADR

START:
            MOV A,M
            OUT 20H
            MOV M,A
            OUT 20H
            INX H
            MOV A, B
            CMP  H
            JNZ START
            MOV A, C
            CMP L
            JNZ START
            
            OUT     20h
           
            JMP     0000h
db 0,0,0,0
BACK2ROM:   OUT     20h
            JMP     0000h
END:
