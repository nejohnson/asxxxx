# incpath -- an included file's own includes are found beside it.
#
# A .include or .incbin with no path of its own is looked for in the
# directory of the file it is written in.  For a file that was itself
# included, the assembler kept the including file's path and the
# included file's path length, so sub/x.asm's .include "y.asm" and
# .incbin "dat.bin" were looked for at the wrong path and failed.
#
# sub/x.asm, included ahead of main.asm, includes sub/y.asm and takes
# sub/dat.bin with .incbin:  0x10 holds 02, 03, 'D' 'E' 'F', 08, and
# main.asm puts 01 at 0.  The '@'s delimit the file name:  quotes
# would be taken by the shell.
name    An included file's own .include and .incbin are found beside it
src     astest/cases/incpath
asm     -gloaxff -i .include@%s/sub/x.asm@ main
gold    asm0.out
gold    main.rel
link    -mxu -i ; main
gold    main.hex
