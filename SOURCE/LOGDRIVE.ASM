Page 60,132

Comment |
******************************************************************

File:       LOGDRIVE.ASM
Author:     Allen L. Wyatt
Date:       7/26/92
Assembler:  MASM 6.0

Purpose:    Illustrate use of IOCTL function 0Eh and 0Fh.  Always
            forces the desired drive into the logical mapping so
            there is no prompt for "Insert disk for drive ..."

Format:     LOGDRIVE

******************************************************************|

            .MODEL  small
            .STACK                      ;Default 1Kb stack is OK
            .DATA
Msg1        DB      'Press any key to see directory of drive A:',13,10,0
Msg2        DB      'Press any key to see directory of drive B:',13,10,0
Msg3        DB      '*** Drive mapping techniques not being used ***',13,10,0
Msg4        DB      '*** Drive mapping techniques being used ***',13,10,0

OneDrive    DB      'There is only one logical drive assigned to this device'
CRLF        DB      13,10,0

EMsg1       DB      'Could not use IOCTL function 0Eh',0

DirA        DB      'A:\*.*',0
DirB        DB      'B:\*.*',0
NoMore      DB      'No more files on drive',13,10,13,10,0

            .CODE
            .STARTUP
LogDrive    PROC

; Check if running on system where A/B is one drive

            MOV     AH,44h              ;IOCTL
            MOV     AL,0Eh              ;Get logical device map
            MOV     BL,1                ;Drive A:
            INT     21h
            JC      Error1
            CMP     AL,0
            JNE     DoIt                ;Logical drives present, continue
            MOV     SI,OFFSET OneDrive
            CALL    PrtString
            JMP     AllDone

Doit:       CALL    Cls

; First, give an example of what normally happens

            MOV     SI,OFFSET Msg3
            CALL    PrtString
            MOV     SI,OFFSET Msg1
            CALL    KeyMsg              ;Display message, wait for keypress
            MOV     DX,OFFSET DirA
            CALL    ShowDir

            MOV     SI,OFFSET Msg2
            CALL    KeyMsg              ;Display message, wait for keypress
            MOV     DX,OFFSET DirB
            CALL    ShowDir

; Now give an example of what can happen

            MOV     SI,OFFSET Msg4
            CALL    PrtString
            MOV     SI,OFFSET Msg1
            CALL    KeyMsg              ;Display message, wait for keypress
            CALL    MakeItA
            MOV     DX,OFFSET DirA
            CALL    ShowDir

            MOV     SI,OFFSET Msg2
            CALL    KeyMsg              ;Display message, wait for keypress
            CALL    MakeItB
            MOV     DX,OFFSET DirB
            CALL    ShowDir
            JMP     AllDone

Error1:     MOV     SI,OFFSET EMsg1
            CALL    PrtString
AllDone:    .EXIT
LogDrive    ENDP


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

; The following routine displays the directory pointed to by DS:DX

ShowDir     PROC    USES AX BX CX DX SI ES
            MOV     AH,2Fh              ;Determine DTA
            INT     21h
            ADD     BX,1Eh              ;Point to ASCIIZ filename field

            MOV     AH,4Eh              ;Find first
            MOV     CX,37h              ;Show all except volume label
            INT     21h
            JC      Done
SDLoop:     CALL    ShowName            ;Print file name
            MOV     AH,4Fh              ;Find next
            INT     21h
            JNC     SDLoop
Done:       MOV     SI,OFFSET NoMore
            CALL    PrtString
            RET
ShowDir     ENDP

; Print ASCIIZ file name pointed to by ES:BX

ShowName    PROC    USES SI
            PUSH    DS                  ;Save for later
            PUSH    ES                  ;Set up addressing
            POP     DS
            MOV     SI,BX
            CALL    PrtString
            POP     DS
            MOV     SI,OFFSET CRLF
            CALL    PrtString
            RET
ShowName    ENDP

; Force drive to be assumed as A:

MakeItA     PROC    USES AX BX
            MOV     AH,44h              ;IOCTL
            MOV     AL,0Fh              ;Set logical drive map
            MOV     BL,1                ;Drive A:
            INT     21h
            RET
MakeItA     ENDP

; Force drive to be assumed as B:

MakeItB     PROC    USES AX BX
            MOV     AH,44h              ;IOCTL
            MOV     AL,0Fh              ;Set logical drive map
            MOV     BL,2                ;Drive A:
            INT     21h
            RET
MakeItB     ENDP

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

            END
