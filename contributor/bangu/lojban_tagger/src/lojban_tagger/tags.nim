## Read text as tag, i.e. gismu or lujvo, and reduce it to words of its tanru, gismu among them.
##
##   |---------------------|-------------------------------------------------------------|
##   | Code                | Meaning                                                     |
##   |---------------------|-------------------------------------------------------------|
##   | Tag                 | words of one tanru, in order; one gismu alone for gismu     |
##   | gismu               | gismu of tag, cmavo left out; what search matches on        |
##   | readTag             | read text as tag, or refuse it with reason                  |
##   | Refusal             | why text is no tag                                          |
##   | `$`                 | lujvo form 4.12 scores lowest, or gismu itself              |
##   | toTanru, readTanru  | words joined by `+`, as lujvo list writes tanru             |
##   |---------------------|-------------------------------------------------------------|
##
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
##   `h` never stands for apostrophe: 3.3 says letter `h` is not used for it, so `h` is refused.
##   `$` rejects 4-letter rafsi several gismu share (`brod`) wherever gismu has other rafsi,
##     so rendered tag reads back as itself; `brodi`, `brodo` and `brodu` have none, so their
##     lujvo render with `brod` and read as `Refusal.Ambiguous` (open question in PROVENANCE).
##   Cost: `$` scores every choice of rafsi, at most four per gismu, so `4^n` joins for tag of
##     `n` gismu; tags are short, so cost is small (unmeasured).

{.experimental: "strictFuncs".}

import std/[options, sequtils, strutils]

import ./[dictionary, forms, lujvo]


type
  Tag* = object  ## Define tag: words of its tanru, gismu and cmavo, in order, last one gismu.
    words*: seq[Word]  ## Words of tanru; one gismu alone for gismu tag.

  Refusal* {.pure.} = enum  ## Define why text is no tag.
    Empty  ## Text holds nothing but spaces.
    Letter  ## Character outside Lojban letters; detail is that character, whole.
    Cmavo  ## Word is cmavo, or lujvo holds no gismu or ends in cmavo; detail names it.
    Unlisted  ## Gismu shape, but list holds no such gismu; detail is word.
    Rafsi  ## Rafsi no list assigns; detail is rafsi.
    Ambiguous  ## 4-letter rafsi several gismu share; detail is rafsi.
    Hyphen  ## Rafsi known, hyphens differ from 4.11; detail is form 4.11 gives.
    Shape  ## Neither gismu nor lujvo by shape.

  Reading* = object  ## Define outcome of reading text as tag.
    text*: string  ## Text as read, trimmed, folded to lowercase, commas removed.
    case is_tag*: bool
    of true:
      tag*: Tag  ## Tag text reduces to.
      pieces*: seq[Piece]  ## Rafsi as text spells them; empty for gismu.
    of false:
      refusal*: Refusal  ## Why text is no tag.
      detail*: string  ## Offending part, or form 4.11 gives.


const LETTERS* = {
  'a', 'b', 'c', 'd', 'e', 'f', 'g', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'r', 's', 't', 'u',
  'v', 'x', 'y', 'z', '\'',
}
  ## Letters brivla may hold: vowels, `y`, seventeen consonants and apostrophe (CLL 3.1, 3.6).


func `==`*(a, b: Tag): bool = a.words == b.words
  ## Compare tags by words of tanru, in order, cmavo included.

func gismu*(tag: Tag): seq[Word] = tag.words.filterIt(it.kind == Kind.Gismu)
  ## Read gismu of tag, in order, cmavo left out; search matches on these alone.

func isGismuAlone*(tag: Tag): bool = tag.words.allIt(it.kind == Kind.Gismu)
  ## Test tag holds gismu alone, i.e. no cmavo converts or groups them.



#[ Reading ]#

func resolve(piece: Piece): tuple[words: seq[Word], refusal: Refusal] =
  ## Find word piece stands for; refusal names why none, or why several.
  case piece.form
  of Form.Cvc, Form.Ccv, Form.Cvv:
    let found = piece.rafsi.wordRafsi
    if found.isNone: return (@[], Refusal.Rafsi)
    (@[found.get], Refusal.Empty)
  of Form.Cvcc, Form.Ccvc:
    let found = piece.rafsi.wordsStem
    if found.len == 0: return (@[], Refusal.Rafsi)
    if found.len > 1: return (found, Refusal.Ambiguous)
    (found, Refusal.Empty)
  of Form.Cvccv, Form.Ccvcv:
    let found = piece.rafsi.word
    if found.isNone: return (@[], Refusal.Unlisted)
    (@[found.get], Refusal.Empty)


func refuse(text: string, refusal: Refusal, detail = ""): Reading =
  ## Build reading that refuses text.
  Reading(text: text, is_tag: false, refusal: refusal, detail: detail)


func character(text: string, at: int): string =
  ## Read character opening at byte `at`: lead byte, then each continuation byte it announces,
  ##   by bit distribution of Table 3-6 of Unicode Standard; byte alone where none follows.
  let size =
    case uint8(text[at])
    of 0xC0'u8..0xDF'u8: 2
    of 0xE0'u8..0xEF'u8: 3
    of 0xF0'u8..0xF7'u8: 4
    else: 1
  var finish = at + 1
  while finish < min(text.len, at + size) and (uint8(text[finish]) and 0xC0) == 0x80: inc finish
  text[at..<finish]


func readLujvo(text: string): Reading =
  ## Read text as lujvo whose rafsi all stand for listed words, last one gismu.
  let splits = text.splitLujvo
  if splits.len == 0:
    let segments = text.segmentLujvo
    if segments.len == 0: return refuse(text, Refusal.Shape)
    return refuse(text, Refusal.Hyphen, joinRafsi(segments[0].mapIt(it.rafsi)))
  var first_refusal = (Refusal.Shape, "")
  for pieces in splits:
    var words: seq[Word]
    for piece in pieces:
      let (found, refusal) = piece.resolve
      if refusal != Refusal.Empty:
        if first_refusal[0] == Refusal.Shape: first_refusal = (refusal, piece.rafsi)
        break
      words.add found[0]
    if words.len < pieces.len: continue
    if words[^1].kind == Kind.Cmavo:  # 4.11 step 2: tanru ends in gismu; so tag holds one
      return refuse(text, Refusal.Cmavo, pieces[^1].rafsi & " (" & $words[^1] & ")")
    return Reading(text: text, is_tag: true, tag: Tag(words: words), pieces: pieces)
  refuse(text, first_refusal[0], first_refusal[1])


func readTag*(text: string): Reading =
  ## Read text as tag: gismu of list, or lujvo whose rafsi stand for listed words, last gismu.
  ##   Character refused is named whole, so report of UTF-8 text stays UTF-8; held by test
  ##     "Character outside letters is named whole, so report of UTF-8 stays UTF-8" of
  ##     `test_tags.nim`.
  let letters = text.strip.toLowerAscii.replace(",", "")
  if letters.len == 0: return refuse(letters, Refusal.Empty)
  for at in 0..<letters.len:
    if letters[at] notin LETTERS: return refuse(letters, Refusal.Letter, letters.character(at))
  let listed = letters.word
  if listed.isSome:
    if listed.get.kind == Kind.Cmavo: return refuse(letters, Refusal.Cmavo, letters)
    return Reading(text: letters, is_tag: true, tag: Tag(words: @[listed.get]))
  if letters.isGismu: return refuse(letters, Refusal.Unlisted, letters)
  readLujvo(letters)



#[ Rendering ]#

func choices(w: Word, is_final: bool): seq[string] =
  ## List rafsi of word 4.11 allows at its position, steps 1 and 2; cmavo has short rafsi alone.
  ##   4-letter rafsi several gismu share is left out where gismu has any other.
  let entry = w.entry
  if is_final:
    for one in entry.rafsi:
      if one.form.get in {Form.Ccv, Form.Cvv}: result.add one
    if w.kind == Kind.Gismu: result.add entry.word
    return
  result = entry.rafsi
  if w.kind != Kind.Gismu: return
  let stem = entry.word[0 .. 3]
  if stem.wordsStem.len == 1 or result.len == 0: result.add stem


func `$`*(tag: Tag): string =
  ## Render tag as gismu, or as lujvo form 4.12 scores lowest; first in order of choices on tie.
  if tag.words.len == 1: return $tag.words[0]
  var options = @[newSeq[string]()]
  for i, w in tag.words:
    var extended: seq[seq[string]]
    for chosen in options:
      for one in choices(w, is_final = i == tag.words.high): extended.add chosen & one
    options = extended
  var best = (score: high(int), word: "")
  for rafsi in options:
    let value = rafsi.toPieces.score
    if value < best.score: best = (value, joinRafsi(rafsi))
  best.word


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
