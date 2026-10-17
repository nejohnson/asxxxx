# pdk -- the Padauk assemblers, aspdk13/14/15.
#
# Moved from SDCC's SDAS onto this assembler's bit-mode relocation:
# code is word addressed, data byte addressed, and each operand field
# is a relocation mode whose width is its range check.  This case is
# the 14 bit core; the three share the emitters and the modes.
#
# What it pins:  the field is the mask less the opcode's own bits
# (cneqsn a,m is 0x1780 with a 7 bit field, not 8, or the merge would
# turn it into ceqsn); a relocatable immediate is range checked unless
# it chose its byte with < or >; a register name is a whole word.
name    Padauk 14 bit core:  word code, byte data, operand fields
tool    aspdk14
asm     -gloaxff pdk
link    -mxi ; -a CODE = 0x0011 ; -a DATA = 0x0002 ; pdk
goldbin pdk.hex
expect  2
asm     -gloaxff pdkbad
asm     -gloaxff pdkrng
expect  2
link    -mxi ; -a DATA = 0x0002 ; pdkrng
