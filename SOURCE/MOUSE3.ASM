Page 60,132

Comment |
******************************************************************

File:       MOUSE3.ASM
Author:     Allen L. Wyatt
Date:       5/13/92
Assembler:  MASM 6.0

Purpose:    In graphics mode, allow the user to select a word by
            pointing and clicking on the left mouse button.
            This program assumes you have an EGA or VGA monitor.

Format:     MOUSE3

******************************************************************|

            .MODEL  small
            .STACK                      ;Default 1Kb stack is OK
            .DATA
XPos        DB      'X Position: $'
YPos        DB      '     Y Position: $'

XCPos       DB      'Column: $'
YCPos       DB      '     Row: $'
NoWord      DB      'There is no word where you clicked$'
WordMsg     DB      'Word last clicked on:  '
BufLen      EQU     40
Buffer      DB      BufLen DUP(' ')
            DB      ' $'
Blank       DB      '        $'

Msg         DB      'Click on the right mouse button to exit program$'
Text        DB      'These are random words on a line.  $'

VidMode     DB      00
VidPage     DB      00
OldX        DW      0000
OldY        DW      0000
ClickX      DB      00
ClickY      DB      00
CurX        DB      00
CurY        DB      00
FirstChar   DB      00

            .CODE
            .STARTUP
Mouse3      PROC

            CALL    ChkMouse            ;Go see if mouse is there
            JC      AllDone             ;Error, so exit

            MOV     AH,0Fh              ;Get video mode
            INT     10h
            MOV     VidMode,AL          ;Store for later

            MOV     AH,0                ;BIOS set video mode
            MOV     AL,10h
            INT     10h

            MOV     AH,0Fh              ;Get video mode (want display page)
            INT     10h
            MOV     VidPage,BH          ;Will use this later

            CALL    Cls                 ;Clear the screen
            MOV     DH,24               ;Row 24
            MOV     DL,0                ;To the left
            MOV     BH,VidPage
            MOV     AH,2                ;Set cursor position
            INT     10h
            MOV     DX,OFFSET Msg       ;Point to exit message
            MOV     AH,9                ;Display a string using DOS
            INT     21h

            MOV     DX,0                ;Upper left corner
            MOV     BH,VidPage
            MOV     AH,2                ;Set cursor position
            INT     10h

            MOV     CX,32
FillScrn:   MOV     DX,OFFSET Text      ;Text for screen top
            MOV     AH,9                ;Display a string using DOS
            INT     21h
            LOOP    FillScrn

            CALL    ShowMouse           ;Go show mouse cursor

Mloop:      MOV     AX,3                ;Read mouse status
            INT     33h

            CMP     BX,2                ;Was right button pressed?
            JE      Exit                ;Yes, so exit

            CMP     BX,1                ;Was left button pressed?
            JNE     M1                  ;No, so do position
            PUSH    DX                  ;Store Y
            PUSH    CX                  ;Store X

            MOV     AX,DX               ;Set up for division
            MOV     CL,14
            DIV     CL                  ;AL now contains Y character position
            MOV     ClickY,AL
            POP     AX                  ;Get back X position
            PUSH    AX                  ;And store again
            MOV     CL,3                ;Divide by 8
            SHR     AX,CL               ;AL contains X character position
            MOV     ClickX,AL           ;Store for a while

            CALL    Position            ;Print position of click
            CALL    Xfer                ;Go move word
            CALL    DispWord            ;Display word

            POP     CX                  ;Restore X
            POP     DX                  ;Restore Y

M1:         CMP     CX,OldX             ;Did X position change?
            JNE     Change              ;Yes, so handle
            CMP     DX,OldY             ;Did Y position change?
            JE      Mloop               ;No, so continue loop

Change:     MOV     OldX,CX             ;Store X position
            MOV     OldY,DX             ;Store Y position
            CALL    Coords              ;Display changes
            JMP     Mloop               ;Do it all again

Exit:       MOV     AX,0                ;Reset mouse
            INT     33h
            MOV     AH,0                ;BIOS set video mode
            MOV     AL,VidMode
            INT     10h
            CALL    Cls                 ;Clear the screen

AllDone:
            .EXIT
Mouse3      ENDP


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


; The following routine hides the mouse cursor

HideMouse   PROC    USES    AX
            MOV     AX,2
            INT     33h
            RET
HideMouse   ENDP


; The following routine displays the mouse cursor

ShowMouse   PROC    USES    AX
            MOV     AX,1
            INT     33h
            RET
ShowMouse   ENDP


; The following routine clears the screen
; Uses the attribute of the character at the current cursor position
;      as the attribute for the cleared screen

Cls         PROC    USES AX BX CX DX
            MOV     AH,8                ;Read character and attribute
            MOV     BH,VidPage
            INT     10h
            MOV     BH,AH               ;Put attribute in right place

            MOV     AH,6                ;Scroll window up
            MOV     AL,0                ;Scroll full screen
            MOV     CX,0                ;Upper left corner of screen
            MOV     DH,24               ;Bottom right
            MOV     DL,79
            INT     10h
            RET
Cls         ENDP


; The following routine updates the coordinate information on the screen
; Pass X position in CX and Y position in DX

Coords      PROC    USES AX BX CX DX

            CALL    HideMouse           ;Hide the mouse cursor
            PUSH    DX                  ;Store Y position
            PUSH    CX                  ;Store X position

            MOV     DH,21               ;Row 21
            MOV     DL,0                ;To the left
            MOV     BH,VidPage
            MOV     AH,2                ;Set cursor position
            INT     10h

            MOV     DX,OFFSET XPos      ;Point to positioning message
            MOV     AH,9                ;Display a string using DOS
            INT     21h
            POP     AX                  ;Get back X position
            CALL    PrtDec              ;Go print it

            MOV     DX,OFFSET YPos      ;Point to positioning message
            MOV     AH,9                ;Display a string using DOS
            INT     21h
            POP     AX                  ;Get back Y position
            CALL    PrtDec              ;Go print it

            MOV     DX,OFFSET Blank     ;Blank string
            MOV     AH,9                ;Display a string using DOS
            INT     21h

            CALL    ShowMouse           ;OK to redisplay mouse cursor
            RET
Coords      ENDP


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


; The following routine displays the word last clicked on by the mouse
; Word is assumed to be in BUFFER
; If there is no word (starts with a space), then a message is displayed

DispWord    PROC    USES AX BX DX
            CALL    HideMouse           ;Hide the mouse cursor
            MOV     DH,22               ;Row 22
            MOV     DL,0                ;To the left
            MOV     BH,VidPage
            MOV     AH,2                ;Set cursor position
            INT     10h

            MOV     DX,OFFSET NoWord    ;Assume no word there
            MOV     AL,Buffer           ;Get character
            CMP     AL,' '              ;Is it a space?
            JE      DW1                 ;Yes, so don't display

            MOV     DX,OFFSET WordMsg   ;Point to display string
DW1:        MOV     AH,9                ;Display a string using DOS
            INT     21h

            CALL    ShowMouse           ;Display the cursor again
            RET
DispWord    ENDP


; The following routine displays the character coordinates when the left
;    mouse button is pressed.  Assumed that ClickX and ClickY are set

Position    PROC    USES AX BX CX DX

            CALL    HideMouse           ;Hide the mouse cursor
            MOV     DH,23               ;Row 23
            MOV     DL,0                ;To the left
            MOV     BH,VidPage
            MOV     AH,2                ;Set cursor position
            INT     10h

            MOV     DX,OFFSET XCPos     ;Point to positioning message
            MOV     AH,9                ;Display a string using DOS
            INT     21h
            MOV     AH,0
            MOV     AL,ClickX           ;Get X position
            CALL    PrtDec              ;Go print it

            MOV     DX,OFFSET YCPos     ;Point to positioning message
            MOV     AH,9                ;Display a string using DOS
            INT     21h
            MOV     AH,0
            MOV     AL,ClickY           ;Get Y position
            CALL    PrtDec              ;Go print it

            MOV     DX,OFFSET Blank     ;Blank string
            MOV     AH,9                ;Display a string using DOS
            INT     21h

            CALL    ShowMouse           ;Display mouse cursor
            RET
Position    ENDP


; The following clears the buffer area

ZapBuf      PROC    USES CX ES DI
            PUSH    DS
            POP     ES
            MOV     DI,OFFSET Buffer
            MOV     CX,BufLen
ZB1:        MOV     BYTE PTR [DI],' '
            INC     DI
            LOOP    ZB1
            RET
ZapBuf      ENDP


; The following transfers the word at the current cursor location
; to the buffer area

Xfer        PROC    USES AX BX CX DX

            CALL    ZapBuf
            MOV     FirstChar,1         ;Set flag for first character
            MOV     AL,ClickX
            MOV     CurX,AL
            MOV     AL,ClickY
            MOV     CurY,AL
            CALL    HideMouse           ;Hide the mouse cursor

XF1:        MOV     AH,2                ;Make sure set to CurX/CurY
            MOV     BH,VidPage
            MOV     DH,CurY
            MOV     DL,CurX
            INT     10h

            MOV     AH,8                ;Read character at cursor
            MOV     BH,VidPage
            INT     10h
            CMP     AL,0                ;Was it a space?
            JE      XF5                 ;Yes, found beginning
            CMP     AL,'.'              ;Was it punctuation?
            JE      XF5                 ;Yes, found beginning

            CMP     CurX,0              ;Are we at position 0?
            JNE     XF2                 ;No, continue
            CMP     CurY,0              ;Are we at upper left?
            JE      XF7                 ;Yes, assume found word start
            DEC     CurY                ;No, so previous row
            MOV     CurX,80             ;Point to right side of screen
XF2:        DEC     CurX
            MOV     FirstChar,0         ;No longer on first character
            JMP     XF1                 ;Continue looking

XF5:        CMP     FirstChar,0         ;On first character?
            JNE     XF7                 ;Yes, no need to increment
            INC     CurX                ;Point to space after separator
            CMP     CurX,80             ;Past right side?
            JNE     XF6
            MOV     CurX,0              ;Point to left side
            INC     CurY
XF6:        MOV     AH,2                ;Set cursor position
            MOV     BH,VidPage
            MOV     DH,CurY
            MOV     DL,CurX
            INT     10h

XF7:        MOV     BX,OFFSET Buffer    ;Point to start of buffer
            MOV     CX,BufLen           ;Length of buffer

XF8:        PUSH    BX                  ;Save position in buffer
            MOV     AH,8                ;Read character at cursor
            MOV     BH,0                ;Assume page 0
            INT     10h
            POP     BX                  ;Get back buffer position
            CMP     AL,0                ;Was it a space?
            JE      XFDone              ;Yes, found end
            CMP     AL,'.'              ;Was it punctuation?
            JE      XFDone              ;Yes, found end
            MOV     [BX],AL             ;Store character
            INC     BX                  ;Point to next one

            INC     CurX                ;Point to next screen location
            CMP     CurX,80             ;Past right side?
            JNE     XF9
            MOV     CurX,0              ;Point to left side
            INC     CurY
XF9:        PUSH    BX                  ;Save position in buffer
            MOV     AH,2                ;Set cursor position
            MOV     BH,0                ;Assume page 0
            MOV     DH,CurY
            MOV     DL,CurX
            INT     10h

            POP     BX                  ;Get back buffer position
            DEC     CX                  ;Counter adjustment
            JNZ     XF8                 ;Keep going as far as we can

XFDone:     MOV     AH,2                ;Set cursor position
            MOV     BH,0                ;Assume page 0
            MOV     DH,ClickY
            MOV     DL,ClickX
            INT     10h
            CALL    ShowMouse           ;OK to show mouse cursor again
            RET
Xfer        ENDP

            END
