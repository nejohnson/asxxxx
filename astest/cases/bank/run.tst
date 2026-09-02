# bank -- five banks, each with its own file suffix.
#
# The source is copied in under a five character base:  a bank suffix
# is appended to the output file's base name, so bankfile_C1.hex would
# be eleven characters and break an 8.3 name.
#
# Each populated bank must produce its own hex file, and the unbanked
# area must land in the base one.
#
# CODE1 is declared 'size = 8' and the area in it is larger, so the
# link is expected to fail:  chkbank() reporting that overflow is part
# of what this source tests.  The output files are still written.
name    Banks with file suffixes, one output file per bank
asm     -gloaxwf bnkf
expect  2
link    -mxiu ; bnkf
gold    bnkf.map
goldbin bnkf.hex
goldbin bnkf_C1.hex
goldbin bnkf_D1.hex
goldbin bnkf_C2.hex
goldbin bnkf_D2.hex
goldbin bnkf_S.hex
