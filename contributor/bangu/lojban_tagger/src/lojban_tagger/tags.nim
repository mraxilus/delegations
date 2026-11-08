## Read text as tag, i.e. gismu or lujvo, and reduce it to words of its tanru, gismu among them.
##
##   |---------------------|-------------------------------------------------------------|
##   | Code                | Meaning                                                     |
##   |---------------------|-------------------------------------------------------------|
##   | Tag                 | words of one tanru, in order; one gismu alone for gismu     |
##   | gismu               | gismu of tag, cmavo left out; what search matches on        |
##   | readTag             | read text as tag, or refuse it with reason                  |
##   | RefusalTag          | why text is no tag                                          |
##   | `$`                 | lujvo form 4.12 scores lowest, or gismu itself              |
##   | tanruUnits          | tag folded into tanru units, as `lojban_parser` folds tanru |
##   | toTanru, readTanru  | words joined by `+`, as lujvo list writes tanru             |
##   |---------------------|-------------------------------------------------------------|
##
##   Reader of `lojban_parser` reads each word by rules of CLL alone, and so do its rendering and
##     fold of tanru; this module holds policy of tag. Architect ruled that tagger alone restricts
##     words: tag holds words of list, last one gismu.
##   Text that reader refuses, or reads as no gismu nor lujvo, is no tag. Its refusal is `Hyphen`
##     where its letters split into rafsi that 4.11 joins with other hyphens, as `ro'ire'o`,
##     which 4.6 reads as two cmavo; `Shape` otherwise.
##     Cost: class reader gives, as cmavo no list holds, cmene or fu'ivla, goes unnamed in report.
##   Tag is words of its tanru, never its spelling: rafsi chosen do not change lujvo (CLL 4.5),
##     so `brivla`, `brivalsi`, `bridyvla` and `bridyvalsi` read as one tag, and `$` renders form
##     4.12 prefers. Order of words stays, since tanru is modifier then head (4.5).
##   Lujvo holding rafsi of cmavo is tag, keeping cmavo: Architect ruled that `selci'a` tags, acts
##     as `ciska` in search, and ranks first where searched for itself. So tag keeps `se`, and
##     `gismu` gives what search matches on. `selci'a` and `ciska` are two tags.
##   Cmavo alone is no tag, nor lujvo of cmavo alone, nor lujvo ending in cmavo: 4.11 step 2
##     ends tanru in gismu, and tag holding no gismu would match every entity.
##   Text is trimmed, folded to lowercase, and stripped of commas before reading. Capital marks
##     irregular stress, which no brivla carries (3.1, 3.9); comma marks syllable break, and no
##     two words differ by comma alone (3.3). Folding is project's choice; CLL writes neither.
##     Space and period are refused as `Letter`, since tag is one word, and reader would name
##     them marks of stream (3.3).
##   `h` never stands for apostrophe: 3.3 says letter `h` is not used for it, so `h` is refused.
##   `$` rejects 4-letter rafsi several gismu share (`brod`) wherever gismu has other rafsi,
##     so rendered tag reads back as itself; `brodi`, `brodo` and `brodu` have none, so their
##     lujvo render with `brod` and read as `RefusalTag.Ambiguous` (open question in PROVENANCE).
##   Cost: `$` is render of `lojban_parser`, which searches choices of rafsi by dynamic
##     programming in time linear in words of tag (PROVENANCE of `lojban_parser`); lujvo of 18
##     words that `test_suggestions.nim` holds renders in under 0.1 ms in release (measured,
##     Figures of PROVENANCE). `readTag` caps no words.

{.experimental: "strictFuncs".}

import std/[options, sequtils, strutils]

import ../../../lojban_parser/src/lojban_parser


type
  Tag* = object  ## Define tag: words of its tanru, gismu and cmavo, in order, last one gismu.
    words*: seq[Word]  ## Words of tanru; one gismu alone for gismu tag.

  RefusalTag* {.pure.} = enum  ## Define why text is no tag.
    Empty  ## Text holds nothing but spaces.
    Letter  ## Character outside lojban letters; detail is that character, whole.
    Cmavo  ## Word is cmavo of list, or lujvo holds no gismu or ends in cmavo; detail names it.
    Unlisted  ## Gismu shape, but list holds no such gismu; detail is word.
    Rafsi  ## Rafsi no list assigns; detail is rafsi.
    Ambiguous  ## 4-letter rafsi several gismu share; detail is rafsi.
    Hyphen  ## Rafsi known, hyphens differ from 4.11; detail is form 4.11 gives.
    Shape  ## Neither gismu nor lujvo: other class, or no word by rules of CLL.

  ReadingTag* = object  ## Define outcome of reading text as tag.
    text*: string  ## Text as read, trimmed, folded to lowercase, commas removed.
    case is_tag*: bool
    of true:
      tag*: Tag  ## Tag text reduces to.
      pieces*: seq[Piece]  ## Rafsi as text spells them; empty for gismu.
    of false:
      refusal*: RefusalTag  ## Why text is no tag.
      detail*: string  ## Offending part, or form 4.11 gives.


func `==`*(a, b: Tag): bool = a.words == b.words
  ## Compare tags by words of tanru, in order, cmavo included.

func gismu*(tag: Tag): seq[Word] = tag.words.filterIt(it.kind == Kind.Gismu)
  ## Read gismu of tag, in order, cmavo left out; search matches on these alone.

func isGismuAlone*(tag: Tag): bool = tag.words.allIt(it.kind == Kind.Gismu)
  ## Test tag holds gismu alone, i.e. no cmavo converts or groups them.

func tanruUnits*(tag: Tag): seq[TanruUnit] = tag.words.mapIt(it.toPart).tanruUnits
  ## Fold words of tag into tanru units, by fold of `lojban_parser`.



#[ Reading ]#

func refuse(text: string, refusal: RefusalTag, detail = ""): ReadingTag =
  ## Build reading that refuses text.
  ReadingTag(text: text, is_tag: false, refusal: refusal, detail: detail)


func refuseOther(text: string): ReadingTag =
  ## Refuse text read as no gismu nor lujvo: as `Hyphen` where its letters split into rafsi that
  ##   4.11 joins with other hyphens, naming form 4.11 gives, else as `Shape`.
  let segments = text.segmentLujvo
  if segments.len == 0: return refuse(text, RefusalTag.Shape)
  refuse(text, RefusalTag.Hyphen, joinRafsi(segments[0].mapIt(it.rafsi)))


func refusalUnnamed(piece: Piece): RefusalTag =
  ## Name why list names no one word for rafsi of lujvo: short rafsi or 4-letter rafsi list assigns
  ##   to none, 4-letter rafsi several gismu share, or gismu list lacks (4.6).
  case piece.form
  of Form.Cvc, Form.Ccv, Form.Cvv: RefusalTag.Rafsi
  of Form.Cvcc, Form.Ccvc:
    if piece.rafsi.wordsStem.len > 1: RefusalTag.Ambiguous else: RefusalTag.Rafsi
  of Form.Cvccv, Form.Ccvcv: RefusalTag.Unlisted


func readTag*(text: string): ReadingTag =
  ## Read text as tag: gismu of list, or lujvo whose rafsi stand for listed words, last gismu.
  ##   Character refused is named whole, so report of UTF-8 text stays UTF-8; held by test
  ##     "Character outside letters is named whole, so report of UTF-8 stays UTF-8" of
  ##     `test_tags.nim`.
  let letters = text.strip.toLowerAscii.replace(",", "")
  if letters.len == 0: return refuse(letters, RefusalTag.Empty)
  for at in 0..<letters.len:
    if letters[at] notin lojban_parser.LETTERS:
      return refuse(letters, RefusalTag.Letter, letters.character(at))
  let reading = letters.readWord
  if not reading.is_word:
    if reading.refusal == Refusal.Hyphen:
      return refuse(letters, RefusalTag.Hyphen, reading.detail)
    return letters.refuseOther

  # Hold words of list alone, last one gismu (4.11 step 2); else name what list lacks.
  let parts = reading.tanru.parts
  case reading.kind
  of Kind.Gismu:
    if not parts[0].is_listed: return refuse(letters, RefusalTag.Unlisted, letters)
  of Kind.Cmavo:
    if parts[0].is_listed: return refuse(letters, RefusalTag.Cmavo, letters)
    return letters.refuseOther
  of Kind.Lujvo:
    for i, part in parts:
      if not part.is_listed:
        return refuse(letters, reading.pieces[i].refusalUnnamed, reading.pieces[i].rafsi)
    if parts[^1].word.kind == Kind.Cmavo:
      let detail = reading.pieces[^1].rafsi & " (" & $parts[^1].word & ")"
      return refuse(letters, RefusalTag.Cmavo, detail)
  of Kind.Fuhivla, Kind.Cmene: return letters.refuseOther
  ReadingTag(
    text: letters,
    is_tag: true,
    tag: Tag(words: parts.mapIt(it.word)),
    pieces: reading.pieces,
  )



#[ Rendering ]#

func `$`*(tag: Tag): string = $Tanru(parts: tag.words.mapIt(it.toPart))
  ## Render tag as gismu, or as lujvo form 4.12 scores lowest, as `lojban_parser` renders tanru.


func toTanru*(tag: Tag): string =
  ## Render tag as its words joined by `+`, as lujvo list writes tanru.
  tag.words.mapIt($it).join("+")


func readTanru*(text: string): Option[Tag] =
  ## Read listed words joined by `+` as tag; `none` where any part is unlisted, or last part
  ##   is no gismu (4.11 step 2).
  var words: seq[Word]
  for part in text.split('+'):
    let found = part.word
    if found.isNone: return none(Tag)
    words.add found.get
  if words[^1].kind != Kind.Gismu: return none(Tag)
  some(Tag(words: words))
