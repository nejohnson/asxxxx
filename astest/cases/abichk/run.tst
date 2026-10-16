# abichk -- modules whose .abi strings disagree.
#
# Two modules that were built for different calling conventions link
# without complaint otherwise:  every symbol resolves, and the fault
# shows up only when the program runs.  The .abi strings differ, so the
# link is reported and fails.
#
# The report names both modules, because knowing the strings disagree
# is not much use without knowing which two files to look at.
name    Modules whose .abi strings disagree are reported
asm     -gloaxff x1
asm     -gloaxff x2
expect  2
link    -mxu ; x1 ; x2
gold    x1.map
