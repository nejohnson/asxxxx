# rabipset -- ipset is written "ipset n" or "ipsetn".
#
# The Rabbit manual writes the operand separately, "ipset 3", and that
# is what this assembler took.  SDAS carries ipset0 through ipset3 as
# four mnemonics instead, and SDCC emits those - its peephole matches
# them by instruction name in six places in src/z80/peep.c, so the
# emitted spelling is not free to change on that side.
#
# Same instruction, same two bytes, so take either.  Same call as
# "tst a,n" and as lea's third operand.
#
# Measured: three cases of SDCC's r2k suite fail to assemble without
# this - tst_critical, tst_bug-3231 and tst_bug2077267 - and nothing
# else in the port does.
name    ipset takes its operand separately or in the mnemonic
tool    asrab
asm     -gloaxff rabipset
link    -mxiu ; rabipset
goldbin rabipset.hex
expect  2
asm     -gloaxff ipsetbad
