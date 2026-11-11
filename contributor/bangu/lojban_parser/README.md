# lojban_parser

This project is a parser of lojban. Its scope is every valid lojban text, and it reads lojban words,
streams of them, and prose. It judges each word by the rules of CLL alone, so a word reads whether a
word list holds it or not. It reads a gismu, a cmavo or a lujvo as the parts of its tanru. It
refuses any other text with the rule that refuses it.

It renders a tanru back as the lujvo form that CLL prefers. It also tells which cmavo bind each
tanru unit.

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

The reader reads `bridyvalsi` as the tanru of `bridi` and `valsi`, and renders the lujvo of lowest
score, `brivla`. It reads `kukta` as a gismu by its form, though no list holds it. It reads
`clozba` as a lujvo, and keeps the letters `clo`, a rafsi that no list assigns. It refuses
`mudsiclu`, because CLL 4.11 requires a `y` there, and it names the correct form. It reads
`lojban` as a cmene, because the word ends in a consonant (4.8).

It also reads a stream of text into its words. Each word carries the pause before it, and the
stress that a capital marks:

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

The period before `i` writes its pause. The capitals of `RE` stress a last syllable before a
brivla, so CLL 4.9 needs a pause there. The text writes none, so the reader infers it, as CLL 3.3
allows.

A written word that holds several words splits into them, where one split needs the fewest
pauses:

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

CLL 4.8 says that `laplas.` looks like the words `la plas.`. A written word with no capital is
stressed on its own penultimate syllable alone, as the Architect ruled on #811. So `mibroda`
reads as `mi broda`, and `MIbroda`, whose capitals mark the stress of `mibro`, as `mibro da`.
`.esperanto` reads as `e speranto`, as Example 19.78 of CLL says.

It reads prose by the formal grammar of CLL 21.1. Before the grammar, quotation, erasure and the
other cmavo of 19.16 act on the words, so each terminal holds the words of one construct:

```text
$ nim r --hints:off --path:src --eval:'import std/[sequtils, strutils], lojban_parser
for text in ["mi klama le zarci", "ti gerku si mlatu",
    "la'o dy. Goethe .dy. cu me la'o ly. Homo sapiens .ly.", "mi klama le"]:
  let r = readText(text)
  if r.is_read: echo text, ": ", r.units.mapIt(it.words.mapIt(r.occurrences[it].text).join(" ") &
    " (" & $it.terminal & ")").join(", ")
  else: echo text, ": ", r.refusal, " at byte ", r.start, ", in ", r.rule'
mi klama le zarci: mi (KOhA), klama (BRIVLA), le (LE), zarci (BRIVLA)
ti gerku si mlatu: ti (KOhA), mlatu (BRIVLA)
la'o dy. Goethe .dy. cu me la'o ly. Homo sapiens .ly.: la'o dy Goethe dy (ZOI), cu (CU),
  me (ME), la'o ly Homo sapiens ly (ZOI)
mi klama le: Grammar at byte 11, in sumti-6 97
```

`si` erases `gerku`, as Example 19.75 says. The text that `la'o` quotes stands whole, in one
terminal of selma'o ZOI (Example 19.57). The grammar stops `mi klama le` at its end, where the
description of `le` waits for its selbri. `r.tree` holds the tree of the named rules of 21.1 over
the terminals.

`toNif` writes that tree as text in the NIF data format, version 2027, which is the native format
of Nim 3. So another program reads the tree with no part of this parser:

```text
$ nim r --hints:off --path:src --eval:'import lojban_parser
stdout.write readText("me\x27o vo").toNif'
(.nif27)
(.lang "cll-21.1")
(sumti_6 0 97 (LI 0 4 "meho") (number 310 812 (PA 5 7 "vo")))
```

Each named rule is a node, which holds its number in 21.1 and then its nodes. In 21.1, a rule often
holds the next rule alone, as `sumti` holds `sumti-1` where the text adds no relative clause. Such a
run of rules is one node. It holds the number of the rule that opens the run, then the number of the
rule that closes it. So `(sumti_6 0 97 ...)` is the run from `text`, rule 0, down to `sumti-6`,
rule 97. The two ends give one run in 21.1, and `LUT_CHAIN_BY_ENDS` gives each rule between them.

Each terminal holds its class, as `LI` or `PA`, then three things for each word. Those are the byte
where it opens, the byte past it, and its letters. So `(LI 0 4 "meho")` ties `me'o` to bytes 0 to 3
of the text. A named rule holds no byte, since its leaves give its span.

A tag writes `_` for `-`, and a word writes `h` for `'`, as chapter 20 writes the names of selma'o.
Lojban writes no `h` of its own (3.3), so `meho` reads back as `me'o`. Only the text that `zoi` or
`la'o` quotes can need an escape of NIF.

`readTextMarked` reads a text as `readText` does, and it reads on past each error. So another
program can mend the text by its tree, and this parser decides no mend (#859). A word that a stage
refuses stands as a unit with that stage, and the grammar reads the words around it. Where the
grammar stops, an error node holds the byte and the rule that stops there. It also holds the class
of each terminal that the grammar would read there:

```text
$ nim r --hints:off --path:src --eval:'import std/[strutils, wordwrap], lojban_parser
for line in readTextMarked("mi 1987 klama le").toNif.strip.splitLines: echo line.wrapWords(100)'
(.nif27)
(.lang "cll-21.1")
(srera 16 sumti_6 97 (nitcu BAI BU BY CAhA COI CUhE DOI FAhA FEhE FIhO GOI GOhA GUhA JAI KE KI KOhA
LA LAU LAhE LE LI LOhU LU ME MOhI NA NAhE NOI NU NUhA PA PU SE SEI SOI TAhE TEI TO VA VEI VEhA VIhA
XI ZAhO ZEI ZEhA ZI ZO ZOI BRIVLA) (sentence 0 40 (sumti_6 80 97 (KOhA 0 2 "mi")) (rivbi Stream
Letter 3 7 "1987") (bridi_tail_3 50 53 (tanru_unit_2 130 152 (BRIVLA 8 13 "klama")) (tail_terms
71))) (LE 14 16 "le"))
```

CLL names none of these nodes, so each takes a gismu, as the Architect ruled on #859. The error
node is `srera`, "x1 errs", and the classes that it holds are `nitcu`, "x1 needs x2". A unit that no
terminal holds is `rivbi`, "x1 avoids x2", since the grammar reads around it.

The stream refuses the digits `1987`, so they stand as `(rivbi Stream Letter 3 7 "1987")`, between
the sumti and the bridi tail. The text ends after `le`, so the grammar stops at byte 16, in
`sumti-6` 97, which waits for the selbri of `le`. The error node holds `mi klama`, which reads
alone as a sentence, and then `le` alone. A text that reads gives the reading of `readText`.

Each word that no terminal holds stands as a unit too, so each byte of each word lies in one leaf.
Words that erasure erases stand with the `si` or `sa` that erases them, as stage `Erasure`. `su`
ends the text before it, which stays as it read, and stands as stage `SU`, as the Architect chose
on #859. `fa'o` that ends the input stands as stage `FAhO`, and each written word after it as stage
`Stream`, with its bytes. Each stage takes the term of CLL, as CLL spells it:

```text
$ nim r --hints:off --path:src --eval:'import std/[strutils, wordwrap], lojban_parser
for line in readTextMarked("mi klama si do su ko fa\x27o 1234").toNif.strip.splitLines:
  echo line.wrapWords(100)'
(.nif27)
(.lang "cll-21.1")
(text 0 (terms 0 80 (sumti_6 81 97 (KOhA 0 2 "mi")) (rivbi Erasure 3 8 "klama" 9 11 "si") (sumti_6
81 97 (KOhA 12 14 "do"))) (rivbi SU 15 17 "su") (sumti_6 2 97 (KOhA 18 20 "ko")) (rivbi FAhO 21 25
"faho") (rivbi Stream FAhO 26 30 "1234"))
```

`si` erases `klama`, so one unit holds both. The root of the text after the last `su` holds each
text before it first. So a program that reads the text as CLL does drops each node up to the last
`su`, and `readText` gives the text `ko` alone.

`initReaderLive` makes a reader of live text, which reads a text piece by piece as it arrives
(#859). Each sentence goes out as NIF once the next one opens, and no piece reads the whole text
again. A word that reaches back cuts the NIF back, as `si` does. Each change from `push` gives the
offset that the NIF cuts back to, and the byte of the text where the cut opens. Then it gives the
nodes that go out, and the tail. The tail is the node of the part still open, as the text so far
gives it, and the next change replaces it:

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
  out  (sentence 0 40 (sumti_6 80 97 (KOhA 0 2 "mi")) (bridi_tail_3 50 53 (tanru_unit_2 130 152
       (BRIVLA 3 8 "klama")) (tail_terms 71)))
  tail (text_1 0 2 (I 10 11 "i") (sumti_6 4 97 (KOhA 12 14 "do")))
push "si si si ": cut back to 28, byte 0
  tail (sumti_6 0 97 (KOhA 0 2 "mi"))
  tail (rivbi Erasure 3 8 "klama" 10 11 "i" 12 14 "do" 15 17 "si" 18 20 "si" 21 23 "si")
push "su ko ": cut back to 28, byte 0
  out  (sumti_6 0 97 (KOhA 0 2 "mi"))
  out  (rivbi Erasure 3 8 "klama" 10 11 "i" 12 14 "do" 15 17 "si" 18 20 "si" 21 23 "si")
  out  (rivbi SU 24 26 "su")
  tail (sumti_6 0 97 (KOhA 27 29 "ko"))
finish: cut back to 163, byte 27
  out  (sumti_6 0 97 (KOhA 27 29 "ko"))
```

Offset 28 is the end of the two directives. The sentence `mi klama` goes out once `.i do` opens.
The three `si` erase `klama .i do`, so the NIF cuts back to the directives, and those words wait in
the tail as one unit. `su` ends that text, so its nodes go out with `su`, and `ko` opens a text of
its own. At the end, a text read piece by piece gives the NIF of its parts read whole, byte for byte
(`suites/test_live.nim`).

The verb `javascript` compiles the parser into one script of JavaScript, `build/lojban_parser.js`.
A page loads it with a `script` element, and calls three functions as globals:

- `parseLojban(text)` returns what `readText` gives, as a plain object. A refused text also
  carries `stream`, which `readStream` gives, so the caller sees the words before the refusal.
- `parseLojbanToNif(text)` returns the module that `toNif` writes, as a string, or null where the
  text is refused.
- `parseLojbanLive()` returns a reader of live text. Its `push(piece)` and `finish()` each give a
  promise of the change, `{at, start, text, tail}`, as `push` gives it in Nim. Its `nif()` gives a
  promise of the NIF so far.

The reader of live text reads in a worker where the page gives one, so the page never waits.
Elsewhere it reads one sentence at each turn of the event loop. A page cuts the NIF it holds back
to `at`, and adds `text`. `at` counts units of UTF-16, as a string of JavaScript indexes it.
`start` counts bytes of the text, as each word of the NIF does.

The verb `drive` holds the script to the native build in headless Chromium, which a backend of Nim
serves, with no node. `LOJBAN_CHROMIUM` names the Chromium to drive. `koch drive` runs the verb,
then judges the font faces of the control page, here with the warnings of the compiler left out:

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

The suite of the script holds each verdict of the sample of Tatoeba. The suite of live text reads
texts with words that reach back. Each text reads to the NIF that the native build gives, in the
worker and on the thread of the page. The suite runs once more on a page that refuses each worker.

## Authority

The project replicates The Complete Lojban Language (CLL), by John Woldemar Cowan, from the
Logical Language Group. It follows version 1.1, generated 2016-08-26, which is the latest edition,
at `lojban.org/publications/cll/`. Chapter 3 gives the letters, the marks of a stream, the consonant
clusters, the syllables and the stress. Chapter 4 gives the classes and shapes of words, the
rafsi, the algorithms that join and score a lujvo, and the pauses between words.
Chapters 5, 7, 9, 12 and 15 tell which words each cmavo binds, and chapter 20 is the catalogue of
selma'o. Chapters 13, 17 and 19 give indicators, lerfu words, quotation and erasure, and 21.1 gives
the formal grammar, which is in the public domain.

The suites carry the names of those chapters, and each assertion cites its source. The name of a
suite that CLL does not cover opens with `Internal:`.

The gismu list and the cmavo list come from the Logical Language Group, which placed them in the
public domain. The project commits both as typed Nim modules under
`src/lojban_parser/lists/`. It keeps the word and the rafsi of each gismu, and the word and the
selma'o of each cmavo. The
suites also read the lujvo list and the whole cmavo list as outside texts, where the Debian
package `lojban-common` installs them.

The folder `tests/cll/` holds the lojban lines of each numbered example of CLL 1.1. A verb
extracts them from the pages of the book, and the folder keeps the notice of the book. That notice
permits a modified copy only under its own terms. So the folder is not under the licence of the
repository.

The folder `tests/sample_tatoeba/` holds a fixed sample of the lojban sentences of Tatoeba. Its
sentences together reach as many rules of CLL as the export can reach. The folder is under the
licence of Tatoeba, CC BY 2.0 FR, and its notice credits each owner of a sentence.

The folder `tests/articles_wikipedia/` holds three long articles of the lojban Wikipedia, under
CC BY-SA 4.0. The suites read each paragraph of them as one connected text. The translations of
Alice and Oz stay out of the repository, and the suites read them where their pinned pages are
present.

## Build and test

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
nim r tools/build.nim drive                       # run suites of script in headless Chromium
nim r tools/build.nim system                      # print packages verbs and suites need
```

The build needs the compiler that `lojban_parser.nimble` pins, and the standard library alone.
The verbs `lists` and `head`, and the tests of outside texts, also need the Debian package
`lojban-common`, and `sha256sum` of `coreutils`. The verb `system` declares both.

The verb `cll` needs `sha256sum`, and the pages of CLL 1.1 saved in one directory, each under its
own name. The verb `tatoeba` needs `sha256sum` and the export of Tatoeba, decompressed. The verb
`wikipedia` needs `sha256sum` and the saved answers of the API of the Wikipedia. The verb
`translations` needs `curl` and `sha256sum`, and the verb `system` declares both.

The verb `javascript` needs the compiler alone. The verb `drive` needs Chromium, the one that
`LOJBAN_CHROMIUM` names. Else it takes the headless shell of Chrome for Testing from the store,
once the curator declares it there (#864). It unpacks that shell with `unzip`, which the verb
`system` declares. No check needs node.

## Pages

The project publishes no page.

## Status

The parser reads words by the rules of CLL alone. It reads each gismu and each cmavo by its form,
and each lujvo by its rafsi and hyphens, listed or not. It gives the selma'o of each cmavo that
the cmavo list holds, and splits cmavo run together into each cmavo. It renders a tanru as a
lujvo, and folds a tanru into tanru units. It reads each fu'ivla and each cmene by the rules of
CLL 4.7 and 4.8.

It reads a stream of text into its words, with its pauses, commas and capitals, and it splits
words that a text writes together. It reads prose by the grammar of 21.1, after quotation,
erasure, `zei`, BAhE, `bu` and indicators act on the words.
It reads on past each error, and it reads live text piece by piece, as the text arrives. Its NIF
ties each word to the bytes it reads from, and each byte of each word lies in one leaf.

The verb `javascript` builds the reader of prose and the reader of live text for a page. The verb
`drive` holds that build in headless Chromium to the native build. It holds the verdicts of the
sample of Tatoeba, and the NIF of live text, in a worker and on the thread of the page.

The suites hold each part to CLL. The parser reads each numbered example of CLL 1.1 that the
book calls grammatical, with the lines that hold notation left out. The book shows ten examples in
notation alone. It calls three examples wrong, and one more is an English sentence. Six write a
mex alone, and each reads after `li`.

Nine examples break a rule of 21.1. The parser follows 21.1 and refuses them, as the Architect
ruled on #815. `PROVENANCE.md` names the rule that each one breaks.

The parser reads 16,469 of the 17,495 sentences of Tatoeba. Each class of the others breaks a rule
of CLL 1.1, and `PROVENANCE.md` names each class with its rule and its count. The suites hold
each verdict of the sample, and cite the rule that each refused sentence of it breaks.

The parser reads 69 of the 86 paragraphs of the three articles, and the longest holds 458 words.
It reads 783 of the 856 paragraphs of Alice, and 56 of the 173 longer paragraphs of Oz. Each
refusal of these long texts breaks a rule of CLL, and none is a mistake of the parser.

The project `lojban_tagger` reads lojban through this parser, and holds no copy of its modules.
Its converter of the word lists imports the reader of the lists, and their pins, from
`tools/lists.nim`.
Nothing here has been read line by line by a human.
