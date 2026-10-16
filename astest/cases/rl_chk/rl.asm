	.title	Cross Module Relocation

	; Two modules referencing each other's globals, linked with
	; the area placed by -a.  Makes the per CPU relocation tests
	; under ascheck/reloc machine independent.

	.globl	rl_here, rl_word, xab_there, xab_word

	.area	RELOC	(REL,CON)

rl_here:
	.word	rl_here		; a local  label, this area
	.word	xab_there	; a global label, the other module
	.byte	<xab_there	; low  byte of an external
	.byte	>xab_there	; high byte of an external
rl_word:
	.word	xab_word - xab_there	; difference, same area

	.end
