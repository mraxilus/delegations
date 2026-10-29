# lojban_tagger

A system that tags anything with Lojban words and finds it again. A tag is a gismu or a lujvo.
The parser reduces each tag to the words of its tanru, and a search matches on its gismu. So a
search for one gismu finds every thing whose tag holds that gismu, alone or inside a lujvo. A
search for a lujvo with a cmavo, such as `selci'a`, lists first each thing whose tag holds it,
net of the cmavo around it. So `selci'avei` comes first, but `selselci'a` does not, because its
two `se` cancel.

A search can also use an English word. The keywords of the gismu list and the glosses of the
lujvo list lead that word to gismu.

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
of words, the rafsi, and the algorithms that make and score a lujvo. Chapters 5, 7, 9, 12 and 15
tell which words the cmavo of a tag bind. The suites carry the names of those chapters, and each
assertion cites its section.

The word lists come from the Logical Language Group, which placed them in the public domain.
The project commits them as typed Nim modules under `src/lojban_tagger/lists/`.

## Build and test

```sh
nim r koch check                                  # from repository root: every check
nim r koch test contributor/bangu/lojban_tagger   # this project alone
nim r tools/build.nim tagger                      # from project root: build binaries/tagger
nim r tools/build.nim suggester                   # build binaries/suggester, with TLS
nim r tools/build.nim examples                    # write worked examples of suggester
nim r tools/build.nim lists                       # write both lists again from lojban-common
nim r tools/build.nim head                        # compare committed lists with lojban-common
```

The build and the tests need only the compiler that `lojban_tagger.nimble` pins. The verbs
`lists` and `head` also need the Debian package `lojban-common`. `suggester` also needs
`libssl3` and `ca-certificates` when it runs. The verb `system` declares all of them.

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

## Suggest

`suggester` asks a language model service for one tag of a text, or of the page at a URL. It
prints the tag alone, so `tagger tag` can take it:

```sh
tagger tag notes/plan.md "$(binaries/suggester "$(cat notes/plan.md)")"
page=https://www.gutenberg.org/ebooks/11
tagger tag "$page" "$(binaries/suggester "$page")"
```

The model names the words of a tanru from the word lists. The tool checks each word against
the lists, and builds the lujvo that CLL 4.12 prefers. It refuses an answer that does not read
back as the same tag. A text that already reads as a tag asks no service, and needs no key.

Usage: `suggester [--record:<directory>|--replay:<directory>] <text>...|<url>`

| Variable | Default | Effect |
|---|---|---|
| `LOJBAN_TAGGER_SERVICE` | `claude` | `claude`, `openrouter`, or `chat` for another server |
| `LOJBAN_TAGGER_ENDPOINT` | the URL of the service | `chat` needs one |
| `LOJBAN_TAGGER_MODEL` | `claude-opus-5-5`, or `anthropic/claude-opus-5.5` | `chat` needs one |
| `LOJBAN_TAGGER_EFFORT` | `medium` | `low`, `medium`, `high`, `xhigh` or `max` |
| `LOJBAN_TAGGER_API_KEY` | none | The key, read first |

Where `LOJBAN_TAGGER_API_KEY` is unset, `claude` reads `ANTHROPIC_API_KEY`, and `openrouter`
reads `OPENROUTER_API_KEY`. The report names the variable that it read, and never the key. Get
a Claude key at `https://platform.claude.com/settings/keys`, and an OpenRouter key at
`https://openrouter.ai/settings/keys`. Put the key in the environment, never on the command
line.

- `--record:<directory>` writes each reply to a file. A later run replays that file, so the
  same request never pays twice.
- `--replay:<directory>` reads every reply from files. It needs no key and no network.
- `nim r tools/build.nim examples` writes worked examples to `build/examples/`, and prints the
  command that replays each one. Their replies are documented shapes, not live replies.

## Pages

The project publishes no page.

## Status

The parser, the index, the search and the command line work, and the suites hold them to CLL.
`suggester` works on recorded replies, and has read no live reply yet. Nothing here has been
read line by line by a human.
