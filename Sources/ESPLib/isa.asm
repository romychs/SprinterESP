; ======================================================
; ISA Library for Sprinter
; By Romych's, 2024 (c)
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
	PUSH	AF
	PUSH	BC
	PUSH	HL
	LD		BC, PORT_ISA
	LD		A,ISA_RST | ISA_AEN							; RESET=1 AEN=1	
	OUT 	(C), A
	LD		HL,2000
	CALL 	UTIL.DELAY
	XOR 	A
	OUT 	(C), A										; RESET=0 AEN=0
	ADD 	HL,HL
	CALL 	UTIL.DELAY
	POP		HL
	POP		BC
	POP		AF
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


; DELAY_20
; 	;IN		A,(PAGE1)
; 	LD		A, CTC_CR_VEC | CTC_CR_SWR					; stop timer
; 	OUT		(CTC_CH1), A
; 	; Init Ch2 CTC - clk source for Ch3
; 	LD		A,CTC_CT_PRE | CTC_CR_TCF | CTC_CR_SWR | CTC_CR_VEC
; 	OUT		(CTC_CH2), A
; 	LD		A, 4
; 	; TO2->TRG3 = 875kHz / 256 / 4 = 854,5 Hz
; 	OUT		(CTC_CH2), A
	
; 	LD		A, CTC_CT_EI | CTC_CT_CTR | CTC_CR_TCF | CTC_CR_SWR | CTC_CR_VEC
; 	OUT		(CTC_CH3), A
; 	LD		A, 17
; 	OUT		(CTC_CH3), A


; it vector defined in bit 7­3,bit 2­1 don't care, bit 0 = 0
; and loaded into channel 0	

; To save memory page 0
SAVE_MMU0		DB	0
; To save memory page 3
SAVE_MMU3		DB	0									

;	ALIGN 256,0


	ENDMODULE