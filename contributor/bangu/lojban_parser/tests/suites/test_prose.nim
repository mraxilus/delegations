## Replicate reading of prose against `prose.nim`: quotation, erasure, `zei`, BAhE, `bu` and
##   indicators, as CLL chapters 4, 6, 13, 17 and 19 give them, then grammar of 21.1.
##   Examples are copied from CLL text, never from library output; rows of one sentence are
##     joined, and text no source holds is marked constructed.
##   Laws run over cited examples, at each place between their words, and over each cmavo of
##     cmavo list (Article IX.3).
##   `test_corpus.nim` reads every example of CLL 1.1 from extract under notice of CLL; suite
##     here holds units and constructs rules of 19.16 give examples it quotes.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[algorithm, options, sequtils, strutils, unittest]

import ../../src/lojban_parser/[grammar, prose, selmaho, stream]
import ../../src/lojban_parser/lists/cmavo


const
  EXAMPLES = [
    "bridi zei valsi", "xy. zei kantu", "kulnr,farsi zei lolgai",
    "na'e zei .a zei na'e zei by. livgyterbilma", ".cerman. zei jamkarce",
    "na'e zei .a zei na'e zei by. zei livgyterbilma", "me la'o ly. spaghetti .ly.",
    "mi cusku lo'u li mi le'u", "mi cusku zo .ai", "mi cusku zoi kuot. I'm John .kuot.",
    ".ui la djan klama", ".ui mi facki fi le mi mapku", ".uiro'obe'unai", "mi .e .ui nai do",
    "mi .e nai .ui do", ".o'onai bu'o", ".iu bu'onai .uinai", "zo bu", "ky.bu .ubu .abu cy. ky.",
    "zai .devanagar. bu", "tei .ebu .akut.bu foi ty. tei .akut.bu .ebu foi",
    ".y'y.bu .abu ny. vo zy. .ibu vo", "mi viska le fu'e .ia blanu zdani fu'o ponse",
    "lo'u mi du do du la djan. le'u na tergerna la lojban.",
    "lu le mlatu cu viska le finpe li'u zo'u lo'u viska le le'u cu selbasti .ei lo'u viska lo " &
      "le'u",
    "la tcarlis. cusku lo'u le ninmu cu morsi le'u .iku'i ri jmive", "zo si cu lojbo valsi",
    "zoi gy. John is a man .gy. cu glico jufra",
    "mi djuno fi le valsi po'u zoi jai. gyrations .jai.",
    "zoi ry. sku .ry. cu rafsi zo cusku", "zo .bab. cmene la bab.", "zo .bab. cmene la'e zo .bab.",
    "la'o dy. Goethe .dy. cu me la'o ly. Homo sapiens .ly.", "ti gerku si mlatu",
    "ta blanu zdani si si xekri zdani", "zo .bab. se cmene zo si si si la bab.",
    "mi cusku zoi fy. gy. .fy. si si si si zo .djan.", "mi se cmene zo .djan. si si zo .djordj.",
    "mi viska le sa .i mi cusku zo .djan.", "mi viska le blanu .zdan. sa le xekri zdani",
  ]
    ## Examples 4.38-44, 6.92-94, 13.2, 13.9, 13.55, 13.61-62, 13.74-75, 17.10-12, 17.18-19,
    ##   19.42, 19.44-45, 19.47-49, 19.51-53, 19.57, 19.75-77, 19.79-81, 19.83, in that order.
  FLOOR_ERASED = 150
    ## Least places erasure law reads: 162 read, between words of each example holding no
    ##   erasure, but after `zo`, `zoi` or `la'o`.



#[ Readers ]#

func unitsRead(text: string): Option[seq[seq[string]]] =
  ## Read prose, and list letters of words each terminal holds; none where prose is refused.
  let reading = text.readText
  if not reading.is_read: return none(seq[seq[string]])
  some(reading.units.mapIt(it.words.mapIt(reading.occurrences[it].text)))


func terminalsRead(text: string): Option[seq[Terminal]] =
  ## Read prose, and list terminal of each unit; none where prose is refused.
  let reading = text.readText
  if reading.is_read: some(reading.units.mapIt(it.terminal)) else: none(seq[Terminal])


func refusalRead(text: string): Option[(RefusalText, int)] =
  ## Read prose, and give rule refusing it with byte it names; none where prose reads.
  let reading = text.readText
  if reading.is_read: none((RefusalText, int)) else: some((reading.refusal, reading.start))


func leaves(node: Node): seq[int] =
  ## List index of each terminal under node, in order of tree.
  if node.is_terminal: return @[node.at]
  for child in node.children: result.add child.leaves



suite "Chapter 4":
  test "Section 4.6":
    check "bridi zei valsi".unitsRead == some(@[@["bridi", "zei", "valsi"]])  # Example 4.38
    check "xy. zei kantu".terminalsRead == some(@[Selmaho.Zei.toTerminal])  # Example 4.39
    check "na'e zei .a zei na'e zei by. livgyterbilma".unitsRead.get.len ==
        2  # Example 4.41, chain of `zei` then lujvo
    check "na'e zei .a zei na'e zei by. zei livgyterbilma".unitsRead.get.len ==
        1  # Example 4.43, one chain
    check "mi zei".refusalRead == some((RefusalText.Construct, 3))  # 4.6, joins two; constructed


  test "Section 4.7":
    check "me la'o ly. spaghetti .ly.".unitsRead ==
        some(@[@["me"], @["la'o", "ly", "spaghetti", "ly"]])  # Example 4.44



suite "Chapter 6":
  test "Section 6.14":
    check "mi cusku lo'u li mi le'u".unitsRead ==
        some(@[@["mi"], @["cusku"], @["lo'u", "li", "mi", "le'u"]])  # Example 6.92
    check "mi cusku zo .ai".unitsRead == some(@[@["mi"], @["cusku"], @["zo", "ai"]])  # Example 6.93
    check "mi cusku zoi kuot. I'm John .kuot.".unitsRead ==
        some(@[@["mi"], @["cusku"], @["zoi", "kuot", "I'm John", "kuot"]])  # Example 6.94



suite "Chapter 13":
  test "Section 13.1-2":
    check ".ui la djan klama".terminalsRead.get[0] ==
        Selmaho.Ui.toTerminal  # Example 13.2, indicator opening text, which rule 0 reads
    check ".ui mi facki fi le mi mapku".terminalsRead.isSome  # Example 13.9


  test "Section 13.7-10":
    check ".uiro'obe'unai".terminalsRead.get.len == 4  # Example 13.55, each opening text
    check "mi .e .ui nai do".unitsRead.get[1] ==
        @["e", "ui", "nai"]  # Example 13.61, `nai` part of UI, all marking `.e`
    check "mi .e nai .ui do".unitsRead.get[1 .. 2] ==
        @[@["e"], @["nai", "ui"]]  # Example 13.62, `nai` of ek, marked
    for text in [".o'onai bu'o", ".iu bu'onai .uinai"]:
      check text.terminalsRead.isSome  # Examples 13.74-75



suite "Chapter 17":
  test "Section 17.4-8":
    check "zo bu".unitsRead == some(@[@["zo", "bu"]])  # Example 17.10, `bu` quoted
    check "ky.bu .ubu .abu cy. ky.".unitsRead ==
        some(@[@["ky", "bu"], @["u", "bu"], @["a", "bu"], @["cy"], @["ky"]])  # Example 17.11
    check "zai .devanagar. bu".unitsRead ==
        some(@[@["zai"], @["devanagar", "bu"]])  # Example 17.12, cmene made lerfu word
    check "tei .ebu .akut.bu foi ty. tei .akut.bu .ebu foi".terminalsRead.isSome  # 17.18
    check ".y'y.bu .abu ny. vo zy. .ibu vo".terminalsRead.isSome  # Example 17.19
    check ".abubu".unitsRead == some(@[@["a", "bu", "bu"]])  # 17.4, "abubu is legal"
    check "bu".refusalRead == some((RefusalText.Construct, 0))  # 17.4, word before; constructed



suite "Chapter 19":
  test "Section 19.8":
    check "mi viska le fu'e .ia blanu zdani fu'o ponse".unitsRead == some(@[
      @["mi"], @["viska"], @["le", "fu'e", "ia"], @["blanu"], @["zdani", "fu'o"], @["ponse"],
    ])  # Example 19.42, `fu'e` and `fu'o` mark word before them (19.16)


  test "Section 19.9":
    check "lo'u mi du do du la djan. le'u na tergerna la lojban.".unitsRead.get[0].len ==
        8  # Example 19.44, quotation whole, grammatical or not
    check "la tcarlis. cusku lo'u le ninmu cu morsi le'u .iku'i ri jmive".terminalsRead.isSome
      # Example 19.47
    check "lo'u le'u".refusalRead == some((RefusalText.Quotation, 5))  # 21.1, one word at least
    check "lo'u mi".refusalRead == some((RefusalText.Quotation, 5))  # 19.9, `le'u` closes it


  test "Section 19.10":
    check "zo si cu lojbo valsi".unitsRead.get[0] == @["zo", "si"]  # Example 19.48, `si` quoted
    check "zoi gy. John is a man .gy. cu glico jufra".unitsRead.get[0] ==
        @["zoi", "gy", "John is a man", "gy"]  # Example 19.49
    check "mi djuno fi le valsi po'u zoi gy. gyrations .gy.".readText.refusal ==
        RefusalText.Stream  # Example 19.50, "ungrammatical as written"
    check "mi djuno fi le valsi po'u zoi jai. gyrations .jai.".terminalsRead.isSome  # 19.51
    check "zoi ry. sku .ry. cu rafsi zo cusku".terminalsRead.isSome  # Example 19.52
    check "zo .bab. cmene la'e zo .bab.".terminalsRead.isSome  # Example 19.54
    check "la'o dy. Goethe .dy. cu me la'o ly. Homo sapiens .ly.".terminalsRead.isSome  # 19.57


  test "Section 19.13":
    check "ti gerku si mlatu".terminalsRead == "ti mlatu".terminalsRead  # Example 19.75
    check "ta blanu zdani si si xekri zdani".terminalsRead ==
        "ta xekri zdani".terminalsRead  # Example 19.76
    check "zo .bab. se cmene zo si si si la bab.".unitsRead ==
        "zo .bab. se cmene la bab.".unitsRead  # Example 19.77, `zo` quotation is two words
    check "mi cusku zoi fy. gy. .fy. si si si si zo .djan.".unitsRead ==
        "mi cusku zo .djan.".unitsRead  # Example 19.79, "four words have been uttered"
    check "mi se cmene zo .djan. si si zo .djordj.".unitsRead ==
        "mi se cmene zo .djordj.".unitsRead  # Example 19.80
    check "mi se cmene zo .djan. si .djordj.".refusalRead ==
        some((RefusalText.Quotation, 26))  # 19.13, "parser will reject" it
    check "mi viska le sa .i mi cusku zo .djan.".unitsRead ==
        ".i mi cusku zo .djan.".unitsRead  # Examples 19.81-82, sentence before `.i` erased
    check "mi viska le blanu .zdan. sa le xekri zdani".unitsRead ==
        "mi viska le xekri zdani".unitsRead  # Example 19.83, `sa` back to `le`
    check "si".refusalRead == some((RefusalText.Construct, 0))  # 19.13, word before; constructed


  test "Section 19.13, Example 19.78":
    check "mi tavla fo la .esperanto si si .esperanton.".unitsRead ==
        "mi tavla fo la .esperanton.".unitsRead  # Example 19.78, `.e speranto` erased as two words


  test "Section 19.15":
    check "mi klama fa'o 日本".unitsRead == some(@[@["mi"], @["klama"]])  # 19.15, input ends
    check "zo fa'o cu cmavo".unitsRead.get[0] == @["zo", "fa'o"]  # 19.15, unless quoted

    # `fa'o` ending text, in each part quotation gives word; tolerant reader of #859 found
    #   `mi cusku zo fa'o` read as `zo` alone, which lost word quoted.
    check "mi klama fa'o".unitsRead == some(@[@["mi"], @["klama"]])  # 19.15, plain: input ends
    check "mi cusku zo fa'o".unitsRead ==
        some(@[@["mi"], @["cusku"], @["zo", "fa'o"]])  # 19.10, `zo` quotes any word; constructed
    check "mi cusku zoi fa'o gy fa'o".unitsRead ==
        some(@[@["mi"], @["cusku"], @["zoi", "fa'o", "gy", "fa'o"]])  # 19.10, delimiter any word
    check "mi cusku la'o fa'o gy fa'o".unitsRead ==
        some(@[@["mi"], @["cusku"], @["la'o", "fa'o", "gy", "fa'o"]])  # 19.10, `la'o` as `zoi`
    check "mi cusku lo'u fa'o".refusalRead ==
        some((RefusalText.Quotation, 14))  # 19.9, `le'u` closes it; byte of word quoted last



suite "Internal: Prose":
  test "Words of each tree, in order, are words of text that erasure leaves":
    var count = 0
    for text in EXAMPLES:
      let reading = text.readText
      check reading.is_read
      if not reading.is_read: continue
      check reading.tree.leaves == toSeq(0 ..< reading.units.len)  # #815, terminals in order
      let held = reading.units.mapIt(it.words).concat
      check held == held.sorted  # 19.13, erasure keeps order of words left
      inc count
    check count == EXAMPLES.len  # IX.3, guard keeps every example


  test "Word and si after it, at each place between words, change no terminal":
    var count = 0
    for text in EXAMPLES:
      let
        words = text.splitWhitespace
        terminals = text.terminalsRead
      if words.anyIt(it in ["si", "sa", "su"]): continue  # erasure already in play
      for at in 1 ..< words.len:
        if words[at - 1] in ["zo", "zoi", "la'o"]: continue  # word after them is quoted
        let erasing = (words[0 ..< at] & @["broda", "si"] & words[at .. ^1]).join(" ")
        check erasing.terminalsRead == terminals  # 19.13, "as if it had never been spoken"
        inc count
    check count >= FLOOR_ERASED  # IX.3, guard keeps erasure in play


  test "zo quotes each cmavo of cmavo list as one terminal":
    var count = 0
    for entry in LIST_CMAVO:
      if '.' in entry.word: continue  # list writes pause as period
      check ("zo " & entry.word).terminalsRead ==
          some(@[Selmaho.Zo.toTerminal])  # 19.10, "any Lojban word whatsoever"
      inc count
    check count >= 590  # IX.3, guard keeps cmavo of list: 598 hold one cmavo


  test "Tie of stream is refused, though grammar reads one split alone":
    let stream = "la .lauras. klama".readStream  # writer means name `lauras`; constructed
    check not stream.is_read and
        stream.detail == "lau ras, or la uras"  # 4.8, `la` opens no cmene, as of `laplas.`
    check "la .lauras. klama".refusalRead ==
        some((RefusalText.Stream, 4))  # `D4 a` of #811, grammar settles no tie
    check "la la .uras. klama".terminalsRead.isSome  # 21.1, fragment of one sumti
    check "la lau .ras. klama".refusalRead ==
        some((RefusalText.Grammar, 8))  # 21.1 rule 987, LAU takes lerfu word
