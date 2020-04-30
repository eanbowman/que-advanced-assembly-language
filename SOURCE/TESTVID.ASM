Page 60,132

Comment |
******************************************************************

File:       TESTVID.ASM
Author:     Allen L. Wyatt
Date:       7/10/92
Assembler:  MASM 6.0

Purpose:    Fill the screen with information, wait for a keypress,
            and then invoke Int 78h to clear the screen and home
            the cursor.  Requires that TSRVIDEO.COM has been run
            before execution.

Format:     TESTVID

******************************************************************|

            .MODEL  small
            .STACK                      ;Default 1Kb stack is OK
            .DATA

IntUse      EQU     78h                 ;Interrupt to use
Upper       EQU     'z'
Lower       EQU     ' '

ErrMsg      DB      'TSRVIDEO.COM has not been run$'
Pause       DB      13,10,'Press any key to clear screen...',0

            .CODE
            .STARTUP
TestVid     PROC
            MOV     AL,IntUse           ;Get keyboard interrupt
            MOV     AH,35h
            INT     21h
            MOV     AX,ES
            ADD     AX,BX               ;See if all zero
            CMP     AX,0
            JNE     ItsThere            ;Assume it is there, continue
            MOV     DX,OFFSET ErrMsg    ;Point to error message
            MOV     AH,9                ;Display a string using DOS
            INT     21h
            JMP     Done

ItsThere:   MOV     CX,25*80            ;Full screen
            MOV     DL,Upper            ;Get top character
TC1:        MOV     AH,02h              ;Output a character
            INT     21h
            DEC     DL                  ;Next character down
            CMP     DL,Lower
            JAE     TC2
            MOV     DL,Upper            ;Get top character
TC2:        LOOP    TC1

            MOV     SI,OFFSET Pause     ;Point to start of pause message
            MOV     AH,1                ;Display string at DS:SI
            INT     IntUse              ;Invoke the TSR
            MOV     AH,0                ;Read keyboard character
            INT     16h

            MOV     AH,0                ;Clear the screen
            INT     IntUse              ;Invoke the TSR

Done:       .EXIT
TestVid     ENDP
            END
