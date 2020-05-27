			;************************************************************************************
			;
			;MON85: A software debugger for the 8080/8085 processor
			;
			;Copyright 1979-2007 Dave Dunfield
			;All rights reserved.
			;
			;Version 1.2 - 2012 Roman Borik
			;
			;Version 1.3 - 2018 Johnny Quest
			;
			;New in version 1.2
			;- Support for undocumented 8085 instructions.
			;  DSUB B, ARHL, RDEL, LDHI d8, LDSI d8, LHLX D, SHLX D, JNK a16, JK a16, RSTV
			;- Command R displays all flags of F register (SZKA3PVC). If flag is not set
			;  dash '-' is displayed.
			;- Added restart vector RST 8 (0040h) for possibility to handle RSTV call.
			;- Changed TRACE mode. After entering TRACE mode, instruction on actual PC and
			;  content of registers (if it is switched on) are displayed.
			;  Entering a space ' ' executes this instruction, and returns to the 'T>'
			;  prompt with the next instruction.
			;- Instructions LXI, DAD, INX, DCX displays argument 'SP' rather than 'S'.
			;- Commands that requires 1 byte parameter raises error if entered value
			;  not fit to 1 byte.
			;- Command 'C' checks overlap of source and destination block and for copying
			;  uses appropriate direction.
			;- Command 'F' checks <start> and <end> parameters and raises error,
			;  if <end> is lower than <start>.
			;- Added command 'H' to send out memory content in Intel HEX format.
			;- Sending of LF and CR characters were reversed and are sent in the usual
			;  order - CR first and followed by LF.
			;
			;New in version 1.3
			;2018-1101	Added support for calling TinyBASIC or IMSAI 8K BASIC
			;2018-0920	Added support for MC68B50 ACIA RX interrupts since an active
			;			RDRF flag is clobbered by a write to the ACIA data register.
			;			Using the RX interrupt, fetch and store the new character in
			;			RAM buffer and let the "IN" routine to fetch it.
			;2018-0913	Modified syntax to assemble using as8085 by Alan R. Baldwin
			;
			;************************************************************************************

ROM			.EQU	 0x0000
DRAM		.EQU	 0xEFA0			;start of RAM

TBASIC		.EQU	0x3900			;Starting address of TinyBASiC
IBASIC		.EQU	0x1100			;Starting address of IMSAI 9K BASiC

ENBL_PIO	.EQU	1				;"1" to enable i8255 I/O routines
ENBL_8251	.EQU	0				;"1" to enable i8251 UART routines
ENBL_6850	.EQU	1				;"1" to enable MC6850 ACIA routines
MSTR_CLK	.EQU	0				;0 = 3.68MHz, 1 = 4.91MHz

			;***********************************************************
			;JQ - For 8085SBC I/O decoder addressing
			;-----------------------------------------------------------
IO0		.EQU	 0x00			;on-board 8255 PIO
IO1		.EQU	 0x20			;I/O expansion 1
IO2		.EQU	 0x10			;I/O expansion 2
IO3		.EQU	 0x30			;I/O expansion 3
IO4		.EQU	 0x08			;I/O expansion 4
IO5		.EQU	 0x28			;I/O expansion 5
IO6		.EQU	 0x18			;I/O expansion 6
IO7		.EQU	 0x38			;I/O expansion 7
			;
			;Common definitions
			;
ESCAPE		.EQU	0x1b			;escape character
SPACE		.EQU	0x20			;space character
CR			.EQU	0x0d			;carriage return character
LF			.EQU	0x0a			;line feed character
			;
			;*****************************************************
			; Interrupt vectors
			;
RST0		.EQU	ROM + 0x00		; Software interrupt
RST1		.EQU	ROM + 0x08		; Software interrupt
RST2		.EQU	ROM + 0x10		; Software interrupt
RST3		.EQU	ROM + 0x18		; Software interrupt
RST4		.EQU	ROM + 0x20		; Software interrupt
TRAP		.EQU	ROM + 0x24		; *Hardware interrupt
RST5		.EQU	ROM + 0x28		; Software interrupt
RST55		.EQU	ROM + 0x2C		; *Hardware interrupt
RST6		.EQU	ROM + 0x30		; Software interrupt
RST65		.EQU	ROM + 0x34		; *Hardware interrupt
RST7		.EQU	ROM + 0x38		; Software interrupt
RST75		.EQU	ROM + 0x3C		; *Hardware interrupt
			;
			;*****************************************************
			;
			;Debugger data area (96 bytes required in RAM)
			;
			.area	_CODE (ABS)
			.ORG	DRAM			;Monitor data goes here
					;
UBASE:		.DS		2				;Base address of user program
HL:			.DS		2				;Saved HL register pair
DE:			.DS		2				;Saved DE register pair
BC:			.DS		2				;Saved BC register pair
PSW:		.DS		2				;Saved PSW (A + CC)
SP:			.DS		2				;Saved Stack Pointer
PC:			.DS		2				;Saved Program Counter
OFLAG:		.DS		1				;Output suspended flag
TFLAG:		.DS		1				;Flag to enable TRACING
SFLAG:		.DS		1				;Flag to enable SUBROUTINE tracing
AFLAG:		.DS		1				;Flag to enable AUTO REGISTER DISPLAY
BRKTAB:		.DS		24				;Breakpoint table
INST:		.DS		6				;Save area for "faking" instructions
.IF ENBL_6850 == 1					;Enable for MC6850 ACIA RX interrupt
ACIA_BUFF:	.DS		1				;MC6850 ACIA RX Buffer
BUFFER:		.DS		46				;Input/temp buffer & stack
.ELSE
BUFFER:		.DS		47				;Input/temp buffer & stack
.ENDIF
DSTACK		.EQU	.				;reserve CPU stack
;DSTACK		.EQU	DRAM + (BUFFER - UBASE)	;reserve CPU stack
;DSTACK		.EQU	BUFFER + 47		;reserve CPU stack

			;
			;Startup code... Kick off the monitor
			;
			.area	_CODE (ABS)
			.ORG	ROM 			;Debugger code goes here
			; Hardware RESET vector
			LXI		SP,DSTACK 		;Set up initial stack pointer
			JMP		TEST 			;Execute main program
			;
			;Interrupt handlers for RESTART interrupts
			;
			;Although the RST 1.5, 2.5 and 3.5 vectors are not used by the
			;8085 hardware,  they are included since the space must contain
			;SOMETHING,  and who knows, perhaps someone uses them for jump
			;table addresses etc...
			;
			;Restart 1 is the entry point for breakpoints
			.ORG	RST1
			JMP		ENTRY 			;Execute handler
			.DB		RST1			;;Offset to handler
			;
			.ORG	RST2
			CALL	RSTINT 			;Invoke interrupt
			.DB		RST2			;;Offset to handler
			;
			.ORG	RST3
			CALL	RSTINT 			;Invoke interrupt
			.DB		RST3			;;Offset to handler
			;
			.ORG	RST4
			CALL	RSTINT 			;Invoke interrupt
			.DB		RST4			;;Offset to handler
			;
			.ORG	TRAP
			CALL	RSTINT 			;Invoke hardware interrupt
			.DB		TRAP			;;Offset to handler
			;
			.ORG	RST5
			CALL	RSTINT 			;Invoke interrupt
			.DB		RST5			;;Offset to handler
			;
			.ORG	RST55
		.IF ENBL_6850 == 1			;Enable RST5.5 for MC6850 ACIA RX interrupt
			JMP		ACIA_ISR		;RX interrupt service routine
		.ELSE
			CALL	RSTINT 			;Invoke hardware interrupt
		.ENDIF
			.DB		RST55			;;Offset to handler
			;
			.ORG	RST6
			CALL	RSTINT 			;Invoke interrupt
			.DB		RST6			;;Offset to handler
			;
			.ORG	RST65
			CALL	RSTINT 			;Invoke hardware interrupt
			.DB		RST65			;;Offset to handler
			;
			.ORG	RST7
			CALL	RSTINT 			;Invoke interrupt
			.DB		RST7			;;Offset to handler
			;
			.ORG	RST75
			CALL	RSTINT 			;Invoke hardware interrupt
			.DB		RST75			;;Offset to handler

			;
			;Process a RESTART interrupt, get offset & vector to code
			;To speed processing, it is assumed that the user program
			;base address begins on a 256 byte page boundary.
			;
RSTINT:		XTHL					;Save HL, Get PTR to offset
			PUSH	PSW 			;Save A and CC
			MOV		A,M 			;Get offset
			LHLD	UBASE 			;Get high of user program
			MOV		L,A 			;Set low address
			POP		PSW 			;Restore A & CC
			XTHL					;Restore HL, set
			RET						;Vector to interrupt
			;
			;Register -> text translation tables used by the disassembler. These tables
			;go here (near beginning) so that we can be sure the high address will not
			;cross a page boundary allowing us to index by modifying low address only.
			;
RTAB:		.STR	"BCDEHLMA" 		;Table of register names
RPTAB:		.STR	"BDHS" 			;Table of register pairs
			;
			;Entry point for breakpoints & program tracing
			;
			;Save the user program registers
ENTRY:		SHLD	HL				;Save HL
			XCHG					;Get DE
			SHLD	DE				;Save DE
			POP		H				;Get RET address
			SHLD	PC				;Save PC
			PUSH	B				;Copy BC
			POP		H				;And get it
			SHLD	BC				;Save PC
			PUSH	PSW 			;Copy PSW
			POP		H				;And get it
			SHLD	PSW 			;Save PSW
			LXI		H,0 			;Start with zero
			DAD		SP				;Get SP
			SHLD	SP	 			;Save SP
			LXI		SP,DSTACK 		;Move to our stack
			LHLD	PC				;Get RET addrss
			DCX		H				;Backup to actual instruction
			SHLD	PC				;Save PC
			LXI		D,BRKTAB 		;Point to breakpoint table
			MVI		B,'0 			;Assume breakpoint #0
			;Search breakpoint table & see if this is a breakpoint
TRYBRK:		LDAX	D				;Get HIGH byte from table
			INX		D				;Advance
			CMP		H				;Does it match?
			LDAX	D				;Get LOW byte from table
			INX		D				;Advance
			JNZ		NOTBRK 			;No, try next
			CMP		L				;Does it match?
			JZ		FOUND 			;Yes, we have an entry
NOTBRK:		INX		D				;Skip saved code byte
			INR		B				;Advance breakpoint number
			MOV		A,B 			;Get breakpoint number
			CPI		'0+8 			;Table exausted
			JC		TRYBRK 			;No, keep looking
			;This interrupt is NOT a breakpoint
			JMP		NOBK 			;Enter with no breakpoint
			;This interrupt is a breakpoint, display the message
FOUND:		CALL	PRTMSG 			;Output message
			.STRZ	"** Breakpoint "
			MOV		A,B 			;Get breakpoint number
			CALL	OUT 			;Output it
			CALL	CRLF 			;New line
			;Reenter monitor, first, restore all breakpoint opcodes
NOBK:		LXI		H,BRKTAB 		;Point to breakpoint table
			MVI		B,8 			;8 breakpoints
FIXL:		MOV		D,M 			;Get HIGH address
			INX		H				;Advance
			MOV		E,M 			;Get LOW address
			INX		H				;Advance
			MOV		A,D 			;Get high
			ORA		E				;Test for ZERO
			JZ		NOFIX 			;Breakpoint is not set
			MOV		A,M 			;Get opcode
			STAX	D				;And patch user code
NOFIX:		INX		H				;Skip opcode
			DCR		B				;Reduce count
			JNZ		FIXL 			;Not finished, keep going
			LDA		TFLAG 			;Get trace mode flag
			ANA		A				;Is it enabled?
			JNZ		TRTB 			;Yes, enter trace mode
			LDA		AFLAG 			;Get auto register display flag
			ANA		A				;Is it enabled?
			CNZ		REGDIS 			;Yes, display the registers
			JMP		REST 			;Enter monitor
			;Prompt for and handle trace mode commands
TRTB:		CALL	PRTMSG 			;Output message
			.STRZ	"T> " 			;Trace mode prompt
			LHLD	PC				;Get PC
			XCHG					;Move to DE
			CALL	DINST 			;Disassemble the instruction
			CALL	CRLF 			;New line
			LDA		AFLAG 			;Get auto register display flag
			ANA		A				;Is it enabled?
			CNZ		REGDIS 			;Yes, display the registers
TRL:		CALL	INCHR 			;Get a command character
			CPI		SPACE			;Execute command?
			JZ		NOADR 			;Yes, handle it
			CPI		ESCAPE 			;ESCAPE?
			JZ		RECR 			;Yes, abort
			CPI		'?				;Register display?
			JNZ		TRL 			;No, ignore it
			CALL	REGDIS 			;Display the registers
			JMP		TRTB 			;And go again
			;
			;Main entry point for the 8080 debugger
			;
TEST:		CALL	INIT 		;Initialize the ACIA/UART

		; JQ - added on-board 8255 PIO
		.IF ENBL_PIO == 1
			CALL	PIOINIT			;Initialize the 8255
		.ENDIF

		.IF ENBL_6850 == 1			;Enable for MC6850 ACIA RX interrupt on RST5.5
		; JQ - added IRQ for MC6850 on-board ACIA
			MVI		A,0b0001110		;enable RST5.5, disable RST7.5 and RST6.5
			SIM						;set the mask bits
			EI						;Enable interrupts
		.ENDIF
		; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

			CALL	PRTMSG 			;Output herald message
		.IF ENBL_6850 == 1			;If MC6850 ACIA is enabled
			.STR	"\r\nMON85 Version 1.3 (6850 ACIA)\r\n"
		.ELSE
			.STR	"\r\nMON85 Version 1.3 (8251 UART)\r\n"
		.ENDIF
			.STR	"(C)1979-2007 Dave Dunfield\r\n"
			.STR	"2012 Roman Borik\r\n"
			.STR	"2018 Martin Maly\r\n"
			.STR	"2018 Johnny Quest\r\n"
			.STRZ	"All rights reserved.\r"
			LXI		H,UBASE 		;Point to start of reserved RAM
			MVI		C,(<DSTACK - <UBASE)	;Number of bytes to zero
INIL1:		MVI		M,0 			;Clear a byte
			INX		H				;Advance
			DCR		C				;Reduce count
			JNZ		INIL1 			;Clear em all
			LXI		H,0xFFFF		;Set flags
			SHLD	SFLAG 			;Turn on SUBTRACE & AUTOREG
			LXI		H,UBASE 		;Default user stack (below monitor RAM)
			SHLD	SP				;Set user SP
			;Newline and prompt for command
RECR:		CALL	CRLF 			;Output a newline
			;Prompt for an input command
REST:		LXI		SP,DSTACK		;Reset stack pointer
			CALL	PRTMSG			;Output message
			.STRZ	"MON85> "		;Command prompt
			CALL	INPT			;Get command character
			;Look up command in table
			MOV		B,A				;Save for later
			LXI		H,CTABLE	 	;Point to command table
REST1:		MOV		A,M				;Get char
			INX		H				;Advance
			CMP		B				;Do it match?
			JZ		REST2			;Yes, go for it
			INX		H				;Skip HIGH address
			INX		H				;Skip LOW address
			ANA		A				;end of table?
			JNZ		REST1 			;Its OK
			;Error has occured, issue message & return for command
ERROR:		MVI		A,'? 			;Error indicator
			CALL	OUT 			;Display
			JMP		RECR 			;And wait for command
			;We have command, execute it
REST2:		INX		D				;Skip command character
			MOV		A,M 			;Get low address
			INX		H				;Skip to next
			MOV		H,M 			;Get HIGH address
			MOV		L,A 			;Set LOW
			CALL	SKIP 			;Set 'Z' of no operands
			PCHL					;And execute
			;Table of commands to execute
CTABLE:		.DB		 'A 			;Set AUTOREG flag
			.DW		 AUTO
			.DB		 'B 			;Set/Display breakpoint
			.DW		 SETBRK
			.DB		 'C 			;Copy memory
			.DW		 COPY
			.DB		 'D 			;Disassemble
			.DW		 GODIS
			.DB		 'E 			;Edit memory
			.DW		 EDIT
			.DB		 'F 			;Fill memory
			.DW		 FILL
			.DB		 'G 			;Go (begin execution)
			.DW		 GO
			.DB		 'H 			;Send out memory as Intel HEX
			.DW		 SNDHEX
			.DB		 'I 			;Input from port
			.DW		 INPUT
			.DB		 'J 			;Jump to TinyBASIC
			.DW		 JUMP
			.DB		 'L 			;Load from serial port
			.DW		 LOAD
			.DB		 'M 			;Memory display
			.DW		 MEMRY
			.DB		 'O 			;Output to port
			.DW		 OUTPUT
			.DB		 'R 			;Set/Display Registers
			.DW		 REGIST
			.DB		 'S 			;Set SUBTRACE flag
			.DW		 SUBON
			.DB		 'T 			;Set TRACE mode
			.DW		 TRACE
			.DB		 'U 			;Set/Display user base
			.DW		 USRBASE
			.DB		 '? 			;Help command
			.DW		 HELP
			.DB		 0				;End of table
			.DW		 REST 			;Handle NULL command
			;
			;Help command
			;
HELP:		LXI		H,HTEXT 		;Point to help text
			SUB		A				;Get a zero
			STA		OFLAG 			;Clear the output flag
			;Output each line
HELP1:		MVI		C,25 			;Column counter
HELP2:		MOV		A,M 			;Get character
			INX		H				;Advance to next
			ANA		A				;End of line?
			JZ		HELP4 			;Yes, terminate
			CPI		'!				;Separator?
			JZ		HELP3 			;Yes, output
			CALL	OUT 			;Write character
			DCR		C				;Reduce count
			JMP		HELP2 			;Keep going
			;Fill with spaces to discription column
HELP3:		CALL	SPACEFILL		;Output a space
			DCR		C				;Reduce count
			JNZ		HELP3 			;Do them all
			MVI		A,'- 			;Spperator
			CALL	OUT 			;Display
			CALL	SPACEFILL		;And space over
			JMP		HELP2 			;Output rest of line
									;End of line encountered...
HELP4:		CALL	CHKSUS 			;New line
			MOV		A,M 			;Get next byte
			ANA		A				;End of text?
			JNZ		HELP1 			;Do them all
			JMP		RECR 			;And go home
			;
			;Input from port
			;
INPUT:		CALL	CALC8 			;Get port number
			MVI		A,0xDB 			;'IN' instruction
			MVI		H,0xC9 			;'RET' instruction
			STA		INST 			;Set RAM instruction
			SHLD	INST+1 			;Set RAM instruction
			CALL	PRTMSG 			;Output message
			.STRZ	"DATA="
			CALL	INST 			;Perform the read
			CALL	HPR 			;Output it
			JMP		RECR 			;Newline & EXIT
			;
			;Output to port
			;
OUTPUT:		CALL	CALC8 			;Get port number
			MVI		A,0xD3 			;'OUT' instruction
			MVI		H,0xC9 			;'RET' instruction
			STA		INST 			;Set RAM instruction
			SHLD	INST+1 			;Set RAM instruction
			CALL	CALC8 			;Get data byte
			CALL	INST 			;Output the data
			JMP		REST 			;Back to command prompt
			;
			;Jump to TinyBASIC or IMSAI 9K FP BASIC
			; Test for its existence first!
JUMP:		CALL	CALC8 			;Get BASIC version, A holds #
			CPI		2				;IMSAI BASIC?
			JZ		JUMP2			;Yes, test and execute
			CPI		1				;TinyBASIC?
			JNZ		ERROR			;Error if not
JUMP1:		LDA     TBASIC			;Fetch 1st OPcode from ROM
			CPI     0x31			;1st OPcode is an LXI SP?
			JNZ     JUMP9			;No match, restart monitor
			LDA     TBASIC+3		;Fetch 4th OPcode from ROM
			CPI     0x3E			;4th OPcode is an MVI?
			JNZ     JUMP9			;No match, restart monitor
;			LXI		H,JUMPM			;Send CAPS lock message
;			CALL	PRTSTR
			JMP     TBASIC			;Execute TinyBASIC
JUMP2:		LDA     IBASIC			;Fetch 1st OPcode from ROM
			CPI     0x21			;1st OPcode is an LXI H?
			JNZ     JUMP9			;No match, restart monitor
			LDA     IBASIC+5		;Fetch 4th OPcode from ROM
			CPI     0xC3			;4th OPcode is an JMP?
			JNZ     JUMP9			;No match, restart monitor
;			LXI		H,JUMPM			;Send CAPS lock message
;			CALL	PRTSTR
			JMP     IBASIC			;Execute TinyBASIC
JUMP9:		CALL	PRTMSG 			;Output error message below
			.STRZ	"\n\nBASIC not available.\r\n"
			JMP     REST			;No match, restart monitor
;JUMPM:		.STRZ	"\n\n\n! Use CAPS lock !\n\n"
			;
			;Set breakpoint command
			;
SETBRK:		JZ		DISBRK 			;No operands, display breakpoints
			;Set a breakpoint
			CALL	CALC8 			;Get hex operand
			CPI		8				;In range?
			JNC		ERROR 			;No, invalid
			LXI		H,BRKTAB-3 		;Point to breakpoint table
			LXI		B,3 			;Offset for a breakpoint
SBRLP:		DAD		B				;Advance to next breakpoint
			DCR		A				;Reduce count
			JP		SBRLP 			;Go until we are there
			PUSH	H				;Save table address
			CALL	CALC 			;Get address
			POP		D				;Restore address
			XCHG					;D=brkpt address, H=table address
			MOV		M,D 			;Set HIGH address in table
			INX		H				;Advance
			MOV		M,E 			;Set LOW address in table
			INX		H				;Advance
			LDAX	D				;Get opcode from memory
			MOV		M,A 			;Save in table
			JMP		REST 			;And get next command
			;Display breakpoints
DISBRK:		LXI		D,BRKTAB 		;Point to breakpoint table
			MVI		B,'0 			;Begin with breakpoint zero
DISLP:		MVI		A,'B 			;Lead in character
			CALL	OUT 			;Output
			MOV		A,B 			;Get breakpoint number
			CALL	OUT 			;Output
			MVI		A,'= 			;Seperator character
			CALL	OUT 			;Output
			LDAX	D				;Get HIGH address
			MOV		H,A 			;Copy
			INX		D				;Advance
			LDAX	D				;Get LOW address
			MOV		L,A 			;Copy
			ORA		H				;Is breakpoint set?
			JZ		NOTSET 			;No, don't display
			CALL	HLOUT 			;Output in hex
			JMP		GIVLF 			;And proceed
			;Breakpoint is not set
NOTSET:		CALL	PRTMSG 			;Output message
			.STRZ	"****"			;Indicate not set
GIVLF:		MVI		A,SPACE			;Get a space
			CALL	OUT 			;Output
			CALL	OUT 			;Output
			MOV		A,B 			;Get breakpoint address
			CPI		'0+3 			;Halfway through?
			CZ		CRLF 			;Yes, new line
			INX		D				;Skip low byte
			INX		D				;Skip opcode
			INR		B				;Advance breakpoint number
			MOV		A,B 			;Get number again
			CPI		'0+8 			;All done?
			JC		DISLP 			;No, keep going
			CALL	CRLF 			;New line
			LXI		H,AUTMSG		;Message for AFLAG
			LDA		AFLAG 			;Get flag state
			CALL	DISON 			;Display ON/OFF indication
			LXI		H,SUBMSG		;Message for SFLAG
			LDA		SFLAG 			;Get flag state
			CALL	DISON 			;Display ON/OFF indication
			LXI		H,TRCMSG 		;Message for TFLAG
			LDA		TFLAG 			;Get flag state
			CALL	DISON 			;Display ON/OFF indication
			CALL	CRLF 			;New line
			JMP		REST 			;Back for another command
			;Display ON/OFF flag state
DISON:		PUSH	PSW 			;Save A
			CALL	PRTSTR 			;Output message
			POP		PSW 			;Restore A
			LXI		H,OFF 			;Assume OFF
			ANA		A				;Test A
			JZ		PRTSTR 			;Yes, display OFF
			LXI		H,ON 			;Convert to ON
			JMP		PRTSTR 			;And display ON
			;
			;GO command, Begin program execution
			;
GO:			JZ		NOHEX 		;Address not given, assume default
			CALL	CALC 		;Get argument
			SHLD	PC 			;Save new PC value
NOHEX:		LDA		TFLAG 		;Get trace flag
			ANA		A 			;Enabled?
			JNZ		TRTB 		;Yes, wait for prompt
			;Single-step one instruction...
			;Used for first instruction even when NOT tracing, so
			;that we can insert breakpoints
NOADR:		SUB		A 			;Get NOP
			MOV		H,A 		;Set high
			MOV		L,A 		;Set LOW
			STA		INST 		;Set first byte
			SHLD	INST+1 		;Set second & third
			LHLD	PC 			;Get PC
			XCHG				;Set DE to PC
			CALL	LOOK 		;Lookup instruction
			MOV		B,A 		;Save the TYPE/LENGTH byte
			ANI		0x03 		;Mask TYPE, save LENGTH
			MOV		C,A 		;Save for count
			;Copy instruction into "faking" area
			LXI		H,INST 		;Point to saved instruction
GOSET:		LDAX	D 			;Get byte from code
			MOV		M,A 		;Save in instruction
			INX		H 			;Advance output
			INX		D 			;Advance input
			DCR		C 			;Reduce count
			JNZ		GOSET 		;Copy it all
			XCHG				;HL = addrss to execute
			MVI		A,0xC3 		;Get a JMP instruction
			STA		INST+3 		;Set up a JUMP instruction
			SHLD	INST+4 		;Set target address
			LDA		TFLAG 		;Get trace flag
			ANA		A 			;Are we tracing?
			JZ		NOTRC 		;No, we are not
			PUSH	B 			;Save TYPE/LENGTH
			LHLD	INST+4 		;Get termination address
			INX		H 			;Skip this one
			SHLD	BUFFER 		;Save for "fake" handling
			LXI		H,FAKE 		;Point to FAKE routine
			SHLD	INST+4 		;Save new addres
			POP		B 			;Restore TYPE/LENGTH
			;Simulate any control transfer instruction
			LDA		INST 		;Get instruction
			CPI		0xE9 		;Is it PCHL?
			JNZ		NOPCHL 		;No, skip
			LHLD	HL 			;Get user HL value
			JMP		HLJMP 		;And simulate a jump
NOPCHL:		CPI		0xCB 		;Is it RSTV?
			JNZ		NORSTV 		;No, skip
			LDA		PSW 		;Get status flags
			ANI		2 			;Check V flag
			JNZ		NOTRC 		;Is set, execute instruction
			STA		INST 		;Change to NOP
			JMP		NOTRC 		;Not set, execute NOP
NORSTV:		CPI		0xDD 		;Is it JNK?
			JZ		JNKJK 		;Yes, go
			CPI		0xFD 		;Is it JK?
			JNZ		NOJNK 		;No, skip
JNKJK:		ANI		0x20 		;Save K flag from instruction code
			MOV		C,A
			LDA		PSW 		;Get status flags
			ANI		0x20 		;Save only K flag
			XRA		C 			;Compare them
			JZ		NOPSH 		;If they are equal, make jump
			JMP		NOTRC 		;No jump
NOJNK:		MOV		A,B 		;Get TYPE back
			CPI		0x0B 		;Is it a 'JUMP'
			JZ		GOJMP 		;Yes, handle it
			CPI		0x05 		;Is it a 'RETURN'
			JZ		CALRET 		;Yes, handle it
			ANI		0xF8 		;Save only conditional bits
			JZ		NOTRC 		;Not conditional, always execute instruction
			ANI		0x08 		;Does this test require COMPLEMENTED flags
			LDA		PSW 		;Get status flags
			JZ		NOCOM 		;No need to complement
			CMA					;Invert for NOT tests
NOCOM:		MOV		C,A 		;Save PSW bits
			MOV		A,B 		;Get conditon back
			RAL					;Is it SIGN flag?
			JC		SIGN 		;Yes, handle it
			RAL					;Is it ZERO flag?
			JC		ZERO 		;Yes, handle it
			RAL					;Is it PARITY flag?
			JC		PARITY 		;Yes, handle it
			;This instruction is conditional on the CARRY flag
CARRY:		MOV		A,C 		;Get flag bits
			ANI		0x01 		;Test CARRY flag
			JMP		ENFLG 		;And proceed
			;This instruction is conditional on the SIGN flag
SIGN:		MOV		A,C 		;Get flag bits
			ANI		0x80 		;Test SIGN flag
			JMP		ENFLG 		;And proceed
			;This instruction is conditional on the ZERO flag
ZERO:		MOV		A,C 		;Get flag bits
			ANI		0x40 		;Test ZERO flag
			JMP		ENFLG 		;And proceed
			;This instruction is conditional on the PARITY flag
PARITY:		MOV		A,C 		;Get flag bits
			ANI		0x04 		;Test PARITY flag
			;Execute conditional instruction
ENFLG:		JZ		NOTRC 		;Not executed
			MOV		A,B 		;Get type back
			ANI		0x04 		;Is it JUMP
			JNZ		CALRET 		;No, try next
			;Simulate a JUMP instruction
GOJMP:		LDA		INST 		;Get instruction
			CPI		0xCD 		;Is it a CALL
			JZ		PADR 		;Yes
			ANI		0xC7 		;Mask conditional
			CPI		0xC4 		;Conditional call?
			JNZ		NOPSH 		;No, its a jump
			;Simulate a subroutine trace
PADR:		LDA		SFLAG 		;Get subroutine tracing flag
			ANA		A 			;Is it set?
			JZ		NOTRC 		;No, simulate as one instruction
			LHLD	BUFFER 		;Get termination address
			DCX		H 			;Backup
			XCHG				;D = address
			LHLD	SP 			;Get user SP
			DCX		H 			;Backup
			MOV		M,D 		;Set HIGH return address
			DCX		H 			;Backup
			MOV		M,E 		;Set LOW return address
			SHLD	SP 			;Resave user SP
			;Continue simulation of a JUMP type instruction
NOPSH:		LHLD	INST+1 		;Get target address
			JMP		HLJMP 		;And proceed
			;Handle simulation of RETURN instruction
CALRET:		LHLD	SP 			;Get sser SP
			MOV		E,M 		;Get LOW return address
			INX		H 			;Advance
			MOV		D,M 		;Get HIGH return address
			INX		H 			;Advance
			SHLD	SP 			;Resave user SP
			XCHG				;Set HL = address
			;Simulate a jump to the address in HL
HLJMP:		INX		H 			;Advance
			SHLD	BUFFER 		;Save new target address
			SUB		A 			;Get NOP
			MOV		H,A 		;Set HIGH
			MOV		L,A 		;Set LOW
			STA		INST 		;NOP first byte
			SHLD	INST+1 		;NOP second byte
			;Dispatch the user program
			;First, insert any breakpoints into the object code
NOTRC:		LXI		D,BRKTAB 	;Point to breakpoint table
			MVI		C,8 		;Size of table (in entries)
RESBP:		LDAX	D 			;Get a HIGH address
			MOV		H,A 		;Save for later
			INX		D 			;Advance
			LDAX	D 			;Get low address
			MOV		L,A 		;Save for later
			INX		D 			;Advance
			ORA		H 			;Is breakpoint enabled?
			JZ		NORES 		;No, its not
			MVI		M,0xCF 		;Set up a RST 1 breakpoint
NORES:		INX		D 			;Skip opcode
			DCR		C 			;Reduce count
			JNZ		RESBP 		;Do them all
			;Restore the user applications registers
			LHLD	SP 			;Get stack pointer
			SPHL				;Set stack pointer
			LHLD	BC 			;Get BC
			PUSH	H 			;Save
			POP		B 			;And set
			LHLD	PSW 		;Get PSW
			PUSH	H 			;Save
			POP		PSW 		;And set
			LHLD	DE 			;Get DE
			XCHG				;Set DE
			LHLD	HL 			;Get HL
			JMP		INST 		;Execute "faked" instruction
			;Trace routine: simulate a breakpoint interrupt
FAKE:		PUSH	H 			;Save HL on stack
			LHLD	BUFFER 		;Get address to execute
			XTHL				;Restore HL, [SP] = address
			JMP		ENTRY 		;Display the registers
			;
			;Display/Change registers
			;
REGIST:		JNZ		CHG1 		;Register name to change is given
			;Display registers
			CALL	REGDIS 		;Display registers
			JMP		REST 		;And exit
			;Set register value
CHG1:		MOV		B,A 		;Save first register name char
			CALL	GETCHI 		;Get char (in upper case)
			MOV		C,A 		;Save for later
			JZ		OKCH 		;End of string
			;Drop extra characters incase 'PSW'
CHG2:		CALL	GETCHR 		;Get next
			JNZ		CHG2 		;Clean them out
			;Get new value for register
OKCH:		CALL	CALC 		;Get new value
			MOV		A,B 		;Get first char
			CPI		'H 			;Is it HL pair
			JNZ		CDE 		;No, try next
			SHLD	HL 			;Set HL value
			JMP		REST 		;And proceed
CDE:		CPI		'D 			;Is it DE pair?
			JNZ		CBC 		;No, try next
			SHLD	DE 			;Set DE value
			JMP		REST 		;And proceed
CBC:		CPI		'B 			;Is it BC pair?
			JNZ		CSP 		;No, try next
			SHLD	BC 			;Set BC value
			JMP		REST 		;And proceed
CSP:		CPI		'S 			;Is it SP?
			JNZ		CP 			;No, try next
			SHLD	SP 			;Set SP value
			JMP		REST 		;And proceed
CP:			CPI		'P 			;Is it PS or PC
			JNZ		ERROR 		;No, error
			MOV		A,C 		;Get low character
			CPI		'S 			;Is it PSW?
			JNZ		CPC 		;No, try next
			SHLD	PSW 		;Set new PSW
			JMP		REST 		;And proceed
CPC:		CPI		'C 			;Is it PC?
			JNZ		ERROR 		;No, error
			SHLD	PC 			;Set new PC
			JMP		REST 		;And proceed
			;Process an ON/OFF operand
ONOFF:		CALL	SKIP 		;Get next char
			CPI		'O 			;Must begin with ON
			JNZ		ERROR 		;Invalid
			CALL	GETCHI 		;Get next char
			MVI		B,0 		;Assume OFF
			CPI		'F 			;OFF?
			JZ		RETON 		;Yes, set it
			CPI		'N 			;ON?
			JNZ		ERROR 		;No, error
			DCR		B 			;Convert to FF
RETON:		MOV		A,B 		;Save new value
			RET

			;
			;Turn automatic register display ON or OFF
			;
AUTO:		CALL	ONOFF 		;Get ON/OFF value
			STA		AFLAG 		;Set AUTOREG flag
			JMP		REST 		;And proceed

			;
			;Turn SUBROUTINE tracing ON or OFF
			;
SUBON:		CALL	ONOFF 		;Get ON/OFF value
			STA		SFLAG 		;Set SUBTRACE flag
			JMP		REST 		;And proceed

			;
			;Set TRACE mode ON or OFF
			;
TRACE:		CALL	ONOFF 		;Get ON/OFF value
			STA		TFLAG 		;Set TRACE flag
			JMP		REST 		;And proceed

			;
			;Edit memory contents
			;
EDIT:		CALL	CALC 		;Get address
EDIT1:		CALL	HLOUT 		;Display address
			CALL	SPACEFILL	;Separator
			MOV		A,M 		;Get contents
			CALL	HPR 		;Output
			MVI		A,'= 		;Prompt
			CALL	OUT 		;Output
			PUSH	H 			;Save address
			CALL	INPT 		;Get a value
			POP		H 			;Restore address
			INX		H 			;Assume advance
			JZ		EDIT1 		;Null, advance
			DCX		H 			;Fix mistake
			DCX		H 			;Assume backup
			CPI		'- 			;Backup?
			JZ		EDIT1 		;Yes, backup a byte
			INX		H 			;Fix mistake
			CPI		0x27 		;Single quote?
			JNZ		EDIT3 		;No, try hex value
			;Handle quoted ASCII text
			INX		D 			;Skip the quote
EDIT2:		LDAX	D 			;Get char
			INX		D 			;Advance input
			ANA		A 			;End of loop?
			JZ		EDIT1 		;Yes, exit
			MOV		M,A 		;Save it
			INX		H 			;Advance output
			JMP		EDIT2 		;And proceed
			;Handle HEXIDECIMAL values
EDIT3:		PUSH	H 			;Save address
			CALL	CALC8 		;Get HEX value
			POP		H 			;HL = address
			MOV		M,A 		;Set value
			INX		H 			;Advance to next
			CALL	SKIP 		;More operands?
			JNZ		EDIT3 		;Get then all
			JMP		EDIT1 		;And continue

			;
			;FIll memory with a value
			;
FILL:		CALL	CALC 		;Get starting address
			PUSH	H 			;Save for later
			CALL	CALC 		;Get ending address
			PUSH	H 			;Save for later
			CALL	CALC8 		;Get value
			MOV		C,A 		;C = value
			POP		D
			INX		D 			;DE = End address+1
			POP		H 			;HL = Starting address
			CALL	COMP16 		;Is Start<End ?
			JNC		ERROR 		;Yes, bad entry
FILL1:		MOV		M,C 		;Save one byte
			INX		H 			;Advance
			CALL	COMP16 		;Test for match
			JC		FILL1 		;And proceed
			JMP		REST 		;Back for next

			;
			;16 bit compare of HL to DE
			;
COMP16:		MOV		A,H 		;Get HIGH
			CMP		D 			;Match?
			RNZ					;No, we are done
			MOV		A,L 		;Get LOW
			CMP		E 			;Match?
			RET

			;
			;Copy a block of memory
			;
COPY:		CALL	CALC 		;Get SOURCE address
			PUSH	H 			;Save for later
			CALL	CALC 		;Get DEST Address
			PUSH	H 			;Save for later
			CALL	CALC 		;Get size
			MOV		B,H 		;BC = Size
			MOV		C,L
			POP		D 			;DE = Dest address
			POP		H 			;HL = Source
			MOV		A,B 		;Size is zero?
			ORA		C
			JZ		REST 		;Yes, exit
			CALL	COMP16 		;Compare source and destination address
			JC		COPY2 		;Dest > Source, jump
			;Source > Dest
COPY1:		MOV		A,M 		;Get byte from source
			STAX	D 			;Write to dest
			INX		H 			;Advance source
			INX		D 			;Advance dest
			DCX		B 			;Reduce count
			MOV		A,C 		;Count is zero ?
			ORA		B
			JNZ		COPY1 		;No, continue
			JMP		REST
			;Dest > Source
COPY2:		DAD		B 			;Move source and destination address to end
			DCX		H 			;of block
			XCHG
			DAD		B
			DCX		H
COPY3:		LDAX	D 			;Get byte from source
			MOV		M,A 		;Write to dest
			DCX		D 			;Decrement source address
			DCX		H 			;Decrement destination address
			DCX		B 			;Reduce count
			MOV		A,C 		;Count is zero ?
			ORA		B
			JNZ		COPY3 		;No, continue
			JMP		REST

			;
			;Display a block of memory
			;
MEMRY:		CALL	CALC 		;Get operand
			SUB		A 			;Get a ZERO
			STA		OFLAG 		;Clear output flag
ALOOP:		CALL	HLOUT2 		;Display address (in hex) with 2 spaces
			MVI		D,16 		;16 bytes/line
			PUSH	H 			;Save address
ALP1:		MOV		A,M 		;Get byte
			CALL	HPR 		;Output in hex
			CALL	SPACEFILL	;Space over
			MOV		A,D 		;Get count
			CPI		9 			;At boundary?
			CZ		SPACEFILL	;Yes, extra space
			MOV		A,D 		;Get count
			ANI		7 			;Mask for low bits
			CPI		5 			;At boundary?
			CZ		SPACEFILL	;Extra space
			INX		H 			;Advance address
			DCR		D 			;Reduce count
			JNZ		ALP1 		;Do them all
			MVI		D,4 		;# separating spaces
AL2:		CALL	SPACEFILL	;Output a space
			DCR		D 			;Reduce count
			JNZ		AL2 		;And proceed
			POP		H
			MVI		D,16 		;16 chars/display
AL3:		MOV		A,M 		;Get data byte
			CALL	OUTP 		;Display (if printable)
			INX		H 			;Advance to next
			DCR		D 			;Reduce count
			JNZ		AL3 		;Do them all
			CALL	CHKSUS 		;Handle output suspension
			JMP		ALOOP 		;And continue

			;
			;Perform disassembly to console
			;
GODIS:		CALL	CALC 		;Get starting address
			PUSH	H 			;Save address
			POP		D 			;Copy to D
			SUB		A 			;Get a zero
			STA		OFLAG 		;Clear output flag
VLOOP:		CALL	DINST 		;Display one instruction
			CALL	CHKSUS 		;Handle output
			JMP		VLOOP 		;And proceed

			;
			;Set/display user base address
			;
USRBASE:	JNZ		USRB1 		;Address is given, set it
			CALL	PRTMSG 		;Output message
			.STRZ	"BASE="
			LHLD	UBASE 		;Get address
			CALL	HLOUT 		;Output
			JMP		RECR 		;New line & exit
USRB1:		CALL	CALC 		;Get operand
			SHLD	UBASE 		;Set the address
			JMP		REST 		;and return

			;
			;Send out as Intel HEX
			;
SNDHEX:		CALL	CALC 		;Get start address
			PUSH	H 			;Save for later
			CALL	CALC 		;Get end address
			INX		H 			;HL = end+1
			POP		D 			;DE = start
			CALL	COMP16 		;Check for Start > End
			JC		ERROR 		;Bad entry
			MOV		A,L 		;Compute length
			SUB		E
			MOV		L,A
			MOV		A,H
			SBB		D
			MOV		H,A
			XCHG				;HL = start, DE = length
SNDHX1:		MOV		A,D 		;Finish ?
			ORA		E
			JZ		SNDHX3 		;Yes, jump
			MVI		B,16 		;16 bytes per record
			MOV		A,D 		;Is rest > 16 ?
			ORA		A
			JNZ		SNDHX2 		;No, jump
			MOV		A,E
			CMP		B
			JNC		SNDHX2 		;No, jump
			MOV		B,E 		;Yes, B=rest
SNDHX2:		CALL	SHXRC 		;Send out one record
			JMP		SNDHX1 		;continue
			;
SNDHX3:		CALL	PRTMSG
			.STRZ	   ":00000001FF\r\n"
			JMP		REST
			;
SHXRC:		MVI		A,': 		;Start record
			CALL	OUT
			MOV		A,B 		;Length
			MOV		C,A 		;Init checksum
			CALL	HPR 		;Output in hex
			MOV		A,H 		;High byte of address
			ADD		C 			;Include in checksum
			MOV		C,A 		;Re-save
			MOV		A,H
			CALL	HPR 		;Output in hex
			MOV		A,L 		;Low byte of address
			ADD		C 			;Include in checksum
			MOV		C,A 		;Re-save
			MOV		A,L
			CALL	HPR 		;Output in hex
			XRA		A 			;Record type
			CALL	HPR
SHXRC1:		MOV		A,M 		;One byte
			ADD		C 			;Include in checksum
			MOV		C,A 		;Re-save
			MOV		A,M
			INX		H
			CALL	HPR 		;Output in hex
			DCX		D 			;Decrement main counter
			DCR		B 			;Decrement bytes per record counter
			JNZ		SHXRC1
			MOV		A,C 		;Negate checksum
			CMA
			INR		A
			CALL	HPR 		;Output in hex
			JMP		CRLF

			;
			;Download command
			;
LOAD:		MVI		A,0x0F 		;Get default initial state
			JZ		LOAD1 		;Address not given...
			CALL	CALC 		;Get operand value
			SHLD	BUFFER+3 	;Save for later calulation
			MVI		A,0xFF 		;Set new initial state
			;Setup the offset calculator
LOAD1:		LXI		H,0 		;Assume no offset
			STA		BUFFER 		;Set mode flag
			SHLD	BUFFER+1 	;Assume offset is ZERO
			;Download the records
LOAD2:		CALL	DLREC 		;Get a record
			JNZ		DLBAD 		;Report error
			JNC		LOAD2 		;Get them all
			JMP		DLWAIT 		;And back to monitor
			;Error in receiving download record
DLBAD:		CALL	PRTMSG 		;Output message
			.STRZ	"?Load error\r\n"
			;Wait till incoming data stream stops
DLWAIT:		MVI		C,0 		;Initial count
DLWAIT1:	CALL	IN 			;Test for input
			ANA		A 			;Any data
			JNZ		DLWAIT 		;Reset count
			DCR		C 			;Reduce counter
			JNZ		DLWAIT1 	;Keep looking
			JMP		REST 		;Back to monitor

			;
			;Download a record from the serial port
			;
DLREC:		CALL	INCHR 		;Read a character
			;****************************************************
			; SV - added means to escape from download
			CPI		ESCAPE 		;ESCAPE?
			JZ		RECR 		;Yes, abort
			;****************************************************
			CPI		': 			;Start of Intel record?
			JZ		DLINT 		;Download INTEL format
			CPI		'S 			;Is it MOTOROLA?
			JNZ		DLREC 		;No, keep looking
			;Download a MOTOROLA HEX format record
DLMOT:		CALL	INCHR 		;Get next character
			;****************************************************
			; SV - added means to escape from download
			CPI		ESCAPE 		;ESCAPE?
			JZ		RECR 		;Yes, abort
			;****************************************************
			CPI		'0 			;Header record?
			JZ		DLREC 		;Yes, skip it
			CPI		'9 			;End of file?
			JZ		DLEOF 		;Yes, report EOF
			CPI		'1 			;Type 1 (code) record
			JNZ		DLERR 		;Report error
			CALL	GETBYT 		;Get length
			MOV		C,A 		;Start checksum
			SUI		3 			;Convert for overhead
			MOV		B,A 		;Save data length
			CALL	GETBYT 		;Get first byte of address
			MOV		H,A 		;Set HIGH address
			ADD		C 			;Include in checksum
			MOV		C,A 		;And re-save
			CALL	GETBYT 		;Get next byte of address
			MOV		L,A 		;Set LOW address
			ADD		C 			;Include in checksum
			MOV		C,A 		;And re-save
			CALL	SETOFF 		;Handle record offsets
DMOT1:		CALL	GETBYT 		;Get a byte of data
			MOV		M,A 		;Save in memory
			INX		H 			;Advance
			ADD		C 			;Include in checksum
			MOV		C,A 		;And re-save
			DCR		B 			;Reduce length
			JNZ		DMOT1 		;Keep going
			CALL	GETBYT 		;Get record checksum
			ADD		C 			;Include calculated checksum
			INR		A 			;Adjust for test
			ANA		A 			;Clear carry set Z
			RET

			;Download a record in INTEL hex format
DLINT:		CALL	GETBYT 		;Get length
			ANA		A 			;End of file?
			JZ		DLEOF 		;Yes, handle it
			MOV		C,A 		;Begin Checksum
			MOV		B,A 		;Record length
			CALL	GETBYT 		;Get HIGH address
			MOV		H,A 		;Set HIGH address
			ADD		C 			;Include in checksum
			MOV		C,A 		;Re-save
			CALL	GETBYT 		;Get LOW address
			MOV		L,A 		;Set LOW address
			ADD		C 			;Include in checksum
			MOV		C,A 		;Re-save
			CALL	SETOFF 		;Handle record offsets
			CALL	GETBYT 		;Get type byte
			ADD		C 			;Include in checksum
			MOV		C,A 		;Re-save
DLINT1:		CALL	GETBYT 		;Get data byte
			MOV		M,A 		;Save in memory
			INX		H 			;Advance to next
			ADD		C 			;Include in checksum
			MOV		C,A 		;Resave checksum
			DCR		B 			;Reduce count
			JNZ		DLINT1 		;Do entire record
			CALL	GETBYT 		;Get record checksum
			ADD		C 			;Add to computed checksum
			ANA		A 			;Clear carry, set Z
			RET
			;End of file on download
DLEOF:		STC					;Set carry, EOF
			RET

			;
			;Process record offsets for download records
			;
SETOFF:		LDA		BUFFER 		;Get flag
			ANA		A 			;Test flag
			JNZ		SETOF1 		;Special case
			;Not first record, adjust for offset & proceed
			XCHG				;DE = address
			LHLD	BUFFER+1 	;Get offset
			DAD		D 			;HL = address + offset
			RET
			;First record, set USER BASE & calculate offset (if any)
SETOF1:		XRA		A	 		;Get zero (NO CC)
			STA		BUFFER 		;Clear flag
			SHLD	UBASE 		;Set user program base
			RP					;No more action
			;Calculate record offset to RAM area
			XCHG				;DE = address
			LHLD	BUFFER+3 	;Get operand
			MOV		A,L 		;Subtract
			SUB		E 			;Record
			MOV		L,A 		;From
			MOV		A,H 		;Operand
			SBB		D 			;To get
			MOV		H,A 		;Offset
			SHLD	BUFFER+1 	;Set new offset
			DAD		D 			;Get address
			RET

			;
			;Gets a byte of HEX data from serial port.
			;
GETBYT:		CALL	GETNIB 		;Get first nibble
			RLC					;Shift into
			RLC					;Upper nibble
			RLC					;Of result
			RLC					;To make room for lower
			MOV		E,A 		;Keep high digit
			CALL	GETNIB 		;Get second digit
			ORA		E 			;Insert high digit
			RET
			;GETS A NIBBLE FROM THE TERMINAL (IN ASCII HEX)
GETNIB:		CALL	INCHR 		;Get a character
			SUI		'0 			;Is it < '0'?
			JC		GETN1 		;Yes, invalid
			CPI		10 			;0-9?
			RC					;Yes, its OK
			SUI		7 			;Convert
			CPI		10 			;9-A?
			JC		GETN1 		;Yes, invalid
			CPI		16 			;A-F?
			RC					;Yes, its OK
GETN1:		POP		D 			;Remove GETNIB RET addr
			POP		D 			;Remove GETBYT RET addr
			;Error during download record
DLERR:		ORI		0xFF 		;Error indicator
			RET

			;
			;Read an input line from the console
			;
INPT:		LXI		H,BUFFER 	;Point to input buffer
INPT1:		CALL	INCHR 		;Get a char
			CPI		ESCAPE 		;ESCAPE?
			JZ		RECR 		;Back for command
			CPI		CR 			;Carriage return?
			JZ		INPT4 		;Yes, exit
			MOV		D,A 		;Save for later
			;Test for DELETE function
			CPI		0x7F 		;Is it delete?
			JZ		INPT3 		;Yes, it is
			CPI		0x08 		;Backspace?
			JZ		INPT3 		;Yes, it is
			;Insert character in buffer
			MOV		A,L 		;Get low address
			CPI		>BUFFER+30	;Beyond end?
			MVI		A,7 		;Assume error
			JZ		INPT2 		;Yes, report error
			MOV		A,D 		;Get char back
			MOV		M,A 		;Save in memory
			INX		H			;Advance
INPT2:		CALL	OUT 		;Echo it
			JMP		INPT1 		;And proceed
			;Delete last character from buffer
INPT3:		MOV		A,L 		;Get char
			CPI		<BUFFER 	;At begining
			MVI		A,7 		;Assume error
			JZ		INPT2 		;Report error
			PUSH	H			;Save H
			CALL	PRTMSG 		;Output message
			.DB		 8,SPACE,8,0	;Wipe away character
			POP		H 			;Restore H
			DCX		H 			;Backup
			JMP		INPT1 		;And proceed
			;Terminate the command
INPT4:		MVI		M,0 		;Zero terminate
			CALL	CRLF 		;New line
			LXI		D,BUFFER 	;Point to input buffer
			;Advance to next non-blank in buffer
SKIP:		LDAX	D 			;Get char from buffer
			INX		D 			;Advance
			CPI		SPACE		;Space?
			JZ		SKIP 		;Yes, keep looking
			DCX		D 			;Backup to it
			JMP		TOCAP 		;And convert to upper

			;
			;Read next character from command & convert to upper case
			;
GETCHI:		INX		D 			;Skip next character
GETCHR:		LDAX	D 			;Get char from command line
			ANA		A 			;End of line?
			RZ					;Yes, return with it
			INX		D 			;Advance command pointer
			;
			;Convert character in A to uppercase, set Z if SPACE or EOL
			;
TOCAP:		CPI		0x61 		;Lower case?
			JC		TOCAP1 		;Yes, its ok
			ANI		0x5F 		;Convert to UPPER
TOCAP1:		CPI		SPACE		;Space
			RZ					;Yes, indicate
			ANA		A 			;Set 'Z' if EOL
			RET

			;
			;Get 8 bit HEX operands to command
			;
CALC8:		CALL	CALC 		;Get operand
			MOV		A,H 		;High byte must be zero
			ORA		A
			JNZ		ERROR 		;Bad value
			MOV		A,L 		;Value also to A
			RET

			;
			;Get 16 bit HEX operands to command
			;
CALC:		PUSH	B 			;Save B-C
			CALL	SKIP 		;Find start of operand
			LXI		H,0 		;Begin with zero value
			MOV		C,H 		;Clear flag
CALC1:		CALL	GETCHR 		;Get next char
			JZ		CALC3 		;End of number
			CALL	VALHEX 		;Is it valid hex?
			JC		ERROR 		;No, report error
			DAD		H 			;HL = HL*2
			DAD		H 			;HL = HL*4
			DAD		H 			;HL = HL*8
			DAD		H 			;HL = HL*16 (Shift over 4 bits)
			SUI		'0 			;Convert to ASCII
			CPI		10 			;Decimal number?
			JC		CALC2 		;Yes, its ok
			SUI		7 			;Convert to HEX
CALC2:		ORA		L 			;Include in final value
			MOV		L,A 		;Resave low byte
			MVI		C,0xFF 		;Set flag & indicate we have char
			JMP		CALC1 		;And continue
			;End of input string was found
CALC3:		MOV		A,C 		;Get flag
			POP		B 			;Restore B-C
			ANA		A 			;Was there any digits?
			JZ		ERROR 		;No, invalid
			RET
			;Test for character in A as valid hex
VALHEX:		CPI		'0 			;< '0'
			RC					;Too low
			CPI		'G 			;>'F'
			CMC					;Set C state
			RC					;Too high
			CPI		0x3A 		;<='9'
			CMC					;Set C state
			RNC					;Yes, its OK
			CPI		'A 			;Set C if < 'A'
			RET

			;
			;Display the user process registers
			;
REGDIS:
;*** JQ - Changed order of displayed registers
			LHLD	PSW			;Get saved PSW
			LXI		B,#"FA 		;And register names
			CALL	OUTPT 		;Output
;************

			LHLD	BC 			;Get saved BC pair
			LXI		B,#"CB 		;And register names
			CALL	OUTPT 		;Output

			LHLD	DE 			;Get saved DE pair
			LXI		B,#"ED 		;And register names
			CALL	OUTPT 		;Output

			LHLD	HL 			;Get saved HL pair
			LXI		B,#"LH 		;And register names
			CALL	OUTPT 		;Output

			LHLD	SP 			;Get saved SP
			LXI		B,#"PS 		;And register name
			CALL	OUTPT 		;Output

			LHLD	PC 			;Get saved PC
			LXI		B,#"CP 		;And regsiter name
			CALL	OUTPT 		;Output

;*** JQ - Changed order of displayed registers
;			CALL	PRTMSG 		;Output message
;			.STRZ	" PSW="
;			LHLD	PSW 		;Get saved PSW
;			CALL	HLOUT2 		;Output value (with two spaces)
;************

			CALL	PRTMSG 		;Output
			.STRZ	" FLAGS="
			LHLD	PSW-1 		;Get Flags to H
			MVI		B,'S 		;'S' flag
			CALL	OUTB 		;Display
			MVI		B,'Z 		;'Z' flag
			CALL	OUTB 		;Display
			MVI		B,'K 		;'K' flag
			CALL	OUTB 		;Display
			MVI		B,'A 		;'A' flag
			CALL	OUTB 		;Display
			MVI		B,'3 		;3. bit flag
			CALL	OUTB 		;Display
			MVI		B,'P 		;'P' flag
			CALL	OUTB 		;Display
			MVI		B,'V 		;'V' flag
			CALL	OUTB 		;Display
			MVI		B,'C 		;'C' flag
			CALL	OUTB 		;Display
			JMP		CRLF 		;New line & exit
			;
			;Display contents of a register pair
OUTPT:		MOV		A,B 		;Get first char of name
			CALL	OUT 		;Output
			MOV		A,C 		;Get second char of name
			CALL	OUT 		;Output
			MVI		A,'= 		;Get separator
			CALL	OUT 		;Output
HLOUT2:		CALL	HLOUT 		;Output value
			CALL	SPACEFILL	;Output a space
			;Display a space on the console
SPACEFILL:	MVI		A,SPACE		;Get a spave
			JMP		OUT 		;Display it
			;Display an individual flag bit B=title, H[7]=bit
OUTB:		DAD		H 			;Shift H[7] into carry
			MVI		A,'- 		;Dash for not set flag
			JNC		OUT 		;Display dash
			MOV		A,B 		;Get character
			JMP		OUT 		;And display

			;
			;Display an instruction in disassembly format
			;
DINST:		PUSH	D 			;Save address
			MOV		A,D 		;Get high value
			CALL	HPR 		;Output
			MOV		A,E 		;Get low address
			CALL	HPR 		;Output
			CALL	SPACEFILL	;Output a space
			CALL	LOOK 		;Lookup instruction
			ANI		0x03 		;Save length
			PUSH	PSW 		;Save length
			PUSH	H 			;Save table address
			MVI		B,4 		;4 spaces total
			MOV		C,A 		;Save count
			DCX		D 			;Backup address
			;Display the opcode bytes in HEX
VLP1:		INX		D 			;Advance
			LDAX	D 			;Get opcode
			CALL	HPR 		;Output in HEX
			CALL	SPACEFILL	;Separator
			DCR		B 			;Reduce count
			DCR		C 			;Reduce count of opcodes
			JNZ		VLP1 		;Do them all
			;Fill in to boundary
VLP2:		CALL	SPACEFILL	;Space over
			CALL	SPACEFILL	;Space over
			CALL	SPACEFILL	;Space over
			DCR		B 			;Reduce count
			JNZ		VLP2 		;Do them all
			;DISPLAY ASCII equivalent of opcodes
			POP		B 			;Restore table address
			POP		PSW 		;Restore type/length
			POP		D 			;Restore instruction address
			PUSH	D 			;Resave
			PUSH	PSW 		;Resave
			MVI		H,8 		;8 spaces/field
			ANI		0x0F 		;Save only length
			MOV		L,A 		;Save for later
PCHR:		LDAX	D 			;Get byte from opcode
			INX		D 			;Advance
			CALL	OUTP 		;Display (if printable)
			DCR		H 			;Reduce field count
			DCR		L 			;Reduce opcode count
			JNZ		PCHR 		;Do them all
			;Space over to instruction address
SPLP:		CALL	SPACEFILL	;Output a space
			DCR		H 			;Reduce count
			JNZ		SPLP 		;Do them all
			MVI		D,6 		;Field width
VLP3:		LDAX	B 			;Get char from table
			ANA		A 			;End of string?
			JZ		VOUT1 		;Yes, exit
			CALL	OUT 		;Output it
			INX		B 			;Advance to next
			DCR		D 			;reduce count
			CPI		SPACE		;end of name?
			JNZ		VLP3 		;no, keep going
			;Fill in name field with spaces
VOUT:		DCR		D 			;reduce count
			JZ		VLP3 		;Keep going
			CALL	SPACEFILL	;Output a space
			JMP		VOUT 		;And proceed
			;Output operands for the instruction
VOUT1:		POP		PSW 		;Restore type
			POP		D 			;Restore instruction address
			DCR		A 			;Is it type1?
			JZ		T1 			;Yes, handle it
			;Type 2 -	One byte immediate date
T2:			PUSH	PSW 		;Save type
			MVI		A,'$ 		;Get HEX indicator
			CALL	OUT 		;Output
			POP		PSW 		;Restore type
			DCR		A 			;Type 2?
			JNZ		T3 			;No, try next
			INX		D 			;Advance to data
			LDAX	D 			;Get data
			CALL	HPR 		;Output in HEX
			;Type 1 - No operand
T1:			INX		D
			RET
			;Type 3 - Two bytes immediate data
T3:			INX		D 			;Skip to low
			INX		D 			;Skip to high
			LDAX	D 			;Get HIGH
			CALL	HPR 		;Output
			DCX		D 			;Backup to low
			LDAX	D 			;Get LOW
			CALL	HPR 		;Output
			INX		D 			;Advance to high
			INX		D
			RET

			;
			;Look up instruction in table & return TYPE/LENGTH[A], and string[HL]
			;
LOOK:		PUSH	D 			;Save DE
			LDAX	D 			;Get opcode
			MOV		B,A 		;Save for later
			LXI		H,ITABLE 	;Point to table
LOOK1:		MOV		A,B 		;Get Opcode
			ANA		M 			;Mask
			INX		H 			;Skip mask
			CMP		M 			;Does it match
			INX		H 			;Skip opcode
			JZ		LOOK3 		;Yes, we found it
			;This wasn't it, advance to the next
LOOK2:		MOV		A,M 		;Get byte
			INX		H 			;Advance to next
			ANA		A 			;End of string?
			JNZ		LOOK2 		;No, keep looking
			JMP		LOOK1 		;And continue
			;We found the instruction, copy over the text description
LOOK3:		MOV		C,M 		;Save type
			INX		H 			;Skip type
			LXI		D,BUFFER 	;Point to text buffer
LOOK4:		MOV		A,M 		;Get char from source
			INX		H 			;Advance to next
			;Insert a RESTART vector number
			CPI		'v 			;Restart vector
			JNZ		LOOK5 		;No, its OK
			MOV		A,B 		;Get opcode
			RRC					;Shift it
			RRC					;Over
			RRC					;To low digit
			ANI		0x07 		;Remove trash
			ADI		'0 			;Convert to digit
			JMP		LOOK10 		;And set the character
			;Insert a register pair name
LOOK5:		CPI		'p 			;Register PAIR?
			JNZ		LOOK6 		;No, try next
			MOV		A,B 		;Get opcode
			RRC					;Shift
			RRC					;Over into
			RRC					;Low digit
			RRC					;For lookup
			ANI		0x03 		;Save only RP
			PUSH	H 			;Save HL
			LXI		H,RPTAB 	;Point to pair table
			JMP		LOOK9 		;And proceed
			;Insert destination register name
LOOK6:		CPI		'd 			;Set destination?
			JNZ		LOOK7 		;No, try next
			MOV		A,B 		;Get opcode
			RRC					;Shift
			RRC					;Into low
			RRC					;digit
			JMP		LOOK8 		;And proceed
			;Insert source register name
LOOK7:		CPI		's 			;Source register?
			JNZ		LOOK10 		;No, its OK
			MOV		A,B 		;Get opcode
			;Lookup a general processor register
LOOK8:		ANI		0x07 		;Save only source
			PUSH	H 			;Save HL
			LXI		H,RTAB 		;Point to table
			;Lookup register in table
LOOK9:		ADD		L 			;Offset to value
			MOV		L,A 		;Resave address
			MOV		A,M 		;Get character
			CPI		'S 			;'SP' register ?
			JNZ		LOOK9A 		;No, skip
			STAX	D 			;Save 'S'
			INX		D 			;Advance to next
			MVI		A,'P 		;Character 'P'
LOOK9A:		POP		H 			;Restore HL
			;Save character in destination string
LOOK10:		STAX	D 			;Save value
			INX		D 			;Advance to next
			ANA		A 			;End of list?
			JNZ		LOOK4 		;No, keep copying
			;End of LIST
			LXI		H,BUFFER 	;Point to description
			MOV		A,C 		;Get length
			POP		D 			;Restore DE
			RET

			;
			;Opcode disassembly table: MASK, OPCODE, TYPE/LENGTH, STRINGZ
			;
ITABLE:
			.DB		 0xFF,0xFE,0x02
			.STRZ	 "CPI "
			.DB		 0xFF,0x3A,0x03
			.STRZ	 "LDA "
			.DB		 0xFF,0x32,0x03
			.STRZ	 "STA "
			.DB		 0xFF,0x2A,0x03
			.STRZ	 "LHLD "
			.DB		 0xFF,0x22,0x03
			.STRZ	 "SHLD "
			.DB		 0xFF,0xF5,0x01
			.STRZ	 "PUSH PSW"
			.DB		 0xFF,0xF1,0x01
			.STRZ	 "POP PSW"
			.DB		 0xFF,0x27,0x01
			.STRZ	 "DAA"
			.DB		 0xFF,0x76,0x01
			.STRZ	 "HLT"
			.DB		 0xFF,0xFB,0x01
			.STRZ	 "EI"
			.DB		 0xFF,0xF3,0x01
			.STRZ	 "DI"
			.DB		 0xFF,0x37,0x01
			.STRZ	 "STC"
			.DB		 0xFF,0x3F,0x01
			.STRZ	 "CMC"
			.DB		 0xFF,0x2F,0x01
			.STRZ	 "CMA"
			.DB		 0xFF,0xEB,0x01
			.STRZ	 "XCHG"
			.DB		 0xFF,0xE3,0x01
			.STRZ	 "XTHL"
			.DB		 0xFF,0xF9,0x01
			.STRZ	 "SPHL"
			.DB		 0xFF,0xE9,0x01
			.STRZ	 "PCHL"
			.DB		 0xFF,0xDB,0x02
			.STRZ	 "IN "
			.DB		 0xFF,0xD3,0x02
			.STRZ	 "OUT "
			.DB		 0xFF,0x07,0x01
			.STRZ	 "RLC"
			.DB		 0xFF,0x0F,0x01
			.STRZ	 "RRC"
			.DB		 0xFF,0x17,0x01
			.STRZ	 "RAL"
			.DB		 0xFF,0x1F,0x01
			.STRZ	 "RAR"
			.DB		 0xFF,0xC6,0x02
			.STRZ	 "ADI "
			.DB		 0xFF,0xCE,0x02
			.STRZ	 "ACI "
			.DB		 0xFF,0xD6,0x02
			.STRZ	 "SUI "
			.DB		 0xFF,0xDE,0x02
			.STRZ	 "SBI "
			.DB		 0xFF,0xE6,0x02
			.STRZ	 "ANI "
			.DB		 0xFF,0xF6,0x02
			.STRZ	 "ORI "
			.DB		 0xFF,0xEE,0x02
			.STRZ	 "XRI "
			.DB		 0xFF,0x00,0x01
			.STRZ	 "NOP"
			;8085 specific instructions
			.DB		 0xFF,0x20,0x01
			.STRZ	 "RIM"
			.DB		 0xFF,0x30,0x01
			.STRZ	 "SIM"
			;8085 undocumented instructions
			.DB		 0xFF,0x08,0x01
			.STRZ	 "DSUB B"
			.DB		 0xFF,0x10,0x01
			.STRZ	 "ARHL"
			.DB		 0xFF,0x18,0x01
			.STRZ	 "RDEL"
			.DB		 0xFF,0x28,0x02
			.STRZ	 "LDHI "
			.DB		 0xFF,0x38,0x02
			.STRZ	 "LDSI "
			.DB		 0xFF,0xCB,0x01
			.STRZ	 "RSTV"
			.DB		 0xFF,0xD9,0x01
			.STRZ	 "SHLX D"
			.DB		 0xFF,0xDD,0x03
			.STRZ	 "JNK "
			.DB		 0xFF,0xED,0x01
			.STRZ	 "LHLX D"
			.DB		 0xFF,0xFD,0x03
			.STRZ	 "JK "
			;Jumps, Calls & Returns
			.DB		 0xFF,0xC3,0x0B
			.STRZ	 "JMP "
			.DB		 0xFF,0xCA,0x43
			.STRZ	 "JZ "
			.DB		 0xFF,0xC2,0x4B
			.STRZ	 "JNZ "
			.DB		 0xFF,0xDA,0x13
			.STRZ	 "JC "
			.DB		 0xFF,0xD2,0x1B
			.STRZ	 "JNC "
			.DB		 0xFF,0xEA,0x23
			.STRZ	 "JPE "
			.DB		 0xFF,0xE2,0x2B
			.STRZ	 "JPO "
			.DB		 0xFF,0xFA,0x83
			.STRZ	 "JM "
			.DB		 0xFF,0xF2,0x8B
			.STRZ	 "JP "
			.DB		 0xFF,0xCD,0x0B
			.STRZ	 "CALL "
			.DB		 0xFF,0xCC,0x43
			.STRZ	 "CZ "
			.DB		 0xFF,0xC4,0x4B
			.STRZ	 "CNZ "
			.DB		 0xFF,0xDC,0x13
			.STRZ	 "CC "
			.DB		 0xFF,0xD4,0x1B
			.STRZ	 "CNC "
			.DB		 0xFF,0xEC,0x23
			.STRZ	 "CPE "
			.DB		 0xFF,0xE4,0x2B
			.STRZ	 "CPO "
			.DB		 0xFF,0xFC,0x83
			.STRZ	 "CM "
			.DB		 0xFF,0xF4,0x8B
			.STRZ	 "CP "
			.DB		 0xFF,0xC9,0x05
			.STRZ	 "RET"
			.DB		 0xFF,0xC8,0x45
			.STRZ	 "RZ"
			.DB		 0xFF,0xC0,0x4D
			.STRZ	 "RNZ"
			.DB		 0xFF,0xD8,0x15
			.STRZ	 "RC"
			.DB		 0xFF,0xD0,0x1D
			.STRZ	 "RNC"
			.DB		 0xFF,0xE8,0x25
			.STRZ	 "RPE"
			.DB		 0xFF,0xE0,0x2D
			.STRZ	 "RPO"
			.DB		 0xFF,0xF8,0x85
			.STRZ	 "RM"
			.DB		 0xFF,0xF0,0x8D
			.STRZ	 "RP"
			;Register based instructions
			.DB		 0xC0,0x40,0x01
			.STRZ	 "MOV d,s"
			.DB		 0xC7,0x06,0x02
			.STRZ	 "MVI d,"
			.DB		 0xF8,0x90,0x01
			.STRZ	 "SUB s"
			.DB		 0xF8,0x98,0x01
			.STRZ	 "SBB s"
			.DB		 0xF8,0x80,0x01
			.STRZ	 "ADD s"
			.DB		 0xF8,0x88,0x01
			.STRZ	 "ADC s"
			.DB		 0xF8,0xA0,0x01
			.STRZ	 "ANA s"
			.DB		 0xF8,0xB0,0x01
			.STRZ	 "ORA s"
			.DB		 0xF8,0xA8,0x01
			.STRZ	 "XRA s"
			.DB		 0xF8,0xB8,0x01
			.STRZ	 "CMP s"
			.DB		 0xC7,0x04,0x01
			.STRZ	 "INR d"
			.DB		 0xC7,0x05,0x01
			.STRZ	 "DCR d"
			;Register pair instructions
			.DB		 0xCF,0x01,0x03
			.STRZ	 "LXI p,"
			.DB		 0xEF,0x0A,0x01
			.STRZ	 "LDAX p"
			.DB		 0xEF,0x02,0x01
			.STRZ	 "STAX p"
			.DB		 0xCF,0x03,0x01
			.STRZ	 "INX p"
			.DB		 0xCF,0x0B,0x01
			.STRZ	 "DCX p"
			.DB		 0xCF,0x09,0x01
			.STRZ	 "DAD p"
			.DB		 0xCF,0xC5,0x01
			.STRZ	 "PUSH p"
			.DB		 0xCF,0xC1,0x01
			.STRZ	 "POP p"
			;Restart instruction
			.DB		 0xC7,0x0C7,0x01
			.STRZ	 "RST v"
			;This entry always matches invalid opcodes
			.DB		 0x00,0x00,0x01
			.STRZ	 "DB "
			;Misc Strings and messages
ON:			.STRZ	 "ON "
OFF:		.STRZ	 "OFF"
AUTMSG:		.STRZ	 "AUTOREG="
SUBMSG:		.STRZ	 " SUBTRACE="
TRCMSG:		.STRZ	 " TRACE="
HTEXT:		.STRZ	 "MON85 Commands:\r\n"
			.STRZ	 "A ON|OFF!Enable/Disable Automatic register display"
			.STRZ	 "B [bp address]!Set/Display breakpoints"
			.STRZ	 "C <src> <dest> <size>!Copy memory"
			.STRZ	 "D <address>!Display memory in assembly format"
			.STRZ	 "E <address>!Edit memory"
			.STRZ	 "F <start> <end> <value>!Fill memory"
			.STRZ	 "G [address]!Begin/Resume execution"
			.STRZ	 "H <start> <end>!Send out memory in Intel HEX format"
			.STRZ	 "I <port>!Input from port"
			.STRZ	 "J <1|2>!Jump to (1)TinyBASIC or (2)IMSAI FP BASIC"
			.STRZ	 "L [address]!Load image into memory"
			.STRZ	 "M <address>!Display memory in hex dump format"
			.STRZ	 "O <port> <data>!Output to port"
			.STRZ	 "R [rp value]!Set/Display program registers"
			.STRZ	 "S ON|OFF!Enable/Disable Subroutine trace"
			.STRZ	 "T ON|OFF!Enable/Disable Trace mode"
			.STRZ	 "U [address]!Set/Display program base address"
			.DB		 0
			;
			;Read a character, and wait for it
			;
INCHR:		CALL	IN 			;Check for a character
			ANA		A 			;Is there any data?
			JZ		INCHR 		;Wait for it
			RET

			;
			;Display HL in hexidecimal
			;
HLOUT:		MOV		A,H 		;Get HIGH byte
			CALL	HPR 		;Output
			MOV		A,L 		;Get LOW byte

			;
			;Display A in hexidecimal
			;
HPR:		PUSH	PSW 		;Save low digit
			RRC					;Shift
			RRC					;high
			RRC					;digit
			RRC					;into low
			CALL	HOUT 		;Display a single digit
			POP		PSW 		;Restore low digit
HOUT:		ANI		0x0F 		;Remove high digit
			CPI		10 			;Convert to ASCII
			SBI		0x2F
			DAA
			JMP		OUT 		;And output it

			;
			;Display message [PC]
			;
PRTMSG:		POP		H 			;Get address
			CALL	PRTSTR 		;Output message
			PCHL				;And return

			;
			;Display message [HL]
			;
PRTSTR:		MOV		A,M 		;Get byte from message
			INX		H 			;Advance to next
			ANA		A 			;End of message?
			RZ					;Yes, exit
			CALL	OUT 		;Output the character
			JMP		PRTSTR 		;And proceed

			;
			;Handle output suspension
			;
CHKSUS:		CALL	CRLF 		;New line
			LDA		OFLAG 		;Is output suspended?
			ANA		A 			;Test flag
			JNZ		CHKS1 		;Yes it is
			CALL	IN 			;Test for ABORT (escape) or PAUSE (space)
			CPI		ESCAPE 		;ESCAPE?
			JZ		REST 		;Abort
			CPI		SPACE		;SPACE - Suspend command
			RNZ
			STA		OFLAG 		;Set the flag
			;Output is suspended, wait for command
CHKS1:		CALL	INCHR 		;Get char
			CPI		SPACE		;One line?
			RZ					;Allow it
			CPI		ESCAPE 		;ESCAPE?
			JZ		REST 		;Abort
			CPI		CR 			;Resume?
			JNZ		CHKS1 		;Keep going
			SUB		A 			;Reset flag
			STA		OFLAG 		;Write it
			RET

			;Display a character if its printable
OUTP:		CPI		SPACE		;< ' '
			JC		OUTP1 		;Invalid, exchange it
			CPI		0x7F 		;Printable?
			JC		OUT 		;Ok to display
OUTP1:		MVI		A,'. 		;Set to DOT to indicate invalid
			JMP		OUT 		;And display

			;
			;Write a Line-Feed and Carriage-Return to console
			;
CRLF:		MVI		A,CR 		;Carriage return
			CALL	OUT 		;Output
			MVI		A,LF 		;Line-feed

		;*** NOTE: "OUT" routine MUST follow immediately!

		.IF ENBL_8251 == 1		;Enable i8251 UART
	.MSG	"!! i8251 UART enabled for SIO function."
UART		.EQU	IO7			; IO address of 8251 UART (IO)
UART_D		.EQU	UART		; Data address
UART_C		.EQU	UART+1		; Control/Status address

RXRDY		.EQU	0b00000010	;RXRDY flag bit in status byte
TXRDY		.EQU	0b00000001	;TXRDY flag bit in status byte

			; User supplied I/O routines.
			;-----------------------------------------------------------
			; These example routines are suitable for use on the
			; 8085SBC
			;

			; Write character in A to console (8251 uart)
OUT:		PUSH	PSW			;Save char
OUT1:		IN		UART_C		;Get 8251 status
			RRC					;Test TX bit
			JNC		OUT1		;Not ready
			POP		PSW			;Restore char
			OUT		UART_D		;Write 8251 data
			RET

			; Check for a character from the console (8251 uart)
IN:			IN		UART_C		;Get 8251 status
			ANI		RXRDY		;Test for RX ready
			RZ					;No char, A=0
			IN		UART_D		;Get 8251 data
			RET

			; Initialize the uart
			; Must force setup mode with 3 consecutive NULL characters
			;
INIT:		XRA	A				; Insure not setup mode
			OUT	UART_C			; Write once
			OUT	UART_C			; Write again (now in operate mode)
			OUT	UART_C			; Write again (now in operate mode)
			;Issue internal RESET
			MVI	A,0x40			; Return to setup mode
			OUT	UART_C			; write it
			;Issue Mode Set
		.IF MSTR_CLK == 1
		.MSG "4.9152MHz Clock Source Selected for i8251"
			MVI	A,0x4E			; 8 data, 1 stop, x16
		.ELSE
		.MSG "3.6864MHz Clock Source Selected for i8251"
			MVI	A,0x4D			; 8 data, 1 stop, x1
		.ENDIF
			OUT	UART_C			; Write it
			;Issue Command Set
			MVI	A,0x37			; RTS,DTR,Enable RX and TX
			OUT	UART_C			; Write it
			RET
			;
		.ENDIF

		.IF ENBL_6850 == 1		;Enable MC6850 ACIA
			;-----------------------------------------------------------
			;User supplied I/O routines.
			;OMEN Alpha fix for 6850 ACIA
			;-----------------------------------------------------------
			;
	.MSG	"!! MC68B50 ACIA enabled for SIO function."
ACIA		.EQU	 0xC0
ACIAC		.EQU	 ACIA
ACIAS		.EQU	 ACIA
ACIAD		.EQU	 ACIA+1

ACIA_TDRE	.EQU	 0b00000010
ACIA_RDRF	.EQU	 0b00000001

			;Write character in A to console (6850 acia)
OUT:		PUSH	PSW 		;Save char
			IN		ACIAS 		;Get 6850 status
			ANI		ACIA_RDRF 	;Test RX bit
			JZ		OUT1 		;No RX character waiting
			CALL	ACIA_ISR	;Let the ISR handle it
			RET					;Return to caller
OUT1:		IN		ACIAS 		;Get 6850 status
			ANI		ACIA_TDRE 	;Test TX bit
			JZ		OUT1 		;Not ready
			POP		PSW 		;Restore char
			OUT		ACIAD 		;Write 6850 data
			RET					;Return to caller

		.IF	0	; Set to "0" to enable original polled code
			;Check for a character from the console (6850 acia)
		;*** 2018-0920 - JQ - Added ACIA RX buffer for 6850 RX bug fix!
IN:			DI
			LDA		ACIA_BUFF	;Fetch RX buffer in RAM
			ANA		A			;Test for new character (A != NULL)
			JZ		IN1			;Exit if not a new character
			PUSH	PSW			;New character, so save it
			XRA		A			;Clear the RX buffer in RAM
			STA		ACIA_BUFF
			POP		PSW			;Restore the character
IN1:		EI					;Re-enable interrupts
			RET					;Return to caller

		.ELSE
			; !!! Original Code !!!
			; Check for a character from the console (6850 acia)
IN:			IN		ACIAS 		;Get 6850 status
			ANI		ACIA_RDRF 	;Test for ready
			RZ					;No char
			IN		ACIAD 		;Get 6850 data
			RET
		.ENDIF

		;***************************************************************
		; 2018-0921 - JQ - 6850 ACIA bug fix!
		; An active RDRF flag is clobbered by a write to the ACIA
		; data register and subsequent TDRE flag update. Using RX
		; interrupt, fetch and store the new character in RAM for the
		; IN routine to fetch.
		;
ACIA_ISR:	PUSH	PSW			;Save flags
			IN		ACIAS		;Get the ACIA status
			ANI		ACIA_RDRF	;Check RDRF flag
			JZ		ACIA_ISR1	;No RDRF, so ignore this IRQ
			IN		ACIAD 		;Get 6850 data
			STA		ACIA_BUFF	;Save character in RAM
ACIA_ISR1:	POP		PSW			;Restore flags
			EI					;Re-enable interrupts
			RET					;Return to caller

			;Initialize the 6850 ACIA
INIT:		MVI		A,0x03 		;Master RESET first!
			OUT		ACIAC
		.IF MSTR_CLK
		.MSG "4.9152MHz Clock Source Selected for MC6850"
			MVI		A,0x96 		;divide by 64 for 38400 Bd, 8 bit, no parity, 1 stop bit, w/ IRQ @ 4.5192MHz
		.ELSE
		.MSG "3.6864MHz Clock Source Selected for MC6850"
			MVI		A,0x95		;divide by 16 for 115200 Bd, 8 bit, no parity, 1 stop bit, w/ IRQ @ 3.6864MHz
		.ENDIF
			OUT		ACIAC
			RET
			;
		.ENDIF
		;***************************************************************

			;***********************************************************
			;User supplied I/O routines.
			;JQ - addition for INS8255 port bit routines
			;-----------------------------------------------------------
			;
		.IF ENBL_PIO == 1
			;
PIO0_PA		.EQU	 IO0+0
PIO0_PB		.EQU	 IO0+1
PIO0_PC		.EQU	 IO0+2
PIO0_CTL	.EQU	 IO0+3
			;
			; Pulse all bits of PortA
PULSPORTA:	MVI		A,0xFF			;bits all high
			OUT		PIO0_PA
			NOP						;wait a cycle
			CMA						;compliment A
			OUT		PIO0_PA
			RET
			;
			; Pulse all bits of PortB
PULSPORTB:	MVI		A,0xFF			;bits all high
			OUT		PIO0_PB
			NOP						;wait a cycle
			CMA						;compliment A
			OUT		PIO0_PB
			RET
			;
			; Output A to PortA
OUTPORTA:	PUSH	PSW			;save character
			OUT		PIO0_PA
			POP		PSW			;restore character
			RET
			;
OUTPORTB:	PUSH	PSW			;save character
			OUT		PIO0_PB
			POP		PSW			;restore character
			RET
			;
PIOINIT:	MVI		A,0x80 		; All ports are outputs
			OUT		PIO0_CTL
			RET
			;
		.ENDIF

