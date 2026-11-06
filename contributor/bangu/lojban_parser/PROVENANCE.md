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
which stands apart from it. The project reads lojban words, and streams of them, by the rules of
CLL alone, and holds no grammar of prose.

`lojban_tagger` keeps a copy of each module here until #809 moves the tagger onto this parser.
It holds no copy of `selmaho.nim`, `lists/cmavo.nim`, `fuhivla.nim` or `stream.nim`.
Where a module differs, the copy in `lojban_tagger` is earlier, and reads listed words alone. The
header of each module names its sibling there, as Article II.9 asks, and `tools/lists.nim` names
the sibling of the list that it renders. A fix to one copy is finished only when the other is
checked.

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
the letterals, chapter 20 is the catalogue of selma'o, and 21.1 gives the rule of a tanru unit.

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

**Each refusal names the rule of CLL that refuses the text, or the gap that holds it.** `Letter`
names 3.1 and 3.3, `Apostrophe` names 3.3, `Shape` names 3.3, 4.2, 4.3 and 4.8, and `Hyphen`
names 4.11. `Cluster` names 3.6, 3.7 and 4.7, `Breakup` names 4.8, and `Combination` and
`Slinkuhi` name 4.7. `Stream` names text that `readStream` reads: marks of a stream, and cmavo run
together. A stream alone gives `Stress` (3.9), `Comma` (3.3, 3.4) and `Split` (3.3). Verified by
`suites/test_tanru.nim` and `suites/test_stream.nim`.

**A gap is text that CLL admits and that the reader does not read yet.** `Foreign` holds the text
that `zoi` and `la'o` quote, for #814. Verified by `suites/test_stream.nim`, Section 4.9.

Cost: a gap also holds text that no rule admits, as `zoi` with no quotation after it. The issue
of the gap tells the two apart. Verified by `suites/test_stream.nim`, Section 4.9.

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
lujvo list, with `readTanru` and `toText`, which read and write it.

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

Rule 7 holds the text that `zoi` and `la'o` quote, which is not lojban. So the reader stops at
either, as the gap `Foreign`, which #814 reads. Verified by `suites/test_stream.nim`, Section 4.9.

Cost: `zo zoi` quotes the word `zoi`, but the reader stops there too, because #814 reads `zo`.
Verified by `suites/test_stream.nim`, Section 4.9.

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
that the reader refuses, by a rule or as a gap. So a caller can point at it. Verified by
`suites/test_stream.nim`.

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

## Tests

**One stub runs every suite as one program.** `tests/test_suites.nim` imports each file of
`tests/suites/` whose name opens with `test_`, in the shape that STYLE.md section 6 gives. Each
suite still runs alone. A suite that CLL covers carries the name of a chapter. The name of each
other suite opens with `Internal:`, so the run shows where the authority stops.

Helpers stand beside the suites, and the stub runs none of them. `suites/texts_outside.nim` reads
the outside texts by their pins. `suites/rafsi_random.nim` spells random rafsi from the letters of
each form. So the suites of the reader and of lujvo share one way to draw them (II.9).

`suites/test_tanru.nim` holds the reader, `suites/test_stream.nim` the reader of a stream, and
`suites/test_tanru_units.nim` the fold. Each suite but `suites/test_selmaho.nim` and
`suites/test_stream.nim` has a sibling in `lojban_tagger`. That
sibling holds an earlier copy, and the header of the suite names it (II.9). The tests of tag
policy and of search are in `lojban_tagger` alone. Each assertion cites its source: a section of
CLL, or the article of the charter that a guard holds.

## Toolchain

**The compiler is pinned exactly**: `requires "nim == 2.4.0"` in `lojban_parser.nimble`, as each
project of the repository pins it (D1 a on #775). The project needs the standard library alone,
so it carries no lock. The verbs `lists` and `head`, and the tests of outside texts, also need
`lojban-common` and `sha256sum`, which the verb `system` declares. A system package carries no
pin, so its version is what the machine has.

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

Each figure comes from an Intel Xeon at 2.10 GHz with four cores, on 2026-11-05, at the code of
`bf40939a`. No figure covers the code after it. The runs of each
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
- The time of `$` is unmeasured here. `$` scores each choice of rafsi, so its time grows with the
  product of the choices of each word (expected).

## Open questions

- **The 4-letter rafsi `brod`.** Five gismu share it, and CLL does not say which one it names. The
  reader reads it as a part with the letters `brod`. `brodi`, `brodo` and `brodu` have no short
  rafsi, so a tanru that holds one of them before its last word renders with `brod`. It then
  reads back with that part, and not with the gismu.
- **The algorithm that splits a stream.** CLL 4.1 gives no algorithm, so the split is the
  reader's. It rests on the rules that CLL gives, and the laws hold it to them. CLL fixes no
  choice among splits whose stress fits, whether or not they need the same pauses. The reader
  takes the split of fewest pauses, and refuses a tie, as `iai` for `.i.ai` or `.ia.i`.
- **What the parser does not read.** It reads no prose: no bridi, no sumti, and no selbri past
  the tanru units of one word. A stream reads into its words. The reader stops at the text that
  `zoi` and `la'o` quote, which #814 reads with erasure, `zei` and `bu`. The fold keeps no
  grouping that no cmavo binds, and no number with its MOI, which prose needs.
