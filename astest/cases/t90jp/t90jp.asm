	.module t90jp
	.area CODE
l$:
;
; A jump through a register, written both ways.  This assembler's own
; tt90.asm writes "jp t,hl"; Toshiba's manual, SDAS and SDCC all write
; "jp (hl)".  Each pair below is one instruction.
;
	jp	t,hl
	jp	(hl)
	call	t,hl
	call	(hl)
	jp	t,ix
	jp	(ix)
	jp	t,iy
	jp	(iy)
	jp	t,bc
	jp	(bc)
	jp	t,hl+a
	jp	(hl+a)
	jp	t,sp+3
	jp	(sp+3)
	jp	nz,hl
	jp	nz,(hl)
;
; A direct address keeps its own opcode when no condition is written,
; and only reaches the prefixed form when one is - including when the
; condition written is the always condition.
;
	jp	l$
	call	l$
	jp	t,l$
	jp	nz,l$
