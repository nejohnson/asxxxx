	.module rab6k
	.r6k10
	.area CODE
;
; The Rabbit 6000 adds the ALU against a stack slot.  The second byte
; is the operation's own bit 3 field moved into the high nibble: add
; 8A, adc 9A, sub AA, sbc BA, and CA, or EA, cp FA.  xor has no such
; form.  And the index registers take an immediate.
;
	add	hl, 4 (sp)
	adc	hl, 4 (sp)
	sub	hl, 4 (sp)
	sbc	hl, 4 (sp)
	and	hl, 4 (sp)
	or	hl, 4 (sp)
	cp	hl, 4 (sp)
	add	ix, #0x12
	add	iy, #0x12
