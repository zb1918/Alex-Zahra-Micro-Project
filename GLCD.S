#include <xc.inc>
    
global  GLCD_Setup, GLCD_Clear, LCD_delay_x4us, Game_Main, Score
global	LCD_SetMode_Instruction, LCD_Enable, LCD_SetMode_Data, LCD_Send_Byte_D, LCD_Set_X
global	LCD_Set_Y
;Reference external variables and subroutines required for this module
extrn	delay, pixelPM, pixelArray
extrn	Int_Setup, Final1, Final2, Final3, Final4
extrn	Key_Return_Data, Key_Reset_Data, Timer_Random_Number, Key_Data
extrn	ADC_Setup, ADC_Read, Multi
extrn	LCD_x, LCD_y, CS1, CS2, LCD_cs
extrn	mid_y, max_y, LCD_counter_x, LCD_counter_y, Score
;declare space for variables in access RAM  
psect	udata_acs   ; named variables in access ram
LCD_cnt_l:	ds 1	; reserve 1 byte for variable LCD_cnt_l
LCD_cnt_h:	ds 1	; reserve 1 byte for variable LCD_cnt_h
LCD_tmp:	ds 1	; reserve 1 byte for temporary use
    
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
	
	
	movlw	64	    ; setting the mid and edge values for the GLCD 
	movwf	mid_y, A
	movlw	128
	movwf	max_y, A
	
	movlw	0	    ;move the correct format for inital score
	movwf	Score	    ;correspponds to a score of zero
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
	
	
LCD_Enable:			     ; pulse enable bit LCD_E for 500ns
	movlw	1
	call	LCD_delay_x4us	    ; delay for 4us
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
