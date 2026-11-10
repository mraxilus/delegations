## Read lojban prose: words of stream, rules of CLL that act on words before grammar, then
##   grammar of 21.1 over terminals they leave.
##
##   |--------------|-------------------------------------------------------------------|
##   | Code         | Meaning                                                           |
##   |--------------|-------------------------------------------------------------------|
##   | Unit         | words one terminal of grammar holds, with that terminal           |
##   | RefusalText  | rule refusing text: stream, selma'o, quotation, construct, grammar |
##   | ReadingText  | tree of text over its units, or refusal with its place            |
##   | readText     | read text by stream, rules of 19.16, and grammar of 21.1          |
##   |--------------|-------------------------------------------------------------------|
##
##   Order follows what 19.16 says each cmavo does not affect: quotation first, then `fa'o`,
##     then erasure, then `zei` and BAhE, then `bu`, then indicators. CLL gives no full order.
##   Quotation: `zo` quotes next word, whatever it is (19.10); `lo'u` quotes words up to
##     `le'u` that no `zo` quotes (19.9); `readStream` holds text `zoi` and `la'o` quote. Each
##     stands as one terminal, as rewrites of `grammar.nim` give.
##   `fa'o` ends parsable input unless quoted (19.15, 21.1); `readStream` stops after it, and
##     it stands in no unit.
##   Erasure acts on words, each quotation counted by its words: `zo` quotation is two, `zoi`
##     quotation four (19.13, Examples 19.77, 19.79). `si` erases word before it, and `su`
##     every word before it. `sa` erases back to and including last word of selma'o of word
##     after it, or back to start of text where none stands, as Example 19.81 erases back to
##     start for `.i` of no earlier sentence.
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
##     or end of text.

{.experimental: "strictFuncs".}

import std/[options, sequtils]

import ./[grammar, selmaho, stream, tanru]


type
  Unit* = object  ## Define words one terminal of grammar holds: one word, or construct of 19.16.
    words*: seq[int]  ## Index of each occurrence unit holds, in order; erased words left out.
    terminal*: Terminal

  RefusalText* {.pure.} = enum  ## Define why prose is refused.
    Stream  ## Stream refuses text; `rule` names its refusal.
    Selmaho  ## Cmavo no list gives selma'o, so grammar reads no terminal (ch. 20).
    Quotation  ## `zo` quoting nothing, `lo'u` never closed or quoting nothing, or erasure
                ##   leaving part of quotation (19.9, 19.10, 19.13).
    Construct  ## `si` or `sa` with nothing to erase, or `zei`, BAhE or `bu` with no word
               ##   to act on (19.13, 4.6, 17.4).
    Grammar  ## Grammar of 21.1 refuses terminals; `rule` names rule stopping there.

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

func toRoles(words: openArray[Occurrence]): seq[Role] =
  ## Give part each word takes in quotation: `zo` quotes next word, `lo'u` words up to `le'u`
  ##   no `zo` quotes, and `zoi` its delimiter, text and delimiter, as `readStream` holds them.
  result = newSeq[Role](words.len)
  var
    i = 0
    is_lohu = false
  while i < words.len:
    if words[i].isSelmaho({Selmaho.Zo}) and i + 1 < words.len:
      result[i] = (if is_lohu: Role.Inner else: Role.Zo)
      result[i + 1] = (if is_lohu: Role.Inner else: Role.Quoted)
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


func erased(words: openArray[Occurrence], roles: openArray[Role]): Option[seq[int]] =
  ## Keep words erasure leaves, by index (19.13): `si` erases word before it, `sa` back to last
  ##   word of selma'o of word after it or to start, `su` every word before it; cmavo
  ##   quotation holds erase nothing. None where `si` or `sa` has nothing to act on.
  var kept: seq[int]
  for i, word in words:
    if roles[i] != Role.Plain or not word.isSelmaho({Selmaho.Si, Selmaho.Sa, Selmaho.Su}):
      kept.add i
      continue
    case word.toSelmaho.get
    of Selmaho.Si:
      if kept.len == 0: return none(seq[int])
      kept.setLen(kept.len - 1)
    of Selmaho.Sa:
      if i + 1 >= words.len: return none(seq[int])
      let
        marker = words[i + 1].reading.toTerminal
        last = toSeq(0 ..< kept.len).filterIt(words[kept[it]].reading.toTerminal == marker)
      kept.setLen(if last.len > 0: last[^1] else: 0)
    else:
      kept.setLen(0)
  some(kept)


func quotations(
    words: openArray[Occurrence], roles: openArray[Role], kept: openArray[int]
): Option[seq[Piece]] =
  ## Group words kept into pieces: each quotation whole, as one terminal, and each other word
  ##   alone; none where erasure leaves part of quotation, or `lo'u` quotes no word (19.80).
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
      if p + size > kept.len or kept[p + size - 1] != i + size - 1: return none(seq[Piece])
      let terminal = (if roles[i] == Role.Zo: Selmaho.Zo else: Selmaho.Zoi).toTerminal
      pieces.add Piece(words: kept[p ..< p + size], head: i, terminal: some(terminal))
      p += size
    of Role.Lohu:
      var q = p + 1
      while q < kept.len and roles[kept[q]] == Role.Inner and kept[q] == kept[q - 1] + 1: inc q
      let is_whole = q < kept.len and roles[kept[q]] == Role.Lehu and kept[q] == kept[q - 1] + 1
      if not is_whole or q == p + 1: return none(seq[Piece])
      pieces.add Piece(words: kept[p .. q], head: i, terminal: some(Selmaho.Lohu.toTerminal))
      p = q + 1
    else:
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


func joined(pieces: openArray[Piece], words: openArray[Occurrence]): Option[seq[Piece]] =
  ## Join each word before `zei` and word after it into one `ZEI` piece, chain into one (4.6);
  ##   none where `zei` stands by no word it may join.
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
    if not is_joinable: return none(seq[Piece])
    var before = joins.pop
    before.words.add piece.words & pieces[k + 1].words
    (before.terminal, before.is_plain) = (some(Selmaho.Zei.toTerminal), false)
    joins.add before
    k += 2
  some(joins)


func marked(pieces: openArray[Piece], words: openArray[Occurrence]): Option[seq[Piece]] =
  ## Give each BAhE, one or more, to piece after it, whose terminal stays (rule 1100); none
  ##   where BAhE ends text.
  var
    marks: seq[Piece]
    pending: seq[int]
  for piece in pieces:
    if piece.isWordPlain(words, {Selmaho.Bahe}):
      pending.add piece.words
      continue
    var held = piece
    held.words = pending & held.words
    held.is_plain = held.is_plain and pending.len == 0
    marks.add held
    pending.setLen(0)
  if pending.len > 0: return none(seq[Piece])
  some(marks)


func lettered(pieces: openArray[Piece], words: openArray[Occurrence]): Option[seq[Piece]] =
  ## Make word before `bu`, one or more, lerfu word: one `BU` piece (17.4); none where `bu`
  ##   follows no word, or cmavo `bu` does not affect.
  var letters: seq[Piece]
  for piece in pieces:
    if not piece.isWordPlain(words, {Selmaho.Bu}):
      letters.add piece
      continue
    let is_lettered = letters.len > 0 and
        (letters[^1].terminal == some(Selmaho.Bu.toTerminal) or
          (letters[^1].is_plain and not letters[^1].isWordPlain(words, SELMAHO_UNLETTERED)))
    if not is_lettered: return none(seq[Piece])
    letters[^1].words.add piece.words
    (letters[^1].terminal, letters[^1].is_plain) = (some(Selmaho.Bu.toTerminal), false)
  some(letters)


func indicated(pieces: openArray[Piece], words: openArray[Occurrence]): seq[Piece] =
  ## Give each indicator to piece before it, `nai` after UI or CAI with it (13.9, 19.16);
  ##   indicators opening text stay pieces of their own, which rule 0 reads.
  var
    is_opening = true
    k = 0
  while k < pieces.len:
    let piece = pieces[k]
    if is_opening or not piece.isWordPlain(words, SELMAHO_INDICATORS):
      is_opening = is_opening and piece.isWordPlain(words, SELMAHO_INDICATORS + {Selmaho.Nai})
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

func readText*(text: string): ReadingText =
  ## Read text by stream, by rules of 19.16 that act on its words, and by grammar of 21.1;
  ##   refuse at byte where reading stops, naming rule.
  let stream = text.readStream
  if not stream.is_read: return refuse(RefusalText.Stream, stream.start, $stream.refusal)
  var words = stream.occurrences
  if words.len > 0 and words[^1].isSelmaho({Selmaho.Faho}) and words.toRoles[^1] == Role.Plain:
    words.setLen(words.len - 1)  # 19.15, `fa'o` no quotation holds ends input

  # Read quotation, then erasure, then words it leaves.
  let
    roles = words.toRoles
    kept = words.erased(roles)
    at = (if words.len > 0: words[^1].start else: 0)
  if kept.isNone: return refuse(RefusalText.Construct, at)
  let quoted = words.quotations(roles, kept.get)
  if quoted.isNone: return refuse(RefusalText.Quotation, at)

  # Act on words: `zei`, then BAhE, then `bu`, then indicators (19.16).
  let joins = quoted.get.joined(words)
  if joins.isNone: return refuse(RefusalText.Construct, at)
  let marks = joins.get.marked(words)
  if marks.isNone: return refuse(RefusalText.Construct, at)
  let letters = marks.get.lettered(words)
  if letters.isNone: return refuse(RefusalText.Construct, at)
  let pieces = letters.get.indicated(words)

  # Hold each piece as terminal, and read terminals by grammar.
  var
    units: seq[Unit]
    terminals: seq[Terminal]
  for piece in pieces:
    let terminal =
      if piece.terminal.isSome: piece.terminal else: words[piece.head].reading.toTerminal
    if terminal.isNone: return refuse(RefusalText.Selmaho, words[piece.head].start)
    units.add Unit(words: piece.words, terminal: terminal.get)
    terminals.add terminal.get
  let reading = terminals.readGrammar
  if not reading.is_read:
    let start = (if reading.at < units.len: words[units[reading.at].words[0]].start else: text.len)
    return refuse(RefusalText.Grammar, start, reading.rule)
  ReadingText(is_read: true, occurrences: stream.occurrences, units: units, tree: reading.tree)
