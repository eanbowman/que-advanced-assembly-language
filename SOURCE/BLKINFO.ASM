Page 60,132

Comment |
******************************************************************

File:       BLKINFO.ASM
Author:     Allen L. Wyatt
Date:       7/18/92
Assembler:  MASM 6.0

Purpose:    Using IOCTL functions, discover and display information
            about a block device

Format:     BLKINFO

******************************************************************|

            .MODEL  small
            .STACK                      ;Default 1Kb stack is OK
            .DATA
Drive       DB      00

NeedDrive   DB      'You must supply a valid drive name',0
EMsg1       DB      'Could not use IOCTL function 0D60h',0
EMsg2       DB      'Could not use IOCTL function 0Eh',0

OneDrive    DB      'There is only one logical drive assigned to this device',13,10,0
LastDrive   DB      'This drive was last referred to as drive '
CRLF        DB      13,10,0

DriveParams EQU     THIS BYTE
SpecialFunc DB      00
DeviceType  DB      00
DeviceAttr  DW      0000
Cylinders   DW      0000
MediaType   DB      00

BytesSect   DW      0000
SectClust   DB      00
ResvSect    DW      0000
NumFATs     DB      00
RootDir     DW      0000
NumSect     DW      0000
MediaID     DB      00
SectFAT     DW      0000
SectTrack   DW      0000
NumHeads    DW      0000
NumHidden   DD      00000000
NumHuge     DD      00000000
Unused      DB      7 DUP (0)

TrackLayout DW      162 DUP (0)         ;Allow for up to 80 sectors per track

TopMsg      DB      'Information derived with IOCTL function 0D60h:',13,10,13,10,0

DTTable     DW      0000h
            DW      OFFSET DT00
            DW      0001h
            DW      OFFSET DT01
            DW      0002h
            DW      OFFSET DT02
            DW      0003h
            DW      OFFSET DT03
            DW      0004h
            DW      OFFSET DT04
            DW      0005h
            DW      OFFSET DT05
            DW      0006h
            DW      OFFSET DT06
            DW      0007h
            DW      OFFSET DT07
            DW      0008h
            DW      OFFSET DT08
            DW      0009h
            DW      OFFSET DT09
            DW      0FFFFh
            DW      OFFSET DTUN

DT00        DB      ':  320K or 360K 5.25" disk',13,10,0
DT01        DB      ':  1.2M 5.25" disk',13,10,0
DT02        DB      ':  720K 3.5" disk',13,10,0
DT03        DB      ':  Single density 8" disk',13,10,0
DT04        DB      ':  Double density 8" disk',13,10,0
DT05        DB      ':  Fixed disk',13,10,0
DT06        DB      ':  Tape drive',13,10,0
DT07        DB      ':  1.44M 3.5" disk',13,10,0
DT08        DB      ':  2.88M 3.5" disk',13,10,0
DT09        DB      ':  Other block device',13,10,0
DTUN        DB      ':  Unknown device type code',13,10,0

MTTable     DW      0001h
            DW      OFFSET MT00
            DW      0002h
            DW      OFFSET MT01
            DW      0FFFFh
            DW      OFFSET MTUN

MT00        DB      ':  Drive accepts one type of media only',13,10,0
MT01        DB      ':  Drive accepts multiple media types',13,10,0
MTUN        DB      ':  Unknown media type',13,10,0

IDTable     DW      00F0h
            DW      OFFSET IDF0
            DW      00F8h
            DW      OFFSET IDF8
            DW      00F9h
            DW      OFFSET IDF9
            DW      00FAh
            DW      OFFSET IDFA
            DW      00FBh
            DW      OFFSET IDFB
            DW      00FCh
            DW      OFFSET IDFC
            DW      00FDh
            DW      OFFSET IDFD
            DW      00FEh
            DW      OFFSET IDFE
            DW      00FFh
            DW      OFFSET IDFF
            DW      0FFFFh
            DW      OFFSET IDUN

IDF0        DB      ':  1.44M or 2.88M 3.5" disk, 1.2M 5.25" disk, or other',13,10,0
IDF8        DB      ':  Fixed disk',13,10,0
IDF9        DB      ':  720K 3.5" disk or 1.2M 5.25" disk',13,10,0
IDFA        DB      ':  320K 5.25" disk',13,10,0
IDFB        DB      ':  640K 3.5" disk',13,10,0
IDFC        DB      ':  180K 5.25" disk',13,10,0
IDFD        DB      ':  360K 5.25" disk or double-density 8" disk',13,10,0
IDFE        DB      ':  160K 5.25" disk or single-density 8" disk',13,10,0
IDFF        DB      ':  320K 5.25" disk',13,10,0
IDUN        DB      ':  Unknown media ID',13,10,0

MsgDT       DB      'Device type code ',0
MsgDA1      DB      'Drive supports removeable media',13,10,0
MsgDA2      DB      'Drive does not support removeable media',13,10,0
MsgDA3      DB      'Drive does not support change line status',13,10,0
MsgDA4      DB      'Drive supports change line status',13,10,0
MsgNC       DB      'Number of cylinders:  ',0
MsgMT       DB      'Media type code ',0
MsgBS       DB      'Bytes per sector:  ',0
MsgSC       DB      'Sectors per cluster:  ',0
MsgRS       DB      'Reserved sectors:  ',0
MsgFA       DB      'Number of FATs:  ',0
MsgRD       DB      'Maximum root directory entries:  ',0
MsgTS       DB      'Total sectors:  ',0
MsgID       DB      'Media ID type ',0
MsgSF       DB      'Sectors per FAT:  ',0
MsgST       DB      'Sectors per track:  ',0
MsgHD       DB      'Number of heads:  ',0
MsgHS       DB      'Hidden sectors:  ',0

            .CODE
            .STARTUP
BlkInfo     PROC

            CALL    GetDrive            ;Get drive from command tail
            JNC     GetInfo
            MOV     SI,OFFSET NeedDrive ;Error message
            JMP     ErrCommon           ;And exit early

GetInfo:    MOV     SpecialFunc,1       ;Want for current BPB
            MOV     AH,44h              ;IOCTL
            MOV     AL,0Dh              ;Generic block I/O
            MOV     BL,Drive
            MOV     CH,08h              ;Disk drive
            MOV     CL,60h              ;Get device parameters
            MOV     DX,OFFSET DriveParams
            INT     21h
            JC      Error1

            CALL    Cls
            MOV     SI,OFFSET TopMsg
            CALL    PrtString
            MOV     SI,OFFSET MsgDT
            CALL    PrtString
            MOV     DX,0
            MOV     AH,0
            MOV     AL,DeviceType
            CALL    PrtDec
            MOV     BX,OFFSET DTTable
            CALL    PrtTable            ;Go print from table

            MOV     SI,OFFSET MsgMT
            CALL    PrtString
            MOV     AL,MediaType
            CALL    PrtDec
            MOV     BX,OFFSET MTTable
            CALL    PrtTable            ;Go print from table

            MOV     SI,OFFSET MsgID
            CALL    PrtString
            MOV     AL,MediaID
            CALL    PrtDec
            MOV     BX,OFFSET IDTable
            CALL    PrtTable            ;Go print from table

            MOV     SI,OFFSET MsgDA1    ;Assume supprts removeable media
            MOV     AX,DeviceAttr
            TEST    AL,00000001b        ;Is media removeable?
            JZ      PMedia              ;Yes, so go print
            MOV     SI,OFFSET MsgDA2    ;No, does not support it
PMedia:     CALL    PrtString
            MOV     SI,OFFSET MsgDA3    ;Assume disk change line unsupported
            TEST    AL,00000010b        ;Is change line supported?
            JZ      PChange             ;No, so continue
            MOV     SI,OFFSET MsgDA4
PChange:    CALL    PrtString

            MOV     SI,OFFSET MsgHD
            CALL    PrtString
            MOV     AX,NumHeads
            CALL    PrtDec
            MOV     SI,OFFSET CRLF
            CALL    PrtString

            MOV     SI,OFFSET MsgNC
            CALL    PrtString
            MOV     AX,Cylinders
            CALL    PrtDec
            MOV     SI,OFFSET CRLF
            CALL    PrtString

            MOV     SI,OFFSET MsgTS
            CALL    PrtString
            MOV     AX,NumSect          ;Get number of sectors
            CMP     AX,0                ;Is it 0?
            JNE     PSect               ;No, so print
            MOV     AX,WORD PTR NumHuge ;Yes, so get huge sectors
            MOV     DX,WORD PTR NumHuge[2]
PSect:      CALL    PrtDec
            MOV     SI,OFFSET CRLF
            CALL    PrtString

            MOV     SI,OFFSET MsgBS
            CALL    PrtString
            MOV     DX,0
            MOV     AX,BytesSect
            CALL    PrtDec
            MOV     SI,OFFSET CRLF
            CALL    PrtString

            MOV     SI,OFFSET MsgSC
            CALL    PrtString
            MOV     AH,0
            MOV     AL,SectClust
            CALL    PrtDec
            MOV     SI,OFFSET CRLF
            CALL    PrtString

            MOV     SI,OFFSET MsgST
            CALL    PrtString
            MOV     AX,SectTrack
            CALL    PrtDec
            MOV     SI,OFFSET CRLF
            CALL    PrtString

            MOV     SI,OFFSET MsgRS
            CALL    PrtString
            MOV     AX,ResvSect
            CALL    PrtDec
            MOV     SI,OFFSET CRLF
            CALL    PrtString

            MOV     SI,OFFSET MsgHS
            CALL    PrtString
            MOV     AX,WORD PTR NumHidden
            MOV     DX,WORD PTR NumHidden[2]
            CALL    PrtDec
            MOV     SI,OFFSET CRLF
            CALL    PrtString
            CALL    PrtString           ;Extra blank line

            MOV     SI,OFFSET MsgFA
            CALL    PrtString
            MOV     DX,0
            MOV     AH,0
            MOV     AL,NumFATs
            CALL    PrtDec
            MOV     SI,OFFSET CRLF
            CALL    PrtString

            MOV     SI,OFFSET MsgSF
            CALL    PrtString
            MOV     AX,SectFAT
            CALL    PrtDec
            MOV     SI,OFFSET CRLF
            CALL    PrtString
            CALL    PrtString           ;Extra blank line

            MOV     SI,OFFSET MsgRD
            CALL    PrtString
            MOV     AX,RootDir
            CALL    PrtDec
            MOV     SI,OFFSET CRLF
            CALL    PrtString

            MOV     AH,44h              ;IOCTL
            MOV     AL,0Eh              ;Get logical device map
            MOV     BL,Drive
            INT     21h
            JC      Error2
            CMP     AL,0
            JNE     Block3
            MOV     SI,OFFSET OneDrive
            CALL    PrtString
            JMP     Block4
Block3:     MOV     SI,OFFSET LastDrive
            CALL    PrtString
            MOV     DL,AL
            ADD     DL,'@'              ;Make it printable ASCII
            MOV     AH,02h              ;Output a character
            INT     21h
            MOV     SI,OFFSET CRLF
            CALL    PrtString
Block4:     JMP     AllDone

Error1:     MOV     SI,OFFSET EMsg1
            JMP     ErrCommon
Error2:     MOV     SI,OFFSET EMsg2
ErrCommon:  CALL    PrtString

AllDone:    .EXIT
BlkInfo     ENDP

; Transfers a drive name from the command tail, converting it into a
; drive number.  Assumes ES points to PSP segment.  Returns with
; carry set if there was no command tail or the drive entered was not
; alphabetic.

GetDrive    PROC    USES AX CX SI
            MOV     SI,80h          ;Point to start of command tail
            MOV     CH,0
            MOV     CL,ES:[SI]      ;Get length of command tail
            JCXZ    X8              ;No command tail, exit with error

            INC     SI              ;Point to first character
X1:         MOV     AL,ES:[SI]      ;Get character
            INC     SI              ;Point to next character
            CMP     AL,' '          ;Was it a space?
            JNE     X4              ;No, so assume have drive
            LOOP    X1              ;Keep going to the end
X4:         AND     AL,01011111b    ;Convert to upper case
            CMP     AL,'A'          ;Check if in range
            JB      X8
            CMP     AL,'Z'
            JA      X8
            AND     AL,00011111b    ;Convert to drive code
            MOV     Drive,AL        ;And store for later
            CLC
            JNC     X9

X8:         STC
X9:         RET
GetDrive    ENDP

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

; The following routine prints a message from an indexed table
; Enter with AX set to the control value to match and BX set to
; the offset address of the table

PrtTable    PROC    USES BX DX SI
PTLoop:     MOV     DX,[BX]             ;Get control word
            INC     BX                  ;Point to message
            INC     BX
            CMP     DX,0FFFFh           ;End of table?
            JE      PrintMsg            ;Yes, so force printing of message
            CMP     AX,DX               ;Proper code?
            JE      PrintMsg            ;Yes
            INC     BX                  ;Point past message
            INC     BX
            JMP     PTLoop              ;Do it again
PrintMsg:   MOV     SI,[BX]             ;Get pointer
            CALL    PrtString           ;Print it
            RET
PrtTable    ENDP

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

; The following routine prints the value in DX:AX as a decimal number
; Will accept numbers up to 655,359,999.  Anything larger will not print.

            .DATA
Temp        DW      0000

            .CODE
PrtDec      PROC    USES AX BX CX DX

            MOV     CX,0FFFFh           ;Ending flag
            PUSH    CX

PD0:        MOV     CX,10000            ;Divide by 10,000
            DIV     CX
            MOV     Temp,AX             ;Store whole portion
            MOV     BX,0                ;Count for this iteration

            MOV     AX,DX
            MOV     CX,10
PD1:        MOV     DX,0
            DIV     CX                  ;Divide by 10
            ADD     DL,30h              ;Convert to ASCII
            PUSH    DX                  ;Store remainder
            INC     BX                  ;Cycle count
            CMP     AX,0                ;Are we done?
            JNE     PD1                 ;No, so continue
            MOV     DX,0
            MOV     AX,Temp             ;Get back part above 10,000
            CMP     AX,0
            JE      PD3
            MOV     CX,'0'
PD2:        CMP     BX,4                ;Did we push 4 numbers?
            JE      PD0                 ;Yes, continue
            PUSH    CX                  ;No, so push it
            INC     BX                  ;Push counter
            JMP     PD2

PD3:        POP     DX                  ;Character is now in DL
            CMP     DX,0FFFFh           ;Is it the ending flag?
            JE      PD4                 ;Yes, so continue
            MOV     AH,02h              ;Output a character
            INT     21h
            JMP     PD3                 ;Keep doing it

PD4:        RET
PrtDec      ENDP

            END
