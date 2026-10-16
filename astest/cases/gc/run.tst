# gc -- what the collector keeps and what it discards.
#
# TEXT.unused and TEXT.orphan must go;  the four that main reaches,
# directly or through a chain, must stay, and the map must show them
# at addresses that close the gap the discarded ones left.
name    Unreachable sections are discarded, reachable ones kept
asm     -gloaxff gc
link    -mxiu ; -r main ; gc
gold    gc.map
goldbin gc.hex
