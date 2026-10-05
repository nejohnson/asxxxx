# rabcnd -- the Rabbit's LZ and LO condition spellings.
#
# asrab/rabadr.c carried NZ/Z/NC/C/PO/NV/PE/V/P/M, with NV aliased to
# PO and V aliased to PE.  It did not carry LZ or LO, which is how the
# Rabbit manual writes those same two conditions when the flag is read
# as logical rather than as overflow - and which is what SDCC emits.
#
# With "add sp,#-n" fixed, this was the only thing left standing
# between the r2k and r3ka libraries and a clean assembly: 31 sites in
# r2k, 13 in r3ka.
#
# The gold pins all three spellings of each condition producing the
# same opcode, which is the whole claim.
name    the Rabbit names its logical conditions LZ and LO as well as NV and V
tool    asrab
asm     -gloaxff rabcnd
link    -mxiu ; rabcnd
goldbin rabcnd.hex
