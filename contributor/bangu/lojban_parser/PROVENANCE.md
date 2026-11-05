# Provenance

| Field   | Value |
|---------|-------|
| Harness | Claude Code |
| Author  | Claude |
| Date    | 2026-11-05 |
| Style   | CONSTITUTION.md and STYLE.md, followed. |
| Rules   | 01a086eda78015fd |
| Review  | **Unreviewed.** Nothing here has been read line by line by a human. |

Origin: a contributor project, from the brief of the Architect and the parsing part of
`lojban_tagger`. The brief gives the project one task alone: a complete parser of lojban, which
reads any valid lojban word or prose. It also has the tagger read lojban through this parser,
which stands apart from it. The project reads lojban words by the rules of CLL alone, and holds
no grammar of prose.

`lojban_tagger` keeps a copy of each module here until #809 moves the tagger onto this parser.
Where a module differs, the copy in `lojban_tagger` is earlier, and reads listed words alone. The
header of each module names its sibling there, as Article II.9 asks, and `tools/lists.nim` names
the sibling of the list that it renders. A fix to one copy is finished only when the other is
checked.

The authority is The Complete Lojban Language (CLL), by John Woldemar Cowan, from the Logical
Language Group. This project reads the first edition, 1997, with its errata, at
`lojban.github.io/cll`. Its chapter 3 gives the letters, the diphthongs and the consonant
clusters. Its chapter 4 gives the classes and shapes of words, the rafsi, and the algorithms that
join and score a lujvo. Chapters 5, 7, 9, 12 and 15 tell which words a cmavo binds. 17.2 gives
the letterals, and 21.2 gives the rule of a tanru unit.

The name of the language is lowercase, as lojban, as the Architect ruled for `lojban_tagger`. In
lojban, a capital letter marks irregular stress (CLL 3.9), and the name has none. A title keeps
its capitals, and so do the word lists, the notice of the group, and a name in code, such as
`Notation.Lojban`. Verified by hand with `grep` over this project, 2026-11-04.

## Rules and lists

**The rules of CLL judge each word, and a list only names it.** The Architect ruled on #823 that
valid means valid by the rules of CLL, and that a word list gives meaning, never validity. So a
word reads wherever those rules admit it, whether a list holds it or not. A list names the word of
each part of a tanru that it assigns. A part that no list names keeps its letters, and has no
meaning here. Verified by `suites/test_tanru.nim`.

**The parser keeps only the data that those rules need.** 4.11 and 4.12 join and score the rafsi
of each word of a tanru, so the gismu list keeps each word and its rafsi. `lojban_tagger` holds the
English of the gismu list and the whole lujvo list, since it searches by them. The selma'o of
each cmavo, which the grammar needs, waits for #813. The limits to single words and to gismu are
choices of the tagger, which holds them.

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

**A cmavo has one of the forms of 4.2.** `isCmavo` reads an optional consonant, then a run of
vowels: one vowel or diphthong, then each further one after an apostrophe. The ten on-glides that
4.2 adds stand first, in a cmavo that opens with a vowel, since 3.4 keeps them to words that stand
alone. `Cy`, `y` and `y'y` are the letterals of 4.2 and 17.2.

Verified by `suites/test_forms.nim`, over the examples of 4.2. It also holds every string of up to
six letters to forms built part by part. Those letters are the vowels, `y`, the apostrophe and two
consonants.

The test over the cmavo list holds each line of one cmavo to a form of 4.2. It holds each line
that the list marks as a compound to none. Verified by `suites/test_forms.nim`, test
`Section 4.2 over cmavo list`. Cost: 4.2 keeps a run of three vowels or more for experiment. Such a
run reads as a cmavo that no list can hold.

## Lujvo

**The join is the algorithm of 4.11, and the split is its inverse.** `joinRafsi` applies steps 4a
to 4c, then the tosmabru test of step 5. `splitLujvo` tries each segmentation that the forms
allow. It keeps a segmentation only where `joinRafsi` joins it back into the same word, letter
for letter. So a split, then a join, gives the word again, by construction. 4.11 makes a hyphen
illegal where the algorithm does not require it, so this comparison tests every hyphen.

Rejected: a check of each junction by local rules, which would state the algorithm twice.
Verified by `suites/test_lujvo.nim`, over the vectors of 4.5, 4.6, 4.11, 4.12 and 4.13. It also
holds a seeded sample of random sequences of listed rafsi. A second sample spells each rafsi from
the letters of its form, whether a list assigns it or not.

**The tosmabru test reads its joints up to the first `y`.** A joint is a consonant pair at a
junction after a leading CVC rafsi, or the medial pair of a final CVCCV. Where each joint is an
initial pair, one `y` goes after the first rafsi.

No example of CLL exercises step 5. So the suite holds it to words of the lujvo list that need it,
such as `xasymabru` and `cibylajyterkruca`. A reading over the whole word fails on four of those
words, so the list supports this reading. Verified by `suites/test_lujvo.nim`.

**A junction that makes `ndj`, `ndz`, `ntc` or `nts` takes `y`.** 4.11 step 4b names only an
impermissible pair, and CLL says nothing of these triples at a junction. 3.7 forbids them in each
word but a name, and the lujvo list writes `kanydzu` and `penydjuxa'a`. No lujvo of the list holds
one of these triples unbroken. Cost: the join holds one rule more than 4.11 states. Verified by
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

**The gismu list is that of the Logical Language Group, in the Debian package `lojban-common`,
version 1.5+dfsg.1-4.** The file is `gismu.txt`, and its header dates the list 9/26/94. The group
placed this material in the public domain. It asks that a derived work state how it was derived,
and give the address of the group. The header of the rendered module does both.

**A converter renders the list as typed Nim, and the project commits the result.** The verb
`nim r tools/build.nim lists` reads `gismu.txt` and checks its SHA-256 against its pin in
`tools/lists.nim`. Then it writes `src/lojban_parser/lists/gismu.nim`, a module of typed constants
whose header names that verb, as the rule of data asks (CONTRIBUTOR.md, Data). The compiler checks
each field against the types of `entries.nim`.

**An entry keeps the word and its rafsi alone, one entry to a line.** The converter reads both by
fixed columns. The columns hold over every line of the file, and no character falls between two
fields. Each entry fits one line of under 100 columns, so no field needs wrapping. Cost: code that
wants a column left out changes the converter and the list in one commit. Verified by
`suites/test_lists.nim`, which reads lines copied from `gismu.txt`, and which compares the
committed list with the installed file where `lojban-common` is present.

**The word takes `{.requiresInit.}`, so an entry without one does not compile.** The rafsi can be
empty, so they stay unmarked. Verified by `suites/test_lists.nim`.

Cost: `mapIt` declares `var it`, so it does not compile over an entry, and the suites read fields
by `collect` or by a loop. A seq of entries gives the warnings `UnsafeSetLen` and `UnsafeDefault`
on Nim 2.2.12 and 2.4.0. `newSeq` of entries also gives `ProveInit`, which Nim says will become an
error, so the suites use `newSeqOfCap`. Verified by hand on both compilers, 2026-11-04, with
`nim check` of the stub, and with a probe of `mapIt` and `newSeq` over an entry.

Rejected: the text file as it is, because the checker reads no `.txt`. Rejected: JSON, which
checks no field, and which `CONTRIBUTOR.md`, Data, keeps only where a tool or a service forces
it. Rejected: a read of the package at compile time, because each build would then need the
package. The Architect ruled for `lojban_tagger` that the lists change seldom, so a commit is
right, and the same holds here.

**The lujvo list and the cmavo list are outside texts.** The suites read `lujvo.txt` and
`cmavo.txt` where `lojban-common` installs them, through `suites/texts_outside.nim`. The Architect
ruled on #819 that outside texts test the parser, pinned by digest and kept out of the repository.
So `tools/lists.nim` pins each file by its SHA-256, and a test that reads one skips where the file
is absent or moved. The verb `system` declares the package, so CI installs it.

The suites read the word of each line of `lujvo.txt` that is lojban letters, and the parts of a
line that writes two or more. A law counts the keywords of a line in English notation, and never
reads them, since the parser holds no English. Cost: a line that writes a phrase for its word
stands in no domain. Verified by `suites/test_lists.nim`, over lines copied from `lujvo.txt`, and
by the floor of each notation in `suites/test_lujvo.nim`.

**The daily `head` verb watches the sources.** It checks the digest of each pinned file, and
renders the gismu module again to compare it with the committed one. Where Debian moves a pinned
file, `head` fails. Where it moves `gismu.txt`, `lists` refuses too, until somebody moves the pin.
Verified by hand, 2026-11-05: `nim r tools/build.nim head` exits 0 against `lojban-common`
1.5+dfsg.1-4.

## Tanru

**The letters sort each word into its class, in the order of 4.3.** A final consonant marks a
cmene (4.8). A consonant pair in the first five letters, `y` and the apostrophe not counted, marks
a brivla (4.3). A brivla of gismu form is a gismu (4.4), and another brivla is a lujvo where its
rafsi join as 4.11 joins them. A word with no consonant pair is one cmavo, or several run
together (4.2). Verified by `suites/test_tanru.nim`.

**A brivla has two syllables or more.** 4.3 stresses a brivla on its next to last syllable, so
`zba` and `brai` are no brivla, and the reader refuses them as `Shape`. Each vowel is one syllable,
`y` included, and each diphthong of 4.1 is one syllable (3.4). Verified by
`suites/test_tanru.nim`, Section 4.3.

**Each refusal names the rule of CLL that refuses the text, or the gap that holds it.** `Letter`
names 3.1 and 3.3, `Apostrophe` names 3.3, `Shape` names 4.2, 4.3 and 4.8, and `Hyphen` names
4.11. A gap is text that CLL admits and that the reader does not read yet. `Stream` holds marks of
a stream and cmavo run together, for #811. `Cmene` and `Fuhivla` hold cmene and fu'ivla, for
#812. Verified by `suites/test_tanru.nim`.

Cost: a gap also holds text that no rule admits, as `cia`, which 3.4 forbids, and the issue of
the gap tells the two apart. Verified by `suites/test_tanru.nim`.

**A word reads as the words of its tanru, never as its spelling.** 4.5 says that the rafsi chosen
do not change a lujvo. So `brivla`, `brivalsi`, `bridyvla` and `bridyvalsi` read as one tanru,
`bridi valsi`. The order of the words stays, because a tanru is a modifier, then a head. `$`
renders the form that 4.12 scores lowest, and on a tie the first in the order of choice. Verified
by `suites/test_tanru.nim`.

**A part of a tanru is a listed word, or the letters of a word that no list names.** A short rafsi
names the word that the list assigns it. A 4-letter rafsi names the gismu that it is the stem of,
and a final 5-letter rafsi names itself. A word read whole names itself where the list holds it.
So `kukta` reads as a gismu with the part `kukta`, and `clozba` as a lujvo with the parts `clo`
and `zbasu`. Verified by `suites/test_tanru.nim`, over every string of gismu form, and over a
seeded sample of lujvo of rafsi spelled from letters.

**A rafsi of a cmavo stands for that cmavo, and the tanru keeps it.** So `selci'a` reads as
`se ciska`, which is not `ciska`, because `se` converts it (9.4). A lujvo whose last rafsi names a
cmavo reads too, as `zbadoi` reads as `zbasu do`. 4.11 step 2 takes the last rafsi from the final
gismu, but the list says which word a rafsi names, never the letters. Verified by
`suites/test_tanru.nim`.

**The shared rafsi `brod` names no one gismu.** Five gismu share it (4.4), so its part keeps the
letters `brod`. `brodyzba` reads as the parts `brod` and `zbasu`. Verified by
`suites/test_tanru.nim`.

**The reader reads canonical form alone: lowercase letters and the apostrophe, as they are
written.** Whitespace, a comma, a period and the capital of a letter mark a stream (3.3,
3.9). So the reader refuses each as the gap `Stream`, which #811 closes. A capital of no letter,
as `H`, is refused as `Letter`. 3.3 says that the letter `h` does not stand
for the apostrophe, so the reader refuses `h` as `Letter`. Verified by `suites/test_tanru.nim`, in
Section 3.3 and in the suite `Internal: Reading`.

Cost: CLL text that writes a comma or a capital inside a word is refused, as `sai,r,goi` and
`DI,ky,jvo` of 3.9 are. The test `Section 3.9` of `suites/test_tanru.nim` is a placeholder that
reports itself as skipped until #811 reads such text (Article IX.9).

**A refusal says why.** The reader refuses with one reason from `Refusal`, and a detail. The detail
is the offending character or the form that 4.11 gives, and it is empty where the whole text
offends. A character outside the letters is named whole, so the detail of UTF-8
text stays UTF-8. Where the rafsi are known and only the hyphens are wrong, the detail is the
form that 4.11 gives, as `patyta'a` for `patta'a`. Verified by `suites/test_tanru.nim`.

**A tanru with no lujvo form renders as its parts, one space apart, as CLL writes a tanru (5.1).**
Such a tanru ends in a cmavo with no CCV or CVV rafsi, as `cusku se`, or holds a cmavo with no
rafsi. Verified by `suites/test_tanru.nim`. `lojban_tagger` holds the notation `+` of the
lujvo list, with `readTanru` and `toText`, which read and write it.

## What cmavo bind

**A tanru folds into tanru units, and each tanru unit is one part with the cmavo that bind it.**
The grammar of CLL gives that name (21.2, rule 152), which the Architect selected for
`lojban_tagger` (#768). SE binds the next brivla or "equivalent unit" (9.4), and NAhE binds close
to its brivla (15.4). A NU rafsi modifies the next tanru unit alone (12.12). Each other cmavo binds
nothing, and stands as a tanru unit of its own where it does more than group. Verified by
`suites/test_tanru_units.nim`.

**A part that no list names binds nothing.** Each binding cmavo is a word of the list. So such a
part stands as a tanru unit of its own, and a cmavo before it binds it. Verified by
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

Cost: the fold reads each tanru as a lujvo, so a tanru that a caller builds from words follows
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
`tests/suites/` whose name opens with `test_`, in the shape that STYLE.md section 6 gives. Each
suite still runs alone. A suite that CLL covers carries the name of a chapter. The name of each
other suite opens with `Internal:`, so the run shows where the authority stops.

Helpers stand beside the suites, and the stub runs none of them. `suites/texts_outside.nim` reads
the outside texts by their pins. `suites/rafsi_random.nim` spells random rafsi from the letters of
each form. So the suites of the reader and of lujvo share one way to draw them (II.9).

`suites/test_tanru.nim` holds the reader, and `suites/test_tanru_units.nim` holds the fold. Each
suite has a sibling in `lojban_tagger`, which holds an earlier copy, and its header names it
(II.9). The tests of tag policy and of search are in `lojban_tagger` alone. Each assertion cites
its source: a section of CLL, or the article of the charter that a guard holds.

## Toolchain

**The compiler is pinned exactly**: `requires "nim == 2.4.0"` in `lojban_parser.nimble`, as each
project of the repository pins it (D1 a on #775). The project needs the standard library alone,
so it carries no lock. The verbs `lists` and `head`, and the tests of outside texts, also need
`lojban-common` and `sha256sum`, which the verb `system` declares. A system package carries no
pin, so its version is what the machine has.

The stub passes on the pin and on Nim 2.2.12, and each placeholder reports itself as skipped.
Verified by hand with `nim c -r -d:testing tests/test_suites.nim` on both compilers, 2026-11-05.

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

Each figure comes from an Intel Xeon at 2.10 GHz with four cores, on 2026-11-05, at the code of
`0b4cb338`. The runs of each pair alternate between Nim 2.2.12 and the pin, 2.4.0, so both share
the load of the machine. A pair against `main` alternates `646bf514` with this code, on the pin.

- **Front end check of the umbrella.** `nim check --hints:off src/lojban_parser.nim` took 0.88 s,
  0.89 s and 0.89 s on 2.4.0, against 0.68 s, 0.73 s and 0.71 s on 2.2.12. The spreads do not
  meet, so 2.2.12 is faster by this measure, on this machine.
- **Suites from an empty cache.** `nim c -r --hints:off -d:testing tests/test_suites.nim`
  compiled and ran every suite in 11.3 s and 11.3 s on 2.4.0, against 11.0 s and 11.0 s on
  2.2.12. Each run started with an empty cache.
- **Suites alone.** The built binary ran every suite in 6.5 s and 6.8 s on 2.4.0, against 6.6 s
  and 6.7 s on 2.2.12. Against `main`, it ran in 6.6 s and 6.4 s, where `main` ran in 5.3 s and
  5.2 s.
- **Forms alone.** The suite of `test_forms.nim` builds alone, without optimisation. It ran in
  2.03 s, 2.11 s and 2.14 s on 2.4.0, against 2.04 s, 2.02 s and 1.95 s on 2.2.12. Against `main`,
  it ran in 2.08 s, 2.06 s and 2.21 s, where `main` ran in 1.41 s, 1.36 s and 1.42 s. The law of
  4.2, over each string of up to six of its nine letters, gives most of the difference (expected,
  unmeasured alone).
- The time of `readWord` and of `$` is unmeasured here. `$` scores each choice of rafsi, so its
  time grows with the product of the choices of each word (expected).

## Open questions

- **The 4-letter rafsi `brod`.** Five gismu share it, and CLL does not say which one it names. The
  reader reads it as a part with the letters `brod`. `brodi`, `brodo` and `brodu` have no short
  rafsi, so a tanru that holds one of them before its last word renders with `brod`. It then
  reads back with that part, and not with the gismu.
- **A word refused as `Hyphen` may be a fu'ivla.** The reader judges each brivla whose letters
  split into rafsi by the hyphens of 4.11. 4.7 gives the tests of a fu'ivla, which #812 adds, and
  only those tests tell whether such a word is a fu'ivla.
- **What the parser does not read.** It reads no prose: no bridi, no sumti, and no selbri past
  the tanru units of one word. It reads no cmene (4.8) and no fu'ivla (4.7), which #812 adds. It
  reads no cmavo run together and no marks of a stream (3.3, 3.9), which #811 adds. It gives no
  selma'o, which #813 adds. The fold keeps no grouping that no cmavo binds, and no number with its
  MOI, which prose needs.
