; Пиноут для 8255
; 0 - Данные (MOSI)
; 1 - SHCP такт для данных(SCK)
; 2 - STCP данные готовы (SS)
; 3 - AY RESET
; 4 - BDIR
; 5 - BC1
.ORG   9000h   
;CALL    INIT8255OUT
;CALL    AYRESET
START:       
        MVI     B, 0AAh   
        CALL    SERIALOUT   
        JMP     START   
AYRESET:      
        MVI   A, 00h   
        OUT   05h   
        CALL   MINILOOP   
        MVI   A, 08h   
        OUT   05h   
        RET      
SERIALOUT:      
        PUSH   B        ; регистр B пусть будет с байтом
        PUSH   D        ; регистр C пусть будет выводиться в порт
                        ; D будет содержать бит данных в младшем разряде
        MVI     C, 08h  ; Сначала мы должны в C установить бит 2(STCP) в 0
                        ; Установить в C бит 3 в 1(AY RESET) (на всякий, по идее мы его не трогаем)
        MVI     E, 08h  ; После мы должны начать цикл
NEXTBIT:      
        MOV     D, B    ; Берем B копируем в D
        MVI     A, 01h  ; Применяем D 00000001  
        ANA     D       ; чтобы получить в нем только один первый бит
        MOV     D, A
        ADD     C       ; в A у нас бит мы просто его прибавляем к C 0 или 1
        ADI     02h     ; Поднимаем в С(A) 1(SHCP)
        OUT     05h     ; Выводим в порт 
        SUI     02h     ; Опускаем С 1(SHCP)
        OUT     05h     ; Выводим в порт
        SUB     D       ; Вертаем взад бит чтобы не уехать после второй 1
        MOV     C, A    ; Сохраняем  наше C  
        MOV     A, B    ; берем наш байт
        RLC             ; Сдвигаем его вправо
        MOV     B, A    ; Возвращаем на будущее 
        DCR     E       ; Уменьшаем счетчик
        JNZ   NEXTBIT   ; Цикл пошел
                        ; байт выставлен на 595
        MVI     A, 04h  ; 
        ORA     C       ; установить бит 2(STCP) в 1
        OUT     05h     ; Вывести в порт 05
        SUI     04h     ; установить бит 2(STCP) в 0
        OUT     05h     ; Вывести в порт 05
        POP   D   
        POP   B   
        RET      

INIT8255OUT:      
MVI   A, 80h   
OUT   07H   
RET      

MINILOOP:   PUSH   D   
MVI   D, 0FFh   
MINILOOP2:   NOP      
NOP      
NOP      
DCR   D   
JNZ   MINILOOP2   
POP   D   
RET      
