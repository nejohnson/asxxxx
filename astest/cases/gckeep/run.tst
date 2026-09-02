# gckeep -- roots that are not reachability.
name    ABS, KEEP and -a areas are kept;  an unreached area is not
src     astest/cases/gckeep
asm     -gloaxff k
link    -mxu ; -r main ; -a PLACED=0x0200 ; k
gold    k.map
