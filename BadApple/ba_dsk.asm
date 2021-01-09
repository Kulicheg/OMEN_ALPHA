                        .ORG    0100h
DAT     EQU 01h
STCP    EQU 02h
SHCP    EQU 04h
RESET   EQU 08h
BDIR    EQU 10h
BC1     EQU 20h
PORT    EQU 05h

            

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


            LXI     SP, 0DBFFh
            MVI     C, 03h                  ;Disk D
            CALL    SELDSK
            CALL    SECTREAD
            CALL    HOMESCR
            
            LXI     H, DMAHERE
            MVI     B, 32            
            
START:
            MOV     A, M
            ORA     A
            JZ      NEXTFR
            CALL    BYTE2DOTS
            
            PUSH    H
            LXI     H, SCTPOS
            DCR M
            CZ      NXTSCT   
            POP     H
            INX     H
            
            JMP      START            
NEXTFR:

            PUSH    H
            INX     H
            MOV     A, M
            ORA     A
            JZ      END
            MVI     B, 32
            CALL    HOMESCR
            JMP     START
END:                        
            LXI     D, 0h
            MVI     C, 0h
            CALL    5 
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
            MOV     D, A            ; Цвет в регистре C DDD
            MVI     A, 07Fh         ; 01111111
            ANA     E
            MOV     E, A            ; Длинна  полосы в регистре E
            DCR     D               ;  Если результат  стал 0, рисуем точку
            JZ      DRAWDOT
DRAWSPC:
            MVI     C, "."          ; "."
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
            CALL    WAIT20MS
            POP     D
            ;POP     B
            POP     H
            RET           

HOMESCR:

            MVI     C, 01Bh         ; "ESC"            
            CALL    CONOUT
            MVI     C, "["          ; "["            
            CALL    CONOUT
            MVI     C, "H"          ; "H"            
            CALL    CONOUT            
            
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


        CALL    INIT8255OUT
        CALL    AYRESET


STARTPOS EQU MODULE + 06h
        LXI     H, STARTPOS

        CALL     PLAYER
        JMP     0000
        
AYRESET:      
        PUSH    B
        PUSH    D
        MVI     B, 00h
        CALL    SERIALOUT
        MVI     A,00h   
        OUT     PORT  
        MVI     A,08h   
        OUT     PORT   
        POP     B
        POP     D
        RET
        
SERIALOUT:      
        PUSH    B        ; регистр B пусть будет с байтом
        PUSH    D        ; регистр C пусть будет выводиться в порт
        MVI     E, 08h   ; D будет содержать бит данных в младшем разряде
        
       
NEXTBIT:      
        
        MOV     A, B    ; берем наш байт
        RLC             ; Сдвигаем его вправо
        MOV     B, A    ; Возвращаем на будущее
        MOV     D, B    ; Берем B копируем в D
        
        MVI     A, 01h  ; Применяем D 00000001  
        ANA     D       ; чтобы получить в нем только один первый бит
        MOV     D, A
        ADD     C       ; в A у нас бит мы просто его прибавляем к C 0 или 1
        OUT     PORT    ; Выводим в порт 
        NOP             ; Нужно подождать перед фиксацией.
        ADI     04h     ; Поднимаем в С(A) 2(SHCP)
        OUT     PORT    ; Выводим в порт 
        SUI     04h     ; Опускаем С 2(SHCP)
        OUT     PORT    ; Выводим в порт
        SUB     D       ; Вертаем взад бит чтобы не уехать после второй 1
        OUT     PORT    ; Выводим в порт
        MOV     C, A    ; Сохраняем  наше C  
        DCR     E       ; Уменьшаем счетчик
        JNZ   NEXTBIT   ; Цикл пошел
                        ; байт выставлен на 595
        MVI     A, 02h  ; 
        ORA     C       ; установить бит 1(STCP) в 1
        OUT     PORT    ; Вывести в порт 05
        SUI     02h     ; установить бит 1(STCP) в 0
        OUT     PORT    ; Вывести в порт 05
        POP   D   
        POP   B   
        RET      

INIT8255OUT:      
        MVI     A, 80h   
        OUT     07h   
        RET      

REGSET:
;DAT     EQU 01h
;STCP    EQU 02h
;SHCP    EQU 04h
;RESET   EQU 08h
;BDIR    EQU 10h
;BC1     EQU 20h
;HL адрес/данные
    
        MVI     C, RESET                ; Сначала мы должны в C установить бит 1(STCP) в 0
                                        ; Установить в C бит 3 в 1(AY RESET)
                                        ; digitalWrite(BC1, LOW);
                                        ; digitalWrite(BCDIR, LOW);
                                        ; //write address
        MOV     B, H                    ; Теперь в B адрес регистра
        CALL    SERIALOUT               ; SPI.transfer(address);

        MVI     A,  BC1 + BDIR + RESET  ; digitalWrite(BC1, HIGH);
        OUT     PORT                    ; digitalWrite(BCDIR, HIGH);

        MVI     A,  RESET               ; digitalWrite(BC1, LOW);
        OUT     PORT                    ; digitalWrite(BCDIR, LOW);
                                        ; //write data
        MVI     A, BDIR + RESET         ; digitalWrite(BC1, LOW);
        OUT     PORT                    ; digitalWrite(BCDIR, HIGH);
        
        MVI     C, BDIR + RESET

        MOV     B, L                    ; Теперь в B данные регистра               
        CALL    SERIALOUT               ; SPI.transfer(data);
        OUT     PORT                
                                        ; digitalWrite(BC1, LOW);
                                        ; digitalWrite(BCDIR, LOW);
        RET

MINILOOP:
        PUSH    D   
        MVI     D, 0FFh   
MINILOOP2:
        NOP      
        DCR   D   
        JNZ   MINILOOP2   
        POP   D   
        RET      




PLAYER:
        PUSH    H
        LXI     H,HELLOSTR
        CALL    TXTOUT
        POP     H

PLAYER2:        
        MOV     A, M
        
        CPI     010h
        JNC  PLAYER3
        
       
        MOV     D, M
        INX     H
        MOV     E, M
        XCHG
        CALL    REGSET
        XCHG
        
        JMP     PLAYER4

PLAYER3:  
        CPI     0FFh
        CZ      WAIT20MS        
        
        CPI     0FEh
        CZ      WAITNX80MS
        
        CPI     0FDh
        CZ      ENDSONG

PLAYER4:       
        INX     H
        JMP     PLAYER2    
        RET
        

WAITNX80MS:
                                    ;80.01 ms
        PUSH    D   
        INX     H
        MOV     D, M   

WAITNX80MS2:
        MVI     E, 04h
WAIT80MS:
        CALL    WAIT20MS
        DCR     E
        JNZ     WAIT80MS

        DCR     D   
        JNZ     WAITNX80MS2   
        POP     D   
        RET






WAIT20MS:
                            ;20.01 ms
        PUSH    D   
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
        XTHL
        XTHL
        
        DCR   D   
        JNZ   WAIT20MS2   
        POP   D   
        RET

ENDSONG:
        CALL    AYRESET
        LXI     H, BYESTR
        CALL    TXTOUT  
        JMP     END

TXTOUT:     
            CALL    WAITOUT 
            MOV     A, M 
            ANI     07Fh ;drop 8th bit
            OUT     0DFh 
            MOV     A, M 
            ANI     80h 
            RNZ      
            INX     H 
            JMP     TXTOUT   
            

BYTEOUT:    
                            ; ВХОД C  - Байт для вывода
            CALL    WAITOUT ; Выход A - Отправленный байт
            MOV     A, C
            OUT     0DFh 
            RET
             
        
HELLOSTR:   .ISTR   "Kulich PSG PLAYER 2020", 10, 13
BYESTR:     .ISTR   "END SONG. BYE."        , 10, 13



;Offset Number of byte Description
;+0 3   Identifier 'PSG'
;+3 1   Marker “End of Text” (1Ah)
;+4 1   Version number
;+5 1   Player frequency (for versions 10+)
;+6 10  Data

;Data — последовательности пар байтов записи в регистр.
;Первый байт — номер регистра (от 0 до 0x0F), второй — значение.
;Вместо номера регистра могут быть специальные маркеры: 0xFF, 0xFE или 0xFD
;0xFD — конец композиции.
;0xFF — ожидание 20 мс.
;0xFE — следующий байт показывает сколько раз выждать по 80 мс.

SECTREAD:
            PUSH    B
            PUSH    H
            
            LXI     B, DMAHERE
            CALL    SETDMA
            LXI     H, TRACK
            MOV     C, M
            CALL    SETTRK
            LXI     H, SECTR
            MOV     C, M
            CALL    SETSEC
            CALL    READ
            POP     H
            POP     B
            RET

NXTSCT:

            LXI     H, SECTR
            INR     M
            
            LXI     H, SCTPOS
            MVI     M, 7Fh
            
            CALL    SECTREAD
            POP     H
            LXI     H, DMAHERE
            PUSH    H
            RET


TRACK:
DB 00h

SECTR:
DB 00h

SCTPOS:
DB 7Fh
            ;.ORG 01000h
DMAHERE:
DB 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
DB 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
DB 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
DB 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
DB 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
DB 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
DB 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
DB 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h


MODULE:
DB 01Fh, 081h, 01Fh, 081h, 01Fh, 081h, 01Fh, 081h, 01Fh, 081h, 01Fh, 081h, 01Fh, 081h, 01Fh, 081h
TOP:
.cstr  "END HERE"

