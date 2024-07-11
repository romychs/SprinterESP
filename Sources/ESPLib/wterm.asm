; ======================================================
; WTERM terminal for Sprinter-WiFi ISA Card
; For Sprinter computer DSS
; By Roman Boykov. Copyright (c) 2024
; https://github.com/romychs
; License: BSD 3-Clause
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

	MODULE	MAIN

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

	CALL	WCOMMON.INIT_ESP

; ------------------------------------------------------
; Do Some
; ------------------------------------------------------

OK_EXIT
	LD		B,0
	JP		WCOMMON.EXIT


; ------------------------------------------------------
; Custom messages
; ------------------------------------------------------
MSG_START
	DB "Terminal for Sprinter-WiFi by Sprinter Team. v1.0.1, ", __DATE__, "\r\n", 0

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
