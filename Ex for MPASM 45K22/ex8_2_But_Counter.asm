;**********************************************************
;*               Ex8-2.ASM
;*  程式將偵測按鍵SW3的狀態，並遞加計數的內容。當計數數值超過四次便反轉燈號
;**********************************************************
			list p=18f45k22		
#include 	<p18f45k22.inc>			; 納入定義檔Include file located at defult directory
;
count_val	equ	.4					; 燈號反轉所需計數數值
;
push_no		equ 0x23					; 儲存計數數值的暫存器位址
;Register for number of button push
;***************************************
;           Program start              *
;***************************************
		org 	0x00			; reset vector
initial:	
		banksel ANSELD
		clrf	ANSELD		; 將PORTD類比功能解除，設定數位輸入腳位
		bcf	ANSELA, 4	; 將RA4類比功能解除，設定數位輸入腳位
					; 將PORTA, RA4腳位設定為訊號輸入
					
		clrf	PORTA, 0		; a=0 for access bank SFR
		bsf	TRISA, 4, 0		; a=0 for access bank SFR
;
		clrf	TRISD, 0		; Set PORTD for LED output	
		clrf	PORTD, 0		; Set PORTD
		movlw	0x0f
		movwf	PORTD, 0
					; 設定TIMER0作為8位元的計數器並使用外部訊號輸入元
		movlw	b'11101000'	; 設定暫存器所需的設定內容
		movwf	T0CON, 0		; 將設定內容存入T0CON暫存器
		clrf 	TMR0L, 0		; 將計數器暫存器TMR0L內容清除為0
;
;************ Main *********************
;
start:
						; 將TIMER0的計數內容與count_val做比較並決定燈號的切換
		movlw	count_val
		subwf	TMR0L, W
		btfss	STATUS, Z, 0
		goto		start
		swapf	PORTD, f, 0
		clrf 	TMR0L, 0
		goto		start
;
			end
