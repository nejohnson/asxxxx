# undoc -- .allow_undocumented and the IX/IY half register instructions.
#
# z80adr.c already classified ixh/ixl/iyh/iyl as S_R8U1 and S_R8U2, and
# z80.h already reserved X_UNDOCD, but nothing used either: there was no
# .allow_undocumented row in the opcode table and no encoding anywhere,
# so every one of these lines was an Invalid Addressing Mode.
#
# Each is an ordinary opcode behind a DD or FD prefix, which is what
# makes the set worth having: ixh and ixl are two more 8 bit registers,
# and a compiler that can reach them spills less.
#
# Every form, so the gold covers the immediate, the two directions of
# the register move, the same-register pair, all eight of the arithmetic
# and logic group, and inc/dec.
name    .allow_undocumented enables the IX/IY half register instructions
tool    asz80
asm     -gloaxff undoc
link    -mxiu ; undoc
goldbin undoc.hex
