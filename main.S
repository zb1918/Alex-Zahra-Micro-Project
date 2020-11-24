#include <xc.inc>

global	delay, dataArray
extrn	GLCD_Setup, GLCD_Clear, GLCD_Main
extrn	Key_Setup, Key_Column, Key_Row
extrn	Int_Setup, B_Int
extrn	Timer_Int_Setup, Timer_Int_Low, Timer_Random_Number
    
psect	data    
	; ******* dataPM, data in programme memory, and its length *****
dataPM:    ;    cont, page, xpos, ypos, char, 0   , 1   , 2   , 3   , 4   , 
	db	0x00, 0x10, 0x00, 0x00, 0x05, 0x00, 0x7e, 0x81, 0x81, 0x7e,\
		0x00, 0x10, 0x01, 0x00, 0x05, 0x00, 0x7e, 0x81, 0x81, 0x7e,\
		0x00, 0x10, 0x02, 0x00, 0x05, 0x00, 0x7e, 0x81, 0x81, 0x7e

	dataPM_l   EQU	30	; length of data
	align	2
pixelPM:
	db	0x7e, 0x81, 0x81, 0x7e,\
		0x84, 0x82, 0xff, 0x80,\
		0xc2, 0xa1, 0x91, 0x8e,\
		0x42, 0x81, 0x89, 0x76,\
		0x1f, 0x90, 0xff, 0x90,\
		0x4e, 0x89, 0x89, 0x71,\
		0x7e, 0x89, 0x89, 0x72,\
		0xc1, 0x31, 0x0d, 0x03,\
		0x76, 0x89, 0x89, 0x76,\
		0x46, 0x89, 0x89, 0x7e
	pixelPM_l   EQU	40
	align	2
;; initialise the array of characters that will float across screen
;; format: control byte, page byte, x-co, y-co, cha, l1, l2, l3, l4, l5
;; control byte is a byte that tells us if we are "mid screen" or not i.e. in between the 2 chips
;; page-byte tells us to either select chip 1 if on Left screen or chip 2 on right
;; x-co is the x-line number of the character
;; y-co is the y-column number that the character is at
;; cha is a another control variable for use when the character hits middle of the two chips
;;l1-l5 are just the information encoding the bit-pattern to write
psect	udata_bank4 ; reserve data anywhere in RAM (here at 0x400)
dataArray:  ds 0x80 ; reserve 128 bytes for message data
pixelArray  EQU dataArray + 30

psect	udata_acs   ; named variables in access ram 
counter:	    ds 1
counter2:	    ds 1
character_count:    ds 1
character_count_max:	ds 1    
delay_count1:	    ds 1    
delay_count2:	    ds 1    
delay_count3:	    ds 1
rand_one:	    ds 1
rand_two:	    ds 1
rand_three:	    ds 1
data_pos:	    ds 1
pixel_byte:	    ds 1
pixel_count:	    ds 1
    
psect	code, abs	
rst: 	org 0x0
 	goto	setup
	
int_hi:	org	0x0008	; high vector, no low vector
	btfss	INT0IF
	retfie	f
	call	B_Int
	call	GLCD_Clear
	retfie	f
	
int_lo:	org	0x0018		; low priority interrupts
	goto	Timer_Int_Low	
	
	; ******* Programme FLASH read Setup Code ***********************
setup:	bcf	CFGS		    ; point to Flash program memory 
	bcf	RBIF
	bsf	EEPGD		    ; access Flash program memory
	call	GLCD_Setup
	call	Key_Setup
	call	Int_Setup
	call	Timer_Int_Setup	    ; set up timer interrupts (random no.)
	clrf	TRISC, A
	call	GLCD_Clear	;; clear the GLCD screen
	goto	start
	
	; ******* Main programme ****************************************
start: 	lfsr	0, dataArray	; Load FSR0 with address in RAM	
	movlw	low highword(dataPM)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(dataPM)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(dataPM)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	dataPM_l	; bytes to read
	movwf 	counter, A		; our counter register
data_loop: 	
	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	data_loop		; keep going until finished
	
	lfsr	0, pixelArray	; Load FSR0 with address in RAM	
	movlw	low highword(pixelPM)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(pixelPM)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(pixelPM)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	pixelPM_l	; bytes to read
	movwf 	counter, A		; our counter register
pixel_loop: 	
	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	pixel_loop		; keep going until finished
	
	
	movlw	0
	movwf	character_count, A	; how many of the characters have been replaced?
	movlw	3
	movwf	character_count_max, A	; replacement goal
	

replace_data:
	call	delay
    	lfsr	0, pixelArray
	lfsr	2, dataArray
	
	movlw	10
	mulwf	character_count, A
	movff	PRODL, data_pos, A	; data_pos now contains relative pos to pixelArray
	movlw	6
	addwf	data_pos, A	; data_pos now contains relative pos to dataArray
	
	call	Timer_Random_Number ; random number in W
	movwf	PORTC, A
	movwf	rand_one, A
	movlw	4		    
	mulwf	rand_one, A	    
	movff	PRODL, rand_one, A  ; rand_one is now rel pos to pixelArray
	movlw	5
	movwf	pixel_count, A	    ; set pixel_count to 5 (no of pixels needed to change per character)
	
loop_replace:
	movf	rand_one, W, A	    ; extract relative position to pixelArray
	movf	PLUSW0, W, A	    ; extract single pixel byte
	movwf	pixel_byte, A
	movf	data_pos, W, A	    ; W now contains relative position to dataArray
	movff	pixel_byte, PLUSW2, A	; move pixel to dataArray
	
	incf	data_pos, A
	incf	rand_one, A	    ; increase rel position
	decfsz	pixel_count, A
	bra	loop_replace
	
	
	incf	character_count, A
	movf	character_count, W, A
	cpfseq	character_count_max, A
	bra	replace_data
	
	;; reads out the message from program memory to data memory, 
	;; the FSR2L initially points at 0x00
	
	
	
Loop2:	
	lfsr	2, dataArray
	;call	GLCD_Main	;; GLCD_Main runs the game, and we keep branching back to it
	call	delay		;;
	;decfsz	counter2
	bra	Loop2
	movlw	0xff
	movwf	PORTC, A		;; error handling to show visual sign that the game 
	goto	$		;; has broken out of the loop
	
	
	
    
    
    
	
	goto	$		; goto current line in code

delay:	movlw	0x55
	movwf	delay_count1, A
	movwf	delay_count2, A
	movwf	delay_count3, A
delay1: decfsz	delay_count1, A	; decrement until zero
	bra	delay1
	movwf	delay_count1, A
	decfsz	delay_count2, A
	bra	delay1
	movwf	delay_count1, A
	movwf	delay_count2, A
	decfsz	delay_count3, A
	bra	delay1
	return
	
	end	rst