## Read live text as it arrives, piece by piece: each sentence goes out as NIF once it ends, and
##   word that reaches back cuts NIF back, so live text of hours reads in time its length gives
##   (#859).
##
##   |----------------|--------------------------------------------------------------------|
##   | Code           | Meaning                                                            |
##   |----------------|--------------------------------------------------------------------|
##   | ReaderLive     | text so far, NIF that went out, and openers that wait for closers  |
##   | ChangeNif      | change piece makes to NIF: offset it cuts back to, nodes, and tail |
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
##       where that node opens: cursor, as `ChangeNif` gives it.
##     Node of part still open goes out as tail, which next change replaces, so tree grows word
##       by word, as program that animates it may show.
##   Piece may cut word, so text read stops before last written word no mark ends: `su` that
##     next piece makes `su'i` erases nothing. Text read opens at span of node: its first word,
##     past words of node before, so span holds each word erasure erased before node. Node
##     shares span before it where quotation holds word span would open at, or where its first
##     word stands among words of node before, as word stream refuses between word and `bu`.
##   Reach back, from text read again to node before it:
##     `si` that finds no word, back as many words as it erases; `bu` or `zei` that finds none,
##       to word before; `sa` that finds no marker, to node holding it, or to start (19.13).
##     First unit read that opens no part, as `zei` joining `.i` to word after it, to node holding
##       unit read last; error node whose stop names unit read after it, once that unit changes.
##     Closer of opener that waits, to node holding opener.
##     `su` erases text before it (19.13), so NIF cuts back to its directives, and no piece reads
##       text before it again. Quotation that waits before `su` may quote it once closed, so its
##       closer reads text again from start; so does erasure past `su`, or `su` that erases no
##       more, as `zo su si` once `sa` erases `zo` (19.10, 19.13).
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
##     before it comes, which quotes it; end reads past it.
##   Laws: at end, NIF of text read piece by piece is NIF of its parts read whole; before end,
##     NIF and tail of each change are parts of text so far, to its last mark, read whole as
##     live text (`test_live.nim`).
##   Cost: each piece reads part still open again, so time grows with length of text times
##     length of sentence; reach back reads from node where it lands, once. Closer of quotation
##     before `su`, or erasure past it, reads text again from start.
##   Reader loops by index, since `items` copies on JavaScript backend.

{.experimental: "strictFuncs".}

import std/[algorithm, options, sequtils, strutils]

import ./[grammar, nif, prose, selmaho, stream, tanru]


type
  ChangeNif* = object  ## Define change one piece makes to NIF of live text.
    at*: int  ## Offset in NIF where change opens: NIF from it on drops, then `text` follows.
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
    stop: Option[int]
      ## Byte of unit read after it, which stop of its error node names; none where no stop
      ##   names unit past its own.

  OpenerLive = object  ## Define opener that waits for its closer in text so far.
    selmaho: Selmaho  ## Selma'o of opener: TUhE, LU, TO, LOhU, or ZOI for `zoi` and `la'o`.
    at: int  ## Byte where its word opens.
    start: int  ## Byte where span of node holding it opens, which its closer reads again from.
    after: int  ## Byte where text `zoi` quotes opens, past its delimiter; 0 for other opener.
    delimiter: string
      ## Delimiter of `zoi`, which closes it; empty for other opener, and for `zoi` that takes
      ##   three words after it, inside words `lo'u` quotes, which each word closes.
    is_erased: bool  ## `su` after it erased each node before it, which its closer brings back.

  ReaderLive* = object  ## Define reader of live text: text so far, NIF out, openers waiting.
    text: string
    nif: string  ## Directives, then line of each node that went out.
    tail: string  ## NIF of each node still open, as last change gives it.
    items: seq[ItemLive]  ## Each node that went out, in order.
    openers: seq[OpenerLive]  ## Each opener waiting, in order of byte.
    start: int  ## Byte where text not yet out opens.
    floor: int
      ## Byte where written word holding last `su` opens, which reading may open again at, since
      ##   `su` erases text before it; 0 where none.
    count_read: int  ## Bytes each reading has read, summed; cost check reads it.
    ending: int  ## Byte where text read last ends: past last mark between words.
    stop: Option[int]
      ## Byte past written word of `fa'o` that ends input (19.15), where each piece stops reading;
      ##   none before. End reads past it, since closer of opener before may quote it.
    is_ended: bool  ## End of live text was read.


const SELMAHO_QUOTING = {Selmaho.Lohu, Selmaho.Zoi}
  ## Selma'o of opener of quotation, which quotes `su` after it once its closer comes.


func initReaderLive*(): ReaderLive =
  ## Make reader of live text, whose NIF holds directives alone.
  ReaderLive(nif: HEADER)


func toNif*(reader: ReaderLive): string = reader.nif
  ## Give NIF that went out so far: directives, then line of each node.

func countRead*(reader: ReaderLive): int = reader.count_read
  ## Give bytes each reading of text has read, summed: cost, which grows with length of text
  ##   times length of sentence.



#[ Text read ]#

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
  ##   erased; or where word stream reads before its first word is `sa` no unit holds, whose
  ##   marker that word gives, past each word stream refuses (19.13).
  template units: untyped = region.reading.units
    ## Alias units of text read, which `let` would copy.
  template occurrences: untyped = region.reading.occurrences
    ## Alias words of text read, which `let` would copy.
  let cleans = occurrences.toCleans
  var is_helds = newSeq[bool](occurrences.len)  # some unit holds word
  for u in 0 ..< units.len:
    for w in units[u].words: is_helds[w] = true
  result = newSeq[int](leaves.len)
  var next = 0  # word past words of children before
  for k in 0 ..< leaves.len:
    var before = (if leaves[k].len > 0: units[leaves[k][0]].words[0] else: next) - 1
    while before >= 0 and not occurrences[before].reading.is_word: dec before
    let
      is_among = leaves[k].len > 0 and units[leaves[k][0]].words[0] < next
      is_marked = before >= 0 and not is_helds[before] and
        occurrences[before].reading.selmaho == some(Selmaho.Sa)
    if k == 0: result[k] = first
    elif is_among or is_marked or (next < occurrences.len and not cleans[next]):
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
  for occurrence in result.reading.occurrences.mitems: occurrence.start += start
  result.reading.size = ending
  for zoi in result.zois.mitems: zoi.start += start
  for lohu in result.lohus.mitems: lohu += start
  if result.su.isSome: result.su = some(result.su.get + start)



#[ Reach back ]#

func boundary(reader: ReaderLive, at: int): int =
  ## Give byte at or before `at` where reading may open again: where node holding first byte of
  ##   written word holding `at` opens, since stream reads each written word whole. With no node
  ##   there, written word of last `su`, which erases text before it, or that word, if earlier.
  result = at
  while result > 0 and reader.text[result - 1] notin MARKS_BOUNDARY:
    var first = result - 1
    while first > 0 and reader.text[first - 1] notin MARKS_BOUNDARY: dec first
    var k = reader.items.high
    while k >= 0 and reader.items[k].start > first: dec k
    result = (if k >= 0: reader.items[k].start else: min(first, reader.floor))


func reach(reader: ReaderLive, region: ReadingParts, start: int): Option[int] =
  ## Give earliest byte before `start` that reading of text from `start` reaches: node holding
  ##   opener whose closer text holds, node where its erasure lands, node its first unit read
  ##   joins, and node whose stop names unit read after it; none where text before reads as it
  ##   did.
  func earlier(back: Option[int], at: int): Option[int] =
    ## Give earlier of byte kept and `at`.
    some(if back.isSome: min(back.get, at) else: at)

  template units: untyped = region.reading.units
    ## Alias units of text read, which `let` would copy.
  template occurrences: untyped = region.reading.occurrences
    ## Alias words of text read, which `let` would copy.
  var
    back = none(int)
    j = reader.items.len  # nodes before `start`
  while j > 0 and reader.items[j - 1].start >= start: dec j

  # Closer of `tu'e`, `lu` or `to` that no opener of text opens closes opener of its kind that
  #   waits, nearest first, as passes track them (`toParts`).
  var
    strays: array[OPENERS.len, int]  # closers of each kind that close no opener of text
    opened: seq[int]  # kind of each opener open in text, innermost last
  for u in 0 ..< units.len:
    if not units[u].is_read: continue
    for k in 0 ..< OPENERS.len:
      if units[u].terminal == OPENERS[k].toTerminal: opened.add k
      if units[u].terminal != CLOSERS[k].toTerminal: continue
      var n = opened.high
      while n >= 0 and opened[n] != k: dec n
      if n >= 0: opened.setLen(n) else: inc strays[k]
  for k in 0 ..< OPENERS.len:
    var
      left = strays[k]
      n = reader.openers.high
    while left > 0 and n >= 0:
      if reader.openers[n].selmaho == OPENERS[k]:
        back = back.earlier(reader.openers[n].start)
        dec left
      dec n

  # Closer of quotation: `le'u` closes first `lo'u` that waits, which quotes each after it, and
  #   delimiter its `zoi`. Quotation `su` follows quotes `su` once closed, so reads from start.
  if occurrences.isClosingLohu:
    var n = 0
    while n < reader.openers.len and reader.openers[n].selmaho != Selmaho.Lohu: inc n
    if n < reader.openers.len:
      back = back.earlier(if reader.openers[n].is_erased: 0 else: reader.openers[n].start)
  for n in 0 ..< reader.openers.len:
    template opener: untyped = reader.openers[n]
      ## Alias opener, which `let` would copy.
    if opener.selmaho != Selmaho.Zoi: continue
    let is_closing = opener.delimiter.len == 0 or
      reader.text.isSpelled(max(start, opener.after), region.reading.size, opener.delimiter)
    if is_closing: back = back.earlier(if opener.is_erased: 0 else: opener.start)
  if region.su.isNone and 0 < start and start <= reader.floor:
    back = back.earlier(0)  # `su` that erased each node before text erases none now
  if region.su.isSome: return back  # `su` erases each node before text

  # `si` that finds no word erases words of nodes before, last first; `bu` or `zei` that finds
  #   none acts on last word of nodes before, where no word kept stands before it (19.13, 19.16).
  var
    deficit = 0
    is_kept = false  # word kept stands before unit
  for u in 0 ..< units.len:
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
  if j == 0:  # erasure past `su` before text, which quotation waiting may quote
    let is_past = deficit > 0 or region.markers.len > 0
    if is_past and reader.openers.anyIt(it.is_erased): back = back.earlier(0)
    return back
  if deficit > 0:
    var k = j - 1
    while k > 0 and reader.items[k].kept.len < deficit:
      deficit -= reader.items[k].kept.len
      dec k
    back = back.earlier(reader.items[k].start)

  # `sa` that finds no marker in text erases back to node holding it, or to start (19.13).
  for marker in region.markers:
    var k = j - 1
    while k > 0 and marker notin reader.items[k].kept: dec k
    back = back.earlier(reader.items[k].start)

  # First unit read opens part only where it opens one after unit read before (`isCutAt`); and
  #   stop that names unit read after node names first unit read here.
  let held = reader.items[j - 1].held
  if held < 0: return back
  var terminals: seq[Terminal]
  for u in 0 ..< units.len:
    if units[u].is_read: terminals.add units[u].terminal
  var first = none(int)  # byte of first unit read
  for u in 0 ..< units.len:
    if units[u].is_read:
      first = some(region.reading.byteAt(u))
      break
  let is_joined = terminals.len > 0 and not terminals.isCutAt(0, reader.items[j - 1].last)
  if is_joined or (reader.items[held].stop.isSome and reader.items[held].stop != first):
    back = back.earlier(reader.items[held].start)
  back



#[ Change of NIF ]#

func cut(reader: var ReaderLive, start: int, region: ReadingParts): int =
  ## Cut nodes, openers and NIF back to first node text from `start` holds, and give offset NIF
  ##   cuts back to. `su` erases each node before it, so NIF cuts back to its directives, and
  ##   opener of quotation alone still waits, since its closer may quote `su`.
  var
    j = reader.items.len
    n = reader.openers.len
  while j > 0 and reader.items[j - 1].start >= start: dec j
  while n > 0 and reader.openers[n - 1].start >= start: dec n
  reader.openers.setLen(n)
  if region.su.isSome:
    j = 0
    reader.openers.keepItIf(it.selmaho in SELMAHO_QUOTING)
    for opener in reader.openers.mitems: opener.is_erased = true
    reader.floor = region.su.get
    template occurrences: untyped = region.reading.occurrences
      ## Alias words of text read, which `let` would copy.
    var k = occurrences.high  # word before `su`, past words stream refuses
    while k >= 0 and occurrences[k].start >= reader.floor: dec k
    while k >= 0 and not occurrences[k].reading.is_word: dec k
    if k >= 0 and occurrences[k].reading.selmaho == some(Selmaho.Zo):
      reader.floor = occurrences[k].start  # `zo` quotes `su` once erasure leaves its word
    while reader.floor > 0 and reader.text[reader.floor - 1] notin MARKS_BOUNDARY:
      dec reader.floor
  elif start <= reader.floor:
    reader.floor = 0  # `su` that set it is quoted now
  result = (if j < reader.items.len: reader.items[j].offset else: reader.nif.len)
  reader.items.setLen(j)
  reader.nif.setLen(result)


func addItems(
    reader: var ReaderLive, region: ReadingParts, leaves: openArray[seq[int]],
    spans: openArray[int], is_final: bool, change: var ChangeNif,
) =
  ## Put out node of each part of text read but last, and of each unit refused before it, on
  ##   line of its own; last part, and units after it, go out as tail. End puts out each.
  ##   Part of no unit, of text of no unit read, goes out only where no node before holds unit
  ##   read, as whole text reads it.
  template children: untyped = region.reading.tree.children
    ## Alias nodes of root of text read, which `let` would copy.
  template units: untyped = region.reading.units
    ## Alias units of text read, which `let` would copy.
  template occurrences: untyped = region.reading.occurrences
    ## Alias words of text read, which `let` would copy.
  let is_held = reader.items.len > 0 and reader.items[^1].held >= 0
  var size = children.len  # children that go out, now or as tail
  if is_held and size > 0 and not children[^1].is_terminal and leaves[^1].len == 0: dec size
  var count = size  # children that go out now
  if not is_final:
    count = 0
    for k in 0 ..< size:
      if not children[k].is_terminal and leaves[k].len > 0: count = k
  for k in 0 ..< count:
    var item = ItemLive(start: spans[k], offset: reader.nif.len, held: -1)
    if reader.items.len > 0:
      (item.last, item.held) = (reader.items[^1].last, reader.items[^1].held)
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
  for k in count ..< size: change.tail.add children[k].toNif(region.reading) & "\n"
  reader.tail = change.tail
  reader.start = (if count < size: spans[count] else: region.reading.size)


func addOpeners(
    reader: var ReaderLive, region: ReadingParts, leaves: openArray[seq[int]],
    spans: openArray[int], start: int,
) =
  ## Add each opener of text read from `start` that waits for its closer, in order of byte:
  ##   `tu'e`, `lu` and `to` left open, `lo'u` alone, and `zoi` no delimiter closes.
  ##   Opener of quotation `su` erased opens again at `start`, and its closer reads text from
  ##     start. So does opener of quotation with word erasure erased before it: its closer may
  ##     quote word that erased it, or change marker of `sa` before it.
  func ownerAt(region: ReadingParts, owners: openArray[int], at: int): Option[int] =
    ## Give byte where child holding unit refused that opens at byte `at` opens; none where `su`
    ##   dropped that unit.
    for u in 0 ..< region.reading.units.len:
      if not region.reading.units[u].is_read and region.reading.byteAt(u) == at:
        return some(owners[u])
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
    if holders[w] >= 0 or not word.reading.is_word: continue
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
    added.add OpenerLive(
      selmaho: Selmaho.Lohu, at: at, start: opening(at, owner), is_erased: owner.isNone,
    )
  for zoi in region.zois:
    let owner = region.ownerAt(owners, zoi.start)
    added.add OpenerLive(
      selmaho: Selmaho.Zoi, at: zoi.start, start: opening(zoi.start, owner),
      is_erased: owner.isNone,
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
      is_erased = region.su.isSome and word.start < region.su.get
      is_whole = u >= 0 and (not units[u].is_read or units[u].words.countIt(it > w) >= 3)
    if is_quoting or is_whole: continue  # stream quotes text, or unit holds its three words
    added.add OpenerLive(
      selmaho: Selmaho.Zoi, at: word.start, is_erased: is_erased,
      start: opening(word.start, if u >= 0: some(owners[u]) else: none(int)),
    )
  reader.openers.add added.sortedByIt(it.start)


func faho(region: ReadingParts): Option[int] =
  ## Give byte of `fa'o` no unit holds that stream of text read stops at, which ends input
  ##   (19.15); none where stream reads to end.
  template occurrences: untyped = region.reading.occurrences
    ## Alias words of text read, which `let` would copy.
  template units: untyped = region.reading.units
    ## Alias units of text read, which `let` would copy.
  if occurrences.len == 0 or not occurrences[^1].reading.is_word: return none(int)
  if occurrences[^1].reading.selmaho != some(Selmaho.Faho): return none(int)
  for u in 0 ..< units.len:
    if units[u].words[^1] == occurrences.high: return none(int)  # quotation holds `fa'o`
  some(occurrences[^1].start)


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
  result.at = reader.cut(start, region)
  let spans = region.toSpans(leaves, if region.su.isSome: reader.floor else: start)
  reader.addItems(region, leaves, spans, is_final, result)
  if is_final: return
  reader.addOpeners(region, leaves, spans, start)
  let faho = region.faho
  if faho.isNone: return
  var stop = faho.get
  while stop < reader.text.len and reader.text[stop] notin MARKS_BOUNDARY: inc stop
  reader.stop = some(stop)
  reader.start = min(reader.start, faho.get)  # each piece reads `fa'o` again



#[ Live text ]#

func push*(reader: var ReaderLive, piece: string): ChangeNif =
  ## Read next piece of live text, and give change it makes to NIF: nodes that go out, and tail
  ##   of part still open. Piece may cut word, which next piece ends.
  doAssert not reader.is_ended, "Live text should take no piece after its end."
  reader.text.add piece
  var ending = reader.text.len  # text read ends past last mark between words
  while ending > reader.ending and reader.text[ending - 1] notin MARKS_BOUNDARY: dec ending
  if ending == reader.ending:
    return ChangeNif(at: reader.nif.len, tail: reader.tail)  # nothing more to read
  for n in 0 ..< reader.openers.len:
    template opener: untyped = reader.openers[n]
      ## Alias opener, which `let` would copy.
    if reader.stop.isNone: break
    let is_closing = opener.selmaho == Selmaho.Zoi and opener.at < reader.stop.get and
      reader.text.isSpelled(max(reader.ending, opener.after), ending, opener.delimiter)
    if is_closing: reader.stop = none(int)  # `zoi` before `fa'o` quotes it once closed
  reader.ending = ending
  reader.readChange(reader.start, is_final = false)


func finish*(reader: var ReaderLive): ChangeNif =
  ## Read end of live text: text from first opener still waiting on reads as whole text does, and
  ##   each node left goes out, so NIF holds node of each part of text.
  doAssert not reader.is_ended, "Live text should end once."
  reader.is_ended = true
  var start = reader.start
  for n in 0 ..< reader.openers.len: start = min(start, reader.openers[n].start)
  reader.readChange(start, is_final = true)
