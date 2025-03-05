;**********************************************************
;*               Ex6-3.ASM
;*  範例程式偵測SW 按鍵狀態輸入控制燈號移動
;**********************************************************
	list p = 18f45k22			;宣告程式使用的微控制器
	#include <p18f45k22.inc>		;將微處理器相暫存器與其他符號的定義檔包含到程式檔中
;
SHIFT_VAL	equ	b'00000001'	; 設定LED初始值
;
VAL_500US	equ	.250			; 0.5ms延遲數值。
VAL_10MS	equ	.20			; 10mS延遲數值。
VAL_200MS	equ	.20			; 200mS延遲數值。
;
count_us	equ	0x20			; 定義儲存1us延遲所需數值暫存器
count_10ms	equ	0x21			; 定義儲存10ms延遲所需數值暫存器
count_200ms	equ	0x22			; 定義儲存200ms延遲所需數值暫存器
;;
;***************************************
;           程式開始                   *
;***************************************
			org 	0x00	; 重置向量
;initial:	
			banksel ANSELD
			clrf	ANSELD, BANKED	; 將PORTD類比功能解除，設定數位輸入腳位
			bcf	ANSELA, 4, BANKED ;; 將RA4類比功能解除，設定數位輸入腳位

			movlw	b'00010000'		; 設定RA4為數位輸入
			iorwf	TRISA, f, 0		; a=0 使用擷取區塊Access Block
;
			clrf	TRISD, 0			; 設定PORTD為輸出	
			clrf	PORTD, 0			; 清除PORTD燈號
;
;************ 主程式*********************
;
start:
			movlw	SHIFT_VAL
			movwf	PORTD
;
test_ra4	btfss	PORTA,4			; 檢查RA4是否觸發
			goto		led_right		; Yes, RA4短路, D0-->D7
;
led_left	rlncf	PORTD,F			; No, RA4 開路, D7-->D0
			call 	delay_200ms 		; Call 時間延遲函式
			goto		test_ra4
;
led_right	rrncf	PORTD,F
			call 	delay_200ms
			goto		test_ra4
;
;
;--------- 200 md delay routine --------
;
delay_200ms:	
			movlw	VAL_200MS		 
			movwf	count_200ms
loop_20ms	call 	delay_10ms
			decfsz	count_200ms,F
			goto		loop_20ms
			return
;
;-------- 10 ms delay routine ----------
;
delay_10ms:	
			movlw	VAL_10MS		 
			movwf	count_10ms
loop_ms		call 	delay_500us
			decfsz	count_10ms,F
			goto		loop_ms
			return
;
;-------- 0.5 ms delay routine -----------
;
delay_500us:
			movlw	VAL_500US		 		
			movwf	count_us
dec_loop	nop
			nop
			decfsz	count_us,F
			goto 	dec_loop
			return
;	
			end
