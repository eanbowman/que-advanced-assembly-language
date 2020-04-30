Page 60,132

Comment |
******************************************************************

File:       SHOWFILE.ASM
Author:     Allen L. Wyatt
Date:       6/25/92
Assembler:  MASM 6.0

Purpose:    Display the contents of a file, one screen at a time

Format:     SHOWFILE filename.ext

******************************************************************|

            .MODEL  small
            .STACK                      ;Default 1Kb stack is OK
            .DATA
TRUE        EQU     -1
FALSE       EQU     0
BufSize     EQU     2048

WorkDir     DB      129 DUP(0)
Handle      DW      0000
NumBytes    DW      0000
EOF         DB      00

Pause       DB      'Press any key to continue...',0
ErrMsg      DB      'Bad file name, path not found, or access denied',13,10,0

            .CODE
            .STARTUP
ShowFile    PROC

            MOV     AL,ES:[80h]         ;Get length of command tail
            CMP     AL,0                ;Is there a command tail?
            JE      Alldone             ;Nope, so exit completely
            CALL    Xfer                ;Go transfer command tail

; The following memory allocation code works because it is known that MASM
; sets DS and SS to the same segment address in the startup code.  Also, ES
; is set to the PSP for the program upon entry.

            MOV     BX,DS               ;Point to start of data segment
            MOV     AX,ES               ;Point to start of PSP
            SUB     BX,AX               ;Number of segments for code & data
            MOV     AX,SP               ;SP is pointing to top of stack area
            MOV     CL,4                ;Dividing by 16
            SHR     AX,CL
            ADD     BX,AX               ;BX=paragraphs needed
            MOV     AH,4Ah              ;Modify memory allocation
            INT     21h

            MOV     AH,3Dh              ;Open file
            MOV     AL,40h              ;Full sharing, read only access
            MOV     DX,OFFSET WorkDir   ;Point to start of file name
            INT     21h
            JNC     FileOpen            ;No error, continue
            MOV     SI,OFFSET ErrMsg    ;Point to message to display
            CALL    PrtString           ;Display the string
            JMP     AllDone

FileOpen:   MOV     Handle,AX           ;Store handle for later
            MOV     AH,48h              ;Allocate memory
            MOV     BX,BufSize/16       ;Paragraphs to request
            INT     21h
            MOV     ES,AX               ;Point to memory block for later use
            MOV     EOF,FALSE
            CALL    Cls

DoLoop:     CALL    ReadFile
            CALL    DispBuffer
            CMP     EOF,FALSE
            JE      DoLoop
            MOV     BX,Handle           ;Get file handle
            MOV     AH,3Eh              ;Close file
            INT     21h

Done:       MOV     AH,49h              ;Release memory block at ES
            INT     21h

AllDone:    .EXIT
ShowFile    ENDP


; The following routine fills the buffer from the disk file
ReadFile    PROC    USES AX BX CX DX
            MOV     AH,3Fh              ;Read file
            MOV     BX,Handle
            MOV     CX,BufSize          ;Get a full buffer
            PUSH    DS                  ;Store data segment and point
            PUSH    ES                  ;      it to the right segment
            POP     DS                  ;      for the buffer area
            MOV     DX,0                ;Start of memory block
            INT     21h
            POP     DS
            JC      ReadErr             ;Could not read from file
            MOV     NumBytes,AX         ;Store number of bytes read
            CMP     AX,CX               ;Were all bytes read?
            JE      RFDone              ;Yes, so exit
SetEOF:     MOV     EOF,TRUE            ;No, so EOF reached
            JMP     RFDone
ReadErr:    CMP     AX,0                ;Was it because EOF was reached
            JE      SetEOF              ;Yes, so set flag
RFDone:     RET
ReadFile    ENDP

; The following routine displays the buffer information.  Assumes
; that ES points to the buffer segment.

DispBuffer  PROC    USES AX DX SI
            MOV     SI,0                ;Point to start of buffer
DB1:        MOV     DL,ES:[SI]          ;Get character
            MOV     AH,02h              ;Output a character
            INT     21h
            MOV     AH,03h              ;Read cursor position
            INT     10h
            CMP     DH,23               ;Rolled over to line 23 yet?
            JNE     DB2                 ;Nope, continue
            CALL    PagePause           ;Yep, so display message
            CALL    Cls                 ;Clear screen
DB2:        INC     SI
            CMP     SI,NumBytes         ;At end of buffer?
            JB      DB1                 ;Nope, so keep going
            RET
DispBuffer  ENDP

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
            MOV     DI,OFFSET ES:WorkDir
X1:         LODSB
            CMP     AL,' '          ;Was it a space?
            JE      X4              ;Yes, so skip it
            STOSB                   ;Store a byte
X4:         LOOP    X1              ;Keep going to the end
            MOV     AL,0
            STOSB                   ;Make sure NUL at end of path
            RET
Xfer        ENDP

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

; The following routine pauses at the bottom of a page

PagePause   PROC    USES AX BX DX SI
            MOV     DH,24               ;Set up to print pause message
            MOV     DL,0
            MOV     BH,0                ;Assume page 0
            MOV     AH,2                ;Set cursor position
            INT     10h
            MOV     SI,OFFSET Pause     ;Point to start of pause message
            CALL    PrtString           ;Display the string
            MOV     AH,0                ;Read keyboard character
            INT     16h
            RET
PagePause   ENDP

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