# tst -- the accumulator may be named or left out.
#
# tst can only ever test the accumulator, so "tst a,n" and "tst n" are
# the same instruction written two ways.  This assembler took only the
# one operand form, which is how Zilog's Z180 manual writes it; SDCC,
# like SDAS, emits the two operand form, because it reads like every
# other instruction that works on a.  That cost the whole of SDCC's
# ucz80n suite one test, and it was the last thing between that port
# and a clean run.
#
# The optional "a," is handled the way the arithmetic and logic group
# already handles it, so a first operand that is not a is still an
# error rather than being quietly ignored - see tstbad.
#
# Both machines, because the immediate form has a different opcode on
# each: ED 27 on the ZX Next, ED 64 on the Z180.
name    tst takes the accumulator named or left out, and nothing else
tool    asz80
asm     -gloaxff tstz
asm     -gloaxff tsth
link    -mxiu ; tstz ; tsth
goldbin tstz.hex
expect  2
asm     -gloaxff tstbad
