## cipra le genturfa'i sepi'o `prose.nim` .e lo claro'a pe `Wikipedia` pe la lojban.
##   .i ro ju'agri cu ralte lo seljdi poi le genturfa'i pu dunda ke'a ca lo nu ciska
##   .i ro ju'agri poi se to'e curmi cu na'e mapti lo javni pe `CLL` zi'e poi vi se sitna
##
## ni'o le prosa cu du `tests/articles_wikipedia/articles.nim` noi lo minde po'u `wikipedia` pe
##     `tools/build.nim` ciska ke'a ku'o gi'e seljva `CC BY-SA` noi selci'a fi lo datnyvei poi lamji
##     le prosa to `D5 c` pe `#819` toi
##   .i lo samtci bakfu no roi ciska le prosa
##
## ni'o lo ju'agri cu du pa linji pe lo sapselci'a gi'e du lo jonselci'a poi vasru su'o re jufra
##   .i le cipra cu tcidu le ju'agri ta'i pa selci'a pe `CLL 21.1`
##   .i lo ju'agri poi traji lo ka ce'u clani cu vasru 458 valsi
##
## ni'o lo linji poi pagbu lo jufra poi cfari ne'i lo pu linji cu se tcidu ta'i lo sepselci'a
##   .i mupli fa lo pagbu be lo liste
##   .i va'o lo nu le genturfa'i cu to'e curmi le linji kei lo sitna cu cusku la'e di'u gi'e cusku
##       lo namcu pe lo pu linji poi le linji cu se tcidu va'o lo nu kansa ke'a
##
## ni'o lo seljdi .e lo se tcidu pe le seljdi cu selkra `tools/tatoeba.nim`
##   .i se ki'u bo lo cipra jo'u lo minde cu skicu le seljdi .e le se tcidu pa roi to `Article II.9`
##       toi

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[sets, unittest]

import ../../tools/tatoeba
import ../articles_wikipedia/articles


const KEYS_REFUSED = [
  # le linji cu pagbu lo jufra poi cfari ne'i le pamoi linji ku'o gi'e se tcidu ta'i lo nu kansa le
  #     pamoi linji
  #   .i va'o lo nu le linji cu sepli kei lo selci'a poi vasru `.e` jo'u lo sumti cu na me
  #       `fragment`
  ("cmaci", 2),  # le javni pe li 20
  # le linji .e le remoi linji cu pagbu le jufra poi cfari ne'i le pamoi linji
  ("cmaci", 3),  # le javni pe li 20
  # lo remoi be zo kei pe `keikei` cu fanmo no da
  #   .i ki'u bo zo cu poi lidne zo cipra .e zo nandu cu fanmo le re jufra poi zo nu krasi ke'a
  ("cmaci", 18),  # `CLL 11.1`
  # `zei` jongau `fermat` `ro` po'o
  #   .i se ki'u bo `moi` se lidne no namcu to le javni pe li 152 toi
  ("cmaci", 22),  # `CLL 4.6`
  # no cmene cu vasru `la` poi lo karsna cu lidne ke'a
  #   .i le ju'agri cu vasru `paulas`
  ("eliogabalus", 18),  # `CLL 4.8`
  # le re namcu po'u `1987` .e zo so'o cu nitcu zo boi poi zvati lo jbini be le re namcu
  #   .i va'o lo drata le gerna cu tcidu le re namcu ta'i pa namcu
  ("lo jbobau", 3),  # `CLL 18.6`
  # zoi gy. a'y .gy. mapti no tarmi be lo cmavo
  #   .i le ju'agri cu vasru `me'o .a'y`
  ("lo jbobau", 5),  # `CLL 4.2`
  # `(` na'e lerfu la lojban.
  #   .i lo cukla grile'u cu sruri `to ... toi`
  ("lo jbobau", 9),  # `CLL 3.1`
  # `tu'u` fanmo `tu'e` pe le 23moi linji
  #   .i va'o lo nu sepli kei `tu'u` fanmo no da
  ("lo jbobau", 29),  # le javni pe li 14
  # lo brale'u po'u `L` pe `Lojban` sinxa no slaka .e no karsna
  ("lo jbobau", 30),  # `CLL 3.9`
]
  ## lo prosa jo'u lo linji pe ro ju'agri poi se to'e curmi
  ##   .i ro le ju'agri cu se lanli ja'i `CLL 1.1`
  ##   .i lo sitna cu cusku le javni poi le ju'agri cu na'e mapti ke'a



suite "Internal: Wikipedia":
  test "Each paragraph of each article keeps verdict parser gave at render":
    var moved: seq[(string, int)]
    for paragraph in PARAGRAPHS_WIKIPEDIA:
      if paragraph.text.reading.verdict != paragraph.verdict:
        moved.add (paragraph.article, paragraph.index)
    # ro seljdi cu mintu le seljdi ca lo nu ciska
    check moved == newSeq[(string, int)]()  # `D5 c`


  test "Each refused paragraph is read against CLL, with rule it breaks":
    var refused: HashSet[(string, int)]
    for paragraph in PARAGRAPHS_WIKIPEDIA:
      if paragraph.verdict.len > 0: refused.incl (paragraph.article, paragraph.index)
    check refused == KEYS_REFUSED.toHashSet  # `KEYS_REFUSED` to lo sitna cu lamji ro linji toi
