; ======================================================
; WTERM for SprinterWiFi for Sprinter computer
; By Romych, 2024
; https://github.com/romychs
; ======================================================

; Set to 1 to turn debug ON with DeZog VSCode plugin
; Set to 0 to compile .EXE
DEBUG               EQU 0

; Set to 1 to output TRACE messages
TRACE               EQU 1

; Version of EXE file, 1 for DSS 1.70+
EXE_VERSION         EQU 0

; Timeout to wait ESP response
DEFAULT_TIMEOUT		EQU	2000

    SLDOPT COMMENT WPMEM, LOGPOINT, ASSERTION

    DEVICE NOSLOT64K
	
    IF  DEBUG == 1
		INCLUDE "dss.asm"
		DB 0
		ALIGN 16384, 0
        DS 0x80, 0
    ENDIF

	INCLUDE "macro.inc"
	INCLUDE "dss.inc"
	INCLUDE "sprinter.inc"

	MODULE MAIN

    ORG	0x8080
; ------------------------------------------------------
EXE_HEADER
    DB  "EXE"
    DB  EXE_VERSION                                     ; EXE Version
    DW  0x0080                                          ; Code offset
    DW  0
    DW  0                                               ; Primary loader size
    DW  0                                               ; Reserved
    DW  0
    DW  0
    DW  START                                           ; Loading Address
    DW  START                                           ; Entry Point
    DW  STACK_TOP                                       ; Stack address
    DS  106, 0                                          ; Reserved

    ORG 0x8100
@STACK_TOP
	
; ------------------------------------------------------
START
	
    IF DEBUG == 1
    ; LD 		IX,CMD_LINE1
	LD		SP, STACK_TOP
    ENDIF

	CALL 	ISA.ISA_RESET
	
	CALL	WCOMMON.INIT_VMODE

    PRINTLN MSG_START

	CALL	WCOMMON.FIND_SWF

	PRINTLN WCOMMON.MSG_UART_INIT
	CALL	WIFI.UART_INIT

	PRINTLN WCOMMON.MSG_ESP_RESET
	CALL	WIFI.ESP_RESET

	CALL	WIFI.UART_EMPTY_RS

	; IF TRACE
	; 	; Dump, DLB=0 registers
	; 	LD		BC, 0x0800
	; 	CALL	DUMP_REGS

	; 	; Dump, DLAB=1 registers
	; 	LD		HL, REG_LCR
	; 	LD		E, LCR_DLAB | LCR_WL8
	; 	CALL	WIFI.UART_WRITE
		
	; 	LD		BC, 0x0210
	; 	CALL	DUMP_REGS

	; 	LD		HL, REG_LCR
	; 	LD		E, LCR_WL8
	; 	CALL	WIFI.UART_WRITE
	; ENDIF

	; Turn local echo Off
	CALL	WCOMMON.INIT_ESP

; ------------------------------------------------------
;	Do Some
; ------------------------------------------------------

OK_EXIT
	LD		B,0
	JP		WCOMMON.EXIT


DUMP_REGS
	LD		HL, PORT_UART_A
	

DR_NEXT	
	LD		DE,MSG_DR_RN
	CALL	HEXB
	INC		C	

	CALL    WIFI.UART_READ
	PUSH    BC
	LD		C,A
	LD		DE,MSG_DR_RV
	CALL	HEXB
	PUSH 	HL	
	
	PRINTLN MSG_DR

	POP		HL,BC
	INC		HL
	DJNZ	DR_NEXT
	RET	

MSG_DR
	DB	"Reg[0x"
MSG_DR_RN	
	DB	"vv]=0x"
MSG_DR_RV	
	DB	"vv",0

; ------------------------------------------------------
; Byte to hex, 
;	Inp: C
;	Out: (DE)
; ------------------------------------------------------
HEXB
   LD		A,C
   RRA
   RRA
   RRA
   RRA
   CALL		CONV_NIBLE
   LD		A,C
CONV_NIBLE
   AND		0x0f
   ADD		A,0x90
   DAA
   ADC		A,0x40
   DAA
   LD		(DE), A
   INC		DE
   RET

; ------------------------------------------------------
; Custom messages
; ------------------------------------------------------
MSG_START
	DB "WTerm terminal for Sprinter-WiFi by Romych's, (c) 2024\r\n", 0

; ------------------------------------------------------
; Custom commands
; ------------------------------------------------------
CMD_QUIT 
    DB "QUIT\r",0

	IF DEBUG == 1
CMD_TEST1	DB "ATE0\r\n",0	
BUFF_TEST1	DS RS_BUFF_SIZE,0
	ENDIF

	ENDMODULE

	INCLUDE "wcommon.asm"
	INCLUDE "util.asm"
	INCLUDE "isa.asm"
	INCLUDE "esplib.asm"

    END MAIN.START
