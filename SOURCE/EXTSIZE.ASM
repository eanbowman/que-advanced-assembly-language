Page 60,132

Comment |
******************************************************************

File:       EXTSIZE.ASM
Author:     Allen L. Wyatt
Date:       7/30/92
Assembler:  MASM 6.0

Purpose:    Display size of extended memory installed

Format:     EXTSIZE

******************************************************************|

            .MODEL  small
            .STACK                      ;Default 1Kb stack is OK
            .DATA

EMsg1       DB      'BIOS function not available'
CRLF        DB      13,10,0
TotalMsg    DB      'Total extended memory:  ',0

            .CODE
            .STARTUP
ExtSize     PROC

            MOV     AH,88h              ;Get extended memory size
            INT     15h
            JC      Error               ;Function not available

            MOV     SI,OFFSET TotalMsg  ;Total memory message
            CALL    PrtString
            MOV     DX,0
            MOV     CX,400h
            MUL     CX
            CALL    PrtDec
            MOV     SI,OFFSET CRLF
            CALL    PrtString
            JMP     AllDone

Error:      MOV     SI,OFFSET EMsg1
            CALL    PrtString

AllDone:
            .EXIT
ExtSize     ENDP


; The following routine prints the ASCIIZ string pointed to by DS:SI

PrtString   PROC    USES AX DX SI
PS1:        MOV     DL,[SI]             ;Get character
            INC     SI                  ;Point to next one
            CMP     DL,0                ;End of string?
            JE      PS2                 ;Yes, so exit
            MOV     AH,02h              ;Output a character
            INT     21h
            JMP     PS1                 ;Keep doing it
PS2:        RET
PrtString   ENDP


; The following routine prints the value in DX:AX as a decimal number
; Will accept numbers up to 655,359,999.  Anything larger will not print.

            .DATA
Temp        DW      0000

            .CODE
PrtDec      PROC    USES AX BX CX DX

            MOV     CX,0FFFFh           ;Ending flag
            PUSH    CX

PD0:        MOV     CX,10000            ;Divide by 10,000
            DIV     CX
            MOV     Temp,AX             ;Store whole portion
            MOV     BX,0                ;Count for this iteration

            MOV     AX,DX
            MOV     CX,10
PD1:        MOV     DX,0
            DIV     CX                  ;Divide by 10
            ADD     DL,30h              ;Convert to ASCII
            PUSH    DX                  ;Store remainder
            INC     BX                  ;Cycle count
            CMP     AX,0                ;Are we done?
            JNE     PD1                 ;No, so continue
            MOV     DX,0
            MOV     AX,Temp             ;Get back part above 10,000
            CMP     AX,0
            JE      PD3
            MOV     CX,'0'
PD2:        CMP     BX,4                ;Did we push 4 numbers?
            JE      PD0                 ;Yes, continue
            PUSH    CX                  ;No, so push it
            INC     BX                  ;Push counter
            JMP     PD2

PD3:        POP     DX                  ;Character is now in DL
            CMP     DX,0FFFFh           ;Is it the ending flag?
            JE      PD4                 ;Yes, so continue
            MOV     AH,02h              ;Output a character
            INT     21h
            JMP     PD3                 ;Keep doing it

PD4:        RET
PrtDec      ENDP

            END
