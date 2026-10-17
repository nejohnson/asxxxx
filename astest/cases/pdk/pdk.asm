	.module pdk
;
; Padauk 14 bit core.  Code is word addressed and data byte addressed,
; so a label has the address its instruction wants.  The expected
; words are in the comments, after linking with CODE at word 0x11 and
; DATA at byte 2.
;
	.area CODE
start:	mov	a, #0x12		; 2F12
	mov	_x, a			; 0B83	_x is byte 3
	mov	a, _x			; 0F83
	cneqsn	a, _x			; 1783	the opcode keeps bit 7
	ceqsn	a, _x			; 1703
	goto	start			; 3011	start is word 0x11
	call	fin			; 3825	fin is word 0x25
	set1.io	0x10, #3		; 1ED0
	t0sn	_x, #7			; 21C3
	mov	a, #<(fin)		; 2F25
	mov	a, #>(fin + 0x8000)	; 2F80	the code space marker
	mov	a, #_x			; 2F03	a RAM address whole
	mov	a, #-1			; 2FFF
	mov	a, #0xFF		; 2FFF
	idxm	a, _p			; 0383	_p is byte 2, even
	ret	#0x55			; 0255
	push	af			; 0072
	sr	a			; 006A
	sr	_x			; 1503
	mov	a, abc			; 0F85	abc is a symbol, not a
fin:	ret				; 007A
	.area DATA (DSEG,BANK=_DSEG)
_p:	.ds	1
_x:	.ds	2
abc:	.ds	1
