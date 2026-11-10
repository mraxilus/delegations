## Hold reading that marks each error to its laws (#859): `readTextMarked` reads text as
##   `readText` does, and reads on past each error, marking it in tree and in NIF.
##   Text `readText` reads gives same units, tree and NIF, over corpora, past last `su`, and once
##     each unit of words no stage reads is cut: text before `su` stands first in root, each with
##     leaf of `su` after it; and words erasure erases, and `fa'o` with words after it, stand as
##     units of their own, which `readText` reads not (19.13, 19.15).
##   Text it refuses still gives tree: each unit stands in it once as leaf, in order; refusal of
##     `readText` is mark of its stage there; and NIF reads back whole (`reader_nif.nim`). Laws
##     run over corpora, and over texts constructed for each stage, since corpora refuse at
##     neither quotation nor construct.
##   Grammar: each branch error node holds that heads `text` is tree its terminals give read
##     alone; each class `expects` names lets grammar read past place it stops, and each other
##     class does not.
##   Cover of error node is least: no terminal it leaves out reads alone, and no two pieces
##     side by side read as one `text`, since branch over them would leave fewer out, or take
##     fewer pieces. Cover that ties stays unchecked: no law reads which cover tie gives.
##   Corpora: as `test_nif.nim` reads them (`corpora.nim`).

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[options, sequtils, unittest]

import ../../src/lojban_parser/grammar {.all.}
import ../../src/lojban_parser/[nif, prose, selmaho, stream, tanru]
import ./[corpora, reader_nif]


type
  Refused = tuple[key, text: string, strict: ReadingText, marked: ReadingMarked]
    ## Define text `readText` refuses, with both readings of it.

  Pool = object  ## Define texts suite reads, each read once by both readers.
    count_read: int  ## Texts of corpora that read.
    differing: seq[string]  ## Key of each text that reads whose reading marked differs.
    refused: seq[Refused]  ## Each text of corpora refused, then each text constructed.
    uncovered: seq[string]
      ## Key of each text of corpora whose words no tree of it covers, once and in order, as
      ##   marked reading and reading of its parts give it (`isCovering`).


const
  COUNT_READ_LEAST = 1800  ## Texts of corpora that read, of 1,941; law reads each marked.
  COUNT_REFUSED_LEAST = 100  ## Texts of corpora `readText` refuses, of 1,941; 110 on adding marks.
  COUNT_COVERS_LEAST = 90
    ## Error nodes that hold branches, in texts refused of corpora and constructed; 94 on adding
    ##   law of cover.
  COUNT_EXPECTED = 24
    ## Stops law of `expects` reads: first texts refused by grammar, of corpora then
    ##   constructed, whose stop takes at most `STOP_EXPECTED_MOST` terminals; 57 qualify.
    ##   Law reads text there once for each of 124 classes, about 2 s of debug build.
  STOP_EXPECTED_MOST = 8  ## Terminals before stop, at most, for law of `expects`.
  TEXTS_CONSTRUCTED = [
    "mi 1987 klama", "mi hello klama", "Mi klama", "zoi gy. gyrations .gy. cu glico",
    "la .lauras. klama",  # stream: letter, letter, stress, quotation, split
    "mi xau klama", "ba'e xau klama",  # selma'o, with BAhE marking cmavo
    "zei mi klama", "mi zei", "si mi klama", "mi klama sa", "bu mi", "mi klama ba'e",  # construct
    "mi cusku lo'u mi klama", "mi cusku lo'u .i mi klama", "mi cusku zo", "lo'u le'u",
    "mi se cmene zo .djan. si .djordj.",  # quotation: never closed, empty, part erased (19.13)
    "mi klama le", "mi klama le .i do citka", "lu mi klama le", "ge mi gi",
    "mi klama le zarci ku ku",  # grammar: text cut off, part, `lu` open, connective, terminator
    "si mi 1987 xau klama le",  # each stage at once
    "si su mi klama", "mi 1987 su klama", "lu mi su do li'u",  # `su` ending text with error
  ]
    ## Texts constructed for each stage that refuses, and for each place grammar stops.
  TEXTS_PARTED = [
    "mi klama su do", "mi su", "su do", "mi su su do", "ba'e su mi", "mi ui su ui do",
    "mi klama le su do", "lu mi su do", "lo'u mi su do le'u", "mi cusku zo su",
    "mi klama si do", "do sa mi klama", "mi si su do si ko", "mi fa'o .i ko 1987",
    "ba'e mi si do",  # erasure, and `fa'o` with words after it
  ]
    ## Texts `readText` reads that `su` parts, with error before it, `su` quoted, or none; then
    ##   texts holding words no stage reads; constructed, since corpora hold no `su` that parts
    ##   text.
  TEXTS_COVERED = [
    "le,nu mi klama", "mi KLAmaku", "zoi gy. a, b .gy. cu glico", "mi klama si si fa'omi do",
    "mi 1987 ui", "ba'e mi si do", "lo'u mi su do", "zo su si si", "mi klama fa'o\t.ui\n",
  ]
    ## Texts of comma and capital, quotation holding marks, words no unit holds, and word between
    ##   word and indicator that marks it, for law of cover; constructed.
  EXAMPLES_MARKED = [
    (
      text: "mi 1987 klama",
      module: "(sentence 0 40 (sumti_6 80 97 (KOhA 0 2 \"mi\")) " &
        "(unread Stream Letter 3 7 \"1987\") (bridi_tail_3 50 53 " &
        "(tanru_unit_2 130 152 (BRIVLA 8 13 \"klama\")) (tail_terms 71)))",
    ),  # written word stream refuses, between sumti and bridi tail around it
    (
      text: "mi xau klama",
      module: "(sentence 0 40 (sumti_6 80 97 (KOhA 0 2 \"mi\")) (unread Selmaho 3 6 \"xau\") " &
        "(bridi_tail_3 50 53 (tanru_unit_2 130 152 (BRIVLA 7 12 \"klama\")) (tail_terms 71)))",
    ),  # cmavo no list gives selma'o
    (
      text: "zei mi klama",
      module: "(text 0 (unread Construct 0 3 \"zei\") (sentence 2 40 (sumti_6 80 97 " &
        "(KOhA 4 6 \"mi\")) (bridi_tail_3 50 53 (tanru_unit_2 130 152 (BRIVLA 7 12 \"klama\")) " &
        "(tail_terms 71))))",
    ),  # `zei` joining no word before it, in root before all units read (4.6)
    (
      text: "mi cusku lo'u .i mi klama",
      module: "(paragraph 0 10 (sentence 11 40 (sumti_6 80 97 (KOhA 0 2 \"mi\")) (bridi_tail_3 " &
        "50 53 (tanru_unit_2 130 152 (BRIVLA 3 8 \"cusku\")) (tail_terms 71))) " &
        "(unread Quotation 9 13 \"lohu\") (I 15 16 \"i\") (sentence 11 40 (sumti_6 80 97 " &
        "(KOhA 17 19 \"mi\")) (bridi_tail_3 50 53 " &
        "(tanru_unit_2 130 152 (BRIVLA 20 25 \"klama\")) (tail_terms 71))))",
    ),  # `lo'u` no `le'u` closes stands alone, and words after it read on (19.9, #859)
    (
      text: "mi klama le",
      module: "(error 11 sumti_6 97 (expects BAI BU BY CAhA COI CUhE DOI FAhA FEhE FIhO GOI " &
        "GOhA GUhA JAI KE KI KOhA LA LAU LAhE LE LI LOhU LU ME MOhI NA NAhE NOI NU NUhA PA PU " &
        "SE SEI SOI TAhE TEI TO VA VEI VEhA VIhA XI ZAhO ZEI ZEhA ZI ZO ZOI BRIVLA) " &
        "(sentence 0 40 (sumti_6 80 97 (KOhA 0 2 \"mi\")) (bridi_tail_3 50 53 " &
        "(tanru_unit_2 130 152 (BRIVLA 3 8 \"klama\")) (tail_terms 71))) (LE 9 11 \"le\"))",
    ),  # text cut off after `le`: grammar stops at its end, in `sumti-6` 97, which waits
    (
      text: "mi klama su do",
      module: "(text 0 (sentence 0 40 (sumti_6 80 97 (KOhA 0 2 \"mi\")) (bridi_tail_3 50 53 " &
        "(tanru_unit_2 130 152 (BRIVLA 3 8 \"klama\")) (tail_terms 71))) (unread Su 9 11 \"su\") " &
        "(sumti_6 2 97 (KOhA 12 14 \"do\")))",
    ),  # `su` ends text before it, which stays as it read, before text after it (ruling on #859)
    (
      text: "mi klama si do fa'o ko",
      module: "(text 0 (terms 2 80 (sumti_6 81 97 (KOhA 0 2 \"mi\")) " &
        "(unread Erasure 3 8 \"klama\" 9 11 \"si\") (sumti_6 81 97 (KOhA 12 14 \"do\"))) " &
        "(unread Faho 15 19 \"faho\") (unread Stream Faho 20 22 \"ko\"))",
    ),  # words `si` erases, with `si`; `fa'o` that ends input, and word after it, as written
  ]
    ## Texts constructed, and root node of module `nif.nim` writes for each, byte for byte.



#[ Readers ]#

func leaves(node: Node): seq[int] =
  ## List index of each leaf under node, in order of tree.
  if node.is_terminal: return @[node.at]
  for child in node.children: result.add child.leaves


func isRead(marked: ReadingMarked, unit: Unit): bool =
  ## Decide whether some stage reads unit, or refuses it: unit is no `su`, words erasure erases,
  ##   `fa'o` that ends input, nor word after it.
  if unit.is_read: return true
  if unit.refusal in {RefusalText.Su, RefusalText.Erasure, RefusalText.Faho}: return false
  unit.refusal != RefusalText.Stream or
    marked.occurrences[unit.words[0]].reading.refusal != Refusal.Faho


func dropUnread(node: var Node, marked: ReadingMarked) =
  ## Cut each leaf of unit no stage reads from node, as `isRead` gives.
  if node.is_terminal: return
  node.children.keepItIf(not it.is_terminal or marked.isRead(marked.units[it.at]))
  for child in node.children.mitems: child.dropUnread(marked)


func isHolding(marked: ReadingMarked, unit: Unit, start: int): bool =
  ## Decide whether unit holds word whose bytes, as text writes them, hold byte `start`.
  for k in unit.words:
    let occurrence = marked.occurrences[k]
    if occurrence.start <= start and start < occurrence.start + occurrence.text.len: return true
  false


func isMarking(marked: ReadingMarked, strict: ReadingText): bool =
  ## Decide whether refusal of `readText` is mark of its stage in marked reading: unit of
  ##   written word stream refuses holding its byte; unit of rule of 19.16 refusing it, where
  ##   stream refuses none; unit of selma'o holding its byte, where only selma'o refuses; error
  ##   node at root with its rule, stopping at its byte, where every unit reads. Unit no stage
  ##   reads is no refusal, so law reads it not (`isRead`).
  let refused = marked.units.filterIt(not it.is_read and marked.isRead(it))
  case strict.refusal
  of RefusalText.Stream:
    refused.anyIt(it.refusal == RefusalText.Stream and marked.isHolding(it, strict.start))
  of RefusalText.Construct, RefusalText.Quotation:
    refused.allIt(it.refusal != RefusalText.Stream) and refused.anyIt(it.refusal == strict.refusal)
  of RefusalText.Selmaho:
    refused.allIt(it.refusal == RefusalText.Selmaho) and
      refused.anyIt(marked.isHolding(it, strict.start))
  of RefusalText.Grammar:
    let
      tree = marked.tree
      at = (if tree.stop.isSome: tree.stop.get.at else: marked.units.len)
      start =
        if at < marked.units.len: marked.occurrences[marked.units[at].words[0]].start
        else: marked.size
    refused.len == 0 and tree.stop.isSome and tree.rule & " " & $tree.number == strict.rule and
      start == strict.start
  of RefusalText.Su, RefusalText.Erasure, RefusalText.Faho: false
    # `readText` refuses no text for stage that reads no words


func terminalsRead(marked: ReadingMarked): seq[Terminal] =
  ## Give terminal of each unit grammar reads, in order.
  for unit in marked.units:
    if unit.is_read: result.add unit.terminal


func isSameShifted(a, b: Node, by: int): bool =
  ## Decide whether tree `a` is tree `b` with index of each terminal moved by `by`: same rules,
  ##   numbers and places grammar stops at, in same order.
  if a.is_terminal != b.is_terminal: return false
  if a.is_terminal: return a.at == b.at + by
  if a.rule != b.rule or a.number != b.number or a.children.len != b.children.len: return false
  if a.stop.isSome != b.stop.isSome: return false
  for k in 0 ..< a.children.len:
    if not a.children[k].isSameShifted(b.children[k], by): return false
  true


func addBranches(node: Node, branches: var seq[Node]) =
  ## Add each branch error node under `node` holds that heads `text`, which reads alone.
  if node.is_terminal: return
  for child in node.children:
    if node.stop.isSome and not child.is_terminal and child.stop.isNone and child.number == 0:
      branches.add child
    child.addBranches(branches)


func covers(tree: Node, terminals: openArray[Terminal]): seq[Node] =
  ## Give each error node of tree that holds branches, and terminals between them: root of text
  ##   of one part, else each error node of part that text cut into parts holds (`toParts`).
  if tree.stop.isNone: return
  let
    split = terminals.toParts(0, terminals.len)
    is_parted = split.parts.len > 1 or split.inner < terminals.len
  if not is_parted: return @[tree]
  for child in tree.children:
    if not child.is_terminal and child.stop.isSome: result.add child


func classes(): seq[Terminal] =
  ## Give each class of terminal grammar reads: each selma'o, then `BRIVLA` and `CMENE`.
  for selmaho in Selmaho: result.add selmaho.toTerminal
  result.add TERMINAL_BRIVLA
  result.add TERMINAL_CMENE


func isReadPast(terminals: openArray[Terminal], at: int): bool =
  ## Decide whether grammar reads terminals past place `at`: whole, or stopping after it.
  let reading = terminals.readGrammar
  reading.is_read or reading.at > at

func isSame(marked: ReadingMarked, strict: ReadingText): bool =
  ## Decide whether reading marked holds each unit once, as leaf in order, and units, words and
  ##   NIF of reading that reads past last `su`: root holds tree of each text before it first,
  ##   each with leaf of `su` after it, which law cuts; and law cuts each leaf of unit no stage
  ##   reads, as words erasure erases, and `fa'o` with words after it.
  var
    first = 0  # first unit past last `su`
    cut = 0  # children of root up to leaf of last `su`
  for k in 0 ..< marked.units.len:
    if not marked.units[k].is_read and marked.units[k].refusal == RefusalText.Su: first = k + 1
  for k in 0 ..< marked.tree.children.len:
    template child: untyped = marked.tree.children[k]
      ## Alias child of root, which `let` would copy.
    if first > 0 and child.is_terminal and child.at == first - 1: cut = k + 1
  var past = marked  # reading of text past last `su`
  past.tree.children = marked.tree.children[cut .. ^1]
  past.tree.dropUnread(marked)
  let
    read = toSeq(first ..< marked.units.len).filterIt(marked.isRead(marked.units[it]))
    words = marked.occurrences.filterIt(it.reading.is_word or it.reading.refusal != Refusal.Faho)
  marked.tree.leaves == toSeq(0 ..< marked.units.len) and read.len == strict.units.len and
    toSeq(0 ..< strict.units.len).allIt(
      marked.units[read[it]].is_read and
        marked.units[read[it]].words == strict.units[it].words and
        marked.units[read[it]].terminal == strict.units[it].terminal
    ) and
    words.mapIt((it.start, it.finish, it.text)) ==
      strict.occurrences.mapIt((it.start, it.finish, it.text)) and
    past.toNif == strict.toNif


func readPool(): Pool =
  ## Read each text of corpora by both readers once, keeping each refused; then each text
  ##   constructed, which `readText` refuses too. Law of cover reads each text of corpora too.
  for (key, text) in textsCorpora():
    let
      strict = text.readText
      marked = text.readTextMarked
    if not (marked.isCovering(text) and readTextParts(text).reading.isCovering(text)):
      result.uncovered.add key
    if strict.is_read:
      inc result.count_read
      if not marked.isSame(strict): result.differing.add key
    else: result.refused.add (key, text, strict, marked)
  for text in TEXTS_CONSTRUCTED:
    result.refused.add ("constructed", text, text.readText, text.readTextMarked)



suite "Internal: Marks":
  let pool = readPool()

  test "Text readText reads gives same units, tree and NIF past last su, over corpora":
    check pool.differing == newSeq[string]()  # header of `prose.nim`, text that reads as before
    check pool.count_read >= COUNT_READ_LEAST  # IX.3, guard keeps texts that read
    for text in TEXTS_PARTED:
      checkpoint text
      let strict = text.readText
      check strict.is_read and text.readTextMarked.isSame(strict)
        # header of `prose.nim`, `su` ends text before it, which marked reading keeps


  test "Each byte of each word lies in one leaf, in order, and each other byte is mark":
    check pool.uncovered == newSeq[string]()  # header of `nif.nim`, each word ties to bytes
    for text in TEXTS_CONSTRUCTED.toSeq & TEXTS_PARTED.toSeq & TEXTS_COVERED.toSeq:
      checkpoint text
      check text.readTextMarked.isCovering(text)  # header of `prose.nim`, each word in leaf
      check readTextParts(text).reading.isCovering(text)  # header of `prose.nim`, live text


  test "Text readText refuses gives tree of each unit once, in order, and its NIF reads back":
    var
      broken: seq[string]
      count = 0
    for (key, text, strict, marked) in pool.refused:
      checkpoint key & ": " & text
      check not strict.is_read  # law reads only texts refused
      if strict.is_read: continue
      if key != "constructed": inc count
      let
        held = marked.units.mapIt(it.words).concat
        is_whole = marked.tree.leaves == toSeq(0 ..< marked.units.len) and
          toSeq(1 ..< marked.units.len).allIt(
            marked.units[it - 1].words[0] < marked.units[it].words[0]
          ) and held.deduplicate.len == held.len
      if not (is_whole and marked.isMarking(strict) and marked.isReadBack): broken.add key
    check broken == newSeq[string]()  # header of `prose.nim`, each unit in place, refusal marked
    check count >= COUNT_REFUSED_LEAST  # IX.3, guard keeps texts refused


  test "Each branch of error node that heads text is tree its terminals give read alone":
    var count = 0
    for (key, text, strict, marked) in pool.refused:
      checkpoint key & ": " & text
      let
        terminals = marked.terminalsRead
        tree = terminals.readGrammarMarked
      check tree.leaves == toSeq(0 ..< terminals.len)  # header of `grammar.nim`, each terminal once
      var branches: seq[Node]
      tree.addBranches(branches)
      for branch in branches:
        let
          span = branch.leaves
          alone = terminals[span[0] .. span[^1]].readGrammar
        check span == toSeq(span[0] .. span[^1])  # header of `grammar.nim`, branch of one span
        check alone.is_read and alone.tree.isSameShifted(branch, -span[0])
          # header of `grammar.nim`, branch is tree its words give alone
        inc count
    check count >= COUNT_REFUSED_LEAST  # IX.3, guard keeps branches in play


  test "Each class expects names lets grammar read past its stop, and each other does not":
    var count = 0
    for (key, text, strict, marked) in pool.refused:
      if count == COUNT_EXPECTED: break
      let
        terminals = marked.terminalsRead
        tree = terminals.readGrammarMarked
      if tree.stop.isNone or tree.stop.get.at > STOP_EXPECTED_MOST: continue
      checkpoint key & ": " & text
      let at = tree.stop.get.at
      for class in classes():
        let is_past = (terminals[0 ..< at] & class).isReadPast(at)
        check is_past == tree.stop.get.expected.anyIt(it == class)
          # header of `grammar.nim`, terminals some derivation reads where grammar stops
      inc count
    check count == COUNT_EXPECTED  # IX.3, guard keeps stops in play


  test "Worked examples write as module suites hold, byte for byte, and read back":
    for (text, module) in EXAMPLES_MARKED:
      checkpoint text
      let marked = text.readTextMarked
      check marked.toNif == "(.nif27)\n(.lang \"cll-21.1\")\n" & module & "\n"
        # header of `nif.nim`, error node and unit `unread`
      check marked.isReadBack  # model of format, and tree rebuilt whole

  test "Cover leaves out no terminal that reads alone, nor two pieces that read as one text":
    var count = 0
    for (key, text, strict, marked) in pool.refused:
      checkpoint key & ": " & text
      let terminals = marked.terminalsRead
      for cover in terminals.readGrammarMarked.covers(terminals):
        for k, piece in cover.children:
          if piece.is_terminal:
            check not terminals[piece.at .. piece.at].readGrammar.is_read
              # header of `grammar.nim`, fewest terminals left out
          if k == 0: continue
          let span = cover.children[k - 1].leaves[0] .. piece.leaves[^1]
          check not terminals[span].readGrammar.is_read
            # header of `grammar.nim`, fewest pieces: two side by side read not as one `text`
        inc count
    check count >= COUNT_COVERS_LEAST  # IX.3, guard keeps covers in play


  test "Error node of text cut into parts holds tree of each part that reads alone":
    for text in ["mi klama le .i do citka", "mi klama le ni'o do citka"]:
      checkpoint text
      let tree = text.readTextMarked.tree
      check tree.stop.isSome and tree.children.len == 2  # header of `grammar.nim`, two parts
      check tree.children[0].stop.isSome  # header of `grammar.nim`, part that reads not
      check tree.children[1].stop.isNone and tree.children[1].number == 0
        # header of `grammar.nim`, part that reads alone, as `text`
    let open = "lu mi klama le .i do citka".readTextMarked.tree
    check open.stop.isSome and open.children.allIt(it.is_terminal or it.stop.isNone)
      # header of `grammar.nim`, text where `lu` stays open is one part, holding branches
