## Read live text as it arrives, piece by piece: each sentence goes out as NIF once it ends, and
##   word that reaches back cuts NIF back, so live text of hours reads in time its length gives
##   (#859).
##
##   |----------------|--------------------------------------------------------------------|
##   | Code           | Meaning                                                            |
##   |----------------|--------------------------------------------------------------------|
##   | ReaderLive     | text so far, NIF that went out, and openers that wait for closers  |
##   | ChangeNif      | change piece makes to NIF: offset and byte it cuts to, nodes, tail |
##   | initReaderLive | reader of live text, whose NIF holds directives alone              |
##   | push           | read next piece of live text                                       |
##   | finish         | read end of live text, and give rest of its NIF                    |
##   | toNif          | NIF that went out so far                                           |
##   | countRead      | bytes each reading read, summed, which cost check reads            |
##   |----------------|--------------------------------------------------------------------|
##
##   Rulings of Architect on #859 give design:
##     Node of each part, read alone (`readTextParts`), goes out on line of its own once next
##       part opens, and so does unit refused between parts. Tree of text follows from nodes
##       (`assembleText`), so nothing of it is lost.
##     No piece reads whole text again: piece reads text from start of part still open. Word
##       that reaches back reads again from node where it lands, and NIF cuts back to offset
##       where that node opens: cursor, as `ChangeNif` gives it. Change gives byte of text where
##       node opens too, so other program ties each node to text it reads, at each change.
##     Node of part still open goes out as tail, which next change replaces, so tree grows word
##       by word, as program that animates it may show.
##   Piece may cut word, so text read stops before last written word no mark ends: `su` that
##     next piece makes `su'i` erases nothing. Text read opens at span of node: its first word,
##     past words of node before, so span holds each word erasure erased before node. Node
##     shares span before it where quotation holds word span would open at, or where its first
##     word stands among words of node before, as word stream refuses between word and `bu`; or
##     where rules refuse `zei` before it, which joins word after it once they read one (19.16).
##   Reach back, from text read again to node before it:
##     `si` that finds no word, back as many words as it erases; `bu` or `zei` that finds none,
##       to word before; `sa` that finds no marker, to node holding it, or to start (19.13).
##       Erasure reaches no node before `su` (19.13).
##     First unit read that opens no part, as `zei` joining `.i` to word after it, to node holding
##       unit read last; error node whose stop names unit read after it, once that unit changes.
##     Closer of opener that waits, to node holding opener.
##     `su` ends text before it, which stays as it read: NIF cuts back nowhere, and `su` goes out
##       as node of its own, before text after it, which reads alone (ruling on #859). Opener of
##       text before it that waits, `tu'e`, `lu` or `to`, closes there, as at end, so text reads
##       again from it; quotation that waits quotes `su` once closed (19.9, 19.10).
##   Opener that waits for its closer, `tu'e`, `lu`, `to`, `lo'u`, `zoi` or `la'o`, reads as
##     plain terminal, so sentences after it go out at once; its closer reads them again. Opener
##     of quotation with word erasure erased before it reads again from start of its text, since
##     its closer may quote word that erased it. End reads text from first opener still waiting
##     as whole text does: `lu`, `to` and `tu'e` close there, as 21.1 lets closer be elided, and
##     `zoi`, `la'o` and `lo'u` stand as errors.
##   Text after `lo'u` that waits reads inside words it quotes, as stream reads them (19.9):
##     there `zoi` takes three words after it as quotation once they come (`toRoles`), so waits.
##     `lo'u` whose `le'u` erasure erases waits for none, since stream reads that `le'u`.
##   `fa'o` that ends input (19.15) stops each piece reading past it, till delimiter of `zoi`
##     before it comes, which quotes it. Each node goes out once `fa'o` reads, and each written
##     word after it goes out as unit of its own once mark ends it, so no piece reads text again:
##     cost stays linear past `fa'o`. End reads text from `fa'o` again, as whole text does.
##   Words erasure erases stand as unit of their own (`prose.nim`), and node after it shares its
##     span, so text read again from node reads them again, as erasure in it may have erased them.
##   Laws: at end, NIF of text read piece by piece is NIF of its parts read whole; before end,
##     NIF and tail of each change are parts of text so far, to its last mark, read whole as
##     live text (`test_live.nim`).
##   Cost: each piece reads part still open again, so time grows with length of text times
##     length of sentence; reach back reads from node where it lands, once.
##   Reader loops by index, since `items` copies on JavaScript backend.

{.experimental: "strictFuncs".}

import std/[algorithm, options, sequtils, strutils]

import ./[grammar, nif, prose, selmaho, stream, tanru]


type
  ChangeNif* = object  ## Define change one piece makes to NIF of live text.
    at*: int  ## Offset in NIF where change opens: NIF from it on drops, then `text` follows.
    start*: int
      ## Byte of text where change opens: each word of NIF before `at` ends at it or before, and
      ##   each word of `text` and `tail` opens at it or past, so NIF ties to text it reads.
    text*: string  ## NIF of each node that goes out, each on line of its own.
    tail*: string
      ## NIF of each node still open, as text so far gives it, each on line of its own; next
      ##   change replaces it.

  ItemLive = object  ## Define node that went out: part, or unit refused between parts.
    start: int  ## Byte where its span opens: word past words of node before it (`toSpans`).
    offset: int  ## Offset in NIF where its line opens.
    kept: seq[Option[Terminal]]
      ## Terminal of each word it holds that erasure may erase, in order: words of units read,
      ##   and of cmavo no list gives selma'o.
    last: Option[Terminal]  ## Terminal of unit read last, in it or in node before it.
    held: int  ## Index of last node, it or one before it, that holds unit read; -1 for none.
    is_parted: bool
      ## Part of its text went out, at it or before it: part of no unit, which text of no unit
      ##   read gives, stands in it once.
    stop: Option[int]
      ## Byte of unit read after it, which stop of its error node names; none where no stop
      ##   names unit past its own.
    is_su: bool
      ## Node is leaf of `su`, which ends text before it: erasure after it reaches no node before,
      ##   save where `is_quoted`.
    is_quoted: bool
      ## Node is leaf of `su` that quotation held in first pass of rules of 19.16: erasure after
      ##   it reaches past it, since erasure that erases rest of quotation quotes it again.
    start_reading: int
      ## Byte where reading that put node out opened: closer of quotation that quotes `su` reads
      ##   text again from it, since `su` then ends no text.

  OpenerLive = object  ## Define opener that waits for its closer in text so far.
    selmaho: Selmaho  ## Selma'o of opener: TUhE, LU, TO, LOhU, or ZOI for `zoi` and `la'o`.
    at: int  ## Byte where its word opens.
    start: int  ## Byte where span of node holding it opens, which its closer reads again from.
    after: int  ## Byte where text `zoi` quotes opens, past its delimiter; 0 for other opener.
    delimiter: string
      ## Delimiter of `zoi`, which closes it; empty for other opener, and for `zoi` that takes
      ##   three words after it, inside words `lo'u` quotes, which each word closes.

  ReaderLive* = object  ## Define reader of live text: text so far, NIF out, openers waiting.
    text: string
    nif: string  ## Directives, then line of each node that went out.
    tail: string  ## NIF of each node still open, as last change gives it.
    start_tail: int
      ## Byte where first word of tail opens, past each word that went out: change of piece that
      ##   reads no word more opens there. End of text read, where tail holds no word.
    items: seq[ItemLive]  ## Each node that went out, in order.
    openers: seq[OpenerLive]  ## Each opener waiting, in order of byte.
    start: int  ## Byte where text not yet out opens.
    count_read: int  ## Bytes each reading has read, summed; cost check reads it.
    ending: int  ## Byte where text read last ends: past last mark between words.
    stop: Option[int]
      ## Byte past written word of `fa'o` that ends input (19.15), where each piece stops reading;
      ##   none before. End reads past it, since closer of opener before may quote it.
    is_ended: bool  ## End of live text was read.


func initReaderLive*(): ReaderLive =
  ## Make reader of live text, whose NIF holds directives alone.
  ReaderLive(nif: HEADER)


func toNif*(reader: ReaderLive): string = reader.nif
  ## Give NIF that went out so far: directives, then line of each node.

func countRead*(reader: ReaderLive): int = reader.count_read
  ## Give bytes each reading of text has read, summed: cost, which grows with length of text
  ##   times length of sentence.



#[ Text read ]#

func isSu(unit: Unit): bool =
  ## Test unit is `su`, which ends text before it.
  not unit.is_read and unit.refusal == RefusalText.Su


func isErasure(unit: Unit): bool =
  ## Test unit holds words erasure erases, and cmavo erasing them.
  not unit.is_read and unit.refusal == RefusalText.Erasure


func isWall(item: ItemLive): bool =
  ## Test node is `su` that erasure after it reaches not: no quotation held it in first pass.
  item.is_su and not item.is_quoted


func addLeaves(node: Node, leaves: var seq[int]) =
  ## Add index of each unit under node to `leaves`, in order of tree.
  if node.is_terminal:
    leaves.add node.at
    return
  for k in 0 ..< node.children.len: node.children[k].addLeaves(leaves)


func stopMost(node: Node): int =
  ## Give greatest unit where grammar stops in tree, as error node marks; -1 where none stops.
  if node.is_terminal: return -1
  result = (if node.stop.isSome: node.stop.get.at else: -1)
  for k in 0 ..< node.children.len: result = max(result, node.children[k].stopMost)


func toCleans(occurrences: openArray[Occurrence]): seq[bool] =
  ## Give, for each word of text read, whether stream reads text from it as it reads it in
  ##   place: no quotation holds it, as word `zo` quotes, word of `zoi` or `la'o` after it, or
  ##   word of `lo'u` that `le'u` closes. Word stream refuses takes state of word stream reads
  ##   after it. `lo'u` no `le'u` closes waits as opener instead (`OpenerLive`).
  func isSelmaho(word: Occurrence, selmaho: Selmaho): bool =
    ## Test word is cmavo of `selmaho`.
    word.reading.is_word and word.reading.selmaho == some(selmaho)

  result = newSeq[bool](occurrences.len)
  var
    reads: seq[int]  # each word stream reads, past words it refuses
    is_reads = newSeq[bool](occurrences.len)
  for k in 0 ..< occurrences.len:
    result[k] = true
    is_reads[k] = occurrences[k].reading.is_word or
      occurrences[k].reading.refusal == Refusal.Foreign
    if is_reads[k]: reads.add k
  var i = 0
  while i < reads.len:
    template word: untyped = occurrences[reads[i]]
      ## Alias word, which `let` would copy.
    var last = i  # last word quotation holds
    if word.isSelmaho(Selmaho.Zo): last = i + 1
    elif word.isSelmaho(Selmaho.Zoi):
      let is_quoting = i + 2 < reads.len and not occurrences[reads[i + 2]].reading.is_word
      if is_quoting: last = i + 3
    elif word.isSelmaho(Selmaho.Lohu):
      var j = i + 1
      while j < reads.len and not occurrences[reads[j]].isSelmaho(Selmaho.Lehu):
        j += (if occurrences[reads[j]].isSelmaho(Selmaho.Zo): 2 else: 1)
      if j < reads.len: last = j
    for q in i + 1 .. min(last, reads.high): result[reads[q]] = false
    i = last + 1
  var is_clean = true  # stream reads from word it reads next as it reads it in place
  for k in countdown(occurrences.high, 0):
    if is_reads[k]: is_clean = result[k] else: result[k] = is_clean


func toSpans(region: ReadingParts, leaves: openArray[seq[int]], first: int): seq[int] =
  ## Give byte where span of each child of root of text read opens: first word past words of
  ##   child before it, so span holds each word erasure erased before child, which erasure in
  ##   it may have erased; first opens at `first`. Child shares span of child before where its
  ##   first word stands among words of that child, as refused word between word and indicator
  ##   marking it; where quotation holds word span would open at (`toCleans`), which erasure
  ##   erased; where word before its first word is `sa` that erasure erased, past each word stream
  ##   or rules refuse, since first word rules read past `sa` gives its marker (19.13); where
  ##   child before is words erasure erased, which erasure in it may have erased; or where rules
  ##   refuse `zei` before its first word, past each word stream or rules refuse or erasure
  ##   erases, since `zei` joins word after it once rules read one there, as once they refuse
  ##   quotation that opens there (19.16).
  func isRefused(unit: Unit): bool =
    ## Test rule of 19.16 refuses unit, so rules read on past its words.
    not unit.is_read and unit.refusal in {RefusalText.Quotation, RefusalText.Construct}

  func isRefusedZei(unit: Unit, word: Occurrence): bool =
    ## Test rules refuse word of unit as `zei`, which joins word after it once they read one.
    not unit.is_read and unit.refusal == RefusalText.Construct and word.reading.is_word and
      word.reading.selmaho == some(Selmaho.Zei)

  template units: untyped = region.reading.units
    ## Alias units of text read, which `let` would copy.
  template occurrences: untyped = region.reading.occurrences
    ## Alias words of text read, which `let` would copy.
  let cleans = occurrences.toCleans
  var holders = newSeq[int](occurrences.len)  # unit holding each word; -1 for none
  for w in 0 ..< occurrences.len: holders[w] = -1
  for u in 0 ..< units.len:
    for w in units[u].words: holders[w] = u
  result = newSeq[int](leaves.len)
  var next = 0  # word past words of children before
  for k in 0 ..< leaves.len:
    let opening = (if leaves[k].len > 0: units[leaves[k][0]].words[0] else: next)  # first word
    var
      before = opening - 1  # word before it, past words stream or rules refuse
      prior = opening - 1  # word before it, past words erasure erases too, save `zei` refused
    while before >= 0 and (not occurrences[before].reading.is_word or
        (holders[before] >= 0 and units[holders[before]].isRefused)):
      dec before
    while prior >= 0 and (not occurrences[prior].reading.is_word or holders[prior] < 0 or
        units[holders[prior]].isErasure or (units[holders[prior]].isRefused and
          not units[holders[prior]].isRefusedZei(occurrences[prior]))):
      dec prior
    let
      is_among = leaves[k].len > 0 and units[leaves[k][0]].words[0] < next
      is_marked = before >= 0 and
        (holders[before] < 0 or units[holders[before]].isErasure) and
        occurrences[before].reading.selmaho == some(Selmaho.Sa)
      is_after_erasure = k > 0 and leaves[k - 1].len == 1 and
        region.reading.tree.children[k - 1].is_terminal and units[leaves[k - 1][0]].isErasure
      is_after_zei = prior >= 0 and holders[prior] >= 0 and
        units[holders[prior]].isRefusedZei(occurrences[prior])
    if k == 0: result[k] = first
    elif is_among or is_marked or is_after_erasure or is_after_zei or
        (next < occurrences.len and not cleans[next]):
      result[k] = result[k - 1]
    elif next < occurrences.len: result[k] = occurrences[next].start
    else: result[k] = region.reading.size
    for u in leaves[k]: next = max(next, units[u].words[^1] + 1)


func byteQuoted(text: string, at: int, delimiter: string): int =
  ## Give byte where text `zoi` at byte `at` quotes opens: past written word after it where that
  ##   word spells delimiter, else past written word holding `zoi`, which then holds delimiter.
  var a = at
  while a < text.len and text[a] notin MARKS_BOUNDARY: inc a
  var b = a
  while b < text.len and text[b] in MARKS_BOUNDARY: inc b
  var c = b
  while c < text.len and text[c] notin MARKS_BOUNDARY: inc c
  if text[b ..< c].toLowerAscii.replace(",", "") == delimiter: c else: a


func isSpelled(text: string, first, last: int, delimiter: string): bool =
  ## Test written word of bytes `first ..< last` of text spells `delimiter`, as stream reads word
  ##   closing text `zoi` quotes (19.10).
  var at = first
  while at < last:
    if text[at] in MARKS_BOUNDARY:
      inc at
      continue
    let start = at
    while at < last and text[at] notin MARKS_BOUNDARY: inc at
    if text[start ..< at].toLowerAscii.replace(",", "") == delimiter: return true
  false


func readFrom(reader: var ReaderLive, start: int, is_final: bool): ReadingParts =
  ## Read text from byte `start` on as its parts, each byte counted from start of text, inside
  ##   words `lo'u` waiting before it quotes, as stream reads them. Before end, text read stops
  ##   before last written word no mark ends, since next piece may go on with it, as `su'i`
  ##   with `su`; and at `fa'o` that ends input, though its end counts past text after it.
  var ending = reader.text.len
  if not is_final:
    while ending > start and reader.text[ending - 1] notin MARKS_BOUNDARY: dec ending
  let
    last = (if reader.stop.isSome and not is_final: min(ending, reader.stop.get) else: ending)
    is_lohu = reader.openers.anyIt(it.selmaho == Selmaho.Lohu and it.at < start)
  result = readTextParts(reader.text[start ..< last], is_live = not is_final, is_lohu)
  reader.count_read += last - start
  for occurrence in result.reading.occurrences.mitems:
    (occurrence.start, occurrence.finish) = (occurrence.start + start, occurrence.finish + start)
  result.reading.size = ending
  for zoi in result.zois.mitems: zoi.start += start
  for lohu in result.lohus.mitems: lohu += start
  for quoted in result.quoted.mitems: quoted += start



#[ Reach back ]#

func reopening(reader: ReaderLive, opener: OpenerLive): int =
  ## Give byte where closer of quotation opener reads text again from: node holding opener, or
  ##   where reading that put out `su` after it opened, since quotation quotes each `su` after
  ##   it, so text before it reads again as text `su` ends not (19.9, 19.10).
  result = opener.start
  var k = reader.items.high
  while k >= 0 and reader.items[k].start > opener.at:
    if reader.items[k].is_su: result = min(result, reader.items[k].start_reading)
    dec k


func boundary(reader: ReaderLive, at: int): int =
  ## Give byte at or before `at` where reading may open again: where node holding first byte of
  ##   written word holding `at` opens, since stream reads each written word whole; start of text,
  ##   with no node there.
  result = at
  while result > 0 and reader.text[result - 1] notin MARKS_BOUNDARY:
    var first = result - 1
    while first > 0 and reader.text[first - 1] notin MARKS_BOUNDARY: dec first
    var k = reader.items.high
    while k >= 0 and reader.items[k].start > first: dec k
    result = (if k >= 0: reader.items[k].start else: 0)


func reach(reader: ReaderLive, region: ReadingParts, start: int): Option[int] =
  ## Give earliest byte before `start` that reading of text from `start` reaches: node holding
  ##   opener whose closer text holds, or that `su` closes, node where its erasure lands, node
  ##   its first unit read joins, and node whose stop names unit read after it; none where text
  ##   before reads as it did. Words after first `su` of text read reach no node before it, save
  ##   closer of quotation, which quotes `su`.
  func earlier(back: Option[int], at: int): Option[int] =
    ## Give earlier of byte kept and `at`.
    some(if back.isSome: min(back.get, at) else: at)

  func landing(reader: ReaderLive, k, j, start: int): int =
    ## Give byte where node `k` opens, where erasure of text from `start`, past node `j`, lands;
    ##   past it where it is `su` that erasure reaches not.
    if not reader.items[k].isWall: reader.items[k].start
    elif k + 1 < j: reader.items[k + 1].start
    else: start

  template units: untyped = region.reading.units
    ## Alias units of text read, which `let` would copy.
  template occurrences: untyped = region.reading.occurrences
    ## Alias words of text read, which `let` would copy.
  var
    back = none(int)
    j = reader.items.len  # nodes before `start`
    first = 0  # units of first text of text read, before its first `su`
  while j > 0 and reader.items[j - 1].start >= start: dec j
  while first < units.len and not units[first].isSu: inc first

  # Closer of `tu'e`, `lu` or `to` that no opener of text opens closes opener of its kind that
  #   waits before text, nearest first, as passes track them (`toParts`); text read again reads
  #   each opener in it again, which may open no more. `su` closes each, as end does.
  var
    strays: array[OPENERS.len, int]  # closers of each kind that close no opener of text
    opened: seq[int]  # kind of each opener open in text, innermost last
  for u in 0 ..< first:
    if not units[u].is_read: continue
    for k in 0 ..< OPENERS.len:
      if units[u].terminal == OPENERS[k].toTerminal: opened.add k
      if units[u].terminal != CLOSERS[k].toTerminal: continue
      var n = opened.high
      while n >= 0 and opened[n] != k: dec n
      if n >= 0: opened.setLen(n) else: inc strays[k]
  for k in 0 ..< OPENERS.len:
    var
      left = (if first < units.len: reader.openers.len else: strays[k])
      n = reader.openers.high
    while left > 0 and n >= 0:
      if reader.openers[n].selmaho == OPENERS[k] and reader.openers[n].start < start:
        back = back.earlier(reader.openers[n].start)
        dec left
      dec n

  # Closer of quotation: `le'u` closes first `lo'u` that waits, which quotes each after it, and
  #   delimiter its `zoi`; each quotes `su` before it.
  if occurrences.isClosingLohu:
    var n = 0
    while n < reader.openers.len and reader.openers[n].selmaho != Selmaho.Lohu: inc n
    if n < reader.openers.len: back = back.earlier(reader.reopening(reader.openers[n]))
  for n in 0 ..< reader.openers.len:
    template opener: untyped = reader.openers[n]
      ## Alias opener, which `let` would copy.
    if opener.selmaho != Selmaho.Zoi: continue
    let is_closing = opener.delimiter.len == 0 or
      reader.text.isSpelled(max(start, opener.after), region.reading.size, opener.delimiter)
    if is_closing: back = back.earlier(reader.reopening(opener))
  if j == 0: return back

  # `si` that finds no word erases words of nodes before, last first; `bu` or `zei` that finds
  #   none acts on last word of nodes before, where no word kept stands before it (19.13, 19.16).
  var
    deficit = 0
    is_kept = false  # word kept stands before unit
  for u in 0 ..< first:
    template unit: untyped = units[u]
      ## Alias unit, which `let` would copy.
    if unit.is_read or unit.refusal == RefusalText.Selmaho: is_kept = true
    if unit.is_read or unit.refusal != RefusalText.Construct or unit.words.len != 1: continue
    template word: untyped = occurrences[unit.words[0]]
      ## Alias word of unit, which `let` would copy.
    if not word.reading.is_word: continue
    if word.reading.selmaho == some(Selmaho.Si): inc deficit
    elif word.reading.selmaho in [some(Selmaho.Bu), some(Selmaho.Zei)] and not is_kept:
      inc deficit
  if deficit > 0:
    var k = j - 1
    while k > 0 and not reader.items[k].isWall and reader.items[k].kept.len < deficit:
      deficit -= reader.items[k].kept.len
      dec k
    back = back.earlier(reader.landing(k, j, start))

  # `sa` that finds no marker in text erases back to node holding it, or to start of its text
  #   (19.13).
  for marker in region.markers:
    var k = j - 1
    while k > 0 and not reader.items[k].isWall and marker notin reader.items[k].kept: dec k
    back = back.earlier(reader.landing(k, j, start))

  # First unit read opens part only where it opens one after unit read before (`isCutAt`); and
  #   stop that names unit read after node names first unit read here.
  let held = reader.items[j - 1].held
  if held < 0: return back
  var
    terminals: seq[Terminal]
    first_read = none(int)  # byte of first unit read
  for u in 0 ..< first:
    if not units[u].is_read: continue
    terminals.add units[u].terminal
    if first_read.isNone: first_read = some(region.reading.byteAt(u))
  let is_joined = terminals.len > 0 and not terminals.isCutAt(0, reader.items[j - 1].last)
  if is_joined or (reader.items[held].stop.isSome and reader.items[held].stop != first_read):
    back = back.earlier(reader.items[held].start)
  back



#[ Change of NIF ]#

func cut(reader: var ReaderLive, start: int): int =
  ## Cut nodes, openers and NIF back to first node text from `start` holds, and give offset NIF
  ##   cuts back to.
  var
    j = reader.items.len
    n = reader.openers.len
  while j > 0 and reader.items[j - 1].start >= start: dec j
  while n > 0 and reader.openers[n - 1].start >= start: dec n
  reader.openers.setLen(n)
  result = (if j < reader.items.len: reader.items[j].offset else: reader.nif.len)
  reader.items.setLen(j)
  reader.nif.setLen(result)


func addItems(
    reader: var ReaderLive, region: ReadingParts, leaves: openArray[seq[int]],
    spans: openArray[int], start: int, is_final: bool, change: var ChangeNif,
) =
  ## Put out node of each part of text read but last, and of each unit refused before it, on
  ##   line of its own; last part, and units after it, go out as tail. End puts out each.
  ##   `su` ends text before it, so each node up to it goes out at once, and node after it
  ##     takes nothing of node before it.
  ##   Part of no unit, of text of no unit read, goes out only where no part of its text went out
  ##   before, as whole text reads it: it stands last in first text, before first `su`.
  template children: untyped = region.reading.tree.children
    ## Alias nodes of root of text read, which `let` would copy.
  template units: untyped = region.reading.units
    ## Alias units of text read, which `let` would copy.
  template occurrences: untyped = region.reading.occurrences
    ## Alias words of text read, which `let` would copy.
  var
    first_su = children.len  # first leaf of `su` among children; count of them for none
    last_su = -1  # last leaf of `su` among children; -1 for none
    first_ended = children.len  # first leaf past text: `fa'o` that ends input, and words after
  for k in 0 ..< children.len:
    if not children[k].is_terminal: continue
    if units[children[k].at].isSu: (first_su, last_su) = (min(first_su, k), k)
    if region.faho.isSome and children[k].at >= region.faho.get:
      first_ended = min(first_ended, k)
  let
    hollow = min(first_su, first_ended) - 1  # child that may be part of no unit
    is_hollow = reader.items.len > 0 and reader.items[^1].is_parted and hollow >= 0 and
      not children[hollow].is_terminal and leaves[hollow].len == 0
  var order: seq[int]  # children that go out, now or as tail, in order
  for k in 0 ..< children.len:
    if not is_hollow or k != hollow: order.add k
  var count = order.len  # children of `order` that go out now
  if not is_final:
    count = 0
    for m in 0 ..< order.len:
      let k = order[m]
      if k == last_su: count = m + 1
      elif not children[k].is_terminal and leaves[k].len > 0: count = m
  for m in 0 ..< count:
    let k = order[m]
    var item = ItemLive(start: spans[k], offset: reader.nif.len, held: -1, start_reading: start)
    if children[k].is_terminal and units[children[k].at].isSu:
      item.is_su = true
      item.is_quoted = region.reading.byteAt(children[k].at) in region.quoted
    elif reader.items.len > 0:
      (item.last, item.held) = (reader.items[^1].last, reader.items[^1].held)
      item.is_parted = reader.items[^1].is_parted or not children[k].is_terminal
    else: item.is_parted = not children[k].is_terminal
    var read_last = -1  # unit read last
    for u in leaves[k]:
      template unit: untyped = units[u]
        ## Alias unit, which `let` would copy.
      if unit.is_read: (item.last, read_last) = (some(unit.terminal), u)
      if unit.is_read or unit.refusal == RefusalText.Selmaho:
        for w in unit.words: item.kept.add occurrences[w].reading.toTerminal
    if read_last >= 0:
      item.held = reader.items.len
      let most = children[k].stopMost
      if most > read_last: item.stop = some(region.reading.byteAt(most))
    let line = children[k].toNif(region.reading) & "\n"
    reader.nif.add line
    change.text.add line
    reader.items.add item
  for m in count ..< order.len: change.tail.add children[order[m]].toNif(region.reading) & "\n"
  reader.tail = change.tail
  reader.start = (if count < order.len: spans[order[count]] else: region.reading.size)
  reader.start_tail = region.reading.size
  for m in count ..< order.len:
    if leaves[order[m]].len > 0:
      reader.start_tail = region.reading.byteAt(leaves[order[m]][0])
      break


func addOpeners(
    reader: var ReaderLive, region: ReadingParts, leaves: openArray[seq[int]],
    spans: openArray[int], start: int,
) =
  ## Add each opener of text read from `start` that waits for its closer, in order of byte:
  ##   `tu'e`, `lu` and `to` left open, `lo'u` alone, and `zoi` no delimiter closes.
  ##   Opener of quotation with word erasure erased before it opens again at `start`, and its
  ##     closer reads text from it: closer may quote word that erased it, or change marker of
  ##     `sa` before it.
  func ownerAt(region: ReadingParts, owners: openArray[int], at: int): Option[int] =
    ## Give byte where child holding unit that holds word opening at byte `at` opens; none where
    ##   no unit holds such word.
    for u in 0 ..< region.reading.units.len:
      for w in region.reading.units[u].words:
        if region.reading.occurrences[w].start == at: return some(owners[u])
    none(int)

  template units: untyped = region.reading.units
    ## Alias units of text read, which `let` would copy.
  template occurrences: untyped = region.reading.occurrences
    ## Alias words of text read, which `let` would copy.
  var
    owners = newSeq[int](units.len)  # byte where span of child holding each unit opens
    holders = newSeq[int](occurrences.len)  # unit holding each word; -1 for none
    erased_first = int.high  # byte of first word erasure erased
    added: seq[OpenerLive]
  for k in 0 ..< leaves.len:
    for u in leaves[k]: owners[u] = spans[k]
  for w in 0 ..< occurrences.len: holders[w] = -1
  for u in 0 ..< units.len:
    for w in units[u].words: holders[w] = u
  for w in 0 ..< occurrences.len:
    template word: untyped = occurrences[w]
      ## Alias word, which `let` would copy.
    if not word.reading.is_word or (holders[w] >= 0 and not units[holders[w]].isErasure): continue
    let
      selmaho = word.reading.selmaho
      is_erasing = selmaho.isSome and selmaho.get in {Selmaho.Si, Selmaho.Sa, Selmaho.Su}
    if not is_erasing:
      erased_first = word.start
      break
  template opening(at: int, owner: Option[int]): int =
    ## Give byte where reading opens again at closer of opener of quotation at byte `at`.
    if owner.isNone or erased_first < at: start else: owner.get
  for u in region.open:
    added.add OpenerLive(
      selmaho: Selmaho(int(units[u].terminal)), at: region.reading.byteAt(u), start: owners[u],
    )
  for at in region.lohus:
    let owner = region.ownerAt(owners, at)
    added.add OpenerLive(selmaho: Selmaho.Lohu, at: at, start: opening(at, owner))
  for zoi in region.zois:
    let owner = region.ownerAt(owners, zoi.start)
    added.add OpenerLive(
      selmaho: Selmaho.Zoi, at: zoi.start, start: opening(zoi.start, owner),
      after: reader.text.byteQuoted(zoi.start, zoi.delimiter), delimiter: zoi.delimiter,
    )

  # `zoi` stream reads as no quotation, inside words `lo'u` quotes, takes three words after it
  #   as quotation once they come (`toRoles` of `prose.nim`), so it waits: alone, or erased.
  for w in 0 ..< occurrences.len:
    template word: untyped = occurrences[w]
      ## Alias word, which `let` would copy.
    if not word.reading.is_word or word.reading.selmaho != some(Selmaho.Zoi): continue
    var
      reads: seq[int]  # two words stream reads after it: delimiter, then text it quotes, if any
      next = w + 1
    while next < occurrences.len and reads.len < 2:
      template after: untyped = occurrences[next].reading
        ## Alias reading of word after, which `let` would copy.
      if after.is_word or after.refusal == Refusal.Foreign: reads.add next
      inc next
    let
      is_quoting = reads.len == 2 and not occurrences[reads[1]].reading.is_word
      u = holders[w]
      is_erased = u < 0 or units[u].isErasure
      is_whole = not is_erased and (not units[u].is_read or units[u].words.countIt(it > w) >= 3)
    if is_quoting or is_whole: continue  # stream quotes text, or unit holds its three words
    added.add OpenerLive(
      selmaho: Selmaho.Zoi, at: word.start,
      start: opening(word.start, if is_erased: none(int) else: some(owners[u])),
    )
  reader.openers.add added.sortedByIt(it.start)


func addRest(reader: var ReaderLive, first: int): ChangeNif =
  ## Put out each written word of text from byte `first` up to end of text read, past `fa'o`
  ##   that ends input, as unit of its own, which stream reads not (19.15); no text before it
  ##   reads again, since each node before `fa'o` went out once it read.
  result = ChangeNif(at: reader.nif.len, start: first)
  var at = first
  while at < reader.ending:
    if reader.text[at] in MARKS_BOUNDARY:
      inc at
      continue
    let start = at
    while at < reader.ending and reader.text[at] notin MARKS_BOUNDARY: inc at
    let
      ended = ReadingMarked(
        occurrences: @[reader.text.occurrenceEnded(start, at)],
        units: @[Unit(words: @[0], is_read: false, refusal: RefusalText.Stream)],
      )
      line = Node(is_terminal: true, at: 0).toNif(ended) & "\n"
    reader.items.add ItemLive(start: start, offset: reader.nif.len, held: -1, start_reading: start)
    reader.nif.add line
    result.text.add line
  reader.start_tail = reader.ending


func readChange(reader: var ReaderLive, at: int, is_final: bool): ChangeNif =
  ## Read text from byte `at` on, back as far as it reaches, and give change to NIF: node of each
  ##   part from first node read again, as each goes out, then tail of part still open.
  var
    start = reader.boundary(at)
    region = reader.readFrom(start, is_final)
  while true:
    let back = reader.reach(region, start)
    if back.isNone or back.get >= start: break
    start = reader.boundary(back.get)
    region = reader.readFrom(start, is_final)
  var leaves = newSeq[seq[int]](region.reading.tree.children.len)
  for k in 0 ..< leaves.len: region.reading.tree.children[k].addLeaves(leaves[k])
  (result.at, result.start) = (reader.cut(start), start)
  let spans = region.toSpans(leaves, start)
  reader.addItems(region, leaves, spans, start, is_final or region.faho.isSome, result)
  if is_final: return
  reader.addOpeners(region, leaves, spans, start)
  if region.faho.isNone: return
  let faho = region.reading.byteAt(region.faho.get)
  var stop = faho
  while stop < reader.text.len and reader.text[stop] notin MARKS_BOUNDARY: inc stop
  reader.stop = some(stop)
  var k = 0  # child holding `fa'o`, whose span end reads again from
  while k < spans.high:
    template child: untyped = region.reading.tree.children[k]
      ## Alias child of root, which `let` would copy.
    if child.is_terminal and child.at == region.faho.get: break
    inc k
  reader.start = min(reader.start, spans[k])  # end reads `fa'o` again



#[ Live text ]#

func push*(reader: var ReaderLive, piece: string): ChangeNif =
  ## Read next piece of live text, and give change it makes to NIF: nodes that go out, and tail
  ##   of part still open. Piece may cut word, which next piece ends.
  doAssert not reader.is_ended, "Live text should take no piece after its end."
  reader.text.add piece
  var ending = reader.text.len  # text read ends past last mark between words
  while ending > reader.ending and reader.text[ending - 1] notin MARKS_BOUNDARY: dec ending
  if ending == reader.ending:
    return ChangeNif(at: reader.nif.len, start: reader.start_tail, tail: reader.tail)  # none new
  for n in 0 ..< reader.openers.len:
    template opener: untyped = reader.openers[n]
      ## Alias opener, which `let` would copy.
    if reader.stop.isNone: break
    let is_closing = opener.selmaho == Selmaho.Zoi and opener.at < reader.stop.get and
      reader.text.isSpelled(max(reader.ending, opener.after), ending, opener.delimiter)
    if is_closing: reader.stop = none(int)  # `zoi` before `fa'o` quotes it once closed
  let first = reader.ending  # text not read yet
  reader.ending = ending
  if reader.stop.isSome: return reader.addRest(first)
  reader.readChange(reader.start, is_final = false)


func finish*(reader: var ReaderLive): ChangeNif =
  ## Read end of live text: text from first opener still waiting on reads as whole text does, and
  ##   each node left goes out, so NIF holds node of each part of text.
  doAssert not reader.is_ended, "Live text should end once."
  reader.is_ended = true
  var start = reader.start
  for n in 0 ..< reader.openers.len: start = min(start, reader.openers[n].start)
  reader.readChange(start, is_final = true)
