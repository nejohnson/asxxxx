	;
	; Both of these name a file beside this one, in sub/, not one
	; beside main.asm.
	;
	.area	XCODE	(ABS)
	.org	0x10
	.byte	2
	.include "y.asm"
	.incbin	"dat.bin"
	.byte	8
