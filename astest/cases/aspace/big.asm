	.title	Area Overrunning The Address Space

	; 256 bytes based at 0xFF80 run off the end of a 16 bit address
	; space.  Assembled with a target whose addresses are two bytes:
	; ascheck's are four, where nothing of a testable size overflows.

	.area	BIG	(REL,CON)

	.ds	0x100

	.end
