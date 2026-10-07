# ovr -- an overlay area is re-entered at its start, not continued.
#
# newdot() treated every area the same:  leaving one recorded its size
# and entering one resumed at that size.  For a CON area that is right.
# For an OVR area it is not - the whole point of an overlay is that
# blocks of the same area start at the same place - and nothing else in
# the assembler made up for it.
#
# It matters because SDCC's 8051 back end gives each function its own
# block of the overlay area, one .area OVL per function, and relies on
# them all starting at zero.  Continued instead of overlaid, a module's
# overlay came out as the sum of every function's block rather than the
# largest:  one regression program went to 352 bytes of a 128 byte
# internal RAM where 16 were called for, and the excess was laid over
# the 8051's special function registers without a word said.
#
# Three blocks of 8, 12 and 4 in one module and two of 6 and 3 in
# another:  every one starts at the area's base and the area is 12
# bytes, the largest.  The concatenating area beside it still appends,
# 2 + 1 + 4 = 7, which is what says the change reached only overlays.
name    An overlay area is re-entered at its start and sized by its largest block
src     astest/cases/ovr
asm     -gloaxff o1
asm     -gloaxff o2
link    -mxu ; o1 ; o2
gold    o1.map
