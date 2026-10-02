## Enforce idioms of source that one line, or one header, shows (STYLE.md §2, §5, §6; Article
##   VIII.5, X.5, X.10; CONTRIBUTOR.md, System and TypeScript); and fix each of these that has
##   one mechanical fix (`koch fix`).
##   Nim rules read code-only view (`names.codeOnly`), so string and comment never trip them:
##   - `{.experimental: "strictFuncs".}` stands in this exact form before first import, in
##     every module, suite included (§2).
##   - Bracket import is alphabetised, and standard library comes before packages, which
##     come before local modules (X.5, §5).
##   - Adjacent imports of one directory share one bracket, and bracket of one module drops
##     it (X.5, §5): `checkImportBrackets`, outside static pass until projects run fix.
##   - Pragma list of declaration and `export` list are alphabetised (X.10): `checkLists`,
##     read on tokens (`tokens.nim`), outside static pass until projects run fix.
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
##   - Adjacent imports of one directory merge into one bracket at first one's line, items
##     alphabetised and `{.all.}` kept; bracket of one module drops its bracket.
##   - List out of order has its items sorted into slots they held, `key: value` item whole.
##   - Run of single bindings becomes keyword alone, then each binding indented two spaces;
##     lines continuing last binding (open bracket, deeper indent, doc under it) move too.
##   - Missing `strictFuncs` goes where X.6 puts directives: before first code line that is
##     neither directive nor testament header, i.e. after header docs and design notes. One
##     standing after first import moves there; blank lines above it go with it where blank
##     lines stand below it, so code after it keeps blank lines it had.
##   - `return result` ending routine that holds `result`, at its body's own indent, goes, with
##     blank lines opening its paragraph; inside branch, or before more body, it becomes bare
##     `return`. Both exit with same value, and §5 keeps `return` for early exit alone.
##   Fixer never writes line width check reports (`form.isWide`); rewrite that would leaves
##     its lines and finding for hand. Fixer moving lines records where each came from, so
##     `chain` reports every later rewrite at line of source as given.
##   No fixer: import ranked low across lines that are not imports, since where it lands and
##     what blank lines surround it are both choices; bracket holding comment, since comment
##     belongs to item or to slot; run whose last binding opens long string, since indenting
##     its lines changes string; `{.used.}` consumer, `{.push.}` scope, random seed, stub
##     header, debug output, machine path and TypeScript flags, since each needs knowledge
##     text does not hold.
##   No fixer, and check silent: import with `except`, `as`, pragma but `{.all.}`, comment or
##     string, statement spanning lines, and imports apart across blank line, since merging
##     them is choice; list whose order may mean, i.e. pragma statement opening line and list
##     holding user pragma, which may be macro applied in order written; list whose order
##     case decides, as `Tree`, `projectDirectories` by code point and reverse by alphabet,
##     which waits on Architect's ruling.
##   No fixer for `return result` whose place reads no one fix: routine's only statement, whose
##     body deletion would empty; line carrying comment, which would lose its line; line after
##     comment, which would then name nothing; end of template or macro, which returns from
##     its caller; opener scanner cannot name, such as lambda bound to `let`.
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
import ./[findings, form, names, tokens]


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

  ReturnPlace {.pure.} = enum
    ## Define where `return result` stands, which decides its one fix.
    Ending  ## Last statement of routine holding `result`, at its body's own indent: line goes.
    Early  ## Inside branch, or with more body after it: bare `return` exits with same value.
    Unread  ## Place scanner cannot name, or whose fix is not one: line stays.

  Consolidation = object
    ## Define adjacent imports of one directory to merge, or bracket of one module to drop.
    lines: seq[int]  ## Zero-based line of each statement; first one takes merged statement.
    prefix: string  ## Directory every statement imports from, e.g. `std/`.
    items: seq[string]  ## Modules, pragma kept, alphabetised once all are read.
    statement: string  ## Statement standing in their place.

  Disorder = object
    ## Define list language leaves unordered, written out of alphabetical order.
    line: int  ## Zero-based line list stands on.
    first: int  ## Byte offset of first item.
    after: int  ## Byte offset after last item.
    sorted: string  ## Items alphabetised into slots they held, separators kept.
    got: string  ## Items as written.


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
  RESULT_ROUTINES = ["converter", "func", "method", "proc"]
    ## Routines holding implicit `result`; template and macro return from their caller.
  TESTAMENT_HEADER = "discard \"\"\""
    ## Opening of stub's testament header, which stands before module's header docs.
  LONG_STRING = "\"\"\""
    ## Delimiter of string spanning lines.
  OPENERS = {'(', '[', '{'}
    ## Brackets opening span that continues line.
  CLOSERS = {')', ']', '}'}
    ## Brackets closing such span.
  ALL_PRAGMA = "{.all.}"
    ## Pragma bracket item may carry (STYLE.md §5); any other keeps its import apart.
  PRAGMAS_BUILT_IN = [
    "acyclic", "align", "asmnostackframe", "base", "bitsize", "booldefine", "borrow", "bycopy",
    "byref", "callsite", "cdecl", "closure", "codegendecl", "compilerproc", "compiletime",
    "completestruct", "constructor", "core", "cppnonpod", "cursor", "define", "delegator",
    "deprecated", "dirty", "discardable", "dynlib", "effectsof", "enforcenoraises", "ensures",
    "error", "explain", "exportc", "exportcpp", "exportnims", "extern", "fastcall", "final",
    "forbids", "gcsafe", "gensym", "global", "goto", "guard", "header", "importc",
    "importcompilerproc", "importcpp", "importjs", "importobjc", "incompletestruct",
    "inheritable", "inject", "inline", "intdefine", "liftlocals", "linetrace", "locks", "magic",
    "member", "nimcall", "noalias", "noconv", "nodecl", "nodestroy", "noinit", "noinline",
    "nonreloadable", "noreturn", "nosideeffect", "nosinks", "package", "packed", "partial",
    "procvar", "pure", "quirky", "raises", "redefine", "register", "requires", "requiresinit",
    "safecall", "sendable", "shallow", "sideeffect", "size", "stacktrace", "stdcall",
    "strdefine", "syscall", "systemraisesdefect", "tags", "thiscall", "thread", "threadvar",
    "unchecked", "union", "used", "varargs", "virtual", "volatile",
  ]
    ## Pragmas compiler gives declarations (`pragmas.nim`, `procPragmas` to `fieldPragmas`),
    ##   lowercase with underscores dropped, as Nim compares names. Order among them moves
    ##   nothing; user pragma may be macro, applied in order written, so list holding one stays.


func firstWord(text: string): string =
  ## Read leading identifier of stripped text.
  let s = text.strip
  var k = 0
  while k < s.len and s[k] in {'a' .. 'z', 'A' .. 'Z', '0' .. '9', '_'}: inc k
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
        path,
        span.first + 1,
        "Bracket import is alphabetised (X.5); got `" & items.join(", ") & "`.",
      )
    let r = span.target.importRank
    if r < rank:
      result.add finding(
        path,
        span.first + 1,
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
      path,
      run.first + 1,
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


func checkPragmas(path: string; lines, code: seq[string]): seq[Finding] =
  ## Report `{.used.}` without comment, and `{.push.}` over block holding no foreign binding.
  for i, c in code:
    let s = c.strip
    if "used" in c.pragmaNames and s != "{.used.}" and
        lines[i].find('#', c.strip(leading = false).len) < 0:
      result.add finding(
        path,
        i + 1,
        "`{.used.}` carries comment naming its consumer (STYLE.md §2); got none.",
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
          path,
          i + 1,
          "`{.push.}` stands only over foreign bindings, which `{.pop.}` closes (STYLE.md §2); " &
            "got `" & s & "`.",
        )
    if s == RETURN_RESULT:
      result.add finding(
        path,
        i + 1,
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


func checkTest(path, source: string; lines, code: seq[string]): seq[Finding] =
  ## Report unseeded random suite, stub header breaking §6, and `echo` of debug shape.
  if code.isRandomImported and not code.join("\n").isSeeded:
    result.add finding(
      path,
      0,
      "Suite seeds `std/random`, as `randomize(0)` does (STYLE.md §6); got no seed.",
    )
  let
    parts = path.split('/')
    is_stub = parts.len >= 2 and parts[^2] == "tests" and parts[^1].startsWith("test_")
  if is_stub:
    let open = source.find(TESTAMENT_HEADER)
    if open < 0:
      result.add finding(path, 0, "Test stub carries testament header (STYLE.md §6); got none.")
    else:
      let
        close = source.find(LONG_STRING, open + TESTAMENT_HEADER.len)
        header = if close > open: source[open + TESTAMENT_HEADER.len ..< close] else: ""
      for line in header.splitLines:
        let s = line.strip
        if s.startsWith("cmd:") and " -r" in s:
          result.add finding(
            path,
            0,
            "Stub `cmd` leaves out `-r`, since testament runs binary itself (STYLE.md §6); " &
              "got `-r`.",
          )
        for key in STUB_KEYS:
          if s.startsWith(key & ":"):
            result.add finding(
              path,
              0,
              "Stub leaves out keys `testament pattern` never reads (STYLE.md §6); got `" & key &
                "`.",
            )
  for i, c in code:
    if c.firstWord == "echo" and '"' notin lines[i] and not code.isUnderCondition(i):
      result.add finding(
        path,
        i + 1,
        "Test leaves no debug output; label report, or print under failing condition " &
          "(VIII.5); got `" & c.strip & "`.",
      )


func firstImport(code: seq[string]): int =
  ## Find zero-based line of first `import`, `include` or `from` at module level; `-1` if none.
  for i, c in code:
    if c.startsWith(IMPORT_MARK) or c.startsWith("include ") or c.startsWith("from "): return i
  -1


func checkIdioms*(path, source: string): seq[Finding] =
  ## Report Nim source breaking one-line idiom of STYLE.md or Article X.5.
  let
    lines = source.splitLines
    code = source.codeOnly.splitLines
  let (strict_at, import_at) = (lines.find(STRICT_FUNCS), code.firstImport)
  if strict_at < 0:
    result.add finding(
      path,
      0,
      "Module carries `" & STRICT_FUNCS & "` before its imports (STYLE.md §2); got none.",
    )
  elif import_at >= 0 and strict_at > import_at:
    result.add finding(
      path,
      strict_at + 1,
      "Module carries `" & STRICT_FUNCS & "` before its imports (STYLE.md §2); got it after.",
    )
  result.add checkImports(path, code)
  result.add checkBindings(path, code)
  result.add checkPragmas(path, lines, code)
  if "/tests/" in "/" & path: result.add checkTest(path, source, lines, code)


func placeOf(lines, code: seq[string]; i: int): ReturnPlace =
  ## Read where `return result` on line `i` stands, from line opening its block.
  ##   Opener is nearest code line above at smaller indent. `:` opens branch; `=` opens
  ##   routine body where routine keyword stands on that line, or on line opening signature
  ##   that its `)` closes. Any other opener is unread.
  let indent = code[i].indentOf
  var opener = i - 1
  while opener >= 0 and (code[opener].strip.len == 0 or code[opener].indentOf >= indent):
    dec opener
  if opener < 0: return ReturnPlace.Unread
  let head = code[opener].strip
  if head.endsWith(":"): return ReturnPlace.Early
  if not head.endsWith("="): return ReturnPlace.Unread
  var signature = opener
  if head.startsWith(")"):
    signature = opener - 1
    while signature >= 0 and
        (code[signature].strip.len == 0 or code[signature].indentOf > code[opener].indentOf):
      dec signature
  if signature < 0 or code[signature].firstWord notin RESULT_ROUTINES:
    return ReturnPlace.Unread

  # Read what follows in body, and what ending line would leave behind.
  var after = i + 1
  while after < code.len and code[after].strip.len == 0: inc after
  if after < code.len and code[after].indentOf >= indent: return ReturnPlace.Early
  let
    has_statement = (opener + 1 ..< i).toSeq.anyIt(code[it].strip.len > 0)
    has_comment = lines[i].strip != RETURN_RESULT
    is_after_comment = lines[i - 1].strip.len > 0 and code[i - 1].strip.len == 0
  if not has_statement or has_comment or is_after_comment: ReturnPlace.Unread
  else: ReturnPlace.Ending


func fixReturnResult(path, source: string): Fix =
  ## Delete `return result` ending routine, and rewrite earlier one as bare `return`.
  ##   Both exit with same value, and STYLE.md §5 keeps `return` for early exit alone.
  let
    lines = source.split('\n')
    code = source.codeOnly.split('\n')
  var shaped: seq[string]
  for i, line in lines:
    let place = if code[i].strip == RETURN_RESULT: placeOf(lines, code, i) else: ReturnPlace.Unread
    case place
    of ReturnPlace.Unread:
      shaped.add line
      result.origin.add i + 1
      continue
    of ReturnPlace.Ending:
      # Blank lines opening its paragraph go with it.
      while shaped.len > 0 and shaped[^1].len == 0:
        shaped.setLen(shaped.len - 1)
        result.origin.setLen(result.origin.len - 1)
    of ReturnPlace.Early:
      let at = code[i].find(RETURN_RESULT)
      shaped.add line[0 ..< at] & "return" & line[at + RETURN_RESULT.len .. ^1]
      result.origin.add i + 1
    result.fixed.add finding(path, i + 1, "return result (STYLE.md §5)")
  result.source = shaped.join("\n")
  if result.origin.len == lines.len: result.origin.setLen(0)


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
    result.fixed.add finding(path, span.first + 1, "bracket import (X.5)")

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
          result.fixed.add finding(path, span.first + 1, "import rank (X.5)")
        rank = max(rank, r)
      for span in ranked: reordered.add lines[span.first .. span.last]
      for k, line in reordered: lines[spans[i].first + k] = line
    i = j + 1
  result.source = lines.join("\n")


func importParts(target: string): tuple[prefix: string, items: seq[string]] =
  ## Split import target into directory and items: `std/os` gives `std/` and `os`, and
  ##   `./[a, b {.all.}]` gives `./` and both items, pragma kept. Empty where target names no
  ##   directory, holds `except`, `as` or second target, or item carries pragma but `{.all.}`.
  let open = target.find('[')
  var prefix, body: string
  if open >= 0:
    if not target.endsWith("]"): return
    (prefix, body) = (target[0 ..< open], target[open + 1 ..< target.high])
  else:
    let
      path = target.itemName
      slash = path.rfind('/')
    if slash < 0: return
    (prefix, body) = (path[0 .. slash], path[slash + 1 .. ^1] & target[path.len .. ^1])
  if not prefix.endsWith("/") or ',' in prefix or ' ' in prefix: return
  for item in body.split(','):
    let core = item.strip
    if core.len == 0: continue
    let rest = core[core.itemName.len .. ^1].strip
    if '/' in core.itemName or (rest.len > 0 and rest != ALL_PRAGMA): return
    result.items.add core
  if result.items.len > 0: result.prefix = prefix


func consolidations(lines, code: seq[string]): seq[Consolidation] =
  ## Find each set of adjacent imports of one directory, and each bracket of one module.
  ##   Imports are read in blocks of adjacent statements, as rank reads them; statement
  ##   spanning lines, or holding comment or string, stays apart.
  let spans = code.importSpans
  var i = 0
  while i < spans.len:
    var j = i
    while j + 1 < spans.len and spans[j + 1].first == spans[j].last + 1: inc j
    var prefixes: seq[string]
    for span in spans[i .. j]:
      if span.first != span.last or lines[span.first] != code[span.first]: continue
      let (prefix, items) = span.target.importParts
      if prefix.len == 0: continue
      let at = prefixes.find(prefix)
      if at < 0:
        prefixes.add prefix
        result.add Consolidation(lines: @[span.first], prefix: prefix, items: items)
      else:
        let k = result.len - prefixes.len + at
        result[k].lines.add span.first
        for item in items:
          if item notin result[k].items: result[k].items.add item
    i = j + 1

  # Keep those whose statement changes and fits its line.
  result = result.filterIt(it.lines.len > 1 or (it.items.len == 1 and '[' in lines[it.lines[0]]))
  for c in result.mitems:
    c.items = c.items.sortedByIt(it.itemName)
    c.statement = IMPORT_MARK & c.prefix &
      (if c.items.len == 1: c.items[0] else: "[" & c.items.join(", ") & "]")
  result = result.filterIt(not it.statement.isWide)


func checkImportBrackets*(path, source: string): seq[Finding] =
  ## Report adjacent imports of one directory standing apart, and bracket of one module (X.5,
  ##   STYLE.md §5).
  ##   Named by its suite and `fixes.nim` alone until static pass calls it (`fixes.nim`).
  for c in consolidations(source.split('\n'), source.codeOnly.split('\n')):
    let message =
      if c.lines.len > 1:
        "Imports of one directory share one bracket (X.5); got `" & c.prefix & "` in `" &
          $c.lines.len & "` statements."
      else: "Bracket of one module drops its bracket (STYLE.md §5); got `" & c.prefix & "[" &
        c.items[0] & "]`."
    result.add finding(path, c.lines[0] + 1, message)


func fixConsolidations(path, source: string): Fix =
  ## Merge each set of adjacent imports of one directory into one bracket, at first one's line;
  ##   bracket of one module drops its bracket.
  let
    lines = source.split('\n')
    found = consolidations(lines, source.codeOnly.split('\n'))
  var
    shaped: seq[string]
    dropped: seq[int]
  for c in found:
    dropped.add c.lines[1 .. ^1]
    result.fixed.add finding(path, c.lines[0] + 1, "import brackets (X.5)")
  for i, line in lines:
    if i in dropped: continue
    var statement = line
    for c in found:
      if c.lines[0] == i: statement = c.statement
    shaped.add statement
    result.origin.add i + 1
  result.source = shaped.join("\n")
  if dropped.len == 0: result.origin.setLen(0)


func depthOf(code: string): int =
  ## Count brackets code line opens and leaves open; negative where it closes more.
  for c in code:
    if c in OPENERS: inc result
    elif c in CLOSERS: dec result


func continuationOf(run: BindingRun; lines, code: seq[string]): int =
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
  var origin = toSeq(1 .. source.count('\n') + 1)
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
    origin = origin[0 ..< run.first] & @[0] & origin[run.first .. ^1]  # Keyword line inserted.
    result.fixed.insert(finding(path, run.first + 1, "single bindings (X.5)"), 0)
  if result.fixed.len > 0: result.origin = origin


func fixStrictFuncs(path, source: string): Fix =
  ## Insert missing `strictFuncs` where X.6 puts directives, one blank line on each side; move
  ##   one standing after first import there, as check reads it.
  ##   Line moved takes blank lines above it along where blank lines stand below it too, so
  ##     code after it keeps blank lines it had.
  result.source = source
  var
    lines = source.split('\n')
    origin = toSeq(1 .. lines.len)
    reported = 0
  let present = lines.find(STRICT_FUNCS)
  if present >= 0:
    let import_at = source.codeOnly.split('\n').firstImport
    if import_at < 0 or present < import_at: return
    var first = present
    if present + 1 < lines.len and lines[present + 1].len == 0:
      while first > 0 and lines[first - 1].len == 0: dec first
    lines = lines[0 ..< first] & lines[present + 1 .. ^1]
    origin = origin[0 ..< first] & origin[present + 1 .. ^1]
    reported = present + 1
  let code = lines.join("\n").codeOnly.split('\n')
  var at = -1
  for i, c in code:
    # Skip text, directives and testament header; `{.push.}` opens body of foreign bindings.
    let is_directive = c.startsWith("{.") and not c.startsWith("{.push")
    if c.strip.len == 0 or is_directive or lines[i].startsWith(TESTAMENT_HEADER): continue
    at = i
    break

  # Cut before that line; module without code takes directive after its last line of text.
  var cut = at
  if at < 0:
    cut = lines.len
    while cut > 0 and lines[cut - 1].len == 0: dec cut
  var inserted: seq[string]
  if cut > 0 and lines[cut - 1].len > 0: inserted.add ""
  inserted.add STRICT_FUNCS
  if at >= 0 or cut == lines.len: inserted.add ""
  result.source = (lines[0 ..< cut] & inserted & lines[cut .. ^1]).join("\n")
  result.origin = origin[0 ..< cut] & inserted.mapIt(0) & origin[cut .. ^1]
  result.fixed.add finding(path, reported, "strictFuncs (STYLE.md §2)")


func disorders(source: string): seq[Disorder] =
  ## Find each pragma list of declaration, and each `export` list, out of alphabetical order.
  ##   List on one line alone is read. Pragma statement opening line (`{.push.}`, `{.pop.}`,
  ##   `{.emit.}`, `{.experimental.}`) stays, and so does list holding user pragma, `except`,
  ##   or items whose order case decides, where alphabet and code points disagree.
  let
    tokens = source.tokens
    partners = tokens.partners
  for k, t in tokens:
    let is_line_first = k == 0 or tokens[k - 1].lastLine(source) < t.line
    var
      spans: seq[(int, int)]
      stop = -1
    if t.spelling(source) == "{." and not is_line_first and partners[k] > k and
        tokens[partners[k]].line == t.line:
      stop = partners[k]
    elif t.spelling(source) == "export" and is_line_first:
      stop = k + 1
      while stop < tokens.len and tokens[stop].line == t.line: inc stop
      if tokens[stop - 1].kind == TokenKind.Comma: continue
    else: continue

    # Split items at commas outside nested brackets.
    var m = k + 1
    while m < stop:
      let first = m
      while m < stop and tokens[m].kind != TokenKind.Comma:
        if tokens[m].kind == TokenKind.Open and partners[m] > m: m = partners[m]
        inc m
      spans.add (first, m - 1)
      inc m
    let names = spans.mapIt(tokens[it[0]].spelling(source))
    if spans.len < 2 or spans.anyIt(it[1] < it[0]): continue
    if t.spelling(source) == "{.":
      if names.anyIt(it.toLowerAscii.replace("_", "") notin PRAGMAS_BUILT_IN): continue
    elif toSeq(k ..< stop).anyIt(tokens[it].spelling(source) == "except"): continue

    # Sort item texts into slots they held; leave list whose order case decides.
    let
      texts = spans.mapIt(source[tokens[it[0]].first ..< tokens[it[1]].after])
      keys = if t.spelling(source) == "{.": names else: texts
      by_alphabet = toSeq(0 ..< texts.len).sortedByIt((keys[it].toLowerAscii, it))
      by_code_point = toSeq(0 ..< texts.len).sortedByIt((keys[it], it))
    if by_alphabet != by_code_point or by_alphabet == toSeq(0 ..< texts.len): continue
    var sorted = texts[by_alphabet[0]]
    for i in 1 ..< spans.len:
      sorted.add source[tokens[spans[i - 1][1]].after ..< tokens[spans[i][0]].first]
      sorted.add texts[by_alphabet[i]]
    result.add Disorder(
      line: t.line,
      first: tokens[spans[0][0]].first,
      after: tokens[spans[^1][1]].after,
      sorted: sorted,
      got: names.join(", "),
    )


func checkLists*(path, source: string): seq[Finding] =
  ## Report pragma list of declaration, or `export` list, out of alphabetical order (X.10).
  ##   Named by its suite and `fixes.nim` alone until static pass calls it (`fixes.nim`).
  for d in source.disorders:
    result.add finding(
      path,
      d.line + 1,
      "List language leaves unordered is alphabetised (X.10); got `" & d.got & "`.",
    )


func fixLists(path, source: string): Fix =
  ## Alphabetise each list check reports, last first, so earlier offsets hold; width is kept.
  let found = source.disorders
  result.source = source
  for d in found.reversed:
    result.source = result.source[0 ..< d.first] & d.sorted & result.source[d.after .. ^1]
  for d in found: result.fixed.add finding(path, d.line + 1, "unordered list (X.10)")


func fixIdioms*(path, source: string): Fix =
  ## Rewrite Nim source so each idiom with one mechanical fix holds; report each rewrite.
  ##   `chain` traces each report through lines earlier fixers moved, to source as given.
  ##   Brackets merge after rank orders blocks, so merged statement takes first rank's place.
  result.source = source
  let fixers = [
    fixReturnResult, fixImports, fixConsolidations, fixBindings, fixStrictFuncs, fixLists,
  ]
  for fixer in fixers: result = result.chain(fixer(path, result.source))


func checkMachinePaths*(path, source: string): seq[Finding] =
  ## Report line naming path of one machine (CONTRIBUTOR.md, System).
  let lines = source.splitLines
  for i, line in lines:
    for prefix in MACHINE_PATHS:
      if prefix in line:
        result.add finding(
          path,
          i + 1,
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
        path,
        0,
        "`tsconfig.json` sets `" & flag & "` to `true` (CONTRIBUTOR.md, TypeScript); got none.",
      )
