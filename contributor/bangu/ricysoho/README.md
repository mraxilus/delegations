# ricyso'o

ni'o ni'o ni'o le vi selgu'a cu genturfa'i la lojban.
  .i le genturfa'i cu ka'e tcidu ro drajboselci'a gi'e tcidu lo jbovla .e lo vlapoi .e lo selci'a

ni'o zo ricyso'o noi lujvo fo lu tricu sombo li'u cu sinxa lo sombo be lo tricu
  .i le vi selgu'a cu se cmene zo ricyso'o ki'u lo nu le genturfa'i cu zbasu lo tricu pe ro jufra
  .i lo cmene be ro selgu'a pe `bangu` cu sinxa lo gunka poi kurji lo tricu ku'o ja'i `#920`
  .i `h` basti zoi gy. ' .gy. ne'i ro judri be lo datnyvei be'o .e ro cmene pe `Nim` ge'u .e
      `RICYSOHO_LISTS`
  .i ki'u bo `Nim` .e `shell` cu pilno zoi gy. ' .gy. lo drata

ni'o le genturfa'i cu jdice ro valsi ja'i lo javni pe `CLL` po'o
  .i se ki'u bo le genturfa'i cu tcidu lo valsi
  .iju lo vlaste cu vasru le valsi
  .i le genturfa'i cu tcidu lo pagbu be lo tanru pe pa gismu .a pa cmavo .a pa lujvo gi'e to'e curmi
      ro datselci'a gi'e cusku lo javni poi to'e curmi ri

ni'o le genturfa'i cu tcidu ro lerfu pe `0` bi'o `9` ta'i le cmavo pe `PA` poi le lerfu cu sinxa
    ke'a to `CLL 18.2` toi
  .i se ki'u bo le genturfa'i cu tcidu lo'u li pa so bi ze le'u fi zoi gy. li 1987 .gy.
  .i `CLL 3.1` na liste le lerfu
  .i ku'i `Architect` cpedu lo nu le genturfa'i cu tcidu le lerfu
  .i denpa bu poi zvati lo jbini be re lerfu cu se tcidu ta'i zo pi mu'u zoi gy. li 3.14 .gy.
  .i slaka bu poi se lidne pa lerfu gi'e lidne ci lerfu po'o cu se tcidu ta'i zo ki'o mu'u zoi gy.
      li 1,000 .gy.
  .i ro porsi be lo valsi pe `PA` cu du pa namcu to `CLL 18.6` toi
  .i se ki'u bo le genturfa'i cu tcidu pa namcu po'o fi zoi gy. le 10moi .gy.
  .i zo boi fendi re namcu poi lamji mu'u lo'u ro boi remei le'u

ni'o le genturfa'i cu ciska lo lujvo poi sinxa pa tanru gi'e selnei `CLL` ku'o gi'e jarco lo du'u ma
    kau poi cmavo cu jorne ro taurpau

```text
$ nim r --hints:off --path:src --eval:'import ricysoho
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

ni'o le genturfa'i cu facki lo du'u zo bridyvalsi sinxa lo tanru be zo bridi bei zo valsi kei gi'e
    ciska zo brivla noi ckini lo cmaraina'u
  .i le genturfa'i cu facki lo du'u zo kukta gismu kei ja'i lo tarmi be zo kukta
  .i ku'i no liste cu vasru zo kukta
  .i le genturfa'i cu facki lo du'u zo clozba lujvo kei gi'e ralte zoi gy. clo .gy. noi rafsi
  .i ku'i no liste cu vasru zoi gy. clo .gy.

ni'o le genturfa'i cu to'e curmi zoi gy. mudsiclu .gy. ki'u lo nu `CLL 4.11` nitcu lo lerjo'e ne'i
    le valsi kei gi'e cusku lo dratai
  .i le genturfa'i cu facki lo du'u zo lojban. cmene ki'u lo nu zo lojban. selfa'o lo zunsna to
      `CLL 4.8` toi

ni'o le genturfa'i cu tcidu lo vlapoi pe lo selci'a
  .i ro valsi cu ponse lo denpa poi lidne ri ku'o .e lo nu basna poi lo brale'u cu sinxa ke'a

```text
$ nim r --hints:off --path:src --eval:'import std/options, ricysoho
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

ni'o denpa bu poi lidne zo i sinxa lo denpa
  .i lo brale'u pe zoi gy. RE .gy. basna lo romoi slaka be zo re noi lidne pa brivla
  .i se ki'u bo `CLL 4.9` nitcu lo denpa vi
  .i le selci'a na sinxa lo denpa
  .i se ki'u bo le genturfa'i cu facki lo denpa ja'i `CLL 3.3`

ni'o le genturfa'i cu fendi lo selci'avla poi vasru so'i valsi ku'o gi'e cuxna lo fendi poi ke'a
    po'o nitcu lo mecraide'a

```text
$ nim r --hints:off --path:src --eval:'import std/strutils, ricysoho
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

ni'o `CLL 4.8` cusku lo du'u zoi gy. laplas. .gy. simsa lo'u la plas. le'u
  .i lo selci'avla poi vasru no brale'u cu se basna lo slaka poi lidne lo romoi
  .i `Architect` jdice di'u bu'u `#811`
  .i se ki'u bo le genturfa'i cu tcidu lo'u mi broda le'u fi zoi gy. mibroda .gy. gi'e tcidu lo'u
      mibro da le'u fi zoi gy. MIbroda .gy. noi lo brale'u be ri cu sinxa lo nu basna zo mibro
  .i le genturfa'i cu tcidu lo'u e speranto le'u fi zoi gy. .esperanto .gy. ja'i `CLL 19.78`

ni'o le genturfa'i cu tcidu lo selci'a ja'i lo gerna pe `CLL 21.1`
  .i pu lo nu le gerna cu tcidu kei lo cmavo pe lo nu sitna .e lo nu vimcu .e lo datma'o pe
      `CLL 19.16` galfi lo valsi
  .i se ki'u bo ro genvla cu vasru lo valsi be pa gensu'a

```text
$ nim r --hints:off --path:src --eval:'import std/[sequtils, strutils, wordwrap], ricysoho
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

ni'o zo si vimcu zo gerku ja'i `CLL 19.75`
  .i lo selci'a poi zo la'o sitna ke'a mulno gi'e selvau pa genvla pe `ZOI` to `CLL 19.57` toi
  .i le gerna cu sisti fi lo fanmo be lo'u mi klama le le'u
  .i vi ku lo sumti pe zo le denpa lo selbri be ri
  .i `r.tree` vasru lo tricu pe lo javni poi selcme noi gapru lo genvla

ni'o `toNif` ciska le tricu fi lo selci'a be fi `NIF 2027` noi raltai `Nim 3`
  .i se ki'u bo lo drata samtci cu ka'e tcidu le tricu gi'e pilno no pagbu be le genturfa'i

```text
$ nim r --hints:off --path:src --eval:'import ricysoho
stdout.write readText("me\x27o vo").toNif'
(.nif27)
(.lang "cll-21.1")
(sumti_6 0 (LI 0 4 "meho") (number 310 (PA 5 7 "vo")))
```

ni'o ro javni poi selcme cu jgena gi'e vasru lo cmene be le javni be'o .e lo jgena pe le javni
  .i ne'i `CLL 21.1` lo javni cu so'i roi vasru pa javni po'o
  .i mupli fa lo nu `sumti` vasru `sumti-1` po'o va'o lo nu lo selci'a cu na vasru
      `relative-clauses`

ni'o lo porsi be lo javni poi simsa cu jgena
  .i lo tcita be lo jgena cu cmene lo javni poi fanmo lo porsi
  .i lo namcu pe lo jgena cu du lo namcu pe lo javni poi krasi lo porsi
  .i se ki'u bo `(sumti_6 0 ...)` jgena lo porsi poi selkra `text` noi ckini li 0 ku'o gi'e selfa'o
      `sumti-6`

ni'o ne'i `CLL 21.1` le re fanmo cu jarco pa porsi
  .i `LUT_CHAIN_BY_ENDS` jarco ro javni poi zvati lo jbini be le re fanmo
  .i lo jgena poi vasru no namcu cu krasi no porsi

ni'o lo cmene be lo javni cu jarco lo namcu pe lo javni
  .i ki'u bo `CLL 21.1` dunda pa cmene .e pa namcu ro lo 88 javni
  .i se ki'u bo lo jgena cu ciska no namcu pe lo javni poi fanmo lo porsi
  .i `Architect` jdice di'u bu'u `#859` to `comment 6805527878` toi
  .i `LUT_NUMBER_BY_RULE` jarco lo namcu mu'u li 97 pe `sumti-6`

ni'o ro genvla cu vasru lo klesi be ri mu'u `LI` .a `PA`
  .i ba bo le genvla cu vasru lo namcu pe lo krasi be ro valsi ge'u .e lo namcu pe lo fanmo be le
      valsi ge'u .e lo lerfu be le valsi
  .i se ki'u bo `(LI 0 4 "meho")` jorne zo me'o lo selci'apau poi krasi li 0 gi'e fanmo li 4
  .i lo javni poi selcme cu vasru no namcu pe lo selci'apau ki'u lo nu lo pezli be le javni cu jarco
      lo pagbu

ni'o lo tcita cu ciska zoi gy. _ .gy. lo stuzi be zoi gy. - .gy.
  .i lo valsi cu ciska zoi gy. h .gy. lo stuzi be zoi gy. ' .gy. ja'i lo cmene be lo selma'o pe
      `CLL 20`
  .i la lojban. na pilno zoi gy. h .gy. to `CLL 3.3` toi
  .i se ki'u bo zoi gy. meho .gy. se tcidu lo'u me'o le'u
  .i lo selci'a po'o poi zo zoi .a zo la'o sitna ke'a cu ka'e nitcu lo bilga be fi `NIF`

ni'o `readTextMarked` tcidu lo selci'a gi'e simsa `readText` gi'e ku'i tcidu ji'a lo valsi poi se
    lidne ro srera
  .i se ki'u bo lo drata samtci cu ka'e cikre lo selci'a ja'i lo tricu be ri
  .i le genturfa'i na jdice lo nu cikre to `#859` toi

ni'o lo valsi poi lo pagbu be le genturfa'i cu to'e curmi ke'a selvau pa genvla noi se tcita lo
    cmene be le pagbu
  .i le gerna cu tcidu lo valsi poi sruri le genvla
  .i vi lo nu le gerna cu sisti kei lo srejge cu vasru lo namcu pe lo stuzi ge'u .e lo javni poi
      sisti vi ku'o gi'e vasru lo klesi be ro genvla poi le gerna ka'e tcidu ke'a vi

```text
$ nim r --hints:off --path:src --eval:'import std/[strutils, wordwrap], ricysoho
for line in readTextMarked("mi html klama le").toNif.strip.splitLines: echo line.wrapWords(100)'
(.nif27)
(.lang "cll-21.1")
(srera 16 sumti_6 (nitcu BAI BU BY CAhA COI CUhE DOI FAhA FEhE FIhO GOI GOhA GUhA JAI KE KI KOhA LA
LAU LAhE LE LI LOhU LU ME MOhI NA NAhE NOI NU NUhA PA PU SE SEI SOI TAhE TEI TO VA VEI VEhA VIhA XI
ZAhO ZEI ZEhA ZI ZO ZOI BRIVLA) (sentence 0 (sumti_6 80 (KOhA 0 2 "mi")) (rivbi Stream Letter 3 7
"html") (bridi_tail_3 50 (tanru_unit_2 130 (BRIVLA 8 13 "klama")) (tail_terms))) (LE 14 16 "le"))
```

ni'o `CLL` dunda no cmene le jgena
  .i se ki'u bo ro le jgena cu selcme pa gismu
  .i `Architect` jdice di'u bu'u `#859`

ni'o lo srejge cu selcme zo srera noi selsmu lu ko'a srera li'u
  .i lo klesi poi le srejge cu vasru ke'a selcme zo nitcu noi selsmu lu ko'a nitcu ko'e li'u
  .i lo pagbu poi no genvla cu vasru ke'a selcme zo rivbi noi selsmu lu ko'a rivbi ko'e li'u
  .i ki'u bo le gerna cu tcidu lo valsi poi sruri le pagbu

ni'o le genturfa'i cu to'e curmi zoi gy. html .gy. ca lo nu tcidu lo vlapoi
  .i se ki'u bo zoi gy. html .gy. selvau `(rivbi Stream Letter 3 7 "html")` noi se lidne lo sumti
      gi'e lidne lo brirebla

ni'o le selci'a cu fanmo ba zo le
  .i se ki'u bo le gerna cu sisti bu'u lo stuzi poi ckini li 16 ku'o ne'i `sumti-6` noi denpa lo
      selbri pe zo le
  .i le jgena cu ciska lo cmene be le javni po'o
  .i ki'u bo lo cmene cu jarco li 97 noi ckini le javni

ni'o le srejge cu vasru lu mi klama li'u noi jufra ku'o gi'e ba bo vasru zo le po'o
  .i va'o lo nu no srera cu zvati kei le re se tcidu cu mintu

ni'o ro valsi poi no genvla cu vasru ke'a selvau pa pagbu
  .i se ki'u bo ro pagbu be ro valsi cu zvati pa pezli
  .i lo valsi poi zo si .a zo sa vimcu ke'a kansa le vi'uvla ne'i pa pagbu poi se tcita zoi gy.
      Erasure .gy.

ni'o zo su fanmo lo selci'a poi lidne ri
  .i le selci'a cu stali
  .i zo su se tcita zoi gy. SU .gy.
  .i `Architect` cuxna di'u bu'u `#859`

ni'o zo fa'o poi fanmo lo selci'a cu se tcita zoi gy. FAhO .gy.
  .i ro selci'avla poi se lidne zo fa'o se tcita zoi gy. Stream .gy. gi'e ralte lo stuzi pe vo'a
  .i ro pagbu be le genturfa'i cu selcme lo valsi pe `CLL`
  .i lo lerfu be le valsi cu mintu lo lerfu poi `CLL` ciska ke'a

```text
$ nim r --hints:off --path:src --eval:'import std/[strutils, wordwrap], ricysoho
for line in readTextMarked("mi klama si do su ko fa\x27o 1234").toNif.strip.splitLines:
  echo line.wrapWords(100)'
(.nif27)
(.lang "cll-21.1")
(text (terms 0 (sumti_6 81 (KOhA 0 2 "mi")) (rivbi Erasure 3 8 "klama" 9 11 "si") (sumti_6 81 (KOhA
12 14 "do"))) (rivbi SU 15 17 "su") (sumti_6 2 (KOhA 18 20 "ko")) (rivbi FAhO 21 25 "faho") (rivbi
Stream FAhO 26 30 "1234"))
```

ni'o zo si vimcu zo klama
  .i se ki'u bo pa pagbu cu vasru le re valsi
  .i lo genja pe le romoi selci'a cu vasru ro selci'a poi lidne le romoi selci'a
  .i se ki'u bo lo samtci poi tcidu lo selci'a ja'i `CLL` vimcu ro jgena poi lidne zo su noi romoi
  .i `readText` jarco zo ko po'o

ni'o `initReaderLive` zbasu lo mivyselci'a tcidu noi tcidu ro selci'apau ca lo nu le pagbu cu klama
    to `#859` toi
  .i ro jufra cu selbe'i fi `NIF` ca lo nu lo bavla'i jufra cu cfari
  .i no pagbu cu raptcidu le mulselci'a
  .i lo valsi poi galfi lo pu valsi cu katna lo pagbu be le selci'a be fi `NIF` mu'u zo si

ni'o ro cenba pe `push` jarco lo stuzi poi le selci'a be fi `NIF` cu selka'a bu'u ke'a ku'o .e lo
    stuzi poi le katna cu cfari bu'u ke'a ne'i lo jboselci'a
  .i ba bo le cenba cu jarco lo jgena poi selbe'i .e lo rebla
  .i lo rebla cu du lo jgena pe lo pagbu poi ca'o kalri ja'i le selci'a ca
  .i lo bavla'i cenba cu basti lo rebla

```text
$ nim r --hints:off --path:src --eval:'import std/[strutils, wordwrap], ricysoho
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

ni'o li 23 cu namcu lo fanmo be le re minde
  .i lu mi klama li'u selbe'i ca lo nu lo'u .i do le'u cfari
  .i le ci valsi po'u zo si vimcu lo'u klama .i do le'u
  .i se ki'u bo le selci'a be fi `NIF` cu selka'a bu'u lo fanmo be le re minde
  .i le vi'uvla cu denpa ne'i lo rebla gi'e selvau pa pagbu

ni'o zo su fanmo le selci'a
  .i se ki'u bo lo jgena be le selci'a cu selbe'ikansa zo su
  .i zo ko cfari pa datselci'a
  .i ca lo fanmo le se tcidu be lo pagbu cu mintu le se tcidu be le mulselci'a ro lerfu to
      `suites/test_live.nim` toi

ni'o `mergeParts` goi ko'a jmina lo pagbu ja'i lo selci'a be fi `NIF` po'o noi lo papri .a lo cikre
    cu ponse ke'a
  .i ko'a vimcu ro valsi poi selvi'u .e zo fa'o .e ro valsi poi se lidne zo fa'o ku'o .e ro pagbu
      poi lidne zo su noi romoi
  .i ba bo ko'a jmina ro porsi be lo pagbu poi vasru no srera ku'o ta'i lo nu tcidu le mulselci'a
  .i va'o lo nu no srera cu stali kei ko'a jarco lo selci'a be fi `NIF` pe lo nu tcidu le mulselci'a
      ro lerfu
  .i `is_whole` jetnu

```text
$ nim r --hints:off --path:src --eval:'import std/[strutils, wordwrap], ricysoho
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

ni'o le ci pagbu be le pamoi selci'a cu selvau re `paragraph` ja'i le javni pe li 4 pe `CLL 21.1`
  .i `Architect` cuxna le selci'a be fi `NIF` pe le nu tcidu le mulselci'a kei to `D1 b` bu'u `#859`
      toi gi'e ba bo cuxna lo nu jmina poi to'e curmi no srera
  .i le se tcidu poi sinxa ro srera cu jarco lo stuzi be ro srera

ni'o ne'i le remoi selci'a le genturfa'i cu to'e curmi zoi gy. x .gy. ca lo nu tcidu lo vlapoi
  .i le gerna cu tcidu lo valsi poi sruri zoi gy. x .gy.
  .i se ki'u bo zoi gy. x .gy. zvati le jgena poi traji lo ka dizlo kei gi'e vasru lo pagbu poi se
      tcidu gi'e sruri zoi gy. x .gy.
  .i le jgena cu du `paragraph` ja'i lo nu tcidu le mulselci'a

ni'o ne'i le cimoi selci'a zo le denpa lo selbri be ri ba lo fanmo
  .i se ki'u bo le pagbu be zo le cu vasru pa srejge
  .i le gerna cu dunda no stuzi ne'i lo tricu le pagbu
  .i se ki'u bo le pagbu cu stali
  .i lo pagbu poi sruri ri se jmina

ni'o lo pagbu poi lidne zo su noi romoi cu stali va'o lo nu le genturfa'i cu tcidu le pagbu pu lo nu
    zo su vimcu to `CLL 19.16` toi
  .i se ki'u bo lo jmina be zoi gy. x su mi klama .gy. cu ralte zoi gy. x .gy. ki'u lo nu le
      genturfa'i cu tcidu lo vlapoi pe le mulselci'a pu ro drata
  .i lo jmina be lo'u le su mi klama le'u cu ralte no zo le
  .i lo nu jmina cu to'e curmi lo selci'a be fi `NIF` po'o poi na se tcidu gi'a vasru lo tarmi poi
      le ciska be fi `NIF` na ciska ke'a
  .i ba bo lo nu jmina cu cusku lo namcu be lo jgena be'o noi krasi li 0 ba le re minde ku'o .e lo
      krinu to `suites/test_merge.nim` toi

ni'o lo minde po'u `javascript` zbasu `build/ricysoho.js` noi samtci be fi `JavaScript` le
    genturfa'i
  .i lo papri cu cpacu le samtci sepi'o lo jgena po'u `script` gi'e pilno ci fancu poi ro da ka'e
      pilno ke'a

- ny.mai `parseLojban(text)` jarco lo selja'o be `readText` ta'i lo sapydai
  .i lo selci'a poi se to'e curmi cu vasru ji'a `stream` noi `readStream` jarco ke'a
  .i se ki'u bo lo pilno cu viska lo valsi poi lidne lo nu to'e curmi
- ny.mai `parseLojbanToNif(text)` jarco lo selci'a be `toNif` ta'i lo porsi be lo lerfu gi'e jarco
      `null` va'o lo nu le selci'a cu se to'e curmi
- ny.mai `parseLojbanLive()` jarco lo mivyselci'a tcidu
  .i `push(piece)` .e `finish()` pe le tcidu cu jarco lo nupre be lo cenba po'u
      `{at, start, text, tail}` noi `push` jarco ke'a ne'i `Nim`
  .i `nif()` pe le tcidu cu jarco lo nupre be lo selci'a be fi `NIF` ca

ni'o lo mivyselci'a tcidu cu tcidu ne'i lo gunka va'o lo nu lo papri cu dunda pa gunka
  .i se ki'u bo lo papri na denpa
  .i va'o lo drata le tcidu cu tcidu pa jufra ca ro nu `event loop` carna

ni'o lo papri cu katna lo selci'a be fi `NIF` be'o poi lo papri cu ponse ke'a ku'o bu'u `at` gi'e
    jmina `text`
  .i `at` kancu lo pagbu be fi `UTF-16` be'o noi lo porsi be fi `JavaScript` cu kancu ke'a
  .i `start` kancu lo selci'apau noi ro valsi pe `NIF` kancu ke'a

ni'o lo minde po'u `drive` cipra lo du'u le samtci cu mintu le jbezba ne'i `headless Chromium` noi
    lo samtci pe `Nim` sabji ke'a
  .i no `node` selpli
  .i `LOJBAN_CHROMIUM` jarco `Chromium` poi selpli
  .i `koch drive` pilno le minde gi'e ba bo jdice lo lertai pe lo tropapri
  .i lo kajde be lo fanva cu selvi'u vi

```text
$ nim r --hints:off koch drive contributor/bangu/ricysoho
== contributor/bangu/ricysoho
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

ni'o lo cipra be le samtci cu cipra ro jdice pe le mupli pe `Tatoeba`
  .i lo cipra be lo mivyselci'a cu tcidu lo selci'a poi vasru lo valsi poi galfi lo pu valsi
  .i ro selci'a cu se tcidu lo selci'a be fi `NIF` poi le jbezba cu jarco ke'a ku'o ne'i lo gunka .e
      lo cilta pe lo papri
  .i lo cipra cu rapli pa roi ne'i lo papri poi to'e curmi ro gunka

## ni'o ni'o ni'o lo krasi

ni'o le vi selgu'a cu fukpi `The Complete Lojban Language` noi `John Woldemar Cowan` ciska ke'a
  .i `Logical Language Group` dunda `CLL`
  .i le vi selgu'a cu jersi `1.1` noi selzba de'i li 2016 pi'e 8 pi'e 26 gi'e romoi bu'u
      `lojban.org/publications/cll/`

ni'o `CLL 3` ciska lo lerfu .e lo zunsna gunma .e lo slaka .e lo nu basna .e lo sinxa be lo vlapoi
  .i `CLL 4` ciska lo vlalei .e lo vlatai .e lo rafsi .e lo tadji poi jmina gi'e jdice lo lujvo ku'o
      .e lo denpa poi zvati lo jbini be lo valsi

ni'o `CLL 5 7 9 12 15` cusku lo du'u ro cmavo cu jorne ma kau valsi
  .i `CLL 20` liste lo selma'o
  .i `CLL 13 17 19` ciska lo cnivla .e lo lervla .e lo nu sitna .e lo nu vimcu
  .i `CLL 21.1` ciska le gerna noi zifre fi ro da

ni'o lo cipra cu selcme lo cmene be le ckupau
  .i ro xusra cu sitna lo krasi be ri
  .i lo cmene be lo cipra poi `CLL` na casnu ke'a cu cfari fi `Internal:`

ni'o le gimste .e le ma'oste cu seldu'a `Logical Language Group` gi'e zifre fi ro da
  .i le vi selgu'a cu ralte le re liste ta'i lo samtci pagbu pe `Nim` ne'i `src/ricysoho/lists/`
      gi'e ralte lo valsi .e lo rafsi be ro gismu be'o .e lo valsi .e lo selma'o be ro cmavo
  .i lo cipra cu tcidu ji'a le jvoste .e le mulma'oste noi datselci'a bu'u lo stuzi poi
      `lojban-common` noi bakfu cu punji le liste ke'a

ni'o `tests/cll/` vasru lo jboju'a be ro mupli poi selna'u ne'i `CLL 1.1` be'o .e lo notci be le
    cukta
  .i pa minde cu cpacu le jufra lo papri be le cukta
  .i le notci cu curmi lo gafyfu'i va'o le javni pe le notci po'o
  .i se ki'u bo `tests/cll/` na seljva le crujva pe `delegations`

ni'o `tests/sample_tatoeba/` vasru lo stomupli be lo jboju'a pe `Tatoeba`
  .i le jufra poi kansa cu jarco ro javni pe `CLL` zi'e poi lo mulselcpa ka'e jarco ke'a
  .i `tests/sample_tatoeba/` seljva le crujva pe `Tatoeba` zi'e po'u `CC BY 2.0 FR`
  .i le notci cu cmene ro ponse be lo jufra

ni'o `tests/articles_wikipedia/` vasru ci claro'a noi seljva `CC BY-SA 4.0` zi'e pe `Wikipedia` pe
    la lojban.
  .i lo cipra cu tcidu ro pagbu be le prosa ta'i pa jonselci'a
  .i lo fanva be `Alice` .e `Oz` na zvati le vi selgu'a
  .i lo cipra cu tcidu lo fanva va'o lo nu lo stopapri be lo fanva cu zvati

## ni'o ni'o ni'o lo nu zbasu .e lo nu cipra

```sh
nim r koch check                                  # from repository root: every check
nim r koch test contributor/bangu/ricysoho   # this project alone
nim r tools/build.nim lists                       # from project root: write both lists again
nim r tools/build.nim head                        # compare lists with lojban-common
nim r tools/build.nim cll <directory>             # write examples of CLL again from saved pages
nim r tools/build.nim tatoeba <export>            # write sample of Tatoeba again from its export
nim r tools/build.nim wikipedia <directory>       # write articles of Wikipedia again from answers
nim r tools/build.nim translations                # fetch Alice and Oz, which suites then read
nim r tools/build.nim javascript                  # compile parser to build/ricysoho.js
nim r tools/build.nim page                        # build page of live text, one file in build/
nim r tools/build.nim drive                       # run suites of script and page in Chromium
nim r tools/build.nim system                      # print packages verbs and suites need
```

ni'o lo nu zbasu cu nitcu lo fanva poi `ricysoho.nimble` stodi ke'a ku'o .e lo fadni samtci pe `Nim`
    po'o
  .i lo minde po'u `lists` .e `head` ge'u .e lo cipra be lo datselci'a cu nitcu ji'a `lojban-common`
      noi bakfu ku'o .e `sha256sum` pe `coreutils`
  .i lo minde po'u `system` cusku le re bakfu

ni'o lo minde po'u `cll` nitcu `sha256sum` .e lo papri be `CLL 1.1` be'o noi selra'e ne'i pa vasru
  .i lo minde po'u `tatoeba` nitcu `sha256sum` .e lo vreji be `Tatoeba` be'o poi se kalri
  .i lo minde po'u `wikipedia` nitcu `sha256sum` .e lo selra'espu be `API` pe `Wikipedia`
  .i lo minde po'u `translations` nitcu `curl` .e `sha256sum`
  .i lo minde po'u `system` cusku le re samtci

ni'o lo minde po'u `javascript` nitcu lo fanva po'o
  .i lo minde po'u `drive` nitcu `Chromium` poi selcme `LOJBAN_CHROMIUM` gi'e ka'e du `Chrome` .a
      `headless shell` pe `Chrome`
  .i va'o lo drata le minde cu cpacu `headless shell` pe `Chrome for Testing 153.0.8010.12` lo vreji
      be le vi selgu'a gi'e kalri `headless shell` fi `unzip` noi lo minde po'u `system` cusku ke'a
  .i no cipra cu nitcu `node`

ni'o lo minde po'u `page` .e `drive` cpacu lo lertai pe le papri sepi'o `koch fetch-assets` noi
    nitcu `curl` .e `sha256sum`
  .i `koch drive` tcidu `woff2` pe `Commit Mono` sepi'o `libbrotli1` noi lo minde po'u `system`
      cusku ke'a

## ni'o ni'o ni'o lo papri

ni'o [`tricu be lo mivyselci'a`](https://claude.ai/artifact/9fNo34mRzibNSs3a8QX7k4) pixra lo
    tricu be lo mivyselci'a ca lo nu lo prenu cu ciska le selci'a
  .i lo gunka cu tcidu ro pagbu be le selci'a ca lo nu le pagbu cu klama
  .i le papri cu pixra ro pagbu ja'i lo selci'a be fi `NIF` be'o poi le gunka cu dunda ke'a
  .i lo pagbu poi ca'o kalri cu skari lo najypelxu
  .i lo valsi poi galfi lo pu valsi mu'u zo si .a zo li'u katna lo selci'a be fi `NIF` bu'u lo stuzi
      be lo selga'i be le valsi

ni'o lo batke po'u `jmina` jmina ro mulpau sepi'o `mergeParts` fi pa tricu poi lo nu tcidu le
    mulselci'a cu jarco ke'a
  .i va'o lo nu lo srera cu stali kei ro porsi be lo pagbu poi sruri le srera cu se jmina
  .i le srera cu stali

| built file, under `build/` | published at |
| --- | --- |
| ricysoho.html | https://claude.ai/artifact/9fNo34mRzibNSs3a8QX7k4 |

ni'o lo minde po'u `page` zbasu le papri `pages/live.html`
  .i ko rapli gubgau le papri fi `build/ricysoho.html` ba ro cenba poi galfi lo selja'o be le papri
  .i ko punji `URL` ne'i `pull request` .e lo notci poi cusku lo du'u le selgu'a cu bredi

## ni'o ni'o ni'o lo ca ckaji be le genturfa'i

ni'o le genturfa'i cu tcidu lo valsi ja'i lo javni pe `CLL` po'o
  .i le genturfa'i cu tcidu ro gismu .e ro cmavo ja'i lo tarmi gi'e tcidu ro lujvo ja'i lo rafsi .e
      lo lerjo'e
  .iju lo liste cu vasru le valsi
  .i le genturfa'i cu jarco lo selma'o be ro cmavo poi le ma'oste cu vasru ke'a ku'o gi'e fendi pa
      selci'avla poi vasru so'i cmavo ku'o lo cmavo
  .i le genturfa'i cu ciska pa tanru ta'i pa lujvo gi'e fendi pa tanru ro taurpau gi'e tcidu ro
      fu'ivla .e ro cmene ja'i `CLL 4.7` .e `CLL 4.8`

ni'o le genturfa'i cu tcidu lo vlapoi pe lo selci'a ge'u .e lo denpa .e lo lerfu po'u slaka bu ge'u
    .e lo brale'u gi'e fendi lo valsi poi le selci'a cu ciska ke'a ne'i pa selci'avla
  .i le genturfa'i cu tcidu lo selci'a ja'i le gerna pe `CLL 21.1` ba lo nu lo nu sitna .e lo nu
      vimcu .e zo zei .e lo cmavo be zoi gy. BAhE .gy. be'o .e zo bu .e lo cnivla cu galfi lo valsi
  .i le genturfa'i cu tcidu lo valsi poi se lidne ro srera ku'o gi'e tcidu lo mivyselci'a ro pagbu
      ca lo nu le pagbu cu klama

ni'o lo selci'a be fi `NIF` pe le genturfa'i cu jorne ro valsi lo stuzi be ri ne'i lo jboselci'a
  .i ro pagbu be ro valsi cu zvati pa pezli
  .i le genturfa'i cu jmina lo selci'apau ja'i lo selci'a be fi `NIF` po'o fi lo selci'a be fi `NIF`
      pe lo nu tcidu le mulselci'a kei gi'e ralte ro srera bu'u lo stuzi be ri

ni'o lo minde po'u `javascript` zbasu lo selci'a tcidu .e lo mivyselci'a tcidu
  .i lo papri cu pilno le re tcidu
  .i lo minde po'u `drive` cipra lo du'u le selzba cu mintu le jbezba ne'i `headless Chromium` kei
      gi'e cipra lo jdice be le mupli pe `Tatoeba` be'o .e lo selci'a be fi `NIF` pe lo mivyselci'a
      ne'i lo gunka .e lo cilta pe lo papri

ni'o lo cipra cu cipra lo du'u ro pagbu cu mapti `CLL`
  .i le genturfa'i cu tcidu ro mupli poi selna'u ne'i `CLL 1.1` gi'e drani ja'i le cukta
  .i lo jufra poi vasru lo sinxa poi na lojbo cu selvi'u

ni'o le cukta cu jarco 10 mupli poi vasru lo na'e lojbo sinxa po'o
  .i le cukta cu cusku lo du'u ci mupli na drani
  .i pa datmupli cu gliju'a
  .i xa mupli cu ciska pa mekso po'o
  .i ro le xa mupli cu se tcidu ba zo li

ni'o so mupli cu na'e mapti su'o javni pe `CLL 21.1`
  .i le genturfa'i cu jersi `CLL 21.1` gi'e to'e curmi le so mupli
  .i `Architect` jdice di'u bu'u `#815`
  .i `PROVENANCE.md` cmene le javni poi ro le so mupli cu na'e mapti ke'a

ni'o le genturfa'i cu tcidu 16492 lo 17495 jufra pe `Tatoeba`
  .i ro klesi be lo drata cu na'e mapti su'o javni pe `CLL 1.1`
  .i `PROVENANCE.md` cmene ro klesi .e lo javni .e lo namcu pe le klesi
  .i lo cipra cu cipra ro jdice pe le mupli gi'e sitna lo javni poi ro jufra poi se to'e curmi cu
      na'e mapti ke'a

ni'o le genturfa'i cu tcidu 75 lo 86 pagbu be le ci prosa
  .i lo traji be lo ka clani cu vasru 458 valsi
  .i le genturfa'i cu tcidu 783 lo 856 pagbu be `Alice` be'o .e 56 lo 173 clapau be `Oz`
  .i ro le nu to'e curmi cu drani ja'i `CLL`

ni'o le ci vreji .e ro pinka pe le samtci .e le papri cu me lo jboselci'a poi le genturfa'i cu tcidu
    ke'a
  .i `suites/test_prose_own.nim` tcidu ro le selci'a sepi'o le genturfa'i gi'e fliba va'o ro srera
  .i ro jufra pe le selci'a cu krasi pa linji
  .i le cipra cu fliba ji'a va'o lo nu pa jufra cu krasi lo midju be pa linji
  .i `Architect` jdice di'u bu'u `#818`

ni'o `rictadni` tcidu la lojban. sepi'o le genturfa'i gi'e ralte no fukpi be lo pagbu be le
    genturfa'i
  .i lo samtci pe `rictadni` zi'e poi galfi lo vlaste cu cpacu lo tcidu be le liste be'o .e lo stodi
      be le liste be'o `tools/lists.nim`
  .i no prenu cu tcidu ro lo jufra pe le vi selci'a
