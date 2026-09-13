## Compare static measurements against their committed baseline; any count grown is finding.
##   Gate is monotone: growth in any gated count or in bytes moved fails, shrink is noticed
##   and never fails, so baseline moves by choice (`baseline` verb) and never by drift.
##   Headers must name same algebra, compiler commit and flags, since counts of another
##   build are not comparable; date and machine are ignored, as counts are theirs to vary
##   by nothing.
##
##   Cost: findings render as `path:0: message; got value`, so `check` reads as koch does.

{.experimental: "strictFuncs".}

import std/[json, strutils]

import ./report


type
  Finding* = object
    ## Define one gate failure, located at baseline file.
    path*: string
      ## Baseline file, project-relative.
    message*: string
      ## Statement ending with value got.
  Verdict* = object
    ## Define outcome of one comparison.
    findings*: seq[Finding]
      ## Growths and mismatches; any one fails gate.
    improvements*: seq[string]
      ## Shrinks, reported and never failing.


const
  HEADER_CONFIG = ["name", "dimensions", "is_conformal", "sizeof_multivector"]
    ## Fields of `algebra` both documents must agree on.
  HEADER_TAKEN = ["nim", "flags"]
    ## Fields of `taken` both documents must agree on; others describe run, not build.


func render*(f: Finding): string =
  ## Render finding as `path:0: message`, line `0` since document is one measurement.
  f.path & ":0: " & f.message


func text(node: JsonNode; keys: varargs[string]): string =
  ## Read nested field as text; empty where absent.
  let n = node{keys}
  if n.isNil: "" elif n.kind == JString: n.getStr else: $n


func compare*(baseline, current: JsonNode; path: string): Verdict =
  ## Compare current document against baseline at path; growth or mismatch is finding.
  for (node, party) in [(baseline, "Baseline"), (current, "Current")]:
    let why = checkSchema(node, "static")
    if why.len > 0:
      result.findings.add Finding(path: path, message: party & " document unusable; " & why)
  if result.findings.len > 0: return
  for field in HEADER_CONFIG:
    let before = text(baseline, "algebra", field)
    let after = text(current, "algebra", field)
    if before != after:
      result.findings.add Finding(
        path: path,
        message: "Algebra `" & field & "` differs; got `" & after & "`, baseline `" & before & "`.",
      )
  for field in HEADER_TAKEN:
    let before = text(baseline, "taken", field)
    let after = text(current, "taken", field)
    if before != after:
      result.findings.add Finding(
        path: path,
        message: "Build `" & field & "` differs; got `" & after & "`, baseline `" & before & "`.",
      )
  if result.findings.len > 0: return
  let before = baseline{"functions"}
  let after = current{"functions"}
  if before.isNil or after.isNil:
    result.findings.add Finding(path: path, message: "Document holds no functions; got none.")
    return
  for key, _ in before.pairs:
    if not after.hasKey(key):
      result.findings.add Finding(path: path, message: "Function absent now; got `" & key & "`.")
  for key, node in after.pairs:
    if not before.hasKey(key):
      result.findings.add Finding(
        path: path, message: "Function absent from baseline; got `" & key & "`."
      )
      continue
    var metrics: seq[(string, int, int)]
    for metric in GATED:
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
            $was & "`."
        )
