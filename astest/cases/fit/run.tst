# fit -- an area may take a gap an addressed area left behind it.
#
# aslink laid every relocatable area down one after another, so an
# area given an address of its own - the 8051's bit bank at 0x20, say -
# left the space below it unusable, and everything after the gap was
# pushed up by its whole width.  On the 8051 that is 24 bytes of 128,
# and the stack is last in the chain, so it is the stack that pays.
#
# FIT offers an area the lowest gap it fits in, and leaves the running
# address alone when it takes one, so the areas after it move down by
# what it would have occupied.  It is a hint and nothing more:  BIG
# asks for the same gap, is too wide for it, and is laid down exactly
# where it would have been.
#
# REG 0x00-0x07, then DAT at 0x08 and IDT at 0x09-0x14 in the gap,
# BIT at its own 0x20, STK at 0x21 rather than 0x2E, BIG after it and
# END after that.
name    An area may be fitted into a gap an addressed area left behind
src     astest/cases/fit
asm     -gloaxff f1
link    -mxu ; -a BIT = 0x0020 ; f1
gold    f1.map
