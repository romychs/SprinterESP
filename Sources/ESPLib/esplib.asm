; ======================================================
; Library for Sprinter-WiFi ESP ISA Card
; By Roman Boykov. Copyright (c) 2024
; https://github.com/romychs
; License: BSD 3-Clause
; ======================================================

;ISA_BASE_A		EQU 0xC000        						; Базовый адрес портов ISA в памяти
PORT_UART		EQU 0x03E8        						; Базовый номер порта COM3
PORT_UART_A		EQU ISA_BASE_A + PORT_UART    			; Порты чипа UART в памяти 

; UART TC16C550 Registers in memory
REG_RBR 		EQU PORT_UART_A
REG_THR 		EQU PORT_UART_A
REG_IER 		EQU PORT_UART_A + 1
REG_IIR 		EQU PORT_UART_A + 2
REG_FCR			EQU PORT_UART_A + 2
REG_LCR			EQU PORT_UART_A + 3
REG_MCR 		EQU PORT_UART_A + 4
REG_LSR 		EQU PORT_UART_A + 5
REG_MSR 		EQU PORT_UART_A + 6
REG_SCR 		EQU PORT_UART_A + 7
REG_DLL 		EQU PORT_UART_A
REG_DLM 		EQU PORT_UART_A + 1
REG_AFR 		EQU PORT_UART_A + 2



; UART TC16C550 Register bits 
MCR_DTR         EQU	0x01
MCR_RTS         EQU	0x02
MCR_RST         EQU	0x04
MCR_PGM         EQU	0x08
MCR_LOOP        EQU	0x10
MCR_AFE         EQU	0x20
LCR_WL8         EQU	0x03								; 8 bits word len
LCR_SB2         EQU	0x04								; 1.5 or 2 stp bits
LCR_DLAB        EQU	0x80								; Enable Divisor latch
FCR_FIFO        EQU	0x01								; Enable FIFO for rx and tx
FCR_RESET_RX    EQU	0x02								; Reset Rx FIFO
FCR_RESET_TX    EQU	0x04								; Reset Tx FIFO
FCR_DMA         EQU	0x08								; Set -RXRDY, -TXRDY to "1"
FCR_TR1         EQU	0x00								; Trigger on 1 byte in fifo
FCR_TR4         EQU	0x40								; Trigger on 4 bytes in fifo
FCR_TR8         EQU	0x80								; Trigger on 8 bytes in fifo
FCR_TR14        EQU	0xC0								; Trigger on 14 bytes in fifo
LSR_DR          EQU	0x01								; Data Ready
LSR_OE          EQU	0x02								; Overrun Error
LSR_PE          EQU	0x04								; Parity Error
LSR_FE          EQU	0x08								; Framing Error
LSR_BI			EQU	0x10								; Break Interrupt
LSR_THRE        EQU	0x20								; Transmitter Holding Register Empty
LSR_TEMT        EQU	0x40								; Transmitter empty
LSR_RCVE        EQU	0x80								; Error in receiver FIFO

; Speed divider for UART 
BAUD_RATE 		EQU 115200                    			; Скорость соединения с ESP8266
XIN_FREQ 		EQU 14745600                  			; Частота генератора для TL16C550
DIVISOR 		EQU XIN_FREQ / (BAUD_RATE * 16)  		; Делитель частоты для передачи/приема данных

RS_BUFF_SIZE 	EQU	2048								; Receive buffer size
MAX_BUFF_SIZE 	EQU	16384

LSTR_SIZE 		EQU	20									; Size of buffer for last response line
LF 				EQU 0x0A
CR 				EQU	0x0D

; -- 
RES_OK			EQU 0
RES_ERROR		EQU 1
RES_FAIL		EQU 2
RES_TX_TIMEOUT 	EQU 3
RES_RS_TIMEOUT	EQU 4
RES_CONNECTED	EQU 5
RES_NOT_CONN	EQU 6
RES_ENABLED		EQU 7
RES_DISABLED 	EQU	8



	MODULE WIFI

; -- UART Registers offset

_RBR 			EQU	0
_THR 			EQU	0
_IER 			EQU	1
_IIR 			EQU	2
_FCR			EQU	2
_LCR			EQU	3
_MCR 			EQU	4
_LSR 			EQU	5
_MSR 			EQU	6
_SCR 			EQU	7
_DLL 			EQU	0
_DLM 			EQU	1
_AFR 			EQU	2


; ------------------------------------------------------
; Find TL550C in ISA slot
; Out: CF=1 - Not found, CF=0 - ISA.ISA_SLOT found in slot
; ------------------------------------------------------
UART_FIND
	PUSH	HL
	XOR 	A
	CALL	UT_T_SLOT
	JR		Z, UF_T_FND
	LD		A,1
	CALL	UT_T_SLOT
	JR		Z, UF_T_FND
	SCF
UF_T_FND
	POP		HL
	RET

; Test slot, A - ISA Slot no. 0 or 1
UT_T_SLOT
	; check IER hi bits, will be 0
	LD		(ISA.ISA_SLOT), A
	LD		HL, REG_IER
	CALL	UART_READ
	AND		0xF0
	RET		NZ

	; check SCR register
	LD		DE,0x5555
	CALL	CHK_SCR
	RET		NZ
	LD		DE,0xAAAA
	CALL	CHK_SCR
	RET

CHK_SCR	
	LD		HL, REG_SCR
	CALL	UART_WRITE
	CALL	UART_READ
	CP		D
	RET



; ------------------------------------------------------
; Init UART device TL16C550
; ------------------------------------------------------
UART_INIT
	PUSH	AF, IX

	CALL 	ISA.ISA_OPEN
	LD		IX, PORT_UART_A
	LD		A, FCR_TR8 | FCR_FIFO						; Enable FIFO buffer, trigger to 14 byte
	LD		(IX+_FCR),A									
	XOR 	A
	LD 		(IX+_IER), A								; Disable interrupts

	; Set 8bit word and Divisor for speed
	LD 		A, LCR_DLAB | LCR_WL8
	LD 		(IX+_LCR), A								; Enable Baud rate latch
	LD 		A, DIVISOR
	LD 		(IX+_DLL), A								; 8 - 115200
	XOR 	A
	LD		(IX+_DLM), A
	LD 		A, LCR_WL8									; 8bit word, disable latch
	LD 		(IX+_LCR), A
	CALL 	ISA.ISA_CLOSE

	POP 	IX,AF
	RET

; ------------------------------------------------------
; Read TL16C550 register
;   Inp: HL - register
;   Out: A - value from register
; ------------------------------------------------------
UART_READ
	CALL 	ISA.ISA_OPEN
	LD 		A, (HL)
	CALL 	ISA.ISA_CLOSE
	RET

; ------------------------------------------------------
; Write TL16C550 register
;   Inp: HL - register, E - value
; ------------------------------------------------------
UART_WRITE            
	CALL	ISA.ISA_OPEN
	LD 		(HL), E
	CALL 	ISA.ISA_CLOSE
	RET

; ------------------------------------------------------
; Wait for transmitter ready
;   Out: CF=1 - tr not ready,  CF=0 ready
; ------------------------------------------------------
UART_WAIT_TR
	CALL	ISA.ISA_OPEN
	CALL	UART_WAIT_TR_INT
	CALL	ISA.ISA_CLOSE
	RET

;
; Wait, without open/close ISA
;
UART_WAIT_TR_INT
	PUSH	AF, BC, HL
	LD BC,	500
	LD HL, 	REG_LSR
WAIT_TR_BZY           
	LD 		A,(HL)
	AND 	A, LSR_THRE
	JR 		NZ,WAIT_TR_RDY
	CALL	UTIL.DELAY_100uS							; ~11 bit tx delay
	DEC 	BC
	LD 		A, C
	OR		B	
	JR 		NZ,WAIT_TR_BZY
	SCF
WAIT_TR_RDY
	POP 	HL, BC, AF
	RET

; ------------------------------------------------------
; Transmit byte 
; Inp: E - byte
; Out: CF=1 - Not ready
; ------------------------------------------------------
UART_TX_BYTE
	CALL 	UART_WAIT_TR
	JP		C, UTB_NOT_R
	LD		HL, REG_THR
	CALL 	UART_WRITE
	XOR		A
UTB_NOT_R
	RET

; ------------------------------------------------------
;  Transmit buffer 
;	Inp: HL -> buffer, BC - size
;   Out: CF=0 - Ok, CF=1 - Timeout
; ------------------------------------------------------
UART_TX_BUFFER
	PUSH	BC,DE,HL
	LD		DE, REG_THR
	CALL	ISA.ISA_OPEN
UTX_NEXT	
	; buff not empty?
	LD		A, B
	OR		C
	JR		Z,UTX_EMP
	; check transmitter ready
	CALL	UART_WAIT_TR_INT
	JR		C, UTX_TXNR
	; transmitt byte
	LD		A,(HL)
	INC		HL
	LD		(DE),A
	DEC		BC
	JR		UTX_NEXT
	; CF=0
UTX_EMP	
	AND		A
UTX_TXNR
	CALL	ISA.ISA_CLOSE
	POP		HL,DE,BC
	RET

; ------------------------------------------------------
;  Transmit zero ended string
;	Inp: HL -> buffer
;   Out: CF=0 - Ok, CF=1 - Timeout
; ------------------------------------------------------
UART_TX_STRING
	PUSH	DE,HL
	LD		DE, REG_THR
	CALL	ISA.ISA_OPEN
UTXS_NEXT
	LD 		A,(HL)
	AND		A
	JR		Z,UTXS_END
	; check transmitter ready
	CALL	UART_WAIT_TR_INT
	JR		C, UTXS_TXNR
	; transmitt byte
	LD		A,(HL)
	INC		HL
	LD		(DE),A
	JR		UTXS_NEXT
	; CF=0
UTXS_END
	AND		A
UTXS_TXNR
	CALL	ISA.ISA_CLOSE
	POP		HL,DE
	RET




; ------------------------------------------------------
; Empty receiver FIFO buffer
; ------------------------------------------------------
UART_EMPTY_RS
	PUSH 	DE, HL
	LD 		E, FCR_TR8 | FCR_RESET_RX | FCR_FIFO
	LD		HL, REG_FCR
	CALL	UART_WRITE
	POP 	HL, DE
	RET

; ------------------------------------------------------
; Wait byte in receiver fifo
; Inp: BC - Wait ms
; Out: CF=1 - Timeout, FIFO is EMPTY
; ------------------------------------------------------
UART_WAIT_RS1
	PUSH	BC,HL
WAIT_MS+*	LD	BC,0x2000
	JR		UVR_NEXT
UART_WAIT_RS
	PUSH	BC,HL
UVR_NEXT
	LD		HL, REG_LSR
	CALL	UART_READ
	AND		LSR_DR
	JR		NZ,UVR_OK
	CALL	UTIL.DELAY_1MS
	DEC		BC
	LD		A,B
	OR		C
	JR		NZ,UVR_NEXT
UVR_TO
    IF TRACE
	PUSH	AF,BC,DE,HL
	PRINTLN MSG_RCV_EMPTY
	POP		HL,DE,BC,AF
	ENDIF
	SCF
UVR_OK
	POP		HL,BC
	RET
	
; ------------------------------------------------------
; Reset ESP module
; ------------------------------------------------------
ESP_RESET
	PUSH	AF,HL

	CALL	ISA.ISA_OPEN

	LD		HL, REG_MCR
	LD		A, MCR_RST ;| MCR_RTS						; -OUT1=0 -> RESET ESP
	LD		(REG_MCR), A
	CALL	UTIL.DELAY_1MS
	LD		A, MCR_AFE | MCR_RTS						; 0x22 -OUT1=1 RTS=1 AutoFlow enabled
	LD		(HL), A
	CALL	ISA.ISA_CLOSE
	
	; wait 2s for ESP firmware boot
	LD		HL,2000
	CALL	UTIL.DELAY

	POP		HL,AF
	RET


; Receive block size
BSIZE		DW 0

; Received message for OK result
MSG_OK		DB "OK", 0
; Received message for Error
MSG_ERROR	DB "ERROR", 0
; Received message for Failure
MSG_FAIL	DB "FAIL", 0

; ------------------------------------------------------
; UART TX Command
;	Inp: HL - ptr to command, 
;		 DE - ptr to receive buffer, 
;		 BC - wait ms
;	Out: CF=1 if Error
; ------------------------------------------------------
UART_TX_CMD
		PUSH	BC, DE, HL		

		LD		A, low RS_BUFF_SIZE
		LD		(BSIZE), A
		LD		A, high RS_BUFF_SIZE
		LD		(BSIZE+1), A

		;LD		(RESBUF),DE
		XOR		A
		LD		(DE), A

		LD		(WAIT_MS), BC
		CALL	UART_EMPTY_RS

		; HL - Buffer, BC - Size
		;CALL	UTIL.STRLEN
		CALL	UART_TX_STRING
		JR		NC, UTC_STRT_RX
		; error, transmit timeout
		LD		A, RES_TX_TIMEOUT
		JR		UTC_RET
UTC_STRT_RX		
		; no transmit timeout, receive response
		; IX - pointer to begin of current line
		LD		IXH, D
		LD		IXL, E
		LD		BC,(BSIZE)
UTC_RCV_NXT
		; wait receiver ready
		;LD		BC,(WAIT_MS)
		CALL	UART_WAIT_RS1
		JR		NC, UTC_NO_RT
		; error, read timeout
		LD		A, RES_RS_TIMEOUT
		JR		UTC_RET
		; no receive timeout
UTC_NO_RT

		; read symbol from tty
		LD		HL, REG_RBR
		CALL	UART_READ
		CP		CR
		JP		Z, UTC_RCV_NXT							; Skip CR 
		CP		LF
		JR		Z, UTC_END								; LF - last symbol in responce
		LD		(DE),A
		INC		DE
		DEC		BC
		LD		A, B
		OR		C
		JR		NZ, UTC_RCV_NXT

UTC_END
		XOR		A
		LD		(DE),A									; temporary mark end of string
		PUSH 	DE										; store DE
		POP		IY
		PUSH	IX
		POP		DE										; DE - ptr to begin pf current line

		; It is 'OK<LF>'?
		LD		HL, MSG_OK
		CALL	UTIL.STRCMP
		JR		NC, UTC_RET
		; It is 'ERROR<LF>'?
		LD		HL,MSG_ERROR
		CALL	UTIL.STRCMP
		JR		C, UTC_CP_FAIL
		LD		A, RES_ERROR
		; It is 'FAIL<LF>'?
		JR		UTC_RET
UTC_CP_FAIL		
		LD		HL,MSG_FAIL
		CALL	UTIL.STRCMP
		JR		C, UTC_NOMSG
		LD		A, RES_FAIL
		JR		UTC_RET
UTC_NOMSG
		; no resp message, continue receive
		PUSH	IY
		POP		DE
		LD		A, LF
		LD		(DE),A									; change 0 - EOL to LF
		INC		DE
		LD		IXH,D									; store new start line ptr
		LD		IXL,E
		JR		UTC_RCV_NXT
UTC_RET
		POP		HL, DE, BC
		RET

	IF TRACE
MSG_RCV_EMPTY
	DB "Receiver is empty!",0	
	ENDIF

; Buffer to receive response from ESP
RS_BUFF	DS RS_BUFF_SIZE, 0

	ENDMODULE