## Hold `nif.nim` to NIF data format, version 2027, as `doc/nif-spec.md` of `nim-lang/nifspec`
##   writes it at `a31513c6`: reader of suite (`reader_nif.nim`), written from grammar of spec,
##   reads each tree back from its NIF text, over corpora, as model of format gives, and rebuilds
##   tree and terminals of reading whole from it.
##   Corpora: each example of CLL 1.1, rows joined and words square brackets mark kept; each
##     sentence of sample of Tatoeba; each paragraph of articles of Wikipedia (`corpora.nim`).
##     Text refused holds no tree, so law skips it; `test_marks.nim` reads it back marked.
##   Suite of JavaScript build holds same law over every fourth sentence of sample, and same
##     worked example, with reader of this suite (`tests/test_javascript.nim`).
##   Corpora reach bytes from 128, byte of start past 1,023, and unit of several words; their
##     modules write escape in quoted text alone.
##   Corpus does not cover yet: each control byte, tab and line end inside quoted text, and `h`
##     and `'` there, which `LITERALS` constructs.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[importutils, options, sequtils, strutils, tables, unittest]

import ../../src/lojban_parser/grammar {.all.}
import ../../src/lojban_parser/nif {.all.}
import ../../src/lojban_parser/[prose, selmaho]
import ./[corpora, reader_nif]


const
  COUNT_TREES_LEAST = 1800  ## Texts of corpora that read, of 1,941; law reads tree of each.
  COUNT_CHAINS = 591  ## Pairs of rules of 21.1 that chain joins, each pair by one chain.
  CHAIN_TERMS = [
    (rule: "terms", number: 80), (rule: "terms-1", number: 81), (rule: "terms-2", number: 82),
    (rule: "term", number: 83), (rule: "sumti", number: 90), (rule: "sumti-1", number: 91),
    (rule: "sumti-2", number: 92), (rule: "sumti-3", number: 93), (rule: "sumti-4", number: 94),
    (rule: "sumti-5", number: 95), (rule: "sumti-6", number: 97),
  ]
    ## Chain from `terms` 80 to `sumti-6` 97, as rules 80 to 97 of 21.1 give it: each rule holds
    ##   next alone where text gives no part each rule may add.
  LITERALS = [
    (
      "zoi gy. a(b)c \"d\" \\e #f :g @h ~i [j] {k} .gy.",
      "\"a\\28b\\29c \\22d\\22 \\5Ce #f :g \\40h \\7Ei \\5Bj\\5D \\7Bk\\7D\"",
    ),  # 19.10, `zoi` quotes text of control bytes; constructed
    (
      "la'o gy. Größe .gy.",
      "\"laho\" 5 7 \"gy\" 9 16 \"Größe\" 18 20 \"gy\"",
    ),  # 19.10, `la'o` quotes name, whose bytes from 128 count in its span
    ("zoi gy. a\tb\nc .gy.", "\"a\\09b\\0Ac\""),  # 19.10, tab and line end inside; constructed
    ("zoi gy. h'a .gy.", "\"h\\27a\""),  # 19.10, quoted text keeps `h` and `'`; constructed
  ]
    ## Texts of quotation, each with string literals its module holds.
  MODULES_REFUSED = [
    " (.nif27)",  # Version directive, no whitespace before it
    "(.nif26)",  # Version 2027, `(.nif26)` changed to `(.nif27)`
    VERSION & "\n(sumti-6 97)",  # Identifiers, `-` takes escape
    VERSION & "\n(2a)",  # Identifiers, digit opens none
    VERSION & "\n(KOhA 0 \"ko'a\")",  # Control characters, `'` takes escape in string literal
    VERSION & "\n(a \"\\\\\")",  # Escape sequences, `\\` is no escape
    VERSION & "\n(a \"\\2d\")",  # Escape sequences, hex digits of upper case alone
    VERSION & "\n(a \"\x01\")",  # String literals, byte below 32 is no visible char
    VERSION & "\n(a \"b)",  # Control characters, `)` takes escape in string literal
    VERSION & "\n(a \"b",  # String literals, `"` closes literal
    VERSION & "\n(a \"b\"",  # Compound nodes, `)` closes node
    VERSION & "\n(KOhA@2,5 0)",  # Line information, which writer writes none of
    VERSION & "\n(a \"b\"#c#)",  # Comments, which writer writes none of
    VERSION & "\n(a b.0)",  # Symbols, which writer writes none of
    VERSION & "\n(a .)",  # Empty, which writer writes none of
    VERSION & "\n(a 'b')",  # Char literals, which writer writes none of
    VERSION & "\n(a 0x1F)",  # Numbers, writer writes decimal digits alone
  ]
    ## Modules reader refuses: what NIF refuses, and constructs writer writes none of.



#[ Names ]#

func names(): seq[string] =
  ## Give each name writer may write as tag: name of each rule of 21.1, then each class of terminal.
  privateAccess(Grammar)
  for k in 0 ..< GRAMMAR_EBNF.names.len:
    if GRAMMAR_EBNF.numbers[k].isSome: result.add GRAMMAR_EBNF.names[k]
  for selmaho in Selmaho: result.add $selmaho.toTerminal
  result.add $TERMINAL_BRIVLA
  result.add $TERMINAL_CMENE



suite "NIF data format, version 2027":
  test "Escape sequences: reader decodes hex pair of upper case, and each of five shortcuts":
    let module = (VERSION & "\n(a \"\\00\\5C\\22\\n\\t\\r\\|\\^\")\n").readModule
    check module[1].children[0].text == "\0\\\"\n\t\r\\\""  # Escape sequences, table of shortcuts


  test "Identifiers: each tag grammar writes is identifier with no escape, `_` for each `-`":
    let spelled = names()
    for name in spelled:
      checkpoint name
      check '\\' notin name.tag  # Identifiers, letters, digits and `_` need no escape
      let module = VERSION & "\n(" & name.tag & ")\n"
      check module.readModule[1].text.replace('_', '-') == name  # Identifiers, read back as name
    check spelled.len == COUNT_RULES + Selmaho.toSeq.len + 2  # 21.1, 88 rules; ch. 20, selma'o
    check spelled.deduplicate.len == spelled.len  # 21.1, ch. 20, one tag for each
    check spelled.allIt('_' notin it)  # 21.1, ch. 20, no name holds `_`, so `_` reads back as `-`


  test "String literals: word writes `h` for `'`; quoted text keeps each byte, control escaped":
    for (text, literals) in LITERALS:
      checkpoint text
      let reading = text.readText
      check reading.is_read  # 19.10, quotation reads
      check literals in reading.toNif  # String literals, Control characters
      check reading.isReadBack  # String literals, bytes read back



suite "Internal: NIF":
  test "Reader reads each tree of corpora back from its NIF text, and rebuilds it whole":
    var
      unread, escaped: seq[string]
      count = 0
    for (key, text) in textsCorpora():
      let reading = text.readText
      if not reading.is_read: continue  # refusal holds no tree
      inc count
      if not reading.isReadBack: unread.add key
      let is_quoting = reading.units.anyIt(it.terminal == Selmaho.Zoi.toTerminal)
      if '\\' in reading.toNif and not is_quoting: escaped.add key
    check unread == newSeq[string]()  # header of `nif.nim`, tree with each word in place
    check escaped == newSeq[string]()  # header of `nif.nim`, escape in quoted text alone
    check count >= COUNT_TREES_LEAST  # IX.3, guard keeps texts that read


  test "Two ends give one chain, as 21.1 gives chain from terms to sumti-6":
    check LUT_CHAIN_BY_ENDS.len == COUNT_CHAINS  # 21.1, each pair chain joins, once
    check LUT_CHAIN_BY_ENDS[(80, 97)] == @CHAIN_TERMS  # 21.1, rules 80 to 97, each holding next


  test "Name of each rule gives its number, so NIF writes no number of rule closing chain":
    check LUT_NUMBER_BY_RULE.len == COUNT_RULES  # 21.1, each rule named once, numbered once
    check LUT_NUMBER_BY_RULE["sumti-6"] == 97  # 21.1, `sumti-6<97>`
    for ends, chain in LUT_CHAIN_BY_ENDS:
      checkpoint $ends
      check LUT_NUMBER_BY_RULE[chain[^1].rule] == ends[1]  # ruling `D1 a` on #859, name of end
      check LUT_NUMBER_BY_RULE[chain[0].rule] == ends[0]


  test "Example 6.98 writes as module suites hold, byte for byte":
    let reading = EXAMPLE_NIF.text.readText
    check reading.toNif == EXAMPLE_NIF.module  # header of `nif.nim`, worked example
    check reading.isReadBack  # model of format, and tree rebuilt whole


  test "Reader refuses each construct writer writes none of, and each byte NIF asks to escape":
    for module in MODULES_REFUSED:
      checkpoint module
      expect ValueError:  # MODULES_REFUSED, section of spec beside each
        discard module.readModule
