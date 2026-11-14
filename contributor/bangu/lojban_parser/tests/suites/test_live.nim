## cipra lo du'u lo tcidu be lo jmive se ciska cu mapti lo flalu pe vo'a to `#859` toi .i ca lo
##   fanmo lo se ciska poi ro spisa be ke'a cu se tcidu ta'i lo porsi cu jarco la'o gy. NIF .gy. pe
##   lo pagbu be le se ciska poi se tcidu ta'i lo mulno to `toNifParts` pe `readTextParts` toi .i ro
##   stuzi pe le re se ciska be fi la'o gy. NIF .gy. cu mintu va'o ro nu le spisa cu katna le se
##   ciska
##   .i lo spisa cu jalge lo cunso nu katna poi se jdice lo tsiju .i le nu katna cu ka'e zvati ne'i
##     lo valsi .i le cipra cu katna ro remoi se ciska pe le se ciska liste ge'u .e lo se ciska poi
##     se zbasu fi lo valsi poi galfi lo pu valsi to `texts_built.nim` toi .i ki'u bo le se ciska
##     liste cu vasru so'u le valsi .i ne'i le flalu pe lo jdima ro se ciska valsi cu spisa
##   .i ro cenba cu katna la'o gy. NIF .gy. ne'i le se ralte po'o .i la'o gy. NIF .gy. poi stali ba
##     le cenba cu mintu la'o gy. NIF .gy. poi le tcidu cu ralte ke'a .i pu lo fanmo
##     la'o gy. NIF .gy. .e le rebla pe ro cenba cu mintu la'o gy. NIF .gy. pe lo pagbu be lo se
##     ciska poi ca zvati gi'e fanmo bu'u lo romoi sinxa poi jbini lo valsi be'o poi se tcidu ta'i
##     pa mulno jmive se ciska .i se ki'u bo le tricu cu zenba ta'i lo nu le se ciska poi ca zvati
##     cu jarco le tricu
##   .i ro cenba cu jorne le se ciska .i ro valsi pe la'o gy. NIF .gy. poi le cenba cu ralte ke'a cu
##     fanmo bu'u lo stuzi poi na se lidne le krasi be le cenba .i ro valsi pe lo jgena poi le cenba
##     cu jarco ke'a cu krasi bu'u lo stuzi poi na lidne le krasi be le cenba
##   .i le pagbu be le se ciska cu cirko no pagbu be le tricu .i `assembleText` cu zbasu lo tricu
##     poi `readGrammar` cu jarco ke'a ku'o fi le pagbu
##   .i lo spisa poi se katna fi lo jufra to `toSentences` toi zi'e poi ro jufra pe ke'a cu se tcidu
##     ta'i lo porsi cu jarco ne'i pa cenba to `combine` toi lo se jarco be lo spisa poi se tcidu
##     ta'i lo mulno .i le se jarco cu vasru la'o gy. NIF .gy. pe lo pagbu be le se ciska ca lo
##     fanmo .i ji'a la'o gy. NIF .gy. cu se ralte gi'e zenba .i ji'a le cenba cu jorne le se ciska
##     .i le spisa cu jalge lo nu jmina ro le jufra .i ro jufra cu vasru pa cmavo be zoi gy. I .gy.
##     .a zoi gy. NIhO .gy. be'o noi pamoi valsi be le jufra
##   .i jdima fa lo nu lo stuzi poi se tcidu ca ro nu tcidu cu zenba ca lo nu le se ciska cu zmadu
##     lo ka clani .i va'o lo nu ro valsi pe lo se jorne jufra pe la'o gy. Tatoeba .gy. cu spisa kei
##     lo stuzi poi se tcidu cu na zmadu lo pilji be `COST_MOST` bei lo stuzi pe le jufra .i va'o lo
##     nu le se ciska cu clani re roi kei lo stuzi poi se tcidu cu du lo pilji be li re bei lo stuzi
##     poi pu se tcidu
##   .i lo mupli cu jarco lo cenba pe ro spisa .i ro stuzi pe le cenba cu se cipra .i le mupli cu
##     cipra lo nu lo jufra cu se benji kei .e lo nu lo valsi cu se katna kei .e lo nu zo si cu
##     katna la'o gy. NIF .gy. kei .e lo nu zo su cu fanmo lo se ciska gi'e katna no da gi'a fanmo
##     zo lu poi lidne zo su kei .e lo nu lo fanmo valsi cu rapli tcidu lo nu sitna kei .e lo nu zo
##     le'u cu sitna zo su kei .e lo nu zo zei cu jorne zo .i

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[options, random, sequtils, strutils, unittest]

import ../../src/lojban_parser/[grammar, live, nif, prose, selmaho, stream]
import ../sample_tatoeba/sentences
import ./[corpora, reader_nif, texts_built]


type
  Change = tuple[at, start: int, text, tail: string]
    ## lo cenba poi pa spisa cu jarco ke'a ne'i la'o gy. NIF .gy.

  ReadingLive = object  ## lo jalge be lo nu tcidu ro spisa be lo se ciska ta'i lo porsi
    nif: string  ## la'o gy. NIF .gy. poi se ralte ca lo fanmo gi'e se galfi ro cenba
    changes: seq[Change]  ## lo cenba pe ro spisa ge'u .e ba bo lo cenba pe lo fanmo
    is_held: bool
      ## lo du'u ro cenba cu katna la'o gy. NIF .gy. ne'i le se ralte gi'e se lidne lo nu le tcidu
      ##   cu ralte le se ralte
    is_grown: bool
      ## lo du'u pu lo fanmo la'o gy. NIF .gy. .e le rebla pe ro cenba cu mintu la'o gy. NIF .gy. pe
      ##   lo pagbu be le se ciska poi ca zvati
    is_tied: bool
      ## lo du'u ro valsi pe la'o gy. NIF .gy. poi ro cenba cu ralte ke'a cu fanmo bu'u lo stuzi poi
      ##   na se lidne le krasi be le cenba .i ji'a ro valsi pe lo jgena poi le cenba cu jarco ke'a
      ##   cu krasi bu'u lo stuzi poi na lidne le krasi be le cenba
    is_cut: bool
      ## lo du'u ro spisa cu jalge lo nu jmina lo jufra poi le spisa cu se katna fi ke'a kei kei .e
      ##   lo du'u ro jufra poi le porsi be lo valsi cu tcidu ke'a po'o cu vasru pa cmavo be
      ##   zoi gy. I .gy. .a zoi gy. NIhO .gy. be'o noi pamoi valsi be le jufra .i ji'a la'e di'u
      ##   jetnu va'o lo nu ro spisa cu se tcidu ta'i lo mulno
    count_sentences: int
      ## lo klani be lo jufra poi le porsi be lo valsi cu tcidu ke'a po'o .i `is_cut` cu cipra le
      ##   jufra
    count_read: int  ## lo sumji be lo stuzi poi se tcidu ca ro nu tcidu


const
  SEED = 859  ## lo tsiju be lo cunso nu katna .e lo se ciska poi se zbasu
  COUNT_BUILT = 300  ## lo klani be lo se ciska poi se zbasu fi lo valsi poi galfi lo pu valsi
  PIECE_MOST = 6
    ## lo stuzi pe lo cunso spisa be lo se ciska poi se zbasu cu na zmadu le stodi .i se ki'u bo lo
    ##   spisa cu katna lo valsi
  PIECE_CORPORA_MOST = 96
    ## lo stuzi pe lo cunso spisa be lo se ciska pe le se ciska liste cu na zmadu le stodi .i lo se
    ##   ciska poi vasru pa jufra cu se rapli tcidu ca ro spisa .i se ki'u bo da'i va'o lo nu ro
    ##   valsi cu spisa kei lo jdima cu du `100 s` ne'i lo cikre zbasu .i le temci cu du lo pilji be
    ##   li pavo bei lo temci be lo nu tcidu le se ciska liste ta'i lo mulno
  COUNT_CORPORA_LEAST = 950
    ## lo se ciska poi cmima le se ciska liste gi'e se tcidu ta'i lo jmive se ciska .i ro remoi se
    ##   ciska pe le pasovopa se ciska cu se tcidu .i ki'u bo lo jdima be ro se ciska cu du lo pilji
    ##   be li ci bei lo jdima be lo nu tcidu le se ciska ta'i lo mulno .i lo jdima be lo nu tcidu
    ##   lo xadba be le se ciska liste cu jibni `12 s` ne'i lo cikre zbasu

  COUNT_PARTED_LEAST = 100
    ## lo se ciska poi cmima le se ciska liste gi'e vasru za'u pa pagbu be ke'a .i ro pagbu pe le se
    ##   ciska cu se tcidu
  COUNT_SENTENCES_CORPORA_LEAST = 450
    ## lo se ciska poi cmima le se ciska liste gi'e se tcidu ta'i lo nu tcidu ro jufra pe ke'a ta'i
    ##   lo porsi .i ro vomoi se ciska pe le pasovopa se ciska cu se tcidu .i le flalu poi tcidu ro
    ##   remoi se ciska cu na tcidu le se ciska .i di'u se cuxna ki'u lo jdima be le cipra
  COUNT_SENTENCES_LEAST = 600
    ## lo jufra poi le porsi be lo valsi cu tcidu ke'a po'o zi'e noi le flalu pe le nu katna cu
    ##   cipra ke'a ne'i lo se ciska poi se zbasu .i ca lo nu le flalu cu se jmina kei le jufra cu
    ##   xazeze mei .i ki'u bo pa jufra po'o cu ka'e katna lo valsi gi'a krasi ne'i lo nu sitna
  SENTENCES_COST = 30
    ## lo se jorne jufra pe la'o gy. Tatoeba .gy. .i le flalu pe lo jdima cu tcidu le jufra .i ba bo
    ##   le flalu cu tcidu lo se ciska poi vasru le jufra re roi
  COST_MOST = 12.0
    ## lo zmadu traji frinu be lo stuzi poi se tcidu bei lo stuzi pe le se ciska ca lo nu ro valsi
    ##   cu spisa .i ca lo nu le flalu cu se jmina kei le frinu cu du li bi pi re .i ki'u bo ro
    ##   spisa cu rapli tcidu lo jufra poi ca'o kalri
  COST_TWICE_MOST = 2.2
    ## lo zmadu traji frinu be lo stuzi poi le se ciska poi re roi clani cu tcidu ke'a bei lo stuzi
    ##   poi le se ciska cu tcidu ke'a
  TEXTS_LOHU_ERASED = [
    # le cunso cipra pe le flalu pe lo jmive se ciska cu facki le se ciska .i zo fa'o cu se tcidu
    #   ta'i lo valsi
    "lo'u cu le'u si mi .i fa'o zarci",
    "lo'u le'u si mi .i zoi gy. ko .gy.",  # zo zoi cu se tcidu ta'i lo valsi ne'i lo nu sitna
    "lo'u mi le'u sa le'u do .i fa'o ko",  # zo sa cu vimcu zo le'u
    # zo zo cu sitna lo pamoi cmavo po'u zo le'u .i lo remoi cu fanmo lo nu sitna
    "lo'u zo le'u le'u si mi .i fa'o ko",
  ]
    ## lo se ciska poi vasru zo lo'u poi lo nu vimcu cu vimcu zo le'u pe ke'a .i le se ciska cu
    ##   vasru lo valsi poi se lidne zo le'u zi'e poi le porsi be lo valsi cu tcidu ke'a ta'i lo
    ##   drata ne'i lo valsi poi zo lo'u cu sitna ke'a .i le valsi cu du zo fa'o noi fanmo lo se
    ##   ciska ku'o .a zo zoi noi sitna lo se ciska .i le se ciska cu se finti
  TEXTS_LOHU_QUOTED = [
    # le cunso cipra pe le flalu pe lo jmive se ciska cu facki le se ciska .i zo fa'o cu se tcidu
    #   ta'i lo valsi
    "zo lo'u si nai fa'o cu",
    "zo lo'u si .i zoi gy. ko .gy.",  # zo zoi cu se tcidu ta'i lo valsi ne'i lo nu sitna
    "zo lo'u si ui fa'o mi",  # lo cinmo valsi poi se lidne zo si
  ]
    ## lo se ciska poi ne'i ke'a zo zo cu sitna pa zo lo'u goi ko'a ta'i lo nu le porsi be lo valsi
    ##   cu tcidu .i zo si cu vimcu ko'a .i se ki'u bo le javni cu to'e curmi zo zo .i ko'a cu zvati
    ##   pa pagbu poi vasru ko'a po'o .i ku'i le porsi be lo valsi cu tcidu no valsi poi ko'a cu
    ##   sitna ke'a .i ba bo le se ciska cu vasru lo valsi poi le porsi be lo valsi cu tcidu ke'a
    ##   ta'i lo drata ne'i lo valsi poi zo lo'u cu sitna ke'a .i le se ciska cu se finti
  TEXTS_LOHU_HELD = [
    # le cunso cipra pe le flalu pe lo jmive se ciska cu facki le se ciska .i zo la'o cu se tcidu
    #   ta'i lo nu sitna
    "zo la'o si lo'u mi .i la'o",
    "zo la'o si lo'u do .i fa'o mi",  # zo fa'o cu se tcidu ta'i lo fanmo be le se ciska
    "zo zoi si lo'u mi .i zoi gy. ko .gy.",  # zo zoi cu se tcidu ta'i lo nu sitna
  ]
    ## lo se ciska poi ne'i ke'a zo zo cu sitna pa cmavo goi ko'a ta'i lo nu le porsi be lo valsi cu
    ##   tcidu .i ko'a cu du zo la'o .a zo zoi .i zo si cu vimcu ko'a .i ba bo le javni cu tcidu
    ##   ko'a ta'i lo nu sitna be ci valsi .i zo lo'u cu cmima le ci valsi .i le porsi be lo valsi
    ##   cu tcidu lo du'u zo lo'u cu sitna ro valsi poi se lidne zo lo'u .i se ki'u bo lo bavla'i
    ##   valsi cu se tcidu ne'i le valsi poi zo lo'u cu sitna ke'a .i le se ciska cu se finti
  TEXTS_SA_PARTED = [
    # le cunso cipra pe le flalu pe lo jmive se ciska cu facki le se ciska .i zo sa na se rapli
    #   tcidu
    "ni'o .i sa 1987 zo .i si",
    "mi klama .i sa 1987 zo .i si do",  # lo valsi poi se lidne zo si
    "ni'o .i sa 1987 1988 zo .i si",  # re valsi poi le porsi be lo valsi cu to'e curmi ke'a
    # le cunso cipra pe le flalu pe lo jmive se ciska cu facki le se ciska .i zo bu .e ba bo zo ba'e
    #   cu se to'e curmi
    "ui lo sa bu ba'e le si",
    "ui lo sa zei ba'e le si",  # zo zei .e ba bo zo ba'e cu se to'e curmi
  ]
    ## lo se ciska poi ne'i ke'a lo valsi poi se to'e curmi le porsi be lo valsi .a le javni cu
    ##   jbini zo sa .e lo valsi poi se lidne le se to'e curmi .i le valsi cu dunda lo sinxa be zo
    ##   sa to `CLL 19.13` toi .i lo bavla'i valsi cu rinka lo nu le valsi cu se to'e curmi ji'a .i
    ##   se ki'u bo le sinxa cu cenba .i mupli fa lo nu zo si cu vimcu lo valsi poi zo zo cu sitna
    ##   ke'a kei noi rinka lo nu zo zo cu se to'e curmi .i mupli fa ji'a lo nu zo ba'e cu tcita no
    ##   valsi .i le se ciska cu se finti
  TEXTS_ZEI_REFUSED = [
    # le cunso cipra pe le flalu pe lo jmive se ciska cu facki le se ciska .i zo zei na se rapli
    #   tcidu
    "lo'u bu zei zoi lu nai ui si cu je",
    "lo'u bu zei la'o lu nai ui si cu je",  # zo la'o
    "lo'u bu zei zoi lu nai ui si klama do",  # zo klama
    "lo'u bu bu zei zoi lu nai ui si cu je",  # re zo bu
    "lo'u bu zei ui si zoi lu nai ui si cu je",  # lo nu vimcu poi jbini zo zei .e lo nu sitna
  ]
    ## lo se ciska poi ne'i ke'a le javni cu to'e curmi zo bu .e zo zei .i lo nu sitna cu cfari ba
    ##   zo zei ne'i lo valsi poi zo lo'u cu sitna ke'a .i zo lo'u cu denpa ta'i lo krasi valsi .i
    ##   zo si cu vimcu lo valsi poi le nu sitna cu sitna ke'a .i se ki'u bo le javni cu to'e curmi
    ##   le nu sitna ji'a .i zo zei cu rinka lo nu zo bu cu jorne lo valsi poi se lidne zo zei to
    ##   `CLL 19.16` toi .i le se ciska cu se finti
  CUTS_CLOSER = [
    # le cunso cipra pe le flalu pe lo jmive se ciska cu facki le se ciska
    (text: "to .i to toi to bu toi ba'e", cuts: @[1, 9, 18, 23, 24]),
    (text: "to mi .i to bu toi do", cuts: @[6, 12, 13, 19]),
    (text: "lu mi .i lu bu li'u do", cuts: @[5, 11, 14, 20]),
    (text: "tu'e mi .i tu'e bu tu'u do", cuts: @[6, 8, 9, 11, 14, 16, 18, 24]),
  ]
    ## lo se ciska poi ne'i ke'a pa krasi valsi cu denpa .i lo se ciska poi se rapli tcidu cu krasi
    ##   bu'u lo stuzi poi se lidne le krasi valsi .i ba bo zo bu cu rinka lo nu lo krasi valsi poi
    ##   zvati le se ciska poi se rapli tcidu cu lerfu valsi .i se ki'u bo lo fanmo valsi cu fanmo
    ##   le pamoi krasi valsi noi lidne le se ciska poi se rapli tcidu .i lo nu katna le se ciska
    ##   ta'i la'e di'u cu se facki lo nu sisku lo cunso nu katna .i le se ciska cu se finti
  TEXTS_SU = [
    # lo nu vimcu poi se lidne zo su cu klama no valsi poi lidne zo su to `CLL 19.13` toi
    "mi su si do", "mi su sa do",
    # zo lu cu se fanmo bu'u zo su .i se ki'u bo zo li'u poi se lidne zo su cu fanmo no da
    "lu mi klama .i do su ko li'u",
    "lo'u mi su do le'u .i ko",  # zo le'u cu sitna zo su
    "ba'e zoi su li'u bu si cu .i su fa'o",  # zo zoi cu sitna zo su .i zo ba'e cu tcita le nu sitna
    # lo nu vimcu cu rinka lo nu zo su cu rapli se sitna .i ki'u bo le nu sitna cu se tcidu ta'i lo
    #   mulno
    "zo su si si", "zo su si sa zarci",
    # zo le'u cu sitna zo su .i zo la'o cu se tcidu ta'i lo valsi
    "lo'u su la'o le le'u sa le klama",
  ]
    ## lo se ciska poi ne'i ke'a zo su cu fanmo lo se ciska poi lidne zo su ku'o .a lo se ciska poi
    ##   ne'i ke'a lo nu sitna cu sitna zo su ca lo nu le nu sitna cu se fanmo kei gi'e galfi lo
    ##   valsi poi lidne zo su .i le cunso cipra pe le flalu pe lo jmive se ciska cu facki le romoi
    ##   vo se ciska .i le romoi cu pu se tcidu ta'i lo srera ca lo nu zo su pu vimcu lo se ciska
    ##   poi lidne zo su
  CUTS_ENDED = [
    (text: "tu'u si fa'o lo", cuts: toSeq(1 .. 14)),
    (text: "gy ku xyz ba'e gy si fa'o zo sa 1987", cuts: @[2, 6, 7, 12, 17, 22, 25, 31, 33, 34]),
    (
      text: "cu sa'a sa'a li'u si fa'o ni'o 1987 .i",
      cuts: @[4, 5, 8, 13, 19, 23, 25, 26, 31, 36],
    ),
  ]
    ## lo se ciska poi ne'i ke'a lo valsi poi lo nu vimcu cu vimcu ke'a cu lidne zo fa'o .i lo jgena
    ##   pe zo fa'o cu pilno lo se kuspe be le valsi .i lo nu katna cu se facki le cunso cipra pe le
    ##   flalu pe lo jmive se ciska ca lo nu se jmina fa lo pagbu pe ro valsi poi no pagbu pu vasru
    ##   ke'a
  LINE_MI_KLAMA = "(sentence 0 (sumti_6 80 (KOhA 0 2 \"mi\")) (bridi_tail_3 50 " &
    "(tanru_unit_2 130 (BRIVLA 3 8 \"klama\")) (tail_terms)))\n"
    ## lo linji pe lo jgena pe `mi klama` .i lo mupli cu se krasi le linji
  LINE_DO = "(text_1 0 (I 10 11 \"i\") (sumti_6 4 (KOhA 12 14 \"do\")))\n"
    ## lo linji pe lo jgena pe `.i do` poi se lidne `mi klama` ca lo nu le jufra cu kalri
  LINE_ERASED = "(rivbi Erasure 3 8 \"klama\" 10 11 \"i\" 12 14 \"do\" 15 17 \"si\" " &
    "18 20 \"si\" 21 23 \"si\")\n"
    ## lo linji pe lo valsi poi ci zo si cu vimcu ke'a ne'i `mi klama .i do si si si` .i ro zo si cu
    ##   kansa le valsi ne'i pa pagbu
  LINE_SUHI = "(srera 3 paragraphs (nitcu A BAI BIhI BU BY CAhA CEhE COI CU CUhE DOI FA " &
    "FAhA FEhE FIhO GA GAhO GOI GOhA GUhA I JAI JOI KE KI KOhA LA LAU LAhE LE LI LOhU LU ME " &
    "MOhI NA NAhE NIhO NOI NU NUhA NUhI PA PEhE PU SE SEI SOI TAhE TEI TO VA VAU VEI VEhA " &
    "VIhA VUhO XI ZAhO ZEI ZEhA ZI ZO ZOI ZOhU BRIVLA) (sumti_6 0 (KOhA 0 2 \"mi\")) " &
    "(mex_operator 370 (VUhU 3 7 \"suhi\")) (sumti_6 0 (KOhA 8 10 \"do\")))\n"
    ## lo linji pe lo jgena pe `mi su'i do` .i le gerna cu sisti ne'i le jgena bu'u zo su'i
  LINE_ZEI = "(sentence 0 (sumti_6 80 (KOhA 0 2 \"mi\")) (bridi_tail_3 50 " &
    "(selbri_3 130 (tanru_unit_2 134 (BRIVLA 3 8 \"klama\")) (tanru_unit_2 134 " &
    "(ZEI 10 11 \"i\" 12 15 \"zei\" 16 21 \"broda\"))) (tail_terms)))\n"
    ## lo linji pe lo jgena pe `mi klama .i zei broda` .i le jgena cu du pa jufra
  EXAMPLES_LIVE: seq[tuple[pieces: seq[string], changes: seq[Change]]] = @[
    (
      pieces: @["mi klama .i do ", "cad", "zu"],
      changes: @[
        (28, 0, LINE_MI_KLAMA, LINE_DO),
        (141, 10, "", LINE_DO),
        (141, 10, "", LINE_DO),
        (
          141, 10, "(text_1 0 (I 10 11 \"i\") (sentence 4 (sumti_6 80 " &
            "(KOhA 12 14 \"do\")) (bridi_tail_3 50 (tanru_unit_2 130 " &
            "(BRIVLA 15 20 \"cadzu\")) (tail_terms))))\n",
          "",
        ),
      ],
    # lo jufra cu se benji ca lo nu le bavla'i jufra cu cfari
    ),  # lo se katna valsi cu denpa lo sinxa poi fanmo ke'a
    (
      pieces: @["mi klama .i do ", "si si si "],
      changes: @[
        (28, 0, LINE_MI_KLAMA, LINE_DO),
        (28, 0, "", "(sumti_6 0 (KOhA 0 2 \"mi\"))\n" & LINE_ERASED),
        (28, 0, "(sumti_6 0 (KOhA 0 2 \"mi\"))\n" & LINE_ERASED, ""),
      ],
    # lo cimoi cmavo po'u zo si cu vimcu zo klama .i se ki'u bo la'o gy. NIF .gy. cu se katna bu'u
    #   le jufra poi pu vasru zo klama
    ),  # `CLL 19.13`
    (
      pieces: @["mi 1987 klama .i ", "su ko "],
      changes: @[
        (
          28, 0, "(sentence 0 (sumti_6 80 (KOhA 0 2 \"mi\")) " &
            "(rivbi Stream Letter 3 7 \"1987\") (bridi_tail_3 50 " &
            "(tanru_unit_2 130 (BRIVLA 8 13 \"klama\")) (tail_terms)))\n",
          "(text_1 0 (I 15 16 \"i\"))\n",
        ),
        (
          175, 15, "(text_1 0 (I 15 16 \"i\"))\n(rivbi SU 17 19 \"su\")\n",
          "(sumti_6 0 (KOhA 20 22 \"ko\"))\n",
        ),
        (222, 20, "(sumti_6 0 (KOhA 20 22 \"ko\"))\n", ""),
      ],
    # zo su cu fanmo lo se ciska poi lidne zo su .i le se ciska cu stali ta'i lo nu pu se tcidu .i
    #   se ki'u bo la'o gy. NIF .gy. cu se katna bu'u no stuzi
    ),  # la'o gy. Architect .gy. cu jdice di'u bu'u `#859`
    (
      pieces: @["lu mi klama .i do ", "su ko "],
      changes: @[
        (
          28, 0, "(sumti_6 0 (LU 0 2 \"lu\") (sentence 0 (sumti_6 80 (KOhA 3 5 \"mi\")) " &
            "(bridi_tail_3 50 (tanru_unit_2 130 (BRIVLA 6 11 \"klama\")) " &
            "(tail_terms))))\n",
          "(text_1 0 (I 13 14 \"i\") (sumti_6 4 (KOhA 15 17 \"do\")))\n",
        ),
        (
          28, 0, "(sumti_6 0 (LU 0 2 \"lu\") (paragraph 0 (sentence 11 (sumti_6 80 " &
            "(KOhA 3 5 \"mi\")) (bridi_tail_3 50 (tanru_unit_2 130 " &
            "(BRIVLA 6 11 \"klama\")) (tail_terms))) (I 13 14 \"i\") " &
            "(sumti_6 20 (KOhA 15 17 \"do\"))))\n(rivbi SU 18 20 \"su\")\n",
          "(sumti_6 0 (KOhA 21 23 \"ko\"))\n",
        ),
        (250, 21, "(sumti_6 0 (KOhA 21 23 \"ko\"))\n", ""),
      ],
    # zo lu cu denpa lo nu zo su cu fanmo le se ciska pe zo lu .i zo lu cu se fanmo bu'u zo su ta'i
    #   lo nu se fanmo bu'u lo fanmo be le se ciska
    ),  # la'o gy. NIF .gy. cu se katna bu'u zo lu
    (
      pieces: @["lo'u mi su do ", "le'u .i ko "],
      changes: @[
        (
          28, 0,
          "(rivbi Quotation 0 4 \"lohu\")\n(sumti_6 0 (KOhA 5 7 \"mi\"))\n" &
            "(rivbi SU 8 10 \"su\")\n",
          "(sumti_6 0 (KOhA 11 13 \"do\"))\n",
        ),
        (
          28, 0,
          "(sumti_6 0 (LOhU 0 4 \"lohu\" 5 7 \"mi\" 8 10 \"su\" 11 13 \"do\" 14 18 \"lehu\"))\n",
          "(text_1 0 (I 20 21 \"i\") (sumti_6 4 (KOhA 22 24 \"ko\")))\n",
        ),
        (101, 20, "(text_1 0 (I 20 21 \"i\") (sumti_6 4 (KOhA 22 24 \"ko\")))\n", ""),
      ],
    # zo lo'u cu denpa .i se ki'u bo zo su poi se lidne zo lo'u cu fanmo lo se ciska .i zo le'u cu
    #   sitna zo su ca lo nu zo le'u cu klama
    ),  # `CLL 19.9`
    (
      pieces: @["mi cusku lu do klama .i mi cadzu ", "li'u .i ko "],
      changes: @[
        (
          28, 0, "(sentence 0 (sumti_6 80 (KOhA 0 2 \"mi\")) (bridi_tail_3 50 " &
            "(tanru_unit_2 130 (BRIVLA 3 8 \"cusku\")) (sumti_6 71 (LU 9 11 \"lu\") " &
            "(sentence 0 (sumti_6 80 (KOhA 12 14 \"do\")) (bridi_tail_3 50 " &
            "(tanru_unit_2 130 (BRIVLA 15 20 \"klama\")) (tail_terms))))))\n",
          "(text_1 0 (I 22 23 \"i\") (sentence 4 (sumti_6 80 (KOhA 24 26 \"mi\")) " &
            "(bridi_tail_3 50 (tanru_unit_2 130 (BRIVLA 27 32 \"cadzu\")) " &
            "(tail_terms))))\n",
        ),
        (
          28, 0, "(sentence 0 (sumti_6 80 (KOhA 0 2 \"mi\")) (bridi_tail_3 50 " &
            "(tanru_unit_2 130 (BRIVLA 3 8 \"cusku\")) (sumti_6 71 (LU 9 11 \"lu\") " &
            "(paragraph 0 (sentence 11 (sumti_6 80 (KOhA 12 14 \"do\")) " &
            "(bridi_tail_3 50 (tanru_unit_2 130 (BRIVLA 15 20 \"klama\")) " &
            "(tail_terms))) (I 22 23 \"i\") " &
            "(sentence 11 (sumti_6 80 (KOhA 24 26 \"mi\")) (bridi_tail_3 50 " &
            "(tanru_unit_2 130 (BRIVLA 27 32 \"cadzu\")) (tail_terms)))) " &
            "(LIhU 33 37 \"lihu\"))))\n",
          "(text_1 0 (I 39 40 \"i\") (sumti_6 4 (KOhA 41 43 \"ko\")))\n",
        ),
        (440, 39, "(text_1 0 (I 39 40 \"i\") (sumti_6 4 (KOhA 41 43 \"ko\")))\n", ""),
      ],
    # zo lu cu denpa .i se ki'u bo lo jufra poi se lidne zo lu cu se benji
    ),  # zo li'u cu rapli tcidu le jufra ta'i lo nu sitna
    (
      pieces: @["mi su", "'i do "],
      changes: @[
        (28, 0, "", "(sumti_6 0 (KOhA 0 2 \"mi\"))\n"),
        (28, 0, "", LINE_SUHI),
        (28, 0, LINE_SUHI, ""),
      ],
    # zo su poi lo spisa cu katna ke'a cu du zo su'i ca lo nu lo bavla'i spisa cu fanmo le valsi
    ),  # le valsi cu vimcu no da
    (
      pieces: @["mi klama .i ", "zei broda "],
      changes: @[
        (28, 0, LINE_MI_KLAMA, "(text_1 0 (I 10 11 \"i\"))\n"),
        (28, 0, "", LINE_ZEI),
        (28, 0, LINE_ZEI, ""),
      ],
    # zo zei cu rinka lo nu zo .i cu jorne lo valsi poi se lidne zo zei .i se ki'u bo zo .i cu krasi
    #   no jufra .i la'o gy. NIF .gy. cu se katna
    ),  # `CLL 4.6`
  ]
    ## lo spisa be lo se ciska .i lo cenba pe ro spisa ne'i la'o gy. NIF .gy. .i ji'a lo cenba pe lo
    ##   fanmo .i ro stuzi pe le cenba cu se cipra



#[ lo tcidu ]#

func spansNif(nif: string): seq[tuple[start, finish: int]] =
  ## jarco lo stuzi poi ro valsi pe ro gerna valsi pe le datnyvei cu krasi bu'u ke'a ku'o .e lo
  ##   stuzi poi se lidne le valsi ku'o ta'i le porsi pe le datnyvei
  func addSpans(node: NodeNif, spans: var seq[tuple[start, finish: int]]) =
    ## jmina lo stuzi pe ro valsi pe ro gerna valsi poi cnita le jgena ku'o `spans` .i lo minde cu
    ##   vasru no valsi
    if node.kind != KindNif.Compound or node.text.startsWith("."): return
    if node.children.len > 0 and node.children[^1].kind == KindNif.Literal:
      var k = 0
      while node.children[k].kind == KindNif.Identifier: inc k
      for m in countup(k, node.children.high, 3):
        spans.add (node.children[m].number, node.children[m + 1].number)
      return
    for child in node.children: child.addSpans(spans)

  for node in nif.readModule: node.addSpans(result)


func isOpener(occurrence: Occurrence): bool =
  ## jdice lo du'u le valsi cu cmavo zoi gy. I .gy. .a zoi gy. NIhO .gy. .i ro le cmavo cu krasi lo
  ##   jufra .a lo jufra girzu
  occurrence.reading.is_word and occurrence.reading.selmaho.isSome and
    occurrence.reading.selmaho.get in {Selmaho.I, Selmaho.Niho}


func countCut(piece: string, sentences: openArray[string]): int =
  ## kancu lo jufra poi le porsi be lo valsi cu tcidu ke'a po'o .i le spisa cu jalge lo nu jmina ro
  ##   le jufra .i ro le jufra poi le porsi cu tcidu ke'a po'o cu vasru pa cmavo be zoi gy. I .gy.
  ##   .a zoi gy. NIhO .gy. be'o noi pamoi valsi be le jufra .i ku'i le pamoi jufra cu ka'e vasru no
  ##   le cmavo .i va'o lo nu la'e di'u na jetnu kei jarco li ni'u pa
  if sentences.join != piece: return -1
  for k in 0 ..< sentences.len:
    let reading = sentences[k].readStream
    # pa jufra po'o cu katna lo valsi
    if not reading.is_read or reading.occurrences.len == 0: continue
    for n in 0 ..< reading.occurrences.len:
      if reading.occurrences[n].isOpener != (n == 0 and (k > 0 or reading.occurrences[0].isOpener)):
        return -1
    inc result


func readLive(
  text: string, cuts: openArray[int], is_growing = false, is_sentences = false
): ReadingLive =
  ## tcidu ro spisa be le se ciska ta'i lo porsi .i le se ciska cu se katna bu'u ro stuzi pe `cuts`
  ##   .i ralte la'o gy. NIF .gy. poi stali ba ro cenba
  ##   .i va'o lo nu `is_growing` cu jetnu kei cipra lo du'u la'o gy. NIF .gy. .e le rebla pe ro
  ##   cenba poi lidne lo fanmo cu mapti le se ciska poi ca zvati .i va'o lo nu `is_sentences` cu
  ##   jetnu kei tcidu ro jufra pe ro spisa ta'i lo porsi ta'i lo nu le samtci cu tcidu ne'i lo
  ##   cilta pe le papri .i ji'a jmina lo cenba pe le jufra fo pa cenba pe le spisa
  var
    reader = initReaderLive()
    last = 0
  result = ReadingLive(nif: HEADER, is_held: true, is_grown: true, is_tied: true, is_cut: true)
  template apply(change: ChangeNif) =
    ## katna la'o gy. NIF .gy. poi se ralte ku'o ta'i lo nu le cenba cu jarco .i ba bo jmina lo
    ##   jgena pe le cenba .i ji'a ralte le cenba .i cipra lo du'u ro valsi pe la'o gy. NIF .gy. poi
    ##   le cenba cu ralte ke'a cu fanmo bu'u lo stuzi poi na se lidne le krasi be le cenba kei .e
    ##   lo du'u ro valsi poi le cenba cu jarco ke'a cu krasi bu'u le krasi be le cenba
    result.is_held = result.is_held and change.at <= result.nif.len
    result.nif.setLen(min(change.at, result.nif.len))
    result.is_tied = result.is_tied and result.nif.spansNif.allIt(it.finish <= change.start) and
      (HEADER & change.text & change.tail).spansNif.allIt(it.start >= change.start)
    result.nif.add change.text
    result.is_held = result.is_held and result.nif == reader.toNif
    result.changes.add (change.at, change.start, change.text, change.tail)
  for k in 0 .. cuts.len:
    let at = (if k < cuts.len: cuts[k] else: text.len)
    var changes: seq[ChangeNif]
    if is_sentences:
      let
        sentences = text[last ..< at].toSentences
        count = text[last ..< at].countCut(sentences)
      result.is_cut = result.is_cut and count >= 0
      result.count_sentences += max(count, 0)
      for n in 0 ..< sentences.len: changes.add reader.push(sentences[n])
    else: changes.add reader.push(text[last ..< at])
    let change = (if is_sentences: changes.combine(reader.toNif) else: changes[0])
    apply(change)
    last = at
    var ending = at  # le se ciska poi ca zvati gi'e fanmo bu'u le romoi sinxa poi jbini lo valsi
    while ending > 0 and text[ending - 1] notin MARKS_BOUNDARY: dec ending
    if is_growing and ending > 0:
      let grown = readTextParts(text[0 ..< ending], is_live = true).reading.toNifParts
      result.is_grown = result.is_grown and result.nif & change.tail == grown
  let change = reader.finish  # le morna fancu cu tcidu le se fancu be vo'a ca ro nu se pilno
  apply(change)
  result.count_read = reader.countRead


func cutsWords(text: string): seq[int] =
  ## jarco lo stuzi pe ro kunti lerfu poi lidne lo valsi .i se ki'u bo ro se ciska valsi cu du pa
  ##   spisa
  for k in 1 ..< text.len:
    if text[k] == ' ': result.add k


func cutsRandom(text: string, rng: var Rand, most: int): seq[int] =
  ## jarco lo cunso stuzi .i lo ni re lamji stuzi cu darno kei cu na zmadu `most` .i se ki'u bo lo
  ##   spisa cu katna lo valsi
  var at = rng.rand(1 .. most)
  while at < text.len:
    result.add at
    at += rng.rand(1 .. most)


func readPool(): seq[tuple[key, text: string, whole: ReadingParts]] =
  ## tcidu ro se ciska pe le se ciska liste ta'i lo pagbu be le se ciska pa roi .i le flalu poi
  ##   tcidu le se ciska cu pilno le jalge
  for (key, text) in textsCorpora(): result.add (key, text, readTextParts(text))


func textCost(count: int): string =
  ## jmina lo pamoi jufra pe la'o gy. Tatoeba .gy. fo pa se ciska .i `count` cu klani le jufra .i ro
  ##   le jufra cu stali lo ka jufra
  var texts: seq[string]
  # da'i lo nu katna cu fukpi ro cmima be le liste
  for k in 0 ..< count: texts.add SENTENCES_TATOEBA[k].text
  texts.join(" .i ")



suite "Internal: Live text":
  let pool = readPool()

  test "Text read piece by piece gives NIF of its parts read whole, over corpora":
    var
      rng = initRand(SEED)
      count = 0
    for k, (key, text, whole) in pool:
      if k mod 2 == 1: continue  # ro remoi se ciska ki'u lo jdima be le cipra
      checkpoint key & ": " & text
      let live = text.readLive(text.cutsRandom(rng, PIECE_CORPORA_MOST))
      check live.nif == whole.reading.toNifParts  # le flalu pe le stedu be `live.nim`
      # lo sinxa be lo stuzi cu katna ne'i la'o gy. NIF .gy. poi se ralte
      check live.is_held  # le stedu be `live.nim`
      check live.is_tied  # `ChangeNif` pe `live.nim` .i lo stuzi poi le cenba cu krasi bu'u ke'a
      inc count
    # lo bandu cu ralte lo se ciska pe le se ciska liste
    check count >= COUNT_CORPORA_LEAST  # `IX.3`


  test "Text built of words that reach back gives NIF of its parts read whole, and grows":
    var rng = initRand(SEED)
    for k in 0 ..< COUNT_BUILT:
      let
        text = rng.textBuilt
        cuts = text.cutsRandom(rng, PIECE_MOST)
      checkpoint text & " cut at " & $cuts
      let live = text.readLive(cuts, is_growing = true)
      check live.nif == readTextParts(text).reading.toNifParts  # le flalu pe le stedu be `live.nim`
      # lo sinxa be lo stuzi cu katna ne'i la'o gy. NIF .gy. poi se ralte
      check live.is_held  # le stedu be `live.nim`
      # le rebla cu zenba ta'i lo nu le se ciska poi ca zvati cu jarco le rebla
      check live.is_grown  # le stedu be `live.nim`
      check live.is_tied  # `ChangeNif` pe `live.nim` .i lo stuzi poi le cenba cu krasi bu'u ke'a
      # ro valsi cu zvati pa pezli
      check readTextParts(text).reading.isCovering(text)  # le stedu be `nif.nim`


  test "Piece read sentence by sentence gives NIF that piece read whole gives, over corpora":
    var
      rng = initRand(SEED)
      count = 0
    for k, (key, text, whole) in pool:
      # ro vomoi se ciska .i le flalu poi tcidu ro remoi se ciska cu na tcidu le se ciska
      if k mod 4 != 1: continue
      checkpoint key & ": " & text
      let live = text.readLive(text.cutsRandom(rng, PIECE_CORPORA_MOST), is_sentences = true)
      # le nu katna cu galfi no pagbu be la'o gy. NIF .gy.
      check live.nif == whole.reading.toNifParts  # `toSentences` pe `live.nim`
      # la'o gy. NIF .gy. poi lidne le mleca traji stuzi cu stali
      check live.is_held  # `combine` pe `live.nim`
      # le jalge cu jorne le se ciska le mleca traji stuzi
      check live.is_tied  # `combine` pe `live.nim`
      # pa cmavo be zoi gy. I .gy. .a zoi gy. NIhO .gy. be'o po'o cu krasi lo jufra
      check live.is_cut  # `toSentences` pe `live.nim`
      inc count
    # lo bandu cu ralte lo se ciska pe le se ciska liste
    check count >= COUNT_SENTENCES_CORPORA_LEAST  # `IX.3`


  test "Text built, read sentence by sentence, gives NIF of its parts read whole, and grows":
    var
      rng = initRand(SEED)
      count = 0
    for k in 0 ..< COUNT_BUILT:
      let
        text = rng.textBuilt
        # lo spisa cu vasru so'i valsi .i se ki'u bo lo spisa cu vasru lo jufra
        cuts = text.cutsRandom(rng, PIECE_MOST * 4)
      checkpoint text & " cut at " & $cuts
      let live = text.readLive(cuts, is_growing = true, is_sentences = true)
      # le nu katna cu galfi no pagbu be la'o gy. NIF .gy.
      check live.nif == readTextParts(text).reading.toNifParts  # `toSentences`
      # la'o gy. NIF .gy. poi lidne le mleca traji stuzi cu stali
      check live.is_held  # `combine` pe `live.nim`
      # le rebla pe le romoi jufra cu du le rebla pe le spisa
      check live.is_grown  # `combine` pe `live.nim`
      # le jalge cu jorne le se ciska le mleca traji stuzi
      check live.is_tied  # `combine` pe `live.nim`
      # pa cmavo be zoi gy. I .gy. .a zoi gy. NIhO .gy. be'o po'o cu krasi lo jufra
      check live.is_cut  # `toSentences` pe `live.nim`
      count += live.count_sentences
    # lo bandu cu ralte lo jufra poi le porsi be lo valsi cu tcidu ke'a po'o
    check count >= COUNT_SENTENCES_LEAST  # `IX.3`


  test "Lo'u whose le'u erasure erases waits for none, so text after it reads as stream reads it":
    for text in TEXTS_LOHU_ERASED:
      checkpoint text
      let live = text.readLive(text.cutsWords, is_growing = true)
      check live.nif == readTextParts(text).reading.toNifParts  # le flalu pe le stedu be `live.nim`
      # le porsi be lo valsi cu tcidu zo le'u poi lo nu vimcu cu vimcu ke'a
      check live.is_grown  # le stedu be `prose.nim` .i `CLL 19.9`


  test "Lo'u that zo quotes in stream waits for none, though rules refuse zo":
    for text in TEXTS_LOHU_QUOTED:
      checkpoint text
      let live = text.readLive(text.cutsWords, is_growing = true)
      check live.nif == readTextParts(text).reading.toNifParts  # le flalu pe le stedu be `live.nim`
      # le porsi be lo valsi cu tcidu zo lo'u poi zo zo cu sitna ke'a
      check live.is_grown  # le stedu be `prose.nim` .i `CLL 19.10`


  test "Lo'u that rules hold in quotation waits, where stream reads words it quotes":
    for text in TEXTS_LOHU_HELD:
      checkpoint text
      let live = text.readLive(text.cutsWords, is_growing = true)
      check live.nif == readTextParts(text).reading.toNifParts  # le flalu pe le stedu be `live.nim`
      # le porsi be lo valsi cu tcidu lo valsi poi zo lo'u cu sitna ke'a
      check live.is_grown  # le stedu be `prose.nim` .i `CLL 19.9`


  test "Sa reads again where word after it changes, past words stream or rules refuse":
    for text in TEXTS_SA_PARTED:
      checkpoint text
      let live = text.readLive(text.cutsWords, is_growing = true)
      check live.nif == readTextParts(text).reading.toNifParts  # le flalu pe le stedu be `live.nim`
      # le rebla cu zenba ta'i lo nu le se ciska poi ca zvati cu jarco le rebla
      check live.is_grown  # le stedu be `live.nim` .i `CLL 19.13`


  test "Zei that rules refuse reads again with quotation after it, once they refuse quotation":
    for text in TEXTS_ZEI_REFUSED:
      checkpoint text
      let live = text.readLive(text.cutsWords, is_growing = true)
      check live.nif == readTextParts(text).reading.toNifParts  # le flalu pe le stedu be `live.nim`
      # le rebla cu zenba ta'i lo nu le se ciska poi ca zvati cu jarco le rebla
      check live.is_grown  # le stedu be `live.nim` .i `CLL 19.16`


  test "Closer reads back past text read again, where opener there opens no more":
    for (text, cuts) in CUTS_CLOSER:
      checkpoint text & " cut at " & $cuts
      let live = text.readLive(cuts, is_growing = true)
      check live.nif == readTextParts(text).reading.toNifParts  # le flalu pe le stedu be `live.nim`
      # lo fanmo valsi be lo krasi valsi poi denpa
      check live.is_grown  # le stedu be `live.nim` .i `CLL 17.4`


  test "Su ends text before it, which stays, save where quotation quotes it once closed":
    for text in TEXTS_SU:
      checkpoint text
      let live = text.readLive(text.cutsWords, is_growing = true)
      check live.nif == readTextParts(text).reading.toNifParts  # le flalu pe le stedu be `live.nim`
      # zo su .e lo nu sitna poi sitna zo su
      check live.is_grown  # le stedu be `live.nim` .i `CLL 19.13`


  test "Fa'o goes out once, and end reads it again from span of its node":
    for (text, cuts) in CUTS_ENDED:
      checkpoint text & " cut at " & $cuts
      let live = text.readLive(cuts, is_growing = true)
      check live.nif == readTextParts(text).reading.toNifParts  # le flalu pe le stedu be `live.nim`
      # zo fa'o poi fanmo le se ciska
      check live.is_grown  # le stedu be `live.nim` .i `CLL 19.15`


  test "Parts lose nothing of tree: assembleText builds tree grammar gives, over corpora":
    var count = 0
    for (key, text, whole) in pool:
      template reading: untyped = whole.reading
        ## lo drata cmene be lo jalge be lo nu tcidu lo pagbu .i `let` da'i fukpi le jalge
      let is_read = reading.units.allIt(it.is_read) and reading.tree.children.len > 1
      if not is_read: continue
      let
        terminals = reading.units.mapIt(it.terminal)
        strict = terminals.readGrammar
      if not strict.is_read: continue
      checkpoint key & ": " & text
      let tree = terminals.assembleText(reading.tree.children)
      check tree.isSome  # le stedu be `grammar.nim` .i lo pagbu cu zbasu lo tricu be le se ciska
      if tree.isNone: continue
      # no pagbu be le tricu cu se cirko
      check tree.get.toNif(reading) == strict.tree.toNif(reading)  # le stedu be `live.nim`
      inc count
    # lo bandu cu ralte lo se ciska poi vasru za'u pa pagbu be le se ciska
    check count >= COUNT_PARTED_LEAST  # `IX.3`


  test "Bytes read grow with length of text, word by word":
    let
      text = textCost(SENTENCES_COST)
      twice = text & " .i " & text
      once = text.readLive(text.cutsWords)
      both = twice.readLive(twice.cutsWords)
    check once.nif == readTextParts(text).reading.toNifParts  # le flalu pe le stedu be `live.nim`
    # le flalu pe lo jdima
    check float(once.count_read) <= COST_MOST * float(text.len)  # le stedu be `live.nim`
    # le jdima cu zenba ta'i lo ni le se ciska cu clani .i le jdima na zenba ta'i lo pilji be le ni
    #   clani bei le ni clani
    check float(both.count_read) <= COST_TWICE_MOST * float(once.count_read)  # `live.nim`


  test "Worked examples give change of each piece, then of end, byte for byte":
    for (pieces, changes) in EXAMPLES_LIVE:
      let text = pieces.join
      checkpoint text
      var cuts: seq[int]
      for k in 0 ..< pieces.high: cuts.add (if k == 0: 0 else: cuts[^1]) + pieces[k].len
      let live = text.readLive(cuts)
      # lo sinxa be lo stuzi .e le rebla .e lo nu galfi lo pu valsi
      check live.changes == changes  # le stedu be `live.nim`
      check live.nif == readTextParts(text).reading.toNifParts  # le flalu pe le stedu be `live.nim`
