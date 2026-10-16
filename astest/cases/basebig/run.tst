# basebig -- a base address that does not fit the address space.
#
# "-a AREA = value" and "-b BANK = value" took whatever expr() handed
# back, and expr() reduces every number it scans to the address space.
# So a base beyond the space did not fail: it silently became the low
# bits of itself, the area was placed there, and the map printed the
# same masked value - so the map read correctly while the placement
# was wrong.
#
# Found on SDCC's Rabbit ports.  The Rabbit reaches extended memory
# through an MMU and SDCC writes "-a _XDATA = 0x84000"; the link is
# 16 bit, so _XDATA was placed at 0x4000 and 40005 bytes of it were
# laid over the data area at 0xA000.  The program linked, exit 0, and
# ran until the simulator gave up.
#
# What must still be accepted is the reason this is not a one line
# change.  expr() sign extends, so a legitimate base in the top half
# of memory - 0xFF80 on a 16 bit target - arrives as 0xFFFFFF80, and
# a check written against the raw value rejects it.  That is the same
# trap as the three sign extension bugs in the area size checks.  So
# the test is made where the number is scanned, against the digits
# actually read, and not against the sign extended result.
#
# One deliberate limitation: the check is on the literal, not on the
# result, so "-a CODE = 0x84000>>4" is reported even though it
# evaluates to 0x8400.  Checking the result instead cannot work - the
# truncation happens inside term(), before any caller sees it - and a
# literal beyond the address space in a link script is worth a
# complaint in its own right.
name    A base address that does not fit the address space is reported
tool    asz80
asm     -gloaxff basebig
# A base in the top half of memory still works: this is the sign
# extended case, and the whole reason the check is where it is.
link    -mxu ; -a CODE=0xFF80 ; basebig
gold    basebig.map
expect  2
link    -mxu ; -a CODE=0x84000 ; basebig
expect  2
link    -mxu ; -b FAR=0x84000 ; basebig
expect  2
link    -mxu ; -a CODE=0x10000 ; basebig
