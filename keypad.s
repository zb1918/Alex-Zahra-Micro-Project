#include <xc.inc>

global  Key_Setup, Key_Column_Tris, Key_Row_Tris, Key_Return_Data, Key_Reset_Data,Key_Data
global	Int_Setup, B_Int
global  ADC_Setup, ADC_Read
extrn	LCD_delay_x4us, LCD_delay_ms, GLCD_Clear
extrn	delay
psect	udata_acs   ; named variables in access ram
Key_Rdata:	ds 1
Key_Cdata:	ds 1
Key_Data:	ds 1  
Row_Col_Byte:	ds 1
	


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

    end











