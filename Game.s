#include <xc.inc>
    
global	Game_Main
global	CS1, CS2, LCD_x, LCD_y, Score, mid_y, max_y, LCD_cs, LCD_counter_x, LCD_counter_y
    
;Reference external variables and subroutines required for this module
extrn	Multi
extrn	Key_Return_Data, Key_Reset_Data
extrn	Timer_Random_Number
extrn	ADC_Read
extrn	LCD_SetMode_Instruction, LCD_Enable, LCD_SetMode_Data, LCD_Send_Byte_D, LCD_Set_X
extrn	LCD_Set_Y
extrn	Key_Data
extrn	Final4, Final3, pixelArray
;declare space for variables in access RAM  
psect	udata_acs
LCD_cs:		ds 1	; reserve 1 byte for cs number 
			; (10 or 01 for 1 or 2 respectively)
LCD_x:		ds 1	; reserve 1 byte for x pos, 3 bits
LCD_y:		ds 1	; reserve 1 byte for y pos, 6 bits
CS1:		ds 1	; reserve 1 byte for 10B
CS2:		ds 1	; reserve 1 byte for 01B
char_value:	ds 1
keypress:	ds 1
pixel_count:    ds 1	; reserve 1 byte to count pixels in a chaaracter
pixel_y_start:  ds 1	; reserve 1 byte for character y start
pixel_y_total:  ds 1	; reserve 1 byte for pixel y
pixel_y:	ds 1	; reserve 1 byte for pixel AND 63d
mid_y:		ds 1	; reserve 1 byte for 63d
max_y:		ds 1	; reserve 1 byte for 128d
chars:		ds 1	; reserve 1 byte for number of characters
LCD_char_x:	ds 1	; reserve 1 byte for x pos of character
LCD_counter_x:  ds 1	; reserve 1 byte for LCD_Clear loop over x
LCD_counter_y:  ds 1	; reserve 1 byte for LCD_Clear loop over y
pos_pixelArray:	ds 1
pos_dataArray:	ds 2
pos_dataArray2:	ds 2
Score:		ds 1
LCD_temp:	ds 1 
    
psect	game_code,class=CODE 
Game_Main:
	movlw	5	    ; number of characters (i.e full numbers)
	movwf	chars, A
char_test:
	call	score_update
	call 	character_loop
	decfsz	chars, A
	bra	char_test
	return
	
score_update:			;Subroutine calculates the constituent decimal degits that make
				;up the score and writes them to the scoreboard
	movff	FSR0L, pos_dataArray		    ;store FSR0 in a temp var
	movlw	1
	movwf	LCD_cs
	movlw	7
	movwf	LCD_char_x
	movlw	0
	movwf	pixel_y
	call	Multi
	clrf	TRISC
	movff	Final4, PORTC	;This corresponds to the 2nd digit
			    	;this corresponds to the first digit
	LFSR	0, pixelArray	;i.e. for a score of 9, Final 3 = 0, Final4 = 9
				;for a score of 14, final3 = 1, final4 = 4
				;for a score of 35, final3 = 3, final4 = 5
	movlw	4			
	mulwf	Final3
	movff	PRODL, pos_pixelArray
	movf	pos_pixelArray, W
	addwf	FSR0L
	movf	POSTINC0, W
	call	send_pixel2
	incf	pixel_y
	movf	POSTINC0, W
	call	send_pixel2
	incf	pixel_y
	movf	POSTINC0, W
	call	send_pixel2
	incf	pixel_y
	movf	POSTINC0, W
	call	send_pixel2
	
	
	LFSR	0, pixelArray	;i.e. for a score of 9, Final 3 = 0, Final4 = 9
				;for a score of 14, final3 = 1, final4 = 4
				;for a score of 35, final3 = 3, final4 = 5
	movlw	6
	movwf	pixel_y
	movlw	4			
	mulwf	Final4
	movff	PRODL, pos_pixelArray
	movf	pos_pixelArray, W
	addwf	FSR0L
	movf	POSTINC0, W
	call	send_pixel2
	incf	pixel_y
	movf	POSTINC0, W
	call	send_pixel2
	incf	pixel_y
	movf	POSTINC0, W
	call	send_pixel2
	incf	pixel_y
	movf	POSTINC0, W
	call	send_pixel2
	
	
	movff	pos_dataArray, FSR0L	;restore the value of FSR0L
	return
character_loop:		; loops over one character in one frame

	
	movf	POSTINC2, A	; control (unused)
	movf	POSTINC2, A	; cs should init as 10
	
	movff	POSTINC2, LCD_char_x, A	; x stored for future use for character	
	
	movf	INDF2, W, A	; y
	movwf	pixel_y_start, A
	incf	INDF2, A	; increase the y position indirectly
	movf	INDF2, W, A	; extract new y position for tests
	
	cpfsgt	max_y, A	; will it reach 128?
	clrf	INDF2, A	; set back to 0 if so
	
	movf	POSTINC2, A	; postinc called (but not used) after test to avoid errors
	
	movf	POSTINC2, W, A	; char bit extracted; this givess the value of the pixels i.e. what number
	movwf	char_value, A
	
	movlw	0
	movwf	pixel_count, A	; start at pixel 0

	keypress_test:		; has this character been pressed by user?
	call	Key_Return_Data
	movwf	keypress, A
	xorwf	char_value, A
	movlw	0
	cpfsgt	char_value, A
	bra	pixel_replace    ; replace pixels to new random number	
	call	pixel_loop	 ; value and key press don't match so continue as normal
	return
	
pixel_replace:			 ; subroutine to replace pixels by a new set if the correct key has been pressed
	call	pixel_clear 
	call	pixel_loop
	call	Timer_Random_Number
	;*** calculating positions of data and pixels to replace the data ***;
	; data
	movlw	6
	subwf	FSR2L
	movff	FSR0L, pos_dataArray	    ; store the position of the beginning of dataArray
	call    ADC_Read		    ; read ADC
	movff	ADRESL, pos_pixelArray	    ; store random number
	movf	pos_pixelArray, W
	andlw	00000111B		    ;limit random number to 8
	movwf	pos_pixelArray
	movwf	INDF2
	movlw	2
	addwf	FSR2L			     ; store dataArray relative position in FSR2
	
	; pixels
	LFSR	0, pixelArray
	movlw	4			     ; calculate position of random number's pixels in pixelArray
	mulwf	pos_pixelArray
	movff	PRODL, pos_pixelArray
	movf	pos_pixelArray, W
	addwf	FSR0L			    ; store pixelArray relative position in FSR0
	
	;replace
	movff	POSTINC0, POSTINC2	    ; transfer of data from pixelArray to dataArray
	movff	POSTINC0, POSTINC2
	movff	POSTINC0, POSTINC2
	movff	POSTINC0, POSTINC2
	
	
	movff	pos_dataArray, FSR0L	; reset dataArray position
	incf	Score
	return
	
	
pixel_clear:
	call	Key_Reset_Data		; reset the key press data
	movff	FSR2L, pos_dataArray2   ; store the position of FSR2
	movlw	2
	subwf	FSR2L			; goto y position
	movlw	1			; reset the y position back to 0
	movwf	INDF2
	movlw	2			; go back to pixel bytes
	addwf	FSR2L
	
	clrf	POSTINC2, A
	clrf	POSTINC2, A
	clrf	POSTINC2, A	
	clrf	POSTINC2, A	
	clrf	POSTINC2, A	        ;clears all 5 lines
	
	
	movff	pos_dataArray2, FSR2L   ;reset position of FSR2
	return

	
	
pixel_loop:
	movff	CS1, LCD_cs, A		; set first CS
	movf	pixel_count, W, A	; extract pixel number to W
	addwf	pixel_y_start, W, A	; add to start position and store in W
	movwf	pixel_y_total, A	; = abs y position of an individual pixel byte
	movwf	pixel_y, A	
	movlw	00111111B		; AND pixel_y_total to limit to 63
	andwf	pixel_y, A		; = rel y position of an individual pixel byte
	
	movf	pixel_y_total, W, A	; extract total for detail handling
	
	cpfsgt	mid_y, A		; exec next line if pixel_y_total >= 64
	movff	CS2, LCD_cs, A		; CS2
	
	cpfsgt	max_y, A		; exec next line if pixel_y_total >= 128
	movff	CS1, LCD_cs, A		; CS1
	; note : order of operations is crucial; if y > 128, then y > 64
	; must take care not to set CS2 for y > 128

	movf	pixel_y, W, A	    
	call	send_pixel	    ; use ANDed y position to avoid errors  
				    ; when Set_Y IORs with 01000000B
	
	incf	pixel_count, A	    ; next pixel
	movlw	5		    ; number of pixels
	cpfseq	pixel_count, A	    ; after 5 pixels, return
	bra	pixel_loop
	
	return
	
send_pixel:			    ; W register should contain ANDed y position
	call	LCD_Set_Y	    ; set Y to W register
	movf	LCD_char_x, W, A
	call	LCD_Set_X	    ; set X, this is required if cs# has changed
	
	movf	POSTINC2, W, A	    ; pixel to be sent in W
	call	LCD_Send_Byte_D	    ; send to D
	call	LCD_SetMode_Data    ; set to data mode (RS high)
	call	LCD_Enable	    ; pulse enable to send to GLCD
	call	LCD_SetMode_Instruction	; set RS low to avoid future errors
	return
	
send_pixel2:			;Special send subroutine for sending the score decimal digits to row 7
	movwf	LCD_temp
	movf	pixel_y, W, A
	call	LCD_Set_Y	    ; set Y to W register
	movf	LCD_char_x, W, A
	call	LCD_Set_X	    ; set X, this is required if cs# has changed
	
	movf	LCD_temp, W	    ; 
	call	LCD_Send_Byte_D	    ; send to D
	call	LCD_SetMode_Data    ; set to data mode (RS high)
	call	LCD_Enable	    ; pulse enable to send to GLCD
	call	LCD_SetMode_Instruction	; set RS low to avoid future errors
	return