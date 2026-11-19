## Convert English of gismu list, and lujvo list, into typed Nim modules project commits.
##   Reads `gismu.txt` and `lujvo.txt` as Debian package `lojban-common` installs them, and
##   renders `src/rictadni/lists/gismu.nim` and `lujvo.nim`; `build.nim` runs it.
##   Runs as own program for verbs `lists` and `head` of `build.nim`, as
##     `nim r tools/lists.nim <lists|head>`: module reads parser package, which driver imports
##     none of, so `koch list-packages` runs driver before Atlas restores any package
##     (`suites/test_build.nim`).
##
##   Columns of `gismu.txt` are fixed; `entries.nim` tables them, and every range here is
##     measured over every line of file: no character of any line falls between two fields.
##   `lujvo.txt` is `:`-separated, in two shapes: tanru in lojban after `:`, or in English
##     keywords after `#`. Line is kept where word is lojban letters, tanru has two parts or
##     more, and gloss is present. Other shapes (phrase for word, no gloss, `,` in tanru) are
##     left out, and module header counts them, so cut stays visible.
##   Reader of each source, key naming its directory, and SHA-256 pin of each file are those of
##     `lojban_parser/tools/lists.nim`, re-exported for suites: both projects
##     read one `gismu.txt`, and English here follows parser's list entry for entry, so one pin
##     serves both. Debian moving list makes `lists` refuse and `head` report, never silent
##     rewrite of committed list.
##     `field` stays here, as parser keeps its own private (II.9); fix to one is finished only
##       when other is checked.
##   Rendering is deterministic and wraps each string under 100 columns after runs of spaces,
##     every space kept, so
##     `head` compares rendered text byte for byte with what is committed.
##   Cost: digest is read by shelling out to `sha256sum`, which `system` declares; standard
##     library holds no SHA-256.

{.experimental: "strictFuncs".}

import std/[options, os, sequtils, strutils]

from ../dependencies/lojban_parser/contributor/bangu/lojban_parser/tools/lists import
  DIGEST_GISMU, DIGEST_LUJVO, DIRECTORY_LISTS, KEY_LISTS, readSource, Source

import ../src/rictadni/entries

export DIGEST_GISMU, DIGEST_LUJVO, DIRECTORY_LISTS, KEY_LISTS, readSource, Source


const
  PATH_GISMU* = "src/rictadni/lists/gismu.nim"  ## Module gismu list renders to.
  PATH_LUJVO* = "src/rictadni/lists/lujvo.nim"  ## Module lujvo list renders to.
  WIDTH = 100  ## Column limit of Article X.1, which rendered lines keep.
  LETTERS_LOJBAN = {'a' .. 'z', '\''}  ## Characters word of kept lujvo line may hold.
  NOTICE = [
    "Derived from material Logical Language Group placed in public domain; facts of",
    "  derivation stated here as group asks: columns cut to fields of `entries.nim`,",
    "  carriage returns removed, spaces at field ends trimmed. Further information about",
    "  Lojban: Logical Language Group, Inc., 2904 Beau Lane, Fairfax VA 22031 USA,",
    "  https://www.lojban.org/.",
  ]
    ## Lines every rendered module carries, honouring request of public-domain notice.



#[ Reading ]#

func field(line: string, first, last: int): string =
  ## Read columns `first` .. `last`, counted from one as `entries.nim` tables them, trimmed.
  if line.len < first: return ""
  line[first - 1 .. min(last, line.len) - 1].strip


func toEntriesGismu*(text: string): seq[EntryGismuEnglish] =
  ## Read English of every entry of `gismu.txt`, header line skipped; rafsi left to parser.
  for line in text.splitLines[1 .. ^1]:
    if line.strip.len == 0: continue
    result.add EntryGismuEnglish(
      word: line.field(2, 6),
      keyword: line.field(21, 40),
      hint: line.field(42, 61),
      definition: line.field(63, 158),
    )


func isLetters(text: string): bool =
  ## Test text is nonempty and holds lojban letters and apostrophe alone.
  text.len > 0 and text.allCharsInSet(LETTERS_LOJBAN)


func toEntryLujvo(line: string): Option[EntryLujvo] =
  ## Read one line of `lujvo.txt`; `none` where it has neither well-formed shape.
  ##   `word:part+part:gloss:places` writes tanru in lojban; `word#keyword+keyword:gloss:places`
  ##   writes it in English keywords. Gloss opening `$` is place structure, so no gloss.
  let fields = line.split(':', maxsplit = 3)
  if fields.len < 2 or ' ' in fields[0]: return none(EntryLujvo)
  let entry =
    if '#' in fields[0]:
      let head = fields[0].split('#', maxsplit = 1)
      EntryLujvo(
        word: head[0],
        notation: Notation.English,
        parts: head[1].split('+'),
        gloss: fields[1].strip,
      )
    elif fields.len >= 3:
      EntryLujvo(
        word: fields[0],
        notation: Notation.Lojban,
        parts: fields[1].split('+'),
        gloss: fields[2].strip,
      )
    else: return none(EntryLujvo)
  let is_parts_valid =
    case entry.notation
    of Notation.Lojban: entry.parts.allIt(it.isLetters)
    of Notation.English: entry.parts.allIt(it.len > 0)
  if not entry.word.isLetters or entry.parts.len < 2 or not is_parts_valid or
      entry.gloss.len == 0 or entry.gloss.startsWith("$"):
    return none(EntryLujvo)
  some(entry)


func toEntriesLujvo*(text: string): tuple[entries: seq[EntryLujvo], count_left: int] =
  ## Read every well-formed line of `lujvo.txt`, and count lines of other shapes left out.
  for line in text.splitLines:
    if line.strip.len == 0: continue
    let entry = line.toEntryLujvo
    if entry.isNone: inc result.count_left
    else: result.entries.add entry.get



#[ Rendering ]#

func toLiteral(text: string): string =
  ## Render text as Nim string literal; lists hold ASCII, and `"` alone needs escape.
  "\"" & text.replace("\"", "\\\"") & "\""


func toSegments(text: string): seq[string] =
  ## Split text after each run of spaces, so segments join back into text exactly.
  var current = ""
  for i, character in text:
    current.add character
    if character == ' ' and (i == text.high or text[i + 1] != ' '):
      result.add current
      current = ""
  if current.len > 0: result.add current


func toLinesWrapped(head, text, tail: string, as_literal = true): seq[string] =
  ## Render `head` then `text` as literal then `tail`, split after runs of spaces into `&` pieces.
  ##   Pieces join back into text exactly, every space kept, so wrapping changes no field.
  ##   Continuation lines take four spaces past head's indent (STYLE.md §5).
  ##   `as_literal = false` renders text as written, i.e. list of literals, and never splits it.
  let
    indent = head.len - head.strip(trailing = false).len
    continuation = repeat(' ', indent + 4)
  if not as_literal: return @[head & text & tail]
  if (head & toLiteral(text) & tail).len <= WIDTH: return @[head & toLiteral(text) & tail]
  var
    line = head
    piece = ""
  for segment in text.toSegments:
    let candidate = piece & segment
    if (line & toLiteral(candidate) & " &").len > WIDTH and piece.len > 0:
      result.add line & toLiteral(piece) & " &"
      line = continuation
      piece = segment
    else: piece = candidate
  result.add line & toLiteral(piece) & tail


func toHeader(purpose, source: string, digest: string, extra: openArray[string]): seq[string] =
  ## Render header shared by both modules: purpose, origin, digest, notice, extra lines.
  result.add "## " & purpose
  result.add "##   Written by `nim r tools/build.nim lists` from `" & source & "` of Debian"
  result.add "##   package `lojban-common`, SHA-256 `" & digest[0 .. 31] & "`"
  result.add "##   `" & digest[32 .. ^1] & "`; never edit by hand, run verb again."
  for line in extra: result.add "##   " & line
  for line in NOTICE: result.add "##   " & line
  result.add ""
  result.add "{.experimental: \"strictFuncs\".}"
  result.add ""
  result.add "import ../entries"
  result.add ""
  result.add ""


func toModuleGismu*(entries: openArray[EntryGismuEnglish], digest: string): string =
  ## Render English of entries of gismu list as committed module text.
  var lines = toHeader(
    "Hold English of gismu list of Logical Language Group as typed entries, one per line.",
    "gismu.txt",
    digest,
    [
      "Entries keep order of list: gismu and cmavo carrying rafsi, alphabetically.",
      "Rafsi of each word stand in gismu list of `lojban_parser`, entry for entry.",
    ],
  )
  lines.add "const LIST_GISMU* = ["
  for entry in entries:
    lines.add "  EntryGismuEnglish("
    lines.add "    word: " & toLiteral(entry.word) & ","
    lines.add toLinesWrapped("    keyword: ", entry.keyword, ",")
    lines.add toLinesWrapped("    hint: ", entry.hint, ",")
    lines.add toLinesWrapped("    definition: ", entry.definition, ",")
    lines.add "  ),"
  lines.add "]"
  lines.add "  ## Every entry of gismu list, in its order."
  lines.join("\n") & "\n"


func toModuleLujvo*(entries: openArray[EntryLujvo], count_left: int, digest: string): string =
  ## Render well-formed entries of lujvo list as committed module text.
  var lines = toHeader(
    "Hold lujvo list of Logical Language Group as typed entries, one per well-formed line.",
    "lujvo.txt",
    digest,
    [
      "Line is kept where word is letters, tanru has two parts or more, and gloss is present;",
      "  " & $count_left & " lines of other shapes left out, i.e. phrase for word, no gloss.",
    ],
  )
  lines.add "const LIST_LUJVO* = ["
  for entry in entries:
    var parts: seq[string]
    for part in entry.parts: parts.add toLiteral(part)
    lines.add "  EntryLujvo("
    lines.add "    word: " & toLiteral(entry.word) & ","
    lines.add "    notation: Notation." & $entry.notation & ","
    lines.add toLinesWrapped("    parts: @[", parts.join(", "), "],", as_literal = false)
    lines.add toLinesWrapped("    gloss: ", entry.gloss, ",")
    lines.add "  ),"
  lines.add "]"
  lines.add "  ## Every well-formed entry of lujvo list, in its order."
  lines.join("\n") & "\n"



#[ Verbs ]#

const USAGE = "Usage: nim r tools/lists.nim <lists|head>\n"  ## Text printed on usage error.


proc readLists(): tuple[gismu, lujvo: string, digests: array[2, string]] =
  ## Read both lists and render both modules, with digest each source carries.
  let
    gismu = readSource("gismu.txt")
    lujvo = readSource("lujvo.txt")
    (entries, count_left) = lujvo.text.toEntriesLujvo
  (
    toModuleGismu(gismu.text.toEntriesGismu, gismu.digest),
    toModuleLujvo(entries, count_left, lujvo.digest),
    [gismu.digest, lujvo.digest],
  )


proc refuseDigests(digests: array[2, string]): int =
  ## Report each list whose digest left its pin; count reports.
  for (name, digest, pin) in [
    ("gismu.txt", digests[0], DIGEST_GISMU),
    ("lujvo.txt", digests[1], DIGEST_LUJVO),
  ]:
    if digest == pin: continue
    stderr.writeLine "List moved from its pin in `tools/lists.nim`; read diff, then move pin; " &
        "got `" & digest & "` for `" & name & "`."
    inc result


proc writeLists(): int =
  ## Write both modules where both digests match their pins.
  let (gismu, lujvo, digests) = readLists()
  if refuseDigests(digests) > 0: return 1
  createDir(PATH_GISMU.parentDir)
  writeFile(PATH_GISMU, gismu)
  writeFile(PATH_LUJVO, lujvo)
  echo PATH_GISMU
  echo PATH_LUJVO


proc compareLists(): int =
  ## Compare digests and rendered modules with committed modules; 1 where any differs.
  let (gismu, lujvo, digests) = readLists()
  var count_differing = refuseDigests(digests)
  for (path, rendered) in [(PATH_GISMU, gismu), (PATH_LUJVO, lujvo)]:
    if fileExists(path) and readFile(path) == rendered: continue
    stderr.writeLine "Committed list differs from list rendered again; run `lists`; got `" &
        path & "`."
    inc count_differing
  if count_differing > 0: 1 else: 0


proc main(): int =
  ## Dispatch verb named as first argument.
  if paramCount() != 1:
    stderr.write USAGE
    return 2
  case paramStr(1)
  of "lists": writeLists()
  of "head": compareLists()
  else:
    stderr.write USAGE
    2


when isMainModule:
  quit main()
