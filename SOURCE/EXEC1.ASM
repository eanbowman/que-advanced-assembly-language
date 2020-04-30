Page 60,132

Comment |
******************************************************************

File:       EXEC1.ASM
Author:     Allen L. Wyatt
Date:       6/6/92
Assembler:  MASM 6.0

Purpose:    Demonstrate how to use the EXEC function to spawn a COM
            or EXE child.  Program uses EXEC to run TREE.COM, a DOS
            utility.

Format:     EXEC1

******************************************************************|

            .MODEL  small
            .STACK                      ;Default 1Kb stack is OK
            .DATA

Path        DB      'C:\DOS\TREE.COM',0

Parms       DW      0                   ;Parent environment block is OK
            DW      OFFSET CmdTail      ;Command tail address
            DW      SEG CmdTail
            DW      0,0                 ;FCB pointers don't matter
            DW      0,0                 ;    for this example

CmdTail     DB      3                   ;Length of command tail
            DB      'C:\',13            ;Actual command tail

SaveSS      DW      0                   ;Temporary storage areas
SaveSP      DW      0
Error       DW      0

Message1    DB      'Press any key to enter child program...$'
Message2    DB      13,10,'Back from child program',13,10,'$'
Message3    DB      'Ending parent program'
CRLF        DB      13,10,'$'
ErrMsg      DB      'Error during EXEC function: $'

ErrorTable  DW      OFFSET ErrorX
            DW      OFFSET Error1
            DW      OFFSET Error2
            DW      OFFSET Error3
            DW      OFFSET Error4
            DW      OFFSET Error5
            DW      OFFSET ErrorX
            DW      OFFSET ErrorX
            DW      OFFSET Error8
            DW      OFFSET ErrorX
            DW      OFFSET ErrorA
            DW      OFFSET ErrorB

Error1      DB      ' (invalid function)$'
Error2      DB      ' (file not found)$'
Error3      DB      ' (path not found)$'
Error4      DB      ' (too many open files)$'
Error5      DB      ' (access denied)$'
Error8      DB      ' (not enough memory)$'
ErrorA      DB      ' (bad environment)$'
ErrorB      DB      ' (bad format)$'
ErrorX      DB      ' (unknown error value)$'

            .CODE
            .STARTUP
Exec1       PROC

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

            CALL    Cls                 ;Clear the screen
            MOV     DX,0                ;Set up to print message
            MOV     BH,0                ;Assume page 0
            MOV     AH,2                ;Set cursor position
            INT     10h
            MOV     DX,OFFSET Message1  ;Point to starting message
            MOV     AH,9                ;Display a string using DOS
            INT     21h
            MOV     AH,0                ;Read keyboard character
            INT     16h
            MOV     DX,OFFSET CRLF      ;Go to next line
            MOV     AH,9                ;Display a string using DOS
            INT     21h

            MOV     Error,0             ;Assume no error will occur
            MOV     AH,4Bh              ;EXEC function
            MOV     AL,0                ;Load and execute
            MOV     DX,OFFSET Path      ;Path name to file to execute
            PUSH    DS
            POP     ES                  ;ES:BX must point to
            MOV     BX,OFFSET Parms     ;   parameter block
            MOV     SaveSS,SS           ;Don't want to loose SP:SS during
            MOV     SaveSP,SP           ;   EXEC call
            INT     21h
            JNC     Back                ;No error, so continue
            MOV     Error,AX            ;Put error value in its place

Back:       MOV     SS,SaveSS           ;Restore SP:SS from saved values
            MOV     SP,SaveSP
            MOV     DX,OFFSET Message2  ;Point to return message
            MOV     AH,9                ;Display a string using DOS
            INT     21h

            CMP     Error,0             ;Was there an error?
            JE      Done                ;No, so exit
            MOV     DX,OFFSET ErrMsg    ;Point to error message
            MOV     AH,9                ;Display a string using DOS
            INT     21h
            MOV     AX,Error            ;Get the value
            CALL    PrtDec              ;Go print it
            MOV     BX,Error            ;Get error value
            SHL     BX,1                ;Multiply by 2
            MOV     DX,ErrorTable[BX]   ;Get the error message
            MOV     AH,9                ;Display a string using DOS
            INT     21h

            MOV     DX,OFFSET CRLF      ;Go to next line
            MOV     AH,9                ;Display a string using DOS
            INT     21h

Done:       MOV     DX,OFFSET Message3  ;Point to exit message
            MOV     AH,9                ;Display a string using DOS
            INT     21h

            .EXIT
Exec1       ENDP


; The following routine clears the screen

Cls         PROC    USES AX BX CX DX
            MOV     AH,6                ;Scroll window up
            MOV     AL,0                ;Scroll full screen
            MOV     BH,7                ;Normal white on black
            MOV     CX,0                ;Upper left corner of screen
            MOV     DH,24               ;Bottom right
            MOV     DL,79
            INT     10h
            RET
Cls         ENDP

; The following routine prints the value in AX as a decimal number

PrtDec      PROC    USES AX CX DX
            MOV     CX,0FFFFh           ;Ending flag
            PUSH    CX
            MOV     CX,10
PD1:        MOV     DX,0
            DIV     CX                  ;Divide by 10
            ADD     DL,30h              ;Convert to ASCII
            PUSH    DX                  ;Store remainder
            CMP     AX,0                ;Are we done?
            JNE     PD1                 ;No, so continue

PD2:        POP     DX                  ;Character is now in DL
            CMP     DX,0FFFFh           ;Is it the ending flag?
            JE      PD3                 ;Yes, so continue
            MOV     AH,02h              ;Output a character
            INT     21h
            JMP     PD2                 ;Keep doing it

PD3:        RET
PrtDec      ENDP

            END
