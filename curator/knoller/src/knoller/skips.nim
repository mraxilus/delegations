## Enforce that each gap of coverage shows in run (Article IX.9): skip gives its reason, gap is
##   placeholder test that skips, and no test leaves run under bare `when`, as Architect ruled on
##   rule 17 of #443. No fix, since no text gives reason.
##   Test is `test "…":` and lines deeper than it, in file under `tests` of its package. Reason of
##     skip trails it on its line, as STYLE.md §6 writes it, or stands on comment line right above
##     it at its indent, or in echo of text there, which run prints. Skip that is whole body of
##     branch may give it above head of that branch, as `when IS_CONFORMAL: skip()` on one line
##     gives it above itself. Placeholder, whose code is `skip()` alone, gives its reason in name
##     opening with `TODO:`.
##   TODO inside test that runs names gap run never shows, so it reports; TODO giving reason of
##     skip is none, and test whose body skips at its own level shows in run as skipped, so it
##     holds no gap.
##   Test under `when` with no other branch leaves run where its condition is false, so it reports;
##     `when isMainModule:` names no configuration. Such gate around whole suite configures
##     suite, and skips no test in it, so test under it passes; gate inside suite reports (ruling
##     `D3 a` of #980). Code under `quote do:` is generated, so its skip and TODO are none of
##     file's.
##
##   Cost: scanner on lines, never parser: test reads from line opening with `test` and ending in
##     `:`, suite alike from `suite`, and line at its indent or shallower ends it.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils]
import ./[reports, views]


const
  CALL_SKIP = "skip()"  ## Call marking test skipped, which run prints as `[SKIPPED]`.
  WORD_GAP = "TODO"  ## Word of comment naming gap of coverage.
  PREFIX_PLACEHOLDER = "TODO:"  ## Opening of name of placeholder test, which gives its reason.
  HEAD_GENERATED = "quote do:"  ## Ending of line whose block is generated code.
  GUARD_MAIN = "isMainModule"  ## Condition of entry block, which names no configuration.
  CHARS_NAME = IdentChars + {'\x80' .. '\xFF'}  ## Bytes Nim reads as part of name.
  BRANCHES = ["if ", "when ", "elif ", "else"]  ## Openings of head of branch that may skip whole.
  MESSAGE_SKIP = "Skip carries its reason, so run shows why test skips; got `"
  MESSAGE_GAP = "Gap in coverage is placeholder test that skips, so run shows it; got `"
  MESSAGE_GATE = "Test that cannot run under configuration skips there, so run keeps it; got `"


func isTest(code: string): bool =
  ## Decide whether line of code view opens test: `test`, blanked name, and `:`.
  let s = code.strip
  s.startsWith("test ") and s.endsWith(":")


func isSuite(code: string): bool =
  ## Decide whether line of code view opens suite: `suite`, blanked name, and `:`.
  let s = code.strip
  s.startsWith("suite ") and s.endsWith(":")


func isSkip(code: string): bool =
  ## Decide whether line of code view calls `skip()`, never as part of other name.
  let at = code.find(CALL_SKIP)
  at >= 0 and (at == 0 or code[at - 1] notin CHARS_NAME)


func comment(line, view: string): string =
  ## Read comment of line, from its `#` outside strings to end; empty where none.
  let at = view.find('#')
  if at < 0: "" else: line[at .. ^1].strip


func codeText(line, view: string): string =
  ## Read code of line as written, comment left out.
  let at = view.find('#')
  (if at < 0: line else: line[0 ..< at]).strip


func checkSkips*(path, source, nimble: string): seq[Report] =
  ## Report skip of test that gives no reason, gap inside test that runs, and test under bare
  ##   `when`, in file under `tests` of its package (`nimble`).
  ##   Named by its suite and `chain.nim` alone until static pass calls it (`fixes.nim`).
  if not path.isFileTest(nimble): return
  let
    lines = source.split('\n')
    code = source.codeOnly.split('\n')
    views = source.codeAndComments.split('\n')
  for i in 0 ..< lines.len:
    if not code[i].isTest: continue
    let indent = lines[i].indentWidth

    # Read each head enclosing test, innermost first; test of generated code is none of file's.
    var heads: seq[int]
    for j in countdown(i - 1, 0):
      let depth = if heads.len > 0: lines[heads[^1]].indentWidth else: indent
      if depth == 0: break
      if code[j].strip.len > 0 and lines[j].indentWidth < depth: heads.add j
    if heads.anyIt(code[it].strip.endsWith(HEAD_GENERATED)): continue

    # Read body: each line deeper than test, until line at its indent or shallower.
    var last = i
    while last + 1 < lines.len and
        (lines[last + 1].strip.len == 0 or lines[last + 1].indentWidth > indent):
      inc last
    var
      body: seq[int]
      depth_generated = -1
    for k in i + 1 .. last:
      if lines[k].strip.len == 0: continue
      if depth_generated >= 0 and lines[k].indentWidth > depth_generated: continue
      depth_generated = if code[k].strip.endsWith(HEAD_GENERATED): lines[k].indentWidth else: -1
      body.add k
    let
      steps = body.filterIt(code[it].strip.len > 0)
      level = if steps.len > 0: lines[steps[0]].indentWidth else: indent + 2
      name = lines[i].strip["test".len .. ^2].strip.strip(chars = {'"'})
    if steps.len == 1 and code[steps[0]].strip == CALL_SKIP and name.startsWith(PREFIX_PLACEHOLDER):
      continue  # placeholder gives its reason in name

    # Each skip gives its reason; comment that gives it names no gap.
    var reasons: seq[int]
    for at, k in steps:
      if not code[k].isSkip: continue
      # Reason of skip that is whole body of branch may stand above that branch: next step leaves
      #   branch, or none follows.
      let
        is_head = k - 1 > i and lines[k - 1].indentWidth < lines[k].indentWidth and
          code[k - 1].strip.endsWith(":") and BRANCHES.anyIt(code[k - 1].strip.startsWith(it))
        is_branch = is_head and
          (at + 1 == steps.len or lines[steps[at + 1]].indentWidth <= lines[k - 1].indentWidth)
        line = if is_branch: k - 1 else: k
        above = line - 1
        is_above_same = above > i and lines[above].indentWidth == lines[line].indentWidth
        is_comment_above = is_above_same and lines[above].strip.startsWith('#')
        is_echo_above = is_above_same and code[above].strip.startsWith("echo") and
          '"' in lines[above]
      if lines[k].comment(views[k]).len > 0: reasons.add k
      elif is_comment_above: reasons.add above
      elif not is_echo_above:
        result.add initReport(
          path, k + 1, Rule.ReasonSkip, MESSAGE_SKIP & lines[k].codeText(views[k]) & "`."
        )

    # TODO inside test that runs is gap; test skipping at its own level shows as skipped.
    let is_running = not steps.anyIt(lines[it].indentWidth == level and code[it].strip == CALL_SKIP)
    if is_running:
      for k in body:
        let
          text = lines[k].comment(views[k])
          marker = text.strip(chars = {'#', ' '}, trailing = false)
        if k notin reasons and marker.startsWith(WORD_GAP):
          result.add initReport(path, k + 1, Rule.ReasonSkip, MESSAGE_GAP & text & "`.")

    # Test under `when` with no other branch leaves run where its condition is false; innermost
    #   such gate reports, once for each test. Gate around whole suite configures suite, and
    #   skips no test in it, so read ends at suite (ruling `D3 a` of #980).
    for j in heads:
      if code[j].isSuite: break
      let
        head = lines[j].indentWidth
        gate = lines[j].codeText(views[j])
      if not gate.startsWith("when ") or not gate.endsWith(":") or GUARD_MAIN in gate: continue
      var next = j + 1
      while next < lines.len and (code[next].strip.len == 0 or lines[next].indentWidth > head):
        inc next
      let is_branched = next < lines.len and lines[next].indentWidth == head and
        (code[next].strip.startsWith("else") or code[next].strip.startsWith("elif "))
      if is_branched: continue
      result.add initReport(
        path,
        i + 1,
        Rule.ReasonSkip,
        MESSAGE_GATE & lines[i].codeText(views[i]) & "` under `" & gate & "`.",
      )
      break
