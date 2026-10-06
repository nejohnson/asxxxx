# gbldh -- ldh takes a full I/O address, in both directions.
#
# "ldh a,(nn)" tested the wrong variable:
#
#     if ((t1 == S_R8) && (v1 == A) && (t2 == S_INDM)) {
#         if (((v2 & 0xFF00) == 0x0000) ||
#             ((v1 & 0xFF00) == 0xFF00)) {     <- v1 is the A register
#
# v1 is the first operand, which in that branch is A, so the second
# test could never be true and a full address - 0xFF42 rather than
# 0x42 - always fell through to "I/O Address Not In Range 0x00-0xFF".
# The store form below it has the same two tests against v1, where v1
# really is the address, and has always worked; that asymmetry is
# what makes this a typo rather than a rule.
#
# The hardware registers are written as full addresses, so SDCC and
# SDAS both emit them that way.  Four cases of SDCC's sm83 suite fail
# to assemble without this.
#
# The gold pins each offset assembling the same from either spelling,
# and the negative case pins that an address in neither page is still
# refused - in both directions, which is what was really being tested
# all along.
name    ldh takes a full I/O address as well as an offset
tool    asgb
asm     -gloaxff gbldh
link    -mxiu ; gbldh
goldbin gbldh.hex
expect  2
asm     -gloaxff gbldhbad
