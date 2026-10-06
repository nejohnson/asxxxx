# t90lda -- lda takes its displacement as one operand or as two.
#
# "lda hl,-6 (ix)" is Toshiba's spelling and is what this assembler
# took.  SDCC and SDAS write "lda hl,ix,#-6", and the HL+A form as
# "lda hl,hl,a".  Same instruction, same bytes.
#
# Same call as "tst a,n", lea's third operand, ipset and jp's register
# operand: SDCC matches its own emitted text in src/z80/peep.c, so a
# second spelling on that side has to be carried through the peephole
# layer, and here it is a dozen lines.
#
# Measured against SDCC's library: 83 error lines, every one of them
# an lda, and the only thing left on the tlcs90 port once the jp (hl)
# bug was fixed.  "lda hl,hl,a" is not among them - it appears only in
# the suite - which is the second time in this batch that the library
# sweep has been a floor rather than a ceiling.
#
# The negative case matters as much as the gold.  Only IX, IY and SP
# take a displacement and only HL takes +A; the register index is
# masked to two bits on the way out, so without those checks
# "lda hl,bc,#4" assembles quietly as "lda hl,0 (ix)".
name    lda takes its displacement as one operand or as two
tool    astlcs90
asm     -gloaxff t90lda
link    -mxiu ; t90lda
goldbin t90lda.hex
expect  2
asm     -gloaxff t90ldabad
