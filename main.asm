;
; InnocentLunikaElectronicCalculatorSolution.asm
;
; Created: 2023/05/03 11:04:59 AM
; Author : Innocent Lunika 214502116
;


;*********************************************************************************
;			LABORATORY PROGRAM
;			TITLE: ELECTRONIC CALCULATOR
;			PART A : READING THE KEYPAD AND DISPLAYING THE VALUE ON AN LCD
;			PROGRAM VERSION 1 SEM 1 11TH APRILL 2012
;			AUTHOR: TOM WALINGO
;			CLOCK FREQUENCY 18MHZ
;
;			MODIFIED BY: RAY KHUBONI
;			PROGRAM VERSION 2 SEMESTER 1 9TH APRIL 2014
;
;			MODIFIED BY: LEBOHANG TLADI
;			PROGRAM VERSION 3 SEMESTER 1 26TH APRIL 2023
;****************************************************************************
; HEADER FILES SECTION
.nolist
.include "m32def.inc"
.list
;***************************************************************************
;DEFINITIONS SECTION
.def Temp	= r16
.def Temp1	= r17
.def Temp5	= r18
.DEF temp6 = r26 //**************************ADDED this
.DEF temp7 = r27 //**************************ADDED this
	;KEYPAD LINES AND PORTS
	.def keycode	= r19
	.def input		= r20
	.def lastKey	= r21
	.def Temp2		= r22
	.def Temp3		= r23
	.def operator	= r24
	.def Temp4		= r25
	#define operand_count XL ; avoid redefinitions

	.equ KEYPAD_DATA_PORT	= PORTA
	.equ KEYPAD_PIN_PORT	= PINA
	.equ KEYPAD_DIR			= DDRA

	.equ COL1 = 7 ;keypad output columns
	.equ COL2 = 6
	.equ COL3 = 5
	.equ COL4 = 4
	.equ ROW1 = 3 ;keypad input rows
	.equ ROW2 = 2
	.equ ROW3 = 1
	.equ ROW4 = 0

;LCD LINES AND PORTS: DATA --&gt; PORTD, CONTROL PORTB
.equ LCD_DATA_PORT		= PORTD
.equ LCD_DATA_DIR		= DDRD
.equ LCD_CONTROL_PORT	= PORTB
.equ LCD_CONTROL_DIR	= DDRB

.equ LCD_RS		= 0
.equ LCD_RW		= 1
.equ LCD_E		= 2
.equ LCD_D7		= 7
;***************************************************************************

.CSEG
.org 0x0000

rjmp setup

.org 0x1F
KEYS: .db '1','2','3','-','4','5','6','*','7','8','9',0xFD,'.','0','=','+';

.org 0x0029
msg: .db "Zipho lunika  ",1," ","cal",0;
;***************************************************************************
;CONFIGURATION SECTION
setup:
	ldi Temp,HIGH(RAMEND) ; Set the stack
	out SPH,Temp
	ldi Temp,LOW(RAMEND)
	out SPL,Temp

	ldi Temp, 0XFF ;Configuring LCD port as output(PORTD)
	out LCD_DATA_DIR, Temp
	out LCD_CONTROL_DIR, Temp

	ldi temp, low(RAMEND)
	out SPL, temp
	ldi temp, high(RAMEND)
	out SPH, temp

	rcall Delay_2milli
	rcall LCD_INIT ;initialize the lcd
	rcall delay_2milli
	rcall delay_2milli

	ldi Temp, 0x0F ;keypad setup
	out KEYPAD_DIR, Temp
	ldi Temp, 0xF0
	;out KEYPAD_DATA_PORT, Temp
	ldi keycode, 255
	rcall delay_50milli
	ldi zh, high(msg<<1)
	ldi zl, low(msg<<1)
	clr temp

welcome: ;Displays welcome message
	lpm Temp, z+
	cpi Temp, 0
	breq start
	cpi Temp, 1
	breq newLine
	rcall LCD_DATA
	rjmp welcome

newLine:
	ldi Temp, 0xC0
	rcall LCD_COMMAND
	rjmp welcome

start:
	ldi temp, 0xC
	rcall LCD_COMMAND
	ldi temp5, 255
	ldi operand_count, 0

	clr Temp2
	clr Temp3
	clr operator

loop:
	ldi ZL, low(keys<<1)
	ldi ZH, high(keys<<1) ;reset z to point to key table
	mov lastKey, keycode
	rcall SCAN ;get input
	cpi keycode, 20
	breq loop
	cp keycode, lastKey ;button must be released
	breq loop

	ldi temp1, 255
	cpse temp5, temp1 ; clear the screen on first key press
	rjmp continue
	rcall clear_screen

continue:
	add ZL, keycode ; Decoding!!!!
	lpm temp, z
	mov temp1, temp
	rcall LCD_DATA ;input to screen
	;handle input here
	mov Input, temp1
	andi temp1, 0x0F
	cpi temp1, 10
	BRLO handle_digit
	BRSH handle_operator

handle_digit: ;if input is a digit
	andi Input, 0x0F ;clear high nibble (so it&#39;s a pure value)
	ldi temp, 10
	cpi operand_count, 1
	breq save_op2

save_op1:
	mul Temp2, temp
	ldi temp1, 0
	cpse r1, temp1
	rjmp overflow_error ;if it overflows 8bit value limit
	mov Temp2, r0
	add Temp2, input
	BRCS overflow_error ;if it overflows 8bit value limit
	rjmp loop

save_op2:
	mul Temp3, temp
	ldi temp1, 0
	cpse r1, temp1
	rjmp overflow_error ;if it overflows 8bit value limit
	mov Temp3, r0
	add Temp3, input
	BRCS overflow_error ;if it overflows 8bit value limit
	rjmp loop
handle_operator: ;if input is an operator
	cpi operand_count, 1 ;if on the first operand, the operator must be saved and waitfor second operand
	breq second_operand

first_operand:
	inc operand_count
	mov operator, input
	rjmp loop

second_operand:
	;if it's anything other than '=', give error
	cpi input, 0x3D
	breq calculate
	rjmp overflow_error

calculate:
	cpi operator, 0x2A
	breq multiplication
	cpi operator, 0x2B
	breq addition
	cpi operator, 0x2D
	breq subt
	cpi operator, 0xFD
	breq division
	calc:
	ldi temp, 0xC0
	rcall LCD_COMMAND
	rcall DELAY
	rcall DELAY
	ldi temp, 0x7E
	rcall LCD_DATA
	clr Temp2
	clr Temp3
	clr operand_count
calc_loop:
	mov lastKey, keycode
	rcall SCAN ;get input
	cpi keycode, 20
	breq calc_loop
	cp keycode, lastKey ;button must be released
	breq calc_loop
	ldi temp, 0x01
	rcall LCD_COMMAND
	ldi keycode, 255
	rjmp setup

subt: rjmp subtraction

overflow_error: ;if there is an overflow
	;display error, wait for button press, then reset
	rcall clear_screen
	ldi temp, 'e'
	rcall LCD_DATA
	ldi temp, 'r'
	rcall LCD_DATA
	ldi temp, 'r'
	rcall LCD_DATA
	ldi temp, 'o'
	rcall LCD_DATA
	ldi temp, 'r'

	rcall LCD_DATA
	overflow_error_loop:
	mov lastKey, keycode
	rcall SCAN ;get input
	cpi keycode, 20
	breq overflow_error_loop
	cp keycode, lastKey ;button must be released
	breq overflow_error_loop
	ldi temp, 0x01
	rcall LCD_COMMAND
	ldi keycode, 255
	rjmp setup

;********************	Missing Code Starts Here	********************
;		Move your your results to ans
/*						Multiplication Subroutine					  */
multiplication:
mul temp2, temp3 ; perform multiplication and store the result in r1:r0
mov temp4, r0 ; move the lower byte of the result to temp4
	rcall DISPLAY_ANS
	rjmp calc

/*						Addition Subroutine							 */
addition:
	/*		missing code for Addition		*/
		add temp2, temp3 ; add the two operands and store the result in temp2
mov temp4, temp2 ; move the result to temp4
//ldi temp4, 42;
	rcall DISPLAY_ANS
	rjmp calc
	/*						division Subroutine							*/
division:
	clr temp1 ;remainder
	clr temp5 ;counter (quotient)*/
	mov temp1, temp2;
   L2:  INC temp5
	 SUB temp1, temp3;
	 BRCC L2	;branch if C is zero
	 DEC temp5 ;ONCE TOO MANY
	 ADD temp1, temp3 ; ADD BACK TO IT
	 mov temp4, temp5;

	
	/*		missing code for division	.1	*/
	
	rcall DISPLAY_ANS
	rjmp calc
div8: 
	clr temp1 ;remainder
	clr temp5 ;counter (quotient)*/
	mov temp1, temp2;
L1:  INC temp5
	 SUB temp1, temp3;
	 BRCC L1	;branch if C is zero
	 DEC temp5 ;ONCE TOO MANY
	 ADD temp1, temp3 ; ADD BACK TO IT
	 mov temp4, temp5;
	 ret;

d8:
	/*		missing code for division	.1	*/

div_done:
	/*		missing code for division	.1	*/
//	ret

/*						Subtruction Subroutine					  */
subtraction:
	/*		missing code for Subtruction		*/
	sub temp2, temp3 ; subtract temp3 from temp2 and store the result in temp2
mov temp4, temp2 ; move the result to temp4

	rcall DISPLAY_ANS
	rjmp calc

;********************	Missing Code Ends Here	********************

DISPLAY_ANS: ;format and display the answer
	clr operator
	cpi Temp4, 0
	brne format
	ldi temp, 0x30
	rcall LCD_DATA
	rjmp display_done
format:
	mov Temp2, Temp4
	ldi Temp3, 10
	rcall div8
	inc operator
	push temp1 ;push remainder
	cpi Temp4, 0; Wierd line
	breq display_num
	rjmp format
display_num:
	cpi operator, 0
	breq display_done
	dec operator
	pop temp
	ldi temp1, 0x30 ;
	add temp, temp1 ; converts to ascii!
	rcall LCD_DATA
	rjmp display_num
display_done:
	ret

; LCD Subroutines
clear_screen: ;clears the screen
	ldi temp, 0x01
	rcall LCD_COMMAND
	rcall DELAY_2milli
	rcall DELAY_2milli
	ldi temp, 0xF
	rcall LCD_COMMAND
	clr temp5
ret

LCD_INIT:
	ldi Temp, $38
	rcall LCD_COMMAND
	ldi Temp, $0F
	rcall LCD_COMMAND
	ldi Temp, $01
	rcall LCD_COMMAND
	ldi Temp, $06
	rcall LCD_COMMAND
	Ret

LCD_COMMAND:
	out LCD_DATA_PORT, Temp
	cbi LCD_CONTROL_PORT, LCD_RS
	cbi LCD_CONTROL_PORT, LCD_RW
	sbi LCD_CONTROL_PORT, LCD_E
	nop

	nop
	cbi LCD_CONTROL_PORT, LCD_E
	ldi temp, 0x00
	out LCD_DATA_PORT, Temp
	rcall LCD_BUSY
	Ret

LCD_DATA:
	out LCD_DATA_PORT, Temp
	sbi LCD_CONTROL_PORT, LCD_RS
	cbi LCD_CONTROL_PORT, LCD_RW
	sbi LCD_CONTROL_PORT, LCD_E
	nop
	nop
	cbi LCD_CONTROL_PORT, LCD_E
	ldi temp, 0x00
	out LCD_DATA_PORT, Temp
	rcall LCD_BUSY
	Ret

LCD_BUSY:
	cbi LCD_DATA_DIR, LCD_D7
	cbi LCD_CONTROL_PORT, LCD_RS
	nop
	sbi LCD_CONTROL_PORT, LCD_RW
	nop

CHECK:
	sbi LCD_CONTROL_PORT, LCD_E
	nop
	nop
	nop
	nop
	cbi LCD_CONTROL_PORT, LCD_E
	sbic PORTC, LCD_D7
	rjmp CHECK
	sbi LCD_DATA_DIR, LCD_D7
	Ret

; Scanning keycodes from keypad
SCAN:
	ldi keycode, 20

	ldi Temp, 0xF0
	out KEYPAD_DATA_PORT, Temp
	nop
	ldi Temp, 0xF7
	out KEYPAD_DATA_PORT, Temp
	nop
	rcall DELAY_10milli

	sbis KEYPAD_PIN_PORT, COL1
	ldi keycode, 0
	sbis KEYPAD_PIN_PORT, COL2
	ldi keycode, 1
	sbis KEYPAD_PIN_PORT, COL3
	ldi keycode, 2
	sbis KEYPAD_PIN_PORT, COL4
	ldi keycode, 3
	ldi Temp, 0xFB
	out KEYPAD_DATA_PORT, Temp
	nop
	sbis KEYPAD_PIN_PORT, COL1
	ldi keycode, 4
	sbis KEYPAD_PIN_PORT, COL2
	ldi keycode, 5
	sbis KEYPAD_PIN_PORT, COL3
	ldi keycode, 6
	sbis KEYPAD_PIN_PORT, COL4
	ldi keycode, 7
	ldi Temp, 0xFD
	out KEYPAD_DATA_PORT, Temp
	nop
	sbis KEYPAD_PIN_PORT, COL1
	ldi keycode, 8
	sbis KEYPAD_PIN_PORT, COL2
	ldi keycode, 9
	sbis KEYPAD_PIN_PORT, COL3
	ldi keycode, 10
	sbis KEYPAD_PIN_PORT, COL4
	ldi keycode, 11
	ldi Temp, 0xFE
	out KEYPAD_DATA_PORT, Temp
	nop
	sbis KEYPAD_PIN_PORT, COL1
	ldi keycode, 12
	sbis KEYPAD_PIN_PORT, COL2
	ldi keycode, 13
	sbis KEYPAD_PIN_PORT, COL3
	ldi keycode, 14
	sbis KEYPAD_PIN_PORT, COL4
	ldi keycode, 15
	clr Temp
	out keypad_data_port, temp
	RET

DELAY: ;this is probably a bit short
	ldi Temp1, $ff
Delayloop:
	dec Temp1
	brne Delayloop
	ret

Delay_50micro:
	push temp1

	ldi temp1, 0xF8
	wait_50micro:
	subi temp1, 0x1
	brne wait_50micro
	pop temp1
	ret

Delay_2milli:
	push temp5
	ldi temp5, 0x28
	wait_2milli:
	rcall delay_50micro
	subi temp5, 0x1
	brne wait_2milli
	pop temp5
	ret

delay_10milli:
	push temp5
	ldi temp5, 0xc8
	wait_10milli:
	rcall delay_50micro
	subi temp5, 0x1
	brne wait_10milli
	pop temp5
	ret

delay_50milli:
	push temp5
	ldi temp5, 0x05
	wait_50milli:
	rcall delay_10milli
	subi temp5, 0x1
	brne wait_50milli
	pop temp5
	ret