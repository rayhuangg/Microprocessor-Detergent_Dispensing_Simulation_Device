;************************************************
;* LAB14-2.ASM                                     *
;* 在LCD第一行顯示 “Welcom to PIC”                  *
;* 在LCD第二行顯示 “Micro-Controller”               *
;************************************************

	list p=18f45k22		
	#include 	<p18f45k22.inc>			; 納入定義檔Include file located at defult directory	
;
; 定義外部函式
	EXTERN	InitLCD, putcLCD, Send_Cmd, L1homeLCD, L2homeLCD, clrLCD

; Define index variables
	Line1_Ind	equ	0x20	; 第一行符號數量暫存器
	Line2_Ind	equ	0x21	; 第二行符號數量暫存器
	L1_char_no	equ .14		; 定義第一行符號數量
	L2_char_no	equ .16		; 定義第二行符號數量暫存器
; Locates startup code @ the reset vector
	org		0x00
	goto	Start

; Locates main code
	org		0x2A
Start

	call	InitLCD
;
	call 	L1homeLCD
	
	BANKSEL	Line1_Ind
	clrf	Line1_Ind
LCD_line1					; 第一行LCD文字符號顯示迴圈
	BANKSEL	Line1_Ind
	rlncf 	Line1_Ind, W		; 將位址指標乘2
	call	Line1
	call	putcLCD

	BANKSEL	Line1_Ind
	incf	Line1_Ind, F			; 每取得一個符號之後，將位址指標遞加1
	movlw	L1_char_no		; 檢查所傳輸的文字符號數量
	subwf	Line1_Ind, W
	btfss	STATUS, Z, 0
	GOTO	LCD_line1
;
	call 	L2homeLCD
	BANKSEL	Line2_Ind
	clrf	Line2_Ind
;
LCD_line2					; 第二行LCD文字符號顯示迴圈
	BANKSEL	Line2_Ind
	rlncf 	Line2_Ind, W		; 將位址指標乘2
	call	Line2
	call	putcLCD

	BANKSEL	Line2_Ind
	incf	Line2_Ind, F			; 每取得一個符號之後，將位址指標遞加1
	movlw	L2_char_no		; 檢查所傳輸的文字符號數量
	subwf	Line2_Ind, W
	btfss	STATUS, Z, 0
	GOTO	LCD_line2

	goto	$

Line1					; 查表函式，第一行所要顯示的文字符號
	ADDWF	PCL, F, 0	; 由工作暫存器取得需要跳躍的行數
	RETLW	'W'
	RETLW	'e'
	RETLW	'l'
	RETLW	'c'
	RETLW	'o'
	RETLW	'm'
	RETLW	'e'
	RETLW	' '
	RETLW	'T'
	RETLW	'o'
	RETLW	' '
	RETLW	'P'
	RETLW	'I'
	RETLW	'C'
;
Line2					; 查表函式，第二行所要顯示的文字符號
	ADDWF	PCL, F, 0	; 由工作暫存器取得需要跳躍的行數
	RETLW	'M'
	RETLW	'i'
	RETLW	'c'
	RETLW	'r'
	RETLW	'o'
	RETLW	'-'
	RETLW	'C'
	RETLW	'o'
	RETLW	'n'
	RETLW	't'
	RETLW	'r'
	RETLW	'o'
	RETLW	'l'
	RETLW	'l'
	RETLW	'e'
	RETLW	'r'
;
	end
