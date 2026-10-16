# lib -- library member selection.
#
# LibTest calls lfnc02, lfnc03 and lfnc10.  Those pull in members of
# lib_a and lib_b, and those members pull in further members:
# func03 references func02, func10 references func07, func07
# references func04 (ascheck/library/readme.txt).  func05, func06,
# func08 and func09 are not reachable and must not be linked.
#
# This is the closest thing the tree has to dead code removal:  the
# linker already declines to include what nothing refers to, and the
# Libraries Linked block of the map records exactly what it chose.
name    Library member selection, including transitive references
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
link    -mxu ; libtest ; -k %w/ ; -l lib_a ; -l lib_b
gold    libtest.map
