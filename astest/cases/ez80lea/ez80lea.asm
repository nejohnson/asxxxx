	.module ez80lea
	.area CODE
;
; Zilog writes lea's displacement into the second operand; a code
; generator writes it as a third, which reads like every other three
; operand instruction.  Same instruction, same bytes.
;
; Each pair below is one instruction written both ways.
;
	lea	hl,ix,#-6
	lea	hl,ix-6
	lea	iy,iy,#+2
	lea	iy,iy+2
	lea	bc,iy,#0
	lea	bc,iy+0
	lea	de,ix,#127
	lea	de,ix+127
	lea	ix,iy,#-128
	lea	ix,iy-128
	lea	hl,ix,-6
	lea	hl,ix-6
