# sll -- the one undocumented Z80 instruction asz80 already carries.
#
# z80pst.c gives sll the opcode type S_RL_UNDOCD, but z80mch.c had no
# case for it, so the mnemonic parsed, reached the end of the switch and
# came back as "Internal Opcode Error" - a diagnostic that blames the
# assembler for a line it had every intention of assembling.  It shares
# the shift and rotate code, which is why it needs no body of its own,
# only the label.
#
# All eight register forms plus the two indexed ones, so the CB prefix,
# the DD/FD prefix and the displacement byte are all covered.
name    sll assembles instead of reporting an Internal Opcode Error
tool    asz80
asm     -gloaxff sll
link    -mxiu ; sll
goldbin sll.hex
