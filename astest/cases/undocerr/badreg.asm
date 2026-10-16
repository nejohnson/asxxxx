	.module badreg
	.allow_undocumented
	.area CODE
;
; h and l name the index register's own halves behind the prefix, so
; these cannot be encoded: the instruction that would come out is a
; different move from the one written.
;
	ld	h, ixh
	ld	l, iyl
	ld	ixh, h
	ld	iyl, l
;
; One prefix, so both halves have to belong to the same index register.
;
	ld	ixh, iyl
	ld	iyh, ixl
