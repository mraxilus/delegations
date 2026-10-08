## Enforce declared names (Article III.5, V.1, V.3-V.6, V.11, V.12; V.10 globals), from text of
##   one file.
##   Reads declarations alone, as `declared.nim` reads them: binding, routine, type, field,
##     parameter, enum member and placeholder. Name library owns reaches code only at use site,
##     which is never read. Foreign binding declares library's own name, so it is skipped; its
##     parameters are ours.
##   Word is run between `_` and case changes.
##   Table `ABBREVIATIONS` gives each banned word its one replacement; word outside table
##     passes, and reading catches rest. `JARGON` is closed list of V.6. Words name may take
##     beyond them are caller's (`exempt`): `curator/audit` reads them from its glossaries
##     (`exemptionsGlossary` there), and command line passes none.
##   V.9 is no rule here: acronym stays only where glossary lists it, and glossary belongs to
##     repository, so knoller, which runs on any repository, reads none. `curator/audit` checks
##     acronyms (`checkAcronyms` there), from words of its glossaries (D2 of #572).
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
##     letters carry no case in `std/unicode`, so `caseLetter` reads them by block. Operator is
##     backticked, so it is never read as name.
##   V.10: binding of entry block is entry block's rule (`entry.nim`, `checkBlockEntry`), so it
##     takes no finding here, its case unjudged. Global shares no word with type, compared
##     without case and underscores, as Nim does.
##   V.12: placeholder in brackets after routine or type name, or after `concept`, is one capital.
##     Generic parameter, i.e. of type `typedesc` alone (`declared.nim`), stands for any type as
##     generic does, so it takes placeholder's letter (Architect's ruling, #443). Snake passes
##     beside it until `pga_benchmark` renames its `kind`, since check reddening project cannot
##     merge (CURATOR.md, duty 3). No rename of case touches either form. `typedesc[I]` holds
##     placeholder `I`, so its parameter stays snake.
##   V.4: boolean binding, field or parameter opens `is`, `as`, `should`, `found` or `has`,
##     with word after it. `func` returning `bool` is predicate and opens `is`. `proc`
##     returning `bool` reports success of action (V.3), so it is unread (Architect's ruling);
##     `func` writing `var` parameter is action too, and is unread for same reason.
##   V.3: routine never opens with `get`, `compute` or `new`. V.5: name opening `lut` reads
##     `lut_<value>_by_<key>`.
##   No fixer here: renames reach every use of name, which only semantic pass of compiler finds,
##     so `curator/audit` plans them (`names.nim` and `rewrites.nim` there) from spellings this
##     module gives (`respelled`, `cased`).
##
##   Cost: text scanner, never parser (`declared.nim`).
##   Cost: boolean is read only where declaration shows it: type `bool`, or value literal
##     `true` or `false`. Boolean from call or expression holds by reading.
##   Cost: `in` calls `contains` by spelling, so predicate of that name keeps host's name.
##   Cost: generic parameter passes in two cases until `pga_benchmark` renames its `kind`, so one
##     file may spell two generic parameters two ways; reading holds it.
##   Cost: Pascal name of capitals alone, e.g. `ANTI`, passes case of type; reading holds it.
##     Letter outside `std/unicode` case tables and mathematical block carries no case, so it
##     fits every casing.
##   Cost: word table is short list; `english.nim` of `curator/audit` pays same cost.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, strutils]
from std/unicode import isLower, isUpper, Rune, runes
import ./[declared, entry, reports, rules, tokens, views]


type
  Casing* {.pure.} = enum  ## Define case one kind of name takes (V.1, V.11, V.12).
    Pascal, Camel, Snake, Screaming, Letter

  CaseLetter {.pure.} = enum  ## Define case of one letter; digit and symbol carry none.
    None, Lower, Upper


type CaseRename* = object
  ## Define rename case of declaration's kind asks (V.1, V.11), or why fix leaves it to hand.
  line*: int  ## One-based line of declared name.
  column*: int  ## Zero-based byte column of declared name.
  name*: string  ## Name as declared.
  renamed*: string  ## Name in case of its kind, each coined abbreviation spelled out (V.6).
  rule*: Rule  ## Rule rename fixes: case of name, or of member (V.1, V.11).
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
  PREFIXES_BOOLEAN* = ["is", "as", "should", "found", "has"]
    ## First words boolean takes: state, interpretation, policy, search outcome, possession (V.4).
  KINDS_VARIABLE = {KindName.Binding, KindName.Field, KindName.Parameter}
    ## Kinds naming variable, which source's notation may name at any scope (III.5).
  PREDICATES_HOST = ["contains"]
    ## Predicates host calls by spelling: `in` and `notin` call `contains`.
  RULES_CASE*: array[Casing, string] = [
    "is `PascalCase`", "is `lowerCamelCase`", "is `snake_case`", "is `SCREAMING_SNAKE_CASE`",
    "is one capital letter",
  ]
    ## Predicate of each casing, as finding states it.
  RULE_GENERIC = "Parameter of type `typedesc` alone is one capital letter or `snake_case`"
    ## Case generic parameter takes, as finding states it: placeholder's letter (V.12), or snake
    ##   until `pga_benchmark` renames its `kind` (#443).


func spansWord(name: string): seq[(int, int)] =
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
    let is_boundary = (c in {'A'..'Z'} and name[k-1] in {'a'..'z', '0'..'9'}) or
      (c in {'a'..'z'} and k - first > 1 and name[k-1] in {'A'..'Z'} and
        name[k-2] in {'A'..'Z'})
    if not is_boundary: continue
    # Capital before lowercase starts new word: `JSONData` is JSON, Data.
    let cut = if c in {'a'..'z'}: k - 1 else: k
    result.add (first, cut)
    first = cut
  if first >= 0: result.add (first, name.len)


func words*(name: string): seq[string] =
  ## Split name at `_` and at case changes: `lut_grade`, `wedgeAnti`, `JSONData` give words.
  name.spansWord.mapIt(name[it[0]..<it[1]])


func wordFullOf(word: string, exempt_lower: openArray[string]): string =
  ## Read full word `ABBREVIATIONS` gives coined abbreviation, in word's own case; empty where
  ##   word is none, or exempt.
  let lower = word.toLowerAscii
  if lower in exempt_lower or lower in JARGON: return
  for (short, full) in ABBREVIATIONS:
    if lower != short: continue
    if word == lower: return full
    if word == word.toUpperAscii: return full.toUpperAscii
    return full.capitalizeAscii


func respelled*(name: string, exempt: openArray[string]): string =
  ## Spell name with each coined abbreviation written out, case kept (V.6): `ctx_dir` gives
  ##   `context_directory`, `bufSize` gives `bufferSize`. Same name where it coins none.
  let exempt_lower = exempt.mapIt(it.toLowerAscii)
  result = name
  for (first, after) in name.spansWord.reversed:
    let full = name[first..<after].wordFullOf(exempt_lower)
    if full.len > 0: result = result[0..<first] & full & result[after .. ^1]


func caseLetter(r: Rune): CaseLetter =
  ## Read case of letter, mathematical alphanumerics by block, since `std/unicode` maps none.
  ##   Latin styles run 52 letters, 26 capitals first; Greek styles run 58, 25 capitals first,
  ##     then nabla, 25 small, partial differential and 6 small variants.
  let c = int(r)
  if c in 0x1D400..0x1D6A3:
    return (if (c - 0x1D400) mod 52 < 26: CaseLetter.Upper else: CaseLetter.Lower)
  if c in 0x1D6A8..0x1D7C9:
    let k = (c - 0x1D6A8) mod 58
    if k < 25: return CaseLetter.Upper
    if k in [25, 51]: return CaseLetter.None
    return CaseLetter.Lower
  if r.isUpper: CaseLetter.Upper
  elif r.isLower: CaseLetter.Lower
  else: CaseLetter.None


func isNotation*(name: string): bool =
  ## Decide whether name is source's notation, i.e. holds non-ASCII letter (III.5).
  name.anyIt(it >= '\x80')


func isCased*(name: string, casing: Casing): bool =
  ## Decide whether name is written in casing; first letter and every letter decide it.
  var
    first = CaseLetter.None
    count = 0
    has_upper = false
    has_lower = false
  for r in name.runes:
    let c = r.caseLetter
    if count == 0: first = c
    inc count
    has_upper = has_upper or c == CaseLetter.Upper
    has_lower = has_lower or c == CaseLetter.Lower
  case casing
  of Casing.Pascal: first == CaseLetter.Upper and '_' notin name
  of Casing.Camel: first != CaseLetter.Upper and '_' notin name
  of Casing.Snake: not has_upper
  of Casing.Screaming: not has_lower
  of Casing.Letter: count == 1 and first == CaseLetter.Upper


func casingOf*(d: Declared): Casing =
  ## Read casing declared name takes by its kind and reach (V.1, V.11, V.12); generic parameter
  ##   takes placeholder's.
  case d.kind
  of KindName.Type, KindName.Member: Casing.Pascal
  of KindName.Routine: Casing.Camel
  of KindName.Field: Casing.Snake
  of KindName.Parameter: (if d.is_generic: Casing.Letter else: Casing.Snake)
  of KindName.Placeholder: Casing.Letter
  of KindName.Binding: (if d.reach == Reach.Global: Casing.Screaming else: Casing.Snake)


func isMiscased*(d: Declared): bool =
  ## Decide whether name breaks case of its kind, as `checkNames` reads it (V.1, V.11, V.12);
  ##   binding of entry block and variable in source's notation carry no case to read, and
  ##   generic parameter passes as snake too (`RULE_GENERIC`).
  if d.kind == KindName.Binding and d.reach == Reach.Entry: return false
  if d.kind in KINDS_VARIABLE and d.name.isNotation: return false
  if d.is_generic and d.name.isCased(Casing.Snake): return false
  not d.name.isCased(d.casingOf)


func checkNames*(path, source: string; exempt: openArray[string]): seq[Report] =
  ## Report declared name that coins abbreviation `exempt` does not list, opens routine with
  ##   banned verb, misnames lookup table or boolean, breaks case of its kind, or shares its word
  ##   with type as global; binding of entry block is entry block's. Acronym is caller's (V.9).
  let
    exempt_lower = exempt.mapIt(it.toLowerAscii)
    declared = source.declarations
  var keys_type: seq[string]
  for d in declared:
    if d.kind == KindName.Type: keys_type.add d.name.toLowerAscii.replace("_", "")
  for d in declared:
    let parts = d.name.words
    for w in parts:
      let full = w.wordFullOf(exempt_lower).toLowerAscii
      if full.len == 0: continue
      result.add initReport(
        path,
        d.line,
        Rule.Abbreviation,
        "Name coins abbreviation; write `" & full & "`; got `" & d.name & "`.",
      )
    if d.kind == KindName.Routine and parts.len > 1 and parts[0] in VERBS_BANNED:
      result.add initReport(
        path,
        d.line,
        Rule.VerbAction,
        "Action is imperative verb and property is bare noun; got `" & d.name & "`.",
      )
    if parts.len > 1 and parts[0].toLowerAscii == "lut" and d.name.toLowerAscii.count("_by_") != 1:
      result.add initReport(
        path,
        d.line,
        Rule.TableLookup,
        "Lookup table reads `lut_<value>_by_<key>`; got `" & d.name & "`.",
      )

    # Boolean is proposition or mode; predicate `func` is `is…` (V.4).
    if d.is_boolean and d.kind == KindName.Routine:
      if (parts.len < 2 or parts[0] != "is") and d.name notin PREDICATES_HOST:
        result.add initReport(
          path,
          d.line,
          Rule.NameBoolean,
          "Predicate `func` is `is…` in camel case; got `" & d.name & "`.",
        )
    elif d.is_boolean and (parts.len < 2 or parts[0].toLowerAscii notin PREFIXES_BOOLEAN):
      result.add initReport(
        path,
        d.line,
        Rule.NameBoolean,
        "Boolean opens `is_`, `as_`, `should_`, `found_` or `has_`; got `" & d.name & "`.",
      )

    # Case follows kind; entry binding is entry block's, and notation excuses immutable global.
    if d.kind == KindName.Binding and d.reach == Reach.Entry: continue
    let
      casing = d.casingOf
      is_notation = d.kind in KINDS_VARIABLE and d.name.isNotation
    if is_notation and d.reach == Reach.Global and d.is_mutable:
      result.add initReport(
        path,
        d.line,
        Rule.Notation,
        "Notation holds over case only for immutable global; got `" & d.name & "`.",
      )
    elif d.isMiscased:
      let
        rule =
          if d.kind == KindName.Member: Rule.CaseMember
          elif casing == Casing.Letter: Rule.LetterPlaceholder
          else: Rule.CaseName
        subject = if d.kind == KindName.Binding: $d.reach else: $d.kind
        stated = if d.is_generic: RULE_GENERIC else: subject & " " & RULES_CASE[casing]
      result.add initReport(
        path,
        d.line,
        rule,
        stated & "; got `" & d.name & "`.",
      )
    if d.kind == KindName.Binding and d.reach == Reach.Global and
        d.name.isCased(Casing.Screaming) and d.name.toLowerAscii.replace("_", "") in keys_type:
      result.add initReport(
        path,
        d.line,
        Rule.WordGlobal,
        "Global never shares its word with type; got `" & d.name & "`.",
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


func acronyms*(name: string): seq[string] =
  ## Read runs of two or more capitals, digits attached, inside camel or Pascal name.
  if name.isCased(Casing.Screaming) or '_' in name: return
  var run = ""
  let text = name & " "
  for k in 0 ..< text.len - 1:
    let
      c = text[k]
      opens_word = c in {'A'..'Z'} and text[k+1] in {'a'..'z'}
    if (c in {'A'..'Z'} and not opens_word) or (run.len > 0 and c in {'0'..'9'}): run.add c
    else:
      if run.count({'A'..'Z'}) >= 2: result.add run
      run = ""
  if run.count({'A'..'Z'}) >= 2: result.add run


func renamesAbbreviation*(
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
      if t.line == d.line - 1 and t.kind == KindToken.Word and t.spelling(source) == d.name:
        result.add (d.line, t.first - starts[t.line], d.name, renamed)
        break


func wordsOf(line: string): seq[string] =
  ## Read identifiers of one line of code view.
  var word = ""
  for c in line & " ":
    if c in CHARS_NAME: word.add c
    elif word.len > 0:
      result.add word
      word = ""


func markForeign(code: openArray[string], line: int, kind: KindName): string =
  ## Read word marking name declared at zero-based line as one foreign code reads by spelling
  ##   (`MARKS_FOREIGN`): on its signature or line, on each line enclosing field or member, or on
  ##   `{.push.}` over it, which stands over foreign bindings alone (STYLE.md §2). Empty where
  ##   none; parameter crosses no boundary by name, since foreign call passes arguments by place.
  if kind == KindName.Parameter: return
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
  if kind == KindName.Routine and read[^1] + 1 < code.len and
      code[read[^1] + 1].strip.startsWith("{."):
    read.add read[^1] + 1
  if kind in {KindName.Field, KindName.Member}:
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
  if value.kind == KindToken.Text: return true
  if value.spelling(source) != "(" or partners[k + 2] < 0: return false
  toSeq(k + 3 ..< partners[k + 2]).anyIt(tokens[it].kind == KindToken.Text)


func renamesCase*(source: string, exempt: openArray[string]): seq[CaseRename] =
  ## Read rename each declaration needs to take case of its kind, as `checkNames` reports case
  ##   (V.1, V.11), each coined abbreviation spelled out too (V.6). Binding of entry block that
  ##   fix moves into `proc main` takes case of local, as it reads there.
  ##   Rename fix leaves to hand carries refusal: name foreign code reads, member `$` reads, name
  ##     line declares twice, or new name that reads otherwise than rule asks.
  ##   Placeholder (V.12) has none, nor generic parameter, which takes its letter: letter is
  ##     initial of what it ranges over, which is choice.
  let
    tokens = source.tokens
    partners = tokens.partners
    starts = source.lineStarts
    code = source.codeOnly.split('\n')
    entry = source.blockEntry
    declared = source.declarations
    exempt_lower = exempt.mapIt(it.toLowerAscii)
  for d in declared:
    var subject = d
    if d.kind == KindName.Binding and d.reach == Reach.Entry:
      if entry.refusal.len > 0: continue
      subject.reach = Reach.Local
    let casing = subject.casingOf
    if casing == Casing.Letter or not subject.isMiscased: continue

    # Name rule: case of member (V.11), else case of name's kind (V.1); spelling out each coined
    #   abbreviation rides on it (V.6).
    let renamed = d.name.respelled(exempt).cased(casing)
    var rename = CaseRename(
      line: d.line,
      name: d.name,
      renamed: renamed,
      rule: if d.kind == KindName.Member: Rule.CaseMember else: Rule.CaseName,
      is_local: d.kind == KindName.Binding and subject.reach == Reach.Local,
    )

    # Find declared name's token from declaration's first line on, where multi-line signature
    #   places parameter below.
    var k = 0
    while k < tokens.len and (tokens[k].line < d.line - 1 or tokens[k].kind != KindToken.Word or
        tokens[k].spelling(source) != d.name):
      inc k
    if k == tokens.len: continue
    rename.line = tokens[k].line + 1
    rename.column = tokens[k].first - starts[tokens[k].line]

    # Refuse rename that no planner can prove keeps meaning.
    let
      mark = code.markForeign(tokens[k].line, d.kind)
      acronyms = renamed.acronyms.filterIt(
        it notin d.name.acronyms and it.toLowerAscii notin exempt_lower,
      )
    if declared.countIt(it.line == d.line and it.name == d.name) > 1:
      rename.refusal = "line declares `" & d.name & "` twice"
    elif d.name.isNotation: rename.refusal = "`" & d.name & "` holds letter outside ASCII"
    elif mark.len > 0: rename.refusal = "foreign code reads name through `" & mark & "`"
    elif d.kind == KindName.Member and not tokens.isMemberSpelled(partners, k, source):
      rename.refusal = "`$` of member reads its name"
    elif not renamed.isCased(casing):
      rename.refusal = "`" & renamed & "` " & RULES_CASE[casing].replace("is ", "is no ")
    elif acronyms.len > 0:
      rename.refusal = "`" & renamed & "` reads `" & acronyms[0] & "` as acronym"
    elif d.reach == Reach.Entry and renamed.identity == ROUTINE_ENTRY:
      rename.refusal = "`" & renamed & "` names routine of entry block"
    result.add rename
