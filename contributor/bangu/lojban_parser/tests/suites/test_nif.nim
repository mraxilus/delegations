## cipra lo du'u `nif.nim` mapti `NIF 2027` poi `doc/nif-spec.md` pe `nim-lang/nifspec` pe
##     `a31513c6` ciska ke'a
##   .i le tcidu pe le cipra to `reader_nif.nim` toi cu selci'a ja'i lo gerna pe le velski
##   .i ro tricu pe le selci'aste zo'u le tcidu cu raptcidu le tricu fi le selci'a be fi `NIF` be'o
##       pe le tricu ta'i le seldu'a be le morna be le tarmi gi'e rapyzba le multricu .e ro genvla
##       pe le se tcidu le selci'a
##   .i le selci'aste cu vasru ro mupli pe `CLL 1.1`
##   .i lo linji pe ro mupli cu seljo'e gi'e ralte lo valsi poi lo kurfa grile'u cu sinxa ke'a
##   .i le selci'aste cu vasru ji'a ro jufra pe le mupli pe `Tatoeba` .e ro ju'agri pe lo claro'a pe
##       `Wikipedia` to `corpora.nim` toi
##   .i lo selci'a poi se to'e curmi cu vasru no tricu
##   .i se ki'u bo le flalu cu cliva le selci'a
##   .i `test_marks.nim` raptcidu le selci'a ta'i lo nu sinxa ro srera
##   .i lo cipra pe lo selzba pe `JavaScript` pilno le tcidu pe le vi cipra gi'e cipra le mitfla
##       ne'i ro vomoi jufra pe le mupli pe `Tatoeba` gi'e cipra fi le mitmupli po'u `EXAMPLE_NIF`
##       to `tests/test_javascript.nim` toi
##   .i le selci'aste cu vasru lo stuzi poi na mleca li parebi .e lo krastu poi zmadu li panoreci .e
##       lo pagbu poi vasru su'o re valsi
##   .i lo selci'a be fi `NIF` be'o pe le selci'aste cu ciska lo basysni ne'i lo selci'a poi se
##       sitna po'o
##   .i ne'i lo selci'a poi se sitna ku'o le selci'aste cu ca na vasru ro midle'u .e `\t` .e lo
##       fanmo be lo linji .e `h` .e `'`
##   .i `LITERALS` finti lo selci'a poi vasru le lerfu

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
    ## lo klani be lo selci'a poi se tcidu gi'e pagbu le pasovopa selci'a pe le selci'aste
    ##   .i le flalu cu tcidu lo tricu pe ro le selci'a
  COUNT_CHAINS = 591
    ## lo klani be lo javni remei pe `CLL 21.1` zi'e poi lo porsi cu jorne ke'a
    ##   .i ro le remei cu seljo'e pa porsi
  CHAIN_TERMS = [
    (rule: "terms", number: 80), (rule: "terms-1", number: 81), (rule: "terms-2", number: 82),
    (rule: "term", number: 83), (rule: "sumti", number: 90), (rule: "sumti-1", number: 91),
    (rule: "sumti-2", number: 92), (rule: "sumti-3", number: 93), (rule: "sumti-4", number: 94),
    (rule: "sumti-5", number: 95), (rule: "sumti-6", number: 97),
  ]
    ## lo porsi poi selkra `terms<80>` gi'e selfa'o `sumti-6<97>` ja'i le javni pe li bino bi'o soze
    ##     pe `CLL 21.1`
    ##   .i ro javni cu vasru lo bavla'i javni po'o va'o lo nu le selci'a cu dunda no pagbu poi le
    ##       javni cu ka'e jmina ke'a
  LITERALS = [
    (
      "zoi gy. a(b)c \"d\" \\e #f :g @h ~i [j] {k} .gy.",
      "\"a\\28b\\29c \\22d\\22 \\5Ce #f :g \\40h \\7Ei \\5Bj\\5D \\7Bk\\7D\"",
    ),  # `CLL 19.10` to zo zoi sitna lo midle'u toi to le mupli cu selfi'i toi
    (
      "la'o gy. Größe .gy.",
      "\"laho\" 5 7 \"gy\" 9 16 \"Größe\" 18 20 \"gy\"",
    # zo la'o sitna lo cmene
    #   .i lo stuzi poi na mleca li parebi cu se kancu
    ),  # `CLL 19.10`
    # `\t` .e lo fanmo be lo linji cu zvati ne'i le se sitna
    #   .i le mupli cu selfi'i
    ("zoi gy. a\tb\nc .gy.", "\"a\\09b\\0Ac\""),  # `CLL 19.10`
    # lo se sitna cu ralte `h` .e `'`
    #   .i le mupli cu selfi'i
    ("zoi gy. h'a .gy.", "\"h\\27a\""),  # `CLL 19.10`
  ]
    ## lo selci'a poi vasru lo nu sitna
    ##   .i ro le selci'a cu kansa lo lerpoi poi lo selci'a be fi `NIF` be'o pe vo'a vasru ke'a
  MODULES_REFUSED = [
    " (.nif27)",  # `Version directive` to no kutle'u cu lidne le minde toi
    "(.nif26)",  # `NIF 2027` to `(.nif27)` basti `(.nif26)` toi
    VERSION & "\n(sumti-6 97)",  # `Identifiers` to `-` nitcu lo basysni toi
    VERSION & "\n(2a)",  # `Identifiers` to no nacle'u cu krasi lo cmene toi
    VERSION & "\n(KOhA 0 \"ko'a\")",  # `Control characters` to ne'i lo lerpoi `'` se basti toi
    VERSION & "\n(a \"\\\\\")",  # `Escape sequences` to `\\` na basysni toi
    VERSION & "\n(a \"\\2d\")",  # `Escape sequences` to lo barda lerfu po'o cu curmi toi
    # lo stuzi poi mleca li cire cu na visle'u
    VERSION & "\n(a \"\x01\")",  # `String literals`
    VERSION & "\n(a \"b)",  # `Control characters` to ne'i lo lerpoi `)` se basti toi
    VERSION & "\n(a \"b",  # `String literals` to `"` fanmo lo lerpoi toi
    VERSION & "\n(a \"b\"",  # `Compound nodes` to `)` fanmo lo jgena toi
    VERSION & "\n(KOhA@2,5 0)",  # `Line information` noi le ciska na ciska ke'a
    VERSION & "\n(a \"b\"#c#)",  # `Comments` noi le ciska na ciska ke'a
    VERSION & "\n(a b.0)",  # `Symbols` noi le ciska na ciska ke'a
    VERSION & "\n(a .)",  # `Empty` noi le ciska na ciska ke'a
    VERSION & "\n(a 'b')",  # `Char literals` noi le ciska na ciska ke'a
    VERSION & "\n(a 0x1F)",  # `Numbers` to le ciska cu ciska lo namcu poi pilno pano lerfu po'o toi
  ]
    ## lo selci'a be fi `NIF` be'o poi le tcidu cu to'e curmi ke'a
    ##   .i ro le selci'a cu se to'e curmi `NIF` gi'a vasru lo tarmi poi le ciska na ciska ke'a



#[ ni'o ni'o ni'o lo cmene ]#

func names(): seq[string] =
  ## dunda ro cmene poi le ciska cu ka'e ciska ke'a ta'i lo tcita
  ##   .i lo cmene be ro javni pe `CLL 21.1` cu lidne lo cmene be ro klesi be lo genvla
  privateAccess(Grammar)
  for k in 0 ..< GRAMMAR_EBNF.names.len:
    if GRAMMAR_EBNF.numbers[k].isSome: result.add GRAMMAR_EBNF.names[k]
  for selmaho in Selmaho: result.add $selmaho.toTerminal
  result.add $TERMINAL_BRIVLA
  result.add $TERMINAL_CMENE



suite "NIF data format, version 2027":
  test "Escape sequences: reader decodes hex pair of upper case, and each of five shortcuts":
    let module = (VERSION & "\n(a \"\\00\\5C\\22\\n\\t\\r\\|\\^\")\n").readModule
    # lo liste be lo torbasysni
    check module[1].children[0].text == "\0\\\"\n\t\r\\\""  # `Escape sequences`


  test "Identifiers: each tag grammar writes is identifier with no escape, `_` for each `-`":
    let spelled = names()
    for name in spelled:
      checkpoint name
      # lo lerfu .e lo nacle'u .e `_` nitcu no basysni
      check '\\' notin name.tag  # `Identifiers`
      let module = VERSION & "\n(" & name.tag & ")\n"
      # le tcita cu selraptcidu ta'i le cmene
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
      check reading.isReadBack  # `String literals` to lo stuzi cu selraptcidu toi



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
    # lo tricu poi ro valsi pe ke'a zvati lo stuzi pe vo'a
    check unread == newSeq[string]()  # lo krapinka pe `nif.nim`
    # lo basysni cu zvati ne'i lo se sitna po'o
    check escaped == newSeq[string]()  # lo krapinka pe `nif.nim`
    # lo bandu cu ralte lo selci'a poi se tcidu
    check count >= COUNT_TREES_LEAST  # `Article IX.3`


  test "Two ends give one chain, as 21.1 gives chain from terms to sumti-6":
    # ro remei poi lo porsi cu jorne ke'a se kancu pa roi
    check LUT_CHAIN_BY_ENDS.len == COUNT_CHAINS  # `CLL 21.1`
    # le javni pe li bino bi'o soze
    #   .i ro le javni cu vasru lo bavla'i javni
    check LUT_CHAIN_BY_ENDS[(80, 97)] == @CHAIN_TERMS  # `CLL 21.1`


  test "Name of each rule gives its number, so NIF writes no number of rule closing chain":
    check LUT_NUMBER_BY_RULE.len == COUNT_RULES  # `CLL 21.1` to ro javni cu selcme pa roi toi
    # ro namcu cu ckini pa javni po'o
    check toSeq(LUT_NUMBER_BY_RULE.values).deduplicate.len == COUNT_RULES  # `CLL 21.1`
    check LUT_NUMBER_BY_RULE["sumti-6"] == 97  # `sumti-6<97>` pe `CLL 21.1`
    for ends, chain in LUT_CHAIN_BY_ENDS:
      checkpoint $ends
      # lo cmene be lo fanmo be lo porsi
      check LUT_NUMBER_BY_RULE[chain[^1].rule] == ends[1]  # lo krapinka pe `nif.nim`
      check LUT_NUMBER_BY_RULE[chain[0].rule] == ends[0]


  test "Example 6.98 writes as module suites hold, byte for byte":
    let reading = EXAMPLE_NIF.text.readText
    check reading.toNif == EXAMPLE_NIF.module  # lo krapinka pe `nif.nim` to le mupli toi
    check reading.isReadBack  # le morna be le tarmi to le multricu cu selrapyzba toi


  test "Reader refuses each construct writer writes none of, and each byte NIF asks to escape":
    for module in MODULES_REFUSED:
      checkpoint module
      expect ValueError:  # `MODULES_REFUSED` to lo pagbu be le velski cu lamji ro le selci'a toi
        discard module.readModule
