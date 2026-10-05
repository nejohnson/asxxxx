	.module sfrown
	.area CODE
;
; A predefined symbol is registered only when the name is still new,
; and it is registered as a local assigned symbol, so a source that
; carries its own definition keeps it.  Pinned because that is what
; makes the table safe to add to an assembler that shipped without
; one: nothing already written can change meaning.
;
ACC	=	0x0040
acc	=	0x0041
	push	ACC
	push	acc
