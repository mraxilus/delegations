## Write `to<Target>` call of compound argument as prefix call, as STYLE.md §5 gives
##   (`toMultivector(a + b)`, never `(a + b).toMultivector`), and fix it (`koch fix`).
##   Check reports nothing and fixer writes nothing yet: rule 15 of #443 lands in its build.

{.experimental: "strictFuncs".}

import ./reports


func checkPrefixes*(path, source: string): seq[Report] =
  ## Report each `to<Target>` call written by dot after compound argument (STYLE.md §5).
  discard


func fixPrefixes*(path, source: string): Fix =
  ## Write each call check reports as prefix call, where fixer reaches it.
  Fix(source: source)
