            .ORG    0F000h
VMSTRT  EQU     0F300h                  ; Video memory



            CALL    CLEARMEM
            MVI     B, 100
            
START:      CALL    RENDERBW
            DCR     B
            JNZ     START
            JMP     0000h


RENDERBW:                               ; Rener B/W VMEM

            PUSH    B
            PUSH    D
            PUSH    H
            MVI     B, 050h             ; 80 ширина экрана
            MVI     D, 018h             ; 24 высота экрана
            LXI     H, VMSTRT

WAITOUT1:   IN      0DEh                    ; STATUS Register
            ANI     02h 
            JZ      WAITOUT1 
            MVI     A, 1Bh
            OUT     0DFh 

WAITOUT2:   IN      0DEh                    ; STATUS Register
            ANI     02h 
            JZ      WAITOUT2 
            MVI     A, "["
            OUT     0DFh 
            
            
WAITOUT3:   IN      0DEh                    ; STATUS Register
            ANI     02h 
            JZ      WAITOUT3 
            MVI     A, "H"
            OUT     0DFh             
            
RNDR:
            MOV     C, M
           
WAITOUT4:   IN      0DEh                    ; STATUS Register
            ANI     02h 
            JZ      WAITOUT4
            MOV     A, C
            OUT     0DFh 
            
            INX     H
            DCR     B
            JNZ     RNDR
            DCR     D
            MVI     B, 050h             ; 80 ширина экрана
            JNZ     RNDR


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

CLEARMEM:            ;Clear memory from RAMSTART to RAMEND with 00h
            PUSH    B
            PUSH    H
            
            LXI     H, VMSTRT 
            LXI     B, VMSTRT + 1920
            
CLEARMEM2:  MVI     M, " " 
; 
            MOV     A, B               ;RAMEND(H)
            INX     H 
            XRA     H 
            JNZ     CLEARMEM2 
            MOV     A, C                 ;RAMEND(L)
            XRA     L 
            JNZ     CLEARMEM2 
            MVI     M, " " 
            
            POP     H
            POP     B
            
            RET      
; 







            .ORG    VMSTRT

;DB "There are significant differences between the 5.0 release of BASIC-80 and the pr"
;DB "evious releases (release 4.51 and earlier). If you have programs written under a"
;DB "previous release of BASIC-80, check Appendix A for new features in 5.0 that may "
;DB "affect execution.   0 1 2 3 4 5 6 7 8 9 0 A B C D E F G H                      !"
;DB "There are significant differences between the 5.0 release of BASIC-80 and the pr"
;DB "evious releases (release 4.51 and earlier). If you have programs written under a"
;DB "previous release of BASIC-80, check Appendix A for new features in 5.0 that may "
;DB "affect execution.   0 1 2 3 4 5 6 7 8 9 0 A B C D E F G H                      !"
;DB "There are significant differences between the 5.0 release of BASIC-80 and the pr"
;DB "evious releases (release 4.51 and earlier). If you have programs written under a"
;DB "previous release of BASIC-80, check Appendix A for new features in 5.0 that may "
;DB "affect execution.   0 1 2 3 4 5 6 7 8 9 0 A B C D E F G H                      !"
;DB "There are significant differences between the 5.0 release of BASIC-80 and the pr"
;DB "evious releases (release 4.51 and earlier). If you have programs written under a"
;DB "previous release of BASIC-80, check Appendix A for new features in 5.0 that may "
;DB "affect execution.   0 1 2 3 4 5 6 7 8 9 0 A B C D E F G H                      !"
;DB "There are significant differences between the 5.0 release of BASIC-80 and the pr"
;DB "evious releases (release 4.51 and earlier). If you have programs written under a"
;DB "previous release of BASIC-80, check Appendix A for new features in 5.0 that may "
;DB "affect execution.   0 1 2 3 4 5 6 7 8 9 0 A B C D E F G H                      !"
;DB "There are significant differences between the 5.0 release of BASIC-80 and the pr"
;DB "evious releases (release 4.51 and earlier). If you have programs written under a"
;DB "previous release of BASIC-80, check Appendix A for new features in 5.0 that may "
;DB "ffect execution.   0 1 2 3 4 5 6 7 8 9 0 A B C D E F G H                       !"
;DB "11111222223333344444555556666677777888889999900000AAAAABBBBBCCCCCDDDDDEEEEEFFFFF"
