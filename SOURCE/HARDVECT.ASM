; This code is used to change the keyboard interrupt vector directly

            PUSH    ES
            PUSH    DS
            MOV     AX,CS               ;Point to current code segment
            MOV     DS,AX
            MOV     AX,0                ;Point to the vector table
            MOV     ES,AX
            MOV     BX,24h              ;Point to the keyboard interrupt
            MOV     AX,OFFSET NewInt    ;Get offset of new routine
            CLI                         ;Disable interrupts
            MOV     ES:[BX],AX          ;Put offset in place
            MOV     AX,SEG NewInt       ;Get segment of new interrupt
            INC     BX
            INC     BX
            MOV     ES:[BX],AX          ;Put segment in place
            STI                         ;Enable interrupts again
            POP     DS
            POP     ES
