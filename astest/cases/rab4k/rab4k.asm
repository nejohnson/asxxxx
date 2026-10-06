	.module rab4k
	.r4k10
	.area CODE
_s::	.ds 4
	.area CODE2
l$:
;
; The Rabbit 4000's 32 bit pairs reuse the Z80's index prefixes: BCDE
; is 0xDD and JKHL is 0xFD in front of the opcode that does the same
; thing to HL.  Mode 10 puts 0x7F in front of a bare HL form, because
; mode 10 has remapped what a bare HL means - which is why .r4k10 is
; assembled here rather than .r4k.  SDCC emits .r4k10.
;
	clr	hl
	cp	hl, de
	cp	hl, #8
	jp	lt, l$
	jp	gt, l$
	jp	gtu, l$
	jp	v, l$
	ld	bcde, #0
	ld	bcde, #-1
	ld	jkhl, #5
	ld	bcde, 4 (sp)
	ld	jkhl, 6 (sp)
	ld	8 (sp), bcde
	ld	10 (sp), jkhl
	ld	bcde, (_s)
	ld	(_s), bcde
	ld	jkhl, (_s)
	ld	(_s), jkhl
	ld	bcde, (hl)
	ld	(hl), bcde
	ld	jkhl, (hl)
	ld	(hl), jkhl
	mulu
	neg	hl
	neg	bcde
	neg	jkhl
	pop	bcde
	pop	jkhl
	push	bcde
	push	jkhl
	push	#0x1234
	rl	bc
	rr	bc
	rlc	bc
	rrc	bc
	rlc	de
	rrc	de
	cbm	#0
	cbm	#3
	ld	-6 (ix), bcde
	ld	bcde, -6 (ix)
	ld	-6 (iy), jkhl
	ld	jkhl, -6 (iy)
	sub	hl, de
	test	hl
	test	bc
	test	bcde
;
; The Z80 conditions keep their Z80 encodings even here.
;
	jp	z, l$
	jp	nz, l$
	jp	c, l$
	jp	nc, l$
;
; And the instructions the earlier Rabbits have are untouched.
;
	rl	de
	rr	de
	ldir
	ldi
	neg
	ipset0
	lsidr
	add	sp, #-6
	push	ip
	ld	a, b
	push	bc
