# itst -- diagnostics from nested .include files.
#
# Upstream's ascheck/itst: two source files, each including a chain
# five files deep, with an error on a line at every level going in and
# coming out, and one .include of a file that does not exist.  Each
# diagnostic carries the line number within the file the error is in,
# and the name of the source file being assembled:  that name also
# prefixes the symbols the assembler manufactures, which must be one
# per module (see incsym), so an included file reports under its
# includer's name.  The comment in itsta.asm, which names the included
# files, describes an older release.
name    Diagnostics from nested .include files name the right lines
src     ascheck/itst
expect  2
asm     -gloaxff itsta
gold    asm0.out
gold    itsta.lst
expect  2
asm     -gloaxff itstb
gold    asm1.out
