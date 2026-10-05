	.module rabsp
	.r2k
	.area CODE
;
; The Rabbit's "add sp,n" adds an eight bit displacement to SP.  It is
; signed in use: negative allocates a stack frame, positive frees one,
; and a compiler emits far more of the first than the second.  The
; operand was range checked as unsigned, so every frame allocation was
; refused - with the correct bytes already in the listing, because the
; check does not change the encoding.
;
; Both signs name the same byte and both are meant, so there is no
; range to check.  The pairs below are the same byte written two ways.
;
	add	sp,#-1
	add	sp,#255
	add	sp,#-6
	add	sp,#250
	add	sp,#-128
	add	sp,#128
	add	sp,#0
	add	sp,#127
