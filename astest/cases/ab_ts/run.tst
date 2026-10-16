# ab_ts -- single module, all four ABS/REL x OVR/CON area combinations.
#
# Pins the placement rules documented in the ASCII memory map at the head
# of ascheck/areabank/ts.asm, and the a_/l_ linker generated area symbols.
# Those symbols carry no areax back link, which is why a section collector
# cannot see through them;  this is the reference point for that work.
name    Single module AREA placement and the a_/l_ area symbols
src     ascheck/areabank
asm     -gloaxff ts
link    -mxu ts
scan    -i ts.rst
gold    ts.map
