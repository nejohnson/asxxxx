	.module rab4kbad
	.r4k10
	.area CODE
;
; The 8 bit immediates take -128 to 255 and nothing else.  SDAS takes
; the low byte of whatever it is given, quietly; a value that does not
; fit is far more likely to be a mistake than an intention.
;
	cp	hl, #256
	ld	bcde, #256
;
; And the operand restrictions are real.
;
	clr	bc
	test	de
