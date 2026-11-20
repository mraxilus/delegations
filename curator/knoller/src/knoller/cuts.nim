## Read words of each declared name in order of cut V.2 gives, where words decide it alone, and
##   rename name that breaks it at every use, through semantic pass (`rewrites.nim`).
##   Head is what name refers to, and each qualifier narrows it, so cut of last qualifier still
##     names thing, more generally (V.2). Three shapes break it, read from words of name and of
##     names package declares (`kindCut`):
##   - property after its one-letter value: `m_norm_bulk`, where one-letter word opens name and
##     property follows it (`PROPERTIES`), so property leads, as `norm_bulk_m`;
##   - `anti` glued first: `antibasis`, where word after `anti` is word names of package take
##     alone, so `anti` follows it, as `basis_anti`, since V.2 spells `scalarAnti`;
##   - axis value first: `left_name`, where first words are axis values and other word follows,
##     so axis values go last, as `name_left`. Axis value is field of wrapper of V.7 package
##     declares (`axesDeclared`): generic object of one placeholder, named for adjective closing
##     with `-al`, whose every field takes that placeholder, as `Chiral[T]` holds `left`.
##   Name of axis values alone passes, since first value names thing, as `bulkFlat` does. Word of
##     library package imports is no axis value, so caller reads package's names alone.
##   Every other order needs meaning of its words, so reading holds it: `c_complement`,
##     `product_complement`, `constructVectorParity`. Type word first is no shape (Architect's
##     ruling, #443), since its names are chosen on purpose, as `FLOAT_WIDTH` is.
##   Rename moves words in case of name's kind (V.1, V.11), each coined abbreviation spelled out
##     (V.6), so one rename settles cut and case where both break, and caller composes it with
##     case rename of same declaration. Name in notation of source is renamed too, since no
##     letter changes case: `𝐦_grade` becomes `grade_𝐦`.
##   Rename is refused before semantic pass where `renamesCase` refuses: name foreign code reads,
##     member `$` reads, name line declares twice, new name reading as acronym, routine of entry
##     block. Constant define names is refused too, since caller passes define and fix never
##     renames it (Architect's ruling, #443). Planner refuses rest: new name Nim reads as global,
##     as `scalar_anti` reads as `scalarAnti`, so that binding needs name for what it holds.
##   Caller reads axis values and words of package (`axesDeclared`, `wordsDeclared`), and passes
##     them in (`NamesPackage`), since rule reads one file.
##
##   Cost: shapes read words, never meaning, so one-letter word that names no value, or property
##     word naming other noun, reads as shape too, and rename follows it.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils]
from std/unicode import isAlpha, runeAt, runeLen
import ./[declared, entry, names {.all.}, reports, rules, tokens, views]


type KindCut {.pure.} = enum  ## Define shape breaking cut of V.2 that words decide alone.
  None  ## Name passes, or its words leave order to reading.
  Property  ## Property after its one-letter value: `m_grade`.
  Anti  ## `anti` glued before word it qualifies: `antibasis`.
  Axis  ## Axis value before word it qualifies: `left_name`.


const
  PROPERTIES = ["centroid", "grade", "norm", "order", "parity"]
    ## Properties that lead name of value they belong to (V.2, V.3, #443).
  PREFIX_ANTI = "anti"  ## Qualifier domain glues first, which goes after word it qualifies.
  SUFFIX_WRAPPER = "al"  ## Ending of adjective wrapper of V.7 takes, as `Chiral` and `Spatial`.
  PRAGMAS_DEFINE = ["booldefine", "define", "intdefine", "strdefine"]
    ## Pragmas giving constant from define caller passes.
  LENGTH_GLUED_MIN = 3
    ## Letters word glued after `anti` holds at least, so short word reads as no shape.


func isLetterOne(word: string): bool =
  ## Decide whether word is one letter, ASCII or not, as value of equation is (V.6).
  word.runeLen == 1 and word.runeAt(0).isAlpha


func axesDeclared*(source: string): seq[string] =
  ## Read each axis value source declares: field of generic object of one placeholder, named for
  ##   adjective closing with `-al`, whose every field takes that placeholder (V.7).
  let
    declared = source.declarations
    lines = source.codeOnly.split('\n')
  for d in declared:
    if d.kind != KindName.Type or not d.value.startsWith("object"): continue
    if not d.name.endsWith(SUFFIX_WRAPPER): continue
    let held = declared.filterIt(it.kind == KindName.Placeholder and it.line == d.line)
    if held.len != 1: continue

    # Read field lines below type, `when` branches among them, each of placeholder alone.
    let indent = lines[d.line - 1].indentWidth
    var
      fields: seq[string]
      is_wrapper = true
    for i in d.line ..< lines.len:
      let text = lines[i].strip
      if text.len == 0: continue
      if lines[i].indentWidth <= indent: break
      if text.identifierAt(0) in ["when", "elif", "else"]: continue
      let colon = text.find(':')
      if colon < 0 or text[colon + 1 .. ^1].strip != held[0].name:
        is_wrapper = false
        break
      for piece in text[0 ..< colon].split(','):
        let name = piece.strip(chars = {' ', '*'})
        if name.len > 0 and name notin fields: fields.add name
    if is_wrapper and fields.len > 1: result.add fields


func wordsDeclared*(source: string): seq[string] =
  ## Read each word, in lowercase, of each name source declares.
  for d in source.declarations:
    for word in d.name.words:
      let lower = word.toLowerAscii
      if lower notin result: result.add lower


func kindCut(name: string; axes, words: openArray[string]): KindCut =
  ## Read shape of V.2 name breaks, from its words, axis values and words names of package take.
  let
    parts = name.words
    lower = parts.mapIt(it.toLowerAscii)
  if parts.len > 1 and parts[0].isLetterOne and lower[1] in PROPERTIES: return KindCut.Property
  if lower.len > 0 and lower[0].startsWith(PREFIX_ANTI):
    let glued = lower[0][PREFIX_ANTI.len .. ^1]
    if glued.len >= LENGTH_GLUED_MIN and glued in words: return KindCut.Anti
  if parts.len > 1 and lower[0] in axes and not lower.allIt(it in axes): return KindCut.Axis
  KindCut.None


func ordered(name: string; kind: KindCut; axes: openArray[string]): string =
  ## Write words of name in order of cut, joined by `_`, case of each word kept.
  let parts = name.words
  case kind
  of KindCut.None: name
  of KindCut.Property: (parts[1 .. ^1] & parts[0]).join("_")
  of KindCut.Anti:
    let
      first = parts[0]
      split = @[first[PREFIX_ANTI.len .. ^1], first[0 ..< PREFIX_ANTI.len]]
    (split & parts[1 .. ^1]).join("_")
  of KindCut.Axis:
    var lead = 0
    while lead < parts.len and parts[lead].toLowerAscii in axes: inc lead
    (parts[lead .. ^1] & parts[0 ..< lead]).join("_")


func checkCuts*(path, source: string; axes, words: openArray[string]): seq[Report] =
  ## Report each declared name whose words break cut of V.2 where they decide it alone: property
  ##   after its one-letter value, `anti` glued first, axis value first. `axes` and `words` are
  ##   axis values and words of names package declares.
  for d in source.declarations:
    if d.kind == KindName.Placeholder: continue
    let stated =
      case d.name.kindCut(axes, words)
      of KindCut.None: ""
      of KindCut.Property: "Property leads name, value it belongs to last"
      of KindCut.Anti: "Name puts `anti` after word it qualifies, as `scalarAnti`"
      of KindCut.Axis:
        "Name opens with head, axis value `" & d.name.words[0].toLowerAscii & "` last"
    if stated.len > 0:
      result.add initReport(path, d.line, Rule.CutName, stated & "; got `" & d.name & "`.")


func renamesCut*(source: string; axes, words, exempt: openArray[string]): seq[CaseRename] =
  ## Read rename each declaration needs to put its words in order of cut, as `checkCuts` reports
  ##   it, in case of its kind, each coined abbreviation spelled out (V.1, V.6). Rename fix leaves
  ##   to hand carries refusal, as `renamesCase` gives it, or where define names constant.
  let
    tokens = source.tokens
    partners = tokens.partners
    starts = source.lineStarts
    code = source.codeOnly.split('\n')
    entry = source.blockEntry
    declared = source.declarations
    exempt_lower = exempt.mapIt(it.toLowerAscii)
  for d in declared:
    if d.kind == KindName.Placeholder: continue
    let kind = d.name.kindCut(axes, words)
    if kind == KindCut.None: continue
    var subject = d
    if d.kind == KindName.Binding and d.reach == Reach.Entry:
      if entry.refusal.len > 0: continue
      subject.reach = Reach.Local
    let renamed = d.name.ordered(kind, axes).respelled(exempt).cased(subject.casing)
    var rename = CaseRename(
      line: d.line,
      name: d.name,
      renamed: renamed,
      rule: Rule.CutName,
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

    # Refuse rename no planner can prove keeps meaning, as case rename refuses it.
    let
      mark = code.markForeign(tokens[k].line, d.kind)
      acronyms = renamed.acronyms.filterIt(
        it notin d.name.acronyms and it.toLowerAscii notin exempt_lower,
      )
      defines = code[tokens[k].line].wordsPragma.filterIt(it in PRAGMAS_DEFINE)
    if declared.countIt(it.line == d.line and it.name == d.name) > 1:
      rename.refusal = "line declares `" & d.name & "` twice"
    elif defines.len > 0:
      rename.refusal = "`" & defines[0] & "` gives `" & d.name & "`, which caller passes"
    elif mark.len > 0: rename.refusal = "foreign code reads name through `" & mark & "`"
    elif d.kind == KindName.Member and not tokens.isMemberSpelled(partners, k, source):
      rename.refusal = "`$` of member reads its name"
    elif acronyms.len > 0:
      rename.refusal = "`" & renamed & "` reads `" & acronyms[0] & "` as acronym"
    elif d.reach == Reach.Entry and renamed.identity == ROUTINE_ENTRY:
      rename.refusal = "`" & renamed & "` names routine of entry block"
    result.add rename


func composed*(recased, cut: openArray[CaseRename]): seq[CaseRename] =
  ## Join case rename and cut rename one declaration asks into one rename, whose new name settles
  ##   both and whose rule is case's; cut rename of other declaration joins as it stands. Cut
  ##   rename refused leaves case rename alone, and stays beside it, so its refusal warns.
  for r in recased:
    var each = r
    for c in cut:
      if c.line == r.line and c.column == r.column and c.refusal.len == 0: each.renamed = c.renamed
    result.add each
  for c in cut:
    let is_joined = c.refusal.len == 0 and
      recased.anyIt(it.line == c.line and it.column == c.column)
    if not is_joined: result.add c
