## cipra lo du'u le se tcidu poi sinxa ro srera cu mapti le flalu pe vo'a to `#859` toi
##   .i `readTextMarked` tcidu lo selci'a ta'i lo nu `readText` tcidu kei gi'e ranji lo nu tcidu ba
##       ro srera gi'e jarco ro le srera ne'i lo tricu .e lo selci'a be fi `NIF`
##   .i va'o lo nu `readText` tcidu lo selci'a kei le pagbu .e le tricu .e le selci'a be fi `NIF` ba
##       zo su noi romoi cu mintu ne'i le selci'aste va'o lo nu ro pezli pe lo pagbu poi no velru'e
##       cu tcidu ke'a selvi'u
##   .i ro selci'a poi lidne zo su zvati le krasi be le genja gi'e lidne lo pezli pe zo su
##   .i lo valsi poi lo nu vimcu cu vimcu ke'a ku'o .e zo fa'o .e lo valsi poi se lidne zo fa'o
##       zvati lo pagbu pe vo'a
##   .i `readText` na tcidu le pagbu to `CLL 19.13` .e `CLL 19.15` toi
##   .i ku'i va'o lo nu `readText` to'e curmi lo selci'a kei le se tcidu poi sinxa ro srera cu dunda
##       lo tricu
##   .i ro pagbu cu pezli le tricu pa roi ta'i le porsi
##   .i ne'i le tricu lo nu `readText` to'e curmi cu selsni lo pagbu pe le velru'e poi to'e curmi
##   .i le selci'a be fi `NIF` cu selraptcidu ta'i lo nu mulno to `reader_nif.nim` toi
##   .i le flalu cu cipra le selci'aste .e lo selci'a poi selfi'i fi ro velru'e
##   .i ki'u bo le selci'aste cu na se to'e curmi ne'i le velru'e pe lo nu sitna ge'u .e le velru'e
##       pe lo gensu'a
##   .i le gerna zo'u ro jimca poi lo srejge cu vasru ke'a zi'e poi selkra `text` du lo tricu poi le
##       gerna valsi po'o pe le jimca cu dunda ke'a
##   .i ro klesi poi `expects` cmene ke'a curmi lo nu le gerna cu tcidu ba le stuzi poi le gerna cu
##       sisti bu'u ke'a
##   .i ro datlei cu na curmi
##   .i lo gacri be lo srejge cu mecrai
##   .i no genvla poi le gacri cu cliva ke'a se tcidu ta'i pa mulselci'a
##   .i no re spisa poi lamji cu se tcidu ta'i pa `text`
##   .i ki'u bo va'o lo nu pa jimca cu kuspe le genvla .a le re spisa kei le gacri cu cliva lo
##       mecygenvla gi'a pilno lo me'aspi
##   .i lo gacri pe lo nu dunli cu na se cipra
##   .i ki'u bo no flalu cu tcidu lo du'u lo nu dunli cu dunda ma kau poi gacri
##   .i le cipra cu tcidu le selci'aste ta'i lo nu `test_nif.nim` tcidu le se ciska liste to
##       `corpora.nim` toi

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[options, sequtils, unittest]

import ../../src/lojban_parser/grammar {.all.}
import ../../src/lojban_parser/[nif, prose, selmaho, stream, tanru]
import ./[corpora, reader_nif]


type
  Refused = tuple[key, text: string, strict: ReadingText, marked: ReadingMarked]
    ## lo selci'a poi `readText` to'e curmi ke'a
    ##   .i ji'a le re se tcidu pe le selci'a

  Pool = object
    ## lo selci'a poi le cipra cu tcidu ke'a
    ##   .i ro le selci'a cu se tcidu pa roi le re tcidu
    count_read: int  ## lo te kancu be lo se ciska pe le se ciska liste zi'e poi se tcidu
    differing: seq[string]
      ## lo ckiku be ro selci'a poi se tcidu zi'e poi le re se tcidu pe ke'a na mintu
    refused: seq[Refused]
      ## ro selci'a pe le selci'aste zi'e poi se to'e curmi ku'o ce'o ro selci'a poi selfi'i
    uncovered: seq[string]
      ## lo ckiku be ro selci'a pe le selci'aste zi'e poi su'o tricu pe ke'a na gacri ro valsi pe
      ##     ke'a pa roi ta'i le porsi
      ##   .i le se tcidu poi sinxa ro srera ku'o .e le se tcidu pe lo pagbu be le selci'a cu dunda
      ##       le re tricu to `isCovering` toi


const
  COUNT_READ_LEAST = 1800
    ## lo mecraiterkancu be lo se ciska pe le se ciska liste zi'e poi se tcidu
    ##   .i le selci'aste cu vasru pasovopa selci'a
    ##   .i le flalu cu tcidu ro le selci'a sepi'o `readTextMarked`
  COUNT_REFUSED_LEAST = 100
    ## lo mecraiterkancu be lo se ciska pe le se ciska liste zi'e poi `readText` to'e curmi ke'a
    ##   .i le selci'aste cu vasru pasovopa selci'a
    ##   .i ca lo nu jmina le se tcidu poi sinxa ro srera kei `readText` to'e curmi papano selci'a
  COUNT_COVERS_LEAST = 90
    ## lo mecraiterkancu be lo srera jgena poi vasru lo jimca ku'o ne'i ro selci'a poi se to'e curmi
    ##   .i le selci'a cu cmima le selci'aste .a lo selci'a poi selfi'i
    ##   .i ca lo nu jmina le flalu pe lo gacri kei sovo lo srejge cu vasru lo jimca
  COUNT_EXPECTED = 24
    ## lo te kancu be lo nu sisti poi le flalu pe `expects` tcidu ke'a
    ##   .i le flalu cu tcidu le pamoi se ciska poi le gerna cu to'e curmi ke'a
    ##   .i le selci'a pe le selci'aste cu lidne le selci'a poi selfi'i
    ##   .i lo nu sisti pe ro le selci'a cu se lidne lo genvla
    ##   .i lo te kancu be le gerna valsi cu na zmadu `STOP_EXPECTED_MOST`
    ##   .i muze selci'a cu mapti
    ##   .i ro le parevo klesi zo'u le flalu cu tcidu le selci'a bu'u le stuzi pa roi
    ##   .i le nu tcidu cu nitcu lo temci poi jibni `2 s` ne'i lo cikryzba
  STOP_EXPECTED_MOST = 8
    ## lo rairterkancu be lo gerna valsi poi lidne lo nu sisti ku'o ne'i le flalu pe `expects`
  TEXTS_CONSTRUCTED = [
    # `Stream` to'e curmi ki'u lo lerfu ce'o lo lerfu ce'o lo nu basna ce'o lo nu sitna ce'o lo nu
    #     fendi
    "mi 1987 klama", "mi hello klama", "Mi klama", "zoi gy. gyrations .gy. cu glico",
    "la .lauras. klama",
    "mi xau klama", "ba'e xau klama",  # `Selmaho` to lo cmavo be `BAhE` cu tcita le cmavo toi
    "zei mi klama", "mi zei", "si mi klama", "mi klama sa", "bu mi", "mi klama ba'e",  # `Construct`
    # `Quotation`
    #   .i lo nu sitna poi no roi selfa'o ce'o lo nu sitna poi kunti ce'o lo nu sitna poi lo pagbu
    #       be ke'a cu se vimcu to `CLL 19.13` toi
    "mi cusku lo'u mi klama", "mi cusku lo'u .i mi klama", "mi cusku zo", "lo'u le'u",
    "mi se cmene zo .djan. si .djordj.",
    # `Grammar`
    #   .i lo selci'a poi selka'a ce'o lo pagbu ce'o zo lu poi kalri ce'o lo jonma'o ce'o lo
    #       fa'orma'o
    "mi klama le", "mi klama le .i do citka", "lu mi klama le", "ge mi gi",
    "mi klama le zarci ku ku",
    "si mi 1987 xau klama le",  # ro velru'e cu to'e curmi ne'i pa selci'a
    # zo su poi fanmo lo selci'a poi vasru lo srera
    "si su mi klama", "mi 1987 su klama", "lu mi su do li'u",
  ]
    ## lo selci'a poi selfi'i fi ro velru'e poi to'e curmi ku'o .e ro stuzi poi le gerna cu sisti
    ##     bu'u ke'a
  TEXTS_PARTED = [
    "mi klama su do", "mi su", "su do", "mi su su do", "ba'e su mi", "mi ui su ui do",
    "mi klama le su do", "lu mi su do", "lo'u mi su do le'u", "mi cusku zo su",
    "mi klama si do", "do sa mi klama", "mi si su do si ko", "mi fa'o .i ko 1987",
    "ba'e mi si do",  # lo nu vimcu .e zo fa'o .e lo valsi poi se lidne zo fa'o
  ]
    ## lo selci'a poi `readText` tcidu ke'a zi'e poi zo su fendi ke'a
    ##   .i su'o selci'a cu vasru lo srera poi lidne zo su
    ##   .i su'o selci'a cu vasru zo su poi se sitna
    ##   .i su'o selci'a cu vasru no srera gi'e na vasru zo su poi se sitna
    ##   .i ba bo le liste cu vasru lo selci'a poi vasru lo valsi poi no velru'e cu tcidu ke'a
    ##   .i ro le selci'a cu selfi'i
    ##   .i ki'u bo no le selci'aste cu vasru zo su poi fendi lo selci'a
  TEXTS_COVERED = [
    "le,nu mi klama", "mi KLAmaku", "zoi gy. a, b .gy. cu glico", "mi klama si si fa'omi do",
    "mi 1987 ui", "ba'e mi si do", "lo'u mi su do", "zo su si si", "mi klama fa'o\t.ui\n",
  ]
    ## lo selci'a poi selfi'i fi le flalu pe lo gacri
    ##   .i le selci'a cu vasru slaka bu .e lo brale'u .e lo nu sitna poi vasru lo sinxa ku'o .e lo
    ##       valsi poi no pagbu cu vasru ke'a ku'o .e lo valsi poi zvati lo jbini be lo valsi .e lo
    ##       cnivla poi tcita le valsi
  EXAMPLES_MARKED = [
    # le selci'avla cu zvati lo jbini be lo sumti .e lo brirebla poi sruri le selci'avla
    (
      text: "mi 1987 klama",
      module: "(sentence 0 (sumti_6 80 (KOhA 0 2 \"mi\")) " &
        "(rivbi Stream Letter 3 7 \"1987\") (bridi_tail_3 50 " &
        "(tanru_unit_2 130 (BRIVLA 8 13 \"klama\")) (tail_terms)))",
    ),  # lo selci'avla poi lo porsi be lo valsi cu to'e curmi ke'a
    (
      text: "mi xau klama",
      module: "(sentence 0 (sumti_6 80 (KOhA 0 2 \"mi\")) (rivbi selmaho 3 6 \"xau\") " &
        "(bridi_tail_3 50 (tanru_unit_2 130 (BRIVLA 7 12 \"klama\")) (tail_terms)))",
    ),  # lo cmavo poi no liste cu dunda lo selma'o ke'a
    # zo zei zvati le genja pu ro pagbu poi se tcidu
    (
      text: "zei mi klama",
      module: "(text (rivbi Construct 0 3 \"zei\") (sentence 2 (sumti_6 80 " &
        "(KOhA 4 6 \"mi\")) (bridi_tail_3 50 (tanru_unit_2 130 (BRIVLA 7 12 \"klama\")) " &
        "(tail_terms))))",
    ),  # zo zei poi jorne no valsi poi lidne zo zei to `CLL 4.6` toi
    # zo lo'u zvati pa pagbu poi vasru zo lo'u po'o
    #   .i lo valsi poi se lidne zo lo'u se tcidu
    (
      text: "mi cusku lo'u .i mi klama",
      module: "(paragraph 0 (sentence 11 (sumti_6 80 (KOhA 0 2 \"mi\")) (bridi_tail_3 " &
        "50 (tanru_unit_2 130 (BRIVLA 3 8 \"cusku\")) (tail_terms))) " &
        "(rivbi Quotation 9 13 \"lohu\") (I 15 16 \"i\") (sentence 11 (sumti_6 80 " &
        "(KOhA 17 19 \"mi\")) (bridi_tail_3 50 " &
        "(tanru_unit_2 130 (BRIVLA 20 25 \"klama\")) (tail_terms))))",
    ),  # zo lo'u poi zo le'u na fanmo lo nu sitna pe ke'a to `CLL 19.9` .e `#859` toi
    # le gerna cu sisti bu'u le fanmo be le selci'a ne'i `sumti-6` noi ckini li soze gi'e denpa
    (
      text: "mi klama le",
      module: "(srera 11 sumti_6 (nitcu BAI BU BY CAhA COI CUhE DOI FAhA FEhE FIhO GOI " &
        "GOhA GUhA JAI KE KI KOhA LA LAU LAhE LE LI LOhU LU ME MOhI NA NAhE NOI NU NUhA PA PU " &
        "SE SEI SOI TAhE TEI TO VA VEI VEhA VIhA XI ZAhO ZEI ZEhA ZI ZO ZOI BRIVLA) " &
        "(sentence 0 (sumti_6 80 (KOhA 0 2 \"mi\")) (bridi_tail_3 50 " &
        "(tanru_unit_2 130 (BRIVLA 3 8 \"klama\")) (tail_terms))) (LE 9 11 \"le\"))",
    ),  # le selci'a cu selka'a ba zo le
    # le selci'a poi lidne zo su stali ta'i lo nu pu se tcidu kei gi'e lidne lo selci'a poi se lidne
    #     zo su
    (
      text: "mi klama su do",
      module: "(text (sentence 0 (sumti_6 80 (KOhA 0 2 \"mi\")) (bridi_tail_3 50 " &
        "(tanru_unit_2 130 (BRIVLA 3 8 \"klama\")) (tail_terms))) (rivbi SU 9 11 \"su\") " &
        "(sumti_6 2 (KOhA 12 14 \"do\")))",
    ),  # zo su fanmo lo selci'a poi lidne ri to lo seljdi pe `#859` toi
    # zo fa'o poi fanmo le selci'a ku'o .e lo valsi poi se lidne zo fa'o zi'e noi stali ta'i lo nu
    #     selci'a
    (
      text: "mi klama si do fa'o ko",
      module: "(text (terms 2 (sumti_6 81 (KOhA 0 2 \"mi\")) " &
        "(rivbi Erasure 3 8 \"klama\" 9 11 \"si\") (sumti_6 81 (KOhA 12 14 \"do\"))) " &
        "(rivbi FAhO 15 19 \"faho\") (rivbi Stream FAhO 20 22 \"ko\"))",
    ),  # lo valsi poi zo si vimcu ke'a kansa zo si
  ]
    ## lo selci'a poi selfi'i
    ##   .i ro le selci'a cu kansa lo gejyjge pe le selci'a be fi `NIF` be'o poi `nif.nim` ciska
    ##       ke'a
    ##   .i le cipra cu cipra ro lerfu pe le gejyjge



#[ ni'o ni'o ni'o lo tcidu ]#

func leaves(node: Node): seq[int] =
  ## dunda lo liste be lo namcu pe ro pezli poi zvati ne'i le jgena ku'o ta'i le porsi pe le tricu
  if node.is_terminal: return @[node.at]
  for child in node.children: result.add child.leaves


func isRead(marked: ReadingMarked, unit: Unit): bool =
  ## jdice lo du'u xu kau su'o velru'e cu tcidu gi'a to'e curmi le pagbu
  ##   .i su'o velru'e cu tcidu gi'a to'e curmi le pagbu va'o lo nu le pagbu cu na du zo su .a lo
  ##       valsi poi lo nu vimcu cu vimcu ke'a ku'o .a zo fa'o poi fanmo le selci'a ku'o .a lo valsi
  ##       poi se lidne zo fa'o
  if unit.is_read: return true
  if unit.refusal in {RefusalText.Su, RefusalText.Erasure, RefusalText.Faho}: return false
  unit.refusal != RefusalText.Stream or
    marked.occurrences[unit.words[0]].reading.refusal != Refusal.Faho


func dropUnread(node: var Node, marked: ReadingMarked) =
  ## vimcu ro pezli pe lo pagbu poi no velru'e cu tcidu ke'a ku'o le jgena ja'i `isRead`
  if node.is_terminal: return
  node.children.keepItIf(not it.is_terminal or marked.isRead(marked.units[it.at]))
  for child in node.children.mitems: child.dropUnread(marked)


func isHolding(marked: ReadingMarked, unit: Unit, start: int): bool =
  ## jdice lo du'u xu kau le pagbu cu vasru lo valsi poi lo stuzi be ke'a ta'i lo nu le selci'a cu
  ##     ciska ke'a cu vasru le stuzi po'u `start`
  for k in unit.words:
    let occurrence = marked.occurrences[k]
    if occurrence.start <= start and start < occurrence.start + occurrence.text.len: return true
  false


func isMarking(marked: ReadingMarked, strict: ReadingText): bool =
  ## jdice lo du'u xu kau le se tcidu poi sinxa ro srera cu vasru lo sinxa be lo nu `readText` to'e
  ##     curmi be'o pe le velru'e poi to'e curmi
  ##   .i ne'i `Stream` le sinxa cu du lo pagbu pe lo selci'avla poi le porsi be lo valsi cu to'e
  ##       curmi ke'a
  ##   .i le pagbu cu vasru le stuzi pe le nu to'e curmi
  ##   .i ne'i lo javni pe `CLL 19.16` le sinxa cu du lo pagbu pe le javni poi to'e curmi
  ##   .i le porsi be lo valsi cu to'e curmi no da
  ##   .i ne'i `Selmaho` le sinxa cu du lo pagbu pe lo selma'o zi'e poi vasru le stuzi
  ##   .i lo selma'o po'o cu to'e curmi
  ##   .i ne'i `Grammar` le sinxa cu du lo srejge poi zvati le genja gi'e ponse le javni gi'e sisti
  ##       bu'u le stuzi
  ##   .i ro pagbu cu se tcidu
  ##   .i lo pagbu poi no velru'e cu tcidu ke'a na du lo nu to'e curmi
  ##   .i se ki'u bo le flalu na tcidu le pagbu to `isRead` toi
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
    # `readText` to'e curmi no selci'a ki'u lo velru'e poi tcidu no valsi


func terminalsRead(marked: ReadingMarked): seq[Terminal] =
  ## dunda lo genvla pe ro pagbu poi le gerna cu tcidu ke'a ku'o ta'i le porsi
  for unit in marked.units:
    if unit.is_read: result.add unit.terminal


func isSameShifted(a, b: Node, by: int): bool =
  ## jdice lo du'u xu kau le tricu po'u `a` du le tricu po'u `b` va'o lo nu `by` se jmina fi lo
  ##     namcu pe ro genvla
  ##   .i le re tricu cu ponse lo mi'ujva .e lo mitna'u .e lo mitstu poi le gerna cu sisti bu'u ke'a
  ##       ku'o ta'i lo mitpoi
  if a.is_terminal != b.is_terminal: return false
  if a.is_terminal: return a.at == b.at + by
  if a.rule != b.rule or a.number != b.number or a.children.len != b.children.len: return false
  if a.stop.isSome != b.stop.isSome: return false
  for k in 0 ..< a.children.len:
    if not a.children[k].isSameShifted(b.children[k], by): return false
  true


func addBranches(node: Node, branches: var seq[Node]) =
  ## jmina ro jimca poi lo srejge poi zvati ne'i `node` vasru ke'a zi'e poi selkra `text` zi'e noi
  ##     se tcidu ta'i pa mulselci'a
  if node.is_terminal: return
  for child in node.children:
    if node.stop.isSome and not child.is_terminal and child.stop.isNone and child.number == 0:
      branches.add child
    child.addBranches(branches)


func covers(tree: Node, terminals: openArray[Terminal]): seq[Node] =
  ## dunda ro srejge pe le tricu zi'e poi vasru lo jimca .e lo genvla poi zvati lo jbini be le jimca
  ##   .i dunda le genja va'o lo nu le selci'a cu vasru pa pagbu po'o
  ##   .i va'o lo datydu'a ro srejge pe lo pagbu be le se ciska to `toParts` toi
  if tree.stop.isNone: return
  let
    split = terminals.toParts(0, terminals.len)
    is_parted = split.parts.len > 1 or split.inner < terminals.len
  if not is_parted: return @[tree]
  for child in tree.children:
    if not child.is_terminal and child.stop.isSome: result.add child


func classes(): seq[Terminal] =
  ## dunda ro klesi be lo genvla poi le gerna cu tcidu ke'a
  ##   .i le klesi cu du ro selma'o ce'o `BRIVLA` ce'o `CMENE`
  for selmaho in Selmaho: result.add selmaho.toTerminal
  result.add TERMINAL_BRIVLA
  result.add TERMINAL_CMENE


func isReadPast(terminals: openArray[Terminal], at: int): bool =
  ## jdice lo du'u xu kau le gerna cu tcidu le genvla ba le stuzi po'u `at`
  ##   .i le gerna cu tcidu ro le genvla gi'a sisti ba le stuzi
  let reading = terminals.readGrammar
  reading.is_read or reading.at > at

func isSame(marked: ReadingMarked, strict: ReadingText): bool =
  ## jdice lo du'u xu kau le se tcidu poi sinxa ro srera cu vasru ro pagbu pa roi ta'i lo pezli ta'i
  ##     le porsi
  ##   .i ji'a ba zo su noi romoi ku'o le re se tcidu cu vasru lo mitpau .e lo mi'uvla .e lo
  ##       mitselci'a be fi `NIF`
  ##   .i le genja cu vasru ca lo krasi le tricu pe ro selci'a poi lidne zo su noi romoi
  ##   .i ro le tricu cu lidne lo pezli pe zo su
  ##   .i le flalu cu vimcu le tricu .e le pezli
  ##   .i ji'a le flalu cu vimcu ro pezli pe lo pagbu poi no velru'e cu tcidu ke'a mu'u lo valsi poi
  ##       lo nu vimcu cu vimcu ke'a ku'o .e zo fa'o .e lo valsi poi se lidne zo fa'o
  var
    first = 0  # le pamoi pagbu poi se lidne zo su noi romoi
    cut = 0  # lo te kancu be lo panzi be le genja be'o poi lidne ja du le pezli pe zo su noi romoi
  for k in 0 ..< marked.units.len:
    if not marked.units[k].is_read and marked.units[k].refusal == RefusalText.Su: first = k + 1
  for k in 0 ..< marked.tree.children.len:
    template child: untyped = marked.tree.children[k]
      ## lo datcme be lo panzi be le genja
      ##   .i `let` zbasu lo fukpi be le panzi
    if first > 0 and child.is_terminal and child.at == first - 1: cut = k + 1
  var past = marked  # le se tcidu pe le selci'a poi se lidne zo su noi romoi
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
  ## tcidu ro selci'a pe le selci'aste pa roi sepi'o le re tcidu gi'e ralte ro selci'a poi se to'e
  ##     curmi
  ##   .i ba bo tcidu ro selci'a poi selfi'i
  ##   .i `readText` to'e curmi ji'a ro le selci'a poi selfi'i
  ##   .i le flalu pe lo gacri cu tcidu ji'a ro selci'a pe le selci'aste
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
    # lo selci'a poi se tcidu cu dunda le pu se tcidu
    check pool.differing == newSeq[string]()  # ja'i le krapinka pe `prose.nim`
    # lo bandu cu ralte lo selci'a poi se tcidu
    check pool.count_read >= COUNT_READ_LEAST  # ja'i `IX.3`
    for text in TEXTS_PARTED:
      checkpoint text
      let strict = text.readText
      check strict.is_read and text.readTextMarked.isSame(strict)
        # ja'i le krapinka pe `prose.nim` zo su fanmo lo selci'a poi lidne ri
        #   .i le se tcidu poi sinxa ro srera cu ralte le selci'a


  test "Each byte of each word lies in one leaf, in order, and each other byte is mark":
    # ro valsi cu jorne lo stuzi
    check pool.uncovered == newSeq[string]()  # ja'i le krapinka pe `nif.nim`
    for text in TEXTS_CONSTRUCTED.toSeq & TEXTS_PARTED.toSeq & TEXTS_COVERED.toSeq:
      checkpoint text
      # ro valsi cu zvati pa pezli
      check text.readTextMarked.isCovering(text)  # ja'i le krapinka pe `prose.nim`
      # ro valsi pe lo mivyselci'a cu zvati pa pezli
      check readTextParts(text).reading.isCovering(text)  # ja'i le krapinka pe `prose.nim`


  test "Text readText refuses gives tree of each unit once, in order, and its NIF reads back":
    var
      broken: seq[string]
      count = 0
    for (key, text, strict, marked) in pool.refused:
      checkpoint key & ": " & text
      check not strict.is_read  # le flalu cu tcidu lo se ciska po'o poi se to'e curmi
      if strict.is_read: continue
      if key != "constructed": inc count
      let
        held = marked.units.mapIt(it.words).concat
        is_whole = marked.tree.leaves == toSeq(0 ..< marked.units.len) and
          toSeq(1 ..< marked.units.len).allIt(
            marked.units[it - 1].words[0] < marked.units[it].words[0]
          ) and held.deduplicate.len == held.len
      if not (is_whole and marked.isMarking(strict) and marked.isReadBack): broken.add key
    # ro pagbu cu zvati le stuzi pe vo'a
    #   .i lo nu to'e curmi cu selsni
    check broken == newSeq[string]()  # ja'i le krapinka pe `prose.nim`
    # lo bandu cu ralte lo selci'a poi se to'e curmi
    check count >= COUNT_REFUSED_LEAST  # ja'i `IX.3`


  test "Each branch of error node that heads text is tree its terminals give read alone":
    var count = 0
    for (key, text, strict, marked) in pool.refused:
      checkpoint key & ": " & text
      let
        terminals = marked.terminalsRead
        tree = terminals.readGrammarMarked
      # ro genvla cu zvati pa roi
      check tree.leaves == toSeq(0 ..< terminals.len)  # ja'i le krapinka pe `grammar.nim`
      var branches: seq[Node]
      tree.addBranches(branches)
      for branch in branches:
        let
          span = branch.leaves
          alone = terminals[span[0] .. span[^1]].readGrammar
        # le jimca cu kuspe pa porsi be lo genvla
        check span == toSeq(span[0] .. span[^1])  # ja'i le krapinka pe `grammar.nim`
        check alone.is_read and alone.tree.isSameShifted(branch, -span[0])
          # ja'i le krapinka pe `grammar.nim` le jimca cu du le tricu poi le valsi po'o pe le jimca
          #     cu dunda ke'a
        inc count
    check count >= COUNT_REFUSED_LEAST  # ja'i `IX.3` lo bandu cu ralte lo jimca


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
          # ja'i le krapinka pe `grammar.nim` lo genvla poi su'o nu genytcidu cu ka'e tcidu ke'a
          #     bu'u lo stuzi poi le gerna cu sisti bu'u ke'a
      inc count
    check count == COUNT_EXPECTED  # ja'i `IX.3` lo bandu cu ralte lo nu sisti


  test "Worked examples write as module suites hold, byte for byte, and read back":
    for (text, module) in EXAMPLES_MARKED:
      checkpoint text
      let marked = text.readTextMarked
      check marked.toNif == "(.nif27)\n(.lang \"cll-21.1\")\n" & module & "\n"
        # ja'i le krapinka pe `nif.nim` lo srejge .e lo pagbu po'u `unread`
      # lo tricu poi selrapyzba ta'i lo mulno
      check marked.isReadBack  # lo morna pe le tarmi

  test "Cover leaves out no terminal that reads alone, nor two pieces that read as one text":
    var count = 0
    for (key, text, strict, marked) in pool.refused:
      checkpoint key & ": " & text
      let terminals = marked.terminalsRead
      for cover in terminals.readGrammarMarked.covers(terminals):
        for k, piece in cover.children:
          if piece.is_terminal:
            check not terminals[piece.at .. piece.at].readGrammar.is_read
              # ja'i le krapinka pe `grammar.nim` lo gacri cu cliva lo mecraigenvla
          if k == 0: continue
          let span = cover.children[k - 1].leaves[0] .. piece.leaves[^1]
          check not terminals[span].readGrammar.is_read
            # ja'i le krapinka pe `grammar.nim` lo gacri cu pilno lo mecraispi
            #   .i no re spisa poi lamji cu se tcidu ta'i pa `text`
        inc count
    check count >= COUNT_COVERS_LEAST  # ja'i `IX.3` lo bandu cu ralte lo gacri


  test "Error node of text cut into parts holds tree of each part that reads alone":
    for text in ["mi klama le .i do citka", "mi klama le ni'o do citka"]:
      checkpoint text
      let tree = text.readTextMarked.tree
      # le srejge cu vasru re pagbu
      check tree.stop.isSome and tree.children.len == 2  # ja'i le krapinka pe `grammar.nim`
      # lo pagbu poi na se tcidu
      check tree.children[0].stop.isSome  # ja'i le krapinka pe `grammar.nim`
      check tree.children[1].stop.isNone and tree.children[1].number == 0
        # ja'i le krapinka pe `grammar.nim` lo pagbu poi se tcidu ta'i pa mulselci'a
        #   .i le pagbu cu selkra `text`
    let open = "lu mi klama le .i do citka".readTextMarked.tree
    check open.stop.isSome and open.children.allIt(it.is_terminal or it.stop.isNone)
      # ja'i le krapinka pe `grammar.nim` lo selci'a poi zo lu stali lo ka kalri ne'i ke'a cu du pa
      #     pagbu poi vasru lo jimca
