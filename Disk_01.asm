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
DMA     EQU     8080h     
INT75   EQU     803Ch

            .ORG    INT75
            JMP     RECINTLOW          ; Прыжок по прерыванию 7.5

            .ORG    9000H 
            
            PUSH    PSW
            PUSH    B
            PUSH    D
            PUSH    H
            CALL    INITOUT
            CALL    ACIAINIT
            MVI     B,81H 
            CALL    RECBYTE 
            
            POP     H
            POP     D
            POP     B
            POP     PSW
            JMP     00D0h            ; warm start of monitor


RECBYTE:
            
            CALL  INITOUT
           
            MVI     B, 00h      ; B - данные которые мы хотим отправить накопителю  перед чтением
            MVI     D, 00h      ; D - комманда  чтения (000)
            CALL    SENDCMD     ; Отправляем накопителю желание считать сектор


            LXI     H, DMA
            MVI     M, 00h
            MVI     D, 80h            


CYCLE:
            EI                     ; Разрешаем прерывания
            MVI     A,18h          ; 
            SIM                    ; Включаем INT 7.5
    
            JMP     CYCLE
            
SECTORDONE:            
            DI
            RET
            


RECINTLOW:                            ;  Сюда мы попадаем  если сработало прерывание
            MOV     A, M
            ANA     A
            JNZ     RECINTHIGH    
            IN      00
            MOV     M, A
            
            MVI     C, 46
            CALL BYTEOUT
            RET
    
RECINTHIGH:

            MOV     C, M
            MVI     A,0F0h ; 11110000
            ANA     C
            RRC
            RRC
            RRC
            RRC
            MOV     C, A
            
            IN      00
            MOV     B, A
            MVI     A,0F0h ; 11110000
            ANA     B 
            MOV     B, A
            ORA     C
            MOV     M, A

            INX     H
            MVI     M, 00h
            DCR     D
            
                        MVI     C, 47
            CALL BYTEOUT
            JZ      SECTORDONE
            RET

INITOUT:                
            MVI     A,80H 
            OUT     07H 
            MVI     A,0H 
            OUT     00H 
            RET      
            
INITIN:                
            MVI     A,90h 
            OUT     07h 
            MVI     A,0h 
            OUT     00h 
            RET  


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

            MVI     D, 01H    ; D - комманда HOME               
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

ACIAINIT:   MVI     A, 15h ;ACIA init (21) 115200-8-N-1
            OUT     0DEh 
            RET
