# r800 -- the R800's multu and multuw, and .r800 to select them.
#
# asz80 covers the Z80, the HD64180/Z180, the 8080, the 8085 and the
# ZX Spectrum Next.  It did not cover the ASCII R800 - the Z80
# superset in the MSX turbo R - which adds two multiply instructions
# and implements the undocumented IX/IY half registers.
#
# .r800 selects it, and allows the half registers the same way .zxn
# already does.  The encodings match SDAS byte for byte: ED C1|r<<3
# for multu, ED C3|rr<<4 for multuw.
#
# SDCC's r800 port is the last of the z80 family still on sdasz80, and
# these were the only instructions standing in its way: measured
# against the shared library, 35 error lines across 12 of 208 objects,
# all multu, multuw, or a half register load.
name    the R800's multu and multuw, selected by .r800
tool    asz80
asm     -gloaxff r800
link    -mxiu ; r800
goldbin r800.hex
expect  2
asm     -gloaxff r800bad
expect  2
asm     -gloaxff r800off
