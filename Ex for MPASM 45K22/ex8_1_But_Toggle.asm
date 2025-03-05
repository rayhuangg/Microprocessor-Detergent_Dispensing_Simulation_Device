;**********************************************************
;*               Ex8_1.ASM
;*  程式將偵測按鍵SW3的狀態，並遞加計數的內容。當計數數值超過四次便反轉燈號
;**********************************************************
			list p=18f45k22		
#include 	<p18f45k22.inc>			; 納入定義檔Include file located at defult directory
;
count_val	equ	.4					; 燈號反轉所需計數數值
;
VAL_500US	equ	.250				; 0.5ms delay value
;
count_us	equ	0x20				; Defined temp reg. for 1ms delay
push_no		equ 0x23					; 儲存計數數值的暫存器位址
;Register for number of button push
;
;***************************************
;           Program start              *
;***************************************
			org 	0x00			; reset vector
			nop						; Reserve for MPLAB-ICD
initial:							; 初始化微控制器
			banksel ANSELD
			clrf	ANSELD		; 將PORTD類比功能解除，設定數位輸入腳位
			bcf	ANSELA, 4	; 將RA4類比功能解除，設定數位輸入腳位
									; 將PORTA, RA4腳位設定為訊號輸入
			clrf	PORTA, 0		; a=0 for access bank SFR
			bsf		TRISA, 4, 0		; a=0 for access bank SFR
									; 將PORTD埠設定為訊號輸出，並點亮LED0~3
			clrf	PORTD, 0		; Clear PORTD
			clrf	TRISD, 0		; Set PORTD for LED output	
			movlw	0x0f			; Turn on LED0~3
			movwf	PORTD, 0
									; 將設定累加的計數次數存入到暫存器中
			banksel push_no	
			movlw	count_val
			movwf	push_no
;
;************ Main *********************
;
start:
									; 檢查按鍵狀態，如按下時跳行
			btfsc	PORTA, 4, 0	
			goto	start
			call	delay_500us		; 延遲10ms去除按鍵彈跳
			btfss	PORTA, 4, 0		; 按鍵鬆開後跳行執行
			goto	start
									; 將push_no暫存器的數值遞減1並檢查是否為0
			banksel push_no
			decfsz	push_no
			goto	start			; 不為零則重複循環
			swapf	PORTD, f, 0 	; 若為0則對調燈號，並將計數內容重置
			banksel push_no
			movlw	count_val
			movwf	push_no
			goto	start			; 程式迴圈
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
