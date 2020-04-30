Page 60,132

Comment |
******************************************************************

File:       CRITTEST.ASM
Author:     Allen L. Wyatt
Date:       7/3/92
Assembler:  MASM 6.0

Purpose:    A test program for the critical error handler.  Run
            this program with no disk in drive A:.  The program
            will attempt to open a file on drive A:.  When it
            cannot (there is no disk there), a critical error
            is generated.  Then you can insert a disk and the
            program will continue.

Format:     CRITTEST

******************************************************************|

            .MODEL  small
            .STACK                      ;Default 1Kb stack is OK
            .DATA

Filename    DB      'A:\TEST.DAT',0
Message     DB      'This is a test file',13,10
            DB      'created by CRITTEST.EXE.',13,10,13,10
            DB      'It can safely be deleted.'
CRLF        DB      13,10,0
Status      DB      'There was an error and the file could',13,10
            DB      'not be created.  Upon trying, the DOS',13,10
            DB      'function returned an error code of ',0

            .CODE
            .STARTUP
CritTest    PROC
            MOV     AL,24h              ;Resetting interrupt handler
            PUSH    DS
            PUSH    CS
            POP     DS
            MOV     DX,OFFSET CritErr
            MOV     AH,25h              ;Set interrupt vector
            INT     21h
            POP     DS

            MOV     AH,3Ch              ;Create/truncate file
            MOV     CX,0                ;Normal file
            MOV     DX,OFFSET Filename  ;Point to name
            INT     21h                 ;This should generate error
            JNC     Continue            ;No error, continue
            MOV     SI,OFFSET Status
            CALL    PrtString
            CALL    PrtDec
            MOV     SI,OFFSET CRLF
            CALL    PrtString
            JMP     AllDone

Continue:   MOV     BX,AX               ;Put handle in proper place
            MOV     AH,40h              ;Write to file
            MOV     CX,76               ;Number of bytes
            MOV     DX,OFFSET Message
            INT     21h
            MOV     AH,3Eh              ;Close file (handle in BX)
            INT     21h

AllDone:    .EXIT
CritTest    ENDP


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


; Critical error handler (from the file CRITERR.ASM)

CritErr     PROC    FAR
            PUSH    BX
            PUSH    CX
            PUSH    DX
            PUSH    BP
            PUSH    DI
            PUSH    DS
            PUSH    ES

            MOV     BX,CS               ;Set up addressing for data segment
            MOV     DS,BX

            PUSH    AX                  ;Save current value
            MOV     AH,03h              ;Get cursor position
            MOV     BH,0                ;Assume page 0
            INT     10h
            MOV     Coord,DX            ;Save cursor position
            MOV     AH,06h              ;Scroll window up
            MOV     AL,2                ;by 2 lines
            MOV     BH,07h              ;Attribute to use
            MOV     CX,1700h            ;Upper left corner (23:00)
            MOV     DX,184Fh            ;Lower right corner (24:79)
            INT     10h
            MOV     AH,02h              ;Set cursor position
            MOV     BH,0                ;Assume page 0
            MOV     DX,1700h            ;Row & column (23:00)
            INT     10h
            POP     AX                  ;Get error info back

            MOV     BL,AH               ;Set up valid exit code info
            MOV     CL,3
            SHR     BL,CL
            AND     BL,00000001b
            MOV     TermOK,BL
            MOV     BL,AH
            MOV     CL,4
            SHR     BL,CL
            AND     BL,00000001b
            MOV     RetryOK,BL
            MOV     BL,AH
            MOV     CL,5
            SHR     BL,CL
            AND     BL,00000001b
            MOV     IgnoreOK,BL

            TEST    AH,10000000b        ;Test bit 7
            JZ      BlockDev            ;Happened on a block device
            MOV     ES,BP
            MOV     BX,ES:[SI+4]        ;Get attribute from header
            TEST    BH,10000000b        ;Test bit 15
            JZ      BlockDev            ;Happened in memory FAT

; By this point, it has been determined that the error occurred on a
; character device

            MOV     AH,09h              ;Display string
            MOV     DX,OFFSET CharMsg1
            INT     21h
            ADD     SI,0Ah              ;Point to device name
            MOV     CX,8                ;Maximum number of characters
NameLoop:   MOV     DL,ES:[SI]          ;Get character
            INC     SI                  ;Point to next one
            CMP     DL,' '              ;Is it a space?
            JE      EndOfName           ;Yes, so end name
            MOV     AH,02h              ;Display a character
            INT     21h
            LOOP    NameLoop
EndOfName:  MOV     AH,09h              ;Display string
            MOV     DX,OFFSET CharMsg2
            INT     21h
            JMP     Common

BlockDev:   ADD     AL,'A'              ;Make it ASCII
            MOV     Drive,AL            ;Put in string
            MOV     AH,09h              ;Display string
            MOV     DX,OFFSET BlockMsg
            INT     21h

Common:     MOV     SI,DI
            SHL     SI,1                ;Multiply by 2
            ADD     SI,OFFSET ErrTable
            MOV     DX,[SI]             ;Get address from error table
            MOV     AH,09h              ;Display string
            INT     21h

            CMP     DI,01h              ;Unknown unit?
            JE      NonRecover          ;Yes, so exit
            CMP     DI,03h              ;Unknown command?
            JE      NonRecover          ;Yes, so exit
            CMP     DI,04h              ;Bad CRC?
            JE      NonRecover          ;Yes, so exit
            CMP     DI,05h              ;Bad request structure length?
            JE      NonRecover          ;Yes, so exit
            CMP     DI,06h              ;Seek error?
            JE      NonRecover          ;Yes, so exit
            CMP     DI,07h              ;Unknown media?
            JE      NonRecover          ;Yes, so exit
            CMP     DI,08h              ;Sector not found?
            JE      NonRecover          ;Yes, so exit
            CMP     DI,0Ah              ;Write fault?
            JE      NonRecover          ;Yes, so exit
            CMP     DI,0Bh              ;Read fault?
            JE      NonRecover          ;Yes, so exit
            CMP     DI,0Ch              ;Was it a general failure?
            JE      NonRecover          ;Yes, so exit

            MOV     AH,02h              ;Set cursor position
            MOV     BH,0                ;Assume page 0
            MOV     DX,1800h            ;Row & column (24:00)
            INT     10h
            MOV     AH,09h              ;Display string
            MOV     DX,OFFSET Prompt
            INT     21h
            MOV     AH,01h              ;Character input with echo
            INT     21h

            PUSH    AX                  ;Save the keypress
            MOV     AH,06h              ;Scroll window up
            MOV     AL,2                ;by 2 lines
            MOV     BH,07h              ;Attribute to use
            MOV     CX,1700h            ;Upper left corner (23:00)
            MOV     DX,184Fh            ;Lower right corner (24:79)
            INT     10h
            MOV     AH,02h              ;Set cursor position
            MOV     BH,0                ;Assume page 0
            MOV     DX,Coord            ;Original row & column
            INT     10h
            POP     AX                  ;Get the keypress back

            CMP     AL,'X'              ;Was X pressed?
            JE      NonRecover          ;Yes, so exit with error
            CMP     AL,'x'              ;Was x pressed?
            JE      NonRecover          ;Yes, so exit with error
            MOV     AL,01h              ;Exit with retry
            CMP     RetryOK,1           ;Is it OK to retry the function?
            JE      ExitCrit            ;Yes, so continue

NonRecover: MOV     AL,03h              ;Terminate function (let parent
                                        ;     program handle the error)
            CMP     TermOK,1            ;Is it OK to terminate the function?
            JE      ExitCrit            ;Yes, so continue
            MOV     AL,02h              ;No, force termination of program

ExitCrit:   POP     ES
            POP     DS
            POP     DI
            POP     BP
            POP     DX
            POP     CX
            POP     BX
            IRET

TermOK      DB      00
RetryOK     DB      00
IgnoreOK    DB      00
Coord       DW      0000
CharMsg1    DB      'Error with the $'
CharMsg2    DB      ' device - $'
BlockMsg    DB      'Error with drive '
Drive       DB      '?: - $'
Prompt      DB      'Press X to stop trying, or correct and press another key to try again...$'

ErrTable    DW      OFFSET Err00
            DW      OFFSET Err01
            DW      OFFSET Err02
            DW      OFFSET Err03
            DW      OFFSET Err04
            DW      OFFSET Err05
            DW      OFFSET Err06
            DW      OFFSET Err07
            DW      OFFSET Err08
            DW      OFFSET Err09
            DW      OFFSET Err0A
            DW      OFFSET Err0B
            DW      OFFSET Err0C

Err00       DB      'disk is write-protected$'
Err01       DB      'unknown unit$'
Err02       DB      'drive not ready$'
Err03       DB      'unknown command$'
Err04       DB      'CRC error$'
Err05       DB      'bad drive-request structure length$'
Err06       DB      'seek error$'
Err07       DB      'unknown media type$'
Err08       DB      'sector not found$'
Err09       DB      'out of paper$'
Err0A       DB      'error while writing$'
Err0B       DB      'error while reading$'
Err0C       DB      'general failure$'

CritErr     ENDP

            END
