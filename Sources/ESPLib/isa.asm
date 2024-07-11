; ======================================================
; ISA Library for Sprinter computer
; By Roman Boykov. Copyright (c) 2024
; https://github.com/romychs
; License: BSD 3-Clause
; ======================================================

PORT_ISA		EQU 0x9FBD
PORT_SYSTEM		EQU 0x1FFD

ISA_BASE_A		EQU 0xC000								; Базовый адрес портов ISA в памяти

; --- PORT_ISA bits
ISA_A14  		EQU	0x01
ISA_A15  		EQU	0x02
ISA_A16  		EQU	0x04
ISA_A17  		EQU	0x08
ISA_A18  		EQU	0x10
ISA_A19  		EQU	0x20
ISA_AEN  		EQU	0x40
ISA_RST			EQU	0x80

	MODULE	ISA

; ------------------------------------------------------
; Reset ISA device
; ------------------------------------------------------
ISA_RESET
	LD		BC, PORT_ISA
	LD		A,ISA_RST | ISA_AEN							; RESET=1 AEN=1	
	OUT 	(C), A
	CALL 	UTIL.DELAY_1MS
	XOR 	A
	OUT 	(C), A										; RESET=0 AEN=0
	LD		HL,100
	CALL 	UTIL.DELAY
	RET

; ------------------------------------------------------
; Open access to ISA ports as memory
;   Inp: A = 0 - ISA slot 0, 1 - ISA SLOT 1
; ------------------------------------------------------
ISA_OPEN
	PUSH	AF,BC
	LD		BC, PAGE3
	IN 		A,(C)
	LD 		(SAVE_MMU3), A
	LD 		BC, PORT_SYSTEM
	LD 		A, 0x11
	OUT 	(C), A
ISA_SLOT+*	LD	A,0x01
	SLA		A
	OR 		A, 0xD4										; D4 - ISA1, D6 - ISA2
	LD		BC, PAGE3
	OUT 	(C), A
	LD 		BC, PORT_ISA
	XOR 	A
	OUT 	(C), A
	POP 	BC,AF
	RET


; ------------------------------------------------------
; Close access to ISA ports
; ------------------------------------------------------
ISA_CLOSE
	PUSH	AF,BC
	LD		A,0x01
	LD 		BC,PORT_SYSTEM
	OUT		(C),A
	LD		BC,PAGE3
	LD		A,(SAVE_MMU3)
	OUT		(C),A
	POP		BC,AF
	RET

; To save memory page 3
SAVE_MMU3		DB	0									

	ENDMODULE