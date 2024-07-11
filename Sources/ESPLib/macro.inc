; ======================================================
; Macros for Sprinter-WiFi utilities
; By Roman Boykov. Copyright (c) 2024
; https://github.com/romychs
; License: BSD 3-Clause
; ======================================================

	; Transmit data|command via UART and check response
	MACRO	SEND_CMD	data
	LD		HL, data
	CALL	WIFI.UART_TX_CMD
	CALL	CHECK_ERROR
	ENDM	

	; Print data ASCIIZ string to screen
	MACRO 	PRINT	data
	LD		HL,data
    LD      C,DSS_PCHARS
    RST     DSS
	ENDM

	; Print data ASCIIZ string to screen and CR+LF
	MACRO 	PRINTLN	data
	LD		HL,data
    LD      C,DSS_PCHARS
    RST     DSS
    LD      C,DSS_PCHARS
	LD		HL, WCOMMON.LINE_END
	RST     DSS
	ENDM

	; Print data ASCIIZ string to screen if TRACE enabled
	MACRO 	TRACELN	data
		IF  TRACE == 1
			PUSH BC,DE
			PRINTLN data
			POP DE,BC
		ENDIF
	ENDM
