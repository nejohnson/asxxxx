	.module gbreloc
	.globl	_hi
	.globl	_lo
	.area	CODE
	ldh	a,(_hi + 0)
	ldh	(_hi + 0),a
	ldh	a,(_lo + 0)
	ldh	(_lo + 0),a
