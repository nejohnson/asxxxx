# obase_i -- -i+ still names the linked output, -o+ names the rest.
#
# The two are not the same thing:  -i+/-s+/-t+ name one particular
# output file, -o+ names the base every generated file falls back to.
# An explicit -i+ therefore wins for the linked output while the map
# still follows -o+, and no file is left under either default name.
name    -i+ overrides -o+ for the linked output only
src     ascheck/areabank
asm     -gloaxff ts
link    -mxi ; -o+%w/other ; -i+%w/image.ihx ; ts
gold    other.map
goldbin image.ihx
absent  other.hex
absent  ts.map
absent  ts.hex
