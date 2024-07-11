; ======================================================
; Common code for Sprinter-WiFi utilities
; By Roman Boykov. Copyright (c) 2024
; https://github.com/romychs
; License: BSD 3-Clause
; ======================================================

	MODULE WCOMMON

; ------------------------------------------------------
; Ckeck for error (CF=1) print message and exit
; ------------------------------------------------------

CHECK_ERROR
	RET		NC
	ADD		A,'0'
	LD		(COMM_ERROR_NO), A
	PRINTLN	MSG_COMM_ERROR
	CALL	DUMP_UART_REGS
	LD		B,3
	POP		HL											; ret addr reset

EXIT	
	CALL	REST_VMODE
    LD		C,DSS_EXIT
    RST		DSS

; ------------------------------------------------------
; Search Sprinter WiFi card
; ------------------------------------------------------
FIND_SWF
	; Find Sprinter-WiFi
	CALL    WIFI.UART_FIND
	JP		C, NO_TL_FOUND
	LD		A,(ISA.ISA_SLOT)
	ADD		A,'1'
	LD      (MSG_SLOT_NO),A
	PRINTLN	MSG_SWF_FOUND
	RET

NO_TL_FOUND
	POP 	BC
	PRINTLN MSG_SWF_NOF
	LD		B,2
	JP		EXIT


	IF TRACE
; ------------------------------------------------------
; Dump all UTL16C550 registers to screen for debug
; ------------------------------------------------------
DUMP_UART_REGS
		; Dump, DLAB=0 registers
		LD		BC, 0x0800
		CALL	DUMP_REGS

		; Dump, DLAB=1 registers
		LD		HL, REG_LCR
		LD		E, LCR_DLAB | LCR_WL8
		CALL	WIFI.UART_WRITE
		
		LD		BC, 0x0210
		CALL	DUMP_REGS

		LD		HL, REG_LCR
		LD		E, LCR_WL8
		CALL	WIFI.UART_WRITE
		RET

DUMP_REGS
		LD		HL, PORT_UART_A
	
DR_NEXT	
		LD		DE,MSG_DR_RN
		CALL	UTIL.HEXB
		INC		C	

		CALL    WIFI.UART_READ
		PUSH    BC
		LD		C,A
		LD		DE,MSG_DR_RV
		CALL	UTIL.HEXB
		PUSH 	HL	
		
		PRINTLN MSG_DR

		POP		HL,BC
		INC		HL
		DJNZ	DR_NEXT
		RET	
	ENDIF


; ------------------------------------------------------
; Store old video mode, set 80x32 and clear
; ------------------------------------------------------
INIT_VMODE
	PUSH	BC,DE,HL
	; Store previous vmode
	LD		C,DSS_GETVMOD
	RST		DSS
	LD		(SAVE_VMODE),A
	CP		DSS_VMOD_T80
	; Set vmode 80x32
	JR		Z, IVM_ALRDY_80
	LD		C,DSS_SETVMOD
	LD		A,DSS_VMOD_T80
	RST		DSS
IVM_ALRDY_80
	; Clear screen
	LD		A,' '
	LD		B,0x07
	LD		C,DSS_CLEAR
	LD		HL,0x2050
	LD		DE,0x0000
	RST		DSS

	POP		HL,DE,BC
	RET

; ------------------------------------------------------
; Restore saved video mode
; ------------------------------------------------------
REST_VMODE
	PUSH	BC
	LD		A,(SAVE_VMODE)
	CP		DSS_VMOD_T80
	JR		Z, RVM_SAME
	; Restore mode
	PRINTLN MSG_PRESS_AKEY

	LD		C, DSS_WAITKEY
	RST		DSS

	LD		C,DSS_SETVMOD
	RST		DSS
RVM_SAME	
	POP		BC
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
; Messages
; ------------------------------------------------------
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

MSG_PRESS_AKEY
	DB "Press any key to continue...",0

MSG_ESP_RESET
	DB "Reset ESP module.",0

MSG_UART_INIT
	DB "Reset UART.",0

LINE_END 
	DB "\r\n",0

SAVE_VMODE
	DB 0

; ------------------------------------------------------
; Debug messages
; ------------------------------------------------------
	IF TRACE

MSG_DR
	DB	"Reg[0x"
MSG_DR_RN	
	DB	"vv]=0x"
MSG_DR_RV	
	DB	"vv",0

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
CMD_QUIT 
    DB "QUIT\r",0

CMD_VERSION
	DB "AT+GMR\r\n",0	
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


	ENDMODULE