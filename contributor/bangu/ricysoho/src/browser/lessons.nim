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
        text: "One part of a tanru, or of a selbri that a connective joins."),
    Lesson(lojban: "poi", english: "relative clause", basis: Basis.Marker),
    Lesson(lojban: "nu", english: "abstraction", basis: Basis.Marker),
    Lesson(lojban: "be", english: "link", basis: Basis.Marker),
    Lesson(lojban: "tcita sumti", english: "tagged argument", basis: Basis.Marker),
    Lesson(lojban: "tcita", english: "tag", basis: Basis.Marker),
    Lesson(lojban: "namcu", basis: Basis.Name),
    Lesson(lojban: "zifre", basis: Basis.Name),
  ]
    ## le ctuca be ro klesi be lo linji
  TAGS* = {Selmaho.Bai, Selmaho.Caha, Selmaho.Cuhe, Selmaho.Faha, Selmaho.Fehe, Selmaho.Fiho,
      Selmaho.Ki, Selmaho.Mohi, Selmaho.Pu, Selmaho.Roi, Selmaho.Tahe, Selmaho.Va, Selmaho.Veha,
      Selmaho.Viha, Selmaho.Zaho, Selmaho.Zeha, Selmaho.Zi}
    ## lo selma'o poi cfari pa tcita
    ##   .i `simple-tense-modal` .e `interval-property` pe `CLL 21.1` cu jarco ri
  MARKERS*: array[Category, set[Selmaho]] = [{}, {}, {}, {}, {}, {},
      {Selmaho.Noi, Selmaho.Goi}, {Selmaho.Nu}, {Selmaho.Be}, TAGS + {Selmaho.Fa}, TAGS, {}, {}]
    ## lo selma'o poi jarco le klesi be pa linji pe `Basis.Marker`
    ##   .i lo valsi pe `SE` .a `NAhE` .a `BAhE` .a `JAI` .a lo namcu cu lidne le valsi poi jarco
    ##       le klesi
  LESSON_START* = "Point at a word or a bar to learn it. Click it to keep the lesson, and click " &
      "it again to let it go."
    ## le selci'a poi le ctuca cu jarco ke'a pu lo nu le prenu cu cuxna da
  LESSON_PARTS* = "Made of"  ## le cmene be le liste be ro pagbu be pa linji
  LESSON_IN* = "in"  ## le valsi poi lidne ro linji poi vasru le se cuxna
  LESSON_NONE* = "The lists hold no meaning for this word."
    ## le selci'a poi le ctuca cu jarco ke'a va'o lo nu le liste cu vasru no smuni be pa valsi


func isMarker*(gloss: string, category: Category): bool =
  ## jdice lo du'u lo selma'o poi se cmene `gloss` cu jarco le klesi be pa linji pe `category`
  for selmaho in MARKERS[category]:
    if $selmaho == gloss: return true


func marking*(glosses: openArray[string], category: Category, first, last: int): int =
  ## le stuna'u pe le pamoi valsi pe lo linji poi jarco le klesi to le romoi `D1 c` pe `#1055` toi
  ##   .i `glosses` cu du lo cmene be le selma'o be ro valsi to `toGloss` toi
  ##   .i va'o lo nu no valsi cu jarco le klesi kei le pamoi valsi pe le linji cu se cuxna
  for k in first .. last:
    if glosses[k].isMarker(category): return k
  first


func shownMarker*(word, gloss, definition: string): string =
  ## le selci'a poi skicu pa linji ta'i le valsi poi jarco le klesi to `Basis.Marker` toi
  word & " · " & gloss & " · " & definition
