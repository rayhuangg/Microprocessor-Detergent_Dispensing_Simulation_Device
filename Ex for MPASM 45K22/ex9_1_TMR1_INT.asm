;**************************************************************************
;****	Ex9-1.asm
;****	設計一個0.5秒讓 PORTD 的 LED 自動加一的程式      
;**************************************************************************
			list p=18f45k22		
#include 	<p18f45k22.inc>			; 納入定義檔Include file located at defult directory
;
;					       		
TMR1_VAL	EQU		.16384			; Timer1 設定為 500ms 中斷一次 

;********************************************************************
;****	RESET Vector @ 0x0000
;********************************************************************

			org		0x00 		;  
 			bra		Initial
;
			org		0x08		; 高優先中斷的程式向量位址
			bra		Hi_ISRs
;
;********************************************************************
;****	The Main Program start from Here !! 
;********************************************************************

			org		0x2A		; 正常執行程式的開始
Initial:
			call	Init_IO		; 以函式的方式宣告所有的輸出入腳位
			call	Init_Timer1	; 以函式的方式設定TIMER1計時器
;
			bsf		RCON,IPEN		; 啟動中斷優先順序的功能
			bsf		INTCON,GIEH		; 啟動所有的高優先中斷
;
Main:
Null_Loop	goto	Null_Loop		; 無窮迴圈
;
;***********************************************************************
;****		Initial the PORTD for the output port 
;***********************************************************************
Init_IO:
			banksel ANSELD
			clrf	ANSELD, BANKED	; 將PORTD類比功能解除，設定數位輸入腳位
			bcf	ANSELA, 4, BANKED ;; 將RA4類比功能解除，設定數位輸入腳位
				    ; 將PORTA, RA4腳位設定為訊號輸入
			
			clrf	TRISD		; 設定所有的PORTD腳位為輸出
			clrf	PORTD		; 清除所有的PORTD腳位值
			return
;***********************************************************************
;****		Initial Timer1 as a 500ms Timer 
;***********************************************************************
Init_Timer1:
			movlw	B'10001111'		;16位元非同步計數器模式，關閉前除器
			movwf	T1CON			; 是用外部32768Hz震盪器並開啟Timer1
;
			movlw	(.65536-TMR1_VAL)/.256	; 設定計時器高位元組資料
			movwf	TMR1H
			movlw	(.65536-TMR1_VAL)%.256	; 設定計時器低位元組資料
			movwf	TMR1L
;
			bsf		IPR1,TMR1IP,				; 設定Timer1為高優先中斷
			bcf		PIR1,TMR1IF,				; 清除Timer1中斷旗標
			bsf		PIE1,TMR1IE,				; 開啟Timer1中斷功能
;
			return

;***************************************************************************************
;****		ISRs() : 中斷執行函式
;****
;***************************************************************************************
Hi_ISRs		; 高優先中斷執行函式

			bcf		PIR1,TMR1IF			; 清除Timer1中斷旗標
;							   		
			movlw	(.65536-TMR1_VAL)/.256	; 設定計時器高位元組資料
			movwf	TMR1H
			movlw	(.65536-TMR1_VAL)%.256	; 設定計時器低位元組資料
			movwf	TMR1L

			incf	PORTD,F					; PORTD = PORTD + 1;
			retfie	FAST				 	; Return with shadow register
; 
	 	  	END					
 
