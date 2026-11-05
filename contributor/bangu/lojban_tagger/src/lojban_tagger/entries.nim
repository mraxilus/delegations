## Define one entry of each word list of Logical Language Group, as project commits them.
##   `lists/gismu.nim` and `lists/lujvo.nim` hold entries; `tools/lists.nim` writes both from
##   files Debian package `lojban-common` installs, and `nim r tools/build.nim head` compares
##   them with those files daily.
##
##   |-------------|-----------------------|----------------------------------------------|
##   | Field       | Source                | Columns, or field of `:`-separated line      |
##   |-------------|-----------------------|----------------------------------------------|
##   | word        | `gismu.txt`           | 2 .. 6                                       |
##   | rafsi       | `gismu.txt`           | 8 .. 10, 12 .. 14, 16 .. 19; empty slots out |
##   | keyword     | `gismu.txt`           | 21 .. 40                                     |
##   | hint        | `gismu.txt`           | 42 .. 61                                     |
##   | definition  | `gismu.txt`           | 63 .. 158                                    |
##   | word        | `lujvo.txt`           | field 1, before `#` where line has one       |
##   | notation    | `lujvo.txt`           | `English` where field 1 holds `#`            |
##   | parts       | `lujvo.txt`           | field 2, or text after `#`; split at `+`     |
##   | gloss       | `lujvo.txt`           | field 3, or field 2 after `#`                |
##   |-------------|-----------------------|----------------------------------------------|
##
##   Lists are committed as typed Nim, not as text files: checker reads no `.txt`, and Nim
##     compiler checks each field against these types, which JSON would not.
##   Fields kept are those tagging and search read, or `read` verb shows; textbook lesson,
##     frequency, notes and place structure of lujvo are left out.
##     Cost: verb wanting one of those changes converter and both lists in one commit.
##   Rafsi keep order of their columns, which is CVC, CCV, then CVV slot; form is derived from
##     letters again where read (`forms.nim`), so order carries no meaning here.
##   Fields every line holds take `{.requiresInit.}` (CONTRIBUTOR.md, Data), so constructor
##     lacking one fails compile, naming entry: word, keyword and definition of gismu; word,
##     notation, parts and gloss of lujvo. Rafsi and hint are empty by right, so stay unmarked.
##     Notation needs it most: its zero value `Lojban` would read English line as lojban.
##     Cost: `var` of entry needs value, and `mapIt` over entries fails compile, since it
##       declares `var it`; suites read fields by loop or `collect`. Seq of entries warns
##       `UnsafeSetLen` and `UnsafeDefault` where it grows, and `newSeq` of entries warns
##       `ProveInit`, which Nim says becomes error, so suites build with `newSeqOfCap`.

{.experimental: "strictFuncs".}


type
  EntryGismu* = object  ## Define one line of gismu list: gismu, or cmavo carrying rafsi.
    word* {.requiresInit.}: string  ## Word itself; five letters for gismu, fewer for cmavo.
    rafsi*: seq[string]  ## Short rafsi assigned to word, none to three.
    keyword* {.requiresInit.}: string  ## English gloss keyword.
    hint*: string  ## Second English hint word, often empty.
    definition* {.requiresInit.}: string  ## Place structure in English, i.e. `x1 is ... x2`.

  Notation* {.pure.} = enum  ## Define how lujvo list writes tanru of one line.
    Lojban  ## `word:part+part:gloss`, parts gismu or cmavo.
    English  ## `word#keyword+keyword:gloss`, parts English keywords of gismu, or phrases.

  EntryLujvo* = object  ## Define one well-formed line of lujvo list.
    word* {.requiresInit.}: string  ## Lujvo as list spells it.
    notation* {.requiresInit.}: Notation  ## Language parts are written in.
    parts* {.requiresInit.}: seq[string]
      ## Parts of tanru lujvo stands for, as list writes them, in order.
    gloss* {.requiresInit.}: string  ## English gloss.
