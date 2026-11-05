## Read stream of lojban text into its words, each with pause before it and stress it marks.
##
##   |---------------|------------------------------------------------------------|
##   | Code          | Meaning                                                    |
##   |---------------|------------------------------------------------------------|
##   | Pause         | pause before word: absent, written as period, or inferred  |
##   | Occurrence    | word as stream holds it: place, letters, pause and stress  |
##   | ReadingStream | words of stream in order, or refusal with its place        |
##   | readStream    | read text as its words by rules of CLL, or refuse it       |
##   |---------------|------------------------------------------------------------|
##
##   Marks of stream (3.3, 3.9): whitespace and period divide words, and period writes pause;
##     comma breaks syllables inside word; capital marks stressed syllable.
##   Words written together need period between them, cmavo run together aside: 3.3 needs no
##     space only where period stands, and 4.2 joins cmavo alone into one written word. So text
##     splits at whitespace and periods, `splitCompound` splits each compound, and `readWord`
##     reads each word.
##     Cost: cmavo run into brivla, as `lonubroda`, is refused as `Shape`, though sounds of
##       stream split uniquely (4.1); CLL presents no algorithm for that split.
##   Pause follows 4.9. Period writes it. Where rule needs pause that text does not write,
##     reader infers it, since 3.3 calls period optional reminder that correct text implies.
##     So no text is refused for unwritten pause, and each word carries pause before it.
##     Rules read: 3, word opening with vowel or `y`; 5 and 4.2, stressed last syllable before
##       brivla or before stressed first syllable; 6, `Cy` before word not `Cy`; and pause
##       after `y` (4.2).
##     Rules 2 and 4 hold cmene, which #812 reads, and rule 7 holds text that `zoi` and `la'o`
##       quote, which #814 reads; reader refuses each as its gap.
##   Comma is never required (3.3), so word reads without it. Comma breaks syllables, so each
##     stretch it bounds, up to next comma, apostrophe or edge of word, holds vowel, `y`, or
##     consonant that may be syllabic (3.4). Between two vowels of word read here, comma would
##     break diphthong, which is one syllable (3.4), so it is refused there.
##     Cost: comma beside `l`, `m`, `n` or `r` may make it syllabic, which 3.4 admits in
##       principle, so reader accepts it; #812 judges commas of cmene and fu'ivla.
##   Capital marks stress (3.1, 3.9): capitals form one run touching one vowel or diphthong,
##     whole syllable or vowel alone, and consonants of run are not judged. Brivla stresses
##     penultimate syllable, `y` and syllabic consonant not counted; cmavo any syllable or none;
##     `y` never. Capital touching no vowel is refused, as sentence opening `Mi` is: 4.8 keeps
##     capitals for stress alone.
##   Place of each word and refusal is byte of stream where it opens, so caller can point at it.
##   Cost: each word read once, and each cmavo of compound once more; time grows with length of
##     stream (expected).

{.experimental: "strictFuncs".}

import std/[options, strutils]

import ./[clusters, forms, selmaho, tanru]


type
  Pause* {.pure.} = enum  ## Define pause before word of stream (3.3, 4.9).
    Absent  ## No period, and no rule of 4.9 needs pause, so words may run together.
    Written  ## Period writes pause.
    Inferred  ## Rule of 4.9 needs pause that text does not write, so reader infers it (3.3).

  Occurrence* = object  ## Define word as stream holds it: place, letters, pause and stress.
    start*: int  ## Byte of stream where word opens.
    text*: string  ## Letters of word in canonical form: lowercase, commas left out (3.3).
    pause*: Pause  ## Pause before word.
    stress*: Option[int]
      ## Nucleus capitals mark stressed, counted from zero over vowels, `y` and diphthongs of
      ##   word; none where text marks none.
    reading*: Reading  ## Word as `readWord` reads `text`.

  ReadingStream* = object  ## Define outcome of reading stream as its words.
    case is_read*: bool
    of true:
      occurrences*: seq[Occurrence]  ## Words of stream in order; empty for marks alone.
    of false:
      refusal*: Refusal  ## Rule refusing stream, or gap holding it.
      start*: int  ## Byte of stream where offending word or mark opens.
      detail*: string  ## Offending character, or form 4.11 gives; empty otherwise.

  Spelling = object  ## Define written word with its marks taken out.
    letters: string  ## Letters in canonical form.
    places: seq[int]  ## Byte of stream each letter stands at.
    capitals: seq[int]  ## Index of each letter written capital, in order.
    breaks: seq[int]  ## Index of letter each comma stands before, in order.
    commas: seq[int]  ## Byte of stream each comma stands at, in order of `breaks`.


const
  MARKS_BOUNDARY = Whitespace + {'.'}  ## Marks dividing words: whitespace, and period (3.3).
  CAPITALS = MARKS_STREAM - MARKS_BOUNDARY - {','}  ## Capital of each letter, marking stress.
  VOWELS_NUCLEUS = VOWELS + {'y'}  ## Letters making syllable: five vowels, and `y` (3.4, 3.9).
  CONSONANTS_SYLLABIC = {'l', 'm', 'n', 'r'}  ## Consonants that may make syllable alone (3.4).


func refuse(refusal: Refusal, start: int, detail = ""): ReadingStream =
  ## Build reading that refuses stream at byte `start`.
  ReadingStream(is_read: false, refusal: refusal, start: start, detail: detail)


func nuclei(text: string): seq[Slice[int]] =
  ## Find nucleus of each syllable of word: vowel or `y` alone, or diphthong (3.4).
  ##   On-glide is diphthong only first in word opening with it, as 4.2 keeps them to cmavo.
  var at = 0
  while at < text.len:
    if text[at] notin VOWELS_NUCLEUS:
      inc at
      continue
    let
      pair = text[at .. min(at + 1, text.high)]
      size = (if pair in DIPHTHONGS or (at == 0 and pair in DIPHTHONGS_CMAVO): 2 else: 1)
    result.add at .. at + size - 1
    at += size


func isLetteral(text: string): bool = text.len == 2 and text[0].isConsonant and text[1] == 'y'
  ## Test word is letteral `Cy`, which names consonant (4.2, 17.2).


func isPauseNeeded(prior: openArray[Occurrence], next: Occurrence): bool =
  ## Test rule of 4.9 needs pause before `next`, which follows last word of `prior`, if any.
  if next.text[0] in VOWELS_NUCLEUS: return true  # rule 3; `y` too (4.2)
  if prior.len == 0: return false
  let last = prior[^1]
  if last.text == "y": return true  # 4.2, `y` takes pause after it too
  if last.text.isLetteral and not next.text.isLetteral: return true  # rule 6
  if last.stress != some(last.text.nuclei.high): return false
  next.reading.kind in {Kind.Gismu, Kind.Lujvo} or next.stress == some(0)  # rule 5; 4.2


func isStretchSyllabic(text: string, at, start, finish, step: int): bool =
  ## Test stretch from comma at `at` toward `step`, up to next comma, apostrophe or edge of
  ##   word, holds vowel, `y` or consonant that may be syllabic (3.4).
  var i = at + step
  while i >= start and i < finish and text[i] notin {',', '\''}:
    if text[i].toLowerAscii in VOWELS_NUCLEUS + CONSONANTS_SYLLABIC: return true
    i += step
  false


func refusalMarks(text: string, start, finish: int): Option[ReadingStream] =
  ## Find first character or comma of written word that no rule admits, as refusal at its byte.
  for at in start ..< finish:
    let symbol = text[at]
    if symbol in tanru.LETTERS or symbol in CAPITALS: continue
    if symbol != ',': return some(refuse(Refusal.Letter, at, text.character(at)))  # 3.1
    let is_syllabic = text.isStretchSyllabic(at, start, finish, -1) and
        text.isStretchSyllabic(at, start, finish, 1)
    if not is_syllabic: return some(refuse(Refusal.Comma, at))  # 3.3, comma breaks syllables
  none(ReadingStream)


func toSpelling(text: string, start, finish: int): Spelling =
  ## Take marks out of written word: lowercase each capital, and leave out each comma.
  for at in start ..< finish:
    if text[at] == ',':
      result.breaks.add result.letters.len
      result.commas.add at
      continue
    if text[at] in CAPITALS: result.capitals.add result.letters.len
    result.letters.add text[at].toLowerAscii
    result.places.add at


func nucleusStressed(word: string, kind: Kind, capitals, breaks: openArray[int]): Option[int] =
  ## Find nucleus capitals mark stressed, or none where 3.9 admits no such stress: capitals
  ##   broken by letter or comma, touching no nucleus or several, on `y`, or off penultimate
  ##   syllable of brivla, `y` not counted.
  ##   `capitals` holds one index at least; `capitals` and `breaks` index letters of `word`.
  let (first, last) = (capitals[0], capitals[^1])
  if last - first + 1 != capitals.len: return  # 3.9, one syllable capitalized
  for b in breaks:
    if first < b and b <= last: return  # 3.3, comma breaks syllable inside run
  let spans = word.nuclei
  var touched: seq[int]
  for i, nucleus in spans:
    if nucleus.b >= first and nucleus.a <= last: touched.add i
  if touched.len != 1 or word[spans[touched[0]].a] == 'y': return  # 3.9, `y` never stressed
  if kind in {Kind.Gismu, Kind.Lujvo}:
    var counted: seq[int]
    for i, nucleus in spans:
      if word[nucleus.a] != 'y': counted.add i
    if touched[0] != counted[^2]: return  # 3.9, brivla stresses penultimate; two at least (4.3)
  some(touched[0])


func readPieces(
    occurrences: var seq[Occurrence], spelling: Spelling, whole: Reading, is_period: bool
): Option[ReadingStream] =
  ## Read each word of one written word onto `occurrences`, cmavo of compound in order, with
  ##   pause before it; refusal at first comma, capital or quotation no rule admits, else none.
  let pieces = (if whole.is_word: @[spelling.letters] else: spelling.letters.splitCompound)
  var lo = 0
  for piece in pieces:
    let
      hi = lo + piece.len
      reading = (if whole.is_word: whole else: piece.readWord)

    # Refuse comma inside diphthong, which is one syllable (3.4).
    var capitals, breaks: seq[int]
    for k, b in spelling.breaks:
      if b <= lo or b >= hi: continue
      if piece[b - lo - 1] in VOWELS_NUCLEUS and piece[b - lo] in VOWELS_NUCLEUS:
        return some(refuse(Refusal.Comma, spelling.commas[k]))
      breaks.add b - lo

    # Read stress capitals mark, and refuse stress that 3.9 does not admit.
    for c in spelling.capitals:
      if c >= lo and c < hi: capitals.add c - lo
    var stress = none(int)
    if capitals.len > 0:
      stress = piece.nucleusStressed(reading.kind, capitals, breaks)
      if stress.isNone: return some(refuse(Refusal.Stress, spelling.places[lo + capitals[0]]))

    # Stop at quotation of text that is not lojban, gap of #814 (4.9 rule 7).
    if reading.selmaho == some(Selmaho.Zoi):
      return some(refuse(Refusal.Foreign, spelling.places[lo]))

    # Add word, with pause that period writes or rule needs.
    var occurrence =
      Occurrence(start: spelling.places[lo], text: piece, stress: stress, reading: reading)
    occurrence.pause =
      if lo == 0 and is_period: Pause.Written
      elif occurrences.isPauseNeeded(occurrence): Pause.Inferred
      else: Pause.Absent
    occurrences.add occurrence
    lo = hi
  none(ReadingStream)


func readStream*(text: string): ReadingStream =
  ## Read text as its words by rules of CLL alone, each with pause before it and stress it
  ##   marks; refuse at first word or mark that no rule admits, naming its byte.
  var
    occurrences: seq[Occurrence]
    is_period = false
    at = 0
  while at < text.len:
    # Pass marks between words, noting period.
    if text[at] in MARKS_BOUNDARY:
      is_period = is_period or text[at] == '.'
      inc at
      continue

    # Take written word up to next mark between words, and refuse mark no rule admits.
    let start = at
    while at < text.len and text[at] notin MARKS_BOUNDARY: inc at
    let refusal_marks = text.refusalMarks(start, at)
    if refusal_marks.isSome: return refusal_marks.get

    # Read each word written word holds, or refuse it as `readWord` does.
    let
      spelling = text.toSpelling(start, at)
      whole = spelling.letters.readWord
    if not whole.is_word and whole.refusal != Refusal.Stream:
      return refuse(whole.refusal, start, whole.detail)
    let refusal_pieces = occurrences.readPieces(spelling, whole, is_period)
    if refusal_pieces.isSome: return refusal_pieces.get
    is_period = false
  ReadingStream(is_read: true, occurrences: occurrences)
