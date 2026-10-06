## Enforce blank lines beside suites, tests and nested helpers in Nim source (Article X.2;
##   STYLE.md §1), and fix them (`koch fix`).
##   Under `tests/` (`reports.isFileTest`): suite is first tier and takes three blank lines
##     before it; test is second tier and takes two. First child follows its opener at once,
##     i.e. test opening suite and suite opening `when` body: no blank line. Suite or test right
##     after banner takes banner's one.
##   Nested helper, i.e. routine declared in body of routine: one blank line on each side,
##     right after owner's doc too. Side leaving owner's body is not read, since what stands
##     there is owner's sibling. Helper never moves (X.11 asks it first; reading holds that).
##     One-line `template` is alias, and is left alone.
##   Routine whose definition stands on one line (`{.borrow.}` with no body, or body on line of
##     its signature, no doc after it) takes none before it where it follows owner's head,
##     owner's doc, or another such routine, so borrowed funcs and thin wrappers stack, as X.2
##     stacks undocumented one-line helpers. One still stands between last of them and stage or
##     routine of several lines after it.
##   Run of blank lines goes above `#` comment on line right before, at same indent, so comment
##     stays with what it names; `##` doc and banner never move with it.
##   Reads code view (`views.codeOnly`), so `suite`, `test` or `proc` inside fixture string never
##     moves. Run lying inside string or block comment spanning lines is never read.
##   Checks and fixer share one reading (`runs`), so each rule is written once (Article II.1).
##
##   Cost: helper inside `when`, `if` or loop of routine body is unread, since X.11 asks helper
##     first in body.
##   Cost: test or suite written other than `test "…"` or `suite "…"` is unread.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, strutils]
import ./[reports, tokens, views]


type
  Target {.pure.} = enum  ## Define what run stands beside, which decides its count and its message.
    Suite  ## Run before suite.
    Test  ## Run before test.
    Child  ## Run before first child of its opener.
    Banner  ## Run after banner, before suite or test.
    Helper  ## Run on either side of nested helper.
    Stacked  ## Run before one-line routine after owner's head, its doc or another such routine.

  Run = object  ## Define run of blank lines whose count rule reads otherwise.
    first: int  ## Zero-based line run opens on.
    count: int  ## Blank lines run holds.
    wanted: int  ## Blank lines rule asks.
    target: Target
    line: int  ## Zero-based line of suite, test or helper run stands beside.

  View = object
    ## Define source as rules read it: text, code, code with comments, lines inside tokens.
    lines: seq[string]
    code: seq[string]  ## Comments, strings and characters blanked.
    kept: seq[string]  ## Strings and characters blanked.
    inside: seq[bool]  ## Line after first of string or comment spanning lines.


const
  LUT_BLANKS_BY_TARGET: array[Target, int] = [3, 2, 0, 1, 1, 0]  ## Blank lines each target takes.
  KEYWORDS_ROUTINE = ["converter", "func", "iterator", "macro", "method", "proc", "template"]
    ## Keywords declaring routine.


func viewOf(source: string): View =
  ## Read source once for every rule here.
  result = View(
    lines: source.split('\n'),
    code: source.codeOnly.split('\n'),
    kept: source.codeAndComments.split('\n'),
  )
  result.inside = newSeq[bool](result.lines.len)
  for t in source.tokens:
    for line in t.line + 1 .. t.lineLast(source): result.inside[line] = true


func isText(v: View, i: int): bool =
  ## Decide whether line holds anything but whitespace.
  v.lines[i].strip.len > 0


func isCode(v: View, i: int): bool =
  ## Decide whether line holds code outside comment and string.
  v.code[i].strip.len > 0


func isComment(v: View, i: int): bool =
  ## Decide whether line holds `#` comment alone: no code, no doc, no banner.
  let text = v.kept[i].strip
  not v.isCode(i) and not v.inside[i] and text.startsWith("#") and not text.startsWith("##") and
    not text.startsWith("#[")


func isBanner(v: View, i: int): bool =
  ## Decide whether line is section banner, alone on its line and never indented (X.2).
  let line = v.lines[i]
  (line.startsWith("#[ ") and line.endsWith(" ]#")) or
    (line.startsWith("#[[ ") and line.endsWith(" ]]#"))


func wordFirst(code: string): string =
  ## Read leading identifier of code line.
  let s = code.strip
  var k = 0
  while k < s.len and s[k] in {'a' .. 'z', 'A' .. 'Z', '0' .. '9', '_'}: inc k
  s[0 ..< k]


func runBefore(v: View, i: int): tuple[first, count, upper: int] =
  ## Read run of blank lines above line `i`, moved above `#` comments right before it at its
  ##   indent; `upper` is text line above run, `-1` where none.
  var anchor = i
  while anchor > 0 and v.isComment(anchor - 1) and
      v.lines[anchor - 1].indentOf == v.lines[i].indentOf:
    dec anchor
  var upper = anchor - 1
  while upper >= 0 and not v.isText(upper): dec upper
  (upper + 1, anchor - upper - 1, upper)


func isOpenerAbove(v: View; upper, i: int): bool =
  ## Decide whether nearest code line at or above `upper`, through comments and docs alone,
  ##   opens block holding line `i`.
  var k = upper
  while k >= 0 and not v.isCode(k) and v.isText(k): dec k
  k >= 0 and v.isCode(k) and v.code[k].indentOf < v.code[i].indentOf


func ownerOf(v: View, i: int): int =
  ## Find line routine opens on whose body holds line `i` at its own level; `-1` where none.
  ##   Body opens after `=` closing signature: on routine's line, or on line `)` opens.
  let indent = v.code[i].indentOf
  var parent = i - 1
  while parent >= 0 and (not v.isCode(parent) or v.code[parent].indentOf >= indent):
    dec parent
  if parent < 0 or not v.code[parent].strip.endsWith("="): return -1
  var signature = parent
  if v.code[parent].strip.startsWith(")"):
    signature = parent - 1
    while signature >= 0 and
        (not v.isCode(signature) or v.code[signature].indentOf > v.code[parent].indentOf):
      dec signature
  if signature >= 0 and v.code[signature].wordFirst in KEYWORDS_ROUTINE: signature else: -1


func lastOf(v: View, i: int): int =
  ## Find last line of routine declared on line `i`: brackets it opens, lines deeper than it,
  ##   and lines inside its strings and comments.
  result = i
  var
    depth = 0
    j = i
  while j < v.lines.len:
    let is_held = j == i or depth > 0 or v.inside[j] or
      (v.isText(j) and v.lines[j].indentOf > v.code[i].indentOf)
    if v.isText(j) and not is_held: break
    if is_held:
      result = j
      for c in v.code[j]:
        if c in {'(', '[', '{'}: inc depth
        elif c in {')', ']', '}'}: dec depth
    inc j


func isHeadRoutine(v: View, i: int): bool =
  ## Decide whether code line `i` declares named routine: keyword, space, then name.
  if not v.isCode(i) or v.inside[i]: return false
  let
    word = v.code[i].wordFirst
    after = v.code[i].strip[word.len .. ^1]
  word in KEYWORDS_ROUTINE and after.startsWith(" ") and after.strip.len > 0 and
    after.strip[0] != '('


func isOneLine(v: View; i, indent: int): bool =
  ## Decide whether line `i` declares, at indent, routine whose definition stands on that line
  ##   alone: `{.borrow.}` with no body, or body on line of its signature, no doc after it.
  v.isHeadRoutine(i) and v.code[i].indentOf == indent and v.lastOf(i) == i


func runs(path, source: string): seq[Run] =
  ## Find each run of blank lines beside suite, test or nested helper whose count breaks rule.
  let
    v = source.viewOf
    is_file_test = path.isFileTest
  var found: seq[Run]
  for i in 0 ..< v.lines.len:
    if not v.isCode(i) or v.inside[i]: continue
    let word = v.code[i].wordFirst
    var after = v.lines[i].strip[word.len .. ^1].strip(trailing = false)
    if is_file_test and word in ["suite", "test"] and after.startsWith("\""):
      let (first, count, upper) = v.runBefore(i)
      if upper < 0: continue
      var target = if word == "suite": Target.Suite else: Target.Test
      if v.isBanner(upper): target = Target.Banner
      elif v.isOpenerAbove(upper, i): target = Target.Child
      found.add Run(first: first, count: count, target: target, line: i)
    elif v.isHeadRoutine(i) and v.code[i].indentOf > 0 and v.ownerOf(i) >= 0:
      let last = v.lastOf(i)
      if word == "template" and last == i: continue

      # One-line routine stacks after owner's head, its doc or another one; others take one.
      let
        indent = v.code[i].indentOf
        is_one_line = last == i
        (first, count, upper) = v.runBefore(i)
      if upper >= 0:
        let
          is_stacked = is_one_line and (v.isOpenerAbove(upper, i) or v.isOneLine(upper, indent))
          target = if is_stacked: Target.Stacked else: Target.Helper
        found.add Run(first: first, count: count, target: target, line: i)
      var next = last + 1
      while next < v.lines.len and not v.isText(next): inc next
      if next < v.lines.len and v.lines[next].indentOf >= indent:
        var named = next  # Code line run stands before, past `#` comments at helper's indent.
        while named < v.lines.len and v.isComment(named) and v.lines[named].indentOf == indent:
          inc named
        let
          is_stacked = is_one_line and named < v.lines.len and v.isOneLine(named, indent)
          target = if is_stacked: Target.Stacked else: Target.Helper
        found.add Run(first: last + 1, count: next - last - 1, target: target, line: i)

  # Keep runs breaking their count, outside multi-line tokens; two rules on one run must agree.
  for run in found.mitems: run.wanted = LUT_BLANKS_BY_TARGET[run.target]
  for run in found:
    if run.count == run.wanted: continue
    if toSeq(run.first ..< run.first + run.count).anyIt(v.inside[it]): continue
    if found.anyIt(it.first == run.first and it.wanted != run.wanted): continue
    if result.anyIt(it.first == run.first): continue
    result.add run


func checkBlanks*(path, source: string): seq[Report] =
  ## Report blank lines beside suite, test or nested helper other than rule asks (X.2, STYLE.md
  ##   §1).
  ##   Named by its suite and `fixes.nim` alone until static pass calls it (`fixes.nim`).
  for run in runs(path, source):
    let message =
      case run.target
      of Target.Suite: "Suite takes three blank lines before it"
      of Target.Test: "Test takes two blank lines before it"
      of Target.Child: "First child follows its opener at once"
      of Target.Banner: "Suite or test after banner takes banner's one blank line"
      of Target.Helper: "Nested helper takes one blank line on each side"
      of Target.Stacked:
        "One-line routine after owner's head, its doc or another one-line routine takes no " &
          "blank line before it"
    let rule =
      if run.target in {Target.Helper, Target.Stacked}: Rule.LinesBlankHelper
      else: Rule.LinesBlankTest
    result.add initReport(path, run.line + 1, rule, message & "; got `" & $run.count & "`.")


func fixBlanks*(path, source: string): Fix =
  ## Set each run check reports to count rule asks, last run first.
  let found = runs(path, source)
  var
    lines = source.split('\n')
    origin = toSeq(1 .. lines.len)
  for run in found.sortedByIt(-it.first):
    let
      after = run.first + run.count
      kept = origin[run.first ..< run.first + min(run.count, run.wanted)]
      inserted = newSeq[int](run.wanted - kept.len)
    lines = lines[0 ..< run.first] & newSeq[string](run.wanted) & lines[after .. ^1]
    origin = origin[0 ..< run.first] & kept & inserted & origin[after .. ^1]
  result.source = lines.join("\n")
  for run in found:
    let rule =
      if run.target in {Target.Helper, Target.Stacked}: Rule.LinesBlankHelper
      else: Rule.LinesBlankTest
    result.fixed.add initReport(path, run.line + 1, rule)
  if found.len > 0: result.origin = origin
