# badrel -- a corrupt object record is reported, not looped on.
#
# eval() reads every numeric field of a .rel record.  Given a character
# that is not a digit in the current radix it consumed nothing and
# returned 0, so the 'while (more())' loops that read T and R records
# called it again on the same character for ever.  Any truncated or
# corrupted object file could wedge the linker - under a parallel make
# that is a stuck job rather than a failed one.
#
# bad.rel is a hand written object file, valid but for the 'zz' in its
# second T record.  The link must stop with ER_FATAL (3).
#
#   The hang is deliberate.  Revert the fix and this case does not
#   print FAIL, it stops 'make check' dead:  astest has no timeout,
#   and is not to be given one on this case's account.  A failure
#   line can be skimmed past;  a suite that will not finish cannot
#   be, which is the right weight for a defect whose symptom is a
#   linker that never returns.
name    A malformed object record is an error, not a hang
copy    bad.rel
expect  3
link    -mx ; bad.rel
