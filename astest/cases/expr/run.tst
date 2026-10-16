# expr -- link time expression evaluation.
name    Link time expression evaluation
src     ascheck/expr
asm     -pxloff expr
link    -mux ; -g cc=0xAB ; -g two=2 ; expr
scan    -i expr.rst
gold    expr.map
