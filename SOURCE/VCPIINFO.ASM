Page 60,132

Comment |
******************************************************************

File:       VCPIINFO.ASM
Author:     Allen L. Wyatt
Date:       7/30/92
Assembler:  MASM 6.0

Purpose:    Display information about extended memory using VCPI functions

Format:     VCPIINFO

******************************************************************|

            .MODEL  small
            .STACK                      ;Default 1Kb stack is OK
            .386                        ;Instructions require 80386
            .DATA

EMSName     DB      'EMMXXXX0',0
InMsg       DB      'A VCPI master program is installed',13,10,0
Version     DB      'Supports VCPI version '
Major       DB      00,'.'
Minor       DB      00,'.'
CRLF        DB      13,10,0
AvailMsg    DB      'Extended memory available:  ',0

EMsg1       DB      'No VCPI master program detected',13,10,0
EMsg2       DB      'Could not determine available 4K pages',13,10,0

            .CODE
            .STARTUP
VCPIinfo    PROC
            CALL    ChkVCPI             ;See if master program present
            JC      Error1              ;Not there
            MOV     SI,OFFSET InMsg
            CALL    PrtString
            MOV     SI,OFFSET Version
            CALL    PrtString

            MOV     AX,0DE03h           ;Get number of free 4K pages
            INT     67h
            CMP     AH,0                ;Any error?
            JNE     Error2              ;Yes, handle
            SHL     EDX,12              ;Multiply by 4096 (4K pages)
            MOV     AX,DX               ;Low word
            SHR     EDX,16              ;Move high word into DX
            MOV     SI,OFFSET AvailMsg  ;Total available memory message
            CALL    PrtString
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
VCPIinfo    ENDP


; The following routine checks to see if a VCPI master program is installed.
; If one is not, the carry flag is set on return
; If one is, the version info is stored and the carry flag is cleared on return

ChkVCPI     PROC    USES AX BX ES
            CALL    ChkEMS              ;Make sure EMS is in first
            JC      NotThere            ;EMS not in, so VCPI can't be
            CALL    GrabPage            ;Make sure EMS initiated
            JC      NotThere            ;Exit if any hint of error

            MOV     AX,0DE00h           ;Get VCPI installed state
            INT     67h
            CMP     AL,0
            JNE     NotThere
            OR      BX,3030h            ;Turn to ASCII
            MOV     Major,BH
            MOV     Minor,BL
            CLC                         ;Set for no error
            JNC     Done

NotThere:   STC
Done:       RET
ChkVCPI     ENDP


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


; This function allocates an EMS page, and then releases it.  This is
; done to make sure the EMS driver has switched the CPU to V86 mode.
; On return, the carry is set if there was any problem using the EMS
; functions.  Carry is clear otherwise.

GrabPage    PROC
            MOV     AH,43h              ;Allocate pages
            MOV     BX,1                ;Get 1 page (16K)
            INT     67h
            CMP     AH,0                ;Was there an error?
            JNE     GPErr               ;Yes, so exit
            MOV     AH,45h              ;Release EMS handle
            INT     67h
            CMP     AH,0                ;Was there an error?
            JNE     GPErr               ;Yes, so exit
            CLC                         ;Mark for no error
            JNC     GPEnd
GPErr:      STC
GPEnd:      RET
GrabPage    ENDP


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