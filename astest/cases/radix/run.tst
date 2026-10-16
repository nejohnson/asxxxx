# radix -- -g SYM=expr in all four radices, and the User Global
# Definitions page of the map.
name    Link time -g globals in hex, decimal, octal and binary
src     ascheck/radix
asm     -loxff rad
link    -mux ; -g X=0x40 ; -g D=0d100 ; -g Q=0q40 ; -g B=0b100 ; rad
gold    rad.map
