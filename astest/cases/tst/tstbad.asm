	.module tstbad
	.zxn
	.area CODE
;
; a is the only destination tst has.  Naming any other register is a
; mistake, not a second spelling, and must stay refused.
;
	tst	b, #0x33
	tst	b, c
	tst	(hl), a
