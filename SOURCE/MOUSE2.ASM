Page 60,132

Comment |
******************************************************************

File:       MOUSE2.ASM
Author:     Allen L. Wyatt
Date:       5/13/92
Assembler:  MASM 6.0

Purpose:    Enable the graphics mouse cursor and display status info
            This program assumes you have an EGA or VGA monitor

Format:     MOUSE2

******************************************************************|

            .MODEL  small
            .STACK                      ;Default 1Kb stack is OK
            .DATA
XPos        DB      'X Position: $'
YPos        DB      '     Y Position: $'
Blank       DB      '   $'

Msg         DB      'Click on the right mouse button to exit program$'

VidMode     DB      00
OldX        DW      0000
OldY        DW      0000

            .CODE
            .STARTUP
Mouse2      PROC

            CALL    ChkMouse            ;Go see if mouse is there
            JC      AllDone             ;Error, so exit

            MOV     AH,0Fh              ;Get video mode
            INT     10h
            MOV     VidMode,AL          ;Store for later

            MOV     AH,0                ;BIOS set video mode
            MOV     AL,10h
            INT     10h

            CALL    Cls                 ;Clear the screen
            MOV     DH,24               ;Row 24
            MOV     DL,0                ;To the left
            MOV     BH,0                ;Assume page 0
            MOV     AH,2                ;Set cursor position
            INT     10h
            MOV     DX,OFFSET Msg       ;Point to exit message
            MOV     AH,9                ;Display a string using DOS
            INT     21h

            CALL    ShowMouse           ;Go show mouse cursor

Mloop:      MOV     AX,3                ;Read mouse status
            INT     33h

            CMP     BX,2                ;Was right button pressed?
            JE      Exit                ;Yes, so exit

            CMP     CX,OldX             ;Did X position change?
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
Mouse2      ENDP


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

            MOV     DH,22               ;Row 22
            MOV     DL,0                ;To the left
            MOV     BH,0                ;Assume page 0
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

            END
