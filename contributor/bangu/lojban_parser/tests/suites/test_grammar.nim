## Replicate reading of CLL chapter 5 by formal grammar of 21.1 against `grammar.nim`; hold laws
##   each tree keeps.
##   Examples are copied from CLL text, never from library output; rows of one sentence are
##     joined, and text no source holds is marked constructed. Square bracket of CLL marks word
##     text may leave out (5.5), so each example reads with that word and without it.
##   References: words CLL groups in prose and gloss, as spans of rule, and terminators 21.1
##     writes between slashes, listed here apart from grammar.
##   Corpus does not cover yet: every example of CLL, whose text its permission notice binds, so
##     suite quotes examples it cites alone (#815); and quotation, erasure, `zei` and `bu`, gap
##     of #814.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[options, sequtils, strutils, unittest]

import ../../src/lojban_parser/[grammar, selmaho, stream]


type
  Example = object  ## Define example of CLL: section holding it, number, and lojban it writes.
    section: string
    number: string
    text: string  ## Lojban of example; square brackets mark word text may leave out.


const
  TERMINATORS_ELIDABLE = {
    Selmaho.Beho, Selmaho.Boi, Selmaho.Dohu, Selmaho.Fehu, Selmaho.Gehu, Selmaho.Kehe,
    Selmaho.Kei, Selmaho.Ku, Selmaho.Kuhe, Selmaho.Kuho, Selmaho.Lihu, Selmaho.Loho,
    Selmaho.Luhu, Selmaho.Mehu, Selmaho.Nuhu, Selmaho.Sehu, Selmaho.Tehu, Selmaho.Toi,
    Selmaho.Tuhu, Selmaho.Vau, Selmaho.Veho,
  }
    ## Selma'o 21.1 writes between slashes, as terminator text may elide.
  COUNT_ELIDED = 12  ## Examples here writing terminators alone in square brackets.
  EXAMPLES = [
    Example(section: "5.1", number: "5.1", text: "do mamta mi"),
    Example(section: "5.1", number: "5.5", text: "ta blotrskunri"),
    Example(section: "5.2", number: "5.6", text: "tu pelnimre tricu"),
    Example(section: "5.2", number: "5.7", text: "la djan. barda nanla"),
    Example(section: "5.3", number: "5.19", text: "ta cmalu nixli bo ckule"),
    Example(section: "5.3", number: "5.20", text: "ta cmalu bo nixli ckule"),
    Example(section: "5.3", number: "5.21", text: "ta cmalu nixli ckule"),
    Example(section: "5.4", number: "5.25", text: "do mutce bo barda gerku bo kavbu"),
    Example(section: "5.4", number: "5.29", text: "ta melbi cmalu bo nixli bo ckule"),
    Example(section: "5.4", number: "5.30", text: "ta cmalu bo nixli bo ckule"),
    Example(section: "5.5", number: "5.32", text: "ta ke ke melbi cmalu ke'e nixli ke'e ckule"),
    Example(section: "5.5", number: "5.33", text:
      "ta ke ke ke melbi cmalu ke'e nixli ke'e ckule ke'e"
    ),
    Example(section: "5.5", number: "5.35", text: "ta melbi cmalu ke nixli ckule [ke'e]"),
    Example(section: "5.5", number: "5.36", text: "ta melbi ke cmalu nixli ckule [ke'e]"),
    Example(section: "5.5", number: "5.37", text: "ta melbi ke cmalu ke nixli ckule [ke'e] [ke'e]"),
    Example(section: "5.6", number: "5.41", text: "barda je xunre gerku"),
    Example(section: "5.6", number: "5.43", text: "barda je pelxu bo xunre gerku"),
    Example(section: "5.6", number: "5.43", text: "barda je ke pelxu xunre ke'e gerku"),
    Example(section: "5.6", number: "5.61", text: "gu'e barda gi xunre gerku"),
    Example(section: "5.6", number: "5.62", text: "gu'e barda je xunre gi gerku ja mlatu"),
    Example(section: "5.7", number: "5.64", text: "ti xamgu be do bei mi [be'o] zdani"),
    Example(section: "5.7", number: "5.65", text:
      "ti cmalu be le ka canlu bei lo'e ckule be'o nixli be li mu bei lo merko be'o bo ckule la " &
      "bryklyn. loi pemci le mela nu,IORK. prenu le jecta"
    ),
    Example(section: "5.7", number: "5.73", text: "le xamgu be do noi barda cu zdani"),
    Example(section: "5.7", number: "5.74", text: "le xamgu be do be'o noi barda cu zdani"),
    Example(section: "5.7", number: "5.75", text: "le xamgu be le ctuca [ku] be'o zdani"),
    Example(section: "5.8", number: "5.77", text: "ta zdani co blanu"),
    Example(section: "5.8", number: "5.80", text: "ta nixli [bo] ckule co cmalu"),
    Example(section: "5.8", number: "5.81", text: "ta cmalu ke nixli ckule [ke'e] co melbi"),
    Example(section: "5.9", number: "5.90", text: "la djan. go'i troci"),
    Example(section: "5.9", number: "5.92", text: "li vo nu'a su'i li re li re"),
    Example(section: "5.9", number: "5.94", text: "la prim. palvr. pamoi cusku"),
    Example(section: "5.9", number: "5.96", text: "ti nu zdile kei kumfa"),
    Example(section: "5.10", number: "5.99", text: "la BALtazar. cu me le ci nolraitru"),
    Example(section: "5.10", number: "5.104", text: "ta me lai kraislr. [me'u] karce"),
    Example(section: "5.10", number: "5.106", text:
      "re me le ci nolraitru me'u .e la djan. cu blabi"
    ),
    Example(section: "5.11", number: "5.110", text: "do se prami mi"),
    Example(section: "5.11", number: "5.112", text:
      "le zarci cu se ke cadzu klama [ke'e] la .alis."
    ),
    Example(section: "5.12", number: "5.116", text:
      "la .alis. cu na'e ke cadzu klama [ke'e] le zarci"
    ),
    Example(section: "5.12", number: "5.120", text:
      "mi na'e ke sutra cadzu be fi le birka [be'o] ke'e klama le zarci"
    ),
    Example(section: "5.12", number: "5.126", text:
      "mi na'e ke sutra cadzu be fi le birka je masno klama [be'o] [ke'e] le zarci"
    ),
    Example(section: "5.13", number: "5.127", text: "mi pu klama le zarci"),
    Example(section: "5.13", number: "5.131", text: "mi na pu na ca klama le zarci"),
    Example(section: "5.16", number: "5.151", text: "ke melbi cmalu bo nixli ke'e je ckule"),
    Example(section: "5.16", number: "5.151", text: "melbi bo cmalu bo nixli je ckule"),
    Example(section: "5.16", number: "5.163", text: "melbi jebo cmalu jebo nixli jebo ckule"),
    Example(section: "5.16", number: "5.171", text: "melbi je ke cmalu je nixli je ckule [ke'e]"),
  ]
    ## Examples of each section of CLL chapter 5, version 1.1, rows of one sentence joined.



#[ Readers ]#

func occurrencesRead(text: string): seq[Occurrence] =
  ## Read stream, and list its words; stream of CLL example always reads.
  let reading = text.readStream
  doAssert reading.is_read, "Stream of example should read; got `" & text & "`."
  reading.occurrences


func readingRead(text: string): ReadingGrammar =
  ## Read words of stream as terminals, and terminals by grammar of 21.1.
  var terminals: seq[Terminal]
  for occurrence in text.occurrencesRead:
    let terminal = occurrence.reading.toTerminal
    doAssert terminal.isSome, "Word of example should be terminal; got `" & occurrence.text & "`."
    terminals.add terminal.get
  terminals.readGrammar


func treeRead(text: string): Option[Node] =
  ## Read text by grammar, and give its tree; none where grammar refuses it.
  let reading = text.readingRead
  if reading.is_read: some(reading.tree) else: none(Node)


func refusalRead(text: string): Option[(int, string)] =
  ## Read text by grammar, and give place and rule refusing it; none where grammar reads it.
  let reading = text.readingRead
  if reading.is_read: none((int, string)) else: some((reading.at, reading.rule))


func leaves(node: Node): seq[int] =
  ## List index of each terminal under node, in order of tree.
  if node.is_terminal: return @[node.at]
  for child in node.children: result.add child.leaves


func spans(node: Node, rule: string): seq[Slice[int]] =
  ## List words each node of `rule` holds, where they are two or more, in order nodes open.
  if node.is_terminal: return
  let leaves = node.leaves
  if node.rule == rule and leaves.len >= 2: result.add leaves[0] .. leaves[^1]
  for child in node.children: result.add child.spans(rule)


func spansRead(text, rule: string): seq[Slice[int]] =
  ## Read text by grammar, and list words each node of `rule` holds, two or more.
  let tree = text.treeRead
  doAssert tree.isSome, "Grammar should read example; got `" & text & "`."
  tree.get.spans(rule)


func shape(node: Node, words: openArray[string], dropped: openArray[int]): string =
  ## Write tree as rules nesting words, words at `dropped` left out.
  if node.is_terminal: return (if node.at in dropped: "" else: words[node.at])
  let parts = node.children.mapIt(it.shape(words, dropped)).filterIt(it.len > 0)
  node.rule & "(" & parts.join(" ") & ")"



#[ References ]#

func withBracketed(text: string): string =
  ## Write example with each word square brackets mark.
  text.multiReplace(("[", ""), ("]", ""))


func withoutBracketed(text: string): string =
  ## Write example without words square brackets mark.
  text.splitWhitespace.filterIt(not it.startsWith("[")).join(" ")


func bracketedAt(text: string): seq[int] =
  ## List index of each word square brackets mark, among words of example written with them;
  ##   each written word of chapter 5 is one word of stream.
  let tokens = text.splitWhitespace
  for i, token in tokens:
    if token.startsWith("["): result.add i



suite "Chapter 5":
  test "Each example of each section reads, with words square brackets mark and without":
    var count = 0
    for example in EXAMPLES:
      check example.text.withBracketed.treeRead.isSome  # example, as CLL writes it
      check example.text.withoutBracketed.treeRead.isSome  # 5.5, bracketed word may be left out
      inc count
    check count == EXAMPLES.len


  test "Section 5.3":
    check "ta cmalu nixli bo ckule".spansRead("selbri-6") == @[2 .. 4]  # Example 5.19, tertau
    check "ta cmalu bo nixli ckule".spansRead("selbri-6") == @[1 .. 3]  # Example 5.20, seltau
    check "ta cmalu nixli ckule".spansRead("selbri-6").len == 0  # Example 5.21, no bo


  test "Section 5.4":
    check "do mutce bo barda gerku bo kavbu".spansRead("selbri-6") ==
        @[1 .. 3, 4 .. 6]  # Example 5.25, seltau and tertau
    check "ta melbi cmalu bo nixli bo ckule".spansRead("selbri-6") ==
        @[2 .. 6, 4 .. 6]  # Example 5.29, right-grouping
    check "ta cmalu bo nixli bo ckule".spansRead("selbri-6") ==
        @[1 .. 5, 3 .. 5]  # Example 5.30, same as Example 5.19


  test "Section 5.5":
    check "ta ke ke melbi cmalu ke'e nixli ke'e ckule".spansRead("tanru-unit-2") ==
        @[1 .. 7, 2 .. 5]  # Example 5.32
    check "ta ke ke ke melbi cmalu ke'e nixli ke'e ckule ke'e".spansRead("tanru-unit-2") ==
        @[1 .. 10, 2 .. 8, 3 .. 6]  # Example 5.33
    check "ta melbi ke cmalu nixli ckule".spansRead("tanru-unit-2") ==
        @[2 .. 5]  # Example 5.36, ke'e elided at end of selbri
    check "ta melbi ke cmalu ke nixli ckule".spansRead("tanru-unit-2") ==
        @[2 .. 6, 4 .. 6]  # Example 5.37, both ke'e elided


  test "Section 5.7":
    check "le xamgu be do noi barda cu zdani".spansRead("linkargs") ==
        @[2 .. 5]  # Example 5.73, clause attaches to last linked sumti
    check "le xamgu be do be'o noi barda cu zdani".spansRead("linkargs") ==
        @[2 .. 4]  # Example 5.74, be'o closes linked sumti
    check "le xamgu be do be'o noi barda cu zdani".spansRead("relative-clause") ==
        @[5 .. 6]  # Example 5.74, clause attaches to outer description
    check "le xamgu be le ctuca be'o zdani".spansRead("sumti-6") ==
        @[0 .. 6, 3 .. 4]  # Example 5.75, be'o closes linked sumti
    check "le xamgu be le ctuca zdani".spansRead("sumti-6") ==
        @[0 .. 5, 3 .. 5]  # 5.7, without ku or be'o, zdani joins linked sumti; constructed



suite "Internal: Grammar":
  test "Words of each tree, in order, are words of text, under rule text":
    var count = 0
    for example in EXAMPLES:
      for text in [example.text.withBracketed, example.text.withoutBracketed]:
        let tree = text.treeRead
        check tree.isSome
        if tree.isNone: continue
        check tree.get.rule == "text" and tree.get.number == 0  # 21.1, rule 0
        check tree.get.leaves == toSeq(0 ..< text.occurrencesRead.len)  # #815
        inc count
    check count == 2 * EXAMPLES.len


  test "Terminator text leaves out changes no tree, as square brackets of CLL mark":
    var count = 0
    for example in EXAMPLES:
      if '[' notin example.text: continue
      let
        text = example.text.withBracketed
        words = text.occurrencesRead
        dropped = example.text.bracketedAt
      if dropped.anyIt(words[it].reading.selmaho.get notin TERMINATORS_ELIDABLE): continue
      let (with_all, without) = (text.treeRead, example.text.withoutBracketed.treeRead)
      check with_all.isSome and without.isSome
      if with_all.isNone or without.isNone: continue
      let words_without = example.text.withoutBracketed.occurrencesRead.mapIt(it.text)
      check with_all.get.shape(words.mapIt(it.text), dropped) ==
          without.get.shape(words_without, [])  # 21.1, elided "without change of meaning"
      inc count
    check count == COUNT_ELIDED


  test "Refusal names place where every derivation stops, and rule stopping there":
    check "mi klama le".refusalRead == some((3, "sumti-6 97"))  # text ends in sumti; constructed
    check "le".refusalRead == some((1, "sumti-6 97"))  # constructed
    check "cu".refusalRead == some((0, "text 0"))  # cu opens no text; constructed
    check "mi cu cu klama".refusalRead == some((2, "sentence 40"))  # second cu; constructed
    check "mi poi".refusalRead == some((2, "relative-clause 122"))  # constructed
    check "lo nu".refusalRead == some((2, "tanru-unit-2 152"))  # nu waits for bridi; constructed
    check "mi klama ku".refusalRead == some((2, "bridi-tail 50"))  # ku closes no sumti; constructed
