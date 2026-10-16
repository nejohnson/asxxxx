	.title	Agreeing modules
	.module	one
	.abi   call(1) model(small)   

	.area	TEXT (REL,CON,CSEG)
	.globl	two, three
one:	.byte	0xC3
	.word	two
	.word	three
