## Hold English leading to gismu against `english.nim`: tokens, keywords, glosses and phrases.
##   CLL defines no English, so every suite is internal and every test is named by behaviour
##     (Article IX.10); comment on each check names law it holds.
##   Examples are lines of lists as committed (`cukta`, `ci'erkei`); laws run exhaustively over
##     every meaning, every gismu and every lujvo line, and over pool of seeded meanings, each
##     with its tokens shuffled, that iterator serves (Article IX.3, STYLE.md §6).
##   Gismu of lujvo line come two ways: parts named, and word read. Laws hold one way against
##     other, never against code that builds them; English notation names no gismu, so reader is
##     held to keywords its parts write.
##   Corpus does not cover yet: phrases of three words or more, and English no list holds.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[algorithm, options, random, sequtils, strutils, unittest]

import ../../src/lojban_tagger/[dictionary, english, entries, tags]
import ../../src/lojban_tagger/lists/[gismu, lujvo]


const
  SAMPLES = 500  ## Random meanings phrase law draws from, seeded.
  FLOOR_PHRASE = 150
    ## Least of those holding two distinct tokens or more, that phrase law reads: 230 read at
    ## seed `0`; keyword and hint mostly hold one word, many glosses several.
  FLOOR_FOUND = 4700
    ## Least meanings whose English holds token, that completeness law reads: 4815 of 4838 read;
    ## 23 keywords hold digits or function words alone.
  FLOOR_READ_LOJBAN = 2400
    ## Least lines of Lojban notation whose parts name gismu alone: 2500 of 3044 read; rest hold
    ## cmavo.
  FLOOR_READ_ENGLISH = 600  ## Least lines of English notation whose word reads: 640 of 758 read.
  FLOOR_KEYWORD = 600
    ## Least lines of English notation whose gismu carry keywords parts write, case and hyphens
    ## aside: 629 of 640 that read; rest write synonym (`old` for `slabu`), misspell, or name
    ## gismu in Lojban.
  LUJVO_PARTS_ODD = ["vikmau"]
    ## Lines of English notation listing more parts than gismu: `vikmau` writes `2nd-place-of`,
    ## `viscous` and `more` for `viknu` and `zmadu`; list data, not reader.


func tanru(text: string): seq[Word] =
  ## Read gismu joined by `+` as their words; suite writes listed gismu alone.
  text.readTanru.get.words


func intersection(a, b: seq[Meaning]): seq[Meaning] =
  ## Keep meanings of `a` that `b` holds, in order of `a`.
  a.filterIt(it in b)


func indexLujvo(word: string): int =
  ## Find line of lujvo list spelling `word`; suite names listed words alone.
  LIST_LUJVO.mapIt(it.word).find(word)


func normalEnglish(text: string): string =
  ## Fold English to lowercase, hyphen to space, so keyword and part of list compare.
  text.toLowerAscii.replace('-', ' ')


proc drawMeanings(): seq[(Meaning, seq[string])] =
  ## Draw `SAMPLES` meanings, seeded, each with its distinct tokens shuffled.
  randomize(0)
  for _ in 1 .. SAMPLES:
    let meaning = MEANINGS[rand(MEANINGS.high)]
    var tokens = meaning.textEnglish.toTokens.deduplicate
    tokens.shuffle
    result.add (meaning, tokens)


let MEANINGS_SAMPLED = drawMeanings()  ## Random meanings phrase law reads, drawn once.


iterator meaningsRandom(): (lent Meaning, lent seq[string]) =
  ## Serve each random meaning of pool with its shuffled tokens, with no copy.
  for i in 0 ..< MEANINGS_SAMPLED.len: yield (MEANINGS_SAMPLED[i][0], MEANINGS_SAMPLED[i][1])



suite "Internal: English":
  test "Tokens are lowercase letters, split at every other character":
    check "Big-Book, KILO2byte".toTokens == @["big", "book", "kilo", "byte"]  # split and folded
    check "x1 is y".toTokens.len == 0  # one-letter tokens and function words dropped
    check "".toTokens.len == 0  # degenerate: no text, no token
    for meaning in MEANINGS:  # every meaning, exhaustive
      let
        text = meaning.textEnglish
        tokens = text.toTokens
      check tokens.allIt(it.len >= 2 and it.allIt(it in 'a' .. 'z'))  # letters, two or more
      check text.toUpperAscii.toTokens == tokens  # case never changes tokens
      check tokens.join(" ").toTokens == tokens  # idempotent


  test "Function words lead nowhere and never narrow phrase":
    for word in ["an", "and", "the", "of", "with", "something"]:
      check word.toTokens.len == 0  # function word dropped
      check word.meanings.len == 0  # function word alone finds nothing
    check "the".meanings.len == 0  # article leads nowhere
    check "the book".meanings == "book".meanings  # article never narrows phrase
    check "a book".meanings == "book".meanings  # one-letter token never narrows phrase


  test "Every function word is dropped, since list is sorted for binary search":
    # Regression: `english.nim` held `something` before `someone`, so binary search missed
    #   `someone`, and `meanings` of it found 62.
    check WORDS_FUNCTION.isSorted  # binary search reads sorted list
    check "someone".toTokens.len == 0  # case as found: search missed it
    check "someone".meanings.len == 0  # case as found: it led to 62 meanings
    for word in WORDS_FUNCTION:  # every function word, exhaustive
      check word.toTokens.len == 0  # domain: each one dropped
    for meaning in MEANINGS:  # every meaning, exhaustive
      check meaning.textEnglish.toTokens.allIt(it notin WORDS_FUNCTION)  # domain: none indexed


  test "Keyword leads to its gismu":
    let
      cukta = "cukta".word.get
      keywords = "book".meanings.filterIt(it.origin == Origin.Keyword)
    check Meaning(words: @[cukta], origin: Origin.Keyword, entry: cukta.index) in
        "book".meanings  # keyword `book` of `cukta`
    check keywords.mapIt(it.words) == @[@[cukta]]  # one gismu carries keyword `book`


  test "Gloss of Lojban notation leads to gismu its parts name":
    let found = "file".meanings.filterIt(it.words == tanru("datni+vreji"))
    check found.len == 1  # one line glosses `file` as `datni+vreji`
    check found[0].origin == Origin.Gloss  # gloss, not keyword
    check LIST_LUJVO[found[0].entry].notation == Notation.Lojban  # parts written as gismu
    check LIST_LUJVO[found[0].entry].parts == @["datni", "vreji"]  # parts name gismu found


  test "Gloss of English notation leads to gismu read from its word":
    let at = indexLujvo("ci'erkei")
    check LIST_LUJVO[at].notation == Notation.English  # parts are keywords, not gismu
    check LIST_LUJVO[at].parts == @["system", "play"]  # keywords of `ciste` and `kelci`
    check Meaning(words: tanru("ciste+kelci"), origin: Origin.Gloss, entry: at) in
        "game".meanings  # gloss `play a game` read through word `ci'erkei`


  test "Gloss leads to every gismu of its tanru, in order":
    let expected = @[tanru("kilto+skami+sorcu+gradu")]
    check "kilobyte".meanings.mapIt(it.words) == expected  # one gloss, four gismu of tanru


  test "Phrase finds intersection of its words, in any order and case":
    let (play, game) = ("play".meanings, "game".meanings)
    check play.len > 0 and game.len > 0  # each word alone finds meanings
    check "play game".meanings == intersection(play, game)  # conjunction of words
    check "play game".meanings.anyIt(it.words == tanru("ciste+kelci"))  # `ci'erkei` in both
    check "game play".meanings == "play game".meanings  # order of words free
    check "play play".meanings == play  # repeated word never narrows
    check "BOOK".meanings == "book".meanings  # case folded


  test "Phrase of words from one meaning finds it, as intersection of words":
    var count_phrase = 0
    for meaning, tokens in meaningsRandom():  # `SAMPLES` meanings, seeded
      if tokens.len < 2: continue
      let
        (first, second) = (tokens[0], tokens[1])
        phrase = first & " " & second
      check meaning in phrase.meanings  # meaning holds each word of phrase
      check phrase.meanings == intersection(first.meanings, second.meanings)  # conjunction
      check (second & " " & first).meanings == phrase.meanings  # order of words free
      check phrase.toUpperAscii.meanings == phrase.meanings  # case folded
      inc count_phrase
    check count_phrase >= FLOOR_PHRASE  # guard kept enough samples


  test "Every meaning is found by its own English":
    var count_found = 0
    for meaning in MEANINGS:  # every meaning, exhaustive
      let text = meaning.textEnglish
      if text.toTokens.len == 0:
        check meaning.origin != Origin.Gloss  # every gloss holds content word
        continue
      check meaning in text.meanings  # completeness: English found leads back
      inc count_found
    check count_found >= FLOOR_FOUND  # guard kept nearly every meaning


  test "Every meaning holds gismu alone":
    for meaning in MEANINGS:  # every meaning, exhaustive
      check meaning.words.len > 0  # meaning leads somewhere
      check meaning.words.allIt(it.kind == Kind.Gismu)  # tag is made of gismu alone
      if meaning.origin != Origin.Gloss:
        check meaning.words == @[Word(meaning.entry)]  # keyword and hint lead to own gismu


  test "Every gismu has keyword meaning, and hint meaning where list gives hint":
    var lut_keywords_by_entry, lut_hints_by_entry = newSeq[int](LIST_GISMU.len)
    for meaning in MEANINGS:
      case meaning.origin
      of Origin.Keyword: inc lut_keywords_by_entry[meaning.entry]
      of Origin.Hint: inc lut_hints_by_entry[meaning.entry]
      of Origin.Gloss: discard
    for i, entry in LIST_GISMU:  # every entry, exhaustive
      let is_gismu = Word(i).kind == Kind.Gismu
      check lut_keywords_by_entry[i] == ord(is_gismu)  # one keyword meaning per gismu
      check lut_hints_by_entry[i] == ord(is_gismu and entry.hint.len > 0)  # hint where given


  test "Gloss meanings are lujvo lines whose word reads as tag, each once":
    let glosses = MEANINGS.filterIt(it.origin == Origin.Gloss)
    check glosses.len == LIST_LUJVO.countIt(it.word.readTag.is_tag)  # one per line read, no more
    for n in 1 ..< glosses.len:
      check glosses[n - 1].entry < glosses[n].entry  # each line once, in list order
    for meaning in glosses:
      let reading = LIST_LUJVO[meaning.entry].word.readTag
      check reading.is_tag and reading.tag.words == meaning.words  # gismu reader finds in word


  test "gismuLujvo of Lojban notation spells its parts, and agrees with reader":
    var count_read = 0
    for entry in LIST_LUJVO:  # every line, exhaustive
      if entry.notation != Notation.Lojban: continue
      let (words, reading) = (entry.gismuLujvo, entry.word.readTag)
      check (words.len > 0) == reading.is_tag  # parts name gismu alone where word reads as tag
      if words.len == 0: continue
      check words.mapIt($it) == entry.parts  # round trip: gismu found spell parts back
      check reading.is_tag and reading.tag.words == words  # reader splits word into parts
      inc count_read
    check count_read >= FLOOR_READ_LOJBAN  # guard kept most lines


  test "gismuLujvo of English notation holds gismu whose keywords its parts write":
    var count_read, count_keyword = 0
    for line in LIST_LUJVO:  # every line, exhaustive
      if line.notation != Notation.English: continue
      let words = line.gismuLujvo
      if words.len == 0: continue
      check (words.len == line.parts.len) ==
          (line.word notin LUJVO_PARTS_ODD)  # one gismu per English part, list slips aside
      if words.mapIt(it.entry.keyword.normalEnglish) == line.parts.mapIt(it.normalEnglish):
        inc count_keyword
      inc count_read
    check count_read >= FLOOR_READ_ENGLISH  # guard kept most lines
    check count_keyword >= FLOOR_KEYWORD  # reader finds gismu parts name by keyword
