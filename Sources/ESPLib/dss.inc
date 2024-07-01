; ======================================================
; Defines for DSS Estex for Sprinter computer
; By Romych, 2024
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
DSS_EXIT            EQU 0x41
DSS_PCHARS          EQU 0x5C

; DSS Error codes
E_FILE_EXISTS       EQU 7
E_FILE_NOT_FOUND    EQU 3
