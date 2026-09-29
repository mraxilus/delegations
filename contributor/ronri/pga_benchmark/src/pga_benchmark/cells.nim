## Read Cayley table as JSON, cell by cell, so trial compares tables across library versions.
##   Trial's `tables` claim compiles one program against library at pin and one against changed
##     copy; each prints tables through this module, and equal JSON is equal table, signs
##     included. Suites run same module against pin, so serialiser trial relies on is tested.
##   Cell shape differs between versions: `Option[BasisSigned]` in 1D tables at pin, `seq` in
##     2D ones and in every derived table. `cellOf` reads both, so one module serves each side.
##
##   Cost: serialiser walks every cell, N² for 2D table; 6D is 4 096 cells, milliseconds.

{.experimental: "strictFuncs".}

import std/[json, options]

import pga/[algebra {.all.}, cayleys {.all.}]


func termOf(b: BasisSigned): JsonNode =
  ## Shape one term: basis it lands on and its sign.
  %*{"to": $b.basis, "neg": b.is_negated}


func cellOf[C](c: C): JsonNode =
  ## Read one cell, `Option` or `seq`, as array of terms.
  result = newJArray()
  when C is seq:
    for b in c: result.add termOf(b)
  else:
    if c.isSome: result.add termOf(c.get)


func cells*[T](table: T): JsonNode =
  ## Read 1D or 2D table as object from cell key to its terms; empty cells left out.
  result = newJObject()
  for a in Basis:
    when table[a] is array:
      for b in Basis:
        let terms = cellOf(table[a][b])
        if terms.len > 0: result[$a & "," & $b] = terms
    else:
      let terms = cellOf(table[a])
      if terms.len > 0: result[$a] = terms
