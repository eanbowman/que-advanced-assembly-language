Page 60,132

Comment |
******************************************************************

File:       POSTCARD.ASM
Author:     Allen L. Wyatt
Date:       8/2/92
Assembler:  MASM 6.0

Purpose:    Example of operating in protected mode.
            All this program does is switch modes, display a
            message, and then terminate.

            Program must be run with a DPMI host (such as Windows)
            present.

Format:     POSTCARD

******************************************************************|

            .MODEL  small
            .STACK                      ;Default 1Kb stack is OK
            .386                        ;Instructions require 80386
            .DATA

ReadyMsg    DB      13,10,10,'Switching to protected mode.',13,10,10,0
MadeIt      DB      '     Hello to the folks at home from the p-zone!',13,10
            DB      '     Hugs and kisses to the kids; will write soon...',13,10,10,0
EndMsg      DB      'Back home again after a successful jaunt beyond the edge',13,10
            DB      'Program completed.',13,10,10,0

Flag32      DB      00
ProcType    DB      00
VerNum      DW      0000
MemNeeded   DW      0000
DPMIentry   DW      0000,0000

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

EMsg1       DB      'No DPMI host detected',13,10,0
EMsg2       DB      'Could not allocate real-mode memory requested',13,10,0
EMsg3       DB      'The switch to protected mode did not work',13,10,0

            .CODE
            .STARTUP
PostCard    PROC
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

; Check to see if DPMI is available, and make the switch if it is
            CALL    ChkDPMI             ;See if host is present
            JC      Error1              ;Not there

            MOV     SI,OFFSET ReadyMsg  ;Ready to switch
            CALL    PrtString
            MOV     AX,0                ;In case no memory needed
            MOV     BX,MemNeeded        ;Get number of paragraphs needed by host
            CMP     BX,0                ;Any allocation needed?
            JE      Plunge              ;No, so continue
            MOV     AH,48h              ;Allocate memory
            INT     21h
            JC      Error2              ;Could not allocate

Plunge:     MOV     ES,AX
            MOV     AX,0                ;Indicate 16-bit application
            CALL    DWORD PTR DPMIentry ;Switch to protected mode
            JC      Error3              ;Error--still in real mode

; If we reach this point, we are operating in protected mode

            MOV     SI,OFFSET MadeIt    ;Message to folks back home
            CALL    PMPrtString         ;Print from protected mode
            MOV     SI,OFFSET EndMsg
            CALL    PMPrtString
            JMP     AllDone

Error1:     MOV     SI,OFFSET EMsg1
            JMP     ErrCommon
Error2:     MOV     SI,OFFSET EMsg2
            JMP     ErrCommon
Error3:     MOV     SI,OFFSET EMsg3
ErrCommon:  CALL    PrtString

AllDone:
            .EXIT
PostCard    ENDP


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
            MOV     MemNeeded,SI
            MOV     DPMIentry[0],DI
            MOV     DPMIentry[2],ES
            CLC                         ;Set for no error
            JNC     Done

NotThere:   STC
Done:       RET
ChkDPMI     ENDP


; Save registers

SaveRegs    PROC    NEAR USES AX
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

GetRegs     PROC    NEAR
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
            PUSH    DS                  ;ES:DI must point to data structure
            POP     ES
            MOV     DI,OFFSET RegSet
            INT     31h
            RET
DOSfunc     ENDP

; The following routine prints the ASCIIZ string pointed to by DS:SI
; Works from protected mode by switching to real mode to do DOS function

PMPrtString PROC    USES AX DX SI
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

PrtString   PROC    FAR USES AX DX SI
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