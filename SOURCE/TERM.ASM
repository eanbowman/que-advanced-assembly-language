Page 60,132

Comment |
******************************************************************

File:       TERM.ASM
Author:     Allen L. Wyatt
Date:       6/27/92
Assembler:  MASM 6.0

Purpose:    A mini terminal program.  Displays on the screen all the
            info coming in the modem.  Anything typed is sent to the 
            modem.  Uses interrupt-driven techniques for all
            communications access.  Program is exited when ESC is
            pressed.

Format:     TERM

******************************************************************|

TimeOut     EQU     364                 ;20 seconds (18.2 * 20)
NormWait    EQU     18                  ;1 second
BuffSize    EQU     2048                ;Size of incoming buffer (in bytes)

; The following equates are modem configuration settings
ComInt      EQU     0Bh                 ;COM1/COM3=0Ch, COM2/COM4=0Bh
ComAddr     EQU     2F8h                ;COM1=3F8h, COM2=2F8h, COM3=3E8h, COM4=2E8h
BRDMSB      EQU     0                   ;See book for common BRD values
BRDLSB      EQU     0Ch

; The following equates are for data format settings
DF_N81      EQU     00000011b           ;8 data bits, 1 stop bit, no parity
DF_E71      EQU     00011010b           ;7 data bits, 1 stop bit, even parity

            .MODEL  small
            .STACK                      ;Default 1Kb stack is OK
            .DATA

VectorSeg   DW      0000
VectorOff   DW      0000
XmitCount   DW      0000
CTMax       DW      0000

SetUpMsg    DB      'Setting up modem information ...',13,10,0
MemMsg      DB      'Could not allocate buffer space',13,10,0
RemindMsg   DB      'Press ESC to exit program',13,10,13,10,0

            .CODE
            .STARTUP
Term        PROC

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

            MOV     AH,48h              ;Allocate memory
            MOV     BX,BuffSize/16      ;Paragraphs to request
            INT     21h
            JNC     MemOK               ;No errors
            MOV     SI,OFFSET MemMsg
            CALL    PrtString
            JMP     AllDone

MemOK:      MOV     CS:BuffSeg,AX       ;Store segment address
            CALL    HookIn              ;Go hook interrupt information
            CALL    Cls
            MOV     SI,OFFSET RemindMsg ;Reminder about how to exit
            CALL    PrtString

InputLoop:  MOV     AH,1                ;Check keyboard status
            INT     16h
            JZ      NoKey               ;No key there
            MOV     AH,0                ;Get key
            INT     16h
            CMP     AH,1                ;Was the key escape? (scan code=1)
            JE      AllDone             ;Yes, so exit
            CALL    XmitChar            ;Send the character in AL to modem
            JNC     NoKey               ;No error, so continue
            MOV     DL,'!'              ;Indication there was a timeout
            MOV     AH,02h              ;Output a character
            INT     21h

NoKey:      CALL    BuffChar            ;Go see if anything in buffer to display
            JMP     InputLoop

AllDone:    MOV     ES,CS:BuffSeg
            MOV     AH,49h              ;Release memory block at ES
            INT     21h
            CALL    HookOut
            .EXIT
Term        ENDP


; The following routine hooks in the interrupt routine and sets up the
; data format and communications parameters

HookIn      PROC    USES AX DX SI

            MOV     SI,OFFSET SetUpMsg
            CALL    PrtString

            PUSH    ES
            MOV     AL,ComInt
            MOV     AH,35h              ;Get interrupt vector
            INT     21h
            MOV     VectorOff,BX        ;Store original offset
            MOV     VectorSeg,ES        ;Store original segment
            POP     ES

            MOV     AL,ComInt
            PUSH    DS
            PUSH    CS
            POP     DS
            MOV     DX,OFFSET IntHandler
            MOV     AH,25h              ;Set interrupt vector
            INT     21h
            POP     DS

            CLI
            MOV     DX,ComAddr+3        ;Point to line control register
            MOV     AL,DF_E71
            OUT     DX,AL               ;Send byte
            INC     DX                  ;Point to modem control register
            MOV     AL,00001011b
            OUT     DX,AL               ;Set it for interrupts

            IN      AL,21h              ;Get current contents of interrupt request mask
            AND     AL,11100111b        ;Make sure that both COMs are enabled
            OUT     21h,AL

            MOV     DX,ComAddr+1        ;Point to interrupt enable register
            MOV     AL,00000001b        ;Turn on bit 0
            OUT     DX,AL               ;Set it
            STI

            CALL    SetBRD              ;Go set for desired baud rate
            RET
HookIn      ENDP


; The following routine unhooks the interrupt handler

HookOut     PROC    USES AX DX SI
            MOV     DX,ComAddr+1        ;Point to interrupt enable register
            MOV     AL,0                ;Disable the interrupts
            OUT     DX,AL               ;Set it

            MOV     DX,ComAddr+1        ;Point to interrupt enable register
            MOV     AL,00000000b        ;Turn off all bits
            OUT     DX,AL               ;Set it

            IN      AL,21h              ;Get current contents of interrupt request mask
            OR      AL,00011000b        ;Make sure that both COMs are disabled
            OUT     21h,AL

            PUSH    DS                  ;Hold current data segment
            MOV     DS,VectorSeg        ;Get original segment
            MOV     DX,VectorOff
            MOV     AL,ComInt
            MOV     AH,25h              ;Set interrupt vector
            INT     21h
            POP     DS                  ;Get the data segment back

            RET
HookOut     ENDP


; Routine to check input buffer for info and display it if there

BuffChar    PROC    USES AX DX SI ES
            MOV     SI,CS:Tail
            CMP     SI,CS:Head          ;Any characters there?
            JE      NoInput             ;Nope, so continue

            MOV     ES,CS:BuffSeg       ;Point to buffer area
            CLD
BCLoop:     MOV     DL,ES:[SI]          ;Get character
            INC     SI                  ;Point to next character
            MOV     AH,02h              ;Output character in DL
            INT     21h
            CMP     SI,BuffSize         ;End of buffer?
            JNE     NotAtEnd            ;No, continue
            MOV     SI,0                ;Point to beginning
NotAtEnd:   CMP     SI,CS:Head          ;At end of buffered data yet?
            JNE     BCLoop              ;No, grab another
            MOV     CS:Tail,SI          ;Update pointer

NoInput:    RET
BuffChar    ENDP


; Routine to transmit the character in AL out the rs232 port

XmitChar    PROC    USES AX BX DX
            PUSH    AX                  ;Save character for a moment
            MOV     AH,0
            INT     1Ah                 ;Get clock ticks
            MOV     XmitCount,DX        ;Store ticks for later

XC1:        MOV     DX,ComAddr+5        ;Point to line status register
            IN      AL,DX               ;Get status byte
            TEST    AL,00100000b        ;Test if ready to transmit character
            JNZ     XC2                 ;Yes, so continue
            MOV     BX,XmitCount
            MOV     AX,NormWait         ;Wait 1 second
            CALL    CheckTime           ;Go see if time expired
            JNC     XC1                 ;Time not up, wait in loop
            POP     AX                  ;Get back character
            JMP     XCBad               ;Time up, exit with error

XC2:        POP     AX                  ;Get character back
            MOV     DX,ComAddr          ;Point to port
            OUT     DX,AL
            CLC
            JNC     XCExit
XCBad:      STC
XCExit:     RET
XmitChar    ENDP


; Routine to check if time has elapsed
; Enter with original clock ticks in BX and maximum wait (in ticks) in AX
; Returns with carry set if time is expired; all other registers intact

CheckTime   PROC    USES AX BX CX DX
            MOV     CTMax,AX            ;Store maximum ticks
            MOV     AH,0
            INT     1Ah                 ;Check for timeout
            CMP     BX,DX               ;Check for wrap around
            JG      CT1                 ;Yup, it was there
            SUB     DX,BX               ;Now we have elapsed ticks in DX
            JMP     CT2   
CT1:        MOV     AX,0FFFFh
            SUB     AX,BX
            ADD     DX,AX
CT2:        CMP     DX,CTMax            ;Is our time up?
            JA      TimeUp              ;Yes, so exit accordingly
            CLC                         ;No, no error
            JNC     CTExit
TimeUp:     STC                         ;Set for time up
CTExit:     RET
CheckTime   ENDP


; Set the baud rate divisor at chip level to 2400 baud

SetBRD      PROC    USES AX DX
            MOV     DX,ComAddr+3        ;Point to line control register
            IN      AL,DX               ;Get what is there
            OR      AL,10000000b        ;Going to set bit 7 high
            OUT     DX,AL               ;Send the byte

            DEC     DX                  ;Point to MSB of baud rate divisor
            DEC     DX
            MOV     AL,BRDMSB
            OUT     DX,AL

            DEC     DX                  ;Point to LSB of baud rate divisor
            MOV     AL,BRDLSB
            OUT     DX,AL

            ADD     DX,3                ;Point to line control register
            IN      AL,DX               ;Get what is there
            AND     AL,01111111b        ;Going to set bit 7 low
            OUT     DX,AL               ;Send the byte

            RET
SetBRD      ENDP


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


; Interrupt handler - process byte coming in on serial channel (COM)

IntHandler  PROC    FAR
            PUSH    AX
            PUSH    DX

; The following bit diddling turns off RTS so the modem stops sending info
            MOV     DX,ComAddr+4        ;Point to modem control register
            IN      AL,DX
            AND     AL,11111101b        ;Sets bit 1 to 0 (turn off RTS)
            OUT     DX,AL               ;Set it

            PUSH    DS
            PUSH    ES
            PUSH    DI

            MOV     AX,CS
            MOV     DS,AX
            MOV     ES,BuffSeg
            MOV     DI,Head
            CLD

Receive:    MOV     DX,ComAddr          ;Get COM base address
            IN      AL,DX               ;Get the character
            STOSB                       ;Store character in buffer
            CMP     DI,BuffSize         ;At end?
            JNE     NoWrap              ;No, so continue
            MOV     DI,0                ;Point to start
NoWrap:     MOV     Head,DI

            MOV     DX,ComAddr+2        ;Point to interrupt identification register
            IN      AL,DX               ;Get the value that is there
                                        ;Bit 0 will contain 1 if nothing there
                                        ;Will contain 0 if pending
            TEST    AL,1                ;Is another request pending?
            JZ      Receive             ;Yes, so go handle again

            MOV     AL,20h              ;Send end-of-interrupt code
            OUT     20h,AL

            POP     DI
            POP     ES
            POP     DS

; This turns RTS back on
            MOV     DX,ComAddr+4        ;Point to modem control register
            IN      AL,DX
            OR      AL,00000010b        ;Sets bit 1 to 1
            OUT     DX,AL               ;Set it

            POP     DX
            POP     AX
            IRET

BuffSeg     DW      0000
Head        DW      0000
Tail        DW      0000

IntHandler  ENDP

            END
