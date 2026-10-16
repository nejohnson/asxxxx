	.module st8rwa
	.area CODE
;
; Each pair is one instruction.
;
	rrwa	x		; 01
	rrwa	x,a		; 01
	rlwa	x		; 02
	rlwa	x,a		; 02
	rrwa	y		; 90 01
	rrwa	y,a		; 90 01
	rlwa	y		; 90 02
	rlwa	y,a		; 90 02
