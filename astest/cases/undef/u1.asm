	.title	Undefined Global Reference

	.globl	u_missing

	.area	UNDEF	(REL,CON)

u_start:
	.word	u_missing	; nothing defines this

	.end
