## Hold size of cell to most terms any cell of products holds, as library carrying this change
##   exports it (`cayley-cells`).
##   Evaluation compiles this against library with change applied, at each algebra its claim
##     names, and exit code is verdict: law below holds, or compile stops on assertion.
##   `add` stops build where cell overflows, so every table fits its cells. Law holds size tight
##     too: some cell of ⟑ and of ⟇ holds `TERMS_CELL` terms, so smaller cell holds no table.
##   Under conformal metric 𝐞ₙ₋₁ ⟑ 𝐞ₙ = 𝐞ₙ₋₁ₙ − 𝟏 holds two terms; under rigid metric each
##     product of two bases holds one term or none.

{.experimental: "strictFuncs".}

import pga/[algebra, cayleys {.all.}]


static:
  for (name, table) in [("⟑", CAYLEYS_WEDGE_DOT.base), ("⟇", CAYLEYS_WEDGE_DOT.anti)]:
    var most = 0
    for m in Basis:
      for n in Basis: most = max(most, table[m][n].len)
    doAssert most == TERMS_CELL,
      "Most terms cell of " & name & " holds is " & $most & "; cell holds " & $TERMS_CELL & "."
