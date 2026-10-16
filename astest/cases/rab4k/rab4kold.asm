	.module rab4kold
	.r3ka
	.area CODE
;
; None of it is available before the 4000.
;
	clr	hl
	mulu
	test	hl
	ld	bcde, 4 (sp)
	push	bcde
