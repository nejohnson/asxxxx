# Link-Time Dead Code / Dead Data Removal for ASxxxx

**A feasibility study for an ASLink equivalent of GNU `ld --gc-sections`**

| | |
|---|---|
| Subject | ASxxxx Cross Assemblers + ASLink, V06.10 (2026) |
| Scope | 56 target assemblers sharing `asxxsrc/`, one shared linker `linksrc/` |
| Consumer | SDCC, via the in-progress ASxxxx-into-SDCC port replacing `sdas`/`sdld` |
| Date | 2026-09-01 (rev. 2 — SDCC identified as the client) |
| Verdict | **Feasible and worth doing. The object format already carries everything needed, and with SDCC as the consumer the granularity question is answered. The remaining work is bounded.** |
| Already actioned | Three defects found during this study are fixed on `master`: the `aslink -y` hang (§7.4, `5356e4c`), a stack-buffer overflow in `lnksect()` (§6.7, `5c1a749`), and the `NCPS` symbol-name truncation mismatch (§6.7/§7.6, `d5e2177`). |

---

## 1. Executive summary

Implementing `--gc-sections`-style dead code and dead data removal in ASLink is **technically feasible without any change to the `.rel` object file format**, and without changes to the 56 target-specific assembler back ends.

The reason is a single structural fact, confirmed empirically below: **ASxxxx's `areax` (one `A` directive in one object module) is already exactly an ELF input section**, and the `R` relocation records already form a complete, sound section-to-section reference graph. The linker resolves every relocation as either "areax + addend" or "symbol → its defining areax". Nothing is missing.

**Granularity — the question that would otherwise sink this — is answered.** ASLink can only collect at the granularity the source provides, exactly as `ld --gc-sections` is inert without `-ffunction-sections`. A hand-written module has one `_CODE` area and nothing is collectable. But the ongoing port of ASxxxx into SDCC (displacing `sdas`/`sdld`) supplies a real code generator that already knows where functions begin and end, and can emit one area per function. That makes SDCC the client, and it changes this from a curiosity into a fundable feature. §7 covers what that client implies.

What is *not* free:

1. **The linker does not scale to per-function sections today.** Measured: 10,000 sections takes **10.7 s** to link versus 0.034 s for the same 10,000 symbols in one section — a ~315× regression, of which ~10 s is map-file generation alone (`lstarea()` is O(areas × symbols) executed twice per area, plus a bubble sort). This is a pre-existing quadratic that per-function sections detonate. With SDCC it is worse than it looks: `.cdb` debug output is emitted *from inside* `lstarea()` and `-y` forces map generation on, so **every SDCC debug build rides this path** (§7.3).
2. **There is a silent-corruption trap in area attribute inheritance** that anything splitting functions into areas will hit, demonstrated in §4.3: sections that omit the parent's bank attributes land in a different bank and are laid out at overlapping addresses with no diagnostic.
3. **The classic crt0 pattern defeats naive liveness**, demonstrated in §6.1: `_INIT`-style data areas are reached only through linker-generated `a_<area>` / `l_<area>` symbols, which have no areax back-link. A GC that does not special-case these will silently delete initialised data. This is precisely SDCC's `_INITIALIZER`/`_INITIALIZED` idiom, so it is guaranteed to be hit, not merely possible.
4. **SDCC's `_GSINIT` chain is a fallthrough structure**, not a call graph (§7.2). It must be excluded from collection and from splitting, or global initialisers break silently.

**Separately, and unrelated to GC: `aslink -y` hung forever on any SDCC symbol.** `DefineSDCDB()` never advanced its scan pointer, so the first symbol containing a `$` — which is every SDCC symbol — spun indefinitely. Found during this study, reproduced, and **fixed on `master` in commit `5356e4c`** (§7.4). It blocked the SDCC port outright, regardless of whether GC is ever built.

Recommended shape: fix the map/`lstarea()` quadratic next, since the SDCC port needs it independently of GC; then build the collector behind an opt-in flag with SDCC emitting per-function areas.

---

## 2. What we are actually trying to build

GNU `ld --gc-sections` does three things:

1. Treat each input section as an indivisible unit.
2. Build a directed graph: section A → section B if A contains a relocation whose target resolves into B.
3. Mark from a root set (entry symbol, `KEEP()` sections, `-u` symbols, `.init`/`.fini`), sweep everything unmarked, then lay out only the survivors.

Everything below maps ASxxxx onto that model.

---

## 3. How ASxxxx works today

### 3.1 The allocation model

The linker's data model (`linksrc/aslink.h:586-622`) is a two-level structure:

- **`struct area`** — one per *unique area name* across the whole link. Carries the flags (CON/OVR, REL/ABS, PAG, CSEG/DSEG, banked), the final base address, and the total size.
- **`struct areax`** — one per *`A` directive in one object module*. Carries this contribution's size, boundary requirement, its base area, and its owning `head` (module).

`lnkarea()` (`linksrc/lkarea.c:422-476`) walks banks then areas assigning base addresses; `lnksect()` (`lkarea.c:513-581`) walks the areax chain of one area either concatenating (`CON`) or overlaying (`OVR`) them.

> **This is the key structural finding.** `areax` *is* an input section. It has a size, an alignment (`a_bndry`), an owning object file, and a base area that behaves exactly like an output section. Removing an `areax` from its area's chain is a well-formed operation that `lnksect()` already handles naturally — the sizes just get smaller.

### 3.2 The two-pass link

`main()` (`linksrc/lkmain.c:302-371`) runs exactly two passes over the `.rel` files:

- **Pass 0** processes `H`, `M`, `G`, `B`, `A`, `S` records and *skips* `T`, `R`, `P` entirely (`lkmain.c:622-628`). At the end of pass 0 it does library resolution (`search()`), area/bank base assignment (`setarea()`, `setbank()`, `lnkarea()`), expression symbol evaluation (`prcsym()`), undefined-symbol reporting (`symdef()`), and map output.
- **Pass 1** re-reads the files and processes `T`/`R`/`P` to relocate and emit code.

So the linker already has, at the end of pass 0, a complete picture of every area, every areax, and every symbol — *but not the relocations*. That is the one piece a collector needs to add.

### 3.3 What the relocation records actually encode

`relr4()` (`linksrc/lkrloc4.c:398-418`) resolves each relocation entry one of two ways:

```c
if (mode & R4_SYM) {
        reli = symval(s[rindex]);       /* symbol → sym->s_axp->a_addr + s_addr */
} else {
        reli = a[rindex]->a_addr;       /* area  → this module's areax base     */
}
```

`a` is `hp->a_list` — an array of **`struct areax *`**, module-local. `s` is `hp->s_list`. And `struct sym` carries `s_axp`, the areax it was defined in (`aslink.h:639`, set in `newsym()` at `linksrc/lksym.c:182`).

Therefore **every relocation already names a specific target `areax`**, either directly or through a symbol. And the `R` line's leading area index names the *containing* `areax`. The graph is right there.

### 3.4 Where the assembler chooses symbol-vs-area relocation

This matters enormously, so it is worth being precise. In `asxxsrc/asexpr.c:1077-1091`, an identifier becomes a *symbol* relocation only if it is still undefined **and** global:

```c
sp = lookup(id);
if (sp->s_type == S_NEW) {
        if (sp->s_flag & S_GBL) {
                esp->e_flag = 1;        /* → R_SYM */
```

Otherwise the expression carries `e_base.e_ap` (the symbol's area) and `asout.c:637-644` emits an **area** relocation with the offset folded into the `T` data:

```c
} else if (esp->e_flag) {
        n = esp->e_base.e_sp->s_ref;  r |= R_SYM;
} else {
        n = esp->e_base.e_ap->a_ref;  r |= R_AREA;
}
```

Consequence: **a reference to a symbol defined in the same module is always an area relocation, even when that symbol is `.globl`.** Cross-module references are symbol relocations. Also note `outgsd()` (`asout.c`) only emits `S_GBL` symbols — local labels never reach the `.rel` file at all.

This is exactly why per-function granularity requires per-function *areas* rather than per-function symbols: within a module, symbols are not the currency, areas are.

---

## 4. Empirical confirmation

All of the following was produced by building `asz80` and `aslink` from this tree with `gcc -O2` and running them.

### 4.1 Today's output: one area, area-relative references

`m1.asm` — `main` calls a global (`used_fn`), a local (`local_fn`), and an external (`extfn`); `dead_fn` is called by nobody:

```
A _CODE size 16 flags CD80 bank 0
S dead_fn Def0010
S used_fn Def000A
S main Def0000
S local_fn Def000D
T 00 00 CD 0A 00 CD 0D 00 CD
R 00 00 00 00  01 03 00 00  01 06 00 00
T 07 00 00 00 C9
R 00 00 00 00  81 02 01 00
```

Reading the `R` groups (`mode, rtp, index-lo, index-hi`):

- `01 03 00 00` — mode `0x01` = word, **no `R4_SYM` bit** → *area* relocation, area index 0 = `_CODE`, addend `0x000A` from the `T` data. This is the call to the **global** `used_fn`.
- `01 06 00 00` — likewise for the local `local_fn` at `0x000D`.
- `81 02 01 00` — mode `0x81` = `R4_SYM|R4_WORD` → *symbol* relocation, symbol index 1 = `extfn`.

So with one area per module, the graph has exactly one node and self-edges. **Nothing is collectable.** This confirms the granularity problem is the dominant one.

### 4.2 Per-function areas: the graph appears, with no format change

The same code with one `.area` per function:

```
A _CODE.main     size A flags D00
A _CODE.used_fn  size 3 flags D00
A _CODE.dead_fn  size 3 flags D00
A _CODE.dead_fn2 size 3 flags D00
T 00 00 CD 00 00 CD 00 00 CD
R 00 00 02 00  01 03 03 00  01 06 05 00
```

Now: containing area index **2** (`_CODE.main`) references area **3** (`_CODE.used_fn`) and area **5** (`_CODE.dead_fn2`), plus symbol `extfn`. Area **4** (`_CODE.dead_fn`) is referenced by nothing.

A mark-and-sweep from `main` keeps `main`, `used_fn`, `dead_fn2`, `extfn` and drops `dead_fn`. **That is `--gc-sections`, and the existing V4 `.rel` format expressed it without a single byte of change.**

### 4.3 ⚠ The area-attribute trap (silent address overlap)

`.area _CODE.main (REL,CON)` produced flags `0x0D00`. The pre-existing `_CODE` has flags `0xCD80`. The missing bits are `A4_BNK` (0x8080) and `A4_CSEG` (0x4000).

`lkbank.c:399-403` assigns every area *without* `A4_BNK` to `bankp` — the default unnamed bank — while `_CODE` goes to the `_CSEG` bank. `lnkarea()` restarts `rloc` at 0 for each bank. Result:

```
_CODE.main                 0000        000A        (default bank)
...
[ Bank == _CSEG ]
_CODE                      0000        0003        ← overlaps _CODE.main
```

**Two code areas allocated at address 0x0000 with no error, no warning.** Adding `CSEG` alone does not fix it; the fix is `.area _CODE.main (REL,CON,CSEG,BANK=_CSEG)`, after which the areas concatenate correctly (`0000`, `0003`, `000D`, `0010`, `0013`).

Any per-function-section generator **must replicate the parent area's complete flag word and bank assignment**, and the linker should grow a diagnostic for same-named-prefix areas landing in different banks. Note also that `outarea()` (`asout.c:1505-1509`) only emits the `bank N` field when `A_BNK` is set, so the bank is genuinely absent from the object file, not merely defaulted.

### 4.4 ⚠ Scaling: the linker does not survive per-function sections today

Synthetic benchmark, 10 modules, Z80, `gcc -O2`:

| Configuration | Link, no map | Link + `-m` map | Map size |
|---|---|---|---|
| 10,000 symbols in **1** area (baseline) | — | **0.034 s** | 3,057 lines |
| 2,000 sections | 0.026 s | 0.30 s | 22,027 lines |
| 10,000 sections | 0.68 s | **10.7 s** | 110,027 lines |

Two separate quadratics:

- **Core linking**: 2,000 → 10,000 sections (5×) costs 0.026 s → 0.68 s (26×). `lkparea()` (`lkarea.c:301-334`) linearly scans the global area list for every `A` record.
- **Map generation**: ~10 s of the 10.7 s. `lstarea()` (`linksrc/lklist.c:406-466`) scans the *entire* symbol hash table once per areax to count symbols, then **again** to collect them, then bubble-sorts. It also emits a full paginated page per area — 11 lines per section.

Compounding this, the linker's symbol hash is only **64 buckets** (`aslink.h:180`) with a sum-of-characters hash (`lksym.c:555-574`) — pathological for machine-generated names sharing long prefixes. And `lnkarea()`/`lnksect()` synthesise **four** extra symbols per section (`a_`, `l_`, `m_`, `s_`), so 10,000 sections adds 40,000 symbols into 64 buckets.

At a realistic 2,000–5,000 functions this is tolerable (sub-second core link) but the map file is not. **Budget for fixing `lstarea()` and enlarging `NHASH` as part of this project, not as a follow-up.**

---

## 5. Proposed design

### 5.1 Collect the graph in pass 0

Change `lkmain.c:622-628` so that on `pass == 0` an `R` line is parsed for edges only (no `T` data required — the `R` line is self-describing):

```
R 00 00 <containing-area-index> ... { mode, rtp, index } ...
```

For each group: if `mode & R4_SYM`, edge to `s[rindex]`; else edge to `a[rindex]`. Store as a per-`areax` list of targets. Cost is one extra tokenised scan of the `R` lines; memory is one small node per relocation.

Note this must be done for **both** object versions — `relr3()` (`lkrloc3.c:283-363`) has the identical structure for V3 objects, which ASLink still accepts.

### 5.2 Mark and sweep between `search()` and `setarea()`

The insertion point is `lkmain.c:318-322`, after library resolution and before any address is assigned. This ordering matters: `lnksect()` mutates `taxp->a_size` by folding in boundary padding (`lkarea.c:538`), so it must run exactly once, after the sweep.

- **Mark**: worklist from the root set; a symbol edge marks `sym->s_axp`; an area edge marks the areax directly.
- **Sweep**: flag unmarked areax as dead (new field in `struct areax`).
- `lnksect()` skips dead areax for address/size accumulation, but **must keep the `m_<area>_n` / `s_<area>_n` counter `i` advancing** so those generated names stay stable across a GC/no-GC build.
- Symbols whose `s_axp` is dead get `s_flag = 1` so they vanish from the map, NoICE and SDCDB output.

### 5.3 Suppress output in pass 1

In `relr4()`/`relr3()`, once the containing areax is known (`lkrloc4.c:334`), if it is dead: skip the `lkout(1)` at `lkrloc4.c:862-864` and suppress relocation range errors (a dead section's relocations may now be out of range and the diagnostics would be noise). `relp4()` must also cope with a `.setdp` page pointing at a dead areax (`lkrloc4.c:1016-1017`).

**`lkulist()` must still be called** (`lkrloc4.c:859-861`). The `.lst` → `.rst` translation consumes the listing file strictly sequentially (`getlst()`, `linksrc/lklist.c:1282-1310`), one byte position at a time driven by the `T` data. Skipping a dead section entirely desynchronises the listing stream for everything after it. The dead section's lines must still be consumed and emitted, ideally marked as removed.

### 5.4 Roots

The linker has **no entry-symbol option** — `-e` already means "end of input". Scanning the option parser (`lkmain.c:880-1030`), **`-r` is the only free letter** in the single-character namespace; `-m1` sets the precedent for sub-options (`-rk`, `-rg`, …).

Proposed default root set:

- All `ABS` areas (fixed addresses — vector tables live here and must never be collected).
- Any area named in a `-a area=expr` base option (the user explicitly placed it).
- Any symbol named in a `-g symbol=expr` option.
- Explicit `-r <symbol|area>` roots.
- **Anything referenced via a linker-generated area symbol** — see §6.1.

If no roots are supplied, error out rather than collecting everything or nothing.

### 5.5 A `KEEP` attribute (optional, later)

Three flag bits in the V4 area flag word are unallocated: `0x0020`, `0x0200`, `0x2000`. `newarea()` (`lkarea.c:209-211`) stores the whole word on first sight and only merges specific masks thereafter, so an older linker would carry an unknown bit harmlessly. A `.area X (KEEP)` attribute is therefore forward- and backward-compatible. This is a nice-to-have, not a prerequisite.

---

## 6. Gotchas

Ordered roughly by how likely they are to sink the project.

### 6.1 ⚠⚠ Linker-generated area symbols break liveness (demonstrated)

`lnkarea()` (`lkarea.c:459-473`) creates `a_<areaname>` and `l_<areaname>` and explicitly sets `sp->s_axp = NULL`; `lnksect()` does the same for `m_<area>_n` / `s_<area>_n`. These are the standard crt0 handles for "copy initialised data from ROM to RAM".

Confirmed from an actual `.rel`:

```
S a__INIT Ref0000
S l__INIT Ref0000
A _INIT size 4 flags CD80 bank 0
```

The reference to `_INIT` is an ordinary **undefined external symbol reference**, and the symbol that satisfies it has **no areax back-link**. A naive collector sees `_INIT` as referenced by nothing and deletes it — silently producing a binary whose initialised data is gone. Every `_INIT`/`_INITIALIZER`/`_INITIALIZED` idiom is affected.

**Mitigation**: before marking, scan all *undefined* symbol references for names matching `a_*`, `l_*`, `s_*_<n>`, `m_*_<n>` and root every areax of the named area. This is a name-pattern hack and it will have false positives on user symbols that happen to start with `l_`; it needs to be documented, and probably gated so that a collision produces a warning.

### 6.2 ✅ Where per-function sections come from — *answered*

This was the open question that determined whether the project was worth doing. It now has an answer: **SDCC**, via the in-progress port of current ASxxxx into SDCC in place of `sdas`/`sdld`.

That matters because SDCC's code generator already knows exactly where each function begins and ends, and already chooses the area each function and each variable lands in. Emitting one area per function is a change to *what text SDCC writes*, not a change to any analysis it performs.

For completeness, the alternatives that were on the table and are now secondary:

- **Hand-written assembly** — one `.area` per function. Still supported, still mechanical, and every `.area` must replicate the parent's full attribute set (§4.3) or you get silent overlap.
- **An assembler option that auto-splits at global labels** — tempting and **dangerous**. It silently breaks fallthrough between adjacent labels, mis-handles interleaved jump tables and data, and cannot know whether a label is a function entry or a loop target. Auto-splitting remains a correctness hazard, not a convenience, and should not be built.
- **`.function` / `.endfunc` directives** — still worth having eventually for hand-written code, but no longer on the critical path, and no longer worth 56 `*pst.c` edits up front.

§7 covers what taking SDCC as the client actually costs and requires.

### 6.3 ⚠⚠ Map file generation is unusable at section scale

Measured in §4.4: 10 s of a 10.7 s link, and a 110,000-line map. `lstarea()` needs an index (areax → symbol list) built once instead of two full hash-table sweeps per area, the bubble sort needs to become `qsort`, and the map needs a compact mode that does not paginate one page per section. Non-negotiable if per-function sections are the target.

### 6.4 ⚠ Fallthrough and reachability that the linker cannot see

The relocation graph is sound for anything the assembler emitted a relocation for. It cannot see:

- **Fallthrough** from one function into the next. Splitting into areas already breaks this regardless of GC; GC makes it worse by reordering and removing.
- **Computed targets** — jump tables built by arithmetic, dispatch via index into a table of offsets rather than addresses, self-modifying code.
- **Data reached by pointer arithmetic** from a neighbouring symbol (`tbl+4` where `tbl` and the target are separate sections).
- **Hardware-invoked entry points** — interrupt handlers whose addresses are placed by the hardware, not by a relocation. If the vector table is in an `ABS` area it roots them naturally; if it is built some other way, it will not.

These are the same failure modes as `ld --gc-sections`, and like there, `KEEP`/`-r` is the only answer.

### 6.5 ⚠ Layout changes have second-order effects on this class of target

Removing sections changes every subsequent address. On 8-bit targets that is not cosmetic:

- **PC-relative range**: `R4_PCR*` modes range-check at link time (`lkrloc4.c:764-777`). GC can move a branch target out of range that previously fit — or fix one that did not. Errors will appear and disappear as unrelated code changes.
- **Paged areas**: `PAG` areas are checked for a 256-byte boundary and length (`lkarea.c:524-528`, `576-580`). GC shifts them.
- **Direct-page / `.setdp`**: `R4_PAGN` checks the target against `sdp.s_addr` (`lkrloc4.c:786-792`). A `.setdp` naming a collected area is now meaningless.
- **`OVR` areas**: overlaid areas size to the largest contributor. Collecting the largest one shrinks the overlay — correct, but surprising if anything else assumed the size.

### 6.6 ⚠ Library extraction happens before liveness is known

`search()` (`linksrc/lklibr.c`) iterates the symbol table pulling library modules for *any* undefined symbol, including references from sections that GC will later delete. `fndsym()` reads library members by scanning `S` records for `Def`.

The outcome is **sound but suboptimal**: a module extracted to satisfy a reference that later dies will have all of its own sections collected, so it contributes nothing to the image — but the file I/O and symbol-table growth already happened, and it may transitively have pulled in further modules (also dead, also wasted). GNU `ld` has the identical phase ordering. Iterating extraction and marking to a fixed point is possible but is a significant restructuring of `search()`; not worth it for a first version.

### 6.7 ✅ Name length and generated-name buffers — *fixed on `master`*

`NCPS` was **80** in the linker (`aslink.h`) but **256** in the assembler (`asxxsrc/asxxxx.h:134`), and both `getid()` implementations truncate silently at `NCPS-1`. The assembler therefore wrote names up to 255 characters into the `.rel` file and the linker read back only the first 79 of each, collapsing any two names that shared a long prefix.

Both outcomes were reproduced:

- **Benign** — two globals differing only after their 92nd character produce a spurious `?ASlink-Error-Multiple definition of …`.
- **Silent and damaging** — where the colliding names are a *definition* in one module and a *reference* in another, the truncated reference matches the truncated definition, `symdef()`'s undefined-symbol check never fires, and the call binds to a different function. Two modules, one defining `<92-char prefix>alpha` and the other calling `<92-char prefix>beta` which nothing defines: the linker exited **0 with no diagnostic** and emitted `CD 03 00` — a call to `…alpha`.

Fixed by raising the linker's `NCPS` to 256 (`d5e2177`). The undefined symbol is now correctly reported by its full name.

Investigating that turned up a second, independent defect in the same code. `lnkarea()`/`lnksect()` build their generated names with `sprintf(temp, "m_%s_%u", tap->a_id, i)` into `char temp[NCPS+2]` — 82 bytes, sized for a prefix plus an area name but not for the `_<n>` section index appended after it. A single `.area` directive with a maximum-length name overflows it. Confirmed under AddressSanitizer:

```
ERROR: AddressSanitizer: stack-buffer-overflow
WRITE of size 84 at 0x7e6a36100e72
  #3 in lnksect linksrc/lkarea.c:560
'temp' (line 519) <== Memory access at offset 114 overflows this variable
```

Fixed by introducing `NGSYM` (`NCPS + 16`, documented against the four format strings that write into it) and using it for both `temp[]` buffers and for `token1[]` in `DefineNoICE()`, which has the same append-after-`sscanf` shape (`5c1a749`).

**Still open:** truncation itself is not diagnosable. A name beyond 255 characters is still silently clipped — identically by both tools now, so it no longer *diverges*, but two such names would still merge. A hard error on truncation remains worth adding.

`.`, `$` and `_` are `LETTER` in the linker's `ctype[]` (`lkdata.c:604-615`) so they are safe in generated names. `-` is `BINOP` and is *not* — note `getsymid()` was added specifically so `S` records could carry `-`, but `getid()` (used for area names) still cannot.

### 6.8 Debug output consumers

`lknoice.c` and `lksdcdb.c` emit symbol addresses. Symbols in collected sections must be suppressed, or debuggers will resolve names to addresses now occupied by unrelated code. `SDCDBcopy()` copies `.adb` files verbatim and has no notion of a removed section at all.

### 6.9 Two relocation implementations, both V3 and V4

`lkrloc3.c` (1,065 lines) and `lkrloc4.c` (1,828 lines) both need the pass-0 edge collection and the pass-1 output suppression. They are structurally parallel but not shared code. ASLink is documented as supporting 3.xx and 4.xx objects and that promise should not quietly lapse.

### 6.10 There is effectively no regression test coverage

`asxmak/linux/misc/lnx_tstscn` assembles a handful of files per target and runs `asxscn` over the `.lst` output. There are no golden outputs, no automated comparison, and **no linker tests at all**. A change that touches address assignment, relocation output, and listing generation across 56 targets with no regression harness is the single largest schedule risk in this project.

**No collector code should be written before a golden-file link regression suite exists.** With SDCC as the client this is much cheaper than it looks — SDCC's own regression suite supplies exactly that coverage once the port runs, so the sequencing answer is "port first, collector second" (§7.7).

### 6.11 Smaller items

- **Empty areas proliferate.** Every module emits `A _CODE size 0` and `A _DATA size 0` even when unused (visible in §4.2). Harmless, but multiplies the areas the linker walks.
- **Area index is 16-bit** (`out_rw()`), capping a single module at 65,535 areas. Not a practical limit.
- **Area order becomes declaration order.** With per-function areas, link-time layout follows the order areas were first seen. Anything relying on area adjacency or on a specific concatenation order will move.
- **`sdp` defaults to the first area seen** (`lkmain.c:610-614`). If that area is collected, the default direct page is dangling.
- **`-u` listing relocation** must be kept in sync as described in §5.3, or every `.rst` file after the first collected section is garbage.

---

## 7. The SDCC client

Taking SDCC as the consumer answers the granularity question but adds a second work stream and a distinct set of hazards. Everything in this section is specific to that pairing.

### 7.1 What SDCC has to emit — and what it does *not* need

The natural shape mirrors GCC: `--ffunction-sections` and `--fdata-sections` driver options that change area emission, plus passthrough of the new linker flag.

An important simplification: **the assembler needs no new options at all.** SDCC does not ask the assembler to split anything — it writes `.asm` text and the assembler obeys the `.area` directives it finds. So the entire section-granularity feature lives in SDCC's emitter plus one new ASLink flag. That removes the 56 `*pst.c` pseudo-op table edits from the critical path entirely.

Where the work lands in SDCC:

- **Code sections.** The code area is emitted once per module during glue; per-function areas mean emitting a fresh `.area` at each function boundary instead. The function prologue/epilogue emitters are per-port, so this is either one central hook at the point functions are flushed to the output, or a touch in each port's function emitter. Worth deciding deliberately — a central hook is the difference between one change and roughly fifteen.
- **Data sections.** The regular-map emitter walks each memory map and writes one `.area` followed by every symbol in it. Per-variable areas mean emitting a fresh `.area` per symbol. This is far more centralised than the code side and is the cheaper half.
- **Driver passthrough.** The link command is assembled in the SDCC driver; the new ASLink flag and the root specifications go there.

**Every generated `.area` must carry the parent area's complete attribute set** — including the bank assignment (§4.3). SDCC already tracks the code segment name (`--codeseg`), the const segment (`--constseg`) and banked-code naming, so the prefix must come from those rather than a hardcoded `_CODE`.

### 7.2 ⚠⚠ `_GSINIT` is a fallthrough chain, not a call graph

SDCC's global initialisation is not a function that calls other functions. Each module contributes a fragment to a shared init area and **control falls straight through from one module's fragment into the next**, terminating in a final fragment that returns.

This breaks both halves of the feature at once:

- **Splitting** an init area into per-function sections would let the linker reorder the fragments. There is no relocation expressing "this fragment must be followed by that one", so nothing prevents it.
- **Collecting**, even without splitting, will drop any fragment nothing references — which is *all* of them, since they are reached by fallthrough rather than by a call.

**Mitigation:** the init areas must be excluded from splitting *and* hard-rooted, not left to the general root heuristic. This is the strongest argument for building the `KEEP` area attribute (§5.5) as part of Stage 1 rather than deferring it — SDCC can mark these areas at emission time and the question disappears. The same applies to any other area SDCC relies on the linker concatenating in emission order.

### 7.3 ⚠⚠ Debug output rides the map-file quadratic

`DefineSDCDB()` and `DefineNoICE()` are both called from inside `lstarea()` (`linksrc/lklist.c:591,598`) — the O(areas × symbols) function measured at ~10 s for 10,000 sections in §4.4. Worse, `SDCDBfopen()` **forces `mflag = 1`**, so requesting `.cdb` debug output turns map generation on whether or not the user wanted a map.

Consequence: with SDCC, **every debug build pays the quadratic**, and per-function sections make it the dominant cost of linking. §6.3 was already non-negotiable; this makes it a prerequisite for the SDCC port on its own merits, independent of whether GC is ever implemented.

### 7.4 ✅ `aslink -y` hung on every SDCC symbol — *found here, fixed on `master`*

Unrelated to GC, but directly on the SDCC port's path. In `DefineSDCDB()` (`linksrc/lksdcdb.c`):

```c
j = 0;
p1 = name;
while ((p1 = strchr(p1, '$')) != NULL) {
        j += 1;
}
```

`p1` is never advanced past the match, so `strchr()` returns the same position forever. The comment immediately above it reads *"SDC symbols have 3 or more $ characters"* — so the loop hangs on precisely the input it was written to handle.

Reproduced: assembling a symbol named `F$main$0$0` and linking with `-y` spins indefinitely (killed at a 10 s timeout). The fix is one line:

```c
while ((p1 = strchr(p1, '$')) != NULL) {
        p1 += 1;
        j += 1;
}
```

**Fixed on `master`** — commit `5356e4c`, merged as `883f305`. Verified across the decision boundary (symbols with 0, 1, 2, 3 and 4 `$` characters): the link completes, the `.cdb` contains exactly the two names with three or more `$` and none below the threshold, output without `-y` is byte-identical before and after, the `asz80` `tz80`/`t80` self-tests produce byte-identical `.lst`/`.rst`, and an ASan/UBSan build reports nothing. A grep of `linksrc/` and `asxxsrc/` found no other instance of the same loop shape.

### 7.5 ⚠ ASxxxx and sdld have diverged where it matters

The port will hit these regardless of GC, but each one also constrains the collector's design:

- **Option letters.** In current ASxxxx, `-a` sets an *area* base address and `-b` sets a *bank* base. SDCC's driver emits `-b <area> = <addr>` for `--code-loc` / `--data-loc`, which in this linker is a bank base — confirmed here, where `-b _CODE=0x0200` fails with `?ASlink-Error-No definition of bank _CODE`. Either the driver's emission or the linker's option mapping must be reconciled, and whichever way it goes determines which option the collector treats as an "explicitly placed, therefore rooted" area (§5.4).
- **Linker-generated area symbols.** This tree generates `a_<area>` for an area's start address and `l_<area>` for its length (`lkarea.c:459-473`), reserving `s_<area>_<n>` for the start of an individual *section* within the area (`lkarea.c:567`). SDCC crt0 code conventionally references `s__INITIALIZER` / `s__INITIALIZED` / `l__INITIALIZER` — i.e. `s_` for an area start, which in ASxxxx means something else. **Verify this against the port before relying on it**, but if it holds, the `s_` prefix is doing double duty and the rooting heuristic in §6.1 must handle both meanings without conflating them.

Good news on the naming front: `$`, `.` and `_` are all `LETTER` in the linker's character table (`lkdata.c:604-615`), so SDCC-style mangled names are safe inside generated *area* names. `-` is not.

### 7.6 ✅ Name length — *mismatch fixed; is 256 enough?*

§6.7 covers the defect and its fix. What remains is the sizing question: **is 256 the right number for an SDCC-driven toolchain?**

**What ISO C actually requires.** The translation limits in §5.2.4.1 are *minimum capacities a conforming implementation must provide*, not caps on identifier length:

| Standard | Internal identifiers / macro names | External identifiers |
|---|---|---|
| C89 / C90 | 31 significant characters | **6**, and case need not be significant |
| C99 | 63 significant characters | **31** significant characters |
| C11 / C17 | 63 | 31 |
| C23 | 63 | 31 |

So a strictly conforming program may not rely on more than **31 significant characters in an external identifier** — the only class that reaches a linker at all. Nothing in the standard sets an upper bound; implementations are free to make every character significant, and in practice GCC, Clang and SDCC all do. The numbers above are a floor, not a ceiling, and no real toolchain has treated them as a limit for decades.

**Is 256 enough?** For C identifiers, comfortably — it is roughly 8× the external-identifier minimum, and longer than any hand-written C function name is likely to be.

But C identifiers are not the binding constraint here. The names that will actually approach the limit are the ones the toolchain *generates*, where several components are concatenated:

```
<segment prefix> _ <module name> _ <function name>
```

A file-scoped static qualified with its module name, under a user-set `--codeseg`, in a banked build, is where the length accumulates. 256 still leaves generous headroom for that — a 32-character segment prefix, a 64-character module name and a 96-character function name together come to under 200 — but it is worth confirming against the port's actual mangling scheme rather than assuming, particularly if any scheme ever qualifies further (nested scopes, block indices, inlining suffixes).

The residual risk is not the number, it is that overrunning it is **silent**. That is why the open item in §6.7 — a hard error on truncation — matters more than the choice between 256 and 512. With a diagnostic in place, an under-sized `NCPS` is a build failure someone fixes in a minute; without one, it is a call quietly bound to the wrong function.

### 7.7 What SDCC gives back: a real test harness

§6.10 identified "no linker regression coverage exists" as the largest schedule risk. SDCC ships a substantial regression suite that builds and links thousands of test programs across many targets and checks their runtime behaviour under simulation.

Once the port is working, that suite becomes exactly the golden-file linker harness this project needs, and it exercises paths — banking, overlays, debug output, `--code-loc` — that no hand-written test set would cover. **This materially reduces the Stage 0 cost** and is a strong argument for sequencing the port ahead of the collector.

### 7.8 Fork maintenance, stated plainly

The SDCC project will not accept AI-assisted contributions, so this lives as a private fork. Two practical consequences worth planning around, neither of them a reason not to proceed:

- Divergence between the fork and upstream SDCC accumulates in exactly the files most likely to change — the per-port code emitters and the driver's link-command assembly.
- The ASxxxx-side changes (the `-y` fix, `NCPS`, the `lstarea()` rewrite) are genuine bug fixes with no AI-specific character to them. They are separable from the GC feature and could be upstreamed to ASxxxx on their own merits if desired.

---

## 8. Effort estimate

### 8.1 Fix first — needed by the SDCC port whether or not GC happens

| Work item | Files | Rough size |
|---|---|---|
| ~~**`-y` infinite loop** (§7.4)~~ | `lksdcdb.c` | ✅ **done** — `5356e4c` |
| ~~`NCPS` 80 → 256~~ (§6.7, §7.6) | `aslink.h` | ✅ **done** — `d5e2177` |
| ~~`lnksect()` generated-name buffer overflow~~ (§6.7) | `aslink.h`, `lkarea.c`, `lknoice.c` | ✅ **done** — `5c1a749` |
| Hard error on identifier truncation (still open, §7.6) | `lklex.c`, `aslex.c` | ~30 lines |
| **`lstarea()` de-quadratication + compact map** (§6.3, §7.3) | `lklist.c` | ~200 lines |
| `NHASH` enlargement + better hash | `lksym.c`, `aslink.h` | ~20 lines |
| Reconcile `-a`/`-b` against the SDCC driver (§7.5) | `lkmain.c` or driver | small, but decide deliberately |

### 8.2 The linker-side collector

| Work item | Files | Rough size |
|---|---|---|
| Link regression coverage | SDCC regression suite (§7.7) | mostly *free* once the port runs |
| Pass-0 edge collection (V4) | `lkrloc4.c`, `lkmain.c` | ~120 lines |
| Pass-0 edge collection (V3) | `lkrloc3.c` | ~100 lines |
| Mark/sweep + root handling | new `lkgc.c`, `aslink.h` | ~350 lines |
| `lnksect()` dead-section skipping | `lkarea.c` | ~40 lines |
| Pass-1 output + listing suppression | `lkrloc3.c`, `lkrloc4.c`, `lklist.c` | ~150 lines |
| Root options + `KEEP` area attribute + usage text | `lkmain.c`, `lkarea.c` | ~110 lines |
| Map/NoICE/SDCDB suppression for dead sections | `lklist.c`, `lknoice.c`, `lksdcdb.c` | ~80 lines |
| `--print-gc-sections` equivalent | `lkgc.c`, `lkmain.c` | ~60 lines |
| Documentation (`asmlnk.txt` is 32,471 lines) | `asxdoc/` | non-trivial |

Roughly **1,000 lines** across 8 files — a genuinely bounded change to a 15,000-line program, and encouragingly localised. Note `KEEP` has moved from "nice to have" into this table: §7.2 makes it a requirement, not a convenience.

### 8.3 The SDCC side

| Work item | Where | Rough size |
|---|---|---|
| `--ffunction-sections`: emit one code area per function | function emitter — **one central hook, or ~15 per-port edits** | decide this first |
| `--fdata-sections`: emit one area per variable | the regular-map emitter (centralised) | small |
| Attribute/prefix inheritance from `--codeseg`/`--constseg`/banking (§7.1) | area-name construction | small, fiddly |
| Mark init areas `KEEP` and exempt from splitting (§7.2) | glue/init emission | small, **essential** |
| Driver passthrough of the new link flag and roots | link-command assembly | small |
| Mark ISRs and `__at` functions as roots | function emitter | small |

**No assembler changes are needed** (§7.1). The `.function`/`.endfunc` directives and their 56 `*pst.c` table edits drop out of scope entirely unless hand-written assembly later wants the same ergonomics.

The single sizing question that dominates this column is whether the per-function `.area` can be emitted from one shared point in the code generator or has to be repeated in each port's function emitter.

---

## 9. Recommendation

**Worth doing.** The decision gate that dominated the first draft of this study — *who emits per-function areas?* — is answered by the SDCC port, and the answer is a good one: a real code generator that already knows function boundaries, driven by GCC-style `--ffunction-sections` / `--fdata-sections` options.

Sequence it so that each stage is independently useful and none of them is wasted if the next is abandoned.

- **Stage 0 — the `-y` hang.** ✅ **Done** — `5356e4c`, merged as `883f305` (§7.4). One line. It blocked the SDCC port outright and had nothing to do with GC.

- **Stage 1 — make the linker fit for SDCC.** `NCPS` ✅ and the generated-name buffer overflow ✅ are done (`d5e2177`, `5c1a749`); what remains is a hard error on truncation (§7.6), the `lstarea()` quadratic and compact map (§6.3), `NHASH`, and the `-a`/`-b` reconciliation (§7.5). All of it is needed by the port whether or not GC ever ships, and the map quadratic is on the critical path for *every SDCC debug build* because `.cdb` generation runs inside `lstarea()` (§7.3). None of this commits you to the feature.

- **Stage 2 — get the port running and inherit the test suite.** SDCC's regression suite becomes the golden-file linker harness that §6.10 says does not exist, covering banking, overlays, debug output and `--code-loc` far better than anything hand-written (§7.7). This is the single biggest risk reduction available, and it costs nothing extra.

- **Stage 3 — the collector.** Opt-in flag, default off, V4 objects only, roots explicit and required. `KEEP` ships *with* it rather than after, because SDCC's init-area fallthrough requires it (§7.2). Include `--print-gc-sections` from day one — without it, debugging what got eaten and why is guesswork.

- **Stage 4 — SDCC-side sections.** `--ffunction-sections` first (the larger, per-port-shaped change), `--fdata-sections` second (centralised and cheaper). Decide the central-hook-versus-fifteen-ports question before writing code.

- **Stage 5 — ergonomics.** V3 object parity, and `.function`/`.endfunc` if hand-written assembly ever wants the same treatment.

Two closing observations.

The encouraging one is §4.2: the V4 `.rel` format, designed decades before anyone said "gc-sections", already encodes a sound and complete section reference graph, resolved per-section by relocation records that were written for an entirely different purpose. Nothing in the object format needs to change. That is unusual, and it is the strongest technical argument for doing this.

The cautionary one has moved. It is no longer "nothing produces fine-grained sections" — SDCC will. It is that **the failure modes here are silent**: truncated area names that merge (§7.6), missing bank attributes that overlap at address zero (§4.3), init chains collected because nothing calls them (§7.2), initialised data deleted because its only reference is a linker-generated symbol (§6.1). None of these produce a diagnostic; all of them produce a binary that links cleanly and misbehaves on hardware. Budget the verification effort accordingly, and treat `--print-gc-sections` and the truncation error as load-bearing safety features rather than polish.
