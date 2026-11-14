# lojban_parser

This project is a parser that reads lojban words as The Complete Lojban Language (CLL) defines
them.

## Standards

This project takes its symbols from CLL, which the [root glossary](../../../GLOSSARY.md) names
under Standards.

## Language

This project gives one word a meaning that differs from its entry below. A gismu is any word of the
form CVC/CV or CCVCV, whether the gismu list holds it or not, as the Architect ruled on #823.

### Words of lojban

**gismu**:
A root word of lojban, with five letters of the form CVC/CV or CCVCV. The gismu list of the
Logical Language Group holds every one.
_Avoid_: root, root word, primitive

**cmavo**:
A structure word of lojban, such as `se` or `nu`. Some cmavo carry rafsi, as `se` carries `sel`.
_Avoid_: particle, function word

**rafsi**:
A combining form that stands for one gismu or cmavo inside a lujvo. It is a short form of three
letters, or a gismu with or without its final vowel.
_Avoid_: affix, combining form, stem

**tanru**:
An ordered sequence of words in which each word modifies the next, so the last word is the head.
_Avoid_: metaphor, phrase

**tanru unit**:
One word of a tanru with the cmavo that bind it, as the grammar of CLL names it (21.2, rule 152).
Its conversions count by their net result, so `se se ciska` is the tanru unit `ciska`.
_Avoid_: unit, operand, converted word

**lujvo**:
A compound word joined from rafsi, with the hyphens that CLL 4.11 requires. It stands for one
tanru, whichever rafsi it uses.
_Avoid_: compound, composite word

**brivla**:
A predicate word of lojban: a gismu, a lujvo or a borrowing. It ends in a vowel, and holds a
consonant pair in its first five letters.
_Avoid_: predicate, content word

**cmene**:
A name of lojban, which ends in a consonant, as CLL 4.8 defines it.
_Avoid_: cmevla, name word

**fu'ivla**:
A borrowed brivla, which is neither a gismu nor a lujvo, as CLL 4.7 defines it.
_Avoid_: borrowing, loanword

**selma'o**:
A grammatical class of cmavo, which tells where the grammar of CLL admits each cmavo of it (4.2).
_Avoid_: class, part of speech, word class
