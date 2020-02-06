            ORG     9000h

WBOOT:   

            CALL    ACIAINIT
            CALL    INIT8255OUT

;simplest case is to read the disk until all sectors loaded
            DI          ;!!!!!
            LXI     H, 8080h ;!!!!!
            SHLD    DMAAD
            
            LXI     sp, 8080h ;use space below buffer for stack !!!!!
            MVI     c,0 ;select disk 0
            CALL    seldsk 
            CALL    home ;go to track 00
; 
            MVI     b, 31h ;b counts * of sectors to load !!!!!
            MVI     c,0 ;c has the current track number
            MVI     d,2 ;d has the next sector to read
;	note that we begin by reading track 0, sector 2 since sector 1
;	contains the cold start loader, which is skipped in a warm start
            LXI     h, 0DC00h ;base of cp/m (initial load point)
LOAD1:               ;load	one more sector
            PUSH    b ;save sector count, current track
            PUSH    d ;save next sector to read
            PUSH    h ;save dma address
            MOV     c,d ;get sector address to register C
            CALL    setsec ;set sector address from register C
            POP     b ;recall dma address to b, C
            PUSH    b ;replace on stack for later recall
            CALL    setdma ;set dma address from b, C
; 
;	drive set to 0, track set, sector set, dma address set
            CALL    READ; JMP GOCPM ;
            CPI     00h ;any errors?
            JNZ     wboot ;retry the entire boot if an error occurs
; 
;	no error, move to next sector
            POP     h ;recall dma address
            
            LXI     d,128 ;dma=dma+128
            DAD     d ;new dma address is in h, l
            POP     d ;recall sector address
            POP     b ;recall number of sectors remaining, and current trk
            DCR     b ;sectors=sectors-1
            JZ      gocpm ;transfer to cp/m if all have been loaded
; 
;	more	sectors remain to load, check for track change
            INR     d 
            MOV     a,d ;sector=27?, if so, change tracks
            CPI     27 
            JC      load1 ;carry generated if sector<27
; 
;	end of	current track,	go to next track
            MVI     d, 0 ;begin with first sector of next track !!!!!
            INR     c ;track=track+1
; 
;	save	register state, and change tracks
            PUSH    b 
            PUSH    d 
            PUSH    h 
            CALL    settrk ;track address set from register c
            POP     h 
            POP     d 
            POP     b 
            JMP     load1 ;for another sector
; 
;	end of	load operation, set parameters and go to cp/m

GOCPM:               

            MVI     a,0c3h ;c3 is a jmp instruction
            STA     8000h ;for jmp to wboot
            LXI     h,0F2A7h ;wboot entry point
            SHLD    8001h ;set address field for jmp at 0
; 
            STA     8005h ;for jmp to bdos
            LXI     h, 0E400h ;bdos entry point
            SHLD    8006h ;address field of Jump at 5 to bdos
; 
            LHLD    DMAAD
            PUSH    H
            POP     B
            LXI     B, 8080h
            CALL    setdma 
; 
            ;EI       ;enable the interrupt system !!!!!
            LDA     8003h ;get current disk number
            MOV     c,a ;send to the ccp
            JMP     0000h ;go to cp/m for further processing



HOME:                ;move to the track 00	position of current drive
;	translate this call into a settrk call with Parameter 00
            
    
            PUSH    B
            PUSH    D
            MVI     D, 01H    ; D - комманда HOME               
            MVI     B, 00h   ; B - неиспользуеммые данные
            CALL    SENDCMD
            CALL    MEGALOOP
            POP     D
            POP     B
            RET      ;we will move to 00 on first read/write
; 
SELDSK:              ;select disk given by register c
            PUSH    B
            PUSH    D
            MVI     D, 02H    ; D - комманда               
            MOV     B, C      ; CPM wants drive in C and 
            CALL    SENDCMD
            CALL    MEGALOOP            
            POP     D
            POP     B
            CALL    MEGALOOP
            RET      
; 
SETTRK:              ;set track given by register c
           
            MVI     D, 04h    ; D - комманда             
            MOV     B, C      ; Пока ограничимся только 256 дорожками, поэтому передаем 
            CALL    SENDCMD   ; только младший байт С
            CALL    MEGALOOP
            RET      
; 
SETSEC:              ;set sector given by register c
            
            PUSH    B
            PUSH    D
           
            MVI     D, 03h    ; D - комманда
            MOV     B, C      ; Пока ограничимся только 256 секторами, поэтому передаем 
            CALL    SENDCMD   ; только младший байт С
            CALL    MEGALOOP
            
            POP     D
            POP     B
            
            RET      
; 
; 
SECTRAN:             
;translate the sector given by bc using the
;translate table given by de
            ;XCHG     ;hl=.trans
            ;DAD     b ;hl=.trans (sector)
            ;MOV     l,m ;l=trans (sector)
            ;MVI     h,0 ;hl=trans (sector)
            
;Пpеобpазование номеpа сектоpа
; паpаметp вызова:  BC - не пpеобpазованный номеp (00....) сектора
;                   DE - адpес таблицы пpеобpазования
;паpаметp возвpата: HL - пpеобpазованный номеp сектоpа
; Тут  что-то  было  про баг если просто не делать ничего.
            
            MOV     H, B
            MOV     L, C
            RET      ;with value in hl
; 
SETDMA:              ;set	dma address given by registers b and c
; Установка адpеса буфеpа
; паpаметp вызова:      BC - адpес буфеpа
; паpаметp возвpата:    -
;set	dma address given by registers b and c
            MOV     l,c ;low order address
            MOV     h,b ;high order address
            SHLD    dmaad ;save the address
            RET      
; 


READ: 
            
            
            PUSH    B
            PUSH    D
            MVI     B, 00h      ; B - данные которые мы хотим отправить накопителю  перед чтением
            MVI     D, 00h      ; D - комманда  чтения (000)
            CALL    SENDCMD     ; Отправляем накопителю желание считать сектор

            CALL    INIT8255IN
            
            LHLD    DMAAD
            MVI     D, 80h   
READSECTOR:
            CALL    WAITZERRO         
            CALL    WAITSYNC
            IN      00
            MOV     C, A
            CALL    WAITZERRO
            CALL    WAITSYNC
            IN      00
            MOV     B, A

            MVI     A,0F0h ; 11110000
            ANA     C
            RRC
            RRC
            RRC
            RRC
            MOV     C, A
            
            MVI     A,0F0h ; 11110000
            ANA     B 
            MOV     B, A
           
            ORA     C
            MOV     M, A
            DCR     D
            JZ      RSEXIT
            INX     H
            JMP     READSECTOR
RSEXIT:
            CALL    LOOP
            CALL    LOOP
            POP     D
            POP     B
            MVI     A, 0h; Placeholder for error
            RET


WAITZERRO:

            IN      00h
            CPI     00h
            RZ
            JMP     WAITZERRO

WAITSYNC:
            IN      00h
            CPI     00h
            RNZ
            JMP     WAITSYNC
            
  


SENDCMD:            ; B - данные
                    ; D - комманда               
            
            CALL INIT8255OUT
 
            PUSH    D
           
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
            POP     D
            RET





INIT8255OUT:                
            MVI     A, 80h
            OUT     07H 
            MVI     A, 0h 
            OUT     00h 
            RET      
            
INIT8255IN:                
            MVI     A,90h 
            OUT     07h 
            MVI     A,0h 
            OUT     00h 
            RET  




; 
WRITE:               ;perform a write operation
  
; Адрес начала сектора в DMA
; Попробуем весь сектор передать как  128 SENDCMD.
; B - данные
; D - комманда 

            CALL    INIT8255OUT
            LHLD    DMAAD      ; Старт DMA
            MVI     D, 07h      ; Комманда записи
            MVI     E, 80h      ; размер сектора
NEXTBYTE:
            MVI     D, 07h      ; Комманда записи
            MOV     B, M        ; Берем из памяти байт
            CALL    SENDCMD     ; Отправляем байт
            INX     H           ; Увеличиваем адрес
            DCR     E           ; Уменьшаем счетчик байт
            JNZ     NEXTBYTE    ; Если не последний шлем далее
            RET  
  
            MVI     A, 0 ;error condition 
; 
WAITIO:              ;enter	here from read	and write to perform the actual i/o
;	operation. return a 00h in register a if the operation completes
;	properly, and 0lh if an error occurs during the read or write
; 
;	in this case, we have saved the disk number in "diskno" (0, 1)
;			the track number in "track" (0-76)
;			the sector number in "sector" (1-26)
;			the dma address in "dmaad" (0-65535)

            RET      ;replaced when filled-in
; 


LOOP:       PUSH    D
            MVI     D, 0FFh ;delay a little
LOOP2:      NOP
            NOP
            NOP
            NOP
            NOP
            DCR     D ;decrement counter
            JNZ     LOOP2 
            POP     D
            RET

WAITOUT:    IN      0DEh 
            ANI     02h
            JZ      WAITOUT 
            RET  


BYTEOUT:    
                            ; ВХОД C  - Байт для вывода
            CALL    WAITOUT ; Выход A - Отправленный байт
            MOV     A, C
            OUT     0DFh 
            RET
            

ACIAINIT:   MVI     A, 15h ;ACIA init (21) 115200-8-N-1
            OUT     0DEh 
            RET


MEGALOOP:      
            PUSH    D
            MVI     E, 20h ;10 30 50   
MEGALOOP2:      
            CALL    LOOP
            DCR     E   
            JNZ     MEGALOOP2   
            POP     D
            RET   



TXTOUT:     CALL    WAITOUT 
            MOV     A,M 
            ANI     7Fh ;drop 8th bit
            OUT     223 
            MOV     A,M 
            ANI     80h 
            RNZ      
            INX     H 
            JMP     TXTOUT 

ERROR0:     .ISTR   "ERROR(0):BOOTING ERROR..."             
DMAAD:      DS      2 ;direct memory address 
