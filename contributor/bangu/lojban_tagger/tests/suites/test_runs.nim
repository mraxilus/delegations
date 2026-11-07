## Replicate which run of tanru units tag holds unchanged, against `runs.nim`: what group around
##   run changes, as CLL chapters 5, 12 and 15 give it.
##   Each assertion folds example CLL gives, or tanru of `ciska`, `vreji` and `gunka` where
##     section gives none holding SE. Tanru is read as text, so no rafsi choice enters; where
##     CLL gives lujvo, its words are those reader gives it.
##   Fold itself is that of `lojban_parser`, whose suite `test_tanru_units.nim` holds it; this
##     suite holds runs alone.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[options, unittest]

import ../../../lojban_parser/src/lojban_parser

import ../../src/lojban_tagger/[runs, tags]


func folded(text: string): seq[TanruUnit] =
  ## Fold tanru text, words joined by `+`, into tanru units.
  readTanru(text).get.tanruUnits



suite "Chapter 5":
  test "Section 5.5":
    let closed = folded("se+ke+ciska+vreji+ke'e+gunka")
    check not closed.isHoldingUnchanged(folded("ciska+vreji"))  # 5.5, `se` binds group whole
    check closed.isHoldingUnchanged(folded("ciska"))  # 5.5, part of group stays as it is


  test "Section 5.8":
    check not "selkemselci'aveicolgu'a".readTag.tag.tanruUnits.isHoldingUnchanged(
        folded("se+ciska+vreji"))  # 5.8, group ends before `co`, so `se` converts run whole


  test "Section 5.11":
    check not "selkemveiselci'a".readTag.tag.tanruUnits.isHoldingUnchanged(
        folded("se+ciska"))  # 5.11, converting tanru converts its head: here `se se ciska`
    check "selkemselci'avei".readTag.tag.tanruUnits.isHoldingUnchanged(
        folded("se+ciska"))  # 5.11, modifier of converted tanru keeps its own places



suite "Chapter 12":
  test "Section 12.11":
    let converse = "selselgekmau".readTag.tag.tanruUnits
    check not converse.isHoldingUnchanged(folded("se+gleki+zmadu"))  # 12.11, "se selgekmau"
    check converse.isHoldingUnchanged(folded("se+gleki"))  # 12.11, `se gleki` modifies `zmadu`
    check folded("se+gleki+zmadu").isHoldingUnchanged(
        folded("se+gleki+zmadu"))  # 12.11, `selgekmau` holds itself unchanged
    check not folded("se+se+ciska+vreji+gunka").isHoldingUnchanged(
        folded("se+se+ciska+vreji"))  # 12.11, outer `se` here converts group up to `gunka`
    check folded("se+se+ciska+vreji").isHoldingUnchanged(
        folded("se+se+ciska+vreji"))  # 12.11, same group, closed by end of both


  test "Section 12.12":
    check not "nunkemveiselci'a".readTag.tag.tanruUnits.isHoldingUnchanged(
        folded("se+ciska"))  # 12.12, x1 of abstraction is event, so head of group changes



suite "Chapter 15":
  test "Section 15.4":
    check not "nalkemselci'avei".readTag.tag.tanruUnits.isHoldingUnchanged(
        folded("se+ciska"))  # 15.4, `na'e ke` denies whole group, so no part holds as it is
