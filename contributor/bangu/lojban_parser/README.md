# lojban_parser

ni'o ni'o ni'o le vi se gunka cu genturfa'i la lojban.
  .i le genturfa'i cu ka'e tcidu ro drani lojbo se ciska
  .i ri tcidu lo lojbo valsi .e lo porsi be lo valsi .e lo se ciska
  .i le genturfa'i cu jdice ro valsi ja'i lo javni pe la'o gy. CLL .gy. po'o
  .i se ki'u bo le genturfa'i cu tcidu lo valsi
  .iju lo valsi liste cu vasru le valsi
  .i le genturfa'i cu tcidu lo pagbu be lo tanru pe pa gismu .a pa cmavo .a pa lujvo
  .i le genturfa'i cu to'e curmi ro drata se ciska gi'e cusku lo javni poi to'e curmi ri

ni'o le genturfa'i cu ciska lo lujvo poi sinxa pa tanru gi'e se nelci la'o gy. CLL .gy.
  .i le genturfa'i cu jarco ji'a lo du'u ma kau poi cmavo cu jorne ro tanru pagbu

```text
$ nim r --hints:off --path:src --eval:'import lojban_parser
for text in ["bridyvalsi", "kukta", "clozba", "mudsiclu", "lojban"]:
  let r = readWord(text)
  if r.is_word: echo text, ": ", r.kind, " ", r.tanru.parts, ", renders as ", r.tanru
  else: echo text, ": ", r.refusal, " ", r.detail'
bridyvalsi: Lujvo @[bridi, valsi], renders as brivla
kukta: Gismu @[kukta], renders as kukta
clozba: Lujvo @[clo, zbasu], renders as clozba
mudsiclu: Hyphen mudysiclu
lojban: Cmene @[lojban], renders as lojban
```

ni'o le genturfa'i cu facki lo du'u zo bridyvalsi cu sinxa lo tanru be zo bridi bei zo valsi
  .i le genturfa'i cu ciska zo brivla noi ckini lo cmalu traji namcu
  .i le genturfa'i cu facki lo du'u zo kukta cu gismu kei ja'i lo tarmi be zo kukta
  .i ku'i no liste cu vasru zo kukta
  .i le genturfa'i cu facki lo du'u zo clozba cu lujvo
  .i le genturfa'i cu ralte zoi gy. clo .gy. noi rafsi
  .i ku'i no liste cu vasru zoi gy. clo .gy.
  .i le genturfa'i cu to'e curmi zoi gy. mudsiclu .gy. ki'u lo nu la'o gy. CLL 4.11 .gy. cu nitcu lo
    lerfu jorne ne'i le valsi
  .i le genturfa'i cu cusku lo drani tarmi
  .i le genturfa'i cu facki lo du'u zo lojban. cmene ki'u lo nu zo lojban. se fanmo lo zunsna to
    la'o gy. CLL 4.8 .gy. toi

ni'o le genturfa'i cu tcidu ji'a lo porsi be lo valsi pe lo se ciska
  .i ro valsi cu ponse lo denpa poi lidne ri .e lo nu basna poi lo barda lerfu cu sinxa ke'a

```text
$ nim r --hints:off --path:src --eval:'import std/options, lojban_parser
let r = readStream(".i mi klama le RE NANmu")
for o in r.occurrences: echo o.text, ": ", o.reading.kind, ", pause ", o.pause,
  (if o.stress.isSome: ", stress on syllable " & $o.stress.get else: "")'
i: Cmavo, pause Written
mi: Cmavo, pause Absent
klama: Gismu, pause Absent
le: Cmavo, pause Absent
re: Cmavo, pause Absent, stress on syllable 0
nanmu: Gismu, pause Inferred, stress on syllable 0
```

ni'o denpa bu poi lidne zo i cu sinxa lo denpa
  .i lo barda lerfu pe zoi gy. RE .gy. cu basna lo romoi slaka be zo re noi lidne pa brivla
  .i se ki'u bo la'o gy. CLL 4.9 .gy. cu nitcu lo denpa vi
  .i le se ciska na sinxa lo denpa
  .i se ki'u bo le genturfa'i cu facki lo denpa ja'i la'o gy. CLL 3.3 .gy.

ni'o lo se ciska valsi poi vasru so'i valsi cu se fendi fi le genturfa'i
  .i le genturfa'i cu cuxna lo fendi poi ke'a po'o cu nitcu lo mleca traji denpa

```text
$ nim r --hints:off --path:src --eval:'import std/strutils, lojban_parser
for text in ["laplas.", "secusku", "mibroda", "MIbroda", ".esperanto"]:
  let r = readStream(text)
  if r.is_read:
    var words: seq[string]
    for o in r.occurrences: words.add o.text & " (" & $o.reading.kind & ")"
    echo text, ": ", words.join(" ")
  else: echo text, ": ", r.refusal, ", ", r.detail'
laplas.: la (Cmavo) plas (Cmene)
secusku: se (Cmavo) cusku (Gismu)
mibroda: mi (Cmavo) broda (Gismu)
MIbroda: mibro (Gismu) da (Cmavo)
.esperanto: e (Cmavo) speranto (Lujvo)
```

ni'o la'o gy. CLL 4.8 .gy. cu cusku lo du'u zoi gy. laplas. .gy. simsa lo'u la plas. le'u
  .i lo se ciska valsi poi vasru no barda lerfu cu se basna lo slaka poi lidne lo romoi
  .i la'o gy. Architect .gy. cu jdice di'u bu'u la'o gy. #811 .gy.
  .i se ki'u bo le genturfa'i cu tcidu lo'u mi broda le'u fi zoi gy. mibroda .gy.
  .i le genturfa'i cu tcidu lo'u mibro da le'u fi zoi gy. MIbroda .gy. noi lo barda lerfu be ri cu
    sinxa lo nu basna zo mibro
  .i le genturfa'i cu tcidu lo'u e speranto le'u fi zoi gy. .esperanto .gy. ja'i la'o gy. CLL 19.78
    .gy.

ni'o le genturfa'i cu tcidu lo se ciska ja'i lo gerna pe la'o gy. CLL 21.1 .gy.
  .i pu lo nu le gerna cu tcidu kei lo cmavo pe lo nu sitna .e lo nu vimcu .e lo drata cmavo pe la'o
    gy. CLL 19.16 .gy. cu galfi lo valsi
  .i se ki'u bo ro gerna valsi cu vasru lo valsi be pa gerna stura

```text
$ nim r --hints:off --path:src --eval:'import std/[sequtils, strutils, wordwrap], lojban_parser
for text in ["mi klama le zarci", "ti gerku si mlatu",
    "la\x27o dy. Goethe .dy. cu me la\x27o ly. Homo sapiens .ly.", "mi klama le"]:
  let r = readText(text)
  if r.is_read: echo (text & ": " & r.units.mapIt(it.words.mapIt(r.occurrences[it].text).join(" ") &
    " (" & $it.terminal & ")").join(", ")).wrapWords(100, newLine = "\n  ")
  else: echo text, ": ", r.refusal, " at byte ", r.start, ", in ", r.rule'
mi klama le zarci: mi (KOhA), klama (BRIVLA), le (LE), zarci (BRIVLA)
ti gerku si mlatu: ti (KOhA), mlatu (BRIVLA)
la'o dy. Goethe .dy. cu me la'o ly. Homo sapiens .ly.: la'o dy Goethe dy (ZOI), cu (CU), me (ME),
  la'o ly Homo sapiens ly (ZOI)
mi klama le: Grammar at byte 11, in sumti-6 97
```

ni'o zo si cu vimcu zo gerku ja'i la'o gy. CLL 19.75 .gy.
  .i lo se ciska poi zo la'o cu sitna ke'a cu mulno gi'e se vasru pa gerna valsi pe la'o gy. ZOI
    .gy. to la'o gy. CLL 19.57 .gy. toi
  .i le gerna cu sisti fi lo fanmo be lo'u mi klama le le'u
  .i vi lo sumti pe zo le cu denpa lo selbri be ri
  .i `r.tree` cu vasru lo tricu pe lo javni poi se cmene noi gapru lo gerna valsi

ni'o `toNif` cu ciska le tricu fi lo se ciska be fi la'o gy. NIF 2027 .gy. noi ralju tarmi la'o gy.
  Nim 3 .gy.
  .i se ki'u bo lo drata samtci cu ka'e tcidu le tricu gi'e pilno no pagbu be le genturfa'i

```text
$ nim r --hints:off --path:src --eval:'import lojban_parser
stdout.write readText("me\x27o vo").toNif'
(.nif27)
(.lang "cll-21.1")
(sumti_6 0 (LI 0 4 "meho") (number 310 (PA 5 7 "vo")))
```

ni'o ro javni poi se cmene cu jgena
  .i lo jgena cu vasru lo cmene be le javni be'o .e lo jgena pe le javni
  .i ne'i la'o gy. CLL 21.1 .gy. lo javni cu so'i roi vasru pa javni po'o
  .i mupli fa lo nu `sumti` cu vasru `sumti-1` po'o va'o lo nu lo se ciska cu na vasru
    `relative-clauses`
  .i lo porsi be lo javni poi simsa cu jgena
  .i lo tcita be lo jgena cu cmene lo javni poi fanmo lo porsi
  .i lo namcu pe lo jgena cu du lo namcu pe lo javni poi krasi lo porsi
  .i se ki'u bo `(sumti_6 0 ...)` cu jgena lo porsi poi se krasi `text` noi ckini li no gi'e se
    fanmo `sumti-6`

ni'o ne'i la'o gy. CLL 21.1 .gy. le re fanmo cu jarco pa porsi
  .i `LUT_CHAIN_BY_ENDS` cu jarco ro javni poi zvati lo jbini be le re fanmo
  .i lo jgena poi vasru no namcu cu krasi no porsi

ni'o lo cmene be lo javni cu jarco lo namcu pe lo javni
  .i ki'u bo la'o gy. CLL 21.1 .gy. cu dunda pa cmene .e pa namcu ro lo bibi javni
  .i se ki'u bo lo jgena cu ciska no namcu pe lo javni poi fanmo lo porsi
  .i la'o gy. Architect .gy. cu jdice di'u bu'u la'o gy. #859 .gy. to la'o gy. comment 6805527878
    .gy. toi
  .i `LUT_NUMBER_BY_RULE` cu jarco lo namcu
  .i mupli fa lo nu li soze cu namcu pe `sumti-6`

ni'o ro gerna valsi cu vasru lo klesi be ri mu'u `LI` .a `PA`
  .i ba bo ri vasru lo namcu pe lo krasi be ro valsi be'o .e lo namcu pe lo fanmo be ri .e lo lerfu
    be ri
  .i se ki'u bo `(LI 0 4 "meho")` cu jorne zo me'o lo pagbu be lo se ciska poi krasi li no gi'e
    fanmo li vo
  .i lo javni poi se cmene cu vasru no namcu pe lo pagbu be lo se ciska ki'u lo nu lo pezli be ri cu
    jarco lo pagbu

ni'o lo tcita cu ciska zoi gy. _ .gy. lo stuzi be zoi gy. - .gy.
  .i lo valsi cu ciska zoi gy. h .gy. lo stuzi be zoi gy. ' .gy. ja'i lo cmene be lo selma'o pe la'o
    gy. CLL 20 .gy.
  .i la lojban. na pilno zoi gy. h .gy. to la'o gy. CLL 3.3 .gy. toi
  .i se ki'u bo zoi gy. meho .gy. se tcidu lo'u me'o le'u
  .i lo se ciska po'o poi zo zoi .a zo la'o cu sitna ke'a cu ka'e nitcu lo bilga be fi la'o gy. NIF
    .gy.

ni'o `readTextMarked` cu tcidu lo se ciska
  .i ri simsa `readText`
  .i ku'i ri tcidu ji'a lo valsi poi se lidne ro srera
  .i se ki'u bo lo drata samtci cu ka'e cikre lo se ciska ja'i lo tricu be ri
  .i le genturfa'i na jdice lo nu cikre to la'o gy. #859 .gy. toi
  .i lo valsi poi le genturfa'i cu to'e curmi ke'a cu se vasru pa gerna valsi noi se tcita lo cmene
    be lo pagbu be le genturfa'i poi to'e curmi
  .i le gerna cu tcidu lo valsi poi sruri le gerna valsi
  .i vi lo nu le gerna cu sisti kei lo srera jgena cu vasru lo namcu pe lo stuzi .e lo javni poi
    sisti vi
  .i ri vasru ji'a lo klesi be ro gerna valsi poi le gerna ka'e tcidu ke'a vi

```text
$ nim r --hints:off --path:src --eval:'import std/[strutils, wordwrap], lojban_parser
for line in readTextMarked("mi 1987 klama le").toNif.strip.splitLines: echo line.wrapWords(100)'
(.nif27)
(.lang "cll-21.1")
(srera 16 sumti_6 (nitcu BAI BU BY CAhA COI CUhE DOI FAhA FEhE FIhO GOI GOhA GUhA JAI KE KI KOhA LA
LAU LAhE LE LI LOhU LU ME MOhI NA NAhE NOI NU NUhA PA PU SE SEI SOI TAhE TEI TO VA VEI VEhA VIhA XI
ZAhO ZEI ZEhA ZI ZO ZOI BRIVLA) (sentence 0 (sumti_6 80 (KOhA 0 2 "mi")) (rivbi Stream Letter 3 7
"1987") (bridi_tail_3 50 (tanru_unit_2 130 (BRIVLA 8 13 "klama")) (tail_terms))) (LE 14 16 "le"))
```

ni'o la'o gy. CLL .gy. cu dunda no cmene le jgena
  .i se ki'u bo ro le jgena cu se cmene pa gismu
  .i la'o gy. Architect .gy. cu jdice di'u bu'u la'o gy. #859 .gy.
  .i lo srera jgena cu se cmene zo srera noi se smuni lu ko'a srera li'u
  .i lo klesi poi le srera jgena cu vasru ke'a cu se cmene zo nitcu noi se smuni lu ko'a nitcu ko'e
    li'u
  .i lo pagbu poi no gerna valsi cu vasru ke'a cu se cmene zo rivbi noi se smuni lu ko'a rivbi ko'e
    li'u
  .i ki'u bo le gerna cu tcidu lo valsi poi sruri le pagbu

ni'o le genturfa'i cu to'e curmi zoi gy. 1987 .gy. ca lo nu tcidu lo porsi be lo valsi
  .i se ki'u bo zoi gy. 1987 .gy. cu se vasru `(rivbi Stream Letter 3 7 "1987")` noi se lidne lo
    sumti gi'e lidne lo bridi rebla
  .i le se ciska cu fanmo ba zo le
  .i se ki'u bo le gerna cu sisti bu'u lo stuzi poi ckini li paxa
  .i le gerna cu sisti ne'i `sumti-6` noi denpa lo selbri pe zo le
  .i le jgena cu ciska lo cmene be le javni po'o
  .i ki'u bo lo cmene cu jarco li soze noi ckini le javni
  .i le srera jgena cu vasru lu mi klama li'u noi jufra
  .i ba bo ri vasru zo le po'o
  .i va'o lo nu no srera cu zvati kei le re se tcidu cu mintu

ni'o ro valsi poi no gerna valsi cu vasru ke'a cu se vasru pa pagbu
  .i se ki'u bo ro pagbu be ro valsi cu zvati pa pezli
  .i lo valsi poi zo si .a zo sa cu vimcu ke'a cu kansa le vimcu valsi ne'i pa pagbu poi se tcita
    zoi gy. Erasure .gy.
  .i zo su cu fanmo lo se ciska poi lidne ri
  .i le se ciska cu stali
  .i zo su cu se tcita zoi gy. SU .gy.
  .i la'o gy. Architect .gy. cu cuxna di'u bu'u la'o gy. #859 .gy.
  .i zo fa'o poi fanmo lo se ciska cu se tcita zoi gy. FAhO .gy.
  .i ro se ciska valsi poi se lidne zo fa'o cu se tcita zoi gy. Stream .gy. gi'e ralte lo stuzi be
    ri
  .i ro pagbu be le genturfa'i cu se cmene lo valsi pe la'o gy. CLL .gy.
  .i lo lerfu be ri cu mintu lo lerfu poi la'o gy. CLL .gy. cu ciska ke'a

```text
$ nim r --hints:off --path:src --eval:'import std/[strutils, wordwrap], lojban_parser
for line in readTextMarked("mi klama si do su ko fa\x27o 1234").toNif.strip.splitLines:
  echo line.wrapWords(100)'
(.nif27)
(.lang "cll-21.1")
(text (terms 0 (sumti_6 81 (KOhA 0 2 "mi")) (rivbi Erasure 3 8 "klama" 9 11 "si") (sumti_6 81 (KOhA
12 14 "do"))) (rivbi SU 15 17 "su") (sumti_6 2 (KOhA 18 20 "ko")) (rivbi FAhO 21 25 "faho") (rivbi
Stream FAhO 26 30 "1234"))
```

ni'o zo si cu vimcu zo klama
  .i se ki'u bo pa pagbu cu vasru le re valsi
  .i lo genja pe le romoi se ciska cu vasru ro se ciska poi lidne le romoi se ciska
  .i se ki'u bo lo samtci poi tcidu lo se ciska ja'i la'o gy. CLL .gy. cu vimcu ro jgena poi lidne
    zo su noi romoi
  .i `readText` cu jarco zo ko po'o

ni'o `initReaderLive` cu zbasu lo tcidu be lo jmive se ciska
  .i ri tcidu ro pagbu be lo se ciska ca lo nu le pagbu cu klama to la'o gy. #859 .gy. toi
  .i ro jufra cu se benji fi la'o gy. NIF .gy. ca lo nu lo jufra poi se lidne ri cu cfari
  .i no pagbu cu rapli tcidu le mulno se ciska
  .i lo valsi poi galfi lo pu valsi cu katna lo pagbu be le se ciska be fi la'o gy. NIF .gy.
  .i zo si cu mupli
  .i ro cenba pe `push` cu jarco lo stuzi poi le se ciska be fi la'o gy. NIF .gy. cu se katna bu'u
    ke'a .e lo stuzi poi le katna cu cfari bu'u ke'a ne'i lo lojbo se ciska
  .i ba bo ri jarco lo jgena poi se benji .e lo rebla
  .i lo rebla cu du lo jgena pe lo pagbu poi ca'o kalri ja'i le se ciska ca
  .i lo bavla'i cenba cu basti lo rebla

```text
$ nim r --hints:off --path:src --eval:'import std/[strutils, wordwrap], lojban_parser
proc show(what: string, change: ChangeNif) =
  echo what, ": cut back to ", change.at, ", byte ", change.start
  for (kind, nif) in [("out ", change.text), ("tail", change.tail)]:
    for line in nif.splitLines:
      if line.len > 0: echo "  ", kind, " ", line.wrapWords(92, newLine = "\n       ")
var reader = initReaderLive()
for piece in ["mi klama .i do ", "si si si ", "su ko "]:
  show("push \"" & piece & "\"", reader.push(piece))
show("finish", reader.finish)'
push "mi klama .i do ": cut back to 28, byte 0
  out  (sentence 0 (sumti_6 80 (KOhA 0 2 "mi")) (bridi_tail_3 50 (tanru_unit_2 130 (BRIVLA 3 8
       "klama")) (tail_terms)))
  tail (text_1 0 (I 10 11 "i") (sumti_6 4 (KOhA 12 14 "do")))
push "si si si ": cut back to 28, byte 0
  tail (sumti_6 0 (KOhA 0 2 "mi"))
  tail (rivbi Erasure 3 8 "klama" 10 11 "i" 12 14 "do" 15 17 "si" 18 20 "si" 21 23 "si")
push "su ko ": cut back to 28, byte 0
  out  (sumti_6 0 (KOhA 0 2 "mi"))
  out  (rivbi Erasure 3 8 "klama" 10 11 "i" 12 14 "do" 15 17 "si" 18 20 "si" 21 23 "si")
  out  (rivbi SU 24 26 "su")
  tail (sumti_6 0 (KOhA 27 29 "ko"))
finish: cut back to 160, byte 27
  out  (sumti_6 0 (KOhA 27 29 "ko"))
```

ni'o li reci cu namcu lo fanmo be le re minde
  .i lu mi klama li'u cu se benji ca lo nu lo'u .i do le'u cu cfari
  .i le ci valsi po'u zo si cu vimcu lo'u klama .i do le'u
  .i se ki'u bo le se ciska be fi la'o gy. NIF .gy. cu se katna bu'u lo fanmo be le re minde
  .i le vimcu valsi cu denpa ne'i lo rebla gi'e se vasru pa pagbu
  .i zo su cu fanmo le se ciska
  .i se ki'u bo lo jgena be le se ciska cu se benji kansa zo su
  .i zo ko cu cfari pa drata se ciska
  .i ca lo fanmo le se tcidu be lo pagbu cu mintu le se tcidu be le mulno se ciska ro lerfu to
    `suites/test_live.nim` toi

ni'o `mergeParts` cu jmina lo pagbu ja'i lo se ciska be fi la'o gy. NIF .gy. po'o noi lo papri .a lo
  cikre cu ponse ke'a
  .i ri vimcu ro valsi poi se vimcu .e zo fa'o .e ro valsi poi se lidne zo fa'o .e ro pagbu poi
    lidne zo su noi romoi
  .i ba bo ri jmina ro porsi be lo pagbu poi vasru no srera ta'i lo nu tcidu le mulno se ciska
  .i va'o lo nu no srera cu stali kei ri jarco lo se ciska be fi la'o gy. NIF .gy. pe lo nu tcidu le
    mulno se ciska ro lerfu
  .i `is_whole` cu jetnu

```text
$ nim r --hints:off --path:src --eval:'import std/[strutils, wordwrap], lojban_parser
for text in ["mi klama .i do cadzu ni\x27o ko sipna", "mi klama .i x .i ko sipna",
    "mi klama .i le .i ko"]:
  let merged = readTextParts(text).reading.toNifParts.mergeParts
  echo "whole: ", merged.is_whole
  for line in merged.nif.strip.splitLines[2 .. ^1]: echo line.wrapWords(100)'
whole: true
(paragraphs 0 (paragraph (sentence 11 (sumti_6 80 (KOhA 0 2 "mi")) (bridi_tail_3 50 (tanru_unit_2
130 (BRIVLA 3 8 "klama")) (tail_terms))) (I 10 11 "i") (sentence 11 (sumti_6 80 (KOhA 12 14 "do"))
(bridi_tail_3 50 (tanru_unit_2 130 (BRIVLA 15 20 "cadzu")) (tail_terms)))) (NIhO 21 25 "niho")
(sentence 4 (sumti_6 80 (KOhA 26 28 "ko")) (bridi_tail_3 50 (tanru_unit_2 130 (BRIVLA 29 34
"sipna")) (tail_terms))))
whole: false
(paragraph 0 (sentence 11 (sumti_6 80 (KOhA 0 2 "mi")) (bridi_tail_3 50 (tanru_unit_2 130 (BRIVLA 3
8 "klama")) (tail_terms))) (I 10 11 "i") (rivbi Stream Shape 12 13 "x") (I 15 16 "i") (sentence 11
(sumti_6 80 (KOhA 17 19 "ko")) (bridi_tail_3 50 (tanru_unit_2 130 (BRIVLA 20 25 "sipna"))
(tail_terms))))
whole: false
(sentence 0 (sumti_6 80 (KOhA 0 2 "mi")) (bridi_tail_3 50 (tanru_unit_2 130 (BRIVLA 3 8 "klama"))
(tail_terms)))
(srera 16 sumti_6 (nitcu BAI BU BY CAhA COI CUhE DOI FAhA FEhE FIhO GOI GOhA GUhA JAI KE KI KOhA LA
LAU LAhE LE LI LOhU LU ME MOhI NA NAhE NOI NU NUhA PA PU SE SEI SOI TAhE TEI TO VA VEI VEhA VIhA XI
ZAhO ZEI ZEhA ZI ZO ZOI BRIVLA) (text_1 0 (I 10 11 "i")) (LE 12 14 "le"))
(text_1 0 (I 16 17 "i") (sumti_6 4 (KOhA 18 20 "ko")))
```

ni'o le ci pagbu be le pamoi se ciska cu se vasru re `paragraph` ja'i le javni pe li vo pe la'o gy.
  CLL 21.1 .gy.
  .i la'o gy. Architect .gy. cu cuxna le se ciska be fi la'o gy. NIF .gy. pe le nu tcidu le mulno se
    ciska to la'o gy. D1 b .gy. bu'u la'o gy. #859 .gy. toi
  .i ba bo la'o gy. Architect .gy. cu cuxna lo nu jmina poi to'e curmi no srera
  .i le se tcidu poi sinxa ro srera cu jarco lo stuzi be ro srera

ni'o ne'i le remoi se ciska le genturfa'i cu to'e curmi zoi gy. x .gy. ca lo nu tcidu lo porsi be lo
  valsi
  .i le gerna cu tcidu lo valsi poi sruri zoi gy. x .gy.
  .i se ki'u bo zoi gy. x .gy. cu zvati le jgena poi traji lo ka dizlo kei gi'e vasru lo pagbu poi
    se tcidu gi'e sruri zoi gy. x .gy.
  .i le jgena cu du `paragraph` ja'i lo nu tcidu le mulno se ciska
  .i ne'i le cimoi se ciska zo le cu denpa lo selbri be ri ba lo fanmo
  .i se ki'u bo le pagbu be zo le cu vasru pa srera jgena
  .i le gerna cu dunda no stuzi ne'i lo tricu le pagbu
  .i se ki'u bo le pagbu cu stali
  .i lo pagbu poi sruri ri cu se jmina

ni'o lo pagbu poi lidne zo su noi romoi cu stali va'o lo nu le pagbu be le genturfa'i poi tcidu ke'a
  cu tcidu pu lo nu zo su cu vimcu to la'o gy. CLL 19.16 .gy. toi
  .i se ki'u bo lo jmina be zoi gy. x su mi klama .gy. cu ralte zoi gy. x .gy. ki'u lo nu le
    genturfa'i cu tcidu lo porsi be lo valsi be le mulno se ciska pu ro drata
  .i lo jmina be lo'u le su mi klama le'u cu ralte no zo le
  .i lo nu jmina cu to'e curmi lo se ciska be fi la'o gy. NIF .gy. po'o poi na se tcidu gi'a vasru
    lo tarmi poi le ciska be fi la'o gy. NIF .gy. cu na ciska ke'a
  .i ba bo ri cusku lo namcu be lo jgena be'o noi krasi li no ba le re minde .e lo krinu to
    `suites/test_merge.nim` toi

ni'o lo minde po'u `javascript` cu zbasu `build/lojban_parser.js` noi samtci be fi la'o gy.
  JavaScript .gy. le genturfa'i
  .i lo papri cu cpacu ri sepi'o lo jgena po'u `script`
  .i lo papri cu pilno ci fancu poi ro da ka'e pilno ke'a

- ny.mai `parseLojban(text)` cu jarco lo se jarco be `readText` ta'i lo sampu dacti
  .i lo se ciska poi se to'e curmi cu vasru ji'a `stream` noi `readStream` cu jarco ke'a
  .i se ki'u bo lo pilno cu viska lo valsi poi lidne lo nu to'e curmi
- ny.mai `parseLojbanToNif(text)` cu jarco lo se ciska be `toNif` ta'i lo porsi be lo lerfu
  .i va'o lo nu le se ciska cu se to'e curmi kei ri jarco `null`
- ny.mai `parseLojbanLive()` cu jarco lo tcidu be lo jmive se ciska
  .i `push(piece)` .e `finish()` pe ri cu jarco lo nupre be lo cenba po'u `{at, start, text, tail}`
    simsa lo nu `push` cu jarco ri ne'i la'o gy. Nim .gy.
  .i `nif()` pe ri cu jarco lo nupre be lo se ciska be fi la'o gy. NIF .gy. ca

ni'o lo tcidu be lo jmive se ciska cu tcidu ne'i lo gunka va'o lo nu lo papri cu dunda pa gunka
  .i se ki'u bo lo papri na denpa
  .i va'o lo drata ri tcidu pa jufra ca ro nu `event loop` cu carna
  .i lo papri cu katna lo se ciska be fi la'o gy. NIF .gy. poi lo papri cu ponse ke'a bu'u `at` gi'e
    jmina `text`
  .i `at` cu kancu lo pagbu be fi la'o gy. UTF-16 .gy. simsa lo nu lo porsi be fi la'o gy.
    JavaScript .gy. cu kancu
  .i `start` cu kancu lo pagbu be lo se ciska simsa ro valsi pe la'o gy. NIF .gy.

ni'o lo minde po'u `drive` cu cipra lo du'u le samtci cu mintu le jbena zbasu ne'i la'o gy. headless
  Chromium .gy.
  .i lo samtci pe la'o gy. Nim .gy. cu sabji ri
  .i no `node` cu se pilno
  .i `LOJBAN_CHROMIUM` cu jarco la'o gy. Chromium .gy. poi se pilno
  .i `koch drive` cu pilno le minde
  .i ba bo ri jdice lo lerfu tarmi pe lo jitro papri
  .i vi lo kajde be lo fanva cu se vimcu

```text
$ nim r --hints:off koch drive contributor/bangu/lojban_parser
== contributor/bangu/lojban_parser
[Suite] Internal: JavaScript build
  [OK] Each sentence of Tatoeba sample takes verdict native build gave it
  [OK] Object of text that reads holds occurrences, units and tree
  [OK] Object of text refused holds refusal, its byte and rule, and stream before it
  [OK] Byte of refusal counts text in UTF-8, apart from index of JavaScript string
  [OK] NIF of every fourth sentence of sample that reads reads back, and rebuilds tree whole
  [OK] parseLojbanToNif gives module native build writes, and null where text is refused
[Suite] Internal: Live text of script
  [OK] Script defines its three functions as globals of page that loads it
  [OK] Worker reads each text to NIF native build gives, and thread of page reads none
  [OK] Thread of page reads each text, one sentence at each turn, to NIF native build gives
  [OK] Page runs task of its own between two sentences that thread of page reads
  [OK] Offset of change counts units of UTF-16, so slice cuts NIF where change opens
[Suite] Internal: Live text of script, worker refused
  [OK] Worker page refuses gives way to thread of page, which reads each text to native NIF
build/font-faces/written.json
0 finding(s).
```

ni'o lo cipra be le samtci cu cipra ro jdice pe le mupli pe la'o gy. Tatoeba .gy.
  .i lo cipra be lo jmive se ciska cu tcidu lo se ciska poi vasru lo valsi poi galfi lo pu valsi
  .i ro se ciska cu se tcidu lo se ciska be fi la'o gy. NIF .gy. poi le jbena zbasu cu jarco ke'a
    ne'i lo gunka .e lo cilta pe lo papri
  .i lo cipra cu rapli pa roi ne'i lo papri poi to'e curmi ro gunka

## ni'o ni'o ni'o lo krasi

ni'o le vi se gunka cu fukpi la'o gy. The Complete Lojban Language .gy. noi la'o gy. John Woldemar
  Cowan .gy. cu ciska ke'a
  .i la'o gy. Logical Language Group .gy. cu dunda la'o gy. CLL .gy.
  .i le vi se gunka cu jersi la'o gy. 1.1 .gy. noi se zbasu de'i li renopaxa pi'e bi pi'e rexa gi'e
    romoi bu'u `lojban.org/publications/cll/`
  .i la'o gy. CLL 3 .gy. cu ciska lo lerfu .e lo sinxa be lo porsi be lo valsi .e lo zunsna gunma .e
    lo slaka .e lo nu basna
  .i la'o gy. CLL 4 .gy. cu ciska lo klesi .e lo tarmi be lo valsi .e lo rafsi .e lo tadji poi jmina
    gi'e jdice lo lujvo .e lo denpa poi zvati lo jbini be lo valsi
  .i la'o gy. CLL 5 7 9 12 15 .gy. cu cusku lo du'u ro cmavo cu jorne ma kau valsi
  .i la'o gy. CLL 20 .gy. cu liste lo selma'o
  .i la'o gy. CLL 13 17 19 .gy. cu ciska lo cinmo valsi .e lo lerfu valsi .e lo nu sitna .e lo nu
    vimcu
  .i la'o gy. CLL 21.1 .gy. cu ciska le gerna noi zifre fi ro da

ni'o lo cipra cu se cmene lo cmene be le ckupau
  .i ro xusra cu sitna lo krasi be ri
  .i lo cmene be lo cipra poi la'o gy. CLL .gy. na casnu ke'a cu cfari fi `Internal:`

ni'o le gismu liste .e le cmavo liste cu se dunda la'o gy. Logical Language Group .gy.
  .i le re liste cu zifre fi ro da
  .i le vi se gunka cu ralte le re liste ta'i lo samtci pagbu pe la'o gy. Nim .gy. ne'i
    `src/lojban_parser/lists/`
  .i ri ralte lo valsi .e lo rafsi be ro gismu .e lo valsi .e lo selma'o be ro cmavo
  .i lo cipra cu tcidu ji'a le lujvo liste .e le mulno cmavo liste noi drata se ciska bu'u lo stuzi
    poi `lojban-common` noi bakfu ku'o cu punji le liste ke'a

ni'o `tests/cll/` cu vasru lo lojbo jufra be ro mupli poi se namcu ne'i la'o gy. CLL 1.1 .gy.
  .i pa minde cu cpacu le jufra lo papri be le cukta
  .i `tests/cll/` cu vasru ji'a lo notci be le cukta
  .i le notci cu curmi lo galfi fukpi va'o le javni pe le notci po'o
  .i se ki'u bo `tests/cll/` na se javni le curmi javni pe la'o gy. delegations .gy.

ni'o `tests/sample_tatoeba/` cu vasru lo stodi mupli be lo lojbo jufra pe la'o gy. Tatoeba .gy.
  .i le jufra poi kansa cu jarco ro javni pe la'o gy. CLL .gy. poi lo mulno se cpacu ka'e jarco ke'a
  .i `tests/sample_tatoeba/` cu se javni le curmi javni pe la'o gy. Tatoeba .gy. po'u la'o gy. CC BY
    2.0 FR .gy.
  .i le notci cu cmene ro ponse be lo jufra

ni'o `tests/articles_wikipedia/` cu vasru ci clani prosa pe la'o gy. Wikipedia .gy. pe la lojban.
  noi se javni la'o gy. CC BY-SA 4.0 .gy.
  .i lo cipra cu tcidu ro pagbu be le prosa ta'i pa jorne se ciska
  .i lo fanva be la'o gy. Alice .gy. .e la'o gy. Oz .gy. cu na zvati le vi se gunka
  .i lo cipra cu tcidu lo fanva va'o lo nu lo stodi papri be lo fanva cu zvati

## ni'o ni'o ni'o lo nu zbasu .e lo nu cipra

```sh
nim r koch check                                  # from repository root: every check
nim r koch test contributor/bangu/lojban_parser   # this project alone
nim r tools/build.nim lists                       # from project root: write both lists again
nim r tools/build.nim head                        # compare lists with lojban-common
nim r tools/build.nim cll <directory>             # write examples of CLL again from saved pages
nim r tools/build.nim tatoeba <export>            # write sample of Tatoeba again from its export
nim r tools/build.nim wikipedia <directory>       # write articles of Wikipedia again from answers
nim r tools/build.nim translations                # fetch Alice and Oz, which suites then read
nim r tools/build.nim javascript                  # compile parser to build/lojban_parser.js
nim r tools/build.nim page                        # build page of live text, one file in build/
nim r tools/build.nim drive                       # run suites of script and page in Chromium
nim r tools/build.nim system                      # print packages verbs and suites need
```

ni'o lo nu zbasu cu nitcu lo fanva poi `lojban_parser.nimble` cu stodi ke'a .e lo fadni samtci pe
  la'o gy. Nim .gy. po'o
  .i lo minde po'u `lists` .e `head` .e lo cipra be lo drata se ciska cu nitcu ji'a `lojban-common`
    noi bakfu ku'o .e `sha256sum` pe `coreutils`
  .i lo minde po'u `system` cu cusku le re bakfu

ni'o lo minde po'u `cll` cu nitcu `sha256sum` .e lo papri be la'o gy. CLL 1.1 .gy. noi se ralte ne'i
  pa vasru
  .i lo minde po'u `tatoeba` cu nitcu `sha256sum` .e lo vreji be la'o gy. Tatoeba .gy. poi se kalri
  .i lo minde po'u `wikipedia` cu nitcu `sha256sum` .e lo se ralte spuda be la'o gy. API .gy. pe
    la'o gy. Wikipedia .gy.
  .i lo minde po'u `translations` cu nitcu `curl` .e `sha256sum`
  .i lo minde po'u `system` cu cusku le re samtci

ni'o lo minde po'u `javascript` cu nitcu lo fanva po'o
  .i lo minde po'u `drive` cu nitcu la'o gy. Chromium .gy. poi `LOJBAN_CHROMIUM` cu cmene ke'a
  .i ri ka'e du la'o gy. Chrome .gy. .a `headless shell` pe ri
  .i va'o lo drata ri cpacu `headless shell` pe la'o gy. Chrome for Testing 153.0.8010.12 .gy. lo
    vreji be le vi se gunka
  .i ri kalri `headless shell` fi `unzip` noi lo minde po'u `system` cu cusku ke'a
  .i no cipra cu nitcu `node`

ni'o lo minde po'u `page` .e `drive` cu cpacu lo lerfu tarmi pe le papri sepi'o `koch fetch-assets`
  noi nitcu `curl` .e `sha256sum`
  .i `koch drive` cu tcidu `woff2` pe la'o gy. Commit Mono .gy. sepi'o `libbrotli1` noi lo minde
    po'u `system` cu cusku ke'a

## ni'o ni'o ni'o lo papri

ni'o [la'o gy. Lojban live tree .gy.](https://claude.ai/artifact/9fNo34mRzibNSs3a8QX7k4) cu pixra lo
  tricu be lo jmive se ciska ca lo nu lo prenu cu ciska le se ciska
  .i lo gunka cu tcidu ro pagbu be le se ciska ca lo nu le pagbu cu klama
  .i le papri cu pixra ro pagbu ja'i lo se ciska be fi la'o gy. NIF .gy. poi le gunka cu dunda ke'a
  .i lo pagbu poi ca'o kalri cu se skari lo narju pelxu
  .i lo valsi poi galfi lo pu valsi mu'u zo si .a zo li'u cu katna lo se ciska be fi la'o gy. NIF
    .gy. bu'u lo stuzi be lo se galfi be ri
  .i lo batke po'u `Merge` cu jmina ro mulno pagbu fi pa tricu poi lo nu tcidu le mulno se ciska cu
    jarco ke'a sepi'o `mergeParts`
  .i va'o lo nu lo srera cu stali kei ro porsi be lo pagbu poi sruri le srera cu se jmina
  .i le srera cu stali

| built file, under `build/` | published at |
| --- | --- |
| lojban_parser.html | https://claude.ai/artifact/9fNo34mRzibNSs3a8QX7k4 |

ni'o lo minde po'u `page` cu zbasu le papri `pages/live.html`
  .i ko rapli gubgau le papri fi `build/lojban_parser.html` ba ro cenba poi galfi lo se jarco be le
    papri
  .i ko punji `URL` ne'i `pull request` .e lo notci poi cusku lo du'u le se gunka cu bredi

## ni'o ni'o ni'o lo ca ckaji be le genturfa'i

ni'o le genturfa'i cu tcidu lo valsi ja'i lo javni pe la'o gy. CLL .gy. po'o
  .i le genturfa'i cu tcidu ro gismu .e ro cmavo ja'i lo tarmi
  .i le genturfa'i cu tcidu ro lujvo ja'i lo rafsi .e lo lerfu jorne
  .iju lo liste cu vasru le valsi
  .i le genturfa'i cu jarco lo selma'o be ro cmavo poi le cmavo liste cu vasru ke'a
  .i le genturfa'i cu fendi pa se ciska valsi poi vasru so'i cmavo ku'o lo cmavo
  .i le genturfa'i cu ciska pa tanru ta'i pa lujvo gi'e fendi pa tanru ro tanru pagbu
  .i le genturfa'i cu tcidu ro fu'ivla .e ro cmene ja'i la'o gy. CLL 4.7 .gy. .e la'o gy. CLL 4.8
    .gy.

ni'o le genturfa'i cu tcidu lo porsi be lo valsi pe lo se ciska kansa lo denpa .e lo lerfu po'u
  slaka bu .e lo barda lerfu
  .i le genturfa'i cu fendi lo valsi poi le se ciska cu ciska ke'a ne'i pa se ciska valsi
  .i le genturfa'i cu tcidu lo se ciska ja'i le gerna pe la'o gy. CLL 21.1 .gy. ba lo nu lo nu sitna
    .e lo nu vimcu .e zo zei .e lo cmavo be zoi gy. BAhE .gy. .e zo bu .e lo cinmo valsi cu galfi lo
    valsi
  .i le genturfa'i cu tcidu ji'a lo valsi poi se lidne ro srera
  .i le genturfa'i cu tcidu lo jmive se ciska ro pagbu ca lo nu le pagbu cu klama
  .i lo se ciska be fi la'o gy. NIF .gy. pe le genturfa'i cu jorne ro valsi lo stuzi be ri ne'i lo
    lojbo se ciska
  .i ro pagbu be ro valsi cu zvati pa pezli
  .i le genturfa'i cu jmina lo pagbu be lo se ciska ja'i lo se ciska be fi la'o gy. NIF .gy. po'o fi
    lo se ciska be fi la'o gy. NIF .gy. pe lo nu tcidu le mulno se ciska
  .i le genturfa'i cu ralte ro srera bu'u lo stuzi be ri

ni'o lo minde po'u `javascript` cu zbasu lo tcidu be lo se ciska .e lo tcidu be lo jmive se ciska
  .i lo papri cu pilno le re tcidu
  .i lo minde po'u `drive` cu cipra lo du'u le se zbasu cu mintu le jbena zbasu ne'i la'o gy.
    headless Chromium .gy.
  .i lo minde po'u `drive` cu cipra ji'a lo jdice be le mupli pe la'o gy. Tatoeba .gy. .e lo se
    ciska be fi la'o gy. NIF .gy. pe lo jmive se ciska ne'i lo gunka .e lo cilta pe lo papri

ni'o lo cipra cu cipra lo du'u ro pagbu cu mapti la'o gy. CLL .gy.
  .i le genturfa'i cu tcidu ro mupli poi se namcu ne'i la'o gy. CLL 1.1 .gy. gi'e drani ja'i le
    cukta
  .i lo jufra poi vasru lo sinxa poi na lojbo cu se vimcu
  .i le cukta cu jarco pano mupli poi vasru lo na'e lojbo sinxa po'o
  .i le cukta cu cusku lo du'u ci mupli na drani
  .i pa drata mupli cu glico jufra
  .i xa mupli cu ciska pa mekso po'o
  .i ro le xa mupli cu se tcidu ba zo li

ni'o so mupli cu na'e mapti su'o javni pe la'o gy. CLL 21.1 .gy.
  .i le genturfa'i cu jersi la'o gy. CLL 21.1 .gy. gi'e to'e curmi le so mupli
  .i la'o gy. Architect .gy. cu jdice di'u bu'u la'o gy. #815 .gy.
  .i `PROVENANCE.md` cu cmene le javni poi ro le so mupli cu na'e mapti ke'a

ni'o le genturfa'i cu tcidu paxavoxaso lo pazevosomu jufra pe la'o gy. Tatoeba .gy.
  .i ro klesi be lo drata cu na'e mapti su'o javni pe la'o gy. CLL 1.1 .gy.
  .i `PROVENANCE.md` cu cmene ro klesi kansa lo javni .e lo namcu be ri
  .i lo cipra cu cipra ro jdice pe le mupli
  .i lo cipra cu sitna lo javni poi ro jufra poi se to'e curmi cu na'e mapti ke'a

ni'o le genturfa'i cu tcidu xaso lo bixa pagbu be le ci prosa
  .i lo traji be lo ka clani cu vasru vomubi valsi
  .i le genturfa'i cu tcidu zebici lo bimuxa pagbu be la'o gy. Alice .gy. .e muxa lo pazeci clani
    pagbu be la'o gy. Oz .gy.
  .i ro le nu to'e curmi cu drani ja'i la'o gy. CLL .gy.

ni'o le ci vreji .e ro pinka pe le samtci .e le papri cu me lo lojbo se ciska poi le genturfa'i cu
  tcidu ke'a
  .i `suites/test_prose_own.nim` cu tcidu ro le se ciska sepi'o le genturfa'i gi'e fliba va'o ro
    srera
  .i la'o gy. Architect .gy. cu jdice di'u bu'u la'o gy. #818 .gy.

ni'o `lojban_tagger` cu tcidu la lojban. sepi'o le genturfa'i
  .i `lojban_tagger` cu ralte no fukpi be lo pagbu be le genturfa'i
  .i lo samtci pe `lojban_tagger` poi galfi lo valsi liste cu cpacu lo tcidu be le liste be'o .e lo
    stodi be le liste be'o `tools/lists.nim`
  .i no prenu cu tcidu ro lo jufra pe le vi se ciska
