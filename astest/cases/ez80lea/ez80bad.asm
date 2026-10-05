	.module ez80bad
	.area CODE
;
; The displacement is still required, and the base register is still
; checked - taking a comma is not the same as ignoring the operand.
;
	lea	hl,ix
	lea	hl,bc,#4
