	.module pdkbad
	.area CODE
	set0	_x, #8			; a bit number is 0 to 7
	mov	a, sp, a		; not a form mov has
	push	bc			; push takes af
	.area DATA (DSEG,BANK=_DSEG)
_x:	.ds	1
