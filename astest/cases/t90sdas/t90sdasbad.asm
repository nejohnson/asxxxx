	.module t90sdasbad
	.area CODE
;
; Only HL, and the A has to be the A register rather than the start of
; a symbol.
;
	ld	hl,a(de)
