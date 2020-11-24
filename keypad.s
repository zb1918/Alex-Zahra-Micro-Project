#include <xc.inc>

global  Key_Setup, Key_Column, Key_Row
global	Int_Setup, B_Int
extrn	LCD_delay_x4us, LCD_delay_ms
extrn	delay
psect	udata_acs   ; named variables in access ram
Key_Rdata:ds 1
Key_Cdata:ds 1
Key_data:ds 1  
Key_temp:ds 1
Key_temp2:ds 1
Key_test:ds 1
	


psect	key_code,class=CODE
    

Key_Setup:
	banksel PADCFG1	    ; PADCFG1 is not in Access Bank!!
	bcf	RBPU	    ; PortE pull-ups on
	movlb	0x00	    ; set BSR back to Bank 0
	movlw	0x00
	movwf	PORTB, A
	call	Key_Row
	return
Key_Column:
	movlw	00001111B
	movwf	TRISB, A
	movlw	10
	call	LCD_delay_x4us
	return
Key_Row:
	movlw	11110000B
	movwf	TRISB, A
	movlw	10
	call	LCD_delay_x4us
	return
KeyMain:
	call	KeyLoop
	TSTFSZ	Key_temp, A
	call	button_test
	bra	KeyMain
	
KeyLoop:
	call	Key_Column
	movff	PORTD, Key_Cdata
	call	Key_Row
	movff	PORTD, Key_Rdata
	movf	Key_Cdata, W
	xorwf	Key_Rdata, W
	XORLW	0xFF
	movwf	Key_temp, A

	return
	
button_test:
	movff	Key_temp, Key_temp2
	movlw	10
	call	LCD_delay_ms
	call	KeyLoop
	movf	Key_temp, W
	XORWF	Key_temp2, F
	TSTFSZ	Key_temp2, A
	return
	call	button_press
	movwf	Key_temp
	call	Key_Display
	return
	
button_press:
button_1:
	movf	Key_temp, W
	XORLW	00010001B
	movwf	Key_test, A
	TSTFSZ	Key_test, A
	bra	button_2
	retlw	'1'
button_2:
	movf	Key_temp, W
	XORLW	00010010B
	movwf	Key_test, A
	TSTFSZ	Key_test, A
	bra	button_3
	retlw	'2'
button_3:
	movf	Key_temp, W
	XORLW	00010100B
	movwf	Key_test, A
	TSTFSZ	Key_test, A
	bra	button_4
	retlw	'3'
button_4:
	movf	Key_temp, W
	XORLW	00011000B
	movwf	Key_test, A
	TSTFSZ	Key_test, A
	bra	button_5
	retlw	'F'
button_5:
	movf	Key_temp, W
	XORLW	00100001B
	movwf	Key_test, A
	TSTFSZ	Key_test, A
	bra	button_6
	retlw	'4'
button_6:
	movf	Key_temp, W
	XORLW	00100010B
	movwf	Key_test, A
	TSTFSZ	Key_test, A
	bra	button_7
	retlw	'5'
button_7:
	movf	Key_temp, W
	XORLW	00100100B
	movwf	Key_test, A
	TSTFSZ	Key_test, A
	bra	button_8
	retlw	'6'
button_8:
	movf	Key_temp, W
	XORLW	00101000B
	movwf	Key_test
	TSTFSZ	Key_test, A
	bra	button_9
	retlw	'E'
button_9:
	movf	Key_temp, W
	XORLW	01000001B
	movwf	Key_test, A
	TSTFSZ	Key_test, A
	bra	button_10
	retlw	'7'
button_10:
	movf	Key_temp, W
	XORLW	01000010B
	movwf	Key_test
	TSTFSZ	Key_test, A
	bra	button_11
	retlw	'8'
button_11:
	movf	Key_temp, W
	XORLW	01000100B
	movwf	Key_test, A
	TSTFSZ	Key_test, A
	bra	button_12
	retlw	'9'
button_12:
	movf	Key_temp, W
	XORLW	01001000B
	movwf	Key_test
	TSTFSZ	Key_test, A
	bra	button_13
	retlw	'D'
button_13:  
	movf	Key_temp, W
	XORLW	10000001B
	movwf	Key_test, A
	TSTFSZ	Key_test, A
	bra	button_14
	retlw	'A'
button_14:
	movf	Key_temp, W
	XORLW	10000010B
	movwf	Key_test, A
	TSTFSZ	Key_test, A
	bra	button_15
	retlw	'0'
button_15:
	movf	Key_temp, W
	XORLW	10000100B
	movwf	Key_test, A
	TSTFSZ	Key_test, A
	bra	button_16
	retlw	'B'
button_16:
	movf	Key_temp, W
	XORLW	10001000B
	movwf	Key_test, A
	TSTFSZ	Key_test, A
	bra	Key_Fail
	retlw	'C'
Key_Fail:
	POP
	return
	
Key_Display:
	;call	LCD_Line1
	;call	LCD_Send_Byte_D
	call	delay
	return
	
B_Int:	
	clrf	TRISE
	setf	PORTE
	call	delay
	clrf	PORTE
	bcf	INT0IF
	;goto	GLCD_Test
	return
	;retfie	f		; fast return from interrupt

Int_Setup:
	bcf	RBPU
	movlw	0x0F
	movwf	TRISB
	;clrf	TRISJ
	;clrf	PORTJ
	clrf	PORTB
	bcf	INT0IF
	bcf	INTEDG0
	bsf	IPEN
	bsf	INT0IE
	bsf	PEIE
	bsf	GIE
	return
	
	
	


	

    end











