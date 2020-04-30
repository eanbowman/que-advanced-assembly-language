Page 60,132

Comment |
******************************************************************

File:       EMSTEST.ASM
Author:     Allen L. Wyatt
Date:       7/30/92
Assembler:  MASM 6.0

Purpose:    Allocate a block of expanded memory, write to it, 
            read the information from there, and then display it.

Format:     EMSTEST

******************************************************************|

            .MODEL  small
            .STACK                      ;Default 1Kb stack is OK
            .DATA

EMSName     DB      'EMMXXXX0',0
EMPhandle   DW      0000
FillMsg     DB      'Filling expanded memory pages',13,10,0
ReadMsg     DB      'Reading expanded memory pages',13,10,0
TestMsg     DB      'This is test message '
Count       DB      '   1',13,0

EMsg1       DB      'Expanded memory manager not installed',13,10,0
EMsg2       DB      'Could not allocate memory requested',13,10,0
EMsg3       DB      'Error mapping memory',13,10,0
EMsg4       DB      'Could not determine page frame',13,10,0
EMsg5       DB      'Error releasing EMS handle',13,10,0

            .CODE
            .STARTUP
EMSTest     PROC

            CALL    ChkEMS              ;See if EMM present
            JC      Error1              ;Not there

            MOV     AH,43h              ;Allocate pages
            MOV     BX,2                ;Get 2 pages (32K)
            INT     67h
            CMP     AH,0                ;Was there an error?
            JNE     Error2              ;Yes, so handle
            MOV     EMPhandle,DX        ;No, save handle

            MOV     AH,44h              ;Map memory
            MOV     AL,0                ;First EMS page
            MOV     BX,0                ;Want this part of my memory
            MOV     DX,EMPhandle        ;Assigned to this handle
            INT     67h
            CMP     AH,0                ;Was there an error?
            JNE     Error3              ;Yes, so handle
            MOV     AH,44h              ;Map memory
            MOV     AL,1
            MOV     BX,1
            INT     67h
            CMP     AH,0                ;Was there an error?
            JNE     Error3              ;Yes, so handle

            MOV     AH,41h              ;Get page frame address
            INT     67h
            CMP     AH,0                ;Was there an error?
            JNE     Error4              ;Yes, so handle
            MOV     ES,BX               ;Make page frame addressable

            MOV     SI,OFFSET FillMsg
            CALL    PrtString
            MOV     CX,1213             ;27-character message fits this
            CLD                         ;   many times in 32K
            MOV     DI,0000             ;Start of page buffer
InLoop:     PUSH    CX
            MOV     SI,OFFSET TestMsg
            MOV     CX,27               ;Length of message
            REP     MOVSB
            CALL    IncMsg              ;Increment the counter
            POP     CX
            LOOP    InLoop
            MOV     AL,0FFh
            STOSB

            MOV     SI,OFFSET ReadMsg
            CALL    PrtString
            MOV     SI,0
            PUSH    DS                  ;Set up addressing
            PUSH    ES
            POP     DS
OutLoop:    CALL    PrtString
            CMP     BYTE PTR [SI],0FFh
            JNE     OutLoop
            POP     DS

            MOV     AH,45h              ;Release EMS handle
            MOV     DX,EMPhandle        ;This handle
            INT     67h
            CMP     AH,0                ;Was there an error
            JNE     Error5
            JMP     AllDone

Error1:     MOV     SI,OFFSET EMsg1     ;No EMM in system
            JMP     ErrCommon
Error2:     MOV     SI,OFFSET EMsg2
            JMP     ErrCommon
Error3:     MOV     SI,OFFSET EMsg3
            JMP     ErrCommon
Error4:     MOV     SI,OFFSET EMsg4
            JMP     ErrCommon
Error5:     MOV     SI,OFFSET EMsg5
ErrCommon:  CALL    PrtString

AllDone:
            .EXIT
EMSTest     ENDP


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


; Increment the message being stored in memory

IncMsg      PROC    USES SI
            MOV     SI,OFFSET Count
            ADD     SI,3
IM1:        INC     BYTE PTR [SI]
            CMP     BYTE PTR [SI],':'   ;Out of number range?
            JNE     IM3                 ;No, so continue
            MOV     BYTE PTR [SI],'0'   ;Reset to zero
            DEC     SI
            CMP     BYTE PTR [SI],' '   ;Filled in yet?
            JNE     IM2
            MOV     BYTE PTR [SI],'0'   ;Reset to zero
IM2:        JMP     IM1
IM3:        RET
IncMsg      ENDP


; The following routine prints the ASCIIZ string pointed to by DS:SI
; The only register affected by this routine is SI

PrtString   PROC    USES AX DX
PS1:        MOV     DL,[SI]             ;Get character
            INC     SI                  ;Point to next one
            CMP     DL,0                ;End of string?
            JE      PS2                 ;Yes, so exit
            MOV     AH,02h              ;Output a character
            INT     21h
            JMP     PS1                 ;Keep doing it
PS2:        RET
PrtString   ENDP

            END
