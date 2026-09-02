# end05 -- .end and bank based output routing.
#
# Three banks based at 0x0000, 0x0100 and 0x0200, two of them with a
# file suffix.  Pins that .end names the entry point, that each bank's
# base address reaches the map, and that the suffixed banks are written
# to their own files.
name    .end entry point and per bank output files
src     ascheck/end
asm     -losxff t05
link    -mxsu ; t05
gold    t05.map
