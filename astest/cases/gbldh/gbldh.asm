	.module gbldh
	.area CODE
_loc	=	0xFF42
;
; LDH reaches 0xFF00-0xFFFF with an eight bit offset.  The hardware
; registers are written as full addresses, so both spellings of the
; same offset have to be taken - and the store form always did.
;
	ldh	a,(0xFF42)
	ldh	a,(0x42)
	ldh	a,(_loc + 0)
	ldh	(0xFF42),a
	ldh	(0x42),a
	ldh	(_loc + 0),a
	ldh	(0xFF00)
	ldh	a,(0xFFFF)
	ldh	(0xFFFF),a
