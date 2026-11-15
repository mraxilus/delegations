## cipra lo du'u `nif.nim` cu mapti la'o gy. NIF 2027 .gy. poi `doc/nif-spec.md` pe
##   `nim-lang/nifspec` pe `a31513c6` cu ciska ke'a
##   .i le tcidu pe le cipra to `reader_nif.nim` toi cu se ciska ja'i lo gerna pe le ve skicu
##   .i ro tricu pe le se ciska liste zo'u le tcidu cu rapli tcidu le tricu fi le se ciska be fi
##     la'o gy. NIF .gy. be'o pe le tricu ta'i le se dunda be le morna be le tarmi gi'e rapli zbasu
##     le mulno tricu .e ro gerna valsi pe le se tcidu le se ciska
##   .i le se ciska liste cu vasru ro mupli pe la'o gy. CLL 1.1 .gy.
##   .i lo linji pe ro mupli cu se jorne gi'e ralte lo valsi poi lo kurfa grile'u cu sinxa ke'a
##   .i le se ciska liste cu vasru ji'a ro jufra pe le mupli pe la'o gy. Tatoeba .gy. .e ro jufra
##     girzu pe lo clani prosa pe la'o gy. Wikipedia .gy. to `corpora.nim` toi
##   .i lo se ciska poi se to'e curmi cu vasru no tricu
##   .i se ki'u bo le flalu cu cliva le se ciska
##   .i `test_marks.nim` cu rapli tcidu le se ciska ta'i lo nu sinxa ro srera
##   .i lo cipra pe lo se zbasu pe la'o gy. JavaScript .gy. cu pilno le tcidu pe le vi cipra gi'e
##     cipra le mintu flalu ne'i ro vomoi jufra pe le mupli pe la'o gy. Tatoeba .gy. gi'e cipra fi
##     le mintu mupli po'u `EXAMPLE_NIF` to `tests/test_javascript.nim` toi
##   .i le se ciska liste cu vasru lo stuzi poi na mleca li parebi .e lo krasi stuzi poi zmadu li
##     panoreci .e lo pagbu poi vasru su'o re valsi
##   .i lo se ciska be fi la'o gy. NIF .gy. be'o pe le se ciska liste cu ciska lo basti sinxa ne'i
##     lo se ciska poi se sitna po'o
##   .i ne'i lo se ciska poi se sitna ku'o le se ciska liste cu ca na vasru ro minde lerfu .e `\t`
##     .e lo fanmo be lo linji .e `h` .e `'`
##   .i `LITERALS` cu finti lo se ciska poi vasru le lerfu

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[importutils, options, sequtils, strutils, tables, unittest]

import ../../src/lojban_parser/grammar {.all.}
import ../../src/lojban_parser/nif {.all.}
import ../../src/lojban_parser/[prose, selmaho]
import ./[corpora, reader_nif]


const
  COUNT_TREES_LEAST = 1800
    ## lo klani be lo se ciska poi se tcidu gi'e pagbu le pasovopa se ciska pe le se ciska liste
    ##   .i le flalu cu tcidu lo tricu pe ro le se ciska
  COUNT_CHAINS = 591
    ## lo klani be lo javni remei pe `CLL 21.1` zi'e poi lo porsi cu jorne ke'a
    ##   .i ro le remei cu se jorne pa porsi
  CHAIN_TERMS = [
    (rule: "terms", number: 80), (rule: "terms-1", number: 81), (rule: "terms-2", number: 82),
    (rule: "term", number: 83), (rule: "sumti", number: 90), (rule: "sumti-1", number: 91),
    (rule: "sumti-2", number: 92), (rule: "sumti-3", number: 93), (rule: "sumti-4", number: 94),
    (rule: "sumti-5", number: 95), (rule: "sumti-6", number: 97),
  ]
    ## lo porsi poi se krasi `terms<80>` gi'e se fanmo `sumti-6<97>` ja'i le javni pe li bino bi'o
    ##   soze pe `CLL 21.1`
    ##   .i ro javni cu vasru lo bavla'i javni po'o va'o lo nu le se ciska cu dunda no pagbu poi le
    ##     javni cu ka'e jmina ke'a
  LITERALS = [
    (
      "zoi gy. a(b)c \"d\" \\e #f :g @h ~i [j] {k} .gy.",
      "\"a\\28b\\29c \\22d\\22 \\5Ce #f :g \\40h \\7Ei \\5Bj\\5D \\7Bk\\7D\"",
    ),  # `CLL 19.10` to zo zoi cu sitna lo minde lerfu toi to le mupli cu se finti toi
    (
      "la'o gy. Größe .gy.",
      "\"laho\" 5 7 \"gy\" 9 16 \"Größe\" 18 20 \"gy\"",
    # zo la'o cu sitna lo cmene
    #   .i lo stuzi poi na mleca li parebi cu se kancu
    ),  # `CLL 19.10`
    # `\t` .e lo fanmo be lo linji cu zvati ne'i le se sitna
    #   .i le mupli cu se finti
    ("zoi gy. a\tb\nc .gy.", "\"a\\09b\\0Ac\""),  # `CLL 19.10`
    # lo se sitna cu ralte `h` .e `'`
    #   .i le mupli cu se finti
    ("zoi gy. h'a .gy.", "\"h\\27a\""),  # `CLL 19.10`
  ]
    ## lo se ciska poi vasru lo nu sitna
    ##   .i ro le se ciska cu kansa lo lerpoi poi lo se ciska be fi la'o gy. NIF .gy. be'o pe vo'a
    ##     cu vasru ke'a
  MODULES_REFUSED = [
    " (.nif27)",  # `Version directive` to no kunti lerfu cu lidne le minde toi
    "(.nif26)",  # la'o gy. NIF 2027 .gy. to `(.nif27)` cu basti `(.nif26)` toi
    VERSION & "\n(sumti-6 97)",  # `Identifiers` to `-` cu nitcu lo basti sinxa toi
    VERSION & "\n(2a)",  # `Identifiers` to no namcu lerfu cu krasi lo cmene toi
    VERSION & "\n(KOhA 0 \"ko'a\")",  # `Control characters` to ne'i lo lerpoi `'` cu se basti toi
    VERSION & "\n(a \"\\\\\")",  # `Escape sequences` to `\\` na basti sinxa toi
    VERSION & "\n(a \"\\2d\")",  # `Escape sequences` to lo barda lerfu po'o cu curmi toi
    # lo stuzi poi mleca li cire cu na viska lerfu
    VERSION & "\n(a \"\x01\")",  # `String literals`
    VERSION & "\n(a \"b)",  # `Control characters` to ne'i lo lerpoi `)` cu se basti toi
    VERSION & "\n(a \"b",  # `String literals` to `"` cu fanmo lo lerpoi toi
    VERSION & "\n(a \"b\"",  # `Compound nodes` to `)` cu fanmo lo jgena toi
    VERSION & "\n(KOhA@2,5 0)",  # `Line information` noi le ciska na ciska ke'a
    VERSION & "\n(a \"b\"#c#)",  # `Comments` noi le ciska na ciska ke'a
    VERSION & "\n(a b.0)",  # `Symbols` noi le ciska na ciska ke'a
    VERSION & "\n(a .)",  # `Empty` noi le ciska na ciska ke'a
    VERSION & "\n(a 'b')",  # `Char literals` noi le ciska na ciska ke'a
    VERSION & "\n(a 0x1F)",  # `Numbers` to le ciska cu ciska lo namcu poi pilno pano lerfu po'o toi
  ]
    ## lo se ciska be fi la'o gy. NIF .gy. be'o poi le tcidu cu to'e curmi ke'a
    ##   .i ro le se ciska cu se to'e curmi la'o gy. NIF .gy. gi'a vasru lo tarmi poi le ciska na
    ##     ciska ke'a



#[ ni'o ni'o ni'o lo cmene ]#

func names(): seq[string] =
  ## dunda ro cmene poi le ciska cu ka'e ciska ke'a ta'i lo tcita
  ##   .i lo cmene be ro javni pe `CLL 21.1` cu lidne lo cmene be ro klesi be lo gerna valsi
  privateAccess(Grammar)
  for k in 0 ..< GRAMMAR_EBNF.names.len:
    if GRAMMAR_EBNF.numbers[k].isSome: result.add GRAMMAR_EBNF.names[k]
  for selmaho in Selmaho: result.add $selmaho.toTerminal
  result.add $TERMINAL_BRIVLA
  result.add $TERMINAL_CMENE



suite "NIF data format, version 2027":
  test "Escape sequences: reader decodes hex pair of upper case, and each of five shortcuts":
    let module = (VERSION & "\n(a \"\\00\\5C\\22\\n\\t\\r\\|\\^\")\n").readModule
    # lo liste be lo tordu basti sinxa
    check module[1].children[0].text == "\0\\\"\n\t\r\\\""  # `Escape sequences`


  test "Identifiers: each tag grammar writes is identifier with no escape, `_` for each `-`":
    let spelled = names()
    for name in spelled:
      checkpoint name
      # lo lerfu .e lo namcu lerfu .e `_` cu nitcu no basti sinxa
      check '\\' notin name.tag  # `Identifiers`
      let module = VERSION & "\n(" & name.tag & ")\n"
      # le tcita cu se rapli tcidu ta'i le cmene
      check module.readModule[1].text.replace('_', '-') == name  # `Identifiers`
    # lo bibi javni .e lo selma'o
    check spelled.len == COUNT_RULES + Selmaho.toSeq.len + 2  # `CLL 21.1` .e `CLL 20`
    # ro javni .e ro klesi cu se tcita pa tcita
    check spelled.deduplicate.len == spelled.len  # `CLL 21.1` .e `CLL 20`
    # no cmene cu vasru `_`
    #   .i se ki'u bo le tcidu cu tcidu `-` fi `_`
    check spelled.allIt('_' notin it)  # `CLL 21.1` .e `CLL 20`


  test "String literals: word writes `h` for `'`; quoted text keeps each byte, control escaped":
    for (text, literals) in LITERALS:
      checkpoint text
      let reading = text.readText
      check reading.is_read  # `CLL 19.10` to lo nu sitna cu se tcidu toi
      check literals in reading.toNif  # `String literals` .e `Control characters`
      check reading.isReadBack  # `String literals` to lo stuzi cu se rapli tcidu toi



suite "Internal: NIF":
  test "Reader reads each tree of corpora back from its NIF text, and rebuilds it whole":
    var
      unread, escaped: seq[string]
      count = 0
    for (key, text) in textsCorpora():
      let reading = text.readText
      if not reading.is_read: continue  # lo nu to'e curmi cu vasru no tricu
      inc count
      if not reading.isReadBack: unread.add key
      let is_quoting = reading.units.anyIt(it.terminal == Selmaho.Zoi.toTerminal)
      if '\\' in reading.toNif and not is_quoting: escaped.add key
    # lo tricu poi ro valsi pe ke'a cu zvati lo stuzi pe vo'a
    check unread == newSeq[string]()  # lo krasi pinka pe `nif.nim`
    # lo basti sinxa cu zvati ne'i lo se sitna po'o
    check escaped == newSeq[string]()  # lo krasi pinka pe `nif.nim`
    # lo bandu cu ralte lo se ciska poi se tcidu
    check count >= COUNT_TREES_LEAST  # `Article IX.3`


  test "Two ends give one chain, as 21.1 gives chain from terms to sumti-6":
    # ro remei poi lo porsi cu jorne ke'a cu se kancu pa roi
    check LUT_CHAIN_BY_ENDS.len == COUNT_CHAINS  # `CLL 21.1`
    # le javni pe li bino bi'o soze
    #   .i ro le javni cu vasru lo bavla'i javni
    check LUT_CHAIN_BY_ENDS[(80, 97)] == @CHAIN_TERMS  # `CLL 21.1`


  test "Name of each rule gives its number, so NIF writes no number of rule closing chain":
    check LUT_NUMBER_BY_RULE.len == COUNT_RULES  # `CLL 21.1` to ro javni cu se cmene pa roi toi
    # ro namcu cu ckini pa javni po'o
    check toSeq(LUT_NUMBER_BY_RULE.values).deduplicate.len == COUNT_RULES  # `CLL 21.1`
    check LUT_NUMBER_BY_RULE["sumti-6"] == 97  # `sumti-6<97>` pe `CLL 21.1`
    for ends, chain in LUT_CHAIN_BY_ENDS:
      checkpoint $ends
      # lo cmene be lo fanmo be lo porsi
      check LUT_NUMBER_BY_RULE[chain[^1].rule] == ends[1]  # lo krasi pinka pe `nif.nim`
      check LUT_NUMBER_BY_RULE[chain[0].rule] == ends[0]


  test "Example 6.98 writes as module suites hold, byte for byte":
    let reading = EXAMPLE_NIF.text.readText
    check reading.toNif == EXAMPLE_NIF.module  # lo krasi pinka pe `nif.nim` to le mupli toi
    check reading.isReadBack  # le morna be le tarmi to le mulno tricu cu se rapli zbasu toi


  test "Reader refuses each construct writer writes none of, and each byte NIF asks to escape":
    for module in MODULES_REFUSED:
      checkpoint module
      expect ValueError:  # `MODULES_REFUSED` to lo pagbu be le ve skicu cu lamji ro le se ciska toi
        discard module.readModule
