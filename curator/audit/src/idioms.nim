## Enforce idioms of source that one line, or one header, shows (STYLE.md §2, §5, §6; Article
##   VIII.5, X.5; CONTRIBUTOR.md, System and TypeScript); and fix each of these that has one
##   mechanical fix (`koch fix`).
##   Nim rules read code-only view (`names.codeOnly`), so string and comment never trip them:
##   - `{.experimental: "strictFuncs".}` stands in this exact form before first import, in
##     every module, suite included (§2).
##   - Bracket import is alphabetised, and standard library comes before packages, which
##     come before local modules (X.5, §5).
##   - Two consecutive single bindings of one keyword share that keyword (X.5).
##   - `{.used.}` carries trailing comment naming its consumer (§2).
##   - `{.push.}` stands only over block of foreign bindings, which `{.pop.}` closes (§2).
##   - `return result` never appears: bare `return` exits early with `result` (§5).
##   Under `tests/` alone:
##   - suite importing `std/random` seeds it (§6);
##   - stub `tests/test_*.nim` carries testament header, without `-r`, `batchable` or
##     `joinable` (§6);
##   - `echo` of value without label, outside condition, is debug output (VIII.5).
##   Every kind but Markdown: path of one machine is finding (CONTRIBUTOR.md, System).
##   `tsconfig.json` sets three flags TypeScript section names, each to `true`.
##
##   Fixers read same spans, runs and constants their checks read, so each rule is written
##     once (Article II.1), and each rewrites only lines its check reports:
##   - Bracket items are sorted into slots they held, so bracket spanning lines keeps its
##     layout; contiguous import lines are reordered by rank, stable within rank.
##   - Run of single bindings becomes keyword alone, then each binding indented two spaces;
##     lines continuing last binding (open bracket, deeper indent, doc under it) move too.
##   - Missing `strictFuncs` goes where X.6 puts directives: before first code line that is
##     neither directive nor testament header, i.e. after header docs and design notes.
##   - `return result` becomes `return`, which exits with same value.
##   Fixer never writes line width check reports (`form.isWide`); rewrite that would leaves
##     its lines and finding for hand.
##   No fixer: import ranked low across lines that are not imports, since where it lands and
##     what blank lines surround it are both choices; bracket holding comment, since comment
##     belongs to item or to slot; run whose last binding opens long string, since indenting
##     its lines changes string; `strictFuncs` after imports, which is move rather than one
##     insertion and waits for its own rule; `{.used.}` consumer, `{.push.}` scope, random
##     seed, stub header, debug output, machine path and TypeScript flags, since each needs
##     knowledge text does not hold.
##
##   Cost: text scanner, never parser. Import under `when` and `from … import` are unread.
##   Cost: seeded `initRand` passes as `randomize(0)` does, since both fix sequence; STYLE
##     names `randomize(0)`, and reading holds which form project takes.
##   Cost: debug output is told from report by its shape alone: labelled `echo`, i.e. one
##     holding string literal, passes as report of measured figure, and conditional `echo`
##     passes as failure diagnostic. Labelled debug output then holds by reading.
##   Cost: `tsconfig.json` is read as text, since TypeScript admits comments that
##     `std/json` refuses; flag set through `extends` reads as absent.
##   Cost: bracket item sorted into slot of other length moves line width by difference, and
##     comment above first import line stays above it when rank reorders block.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, strutils]
import ./[findings, form, names]


type
  ImportSpan = object
    ## Define one import statement as code view holds it: lines it spans, what it imports.
    first: int  ## Zero-based line `import` opens.
    last: int  ## Zero-based line statement closes on; bracket spanning lines is read whole.
    target: string  ## Text after `import`, lines joined.

  BindingRun = object
    ## Define run of consecutive single bindings sharing keyword and indent.
    first: int  ## Zero-based line of first binding.
    last: int  ## Zero-based line of last binding.
    keyword: string  ## Keyword each binding repeats.
    indent: int  ## Indent each binding stands at.


const
  STRICT_FUNCS* = "{.experimental: \"strictFuncs\".}"
    ## Pragma line every module carries, in this exact form (STYLE.md §2).
  MACHINE_PATHS* = ["/home/", "/Users/", "C:\\"]
    ## Prefixes naming paths of one machine (CONTRIBUTOR.md, System).
  TYPESCRIPT_FLAGS* = ["exactOptionalPropertyTypes", "noUncheckedIndexedAccess", "strict"]
    ## Compiler options `tsconfig.json` sets to `true` (CONTRIBUTOR.md, TypeScript).
  BINDING_KEYWORDS = ["const", "let", "var"]
    ## Keywords opening binding.
  CONDITIONS = ["case", "elif", "else", "except", "if", "of", "when"]
    ## Openers making `echo` beneath them conditional, i.e. failure diagnostic.
  FOREIGN_MARKS = ["dynlib", "header:", "importc", "importcpp", "importjs"]
    ## Pragmas marking foreign bindings, which alone may stand under `{.push.}`.
  STUB_KEYS = ["batchable", "joinable"]
    ## Testament keys `testament pattern` never reads (STYLE.md §6).
  IMPORT_MARK = "import "
    ## Opening of import statement at module level.
  RETURN_RESULT = "return result"
    ## Statement STYLE.md §5 bans, since bare `return` exits with `result`.
  TESTAMENT_HEADER = "discard \"\"\""
    ## Opening of stub's testament header, which stands before module's header docs.
  LONG_STRING = "\"\"\""
    ## Delimiter of string spanning lines.
  OPENERS = {'(', '[', '{'}
    ## Brackets opening span that continues line.
  CLOSERS = {')', ']', '}'}
    ## Brackets closing such span.


func firstWord(text: string): string =
  ## Read leading identifier of stripped text.
  let s = text.strip
  var k = 0
  while k < s.len and s[k] in {'a'..'z', 'A'..'Z', '0'..'9', '_'}: inc k
  s[0 ..< k]


func importRank(target: string): int =
  ## Rank import for order: standard library, then packages, then local modules.
  if target.startsWith("std/"): 0
  elif target.startsWith("./") or target.startsWith("../"): 2
  else: 1


func itemName(item: string): string =
  ## Read module name of bracket item, pragma dropped: `b {.all.}` gives `b`.
  item.strip.split(' ')[0]


func bracketItems(text: string): seq[string] =
  ## Read module names inside brackets of `prefix/[a, b {.all.}]`, pragma dropped.
  let
    open = text.find('[')
    close = text.rfind(']')
  if open < 0 or close < open: return
  for item in text[open + 1 ..< close].split(','):
    let name = item.itemName
    if name.len > 0: result.add name


func importSpans(code: seq[string]): seq[ImportSpan] =
  ## Read each import statement of code view, bracket spanning lines read whole.
  var i = 0
  while i < code.len:
    if not code[i].startsWith(IMPORT_MARK):
      inc i
      continue
    let first = i
    var text = code[i]
    while text.count('[') > text.count(']') and i + 1 < code.len:
      inc i
      text.add code[i]
    result.add ImportSpan(first: first, last: i, target: text[IMPORT_MARK.len .. ^1].strip)
    inc i


func checkImports(path: string, code: seq[string]): seq[Finding] =
  ## Report bracket import out of order, and import ranked below one before it.
  var rank = -1
  for span in code.importSpans:
    let items = span.target.bracketItems
    if items != items.sorted:
      result.add finding(
        path, span.first + 1,
        "Bracket import is alphabetised (X.5); got `" & items.join(", ") & "`.",
      )
    let r = span.target.importRank
    if r < rank:
      result.add finding(
        path, span.first + 1,
        "Standard library comes first, then packages, then local modules (X.5); got `" &
          span.target.split('[')[0] & "`.",
      )
    rank = max(rank, r)


func isSingleBinding(line: string): bool =
  ## Decide whether line opens binding naming value on same line, e.g. `let x = 1`.
  let word = line.firstWord
  word in BINDING_KEYWORDS and line.strip.len > word.len and line.strip[word.len] == ' '


func bindingRuns(code: seq[string]): seq[BindingRun] =
  ## Find each run of two or more consecutive single bindings of one keyword at one indent.
  var i = 0
  while i + 1 < code.len:
    let
      a = code[i]
      b = code[i + 1]
    if a.isSingleBinding and b.isSingleBinding and a.firstWord == b.firstWord and
        a.indentOf == b.indentOf:
      var j = i + 1
      while j + 1 < code.len and code[j + 1].isSingleBinding and
          code[j + 1].firstWord == a.firstWord and code[j + 1].indentOf == a.indentOf:
        inc j
      result.add BindingRun(first: i, last: j, keyword: a.firstWord, indent: a.indentOf)
      i = j + 1
    else: inc i


func checkBindings(path: string, code: seq[string]): seq[Finding] =
  ## Report run of consecutive single bindings of one keyword at one indent, once per run.
  for run in code.bindingRuns:
    result.add finding(
      path, run.first + 1,
      "Consecutive single bindings share one keyword (X.5); got `" & run.keyword & "` twice.",
    )


func pragmaNames(code: string): seq[string] =
  ## Read names inside every `{. .}` of code line: `{.borrow, used.}` gives `borrow`, `used`.
  var at = 0
  while true:
    let open = code.find("{.", at)
    if open < 0: break
    let close = code.find(".}", open + 2)
    if close < 0: break
    for p in code[open + 2 ..< close].split(','):
      let name = p.strip.split({':', ' ', '['})[0]
      if name.len > 0: result.add name
    at = close + 2


func checkPragmas(path: string, lines, code: seq[string]): seq[Finding] =
  ## Report `{.used.}` without comment, and `{.push.}` over block holding no foreign binding.
  for i, c in code:
    let s = c.strip
    if "used" in c.pragmaNames and s != "{.used.}" and
        lines[i].find('#', c.strip(leading = false).len) < 0:
      result.add finding(
        path, i + 1, "`{.used.}` carries comment naming its consumer (STYLE.md §2); got none."
      )
    if s.startsWith("{.push"):
      var
        j = i
        text = ""
      while j < code.len:
        text.add code[j]
        if j > i and code[j].strip.startsWith("{.pop"): break
        inc j
      if not FOREIGN_MARKS.anyIt(it in text):
        result.add finding(
          path, i + 1,
          "`{.push.}` stands only over foreign bindings, which `{.pop.}` closes (STYLE.md §2); " &
            "got `" & s & "`.",
        )
    if s == RETURN_RESULT:
      result.add finding(
        path, i + 1,
        "Bare `return` exits early with `result`, and routine ends on value itself " &
          "(STYLE.md §5); got `return result`.",
      )


func isUnderCondition(code: seq[string], i: int): bool =
  ## Decide whether nearest line enclosing line `i` opens condition.
  let indent = code[i].indentOf
  var k = i - 1
  while k >= 0:
    if code[k].strip.len > 0 and code[k].indentOf < indent:
      return code[k].firstWord in CONDITIONS
    dec k


func isRandomImported(code: seq[string]): bool =
  ## Decide whether code imports `std/random`, alone or in bracket.
  for c in code:
    if c.startsWith(IMPORT_MARK) and
        ("std/random" in c or (c.startsWith("import std/[") and "random" in c.bracketItems)):
      return true


func isSeeded(code: string): bool =
  ## Decide whether code seeds generator: `initRand(<seed>)`, or `randomize(<seed>)`.
  let at = code.find("randomize(")
  "initRand(" in code or (at >= 0 and at + 10 < code.len and code[at + 10] != ')')


func checkTest(path, source: string, lines, code: seq[string]): seq[Finding] =
  ## Report unseeded random suite, stub header breaking §6, and `echo` of debug shape.
  if code.isRandomImported and not code.join("\n").isSeeded:
    result.add finding(
      path, 0, "Suite seeds `std/random`, as `randomize(0)` does (STYLE.md §6); got no seed."
    )
  let
    parts = path.split('/')
    is_stub = parts.len >= 2 and parts[^2] == "tests" and parts[^1].startsWith("test_")
  if is_stub:
    let open = source.find(TESTAMENT_HEADER)
    if open < 0:
      result.add finding(
        path, 0, "Test stub carries testament header (STYLE.md §6); got none."
      )
    else:
      let
        close = source.find(LONG_STRING, open + TESTAMENT_HEADER.len)
        header = if close > open: source[open + TESTAMENT_HEADER.len ..< close] else: ""
      for line in header.splitLines:
        let s = line.strip
        if s.startsWith("cmd:") and " -r" in s:
          result.add finding(
            path, 0,
            "Stub `cmd` leaves out `-r`, since testament runs binary itself (STYLE.md §6); " &
              "got `-r`.",
          )
        for key in STUB_KEYS:
          if s.startsWith(key & ":"):
            result.add finding(
              path, 0,
              "Stub leaves out keys `testament pattern` never reads (STYLE.md §6); got `" & key &
                "`.",
            )
  for i, c in code:
    if c.firstWord == "echo" and '"' notin lines[i] and not code.isUnderCondition(i):
      result.add finding(
        path, i + 1,
        "Test leaves no debug output; label report, or print under failing condition " &
          "(VIII.5); got `" & c.strip & "`.",
      )


func checkIdioms*(path, source: string): seq[Finding] =
  ## Report Nim source breaking one-line idiom of STYLE.md or Article X.5.
  let
    lines = source.splitLines
    code = source.codeOnly.splitLines
  let strict_at = lines.find(STRICT_FUNCS)
  var import_at = -1
  for i, c in code:
    if c.startsWith(IMPORT_MARK) or c.startsWith("include ") or c.startsWith("from "):
      import_at = i
      break
  if strict_at < 0:
    result.add finding(
      path, 0, "Module carries `" & STRICT_FUNCS & "` before its imports (STYLE.md §2); got none."
    )
  elif import_at >= 0 and strict_at > import_at:
    result.add finding(
      path, strict_at + 1,
      "Module carries `" & STRICT_FUNCS & "` before its imports (STYLE.md §2); got it after.",
    )
  result.add checkImports(path, code)
  result.add checkBindings(path, code)
  result.add checkPragmas(path, lines, code)
  if "/tests/" in "/" & path: result.add checkTest(path, source, lines, code)


func fixReturnResult(path, source: string): Fix =
  ## Rewrite `return result` as bare `return`, which exits with same value.
  var lines = source.split('\n')
  let code = source.codeOnly.split('\n')
  for i, c in code:
    if c.strip != RETURN_RESULT: continue
    let at = c.find(RETURN_RESULT)
    lines[i] = lines[i][0 ..< at] & "return" & lines[i][at + RETURN_RESULT.len .. ^1]
    result.fixed.add finding(path, i + 1, "return result (STYLE.md §5) fixed")
  result.source = lines.join("\n")


func sortedBracket(statement: string): string =
  ## Sort items of bracket into slots they held, so whitespace and commas stay in place.
  let
    open = statement.find('[')
    close = statement.rfind(']')
    slots = statement[open + 1 ..< close].split(',')
  var items = slots.mapIt(it.strip).filterIt(it.len > 0)
  items = items.sortedByIt(it.itemName)
  var
    k = 0
    filled: seq[string]
  for slot in slots:
    let core = slot.strip
    if core.len == 0:
      filled.add slot
      continue
    let lead = slot.len - slot.strip(leading = true, trailing = false).len
    filled.add slot[0 ..< lead] & items[k] & slot[lead + core.len .. ^1]
    inc k
  statement[0 .. open] & filled.join(",") & statement[close .. ^1]


func fixImports(path, source: string): Fix =
  ## Sort each bracket import out of order, then order each block of import lines by rank.
  var lines = source.split('\n')
  let code = source.codeOnly.split('\n')

  # Sort items in place, leaving bracket holding comment or wide result to hand.
  for span in code.importSpans:
    let items = span.target.bracketItems
    if items == items.sorted: continue
    let statement = lines[span.first .. span.last].join("\n")
    if statement != code[span.first .. span.last].join("\n"): continue
    let sorted_lines = statement.sortedBracket.split('\n')
    if sorted_lines.countIt(it.isWide) > lines[span.first .. span.last].countIt(it.isWide):
      continue
    for k, line in sorted_lines: lines[span.first + k] = line
    result.fixed.add finding(path, span.first + 1, "bracket import (X.5) fixed")

  # Reorder each block of adjacent import statements by rank, stable within rank.
  let spans = code.importSpans
  var i = 0
  while i < spans.len:
    var j = i
    while j + 1 < spans.len and spans[j + 1].first == spans[j].last + 1: inc j
    let
      block_spans = spans[i .. j]
      ranked = block_spans.sortedByIt(it.target.importRank)
    if ranked != block_spans:
      var
        rank = -1
        reordered: seq[string]
      for span in block_spans:
        let r = span.target.importRank
        if r < rank:
          result.fixed.add finding(path, span.first + 1, "import rank (X.5) fixed")
        rank = max(rank, r)
      for span in ranked: reordered.add lines[span.first .. span.last]
      for k, line in reordered: lines[spans[i].first + k] = line
    i = j + 1
  result.source = lines.join("\n")


func depthOf(code: string): int =
  ## Count brackets code line opens and leaves open; negative where it closes more.
  for c in code:
    if c in OPENERS: inc result
    elif c in CLOSERS: dec result


func continuationOf(run: BindingRun, lines, code: seq[string]): int =
  ## Find last line continuing run's last binding: open bracket, deeper indent, doc under it.
  ##   Blank line counts only where line after it continues too.
  result = run.last
  var
    depth = code[run.last].depthOf
    i = run.last + 1
  while i < lines.len:
    let
      is_code = code[i].strip.len > 0
      is_text = lines[i].strip.len > 0
    if depth > 0 or (is_code and code[i].indentOf > run.indent) or
        (not is_code and is_text and lines[i].indentOf > run.indent):
      depth += code[i].depthOf
      result = i
      inc i
    elif not is_text: inc i
    else: break


func fixBindings(path, source: string): Fix =
  ## Rewrite each run of single bindings as one keyword over bindings indented two spaces.
  ##   Last run goes first: run nested in continuation of earlier one is then rewritten before
  ##   that continuation moves, and every earlier run keeps its lines.
  result.source = source
  let runs = source.codeOnly.split('\n').bindingRuns
  for run in runs.reversed:
    let
      lines = result.source.split('\n')
      code = result.source.codeOnly.split('\n')
      kept = result.source.codeAndComments.split('\n')
      last = run.continuationOf(lines, code)
      margin = ' '.repeat(run.indent)
    var shaped = @[margin & run.keyword]
    for k in run.first .. run.last:
      let binding = lines[k][run.indent + run.keyword.len .. ^1].strip(trailing = false)
      shaped.add margin & "  " & binding
    for k in run.last + 1 .. last:
      shaped.add(if lines[k].len == 0: "" else: "  " & lines[k])

    # Leave run to hand where its lines hold long string, or reshaping makes line wide.
    var is_long_string = false
    for k in run.first .. last:
      let at = lines[k].find(LONG_STRING)
      if at >= 0 and kept[k][at] == ' ': is_long_string = true
    let is_widened = shaped.countIt(it.isWide) > lines[run.first .. last].countIt(it.isWide)
    if is_long_string or is_widened: continue
    result.source = (lines[0 ..< run.first] & shaped & lines[last + 1 .. ^1]).join("\n")
    result.fixed.insert(finding(path, run.first + 1, "single bindings (X.5) fixed"), 0)


func fixStrictFuncs(path, source: string): Fix =
  ## Insert missing `strictFuncs` where X.6 puts directives, one blank line on each side.
  result.source = source
  let lines = source.split('\n')
  if lines.find(STRICT_FUNCS) >= 0: return
  let code = source.codeOnly.split('\n')
  var at = -1
  for i, c in code:
    # Skip text, directives and testament header; `{.push.}` opens body of foreign bindings.
    let is_directive = c.startsWith("{.") and not c.startsWith("{.push")
    if c.strip.len == 0 or is_directive or lines[i].startsWith(TESTAMENT_HEADER): continue
    at = i
    break
  var shaped: seq[string]
  if at >= 0:
    shaped = lines[0 ..< at]
    if at > 0 and lines[at - 1].len > 0: shaped.add ""
    shaped.add [STRICT_FUNCS, ""]
    shaped.add lines[at .. ^1]
  else:
    # Module without code takes directive after its last line of text.
    var last = lines.len
    while last > 0 and lines[last - 1].len == 0: dec last
    shaped = lines[0 ..< last]
    if last > 0: shaped.add ""
    shaped.add STRICT_FUNCS
    shaped.add lines[last .. ^1]
    if last == lines.len: shaped.add ""
  result.source = shaped.join("\n")
  result.fixed.add finding(path, 0, "strictFuncs (STYLE.md §2) fixed")


func fixIdioms*(path, source: string): Fix =
  ## Rewrite Nim source so each idiom with one mechanical fix holds; report each rewrite.
  ##   Fixers that keep line count run first, so each reports lines of source as given.
  result.source = source
  for fixer in [fixReturnResult, fixImports, fixBindings, fixStrictFuncs]:
    result = result.chain(fixer(path, result.source))


func checkMachinePaths*(path, source: string): seq[Finding] =
  ## Report line naming path of one machine (CONTRIBUTOR.md, System).
  let lines = source.splitLines
  for i, line in lines:
    for prefix in MACHINE_PATHS:
      if prefix in line:
        result.add finding(
          path, i + 1,
          "Source names path of one machine; take location from environment " &
            "(CONTRIBUTOR.md, System); got `" & prefix & "`.",
        )


func isFlagSet(config, flag: string): bool =
  ## Decide whether text of `tsconfig.json` sets `"flag": true`.
  let at = config.find("\"" & flag & "\"")
  if at < 0: return
  var k = at + flag.len + 2
  while k < config.len and config[k] in {' ', '\t', '\n', '\r', ':'}: inc k
  config.continuesWith("true", k)


func checkTsconfig*(path, config: string): seq[Finding] =
  ## Report flag `tsconfig.json` leaves unset (CONTRIBUTOR.md, TypeScript).
  for flag in TYPESCRIPT_FLAGS:
    if not config.isFlagSet(flag):
      result.add finding(
        path, 0,
        "`tsconfig.json` sets `" & flag & "` to `true` (CONTRIBUTOR.md, TypeScript); got none.",
      )
