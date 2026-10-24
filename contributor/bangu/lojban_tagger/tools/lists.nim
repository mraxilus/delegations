## Convert word lists of Logical Language Group into typed Nim modules project commits.
##   Reads `gismu.txt` and `lujvo.txt` as Debian package `lojban-common` installs them, and
##   renders `src/lojban_tagger/lists/gismu.nim` and `lujvo.nim`; `build.nim` runs it.
##
##   Columns of `gismu.txt` are fixed; `entries.nim` tables them, and every range here is
##     measured over every line of file: no character of any line falls between two fields.
##   `lujvo.txt` is `:`-separated, in two shapes: tanru in Lojban after `:`, or in English
##     keywords after `#`. Line is kept where word is Lojban letters, tanru has two parts or
##     more, and gloss is present. Other shapes (phrase for word, no gloss, `,` in tanru) are
##     left out, and module header counts them, so cut stays visible.
##   Each source is pinned by SHA-256: Debian moving list makes `lists` refuse and `head`
##     report, never silent rewrite of committed list.
##   Rendering is deterministic and wraps each string under 100 columns at spaces, so
##     `head` compares rendered text byte for byte with what is committed.
##   Cost: digest is read by shelling out to `sha256sum`, which `system` declares; standard
##     library holds no SHA-256.

{.experimental: "strictFuncs".}

import std/[options, os, osproc, sequtils, strutils]

import ../src/lojban_tagger/entries


type
  Source* = object  ## Define one list file read: its bytes, and digest they hash to.
    text*: string  ## Content with carriage returns removed.
    digest*: string  ## SHA-256 of bytes as installed, lowercase hex.


const
  KEY_LISTS* = "LOJBAN_TAGGER_LISTS"  ## Environment name overriding where lists are read from.
  DIRECTORY_LISTS* = "/usr/share/lojban"  ## Directory package `lojban-common` installs lists in.
  DIGEST_GISMU* = "f2fc4cff4f265ad02717d56733b4627ffa78c616db78dcaa44caab694e1dd5b7"
    ## SHA-256 of `gismu.txt` of `lojban-common` 1.5+dfsg.1-4, header dated 9/26/94.
  DIGEST_LUJVO* = "23c182f3534f4e33efbb4a3d92cd943427d5a6fdf3b061b07cd6bbc3d0e6b0cc"
    ## SHA-256 of `lujvo.txt` of `lojban-common` 1.5+dfsg.1-4.
  PATH_GISMU* = "src/lojban_tagger/lists/gismu.nim"  ## Module gismu list renders to.
  PATH_LUJVO* = "src/lojban_tagger/lists/lujvo.nim"  ## Module lujvo list renders to.
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

proc readSource*(name: string): Source =
  ## Read list file `name` from directory environment names, else from package's directory.
  let
    directory = getEnv(KEY_LISTS, DIRECTORY_LISTS)
    path = directory / name
  if not fileExists(path):
    quit "List is missing; install `lojban-common` or set `" & KEY_LISTS & "`; got `" & path &
        "`.", 1
  let (output, code) = execCmdEx("sha256sum " & quoteShell(path))
  if code != 0: quit "Digest could not be read; got `" & output.strip & "`.", 1
  Source(text: readFile(path).replace("\r", ""), digest: output.splitWhitespace[0])


func field(line: string, first, last: int): string =
  ## Read columns `first` .. `last`, counted from one as `entries.nim` tables them, trimmed.
  if line.len < first: return ""
  line[first - 1 .. min(last, line.len) - 1].strip


func toEntriesGismu*(text: string): seq[EntryGismu] =
  ## Read every entry of `gismu.txt`, header line skipped.
  for line in text.splitLines[1 .. ^1]:
    if line.strip.len == 0: continue
    var rafsi: seq[string]
    for (first, last) in [(8, 10), (12, 14), (16, 19)]:
      let one = line.field(first, last)
      if one.len > 0: rafsi.add one
    result.add EntryGismu(
      word: line.field(2, 6),
      rafsi: rafsi,
      keyword: line.field(21, 40),
      hint: line.field(42, 61),
      definition: line.field(63, 158),
    )


func isLetters(text: string): bool =
  ## Test text is nonempty and holds Lojban letters and apostrophe alone.
  text.len > 0 and text.allCharsInSet(LETTERS_LOJBAN)


func toEntryLujvo(line: string): Option[EntryLujvo] =
  ## Read one line of `lujvo.txt`; `none` where it has neither well-formed shape.
  ##   `word:part+part:gloss:places` writes tanru in Lojban; `word#keyword+keyword:gloss:places`
  ##   writes it in English keywords. Gloss opening `$` is place structure, so no gloss.
  let fields = line.split(':', maxsplit = 3)
  if fields.len < 2 or ' ' in fields[0]: return none(EntryLujvo)
  var entry: EntryLujvo
  if '#' in fields[0]:
    let head = fields[0].split('#', maxsplit = 1)
    entry = EntryLujvo(
      word: head[0],
      notation: Notation.English,
      parts: head[1].split('+'),
      gloss: fields[1].strip,
    )
  elif fields.len >= 3:
    entry = EntryLujvo(
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


func toLinesWrapped(head, text, tail: string, as_literal = true): seq[string] =
  ## Render `head` then `text` as literal then `tail`, split at spaces into `&` pieces.
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
  for word in text.splitWhitespace:
    let candidate = piece & word & " "
    if (line & toLiteral(candidate) & " &").len > WIDTH and piece.len > 0:
      result.add line & toLiteral(piece) & " &"
      line = continuation
      piece = word & " "
    else: piece = candidate
  result.add line & toLiteral(piece.strip(leading = false)) & tail


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


func toModuleGismu*(entries: openArray[EntryGismu], digest: string): string =
  ## Render entries of gismu list as committed module text.
  var lines = toHeader(
    "Hold gismu list of Logical Language Group as typed entries, one per line of list.",
    "gismu.txt",
    digest,
    ["Entries keep order of list: gismu and cmavo carrying rafsi, alphabetically."],
  )
  lines.add "const LIST_GISMU* = ["
  for entry in entries:
    var rafsi: seq[string]
    for one in entry.rafsi: rafsi.add toLiteral(one)
    lines.add "  EntryGismu("
    lines.add "    word: " & toLiteral(entry.word) & ","
    lines.add "    rafsi: @[" & rafsi.join(", ") & "],"
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
