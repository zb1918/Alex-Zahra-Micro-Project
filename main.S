#include <xc.inc>

global	delay, dataArray
global	pixelPM, pixelArray
extrn	GLCD_Setup, GLCD_Clear, Game_Main
extrn	Key_Setup, Key_Column_Tris, Key_Row_Tris, Key_Return_Data, Key_Reset_Data
extrn	Int_Setup, B_Int
extrn	Timer_Int_Setup, Timer_Int_Low, Timer_Random_Number
extrn	ADC_Setup, ADC_Read

    
psect	data    
	; ******* dataPM, data in programme memory, and its length *****
dataPM:    ;    cont, page, xpos, ypos, char, 0   , 1   , 2   , 3   , 4   , 
	db	0x00, 0x10, 0x01, 0x00, 0x00, 0x00, 0x7e, 0x81, 0x81, 0x7e,\
		0x00, 0x10, 0x02, 0x0a, 0x01, 0x00, 0x84, 0x82, 0xff, 0x80,\
		0x00, 0x10, 0x03, 0x20, 0x02, 0x00, 0xc2, 0xa1, 0x91, 0x8e,\
		0x00, 0x10, 0x04, 0x0a, 0x02, 0x00, 0x42, 0x81, 0x89, 0x76,\
		0x00, 0x10, 0x05, 0x37, 0x02, 0x00, 0x1f, 0x90, 0xff, 0x90
		
	dataPM_l   EQU	50	; length of data
	align	2
pixelPM:	    ; 4 pixels for each number from 0-9 in order
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
	
psect	udata_bank4		    ; reserve data anywhere in RAM (here at 0x400)
dataArray:  ds 0x80		    ; reserve 128 bytes for message data
pixelArray  EQU dataArray + 0x80    ; reserve an array at a different location for pixels

psect	udata_acs		    ; named variables in access ram 
counter:		ds 1	    ; counter for the program memory data transfer
counter2:		ds 1	    ; ^
character_count:	ds 1	    ; digit being handled
character_count_max:	ds 1	    ; total number of digits on screen
delay_count1:		ds 1	    ; delay counter
delay_count2:		ds 1	    ; ^
delay_count3:		ds 1	    ; ^
random_number:		ds 1	    ; pseudo-random number from timer interrupts
data_pos:		ds 1	    ; position of the pixel with respect to dataArray
char_pos:		ds 1	    ; position of pixel with respect to pixelArray
pixel_byte:		ds 1	    ; byte of pixels
pixel_count:		ds 1	    ; pixel number (0-3) in a digit
    
psect	code, abs	
rst: 	org 0x0
 	goto	setup
	
int_hi:	org	0x0008	; high priority interrupts
	call	B_Int	; call interrupt subroutines
	bcf	INT0IF	; clear flags 0-3 on port B
	bcf	INT1IF
	bcf	INT2IF
	bcf	INT3IF
	retfie	f	; fast return from interrupt
	
int_lo:	org	0x0018		; low priority interrupts
	goto	Timer_Int_Low	; goto subroutine for timer interrupts
	
	; ******* Programme FLASH read Setup Code ***********************
setup:	bcf	CFGS		    ; point to Flash program memory 
	bcf	RBIF
	bsf	EEPGD		    ; access Flash program memory
	call	GLCD_Setup	    ; set up GLCD
	call	Int_Setup	    ; set up high priority interrupts (port B)
	call	Timer_Int_Setup	    ; set up low priority interrupts (timer)
	call	Key_Setup	    ; set up keypad
	call	ADC_Setup	    ; set up ADC
	call	GLCD_Clear	    ; clear the GLCD screen
	goto	start
	
	; ******* Main programme ****************************************
start: 	lfsr	0, dataArray		; Load FSR0 with address in RAM	
	movlw	low highword(dataPM)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(dataPM)		; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(dataPM)		; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	dataPM_l		; number of bytes to read
	movwf 	counter, A		; our counter register
data_loop: 	
	tblrd*+				; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0	; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	data_loop		; keep going until finished
	
	lfsr	0, pixelArray		; Load FSR0 with address in RAM	
	movlw	low highword(pixelPM)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(pixelPM)		; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(pixelPM)		; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	pixelPM_l		; bytes to read
	movwf 	counter, A		; our counter register
pixel_loop: 	
	tblrd*+				; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0	; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	pixel_loop		; keep going until finished
	
	
replace_data_master:			
	movlw	5			; number of characters
	movwf	character_count_max, A	; replacement goal
	movlw	0
	movwf	character_count, A	; how many of the characters have been replaced?

replace_data:
	call	delay
    	lfsr	0, pixelArray
	lfsr	2, dataArray
	
	movlw	10			; length of each character's sub array
	mulwf	character_count, A	; multiply by 4 to obtain the reqired sub array of data
	movff	PRODL, data_pos, A	; data_pos now contains relative pos to pixelArray
	movlw	6			; this is pixel start position relative to beginning of data array
	
	addwf	data_pos, A		    ; data_pos now contains relative pos to dataArray
	
	call	Timer_Random_Number	    ; place random number in W
	movwf	random_number, A
	
	movff	data_pos, char_pos, A	
	movlw	2
	subwf	char_pos, W, A
	movff	random_number, PLUSW2, A
	
	lfsr	2, dataArray

	
	
	movlw	4		    	    
	mulwf	random_number, A	    ; multiply by 4 to obtain the reqired sub array of pixels
	movff	PRODL, random_number, A	    ; random_number is now rel pos to pixelArray
	movlw	5
	movwf	pixel_count, A		    ; set pixel_count to 5 (no of pixels needed to change per character)
	
loop_replace:
	movf	random_number, W, A	    ; extract relative position to pixelArray
	movf	PLUSW0, W, A		    ; extract single pixel byte
	movwf	pixel_byte, A
	movf	data_pos, W, A		    ; W now contains relative position to dataArray
	movff	pixel_byte, PLUSW2, A	    ; move pixel to dataArray
	incf	data_pos, A
	incf	random_number, A	    ; increase rel position
	decfsz	pixel_count, A
	bra	loop_replace
	incf	character_count, A
	movf	character_count, W, A
	cpfseq	character_count_max, A
	bra	replace_data
	
Game_loop:	
	lfsr	2, dataArray
	call	Game_Main	;; Game_Main runs the game, and we keep branching back to it
	call	delay		;;
	bra	Game_loop
	
	
	
;Cascaded delay loop to allow variable game speed
delay:	movlw	0x44
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
