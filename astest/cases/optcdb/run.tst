# optcdb -- a module with no .cdb file is not an error.
#
# SDCDBcopy() copies each module's cdb file into the linker's own and
# already treats a missing one as nothing to copy.  Reporting it as an
# error contradicted that, and made -y fail the link for any module
# assembled without debugging information - which is every module a
# compiler ships in its libraries.
#
# ascheck writes no cdb file, so ts has none:  the link must still
# succeed and still produce the linker's own cdb output.
name    -y with a module that has no .cdb is not an error
src     ascheck/areabank
asm     -gloaxff ts
link    -myx ; -o+%w/dbg ; ts
gold    dbg.map
gold    dbg.cdb
