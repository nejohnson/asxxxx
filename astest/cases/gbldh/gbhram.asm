	.module gbhram
;
; Two symbols another module reaches through ldh: one written as a
; full I/O address, one as an offset.  Both are the same byte to the
; instruction, which is the point.
;
	.area	HRAM (ABS)
	.org	0xFF42
_hi::	.ds	1
	.area	LOWPG (ABS)
	.org	0x0042
_lo::	.ds	1
