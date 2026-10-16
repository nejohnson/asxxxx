	.module r800
	.r800
	.area CODE
;
; The R800's two multiply instructions.  multu takes b, c, d or e;
; multuw takes bc or sp.  Nothing else encodes.
;
	multu	a,b
	multu	a,c
	multu	a,d
	multu	a,e
	multuw	hl,bc
	multuw	hl,sp
;
; .r800 also allows the IX/IY half registers, the way .zxn does -
; the R800 is a Z80 superset and implements them.
;
	ld	iyl,a
	ld	iyh,d
	ld	a,ixl
	inc	ixh
