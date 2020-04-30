Page 60,132

Comment |
******************************************************************

File:       FMT.ASM
Author:     Allen L. Wyatt
Date:       7/26/92
Assembler:  MASM 6.0

Purpose:    Illustrate use of IOCTL functions to format a drive.
            This program will format only drives A: or B:, so there
            is no danger of formatting the hard drive.

Format:     FMT

******************************************************************|

            .MODEL  small
            .STACK                      ;Default 1Kb stack is OK
            .DATA
Drive       DB      00
FormatType  DB      00
CurHead     DB      00
CurCylinder DB      00

ParmLen     EQU     75                  ;Bytes in parm buffers
OrigParms   EQU     THIS BYTE
SFOrig      DB      00
            DB      74 DUP(0)           ;Bulk storage for current settings

NewParms    EQU     THIS BYTE
SpecFuncNew DB      00
DeviceType  DB      00
DeviceAttr  DW      0000
Cylinders   DW      0000
MediaType   DB      00

DiskBPB     EQU     THIS BYTE
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
Unused      DB      6 DUP (0)
TrackLayout DW      18*2+1 DUP (0)      ;Allow for up to 18 sectors per track

FmtParms    EQU     THIS BYTE
FmtParmSF   DB      00
FmtParmHead DW      0000
FmtParmCyl  DW      0000

MIDStruct   EQU     THIS BYTE
InfoLevel   DW      0000
SerialNum   DD      00000000
VolLabel    DB      'Advanced   '
FileSys     DB      'FAT12   '

DiskIO      EQU     THIS BYTE
SectBegin   DW      0000,0000
SectCount   DW      0000
BuffStart   DW      0000,0000

DCTable     DW      OFFSET D360
            DW      OFFSET D120
            DW      OFFSET D720
            DW      OFFSET D144

D360        DW      40                  ;Number of cylinders (tracks)
            DW      512                 ;Bytes per sector
            DB      2                   ;Sectors per cluster
            DW      1                   ;Reserved sectors
            DB      2                   ;Number of FATs
            DW      112                 ;Root directory entries
            DW      40*9*2              ;Total sectors
            DB      0FDh                ;Media descriptor
            DW      2                   ;Sectors per FAT
            DW      9                   ;Sectors per track
            DW      2                   ;Number of heads
            DD      00000000            ;Hidden sectors
            DD      00000000            ;Large sector count

D120        DW      80                  ;Number of cylinders (tracks)
            DW      512                 ;Bytes per sector
            DB      1                   ;Sectors per cluster
            DW      1                   ;Reserved sectors
            DB      2                   ;Number of FATs
            DW      224                 ;Root directory entries
            DW      80*15*2             ;Total sectors
            DB      0F9h                ;Media descriptor
            DW      7                   ;Sectors per FAT
            DW      15                  ;Sectors per track
            DW      2                   ;Number of heads
            DD      00000000            ;Hidden sectors
            DD      00000000            ;Large sector count

D720        DW      80                  ;Number of cylinders (tracks)
            DW      512                 ;Bytes per sector
            DB      2                   ;Sectors per cluster
            DW      1                   ;Reserved sectors
            DB      2                   ;Number of FATs
            DW      112                 ;Root directory entries
            DW      80*9*2              ;Total sectors
            DB      0F9h                ;Media descriptor
            DW      3                   ;Sectors per FAT
            DW      9                   ;Sectors per track
            DW      2                   ;Number of heads
            DD      00000000            ;Hidden sectors
            DD      00000000            ;Large sector count

D144        DW      80                  ;Number of cylinders (tracks)
            DW      512                 ;Bytes per sector
            DB      1                   ;Sectors per cluster
            DW      1                   ;Reserved sectors
            DB      2                   ;Number of FATs
            DW      224                 ;Root directory entries
            DW      80*18*2             ;Total sectors
            DB      0F0h                ;Media descriptor
            DW      9                   ;Sectors per FAT
            DW      18                  ;Sectors per track
            DW      2                   ;Number of heads
            DD      00000000            ;Hidden sectors
            DD      00000000            ;Large sector count

DriveMsg    DB      'Format disk in drive A or B? ',0
DriveRdy    DB      'Ready to format'
DRMsg2      DB      ' disk in drive '
AscDrive    DB      'A:',13,10,0
Insert      DB      'Insert disk to be formatted and press a key',0
CRLF        DB      13,10,0

TypeTable   DW      OFFSET M525
            DW      OFFSET M350

M525        DB      '   1.  360K disk',13,10
            DB      '   2.  1.2M disk',13,10,0

M350        DB      '   1.  720K disk',13,10
            DB      '   2.  1.44M disk',13,10,0

TypeMsg     DB      13,10,'Select type 1 or 2: ',0

FmtMsg      DB      'Formatting ',0

FTTable     DW      OFFSET FT00
            DW      OFFSET FT01
            DW      OFFSET FT02
            DW      OFFSET FT03

FT00        DB      '360K 5.25"',0
FT01        DB      '1.2M 5.25"',0
FT02        DB      '720K 3.5"',0
FT03        DB      '1.44M 3.5"',0

TrackMsg1   DB      13,'Formatting track ',0
TrackMsg2   DB      ' of ',0
FinishMsg   DB      13,'Format completed           ',13,10,0

EMsg1       DB      'Could not determine drive parameters',13,10,0
EMsg2       DB      'Could not work with this device type',13,10,0
EMsg3       DB      'Could not set proper parameters',13,10,0
EMsg4       DB      13,10,'Error formatting track',13,10,0

            .CODE
            .STARTUP
Fmt         PROC

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

; Check if running on system where A/B is one drive

            CALL    Cls

            MOV     AH,44h              ;IOCTL
            MOV     AL,0Eh              ;Get logical device map
            MOV     BL,1                ;Drive A:
            INT     21h
            JC      Error1
            CMP     AL,0
            JE      TwoDrives           ;Two drives present, continue
            CMP     AL,1                ;Already set to access as A:?
            JE      SetDrive            ;Yes, so continue
            MOV     AH,44h              ;IOCTL
            MOV     AL,0Fh              ;Set logical drive map
            MOV     BL,1                ;Make it drive A:
            INT     21h
            MOV     AL,1                ;Signal want drive A:
            JMP     SetDrive            ;No need to query on which drive

TwoDrives:  MOV     SI,OFFSET DriveMsg
            CALL    PrtString

TDLoop:     MOV     AH,0                ;Read keyboard character
            INT     16h
            CMP     AL,'a'              ;Into lowercase territory?
            JB      TD1                 ;No, continue
            SUB     AL,32               ;Make it upper case
TD1:        CMP     AL,'A'              ;Less than minimum choice?
            JB      TDLoop              ;Yes, so keep asking
            CMP     AL,'B'              ;Greater than maximum?
            JA      TDLoop              ;Yes, so keep asking

            PUSH    AX                  ;Store keypress for a moment
            MOV     DL,AL               ;Print character
            MOV     AH,02h              ;Output a character
            INT     21h
            MOV     SI,OFFSET CRLF
            CALL    PrtString
            CALL    PrtString           ;Print it a second time
            POP     AX                  ;Get back keypress
            SUB     AL,64               ;Change to drive code

SetDrive:   MOV     Drive,AL            ;Store drive number
            ADD     AL,64               ;Make it into an ASCII character
            MOV     AscDrive,AL         ;Store it in message

            MOV     AL,0                ;Special function desired
            CALL    GetParms            ;Go find out about drive
            JC      Error1              ;Didn't work, so exit
            CALL    XferParms           ;Transfer to real work area

            MOV     SI,OFFSET DriveRdy
            CALL    PrtString

            MOV     SI,OFFSET Insert    ;Prompt to put in disk
            CALL    KeyMsg
            MOV     SI,OFFSET CRLF
            CALL    PrtString
            CALL    PrtString

            MOV     AL,DeviceType
            CMP     AL,3                ;Valid device types?
            JB      DeviceOK
            CMP     AL,7                ;Still valid?
            JNE     Error2              ;Nope, so exit
            MOV     AL,3                ;Force 7=3 for format type

DeviceOK:   MOV     FormatType,AL       ;Assume 0 or 2
            CMP     AL,0
            JE      Ready
            CMP     AL,2
            JE      Ready
            DEC     AL
            MOV     AH,0
            MOV     BX,OFFSET TypeTable ;Start of type table
            ADD     BX,AX               ;Adjust to proper message
            MOV     SI,[BX]             ;Get address
            CALL    PrtString
            MOV     SI,OFFSET TypeMsg
            CALL    PrtString

GTLoop:     MOV     AH,0                ;Read keyboard character
            INT     16h
            CMP     AL,'1'              ;Less than minimum choice?
            JB      GTLoop              ;Yes, so keep asking
            CMP     AL,'2'              ;Greater than maximum?
            JA      GTLoop              ;Yes, so keep asking

            PUSH    AX                  ;Store keypress for a moment
            MOV     DL,AL               ;Print character
            MOV     AH,02h              ;Output a character
            INT     21h
            MOV     SI,OFFSET CRLF
            CALL    PrtString
            CALL    PrtString           ;Print it a second time
            POP     AX                  ;Get back keypress
            CMP     AL,'2'              ;Was default OK?
            JE      Ready               ;Yes, so continue
            DEC     FormatType          ;No, so adjust

Ready:      MOV     SI,OFFSET FmtMsg
            CALL    PrtString
            MOV     AL,FormatType
            SHL     AL,1                ;Multiply by 2
            MOV     AH,0
            MOV     BX,OFFSET FTTable
            ADD     BX,AX               ;Adjust for proper message
            MOV     SI,[BX]             ;Get address from table
            CALL    PrtString
            MOV     SI,OFFSET DRMsg2
            CALL    PrtString

            CALL    DoParms             ;Set up parameters for format
            MOV     AL,5                ;Special code desired
            CALL    SetParms            ;Send them to IOCTL
            JC      Error3

            MOV     CurHead,0
            MOV     CX,Cylinders        ;This is number of tracks to format
            MOV     CurCylinder,-1      ;First increment will be for track 0
FmtLoop:    INC     CurCylinder
            CALL    Status              ;Display status
            CALL    FormatTrack         ;Go format the track
            JC      Error4
            LOOP    FmtLoop

            CALL    WriteBoot           ;Write the boot sector
            CALL    SetMID
            CALL    WriteFAT            ;Write the FAT
            CALL    WriteDir            ;Write the directory
            CALL    RestParms           ;Set the IOCTL stuff back right

            MOV     SI,OFFSET FinishMsg
            CALL    PrtString
            JMP     AllDone

Error1:     MOV     SI,OFFSET EMsg1
            JMP     ErrCommon
Error2:     MOV     SI,OFFSET EMsg2
            JMP     ErrCommon
Error3:     CALL    RestParms           ;Restore parameters
            MOV     SI,OFFSET EMsg3
            JMP     ErrCommon
Error4:     CALL    RestParms           ;Restore parameters
            MOV     SI,OFFSET EMsg4
ErrCommon:  CALL    PrtString
AllDone:    .EXIT
Fmt         ENDP


; Get current parms for desired drive.  Enter with AL equal to special function

GetParms    PROC    USES AX BX CX DX
            MOV     SFOrig,AL           ;Want for current BPB
            MOV     AH,44h              ;IOCTL
            MOV     AL,0Dh              ;Generic block I/O
            MOV     BL,Drive
            MOV     CH,08h              ;Disk drive
            MOV     CL,60h              ;Get device parameters
            MOV     DX,OFFSET OrigParms
            INT     21h
            RET
GetParms    ENDP


; Transfer from retrieved parameter area into one that will be used
; for the real work in the program

XferParms   PROC    USES CX SI DI ES
            CLD
            PUSH    DS
            POP     ES
            MOV     SI,OFFSET OrigParms
            MOV     DI,OFFSET NewParms
            MOV     CX,ParmLen
            REP     MOVSB
            CLC                         ;Exit with no error
            RET
XferParms   ENDP


; Set parameters.  Enter with AL equal to special function desired

SetParms    PROC    USES AX BX CX DX
            MOV     SpecFuncNew,AL
            MOV     AH,44h              ;IOCTL
            MOV     AL,0Dh              ;Generic block I/O
            MOV     BL,Drive
            MOV     CH,08h              ;Disk drive
            MOV     CL,40h              ;Set device parameters
            MOV     DX,OFFSET NewParms
            INT     21h
            RET
SetParms    ENDP


; Restore parms to their old condition

RestParms   PROC    USES AX BX CX DX
            MOV     SFOrig,00000100b
            MOV     AH,44h              ;IOCTL
            MOV     AL,0Dh              ;Generic block I/O
            MOV     BL,Drive
            MOV     CH,08h              ;Disk drive
            MOV     CL,40h              ;Set device parameters
            MOV     DX,OFFSET OrigParms
            INT     21h
            RET
RestParms   ENDP


; Set up parameters (including BPB) for selected format type.  Also
; transfers information into the BPB in the boot sector.

DoParms     PROC    USES AX BX CX SI DI ES
            MOV     AH,0
            MOV     AL,FormatType
            SHL     AX,1                ;Multiply by 2
            MOV     BX,OFFSET DCTable
            ADD     BX,AX               ;Adjust for format type
            MOV     SI,[BX]             ;Get proper address
            MOV     AX,[SI]             ;Get number of cylinders
            INC     SI                  ;Point to next parameter
            INC     SI
            CMP     Cylinders,AX        ;Default capacity for drive?
            JE      DP1
            MOV     MediaType,1         ;Set for low format
            MOV     Cylinders,AX
DP1:        PUSH    SI                  ;Store for a moment
            MOV     CX,25               ;Bytes to transfer
            MOV     DI,OFFSET DiskBPB
            PUSH    DS
            POP     ES
            CLD
            REP     MOVSB               ;Transfer parms
            CALL    DoLayout

            POP     SI                  ;Get start of BPB back
            MOV     AX,SEG BootBPB
            MOV     ES,AX
            MOV     DI,OFFSET ES:BootBPB
            MOV     CX,25
            REP     MOVSB               ;Transfer to boot sector
            RET
DoParms     ENDP


; Set the track layout field

DoLayout    PROC    USES AX BX CX SI DI ES
            CLD
            MOV     DI,OFFSET TrackLayout
            MOV     AX,SectTrack
            PUSH    DS
            POP     ES
            STOSW
            MOV     BX,1                ;First sector number
            MOV     CX,AX               ;Number of sectors per track
            MOV     DX,BytesSect        ;Bytes per sector
TrkLoop:    MOV     AX,BX               ;Sector number
            STOSW
            INC     BX                  ;Point to next sector
            MOV     AX,DX               ;Bytes per sector
            STOSW
            LOOP    TrkLoop             ;Do it all again
            RET
DoLayout    ENDP


; Set the media ID

SetMID      PROC    USES AX BX CX DX
            MOV     AH,44h              ;IOCTL
            MOV     AL,0Dh              ;Generic block I/O
            MOV     BL,Drive
            MOV     CH,08h              ;Disk drive
            MOV     CL,46h              ;Set media ID
            MOV     DX,OFFSET MIDStruct
            INT     21h
            RET
SetMID      ENDP


; Handle formatting a single track.  Return with carry set if error

FormatTrack PROC    USES CX
            MOV     CX,NumHeads
            DEC     CX                  ;Make zero based
FTLoop:     MOV     CurHead,CL
            CALL    FormatSide
            JC      FTDone
            LOOP    FTLoop
            CLC                         ;Return with no errors
FTDone:     RET
FormatTrack ENDP


; Format one head of a track.  Return with carry set if error

FormatSide  PROC    USES AX BX CX DX
            MOV     FmtParmSF,0
            MOV     AH,0
            MOV     AL,CurHead
            MOV     FmtParmHead,AX
            MOV     AL,CurCylinder
            MOV     FmtParmCyl,AX

            MOV     AH,44h              ;IOCTL
            MOV     AL,0Dh              ;Generic block I/O
            MOV     BH,0
            MOV     BL,Drive
            MOV     CH,08h              ;Disk drive
            MOV     CL,42h              ;Format/verify track
            MOV     DX,OFFSET FmtParms
            INT     21h
            RET
FormatSide  ENDP


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


; Display the status message during formatting

Status      PROC    USES AX SI
            MOV     SI,OFFSET TrackMsg1
            CALL    PrtString
            MOV     AH,0
            MOV     AL,CurCylinder
            INC     AX                  ;Normalize number
            CALL    PrtDec
            MOV     SI,OFFSET TrackMsg2
            CALL    PrtString
            MOV     AX,Cylinders
            CALL    PrtDec
            RET
Status      ENDP


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


; The following routine prints the message pointed to by SI and then
; waits for a keypress

KeyMsg      PROC    USES AX
            CALL    PrtString           ;Message pointed to by SI
            MOV     AH,0                ;Read keyboard character
            INT     16h
            RET
KeyMsg      ENDP


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


; Write the boot sector to the disk

WriteBoot   PROC    USES AX BX CX ES
            MOV     AX,SEG BootSector   ;Point to boot sector
            MOV     ES,AX
            MOV     BX,OFFSET ES:BootSector
            MOV     BuffStart[0],BX
            MOV     BuffStart[2],ES
            MOV     SectBegin,0
            MOV     SectCount,1
            MOV     AL,Drive
            DEC     AL                  ;Make it zero based
            MOV     BX,OFFSET DiskIO    ;Point to buffer
            MOV     CX,-1
            INT     26h
            POP     AX                  ;Get rid of flags
            RET
WriteBoot   ENDP


; Write the FAT to the disk

WriteFAT    PROC    USES AX BX CX DX DI ES DS
            MOV     AX,SectFAT
            MOV     BL,32               ;Paragraphs per 512 bytes
            MUL     BL                  ;AX now contains paragraphs needed
            MOV     BX,AX               ;   for one FAT image
            MOV     AH,48h              ;Allocate memory
            INT     21h                 ;DOS services
            MOV     ES,AX               ;Put in proper place

            MOV     AX,SectFAT
            MOV     CL,8                ;2^8 power (256)
            SHL     AX,CL               ;Number of words in memory area
            MOV     CX,AX               ;Iteration count
            MOV     DI,0                ;Point to start of memory block
            MOV     AX,0                ;Want to clear memory area
            CLD                         ;Go in proper direction
            REP     STOSW               ;Store 0s in memory

            MOV     AX,0FFFFh
            MOV     BL,MediaID
            MOV     ES:[0],BL           ;Store FAT ID
            MOV     ES:[1],AX           ;Store filler

            MOV     AX,1
            MOV     CH,0
            MOV     CL,NumFATs
FATLoop:    CALL    PutFAT
            ADD     AX,SectFAT
            LOOP    FATLoop

            MOV     AH,49h              ;Release memory block
            INT     21h                 ;DOS services

            RET
WriteFAT    ENDP


; Put one copy of the FAT on disk.  Enter with AX=beginning sector number

PutFAT      PROC    USES AX BX CX ES
            MOV     BuffStart[0],0
            MOV     BuffStart[2],ES
            MOV     SectBegin,AX
            MOV     AX,SectFAT
            MOV     SectCount,AX
            MOV     AL,Drive
            DEC     AL                  ;Make it zero based
            MOV     BX,OFFSET DiskIO    ;Point to buffer
            MOV     CX,-1
            INT     26h
            POP     AX                  ;Get rid of flags
            RET
PutFAT      ENDP


; Write the directory to the disk

WriteDIR    PROC    USES AX BX CX DX DI ES DS
            MOV     AX,RootDir          ;Maximum root directory entries
            MOV     CL,4                ;2^4 power (16)
            SHR     AX,CL               ;Divide by 16, now AX = sectors needed
            PUSH    AX                  ;Store for later

            MOV     BL,32               ;Paragraphs per 512 bytes
            MUL     BL                  ;AX now contains paragraphs needed
            MOV     BX,AX
            MOV     AH,48h              ;Allocate memory
            INT     21h                 ;DOS services
            MOV     ES,AX               ;Put in proper place

            POP     AX                  ;Get back number of directory sectors
            PUSH    AX                  ;And store for later
            MOV     CL,8                ;2^8 power (256)
            SHL     AX,CL               ;AX now has number of words in data area
            MOV     CX,AX               ;Put into loop counter
            MOV     DI,0                ;Start at beginning of block
            MOV     AX,0                ;Want to clear memory area
            CLD                         ;Go in proper direction
            REP     STOSW               ;Store 0s in memory

            MOV     AX,SectFAT          ;Number of sectors in one FAT
            MOV     BL,NumFATs          ;Get number of FATs
            MUL     BL                  ;AX now has number of sectors
            INC     AX                  ;Point to sector past FAT

            MOV     BuffStart[0],0
            MOV     BuffStart[2],ES
            MOV     SectBegin,AX
            POP     AX                  ;Get back directory sectors
            MOV     SectCount,AX
            MOV     AL,Drive
            DEC     AL                  ;Make it zero based
            MOV     BX,OFFSET DiskIO    ;Point to buffer
            MOV     CX,-1
            INT     26h
            POP     AX                  ;Get rid of flags

            MOV     AH,49h              ;Release memory block
            INT     21h                 ;DOS services

            RET
WriteDIR    ENDP


; The following routine is the actual code that will be written
; to disk for the boot sector.

BSect       SEGMENT PARA PRIVATE 'CODE'
            ASSUME CS:BSect, DS:BSect
            ORG     0                   ;Boot sector will be here

BootSector   DB     0EBh,03Ch,090h
;            JMP     SHORT BootCode
;            NOP

; Note that the following information, between here and BootCode, is the BPB
; used by DOS. This info is compatible with DOS 5, but will also work with
; earlier DOS versions.

            DB      'Assembly'
BootBPB     DB      25 DUP (0)
            DB      00                  ;Drive number, if a hard disk
            DB      00                  ;Reserved
            DB      29h                 ;Extended boot signature
            DD      00000000            ;Volume serial number
            DB      'Advanced   '       ;Volume label
            DB      'FAT12   '          ;File type

BootCode:   MOV     AX,7C0h             ;Standard loading place for
            MOV     DS,AX               ;   boot sector
            MOV     ES,AX

            MOV     AH,0Fh              ;Get current display mode
            INT     10h                 ;BIOS services

            MOV     SI,OFFSET BootMsg
MsgLoop:    MOV     AL,[SI]             ;Get next character
            CMP     AL,0                ;End of string?
            JE      MsgDone             ;Yes, so end
            MOV     AH,0Eh              ;Write text in teletype mode
            INT     10h                 ;BIOS services
            INC     SI
            JMP     SHORT MsgLoop

MsgDone:    MOV     AH,0                ;Read keyboard character
            INT     16h                 ;BIOS services
            MOV     AL,13               ;Process a carriage return
            MOV     AH,0Eh
            INT     10h
            MOV     AL,10               ;Process a line feed
            MOV     AH,0Eh
            INT     10h
            INT     19h                 ;Do a warm boot

BootMsg     DB      13,10,13,10
            DB      '                  This disk was formatted with a program from',13,10
            DB      '                 Advanced Assembly Language, by Allen L. Wyatt.',13,10
            DB      13,10
            DB      '                  This is a non-system disk.  Remove this disk',13,10
            DB      '                    and press any key to reboot your system.',13,10
            DB      13,10, 43 DUP (' '), 0

            ORG     510
            DB      55h                 ;Boot sector has to end with
            DB      0AAh                ;   these bytes, in this order

BSect       ENDS

            END
