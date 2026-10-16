	.title	24 and 32 Bit Addressing

	; The linker's map columns and asxscn's listing columns are
	; both selected by the address width, and the two are chosen
	; independently:  the assembler is told by .24bit / .32bit,
	; the linker by the .rel file header, and asxscn by -3 / -4.
	; A mismatch makes asxscn report an invalid file format, so
	; this pins all three together.
	;
	; ascheck emits the high byte first, so the expected bytes
	; below read in that order.

	.24bit
	.area	A24	(REL,CON)

	.globl	w24
w24:	.word	0x1234		; 12 34
	.3byte	0x123456	; 12 34 56
	.byte	0x7F		; 7F

	.end
