## Enforce declared names (Article III.5, V.1, V.3-V.6, V.9, V.11, V.12; V.10 globals), from text
##   of one file.
##   Reads declarations alone, as `declared.nim` reads them: binding, routine, type, field,
##     parameter, enum member and placeholder. Name library owns reaches code only at use site,
##     which is never read, so library clause of V.9 holds by construction. Foreign binding
##     declares library's own name and is skipped for same reason; its parameters are ours.
##   Word is run between `_` and case changes; acronym is run of two or more capitals inside
##     camel or Pascal name. SCREAMING name is all capitals, so its acronyms cannot be told
##     from words and hold by reading.
##   Table `ABBREVIATIONS` gives each banned word its one replacement; word outside table
##     passes, and reading catches rest. `JARGON` is closed list of V.6. Words name may take
##     beyond them are caller's (`exempt`): `curator/audit` reads them from its glossaries
##     (`glossaryExemptions` there), and command line passes none.
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
##   V.10: binding of entry block is entry block's rule (`entry.nim`, `checkBlockEntry`), so it
##     takes no finding here, its case unjudged. Global shares no word with type, compared
##     without case and underscores, as Nim does.
##   V.12: parameter typed `typedesc` is parameter, so snake (Architect's ruling); one capital
##     is for placeholder in brackets after routine or type name, and after `concept`.
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
##   Cost: Pascal name of capitals alone, e.g. `ANTI`, reads as acronym and passes; V.9 and
##     reading hold it. Letter outside `std/unicode` case tables and mathematical block carries
##     no case, so it fits every casing.
##   Cost: word table is short list; `english.nim` of `curator/audit` pays same cost.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, strutils]
from std/unicode import isLower, isUpper, Rune, runes
import ./[declared, reports]


type
  Casing* {.pure.} = enum  ## Define case one kind of name takes (V.1, V.11, V.12).
    Pascal, Camel, Snake, Screaming, Letter

  LetterCase {.pure.} = enum  ## Define case of one letter; digit and symbol carry none.
    None, Lower, Upper


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
  CASE_RULES*: array[Casing, string] = [
    "is `PascalCase`", "is `lowerCamelCase`", "is `snake_case`", "is `SCREAMING_SNAKE_CASE`",
    "is one capital letter",
  ]
    ## Predicate of each casing, as finding states it.


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


func isMiscased*(d: Declared): bool =
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


func checkNames*(path, source: string; exempt: openArray[string]): seq[Report] =
  ## Report declared name that coins abbreviation, carries acronym `exempt` does not list,
  ##   opens routine with banned verb, misnames lookup table or boolean, breaks case of its
  ##   kind, or shares its word with type as global; binding of entry block is entry block's.
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
      result.add initReport(
        path,
        d.line,
        Rule.Abbreviation,
        "Name coins abbreviation; write `" & full & "`; got `" & d.name & "`.",
      )
    for a in d.name.acronyms:
      if a.toLowerAscii in lower_exempt: continue
      result.add initReport(
        path,
        d.line,
        Rule.Acronym,
        "Acronym stays only where glossary lists it; got `" & a & "` in `" & d.name & "`.",
      )
    if d.kind == NameKind.Routine and parts.len > 1 and parts[0] in VERBS_BANNED:
      result.add initReport(
        path,
        d.line,
        Rule.ActionVerb,
        "Action is imperative verb and property is bare noun; got `" & d.name & "`.",
      )
    if parts.len > 1 and parts[0].toLowerAscii == "lut" and d.name.toLowerAscii.count("_by_") != 1:
      result.add initReport(
        path,
        d.line,
        Rule.LookupTable,
        "Lookup table reads `lut_<value>_by_<key>`; got `" & d.name & "`.",
      )

    # Boolean is proposition or mode; predicate `func` is `is…` (V.4).
    if d.is_boolean and d.kind == NameKind.Routine:
      if (parts.len < 2 or parts[0] != "is") and d.name notin HOST_PREDICATES:
        result.add initReport(
          path,
          d.line,
          Rule.BooleanName,
          "Predicate `func` is `is…` in camel case; got `" & d.name & "`.",
        )
    elif d.is_boolean and (parts.len < 2 or parts[0].toLowerAscii notin BOOLEAN_PREFIXES):
      result.add initReport(
        path,
        d.line,
        Rule.BooleanName,
        "Boolean opens `is_`, `as_`, `should_`, `found_` or `has_`; got `" & d.name & "`.",
      )

    # Case follows kind; entry binding is entry block's, and notation excuses immutable global.
    if d.kind == NameKind.Binding and d.reach == Reach.Entry: continue
    let
      casing = d.casingOf
      is_notation = d.kind in VARIABLE_KINDS and d.name.isNotation
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
          if d.kind == NameKind.Member: Rule.MemberCase
          elif casing == Casing.Letter: Rule.PlaceholderLetter
          else: Rule.NameCase
        subject = if d.kind == NameKind.Binding: $d.reach else: $d.kind
      result.add initReport(
        path,
        d.line,
        rule,
        subject & " " & CASE_RULES[casing] & "; got `" & d.name & "`.",
      )
    if d.kind == NameKind.Binding and d.reach == Reach.Global and
        d.name.isCased(Casing.Screaming) and d.name.toLowerAscii.replace("_", "") in type_keys:
      result.add initReport(
        path,
        d.line,
        Rule.GlobalWord,
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
