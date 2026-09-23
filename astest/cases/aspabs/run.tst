# aspabs -- an absolute area high in the address space is not mistaken
# for one that overruns it.
#
# The check added for the aspace case compared an area's base against
# its accumulated size.  That says nothing about an absolute area: its
# sections each carry their own address, so a_addr stays 0 while the
# size is whatever the highest section reached, and for anything at or
# above 0x8000 that size arrives sign extended.  hc08's XABS came
# through as a_addr 0 with size 0xFFFFCAAE and was reported as
# overrunning a space it sits well inside, which broke four working
# regression cases.
#
# The link must succeed.
name    An absolute area high in memory is not an address space overrun
tool    as6808
asm     -gloaxff habs
link    -mxu ; habs
gold    habs.map
