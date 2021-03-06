;
; 15.01.90
;
; ��䬥��᪨� � �ᯮ����⥫�� ��楤���
; �� �ᯮ����騥 RAM � ���譨� EQU
;
;
;------------------------------------------------
;                                               
; �����㦥�� 2 �訡�� - ������祭� "?????????"                                               
;                                               
;------------------------------------------------
;
;ARIFM	ORG	2000H
;
;
;	JMP	DIV     ; ������� 楫�� �ᥫ
;	JMP	MULT    ; 㬭������ 楫�� �ᥫ
;	JMP	FDIV    ;  /BHL/=/BHL/:/CDE/ (��. �窠)
;	JMP	FMULT   ; 㬭������ ���� �ᥫ � ������饩
;                         �窮�
;                         /BHL/=/BHL/*/CDE/
;
;	JMP	FADD    ; /BHL/=/BHL/+/CDE/ (��. �窠)
;	JMP	FSUB
;	JMP	FCVFL   ; �८�ࠧ������ �᫠ � ��. �窮�
;                         � �����筮�
;
;	JMP	FLOAT   ; �८�ࠧ������: 楫�� --> � ��. �窮�
;                       ; /HL/ --> /BHL/
;
;	JMP	FIX     ; �८�ࠧ������: � ��. �窮�-->楫��
;                         /BHL/-->/HL/
;
;	JMP	CNHL    ;  /HL/=/-HL/
;	JMP	CNDE    ;  /DE/=/-DE/
;	JMP	CHGS1   ; �ନ��� ����筮� ���������� �᫠
;                         � ������饩 �窮�
;                         INP: /BHL/=/-BHL/
;	JMP	CHGS2   ; �ନ��� ����筮� ���������� �᫠
;                         � ������饩 �窮�
;                         INP: /CDE/=/-CDE/
;	JMP	NORM1   ; ��ଠ������ /BHL/
;	JMP	NORM2   ; ��ଠ������ /CDE/
;	JMP	CNBCHL  ; /BCHL/=/-BCHL/
;	JMP	HLADA@  ; /HL/=/HL/+/A/
;	JMP	BRUIN@
;	JMP	CMDBL@  
;	JMP	IWASC   ; �८�ࠧ������: 楫��-->�����筮�
; 	JMP	CMPDBL  ; Compare /HL/&/DE/
;	JMP	MVSO    ; ����뫠�� �����
;	JMP	MVST    ; ��६�頥� ��ப� ���⮢
;	JMP	SRLS    ; ᤢ�� /BC/ ��ࠢ� �� ���� ࠧ��
;	JMP	SLLS    ; ᤢ�� /BC/ ����� �� ���� ࠧ��
;
;------------------------------------------------
;                                               
;     1 -� ����         2 -� ����         3 -� ����                           
;  +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+
;   7 6 5 4 3 2 1 0   7 6 5 4 3 2 1 0   7 6 5 4 3 2 1 0 
;  +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+
;   ! !-----------!   !-------------------------------!
;   !    ���冷� (C)          ������ (M)      
;   !                                           
;   !    C - 64         ���訩 ࠧ�� ������� = 1/2
;   !                                           
;   !-- -> ���� �ᥣ� �᫠                     
;                                               
;   ����⥫�� �᫠ ����ࠦ����� �� �����묨
;   �������⥫�묨 ������ (�� 3 -� �����)     
;                                               
;   ��� ����権 � ��. ����⮩                  
;   ���࠭�� ��室���� � ॣ����� :            
;                                               
;   1.  (B,H,L)                                 
;   2.  (C,D,E)                                 
;                                               
;   ������� (B,H,L)                                 
;                                               
;------------------------------------------------
;
;**************************************
;   SUBROUTINE DIV
;**************************************
;
; ������� 楫�� �ᥫ
;
; INP: /BCHL/ - �������, /DE/ - ����⥫�
; OUT: /HL/   - ��⭮�, /BC/ - ���⮪
;      /DE/   - ����⥫�
;
DIV:
;
	PUSH	PSW
	PUSH	D
	MOV	A,B
	XRA	D
	PUSH	PSW
	MOV	A,B
	CPI	0
	CM	CNBCHL
	MOV	A,D
	CPI	0
	CP	CNDE
	MVI	A,17
RA100@:
	DCR	A
	JM	FA100@
	PUSH	H
	MOV	H,B
	MOV	L,B+1
	DAD	D
	JNC	JDIV1
	MOV	B,H
	MOV	B+1,L
JDIV1:
	POP	H
	PUSH	PSW
	MOV	A,L
	RAL
	MOV	L,A
	MOV	A,H
	RAL
	MOV	H,A
	MOV	A,C
	RAL
	MOV	C,A
	MOV	A,B
	RAL
	MOV	B,A
	POP	PSW
	JMP	RA100@
FA100@:
	XRA	A
	MOV	A,B
	RAR
	MOV	B,A
	MOV	A,C
	RAR
	MOV	C,A
	POP	PSW
	CPI	0
	CM	CNHL
	POP	D
	POP	PSW
	RET
;
;------------------------------------------------
;
;**************************************
;    SUBROUTINE MULT
;**************************************
;
;   㬭������ 楫�� �ᥫ
; INP: /HL/*/DE/
; OUT: /BCHL/ - १����, /DE/ - ��� ���������
;
MULT:
;
	PUSH	PSW
	PUSH	D
	MOV	A,H
	XRA	D
	PUSH	PSW
	MOV	A,H
	CPI	0
	CM	CNHL
	MOV	A,D
	CPI	0
	CM	CNDE
	LXI	B,0
	PUSH	B
	STC
LA200@:
	MOV	A,L
	RAL
	MOV	L,A
	MOV	A,H
	RAL
	MOV	H,A
	JNC	JMULT1
	XTHL
	DAD	D
	JNC	$+4
	INX	B
	XTHL
JMULT1:
	MOV	A,H
	ANI	7FH
	ORA	L
	JZ	WA200@
	XTHL
	DAD	H
	MOV	A,C
	RAL
	MOV	C,A
	MOV	A,B
	RAL
	MOV	B,A
	XTHL
	JMP	LA200@
WA200@:
	POP	H
	POP	PSW
	CPI	0
	CM	CNBCHL
	POP	D
	POP	PSW
	RET
;
;------------------------------------------------
;
;**************************************
;    SUBROUTINE CNHL
;**************************************
;
;  /HL/=/-HL/
;
CNHL:
	PUSH	PSW
	MOV	A,L
	CMA
	MOV	L,A
	MOV	A,H
	CMA	
	MOV	H,A
	INX	H
	POP	PSW
	RET
;
;------------------------------------------------
;
;**************************************
;    SUBROUTINE CNDE
;**************************************
;
;  /DE/=/-DE/
;
CNDE:
	PUSH	PSW
	MOV	A,E
	CMA
	MOV	E,A
	MOV	A,D
	CMA
	MOV	D,A
	INX	D
	POP	PSW
	RET
;
;------------------------------------------------
;
;**************************************
;    SUBROUTINE CNBCHL
;**************************************
;
; /BCHL/=/-BCHL/
;
CNBCHL:
	PUSH	PSW
	MOV	A,L
	CMA
	ADI	1
	MOV	L,A
	MOV	A,H
	CMA
	ACI	0
	MOV	H,A
	MOV	A,C
	CMA
	ACI	0
	MOV	C,A
	MOV	A,B
	CMA
	ACI	0
	MOV	B,A
	POP	PSW
	RET
;
;------------------------------------------------
;
;**************************************
;   SUBROUTINE SIGNUM (�ᯮ����⥫쭠�)
;**************************************
;
;
SIGNUM:
	MOV	A,B
	XRA	C
	PUSH	PSW
	MOV	A,B
	CPI	0
	CM	CHGS1
	MOV	A,B
	SUI	64
	MOV	B,A
	MOV	A,C
	CPI	0
	CM	CHGS2
	MOV	A,C
	SUI	64
	MOV	C,A
	CALL	NORM1
	CALL	NORM2
	POP	PSW
	RET
;
;------------------------------------------------
;
;**************************************
;   SUBROUTINE CHGS1
;**************************************
;
; �ନ��� ����筮� ���������� �᫠
; � ������饩 �窮�
;
; INP: /BHL/=/-BHL/
;
CHGS1:
	PUSH	PSW
	MOV	A,L
	CMA
	ADI	1
	MOV	L,A
	MOV	A,H
	CMA
	ACI	0
	MOV	H,A
	MOV	A,B
	CMA
	ACI	0
	MOV	B,A
	POP	PSW
	RET
;
;------------------------------------------------
;
;**************************************
;   SUBROUTINE CHGS2
;**************************************
;
;
; �ନ��� ����筮� ���������� �᫠
; � ������饩 �窮�
;
; INP: /CDE/=/-CDE/
;
CHGS2:
	PUSH	PSW
	MOV	A,E
	CMA
	ADI	1
	MOV	E,A
	MOV	A,D
	CMA
	ACI	0
	MOV	D,A
	MOV	A,C
	CMA
	ACI	0
	MOV	C,A
	POP	PSW
	RET
;
;------------------------------------------------
;
;**************************************
;   SUBROUTINE FMULT
;**************************************
;
; 㬭������ ���� �ᥫ � ������饩
; �窮�
;
;  /BHL/=/BHL/*/CDE/
;
FMULT:
	PUSH	PSW
	MOV	A,H
	ORA	L
	JZ	IA901@
	MOV	A,D
	ORA	E
	JNZ	IA900@
IA901@:
	MOV	H,A
	MOV	L,A
	MOV	B,A
	POP	PSW
	RET
IA900@:
	PUSH	D
	PUSH	B
	CALL	SIGNUM
	PUSH	PSW
	PUSH	B
	LXI	B,0
	PUSH	B
	STC
LA902@:
	MOV	A,L
	RAL
	MOV	L,A
	MOV	A,H
	RAL
	MOV	H,A
	JNC	FMULT1
	XTHL
	DAD	D
	JNC	$+4
	INX	B
	XTHL
FMULT1:
	MOV	A,H
	ANI	7FH
	ORA	L
	JZ	WA902@
	XTHL
	MOV	A,L
	RAL
	MOV	L,A
	MOV	A,H
	RAL
	MOV	H,A
	MOV	A,C
	RAL
	MOV	C,A
	MOV	A,B
	RAL
	MOV	B,A
	XTHL
	JMP	LA902@
WA902@:
	POP	H
	POP	D
LA903@:
	MOV	A,B
	CPI	0
	JM	WA903@
	DAD	H
	MOV	A,C
	RAL
	MOV	C,A
	MOV	A,B
	RAL
	MOV	B,A
	DCR	D
	JMP	LA903@
WA903@:
	MOV	A,H
	ORA	L
	JZ	IA904@
	MOV	A,C
	ORI	1
	MOV	C,A
IA904@:
	MOV	H,B
	MOV	L,C
	MOV	A,D
	ADD	E
	ADI	64
	MOV	B,A
	POP	PSW
;
;  ????????? - �訡�� ! � PSW ���� १����
;  CPI 0 - �� �㦭�
;
	CPI	0	
	CM	CHGS1
	POP	D
	MOV	C,E
	POP	D
	POP	PSW
	RET
;
;------------------------------------------------
;
;**************************************
;   SUBROUTINE NORM1
;**************************************
;
; ��ଠ������ /BHL/
;
NORM1:
	MOV	A,H
	ORA	L
	RZ
LAA00@:
	MOV	A,H
	CPI	0
	JM	WAA00@
	DAD	H
	DCR	B
	JMP	LAA00@
WAA00@:
	RET
;
;------------------------------------------------
;
;**************************************
;   SUBROUTINE NORM2
;**************************************
;
; ��ଠ������ /CDE/
;
NORM2:
	MOV	A,D
	ORA	E
	RZ
	XCHG
LAB00@:
	MOV	A,H
	CPI	0
	JM	WAB00@
	DAD	H
	DCR	C
	JMP	LAB00@
WAB00@:
	XCHG
	RET
;
;------------------------------------------------
;
;**************************************
;   SUBROUTINE FDIV
;**************************************
;
;  /BHL/=/BHL/:/CDE/
;
FDIV:
	PUSH	PSW
	PUSH	D
	PUSH	B
	CALL	SIGNUM
	PUSH	PSW
	PUSH	B
	MOV	B,H
	MOV	B+1,L
	LXI	H,0
	PUSH	H
	MVI	L,16
RAC00@:
	DCR	L
	JM	FAC00@
	MOV	A,C
	SUB	E
	MOV	A,B
	SBB	D
	MOV	A,H
	SBI	0
	JC	FDIV1
	MOV	H,A
	MOV	A,C
	SUB	E
	MOV	C,A
	MOV	A,B
	SBB	D
	MOV	B,A
	XRA	A
FDIV1:
	CMC
	XTHL
	MOV	A,L
	RAL
	MOV	L,A
	MOV	A,H
	RAL
	MOV	H,A
	XTHL
	MOV	A,C
	RAL
	MOV	C,A
	MOV	A,B
	RAL
	MOV	B,A
	MOV	A,H
	RAL
	MOV	H,A
	JMP	RAC00@
FAC00@:
	MOV	D,B
	MOV	E,C
	POP	H
	POP	B
	CALL	NORM1
	MOV	A,D
	ORA	E
	JZ	IAC01@
	MOV	A,L
	ORI	1
	MOV	L,A
IAC01@:
	MOV	A,B
	SUB	C
	ADI	65
	MOV	B,A
	POP	PSW
;
;  ????????? - �訡�� ! � PSW ���� १����
;  CPI 0 - �� �㦭�
;
	CPI	0
	CM	CHGS1
	MOV	A,H
	ORA	L
	JNZ	IAC02@
	MOV	B,A
IAC02@:
	POP	D
	MOV	C,E
	POP	D
	POP	PSW
	RET
;
;------------------------------------------------
;
;**************************************
;    SUBROUTINE FADD
;**************************************
;
; /BHL/=/BHL/+/CDE/
;
FADD:
	PUSH	PSW
	PUSH	D
	PUSH	B
	JMP	COMM
FSUB:
	PUSH	PSW
	PUSH	D
	PUSH	B
	CALL	CHGS2
;
;------------------------------------------------
;
;**************************************
;  SUBROUTINE COMM (�ᯮ����⥫쭠�)
;**************************************
;
COMM:
	MOV	A,C
	RAL
	MOV	A,B
	RAR
	PUSH	PSW
	CALL	SIGNUM
	MOV	A,C
	CMP	B
	JP	IAE00@
LAE01@:
	MOV	A,B
	CMP	C
	JZ	WAE01@
	XRA	A
	MOV	A,D
	RAR
	MOV	D,A
	MOV	A,E
	RAR
	MOV	E,A
	INR	C
	JMP	LAE01@
WAE01@:
	JMP	BEQUC
IAE00@:
LAE02@:
	MOV	A,B
	CMP	C
	JZ	WAE02@
	XRA	A
	MOV	A,H
	RAR
	MOV	H,A
	MOV	A,L
	RAR
	MOV	L,A
	INR	B
	JMP	LAE02@
WAE02@:
BEQUC:
	POP	PSW
	PUSH	B
	LXI	B,0
	CPI	0
	CM	CHGS2
	ANI	40H
	CNZ	CHGS1
	MOV	A,L
	ADD	E
	MOV	L,A
	MOV	A,H
	ADC	D
	MOV	H,A
	MOV	A,B
	ADC	C
	MOV	B,A
	MOV	C,B
	CPI	0
	CM	CHGS1
	POP	D
	MOV	A,B
	ORA	A
	JZ	IAE03@
	MOV	A,B
	RAR
	MOV	B,A
	MOV	A,H
	RAR
	MOV	H,A
	MOV	A,L
	RAR
	MOV	L,A
	INR	D
IAE03@:
	MVI	A,0
	RAL
	MOV	E,A
	MOV	B,D
	CALL	NORM1
	MOV	A,L
	ORA	E
	MOV	L,A
	MOV	A,B
	ADI	64
	MOV	B,A
	MOV	A,H
	ORA	L
	JNZ	IAE04@
	MOV	B,A
IAE04@:
	MOV	A,C
	CPI	0
	CM	CHGS1
	POP	D
	MOV	C,E
	POP	D
	POP	PSW
	RET
;
;------------------------------------------------
;
;**************************************
;  SUBROUTINE FLOAT
;**************************************
;
; �८�ࠧ������: 楫�� --> � ��. �窮�
;
; /HL/ --> /BHL/
;
FLOAT:
	PUSH	PSW
	PUSH	B
	MOV	A,H
	CPI	0
	CM	CNHL
	MOV	C,A
	MVI	A,16
	MOV	B,A
	CALL	NORM1
	MOV	A,B
	ADI	64
	MOV	B,A
	MOV	A,C
	CPI	0
	CM	CHGS1
	MOV	A,B
	POP	B
	MOV	B,A
	POP	PSW
	RET
;
;------------------------------------------------
;
;**************************************
;  SUBROUTINE FIX
;**************************************
;
; �८�ࠧ������: � ��. �窮�-->楫��
;
; /BHL/-->/HL/
;
FIX:
	PUSH	PSW
	PUSH	B
	PUSH	D
	MOV	A,B
	CPI	0
	CM	CHGS1
	MOV	C,A
	LXI	D,0
LB000@:
	MOV	A,B
	CPI	65
	JM	WB000@
	DAD	H
	MOV	A,E
	RAL
	MOV	E,A
	MOV	A,D
	RAL
	MOV	D,A
	DCR	B
	JMP	LB000@
WB000@:
	XCHG
	MOV	A,C
	CPI	0
	CM	CNHL
	POP	D
	POP	B
	POP	PSW
	RET
;
;------------------------------------------------
;
;**************************************
;  SUBROUTINE FCVFL
;**************************************
;
; �८�ࠧ������ �᫠ � ��. �窮�
; � �����筮�
;
; INP: /BHL/ - �᫮ � ��. �窮�
;      /DE/  - ���� ����
;      /A/   - ��� �ଠ�
;               
;       A(7..4) - �᫮ ��� 楫�� ���
;                 (� ������ �᫠) 
;               
;       A(3..0) - �᫮ ��� �஡��� ���
;               
;
;      ����� ����祭��� 楯�窨 ᨬ�����:
;
;    �᫨  (A3..A0) = 0, ⮣�� (A7..A4) +4
;    ���� (A7..A4)+(A3..A0) +5
;
;
; OUT: /BHL/ - ��� ���������
;      /DE/  - ���� �� ��ப��
;      /A/   = 0
;
FCVFL:
	PUSH	H
	PUSH	B
	MOV	C,A
	ANI	0FH
	PUSH	PSW
	MOV	A,B
	CPI	0
	JP	IB100@
	CALL	CHGS1
	POP	PSW
	ORI	80H
	PUSH	PSW
IB100@:
	MOV	A,C
	RRC
	RRC
	RRC
	RRC
	ANI	0FH
	MOV	C,A
	XCHG
RB101@:
	DCR	A
	JM	FB101@
	MVI	M,' '
	INX	H
	JMP	RB101@
FB101@:
	POP	PSW
	PUSH	H
	ADD	A
	JZ	IB102@
	MVI	M,'.'
	INX	H
	XTHL
IB102@:
	RAR
	PUSH	PSW
	XCHG
	MOV	A,B
	SUI	64
	MOV	B,A
LB103@:
	MOV	A,B
	CPI	18
	JM	WB103@
	CALL	FDVTEN
	DCR	C
	JM	WB103@
	DCX	D
	MVI	A,'0'
	STAX	D
	JMP	LB103@
WB103@:
	PUSH	D
	LXI	D,0
	XRA	A
RB104@:
	DCR	B
	JM	FB104@
	DAD	H
	MOV	A,E
	RAL	
	MOV	E,A
	MOV	A,D
	RAL
	MOV	D,A
	JMP	RB104@
FB104@:
	INR	B
	XTHL
	XCHG
LB105@:
	DCR	C
	JM	WB105@
	CALL	DVTEN
	DCX	D
	ADI	30H
	STAX	D
	MOV	A,H
	ORA	L
	JNZ	LB105@
WB105@:
	XCHG
	POP	D
	POP	PSW
	CPI	0
	JP	IB106@
	ANI	7FH
	DCR	C
	JM	IB107@
	DCX	H
	MVI	M,'-'
IB107@:
IB106@:
	INR	C
	DCR	C
	JP	IB108@
	MVI	M,'*'
IB108@:
	XCHG
	POP	D
	MOV	C,A
LB109@:
	MOV	A,H
	ORA	L
	JZ	WB109@
	DCR	C
	JM	WB109@
	CALL	FMLTEN
	ADI	30H
	STAX	D
	INX	D
	JMP	LB109@
WB109@:
	MVI	A,30H
RB10A@:
	DCR	C
	JM	FB10A@
	STAX	D
	INX	D
	JMP	RB10A@
FB10A@:
	POP	B
	POP	H
	XRA	A
	RET
;
;------------------------------------------------
;
;**************************************
;  SUBROUTINE DVTEN (�ᯮ����⥫쭠�)
;**************************************
;
; 
DVTEN:
	PUSH	B
	PUSH	D
	MOV	A,H
	RAR
	MOV	D,A
	MOV	A,L
	RAR
	MOV	E,A
	MVI	L,0
	MOV	A,L
	RAR
	MOV	H,A
	XRA	A
	MOV	A,D
	RAR
	MOV	D,A
	MOV	A,E
	RAR
	MOV	E,A
	MOV	A,H
	RAR
	MOV	H,A
	MVI	C,0DH
LB200@:
	MOV	A,D
;	ADI	0-50H:100H	; C6B0
	ADI	0B0H
	JNC	$+4
	MOV	D,A
	MOV	A,L
	RAL
	MOV	L,A
	MOV	A,H
	RAL
	MOV	H,A
	DCR	C
	JM	$+12
	MOV	A,E
	RAL	
	MOV	E,A
	MOV	A,D
	RAL
	MOV	D,A
	JMP	LB200@
WB200@:
	MOV	A,D
	RRC
	RRC
	RRC
	POP	D
	POP	B
	RET
;
;------------------------------------------------
;
;**************************************
; SUBROUTINE SLLS
;**************************************
;
; ᤢ�� /BC/ ����� �� ���� ࠧ��
;
;
SLLS:
	ORA	A	; ��� CARRY
	MOV	A,C
	RAL
	MOV	C,A
	MOV	A,B
	RAL
	MOV	B,A
	RET
;
;------------------------------------------------
;
;**************************************
;  SUBROUTINE SRLS
;**************************************
;
; ᤢ�� /BC/ ��ࠢ� �� ���� ࠧ��
;
SRLS:
	ORA	A
	MOV	A,B
	RAR
	MOV	B,A
	MOV	A,C
	RAR
	MOV	C,A
	RET
;
;------------------------------------------------
;
;**************************************
; SUBROUTINE MVST
;**************************************
;
; ��६�頥� ��ப� ���⮢
;
; /HL/ - ��㤠, /DE/ - �㤠, /BC/ - ᪮�쪮
;
MVST:
	MOV	A,B
	ORA	C
	RZ
;
	DCX	B
	MOV	A,M
	INX	H
	XCHG
	MOV	M,A
	INX	H
	XCHG
	JMP	MVST
;
;------------------------------------------------
;
;**************************************
;  SUBROUTINE FDVTEN (�ᯮ����⥫쭠�)
;**************************************
;
;
FDVTEN:
	PUSH	D
	PUSH	B
	XRA	A
	MOV	A,H
	RAR
	MOV	D,A
	MOV	A,L
	RAR
	MOV	E,A
	MVI	L,0
	MOV	A,L
	RAR
	MOV	H,A
	MVI	C,10H
LA100@:
	MOV	A,D
;	ADI	0-50H:100H	; C6B0
	ADI	0B0H
	JNC	$+4
	MOV	D,A
	MOV	A,L
	RAL
	MOV	L,A
	MOV	A,H
	RAL
	MOV	H,A
	DCR	C
	JZ	$+12
	MOV	A,E
	RAL
	MOV	E,A
	MOV	A,D
	RAL
	MOV	D,A
	JMP	LA100@
WA100@:
	POP	B
	MOV	A,B
	SUI	3
	MOV	B,A
	MOV	A,H
	CPI	0
	JM	IA101@
	DAD	H
	DCR	B
IA101@:
	MOV	A,D
	ORA	E
	JZ	IA102@
	MOV	A,L
	ORI	1
	MOV	L,A
IA102@:
	POP	D
	RET
;
;------------------------------------------------
;
;**************************************
;  SUBROUTINE FMLTEN (�ᯮ����⥫쭠�)
;**************************************
;
;
FMLTEN:
	PUSH	D
	MOV	D,H
	MOV	D+1,L
	XRA	A
	DAD	H
	ADC	A
	DAD	H
	ADC	A
	DAD	D
	ACI	0
	DAD	H
	ADC	A
	MOV	E,A
	MVI	D,0
RA200@:
	MOV	A,B
	CPI	0
	JP	UA200@
	MOV	A,E
	ORA	A
	JZ	UA200@
	RAR
	MOV	E,A
	MOV	A,H
	RAR
	MOV	H,A
	MOV	A,L
	RAR
	MOV	L,A
	MOV	A,D
	RAL
	ORA	L
	MOV	L,A
	INR	B
	JMP	RA200@
UA200@:
	MOV	A,E
	POP	D
	RET
;
;------------------------------------------------
;
;**************************************
;  SUBROUTINE IWASC
;**************************************
;
; �८�ࠧ������: 楫��-->�����筮�
;
; INP: /HL/-楫��, /DE/ - ���� ����
;      /A/ -��� �ଠ�
;
;      A(7) :
;       1 - �८�ࠧ������ � ������
;       0 - �८�ࠧ������ ��᮫���� ����稭
;
;      A(6..0) - �᫮ ��� १����
;
IWASC:
	PUSH	PSW
	PUSH	B
	PUSH	H
	MOV	B,A
	ANA	H
	MOV	C,A
	MOV	A,B
	ANI	7FH
	MOV	B,A
	XCHG
RA500@:
	DCR	A
	JM	FA500@
	MVI	M,' '
	INX	H
	JMP	RA500@
FA500@:
	XCHG
	PUSH	D
	MOV	A,C
	CPI	0
	CM	CNHL
	XRA	A
LA501@:
	DCR	B
	JM	WA501@
	CALL	DVTEN
	DCX	D
	ADI	30H
	STAX	D
	MOV	A,H
	ORA	L
	JNZ	LA501@
WA501@:
	XCHG
	MOV	A,C
	CPI	0
	JP	IA502@
	DCR	B
	JM	IA503@
	DCX	H
	MVI	M,'-'
IA503@:
IA502@:
	INR	B
	DCR	B
	JP	IA504@
	MVI	M,'*'
IA504@:
	POP	D
	POP	H
	POP	B
	POP	PSW
	RET
;
;------------------------------------------------
;
;**************************************
;  SUBROUTINE HLADA@
;**************************************
;
; /HL/=/HL/+/A/
;
HLADA@:
	ADD	L
	MOV	L,A
	RNC
	INR	H
	RET
;
;------------------------------------------------
;
;**************************************
;  SUBROUTINE BRUIN@
;**************************************
;
;
BRUIN@:
	XTHL
	ADD	A
	MVI	D,0
	MOV	E,A
	DAD	D
	MOV	A,M
	INX	H
	MOV	H,M
	MOV	L,A
	XTHL
	RET
;
;------------------------------------------------
;
;**************************************
;  SUBROUTINE CMDBL@
;**************************************
;
;
CMDBL@:
	MOV	A,L
	CMA
	MOV	L,A
	MOV	A,H
	CMA
	MOV	H,A
	INX	H
	RET
;
;------------------------------------------------
;
;**************************************
;  SUBROUTINE MVSO
;**************************************
;
; ����뫠�� �����
; 
; INP: /A/  - �᫮ ���⮢
;      /HL/ - ��㤮 ����
;      /DE/ - �㤠 ����뫠��
;
; OUT: /HL/,/DE/ - ���� �� ��᫥���� ���⮬
;      /A/ = 0
;
MVSO:
	ORA	A
	RZ            ; ��祣� ����뫠�� ...
MVO:
	MOV	B,M
	XCHG
	MOV	M,B
	INX	H
	XCHG
	INX	H
	DCR	A
	RZ
	JMP	MVO
;
;------------------------------------------------
;
;**************************************
;  SUBROUTINE CMPDBL
;**************************************
;
; Compare /HL/&/DE/
; OUT: Z=1 -> /HL/=/DE/, C=1 -> /HL/</DE/
;
CMPDBL:
	MOV	A,H
	CMP	D
	JZ	CMPL
	RET
CMPL:
	MOV	A,L
	CMP	E
	RET
;
;------------------------------------------------
;
	END	ARIFM
;
;
;












