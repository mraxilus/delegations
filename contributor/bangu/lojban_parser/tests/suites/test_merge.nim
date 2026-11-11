## Hold merge of parts (`merge.nim`) to one pass (rulings on #859: `D1 b`, then merge of each run
##   around error): NIF of parts of text, as `toNifParts` writes it, merges to what one pass
##   gives, and merge refuses no error.
##   Laws, each by what one pass gives text:
##     Text one pass reads merges to NIF `readText` writes, byte for byte, and `is_whole` holds.
##     Text whose parts hold no error node merges to marked reading of one pass (`readTextMarked`),
##       with each unit one pass holds no word of left out, as merge drops it: each unit some
##       stage refuses stands in place, and error node stands over parts that join not.
##     Text whose parts hold error node keeps each such part as it is, and merges each run of
##       parts between them to marked reading of its text read alone, where that text gives same
##       words: word acting across start of run reads otherwise alone, as `si`, `sa`, `zei` or
##       `bu` reaching back past it, or quotation of `lo'u`, `la'o` or `zoi` crossing it.
##   Domain: each text of corpora, and texts built of words that reach back (`texts_built.nim`),
##     since corpora hold few of them; each cut as text read whole cuts it, and as live text
##     cuts it. Text one pass refuses that holds `su` stands in worked examples alone, since
##     marked reading keeps text before `su`, which merge drops.
##   Live parts cut after opener that waits may differ from parts of text read whole: part read
##     alone stops where closer would come, so merge keeps it as part holding error node; or
##     parts join as another valid reading, closer left out. Laws read live parts as live text
##     cuts them, save texts whose live parts break them (`TEXTS_LIVE_DIFFERING`).
##   Worked examples give each drop and each place: `ni'o ni'o`, `tu'e`, `.ibo`, vocative, `si`,
##     `su`, `fa'o`; unit in place; run around error node; unit before last `su` that one pass
##     refuses text for (19.16); and live parts that differ.
##   Rebuild loses nothing: tree that each node of module rebuilds writes that node back, byte for
##     byte, marks among them (`toNif` of trees and leaves), over each text of domain, each cut,
##     and constructed texts.
##   NIF that reads not, or holds shape writer gives not, is refused, never raised.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[options, random, strutils, unittest]

import ../../src/lojban_parser/[merge, nif, nif_read, prose]
import ./[corpora, texts_built]


const
  SEED = 859  ## Seed of texts built.
  COUNT_BUILT = 1500  ## Texts built of words that reach back, each cut both ways.
  COUNT_READ_LEAST = 1800  ## Texts of corpora one pass reads, of 1,941; 1,831 on adding law.
  COUNT_PARTED_LEAST = 100
    ## Texts of corpora one pass reads, cut into more than one node; 133 on adding law.
  COUNT_MARKED_LEAST = 350
    ## Texts of corpora and built, each cut, whose parts hold no error node, which one pass
    ##   refuses; 388 on adding law.
  COUNT_RUNS_LEAST = 900
    ## Runs of parts of corpora and built, each cut, that merge around error node, and whose
    ##   text read alone gives same words; 937 on adding law.
  RUNS_OUTSIDE_MOST = 0.1
    ## Share of runs, at most, whose text read alone gives other words; 0.079 on adding law, each
    ##   run of them by word acting across its start.
  COUNT_BUILT_READ_LEAST = 200  ## Texts built that one pass reads; 263 on adding law.
  COUNT_BUILT_SU_LEAST = 30
    ## Texts built that one pass reads, holding `su` that ends text before it; 46 on adding law.
  MARKS_TRAILING = {' ', '\t', '\n', '.', ','}
    ## Marks between words, which end text; NIF gives no byte of them, so merge stops before.
  TEXTS_MERGED = [
    "ni'o ni'o mi klama .i do cadzu",  # two NIhO open first paragraph (rule 2)
    "mi klama ni'o do cadzu .i ko",  # NIhO nests paragraph after first (rule 4)
    "tu'e mi klama .i do cadzu tu'u .i ko",  # text inside text (rule 14)
    "mi klama .ibo do cadzu",  # `.ibo` joins sentences in one part
    "coi do .i mi klama",  # vocative opens text, before first part
    "lu mi klama .i do cadzu li'u .i ko",  # `li'u` closes text it quotes
    "lu mi klama .i do cadzu",  # live cut after `lu` breaks rule of passes, so grammar reads whole
    "mi klama .i do cadzu si si si ko",  # erasure reaches into part before it (19.13)
    "le su mi klama",  # error of grammar before `su` drops
    "xu'au su mi klama",  # selma'o reads after `su` erases, so cmavo no list gives drops
    "zei su mi klama",  # `zei` reads after `su` erases, so error of it drops (19.16)
    "ba'e su mi klama",  # BAhE reads after `su` erases, so error of it drops (19.16)
    "bu su mi klama",  # `bu` reads after `su` erases, so error of it drops (19.16)
    "lo'u mi le'u si su ko",  # `le'u` erasure erases closed `lo'u`, which `su` erases
    "ba'e zoi gy. a'h .gy. ui su ko",  # BAhE stands before `zoi`, so text quoted is fourth word
    "zoi gy. ab'h .gy. cu melbi",  # text `zoi` quotes keeps `'` and `h`
  ]
    ## Constructed texts one pass reads, whose parts merge to its NIF, cut both ways.
  EXAMPLES_MERGED = [
    (
      text: "ti gerku si mlatu",  # `si` erases `gerku` (19.13)
      nif: "(sentence 0 40 (sumti_6 80 97 (KOhA 0 2 \"ti\")) " &
        "(bridi_tail_3 50 53 (tanru_unit_2 130 152 (BRIVLA 12 17 \"mlatu\")) (tail_terms 71)))",
    ),
    (
      text: "mi su do .i ko",  # `su` ends text before it (19.13)
      nif: "(paragraph 0 10 (sumti_6 20 97 (KOhA 6 8 \"do\")) (I 10 11 \"i\") " &
        "(sumti_6 20 97 (KOhA 12 14 \"ko\")))",
    ),
    (
      text: "mi klama fa'o xu",  # `fa'o` ends input (19.15)
      nif: "(sentence 0 40 (sumti_6 80 97 (KOhA 0 2 \"mi\")) " &
        "(bridi_tail_3 50 53 (tanru_unit_2 130 152 (BRIVLA 3 8 \"klama\")) (tail_terms 71)))",
    ),
    (
      text: "mi klama .i x .i ko sipna",  # stream refuses `x`, which stands in its paragraph
      nif: "(paragraph 0 10 (sentence 11 40 (sumti_6 80 97 (KOhA 0 2 \"mi\")) " &
        "(bridi_tail_3 50 53 (tanru_unit_2 130 152 (BRIVLA 3 8 \"klama\")) (tail_terms 71))) " &
        "(I 10 11 \"i\") (rivbi Stream Shape 12 13 \"x\") (I 15 16 \"i\") " &
        "(sentence 11 40 (sumti_6 80 97 (KOhA 17 19 \"ko\")) " &
        "(bridi_tail_3 50 53 (tanru_unit_2 130 152 (BRIVLA 20 25 \"sipna\")) (tail_terms 71))))",
    ),
  ]
    ## Constructed texts, and tree their parts merge to, byte for byte, as one pass gives it.
  EXAMPLES_KEPT = [
    (text: "x su mi klama", first: "(rivbi Stream Shape 0 1 \"x\")", count: 2, errors: @[0]),
      # stream reads whole text before `su` erases, so `x` stays in front
    (text: "si su mi klama", first: "(rivbi Construct 0 2 \"si\")", count: 2, errors: @[0]),
      # `si` erasing nothing reads before `su` erases (19.13)
    (text: "lo'u su ko", first: "(rivbi Quotation 0 4 \"lohu\")", count: 2, errors: @[0]),
      # `lo'u` no `le'u` closes quotes `su` (19.9)
    (text: "mi klama .i le", first: "", count: 2, errors: @[1]),
      # `le` waits for sumti past end of text, so its part stays
    (text: "mi klama .i do cadzu .i le .i ko sipna .i mi klama", first: "", count: 3, errors: @[1]),
      # run on each side of part holding `le` merges
    (text: "cadzu ni'o", first: "", count: 1, errors: @[0]),
      # each part reads alone, and error node stands over both, as one pass marks it
    (text: "ui cadzu ni'o do si", first: "(srera 19 ", count: 1, errors: @[0]),
      # grammar stops past words erasure erases at end of text, as one pass marks it
    (text: "cadzu ni'o fa'o xu", first: "(srera 11 ", count: 1, errors: @[0]),
      # grammar stops where `fa'o` ends input, as one pass marks it (19.15)
  ]
    ## Constructed texts one pass refuses, with first node merge gives where it is fixed, count of
    ##   nodes, and index of each node holding error node or unit refused.
  TEXTS_LIVE_DIFFERING = [
    ".i lu le'u si gy li'u bu broda do le to .i broda",  # part after `to` stops where `toi` is due
    "lu gy li'u zarci lo lu .i cadzu je bu",  # part after second `lu` stops where `li'u` is due
    "tu'e to nai .i zo sa'a .i zoi bu",  # parts join as other reading, `toi` left out after `nai`
  ]
    ## Texts built whose live parts break laws that their parts as text read whole hold: of 30,000
    ##   texts built by seed of suite, both cuts, these three, at 10,259, 19,141 and 25,354.
  MODULES_MALFORMED = [
    ("", "should open with directives"),  # no directive
    (HEADER & "(sentence 0 40", "NIF should hold"),  # node never closed
    (HEADER & "(FOO 0 2 \"mi\")\n", "should name selma'o"),  # class that names no selma'o
    (HEADER & "(sumti_6 1 2 (KOhA 0 2 \"mi\"))\n", "two ends of chain"),  # no chain of 21.1
    (HEADER & "(sumti_6 (KOhA 0 2 \"mi\"))\n", "number of rule"),  # rule with no number
    (HEADER & "(KOhA 0 \"mi\")\n", "bytes and letters"),  # word with no byte past it
    (HEADER & "(srera 0 sumti_6)\n", "byte, rule, number"),  # error node with no rule number
  ]
    ## Modules of NIF merge refuses, each with no shape `nif.nim` writes, and what reason holds.



func isHoldingError(node: NodeNif): bool =
  ## Decide whether node of NIF holds error node, at any depth.
  if node.kind != KindNif.Compound: return false
  if node.text == TAG_ERROR: return true
  for k in 0 ..< node.children.len:
    if node.children[k].isHoldingError: return true


func isDropped(node: NodeNif): bool =
  ## Decide whether node is unit one pass holds no word of: erasure, `fa'o`, or word after it.
  node.kind == KindNif.Compound and node.text == TAG_UNREAD and node.children.len > 1 and (
    node.children[0].text in ["Erasure", "FAhO"] or
    (node.children[0].text == "Stream" and node.children[1].text == "FAhO")
  )


func stripped(node: NodeNif): NodeNif =
  ## Give node with each unit one pass holds no word of left out, at any depth.
  result = NodeNif(kind: node.kind, text: node.text, number: node.number)
  for k in 0 ..< node.children.len:
    if not node.children[k].isDropped: result.children.add node.children[k].stripped


func written(node: NodeNif): string =
  ## Give module of NIF node rebuilds, with each unit one pass holds no word of left out.
  var terminals: seq[TerminalNif]
  @[node.stripped.toTree(terminals)].toNif(LeavesNif(terminals: terminals))


func marked(text: string): string =
  ## Give marked reading of one pass, with each unit one pass holds no word of left out, as
  ##   merge drops it; marks that end text left out, as NIF gives no byte of them.
  readTextMarked(text.strip(leading = false, chars = MARKS_TRAILING)).toNif.readModule[2].written


func span(node: NodeNif, first, past: var int) =
  ## Widen `first ..< past` to bytes of each word node holds.
  if node.kind != KindNif.Compound: return
  for k in 0 ..< node.children.len:
    template child: untyped = node.children[k]
      ## Alias node, which `let` would copy.
    if child.kind == KindNif.Literal:
      first = min(first, node.children[k - 2].number)
      past = max(past, node.children[k - 1].number)
    else: child.span(first, past)


func words(nif: string): seq[TerminalNif] =
  ## Give terminals of each node of module, in order.
  let module = nif.readModule
  for k in 2 ..< module.len: discard module[k].toTree(result)


func isWrittenBack(nif: string): bool =
  ## Decide whether tree each node of module rebuilds writes that node back, byte for byte.
  let
    module = nif.readModule
    lines = nif.splitLines
  for k in 2 ..< module.len:
    var terminals: seq[TerminalNif]
    let tree = module[k].toTree(terminals)
    if @[tree].toNif(LeavesNif(terminals: terminals)) != HEADER & lines[k] & "\n": return false
  true


func readTexts(): seq[
  tuple[text: string, is_corpus: bool, whole: ReadingText, parts, live: string]
] =
  ## Read each text of corpora, then each text built, once, for laws that read it: one pass, then
  ##   NIF of its parts as text read whole cuts them, and as live text cuts them.
  var
    rng = initRand(SEED)
    texts: seq[(string, bool)]
  for (key, text) in textsCorpora(): texts.add (text, true)
  for k in 0 ..< COUNT_BUILT: texts.add (rng.textBuilt, false)
  for (text, is_corpus) in texts:
    result.add (
      text, is_corpus, readText(text), readTextParts(text).reading.toNifParts,
      readTextParts(text, is_live = true).reading.toNifParts,
    )


func isRunAlone(text: string, module: seq[NodeNif], k: int, inside, outside: var int): bool =
  ## Decide whether node `k` of module merge gives is marked reading of one pass of its text read
  ##   alone, where that text gives same words: bytes before it blanked, and text cut where next
  ##   node opens; count it in `inside` where that text gives same words, else in `outside`.
  var (first, past) = (high(int), -1)
  module[k].span(first, past)
  var cut = text.len
  if k + 1 < module.len:
    var (next, after) = (high(int), -1)
    module[k + 1].span(next, after)
    if after >= 0: cut = next
  var alone = text[0 ..< cut]
  for b in 0 ..< min(first, cut): alone[b] = ' '
  let
    theirs = alone.marked
    mine = module[k].written
  if theirs.words != mine.words:
    inc outside
    return true
  inc inside
  theirs == mine



suite "Internal: Merge of parts":
  let texts = readTexts()

  test "Text one pass reads merges to its NIF, byte for byte, over corpora and texts built":
    var count_read, count_parted, count_built, count_su = 0
    for k in 0 ..< texts.len:
      template item: untyped = texts[k]
        ## Alias text, which `let` would copy.
      if not item.whole.is_read: continue
      checkpoint item.text
      for parts in [item.parts, item.live]:
        if parts != item.parts and item.text in TEXTS_LIVE_DIFFERING: continue
        let merged = parts.mergeParts
        check merged.is_merged and merged.is_whole  # header of `merge.nim`, one tree, no error
        if merged.is_merged: check merged.nif == item.whole.toNif  # header, merge is one pass
      if item.is_corpus:
        inc count_read
        if item.parts.splitLines.len > 4: inc count_parted  # directives, nodes, empty line
      else:
        inc count_built
        if "(rivbi SU " in item.parts: inc count_su
    check count_read >= COUNT_READ_LEAST  # IX.3, guard keeps texts that read
    check count_parted >= COUNT_PARTED_LEAST  # IX.3, guard keeps texts of more than one node
    check count_built >= COUNT_BUILT_READ_LEAST  # IX.3, guard keeps texts built that read
    check count_su >= COUNT_BUILT_SU_LEAST  # IX.3, guard keeps texts `su` cuts


  test "Text one pass refuses merges to marked reading of one pass, or of each run around error":
    var count_marked, inside, outside = 0
    for k in 0 ..< texts.len:
      template item: untyped = texts[k]
        ## Alias text, which `let` would copy.
      if item.whole.is_read: continue
      checkpoint item.text
      for parts in [item.parts, item.live]:
        if parts != item.parts and item.text in TEXTS_LIVE_DIFFERING: continue
        let merged = parts.mergeParts
        check merged.is_merged and not merged.is_whole  # header of `merge.nim`, error stays
        if not merged.is_merged or "(rivbi SU " in item.parts: continue  # header, su in examples
        let module = parts.readModule
        var shape: seq[string]  # each node merge should give: part holding error node, or run
        for m in 2 ..< module.len:
          if module[m].isDropped: continue
          if module[m].isHoldingError: shape.add module[m].written
          elif shape.len == 0 or shape[^1].len > 0: shape.add ""
        if shape == @[""]:
          check merged.nif == item.text.marked  # header of `merge.nim`, unit in place
          inc count_marked
          continue
        let nodes = merged.nif.readModule
        check nodes.len - 2 == shape.len  # header of `merge.nim`, node of each run and error
        if nodes.len - 2 != shape.len: continue
        for m in 0 ..< shape.len:
          if shape[m].len > 0: check nodes[m + 2].written == shape[m]  # header, error stays
          else: check item.text.isRunAlone(nodes, m + 2, inside, outside)  # header, run alone
    check count_marked >= COUNT_MARKED_LEAST  # IX.3, guard keeps texts merged with unit in place
    check inside >= COUNT_RUNS_LEAST  # IX.3, guard keeps runs merged around error node
    check float(outside) <= RUNS_OUTSIDE_MOST * float(inside + outside)  # IX.3, domain of law


  test "Constructed texts merge to NIF of one pass, cut both ways":
    for text in TEXTS_MERGED:
      checkpoint text
      let whole = readText(text)
      check whole.is_read
      if not whole.is_read: continue
      for is_live in [false, true]:
        let merged = readTextParts(text, is_live).reading.toNifParts.mergeParts
        check merged.is_merged and merged.is_whole
        if merged.is_merged: check merged.nif == whole.toNif  # header of `merge.nim`


  test "Worked examples merge to tree of one pass, byte for byte, unit in place":
    for (text, nif) in EXAMPLES_MERGED:
      checkpoint text
      let merged = readTextParts(text).reading.toNifParts.mergeParts
      check merged.is_merged
      if merged.is_merged: check merged.nif == HEADER & nif & "\n"  # header of `merge.nim`, drop


  test "Worked examples keep each error, merging each run around it":
    for (text, first, count, errors) in EXAMPLES_KEPT:
      checkpoint text
      check not readText(text).is_read
      let merged = readTextParts(text).reading.toNifParts.mergeParts
      check merged.is_merged and not merged.is_whole
      if not merged.is_merged: continue
      let lines = merged.nif.splitLines[2 .. ^2]
      check lines.len == count  # header of `merge.nim`, node of each run and each error
      if first.len > 0 and lines.len > 0: check lines[0].startsWith(first)
      var held: seq[int]  # node holding error node or unit refused
      for k in 0 ..< lines.len:
        if "(srera " in lines[k] or "(rivbi " in lines[k]: held.add k
      check held == errors


  test "Live parts that differ from parts of text read whole merge to their own trees":
    for text in TEXTS_LIVE_DIFFERING:
      checkpoint text
      let
        parts = readTextParts(text).reading.toNifParts
        live = readTextParts(text, is_live = true).reading.toNifParts
        whole = readText(text)
      check live != parts  # header, live part reads alone where closer is due
      let merged = parts.mergeParts
      check merged.is_merged
      if not merged.is_merged: continue
      if whole.is_read: check merged.nif == whole.toNif  # cut as text read whole cuts it
      else: check merged.nif == text.marked
      let differing = live.mergeParts
      check differing.is_merged and not differing.is_whole and differing.nif != merged.nif


  test "Tree each node of module rebuilds writes it back, byte for byte, marks among them":
    for k in 0 ..< texts.len:
      template item: untyped = texts[k]
        ## Alias text, which `let` would copy.
      checkpoint item.text
      check item.parts.isWrittenBack  # header of `nif.nim`, tree rebuilt writes back
      check item.live.isWrittenBack
      if item.whole.is_read: check item.whole.toNif.isWrittenBack
    var constructed = @TEXTS_MERGED
    for (text, first, count, errors) in EXAMPLES_KEPT: constructed.add text
    for text in constructed:
      checkpoint text
      check readTextParts(text).reading.toNifParts.isWrittenBack  # header of `nif.nim`
      let whole = readText(text)
      if whole.is_read: check whole.toNif.isWrittenBack


  test "NIF that reads not, or holds shape writer gives not, is refused":
    for (module, reason) in MODULES_MALFORMED:
      checkpoint module
      let merged = module.mergeParts  # raises not
      check not merged.is_merged  # header of `merge.nim`, rebuild refuses shape
      if not merged.is_merged: check reason in merged.reason
    var terminals: seq[TerminalNif]
    expect ValueError:  # rebuild refuses error node of no shape writer gives
      discard readModule(HEADER & "(srera 0 sumti_6)\n")[2].toTree(terminals)
