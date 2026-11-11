## Read lojban prose: words of stream, rules of CLL that act on words before grammar, then
##   grammar of 21.1 over terminals they leave.
##
##   |----------------|-------------------------------------------------------------------|
##   | Code           | Meaning                                                           |
##   |----------------|-------------------------------------------------------------------|
##   | Unit           | words one terminal of grammar holds, or words stage refuses       |
##   | RefusalText    | rule refusing text: stream, selma'o, quotation, construct, grammar |
##   | ReadingText    | tree of text over its units, or refusal with its place            |
##   | ReadingMarked  | tree of text that marks each error, over every unit               |
##   | readText       | read text by stream, rules of 19.16, and grammar of 21.1          |
##   | readTextMarked | read text as `readText` does, and read on past each error         |
##   |----------------|-------------------------------------------------------------------|
##
##   Order follows what 19.16 says each cmavo does not affect: quotation first, then `fa'o`,
##     then erasure, then `zei` and BAhE, then `bu`, then indicators. CLL gives no full order.
##   Quotation: `zo` quotes next word, whatever it is (19.10); `lo'u` quotes words up to
##     `le'u` that no `zo` quotes (19.9); `readStream` holds text `zoi` and `la'o` quote. Each
##     stands as one terminal, as rewrites of `grammar.nim` give.
##   `fa'o` ends parsable input unless quoted (19.15, 21.1); `readStream` stops after it, and
##     it stands in no terminal.
##   Erasure acts on words, each quotation counted by its words: `zo` quotation is two, `zoi`
##     quotation four (19.13, Examples 19.77, 19.79). `si` erases word before it. `sa` erases
##     back to and including last word of selma'o of word after it, or back to start of text
##     where none stands, as Example 19.81 erases back to start for `.i` of no earlier sentence.
##     `su` erases every word before it, so `readText` reads words after last `su` alone, as CLL
##       reads text. Reading that marks each error keeps text before it, as it read before `su`
##       came, so live text cuts back nowhere (ruling on #859): `su` ends that text, and stands
##       as unit of its own, stage `Su`, before text after it, which reads alone. Program that
##       reads text as CLL does drops each node before last `su`.
##     Erasure leaving part of quotation is refused, as 19.80 says parser rejects
##       `zo .djan. si .djordj.`: quotation is read before erasure, never again after it.
##     Cost: 21.1 rule 1101 and chapter 20 give `sa` scope of utterance and `su` of text;
##       reader takes words 19.13 describes, one speaker writing whole text.
##   `zei` joins word before it and word after it into one terminal (4.6), and chain of them
##     into one; neither word may be cmavo 19.16 says `zei` does not affect.
##   BAhE, one or more, marks next word (rule 1100); `bu`, one or more, makes word before it
##     lerfu word (17.4). Indicator marks word before it (13.9, rule 1100): UI or CAI with `nai`
##     after it, `y`, `da'o`, `fu'e` and `fu'o`. Indicators opening text stand as terminals,
##     which rule 0 reads.
##   Refusal names byte where reading stops: word refused, or start of unit grammar stops at,
##     or end of input: `fa'o` that ends it, else byte past text. So text after `fa'o` moves no
##     byte that reading names, as live text holds once `fa'o` reads.
##   Marks (#859): `readTextMarked` reads on past each error, so other program mends text by
##     its tree, whose words that read keep their trees; this parser decides no mend.
##     Words stage refuses stand as unit no terminal holds, with that stage, and grammar reads
##       terminals around them: written word stream refuses, as written; words rule of 19.16
##       refuses, as quotation erasure leaves in part, or `zei` joining nothing; and cmavo no
##       list gives selma'o, with words marking it. `lo'u` no `le'u` closes stands alone, and
##       words after it read on, as words after `zoi` with no delimiter do.
##     Words no stage reads stand as unit too, so each byte of each word lies in one leaf: each
##       run erasure erases, with `si` or `sa` erasing it, as unit of stage `Erasure`; `fa'o` that
##       ends input as unit of stage `Faho`, and each written word after it as unit of stage
##       `Stream`, refusal `Faho`, as written. Those stand last in root, past text.
##     Unit refused stands as leaf in lowest node holding both units read around it, between
##       them, or in root at end of text: no rule of 21.1 holds it, so its place is no claim of
##       rule it would take.
##     Grammar marks where it stops by error node (`grammar.nim`).
##     Cost: each written word stream refuses reads stream again, so time grows with product of
##       their count and length of text; each set of words rule refuses reads rules again.

{.experimental: "strictFuncs".}

import std/[algorithm, options, sequtils]

import ./[grammar, selmaho, stream, tanru]


type
  RefusalText* {.pure.} = enum  ## Define why prose is refused, or why unit stands in no terminal.
    Stream  ## Stream refuses text; `rule` names its refusal.
    Selmaho  ## Cmavo no list gives selma'o, so grammar reads no terminal (ch. 20).
    Quotation  ## `zo` quoting nothing, `lo'u` never closed or quoting nothing, or erasure
                ##   leaving part of quotation (19.9, 19.10, 19.13).
    Construct  ## `si` or `sa` with nothing to erase, or `zei`, BAhE or `bu` with no word
               ##   to act on (19.13, 4.6, 17.4).
    Grammar  ## Grammar of 21.1 refuses terminals; `rule` names rule stopping there.
    Su  ## No refusal: `su` ending text before it, which reading that marks each error keeps.
    Erasure  ## No refusal: words erasure erases, and `si` or `sa` erasing them (19.13).
    Faho  ## No refusal: `fa'o` ending input (19.15).

  Unit* = object
    ## Define words one terminal of grammar holds, one word or construct of 19.16; or words
    ##   stage refuses, which no terminal holds (#859).
    words*: seq[int]  ## Index of each occurrence unit holds, in order; erased words left out.
    case is_read*: bool
    of true:
      terminal*: Terminal
    of false:
      refusal*: RefusalText
        ## Stage refusing words, which no terminal holds, and grammar reads around them
        ##   (`readTextMarked`): stream, selma'o, quotation or construct; or stage that leaves
        ##   words out of every terminal: `su`, erasure, or `fa'o`.

  ReadingText* = object  ## Define outcome of reading prose.
    case is_read*: bool
    of true:
      occurrences*: seq[Occurrence]  ## Words of stream in order, erased words and `fa'o` among.
      units*: seq[Unit]  ## Terminals of grammar in order, with words each holds.
      tree*: Node  ## Tree of text; each terminal of it indexes `units`.
    of false:
      refusal*: RefusalText
      start*: int  ## Byte of text where reading stops.
      rule*: string  ## Refusal of stream, or rule of grammar, as `sumti-6 97`; empty otherwise.

  ReadingMarked* = object  ## Define reading of prose that marks each error, and holds tree still.
    occurrences*: seq[Occurrence]
      ## Words of stream in order, erased words and `fa'o` among; and each written word stream
      ##   refuses, as written, whose reading names refusal of stream.
    units*: seq[Unit]  ## Units in order of first word, each read or refused.
    tree*: Node
      ## Tree of text, error node where grammar stops (`readGrammarMarked`); each leaf indexes
      ##   `units`, and place grammar stops at indexes them too, count of them where text ends.
    size*: int  ## Bytes of text, which names place where text ends.

  ReadingParts* = object
    ## Define reading of text as its parts, and what live text reads past them: erasure that
    ##   reaches before text, and quotation that waits for its closer (`readTextParts`).
    reading*: ReadingMarked
      ## Reading whose root holds node of each part (`readGrammarParts`), and each unit refused
      ##   between parts, in order, `su` among them; each part reads alone.
    open*: seq[int]  ## Unit of each `tu'e`, `lu` or `to` that waits for its closer.
    zois*: seq[tuple[start: int, delimiter: string]]
      ## Byte of written word of each `zoi` that no delimiter closes, with that delimiter.
    lohus*: seq[int]
      ## Byte of each `lo'u` whose words stream reads to end of text: no `zo` quotes it, and no
      ##   `le'u` closes it, as stream reads them, whatever unit rules give it. So text after it
      ##   reads as stream reads it, inside words it quotes, though erasure erases its `le'u`, or
      ##   rules read it as text `la'o` quotes.
    markers*: seq[Option[Terminal]]
      ## Marker of each `sa` before first `su` that finds none, in any pass of rules of 19.16,
      ##   so erases to start.
    faho*: Option[int]
      ## Unit of `fa'o` that ends input (19.15): it and each unit after it, of written word stream
      ##   reads not, stand last in root, past text; none where none.
    quoted*: seq[int]
      ## Byte of each `su` that quotation holds in first pass of rules of 19.16, which erasure
      ##   left in part, so pass refused it: erasure after `su` that erases rest of it makes first
      ##   pass read, and quote `su` again, as `zo su si si` does (19.13).

  Role {.pure.} = enum  ## Define part word takes in quotation, or none (19.9, 19.10).
    Plain  ## Word acting as itself.
    Zo  ## `zo` quoting next word.
    Quoted  ## Word `zo` quotes.
    Lohu  ## `lo'u` opening quotation of words.
    Inner  ## Word between `lo'u` and `le'u`.
    Lehu  ## `le'u` closing it.
    Zoi  ## `zoi` or `la'o` opening quotation of text.
    Delimiter  ## Word delimiting text quoted, before it or after it.
    Foreign  ## Text `zoi` or `la'o` quotes.

  Piece = object  ## Define unit under construction, and what it holds.
    words: seq[int]
    head: int  ## Occurrence whose terminal piece takes, for word alone.
    terminal: Option[Terminal]  ## Terminal of construct; none for word alone.
    is_plain: bool  ## Piece is one plain word, which construct may still act on.

  Reach = object  ## Define what erasure reaches before start of words, which live text reads.
    markers: seq[Option[Terminal]]
      ## Marker of each `sa` before first `su` that finds none, so erases to start.


const
  SELMAHO_INDICATORS = {
    Selmaho.Ui, Selmaho.Cai, Selmaho.Y, Selmaho.Daho, Selmaho.Fuho, Selmaho.Fuhe,
  }
    ## Selma'o of indicator marking word before it (13.9, 19.16).
  SELMAHO_UNJOINED = {
    Selmaho.Zo, Selmaho.Si, Selmaho.Sa, Selmaho.Su, Selmaho.Lohu, Selmaho.Zoi, Selmaho.Faho,
    Selmaho.Zei,
  }
    ## Selma'o of cmavo `zei` does not affect (19.16).
  SELMAHO_UNLETTERED = SELMAHO_UNJOINED + {Selmaho.Bahe, Selmaho.Bu}
    ## Selma'o of cmavo `bu` makes no lerfu word (17.4, 19.16).


func refuse(refusal: RefusalText, start: int, rule = ""): ReadingText =
  ## Build reading that refuses prose at byte `start`.
  ReadingText(is_read: false, refusal: refusal, start: start, rule: rule)


func toSelmaho(word: Occurrence): Option[Selmaho] =
  ## Give selma'o of cmavo word; none for other word, and for text quoted.
  if word.reading.is_word: word.reading.selmaho else: none(Selmaho)


func isSelmaho(word: Occurrence, selmaho: set[Selmaho]): bool =
  ## Test word is cmavo of one of `selmaho`.
  let own = word.toSelmaho
  own.isSome and own.get in selmaho



#[ Quotation and erasure ]#

func isClosingLohu*(words: openArray[Occurrence]): bool =
  ## Test words hold `le'u` that no `zo` quotes, which closes `lo'u` before them, as stream reads
  ##   words `lo'u` quotes (19.9).
  var is_quoting = false
  for k in 0 ..< words.len:
    template word: untyped = words[k]
      ## Alias word, which `let` would copy.
    if not word.reading.is_word: continue
    if is_quoting:
      is_quoting = false
      continue
    if word.isSelmaho({Selmaho.Zo}): is_quoting = true
    elif word.isSelmaho({Selmaho.Lehu}): return true
  false


func toRoles(words: openArray[Occurrence], is_lohu = false): seq[Role] =
  ## Give part each word takes in quotation: `zo` quotes next word, `lo'u` words up to `le'u`
  ##   no `zo` quotes, and `zoi` its delimiter, text and delimiter, as `readStream` holds them.
  ##   `zo` ending text quotes no word, and `quotations` refuses it (19.10). With `is_lohu`,
  ##   words open inside words `lo'u` quotes, as `readStream` reads them.
  result = newSeq[Role](words.len)
  var
    i = 0
    is_lohu = is_lohu  # words `lo'u` quotes, up to `le'u`
  while i < words.len:
    if words[i].isSelmaho({Selmaho.Zo}):
      result[i] = (if is_lohu: Role.Inner else: Role.Zo)
      if i + 1 < words.len: result[i + 1] = (if is_lohu: Role.Inner else: Role.Quoted)
      i += 2
      continue
    if is_lohu:
      result[i] = (if words[i].isSelmaho({Selmaho.Lehu}): Role.Lehu else: Role.Inner)
      is_lohu = result[i] == Role.Inner
    elif words[i].isSelmaho({Selmaho.Lohu}):
      (result[i], is_lohu) = (Role.Lohu, true)
    elif words[i].isSelmaho({Selmaho.Zoi}) and i + 3 < words.len:
      for k, role in [Role.Zoi, Role.Delimiter, Role.Foreign, Role.Delimiter]: result[i + k] = role
      i += 4
      continue
    inc i


func erased(
    words: openArray[Occurrence], roles: openArray[Role], offender: var seq[int],
    reach: var Reach, as_parting: bool,
): Option[seq[int]] =
  ## Keep words erasure leaves, by index (19.13): `si` erases word before it, `sa` back to last
  ##   word of selma'o of word after it or to start, `su` every word before it; cmavo
  ##   quotation holds erase nothing. None where `si` or `sa` has nothing to act on, which
  ##   `offender` then names. `reach` names each `sa` before first `su` that erases to start.
  ##   With `as_parting`, `su` stays as word kept, which ends text before it, so erasure after it
  ##     reaches no word before it (ruling on #859).
  reach = Reach()
  var
    kept: seq[int]
    floor = 0  # words kept before it stand before last `su`, which erasure reaches not
  for i, word in words:
    if roles[i] != Role.Plain or not word.isSelmaho({Selmaho.Si, Selmaho.Sa, Selmaho.Su}):
      kept.add i
      continue
    case word.toSelmaho.get
    of Selmaho.Si:
      if kept.len == floor:
        offender = @[i]
        return none(seq[int])
      kept.setLen(kept.len - 1)
    of Selmaho.Sa:
      if i + 1 >= words.len:
        offender = @[i]
        return none(seq[int])
      let
        marker = words[i + 1].reading.toTerminal
        last = toSeq(floor ..< kept.len).filterIt(words[kept[it]].reading.toTerminal == marker)
      if last.len == 0 and floor == 0: reach.markers.add marker
      kept.setLen(if last.len > 0: last[^1] else: floor)
    else:
      if as_parting: kept.add i
      else: kept.setLen(0)
      floor = kept.len
  some(kept)


func quotations(
    words: openArray[Occurrence], roles: openArray[Role], kept: openArray[int],
    offender: var seq[int],
): Option[seq[Piece]] =
  ## Group words kept into pieces: each quotation whole, as one terminal, and each other word
  ##   alone; none where erasure leaves part of quotation, or `lo'u` quotes no word (19.80).
  ##   `offender` then names words of that quotation kept: erasure leaves its first words. Of
  ##     `lo'u` that no `le'u` closes, it names `lo'u` alone, so words after it read on, as words
  ##     after `zoi` with no delimiter do: in live text, it holds no word of hours after it.
  var
    pieces: seq[Piece]
    p = 0
  while p < kept.len:
    let i = kept[p]
    case roles[i]
    of Role.Plain:
      pieces.add Piece(words: @[i], head: i, is_plain: true)
      inc p
    of Role.Zo, Role.Zoi:
      let size = (if roles[i] == Role.Zo: 2 else: 4)
      if p + size > kept.len or kept[p + size - 1] != i + size - 1:
        var q = p + 1
        while q < min(kept.len, p + size) and kept[q] == i + q - p: inc q
        offender = kept[p ..< q]
        return none(seq[Piece])
      let terminal = (if roles[i] == Role.Zo: Selmaho.Zo else: Selmaho.Zoi).toTerminal
      pieces.add Piece(words: kept[p ..< p + size], head: i, terminal: some(terminal))
      p += size
    of Role.Lohu:
      var q = p + 1
      while q < kept.len and roles[kept[q]] == Role.Inner and kept[q] == kept[q - 1] + 1: inc q
      let is_whole = q < kept.len and roles[kept[q]] == Role.Lehu and kept[q] == kept[q - 1] + 1
      if not is_whole or q == p + 1:
        offender = (if is_whole: kept[p .. q] else: @[i])
        return none(seq[Piece])
      pieces.add Piece(words: kept[p .. q], head: i, terminal: some(Selmaho.Lohu.toTerminal))
      p = q + 1
    else:
      offender = @[i]
      return none(seq[Piece])
  some(pieces)



#[ Constructs ]#

func isWordPlain(piece: Piece, words: openArray[Occurrence], selmaho: set[Selmaho]): bool =
  ## Test piece is one plain word, cmavo of `selmaho`.
  piece.is_plain and words[piece.head].isSelmaho(selmaho)


func isJoinable(piece: Piece, words: openArray[Occurrence]): bool =
  ## Test piece may stand by `zei`: plain word but cmavo `zei` does not affect, or `zei` chain.
  piece.terminal == some(Selmaho.Zei.toTerminal) or
      (piece.is_plain and not piece.isWordPlain(words, SELMAHO_UNJOINED))


func joined(
    pieces: openArray[Piece], words: openArray[Occurrence], offender: var seq[int]
): Option[seq[Piece]] =
  ## Join each word before `zei` and word after it into one `ZEI` piece, chain into one (4.6);
  ##   none where `zei` stands by no word it may join, which `offender` then names.
  var
    joins: seq[Piece]
    k = 0
  while k < pieces.len:
    let piece = pieces[k]
    if not piece.isWordPlain(words, {Selmaho.Zei}):
      joins.add piece
      inc k
      continue
    let is_joinable = joins.len > 0 and k + 1 < pieces.len and joins[^1].isJoinable(words) and
        pieces[k + 1].is_plain and pieces[k + 1].isJoinable(words)
    if not is_joinable:
      offender = piece.words
      return none(seq[Piece])
    var before = joins.pop
    before.words.add piece.words & pieces[k + 1].words
    (before.terminal, before.is_plain) = (some(Selmaho.Zei.toTerminal), false)
    joins.add before
    k += 2
  some(joins)


func marked(
    pieces: openArray[Piece], words: openArray[Occurrence], offender: var seq[int]
): Option[seq[Piece]] =
  ## Give each BAhE, one or more, to piece after it, whose terminal stays (rule 1100); none
  ##   where BAhE ends text, or stands before `su` that ends it, which `offender` then names.
  var
    marks: seq[Piece]
    pending: seq[int]
  for piece in pieces:
    if piece.isWordPlain(words, {Selmaho.Bahe}):
      pending.add piece.words
      continue
    if pending.len > 0 and piece.isWordPlain(words, {Selmaho.Su}): break
    var held = piece
    held.words = pending & held.words
    held.is_plain = held.is_plain and pending.len == 0
    marks.add held
    pending.setLen(0)
  if pending.len > 0:
    offender = pending
    return none(seq[Piece])
  some(marks)


func lettered(
    pieces: openArray[Piece], words: openArray[Occurrence], offender: var seq[int]
): Option[seq[Piece]] =
  ## Make word before `bu`, one or more, lerfu word: one `BU` piece (17.4); none where `bu`
  ##   follows no word, or cmavo `bu` does not affect, which `offender` then names.
  var letters: seq[Piece]
  for piece in pieces:
    if not piece.isWordPlain(words, {Selmaho.Bu}):
      letters.add piece
      continue
    let is_lettered = letters.len > 0 and
        (letters[^1].terminal == some(Selmaho.Bu.toTerminal) or
          (letters[^1].is_plain and not letters[^1].isWordPlain(words, SELMAHO_UNLETTERED)))
    if not is_lettered:
      offender = piece.words
      return none(seq[Piece])
    letters[^1].words.add piece.words
    (letters[^1].terminal, letters[^1].is_plain) = (some(Selmaho.Bu.toTerminal), false)
  some(letters)


func indicated(pieces: openArray[Piece], words: openArray[Occurrence]): seq[Piece] =
  ## Give each indicator to piece before it, `nai` after UI or CAI with it (13.9, 19.16);
  ##   indicators opening text stay pieces of their own, which rule 0 reads, as do those after
  ##   `su`, which opens text.
  var
    is_opening = true
    k = 0
  while k < pieces.len:
    let piece = pieces[k]
    if is_opening or not piece.isWordPlain(words, SELMAHO_INDICATORS):
      is_opening = piece.isWordPlain(words, {Selmaho.Su}) or
          (is_opening and piece.isWordPlain(words, SELMAHO_INDICATORS + {Selmaho.Nai}))
      result.add piece
      inc k
      continue
    result[^1].words.add piece.words
    let is_negated = piece.isWordPlain(words, {Selmaho.Ui, Selmaho.Cai}) and k + 1 < pieces.len and
        pieces[k + 1].isWordPlain(words, {Selmaho.Nai})
    if is_negated: result[^1].words.add pieces[k + 1].words
    result[^1].is_plain = false
    k += (if is_negated: 2 else: 1)



#[ Reading ]#

func toParsable(occurrences: openArray[Occurrence], is_lohu = false): seq[Occurrence] =
  ## Give words of parsable input: stream stops after `fa'o` no quotation holds, which stands
  ##   in no unit (19.15); with `is_lohu`, words open inside words `lo'u` quotes.
  result = @occurrences
  let is_ending = result.len > 0 and result[^1].isSelmaho({Selmaho.Faho}) and
    result.toRoles(is_lohu)[^1] == Role.Plain
  if is_ending: result.setLen(result.len - 1)


func toPieces(
    words: openArray[Occurrence], refusal: var RefusalText, offender: var seq[int],
    reach: var Reach, as_parting: bool,
): Option[seq[Piece]] =
  ## Group words into pieces by rules of 19.16 that act on words: quotation, then erasure,
  ##   then `zei`, BAhE, `bu` and indicators; none where rule has nothing to act on, which
  ##   `refusal` and `offender` then name. `reach` gives what erasure reaches before words.
  ##   With `as_parting`, `su` stands as piece of its own, which ends text before it, and no
  ##     rule acts across it.
  let
    roles = words.toRoles
    kept = words.erased(roles, offender, reach, as_parting)
  refusal = RefusalText.Construct
  if kept.isNone: return none(seq[Piece])
  let quoted = words.quotations(roles, kept.get, offender)
  if quoted.isNone:
    refusal = RefusalText.Quotation
    return none(seq[Piece])
  let joins = quoted.get.joined(words, offender)
  if joins.isNone: return none(seq[Piece])
  let marks = joins.get.marked(words, offender)
  if marks.isNone: return none(seq[Piece])
  let letters = marks.get.lettered(words, offender)
  if letters.isNone: return none(seq[Piece])
  some(letters.get.indicated(words))


func toTerminal(piece: Piece, words: openArray[Occurrence]): Option[Terminal] =
  ## Give terminal piece stands as: terminal of its construct, else of its word; none for cmavo
  ##   no list gives selma'o.
  if piece.terminal.isSome: piece.terminal else: words[piece.head].reading.toTerminal


func readText*(text: string): ReadingText =
  ## Read text by stream, by rules of 19.16 that act on its words, and by grammar of 21.1;
  ##   refuse at byte where reading stops, naming rule.
  let stream = text.readStream
  if not stream.is_read: return refuse(RefusalText.Stream, stream.start, $stream.refusal)
  let words = stream.occurrences.toParsable
  var
    refusal: RefusalText
    offender: seq[int]
    reach: Reach
  let pieces = words.toPieces(refusal, offender, reach, as_parting = false)
  if pieces.isNone: return refuse(refusal, (if words.len > 0: words[^1].start else: 0))

  # Hold each piece as terminal, and read terminals by grammar.
  var
    units: seq[Unit]
    terminals: seq[Terminal]
  for piece in pieces.get:
    let terminal = piece.toTerminal(words)
    if terminal.isNone: return refuse(RefusalText.Selmaho, words[piece.head].start)
    units.add Unit(words: piece.words, is_read: true, terminal: terminal.get)
    terminals.add terminal.get
  let reading = terminals.readGrammar
  if not reading.is_read:
    let start =
      if reading.at < units.len: words[units[reading.at].words[0]].start
      elif words.len < stream.occurrences.len: stream.occurrences[^1].start  # `fa'o` ends input
      else: text.len
    return refuse(RefusalText.Grammar, start, reading.rule)
  ReadingText(is_read: true, occurrences: stream.occurrences, units: units, tree: reading.tree)



#[ Marks ]#

func writtenAt(text: string, at: int): Slice[int] =
  ## Give bytes of written word holding byte `at`: run of bytes no mark between words parts.
  doAssert at < text.len and text[at] notin MARKS_BOUNDARY,
      "Stream should refuse byte of written word; got byte " & $at & "."
  var (a, b) = (at, at)
  while a > 0 and text[a - 1] notin MARKS_BOUNDARY: dec a
  while b + 1 < text.len and text[b + 1] notin MARKS_BOUNDARY: inc b
  a .. b


func remap(node: var Node, indexes: openArray[int], count: int) =
  ## Index units by each terminal of tree, and by each place grammar stops at: terminal `k` is
  ##   unit `indexes[k]`, and end of terminals is end of all `count` units.
  if node.is_terminal:
    node.at = indexes[node.at]
    return
  if node.stop.isSome:
    let at = node.stop.get.at
    node.stop.get.at = (if at < indexes.len: indexes[at] else: count)
  for child in node.children.mitems: child.remap(indexes, count)


func addPaths(node: Node, path: var seq[int], wanted: openArray[bool], paths: var seq[seq[int]]) =
  ## Give index of child at each depth down to each leaf of unit `wanted` marks, by unit.
  if node.is_terminal:
    if wanted[node.at]: paths[node.at] = path
    return
  for k in 0 ..< node.children.len:
    path.add k
    node.children[k].addPaths(path, wanted, paths)
    path.setLen(path.len - 1)


func insertAt(node: var Node, path: openArray[int], index: int, leaves: openArray[Node]) =
  ## Insert `leaves` among children of node `path` leads down to, before child `index`.
  if path.len > 0:
    node.children[path[0]].insertAt(path.toOpenArray(1, path.high), index, leaves)
    return
  node.children.insert(leaves, index)


func placeRefused(tree: var Node, units: openArray[Unit], span: Slice[int]) =
  ## Put leaf of each unit of `span` no terminal holds in lowest node holding both units read
  ##   around it, between them; leaf before first unit read, or after last, stands in root at
  ##   that end. Run of such units between two units read stands there together, in order.
  ##   Tree holds units read of `span`: one text that `su` parts.
  var
    runs: seq[tuple[before, after: Option[int], leaves: seq[Node]]]  # units read around run
    wanted = newSeq[bool](units.len)
    last = none(int)  # unit read last
    is_open = false  # last run waits for unit read after it
  for k in span:
    if units[k].is_read:
      if is_open:
        (runs[^1].after, wanted[k], is_open) = (some(k), true, false)
      last = some(k)
      continue
    if not is_open:
      runs.add (last, none(int), newSeq[Node]())
      if last.isSome: wanted[last.get] = true
      is_open = true
    runs[^1].leaves.add Node(is_terminal: true, at: k)
  var
    path: seq[int]
    paths = newSeq[seq[int]](units.len)
  tree.addPaths(path, wanted, paths)

  # From last run back, so path to each unit before it stays as it was.
  for k in countdown(runs.high, 0):
    template run: untyped = runs[k]
      ## Alias run, which `let` would copy.
    if run.before.isNone or run.after.isNone:
      tree.children.insert(run.leaves, (if run.before.isNone: 0 else: tree.children.len))
      continue
    template a: untyped = paths[run.before.get]
      ## Alias path to unit before run.
    template b: untyped = paths[run.after.get]
      ## Alias path to unit after run.
    var depth = 0
    while a[depth] == b[depth]: inc depth  # leaves differ, so paths part before either ends
    tree.insertAt(a.toOpenArray(0, depth - 1), a[depth] + 1, run.leaves)


func occurrenceEnded*(text: string, first, last: int): Occurrence =
  ## Give written word of bytes `first ..< last` of text, past `fa'o` that ends input, as
  ##   occurrence stream reads not: bytes as written, and pause period writes before it (19.15).
  var k = first
  while k > 0 and text[k - 1] in MARKS_BOUNDARY: dec k
  Occurrence(
    start: first, finish: last, text: text[first ..< last],
    pause: (if '.' in text[k ..< first]: Pause.Written else: Pause.Absent),
    reading: Reading(is_word: false, refusal: Refusal.Faho),
  )


func readUnits(text: string, is_lohu = false): ReadingParts =
  ## Read text by stream and rules of 19.16 into units, in order of first word, reading on past
  ##   each error: words stage refuses stand as unit of their own (`readTextMarked`). Tree stays
  ##   empty; reading gives what live text reads past units: erasure, and quotation that waits.
  ##   `su` stands as unit of its own, which ends text before it (ruling on #859).
  ##   With `is_lohu`, text opens inside words `lo'u` quotes (`readStream`).
  template occurrences: untyped = result.reading.occurrences
    ## Alias words of reading.
  template units: untyped = result.reading.units
    ## Alias units of reading.
  result.reading.size = text.len

  # Stream: blank each written word stream refuses, which stands as occurrence of its own.
  var
    blanked = text
    refused: seq[Occurrence]
    stream = blanked.readStream(is_lohu)
  while not stream.is_read:
    let span = blanked.writtenAt(stream.start)
    var k = span.a
    while k > 0 and text[k - 1] in MARKS_BOUNDARY: dec k
    refused.add Occurrence(
      start: span.a, finish: span.b + 1, text: text[span],
      pause: (if '.' in text[k ..< span.a]: Pause.Written else: Pause.Absent),
      reading: Reading(is_word: false, refusal: stream.refusal, detail: stream.detail),
    )
    if stream.refusal == Refusal.Quotation and stream.detail.len > 0:
      result.zois.add (span.a, stream.detail)  # `zoi` waits for its delimiter
    for i in span: blanked[i] = ' '
    stream = blanked.readStream(is_lohu)
  refused = refused.sortedByIt(it.start)

  # Words stream reads and words it refuses, in order of byte; each refused is unit of its own.
  var
    indexes = newSeq[int](stream.occurrences.len)  # index in `occurrences` of each word read
    r = 0
  template addRefused() =
    ## Add word stream refuses next, and unit holding it.
    units.add Unit(words: @[occurrences.len], is_read: false, refusal: RefusalText.Stream)
    occurrences.add refused[r]
    inc r
  for k in 0 ..< stream.occurrences.len:
    while r < refused.len and refused[r].start < stream.occurrences[k].start: addRefused()
    indexes[k] = occurrences.len
    occurrences.add stream.occurrences[k]
  while r < refused.len: addRefused()

  # Rules of 19.16: each set of words rule refuses stands as unit, and rules read words left.
  let
    words = stream.occurrences.toParsable(is_lohu)
    roles = words.toRoles  # part each word takes in first pass, over every word
  var
    alive = toSeq(0 ..< words.len)  # index in `words` of each word rules read still
    pieces: seq[Piece]
    reach: Reach
  while true:
    var
      refusal: RefusalText
      offender: seq[int]
    let grouped = alive.mapIt(words[it]).toPieces(refusal, offender, reach, as_parting = true)
    for marker in reach.markers:
      if marker notin result.markers: result.markers.add marker  # `sa` refused later sought it
    if grouped.isSome:
      pieces = grouped.get
      break
    doAssert offender.len > 0, "Rule refusing words should name them."
    units.add Unit(words: offender.mapIt(indexes[alive[it]]), is_read: false, refusal: refusal)
    for k in countdown(offender.high, 0): alive.delete(offender[k])

  # Each piece stands as terminal, or as unit no terminal holds: `su`, or cmavo no list gives
  #   selma'o.
  let left = alive.mapIt(words[it])
  for piece in pieces:
    let
      terminal = piece.toTerminal(left)
      held = piece.words.mapIt(indexes[alive[it]])
    if piece.isWordPlain(left, {Selmaho.Su}):
      units.add Unit(words: held, is_read: false, refusal: RefusalText.Su)
      if roles[alive[piece.head]] != Role.Plain: result.quoted.add words[alive[piece.head]].start
    elif terminal.isSome: units.add Unit(words: held, is_read: true, terminal: terminal.get)
    else: units.add Unit(words: held, is_read: false, refusal: RefusalText.Selmaho)

  # Words no unit holds: each run erasure erases, with cmavo erasing it (19.13); then `fa'o` that
  #   ends input, and each written word after it, which stream reads not (19.15).
  var is_helds = newSeq[bool](occurrences.len)  # some unit holds word
  for k in 0 ..< units.len:
    for w in units[k].words: is_helds[w] = true
  let ending = (if words.len < stream.occurrences.len: occurrences.high else: occurrences.len)
  var w = 0
  while w < ending:
    if is_helds[w]:
      inc w
      continue
    var run: seq[int]
    while w < ending and not is_helds[w]:
      run.add w
      inc w
    units.add Unit(words: run, is_read: false, refusal: RefusalText.Erasure)
  if ending < occurrences.len:
    units.add Unit(words: @[ending], is_read: false, refusal: RefusalText.Faho)
    var at = occurrences[ending].finish
    while at < text.len:
      if text[at] in MARKS_BOUNDARY:
        inc at
        continue
      let first = at
      while at < text.len and text[at] notin MARKS_BOUNDARY: inc at
      units.add Unit(words: @[occurrences.len], is_read: false, refusal: RefusalText.Stream)
      occurrences.add text.occurrenceEnded(first, at)
  units = units.sortedByIt(it.words[0])
  if ending < occurrences.len:
    var u = units.high
    while units[u].words[0] != ending: dec u
    result.faho = some(u)

  # `lo'u` waits where stream reads words it quotes to end of text, whatever unit holds it.
  let roles_stream = words.toRoles(is_lohu)  # part each word takes as stream reads it
  for w in 0 ..< words.len:
    let is_waiting = roles_stream[w] == Role.Lohu and
      not words.toOpenArray(w + 1, words.high).isClosingLohu
    if is_waiting: result.lohus.add words[w].start


func toTexts(units: openArray[Unit]): seq[Slice[int]] =
  ## Give units of each text `su` parts, in order: units before first `su`, between each two,
  ##   then after last; `su` stands in none.
  var first = 0
  for k in 0 ..< units.len:
    if not units[k].is_read and units[k].refusal == RefusalText.Su:
      result.add first ..< k
      first = k + 1
  result.add first ..< units.len


func toTerminals(
    units: openArray[Unit], span: Slice[int]
): tuple[read: seq[int], terminals: seq[Terminal]] =
  ## Give index of each unit of `span` grammar reads, in order, and terminal of each.
  for k in span:
    if units[k].is_read:
      result.read.add k
      result.terminals.add units[k].terminal


func readTree(reading: ReadingMarked, span: Slice[int], count: int): Node =
  ## Read units `span` of reading, one text that `su` parts, into tree that marks each error,
  ##   with each unit refused in place: place where its grammar stops at its end is unit `count`.
  let (read, terminals) = reading.units.toTerminals(span)
  result = terminals.readGrammarMarked
  result.remap(read, count)
  if read.len < span.len: result.placeRefused(reading.units, span)


func readTextMarked*(text: string): ReadingMarked =
  ## Read text as `readText` does, and read on past each error, marking it (#859): words stage
  ##   refuses stand as unit of their own, which grammar reads around, and tree marks where
  ##   grammar stops (`readGrammarMarked`). Text `readText` reads gives reading it gives.
  ##   Stream: each written word stream refuses stands as occurrence, as written, and stream
  ##     reads text again with its bytes blanked; so each refusal holds one written word.
  ##   Rules of 19.16: words rule refuses stand as unit, and rules read words left again.
  ##   Selma'o: piece of cmavo no list gives selma'o stands as unit, with words it holds.
  ##   This parser decides no mend (ruling `D1 a` of #859); other program reads tree and mends.
  ##   `su` ends text before it, which reads alone, as text after it does: root of text after
  ##     last `su` holds tree of each text before it, each with leaf of `su` after it, before its
  ##     own nodes (ruling on #859). So tree `readText` gives is root past last `su`.
  ##   `fa'o` that ends input, and each written word after it, stand last in root, past text.
  let parts = text.readUnits
  result = parts.reading
  let
    ending = (if parts.faho.isSome: parts.faho.get else: result.units.len)
    texts = result.units.toOpenArray(0, ending - 1).toTexts
  var before: seq[Node]  # tree of each text before last `su`, then leaf of `su` after it
  for k in 0 ..< texts.high:
    before.add result.readTree(texts[k], texts[k].b + 1)
    before.add Node(is_terminal: true, at: texts[k].b + 1)
  result.tree = result.readTree(texts[^1], ending)
  result.tree.children.insert(before, 0)
  for u in ending ..< result.units.len: result.tree.children.add Node(is_terminal: true, at: u)


func readTextParts*(text: string, is_live, is_lohu = false): ReadingParts =
  ## Read text as `readTextMarked` does, into node of each part as passes cut it, each reading
  ##   alone (`readGrammarParts`), so each sentence of live text goes out once it ends. Root
  ##   holds them, with each unit refused between parts; `assembleText` builds tree of text.
  ##   Live text (`is_live`) cuts after opener that waits for its closer (ruling on #859), and
  ##     reads text after `lo'u` that waits inside words it quotes (`is_lohu`), as stream does.
  ##   `su` ends text before it, which reads alone, as text after it does; its leaf stands
  ##     between their parts. Opener of text before it that waits closes there, as at end of
  ##     text, so live text cuts after opener of text after last `su` alone.
  result = text.readUnits(is_lohu)
  template reading: untyped = result.reading
    ## Alias reading of parts.
  reading.tree = Node(is_terminal: false, rule: "text", number: 0)
  let
    ending = (if result.faho.isSome: result.faho.get else: reading.units.len)
    texts = reading.units.toOpenArray(0, ending - 1).toTexts
  for k in 0 ..< texts.len:
    let
      is_last = k == texts.high
      (read, terminals) = reading.units.toTerminals(texts[k])
      (parts, open) = terminals.readGrammarParts(is_live and is_last)
    var tree = Node(is_terminal: false, rule: "text", number: 0, children: parts)
    tree.remap(read, if is_last: ending else: texts[k].b + 1)
    if read.len < texts[k].len: tree.placeRefused(reading.units, texts[k])
    for child in tree.children.mitems: reading.tree.children.add move(child)
    if is_last: result.open = open.mapIt(read[it])
    else: reading.tree.children.add Node(is_terminal: true, at: texts[k].b + 1)
  for u in ending ..< reading.units.len: reading.tree.children.add Node(is_terminal: true, at: u)
