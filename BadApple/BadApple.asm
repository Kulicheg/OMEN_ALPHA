            .ORG 9000h

            ;CALL    HOMESCR
            LXI     H, 9500h
            
START:
            MVI     B, 32           ; Длинна строки
            MOV     A, M
            ORA     A
            JZ      NEXTFR
            CALL    BYTE2DOTS
            INX     H
            JP      START            
            
NEXTFR:
            
            JMP     NEXTFR



END:                        
            JMP     0000


BYTE2DOTS:
        
            ; Процедура берет байт и выводит 8 пикселей
            ; HL - Адрес  байта

            PUSH    H
            PUSH    B
            PUSH    D
            MOV     D, M            ; Загружаем  байт
            MOV     E, D            ; кэшируем  данные        
            MVI     A, 080h         ; 10000000
            ANA     D               ; Отбрасываем младшую часть и получаем цвет
            RLC
            MOV     D, A            ; Цвет в регистре C
            MVI     A, 07Fh         ; 01111111
            ANA     E
            MOV     E, A            ; Длинна  полосы в регистре E
            DCR     D               ;  Если результат  стал 0, рисуем точку
            JZ      DRAWDOT
DRAWSPC:
            MVI     C, 02Eh         ; ".."
            CALL    CONOUT2         ; Печатаем  ".."
            DCR     B
            CZ      NEWLNSCR
            DCR     E
            JNZ     DRAWSPC
            JMP     DRWEXIT
DRAWDOT:    
            MVI     C, 02Ah         ; "*"
            CALL    CONOUT2         ; Печатаем  "**"
            DCR     B
            CZ      NEWLNSCR
            DCR     E
            JNZ     DRAWDOT
            
DRWEXIT:    
            
            POP     D
            POP     B
            POP     H
            RET           
            
            
CONIN:	    IN   0DEh	;READ CONSOLE STATUS.
	        ANI  01h	;IF NOT READY,
	        JZ   CONIN	;LOOP UNTIL LOW
	        IN   0DFh	;READ A CHARACTER.
	        ANI  7Fh	;MAKE MOST SIG. BIT = 0.
	        RET		    ;RETURN FROM CONIN.

WAITIN:     IN      0DEh 
            ANI     01 
            JZ      WAITIN 
            RET              
           
; 
CONOUT2:                            ; DOUBLE PRINT    
            CALL    WAITOUT
            MOV     A, C
            OUT     0DFh 
            CALL    WAITOUT
            MOV     A, C
            OUT     0DFh 
            RET
WAITOUT:    
            IN      0DEh 
            ANI     02h 
            JZ      WAITOUT 
            RET                 

CONOUT:                            
            CALL    WAITOUT
            MOV     A, C
            OUT     0DFh 
            RET

HOMESCR:
            PUSH    B
            MVI     C, 01Bh         ; "ESC"            
            CALL    CONOUT
            MVI     C, "["          ; "["            
            CALL    CONOUT
            MVI     C, "H"          ; "H"            
            CALL    CONOUT            
            POP     B
            RET

NEWLNSCR:
            PUSH    B
            MVI     C, 0Ah          ; "CARRIAGE RETURN"            
            CALL    CONOUT
            MVI     C, 0Dh          ; "LINE FEED"            
            CALL    CONOUT            
            POP     B
            MVI     B, 32           ; Обнуляем  счетчик длинны
            RET








            .ORG 09500h
DATAHERE:
DB 0B6h, 001h, 09Eh, 003h, 09Dh, 005h, 099h, 008h, 097h, 009h, 097h, 009h, 096h, 00Bh, 095h, 000h
