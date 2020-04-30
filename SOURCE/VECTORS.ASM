Page 60,132

Comment |
******************************************************************

File:       VECTORS.ASM
Author:     Allen L. Wyatt
Date:       3/25/92
Assembler:  MASM 6.0

Purpose:    Display the contents of the interrupt vectors.

Format:     VECTORS

******************************************************************|

            .MODEL  small
            .STACK                      ;Default 1Kb stack is OK
            .DATA
Row         DB      02
Column      DB      00
IntCount    DB      00

Output      DB      'Int '
IntNum      DW      0000
            DB      'h $'
Address     EQU     THIS BYTE
SegNum      DW      0000,0000
            DB      ':'
OffNum      DW      0000,0000
            DB      '$'
Unused      DB      '[unused]$'

TopLine     DB      '                           System Interrupt Vectors$'
Pause       DB      'Press any key to continue...$'

            .CODE
            .STARTUP
Vectors     PROC

            CALL    NewScreen           ;Go do a new screen setup
            MOV     BX,0                ;Point to vector table
            MOV     ES,BX
            MOV     IntCount,0
            MOV     CX,255              ;Want to go all the way round

Vloop:      MOV     AL,IntCount
            CALL    ConHex
            MOV     IntNum,AX
            MOV     AX,ES:[BX]
            CALL    ConHexLong
            MOV     OffNum[0],AX
            MOV     OffNum[2],DX
            INC     BX
            INC     BX
            MOV     AX,ES:[BX]
            CALL    ConHexLong
            MOV     SegNum[0],AX
            MOV     SegNum[2],DX
            INC     BX
            INC     BX
            CALL    ShowVector          ;Go show the vector
            INC     IntCount            ;Next interrupt
            JNE     Vloop               ;Keep going until IntCount = 0 again
            CALL    PagePause           ;Go wait for a keypress
            CALL    Cls                 ;Clear the screen

            .EXIT
Vectors     ENDP


; The following routine displays the individual vectors on the screen

ShowVector  PROC    USES AX BX DX
            MOV     DH,Row
            MOV     DL,Column
            MOV     BH,0                ;Assume page 0
            MOV     AH,2                ;Set cursor position
            INT     10h

            MOV     DX,OFFSET Output    ;Point to start of screen display
            MOV     AH,9                ;Display a string using DOS
            INT     21h
            MOV     DX,OFFSET Address   ;Point to output string
            CMP     SegNum[0],3030h     ;Is this set to zeros?
            JNE     SV1
            CMP     SegNum[2],3030h     ;Is this set to zeros?
            JNE     SV1
            CMP     OffNum[0],3030h     ;Is this set to zeros?
            JNE     SV1
            CMP     OffNum[2],3030h     ;Is this set to zeros?
            JNE     SV1
            MOV     DX,OFFSET Unused    ;Unused vector

SV1:        MOV     AH,9                ;Display a string using DOS
            INT     21h

            INC     Row                 ;Point to next row
            CMP     Row,21              ;At bottom of column?
            JLE     SVok                ;No, continue
            MOV     Row,2               ;Yes, set to top of column
            ADD     Column,20           ;Move to next column
            CMP     Column,80           ;Is the screen full?
            JL      SVok                ;No, continue
            MOV     Column,0            ;Set to left-most column
            CALL    PagePause           ;Go wait for a keypress
            CALL    NewScreen           ;Go do a new screen setup

SVok:       RET
ShowVector  ENDP

; The following routine sets up the standard screen info

NewScreen   PROC    USES AX BX DX
            CALL    Cls                 ;Clear the screen
            MOV     DX,0                ;Set up to print page title
            MOV     BH,0                ;Assume page 0
            MOV     AH,2                ;Set cursor position
            INT     10h
            MOV     DX,OFFSET TopLine   ;Point to start of header
            MOV     AH,9                ;Display a string using DOS
            INT     21h
            RET
NewScreen   ENDP

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

; The following routine pauses at the bottom of a page

PagePause   PROC    USES AX BX DX
            MOV     DH,23               ;Set up to print pause message
            MOV     DL,0
            MOV     BH,0                ;Assume page 0
            MOV     AH,2                ;Set cursor position
            INT     10h
            MOV     DX,OFFSET Pause     ;Point to start of pause message
            MOV     AH,9                ;Display a string using DOS
            INT     21h
            MOV     AH,0                ;Read keyboard character
            INT     16h
            RET
PagePause   ENDP

; The following routine converts the number in AL into an ASCII
; representation of the hex value, with a leading zero.  Value
; is returned in AX as well.

ConHex      PROC    USES CX
            MOV     CL,10h              ;What we will be dividing by
            MOV     AH,0
            DIV     CL                  ;Divide by 16
            ADD     AL,30h
            ADD     AH,30h
            CMP     AL,'9'              ;Is it greater than 9?
            JBE     CA4                 ;No, so continue
            ADD     AL,7                ;Make into hex digit
CA4:        CMP     AH,'9'              ;Is it greater than 9?
            JBE     CA5                 ;No, so continue
            ADD     AH,7                ;Make into hex digit
CA5:        RET
ConHex      ENDP

; The following uses ConHex to convert a long number (AX) into it's ASCII
; equivalent in DX:AX.

ConHexLong  PROC
            PUSH    AX
            CALL    ConHex
            MOV     DX,AX
            POP     AX
            MOV     AL,AH
            CALL    ConHex
            RET
ConHexLong  ENDP

            END
