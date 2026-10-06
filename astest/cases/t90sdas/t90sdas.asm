	.module t90sdas
	.area CODE
;
; RLD and RRD rotate a digit through (HL).  There is nowhere else for
; them to work, so Toshiba's manual, SDAS and SDCC all write them with
; no operand; this assembler wanted one.  Each pair is one instruction.
;
	rrd
	rrd	(hl)
	rld
	rld	(hl)
;
; And (HL+A), which SDAS and SDCC write "a(hl)".  A is a register in
; its own right, so it is taken as one before anything looks for the
; rest of the form - which is why it used to end up a symbol.
;
	ld	hl,(hl+a)
	ld	hl,a(hl)
	ld	a,(hl+a)
	ld	a,a(hl)
	ld	bc,(hl+a)
	ld	bc,a(hl)
;
; The ordinary indexed forms are untouched: "a" before a parenthesis
; is only HL+A when the register inside really is HL.
;
	ld	a,4 (ix)
	ld	a,(ix+4)
