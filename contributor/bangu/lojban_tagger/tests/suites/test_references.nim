## Hold `splitLujvo` to verdicts of reference parsers on 41 words probing hyphens of CLL 4.11.
##   Each check names CLL rule deciding its word, then tools agreeing with suite.
##   Verdicts read 2026-10-24 from camxes of ilmentufa master, vlatai 0.38, `is_valid_lujvo`
##     of jbofihe 0.43 master, and latkerlo-jvotci 2.4.0; citations write jbofihe for
##     `is_valid_lujvo`, since vlatai is named apart.
##   Where tools disagree, project follows CLL strictly: 4.11 step 4 forbids hyphen algorithm
##     does not require, so suite refuses every such word that lenient tool accepts.
##     Cost: suite parts from camxes on added `y` and `r`, from latkerlo on added `r`, and
##       from jbofihe on `r` between CVV and final CCV and on `nlatu`, which it takes as CCVCV.
##   Reading of tool output:
##     vlatai printing `lujvo : to smabru` splits word in two, so counts as refusal.
##     latkerlo verdict `EXTENDED_LUJVO` names form outside CLL, so counts as refusal too.
##   Citation names tools agreeing: `all agree` names all four, and `all but` names one that
##     differs. vlatai and jbofihe are strict tools; citation says where they part.
##   Forbidden triple at junction takes `y` by convention of `lujvo.nim`, which 4.11 does not
##     state (3.7); every tool agrees on words it decides.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/unittest

import ../../src/lojban_tagger/lujvo


func isLujvo(word: string): bool =
  ## Test `splitLujvo` finds exactly one rafsi sequence in word.
  word.splitLujvo.len == 1


func isRefused(word: string): bool =
  ## Test `splitLujvo` finds no rafsi sequence in word.
  word.splitLujvo.len == 0



suite "Internal: Reference parsers":
  test "Tosmabru test refuses word that falls apart, and no other":
    check "tosmabru".isRefused  # 4.11 step 5, `tosmabru` falls apart; all agree
    check "tosymabru".isLujvo  # 4.11 step 5c, `y` at first joint; all agree
    check "pasmabru".isRefused  # 4.11 step 5, `pa` falls off; all agree
    check "pasymabru".isLujvo  # 4.11 step 5c, `y` at first joint; all agree
    check "tosmakyjbo".isRefused  # 4.11 step 5, X took `y` by step 4b; all agree
    check "tosymakyjbo".isLujvo  # 4.11 step 5c, one `y` added at first joint; all agree
    check "tosmablabru".isRefused  # 4.11 step 5b, joints `sm`, `bl`, `br` initial; all agree
    check "tosymablabru".isLujvo  # 4.11 step 5c, `y` at first joint; all agree
    check "tosmastisna".isRefused  # 4.11 step 5b, joints `sm`, `st`, `sn` initial; all agree
    check "tosymastisna".isLujvo  # 4.11 step 5c, `y` at first joint; all agree
    check "tosmastci".isLujvo  # 4.11 step 5, CCV after CVC run is no X; all agree
    check "tosymastci".isRefused  # 4.11 step 4, `y` not required; all but camxes agree
    check "tosleiku'i".isLujvo  # 4.11 step 5, CVV after CVC run is no X; all agree


  test "CVV takes r or n exactly where required":
    check "saicli".isLujvo  # 4.11 step 4a, two rafsi ending CCV take no `r`; all agree
    check "saircli".isRefused  # 4.11 step 4a, CVV-CCV takes no `r`; vlatai agrees, jbofihe differs
    check "sairgau".isLujvo  # 4.11 step 4a, CVV-CVV takes `r`; all agree
    check "sainmle".isRefused  # 4.11 step 4a, `n` only before `r`; all agree
    check "sainrebma".isLujvo  # 4.11 step 4a, `n` before `r`; all agree
    check "sairrebma".isRefused  # 4.11 step 4a, `n` before `r`; 3.6 rule 1, `rr`; all agree
    check "saiclika".isRefused  # 4.11 step 4a, CVV before 5-letter takes `r`; all agree
    check "sairclika".isLujvo  # 4.11 step 4a, CVV before 5-letter takes `r`; all agree
    check "saiclibau".isRefused  # 4.11 step 4a, CVV opening three rafsi takes `r`; all agree
    check "sairclibau".isLujvo  # 4.11 step 4a, CVV opening three rafsi takes `r`; all agree
    check "jbosairgau".isRefused  # 4.11 step 4a, `r` after first rafsi alone; vlatai, jbofihe agree
    check "re'enmlatu".isRefused  # 4.11 step 4a, `n` only before `r`; all agree
    check "jborsai".isRefused  # 4.6, `r` used only after CVV; all agree
    check "neijbomlatu".isRefused  # 4.11 step 4a, CVV opening three rafsi takes `r`; all agree
    check "neikerlo".isRefused  # 4.11 step 4a, CVV before 5-letter takes `r`; all agree
    check "re'emlatu".isRefused  # 4.11 step 4a, CVV before 5-letter takes `r`; all agree
    check "fu'ivla".isLujvo  # 4.11 step 4a, two rafsi ending CCV take no `r`; all agree
    check "fu'irvla".isRefused  # 4.11 step 4a, CVV-CCV takes no `r`; vlatai agrees, jbofihe differs
    check "branlatu".isRefused  # 3.7, `nl` not initial; all but jbofihe agree; strict tools part


  test "Y stands exactly where required":
    check "nunjdu".isLujvo  # 4.11 step 4b, `nj` permissible, no `y`; all agree
    check "nunyjdu".isRefused  # 4.11 step 4, `y` not required; all but camxes agree
    check "sanmle".isLujvo  # 4.11 step 4b, `nm` permissible, no `y`; all agree
    check "sanymle".isRefused  # 4.11 step 4, `y` not required; all but camxes agree
    check "brodymle".isLujvo  # 4.11 step 4c, `y` after 4-letter rafsi; all agree
    check "brodmle".isRefused  # 4.11 step 4c, 4-letter rafsi needs `y`; all agree


  test "Forbidden triple takes y by convention":
    check "cintca".isRefused  # 3.7 triple `ntc`, convention; all agree
    check "cinytca".isLujvo  # 3.7 triple `ntc`, convention puts `y`; all agree
    check "dindji".isRefused  # 3.7 triple `ndj`, convention; all agree
