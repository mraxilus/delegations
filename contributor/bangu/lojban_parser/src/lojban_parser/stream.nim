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
##     Stress takes part, as in speech. Written word with no capital is stressed on its own
##       penultimate syllable alone, and one with capitals on each syllable they mark, as
##       Architect ruled (`D3 a` on #811). So each brivla holds capital, or ends syllables counted
##       for stress: `mibroda` reads as `mi broda`, `MIbroda` as `mibro da`, `.esperanto` as
##       `e speranto` (Example 19.78), and `klamaku` as one fu'ivla.
##     Comma parts syllables, as 3.5 groups vowels by it, so capitals stress syllables it marks:
##       `me,IIn.` is one cmene stressed on `ii`. Comma marks "no pause between" syllables
##       (3.3), so no split takes pause where it stands: `ka,i` is `kai` with comma refused,
##       never `ka .i`. Each comma is then judged against words chosen.
##       Cost: comma under capital may make written word split, as `crarcI,ae` reads
##         `crarcia e` where `crarcIae` reads `crarciae`; with no capital, comma changes no word.
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
##     Rule 7 sets pause on each side of text that `zoi` and `la'o` quote. Reader holds that
##       text whole as one occurrence, `Foreign`, up to written word spelling delimiter again;
##       text holding delimiter is refused as `Quotation`, since delimiter is "not found" in it
##       (19.10), so `zoi gy. gyrations .gy.` is refused, as Example 19.50 is as written.
##   Quotation `zo` makes, or `lo'u` up to `le'u`, quotes words, so `zoi` and `fa'o` inside it
##     act on none (19.9, 19.10). Stream stops after `fa'o` no quotation holds (19.15).
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
      refusal*: Refusal  ## Rule refusing stream.
      start*: int  ## Byte of stream where offending word or mark opens.
      detail*: string
        ## Offending character, form 4.11 gives, or two splits; delimiter of `zoi` that no word
        ##   spelling it closes, which live text waits for; empty otherwise.

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
  MARKS_BOUNDARY* = Whitespace + {'.'}  ## Marks dividing words: whitespace, and period (3.3).
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

  # Written word with capitals marks each stress with them; one with none stresses its own
  #   penultimate syllable alone (`D3 a` on #811). So brivla holds capital, or no vowel counted
  #   for stress follows it in written word.
  if reading.kind in KINDS_BRIVLA:
    if spelling.capitals.len > 0 and stress.isNone: return
    if spelling.capitals.len == 0 and spelling.letters[span.b + 1 .. ^1].anyIt(it in VOWELS): return
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


func isForeign(word: Occurrence): bool =
  ## Test occurrence holds text that `zoi` or `la'o` quotes, which is no lojban (4.9 rule 7).
  not word.reading.is_word and word.reading.refusal == Refusal.Foreign


func pauseBefore(occurrences: openArray[Occurrence], word: Occurrence, is_period: bool): Pause =
  ## Name pause before word that follows `occurrences`: period writes it, or rule needs it.
  ##   Pause stands on each side of text quoted that is no lojban (4.9 rule 7).
  if is_period: return Pause.Written
  let is_needed =
    if occurrences.len == 0: word.isPauseNeededFirst
    elif occurrences[^1].isForeign or word.isForeign: true
    else: isPauseNeeded(occurrences[^1], word)
  if is_needed: Pause.Inferred else: Pause.Absent


func wordsWritten(text: string, start, finish: int): ReadingStream =
  ## Read written word of bytes `start ..< finish` as its words, pause left unset; refuse mark,
  ##   letters or split no rule admits.
  let refusal_marks = text.refusalMarks(start, finish)
  if refusal_marks.isSome: return refusal_marks.get

  # Choose words that fit every mark: comma parts syllables, as 3.5 groups vowels by it, so
  #   capitals stress syllables it marks; and no split takes pause where comma stands (3.3).
  let
    spelling = text.toSpelling(start, finish)
    split = spelling.splitChosen(is_parting = true)
  if split.count == 0: return spelling.refusalWritten(start)
  if split.count > 1:
    let detail = split.splits.mapIt(it.mapIt(it.text).join(" ")).join(", or ")
    return refuse(Refusal.Split, start, detail)  # 3.3, no one split to infer
  let refusal_commas = spelling.refusalCommas(split.splits[0])
  if refusal_commas.isSome: return refusal_commas.get
  ReadingStream(is_read: true, occurrences: split.splits[0])


func quoted(text: string, start: int, delimiter: string): Option[Slice[int]] =
  ## Find bytes of text quoted from `start` up to next written word spelling `delimiter`, marks
  ##   around it left out; none where no such word follows (19.10).
  var at = start
  while at < text.len:
    if text[at] in MARKS_BOUNDARY:
      inc at
      continue
    let first = at
    while at < text.len and text[at] notin MARKS_BOUNDARY: inc at
    if text[first ..< at].toLowerAscii.replace(",", "") != delimiter: continue
    var (a, b) = (start, first - 1)
    while a <= b and text[a] in MARKS_BOUNDARY: inc a
    while b >= a and text[b] in MARKS_BOUNDARY: dec b
    return some(a .. b)
  none(Slice[int])


func readStream*(text: string): ReadingStream =
  ## Read text as its words by rules of CLL alone, each with pause before it and stress it
  ##   marks; refuse at first word or mark that no rule admits, naming its byte.
  ##   Text `zoi` or `la'o` quotes stands as one occurrence, whole and as written; quotation
  ##     `zo` makes, or `lo'u` up to `le'u`, quotes words, so their cmavo act on none (19.9).
  ##   Stream stops after `fa'o` that no quotation holds, which ends parsable input (21.1).
  var
    occurrences: seq[Occurrence]
    is_period, is_quoting, is_lohu = false
    zoi, closing = none(int)  # quotation whose delimiter comes next; delimiter closing text
    at = 0
  while at < text.len:
    # Pass marks between words, noting period.
    if text[at] in MARKS_BOUNDARY:
      is_period = is_period or text[at] == '.'
      inc at
      continue

    # Take written word up to next mark between words, and read its words.
    let start = at
    while at < text.len and text[at] notin MARKS_BOUNDARY: inc at
    let written = text.wordsWritten(start, at)
    if not written.is_read: return written
    let words = written.occurrences

    # Read delimiter closing text quoted: that written word alone, spelled as delimiter (19.10).
    if closing.isSome:
      if words.len != 1 or words[0].text != occurrences[closing.get].text:
        return refuse(Refusal.Quotation, start)
      var occurrence = words[0]
      occurrence.pause = (if is_period: Pause.Written else: Pause.Inferred)  # 4.9 rule 7
      occurrences.add occurrence
      (closing, is_period) = (none(int), false)
      continue

    # Add each word with its pause, and follow quotation it opens or closes.
    for i, word in words:
      var occurrence = word
      occurrence.pause = occurrences.pauseBefore(occurrence, is_period = i == 0 and is_period)
      occurrences.add occurrence

      # Delimiter ends its written word, and text it quotes runs to it again (19.10).
      if zoi.isSome:
        if i < words.high: return refuse(Refusal.Quotation, words[i + 1].start)
        let span = text.quoted(at, word.text)
        if span.isNone: return refuse(Refusal.Quotation, occurrences[zoi.get].start, word.text)
        let quotation = text[span.get]
        if word.text in quotation.toLowerAscii:
          return refuse(Refusal.Quotation, span.get.a)  # 19.10, delimiter "not found" in text
        occurrences.add Occurrence(
          start: span.get.a, text: quotation, stress: none(int),
          pause: (if '.' in text[at ..< span.get.a]: Pause.Written else: Pause.Inferred),
          reading: Reading(is_word: false, refusal: Refusal.Foreign),
        )
        (zoi, closing, at) = (none(int), some(occurrences.high - 1), span.get.b + 1)
        break

      # Word after `zo` is quoted; `lo'u` quotes words up to `le'u`, but `zo le'u` (19.9).
      if is_quoting:
        is_quoting = false
        continue
      let selmaho = word.reading.selmaho
      if is_lohu:
        if selmaho == some(Selmaho.Zo): is_quoting = true
        elif selmaho == some(Selmaho.Lehu): is_lohu = false
        continue
      if selmaho == some(Selmaho.Zo): is_quoting = true
      elif selmaho == some(Selmaho.Lohu): is_lohu = true
      elif selmaho == some(Selmaho.Zoi): zoi = some(occurrences.high)
      elif selmaho == some(Selmaho.Faho):
        return ReadingStream(is_read: true, occurrences: occurrences)  # 19.15, end of input
    is_period = false
  if zoi.isSome: return refuse(Refusal.Quotation, occurrences[zoi.get].start)  # 19.10, no delimiter
  ReadingStream(is_read: true, occurrences: occurrences)
