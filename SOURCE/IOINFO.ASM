Page 60,132

Comment |
******************************************************************

File:       IOINFO.ASM
Author:     Allen L. Wyatt
Date:       7/18/92
Assembler:  MASM 6.0

Purpose:    Using IOCTL functions, discover and display information
            about a character device

Format:     IOINFO

******************************************************************|

            .MODEL  small
            .STACK                      ;Default 1Kb stack is OK
            .DATA
WorkDir     DB      129 DUP(0)
Handle      DW      0000

NeedFile    DB      'You must supply a file or device name',0
EMsg1       DB      'Could not open device',0
EMsg2       DB      'Could not use IOCTL function 0',0

FileMsg1    DB      'You have specified a file on drive ',0
FileMsg2    DB      13,10,'The file has ',0
FileMsg3    DB      'not ',0
FileMsg4    DB      'been written',13,10,0

DeviceMsg   DB      'The following information about this device was',13,10
            DB      'returned by IOCTL function 00h:',13,10,0
StdOYes     DB      '   This is a standard input device',13,10,0
StdIYes     DB      '   This is a standard output device',13,10,0
NulYes      DB      '   This is a NUL device',13,10,0
ClockYes    DB      '   This is a clock device',13,10,0
Binary      DB      '   This device is operating in raw (binary) mode',13,10,0
ASCII       DB      '   This device is operating in cooked (ASCII) mode',13,10,0
I28Yes      DB      '   This device supports Interrupt 28h',13,10,0
I28No       DB      '   This device does not support Interrupt 28h',13,10,0
EOFNo       DB      '   EOF is not returned when device is read',13,10,0
EOFYes      DB      '   EOF is returned when device is read',13,10,0
F23Yes      DB      '   IOCTL functions 02h and 03h are supported',13,10,0
F23No       DB      '   IOCTL functions 02h and 03h are not supported',13,10,0

DevTable    DB      01                  ;Flag to test bit
            DW      OFFSET StdOYes
            DW      0000
            DB      01                  ;Flag to test bit
            DW      OFFSET StdIYes
            DW      0000
            DB      01                  ;Flag to test bit
            DW      OFFSET NulYes
            DW      0000
            DB      01                  ;Flag to test bit
            DW      OFFSET ClockYes
            DW      0000
            DB      01                  ;Flag to test bit
            DW      OFFSET I28Yes
            DW      OFFSET I28No
            DB      01                  ;Flag to test bit
            DW      OFFSET Binary
            DW      OFFSET ASCII
            DB      01                  ;Flag to test bit
            DW      OFFSET EOFNo
            DW      OFFSET EOFYes
            DB      00                  ;No need to test
            DB      00                  ;Reserved bit, do not test
            DB      00                  ;Reserved bit, do not test
            DB      00                  ;Reserved bit, do not test
            DB      00                  ;Reserved bit, do not test
            DB      00                  ;Reserved bit, do not test
            DB      00                  ;Reserved bit, do not test
            DB      01                  ;Flag to test bit
            DW      OFFSET F23Yes
            DW      OFFSET F23No
            DB      00                  ;Reserved bit, do not test

            .CODE
            .STARTUP
IOInfo      PROC

            CALL    Xfer                ;Move command tail into work area
            JNC     OpenFile
            MOV     SI,OFFSET NeedFile  ;Error message
            JMP     ErrCommon           ;And exit early

OpenFile:   MOV     AH,3Dh              ;Open file
            MOV     AL,00000010b        ;Access mode
            MOV     DX,OFFSET WorkDir
            INT     21h
            JC      Error1
            MOV     Handle,AX           ;Store the handle

            MOV     AH,44h              ;IOCTL
            MOV     AL,0                ;Get device info
            MOV     BX,Handle
            INT     21h
            JC      Error2

            TEST    DL,10000000b        ;See if it is a file
            JNZ     DoDevice            ;Indicates it is a device

            MOV     SI,OFFSET FileMsg1
            CALL    PrtString
            PUSH    DX                  ;Save info word for a moment
            AND     DL,00111111b        ;Want only drive number
            ADD     DL,'A'              ;Make it ASCII
            MOV     AH,02h              ;Output a character
            INT     21h
            MOV     SI,OFFSET FileMsg2
            CALL    PrtString
            POP     DX                  ;Get back info word
            TEST    DL,01000000b        ;Test if written to
            JZ      File2               ;Nope, not written
            MOV     SI,OFFSET FileMsg3
            CALL    PrtString
File2:      MOV     SI,OFFSET FileMsg4
            CALL    PrtString
            JMP     CloseFile

DoDevice:   MOV     CX,16               ;Testing 16 bits
            MOV     AX,DX               ;Move word to test
            MOV     BX,OFFSET DevTable  ;Point to start of table

            MOV     SI,OFFSET DeviceMsg
            CALL    PrtString

TestLoop:   CMP     BYTE PTR DS:[BX],0  ;If 0, then skip
            JE      TL8
            INC     BX                  ;Point to first message
            CMP     WORD PTR DS:[BX],0  ;Is it a null message?
            JE      TL2                 ;Yes, so continue
            TEST    AX,01h
            JZ      TL2                 ;Bit is not set, don't do message
            MOV     SI,[BX]
            CALL    PrtString           ;Go print the message
TL2:        INC     BX                  ;Point to the next message
            INC     BX
            CMP     WORD PTR DS:[BX],0  ;Is it a null message?
            JE      TL3                 ;Yes, so skip
            TEST    AX,01h
            JNZ     TL3                 ;Bit is set, don't do message
            MOV     SI,[BX]
            CALL    PrtString           ;Go print the message
TL3:        INC     BX                  ;Point to start of next record
TL8:        INC     BX
TL9:        SHR     AX,1                ;Move over one bit
            LOOP    TestLoop            ;And do it again

CloseFile:  MOV     AH,3Eh              ;Close file
            MOV     BX,Handle
            INT     21h
            JMP     AllDone

Error1:     MOV     SI,OFFSET EMsg1
            JMP     ErrCommon
Error2:     MOV     AH,3Eh              ;Close file
            MOV     BX,Handle
            INT     21h
            MOV     SI,OFFSET EMsg2
ErrCommon:  CALL    PrtString

AllDone:    .EXIT
IOInfo      ENDP

; Transfers the command tail into the work file area, converting it
; into an ASCIIZ string.  Assumes ES points to PSP segment.  Returns
; with carry set if there was no command tail.

Xfer        PROC    USES AX CX SI DI ES DS
            PUSH    ES              ;Swap ES and DS
            PUSH    DS
            POP     ES
            POP     DS
            MOV     SI,80h          ;Point to start of command tail
            MOV     CH,0
            MOV     CL,[SI]         ;Get length of command tail
            JCXZ    X8              ;No command tail, exit with error

            INC     SI              ;Point to first character
            MOV     DI,OFFSET ES:WorkDir
X1:         LODSB
            CMP     AL,' '          ;Was it a space?
            JE      X4              ;Yes, so skip it
            STOSB                   ;Store a byte
X4:         LOOP    X1              ;Keep going to the end
            MOV     AL,0
            STOSB                   ;Make sure NUL at end of path
            CLC
            JNC     X9

X8:         STC
X9:         RET
Xfer        ENDP

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