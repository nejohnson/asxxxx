ASxxxx V6.10 - BUG FIXES
========================

Twenty-six fixes to the ASxxxx Cross Assemblers V6.10, found while
using ASxxxx as the assembler and linker for an 8085/8080 and STM8
port of the SDCC C compiler.

Each fix is a separate patch, numbered in the order they apply.  The
text at the top of each patch explains the problem, the change, and
how it was checked.  The patches change only the existing files named
below; they add no files and no command-line options.


APPLYING
--------

The patches are against the V6.10 distribution exactly as released.
From the top of the distribution (the directory holding asxxsrc,
linksrc, asz80, ...):

    patch -p1 < 0001-asz80-fix-i85pg1-0x11-....patch
    patch -p1 < 0002-...
    ...

in numerical order.  Some patches build on an earlier one (for
example 0003 on 0002, and 0024 on 0023), so the order matters.  The
tree builds after every patch.

all-fixes.patch is the same 26 changes as a single patch, for
applying in one step:

    patch -p1 < all-fixes.patch

The sources use CR-LF line endings and so do the patches.  On Windows
GNU patch may need --binary to keep them.

Every patch was checked by applying it with GNU patch to a fresh copy
of the V6.10 distribution; the result is identical, file for file,
to the tree they were made from.


THE PATCHES
-----------

01  asz80: fix i85pg1[0x11] incorrectly marking LD DE,nn illegal on 8085
    asz80/t80.asm, asz80/z80mch.c

02  asxxsrc: fix aslex.c reading only half of the ib[] input line buffer
    asxxsrc/aslex.c

03  asxxsrc: make the source-line input buffer (ib[]/ic[]) dynamically sized
    asxxsrc/asdata.c, asxxsrc/aslex.c, asxxsrc/asmain.c,
    asxxsrc/asxxxx.h, s19os9/s19os9.c

04  aslink: fix DefineSDCDB() hanging on any symbol containing a '$'
    linksrc/lksdcdb.c

05  aslink: size the linker-generated symbol name buffers correctly
    linksrc/aslink.h, linksrc/lkarea.c, linksrc/lknoice.c

06  aslink: raise NCPS to 256 to match the assemblers, fixing symbol collisions
    asxdoc/asmlnk.rtf, asxdoc/asmlnk.txt, asxhtml/asmlnk.htm,
    asxhtml/asmlnk.rtf, asxhtml/asmlnk.txt, asxhtml/asxs02.htm,
    linksrc/aslink.h

07  asxxxx, aslink: report identifier truncation instead of doing it silently
    asxdoc/asmlnk.rtf, asxdoc/asmlnk.txt, asxhtml/asmlnk.htm,
    asxhtml/asmlnk.rtf, asxhtml/asmlnk.txt, asxhtml/asxs03.htm,
    asxxsrc/aslex.c, asxxsrc/assubr.c, linksrc/lklex.c

08  aslink: index symbols by areax so the map is not quadratic
    linksrc/aslink.h, linksrc/lklist.c, linksrc/lkmain.c,
    linksrc/lksym.c

09  aslink: hash the area names, removing lkparea()'s linear search
    linksrc/aslink.h, linksrc/lkarea.c

10  s19os9: do not close the input file twice
    s19os9/s19os9.c

11  asxxxx: do not clear the location counter's area on a '. = <arg>' error
    asxxsrc/asmain.c

12  ascheck: correct the generated area symbol names in the bndry test
    ascheck/bndry/b_areas_1.asm, ascheck/bndry/b_areas_2.asm,
    ascheck/bndry/b_areas_3.asm

13  aslink: a module with no .cdb file is not an error
    linksrc/lkmain.c, linksrc/lksdcdb.c

14  aslink: find a -l library named by a path, and say so when one is missing
    linksrc/aslink.h, linksrc/lklibr.c

15  aslink: a malformed object record is an error, not an endless loop
    linksrc/lkeval.c

16  aslink: do not crash reporting a relocation error against a library module
    linksrc/aslink.h, linksrc/lkhead.c, linksrc/lklibr.c,
    linksrc/lkrloc3.c, linksrc/lkrloc4.c

17  asz80: sll reported an Internal Opcode Error for its own mnemonic
    asz80/z80mch.c

18  asxxxx: keep manufactured symbol names to identifier characters
    asxxsrc/asexpr.c, asxxsrc/asxxxx.h

19  as8xcxxx: predefine the core 8051 SFRs, as as8051 already does
    as8xcxxx/ds8mch.c, as8xcxxx/ds8pst.c

20  asrab: "add sp,n" takes a signed displacement, so do not range check it
    asrab/rabmch.c

21  aslink: report a base address that does not fit the address space
    linksrc/aslink.h, linksrc/lkarea.c, linksrc/lkbank.c,
    linksrc/lkdata.c, linksrc/lkeval.c

22  astlcs90: jp and call take a register operand written either way
    astlcs90/t90mch.c

23  asgb: ldh takes a full I/O address, in both directions
    asgb/gbmch.c

24  asgb: the relocatable ldh could not link at all
    asgb/gbmch.c

25  asxxsrc: re-enter an overlay area at its start, not where it left off
    asxxsrc/asmain.c, asxxsrc/asxxxx.h

26  asxxsrc: an included file's .include and .incbin are found beside it
    asxxsrc/aslex.c


COMMIT NAMES IN THE TEXT
------------------------

Some patch descriptions refer to another change by a seven-character
name such as 83a99c1.  These name commits in the public copy of this
work at

    https://github.com/nejohnson/asxxxx

where each patch here began.  The fork commit(s) behind each patch:

    01  1fbc20f
    02  83a99c1
    03  56c5bcd, 03533d2
    04  5356e4c
    05  5c1a749
    06  d5e2177, 246880f
    07  d150ace, baf7fcd
    08  8bd8253
    09  7d7548b
    10  d5994a8
    11  f49765f
    12  0d2c37a
    13  a0a3eda
    14  62b5902
    15  c9fbd13
    16  ad6cd6e
    17  f3922a6
    18  d7ee0bd (asxxsrc part)
    19  8f3852f
    20  bfac3cf
    21  7de9475
    22  c0d155f
    23  ce6624f
    24  8b83c64
    25  c082027
    26  b711951

More changes - new directives, linker options and a regression test
suite - are on the same repository's submit/series branch, after
these 26.  None of the fixes here depends on any of them.

Neil Johnson <neil.johnson71@gmail.com>
