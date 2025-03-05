 ;************************************************
;* ex14-1.ASM                                     *
;* 在LCD第一行顯示 “Welcome to PIC”                  *
;* 在LCD第二行顯示 “Micro-Controller”               *
;************************************************

			list p=18f45k22		
#include 	<p18f45k22.inc>			; 納入定義檔Include file located at defult directory	

;
; 定義外部函式
	EXTERN	InitLCD, putcLCD, Send_Cmd, L1homeLCD, L2homeLCD, clrLCD

; Locates startup code @ the reset vector

;STARTUP	code 
	org		0x00
	goto	Start

; Locates main code
;PROG1	code
Start
	org		0x2A
	call	InitLCD
;
	call 	L1homeLCD
	movlw	'W'
	call	putcLCD
	movlw	'e'
	call	putcLCD
	movlw	'l'
	call	putcLCD
	movlw	'c'
	call	putcLCD
	movlw	'o'
	call	putcLCD
	movlw	'm'
	call	putcLCD
	movlw	'e'
	call	putcLCD
	movlw	' '
	call	putcLCD
	movlw	'T'
	call	putcLCD
	movlw	'o'
	call	putcLCD
	movlw	' '
	call	putcLCD
	movlw	'P'
	call	putcLCD
	movlw	'I'
	call	putcLCD
	movlw	'C'
	call	putcLCD
;
	call 	L2homeLCD
	movlw	'M'
	call	putcLCD
	movlw	'i'
	call	putcLCD
	movlw	'c'
	call	putcLCD
	movlw	'r'
	call	putcLCD
	movlw	'o'
	call	putcLCD
	movlw	'-'
	call	putcLCD
	movlw	'C'
	call	putcLCD
	movlw	'o'
	call	putcLCD
	movlw	'n'
	call	putcLCD
	movlw	't'
	call	putcLCD
	movlw	'r'
	call	putcLCD
	movlw	'o'
	call	putcLCD
	movlw	'l'
	call	putcLCD
	movlw	'l'
	call	putcLCD
	movlw	'e'
	call	putcLCD
	movlw	'r'
	call	putcLCD

	goto	$

	end
