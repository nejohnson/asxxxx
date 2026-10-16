	.module rabz80
	.z80
	.area CODE
;
; And a Z80 has neither these nor the Rabbit 2000/3000 set - the
; check that the Rabbit instructions are gated on "is a Rabbit" and
; not on "is exactly a Rabbit 2000".
;
	lsidr
	push	ip
