	.module	main
	;
	; run.tst puts .include of sub/x.asm before this file with -i:
	; an .include that names a path takes it from the directory the
	; assembler runs in, so -i and astest's %s are what can name sub/
	; portably.
	;
	.area	CODE	(ABS)
	.org	0
	.byte	1
