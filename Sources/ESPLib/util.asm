; ======================================================
; Utility code for Sprinter-WiFi utilities
; By Roman Boykov. Copyright (c) 2024
; https://github.com/romychs
; License: BSD 3-Clause
; ======================================================

	MODULE UTIL
	
; ------------------------------------------------------
; Small delay
; Inp:	HL - number of cycles, if HL=0, then 2000
; ------------------------------------------------------
DELAY
	PUSH	AF,BC,HL

    LD		A,H
    OR		L
    JR		NZ,DELAY_NXT
    LD		HL,20

DELAY_NXT
	CALL	DELAY_1MS_INT
   	DEC		HL
    LD		A,H
    OR		L
    JP		NZ,DELAY_NXT

	POP		HL,BC,AF
	RET



DELAY_1MS_INT
	LD		BC,400
SBD_NXT
	DEC		BC
	LD		A, B
	OR		C
	JR		NZ, SBD_NXT
	RET




DELAY_1MS
	PUSH	BC
	CALL	DELAY_1MS_INT
	POP		BC
	RET

DELAY_100uS
	PUSH	BC
	LD		BC,40
	CALL	SBD_NXT
	POP		BC
	RET


; ------------------------------------------------------
; Calc length of zero ended string
;	Inp: HL - pointer to string
;	Out: BC - length of string
; ------------------------------------------------------
STRLEN
	PUSH	DE,HL,HL
	LD		BC,MAX_BUFF_SIZE
	XOR		A
	CPIR
	POP		DE
	SUB		HL,DE										; llength of zero ended string
	LD		BC,HL
	LD		A, B
	OR		C
	JR		Z, STRL_NCOR
	DEC		BC
STRL_NCOR	
	POP		HL,DE
	RET

; ------------------------------------------------------
; Compare zero-ended strings
; Inp: HL, DE - pointers to strinngs to compare
; Out: CF=0 - equal, CF=1 - not equal
; ------------------------------------------------------
STRCMP
	PUSH	DE,HL
STC_NEXT
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
	POP		HL,DE
	RET

; ------------------------------------------------------
; Convert string to number
; Inp: DE - ptr to zero ended string
; Out: HL - Result
; ------------------------------------------------------
ATOU
	PUSH	BC
  	LD		HL,0x0000
ATOU_L1
  	LD		A,(DE)
  	AND		A
  	JR		Z, ATOU_LE
  	SUB		0x30
  	CP		10
  	JR		NC, ATOU_LE
  	INC 	DE
  	LD 		B,H
  	LD 		C,L
  	ADD 	HL,HL
  	ADD 	HL,HL
  	ADD 	HL,BC
  	ADD 	HL,HL
  	ADD 	A,L
  	LD 		L,A
  	JR 		NC,ATOU_L1
  	INC 	H
  	JP 		ATOU_L1
ATOU_LE
	POP		BC
	RET


; ------------------------------------------------------
; Find char in string
;	Inp: HL - ptr to zero endeds string
;		 A  - char to find
;	Outp: CF=0, HL points to char if found
;		  CF=1 - Not found
; ------------------------------------------------------
STRCHR
	PUSH	BC
STCH_NEXT	
	LD		C,A
	LD		A,(HL)
	AND		A
	JR		Z, STCH_N_FOUND
	CP		C
	JR		Z, STCH_FOUND
	INC		HL
	JR		STCH_NEXT
STCH_N_FOUND
	SCF
STCH_FOUND
	POP		BC
	RET

; ------------------------------------------------------
; Convert Byte to hex
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



	ENDMODULE