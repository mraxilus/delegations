# Provenance

| Field   | Value |
|---------|-------|
| Harness | Claude Code |
| Author  | Claude |
| Date    | 2026-10-24 |
| Style   | CONSTITUTION.md and STYLE.md, followed. |
| Rules   | 01a086eda78015fd |
| Review  | **Unreviewed.** Nothing here has been read line by line by a human. |

Origin: a contributor project, from the brief of the Architect. A tag is a gismu or a lujvo that
describes a thing which somebody tags. A search finds every tagged thing by a gismu, or by an
English word that leads to one. The system uses only the compound and parsable nature of lojban.

The authority is The Complete Lojban Language (CLL), by John Woldemar Cowan, first edition, 1997,
from the Logical Language Group. The text used is the edition at `lojban.github.io/cll`, which is
the first edition with errata. Chapter 3 gives the consonant clusters, and chapter 4 gives the
shapes of words and the algorithm that makes a lujvo. Chapters 5, 7, 9, 12 and 15 tell which words
the cmavo SE, NAhE, NA, NU, `ke`, `ke'e`, `bo`, `kei` and `co` bind. The suites carry the names of
those chapters, and each assertion cites its section or example.

The Architect ruled that the project writes the name of the language in lowercase, as lojban.
In lojban, a capital letter marks irregular stress (CLL 3.9), and the name has none. A title
keeps its capital, as The Complete Lojban Language does. So do the word lists, the notice of the
group, and a name in code such as `Notation.Lojban`, whose case Article V sets. Verified by
`suites/test_suggestions.nim`, for each line of the report and of the system text.

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
writes `src/lojban_tagger/lists/gismu.nim` and `lujvo.nim`. Each is a module of typed constants,
and its header names that verb, as the rule of data asks (CONTRIBUTOR.md, Data). The compiler
checks each field against the types of `entries.nim`.

**A field that every line holds takes `{.requiresInit.}`, so an entry that lacks one does not
compile.** The marked fields are the word, keyword and definition of a gismu, and the word,
notation, parts and gloss of a lujvo. The rafsi and the hint are empty by right, so they stay
unmarked. The zero value of the notation is `Lojban`, so an entry with no notation would claim
the notation of lojban for an English line. Verified by `suites/test_lists.nim`, which holds that
an entry without each marked field does not compile.

Cost: `mapIt` declares `var it`, so it does not compile over an entry, and the suites read fields
by `collect` or a loop. Each seq of entries gives the warnings `UnsafeSetLen` and `UnsafeDefault`
of Nim 2.2.12 and 2.4.0. `newSeq` of entries also gives `ProveInit`, which Nim says will become an
error, so the suites use `newSeqOfCap`. Verified by hand with `nim check` of the stub on
2026-11-03, and with a probe of `mapIt` and `newSeq` on both compilers on 2026-11-04.

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
the parts in lojban, after a colon. Other lines name them by English keywords of gismu, after
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

**A tag folds into tanru units, and each tanru unit is one word with the cmavo that bind it.** The
grammar of CLL gives that name (21.2, rule 152), and the Architect ruled that the project uses it
(#768). SE binds the next brivla or "equivalent unit" (9.4), and NAhE binds close to its brivla
(15.4). A NU rafsi modifies the next tanru unit alone (12.12). Every other cmavo binds nothing, and
stands as a tanru unit of its own where it does not only group. Verified by
`suites/test_tanru_units.nim`.

**`na` binds the whole tag.** 15.2 says that negation with `na` applies to an entire bridi, and
not to just part of a selbri. So an odd count of `na`, wherever it stands, folds as one `na` before
a group of the whole tag. An even count folds as none, because adjacent negations cancel out
(15.2). Verified by `suites/test_tanru_units.nim`.

**A run of SE that binds one tanru unit composes into one conversion.** The inner conversion applies
first (9.4), so `te se ciska` puts the third place of `ciska` first. Two `se` cancel (12.11), so
`se se ciska` folds to `ciska`. Other cmavo keep their order against the conversions. Verified by
`suites/test_tanru_units.nim`, over every chain of up to four SE, and by `se na'e se ciska`.

**A group of one tanru unit is that tanru unit.** `ke` opens a group, and `ke'e` or the end of the
tag closes it (5.5). A cmavo before `ke` binds the whole group, as in `selkemdzukla` (12.11). So
`se ke ciska` folds to `se ciska`, and `selkemci'avei` holds no tanru unit `se ciska`. Verified by
`suites/test_tanru_units.nim`, over every chain of up to two of `se`, `te`, `na'e` and `nu`.

**A cmavo that only groups drops.** The rank reads no grouping that no cmavo binds. So the `ke` and
`ke'e` of a group that no cmavo binds drop, and `kemdatnyvei` folds as `datnyvei`. A group whose
cmavo cancel binds nothing, so it drops too. `bo` only groups (5.3), and drops. Verified by
`suites/test_tanru_units.nim`.

**`kei` closes an abstraction.** Rule 152 of 21.2 ends a NU with `kei`. So the fold reads `kei` as
a `ke'e` that closes a `ke` after its NU, and `nu citka gasnu kei klama` abstracts two tanru
units. After one tanru unit, the group holds only that tanru unit, as 12.13 says of
`nunctikezgau`. A `kei` with no NU before it drops. Verified by `suites/test_tanru_units.nim`.

**No group holds `co`.** 5.8 puts a `ke'e` before `co` for each group that is open there. Cost:
`co` inverts the order of a tanru (5.8), but the fold keeps the written order. So the rank does not
see a run across `co`. Verified by `suites/test_tanru_units.nim`.

**A lujvo leaves `ke` out in two places that CLL names.** Two SE in a row read as SE `ke` SE
(12.11). So the first one converts the rest of the tag, up to a `ke'e` that closes it. A `ke'e`
that closes nothing implies a `ke` after the nearest run of binding cmavo with two tanru units or
more after it (15.4). With no such run, the `ke'e` only groups, and it drops. Verified by
`suites/test_tanru_units.nim`.

Cost: the fold reads every tag as a lujvo, so a tag read from tanru text follows 12.11 too. Cost: in
a run of `na'e se` before such a group, both cmavo bind the group, where 15.4 names the negation
alone.

**CLL spells one example with a rafsi that the list gives to another gismu.** 15.4 writes
`na'e ke sutra cadzu ke'e klama` as `nalsu'adzuke'ekla`. The list gives `su'a` to `stura`, and
gives `sutra` only `sut`, so the reader reads that example as `stura`. The suite holds the shape of
the example, which the choice of gismu does not change. Verified by `suites/test_tanru_units.nim`,
Section 15.4.

13.13 makes a lujvo with `pev` figurative as a whole, and 5.13 gives a tense the whole bridi. The
fold binds nothing to them. Cost: `pevyselci'a` ranks for `selci'a`, although `pe'a` makes it
figurative. Verified by `suites/test_tanru_units.nim` and `suites/test_search.nim`.

Rule 152 of 21.2 makes a number and its MOI one tanru unit. The fold keeps each digit as a tanru
unit of its own. Cost: the term `pavmomci'a` ranks the tag `relpavmomci'a`, whose number is 21,
not 1. Verified by hand with `tagger find` on 2026-10-25. That such tags are rare is assumed.

JAI binds as SE does (5.11), but the list gives `jai` no rafsi, so no tag holds it. CLL 12.12 gives
`jai` the rafsi `jax`, which the list does not hold. A static check in `tanru_units.nim` fails the
build where the list gains `jai`.

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

The rule of data gives Protocol Buffers to data that one program writes and another reads
(CONTRIBUTOR.md, Data). Only `tagger` writes and reads the index. So the Architect ruled that it
stays text, which a person reads and any tool splits at the tab (D1 on #768). Rejected: Protocol
Buffers, whose binary a person cannot read or edit.

**A term becomes sets of gismu, and an entity meets the term where it holds one set whole.** A
lojban term gives one set, the gismu of its tanru. An English term gives one set for each meaning
that it leads to. So `vreji` finds a thing tagged `datnyvei`, and `datnyvei` finds what `datni`
and `vreji` tag together.

Cost: order and relation are lost, so the tanru `patfu mamta` and the lujvo `mampa'u` find each
other. Verified by `suites/test_search.nim`.

**A query shows each entity that one of its terms finds, and the entities that meet the most
terms come first.** The Architect ruled so (D5 c on #779). The entities that meet every term come
first, then the entities that meet one term fewer, and so on down to one term. So a term that
finds nothing does not empty the result. Over the tags of Alice's Adventures in Wonderland,
`rabbit hole` and `cheshire cat` find the book, though `hole` and `cheshire` find nothing.

The entities that meet every term are what the conjunction of the terms finds, in the same order.
Verified by `suites/test_search.nim`, against an oracle of the conjunction that shares no code
with `find`. Verified by `suites/test_commands.nim` for the book.

Each term counts once for each time that the query names it. Verified by `suites/test_search.nim`.
Cost: every term counts the same, so an entity that meets two wide terms comes before an entity
that meets one narrow term. Cost: the search tests every entity against every term, with no stop
at the first term that it fails (Figures).

The report names each term that finds nothing in the index, because the output does not show it.
In a query of several terms, the report of a term with a cmavo says where its rank applies. The
output line of an entity does not say how many terms it meets, so its form stays the same for
other tools. Verified by `suites/test_commands.nim`.

**A lojban term that holds a cmavo ranks first each entity with a tag that holds its tanru units
unbroken.** The Architect ruled that a search for `selci'a` lists first each thing with a tag that
holds `se` right before `ciska`, wherever the pair stands. The net result of the cmavo around the
pair decides, and a longer term ranks by an unbroken run too. A search for `ciska` gives no
priority. So the search finds what the gismu find. Then it puts first each entity with a tag whose
tanru units hold those of the term in order, with nothing between them.

So `selci'a`, `selci'avei` and `veirselci'a` rank for `selci'a`. `selselci'a`, `terselci'a` and
`nalselci'a` do not, because their cmavo convert or negate `se ciska`. A term whose cmavo all fold
away ranks nothing, as a gismu does. The rank orders the entities that meet the same number of
terms. Each of its two tiers keeps the order of the index. Verified by `suites/test_search.nim`.

A group that cmavo bind changes a run inside it in three ways, and then the run does not rank. A
run that ends where the group ends holds its head, which a conversion converts (5.11) and an
abstraction turns to an event (12.12). A negation denies every part of the group (15.4). A group
that the run leaves open must end where the run ends. Verified by `suites/test_tanru_units.nim` and
`suites/test_search.nim`.

So the term `selci'avei` does not rank `selselci'avei`, which 12.11 reads as the converse of
`selci'avei`. The term `selci'a` does not rank `selkemveiselci'a` or `nalkemselci'avei`. A modifier
inside a converted group keeps its places, so the term `selci'a` ranks `selselci'avei`.

The test is a run of tanru units, and not a part of the grouped tanru, because a lujvo often
leaves its grouping out. Lujvo makers often leave `ke` out (4.10, 12.11), so the rafsi hold only
the run. Cost: the term `selci'avei` ranks a tag of `vreta se ciska vreji`, where `vreta` groups
with `se ciska` first (5.3). Verified by `suites/test_search.nim`.

**An English term ranks nothing, because the ruling on the rank names a term typed in lojban.**
The Architect ruled so (#768), since an English word can lead to several meanings. So `writing`
leads to several meanings, among them a writing desk and a joke, and only the joke,
`xajmi+se+finti`, holds a cmavo. A rank by that meaning would put jokes first, which the user may
not mean. Rejected: a rank by each meaning that holds a cmavo. Verified by
`suites/test_search.nim`.

## Suggestion

**The tool suggests each gismu that a search might use.** One tag for each text, such as
`selmacygu'e` for Alice's Adventures in Wonderland, finds that text by one tanru alone. So the
Architect ruled that the tool suggests each tag that a person might use to find a work, or other
content, in a database. That person may not remember its title or its names, and a word of form,
such as book, counts. Verified by `suites/test_suggestions.nim`, which holds the prompt.

**The model decides how many gismu a text needs, up to 32.** The Architect chose this over a hard
cap of ten tags, and over a threshold in an embedding space. The prompt states 32 as a cap and not
as a target, and asks for the most likely search first. The tool reads the first 32 elements of
an answer, and the report counts the rest, which the tool never reads. A user who wants fewer tags
cuts the ordered output, for example with `head -n 10`. Verified by `suites/test_suggestions.nim`,
which holds the prompt, and reads each count of elements from 0 to 64.

**A suggested tag is one gismu, because the search matches gismu across tags.** The Architect
ruled that the tool suggests gismu alone, while `tagger` still reads lujvo in tags and in search.
An entity meets a term where each gismu of one meaning of the term stands in any of its tags
(`search.nim`). So gismu tags, each apart, meet an English word whose meaning holds several gismu.
The prompt asks for each gismu of such an idea, and the reader drops each lujvo and each cmavo.

Verified by hand with `binaries/tagger find` on 2026-10-31, over one thing with the tags `cukta`,
`nixli`, `ractu`, `kevna`, `nobli`, `traji`, `turni` and `mlatu`. The terms `book`, `girl`, `cat`
and `rabbit` find it. So do `queen` and `king`, through the meanings `nobli+traji+turni` and
`nobli+traji`. Open questions names the terms that find nothing.

**The schema asks for a list of tags, each a gismu with its gloss.** A pattern of five letters,
built from the letters of `tags.nim`, holds each gismu. The schema has no `maxItems`, because
structured outputs of Claude refuse an array constraint past `minItems` of 0 or 1 with status 400.
The same page lists a simple pattern with a quantifier, such as `{5}`, as supported. Verified by
reading `https://platform.claude.com/docs/en/build-with-claude/structured-outputs`, JSON Schema
limitations, on 2026-10-31.

Cost: a model that reaches for a lujvo or a cmavo must give five letters. So it may give an
unlisted word, which the reader drops, or a listed gismu of another sense, which the reader keeps.
How often either occurs is unmeasured.

Each object of the schema is closed, because Claude and the strict mode of OpenAI both need it.
Each property is required, because the strict mode of OpenAI needs it, and `openrouter` and `chat`
ask for that mode. Claude itself allows optional properties. Verified by reading the page above and
`https://developers.openai.com/api/docs/guides/structured-outputs` on 2026-10-31. One schema
serves all three services, which `suites/test_suggestions.nim` holds.

**An element of the answer that is no gismu of the list drops alone.** The report names the
element by its position and by its reason, and the tool keeps the rest of the answer. A word that
the reader refuses keeps the reason of the reader. A cmavo, a lujvo and an element that is no
object of the schema drop with a reason of their own. A gismu that an earlier element kept drops
as `Duplicate`, so each gismu prints once.

Rejected: a refusal of the whole answer. The tool makes no retry, and the key is for sparing use,
so one bad element would then waste a paid answer. A reply that fails as a whole still fails as
one. Its status, a refusal, a cut, or an answer with no elements can each cause that. Verified by
`suites/test_suggestions.nim`, over each kind of dropped element at each position among kept
gismu, and over every sequence of up to three dropped elements.

**The output holds one gismu to a line, in the order of the answer.** The README passes the
output to `tagger tag` with no quotes, so the shell splits the lines into words. A gismu has five
letters, so no space and no glob character can enter. The report goes to standard error. It
names each refusal, then the count of elements that the tool did not read, then each gismu with its
gloss. Each string that the model controls is made printable before it reaches the report.

Where the tool keeps a gismu, the report names the model once, and the model asked where the two
differ. The tool exits 0 where it keeps a gismu, and 1 where it keeps none. Verified by
`suites/test_suggester.nim`, which builds the binary and drives it.

**The system text holds the gismu list, and it is the same bytes on every request.** It gives
each gismu of the list, with its keyword and its hint, so the model sees what the reader accepts.
It holds no cmavo, because no tag may be one. `claude` and `openrouter` mark the text for the
cache, and `chat` caches nothing. Rejected: the definitions too, at five times the size. Verified
by `suites/test_suggestions.nim`.

Cost: the text goes with each request, and the cache helps only within its lifetime. It is 23,699
bytes, against 24,918 bytes for the list with cmavo at `bf9c82d8`, by one command on 2026-10-31:
`nim r --hints:off --path:src --eval:'import lojban_tagger/suggestions; echo PROMPT_SYSTEM.len'`.

**The passage is data inside one element.** Its `&`, `<`, `>` and `"` are escaped, so it can
never close the element. The URL in the element keeps its scheme, host, port and path, so no user
part, query or fragment reaches the service or the report. Cost: a token that a URL holds in its
path, as a share link does, reaches the service and the report. Cost: the page request itself
sends the whole URL to the page host, and to any http proxy. Verified by
`suites/test_suggestions.nim`.

**A text of at most 64 bytes that reads as a tag asks no service.** The tool prints the gismu of
that tag, each once and in order, leaves out its cmavo, and reads no key. A longer text goes to
the service as a passage. A tag of more than six words fails as `Long`. Verified by
`suites/test_suggestions.nim` and `suites/test_suggester.nim`.

Cost: the tool counts the words after `readTag`, so the cap of six words saves none of the time
of the reading. It saves only the time to list and print the gismu and the report, about 1 µs on
Nim 2.2.12 (Figures). Open questions asks about it.

Cost: `tagger read` and `tagger tag` have no cap of words. `$` scores every choice of rafsi, so
its time grows about 4 times for each word of `bloti`, `condi` or `rotsu` (Figures). So a lujvo of
18 words fills memory there.

**The tool speaks the wire format of each of three services.**

- `claude` speaks the Messages API of Anthropic.
- `openrouter` speaks Chat Completions with the routing and cache fields of OpenRouter.
- `chat` speaks Chat Completions with standard fields alone, for any compatible server. Its
  body is a project choice, because no OpenAI reference of Chat Completions was read.

The settings come from the environment on each run, as the index path does for `tagger`.
Verified by `suites/test_suggestions.nim`, against documented shapes alone.

**JSON appears only on the wire of each service, which forces it.** An exchange file holds those
bytes unchanged. The rule of data keeps JSON on the wire of an outside service that speaks it alone
(CONTRIBUTOR.md, Data). No exported routine takes or returns a `JsonNode`, so the compiler checks
each field past `suggestions.nim`, which reads each reply. Verified by hand with `grep` over the
source of the project, 2026-11-04.

**`claude` asks for a fallback model on refusal.** The body sends `fallbacks: "default"` and its
beta for each model but `claude-haiku-5-5`. The documentation says that a model with no fallback
runs alone, and that `claude-haiku-5-5` takes none. Cost: a refusal in a billed category is
billed beside the fallback request. Verified by `suites/test_suggestions.nim`, whose table cites
the page for each row.

**`openrouter` names one session, and `claude` can name a workspace.** A fixed `session_id` keeps
the cached system text on one endpoint of OpenRouter, where the passage alone would route each
request apart. Its documentation says so, and no run measured a hit of the cache. A Claude key
that no workspace scopes needs `anthropic-workspace-id`, which `LOJBAN_TAGGER_WORKSPACE` gives.
The workspace goes in a header, never in the body, so the exchange replays under any
workspace. Verified by `suites/test_suggestions.nim` and `suites/test_suggester.nim`.

**There is no retry.** The key is for sparing use. So a reply that fails as a whole goes to the
user, who may run again, and a bad element of the answer drops alone. The report names every cut
and every repair of the text, and the passage element tells the model of each cut. Cost: a
failure that passes, such as an overload, still needs a second run. Verified by
`suites/test_suggestions.nim`.

**The tool reads pages with its own reader, in one pass.** Script, style, iframe and noscript are
raw text to their own end tag, and a comment ends as the HTML tokenizer ends it. The reader
refuses a page with no visible character, so the tool never sends it. Cost: only 23 named
references are decoded, so `&eacute;` stays as written. Rejected: `std/htmlparser`, which Nim
2.2 deprecates, and which recurses and keeps script text. Verified by
`suites/test_suggestions.nim`.

**The encoding comes from the bytes before any label.** A byte order mark wins over each label,
and a page whose mark or header names UTF-16 is refused. Otherwise the header names the label,
or a meta element does, as steps 1, 3 and 4 of the prescan of HTML 13.2.3.2 read it. Cost: the
prescan reads no UTF-16 declaration and no XML encoding, so a UTF-16 page with no mark or header
reads as UTF-8. Cost: a meta value that names no encoding is taken, where HTML reads on to the
next meta. Verified by `suites/test_suggestions.nim`.

**The tool decodes two groups of labels.** It decodes the UTF-8 group and the windows-1252 group,
as the WHATWG Encoding Standard names them. A page cut at its cap drops the character that the
cut split, and never counts it as ill-formed. Verified by `suites/test_suggestions.nim`.

## Transport

**Each request gets a new client that follows no redirect.** A client loop keeps its headers
across hosts, so the key could reach another host. `suggester` follows each page redirect
itself:

- at most five times, with the proxy chosen again for each hop;
- never in a loop, and never from https to http.

Cost: each hop makes a new connection and a new TLS handshake. Cost: a page can redirect to a
loopback or private address, whose text then goes to the service. Verified by
`suites/test_exchanges.nim` and `suites/test_suggester.nim`.

**TLS checks the chain and the name of the host.** The context checks the chain against the roots
of the machine, or the roots that `SSL_CERT_FILE` names. `send` pins the host of the URL on the
context before each request, so the handshake refuses a leaf that names another host. Through a
proxy, the tunnel to the host carries the same pin. Cost: sends that share a context run one at a
time, as `suggester` runs them. Verified by `suites/test_exchanges.nim`, against a test root that
`openssl` makes for each run.

The async client of Nim 2.4.0 checks the name too, after the handshake. It reads the common name
of the subject even where the leaf holds DNS names, which RFC 6125 section 6.4.4 forbids. So it
takes a leaf whose common name alone names the host, and the pin refuses that leaf. Verified by
hand with Nim 2.4.0, 2026-11-04, for `localhost` and a leaf that names `wrong.example` by DNS. Its
common name is `localhost`, so the client alone takes it, and the pin refuses it.

**An https host loses one closing dot before the client dials it.** A certificate names a host
without the dot that closes an absolute name, and curl pins the name without it too. The async
client of Nim 2.4.0 checks the certificate against the host that it dials, after the handshake.
So `pinHost` and `send` both drop one closing dot from the name. Of two closing dots, one stays,
and no leaf names that host. Verified by `suites/test_exchanges.nim`, over each name that closes
with one dot or two through a tunnel, and over `localhost.` directly, with each leaf.

An address that closes with a dot, as `127.0.0.1.` does, is refused before any connection. The
client would dial the address, while the pin would hold a name. Verified by
`suites/test_exchanges.nim`, over each leaf, directly and through a tunnel.

Cost: the lookup, the tunnel and `Host` take the absolute name without its dot, so the name is
relative. The hosts file matches it, and DNS tries the search list first where the name holds
fewer dots than `ndots`. Through a proxy, the resolver of the proxy reads the name so. So `send`
can reach a host that curl does not reach, because curl resolves the name with its dot. The pin
still refuses each leaf that names another host. Rejected: a dial with the dot and a check
without it, as the client gives one host to the lookup, the tunnel and the check.

Verified by hand with Nim 2.4.0 and curl 8.5.0, 2026-11-04, with a trace of each DNS query. For
`https://intranet./` and the search list `corp.example.test`, `send` asks for
`intranet.corp.example.test` first, and curl asks for `intranet.` alone. A URL of `localhost.`
reaches loopback with a `Host` of `localhost` and the port, and curl cannot resolve `localhost.`.
Through a tunnel, curl takes a leaf that names `localhost` for `localhost.`, and its tunnel and
`Host` keep the dot.

**The key goes as Bearer to the endpoint alone.** It is a distinct type whose `$` stops the
compile, so no report or exchange file can hold it. `suggester` passes it with the service request
alone, never with a page request. The documentation of Anthropic gives `Authorization: Bearer`
first, and calls `x-api-key` legacy. An endpoint must be https, or http to a loopback host, and
`ANTHROPIC_BASE_URL` is never read. Verified by `suites/test_exchanges.nim` and
`suites/test_suggester.nim`.

**The deadline is a future, and the body has a cap.** The caller passes the deadline, so the
suites complete it and read no clock. The body is read from the stream up to its cap: 4 MiB for
a page, and 1 MiB for a reply. Cost: the head of a reply has no cap in bytes. Cost: a request
with no streaming waits while the model thinks, so a dropped connection loses a paid answer.
Verified by `suites/test_exchanges.nim` and `suites/test_suggester.nim`.

**The proxy follows the rules of curl.** An https URL takes `https_proxy`, then `HTTPS_PROXY`,
and an http URL takes `http_proxy` alone. A loopback host goes direct, and so does a host that
`no_proxy` or `NO_PROXY` names. A value with no scheme takes `http://`, and a value whose host
names no port takes 1080, as curl assumes. Cost: a bypass entry for a range of addresses never
matches. Verified by `suites/test_exchanges.nim`.

The choice reads the host without one closing dot, as the pin and the dial read it. So
`localhost.` goes direct, and the bypass entry `example.org` names `api.example.org.`, as curl
reads it. Verified by `suites/test_exchanges.nim`.

**A proxy must be `http://`, and for an https URL it must hold no user part.** The client of
`std/httpclient` speaks TLS to no proxy that this tool can pin. It also repeats
`Proxy-Authorization` on the request inside the tunnel, so a proxy login would reach the service
and each https page. A proxy whose user part runs past `/`, `?` or `#` is refused, since its
password would read as host or port. Cost: a proxy that needs a login cannot reach an https URL,
and a proxy of `socks5h` is refused, though the client speaks it. Verified by
`suites/test_exchanges.nim`.

**A URL is checked as RFC 3986 splits it, before the client reads it.** A scheme in capitals is
made lowercase, because the client compares the scheme with case. The authority is split as
section 3.2 splits it, and the port must be from 1 to 65535. The client joins the digits after
each colon into one port and reads a port modulo 65536, so either fault would reach another
port. A URL that holds whitespace or a control character is refused. Verified by
`suites/test_exchanges.nim`.

## Record and replay

**An exchange file is a frame, then one message of Protocol Buffers.** The rule of data gives
Protocol Buffers to data that one program writes and another reads (CONTRIBUTOR.md, Data).
`tools/examples.nim` and `suggester` write exchange files, and `suggester` reads them. The schema
is `app/exchanges.proto`, beside `app/exchanges.nim`, which owns the format. Nim writes and reads
the message only through the types that `import_proto3` of `protobuf_serialization` generates.
Verified by `suites/test_exchanges.nim`.

The generator names each type after its message, and leaves out the package. So its `Exchange`
and `Reply` would clash with `Exchange` of `exchanges.nim` and `Reply` of `suggestions.nim`. The
types live in `app/exchanges_schema.nim`, which `exchanges.nim` imports with `from
./exchanges_schema import nil`. `toMessage` and `toExchange` convert each field between the two
types.

**The reader checks the frame before any byte of the message decodes.** A decoder of Protocol
Buffers reads a message that is cut between two fields as a message with fewer fields. So the
frame holds three parts, and the reader refuses the file at the first part that fails:

1. The opening `lojban_tagger exchange 2` and a line break, which name the format and its version.
2. The length of the message, in four bytes.
3. The CRC-32C of the message, in four bytes.

Both numbers put the least significant byte first, as Protocol Buffers writes `fixed32`. The
message starts after these 33 bytes. Verified by `suites/test_exchanges.nim`, against a frame that
the suite builds apart, over each cut and each changed bit or byte.

The opening ends with a line break, so `head -n 1` prints it. A transfer that rewrites line ends
also changes the opening, so the reader refuses the file there and shows the carriage return. The
text format of version 1 opens with `lojban_tagger exchange 1`, so the reader refuses it at the
opening too. Verified by `suites/test_exchanges.nim`.

**The checksum is CRC-32C, the cyclic redundancy check of RFC 3720, section 12.1.** It detects
each run of up to 32 changed bits in the message. Its polynomial has 18 terms, so `x + 1` divides
it, and it detects each change of an odd count of bits too. The suite holds both laws over random
files, and the vectors of appendix B.4 of RFC 3720. Verified by `suites/test_exchanges.nim`.
Verified by hand with `gsutil hash -c` on 2026-11-04, for the vectors and the worked example.

Rejected: CRC-32 of IEEE 802.3, whose polynomial has 15 terms, so `x + 1` does not divide it. So
it gives no promise to detect each change of an odd count of bits. Verified by hand with Nim 2.4.0
on 2026-11-04, which counted the terms of both polynomials.

Rejected: SHA-256, which `sha256sum` checks by hand. The standard library has no SHA-256, and the
checksum carries no key, so its strength buys nothing here. Rejected: FNV-1a 64 of `stamp`, a
hash for names. It detects each change of one byte, but it makes no promise for a longer run. It
would also tie the checksum to the name of the file.

Cost: each file holds 33 bytes of frame, and a person reads it through `protoc`, past the frame.

**The message holds each field of `Exchange`.** The label is a `string`, and Protocol Buffers
holds a `string` as well-formed UTF-8 alone. `protoc` refuses a message whose `string` is
ill-formed. So `toBytes` repairs the label by Table 3-7 of the Unicode Standard, and the reader
refuses a label that this rule would repair. The decoder of `protobuf_serialization` takes a
surrogate and a code point past U+10FFFF, so the reader checks the label itself. Verified by
`suites/test_exchanges.nim`, over each kind of ill-formed label.

Verified by hand with `protoc` 3.21.12 on 2026-11-04. It refuses each of those labels, and takes
U+FFFD and U+10FFFF.

The request and each field of the reply are `bytes`, so any bytes read back. The status reads
from 0 to 999, the three digits of a status line, and `send` gives 0 to 599. No field is
`optional`, since each field defaults to zero, empty or false. No enum exists, since `is_cut`
takes two values, which a `bool` carries. Verified by `suites/test_exchanges.nim`.

A field of a newer version is unknown to an older reader, so the decoder skips it. So an older
reader reads a newer file, as the field numbers carry the versions of the format. Verified by
`suites/test_exchanges.nim`.

Cost: a label of ill-formed bytes reads back repaired. Record mode writes `recorded <date>`,
which holds ASCII alone.

**The writer agrees with `protoc` byte for byte.** `app/exchanges_example.txtpb` holds the first
hop of the worked example `page` in text format. `protoc --decode` printed it from the file that
`nim r tools/build.nim examples` writes. `test_exchanges.nim` encodes that file with `protoc
--encode` into `build/` when it compiles, and checks the exit code of `protoc`. It then reads the
bytes with `staticRead`, as STYLE.md section 4 gives.

The writer gives the same bytes, and the reader reads them back as the exchange of the example.
Verified by `suites/test_exchanges.nim`.

Cost: `nim check` runs no `gorgeEx`, which then gives an empty output and exit code 0. So a check
reads the binary that the last compile left in `build/`, and fails before any compile ran.
Verified by hand with Nim 2.4.0 on 2026-11-04, with a command that exits 3.

**A person reads an exchange file through `protoc`, past its frame.** From the folder of the
project, this command prints the first hop of the example `page`:

```sh
tail -c +34 build/examples/390a130dbd59a40f.exchange |
  protoc --decode=lojban_tagger.Exchange app/exchanges.proto
```

Verified by hand with `protoc` 3.21.12 on 2026-11-04, for each file that `examples` writes.

**Each refusal names the part that fails, and ends in the value that it refuses.** That value is
the first line of the file, a count of bytes, a checksum, an error of the decoder, a label or a
status. It is never a byte of the request or the body. The first line and the label show each URL
that they name by scheme, host, port and path alone, wherever it stands (`dropSecretsText`). So
no user part, query or fragment reaches the report.

Verified by `suites/test_exchanges.nim`, over each cut and each changed bit of page files whose
URL holds secrets. One of those files has no label, so its message opens with the request. A
changed line break of the opening then shows the URL after binary bytes. Cost: the query of a
reference with no `//`, as of `mailto:`, shows whole.

**The stamp, FNV-1a 64 of the request, names the file.** The request is the method and the URL
of a page, or the method, the endpoint and the body of a service request. FNV-1a resists no
collision, so the file holds the whole request, and a replay compares it. The headers and the key
stay out of the request. Rejected: `std/hashes`, whose values change between versions of Nim.
Verified by `suites/test_exchanges.nim` and `suites/test_suggester.nim`.

**Three modes reach each exchange, and a live run writes nothing.** `--record:<directory>`
replays a page reply of 2xx or 3xx, and a service reply that holds an answer of the model. It
sends the rest again, such as a refusal or an error in a reply of 200, and writes each reply.
Cost: a refusal in a billed category is paid again on the next record run. `--replay:<directory>`
reads every exchange from files, and needs no key and no network. Verified by
`suites/test_suggester.nim`.

**Exchange files stay private and bounded.** An exchange file holds the text and the reply, so
record mode makes its directory with mode 0700 and writes each file with mode 0600. Both modes
refuse a link at the path of an exchange file, and a directory that every user may write, where
others could put one. A file larger than its request, its cap and 65,536 bytes is refused before
it is read, and record mode writes none. Cost: members of a group that may write the directory are
trusted. Verified by `suites/test_suggester.nim`.

**The worked examples are documented shapes, not live replies.** The verb `examples` of
`tools/build.nim` writes them, and each label says so. Record mode replays them, because each
reply holds an answer, so a live reply needs a run under `--record:` into another directory.
Verified by `suites/test_suggester.nim`, which replays each one.

The examples are typed constants in `tools/examples.nim`, as the rule of data asks of data that a
person writes. The name, the argument and the tags of an example take `{.requiresInit.}`, so an
example that lacks one does not compile. The hops stay unmarked, because a text given has none.
Verified by `suites/test_suggester.nim`.

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

**`suggester` is a second binary, and not a verb of `tagger`.** `-d:ssl` loads libssl when a
program starts, so each verb of `tagger` would need it. The Architect chose the second binary in
the conversation of this delivery, and the pull request records the ruling. Each gismu goes to
standard output on a line of its own, so `tagger tag <name> $(suggester ...)` joins the two
programs. Cost: a second build and a second binary to ship. Verified by
`suites/test_suggester.nim`, which builds the binary and drives it.

**A flag that `suggester` does not know is a usage error, so it never sends a paid request.**
Before `--`, each word that starts with `-` reads as a flag, wherever it stands. Exit 2 names a
usage or settings error and sends nothing. Exit 1 names each failure where no gismu is kept, and
exit 0 prints one gismu or more.

A blank passage exits 2 before any setting is read, and so does a URL whose host or port RFC 3986
refuses. The argument `-` reads the text from standard input, up to 4 MiB, so the text stays out
of the list of processes. Verified by `suites/test_suggester.nim`.

**The key comes from the environment alone.** `LOJBAN_TAGGER_API_KEY` is read first, and where it
is unset, `claude` reads `ANTHROPIC_API_KEY` and `openrouter` reads `OPENROUTER_API_KEY`, as the
Architect ruled. Each reads that name only for the host of its default endpoint. So a key that
the user set for other tools never goes to another host. The report names the variable, and
never the value. Verified by `suites/test_suggester.nim`.

## Tests

**One stub runs every suite as one program.** `tests/test_suites.nim` imports each file of
`tests/suites/`, in the shape that STYLE.md section 6 gives. Each suite still runs alone. Suites
that CLL covers carry the names of its chapters. The others open with `Internal:`, so the run
shows where the authority stops.

The stub compiles with `-d:ssl`, because the transport suite drives TLS against a test root that
`openssl` makes for each run. The stub also needs `protoc` to compile, because the suite of
exchanges encodes the worked example with it.

## Toolchain

**The compiler is pinned exactly**: `requires "nim == 2.4.0"` in `lojban_tagger.nimble`, as every
project of the repository pins it (D1 a on #775). The verbs `lists` and `head` also need
`lojban-common` and `sha256sum`, which the verb `system` declares. `suggester` and the stub
compile with `-d:ssl`, so each needs `libssl3` when it starts. `suggester` checks hosts against
`ca-certificates`, and the transport suite runs `openssl`, which `system` declares too. The suite
of exchanges runs `protoc` of `protobuf-compiler` when it compiles, and `system` declares it.

A system package carries no pin, so its version is what the machine has. Here, OpenSSL is 3.0.13,
and `protoc` is 3.21.12.

**One package reads and writes exchange files, and Atlas pins it.** The project derives the
morphology of lojban, which it exists to understand (Article II.8). Protocol Buffers are an
external concern, and the rule of data names `protobuf_serialization`. Atlas pins it in
`atlas.lock` with the six packages that it needs, and restores them under `dependencies/`, which
git never keeps (Article XI.3). Each version below is the one that the nimble file of its package
declares:

- `protobuf_serialization` 0.6.2, at `a671c6d497c7028ed7390b2d5a80c7b62138c586` of
  `https://github.com/status-im/nim-protobuf-serialization`, under Apache-2.0 or MIT.
- `faststreams` 0.6.0, at `5bdef9939b483435a61aa91a6422c1a9852127b4` of
  `https://github.com/status-im/nim-faststreams`, under Apache-2.0 or MIT.
- `serialization` 0.5.5, at `937a65c19fc49a5f79e2ecd89094d367b6ca0e1b` of
  `https://github.com/status-im/nim-serialization`, under Apache-2.0 or MIT.
- `stew` 0.6.5, at `29c11c7264289cc4c423f0e0662effbc5fdc6f61` of
  `https://github.com/status-im/nim-stew`, under Apache-2.0 or MIT.
- `results` 0.5.1, at `df8113dda4c2d74d460a8fa98252b0b771bf1f27` of
  `https://github.com/arnetheduck/nim-results`, under Apache-2.0 or MIT.
- `unittest2` 0.3.0, at `19701632b4f287b3012a5e435a9d829b0f66c605` of
  `https://github.com/status-im/nim-unittest2`, under MIT.
- `npeg` 1.3.0, at `409f6796d0e880b3f0222c964d1da7de6e450811` of `https://github.com/zevv/npeg`,
  under MIT.

Status Research & Development GmbH holds the copyright of the first five packages. Zahary
Karadjov and Ștefan Talpalaru hold that of `unittest2`, and Ico Doornekamp holds that of `npeg`.
Each licence asks that each copy keeps its notice. The repository holds no copy, so it gives no
notice here. A binary that ships, such as `binaries/suggester`, holds compiled code of these
packages, so it must carry their notices. Verified by hand with Atlas 0.14.7 on 2026-11-04:
`atlas changed` exits 0 against the lock, and the licence of each checkout says the above.

The lock keeps each line of the nimble file as a JSON string, with its indent and its escaped
quotes. So each line of the nimble file stays within 91 characters, and its copy fits the width
of 100 columns.

Nim 2.4.0 adds a check of the host name of a certificate to `std/asyncnet`. The async client of
`std/httpclient` then checks the certificate against the host that it dials. `suggester` opens its
sockets through that client, so `send` dials an https host without its one closing dot, as
`pinHost` holds it (Transport). Verified by `suites/test_exchanges.nim`, which holds the host that
the tunnel names. Verified by hand with Nim 2.4.0, 2026-11-04: where the client dials
`localhost.`, it refuses a leaf that names `localhost`.

**`constructRafsiByForm` of `test_lujvo.nim` reads the form of each 4-letter rafsi before `add`.**
The compile-time virtual machine (VM) of the pin evaluates the element of `add` before its
destination. It also moves a local, `let` or `var`, at its last use (#786). So
`result[stem.form.get].add stem` would move `stem` first, and then read the form of an empty
string.

Rejected: the form of `stem` read inside the call of `add`, which stops the compile of the stub.
The form of an empty string is `none`, and `get` of `none` stops the compile on the pin, so that
compile holds the order. Cost: an index that gives a value for an empty string can build a wrong
table with no error (#786). Verified by hand with Nim 2.4.0, 2026-11-03: the rejected call stops
the compile of the stub at `constructRafsiByForm`, with `UnpackDefect`. Verified by hand with Nim
2.2.12 and 2.4.0, 2026-11-03: the suites pass under both, and both build the same table.

## Figures

Each figure below comes from an Intel Xeon at 2.10 GHz with four cores. The runs of each pair of
compilers alternate between Nim 2.2.12 and the pin, 2.4.0, so both share the load of the machine.

The figures of `tagger` are from 2026-11-03, at `5b6b694a`, which holds no `suggester`. The
release build of `suggester` and the suites are from 2026-11-04, at `76f9c5a7`. Each of them
names the same runs at `c1ba9c19` too, before the port of exchange files to Protocol Buffers.
The figures of search are from 2026-11-05, at `b385c5e7`, against the conjunction at `5da0aaf1`.
Each other figure names its date, and comes from Nim 2.2.12.

- **Compile of the English index.** Each part of each lujvo line is found by binary search. The
  front end of `nim check app/tagger.nim` took 4.4 s and 4.1 s on 2.4.0, against 2.1 s and 2.5 s
  on 2.2.12. A copy that maps the whole list again for each part never finishes on either
  compiler. The compile-time VM stops it at its limit of 10,000,000 iterations, so that form is a
  trap, not a slower choice.
- **Release build.** `nim c -f -d:release app/tagger.nim` took between 6.3 s and 6.7 s on 2.4.0,
  against between 4.7 s and 5.1 s on 2.2.12, over three runs each.
- **Release build of `suggester`.** `nim c -f -d:release -d:ssl app/suggester.nim` took 12.1 s
  and 12.6 s on 2.4.0, against 10.2 s and 11.5 s on 2.2.12, from an empty cache. The binary holds
  2,586,584 bytes on 2.4.0, against 2,516,680 bytes on 2.2.12. At `c1ba9c19`, the build took
  12.3 s and 10.4 s on 2.4.0, against 8.8 s and 8.5 s on 2.2.12. Its binary held 2,515,600 bytes
  on 2.4.0, against 2,445,752 bytes on 2.2.12. So the port adds 70,984 bytes on 2.4.0, and
  70,928 bytes on 2.2.12.
- **Suites.** `nim c -r -d:ssl -d:testing tests/test_suites.nim` compiled and ran every suite in
  88.7 s and 86.7 s on 2.4.0, against 86.0 s and 78.8 s on 2.2.12. Each compiler ran it twice
  from an empty cache. The suite of `suggester` builds its own binary inside that time. At
  `c1ba9c19`, the same runs took 88.3 s and 81.7 s on 2.4.0, against 75.8 s and 74.7 s on 2.2.12.
- **Text given as tag.** A probe drew 200 random lujvo for each count of words, as `poolLujvo` of
  `suites/test_suggestions.nim` draws them, with seed 0. In release over two runs on 2026-10-31,
  `readTagGiven` took 7.5 µs and 7.2 µs for six words, and 30.0 µs and 28.5 µs for 18. To list
  and print the gismu and the report took 0.73 µs and 0.74 µs for six words, and 1.84 µs twice
  for 18.
- **Render of a tag.** `$` of six words of `bloti` took 2,151 µs in release and 14,697 µs in
  debug, the best of three runs each, on 2026-10-29. Seven words took 8,241 µs and 68,105 µs.
  Each word of `bloti`, `condi` and `rotsu` has four choices of rafsi, the most that a probe of
  the list found.
- **Render of a long lujvo.** Each tag takes the first words of the reading of `TEXT_GIVEN_LONG`
  in `suites/test_suggestions.nim`, closed by `mlatu`, its last word. In release over two runs on
  2026-10-30, `$` took 0.22 s and 0.30 s for 11 words. For 12 words it took 0.64 s and 0.76 s.
- **Reading of a long word.** `readTag` of `cizy` 128 times, then `ci'a`, which make 516 letters,
  took 694 µs and 977 µs in release over two runs on 2026-10-30.
- **Dot segments of a redirect.** For a location of 128 KiB of `/a` segments, `redirect` took 2 ms
  and 3 ms in release over two runs on 2026-10-30. A walk that slices its input took 4,828 ms and
  4,501 ms on the same input.
- **Search.** A seeded probe outside the tree wrote an index of 10,000 entities, each with one to
  eight random gismu. In release, `find` of three gismu took 4.57 ms on 2.4.0 and 5.00 ms on
  2.2.12, and the conjunction took 4.27 ms and 4.36 ms. Each figure is the median of six rounds,
  and each round keeps the least of 21 calls. A `find` that gathers the gismu of an entity for
  each term took 12.10 ms and 13.06 ms.
- **Search through `tagger`.** Over 21 runs on the same index, the least time of the whole
  `tagger find` rose by at most 1.2 ms, from about 31 ms. Its median moved inside the spread of
  the runs.
- Reading is unmeasured. The tool reads and writes the whole index for each command.

## Open questions

- **Stemming.** `files` finds nothing that `file` finds. A stemmer would widen the English, at the
  cost of a rule that no standard of the project gives.
- **Gaps of the English search.** Verified by hand with `binaries/tagger find` on 2026-10-31,
  over the thing with the tags that Suggestion names. `hole` leads only to lujvo meanings, such as
  `batke+kevna`, and never to `kevna` alone, so it does not find that thing. `grin`, `fantasy`,
  `novel`, `hatter` and `Cheshire` lead to nothing, because English reads only keywords, hints and
  lujvo glosses. A query that holds such a term still shows what its other terms find (Index and
  search).
- **The cap of six words on text given.** The tool counts the words after `readTag`, so the cap
  saves about 1 µs at most on Nim 2.2.12 (Figures). It refuses a lujvo of seven words or more,
  whose gismu the tool could print. To lift it would change no other path.
- **The 4-letter rafsi `brod`.** Five gismu share it, and CLL does not say which one it names. The
  reader refuses it as ambiguous. `brodi`, `brodo` and `brodu` have no short rafsi. So a tag
  that holds one of them before its head renders with `brod`, and does not read back.
- **Live replies.** No run read a reply of 2xx from a service. The readers follow the documented
  shapes, and three replies of 401 to requests without a key, from 2026-10-28. A run under
  `--record:` into its own directory records live replies once a key exists.
- **The cost of the system text.** Its count of tokens and the hits of the cache are
  unmeasured. So is the quality of the answers at effort `low` against `medium`.
- **Fallback and the format of the answer.** It is unverified whether `fallbacks: "default"`
  keeps the format, the effort and the thinking on the fallback model.
- **Servers of plain `chat`.** No run tried a server of plain Chat Completions.
- **Title and textarea.** The reader reads their content as markup, where HTML reads it as text.
