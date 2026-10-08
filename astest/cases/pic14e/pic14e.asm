;  pic14e.asm -- the enhanced 14-bit core of the PIC12F1xxx and
;  PIC16F1xxx.
;
;  Every instruction below was assembled by gpasm 1.4.0 for a
;  16f1788 as well and the two agree on all 140 encodings, byte
;  for byte.  The operand forms are enumerated rather than
;  sampled:  both destinations of every f,d instruction, both
;  ends of every literal field, all eight MOVIW / MOVWI
;  increment forms and both ends of their index, and the five
;  BRA offsets that bound its range.
;
	.module	pic14e
	.pic	"p16f1788"
	.pic14ebit

	.area	DATA	(DSEG)
dreg::	.ds	1

	.area	CODE	(CSEG)

;  bra is the one branch this core takes relative, nine bits of
;  it, reaching -256 to +255 words from the word that follows.
;
lbase:
	bra	lbase+0x100	; +255
	bra	lbase+2		;   0
	bra	lbase+4		;  +1
	bra	lbase+3		;  -1
	bra	lbase-251	; -256

	addwf	0x20, w
	addwf	0x7f, f
	addwfc	0x20, w
	addwfc	0x7f, f
	andwf	0x20, w
	andwf	0x7f, f
	asrf	0x20, w
	asrf	0x7f, f
	lslf	0x20, w
	lslf	0x7f, f
	lsrf	0x20, w
	lsrf	0x7f, f
	comf	0x20, w
	comf	0x7f, f
	decf	0x20, w
	decf	0x7f, f
	incf	0x20, w
	incf	0x7f, f
	iorwf	0x20, w
	iorwf	0x7f, f
	movf	0x20, w
	movf	0x7f, f
	rlf	0x20, w
	rlf	0x7f, f
	rrf	0x20, w
	rrf	0x7f, f
	subwf	0x20, w
	subwf	0x7f, f
	subwfb	0x20, w
	subwfb	0x7f, f
	swapf	0x20, w
	swapf	0x7f, f
	xorwf	0x20, w
	xorwf	0x7f, f
	decfsz	0x20, w
	decfsz	0x7f, f
	incfsz	0x20, w
	incfsz	0x7f, f
	clrf	0x20
	clrf	0x7f
	movwf	0x20
	movwf	0x7f
	clrw
	brw
	callw
	nop
	option
	reset
	retfie
	return
	sleep
	clrwdt
	tris	#5
	tris	#6
	tris	#7
	bcf	0x20, #0
	bcf	0x20, #7
	bsf	0x20, #0
	bsf	0x20, #7
	btfsc	0x20, #0
	btfsc	0x20, #7
	btfss	0x20, #0
	btfss	0x20, #7
	addlw	#0x00
	addlw	#0xff
	andlw	#0x00
	andlw	#0xff
	iorlw	#0x00
	iorlw	#0xff
	movlw	#0x00
	movlw	#0xff
	sublw	#0x00
	sublw	#0xff
	xorlw	#0x00
	xorlw	#0xff
	retlw	#0x00
	retlw	#0xff
	movlb	#0
	movlb	#1
	movlb	#31
	movlp	#0
	movlp	#18
	movlp	#127
	call	0x000
	goto	0x000
	call	0x123
	goto	0x123
	call	0x7ff
	goto	0x7ff
	addfsr	fsr0, #-32
	addfsr	fsr0, #-1
	addfsr	fsr0, #0
	addfsr	fsr0, #1
	addfsr	fsr0, #31
	addfsr	fsr1, #-32
	addfsr	fsr1, #-1
	addfsr	fsr1, #0
	addfsr	fsr1, #1
	addfsr	fsr1, #31
	moviw	++fsr0
	moviw	--fsr0
	moviw	fsr0++
	moviw	fsr0--
	moviw	++fsr1
	moviw	--fsr1
	moviw	fsr1++
	moviw	fsr1--
	movwi	++fsr0
	movwi	--fsr0
	movwi	fsr0++
	movwi	fsr0--
	movwi	++fsr1
	movwi	--fsr1
	movwi	fsr1++
	movwi	fsr1--
	moviw	#-32[fsr0]
	moviw	#-1[fsr0]
	moviw	#0[fsr0]
	moviw	#1[fsr0]
	moviw	#31[fsr0]
	moviw	#-32[fsr1]
	moviw	#-1[fsr1]
	moviw	#0[fsr1]
	moviw	#1[fsr1]
	moviw	#31[fsr1]
	movwi	#-32[fsr0]
	movwi	#-1[fsr0]
	movwi	#0[fsr0]
	movwi	#1[fsr0]
	movwi	#31[fsr0]
	movwi	#-32[fsr1]
	movwi	#-1[fsr1]
	movwi	#0[fsr1]
	movwi	#1[fsr1]
	movwi	#31[fsr1]

;  The same instructions with an operand the linker has to
;  resolve:  a page relative file address through .setdmm, a
;  call and a goto, a bra whose target is outside this area,
;  and the literal fields of movlb, movlp, addfsr and movwi.
;
	.setdmm	0, DATA
	movwf	dreg
	addwf	dreg, w
	bcf	dreg, #3

	.globl	extadr, extbra, extbnk, extpag, extndx
	call	extadr
	goto	extadr
	movlb	#extbnk
	movlp	#extpag
	addfsr	fsr1, #extndx
	movwi	#extndx[fsr0]
brahere::
	bra	extbra

	.end
