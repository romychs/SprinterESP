; ======================================================
; Defines for DSS Estex for Sprinter computer
; By Roman Boykov. Copyright (c) 2024
; https://github.com/romychs
; ======================================================

; DSS RST Entry
DSS                 EQU 0x10

; DSS Functions
DSS_CURDISK         EQU 0x02
DSS_CREATE_FILE     EQU 0x0B
DSS_OPEN_FILE       EQU 0x11
DSS_CLOSE_FILE      EQU 0x12
DSS_READ_FILE       EQU 0x13
DSS_WRITE           EQU 0x14
DSS_MOVE_FP_CP      EQU 0x0115
DSS_FIND_FIRST      EQU 0x0119
DSS_FIND_NEXT       EQU 0x011A
DSS_MKDIR           EQU 0x1B
DSS_CHDIR           EQU 0x1D
DSS_CURDIR          EQU 0x1E
DSS_ECHOKEY			EQU	0x32 
DSS_EXIT            EQU 0x41
DSS_WAITKEY			EQU 0x48
DSS_SETVMOD			EQU 0x50
DSS_GETVMOD			EQU 0x51
DSS_CLEAR			EQU 0x56
DSS_PCHARS          EQU 0x5C


DSS_VMOD_T40		EQU 0x02							; text 40x32, 16 colors
DSS_VMOD_T80		EQU 0x03							; text 80x32, 16 colors
DSS_VMOD_G320		EQU 0x81							; graphics 320x256, 256 colors
DSS_VMOD_G640		EQU 0x82							; graphics 640x256, 16 colors


; DSS Error codes
E_FILE_EXISTS       EQU 7
E_FILE_NOT_FOUND    EQU 3

