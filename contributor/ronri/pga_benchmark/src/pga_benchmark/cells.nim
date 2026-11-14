## Read Cayley table as JSON, cell by cell, so evaluation compares tables across library versions.
##   Evaluation's `tables` claim compiles one program against library at pin and one against changed
##     copy; each prints tables through this module, and equal JSON is equal table, signs
##     included. Suites run same module against pin, so serialiser evaluation relies on is tested.
##   Cell is `seq` in every table at pin; library before `3121342` held `Option[BasisSigned]` in
##     1D ones, and P12 holds terms in place beside their count. `toTerms` reads `Option`, and any
##     other cell it can iterate, so one module serves change that brings any of these shapes.
##
##   Cost: serialiser walks every cell, N² for 2D table; 6D is 4 096 cells, milliseconds.

{.experimental: "strictFuncs".}

import std/[json, options]

import pga/[algebra {.all.}, cayleys {.all.}]


func term(b: BasisSigned): JsonNode =
  ## Build one term: basis it lands on and its sign.
  %*{"to": $b.basis, "neg": b.is_negated}


func toTerms[C](c: C): JsonNode =
  ## Read one cell, `Option` or any cell with `items`, as array of terms.
  result = newJArray()
  when C is Option:
    if c.isSome: result.add term(c.get)
  else:
    for b in c: result.add term(b)


func cells*[T](table: T): JsonNode =
  ## Read 1D or 2D table as object from cell key to its terms; empty cells left out.
  result = newJObject()
  for a in Basis:
    when table[a] is array:
      for b in Basis:
        let terms = toTerms(table[a][b])
        if terms.len > 0: result[$a&"," & $b] = terms
    else:
      let terms = toTerms(table[a])
      if terms.len > 0: result[$a] = terms
