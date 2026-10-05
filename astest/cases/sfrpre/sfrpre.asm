	.module sfrpre
	.area CODE
;
; as8051 predefines the core 8051 SFRs from i51pst.c, in both cases,
; so that hand written code can say ACC or acc without including a
; .sfr file.  as8xcxxx declared the same PreDef structure and the
; extern for the table, but never defined one and never registered
; it, so every one of these names assembled as an undefined global.
;
; Each pair is the upper and the lower case spelling of the same
; register, so the gold shows them assembling to the same bytes
; rather than merely assembling.
;
	push	ACC
	push	acc
	push	B
	push	b
	push	PSW
	push	psw
	push	SP
	push	sp
	push	DPL
	push	dpl
	push	DPH
	push	dph
	push	PCON
	push	pcon
	push	IE
	push	ie
	push	IP
	push	ip
;
; The bit addressable names, which are what SDCC's 8051 runtime
; reaches for most often.
;
	jb	ACC.7,.
	jb	acc.7,.
	jnb	B.6,.
	jnb	b.6,.
	jb	CY,.
	jb	cy,.
	jnb	OV,.
	jnb	ov,.
	jb	F0,.
	jb	f0,.
	jnb	EA,.
	jnb	ea,.
	jb	AC,.
	jb	ac,.
	jnb	P,.
	jnb	p,.
	jb	RS0,.
	jb	rs0,.
	jnb	RS1,.
	jnb	rs1,.
	jb	PS,.
	jb	ps,.
	jnb	SM0,.
	jnb	sm0,.
	jb	SM1,.
	jb	sm1,.
	jnb	SM2,.
	jnb	sm2,.
