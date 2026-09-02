	.title	Reachability

	; main reaches used, used reaches chain1, chain1 reaches
	; chain2.  Nothing reaches unused, so neither it nor the
	; orphan it alone refers to belongs in the program.

	.area	TEXT (REL,CON,CSEG)
	.globl	main, used, unused, chain1, chain2, orphan

	.function main
main:	.byte	0xC3
	.word	used
	.endfunc
	.function used
used:	.byte	0xC3
	.word	chain1
	.endfunc
	.function chain1
chain1:	.byte	0xC3
	.word	chain2
	.endfunc
	.function chain2
chain2:	.byte	0xC9
	.endfunc
	.function unused
unused:	.byte	0xC3
	.word	orphan
	.endfunc
	.function orphan
orphan:	.byte	0xC9
	.endfunc
