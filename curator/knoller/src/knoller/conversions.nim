## Enforce type conversion as prefix call STYLE.md §5 gives (`Grade(x)`, never `x.Grade`), and
##   fix it through semantic pass (`symbols.nim`); caller resolves what `queryConversion` asks.
##   `to<Target>` call, which takes its plain subject first, is knoller's (`targets.nim`).
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
##   Check and fixer share one reading (`conversions`), so rule is written once (Article II.1).
##
##   No fixer, check silent: conversion followed by bracket glued after it (`x.T(y)`, two
##     arguments), receiver spanning lines, and name in file semantic pass cannot compile.
##   Cost: conversion inside `template` resolves nothing, since template body is not checked,
##     and stays to hand.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, sets, strutils, tables]
import ./[edits, form, reports, rules, spacing, symbols, tokens]


type

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
  TYPES_BUILTIN = [
    "bool", "byte", "cchar", "cdouble", "cfloat", "char", "cint", "clong", "clonglong",
    "cshort", "csize_t", "cstring", "cuint", "culong", "float", "float32", "float64", "int",
    "int16", "int32", "int64", "int8", "Natural", "Positive", "string", "uint", "uint16",
    "uint32", "uint64", "uint8",
  ]
    ## Lowercase types `system` declares; capitalised name is candidate on its case alone.
  KINDS_TYPE = ["skType", "skGenericParam"]  ## Symbol kinds conversion name resolves to.
  KINDS_VALUE = [
    "skConst", "skConverter", "skEnumField", "skField", "skForVar", "skFunc", "skIterator",
    "skLet", "skMacro", "skMethod", "skParam", "skProc", "skResult", "skTemplate", "skVar",
  ]
    ## Symbol kinds receiver's last name resolves to where it is value, or call yielding one.


func namesImported(
  tokens: openArray[Token], partners: openArray[int], source: string
): HashSet[string] =
  ## Collect names standing in `import`, `include`, `from` and `export` statements: modules
  ##   file may qualify name with.
  for k in tokens.tokensPath(partners, source):
    if tokens[k].kind == KindToken.Word: result.incl tokens[k].spelling(source)


func receiverOf(tokens: openArray[Token], partners: openArray[int], dot: int, source: string): int =
  ## Read index of first token of receiver ending before `.` at `dot`: name with calls, indexes
  ##   and fields glued after it, or bracket group; `-1` where none stands there.
  var j = dot - 1
  while j >= 0:
    let t = tokens[j]
    if t.kind == KindToken.Close and partners[j] >= 0:
      let open = partners[j]
      if open > 0 and tokens[open - 1].after == tokens[open].first and
          tokens[open - 1].kind in {KindToken.Word, KindToken.Quoted, KindToken.Close} and
          not tokens[open - 1].isKeyword(source):
        j = open - 1
        continue
      return (if tokens[open].spelling(source) in ["(", "["]: open else: -1)
    if t.kind in {KindToken.Word, KindToken.Quoted} and t.isKeyword(source): return -1
    if t.kind notin {KindToken.Word, KindToken.Quoted, KindToken.Number, KindToken.Text,
                     KindToken.Character}:
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
    skipped = tokens.tokensPath(partners, source)
    modules = namesImported(tokens, partners, source)
  for k in 1 ..< tokens.len - 1:
    let t = tokens[k]
    if t.kind != KindToken.Operator or t.spelling(source) != "." or k in skipped: continue
    let name = tokens[k + 1]
    if tokens[k - 1].after != t.first or name.first != t.after: continue
    if name.kind != KindToken.Word or name.isKeyword(source): continue
    let text = name.spelling(source)
    if text notin TYPES_BUILTIN and text[0] notin {'A' .. 'Z'}: continue
    if k + 2 < tokens.len and tokens[k + 2].first == name.after and
        tokens[k + 2].kind == KindToken.Open:
      continue
    let
      last = tokens[k - 1]
      first = receiverOf(tokens, partners, k, source)
    if first < 0 or tokens[first].line != name.line: continue
    if last.kind == KindToken.Word and
        (last.spelling(source)[0] in {'A' .. 'Z'} or last.spelling(source) in modules):
      continue
    result.add Candidate(first: first, last: k - 1, dot: k, name: k + 1)


func queryConversion*(path, source: string): Query =
  ## Build what conversion check asks semantic pass of file: each candidate's type name, and
  ##   receiver's last name where it ends on one.
  result.path = path
  let
    tokens = source.tokens
    starts = source.lineStarts
  for c in source.candidates:
    for k in [c.name, c.last]:
      if tokens[k].kind != KindToken.Word: continue
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
    if tokens[k].kind in {KindToken.Comma, KindToken.Semicolon}: return false
    if tokens[k].spelling(source) == ":": return false
    if tokens[k].kind == KindToken.Open and partners[k] > k: k = partners[k]
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
    if kindAt(c.name) notin KINDS_TYPE: continue
    if tokens[c.last].kind == KindToken.Word and kindAt(c.last) notin KINDS_VALUE and
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


func checkConversions*(path, source: string; answer: Answer): seq[Report] =
  ## Report type conversion written `x.T`, as semantic pass settles it (STYLE.md §5).
  for conversion in conversions(source, answer):
    result.add initReport(
      path,
      conversion.line + 1,
      Rule.Conversion,
      "Type conversion is prefix call, as `Grade(x)`; got `" & conversion.got & "`.",
    )


func editsConversion*(
  path, source: string; answer: Answer; fenced: openArray[int]; held: openArray[Edit] = []
): (seq[Edit], seq[Report]) =
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
  for conversion in found: result[1].add initReport(path, conversion.line + 1, Rule.Conversion)
