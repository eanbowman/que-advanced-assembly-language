Page 60,132

Comment |
******************************************************************

File:       TSRVIDEO.ASM
Author:     Allen L. Wyatt
Date:       7/10/92
Assembler:  MASM 6.0

Purpose:    TSR program that acts as a function dispatcher for
            various video related subroutines.  This implementation
            contains only 2 functions, as follows:
                AH      Function
                 0      Clear screen, home cursor
                 1      Print string at DS:SI
            This is a passive TSR.  It can be used from other
            programs by invoking an INT 78h with AH loaded with
            the function number wanted.

Format:     TSRVIDEO

******************************************************************|

            .MODEL  tiny                ;Creating a COM file
            .STACK                      ;Default 1Kb stack is OK
            .DATA

IntUse      EQU     78h                 ;Interrupt to use
EnvBlock    EQU     2Ch
ErrMsg      DB      'Sorry, that vector is already in use',13,10,0

            .CODE
            .STARTUP
TSRVideo    PROC
            CALL    Hookin              ;Start TSR, no return
TSRVideo    ENDP

; The following is the new interrupt routine for Int 78h.  It clears the
; screen and homes the cursor.

NewInt:     CMP     AH,0                ;Want to clear screen?
            JNE     NI1                 ;Nope, continue
            CALL    Cls
            JMP     NI9
NI1:        CMP     AH,1                ;Want to print string?
            JNE     NI9                 ;Nope, continue
            CALL    PrtString

NI9:        IRET


; Clear the screen and home the cursor

Cls         PROC    USES AX BX CX DX
            MOV     AH,8                ;Read character and attribute
            MOV     BH,0                ;Assume page 0
            INT     10h
            MOV     BH,AH               ;Put attribute in right place

            MOV     AH,6                ;Scroll window up
            MOV     AL,0                ;Scroll full screen
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


; The following is the transient portion of the TSR.  It is discarded
; after the startup procedure takes place

Hookin      PROC
            POP     AX                  ;Throw away the return address

            MOV     AL,IntUse           ;Get keyboard interrupt
            MOV     AH,35h
            INT     21h
            MOV     AX,ES
            ADD     AX,BX               ;See if all zero
            CMP     AX,0
            JE      AllOK               ;Nothing there, continue
            MOV     SI,OFFSET ErrMsg    ;Point to error message
            CALL    PrtString
            MOV     AH,4Ch              ;Terminate with code
            MOV     AL,1
            INT     21h

AllOK:      MOV     DX,OFFSET NewInt    ;New offset address
            MOV     AL,IntUse           ;Redirect this vector
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