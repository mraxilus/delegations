## Define one entry of each word list of Logical Language Group, as project commits them.
##   `lists/gismu.nim` and `lists/cmavo.nim` hold entries; `tools/lists.nim` writes them from
##   `gismu.txt` and `cmavo.txt` that Debian package `lojban-common` installs, and
##   `nim r tools/build.nim head` compares them with those files daily.
##
##   |-------------|-----------------------|----------------------------------------------|
##   | Field       | Source                | Columns                                      |
##   |-------------|-----------------------|----------------------------------------------|
##   | word        | `gismu.txt`           | 2 .. 6                                       |
##   | rafsi       | `gismu.txt`           | 8 .. 10, 12 .. 14, 16 .. 19; empty slots out |
##   | word        | `cmavo.txt`           | 1 .. 11, period of pause out                 |
##   | selmaho     | `cmavo.txt`           | 12 .. 20, name before subclass of list       |
##   |-------------|-----------------------|----------------------------------------------|
##
##   Lists are committed as typed Nim, not as text files: checker reads no `.txt`, and Nim
##     compiler checks each field against these types, which JSON would not.
##   Fields kept are those rules of CLL need alone: word and rafsi of gismu list, since 4.11
##     and 4.12 join and score rafsi of each word of tanru, and word and selma'o of cmavo
##     list, which grammar of CLL reads. English of each list gives meaning, never validity, so
##     it stays with `lojban_tagger`, which searches by it.
##     Cost: code wanting column left out changes converter and list in one commit.
##   Cmavo list keeps lines of one cmavo alone: compound reads as cmavo it joins (4.2), so its
##     line adds no fact, and phrase is several words. Subclass list writes after selma'o, as
##     `1` of `UI1`, groups cmavo for learners, and no rule of CLL reads it.
##   Rafsi keep order of their columns, which is CVC, CCV, then CVV slot; form is derived from
##     letters again where read (`forms.nim`), so order carries no meaning here.
##   Field every line holds takes `{.requiresInit.}` (CONTRIBUTOR.md, Data), so constructor
##     lacking one fails compile, naming entry: word of each list, and selma'o, whose zero value
##     `Selmaho.A` would stand in silence. Rafsi are empty by right, so stay unmarked.
##     Cost: `var` of entry needs value, and `mapIt` over entries fails compile, since it
##       declares `var it`; suites read fields by loop or `collect`. Seq of entries warns
##       `UnsafeSetLen` and `UnsafeDefault` where it grows, and `newSeq` of entries warns
##       `ProveInit`, which Nim says becomes error, so suites build with `newSeqOfCap`.

{.experimental: "strictFuncs".}

import ./selmaho


type
  EntryGismu* = object  ## Define one line of gismu list: gismu, or cmavo carrying rafsi.
    word* {.requiresInit.}: string  ## Word itself; five letters for gismu, fewer for cmavo.
    rafsi*: seq[string]  ## Short rafsi assigned to word, none to three.

  EntryCmavo* = object  ## Define one line of cmavo list that holds one cmavo, never compound.
    word* {.requiresInit.}: string  ## Cmavo, period of pause left out (3.3).
    selmaho* {.requiresInit.}: Selmaho  ## Selma'o of cmavo, as chapter 20 names it.
