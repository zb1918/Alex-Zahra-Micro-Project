#include <xc.inc>
    
global  GLCD_Setup, GLCD_Clear, LCD_delay_x4us, LCD_delay_ms, GLCD_Main
extrn	delay
extrn	Int_Setup
    
    
psect	udata_acs   ; named variables in access ram
LCD_cnt_l:	ds 1   ; reserve 1 byte for variable LCD_cnt_l
LCD_cnt_h:	ds 1   ; reserve 1 byte for variable LCD_cnt_h
LCD_cnt_ms:	ds 1   ; reserve 1 byte for ms counter
LCD_tmp:	ds 1   ; reserve 1 byte for temporary use
LCD_counter:	ds 1   ; reserve 1 byte for counting through nessage
YCount:		ds 1
Y_Count_Max:	ds 1
XCount:		ds 1
X_Count_Max:	ds 1
location:	ds 1
location2:	ds 1    
max_pos:	ds 1
counter5:	ds 1
three:		ds 1
counter6:	ds 1
counter7:	ds 1
LCD_counter2:	ds 1
no_char:	ds 1
debugger:	ds 1
debugger2:	ds 1   
	
LCD_CS1	EQU 0	; LCD register select bit
LCD_CS2	EQU 1	; LCD register select bit
LCD_RS	EQU 2	; LCD register select bit
LCD_RW	EQU 3
LCD_E	EQU 4	; LCD enable bit
LCD_RT	EQU 5
	
control	EQU 0
page_no	EQU 0
	
psect	glcd_code,class=CODE
    
GLCD_Setup:
	banksel ANCON0
	clrf    ANCON0, A	; set all pins to digital output, not analogue
	clrf    ANCON1, A
	clrf    ANCON2, A
	movlb	0x00
	movlw	01111011B
	movwf	max_pos
	movlw	3
	movwf	three
	movlw	2
	movwf	debugger
	movlw	0
	movwf	debugger2
	
	
	clrf    TRISH, A
	clrf	TRISD, A
	clrf    PORTH, A
	clrf	PORTD, A
	bsf	LATH, LCD_RT
	bsf	LATH, LCD_E
	movlw   10
	call	LCD_delay_x4us	; wait 40ms for LCD to start up properly
	movlw   0x3F	    ; RD0:5 all outputs
	movwf	PORTD, A
	movlw	10
	call	LCD_delay_x4us
	call	LCD_Enable
	
	
	
	call	LCD_delay_x4us
	
	return
	
LCD_Enable:	    ; pulse enable bit LCD_E for 500ns
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
	return
    
GLCD_Y_address:
	movwf	PORTD, A
	movlw	20
	call	LCD_delay_x4us
	call	LCD_Enable
	;call	LCD_delay_x4us
	return
	
GLCD_CS1:
	bsf	LATH, LCD_CS2
	bcf	LATH, LCD_CS1
	movlw	10
	call	LCD_delay_x4us
	return
GLCD_CS2:
	bsf	LATH, LCD_CS1
	bcf	LATH, LCD_CS2
	movlw	10
	call	LCD_delay_x4us
	return
	
GLCD_X_address:
	movwf	PORTD, A
	movlw	20
	call	LCD_delay_x4us
	call	LCD_Enable
	;call	LCD_delay_x4us
	return
GLCD_Write:
	bsf	LATH, LCD_RS
	movwf	PORTD, A
	movlw	20
	call	LCD_delay_x4us
	call	LCD_Enable
	call	LCD_delay_x4us
	bcf	LATH, LCD_RS	
	clrf	PORTD
	return
	
GLCD_Clear:
	call	GLCD_CS1
	call	GLCD_Clear_Page
	call	GLCD_CS2
	call	GLCD_Clear_Page	
	return
	
GLCD_Clear_Page:
	movlw	10111111B
	movwf	X_Count_Max
	movlw	0xF0
	movwf	Y_Count_Max
	movlw	10111000B
	movwf	XCount
GLCD_Clear_X:
	movf	XCount, W
	call	GLCD_X_address
	call	GLCD_Clear_Row
	incf	XCount, F
	movf	XCount, W
	CPFSLT	X_Count_Max, A
	bra	GLCD_Clear_X
	return	
GLCD_Clear_Row:
	movlw	01000000B
	call	GLCD_Y_address
	movlw	0x00
	movwf	YCount
LoopY:	
	movlw	0x00
	call	GLCD_Write
	incf	YCount, 1, 0
	movf	YCount,W, A
	CPFSLT	Y_Count_Max
	bra	LoopY
	return
	


	


	

	


GLCD_Erase:
	call	GLCD_Y_address
	movlw	0
	call	GLCD_Write
	call	GLCD_Write
	call	GLCD_Write
	call	GLCD_Write
	call	GLCD_Write
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

GLCD_Main:
	movlw	4	    ; number + 1
	movwf	no_char
	clrf	FSR2L
Main_Loop:		    ; moves all characters on screen by one frame
	dcfsnz	no_char
	return
	btfsc	POSTINC2, control	;check control bit to see if err handling needed
	bra	Main_Tran		; branch to transition code
	btfss	INDF2, page_no	; since we know we are not mid page, set page 1 or page 2
	call	GLCD_CS1		;sets chip select 1
	btfsc	POSTINC2, page_no
	call	GLCD_CS2		;set chip select 2
	movf	POSTINC2, W
	call	GLCD_X_address
	movf	INDF2, W
	call	GLCD_Y_address
	incf	INDF2, F, A
	movf	POSTINC2, W
	movf	POSTINC2, W
	movlw	5
	movwf	LCD_counter
	call	GLCD_Send_character
	call	GLCD_Check
	bra	Main_Loop
	
GLCD_Check:
	movlw	7
	subwf	FSR2L, F
	movf	INDF2, W
	CPFSLT	max_pos
	bra	NOT_BITSET
	bra	BITSET
NOT_BITSET:
	movlw	7
	addwf	FSR2L, F
	return
BITSET:	
	call	Main_Bitset
	movlw	10
	addwf	FSR2L, F
	return
	
Main_Tran:
	call	GLCD_CS1
	movf	POSTINC2, W
	movf	POSTINC2, W
	call	GLCD_X_address
	movf	INDF2, W
	call	GLCD_Y_address
	movlw	1
	addwf	POSTINC2, A
	decf	INDF2
	movf	POSTINC2, W
	movwf	LCD_counter	; pixels on left side
	sublw	5	    
	movwf	LCD_counter2	; pixels on right side
	cpfslt	three		; right side > 3? yes = no error handling
	bra	bench		; go to bench if error handling required
	call	Main_Bitclear
bench:	
	call	GLCD_Send_character
	;decfsz	debugger
	;bra	skip3
	;movff	FSR2L, PORTC
	;goto	$
	;call	GLCD_CS2
	movf	LCD_counter2, W
	addwf	FSR2L
	;movff	FSR2L, PORTC
	;movwf	PORTC
	;call	GLCD_Send_character2
	;call	GLCD_CS1
	goto	Main_Loop
	
GLCD_Send_character:
Send_Loop:
	movf    POSTINC2, W, A
	call    GLCD_Write
	decfsz  LCD_counter, A
	bra	Send_Loop
	return
GLCD_Send_character2:
	movlw	7
	subwf	FSR2L, F
	movf	INDF2, W
	call	GLCD_X_address
	movlw	7
	addwf	FSR2L, F
	movlw	01000000B
	call	GLCD_Y_address
Send_Loop2:
	movf    POSTINC2, W, A
	call    GLCD_Write
	decfsz  LCD_counter2, A
	bra	Send_Loop2
	return
    
Main_Bitset:
	movlw	2
	subwf	FSR2L
	btfss	INDF2, page_no
	bra	skip2
	btfsc	INDF2, page_no
	goto	Main_Reset
	
skip2:	movlw	1
	subwf	FSR2L
	bsf	INDF2, control
	return
	
Main_Bitclear:
	movlw	5		; move 5 to W reg
	subwf	FSR2L		; subtract 5 to point back to control bit
	bcf	POSTINC2, control	; clear control bit
	bsf	INDF2, page_no
	movlw	2
	addwf	FSR2L
	movlw	01000000B
	movwf	POSTINC2, F, A
	movlw	5
	movwf	POSTINC2
	return
	
	

	
Main_Reset:
	movlw	1
	subwf	FSR2L, F, A
	clrf	POSTINC2
	clrf	POSTINC2
	movlw	1
	addwf	FSR2L
	movlw	01000000B
	movwf	POSTINC2
	movlw	5
	movwf	INDF2, F, A
	movlw	4
	subwf	FSR2L
	movlw	01111011B
	call	GLCD_Erase
	bsf	debugger2, 0
	return
	
	
LCD_delay:			; delay routine	4 instruction loop == 250ns	    
	movlw 	0x00		; W=0
lcdlp1:	decf 	LCD_cnt_l, F, A	; no carry when 0x00 -> 0xff
	subwfb 	LCD_cnt_h, F, A	; no carry when 0x00 -> 0xff
	bc 	lcdlp1		; carry, then loop again
	return			; carry reset so return
	;ayfbauif