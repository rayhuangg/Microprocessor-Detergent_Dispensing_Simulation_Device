;**********************************************************
;*               Ex6-1.ASM
;*  範例程式示範時間延遲的LED顯示效果 
;*  For 10Mhz OSC 1 Instruction(Ins) = 0.4 us
;*  For 40Mhz OSC 1 Instruction(Ins) = 0.1 us
;**********************************************************
	list p = 18f45k22			;宣告程式使用的微控制器
	#include <p18f45k22.inc>		;將微處理器相暫存器與其他符號的定義檔包含到程式檔中
;
VAL_US		equ	.147			; 1ms 延遲數值。
VAL_MS		equ	.100
count		equ	0x20			; 定義儲存延遲所需數值暫存器
count_ms		equ	0x21          	; 定義儲存1ms延遲所需數值暫存器
;
;***************************************
;           程式開始 
;***************************************
			org 	0x00			; 重置向量
Initial:	
			banksel ANSELD
			clrf	ANSELD, BANKED	; 將PORTD類比功能解除，設定數位輸入腳位	

			clrf 	TRISD	; 設定PORTD為輸出
			clrf	PORTD	; 清除PORTD
;
;************ 主程式 *********************
;
start:
			incf	PORTD,f		; 遞加PORTD 
			call 	delay_100ms	; 呼叫延遲函式
			goto	start		; 迴圈
;
;-------- 100 ms 延遲函式 ----------
delay_100ms:	
			movlw	VAL_MS		 
			movwf	count_ms
loop_ms		call 	delay_1ms
			decfsz	count_ms,f
			goto	loop_ms
			return
;
;-------- 1 ms延遲函式-----------
delay_1ms:	 
			movlw	VAL_US		 		
			movwf	count
dec_loop	call 	D_short		; 2 Ins +(12 Ins)
			decfsz	count,f		; 1 Ins
			goto 	dec_loop		; 2 Ins, Total=(12+5)*VAL_US Ins
			return
;
;--------  5uS延遲函式 -----------
D_short		call	D_ret			; 4 Ins
			call	D_ret			; 4 Ins
			nop					; 1 Ins
			nop					; 1 Ins
D_ret		return				; 2 Ins, Total=12 Ins =8us (10Mhz)
;	
			end
