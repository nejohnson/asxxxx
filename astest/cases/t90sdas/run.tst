# t90sdas -- rrd/rld with no operand, and a(hl) for (hl+a).
#
# The last two spellings between SDCC's tlcs90 port and this
# assembler, and the same shape as jp's register operand and lda's
# displacement: one instruction, one encoding, two ways of writing it.
#
#   rrd           ==  rrd (hl)        E2 11
#   ld hl,a(hl)   ==  ld hl,(hl+a)    F3 4A
#
# Measured against SDCC's suite: 1848 rrd, 1815 rld and 27 a(hl).
# None of the three appears anywhere in the 208 shared library
# sources, which is the third time in this batch that a library sweep
# has been a floor rather than a ceiling - it said tlcs90 was clean.
#
# a(hl) is picked out where A is matched as a register, not where the
# indexed forms are scanned, because by then it is too late: A is a
# register in its own right and the match has already consumed it.
name    rrd and rld take no operand, and (hl+a) is also written a(hl)
tool    astlcs90
asm     -gloaxff t90sdas
link    -mxiu ; t90sdas
goldbin t90sdas.hex
expect  2
asm     -gloaxff t90sdasbad
