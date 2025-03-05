	;AD轉換26以下，無法完全顯示燈號
	;按小寫R請除排放次數
	;SW2按住AD轉換
	;SW3按一下開始排放
	;####有時間的話把閃爍改成CCP用LED9，不然太沒效率了
	; 給愛麗絲 323237216
	
	
	list p=18f45k22		
	#include 	<p18f45k22.inc>
	
	;CONFIG  CCP2MX = PORTB3
	
	;
	; 定義外部函式
	EXTERN	InitLCD, putcLCD, Send_Cmd, L1homeLCD, L2homeLCD, clrLCD,PutHexLCD,L1_4LCD,Hex2ASCII,L2_2LCD,L2_7LCD,L2_12LCD
	
	CBLOCK	    0x00
	    C_Hold_Delay	    
	    div_1			;除數
	    div_2			;被除數
	    div_sum			;商
	    div_temp	    
	    TMR1_VAL	
	    LED_0_temp
	    ENDC
	        
	CBLOCK	    0x10
	    TMR1_H_byte_Temp      
	    TMR1_L_byte_Temp      
	    Escape_temp	  

	    count_us	    		
	    count_10ms	          
	    count_200ms	    	

	    count_times			;排放次數(EEP
	    count_times_past		;上次循環的排放數值
	    Timer1_Times		;進中斷次數(數八次歸零)
	    ENDC
	
	
	CBLOCK	0x20
	    Data_EE_Addr		;EEPROM資料位址
	    Data_EE_Data		;EEPROM資料
	    ADRH			;高位元資料變數
	    ADRL			;低位元資料變數
	    Push_R			;檢查有沒有按R
	    RX_Temp			;放USART接收到的值
	    
	    HND
	    TEN
	    ONE
	    BIN_Value
	    
	    Si_m_temp
	    point_1s_Times
	    ENDC    
	    
	    
	VAL_500US	    equ	    .250		
	VAL_10MS	    equ	    .20			
	VAL_200MS	    equ	    .20     
	LED_0		    equ	    b'00000001'    
		    
	#define			EEP_ADRL	0		; Define EEPROM Low Byte Address、排放次數
	#define			EEP_ADRH	1		; Define EEPROM High Byte Address
;---------------------------------------音高頻率	    
	La_m	equ	0xB1
	Si_m	equ	0x9D	
	Do	equ	0x94
	Re	equ	0x84
	Mi	equ	0x76
	Fa	equ	0x6F
	So	equ	0x63
	La	equ	0x58
	Si	equ	0x4E  

	org	    0x00 		
 	bra	    Main
	org	    0x08			
	bra	    Hi_ISRs
	org	    0x18
	bra	    Low_ISRs

	org	    0x2A		
Main:
	bsf	    RCON,	IPEN,	A	;開啟中斷功能
	bsf	    INTCON,	GIEH,	A
	bsf	    INTCON,	GIEL,	A
	
    ;IO初始化
	banksel	    ANSELA
	bcf	    ANSELA, 4
	bcf	    ANSELB, 0
	clrf	    ANSELD
	bsf	    TRISA,  4
	bsf	    TRISB,  0
	clrf	    TRISD
	clrf	    LATD
	bcf	    PORTA,  4
	bcf	    PORTB,  0 
    
    ;AD初始化
	banksel	    ADCON0
	movlw	    b'00000001'		;選AN0 (VR1)
  	movwf	    ADCON0			
	movlw	    b'00000000'		;VDD/VSS
	movwf	    ADCON1			
	movlw	    b'00111010'		;靠左對齊
	movwf	    ADCON2			

	bcf	    PIE1,   ADIE
    
    ;TIMER 1初始化 (LED亮燈)
	banksel	    T1CON
	movlw	    b'10111010'		;前除8, 32768Hz
	movwf	    T1CON
	clrf	    TMR1H
	clrf	    TMR1L
	clrf	    Timer1_Times
		
	bsf	    PIE1,    TMR1IE
	bcf	    PIR1,    TMR1IF
	bsf	    IPR1,    TMR1IP
	
	
    ;TIMER 3初始化 (LCD計時，0.1秒單位)
	banksel	    T3CON
	movlw	    b'10111010'		;前除8, 32768Hz
	movwf	    T3CON
	movlw	    .254		;0.1秒
	movwf	    TMR3H
	movlw	    .102
	movwf	    TMR3L
	clrf	    point_1s_Times

		
	bsf	    PIE2,    TMR3IE
	bcf	    PIR2,    TMR3IF
	bsf	    IPR2,    TMR3IP
	
    ;Initial USART as 9600,N,8,1
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
	bcf	ANSELC, 6, BANKED   ; 將TX1/RX1(RC6/RC7)腳位類比功能解除
	bcf	ANSELC, 7, BANKED
	bcf	TRISC, 6
	bsf	TRISC, 7
;
	bcf		PIR1,TXIF				; 清除資料傳輸中斷旗標
	bcf		PIE1,TXIE				; 停止資料傳輸中斷功能
;
	bcf		IPR1,RCIP	  			; 設定資料接收低優先中斷
	bcf		PIR1,RCIF				; 清除資料接收中斷旗標
	bsf		PIE1,RCIE				; 啟動資料接收中斷

				
	
    ;CCP1 + TMR2 初始化 (Buzzer)	
	banksel	    ANSELC
	bcf	    ANSELC, ANSC2
	bcf	    TRISC,2		; 設定RC2為輸出
		
	movlw	    B'00001100'		; 設定CCP1為PWM模式，工作週期最高2位元為00
	movwf	    CCP1CON
	movlw	    0x3F
	movwf	    CCPR1L		; 設定Duty Cyle
	movlw	    B'00000010'		; 設定TIMER2(沒啟動)，前除器為16倍
	movwf	    T2CON
	clrf	    PR2			; 設定週期
	


    ;LCD初始化	
	call	    InitLCD
	call	    L1homeLCD
	movlw	    'N'
	call	    putcLCD
	movlw	    'o'
	call	    putcLCD
	movlw	    '#'
	call	    putcLCD
	movlw	    ':'
	call	    putcLCD
	
;____________________________________________	
	call	    L2homeLCD
	movlw	    'V'
	call	    putcLCD
	movlw	    ':'
	call	    putcLCD
	
	call	    L2_7LCD
	movlw	    'T'
	call	    putcLCD
	movlw	    'i'
	call	    putcLCD
	movlw	    'm'
	call	    putcLCD
	movlw	    'e'
	call	    putcLCD
	movlw	    ':'
	call	    putcLCD
	
;____________________________________________	
	movlw	    EEP_ADRL			
	movwf	    Data_EE_Addr
	call	    READ_EEPROM    	
	movf	    EEDATA, W
	
	call	    B_to_D_Value		  ;把EE數值做十進位轉換
	call	    L1_4LCD
	movf	    HND,    W			  ;NOTE 不確定為何要這樣做才可以寫進去，用PutHexLCD會佔兩格空間
	call	    Hex2ASCII
	call	    putcLCD
	movf	    TEN,    W
	call	    Hex2ASCII
	call	    putcLCD
	movf	    ONE,    W
	call	    Hex2ASCII
	call	    putcLCD
	
    ;雜七雜八初始化
	movlw	    LED_0
	movwf	    LED_0_temp
	movlw	    Si_m
	movwf	    Si_m_temp
   	
	
    ; Read  EEPROM #####

	movlw	    EEP_ADRL
	movwf	    Data_EE_Addr
	movlw	    .0
	movwf	    Data_EE_Data
	call	    WRITE_EEPROM
	
Start:		
	
	btfsc	    PORTB,  0		     ;按SW2/RB0才開始ADC
	bra	    $+4
	call	    AD_Loop
	btfsc	    PORTA,  4		     ;按下SW1才開始執行亮燈
	bra	    $+4
	call	    LED_Rotate
	
	movf	    count_times_past,	W
	subwf	    count_times,    W		;判斷有差值代表多一次了
	btfsc	    STATUS,	Z
	bra	    ff
	
	movlw	    Si_m			;回復音高
	movwf	    Si_m_temp
	movlw	    EEP_ADRL			;有改變再做寫入
	movwf	    Data_EE_Addr
	movff	    count_times,  Data_EE_Data
	call	    WRITE_EEPROM
				
read	movlw	    EEP_ADRL			 ;一寫入馬上讀取
	movwf	    Data_EE_Addr
	call	    READ_EEPROM    	
	movf	    EEDATA, W
	
	call	    B_to_D_Value		  ;把EE數值做十進位轉換
	call	    L1_4LCD
	movf	    HND,    W			  ;NOTE 不確定為何要這樣做才可以寫進去，用PutHexLCD會佔兩格空間
	call	    Hex2ASCII
	call	    putcLCD
	movf	    TEN,    W
	call	    Hex2ASCII
	call	    putcLCD
	movf	    ONE,    W
	call	    Hex2ASCII
	call	    putcLCD
	
	call	    L2_12LCD
	movf	    point_1s_Times, W		;顯示時間
	call	    B_to_D_Value
	movf	    TEN,    W
	call	    Hex2ASCII
	call	    putcLCD
	movlw	    a'.'
	call	    putcLCD
	movf	    ONE,    W
	call	    Hex2ASCII
	call	    putcLCD
	movlw	    a's'
	call	    putcLCD
	
	
ff	movff	    count_times,    count_times_past	;把這次循環的排放次數記下來，下次循環判斷有無差值決定是否寫入EE
	
	btfss	    Push_R, 0			;按R的話清空次數
	bra	    back_to_start
	clrf	    count_times			;清除次數，並將EEP也清除
	clrf	    count_times_past
	bcf	    Push_R, 0			
	movlw	    EEP_ADRL			
	movwf	    Data_EE_Addr
	movlw	    .0
	movwf	    Data_EE_Data
	call	    WRITE_EEPROM
	bra	    read
	
display_time	
	;movf	    point_1s_Times, W		;顯示時間
	;call	    L2_6LCD
	;call	    PutHexLCD
	
	
back_to_start
	bra	    Start
	
	  	
;===============================================================================	
	
AD_Loop		
	call	    C_Hold_Time		; 延遲50uS完成類比訊號採樣保持
	bsf	    ADCON0,	GO	; 啟動類比訊號轉換
	nop								
	btfsc	    ADCON0,	GO	; 檢查類比訊號轉換是否完成?
	bra	    $-4			; 否，迴圈繼續(倒退兩行, 4/2=2)
	movff	    ADRESH,	LATD
	movf	    ADRESH,	W
	call	    B_to_D_Value
	call	    L2_2LCD		;把電壓值放到LCD
	movf	    HND,    W		;NOTE 不確定為何要這樣做才可以寫進去，只有用PutHexLCD會佔兩格空間
	call	    Hex2ASCII
	call	    putcLCD
	movf	    TEN,    W
	call	    Hex2ASCII
	call	    putcLCD
	movf	    ONE,    W
	call	    Hex2ASCII
	call	    putcLCD
	
	return
;===============================================================================	

LED_Rotate:	
	banksel	    ADRESH
	movlw	    .10			; 255*10 約等於五秒/8 計時器要數的數值
	mulwf	    ADRESH		; "MULWF" W和F相乘
	movf	    PRODH,  W,	A	; 設定計時器高位元組資料(PRODH:乘法high byte)
	sublw	    0xFF
	movwf	    TMR1H
	movf	    PRODL,  W,	A	; 設定計時器低位元組資料(PRODL:乘法low byte)
	sublw	    0xFF
	movwf	    TMR1L		
			
	bsf	    T1CON,	TMR1ON		  ;按SW1按下後才開始計時
	return
	
B_to_D_Value:
	movwf	BIN_Value
	clrf	HND
	clrf	TEN
	clrf	ONE
   
Count_HND    
	banksel	    BIN_Value
	movlw	.100
	cpfslt	BIN_Value
	bra	$+4
	goto	Count_TEN
	subwf	BIN_Value
	incf	HND
	bra	Count_HND
	
Count_TEN
	banksel	    BIN_Value
	movlw	.10
	cpfslt	BIN_Value
	bra	$+4
	goto	Count_ONE
	subwf	BIN_Value
	incf	TEN	
	bra	Count_TEN	
	
Count_ONE
	banksel	    BIN_Value	
	movlw	.1
	cpfslt	BIN_Value
	bra	$+4
	return
	subwf	BIN_Value
	incf	ONE
	bra	Count_ONE
	return
	
	
;------ INTERNAL EEPROM READ ------
;
READ_EEPROM						;讀取eeprom標準程序
			movff	Data_EE_Addr,EEADR
;
			bcf     INTCON,GIE  
			bcf	EECON1,EEPGD
			bcf	EECON1,CFGS
			bsf	EECON1,RD
			movf	EEDATA,W
			bsf     INTCON,GIE  
			return	
	
;----INTERNAL EEPROM WRITE-----
;
WRITE_EEPROM						;寫入eeprom標準程序
	         movff  Data_EE_Addr,EEADR
	         movff  Data_EE_Data,EEDATA
;
	         BCF   	 EECON1,EEPGD 
	         BCF  	 EECON1,CFGS
	      
	         BSF   	 EECON1,WREN 
	         BCF     INTCON,GIE   
;  
	         MOVLW   0X55
	         MOVWF   EECON2
	         MOVLW   0XAA
	         MOVWF   EECON2      
	         BSF  	 EECON1,WR 
;         
	         BSF   INTCON,GIE 
	
LOOP1    	BTFSS   PIR2, EEIF 		; 檢查寫入動作是否完成
 	        GOTO    LOOP1 
;
	         BCF  	 EECON1,WREN   
	         BCF   	 PIR2,EEIF
	      
	         RETURN		
		 
C_Hold_Time
   	movlw	    .125
   	movwf	    C_Hold_Delay
   	nop
   	decfsz	    C_Hold_Delay,F
   	bra	    $-4
   	return
	
sing_a_song
	movlw	    .0
	cpfseq	    Timer1_Times
	bra	    $+4
	call	    Sing_Mi
	
	movlw	    .1
	cpfseq	    Timer1_Times
	bra	    $+4
	call	    Sing_Re
	
	movlw	    .2
	cpfseq	    Timer1_Times
	bra	    $+4
	call	    Sing_Mi
	
	movlw	    .3
	cpfseq	    Timer1_Times
	bra	    $+4
	call	    Sing_Re
	
	movlw	    .4
	cpfseq	    Timer1_Times
	bra	    $+4
	call	    Sing_Mi
	
	movlw	    .5
	cpfseq	    Timer1_Times
	bra	    $+4
	call	    Sing_Si_m
	
	movlw	    .6
	cpfseq	    Timer1_Times
	bra	    $+4
	call	    Sing_Re
	
	movlw	    .7
	cpfseq	    Timer1_Times
	bra	    $+4
	call	    Sing_Do
	
	movlw	    .8
	cpfseq	    Timer1_Times
	bra	    $+4
	call	    Sing_La_m
	return

Sing_Mi	movlw	    Mi
	movwf	    PR2
	return

Sing_Re	movlw	    Re
	movwf	    PR2
	return

Sing_Do	movlw	    Do
	movwf	    PR2
	return

Sing_La_m	movlw	    La_m
	movwf	    PR2
	return
	
Sing_Si_m	movlw	    Si_m
	movwf	    PR2
	return

Hi_ISRs:
    
;==========檢查是哪個旗標進中斷的========  
	btfsc	PIR1,    TMR1IF
	bra	High_TMR1
	btfsc	PIR2,    TMR3IF
	bra	High_TMR3
    
    
High_TMR1
	banksel	    LATD	
	bcf	    PIR1,   TMR1IF  
;=============還原設定TIM1 值==============
	
	movf	    PRODH,  W,	A	; 設定計時器高位元組資料(PRODH:乘法high byte)
	sublw	    0xFF
	movwf	    TMR1H
	movf	    PRODL,  W,	A	; 設定計時器低位元組資料(PRODL:乘法low byte)
	sublw	    0xFF
	movwf	    TMR1L	
;========================================
	
	
	rlncf	    LATD			;第一次空轉，再從下方設定bit0
	movlw	    .0
	cpfsgt	    Timer1_Times
	call	    Timer1_0_times
	
	;movlw	    .9
	;subwf	    Si_m_temp,	F
	;movf	    Si_m_temp,	W
	;movwf	    PR2
	call	    sing_a_song
	bsf	    T2CON,	TMR2ON		;開啟TMR2 (BUZZER)
	bsf	    T3CON,	TMR3ON		;開始累計秒數
	incf	    Timer1_Times		;進入中斷次數加一
	movlw	    .9
	cpfseq	    Timer1_Times		;八次一循環
	retfie	    FAST
	bcf	    T1CON,  TMR1ON  
	bcf	    T3CON,  TMR3ON		;累計幾秒也關閉
	clrf	    Timer1_Times
	incf	    count_times,    F		;排放次數+1
	bcf	    T2CON,	TMR2ON		;關閉TMR2
	retfie	    FAST
Timer1_0_times
	movff	    LED_0_temp,  LATD		;LED_0_temp = b'00000001'
	clrf	    point_1s_Times		;清除上次秒數
	return
	
	
High_TMR3
	
	bcf	    PIR2,    TMR3IF
	movlw	    .254		;0.1秒
	movwf	    TMR3H
	movlw	    .102
	movwf	    TMR3L
	incf	    point_1s_Times, F
	
	retfie	    FAST
	

Low_ISRs:

	bcf	    PIR1,   RCIF				; 清除資料接收中斷旗標
	movff	    RCREG1, RX_Temp				; 將接收資料顯示在LED
;
	movlw	a'R'					; 檢查接收資料是否為’r’?
	cpfseq	RX_Temp
	bsf	Push_R,	0				;設定清除旗標
	
Exit_Low_ISR
	retfie	FAST			; 一般中斷返回

  	END