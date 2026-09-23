# aspbig -- a large area that fits is not reported as an overrun.
#
# The aspace check compares an area's base against its size.  Both
# arrive sign extended:  an -a base at or above 0x8000, and a size at
# or above 0x8000.  The base was masked when the check was written, the
# size was not, so every area of 32K or more was reported as overrunning
# the address space no matter where it sat.  Found on an hc08 program
# whose CSEG is 0x96F3 bytes:  moved to 0x2021 it ends at 0xB713 and is
# fine, and was rejected anyway.
#
# BIG2 is 0x9000 bytes at 0x1000 and ends at 0xA000.  The link must
# succeed.  aspace covers the other side, an area that really does not
# fit.
name    A large area that fits is not an address space overrun
tool    as6808
asm     -gloaxff big2
link    -mxu ; -a BIG2=0x1000 ; big2
gold    big2.map
