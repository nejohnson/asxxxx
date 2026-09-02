# equtst -- .equ against link time globals.
name    Assembler .equ against link time globals
src     ascheck/equtst
asm     -loxff equtst
link    -mx ; equtst
gold    equtst.map
