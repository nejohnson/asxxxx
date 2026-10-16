	.module st8rwab
	.area CODE
;
; The register is X or Y, and a second operand has to be A.
;
	rrwa	a
	rrwa	sp
	rrwa	x,b
	rlwa	x,y
	rlwa	x,
