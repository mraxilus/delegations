# lojban_parser

This project is a parser of lojban. Its scope is every valid lojban text, and it reads lojban
words, and streams of them. It judges each word by the rules of CLL alone, so a word reads whether
a word list holds it or not. It reads a gismu, a cmavo or a lujvo as the parts of its tanru. It
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
lojban: Cmene
```

The reader reads `bridyvalsi` as the tanru of `bridi` and `valsi`, and renders the lujvo of lowest
score, `brivla`. It reads `kukta` as a gismu by its form, though no list holds it. It reads
`clozba` as a lujvo, and keeps the letters `clo`, a rafsi that no list assigns. It refuses
`mudsiclu`, because CLL 4.11 requires a `y` there, and it names the correct form. It refuses
`lojban` as a cmene, which this parser does not read yet.

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

## Authority

The project replicates The Complete Lojban Language (CLL), by John Woldemar Cowan, first
edition, 1997, from the Logical Language Group. The text is the first edition with errata, at
`lojban.github.io/cll`. Chapter 3 gives the letters, the marks of a stream, the consonant
clusters, the syllables and the stress. Chapter 4 gives the classes and shapes of words, the
rafsi, the algorithms that join and score a lujvo, and the pauses between words.
Chapters 5, 7, 9, 12 and 15 tell which words each cmavo binds, and chapter 20 is the catalogue of
selma'o.

The suites carry the names of those chapters, and each assertion cites its source. The name of a
suite that CLL does not cover opens with `Internal:`.

The gismu list and the cmavo list come from the Logical Language Group, which placed them in the
public domain. The project commits both as typed Nim modules under
`src/lojban_parser/lists/`. It keeps the word and the rafsi of each gismu, and the word and the
selma'o of each cmavo. The
suites also read the lujvo list and the whole cmavo list as outside texts, where the Debian
package `lojban-common` installs them.

## Build and test

```sh
nim r koch check                                  # from repository root: every check
nim r koch test contributor/bangu/lojban_parser   # this project alone
nim r tools/build.nim lists                       # from project root: write both lists again
nim r tools/build.nim head                        # compare lists with lojban-common
nim r tools/build.nim system                      # print packages verbs and suites need
```

The build needs the compiler that `lojban_parser.nimble` pins, and the standard library alone.
The verbs `lists` and `head`, and the tests of outside texts, also need the Debian package
`lojban-common`, and `sha256sum` of `coreutils`. The verb `system` declares both.

## Pages

The project publishes no page.

## Status

The parser reads words by the rules of CLL alone. It reads each gismu and each cmavo by its form,
and each lujvo by its rafsi and hyphens, listed or not. It gives the selma'o of each cmavo that
the cmavo list holds, and splits cmavo run together into each cmavo. It renders a tanru as a
lujvo, and folds a tanru into tanru units. It reads a stream of text into its words, with its
pauses, commas and capitals.

The suites hold each part to CLL. The parser reads no grammar of prose, no cmene and no fu'ivla,
and no text that `zoi` or `la'o` quotes.

The project `lojban_tagger` keeps an earlier copy of these modules until #809 moves it onto this
parser. `selmaho.nim`, `lists/cmavo.nim` and `stream.nim` are new here, so it holds no copy of
them. Nothing here has been read line by line by a human.
