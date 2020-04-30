Page 60,132

Comment |
******************************************************************

File:       EMSINFO.ASM
Author:     Allen L. Wyatt
Date:       7/29/92
Assembler:  MASM 6.0

Purpose:    Display information about expanded memory

Format:     EMSINFO

******************************************************************|

            .MODEL  small
            .STACK                      ;Default 1Kb stack is OK
            .DATA

EMSName     DB      'EMMXXXX0',0
InMsg       DB      'An expanded memory manager is installed',13,10,0
NoneMsg     DB      'No expanded memory manager detected',13,10,0
Version     DB      'Supports EMS version '
Major       DB      00,'.'
Minor       DB      00,'.'
CRLF        DB      13,10,0
PageMsg     DB      'Using page frame address:  ',0
TotalMsg    DB      'Total expanded memory:      ',0
FreeMsg     DB      'Expanded memory available:  ',0

            .CODE
            .STARTUP
EMSinfo     PROC

            CALL    ChkEMS              ;See if EMM present
            JNC     ItsThere
            MOV     SI,OFFSET NoneMsg
            CALL    PrtString
            JMP     AllDone

ItsThere:   MOV     SI,OFFSET InMsg
            CALL    PrtString

            MOV     AH,46h              ;Get EMS version
            INT     67h
            MOV     AH,AL
            AND     AH,1111b            ;Minor version
            MOV     CL,4
            SHR     AL,CL               ;Major version
            OR      AX,3030h            ;Turn to ASCII
            MOV     Major,AL
            MOV     Minor,AH
            MOV     SI,OFFSET Version
            CALL    PrtString

            MOV     SI,OFFSET PageMsg   ;Page frame message
            CALL    PrtString
            MOV     AH,41h              ;Get page frame address
            INT     67h
            MOV     AX,BX               ;This is the page frame base
            CALL    PrtHex
            MOV     SI,OFFSET CRLF
            CALL    PrtString
            CALL    PrtString

            MOV     SI,OFFSET TotalMsg  ;Total memory message
            CALL    PrtString
            MOV     AH,42h
            INT     67h
            MOV     AX,DX
            MOV     DX,0
            MOV     CX,4000h
            MUL     CX
            CALL    PrtDec
            MOV     SI,OFFSET CRLF
            CALL    PrtString

            MOV     SI,OFFSET FreeMsg   ;Available memory message
            CALL    PrtString
            MOV     AX,BX
            MOV     DX,0
            MOV     BX,4000h
            MUL     BX
            CALL    PrtDec
            MOV     SI,OFFSET CRLF
            CALL    PrtString

AllDone:
            .EXIT
EMSinfo     ENDP


; The following routine checks to see if an EMM is installed.
; If one is not, the carry flag is set on return
; If one is, the carry flag is cleared on return

ChkEMS      PROC    USES AX BX DX ES
            MOV     DX,OFFSET EMSName   ;Device driver name
            MOV     AH,3Dh              ;Open file
            MOV     AL,0                ;Access/file sharing mode
            INT     21h
            JC      NotThere2
            MOV     BX,AX               ;Put handle in proper place
            MOV     AH,44h              ;IOCTL
            MOV     AL,07h              ;Get output status
            INT     21h
            JC      NotThere1
            CMP     AL,0FFh
            JNE     NotThere1
            MOV     AH,3Eh              ;Close file
            INT     21h
            CLC                         ;Set for no error
            JNC     Done

NotThere1:  MOV     AH,3Eh              ;Close file
            INT     21h
NotThere2:  STC
Done:       RET
ChkEMS      ENDP


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


; The following routine prints the value in AX as a hex number

PrtHex      PROC    USES AX CX DX
            MOV     CX,0FFFFh           ;Ending flag
            PUSH    CX
            MOV     CX,10h              ;Divide by 16
PH1:        MOV     DX,0
            DIV     CX                  ;Divide by 16
            ADD     DL,30h              ;Convert to ASCII
            PUSH    DX                  ;Store remainder
            CMP     AX,0                ;Are we done?
            JNE     PH1                 ;No, so continue

PH2:        POP     DX                  ;Character is now in DL
            CMP     DX,0FFFFh           ;Is it the ending flag?
            JE      PH4                 ;Yes, so continue
            CMP     DL,'9'              ;Greater than 9?
            JBE     PH3
            ADD     DL,7                ;Convert to hex
PH3:        MOV     AH,02h              ;Output a character
            INT     21h
            JMP     PH2                 ;Keep doing it

PH4:        RET
PrtHex      ENDP


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