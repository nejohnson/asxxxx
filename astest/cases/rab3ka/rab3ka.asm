	.module rab3ka
	.r3ka
	.area CODE
;
; The Rabbit 3000A's additions over the 2000 and the 3000: the block
; move group, the multiply-accumulate pair, the system/user mode
; group, and push/pop su.
;
	idet
	lddsr
	ldisr
	lsddr
	lsdr
	lsidr
	lsir
	rdmode
	setusr
	sures
	syscall
	uma
	ums
	push	su
	pop	su
;
; And it is still a Rabbit, so everything the 2000 and 3000 have is
; still here.  This is the part that the machine type being a list
; rather than a hierarchy would have broken.
;
	ioi
	ld	a,(hl)
	push	ip
	pop	ip
	bool	hl
;
; The addressing modes too, not just the opcodes: the machine type
; is tested in rabadr.c as well as rabmch.c, and SP relative loads
; are where SDCC noticed.
;
	ld	4 (sp), hl
	ld	hl, 4 (sp)
	ld	0 (sp), hl
	ldp	(hl), hl
	add	sp,#-6
	jp	lz,.
