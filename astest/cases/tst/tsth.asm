	.module tsth
	.hd64
	.area CODE
;
; The Z180 spells the immediate form with a different opcode, so it
; needs its own pass through the same code.
;
	tst	#0x44
	tst	a, #0x44
	tst	c
	tst	a, c
	tst	(hl)
	tst	a, (hl)
