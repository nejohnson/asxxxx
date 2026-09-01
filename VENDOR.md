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

- **One self-contained change per `bugfix/<slug>` branch**, merged back to
  `master` with `--no-ff` so the branch stays visible in the history and
  `git log master..bugfix/<slug>` is the patch.
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

Fixes, oldest first. All are upstream defects, none are fork-specific
adaptations.

| Commit | Area | Change |
|---|---|---|
| `1fbc20f` | `asz80` | `i85pg1[0x11]` incorrectly marked `LD DE,nn` illegal on 8085 |
| `83a99c1` | `asxxsrc` | `aslex.c` read only half of the `ib[]` input line buffer |
| `56c5bcd` | `asxxsrc` | made the source-line input buffer (`ib[]`/`ic[]`) dynamically sized |
| `18aa725` | `aslink` | accept `-` in a symbol name when reading a `.rel` `S` record |
| `5356e4c` | `aslink` | `DefineSDCDB()` hung forever on any symbol containing a `$` (i.e. on every SDCC symbol) — the scan pointer was never advanced |
| `5c1a749` | `aslink` | stack-buffer overflow building the generated `a_`/`l_`/`m_`/`s_` area symbol names; buffer was sized for the prefix but not the section index |
| `d5e2177` | `aslink` | `NCPS` was 80 in the linker against 256 in the assemblers, so long names were truncated on read and distinct symbols silently collided |
| `d150ace` | `asxxsrc`, `aslink` | identifier truncation was silent in both tools; now reported (new assembler error code `<l>`) |
| `baf7fcd` | `asxdoc`, `asxhtml` | manual's error-code list was missing `<k>`, `<v>` and the new `<l>` |

Local documents, not for upstream: `GC-SECTIONS-FEASIBILITY.md` (a study
of whether ASLink could gain an `ld --gc-sections` equivalent, added in
`6b8fdc3` and updated in `abd44c1` and `8341553`) and this file.

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
