# gccrt -- an area reached only through the linker's own area symbols.
name    An area reached only through a_/l_ symbols is kept
src     astest/cases/gccrt
asm     -gloaxff crt
link    -mxiu ; -r start ; crt
gold    crt.map
goldbin crt.hex
