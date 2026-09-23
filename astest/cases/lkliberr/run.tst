# lkliberr -- a relocation error against a library module is reported,
# not crashed on.
#
# errdmp4() and errdmp3() print where the symbol was referenced from and
# where it was defined, both as hp->h_lfile->f_idp.  A module named in
# the link script has an lfile; one pulled from a library does not.
# loadfile() in lklibr.c opens the library member with fopen() rather
# than reaching it through the script's file list, so it never becomes
# the current lfile, and lkmain.c has already cleared cfp for the
# library pass by then.  Every such header therefore had h_lfile NULL,
# and the six sites that dereferenced it took the linker down with
# SIGSEGV - while it was part way through printing the diagnostic the
# user needed, and for the common case of a symbol resolved out of a
# library.
#
# edef_lo and edef_hi straddle the end of page 0, so the direct page
# reference in emain cannot reach edef_hi.  aslink must report that and
# exit 2.  Before the fix it printed the Refby line and died on the
# Defin line, giving exit 139 and half a diagnostic.
name    A relocation error against a library module is reported, not a crash
tool    as6808
asm     -gloaxff edef
asm     -gloaxff emain
copy    elib.lib
expect  2
link    -mxu ; -a DPAGE=0x00FF ; -a MAIN=0x8000 ; emain ; -k %w/ ; -l elib
