Page 60,132

Comment |
******************************************************************

File:       BUFFMOVE.ASM
Author:     Allen L. Wyatt
Date:       3/21/92
Assembler:  MASM 6.0

Purpose:    Moves the keyboard buffer pointers to new location
            in the 64K of memory beginning at 0040:0000.

Format:     BUFFMOVE

******************************************************************|

Head        EQU     01Ah
Tail        EQU     01Ch
OrigBuff    EQU     01Eh
BuffStart   EQU     080h
BuffEnd     EQU     082h

NewBuff     EQU     200h
NewEnd      EQU     300h

            .MODEL  small
            .STACK                      ;Default 1Kb stack is OK

            .CODE
            .STARTUP

BUFFMOVE    PROC

            PUSH    DS
            MOV     AX,040h             ;Point to BIOS data area
            MOV     DS,AX

            MOV     AX,NewBuff          ;Set start of buffer
            MOV     BX,BuffStart
            MOV     [BX],AX
            MOV     BX,Head
            MOV     [BX],AX             ;Move head and tail into
            MOV     BX,Tail             ;  the new buffer area
            MOV     [BX],AX

            MOV     AX,NewEnd           ;Set end of buffer
            MOV     BX,BuffEnd
            MOV     [BX],AX

            POP     DS
            .EXIT
BuffMove    ENDP

            END
