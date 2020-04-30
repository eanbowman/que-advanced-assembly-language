Page 60,132

Comment |
******************************************************************

File:       BUFFSTUF.ASM
Author:     Allen L. Wyatt
Date:       3/21/92
Assembler:  MASM 6.0

Purpose:    Stuff characters into the keyboard buffer which will
            be executed by DOS when the program is completed.

Format:     BUFFSTUF.ASM

******************************************************************|

            .MODEL  small
            .STACK                      ;Default 1Kb stack is OK
            .DATA

OKMsg       DB      'BUFFSTUF has completed working.  Now returning to DOS...$'
FullMsg     DB      'Sorry; the keyboard buffer is full.  Flushing buffer...$'

; The following line to be stuffed into the buffer works with DOS 5.  It can
; be changed with no ill effects to the program.  All commands will be
; stuffed until an NULL character is reached.  The 0Dh is a carriage return
; and will cause DOS to execute the line before it.

Stuffer     DB      'dir',0Dh
            DB      'cls',0Dh
            DB      'type buffstuf.asm',0Dh
            DB      'Well, that',27h,'s about it.  (Now for an Esc)',1Bh
            DB      00

            .CODE
            .STARTUP

BUFFSTUF    PROC

            MOV     SI,OFFSET Stuffer   ;Point to start of stuffing
            CLD                         ;Make sure the direction flag is OK
St1:        LODSB                       ;Get the character
            CMP     AL,0                ;Is it the ending signal?
            JE      StDone              ;Yes, so exit
            MOV     CL,AL               ;Put ASCII in proper place
            MOV     CH,0                ;Don't care about the scan code
            MOV     AH,5                ;Stuffing routine
            INT     16h
            CMP     AL,1                ;If the buffer is full, AL=1
            JNE     St1
            CALL    ClrBuff             ;Go clear the buffer
            MOV     DX,Offset FullMsg   ;Point to full message
            JMP     Exit

StDone:     MOV     DX,Offset OKMsg     ;Point to everything OK message
Exit:       MOV     AH,9                ;Display a string using DOS
            INT     21h

            .EXIT
BUFFSTUF    ENDP

; The following routine clears the entire keyboard buffer

ClrBuff     PROC    USES AX
CB1:        MOV     AH,1                ;Read keyboard status
            INT     16h
            JZ      CBExit              ;No key, so exit
            MOV     AH,0                ;Read keyboard character
            INT     16h
            JMP     CB1                 ;Go do it all again
CBExit:     RET
ClrBuff     ENDP

            END
