Page 60,132

Comment |
******************************************************************

File:       XMSINFO.ASM
Author:     Allen L. Wyatt
Date:       7/30/92
Assembler:  MASM 6.0

Purpose:    Display information about extended memory using XMS functions

Format:     XMSINFO

******************************************************************|

            .MODEL  small
            .STACK                      ;Default 1Kb stack is OK
            .DATA

XMSentry    DD      00000000
InMsg       DB      'An XMS-compilant extended memory manager is installed',13,10,0
Version     DB      'Supports XMS version '
Major       DB      00,'.'
Minor       DB      00,'.'
CRLF        DB      13,10,0
EnabMsg     DB      'The A20 line is enabled',13,10,0
DisMsg      DB      'The A20 line is disabled',13,10,0

TotalMsg    DB      'Total extended memory:      ',0
FreeMsg     DB      'Extended memory available:  ',0

EMsg1       DB      'No XMS-complaint expanded memory manager detected',13,10,0
EMsg2       DB      'Error checking on A20 line',13,10,0


            .CODE
            .STARTUP
XMSinfo     PROC

            CALL    ChkXMS              ;See if EMM present
            JC      Error1              ;Not there
            MOV     SI,OFFSET InMsg
            CALL    PrtString

            MOV     AH,0                ;Get XMS version
            CALL    XMSentry
            OR      AX,3030h            ;Turn to ASCII
            MOV     Major,AH
            MOV     Minor,AL
            MOV     SI,OFFSET Version
            CALL    PrtString

            MOV     AH,07h              ;Get status of A20 line
            CALL    XMSentry
            MOV     SI,OFFSET EnabMsg   ;Assume enabled
            CMP     AX,1                ;Was it enabled?
            JE      Enabled             ;Yes, continue
            CMP     BL,0                ;Was there really an error?
            JNE     Error2              ;Yes, so handle
            MOV     SI,OFFSET DisMsg    ;No, so it is disabled
Enabled:    CALL    PrtString

            MOV     SI,OFFSET TotalMsg  ;Total extended memory message
            CALL    PrtString
            MOV     AH,08h              ;Query free extended memory
            CALL    XMSentry

            PUSH    AX                  ;Save available
            MOV     AX,DX               ;Move total amount
            MOV     DX,0
            MOV     CX,400h
            MUL     CX
            CALL    PrtDec
            MOV     SI,OFFSET CRLF
            CALL    PrtString

            MOV     SI,OFFSET FreeMsg   ;Available memory message
            CALL    PrtString
            POP     AX                  ;Get back amount
            MOV     DX,0
            MOV     BX,400h
            MUL     BX
            CALL    PrtDec
            MOV     SI,OFFSET CRLF
            CALL    PrtString
            JMP     AllDone

Error1:     MOV     SI,OFFSET EMsg1
            JMP     ErrCommon
Error2:     MOV     SI,OFFSET EMsg2
ErrCommon:  CALL    PrtString

AllDone:
            .EXIT
XMSinfo     ENDP


; The following routine checks to see if an XMM is installed.
; If one is not, the carry flag is set on return
; If one is, the address is stored and the carry flag is cleared on return

ChkXMS      PROC    USES AX BX ES
            MOV     AX,4300h            ;Get XMS installed state
            INT     2Fh
            CMP     AL,0
            JE      NotThere
            MOV     AX,4310h            ;Get entry point
            INT     2Fh
            MOV     WORD PTR XMSentry[0],BX
            MOV     WORD PTR XMSentry[2],ES
            CLC                         ;Set for no error
            JNC     Done
NotThere:   STC
Done:       RET
ChkXMS      ENDP


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