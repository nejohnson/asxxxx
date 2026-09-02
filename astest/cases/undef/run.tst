# undef -- the negative case.
#
# Proves the harness reports a failing link rather than passing it,
# and pins both the diagnostic and the exit status.  One such case is
# enough:  symdef() walks the symbol hash table in bucket order, so
# with more than one undefined symbol the order of the warnings in the
# map depends on NCPS, NHASH and the hash function.
name    An undefined global is reported and the link fails
asm     -gloaxff u1
expect  2
link    -mxu ; u1
gold    u1.map
