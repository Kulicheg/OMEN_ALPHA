            .ORG    0F000h
VMSTRT  EQU     0F300h                  ; Video memory


            CALL    RENDERBW
            
            
            
            
            JMP     0000h


RENDERBW:                               ; Rener B/W VMEM

            PUSH    B
            PUSH    D
            PUSH    H
            MVI     B, 050h             ; 80 ширина экрана
            MVI     D, 019h             ; 25 высота экрана
            LXI     H, VMSTRT

WAITOUT1:   IN      0DEh                    ; STATUS Register
            ANI     02h 
            JZ      WAITOUT1 
            MVI     A, 1Bh
            OUT     0DFh 

WAITOUT2:   IN      0DEh                    ; STATUS Register
            ANI     02h 
            JZ      WAITOUT2 
            MVI     A, "c"
            OUT     0DFh 
RNDR:
            MOV     C, M
           
WAITOUT3:   IN      0DEh                    ; STATUS Register
            ANI     02h 
            JZ      WAITOUT3 
            MOV     A, C
            OUT     0DFh 
            
            INX     H
            DCR     B
            JNZ     RNDR
            ;DCR     D
            ;JNZ     RNDR

            POP     H
            POP     D
            POP     B
            
            RET


WAITOUT:    


            IN      0DEh                    ; STATUS Register
            ANI     02h 
            JZ      WAITOUT 
            RET

BYTEOUT:    
                            ; ВХОД C  - Байт для вывода
            CALL    WAITOUT ; Выход A - Отправленный байт
            MOV     A, C
            OUT     0DFh 
            RET



TXTOUT:     CALL    WAITOUT 
            MOV     A,M 
            ANI     7Fh ;drop 8th bit
            OUT     223 
            MOV     A,M 
            ANI     80h 
            JNZ     TXTOUT2      
            INX     H 
            JMP     TXTOUT
TXTOUT2:
            POP     H
            RET

 ;, 1Bh, "[H"





























            .ORG    VMSTRT - 2
DB  1Bh, "c"            
DB "There are significant differences between the 5.0 release of BASIC-80 and the previous releases (release 4.51 and earlier). If you have programs written under a previous release of BASIC-80, check Appendix A for new features in 5.0 that may affect execution. "
DB "There are significant differences between the 5.0 release of BASIC-80 and the previous releases (release 4.51 and earlier). If you have programs written under a previous release of BASIC-80, check Appendix A for new features in 5.0 that may affect execution. "
DB "There are significant differences between the 5.0 release of BASIC-80 and the previous releases (release 4.51 and earlier). If you have programs written under a previous release of BASIC-80, check Appendix A for new features in 5.0 that may affect execution. "
DB "                                                                                                                                                                                                                                                                   "
DB "                                                                                                                                                                                                                                                                   "
DB "                                                                                                                                                                                                                                                                   "
DB "                                                                                                                                                                                                                                                                   "
DB "                                                                                                                                                                                                                                                                   "
