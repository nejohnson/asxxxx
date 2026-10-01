	.module tstz
	.zxn
	.area CODE
;
; Both spellings of every form, in pairs, so the gold shows them
; assembling to the same bytes rather than merely assembling.
;
	tst	#0x33
	tst	a, #0x33
	tst	b
	tst	a, b
	tst	(hl)
	tst	a, (hl)
