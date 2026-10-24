## Read text as tag, i.e. gismu or lujvo made of gismu alone, and reduce it to gismu of its tanru.
##
##   |---------------------|-------------------------------------------------------------|
##   | Code                | Meaning                                                     |
##   |---------------------|-------------------------------------------------------------|
##   | Tag                 | gismu of one tanru, in order; one alone for gismu           |
##   | readTag             | read text as tag, or refuse it with reason                  |
##   | Refusal             | why text is no tag                                          |
##   | `$`                 | lujvo form 4.12 scores lowest, or gismu itself              |
##   | toTanru, readTanru  | gismu joined by `+`, as lujvo list writes tanru             |
##   |---------------------|-------------------------------------------------------------|
##
##   Tag is its gismu, never its spelling: rafsi chosen do not change lujvo (CLL 4.5), so
##     `brivla`, `brivalsi`, `bridyvla` and `bridyvalsi` read as one tag, and `$` renders form
##     4.12 prefers. Order of gismu stays, since tanru is modifier then head (4.5).
##   Lujvo holding rafsi of cmavo is refused, naming rafsi and cmavo: Architect's brief admits
##     lujvo made of gismu alone. Reader still knows every rafsi of cmavo list carries, so
##     refusal says why rather than calling rafsi unknown.
##     Cost: `selci'a` and every lujvo converting place with `se` cannot tag (open decision).
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
  Tag* = object  ## Define tag: gismu of its tanru, in order.
    words*: seq[Word]  ## Gismu, one alone for gismu tag.

  Refusal* {.pure.} = enum  ## Define why text is no tag.
    Empty  ## Text holds nothing but spaces.
    Letter  ## Character outside Lojban letters; detail is that character.
    Cmavo  ## Word is cmavo, or lujvo holds rafsi of cmavo; detail names it.
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
  ## Compare tags by gismu, in order.



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


func readLujvo(text: string): Reading =
  ## Read text as lujvo whose rafsi all stand for listed gismu.
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
    for i, w in words:
      if w.kind == Kind.Cmavo:
        return refuse(text, Refusal.Cmavo, pieces[i].rafsi & " (" & $w & ")")
    return Reading(text: text, is_tag: true, tag: Tag(words: words), pieces: pieces)
  refuse(text, first_refusal[0], first_refusal[1])


func readTag*(text: string): Reading =
  ## Read text as tag: gismu of list, or lujvo whose rafsi all stand for gismu of list.
  let letters = text.strip.toLowerAscii.replace(",", "")
  if letters.len == 0: return refuse(letters, Refusal.Empty)
  for character in letters:
    if character notin LETTERS: return refuse(letters, Refusal.Letter, $character)
  let listed = letters.word
  if listed.isSome:
    if listed.get.kind == Kind.Cmavo: return refuse(letters, Refusal.Cmavo, letters)
    return Reading(text: letters, is_tag: true, tag: Tag(words: @[listed.get]))
  if letters.isGismu: return refuse(letters, Refusal.Unlisted, letters)
  readLujvo(letters)



#[ Rendering ]#

func choices(w: Word, is_final: bool): seq[string] =
  ## List rafsi of gismu 4.11 allows at its position, steps 1 and 2.
  ##   4-letter rafsi several gismu share is left out where gismu has any other.
  let entry = w.entry
  if is_final:
    for one in entry.rafsi:
      if one.form.get in {Form.Ccv, Form.Cvv}: result.add one
    result.add entry.word
    return
  result = entry.rafsi
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
  ## Render tag as its gismu joined by `+`, as lujvo list writes tanru.
  tag.words.mapIt($it).join("+")


func readTanru*(text: string): Option[Tag] =
  ## Read gismu joined by `+` as tag; `none` where any part is no gismu of list.
  var words: seq[Word]
  for part in text.split('+'):
    let found = part.word
    if found.isNone or found.get.kind != Kind.Gismu: return none(Tag)
    words.add found.get
  some(Tag(words: words))
