	.title	Absolute Area High In The Address Space

	; An absolute section at 0xCAAE.  Its size reaches the linker sign
	; extended, as 0xFFFFCAAE, and its area's a_addr stays 0 because an
	; absolute section carries its own address.  Neither describes a
	; span, and the area sits well inside a 16 bit space.

	.area	HABS	(ABS)

	.org	0xCAAE

	.byte	0x5A

	.end
