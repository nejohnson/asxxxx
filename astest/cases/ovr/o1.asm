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
	;
	; An area that is ABS as well as OVR is positioned by .org, and
	; that has to keep working on re-entry:  the restart is for
	; overlays, not for absolute areas, which have an address of
	; their own.  Two blocks at two origins, and a third re-entry
	; with no .org at all, which resumes where the second left off.
	;
	.area	FIX	(ABS,OVR)
	.org	0x0100
f1::	.db	0x11
	.area	OVL	(REL,OVR)
o1d::	.ds	2
	.area	FIX	(ABS,OVR)
	.org	0x0200
f2::	.db	0x22
	.area	OVL	(REL,OVR)
o1e::	.ds	2
	.area	FIX	(ABS,OVR)
f3::	.db	0x33
	.area	COD	(REL,CON)
start::	.db	1,2,3
