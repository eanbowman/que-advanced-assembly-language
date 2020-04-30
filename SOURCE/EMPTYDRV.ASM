Page 60,132

Comment |
******************************************************************

File:       EMPTYDRV.ASM
Author:     Allen L. Wyatt
Date:       7/28/92
Assembler:  MASM 6.0

Purpose:    Skeleton device driver.  Simply displays a message at
            installation.  All other commands simply return with
            the done bit in the return status word set.

Format:     DEVICE = EMPTYDRV.SYS

******************************************************************|

; The following are equates used in this file

RHLength    TEXTEQU <SI>
UnitCode    TEXTEQU <SI+1>
Command     TEXTEQU <SI+2>
ReturnStat  TEXTEQU <SI+3>

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
            DW      0C840h              ;Device attribute
            DW      OFFSET Strategy     ;Point to strategy routine
            DW      OFFSET Interrupt    ;Point to interrupt routine
            DB      'EMPTYDRV'          ;Device name

; Other data used by the driver

RHaddress   DW      0000,0000           ;Request header address storage

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

            MOV     AX,0                ;Set return code
            RET
NDRead      ENDP

InStat      PROC    NEAR                ;Command 06h - Input Status

            MOV     AX,0                ;Set return code
            RET
InStat      ENDP

InFlush     PROC    NEAR                ;Command 07h - Input Flush

            MOV     AX,0                ;Set return code
            RET
InFlush     ENDP

Write       PROC    NEAR                ;Command 08h - Write

            MOV     AX,0                ;Set return code
            RET
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

            MOV     AX,0                ;Set return code
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

; The following routine prints the ASCIIZ string pointed to by DS:SI

PrtString   PROC    NEAR USES AX DX SI
PS1:        MOV     DL,[SI]             ;Get character
            INC     SI                  ;Point to next one
            CMP     DL,0                ;End of string?
            JE      PS2                 ;Yes, so exit
            MOV     AH,02h              ;Output a character
            INT     21h
            JMP     PS1                 ;Keep doing it
PS2:        RET
PrtString   ENDP

Welcome     DB      13,10,13,10
            DB      '         --- EMPTYDRV now loaded ---',13,10
            DB      ' Source code from Advanced Assembly Language',13,10
            DB      '              by Allen L. Wyatt',13,10,10,10,0

_TEXT       ENDS
            END
