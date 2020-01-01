            .ORG    8100H 
; 
; 
XPOS        EQU     80F0H ;X(XPOS)
YPOS        EQU     80F1H ;Y(YPOS)
WPOS        EQU     80F2H ;W(WPOS)
HPOS        EQU     80F3H ;H(HPOS)
ATTR        EQU     80F4H ;FC(ATTR)
ATTR2       EQU     80F5H ; -UU BC(33013)
FILLCHR     EQU     80F6H ;char(FILLCHR)
; 
START:               
; 
            LXI     H,33792 ;		    8400
            SHLD    32992 ;			RAMSTART
            LXI     H,64512 ;		    FC00		
            SHLD    32994 ;			RAMEND
; 
;            CALL    CLEARMEM
; 
            MVI     A,21 ;ACIA init
            OUT     222 


            LXI     H,ATTR
            MVI     M,32 
            CALL    SETATTRIB 
            LXI     H,ATTR
            MVI     M,40 
            CALL    SETATTRIB 


            CALL    CLEARSCR 
; 
; 
LOOP:                
; 
            LXI     H,XPOS ;Save X
            MVI     M,1 
            LXI     H,YPOS ;Save Y
            MVI     M,1 
            LXI     H,WPOS ;Save W
            MVI     M,5 
            LXI     H,HPOS ;Save H
            MVI     M,24 
            LXI     H,FILLCHR ;Save CHAR
            MVI     M,32 
            LXI     H,ATTR ;Save FC
            MVI     M,40 
            CALL    SETATTRIB 
            CALL    RECTDRAW 
; 
            LXI     H,XPOS ;Save X
            MVI     M,6 
            LXI     H,YPOS ;Save Y
            MVI     M,1 
            LXI     H,WPOS ;Save W
            MVI     M,5 
            LXI     H,HPOS ;Save H
            MVI     M,24 
            LXI     H,FILLCHR ;Save CHAR
            MVI     M,48 
            LXI     H,ATTR ;Save FC
            MVI     M,41 
            CALL    SETATTRIB 
            CALL    RECTDRAW 
; 
            LXI     H,XPOS ;Save X
            MVI     M,11 
            LXI     H,YPOS ;Save Y
            MVI     M,1 
            LXI     H,WPOS ;Save W
            MVI     M,5 
            LXI     H,HPOS ;Save H
            MVI     M,24 
            LXI     H,FILLCHR ;Save CHAR
            MVI     M,49 
            LXI     H,ATTR ;Save FC
            MVI     M,42 
            CALL    SETATTRIB 
            CALL    RECTDRAW 
; 
            LXI     H,XPOS ;Save X
            MVI     M,16 
            LXI     H,YPOS ;Save Y
            MVI     M,1 
            LXI     H,WPOS ;Save W
            MVI     M,5 
            LXI     H,HPOS ;Save H
            MVI     M,24 
            LXI     H,FILLCHR ;Save CHAR
            MVI     M,50 
            LXI     H,ATTR ;Save FC
            MVI     M,43 
            CALL    SETATTRIB 
            CALL    RECTDRAW 
; 
            LXI     H,XPOS ;Save X
            MVI     M,21 
            LXI     H,YPOS ;Save Y
            MVI     M,1 
            LXI     H,WPOS ;Save W
            MVI     M,5 
            LXI     H,HPOS ;Save H
            MVI     M,24 
            LXI     H,FILLCHR ;Save CHAR
            MVI     M,51 
            LXI     H,ATTR ;Save FC
            MVI     M,44 
            CALL    SETATTRIB 
            CALL    RECTDRAW 
; 
            LXI     H,XPOS ;Save X
            MVI     M,26 
            LXI     H,YPOS ;Save Y
            MVI     M,1 
            LXI     H,WPOS ;Save W
            MVI     M,5 
            LXI     H,HPOS ;Save H
            MVI     M,24 
            LXI     H,FILLCHR ;Save CHAR
            MVI     M,52 
            LXI     H,ATTR ;Save FC
            MVI     M,45 
            CALL    SETATTRIB 
            CALL    RECTDRAW 
; 
            LXI     H,XPOS ;Save X
            MVI     M,31 
            LXI     H,YPOS ;Save Y
            MVI     M,1 
            LXI     H,WPOS ;Save W
            MVI     M,5 
            LXI     H,HPOS ;Save H
            MVI     M,24 
            LXI     H,FILLCHR ;Save CHAR
            MVI     M,53 
            LXI     H,ATTR ;Save FC
            MVI     M,46 
            CALL    SETATTRIB 
            CALL    RECTDRAW 
; 
            LXI     H,XPOS ;Save X
            MVI     M,36 
            LXI     H,YPOS ;Save Y
            MVI     M,1 
            LXI     H,WPOS ;Save W
            MVI     M,5 
            LXI     H,HPOS ;Save H
            MVI     M,24 
            LXI     H,FILLCHR ;Save CHAR
            MVI     M,54 
            LXI     H,ATTR ;Save FC
            MVI     M,47 
            CALL    SETATTRIB 
            CALL    RECTDRAW 
; 
            LXI     H,XPOS ;Save X
            MVI     M,41 
            LXI     H,YPOS ;Save Y
            MVI     M,1 
            LXI     H,WPOS ;Save W
            MVI     M,5 
            LXI     H,HPOS ;Save H
            MVI     M,24 
            LXI     H,FILLCHR ;Save CHAR
            MVI     M,48 
            LXI     H,ATTR ;Save FC
            MVI     M,30 
            CALL    SETATTRIB 
            CALL    RECTDRAW 
; 
            LXI     H,XPOS ;Save X
            MVI     M,46 
            LXI     H,YPOS ;Save Y
            MVI     M,1 
            LXI     H,WPOS ;Save W
            MVI     M,5 
            LXI     H,HPOS ;Save H
            MVI     M,24 
            LXI     H,ATTR ;Save CHAR
            MVI     M,49 
            LXI     H,ATTR ;Save FC
            MVI     M,31 
            CALL    SETATTRIB 
            CALL    RECTDRAW 
; 
            LXI     H,XPOS ;Save X
            MVI     M,51 
            LXI     H,YPOS ;Save Y
            MVI     M,1 
            LXI     H,WPOS ;Save W
            MVI     M,5 
            LXI     H,HPOS ;Save H
            MVI     M,24 
            LXI     H,FILLCHR ;Save CHAR
            MVI     M,50 
            LXI     H,ATTR ;Save FC
            MVI     M,32 
            CALL    SETATTRIB 
            CALL    RECTDRAW 
; 
            LXI     H,XPOS ;Save X
            MVI     M,56 
            LXI     H,YPOS ;Save Y
            MVI     M,1 
            LXI     H,WPOS ;Save W
            MVI     M,5 
            LXI     H,HPOS ;Save H
            MVI     M,24 
            LXI     H,FILLCHR ;Save CHAR
            MVI     M,51 
            LXI     H,ATTR ;Save FC
            MVI     M,33 
            CALL    SETATTRIB 
            CALL    RECTDRAW 
; 
            LXI     H,XPOS ;Save X
            MVI     M,61 
            LXI     H,YPOS ;Save Y
            MVI     M,1 
            LXI     H,WPOS ;Save W
            MVI     M,5 
            LXI     H,HPOS ;Save H
            MVI     M,24 
            LXI     H,FILLCHR ;Save CHAR
            MVI     M,52 
            LXI     H,ATTR ;Save FC
            MVI     M,34 
            CALL    SETATTRIB 
            CALL    RECTDRAW 
; 
            LXI     H,XPOS ;Save X
            MVI     M,66 
            LXI     H,YPOS ;Save Y
            MVI     M,1 
            LXI     H,WPOS ;Save W
            MVI     M,5 
            LXI     H,HPOS ;Save H
            MVI     M,24 
            LXI     H,FILLCHR ;Save CHAR
            MVI     M,53 
            LXI     H,ATTR ;Save FC
            MVI     M,35 
            CALL    SETATTRIB 
            CALL    RECTDRAW 
; 
            LXI     H,XPOS ;Save X
            MVI     M,71 
            LXI     H,YPOS ;Save Y
            MVI     M,1 
            LXI     H,WPOS ;Save W
            MVI     M,5 
            LXI     H,HPOS ;Save H
            MVI     M,24 
            LXI     H,FILLCHR ;Save CHAR
            MVI     M,54 
            LXI     H,ATTR ;Save FC
            MVI     M,36 
            CALL    SETATTRIB 
            CALL    RECTDRAW 
; 
            LXI     H,XPOS ;Save X
            MVI     M,76 
            LXI     H,YPOS ;Save Y
            MVI     M,1 
            LXI     H,WPOS ;Save W
            MVI     M,5 
            LXI     H,HPOS ;Save H
            MVI     M,24 
            LXI     H,FILLCHR ;Save CHAR
            MVI     M,55 
            LXI     H,ATTR ;Save FC
            MVI     M,37 
            CALL    SETATTRIB 
            CALL    RECTDRAW 
            CALL    CLEARSCR
            CALL    HELLO
            RET      







; 
SETCURSOR:           
            LXI     H,SETCURSORSTR + 2 
            XCHG     ; DE<->HL
            LHLD    YPOS ;80F0->HL Y
            MVI     A,2 
            MVI     H,0 
            CALL    IWASC 
; 
            LXI     H,SETCURSORSTR + 5 
            XCHG     ; DE<->HL
            LHLD    XPOS ;80F0->HL X
            MVI     A,2 
            MVI     H,0 
            CALL    IWASC 
; 
            LXI     H,SETCURSORSTR 
            CALL    TXTOUT 
            RET      
; 
WAITOUT:    IN      222 
            ANI     02 
            JZ      WAITOUT 
            RET      
; 
; 
HOMESCR:             
            LXI     H,HOMESTR 
            CALL    TXTOUT 
            RET      
; 
CLEARSCR:            
            LXI     H,XPOS 
            MVI     M,1 
            LXI     H,YPOS 
            MVI     M,1 
            LXI     H,WPOS 
            MVI     M,80 
            LXI     H,HPOS 
            MVI     M,25 
            LXI     H,FILLCHR 
            MVI     M,32 
            CALL    RECTDRAW

            LXI     H,CLSSTR 
            CALL    TXTOUT 
            RET      


; 
TXTOUT:     CALL    WAITOUT 
            MOV     A,M 
            ANI     7Fh ;drop 8th bit
            OUT     223 
            MOV     A,M 
            ANI     80h 
            RNZ      
            INX     H 
            JMP     TXTOUT 
; 
RECTDRAW:            ;Draws rectangle
; 
;80F0H	X(XPOS)
;80F1H	Y(YPOS)
;80F2H	W(WPOS)
;80F3H	H(HPOS)
;80F4H	FC(ATTR)
;80F5H	BC(33013)
;80F6H	char(FILLCHR)
; 
; 
            CALL    SETCURSOR 
            LXI     H,WPOS ;Load W
            MOV     B,M 
            LXI     H,HPOS ;Load H
            MOV     C,M 
; 
COLUMNS:    CALL    WAITOUT 
            LDA     FILLCHR ; 
            OUT     223 
            DCR     B 
            JNZ     COLUMNS 
            DCR     C 
            RZ       
            LXI     H,YPOS 
            INR     M 
            CALL    SETCURSOR 
            LXI     H,WPOS ;Load W
            MOV     B,M 
            JMP     COLUMNS 
; 
; 
; 
;0	Reset all attributes
;1	Bright
;2	Dim
;4	Underscore	
;5	Blink
;7	Reverse
;8	Hidden
; 
;	Foreground Colours
;30	Black
;31	Red
;32	Green
;33	Yellow
;34	Blue
;35	Magenta
;36	Cyan
;37	White
; 
;	Background Colours
;40	Black
;41	Red
;42	Green
;43	Yellow
;44	Blue
;45	Magenta
;46	Cyan
;47	White
; 
SETATTRIB:           
; 
            LXI     H,SETATTRIBSTR + 2 
            XCHG     ; DE<->HL
            LHLD    ATTR ;80F0->HL FC
            MVI     A,2 
            MVI     H,0 
            CALL    IWASC 
; 
            LXI     H,SETATTRIBSTR 
            CALL    TXTOUT 
            RET      
; 
; 
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
            LDA     32994 ;RAMEND(L)
            XRA     L 
            JNZ     CLEARMEM2 
            MVI     M,0 
            RET      
;
; .ISTR adds 80h  automaticaly 
;--------------CONST STRINGS Stored in ROM-------------- 
HELLOSTR:    .ISTR   "Kulich System Extension 1.0 2020(c)",0Dh,0Ah
HELLOSTR1:   .ISTR   "--------------------------------------------",0Dh,0Ah
HELLOSTR2:   .ISTR   "SETCURSOR sets cursor at XPOS, YPOS",0Dh,0Ah
HELLOSTR3:   .ISTR   "HOMESCR puts cursor at home position",0Dh,0Ah
HELLOSTR4:   .ISTR   "CLEARSCR and drops all attribs to G/B",0Dh,0Ah
HELLOSTR5:   .ISTR   "TXTOUT Prints text from HL",0Dh,0Ah
HELLOSTR6:   .ISTR   "RECTDRAW Draw rectangle X,Y,H,W,A,C",0Dh,0Ah
HELLOSTR7:   .ISTR   "SETATTRIB print VT100 color attribs",0Dh,0Ah
HELLOSTR8:   .ISTR   "CLEARMEM from '80E0H' to '80E2H'",0Dh,0Ah
;
HOMESTR:    .ISTR   1Bh,"[H" 
; 
CLSSTR:     .ISTR   1Bh,"[2J",1Bh,"[H",1Bh,"[40;32;1m"
;
;--------------CHANGABLE STRINGS Stored in RAM-------------- 
; 
SETCURSORSTR: .ISTR 1Bh,"[00;00H" 
; 
SETATTRIBSTR: .ISTR 1Bh,"[00m" 
; 


HELLO:

            LXI     H,HELLOSTR 
            CALL    TXTOUT 
            LXI     H,HELLOSTR1
            CALL    TXTOUT 
            LXI     H,HELLOSTR2
            CALL    TXTOUT 
            LXI     H,HELLOSTR3
            CALL    TXTOUT 
            LXI     H,HELLOSTR4
            CALL    TXTOUT 
            LXI     H,HELLOSTR5
            CALL    TXTOUT 
            LXI     H,HELLOSTR6
            CALL    TXTOUT 
            LXI     H,HELLOSTR7
            CALL    TXTOUT
            LXI     H,HELLOSTR8
            CALL    TXTOUT 
            RET









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
