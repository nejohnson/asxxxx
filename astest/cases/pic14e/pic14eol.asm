;  pic14eol.asm -- none of it is available on the baseline
;  14-bit core, and the instructions it shares with the PIC17
;  and PIC18 are not available there either.
;
	.module	pic14eol
	.pic14bit
	.area	CODE	(ABS,CSEG)
	.org	0
	asrf	0x20, w
	lslf	0x20, w
	lsrf	0x20, w
	brw
	reset
	movlp	#0x12
	moviw	fsr0++
	movwi	++fsr1
	addwfc	0x20, w
	subwfb	0x20, w
	movlb	#0
	addfsr	fsr0, #4
	callw
	bra	.
	.end
