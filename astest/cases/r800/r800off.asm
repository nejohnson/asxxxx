	.module r800off
	.z80
	.area CODE
;
; And they are R800 instructions, not Z80 ones: without .r800 they
; are refused rather than quietly encoded.
;
	multu	a,b
	multuw	hl,bc
