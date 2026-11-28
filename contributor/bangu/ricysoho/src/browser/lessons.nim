## lo glico selci'a .e lo javni poi le ctuca pe le papri pe lo linji cu pilno ke'a
##   .i `Architect` jdice lo du'u le ctuca cu glico bu'u `#1055`
##   .i lo smuni pe le liste pe `Logical Language Group` cu basti lo selci'a pe le papri va'o lo nu
##       le liste cu vasru ke'a to `D1 c` toi
##   .i `suites/test_layers.nim` jarco lo du'u le javni cu mapti ro linji pe le selci'agri

{.experimental: "strictFuncs".}

import ../ricysoho/[layers, selmaho]


type  # le ctuca be pa klesi be lo linji
  Basis* {.pure.} = enum
    Name  ## le smuni be le jbocme be le klesi ne'i le liste
    Marker  ## le smuni be le valsi poi jarco le klesi ne'i le linji to `marking` toi
    Own  ## le glico selci'a pe le papri

  Lesson* = object
    lojban*: string  ## le jbocme be le klesi
    english*: string
      ## le glico cmene be le klesi
      ##   .i kunti va'o lo nu le klesi cu pilno le glico valsi pe le liste to `Basis.Name` toi
    basis*: Basis
    text*: string  ## le glico selci'a pe le papri to `Basis.Own` toi


const  # ro glico selci'a .e ro javni pe le ctuca
  LESSON_KIND*: array[Category, Lesson] = [
    Lesson(lojban: "bridi", basis: Basis.Name),
    Lesson(lojban: "romoi", english: "tail", basis: Basis.Own,
        text: "The tail of a bridi: its selbri and each sumti after it."),
    Lesson(lojban: "sumti", basis: Basis.Name),
    Lesson(lojban: "selbri", english: "relation", basis: Basis.Own,
        text: "The relation that a bridi claims. Each of its places takes a sumti."),
    Lesson(lojban: "tanru", basis: Basis.Name),
    Lesson(lojban: "tanru pagbu", english: "compound part", basis: Basis.Own,
        text: "One part of a tanru. The last part is the head, and each part before it " &
        "narrows its sense."),
    Lesson(lojban: "poi", english: "relative clause", basis: Basis.Marker),
    Lesson(lojban: "nu", english: "abstraction", basis: Basis.Marker),
    Lesson(lojban: "be", english: "link", basis: Basis.Marker),
    Lesson(lojban: "tcita sumti", english: "tagged argument", basis: Basis.Marker),
    Lesson(lojban: "tcita", english: "tag", basis: Basis.Marker),
    Lesson(lojban: "namcu", basis: Basis.Name),
    Lesson(lojban: "zifre", basis: Basis.Name),
  ]
    ## le ctuca be ro klesi be lo linji
  PREFIXES* = {Selmaho.Se, Selmaho.Nahe, Selmaho.Bahe, Selmaho.Pa}
    ## lo selma'o poi zvati le cfari be lo linji gi'e na jarco le klesi
    ##   .i zo se .e zo na'e cu lidne lo tcita .a lo valsi pe `NU` to `CLL 21.1` toi
    ##   .i zo ba'e cu lidne ro valsi
    ##   .i lo namcu cu lidne lo valsi pe `ROI`
  LESSON_START* = "Point at a word or a bar to learn it. Click it to keep the lesson, and click " &
      "it again to let it go."
    ## le selci'a poi le ctuca cu jarco ke'a pu lo nu le prenu cu cuxna da
  LESSON_PARTS* = "Made of"  ## le cmene be le liste be ro pagbu be pa linji
  LESSON_IN* = "in"  ## le valsi poi lidne ro linji poi vasru le se cuxna
  LESSON_NONE* = "The lists hold no meaning for this word."
    ## le selci'a poi le ctuca cu jarco ke'a va'o lo nu le liste cu vasru no smuni be pa valsi


func isPrefix*(gloss: string): bool =
  ## jdice lo du'u lo selma'o poi se cmene `gloss` cu pagbu `PREFIXES`
  for selmaho in PREFIXES:
    if $selmaho == gloss: return true


func marking*(glosses: openArray[string], first, last: int): int =
  ## le stuna'u pe le pamoi valsi pe lo linji poi jarco le klesi
  ##   .i `glosses` cu du lo cmene be le selma'o be ro valsi to `toGloss` toi
  ##   .i le valsi cu na pagbu `PREFIXES` gi'a romoi le linji
  result = first
  while result < last and glosses[result].isPrefix: inc result


func shownMarker*(word, gloss, definition: string): string =
  ## le selci'a poi skicu pa linji ta'i le valsi poi jarco le klesi to `Basis.Marker` toi
  word & " · " & gloss & " · " & definition
