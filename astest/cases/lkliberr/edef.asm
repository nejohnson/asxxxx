	.title	Library Member In The Direct Page

	; Two bytes straddling the end of page 0 once the linker places
	; DPAGE at 0x00FF:  edef_lo lands at 0x00FF and edef_hi at 0x0100,
	; which a direct page reference cannot reach.

	.globl	edef_lo, edef_hi

	.area	DPAGE	(REL,CON)

edef_lo:	.ds	1
edef_hi:	.ds	1

	.end
