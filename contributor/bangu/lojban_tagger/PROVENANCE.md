# Provenance

| Field   | Value |
|---------|-------|
| Harness | Claude Code |
| Author  | Claude |
| Date    | 2026-10-24 |
| Style   | CONSTITUTION.md and STYLE.md, followed. |
| Rules   | 50ecd726ec1a5108 |
| Review  | **Unreviewed.** Nothing here has been read line by line by a human. |

Origin: a contributor project, from the brief of the Architect. A tag is a gismu or a lujvo that
describes a thing which somebody tags. A search finds every tagged thing by a gismu, or by an
English word that leads to one. The system uses only the compound and parsable nature of Lojban.

The authority is The Complete Lojban Language (CLL), by John Woldemar Cowan, first edition, 1997,
from the Logical Language Group. The text used is the edition at `lojban.github.io/cll`, which is
the first edition with errata. Chapter 3 gives the consonant clusters, and chapter 4 gives the
shapes of words and the algorithm that makes a lujvo. Chapters 5, 7, 9, 12 and 15 tell which words
the cmavo SE, NAhE, NA, NU, `ke`, `ke'e`, `bo`, `kei` and `co` bind. The suites carry the names of
those chapters, and each assertion cites its section or example.

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

**The split agrees with strict reference parsers.** On 41 words read by camxes, vlatai, the
`is_valid_lujvo` of jbofihe and latkerlo-jvotci on 2026-10-24, the split finds one lujvo exactly
where CLL makes one. Where the strict tools disagree, as on `saircli` and `branlatu`, this project
follows CLL. Verified by `suites/test_references.nim`, which cites the deciding rule of each word.

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

**Rendering keeps every character of each field.** A string too long for one line is split after
a run of spaces, so its pieces join back into the field exactly. The definitions of `co'a`,
`co'u`, `sirji` and `za'o` hold runs of spaces, and the suite holds them against lines copied from
`gismu.txt`. Verified by `suites/test_lists.nim`, which also compares the whole committed list
with the installed file where `lojban-common` is present.

**The lujvo list writes a tanru in two notations, and the converter keeps both.** Most lines name
the parts in Lojban, after a colon. Other lines name them by English keywords of gismu, after
`#`, as `ci'erkei#system+play`. For those lines, the English index reads the gismu from the word
itself. Lines of other shapes are left out, and the rendered header counts them. The phrase in
place of a word, the line with no gloss, and the comma inside a tanru are such shapes.

## Tags

**A tag is the words of its tanru, never its spelling.** 4.5 says that the rafsi chosen do not
change a lujvo. So `brivla`, `brivalsi`, `bridyvla` and `bridyvalsi` read as one tag,
`bridi+valsi`. The order of the words stays, because a tanru is a modifier, then a head. `$`
renders the form that 4.12 scores lowest, and the first in order of choice on a tie. Verified by
`suites/test_tags.nim`.

**A lujvo that holds a rafsi of a cmavo is a tag, and keeps its cmavo.** The Architect ruled that
`selci'a` is a tag, which acts as `ciska` in search, and ranks first where somebody searches for
`selci'a` itself. So the tag keeps `se`, and `gismu` gives the words that search matches on.

A cmavo alone is no tag. Neither is a lujvo that ends in a cmavo, because 4.11 step 2 ends a tanru
in a gismu. A tag with no gismu would match every entity. Verified by `suites/test_tags.nim`.

**The reader folds case and drops commas, and it refuses `h`.** A capital marks irregular stress,
which no brivla carries (3.1, 3.9). A comma marks a syllable break, and no two words differ by a
comma alone (3.3). 3.3 also says that the letter `h` does not stand for the apostrophe. The fold of
case is a choice of this project, since CLL writes no capital in a brivla. Verified by
`suites/test_tags.nim`.

**A refusal says why.** The reader refuses with one reason from `Refusal`, and a detail that ends
in the offending text. Where the rafsi are known and only the hyphens are wrong, the detail is
the form that 4.11 gives, as `patyta'a` for `patta'a`.

## What cmavo bind

**A tag folds into units, and each unit is one word with the cmavo that bind it.** The cmavo that
bind come from CLL. SE binds the next brivla or equivalent unit (9.4), and NAhE binds close to its
brivla (15.4). A NU rafsi modifies the next unit alone (12.12). Every other cmavo binds nothing,
and stands as a unit of its own where it does not only group. Verified by `suites/test_units.nim`.

**`na` binds the whole tag.** 15.2 says that negation with `na` applies to an entire bridi, and
not to just part of a selbri. So an odd count of `na`, wherever it stands, folds as one `na` before
a group of the whole tag. An even count folds as none, because adjacent negations cancel out
(15.2). Verified by `suites/test_units.nim`.

**A run of SE that binds one unit composes into one conversion.** The inner conversion applies
first (9.4), so `te se ciska` puts the third place of `ciska` first. Two `se` cancel (12.11), so
`se se ciska` folds to `ciska`. Other cmavo keep their order against the conversions. Verified by
`suites/test_units.nim`, over every chain of up to four SE, and by `se na'e se ciska`.

**A group of one unit is that unit.** `ke` opens a group, and `ke'e` or the end of the tag closes
it (5.5). A cmavo before `ke` binds the whole group, as in `selkemdzukla` (12.11). So `se ke ciska`
folds to `se ciska`, and `selkemci'avei` holds no unit `se ciska`. Verified by
`suites/test_units.nim`, over every chain of up to two of `se`, `te`, `na'e` and `nu`.

**A cmavo that only groups drops.** The rank reads no grouping that no cmavo binds. So the `ke` and
`ke'e` of a group that no cmavo binds drop, and `kemdatnyvei` folds as `datnyvei`. A group whose
cmavo cancel binds nothing, so it drops too. `bo` only groups (5.3), and drops. Verified by
`suites/test_units.nim`.

**`kei` closes an abstraction.** Rule 152 of 21.2 ends a NU with `kei`. So the fold reads `kei` as
a `ke'e` that closes a `ke` after its NU, and `nu citka gasnu kei klama` abstracts two units. After
one unit, that group holds one unit, as 12.13 says of `nunctikezgau`. A `kei` with no NU before it
drops. Verified by `suites/test_units.nim`.

**No group holds `co`.** 5.8 puts a `ke'e` before `co` for each group that is open there. Cost:
`co` inverts the order of a tanru (5.8), but the fold keeps the written order. So the rank does not
see a run across `co`. Verified by `suites/test_units.nim`.

**A lujvo leaves `ke` out in two places that CLL names.** Two SE in a row read as SE `ke` SE
(12.11). So the first one converts the rest of the tag, up to a `ke'e` that closes it. A `ke'e`
that closes nothing implies a `ke` after the nearest run of binding cmavo with two units or more
after it (15.4). With no such run, the `ke'e` only groups, and it drops. Verified by
`suites/test_units.nim`.

Cost: the fold reads every tag as a lujvo, so a tag read from tanru text follows 12.11 too. Cost: in
a run of `na'e se` before such a group, both cmavo bind the group, where 15.4 names the negation
alone.

**CLL spells one example with a rafsi that the list gives to another gismu.** 15.4 writes
`na'e ke sutra cadzu ke'e klama` as `nalsu'adzuke'ekla`. The list gives `su'a` to `stura`, and
gives `sutra` only `sut`, so the reader reads that example as `stura`. The suite holds the shape of
the example, which the choice of gismu does not change. Verified by `suites/test_units.nim`,
Section 15.4.

13.13 makes a lujvo with `pev` figurative as a whole, and 5.13 gives a tense the whole bridi. The
fold binds nothing to them. Cost: `pevyselci'a` ranks for `selci'a`, although `pe'a` makes it
figurative. Verified by `suites/test_units.nim` and `suites/test_search.nim`.

Rule 152 of 21.2 makes a number and its MOI one tanru unit, but the fold keeps each digit as a unit
of its own. Cost: the term `pavmomci'a` ranks the tag `relpavmomci'a`, whose number is 21, not 1.
Verified by hand with `tagger find` on 2026-10-25. That such tags are rare is assumed.

JAI binds as SE does (5.11), but the list gives `jai` no rafsi, so no tag holds it. CLL 12.12 gives
`jai` the rafsi `jax`, which the list does not hold. A static check in `units.nim` fails the build
where the list gains `jai`.

## English

**English leads to gismu through keywords and glosses.** The keyword and the hint of each gismu
lead to that gismu. The gloss of each lujvo leads to the words of its tanru, cmavo included, and
search matches them on their gismu. The Architect chose these sources. Rejected: the words of the
definitions, which lead `book` to `papri` and to every place structure that mentions a book.
Verified by `suites/test_english.nim`.

**Seventeen lines of the lujvo list disagree with their own spelling.** Thirteen name the earlier
owner of a rafsi, as `mumcte` names `re` where the list now gives `mum` to `mu`. Four name a
compound cmavo or an English word, as `dazmoipru` names `da'amoi`. A meaning takes the parts that
the line names, and the suite pins each such line by name, so a change to the list shows.

**Function words lead nowhere.** The tokenizer folds case, splits at each character outside `a`
to `z`, and drops tokens of one letter. It also drops the words of `WORDS_FUNCTION`, such as
`the` and `of`, so a phrase is never narrowed by glue. The search for those words is binary, so a
static check fails the build where the list falls out of order. Cost: the list is a judgement, not
a standard, and a word that it holds cannot be searched alone.

## Index and search

**The index is one text file that its reader types.** A header line names the format and its
version. Each other line holds a name, a tab, then each tag as a tanru, as `datni+vreji`. The
reader refuses the whole file at the first bad line, and names the line. A writer that kept part
would drop the rest of the index on its next write.

Adding no tag changes nothing, so no entity is ever left without a tag. Verified by
`suites/test_index.nim`.

**A term becomes sets of gismu, and an entity matches where it holds one set whole.** A Lojban
term gives one set, the gismu of its tanru. An English term gives one set for each meaning that it
leads to. Every term of a query must match. So `vreji` finds a thing tagged `datnyvei`, and
`datnyvei` finds what `datni` and `vreji` tag together.

Cost: order and relation are lost, so
`patfu mamta` and `mampa'u` find each other. Verified by `suites/test_search.nim`.

**A Lojban term that holds a cmavo ranks first each entity with a tag that holds its units
unbroken.** The Architect ruled that a search for `selci'a` lists first each thing with a tag that
holds `se` right before `ciska`, wherever the pair stands. The net result of the cmavo around the
pair decides, and a longer term ranks by an unbroken run too. A search for `ciska` gives no
priority. So the search finds what the gismu find. Then it puts first each entity with a tag whose
units hold the units of the term in order, with nothing between them.

So `selci'a`, `selci'avei` and `veirselci'a` rank for `selci'a`. `selselci'a`, `terselci'a` and
`nalselci'a` do not, because their cmavo convert or negate `se ciska`. A term whose cmavo all fold
away ranks nothing, as a gismu does. Each of the two tiers keeps the order of the index. An English
term ranks nothing, because the ruling names a term typed in Lojban. Verified by
`suites/test_search.nim`.

A group that cmavo bind changes a run inside it in three ways, and then the run does not rank. A
run that ends where the group ends holds its head, which a conversion converts (5.11) and an
abstraction turns to an event (12.12). A negation denies every part of the group (15.4). A group
that the run leaves open must end where the run ends. Verified by `suites/test_units.nim` and
`suites/test_search.nim`.

So the term `selci'avei` does not rank `selselci'avei`, which 12.11 reads as the converse of
`selci'avei`. The term `selci'a` does not rank `selkemveiselci'a` or `nalkemselci'avei`. A modifier
inside a converted group keeps its places, so the term `selci'a` ranks `selselci'avei`.

The test is a run of units, and not a part of the grouped tanru, because a lujvo often leaves its
grouping out. Lujvo makers often leave `ke` out (4.10, 12.11), so the rafsi hold only the run.
Cost: the term `selci'avei` ranks a tag of `vreta se ciska vreji`, where `vreta` groups with
`se ciska` first (5.3). Verified by `suites/test_search.nim`.

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
2026-10-25.

- **Compile of the English index.** Each part of each lujvo line is found by binary search. The
  front end of `nim check app/tagger.nim` took 2.4 s and 2.9 s over two runs. A copy that maps
  the whole list again for each part never finishes. The compile-time VM stops it at its limit of
  10,000,000 iterations, so that form is a trap, not a slower choice.
- **Release build.** `nim c -f -d:release app/tagger.nim` took between 5.6 s and 6.5 s over three
  runs.
- **Suites.** `nim c -r -d:testing tests/test_suites.nim` compiled and ran every suite in 26.5 s
  and 28.8 s, over two runs from an empty cache.
- Search and reading are unmeasured. The tool reads and writes the whole index for each command.

## Open questions

- **Stemming.** `files` finds nothing that `file` finds. A stemmer would widen the English, at the
  cost of a rule that no standard of the project gives.
- **The 4-letter rafsi `brod`.** Five gismu share it, and CLL does not say which one it names. The
  reader refuses it as ambiguous. `brodi`, `brodo` and `brodu` have no short rafsi. So a tag
  that holds one of them before its head renders with `brod`, and does not read back.
- **English terms and rank.** An English term whose meaning holds a cmavo, such as a gloss of
  `selci'a`, ranks nothing, since the ruling names a term typed in Lojban. Whether such a meaning
  should rank its tag first is not decided.
