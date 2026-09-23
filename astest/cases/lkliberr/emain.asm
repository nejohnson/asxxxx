	.title	Direct Page Reference To A Library Symbol

	; edef_hi is resolved out of elib.lib, so its module has no lfile.

	.globl	edef_hi

	.area	MAIN	(REL,CON)

	lda	*edef_hi

	.end
