# st8rwa -- rrwa and rlwa with the A left implicit.
#
# The A operand names the only register these rotate through, so SDAS
# and SDCC's stm8 port write it without one; this assembler wanted it.
# One instruction, one encoding, two ways of writing it:
#
#   rrwa x   ==  rrwa x,a    01
#   rlwa y   ==  rlwa y,a    90 02
#
# Measured against SDCC's stm8 library: 118 sites, in 50 of 389
# sources.
name    rrwa and rlwa take their A operand implicitly
tool    asst8
asm     -gloaxff st8rwa
link    -mxiu ; st8rwa
goldbin st8rwa.hex
expect  2
asm     -gloaxff st8rwab
