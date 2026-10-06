# Vendoring notes (not part of upstream)

This repository is a **patched fork** of Alan R. Baldwin's **ASxxxx Cross
Assemblers**. It started as a pristine vendor drop of 6.10 (commit
`903242b`, "Vendor ASxxxx Cross Assemblers v6.10 (upstream, unmodified)")
and local fixes have been applied on top of it since.

> Earlier revisions of this file described the tree as read-only and said
> bugs would be reported upstream rather than patched here. That stopped
> being true almost immediately and the description is corrected below;
> the intent it was reaching for — that every local change stays cleanly
> separable from upstream — is preserved by the branch policy instead.

## Upstream drop

- **Source**: https://shop-pdp.net/ashtml/asxxxx.htm (official site)
- **Fetched**: https://shop-pdp.net/_ftp/asxxxx/asxs6p10.zip
- **Version**: 6.10 (July 2026 per the download page; the bundled
  `readme.txt` itself says "Version 6.0, May 2026" — upstream's own docs
  lag the code, a known quirk, see SDCC's `sdcc/sdas/doc/asmlnk.txt` for
  the same pattern on their fork).
- **SHA-256 of the zip**: `cd1598bcfb75c0cce4b70c9da8f1c689675f785e08ed555dedf3143aa7fe08de`
- **License**: GPLv3 (`gpl3.txt` at repo root; per-file GPL headers
  throughout, e.g. `as8085/i85mch.c`, `as8085/i85pst.c`).
- **Layout**: the zip's `asxv6pxx/` wrapper directory has been flattened
  into this repo's root (i.e. `asxxsrc/`, `asz80/`, `as8085/` etc. are at
  the top level here) purely for easier diffing against
  `sdcc/sdas/asxxsrc`, `sdcc/sdas/asz80`, etc. in the sdcc-8085 project.
  No file contents were changed by the flattening.
- **Bug reports**: via the form linked from
  https://shop-pdp.net/ashtml/asxbug.php.

## How local changes are made

Every change is kept individually submittable to Baldwin, because at some
point it will be offered upstream.

- **One self-contained change per branch**, `bugfix/<slug>` for a defect
  and `feat/<slug>` for an addition, merged back to `master` with
  `--no-ff` so the branch stays visible in the history and
  `git log master..<branch>` is the patch.
- **Commit messages carry the analysis**: what the defect is, the
  mechanism, then a `Verified:` section recording what was actually run —
  reproducer, regression comparison, sanitizer build. These are written to
  be read by someone who did not do the work.
- **Fork-only files never appear on those branches.** `VENDOR.md` and
  `GC-SECTIONS-FEASIBILITY.md` are local artifacts; a patch sent upstream
  must not contain them.
- `903242b` is the pristine baseline: `git diff 903242b master -- <path>`
  is the total local divergence for any file.

## Local changes so far

Grouped by what each one would be if it were offered upstream, because
that is the only distinction that matters when the time comes. Within a
group, oldest first.

Four commits are not submittable in the shape they are in, and there is
a table for them below. Three repair something this fork itself added,
so they belong squashed into their parent rather than sent as defects in
their own right; the fourth carries two unrelated changes and needs
splitting.

### Fixes to upstream defects

Submittable as they stand.

| Commit | Area | Change |
|---|---|---|
| `1fbc20f` | `asz80` | `i85pg1[0x11]` incorrectly marked `LD DE,nn` illegal on 8085 |
| `83a99c1` | `asxxsrc` | `aslex.c` read only half of the `ib[]` input line buffer |
| `56c5bcd` | `asxxsrc` | made the source-line input buffer (`ib[]`/`ic[]`) dynamically sized |
| `5356e4c` | `aslink` | `DefineSDCDB()` hung forever on any symbol containing a `$` (i.e. on every SDCC symbol) — the scan pointer was never advanced |
| `5c1a749` | `aslink` | stack-buffer overflow building the generated `a_`/`l_`/`m_`/`s_` area symbol names; buffer was sized for the prefix but not the section index |
| `d5e2177` | `aslink` | `NCPS` was 80 in the linker against 256 in the assemblers, so long names were truncated on read and distinct symbols silently collided |
| `d150ace` | `asxxsrc`, `aslink` | identifier truncation was silent in both tools; now reported (new assembler error code `<l>`) |
| `7d7548b` | `aslink` | `lkparea()` searched the area list linearly; hash the names |
| `d5994a8` | `s19os9` | the input file was closed twice |
| `f49765f` | `asxxsrc` | a `. = <arg>` error cleared the location counter's area |
| `0d2c37a` | `ascheck` | the `bndry` test generated the wrong area symbol names |
| `a0a3eda` | `aslink` | a module with no `.cdb` file was treated as an error |
| `62b5902` | `aslink` | `-l` could not find a library named by a path, and said nothing when one was missing |
| `c9fbd13` | `aslink` | a malformed object record was an endless loop rather than an error |
| `ad6cd6e` | `aslink` | crashed printing a relocation error against a library module — every header pulled from a library has `h_lfile == NULL` |
| `f3922a6` | `asz80` | `sll` reported `Internal Opcode Error` for a mnemonic its own table carries |
| `d7ee0bd` | `asxxsrc` | a manufactured symbol name took the source file name verbatim, so a file name containing a `-` produced a symbol the linker could not read back as an expression operand — `-` is also subtraction. Sanitised in `symfn()`, which is also where `18aa725` is reverted |
| `8f3852f` | `as8xcxxx` | the predefined 8051 SFR names were missing. `ds8.h` declares `struct PreDef` and an `extern` for the table, but no table was ever defined and `minit()` never registered one, so the `extern` dangled and every name `as8xcxxx` shares with `as8051` assembled as an undefined global. Table and registration added, matching `as8051`'s values |
| `bfac3cf` | `asrab` | the Rabbit's `add sp,n` is a signed displacement - negative allocates a stack frame - and was range checked as unsigned, so every frame allocation was refused with the correct bytes already in the listing. 190 sites in each of the six Rabbit ports |
| `093caac` | `asrab` | the Rabbit 3000A support in `6a57c37` converted the thirty machine-type tests in `rabmch.c` and missed the four in `rabadr.c` and the cycle-count table, so under `.r3ka` the opcodes worked and the addressing modes did not |
| `7de9475` | `aslink` | `-a AREA =` and `-b BANK =` took whatever `expr()` returned, and `expr()` reduces every number it scans to the address space, so a base beyond the space silently became the low bits of itself and the map printed the same masked value. Checked where the digits are read, because `expr()` sign-extends and a legitimate `0xFF80` arrives as `0xFFFFFF80` |
| `ac2a167` | `asez80` | `lea` took its displacement only in the second operand, Zilog's spelling. Code generators write it as a third, which is the same instruction and the same bytes; the code already parsed the expression, it just could not step over the comma |

### Additions

New behaviour rather than repaired behaviour. Each is self-contained and
guarded, but an addition is a different conversation upstream from a
defect, so they travel separately.

| Commit | Area | Addition |
|---|---|---|
| `5e75020`, `64281e6`, `4870877` | `astest` | a portable regression harness for the assemblers and the linker: C89 driver, `.tst` case format, `make check` / `make bless`. 40 cases |
| `d033ae5` | `asxxsrc` | `.function` / `.endfunc`, per-function areas that inherit the enclosing area's flags and bank |
| `80f74d0` | `aslink` | the section collector — `-r` roots, `KEEP`, `--print-gc-sections` equivalent |
| `a3ce67a` | `aslink` | `-o+` names every file the linker creates after the program rather than after the first object |
| `5c4207e` | `asxxsrc`, `aslink` | `.abi`, an opaque compatibility key compared between modules at link time |
| `94d8c73` | `aslink` | report an area that runs off the end of the address space, which was silently wrapping |
| `40e56a0` | `asz80` | `.allow_undocumented` and the IX/IY half register instructions. Upstream already classified the operands and reserved the opcode type; only the directive row and the encodings were missing |
| `d02ee7a` | `asz80` | `tst` accepts `tst a,n` as well as `tst n`. Same instruction, same bytes; code generators emit the first |
| `6392f48` | `asrab` | `LZ` and `LO`, the Rabbit's names for the two logical conditions, alongside the `NV` and `V` it already had. Same two encodings |
| `d298d9b` | `asz80` | `.r800`, `multu` and `multuw`, and the IX/IY half registers with them. The ASCII R800 is a Z80 superset that `asz80` did not cover |
| `6a57c37` | `asrab` | the Rabbit 3000A: `.r3ka`, the block-move group, `uma`/`ums`, the system/user mode group and `push`/`pop su`. The machine type was a single value compared for equality, so there was no room for a second Rabbit |
| `614da60` | `asrab` | `ipset0`..`ipset3` beside the manual's `ipset n`. Same instruction, same two bytes |

### Not for upstream as separate patches

| Commit | Why |
|---|---|
| `03533d2` | repairs `s19os9` after **our own** `56c5bcd` made `ib[]` a pointer. Belongs squashed into `56c5bcd` |
| `b37cf7e`, `79c25e7` | both correct sign-extension bugs in **our own** `94d8c73`. Belong squashed into it — three commits, one patch |
| `18aa725` | **reverted by `d7ee0bd`** and no longer in the tree. It taught the linker's `newsym()` to accept `-` in a symbol's own name, which was the same defect treated one layer out: a name is only half of it, and an expression referring to that name is the other half. Not to be offered upstream, and worth remembering as the shape of mistake it was - the assembler was manufacturing the name, so the assembler was where to fix it |
| `198f405` | two changes in one: a real `lstarea()` fix (map generation was `O(sections * symbols)`; 10,000 sections took 10.36 s, of which nine tenths was the map) and a new `-mc` compact map format. Split before offering |

### Documentation

Travels with whichever change above it describes, never on its own.

| Commit | Describes |
|---|---|
| `baf7fcd` | the `<k>`, `<l>` and `<v>` assembler error codes |
| `f0528ad` | `.function`, `.endfunc`, `KEEP`, `-r` and the `<f>` error |
| `246880f` | a name may be 255 characters, not 79 |
| `91f79bb` | `aslink`'s `-o+` |
| `1131948` | the `.abi` directive and the `O` line |

### Fork-only files

Never on a branch that goes upstream.

- `VENDOR.md` — this file (`2b32c63`, `5d0dd04`, and the commit that
  added this line).
- `GC-SECTIONS-FEASIBILITY.md` — a study of whether ASLink could gain an
  `ld --gc-sections` equivalent. Added in `6b8fdc3`, updated in
  `abd44c1`, `8341553`, `89cf960`, `9e68e94`, `3b976de` and `7690547`.

### One measured obstacle to submitting any of it

`astest`'s golden files pin **this fork's** output, not upstream's. The
map module column is wider because `d5e2177` took `NCPS` from 80 to 256,
and the area and symbol listing changed again in `198f405`. Goldens have
to be regenerated against pristine `903242b`, and the cases sorted by
which feature patch each one travels with, before the harness can be
offered to anyone.

## Known divergences and upstream quirks

- **`asmlnk.pdf` is stale.** The manual ships as four renderings of one
  fixed-width layout — `.txt`, `.rtf`, `.htm` and `.pdf` — with no source
  document in the distribution, and `asxdoc/` and `asxhtml/` carry
  byte-identical copies of three of them. `baf7fcd` updated all six text
  files but the two copies of `asmlnk.pdf` are a print of the RTF and
  cannot be regenerated here without re-typesetting the whole document.
  They lag by three error-code entries.
- **`asxhtml/asmlnk.htm` is broken as HTML** (upstream, unmodified by us).
  It is `asmlnk.txt` with an HTML header and footer bolted on: no `<pre>`,
  no entity escaping, raw form feeds. Browsers therefore parse every
  `<x>` error code and every `<arg>` placeholder as an unknown tag and
  drop it, so parts of the manual are simply invisible in that rendering.
  `asxhtml/asxs03.htm` is generated correctly, with escaping, so the
  tooling to do it right exists. **Worth reporting upstream.**
- **The manual has no source form in the distribution.** Editing it means
  editing the rendered artifacts by hand, keeping the hardcoded
  pagination valid (700 pages, at most 55 lines each). `baf7fcd`'s message
  records how the formats line up.

## Relevant targets for the sdcc-8085 project

- `asz80/` — the Z80 family assembler, including its own 8080/8085
  sub-modes (Zilog mnemonics). This is the lineage SDCC's `sdasz80`
  forked from.
- `as8085/` — a **separate**, dedicated 8080/8085 assembler using classic
  Intel mnemonics (`i85mch.c`, `i85pst.c`, `i8085.h`). Ships its own test
  programs distinguishing the three same instruction-set tiers SDCC's
  fork already models: `t8080.asm` (documented 8080), `t8085.asm`
  (documented 8085), `t8085x.asm` (undocumented 8085) — a strong
  structural match to SDCC's own `X_8080`/`X_8085`/`X_8085X`.
- `asxxsrc/` — the shared core both `asz80/` and `as8085/` (and every
  other target) plug into. This is what SDAS's own `asxxsrc/` forked
  from.
- `linksrc/` — ASLINK, the relocating linker SDCC's `sdldz80` forked from.
