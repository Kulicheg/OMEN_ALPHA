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

        .ORG   9000h   
START:     
        CALL    INIT8255OUT
        CALL    AYRESET
       

        LXI     H, MODULE
PLAY:
        MOV     B, M
        INX     H
        MOV     C, M
        INX     H
        PUSH    H
        MOV     H, B
        MOV     L, C
        CALL    REGSET
        POP     H
        JMP     PLAY


AYRESET:      
        MVI   A,00h   
        OUT   05h   
        CALL   MINILOOP   
        MVI   A,08h   
        OUT   05h   
        RET      
SERIALOUT:      
        PUSH   B        ; регистр B пусть будет с байтом
        PUSH   D        ; регистр C пусть будет выводиться в порт
                        ; D будет содержать бит данных в младшем разряде
NEXTBIT:      
        MOV     D, B    ; Берем B копируем в D
        MVI     A, 01h  ; Применяем D 00000001  
        ANA     D       ; чтобы получить в нем только один первый бит
        MOV     D, A
        ADD     C       ; в A у нас бит мы просто его прибавляем к C 0 или 1
        ADI     04h     ; Поднимаем в С(A) 2(SHCP)
        CALL    MINILOOP
        OUT     05h     ; Выводим в порт 
        SUI     04h     ; Опускаем С 2(SHCP)
        CALL    MINILOOP
        OUT     05h     ; Выводим в порт
        SUB     D       ; Вертаем взад бит чтобы не уехать после второй 1
        MOV     C, A    ; Сохраняем  наше C  
        MOV     A, B    ; берем наш байт
        RRC             ; Сдвигаем его вправо
        MOV     B, A    ; Возвращаем на будущее 
        DCR     E       ; Уменьшаем счетчик
        JNZ   NEXTBIT   ; Цикл пошел
                        ; байт выставлен на 595
        MVI     A, 02h  ; 
        ORA     C       ; установить бит 1(STCP) в 1
        OUT     05h     ; Вывести в порт 05
        SUI     02h     ; установить бит 1(STCP) в 0
        CALL    MINILOOP
        OUT     05h     ; Вывести в порт 05
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
        PUSH    B        
        PUSH    D        
        MVI     C, RESET    ;Сначала мы должны в C установить бит 1(STCP) в 0
                            ;Установить в C бит 3 в 1(AY RESET) (на всякий, по идее мы его не трогаем)
                            ;digitalWrite(BC1, LOW);
                            ;digitalWrite(BCDIR, LOW);
                            ;//write address
        MOV     B, H        ;Теперь в B адрес регистра
        CALL    SERIALOUT   ;SPI.transfer(address);

        MVI     A,  BC1 + BDIR + RESET  ;digitalWrite(BC1, HIGH);
        OUT     05h                     ;digitalWrite(BCDIR, HIGH);

        MVI     A,  RESET               ;digitalWrite(BC1, LOW);
        OUT     05h                     ;digitalWrite(BCDIR, LOW);

                                        ;//write data
        MVI     A,  BDIR + RESET        ;digitalWrite(BC1, LOW);
        OUT     05h                     ;digitalWrite(BCDIR, HIGH);
        
        MVI     C, RESET
        MOV     B, L                    ;Теперь в B данные регистра               
        CALL    SERIALOUT               ;SPI.transfer(data);
        OUT     05h                

        MVI     A,  RESET               ;digitalWrite(BC1, LOW);
                                        ;digitalWrite(BCDIR, LOW);
                        
        POP   D   
        POP   B
        RET

MINILOOP:
        PUSH    D   
        MVI     D, 0FFh   
MINILOOP2:
        NOP      
        NOP      
        NOP      
        DCR   D   
        JNZ   MINILOOP2   
        POP   D   
        RET      



MODULE:
    DB 000h,077h,007h,008h,008h,00Fh,008h,00Eh,000h,05Eh,008h,00Fh,008h,00Eh,000h,04Fh,008h,00Dh,008h,00Ch,000h,03Fh,008h,00Bh,008h,00Ah,000h,03Bh,008h,008h,008h,007h,008h,006h,000h,02Fh,008h,007h,008h,006h,000h,027h,008h,008h,008h,007h,008h,006h,000h,01Fh,008h,00Ch,008h,00Bh,008h,00Ah,000h,01Dh,008h,00Fh,008h,00Eh,000h,017h,008h,00Fh,008h,00Eh,000h,013h,008h,00Dh,008h,00Ch,000h,00Fh,008h,00Bh,008h,00Ah,000h,03Bh,008h,008h,008h,007h,008h,006h,000h,02Fh,008h,007h,008h,006h,000h,027h,008h,008h,008h,007h,008h,006h,000h,01Fh,008h,00Ch,008h,00Bh,008h,00Ah,008h,009h,008h,008h,008h,007h,008h,006h,008h,005h,008h,004h,008h,003h,008h,002h,008h,001h,008h,000h,007h,000h
