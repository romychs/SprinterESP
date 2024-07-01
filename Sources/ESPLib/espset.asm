; ======================================================
; ESPSET for SprinterWiFi for Sprinter computer
; By Romych, 2024
; https://github.com/romychs
; ======================================================

; Set to 1 to turn debug ON with DeZog VSCode plugin
; Set to 0 to compile .EXE
DEBUG               EQU 0
TRACE               EQU 1
EXE_VERSION         EQU 1
DEFAULT_TIMEOUT		EQU	2000

    SLDOPT COMMENT WPMEM, LOGPOINT, ASSERTION

    DEVICE NOSLOT64K

    IF  DEBUG == 1
		INCLUDE "dss.asm"
		DB 0
		ALIGN 16384, 0
        DS 0x80, 0
    ENDIF

	MACRO	SEND_CMD	data
	LD		HL, data
	CALL	WIFI.UART_TX_CMD
	CALL	CHECK_ERROR
	ENDM	

	; MACRO 	PRINT	data
	; LD		HL,data
    ; LD      C,DSS_PCHARS
    ; RST     DSS
	; ENDM

	MACRO 	PRINTLN	data
	LD		HL,data
    LD      C,DSS_PCHARS
    RST     DSS
	LD		HL, LINE_END
	RST     DSS
	ENDM

	INCLUDE "dss.inc"
	INCLUDE "sprinter.inc"

	MODULE MAIN

    ORG 0x8080

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

    PRINTLN MSG_START

	CALL	FIND_SWF

	; Turn local echo Off
	CALL	INIT_ESP

	LD		B,0
	JP		EXIT


NO_TL_FOUND
	PRINTLN MSG_SWF_NOF
	LD		B,2
	JP		EXIT

CHECK_ERROR
	RET		NC
	ADD		A,'0'
	LD		(COMM_ERROR_NO), A
	PRINTLN	MSG_COMM_ERROR
	LD		B,3
	POP		HL											; ret addr reset

EXIT	
    LD		C,DSS_EXIT
    RST		DSS

FIND_SWF
	; Find Sprinter-WiFi
	CALL    WIFI.UART_FIND
	JP		C, NO_TL_FOUND
	LD		A,(ISA.ISA_SLOT)
	ADD		A,'1'
	LD      (MSG_SLOT_NO),A
	PRINTLN	MSG_SWF_FOUND
    LD      C,DSS_PCHARS
    RST     DSS
	RET
	


; ------------------------------------------------------
; Init basic parameters of ESP
; ------------------------------------------------------
INIT_ESP
	LD		DE, WIFI.RS_BUFF
	LD		BC, DEFAULT_TIMEOUT

 	IF TRACE
   	PRINTLN	MSG_ECHO_OFF
 	ENDIF
	SEND_CMD CMD_ECHO_OFF

 	IF TRACE
   	PRINTLN MSG_STATIOJN_MODE
 	ENDIF
	SEND_CMD CMD_STATION_MODE

 	IF TRACE
   	PRINTLN MSG_NO_SLEEP
 	ENDIF
	SEND_CMD CMD_NO_SLEEP

 	IF TRACE
   	PRINTLN MSG_SET_UART
 	ENDIF
	SEND_CMD CMD_SET_SPEED

	IF TRACE
   	PRINTLN MSG_SET_OPT
 	ENDIF
	SEND_CMD CMD_CWLAP_OPT
	
	RET

; ------------------------------------------------------
; Messages
; ------------------------------------------------------
MSG_START
	DB "ESP-Setup for Sprinter-WiFi by Romych's, (c) 2024\r\n", 0

MSG_SWF_NOF
	DB "Sprinter-WiFi not found!",0

MSG_SWF_FOUND
	DB "Sprinter-WiFi found in ISA#"
MSG_SLOT_NO
	DB "n slot.",0

MSG_COMM_ERROR
	DB "Error communication with Sprinter-WiFi #"
COMM_ERROR_NO
	DB "n!",0

; ------------------------------------------------------
; Debug messages
; ------------------------------------------------------
	IF TRACE

MSG_ECHO_OFF 
	DB "Echo off",0

MSG_STATIOJN_MODE
	DB "Station mode",0

MSG_NO_SLEEP
	DB "No sleep",0

MSG_SET_UART
	DB "Setup uart",0

MSG_SET_OPT
	DB "Set options",0

	ENDIF


; ------------------------------------------------------
; Commands
; ------------------------------------------------------
CMD_SET_SPEED 
	DB	"AT+UART_CUR=115200,8,1,0,3\r\n",0	
CMD_ECHO_OFF
	DB	"ATE0\r\n",0
CMD_STATION_MODE 
	DB	"AT+CWMODE=1\r\n",0
CMD_NO_SLEEP
	DB	"AT+SLEEP=0\r\n",0
CMD_CHECK_CONN_AP
	DB	"AT+CWJAP?\r\n",0
CMD_CWLAP_OPT
	DB	"AT+CWLAPOPT=1,23\r\n",0
CMD_GET_AP_LIST
	DB "AT+CWLAP\r\n",0
CMD_GET_DHCP
	DB "AT+CWDHCP?\r\n",0
CMD_SET_DHCP
	DB	"AT+CWDHCP=1,1\r\n",0
CMD_GET_IP
	DB "AT+CIPSTA?\r\n",0
LINE_END 
	DB "\r\n",0



	IF DEBUG == 1
CMD_TEST1	DB "ATE0\r\n",0	
BUFF_TEST1	DS RS_BUFF_SIZE,0
	ENDIF

	ENDMODULE

	INCLUDE "util.asm"
	INCLUDE "isa.asm"
	INCLUDE "esplib.asm"

    END MAIN.START

    ; PUSH	IX                                          ; IX ptr to cmd line
    ; POP		HL
    ; INC		HL                                          ; Skip size of Command line
    ; LD		DE,ZIP_FILE
    ; CALL 	GET_CMD_PARAM
    ; JR		C,INVALID_CMDLINE
    ; LD		DE,FILES_TO_ZIP
    ; CALL	GET_CMD_PARAM
    ; JR		C,INVALID_CMDLINE
