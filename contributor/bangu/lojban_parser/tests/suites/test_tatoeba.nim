## cipra le genturfa'i sepi'o `prose.nim` .e lo stomupli be fi lo lojbo jufra pe `Tatoeba`
##   .i ro jufra cu ralte lo seljdi poi le genturfa'i pu dunda ke'a ca lo nu ciska
##   .i ro jufra poi se to'e curmi cu na'e mapti lo javni pe `CLL` zi'e poi vi se sitna
##   .i le mupli cu du `tests/sample_tatoeba/sentences.nim` noi lo minde po'u `tatoeba` pe
##       `tools/build.nim` ciska ke'a
##   .i le mupli cu seljva le crujva pe `Tatoeba` noi selci'a fi lo datnyvei poi lamji le mupli to
##       `D4 c` pe `#819` toi
##   .i lo samtci bakfu no roi ciska le mupli
##   .i lo jufra poi se tcidu cu bilga lo nu se tcidu
##   .i lo jufra poi se to'e curmi cu bilga lo nu le genturfa'i cu dunda lo mintu nu to'e curmi kei
##       .e lo mi'ujva
##   .i se ki'u bo va'o lo nu lo nu galfi le genturfa'i cu galfi su'o seljdi kei le cipra cu fliba
##       gi'e cusku le jufra
##   .i ro jufra pe le mupli zi'e poi se to'e curmi cu se lanli ja'i `CLL 1.1` vi
##   .i lo sitna pe ro le jufra cu cusku le javni poi le jufra cu na'e mapti ke'a
##   .i lo nu to'e curmi cu cusku le javni poi lo nu tcidu cu sisti ne'i ke'a
##   .i lo nu sisti cu ka'e fasnu ba le javni poi le jufra cu na'e mapti ke'a
##   .i le mupli cu jarco ro tcila poi le mupli pu jarco ke'a
##   .i le cipra cu karbi lo te kancu be le tcila `COUNT_FEATURES_TATOEBA`
##   .i lo se tcidu .e lo tcila cu selkra `tools/tatoeba.nim`
##   .i se ki'u bo le cipra jo'u le minde cu skicu le se tcidu .e le tcila pa roi to `Article II.9`
##       toi
##   .i le mupli ca na gacri lo javni poi no jufra pe le vreji cu jarco ke'a
##   .i le javni cu du `rp-expression` jo'u `rp-operand` vu'o pe lo mekso pe `reverse Polish`
##   .i `test_grammar.nim` cipra le re javni sepi'o `CLL 18.16`

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[sets, unittest]

import ../../tools/tatoeba
import ../sample_tatoeba/sentences


const IDS_REFUSED = [
  # `sepide` fanmo lo karsna
  #   .i se ki'u bo `sepide` na cmene
  #   .i le javni pe li cire cu na curmi lo nu `se pi de` se lidne `mi'e`
  634760,  # `CLL 4.8`
  # `NAI` na ka'e se lidne `CAhA`
  #   .i le jufra cu vasru `ka'enai`
  645249,  # le javni pe li sozere
  # lo cmene po'u `jim` cu ka'e sumti va'o po'o lo nu `la` lidne le cmene
  645284,  # le javni pe li soze
  # `NAI` na ka'e se lidne `CAhA`
  #   .i le jufra cu vasru `ka'enai`
  656510,  # le javni pe li sozere
  # `na` lidne lo selbri gi'e no roi se lidne le selbri
  657753,  # le javni pe li pacipa
  # `ba'e` rinka lo nu `pei` seivla
  #   .i no javni cu curmi lo nu le valsi cu se lidne `.i`
  678056,  # le javni pe li papanono
  # `s` .e `b` nitcu lo nu `y` zvati lo jbini be le re lerfu
  #   .i le jufra cu vasru `dusybarda`
  1484737,  # `CLL 4.11`
  # no cmene cu vasru `la` poi lo karsna cu lidne ke'a
  #   .i le jufra cu vasru `Milan`
  1502454,  # `CLL 4.8`
  # `xotli` noi brivla cu se lidne `ti` noi rebysu'i
  #   .i se ki'u bo `le` bilga lo nu lidne `ti`
  1576931,  # le javni pe li papapa
  # lo cmavo be `NAhE` be'o poi lidne lo sumti cu nitcu `bo`
  #   .i le jufra cu vasru `je'a bo ko'a`
  2024281,  # le javni pe li soze
  2063807,  # le javni pe li papapa lo'o to `la do` nitcu lo selbri poi se lidne `do` toi
  # `na` lidne lo selbri
  #   .i no javni cu curmi lo nu `bo` se lidne `na`
  2108189,  # le javni pe li pacipa
  # lo cmene po'u `tom` cu ka'e sumti va'o po'o lo nu `la` lidne le cmene
  2119742,  # le javni pe li soze
  # `djunko` fliba le cipra pe `slinku'i`
  #   .i ki'u bo `badjunko` lujvo
  2159050,  # `CLL 4.7`
  # `je` jongau lo selbri
  #   .i ku'i `cu` cfari no selbri
  2253980,  # le javni pe li pacivo
  # `NAI` na ka'e se lidne `NA`
  #   .i le jufra cu vasru `ja'anai`
  2312326,  # le javni pe li pacipa
  # lo cmavo be `GIhA` cu jongau lo brirebla
  #   .i `je` no roi jongau lo brirebla
  2332321,  # le javni pe li muno
  # `la` cu ka'e lidne lo cmene
  #   .i `lo` no roi lidne lo cmene
  #   .i le jufra cu vasru `lo tom`
  2577894,  # le javni pe li soze
  # lo cmavo be `NAhE` cu lidne lo valsi poi le cmavo cu natfe ke'a
  #   .i lo cmavo be `NAhE` no roi zvati lo fanmo
  #   .i le jufra cu vasru `je'a`
  2626994,  # le javni pe li sozere
  # `bei` lidne lo me `term`
  #   .i ku'i `se irsi` selbri
  2688629,  # le javni pe li paxapa
  # lo cmene po'u `borg` cu ka'e sumti va'o po'o lo nu `la` lidne le cmene
  2793895,  # le javni pe li soze
  # ne'i lo tcita `SE` cu ka'e lidne lo cmavo be `BAI` po'o
  #   .i `SE` no roi lidne `ne'i` noi cmavo be `FAhA`
  2802254,  # le javni pe li sozere
  # `pe'e je` jongau lo me `term`
  #   .i `je` poi na se lidne `pe'e` cu no roi se lidne `vau`
  2803459,  # le javni pe li bipa
  2808680,  # `CLL 20` to `di'ai` cmima no selma'o poi `CLL 1.1` dunda ke'a toi
  # `NAI` se lidne no brivla
  #   .i le jufra cu vasru `djica nai`
  2853152,  # le javni pe li pamure
  # `NAI` se lidne no brivla
  #   .i le jufra cu vasru `slabu nai`
  2864592,  # le javni pe li pamure
  # `NAI` se lidne no brivla
  #   .i le jufra cu vasru `lakne nai`
  2988210,  # le javni pe li pamure
  # `NAI` se lidne no cmavo be `KOhA`
  #   .i le jufra cu vasru `mi nai`
  3083055,  # le javni pe li soze
  # lo cmavo be `MOhE` cu lidne lo sumti
  #   .i ku'i `namcrgogolo` brivla
  3807272,  # le javni pe li cibimu
  # le valsi poi fanmo le selci'a pe `zoi` du le valsi poi cfari le selci'a
  #   .i ne'i le jufra lo cfavla cu du `gy`
  #   .i ku'i lo famvla cu du `dy`
  3807297,  # `CLL 19.10`
  3843946,  # `CLL 3.1` to `H` .e `!` na'e lerfu la lojban. toi
  # `NAI` se lidne no cmavo be `PA`
  #   .i le jufra cu vasru `su'e nai`
  3855768,  # le javni pe li bipare
  # lo cmavo be `LAhE` cu lidne lo sumti
  #   .i ku'i `pu ku` me `term`
  3989793,  # le javni pe li soze
  4167581,  # le javni pe li papare lo'o to `ku` fanmo lo sumti toi to ku'i `djuno` selbri toi
  # lo lerfu po'u slaka bu cu fendi lo slaka pe pa porsi be lo lerfu gi'e zvati lo stuzi poi no
  #     denpa cu ka'e zvati ke'a
  4225380,  # `CLL 3.3`
  # `je ca bo` lidne lo selbri
  #   .i `je ca bo` no roi lidne `cu`
  4226728,  # le javni pe li pacimu
  # `i'e` .e `ei'e` selkra lo karsna
  #   .i se ki'u bo le selci'a cu bilga lo nu denpa bu cu lidne pa le re valsi
  4285480,  # `CLL 3.3`
  # `vfd` vasru no karsna
  #   .i se ki'u bo `vfd` mapti no klesi be lo valsi
  4412245,  # `CLL 4.1`
  # `GA` cu ka'e lidne `NAI` gi'e no roi lidne `JA`
  #   .i le jufra cu vasru `ganai`
  4436842,  # le javni pe li binoze
  # `nu` lidne lo bridi
  #   .i ku'i `lo ckafi` vasru no selbri
  5181396,  # le javni pe li pamure
  # lo lerfu po'u zoi gy. ' .gy. zvati lo jbini be re karsna gi'e no roi zvati lo datstu
  #   .i le jufra cu vasru `mi''a`
  5181743,  # `CLL 3.3`
  # lo me `ek` .a lo me `joik` cu jongau lo namcu
  #   .i `je` no roi jongau lo namcu
  #   .i le jufra cu vasru `pa je su'e`
  5183488,  # le javni pe li cibici
  # lo brale'u cu sinxa lo slaka poi se basna ku'o .a lo karsna pe le slaka
  #   .i lo brale'u no roi sinxa lo zunsna po'o
  #   .i le jufra cu vasru `Mi`
  5912012,  # `CLL 3.9`
  # `ne` lidne lo me `term`
  #   .i ku'i `facki` selbri
  8639562,  # le javni pe li parere
  8721221,  # le javni pe li paxano lo'o to `be` nitcu lo me `term` poi se lidne `be` toi
  # lo me `term` lidne `cu`
  #   .i se ki'u bo `na ku` na ka'e se lidne `cu`
  8738058,  # le javni pe li vono
  # `jai` lidne pa tcita
  #   .i le tcita cu lidne lo brivla
  #   .i ku'i `pu` cfari lo remoi tcita
  10789002,  # le javni pe li pamure
  # `ziri` fanmo lo karsna
  #   .i se ki'u bo `ziri` na cmene
  #   .i se ki'u bo `la zi` na'e mapti le javni pe li soze
  12406452,  # `CLL 4.8`
  # `s` frica `b` lo ka voksa
  #   .i se ki'u bo no valsi cu vasru `sb`
  #   .i le jufra cu vasru `beisbol`
  13820484,  # `CLL 3.6`
]
  ## lo namcu pe ro jufra pe le mupli zi'e poi se to'e curmi
  ##   .i ro le jufra cu se lanli ja'i `CLL 1.1`
  ##   .i lo sitna pe ro namcu cu cusku le javni poi le jufra cu na'e mapti ke'a



suite "Internal: Tatoeba":
  test "Each sentence of sample keeps verdict parser gave, and sample keeps its features":
    var
      moved: seq[int]
      reached: HashSet[string]
    for sentence in SENTENCES_TATOEBA:
      let (verdict, features) = sentence.text.reading
      if verdict != sentence.verdict: moved.add sentence.id
      reached.incl features
    check moved == newSeq[int]()  # `D4 c` to ro seljdi cu mintu le seljdi ca lo nu ciska toi
    # lo tcila poi le mupli pu selcu'a ki'u ke'a
    check reached.len == COUNT_FEATURES_TATOEBA  # `D4 c`


  test "Each refused sentence of sample is read against CLL, with rule it breaks":
    var refused: HashSet[int]
    for sentence in SENTENCES_TATOEBA:
      if sentence.verdict.len > 0: refused.incl sentence.id
    check refused == IDS_REFUSED.toHashSet  # `IDS_REFUSED` to lo sitna cu lamji ro namcu toi
