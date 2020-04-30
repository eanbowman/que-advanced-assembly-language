Page 60,132

Comment |
******************************************************************

File:       MINFO.ASM
Author:     Allen L. Wyatt
Date:       5/13/92
Assembler:  MASM 6.0

Purpose:    Display information about the mouse and driver

Format:     MINFO

******************************************************************|

            .MODEL  small
            .STACK                      ;Default 1Kb stack is OK
            .DATA

Installed   DB      13,10,13,10
            DB      'The mouse driver is installed, version $'
TypeTable   DW      OFFSET Type1
            DW      OFFSET Type2
            DW      OFFSET Type3
            DW      OFFSET Type4
            DW      OFFSET Type5

Type1       DB      13,10,'This is a bus mouse',13,10,'$'
Type2       DB      13,10,'This is a serial mouse',13,10,'$'
Type3       DB      13,10,'This is an InPort mouse',13,10,'$'
Type4       DB      13,10,'This is a PS/2 mouse',13,10,'$'
Type5       DB      13,10,'This is an HP mouse',13,10,'$'

FileType    DB      'The driver was loaded as a $'
SysType     DB      'SYS file in CONFIG.SYS',13,10,'$'
ComType     DB      'COM file',13,10,'$'
MDD         DB      'The driver is newer Mouse Display Driver (MDD)',13,10,'$'
NonInt      DB      'The driver is of the non-integrated variety',13,10,'$'

Cur         DB      'The mouse is set to use the $'

CurTable    DW      OFFSET Cur1
            DW      OFFSET Cur2
            DW      OFFSET Cur3
            DW      OFFSET Cur3

Cur1        DB      'software text cursor',13,10,'$'
Cur2        DB      'hardware text cursor',13,10,'$'
Cur3        DB      'graphics text cursor',13,10,'$'

VidModes    DB      13,10
            DB      'The following video modes are supported by the driver:'
            DB      13,10,'$'

Mode        DB      'Mode $'
Spaces      DB      '     $'
NoVid       DB      '[no description provided]'
CRLF        DB      13,10,'$'

Pause       DB      13,10,'Press any key to continue...$'

VNum        DW      0000
Count       DB      00

            .CODE
            .STARTUP
Minfo       PROC

            CALL    ChkMouse            ;Go see if mouse is there
            JC      AllDone             ;Error, so exit

            MOV     DX,OFFSET Installed ;Point to installed message
            MOV     AH,9                ;Display a string using DOS
            INT     21h

            MOV     AX,36               ;Get driver info
            INT     33h
            MOV     VNum,BX             ;Store the version

            MOV     AX,0                ;Reset value
            MOV     AL,BH               ;Major version number
            CALL    PrtDec              ;Go print it
            MOV     DL,'.'
            MOV     AH,02h              ;Output a character
            INT     21h
            MOV     AX,0                ;Reset value
            MOV     AL,BL               ;Minor version number
            CALL    PrtDec              ;Go print it
            MOV     BH,0                ;Reset high byte
            MOV     BL,CH               ;Mouse type
            DEC     BL                  ;Use as index
            SHL     BX,1                ;Multiply by 2
            MOV     DX,TypeTable[BX]    ;Get proper type
            MOV     AH,9                ;Display a string using DOS
            INT     21h

            CMP     VNum,061Ah          ;Is this version 6.26?
            JL      AllDone             ;Nope, earlier version, so exit

            MOV     DX,OFFSET FileType  ;Point to next message
            MOV     AH,9                ;Display a string using DOS
            INT     21h
            MOV     AX,37               ;Get mouse driver info
            INT     33h
            PUSH    AX                  ;Store flags for a moment
            MOV     DX,OFFSET ComType   ;Assume COM file
            AND     AX,8000h            ;Only want bit 15
            JZ      M1                  ;Not a SYS file
            MOV     DX,OFFSET SysType   ;Using SYS file
M1:         MOV     AH,9                ;Display a string using DOS
            INT     21h
            POP     AX                  ;Get flags back
            PUSH    AX                  ;Store flags again
            MOV     DX,OFFSET MDD       ;Assume MDD driver
            AND     AX,4000h            ;Only want bit 14
            JNZ     M2                  ;Not a COM file
            MOV     DX,OFFSET NonInt    ;Using non-integrated driver
M2:         MOV     AH,9                ;Display a string using DOS
            INT     21h
            MOV     DX,OFFSET Cur       ;Point to next message
            MOV     AH,9                ;Display a string using DOS
            INT     21h
            POP     AX                  ;Get flags back
            AND     AX,3000h            ;Only want bits 13 and 12
            XCHG    AH,AL
            MOV     CL,3
            SHR     AX,CL               ;Right-justify bits/multiply by 2
            MOV     BX,AX
            MOV     DX,CurTable[BX]
            MOV     AH,9                ;Display a string using DOS
            INT     21h

            CMP     VNum,0700h          ;Is this version 6.26?
            JL      AllDone             ;Nope, earlier version, so exit

            MOV     DX,OFFSET VidModes  ;Message on video modes
            MOV     AH,9                ;Display a string using DOS
            INT     21h

            MOV     Count,16            ;Have already printed six lines
            MOV     CX,0                ;Start enumerating video modes
EnumLoop:   MOV     AX,41               ;Enumerate video modes
            INT     33h
            JCXZ    AllDone             ;Quit when no more modes
            PUSH    CX                  ;Save video mode
            PUSH    BX                  ;Save segment
            PUSH    DX                  ;Save offset
            MOV     DX,OFFSET Mode
            MOV     AH,9                ;Display a string using DOS
            INT     21h

            MOV     AX,CX
            CALL    PrtDec
            MOV     DX,OFFSET Spaces
            MOV     AH,9                ;Display a string using DOS
            INT     21h

            POP     DX                  ;Get offset back
            POP     AX                  ;Get segment back
            CMP     DX,0                ;Is offset 0?
            JNE     M3                  ;No, continue
            CMP     AX,0                ;Is segment 0?
            JE      M4                  ;Yes, so none there
M3:         PUSH    DS
            MOV     DS,AX
            MOV     AH,9                ;Display a string using DOS
            INT     21h
            POP     DS
            MOV     DX,OFFSET CRLF
            MOV     AH,9                ;Display a string using DOS
            INT     21h
            JMP     M5

M4:         MOV     DX,OFFSET NoVid
            MOV     AH,9                ;Display a string using DOS
            INT     21h

M5:         DEC     Count               ;At end of page?
            JNZ     M6
            CALL    PagePause           ;Go pause
            MOV     Count,23            ;Allow for full page

M6:         POP     CX                  ;Get video mode back
            JMP     EnumLoop

AllDone:
            .EXIT
Minfo       ENDP


; The following routine checks to see if a mouse is installed.
; If one is not, then the appropriate message is displayed, and the
;    carry flag is set on return
; If one is, then the mouse is reset, and the carry flag is cleared

            .DATA
NoDriver    DB      13,10,'Sorry, the mouse driver was not loaded$'
NoMouse     DB      13,10,'A mouse is not attached to the system$'

            .CODE
ChkMouse    PROC    USES AX BX DX ES

            MOV     AH,35h              ;Get interrupt vector
            MOV     AL,33h              ;Mouse interrupt
            INT     21h

            OR      AX,BX               ;Was an address returned?
            JZ      CM1                 ;No, so give error
            CMP     BYTE PTR ES:[BX],0CFh ;Is it simply IRET at address?
            JNE     CM2                 ;No, so driver is installed
CM1:        MOV     DX,OFFSET NoDriver  ;Point to error message
            JMP     CM3                 ;Go print it

CM2:        MOV     AX,0                ;Initialize mouse
            INT     33h
            CMP     AX,0                ;Zero returned if no mouse
            JNE     CM4                 ;Mouse is there
            MOV     DX,OFFSET NoMouse   ;Point to error message
CM3:        MOV     AH,9                ;Display a string using DOS
            INT     21h
            STC                         ;Set error indication
            JC      CMDone

CM4:        CLC
CMDone:     RET
ChkMouse    ENDP


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


; The following routine pauses at the bottom of a page

PagePause   PROC    USES AX BX DX
            MOV     DX,OFFSET Pause     ;Point to start of pause message
            MOV     AH,9                ;Display a string using DOS
            INT     21h
            MOV     AH,0                ;Read keyboard character
            INT     16h
            MOV     DX,OFFSET CRLF
            MOV     AH,9                ;Display a string using DOS
            INT     21h
            RET
PagePause   ENDP

            END
