;  pic14ebd.asm -- operands the enhanced 14-bit core rejects.
;
;  gpasm takes movlb 32 quietly, giving movlb 0 and selecting
;  the wrong bank;  this does not.
;
	.module	pic14ebd
	.pic14ebit
	.area	CODE	(ABS,CSEG)
	.org	0
	movlb	#32
	movlp	#128
	addfsr	fsr0, #32
	addfsr	fsr0, #-33
	addfsr	#2, #0
	moviw	#32[fsr0]
	moviw	#-33[fsr1]
	movwi	#0 fsr0]
	tris	#4
	.org	0x400
far:
	.org	0x200
	bra	far
	.end
