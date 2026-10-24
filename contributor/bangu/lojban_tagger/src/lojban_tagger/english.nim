## Lead English words to gismu, through keywords of gismu list and glosses of lujvo list.
##
##   |--------------------------|---------------------------------------------------------|
##   | Code                     | Meaning                                                 |
##   |--------------------------|---------------------------------------------------------|
##   | Meaning                  | gismu English leads to, in order of tanru, and origin   |
##   | MEANINGS                 | every meaning lists give                                |
##   | toTokens(english)        | lowercase content words of English                      |
##   | meanings(english)        | every meaning whose English holds each word given       |
##   |--------------------------|---------------------------------------------------------|
##
##   English leads to meaning three ways, each built at compile time (Article II.2):
##     keyword and hint of gismu lead to that gismu;
##     gloss of lujvo line in Lojban notation leads to gismu its parts name;
##     gloss of lujvo line in English notation leads to gismu reader finds in its word, since
##     those parts are English keywords, never gismu (`entries.nim`).
##   Meaning holding cmavo, or word no list holds, is left out: tag is made of gismu alone.
##   Rejected: words of definitions, which lead `book` to `papri` and every place structure
##     mentioning books; Architect chose keywords and glosses.
##   English is folded to lowercase and split at every character outside `a .. z`; tokens of
##     one letter, and function words of `WORDS_FUNCTION`, are dropped, so article or
##     preposition of gloss leads nowhere and never narrows phrase.
##     Cost: list is judgement, not standard; word it holds cannot be searched alone.
##     Cost: no stemming, so `files` finds nothing `file` finds (open question in PROVENANCE).
##   Cost: reading every word of English notation at compile time, and both sorted tables, add
##     to compile of every module importing this one (PROVENANCE.md, Figures).

{.experimental: "strictFuncs".}

import std/[algorithm, options, sequtils, strutils]

import ./[dictionary, entries, forms, tags]
import ./lists/[gismu, lujvo]


type
  Origin* {.pure.} = enum  ## Define which text of which list English came from.
    Keyword, Hint, Gloss

  Meaning* = object  ## Define what English word leads to: gismu of one tanru, and origin.
    words*: seq[Word]  ## Gismu in order of tanru; one alone for keyword or hint.
    origin*: Origin  ## Field English came from.
    entry*: int  ## Index into `LIST_GISMU` for keyword or hint, into `LIST_LUJVO` for gloss.


const WORDS_FUNCTION* = [
  "an", "and", "as", "at", "be", "by", "for", "from", "in", "into", "is", "it", "of", "on",
  "or", "so", "something", "someone", "the", "to", "with",
]
  ## English function words glosses use as glue, never as content; sorted for search.


func toTokens*(english: string): seq[string] =
  ## Split English into lowercase tokens of letters; one-letter tokens and function words dropped.
  for token in english.toLowerAscii.split(AllChars - {'a' .. 'z'}):
    if token.len >= 2 and WORDS_FUNCTION.binarySearch(token) < 0: result.add token


func textEnglish*(meaning: Meaning): string =
  ## Read English text meaning came from.
  case meaning.origin
  of Origin.Keyword: LIST_GISMU[meaning.entry].keyword
  of Origin.Hint: LIST_GISMU[meaning.entry].hint
  of Origin.Gloss: LIST_LUJVO[meaning.entry].gloss


func gismuLujvo*(entry: EntryLujvo): seq[Word] =
  ## Read gismu of lujvo line: parts named in Lojban, or word read where parts are English.
  ##   Empty where any part is no gismu of list, or word reads as no tag.
  case entry.notation
  of Notation.Lojban:
    for part in entry.parts:
      let found = part.word
      if found.isNone or found.get.kind != Kind.Gismu: return @[]
      result.add found.get
  of Notation.English:
    let reading = entry.word.readTag
    if reading.is_tag: result = reading.tag.words


func constructMeanings(): seq[Meaning] {.compileTime.} =
  ## Build every meaning English leads to: keyword and hint of each gismu, then gloss of each
  ##   lujvo whose tanru holds listed gismu alone.
  for i, entry in LIST_GISMU:
    if not entry.word.isGismu: continue
    result.add Meaning(words: @[Word(i)], origin: Origin.Keyword, entry: i)
    if entry.hint.len > 0: result.add Meaning(words: @[Word(i)], origin: Origin.Hint, entry: i)
  for i, entry in LIST_LUJVO:
    let words = entry.gismuLujvo
    if words.len > 0: result.add Meaning(words: words, origin: Origin.Gloss, entry: i)


const MEANINGS* = constructMeanings()  ## Every meaning English leads to.


func constructEnglish(): seq[(string, int)] {.compileTime.} =
  ## Build every English token with index of meaning holding it, sorted by token.
  for i, meaning in MEANINGS:
    for token in meaning.textEnglish.toTokens.deduplicate: result.add (token, i)
  result.sort(proc (a, b: (string, int)): int = cmp(a, b))


const ENGLISH = constructEnglish()  ## Every English token, sorted, with meaning index.



#[ Lookups ]#

func meanings*(english: string): seq[Meaning] =
  ## Find every meaning whose English text holds each token of `english`.
  ##   Empty where `english` holds no token, or no meaning holds all of them.
  let tokens = english.toTokens.deduplicate
  if tokens.len == 0: return
  var indices: seq[int]
  for n, token in tokens:
    var
      found: seq[int]
      at = ENGLISH.lowerBound(token, proc (row: (string, int), key: string): int =
        cmp(row[0], key))
    while at < ENGLISH.len and ENGLISH[at][0] == token:
      found.add ENGLISH[at][1]
      inc at
    indices = (if n == 0: found else: indices.filterIt(it in found))
  for i in indices: result.add MEANINGS[i]
