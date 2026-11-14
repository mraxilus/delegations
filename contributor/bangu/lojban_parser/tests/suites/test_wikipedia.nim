## cipra le genturfa'i sepi'o `prose.nim` .e lo clani prosa pe la'o gy. Wikipedia .gy. pe la lojban.
##   .i ro ju'agri cu ralte lo se jdice poi le genturfa'i pu dunda ke'a ca lo nu ciska .i ro ju'agri
##   poi se to'e curmi cu na'e mapti lo javni pe la'o gy. CLL .gy. zi'e poi vi se sitna
##   .i le prosa cu du `tests/articles_wikipedia/articles.nim` noi lo minde po'u `wikipedia` pe
##     `tools/build.nim` cu ciska ke'a .i le prosa cu se javni la'o gy. CC BY-SA .gy. noi se ciska
##     fi lo datnyvei poi lamji le prosa to `D5 c` pe `#819` toi .i lo samtci bakfu no roi ciska le
##     prosa
##   .i lo ju'agri cu du pa linji pe lo sampu se ciska .i le cipra cu tcidu le ju'agri ta'i pa se
##     ciska pe `CLL 21.1` .i le ju'agri cu du lo jorne se ciska poi vasru su'o re jufra .i lo
##     ju'agri poi traji lo ka ce'u clani cu vasru vomubi valsi
##   .i lo linji poi pagbu lo jufra poi cfari ne'i lo pu linji cu se tcidu ta'i lo sepli se ciska .i
##     mupli fa lo pagbu be lo liste .i va'o lo nu le genturfa'i cu to'e curmi le linji kei lo sitna
##     cu cusku la'e di'u gi'e cusku lo namcu pe lo pu linji poi le linji cu se tcidu va'o lo nu
##     kansa ke'a
##   .i lo se jdice .e lo se tcidu pe le se jdice cu se krasi `tools/tatoeba.nim` .i se ki'u bo lo
##     cipra jo'u lo minde cu skicu le se jdice .e le se tcidu pa roi to `Article II.9` toi

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[sets, unittest]

import ../../tools/tatoeba
import ../articles_wikipedia/articles


const KEYS_REFUSED = [
  # le linji cu pagbu lo jufra poi cfari ne'i le pamoi linji .i le linji cu se tcidu ta'i lo nu
  #   kansa le pamoi linji .i va'o lo nu le linji cu sepli kei lo se ciska poi vasru `.e` jo'u lo
  #   sumti cu na me `fragment`
  ("cmaci", 2),  # le javni pe li reno
  # le linji cu pagbu le jufra poi cfari ne'i le pamoi linji .i le remoi linji cu pagbu le jufra
  #   ji'a
  ("cmaci", 3),  # le javni pe li reno
  # lo namcu lerfu po'u `3` cu na'e lerfu la lojban. .i le ju'agri cu vasru `3000moi`
  ("cmaci", 13),  # `CLL 3.1`
  # lo namcu lerfu po'u `1` cu na'e lerfu la lojban. .i le ju'agri cu vasru `16moi`
  ("cmaci", 16),  # `CLL 3.1`
  # lo namcu lerfu po'u `1` cu na'e lerfu la lojban. .i le ju'agri cu vasru `19xyxy`
  ("cmaci", 18),  # `CLL 3.1`
  # lo namcu lerfu po'u `1` cu na'e lerfu la lojban. .i le ju'agri cu vasru `193xymoi`
  ("cmaci", 21),  # `CLL 3.1`
  # `zei` cu jongau `fermat` `ro` po'o .i se ki'u bo `moi` cu se lidne no namcu to le javni pe li
  #   pamure toi
  ("cmaci", 22),  # `CLL 4.6`
  # no cmene cu vasru `la` poi lo karsna cu lidne ke'a .i le ju'agri cu vasru `paulas`
  ("eliogabalus", 18),  # `CLL 4.8`
  # lo namcu lerfu po'u `1` cu na'e lerfu la lojban. .i le ju'agri cu vasru `1987`
  ("lo jbobau", 1),  # `CLL 3.1`
  # lo namcu lerfu po'u `1` cu na'e lerfu la lojban. .i le ju'agri cu vasru `1987`
  ("lo jbobau", 3),  # `CLL 3.1`
  # lo namcu lerfu po'u `2` cu na'e lerfu la lojban. .i le ju'agri cu vasru `27`
  ("lo jbobau", 5),  # `CLL 3.1`
  # lo namcu lerfu po'u `2` cu na'e lerfu la lojban. .i le ju'agri cu vasru `26`
  ("lo jbobau", 6),  # `CLL 3.1`
  # `(` cu na'e lerfu la lojban. .i lo cukla grile'u cu sruri `to ... toi`
  ("lo jbobau", 9),  # `CLL 3.1`
  # lo namcu lerfu po'u `6` cu na'e lerfu la lojban. .i le ju'agri cu vasru `630`
  ("lo jbobau", 13),  # `CLL 3.1`
  # lo namcu lerfu po'u `1` cu na'e lerfu la lojban. .i le ju'agri cu vasru `1400`
  ("lo jbobau", 14),  # `CLL 3.1`
  # `tu'u` cu fanmo `tu'e` pe le recimoi linji .i va'o lo nu sepli kei `tu'u` cu fanmo no da
  ("lo jbobau", 29),  # le javni pe li pavo
  # lo barda lerfu po'u `L` pe `Lojban` cu sinxa no slaka .e no karsna
  ("lo jbobau", 30),  # `CLL 3.9`
]
  ## lo prosa jo'u lo linji pe ro ju'agri poi se to'e curmi .i ro le ju'agri cu se lanli ja'i
  ##   `CLL 1.1` .i lo sitna cu cusku le javni poi le ju'agri cu na'e mapti ke'a



suite "Internal: Wikipedia":
  test "Each paragraph of each article keeps verdict parser gave at render":
    var moved: seq[(string, int)]
    for paragraph in PARAGRAPHS_WIKIPEDIA:
      if paragraph.text.reading.verdict != paragraph.verdict:
        moved.add (paragraph.article, paragraph.index)
    # ro se jdice cu mintu le se jdice ca lo nu ciska
    check moved == newSeq[(string, int)]()  # `D5 c`


  test "Each refused paragraph is read against CLL, with rule it breaks":
    var refused: HashSet[(string, int)]
    for paragraph in PARAGRAPHS_WIKIPEDIA:
      if paragraph.verdict.len > 0: refused.incl (paragraph.article, paragraph.index)
    check refused == KEYS_REFUSED.toHashSet  # `KEYS_REFUSED` .i lo sitna cu lamji ro linji
