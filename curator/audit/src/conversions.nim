## Enforce form of conversion call STYLE.md §5 gives, and fix it (`koch fix`): `to<Target>`
##   takes its plain subject first (`b.toDigits`), and type conversion is prefix call
##   (`Grade(x)`, never `x.Grade`).
##   `to<Target>` call: one argument, on one line, callee `to` and capital, neither generic
##     (`toX[T](y)`) nor already method call. Argument is plain: name, then any call, index or
##     field glued after it (`a.b(c)[i]`). Compound argument (`toMultivector(a + b)`, `-v`,
##     literal) stays prefix call, so no parentheses hide it (STYLE.md §5). Call followed by
##     bracket glued after it stays too, since `y.toX(z)` and `y.toX[T]` read otherwise.
##   Rewrite moves no reading: `toX(y)` and `y.toX` are one call, and `.` binds tighter than
##     any prefix operator before it.
##   Type conversion `x.T`: text cannot tell it from field or module path (`rigid3.Point`,
##     `Kind.Nim`), so compiler's semantic pass decides (`symbols.nim`). Candidate is name after
##     `.` glued to receiver, builtin type or capitalised, whose receiver is neither capitalised
##     name nor module file imports. It converts where name resolves to type, and receiver to
##     value: its last name resolves to variable, constant, parameter, field, enum member or
##     routine, or it ends on bracket or literal. Receiver is name with calls, indexes and fields
##     glued after it, or bracket group; `x.T` becomes `T(x)`, `.` binding tighter than any
##     prefix operator before it, and parenthesised receiver gives call its parentheses
##     (`(a + b).float` becomes `float(a + b)`), tuple aside. Conversion inside receiver of
##     another nests (`x.float.int` becomes `int(float(x))`).
##   Checks and fixers share one reading each (`targets`, `conversions`), so each rule is
##     written once (Article II.1).
##
##   No fixer, check silent: conversion followed by bracket glued after it (`x.T(y)`, two
##     arguments), receiver spanning lines, and name in file semantic pass cannot compile.
##   Cost: `to<Target>` text reads no symbol, so field named as routine (`to_x`) would capture
##     method call; tree proof compares symbol each call resolves to, before and after.
##   Cost: conversion inside `template` resolves nothing, since template body is not checked,
##     and stays to hand.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, sets, strutils, tables]
import ../../knoller/src/knoller
import ./[findings, form, rewrites, spacing, symbols]


type
  Target = object  ## Define one `to<Target>` call to write subject first.
    line: int  ## Zero-based line.
    first: int  ## Byte offset of callee.
    after: int  ## Byte offset after closing parenthesis.
    shaped: string  ## Call as rule writes it: argument, `.`, callee.
    got: string  ## Call as written.

  Candidate = object  ## Define `x.T` text cannot settle: receiver, dot and type name tokens.
    first: int  ## Index of receiver's first token.
    last: int  ## Index of receiver's last token.
    dot: int  ## Index of `.`.
    name: int  ## Index of type name.

  Conversion = object  ## Define `x.T` semantic pass settles: line, edits writing `T(x)`.
    line: int  ## Zero-based line of `.`.
    edits: seq[Edit]
    got: string  ## Conversion as written.


const
  PASSES_MAX = 8  ## Passes target fixer takes at most; each writes calls nesting none.
  BUILTIN_TYPES = [
    "bool", "byte", "cchar", "cdouble", "cfloat", "char", "cint", "clong", "clonglong",
    "cshort", "csize_t", "cstring", "cuint", "culong", "float", "float32", "float64", "int",
    "int16", "int32", "int64", "int8", "Natural", "Positive", "string", "uint", "uint16",
    "uint32", "uint64", "uint8",
  ]
    ## Lowercase types `system` declares; capitalised name is candidate on its case alone.
  TYPE_KINDS = ["skType", "skGenericParam"]  ## Symbol kinds conversion name resolves to.
  VALUE_KINDS = [
    "skConst", "skConverter", "skEnumField", "skField", "skForVar", "skFunc", "skIterator",
    "skLet", "skMacro", "skMethod", "skParam", "skProc", "skResult", "skTemplate", "skVar",
  ]
    ## Symbol kinds receiver's last name resolves to where it is value, or call yielding one.


func isTargetName(text: string): bool =
  ## Decide whether name is `to<Target>`: `to`, then capital.
  text.len > 2 and text.startsWith("to") and text[2] in {'A' .. 'Z'}


func isPlain(tokens: openArray[Token]; partners: openArray[int]; a, b: int; source: string): bool =
  ## Decide whether tokens `a` to `b` are name with call, index or field glued after it.
  if a > b or tokens[a].kind != TokenKind.Word or tokens[a].isKeyword(source): return false
  var k = a + 1
  while k <= b:
    let t = tokens[k]
    if t.first != tokens[k - 1].after: return false
    if t.kind == TokenKind.Open and t.spelling(source) in ["(", "["] and partners[k] in k .. b:
      k = partners[k] + 1
    elif t.spelling(source) == "." and k + 1 <= b and tokens[k + 1].kind == TokenKind.Word and
        tokens[k + 1].first == t.after:
      k += 2
    else: return false
  true


func targets(source: string): seq[Target] =
  ## Find each one-argument `to<Target>` prefix call whose argument is plain.
  let
    tokens = source.tokens
    partners = tokens.partners
  for k in 0 ..< tokens.len - 1:
    let t = tokens[k]
    if t.kind != TokenKind.Word or not t.spelling(source).isTargetName: continue
    if k > 0 and tokens[k - 1].spelling(source) == "." and tokens[k - 1].after == t.first:
      continue
    let o = k + 1
    if not tokens.isCallOpen(partners, o, source) or partners[o] <= o + 1: continue
    let c = partners[o]
    if tokens[c].line != t.line or toSeq(o .. c).anyIt(tokens[it].lastLine(source) != t.line):
      continue
    if not tokens.isPlain(partners, o + 1, c - 1, source): continue
    if c + 1 < tokens.len and tokens[c + 1].first == tokens[c].after and
        tokens[c + 1].kind == TokenKind.Open:
      continue
    let argument = source[tokens[o + 1].first ..< tokens[c - 1].after]
    result.add Target(
      line: t.line,
      first: t.first,
      after: tokens[c].after,
      shaped: argument & "." & t.spelling(source),
      got: source[t.first ..< tokens[c].after],
    )


func checkTargets*(path, source: string): seq[Report] =
  ## Report `to<Target>` prefix call whose plain subject could come first (STYLE.md §5).
  ##   Named by its suite and `fixes.nim` alone until static pass calls it (`fixes.nim`).
  for target in source.targets:
    result.add initReport(
      path,
      target.line + 1,
      Rule.TargetSubject,
      "`to<Target>` takes its plain subject first, as `b.toDigits` (STYLE.md §5); got `" &
        target.got & "`.",
    )


func fixTargets*(path, source: string): Fix =
  ## Write each call check reports subject first; call holding another such call waits for
  ##   next pass, so inner one is written first, and its text carries into outer one.
  result.source = source
  for pass in 1 .. PASSES_MAX:
    let found = result.source.targets
    if found.len == 0: break
    var
      shaped = result.source
      step: Fix
    for target in found.sortedByIt(-it.first):
      if found.anyIt(it.first > target.first and it.after <= target.after): continue
      shaped = shaped[0 ..< target.first] & target.shaped & shaped[target.after .. ^1]
      step.fixed.add initReport(path, target.line + 1, Rule.TargetSubject)
    step.source = shaped
    step.fixed.reverse
    result = result.chain(step)


func importedNames(
  tokens: openArray[Token], partners: openArray[int], source: string
): HashSet[string] =
  ## Collect names standing in `import`, `include`, `from` and `export` statements: modules
  ##   file may qualify name with.
  for k in tokens.pathTokens(partners, source):
    if tokens[k].kind == TokenKind.Word: result.incl tokens[k].spelling(source)


func receiverOf(tokens: openArray[Token], partners: openArray[int], dot: int, source: string): int =
  ## Read index of first token of receiver ending before `.` at `dot`: name with calls, indexes
  ##   and fields glued after it, or bracket group; `-1` where none stands there.
  var j = dot - 1
  while j >= 0:
    let t = tokens[j]
    if t.kind == TokenKind.Close and partners[j] >= 0:
      let open = partners[j]
      if open > 0 and tokens[open - 1].after == tokens[open].first and
          tokens[open - 1].kind in {TokenKind.Word, TokenKind.Quoted, TokenKind.Close} and
          not tokens[open - 1].isKeyword(source):
        j = open - 1
        continue
      return (if tokens[open].spelling(source) in ["(", "["]: open else: -1)
    if t.kind in {TokenKind.Word, TokenKind.Quoted} and t.isKeyword(source): return -1
    if t.kind notin {TokenKind.Word, TokenKind.Quoted, TokenKind.Number, TokenKind.Text,
                     TokenKind.Character}:
      return -1
    if j >= 2 and tokens[j - 1].spelling(source) == "." and tokens[j - 1].after == t.first and
        tokens[j - 2].after == tokens[j - 1].first:
      j -= 2
      continue
    return j
  -1


func candidates(source: string): seq[Candidate] =
  ## Find each `x.T` text cannot settle: type-like name glued after `.` glued to receiver.
  let
    tokens = source.tokens
    partners = tokens.partners
    skipped = tokens.pathTokens(partners, source)
    modules = importedNames(tokens, partners, source)
  for k in 1 ..< tokens.len - 1:
    let t = tokens[k]
    if t.kind != TokenKind.Operator or t.spelling(source) != "." or k in skipped: continue
    let name = tokens[k + 1]
    if tokens[k - 1].after != t.first or name.first != t.after: continue
    if name.kind != TokenKind.Word or name.isKeyword(source): continue
    let text = name.spelling(source)
    if text notin BUILTIN_TYPES and text[0] notin {'A' .. 'Z'}: continue
    if k + 2 < tokens.len and tokens[k + 2].first == name.after and
        tokens[k + 2].kind == TokenKind.Open:
      continue
    let
      last = tokens[k - 1]
      first = receiverOf(tokens, partners, k, source)
    if first < 0 or tokens[first].line != name.line: continue
    if last.kind == TokenKind.Word and
        (last.spelling(source)[0] in {'A' .. 'Z'} or last.spelling(source) in modules):
      continue
    result.add Candidate(first: first, last: k - 1, dot: k, name: k + 1)


func conversionQuery*(path, source: string): Query =
  ## Build what conversion check asks semantic pass of file: each candidate's type name, and
  ##   receiver's last name where it ends on one.
  result.path = path
  let
    tokens = source.tokens
    starts = source.lineStarts
  for c in source.candidates:
    for k in [c.name, c.last]:
      if tokens[k].kind != TokenKind.Word: continue
      let site = (tokens[k].line + 1, tokens[k].first - starts[tokens[k].line])
      if site notin result.sites: result.sites.add site


func isGroup(
  tokens: openArray[Token]; partners: openArray[int]; first, last: int; source: string
): bool =
  ## Decide whether tokens `first` to `last` are one parenthesis holding one expression, no
  ##   tuple: no comma, semicolon or `:` at its own depth.
  if tokens[first].spelling(source) != "(" or partners[first] != last or last <= first + 1:
    return false
  var k = first + 1
  while k < last:
    if tokens[k].kind in {TokenKind.Comma, TokenKind.Semicolon}: return false
    if tokens[k].spelling(source) == ":": return false
    if tokens[k].kind == TokenKind.Open and partners[k] > k: k = partners[k]
    inc k
  true


func conversions(source: string, answer: Answer): seq[Conversion] =
  ## Find each candidate semantic pass settles as conversion, with edits writing `T(x)`.
  if answer.reason.len > 0: return
  let
    tokens = source.tokens
    partners = tokens.partners
    starts = source.lineStarts

  func kindAt(k: int): string =
    let site = (tokens[k].line + 1, tokens[k].first - starts[tokens[k].line])
    if site in answer.symbols: answer.symbols[site].kind else: ""

  var converted: seq[int]  # Name token of each conversion so far; its call is value too.
  for c in source.candidates.sortedByIt(it.name):
    if kindAt(c.name) notin TYPE_KINDS: continue
    if tokens[c.last].kind == TokenKind.Word and kindAt(c.last) notin VALUE_KINDS and
        c.last notin converted:
      continue
    converted.add c.name
    let
      name = tokens[c.name].spelling(source)
      span = tokens[c.name].after - tokens[c.first].first
    var conversion = Conversion(
      line: tokens[c.dot].line,
      got: source[tokens[c.first].first ..< tokens[c.name].after],
    )
    if isGroup(tokens, partners, c.first, c.last, source):
      conversion.edits = @[
        Edit(first: tokens[c.first].first, after: tokens[c.first].after, text: name & "("),
        Edit(first: tokens[c.last].first, after: tokens[c.name].after, text: ")"),
      ]
    else:
      conversion.edits = @[
        Edit(
          first: tokens[c.first].first,
          after: tokens[c.first].first,
          text: name & "(",
          rank: -span,
        ),
        Edit(first: tokens[c.dot].first, after: tokens[c.name].after, text: ")"),
      ]
    result.add conversion


func checkConversions*(path, source: string; answer: Answer): seq[Finding] =
  ## Report type conversion written `x.T`, as semantic pass settles it (STYLE.md §5).
  ##   Static pass compiles nothing, so `koch fix --dry-run` is where it runs (`fixes.nim`).
  for conversion in conversions(source, answer):
    result.add finding(
      path,
      conversion.line + 1,
      "Type conversion is prefix call, as `Grade(x)` (STYLE.md §5); got `" & conversion.got & "`.",
    )


func isTouching(a, b: Edit): bool =
  ## Decide whether two edits write one byte, or one inserts strictly inside other's span.
  if a.first == a.after: b.first < a.first and a.first < b.after
  elif b.first == b.after: a.first < b.first and b.first < a.after
  else: a.first < b.after and b.first < a.after


func conversionEdits*(
  path, source: string; answer: Answer; fenced: openArray[int]; held: openArray[Edit] = []
): (seq[Edit], seq[Finding]) =
  ## Read edits writing each conversion check reports, and one report per conversion. Fenced
  ##   line (X.1), and line conversions would widen beside `held` edits of other fixers, keep
  ##   every conversion on them for hand; so does conversion touching span held edit writes.
  var found = conversions(source, answer).filterIt(it.line notin fenced)
  found = found.filterIt(not it.edits.anyIt((let e = it; held.anyIt(it.isTouching(e)))))
  let before = source.split('\n')
  while true:
    let
      after = source.applied(found.mapIt(it.edits).concat & held.toSeq).split('\n')
      widened = toSeq(0 ..< before.len).filterIt(after[it].isWide and not before[it].isWide)
    if widened.len == 0: break
    found = found.filterIt(it.line notin widened)
  result[0] = found.mapIt(it.edits).concat
  for conversion in found:
    result[1].add finding(path, conversion.line + 1, "type conversion (STYLE.md §5)")
