Page 60,132

Comment |
******************************************************************

File:       KEYLOOK2.ASM
Author:     Allen L. Wyatt
Date:       3/21/92
Assembler:  MASM 6.0

Purpose:    Display the status of the keyboard buffer, but use
            Int 15/4F to intercept keys, instead of intercepting
            Int 09.

Format:     KEYLOOK2

******************************************************************|

Head        EQU     01Ah
Tail        EQU     01Ch
Buffer      EQU     01Eh
BuffStart   EQU     080h
BuffEnd     EQU     082h

EscScan     EQU     01h                 ;Keypress to exit program
DelScan     EQU     3Bh                 ;Keypress to delete from buffer
ClrScan     EQU     3Ch                 ;Keypress to clear buffer

            .MODEL  small
            .STACK                      ;Default 1Kb stack is OK
            .DATA
ExitFlag    DB      00
ClearFlag   DB      00
PopFlag     DB      00
OldDiff     DW      0000

Screen      DB      'Pair #   0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F '
            DB      '       ÚÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄ¿'
            DB      'Byte 1 ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³'
            DB      'Byte 2 ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³'
            DB      ' ASCII ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³  ³'
            DB      '       ÀÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÙ'

Info        DB      'Byte 1 is the ASCII value of the keypress, Byte 2 is the'
            DB      'scan code. The ASCII row is the ASCII representation of '
            DB      'Byte 1.  Special keys:       Esc  to Exit               '
            DB      '                             F1   to Grab from buffer   '
            DB      '                             F2   to Clear buffer       '

            .CODE
            .STARTUP

KEYLOOK     PROC

; Check that keyboard buffer is in proper place, exit if not
            PUSH    DS
            MOV     AX,040h             ;Point to BIOS data area
            MOV     DS,AX
            MOV     BX,BuffStart
            CMP     WORD PTR [BX],Buffer ;Does the buffer begin at the default?
            POP     DS                  ;Restore DS before branching
            JE      BufferOK            ;Yes, so continue
NoWay:      JMP     FinalExit

; To make sure that Int 15/4F is usable on this machine, call Int 15/C0.  Bit
; 4 of the byte at offset 05 of the returned table indicates if 15/4F is
; chained from Int 09h.  If Int 15/C0 is not available on the system, then
; 80h or 86h should be returned in AH.

BufferOK:   MOV     AH,0C0h
            INT     15h
            CMP     AH,80h              ;Available?
            JE      NoWay               ;Nope
            CMP     AH,86h              ;
            JE      NoWay               ;Sorry

            MOV     AL,ES:[BX+5]        ;Get the byte
            AND     AL,10h              ;Only interested in bit 4
            CMP     AL,0                ;Is it there?
            JE      NoWay               ;No, so exit

; Everything is OK.  Now hook in the intercept and start the program

            MOV     AL,15h              ;Get keyboard interrupt
            MOV     AH,35h
            INT     21h
            MOV     CS:KeyInt[0],BX     ;Offset address
            MOV     CS:KeyInt[2],ES     ;Segment address

            PUSH    DS                  ;Store data segment
            MOV     AX,CS               ;New segment address
            MOV     DS,AX
            MOV     DX,OFFSET NewInt    ;New offset address
            MOV     AL,15h              ;Change keyboard vector
            MOV     AH,25h              ;to point to new handler
            INT     21h
            POP     DS                  ;Restore data segment

            CALL    Cls                 ;Clear the screen
            CALL    ShowScreen          ;Paint the original screen
            CALL    ShowHex             ;Show the buffer data in hex
            CALL    ShowASCII           ;Show the buffer data in ASCII
            CALL    ShowPtrs            ;Show the buffer pointers

            MOV     AX,040h
            MOV     ES,AX               ;Point to BIOS data area

M1:         MOV     AX,[ES:Head]        ;Get head pointer
            SUB     AX,[ES:Tail]        ;Difference to tail
            CMP     AX,OldDiff          ;Any change?
            JE      M2                  ;No, so continue
            MOV     OldDiff,AX

            CALL    ShowHex             ;Show the buffer data in hex
            CALL    ShowASCII           ;Show the buffer data in ASCII
            CALL    ShowPtrs            ;Show the buffer pointers

M2:         CMP     ExitFlag,1          ;Has the exit key been pressed?
            JE      Exit

            CMP     PopFlag,1           ;Should a key be popped?
            JNE     M3
            CALL    DelKey
            MOV     PopFlag,0

M3:         CMP     ClearFlag,1         ;Should the buffer be cleared?
            JNE     M4
            CALL    ClrBuff
            MOV     ClearFlag,0

M4:         JMP     M1                  ;Do it continually

Exit:       PUSH    DS                  ;Store for later
            MOV     DX,CS:KeyInt[0]     ;Get offset address
            MOV     AX,CS:KeyInt[2]     ;Get segment address
            MOV     DS,AX
            MOV     AL,15h              ;Change keyboard vector
            MOV     AH,25h              ;to point to old interrupt
            INT     21h
            POP     DS                  ;Restore data segment

FinalExit:  CALL    ClrBuff             ;Clear the buffer before leaving
            CALL    Cls                 ;Clear the screen
            .EXIT
KEYLOOK     ENDP


; The following routine displays the static portion of
; the display screen

ShowScreen  PROC    USES AX BX CX DX SI
            MOV     SI,OFFSET Screen    ;Point to start of screen display
            CLD                         ;Make sure the direction flag is OK
            MOV     BH,0                ;Assume page 0 (for next BIOS calls)
            MOV     DH,6                ;Starting on row 7 (increment later)
            MOV     DL,12               ;Always use column 12
            MOV     CX,11               ;Have 11 rows to paint
Paint1:     PUSH    CX                  ;Outside loop
            INC     DH                  ;Point to proper row
            CMP     CX,5                ;Only 5 rows left?
            JNE     P1A                 ;No, continue
            ADD     DH,4                ;Yes, so put some blank rows in
P1A:        MOV     AH,2                ;Set cursor position
            INT     10h
            MOV     AH,0Eh              ;Teletype output
            MOV     CX,56               ;71 characters wide

Paint2:     LODSB                       ;Get character
            INT     10h
            LOOP    Paint2              ;Continue for row
            POP     CX                  ;Get outside loop back
            LOOP    Paint1              ;Continue for all rows
            RET
ShowScreen  ENDP

; The following routine displays on the screen, in hex, the
; contents of the keyboard buffer

ShowHex     PROC    USES AX BX CX DX DS SI
            MOV     DL,17               ;Set column
            MOV     AX,040h
            MOV     DS,AX               ;Point to BIOS data area
            MOV     SI,Buffer           ;Point to keyboard buffer
            MOV     CX,16               ;Have 16 iterations to do

SB1:        LODSB                       ;Get the first byte of the pair
            CALL    ConHex              ;Go convert byte to hex ASCII
            PUSH    AX                  ;Store value
            ADD     DL,3                ;Point to the next column
            MOV     AH,2                ;Set cursor position
            MOV     BH,0                ;Assume video page 0
            MOV     DH,9                ;Set row
            INT     10h
            POP     AX                  ;Get value back
            PUSH    AX                  ;Store it again
            MOV     AH,0Eh              ;Teletype output
            INT     10h
            POP     AX                  ;Get value back
            MOV     AL,AH               ;Move ASCII value into proper place
            MOV     AH,0Eh              ;Teletype output
            INT     10h

            LODSB                       ;Get the second byte of the pair
            CALL    ConHex              ;Go convert byte to hex ASCII
            PUSH    AX                  ;Store value
            MOV     AH,2                ;Set cursor position
            MOV     DH,10               ;Set row
            INT     10h
            POP     AX                  ;Get value back
            PUSH    AX                  ;Store it again
            MOV     AH,0Eh              ;Teletype output
            INT     10h
            POP     AX                  ;Get value back
            MOV     AL,AH               ;Move ASCII value into proper place
            MOV     AH,0Eh              ;Teletype output
            INT     10h
            LOOP    SB1                 ;Do it all again
            RET
ShowHex     ENDP

; The following routine displays on the screen, in ASCII, the
; contents of the keyboard buffer

ShowASCII   PROC    USES AX BX CX DX DS SI
            MOV     DL,18               ;Set column
            MOV     BH,0                ;Assume video page 0
            MOV     AX,040h
            MOV     DS,AX               ;Point to BIOS data area
            MOV     SI,Buffer           ;Point to keyboard buffer
            MOV     CX,16               ;Have 16 iterations to do

SA1:        ADD     DL,3                ;Point to the next column
            MOV     DH,11               ;Set row
            MOV     AH,2                ;Set cursor position
            INT     10h
            LODSB                       ;Get the first byte of the pair
            MOV     AH,0Eh              ;Teletype output
            INT     10h
            INC     SI                  ;Throw away the scan code
            LOOP    SA1                 ;Do it all again
            RET
ShowASCII   ENDP

; The following routine displays on the screen the position of the
; keyboard buffer pointers

ShowPtrs    PROC    USES AX BX CX DX ES
            MOV     AH,6                ;Scroll window up
            MOV     AL,1                ;Only scroll 1 line
            MOV     BH,7                ;Normal white on black
            MOV     CH,13               ;Row
            MOV     CL,0                ;Start at left column
            MOV     DH,13               ;Row
            MOV     DL,79               ;End at right side
            INT     10h

            MOV     AX,040h
            MOV     ES,AX               ;Point to BIOS data area
            MOV     AX,[ES:Head]        ;Get head pointer
            SUB     AX,Buffer           ;Subtract start of buffer location
            SHR     AX,1                ;Divide by two to find right offset
            MOV     BL,3                ;Want to multiply by this
            MUL     BL                  ;Adjust for screen position
            ADD     AL,20               ;Point to screen column

            MOV     DL,AL               ;Put column in proper place
            MOV     DH,13               ;Always will be this row
            MOV     AH,2                ;Set cursor position
            MOV     BH,0                ;Assume page 0
            INT     10h

            MOV     AH,0Eh              ;Teletype output
            MOV     AL,'H'
            INT     10h

            MOV     AX,[ES:Tail]        ;Get tail pointer
            SUB     AX,Buffer           ;Subtract start of buffer location
            SHR     AX,1                ;Divide by two to find right offset
            MOV     BL,3                ;Want to multiply by this
            MUL     BL                  ;Adjust for screen position
            ADD     AL,21               ;Point to screen column

            MOV     DL,AL               ;Put column in proper place
            MOV     DH,13               ;Always will be this row
            MOV     AH,2                ;Set cursor position
            MOV     BH,0                ;Assume page 0
            INT     10h

            MOV     AH,0Eh              ;Teletype output
            MOV     AL,'T'
            INT     10h
            RET
ShowPtrs    ENDP

; The following routine removes a key from the buffer

DelKey      PROC    USES AX
            MOV     AH,1                ;Read keyboard status
            INT     16h
            JZ      DKExit              ;Sorry, no key, so exit
            MOV     AH,0                ;Read keyboard character
            INT     16h
DKExit:     RET
DelKey      ENDP

; The following routine clears the entire keyboard buffer

ClrBuff     PROC    USES AX
CB1:        MOV     AH,1                ;Read keyboard status
            INT     16h
            JZ      CBExit              ;No key, so exit
            MOV     AH,0                ;Read keyboard character
            INT     16h
            JMP     CB1                 ;Go do it all again
CBExit:     RET
ClrBuff     ENDP

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

; The following is the new keyboard interrupt to replace Int 15/4F

NewInt      PROC
            CMP     AH,4Fh              ;Is it the keyboard intercept?
            JE      Process             ;Yes, so continue
            JMP     DWORD PTR CS:KeyInt ;Skip to original interrupt handler

Process:    PUSH    DS
            PUSH    AX
            MOV     AX,SEG ExitFlag     ;Set up addressing
            MOV     DS,AX
            POP     AX                  ;Now get the key back
            PUSH    AX                  ;Store again

            CMP     AL,EscScan          ;Was Esc pressed?
            JNE     NI1
            MOV     ExitFlag,1
            JNC     Ignore              ;Carry is clear from equality

NI1:        CMP     AL,DelScan          ;Want to delete a key?
            JNE     NI2
            MOV     PopFlag,1
            JNC     Ignore              ;Carry is clear from equality

NI2:        CMP     AL,ClrScan          ;Want to clear the buffer?
            JNE     Pass
            MOV     ClearFlag,1
            JNC     Ignore              ;Carry is clear from equality

Pass:       STC                         ;Go ahead, put key in buffer
Ignore:     POP     AX
            POP     DS
            RETF    2                   ;Don't want IRET because it restores
                                        ;the flags register

; The following bytes are for the original Int 15 routine.  It is necessary
; for it to be here because of the JMP hook at the end of the Pass section
; of the new interrupt handler.

KeyInt      DW      0000,0000           ;Address for old keyboard routine

NewInt      ENDP

            END
