Page 60,132

Comment |
******************************************************************

File:       IOWHERE.ASM
Author:     Allen L. Wyatt
Date:       7/18/92
Assembler:  MASM 6.0

Purpose:    Allow the user to decide where the output of a text
            string will be sent.

Format:     IOWHERE

******************************************************************|

            .MODEL  small
            .STACK                      ;Default 1Kb stack is OK
            .DATA
Handle      DW      0000

EMsg1       DB      'Could not open device',0
EMsg2       DB      'Error while checking if ready for output',0
EMsg3       DB      'Timeout error',0

OutTable    DW      OFFSET Screen
            DW      OFFSET Printer
            DW      OFFSET FileName

Screen      DB      'CON',0
Printer     DB      'PRN',0
FileName    DB      'TEST.OUT',0

TestOut     DB      'This is a test string created with '
            DB      'the program IOWHERE.EXE.  For more ',13,10
            DB      'information, please refer to the '
            DB      'book Advanced Assembly Language,',13,10
            DB      'by Allen L. Wyatt'
CRLF        DB      13,10,0

Prompt      DB      'Would you like the test string sent to:',13,10
            DB      '    1. The screen',13,10
            DB      '    2. The printer (PRN)',13,10
            DB      '    3. The file TEST.OUT',13,10,13,10
            DB      'Your choice: ',0

            .CODE
            .STARTUP
IOWhere     PROC

            CALL    Cls                 ;Clear the screen
            MOV     SI,OFFSET Prompt    ;Point to question
            CALL    PrtString
InLoop:     MOV     AH,0                ;Read keyboard character
            INT     16h
            CMP     AL,'1'              ;Less than minimum choice?
            JB      InLoop              ;Yes, so keep asking
            CMP     AL,'3'              ;Greater than maximum?
            JA      InLoop              ;Yes, so keep asking

            MOV     DL,AL               ;Print character
            MOV     AH,02h              ;Output a character
            INT     21h
            MOV     SI,OFFSET CRLF
            CALL    PrtString

            MOV     BH,0
            MOV     BL,AL
            AND     BL,00001111b        ;Convert to binary value
            DEC     BX                  ;Make it a zero offset
            SHL     BX,1                ;And multiply by 2
            ADD     BX,OFFSET OutTable  ;Point to proper table entry

            MOV     AH,6Ch              ;Extended file open
            MOV     AL,0
            MOV     SI,DS:[BX]          ;Point to name
            MOV     BX,02h              ;Open mode
            MOV     CX,0                ;Normal file
            MOV     DX,11h              ;Open or create
            INT     21h
            JC      Error1
            MOV     Handle,AX           ;Store the handle

            MOV     SI,OFFSET TestOut   ;Point to start of output data
OutLoop:    CMP     BYTE PTR DS:[SI],0  ;End of string?
            JE      CloseFile           ;Yes, so close device or file
            MOV     CX,20h              ;Number of times to try output
WaitLoop:   MOV     AH,44h              ;IOCTL
            MOV     AL,07h              ;Test if ready for output
            MOV     BX,Handle
            INT     21h
            JC      Error2
            CMP     AL,0FFh             ;Ready for output?
            JE      CharOut             ;Yes, so send character
            LOOP    WaitLoop            ;No, so try another time
            JMP     Error3              ;Exit with error

CharOut:    MOV     AH,40h              ;Write file
            MOV     BX,Handle
            MOV     DX,SI               ;Pointer for info to write
            MOV     CX,1                ;Only 1 byte
            INT     21h
            INC     SI                  ;Point to next character
            JMP     OutLoop

CloseFile:  MOV     AH,3Eh              ;Close file
            MOV     BX,Handle
            INT     21h
            JMP     AllDone

Error1:     MOV     SI,OFFSET EMsg1
            JMP     ErrPrt
Error2:     MOV     SI,OFFSET EMsg2
            JMP     ErrCommon
Error3:     MOV     SI,OFFSET EMsg3
ErrCommon:  MOV     AH,3Eh              ;Close file
            MOV     BX,Handle
            INT     21h
ErrPrt:     CALL    PrtString

AllDone:    .EXIT
IOWhere     ENDP

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

; The following routine prints the ASCIIZ string pointed to by DS:SI
; DOS routines for character output are used

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

            END
