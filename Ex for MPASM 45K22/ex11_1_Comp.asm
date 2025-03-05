;**************************************************************************
;****	Ex11-1.asm
;****	將微控制器的CCP模組設定為輸出比較模式，配合計時器TIMER1於每一次訊號發生時，
;****	進行可變電阻的電壓採樣，並將類比訊號採樣結果顯示在發光二極體上；
;****	然後使用類比電壓值改變輸出訊號的週期，並以此訊號周期觸發LED_0，顯示訊號的變化。
;**************************************************************************

			list p=18f45k22		
#include 	<p18f45k22.inc>			; 納入定義檔Include file located at defult directory	
;
C_Hold_Delay	equ		0x20			; 延遲時間計數暫存器
AD_TEMP			equ		0x21			; 延遲時間計數暫存器

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
			call	Init_AD			; 呼叫類比訊號轉換模組初始化函式
			call	Init_CCP2		; 呼叫CCP2模組初始化函式
;
			bsf		RCON,IPEN		; 啟動中斷優先順序的功能
			bsf		INTCON,GIEH		; 啟動所有的高優先中斷
;
Main:
;
			goto	Main		 ; 重複無窮迴圈
;
;***********************************************************************
;****		Initial the PORTD for the output port 
;***********************************************************************
Init_IO:
			banksel ANSELD
			clrf	ANSELD, BANKED	; 將PORTD類比功能解除，設定數位輸入腳位
			bcf	ANSELA, 4, BANKED ;; 將RA4類比功能解除，設定數位輸入腳位
									; 將PORTA, RA4腳位設定為訊號輸入
			bsf	ANSELA, 0, BANKED ;; 將RA0設定類比功能
			
			
			clrf	TRISD		; 設定所有的PORTD腳位為輸出
			clrf	PORTD		; 清除所有的PORTD腳位值
			return
;***********************************************************************
;****		Initial Timer1 as a 500ms Timer 
;***********************************************************************
Init_Timer1:
			movlw	B'00110011'		; 16位元非同步計數器模式，開啟1:8前除器
			movwf	T1CON			; 使用外部32768Hz震盪器並開啟Timer1
;
			clrf	TMR1H			; 設定計時器高位元組資料
			clrf	TMR1L			; 設定計時器低位元組資料
;
			bcf		PIE1,TMR1IE				; 關閉Timer1中斷功能
;
			return

;***********************************************************************
;****		Initial A/D converter
;***********************************************************************
Init_AD:								; 類比訊號模組初始化函式
  			movlw	b'00000001'		; 選擇AN0通道轉換，
  			movwf	ADCON0			; 啟動A/D模組
;
			movlw	b'0000000'		; 設定VDD/VSS為參考電壓
			movwf	ADCON1			
;
			movlw	b'00111010'		; 結果向左靠齊並
			movwf	ADCON2			; 設定採樣時間20TAD，轉換時間為Fosc/32
;
			bcf		PIE1,ADIE		; 停止A/D中斷功能

			return

;***********************************************************************
; 採樣保持時間延遲函式	 (50uS) 
;***********************************************************************
C_Hold_Time:
   			movlw	.250
   			movwf	C_Hold_Delay
   			nop
			nop
   			decfsz	C_Hold_Delay,F
   			bra		$-6
   			return


;***********************************************************************
;****		Initial CCP Module
;***********************************************************************
Init_CCP2:							; CCP2模組初始化函式
			banksel ANSELB		; 解除RB3腳位類比功能
			bcf	ANSELB, 3, BANKED
			bcf	TRISB,3		; 設定RB3為輸出
			movlw	B'00001011'	; 設定CCP2為compare模式
			movwf	CCP2CON
			clrf	CCPR2H
			clrf	CCPR2L
			bsf		CCPR2L,7
			clrf	CCPTMRS0, BANKED    ;CCP1/2/3使用TIMER1/2

			bsf		IPR2, CCP2IP
			bsf		PIE2, CCP2IE
			bcf		PIR2, CCP2IF

			return

;***************************************************************************************
;****		ISRs() : 中斷執行函式
;****
;***************************************************************************************
Hi_ISRs		; 高優先中斷執行函式

			bcf		INTCON,GIEH				; 關閉所有的高優先中斷
			btg		PORTD, 0
;							   		
			call	C_Hold_Time				; 延遲50uS完成類比訊號採樣保持
			bsf		ADCON0,GO				; 啟動類比訊號轉換
			btfsc	ADCON0,GO				; 檢查類比訊號轉換是否完成?
			bra		$-2						; 否，迴圈繼續(倒退一行, 2/2=2)
			movff	ADRESH, AD_TEMP			; 是，將結果轉移到PORTD
			bcf 	STATUS, C
			rlcf	AD_TEMP, 1
			btfsc	PORTD, 0
			bsf		AD_TEMP, 0
			movff	AD_TEMP, PORTD
			movff	ADRESH, CCPR2H
			nop
			bcf		PIR2, CCP2IF			; 清除CCP2中斷旗標
			bsf		INTCON,GIEH				; 啟動所有的高優先中斷
			retfie	FAST				 	; Return with shadow register
; 
	 	  	END					

