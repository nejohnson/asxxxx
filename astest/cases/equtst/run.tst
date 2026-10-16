# equtst -- upstream's own test of assembler equates.
#
# The source provokes 17 errors deliberately, each annotated in the
# source with the code it should produce, so both tools are expected to
# exit 2.  Line 294 is '. = 4', which segmentation faulted every
# assembler until the equate() fix;  this case is what keeps that fixed.
#
# The listing is golded rather than the map:  the map would contain the
# two deliberate undefined-symbol warnings, and symdef() walks the
# symbol hash table in bucket order, so their order depends on NCPS,
# NHASH and the hash function.  The listing is in source order and is
# stable.
name    Assembler equates, and the 17 errors equtst.asm provokes
src     ascheck/equtst
expect  2
asm     -loxff equtst
gold    equtst.lst
expect  2
link    -mx ; equtst
