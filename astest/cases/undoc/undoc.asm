	.module undoc
	.allow_undocumented
	.area CODE
;
; The undocumented half register instructions.  An index register's
; halves stand in for h and l behind a DD or FD prefix, so each of
; these is an ordinary opcode with a prefix in front of it.
;
	ld	ixh, #0x12
	ld	ixl, #0x34
	ld	iyh, #0x56
	ld	iyl, #0x78
	ld	a, ixh
	ld	b, ixl
	ld	c, iyh
	ld	d, iyl
	ld	ixh, a
	ld	ixl, b
	ld	iyh, c
	ld	iyl, d
	ld	ixh, ixl
	ld	ixl, ixh
	ld	iyh, iyl
	ld	iyl, iyh
	add	a, ixh
	adc	a, ixl
	sub	iyh
	sbc	a, iyl
	and	ixh
	xor	ixl
	or	iyh
	cp	iyl
	inc	ixh
	inc	ixl
	dec	iyh
	dec	iyl
