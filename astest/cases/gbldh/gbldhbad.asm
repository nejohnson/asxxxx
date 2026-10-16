	.module gbldhbad
	.area CODE
;
; An address that is neither page zero nor page 0xFF is still out of
; range, in both directions.
;
	ldh	a,(0x1234)
	ldh	(0x1234),a
