	.module t90lda
	.area CODE
;
; lda's source, written both ways.  Toshiba's manual writes it as one
; operand; a code generator writes the displacement as a third, which
; reads like every other three operand instruction.  Each pair below
; is one instruction.
;
	lda	hl,-6 (ix)
	lda	hl,ix,#-6
	lda	hl,ix,-6
	lda	bc,4 (iy)
	lda	bc,iy,#4
	lda	de,0 (sp)
	lda	de,sp,#0
	lda	iy,127 (ix)
	lda	iy,ix,#127
	lda	hl,(hl+a)
	lda	hl,hl,a
