## sisku lo valsi .e lo rafsi ne'i le gismu liste poi se ralte
##   .i sisku lo selma'o ne'i le cmavo liste poi se ralte
##
##   |-------------------|-------------------------------------------------------------------------|
##   | lo cmene          | lo smuni                                                                |
##   |-------------------|-------------------------------------------------------------------------|
##   | `Word`            | lo namcu pe lo liste cmima pe `LIST_GISMU`                              |
##   |                   | le liste cmima cu gismu ja cmavo                                        |
##   | `kind(w)`         | lo klesi be le valsi                                                    |
##   |                   | le valsi cu du lo gismu to `CLL 4.4` toi .a lo cmavo poi ponse lo rafsi |
##   | `word(text)`      | lo liste cmima poi lo valsi pe ke'a cu du `text`                        |
##   | `wordRafsi(text)` | lo valsi poi lo cmalu rafsi po'u `text` cu sinxa ke'a to `CLL 4.6` toi  |
##   | `wordsStem(text)` | lo gismu poi `text` cu rafsi ke'a gi'e vasru vo lerfu to `CLL 4.6` toi  |
##   | `selmaho(text)`   | lo selma'o be lo cmavo po'u `text` ja'i lo cmene pe `CLL 20`            |
##   |-------------------|-------------------------------------------------------------------------|
##
## ni'o ro sisku liste cu stodi gi'e porsi gi'e se zbasu fi le liste ca lo nu fanva to
##   `Article II.2` toi
##   .i ca lo nu le samtci cu gunka kei le samtci cu pilno lo sampu porsi poi stali .e lo nu sisku
##     ta'i lo nu rapli fendi fi re pagbu gi'e pilno no drata
##   .i lo cipra ca lo nu fanva cu xusra ro se nitcu be lo nu sisku
##   .i ro liste cu porsi fi lo stuzi
##   .i ro cmalu rafsi cu sinxa pa valsi
##   .i ro cmavo cu zvati le cmavo liste pa roi
##   .i va'o lo nu lo liste cu na'e mapti su'o le se nitcu kei lo nu zbasu cu fliba gi'e cusku lo
##     cmene be lo liste cmima poi srera
##   .i lo nu fliba cu basti lo nu lo nu sisku cu srera
##   .i ji'a lo nu zbasu cu fliba va'o lo nu le cmavo liste cu claxu pa cmavo pe le gismu liste
##   .i ki'u bo ro cmavo poi ponse lo rafsi cu ponse lo selma'o
##   .i `Word` cu kuspe ro liste cmima
##   .i se ki'u bo lo korbi be `Word` cu se krasi le liste
##   .i no te kancu be lo liste cmima cu se ciska to `Article II.5` toi

{.experimental: "strictFuncs".}

import std/[algorithm, options]

import ./[entries, forms, selmaho]
import ./lists/[cmavo, gismu]


const COUNT_ENTRIES = LIST_GISMU.len  ## lo te kancu be ro liste cmima pe le gismu liste


type
  Word* = distinct range[0 .. COUNT_ENTRIES - 1]  ## lo namcu pe lo liste cmima pe le gismu liste


func `==`*(a, b: Word): bool {.borrow.}
  ## karbi lo valsi ja'i lo namcu

func `<`*(a, b: Word): bool {.borrow.}
  ## jdice lo porsi be lo valsi ja'i lo namcu
  ##   .i le porsi cu du le porsi pe le liste noi porsi ja'i lo lerfu

func index*(w: Word): int {.inline.} = int(w)
  ## tcidu lo namcu pe le valsi ne'i le gismu liste

func entry*(w: Word): lent EntryGismu {.inline.} = LIST_GISMU[int(w)]
  ## tcidu lo liste cmima pe le valsi

func `$`*(w: Word): string = LIST_GISMU[int(w)].word
  ## ciska le valsi ta'i lo nu le liste cu ciska le valsi

func kind*(w: Word): Kind =
  ## tcidu lo klesi be le valsi ja'i lo tarmi be le valsi
  ##   .i le klesi cu klesi lo gismu va'o lo nu le valsi cu se tarmi lo tarmi pe `CLL 4.4`
  ##   .i va'o lo drata le klesi cu klesi lo cmavo
  if LIST_GISMU[int(w)].word.isGismu: Kind.Gismu else: Kind.Cmavo


func constructRafsi(): seq[(string, Word)] {.compileTime.} =
  ## zbasu ro cmalu rafsi .e lo valsi poi le rafsi cu sinxa ke'a
  ##   .i le se zbasu cu porsi ja'i le rafsi
  for i, entry in LIST_GISMU:
    for one in entry.rafsi: result.add (one, Word(i))
  result.sort(proc (a, b: (string, Word)): int = cmp(a[0], b[0]))


func constructStems(): seq[(string, Word)] {.compileTime.} =
  ## zbasu lo rafsi be ro gismu be'o poi vasru vo lerfu
  ##   .i le se zbasu cu porsi ja'i le rafsi
  ##   .i pa rafsi poi vasru vo lerfu cu rafsi zo broda bi'o zo brodu
  for i, entry in LIST_GISMU:
    if entry.word.isGismu: result.add (entry.word[0 .. 3], Word(i))
  result.sort(proc (a, b: (string, Word)): int = cmp(a[0], b[0]))


const
  RAFSI = constructRafsi()  ## lo porsi be ro cmalu rafsi .e lo valsi pe ro le rafsi
  STEMS = constructStems()
    ## lo porsi be ro rafsi poi vasru vo lerfu ku'o .e lo gismu pe ro le rafsi

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



#[ ni'o ni'o ni'o lo nu sisku ]#

func word*(text: string): Option[Word] =
  ## facki lo liste cmima poi lo valsi pe ke'a cu du `text`
  ##   .i dunda `none` va'o lo nu le liste cu vasru no valsi po'u `text`
  let at = LIST_GISMU.lowerBound(text, proc (entry: EntryGismu, key: string): int =
    cmp(entry.word, key))
  if at < LIST_GISMU.len and LIST_GISMU[at].word == text: some(Word(at)) else: none(Word)


func wordRafsi*(text: string): Option[Word] =
  ## facki lo valsi poi lo cmalu rafsi po'u `text` cu sinxa ke'a
  ##   .i dunda `none` va'o lo nu le liste cu dunda `text` no valsi
  let at = RAFSI.lowerBound(text, proc (row: (string, Word), key: string): int = cmp(row[0], key))
  if at < RAFSI.len and RAFSI[at][0] == text: some(RAFSI[at][1]) else: none(Word)


func wordsStem*(text: string): seq[Word] =
  ## facki ro gismu poi `text` cu rafsi ke'a gi'e vasru vo lerfu
  ##   .i `brod` po'o cu rafsi su'o re gismu
  var at = STEMS.lowerBound(text, proc (row: (string, Word), key: string): int =
    cmp(row[0], key))
  while at < STEMS.len and STEMS[at][0] == text:
    result.add STEMS[at][1]
    inc at


func selmaho*(text: string): Option[Selmaho] =
  ## facki lo selma'o be lo cmavo po'u `text` to `CLL 20` toi
  ##   .i dunda `none` va'o lo nu le cmavo liste cu vasru no cmavo po'u `text`
  let at = LIST_CMAVO.lowerBound(text, proc (entry: EntryCmavo, key: string): int =
    cmp(entry.word, key))
  if at < LIST_CMAVO.len and LIST_CMAVO[at].word == text: some(LIST_CMAVO[at].selmaho)
  else: none(Selmaho)


static:
  for entry in LIST_GISMU:
    if entry.word.isGismu: continue
    doAssert entry.word.selmaho.isSome,
      "Cmavo carrying rafsi should be cmavo of cmavo list; got `" & entry.word & "`."
