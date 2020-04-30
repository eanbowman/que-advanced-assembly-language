Page 60,132

Comment |
******************************************************************

File:       POLL.ASM
Author:     Allen L. Wyatt
Date:       6/27/92
Assembler:  MASM 6.0

Purpose:    A mini terminal program.  Displays on the screen all the
            info coming in the modem.  Anything typed is sent to the 
            modem.  Uses polling techniques and BIOS functions for
            all communications access.  Program is exited when ESC
            is pressed.

Format:     POLL

******************************************************************|

; The following equates are modem configuration settings
ComPort     EQU     01h                 ;0=COM1, 1=COM2, 2=COM3, 3=COM4

; The following equates are for data format settings
DF_N81      EQU     10100011b           ;2400 bps, 8 data bits, 1 stop bit, no parity
DF_E71      EQU     10111010b           ;2400 bps, 7 data bits, 1 stop bit, even parity

            .MODEL  small
            .STACK                      ;Default 1Kb stack is OK

            .CODE
            .STARTUP
Poll        PROC
            MOV     AH,00h              ;Initialize communications port
            MOV     AL,DF_E71           ;2400 bps, E71
            MOV     DX,ComPort          ;Using this port
            INT     14h
            CALL    Cls

InputLoop:  MOV     AH,1                ;Check keyboard status
            INT     16h
            JZ      NoKey               ;No key there

            MOV     AH,0                ;Get key
            INT     16h
            CMP     AH,1                ;Was the key escape? (scan code=1)
            JE      AllDone             ;Yes, so exit
            MOV     AH,01h              ;No, so write character in AL to port
            MOV     DX,ComPort          ;Send to this port
            INT     14h

NoKey:      MOV     AH,03h              ;Get port status
            MOV     DX,ComPort          ;From this port
            INT     14h
            TEST    AH,00000001b        ;Is data ready?
            JZ      InputLoop           ;No, so go back in loop

            MOV     AH,02h              ;Read character from port
            MOV     DX,ComPort          ;From this port
            INT     14h
            TEST    AH,10000000b        ;Was there a timeout?
            JZ      NoTimeout           ;No, continue
            TEST    AH,00011110b        ;If not these errors, then data not ready
            JZ      InputLoop
            MOV     AL,'!'              ;Indicate data loss
NoTimeout:  MOV     DL,AL
            MOV     AH,02h              ;Output a character
            INT     21h
            JMP     InputLoop

AllDone:    .EXIT
Poll        ENDP


 ; The following routine clears the screen and homes the cursor

Cls         PROC    USES AX BX CX DX
            MOV     AH,6                ;Scroll window up
            MOV     AL,0                ;Scroll full screen
            MOV     BH,7                ;Normal white on black
            MOV     CX,0                ;Upper left corner of screen
            MOV     DH,24               ;Bottom right
            MOV     DL,79
            INT     10h

            MOV     DX,0                ;Upper left corner of screen
            MOV     BH,0                ;Assume page 0
            MOV     AH,2                ;Set cursor position
            INT     10h
            RET
Cls         ENDP

            END
