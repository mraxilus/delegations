## Hold driver of verbs, `tools/build.nim`, to shape koch reads its verbs in: dispatch opens on
##   line `case paramStr(1)`, and names each verb koch reaches as branch `of "<verb>":` before
##   `else:` (`verbsDispatch` of `checker.nim` of curator, `CASE_DRIVER`). Koch learns from that
##   dispatch alone whether project carries `drive`, `head` or `system` (CONTRIBUTOR.md), so verb
##   it cannot read is one runner passes by in silence.
##   Case as found, 2026-11-11, on branch of live script: dispatch opened on `case arguments[0]`,
##     so koch read no verb of driver. `koch drive` drove nothing, and `koch list-packages` named
##     no package of project.
##   Reader below is copy of `verbsDispatch`, since project imports no module of curator; driver
##     is read as text it is, at compile time, and no line of it runs here.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[strutils, unittest]


const
  TEXT_DRIVER = staticRead("../../tools/build.nim")  ## Driver, as committed.
  OPENING_DISPATCH = "case paramStr(1)"  ## Line dispatch opens on (`CASE_DRIVER` of curator).
  MARK_BRANCH = "of \""  ## Opening of branch naming one verb (`MARK_DISPATCH` of curator).
  CLOSING_DISPATCH = "else:"  ## Line dispatch closes on (`CASE_END` of curator).
  VERBS_KOCH = ["drive", "head", "system"]  ## Verbs of driver koch reaches, each carried here.



func readVerbs(text: string): seq[string] =
  ## Read verbs driver dispatches as koch reads them: quoted label of each branch after line that
  ##   opens dispatch, till line that closes it.
  var is_inside = false
  for line in text.splitLines:
    let stripped = line.strip
    if stripped.startsWith(OPENING_DISPATCH):
      is_inside = true
      continue
    if not is_inside: continue
    if stripped == CLOSING_DISPATCH: break
    if not stripped.startsWith(MARK_BRANCH): continue
    let verb = stripped[MARK_BRANCH.len .. ^1].split('"')[0]
    if verb.len > 0 and verb notin result: result.add verb



suite "Internal: Driver":
  test "Driver dispatches each verb koch reaches, where koch reads dispatch":
    let verbs = TEXT_DRIVER.readVerbs
    checkpoint "verbs read: " & $verbs
    for verb in VERBS_KOCH:
      check verb in verbs  # `CASE_DRIVER` of curator, koch learns verb from dispatch alone
