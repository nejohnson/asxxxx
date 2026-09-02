# bndry -- .even/.odd/.bndry alignment surviving relocation, and -a base
# placement.  Wide map format with linker generated symbols included.
name    Area boundary alignment and -a base address
src     ascheck/bndry
asm     -lagoxcff b_areas_1
asm     -lagoxcff b_areas_2
asm     -lagoxcff b_areas_3
link    -xmuwi1 ; -a Area_1=0x0000 ; b_areas_1 b_areas_2 b_areas_3
scan    -i b_areas_1.rst
scan    -i b_areas_2.rst
scan    -i b_areas_3.rst
gold    b_areas_1.map
