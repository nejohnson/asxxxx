# rab4k -- the Rabbit 4000 and 6000.
#
# asrab assembled the Rabbit 2000, 3000 and - as of this fork - the
# 3000A, selecting between them with a single machine type.  The 4000
# needs two: a processor and a mode, because the two mode bits select
# between register mappings and several encodings differ by them.
# Mode 10 puts a 0x7F escape in front of a bare HL form.  SDCC emits
# .r4k10 for its r4k and r5k ports and .r6k10 for r6k, so that is what
# is assembled here.
#
# The 32 bit pairs reuse the Z80's index prefixes - BCDE is 0xDD and
# JKHL is 0xFD in front of the opcode that does the same thing to HL -
# which is most of why this is 30 instruction forms rather than a
# CPU's worth.
#
# Every encoding here was taken from SDAS and diffed against it byte
# for byte; the two assemblers agree on all 50 of them.  They disagree
# on one thing deliberately, which rab4kbad pins: SDAS takes the low
# byte of an out of range immediate quietly, and this does not.
#
# Measured against SDCC's library: 676 error lines across 205 of 208
# objects before, none after, for each of r4k, r5k and r6k.
name    the Rabbit 4000 and 6000
tool    asrab
asm     -gloaxff rab4k
link    -mxiu ; rab4k
goldbin rab4k.hex
asm     -gloaxff rab6k
link    -mxiu ; rab6k
goldbin rab6k.hex
expect  2
asm     -gloaxff rab4kbad
expect  2
asm     -gloaxff rab4kold
