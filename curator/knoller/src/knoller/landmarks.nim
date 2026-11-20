## Write each landmark index as alias its type declares, as V.8 gives (`Grade.vector`, never
##   `Grade(1)`), and fix it (`koch fix`); caller reads aliases of package and of library it
##   builds on (`landmarksDeclared`), and passes them in (`NamesPackage`).
##   Alias is template or routine at module level whose one parameter is `typedesc[T]`, which
##     returns `T`, and whose body is one expression, on its line or alone below it
##     (`aliasesDeclared`). `T` is type, or placeholder whose constraint lists types
##     (`[G: Grade | GradeAnti]`).
##   Body is read for each type (`indexNamed`): `when G is GradeAnti: … else: …` takes branch of
##     type; conversion to placeholder or to type itself, as `G(1)`, names index; `t.low`, `G.low`
##     or `T.low` names index alias `low` names, read through it. Other `when` branches on
##     configuration, as `origin` does, and other body names no index, so no bare form matches.
##   Alias declared under `when`, as `infinity` is, exists in one configuration alone, so fix
##     never writes it, and it names no index here.
##   Bare form is conversion `T(…)` whose argument, spaces aside, is index of alias of `T`
##     (`conversionsBare`); body of alias itself passes, so its own index stays.
##   Fix writes alias where one names index. Where several do, it writes `low` or `high` among
##     them (Architect's ruling, #443), as library writes grade in 20 of 21 places; other choice
##     stays for hand. Edit replaces conversion whole, and `.` binds tighter than any prefix
##     operator before it, so reading holds.
##   Edits apply once, before chain, on source as given, as type conversions do: none moves line,
##     so fence holds, and none lands on fenced line. Edit widening narrow line past `LINE_MAX`,
##     or touching span other edit writes, stays for hand.
##
##   Cost: `low` and `high` of enum are builtin, so alias read through them names no index, as
##     `Basis.scalar` does; `ord(Basis.high) + 1` counts bases elsewhere, and only reading tells
##     it from antiscalar.
##   Cost: where no alias names index, as for `Basis.scalar.succ`, rule is silent, since new alias
##     is choice of design.
##   Cost: fix reads no import, so module that sees type and not its alias fails to build; build
##     of fixed tree reads it.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils]
import ./[edits, form, reports, rules, tokens, views]


type
  Alias = object  ## Define template or routine naming landmark of type by its one `typedesc`.
    name: string  ## Name of alias, as `vector`.
    types: seq[string]  ## Each type it applies to: placeholder's constraint, or type itself.
    placeholder: string  ## Placeholder `typedesc` takes, as `G`; empty where type is named.
    parameter: string  ## Name of its parameter, as `t`.
    body: string  ## Its one expression, as code reads it.
    line: int  ## One-based line of body.

  Landmark* = object  ## Define landmark index of type, and each alias naming it.
    name*: string  ## Type, as `Grade`.
    index*: string  ## Index as body spells it, with no whitespace, as `DIMENSIONS-1`.
    aliases*: seq[string]  ## Each alias naming index, in order read.

  Bare = object  ## Define conversion writing landmark index bare.
    line: int  ## Zero-based line of type name.
    first: int  ## Byte offset of type name.
    after: int  ## Byte offset after closing parenthesis.
    got: string  ## Conversion as written.
    landmark: Landmark


const
  KEYWORDS_ALIAS = ["func", "proc", "template"]  ## Keywords declaring alias.
  ALIASES_PREFERRED = ["low", "high"]
    ## Alias fix writes where several name one index, as library writes grade (#443).
  DEPTH_MAX = 8  ## Aliases read through one another at most.


func spaceless(text: string): string =
  ## Write text with no whitespace, as index compares spaces aside.
  for c in text:
    if c notin Whitespace: result.add c


func indexTop(text, mark: string): int =
  ## Find first `mark` outside brackets; `-1` where none.
  var depth = 0
  for k, c in text:
    if c in {'(', '[', '{'}: inc depth
    elif c in {')', ']', '}'}: dec depth
    elif depth == 0 and text.continuesWith(mark, k): return k
  -1


func closingAt(text: string, open: int): int =
  ## Find bracket closing one opened at index; `-1` where text ends first.
  var depth = 0
  for k in open ..< text.len:
    if text[k] in {'(', '[', '{'}: inc depth
    elif text[k] in {')', ']', '}'}:
      dec depth
      if depth == 0: return k
  -1


func aliasesDeclared(source: string): seq[Alias] =
  ## Read each alias source declares at module level: template or routine whose one parameter is
  ##   `typedesc[T]`, which returns `T`, and whose body is one expression.
  let lines = source.codeOnly.split('\n')
  for i, line in lines:
    let keyword = line.identifierAt(0)
    if line.indentWidth > 0 or keyword notin KEYWORDS_ALIAS: continue
    let name = line.identifierAt(keyword.len)
    if name.len == 0: continue
    var k = line.find(name, keyword.len) + name.len
    if k < line.len and line[k] == '*': inc k

    # Read placeholders with constraints, as `[G: Grade | GradeAnti]`.
    var constrained: seq[(string, seq[string])]
    if k < line.len and line[k] == '[':
      let close = line.closingAt(k)
      if close < 0: continue
      for piece in line[k + 1 ..< close].split({',', ';'}):
        let colon = piece.find(':')
        if colon <= 0: continue
        let types = piece[colon + 1 .. ^1].split('|').mapIt(it.strip)
        constrained.add (piece[0 ..< colon].strip, types)
      k = close + 1
    if k >= line.len or line[k] != '(': continue
    let close = line.closingAt(k)
    if close < 0: continue

    # Read one parameter `t: typedesc[T]`, then return type `T` before `=`.
    let
      parameter = line[k + 1 ..< close]
      colon = parameter.find(':')
      tail = line[close + 1 .. ^1]
      equal = tail.indexTop(" =")
    if colon < 0 or parameter.indexTop(",") >= 0 or parameter.indexTop(";") >= 0: continue
    let kind = parameter[colon + 1 .. ^1].spaceless
    if not kind.startsWith("typedesc[") or not kind.endsWith("]") or equal < 0: continue
    let held = kind["typedesc[".len ..< kind.high]
    if tail[0 ..< equal].spaceless != ":" & held: continue
    var alias = Alias(name: name, parameter: parameter[0 ..< colon].strip)
    let at = constrained.mapIt(it[0]).find(held)
    if at >= 0:
      alias.placeholder = held
      alias.types = constrained[at][1]
    else: alias.types = @[held]

    # Read body: rest of line, else one line below it, which no other line of body follows.
    let rest = tail[equal + " =".len .. ^1].strip
    if rest.len > 0:
      alias.body = rest
      alias.line = i + 1
    else:
      var j = i + 1
      while j < lines.len and lines[j].strip.len == 0: inc j
      if j == lines.len or lines[j].indentWidth == 0: continue
      var next = j + 1
      while next < lines.len and lines[next].strip.len == 0: inc next
      if next < lines.len and lines[next].indentWidth > 0: continue
      alias.body = lines[j].strip
      alias.line = j + 1
    result.add alias


func indexNamed(aliases: openArray[Alias]; name, kind: string; depth = 0): string =
  ## Read index alias `name` names for type `kind`, through other aliases; empty where none.
  if depth > DEPTH_MAX: return
  for alias in aliases:
    if alias.name != name or kind notin alias.types: continue
    let selves = [alias.placeholder, alias.parameter, kind].filterIt(it.len > 0)
    var body = alias.body

    # Take branch of `when` on type; other condition branches on configuration.
    if body.startsWith("when "):
      let colon = body.indexTop(":")
      if colon < 0: return
      let
        condition = body["when ".len ..< colon].split(" is ")
        branches = body[colon + 1 .. ^1]
        otherwise = branches.indexTop("else:")
      if otherwise < 0 or condition.len != 2 or condition[0].strip notin selves: return
      body =
        if condition[1].strip == kind: branches[0 ..< otherwise].strip
        else: branches[otherwise + "else:".len .. ^1].strip

    # Read conversion to placeholder or type itself, else alias read through.
    let
      head = body.identifierAt(0)
      rest = body[head.len .. ^1]
    if head notin selves: return
    if rest.startsWith("(") and rest.closingAt(0) == rest.high:
      return rest[1 ..< rest.high].spaceless
    if rest.startsWith(".") and rest[1 .. ^1].identifierAt(0) == rest[1 .. ^1]:
      return aliases.indexNamed(rest[1 .. ^1], kind, depth + 1)
    return


func landmarksDeclared*(sources: openArray[string]): seq[Landmark] =
  ## Read each landmark index aliases of sources name, with each alias naming it, in order read:
  ##   modules of package, then those of library it builds on.
  var aliases: seq[Alias]
  for source in sources: aliases.add source.aliasesDeclared
  for alias in aliases:
    for kind in alias.types:
      let index = aliases.indexNamed(alias.name, kind)
      if index.len == 0: continue
      let at = result.mapIt((it.name, it.index)).find((kind, index))
      if at < 0: result.add Landmark(name: kind, index: index, aliases: @[alias.name])
      elif alias.name notin result[at].aliases: result[at].aliases.add alias.name


func written(landmark: Landmark): string =
  ## Read alias fix writes for landmark: one alias, else `low` or `high` among several; empty
  ##   where choice stays for hand.
  if landmark.aliases.len == 1: return landmark.aliases[0]
  for preferred in ALIASES_PREFERRED:
    if preferred in landmark.aliases: return preferred


func conversionsBare(source: string; landmarks: openArray[Landmark]): seq[Bare] =
  ## Find each conversion `T(…)` writing index of alias of `T` bare; body of alias passes.
  let
    tokens = source.tokens
    partners = tokens.partners
    bodies = source.aliasesDeclared.mapIt(it.line - 1)
  for k in 0 ..< tokens.len - 1:
    let
      t = tokens[k]
      o = k + 1
    if t.kind != KindToken.Word or t.line in bodies: continue
    if k > 0 and tokens[k - 1].spelling(source) == "." and tokens[k - 1].after == t.first:
      continue
    if tokens[o].spelling(source) != "(" or tokens[o].first != t.after or partners[o] <= o:
      continue
    let
      index = source[tokens[o].after ..< tokens[partners[o]].first].spaceless
      at = landmarks.mapIt((it.name, it.index)).find((t.spelling(source), index))
    if at < 0: continue
    result.add Bare(
      line: t.line,
      first: t.first,
      after: tokens[partners[o]].after,
      got: source[t.first ..< tokens[partners[o]].after],
      landmark: landmarks[at],
    )


func checkLandmarks*(path, source: string; landmarks: openArray[Landmark]): seq[Report] =
  ## Report each landmark index written bare where alias of its type names it (V.8); `landmarks`
  ##   holds those of package and of library it builds on.
  for bare in source.conversionsBare(landmarks):
    let
      written = bare.landmark.written
      named =
        if written.len > 0: "its alias, `" & bare.landmark.name & "." & written & "`"
        else: "one of its aliases, " &
          bare.landmark.aliases.mapIt("`" & bare.landmark.name & "." & it & "`").join(" or ")
    result.add initReport(
      path,
      bare.line + 1,
      Rule.AliasLandmark,
      "Landmark index stands as " & named & "; got `" & bare.got & "`.",
    )


func editsLandmark*(
  path, source: string;
  landmarks: openArray[Landmark];
  fenced: openArray[int];
  held: openArray[Edit] = [],
): (seq[Edit], seq[Report]) =
  ## Read edits writing alias of each landmark index check reports, and one report for each.
  ##   Fenced line (X.1), choice of several aliases, edit touching span `held` edits write, and
  ##   line edits would widen past `LINE_MAX`, keep index bare for hand.
  var found: seq[(int, Edit)]
  for bare in source.conversionsBare(landmarks):
    let written = bare.landmark.written
    if written.len == 0 or bare.line in fenced: continue
    let edit = Edit(first: bare.first, after: bare.after, text: bare.landmark.name & "." & written)
    if held.anyIt(it.isTouching(edit)): continue
    found.add (bare.line, edit)
  let before = source.split('\n')
  while true:
    let
      after = source.applied(found.mapIt(it[1]) & held.toSeq).split('\n')
      widened = toSeq(0 ..< before.len).filterIt(after[it].isWide and not before[it].isWide)
    if widened.len == 0: break
    found = found.filterIt(it[0] notin widened)
  result[0] = found.mapIt(it[1])
  for (line, _) in found: result[1].add initReport(path, line + 1, Rule.AliasLandmark)
