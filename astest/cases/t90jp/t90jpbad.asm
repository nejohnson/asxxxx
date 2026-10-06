	.module t90jpbad
	.area CODE
foo:
;
; The point of the exercise: a parenthesised symbol is not a register,
; and must not be taken for one or for an address.  This assembled
; quietly as "jp foo" before - and "jp (hl)" assembled quietly as a
; jump to an undefined global named hl.
;
	jp	(foo)
