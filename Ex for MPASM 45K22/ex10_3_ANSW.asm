;********************************************************************
;       Ex10-3.asm
;     1. 按下RB0按鍵時，讀取類比按鍵的類比電壓值，將結果轉換成8位元的訊號
;        並呈現在PORTD發光二極體
;     2. 放開RB0按鍵時，在PORTD發光二極體顯示對應按鍵之LED
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
;
AD_Loop		btfsc	PORTB, RB0
			bra		$-2
			call	C_Hold_Time				; 延遲50uS完成類比訊號採樣保持
			bsf		ADCON0,GO				; 啟動類比訊號轉換
			nop								; 
			btfsc	ADCON0,GO				; 檢查類比訊號轉換是否完成?
			bra		$-4						; 否，迴圈繼續(倒退兩行, 4/2=2)
			movff	ADRESH, PORTD			; 是，將結果轉移到PORTD
;
			btfss	PORTB, RB0
			bra		$-2
			clrf	PORTD
			movf	ADRESH, W
SW4:		bnz		SW5				; ADRESH>0, Others
			bsf		PORTD, 4		; ADRES=0, SW4 Pressed
			goto	AD_Loop		 	; 重複無窮迴圈
SW5:
			sublw	.127
			bn		SW6				; ADRES>128, Others
			bsf		PORTD, 5		; ADRES<128, SW5 Pressed
			goto	AD_Loop		 	; 重複無窮迴圈
SW6:		movf	ADRESH, W
			sublw	.169
			bn		AD_Loop
			bsf		PORTD, 6		; ADRES<170, SW6 Pressed
			bra		AD_Loop		 	; ADRES>170, None, 重複無窮迴圈
;***********************************************************************
;****		Initial the PORTD for the output port 
;***********************************************************************
Init_IO:						; 數位輸出入埠初始化函式
			banksel ANSELD
			clrf	ANSELD, BANKED	; 將PORTD類比功能解除，設定數位輸入腳位
			bcf	ANSELA, 4, BANKED ;; 將RA4類比功能解除，設定數位輸入腳位
									; 將PORTA, RA4腳位設定為訊號輸入
			bcf	ANSELB, 0, BANKED ;; 將RB0類比功能解除，設定數位輸入腳位
									; 將PORTB, RB0腳位設定為訊號輸入
			
			clrf	PORTD		; 設定PORTD暫存器數值
			clrf	TRISD		; 設定PORTD全部為數位輸出
;
   			bsf		TRISA,RA4	; 設定RA4為數位輸入
   			bsf		TRISB,RB0	; 設定RB0為數位輸入
;
			return
;***********************************************************************
;****		Initial A/D converter
;***********************************************************************
Init_AD:							; 類比訊號模組初始化函式 for PIC18F4520
			movlw	b'00000111'		; 設定AN0~AN2為類比輸入
			BANKSEL ANSELA
			iorwf	ANSELA, BANKED			
;
			movlw	b'00001001'		; 選擇AN2通道轉換，
  			movwf	ADCON0			; 啟動A/D模組
;
			movlw	b'0000000'		; 設定VDD/VSS為參考電壓
			movwf	ADCON1			
;
			movlw	b'00111010'		; 結果向左靠齊並
			movwf	ADCON2			; 設定採樣時間20TAD，轉換時間為Fosc/32
;

			bcf		PIE1,ADIE		; 關閉A/D模組中斷功能

			return
;
;
;***********************************************************************
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
