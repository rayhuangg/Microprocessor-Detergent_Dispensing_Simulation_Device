;****************************************************************
;	Ex12_1.asm
;	量測可變電阻的類比電壓值，並將10位元的的量測結果轉換成ASCII編碼
;	並輸出到個人電腦上的VT-100終端機。
;	當電腦鍵盤按下 ‘c’ 按鍵時開始輸出資料
;	當按下按鍵 ‘p’ 停止輸出資料。
;****************************************************************
			list p=18f45k22		
#include 	<p18f45k22.inc>			; 納入定義檔Include file located at defult directory	
;
RX_Temp 	EQU 	0x20
;
			CBLOCK	0x00		; 由暫存器位址0x00開始宣告保留變數的位址
			C_Hold_Delay		; 類比訊號採樣保持時間延遲計數暫存器
			TxD_Flag			; 資料傳輸延遲時間旗標
			Hex_Temp			; 編碼轉換暫存器
			ENDC					; 結束變數宣告

			CBLOCK	0x020		; 由暫存器位址0x20開始
			WREG_TEMP			; 儲存處理器資料重要變數
			STATUS_TEMP			; 以便在進出函式時，暫存重要資料
			BSR_TEMP				
			ENDC
;
#define			TMR1_VAL	.32768	; 定義Timer1計時器週期1 SEC
;					       		
;********************************************************************
;****	RESET Vector @ 0x0000
;********************************************************************

			org		0x00 			; 重置向量
 			bra		Init
;
			org		0x08			; 高優先中斷向量
			bra		Hi_ISRs
;
			org		0x18			; 低優先中斷向量
			bra		Low_ISRs
;
;********************************************************************
;****	The Main Program start from Here !! 
;********************************************************************

			org		0x02A		; 主程式開始位址
Init:
			call	Init_IO
			call	Init_Timer1
			call	Init_AD
			call	Init_USART
;
			bsf		RCON,IPEN		; 啟動中斷優先順序
			bsf		INTCON,GIEH		; 啟動高優先中斷功能，以利用TIMER1計時器中斷
			bsf		INTCON,GIEL		; 啟動並優先中斷功能，以利用USART RD中斷
			clrf	TxD_Flag			; 清除計時旗標
;
Main:	
			nop
			btfsc	TxD_Flag,1		; 旗標等於0，繼續傳送類比訊號資料
			bra		Main			; 旗標等於1，停止傳送類比訊號資料
;
			btfss	TxD_Flag,0		; 檢查計時是否超過1 Sec?
			bra 	Main				; 否，繼續迴圈
			bcf		TxD_Flag,0		; 是，清除1S中計時器錶
			call	AD_Convert		; 開始類比訊號轉換
;
 			movf	ADRESH,W		; 將轉換結果A/D <b9:b8>轉成ASCII 並由UART送出
 			andlw	b'00000011'
 			call	Hex_ASCII
 			call 	Tx_a_Byte
;
 			swapf	ADRESL,W		; 將轉換結果A/D <b7:b4>轉成ASCII 並由USART送出
 			andlw	h'0F'
 			call	Hex_ASCII
 			call	Tx_a_Byte
;
 			movf	ADRESL,W		; 將轉換結果A/D <b3:b0>轉成ASCII 並由USART送出
 			andlw	h'0F'
 			call	Hex_ASCII
 			call	Tx_a_Byte
;
			movlw	h'0a'			; 送出符號0x0A & 0x0D以便在終端機換行
			call 	Tx_a_Byte
			movlw	h'0d'
			call 	Tx_a_Byte
;
			bra	Main					; 無窮迴圈
			
			
;
;******   Send a byte to USART   ******
Tx_a_Byte:
			movwf	TXREG1					; 透過USART送出去的位元符號
			nop								; 
			btfss	PIR1,TXIF				; 檢查資料傳輸完成與否?
			bra		$-4						; No, 繼續檢查旗標位元TXIF
			bcf		PIR1,TXIF				; Yes, 清楚旗標位元TXIF
			return
;
;******* Convert low nibble to ASCII code   *******
Hex_ASCII:
 			andlw	h'0F'					; 確定high nibble為"0000"
 			movwf	Hex_Temp
 			movlw	h'9'					; 跟9比較
 			cpfsgt  Hex_Temp
 			bra		Less_9
 			movf	Hex_Temp,W				; > 9, 數字加0x37
 			addlw	h'37'
 			return
Less_9		movf	Hex_Temp,W				; < = 9, 數字加0x30
 			addlw	h'30'
 			return
 			
;
;*****    Connvert the 10-bit A/D   *****
AD_Convert:
			call	C_Hold_Time				; 延遲50uS 完成訊號採樣保持
			bsf		ADCON0,GO				; 開始A/D轉換
			nop								; Nop
			btfsc	ADCON0,GO				; 檢查A/D轉換是否完成
			bra		$-4						; 否，繼續檢查
			return 
;
;***********************************************************************
;****		Initial I/O Port 
;***********************************************************************
Init_IO:									; 設定數位輸入腳位
			banksel ANSELD
			clrf	ANSELD, BANKED	; 將PORTD類比功能解除，設定數位輸入腳位
			bcf	ANSELC, 6, BANKED   ; 將TX1/RX1(RC6/RC7)腳位類比功能解除
			bcf	ANSELC, 7, BANKED
			
			clrf	TRISD					; 將PORTD數位輸出入埠設為輸出
			clrf	LATD
			bcf	TRISC, 6
			bsf	TRISC, 7

			return
;
;***********************************************************************
;****		Initial Timer1 as a 1 Sec Timer 
;***********************************************************************
Init_Timer1:
			movlw	B'10001111'				;16位元模式、1倍前除器、非同步計數模式
			movwf	T1CON				; 使用外部震盪器，開啟計時器
;
			movlw	(.65536-TMR1_VAL)/.256	; 計算計時器Timer1高位元組資料
			movwf	TMR1H
			movlw	(.65536-TMR1_VAL)%.256	; 計算計時器Timer1低位元組資料
			movwf	TMR1L
;
			bsf		IPR1,TMR1IP				; 設定Timer1高優先中斷
			bcf		PIR1,TMR1IF				; 清除中斷旗標
			bsf		PIE1,TMR1IE				; 開啟計時器中斷功能
;
			return
;
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
			movlw	b'10111010'		; 結果向右靠齊並
			movwf	ADCON2			; 設定採樣時間20TAD，轉換時間為Fosc/32
;
			bcf		PIE1,ADIE				; 停止A/D中斷功能

			return
;
;***********************************************************************
;****		Initial USART as 9600,N,8,1 
;***********************************************************************
Init_USART:
			movlw	b'00100110'				; 8位元模式非同步傳輸 
			movwf	TXSTA1					; 低鮑率設定，啟動傳輸功能
;
			movlw	b'10010000'				; 啟動8位元資料接收功能
			movwf	RCSTA1					; 連續接收模式，停止位址偵測點
;
			movlw	0x08						; 設定16位元鮑率參數
			movwf	BAUDCON1
			movlw	0x03						; 設定鮑率為9600
			movwf	SPBRG1
			movlw	0x01						
			movwf	SPBRGH1
;
			bcf		PIR1,TXIF				; 清除資料傳輸中斷旗標
			bcf		PIE1,TXIE				; 停止資料傳輸中斷功能
;
			bcf		IPR1,RCIP	  			; 設定資料接收低優先中斷
			bcf		PIR1,RCIF				; 清除資料接收中斷旗標
			bsf		PIE1,RCIE				; 啟動資料接收中斷
;
			return

;
;***********************************************************************
;****		Sample Hold (Charge) time delay routine (50uS) 
;***********************************************************************
C_Hold_Time:
   			movlw	.200
   			movwf	C_Hold_Delay
   			nop
			nop
   			decfsz	C_Hold_Delay,F
   			bra		$-4
   			return

;***************************************************************************
;****		Hi_ISRs : Hi-Priority Interrupt reotine 
;****
;***************************************************************************
Hi_ISRs

			bcf		PIR1,TMR1IF				; 清除Timer1中斷旗標
;							   		
			movlw	(.65536-TMR1_VAL)/.256	; 計算計時器Timer1高位元組資料
			movwf	TMR1H
			movlw	(.65536-TMR1_VAL)%.256	; 計算計時器Timer1低位元組資料
			movwf	TMR1L
;
			bsf		TxD_Flag,0				; 設定1 Sec計時旗標
;
			retfie	FAST				 	; 利用shadow register返回
; 
;***************************************************************************
;****		Low_ISRs : Low-Priority Interrupt reotine 
;****
;***************************************************************************
Low_ISRs:
			movff	STATUS,STATUS_TEMP		; 儲存處理器資料重要變數
			movff	WREG,WREG_TEMP
			movff	BSR,BSR_TEMP	
;
			bcf		PIR1,RCIF				; 清除資料接收中斷旗標
			movff	RCREG1, RX_Temp				; 將接收資料顯示在LED
			movff	RX_Temp, LATD				; 將接收資料顯示在LED
;
			movlw	a'c'					; 檢查接收資料是否為’c’?
			cpfseq  RX_Temp
			bra		No_EQU_C
			bcf		TxD_Flag,1				; Yes, 啟動傳輸資料
			bra		Exit_Low_ISR
No_EQU_C	movlw	a'p'					; 檢查接收資料是否為’p’?
			cpfseq  RX_Temp
			bra		Exit_Low_ISR			; No, 不作動
			bsf		TxD_Flag,1				; Yes,停止傳送資料
;
Exit_Low_ISR
			movff	BSR_TEMP,BSR			; 回復重要資料暫存器
			movff	WREG_TEMP,WREG
			movff	STATUS_TEMP,STATUS
			retfie					; 一般中斷返回
; 
	 	  	END
