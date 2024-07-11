; ======================================================
; ESPSET for Sprinter-WiFi for Sprinter computer
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

	; Display main menu to make selection
MENU_AGAIN
	CALL	SELECT_MAIN_MENU

	; Do somethink with selected item
	AND 	A
	JR		Z, MENU_EXIT
	DEC		A
	JP		Z, MENU_SELECT_WIFI
	DEC		A
	JP		Z, MENU_CONFIGURE_IP
	DEC		A
	JP		Z, MENU_DISPLAY_INFO
	JP		MENU_AGAIN

MENU_EXIT
	LD		B,0
	JP		EXIT


MENU_SELECT_WIFI
MENU_CONFIGURE_IP
MENU_DISPLAY_INFO
	JP		MENU_AGAIN

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
	PUSH	BC, DE
	LD		DE, WIFI.RS_BUFF
	LD		BC, DEFAULT_TIMEOUT

   	TRACELN	MSG_ECHO_OFF
	SEND_CMD CMD_ECHO_OFF

   	TRACELN MSG_STATIOJN_MODE
	SEND_CMD CMD_STATION_MODE

   	TRACELN MSG_NO_SLEEP
	SEND_CMD CMD_NO_SLEEP

   	TRACELN MSG_SET_UART
	SEND_CMD CMD_SET_SPEED

   	TRACELN MSG_SET_OPT
	SEND_CMD CMD_CWLAP_OPT
	POP		DE,BC
	RET

; ------------------------------------------------------
; Set DHCP mode
; Out: CF=1 if error
; ------------------------------------------------------
SET_DHCP_MODE
	PUSH	BC,DE
	LD		DE, WIFI.RS_BUFF
	LD		BC, DEFAULT_TIMEOUT
	TRACELN MSG_SET_DHCP
	SEND_CMD CMD_SET_DHCP
	POP		DE,BC
	RET



; ------------------------------------------------------
;  Output main menu to select user action
;  Ret: A = selected menu item
; ------------------------------------------------------
SELECT_MAIN_MENU
	PUSH	BC
	PRINTLN MSG_MAIN_MENU
SMM_L1
	PRINT MSG_ENT_NO
	; SCANF
	LD		C, DSS_ECHOKEY
	RST		DSS
	SUB		'0'
	; Test A in range [0..3]
	AND		A
	JP		M, SMM_L1
	CP		4
	JP 		P, SMM_L1
	POP		BC
	RET

; ------------------------------------------------------
; Messages	DB "\r\n1 - Select WiFi Network\r\n"
   	DB "2 - Configure IP parameters\r\n"
   	DB "3 - Display info\r\n"
	DB "0 - Exit",0

; ------------------------------------------------------
MSG_START
	DB "Setup for Sprinter-WiFi by Sprinter Team, ", __DATE__ ,"\r\n", 0

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

MSG_MAIN_MENU
	DB "\r\n1 - Select WiFi Network\r\n"
   	DB "2 - Configure IP parameters\r\n"
   	DB "3 - Display info\r\n"
	DB "0 - Exit",0

MSG_ENT_NO
	DB "\r\nEnter number 0..3: ",0
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

MSG_SET_DHCP
	DB	"Set DHCP mode",0

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
