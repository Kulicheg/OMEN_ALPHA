            .ORG    8100H 
; 
; 
XPOS        EQU     80F0H ;X(XPOS)
YPOS        EQU     80F1H ;Y(YPOS)
WPOS        EQU     80F2H ;W(WPOS)
HPOS        EQU     80F3H ;H(HPOS)
ATTR        EQU     80F4H ;BC(ATTR)
ATTR2       EQU     80F5H ;FC(33013)
FILLCHR     EQU     80F6H ;char(FILLCHR)
TMP2B       EQU     80FEH ;temp USE WITH CAUTION + 80FFH
; 
START:               
;
            CALL ACIAINIT

            LXI     H,33792 ;		    8400
            SHLD    32992 ;			RAMSTART
            LXI     H,64512 ;		    FC00		
            SHLD    32994 ;			RAMEND
; 
;            CALL    CLEARMEM
; 

            LXI     H,ATTR 
            MVI     M,40 
            LXI     H,ATTR2 
            MVI     M,1 
; 
LOOP:       CALL    SETATTRIB
            CALL    CLEARSCR 
            LXI     H,XPOS ;Save X
            MVI     M,40 
            LXI     H,YPOS ;Save Y
            MVI     M,12 
            CALL    SETCURSOR
            
            MVI     C, 46
            CALL    BYTEOUT
            MVI     C,  20
CHARSET:    CALL    BYTEOUT
            INR     C
            SUI     7Fh        
            JNZ     CHARSET
            CALL WAITIN
            
            
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
            CALL    RECTDRAW 
            
            CALL    BYTEIN
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
            
            CALL    BYTEIN
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
            LXI     H,ATTR2 ;Save FC
            MVI     M,42 
            CALL    SETATTRIB 
            CALL    RECTDRAW 
            
            CALL    BYTEIN
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
            
            CALL    BYTEIN
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

            CALL    BYTEIN
            CALL    CLEARSCR
            RET      


ACIAINIT:   MVI     A, 15h ;ACIA init (21) 115200-8-N-1
            OUT     0DEh 
            RET

WAITIN:     IN      0DEh 
            ANI     01 
            JZ      WAITIN 
            RET      

BYTEIN:     
            CALL    WAITIN 
            IN     0DFh 
            RET
            

BYTEOUT:    
                            ; ВХОД C  - Байт для вывода
            CALL    WAITOUT ; Выход A - Отправленный байт
            MOV     A, C
            OUT     0DFh 
            RET

; 
SETCURSOR:           
            
            PUSH    H
            PUSH    D
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
            
            POP     D
            POP     H
            RET      
; 
WAITOUT:    


            IN      0DEh 
            ANI     02h 
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
;80F4H	1C(ATTR)
;80F5H	2C(ATTR2)
;80F6H	char(FILLCHR)
;80F7H  TEMP
;80F8H  TEMP
; 

            CALL    SETCURSOR 
            CALL    SETATTRIB 

            LXI     H,YPOS 
            MOV     B,M 
            PUSH    B 
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
            JZ      COLUMNS2 
            LXI     H,YPOS 
            INR     M 
            CALL    SETCURSOR 
            LXI     H,WPOS ;Load W
            MOV     B,M 
            JMP     COLUMNS 
COLUMNS2:            
            POP     B 
            MOV     A,B 
            STA     YPOS 
            RET      
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
            
            LXI     H,SETATTRIBSTR + 5 
            XCHG     ; DE<->HL
            LHLD    ATTR2 ;80F0->HL BC
            MVI     A,2 
            MVI     H,0 
            CALL    IWASC 
; 
            LXI     H,SETATTRIBSTR 
            CALL    TXTOUT 
            RET      
; 
DEFATTRIB:           
            LXI     H,DEFATTRIBSTR 
            CALL    TXTOUT 
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
            LDA     32994 ;RAMEND(L)
            XRA     L 
            JNZ     CLEARMEM2 
            MVI     M,0 
            RET      
; 
; .ISTR adds 80h  automaticaly
;--------------CONST STRINGS Stored in ROM--------------
;HELLOSTR:    .ISTR   "Kulich System Extension 1.0 2020(c)",0Dh,0Ah
;HELLOSTR1:   .ISTR   "--------------------------------------------",0Dh,0Ah
;HELLOSTR2:   .ISTR   "SETCURSOR sets cursor at XPOS, YPOS",0Dh,0Ah
;HELLOSTR3:   .ISTR   "HOMESCR   puts cursor at home position",0Dh,0Ah
;HELLOSTR4:   .ISTR   "CLEARSCR  and drops all attribs to G/B",0Dh,0Ah
;HELLOSTR5:   .ISTR   "TXTOUT    Prints text from HL",0Dh,0Ah
;HELLOSTR6:   .ISTR   "RECTDRAW  Draw rectangle X,Y,H,W,A,C",0Dh,0Ah
;HELLOSTR7:   .ISTR   "SETATTRIB Print VT100 color attribs",0Dh,0Ah
;HELLOSTR8:   .ISTR   "CLEARMEM  from '80E0H' to '80E2H'",0Dh,0Ah
;HELLOSTR8:   .ISTR   "DEFATTR  Quick reset to G/B w/o changin MEM",0Dh,0Ah
;HELLOSTR9:   .ISTR   "--------------------------------------------",0Dh,0Ah
; 
HOMESTR:    .ISTR   1Bh,"[H" 
; 
CLSSTR:     .ISTR   1Bh,"c"
;
CLSSTR2:     .ISTR   1Bh,"[2J",1Bh,"[H",1Bh,"[40;32;0m" 
; 
DEFATTRIBSTR: .ISTR 1Bh,"[40;32;1m" 

DUMMYSTR:   .ISTR   "               ABOUT" 
; 
;--------------CHANGABLE STRINGS Stored in RAM--------------
; 
SETCURSORSTR: .ISTR 1Bh,"[00;00H" 
; 
SETATTRIBSTR: .ISTR 1Bh,"[00;00m" 
; 


;HELLO:
; 
            CALL    CLEARSCR
            CALL    HOMESCR
;            LXI     H,HELLOSTR
;            CALL    TXTOUT
;            LXI     H,HELLOSTR1
;            CALL    TXTOUT
;            LXI     H,HELLOSTR2
;            CALL    TXTOUT
;            LXI     H,HELLOSTR3
;            CALL    TXTOUT
;            LXI     H,HELLOSTR4
;            CALL    TXTOUT
;            LXI     H,HELLOSTR5
;            CALL    TXTOUT
;            LXI     H,HELLOSTR6
;            CALL    TXTOUT
;            LXI     H,HELLOSTR7
;            CALL    TXTOUT
;            LXI     H,HELLOSTR8
;            CALL    TXTOUT
;            LXI     H,HELLOSTR9
;            CALL    TXTOUT
;            RET
ABOUT:  DB  17,06,45,12,47,30,32
DB "      Kulich System Extension 0.1 2020      ",255
;   1---------------------+---------------------4 5
ABODY:
DB "CLEARSCR  and drops all attribs to G/B       "
DB "HOMESCR   puts cursor at home position       "
DB "SETCURSOR sets cursor at XPOS, YPOS          "
DB "TXTOUT    Prints text from adress @ HL       "
DB "SETATTRIB Print 2 VT100 color attribs        "
DB "RECTDRAW  Draw rectangle X,Y,H,W,A,C         "
DB "CLEARMEM  from '80E0H' to '80E2H'            "
DB "DEFATTR   Quick reset to G/B w/o MEM         "
DB "DRAWWINDOW  Draws window like this           "
DB "WAITIN    Wait for any key                   "
DB "BYTEIN    Read byte from console with wait   "
DB "BYTEOUT   Print byte from C                  "
DB "80F0H XPOS 80F1H YPOS 80F2H WPOS 80F3H HPOS  "
DB "80F4H ATTR 80F5H ATTR2 80F6H FILLCHR   "
DB 255
DRAWWINDOW:          
;(HL - data adress)
;XPOS YPOS WPOS HPOS ATTR ATTR2 CHR
;TITLE STRING
;BODY TEXT
;*********************
;*       TITLE       *
;*                   *
;*                   *
;*                   *
;*       [OK]        *
;*********************


            MOV     A,M 
            STA     XPOS 
            INX     H 
            MOV     A,M 
            STA     YPOS 
            INX     H 
            MOV     A,M 
            STA     WPOS 
            INX     H 
            MOV     A,M 
            STA     HPOS 
            INX     H 
            MOV     A,M 
            STA     ATTR
            INX     H 
            MOV     A,M 
            STA     ATTR2
            INX     H 
            MOV     A,M 
            STA     FILLCHR 

            CALL    RECTDRAW 


;---TITLE------------------------------------------
            LXI     H,HPOS 
            MOV     B,M
            LXI     H,ATTR 
            MOV     C,M 
            PUSH    B 
            MVI     A,1 
            STA     HPOS 
            MVI     A,41 ; TODO INVERSION OF  COLOR
            STA     ATTR 
            CALL    RECTDRAW 
            POP     B 
            MOV     A,B 
            STA     HPOS
            MOV     A,C 
            STA     ATTR
            CALL    SETCURSOR 
            LXI     H,ABOUT + 7 
            CALL    TXTOUT 
            ;CALL    SETATTRIB

;---BODY--------------------------------------------
            
            
            LXI     H,ATTR2
            MVI     M, 30

            LDA     XPOS 
            MOV     B,A 
            LDA     YPOS 
            MOV     C,A 
            PUSH    B 
            LDA     HPOS 
            MOV     B,A 
            LDA     ATTR 
            MOV     C,A 
            PUSH    B 

            LXI     H,ATTR2
            MVI     M, 30
            CALL SETATTRIB
            
            
            LXI     H,ABODY

DRAWWINDOW2:
            
            PUSH    H
            
            LXI     H,YPOS 
            INR     M               ;down to  body
            CALL    SETCURSOR
            LXI     H,WPOS
            MOV     E,M 
            POP     H
DRAWWINDOW3:  
            CALL    WAITOUT 
            MOV     A,M 
            ANI     7Fh ;drop 8th bit
            OUT     223 
            MOV     A,M 
            ANI     80h 
            JNZ     DRAWWINDOW4 
            INX     H 
            DCR     E 
            JNZ     DRAWWINDOW3 
            PUSH    H
            LXI     H,WPOS 
            MOV     E,M 
            POP     H
            JMP     DRAWWINDOW2


DRAWWINDOW4:         
;----------------------------------------------------
            POP     B 
            MOV     A,C 
            STA     ATTR 
            MOV     A,B 
            STA     HPOS ; RESTORING COORDS
            POP     B 
            MOV     A,C 
            STA     YPOS 
            MOV     A,B 
            STA     XPOS 


            CALL    DEFATTRIB 
            CALL    HOMESCR 
            RET      

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




