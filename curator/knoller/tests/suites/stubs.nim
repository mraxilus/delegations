## Stub parser of code's compiler for suites, so they run with no compiler: each candidate group
##   is proven but one `REJECTED` names, as commit pin of `ronri` projects answered each
##   (2026-10-05). `test_proofs.nim` holds ASCII verdicts to parser of 2.2.12 itself.
##   Group is named by text alone, so suite writing one text twice gets one verdict for both.

{.experimental: "strictFuncs".}

import std/[sequtils, tables]
import ../../src/knoller/[chain, parentheses, proofs, reports]


const
  REJECTED* = [
    "(1)",  # `-1` lexes one literal
    "(■m)",  # `■m.x` reads `■(m.x)`
    "(|∙ x)",  # after command head, `|∙` reads binary
    "(PAIRS[task.pair][0])",  # sigil `@` binds name before index (#539)
    "(x.items)",
    "(f(a))",
    "(x[0])",
    "(x[i])",
  ]
    ## Text of each group parser of commit pin reads otherwise without it.
  ASKS_MAX = 8  ## Rounds of asking at most, as `command.nim` takes.


func stubbed*(source: string): seq[int] =
  ## Answer source as stub parser: offset of `(` of each candidate group `REJECTED` does not name.
  source.candidatesOf.filterIt(it.got notin REJECTED).mapIt(it.opening[0])


func stubProver*(sources: seq[string]): Proving =
  ## Answer each source as stub parser, as compiler would in one run.
  Proving(answers: sources.mapIt(it.stubbed))


func failingProver*(sources: seq[string]): Proving =
  ## Answer as compiler that does not run: none proven, with failure.
  Proving(answers: newSeq[seq[int]](sources.len), failure: "Compiler ran no probe; got `x`.")


func stubProofs*(path, source: string; dialect: Dialect): Proofs =
  ## Answer source as given, and each source chain asks while it fixes source, by stub parser,
  ##   until chain asks nothing more.
  result.answers[source] = source.stubbed
  for ask in 1 .. ASKS_MAX:
    let asked = formatted(path, source, dialect, result).asked
    if asked.len == 0: break
    for each in asked: result.answers[each] = each.stubbed
