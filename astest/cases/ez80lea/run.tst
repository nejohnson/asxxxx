# ez80lea -- lea takes its displacement as a second or a third operand.
#
# "lea hl,ix-6" is how Zilog's eZ80 manual writes it and is what this
# assembler took.  SDCC, like SDAS, emits "lea hl,ix,#-6", which reads
# like every other three operand instruction.  Same instruction, same
# bytes, and the code already parsed a displacement expression after
# the base register - it just could not step over the comma.
#
# Taking it here rather than changing the code generator is the same
# call as "tst a,n": the emitted text is matched by SDCC's own
# peephole rules, in src/z80/peeph-ez80.def and src/z80/peep.c, so a
# second spelling on that side has to be carried through the whole
# peephole layer forever.  On this side it is six lines.
#
# Measured against SDCC's library: 260 error lines across 98 of the
# 208 shared objects, every one of them a lea.
name    lea takes its displacement as a second or a third operand
tool    asez80
asm     -gloaxff ez80lea
link    -mxiu ; ez80lea
goldbin ez80lea.hex
expect  2
asm     -gloaxff ez80bad
