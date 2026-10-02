## Enforce idioms of source that one line, or one header, shows (STYLE.md §2, §5, §6; Article
##   VIII.5, X.5; CONTRIBUTOR.md, System and TypeScript).
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
##   Cost: text scanner, never parser. Import under `when` and `from … import` are unread.
##   Cost: seeded `initRand` passes as `randomize(0)` does, since both fix sequence; STYLE
##     names `randomize(0)`, and reading holds which form project takes.
##   Cost: debug output is told from report by its shape alone: labelled `echo`, i.e. one
##     holding string literal, passes as report of measured figure, and conditional `echo`
##     passes as failure diagnostic. Labelled debug output then holds by reading.
##   Cost: `tsconfig.json` is read as text, since TypeScript admits comments that
##     `std/json` refuses; flag set through `extends` reads as absent.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, strutils]
import ./[findings, names]


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


func bracketItems(text: string): seq[string] =
  ## Read module names inside brackets of `prefix/[a, b {.all.}]`, pragma dropped.
  let
    open = text.find('[')
    close = text.rfind(']')
  if open < 0 or close < open: return
  for item in text[open + 1 ..< close].split(','):
    let name = item.strip.split(' ')[0]
    if name.len > 0: result.add name


func checkImports(path: string, code: seq[string]): seq[Finding] =
  ## Report bracket import out of order, and import ranked below one before it.
  var
    rank = -1
    i = 0
  while i < code.len:
    if not code[i].startsWith("import "):
      inc i
      continue
    var text = code[i]
    let one = i + 1
    while text.count('[') > text.count(']') and i + 1 < code.len:
      inc i
      text.add code[i]
    let
      target = text[7 .. ^1].strip
      items = text.bracketItems
    var sorted_items = items
    sorted_items.sort
    if items != sorted_items:
      result.add finding(
        path, one, "Bracket import is alphabetised (X.5); got `" & items.join(", ") & "`."
      )
    let r = target.importRank
    if r < rank:
      result.add finding(
        path, one,
        "Standard library comes first, then packages, then local modules (X.5); got `" &
          target.split('[')[0] & "`.",
      )
    rank = max(rank, r)
    inc i


func isSingleBinding(line: string): bool =
  ## Decide whether line opens binding naming value on same line, e.g. `let x = 1`.
  let word = line.firstWord
  word in BINDING_KEYWORDS and line.strip.len > word.len and line.strip[word.len] == ' '


func checkBindings(path: string, code: seq[string]): seq[Finding] =
  ## Report run of consecutive single bindings of one keyword at one indent, once per run.
  var i = 0
  while i + 1 < code.len:
    let
      a = code[i]
      b = code[i + 1]
    if a.isSingleBinding and b.isSingleBinding and a.firstWord == b.firstWord and
        a.indentOf == b.indentOf:
      result.add finding(
        path, i + 1,
        "Consecutive single bindings share one keyword (X.5); got `" & a.firstWord & "` twice.",
      )
      var j = i + 1
      while j + 1 < code.len and code[j + 1].isSingleBinding and
          code[j + 1].firstWord == a.firstWord and code[j + 1].indentOf == a.indentOf:
        inc j
      i = j + 1
    else: inc i


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
    if s == "return result":
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
    if c.startsWith("import ") and
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
    let open = source.find("discard \"\"\"")
    if open < 0:
      result.add finding(
        path, 0, "Test stub carries testament header (STYLE.md §6); got none."
      )
    else:
      let
        close = source.find("\"\"\"", open + 11)
        header = if close > open: source[open + 11 ..< close] else: ""
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
    if c.startsWith("import ") or c.startsWith("include ") or c.startsWith("from "):
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
