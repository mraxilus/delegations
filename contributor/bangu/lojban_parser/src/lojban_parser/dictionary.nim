## Look up words and rafsi of committed gismu list, and selma'o of committed cmavo list.
##
##   |--------------------------|---------------------------------------------------------|
##   | Code                     | Meaning                                                 |
##   |--------------------------|---------------------------------------------------------|
##   | Word                     | index of entry in `LIST_GISMU`: gismu, or cmavo         |
##   | kind(w)                  | class of word: gismu (4.4), or cmavo carrying rafsi     |
##   | word(text)               | entry spelled `text`                                    |
##   | wordRafsi(text)          | word short rafsi `text` stands for (4.6)                |
##   | wordsStem(text)          | gismu whose 4-letter rafsi is `text` (4.6)              |
##   | selmaho(text)            | selma'o of cmavo `text`, as chapter 20 names it        |
##   |--------------------------|---------------------------------------------------------|
##
##   Every table is sorted constant built at compile time from list (Article II.2); runtime
##     holds flattened residue and binary search alone.
##   Static checks hold what lookups rely on: each list in byte order, each short rafsi naming
##     one word, each cmavo once. List that breaks one fails build, naming offender, rather than
##     lookup erring. So does cmavo of gismu list that cmavo list lacks, since every cmavo
##     carrying rafsi has its selma'o.
##   `Word` ranges over entries, so bound follows list and no count is written (II.5).

{.experimental: "strictFuncs".}

import std/[algorithm, options]

import ./[entries, forms, selmaho]
import ./lists/[cmavo, gismu]


const COUNT_ENTRIES = LIST_GISMU.len  ## Number of entries in gismu list.


type
  Word* = distinct range[0 .. COUNT_ENTRIES - 1]  ## Define index of entry in gismu list.


func `==`*(a, b: Word): bool {.borrow.}
  ## Compare words by index.

func `<`*(a, b: Word): bool {.borrow.}
  ## Order words by index, i.e. alphabetically, as list is.

func index*(w: Word): int {.inline.} = int(w)
  ## Read index of word in gismu list.

func entry*(w: Word): lent EntryGismu {.inline.} = LIST_GISMU[int(w)]
  ## Read entry of word.

func `$`*(w: Word): string = LIST_GISMU[int(w)].word
  ## Render word as list spells it.

func kind*(w: Word): Kind =
  ## Read class of word by its form: gismu where it has shape of 4.4, cmavo otherwise.
  if LIST_GISMU[int(w)].word.isGismu: Kind.Gismu else: Kind.Cmavo


func constructRafsi(): seq[(string, Word)] {.compileTime.} =
  ## Build every short rafsi with word it stands for, sorted by rafsi.
  for i, entry in LIST_GISMU:
    for one in entry.rafsi: result.add (one, Word(i))
  result.sort(proc (a, b: (string, Word)): int = cmp(a[0], b[0]))


func constructStems(): seq[(string, Word)] {.compileTime.} =
  ## Build 4-letter rafsi of every gismu, sorted by stem; `broda` .. `brodu` share one.
  for i, entry in LIST_GISMU:
    if entry.word.isGismu: result.add (entry.word[0 .. 3], Word(i))
  result.sort(proc (a, b: (string, Word)): int = cmp(a[0], b[0]))


const
  RAFSI = constructRafsi()  ## Every short rafsi, sorted, with its word.
  STEMS = constructStems()  ## Every 4-letter rafsi, sorted, with its gismu.

static:
  for i in 1 ..< LIST_GISMU.len:
    doAssert LIST_GISMU[i - 1].word < LIST_GISMU[i].word,
      "Gismu list should be in byte order; got `" & LIST_GISMU[i].word & "`."
  for i in 1 ..< RAFSI.len:
    doAssert RAFSI[i - 1][0] != RAFSI[i][0],
      "Short rafsi should stand for one word (CLL 4.6); got `" & RAFSI[i][0] & "`."
  for i in 1 ..< LIST_CMAVO.len:
    doAssert LIST_CMAVO[i - 1].word < LIST_CMAVO[i].word,
      "Cmavo list should be in byte order, each cmavo once; got `" & LIST_CMAVO[i].word & "`."



#[ Lookups ]#

func word*(text: string): Option[Word] =
  ## Find entry spelled `text`; `none` where list holds no such word.
  let at = LIST_GISMU.lowerBound(text, proc (entry: EntryGismu, key: string): int =
    cmp(entry.word, key))
  if at < LIST_GISMU.len and LIST_GISMU[at].word == text: some(Word(at)) else: none(Word)


func wordRafsi*(text: string): Option[Word] =
  ## Find word short rafsi `text` stands for; `none` where list assigns it to none.
  let at = RAFSI.lowerBound(text, proc (row: (string, Word), key: string): int = cmp(row[0], key))
  if at < RAFSI.len and RAFSI[at][0] == text: some(RAFSI[at][1]) else: none(Word)


func wordsStem*(text: string): seq[Word] =
  ## Find every gismu whose 4-letter rafsi is `text`; several for `brod` alone.
  var at = STEMS.lowerBound(text, proc (row: (string, Word), key: string): int =
    cmp(row[0], key))
  while at < STEMS.len and STEMS[at][0] == text:
    result.add STEMS[at][1]
    inc at


func selmaho*(text: string): Option[Selmaho] =
  ## Find selma'o of cmavo spelled `text` (chapter 20); `none` where cmavo list holds no such cmavo.
  let at = LIST_CMAVO.lowerBound(text, proc (entry: EntryCmavo, key: string): int =
    cmp(entry.word, key))
  if at < LIST_CMAVO.len and LIST_CMAVO[at].word == text: some(LIST_CMAVO[at].selmaho)
  else: none(Selmaho)


static:
  for entry in LIST_GISMU:
    if entry.word.isGismu: continue
    doAssert entry.word.selmaho.isSome,
      "Cmavo carrying rafsi should be cmavo of cmavo list; got `" & entry.word & "`."
