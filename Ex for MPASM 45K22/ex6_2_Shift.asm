;**********************************************************
;*        	Ex6-2.ASM
;*  範例程式示範LED燈號的移動
;*  For 10Mhz OSC 1 Instruction(Ins) = 0.4 us
;*  For 40Mhz OSC 1 Instruction(Ins) = 0.1 us
;**********************************************************
	list p = 18f45k22			;宣告程式使用的微控制器
	#include <p18f45k22.inc>		;將微處理器相暫存器與其他符號的定義檔包含到程式檔中
;;
VAL_500US	equ	.250		; 0.5ms延遲數值。
VAL_10MS	equ	.20			; 10mS延遲數值。
VAL_200MS	equ	.20			; 200mS延遲數值。
;
count_us	equ	0x20		; 定義儲存1us延遲所需數值暫存器
count_10ms	equ	0x21        ; 定義儲存10ms延遲所需數值暫存器
count_200ms	equ	0x22		; 定義儲存200ms延遲所需數值暫存器
;
;***************************************
;           程式開始                   *
;***************************************
			org 	0x00	; 重置向量
;
;************ 主程式*********************
;
start:
			banksel ANSELD
			clrf	ANSELD, BANKED	; 將PORTD類比功能解除，設定數位輸入腳位	

			clrf	TRISD	; 設定PORTD為輸出
			setf	PORTD
;
LED_Shift					; 移動燈號
			movlw	b'00000001'	; 設定輸出值
			movwf	PORTD
			call	delay_200ms	; 時間延遲
			movlw	b'00000010'
			movwf	PORTD
			call	delay_200ms
			movlw	b'00000100'
			movwf	PORTD
			call	delay_200ms
			movlw	b'00001000'
			movwf	PORTD
			call	delay_200ms
			movlw	b'00010000'
			movwf	PORTD
			call	delay_200ms
			movlw	b'00100000'
			movwf	PORTD
			call	delay_200ms
			movlw	b'01000000'
			movwf	PORTD
			call	delay_200ms
			movlw	b'10000000'
			movwf	PORTD
			call	delay_200ms

			goto	LED_Shift	; 迴圈
			

;
;--------- 200 md delay routine --------
;
delay_200ms:	
			movlw	VAL_200MS		 
			movwf	count_200ms
loop_20ms	call 	delay_10ms
			decfsz	count_200ms,f
			goto	loop_20ms
			return
;
;-------- 10 ms delay routine ----------
;
delay_10ms:	
			movlw	VAL_10MS		 
			movwf	count_10ms
loop_ms		call 	delay_500us
			decfsz	count_10ms,f
			goto	loop_ms
			return
;
;-------- 0.5 ms delay routine -----------
;
delay_500us:
			movlw	VAL_500US		 		
			movwf	count_us
dec_loop	nop					; 5 Ins * 0.4us = 2us @ 10Mhz
			nop
			decfsz	count_us,f
			goto 	dec_loop
			return
;	
			end
