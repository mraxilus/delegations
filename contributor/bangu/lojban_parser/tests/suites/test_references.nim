## cipra lo du'u `splitLujvo` mapti lo seljdi be lo te karbi genturfa'i ne'i lo vopa valsi poi cipra
##     lo lerjo'e pe `CLL 4.11`
##   .i lo pinka pe ro xusra cu sitna lo javni pe `CLL` ge'u zi'e poi jdice fi le valsi
##   .i le pinka cu cusku lo samtci poi tugni le cipra ku'o ba lo nu sitna le javni
##   .i le seljdi cu se tcidu de'i `2026-10-24` fi `camxes` pe `ilmentufa master` ge'u .e
##       `vlatai 0.38` .e `is_valid_lujvo` pe `jbofihe 0.43 master` ge'u .e `latkerlo-jvotci 2.4.0`
##   .i lo pinka cu ciska zoi gy. jbofihe .gy. ta'i lo cmene be `is_valid_lujvo`
##   .i ki'u bo `vlatai` sepselcme
##   .i va'o lo nu le samtci cu na tugni kei le vi selgu'a cu jersi `CLL` ta'i lo ka satci
##   .i `4.11 step 4` to'e curmi ro lerjo'e poi le tadji na nitcu ke'a
##   .i se ki'u bo le cipra cu to'e curmi ro valsi poi vasru pa lerjo'e poi na seltcu
##   .iju lo na'e satci samtci cu curmi le valsi
##   .i jdima fa di'e
##   .i le cipra cu frica `camxes` bu'u `y` .e `r` vu'o poi se jmina
##   .i le cipra cu frica `latkerlo` bu'u `r` poi se jmina
##   .i le cipra cu frica `jbofihe` bu'u `r` poi zvati lo jbini be `CVV` jo'u `CCV` poi fanmo le
##       valsi
##   .i le cipra cu frica `jbofihe` bu'u `nlatu` ji'a
##   .i `jbofihe` tcidu `nlatu` ta'i `CCVCV`
##   .i le pinka cu tcidu lo selsku be le samtci ta'i di'e
##   .i va'o lo nu `vlatai` cusku `lujvo : to smabru` kei `vlatai` fendi le valsi re pagbu
##   .i se ki'u bo le selsku cu sinxa lo nu to'e curmi
##   .i `EXTENDED_LUJVO` noi seljdi `latkerlo` cmene pa tarmi poi bartu `CLL`
##   .i se ki'u bo le seljdi cu sinxa lo nu to'e curmi ji'a
##   .i lo pinka cu cusku lo samtci poi tugni
##   .i lu ro samtci cu tugni li'u sinxa ro le vo samtci
##   .i lo'u ro samtci poi na du le'u lidne lo cmene be le samtci poi frica
##   .i `vlatai` .e `jbofihe` satci samtci
##   .i lo pinka cu cusku lo nu le re satci samtci cu frica
##   .i lo ci zunsna poi na selcru gi'e zvati lo jonstu cu cpacu `y` ja'i lo tcaci pe `lujvo.nim`
##   .i `4.11` na cusku le tcaci to `3.7` toi
##   .i ro samtci cu tugni fo ro valsi poi le samtci cu jdice fi ke'a

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/unittest

import ../../src/lojban_parser/lujvo


func isLujvo(word: string): bool =
  ## cipra lo du'u `splitLujvo` facki fi pa porsi be lo rafsi ne'i le valsi
  word.splitLujvo.len == 1


func isRefused(word: string): bool =
  ## cipra lo du'u `splitLujvo` facki fi no porsi be lo rafsi ne'i le valsi
  word.splitLujvo.len == 0



suite "Internal: Reference parsers":
  test "Tosmabru test refuses word that falls apart, and no other":
    # ja'i `4.11 step 5` `tosmabru` se fendi
    #   .i ro samtci cu tugni
    check "tosmabru".isRefused  # `4.11 step 5`
    # ja'i `4.11 step 5c` `y` zvati le pamoi jorne stuzi
    #   .i ro samtci cu tugni
    check "tosymabru".isLujvo  # `4.11 step 5c`
    # ja'i `4.11 step 5` `pa` cliva le valsi
    #   .i ro samtci cu tugni
    check "pasmabru".isRefused  # `4.11 step 5`
    # ja'i `4.11 step 5c` `y` zvati le pamoi jorne stuzi
    #   .i ro samtci cu tugni
    check "pasymabru".isLujvo  # `4.11 step 5c`
    # ja'i `4.11 step 5` zoi gy. X .gy. pu cpacu `y` ja'i `step 4b`
    #   .i ro samtci cu tugni
    check "tosmakyjbo".isRefused  # `4.11 step 5`
    # ja'i `4.11 step 5c` pa `y` se jmina bu'u le pamoi jorne stuzi
    #   .i ro samtci cu tugni
    check "tosymakyjbo".isLujvo  # `4.11 step 5c`
    # ja'i `4.11 step 5b` `sm` .e `bl` .e `br` vu'o noi jonstu cu ka'e krasi lo valsi
    #   .i ro samtci cu tugni
    check "tosmablabru".isRefused  # `4.11 step 5b`
    # ja'i `4.11 step 5c` `y` zvati le pamoi jorne stuzi
    #   .i ro samtci cu tugni
    check "tosymablabru".isLujvo  # `4.11 step 5c`
    # ja'i `4.11 step 5b` `sm` .e `st` .e `sn` vu'o noi jonstu cu ka'e krasi lo valsi
    #   .i ro samtci cu tugni
    check "tosmastisna".isRefused  # `4.11 step 5b`
    # ja'i `4.11 step 5c` `y` zvati le pamoi jorne stuzi
    #   .i ro samtci cu tugni
    check "tosymastisna".isLujvo  # `4.11 step 5c`
    # ja'i `4.11 step 5` `CCV` poi se lidne lo porsi be `CVC` na du zoi gy. X .gy.
    #   .i ro samtci cu tugni
    check "tosmastci".isLujvo  # `4.11 step 5`
    # ja'i `4.11 step 4` `y` na seltcu
    #   .i ro samtci poi na du `camxes` tugni
    check "tosymastci".isRefused  # `4.11 step 4`
    # ja'i `4.11 step 5` `CVV` poi se lidne lo porsi be `CVC` na du zoi gy. X .gy.
    #   .i ro samtci cu tugni
    check "tosleiku'i".isLujvo  # `4.11 step 5`


  test "CVV takes r or n exactly where required":
    # ja'i `4.11 step 4a` lo re rafsi poi selfa'o `CCV` na cpacu `r`
    #   .i ro samtci cu tugni
    check "saicli".isLujvo  # `4.11 step 4a`
    # ja'i `4.11 step 4a` `CVV-CCV` na cpacu `r`
    #   .i `vlatai` tugni
    #   .i `jbofihe` frica
    check "saircli".isRefused  # `4.11 step 4a`
    # ja'i `4.11 step 4a` `CVV-CVV` cpacu `r`
    #   .i ro samtci cu tugni
    check "sairgau".isLujvo  # `4.11 step 4a`
    # ja'i `4.11 step 4a` `n` lidne `r` po'o
    #   .i ro samtci cu tugni
    check "sainmle".isRefused  # `4.11 step 4a`
    # ja'i `4.11 step 4a` `n` lidne `r`
    #   .i ro samtci cu tugni
    check "sainrebma".isLujvo  # `4.11 step 4a`
    # ja'i `4.11 step 4a` `n` lidne `r`
    #   .i ja'i `3.6 rule 1` `rr`
    #   .i ro samtci cu tugni
    check "sairrebma".isRefused  # `4.11 step 4a`
    # ja'i `4.11 step 4a` `CVV` poi lidne lo rafsi poi vasru mu lerfu cu cpacu `r`
    #   .i ro samtci cu tugni
    check "saiclika".isRefused  # `4.11 step 4a`
    # ja'i `4.11 step 4a` `CVV` poi lidne lo rafsi poi vasru mu lerfu cu cpacu `r`
    #   .i ro samtci cu tugni
    check "sairclika".isLujvo  # `4.11 step 4a`
    # ja'i `4.11 step 4a` `CVV` poi krasi lo ci rafsi cu cpacu `r`
    #   .i ro samtci cu tugni
    check "saiclibau".isRefused  # `4.11 step 4a`
    # ja'i `4.11 step 4a` `CVV` poi krasi lo ci rafsi cu cpacu `r`
    #   .i ro samtci cu tugni
    check "sairclibau".isLujvo  # `4.11 step 4a`
    # ja'i `4.11 step 4a` `r` se lidne le pamoi rafsi po'o
    #   .i `vlatai` .e `jbofihe` tugni
    check "jbosairgau".isRefused  # `4.11 step 4a`
    # ja'i `4.11 step 4a` `n` lidne `r` po'o
    #   .i ro samtci cu tugni
    check "re'enmlatu".isRefused  # `4.11 step 4a`
    # ja'i `4.6` `r` se lidne `CVV` po'o
    #   .i ro samtci cu tugni
    check "jborsai".isRefused  # `4.6`
    # ja'i `4.11 step 4a` `CVV` poi krasi lo ci rafsi cu cpacu `r`
    #   .i ro samtci cu tugni
    check "neijbomlatu".isRefused  # `4.11 step 4a`
    # ja'i `4.11 step 4a` `CVV` poi lidne lo rafsi poi vasru mu lerfu cu cpacu `r`
    #   .i ro samtci cu tugni
    check "neikerlo".isRefused  # `4.11 step 4a`
    # ja'i `4.11 step 4a` `CVV` poi lidne lo rafsi poi vasru mu lerfu cu cpacu `r`
    #   .i ro samtci cu tugni
    check "re'emlatu".isRefused  # `4.11 step 4a`
    # ja'i `4.11 step 4a` lo re rafsi poi selfa'o `CCV` na cpacu `r`
    #   .i ro samtci cu tugni
    check "fu'ivla".isLujvo  # `4.11 step 4a`
    # ja'i `4.11 step 4a` `CVV-CCV` na cpacu `r`
    #   .i `vlatai` tugni
    #   .i `jbofihe` frica
    check "fu'irvla".isRefused  # `4.11 step 4a`
    # ja'i `3.7` `nl` na ka'e krasi lo valsi
    #   .i ro samtci poi na du `jbofihe` tugni
    #   .i le re satci samtci cu frica
    check "branlatu".isRefused  # `3.7`


  test "Y stands exactly where required":
    # ja'i `4.11 step 4b` `nj` selcru
    #   .i le valsi cu vasru no `y`
    #   .i ro samtci cu tugni
    check "nunjdu".isLujvo  # `4.11 step 4b`
    # ja'i `4.11 step 4` `y` na seltcu
    #   .i ro samtci poi na du `camxes` tugni
    check "nunyjdu".isRefused  # `4.11 step 4`
    # ja'i `4.11 step 4b` `nm` selcru
    #   .i le valsi cu vasru no `y`
    #   .i ro samtci cu tugni
    check "sanmle".isLujvo  # `4.11 step 4b`
    # ja'i `4.11 step 4` `y` na seltcu
    #   .i ro samtci poi na du `camxes` tugni
    check "sanymle".isRefused  # `4.11 step 4`
    # ja'i `4.11 step 4c` `y` se lidne lo rafsi poi vasru vo lerfu
    #   .i ro samtci cu tugni
    check "brodymle".isLujvo  # `4.11 step 4c`
    # ja'i `4.11 step 4c` lo rafsi poi vasru vo lerfu cu nitcu `y`
    #   .i ro samtci cu tugni
    check "brodmle".isRefused  # `4.11 step 4c`


  test "Forbidden triple takes y by convention":
    # ja'i `3.7` lo ci zunsna po'u `ntc` na selcru
    #   .i ja'i lo tcaci
    #   .i ro samtci cu tugni
    check "cintca".isRefused  # `3.7`
    # ja'i `3.7` lo ci zunsna po'u `ntc` na selcru
    #   .i lo tcaci cu punji `y`
    #   .i ro samtci cu tugni
    check "cinytca".isLujvo  # `3.7`
    # ja'i `3.7` lo ci zunsna po'u `ndj` na selcru
    #   .i ja'i lo tcaci
    #   .i ro samtci cu tugni
    check "dindji".isRefused  # `3.7`
