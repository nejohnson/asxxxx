# incsym -- an included file's manufactured symbols belong to its module.
#
# An expression the assembler cannot finish is passed to the linker as
# a symbol it makes up, m1_1 or m2_1, prefixed with the name of the
# source file being assembled so that it is unique across modules.
# common.asm is included by both modules and makes one such symbol in
# each:  had it been named after the included file, both modules would
# define common_1 and the link would fail.  Each .word is 2 * 3:  the
# image is 00 06 00 06.
name    Symbols made up inside an included file are named after the module
src     astest/cases/incsym
asm     -gloaxff m1
asm     -gloaxff m2
gold    m1.rel
gold    m2.rel
link    -mxu -i ; -g two=2 ; m1 ; m2
gold    m1.map
gold    m1.hex
