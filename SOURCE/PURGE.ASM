Page 60,132

Comment |
******************************************************************

File:       PURGE.ASM
Author:     Allen L. Wyatt
Date:       6/25/92
Assembler:  MASM 6.0

Purpose:    Erase the contents of a file, then delete the file

Format:     PURGE filename.ext

******************************************************************|

            .MODEL  small
            .STACK                      ;Default 1Kb stack is OK
            .DATA
TRUE        EQU     -1
FALSE       EQU     0
BufSize     EQU     32768               ;Use large buffer

WorkDir     DB      129 DUP(0)
Handle      DW      0000
NumBytes    DW      0000
FilePtrH    DW      0000
FilePtrL    DW      0000
Blocks      DW      0000
EOF         DB      00

ErrMsg      DB      'Bad file name, path not found, or access denied',13,10,0
DoneMsg     DB      'File is purged',0
WriteMsg    DB      'This file could not be written to',0
DelMsg      DB      'File has been overwritten, but was not deleted',0
MemMsg      DB      'Sorry, not enough memory could be allocated',13,10
            DB      'for this program',0
BlockMsg1   DB      'There are ',0
BlockMsg2   DB      ' blocks in this file',13,10,0
BlockMsgS   DB      'There is 1 block in this file',13,10,0
StatusMsg   DB      13,'Writing block ',0
ProcDone    DB      '... processing completed',13,10,0
Blank       DB      ' ',0

            .CODE
            .STARTUP
PurgeFile   PROC

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
            MOV     AL,42h              ;Full sharing, read/write access
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
            JNC     MemOK               ;No errors
            MOV     SI,OFFSET MemMsg
            CALL    PrtString
            JMP     AllDone

MemOK:      CALL    FindBlocks          ;Determine number of blocks in file
            MOV     ES,AX               ;Point to memory block for later use
            MOV     EOF,FALSE

DoLoop:     CALL    ReadFile
            CALL    WriteFile
            JC      BadWrite
            CMP     EOF,FALSE
            JE      DoLoop
            JNE     CloseFile
BadWrite:   MOV     SI,OFFSET WriteMsg  ;Error message

CloseFile:  MOV     BX,Handle           ;Get file handle
            MOV     AH,3Eh              ;Close file
            INT     21h
            CMP     EOF,FALSE           ;Was end of file reached?
            JE      Done                ;No, exit with error msg in SI

            MOV     AH,41h              ;Delete file
            MOV     DX,OFFSET WorkDir   ;Point to start of file name
            INT     21h
            MOV     SI,OFFSET DoneMsg
            JNC     Done                ;No error, file was deleted
            MOV     SI,OFFSET DelMsg    ;Point to error message

Done:       PUSH    SI
            MOV     SI,OFFSET ProcDone
            CALL    PrtString
            POP     SI
            CALL    PrtString
            MOV     AH,49h              ;Release memory block at ES
            INT     21h

AllDone:    .EXIT
PurgeFile   ENDP


; The following routine saves the current file pointer location,
; then fills the buffer from the disk file

ReadFile    PROC    USES AX BX CX DX
            MOV     AH,42h              ;Move file pointer
            MOV     AL,01h              ;Offset from current position
            MOV     BX,Handle
            MOV     CX,0                ;Stay where we are
            MOV     DX,0
            INT     21h
            MOV     FilePtrH,DX         ;Store current position
            MOV     FilePtrL,AX

            MOV     AH,3Fh              ;Read file
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

; The following routine fills the buffer with spaces, sets the file
; pointer back to where the last read occurred, and then writes the
; buffer contents to disk

WriteFile   PROC    USES AX BX CX DX
            MOV     CX,NumBytes         ;Only need this many
            MOV     AL,20h              ;Want to use spaces
            MOV     DI,0
            REP     STOSB

            MOV     AH,42h              ;Move file pointer
            MOV     AL,00h              ;From beginning of file
            MOV     BX,Handle
            MOV     CX,FilePtrH         ;Get start of last read
            MOV     DX,FilePtrL
            INT     21h

            MOV     AH,40h              ;Write file
            MOV     CX,NumBytes         ;Writing what was read earlier
            PUSH    DS                  ;Store data segment and point
            PUSH    ES                  ;      it to the right segment
            POP     DS                  ;      for the buffer area
            MOV     DX,0                ;Start of memory block
            INT     21h
            POP     DS
            JC      WriteErr            ;Could not write to file
            CMP     AX,CX               ;Were all bytes written?
            JNE     WriteErr            ;No, so exit with error
            CALL    DoStatus
            CLC
            JNC     WFExit
WriteErr:   STC                         ;Return with error
WFExit:     RET
WriteFile   ENDP

; Print a status message

DoStatus    PROC    USES AX SI
            MOV     SI,OFFSET StatusMsg
            CALL    PrtString
            MOV     AX,Blocks
            CALL    PrtDec
            MOV     SI,OFFSET Blank
            CALL    PrtString
            DEC     Blocks
            RET
DoStatus    ENDP

; Determine the number of blocks in the file

FindBlocks  PROC    USES AX BX CX DX SI
            MOV     AH,42h              ;Find file size
            MOV     AL,02h              ;From end of file
            MOV     BX,Handle
            MOV     CX,0                ;Keep at end
            MOV     DX,0
            INT     21h

            MOV     CX,BufSize
            DIV     CX
            CMP     DX,0
            JE      NoInc
            INC     AX
NoInc:      MOV     Blocks,AX
            CMP     AX,1                ;Only one block?
            JNE     FB1                 ;No, so continue
            MOV     SI,OFFSET BlockMsgS ;Use singular message
            JMP     FB2
FB1:        MOV     SI,OFFSET BlockMsg1
            CALL    PrtString
            CALL    PrtDec
            MOV     SI,OFFSET BlockMsg2
FB2:        CALL    PrtString

            MOV     AH,42h              ;Find file size
            MOV     AL,00h              ;From start of file
            MOV     BX,Handle
            MOV     CX,0                ;Keep at start
            MOV     DX,0
            INT     21h
            RET
FindBlocks  ENDP

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