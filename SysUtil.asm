; 
            .ORG    8100H 
; 
8100H:      JMP     START 
8110H:      JMP     CLEARSCR 
8113H:      JMP     SETCURSOR 
; 
; 
START:               
; 
; 
            MVI     A,21 ;ACIA init
            OUT     222 
; 
; 
            CALL    CLEARSCR 
; 
LOOP:       MVI     A,20 
            LXI     H,33009 ;X
;MVI 	M, 10		;10
            MOV     M,A ;A
            LXI     H,33008 ;Y
;MVI 	M, A		;5
            MOV     M,A ;A
            CALL    SETCURSOR 
            CALL    HELLO 
; 
            DCR     A 
            JNZ     LOOP 
; 
            RET      
; 
; 
; 
; 
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
HELLO:               
            LXI     H,HELLOSTR 
; 
HELLO2:              
            CALL    WAITOUT 
            MOV     A,M 
            ANI     7Fh 
            OUT     223 
            MOV     A,M 
            ANI     80h 
            RNZ      
            INX     H 
            JMP     HELLO2 
; 
; 
; 
; 
HELLOSTR:   .ISTR   "Hello this cruel world!",0Dh,0Ah 
; 
CLSSTR:     .ISTR   1Bh,"[2J",1Bh,"[H" ;,0Ah 
; 
SETCURSORSTR: .ISTR 1Bh,"[00;00H" ;,0Ah ; 
; 
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

