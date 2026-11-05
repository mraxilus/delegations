## Read word by rules of CLL alone, as words of its tanru, and render tanru back as word.
##
##   |---------------------|-------------------------------------------------------------|
##   | Code                | Meaning                                                     |
##   |---------------------|-------------------------------------------------------------|
##   | Part                | word of tanru: listed word, or letters naming none of list  |
##   | Tanru               | parts of one tanru, in order; word read whole for itself    |
##   | readWord            | read text as word by rules of CLL, or refuse it with reason |
##   | Refusal             | rule of CLL refusing text, or gap reader does not read yet  |
##   | `$`                 | lujvo form 4.12 scores lowest, or word itself               |
##   |---------------------|-------------------------------------------------------------|
##
##   Sibling: part of `lojban_tagger/src/lojban_tagger/tags.nim` holds earlier copy, reading
##     listed words alone, until #809 drops it (II.9).
##   Rules judge, list names (#823): text reads wherever rules of CLL admit it, whether list
##     holds it or not. List names word of each part it assigns rafsi; part no list names keeps
##     its letters and has no meaning here, and `lojban_tagger` refuses it.
##   Class follows letters, as 4.1 to 4.8 sort them: final consonant marks cmene (4.8);
##     consonant pair in first five letters, `y` and apostrophe not counted, marks brivla (4.3),
##     which is gismu by its five letters (4.4), else lujvo by its rafsi (4.6, 4.11); no pair at
##     all marks cmavo (4.2), one, or several run together.
##   Each refusal names rule of CLL. Where CLL admits text that reader does not read yet,
##     refusal names gap and issue that reads it: `Stream` (#811), `Cmene` and `Fuhivla` (#812).
##     Cost: gap refuses some text that no rule admits either, as `cia`, which 3.4 forbids;
##       issue of gap tells two apart.
##   Word reads as words of its tanru, never as its spelling: rafsi chosen do not change lujvo
##     (CLL 4.5), so `brivla`, `brivalsi`, `bridyvla` and `bridyvalsi` read as one tanru, and
##     `$` renders form 4.12 prefers. Order of words stays, since tanru is modifier then head
##     (4.5).
##   Rafsi of cmavo stands for that cmavo, and tanru keeps it: `selci'a` reads as `se ciska`,
##     never as `ciska`, since `se` converts it (4.6, 9.4). Lujvo whose last rafsi names cmavo
##     reads too: 4.11 step 2 takes last rafsi from final gismu, but which word rafsi names is
##     list's to say, never letters'.
##   Shared 4-letter rafsi names no one gismu (`brod`, 4.4), so its part keeps letters `brod`.
##   Cmavo read whole carries its selma'o, which cmavo list gives (chapter 20); cmavo no list
##     holds, as experimental `ku'a'e`, carries none. Part of lujvo carries none: rafsi can spell
##     cmavo, as `kau` of `kampu` spells cmavo `kau`, and names no cmavo for it.
##   Split is first of `splitLujvo`; laws of `test_lujvo.nim` hold it unique over random rafsi
##     and over lujvo list.
##   Text is read as written, in canonical form: lowercase letters and apostrophe alone. Space,
##     comma, period and capital are marks of stream (3.3, 3.9), which #811 reads.
##     Cost: CLL text writing comma or capital inside word, as `sai,r,goi` and `DI,ky,jvo` of
##       3.9, is refused as gap; test `Section 3.9` of `test_tanru.nim` waits for it, skipped.
##   `h` never stands for apostrophe: 3.3 says letter `h` is not used for it, so `h` is refused.
##   `$` leaves out 4-letter rafsi several gismu share wherever gismu has other rafsi;
##     `brodi`, `brodo` and `brodu` have none, so their lujvo render with `brod`, and read back
##     with part `brod` (open question in PROVENANCE).
##   Cost: `$` scores every choice of rafsi, at most four per gismu, so `4^n` joins for tanru
##     of `n` gismu, and time grows with them (expected); `readWord` caps no words.

{.experimental: "strictFuncs".}

import std/[options, sequtils, strutils]

import ./[clusters, dictionary, forms, lujvo, selmaho]


type
  Part* = object  ## Define word of tanru: listed word, or letters naming no one word of list.
    case is_listed*: bool
    of true:
      word*: Word  ## Word of gismu list that text or rafsi names (4.6).
    of false:
      letters*: string  ## Word read whole, or rafsi, that names none of list, or several.

  Tanru* = object  ## Define tanru: parts of one tanru, gismu and cmavo, in order.
    parts*: seq[Part]  ## Parts of tanru; one part alone for word read whole.

  Refusal* {.pure.} = enum  ## Define why text is no word reader reads: rule of CLL, or gap.
    Empty  ## Text holds no character, so no word of any class (4.1).
    Letter  ## Character no lojban text holds (3.1, 3.3); detail is that character, whole.
    Apostrophe  ## Apostrophe not between vowels, which alone it joins (3.3).
    Shape  ## Letters fit no class: no cmavo (4.2), brivla (4.3) or cmene (4.8).
    Hyphen  ## Rafsi fit lujvo, but hyphens differ from 4.11; detail is form 4.11 gives.
    Stream  ## Gap of #811: mark of stream (3.3, 3.9), or several words run together (4.2).
    Cmene  ## Gap of #812: final consonant marks cmene (4.3, 4.8).
    Fuhivla  ## Gap of #812: brivla neither gismu nor lujvo, so fu'ivla (4.7), or no word.

  Reading* = object  ## Define outcome of reading text as word.
    case is_word*: bool
    of true:
      kind*: Kind  ## Class of word by its letters (4.1).
      tanru*: Tanru  ## Tanru text reads as.
      pieces*: seq[Piece]  ## Rafsi as text spells them; empty for word read whole.
      selmaho*: Option[Selmaho]
        ## Selma'o cmavo list gives cmavo read whole (chapter 20); none otherwise.
    of false:
      refusal*: Refusal  ## Rule refusing text, or gap holding it.
      detail*: string  ## Offending character, or form 4.11 gives; empty where whole text offends.


const
  LETTERS* = {
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'r', 's', 't',
    'u', 'v', 'x', 'y', 'z', '\'',
  }
    ## Letters word holds in canonical form: vowels, `y`, seventeen consonants and apostrophe
    ##   (CLL 3.1, 3.6).
  MARKS_STREAM* = block:
    ## Characters marking stream rather than word: whitespace between words, period of pause,
    ##   comma of syllable break (3.3), and capital of stress (3.9), one for each letter.
    var marks = Whitespace + {',', '.'}
    for letter in LETTERS - {'\''}: marks.incl letter.toUpperAscii
    marks
  VOWELS_JOINED = VOWELS + {'y'}  ## Vowels apostrophe may stand between: `y'y` joins two `y`.


func `==`*(a, b: Part): bool =
  ## Compare parts: listed ones by word, others by letters; listed part never equals other.
  if a.is_listed != b.is_listed: return false
  if a.is_listed: a.word == b.word else: a.letters == b.letters


func `==`*(a, b: Tanru): bool = a.parts == b.parts
  ## Compare tanru by parts, in order, cmavo included.

func toPart*(w: Word): Part = Part(is_listed: true, word: w)
  ## Hold listed word as part of tanru.

func `$`*(part: Part): string = (if part.is_listed: $part.word else: part.letters)
  ## Render part as list spells its word, or as its letters.



#[ Reading ]#

func part(piece: Piece): Part =
  ## Name word piece stands for where list assigns it one (4.6); else keep its letters.
  let found =
    case piece.form
    of Form.Cvc, Form.Ccv, Form.Cvv: piece.rafsi.wordRafsi
    of Form.Cvcc, Form.Ccvc:
      let stems = piece.rafsi.wordsStem
      if stems.len == 1: some(stems[0]) else: none(Word)
    of Form.Cvccv, Form.Ccvcv: piece.rafsi.word
  if found.isSome: found.get.toPart else: Part(is_listed: false, letters: piece.rafsi)


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


func isPairHeld(text: string): bool =
  ## Test text holds two consonants side by side anywhere, which no cmavo holds (4.2).
  for i in 0 ..< text.high:
    if text[i].isConsonant and text[i + 1].isConsonant: return true
  false


func syllables(text: string): int =
  ## Count syllables: each vowel, `y` included, is one, and diphthong of 4.1 joins two (3.4).
  for i, letter in text:
    if letter notin VOWELS_JOINED: continue
    if i > 0 and text[i - 1 .. i] in DIPHTHONGS: continue
    inc result


func readWhole(text: string, kind: Kind): Reading =
  ## Read text as one word of its class: listed word where list holds it, else its letters.
  let
    listed = text.word
    part = if listed.isSome: listed.get.toPart else: Part(is_listed: false, letters: text)
  Reading(
    is_word: true,
    kind: kind,
    tanru: Tanru(parts: @[part]),
    selmaho: (if kind == Kind.Cmavo: text.selmaho else: none(Selmaho)),
  )


func readLujvo(text: string): Reading =
  ## Read brivla as lujvo by forms of its rafsi and hyphens of 4.11; list names parts it can.
  let splits = text.splitLujvo
  if splits.len == 0:
    let segments = text.segmentLujvo
    if segments.len == 0: return refuse(Refusal.Fuhivla)
    return refuse(Refusal.Hyphen, joinRafsi(segments[0].mapIt(it.rafsi)))
  let pieces = splits[0]
  Reading(is_word: true, kind: Kind.Lujvo, tanru: Tanru(parts: pieces.mapIt(it.part)),
      pieces: pieces)


func readWord*(text: string): Reading =
  ## Read text as one word by rules of CLL alone: cmavo, gismu or lujvo, whether list holds it
  ##   or not; text is read as written, in canonical form.
  ##   Character refused is named whole, so detail of UTF-8 text stays UTF-8; held by test
  ##     "Character outside letters is named whole, so detail of UTF-8 stays UTF-8" of
  ##     `test_tanru.nim`.
  if text.len == 0: return refuse(Refusal.Empty)
  for at in 0..<text.len:
    if text[at] in MARKS_STREAM: return refuse(Refusal.Stream, $text[at])
    if text[at] notin LETTERS: return refuse(Refusal.Letter, text.character(at))
  for at in 0..<text.len:
    let is_joining = at > 0 and at < text.high and text[at - 1] in VOWELS_JOINED and
        text[at + 1] in VOWELS_JOINED
    if text[at] == '\'' and not is_joining: return refuse(Refusal.Apostrophe)

  # Sort class by letters, as 4.3 tells cmene, brivla and cmavo apart.
  if text[^1].isConsonant: return refuse(Refusal.Cmene)
  if text.isBrivla:
    if text.syllables < 2: return refuse(Refusal.Shape)  # 4.3, penultimate stress needs two
    if text.isGismu: return readWhole(text, Kind.Gismu)
    return readLujvo(text)
  if not text.isPairHeld:
    if text.isCmavo: return readWhole(text, Kind.Cmavo)
    return refuse(Refusal.Stream)  # 4.2, compound cmavo reads as each cmavo, which #811 does
  if text[^1] == 'y': return refuse(Refusal.Shape)  # pair, yet `y` last: neither class of 4.3
  refuse(Refusal.Stream)  # pair past fifth letter: cmavo run into brivla, which #811 splits



#[ Rendering ]#

func choices(part: Part, is_final: bool): seq[string] =
  ## List rafsi of part 4.11 allows at its position, steps 1 and 2; cmavo has short rafsi alone.
  ##   4-letter rafsi several gismu share is left out where gismu has any other.
  ##   Part no list names offers its letters where their form takes position, or 4-letter
  ##     rafsi of gismu read whole; cmavo no rafsi stands for, as `lo`, offers none.
  if not part.is_listed:
    let shape = part.letters.form
    if shape.isNone: return
    if shape.get in FORMS_GISMU:
      return @[(if is_final: part.letters else: part.letters[0 .. 3])]
    let forms_allowed = (if is_final: FORMS_FINAL else: FORMS_SHORT + FORMS_UNREDUCED)
    if shape.get in forms_allowed: result.add part.letters
    return
  let entry = part.word.entry
  if is_final:
    for one in entry.rafsi:
      if one.form.get in {Form.Ccv, Form.Cvv}: result.add one
    if part.word.kind == Kind.Gismu: result.add entry.word
    return
  result = entry.rafsi
  if part.word.kind != Kind.Gismu: return
  let stem = entry.word[0 .. 3]
  if stem.wordsStem.len == 1 or result.len == 0: result.add stem


func `$`*(tanru: Tanru): string =
  ## Render tanru as word: part alone as itself, else lujvo form 4.12 scores lowest, first in
  ##   order of choices on tie.
  ##   Tanru with no lujvo form, as one ending in cmavo without CCV or CVV rafsi, renders its
  ##     parts one space apart, as CLL writes tanru (5.1).
  if tanru.parts.len == 0: return ""
  if tanru.parts.len == 1: return $tanru.parts[0]
  var options = @[newSeq[string]()]
  for i, part in tanru.parts:
    var extended: seq[seq[string]]
    for chosen in options:
      for one in choices(part, is_final = i == tanru.parts.high): extended.add chosen & one
    options = extended
  if options.len == 0: return tanru.parts.mapIt($it).join(" ")
  var best = (score: high(int), word: "")
  for rafsi in options:
    let value = rafsi.toPieces.score
    if value < best.score: best = (value, joinRafsi(rafsi))
  best.word
