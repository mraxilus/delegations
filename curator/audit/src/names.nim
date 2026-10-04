## Enforce declared names (Article III.5, V.1, V.3-V.6, V.9-V.12; GUIDE.md, Names).
##   Reads declarations alone: binding (`let`, `var`, `const`, `for`, `except … as`), routine,
##     type, field, parameter, enum member and placeholder in generic brackets. Name library
##     owns reaches code only at use site, which is never read, so library clause of V.9 holds
##     by construction. Foreign binding, i.e. routine carrying `importc`, `importcpp`,
##     `importjs` or `dynlib`, declares library's own name and is skipped for same reason; its
##     parameters are ours and are read.
##   Word is run between `_` and case changes; acronym is run of two or more capitals inside
##     camel or Pascal name. SCREAMING name is all capitals, so its acronyms cannot be told
##     from words and hold by reading.
##   Table `ABBREVIATIONS` gives each banned word its one replacement, as `english.nim` does
##     for prose; word outside table passes, and reading catches rest. `JARGON` is closed list
##     of V.6. Caller adds symbols glossaries list under `## Standards` as code spans, and
##     their `**Term**` names, through `glossaryExemptions`.
##   V.1, V.11, V.12: case follows kind. Type and enum member are Pascal, routine camel, local,
##     parameter and field snake, global SCREAMING, placeholder one capital. Pascal opens on
##     capital, camel and snake on none; Pascal and camel hold no `_`, snake no capital,
##     SCREAMING no lowercase. One letter fits by its own case: capital passes type, global and
##     placeholder, lowercase passes routine, local, parameter and field. Plain ASCII is no
##     notation, so capital local is finding (Architect's ruling).
##   III.5: source's notation is variable's name holding non-ASCII letter: binding, field or
##     parameter. It holds over case at any scope, so its case is unread; at module scope it
##     holds only for immutable global, so mutable global in notation is finding. Type,
##     routine, member and placeholder are no variable, and their case is read; mathematical
##     letters carry no case in `std/unicode`, so `letterCase` reads them by block. Operator is
##     backticked, so it is never read as name.
##   V.10: reach of binding is decided in `reachOf` alone. Global where every enclosing block
##     opens no scope (`when` chain, bare `let`, `var`, `const` or `type`); local under routine
##     or any other block; entry inside top-level `when isMainModule:` and outside routine.
##     Entry block holds no binding, so binding there is one finding, its case unjudged.
##     Global shares no word with type, compared without case and underscores, as Nim does.
##   V.12: parameter typed `typedesc` is parameter, so snake (Architect's ruling); one capital
##     is for placeholder in brackets after routine or type name, and after `concept`.
##   V.4: boolean binding, field or parameter opens `is`, `as`, `should`, `found` or `has`,
##     with word after it. `func` returning `bool` is predicate and opens `is`. `proc`
##     returning `bool` reports success of action (V.3), so it is unread (Architect's ruling);
##     `func` writing `var` parameter is action too, and is unread for same reason.
##   V.3: routine never opens with `get`, `compute` or `new`. V.5: name opening `lut` reads
##     `lut_<value>_by_<key>`.
##
##   V.6 has fixer (`koch fix`): `abbreviationRenames` reads each declaration coining
##     abbreviation and its full spelling, case kept, as check reads it, and rename planner of
##     `rewrites.nim` renames it at every use through semantic pass, or refuses with reason.
##   V.1 and V.11 have fixer: `renamesCase` reads each declaration whose case check reports, and
##     spells it in case of its kind word by word (`cased`), abbreviation spelled out too; same
##     planner renames it. Binding of entry block that moves takes case of local it becomes.
##     Fix refuses before planner where meaning would leave text: name foreign code reads by
##     spelling (`MARKS_FOREIGN` on its line, on its type, or `{.push.}` over it), member
##     without own string, whose `$` reads its name, name line declares twice, and new name
##     reading as new acronym. Parameter of foreign routine is renamed: call passes it by place.
##   V.10 has fixer in knoller (`entry.nim`), and declarations are read by its scanner
##     (`declared.nim`); this module judges what scanner reads.
##
##   Rejected: placeholder rename (V.12), since initial of what it ranges over is choice.
##   Cost: field and type renamed change what `$`, `%` and `fieldPairs` print of them; member
##     is refused for that reason, since its `$` is commonly output. Reading holds rest.
##
##   Cost: text scanner, never parser. Comments and strings are blanked first; multi-line
##     signature is joined to its closing parenthesis; object variant branch is read as fields
##     where it sits in `type` block; tuple type in brackets, and name `{.inject.}` makes, are
##     unread.
##   Cost: boolean is read only where declaration shows it: type `bool`, or value literal
##     `true` or `false`. Boolean from call or expression holds by reading.
##   Cost: `in` calls `contains` by spelling, so predicate of that name keeps host's name.
##   Cost: Pascal name of capitals alone, e.g. `ANTI`, reads as acronym and passes; V.9 and
##     reading hold it. Letter outside `std/unicode` case tables and mathematical block carries
##     no case, so it fits every casing.
##   Cost: word table is short list; `english.nim` pays same cost.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, strutils]
from std/unicode import isLower, isUpper, Rune, runes
import ../../knoller/src/knoller
import ./[findings, glossary]


type


  Casing* {.pure.} = enum  ## Define case one kind of name takes (V.1, V.11, V.12).
    Pascal, Camel, Snake, Screaming, Letter

  LetterCase {.pure.} = enum  ## Define case of one letter; digit and symbol carry none.
    None, Lower, Upper



  RenameCase* = object
    ## Define rename case of declaration's kind asks (V.1, V.11), or why fix leaves it to hand.
    line*: int  ## One-based line of declared name.
    column*: int  ## Zero-based byte column of declared name.
    name*: string  ## Name as declared.
    renamed*: string  ## Name in case of its kind, each coined abbreviation spelled out (V.6).
    rule*: string  ## Rule report names, e.g. `local constant case (V.1)`.
    refusal*: string  ## Why fix leaves rename to hand before semantic pass reads it; empty if none.
    is_local*: bool  ## Binding no other module can name: local, or binding of entry block.



const
  ABBREVIATIONS* = [
    ("ctx", "context"), ("tmp", "temporary"), ("buf", "buffer"), ("cfg", "configuration"),
    ("dir", "directory"), ("args", "arguments"), ("err", "error"), ("dest", "destination"),
    ("avail", "available"), ("verts", "vertices"), ("attrib", "attribute"),
  ]
    ## Coined abbreviation and its one full word (V.6).
  JARGON* = ["lut", "min", "max", "src", "prev", "curr", "len"]
    ## Closed list of V.6, which Architect alone extends.
  VERBS_BANNED* = ["get", "compute", "new"]  ## First words routine never takes (V.3).
  BOOLEAN_PREFIXES* = ["is", "as", "should", "found", "has"]
    ## First words boolean takes: state, interpretation, policy, search outcome, possession (V.4).
  VARIABLE_KINDS = {NameKind.Binding, NameKind.Field, NameKind.Parameter}
    ## Kinds naming variable, which source's notation may name at any scope (III.5).
  HOST_PREDICATES = ["contains"]
    ## Predicates host calls by spelling: `in` and `notin` call `contains`.
  CASE_RULES: array[Casing, string] = [
    "is `PascalCase`", "is `lowerCamelCase`", "is `snake_case`", "is `SCREAMING_SNAKE_CASE`",
    "is one capital letter",
  ]
    ## Predicate of each casing, as finding states it.
  MARKS_FOREIGN = [
    "dynlib", "exportc", "exportcpp", "extern", "header", "importc", "importcpp", "importjs",
    "importobjc", "JsRoot",
  ]
    ## Words marking name foreign code reads by its spelling: pragma, or root of JavaScript object.


func wordSpans(name: string): seq[(int, int)] =
  ## Read span of each word of name, split at `_` and at case changes.
  var first = -1  # Index current word opens at; `-1` between words.
  for k, c in name:
    if c == '_':
      if first >= 0: result.add (first, k)
      first = -1
      continue
    if first < 0:
      first = k
      continue
    let is_boundary = (c in {'A' .. 'Z'} and name[k - 1] in {'a' .. 'z', '0' .. '9'}) or
      (c in {'a' .. 'z'} and k - first > 1 and name[k - 1] in {'A' .. 'Z'} and
        name[k - 2] in {'A' .. 'Z'})
    if not is_boundary: continue
    # Capital before lowercase starts new word: `JSONData` is JSON, Data.
    let cut = if c in {'a' .. 'z'}: k - 1 else: k
    result.add (first, cut)
    first = cut
  if first >= 0: result.add (first, name.len)


func words*(name: string): seq[string] =
  ## Split name at `_` and at case changes: `lut_grade`, `wedgeAnti`, `JSONData` give words.
  name.wordSpans.mapIt(name[it[0] ..< it[1]])


func fullWordOf(word: string, lower_exempt: openArray[string]): string =
  ## Read full word `ABBREVIATIONS` gives coined abbreviation, in word's own case; empty where
  ##   word is none, or exempt.
  let lower = word.toLowerAscii
  if lower in lower_exempt or lower in JARGON: return
  for (short, full) in ABBREVIATIONS:
    if lower != short: continue
    if word == lower: return full
    if word == word.toUpperAscii: return full.toUpperAscii
    return full.capitalizeAscii


func respelled*(name: string, exempt: openArray[string]): string =
  ## Spell name with each coined abbreviation written out, case kept (V.6): `ctx_dir` gives
  ##   `context_directory`, `bufSize` gives `bufferSize`. Same name where it coins none.
  let lower_exempt = exempt.mapIt(it.toLowerAscii)
  result = name
  for (first, after) in name.wordSpans.reversed:
    let full = name[first ..< after].fullWordOf(lower_exempt)
    if full.len > 0: result = result[0 ..< first] & full & result[after .. ^1]


func abbreviationRenames*(
  source: string, exempt: openArray[string]
): seq[(int, int, string, string)] =
  ## Read one-based line, zero-based byte column, name and full spelling of each declared name
  ##   coining abbreviation (V.6), as `checkNames` reads them.
  let
    tokens = source.tokens
    starts = source.lineStarts
  for d in source.declarations:
    let renamed = d.name.respelled(exempt)
    if renamed == d.name: continue
    for t in tokens:
      if t.line == d.line - 1 and t.kind == TokenKind.Word and t.spelling(source) == d.name:
        result.add (d.line, t.first - starts[t.line], d.name, renamed)
        break


func letterCase(r: Rune): LetterCase =
  ## Read case of letter, mathematical alphanumerics by block, since `std/unicode` maps none.
  ##   Latin styles run 52 letters, 26 capitals first; Greek styles run 58, 25 capitals first,
  ##     then nabla, 25 small, partial differential and 6 small variants.
  let c = int(r)
  if c in 0x1D400 .. 0x1D6A3:
    return (if (c - 0x1D400) mod 52 < 26: LetterCase.Upper else: LetterCase.Lower)
  if c in 0x1D6A8 .. 0x1D7C9:
    let k = (c - 0x1D6A8) mod 58
    if k < 25: return LetterCase.Upper
    if k in [25, 51]: return LetterCase.None
    return LetterCase.Lower
  if r.isUpper: LetterCase.Upper
  elif r.isLower: LetterCase.Lower
  else: LetterCase.None


func isNotation*(name: string): bool =
  ## Decide whether name is source's notation, i.e. holds non-ASCII letter (III.5).
  name.anyIt(it >= '\x80')


func isCased*(name: string, casing: Casing): bool =
  ## Decide whether name is written in casing; first letter and every letter decide it.
  var
    first = LetterCase.None
    count = 0
    has_upper = false
    has_lower = false
  for r in name.runes:
    let c = r.letterCase
    if count == 0: first = c
    inc count
    has_upper = has_upper or c == LetterCase.Upper
    has_lower = has_lower or c == LetterCase.Lower
  case casing
  of Casing.Pascal: first == LetterCase.Upper and '_' notin name
  of Casing.Camel: first != LetterCase.Upper and '_' notin name
  of Casing.Snake: not has_upper
  of Casing.Screaming: not has_lower
  of Casing.Letter: count == 1 and first == LetterCase.Upper


func casingOf*(d: Declared): Casing =
  ## Read casing declared name takes by its kind and reach (V.1, V.11, V.12).
  case d.kind
  of NameKind.Type, NameKind.Member: Casing.Pascal
  of NameKind.Routine: Casing.Camel
  of NameKind.Field, NameKind.Parameter: Casing.Snake
  of NameKind.Placeholder: Casing.Letter
  of NameKind.Binding: (if d.reach == Reach.Global: Casing.Screaming else: Casing.Snake)


func isMiscased(d: Declared): bool =
  ## Decide whether name breaks case of its kind, as `checkNames` reads it (V.1, V.11, V.12);
  ##   binding of entry block and variable in source's notation carry no case to read.
  if d.kind == NameKind.Binding and d.reach == Reach.Entry: return false
  if d.kind in VARIABLE_KINDS and d.name.isNotation: return false
  not d.name.isCased(d.casingOf)


func acronyms*(name: string): seq[string] =
  ## Read runs of two or more capitals, digits attached, inside camel or Pascal name.
  if name.isCased(Casing.Screaming) or '_' in name: return
  var run = ""
  let text = name & " "
  for k in 0 ..< text.len - 1:
    let
      c = text[k]
      opens_word = c in {'A' .. 'Z'} and text[k + 1] in {'a' .. 'z'}
    if (c in {'A' .. 'Z'} and not opens_word) or (run.len > 0 and c in {'0' .. '9'}): run.add c
    else:
      if run.count({'A' .. 'Z'}) >= 2: result.add run
      run = ""
  if run.count({'A' .. 'Z'}) >= 2: result.add run


func glossaryExemptions*(glossary: string): seq[string] =
  ## Collect code spans under `## Standards` and names of terms, as words name may take.
  var is_standards = false
  for line in glossary.splitLines:
    if line.startsWith("#"): is_standards = line == STANDARDS_HEADING
    if is_standards:
      var i = 0
      while true:
        let open = line.find('`', i)
        if open < 0: break
        let close = line.find('`', open + 1)
        if close < 0: break
        for w in line[open + 1 ..< close].split({' ', ','}):
          if w.len > 0: result.add w
        i = close + 1
    if line.isTermLine: result.add line[2 ..< line.len - 3]


func exemptionsOf*(glossaries: openArray[(string, string)], path: string): seq[string] =
  ## Read words name in path may take beyond table: jargon of V.6, and what root glossary and
  ##   glossary of path's own project list (`glossaryExemptions`).
  result = JARGON.toSeq
  for (glossary, source) in glossaries:
    let directory = glossary[0 ..< glossary.len - ROOT_GLOSSARY.len]
    if glossary == ROOT_GLOSSARY or path.startsWith(directory):
      result.add source.glossaryExemptions


func checkNames*(path, source: string; exempt: openArray[string]): seq[Finding] =
  ## Report declared name that coins abbreviation, carries unlisted acronym, opens routine
  ##   with banned verb, misnames lookup table or boolean, breaks case of its kind, binds in
  ##   entry block, or shares its word with type as global.
  let
    lower_exempt = exempt.mapIt(it.toLowerAscii)
    declared = source.declarations
  var type_keys: seq[string]
  for d in declared:
    if d.kind == NameKind.Type: type_keys.add d.name.toLowerAscii.replace("_", "")
  for d in declared:
    let parts = d.name.words
    for w in parts:
      let full = w.fullWordOf(lower_exempt).toLowerAscii
      if full.len == 0: continue
      result.add finding(
        path,
        d.line,
        "Name coins abbreviation; write `" & full & "` (V.6); got `" & d.name & "`.",
      )
    for a in d.name.acronyms:
      if a.toLowerAscii in lower_exempt: continue
      result.add finding(
        path,
        d.line,
        "Acronym stays only where glossary lists it (V.9); got `" & a & "` in `" & d.name & "`.",
      )
    if d.kind == NameKind.Routine and parts.len > 1 and parts[0] in VERBS_BANNED:
      result.add finding(
        path,
        d.line,
        "Action is imperative verb and property is bare noun (V.3); got `" & d.name & "`.",
      )
    if parts.len > 1 and parts[0].toLowerAscii == "lut" and d.name.toLowerAscii.count("_by_") != 1:
      result.add finding(
        path,
        d.line,
        "Lookup table reads `lut_<value>_by_<key>` (V.5); got `" & d.name & "`.",
      )

    # Boolean is proposition or mode; predicate `func` is `is…` (V.4).
    if d.is_boolean and d.kind == NameKind.Routine:
      if (parts.len < 2 or parts[0] != "is") and d.name notin HOST_PREDICATES:
        result.add finding(
          path,
          d.line,
          "Predicate `func` is `is…` in camel case (V.4); got `" & d.name & "`.",
        )
    elif d.is_boolean and (parts.len < 2 or parts[0].toLowerAscii notin BOOLEAN_PREFIXES):
      result.add finding(
        path,
        d.line,
        "Boolean opens `is_`, `as_`, `should_`, `found_` or `has_` (V.4); got `" & d.name & "`.",
      )

    # Case follows kind; entry binding is reported once, and notation excuses immutable global.
    if d.kind == NameKind.Binding and d.reach == Reach.Entry:
      result.add finding(
        path,
        d.line,
        "Entry block holds no binding; move code that binds into `proc main` " &
          "(V.10); got `" & d.name & "`.",
      )
      continue
    let
      casing = d.casingOf
      is_notation = d.kind in VARIABLE_KINDS and d.name.isNotation
    if is_notation and d.reach == Reach.Global and d.is_mutable:
      result.add finding(
        path,
        d.line,
        "Notation holds over case only for immutable global (III.5); got `" & d.name & "`.",
      )
    elif d.isMiscased:
      let
        rule = if d.kind == NameKind.Member: "V.11" elif casing == Casing.Letter: "V.12" else: "V.1"
        subject = if d.kind == NameKind.Binding: $d.reach else: $d.kind
      result.add finding(
        path,
        d.line,
        subject & " " & CASE_RULES[casing] & " (" & rule & "); got `" & d.name & "`.",
      )
    if d.kind == NameKind.Binding and d.reach == Reach.Global and
        d.name.isCased(Casing.Screaming) and d.name.toLowerAscii.replace("_", "") in type_keys:
      result.add finding(
        path,
        d.line,
        "Global never shares its word with type (V.10); got `" & d.name & "`.",
      )


func cased*(name: string, casing: Casing): string =
  ## Spell name in casing, word by word (V.1, V.11): `localValue` gives `local_value`,
  ##   `Construct_table` gives `constructTable`, `base` gives `Base`.
  ##   Camel and Pascal keep later letters of each word, so `parse_JSON` gives `parseJSON`,
  ##     unless name is capitals alone; `Letter` keeps name, since placeholder's initial is choice.
  let
    parts = name.words
    is_capitals = name.isCased(Casing.Screaming)
  case casing
  of Casing.Snake: result = parts.mapIt(it.toLowerAscii).join("_")
  of Casing.Screaming: result = parts.mapIt(it.toUpperAscii).join("_")
  of Casing.Letter: result = name
  of Casing.Camel, Casing.Pascal:
    for k, part in parts:
      let rest = if is_capitals: part[1 .. ^1].toLowerAscii else: part[1 .. ^1]
      if k == 0 and casing == Casing.Camel: result.add part.toLowerAscii
      else: result.add part[0].toUpperAscii & rest


func wordsOf(line: string): seq[string] =
  ## Read identifiers of one line of code view.
  var word = ""
  for c in line & " ":
    if c in NAME_CHARS: word.add c
    elif word.len > 0:
      result.add word
      word = ""


func foreignMark(code: openArray[string], line: int, kind: NameKind): string =
  ## Read word marking name declared at zero-based line as one foreign code reads by spelling
  ##   (`MARKS_FOREIGN`): on its signature or line, on each line enclosing field or member, or on
  ##   `{.push.}` over it, which stands over foreign bindings alone (STYLE.md §2). Empty where
  ##   none; parameter crosses no boundary by name, since foreign call passes arguments by place.
  if kind == NameKind.Parameter: return
  var pushed = ""
  for i in 0 ..< line:
    let s = code[i].strip
    if s.startsWith("{.push"):
      let marks = s.wordsOf.filterIt(it in MARKS_FOREIGN)
      pushed = if marks.len > 0: marks[0] else: "push"
    elif s.startsWith("{.pop"): pushed = ""
  if pushed.len > 0: return pushed

  # Read declaring lines: signature runs to its closing parenthesis, pragma line after it.
  var
    read = @[line]
    text = code[line]
  while text.count('(') > text.count(')') and read[^1] + 1 < code.len:
    read.add read[^1] + 1
    text.add code[read[^1]]
  if kind == NameKind.Routine and read[^1] + 1 < code.len and
      code[read[^1] + 1].strip.startsWith("{."):
    read.add read[^1] + 1
  if kind in {NameKind.Field, NameKind.Member}:
    var indent = code[line].indentOf
    for i in countdown(line - 1, 0):
      if code[i].strip.len == 0 or code[i].indentOf >= indent: continue
      read.add i
      indent = code[i].indentOf
      if indent == 0: break
  for i in read:
    for word in code[i].wordsOf:
      if word in MARKS_FOREIGN: return word


func isMemberSpelled(
  tokens: openArray[Token], partners: openArray[int], k: int, source: string
): bool =
  ## Decide whether enum member at token `k` carries its own string, so `$` reads no name of it:
  ##   `A = "a"` or `A = (0, "a")`.
  if k + 2 >= tokens.len or tokens[k + 1].spelling(source) != "=": return false
  let value = tokens[k + 2]
  if value.kind == TokenKind.Text: return true
  if value.spelling(source) != "(" or partners[k + 2] < 0: return false
  toSeq(k + 3 ..< partners[k + 2]).anyIt(tokens[it].kind == TokenKind.Text)


func renamesCase*(source: string, exempt: openArray[string]): seq[RenameCase] =
  ## Read rename each declaration needs to take case of its kind, as `checkNames` reports case
  ##   (V.1, V.11), each coined abbreviation spelled out too (V.6). Binding of entry block that
  ##   fix moves into `proc main` takes case of local, as it reads there.
  ##   Rename fix leaves to hand carries refusal: name foreign code reads, member `$` reads, name
  ##     line declares twice, or new name that reads otherwise than rule asks.
  ##   Placeholder (V.12) has none: its letter is initial of what it ranges over, which is choice.
  let
    tokens = source.tokens
    partners = tokens.partners
    starts = source.lineStarts
    code = source.codeOnly.split('\n')
    entry = source.blockEntry
    declared = source.declarations
    lower_exempt = exempt.mapIt(it.toLowerAscii)
  for d in declared:
    var subject = d
    if d.kind == NameKind.Binding and d.reach == Reach.Entry:
      if entry.refusal.len > 0: continue
      subject.reach = Reach.Local
    let casing = subject.casingOf
    if casing == Casing.Letter or not subject.isMiscased: continue

    # Name rule: member, local constant, i.e. local in capitals, or kind as finding names it.
    let
      respelled = d.name.respelled(exempt)
      renamed = respelled.cased(casing)
      rule_case =
        if d.kind == NameKind.Member: "member case (V.11)"
        elif d.kind == NameKind.Binding and subject.reach == Reach.Local and
            d.name.isCased(Casing.Screaming):
          "local constant case (V.1)"
        elif d.kind == NameKind.Binding: ($subject.reach).toLowerAscii & " case (V.1)"
        else: ($d.kind).toLowerAscii & " case (V.1)"
    var rename = RenameCase(
      line: d.line,
      name: d.name,
      renamed: renamed,
      rule: if respelled == d.name: rule_case else: "abbreviation (V.6) and " & rule_case,
      is_local: d.kind == NameKind.Binding and subject.reach == Reach.Local,
    )

    # Find declared name's token from declaration's first line on, where multi-line signature
    #   places parameter below.
    var k = 0
    while k < tokens.len and (tokens[k].line < d.line - 1 or tokens[k].kind != TokenKind.Word or
        tokens[k].spelling(source) != d.name):
      inc k
    if k == tokens.len: continue
    rename.line = tokens[k].line + 1
    rename.column = tokens[k].first - starts[tokens[k].line]

    # Refuse rename that no planner can prove keeps meaning.
    let
      mark = code.foreignMark(tokens[k].line, d.kind)
      acronyms = renamed.acronyms.filterIt(
        it notin d.name.acronyms and it.toLowerAscii notin lower_exempt,
      )
    if declared.countIt(it.line == d.line and it.name == d.name) > 1:
      rename.refusal = "line declares `" & d.name & "` twice"
    elif d.name.isNotation: rename.refusal = "`" & d.name & "` holds letter outside ASCII"
    elif mark.len > 0: rename.refusal = "foreign code reads name through `" & mark & "`"
    elif d.kind == NameKind.Member and not tokens.isMemberSpelled(partners, k, source):
      rename.refusal = "`$` of member reads its name"
    elif not renamed.isCased(casing):
      rename.refusal = "`" & renamed & "` " & CASE_RULES[casing].replace("is ", "is no ")
    elif acronyms.len > 0:
      rename.refusal = "`" & renamed & "` reads `" & acronyms[0] & "` as acronym (V.9)"
    elif d.reach == Reach.Entry and renamed.identity == ROUTINE_ENTRY:
      rename.refusal = "`" & renamed & "` names routine of entry block (V.10)"
    result.add rename
