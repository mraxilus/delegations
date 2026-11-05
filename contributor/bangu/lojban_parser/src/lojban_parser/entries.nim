## Define one entry of gismu list of Logical Language Group, as project commits it.
##   `lists/gismu.nim` holds entries; `tools/lists.nim` writes them from `gismu.txt` that Debian
##   package `lojban-common` installs, and `nim r tools/build.nim head` compares them with that
##   file daily.
##
##   |-------------|-----------------------|----------------------------------------------|
##   | Field       | Source                | Columns                                      |
##   |-------------|-----------------------|----------------------------------------------|
##   | word        | `gismu.txt`           | 2 .. 6                                       |
##   | rafsi       | `gismu.txt`           | 8 .. 10, 12 .. 14, 16 .. 19; empty slots out |
##   |-------------|-----------------------|----------------------------------------------|
##
##   Sibling `lojban_tagger/src/lojban_tagger/entries.nim` holds earlier copy, English fields
##     and lujvo list included, until #809 drops it (II.9).
##   List is committed as typed Nim, not as text file: checker reads no `.txt`, and Nim compiler
##     checks each field against these types, which JSON would not.
##   Fields kept are word and rafsi alone: 4.11 and 4.12 join and score rafsi of each word of
##     tanru, and reader names word each rafsi stands for. English of list gives meaning, never
##     validity, so it stays with `lojban_tagger`, which searches by it.
##     Cost: code wanting keyword, hint, definition or column after changes converter and list
##       in one commit.
##   Rafsi keep order of their columns, which is CVC, CCV, then CVV slot; form is derived from
##     letters again where read (`forms.nim`), so order carries no meaning here.
##   Word takes `{.requiresInit.}` (CONTRIBUTOR.md, Data), so constructor lacking it fails
##     compile, naming entry. Rafsi are empty by right, so stay unmarked.
##     Cost: `var` of entry needs value, and `mapIt` over entries fails compile, since it
##       declares `var it`; suites read fields by loop or `collect`. Seq of entries warns
##       `UnsafeSetLen` and `UnsafeDefault` where it grows, and `newSeq` of entries warns
##       `ProveInit`, which Nim says becomes error, so suites build with `newSeqOfCap`.

{.experimental: "strictFuncs".}


type
  EntryGismu* = object  ## Define one line of gismu list: gismu, or cmavo carrying rafsi.
    word* {.requiresInit.}: string  ## Word itself; five letters for gismu, fewer for cmavo.
    rafsi*: seq[string]  ## Short rafsi assigned to word, none to three.
