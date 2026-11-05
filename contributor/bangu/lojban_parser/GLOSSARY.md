# lojban_parser

This project is a parser that reads lojban words as The Complete Lojban Language (CLL) defines
them.

## Standards

This project takes its symbols from CLL, which the glossary of
[lojban_tagger](../lojban_tagger/GLOSSARY.md) names under Standards. A standard that two projects
use belongs in the root glossary, so this glossary does not name it a second time.

## Language

The glossary of [lojban_tagger](../lojban_tagger/GLOSSARY.md) defines these words of lojban under
Words of lojban: gismu, cmavo, rafsi, tanru, tanru unit, lujvo and brivla. The Architect selected
each one. This project uses each word with that meaning, and does not write the definitions a
second time.

One meaning differs here. A gismu is any word of the form CVC/CV or CCVCV, whether the gismu list
holds it or not, as the Architect ruled on #823.

### Words of lojban

**cmene**:
A name of lojban, which ends in a consonant, as CLL 4.8 defines it.
_Avoid_: cmevla, name word

**fu'ivla**:
A borrowed brivla, which is neither a gismu nor a lujvo, as CLL 4.7 defines it.
_Avoid_: borrowing, loanword

**selma'o**:
A grammatical class of cmavo, which tells where the grammar of CLL admits each cmavo of it (4.2).
_Avoid_: class, part of speech, word class
