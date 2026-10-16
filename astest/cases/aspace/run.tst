# aspace -- an area that runs off the end of the address space is
# reported.
#
# lnksect() laid an area out and never asked whether it still fitted.
# Past the top the addresses simply wrapped:  the far end of the area
# reappeared at the bottom of memory, on top of whatever was already
# there, and the output was written with no error and no warning.  A
# 38 KB CSEG based at 0x8021 came back at 0x1718 over the data area,
# which is a difficult thing to find from the far end.
#
# BIG is 256 bytes based at 0xFF80, so it ends at 0x1007F and does not
# fit.  aslink must say so and exit 2.
name    An area that overruns the address space is reported
tool    as6808
asm     -gloaxff big
expect  2
link    -mxu ; -a BIG=0xFF80 ; big
