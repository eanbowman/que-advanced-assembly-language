Page 60,132

Comment |
******************************************************************

File:       TSRHELP.ASM
Author:     Allen L. Wyatt
Date:       7/10/92
Assembler:  MASM 6.0

Purpose:    TSR program that monitors the keyboard interrupt.  When
            a user presses the F1 key, the DOS help command is
            executed.

Format:     TSRHELP

******************************************************************|

            .MODEL  tiny                ;Creating a COM file
            .STACK                      ;Default 1Kb stack is OK
            .DATA

F1Scan      EQU     3Bh
EnvBlock    EQU     2Ch
ErrMsg      DB      'Sorry, this program cannot be used',13,10,'$'

            .CODE
            .STARTUP
TSRHelp     PROC
            CALL    Hookin              ;Go start the program
TSRHelp     ENDP


; The following is the new keyboard interrupt to replace Int 15/4F

NewInt:     CMP     AH,4Fh              ;Is it the keyboard intercept?
            JE      Process             ;Yes, so continue
            JMP     DWORD PTR CS:KeyInt ;Skip to original interrupt handler

Process:    CMP     AL,F1Scan           ;Was F1 pressed?
            JNE     NoProc              ;No, so return

            PUSH    DS
            PUSH    AX
            PUSH    CX
            PUSH    SI
            MOV     AX,CS               ;New segment address
            MOV     DS,AX

ClrLoop:    MOV     AH,1                ;Read keyboard status
            INT     16h
            JZ      Empty               ;No key, so exit
            MOV     AH,0                ;Read keyboard character
            INT     16h
            JMP     ClrLoop             ;Go do it all again

Empty:      MOV     SI,OFFSET DOSCmd    ;Point to start of stuffing
            CLD                         ;Make sure the direction flag is OK
St1:        LODSB                       ;Get the character
            CMP     AL,0                ;Is it the ending signal?
            JE      StDone              ;Yes, so exit
            MOV     CL,AL               ;Put ASCII in proper place
            MOV     CH,0                ;Don't care about the scan code
            MOV     AH,5                ;Stuffing routine
            INT     16h
            JMP     St1

StDone:     POP     SI
            POP     CX
            POP     AX
            POP     DS
            CLC                         ;Ignore character
            JNC     Done

NoProc:     STC                         ;Process character as normal
Done:       RETF    2                   ;Don't want IRET because it restores
                                        ;the flags register

; The following data elements are here because they need to be included in
; the memory reserved by the TSR call.  If they are in the normal .DATA area,
; then they are placed AFTER all the code.  That would place them in the
; transient program area, which is discarded.  That would cause a run-time
; error.

DOSCmd      DB      1Bh,'help',0Dh
            DB      00
KeyInt      DW      0000,0000           ;Address for old keyboard routine


; This is the routine to hook in the interrupt

; To make sure that Int 15/4F is usable on this machine, call Int 15/C0.  Bit
; 4 of the byte at offset 05 of the returned table indicates if 15/4F is
; chained from Int 09h.  If Int 15/C0 is not available on the system, then
; 80h or 86h should be returned in AH.

Hookin      PROC
            POP     AX                  ;Throw away the return address

            MOV     AH,0C0h
            INT     15h
            CMP     AH,80h              ;Available?
            JE      NoWay               ;Nope
            CMP     AH,86h
            JE      NoWay               ;Sorry

            MOV     AL,ES:[BX+5]        ;Get the byte
            TEST    AL,00010000b        ;Only interested in bit 4
            JNZ     AllOK               ;Function supported, so continue

NoWay:      MOV     DX,OFFSET ErrMsg    ;Point to error message
            MOV     AH,9                ;Display a string using DOS
            INT     21h
            MOV     AH,4Ch              ;Terminate with code
            MOV     AL,1
            INT     21h

; Everything is OK.  Now hook in the intercept and start the program

AllOK:      MOV     AL,15h              ;Get keyboard interrupt
            MOV     AH,35h
            INT     21h
            MOV     KeyInt[0],BX        ;Offset address
            MOV     KeyInt[2],ES        ;Segment address

            MOV     DX,OFFSET NewInt    ;New offset address
            MOV     AL,15h              ;Change keyboard vector
            MOV     AH,25h              ;to point to new handler
            INT     21h

            MOV     ES,DS:[EnvBlock]    ;Get environment block segment
            MOV     AH,49h              ;Free memory block (don't need it)
            INT     21h

            MOV     DX,OFFSET Hookin    ;End of resident area
            MOV     CL,4                ;Divide by 16
            SHR     DX,CL               ;No in paragraphs
            INC     DX                  ;Add 1 for good measure
            MOV     AL,0                ;Return code is OK
            MOV     AH,31h              ;TSR function
            INT     21h

Hookin      ENDP

            END
