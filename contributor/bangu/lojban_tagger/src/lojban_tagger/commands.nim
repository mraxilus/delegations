## Answer each verb of `tagger` as pure function of its arguments and index read before it.
##
##   |---------------------------|-------------------------------------------------------------|
##   | Verb                      | Effect                                                      |
##   |---------------------------|-------------------------------------------------------------|
##   | tag <name> <word>...      | tag entity with each word; refuse all where one is no tag   |
##   | untag <name> <word>...    | remove each tag; entity with none left leaves index         |
##   | find <term>...            | print each entity satisfying every term; report each term   |
##   | show [<name>]             | print every entity, or one, with its tags                   |
##   | read <word>...            | explain each word: rafsi, gismu, preferred form, English    |
##   |---------------------------|-------------------------------------------------------------|
##   Exit: 0 done, 1 refused or found nothing, 2 usage error; `grep` does same.
##
##   Verbs compute; `app/tagger.nim` reads file, calls `run`, writes file where index changed,
##     and prints. So suites drive every verb without file, and one suite drives built binary
##     too, for wiring (Article IX.5).
##   Entity prints as name, tab, then each tag in form 4.12 prefers, space apart: line any
##     other tool splits at tab.
##   Report goes to standard error: how each term read, and why each refusal.

{.experimental: "strictFuncs".}

import std/[options, sequtils, strutils]

import ./[dictionary, english, index, lujvo, search, tags]


type
  Outcome* = object  ## Define what verb answers: exit code, output, report, and index after it.
    code*: int  ## Exit code: 0 done, 1 refused or found nothing, 2 usage error.
    output*: string  ## Text for standard output.
    report*: string  ## Text for standard error.
    is_changed*: bool  ## Index changed, so caller writes it.
    index*: Index  ## Index after verb.


const
  USAGE* = "Usage: tagger [--index:<path>] " &
      "<tag <name> <word>...|untag <name> <word>...|find <term>...|show [<name>]|read <word>...>\n"
    ## Text printed on usage error.
  COUNT_MEANINGS_SHOWN = 8  ## Meanings report names per English term before it counts rest.



#[ Rendering ]#

func explain*(reading: Reading): string =
  ## Render why text is no tag, ending in offending text.
  let text = "`" & reading.text & "`"
  case reading.refusal
  of Refusal.Empty: "Tag should hold letters; got ``."
  of Refusal.Letter: "Tag should hold Lojban letters alone; got `" & reading.detail & "` in " &
      text & "."
  of Refusal.Cmavo: "Tag should be made of gismu alone; got cmavo `" & reading.detail &
      "` in " & text & "."
  of Refusal.Unlisted: "Gismu should be in gismu list; got " & text & "."
  of Refusal.Rafsi: "Rafsi should be assigned in gismu list; got `" & reading.detail &
      "` in " & text & "."
  of Refusal.Ambiguous: "Rafsi should name one gismu; got `" & reading.detail &
      "`, which several share, in " & text & "."
  of Refusal.Hyphen: "Hyphens should be those of CLL 4.11, i.e. `" & reading.detail &
      "`; got " & text & "."
  of Refusal.Shape: "Text should be gismu or lujvo; got " & text & "."


func toLine(entity: Entity): string =
  ## Render entity as name, tab, then each tag in preferred form.
  entity.name & "\t" & entity.tags.mapIt($it).join(" ") & "\n"


func describe(term: Term): string =
  ## Render how term read: as tag with its gismu, as English with its meanings, or as nothing.
  let text = "`" & term.reading.text & "`"
  if term.reading.is_tag:
    return text & " reads as tag `" & term.reading.tag.toTanru & "`.\n"
  if term.meanings.len == 0:
    return text & " reads as neither tag nor English of lists, so finds nothing; " &
        term.reading.explain & "\n"
  var shown: seq[string]
  for meaning in term.meanings[0 ..< min(term.meanings.len, COUNT_MEANINGS_SHOWN)]:
    shown.add meaning.words.mapIt($it).join("+") & " (" & meaning.textEnglish & ")"
  let rest = term.meanings.len - shown.len
  text & " reads as English: " & shown.join(", ") &
      (if rest > 0: ", and " & $rest & " more" else: "") & ".\n"



#[ Verbs ]#

func readWords(words: openArray[string]): tuple[tags: seq[Tag], report: string] =
  ## Read each word as tag; report names every refusal.
  for text in words:
    let reading = text.readTag
    if reading.is_tag: result.tags.add reading.tag
    else: result.report.add reading.explain & "\n"


func explainWord(text: string): string =
  ## Render everything reader knows of one word.
  let reading = text.readTag
  if not reading.is_tag:
    result = reading.explain & "\n"
  else:
    let spelled = reading.pieces.mapIt(it.rafsi & LUT_LETTER_BY_HYPHEN[it.hyphen]).join("-")
    result = "`" & reading.text & "`: tag `" & reading.tag.toTanru & "`, preferred form `" &
        $reading.tag & "`" & (if spelled.len > 0: ", spelled `" & spelled & "`" else: "") &
        ".\n"
    for w in reading.tag.words:
      result.add "  " & $w & ": " & w.entry.keyword & "; " & w.entry.definition & "\n"
  let meanings = text.meanings
  if meanings.len > 0: result.add text.readTerm.describe


func run*(arguments: openArray[string], index: Index): Outcome =
  ## Answer verb named by first argument, against index read before it.
  result = Outcome(index: index)
  if arguments.len == 0:
    return Outcome(code: 2, report: USAGE, index: index)
  let rest = arguments[1 .. ^1]
  case arguments[0]
  of "tag", "untag":
    if rest.len < 2 or not rest[0].isNameValid:
      return Outcome(code: 2, report: USAGE, index: index)
    let (tags, report) = readWords(rest[1 .. ^1])
    if report.len > 0: return Outcome(code: 1, report: report, index: index)
    if arguments[0] == "tag": result.index.addTags(rest[0], tags)
    else: result.index.removeTags(rest[0], tags)
    result.is_changed = result.index != index
    let entity = result.index.entity(rest[0])
    if entity.isSome: result.output = entity.get.toLine
  of "find":
    if rest.len == 0: return Outcome(code: 2, report: USAGE, index: index)
    let terms = rest.mapIt(it.readTerm)
    for term in terms: result.report.add term.describe
    let found = index.find(terms)
    for entity in found: result.output.add entity.toLine
    result.code = (if found.len > 0: 0 else: 1)
  of "show":
    if rest.len > 1: return Outcome(code: 2, report: USAGE, index: index)
    if rest.len == 0:
      for entity in index.entities: result.output.add entity.toLine
      return
    let entity = index.entity(rest[0])
    if entity.isNone:
      return Outcome(code: 1, report: "Entity should be in index; got `" & rest[0] & "`.\n",
          index: index)
    result.output = entity.get.toLine
  of "read":
    if rest.len == 0: return Outcome(code: 2, report: USAGE, index: index)
    for text in rest: result.output.add explainWord(text)
    result.code = (if rest.allIt(it.readTag.is_tag): 0 else: 1)
  else:
    return Outcome(code: 2, report: USAGE, index: index)
