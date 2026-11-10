# Provenance

| Field   | Value |
|---------|-------|
| Harness | Claude Code |
| Author  | Claude |
| Date    | 2026-11-08 |
| Style   | CONSTITUTION.md and STYLE.md, followed. |
| Rules   | 00c5e626e221951e |
| Review  | **Unreviewed.** Nothing here has been read line by line by a human. |

Origin: a contributor project, from the brief of the Architect and the parsing part of
`lojban_tagger`. The brief gives the project one task alone: a complete parser of lojban, which
reads any valid lojban word or prose. It also has the tagger read lojban through this parser,
which stands apart from it. The project reads lojban words, and streams of them, by the rules of
CLL alone. It reads prose by the formal grammar of 21.1, after the rules that act on words before
that grammar (19.16).

`lojban_tagger` reads lojban through the umbrella of this parser, and holds no copy of its
modules. Three parts of the parser keep a sibling in the tagger, and the header of each names it,
as Article II.9 asks. They are `tools/lists.nim`, the verbs `lists` and `head` of
`tools/build.nim`, and the private `ending` of `tanru_units.nim`. A fix to one sibling is
finished only when the other is checked.

The converter of the tagger also imports six names of `tools/lists.nim`, which its header lists.
Cost: a change to the umbrella or to those six names can break the tagger with no red run. A
change to this project compiles no suite of the tagger, since the plan of `koch` selects the
importers of knoller alone (#832). Verified by hand in `curator/audit/src/plan.nim`, 2026-11-08.

The authority is The Complete Lojban Language (CLL), by John Woldemar Cowan, from the Logical
Language Group. This project reads version 1.1, generated 2016-08-26, which is the latest edition
of the group, as the Architect ruled on #811. Its text is at
`lojban.org/publications/cll/cll_v1.1_xhtml-section-chunks/`. Version 1.1 is the first edition of
1997 with its errata applied, and it keeps the sections of chapters 1 to 19. It numbers each
example within its chapter, as Example 4.3, and 21.1 gives its one formal grammar, in EBNF.

Its chapter 3 gives the letters, the marks of a stream, the diphthongs,
the consonant clusters, the syllables and the stress. Its chapter 4 gives the classes and shapes
of words, the rafsi, the algorithms that join and score a lujvo, and the pauses between words.
Chapters 5, 7, 9, 12 and 15 tell which words a cmavo binds. 17.2 gives
the letterals, chapter 20 is the catalogue of selma'o, and 21.1 gives the formal grammar. Chapters
13, 17 and 19 give indicators, lerfu words, quotation and erasure, which act before that grammar.

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
English of the gismu list and the whole lujvo list, since it searches by them. The cmavo list
keeps the word and the selma'o of each cmavo, which the grammar needs. The limits to single words
and to gismu are choices of the tagger, which holds them.

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

**A compound of cmavo splits before each consonant and at each period.** A cmavo holds one
consonant at most, and that consonant comes first (4.2). A cmavo that opens with a vowel follows a
pause, which a period writes (3.3). So `splitCompound` splits a compound in one way only, and each
piece is a cmavo of 4.2, or the text is no compound. Verified by `suites/test_forms.nim`, over the
examples of 4.2 and over seeded compounds of listed cmavo.

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

**The score sums a part for each rafsi and a part for each junction.** 4.12 counts each letter,
apostrophe, hyphen, rafsi and vowel alone, so `scoreRafsi` and `scoreJunction` give each part.
Steps 4a to 4c settle a junction from the two rafsi beside it. Step 5 reads the junctions from left
to right with one flag, which says whether the leading run of CVC rafsi is still open. Where step 5
puts `y` at the first junction, the junction that ends the run holds that part of the score.

`hyphensRafsi` and `score` use the same parts, so each rule has one definition. The parts stay
private, and `tanru.nim` and the suites import every symbol of `lujvo.nim` to reach them. So the
umbrella exports no new name to the tagger (#832). Verified by `suites/test_lujvo.nim`, over seeded
samples. In one of them, step 5 puts `y` at the first junction of about a third of the sequences.

The parts give the hyphens and scores that the earlier code gave. Verified by hand, 2026-11-08,
with a program that held a copy of the earlier `hyphensRafsi` and `score`. It found no difference
over 95.6 million sequences: every pair of rafsi, runs of CVC rafsi, and seeded random sequences.

**The split agrees with strict reference parsers.** On 41 words, the split finds one lujvo
exactly where CLL makes one. The verdicts on those words are those of camxes, vlatai, the
`is_valid_lujvo` of jbofihe and latkerlo-jvotci, read on 2026-10-24 for `lojban_tagger`. Where
the strict tools disagree, as on `saircli` and `branlatu`, this project follows CLL. Verified by
`suites/test_references.nim`, which cites the deciding rule of each word. No tool ran again for
this project.

## Word lists

**The gismu list and the cmavo list are those of the Logical Language Group, in the Debian package
`lojban-common`, version 1.5+dfsg.1-4.** The files are `gismu.txt`, whose header dates it
9/26/94, and `cmavo.txt`, whose header dates it 26 August 2002. The group placed this material in
the public domain. It asks that a derived work state how it was derived, and give the address of
the group. The header of each rendered module does both.

**A converter renders each list as typed Nim, and the project commits the result.** The verb
`nim r tools/build.nim lists` reads both files and checks the SHA-256 of each against its pin in
`tools/lists.nim`. Then it writes `src/lojban_parser/lists/gismu.nim` and `cmavo.nim`. Each is a
module of typed constants whose header names that verb, as the rule of data asks (CONTRIBUTOR.md,
Data). The compiler checks
each field against the types of `entries.nim`.

**An entry keeps the word and its rafsi alone, one entry to a line.** The converter reads both by
fixed columns. The columns hold over every line of the file, and no character falls between two
fields. Each entry fits one line of under 100 columns, so no field needs wrapping. Cost: code that
wants a column left out changes the converter and the list in one commit. Verified by
`suites/test_lists.nim`, which reads lines copied from `gismu.txt`, and which compares the
committed list with the installed file where `lojban-common` is present.

**The cmavo list keeps the word and the selma'o of each line of one cmavo.** The converter reads
the word in columns 1 to 11, without the period of a pause, and the selma'o in columns 12 to 20.
It keeps the name of the selma'o, and drops the subclass that the list writes after it, as the
`1` of `UI1`. That subclass groups cmavo for learners, and no rule of CLL reads it. The converter
leaves out each line whose selma'o holds `*`: a compound reads as the cmavo it joins (4.2), and a
phrase is several words. Verified by `suites/test_lists.nim`, over lines copied from `cmavo.txt`.

Cost: the list holds no compound, so a caller that wants the selma'o of a compound reads the
selma'o of each of its cmavo.

**The word of each list and the selma'o take `{.requiresInit.}`, so an entry without one does not
compile.** The zero value of the selma'o is `Selmaho.A`, which would stand in silence. The rafsi
can be empty, so they stay unmarked. Verified by `suites/test_lists.nim`.

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

**The lujvo list is an outside text, and so is the whole cmavo list.** The suites read
`lujvo.txt` and `cmavo.txt` where `lojban-common` installs them, through
`suites/texts_outside.nim`. The parser commits no part of the lujvo list, and the lines of one
cmavo alone of the cmavo list. The Architect
ruled on #819 that outside texts test the parser, pinned by digest and kept out of the repository.
So `tools/lists.nim` pins each file by its SHA-256, and a test that reads one skips where the file
is absent or moved. The verb `system` declares the package, so CI installs it.

The sentences of Tatoeba are the one outside text that the repository holds, as Sample of Tatoeba
gives.

The suites read the word of each line of `lujvo.txt` that is lojban letters, and the parts of a
line that writes two or more. A law counts the keywords of a line in English notation, and never
reads them, since the parser holds no English. Cost: a line that writes a phrase for its word
stands in no domain. Verified by `suites/test_lists.nim`, over lines copied from `lujvo.txt`, and
by the floor of each notation in `suites/test_lujvo.nim`.

**The daily `head` verb watches the sources.** It checks the digest of each pinned file, and
renders both modules again to compare each with the committed one. Where Debian moves a pinned
file, `head` fails. Where it moves `gismu.txt` or `cmavo.txt`, `lists` refuses too, until somebody
moves the pin.
Verified by hand, 2026-11-05: `nim r tools/build.nim head` exits 0 against `lojban-common`
1.5+dfsg.1-4.

## Selma'o

**`Selmaho` names each selma'o of the catalogue of chapter 20.** Chapter 20 names each selma'o by a
representative cmavo, in capitals, with `h` for the apostrophe. A member is the Pascal case of that
name, as `Form.Cvc` is of CVC, and `$` spells the name of CLL again. `h` is no letter of lojban
(3.3), so each `h` of a member marks an apostrophe. The members keep the order of the catalogue,
which is the byte order of the names. Verified by `suites/test_selmaho.nim`, against each name,
its order and its representative cmavo.

**A cmavo read whole carries its selma'o.** The reader gives the selma'o that the cmavo list gives
the cmavo. A cmavo that no list holds, as the experimental `ku'a'e`, carries none. A part of a
lujvo carries none either, since a rafsi can spell a cmavo, as `kau` of `kampu` spells the cmavo
`kau`. Verified by `suites/test_tanru.nim`, Section 4.2, and by `suites/test_selmaho.nim`.

**The lists and the catalogue agree.** Each selma'o of the catalogue holds a cmavo of the list.
Each cmavo of the gismu list stands in the cmavo list, which a static check of `dictionary.nim`
holds. Verified by `suites/test_selmaho.nim`.

**Each line of `cmavo.txt` reads.** A line of one cmavo reads with the selma'o that it gives. A
compound written as one word reads as cmavo that the list holds. A phrase reads word by word, each
word a cmavo of the list, alone or run together, or a brivla. Verified by `suites/test_selmaho.nim`.

## Tanru

**The letters sort each word into its class, in the order of 4.3.** A final consonant marks a
cmene (4.8). A consonant pair in the first five letters, `y` and the apostrophe not counted, marks
a brivla (4.3). A brivla of gismu form is a gismu (4.4). Another brivla is a lujvo where its rafsi
join as 4.11 joins them, and else a fu'ivla where it meets each rule of 4.7. Verified by
`suites/test_tanru.nim`.

**A word with no consonant pair is one cmavo, or several run together (4.2).** Each piece that
`splitCompound` cuts is then a cmavo. Other letters fit no class as one word, and the reader
refuses them as `Shape`. `cia` holds `ia` after a consonant, which 3.4 forbids, and `lonubarda`
runs cmavo into a brivla. `readStream` splits both, as Stream says. Verified by
`suites/test_tanru.nim`.

**A brivla has two syllables or more.** 4.3 stresses a brivla on its next to last syllable, so
`zba` and `brai` are no brivla, and the reader refuses them as `Shape`. Each vowel is one syllable,
`y` included, and a diphthong is always one syllable (3.4). Verified by `suites/test_tanru.nim`,
Section 4.3.

**Vowels pair into syllables from the left (3.5).** An on-glide, as `ua`, is a diphthong anywhere
in a fu'ivla or a cmene, so `brua` is no brivla. `nuclei` of `forms.nim` finds the syllables of
each word, both for this count and for the stress that a stream reads. Verified by
`suites/test_stream.nim`, Section 3.4, and by a law over on-glides in five frames.

**A cmene ends in a consonant, holds a syllable, and holds permissible pairs alone (4.8).** A
syllable stands on a vowel, `y`, or a consonant that may be syllabic, as in `rl` of 3.4. A name
may hold a triple anywhere, where its pairs are permissible (3.7). So `NEderlants` reads with the
triple `nts`, and `djandjonz` with `ndj`. Verified by `suites/test_tanru.nim`, Section 4.8.

**A cmene may not hold `la`, `lai` or `doi` after no consonant (4.8).** Else it breaks up into
words, as `laplas` does. The reader refuses that as `Breakup`. Verified by
`suites/test_tanru.nim`, Section 4.8.

**`iy` and `uy` are diphthongs of a cmene alone (3.4).** So capitals on `uy` of `kUYn.` mark one
syllable, which a cmene may stress. Verified by `suites/test_stream.nim`, Section 3.4, and by a law
over four frames of cmene.

**A fu'ivla meets each rule of 4.7.** It holds no `y`, and a cluster that opens it is made of
initial pairs (3.7). Its pairs are permissible, and it holds no triple that 3.7 forbids, as
`lerndjamo` holds `ndj`. It is no combination of cmavo, gismu and lujvo. No CV cmavo before it
makes a lujvo, which 4.7 calls the slinku'i test. Verified by `suites/test_tanru.nim`, Section
4.7, and by a law over random letters.

**A combination counts where it sounds as the fu'ivla does.** A brivla stresses its penultimate
syllable (3.9). So only a brivla that ends a combination stresses where the fu'ivla does, and the
cmavo before it may take stress or none. So the reader looks for cmavo, then one gismu or lujvo,
with no pause between any two. `mibroda` is such a combination, and `spageti` is none, though
`spage` has the form of a gismu. Verified by `suites/test_tanru.nim`, Section 4.7, and by a law
over listed cmavo joined before listed gismu.

Cost: 4.7 forbids "any combination of cmavo, gismu, and lujvo". Read by its letters alone, with
#823, that rule refuses `spageti`, which 4.7 gives as a fu'ivla. So the reader keeps the
combination that stresses as the fu'ivla does. It reads `klamaku`, `klamabroda` and
`ve'iglicoxebni` as fu'ivla, though `klama` and `ku` are listed words. 3.9 lets a secondary stress
rise up to primary, so stress is a weak divider in speech. Verified by `suites/test_stream.nim`,
in the suite `Internal: Stream`, and by the law over words written together.

**A fu'ivla reads, though its letters split into rafsi whose hyphens 4.11 sets otherwise.** 4.7
forbids a fu'ivla to be a lujvo, and not to look like one. So `ci'onmau` reads as a fu'ivla,
where 4.11 gives the lujvo `ci'ormau`. A brivla that breaks a rule of fu'ivla, and splits into
rafsi, is refused as `Hyphen`, with the form that 4.11 gives. Verified by `suites/test_tanru.nim`,
in the suite `Internal: Reading`.

**Each refusal names the rule of CLL that refuses the text.** `Letter`
names 3.1 and 3.3, `Apostrophe` names 3.3, `Shape` names 3.3, 4.2, 4.3 and 4.8, and `Hyphen`
names 4.11. `Cluster` names 3.6, 3.7 and 4.7, `Breakup` names 4.8, and `Combination` and
`Slinkuhi` name 4.7. `Stream` names text that `readStream` reads: marks of a stream, and cmavo run
together. A stream alone gives `Stress` (3.9), `Comma` (3.3, 3.4), `Split` (3.3) and
`Quotation` (19.10). Verified by `suites/test_tanru.nim` and `suites/test_stream.nim`.

**`Foreign` refuses nothing.** It marks the text that `zoi` or `la'o` quotes, which is no lojban
(4.9 rule 7). The stream holds that text whole as one occurrence. Verified by
`suites/test_stream.nim`, Section 4.9.

**A word reads as the words of its tanru, never as its spelling.** 4.5 says that the rafsi chosen
do not change a lujvo. So `brivla`, `brivalsi`, `bridyvla` and `bridyvalsi` read as one tanru,
`bridi valsi`. The order of the words stays, because a tanru is a modifier, then a head. `$`
renders the form that 4.12 scores lowest, and on a tie the first in the order of choice. Verified
by `suites/test_tanru.nim`.

**The render searches by dynamic programming, in time linear in the words of the tanru.** A table
holds the lowest score of the rest for each choice at each position, in each state of the run of
step 5. A walk from the first position takes the first choice that reaches that score. So a tie
keeps the form that a search over every sequence of choices gives. Verified by
`suites/test_tanru.nim`, against that search, over seeded samples and each lujvo of the lujvo list.

The search alone, `searchLowest`, takes the options of each position. So the suite holds it to the
search over every sequence on drawn lists of options. The order of the options breaks a tie in
more than half of those lists. The state of the run decides in about one in a hundred. Three
tanru that the suite constructs hold a tie at the first position, a tie past it, and the state.
Verified by `suites/test_tanru.nim`.

Rejected: a search over every sequence of choices, whose count grows about 3.2 times for each word
(Figures, Render of tanru).

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

**`readWord` reads canonical form alone: lowercase letters and the apostrophe, as they are
written.** Whitespace, a comma, a period and the capital of a letter mark a stream (3.3,
3.9). So `readWord` refuses each as `Stream`, and `readStream` takes them out before it reads
each word, as Stream says. A capital of no letter, as `H`, is refused as `Letter`. 3.3 says that
the letter `h` does not stand for the apostrophe, so the reader refuses `h` as `Letter`. Verified
by `suites/test_tanru.nim`, in Section 3.3 and in the suite `Internal: Reading`.

**A refusal says why.** The reader refuses with one reason from `Refusal`, and a detail. The detail
is the offending character or the form that 4.11 gives, and it is empty where the whole text
offends. A character outside the letters is named whole, so the detail of UTF-8
text stays UTF-8. Where the rafsi are known and only the hyphens are wrong, the detail is the
form that 4.11 gives, as `patyta'a` for `patta'a`. Verified by `suites/test_tanru.nim`.

**A tanru with no lujvo form renders as its parts, one space apart, as CLL writes a tanru (5.1).**
Such a tanru ends in a cmavo with no CCV or CVV rafsi, as `cusku se`, or holds a cmavo with no
rafsi. Verified by `suites/test_tanru.nim`. `lojban_tagger` holds the notation `+` of the
lujvo list, with `readTanru` and `toTanru` of its `tags.nim`, which read and write it.

## Stream

**A stream divides into words at whitespace and at periods.** 3.3 makes a period a pause, and a
pause breaks up a word into two (4.9 rule 1). 3.3 needs no space between words where a period
stands. Verified by `suites/test_stream.nim`, Section 3.3, and by the law that words joined by a
period read as words joined by a space.

**A written word reads as one word where its letters and capitals allow.** Else the reader splits
it into words, as the Architect ruled on #811. 4.1 says that the sounds of a stream split one way
alone, and 3.3 lets correct text leave a period out. Verified by `suites/test_stream.nim`, in the
suite `Internal: Stream`.

**The split chosen needs the fewest pauses that rules need and the text does not write.** So a
period left out is inferred only where the letters read no other way. `losei` reads as
`lo sei`, never as `lo se .i`, and `ki'eu'e` reads as `ki'e .u'e`. Splits of fewest pauses
that tie are refused as `Split`, which names two of them. A written word with no split is refused
as `readWord` refuses its letters. Verified by `suites/test_stream.nim`, in the suite
`Internal: Stream`, and by a law over words written together.

**Stress chooses among splits, as it does in speech.** 3.9 requires primary stress on the
penultimate syllable of each brivla. A written word with no capital is stressed on its own
penultimate syllable alone, as the Architect ruled (`D3 a` on #811). One with capitals is stressed
on each syllable that they mark. So each brivla of a split holds a capital, or ends the syllables
of its written word that count for stress. Verified by `suites/test_stream.nim`, Section 3.9 and
the suite `Internal: Stream`, and by a law over words written together.

**So the stress of a written word chooses its split.** `mibroda` reads as `mi broda`, and
`MIbroda` as `mibro da`. `KLAmaku` reads as `klama ku`, and `klamaku` as one fu'ivla.
`.esperanto` reads as `e speranto`, as Example 19.78 says it "breaks up". Verified by
`suites/test_stream.nim`, in the suite `Internal: Stream`.

Cost: a writer who means a brivla before other words must write its capital, as `MIbroda`. Runs
whose stress fits no brivla read as other words, or are refused. Verified by
`suites/test_stream.nim`, by the law over words written together, which holds 800 such runs at
least.

Precedent: the parser of the Logical Language Group splits compound cmavo, and assumes that brivla
and cmene stand alone, in its file `lex.c`. It says that this holds for written lojban, but not
for a naive transcription of speech. This reader reads that transcription too, as the Architect
ruled. The archive is `lojban.org/files/software/parser/parser.shar.gz`, with SHA-256
`72a4883f2cbceff616eaf7d93dee86e4b20798ed4aad3c6a91f95dc6ba0077c5`. Verified by hand with `curl`,
`sha256sum` and `zcat`, 2026-11-05.

**A cmene stands last in a written word.** A pause follows each cmene (4.9 rule 2), and the parts
of a name join into one word with no pause (4.8). So a consonant inside a written word goes on
with the name. `bri` is no `br .i`, though `br` alone would read as a cmene, and `secusku` is
`se cusku`, never `secusk .u`. Verified by `suites/test_stream.nim`, Section 3.3, and in the suite
`Internal: Stream`.

**The reader infers a pause where a rule needs one and the text writes none.** 3.3 calls the
period an optional reminder of a mandatory pause, which correct text implies where the period is
missing. So the reader refuses no words for a pause that the text does not write. Each word
carries the pause before it: written, inferred or absent. Verified by `suites/test_stream.nim`,
Sections 3.3, 4.2 and 4.9, and by a law that states each rule again, apart from the reader.

The rules that the reader applies are these:

- A word that ends in a consonant takes a pause after it (4.9 rule 2).
- A word that opens with a vowel, or with `y`, takes a pause before it (4.9 rule 3, 4.2).
- A cmene takes a pause before it, unless `la`, `lai`, `la'i` or `doi` stands before it (4.9
  rule 4).
- A stressed last syllable takes a pause after it, before a brivla or a stressed first syllable
  (4.9 rule 5, 4.2). Its syllables are counted with the commas of its word, as its stress is.
- `Cy` takes a pause before a word that is not `Cy` (4.9 rule 6), and `y` takes one after it
  (4.2).
- The first word takes a pause where rule 3 or rule 4 needs one.

**The text that `zoi` and `la'o` quote stands whole, as one occurrence.** The word after `zoi` is
its delimiter, and the text runs up to that word written again (19.10). The delimiter ends its
written word, and a pause stands on each side of the text (4.9 rule 7). The marks around the text
are left out. Verified by `suites/test_stream.nim`, Section 4.9, and by
`suites/test_prose.nim`, Section 19.10.

**A delimiter that the text holds is refused as `Quotation`.** 19.10 says that the delimiter is
"not found in the written text". So `zoi gy. gyrations .gy.` is refused, as Example 19.50 is "as
written". `zoi` with no delimiter, or with text that never closes, is refused too. Verified by
`suites/test_stream.nim`, Section 4.9.

**A word that `zo` or `lo'u` quotes acts on nothing, and the stream stops after `fa'o`.** `zo`
quotes the next word, whatever it is, and `lo'u` quotes words up to a `le'u` that no `zo` quotes
(19.9, 19.10). So `zo zoi` quotes `zoi`, and `zoi` inside `lo'u` quotes no text. `fa'o` ends
parsable input unless a quotation holds it (19.15, 21.1). Verified by `suites/test_stream.nim`,
Section 4.9.

**A comma parts syllables, and the words chosen fit them.** 3.5 groups vowels by a comma, as
Example 3.7 writes `me,iin.`, and 4.8 keeps a stress with capitals. So capitals stress the
syllables that commas mark. `me,IIn.` is one cmene stressed on `ii`, and so is `.nu,IORK.` of
Example 5.65, stressed on `io`. Each comma is then judged against the words chosen. Verified
by `suites/test_stream.nim`, Section 3.5, and by a law over each grouping of seven names.

**With no capital, a comma changes no word.** 3.3 says that "no two Lojban words differ solely
because of the presence or placement of a comma". Without a capital, syllables choose no words,
so a comma keeps the words or is refused. Verified by `suites/test_stream.nim`, Section 3.3, and
by laws over each position of each word of the lists, and of fourteen fu'ivla and cmene.

Cost: a comma under a capital may make a written word split. `crarcI,ae` reads `crarcia e`,
where `crarcIae` reads `crarciae`, since the comma parts `ia`. Verified by
`suites/test_stream.nim`, Section 3.3.

**A comma marks no pause, so no split takes a pause where a comma stands.** 3.3 says that a comma
"indicates that there must be no pause" between its syllables. Where only such a split reads, the
written word is refused as `Comma` at that comma. Verified by `suites/test_stream.nim`, Section
3.3, and by a law over two cmavo that need a pause.

**A comma breaks syllables inside a word.** Each stretch that it bounds holds a vowel, `y`, or a
consonant that may be syllabic, as the `r` of `sai,r,goi` (3.4). A comma also parts two vowels into
two syllables, as `.nu,IOrk.` parts `u` from `io` (3.5). Verified by `suites/test_stream.nim`,
Sections 3.3, 3.4 and 3.9, and by the same law.

**A comma between two vowels of a cmavo, a gismu or a lujvo is refused.** In those classes two
vowels side by side make a diphthong, which is one syllable (3.4). A cmene and a fu'ivla may part
two vowels with a comma, as `kore,a` of Examples 4.55 and 4.56 does. Verified by
`suites/test_stream.nim`, Sections 3.4 and 4.7, and by the law over each position.

**A comma may stand between two words, but never where a pause must stand.** 3.3 says that a comma
cannot be pronounced as a pause. So `ka,i` is `kai` with its comma refused, never `ka .i`.
Verified by `suites/test_stream.nim`, in the suite `Internal: Stream`.

Cost: a comma beside `l`, `m`, `n` or `r` may make that consonant syllabic, which 3.4 admits in
principle, so the reader accepts it. Verified by `suites/test_stream.nim`, Section 3.4, and by the
law over each position.

**A capital marks stress, and nothing else.** 3.9 capitalizes the stressed syllable, or at least
its vowel, and 4.8 calls this the only use of capitals. So the capitals of a word form one run,
which touches one vowel or diphthong. The reader refuses any other capital as `Stress`, as the
`M` of `Mi` that opens a sentence. Verified by `suites/test_stream.nim`, Sections 3.1 and 3.9.

Cost: a text that capitalizes the first word of each sentence, as English does, is refused there.
Verified by `suites/test_stream.nim`, Section 3.1.

**A brivla stresses its penultimate syllable, and a cmavo or a cmene any syllable or none.** `y`
and a syllabic consonant are not counted, and `y` takes no stress (3.9). A fu'ivla stresses as the
other brivla do (4.7). Verified by `suites/test_stream.nim`, Section 3.9, and by laws over each
syllable of each word of the lists and of each random lujvo. Verified also by the law over
on-glides, whose frames read as fu'ivla.

**A capital off the penultimate syllable never reads as that brivla.** The reader refuses it, or
reads other words that the capital fits, as 3.9 warns. So `djAcadyfanta` reads `djaca dy fanta`.
Verified by `suites/test_stream.nim`, by the law over each syllable of each gismu and lujvo.

**Each refusal of a stream names the byte where it applies.** It names the first word or mark
that the reader refuses, by a rule. So a caller can point at it. Verified by
`suites/test_stream.nim`.

## Grammar

**The grammar is data: the 88 formal rules of 21.1, as CLL writes them.** The Logical Language
Group dedicates that text to the public domain, and CLL says that chapter 21 is in the public
domain. Compile time turns each rule into productions, so no rule is written twice (II.9). Static
checks hold 88 rules, each name defined, each rewrite applied once, and each unit cycle a
self-loop. Verified by the compile of `grammar.nim`, which stops where a check fails.

**The notation follows 21.1.** `|` is a choice, `[]` an option, `&` is and/or, `...` a repetition,
and `()` a group. `#` stands for free modifiers, and `/X/` for a terminator that text may elide.
`...` binds closer than `&`, and `&` closer than `|`. Verified by `suites/test_grammar.nim`, by
46 examples of chapter 5.

**A sequence binds closer than `&`, except in rule 972.** 21.1 does not say how a sequence and
`&` group. The final baseline YACC grammar settles it, since 21.1 cross-references the numbers of
that grammar. Its rule 1030 takes `ZEhA [PU [NAI]]` as one part, so a sequence binds closer.

Its rule 972 takes the `&` of tense and CAhA inside `[NAhE]` and `[KI]`, so NAhE takes CAhA alone,
as in `mi na'e ka'e tavla`. `GROUPINGS` of `grammar.nim` writes that grouping, applied once.
Verified by `suites/test_grammar.nim`, in the suite `Internal: Grammar`.

The final baseline is `grammar.300`, the third baseline of 10 January 1997, at
`lojban.org/publications/formal-grammars/`. The Logical Language Group dedicates it to the public
domain. CLL 1.1 does not print it. Verified by hand, 2026-11-06: rules 972 to 979 and 1030 to
1036 of that file give each grouping above.

Cost: `EBNF` stays the text of the book, and each grouping that 21.1 leaves open is a line beside
it. Rejected: one order for every rule, because rule 1030 then refuses `ta'e` alone as a time,
which the YACC grammar reads. Rejected: the 1993 grammar, version 2.33, which is a draft.

**Five constructs stand as one terminal, as rules 1100 and 1101 say they act before grammar.**
`ZO any-word` stands as `ZO`, and `LOhU any-word ... LEhU` as `LOhU`. `ZOI any-word anything
any-word` stands as `ZOI`, `any-word (ZEI any-word) ...` as `ZEI`, and `any-word BU` as `BU`.
`prose.nim` joins their words before the grammar reads them. Verified by `suites/test_prose.nim`.

**An Earley parser reads the terminals, and a text reads where any derivation holds it.** The
grammar holds left recursion, as `rp-operand` through `rp-expression`, and empty options. It is
ambiguous too, so recursive descent cannot read it. Verified by `suites/test_grammar.nim`,
Section 18.16, which nests reverse Polish to the left and to the right.

**Each Earley set indexes its items by the nonterminal that each one waits for.** So a completion
walks only the items that wait for the nonterminal that it completes. Each set predicts each
nonterminal once. Rejected: a walk of every item of the origin set at each completion, whose time
grows with the square of the set. Verified by `suites/test_grammar.nim` and
`suites/test_corpus.nim`, which hold the same trees and refusals. Figures gives the pair.

Cost: CLL numbers its rules by a YACC grammar, which a deterministic parser reads, and version 1.1
gives the EBNF alone. A text that such a parser stops on may still read here. Verified by hand:
CLL 1.1 holds no YACC grammar, 2026-11-06.

**The tree is the derivation that closes the fewest rules before each terminal, from the first.**
So the construct that the text opens last takes each word that it can. An elided `ke'e` closes at
the end of the selbri (Example 5.36). A relative clause after `be` attaches to the last linked
sumti, unless `be'o` closes it (Examples 5.73 and 5.74). A tie goes to the first choice of a rule.
Verified by `suites/test_grammar.nim`, Sections 5.3 to 5.7.

21.1 lets a terminator be elided "if no grammatical ambiguity results", and it orders no trees. So
the choice follows the examples of CLL. A parser that reads left to right, and prefers to read a
terminal over closing a rule, chooses the same tree. Verified by `suites/test_grammar.nim`, by the
law that a terminator left out changes no tree.

**A child of a production never spans more terminals than the symbols after it leave.** So a
child spans all of its parent only along a unit edge, and each unit cycle is a self-loop. So the
choice kept for a span never depends on a span still open. Verified by `suites/test_grammar.nim`,
Section 18.16, whose Example 18.111 the choice lost before.

**The last symbol of a production ends where its span ends.** So the choice tries that one bound
for it, and no other. Rejected: each bound for each symbol, whose cost grew with the square of the
span on a long text. Verified by hand with a probe built on the pin, 2026-11-06. Each tree and
refusal of the CLL corpus, of Tatoeba and of five articles of the lojban Wikipedia is unchanged.

**A refusal names the place where every derivation stops, and the rule that stops there.** The
rule is that of the item that waits there, has read a terminal, and started last. So `mi klama le`
is refused at its end, in `sumti-6 97`. Verified by `suites/test_grammar.nim`, in the suite
`Internal: Grammar`.

**Each word is one terminal.** A cmavo stands as its selma'o, a cmene as `CMENE`, and a gismu, a
lujvo or a fu'ivla as `BRIVLA` (21.1). A cmavo that no list gives a selma'o stands as none, so
prose refuses it. Verified by `suites/test_grammar.nim` and `suites/test_prose.nim`.

## Prose

**The rules of 19.16 act on the words in its order.** Quotation comes first, then `fa'o`, then
erasure, then `zei` and BAhE, then `bu`, then indicators. CLL gives no full order. 19.16 says what
each cmavo does not affect, and that order follows from it. Verified by `suites/test_prose.nim`.

**Each quotation is one terminal.** `zo` and the word that it quotes are `ZO`, and `lo'u` up to
`le'u` is `LOhU`. `zoi` or `la'o` with its delimiters and text is `ZOI` (19.9, 19.10).
`lo'u` that quotes no word, or that never closes, is refused as `Quotation`. Verified by
`suites/test_prose.nim`, Sections 6.14, 19.9 and 19.10.

**Erasure acts on words.** `si` erases the word before it, and `su` each word before it. `sa`
erases back to the last word of the selma'o of the word after it, that word included (19.13). A
quotation counts as its words, so a `zo` quotation is two words and a `zoi` quotation four
(Examples 19.77, 19.79). Verified by `suites/test_prose.nim`, Section 19.13. Verified also by a
law over a word and `si` at each place between the words of each example with no erasure.

**`sa` erases back to the start where no word of its selma'o stands.** So Example 19.81 erases
the sentence before `.i`, as CLL says, though no `.i` opens the text. Verified by
`suites/test_prose.nim`, Section 19.13.

Cost: 21.1 rule 1101 and chapter 20 give `sa` the scope of an utterance, and `su` that of a text.
The reader takes the words that 19.13 describes, as one speaker writes the whole text. Verified by
`suites/test_prose.nim`, Section 19.13.

**An erasure that leaves part of a quotation is refused.** The quotation is read before the
erasure, and never again after it. 19.13 says that the parser rejects `zo .djan. si .djordj.`,
and the reader refuses it as `Quotation`. Verified by `suites/test_prose.nim`, Section 19.13.

**`zei` joins the word before it and the word after it into one terminal (4.6).** A chain of
`zei` joins into one. Neither word may be a cmavo that 19.16 says `zei` does not affect.
Verified by `suites/test_prose.nim`, Section 4.6.

**BAhE marks the next word, `bu` makes a lerfu word, and an indicator marks the word before
it.** BAhE gives its word nothing more (rule 1100), and one `bu` or more makes the word before it a
lerfu word (17.4). UI or CAI takes a `nai` after it, and `y`, `da'o`, `fu'e` and `fu'o` mark too
(13.9, 19.16). Indicators that open a text stand as terminals, which rule 0 reads. Verified by
`suites/test_prose.nim`, Sections 13.1 to 13.10, 17.4 to 17.8, and 19.8.

**A refusal of prose names its rule and its byte.** `Stream` carries the refusal of the stream,
and `Grammar` the rule of 21.1 that stops. `Selmaho` names a cmavo with no selma'o. `Quotation`
and `Construct` name a quotation, or a cmavo of 19.16, that the words cannot complete. Verified by
`suites/test_prose.nim`.

**The grammar settles no split that ties.** The stream gives the words before the grammar reads
them. So a tie that the stream refuses refuses the text as `Stream`, though one tied split alone
may read. The Architect ruled so (`D4 a` on #811). Verified by `suites/test_prose.nim`, in the
suite `Internal: Prose`.

The rules of chapter 4 split a stream by the letters, stress and pauses of its words (4.1). A
split that the grammar chose could read as the writer did not mean. `la .lauras. klama` ties as
`lau .ras.` or `la .uras.`, and only `la la .uras. klama` reads. That is a fragment of one sumti,
where the text means a name, `lauras`, which 4.8 forbids. Verified by `suites/test_prose.nim`, in
the suite `Internal: Prose`.

## What cmavo bind

**A tanru folds into tanru units, and each tanru unit is one part with the cmavo that bind it.**
The grammar of CLL gives that name (21.1, rule 152), which the Architect selected for
`lojban_tagger` (#768). SE binds the next brivla or "equivalent unit" (9.4), and NAhE binds close
to its brivla (15.4). A NU rafsi modifies the next tanru unit alone (12.12). Each other cmavo binds
nothing, and stands as a tanru unit of its own where it does more than group. Verified by
`suites/test_tanru_units.nim`.

**Each folded cmavo carries the selma'o of its role in the fold, as the cmavo list gives it.** The
cmavo of SE carry SE, those of NU carry NU, and those of NA and NAhE carry those two. `ke`,
`ke'e`, `kei`, `bo` and `co` carry KE, KEhE, KEI, BO and CO. So the fold and the cmavo list never
part. Verified by the static check of `tanru_units.nim`, which each build runs.

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

**`kei` closes an abstraction.** Rule 152 of 21.1 ends a NU with `kei`. So the fold reads `kei` as
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

Rule 152 of 21.1 makes a number and its MOI one tanru unit. The fold keeps each digit as a tanru
unit of its own. Cost: `relpavmomci'a` folds `re`, `pa` and `moi` apart, although together they
make the ordinal 21. Verified by `suites/test_tanru_units.nim`, in the suite
`Internal: Convention`.

JAI binds as SE does (5.11), but the gismu list gives `jai` no rafsi, so no lujvo of the list
holds it. CLL 12.12 gives `jai` the rafsi `jax`, which the gismu list does not hold. A static
check in `tanru_units.nim` stops the build where the gismu list gains `jai`.

## Corpus of CLL

**`tests/cll/` holds the lojban lines of each numbered example of CLL 1.1, under the notice of the
book.** The Architect ruled D1 a on #815, so the repository commits these lines in a folder of
their own. `tests/cll/NOTICE.md` holds the copyright notice and the permission notice of the book,
verbatim. It also says that the lines are extracted, and it names each modification, as the notice
asks. Verified by hand, 2026-11-06: each paragraph that it quotes is the paragraph of the page,
word for word, once the address is decoded.

The notice permits a modified copy only under its own terms. So the folder is distributed under
that notice, and not under the licence of the repository.

**The verb `nim r tools/build.nim cll <directory>` writes both files from saved pages of the
book.** The pages are those of `URL_CLL` in `tools/cll.nim`, one section to a page, each saved
under its own name. The verb reads each page that holds an example, and the page of Section 1.8,
which holds the notice. It checks one SHA-256 over those pages against `DIGEST_CLL`, so a page
that the server changes makes the verb refuse. That digest is the SHA-256 of the output of
`sha256sum` over the pages, given in order of name.

`DIGEST_CLL` pins the pages that lojban.org served on 2026-11-05. Verified by hand, 2026-11-06:
`sha256sum` over the pages that hold `<div class="example">`, and `section-copyright.html`, piped
into `sha256sum`, gives `DIGEST_CLL`. Verified by hand with the verb, 2026-11-06: a page that
differs by one comment makes it refuse, and it writes no file.

**A line is lojban where the markup of the book gives it the class `jbo` or `jbophrase`.** The
cells of a row of a table join with one space, and a paragraph is one line. A no-break space
becomes a space, and the markup of the line goes. The text keeps its brackets and its notation, so
the suite decides which lines it reads. Verified by hand with a separate extraction in Python 3,
2026-11-06: it gives the same lines, line by line, for chapters 2 to 19. Verified by hand against
its page, 2026-11-06: Example 1.1, the one example of chapter 1, is `mi klama le zarci`.

Lines of the classes `pronunciation-jbo` and `compound-cmavo-jbo` stay out. The book judges each
of them in prose, and `suites/test_stream.nim` and `suites/test_forms.nim` hold those judgments by
hand, as chapters 3 and 4 give them. Verified by `suites/test_stream.nim` and
`suites/test_forms.nim`, whose citations name each example.

Cost: the verb reads each page as XML once it cuts each `script` element, whose code holds an `&`
that XML forbids. A page that the server sends as HTML alone stops the verb, which names the page.
Verified by hand with the verb, 2026-11-06, on a page that holds an unclosed `br`.
The server also hides the email address of the notice in an encoded attribute, and the verb
decodes it. Rejected: `std/htmlparser`, which Nim 2.4.0 deprecates in favour of a package.
Rejected: a read of the pages by the suite, because each run would then need pages that the
repository does not hold.

**The suite reads each example that the book calls grammatical.** An example reads where its lines
joined read, or each line alone. The markup does not say whether the lines of a table are one
sentence. Each text reads with the words that square brackets mark, and without them (5.5).
Verified by `suites/test_corpus.nim`, which asserts the count of examples that read.

A line that holds notation stays out: a digit of a place variable, an ellipsis, a parenthesis, a
colon after a speaker, or a hyphen. An example whose every line holds notation reads nothing.
Verified by `suites/test_corpus.nim`, which asserts the count of examples and of lines that
notation leaves out.

**The suite refuses each example that the book calls wrong.** Example 4.4 is a cmavo "reserved for
experimental purposes", and no list gives it a selma'o. Example 4.77 is "an illegal word in
standard Lojban". Example 19.50 is "ungrammatical as written", because its delimiter stands inside
the text that it quotes. Example 16.79 is an English sentence, which the markup marks as lojban.
Verified by `suites/test_corpus.nim`.

**Examples 18.77, 18.78, 18.105, 18.106, 18.108 and 18.109 write a mex alone, and each reads after
`li`.** No rule of 21.1 reads a mex as a whole text, and the book shows each one as the operand of
`li`. Verified by `suites/test_corpus.nim`.

**Where an example breaks a rule of 21.1, the parser follows 21.1, as the Architect ruled D2 a on
#815.** The parser refuses each example of the list, which gives the rule that each one breaks.
Each reads once it is repaired as its rule asks. Verified by `suites/test_corpus.nim`, which holds
each refusal and each repair.

- **14.27**, rule 10 `paragraph`: a fragment takes a bare `.i`, and `.ije` joins statements
  alone. With `.i` for `.ije`, it reads.
- **14.123**, rule 81 `terms-1`: `pe'e` takes a joik or a jek, and never the ek `.e`. With `je`
  for `.e`, it reads.
- **14.131**, rule 85 `termset`: `nu'u` closes a termset only after `nu'i`. With `nu'i` before
  the terms, it reads.
- **14.133**, rule 85 `termset`: a termset joins its parts by gek and gik, and never by `fa'u`
  after `nu'u`. With `pe'e fa'u` for `nu'u fa'u`, it reads.
- **14.152 and 18.118**, rule 371 `operator-1`: a forethought operator takes `gu'e`, and never
  `ge`. With `gu'e` for `ge`, each reads.
- **17.38 and 18.123**, rule 97 `sumti-6`: a subscript after a lerfu string needs `boi` before
  it. With `boi` before `xi`, each reads. Example 14.154 writes the text of 18.123 with `boi`.
- **18.122**, rule 806 `joik`: `ke'i` stands on each side of the interval `bi'o`. With
  `ke'i bi'o ke'i`, it reads.

## Sample of Tatoeba

**`tests/sample_tatoeba/` holds a fixed sample of the lojban sentences of Tatoeba, with the verdict
that the parser gives each.** The Architect ruled D1 a on #819, so the repository holds sentences
of Tatoeba. The Architect then ruled D4 c there: the export only grows, so the sample is fixed. It
is also diverse, so its sentences reach as many rules of CLL as they can.

The folder is under CC BY 2.0 FR, the licence of Tatoeba, and not under the licence of the
repository. `tests/sample_tatoeba/NOTICE.md` names each change, and credits Tatoeba and each
owner of a sentence of the sample.

**The verb `nim r tools/build.nim tatoeba <export>` writes both files from the export.** The
export is `jbo_sentences_detailed.tsv.bz2` at `URL_TATOEBA` of `tools/tatoeba.nim`, decompressed.
`DIGEST_TATOEBA` pins that file as Tatoeba served it on 2026-11-05, from the export of 2026-10-31.
The verb reads each sentence through the parser once. It prints the count of each verdict over the
whole export. Verified by hand with the verb, 2026-11-06: it writes both files byte for byte as
committed.

Cost: a newer export moves the pin, and the verb may then pick another sample. The sample stays
fixed until somebody moves the pin and writes it again.

**A feature is what the reading of a sentence shows.** One is the shape of each named rule of the
tree. A shape is the rule with the labels of its children, and a run of one label collapses. Others
are each terminal, each construct of 19.16 that holds several words, each kind of word, and each
form of rafsi and hyphen. The marks of the stream count too: a pause, a stress, a comma and quoted
text. A refused sentence shows one feature, its refusal with the rule where reading stops.

Verified by `suites/test_tatoeba.nim`, which counts the features that the sample reaches.

**The sample is a greedy cover of the features.** The sentence that adds the most features not yet
reached comes first. A tie goes to the shorter text, then to the lower number. The cover stops
where no sentence adds a feature.

Cost: a greedy cover is not the least cover, which is NP-hard to find. Rejected: a seeded random
sample, which ruling D4 c replaces. Rejected: the whole export on each push, which costs about
57 s of a debug build.

The sample holds 234 sentences, which reach 599 features. They reach 86 of the 88 named rules of
21.1. No sentence of the export reaches `rp-expression` or `rp-operand`, and
`suites/test_grammar.nim` holds both by Section 18.16. Verified by hand with the verb, 2026-11-06.

**The suite holds each verdict of the sample.** A sentence that reads must read. A refused one must
give the same refusal and rule, so a change of the parser that moves a verdict fails, and names the
sentence. Each refused sentence of the sample is read against CLL 1.1, and `IDS_REFUSED` cites the
rule that it breaks. Verified by `suites/test_tatoeba.nim`.

**Each class of refusal over the whole export breaks a rule of CLL 1.1.** The verb gives these
counts for the export of 2026-10-31, and 16,469 sentences read. A class is the refusal, with the
rule where reading stops. The table names the sentence of the sample for each class, and the rule
of CLL that it breaks. That rule can differ from the rule where reading stops.

Verified by hand, 2026-11-06: each class was read against CLL, by its sentence of the sample and by
other sentences of it. One parser mistake came out of that reading, and rule 972 now holds its fix.

| Refusal | Count | Sentence | Rule broken |
| --- | --- | --- | --- |
| Selmaho | 485 | 2808680 | chapter 20 |
| Stream Letter | 93 | 3843946 | 3.1 |
| Grammar bridi-tail 50 | 48 | 2853152 | 152 |
| Grammar sumti-6 97 | 47 | 2577894 | 97 |
| Grammar selbri-4 134 | 36 | 2253980 | 134 |
| Grammar terms-1 81 | 34 | 645284 | 97 |
| Stream Stress | 29 | 5912012 | 3.9 |
| Stream Shape | 28 | 4412245 | 4.1 |
| Grammar tanru-unit-2 152 | 24 | 2864592 | 152 |
| Stream Hyphen | 23 | 1484737 | 4.11 |
| Grammar paragraphs 4 | 21 | 2793895 | 97 |
| Grammar tail-terms 71 | 14 | 1576931 | 111 |
| Grammar sumti-tail-1 112 | 13 | 5181396 | 152 |
| Grammar simple-tense-modal 972 | 11 | 2626994 | 972 |
| Grammar text 0 | 9 | 2119742 | 97 |
| Stream Breakup | 9 | 1502454 | 4.8 |
| Grammar sumti-4 94 | 8 | 4436842 | 807 |
| Stream Cluster | 8 | 13820484 | 3.6 |
| Grammar selbri 130 | 7 | 12406452 | 4.8 |
| Grammar sentence 40 | 7 | 656510 | 972 |
| Grammar sumti-5 95 | 7 | 5183488 | 383 |
| Grammar guhek 808 | 5 | 2802254 | 972 |
| Grammar sumti-tail 111 | 5 | 2063807 | 111 |
| Grammar free 32 | 4 | 634760 | 4.8 |
| Grammar gihek 818 | 4 | 2108189 | 131 |
| Grammar selbri-1 131 | 4 | 8738058 | 40 |
| Grammar selbri-2 132 | 4 | 4167581 | 112 |
| Stream Quotation | 4 | 3807297 | 19.10 |
| Grammar sumti 90 | 3 | 3083055 | 97 |
| Stream Slinkuhi | 3 | 2159050 | 4.7 |
| Stream Split | 3 | 4285480 | 3.3 |
| Grammar gek 807 | 2 | 3989793 | 97 |
| Grammar jek 805 | 2 | 2312326 | 131 |
| Grammar mex 310 | 2 | 3855768 | 812 |
| Grammar operand-3 385 | 2 | 3807272 | 385 |
| Grammar relative-clause 122 | 2 | 8639562 | 122 |
| Grammar selbri-5 135 | 2 | 4226728 | 135 |
| Grammar stag 971 | 2 | 2803459 | 81 |
| Stream Apostrophe | 2 | 5181743 | 3.3 |
| Grammar ek 802 | 1 | 657753 | 131 |
| Grammar gek-sentence 54 | 1 | 645249 | 972 |
| Grammar interval 932 | 1 | 2688629 | 161 |
| Grammar linkargs 160 | 1 | 8721221 | 160 |
| Grammar selbri-6 136 | 1 | 2024281 | 97 |
| Grammar statement-1 12 | 1 | 2988210 | 152 |
| Grammar tense-modal 815 | 1 | 10789002 | 152 |
| Grammar text-1 2 | 1 | 678056 | 1100 |
| Grammar time 1030 | 1 | 2332321 | 50 |
| Stream Comma | 1 | 4225380 | 3.3 |


## Articles of Wikipedia

**`tests/articles_wikipedia/` holds three long articles of the lojban Wikipedia, with the verdict
that the parser gives each paragraph.** The Architect ruled D5 c on #819: a folder holds long
articles under CC BY-SA, and each run reads them. The folder is under CC BY-SA 4.0, and not under
the licence of the repository. `tests/articles_wikipedia/NOTICE.md` names each change, and credits
each article by its revision and its history.

The articles are `cmaci`, `eliogabalus` and `lo jbobau`. They are the long articles of prose that
the parser reads most of. Rejected: the pages of years, which write dates in digits and read none.
Rejected: `toldi`, of which 9 of 55 paragraphs read. Verified by hand with a probe built on the
pin, 2026-11-06, over the longest pages that the API lists.

**The verb `nim r tools/build.nim wikipedia <directory>` writes both files from saved answers of the
API.** Each answer is saved by `QUERY` of `tools/wikipedia.nim`, one file to a page, named by the
number of the page. `DIGEST_WIKIPEDIA` pins the answers, as `DIGEST_CLL` pins pages, and a newer
revision of an article moves it. Verified by hand, 2026-11-06: `sha256sum` over the answers, piped
into `sha256sum`, gives `DIGEST_WIKIPEDIA`.

**A paragraph is one line of the plain text, and the suite reads it as one text of 21.1.** So the
suite reads connected text of several sentences, and the longest paragraph holds 458 words. A
heading is left out. Cost: a line that continues the sentence of the line before it, as an item of
a list does, reads alone. Verified by `suites/test_wikipedia.nim`, whose citation names the line
that such a line reads with.

**69 of the 86 paragraphs read, and each refused paragraph breaks a rule of CLL.** Ten write a
digit, which is no letter of lojban (3.1). Three continue a line before them, as lines 2 and 3 of
`cmaci` continue line 1. The others put `la` inside a cmene (4.8), take one word of a compound with
`zei` (4.6), or put a capital on a consonant (3.9). Verified by `suites/test_wikipedia.nim`, which
cites the rule beside each paragraph.

## Translations

**The suites read the translations of Alice and Oz where their pinned pages are present.** The
Architect ruled D3 a on #819: each translation is pinned and kept out of the repository, since no
translator stated a release. The Architect then ruled D5 c, that the suites read Alice and Oz
where the pinned pages are present. The runner holds no page, so it skips both. Verified by
`suites/test_translations.nim`, which skips each page that is absent.

**The verb `nim r tools/build.nim translations` fetches each page with `curl` into
`build/translations/`.** It checks the digest of each page against its pin in `TRANSLATIONS` of
`tools/translations.nim`. The digest is of the page with each `script` element cut, since the
server of Alice writes a script that differs at each request. Verified by hand, 2026-11-06: two
fetches of Alice differ in that script alone.

**A paragraph is the text of one `p` element, and reading drops each mark that CLL does not
define.** The marks are guillemets, dashes, parentheses, the colon and the asterisk. They are also
the marks of question and exclamation, the quote, and the accent or breve over a vowel. Capitals
stay, since CLL 3.9 defines them as stress. The page of Oz holds Windows-1252, though its header
declares UTF-8, and the reader converts it.

Cost: the accent of Oz marks stress, and reading drops it, so each brivla reads with the stress
that its form gives. Rejected: an accent read as a capital. Oz marks secondary stress too, as
`jbìbì'o`, and CLL 3.9 forbids a false primary stress in a brivla.

**Alice reads 783 of 856 paragraphs, and Oz 56 of 173.** A paragraph of Oz holds about 300 words,
and up to 2,233, so one mistake refuses all of it. The suite holds both counts. Verified by
`suites/test_translations.nim`, where the pages are present.

**Each refusal of the translations breaks a rule of CLL, as the first place where it stops
shows.** In Alice, a quotation often opens in one paragraph and closes in another. Other refusals
put `.i ba bo` or `.i je` after a fragment (rule 10, as Example 14.27 does). Some put a free
modifier after a lerfu word or number whose `boi` is elided (rules 97 and 300). Some put a tense
in an order that rules 972 and 1030 forbid, or write a word in capitals (3.9).

In Oz, many refusals put a brivla and a cmene together after `la` (rule 97). Others write `ni'o ba
bo` (rule 2), `ku` after a cmene (rule 97), or a cmavo that CLL 1.1 does not define. The page also
cuts some words where a cell of its table ends, as `zdà.i`, and some hyphens break 4.11. No
refusal of either text is a mistake of the parser. Verified by hand, 2026-11-06, by the first stop
of each refused paragraph.

The final baseline YACC grammar also takes a free modifier after `boi` alone. Its elided `boi` is
the branch `error` of `BOI_gap_461`, which holds no free modifier. Verified by hand, 2026-11-06,
in `grammar.300`.

## JavaScript build

**One function gives the reader of prose to JavaScript.** `src/javascript/bridge.nim` exports
`parseLojban(text)`, and the verb `javascript` compiles it with the whole parser into
`build/lojban_parser.js`. The function returns what `readText` gives, as a plain object. The object
holds each field of `ReadingText`, and each value of an enum as its name, as `KOhA`. Verified by
`test_javascript.nim`.

**A refused text also carries `stream`, which `readStream` gives.** So a caller sees the words
before a refusal of the grammar, or the refusal of the stream with its detail. The bridge reads the
stream a second time for it. On the JavaScript build, `readStream` reads the sample in about 1.4
percent of the time of `readText` (Figures, JavaScript build). Verified by `test_javascript.nim`.

**`start` counts the bytes of the text in UTF-8, as the parser reads them.** For a text of ASCII
alone, a byte is also an index of the string of JavaScript. Beyond ASCII the two differ, so a page
that marks the place of a refusal converts the byte to an index first. Verified by
`test_javascript.nim`, where `start` gives 34 and the index of JavaScript gives 32.

**The script loads in a page and in node alike.** It defines `parseLojban` as a global, and sets
it on `module.exports` where node loads the script as CommonJS. A page has no `module`, so the
script reads it through `typeof`, which does not throw there. Verified by `test_javascript.nim`
for node. Verified by hand in headless Chromium 153.0.8010.12 through Playwright, 2026-11-08. A
`script` element loads the script, and a call reads one text and refuses another with no error.

**The object holds values of JavaScript alone.** Rejected: a text of JSON, which the caller would
parse again. A plain object is a value of the runtime of the caller, so no format of data goes
between two programs (CONTRIBUTOR.md, Data).

**The mirror reads each child of the tree, and each unit, by its index.** On the JavaScript
backend, a loop over `items` of `node.children` or of `reading.units` copies each value. The copy
of a node copies its whole subtree. Rejected: those loops, which took 12.6 s over the sample in one
run, against 11.4 s and 11.5 s by index. Verified by hand with `grep -c nimCopy` over each routine
of the mirror in the script, 2026-11-08: none copies.

**The verb builds with `-d:release`, and the suite compiles with it too.** On the pin, the define
keeps every check and drops the traces of stack and line (`config/nim.cfg`). So the suite holds
the build that ships, and a failed check still names its line. Rejected: `-d:danger`, which
removes each check of bounds and range from the build that a caller runs. Cost: an exception
names no line of Nim (expected). The verb takes the compiler that compiled the driver.

**Cost: the script reads about 32 times slower than the native build, on the thread of its
caller.** So a page waits while it reads. A text of the sample takes 19 ms at the median, against
0.56 ms and 0.57 ms native. The longest, of 771 bytes, takes 633 ms, against 21 ms and 28 ms
native. Figures, JavaScript build, gives the method. At `5fa0c368`, the verb writes 718,891 bytes,
and prints the size.

## Tests

**One stub runs every suite as one program.** `tests/test_suites.nim` imports each file of
`tests/suites/` whose name opens with `test_`, in the shape that STYLE.md section 6 gives. Each
suite still runs alone. A suite that CLL covers carries the name of a chapter. The name of each
other suite opens with `Internal:`, so the run shows where the authority stops.

`tests/cll/examples.nim` is data beside the suites, and `suites/test_corpus.nim` reads it.
`tests/sample_tatoeba/sentences.nim` is data too, and `suites/test_tatoeba.nim` reads it.
`tests/articles_wikipedia/articles.nim` is data, and `suites/test_wikipedia.nim` reads it.

Helpers stand beside the suites, and the stub runs none of them. `suites/texts_outside.nim` reads
the outside texts by their pins. `suites/rafsi_random.nim` spells random rafsi from the letters of
each form. So the suites of the reader and of lujvo share one way to draw them (II.9).

`suites/test_tanru.nim` holds the reader, `suites/test_stream.nim` the reader of a stream, and
`suites/test_tanru_units.nim` the fold. No suite here has a copy in `lojban_tagger`, whose suites
hold the modules of the tagger alone, tag policy and search among them. Each assertion cites its
source: a section of CLL, or the article of the charter that a guard holds.

**The JavaScript build runs in a stub of its own.** `tests/test_javascript.nim` runs on the
JavaScript target under node, since `std/jsffi` compiles on that target alone. It holds each
sentence of the sample of Tatoeba to the verdict that the native build gave it. It compiles the
bridge with `-d:release`, as the verb does. So the bridge stays in step with the parser, and no
suite loads `build/lojban_parser.js` itself.

**A failed check of the stub exits 1 only under the define `nodejs`.** Under node 22.23.4, a probe
with a check that fails exits 0 without the define. Testament and the assayer pass the define for
the JavaScript target, in `$options`, so the command of the stub names none. The stub stops its
compile where the define is missing, so a compile by hand cannot pass in silence. Verified by hand
with testament on the pin, 2026-11-08: a copy with one wrong expectation fails, and names the line
of its check.

## Toolchain

**The compiler is pinned exactly**: `requires "nim == 2.4.0"` in `lojban_parser.nimble`, as each
project of the repository pins it (D1 a on #775). The project needs the standard library alone,
so it carries no lock. The verbs `lists` and `head`, and the tests of outside texts, also need
`lojban-common` and `sha256sum`, which the verb `system` declares. The verbs `cll`, `tatoeba` and
`wikipedia` need `sha256sum` too. The verb `translations` needs `curl`, which `system` declares.
The suite of the JavaScript build needs node, which `system` declares as `nodejs`.

A system package carries no pin, so its version is what the machine has.

The stub passes on the pin and on Nim 2.2.12.
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

Each figure comes from an Intel Xeon at 2.10 GHz with four cores. A figure is from 2026-11-05, at
the code of `bf40939a`, unless it names another date and code. The runs of each
pair alternate between Nim 2.2.12 and the pin, 2.4.0, so both share the load of the machine. A
pair against the base alternates `40718874`, the head of #828, with this code, on the pin.

- **Front end check of the umbrella.** `nim check --hints:off src/lojban_parser.nim` took 0.95 s,
  0.94 s and 0.93 s on 2.4.0, against 0.79 s, 0.77 s and 0.79 s on 2.2.12. So 2.2.12 is faster
  by about 0.15 s by this measure.
- **Suites from an empty cache.** `nim c -r --hints:off -d:testing tests/test_suites.nim`
  compiled and ran every suite in 17.6 s and 17.4 s on 2.4.0, against 17.8 s and 17.1 s on
  2.2.12. Each run started with an empty cache.
- **Suites alone.** The built binary ran every suite in 11.0 s and 11.0 s on 2.4.0, against
  11.0 s and 11.2 s on 2.2.12. The base ran in 6.5 s and 6.5 s, so this code costs about 4.5 s,
  most of it the suite of the stream.
- **Stream alone.** The suite of `test_stream.nim` builds alone, without optimisation. It ran in
  4.2 s, 4.2 s and 4.0 s on 2.4.0, against 4.0 s, 4.0 s and 3.9 s on 2.2.12. Its laws read 4000
  runs of words written together, and each position of each word of the lists.
- **Forms alone.** The suite of `test_forms.nim` builds alone, without optimisation. It ran in
  2.02 s, 2.02 s and 2.10 s on 2.4.0, against 2.03 s, 2.07 s and 2.13 s on 2.2.12. The base ran in
  2.01 s, 2.02 s and 2.04 s, so the spreads meet.
- **Tatoeba.** A program built with `-d:release` read the 17,495 sentences of the Tatoeba export
  through `readStream`. It took 0.24 s, 0.22 s and 0.21 s on the pin, the read of the file
  included. So one sentence takes about 13 microseconds. It read 17,170 of them whole.
- **Render of tanru.** On 2026-11-08, on the pin, a program built with `-d:release` rendered
  prefixes of the tanru of 18 words that #782 names. Each figure is the median of three renders.
  At `3f769b36`, the search over every sequence took 0.036 ms for 4 words and 4.0 ms for 8. It
  took 45 ms for 10 and 483 ms for 12.
- **Render of tanru, by table.** The same program at `954d51af` took 0.008 ms, 0.011 ms, 0.011 ms
  and 0.013 ms for those prefixes, and 0.019 ms for all 18 words. Both searches gave one form for
  each prefix that both rendered.
- **Prose of Tatoeba.** On 2026-11-06, at `6a44ab94`, a program built with `-d:release` read the
  17,495 sentences through `readText`. It took 10.2 s and 10.4 s on the pin, so one sentence
  takes about 0.6 ms. It read 16,469 of them.
- **Sample of Tatoeba.** On 2026-11-06, at `6a44ab94`, the suite of the sample, built alone as
  the stub is, ran in 2.7 s and 3.0 s.
- **Long texts.** On 2026-11-06, at `8f14bfdd`, the suite of the articles of Wikipedia, built
  alone, ran in 3.4 s and 3.6 s. The suite of the translations ran in 27.7 s and 27.8 s with both
  pages present. Without them, as on the runner, the stub ran every suite in 27.0 s and 27.5 s.
- **Indexed Earley sets.** On 2026-11-06, on the pin, the stub built with `nim c -d:testing
  -d:nimUnittestOutputLevel:PRINT_FAILURES tests/test_suites.nim` ran every suite in 21.5 s and
  21.6 s at `67b4773b`. At `487f618c`, whose completion walks each origin set whole, it ran them
  in 43.9 s and 43.2 s. The runs alternate.
- **Corpus of CLL.** On 2026-11-06, the suite of the corpus was built alone in the same way. It
  ran in 5.8 s and 5.9 s at `67b4773b`, against 21.8 s and 21.8 s at `487f618c`.
- **Corpus by stage.** On 2026-11-06, at `67b4773b`, a program read each line of the corpus. It
  was built on the pin with `nim c`, with no optimisation. It read the lines through `readStream`
  in 0.10 s and 0.14 s, and through `readText` in 3.97 s and 4.01 s. So the grammar takes most of
  the time of `readText`.
- **Long text.** On 2026-11-06, a program built the same way read 86 paragraphs of three articles
  of the lojban Wikipedia. It took 3.1 s at `e5b6e632`, and 9.2 s at `a6e61b33`, before the last
  symbol of a production tried one bound. Its longest paragraph, 458 words, took 397 ms against
  2,144 ms. The tree choice took nearly all of that time, and the fill of the sets 50 to 71 ms.
- **Suites, last symbol.** On 2026-11-06, the stub ran every suite in 23.5 s and 22.5 s at
  `e5b6e632`, against 23.7 s and 23.5 s at `a6e61b33`. The suite of the corpus ran in 5.6 s and
  5.3 s, against 6.5 s and 6.1 s. The runs alternate, and the spread of the stub meets.
- **JavaScript build.** On 2026-11-08, at `5fa0c368`, on the pin, each program read the 234
  sentences of the sample of Tatoeba seven times in one run. Each program ran twice, and each
  figure is the median of one run. A native program built with `-d:release` read them through
  `readText` in 349 ms and 366 ms. Built with `nim js` and run under node 22.23.4, the same
  program took 11.6 s and 11.7 s. `parseLojban` of the script, with the mirror and the second read
  of the stream, took 11.4 s and 11.5 s.
- **JavaScript build, stream.** Built the same way, a program read the sample through
  `readStream` in 163 ms and 166 ms.
- **JavaScript build, one text.** After a first pass over the sample, the script read each text
  once, in one run. It took 19 ms at the median, and 633 ms at most. The native build took 0.56 ms
  and 0.57 ms at the median, and 21 ms and 28 ms at most, in two runs.

## Open questions

- **The 4-letter rafsi `brod`.** Five gismu share it, and CLL does not say which one it names. The
  reader reads it as a part with the letters `brod`. `brodi`, `brodo` and `brodu` have no short
  rafsi, so a tanru that holds one of them before its last word renders with `brod`. It then
  reads back with that part, and not with the gismu.
- **The algorithm that splits a stream.** CLL 4.1 gives no algorithm, so the split is the
  reader's. It rests on the rules that CLL gives, and the laws hold it to them. CLL fixes no
  choice among splits whose stress fits, whether or not they need the same pauses. The reader
  takes the split of fewest pauses, and refuses a tie, as `iai` for `.i.ai` or `.ia.i`.
- **Scopes that CLL gives two ways.** 19.13 and 21.1 give `sa` and `su` different scopes. 13.9,
  13.1 and 2.16 give an indicator that opens a text three scopes. 19.16 calls `fu'e` the same as
  UI, where 21.1 rule 411 sets it before the indicators that it opens.
- **The tree beyond the grammar.** The fold keeps no grouping that no cmavo binds, and no number
  with its MOI. The tree of 21.1 holds both, and no module yet reads meaning from it.
