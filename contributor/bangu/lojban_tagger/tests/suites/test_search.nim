## Hold search of `search.nim` to its laws: query is conjunction of its terms, more tags never
##   lose entity, lujvo term finds what its gismu find together, English finds union of meanings.
##   CLL covers no search, so suite is `Internal:`, tests named by behaviour (Article IX.10).
##   Random tags draw from twelve gismu of `POOL` alone, so entities share gismu and terms find
##     often; with every gismu of list, nearly every query would find nothing (Article IX.3).
##   English terms are every word that keyword, hint or gloss of meaning made of `POOL` holds,
##     enumerated whole; each may lead to gismu outside `POOL` too, which finds nothing here.
##   Corpus holds no index of more than ten names, and no query of more than three terms.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[algorithm, options, random, sequtils, unittest]

import ../../src/lojban_tagger/[dictionary, english, index, search, tags]


const
  SEED = 1997  ## Seed of every random draw, year of CLL first edition.
  SAMPLES = 400  ## Random indexes, with random terms, each law is checked over.
  SAMPLES_FLOOR = 200  ## Fewest samples guard must pass, so guard rejecting most fails.
  POOL = [
    "cukta", "datni", "gerku", "liste", "mamta", "mlatu", "papri", "patfu", "skami", "tcidu",
    "vreji", "zdani",
  ]
    ## Gismu random tags draw from, chosen so English of lists ties several together.
  UNKNOWN = "qwzx"  ## Text reading as neither tag nor English of lists.
  WORDS_POOL = block:
    ## Words of `POOL`, as list holds them.
    var words: seq[Word]
    for text in POOL: words.add text.word.get
    words


proc tagRandom(count = 0): Tag =
  ## Draw tag of `count` gismu of `POOL`, repeats allowed; one to three where `count` is 0.
  for _ in 1..(if count > 0: count else: rand(1..3)): result.words.add WORDS_POOL.sample


proc indexRandom(): Index =
  ## Build index of up to ten names through `addTags`, one to three tags each change.
  for _ in 1..rand(0..10):
    var tags: seq[Tag]
    for _ in 1..rand(1..3): tags.add tagRandom()
    result.addTags($rand(0..9), tags)


func englishPool(): seq[string] =
  ## List every English word some meaning made of `POOL` alone holds, sorted, none twice.
  for meaning in MEANINGS:
    if meaning.words.allIt(it in WORDS_POOL): result.add meaning.textEnglish.toTokens
  result = result.deduplicate.sorted


proc termRandom(english: openArray[string]): Term =
  ## Draw term: gismu of `POOL`, lujvo of two or three, English word, or `UNKNOWN`.
  case rand(9)
  of 0..3: readTerm(POOL.sample)
  of 4..5: readTerm($tagRandom(rand(2..3)))
  of 6..8: readTerm(english.sample)
  else: readTerm(UNKNOWN)


proc termsRandom(english: openArray[string]): seq[Term] =
  ## Draw one to three random terms.
  for _ in 1..rand(1..3): result.add termRandom(english)


func names(entities: openArray[Entity]): seq[string] =
  ## List names of entities, in their order.
  entities.mapIt(it.name)


func termsGismu(words: openArray[Word]): seq[Term] =
  ## Read each gismu alone as term.
  words.mapIt readTerm($it)



suite "Internal: Search":
  test "more tags never lose entity, fewer never gain one":
    randomize(SEED)
    let english = englishPool()
    for _ in 1..SAMPLES:
      let
        index = indexRandom()
        terms = termsRandom(english)
        (name, tag) = ($rand(0..9), tagRandom())
        found = index.find(terms).names
      var (added, removed) = (index, index)
      added.addTags(name, [tag])
      removed.removeTags(name, [tag])
      check found.allIt(it in added.find(terms).names)  # monotonic in tags added
      check removed.find(terms).names.allIt(it in found)  # monotonic in tags removed


  test "query finds what each of its terms finds, in order of index":
    randomize(SEED)
    let english = englishPool()
    for _ in 1..SAMPLES:
      let
        index = indexRandom()
        terms = termsRandom(english)
        found = index.find(terms).names
      var expected = index.entities.names
      for term in terms: expected = expected.filterIt(it in index.find([term]).names)
      check found == expected  # conjunction, i.e. intersection of each term's entities
      check found.isSorted  # order of index, which sorts by name
      check index.find(terms.reversed).names == found  # order of terms does not matter
      check index.find(terms & terms).names == found  # term repeated changes nothing


  test "lujvo term finds what its gismu terms find together":
    randomize(SEED)
    var passed = 0
    for _ in 1..SAMPLES:
      let
        index = indexRandom()
        tag = tagRandom(rand(2..3))
        term = readTerm($tag)
      if not term.reading.is_tag or term.reading.tag != tag: continue
      inc passed
      let expected = index.find(termsGismu(tag.words)).names
      check index.find([term]).names == expected  # lujvo reduces to conjunction of gismu
    check passed >= SAMPLES_FLOOR  # guard leaves enough lujvo reading back as their tag


  test "English term finds union of what each of its meanings finds":
    randomize(SEED)
    let english = englishPool()
    var passed = 0
    for _ in 1 .. SAMPLES div 10:
      let index = indexRandom()
      for text in english:  # every English word of `POOL`, exhaustive
        let term = readTerm(text)
        if term.reading.is_tag or term.meanings.len == 0: continue
        inc passed
        var union: seq[string]
        for meaning in term.meanings: union.add index.find(termsGismu(meaning.words)).names
        let expected = index.entities.names.filterIt(it in union)
        check index.find([term]).names == expected  # disjunction over meanings
    check passed >= SAMPLES_FLOOR  # guard leaves enough English read as English


  test "unknown English and empty query find nothing":
    check readTerm(UNKNOWN).alternatives.len == 0  # neither tag nor English of lists
    check readTerm("the of").alternatives.len == 0  # function words alone lead nowhere
    randomize(SEED)
    let english = englishPool()
    for _ in 1..SAMPLES:
      let index = indexRandom()
      check index.find([readTerm(UNKNOWN)]).len == 0  # unknown term finds nothing
      check index.find(termsRandom(english) & readTerm(UNKNOWN)).len == 0  # nor in conjunction
      check index.find(newSeq[Term]()).len == 0  # empty query finds nothing, vacuous truth aside


  test "gismu finds entity tagged with lujvo holding it":
    let datnyvei = readTag("datnyvei").tag
    var index: Index
    index.addTags("notes", [datnyvei])
    index.addTags("photo", [readTag("pixra").tag])
    check index.find([readTerm("vreji")]).names == @["notes"]  # head of tanru finds it
    check index.find([readTerm("datni")]).names == @["notes"]  # modifier of tanru finds it
    check index.find([readTerm("datnyvreji")]).names == @["notes"]  # other spelling, one tag
    check index.find([readTerm("file")]).names == @["notes"]  # English of gloss finds it


  test "lujvo finds entity holding its gismu in separate tags, at cost of relation":
    let (datni, vreji) = (readTag("datni").tag, readTag("vreji").tag)
    var index: Index
    index.addTags("apart", [datni, vreji])
    index.addTags("data", [datni])
    index.addTags("record", [vreji])
    check index.find([readTerm("datnyvei")]).names == @["apart"]  # gismu held apart satisfy it
    check index.find([readTerm("datni"), readTerm("vreji")]).names == @["apart"]  # same set
    check index.find([readTerm("datni")]).names == @["apart", "data"]  # gismu alone finds more
