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

Rejected: FlatBuffers, which needs a committed schema, and whose buffer a person cannot read or
edit. The Architect ruled that the index stays text, which a person reads and any tool splits at
the tab (#768). The ruling on the format of data names FlatBuffers for data that one program
writes and another reads (#755). One program writes and reads this index.

**A term becomes sets of gismu, and an entity matches where it holds one set whole.** A Lojban
term gives one set, the gismu of its tanru. An English term gives one set for each meaning that it
leads to. Every term of a query must match. So `vreji` finds a thing tagged `datnyvei`, and
`datnyvei` finds what `datni` and `vreji` tag together.

Cost: order and relation are lost, so
`patfu mamta` and `mampa'u` find each other. Verified by `suites/test_search.nim`.

**A Lojban term that holds a cmavo ranks first each entity with a tag that holds its tanru units
unbroken.** The Architect ruled that a search for `selci'a` lists first each thing with a tag that
holds `se` right before `ciska`, wherever the pair stands. The net result of the cmavo around the
pair decides, and a longer term ranks by an unbroken run too. A search for `ciska` gives no
priority. So the search finds what the gismu find. Then it puts first each entity with a tag whose
tanru units hold those of the term in order, with nothing between them.

So `selci'a`, `selci'avei` and `veirselci'a` rank for `selci'a`. `selselci'a`, `terselci'a` and
`nalselci'a` do not, because their cmavo convert or negate `se ciska`. A term whose cmavo all fold
away ranks nothing, as a gismu does. Each of the two tiers keeps the order of the index. Verified
by `suites/test_search.nim`.

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

**An English term ranks nothing, because the ruling on the rank names a term typed in Lojban.**
The Architect ruled so (#768), since an English word can lead to several meanings. So `writing`
leads to several meanings, among them a writing desk and a joke, and only the joke,
`xajmi+se+finti`, holds a cmavo. A rank by that meaning would put jokes first, which the user may
not mean. Rejected: a rank by each meaning that holds a cmavo. Verified by
`suites/test_search.nim`.

## Suggestion

**A service suggests a tanru, and the tool makes the tag.** `suggestions.nim` reads each word of
the answer through `readTag`, the tanru through `readTanru`, and the form through `$`. So 4.11
and 4.12 stay in `tags.nim` and `lujvo.nim` (Article II.1). The form must read back as the same
tag, so the tool never prints a tag that `tagger tag` refuses. `brod` is the one form that fails,
as Open questions says. Verified by `suites/test_suggestions.nim`.

**The system text holds the word lists, and it is the same bytes on every request.** It gives
each word that the reader takes, with its keyword and its hint, so the model sees what the reader
accepts. `claude` and `openrouter` mark the text for the cache, and `chat` caches nothing. Cost:
24,918 bytes go with each request, and the cache helps only within its lifetime. Rejected: the
definitions too, at five times the size. Verified by `suites/test_suggestions.nim`.

**The passage is data inside one element.** Its `&`, `<`, `>` and `"` are escaped, so it can
never close the element. The URL in the element keeps its scheme, host, port and path alone. So
a user part, a query or a fragment stays on this machine. Cost: a token that a URL holds in its
path, as a share link does, reaches the service and the report. Verified by
`suites/test_suggestions.nim`.

**A text that reads as a tag asks no service, and a tag holds at most six words.** Such a text
is printed as its tag, and no key is read. `$` scores every choice of rafsi, so its time grows
about 3.2 times for each word. A tag of more words fails as `Long` before `$` runs, whether a
text or an answer holds it. Cost: `tagger read` and `tagger tag` have no such cap, so a lujvo of
13 words takes 2.5 s there. Verified by `suites/test_suggestions.nim` and
`suites/test_suggester.nim`.

**The tool speaks the wire format of each of three services.**

- `claude` speaks the Messages API of Anthropic.
- `openrouter` speaks Chat Completions with the routing and cache fields of OpenRouter.
- `chat` speaks Chat Completions with standard fields alone, for any compatible server. Its
  body is a project choice, because no page of OpenAI was read.

The settings come from the environment on each run, as the index path does for `tagger`.
Verified by `suites/test_suggestions.nim`, against documented shapes alone.

**`claude` asks for a fallback model on refusal.** The body sends `fallbacks: "default"` and its
beta for each model but `claude-haiku-5-5`. The documentation says that a model with no fallback
runs alone, and that `claude-haiku-5-5` takes none. Cost: a refusal in a billed category is
billed beside the fallback request. Verified by `suites/test_suggestions.nim`, whose table cites
the page for each row.

**`openrouter` names one session, and `claude` can name a workspace.** A fixed `session_id` keeps
the cached system text on one endpoint of OpenRouter, as its documentation says, and no hit of
the cache is measured. Without it, the passage would route each request apart. A Claude key
that no workspace scopes needs `anthropic-workspace-id`, which `LOJBAN_TAGGER_WORKSPACE` gives.
The workspace goes in a header, never in the body, so the recording replays under any
workspace. Verified by `suites/test_suggestions.nim` and `suites/test_suggester.nim`.

**There is no retry.** The key is for sparing use, so a refused answer goes to the user, who may
run again. Every cut and every repair is named to the user and to the model. Cost: a failure
that passes, such as an overload, still needs a second run.

**The tool reads pages with its own reader, in one pass.** Script, style, iframe and noscript are
raw text to their own end tag, and a comment ends as the HTML tokenizer ends it. A page with no
visible character is refused, so it is never sent. Cost: only 23 named references are decoded,
so `&eacute;` stays as written. Rejected: `std/htmlparser`, which Nim 2.2 deprecates, and which
recurses and keeps script text. Verified by `suites/test_suggestions.nim`.

**The encoding comes from the bytes before any label.** A byte order mark wins over each label,
and a page of UTF-16 is refused. Otherwise the header names the label, or a meta element does,
as the prescan of HTML 13.2.3.2 reads it. The tool decodes the UTF-8 group and the windows-1252
group of labels, as the WHATWG Encoding Standard names them. A page cut at its cap drops the
character that the cut split, and never counts it as ill-formed. Verified by
`suites/test_suggestions.nim`.

## Transport

**Each request gets a new client that follows no redirect.** A client loop keeps its headers
across hosts, so the key could reach another host. `suggester` follows a page redirect itself,
at most five times, and chooses the proxy again for each hop. A redirect from https to http is
refused, and so is a loop. Cost: each hop makes a new connection and a new TLS handshake.
Verified by `suites/test_exchanges.nim` and `suites/test_suggester.nim`.

**TLS checks the chain and the name of the host.** The context checks the chain against the roots
of the machine, or the roots that `SSL_CERT_FILE` names. The async client of Nim checks no name,
so `send` pins the host of the URL on the context before each request. Through a proxy, the
tunnel to the host carries the same pin. Cost: sends that share a context run one at a time, as
`suggester` runs them. Verified by `suites/test_exchanges.nim`, against a test root that
`openssl` makes for each run.

**The key goes as Bearer to the endpoint alone.** It is a distinct type whose `$` stops the
compile, so no report or recording can hold it. `send` writes it into the service request alone,
never into a page request. The documentation of Anthropic gives `Authorization: Bearer` first,
and calls `x-api-key` legacy. An endpoint must be https, or http to a loopback host, and
`ANTHROPIC_BASE_URL` is never read. Verified by `suites/test_exchanges.nim`.

**The deadline is a future, and the body has a cap.** The caller passes the deadline, so the
suites complete it and read no clock. The body is read from the stream up to its cap: 4 MiB for
a page, and 1 MiB for a reply. Cost: the head of a reply has no cap in bytes. Cost: a request
with no streaming waits while the model thinks, so a dropped connection loses a paid answer.
Verified by `suites/test_exchanges.nim`.

**The proxy follows the rules of curl.** An https URL takes `https_proxy`, then `HTTPS_PROXY`,
and an http URL takes `http_proxy` alone. A loopback host goes direct, and so does a host that
`no_proxy` names. A value with no scheme takes `http://`, and a value with no port takes 1080,
as curl assumes. Cost: a bypass entry for a range of addresses never matches. Verified by
`suites/test_exchanges.nim`.

**A proxy must be `http://`, and for an https URL it must hold no user part.** The client of
`std/httpclient` speaks TLS to no proxy that this tool can pin. It also repeats
`Proxy-Authorization` on the request inside the tunnel, so a proxy login would reach the service
and each https page. Cost: a proxy that needs a login cannot reach an https URL, and a proxy of
`socks5h` is refused, though the client speaks it. Verified by `suites/test_exchanges.nim`.

**A URL is checked as RFC 3986 splits it, before the client reads it.** A scheme in capitals is
made lowercase, because the client compares the scheme with case. The authority is split as
section 3.2 splits it, and the port must be from 1 to 65535. The client joins the digits after
each colon into one port and reads a port modulo 65536, so either fault would reach another
port. A URL that holds whitespace or a control character is refused. Verified by
`suites/test_exchanges.nim`.

## Recordings

**A recording is text of its own format, as the index is.** It holds a label, the request, and
the reply. The request and the body carry byte counts, so any bytes read back. Each refusal
names the faulty line and ends in what that line holds. The format waits on the ruling of #761
about Protocol Buffers. Verified by `suites/test_exchanges.nim`.

**The stamp, FNV-1a 64 of the request, names the file.** The request is the method and the URL
of a page, or the method, the endpoint and the body of a service request. FNV-1a resists no
collision, so the file holds the whole request, and a replay compares it. The headers and the key
stay out of the request. Rejected: `std/hashes`, whose values change between versions of Nim.
Verified by `suites/test_exchanges.nim` and `suites/test_suggester.nim`.

**Three modes reach each exchange.** A live run sends each exchange and writes nothing.
`--record:<directory>` replays a page reply of 2xx or 3xx, and a service reply that reads as an
answer. It sends the rest again, such as an error that the service reports in a reply of 200,
and writes each reply. `--replay:<directory>` reads every exchange from files, and needs no key
and no network. Verified by `suites/test_suggester.nim`.

**Recordings stay private and bounded.** A recording holds the text and the reply, so record
mode makes its directory with mode 0700 and writes each file with mode 0600. Both modes refuse a
directory that every user may write, because another user could put a link there. A file larger
than its request, its cap and 65,536 bytes is refused before it is read. Cost: members of a group
that may write the directory are trusted. Verified by `suites/test_suggester.nim`.

**The worked examples are documented shapes, not live replies.** The verb `examples` of
`tools/build.nim` writes them, and each label says so. A reply that a live run records replaces
them once a key exists. Verified by `suites/test_suggester.nim`, which replays each one.

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

**The suggestion is a second binary, `suggester`, and not a verb.** `-d:ssl` loads libssl when a
program starts, so each verb of `tagger` would need it. The Architect chose the second binary in
the conversation of this delivery, and the pull request records the ruling. The tag goes to
standard output alone, so `tagger tag <name> "$(suggester ...)"` joins the two programs. Cost: a
second build and a second binary to ship. Verified by `suites/test_suggester.nim`, which builds
the binary and drives it.

**A flag that `suggester` does not know is a usage error, so it never sends a paid request.** Exit
2 names a usage or settings error, and nothing goes out. Exit 1 names a failure, and exit 0
prints a tag. A text with no visible character, and a URL whose port is outside 1 to 65535, exit
2 before any setting is read. The argument `-` reads the text from standard input, up to 4 MiB,
so the text stays out of the list of processes. Verified by `suites/test_suggester.nim`.

**The key comes from the environment alone.** `LOJBAN_TAGGER_API_KEY` is read first, and where it
is unset, `claude` reads `ANTHROPIC_API_KEY` and `openrouter` reads `OPENROUTER_API_KEY`, as the
Architect ruled. Each reads that name only for the host of its default endpoint. So a key that
the user set for other tools never goes to another host. The report names the variable, and
never the value. Verified by `suites/test_suggester.nim`.

## Tests

**One stub runs every suite as one program.** `tests/test_suites.nim` imports each file of
`tests/suites/`, in the shape that STYLE.md section 6 gives. Each suite still runs alone. Suites
that CLL covers carry the names of its chapters. The others open with `Internal:`, so the run
shows where the authority stops. The stub compiles with `-d:ssl`, because the transport suite
drives TLS against a test root that `openssl` makes for each run.

## Toolchain

**The compiler is pinned exactly**: `requires "nim == 2.2.12"` in `lojban_tagger.nimble`. The
project needs the standard library alone, so it carries no lock. The verbs `lists` and `head` also
need `lojban-common` and `sha256sum`, which the verb `system` declares. `suggester` and the stub
compile with `-d:ssl`, so each needs `libssl3` when it starts. `suggester` checks hosts against
`ca-certificates`, and the transport suite runs `openssl`, which `system` declares too. A system
package carries no pin, so its version is what the machine has, as OpenSSL 3.0.13 is here.

## Figures

Each figure below comes from an Intel Xeon at 2.10 GHz with four cores, and Nim 2.2.12. The
figures of `tagger` are from 2026-10-25, and those of `suggester` are from 2026-10-29.

- **Compile of the English index.** Each part of each lujvo line is found by binary search. The
  front end of `nim check app/tagger.nim` took 2.4 s and 2.9 s over two runs. A copy that maps
  the whole list again for each part never finishes. The compile-time VM stops it at its limit of
  10,000,000 iterations, so that form is a trap, not a slower choice.
- **Release build.** `nim c -f -d:release app/tagger.nim` took between 5.6 s and 6.5 s over three
  runs.
- **Release build of `suggester`.** `nim c -f -d:release -d:ssl app/suggester.nim` took 9.2 s
  and 9.4 s over two runs, and the binary holds 2,451,936 bytes.
- **Suites.** `nim c -r -d:ssl -d:testing tests/test_suites.nim` compiled and ran every suite in
  62.2 s and 63.4 s, over two runs from an empty cache. The suite of `suggester` builds its own
  binary inside that time.
- **Render of a tag.** `$` of six words of `bloti` took 2,151 µs in release and 14,697 µs in
  debug, the best of three runs each. Seven words took 8,241 µs and 68,105 µs. Each word of
  `bloti`, `condi` and `rotsu` has four choices of rafsi, the most that a probe of the list found.
- **Render of a long lujvo.** A probe of the review timed `$` in release at 0.79 s for 12 words
  and 2.47 s for 13 words, in one run each.
- **Reading of a long word.** `readTag` of a text of 516 letters took 0.9 ms in release, in one
  run.
- Search and reading are unmeasured. The tool reads and writes the whole index for each command.

## Open questions

- **Stemming.** `files` finds nothing that `file` finds. A stemmer would widen the English, at the
  cost of a rule that no standard of the project gives.
- **The 4-letter rafsi `brod`.** Five gismu share it, and CLL does not say which one it names. The
  reader refuses it as ambiguous. `brodi`, `brodo` and `brodu` have no short rafsi. So a tag
  that holds one of them before its head renders with `brod`, and does not read back.
- **Live replies.** No reply of 2xx from a service has been read. The readers follow the
  documented shapes, and three replies of 401 to requests without a key, from 2026-10-28. A run
  under `--record:` replaces the worked examples once a key exists.
- **The cost of the system text.** Its count of tokens and the hits of the cache are
  unmeasured. So is the quality of the answers at effort `low` against `medium`.
- **Fallback and the format of the answer.** It is unverified whether `fallbacks: "default"`
  keeps the format, the effort and the thinking on the fallback model.
- **Servers of plain `chat`.** No server of plain Chat Completions has been tried.
- **Title and textarea.** The reader reads their content as markup, where HTML reads it as text.
