# t90jp -- jp and call through a register, and the silent wrong answer.
#
# S_JP handled a register operand only after a condition - "jp t,hl" -
# and for the unconditional form went straight to expr().  "(hl)" is a
# perfectly good parenthesised expression naming a symbol hl, so
# "jp (hl)" assembled, with no diagnostic whatever, as 1A followed by
# a relocatable word: an absolute jump to an undefined global.  It
# then linked, because the global was undefined and undefined globals
# are a warning.
#
# That is the worst shape of bug this project has found so far: wrong
# code, no error, and only a running program to show for it.  It is
# why SDCC's tlcs90 port was attempted in September and reverted - 84
# of 202 library objects were wrong.
#
# Two things are fixed here.  Leaving the condition out is the T
# (always) condition, so the register forms have to be looked for
# there too; and the operand is taken in either spelling, because
# tt90.asm in this directory writes "jp t,hl" where Toshiba's manual,
# SDAS and SDCC write "jp (hl)".  Same instruction, same two bytes.
#
# The gold pins each pair assembling identically, and tt90.asm still
# assembles to the bytes its own comments give for all 750 of them.
name    jp and call take a register operand written either way
tool    astlcs90
asm     -gloaxff t90jp
link    -mxiu ; t90jp
goldbin t90jp.hex
expect  2
asm     -gloaxff t90jpbad
