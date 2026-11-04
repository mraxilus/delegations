# lojban_parser

This project is a parser of lojban. It reads lojban words now, and it will read all lojban text
as the project grows. It reads a gismu, a cmavo or a lujvo as the words of its tanru, and it
refuses any other text with a reason. It renders a tanru back as the lujvo form that CLL
prefers. It also tells which cmavo bind each tanru unit.

```text
$ nim r --hints:off --path:src --eval:'import lojban_parser
let reading = readWord("bridyvalsi")
echo reading.tanru.toText, " renders as ", reading.tanru
echo readWord("mudsiclu").refusal, ": ", readWord("mudsiclu").detail'
bridi+valsi renders as brivla
Hyphen: mudysiclu
```

The reader reads `bridyvalsi` as the tanru of `bridi` and `valsi`, and renders the lujvo of lowest
score, `brivla`. It refuses `mudsiclu`, because CLL 4.11 requires a `y` there, and it names the
correct form.

## Authority

The project replicates The Complete Lojban Language (CLL), by John Woldemar Cowan, first
edition, 1997, from the Logical Language Group. The text is the first edition with errata, at
`lojban.github.io/cll`. Chapter 3 gives the letters and the consonant clusters. Chapter 4 gives
the shapes of words, the rafsi, and the algorithms that join and score a lujvo. Chapters 5, 7, 9,
12 and 15 tell which words each cmavo binds.

The suites carry the names of those chapters, and each assertion cites its section. The name of a
suite that CLL does not cover opens with `Internal:`.

The word lists come from the Logical Language Group, which placed them in the public domain. The
project commits them as typed Nim modules under `src/lojban_parser/lists/`.

## Build and test

```sh
nim r koch check                                  # from repository root: every check
nim r koch test contributor/bangu/lojban_parser   # this project alone
nim r tools/build.nim lists                       # from project root: write both lists again
nim r tools/build.nim head                        # compare committed lists with lojban-common
nim r tools/build.nim system                      # print packages that lists and head need
```

The build needs the compiler that `lojban_parser.nimble` pins, and the standard library alone.
The verbs `lists` and `head` also need the Debian package `lojban-common`, and `sha256sum` of
`coreutils`. The verb `system` declares both.

## Pages

The project publishes no page.

## Status

The parser reads words: each gismu and cmavo of the gismu list, and each lujvo of their rafsi.
It renders a tanru as a lujvo, and folds a tanru into tanru units. The suites hold each part to
CLL. The grammar of prose is to come, and so are names, borrowings, and text with commas and
capitals.

The project `lojban_tagger` keeps its own copy of these modules until #809 moves it onto this
parser. Nothing here has been read line by line by a human.
