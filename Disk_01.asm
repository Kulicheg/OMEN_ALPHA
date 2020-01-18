;  Пакет содержит 8 бит
;  0   Синхро, каждое изменение это новый пакет на шине
;  1 Комманда
;  2 Комманда
;  3 Комманда
;  4 Данные
;  5 Данные
;  6 Данные
;  7 Данные
; 
;  Комманды:
; 
;  00  000 Чтение  READ    ;36: Read a sector
;  01  001 Домой   HOME    ;21: Move disc head to track 0
;  02  010 Выбор   SELDSK  ;24: Select disc drive
;  03  011 Сектор  SETSEC  ;30: Set sector number
;  04  100 Трек    SETTRK  ;27: Set track number
;  05  101 Чтение 2
;  06  110 Запись 2
;  07  111 Запись  WRITE   ;39: Write a sector

            .ORG    9000H 
DMA EQU  8080h            
            
            CALL INIT
START: 
        CALL HOME

            RET      


INIT:                
            MVI     A, 80H 
            OUT     07H 
            MVI     A, 00H 
            OUT     00H 
            RET      



                            
READ:           
                                ; на выходе мы имеем сектор записанный в память по адресу условного DMA
            MVI     B, 00h      ; B - данные которые мы хотим отправить накопителю  перед чтением
            MVI     D, 00h      ; D - комманда  чтения (000)
            CALL    SENDCMD     ; Отправляем накопителю желание считать сектор
            MVI     E, 7Fh      ; счетчик длины сектора (127)
            LXI     H, DMA      ; Адрес куда будем сохранять сектор
RCVBYTE:
            IN      00h         ; Отправив комманду на чтение текущего сектора переходим в ожидание данных
            JZ      RCVBYTE     ; Крутим цикл пока в порт не поступят данные, архитектурой задано  что между циклами в порт записан 0
            MOV     M, A        ; Сохраняем в память принятый байт.
            INX     H           ; HL + 1
            DCR     E           ; D  - 1
            JNZ     RCVBYTE     ; Пока счетчик не обнулился продолжаем принимать байты
            MVI     A, 00h      ; OK
            RET                 ; Возврат



SENDCMD:            ; B - данные
                    ; D - комманда               
            MOV     C,B ; в BC у нас 2 копии данных В-h C-l

            MVI     A,0F0h ; 11110000
            ANA     B 
            MOV     B,A
            MVI     A,0Fh ; 00001111
            ANA     C 
            RLC 
            RLC             ; Сдвигаем данные  младшей половинки до конца влево
            RLC             ; и получаем       обе половинки справа
            RLC      
            MOV     C,A 

            MOV     A,D     ; комманда
            RLC             ; Сдвигаем комманду на место
            ORA     B       ; Добавляем к половинкам код комманды.
            MOV     B,A
            MOV     A,D     ; комманда
            RLC             ; Сдвигаем комманду на место
            ORA     C       ; Добавляем к половинкам код комманды.
            MOV     C,A

SENDBYTE:                    ; BC содержит половинки, код комманды и 0 в младшем бите

            MOV     A,C 
            INR     A       ; Поднимаем младший бит  чтобы диск проснулся
            OUT     00h     ; Выводим  младшую половину в порт
            CALL    LOOP
            MVI     A,00h 
            OUT     00h ; обнуляем порт 
            CALL    LOOP
           
            MOV     A,B 
            INR     A       ; Поднимаем младший бит
            OUT     00h     ; Выводим  старшую половину в порт для для совместимости 
            CALL    LOOP    ; даже комманды без данных передаем в 2 такта
            MVI     A,00h  
            OUT     00h     ; обнуляем порт
            CALL    LOOP
            RET
            

HOME:

            MVI     D, 02H    ; D - комманда HOME               
            MVi     B, 0ABh   ; B - неиспользуеммые данные
            CALL    SENDCMD    
            RET



LOOP:
            MVI     D,50h ;delay a little
LOOP2:      NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            DCR     D ;decrement counter
            JNZ     LOOP2 
            RET
