# rl_chk -- two module relocation with an area base address.
#
# ascheck/reloc holds about fifty of these, one per CPU, none of them
# automated.  Written against ascheck instead, it needs no target.
name    Two module relocation with -a area placement
asm     -gloaxff rl
asm     -gloaxff xab
link    -mxu ; -a RELOC=0x1000 ; rl xab
gold    rl.map
