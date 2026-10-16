	.module pdkrng
;
; Addresses that do not fit their field are errors the linker
; reports, and aslink fails:  a RAM address past 0x7F in a 7 bit
; field, and a whole RAM address too big for an 8 bit immediate.
;
	.area CODE
	mov	a, _far			; DATA at 0x80 does not fit 0x7F
	mov	a, #(_x + 0x204)	; nor 0x206 an 8 bit immediate
	.area DATA (DSEG,BANK=_DSEG)
_x:	.ds	0x7E
_far:	.ds	1
