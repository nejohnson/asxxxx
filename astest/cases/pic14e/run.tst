# pic14e -- the enhanced 14-bit core of the PIC12F1xxx and PIC16F1xxx.
#
# aspic chose between five cores with .pic12bit, .pic14bit, .pic16bit,
# .pic20bit and .picnopic, and the enhanced midrange was not one of
# them:  moviw, movwi, lslf, lsrf, asrf, movlp, brw and reset were
# absent outright, and addfsr, callw, bra, addwfc, subwfb and movlb
# were in the PIC18 column only.  Half of SDCC's pic14 devices - 94 of
# 189 - are this core.
#
# The core is a sixth column of picDef[] and a sixth processor type,
# .pic14ebit, because what differs from the baseline midrange differs
# per mnemonic rather than by a rule:  clrw is 0x0103 against 0x0100,
# movlb 0x0020 against the PIC17's 0xB800 and the PIC18's 0x0100,
# addwfc 0x3D00 against 0x1000 and 0x2000.  That is table data, which
# is what a column is.
#
# pic14e.asm holds 140 encodings.  gpasm 1.4.0 was given the same 140
# instructions for a 16f1788 and the two agree on every one, byte for
# byte.  The forms are enumerated rather than sampled:  both
# destinations of every f,d instruction, both ends of every literal
# field, all eight moviw / movwi increment forms, both ends of their
# signed index, and the five bra offsets that bound its range.  The
# tail then puts a relocatable operand into the same instructions, so
# that aslink resolves a .setdmm page, a call and a goto, the literal
# of movlb, movlp, addfsr and movwi, and a bra outside the area, which
# is the first use this family of assemblers makes of R_PCR with a
# 9-bit mode.
#
# pic14ebd pins the operands that are rejected.  gpasm takes movlb 32
# quietly, giving movlb 0 and the wrong bank;  this does not.
#
# pic14eol pins that .pic14bit still rejects all of it.
name    the enhanced 14-bit core
tool    aspic
asm     -gloaxff pic14e
link    -mxiu ; -g extadr=0x123 ; -g extbnk=5 ; -g extpag=0x12 ; -g extndx=-4 ; -g extbra=brahere+4 ; pic14e
goldbin pic14e.hex
expect  2
asm     -gloaxff pic14ebd
expect  2
asm     -gloaxff pic14eol
