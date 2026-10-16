# elfout -- .uleb128 and .sleb128, NOLOAD areas, and ELF output.
#
# The three things SDCC's --out-fmt-elf --debug needs from the tools
# for stm8 and hc08.  The DWARF it writes is LEB128 numbers in areas
# marked NOLOAD; those take no room in a bank, start at 0 on their
# own and stay out of the hex file; and the ELF file carries them as
# unallocated sections beside the program's loadable ones.
#
# .uleb128 -2 is five bytes, all 32 bits of 0xFFFFFFFE:  SDCC gives a
# negative CFA offset to .uleb128, and this is what SDAS writes.
#
# The first link checks the map and that the hex holds CODE alone;
# the second writes ELF with machine number 186, EM_STM8.
name    LEB128 numbers, NOLOAD areas and ELF output
tool    asst8
asm     -gloaxff elfout
link    -mxi ; -a CODE = 0x8000 ; elfout
gold    elfout.map
goldbin elfout.hex
link    -mx ; -a CODE = 0x8000 ; -e186+.elf ; elfout
goldbin elfout.elf
