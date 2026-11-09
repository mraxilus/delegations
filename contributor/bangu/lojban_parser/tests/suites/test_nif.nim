## Hold `nif.nim` to NIF data format, version 2027, as `doc/nif-spec.md` of `nim-lang/nifspec`
##   writes it at `a31513c6`: reader of suite (`reader_nif.nim`), written from grammar of spec,
##   reads each tree back from its NIF text, over corpora, as model of format gives.
##   Corpora: each example of CLL 1.1, rows joined and words square brackets mark kept; each
##     sentence of sample of Tatoeba; each paragraph of articles of Wikipedia. Text refused
##     holds no tree, so law skips it.
##   Suite of JavaScript build holds same law over every fourth sentence of sample, and same
##     worked example, with reader of this suite (`tests/test_javascript.nim`).
##   Corpora reach bytes from 128, byte of start past 1,023, and unit of several words; they write
##     no escape save of `-`, `'`, parenthesis and square bracket.
##   Corpus does not cover yet: each other control byte, tab and line end inside quoted text,
##     which `LITERALS` constructs.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[importutils, options, sequtils, strutils, unittest]

import ../../src/lojban_parser/grammar {.all.}
import ../../src/lojban_parser/nif {.all.}
import ../../src/lojban_parser/[prose, selmaho]
import ../articles_wikipedia/articles
import ../cll/examples
import ../sample_tatoeba/sentences
import ./reader_nif


const
  COUNT_TREES_LEAST = 1800  ## Texts of corpora that read, of 1,941; law reads tree of each.
  LITERALS = [
    (
      "zoi gy. a(b)c \"d\" \\e #f :g @h ~i [j] {k} .gy.",
      "\"a\\28b\\29c \\22d\\22 \\5Ce #f :g \\40h \\7Ei \\5Bj\\5D \\7Bk\\7D\"",
    ),  # 19.10, `zoi` quotes text of control bytes; constructed
    ("la'o gy. Größe .gy.", "\"la\\27o\" \"gy\" \"Größe\" \"gy\""),  # 19.10, `la'o` quotes name
    ("zoi gy. a\tb\nc .gy.", "\"a\\09b\\0Ac\""),  # 19.10, tab and line end inside; constructed
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
    VERSION & "\n(a \"b)",  # String literals, `"` closes literal
    VERSION & "\n(a \"b\"",  # Compound nodes, `)` closes node
    VERSION & "\n(KOhA@2,5 0)",  # Line information, which writer writes none of
    VERSION & "\n(a \"b\"#c#)",  # Comments, which writer writes none of
    VERSION & "\n(a b.0)",  # Symbols, which writer writes none of
    VERSION & "\n(a .)",  # Empty, which writer writes none of
    VERSION & "\n(a 'b')",  # Char literals, which writer writes none of
    VERSION & "\n(a 0x1F)",  # Numbers, writer writes decimal digits alone
  ]
    ## Modules reader refuses: what NIF refuses, and constructs writer writes none of.



#[ Corpora ]#

func textsCorpora(): seq[(string, string)] =
  ## Give key and text of each text of corpora: rows of each example of CLL joined, words square
  ##   brackets mark kept; each sentence of sample of Tatoeba; each paragraph of Wikipedia.
  for example in EXAMPLES_CLL:
    let text = example.rows.join(" ").multiReplace(("[", ""), ("]", ""))
    result.add ("CLL " & example.number, text)
  for sentence in SENTENCES_TATOEBA: result.add ("Tatoeba " & $sentence.id, sentence.text)
  for paragraph in PARAGRAPHS_WIKIPEDIA:
    result.add ("Wikipedia " & paragraph.article & " " & $paragraph.index, paragraph.text)


func leaves(node: Node): seq[int] =
  ## Give index of each terminal of tree, in order.
  if node.is_terminal: return @[node.at]
  for child in node.children: result.add child.leaves


func tags(): seq[string] =
  ## Give each tag writer may write: name of each rule of 21.1, then each class of terminal.
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


  test "Identifiers: each tag grammar writes is identifier, read back as name it escapes":
    let names = tags()
    for tag in names:
      checkpoint tag
      let module = VERSION & "\n(" & tag.escaped(is_identifier = true) & ")\n"
      check module.readModule[1].text == tag  # Identifiers, escape `\xx` of each other byte
    check names.len == COUNT_RULES + Selmaho.toSeq.len + 2  # 21.1, 88 rules; ch. 20, selma'o
    check names.deduplicate.len == names.len  # 21.1, ch. 20, one tag for each


  test "String literals: control bytes take escape; #, :, space and bytes from 128 stay":
    for (text, literals) in LITERALS:
      checkpoint text
      let reading = text.readText
      check reading.is_read  # 19.10, quotation reads
      check literals in reading.toNif  # String literals, Control characters
      check reading.toNif.readModule == reading.toModule  # String literals, bytes read back



suite "Internal: NIF":
  test "Reader reads each tree of corpora back from its NIF text, as model of format gives":
    var
      unread: seq[string]
      count = 0
    for (key, text) in textsCorpora():
      let reading = text.readText
      if not reading.is_read: continue  # refusal holds no tree
      inc count
      let module =
        try: reading.toNif.readModule
        except ValueError: @[]
      if module != reading.toModule or reading.tree.leaves != toSeq(0 ..< reading.units.len):
        unread.add key
    check unread == newSeq[string]()  # header of `nif.nim`, tree with each word in place
    check count >= COUNT_TREES_LEAST  # IX.3, guard keeps texts that read


  test "Example 2.57 writes as module suites hold, byte for byte":
    let reading = EXAMPLE_NIF.text.readText
    check reading.toNif == EXAMPLE_NIF.module  # header of `nif.nim`, worked example
    check reading.toNif.readModule == reading.toModule  # model of format, same module


  test "Reader refuses each construct writer writes none of, and each byte NIF asks to escape":
    for module in MODULES_REFUSED:
      checkpoint module
      expect ValueError:  # MODULES_REFUSED, section of spec beside each
        discard module.readModule
