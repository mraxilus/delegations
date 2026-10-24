# Provenance

| Field   | Value |
|---------|-------|
| Harness | Claude Code |
| Author  | Claude |
| Date    | 2026-10-24 |
| Style   | CONSTITUTION.md and STYLE.md, followed. |
| Rules   | 0ff7fe750293e4e9 |
| Review  | **Unreviewed.** Nothing here has been read line by line by a human. |

Origin: a contributor project, from the brief of the Architect. A tag is a gismu, or a lujvo made
only of gismu, that describes a thing which somebody tags. A search finds every tagged thing by a
gismu, or by an English word that leads to one. The system uses only the compound and parsable
nature of Lojban.

The authority is The Complete Lojban Language (CLL), by John Woldemar Cowan, first edition, 1997,
from the Logical Language Group. The text used is the edition at `lojban.github.io/cll`, which is
the first edition with errata. Chapter 3 gives the consonant clusters, and chapter 4 gives the
shapes of words and the algorithm that makes a lujvo. The suites carry the names of those
chapters, and each assertion cites its section or example.

## Clusters and forms

**The rules of CLL are data, and the judgements derive from them.** `clusters.nim` holds the four
rules of 3.6 as sets, and builds the table of permissible pairs at compile time. The 48 initial
pairs of 3.7 are a list, because no rule derives them. A static check holds that each initial
pair is also a permissible pair, so the two sections can never disagree in the code. Verified by
`suites/test_clusters.nim`, over every pair and every triple of the seventeen consonants.

**Forms use the notation of CLL as names.** `Form.Cvc`, `Form.Ccvcv` and the rest spell the C and
V notation of 4.6, because Article III.1 makes canonical notation the spelling. A form judges
letters alone and never asks the dictionary. So morphology and vocabulary stay separate, and
each one is testable alone.

CV'V and the diphthong CVV share `Form.Cvv`, since both take every
position that CVV takes. Only the score of 4.12 tells them apart, and it reads the apostrophe off
the letters. Verified by `suites/test_forms.nim`.

## Lujvo

**The join is the algorithm of 4.11, and the split is its inverse.** `joinRafsi` applies steps 4a
to 4c, then the tosmabru test of step 5. `splitLujvo` tries every segmentation that the forms
allow, and keeps only those that `joinRafsi` joins back into the word, letter for letter. So a
split followed by a join is the identity by construction. 4.11 says that a hyphen the algorithm
does not require is illegal, so this comparison is the whole test of hyphens.

Rejected: a check
of each junction by local rules, which would state the algorithm twice. Verified by
`suites/test_lujvo.nim`, over the vectors of 4.5, 4.6, 4.11, 4.12 and 4.13, and over a seeded
sample of random rafsi sequences.

**The tosmabru test reads its joints up to the first `y`.** The joints are the consonant pairs at
the junctions of the leading CVC rafsi, and in the medial pair of a final CVCCV. Where all of them
are initial pairs, one `y` goes after the first rafsi. No example of CLL exercises step 5, so the
suite holds it to lujvo of the list that need it, such as `xasymabru` and `cibylajyterkruca`. A
reading over the whole word fails on four of those words, so the list supports this reading.
Verified by `suites/test_lujvo.nim`.

**A junction that forms `ndj`, `ndz`, `ntc` or `nts` takes `y`.** 4.11 step 4b names only an
impermissible pair, and CLL says nothing of these triples at a junction. 3.7 forbids them in
every word but a name, and the list writes `kanydzu` and `penydjuxa'a`. The list holds no lujvo
with one of these triples unbroken. Cost: the join holds one rule more than 4.11 states. Verified
by `suites/test_lujvo.nim`, in the suite `Internal: Convention`.

**The score is that of 4.12, and the lowest score is the preferred form.** The suite holds the
scores of 4.12 and 4.13 exactly. CLL misstates one part of one score: 4.13 gives `gerzda` a V of 3,
but the word has two vowels. The total that CLL gives, 5878, is right, and the suite holds the
total. Verified by `suites/test_lujvo.nim`.

## Word lists

**The lists are the public-domain lists of the Logical Language Group, as Debian packages them.**
The source is `gismu.txt` and `lujvo.txt` of the package `lojban-common`, version 1.5+dfsg.1-4.
The header of `gismu.txt` dates it 9/26/94. The group placed this material in the public domain.
It asks that a derived work state the facts of its derivation and give the address of the group.
The header of each rendered module does both.

**The lists are committed as typed Nim, and a converter renders them.** `nim r tools/build.nim
lists` reads both files, checks the SHA-256 of each against a pin in `tools/lists.nim`, and
writes `src/lojban_tagger/lists/gismu.nim` and `lujvo.nim`. The compiler checks each field
against the types of `entries.nim`.

Rejected: the text files as they are, because the checker
reads no `.txt`. Rejected: JSON, which the Architect asked to stop using by default, and which
checks no field. Rejected: a read of the package at compile time, because the CI job `test`
installs no package. The Architect ruled that the lists change seldom, so a commit is right.

**A daily `head` verb watches the source.** It renders both modules again from the installed
package, and compares the digests and the text with what is committed. Where Debian moves a list,
`head` fails, and `lists` refuses until somebody moves the pin. Verified by hand on this machine,
2026-10-24: `head` exits 0 against `lojban-common` 1.5+dfsg.1-4.

**The converter keeps the fields that tagging, search and `read` use.** From `gismu.txt` it keeps
the word, the rafsi, the keyword, the hint and the definition, by fixed columns. The columns were
measured over every line, and no character falls between two fields. From `lujvo.txt` it keeps the
word, the parts and the gloss. It drops the textbook lesson, the frequency, the notes and the
place structures.

Cost: a verb that wants one of those changes the converter and both lists in
one commit. Verified by `suites/test_lists.nim`, on lines copied from both files.

**The lujvo list writes a tanru in two notations, and the converter keeps both.** Most lines name
the parts in Lojban, after a colon. Other lines name them by English keywords of gismu, after
`#`, as `ci'erkei#system+play`. For those lines, the English index reads the gismu from the word
itself. Lines of other shapes are left out, and the rendered header counts them. The phrase in
place of a word, the line with no gloss, and the comma inside a tanru are such shapes.

## Tags

**A tag is its gismu, never its spelling.** 4.5 says that the rafsi chosen do not change a lujvo.
So `brivla`, `brivalsi`, `bridyvla` and `bridyvalsi` read as one tag, `bridi+valsi`. The order of
the gismu stays, because a tanru is a modifier, then a head. `$` renders the form that 4.12 scores
lowest, and the first in order of choice on a tie. Verified by `suites/test_tags.nim`.

**A lujvo that holds a rafsi of a cmavo is refused.** The brief admits a lujvo made of gismu alone.
The reader still knows every rafsi of a cmavo that the gismu list carries. So the refusal names the
rafsi and its cmavo, as `sel (se)`, rather than calls the rafsi unknown. Cost: `selci'a`, and every
lujvo that converts a place with `se`, cannot be a tag. This choice waits on the Architect.

**The reader folds case and drops commas, and it refuses `h`.** A capital marks irregular stress,
which no brivla carries (3.1, 3.9). A comma marks a syllable break, and no two words differ by a
comma alone (3.3). 3.3 also says that the letter `h` does not stand for the apostrophe. The fold of
case is a choice of this project, since CLL writes no capital in a brivla. Verified by
`suites/test_tags.nim`.

**A refusal says why.** The reader refuses with one reason from `Refusal`, and a detail that ends
in the offending text. Where the rafsi are known and only the hyphens are wrong, the detail is
the form that 4.11 gives, as `patyta'a` for `patta'a`.

## English

**English leads to gismu through keywords and glosses.** The keyword and the hint of each gismu
lead to that gismu. The gloss of each lujvo leads to the gismu of its tanru. The Architect chose
these sources. Rejected: the words of the definitions, which lead `book` to `papri` and to every
place structure that mentions a book. Verified by `suites/test_english.nim`.

**Function words lead nowhere.** The tokenizer folds case, splits at each character outside `a`
to `z`, and drops tokens of one letter. It also drops the words of `WORDS_FUNCTION`, such as
`the` and `of`, so a phrase is never narrowed by glue. Cost: the list is a judgement, not a
standard, and a word that it holds cannot be searched alone.

## Index and search

**The index is one text file that its reader types.** A header line names the format and its
version. Each other line holds a name, a tab, then each tag as a tanru, as `datni+vreji`. The
reader refuses the whole file at the first bad line, and names the line. A writer that kept part
would drop the rest of the index on its next write. Verified by `suites/test_index.nim`.

**A term becomes sets of gismu, and an entity matches where it holds one set whole.** A Lojban
term gives one set, the gismu of its tanru. An English term gives one set for each meaning that it
leads to. Every term of a query must match. So `vreji` finds a thing tagged `datnyvei`, and
`datnyvei` finds what `datni` and `vreji` tag together.

Cost: order and relation are lost, so
`patfu mamta` and `mampa'u` find each other. Verified by `suites/test_search.nim`.

## Command line

**The verbs are pure functions, and one thin program wires them to a file.** `commands.nim`
answers each verb from its arguments and the index read before it. `app/tagger.nim` reads the
file, calls `run`, and writes the file back where the index changed. The write goes to a sibling
file that is then renamed over the index, so an interrupted write leaves no half index. Cost: two
runs at one time race, and the last rename wins. Verified by `suites/test_commands.nim`, and by
`suites/test_tagger.nim`, which builds the binary and drives it.

**The index path comes from the user, never from this machine.** The option `--index:<path>`
wins, then the variable `LOJBAN_TAGGER_INDEX`, then `lojban_tagger/index` under the data directory
of XDG. An absent file reads as an empty index, so the first `tag` makes it.

## Tests

**One stub runs every suite as one program.** `tests/test_suites.nim` imports each file of
`tests/suites/`, in the shape that STYLE.md section 6 gives. Each suite still runs alone. Suites
that CLL covers carry the names of its chapters. The others open with `Internal:`, so the run
shows where the authority stops.

## Toolchain

**The compiler is pinned exactly**: `requires "nim == 2.2.12"` in `lojban_tagger.nimble`. The
project needs the standard library alone, so it carries no lock. The verbs `lists` and `head` also
need `lojban-common` and `sha256sum`, which the verb `system` declares. A system package carries
no pin, so their version is what the machine has.

## Figures

Each figure below comes from an Intel Xeon at 2.10 GHz with four cores, Nim 2.2.12, on
2026-10-24.

- **Compile of the English index.** The front end of `nim check app/tagger.nim` took 7.3 s and
  7.2 s where the list of words was mapped again for each part of each lujvo. It took 2.5 s and
  2.4 s where the map is made once. The pair is two rounds of the same probe, run in turn.
- **Release build.** `nim c -f -d:release app/tagger.nim` took between 5.2 s and 6.1 s over three
  runs.
- Search and reading are unmeasured. The tool reads and writes the whole index for each command.

## Open questions

- **Stemming.** `files` finds nothing that `file` finds. A stemmer would widen the English, at the
  cost of a rule that no standard of the project gives.
- **The 4-letter rafsi `brod`.** Five gismu share it, and CLL does not say which one it names. The
  reader refuses it as ambiguous. `brodi`, `brodo` and `brodu` have no short rafsi. So a tag
  that holds one of them before its head renders with `brod`, and does not read back.
- **The definition of `xabju`.** The check for machine paths reads `nest/home/abode` as a path.
  So no push can land until a curator changes the check, or the Architect picks a workaround.
