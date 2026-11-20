## cipra lo du'u lo tcidu be lo mivyselci'a cu mapti lo flalu pe vo'a to `#859` toi
##   .i ca lo fanmo lo selci'a poi ro spisa be ke'a cu se tcidu ta'i lo porsi cu jarco `NIF` pe lo
##       pagbu be le selci'a poi se tcidu ta'i lo mulno to `toNifParts` pe `readTextParts` toi
##   .i ro stuzi pe le re selci'a be fi `NIF` cu mintu va'o ro nu le spisa cu katna le selci'a
##
## ni'o lo spisa cu jalge lo cunso nu katna poi seljdi lo tsiju
##   .i le nu katna cu ka'e zvati ne'i lo valsi
##   .i le cipra cu katna ro remoi se ciska pe le selci'aste ge'u .e lo selci'a poi selzba fi lo
##       valsi poi galfi lo pu valsi to `texts_built.nim` toi
##   .i ki'u bo le selci'aste cu vasru so'u le valsi
##   .i ne'i le flalu pe lo jdima ro selci'avla cu spisa
##
## ni'o ro cenba cu katna `NIF` ne'i le se ralte po'o
##   .i `NIF` poi stali ba le cenba cu mintu `NIF` poi le tcidu cu ralte ke'a
##   .i pu lo fanmo `NIF` .e le rebla pe ro cenba cu mintu `NIF` pe lo pagbu be lo selci'a poi ca
##       zvati gi'e fanmo bu'u lo romoi sinxa poi jbini lo valsi be'o poi se tcidu ta'i pa
##       mulji'eselci'a
##   .i se ki'u bo le tricu cu zenba ta'i lo nu le selci'a poi ca zvati cu jarco le tricu
##
## ni'o ro cenba cu jorne le selci'a
##   .i ro valsi pe `NIF` poi le cenba cu ralte ke'a fanmo bu'u lo stuzi poi na se lidne le krasi be
##       le cenba
##   .i ro valsi pe lo jgena poi le cenba cu jarco ke'a krasi bu'u lo stuzi poi na lidne le krasi be
##       le cenba
##
## ni'o le pagbu be le selci'a cu cirko no pagbu be le tricu
##   .i `assembleText` zbasu lo tricu poi `readGrammar` jarco ke'a ku'o fi le pagbu
##
## ni'o lo spisa poi selka'a fi lo jufra to `toSentences` toi zi'e poi ro jufra pe ke'a se tcidu
##     ta'i lo porsi cu jarco ne'i pa cenba to `combine` toi lo selja'o be lo spisa poi se tcidu
##     ta'i lo mulno
##   .i le selja'o cu vasru `NIF` pe lo pagbu be le selci'a ca lo fanmo
##   .i ji'a `NIF` selra'e gi'e zenba
##   .i ji'a le cenba cu jorne le selci'a
##
## ni'o le spisa cu jalge lo nu jmina ro le jufra
##   .i ro jufra cu vasru pa cmavo be zoi gy. I .gy. .a zoi gy. NIhO .gy. be'o noi pamoi valsi be le
##       jufra
##
## ni'o jdima fa lo nu lo stuzi poi se tcidu ca ro nu tcidu cu zenba ca lo nu le selci'a cu zmadu lo
##     ka clani
##   .i va'o lo nu ro valsi pe lo seljonju'a pe `Tatoeba` spisa kei lo stuzi poi se tcidu cu na
##       zmadu lo pilji be `COST_MOST` bei lo stuzi pe le jufra
##   .i va'o lo nu le selci'a cu clani re roi kei lo stuzi poi se tcidu cu du lo pilji be li 2 bei
##       lo stuzi poi pu se tcidu
##
## ni'o lo mupli cu jarco lo cenba pe ro spisa
##   .i ro stuzi pe le cenba cu se cipra
##   .i le mupli cu cipra lo nu lo jufra cu selbe'i kei .e lo nu lo valsi cu selka'a kei .e lo nu zo
##       si katna `NIF` kei .e lo nu zo su fanmo lo selci'a gi'e katna no da gi'a fanmo zo lu poi
##       lidne zo su kei .e lo nu lo famvla cu raptcidu lo nu sitna kei .e lo nu zo le'u sitna zo su
##       kei .e lo nu zo zei jorne zo .i

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[options, random, sequtils, strutils, unittest]

import ../../src/ricysoho/[grammar, live, nif, prose, selmaho, stream]
import ../sample_tatoeba/sentences
import ./[corpora, reader_nif, texts_built]


type
  Change = tuple[at, start: int, text, tail: string]
    ## lo cenba poi pa spisa cu jarco ke'a ne'i `NIF`

  ReadingLive = object  ## lo jalge be lo nu tcidu ro spisa be lo selci'a ta'i lo porsi
    nif: string  ## `NIF` poi selra'e ca lo fanmo gi'e selga'i ro cenba
    changes: seq[Change]  ## lo cenba pe ro spisa ge'u .e ba bo lo cenba pe lo fanmo
    is_held: bool
      ## lo du'u ro cenba cu katna `NIF` ne'i le selra'e gi'e se lidne lo nu le tcidu cu ralte le
      ##     selra'e
    is_grown: bool
      ## lo du'u pu lo fanmo `NIF` .e le rebla pe ro cenba cu mintu `NIF` pe lo pagbu be le selci'a
      ##     poi ca zvati
    is_tied: bool
      ## lo du'u ro valsi pe `NIF` poi ro cenba cu ralte ke'a fanmo bu'u lo stuzi poi na se lidne le
      ##     krasi be le cenba
      ##   .i ji'a ro valsi pe lo jgena poi le cenba cu jarco ke'a krasi bu'u lo stuzi poi na lidne
      ##       le krasi be le cenba
    is_cut: bool
      ## lo du'u ro spisa cu jalge lo nu jmina lo jufra poi le spisa cu selka'a fi ke'a kei kei .e
      ##     lo du'u ro jufra poi le porsi be lo valsi cu tcidu ke'a po'o vasru pa cmavo be zoi gy.
      ##     I .gy. .a zoi gy. NIhO .gy. be'o noi pamoi valsi be le jufra
      ##   .i ji'a la'e di'u jetnu va'o lo nu ro spisa cu se tcidu ta'i lo mulno
    count_sentences: int
      ## lo klani be lo jufra poi le porsi be lo valsi cu tcidu ke'a po'o
      ##   .i `is_cut` cipra le jufra
    count_read: int  ## lo sumji be lo stuzi poi se tcidu ca ro nu tcidu


const
  SEED = 859  ## lo tsiju be lo cunso nu katna .e lo selci'a poi selzba
  COUNT_BUILT = 300  ## lo klani be lo selci'a poi selzba fi lo valsi poi galfi lo pu valsi
  DRAWS_NUMBERED = 40
    ## lo klani be lo cunso nu katna be ro selci'a pe le flalu pe denpa bu .e slaka bu poi zvati lo
    ##     jbini be lo lerfu
  PIECE_MOST = 6
    ## lo stuzi pe lo cunspi be lo selci'a poi selzba cu na zmadu le stodi
    ##   .i se ki'u bo lo spisa cu katna lo valsi
  PIECE_CORPORA_MOST = 96
    ## lo stuzi pe lo cunspi be lo selci'a pe le selci'aste cu na zmadu le stodi
    ##   .i lo selci'a poi vasru pa jufra cu selraptcidu ca ro spisa
    ##   .i se ki'u bo da'i va'o lo nu ro valsi cu spisa kei lo jdima cu du `100 s` ne'i lo cikryzba
    ##   .i le temci cu du lo pilji be li 14 bei lo temci be lo nu tcidu le selci'aste ta'i lo
    ##       mulno
  COUNT_CORPORA_LEAST = 950
    ## lo selci'a poi cmima le selci'aste gi'e se tcidu ta'i lo mivyselci'a
    ##   .i ro remoi se ciska pe le 1941 selci'a cu se tcidu
    ##   .i ki'u bo lo jdima be ro selci'a cu du lo pilji be li 3 bei lo jdima be lo nu tcidu le
    ##       selci'a ta'i lo mulno
    ##   .i lo jdima be lo nu tcidu lo xadba be le selci'aste cu jibni `12 s` ne'i lo cikryzba

  COUNT_PARTED_LEAST = 100
    ## lo selci'a poi cmima le selci'aste gi'e vasru za'u pa pagbu be ke'a
    ##   .i ro pagbu pe le selci'a cu se tcidu
  COUNT_SENTENCES_CORPORA_LEAST = 450
    ## lo selci'a poi cmima le selci'aste gi'e se tcidu ta'i lo nu tcidu ro jufra pe ke'a ta'i lo
    ##     porsi
    ##   .i ro vomoi se ciska pe le 1941 selci'a cu se tcidu
    ##   .i le flalu poi tcidu ro remoi se ciska cu na tcidu le selci'a
    ##   .i di'u selcu'a ki'u lo jdima be le cipra
  COUNT_SENTENCES_LEAST = 600
    ## lo jufra poi le porsi be lo valsi cu tcidu ke'a po'o zi'e noi le flalu pe le nu katna cu
    ##     cipra ke'a ne'i lo selci'a poi selzba
    ##   .i ca lo nu le flalu cu se jmina kei le jufra cu 677 mei
    ##   .i ki'u bo pa jufra po'o cu ka'e katna lo valsi gi'a krasi ne'i lo nu sitna
  SENTENCES_COST = 30
    ## lo seljonju'a pe `Tatoeba`
    ##   .i le flalu pe lo jdima cu tcidu le jufra gi'e ba bo tcidu lo selci'a poi vasru le jufra re
    ##       roi
  COST_MOST = 12.0
    ## lo zmaraifrinu be lo stuzi poi se tcidu bei lo stuzi pe le selci'a ca lo nu ro valsi cu spisa
    ##   .i ca lo nu le flalu cu se jmina kei le frinu cu du li 8 pi 2
    ##   .i ki'u bo ro spisa cu raptcidu lo jufra poi ca'o kalri
  COST_TWICE_MOST = 2.2
    ## lo zmaraifrinu be lo stuzi poi le selci'a poi re roi clani cu tcidu ke'a bei lo stuzi poi le
    ##     selci'a cu tcidu ke'a
  TEXTS_LOHU_ERASED = [
    # le cuncipra pe le flalu pe lo mivyselci'a cu facki le selci'a
    #   .i zo fa'o se tcidu ta'i lo valsi
    "lo'u cu le'u si mi .i fa'o zarci",
    "lo'u le'u si mi .i zoi gy. ko .gy.",  # zo zoi se tcidu ta'i lo valsi ne'i lo nu sitna
    "lo'u mi le'u sa le'u do .i fa'o ko",  # zo sa vimcu zo le'u
    # zo zo sitna lo pamoi cmavo po'u zo le'u
    #   .i lo remoi cu fanmo lo nu sitna
    "lo'u zo le'u le'u si mi .i fa'o ko",
  ]
    ## lo selci'a poi vasru zo lo'u poi lo nu vimcu cu vimcu zo le'u pe ke'a
    ##   .i le selci'a cu vasru lo valsi poi se lidne zo le'u zi'e poi le porsi be lo valsi cu tcidu
    ##       ke'a ta'i lo drata ne'i lo valsi poi zo lo'u sitna ke'a
    ##   .i le valsi cu du zo fa'o noi fanmo lo selci'a ku'o .a zo zoi noi sitna lo selci'a
    ##   .i le selci'a cu selfi'i
  TEXTS_LOHU_QUOTED = [
    # le cuncipra pe le flalu pe lo mivyselci'a cu facki le selci'a
    #   .i zo fa'o se tcidu ta'i lo valsi
    "zo lo'u si nai fa'o cu",
    "zo lo'u si .i zoi gy. ko .gy.",  # zo zoi se tcidu ta'i lo valsi ne'i lo nu sitna
    "zo lo'u si ui fa'o mi",  # lo cnivla poi se lidne zo si
  ]
    ## lo selci'a poi ne'i ke'a zo zo sitna pa zo lo'u goi ko'a ta'i lo nu le porsi be lo valsi cu
    ##     tcidu
    ##   .i zo si vimcu ko'a
    ##   .i se ki'u bo le javni cu to'e curmi zo zo
    ##   .i ko'a zvati pa pagbu poi vasru ko'a po'o
    ##   .i ku'i le porsi be lo valsi cu tcidu no valsi poi ko'a sitna ke'a
    ##   .i ba bo le selci'a cu vasru lo valsi poi le porsi be lo valsi cu tcidu ke'a ta'i lo drata
    ##       ne'i lo valsi poi zo lo'u sitna ke'a
    ##   .i le selci'a cu selfi'i
  TEXTS_LOHU_HELD = [
    # le cuncipra pe le flalu pe lo mivyselci'a cu facki le selci'a
    #   .i zo la'o se tcidu ta'i lo nu sitna
    "zo la'o si lo'u mi .i la'o",
    "zo la'o si lo'u do .i fa'o mi",  # zo fa'o se tcidu ta'i lo fanmo be le selci'a
    "zo zoi si lo'u mi .i zoi gy. ko .gy.",  # zo zoi se tcidu ta'i lo nu sitna
  ]
    ## lo selci'a poi ne'i ke'a zo zo sitna pa cmavo goi ko'a ta'i lo nu le porsi be lo valsi cu
    ##     tcidu
    ##   .i ko'a du zo la'o .a zo zoi
    ##   .i zo si vimcu ko'a
    ##   .i ba bo le javni cu tcidu ko'a ta'i lo nu sitna be ci valsi
    ##   .i zo lo'u cmima le ci valsi
    ##
    ## ni'o le porsi be lo valsi cu tcidu lo du'u zo lo'u sitna ro valsi poi se lidne zo lo'u
    ##   .i se ki'u bo lo bavla'i valsi cu se tcidu ne'i le valsi poi zo lo'u sitna ke'a
    ##   .i le selci'a cu selfi'i
  TEXTS_SA_PARTED = [
    # le cuncipra pe le flalu pe lo mivyselci'a cu facki le selci'a
    #   .i zo sa na selraptcidu
    "ni'o .i sa html zo .i si",
    "mi klama .i sa html zo .i si do",  # lo valsi poi se lidne zo si
    "ni'o .i sa html http zo .i si",  # re valsi poi le porsi be lo valsi cu to'e curmi ke'a
    # le cuncipra pe le flalu pe lo mivyselci'a cu facki le selci'a
    #   .i zo bu .e ba bo zo ba'e se to'e curmi
    "ui lo sa bu ba'e le si",
    "ui lo sa zei ba'e le si",  # zo zei .e ba bo zo ba'e se to'e curmi
  ]
    ## lo selci'a poi ne'i ke'a lo valsi poi se to'e curmi le porsi be lo valsi .a le javni cu jbini
    ##     zo sa .e lo valsi poi se lidne le se to'e curmi
    ##   .i le valsi cu dunda lo sinxa be zo sa to `CLL 19.13` toi
    ##   .i lo bavla'i valsi cu rinka lo nu le valsi cu se to'e curmi ji'a
    ##   .i se ki'u bo le sinxa cu cenba
    ##
    ## ni'o mupli fa lo nu zo si vimcu lo valsi poi zo zo sitna ke'a kei noi rinka lo nu zo zo se
    ##     to'e curmi
    ##   .i mupli fa ji'a lo nu zo ba'e tcita no valsi
    ##   .i le selci'a cu selfi'i
  TEXTS_ZEI_REFUSED = [
    # le cuncipra pe le flalu pe lo mivyselci'a cu facki le selci'a
    #   .i zo zei na selraptcidu
    "lo'u bu zei zoi lu nai ui si cu je",
    "lo'u bu zei la'o lu nai ui si cu je",  # zo la'o
    "lo'u bu zei zoi lu nai ui si klama do",  # zo klama
    "lo'u bu bu zei zoi lu nai ui si cu je",  # re zo bu
    "lo'u bu zei ui si zoi lu nai ui si cu je",  # lo nu vimcu poi jbini zo zei .e lo nu sitna
  ]
    ## lo selci'a poi ne'i ke'a le javni cu to'e curmi zo bu .e zo zei
    ##   .i lo nu sitna cu cfari ba zo zei ne'i lo valsi poi zo lo'u sitna ke'a
    ##   .i zo lo'u denpa ta'i lo kravla
    ##   .i zo si vimcu lo valsi poi le nu sitna cu sitna ke'a
    ##   .i se ki'u bo le javni cu to'e curmi le nu sitna ji'a
    ##   .i zo zei rinka lo nu zo bu jorne lo valsi poi se lidne zo zei to `CLL 19.16` toi
    ##   .i le selci'a cu selfi'i
  CUTS_CLOSER = [
    # le cuncipra pe le flalu pe lo mivyselci'a cu facki le selci'a
    (text: "to .i to toi to bu toi ba'e", cuts: @[1, 9, 18, 23, 24]),
    (text: "to mi .i to bu toi do", cuts: @[6, 12, 13, 19]),
    (text: "lu mi .i lu bu li'u do", cuts: @[5, 11, 14, 20]),
    (text: "tu'e mi .i tu'e bu tu'u do", cuts: @[6, 8, 9, 11, 14, 16, 18, 24]),
  ]
    ## lo selci'a poi ne'i ke'a pa kravla cu denpa
    ##   .i lo selci'a poi selraptcidu cu krasi bu'u lo stuzi poi se lidne le kravla
    ##   .i ba bo zo bu rinka lo nu lo kravla poi zvati le selci'a poi selraptcidu cu lervla
    ##   .i se ki'u bo lo famvla cu fanmo le pamoi krasi valsi noi lidne le selci'a poi selraptcidu
    ##   .i lo nu katna le selci'a ta'i la'e di'u cu selfa'i lo nu sisku lo cunso nu katna
    ##   .i le selci'a cu selfi'i
  TEXTS_SU = [
    # lo nu vimcu poi se lidne zo su klama no valsi poi lidne zo su to `CLL 19.13` toi
    "mi su si do", "mi su sa do",
    # zo lu selfa'o bu'u zo su
    #   .i se ki'u bo zo li'u poi se lidne zo su fanmo no da
    "lu mi klama .i do su ko li'u",
    "lo'u mi su do le'u .i ko",  # zo le'u sitna zo su
    # zo ba'e tcita le nu sitna
    "ba'e zoi su li'u bu si cu .i su fa'o",  # zo zoi sitna zo su
    # lo nu vimcu cu rinka lo nu zo su rapselsitna
    #   .i ki'u bo le nu sitna cu se tcidu ta'i lo mulno
    "zo su si si", "zo su si sa zarci",
    # zo le'u sitna zo su
    #   .i zo la'o se tcidu ta'i lo valsi
    "lo'u su la'o le le'u sa le klama",
  ]
    ## lo selci'a poi ne'i ke'a zo su fanmo lo selci'a poi lidne zo su ku'o .a lo selci'a poi ne'i
    ##     ke'a lo nu sitna cu sitna zo su ca lo nu le nu sitna cu selfa'o kei gi'e galfi lo valsi
    ##     poi lidne zo su
    ##   .i le cuncipra pe le flalu pe lo mivyselci'a cu facki le romoi vo selci'a
    ##   .i le romoi cu pu se tcidu ta'i lo srera ca lo nu zo su pu vimcu lo selci'a poi lidne zo su
  CUTS_ENDED = [
    (text: "tu'u si fa'o lo", cuts: toSeq(1 .. 14)),
    (text: "gy ku xyz ba'e gy si fa'o zo sa html", cuts: @[2, 6, 7, 12, 17, 22, 25, 31, 33, 34]),
    (
      text: "cu sa'a sa'a li'u si fa'o ni'o html .i",
      cuts: @[4, 5, 8, 13, 19, 23, 25, 26, 31, 36],
    ),
  ]
    ## lo selci'a poi ne'i ke'a lo valsi poi lo nu vimcu cu vimcu ke'a lidne zo fa'o
    ##   .i lo jgena pe zo fa'o pilno lo selku'e be le valsi
    ##   .i lo nu katna cu selfa'i le cuncipra pe le flalu pe lo mivyselci'a ca lo nu se jmina fa lo
    ##       pagbu pe ro valsi poi no pagbu pu vasru ke'a
  LINE_MI_KLAMA = "(sentence 0 (sumti_6 80 (KOhA 0 2 \"mi\")) (bridi_tail_3 50 " &
    "(tanru_unit_2 130 (BRIVLA 3 8 \"klama\")) (tail_terms)))\n"
    ## lo linji pe lo jgena pe `mi klama`
    ##   .i lo mupli cu selkra le linji
  LINE_DO = "(text_1 0 (I 10 11 \"i\") (sumti_6 4 (KOhA 12 14 \"do\")))\n"
    ## lo linji pe lo jgena pe `.i do` poi se lidne `mi klama` ca lo nu le jufra cu kalri
  LINE_ERASED = "(rivbi Erasure 3 8 \"klama\" 10 11 \"i\" 12 14 \"do\" 15 17 \"si\" " &
    "18 20 \"si\" 21 23 \"si\")\n"
    ## lo linji pe lo valsi poi ci zo si vimcu ke'a ne'i `mi klama .i do si si si`
    ##   .i ro zo si kansa le valsi ne'i pa pagbu
  LINE_SUHI = "(srera 3 paragraphs (nitcu A BAI BIhI BU BY CAhA CEhE COI CU CUhE DOI FA " &
    "FAhA FEhE FIhO GA GAhO GOI GOhA GUhA I JAI JOI KE KI KOhA LA LAU LAhE LE LI LOhU LU ME " &
    "MOhI NA NAhE NIhO NOI NU NUhA NUhI PA PEhE PU SE SEI SOI TAhE TEI TO VA VAU VEI VEhA " &
    "VIhA VUhO XI ZAhO ZEI ZEhA ZI ZO ZOI ZOhU BRIVLA) (sumti_6 0 (KOhA 0 2 \"mi\")) " &
    "(mex_operator 370 (VUhU 3 7 \"suhi\")) (sumti_6 0 (KOhA 8 10 \"do\")))\n"
    ## lo linji pe lo jgena pe `mi su'i do`
    ##   .i le gerna cu sisti ne'i le jgena bu'u zo su'i
  LINE_ZEI = "(sentence 0 (sumti_6 80 (KOhA 0 2 \"mi\")) (bridi_tail_3 50 " &
    "(selbri_3 130 (tanru_unit_2 134 (BRIVLA 3 8 \"klama\")) (tanru_unit_2 134 " &
    "(ZEI 10 11 \"i\" 12 15 \"zei\" 16 21 \"broda\"))) (tail_terms)))\n"
    ## lo linji pe lo jgena pe `mi klama .i zei broda`
    ##   .i le jgena cu du pa jufra
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
    # lo jufra cu selbe'i ca lo nu le bavla'i jufra cu cfari
    ),  # lo selka'avla cu denpa lo sinxa poi fanmo ke'a
    (
      pieces: @["mi klama .i do ", "si si si "],
      changes: @[
        (28, 0, LINE_MI_KLAMA, LINE_DO),
        (28, 0, "", "(sumti_6 0 (KOhA 0 2 \"mi\"))\n" & LINE_ERASED),
        (28, 0, "(sumti_6 0 (KOhA 0 2 \"mi\"))\n" & LINE_ERASED, ""),
      ],
    # lo cimoi cmavo po'u zo si vimcu zo klama
    #   .i se ki'u bo `NIF` selka'a bu'u le jufra poi pu vasru zo klama
    ),  # `CLL 19.13`
    (
      pieces: @["mi html klama .i ", "su ko "],
      changes: @[
        (
          28, 0, "(sentence 0 (sumti_6 80 (KOhA 0 2 \"mi\")) " &
            "(rivbi Stream Letter 3 7 \"html\") (bridi_tail_3 50 " &
            "(tanru_unit_2 130 (BRIVLA 8 13 \"klama\")) (tail_terms)))\n",
          "(text_1 0 (I 15 16 \"i\"))\n",
        ),
        (
          175, 15, "(text_1 0 (I 15 16 \"i\"))\n(rivbi SU 17 19 \"su\")\n",
          "(sumti_6 0 (KOhA 20 22 \"ko\"))\n",
        ),
        (222, 20, "(sumti_6 0 (KOhA 20 22 \"ko\"))\n", ""),
      ],
    # zo su fanmo lo selci'a poi lidne zo su
    #   .i le selci'a cu stali ta'i lo nu pu se tcidu
    #   .i se ki'u bo `NIF` selka'a bu'u no stuzi
    ),  # `Architect` jdice di'u bu'u `#859`
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
    # zo lu denpa lo nu zo su fanmo le selci'a pe zo lu
    #   .i zo lu selfa'o bu'u zo su ta'i lo nu selfa'o bu'u lo fanmo be le selci'a
    ),  # `NIF` selka'a bu'u zo lu
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
    # zo lo'u denpa
    #   .i se ki'u bo zo su poi se lidne zo lo'u fanmo lo selci'a
    #   .i zo le'u sitna zo su ca lo nu zo le'u klama
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
    # zo lu denpa
    #   .i se ki'u bo lo jufra poi se lidne zo lu selbe'i
    ),  # zo li'u raptcidu le jufra ta'i lo nu sitna
    (
      pieces: @["mi su", "'i do "],
      changes: @[
        (28, 0, "", "(sumti_6 0 (KOhA 0 2 \"mi\"))\n"),
        (28, 0, "", LINE_SUHI),
        (28, 0, LINE_SUHI, ""),
      ],
    # zo su poi lo spisa cu katna ke'a du zo su'i ca lo nu lo bavla'i spisa cu fanmo le valsi
    ),  # le valsi cu vimcu no da
    (
      pieces: @["mi klama .i ", "zei broda "],
      changes: @[
        (28, 0, LINE_MI_KLAMA, "(text_1 0 (I 10 11 \"i\"))\n"),
        (28, 0, "", LINE_ZEI),
        (28, 0, LINE_ZEI, ""),
      ],
    # zo zei rinka lo nu zo .i jorne lo valsi poi se lidne zo zei
    #   .i se ki'u bo zo .i krasi no jufra
    #   .i `NIF` selka'a
    ),  # `CLL 4.6`
  ]
    ## lo spisa be lo selci'a
    ##   .i lo cenba pe ro spisa ne'i `NIF`
    ##   .i ji'a lo cenba pe lo fanmo
    ##   .i ro stuzi pe le cenba cu se cipra



#[ ni'o ni'o ni'o lo tcidu ]#

func spansNif(nif: string): seq[tuple[start, finish: int]] =
  ## jarco lo stuzi poi ro valsi pe ro genvla pe le datnyvei cu krasi bu'u ke'a ku'o .e lo stuzi poi
  ##     se lidne le valsi ku'o ta'i le porsi pe le datnyvei
  func addSpans(node: NodeNif, spans: var seq[tuple[start, finish: int]]) =
    ## jmina lo stuzi pe ro valsi pe ro genvla poi cnita le jgena ku'o `spans`
    ##   .i lo minde cu vasru no valsi
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
  ## jdice lo du'u le valsi cu cmavo zoi gy. I .gy. .a zoi gy. NIhO .gy.
  ##   .i ro le cmavo cu krasi lo jufra .a lo ju'agri
  occurrence.reading.is_word and occurrence.reading.selmaho.isSome and
    occurrence.reading.selmaho.get in {Selmaho.I, Selmaho.Niho}


func countCut(piece: string, sentences: openArray[string]): int =
  ## kancu lo jufra poi le porsi be lo valsi cu tcidu ke'a po'o
  ##   .i le spisa cu jalge lo nu jmina ro le jufra
  ##   .i ro le jufra poi le porsi cu tcidu ke'a po'o vasru pa cmavo be zoi gy. I .gy. .a zoi gy.
  ##       NIhO .gy. be'o noi pamoi valsi be le jufra
  ##   .i ku'i le pamoi jufra cu ka'e vasru no le cmavo
  ##   .i va'o lo nu la'e di'u na jetnu kei jarco li ni'u 1
  if sentences.join != piece: return -1
  for k in 0 ..< sentences.len:
    let reading = sentences[k].readStream
    # pa jufra po'o cu katna lo valsi
    if not reading.is_read or reading.occurrences.len == 0: continue
    for n in 0 ..< reading.occurrences.len:
      if reading.occurrences[n].isOpener != (n == 0 and (k > 0 or reading.occurrences[0].isOpener)):
        return -1
    inc result


func isSettledTyped(typed: string, at: int): bool =
  ## jdice lo du'u xu kau le lerfu pe `at` cu fendi lo selci'avla ca lo nu `typed` po'o cu se ciska
  ##   .i lo kutle'u cu fendi
  ##   .i denpa bu poi zvati lo jbini be re lerfu pe `0` bi'o `9` cu na fendi
  ##   .i denpa bu poi romoi gi'e se lidne pa lerfu pe `0` bi'o `9` cu na fendi
  ##   .i ki'u bo lo lerfu poi ba se ciska cu jdice lo du'u xu kau ri sinxa zo pi
  ##   .i le fancu cu ciska le javni pe `D1 a` ji'a gi'e pilno no fancu pe `stream.nim` .e
  ##       `live.nim`
  let c = typed[at]
  if c in Whitespace: return true
  if c != '.': return false
  let is_after_digit = at > 0 and typed[at - 1] in Digits
  if at == typed.high: return not is_after_digit
  not (is_after_digit and typed[at + 1] in Digits)


func readLive(
  text: string, cuts: openArray[int], is_growing = false, is_sentences = false
): ReadingLive =
  ## tcidu ro spisa be le selci'a ta'i lo porsi
  ##   .i le selci'a cu selka'a bu'u ro stuzi pe `cuts`
  ##   .i ralte `NIF` poi stali ba ro cenba
  ##   .i va'o lo nu `is_growing` jetnu kei cipra lo du'u `NIF` .e le rebla pe ro cenba poi lidne lo
  ##       fanmo cu mapti le selci'a poi ca zvati
  ##   .i va'o lo nu `is_sentences` jetnu cu tcidu ro jufra pe ro spisa ta'i lo porsi ta'i lo nu le
  ##       samtci cu tcidu ne'i lo cilta pe le papri kei gi'e jmina lo cenba pe le jufra fo pa cenba
  ##       pe le spisa
  var
    reader = initReaderLive()
    last = 0
  result = ReadingLive(nif: HEADER, is_held: true, is_grown: true, is_tied: true, is_cut: true)
  template apply(change: ChangeNif) =
    ## katna `NIF` poi selra'e ku'o ta'i lo nu le cenba cu jarco
    ##   .i ba bo jmina lo jgena pe le cenba gi'e ralte le cenba
    ##   .i cipra lo du'u ro valsi pe `NIF` poi le cenba cu ralte ke'a fanmo bu'u lo stuzi poi na se
    ##       lidne le krasi be le cenba kei .e lo du'u ro valsi poi le cenba cu jarco ke'a krasi
    ##       bu'u le krasi be le cenba
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
    var ending = at  # le selci'a poi ca zvati gi'e fanmo bu'u le romoi sinxa poi jbini lo valsi
    # lo lerfu poi se lidne `at` cu na zvati ca ro nu se ciska
    #   .i ki'u bo `isSettledTyped` tcidu lo pagbu po'o poi se ciska
    let typed = text[0 ..< at]
    while ending > 0 and not typed.isSettledTyped(ending - 1): dec ending
    if is_growing and ending > 0:
      let grown = readTextParts(text[0 ..< ending], is_live = true).reading.toNifParts
      result.is_grown = result.is_grown and result.nif & change.tail == grown
  let change = reader.finish  # le monfancu cu tcidu le se fancu be vo'a ca ro nu selpli
  apply(change)
  result.count_read = reader.countRead


func cutsWords(text: string): seq[int] =
  ## jarco lo stuzi pe ro kutle'u poi lidne lo valsi
  ##   .i se ki'u bo ro selci'avla cu du pa spisa
  for k in 1 ..< text.len:
    if text[k] == ' ': result.add k


func cutsRandom(text: string, rng: var Rand, most: int): seq[int] =
  ## jarco lo cunstu
  ##   .i lo ni re lamstu cu darno cu na zmadu `most`
  ##   .i se ki'u bo lo spisa cu katna lo valsi
  var at = rng.rand(1 .. most)
  while at < text.len:
    result.add at
    at += rng.rand(1 .. most)


func readPool(): seq[tuple[key, text: string, whole: ReadingParts]] =
  ## tcidu ro selci'a pe le selci'aste ta'i lo pagbu be le selci'a pa roi
  ##   .i le flalu poi tcidu le selci'a cu pilno le jalge
  for (key, text) in textsCorpora(): result.add (key, text, readTextParts(text))


func textCost(count: int): string =
  ## jmina lo pamoi jufra pe `Tatoeba` fo pa selci'a
  ##   .i `count` klani le jufra
  ##   .i ro le jufra cu stali lo ka jufra
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
      # lo sinxa be lo stuzi cu katna ne'i `NIF` poi selra'e
      check live.is_held  # le stedu be `live.nim`
      # lo stuzi poi le cenba cu krasi bu'u ke'a
      check live.is_tied  # `ChangeNif` pe `live.nim`
      inc count
    # lo bandu cu ralte lo selci'a pe le selci'aste
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
      # lo sinxa be lo stuzi cu katna ne'i `NIF` poi selra'e
      check live.is_held  # le stedu be `live.nim`
      # le rebla cu zenba ta'i lo nu le selci'a poi ca zvati cu jarco le rebla
      check live.is_grown  # le stedu be `live.nim`
      # lo stuzi poi le cenba cu krasi bu'u ke'a
      check live.is_tied  # `ChangeNif` pe `live.nim`
      # ro valsi cu zvati pa pezli
      check readTextParts(text).reading.isCovering(text)  # le stedu be `nif.nim`


  test "Piece read sentence by sentence gives NIF that piece read whole gives, over corpora":
    var
      rng = initRand(SEED)
      count = 0
    for k, (key, text, whole) in pool:
      # ro vomoi se ciska
      #   .i le flalu poi tcidu ro remoi se ciska cu na tcidu le selci'a
      if k mod 4 != 1: continue
      checkpoint key & ": " & text
      let live = text.readLive(text.cutsRandom(rng, PIECE_CORPORA_MOST), is_sentences = true)
      # le nu katna cu galfi no pagbu be `NIF`
      check live.nif == whole.reading.toNifParts  # `toSentences` pe `live.nim`
      # `NIF` poi lidne le mecraistu cu stali
      check live.is_held  # `combine` pe `live.nim`
      # le jalge cu jorne le selci'a le mecraistu
      check live.is_tied  # `combine` pe `live.nim`
      # pa cmavo be zoi gy. I .gy. .a zoi gy. NIhO .gy. be'o po'o cu krasi lo jufra
      check live.is_cut  # `toSentences` pe `live.nim`
      inc count
    # lo bandu cu ralte lo selci'a pe le selci'aste
    check count >= COUNT_SENTENCES_CORPORA_LEAST  # `IX.3`


  test "Text built, read sentence by sentence, gives NIF of its parts read whole, and grows":
    var
      rng = initRand(SEED)
      count = 0
    for k in 0 ..< COUNT_BUILT:
      let
        text = rng.textBuilt
        # lo spisa cu vasru so'i valsi
        #   .i se ki'u bo lo spisa cu vasru lo jufra
        cuts = text.cutsRandom(rng, PIECE_MOST * 4)
      checkpoint text & " cut at " & $cuts
      let live = text.readLive(cuts, is_growing = true, is_sentences = true)
      # le nu katna cu galfi no pagbu be `NIF`
      check live.nif == readTextParts(text).reading.toNifParts  # `toSentences`
      # `NIF` poi lidne le mecraistu cu stali
      check live.is_held  # `combine` pe `live.nim`
      # le rebla pe le romoi jufra cu du le rebla pe le spisa
      check live.is_grown  # `combine` pe `live.nim`
      # le jalge cu jorne le selci'a le mecraistu
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
      check live.is_grown  # le stedu be `prose.nim` to `CLL 19.9` toi


  test "Lo'u that zo quotes in stream waits for none, though rules refuse zo":
    for text in TEXTS_LOHU_QUOTED:
      checkpoint text
      let live = text.readLive(text.cutsWords, is_growing = true)
      check live.nif == readTextParts(text).reading.toNifParts  # le flalu pe le stedu be `live.nim`
      # le porsi be lo valsi cu tcidu zo lo'u poi zo zo sitna ke'a
      check live.is_grown  # le stedu be `prose.nim` to `CLL 19.10` toi


  test "Lo'u that rules hold in quotation waits, where stream reads words it quotes":
    for text in TEXTS_LOHU_HELD:
      checkpoint text
      let live = text.readLive(text.cutsWords, is_growing = true)
      check live.nif == readTextParts(text).reading.toNifParts  # le flalu pe le stedu be `live.nim`
      # le porsi be lo valsi cu tcidu lo valsi poi zo lo'u sitna ke'a
      check live.is_grown  # le stedu be `prose.nim` to `CLL 19.9` toi


  test "Sa reads again where word after it changes, past words stream or rules refuse":
    for text in TEXTS_SA_PARTED:
      checkpoint text
      let live = text.readLive(text.cutsWords, is_growing = true)
      check live.nif == readTextParts(text).reading.toNifParts  # le flalu pe le stedu be `live.nim`
      # le rebla cu zenba ta'i lo nu le selci'a poi ca zvati cu jarco le rebla
      check live.is_grown  # le stedu be `live.nim` to `CLL 19.13` toi


  test "Zei that rules refuse reads again with quotation after it, once they refuse quotation":
    for text in TEXTS_ZEI_REFUSED:
      checkpoint text
      let live = text.readLive(text.cutsWords, is_growing = true)
      check live.nif == readTextParts(text).reading.toNifParts  # le flalu pe le stedu be `live.nim`
      # le rebla cu zenba ta'i lo nu le selci'a poi ca zvati cu jarco le rebla
      check live.is_grown  # le stedu be `live.nim` to `CLL 19.16` toi


  test "Closer reads back past text read again, where opener there opens no more":
    for (text, cuts) in CUTS_CLOSER:
      checkpoint text & " cut at " & $cuts
      let live = text.readLive(cuts, is_growing = true)
      check live.nif == readTextParts(text).reading.toNifParts  # le flalu pe le stedu be `live.nim`
      # lo famvla be lo kravla poi denpa
      check live.is_grown  # le stedu be `live.nim` to `CLL 17.4` toi


  test "Su ends text before it, which stays, save where quotation quotes it once closed":
    for text in TEXTS_SU:
      checkpoint text
      let live = text.readLive(text.cutsWords, is_growing = true)
      check live.nif == readTextParts(text).reading.toNifParts  # le flalu pe le stedu be `live.nim`
      # zo su .e lo nu sitna poi sitna zo su
      check live.is_grown  # le stedu be `live.nim` to `CLL 19.13` toi


  test "Fa'o goes out once, and end reads it again from span of its node":
    for (text, cuts) in CUTS_ENDED:
      checkpoint text & " cut at " & $cuts
      let live = text.readLive(cuts, is_growing = true)
      check live.nif == readTextParts(text).reading.toNifParts  # le flalu pe le stedu be `live.nim`
      # zo fa'o poi fanmo le selci'a
      check live.is_grown  # le stedu be `live.nim` to `CLL 19.15` toi


  test "Parts lose nothing of tree: assembleText builds tree grammar gives, over corpora":
    var count = 0
    for (key, text, whole) in pool:
      template reading: untyped = whole.reading
        ## lo datcme be lo jalge be lo nu tcidu lo pagbu
        ##   .i `let` da'i fukpi le jalge
      let is_read = reading.units.allIt(it.is_read) and reading.tree.children.len > 1
      if not is_read: continue
      let
        terminals = reading.units.mapIt(it.terminal)
        strict = terminals.readGrammar
      if not strict.is_read: continue
      checkpoint key & ": " & text
      let tree = terminals.assembleText(reading.tree.children)
      # lo pagbu cu zbasu lo tricu be le selci'a
      check tree.isSome  # le stedu be `grammar.nim`
      if tree.isNone: continue
      # no pagbu be le tricu cu selcri
      check tree.get.toNif(reading) == strict.tree.toNif(reading)  # le stedu be `live.nim`
      inc count
    # lo bandu cu ralte lo selci'a poi vasru za'u pa pagbu be le selci'a
    check count >= COUNT_PARTED_LEAST  # `IX.3`


  test "Decimal point and digit group read typed byte by byte or in pieces as read whole, and grow":
    # `Architect` jdice `D1 a` bu'u `#991`
    #   .i denpa bu poi romoi gi'e se lidne pa lerfu cu sinxa lo denpa
    #   .i ba lo nu lo lerfu cu se ciska ba ke'a kei denpa bu cu sinxa zo pi
    #   .i ro selci'a cu se tcidu ta'i lo nu ro lerfu cu spisa kei .e lo nu lo cunso stuzi cu katna
    #   .i lo spisa poi vasru so'i lerfu cu se benji ca lo nu lo selci'a cu se jmina fi le papri
    var rng = initRand(SEED)
    for text in [
        "li 3.14 .i li 1,000", "mi viska 3. do", "li 1,000.5 du li 1,000 su'i pi 5",
        "li 3,14 du li ci", "mi fa'o 3.5 do", "mi fa'o 1,000.5 do", "zoi 5 2.5 5 5",
        "mi viska li 3."]:
      for draw in 0 .. DRAWS_NUMBERED:
        let cuts = (if draw == 0: toSeq(1 ..< text.len) else: text.cutsRandom(rng, PIECE_MOST))
        checkpoint text & " cut at " & $cuts
        let live = text.readLive(cuts, is_growing = true)
        # le flalu pe le stedu be `live.nim`
        check live.nif == readTextParts(text).reading.toNifParts
        check live.is_held  # le stedu be `live.nim`
        check live.is_grown  # le stedu be `live.nim`
        check live.is_tied  # `ChangeNif` pe `live.nim`


  test "Bytes read grow with length of text, word by word":
    let
      text = textCost(SENTENCES_COST)
      twice = text & " .i " & text
      once = text.readLive(text.cutsWords)
      both = twice.readLive(twice.cutsWords)
    check once.nif == readTextParts(text).reading.toNifParts  # le flalu pe le stedu be `live.nim`
    # le flalu pe lo jdima
    check float(once.count_read) <= COST_MOST * float(text.len)  # le stedu be `live.nim`
    # le jdima cu zenba ta'i lo ni le selci'a cu clani
    #   .i le jdima na zenba ta'i lo pilji be le ni clani bei le ni clani
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
