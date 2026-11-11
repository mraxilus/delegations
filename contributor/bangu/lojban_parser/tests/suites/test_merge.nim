## Hold merge of parts (`merge.nim`) to one pass (ruling `D1 b` on #859): NIF of parts of text,
##   as `toNifParts` writes it, merges to NIF `readText` writes, byte for byte, where one pass
##   reads text, and is refused where one pass refuses it.
##   Domain: each text of corpora, its parts cut as text read whole cuts them, and as live text
##     cuts them after opener that waits; and texts built of words that reach back
##     (`texts_built.nim`), since corpora hold few of them.
##   Live parts cut after opener that waits may hold error node where text read whole holds
##     none, since part read alone stops where closer would come. Merge refuses there, naming
##     part, as ruling asks; law holds that such refusal names node of module holding error node.
##   Worked examples give drop, merge and refusal of each word that reaches back: `ni'o ni'o`,
##     `tu'e`, `.ibo`, vocative, `si`, `su`, `fa'o`; and error before last `su`, which one pass
##     refuses where stream, erasure or `lo'u` no `le'u` closes gives it, else drops (19.16).
##   Rebuild loses nothing: tree that each node of module rebuilds writes that node back, byte for
##     byte, marks among them (`toNif` of tree and leaves), over corpora and worked examples.
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
  COUNT_BUILT_READ_LEAST = 200  ## Texts built that one pass reads; 263 on adding law.
  COUNT_BUILT_SU_LEAST = 30
    ## Texts built that one pass reads, holding `su` that ends text before it; 46 on adding law.
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
    ## Constructed texts one pass reads, whose parts merge to its NIF.
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
  ]
    ## Constructed texts, and tree their parts merge to, byte for byte, as one pass writes it.
  EXAMPLES_REFUSED = [
    (text: "x su mi klama", part: 0, start: 0, reason: "stage `Stream` refuses it, as `Shape`"),
      # stream reads whole text before `su` erases
    (text: "si su mi klama", part: 0, start: 0, reason: "stage `Construct` refuses it"),
      # `si` erasing nothing reads before `su` erases (19.13)
    (text: "lo'u su ko", part: 0, start: 0, reason: "stage `Quotation` refuses it"),
      # `lo'u` no `le'u` closes quotes `su` (19.9)
    (text: "mi su si do", part: 2, start: 6, reason: "stage `Construct` refuses it"),
      # `si` past last `su` erases nothing
    (
      text: "mi klama .i le", part: 1, start: 14,
      reason: "grammar of 21.1 stops in rule `sumti-6 97`",
    ),  # `le` waits for sumti, past end of text
  ]
    ## Constructed texts one pass refuses, with node of module refused, byte, and reason.
  EXAMPLES_LIVE_REFUSED = [
    (text: ".i lu le'u si gy li'u bu broda do le to .i broda", part: 0, start: 41),
      # part after `to`, which waits for `toi`, reads alone
    (text: "lu gy li'u zarci lo lu .i cadzu je bu", part: 0, start: 24),
      # part after second `lu`, which waits for `li'u`, reads alone
  ]
    ## Texts built that one pass reads, whose parts cut as live text hold error node, with node
    ##   of module refused and byte: of 30,000 texts built by seed of suite, these two.
  MODULES_MALFORMED = [
    ("", "should open with directives"),  # no directive
    (HEADER & "(sentence 0 40", "NIF should hold"),  # node never closed
    (HEADER & "(FOO 0 2 \"mi\")\n", "should name selma'o"),  # class that names no selma'o
    (HEADER & "(sumti_6 1 2 (KOhA 0 2 \"mi\"))\n", "two ends of chain"),  # no chain of 21.1
    (HEADER & "(sumti_6 (KOhA 0 2 \"mi\"))\n", "number of rule"),  # rule with no number
    (HEADER & "(KOhA 0 \"mi\")\n", "bytes and letters"),  # word with no byte past it
    (HEADER & "(srera 0 sumti_6)\n", "grammar of 21.1 stops"),  # error node, refused as one
  ]
    ## Modules of NIF merge refuses, each with no shape `nif.nim` writes, and what reason holds.



func isHoldingError(nif: string, part: Option[int]): bool =
  ## Decide whether node `part` of module, counted past directives, holds error node.
  func isHeld(node: NodeNif): bool =
    if node.kind != KindNif.Compound: return false
    if node.text == TAG_ERROR: return true
    for k in 0 ..< node.children.len:
      if node.children[k].isHeld: return true

  if part.isNone: return false
  let module = nif.readModule
  part.get + 2 < module.len and module[part.get + 2].isHeld


func readPool(): seq[tuple[key, text: string, whole: ReadingText, parts, live: string]] =
  ## Read each text of corpora once, for laws that read it: one pass, then NIF of its parts as
  ##   text read whole cuts them, and as live text cuts them.
  for (key, text) in textsCorpora():
    result.add (
      key, text, readText(text), readTextParts(text).reading.toNifParts,
      readTextParts(text, is_live = true).reading.toNifParts,
    )


func isWrittenBack(nif: string): bool =
  ## Decide whether tree each node of module rebuilds writes that node back, byte for byte.
  let
    module = nif.readModule
    lines = nif.splitLines
  for k in 2 ..< module.len:
    var terminals: seq[TerminalNif]
    let tree = module[k].toTree(terminals)
    if tree.toNif(LeavesNif(terminals: terminals)) != HEADER & lines[k] & "\n": return false
  true



suite "Internal: Merge of parts":
  let pool = readPool()

  test "Parts merge to NIF of one pass, and are refused where it refuses, over corpora":
    var count_read, count_parted = 0
    for k in 0 ..< pool.len:
      template whole: untyped = pool[k].whole
        ## Alias reading, which `let` would copy.
      checkpoint pool[k].key & ": " & pool[k].text
      for is_live in [false, true]:
        let
          parts = (if is_live: pool[k].live else: pool[k].parts)
          merged = parts.mergeParts
        if whole.is_read and merged.is_merged:
          check merged.nif == whole.toNif  # header of `merge.nim`, merge gives one pass
        elif whole.is_read:
          check is_live and parts.isHoldingError(merged.part)  # header, live part holds error node
        else:
          check not merged.is_merged  # header of `merge.nim`, merge refuses where one pass does
        if is_live or not whole.is_read: continue
        inc count_read
        if parts.splitLines.len > 4: inc count_parted  # directives, nodes, then empty line
    check count_read >= COUNT_READ_LEAST  # IX.3, guard keeps texts that read
    check count_parted >= COUNT_PARTED_LEAST  # IX.3, guard keeps texts of more than one node


  test "Parts merge to NIF of one pass, and are refused where it refuses, over texts built":
    var
      rng = initRand(SEED)
      count_read, count_su = 0
    for k in 0 ..< COUNT_BUILT:
      let
        text = rng.textBuilt
        whole = readText(text)
      checkpoint text
      for is_live in [false, true]:
        let
          parts = readTextParts(text, is_live).reading.toNifParts
          merged = parts.mergeParts
        if whole.is_read and merged.is_merged:
          check merged.nif == whole.toNif  # header of `merge.nim`, merge gives one pass
        elif whole.is_read:
          check is_live and parts.isHoldingError(merged.part)  # header, live part holds error node
        else:
          check not merged.is_merged  # header of `merge.nim`, merge refuses where one pass does
        if is_live or not whole.is_read: continue
        inc count_read
        if "(rivbi SU " in parts: inc count_su
    check count_read >= COUNT_BUILT_READ_LEAST  # IX.3, guard keeps texts that read
    check count_su >= COUNT_BUILT_SU_LEAST  # IX.3, guard keeps texts `su` cuts


  test "Constructed texts merge to NIF of one pass, cut both ways":
    for text in TEXTS_MERGED:
      checkpoint text
      let whole = readText(text)
      check whole.is_read
      if not whole.is_read: continue
      for is_live in [false, true]:
        let merged = readTextParts(text, is_live).reading.toNifParts.mergeParts
        check merged.is_merged
        if merged.is_merged: check merged.nif == whole.toNif  # header of `merge.nim`


  test "Worked examples merge to tree of one pass, byte for byte":
    for (text, nif) in EXAMPLES_MERGED:
      checkpoint text
      let merged = readTextParts(text).reading.toNifParts.mergeParts
      check merged.is_merged
      if merged.is_merged: check merged.nif == HEADER & nif & "\n"  # header of `merge.nim`, drop


  test "Worked examples are refused, naming node of module, byte and reason":
    for (text, part, start, reason) in EXAMPLES_REFUSED:
      checkpoint text
      check not readText(text).is_read
      let merged = readTextParts(text).reading.toNifParts.mergeParts
      check not merged.is_merged
      if merged.is_merged: continue
      check merged.part == some(part)  # header of `merge.nim`, refusal names node
      check merged.start == some(start)
      check merged.reason == reason


  test "Tree each node of module rebuilds writes it back, byte for byte, marks among them":
    for k in 0 ..< pool.len:
      checkpoint pool[k].key & ": " & pool[k].text
      check pool[k].parts.isWrittenBack  # header of `nif.nim`, tree rebuilt writes back
      if pool[k].whole.is_read: check pool[k].whole.toNif.isWrittenBack
    var texts = @TEXTS_MERGED
    for (text, part, start, reason) in EXAMPLES_REFUSED: texts.add text
    for text in texts:
      checkpoint text
      check readTextParts(text).reading.toNifParts.isWrittenBack  # header of `nif.nim`
      let whole = readText(text)
      if whole.is_read: check whole.toNif.isWrittenBack


  test "Live parts cut after opener that waits may hold error node, which merge names":
    for (text, part, start) in EXAMPLES_LIVE_REFUSED:
      checkpoint text
      let whole = readText(text)
      check whole.is_read
      if not whole.is_read: continue
      let merged = readTextParts(text).reading.toNifParts.mergeParts
      check merged.is_merged and merged.nif == whole.toNif  # cut as text read whole cuts it
      let
        live = readTextParts(text, is_live = true).reading.toNifParts
        refused = live.mergeParts
      check not refused.is_merged  # header of `merge.nim`, live part holds error node
      if refused.is_merged: continue
      check refused.part == some(part) and refused.start == some(start)
      check live.isHoldingError(refused.part)


  test "NIF that reads not, or holds shape writer gives not, is refused":
    for (module, reason) in MODULES_MALFORMED:
      checkpoint module
      let merged = module.mergeParts  # raises not
      check not merged.is_merged  # header of `merge.nim`, rebuild refuses shape
      if not merged.is_merged: check reason in merged.reason
    var terminals: seq[TerminalNif]
    expect ValueError:  # rebuild refuses error node of no shape writer gives
      discard readModule(HEADER & "(srera 0 sumti_6)\n")[2].toTree(terminals)
