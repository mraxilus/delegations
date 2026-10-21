## Carry projections `pga` has withdrawn, spelled as library itself defines them.
##
## Transitional, and states its own end. At pinned pga head `projectCentral`,
## `projectCentralAnti`, `projectOrthogonal` and `projectOrthogonalAnti` are declared
## `{.error.}` while their compound operator forms (`∨∧★`, `∧∨★`, `∨∧☆`, `∧∨☆`) are built,
## so calling one is compile error rather than absent symbol. Project follows library's head
## rather than waiting behind it, and two of these four are operations its catalogue offers,
## so bodies stand here until library's own return.
##   Each body is definition pga's own operator table gives, in that table's notation, read
##   from pinned tree rather than derived here. Nothing is invented: reimplementing library
##   this project exists to exercise would defeat it (Article II.8), and copying four
##   documented expressions across is not that.
##   Guard below refuses to compile once pinned pga carries its own, so stand-in can never
##   quietly shadow real thing, and moving pin is what removes this module.
##   Templates rather than funcs: expansion adds no call to output, and kind itself says
##   stand-in rather than home.
##
## Seam, so caller imports this instead of `pga` and reaches both. Importing both raises
## ambiguous call on these four names — never silently wrong answer.
##   Callers today: `scene`, `tessellate`, `interaction`, and suite. Every other module
##   imports `pga` directly, since none calls projection.

{.experimental: "strictFuncs".}

import pga
export pga except
  projectCentral, projectCentralAnti, projectOrthogonal, projectOrthogonalAnti



#[ Withdrawal ]#

const HAS_OWN_PROJECTIONS = compiles((block:
  var m: Multivector
  discard pga.projectOrthogonal(m, m)))
  ## Report whether pinned pga carries own projection bodies, i.e. whether module is spent.
  ##   Read through qualified call, since `except` above hides name from plain scope.

when HAS_OWN_PROJECTIONS:
  {.error: "pga at this pin defines its own projections; delete `projections.nim` and " &
    "put `import pga` back in `scene`, `tessellate`, `interaction` and `tests/suites`.".}



#[ Projections ]#

template projectCentral*(m, n: Multivector): Multivector = n ∨ (m ∧★ n)
  ## Project `m` centrally onto `n`, i.e. 𝐧 ∨ (𝐦 ∧ 𝐧★).

template projectCentralAnti*(m, n: Multivector): Multivector = n ∧ (m ∨★ n)
  ## Project `m` centrally onto `n` through antiproduct, i.e. 𝐧 ∧ (𝐦 ∨ 𝐧★).

template projectOrthogonal*(m, n: Multivector): Multivector = n ∨ (m ∧☆ n)
  ## Project `m` orthogonally onto `n`, i.e. 𝐧 ∨ (𝐦 ∧ 𝐧☆).

template projectOrthogonalAnti*(m, n: Multivector): Multivector = n ∧ (m ∨☆ n)
  ## Project `m` orthogonally onto `n` through antiproduct, i.e. 𝐧 ∧ (𝐦 ∨ 𝐧☆).
