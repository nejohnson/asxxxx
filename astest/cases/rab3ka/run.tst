# rab3ka -- the Rabbit 3000A.
#
# asrab assembled the Rabbit 2000 and 3000, the Z80 and the Z180, and
# selected between them with a single machine type compared for
# equality - "mchtyp == X_R2K" meaning "is a Rabbit".  That left no
# room for a second Rabbit, so the 3000A's instructions were missing
# and .r3ka was not a directive.
#
# The equality tests become IS_RABBIT(), which is any Rabbit, and the
# 3000A's own instructions use IS_MIN_R3KA().  30 tests converted.
#
# SDCC emits lsidr in place of ldir on its r3ka, r4k, r5k and r6k
# ports - a Rabbit 2000 ldir has a wait state bug across memory types
# - so this is what stands between the r3ka port and the vendor
# toolchain.  Worth noting how it was found: sweeping the 208 shared
# library sources said r3ka was clean, because none of them copies a
# block.  An assembler sweep is a floor, not a ceiling.
#
# The gold pins the encodings, which match SDAS byte for byte.  The
# two negative cases pin the gating in both directions: a 2000 does
# not have the 3000A instructions, and a Z80 has neither those nor
# the Rabbit 2000/3000 ones.
name    the Rabbit 3000A, and .r3ka to select it
tool    asrab
asm     -gloaxff rab3ka
link    -mxiu ; rab3ka
goldbin rab3ka.hex
expect  2
asm     -gloaxff rab2k
expect  2
asm     -gloaxff rabz80
