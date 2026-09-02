# ab_tm -- two modules contributing to the same areas.
#
# Proves OVR areas overlay and CON areas concatenate across modules, and
# that concatenation follows the order the modules are given.  Note the
# link list starts with tm1:  ascheck/areabank/tm.bat names a 'tm' that
# has no source, so the linker there fails to open tm.rel.
name    Two module AREA overlay and concatenation
src     ascheck/areabank
asm     -gloaxff tm1
asm     -gloaxff tm2
link    -mxu ; tm1 tm2
scan    -i tm1.rst
scan    -i tm2.rst
gold    tm1.map
