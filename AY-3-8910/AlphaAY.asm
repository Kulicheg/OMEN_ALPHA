; Пиноут для 8255
; 0 - Данные (MOSI)
; 1 - STCP защелка (SS)
; 2 - SHCP такт для данных(SCK)
; 3 - AY RESET
; 4 - BDIR
; 5 - BC1
DAT     EQU 01h
STCP    EQU 02h
SHCP    EQU 04h
RESET   EQU 08h
BDIR    EQU 10h
BC1     EQU 20h
PORT    EQU 05h
PADR    EQU 8100h
        
        .ORG   PADR
START:     
        CALL    INIT8255OUT
        CALL    AYRESET


STARTPOS    EQU MODULE + 06h
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
        MVI     D, 0F0h  
WAIT20MS2:
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
        JMP     0000h

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

WAITOUT:    


            IN      0DEh 
            ANI     02h 
            JZ      WAITOUT 
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






    .ORG    PADR + 200h
MODULE:
DB  050h ,053h ,047h ,01Ah ,000h ,000h ,000h ,000h ,000h ,000h ,000h ,000h ,000h ,000h ,000h ,000h ,0FFh ,000h ,0F1h ,001h ,005h ,002h ,091h ,004h ,07Ch ,005h ,001h ,007h ,030h ,008h ,00Fh ,009h ,00Dh ,00Ah ,00Eh ,0FFh ,002h ,094h ,004h ,0BEh ,005h ,000h ,007h ,038h ,009h ,00Eh ,0FFh ,002h ,097h ,0FFh ,008h ,00Eh ,00Ah ,00Dh ,0FFh ,004h ,07Ch ,005h ,001h ,009h ,00Dh ,0FFh ,0FFh ,002h ,098h ,008h ,00Dh ,009h ,00Ch ,00Ah ,00Ch ,0FFh ,004h ,0BEh ,005h ,000h ,0FFh ,002h ,097h ,0FFh ,002h ,096h ,008h ,00Ch ,00Ah ,00Bh ,0FFh ,002h ,095h ,004h ,07Ch ,005h ,001h ,009h ,00Bh ,0FFh ,0FFh ,000h ,073h ,001h ,004h ,002h ,0B8h ,004h ,0FBh ,007h ,030h ,008h ,00Fh ,009h ,00Dh ,00Ah ,00Eh ,0FFh ,002h ,0BBh ,007h ,038h ,008h ,00Eh ,009h ,00Eh ,00Ah ,00Dh ,0FFh ,002h ,0BEh ,004h ,0FEh ,005h ,000h ,0FFh ,0FFh ,008h ,00Dh ,009h ,00Dh ,00Ah ,00Ch ,0FFh ,004h ,0FBh ,005h ,001h ,0FFh ,002h ,0BFh ,009h ,00Ch ,0FFh ,008h ,00Ch ,00Ah ,00Bh ,0FFh ,002h ,0BEh ,004h ,0FEh ,005h ,000h ,0FFh ,002h ,0BDh ,009h ,00Bh ,0FFh ,002h ,0BCh ,008h ,00Bh ,00Ah ,00Ah ,0FFh ,004h ,0FBh ,005h ,001h ,009h ,00Ah ,0FFh ,000h ,0F7h ,001h ,003h ,002h ,0A3h ,004h ,0ABh ,007h ,030h ,008h ,00Fh ,009h ,00Dh ,00Ah ,00Eh ,0FFh ,002h ,0A6h ,007h ,038h ,009h ,00Eh ,0FFh ,002h ,0A9h ,008h ,00Eh ,00Ah ,00Dh ,0FFh ,004h ,0D5h ,005h ,000h ,0FFh ,009h ,00Dh ,0FFh ,008h ,00Dh ,00Ah ,00Ch ,0FFh ,002h ,0AAh ,004h ,0ABh ,005h ,001h ,009h ,00Ch ,0FFh ,0FFh ,002h ,0A9h ,008h ,00Ch ,00Ah ,00Bh ,0FFh ,002h ,0A8h ,004h ,0D5h ,005h ,000h ,0FFh ,002h ,0A7h ,009h ,00Bh ,0FFh ,008h ,00Bh ,00Ah ,00Ah ,0FFh ,000h ,055h ,002h ,0CFh ,004h ,03Ah ,005h ,002h ,007h ,030h ,008h ,00Fh ,009h ,00Dh ,00Ah ,00Eh ,0FFh ,002h ,0D2h ,007h ,038h ,009h ,00Eh ,0FFh ,002h ,0D5h ,0FFh ,008h ,00Eh ,00Ah ,00Dh ,0FFh ,004h ,01Dh ,005h ,001h ,009h ,00Dh ,0FFh ,0FFh ,002h ,0D6h ,008h ,00Dh ,009h ,00Ch ,00Ah ,00Ch ,0FFh ,004h ,03Ah ,005h ,002h ,0FFh ,002h ,0D5h ,0FFh ,002h ,0D4h ,008h ,00Ch ,009h ,00Bh ,00Ah ,00Bh ,0FFh ,002h ,0D3h ,004h ,01Dh ,005h ,001h ,0FFh ,009h ,00Ah ,0FFh ,000h ,0F8h ,001h ,002h ,002h ,0B8h ,004h ,0FBh ,007h ,030h ,008h ,00Fh ,009h ,00Dh ,00Ah ,00Eh ,0FFh ,002h ,0BBh ,004h ,0FEh ,005h ,000h ,007h ,038h ,008h ,00Eh ,009h ,00Eh ,00Ah ,00Dh ,0FFh ,002h ,0BEh ,004h ,0FBh ,005h ,001h ,0FFh ,0FFh ,008h ,00Dh ,009h ,00Dh ,00Ah ,00Ch ,0FFh ,004h ,0FEh ,005h ,000h ,0FFh ,002h ,0BFh ,009h ,00Ch ,0FFh ,008h ,00Ch ,00Ah ,00Bh ,0FFh ,002h ,0BEh ,004h ,0FBh ,005h ,001h ,0FFh ,002h ,0BDh ,0FFh ,002h ,0BCh ,008h ,00Bh ,009h ,00Bh ,00Ah ,00Ah ,0FFh ,004h ,0FEh ,005h ,000h ,0FFh ,000h ,055h ,001h ,003h ,002h ,0CFh ,004h ,03Ah ,005h ,002h ,007h ,030h ,008h ,00Fh ,009h ,00Dh ,00Ah ,00Eh ,0FFh ,002h ,0D2h ,004h ,01Dh ,005h ,001h ,007h ,038h ,009h ,00Eh ,0FFh ,002h ,0D5h ,008h ,00Eh ,00Ah ,00Dh ,0FFh ,004h ,03Ah ,005h ,002h ,0FFh ,009h ,00Dh ,0FFh ,008h ,00Dh ,00Ah ,00Ch ,0FFh ,000h ,0F8h ,001h ,002h ,002h ,0B8h ,004h ,0FBh ,005h ,001h ,007h ,030h ,008h ,00Fh ,00Ah ,00Eh ,0FFh ,002h ,0BBh ,004h ,0FEh ,005h ,000h ,007h ,038h ,009h ,00Eh ,0FFh ,002h ,0BEh ,0FFh ,008h ,00Eh ,009h ,00Dh ,00Ah ,00Dh ,0FFh ,004h ,0FBh ,005h ,001h ,0FFh ,009h ,00Ch ,0FFh ,002h ,0BFh ,008h ,00Dh ,00Ah ,00Ch ,0FFh ,004h ,0FEh ,005h ,000h ,0FFh ,002h ,0BEh ,0FFh ,002h ,0BDh ,008h ,00Ch ,00Ah ,00Bh ,0FFh ,002h ,0BCh ,004h ,0FBh ,005h ,001h ,0FFh ,0FFh ,002h ,0BDh ,008h ,00Bh ,00Ah ,00Ah ,0FFh ,002h ,0BEh ,004h ,0FEh ,005h ,000h ,0FFh ,002h ,0BFh ,0FFh ,008h ,00Ah ,00Ah ,009h ,0FFh ,002h ,0BEh ,004h ,0FBh ,005h ,001h ,0FFh ,002h ,0BDh ,0FFh ,002h ,0BCh ,008h ,009h ,00Ah ,008h ,0FFh ,004h ,0FEh ,005h ,000h ,0FFh ,002h ,0BDh ,0FFh ,002h ,0BEh ,008h ,008h ,009h ,00Bh ,00Ah ,007h ,0FFh ,002h ,0BFh ,004h ,0FBh ,005h ,001h ,0FFh ,009h ,00Ah ,0FFh ,007h ,03Fh,0FDh,0FDh
