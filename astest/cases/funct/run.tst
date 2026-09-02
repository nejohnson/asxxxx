# funct -- .function / .endfunc.
#
# The point of the directive is that the area it opens carries the
# enclosing area's attributes and bank without them being retyped.
# The map golden is what pins that:  TEXT.main, TEXT.helper and
# TEXT.unused must all show (REL,CON,CSEG) and sit in bank CODE,
# exactly as TEXT does.  An area that quietly lost its bank would be
# placed in a different one and allocated over the top of it.
#
# tail is emitted after the last .endfunc and must land back in TEXT.
name    .function areas inherit the enclosing area's attributes
asm     -gloaxff fn
link    -mxu ; fn
scan    -i fn.rst
gold    fn.map
