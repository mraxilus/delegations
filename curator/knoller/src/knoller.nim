## Fix Nim source from its text alone, as `koch fix` asks; library umbrella.
##   Package holds fixers whose rule reads one file and nothing else, and checks they clear;
##   fixers asking compiler stay in `curator/audit`, which reaches this umbrella by relative
##   import, as `koch.nim` reaches audit.
##   Every import stays inside `src/`, so package requires compiler alone
##     (`tests/suites/test_imports.nim`).
##   Cost: koch compiles this package, so its pin is `curator/audit` pin.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import ./knoller/[form, reports, rules, spacing, tokens, views]

export form, reports, rules, spacing, tokens, views
