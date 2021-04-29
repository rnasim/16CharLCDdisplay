;;Raiyan Nasim
;;ID: 69632419
ORG 0
	JMP main
ORG 3
	jmp ext0ISR
ORG 0BH
	JMP timer0ISR
;; define E and RS signals
E EQU P3.1
RS EQU P3.3

ORG 30H
; initialise the display 
; see instruction set for details
main:
	ACALL LCD_INIT
	
	SETB IT0	;set external 0 interrupt as edge-activated
	SETB EX0 	;enable external 0 interrupt
	SETB EA 	;set the global interrupt enable bit
	
	MOV TMOD, #01H	; timer 0 as 8bit
Timer:
	MOV TH0, #0DBH	
	MOV TL0, #0FFH ; 10ms
	SETB TR0
	SETB ET0		; enable timer 0 interrupt
LOOP: 
	JNB TF0, LOOP
	CLR TR0
	CLR TF0
	SJMP Timer
	
	CLR RS		; clear RS - indicates that instructions are being sent to the module

	MOV P1,#38H ;; 0011 1000 Set Interface data length to 8 bits, 2 line, 5x7 character font

	CALL PulseE

; entry mode set
; 
	MOV P1,#06H 		;; 0000 0110  set to increment with no shift

	CALL PulseE		

; display on/off control

	MOV P1,#0FH			;; 0000 1111  display  on, the cursor on and blinking  on

	Call PulseE
	
; send data



finish:
			JMP $					; loop forever ($ means the same address)
;timers
timer0ISR:	;starts an ADC Conversion
	CLR P3.6	;clear ADC WR line
	SETB P3.6	;set it so the positive edge triggers the conversion
	RETI		;return from interrupt

ext0ISR:		;responds to ADC conversion complete interrupt
	CLR P3.7 	;clear the ADC RD line - this enables the data lines
	MOV A,P2	;take the data from the ADC on P2 and send it to the DAC data lines on 
	CALL CONVERSION
	;scaling R5, R6 and R7
	CLR A
	MOV A, R7
	ADD A, R7
	CJNE  A, #09H,NOTEQUAL ; equal code goes here, then branch out
	JMP DONE;JMP to done if it's not 9
	NOTEQUAL:
		JC LESSTHAN; less than code goes here, then branch out
	GREATER:
		; greater code goes here
		ADD A, #06H ;scale the value if greater than 9
		SETB C
		JMP DONE
	LESSTHAN:
		CLR C
	DONE:
	ANL A, #0FH; take only the right value E.G. if 14 then only 4 in A
	MOV R7, A ;store it back to R7
	;Repeat for R6
	CLR A
	MOV A, R6
	ADDC A, R6
	CJNE  A,#09H,NE ; equal code goes here, then branch out
	JMP COMPLETE
	NE:
		JC LT; less than code goes here, then branch out
	GR:
		; greater code goes here
		ADD A, #06H ;scale the value if greater than 9
		SETB C
		JMP COMPLETE
	LT:
		CLR C
	COMPLETE:
	ANL A, #0FH
	MOV R6, A
	;Repeat for R5
	CLR A
	MOV A, R5
	ADDC A, R5
	CJNE  A,#09H,N ; equal code goes here, then branch out
	JMP DONSO
	N:
		JC L; less than code goes here, then branch out
	G:
		; greater code goes here
		ADD A, #06H ;scale the value if greater than 9
		SETB C
		JMP DONSO
	L:
		CLR C
	DONSO:
	ANL A, #0FH
	MOV R5, A

	CALL PRINT
	SETB P3.7	;disable the ADC data lines by setting RD
	RETI		;return from interrupt

;; Library of LCD functions called above
CONVERSION:
	MOV B,#0AH;Load B with AH = 10D
	DIV AB ;Divide A with B
	MOV R7,B;Store LS portion
	MOV R1,A;Store the remainder

	MOV B, #0AH;Load B with AH = 10D
	DIV AB ;Divide A with B
	MOV R6,B;Store the remainder
	MOV R2,A;Store the Middle portion

	MOV B, #0AH;LoadB with AH = 10D
	DIV AB ;Divide A with B
	MOV R5,B;Store the MS portion
	MOV R3,A;Store the remainder


PRINT: 
	SETB RS	; sending data to module
	MOV R1, #4	;limit the number of chars in screen
	MOV A, R5	;move the most significant bit in R5 to A
	ADD A, #48	;ASCII conversion
	CALL sendCharacter ; send it to LCD

	MOV A, #46	;move '.' to A
	CALL sendCharacter ; send it to LCD

	MOV A, R6	;move the middle bit in R6 to A
	ADD A, #48	;ASCII conversion
	CALL sendCharacter ; send it to LCD

	MOV A, R7	;move the least significant bit in R7 to A
	ADD A, #48	;ASCII conversion
	CALL sendCharacter ; send it to LCD
	CALL BEGINING
	CALL CMD	;clear LCD
	
LCD_INIT:
	MOV A, #38H
	ACALL CMD
	MOV A, #06H
	ACALL CMD
	MOV A, #0FH
	ACALL CMD
	RET	
CMD: ;clearing display
	CLR RS		;clear display
	MOV P1, A; move P1 to home
	CALL PulseE	;pulse LCD
	RET		;return
sendCharacter:
	MOV P1,A
	Call PulseE
	RET
BEGINING:
	MOV R3, #3H
	MOV A, #80H
	ACALL CMD
delay:
	MOV R0, #50			;;delay loop to make sure LCD module has enough to execute command following the Enable Pulse
	DJNZ R0, $
	RET

PulseE:
	SETB E 				; negative edge on E
	CLR E
	CALL delay
	RET


