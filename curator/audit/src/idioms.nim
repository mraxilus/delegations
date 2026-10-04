## Enforce idioms of source that one line, or one header, shows and no fixer reaches (STYLE.md
##   §2, §6; Article VIII.5; CONTRIBUTOR.md, System and TypeScript); and compose them with idioms
##   knoller fixes (`idioms.nim` there), as static pass reads both.
##   Nim rules read code-only view (`views.codeOnly`), so string and comment never trip them:
##   - `{.used.}` carries trailing comment naming its consumer (§2).
##   - `{.push.}` stands only over block of foreign bindings, which `{.pop.}` closes (§2).
##   Under `tests/` alone:
##   - suite importing `std/random` seeds it (§6);
##   - stub `tests/test_*.nim` carries testament header (§6);
##   - `echo` of value without label, outside condition, is debug output (VIII.5).
##   Every kind but Markdown: path of one machine is finding (CONTRIBUTOR.md, System).
##   `tsconfig.json` sets three flags TypeScript section names, each to `true`.
##   No fixer: `{.used.}` consumer, `{.push.}` scope, random seed, missing stub header, debug
##     output, machine path and TypeScript flags, since each needs knowledge text does not hold.
##
##   Cost: seeded `initRand` passes as `randomize(0)` does, since both fix sequence; STYLE
##     names `randomize(0)`, and reading holds which form project takes.
##   Cost: debug output is told from report by its shape alone: labelled `echo`, i.e. one
##     holding string literal, passes as report of measured figure, and conditional `echo`
##     passes as failure diagnostic. Labelled debug output then holds by reading.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils]
import ../../knoller/src/knoller
import ./findings



const
  MACHINE_PATHS* = ["/home/", "/Users/", "C:\\"]
    ## Prefixes naming paths of one machine (CONTRIBUTOR.md, System).
  TYPESCRIPT_FLAGS* = ["exactOptionalPropertyTypes", "noUncheckedIndexedAccess", "strict"]
    ## Compiler options `tsconfig.json` sets to `true` (CONTRIBUTOR.md, TypeScript).
  CONDITIONS = ["case", "elif", "else", "except", "if", "of", "when"]
    ## Openers making `echo` beneath them conditional, i.e. failure diagnostic.
  FOREIGN_MARKS = ["dynlib", "header:", "importc", "importcpp", "importjs"]
    ## Pragmas marking foreign bindings, which alone may stand under `{.push.}`.


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
  ## Report unseeded random suite, stub lacking testament header, and `echo` of debug shape.
  if code.isRandomImported and not code.join("\n").isSeeded:
    result.add finding(
      path,
      0,
      "Suite seeds `std/random`, as `randomize(0)` does (STYLE.md §6); got no seed.",
    )
  if path.isStub and source.find(TESTAMENT_HEADER) < 0:
    result.add finding(path, 0, "Test stub carries testament header (STYLE.md §6); got none.")
  for i, c in code:
    if c.firstWord == "echo" and '"' notin lines[i] and not code.isUnderCondition(i):
      result.add finding(
        path,
        i + 1,
        "Test leaves no debug output; label report, or print under failing condition " &
          "(VIII.5); got `" & c.strip & "`.",
      )


func checkIdioms*(path, source: string): seq[Finding] =
  ## Report Nim source breaking one-line idiom of STYLE.md or Article X.5: those knoller fixes,
  ##   then those no fixer reaches.
  let
    lines = source.splitLines
    code = source.codeOnly.splitLines
  result = checkStrictFuncs(path, lines, code).findingsOf
  result.add checkImports(path, code).findingsOf
  result.add checkBindings(path, code).findingsOf
  result.add checkPragmas(path, lines, code)
  result.add checkReturns(path, code).findingsOf
  if "/tests/" in "/" & path:
    result.add checkTest(path, source, lines, code)
    result.add checkStubKeys(path, source).findingsOf


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
