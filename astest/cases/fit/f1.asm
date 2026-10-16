	.module	f1
	;
	; An area with an address of its own leaves a gap behind it.
	; FIT offers an area that gap:  DAT and IDT take it, in the
	; order they are declared, and the stack that follows BIT
	; starts thirteen bytes lower than it otherwise would.
	;
	.area	REG	(REL,OVR)
r0::	.ds	8
	.area	BIT	(REL,OVR)
b0::	.ds	1
	.area	DAT	(REL,CON,FIT)
d0::	.ds	1
	.area	IDT	(REL,CON,FIT)
i0::	.ds	12
	.area	STK	(REL,OVR)
s0::	.ds	1
	;
	; BIG asks for the same gap and does not fit in it, so it is
	; laid down where it would have been without FIT.  That is the
	; half of this that matters:  the attribute is a hint, and an
	; area it cannot help is placed exactly as before.
	;
	.area	BIG	(REL,CON,FIT)
g0::	.ds	40
	.area	END	(REL,CON)
e0::	.ds	1
