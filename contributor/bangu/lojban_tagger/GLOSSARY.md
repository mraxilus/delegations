# lojban_tagger

A tagging and search system whose tags are lojban words. A parser reads each tag, and reduces it
to the words of its tanru. The Architect selected each term below before it was written.

## Standards

This project takes its symbols from The Complete Lojban Language, which the
[root glossary](../../../GLOSSARY.md) names under Standards.

## Language

The glossary of [lojban_parser](../lojban_parser/GLOSSARY.md) defines these words of lojban under
Words of lojban: gismu, cmavo, rafsi, tanru, tanru unit, lujvo and brivla. The Architect selected
each one. This project uses each word with that meaning, and does not write the definitions a
second time.

### Tagger

**Tag**:
The words of one tanru that an entity carries, read from a gismu or a lujvo. Its last word is a
gismu.
_Avoid_: label, keyword, tag word

**Entity**:
One thing that carries tags, named by any text, such as a path, a URL or a title.
_Avoid_: item, object, document, file

**Term**:
One word of a query: a gismu, a lujvo or an English word.
_Avoid_: keyword, query word, search word

**Meaning**:
The words of one tanru that an English word leads to. A keyword of the gismu list, or a gloss
of the lujvo list, leads the word there.
_Avoid_: sense, translation, definition

### Suggester

**Suggestion**:
One gismu that a service proposes as a tag for a passage, which the tool keeps after it checks the
gismu against the lists.
_Avoid_: proposal, recommendation, prediction

**Passage**:
The text that a suggestion describes. It is the text that the user gives, or the text of the page
at a URL, repaired and cut to a fixed size.
_Avoid_: source, input, document

**Service**:
A language model service, which the tool names by the wire format that it answers. Its endpoint
does not change which service it is.
_Avoid_: provider, backend, vendor

**Exchange**:
One request to a service or a page, and its reply. The tool can write it to a file without the key,
so that a later run replays it.
_Avoid_: recording, cassette, transcript
