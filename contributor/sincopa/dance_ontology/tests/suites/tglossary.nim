## Hold chain's names to glossary they are meant to speak.
##   `GLOSSARY.md` is agreed vocabulary, and every entry carries `_Avoid_` line
##     naming words that entry replaced.  Nothing in project read that line, so
##     build could print word glossary rejects and stay green -- which is what
##     happened: chain's two middle shapes were written `X` and `box`, both
##     listed under `_Avoid_`, while glossary called them `Cross` and
##     `Diamond`.
##   Law is glossary's, not this file's: document is parsed rather than
##     restated, so ruling made there reaches build without second edit here
##     (Article II.1).
##   Every hold walks same chain (rule 31), so claim is made over both holds
##     workbench draws, never over one example (Article IX.2).

import std/[math, options, os, strutils, tables, unittest]

import ../../design/parts
import ../../design/rules
from ../../src/dance_ontology/rotation import nil


const
  GLOSSARY = currentSourcePath().parentDir.parentDir.parentDir / "GLOSSARY.md"
    ## Vocabulary this project agreed, beside its code.
  REPORT = currentSourcePath().parentDir.parentDir.parentDir / "sim" / "verdicts.md"
    ## Report sim writes, which is what reader of sim reads.
  RUNG_AT = {50: "cross", 100: "diamond", 150: "swan"}.toTable
    ## Glossary's word for each rung of chain, by turns in hundredths.
    ##   Hundredths because report prints turns to two places, and key must
    ##     compare exactly.
  SHAPE_AT = {0: "Neutral", 5: "Cross", 10: "Diamond", 15: "Swan"}.toTable
    ## Glossary's word for each step of chain, by wind in tenths of turn.
    ##   Tenths because wind is float and key must compare exactly.
  CHAIN_TERMS = ["Neutral", "Cross", "Diamond", "Swan"]
    ## Entries naming step of chain, which are only ones position may speak.
    ##   Rest of glossary is held to elsewhere; word another entry rejects is
    ##     no business of position's name.
  FACING_TERMS = ["Pillion", "Sidecar"]
    ## Entries naming facing whose rejected words name facing and nothing else.
    ##   Face-to-face and Back-to-back are left out: they reject `facing` and
    ##     `apart`, which report says in own sense, of what no facing says and
    ##     of distance couple stand at.
  DANCER_TERMS = ["Lead", "Follow"]
    ## Entries naming dancer, whose rejected words no page may say at all.
  SAID_IN = ["design", "app", "sim"]
    ## Directories whose string literals reach reader: page written into markup,
    ##   element set by browser, or row of `sim/verdicts.md`.
  DOCUMENTS = ["mockups" / "wholecloth.html", "pages" / "review" / "review.html"]
    ## Pages this project writes by hand rather than from Nim.
  HOLDS = [HAND_TO_HAND, [some Arm.L, some Arm.R]]
    ## Both holds workbench walks: app's own frame, and its dual (rule 31).


func avoided(source: string; terms: openArray[string]): Table[string, seq[string]] =
  ## Collect words each named entry replaced, by term entry names.
  ##   Entry opens `**Term**:` and its rejected words sit on `_Avoid_:` line
  ##     inside same entry, comma separated.
  var term = ""
  for line in source.splitLines:
    let bare = line.strip
    if bare.startsWith("**") and bare.endsWith("**:"):
      term = bare[2 ..< bare.len - 3]
    elif bare.startsWith("_Avoid_:") and term in terms:
      for word in bare["_Avoid_:".len .. ^1].split(','):
        result.mgetOrPut(term, @[]).add word.strip.toLowerAscii


func literals(source: string): seq[tuple[said: string; next: char]] =
  ## Every string literal of Nim source, with character that follows it.
  ##   Follower tells key of object, which is data, from text page shows: writer
  ##     of sweep data holds `"him":` as key, and browser reads it back by that
  ##     name.  Cost: gendered word used as key passes this check, and rename of
  ##     those keys waits on rewrite of recorded sweeps.
  var i = 0
  while i < source.len:
    if source[i] == '#' :
      while i < source.len and source[i] != '\n': i += 1
    elif source.continuesWith("\"\"\"", i):
      let opens = i + 3
      var shuts = source.find("\"\"\"", opens)
      if shuts < 0: shuts = source.len
      result.add (source[opens ..< shuts], (if shuts + 3 < source.len: source[shuts + 3] else: ' '))
      i = shuts + 3
    elif source[i] == '\"':
      var j = i + 1
      while j < source.len and source[j] != '\"':
        if source[j] == '\\': j += 1
        j += 1
      result.add (source[i + 1 ..< min(j, source.len)],
                  (if j + 1 < source.len: source[j + 1] else: ' '))
      i = j + 1
    else:
      i += 1


func rungsOf(report: string): seq[tuple[turns: int, said, facing: string]] =
  ## Read chain table of report: how far each rung is wound, word report gave
  ## that rung, and facing it stands at.
  ##   Rung cell reads `<word> (<turns>)`, under header that names its columns,
  ##     and facing cell follows it.
  var inside = false
  for line in report.splitLines:
    let bare = line.strip
    if bare.startsWith("| level | rung |"):
      inside = true
      continue
    if not inside: continue
    if not bare.startsWith("|"): break
    if bare.startsWith("|---"): continue
    let cells = bare.strip(chars = {'|', ' '}).split('|')
    if cells.len < 3: continue
    let
      cell = cells[1].strip
      opens = cell.find('(')
      shuts = cell.find(')')
    if opens < 0 or shuts < opens: continue
    var wound: float
    try:
      wound = parseFloat(cell[opens + 1 ..< shuts])
    except ValueError:
      continue
    result.add (int(round(wound * 100.0)), cell[0 ..< opens].strip, cells[2].strip)


func says(text, phrase: string): bool =
  ## Decide whether text speaks phrase as whole words, not inside longer one.
  var from_here = 0
  while true:
    let at = text.find(phrase, from_here)
    if at < 0: return false
    if (at == 0 or text[at - 1] notin Letters) and
        (at + phrase.len >= text.len or text[at + phrase.len] notin Letters):
      return true
    from_here = at + 1


suite "chain speaks glossary":
  let
    source = readFile(GLOSSARY)
    rejected = source.avoided(CHAIN_TERMS)

  test "glossary still names every step of chain":
    # Laws below are vacuous where entries they read are missing, so entries
    # are demanded first.
    for term in CHAIN_TERMS:
      check term in rejected
      check rejected[term].len > 0

  test "no position is named by word glossary rejects":
    for holds in HOLDS:
      for position in chainFor(holds):
        let name = position.name.toLowerAscii
        for _, words in rejected:
          for word in words:
            check not name.says(word)

  test "every position carries glossary's own word":
    for holds in HOLDS:
      for position in chainFor(holds):
        let tenths = int(abs(position.wind) * 10)
        if tenths in SHAPE_AT:
          check position.name.toLowerAscii.says(SHAPE_AT[tenths].toLowerAscii)


suite "pages speak of the lead and the follow":
  ## Glossary rejects every gendered word for dancer, and page is where reader
  ##   meets it.  Readout of whole-cloth panel said `her arm`, and reason turn
  ##   blocked said `his reach`, while every other law passed.
  let
    source = readFile(GLOSSARY)
    rejected = source.avoided(DANCER_TERMS)
    root = currentSourcePath().parentDir.parentDir.parentDir

  test "glossary still rejects a gendered word for each dancer":
    for term in DANCER_TERMS:
      check term in rejected
      check rejected[term].len > 0

  var gendered: seq[string]
  for _, words in rejected:
    for word in words: gendered.add word

  test "no string a page shows says a gendered word":
    for dir in SAID_IN:
      for path in walkDirRec(root / dir):
        if path.splitFile.ext != ".nim": continue
        for (said, next) in readFile(path).literals:
          if next == ':': continue  # key of object, read back by that name
          for word in gendered:
            if said.toLowerAscii.says(word):
              checkpoint path.extractFilename & " says `" & word & "`: " & said
              fail()

  test "no page written by hand says a gendered word":
    for name in DOCUMENTS:
      let said = readFile(root / name).toLowerAscii
      for word in gendered:
        if said.says(word):
          checkpoint name & " says `" & word & "`"
          fail()


suite "the report speaks glossary":
  ## Chain table of `sim/verdicts.md` names every rung.  It said `X`, which
  ##   entry **Cross** rejects, while `design/parts` named same rung right: one
  ##   chain, two namings, one of them wrong.
  ##   Report is what reader of sim reads, so law reads written bytes back
  ##     rather than function that wrote them (Article IX.5).
  let
    source = readFile(GLOSSARY)
    rejected = source.avoided(CHAIN_TERMS)
    report = readFile(REPORT)
    rungs = rungsOf(report)

  test "report still tabulates every rung of chain":
    # Laws below say nothing where table is missing or unparsed, so rows are
    # demanded first.
    check rungs.len > 0
    for (wound, _, _) in rungs:
      check wound in RUNG_AT

  test "no rung of report is named by word glossary rejects":
    for (wound, said, _) in rungs:
      for _, words in rejected:
        for word in words:
          if said.toLowerAscii.says(word):
            checkpoint "rung at " & $wound & " says `" & word & "`: " & said
            fail()

  test "every rung of report carries glossary's own word":
    for (wound, said, _) in rungs:
      check said.toLowerAscii.says(RUNG_AT[wound])

  test "every rung of report stands at facing model gives its turn":
    ## Report reads facing off stance sim winds couple to (`words.facingName`),
    ##   and model reads it off turn each dancer takes on spot (`rotation.facing`).
    ##   Chain rests Face-to-face and sim turns follow, anticlockwise positive,
    ##     where model counts quarters to dancer's right.
    for (wound, _, said) in rungs:
      let
        turned = [rotation.Dancer.Lead: 0, rotation.Dancer.Follow: -(wound div 25)]
        want = rotation.facing(rotation.seenAfter(turned))
      check want.isSome
      if want.isSome: check said == want.get.name

  test "no facing of report is named by word glossary rejects":
    ## Report named rest of same-name pair `pillion lead`, which entry
    ##   **Pillion** rejects, while every page named it `Pillion`.
    let faced = source.avoided(FACING_TERMS)
    check faced.len == FACING_TERMS.len
    for _, words in faced:
      for word in words:
        if report.toLowerAscii.says(word):
          checkpoint "report says `" & word & "`"
          fail()
