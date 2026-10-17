	.module elfout
	.area CODE
	.globl start
start:	ld	a,#1
	jp	start
	.area DATA
var:	.ds	2
;
; Debugging information:  not part of the program's image.
; Expected bytes are in the comments.
;
	.area .debug_x (NOLOAD)
	.uleb128	0, 127, 128, 300	; 00  7F  80 01  AC 02
	.uleb128	-2			; FE FF FF FF 0F
	.sleb128	0, -1, 63, 64		; 00  7F  3F  C0 00
	.sleb128	-64, -65, -8192		; 40  BF 7F  80 40
	.dw	start, var
