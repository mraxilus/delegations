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
##   Written word between marks reads as one word where it can, its commas and capitals
##     admitted. Else reader splits it into words, as Architect ruled on #811: 4.1 says sounds
##     of stream split one way alone, and 3.3 lets correct text leave period out.
##     Split chosen needs fewest pauses that rules need and text does not write, so period left
##       out is inferred only where letters read no other way: `losei` reads as `lo sei`, never
##       as `lo se .i`.
##     Several splits of fewest pauses tie, as `iai` for `.i.ai` or `.ia.i`, and reader refuses
##       them as `Split`; written word with no split is refused as `readWord` refuses letters.
##     Stress takes part, as in speech: capitals must fit each word, so `KLAmaku` reads as
##       `klama ku`, and `klamaku` as one fu'ivla, stressed on its penultimate syllable.
##     Comma changes no word: no two words "differ solely because of" comma (3.3). So letters
##       and capitals choose words, comma left out, where they read. Comma marks "no pause
##       between" syllables (3.3), so no split takes pause where it stands: `ka,i` is `kai`
##       with comma refused, never `ka .i`. Each comma is then judged against words chosen,
##       and one parting stress off them is refused, as `crarcI,ae` is.
##       Only where words read no other way does comma part syllables, as grouping of vowels
##       needs it (3.5): `.nu,IORK.` of Example 5.65 is one cmene stressed on `io`, and
##       `.nuIORK.` is `nu .iork.`.
##     Cmene stands last in written word: pause follows it (4.9 rule 2), and parts of name join
##       into one word with no pause (4.8), so consonant inside written word goes on with name.
##       So `bri` is no `br .i`, though `br` alone would read as cmene, as `rl` does (3.4); and
##       `secusku` is `se cusku`, never `secusk .u`.
##     Cost: CLL presents no algorithm for split (4.1), so split is reader's, built from rules
##       of 3.9, 4.2, 4.7, 4.8 and 4.9. It tries each word and each word before it, so time grows
##       with cube of length of written word (expected); words written apart skip it.
##   Pause follows 4.9. Period writes it. Where rule needs pause that text does not write,
##     reader infers it, since 3.3 calls period optional reminder that correct text implies.
##     So no text is refused for unwritten pause, and each word carries pause before it.
##     Rules read: 2, word ending in consonant; 3, word opening with vowel or `y`; 4, cmene
##       after word other than `la`, `lai`, `la'i` or `doi`; 5 and 4.2, stressed last syllable
##       before brivla or before stressed first syllable; 6, `Cy` before word not `Cy`; and
##       pause after `y` (4.2). First word takes pause where rule 3 or 4 needs one.
##     Rule 7 holds text that `zoi` and `la'o` quote, which #814 reads; reader refuses it as gap.
##   Comma is never required (3.3), so word reads without it. Comma breaks syllables, so each
##     stretch it bounds, up to next comma, apostrophe or edge of word, holds vowel, `y`, or
##     consonant that may be syllabic (3.4). In cmavo, gismu and lujvo, vowels side by side make
##     diphthong, which is one syllable (3.4), so comma between them is refused; cmene and
##     fu'ivla may part vowels with it (3.5, 4.7).
##     Cost: comma beside `l`, `m`, `n` or `r` may make it syllabic, which 3.4 admits in
##       principle, so reader accepts it.
##   Capital marks stress (3.1, 3.9): capitals form one run touching one vowel or diphthong,
##     whole syllable or vowel alone, and consonants of run are not judged. Brivla stresses
##     penultimate syllable, `y` and syllabic consonant not counted; cmavo and cmene any syllable
##     or none; `y` never. Capital touching no vowel is refused, as sentence opening `Mi` is:
##     4.8 keeps capitals for stress alone.
##   Place of each word and refusal is byte of stream where it opens, so caller can point at it.

{.experimental: "strictFuncs".}

import std/[algorithm, options, sequtils, strutils]

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
      ##   word, commas parting them; none where text marks none.
    breaks*: seq[int]  ## Index of letter of word each comma stands before, in order (3.3).
    reading*: Reading  ## Word as `readWord` reads `text`.

  ReadingStream* = object  ## Define outcome of reading stream as its words.
    case is_read*: bool
    of true:
      occurrences*: seq[Occurrence]  ## Words of stream in order; empty for marks alone.
    of false:
      refusal*: Refusal  ## Rule refusing stream, or gap holding it.
      start*: int  ## Byte of stream where offending word or mark opens.
      detail*: string  ## Offending character, form 4.11 gives, or two splits; empty otherwise.

  Spelling = object  ## Define written word with its marks taken out.
    letters: string  ## Letters in canonical form.
    places: seq[int]  ## Byte of stream each letter stands at.
    capitals: seq[int]  ## Index of each letter written capital, in order.
    breaks: seq[int]  ## Index of letter each comma stands before, in order.
    commas: seq[int]  ## Byte of stream each comma stands at, in order of `breaks`.

  Score = object  ## Define splits reaching word: fewest pauses, ties, and words before.
    pauses: int  ## Fewest pauses of any split reaching word.
    ties: int  ## Splits of fewest pauses reaching word, two standing for more.
    befores: seq[int]  ## Start of word before, in each split of fewest pauses; none for first.

  Split = object  ## Define split of written word into words with fewest pauses it needs.
    splits: seq[seq[Occurrence]]  ## Up to two splits of fewest pauses, in order; pause unset.
    count: int  ## Splits of fewest pauses: none, one, or two standing for two or more.


const
  MARKS_BOUNDARY = Whitespace + {'.'}  ## Marks dividing words: whitespace, and period (3.3).
  CAPITALS = MARKS_STREAM - MARKS_BOUNDARY - {','}  ## Capital of each letter, marking stress.
  VOWELS_NUCLEUS = VOWELS + {'y'}  ## Letters making syllable: five vowels, and `y` (3.4, 3.9).
  CONSONANTS_SYLLABIC = {'l', 'm', 'n', 'r'}  ## Consonants that may make syllable alone (3.4).
  KINDS_BRIVLA = {Kind.Gismu, Kind.Lujvo, Kind.Fuhivla}
    ## Classes stressed on penultimate syllable alone (3.9, 4.7).
  KINDS_DIPHTHONG = {Kind.Cmavo, Kind.Gismu, Kind.Lujvo}
    ## Classes whose vowels side by side make diphthong, so comma may not part them (3.4).


func refuse(refusal: Refusal, start: int, detail = ""): ReadingStream =
  ## Build reading that refuses stream at byte `start`.
  ReadingStream(is_read: false, refusal: refusal, start: start, detail: detail)


func isPauseNeeded(prior, next: Occurrence): bool =
  ## Test rule of 4.9 needs pause between two words: rules by letters (`forms.nim`), and rule 5,
  ##   stressed last syllable before brivla or before stressed first syllable (4.2).
  if isPauseNeeded(prior.text, next.text): return true
  if prior.stress != some(prior.text.nuclei(prior.reading.kind, prior.breaks).high): return false
  next.reading.kind in KINDS_BRIVLA or next.stress == some(0)  # rule 5; 4.2


func isPauseNeededFirst(word: Occurrence): bool =
  ## Test rule of 4.9 needs pause before word opening stream: rule 3, vowel or `y` first (4.2),
  ##   or rule 4, cmene.
  word.text[0] in VOWELS_NUCLEUS or word.reading.kind == Kind.Cmene


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
  let spans = word.nuclei(kind, breaks)
  var touched: seq[int]
  for i, nucleus in spans:
    if nucleus.b >= first and nucleus.a <= last: touched.add i
  if touched.len != 1 or word[spans[touched[0]].a] == 'y': return  # 3.9, `y` never stressed
  if kind in KINDS_BRIVLA:
    var counted: seq[int]
    for i, nucleus in spans:
      if word[nucleus.a] != 'y': counted.add i
    if touched[0] != counted[^2]: return  # 3.9, brivla stresses penultimate; two at least (4.3)
  some(touched[0])


func occurrenceWritten(
    spelling: Spelling, span: Slice[int], is_parting = true
): Option[Occurrence] =
  ## Read letters of `span` as one word, with stress its capitals mark; none where no word
  ##   reads, or where its capitals break rule of 3.9. Commas part syllables where
  ##   `is_parting`, and judge no word otherwise; pause left unset.
  let
    piece = spelling.letters[span]
    reading = piece.readWord
  if not reading.is_word: return

  # Read stress capitals mark, commas inside breaking run, and refuse stress 3.9 does not admit.
  var capitals, breaks: seq[int]
  for b in spelling.breaks:
    if is_parting and b > span.a and b <= span.b: breaks.add b - span.a
  for c in spelling.capitals:
    if c in span: capitals.add c - span.a
  var stress = none(int)
  if capitals.len > 0:
    stress = piece.nucleusStressed(reading.kind, capitals, breaks)
    if stress.isNone: return
  some(Occurrence(
    start: spelling.places[span.a], text: piece, stress: stress, breaks: breaks, reading: reading,
  ))


func splitWritten(spelling: Spelling, is_parting: bool): Split =
  ## Split written word into words with fewest pauses that rules need and text does not write
  ##   (3.3, 4.9), and none where comma stands; count splits of fewest pauses, two standing for
  ##   more. Commas part syllables where `is_parting`.
  ##   `words[j][i]` holds word of letters `j ..< i`, and `scores[j][i]` splits ending in it.
  let n = spelling.letters.len
  var
    words = newSeqWith(n + 1, newSeq[Option[Occurrence]](n + 1))
    scores = newSeqWith(n + 1, newSeq[Option[Score]](n + 1))

  # Score each word by fewest pauses of splits reaching it, counting ties.
  for i in 1 .. n:
    for j in 0 ..< i:
      let word = spelling.occurrenceWritten(j .. i - 1, is_parting)
      if word.isNone: continue
      if word.get.reading.kind == Kind.Cmene and i < n: continue  # 4.8, cmene stands last
      words[j][i] = word
      if j == 0:
        scores[j][i] = some(Score(pauses: 0, ties: 1))
        continue
      let is_comma = j in spelling.breaks
      for k in 0 ..< j:
        if scores[k][j].isNone: continue
        let is_needed = isPauseNeeded(words[k][j].get, word.get)
        if is_needed and is_comma: continue  # 3.3, comma marks "no pause between" syllables
        let
          score = scores[k][j].get
          pauses = score.pauses + ord(is_needed)
        if scores[j][i].isNone or pauses < scores[j][i].get.pauses:
          scores[j][i] = some(Score(pauses: pauses, ties: score.ties, befores: @[k]))
        elif pauses == scores[j][i].get.pauses:
          scores[j][i].get.ties = min(2, scores[j][i].get.ties + score.ties)
          scores[j][i].get.befores.add k

  # Choose fewest pauses over words ending written word, and count ties.
  var lasts: seq[int]
  for j in 1 ..< n:
    if scores[j][n].isNone: continue
    let score = scores[j][n].get
    if lasts.len == 0 or score.pauses < scores[lasts[0]][n].get.pauses:
      lasts = @[j]
      result.count = score.ties
    elif score.pauses == scores[lasts[0]][n].get.pauses:
      lasts.add j
      result.count = min(2, result.count + score.ties)

  # Read up to two splits of fewest pauses back, from last word, by each word before it.
  var paths = lasts.mapIt(@[(it, n)])
  while paths.len > 0 and result.splits.len < 2:
    let
      path = paths.pop
      (start, finish) = path[^1]
    if start == 0:
      result.splits.add path.reversed.mapIt(words[it[0]][it[1]].get)
      continue
    for before in scores[start][finish].get.befores.reversed:
      paths.add path & (before, start)


func splitChosen(spelling: Spelling, is_parting: bool): Split =
  ## Choose words of written word: one word where letters read whole, else splits of fewest
  ##   pauses; commas part syllables where `is_parting`.
  let whole = spelling.occurrenceWritten(0 .. spelling.letters.high, is_parting)
  if whole.isSome: return Split(splits: @[@[whole.get]], count: 1)
  spelling.splitWritten(is_parting)


func refusalWritten(spelling: Spelling, start: int): ReadingStream =
  ## Refuse written word that splits into no words, at byte `start`: at first comma where words
  ##   its letters read take pause, since comma marks none (3.3); else as `readWord` refuses its
  ##   letters; else at its first capital, which breaks rule of 3.9. Letters that split into
  ##   cmavo split here too, so comma or capital alone stops them.
  var bare = spelling
  (bare.breaks, bare.commas) = (newSeq[int](), newSeq[int]())
  let split = bare.splitChosen(is_parting = false)
  if split.count > 0:
    var lo = 0
    for i, word in split.splits[0]:
      let k = spelling.breaks.find(lo)
      if i > 0 and k >= 0 and isPauseNeeded(split.splits[0][i - 1], word):
        return refuse(Refusal.Comma, spelling.commas[k])  # 3.3, comma "cannot be" pause
      lo += word.text.len
  let whole = spelling.letters.readWord
  if not whole.is_word and whole.refusal != Refusal.Stream:
    return refuse(whole.refusal, start, whole.detail)
  doAssert spelling.capitals.len > 0, "Written word whose letters read should break 3.9 by capital."
  refuse(Refusal.Stress, spelling.places[spelling.capitals[0]])  # 3.9


func refusalCommas(spelling: Spelling, words: openArray[Occurrence]): Option[ReadingStream] =
  ## Find first comma that breaks rule against words written word holds, as refusal at its
  ##   byte: comma inside diphthong of cmavo, gismu or lujvo (3.4), or where pause must stand
  ##   between two words, since comma "cannot be pronounced as pause" (3.3).
  var
    lo = 0
    k = 0
  for i, word in words:
    let hi = lo + word.text.len
    while k < spelling.breaks.len and spelling.breaks[k] < hi:
      let
        b = spelling.breaks[k] - lo
        is_broken =
          if b == 0: isPauseNeeded(words[i - 1], word)
          else: word.text[b - 1] in VOWELS_NUCLEUS and word.text[b] in VOWELS_NUCLEUS and
              word.reading.kind in KINDS_DIPHTHONG
      if is_broken: return some(refuse(Refusal.Comma, spelling.commas[k]))
      inc k
    lo = hi
  none(ReadingStream)


func pauseBefore(occurrences: openArray[Occurrence], word: Occurrence, is_period: bool): Pause =
  ## Name pause before word that follows `occurrences`: period writes it, or rule needs it.
  if is_period: return Pause.Written
  let is_needed =
    if occurrences.len == 0: word.isPauseNeededFirst else: isPauseNeeded(occurrences[^1], word)
  if is_needed: Pause.Inferred else: Pause.Absent


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

    # Choose words that fit every mark: comma parts syllables, as 3.5 groups vowels by it, so
    #   capitals stress syllables it marks; and no split takes pause where comma stands (3.3).
    let
      spelling = text.toSpelling(start, at)
      split = spelling.splitChosen(is_parting = true)
    if split.count == 0: return spelling.refusalWritten(start)
    if split.count > 1:
      let detail = split.splits.mapIt(it.mapIt(it.text).join(" ")).join(", or ")
      return refuse(Refusal.Split, start, detail)  # 3.3, no one split to infer
    let
      words = split.splits[0]
      refusal_commas = spelling.refusalCommas(words)
    if refusal_commas.isSome: return refusal_commas.get

    # Stop at quotation of text that is not lojban, gap of #814; add each word with its pause.
    for i, word in words:
      if word.reading.selmaho == some(Selmaho.Zoi): return refuse(Refusal.Foreign, word.start)
      var occurrence = word
      occurrence.pause = occurrences.pauseBefore(occurrence, is_period = i == 0 and is_period)
      occurrences.add occurrence
    is_period = false
  ReadingStream(is_read: true, occurrences: occurrences)
