# fitsplt -- a FIT area too big for a gap is split by section.
#
# An area offered a gap by FIT that it does not fit whole is laid
# down a section at a time:  each module's section takes the lowest
# gap that holds it, and the sections no gap holds follow on from
# where the area would have started.  The area's address and size
# are the span of its sections.
#
# REG 0x00-0x07 and BIT at its own 0x20 leave 0x08-0x1F.  DAT's
# sections are 20, 10 and 3 bytes:  s1's at 0x08, s2's at 0x21 after
# BIT, s3's at 0x1C in what s1 left of the gap.  DAT spans 0x08-0x2A,
# 35 bytes counting the free byte at 0x1F and BIT's at 0x20,
# and STK follows at 0x2B;  laid down whole after BIT, DAT would have
# pushed it to 0x42.
name    A FIT area too big for a gap is split by section
src     astest/cases/fitsplt
asm     -gloaxff s1
asm     -gloaxff s2
asm     -gloaxff s3
link    -mxu ; -a BIT = 0x0020 ; s1 ; s2 ; s3
gold    s1.map
