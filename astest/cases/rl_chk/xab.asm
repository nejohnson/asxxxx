	.title	Cross Module Relocation, Second Module

	.globl	rl_here, xab_there, xab_word

	.area	RELOC	(REL,CON)

xab_there:
	.word	rl_here		; back reference to the first module
xab_word:
	.word	xab_there
