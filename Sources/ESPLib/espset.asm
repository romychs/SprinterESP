; ======================================================
; ESPSET for SprinterWiFi for Sprinter computer
; By Romych, 2024
; https://github.com/romychs
; ======================================================

; Set to 1 to turn debug ON with DeZog VSCode plugin
; Set to 0 to compile .EXE
DEBUG               EQU 1
EXE_VERSION         EQU 1

    SLDOPT COMMENT WPMEM, LOGPOINT, ASSERTION

    DEVICE NOSLOT64K

    IF  DEBUG == 1
        DS 0x8080, 0
    ENDIF

	INCLUDE "dss.inc"
	INCLUDE "sprinter.inc"

	MODULE MAIN

    ORG 0x8080

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
	

START
	
    ; IF DEBUG == 1
    ; LD 		IX,CMD_LINE1
    ; ENDIF
	CALL 	ISA.ISA_RESET

    LD      HL,MSG_START
    LD      C,DSS_PCHARS
    RST     DSS

	IF	DEBUG==1
	LD		HL, CMD_TEST1
	LD		DE, BUFF_TEST1
	LD		BC, 100
	CALL	WIFI.UART_TX_CMD
	ENDIF
    ; PUSH	IX                                          ; IX ptr to cmd line
    ; POP		HL
    ; INC		HL                                          ; Skip size of Command line
    ; LD		DE,ZIP_FILE
    ; CALL 	GET_CMD_PARAM
    ; JR		C,INVALID_CMDLINE
    ; LD		DE,FILES_TO_ZIP
    ; CALL	GET_CMD_PARAM
    ; JR		C,INVALID_CMDLINE

EXIT	
    LD		BC,DSS_EXIT
    RST		DSS


MSG_START
	DB "ESPSET for Sprinter by Romych's, (c) 2024\n\r\n\r", 0

	IF DEBUG == 1
CMD_TEST1	DB "ATE0\r\n",0	
BUFF_TEST1	DS RS_BUFF_SIZE,0

	ENDIF

	ENDMODULE

	INCLUDE "util.asm"
	INCLUDE "isa.asm"
	INCLUDE "esplib.asm"

    END MAIN.START
