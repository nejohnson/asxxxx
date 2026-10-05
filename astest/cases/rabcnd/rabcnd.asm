	.module rabcnd
	.r2k
	.area CODE
;
; The Rabbit replaced the Z80's parity flag with a combined logical
; / overflow flag, and its literature names the two conditions twice:
; LZ and LO when the flag is read as logical, NV and V when it is read
; as overflow.  They are the same two encodings, E2 and EA.
;
; Only one pair was here.  PO/NV and PE/V were already aliased to each
; other, so the logical spellings are the same aliasing again - and
; they are the spellings a compiler emits.
;
l$:
	jp	lz,l$
	jp	nv,l$
	jp	po,l$
	jp	lo,l$
	jp	v,l$
	jp	pe,l$
