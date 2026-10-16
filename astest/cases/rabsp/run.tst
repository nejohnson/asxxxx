# rabsp -- the Rabbit's "add sp,n" takes a signed displacement.
#
# asrab/rabmch.c emitted the operand with outrb(&e2, R_USGN), so
# "add sp,#-6" - a compiler allocating a six byte stack frame - was
# reported as <v> Unsigned Number Exceeded Range.  The encoding was
# right either way: the listing already showed 27 FA, the check just
# refused to let it out.  sdas passes 0 here and says so in a comment,
# "n=signed displacement".
#
# Measured against SDCC's library: 190 sites in each of the six Rabbit
# ports, every one of them a stack frame.
#
# The gold pins each negative value assembling to the same byte as the
# unsigned spelling of the same byte, which is the whole argument for
# not checking the range.
name    the Rabbit's add sp,n takes a signed displacement
tool    asrab
asm     -gloaxff rabsp
link    -mxiu ; rabsp
goldbin rabsp.hex
