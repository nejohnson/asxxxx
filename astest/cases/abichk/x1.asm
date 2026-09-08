	.title	One calling convention
	.module	x1
	.abi call(1)

	.area	TEXT (REL,CON,CSEG)
	.globl	x2
x1:	.byte	0xC3
	.word	x2
