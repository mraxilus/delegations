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
(sumti_6 0 97 (LI 0 "meho") (number 310 812 (PA 5 "vo")))
```

Each named rule is a node, which holds its number in 21.1 and then its nodes. In 21.1, a rule often
holds the next rule alone, as `sumti` holds `sumti-1` where the text adds no relative clause. Such a
run of rules is one node. It holds the number of the rule that opens the run, then the number of the
rule that closes it. So `(sumti_6 0 97 ...)` is the run from `text`, rule 0, down to `sumti-6`,
rule 97. The two ends give one run in 21.1, and `LUT_CHAIN_BY_ENDS` gives each rule between them.

Each terminal holds its class, as `LI` or `PA`, the byte where its first word opens, and the
letters of each word. A tag writes `_` for `-`, and a word writes `h` for `'`, as chapter 20 writes
the names of selma'o. Lojban writes no `h` of its own (3.3), so `meho` reads back as `me'o`. Only
the text that `zoi` or `la'o` quotes can need an escape of NIF.

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
(error 16 sumti_6 97 (expects BAI BU BY CAhA COI CUhE DOI FAhA FEhE FIhO GOI GOhA GUhA JAI KE KI
KOhA LA LAU LAhE LE LI LOhU LU ME MOhI NA NAhE NOI NU NUhA PA PU SE SEI SOI TAhE TEI TO VA VEI VEhA
VIhA XI ZAhO ZEI ZEhA ZI ZO ZOI BRIVLA) (sentence 0 40 (sumti_6 80 97 (KOhA 0 "mi")) (unread 3
Stream Letter "1987") (bridi_tail_3 50 53 (tanru_unit_2 130 152 (BRIVLA 8 "klama")) (tail_terms
71))) (LE 14 "le"))
```

The stream refuses the digits `1987`, so they stand as `(unread 3 Stream Letter "1987")`, between
the sumti and the bridi tail. The text ends after `le`, so the grammar stops at byte 16, in
`sumti-6` 97, which waits for the selbri of `le`. The error node holds `mi klama`, which reads
alone as a sentence, and then `le` alone. A text that reads gives the reading of `readText`.

`initReaderLive` makes a reader of live text, which reads a text piece by piece as it arrives
(#859). Each sentence goes out as NIF once the next one opens, and no piece reads the whole text
again. A word that reaches back cuts the NIF back, as `si` and `su` do. Each change from `push`
gives the offset that the NIF cuts back to, then the nodes that go out, then the tail. The tail is
the node of the part still open, as the text so far gives it, and the next change replaces it:

```text
$ nim r --hints:off --path:src --eval:'import std/[strutils, wordwrap], lojban_parser
proc show(what: string, change: ChangeNif) =
  echo what, ": cut back to ", change.at
  for (kind, nif) in [("out ", change.text), ("tail", change.tail)]:
    for line in nif.splitLines:
      if line.len > 0: echo "  ", kind, " ", line.wrapWords(92, newLine = "\n       ")
var reader = initReaderLive()
for piece in ["mi klama .i do ", "si si si ", "ko "]:
  show("push \"" & piece & "\"", reader.push(piece))
show("finish", reader.finish)'
push "mi klama .i do ": cut back to 28
  out  (sentence 0 40 (sumti_6 80 97 (KOhA 0 "mi")) (bridi_tail_3 50 53 (tanru_unit_2 130 152
       (BRIVLA 3 "klama")) (tail_terms 71)))
  tail (text_1 0 2 (I 10 "i") (sumti_6 4 97 (KOhA 12 "do")))
push "si si si ": cut back to 28
  tail (sumti_6 0 97 (KOhA 0 "mi"))
push "ko ": cut back to 28
  tail (terms 0 80 (sumti_6 81 97 (KOhA 0 "mi")) (sumti_6 81 97 (KOhA 24 "ko")))
finish: cut back to 28
  out  (terms 0 80 (sumti_6 81 97 (KOhA 0 "mi")) (sumti_6 81 97 (KOhA 24 "ko")))
```

Offset 28 is the end of the two directives. The sentence `mi klama` goes out once `.i do` opens.
The third `si` erases `klama`, so the NIF cuts back to the directives, and `mi` waits in the tail.
`ko` then joins it. At the end, the NIF of a text read piece by piece is the NIF of its parts read
whole. They are the same byte for byte, as `suites/test_live.nim` holds.

The verb `javascript` compiles the reader of prose, with the whole parser, into one script of
JavaScript. The script gives the function `parseLojban`, which returns what `readText` gives as a
plain object. After `nim r tools/build.nim javascript`, node reads the script:

```text
$ node -e 'const { parseLojban } = require("./build/lojban_parser.js")
for (const text of ["mi klama le zarci", "mi klama le zarc"]) {
  const r = parseLojban(text)
  if (r.is_read) console.log(text + ":", r.occurrences.map((o) => o.text + " " +
    (o.reading.selmaho ?? o.reading.kind)).join(", "), "| tree", r.tree.rule)
  else console.log(text + ":", r.refusal, "at byte", r.start + ", in", r.rule + ", after",
    r.stream.occurrences.map((o) => o.text).join(" "))
}'
mi klama le zarci: mi KOhA, klama Gismu, le LE, zarci Gismu | tree text
mi klama le zarc: Grammar at byte 12, in sumti-6 97, after mi klama le zarc
```

A refused text also carries `stream`, which `readStream` gives, so the caller sees the words before
the refusal. The script also gives `parseLojbanToNif`, which returns the module that `toNif`
writes, as a string, or null where the text is refused:

```text
$ node -e 'const { parseLojbanToNif } = require("./build/lojban_parser.js")
process.stdout.write(parseLojbanToNif("me\x27o vo"))
console.log(parseLojbanToNif("mi klama le zarc"))'
(.nif27)
(.lang "cll-21.1")
(sumti_6 0 97 (LI 0 "meho") (number 310 812 (PA 5 "vo")))
null
```

A page loads the same file with a `script` element, and calls both functions as globals.

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
nim r tools/build.nim system                      # print packages verbs and suites need
```

The build needs the compiler that `lojban_parser.nimble` pins, and the standard library alone.
The verbs `lists` and `head`, and the tests of outside texts, also need the Debian package
`lojban-common`, and `sha256sum` of `coreutils`. The verb `system` declares both.

The verb `cll` needs `sha256sum`, and the pages of CLL 1.1 saved in one directory, each under its
own name. The verb `tatoeba` needs `sha256sum` and the export of Tatoeba, decompressed. The verb
`wikipedia` needs `sha256sum` and the saved answers of the API of the Wikipedia. The verb
`translations` needs `curl` and `sha256sum`, and the verb `system` declares both.

The suite `tests/test_javascript.nim` runs on the JavaScript target of the compiler, and needs
node to run. The verb `system` declares node as the package `nodejs`. The verb `javascript` needs
the compiler alone.

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

The verb `javascript` builds the reader of prose for a page or for node. A suite holds that build
to the verdicts that the native build gives the sample of Tatoeba.

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
