Page 60,132

Comment |
******************************************************************

File:       DPMIINFO.ASM
Author:     Allen L. Wyatt
Date:       7/31/92
Assembler:  MASM 6.0

Purpose:    Display information about extended memory using DPMI functions

Format:     DPMIINFO

******************************************************************|

            .MODEL  small
            .STACK                      ;Default 1Kb stack is OK
            .386                        ;Instructions require 80386
            .DATA

InMsg       DB      'A DPMI host is installed'
CRLF        DB      13,10,0
Version     DB      'Supports DPMI version ',0
Divider     DB      '.',0
AvailMsg    DB      'Extended memory available:  ',0
Yes32       DB      '32-bit programs can be executed with this host',13,10,0
No32        DB      'Only 16-bit programs can be executed with this host',13,10,0
EntryMsg    DB      'The protected mode entry point is '
SegNum      DW      0000,0000
            DB      ':'
OffNum      DW      0000,0000
            DB      13,10,0

CPUTable    DW      OFFSET CPU286
            DW      OFFSET CPU386
            DW      OFFSET CPU486
            DW      OFFSET CPUUN

CPU286      DB      'Running on an 80286 CPU',13,10,0
CPU386      DB      'Running on an 80386 CPU',13,10,0
CPU486      DB      'Running on an 80486 CPU',13,10,0
CPUUN       DB      'Running on an unknown CPU',13,10,0

Flag32      DB      00
ProcType    DB      00
VerNum      DW      0000
DPMIentry   DW      0000,0000

EMsg1       DB      'No DPMI host detected',13,10,0

            .CODE
            .STARTUP
DPMIinfo    PROC
            CALL    ChkDPMI             ;See if master program present
            JC      Error1              ;Not there
            MOV     SI,OFFSET InMsg
            CALL    PrtString
            MOV     SI,OFFSET Version
            CALL    PrtString
            MOV     BX,VerNum
            MOV     AH,0
            MOV     AL,BH               ;Major version number
            CALL    PrtDec
            MOV     SI,OFFSET Divider
            CALL    PrtString
            MOV     AL,BL               ;Minor version number
            CALL    PrtDec
            MOV     SI,OFFSET CRLF
            CALL    PrtString

            MOV     BH,0
            MOV     BL,ProcType
            DEC     BL
            DEC     BL
            SHL     BX,1
            ADD     BX,OFFSET CPUTable
            MOV     SI,[BX]
            CALL    PrtString

            MOV     SI,OFFSET No32      ;Assume can't do 32-bit
            MOV     BL,Flag32
            CMP     BL,1
            JNE     FlagPrt
            MOV     SI,OFFSET Yes32     ;32-bit is OK after all
FlagPrt:    CALL    PrtString

            MOV     AX,DPMIentry[2]
            CALL    ConHexLong
            MOV     SegNum[0],AX
            MOV     SegNum[2],DX
            MOV     AX,DPMIentry[0]
            CALL    ConHexLong
            MOV     OffNum[0],AX
            MOV     OffNum[2],DX

            MOV     SI,OFFSET EntryMsg  ;Entry point message
            CALL    PrtString
            JMP     AllDone

Error1:     MOV     SI,OFFSET EMsg1
            CALL    PrtString

AllDone:
            .EXIT
DPMIinfo    ENDP


; The following routine checks to see if a DPMI master program is installed.
; If one is not, the carry flag is set on return
; If one is, the stat info is stored and the carry flag is cleared on return

ChkDPMI     PROC    USES AX BX CX DX SI DI ES
            MOV     AX,1687h            ;Get DPMI host address
            INT     2Fh                 ;Multiplex interrupt
            CMP     AX,0                ;Was it there?
            JNE     NotThere            ;Nope, so exit

            AND     BL,00000001b        ;Test bit 1 (32-bit OK?)
            SETNE   AL
            MOV     Flag32,AL
            MOV     ProcType,CL
            MOV     VerNum,DX
            MOV     DPMIentry[0],DI
            MOV     DPMIentry[2],ES
            CLC                         ;Set for no error
            JNC     Done

NotThere:   STC
Done:       RET
ChkDPMI     ENDP


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


; The following routine prints the value in AX as a decimal number

PrtDec      PROC    USES AX CX DX
            MOV     CX,0FFFFh           ;Ending flag
            PUSH    CX
            MOV     CX,10
PD1:        MOV     DX,0
            DIV     CX                  ;Divide by 10
            ADD     DL,30h              ;Convert to ASCII
            PUSH    DX                  ;Store remainder
            CMP     AX,0                ;Are we done?
            JNE     PD1                 ;No, so continue

PD2:        POP     DX                  ;Character is now in DL
            CMP     DX,0FFFFh           ;Is it the ending flag?
            JE      PD3                 ;Yes, so continue
            MOV     AH,02h              ;Output a character
            INT     21h
            JMP     PD2                 ;Keep doing it

PD3:        RET
PrtDec      ENDP


; The following routine converts the number in AL into an ASCII
; representation of the hex value, with a leading zero.  Value
; is returned in AX as well.

ConHex      PROC    USES CX
            MOV     CL,10h              ;What we will be dividing by
            MOV     AH,0
            DIV     CL                  ;Divide by 16
            OR      AX,3030h            ;Convert to ASCII
            CMP     AL,'9'              ;Is it greater than 9?
            JBE     CA4                 ;No, so continue
            ADD     AL,7                ;Make into hex digit
CA4:        CMP     AH,'9'              ;Is it greater than 9?
            JBE     CA5                 ;No, so continue
            ADD     AH,7                ;Make into hex digit
CA5:        RET
ConHex      ENDP

; The following uses ConHex to convert a long number (AX) into it's ASCII
; equivalent in DX:AX.

ConHexLong  PROC
            PUSH    AX
            CALL    ConHex
            MOV     DX,AX
            POP     AX
            MOV     AL,AH
            CALL    ConHex
            RET
ConHexLong  ENDP

            END
