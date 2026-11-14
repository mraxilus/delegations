## cipra lo du'u lo nu jmina lo pagbu to `merge.nim` toi cu mapti lo nu tcidu le mulno se ciska to
##   `D1 b` pe `#859` toi .i ba bo la'o gy. Architect .gy. cu jdice bu'u `#859` lo du'u lo nu jmina
##   cu jmina ro porsi be lo pagbu poi sruri lo srera .i lo se ciska be fi la'o gy. NIF .gy. be'o pe
##   lo pagbu be lo se ciska be'o ge'u zi'e poi `toNifParts` cu ciska ke'a cu se jmina fo lo se
##   dunda be lo nu tcidu le mulno se ciska .i lo nu jmina cu to'e curmi no srera
##   .i ro flalu cu jdice ja'i lo se dunda be lo nu tcidu le mulno se ciska
##     .i va'o lo nu lo nu tcidu le mulno se ciska cu tcidu lo se ciska kei le se ciska cu se jmina
##       fo lo se ciska be fi la'o gy. NIF .gy. be'o poi `readText` cu ciska ke'a .i ro lerfu cu
##       mintu .i `is_whole` cu jetnu
##     .i lo se ciska poi no pagbu be ke'a cu vasru lo srera jgena cu se jmina fo le se tcidu poi
##       sinxa ro srera ca lo nu tcidu le mulno se ciska to `readTextMarked` toi .i ro pagbu poi lo
##       nu tcidu le mulno se ciska cu ralte no valsi pe ke'a cu se vimcu ta'i lo nu lo nu jmina cu
##       vimcu le pagbu .i ro pagbu poi su'o ve pruce cu to'e curmi ke'a cu zvati lo stuzi pe vo'a
##       .i lo srera jgena cu gapru lo pagbu poi na se jorne
##     .i lo se ciska poi su'o pagbu be ke'a cu vasru lo srera jgena cu ralte ro pagbu poi vasru lo
##       srera jgena ku'o gi'e na galfi le pagbu gi'e jmina ro porsi be lo pagbu poi zvati lo jbini
##       be le pagbu ku'o be'o fo le se tcidu poi sinxa ro srera ca lo nu tcidu lo se ciska pe le
##       porsi po'o .i di'u jetnu va'o lo nu le se ciska pe le porsi cu dunda le mintu valsi .i lo
##       valsi poi bancu lo krasi be le porsi cu se tcidu ta'i lo drata va'o lo nu le porsi cu se
##       tcidu po'o .i mupli fa lo nu zo si .a zo sa .a zo zei .a zo bu cu galfi lo valsi poi lidne
##       lo krasi be le porsi .i mupli fa lo nu lo nu sitna sepi'o zo lo'u .a zo la'o .a zo zoi cu
##       bancu le krasi
##     .i lo se ciska poi lo nu tcidu le mulno se ciska cu to'e curmi ke'a cu ralte ro valsi pe lo
##       pagbu pe vo'a ta'i lo porsi .i ro pagbu poi lo nu tcidu le mulno se ciska cu ralte no valsi
##       pe ke'a cu se vimcu .i se ki'u bo no porsi cu cirko lo pagbu poi lo flalu pe lo porsi cu na
##       viska ke'a
##   .i le flalu cu tcidu ro se ciska pe le se ciska liste .e lo se ciska poi se zbasu fi lo valsi
##     poi galfi lo pu valsi to `texts_built.nim` toi .i ki'u bo le se ciska liste cu vasru so'u lo
##     se ciska poi vasru le valsi .i ro se ciska cu se katna re roi .i pa roi le se ciska cu se
##     katna ta'i lo nu tcidu le mulno se ciska .i pa roi le se ciska cu se katna ta'i lo jmive se
##     ciska .i lo se ciska poi lo nu tcidu le mulno se ciska cu to'e curmi ke'a gi'e vasru zo su cu
##     zvati lo mupli po'o .i ki'u bo le se tcidu poi sinxa ro srera cu ralte lo se ciska poi lidne
##     zo su .i ku'i lo nu jmina cu vimcu le se ciska
##   .i lo jmive pagbu poi se katna ba pa cfari valsi poi denpa cu ka'e frica lo pagbu pe lo nu
##     tcidu le mulno se ciska .i ca lo nu tcidu pa pagbu po'o kei le gerna cu sisti bu'u lo stuzi
##     poi le fanmo valsi cu ka'e zvati ke'a .i se ki'u bo lo nu jmina cu ralte le pagbu ta'i lo
##     pagbu poi vasru pa srera jgena .i ja lo pagbu cu se jmina fo pa drata drani se tcidu .i le se
##     tcidu na vasru le fanmo valsi .i le flalu cu tcidu lo jmive pagbu ta'i lo nu lo jmive se
##     ciska cu katna lo se ciska .i ku'i le flalu na tcidu lo jmive pagbu be lo se ciska poi lo
##     jmive pagbu be ke'a cu na mapti le flalu to `EXAMPLES_LIVE` toi
##   .i lo mupli cu jarco ro nu vimcu .e ro stuzi .i lo mupli cu vasru lo'u ni'o ni'o le'u .e zo
##     tu'e .e lo'u .ibo le'u .e lo cmavo be zoi gy. COI .gy. be'o .e zo si .e zo su .e zo fa'o .i
##     ji'a lo mupli cu vasru lo pagbu poi zvati lo stuzi pe vo'a ku'o .e lo porsi poi sruri lo
##     srera jgena ku'o .e lo pagbu poi lidne zo su poi romoi ku'o gi'e rinka lo nu lo nu tcidu le
##     mulno se ciska cu to'e curmi le se ciska to `CLL 19.16` toi ku'o .e lo jmive pagbu poi frica
##     .i ro mupli cu jdice lo krasi be lo jgena poi vasru lo srera .i le krasi cu du lo stuzi poi
##     le gerna cu sisti bu'u ke'a ku'o ce'o lo javni ce'o lo namcu .i ja le krasi cu du lo pagbu
##     ce'o lo valsi pe le pagbu
##   .i lo nu rapli zbasu cu cirko no da .i lo tricu poi ro jgena pe lo se ciska be fi la'o gy. NIF
##     .gy. cu rapli zbasu ke'a cu rapli ciska le jgena .i ro lerfu cu mintu .i le sinxa cu se kancu
##     ji'a to `toNif` pe lo tricu .e lo pezli toi .i le flalu cu tcidu ro se ciska pe le se ciska
##     liste ge'u .e ro se ciska poi se zbasu ku'o .e lo se ciska poi se finti .i ro nu katna cu se
##     kancu
##   .i lo se ciska be fi la'o gy. NIF .gy. be'o poi na se tcidu gi'a vasru lo tarmi poi le ciska na
##     ciska ke'a cu se to'e curmi .i lo nu jmina cu no roi renro lo srera

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[options, random, strutils, unittest]

import ../../src/lojban_parser/[merge, nif, nif_read, prose]
import ./[corpora, texts_built]


const
  SEED = 859  ## lo tsiju be lo se ciska poi se zbasu
  COUNT_BUILT = 1500
    ## lo klani be lo se ciska poi se zbasu fi lo valsi poi galfi lo pu valsi .i ro le se ciska cu
    ##   se katna ta'i ro lo re tadji
  COUNT_READ_LEAST = 1800
    ## lo klani be lo se ciska pe le se ciska liste zi'e poi lo nu tcidu le mulno se ciska cu tcidu
    ##   ke'a .i le se ciska liste cu vasru pasovopa se ciska .i ca lo nu le flalu cu se jmina kei
    ##   le klani cu du li pabicipa
  COUNT_PARTED_LEAST = 100
    ## lo klani be lo se ciska pe le se ciska liste zi'e poi lo nu tcidu le mulno se ciska cu tcidu
    ##   ke'a gi'e se katna fi su'o re jgena .i ca lo nu le flalu cu se jmina kei le klani cu du li
    ##   pacici
  COUNT_MARKED_LEAST = 350
    ## lo klani be lo se ciska poi lo nu tcidu le mulno se ciska cu to'e curmi ke'a .i le se ciska
    ##   cu pagbu le se ciska liste gi'a se zbasu .i ro nu katna cu se kancu .i no pagbu be le se
    ##   ciska cu vasru lo srera jgena .i ca lo nu le flalu cu se jmina kei le klani cu du li cibibi
  COUNT_RUNS_LEAST = 900
    ## lo klani be lo porsi be lo pagbu be'o poi se jmina gi'e sruri lo srera jgena .i le porsi cu
    ##   pagbu lo se ciska pe le se ciska liste ge'u .a lo se ciska poi se zbasu .i ro nu katna cu
    ##   se kancu .i va'o lo nu le se ciska pe le porsi cu se tcidu po'o kei le se ciska cu dunda le
    ##   mintu valsi .i ca lo nu le flalu cu se jmina kei le klani cu du li socize
  RUNS_OUTSIDE_MOST = 0.1
    ## lo frinu pe lo porsi poi lo se ciska pe ke'a cu dunda lo drata valsi va'o lo nu le se ciska
    ##   cu se tcidu po'o .i le frinu cu mleca ja du le vi namcu .i ca lo nu le flalu cu se jmina
    ##   kei le frinu cu du li no pi no ze so .i ro le porsi cu frica ki'u lo valsi poi bancu lo
    ##   krasi be le porsi
  COUNT_BUILT_READ_LEAST = 200
    ## lo klani be lo se ciska poi se zbasu gi'e se tcidu ca lo nu tcidu le mulno se ciska .i ca lo
    ##   nu le flalu cu se jmina kei le klani cu du li rexaci
  COUNT_BUILT_SU_LEAST = 30
    ## lo klani be lo se ciska poi se zbasu gi'e se tcidu ca lo nu tcidu le mulno se ciska gi'e
    ##   vasru zo su poi fanmo lo se ciska poi lidne zo su .i ca lo nu le flalu cu se jmina kei le
    ##   klani cu du li voxa
  MARKS_TRAILING = {' ', '\t', '\n', '.', ','}
    ## lo sinxa poi zvati lo jbini be lo valsi gi'e fanmo lo se ciska .i la'o gy. NIF .gy. cu dunda
    ##   no stuzi pe le sinxa .i se ki'u bo lo nu jmina cu sisti pu le sinxa
  TEXTS_MERGED = [
    # re cmavo be zoi gy. NIhO .gy. cu krasi lo pamoi jufra girzu
    "ni'o ni'o mi klama .i do cadzu",  # `text-1<2>`
    # lo cmavo be zoi gy. NIhO .gy. cu punji lo jufra girzu poi se lidne lo pamoi jufra girzu ku'o
    #   ne'i lo jgena
    "mi klama ni'o do cadzu .i ko",  # `paragraphs<4>`
    # lo se ciska ne'i lo se ciska
    "tu'e mi klama .i do cadzu tu'u .i ko",  # `statement-3<14>`
    "mi klama .ibo do cadzu",  # lo'u .ibo le'u cu jorne lo jufra ne'i pa pagbu
    # lo cmavo be zoi gy. COI .gy. cu krasi le se ciska
    "coi do .i mi klama",  # .i le cmavo cu lidne lo pamoi pagbu
    "lu mi klama .i do cadzu li'u .i ko",  # zo li'u cu fanmo lo se ciska poi se sitna
    # lo jmive se ciska poi se katna ba zo lu cu na mapti le javni pe le so'i nu tcidu
    "lu mi klama .i do cadzu",  # .i se ki'u bo le gerna cu tcidu ro gerna valsi ca pa nu tcidu
    # lo nu vimcu cu klama ne'i lo pagbu poi lidne le nu vimcu
    "mi klama .i do cadzu si si si ko",  # `CLL 19.13`
    "le su mi klama",  # lo srera pe le gerna poi lidne zo su cu se vimcu
    # lo selma'o cu se tcidu ba lo nu zo su cu vimcu
    "xu'au su mi klama",  # .i se ki'u bo lo cmavo poi no liste cu dunda lo selma'o ke'a cu se vimcu
    # zo zei cu se tcidu ba lo nu zo su cu vimcu .i se ki'u bo lo srera pe zo zei cu se vimcu
    "zei su mi klama",  # `CLL 19.16`
    # lo cmavo be zoi gy. BAhE .gy. cu se tcidu ba lo nu zo su cu vimcu .i se ki'u bo lo srera pe le
    #   cmavo cu se vimcu
    "ba'e su mi klama",  # `CLL 19.16`
    # zo bu cu se tcidu ba lo nu zo su cu vimcu .i se ki'u bo lo srera pe zo bu cu se vimcu
    "bu su mi klama",  # `CLL 19.16`
    # lo nu vimcu cu vimcu zo le'u poi fanmo zo lo'u
    "lo'u mi le'u si su ko",  # .i zo su cu vimcu zo lo'u
    # lo cmavo be zoi gy. BAhE .gy. cu lidne zo zoi
    "ba'e zoi gy. a'h .gy. ui su ko",  # .i se ki'u bo lo se sitna cu vomoi valsi
    "zoi gy. ab'h .gy. cu melbi",  # lo se ciska poi zo zoi cu sitna ke'a cu ralte `'` .e `h`
  ]
    ## lo se ciska poi se finti gi'e se tcidu ca lo nu tcidu le mulno se ciska .i lo pagbu be ro le
    ##   se ciska cu se jmina fo lo se ciska be fi la'o gy. NIF .gy. be'o pe le se ciska .i ro le se
    ##   ciska cu se katna ta'i ro lo re tadji
  EXAMPLES_MERGED = [
    (
      text: "ti gerku si mlatu",  # zo si cu vimcu zo gerku to `CLL 19.13` toi
      nif: "(sentence 0 (sumti_6 80 (KOhA 0 2 \"ti\")) " &
        "(bridi_tail_3 50 (tanru_unit_2 130 (BRIVLA 12 17 \"mlatu\")) (tail_terms)))",
    ),
    (
      text: "mi su do .i ko",  # zo su cu fanmo lo se ciska poi lidne zo su to `CLL 19.13` toi
      nif: "(paragraph 0 (sumti_6 20 (KOhA 6 8 \"do\")) (I 10 11 \"i\") " &
        "(sumti_6 20 (KOhA 12 14 \"ko\")))",
    ),
    (
      text: "mi klama fa'o xu",  # zo fa'o cu fanmo le se ciska to `CLL 19.15` toi
      nif: "(sentence 0 (sumti_6 80 (KOhA 0 2 \"mi\")) " &
        "(bridi_tail_3 50 (tanru_unit_2 130 (BRIVLA 3 8 \"klama\")) (tail_terms)))",
    ),
    (
      # le porsi be lo valsi cu to'e curmi `x`
      text: "mi klama .i x .i ko sipna",  # .i `x` cu zvati lo jufra girzu pe vo'a
      nif: "(paragraph 0 (sentence 11 (sumti_6 80 (KOhA 0 2 \"mi\")) " &
        "(bridi_tail_3 50 (tanru_unit_2 130 (BRIVLA 3 8 \"klama\")) (tail_terms))) " &
        "(I 10 11 \"i\") (rivbi Stream Shape 12 13 \"x\") (I 15 16 \"i\") " &
        "(sentence 11 (sumti_6 80 (KOhA 17 19 \"ko\")) " &
        "(bridi_tail_3 50 (tanru_unit_2 130 (BRIVLA 20 25 \"sipna\")) (tail_terms))))",
    ),
  ]
    ## lo se ciska poi se finti .e lo tricu poi lo pagbu be le se ciska cu se jmina fo ke'a .i ro
    ##   lerfu pe le tricu cu mintu lo se dunda be lo nu tcidu le mulno se ciska
  EXAMPLES_KEPT = [
    (text: "x su mi klama", count: 2, held: @[(0, "(rivbi Stream Shape 0 1 \"x\")")]),
      # le porsi be lo valsi cu tcidu le mulno se ciska pu lo nu zo su cu vimcu .i se ki'u bo `x` cu
      #   stali bu'u lo krasi
    (text: "si su mi klama", count: 2, held: @[(0, "(rivbi Construct 0 2 \"si\")")]),
      # zo si poi vimcu no da cu se tcidu pu lo nu zo su cu vimcu to `CLL 19.13` toi
    (text: "lo'u su ko", count: 2, held: @[(0, "(rivbi Quotation 0 4 \"lohu\")")]),
      # zo lo'u poi no zo le'u cu fanmo ke'a cu sitna zo su to `CLL 19.9` toi
    (text: "mi su si do", count: 1, held: @[(0, "(text (rivbi Construct 6 8 \"si\") (sumti_6 ")]),
      # zo si poi vimcu no da gi'e se lidne zo su poi romoi ku'o cu zvati le porsi gi'e lidne lo
      #   pamoi pagbu poi se tcidu
    (text: "mi klama .i le", count: 2, held: @[(1, "(srera 14 sumti_6 (nitcu ")]),
      # zo le cu denpa lo sumti ba lo fanmo be le se ciska .i se ki'u bo lo pagbu pe zo le cu stali
    (text: "mi klama .i do cadzu .i le .i ko sipna .i mi klama", count: 3,
      held: @[(1, "(srera 28 sumti_6 (nitcu ")]),
      # lo porsi poi zvati ro lo re mlana be lo pagbu poi vasru zo le cu se jmina
    (text: "cadzu ni'o", count: 1, held: @[(0, "(srera 10 paragraphs (nitcu ")]),
      # ro pagbu cu se tcidu ta'i lo nu sepli .i lo srera jgena cu gapru ro le re pagbu ta'i lo nu
      #   lo nu tcidu le mulno se ciska cu sinxa le srera
    (text: "ui cadzu ni'o do si", count: 1, held: @[(0, "(srera 19 paragraphs (nitcu ")]),
      # le gerna cu sisti ba lo valsi poi lo nu vimcu cu vimcu ke'a bu'u lo fanmo be le se ciska
      #   ku'o ta'i lo nu lo nu tcidu le mulno se ciska cu sinxa le nu sisti
    (text: "cadzu ni'o fa'o xu", count: 1, held: @[(0, "(srera 11 paragraphs (nitcu ")]),
      # le gerna cu sisti bu'u lo stuzi poi zo fa'o cu fanmo le se ciska bu'u ke'a ku'o ta'i lo nu
      #   lo nu tcidu le mulno se ciska cu sinxa le nu sisti to `CLL 19.15` toi
  ]
    ## lo se ciska poi se finti gi'e se to'e curmi lo nu tcidu le mulno se ciska .i ro le se ciska
    ##   cu kansa lo klani be lo jgena poi lo nu jmina cu dunda ke'a ku'o be'o .e ro jgena poi vasru
    ##   lo srera jgena .a lo pagbu poi se to'e curmi .i ro le jgena cu kansa lo namcu pe vo'a .e lo
    ##   krasi be vo'a
  EXAMPLES_LIVE = [
    (
      text: ".i lu le'u si gy li'u bu broda do le to .i broda", is_read: true, count: 2,
      held: @[(0, "(srera 41 text (nitcu ")],
    ),  # lo pagbu poi se lidne zo to cu sisti bu'u lo bilga stuzi be zo toi
    (
      text: "lu gy li'u zarci lo lu .i cadzu je bu", is_read: true, count: 2,
      held: @[(0, "(srera 24 sumti_tail (nitcu ")],
    ),  # lo pagbu poi se lidne lo remoi be zo lu cu sisti bu'u lo bilga stuzi be zo li'u
    (
      text: "tu'e to nai .i zo sa'a .i zoi bu", is_read: false, count: 1,
      held: @[(
        0, "(text (statement_3 2 (TUhE 0 4 \"tuhe\") (free (TO 5 7 \"to\") " &
          "(text (NAI 8 11 \"nai\") (text_1)))",
      )],
    ),  # lo pagbu cu se jmina fo lo drata se tcidu .i no zo toi cu se lidne zo nai
  ]
    ## lo se ciska poi se zbasu .i lo jmive pagbu be le se ciska cu na mapti lo flalu .i ku'i lo
    ##   pagbu be le se ciska ta'i lo nu tcidu le mulno se ciska cu mapti le flalu .i le ci se ciska
    ##   cu pagbu lo cinonono se ciska poi se zbasu sepi'o lo tsiju pe le cipra ku'o gi'e se katna
    ##   ta'i ro lo re tadji .i lo namcu pe le ci se ciska cu du li panoremuso .e li pasopavopa .e
    ##   li remucimuvo .i ro mupli cu vasru lo du'u xu kau lo nu tcidu le mulno se ciska cu curmi le
    ##   se ciska pe le mupli .i ji'a ro mupli cu vasru lo jgena poi lo nu jmina lo jmive pagbu cu
    ##   dunda ke'a ta'i le tarmi pe `EXAMPLES_KEPT`
  MODULES_MALFORMED = [
    ("", "should open with directives", -1),  # no minde
    (HEADER & "(sentence 0", "NIF should hold", -1),  # lo jgena poi no roi se fanmo
    (HEADER & "(FOO 0 2 \"mi\")\n", "should name selma'o", 0),  # lo klesi poi cmene no selma'o
    (HEADER & "(sumti_6 1 (KOhA 0 2 \"mi\"))\n", "two ends of chain", 0),  # no porsi pe `CLL 21.1`
    (HEADER & "(sumti_6 80 97 (KOhA 0 2 \"mi\"))\n", "number of rule opening", 0),
      # lo namcu pe lo javni poi fanmo lo porsi .i lo cmene be le javni cu jarco le namcu to lo se
      #   jdice pe `#859` pe la'o gy. comment 6805527878 .gy. toi
    (HEADER & "(sumti_6 97 (KOhA 0 2 \"mi\"))\n", "two ends of chain", 0),
      # lo jgena poi pagbu no porsi ta'i lo nu la'o gy. NIF .gy. pu ciska ke'a .i le jgena cu ka'e
      #   se tcidu ta'i no drata tricu
    (HEADER & "(sumti_9 (KOhA 0 2 \"mi\"))\n", "name of rule of 21.1", 0),  # lo cmene be no javni
    (HEADER & "(KOhA 0 \"mi\")\n", "bytes and letters", 0),  # lo valsi poi ponse no fanmo stuzi
    (HEADER & "(srera 0 sumti_6)\n", "byte, rule and terminals", 0),  # lo srera jgena pe no `nitcu`
    (HEADER & "(srera 0 sumti_6 97 (nitcu BRIVLA))\n", "byte, rule and terminals", 0),
      # lo namcu pe lo javni poi le gerna cu sisti ne'i ke'a .i lo cmene be le javni cu jarco le
      #   namcu to `#859` pe la'o gy. comment 6806614095 .gy. toi
    (HEADER & "(srera 0 sumti_9 (nitcu BRIVLA))\n", "name of rule of 21.1", 0),  # cmene no javni
    (
      HEADER & "(sumti_6 0 (LI 0 4 \"meho\") (number 310 (PA 5 7 \"vo\")))\n" &
        "(FOO 8 10 \"do\")\n",
      "should name selma'o", 1,
    ),  # lo remoi jgena cu cmene no selma'o
  ]
    ## lo se ciska be fi la'o gy. NIF .gy. be'o poi lo nu jmina cu to'e curmi ke'a .i ro le se ciska
    ##   cu vasru no tarmi poi `nif.nim` cu ciska ke'a .i ro le se ciska cu kansa lo pagbu be lo
    ##   krinu be'o .e lo namcu pe lo jgena poi lo nu jmina cu cusku ke'a .i li no cu krasi lo nu
    ##   kancu lo jgena poi se lidne lo minde .i va'o lo nu lo nu jmina cu cusku no jgena kei le
    ##   namcu cu du li ni'u pa



func isHoldingError(node: NodeNif): bool =
  ## jdice lo du'u lo jgena pe la'o gy. NIF .gy. cu vasru pa srera jgena .i lo ni le srera jgena cu
  ##   dizlo cu na vajni
  if node.kind != KindNif.Compound: return false
  if node.text == TAG_ERROR: return true
  for k in 0 ..< node.children.len:
    if node.children[k].isHoldingError: return true


func isDropped(node: NodeNif): bool =
  ## jdice lo du'u le jgena cu du lo pagbu poi lo nu tcidu le mulno se ciska cu ralte no valsi pe
  ##   ke'a .i le pagbu cu se tcita `Erasure` .a `FAhO` .i ja le pagbu cu vasru lo valsi poi se
  ##   lidne zo fa'o
  node.kind == KindNif.Compound and node.text == TAG_UNREAD and node.children.len > 1 and (
    node.children[0].text in ["Erasure", "FAhO"] or
    (node.children[0].text == "Stream" and node.children[1].text == "FAhO")
  )


func stripped(node: NodeNif): NodeNif =
  ## dunda lo fukpi be le jgena .i ro pagbu poi lo nu tcidu le mulno se ciska cu ralte no valsi pe
  ##   ke'a cu se vimcu .i lo ni le pagbu cu dizlo cu na vajni
  result = NodeNif(kind: node.kind, text: node.text, number: node.number)
  for k in 0 ..< node.children.len:
    if not node.children[k].isDropped: result.children.add node.children[k].stripped


func written(node: NodeNif): string =
  ## dunda lo se ciska be fi la'o gy. NIF .gy. be'o pe lo tricu poi le jgena cu rapli zbasu ke'a .i
  ##   ro pagbu poi lo nu tcidu le mulno se ciska cu ralte no valsi pe ke'a cu se vimcu
  var terminals: seq[TerminalNif]
  @[node.stripped.toTree(terminals)].toNif(LeavesNif(terminals: terminals))


func marked(text: string): string =
  ## dunda le se tcidu poi sinxa ro srera ca lo nu tcidu le mulno se ciska .i ro pagbu poi lo nu
  ##   tcidu le mulno se ciska cu ralte no valsi pe ke'a cu se vimcu ta'i lo nu lo nu jmina cu vimcu
  ##   le pagbu .i ro sinxa poi fanmo le se ciska cu se vimcu ji'a .i ki'u bo la'o gy. NIF .gy. cu
  ##   dunda no stuzi pe le sinxa
  readTextMarked(text.strip(leading = false, chars = MARKS_TRAILING)).toNif.readModule[2].written


func span(node: NodeNif, first, past: var int) =
  ## zengau `first ..< past` fi lo ka kuspe ro stuzi pe ro valsi poi le jgena cu vasru ke'a
  if node.kind != KindNif.Compound: return
  for k in 0 ..< node.children.len:
    template child: untyped = node.children[k]
      ## drata cmene le jgena .i `let` cu zbasu lo fukpi be le jgena
    if child.kind == KindNif.Literal:
      first = min(first, node.children[k - 2].number)
      past = max(past, node.children[k - 1].number)
    else: child.span(first, past)


func words(nif: string): seq[TerminalNif] =
  ## dunda lo gerna valsi pe ro jgena pe lo se ciska be fi la'o gy. NIF .gy. ta'i lo porsi
  let module = nif.readModule
  for k in 2 ..< module.len: discard module[k].toTree(result)


func isLiveDiffering(text: string): bool =
  ## jdice lo du'u le se ciska cu du pa se ciska poi lo jmive pagbu be ke'a cu na mapti le flalu to
  ##   `EXAMPLES_LIVE` toi
  for example in EXAMPLES_LIVE:
    if example.text == text: return true


func isHolding(nif: string, count: int, held: openArray[(int, string)]): bool =
  ## jdice lo du'u lo se ciska be fi la'o gy. NIF .gy. cu vasru lo jgena .i lo klani be le jgena cu
  ##   du `count` .i ji'a jdice lo du'u ro jgena poi vasru lo srera jgena .a lo pagbu poi se to'e
  ##   curmi cu zvati lo namcu poi `held` cu dunda ke'a gi'e se krasi lo se dunda be `held`
  let lines = nif.splitLines[2 .. ^2]
  if lines.len != count: return false
  var indexes: seq[int]
  for k in 0 ..< lines.len:
    if "(srera " in lines[k] or "(rivbi " in lines[k]: indexes.add k
  if indexes.len != held.len: return false
  for m in 0 ..< held.len:
    if indexes[m] != held[m][0] or not lines[indexes[m]].startsWith(held[m][1]): return false
  true


func wordsKept(nif: string): seq[TerminalNif] =
  ## dunda lo gerna valsi pe ro jgena pe lo se ciska be fi la'o gy. NIF .gy. ta'i lo porsi .i ro
  ##   pagbu poi lo nu tcidu le mulno se ciska cu ralte no valsi pe ke'a cu se vimcu ta'i lo nu lo
  ##   nu jmina cu vimcu le pagbu
  let module = nif.readModule
  for k in 2 ..< module.len:
    if not module[k].isDropped: discard module[k].stripped.toTree(result)


func isWrittenBack(nif: string): bool =
  ## jdice lo du'u lo tricu poi ro jgena pe lo se ciska be fi la'o gy. NIF .gy. cu rapli zbasu ke'a
  ##   cu rapli ciska le jgena .i ro lerfu cu mintu
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
  ## tcidu ro se ciska pe le se ciska liste .i ba bo tcidu ro se ciska poi se zbasu .i ro se ciska
  ##   cu se tcidu pa roi mu'i lo flalu poi tcidu le se ciska .i le fancu cu dunda lo se tcidu pe lo
  ##   nu tcidu le mulno se ciska .i ji'a le fancu cu dunda lo se ciska be fi la'o gy. NIF .gy. be'o
  ##   pe lo pagbu be le se ciska ta'i ro lo re tadji .i pa tadji cu du lo nu tcidu le mulno se
  ##   ciska .i le drata cu du lo nu lo jmive se ciska cu katna le se ciska
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
  ## jdice lo du'u lo jgena poi `k` cu sinxa ke'a ne'i lo se ciska be fi la'o gy. NIF .gy. be'o poi
  ##   lo nu jmina cu dunda ke'a ku'o cu du le se tcidu poi sinxa ro srera ca lo nu tcidu lo se
  ##   ciska pe le jgena po'o .i di'u jetnu va'o lo nu le se ciska cu dunda le mintu valsi .i ro
  ##   stuzi poi lidne le jgena cu se basti lo kunti lerfu .i le se ciska cu se katna bu'u lo stuzi
  ##   poi lo bavla'i jgena cu krasi bu'u ke'a .i va'o lo nu le se ciska cu dunda le mintu valsi kei
  ##   le fancu cu kancu le jgena ne'i `inside` .i va'o lo drata le fancu cu kancu le jgena ne'i
  ##   `outside`
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
        ## drata cmene le se ciska .i `let` cu zbasu lo fukpi be le se ciska
      if not item.whole.is_read: continue
      checkpoint item.text
      for parts in [item.parts, item.live]:
        if parts != item.parts and item.text.isLiveDiffering: continue
        let merged = parts.mergeParts
        # pa tricu .i no srera
        check merged.is_merged and merged.is_whole  # lo krasi pinka pe `merge.nim`
        # lo nu jmina cu du lo nu tcidu le mulno se ciska
        if merged.is_merged: check merged.nif == item.whole.toNif  # le krasi pinka
      if item.is_corpus:
        inc count_read
        if item.parts.splitLines.len > 4: inc count_parted  # lo minde .e lo jgena .e lo kunti linji
      else:
        inc count_built
        if "(rivbi SU " in item.parts: inc count_su
    # lo bandu cu ralte lo se ciska poi se tcidu
    check count_read >= COUNT_READ_LEAST  # `Article IX.3`
    # lo bandu cu ralte lo se ciska poi vasru su'o re jgena
    check count_parted >= COUNT_PARTED_LEAST  # `Article IX.3`
    # lo bandu cu ralte lo se ciska poi se zbasu gi'e se tcidu
    check count_built >= COUNT_BUILT_READ_LEAST  # `Article IX.3`
    # lo bandu cu ralte lo se ciska poi zo su cu katna ke'a
    check count_su >= COUNT_BUILT_SU_LEAST  # `Article IX.3`


  test "Text one pass refuses merges to marked reading of one pass, or of each run around error":
    var count_marked, inside, outside = 0
    for k in 0 ..< texts.len:
      template item: untyped = texts[k]
        ## drata cmene le se ciska .i `let` cu zbasu lo fukpi be le se ciska
      if item.whole.is_read: continue
      checkpoint item.text
      for parts in [item.parts, item.live]:
        if parts != item.parts and item.text.isLiveDiffering: continue
        let merged = parts.mergeParts
        # lo srera cu stali
        check merged.is_merged and not merged.is_whole  # lo krasi pinka pe `merge.nim`
        # le krasi pinka .i lo se ciska poi vasru zo su cu zvati lo mupli po'o
        if not merged.is_merged or "(rivbi SU " in item.parts: continue
        # lo nu jmina cu ralte ro valsi
        check merged.nif.words == parts.wordsKept  # lo krasi pinka pe `merge.nim`
        let module = parts.readModule
        # ro jgena poi lo nu jmina cu bilga lo nu dunda ke'a .i le jgena cu du lo pagbu poi vasru lo
        #   srera jgena ku'o .a lo porsi
        var shape: seq[string]
        for m in 2 ..< module.len:
          if module[m].isDropped: continue
          if module[m].isHoldingError: shape.add module[m].written
          elif shape.len == 0 or shape[^1].len > 0: shape.add ""
        if shape == @[""]:
          # lo pagbu cu zvati lo stuzi pe vo'a
          check merged.nif == item.text.marked  # lo krasi pinka pe `merge.nim`
          inc count_marked
          continue
        let nodes = merged.nif.readModule
        # lo jgena pe ro porsi .e ro srera
        check nodes.len - 2 == shape.len  # lo krasi pinka pe `merge.nim`
        if nodes.len - 2 != shape.len: continue
        for m in 0 ..< shape.len:
          # lo srera cu stali
          if shape[m].len > 0: check nodes[m + 2].written == shape[m]  # le krasi pinka
          # lo porsi cu se tcidu po'o
          else: check item.text.isRunAlone(nodes, m + 2, inside, outside)  # le krasi pinka
    # lo bandu cu ralte lo se ciska poi se jmina gi'e ralte lo pagbu poi zvati lo stuzi pe vo'a
    check count_marked >= COUNT_MARKED_LEAST  # `Article IX.3`
    # lo bandu cu ralte lo porsi poi se jmina gi'e sruri lo srera jgena
    check inside >= COUNT_RUNS_LEAST  # `Article IX.3`
    # lo se kuspe be le flalu
    check float(outside) <= RUNS_OUTSIDE_MOST * float(inside + outside)  # `Article IX.3`


  test "Constructed texts merge to NIF of one pass, cut both ways":
    for text in TEXTS_MERGED:
      checkpoint text
      let whole = readText(text)
      check whole.is_read
      if not whole.is_read: continue
      for is_live in [false, true]:
        let merged = readTextParts(text, is_live).reading.toNifParts.mergeParts
        check merged.is_merged and merged.is_whole
        if merged.is_merged: check merged.nif == whole.toNif  # lo krasi pinka pe `merge.nim`


  test "Worked examples merge to tree of one pass, byte for byte, unit in place":
    for (text, nif) in EXAMPLES_MERGED:
      checkpoint text
      let merged = readTextParts(text).reading.toNifParts.mergeParts
      check merged.is_merged
      # lo nu vimcu
      if merged.is_merged: check merged.nif == HEADER & nif & "\n"  # lo krasi pinka pe `merge.nim`


  test "Worked examples keep each error, merging each run around it":
    for (text, count, held) in EXAMPLES_KEPT:
      checkpoint text
      check not readText(text).is_read
      let merged = readTextParts(text).reading.toNifParts.mergeParts
      check merged.is_merged and not merged.is_whole
      # lo srera cu zvati lo stuzi pe vo'a
      if merged.is_merged: check merged.nif.isHolding(count, held)  # le krasi pinka


  test "Live parts that differ from parts of text read whole merge to their own trees":
    for (text, is_read, count, held) in EXAMPLES_LIVE:
      checkpoint text
      let
        parts = readTextParts(text).reading.toNifParts
        live = readTextParts(text, is_live = true).reading.toNifParts
        whole = readText(text)
      check whole.is_read == is_read
      # lo jmive pagbu cu se tcidu po'o bu'u lo stuzi poi lo fanmo valsi cu se nitcu bu'u ke'a
      check live != parts  # le krasi pinka
      let merged = parts.mergeParts
      check merged.is_merged
      if not merged.is_merged: continue
      # lo nu katna
      if whole.is_read: check merged.nif == whole.toNif  # ta'i lo nu tcidu le mulno se ciska
      else: check merged.nif == text.marked
      let differing = live.mergeParts
      check differing.is_merged and not differing.is_whole and differing.nif != merged.nif
      # lo nu katna pe le jmive pagbu
      if differing.is_merged: check differing.nif.isHolding(count, held)  # le krasi pinka


  test "Tree each node of module rebuilds writes it back, byte for byte, marks among them":
    for k in 0 ..< texts.len:
      template item: untyped = texts[k]
        ## drata cmene le se ciska .i `let` cu zbasu lo fukpi be le se ciska
      checkpoint item.text
      # lo tricu poi se rapli zbasu cu rapli ciska
      check item.parts.isWrittenBack  # lo krasi pinka pe `nif.nim`
      check item.live.isWrittenBack
      if item.whole.is_read: check item.whole.toNif.isWrittenBack
    var constructed = @TEXTS_MERGED
    for (text, count, held) in EXAMPLES_KEPT: constructed.add text
    for text in constructed:
      checkpoint text
      check readTextParts(text).reading.toNifParts.isWrittenBack  # lo krasi pinka pe `nif.nim`
      let whole = readText(text)
      if whole.is_read: check whole.toNif.isWrittenBack


  test "NIF that reads not, or holds shape writer gives not, is refused":
    for (module, reason, part) in MODULES_MALFORMED:
      checkpoint module
      let merged = module.mergeParts  # renro no srera
      # lo nu rapli zbasu cu to'e curmi le tarmi
      check not merged.is_merged  # lo krasi pinka pe `merge.nim`
      if merged.is_merged: continue
      check reason in merged.reason
      # lo jgena poi se to'e curmi
      check merged.part == (if part < 0: none(int) else: some(part))  # le krasi pinka
    var terminals: seq[TerminalNif]
    # lo srera jgena poi vasru no tarmi poi le ciska cu dunda ke'a
    expect ValueError:  # lo nu rapli zbasu cu to'e curmi
      discard readModule(HEADER & "(srera 0 sumti_6)\n")[2].toTree(terminals)
