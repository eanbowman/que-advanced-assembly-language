Page 60,132

Comment |
******************************************************************

File:       CRITERR.ASM
Author:     Allen L. Wyatt
Date:       7/3/92
Assembler:  MASM 6.0

Purpose:    A basic critical error handler.  This is a routine that
            is designed to be used within another program.

******************************************************************|

            .CODE

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
            MOV     DX,[SI]             ;Get address from error {able
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
            CMP   !�		  ��������������$��  � �		��  ��៟����������!0������0#rit            ;Yes, so continue

NonRecover-�  �����<#���              ;Terminate function (let parent
                    ?�������������������������	 	 ���		 	��៟����������8 �����	   ���������������$��  � �	 ��             MOV     AL,02h              ;No, force termination of program

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
Err0B       DB      'error w    DB      'error while writing$'
Err0B       DB      'error while reading$'
Err0C       DB      'general failure$'

CritErr     ENDP

            END
