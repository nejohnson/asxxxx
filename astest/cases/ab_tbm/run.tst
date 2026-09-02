# ab_tbm -- banked, multi module.
name    Banked multi module AREA placement
src     ascheck/areabank
asm     -gloaxff tbm
asm     -gloaxff tbm1
asm     -gloaxff tbm2
link    -mxu ; tbm tbm1 tbm2
scan    -i tbm1.rst
scan    -i tbm2.rst
gold    tbm.map
