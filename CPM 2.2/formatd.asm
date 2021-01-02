            .ORG    0100h
;128 sectors per track, 2 tracks to free.
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
STRT:
            LXI     D, MSG1
            MVI     C, 09h
            CALL    5
            CALL    CLEARMEM
            MVI     C, 03h                  ;Disk D
            CALL    SELDSK
            LXI     B, BUFFER
            CALL    SETDMA
            MVI     C, 00h
            MOV     B, C
WRTRK:      MOV     C, B
            CALL    SETTRK
            MOV     B, C          
            MVI     C, 7Fh
WRSECT:     PUSH    B
            CALL    SETSEC
            CALL    WRITE
            CALL    DOT
            POP     B
            PUSH    B
            DCR     C
            JNZ     WRSECT
            CALL    SETSEC
            CALL    WRITE
            CALL    DOT
            POP     B
            INR     B
            MOV     A, B
            CPI     02h
            JNZ     WRTRK
            
            LXI     D, 0h
            MVI     C, 0h
            CALL    5
            
                                                
CLEARMEM:                                   ;Clear memory 
            PUSH    B
            PUSH    H
            LXI     H, BUFFER 
            LXI     B, BUFFER + 128
CLEARMEM2:  MVI     M, 0E5h 
            MOV     A, B                    ;RAMEND(H)
            INX     H 
            XRA     H 
            JNZ     CLEARMEM2 
            MOV     A, C                    ;RAMEND(L)
            XRA     L 
            JNZ     CLEARMEM2 
            MVI     M, 0E5h 
            POP     H
            POP     B
            RET     

DOT:
            MVI     E, "."
            MVI     C, 02h
            CALL    5
            RET

MSG1:
DB "Formating DISK D: $"
BUFFER:
DB            00

