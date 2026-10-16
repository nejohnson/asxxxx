	.title	Roots Other Than Reachability

	; Three things a collector must not discard even though no
	; relocation reaches them:  an absolute area, whose address
	; the hardware knows;  an area marked KEEP, which runs
	; because it is laid next to what runs before it;  and an
	; area the user placed with -a.  DROPME has none of those
	; and must go.

	.globl	main

	.area	VECT (ABS,OVR)
	.org	0x0038
	.byte	0xC9

	.area	TEXT (REL,CON,CSEG)
	.function main
main:	.byte	0xC9
	.endfunc

	.area	GSINIT (REL,CON,CSEG,KEEP)
	.byte	0x01

	.area	PLACED (REL,CON,CSEG)
	.byte	0xAA

	.area	DROPME (REL,CON,CSEG)
	.byte	0xBB
