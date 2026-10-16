	.module sll
	.area CODE
;
; sll is undocumented but present in the opcode table, and shifts
; left putting a 1 into bit 0.  Every addressing mode the documented
; shifts accept.
;
	sll	b
	sll	c
	sll	d
	sll	e
	sll	h
	sll	l
	sll	(hl)
	sll	a
	sll	(ix+4)
	sll	(iy-4)
