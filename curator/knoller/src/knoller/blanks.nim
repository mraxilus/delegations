## Enforce blank lines beside suites, tests and nested helpers, and between definitions, in Nim
##   source (Article X.2, STYLE.md §1), and fix them (`koch fix`).
##   Under `tests/` of package (`reports.isFileTest`): suite is first tier and takes three blank
##     lines before it; test is second tier and takes two. First child follows its opener at
##     once, i.e. test opening suite and suite opening `when` body: no blank line. Suite or test
##     right after banner takes banner's one.
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
##   Run before definition at module level, or in `when` branch there, takes count X.2 gives
##     definition below it (`checkDefinitions`): declarative calls of one family stack,
##     declarative call after routine takes up to two, undocumented one-line helpers stack,
##     declaration block after another and documented one-line definition take one, every other
##     definition two, and inside second-tier section each count caps at one (#443). Documented
##     one-line call after routine takes one, as Q3 gives documented one-line definition (ruling
##     `D3 a` of #980). Item is documented by `##` doc on its head line or inside it; nearest
##     banner above, outside strings, gives tier. `when` counts as definition it holds first,
##     below it as one it holds last; run after pragma line, statement, banner or free comment is
##     not read. Fixer shares its reading (`gapsDefinition`).
##
##   Cost: helper inside `when`, `if` or loop of routine body is unread, since X.11 asks helper
##     first in body.
##   Cost: test or suite written other than `test "…"` or `suite "…"` is unread.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, strutils]
import ./[reports, tokens, views]


type  # TODO: Document.
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

  Form {.pure.} = enum  ## Define form of item at level, which decides count of run before it.
    Routine  ## `proc`, `func`, `template` or other routine, with its name.
    Declaration  ## Block of `type`, `const`, `let` or `var`.
    Call  ## Declarative call: of template or macro module declares, or of `define…`.
    When  ## `when` block, which counts as definition it holds first, and last below it.
    Import  ## `import`, `from`, `include` or `export`.
    Pragma  ## Pragma line, as `{.push.}`, which opens what follows.
    Statement  ## Any other code, which defines nothing.

  Item = object  ## Define item at level: its lines, form and shape.
    head: int  ## Zero-based line item opens on.
    last: int  ## Zero-based last line of item, its doc and branches included.
    form: Form
    is_one_line: bool  ## Code on head line alone, or routine with no body.
    is_documented: bool  ## Holds `##` doc.
    branches: seq[seq[Item]]  ## Items of each branch of `when`.

  Spacing {.pure.} = enum  ## Define bullet of X.2 that sets count of run, which names message.
    Two  ## Every other definition.
    Block  ## Declaration block after another.
    Documented  ## Documented one-line definition.
    Family  ## Declarative call after another.
    CallRoutine  ## Declarative call after routine.
    Group  ## Undocumented one-line helper after another.

  Gap = object  ## Define run of blank lines before definition, and counts X.2 lets it hold.
    first: int  ## Zero-based line run opens on.
    count: int  ## Blank lines run holds.
    lo: int  ## Fewest blank lines X.2 lets run hold.
    hi: int  ## Most blank lines X.2 lets run hold.
    target: Spacing
    is_second: bool  ## Inside second-tier section, where two becomes one.
    line: int  ## Zero-based head line of definition run stands before.


const  # TODO: Document.
  LUT_BLANKS_BY_TARGET: array[Target, int] = [3, 2, 0, 1, 1, 0]  ## Blank lines each target takes.
  KEYWORDS_ROUTINE = ["converter", "func", "iterator", "macro", "method", "proc", "template"]
    ## Keywords declaring routine.
  KEYWORDS_DECLARATION = ["const", "let", "type", "var"]  ## Keywords opening declaration block.
  KEYWORDS_IMPORT = ["export", "from", "import", "include"]  ## Keywords naming other module.
  KEYWORDS_BRANCH = ["elif", "else", "except", "finally", "of"]
    ## Keywords opening later branch of block at its own indent.
  FORMS_DEFINITION = {Form.Routine, Form.Declaration, Form.Call}  ## Forms X.2 counts runs before.
  OPERATORS = {'=', '+', '-', '*', '/', '<', '>', '@', '$', '~', '&', '%', '|', '!', '?', '^',
    '.', ':', '\\'}
    ## Characters of operator, which `=` beside them joins.


func toView(source: string): View =
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


func isDoc(kept: string): bool =
  ## Decide whether comment of line, strings blanked, is `##` doc: first `#` opens it.
  let at = kept.find('#')
  at >= 0 and kept.continuesWith("##", at)


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
      v.lines[anchor - 1].indentWidth == v.lines[i].indentWidth:
    dec anchor
  var upper = anchor - 1
  while upper >= 0 and not v.isText(upper): dec upper
  (upper + 1, anchor - upper - 1, upper)


func isOpenerAbove(v: View; upper, i: int): bool =
  ## Decide whether nearest code line at or above `upper`, through comments and docs alone,
  ##   opens block holding line `i`.
  var k = upper
  while k >= 0 and not v.isCode(k) and v.isText(k): dec k
  k >= 0 and v.isCode(k) and v.code[k].indentWidth < v.code[i].indentWidth


func owner(v: View, i: int): int =
  ## Find line routine opens on whose body holds line `i` at its own level; `-1` where none.
  ##   Body opens after `=` closing signature: on routine's line, or on line `)` opens.
  let indent = v.code[i].indentWidth
  var parent = i - 1
  while parent >= 0 and (not v.isCode(parent) or v.code[parent].indentWidth >= indent):
    dec parent
  if parent < 0 or not v.code[parent].strip.endsWith("="): return -1
  var signature = parent
  if v.code[parent].strip.startsWith(")"):
    signature = parent - 1
    while signature >= 0 and
        (not v.isCode(signature) or v.code[signature].indentWidth > v.code[parent].indentWidth):
      dec signature
  if signature >= 0 and v.code[signature].wordFirst in KEYWORDS_ROUTINE: signature else: -1


func lineLast(v: View, i: int): int =
  ## Find last line of routine declared on line `i`: brackets it opens, lines deeper than it,
  ##   and lines inside its strings and comments.
  result = i
  var
    depth = 0
    j = i
  while j < v.lines.len:
    let is_held = j == i or depth > 0 or v.inside[j] or
      (v.isText(j) and v.lines[j].indentWidth > v.code[i].indentWidth)
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
  v.isHeadRoutine(i) and v.code[i].indentWidth == indent and v.lineLast(i) == i


func isBodied(v: View; head, last: int): bool =
  ## Decide whether routine from line `head` to `last` holds body: `=` at depth 0, outside
  ##   backticks, that joins no operator.
  var
    depth = 0
    is_quoted = false
  for k in head .. last:
    let code = v.code[k]
    for j, c in code:
      if c == '`': is_quoted = not is_quoted
      elif is_quoted: continue
      elif c in {'(', '[', '{'}: inc depth
      elif c in {')', ']', '}'}: dec depth
      elif c == '=' and depth == 0 and (j == 0 or code[j - 1] notin OPERATORS) and
          (j + 1 >= code.len or code[j + 1] notin OPERATORS):
        return true


func runs(path, source, nimble: string): seq[Run] =
  ## Find each run of blank lines beside suite, test or nested helper whose count breaks rule.
  let
    v = source.toView
    is_file_test = path.isFileTest(nimble)
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
    elif v.isHeadRoutine(i) and v.code[i].indentWidth > 0 and v.owner(i) >= 0:
      let last = v.lineLast(i)
      if word == "template" and last == i: continue

      # One-line routine stacks after owner's head, its doc or another one; others take one.
      let
        indent = v.code[i].indentWidth
        is_one_line = last == i
        (first, count, upper) = v.runBefore(i)
      if upper >= 0:
        let
          is_stacked = is_one_line and (v.isOpenerAbove(upper, i) or v.isOneLine(upper, indent))
          target = if is_stacked: Target.Stacked else: Target.Helper
        found.add Run(first: first, count: count, target: target, line: i)
      var next = last + 1
      while next < v.lines.len and not v.isText(next): inc next
      if next < v.lines.len and v.lines[next].indentWidth >= indent:
        var named = next  # Code line run stands before, past `#` comments at helper's indent.
        while named < v.lines.len and v.isComment(named) and v.lines[named].indentWidth == indent:
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


func checkBlanks*(path, source: string; nimble = ""): seq[Report] =
  ## Report blank lines beside suite, test or nested helper other than rule asks (X.2, STYLE.md
  ##   §1); `nimble` is nimble file nearest path, which says where tests lie.
  ##   Named by its suite and `fixes.nim` alone until static pass calls it (`fixes.nim`).
  for run in runs(path, source, nimble):
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


func fixBlanks*(path, source: string; nimble = ""): Fix =
  ## Set each run check reports to count rule asks, last run first.
  let found = runs(path, source, nimble)
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


func isKeywordFirst(code: string, words: openArray[string]): bool =
  ## Decide whether code line opens with one of words, alone or before space.
  let word = code.wordFirst
  word in words and (code.strip.len == word.len or code.strip[word.len] in {' ', ':'})


func isBindingSingle(code: string): bool =
  ## Decide whether code line opens binding naming value on same line, as `idioms.nim` reads it.
  let word = code.wordFirst
  word in ["const", "let", "var"] and code.strip.len > word.len and code.strip[word.len] == ' '


func itemLast(v: View, i: int): int =
  ## Find last line of item at level opening on line `i`: its own lines, and each branch of
  ##   `elif`, `else`, `of`, `except` or `finally` at its indent after it.
  result = v.lineLast(i)
  while true:
    var next = result + 1
    while next < v.lines.len and (not v.isCode(next) or v.inside[next]): inc next
    if next >= v.lines.len or v.code[next].indentWidth != v.code[i].indentWidth or
        not v.code[next].isKeywordFirst(KEYWORDS_BRANCH):
      return
    result = v.lineLast(next)


func items(v: View; a, b: int; declared: seq[string]): seq[Item] =
  ## Read each item of level from line `a` to `b`, at indent of its first code line; each `when`
  ##   holds items of its branches.
  var i = a
  while i <= b and (not v.isCode(i) or v.inside[i]): inc i
  if i > b: return
  let indent = v.code[i].indentWidth
  while i <= b:
    if not v.isCode(i) or v.inside[i] or v.code[i].indentWidth != indent:
      inc i
      continue
    let
      code = v.code[i].strip
      word = code.wordFirst
      callee = code[word.len .. ^1]
    var item = Item(head: i, last: min(v.itemLast(i), b))
    item.form =
      if v.isHeadRoutine(i): Form.Routine
      elif code.isKeywordFirst(KEYWORDS_DECLARATION): Form.Declaration
      elif code.isKeywordFirst(["when"]): Form.When
      elif code.isKeywordFirst(KEYWORDS_IMPORT): Form.Import
      elif code.startsWith("{."): Form.Pragma
      elif callee.startsWith("(") and (word in declared or
          (word.startsWith("define") and word.len > 6 and word[6] in {'A' .. 'Z'})):
        Form.Call
      else: Form.Statement
    if item.form == Form.When:
      var openers = @[i]
      for k in i + 1 .. item.last:
        if v.isCode(k) and not v.inside[k] and v.code[k].indentWidth == indent and
            v.code[k].isKeywordFirst(KEYWORDS_BRANCH):
          openers.add k
      for n, opener in openers:
        let close = if n + 1 < openers.len: openers[n + 1] - 1 else: item.last
        item.branches.add v.items(opener + 1, close, declared)
    item.is_one_line = toSeq(item.head + 1 .. item.last).allIt(not v.isCode(it))
    if item.form == Form.Routine and not item.is_one_line:
      item.is_one_line = not v.isBodied(item.head, item.last)
    item.is_documented = toSeq(item.head .. item.last).anyIt(v.kept[it].isDoc)
    result.add item
    i = item.last + 1


func held(item: Item, is_first: bool): Item =
  ## Read definition `when` counts as: one it holds first, or last; statement where none.
  if item.form != Form.When: return item
  let branches = item.branches.filterIt(it.len > 0)
  if branches.len == 0: return Item(form: Form.Statement)
  (if is_first: branches[0][0] else: branches[^1][^1]).held(is_first)


func gaps(v: View; level: seq[Item]; result: var seq[Gap]) =
  ## Add run before each item of level that follows definition or import, with counts X.2
  ##   gives it, then runs inside each `when` branch; first item of level is not read.
  for n, item in level:
    for branch in item.branches: v.gaps(branch, result)
    if n == 0: continue
    let
      above = level[n - 1].held(is_first = false)
      below = item.held(is_first = true)
    if above.form notin FORMS_DEFINITION + {Form.Import} or below.form notin FORMS_DEFINITION:
      continue

    # Run stands above `#` comments and `##` docs right before item, at its indent.
    let indent = v.code[item.head].indentWidth
    var anchor = item.head
    while anchor > 0 and v.isText(anchor - 1) and not v.isCode(anchor - 1) and
        not v.inside[anchor - 1] and v.kept[anchor - 1].strip.startsWith("#") and
        not v.isBanner(anchor - 1) and v.lines[anchor - 1].indentWidth == indent:
      dec anchor
    var upper = anchor - 1
    while upper >= 0 and not v.isText(upper): dec upper
    if upper != level[n - 1].last: continue  # banner or free comment between
    let (head_above, head_below) = (v.code[level[n - 1].head], v.code[item.head])
    if level[n - 1].head == item.head - 1 and head_above.isBindingSingle and
        head_below.isBindingSingle and head_above.wordFirst == head_below.wordFirst:
      continue  # single bindings of one keyword, which share it (`idioms.nim`)
    var gap = Gap(first: upper + 1, count: anchor - upper - 1, line: item.head)
    if toSeq(gap.first ..< anchor).anyIt(v.inside[it]): continue

    # Count follows form of each side; inside second-tier section, two becomes one. Documented
    #   one-line call after routine reads Q3, as other documented one-line definition does
    #   (ruling `D3 a` of #980).
    let
      is_helper = below.form == Form.Routine and below.is_one_line and not below.is_documented
      is_helper_above = above.form == Form.Routine and above.is_one_line and not above.is_documented
      is_documented_one_line = below.is_one_line and below.is_documented
    (gap.lo, gap.hi, gap.target) =
      if below.form == Form.Call and above.form == Form.Call: (0, 1, Spacing.Family)
      elif below.form == Form.Call and above.form == Form.Routine and not is_documented_one_line:
        (0, 2, Spacing.CallRoutine)
      elif is_helper and is_helper_above: (0, 2, Spacing.Group)
      elif below.form == Form.Declaration and above.form == Form.Declaration: (1, 1, Spacing.Block)
      elif is_documented_one_line: (1, 1, Spacing.Documented)
      else: (2, 2, Spacing.Two)
    var banner = item.head - 1
    while banner >= 0 and (v.inside[banner] or not v.isBanner(banner)): dec banner
    gap.is_second = banner >= 0 and v.lines[banner].startsWith("#[[")
    if gap.is_second:
      gap.lo = min(gap.lo, 1)
      gap.hi = min(gap.hi, 1)
    if gap.count notin gap.lo .. gap.hi: result.add gap


func gapsDefinition(source: string): seq[Gap] =
  ## Find each run between two definitions at module level, or in `when` branch there, or
  ##   between imports and definition, whose count breaks X.2.
  let v = source.toView
  var declared: seq[string]
  for i in 0 ..< v.lines.len:
    if not v.isCode(i) or v.inside[i] or v.code[i].wordFirst notin ["macro", "template"]: continue
    var name = v.code[i].strip[v.code[i].wordFirst.len .. ^1].strip
    name = name.replace("`", "")
    var k = 0
    while k < name.len and name[k] notin {'*', '(', '[', ' ', ':', '='}: inc k
    declared.add name[0 ..< k]
  v.gaps(v.items(0, v.lines.len - 1, declared), result)
  result.sort(proc (x, y: Gap): int = cmp(x.line, y.line))


func checkDefinitions*(path, source: string): seq[Report] =
  ## Report blank lines before definition at module level other than X.2 asks for its kind.
  ##   Named by its suite and `checkFormatting` alone until static pass calls it.
  for gap in source.gapsDefinition:
    let text =
      case gap.target
      of Spacing.Two:
        if gap.is_second: "Sibling inside second-tier section takes one blank line before it"
        else: "Definition takes two blank lines before it"
      of Spacing.Block: "Declaration block takes one blank line after another"
      of Spacing.Documented: "Documented one-line definition takes one blank line after another"
      of Spacing.Family:
        "Declarative call stacks in its family, and one blank line separates two families"
      of Spacing.CallRoutine:
        "Declarative call takes at most " &
          (if gap.is_second: "one blank line" else: "two blank lines") & " after routine above it"
      of Spacing.Group:
        "Undocumented one-line helper stacks in its group, and at most " &
          (if gap.is_second: "one blank line separates" else: "two blank lines separate") &
          " two groups"
    result.add initReport(
      path, gap.line + 1, Rule.LinesBlankDefinition, text & "; got `" & $gap.count & "`."
    )


func fixDefinitions*(path, source: string): Fix =
  ## Set each run `checkDefinitions` reports to count X.2 asks, last run first.
  let found = source.gapsDefinition
  var
    lines = source.split('\n')
    origin = toSeq(1 .. lines.len)
  for gap in found.sortedByIt(-it.first):
    let
      wanted = gap.count.clamp(gap.lo, gap.hi)
      after = gap.first + gap.count
      kept = origin[gap.first ..< gap.first + min(gap.count, wanted)]
      inserted = newSeq[int](wanted - kept.len)
    lines = lines[0 ..< gap.first] & newSeq[string](wanted) & lines[after .. ^1]
    origin = origin[0 ..< gap.first] & kept & inserted & origin[after .. ^1]
  result.source = lines.join("\n")
  for gap in found: result.fixed.add initReport(path, gap.line + 1, Rule.LinesBlankDefinition)
  if found.len > 0: result.origin = origin
