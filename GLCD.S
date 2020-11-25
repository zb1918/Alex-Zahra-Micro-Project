#include <xc.inc>
    
global  GLCD_Setup, GLCD_Clear, LCD_delay_x4us, LCD_delay_ms, GLCD_Main
extrn	delay
extrn	Int_Setup
    
    
psect	udata_acs   ; named variables in access ram
LCD_cnt_l:	ds 1	; reserve 1 byte for variable LCD_cnt_l
LCD_cnt_h:	ds 1	; reserve 1 byte for variable LCD_cnt_h
LCD_cnt_ms:	ds 1	; reserve 1 byte for ms counter
LCD_tmp:	ds 1	; reserve 1 byte for temporary use
LCD_cs:		ds 1	; reserve 1 byte for cs number 
			; (10 or 01 for 1 or 2 respectively)
LCD_x:		ds 1	; reserve 1 byte for x pos, 3 bits
LCD_y:		ds 1	; reserve 1 byte for y pos, 6 bits
LCD_z:		ds 1	; reserve 1 byte for  z pos, 6 bits
CS1:		ds 1	; reserve 1 byte for 10B
CS2:		ds 1	; reserve 1 byte for 01B
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
    
LCD_E	EQU 4	; LCD enable bit
	
psect	glcd_code,class=CODE
GLCD_Setup:
	banksel ANCON0
	clrf    ANCON0, A	; set all pins to digital output, not analogue
	clrf    ANCON1, A
	clrf    ANCON2, A
	movlb	0x00
	
	clrf    TRISH, A
	clrf	TRISD, A
	clrf    PORTH, A
	clrf	PORTD, A
	
	movlw   10
	call	LCD_delay_ms	; allow some time for PORTs and LATs to set
	
	movlw	64	    ; setting the mid and edge values for the GLCD 
	movwf	mid_y, A
	movlw	128
	movwf	max_y, A
	
	movlw	00000010B   ; to allow for movff    CS1, LCD_cs, A
	movwf	CS1, A
	movlw	00000001B
	movwf	CS2, A
	
	movlw	0x0
	call	LCD_Set_CS  ; enable both halves of the display (both CS)
	

	movlw	00111111B   ; init GLCD
	call	LCD_Send_Byte_D
	call	LCD_SetMode_Instruction
	call	LCD_Enable
	
	movlw	10
	call	LCD_delay_x4us	; allow somee time for set up
	
	return
	
GLCD_Clear:
	movlw	00000001B	; Clear CS 2
	call	LCD_Set_CS
	call	LCD_Clear
	
	movlw	00000010B	; Clear CS 1
	call	LCD_Set_CS
	call	LCD_Clear
	
	return	
LCD_Clear:
	movlw	0x0
	movwf	LCD_counter_x, A    ; Set x to 0 before starting
	call	LCD_Clear_x
	return	
LCD_Clear_x:			    ; Loop over all x 
	movlw	0x0
	movwf	LCD_counter_y, A
	
	movf	LCD_counter_x, W, A
	call	LCD_Set_X	    ; Set X
	incf	LCD_counter_x, A    ; Incr X
	
	call	LCD_Clear_y	    ; Loop over all y
	
	movlw	8		    ; Stop at x = 8
	cpfseq	LCD_counter_x, A
	bra	LCD_Clear_x
	
	return	
LCD_Clear_y:			    ; Loop over all y
	call	LCD_Send_Zeroes	    ; Clear byte
	incf	LCD_counter_y, A
	movlw	64		    ; Stop at x = 64
	cpfseq	LCD_counter_y, A
	bra	LCD_Clear_y
	return	
LCD_Send_Zeroes:
	call	LCD_SetMode_Data    ; Set mode to data
	movlw	00000000B
	call	LCD_Send_Byte_D
	call	LCD_Enable	    ; Send B and H to LCD
	call	LCD_SetMode_Instruction	; avoid future errors, set RS back low
	return
    
LCD_Send_Byte_D:	    ; are thesse really necessary? just sending to LATX
	movwf	LATD, A
	return
LCD_Send_Byte_H:
	movwf	LATH, A
	return

LCD_SetMode_Data:
	movlw	00110100B	; rst high, e high, rs high
	iorwf	LCD_cs, W, A	; include the cs bit at the end (10 or 01)
	call	LCD_Send_Byte_H
	return
	
LCD_SetMode_Instruction:
	movlw	00110000B	; rst high, e high, rs low
	iorwf	LCD_cs, W, A	; include the cs bit at the end (10 or 01)
	call	LCD_Send_Byte_H
	return		
	
LCD_Set_CS:		    ; W must contain 1d or 2d
	movwf	LCD_cs, A   ; store the cs#, note this only stored and not sent
	return		    ; to the lcd immediately, sends at next instruction
	
LCD_Set_X:		    ; sets row (page)
	movwf	LCD_x, A
	movlw	10111000B   ; instruction for set x
	iorwf	LCD_x, W, A ; add on the address on the end (last 3 bits)
	call	LCD_Send_Byte_D
	call	LCD_SetMode_Instruction
	call	LCD_Enable
	return
	
LCD_Set_Y:		    ; sets column
	movwf	LCD_y, A    
	movlw	01000000B   ; instruction for set y
	iorwf	LCD_y, W, A ; add on the address on the end (last 6 bits)
	call	LCD_Send_Byte_D
	call	LCD_SetMode_Instruction
	call	LCD_Enable
	return
	
LCD_Set_Z:		    ; sets the starting position (unused) 
	movwf	LCD_z, A
	movlw	11000000B   ; instruction for set z
	iorwf	LCD_z, W, A ; add on the address on the end (last 6 bits)
	call	LCD_Send_Byte_D
	call	LCD_SetMode_Instruction
	call	LCD_Enable
	return
    
GLCD_Main:
	movlw	3	    ; number of characters (i.e full numbers)
	movwf	chars, A
char_test:
	call 	character_loop
	decfsz	chars, A
	bra	char_test
	return
	
character_loop:
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
	
	movf	POSTINC2, W, A	; char
	
	movlw	0
	movwf	pixel_count, A
	call	pixel_loop
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
	movlw	5
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
	
	
    

	
LCD_Enable:			     ; pulse enable bit LCD_E for 500ns
	movlw	10
	call	LCD_delay_x4us	    ; delay for 40us
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bcf	LATH, LCD_E, A	    ; Take enable low
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bsf	LATH, LCD_E, A	    ; Take enable back high
	return
    

	
	
	
	
	
; ** a few delay routines below here as GLCD timing can be quite critical ****
LCD_delay_ms:		    ; delay given in ms in W
	movwf	LCD_cnt_ms, A
lcdlp2:	movlw	250	    ; 1 ms delay
	call	LCD_delay_x4us	
	decfsz	LCD_cnt_ms, A
	bra	lcdlp2
	return
    
LCD_delay_x4us:		    ; delay given in chunks of 4 microsecond in W
	movwf	LCD_cnt_l, A	; now need to multiply by 16
	swapf   LCD_cnt_l, F, A	; swap nibbles
	movlw	0x0f	    
	andwf	LCD_cnt_l, W, A ; move low nibble to W
	movwf	LCD_cnt_h, A	; then to LCD_cnt_h
	movlw	0xf0	    
	andwf	LCD_cnt_l, F, A ; keep high nibble in LCD_cnt_l
	call	LCD_delay
	return	
	
LCD_delay:			; delay routine	4 instruction loop == 250ns	    
	movlw 	0x00		; W=0
lcdlp1:	decf 	LCD_cnt_l, F, A	; no carry when 0x00 -> 0xff
	subwfb 	LCD_cnt_h, F, A	; no carry when 0x00 -> 0xff
	bc 	lcdlp1		; carry, then loop again
	return			; carry reset so return
	;ayfbauif