;************************************************
;*  ex11_3.ASM                                     *
;*  利用CCP1模組的PWM模式產生1個周期變化的訊號，
;*  並以可變電阻VR1的電壓值調整訊號的週期。
;*  然後利用短路器這個周期變化的訊號傳送至CCP2模組的腳位上，
;*  利用模組的輸入訊號擷取功能計算訊號的週期變化
;*  並將高位元的結果顯示在發光二極體上。
;************************************************

			list p=18f45k22		
#include 	<p18f45k22.inc>			; 納入定義檔Include file located at defult directory	
;CCP2MX=PORTB3
			
; Variables used in this program;
	Count equ 0x00		; 時間延遲計數暫存器
	EDGEH equ 0x01		; CCP2高位元計數暫存器
	EDGEL equ 0x02		; CCP2低位元計數暫存器

; Locates startup code @ the reset vector
	org		0x00		; 程式重置向量
	nop
	goto	Init

	org		0x08		; 高優先中斷的程式向量位址
	bra		Hi_ISRs

; Locates main code
	org		0x2A		; 主程式開始
Init
; 初始化ADC模組
  	movlw	b'00000001'		; 選擇AN0通道轉換，
  	movwf	ADCON0			; 啟動A/D模組
	movlw	b'0000000'		; 設定VDD/VSS為參考電壓
	movwf	ADCON1			
	movlw	b'00111010'		; 結果向左靠齊並
	movwf	ADCON2			; 設定採樣時間20TAD，轉換時間為Fosc/32
	bcf		PIE1,ADIE		; 停止A/D中斷功能
; 初始化PORTD
	banksel ANSELD
	clrf	ANSELD, BANKED	; 將PORTD類比功能解除，設定數位輸入腳位
	bcf	ANSELC, 2, BANKED ;; 將RC2/CCP1類比功能解除，設定數位輸入腳位
	bcf	ANSELB, 3, BANKED ;; 將RB3/CCP2設定類比功能
			
	clrf 	PORTD		; 清除PORTD數值
	clrf	TRISD		; 設定PORTD為輸出
; 初始化TIMER1模組
	movlw	B'00110011'		; 16位元非同步計數器模式，關閉前除器
	movwf	T1CON			; 使用外部32768Hz震盪器並開啟Timer1
; 初始化TIMER2模組
	movlw	B'00000110'	; 啟動TIMER2，前除器為16倍
	movwf	T2CON
; 初始化CCP1模組
	clrf	CCPR1L		; 設定PWM工作周期為B'0000000010'
	bcf	TRISC,2		; 設定RC2為輸出
	movlw	B'00101100'	; 設定CCP1為PWM模式，工作週期最低2位元為10
	movwf	CCP1CON
; 初始化CCP2模組
	bsf	TRISB,3		; 設定RC1為輸入
	movlw	B'00000100'	; 設定CCP2為Capture模式，捕捉每個下降邊緣
	movwf	CCP2CON

	bsf		IPR2, CCP2IP	;設CCP2定中斷功能
	bsf		PIE2, CCP2IE
	bcf		PIR2, CCP2IF
	bsf		RCON,IPEN		; 啟動中斷優先順序的功能
	bsf		INTCON,GIEH		; 啟動所有的高優先中斷
;

	
Main
	call	Delay20		; 延遲 20us
	bsf		ADCON0,GO	; 開始 A/D轉換
WaitADC
	btfsc	ADCON0,GO	; 檢查AD轉換是否完成
	goto	WaitADC		; 
	movlw	.2
	subwf	ADRESH, W
	btfss	STATUS, C	
	addlw	0x03	; 將最小PR2調整為5，避免PR2小於2
	addlw	0x02
	movwf	PR2		; 設定Duty cycle
	goto	Main

;************************************************
;*  Delay20 – 延遲 20us 
;************************************************
Delay20					; 2 Tcy for call
	movlw	0x09		; 1 Tcy
	movwf	Count		; 1 Tcy
	nop					; 1 Tcy
D20Loop					;  \ 9 * 5 = 45 Tcy
	nop					; 1 Tcy
	nop					; 1 Tcy
	decfsz	Count,F		; 1 Tcy for non-skip
	goto	D20Loop		; 2 Tcy for goto
	return				; 2 Tcy for return

;***************************************************************************************
;****		ISRs() : 中斷執行函式
;****
;***************************************************************************************
Hi_ISRs		; 高優先中斷執行函式

	bcf		INTCON,GIEH				; 啟動所有的高優先中斷

	movf	EDGEH, W				; 計算兩次觸發邊緣時間差
	subwf	CCPR2H,W
	bnn		LED						; 時間差>0
	addlw	0xff					; 時間差<0, +256
	incf	WREG
LED:
	movwf	PORTD
	movff	CCPR2H, EDGEH
	movff	CCPR2L, EDGEL
	bcf		PIR2, CCP2IF			; 清除Timer1中斷旗標
	bsf		INTCON,GIEH				; 啟動所有的高優先中斷
	retfie	FAST				 	; Return with shadow register
; 
	END					
