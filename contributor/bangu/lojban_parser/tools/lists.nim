## Convert gismu list of Logical Language Group into typed Nim module project commits, and pin
##   lujvo and cmavo lists suites read as outside texts.
##   Reads `gismu.txt` as Debian package `lojban-common` installs it, and renders
##   `src/lojban_parser/lists/gismu.nim`; `build.nim` runs it.
##
##   Sibling `lojban_tagger/tools/lists.nim` holds earlier copy, which renders English fields and
##     lujvo list too, until #809 drops it (II.9).
##   Columns of `gismu.txt` are fixed; `entries.nim` tables them, and every range here is
##     measured over every line of file: no character of any line falls between two fields.
##   Module keeps word and rafsi alone (`entries.nim`), so each entry renders on one line, far
##     under 100 columns; no field needs wrapping.
##   `lujvo.txt` is rendered nowhere: lujvo list gives meaning, never validity, so it stays with
##     `lojban_tagger`. Suites read installed file as outside text, pinned here by digest, and
##     skip where it is absent or moved (Article IX.9). `cmavo.txt` is pinned so too, until #813
##     renders word and selma'o of each cmavo.
##   Each source is pinned by SHA-256: Debian moving list makes `lists` refuse and `head`
##     report, never silent rewrite of committed list or silent read of other text.
##   Rendering is deterministic, so `head` compares rendered text byte for byte with what is
##     committed.
##   Cost: digest is read by shelling out to `sha256sum`, which `system` declares; standard
##     library holds no SHA-256.

{.experimental: "strictFuncs".}

import std/[os, osproc, strutils]

import ../src/lojban_parser/entries


type
  Source* = object  ## Define one list file read: its bytes, and digest they hash to.
    text*: string  ## Content with carriage returns removed.
    digest*: string  ## SHA-256 of bytes as installed, lowercase hex.


const
  KEY_LISTS* = "LOJBAN_PARSER_LISTS"  ## Environment name overriding where lists are read from.
  DIRECTORY_LISTS* = "/usr/share/lojban"  ## Directory package `lojban-common` installs lists in.
  DIGEST_GISMU* = "f2fc4cff4f265ad02717d56733b4627ffa78c616db78dcaa44caab694e1dd5b7"
    ## SHA-256 of `gismu.txt` of `lojban-common` 1.5+dfsg.1-4, header dated 9/26/94.
  DIGEST_LUJVO* = "23c182f3534f4e33efbb4a3d92cd943427d5a6fdf3b061b07cd6bbc3d0e6b0cc"
    ## SHA-256 of `lujvo.txt` of `lojban-common` 1.5+dfsg.1-4; outside text suites read.
  DIGEST_CMAVO* = "544414d61f3ff35dd2cf4e4f79f3c86bf9bb0568eb3403f57288057e16796402"
    ## SHA-256 of `cmavo.txt` of `lojban-common` 1.5+dfsg.1-4, header dated 26 August 2002;
    ##   outside text suites read.
  PATH_GISMU* = "src/lojban_parser/lists/gismu.nim"  ## Module gismu list renders to.
  NOTICE = [
    "Derived from material Logical Language Group placed in public domain; facts of",
    "  derivation stated here as group asks: columns cut to word and rafsi of `entries.nim`,",
    "  carriage returns removed, spaces at field ends trimmed. Further information about",
    "  Lojban: Logical Language Group, Inc., 2904 Beau Lane, Fairfax VA 22031 USA,",
    "  https://www.lojban.org/.",
  ]
    ## Lines rendered module carries, honouring request of public-domain notice.



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
    result.add EntryGismu(word: line.field(2, 6), rafsi: rafsi)



#[ Rendering ]#

func toLiteral(text: string): string =
  ## Render text as Nim string literal; words and rafsi hold letters and apostrophe alone.
  "\"" & text & "\""


func toModuleGismu*(entries: openArray[EntryGismu], digest: string): string =
  ## Render entries of gismu list as committed module text, one entry to line.
  var lines = @[
    "## Hold gismu list of Logical Language Group as typed entries, one per line of list.",
    "##   Written by `nim r tools/build.nim lists` from `gismu.txt` of Debian",
    "##   package `lojban-common`, SHA-256 `" & digest[0 .. 31] & "`",
    "##   `" & digest[32 .. ^1] & "`; never edit by hand, run verb again.",
    "##   Entries keep order of list: gismu and cmavo carrying rafsi, alphabetically.",
  ]
  for line in NOTICE: lines.add "##   " & line
  lines.add [
    "",
    "{.experimental: \"strictFuncs\".}",
    "",
    "import ../entries",
    "",
    "",
    "const LIST_GISMU* = [",
  ]
  for entry in entries:
    var rafsi: seq[string]
    for one in entry.rafsi: rafsi.add toLiteral(one)
    lines.add "  EntryGismu(word: " & toLiteral(entry.word) & ", rafsi: @[" & rafsi.join(", ") &
        "]),"
  lines.add "]"
  lines.add "  ## Every entry of gismu list, in its order."
  lines.join("\n") & "\n"
