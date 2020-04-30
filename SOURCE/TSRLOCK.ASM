Page 60,132

Comment |
******************************************************************

File:       TSRLOCK.ASM
Author:     Allen L. Wyatt
Date:       7/11/92
Assembler:  MASM 6.0

Purpose:    TSR program that monitors the keyboard interrupt.  When
            a user presses a designated function key, the TSR is
            activated.  Allows the user to lock the keyboard until
            a user-defined password is input.

Format:     TSRLOCK

******************************************************************|

            .MODEL  tiny                ;Creating a COM file
            .STACK                      ;Default 1Kb stack is OK
            .DATA

TRUE        EQU     -1
FALSE       EQU     0
DataPort    EQU     60h
StatusPort  EQU     64h
InputFull   EQU     02h
FuncScan    EQU     58h                 ;Using F12
EnvBlock    EQU     2Ch                 ;Offset of pointer in PSP
StkSize     EQU     256                 ;Stack size for TSR

AlreadyIn   DB      'Sorry, TSRLock is already installed$'
Hooked      DB      'TSRLock is now installed$'

            .CODE
            .STARTUP
TSRLock     PROC
            CALL    Hookin              ;Go start the program
TSRLock     ENDP


; The following is the new keyboard interrupt to replace Int 09h

NewKeyInt:  PUSH    CX
            PUSH    BX
            PUSH    AX
            PUSH    DS
            PUSH    ES
            MOV     AX,CS               ;Set up addressing
            MOV     DS,AX

            CLI                         ;Disable interrupts
GetStat:    IN      AL,StatusPort       ;Get keyboard status
            TEST    AL,InputFull        ;Is the coding complete?
            LOOPNZ  GetStat             ;No, so continue waiting
            IN      AL,DataPort         ;Yes, so get code
            STI                         ;Enable interrupts

            AND     AL,7Fh              ;Turn off if a break key
            CMP     AL,FuncScan         ;Was the function key pressed?
            JE      GotFunc             ;Yes, go handle
            CMP     LockState,TRUE      ;Is the keyboard locked?
            JNE     Pass                ;No, so continue
            CMP     TSRActive,TRUE      ;Yes, but are we in the TSR?
            JE      Pass                ;Yes, so let it through
            JNE     Ignore              ;No, so ignore keystroke

GotFunc:    CMP     TSRActive,TRUE      ;Already in TSR?
            JE      Ignore              ;Yes, so ignore key and continue
            MOV     RequestFlag,TRUE    ;Turn on the flag
            JMP     Ignore              ;Drop the key (don't need it)

Pass:       POP     ES
            POP     DS
            POP     AX
            POP     BX
            POP     CX
            JMP     DWORD PTR CS:KeyInt ;Skip to original INT 9 routine

Ignore:     MOV     AL,20h              ;Signify end of interrupt
            OUT     20h,AL
            POP     ES
            POP     DS
            POP     AX
            POP     BX
            POP     CX
            IRET

; The following is the new handler for the idler interrupt
; Only effect on stack is to push one word (return address for DoTSR)

Idler:      PUSHF                       ;Want to save original flags
            CMP     CS:TSRActive,TRUE   ;Already in TSR?
            JE      ExitIdle            ;Yes, so exit
            CMP     CS:RequestFlag,TRUE ;Was TSR requested?
            JNE     ExitIdle            ;No, so exit
            MOV     CS:TSRActive,TRUE
            CALL    DoTSR               ;Yes, go handle TSR
            MOV     CS:TSRActive,FALSE
ExitIdle:   POPF
            JMP     DWORD PTR CS:IdleInt ;Skip to original interrupt handler

; The following is the new handler for the timer interrupt

Timer:      PUSHF                       ;Save original flags
            CALL    DWORD PTR CS:TimeInt ;Call original interrupt handler
            PUSH    AX
            PUSH    BX
            PUSH    DS
            PUSH    ES
            MOV     AX,CS
            MOV     DS,AX
            CMP     TSRActive,TRUE      ;Already in TSR?
            JE      ExitTime            ;Yes, so exit
            CMP     RequestFlag,TRUE    ;Was TSR requested?
            JNE     ExitTime            ;No, so exit
            LES     BX,DWORD PTR InDOSPtr
            CMP     BYTE PTR ES:[BX],0  ;OK to process?
            JNE     ExitTime            ;No, so set exit

            MOV     TSRActive,TRUE
            MOV     AL,20h              ;Signify end of interrupt
            OUT     20h,AL
            CALL    DoTSR               ;Yes, go handle TSR
            MOV     TSRActive,FALSE

ExitTime:   POP     ES
            POP     DS
            POP     BX
            POP     AX
            IRET


; The following is the new handler for the multiplex interrupt
; Implements the following functions:
;        D700h     Installation state    AX=TRUE, Carry clear if installed
;        D701h     Current lock state    AX=TRUE, Carry set if locked
;        D702h     Lock keyboard
;        D703h     Unlock keyboard

Multiplex:  CMP     AH,0D7h             ;Is it our interrupt?
            JE      MPin                ;Yes, so continue
            JMP     DWORD PTR CS:MultiInt ;Skip to original interrupt handler

MPin:       PUSH    DS                  ;Set up addressibility
            PUSH    AX
            MOV     AX,CS
            MOV     DS,AX
            POP     AX

            CMP     AL,0                ;Want to know installation state?
            JNE     MP1                 ;No, so look at next option
            MOV     AX,TRUE
            JMP     RetCC               ;Return with carry clear

MP1:        CMP     AL,1                ;Want to know lock state?
            JNE     MP2
            MOV     AX,LockState
            CMP     AX,TRUE
            JE      RetCS               ;Return with carry set
            JMP     RetCC               ;Otherwise, return with carry clear

MP2:        CMP     AL,2                ;Want to lock keyboard?
            JNE     MP3
            MOV     LockState,TRUE
            MOV     RequestFlag,FALSE   ;No request pending
            JMP     RetCC

MP3:        CMP     AL,3                ;Want to unlock keyboard?
            JNE     MPErr
            MOV     LockState,FALSE
            MOV     RequestFlag,FALSE   ;No request pending

RetCC:      CLC
            JNC     MPDone
MPErr:      MOV     AX,1
RetCS:      STC                         ;Return with error
MPDone:     POP     DS                  ;Restore data segment
            RETF    2                   ;Don't want IRET because it restores
                                        ;the flags register


; The following routine is the main pop-up part of the TSR

DoTSR       PROC
            CLI
            MOV     CS:OrigSS,SS        ;Swap stack information
            MOV     CS:OrigSP,SP
            MOV     SS,CS:StkSeg
            MOV     SP,CS:StkPtr
            STI

            PUSH    AX
            PUSH    BX
            PUSH    CX
            PUSH    DX
            PUSH    SI
            PUSH    DI
            PUSH    DS
            PUSH    ES

            MOV     AX,CS               ;New segment address
            MOV     DS,AX

            MOV     AH,05h              ;Select active display page
            MOV     AL,01h              ;Want to use page 1
            INT     10h
            CALL    Cls                 ;Clear video page 1

            MOV     AX,0D701h           ;Get current state of lock
            INT     2Fh
            JC      TryUnlock           ;Locked, so try to unlock

            MOV     SI,OFFSET LPrompt   ;Point to locking prompt
            CALL    PrtString           ;Display it
            CALL    GetString           ;Go get input
            JCXZ    ResetVid            ;No password, exit early
            MOV     PWlength,CX         ;Store the length
            MOV     AX,CS
            MOV     ES,AX
            CLD
            MOV     SI,OFFSET InBuff
            MOV     DI,OFFSET Password
            REP     MOVSB               ;Move to password field
            MOV     AX,0D702h           ;Lock keyboard
            INT     2Fh
            CALL    ClrBuff             ;Clear the keyboard buffer
            JMP     ResetVid            ;And exit

TryUnlock:  MOV     SI,OFFSET UPrompt   ;Point to unlocking prompt
            CALL    PrtString           ;Display it
            CALL    GetString           ;Go get input
            JCXZ    ResetVid            ;No password, exit early
            CMP     CX,PWlength         ;Same length as current one?
            JNE     BadMatch            ;No, so exit early

            MOV     AX,CS
            MOV     ES,AX
            CLD
            MOV     SI,OFFSET InBuff
            MOV     DI,OFFSET Password
            REPE    CMPSB               ;Compare strings
            JNE     BadMatch            ;Didn't match
            MOV     AX,0D703h           ;Unlock keyboard
            INT     2Fh
            JMP     ResetVid            ;And exit

BadMatch:   MOV     SI,OFFSET BadPass   ;Point to error message
            CALL    PrtString
            MOV     AH,10h              ;Wait for keypress from keyboard
            INT     16h

ResetVid:   MOV     AH,05h              ;Select active display page
            MOV     AL,00h              ;Set back to original page
            INT     10h
            MOV     RequestFlag,FALSE   ;Reset request flag
            POP     ES
            POP     DS
            POP     DI
            POP     SI
            POP     DX
            POP     CX
            POP     BX
            POP     AX

            CLI
            MOV     SS,CS:OrigSS        ;Swap stack information
            MOV     SP,CS:OrigSP
            STI
            RET
DoTSR       ENDP

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

; Clear the screen and home the cursor.  WORKS ON VIDEO PAGE 1 ONLY.

Cls         PROC    USES AX BX CX DX
            MOV     AH,8                ;Read character and attribute
            MOV     BH,1                ;Assume page 1
            INT     10h
            MOV     BH,AH               ;Put attribute in right place

            MOV     AH,6                ;Scroll window up
            MOV     AL,0                ;Scroll full screen
            MOV     CX,0                ;Upper left corner of screen
            MOV     DH,24               ;Bottom right
            MOV     DL,79
            INT     10h

            MOV     DX,0                ;Upper left corner of screen
            MOV     BH,1                ;Assume page 1
            MOV     AH,2                ;Set cursor position
            INT     10h

            RET
Cls         ENDP

; The following routine prints the ASCIIZ string pointed to by DS:SI
; Writes only to video page 1.

PrtString   PROC    USES AX BX SI
            MOV     BH,01h              ;Write only to video page 1
PS1:        MOV     AL,[SI]             ;Get character
            INC     SI                  ;Point to next one
            CMP     AL,0                ;End of string?
            JE      PS2                 ;Yes, so exit
            MOV     AH,0Eh              ;Write text
            INT     10h
            JMP     PS1                 ;Keep doing it
PS2:        RET
PrtString   ENDP


; The following routine gets a string at the current cursor position.
; Accumulates up to 10 characters at InBuff.  String entry halted by
; carriage return.  Will handle backspace character.  Otherwise, only
; printable characters handled.  Returns with CX set to the number of
; characters in the buffer.  All other registers unchanged.  Video
; output is to page 1.

GetString   PROC    USES AX BX DI DS ES
            MOV     AX,CS
            MOV     DS,AX
            MOV     ES,AX
            CLD
            MOV     DI,OFFSET InBuff    ;Point to start of buffer
            MOV     CX,10
            MOV     AL,0
            REP     STOSB               ;Zero out the buffer

            MOV     DI,OFFSET InBuff    ;Point to start of buffer
            MOV     CX,0                ;Character count
GS1:        MOV     AH,10h              ;Get keystroke
            INT     16h
            CMP     CX,10               ;At length limit?
            JE      GS2                 ;Yes, don't accept any other
            CMP     AL,' '              ;Within lower range?
            JL      GS2                 ;No
            CMP     AL,'~'              ;Within upper range
            JA      GS2                 ;No
            STOSB
            INC     CX
            JMP     GS4                 ;Ready for next character
GS2:        CMP     AL,8                ;Was it backspace?
            JNE     GS3                 ;No, continue
            CMP     CX,0                ;Already at left side?
            JE      GS5                 ;Yes, so ignore
            DEC     CX
            DEC     DI
            MOV     BYTE PTR ES:[DI],0  ;Zero it out
            MOV     AH,0Eh              ;Write text
            MOV     BH,1                ;Using video page 1
            INT     10h
            MOV     AL,' '              ;Overwrite with space
            MOV     AH,0Eh              ;Write text
            MOV     BH,1                ;Using video page 1
            INT     10h
            MOV     AL,8                ;Load with backspace again
            JMP     GS4
GS3:        CMP     AL,13               ;Was it C/R?
            JE      GSDone              ;Yes, so exit
            MOV     AL,7                ;Bell character for error
GS4:        MOV     AH,0Eh              ;Write text
            MOV     BH,1                ;Using video page 1
            INT     10h
GS5:        JMP     GS1                 ;Do it all again

GSDone:     RET
GetString   ENDP

; The following data elements are here because they need to be included in
; the memory reserved by the TSR call.  If they are in the normal .DATA area,
; then they are placed AFTER all the code.  That would place them in the
; transient program area, which is discarded.  That would cause a run-time
; error.

RequestFlag DW      0000
TSRActive   DW      0000
KeyInt      DW      0000,0000           ;Address for old keyboard routine
IdleInt     DW      0000,0000           ;Address for old idle routine
TimeInt     DW      0000,0000           ;Address for old timer tick
MultiInt    DW      0000,0000           ;Address for old multiplex interrupt
InDOSPtr    DW      0000,0000           ;Pointer to InDOS flag
LockState   DW      0000
OrigSS      DW      0000                ;Calling program SS:SP
OrigSP      DW      0000
LPrompt     DB      'Enter password to use: ',0
UPrompt     DB      'Enter password to unlock keyboard: ',0
BadPass     DB      13,10,'Incorrect password!  Press a key to continue...',7,0
InBuff      DB      11 DUP (0)
Password    DB      11 DUP (0)
PWlength    DW      0000
Temp        DW      0000                ;Used as temporary area

; The following area is for the stack used by the TSR

StkSeg      DW      0000
StkPtr      DW      0000
TSRStack    DB      StkSize DUP(0)

; This is the routine to hook in the interrupt intercepts

Hookin      PROC
            POP     AX                  ;Throw away the return address

AllOK:      MOV     AX,0D700h           ;Want to get state of TSR
            INT     2Fh
            JC      NotThere            ;Not there, so continue
            CMP     AX,TRUE             ;Is it installed?
            JNE     NotThere            ;No, so continue
            MOV     DX,OFFSET AlreadyIn ;Point to error message
            MOV     AH,09h              ;Display string
            INT     21h
            MOV     AH,4Ch              ;Terminate with code
            MOV     AL,1                ;Error code=1
            INT     21h

NotThere:   MOV     AL,09h              ;Changing this vector
            MOV     DI,OFFSET KeyInt    ;Storing old address here
            MOV     DX,OFFSET NewKeyInt ;New offset address
            CALL    ChgInt              ;Go change it

            MOV     AL,28h              ;Changing this vector
            MOV     DI,OFFSET IdleInt   ;Storing old address here
            MOV     DX,OFFSET Idler     ;New offset address
            CALL    ChgInt              ;Go change it

            MOV     AL,1Ch              ;Changing this vector
            MOV     DI,OFFSET TimeInt   ;Storing old address here
            MOV     DX,OFFSET Timer     ;New offset address
            CALL    ChgInt              ;Go change it

            MOV     AL,2Fh              ;Changing this vector
            MOV     DI,OFFSET MultiInt  ;Storing old address here
            MOV     DX,OFFSET Multiplex ;New offset address
            CALL    ChgInt              ;Go change it

            MOV     AX,0D703h           ;Unlock keyboard
            INT     2Fh
            MOV     TSRActive,FALSE     ;Indicate not in TSR right now

            MOV     AH,34h              ;Get InDOS flag
            INT     21h
            MOV     InDOSPtr[0],BX      ;Offset address
            MOV     InDOSPtr[2],ES      ;Segment address

            MOV     AX,CS
            MOV     StkSeg,AX           ;Store for later use
            MOV     AX,OFFSET TSRStack+StkSize ;Set top of stack
            MOV     StkPtr,AX

            MOV     ES,DS:[EnvBlock]    ;Get environment block segment
            MOV     AH,49h              ;Free memory block (don't need it)
            INT     21h

            MOV     DX,OFFSET Hooked    ;Point to initial message
            MOV     AH,09h              ;Display string
            INT     21h

            MOV     DX,OFFSET Hookin    ;End of resident area
            MOV     CL,4                ;Divide by 16
            SHR     DX,CL               ;No in paragraphs
            INC     DX                  ;Add 1 for good measure
            MOV     AL,0                ;Return code is OK
            MOV     AH,31h              ;TSR function
            INT     21h

Hookin      ENDP

; Set the interrupt pointed to by AL to the address in DS:DX
; Stores the old address in DS:DI

ChgInt      PROC    USES AX DI
            MOV     AH,35h              ;Get interrupt address
            INT     21h
            MOV     DS:[DI],BX          ;Offset address
            MOV     DS:[DI+2],ES        ;Segment address

            MOV     AH,25h              ;Set interrupt vector to DS:DX
            INT     21h
            RET
ChgInt      ENDP

            END
