            .ORG    8100H 
; 
START:               
; 
            LXI     H,33792 ;		    8400
            SHLD    32992 ;			RAMSTART
            LXI     H,64512 ;		    FC00		
            SHLD    32994 ;			RAMEND
; 
            CALL    CLEARMEM 
; 
            MVI     A,21 ;ACIA init
            OUT     222 
; 
            CALL    CLEARSCR 
; 
            LXI     H,33008 ;Save X
            MVI     M,10 
            LXI     H,33009 ;Save Y
            MVI     M,5 
            LXI     H,33010 ;Save W
            MVI     M,10 
            LXI     H,33011 ;Save H
            MVI     M,5 
            LXI     H,33014 ;Save CHAR
            MVI     M,46 
LOOP:                
            CALL    RECTDRAW
            
            CALL HOMESCR
            RET      
; 
SETCURSOR:           
; 
; 
; 
            LXI     H,SETCURSORSTR + 2 
            XCHG     ; DE<->HL
            LHLD    33009 ;80F0->HL Y
            MVI     A,2 
            MVI     H,0 
; 
            CALL    IWASC 
; 
            LXI     H,SETCURSORSTR + 5 
            XCHG     ; DE<->HL
            LHLD    33008 ;80F0->HL X
            MVI     A,2 
            MVI     H,0 
            CALL    IWASC 
; 
; 
            LXI     H,SETCURSORSTR 
; 
SETCURSOR2:          
            CALL    WAITOUT 
            MOV     A,M 
            ANI     7Fh 
            OUT     223 
            MOV     A,M 
            ANI     80h 
            RNZ      
            INX     H 
            JMP     SETCURSOR2 
; 
; 
            RET      
; 
WAITOUT:    IN      222 
            ANI     02 
            JZ      WAITOUT 
; 
            RET      
; 
; 

HOMESCR: 
            LXI     H,HOMESTR 
            CALL    TXTOUT
            RET

CLEARSCR:            
            LXI     H,CLSSTR 
; 
CLEARSCR2:           
            CALL    WAITOUT 
            MOV     A,M 
            ANI     7Fh 
            OUT     223 
            MOV     A,M 
            ANI     80h 
            RNZ      
            INX     H 
            JMP     CLEARSCR2 
; 
; 
; 
; 
; 
; 
; 
TXTOUT:     CALL    WAITOUT 
            MOV     A,M 
            ANI     7Fh 
            OUT     223 
            MOV     A,M 
            ANI     80h 
            RNZ      
            INX     H 
            JMP     TXTOUT 
; 
; 
; 
RECTDRAW:            ;Draws rectangle
;Y(33008)
;80F0H	X(33008)
;80F1H	Y(33009)
;80F2H	W(33010)
;80F3H	H(33011)
;80F4H	FC
;80F5H	BC
;80F6H	char(33014)
; 
            CALL    SETCURSOR 
            LXI     H,33010 ;Load W
            MOV     B,M 
            LXI     H,33011 ;Load H
            MOV     C,M 
; 
COLUMNS:    CALL    WAITOUT 
            LXI     H,33014 ;Load char 2do speedup
            MOV     A,M 
            OUT     223 
            DCR     B 
            JNZ     COLUMNS 
            DCR     C 
            RZ       
            LXI     H,33009
            INR     M
            CALL    SETCURSOR 
            LXI     H,33010 ;Load W
            MOV     B,M 
            JMP     COLUMNS 
; 
; 
; 
            RET      
; 
CLEARMEM:            ;Clear memory from RAMSTART to RAMEND with 00h
;80E0H	RAMSTART(32992)
;80E2H	RAMEND (32994)
; 
            LHLD    32992 ;RAMSTART
CLEARMEM2:  MVI     M,0 
; 
            LDA     32995 ;RAMEND(H)
            INX     H 
            XRA     H 
            JNZ     CLEARMEM2 
; 
            LDA     32994 ;RAMEND(L)
            XRA     L 
            JNZ     CLEARMEM2 
            MVI     M,0 
            RET      
; 
; 
; 
; 
; 
; 
; 
; 
; 
HELLOSTR:       .ISTR   "Hello this cruel world!",0Dh,0Ah 
; 
CLSSTR:         .ISTR   1Bh,"[2J",1Bh,"[H" ;,0Ah
; 
SETCURSORSTR:   .ISTR   1Bh,"[00;00H" ;,0Ah ;
; 
HOMESTR:        .ISTR   1Bh,"[H"
; 
; 
; 
; 
; 
;**************************************
;  SUBROUTINE IWASC
;**************************************
; 
; преобразование: целое-->десятичное
; 
; INP: /HL/-целое, /DE/ - адрес буфера
;      /A/ -код формата
; 
;      A(7) :
;       1 - преобразование со знаком
;       0 - преобразование абсолютных величин
; 
;      A(6..0) - число цифр результата
; 
IWASC:               
            PUSH    PSW 
            PUSH    B 
            PUSH    H 
            MOV     B,A 
            ANA     H 
            MOV     C,A 
            MOV     A,B 
            ANI     7FH 
            MOV     B,A 
            XCHG     
RA500:               
            DCR     A 
            JM      FA500 
            MVI     M,"0" 
            INX     H 
            JMP     RA500 
FA500:               
            XCHG     
            PUSH    D 
            MOV     A,C 
            CPI     0 
            CM      CNHL 
            XRA     A 
LA501:               
            DCR     B 
            JM      WA501 
            CALL    DVTEN 
            DCX     D 
            ADI     30H 
            STAX    D 
            MOV     A,H 
            ORA     L 
            JNZ     LA501 
WA501:               
            XCHG     
            MOV     A,C 
            CPI     0 
            JP      IA502 
            DCR     B 
            JM      IA503 
            DCX     H 
            MVI     M,"-" 
IA503:               
IA502:               
            INR     B 
            DCR     B 
            JP      IA504 
            MVI     M,"*" 
IA504:               
            POP     D 
            POP     H 
            POP     B 
            POP     PSW 
            RET      
; 
; 
;  SUBROUTINE DVTEN (вспомогательная)
;**************************************
; 
DVTEN:               
            PUSH    B 
            PUSH    D 
            MOV     A,H 
            RAR      
            MOV     D,A 
            MOV     A,L 
            RAR      
            MOV     E,A 
            MVI     L,0 
            MOV     A,L 
            RAR      
            MOV     H,A 
            XRA     A 
            MOV     A,D 
            RAR      
            MOV     D,A 
            MOV     A,E 
            RAR      
            MOV     E,A 
            MOV     A,H 
            RAR      
            MOV     H,A 
            MVI     C,0DH 
LB200:               
            MOV     A,D 
;	ADI	0-50H:100H	; C6B0
            ADI     0B0H 
            JNC     $+4 
            MOV     D,A 
            MOV     A,L 
            RAL      
            MOV     L,A 
            MOV     A,H 
            RAL      
            MOV     H,A 
            DCR     C 
            JM      $+12 
            MOV     A,E 
            RAL      
            MOV     E,A 
            MOV     A,D 
            RAL      
            MOV     D,A 
            JMP     LB200 
WB200:               
            MOV     A,D 
            RRC      
            RRC      
            RRC      
            POP     D 
            POP     B 
            RET      
; 
; 
; 
;**************************************
;    SUBROUTINE CNHL
;**************************************
; 
;  /HL/=/-HL/
; 
CNHL:                
            PUSH    PSW 
            MOV     A,L 
            CMA      
            MOV     L,A 
            MOV     A,H 
            CMA      
            MOV     H,A 
            INX     H 
            POP     PSW 
            RET      
; 
; 
; 
; 
; 
; 

