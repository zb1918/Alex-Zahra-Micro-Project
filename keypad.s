#include <xc.inc>

global  Key_Setup, Key_Column_Tris, Key_Row_Tris, Key_Return_Data, Key_Reset_Data,Key_Data
global	Int_Setup, B_Int
global  ADC_Setup, ADC_Read
global	Final1, Final2, Final3, Final4, Multi
extrn	LCD_delay_x4us, LCD_delay_ms, GLCD_Clear
extrn	delay, Score
psect	udata_acs   ; named variables in access ram
Key_Rdata:	ds 1
Key_Cdata:	ds 1
Key_Data:	ds 1  
Row_Col_Byte:	ds 1

Multi_1a:	ds 1    ; reserve 1 byte for variable 1
Multi_1b:	ds 1    ; reserve 1 byte for variable 2
Multi_2a:	ds 1    ; reserve 1 byte for variable 3
Multi_3a:	ds 1    ; reserve 1 byte for variable 3
In_1a:		ds 1    ; reserve 1 byte for variable 3
In_1b:		ds 1    ; reserve 1 byte for variable 3
In_2a:		ds 1    ; reserve 1 byte for variable 3
In_2b:		ds 1    ; reserve 1 byte for variable 3
In_3a:		ds 1    ; reserve 1 byte for variable 3 
Col_1a:		ds 1    ; reserve 1 byte for variable 4
Col_2a:		ds 1    ; reserve 1 byte for variable 4    
Col_2b:		ds 1    ; reserve 1 byte for variable 4	
Col_3a:		ds 1    ; reserve 1 byte for variable 4
Col_3b:		ds 1    ; reserve 1 byte for variable 4
Col_4a:		ds 1    ; reserve 1 byte for variable 4
Res_1a:		ds 1    ; reserve 1 byte for variable 4	
Res_2a:		ds 1    ; reserve 1 byte for variable 4	
Res_3a:		ds 1    ; reserve 1 byte for variable 4
Res_4a:		ds 1    ; reserve 1 byte for variable 4	    
Out_1a:		ds 1    ; reserve 1 byte for variable 4	
Out_2a:		ds 1    ; reserve 1 byte for variable 4	
Out_3a:		ds 1    ; reserve 1 byte for variable 4	
Out_4a:		ds 1    ; reserve 1 byte for variable 4	
Final1:		ds 1	
Final2:		ds 1
Final3:		ds 1
Final4:		ds 1

psect	key_code,class=CODE
    

Key_Setup:
	banksel PADCFG1	    ; PADCFG1 is not in Access Bank!!
	bcf	RBPU	    ; PortE pull-ups on
	bsf	RJPU
	movlb	0x00	    ; set BSR back to Bank 0
	clrf	LATB, A
	clrf	TRISB, A
	clrf	LATJ, A
	clrf	TRISJ, A
	clrf	TRISE, A
	clrf	LATE, A
	return

Int_Setup:
	bcf	RBPU
	bcf	INTEDG0
	bcf	INTEDG1
	bcf	INTEDG2
	bcf	INTEDG3
	
	bsf	IPEN
	
	bsf	INT0IE
	bcf	INT0IF
	;bsf	INT0IP ; doesn't exist
	
	bsf	INT1IE
	bcf	INT1IF
	bsf	INT1IP
	
	bsf	INT2IE
	bcf	INT2IF
	bsf	INT2IP
	
	bsf	INT3IE
	bcf	INT3IF
	bsf	INT3IP
	
	bsf	RBIP
	bsf	PEIE
	bsf	GIE
	return
	
Key_Column_Tris:		; columns connected to J
	movlw	0x00
	movwf	TRISB, A	; send 0 to rows
	movlw	0x0f
	movwf	TRISJ, A	; test J 0:3
	movlw	5
	call	LCD_delay_x4us
	return
	
Key_Row_Tris:			; rows connected to B
    	movlw	0x0f
	movwf	TRISB, A	; test B 0:3
	movlw	0x00
	movwf	TRISJ, A	; send 0 to columns
	movlw	5
	call	LCD_delay_x4us
	return
	
Key_Loop:
    	call	Key_Column_Tris
	movff	PORTJ, Key_Cdata, A
	call	Key_Row_Tris
	movff	PORTB, Key_Rdata, A

	swapf	Key_Rdata, W, A	    ; since both J and B are in 0:3 respectively
	iorwf	Key_Cdata, W, A	    
	movwf	Row_Col_Byte, A
	comf	Row_Col_Byte, A	    ; 0:3 contains row, 4:7 contains column

	return
	
	
B_Int:	
	call	Key_Loop
	clrf	TRISE, A
	;movff	Row_Col_Byte, LATE, A	; debugging the Row_Col_Byte
	call	button_press		; returns the key number pressed
	movwf	Key_Data, A
	movwf	LATE, A			; debugging the Key_Data
	bcf	INT0IF
	bcf	INT1IF
	bcf	INT2IF
	bcf	INT3IF
	return	
	
Key_Reset_Data:
	movlw	0
	movwf	Key_Data, A
	return
	
Key_Return_Data:
	movf	Key_Data, W, A
	return
	
button_press:
button_1:
	movlw	10001000B
	cpfseq	Row_Col_Byte, A
	bra	button_2
	retlw	1
button_2:
	movlw	10000100B
	cpfseq	Row_Col_Byte, A
	bra	button_3
	retlw	2
button_3:
	movlw	10000010B
	cpfseq	Row_Col_Byte, A
	bra	button_4
	retlw	3
button_4:
	movlw	01001000B
	cpfseq	Row_Col_Byte, A
	bra	button_5
	retlw	4
button_5:
	movlw	01000100B
	cpfseq	Row_Col_Byte, A
	bra	button_6
	retlw	5
button_6:
	movlw	01000010B
	cpfseq	Row_Col_Byte, A
	bra	button_7
	retlw	6
button_7:
	movlw	00101000B
	cpfseq	Row_Col_Byte, A
	bra	button_8
	retlw	7
button_8:
	movlw	00100100B
	cpfseq	Row_Col_Byte, A
	bra	button_9
	retlw	8
button_9:
	movlw	00100010B
	cpfseq	Row_Col_Byte, A
	bra	button_0
	retlw	9
button_0:
	movlw	00010100B
	cpfseq	Row_Col_Byte, A
	bra	Key_Fail
	retlw	0

Key_Fail:
	retlw	0


	
ADC_Setup:
	bsf	TRISA, PORTA_RA0_POSN, A  ; pin RA0==AN0 input
	bsf	ANSEL0	    ; set AN0 to analog
	movlw   0x01	    ; select AN0 for measurement
	movwf   ADCON0, A   ; and turn ADC on
	movlw   0x30	    ; Select 4.096V positive reference
	movwf   ADCON1,	A   ; 0V for -ve reference and -ve input
	movlw   0xF6	    ; Right justified output
	movwf   ADCON2, A   ; Fosc/64 clock and acquisition times
	return

ADC_Read:
	bsf	GO	    ; Start conversion by setting GO bit in ADCON0
adc_loop:
	btfsc   GO	    ; check to see if finished
	bra	adc_loop
	return
Eight_16:
	clrf	TRISH
	movf	Multi_1a, W
	mulwf	Multi_1b, A
	movff	PRODH, Col_2a
	movff	PRODL, Col_1a
	movf	Multi_2a, W
	mulwf	Multi_1b, A
	movff	PRODH, Col_3a
	movff	PRODL, Col_2b
	movff	Col_1a, Res_1a
	movf	Col_2a, W
	addwf	Col_2b, W
	movwf	Res_2a, A
	movlw	0x00
	addwfc	Col_3a, W
	movwf	Res_3a
	;goto	$
	return
	
Sixteen_16:
	movff	In_1a, Multi_1a
	movff	In_1b, Multi_1b
	movff	In_2a, Multi_2a
	call	Eight_16
	movff	Res_1a, Out_1a
	movff	Res_2a, Out_2a
	movff	Res_3a, Out_3a
	movff	In_1a, Multi_1a
	movff	In_2b, Multi_1b
	movff	In_2a, Multi_2a
	call	Eight_16
	movf	Res_1a, W
	addwf	Out_2a, F
	movf	Res_2a, W
	addwfc	Out_3a, F
	movlw	0x00
	addwfc	Res_3a, W
	movwf	Out_4a, A
	return

Eight_24:
	movff	In_1a, Multi_1a
	movff	In_2a, Multi_2a
	movff	In_3a, Multi_3a
	movff	In_1b, Multi_1b
	movf	Multi_1a, W
	mulwf	Multi_1b, A
	movff	PRODH, Col_2a
	movff	PRODL, Col_1a
	movf	Multi_2a, W
	mulwf	Multi_1b, A
	movff	PRODH, Col_3a
	movff	PRODL, Col_2b
	movf	Multi_3a, W
	mulwf	Multi_1b, A
	movff	PRODH, Col_4a
	movff	PRODL, Col_3b
	movff	Col_1a, Out_1a
	movf	Col_2a, W
	addwf	Col_2b, W
	movwf	Out_2a, A
	movf	Col_3a, W
	addwfc	Col_3b, W
	movwf	Out_3a, A
	movlw	0x00
	addwfc	Col_4a, W
	movwf	Out_4a
	return
	
Multi:
	movlw	00000100B
	movwf	In_2a
	movlw	01001100B
	addwf	Score, W
	movwf	In_1a
	clrf	TRISF
	movwf	PORTF
	;movff	Score, In_1a
	movlw	0x0F
	andwf	In_2a, F
	movlw	0x8A
	movwf	In_1b
	movlw	0x41
	movwf	In_2b
	call	Sixteen_16
	movf	Out_4a, W
	movwf	Final1
	;call	LCD_Send_Byte_D
	movff	Out_1a, In_1a
	movff	Out_2a, In_2a
	movff	Out_3a, In_3a
	movlw	0x0A
	movwf	In_1b
	call	Eight_24
	movf	Out_4a, W
	movwf	Final2
	;call	LCD_Send_Byte_D
	movff	Out_1a, In_1a
	movff	Out_2a, In_2a
	movff	Out_3a, In_3a
	movlw	0x0A
	movwf	In_1b
	call	Eight_24
	movf	Out_4a, W
	movwf	Final3
	;call	LCD_Send_Byte_D
	movff	Out_1a, In_1a
	movff	Out_2a, In_2a
	movff	Out_3a, In_3a
	movlw	0x0A
	movwf	In_1b
	call	Eight_24
	movf	Out_4a, W
	movwf	Final4	; 
	;call	LCD_Send_Byte_D
	;call	delay
	return
    end
