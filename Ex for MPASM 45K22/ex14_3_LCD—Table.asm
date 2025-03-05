;************************************************
;* ex14-3.ASM                                          *
;* 在LCD第一行顯示 “Welcom to PIC”                  *
;* 在LCD第二行顯示 “Micro-Controller”               *
;************************************************

			list p=18f45k22		
#include 	<p18f45k22.inc>			; 納入定義檔Include file located at defult directory	
;
; 定義外部函式
	EXTERN	InitLCD, putcLCD, Send_Cmd, L1homeLCD, L2homeLCD, clrLCD

; 定義巨集指令PUT_Address讀取所要顯示的字串位址TARGET_STR
; 並呼叫函式Put_String將字串傳輸到LCD模組
PUT_Address	MACRO	TARGET_STR
			movlw	UPPER	TARGET_STR
			movwf	TBLPTRU
			movlw	HIGH	TARGET_STR
			movwf	TBLPTRH
			movlw	LOW	TARGET_STR
			movwf	TBLPTRL
			call	Put_String		; 	
			ENDM
;					       		

; Locates startup code @ the reset vector

STARTUP	code 
	org		0x00
	nop
	goto	Start

; Locates main code
PROG1	code
Start

	call	InitLCD
;
	call 	L1homeLCD
	PUT_Address	String_1	;利用巨集指令傳輸字串
;
	call 	L2homeLCD
	PUT_Address	String_2	;利用巨集指令傳輸字串

	goto	$

; 
;**************************************************************************
;****		由程式記憶體讀取1個字串，並將字串傳輸到LCD模組
;**************************************************************************
Put_String
			TBLRD*+	; 利用列表讀取指定將資料擷取到TABLAT暫存器，並將列表指標遞加1
			movlw	0x00
			cpfseq	TABLAT, 0			; 檢查是否讀到0x00?
			goto	Send_String				; No, 將資料傳輸到LCD模組
			return							; Yes, 返回呼叫程式
;
Send_String	movf	TABLAT,W, 0				; 將資料傳輸到LCD模組
			call	putcLCD					;  
			goto	Put_String				; 繼續迴圈讀取下1筆資料
;

String_1	db	"Welcome To PIC", 0x00		; 文字符號字串定義，並加上0x00作為檢查
String_2	db  "Micro-Controller", 0x00
;
	end
