	.module z180
	.hd64
;
; The HD64180/Z180 traps on an illegal instruction rather than quietly
; doing what the Z80 did, so there is nothing here to enable and asking
; for it is worth reporting rather than ignoring.
;
	.allow_undocumented
	.area CODE
