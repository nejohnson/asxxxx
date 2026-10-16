	.module	s1
	;
	; The register bank and the bit bank leave 24 bytes free at
	; 0x08-0x1F.  DAT is 33 bytes in all, too much for the gap, but
	; it is made of three modules' sections and two of them fit:
	; s1's 20 bytes take 0x08, s3's 3 bytes take 0x1C from what is
	; left, and only s2's 10 bytes are laid down after BIT.
	;
	.area	REG	(REL,OVR)
r0::	.ds	8
	.area	BIT	(REL,OVR)
b0::	.ds	1
	.area	DAT	(REL,CON,FIT)
d1::	.ds	20
	.area	STK	(REL,OVR)
s0::	.ds	1
