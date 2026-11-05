## Read word as words of its tanru, and render tanru back as word, as CLL chapter 4 reads lujvo.
##
##   |---------------------|-------------------------------------------------------------|
##   | Code                | Meaning                                                     |
##   |---------------------|-------------------------------------------------------------|
##   | Tanru               | words of one tanru, in order; listed word alone for itself  |
##   | readWord            | read text as word, or refuse it with reason                 |
##   | Refusal             | why text is no word reader reads                            |
##   | `$`                 | lujvo form 4.12 scores lowest, or listed word itself        |
##   | toText, readTanru   | words joined by `+`, as lujvo list writes tanru             |
##   |---------------------|-------------------------------------------------------------|
##
##   Copied as part of `lojban_tagger/src/lojban_tagger/tags.nim` until #809 drops it (II.9).
##   Word reads as words of its tanru, never as its spelling: rafsi chosen do not change lujvo
##     (CLL 4.5), so `brivla`, `brivalsi`, `bridyvla` and `bridyvalsi` read as one tanru, and
##     `$` renders form 4.12 prefers. Order of words stays, since tanru is modifier then head
##     (4.5).
##   Rafsi of cmavo stands for that cmavo, and tanru keeps it: `selci'a` reads as `se ciska`,
##     never as `ciska`, since `se` converts it (4.6, 9.4).
##   Lujvo ending in rafsi of cmavo is refused, as 4.11 step 2 takes last rafsi from "final
##     gismu in tanru". Listed word alone reads as itself, cmavo too, as tanru of one word.
##   Text is read as written, in canonical form: lowercase letters and apostrophe alone.
##     Capital marks stress of name alone (3.1), and comma marks syllable break (3.3); reader
##     refuses both, as it reads no name and no written syllable yet.
##     Cost: CLL text writing either inside word, as `sai,r,goi` and `DI,ky,jvo` of 3.9, is
##       refused; test `Section 3.9` of `test_tanru.nim` waits for it, skipped (IX.9).
##   `h` never stands for apostrophe: 3.3 says letter `h` is not used for it, so `h` is refused.
##   `$` rejects 4-letter rafsi several gismu share (`brod`) wherever gismu has other rafsi,
##     so rendered tanru reads back as itself; `brodi`, `brodo` and `brodu` have none, so their
##     lujvo render with `brod` and read as `Refusal.Ambiguous` (open question in PROVENANCE).
##   Cost: `$` scores every choice of rafsi, at most four per gismu, so `4^n` joins for tanru
##     of `n` gismu, and time grows with them (expected); `readWord` caps no words.

{.experimental: "strictFuncs".}

import std/[options, sequtils, strutils]

import ./[dictionary, forms, lujvo]


type
  Tanru* = object  ## Define tanru: words of one tanru, gismu and cmavo, in order.
    words*: seq[Word]  ## Words of tanru; one listed word alone for that word.

  Refusal* {.pure.} = enum  ## Define why text is no word reader reads.
    Empty  ## Text holds no character.
    Letter  ## Character outside `LETTERS`; detail is that character, whole.
    Cmavo  ## Lujvo ends in rafsi of cmavo, where 4.11 step 2 asks gismu; detail names it.
    Unlisted  ## Gismu shape, but list holds no such gismu; detail is word.
    Rafsi  ## Rafsi no list assigns; detail is rafsi.
    Ambiguous  ## 4-letter rafsi several gismu share; detail is rafsi.
    Hyphen  ## Rafsi known, hyphens differ from 4.11; detail is form 4.11 gives.
    Shape  ## Neither listed word nor lujvo by shape, as cmavo outside list is.

  Reading* = object  ## Define outcome of reading text as word.
    case is_word*: bool
    of true:
      tanru*: Tanru  ## Tanru text reads as.
      pieces*: seq[Piece]  ## Rafsi as text spells them; empty for listed word.
    of false:
      refusal*: Refusal  ## Why text is no word reader reads.
      detail*: string  ## Offending part, or form 4.11 gives.


const LETTERS* = {
  'a', 'b', 'c', 'd', 'e', 'f', 'g', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'r', 's', 't', 'u',
  'v', 'x', 'y', 'z', '\'',
}
  ## Letters word holds in canonical form: vowels, `y`, seventeen consonants and apostrophe
  ##   (CLL 3.1, 3.6).


func `==`*(a, b: Tanru): bool = a.words == b.words
  ## Compare tanru by words, in order, cmavo included.



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


func refuse(refusal: Refusal, detail = ""): Reading =
  ## Build reading that refuses text.
  Reading(is_word: false, refusal: refusal, detail: detail)


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
    if segments.len == 0: return refuse(Refusal.Shape)
    return refuse(Refusal.Hyphen, joinRafsi(segments[0].mapIt(it.rafsi)))
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
    if words[^1].kind == Kind.Cmavo:  # 4.11 step 2: last rafsi from final gismu of tanru
      return refuse(Refusal.Cmavo, pieces[^1].rafsi & " (" & $words[^1] & ")")
    return Reading(is_word: true, tanru: Tanru(words: words), pieces: pieces)
  refuse(first_refusal[0], first_refusal[1])


func readWord*(text: string): Reading =
  ## Read text as word: gismu or cmavo of list, or lujvo whose rafsi stand for listed words,
  ##   last one gismu (4.11 step 2); text is read as written, in canonical form.
  ##   Character refused is named whole, so detail of UTF-8 text stays UTF-8; held by test
  ##     "Character outside letters is named whole, so detail of UTF-8 stays UTF-8" of
  ##     `test_tanru.nim`.
  if text.len == 0: return refuse(Refusal.Empty)
  for at in 0..<text.len:
    if text[at] notin LETTERS: return refuse(Refusal.Letter, text.character(at))
  let listed = text.word
  if listed.isSome: return Reading(is_word: true, tanru: Tanru(words: @[listed.get]))
  if text.isGismu: return refuse(Refusal.Unlisted, text)
  readLujvo(text)



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


func `$`*(tanru: Tanru): string =
  ## Render tanru as word: listed word alone as itself, else lujvo form 4.12 scores lowest,
  ##   first in order of choices on tie.
  if tanru.words.len == 1: return $tanru.words[0]
  var options = @[newSeq[string]()]
  for i, w in tanru.words:
    var extended: seq[seq[string]]
    for chosen in options:
      for one in choices(w, is_final = i == tanru.words.high): extended.add chosen & one
    options = extended
  var best = (score: high(int), word: "")
  for rafsi in options:
    let value = rafsi.toPieces.score
    if value < best.score: best = (value, joinRafsi(rafsi))
  best.word


func toText*(tanru: Tanru): string =
  ## Render tanru as its words joined by `+`, as lujvo list writes tanru; `readTanru` reads it.
  tanru.words.mapIt($it).join("+")


func readTanru*(text: string): Option[Tanru] =
  ## Read listed words joined by `+` as tanru; `none` where any part is unlisted, or where two
  ##   words or more end in cmavo, as lujvo takes last rafsi from final gismu (4.11 step 2).
  var words: seq[Word]
  for part in text.split('+'):
    let found = part.word
    if found.isNone: return none(Tanru)
    words.add found.get
  if words.len > 1 and words[^1].kind != Kind.Gismu: return none(Tanru)
  some(Tanru(words: words))
