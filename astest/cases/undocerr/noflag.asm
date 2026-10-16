	.module noflag
	.area CODE
;
; Without the directive these stay refused, exactly as before, so no
; program that assembles today changes meaning.
;
	ld	a, ixh
	ld	iyl, b
	add	a, ixl
	inc	iyh
