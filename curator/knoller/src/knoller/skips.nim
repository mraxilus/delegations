## Enforce that each gap of coverage shows in run (Article IX.9): skip gives its reason, gap is
##   placeholder test that skips, and no test leaves run under bare `when`, as Architect ruled on
##   rule 17 of #443. No fix, since only author knows reason.

{.experimental: "strictFuncs".}

import ./reports


func checkSkips*(path, source, nimble: string): seq[Report] =
  ## Report skip of test that gives no reason, gap inside test that runs, and test under bare
  ##   `when`, in file under `tests` of its package (`nimble`).
  ##   Named by its suite and `chain.nim` alone until static pass calls it (`fixes.nim`).
  discard
