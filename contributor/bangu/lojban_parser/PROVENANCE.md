# Provenance

| Field   | Value |
|---------|-------|
| Harness | Claude Code |
| Author  | Claude |
| Date    | 2026-11-04 |
| Style   | CONSTITUTION.md and STYLE.md, followed. |
| Rules   | 01a086eda78015fd |
| Review  | **Unreviewed.** Nothing here has been read line by line by a human. |

Origin: a contributor project, split from `lojban_tagger` at the request of the Architect. The
Architect asked for a project with one task alone: a complete parser of lojban, which reads any
valid lojban word or prose. The Architect also asked that the tagger use this parser, which
stands apart from it. This first version takes the parsing part of the tagger, and it holds no
grammar of prose yet.

Until #809 moves the tagger onto this parser, `lojban_tagger` keeps its own copy of each module
here. The header of each copied module names its sibling there, as Article II.9 asks, and
`tools/lists.nim` names the siblings of the lists that it renders. A fix to one copy is finished
only when the other is checked.

The authority is The Complete Lojban Language (CLL), by John Woldemar Cowan, from the Logical
Language Group. This project reads the first edition, 1997, with its errata, at
`lojban.github.io/cll`. Its chapter 3 gives the letters and the consonant clusters. Its chapter 4
gives the shapes of words, the rafsi, and the algorithms that join and score a lujvo. Chapters 5,
7, 9, 12 and 15 tell which words a cmavo binds, and 21.2 gives the rule of a tanru unit.

The name of the language is lowercase, as lojban, as the Architect ruled for `lojban_tagger`. In
lojban, a capital letter marks irregular stress (CLL 3.9), and the name has none. A title keeps
its capitals, and so do the word lists, the notice of the group, and a name in code, such as
`Notation.Lojban`. Verified by hand with `grep` over this project, 2026-11-04.

## Clusters and forms

**Each judgement derives from rules of CLL that the code holds as data.** `clusters.nim` holds the
four rules of 3.6 as sets, and builds the table of permissible pairs from them at compile time.
The 48 initial pairs of 3.7 are a list, since no rule derives them. A static check holds that each
initial pair is also permissible, so the code can never set the two sections against each other.
Verified by `suites/test_clusters.nim`, over each pair and each triple of the seventeen
consonants.

**The names of the forms are the notation of CLL.** `Form.Cvc`, `Form.Ccvcv` and the other members
spell the C and V notation of 4.6, since Article III.1 makes the canonical notation the spelling.
A form judges the letters alone, and never asks the dictionary. So the shapes of words and the
vocabulary stay apart, and a test drives each one alone.

`Form.Cvv` serves both CV'V and the diphthong CVV, because the two take the same positions. The
score of 4.12 alone tells them apart, and it reads the apostrophe from the letters. Verified by
`suites/test_forms.nim`.

## Lujvo

**The join is the algorithm of 4.11, and the split is its inverse.** `joinRafsi` applies steps 4a
to 4c, then the tosmabru test of step 5. `splitLujvo` tries each segmentation that the forms
allow. It keeps a segmentation only where `joinRafsi` joins it back into the same word, letter
for letter. So a split, then a join, gives the word again, by construction. 4.11 makes a hyphen
illegal where the algorithm does not require it, so this comparison tests every hyphen.

Rejected: a check of each junction by local rules, which would state the algorithm twice.
Verified by `suites/test_lujvo.nim`, over the vectors of 4.5, 4.6, 4.11, 4.12 and 4.13, and over a
seeded sample of random sequences of rafsi.

**The tosmabru test reads its joints up to the first `y`.** A joint is a consonant pair at a
junction after a leading CVC rafsi, or the medial pair of a final CVCCV. Where each joint is an
initial pair, one `y` goes after the first rafsi. No example of CLL exercises step 5, so the suite
holds it to lujvo of the list that need it, such as `xasymabru` and `cibylajyterkruca`. A reading
over the whole word fails on four of those words, so the list supports this reading. Verified by
`suites/test_lujvo.nim`.

**A junction that makes `ndj`, `ndz`, `ntc` or `nts` takes `y`.** 4.11 step 4b names only an
impermissible pair, and CLL says nothing of these triples at a junction. 3.7 forbids them in each
word but a name, and the list writes `kanydzu` and `penydjuxa'a`. No lujvo of the list holds one
of these triples unbroken. Cost: the join holds one rule more than 4.11 states. Verified by
`suites/test_lujvo.nim`, in the suite `Internal: Convention`.

**The score is that of 4.12, and the form of lowest score is the preferred form.** The suite holds
the scores of 4.12 and 4.13 exactly. One part of one score in CLL is wrong. 4.13 gives `gerzda` a
V of 3, but the word has two vowels. The total of 5878 that CLL gives is right, and the suite holds
that total. Verified by `suites/test_lujvo.nim`.

**The split agrees with strict reference parsers.** On 41 words, the split finds one lujvo
exactly where CLL makes one. The verdicts on those words are those of camxes, vlatai, the
`is_valid_lujvo` of jbofihe and latkerlo-jvotci, read on 2026-10-24 for `lojban_tagger`. Where
the strict tools disagree, as on `saircli` and `branlatu`, this project follows CLL. Verified by
`suites/test_references.nim`, which cites the deciding rule of each word. No tool ran again for
this project.

## Word lists

**The word lists are those of the Logical Language Group, in the Debian package `lojban-common`,
version 1.5+dfsg.1-4.** The files are `gismu.txt` and `lujvo.txt`, and the header of `gismu.txt`
dates the list 9/26/94. The group placed this material in the public domain. It asks that a
derived work state how it was derived, and give the address of the group. The header of each
rendered module does both.

**A converter renders each list as typed Nim, and the project commits the result.** The verb
`nim r tools/build.nim lists` reads both files and checks the SHA-256 of each against its pin in
`tools/lists.nim`. Then it writes `src/lojban_parser/lists/gismu.nim` and `lujvo.nim`. Each is a
module of typed constants whose header names that verb, as the rule of data asks (CONTRIBUTOR.md,
Data). The compiler checks each field against the types of `entries.nim`.

The rendered header names no project, so the converter here and the converter of
`lojban_tagger` write the same bytes. So the committed lists are those of `lojban_tagger`, byte
for byte. Verified by hand with `cmp` against the lists of `lojban_tagger` at `aaf51e28`,
2026-11-04. The header of `tools/lists.nim` names both lists as siblings, since a rendered module
holds what the converter writes, and no line by hand.

**A field that each line holds takes `{.requiresInit.}`, so an entry without one does not
compile.** The marked fields are the word, the keyword and the definition of a gismu. For a lujvo,
they are the word, the notation, the parts and the gloss. The rafsi and the hint can be empty, so
they stay unmarked. The zero value of the notation is `Lojban`, so an entry with no notation would
give the notation of lojban to an English line. Verified by `suites/test_lists.nim`, which holds
that an entry without each marked field does not compile.

Cost: `mapIt` declares `var it`, so it does not compile over an entry, and the suites read fields
by `collect` or by a loop. A seq of entries gives the warnings `UnsafeSetLen` and `UnsafeDefault`
on Nim 2.2.12 and 2.4.0. `newSeq` of entries also gives `ProveInit`, which Nim says will become an
error, so the suites use `newSeqOfCap`. Verified by hand on both compilers, 2026-11-04, with
`nim check` of the stub, and with a probe of `mapIt` and `newSeq` over an entry.

Rejected: the text files as they are, because the checker reads no `.txt`. Rejected: JSON, which
checks no field, and which the Architect asked to stop using by default. Rejected: a read of the
package at compile time, because the CI job `test` installs no package. The Architect ruled for
`lojban_tagger` that the lists change seldom, so a commit is right, and the same holds here.

**The daily `head` verb watches the source.** It renders both modules again from the installed
package, and compares the digests and the text with the committed modules. Where Debian moves a
list, `head` fails, and `lists` refuses until somebody moves the pin. Verified by hand,
2026-11-04: `nim r tools/build.nim head` exits 0 against `lojban-common` 1.5+dfsg.1-4.

**The converter keeps the fields that this project and the tagger read.** From `gismu.txt` it keeps
the word, the rafsi, the keyword, the hint and the definition, by fixed columns. The columns hold
over every line of the file, and no character falls between two fields. From `lujvo.txt` it keeps
the word, the notation, the parts and the gloss. It drops the textbook lesson, the frequency, the
notes and the place structures.

Cost: code that wants one of the dropped fields changes the converter and both lists in one
commit. Verified by `suites/test_lists.nim`, which reads lines copied from both files, and which
compares each committed list with the installed file where `lojban-common` is present.

**A rendered module keeps every character of each field.** A string too long for one line splits
after a run of spaces, so its pieces join back into the field exactly. The definitions of `co'a`,
`co'u`, `sirji` and `za'o` hold runs of spaces, and the suite holds them against lines copied from
`gismu.txt`. Verified by `suites/test_lists.nim`.

**The lujvo list writes a tanru in two notations, and the converter keeps both.** Most lines name
the parts in lojban, after a colon. Other lines name the parts by English keywords of gismu, after
`#`, as `ci'erkei#system+play` does. For such a line, `suites/test_lujvo.nim` reads the word and
holds each of its words to the keyword that the line names.

The converter leaves out lines of other shapes, and the rendered header counts them. Such a shape
is a phrase in place of a word, a line with no gloss, or a comma inside a tanru. Verified by
`suites/test_lists.nim`.

## Tanru

**A word reads as the words of its tanru, never as its spelling.** 4.5 says that the rafsi
chosen do not change a lujvo. So `brivla`, `brivalsi`, `bridyvla` and `bridyvalsi` read as one
tanru, `bridi+valsi`. The order of the words stays, because a tanru is a modifier, then a head.
`$` renders the form that 4.12 scores lowest, and on a tie the first in the order of choice.
Verified by `suites/test_tanru.nim`.

**A rafsi of a cmavo stands for that cmavo, and the tanru keeps it.** So `selci'a` reads as
`se+ciska`, which is not `ciska`, because `se` converts it (9.4). The reader refuses a lujvo whose
last rafsi stands for a cmavo, since 4.11 step 2 takes that rafsi from the final gismu. A gismu
or cmavo of the list reads as itself, as a tanru of one word. Verified by
`suites/test_tanru.nim`.

The reader holds no policy of the tagger. Whether a cmavo alone can be a tag, and which words a
search matches on, are choices of `lojban_tagger`, and they stay there.

**The reader reads canonical form alone: lowercase letters and the apostrophe, as they are
written.** It refuses each other character as `Refusal.Letter`, a space at either end included.
CLL writes a capital only for the stress of a name (3.1), and a comma for a syllable break (3.3).
The reader reads no name and no written syllable yet, so it refuses both. 3.3 also says that the
letter `h` does not stand for the apostrophe, so the reader refuses `h`. Verified by
`suites/test_tanru.nim`, in Section 3.3 and in the suite `Internal: Reading`.

Cost: CLL text that writes a comma or a capital inside a word is refused, as `sai,r,goi` and
`DI,ky,jvo` of 3.9 are. The test `Section 3.9` of `suites/test_tanru.nim` is a placeholder that
reports itself as skipped until the reader reads such text (Article IX.9).

**A refusal says why.** The reader refuses with one reason from `Refusal`, and a detail that ends
in the offending text. A character outside the letters is named whole, so the detail of UTF-8
text stays UTF-8. Where the rafsi are known and only the hyphens are wrong, the detail is the
form that 4.11 gives, as `patyta'a` for `patta'a`. Verified by `suites/test_tanru.nim`.

**`readTanru` reads the words of a tanru joined by `+`, as the lujvo list writes them.** It
refuses text where any part is unlisted, or where two words or more end in a cmavo. So it reads
back each tanru that the reader gives, and `toText` writes that tanru again. Verified by
`suites/test_tanru.nim`.

## What cmavo bind

**A tanru folds into tanru units, and each tanru unit is one word with the cmavo that bind it.**
The grammar of CLL gives that name (21.2, rule 152), which the Architect selected for
`lojban_tagger` (#768). SE binds the next brivla or "equivalent unit" (9.4), and NAhE binds close
to its brivla (15.4). A NU rafsi modifies the next tanru unit alone (12.12). Each other cmavo binds
nothing, and stands as a tanru unit of its own where it does more than group. Verified by
`suites/test_tanru_units.nim`.

**`na` binds the whole tanru.** 15.2 says that negation with `na` applies to an entire bridi, and
not to just part of a selbri. So an odd count of `na`, wherever it stands, folds as one `na`
before a group of the whole tanru. An even count folds as none, because adjacent negations cancel
out (15.2). Verified by `suites/test_tanru_units.nim`.

**A run of SE that binds one tanru unit composes into one conversion.** The inner conversion
applies first (9.4), so `te se ciska` puts the third place of `ciska` first. Two `se` cancel
(12.11), so `se se ciska` folds to `ciska`. Other cmavo keep their order against the conversions.
Verified by `suites/test_tanru_units.nim`, over each chain of up to four SE, and by
`se na'e se ciska`.

**A group of one tanru unit is that tanru unit.** `ke` opens a group, and `ke'e` or the end of
the tanru closes it (5.5). A cmavo before `ke` binds the whole group, as in `selkemdzukla`
(12.11). So `se ke ciska` folds to `se ciska`. Verified by `suites/test_tanru_units.nim`, over
each chain of up to two of `se`, `te`, `na'e` and `nu`.

**A cmavo that only groups drops.** The fold tells which cmavo bind each tanru unit, and it keeps
no group that no cmavo binds. So the `ke` and `ke'e` of such a group drop, and `kemdatnyvei`
folds as `datnyvei`. A group whose cmavo cancel binds nothing, so it drops too. `bo` only groups
(5.3), so it drops. Verified by `suites/test_tanru_units.nim`.

Cost: the fold loses a grouping that no cmavo binds. So `datni ke vreji liste` folds as
`datni vreji liste`, although 5.3 groups the two apart. Verified by `suites/test_tanru_units.nim`,
in the suite `Internal: Convention`.

**`kei` closes an abstraction.** Rule 152 of 21.2 ends a NU with `kei`. So the fold reads `kei` as
a `ke'e` that closes a `ke` after its NU, and `nu citka gasnu kei klama` abstracts two tanru
units. After one tanru unit, the group holds only that tanru unit, as 12.13 says of
`nunctikezgau`. Verified by `suites/test_tanru_units.nim`, Section 12.13. A `kei` with no NU
before it drops, which the suite `Internal: Convention` holds.

**No group holds `co`.** 5.8 puts a `ke'e` before `co` for each group that is open there. Cost:
`co` inverts the order of a tanru (5.8), but the fold keeps the written order. Verified by
`suites/test_tanru_units.nim`, in Section 5.8 and in the suite `Internal: Convention`.

**A lujvo leaves `ke` out in two places that CLL names.** Two SE in a row read as SE `ke` SE
(12.11). So the first one converts the rest of the tanru, up to a `ke'e` that closes it. A `ke'e`
that closes nothing implies a `ke` after the nearest run of binding cmavo with two tanru units or
more after it (15.4). With no such run, the `ke'e` only groups, and it drops. Verified by
`suites/test_tanru_units.nim`.

Cost: the fold reads each tanru as a lujvo, so a tanru that `readTanru` reads from text follows
12.11 too. Cost: in a run of `na'e se` before such a group, both cmavo bind the group, where 15.4
names the negation alone.

**CLL spells one example with a rafsi that the list gives to another gismu.** 15.4 writes
`na'e ke sutra cadzu ke'e klama` as `nalsu'adzuke'ekla`. The list gives `su'a` to `stura`, and it
gives `sutra` only `sut`, so the reader reads that example with `stura`. The suite holds the shape
of the example, which the choice of gismu does not change. Verified by
`suites/test_tanru_units.nim`, Section 15.4.

13.13 makes a lujvo with `pev` figurative as a whole, and 5.13 gives a tense the whole bridi. The
fold binds nothing to them. Cost: `pevyselci'a` folds as `pe'a` beside `se ciska`, although `pe'a`
makes the whole lujvo figurative. Verified by `suites/test_tanru_units.nim`.

Rule 152 of 21.2 makes a number and its MOI one tanru unit. The fold keeps each digit as a tanru
unit of its own. Cost: `relpavmomci'a` folds `re`, `pa` and `moi` apart, although together they
make the ordinal 21. Verified by `suites/test_tanru_units.nim`, in the suite
`Internal: Convention`.

JAI binds as SE does (5.11), but the list gives `jai` no rafsi, so no lujvo of the list holds it.
CLL 12.12 gives `jai` the rafsi `jax`, which the list does not hold. A static check in
`tanru_units.nim` stops the build where the list gains `jai`.

## Tests

**One stub runs every suite as one program.** `tests/test_suites.nim` imports each file of
`tests/suites/`, in the shape that STYLE.md section 6 gives. Each suite still runs alone. A suite
that CLL covers carries the name of a chapter. The name of each other suite opens with
`Internal:`, so the run shows where the authority stops.

The suites are those of `lojban_tagger` that hold the parser. The tests of tag policy and of
search stay in that project. The tests of `tags.nim` that hold the reader are in
`suites/test_tanru.nim`, and the tests of the fold are in `suites/test_tanru_units.nim`. Each
assertion keeps its citation of CLL.

## Toolchain

**The compiler is pinned exactly**: `requires "nim == 2.4.0"` in `lojban_parser.nimble`, as each
project of the repository pins it (D1 a on #775). The project needs the standard library alone,
so it carries no lock. The verbs `lists` and `head` also need `lojban-common` and `sha256sum`,
which the verb `system` declares. A system package carries no pin, so its version is what the
machine has.

The stub passes on the pin and on Nim 2.2.12, and each placeholder reports itself as skipped.
Verified by hand with `nim c -r -d:testing tests/test_suites.nim` on both compilers, 2026-11-04.

**`constructRafsiByForm` of `suites/test_lujvo.nim` reads the form of each 4-letter rafsi
before `add`.** The compile-time virtual machine (VM) of the pin, Nim 2.4.0, evaluates the element
of `add` before its destination. It also moves a local, `let` or `var`, at its last use (#786). So
`result[stem.form.get].add stem` would move `stem` first, and then read the form of an empty
string.

Rejected: the form of `stem` read inside the call of `add`, which stops the compile of the stub.
The form of an empty string is `none`, and `get` of `none` stops the compile on the pin, so that
compile holds the order. Cost: an index that gives a value for an empty string can build a wrong
table with no error (#786).

Verified by hand with Nim 2.4.0, 2026-11-04: the rejected call stops the compile of the stub at
`constructRafsiByForm`, with `UnpackDefect`, and Nim 2.2.12 compiles it. Verified by hand with
both compilers, 2026-11-04: with the committed order, a probe of the same body builds the same
table on each.

## Figures

Each figure comes from an Intel Xeon at 2.10 GHz with four cores, on 2026-11-04, at the code of
`1e280037`. The runs of each pair alternate between Nim 2.2.12 and the pin, 2.4.0, so both share
the load of the machine.

- **Front end check of the umbrella.** `nim check --hints:off src/lojban_parser.nim` took 1.04 s,
  0.88 s and 0.79 s on 2.4.0, against 0.94 s, 0.81 s and 1.04 s on 2.2.12. The spread of each
  compiler covers the other, so neither is faster by this measure.
- **Suites from an empty cache.** `nim c -r --hints:off -d:testing tests/test_suites.nim`
  compiled and ran every suite in 11.6 s and 11.3 s on 2.4.0, against 11.3 s and 11.3 s on
  2.2.12. Each run started with an empty cache.
- **Suites alone.** The built binary ran every suite in 4.8 s and 5.0 s on 2.4.0, against 5.1 s
  and 5.1 s on 2.2.12.
- **Forms alone.** The suite of `test_forms.nim` builds alone, without optimisation. It ran in
  1.23 s, 1.36 s and 1.27 s on 2.4.0, against 1.29 s, 1.34 s and 1.34 s on 2.2.12.
- The time of `readWord` and of `$` is unmeasured here. `$` scores each choice of rafsi, so its
  time grows with the product of the choices of each word (expected).

## Open questions

- **The 4-letter rafsi `brod`.** Five gismu share it, and CLL does not say which one it names.
  The reader refuses it as ambiguous. `brodi`, `brodo` and `brodu` have no short rafsi. So a
  tanru that holds one of them before its last word renders with `brod`, and does not read back.
- **What the parser does not read yet.** It reads no prose: no bridi, no sumti, and no selbri
  past the tanru units of one word. It reads no name, which CLL calls cmevla, and no borrowing,
  which CLL calls fu'ivla. It reads no cmavo that the gismu list leaves out, such as `lo`, since
  that list holds only cmavo with rafsi. It reads no text with commas, capitals or periods
  (3.3, 3.9). The fold keeps no grouping that no cmavo binds, and no number with its MOI, which
  prose needs.
