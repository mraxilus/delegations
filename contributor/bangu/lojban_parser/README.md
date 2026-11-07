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

## Build and test

```sh
nim r koch check                                  # from repository root: every check
nim r koch test contributor/bangu/lojban_parser   # this project alone
nim r tools/build.nim lists                       # from project root: write both lists again
nim r tools/build.nim head                        # compare lists with lojban-common
nim r tools/build.nim cll <directory>             # write examples of CLL again from saved pages
nim r tools/build.nim system                      # print packages verbs and suites need
```

The build needs the compiler that `lojban_parser.nimble` pins, and the standard library alone.
The verbs `lists` and `head`, and the tests of outside texts, also need the Debian package
`lojban-common`, and `sha256sum` of `coreutils`. The verb `system` declares both. The verb `cll`
needs `sha256sum`, and the pages of CLL 1.1 saved in one directory, each under its own name.

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

The suites hold each part to CLL. The parser reads each numbered example of CLL 1.1 that the
book calls grammatical, with the lines that hold notation left out. The book shows ten examples in
notation alone. It calls three examples wrong, and one more is an English sentence. Six write a
mex alone, and each reads after `li`.

Nine examples break a rule of 21.1. The parser follows 21.1 and refuses them, as the Architect
ruled on #815. `PROVENANCE.md` names the rule that each one breaks.

The project `lojban_tagger` keeps an earlier copy of these modules until #809 moves it onto this
parser. It holds no copy of `selmaho.nim`, `lists/cmavo.nim`, `fuhivla.nim`, `stream.nim`,
`grammar.nim` or `prose.nim`.
Nothing here has been read line by line by a human.
