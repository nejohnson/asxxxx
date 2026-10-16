# obase -- -o+ names every file the linker creates.
#
# Without -o+ the map, the NoICE file and the linked output are all
# named after the first object file.  That is the wrong name whenever
# the first object is not the program - a C runtime's crt0 out of a
# library directory, say - and it is unwritable whenever that
# directory is.
#
# Here the first (and only) object is ts, so every output would be
# ts.*;  -o+other must move all three and leave no ts.* behind.
name    -o+ names the map, the NoICE file and the linked output
src     ascheck/areabank
asm     -gloaxff ts
link    -mjxi ; -o+%w/other ; ts
gold    other.map
gold    other.noi
goldbin other.hex
absent  ts.map
absent  ts.noi
absent  ts.hex
