	.title	.function / .endfunc

	; Each .function opens an area named for the enclosing area
	; and the function, carrying that area's attributes and its
	; bank.  .endfunc restores the enclosing area, so 'tail'
	; below belongs to TEXT and not to the last function.

	.bank	CODE	(fsfx = _C)
	.area	TEXT	(REL,CON,CSEG,BANK=CODE)

	.globl	main, helper, unused

	.function main
main:	.byte	1, 2		; 01 02
	.endfunc

	.function helper
helper:	.byte	3		; 03
	.endfunc

	.function unused
unused:	.byte	4, 5, 6		; 04 05 06
	.endfunc

	.area	TEXT
tail:	.byte	0xFF		; FF
