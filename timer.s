#include <xc.inc>
    
global	Timer_Int_Setup, Timer_Int_Low, Timer_Random_Number
    
psect	udata_acs
timer_w_temp:		ds 1
timer_stat_temp:	ds 1
timer_bsr_temp:		ds 1
timer_rand_no:		ds 1
min:			ds 1
max:			ds 1
	
psect	timer_code, class=CODE	
   
Timer_Int_Setup:
	clrf	TRISJ, A	
	clrf	timer_rand_no, A    
	movlw	10001111B	    ; timer speed, Fcyc/x
				    ; speeds are in 0:2 (16MHz - 62.5KHz)
				    ; bit 3 is prescaler (i.e. max, 16MHz)
	movwf	T0CON, A	    ; move to timer0 controller
	bsf	TMR0IE		    ; enable timer0 interrupt
	bsf	GIE		    ; enable all interrupts
	bcf	TMR0IF		    ; clear any flags for timer0
	bcf	TMR0IP		    ; clear priority it ; this is low priority
	movlw	5
	movwf	min, A
	movff	min, LATJ, A
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
	movff	timer_rand_no, LATJ, A	    ; display on J for debug purposes
	bcf	TMR0IF			    ; clear interrupt flag
	
	;restore data from before interrupt
	movff	timer_bsr_temp, BSR, A	    ; restore bsr
	movf	timer_w_temp, W, A	    ; restore wreg
	movff	timer_stat_temp, STATUS, A  ; restore status
	
	retfie	f		
	
Timer_Random_Number:
	movf	timer_rand_no, W, A	    ; move the random number into W
	return