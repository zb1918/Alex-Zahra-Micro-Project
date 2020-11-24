#include <xc.inc>
    
global  GLCD_Setup, GLCD_Clear, LCD_delay_x4us, LCD_delay_ms, GLCD_Main
extrn	delay
extrn	Int_Setup
    
    
psect	udata_acs   ; named variables in access ram
LCD_cnt_l:	ds 1   ; reserve 1 byte for variable LCD_cnt_l
LCD_cnt_h:	ds 1   ; reserve 1 byte for variable LCD_cnt_h
LCD_cnt_ms:	ds 1   ; reserve 1 byte for ms counter
LCD_tmp:	ds 1   ; reserve 1 byte for temporary use
    LCD_cs:	ds 1
    LCD_x:	ds 1
    LCD_y:	ds 1
    LCD_z:	ds 1
    pixel_count:    ds 1
    pixel_y_start:  ds 1
    mid_y:	ds 1
    max_y:	ds 1
    chars:	ds 1
    LCD_counter_x:  ds 1
    LCD_counter_y:  ds 1
LCD_RS	EQU 2	; LCD register select bit
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
	movlw   40
	call	LCD_delay_ms
	
	movlw	64
	movwf	mid_y, A
	movlw	128
	movwf	max_y, A
	
	movlw	4
	movwf	chars, A
	
	movlw	0x0
	call	LCD_Set_CS
	

	movlw	00111111B
	call	LCD_Send_Byte_D
	call	LCD_SetMode_Instruction
	movlw   40
	call	LCD_delay_ms
	call	LCD_Enable
	movlw	40
	call	LCD_delay_x4us
	
	return
	
GLCD_Clear:
	movlw	00000010B
	call	LCD_Set_CS
	call	lcdclrlp
	
	movlw	00000001B
	call	LCD_Set_CS
	call	lcdclrlp
	
	;;;;;;;;;;;;;;;;;;;
	
	movlw	00000000B
	call	LCD_Set_X
	movlw	00000000B
	call	LCD_Set_Y
	movlw	00000000B
	call	LCD_Set_Z

	
	
	movlw	0xf0
	call	LCD_Send_Byte_D
	call	LCD_SetMode_Data
	call	LCD_Enable
	
	
	return	
lcdclrlp:
	movlw	0x0
	movwf	LCD_counter_x, A
	call	lcdclrlp1
	return	
lcdclrlp1:
	movlw	0x0
	movwf	LCD_counter_y, A
	
	movf	LCD_counter_x, W, A
	call	LCD_Set_X
	incf	LCD_counter_x, A
	
	call	lcdclrlp2
	
	movlw	7
	cpfseq	LCD_counter_x, A
	bra	lcdclrlp1
	
	return	
lcdclrlp2:
	call	LCD_Send_Zeroes
	incf	LCD_counter_y, A
	movlw	63
	cpfseq	LCD_counter_y, A
	bra	lcdclrlp2
	return	
LCD_Send_Zeroes:
	call	LCD_SetMode_Data
	movlw	00000000B
	call	LCD_Send_Byte_D
	call	LCD_Enable
	call	LCD_SetMode_Instruction
	return
    
LCD_Send_Byte_D:
	movwf	LATD, A
	return
LCD_Send_Byte_H:
	movwf	LATH, A
	return
	
LCD_SetMode_Data:
	movlw	00010100B
	iorwf	LCD_cs, W, A
	call	LCD_Send_Byte_H
	return
	
LCD_SetMode_Instruction:
	movlw	00010000B
	iorwf	LCD_cs, W, A
	call	LCD_Send_Byte_H
	return		
	
LCD_Set_CS:
	movwf	LCD_cs, A
	return
	
LCD_Set_X:
	movwf	LCD_x, A
	movlw	10111000B
	iorwf	LCD_x, W, A
	call	LCD_Send_Byte_D
	call	LCD_SetMode_Instruction
	call	LCD_Enable
	return
	
LCD_Set_Y:
	movwf	LCD_y, A
	movlw	01000000B
	iorwf	LCD_y, W, A
	call	LCD_Send_Byte_D
	call	LCD_SetMode_Instruction
	call	LCD_Enable
	return
	
LCD_Set_Z:
	movwf	LCD_z, A
	movlw	11000000B
	iorwf	LCD_z, W, A
	call	LCD_Send_Byte_D
	call	LCD_SetMode_Instruction
	call	LCD_Enable
	return
    
GLCD_Main:
	decfsz	chars, A
	call	character_loop
	return
	
character_loop:
	movf	POSTINC2, W, A	; control
	movf	POSTINC2, W, A	; cs should init as 10
	call	LCD_Set_CS
	movf	POSTINC2, W, A	; x should init as 0
	call	LCD_Set_X
	movf	INDF2, W, A	; y
	movwf	pixel_y_start, A
	incf	INDF2, W, A	; increase the pixel start after extraction
	cpfseq	max_y, A	; clear if it has reached 128
	clrf	POSTINC2, A 
	
	movf	POSTINC2, W, A	; char
	movlw	0x0
	movwf	pixel_count, A
	call	pixel_loop
	return
pixel_loop:
	movf	pixel_count, W, A
	addwf	pixel_y_start, A    ; the y position of an individual pixel byte
	movf	pixel_y_start, W, A
	
	cpfsgt	mid_y, A    ; if pixel exceeds 63 then execute next line
	bra	toggle_cs	  
	
	; if pixel does not exceed y = 63
	bra	send_pixel
	
toggle_cs:
	comf	LCD_cs, A
	movlw	00000011B
	andwf	LCD_cs, A	; toggle the display
	
	call	LCD_Set_CS
	movf	mid_y, W, A
	subwf	pixel_y_start, A
	movf	pixel_y_start, W, A
	
	bra	send_pixel

send_pixel:
	call	LCD_Set_Y
	call	LCD_SetMode_Data
	movf	POSTINC2, W, A	; pixel
	call	LCD_Send_Byte_D
	call	LCD_Enable
	call	LCD_SetMode_Instruction
	
	incf	pixel_count, A
	movlw	5
	cpfseq	pixel_count, A
	bra	pixel_loop
	return
	
	
    

	
LCD_Enable:	    ; pulse enable bit LCD_E for 500ns
	movlw	40
	call	LCD_delay_x4us
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bcf	LATH, LCD_E, A	    ; Take enable high
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bsf	LATH, LCD_E, A	    ; Writes data to LCD
	movlw	40
	call	LCD_delay_x4us
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