## Compare static and machine measurements against their committed baselines; any count grown
##   is finding.
##   Gate is monotone: growth in any gated count or in bytes moved fails, shrink is noticed
##   and never fails, so baseline moves by choice (`baseline` verb) and never by drift.
##   Headers must name same algebra, compiler commit and flags, since counts of another
##   build are not comparable; date and machine are ignored, as counts are theirs to vary
##   by nothing.
##   Machine measurements take zero band (VII.12): same build runs same instructions, and wrapper
##     reaching no shared object runs no code processor selects. So header names C compiler and
##     tracer too (VII.11), and wrapper reaching shared object is finding, since its band would
##     need readings of runner and delegate that no record holds.
##   Static count of measurand's library function stands beside each machine finding, since it
##     names line of C (VII.10).
##   Wrapper whose copy, later in same C file on same operands, reads other counts is finding:
##     its count moves with code around it, as when gcc's limits over whole file decide what it
##     inlines.
##
##   Cost: findings render as `path:line: message; got value`, so `guard` reads as koch does.

{.experimental: "strictFuncs".}

import std/json

import ./report


const BOUNDED* = ["multiplies", "adds", "divides", "roots", "bytes_moved"]
  ## Lower bound fields gate holds.
  ##   Bound is derived rather than measured, so gate holds it to equality.
  ##   It moves only where derivation moves, which is change to read, not drift.


type
  Finding* = object  ## Define one gate failure, located at file and line.
    path*: string  ## File failing, project-relative.
    line*: int  ## Line failing, counted from one; zero where whole document fails.
    message*: string  ## Statement ending with value got.
  Verdict* = object  ## Define outcome of one comparison.
    findings*: seq[Finding]  ## Growths and mismatches; any one fails gate.
    improvements*: seq[string]  ## Shrinks, reported and never failing.


const
  HEADER_CONFIG = ["name", "dimensions", "is_conformal", "sizeof_multivector"]
    ## Fields of `algebra` both documents must agree on.
  HEADER_TAKEN = ["nim", "flags"]
    ## Fields of `taken` both static documents must agree on; others describe run, not build.
  HEADER_MACHINE = ["nim", "flags", "flags_machine", "compiler_c", "tracer"]
    ## Fields of `taken` both machine documents must agree on: build whole, and tool counting.
  WORKS* = ["instructions", "bytes_read", "bytes_written"]
    ## Counts of machine's work gate holds, each with zero band.


func render*(f: Finding): string =
  ## Render finding as `path:line: message`, line `0` where whole document fails.
  f.path & ":" & $f.line & ": " & f.message


func text(node: JsonNode, keys: varargs[string]): string =
  ## Read nested field as text; empty where absent.
  let n = node{keys}
  if n.isNil: "" elif n.kind == JString: n.getStr else: $n


func checkHeaders(
  baseline, current: JsonNode; kind: string; fields_taken: openArray[string]; path: string
): seq[Finding] =
  ## Check both documents are of kind, of one algebra, and of one build; mismatch is finding.
  for (node, party) in [(baseline, "Baseline"), (current, "Current")]:
    let why = checkSchema(node, kind)
    if why.len > 0:
      result.add Finding(path: path, message: party & " document unusable; " & why)
  if result.len > 0: return
  for field in HEADER_CONFIG:
    let
      before = text(baseline, "algebra", field)
      after = text(current, "algebra", field)
    if before != after:
      result.add Finding(
        path: path,
        message: "Algebra `" & field & "` differs; got `" & after & "`, baseline `" & before & "`.",
      )
  for field in fields_taken:
    let
      before = text(baseline, "taken", field)
      after = text(current, "taken", field)
    if before != after:
      result.add Finding(
        path: path,
        message: "Build `" & field & "` differs; got `" & after & "`, baseline `" & before & "`.",
      )


func compare*(baseline, current: JsonNode; path: string): Verdict =
  ## Compare current document against baseline at path; growth or mismatch is finding.
  result.findings = checkHeaders(baseline, current, "static", HEADER_TAKEN, path)
  if result.findings.len > 0: return
  let
    before = baseline{"functions"}
    after = current{"functions"}
  if before.isNil or after.isNil:
    result.findings.add Finding(path: path, message: "Document holds no functions; got none.")
    return
  for key, _ in before.pairs:
    if not after.hasKey(key):
      result.findings.add Finding(path: path, message: "Function absent now; got `" & key & "`.")
  for key, node in after.pairs:
    if not before.hasKey(key):
      result.findings.add Finding(
        path: path,
        message: "Function absent from baseline; got `" & key & "`.",
      )
      continue
    var metrics: seq[(string, int, int)]
    for metric in METRICS_GATED:
      metrics.add (
        metric, before[key]{"total", metric}.getInt, node{"total", metric}.getInt
      )
    metrics.add (
      "bytes_moved",
      before[key]{"movement", "bytes_moved"}.getInt,
      node{"movement", "bytes_moved"}.getInt,
    )
    for (metric, was, now) in metrics:
      if now > was:
        result.findings.add Finding(
          path: path,
          message: "Total `" & metric & "` of `" & key & "` grew; got `" & $now &
              "`, baseline `" & $was & "`.",
        )
      elif now < was:
        result.improvements.add(
          "Total `" & metric & "` of `" & key & "` shrank; got `" & $now & "`, baseline `" &
          $was & "`.",
        )
  # Bounds are derived, so they never drift: any move means derivation itself changed.
  let
    bounds_before = baseline{"measurands"}
    bounds_after = current{"measurands"}
  if not bounds_before.isNil and not bounds_after.isNil:
    for id, node in bounds_before.pairs:
      let was = node{"bound"}
      if was.isNil: continue
      let now = bounds_after{id, "bound"}
      if now.isNil:
        result.findings.add Finding(
          path: path,
          message: "Lower bound absent now; got `" & id & "`.",
        )
        continue
      for metric in BOUNDED:
        let
          value_was = was{metric}.getInt
          value_now = now{metric}.getInt
        if value_was != value_now:
          result.findings.add Finding(
            path: path,
            message: "Lower bound `" & metric & "` of `" & id & "` moved; got `" & $value_now &
                "`, baseline `" & $value_was & "`.",
          )


func messageMachine(work, id, verb: string; now, was: int; statics: JsonNode): string =
  ## Spell machine finding or notice, static count of measurand's library function beside it.
  let
    key = statics{"measurands", id, "library"}.getStr
    function = statics{"functions", key}
  if key.len == 0 or function.isNil:
    return "Machine `" & work & "` of `" & id & "` " & verb & "; got `" & $now &
        "`, baseline `" & $was & "`, and no static function names it."
  "Machine `" & work & "` of `" & id & "` " & verb & "; got `" & $now & "`, baseline `" & $was &
      "`, beside static `" & key & "` of `" & $function{"total", "fills_zero"}.getInt &
      "` fills, `" & $function{"total", "copies"}.getInt & "` copies and `" &
      $function{"movement", "bytes_moved"}.getInt & "` bytes moved."


func compareMachine*(baseline, current, statics: JsonNode; path: string): Verdict =
  ## Compare current machine document against baseline at path, static document of same
  ##   inspect beside it; growth, mismatch, or wrapper reaching shared object is finding.
  result.findings = checkHeaders(baseline, current, "machine", HEADER_MACHINE, path)
  if result.findings.len > 0: return
  let
    before = baseline{"measurands"}
    after = current{"measurands"}
  if before.isNil or after.isNil:
    result.findings.add Finding(path: path, message: "Document holds no measurands; got none.")
    return
  for id, _ in before.pairs:
    if not after.hasKey(id):
      result.findings.add Finding(path: path, message: "Measurand absent now; got `" & id & "`.")
  for id, node in after.pairs:
    if node{"is_shared_reached"}.getBool:
      result.findings.add Finding(
        path: path,
        message: "Wrapper reaches shared object, whose code processor may select, so band of " &
            "its counts is zero no longer; got `" & id & "`.",
      )
    if node{"is_copy_apart"}.getBool:
      result.findings.add Finding(
        path: path,
        message: "Copy of wrapper reads other counts, so its count moves with code around it; " &
            "got `" & id & "`.",
      )
    if not before.hasKey(id):
      result.findings.add Finding(
        path: path,
        message: "Measurand absent from baseline; got `" & id & "`.",
      )
      continue
    for work in WORKS:
      let
        was = before[id]{work}.getInt
        now = node{work}.getInt
      if now > was:
        result.findings.add Finding(
          path: path,
          message: messageMachine(work, id, "grew", now, was, statics),
        )
      elif now < was:
        result.improvements.add messageMachine(work, id, "shrank", now, was, statics)
