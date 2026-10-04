## Fix Nim source from its text alone, as `koch fix` asks; library umbrella.
##   Package holds fixers whose rule reads one file and nothing else, and checks they clear;
##   fixers asking compiler stay in `curator/audit`, which reaches this umbrella by relative
##   import, as `koch.nim` reaches audit.
##   Every import stays inside `src/`, so package requires compiler alone
##     (`tests/suites/test_imports.nim`).
##   Command line, `knoller [--check] path...`, lives in `command.nim`; umbrella runs it as
##     program and exports none of it, since library caller needs none.
##   Cost: koch compiles this package, so its pin is `curator/audit` pin.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import ./knoller/[
  alignment, articles, blanks, chain, command, declarations, declared, entry, fences, form, idioms,
  messages, precedence, reports, rules, spacing, targets, tokens, views, wrapping,
]

export
  alignment, articles, blanks, chain, declarations, declared, entry, fences, form, idioms, messages,
  precedence, reports, rules, spacing, targets, tokens, views, wrapping


when isMainModule:
  quit main()
