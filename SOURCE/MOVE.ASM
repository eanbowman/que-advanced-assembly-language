Page 60,132

Comment |
******************************************************************

File:       MOVE.ASM
Author:     Allen L. Wyatt
Date:       6/26/92
Assembler:  MASM 6.0

Purpose:    Full rename, including moving to another directory

Format:     MOVE oldfile.ext newfile.ext

******************************************************************|

            .MODEL  small
            .STACK                      ;Default 1Kb stack is OK
            .DATA

WorkDir1    DB      129 DUP(0)
WorkDir2    DB      129 DUP(0)

Unknown     DB      'Unknown error occurred',0
BadFile     DB      'File not found',0
BadPath     DB      'Path not found',0
NoAccess    DB      'Access denied',0
BadDisk     DB      'File names must be on same disk',0

            .CODE
            .STARTUP
MoveFile    PROC

            MOV     AL,ES:[80h]         ;Get length of command tail
            CMP     AL,0                ;Is there a command tail?
            JE      Alldone             ;Nope, so exit completely
            CALL    Xfer                ;Go transfer command tail
            MOV     AL,WorkDir1         ;Get first byte of first name
            CMP     AL,0                ;Is it NULL?
            JE      AllDone             ;Yes, so exit
            MOV     AL,WorkDir2         ;Get first byte of second name
            CMP     AL,0                ;Is it NULL?
            JE      AllDone             ;Yes, so exit

            PUSH    DS
            POP     ES
            MOV     DX,OFFSET WorkDir1  ;Point to current file name
            MOV     DI,OFFSET WorkDir2  ;Point to new file name
            MOV     AH,56h
            INT     21h
            JNC     AllDone             ;No error, so exit
            MOV     SI,OFFSET Unknown   ;Assume unknown error
            CMP     AX,02h              ;File not found?
            JNE     E1
            MOV     SI,OFFSET BadFile

E1:         CMP     AX,03h              ;Path not found?
            JNE     E2
            MOV     SI,OFFSET BadPath

E2:         CMP     AX,05h              ;No access?
            JNE     E3
            MOV     SI,OFFSET NoAccess

E3:         CMP     AX,11h              ;Not on same disk?
            JNE     E4
            MOV     SI,OFFSET BadDisk

E4:         CALL    PrtString

AllDone:    .EXIT
MoveFile    ENDP


; Transfers the command tail into the work file area, converting it
; into an ASCIIZ string.  Assumes ES points to PSP segment.

Xfer        PROC    USES AX CX SI DI ES DS
            PUSH    ES              ;Swap ES and DS
            PUSH    DS
            POP     ES
            POP     DS
            MOV     SI,80h          ;Point to start of command tail
            MOV     CH,0
            MOV     CL,[SI]         ;Get length of command tail
            INC     SI              ;Point to first character
            MOV     DI,OFFSET ES:WorkDir1
X1:         LODSB
            CMP     AL,' '          ;Was it a space?
            JNE     X2              ;No, so do first name
            LOOP    X1              ;Yes, so get next one
            JCXZ    XDone

X2:         DEC     SI              ;Point back to character
X3:         LODSB
            CMP     AL,' '          ;Was it a space?
            JNE     X4              ;No, so keep stuffing
            DEC     SI              ;Point back at space
            MOV     DI,OFFSET ES:WorkDir2
            JMP     X1
X4:         STOSB
            LOOP    X3
XDone:      RET
Xfer        ENDP

; The following routine prints the ASCIIZ string pointed to by DS:SI

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

            END
