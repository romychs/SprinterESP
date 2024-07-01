

	MODULE UTIL
	
; ------------------------------------------------------
; Small delay
; Inp:	HL - number of cycles, if HL=0, then 2000
; ------------------------------------------------------
DELAY
	PUSH	AF
	PUSH	HL
    LD		A,H
    OR		L
    JP		NZ,DELAY_L1
    LD		HL,2000
DELAY_L1:
   	DEC		HL
    LD		A,H
    OR		L
    JP		NZ,DELAY_L1
	POP		HL
    POP		AF
	RET

; TODO: Do it with timer
DELAY_1MS
	PUSH	HL
	LD 		HL,100
	CALL	DELAY
	POP		HL
	RET

; ------------------------------------------------------
; Calc length of zero ended string
;	Inp: HL - pointer to string
;	Out: BC - length of string
; ------------------------------------------------------
STRLEN
	PUSH	DE,HL
	LD		BC,MAX_BUFF_SIZE
	XOR		A
	CPIR
	POP		DE
	SUB		HL,DE										; llength of zero ended string
	LD		BC,HL
	POP		HL,DE
	RET

; ------------------------------------------------------
; Compare zero-ended strings
; Inp: HL, DE - pointers to strinngs to compare
; Out: CF=0 - equal, CF=1 - not equal
; ------------------------------------------------------
STRCMP	INCLUDE "util.asm"
	INCLUDE "isa.asm"
	INCLUDE "esplib.asm"

	LD		A, (DE)
	CP		(HL)
	JR		NZ, STC_NE
	AND		A
	JR		Z,	STC_EQ	
	INC		DE
	INC		HL
	JR		STC_NEXT
STC_NE
	SCF
STC_EQ
	POP		BC,HL,DE
	RET





	POP 	BC,HL,DE
	RET

	ENDMODULE