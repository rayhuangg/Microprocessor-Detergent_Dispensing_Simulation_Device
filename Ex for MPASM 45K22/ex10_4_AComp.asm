;********************************************************************
;       Ex10-4.asm
;       讀取可變電阻的類比電壓值，將結果轉換成8位元的訊號
;       並將結果呈現在PORTD發光二極體
;		同時使用類比訊號比較器，偵測電壓是否超出預設值
;********************************************************************

			list p=18f45k22		
#include 	<p18f45k22.inc>			; 納入定義檔Include file located at defult directory	
;
C_Hold_Delay	equ		0x20			; 延遲時間計數暫存器
;					       		
;********************************************************************
;****	RESET Vector @ 0x0000
;********************************************************************

			org		0x00 		; 程式起始位址
 			bra		Main
;
			org		0x08			; 中斷向量起始位址
			bra		Hi_ISRs
;
;********************************************************************
;****	The Main Program start from Here !! 
;********************************************************************

			org		0x02A		; 主程式起始位址
Main:
			call	Init_IO			; 呼叫數位輸出入埠初始化函式
			call	Init_AD			; 呼叫類比訊號轉換模組初始化函式
			call	Init_DAC		; 呼叫數位類比訊號轉換模組初始化函式
;
Init_Comparator:
			movlw	b'10101100'		; 開啟類比訊號比較模組，負端IN0-，正端CxVref
			movwf	CM1CON0 		; 設定比較器內部參考電壓為(VDD-VSS)/2
			movlw	b'00000011' 	; 設定類比電壓比較器模組 C1/2+聯結至DACOUT
			movwf	CM2CON1			; 
;
AD_Loop			btfss	CM2CON1, MC1OUT	; 檢查電壓是否小於預設值
			goto	LED_ON			; 否，點亮所有LED
									; 是，顯示電壓採樣值
			call	C_Hold_Time		; 延遲50uS完成類比訊號採樣保持
			bsf		ADCON0,GO		; 啟動類比訊號轉換
			nop						; 
			btfsc	ADCON0,GO		; 檢查類比訊號轉換是否完成?
			bra		$-4				; 否，迴圈繼續(倒退兩行, 4/2=2)
			movff	ADRESH, PORTD	; 是，將結果轉移到PORTD
;
			goto	AD_Loop			; 重複無窮迴圈
LED_ON		setf	PORTD
			goto	AD_Loop			; 重複無窮迴圈
;***********************************************************************
;****		Initial the PORTD for the output port 
;***********************************************************************
Init_IO:						; 數位輸出入埠初始化函式
			banksel ANSELD
			clrf	ANSELD, BANKED	; 將PORTD類比功能解除，設定數位輸入腳位
			bcf	ANSELA, 4, BANKED ;; 將RA4類比功能解除，設定數位輸入腳位
									; 將PORTA, RA4腳位設定為訊號輸入
			bsf	ANSELA, 0, BANKED ;; 將RA0設定類比功能
			
			
			clrf	PORTD		; 清除PORTD暫存器數值
			clrf	TRISD		; 設定PORTD全部為數位輸出
;
			return
;***********************************************************************
;****		Initial A/D converter
;***********************************************************************
Init_AD:
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
;****		Initial DA converter
;***********************************************************************
Init_DAC:
  			banksel VREFCON1
			movlw	b'11000000'	; 開啟模組/內部電壓/低電壓使用正端/電源選用VDD/VSS，
  			movwf	VREFCON1, BANKED	; 啟動DAC模組
;
			movlw	b'00010000'		; 設定輸出為0.5*(VDD-VSS)
			movwf	VREFCON2, BANKED			
;
			return
;;***********************************************************************
; 採樣保持時間延遲函式	 (50uS) 
;***********************************************************************
C_Hold_Time:
   			movlw	.125
   			movwf	C_Hold_Delay
   			nop
   			decfsz	C_Hold_Delay,F
   			bra		$-4
   			return

;**************************************************************************
; 高優先權中斷執行函式
;************************************************************************** 
Hi_ISRs
			retfie	FAST				 ; Return with shadow register
; 
	 	  	END
