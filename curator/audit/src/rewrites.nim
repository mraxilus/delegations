## Rewrite source by edits that fixers resting on semantic pass plan (`symbols.nim`), and plan
##   rename of symbol across files from what that pass resolves.
##   Edit replaces byte span of source as given, or inserts where span is empty. Edits never
##     overlap, but insertions may share offset; rank orders them, lower first, so wrapper
##     planned outside another opens before it (`int(float(x))`).
##   Rename is planned whole or refused whole, since part of rename breaks build:
##   - declaration must resolve, in file that compiles, to symbol declared at that very site;
##     name check's scanner may read use as declaration, and rename of it would repeat other;
##   - every name token of scope that Nim reads as old name must resolve, in file that
##     compiles: one resolving to declaration is renamed, one resolving to other symbol stays,
##     and one resolving to nothing refuses rename, since it cannot be proved either way. Edit
##     spans token as spelled there, since Nim reads `tmpDir` as `tmp_dir`.
##     Named argument and field of constructor (`f(name = v)`, `T(name: v)`), which semantic
##     pass resolves to nothing, resolve through callee: they are declaration where it is
##     parameter or field of that callee, in file declaring callee;
##   - new name must stand nowhere in files rename writes, and name no global declaration of
##     any module compiled with declaring file, `system` among them: it would collide there, or
##     shadow it. Global there is what bare name reaches, `module.name` or enum member; field,
##     parameter and local of other scope, which `globalSymbols` answers too, never collide.
##     New name Nim reads as old one (`localValue` to `local_value`) skips both tests: it
##     changes no reading, so nothing new can collide;
##   - new name is no keyword, and not `result`, which compiler declares in routine;
##   - no edit lands on fenced line (X.1), and none widens line past `LINE_MAX`.
##   Mention of old name in backticks, in comment of file where rename takes every use, is
##     renamed too, so comment still names what code does.
##   Refusal names its reason, and rule's finding stays for hand. Rule choosing new name is
##     caller's (`names.nim`): V.6 abbreviation, and V.1 and V.11 case of each kind.
##
##   Cost: scope is caller's: project of declaring file and root files that import across
##     projects (`koch.nim`). Use in other project's file is not read, and none exists today.
##   Cost: collision test is by name presence, so rename that would compile may be refused.
##   Cost: overloads of one routine in one file share qualified name of parameter, so named
##     argument to overload whose parameter rename does not reach is renamed too; build then
##     fails, and tree proof reads it.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, strutils, tables]
import ./[form, symbols, tokens]


type
  Edit* = object  ## Define one edit: byte span of source as given, text replacing it, rank.
    first*: int  ## Byte offset span opens at.
    after*: int  ## Byte offset after span; equal to `first` for insertion.
    text*: string
    rank*: int  ## Order among insertions at one offset: lower first.

  Rename* = object  ## Define rename to plan: declaration site, old and new name, rule.
    path*: string  ## Repository-relative path of declaring file.
    line*: int  ## One-based line of declared name.
    column*: int  ## Zero-based byte column of declared name.
    name*: string  ## Name as declared.
    renamed*: string  ## Name rule gives.
    rule*: string  ## Rule report names, e.g. `abbreviation (V.6)`.
    is_local*: bool  ## Binding no other module can name, so scope is declaring file alone.

  Plan* = object  ## Define rename planned, or refused with reason.
    rename*: Rename
    edits*: Table[string, seq[Edit]]  ## Edits of each file rename writes.
    lines*: seq[(string, int)]  ## Path and one-based line of each edit, for reports.
    refusal*: string  ## Why rename is refused; empty where planned.


const
  NAME_CHARS = {'a'..'z', 'A'..'Z', '0'..'9', '_', '\x80'..'\xFF'}
    ## Bytes name token is built from: Nim reads every non-ASCII byte as letter.
  RESULT_NAME = "result"  ## Name compiler declares in each routine returning value.
  KIND_MEMBER = "skEnumField"  ## Kind of enum member, which bare name reaches unless enum is pure.


func applied*(source: string, edits: openArray[Edit]): string =
  ## Apply edits to source, last first, so earlier offsets hold; insertions at one offset in
  ##   rank order.
  result = source
  for edit in edits.sortedByIt((-it.first, -(it.after - it.first), -it.rank)):
    result = result[0..<edit.first] & edit.text & result[edit.after .. ^1]


func isIdentical(a, b: Symbol): bool =
  ## Decide whether two answers name one symbol: one definition site.
  a.file == b.file and a.line == b.line and a.column == b.column


func isReached(symbol: Symbol): bool =
  ## Decide whether bare name reaches symbol from module importing its own: global, i.e.
  ##   `module.name`, or enum member; field, parameter and local nest one name deeper.
  symbol.kind == KIND_MEMBER or symbol.name.count('.') == 1


func nameAfter(source: string, first: int): int =
  ## Read byte offset after name token opening at offset; its spelling may differ from declared
  ##   name's in case and underscores, which Nim ignores past first character.
  result = first
  while result < source.len and source[result] in NAME_CHARS: inc result


func sitesOf(source, name: string): seq[(int, int)] =
  ## Read one-based line and zero-based byte column of each name token Nim reads as `name`.
  let starts = source.lineStarts
  for t in source.tokens:
    if t.kind == TokenKind.Word and t.spelling(source).isSameName(name):
      result.add (t.line + 1, t.first - starts[t.line])


func calleeOf(source: string, site: (int, int)): (int, int) =
  ## Read site of callee whose named argument or field name stands at site (`f(name = v)`,
  ##   `T(name: v)`); `(0, 0)` where site names none. Semantic pass resolves no such name, so
  ##   callee tells whose parameter or field it is.
  let
    tokens = source.tokens
    partners = tokens.partners
    starts = source.lineStarts
  var k = tokens.high
  while k >= 0 and (tokens[k].line + 1, tokens[k].first - starts[tokens[k].line]) != site: dec k
  if k < 1 or k + 1 >= tokens.len or tokens[k + 1].spelling(source) notin ["=", ":"]:
    return (0, 0)
  if tokens[k - 1].kind notin {TokenKind.Open, TokenKind.Comma}: return (0, 0)
  var open = k - 1
  while open >= 0 and not (tokens[open].kind == TokenKind.Open and partners[open] > k):
    dec open
  if open < 1 or tokens[open].spelling(source) != "(" or
      tokens[open - 1].after != tokens[open].first:
    return (0, 0)
  var callee = open - 1
  if tokens[callee].spelling(source) == "]" and partners[callee] > 0:
    callee = partners[callee] - 1
  if callee < 0 or tokens[callee].kind != TokenKind.Word: return (0, 0)
  (tokens[callee].line + 1, tokens[callee].first - starts[tokens[callee].line])


func queriesOf*(rename: Rename, files: openArray[(string, string)]): seq[Query] =
  ## Build what rename asks semantic pass: every site of old name in scope, declaration among
  ##   them, and globals named as new name, in declaring file.
  for (path, source) in files:
    let sites = source.sitesOf(rename.name)
    var query = Query(path: path, sites: sites)
    for site in sites:
      let callee = source.calleeOf(site)
      if callee != (0, 0) and callee notin query.sites: query.sites.add callee
    if path == rename.path:
      if (rename.line, rename.column) notin query.sites:
        query.sites.add (rename.line, rename.column)
      query.names.add rename.renamed
    if query.sites.len > 0 or query.names.len > 0: result.add query


func planRename*(
  rename: Rename,
  files: openArray[(string, string)],
  answers: Table[string, Answer],
  fenced: Table[string, seq[int]],
): Plan =
  ## Plan rename across files of scope from answers of semantic pass, or refuse it with reason;
  ##   refused plan holds no edit.

  template refuse(reason: string) =
    result.refusal = reason
    result.edits.clear
    result.lines.setLen(0)
    return

  result.rename = rename
  if rename.renamed.isKeyword: refuse "`" & rename.renamed & "` is keyword"
  if rename.renamed.isSameName(RESULT_NAME):
    refuse "`" & rename.renamed & "` names implicit result of routine"
  if rename.path notin answers or answers[rename.path].reason.len > 0:
    refuse "declaring file does not compile on its pin"
  let declaring = answers[rename.path]
  if (rename.line, rename.column) notin declaring.symbols:
    refuse "declaration resolves to no symbol"
  let
    declared = declaring.symbols[(rename.line, rename.column)]
    shadowed = declaring.globals.getOrDefault(rename.renamed).filterIt(
      it.isReached and not it.isIdentical(declared),
    )
    is_respelled = rename.name.isSameName(rename.renamed)
  if not declared.file.endsWith("/" & rename.path) or declared.line != rename.line or
      declared.column != rename.column:
    refuse "`" & rename.path & ":" & $rename.line & "` names symbol declared elsewhere"
  if shadowed.len > 0 and not is_respelled:
    refuse "`" & rename.renamed & "` would shadow `" & shadowed[0].name & "`"

  # Classify each site of old name; any site unresolved refuses rename whole.
  for (path, source) in files:
    let sites = source.sitesOf(rename.name)
    if sites.len == 0: continue
    if path notin answers or answers[path].reason.len > 0:
      refuse "`" & path & "` names `" & rename.name & "` and does not compile"
    let starts = source.lineStarts
    var
      edits: seq[Edit]
      is_every = true
    for site in sites:
      var symbol: Symbol
      if site in answers[path].symbols: symbol = answers[path].symbols[site]
      else:
        # Named argument or field resolves through its callee: parameter of that routine, or
        #   field of that type, in file declaring it.
        let callee = source.calleeOf(site)
        if callee == (0, 0) or callee notin answers[path].symbols:
          refuse "`" & path & ":" & $site[0] & "` resolves to no symbol"
        let
          owner = answers[path].symbols[callee]
          is_owned = owner.file == declared.file and
            declared.name == owner.name & "." & declared.name.split('.')[^1]
        symbol = if is_owned: declared else: owner
      if not symbol.isIdentical(declared):
        is_every = false
        continue
      let first = starts[site[0] - 1] + site[1]
      edits.add Edit(first: first, after: source.nameAfter(first), text: rename.renamed)
      result.lines.add (path, site[0])
    if edits.len == 0: continue
    if not is_respelled and source.sitesOf(rename.renamed).len > 0:
      refuse "`" & rename.renamed & "` already stands in `" & path & "`"

    # Rename mention in backticks of comment where every use is renamed.
    if is_every:
      let quoted = "`" & rename.name & "`"
      for t in source.tokens:
        if t.kind != TokenKind.Comment: continue
        var at = source.find(quoted, t.first)
        while at >= 0 and at + quoted.len <= t.after:
          edits.add Edit(first: at + 1, after: at + 1 + rename.name.len, text: rename.renamed)
          at = source.find(quoted, at + quoted.len)

    # Refuse edit on fenced line, or one widening its line.
    let
      before = source.split('\n')
      after = source.applied(edits).split('\n')
    for edit in edits:
      let line = starts.upperBound(edit.first) - 1
      if line in fenced.getOrDefault(path):
        refuse "`" & path & ":" & $(line + 1) & "` is fenced (X.1)"
    for i in 0..<min(before.len, after.len):
      if after[i].isWide and not before[i].isWide:
        refuse "`" & path & ":" & $(i + 1) & "` would cross " & $LINE_MAX & " characters"
    result.edits[path] = edits
