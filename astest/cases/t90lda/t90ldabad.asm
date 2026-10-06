	.module t90ldabad
	.area CODE
;
; Taking a comma is not the same as ignoring the operand.  Only IX, IY
; and SP take a displacement, and only HL takes +A - without those
; checks the register index is masked to two bits and "lda hl,bc,#4"
; encodes quietly as "lda hl,0 (ix)", which is the whole failure this
; assembler was being fixed for.
;
	lda	hl,bc,#4
	lda	hl,de,a
	lda	hl,hl,#4
	lda	hl,ix
