;**********************************************************
;*               Ex8_4.ASM
;*  程式將偵測按鍵SW3的狀態，並遞加計數的內容。
;*  當計數數值超過四次利用中斷反轉燈號
;**********************************************************
			list p=18f45k22		
#include 	<p18f45k22.inc>			; 納入定義檔Include file located at defult directory
;
count_val	equ	(.256-.4)		; 燈號反轉所需計數數值
;
push_no		equ 0x23			; 儲存計數數值的暫存器位址
;Register for number of button push
;***************************************
;           Program start              *
;***************************************
		org 	0x00			; reset vector
		nop						; Reserve for MPLAB-ICD
		goto	initial			; 程式執行跳換到標籤initial的位址
ISR								; 中斷執行函式
		org		0x08			; 程式由位址0x08的程式記憶體開始
		swapf	PORTD, f, 0		; 切換發光二極體、
		movlw	count_val		; 重新載入設定值到TIMER0計數器
		movwf 	TMR0L, 0
		bcf		INTCON, TMR0IF	; 清除中斷旗標
		retfie					; 由中斷返回正常程式執行
	
		org		0x2A			; 正常程式由位址0x2A的程式記憶體開始
initial:	
		banksel ANSELD
		clrf	ANSELD, BANKED	; 將PORTD類比功能解除，設定數位輸入腳位
		bcf	ANSELA, 4, BANKED ;; 將RA4類比功能解除，設定數位輸入腳位
				; 將PORTA, RA4腳位設定為訊號輸入
				
		clrf	PORTA, 0		; a=0 for access bank SFR
		bsf		TRISA, 4, 0		; a=0 for access bank SFR
;
		clrf	TRISD, 0		; Set PORTD for LED output	
		clrf	PORTD, 0		; Clear PORTD
		movlw	0x0f
		movwf	PORTD, 0
								; 設定TIMER0作為8位元的計數器並使用外部訊號輸入源
		movlw	b'11101000'		; 設定暫存器所需的設定內容
		movwf	T0CON, 0		; 將設定內容存入T0CON暫存器
		clrf 	TMR0L, 0		; 將計數器暫存器TMR0L內容清除為0

		bcf		RCON, IPEN		; 關閉中斷優先順序設定位元
		bsf		INTCON, T0IE	; 開啟TIMER0計數器中斷功能
		bsf		INTCON, GIE		; 開啟全域中斷功能控制位元

		movlw	count_val		; 載入設定值到TIMER0計數器
		movwf 	TMR0L, 0
;
;************ Main *********************
;
start:							; 主程式僅需要1個無窮迴圈
			goto	start
;
			end

