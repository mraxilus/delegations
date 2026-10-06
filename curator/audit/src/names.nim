## Read words names may take from glossaries, and plan renames that names check of knoller asks
##   (Article V.1, V.6, V.11; GUIDE.md, Names).
##   Check is knoller's (`names.nim` there, `checkNames`), whose rules read one file alone; this
##     module holds what reads more: words glossaries admit, and renames each use of name needs.
##   `JARGON` is closed list of V.6. Caller adds symbols glossaries list under `## Standards` as
##     code spans, and their `**Term**` names, through `glossaryExemptions`; `exemptionsOf`
##     reads root glossary and glossary of path's own project, and static pass gives them to
##     knoller's check.
##
##   V.6 has fixer (`koch fix`): `abbreviationRenames` reads each declaration coining
##     abbreviation and its full spelling, case kept, as check reads it, and rename planner of
##     `rewrites.nim` renames it at every use through semantic pass, or refuses with reason.
##   V.1 and V.11 have fixer: `renamesCase` reads each declaration whose case check reports, and
##     spells it in case of its kind word by word (`cased`), abbreviation spelled out too; same
##     planner renames it. Binding of entry block that moves takes case of local it becomes.
##     Fix refuses before planner where meaning would leave text: name foreign code reads by
##     spelling (`MARKS_FOREIGN` of knoller on its line, on its type, or `{.push.}` over it), member
##     without own string, whose `$` reads its name, name line declares twice, and new name
##     reading as new acronym. Parameter of foreign routine is renamed: call passes it by place.
##   V.10 has fixer in knoller (`entry.nim`), and declarations are read by its scanner
##     (`declared.nim`).
##
##   Rejected: placeholder rename (V.12), since initial of what it ranges over is choice.
##   Cost: field and type renamed change what `$`, `%` and `fieldPairs` print of them; member
##     is refused for that reason, since its `$` is commonly output. Reading holds rest.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils]
import ../../knoller/src/knoller
import ./glossary


type RenameCase* = object
  ## Define rename case of declaration's kind asks (V.1, V.11), or why fix leaves it to hand.
  line*: int  ## One-based line of declared name.
  column*: int  ## Zero-based byte column of declared name.
  name*: string  ## Name as declared.
  renamed*: string  ## Name in case of its kind, each coined abbreviation spelled out (V.6).
  rule*: string  ## Rule report names, e.g. `local constant case (V.1)`.
  refusal*: string  ## Why fix leaves rename to hand before semantic pass reads it; empty if none.
  is_local*: bool  ## Binding no other module can name: local, or binding of entry block.


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
