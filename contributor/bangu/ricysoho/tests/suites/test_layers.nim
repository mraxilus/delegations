## cipra lo linji poi zvati lo cnita be lo valsi .e lo skari be lo valsi to `layers.nim` toi
##   .i ro linji cu vasru lo valsi pe lo jgena pe le tricu poi le linji cu sinxa ke'a
##   .i ro linji cu zvati lo jbini be le linji poi vasru ke'a
##   .i ro valsi cu skari ja'i le girzu be le selma'o be ke'a to `D3 a` pe `#1055` toi
##   .i le selci'a cu du ro selci'a pe le selci'agri to `corpora.nim` toi

{.experimental: "strictFuncs".}

import std/[options, sets, unittest]

import ../../src/ricysoho/[forms, grammar, layers, prose, selmaho, stream, tanru]
import ./corpora


const
  COUNT_TEXTS_LEAST = 1900
    ## lo klani be lo selci'a poi le cipra cu tcidu ke'a
    ##   .i ca lo nu le cipra cu se jmina kei le klani cu du li 1944
  COUNT_BARS_LEAST = 20000
    ## lo klani be lo linji poi le cipra cu cipra ke'a
    ##   .i ca lo nu le cipra cu se jmina kei le klani cu du li 20599
  COUNT_MARKED_LEAST = 75
    ## lo klani be lo selci'a poi le gerna cu sisti bu'u ke'a
    ##   .i le selci'a cu se tcidu ta'i lo nu sinxa lo srera
    ##   .i ca lo nu le cipra cu se jmina kei le klani cu du li 82
  GROUPS_SELMAHO = [
    (Selmaho.Koha, Group.Sumti),  # `CLL 7.1`
    (Selmaho.Le, Group.Sumti),  # `CLL 6.2`
    (Selmaho.La, Group.Sumti),  # `CLL 6.2`
    (Selmaho.Se, Group.Predicate),  # `CLL 5.11`
    (Selmaho.Goha, Group.Predicate),  # `CLL 7.6`
    (Selmaho.Pa, Group.Number),  # `CLL 18.2`
    (Selmaho.Moi, Group.Number),  # `CLL 18.18`
    (Selmaho.Pu, Group.Tag),  # `CLL 10.2`
    (Selmaho.Fa, Group.Tag),  # `CLL 9.3`
    (Selmaho.Bai, Group.Tag),  # `CLL 9.6`
    (Selmaho.Na, Group.Tag),  # `CLL 15.2`
    (Selmaho.Noi, Group.Link),  # `CLL 8.1`
    (Selmaho.Nu, Group.Link),  # `CLL 11.1`
    (Selmaho.Be, Group.Link),  # `CLL 5.7`
    (Selmaho.A, Group.Link),  # `CLL 14.6`
    (Selmaho.Ui, Group.Free),  # `CLL 13.1`
    (Selmaho.Coi, Group.Free),  # `CLL 13.14`
    (Selmaho.Cu, Group.Structure),  # `CLL 9.2`
    (Selmaho.I, Group.Structure),  # `CLL 19.2`
    (Selmaho.Ku, Group.Structure),  # `CLL 6.2`
  ]
    ## pa selma'o pe ro selma'o poi le girzu cu cmene ke'a ge'u .e le girzu be ri


type Span = tuple[first, last: int]


func spanned(reading: ReadingMarked, node: Node, rules: var HashSet[(string, Span)]): Span =
  ## lo stuna'u pe le pamoi valsi .e le romoi valsi pe `node`
  ##   .i ji'a jmina le javni .e le stuna'u pe ro jgena poi na srejge `rules`
  if node.is_terminal:
    let unit = reading.units[node.at]
    return (unit.words[0], unit.words[^1])
  result = (int.high, -1)
  for child in node.children:
    let span = reading.spanned(child, rules)
    result = (min(result.first, span.first), max(result.last, span.last))
  if node.stop.isNone: rules.incl (node.rule, result)


suite "Internal: Bars of text":
  test "Each bar covers the words of its node, and stands inside the bar that holds it":
    var texts, bars, marked = 0
    for (name, text) in textsCorpora():
      let reading = text.readTextMarked
      if reading.occurrences.len == 0: continue
      inc texts
      var rules: HashSet[(string, Span)]
      discard reading.spanned(reading.tree, rules)
      if reading.tree.stop.isSome: inc marked
      let layers = reading.toLayers
      for k, bar in layers.bars:
        inc bars
        check (bar.rule, (bar.first, bar.last)) in rules
        check bar.category != Category.Tail
        check bar.first <= bar.last
        if bar.parent >= 0:
          let above = layers.bars[bar.parent]
          check bar.parent < k
          check above.first <= bar.first and bar.last <= above.last
          check above.depth + 1 == bar.depth
        else:
          check bar.depth == 0
        if not ((bar.rule, (bar.first, bar.last)) in rules): checkpoint name & ": " & text
    check texts >= COUNT_TEXTS_LEAST
    check bars >= COUNT_BARS_LEAST
    check marked >= COUNT_MARKED_LEAST

  test "Each bar stands one row below the bars it holds, and the rows hold every bar":
    for (name, text) in textsCorpora():
      let layers = text.readTextMarked.toLayers
      var most = newSeq[int](layers.bars.len)
      for k in countdown(layers.bars.high, 0):
        check layers.bars[k].height == most[k]
        let parent = layers.bars[k].parent
        if parent >= 0: most[parent] = max(most[parent], layers.bars[k].height + 1)
      var rows = 0
      for bar in layers.bars: rows = max(rows, bar.height + 1)
      check layers.rows == rows


suite "Chapter 20":
  test "Each word takes group of its selma'o, brivla predicate and cmene sumti":
    for (selmaho, group) in GROUPS_SELMAHO: check selmaho.toGroup == group
    for (name, text) in textsCorpora():
      let stream = text.readStream
      if not stream.is_read: continue
      for occurrence in stream.occurrences:
        let reading = occurrence.reading
        if not reading.is_word:
          check reading.toGroup == Group.Refused
        elif reading.selmaho.isSome:
          check reading.toGroup == reading.selmaho.get.toGroup
          check reading.toGloss == $reading.selmaho.get
        elif reading.kind == Kind.Cmene:
          check reading.toGroup == Group.Sumti
          check reading.toGloss == "CMENE"
        elif reading.kind in {Kind.Gismu, Kind.Lujvo, Kind.Fuhivla}:
          check reading.toGroup == Group.Predicate
          check reading.toGloss == "BRIVLA"

  test "Each selma'o takes one of seven groups, and never group of refused word":
    for selmaho in Selmaho: check selmaho.toGroup != Group.Refused
