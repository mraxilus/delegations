## Fix Nim source from its text alone, as `koch fix` asks; library umbrella.
##   Package holds fixers whose rule reads one file and nothing else, and checks they clear;
##   fixers asking semantic pass of compiler stay in `curator/audit`, which reaches this
##   umbrella by relative import, as `koch.nim` reaches audit. Parser of compiler proves each
##   needless group out of process (`proofs.nim`), and caller passes it in, so chain stays pure.
##   Pin of nimble file (`pins.nim`), and compiler serving it, from PATH, cache or fetch
##     (`compilers.nim`), live here too: koch and command line each take compiler of pin, and
##     audit imports knoller, never reverse.
##   Every import stays inside `src/`, so package requires compiler alone
##     (`tests/suites/test_imports.nim`).
##   Command line, `knoller [--check] [--nim:path] path...`, lives in `command.nim`; umbrella
##     runs it as program and exports none of it, since library caller needs none.
##   Cost: koch compiles this package, so its pin is `curator/audit` pin.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import ./knoller/[
  articles, blanks, chain, command, commands, compilers, declarations, declared, entry, fences,
  form, idioms, messages, parentheses, pins, precedence, proofs, reports, rules, spacing, targets,
  tokens, views, wrapping,
]

export
  articles, blanks, chain, commands, compilers, declarations, declared, entry, fences, form, idioms,
  messages, parentheses, pins, precedence, proofs, reports, rules, spacing, targets, tokens, views,
  wrapping


when isMainModule:
  quit main()
