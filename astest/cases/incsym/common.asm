	;
	; An expression the linker evaluates is carried by a symbol the
	; assembler makes up, named after the module's source file.
	;
	.globl	two
	.word	(two * 3)
