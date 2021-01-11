boot        EQU     0F200h   ;cold start
wboot       EQU     0F203h   ;warm start
const       EQU     0F206h   ;console status
conin       EQU     0F209h   ;console character in
conout      EQU     0F20Ch   ;console character out
list        EQU     0F20Fh   ;list character out
punch       EQU     0F212h   ;punch character out
reader      EQU     0F215h   ;reader character out
home        EQU     0F218h   ;move head to home position
seldsk      EQU     0F21Bh   ;select disk
settrk      EQU     0F21Eh   ;set track number
setsec      EQU     0F221h   ;set sector number
setdma      EQU     0F224h   ;set dma address
read        EQU     0F227h   ;read disk
write       EQU     0F22Ah   ;write disk
listst      EQU     0F22Dh   ;return list status
sectran     EQU     0F230h   ;sector translate


.ORG    0100h
            LXI     SP, 0DBFFh
            CALL    HOMESCR
            LXI     H, DATAHERE
            MVI     B, 32           ; Длинна строки
            
START:
            
            MOV     A, M
            ORA     A
            JZ      NEXTFR
            CALL    BYTE2DOTS
            INX     H
            JP      START            
            
NEXTFR:
            
            INX     H
            MOV     A, M
            ORA     A
            JZ      END
            MVI     B, 32
            CALL    HOMESCR
            
            PUSH    D
            CALL    WAITNX80MS2
            POP     D
            JMP     START



END:                        
            LXI     D, 0h
            MVI     C, 0h
            CALL    5


BYTE2DOTS:
        
            ; Процедура берет байт и выводит 8 пикселей
            ; HL - Адрес  байта

            PUSH    H
            ;PUSH    B
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
            MVI     C, 20h         ; "."
            CALL    CONOUT2         ; Печатаем  ".."
            DCR     B
            CZ      NEWLNSCR
            DCR     E
            JNZ     DRAWSPC
            JMP     DRWEXIT
DRAWDOT:    
            MVI     C, 0FBh         ; "*"
            CALL    CONOUT2         ; Печатаем  "**"
            DCR     B
            CZ      NEWLNSCR
            DCR     E
            JNZ     DRAWDOT
            
DRWEXIT:    
            
            POP     D
            ;POP     B
            POP     H
            RET           
            
            
 
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

CONOUT1:                            
            CALL    WAITOUT
            MOV     A, C
            OUT     0DFh 
            RET

HOMESCR:

            MVI     C, 01Bh         ; "ESC"            
            CALL    CONOUT1
            MVI     C, "["          ; "["            
            CALL    CONOUT1
            MVI     C, "H"          ; "H"            
            CALL    CONOUT1            
            
            RET

NEWLNSCR:

            MVI     C, 0Ah          ; "CARRIAGE RETURN"            
            CALL    CONOUT1
            MVI     C, 0Dh          ; "LINE FEED"            
            CALL    CONOUT1            
            MVI     B, 32           ; Обнуляем  счетчик длинны
            RET


                                    

WAITNX80MS2:                        ;70.01 ms

        MVI     E, 04h
WAIT80MS:
        CALL    WAIT20MS
        DCR     E
        JNZ     WAIT80MS
        RET

WAIT20MS:
        MVI     D, 0FFh  
WAIT20MS2:
        XTHL
        XTHL 
        XTHL 
        XTHL 
        XTHL 
        XTHL 
        XTHL    ;FOR ALPHA+
        XTHL 
        XTHL 
        XTHL 
        XTHL 
        XTHL
        XTHL 
        XTHL 
        DCR   D   
        JNZ   WAIT20MS2   
        RET
DB 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00 
DATAHERE:
.cstr  "Start..."
