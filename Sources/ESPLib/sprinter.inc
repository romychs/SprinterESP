; ======================================================
; Defines for Sprinter computer hardware
; By Roman Boykov. Copyright (c) 2024
; https://github.com/romychs
; ======================================================

; Memory pages
PAGE0_ADDR          EQU 0x0000
PAGE1_ADDR          EQU 0x4000
PAGE2_ADDR          EQU 0x8000
PAGE3_ADDR          EQU 0xC000

; Sprinter ports to switch mem pages
PAGE0               EQU 0x82
PAGE1               EQU 0xA2
PAGE2               EQU 0xC2
PAGE3               EQU 0xE2

; CTC Control register ports
CTC_CH0				EQU 0x10
CTC_CH1				EQU 0x11
CTC_CH2				EQU 0x12
CTC_CH3				EQU 0x13

CTC_CR_VEC			EQU 0x01							; 1 - Vector, 0 - Control
CTC_CR_SWR			EQU 0x02							; 1 - Software Reset, 0 - Continued operation
CTC_CR_TCF			EQU 0x04							; 1 - TYime const follows
CTC_CR_TTR			EQU 0x08							; 1 - Time trigger
CTC_CT_TRE			EQU 0x10							; 1 - Trigger Edge
CTC_CT_PRE			EQU 0x20							; 1 - 256 Prescaler, 0 - 16
CTC_CT_CTR			EQU 0x40							; 0 - Timer, 1 - Counter
CTC_CT_EI			EQU 0x80							; Interrupt 1 - enable, 0 - disable
