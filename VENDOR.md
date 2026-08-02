# Vendoring notes (not part of upstream)

This repository is a **pristine, read-only vendor drop** of Alan R.
Baldwin's **ASxxxx Cross Assemblers**. Nothing under any of the upstream
directories (`asxxsrc/`, `asz80/`, `as8085/`, `linksrc/`, ...) is ever
edited locally. If a bug is found, it gets reported upstream, not patched
here.

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
  No file contents were changed.
- **Bug reports**: via the form linked from
  https://shop-pdp.net/ashtml/asxbug.php.

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
