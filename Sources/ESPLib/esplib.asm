; ===========================================
; SOLID C  Lbrary to work with Sprinter WiFi 
; ESP ISA Card
; ===========================================

               DEVICE NOSLOT64K
               ;INCLUDE "ports.inc"

PORT_ISA		   EQU 0x9FBD
PORT_SYSTEM		EQU 0x1FFD
PORT_MEM_W3    EQU 0xE2

ISA_BASE_A		EQU 0xC000        ; Базовый адрес портов ISA в памяти
PORT_UART		EQU 0x03E8        ; Базовый номер порта COM3
PORT_UART_A		EQU ISA_BASE_A + PORT_UART    ; Порты чипа UART в памяти 

			      ; Регистры UART TC16C550 в памяти 
REG_RBR 			EQU PORT_UART_A + 0
REG_THR 			EQU PORT_UART_A + 0
REG_IER 			EQU PORT_UART_A + 1
REG_IIR 			EQU PORT_UART_A + 2
REG_FCR		   EQU PORT_UART_A + 2
REG_LCR 			EQU PORT_UART_A + 3
REG_MCR 			EQU PORT_UART_A + 4
REG_LSR 			EQU PORT_UART_A + 5
REG_MSR 			EQU PORT_UART_A + 6
REG_SCR 			EQU PORT_UART_A + 7
REG_DLL 			EQU PORT_UART_A + 0
REG_DLM 			EQU PORT_UART_A + 1
REG_AFR 			EQU PORT_UART_A + 2

BAUD_RATE 	EQU 115200                    ; Скорость соединения с ESP8266
XIN_FREQ 	EQU 14745600                  ; Частота генератора для TL16C550
DIVISOR 		EQU XIN_FREQ / (BAUD_RATE * 16)  ; Делитель частоты для передачи/приема данных

            ORG 0x0000
            jp main

save_mmu3	DB 0		; Variable to save memory page

				; ===============================================
				; Small delay
				; void delay(hl)
				; in hl - number of cycles, if hl=0, then 2000
				; ===============================================
            MODULE delay
delay_:
				push af
				ld a,h
				or l
				jp nz,delay_l1
				ld hl,2000
delay_l1:	dec hl
				ld a,h
				or l
				jp nz,delay_l1
				pop af
				ret
				ENDMODULE

				; ===============================================
				; Reset ISA device
				; ===============================================
            MODULE reset_isa
reset_isa_:
				push af
				push bc
            push hl
				ld bc, PORT_ISA
            ld a, 0xC0		   ; RESET=1 AEN=1
				out (c), a
				ld hl,2000
				call delay.delay_
            xor a
            out (c), a        ; RESET=0 AEN=0
            add hl,hl
            call delay.delay_
            pop hl
            pop bc
            pop af
            ret
            ENDMODULE 

				; ===============================================
            ; Open access to ISA ports as memory
            ;   input a = 0 - ISA slot 0, 1 - ISA SLOT 1
				; ===============================================
            MODULE open_isa
open_isa_:
            push af
            push bc
            PORT_EMM_WIN_P3in_p3
            in a,(c)
            ld (save_mmu3), a
            push bc
            ld bc, PORT_SYSTEM
            ld a, 0x11
            out (c), a
            PORT_MEM_W3      ; em   m_win_p3
            pop af
            and a, 0x01
            rlca
            rlca
            or a, 0xd0        ; 1101 - Magic number, 0100 - 0,ISA PORT, ISA SLOT, 0
            out (c), a
            ld bc, PORT_SYSTEM
            xor a
            out (c), a
            pop bc
            
            ret
            ENDMODULE

				; ===============================================
            ; Close access to ISA ports
				; ===============================================
            MODULE close_isa
close_isa_:
            push af
            push bc
            ld bc, PORT_SYSTEM
            ld a, 0x01
            out (c), a
            ld a, save_mmu3
            PORT_EMM_WIN_P3in_p3
            out (c), a
            pop bc
            pop af
            ret
            ENDMODULE

				; ===============================================
            ;  Init ISA device
				; ===============================================
            MODULE init_isa
init_isa_:
            call reset_isa.reset_isa_      ; just only reset
            ret            
            ENDMODULE

				; ===============================================
            ; Init UART device TL16C550
				; ===============================================
            MODULE init_serial
init_serial_:
            push af
            push hl
            call open_isa.open_isa_
            ld a, 1
            ld (REG_FCR
          a            ; 8 byte FIFO buffer
            ld a, 0x81   
            ld (REG_FCR
          a
            xor a
            ld (REG_IER
         ), a            ; Disable interrupts
            
            ; Set baud rate
            ld a, 0x83
              ld (REG_LCR), a            ; enable Baud rate latch
            ld a, DIVISOR
            ld (REG_DLL), a            ; 8 - 115200
            xor a
            ld (REG_DLM), a            
            ld a, 0x03             ; disable Baud rate latch & 8N1
            ld (REG_LCR), a
            
            ; reset ESP
            ld a,0x06            ; ESP -PGM=1, -RTS=0
            ld (REG_MCR), a
            ld hl,2000
            call delay.delay_
            ld a,0x02            ; ESP -RST=1, -RTS=0
            call delay.delay_
            call close_isa.close_isa_
            pop hl
            pop af
            ret
            ENDMODULE

				; ===============================================
            ; Read TL16C550 register
            ;   char read_reg(reg)
            ;   input hl - register no
            ;   output a - value from register
				; ===============================================
            MODULE read_reg
read_reg_:  
            call open_isa.open_isa_
            ld a, (hl)
            call close_isa.close_isa_
            ret
            ENDMODULE

				; ===============================================
            ; Write TL16C550 register
            ;   void write_reg(reg, b)
            ;   input hl - reg no, e - value            
				; ===============================================
            MODULE write_reg
write_reg_:            
            call open_isa.open_isa_
            ld (hl), e
            call close_isa.close_isa_
            ret
            ENDMODULE

				; ===============================================
            ; Wait for transmitter ready
            ;   char wait_tr()
            ;   output a = 0 - tr not ready, !=0 - tr ready
				; ===============================================
            MODULE wait_tr
wait_tr_: 
            push bc
            push hl
            ld bc, 100
            ld hl, REG_LSR
wait_tr_r:            
            call read_reg.read_reg_
            and a, 0x20
            jp nz,wait_tr_e
            dec bc
            ld a, c
            or b
            jp nz,wait_tr_r
            xor a
wait_tr_e:
            pop hl
            pop bc
            ret
            ENDMODULE

				; ===============================================
            ; Empty receiver FIFO buffer
            ;   void empty_rs()
				; ===============================================
            MODULE empty_rs
empty_rs_: 
            push af
            call open_isa.open_isa_
            ld a, 0x83
            ld (REG_FCR
          a
            call close_isa.close_isa_
            pop af
            ret
            ENDMODULE

				; ===============================================
            ; Wait byte in receiver fifo
            ; char wait_rs()
            ; output a=0 - fifo still empty, a!=0 - receiver fifo is not empty
				; ===============================================
            MODULE wait_rs
wait_rs_:    
            push bc
            push hl
            ld bc, 1000
            ld hl, REG_LSR
wait_rs_r:            
            call read_reg.read_reg_
            and a, 0x01
            jp nz,wait_rs_e
            dec bc
            ld a, c
            or b
            jp nz,wait_rs_r
            xor a
wait_rs_e:
            pop hl
            pop bc
            ret
            ENDMODULE

				; ===============================================
            ;  STUB
				; ===============================================

main:
            call init_isa.init_isa_
            ret