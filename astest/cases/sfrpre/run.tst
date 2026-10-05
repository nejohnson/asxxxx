# sfrpre -- as8xcxxx predefines the core 8051 SFRs, in both cases.
#
# as8051 carries a preDef[] table in i51pst.c and registers it from
# minit(), which gives every source ACC, B, PSW, the bit addressable
# names and so on without including a .sfr file, spelled either case.
# as8xcxxx declares the same struct and the same extern in ds8.h but
# defines no table and never registers one, so the names it shares
# with as8051 all assembled as undefined globals.  SDCC's ds390
# runtime is written against them: "push acc" and "jnb b.6,..." come
# straight out of tinibios.c, and the whole suite linked with twenty
# five thousand undefined global warnings.
#
# The table here is the subset of as8051's that every DS8xCxxx part
# has, with the structure's ptype field left zero to mean "common to
# all of them" - the per processor registers the structure was shaped
# for can be added against their own ptype later.
#
# The first gold pins the pairs assembling identically, which is the
# part that matters: it is the lower case spellings that SDCC emits.
# The second pins a source's own definition still winning, which is
# what makes the table safe to add to a released assembler.
name    as8xcxxx predefines the core 8051 SFRs in both cases
tool    as8xcxxx
asm     -gloaxff sfrpre
link    -mxiu ; sfrpre
goldbin sfrpre.hex
asm     -gloaxff sfrown
link    -mxiu ; sfrown
goldbin sfrown.hex
