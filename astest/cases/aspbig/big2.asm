	.title	A Large Area That Does Fit

	; 0x9000 bytes based at 0x1000 end at 0xA000, well inside a 16 bit
	; space.  The size has bit 15 set, so it reaches the linker sign
	; extended as 0xFFFF9000:  unmasked, that reports the area as an
	; overrun however much room it has.

	.area	BIG2	(REL,CON)

	.ds	0x9000

	.end
