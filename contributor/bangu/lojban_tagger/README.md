# lojban_tagger

A system that tags anything with Lojban words and finds it again. A tag is a gismu, or a lujvo
made only of gismu. The parser reduces each tag to the gismu of its tanru. So a search for one
gismu finds every thing whose tag holds that gismu, alone or inside a lujvo. A search can also
use an English word. The keywords of the gismu list and the glosses of the lujvo list lead that
word to gismu.

```text
$ tagger tag notes/plan.md notci datnyvei
notes/plan.md    notci datnyvei
$ tagger find vreji
`vreji` reads as tag `vreji`.
notes/plan.md    notci datnyvei
$ tagger find file
`file` reads as English: datni+vreji (file (incl. computers)), datni+vreji+liste (file directory).
notes/plan.md    notci datnyvei
```

In this example, four spaces stand for the tab that separates a name from its tags.

## Authority

The project replicates the morphology of The Complete Lojban Language (CLL), by John Woldemar
Cowan, first edition, 1997. Chapter 3 gives the consonant clusters. Chapter 4 gives the shapes
of words, the rafsi, and the algorithms that make and score a lujvo. The suites carry the names
of those chapters, and each assertion cites its section.

The word lists come from the Logical Language Group, which placed them in the public domain.
The project commits them as typed Nim modules under `src/lojban_tagger/lists/`.

## Build and test

```sh
nim r koch check                                  # from repository root: every check
nim r koch test contributor/bangu/lojban_tagger   # this project alone
nim r tools/build.nim tagger                      # from project root: build binaries/tagger
nim r tools/build.nim lists                       # write both lists again from lojban-common
nim r tools/build.nim head                        # compare committed lists with lojban-common
```

The build and the tests need only the compiler that `lojban_tagger.nimble` pins. The verbs
`lists` and `head` also need the Debian package `lojban-common`, which `system` declares.

## Use

`tagger` keeps its index in one text file. The option `--index:<path>` names it. Otherwise the
variable `LOJBAN_TAGGER_INDEX` names it, and otherwise it is `lojban_tagger/index` under the
data directory of the user.

- `tag <name> <word>...` adds tags to a thing. A path, a URL or a title is a name.
- `untag <name> <word>...` removes tags.
- `find <term>...` prints each thing that every term finds. A term is a gismu, a lujvo or an
  English word.
- `show [<name>]` prints things with their tags.
- `read <word>...` explains a word: its rafsi, its gismu, its preferred form and its English.

## Pages

The project publishes no page.

## Status

The parser, the index, the search and the command line work, and the suites hold them to CLL.
Nothing here has been read line by line by a human.
