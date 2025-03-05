;************************************************
;*  ex11_2.ASM                                     *
;	讀取可變電阻的類比電壓值，將結果轉換成8位元的訊號
;	並將結果呈現在PORTD發光二極體。
;	同時以此8位元結果作為CCP1的PWM模組之工作週期設定值，
;	產生一個頻率為4000Hz的可調音量之蜂鳴器週期波。
;************************************************

			list p=18f45k22		
#include 	<p18f45k22.inc>			; 納入定義檔Include file located at defult directory	
;
; Variables used in this program;
	Count equ 0x00		; 時間延遲計數暫存器

; Locates startup code @ the reset vector
	org		0x00		; 程式重置向量
	nop
	goto	Init

; Locates main code
	org		0x2A		; 主程式開始
Init
;
  	movlw	b'00000001'		; 選擇AN0通道轉換，
  	movwf	ADCON0			; 啟動A/D模組
	movlw	b'0000000'		; 設定VDD/VSS為參考電壓
	movwf	ADCON1			
	movlw	b'00111010'		; 結果向左靠齊並
	movwf	ADCON2			; 設定採樣時間20TAD，轉換時間為Fosc/32

	movlw	0x9B		; 設定PWM周期為250us 頻率為4kHz
	movwf	PR2
	
	banksel ANSELC
	bcf	ANSELC, ANSC2
	bcf	TRISC,2		; 設定RC2為輸出
	clrf	ANSELD		; 設定PORTD為輸出

	movlw	B'00001100'	; 設定CCP1為PWM模式，工作週期最高2位元為00
	movwf	CCP1CON
	movlw	B'00000101'	; 啟動TIMER2，前除器為4倍
	movwf	T2CON
	clrf 	PORTD		; 設定PORTD數值
	clrf	TRISD		; 設定PORTD為輸出

Main
	call	Delay20		; 延遲 20us
	bsf		ADCON0,GO	; 開始 A/D轉換
WaitADC
	btfsc	ADCON0,GO	; 檢查AD轉換是否完成
	goto	WaitADC		; 
	movf	ADRESH,W	; 儲存轉換結果
	comf	WREG
	movwf	PORTD		; LED顯示
	movwf	CCPR1L		; 設定Duty cycle
	goto	Main

;************************************************
;*  Delay20 – 延遲 20us 
;************************************************
Delay20					; 2 Tcy for call
	movlw	0x09		; 1 Tcy
	movwf	Count		; 1 Tcy
	nop					; 1 Tcy
D20Loop					; 9 * 5 = 45 Tcy
	nop					;  
	nop
	decfsz	Count,F		; 1 Tcy for non-skip
	goto	D20Loop		; 2 Tcy for goto
	return				; 2 Tcy for return

	end

