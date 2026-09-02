	.title	Startup Copying Initialised Data

	; _INIT is not the target of any relocation.  It is reached
	; through a__INIT and l__INIT, symbols the linker generates
	; for the area itself, which is how startup code finds data
	; to copy.  A collector that followed only relocations would
	; discard the data and say nothing.

	.globl	start, a__INIT, l__INIT

	.area	HOME (REL,CON,CSEG)
	.function start
start:	.word	a__INIT
	.word	l__INIT
	.endfunc

	.area	_INIT (REL,CON,CSEG)
	.byte	0x11, 0x22, 0x33, 0x44
