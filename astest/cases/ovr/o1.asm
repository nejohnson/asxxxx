	.module	o1
	;
	; A concatenating area and an overlay area, each entered more than
	; once.  CON appends;  OVR restarts, so every block in it begins at
	; the area's start and the area is as big as its largest block.
	;
	.area	DAT	(REL,CON)
d1::	.ds	2
	.area	OVL	(REL,OVR)
o1a::	.ds	8
	.area	DAT	(REL,CON)
d2::	.ds	1
	.area	OVL	(REL,OVR)
o1b::	.ds	12
	.area	OVL	(REL,OVR)
o1c::	.ds	4
	.area	COD	(REL,CON)
start::	.db	1,2,3
