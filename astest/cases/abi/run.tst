# abi -- modules that agree, and one that makes no claim.
#
# .abi carries an opaque string the linker compares between modules.
# 'one' and 'two' give the same string and must link without comment -
# including the leading and trailing white space on one of them, which
# the assembler trims before writing the record.
#
# 'three' declares no .abi at all.  A module that makes no claim is not
# compared against, so a library built before anyone thought about this
# still links.
name    Modules whose .abi strings agree, and one that makes none
asm     -gloaxff one
asm     -gloaxff two
asm     -gloaxff three
link    -mxu ; one ; two ; three
gold    one.map
