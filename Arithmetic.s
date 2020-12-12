#include <xc.inc>
    
global	Timer_Int_Setup, Timer_Int_Low, Timer_Random_Number
global  ADC_Setup, ADC_Read
global	Final1, Final2, Final3, Final4, Multi
    
extrn	Score
psect	udata_acs
timer_w_temp:		ds 1
timer_stat_temp:	ds 1
timer_bsr_temp:		ds 1
timer_rand_no:		ds 1
min:			ds 1
max:			ds 1
    
    
    
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
	
psect	timer_code, class=CODE	
   
Timer_Int_Setup:
	;clrf	TRISJ, A	
	clrf	timer_rand_no, A    
	movlw	10001111B	    ; timer speed, Fcyc/x
				    ; speeds are in 0:2 (16MHz - 62.5KHz)
				    ; bit 3 is prescaler (i.e. max, 16MHz)
	movwf	T0CON, A	    ; move to timer0 controller
	bsf	TMR0IE		    ; enable timer0 interrupt
	bsf	GIE		    ; enable all interrupts
	bcf	TMR0IF		    ; clear any flags for timer0
	bcf	TMR0IP		    ; clear priority it ; this is low priority
	movlw	0
	movwf	min, A
	;movff	min, LATJ, A
	movff	min, timer_rand_no, A
	movlw	9
	movwf	max, A
	return

Timer_Int_Low:
	; low priority interrupt so must store data before moving on
	movwf	timer_w_temp, A		    ; timer_w_temp is in virtual bank
	movff	STATUS, timer_stat_temp, A  ; timer_stat_temp located anywhere
	movff	BSR, timer_bsr_temp, A	    ; bsr_temp located anywhere

	btfss	TMR0IF			    ; is this timer0?
	retfie	f			    ; if not then return
	movf	timer_rand_no, W, A
	cpfsgt	max, A			    ; has it reached max?
	movff	min, timer_rand_no, A	    ; set back to min if maxed
	incf	timer_rand_no, A	    ; increase
	;movff	timer_rand_no, LATJ, A	    ; display on J for debug purposes
	bcf	TMR0IF			    ; clear interrupt flag
	
	;restore data from before interrupt
	movff	timer_bsr_temp, BSR, A	    ; restore bsr
	movf	timer_w_temp, W, A	    ; restore wreg
	movff	timer_stat_temp, STATUS, A  ; restore status
	
	retfie	f		
	
Timer_Random_Number:
	movf	timer_rand_no, W, A	    ; move the random number into W
	return

	
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