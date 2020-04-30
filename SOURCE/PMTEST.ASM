Page 60,132

Comment |
******************************************************************

File:       PMTEST.ASM
Author:     Allen L. Wyatt
Date:       8/2/92
Assembler:  MASM 6.0

Purpose:    Example of operating in protected mode to accomplish
            a task

Format:     PMTEST

******************************************************************|

            .MODEL  small
            .STACK  2048
            .386                        ;Instructions require 80386
            .DATA

ReadyMsg    DB      'Switching to protected mode...'
CRLF        DB      13,10,0

BufSelector DW      0000
BufHandleH  DW      0000
BufHandleL  DW      0000
BufLAddrH   DW      0000
BufLAddrL   DW      0000
DOSBufSel   DW      0000
DOSBufSeg   DW      0000

Flag32      DB      00
ProcType    DB      00
VerNum      DW      0000
MemNeeded   DW      0000
DPMIentry   DD      00000000

FillMsg     DB      'Filling a portion of the buffer...',13,10,0
ReadMsg     DB      'Reading the buffer...',13,10,0
TestMsg     DB      13,'Reading from protected mode, message ',0

; Register storage areas for cross-mode interrupt handling
; This structure is defined by the DPMI specifications for
; use with function 0300h

RegSet      EQU     THIS BYTE
SaveDI      EQU     THIS WORD
SaveEDI     DD      00000000
SaveSI      EQU     THIS WORD
SaveESI     DD      00000000
SaveBP      EQU     THIS WORD
SaveEBP     DD      00000000
            DD      00000000            ;Reserved area--set to 0
SaveBX      EQU     THIS WORD
SaveEBX     DD      00000000
SaveDX      EQU     THIS WORD
SaveEDX     DD      00000000
SaveCX      EQU     THIS WORD
SaveECX     DD      00000000
SaveAX      EQU     THIS WORD
SaveEAX     DD      00000000
SaveFlags   DW      0000
SaveES      DW      0000
SaveDS      DW      0000
SaveFS      DW      0000
SaveGS      DW      0000
SaveIP      DW      0000
SaveCS      DW      0000
SaveSP      DW      0000
SaveSS      DW      0000

; Error messages

ErrMsg      DB      'Error - '
ErrNum      DW      0000,0000
            DB      '   ',0
EMsg1       DB      'No DPMI host detected',13,10,0
EMsg2       DB      'Could not allocate memory for mode switch',13,10,0
EMsg3       DB      'Could not switch to protected mode',13,10,0
EMsg4       DB      'Could not allocate LDT',13,10,0
EMsg5       DB      'Could not set up 1Mb buffer',13,10,0
EMsg6       DB      'Could not set descriptor base address',13,10,0
EMsg7       DB      'Could not set descriptor limit',13,10,0

            .CODE
            .STARTUP
PMTest      PROC

; The following memory allocation code works because it is known that MASM
; sets DS and SS to the same segment address in the startup code.  Also, ES
; is set to the PSP for the program upon entry.

            MOV     BX,DS               ;Point to start of data segment
            MOV     AX,ES               ;Point to start of PSP
            SUB     BX,AX               ;Number of segments for code & data
            MOV     AX,SP               ;SP is pointing to top of stack area
            MOV     CL,4                ;Dividing by 16
            SHR     AX,CL
            ADD     BX,AX               ;BX=paragraphs needed
            MOV     AH,4Ah              ;Modify memory allocation
            INT     21h

; Check to see if DPMI is available (makes no sense to go on if not)
            CALL    ChkDPMI             ;See if host is present
            JC      Error1              ;Not there

            MOV     SI,OFFSET ReadyMsg  ;Ready to switch
            CALL    PrtString
            MOV     AX,0                ;In case no memory needed
            MOV     BX,MemNeeded        ;Get number of paragraphs needed by host
            CMP     BX,0                ;Any allocation needed?
            JE      PM1                 ;No, so continue
            MOV     AH,48h              ;Allocate memory
            INT     21h
            JC      Error2              ;Could not allocate

PM1:        MOV     ES,AX               ;Segment of allocated memory
            MOV     AX,0                ;Indicate 16-bit application
            CALL    DPMIentry           ;Switch to protected mode
            JC      Error3              ;Error--still in real mode

; If we reach this point, we are operating in protected mode

            PUSH    DS
            POP     GS                  ;Save the data selector in secure place

            MOV     AX,0000h            ;Allocate LDT descriptor
            MOV     CX,1                ;Only need one descriptor
            INT     31h
            JC      Error4              ;Could not allocate descriptor
            MOV     BufSelector,AX

            MOV     AX,0501h            ;Allocate memory block
            MOV     BX,10h              ;BX:CX = 100000h (1M) bytes wanted
            MOV     CX,0000h
            INT     31h
            JC      Error5
            MOV     BufHandleH,SI       ;Store handle
            MOV     BufHandleL,DI
            MOV     BufLAddrH,BX
            MOV     BufLAddrL,CX

            MOV     AX,0007h            ;Set base address to address
            MOV     BX,BufSelector      ;Move selector to proper place
            MOV     CX,BufLAddrH        ;Get linear address in CX:DX
            MOV     DX,BufLAddrL
            INT     31h
            JC      Error6              ;Could not set base address

            MOV     AX,0008h            ;Set limit
            MOV     BX,BufSelector
            MOV     CX,0h               ;Buffer size in CX:DX
            MOV     DX,0FFFFh
            INT     31h
            JC      Error7              ;Could not set limit

; Ready to fill buffer with string.

            MOV     SI,OFFSET FillMsg
            CALL    PMPrtString
            MOV     CX,1680             ;39-character message fits this
            CLD                         ;   many times in buffer
            MOV     ES,BufSelector
            MOV     DI,0                ;Start of page buffer
InLoop:     PUSH    CX
            MOV     SI,OFFSET TestMsg
            MOV     CX,39               ;Length of message
            REP     MOVSB
            POP     CX
            LOOP    InLoop
            MOV     AL,0FFh
            STOSB

            MOV     SI,OFFSET ReadMsg
            CALL    PMPrtString
            MOV     DS,BufSelector
            MOV     SI,0
            MOV     AX,1                ;Reading message 1
            MOV     DX,0
OutLoop:    CALL    PMPrtString
            CALL    PMPrtDec
            INC     AX
            CMP     BYTE PTR [SI],0FFh
            JNE     OutLoop
            PUSH    GS
            POP     DS                  ;Default data selector

            JMP     CleanUp

Error1:     MOV     SI,OFFSET EMsg1
            CALL    PrtString
            JMP     AllDone
Error2:     MOV     SI,OFFSET EMsg2
            CALL    PrtString
            JMP     AllDone
Error3:     MOV     SI,OFFSET EMsg3
            CALL    PrtString
            JMP     AllDone
Error4:     MOV     SI,OFFSET EMsg4
            CALL    PMAlert
            JMP     AllDone
Error5:     MOV     SI,OFFSET EMsg5
            CALL    PMAlert
            JMP     AllDone
Error6:     MOV     SI,OFFSET EMsg6
            CALL    PMAlert
            JMP     CleanUp
Error7:     MOV     SI,OFFSET EMsg7
            CALL    PMAlert

CleanUp:    MOV     AX,0001h            ;Release descriptor
            MOV     BX,BufSelector
            INT     31h
            MOV     AX,0502h            ;Release memory block
            MOV     SI,BufHandleH       ;Store handle
            MOV     DI,BufHandleL
            INT     31h

AllDone:
            .EXIT
PMTest      ENDP


; The following routine checks to see if a DPMI master program is installed.
; If one is not, the carry flag is set on return
; If one is, the stat info is stored and the carry flag is cleared on return

ChkDPMI     PROC    NEAR USES AX BX CX DX SI DI ES
            MOV     AX,1687h            ;Get DPMI host address
            INT     2Fh                 ;Multiplex interrupt
            CMP     AX,0                ;Was it there?
            JNE     NotThere            ;Nope, so exit

            AND     BL,00000001b        ;Test bit 1 (32-bit OK?)
            SETNE   AL
            MOV     Flag32,AL
            MOV     ProcType,CL
            MOV     VerNum,DX
            MOV     MemNeeded,SI
            MOV     WORD PTR DPMIentry,DI
            MOV     WORD PTR DPMIentry+2,ES
            CLC                         ;Set for no error
            JNC     Done

NotThere:   STC
Done:       RET
ChkDPMI     ENDP


; Save registers

SaveRegs    PROC    NEAR USES AX DS
            PUSH    GS
            POP     DS                  ;Default data selector
            MOV     SaveAX,AX
            MOV     SaveBX,BX
            MOV     SaveCX,CX
            MOV     SaveDX,DX
            MOV     SaveSI,SI
            MOV     SaveDI,DI
            MOV     SaveBP,BP
            PUSHF
            POP     AX
            MOV     SaveFlags,AX
            RET
SaveRegs    ENDP

GetRegs     PROC    NEAR USES DS
            PUSH    GS
            POP     DS                  ;Default data selector
            MOV     AX,SaveFlags
            PUSH    AX
            POPF
            MOV     AX,SaveAX
            MOV     BX,SaveBX
            MOV     CX,SaveCX
            MOV     DX,SaveDX
            MOV     SI,SaveSI
            MOV     DI,SaveDI
            MOV     BP,SaveBP
            RET
GetRegs     ENDP


DOSfunc     PROC    NEAR USES AX BX CX ES
            MOV     AX,0300h            ;Simulate real-mode interrupt
            MOV     BL,21h              ;Want the DOS interrupt
            MOV     BH,0                ;Should be 0
            MOV     CX,0                ;Copy nothing from stack
            PUSH    GS
            POP     ES                  ;ES:DI must point to data structure
            MOV     DI,OFFSET ES:RegSet
            INT     31h
            RET
DOSfunc     ENDP


; The following routine prints the ASCIIZ string pointed to by DS:SI
; Works from protected mode by switching to real mode to do DOS function

PMPrtString PROC    NEAR USES AX DX
PS1:        MOV     DL,[SI]             ;Get character
            INC     SI                  ;Point to next one
            CMP     DL,0                ;End of string?
            JE      PS2                 ;Yes, so exit
            MOV     AH,02h              ;Output a character
            CALL    SaveRegs
            CALL    DOSfunc
            CALL    GetRegs
            JMP     PS1                 ;Keep doing it
PS2:        RET
PMPrtString ENDP


; The following routine prints the ASCIIZ string pointed to by DS:SI

PrtString   PROC    NEAR USES AX DX SI
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
; Will accept numbers up to 655,359,999.  Anything larger will not print.

            .DATA
Temp        DW      0000

            .CODE
PMPrtDec    PROC    NEAR USES AX BX CX DX DS

            PUSH    GS
            POP     DS                  ;Default data selector
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
            CALL    SaveRegs
            CALL    DOSfunc
            CALL    GetRegs
            JMP     PD3                 ;Keep doing it

PD4:        RET
PMPrtDec    ENDP


; Print error number and message in protected mode

PMAlert     PROC
            CMP     VerNum,5Ah          ;Running under version .9?
            JE      NoErrNum            ;Yes, so there are no error numbers
            CALL    ConHexLong
            MOV     ErrNum[0],AX
            MOV     ErrNum[2],DX
            PUSH    SI
            MOV     SI,OFFSET ErrMsg
            CALL    PMPrtString
            POP     SI
NoErrNum:   CALL    PMPrtString
            RET
PMAlert     ENDP


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