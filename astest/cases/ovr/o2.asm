	.module	o2
	;
	; A second module:  its blocks overlay the first module's, and its
	; concatenating data is appended after it.
	;
	.area	DAT	(REL,CON)
d3::	.ds	4
	.area	OVL	(REL,OVR)
o2a::	.ds	6
	.area	OVL	(REL,OVR)
o2b::	.ds	3
	.area	COD	(REL,CON)
second::	.db	4,5
