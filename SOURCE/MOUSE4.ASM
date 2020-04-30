Page 60,132

Comment |
******************************************************************

File:       MOUSE4.ASM
Author:     Allen L. Wyatt
Date:       5/14/92
Assembler:  MASM 6.0

Purpose:    Illustrate differing mouse speeds
            This program assumes you have an EGA or VGA monitor

Format:     MOUSE4

******************************************************************|

            .MODEL  small
            .STACK                      ;Default 1Kb stack is OK
            .DATA
XPos        DB      'X Position: $'
YPos        DB      '     Y Position: $'
Blank       DB      '   $'

Msg         DB      'Click on the controls to affect sensitivity',13,10
            DB      'Click on the right mouse button to exit program$'

Controls    DB      'ษออออออออออออออัออออออออออออออัออออออออออออออป',13,10
            DB      'บ  Horizontal  ณ   Vertical   ณ Double Speed บ',13,10
            DB      'วฤฤฤฤฤฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤฤฤฤฤถ',13,10
            DB      'บ  ',24,'       ',25,'   ณ  ',24
            DB      '       ',25,'   ณ  ',24,'       ',25,'   บ',13,10
            DB      'ศออออออออออออออฯออออออออออออออฯออออออออออออออผ',13,10
            DB      '$'

VidMode     DB      00
Horiz       DW      0000
Vert        DW      0000
DSThresh    DW      0000

THoriz      DW      0000
TVert       DW      0000
TDSThresh   DW      0000
OldX        DW      0000
OldY        DW      0000
ClickX      DB      00
ClickY      DB      00

            .CODE
            .STARTUP
Mouse4      PROC

            CALL    ChkMouse            ;Go see if mouse is there
            JC      AllDone             ;Error, so exit

            MOV     AH,0Fh              ;Get video mode
            INT     10h
            MOV     VidMode,AL          ;Store for later

            MOV     AH,0                ;BIOS set video mode
            MOV     AL,10h
            INT     10h

            CALL    Cls                 ;Clear the screen
            MOV     DX,0                ;Top left corner
            MOV     BH,0                ;Assume page 0
            MOV     AH,2                ;Set cursor position
            INT     10h
            MOV     DX,OFFSET Controls  ;Want to display controls
            MOV     AH,9                ;Display a string using DOS
            INT     21h

            MOV     DH,23               ;Row 23
            MOV     DL,0                ;To the left
            MOV     BH,0                ;Assume page 0
            MOV     AH,2                ;Set cursor position
            INT     10h
            MOV     DX,OFFSET Msg       ;Point to exit message
            MOV     AH,9                ;Display a string using DOS
            INT     21h

            MOV     AX,27               ;Get mouse sensitivity
            INT     33h
            MOV     Horiz,BX            ;And store the parameters
            MOV     Vert,CX             ;    for later reset
            MOV     DSThresh,DX

            MOV     THoriz,BX           ;Store them again in work area
            MOV     TVert,CX
            MOV     TDSThresh,DX

            CALL    DispParms           ;Display initial values
            CALL    ShowMouse           ;Go show mouse cursor

Mloop:      MOV     AX,3                ;Read mouse status
            INT     33h

            CMP     BX,2                ;Was right button pressed?
            JE      Exit                ;Yes, so exit

            CMP     BX,1                ;Was the left button pressed?
            JNE     M5                  ;No, so do positioning
            CALL    LeftButton          ;Go handle left button press

M5:         CMP     CX,OldX             ;Did X position change?
            JNE     Change              ;Yes, so handle
            CMP     DX,OldY             ;Did Y position change?
            JE      Mloop               ;No, so continue loop

Change:     MOV     OldX,CX             ;Store X position
            MOV     OldY,DX             ;Store Y position
            CALL    Coords              ;Display changes
            JMP     Mloop               ;Do it all again

Exit:       MOV     BX,Horiz            ;Get sensitivity parameters
            MOV     CX,Vert
            MOV     DX,DSThresh
            MOV     AX,26               ;Set mouse sensitivity
            INT     33h

            MOV     AX,0                ;Reset mouse
            INT     33h
            MOV     AH,0                ;BIOS set video mode
            MOV     AL,VidMode
            INT     10h
            CALL    Cls                 ;Clear the screen

AllDone:
            .EXIT
Mouse4      ENDP


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


; The following routine handles what goes on when the left mouse
;     button is pressed.  All registers undisturbed on return

LeftButton  PROC    USES AX BX CX DX

            PUSH    CX                  ;Store X position
            MOV     AX,DX               ;Set up for division
            MOV     CL,14
            DIV     CL                  ;AL now contains Y character position
            MOV     ClickY,AL
            POP     AX                  ;Get back X position
            MOV     CL,3                ;Divide by 8
            SHR     AX,CL               ;AL contains X character position
            MOV     ClickX,AL           ;Store for a while

            CMP     ClickY,3            ;Are we on the right row?
            JNE     LBError             ;No, so go handle error

            CMP     ClickX,3            ;Horizontal Up?
            JNE     LB1                 ;No, continue
            CMP     THoriz,100          ;Aready at limit?
            JE      LBError             ;Yes, so exit
            INC     THoriz
            JMP     LBSet

LB1:        CMP     ClickX,11           ;Horizontal Down?
            JNE     LB2                 ;No, continue
            CMP     THoriz,5            ;Already at meaningful bottom limit?
            JE      LBError             ;Yes, so exit
            DEC     THoriz
            JMP     LBSet

LB2:        CMP     ClickX,18           ;Vertical Up?
            JNE     LB3                 ;No, continue
            CMP     TVert,100           ;Aready at limit?
            JE      LBError             ;Yes, so exit
            INC     TVert
            JMP     LBSet

LB3:        CMP     ClickX,26           ;Vertical Down?
            JNE     LB4                 ;No, continue
            CMP     TVert,5             ;Already at meaningful bottom limit?
            JE      LBError             ;Yes, so exit
            DEC     TVert
            JMP     LBSet

LB4:        CMP     ClickX,33           ;DS Up?
            JNE     LB5                 ;No, continue
            CMP     TDSThresh,100       ;Aready at limit?
            JE      LBError             ;Yes, so exit
            INC     TDSThresh
            JMP     LBSet

LB5:        CMP     ClickX,41           ;DS Down?
            JNE     LBError             ;No, so must be an error
            CMP     TDSThresh,5         ;Already at meaningful bottom limit?
            JE      LBError             ;Yes, so exit
            DEC     TDSThresh

LBSet:      MOV     BX,THoriz           ;Get sensitivity parameters
            MOV     CX,TVert
            MOV     DX,TDSThresh
            MOV     AX,26               ;Set mouse sensitivity
            INT     33h

            CALL    DispParms           ;Go display values
            JMP     LBDone

LBError:    MOV     AH,02               ;Output a character
            MOV     DL,07               ;Bell character
            INT     21h
            
LBDone:     RET
LeftButton  ENDP


; The following routine clears the screen
; Uses the attribute of the character at the current cursor position
;      as the attribute for the cleared screen

Cls         PROC    USES AX BX CX DX
            MOV     AH,8                ;Read character and attribute
            MOV     BH,0                ;Assume page 0
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
            MOV     BH,0                ;Assume page 0
            MOV     AH,2                ;Set cursor position
            INT     10h

            MOV     DX,OFFSET XPos      ;Point to positioning message
            MOV     AH,9                ;Display a string using DOS
            INT     21h
            POP     AX                  ;Get back X position
            MOV     BL,0                ;Print as-is
            CALL    PadDec              ;Go print it

            MOV     DX,OFFSET YPos      ;Point to positioning message
            MOV     AH,9                ;Display a string using DOS
            INT     21h
            POP     AX                  ;Get back Y position
            MOV     BL,0                ;Print as-is
            CALL    PadDec              ;Go print it

            MOV     DX,OFFSET Blank     ;Blank string
            MOV     AH,9                ;Display a string using DOS
            INT     21h

            CALL    ShowMouse           ;OK to redisplay mouse cursor
            RET
Coords      ENDP


; The following routine displays the mouse parameters

DispParms   PROC    USES    AX BX DX

            CALL    HideMouse           ;Hide the mouse cursor
            MOV     DH,3                ;Row 3
            MOV     DL,6                ;Column 6
            MOV     BH,0                ;Assume page 0
            MOV     AH,2                ;Set cursor position
            INT     10h
            MOV     AX,THoriz
            MOV     BL,3                ;Take 3 spaces
            CALL    PadDec              ;Go print it

            MOV     DH,3                ;Row 3
            MOV     DL,21               ;Column 21
            MOV     BH,0                ;Assume page 0
            MOV     AH,2                ;Set cursor position
            INT     10h
            MOV     AX,TVert
            MOV     BL,3                ;Take 3 spaces
            CALL    PadDec              ;Go print it

            MOV     DH,3                ;Row 3
            MOV     DL,36               ;Column 36
            MOV     BH,0                ;Assume page 0
            MOV     AH,2                ;Set cursor position
            INT     10h
            MOV     AX,TDSThresh
            MOV     BL,3                ;Take 3 spaces
            CALL    PadDec              ;Go print it

            CALL    ShowMouse           ;OK to redisplay mouse cursor
            RET
DispParms   ENDP


; The following routine prints the value in AX as a decimal number
; The number is right-justified in a field defined by the contents
;     of BL.  If BL is 0, or is a value too small for the width of
;     the number being printed, then the number is printed as-is.

PadDec      PROC    USES AX BX CX DX
            MOV     BH,0                ;Counter for number of digits
            MOV     CX,0FFFFh           ;Ending flag
            PUSH    CX
            MOV     CX,10
PD1:        MOV     DX,0
            DIV     CX                  ;Divide by 10
            ADD     DL,30h              ;Convert to ASCII
            PUSH    DX                  ;Store remainder
            INC     BH                  ;One more digit
            CMP     AX,0                ;Are we done?
            JNE     PD1                 ;No, so continue

            SUB     BL,BH               ;BL now contains spaces to print
            CMP     BL,0                ;No space or below zero?
            JLE     PD3                 ;Yes, so don't do spaces
            MOV     CH,0
            MOV     CL,BL
PD2:        MOV     AH,02h              ;Output a character
            MOV     DL,' '
            INT     21h
            LOOP    PD2

PD3:        POP     DX                  ;Character is now in DL
            CMP     DX,0FFFFh           ;Is it the ending flag?
            JE      PD4                 ;Yes, so continue
            MOV     AH,02h              ;Output a character
            INT     21h
            JMP     PD3                 ;Keep doing it

PD4:        RET
PadDec      ENDP

            END
