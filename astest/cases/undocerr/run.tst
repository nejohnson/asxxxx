# undocerr -- what .allow_undocumented does not allow.
#
# Three refusals, because a flag that turns instructions on is only
# worth having if it is still clear about the ones that do not exist.
#
# noflag:  without the directive the half registers stay refused, so no
#          program that assembles today changes meaning.
# badreg:  h and l name the index register's own halves behind the
#          prefix, and one prefix cannot name both index registers.
# z180:    the Z180 traps on an illegal instruction instead of quietly
#          doing what the Z80 did.
name    The IX/IY half registers stay refused where they cannot be encoded
tool    asz80
expect  2
asm     -gloaxff noflag
expect  2
asm     -gloaxff badreg
expect  2
asm     -gloaxff z180
