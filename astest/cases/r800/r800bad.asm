	.module r800bad
	.r800
	.area CODE
;
; The operand restrictions are real: multu is a,r for b/c/d/e only
; and multuw is hl,bc or hl,sp only.
;
	multu	a,h
	multu	b,c
	multuw	hl,de
	multuw	de,bc
