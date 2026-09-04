# libpath -- a -l naming a path, alongside a -k path.
#
# Same corpus as the lib case, but the libraries are named by a path
# rather than by a bare name, while a -k path is also given.  addlib()
# only ever offered the -l argument to the -k paths, so lib_a was
# looked for under %w/%w/ and never found;  nothing said so, and the
# link ended in undefined symbols naming the functions rather than
# the library.  The member names inside a library are relative to the
# library, so finding it by path has to set the search path too.
name    A -l naming a path is found, and its members with it
src     ascheck/library/src
asm     -oxff func01
asm     -oxff func02
asm     -oxff func03
asm     -oxff func04
asm     -oxff func05
asm     -oxff func06
asm     -oxff func07
asm     -oxff func08
asm     -oxff func09
asm     -oxff func10
src     ascheck/library/bin
copy    lib_a.lib
copy    lib_b.lib
src     ascheck/library
asm     -olxff libtest
link    -mxu ; libtest ; -k %w/ ; -l %w/lib_a ; -l %w/lib_b
gold    libtest.map
