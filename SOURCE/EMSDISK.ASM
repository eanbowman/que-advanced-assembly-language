Page 60,132

Comment |
******************************************************************

File:       EMSDISK.ASM
Author:     Allen L. Wyatt
Date:       8/1/92
Assembler:  MASM 6.0

Purpose:    Simple RAM drive that uses EMS memory.  Installs a
            720K disk that uses the next available drive name.

Format:     Installation:  DEVICE = EMSDISK.SYS

******************************************************************|

; The following are equates used in this file

RHLength    TEXTEQU <SI>
UnitCode    TEXTEQU <SI+1>
Command     TEXTEQU <SI+2>
ReturnStat  TEXTEQU <SI+3>

; Equates used in program

SectSize    EQU     512                 ;Bytes per sector on RAM disk
RootDE      EQU     112                 ;Root directory entries
TtlSect     EQU     32*45               ;Modified 720K 3.5" disk
MediaID     EQU     0F9h                ;Use media ID for 720K 3.5" disk
NumFATs     EQU     1                   ;Number of FATs in disk (only need 1)
FATSect     EQU     3                   ;Number of sectors per FAT
RDStart     EQU     NumFATs*FATSect+1   ;Where the root directory starts

; Error code equates

WPErr       EQU     00h
UnUnit      EQU     01h
NotReady    EQU     02h
BadCmd      EQU     03h
CRCErr      EQU     04h
BadRSLength EQU     05h
SeekErr     EQU     06h
UnMedia     EQU     07h
SecNotFound EQU     08h
OutOfPaper  EQU     09h
WriteFault  EQU     0Ah
ReadFault   EQU     0Bh
GeneralFail EQU     0Ch
BadChange   EQU     0Fh


; Start of real program

_TEXT       SEGMENT WORD PUBLIC 'CODE'
            ASSUME CS:_TEXT, DS:_TEXT, ES:NOTHING
            ORG     0                   ;Boot sector will be here

; Start of device driver header

            DD      -1                  ;Next-driver link set by DOS
            DW      0800h               ;Device attribute
            DW      OFFSET Strategy     ;Point to strategy routine
            DW      OFFSET Interrupt    ;Point to interrupt routine
            DB      1                   ;Number of units controlled
            DB      7 DUP(0)            ;Device name

; Other data used by the driver

RHaddress   DW      0000,0000           ;Request header address storage

; This RAM disk is set up to have 45 32-sector tracks.  That is because
; 32 512-byte sectors will fit in one 16K EMS page.  Makes life easier later

BootRec     EQU     THIS BYTE
            NOP                         ;3 bytes normally for jump statement
            NOP
            NOP
            DB      'MSDOS5.0'
BPB         DW      SectSize            ;Bytes per sector
            DB      02                  ;Sectors per cluster
            DW      0001                ;Reserved sectors
            DB      NumFATs             ;Number of FATs
            DW      RootDE              ;Number of root directory entries
            DW      TtlSect             ;Numer of sectors on disk
            DB      MediaID             ;Media ID
            DW      FATSect             ;Sectors per FAT
            DW      32                  ;Sectors per track
            DW      0001                ;Number of heads
            DD      00000000            ;Unused in our disk
            DD      00000000
            DB      6 DUP (0)
BRLen       EQU     $-OFFSET BootRec

SaveSS      DW      0000                ;Used to store DOS's stack pointers
SaveSP      DW      0000
Drive       DB      00                  ;Store drive assigned to this device
MemHandle   DW      0000                ;EMS memory block handle
PageFrame   DW      0000                ;EMS page frame
SectOff     DW      0000                ;Offset of sector in page frame
BuffOff     DW      0000
BuffSeg     DW      0000
SectCount   DW      0000
SectStart   DW      0000
SectDone    DW      0000                ;Sectors actually transferred

            EVEN                        ;Set up driver's stack area
            DW      128 DUP(0)
StackTop    EQU     $

CmdTable    DW      OFFSET Init         ;00 - Init
            DW      OFFSET MediaChk     ;01 - Media Check
            DW      OFFSET BuildBPB     ;02 - Build BPB
            DW      OFFSET MarkAsDone   ;03 - Control Info Read
            DW      OFFSET Read         ;04 - Read
            DW      OFFSET MarkAsDone   ;05 - Nondestructive Read
            DW      OFFSET MarkAsDone   ;06 - Input Status
            DW      OFFSET MarkAsDone   ;07 - Input Flush
            DW      OFFSET Write        ;08 - Write
            DW      OFFSET Write        ;09 - Write with Verify
            DW      OFFSET MarkAsDone   ;0A - Output Status
            DW      OFFSET MarkAsDone   ;0B - Output Flush
            DW      OFFSET MarkAsDone   ;0C - Control Info Write
            DW      OFFSET MarkAsDone   ;0D - Open Device
            DW      OFFSET MarkAsDone   ;0E - Close Device
            DW      OFFSET Removeable   ;0F - Removeable Media
            DW      OFFSET MarkAsDone   ;10 - Output Until Busy
            DW      OFFSET BadCommand   ;11 - BadCommand
            DW      OFFSET BadCommand   ;12 - BadCommand
            DW      OFFSET MarkAsDone   ;13 - Generic IOCTL
            DW      OFFSET BadCommand   ;14 - BadCommand
            DW      OFFSET BadCommand   ;15 - BadCommand
            DW      OFFSET BadCommand   ;16 - BadCommand
            DW      OFFSET MarkAsDone   ;17 - Get Logical Device
            DW      OFFSET MarkAsDone   ;18 - Set Logical Device
            DW      OFFSET MarkAsDone   ;19 - IOCTL Query

; Start of device driver strategy routine

Strategy    PROC    FAR
            MOV     CS:RHaddress[0],BX  ;Offset of request header
            MOV     CS:RHaddress[2],ES  ;Segment of request header
            RET
Strategy    ENDP

; Start of device driver interrupt routine

Interrupt   PROC    FAR
            PUSHF                       ;Save all the registers
            PUSH    AX
            PUSH    BX
            PUSH    CX
            PUSH    DX
            PUSH    SI
            PUSH    DI
            PUSH    DS
            PUSH    ES
            PUSH    BP

            MOV     AX,CS               ;Set up addressing and stack
            MOV     DS,AX
            MOV     SaveSS,SS           ;Save DOS stack context
            MOV     SaveSP,SP
            MOV     SS,AX
            MOV     SP,OFFSET StackTop

            MOV     SI,RHaddress[0]     ;Offset of request header
            MOV     ES,RHaddress[2]     ;Segment of request header
            MOV     BL,ES:[Command]     ;Get command from request header
            CMP     BL,25               ;Is command out of range?
            JBE     CmdOK
            CALL    BadCommand
            JMP     AllDone             ;Bypass context save and exit with error

CmdOK:      CMP     BL,0                ;Are we doing Init?
            JE      DoJump              ;Yes, skip EMS context call
            CALL    PutContext          ;Save current context
            JNC     DoJump              ;No error, continue
            MOV     AL,GeneralFail      ;Mark for general failure
            JMP     AllDone             ;And exit

DoJump:     MOV     BH,0
            SHL     BX,1                ;Set up addressing for CmdTable
            CALL    WORD PTR [BX+CmdTable]

; When entering the command handlers, ES:SI is set to the address of
; the request header.

; When returning from the command handler, AX should be set with the
; return code.  Following code saves new EMS context, determines if
; AL has an error code in it, and sets the error bit accordingly.
; In any case, the done bit is set prior to return.

            MOV     SI,RHaddress[0]     ;Offset of request header
            MOV     ES,RHaddress[2]     ;Segment of request header
            CMP     BYTE PTR ES:[Command],0 ;Are we finishing an Init?
            JE      AllDone             ;Yes, so don't restore context
            CALL    GetContext          ;Get back context
            JNC     AllDone             ;No error in this routine
            CMP     AL,0                ;Preexisting error?
            JNE     AllDone             ;Yes, so continue
            MOV     AL,GeneralFail      ;Mark for general failure and proceed

AllDone:    CMP     AL,0                ;Is there an error code?
            JE      NoError             ;No, so continue
            OR      AH,10000000b        ;Turn on error bit
NoError:    OR      AH,00000001b        ;Turn on done bit
            MOV     ES:[ReturnStat],AX  ;Store for return

            MOV     SS,SaveSS           ;Restore DOS stack context
            MOV     SP,SaveSP
            POP     BP                  ;Restore all registers
            POP     ES
            POP     DS
            POP     DI
            POP     SI
            POP     DX
            POP     CX
            POP     BX
            POP     AX
            POPF
            RET
Interrupt   ENDP


; The following are the command handlers called from
; the interrupt routine

MediaChk    PROC    NEAR                ;Command 01h - Media Check
            MOV     BYTE PTR ES:[SI+0Eh],1 ;Disk not changed (couldn't be)
            MOV     AX,0                ;Set return code
            RET
MediaChk    ENDP

BuildBPB    PROC    NEAR                ;Command 02h - Build BPB
            MOV     ES:[SI+12h],OFFSET BPB ;Point to BPB
            MOV     ES:[SI+14h],DS
            MOV     AX,0                ;Set return code
            RET
BuildBPB    ENDP


; Command 04h - Read

Read        PROC    NEAR USES BX CX DX SI DI ES
            CALL    XferSetup           ;Set up variables
            MOV     CX,SectCount        ;Number of sectors to transfer
            MOV     AX,SectStart        ;Starting sector number
            MOV     ES,BuffSeg
            MOV     DI,BuffOff

ReadLoop:   CALL    FindSect
            JC      ReadErr
            PUSH    CX                  ;Save exterior loop
            MOV     CX,SectSize
            MOV     SI,SectOff
            MOV     BX,PageFrame
            PUSH    DS                  ;Store temporarily
            MOV     DS,BX
            CLD                         ;Go proper direction
            REP     MOVSB
            POP     DS                  ;Get back addressing
            INC     AX                  ;Point to next sector
            POP     CX                  ;Get exterior loop back
            INC     SectDone            ;Finished another one
            LOOP    ReadLoop
            MOV     AX,0                ;Set return code
            JMP     ReadDone

ReadErr:    MOV     AX,SecNotFound      ;Sector not found
ReadDone:   MOV     SI,RHaddress[0]     ;Offset of request header
            MOV     ES,RHaddress[2]     ;Segment of request header
            MOV     BX,SectDone
            MOV     ES:[SI+12h],BX
            RET
Read        ENDP


; Command 08h - Write

Write       PROC    NEAR USES BX CX DX  ;Command 08h - Write
            CALL    XferSetup           ;Set up variables
            MOV     CX,SectCount        ;Number of sectors to transfer
            MOV     AX,SectStart        ;Starting sector number
            MOV     SI,BuffOff
            MOV     ES,PageFrame

WriteLoop:  CALL    FindSect
            JC      WriteErr
            PUSH    CX                  ;Save exterior loop
            MOV     DI,SectOff          ;Proper place in page frame
            MOV     CX,SectSize         ;Bytes to transfer
            MOV     BX,BuffSeg
            PUSH    DS                  ;Set up for transfer
            MOV     DS,BX               ;DS:SI points to buffer
            CLD                         ;Proper direction
            REP     MOVSB               ;Transfer to EMS area
            POP     DS                  ;Get back proper data segment
            INC     AX                  ;Point to next sector
            POP     CX                  ;Get exterior loop back
            INC     SectDone            ;Finished another one
            LOOP    WriteLoop
            MOV     AX,0                ;Set return code
            JMP     WriteDone

WriteErr:   MOV     AX,SecNotFound      ;Sector not found
WriteDone:  MOV     SI,RHaddress[0]     ;Offset of request header
            MOV     ES,RHaddress[2]     ;Segment of request header
            MOV     BX,SectDone
            MOV     ES:[SI+12h],BX
            RET
Write       ENDP


; Command 0Fh - Removeable Media

Removeable  PROC    NEAR
            MOV     AX,0200h            ;Set busy bit--indicates media is
            RET                         ;    not removeable
Removeable  ENDP


; The following command handler is used to simply mark a command as
; done.  It does nothing else, and is where commands are sent that
; are not implemented or supported.

MarkAsDone  PROC    NEAR
            MOV     AX,0                ;Set return code
            RET
MarkAsDone  ENDP

BadCommand  PROC    NEAR                ;BadCommand
            MOV     AX,BadCmd           ;Set return code
            RET
BadCommand  ENDP


; From here down through the rest of the driver is routines used
; in the command handlers

; Get sector specified in AX.  Converts sector number to EMS page and
; offset.  Sets SectOff variable to offset within page frame for start
; of sector.  No registers affected.  Carry clear on return if no error.
; Carry set on return if error dectected.

FindSect    PROC    NEAR USES AX BX CX DX
            MOV     DX,0                ;Set high word to zero
            MOV     BX,32               ;Dividing by 32 (sectors per EMS page)
            DIV     BX                  ;AX=EMS page, DX=sector in page
            MOV     BX,AX               ;Put in place for mapping

            MOV     AX,DX               ;Sector in page now in AX
            MOV     CX,SectSize
            MUL     CX                  ;AX=offset into EMS page
            MOV     SectOff,AX          ;Put offset in proper place

            CALL    GetPage             ;Go get the EMS page
            RET
FindSect    ENDP


; Get an EMS page into physical page 0.  Enter with BX set to logical
; page wanted.  All registers return unchanged.  Carry set if error.

GetPage     PROC    USES AX BX DX
            MOV     AH,44h              ;No, so map page
            MOV     AL,0                ;Start of page frame
            MOV     DX,MemHandle
            INT     67h
            CMP     AL,0                ;Was there an error?
            JNE     BadGet              ;Yes, so exit
            CLC
            JNC     GPExit
BadGet:     STC
GPExit:     RET
GetPage     ENDP


; Transfer information to local variables from the request header
; This routine is called before any read or write operation
; ES:SI should be set to start of request header

XferSetup   PROC    NEAR USES AX
            MOV     AX,ES:[SI+0Eh]      ;Get offset
            MOV     BuffOff,AX
            MOV     AX,ES:[SI+10h]      ;Get segment
            MOV     BuffSeg,AX
            MOV     AX,ES:[SI+12h]      ;Get sector count
            MOV     SectCount,AX
            MOV     AX,ES:[SI+14h]      ;Get starting sector
            MOV     SectStart,AX
            MOV     SectDone,0          ;Number of sectors transferred
            RET
XferSetup   ENDP


; Saves the page mapping info for MemHandle

PutContext  PROC    NEAR
            MOV     AH,47h              ;Save page map
            MOV     DX,MemHandle
            INT     67h
            CMP     AH,0                ;Any error?
            JNE     PCErr               ;Yes, exit
            CLC
            JNC     PCExit
PCErr:      STC
PCExit:     RET
PutContext  ENDP


; Restores the page mapping info for MemHandle

GetContext  PROC    NEAR
            MOV     AH,48h              ;Restore page map
            MOV     DX,MemHandle
            INT     67h
            CMP     AH,0                ;Any error?
            JNE     GCErr               ;Yes, exit
            CLC
            JNC     GCExit
GCErr:      STC
GCExit:     RET
GetContext  ENDP


; Init command.  This part of the driver is stripped after installation

Init        PROC    NEAR                ;Command 00h - Init
            MOV     AL,ES:[SI+16h]      ;Drive number for this drive
            MOV     Drive,AL
            ADD     AL,'@'              ;Make printable ASCII
            MOV     DriveMsg,AL         ;Store for welcome message

            MOV     SI,OFFSET CRLF
            CALL    PrtString

            CALL    ChkEMS              ;See if EMM is present
            JC      NoEMS               ;Not there, so go handle
            MOV     AH,41h              ;Get page frame
            INT     67h
            CMP     AH,0                ;Was there an error?
            JNE     NoPF                ;Yes, couldn't get page frame
            MOV     PageFrame,BX        ;And store for later
            MOV     AH,42h              ;Get pages available
            INT     67h
            CMP     AH,0                ;Was there an error?
            JNE     NoPA                ;Yes, couldn't determine pages available
            CMP     BX,45               ;We need 45 pages--is there enough?
            JB      NotEnough           ;Nope, go for error

; Everything is going great up to now.  EMM is installed, version number is
; right, and enough memory is available.  Now need to allocate the memory.

            MOV     AH,43h              ;Allocate EMS memory
            MOV     BX,45               ;Want 720K
            INT     67h
            CMP     AH,0                ;Was there an error?
            JNE     BadAlloc            ;Yes, couldn't allocate
            MOV     MemHandle,DX        ;Save the handle for the block

; Ready to zero-out 45 pages of EMS memory just successfully requested

            MOV     ES,PageFrame
            MOV     CX,45               ;Number of pages to zero
            MOV     AX,0                ;Filling with this
            MOV     BX,0
FillLoop:   CALL    GetPage             ;Go get page
            JC      GetErr              ;Exit if error
            PUSH    CX                  ;Store loop counter
            MOV     CX,2000h            ;Zero this many words
            MOV     DI,0                ;ES:DI to physical page 0
            CLD                         ;Proper direction
            REP     STOSW               ;And store it all
            POP     CX                  ;Get back loop counter
            INC     BX                  ;Point to next page
            LOOP    FillLoop

            MOV     AX,0                ;Want to get sector 0
            CALL    FindSect
            JC      GetErr              ;Exit if error
            MOV     ES,PageFrame        ;Make ES:DI point to sector
            MOV     DI,SectOff
            MOV     SI,OFFSET BootRec
            MOV     CX,BRLen            ;Length of boot record
            CLD                         ;Proper direction
            REP     MOVSB

            MOV     AX,1                ;Want first FAT sector
            CALL    FindSect
            JC      GetErr              ;Exit if error
            MOV     ES,PageFrame        ;Make ES:DI point to sector
            MOV     DI,SectOff
            MOV     BYTE PTR ES:[DI],MediaID
            INC     DI
            MOV     WORD PTR ES:[DI],0FFFFh

            MOV     AX,RDStart          ;Put a volume label in directory
            CALL    FindSect
            JC      GetErr
            MOV     ES,PageFrame
            MOV     DI,SectOff
            MOV     SI,OFFSET VolName
            MOV     CX,VNLen
            CLD
            REP     MOVSB

; Boot record and FAT are complete; all done setting up RAM disk
; Ready to display all-OK message

            MOV     SI,OFFSET Welcome
            CALL    PrtString

            MOV     SI,RHaddress[0]     ;Offset of request header
            MOV     ES,RHaddress[2]     ;Segment of request header
            MOV     BYTE PTR ES:[SI+0Dh],1 ;Number of block devices
            MOV     ES:[SI+0Eh],OFFSET Init
            MOV     ES:[SI+10h],CS
            MOV     ES:[SI+12h],OFFSET BPBarray ;Point to BPB array
            MOV     ES:[SI+14h],DS
            MOV     AX,0                ;Set return code
            JMP     InitDone            ;Exit with everything great

; Routines between here and InitDone receive control if there was an
; error during initialization and the driver installation must be aborted.

NoEMS:      MOV     SI,OFFSET EMSMsg    ;Point to error message
            JMP     ErrCommon
NoPF:       MOV     SI,OFFSET NoPFMsg
            JMP     ErrCommon
NoPA:       MOV     SI,OFFSET NoPAMsg
            JMP     ErrCommon
NotEnough:  MOV     SI,OFFSET NEMemMsg
            JMP     ErrCommon
BadAlloc:   MOV     SI,OFFSET BAMsg
            JMP     ErrCommon
GetErr:     MOV     SI,OFFSET GetMsg
ErrCommon:  CALL    PrtString

Abort:      MOV     SI,OFFSET AbortMsg  ;Generic abort message
            CALL    PrtString
            MOV     SI,RHaddress[0]     ;Offset of request header
            MOV     ES,RHaddress[2]     ;Segment of request header
            MOV     BYTE PTR ES:[SI+0Dh],0 ;No block devices
            MOV     WORD PTR ES:[SI+0Eh],0 ;Point to nowhere
            MOV     ES:[SI+10h],CS
            MOV     AX,0                ;No error noted

InitDone:   MOV     SI,OFFSET CRLF
            CALL    PrtString
            RET
Init        ENDP


; The following routine checks to see if an EMM is installed.
; If one is not, the carry flag is set on return
; If one is, the carry flag is cleared on return

ChkEMS      PROC    USES AX BX DX ES
            MOV     AX,0
            MOV     ES,AX
            MOV     BX,67h*4            ;Vector table position for EMS vector
            MOV     ES,ES:[BX+2]        ;Get offset
            MOV     DI,0Ah              ;Point to device driver header name
            MOV     SI,OFFSET EMSName   ;Point to name to check
            MOV     CX,8                ;Check 8 characters
            CLD                         ;Go in right direction
            REPE    CMPSB               ;Is it equal?
            JNE     NotThere            ;Nope, so exit

            MOV     AH,40h              ;Check manager status
            INT     67h
            CMP     AH,0                ;Error?
            JNE     NotThere            ;Yes, so exit

            MOV     AH,46h              ;Get EMS version
            INT     67h
            CMP     AL,30h              ;Running at least EMS 3.0?
            JB      NotThere            ;No, so can't use

            CLC                         ;Set for no error
            JNC     Done
NotThere:   STC
Done:       RET
ChkEMS      ENDP


; The following routine prints the ASCIIZ string pointed to by DS:SI

PrtString   PROC    NEAR USES AX BX SI
            MOV     BH,0                ;Assume page 0
PS1:        MOV     AL,[SI]             ;Get character
            INC     SI                  ;Point to next one
            CMP     AL,0                ;End of string?
            JE      PS2                 ;Yes, so exit
            MOV     AH,0Eh              ;Output a character
            INT     10h
            JMP     PS1                 ;Keep doing it
PS2:        RET
PrtString   ENDP


; Data area used by the init portion of the driver.  Contains information not
; needed after device driver is loaded.

EMSName     DB      'EMMXXXX0'
BPBarray    DW      OFFSET BPB          ;Array for initialization
CRLF        DB      13,10,0
Welcome     DB      55 DUP('-'),13,10
            DB      ' EMSDisk -- A 720K disk emulator using expanded memory',13,10
            DB      '      Source code from Advanced Assembly Language',13,10
            DB      '                   by Allen L. Wyatt',13,10,13,10
            DB      '                  EMSDisk is drive '
DriveMsg    DB      '?:',13,10
            DB      55 DUP('-'),13,10,0
EMSMsg      DB      'Could not locate a functional EMS driver'
            DB      'EMSdisk needs at driver compatible with at least EMS 3.0',13,10,0
NoPFMsg     DB      'Could not determine EMS page frame',13,10,0
NoPAMsg     DB      'Could not determine available EMS memory',13,10,0
NEMemMsg    DB      'Not enough EMS memory available for installation',13,10,0
BAMsg       DB      'Could not allocate 720K of EMS memory',13,10,0
GetMsg      DB      'Could not initialize the EMS memory',13,10,0
AbortMsg    DB      'EMSDisk was not loaded',13,10,0

; The following is a directory entry for the volume name

VolName     DB      'Advanced   '       ;Volume name
            DB      00001000b           ;File attributes (volume label)
            DB      10 DUP(0)           ;Unused area
            DW      0000100000000000b   ;Time stamp
            DW      0001101100000001b   ;Date stamp
            DW      0000                ;Beginning cluster (N/A on volume)
            DD      00000000            ;File size (N/A on volume)
VNLen       EQU     $-VolName


_TEXT       ENDS
            END
