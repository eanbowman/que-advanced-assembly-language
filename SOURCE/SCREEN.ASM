Page 60,132

Comment |
******************************************************************

File:       SCREEN.ASM
Author:     Allen L. Wyatt
Date:       7/28/92
Assembler:  MASM 6.0

Purpose:    Installable character device driver.  Can be used in
            programs or from the command line to display a screen
            of information at a time, and then pause for the user
            to press a key.

Format:     Installation:  DEVICE = SCREEN.SYS
            Use:  COPY FILENAME.EXT SCREEN
                  TYPE FILENAME.EXE >SCREEN
                  or, open the device for output

******************************************************************|

; The following are equates used in this file

RHLength    TEXTEQU <SI>
UnitCode    TEXTEQU <SI+1>
Command     TEXTEQU <SI+2>
ReturnStat  TEXTEQU <SI+3>

LinesPer    EQU     23                  ;Number of lines to display per screen

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
            DW      0A800h              ;Device attribute
            DW      OFFSET Strategy     ;Point to strategy routine
            DW      OFFSET Interrupt    ;Point to interrupt routine
            DB      'SCREEN  '          ;Device name

; Other data used by the driver

RHaddress   DW      0000,0000           ;Request header address storage

CharWanted  DW      0000                ;Number of characters to transfer
CharDone    DW      0000                ;Number done
CharCol     DB      00                  ;Character per line
VidPage     DB      -1                  ;Current video page
PauseMsg    DB      'Press any key to continue...',0
CRLF        DB      13,10,0

CmdTable    DW      OFFSET Init         ;Init
            DW      OFFSET MediaChk     ;Media Check
            DW      OFFSET BuildBPB     ;Build BPB
            DW      OFFSET ReadInfo     ;Control Info Read
            DW      OFFSET Read         ;Read
            DW      OFFSET NDRead       ;Nondestructive Read
            DW      OFFSET InStat       ;Input Status
            DW      OFFSET InFlush      ;Input Flush
            DW      OFFSET Write        ;Write
            DW      OFFSET WriteVfy     ;Write with Verify
            DW      OFFSET OutStat      ;Output Status
            DW      OFFSET OutFlush     ;Output Flush
            DW      OFFSET WriteInfo    ;Control Info Write
            DW      OFFSET Open         ;Open Device
            DW      OFFSET Close        ;Close Device
            DW      OFFSET Removeable   ;Removeable Media
            DW      OFFSET OutTilBusy   ;Output Until Busy
            DW      OFFSET BadCommand   ;BadCommand
            DW      OFFSET BadCommand   ;BadCommand
            DW      OFFSET Generic      ;Generic IOCTL
            DW      OFFSET BadCommand   ;BadCommand
            DW      OFFSET BadCommand   ;BadCommand
            DW      OFFSET BadCommand   ;BadCommand
            DW      OFFSET GetDevice    ;Get Logical Device
            DW      OFFSET SetDevice    ;Set Logical Device
            DW      OFFSET Query        ;IOCTL Query

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

            PUSH    CS                  ;Set up addressing
            POP     DS

            MOV     SI,RHaddress[0]     ;Offset of request header
            MOV     ES,RHaddress[2]     ;Segment of request header
            MOV     BL,ES:[Command]     ;Get command from request header
            CMP     BL,25               ;Is command out of range?
            JBE     CmdOK
            CALL    BadCommand
            JMP     AllDone

CmdOK:      MOV     BH,0
            SHL     BX,1                ;Set up addressing for CmdTable
            CALL    WORD PTR [BX+CmdTable]

; When entering the command handlers, ES:SI is set to the address of
; the request header.

; When returning from the command handler, AX should be set with the
; return code.  Following code determines if AL has an error code in
; it, and sets the error bit accordingly.  In any case, the done bit
; is set prior to return.

AllDone:    CMP     AL,0                ;Is there an error code?
            JE      NoError             ;No, so continue
            OR      AH,10000000b        ;Turn on error bit
NoError:    OR      AH,00000001b        ;Turn on done bit
            MOV     ES:[ReturnStat],AX  ;Store for return

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

            MOV     AX,0                ;Set return code
            RET
MediaChk    ENDP

BuildBPB    PROC    NEAR                ;Command 02h - Build BPB

            MOV     AX,0                ;Set return code
            RET
BuildBPB    ENDP

ReadInfo    PROC    NEAR                ;Command 03h - Control Info Read

            MOV     AX,0                ;Set return code
            RET
ReadInfo    ENDP

Read        PROC    NEAR                ;Command 04h - Read

            MOV     AX,0                ;Set return code
            RET
Read        ENDP

NDRead      PROC    NEAR                ;Command 05h - Nondestructive Read

            MOV     AX,0200h            ;Set busy bit in return code
            RET                         ; (no characters waiting in buffer)
NDRead      ENDP

InStat      PROC    NEAR                ;Command 06h - Input Status

            MOV     AX,0                ;Set return code
            RET
InStat      ENDP

InFlush     PROC    NEAR                ;Command 07h - Input Flush

            MOV     AX,0                ;Set return code
            RET
InFlush     ENDP

Write       PROC    NEAR USES BX CX     ;Command 08h - Write
            PUSH    ES
            PUSH    SI
            CALL    SetParms
            MOV     AX,ES:[SI+0Eh]      ;Get offset
            MOV     BX,ES:[SI+10h]      ;Get segment
            MOV     CX,ES:[SI+12h]      ;Character count
            MOV     CharWanted,CX       ;Characters wanted
            MOV     CharDone,0          ;Actually done
            JCXZ    WriteDone           ;Nothing to transfer

            MOV     ES,BX               ;Set up addressing
            MOV     SI,AX               ;Now ES:SI points to transfer buffer
            CALL    DoScreen

WriteDone:  POP     SI
            POP     ES
            MOV     AX,0                ;Assume no errors
            MOV     CX,CharDone
            MOV     ES:[SI+12h],CX      ;Number transferred
            CMP     CX,CharWanted
            JE      WriteEnd
            MOV     AL,WriteFault       ;Set for error
WriteEnd:   RET
Write       ENDP

WriteVfy    PROC    NEAR                ;Command 09h - Write with Verify

            MOV     AX,0                ;Set return code
            RET
WriteVfy    ENDP

OutStat     PROC    NEAR                ;Command 0Ah - Output Status

            MOV     AX,0                ;Set return code
            RET
OutStat     ENDP

OutFlush    PROC    NEAR                ;Command 0Bh - Output Flush

            MOV     AX,0                ;Set return code
            RET
OutFlush    ENDP

WriteInfo   PROC    NEAR                ;Command 0Ch - Control Info Write

            MOV     AX,0                ;Set return code
            RET
WriteInfo   ENDP

Open        PROC    NEAR                ;Command 0Dh - Open Device
            CALL    SetParms
            CALL    Cls
            MOV     AX,0                ;Set return code
            RET
Open        ENDP

Close       PROC    NEAR                ;Command 0Eh - Close Device

            MOV     AX,0                ;Set return code
            RET
Close       ENDP

Removeable  PROC    NEAR                ;Command 0Fh - Removeable Media

            MOV     AX,0                ;Set return code
            RET
Removeable  ENDP

OutTilBusy  PROC    NEAR                ;Command 10h - Output Until Busy
            CALL    Write               ;Handled by same routines
            AND     AX,7F00h            ;Turn off any errors
            RET
OutTilBusy  ENDP

Generic     PROC    NEAR                ;Command 13h - Generic IOCTL

            MOV     AX,0                ;Set return code
            RET
Generic     ENDP

GetDevice   PROC    NEAR                ;Command 17h - Get Logical Device

            MOV     AX,0                ;Set return code
            RET
GetDevice   ENDP

SetDevice   PROC    NEAR                ;Command 18h - Set Logical Device

            MOV     AX,0                ;Set return code
            RET
SetDevice   ENDP

Query       PROC    NEAR                ;Command 19h - IOCTL Query

            MOV     AX,0                ;Set return code
            RET
Query       ENDP

BadCommand  PROC    NEAR                ;BadCommand
            MOV     AX,BadCmd           ;Set return code
            RET
BadCommand  ENDP


; From here down through the rest of the driver is routines used
; in the command handlers

; Set parameters for video page and screen width

SetParms    PROC    NEAR USES AX BX
            MOV     AH,0Fh              ;Get display mode
            INT     10h
            MOV     VidPage,BH          ;Display page
            MOV     CharCol,AH          ;Store character per line
            RET
SetParms    ENDP

; Display a screen of information.  Enter with CX set to the number
; of characters to be displayed.

DoScreen    PROC    NEAR USES AX BX CX DX SI
            MOV     BH,VidPage          ;Grab video page
DSLoop:     PUSH    CX                  ;Store loop counter
            MOV     AL,ES:[SI]          ;Grab character
            INC     SI                  ;Point to next character
            MOV     AH,0Eh              ;BIOS output in teletype mode
            INT     10h
            INC     CharDone            ;Number of characters transferred

            MOV     AH,03h              ;Get cursor position
            INT     10h
            CMP     DH,LinesPer         ;Reached full screen?
            JB      DS2                 ;No, continue
            CALL    PagePause
            CALL    Cls
DS2:        POP     CX                  ;Get back loop counter
            LOOP    DSLoop

            RET
DoScreen    ENDP

 ; The following routine clears the screen and homes the cursor

Cls         PROC    USES AX BX CX DX
            MOV     AH,6                ;Scroll window up
            MOV     AL,0                ;Scroll full screen
            MOV     BH,7                ;Normal white on black
            MOV     CX,0                ;Upper left corner of screen
            MOV     DH,24               ;Bottom right
            MOV     DL,CharCol
            INT     10h

            MOV     DX,0                ;Upper left corner of screen
            MOV     BH,VidPage          ;Video page
            MOV     AH,2                ;Set cursor position
            INT     10h
            RET
Cls         ENDP

; The following routine pauses at the bottom of a page

PagePause   PROC    USES AX BX DX SI
            MOV     DH,24               ;Set up to print pause message
            MOV     DL,0
            MOV     BH,VidPage          ;Video page
            MOV     AH,2                ;Set cursor position
            INT     10h
            MOV     SI,OFFSET PauseMsg  ;Point to start of pause message
            CALL    PrtString           ;Display the string
            MOV     AH,0                ;Read keyboard character
            INT     16h
            RET
PagePause   ENDP

; The following routine prints the ASCIIZ string pointed to by DS:SI

PrtString   PROC    NEAR USES AX BX SI
            MOV     BH,VidPage
PS1:        MOV     AL,[SI]             ;Get character
            INC     SI                  ;Point to next one
            CMP     AL,0                ;End of string?
            JE      PS2                 ;Yes, so exit
            MOV     AH,0Eh              ;Output a character
            INT     10h
            JMP     PS1                 ;Keep doing it
PS2:        RET
PrtString   ENDP


; Init command.  This part of the driver is stripped after installation

Init        PROC    NEAR                ;Command 00h - Init
            PUSH    SI
            MOV     SI,OFFSET Welcome
            CALL    PrtString
            POP     SI
            MOV     ES:[SI+0Eh],OFFSET Init
            MOV     ES:[SI+10h],CS
            MOV     AX,0                ;Set return code
            RET
Init        ENDP

Welcome     DB      13,10,13,10
            DB      '--- SCREEN now loaded ---',13,10,13,10,0

_TEXT       ENDS
            END
