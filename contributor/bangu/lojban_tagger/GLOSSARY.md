# lojban_tagger

A tagging and search system whose tags are Lojban words. A parser reads each tag, and reduces it
to the words of its tanru. The Architect selected each term and standard below before it was
written.

## Standards

- **The Complete Lojban Language**, Logical Language Group, first edition 1997: `C` and `V`.
  `C` is a consonant, and `V` is a vowel other than `y` (4.1). The forms are `CVC`, `CCV`,
  `CVV`, `CVCC`, `CCVC`, `CVCCV` and `CCVCV` (4.4, 4.6). A `/` marks a medial pair that need
  only be permissible, as in `CVC/CV`. The author is John Woldemar Cowan, and the same symbols
  are free at `lojban.github.io/cll`.

## Language

### Words of Lojban

**gismu**:
A root word of Lojban, with five letters of the form CVC/CV or CCVCV. The gismu list of the
Logical Language Group holds every one.
_Avoid_: root, root word, primitive

**cmavo**:
A structure word of Lojban, such as `se` or `nu`. Some cmavo carry rafsi, as `se` carries `sel`.
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
A predicate word of Lojban: a gismu, a lujvo or a borrowing. It ends in a vowel, and holds a
consonant pair in its first five letters.
_Avoid_: predicate, content word

### Tagging

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
