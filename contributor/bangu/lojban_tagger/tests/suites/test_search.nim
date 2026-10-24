## Hold search of `search.nim` to its laws: query is conjunction of its terms, more tags never
##   lose entity, lujvo term finds what its gismu find together, English finds union of meanings.
##   CLL covers no search, so suite is `Internal:`, tests named by behaviour (Article IX.10).
##   Random tags draw from twelve gismu of `POOL` alone, so entities share gismu and terms find
##     often; with every gismu of list, nearly every query would find nothing (Article IX.3).
##   Half of queries name gismu of one entity index holds, so tag removed from it, and tag
##     holding every gismu query names, change what query finds often; floors hold both counts.
##   English terms are every word that keyword, hint or gloss of meaning made of `POOL` holds,
##     enumerated whole; each may lead to gismu outside `POOL` too, which finds nothing here.
##   Union law adds two or three entities, each tagged with gismu of one meaning of English word
##     whose meanings hold two gismu sets, neither inside other, so union outgrows every meaning
##     alone often; floor holds that count.
##   Samples are drawn into pools allocated once, after one seeding per test, and served by
##     `served`.
##   Corpus holds no index of more than thirteen names: ten random, three tagged by meanings. No
##     query holds more than six terms: three drawn, doubled where repetition is tested.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[algorithm, options, random, sequtils, unittest]

import ../../src/lojban_tagger/[dictionary, english, index, search, tags]


type
  Sample = object  ## Define one random case: index, query, and changes to make.
    index: Index  ## Index built through `addTags`.
    terms: seq[Term]  ## Query, one to three terms.
    name: string  ## Name `tag` is added to.
    tag: Tag  ## Tag added: random, or holding every gismu query names as tag.
    lujvo: Tag  ## Random tag of two or three gismu, read back as lujvo.
    pick: int  ## Natural number choosing entity, and tag of it removed.


const
  SEED = 1997  ## Seed of every random draw, year of CLL first edition.
  SAMPLES = 400  ## Random cases each law is checked over.
  FLOOR_GAINED = 85  ## Fewest cases where tag added makes query find more; 114 read at `SEED`.
  FLOOR_LOST = 85  ## Fewest cases where tag removed makes query find less; 112 read at `SEED`.
  FLOOR_LUJVO = 380  ## Fewest cases whose lujvo reads back as its tag; 400 read at `SEED`.
  FLOOR_ENGLISH = 10000  ## Fewest terms of union law read as English; 10800 read at `SEED`.
  FLOOR_WIDER = 160  ## Fewest cases where union outgrows every meaning alone; 210 read at `SEED`.
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


func isWide(text: string): bool =
  ## Test English word leads to two gismu sets, neither inside other, so union can outgrow both.
  let alternatives = readTerm(text).alternatives
  for a in alternatives:
    for b in alternatives:
      if not a.allIt(it in b) and not b.allIt(it in a): return true
  false


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


proc termsHeld(entity: Entity): seq[Term] =
  ## Draw one or two terms, each gismu entity holds, so query finds entity.
  for _ in 1..rand(1..2): result.add readTerm($entity.words.sample)


func tagCovering(terms: openArray[Term]): Tag =
  ## Build tag of every gismu that terms read as tag name; empty where none reads as tag.
  for term in terms:
    if term.reading.is_tag: result.words.add term.alternatives[0]


func held(index: Index, pick: int): (string, Tag) =
  ## Choose entity of nonempty index by `pick`, and one tag it holds.
  let entity = index.entities[pick mod index.entities.len]
  (entity.name, entity.tags[(pick div index.entities.len) mod entity.tags.len])


proc poolSamples(english: openArray[string]): seq[Sample] =
  ## Draw `SAMPLES` random cases into pool allocated once; caller seeds first.
  ##   Query names gismu of entity `pick` chooses half time; tag added covers query half time.
  result = newSeqOfCap[Sample](SAMPLES)
  for _ in 1..SAMPLES:
    var sample = Sample(index: indexRandom(), pick: rand(int.high))
    let is_held = rand(1) == 0 and sample.index.entities.len > 0
    sample.terms = (
      if is_held: termsHeld(sample.index.entities[sample.pick mod sample.index.entities.len])
      else: termsRandom(english)
    )
    sample.name = $rand(0..9)
    sample.tag = (if rand(1) == 0: tagCovering(sample.terms) else: tagRandom())
    if sample.tag.words.len == 0: sample.tag = tagRandom()
    sample.lujvo = tagRandom(rand(2..3))
    result.add sample


proc poolUnion(wide: openArray[string]): seq[Sample] =
  ## Draw `SAMPLES` cases into pool allocated once, each random index with two or three entities
  ##   added, tagged with gismu of one meaning of wide English word; caller seeds first.
  result = newSeqOfCap[Sample](SAMPLES)
  for _ in 1..SAMPLES:
    let term = readTerm(wide.sample)
    var index = indexRandom()
    for i in 1..rand(2..3): index.addTags("m" & $i, [Tag(words: term.meanings.sample.words)])
    result.add Sample(index: index, terms: @[term])


iterator served[T](pool: seq[T]): lent T =
  ## Serve each sample of pool in order, with no copy.
  for i in 0..<pool.len: yield pool[i]


func names(entities: openArray[Entity]): seq[string] =
  ## List names of entities, in their order.
  entities.mapIt(it.name)


func termsGismu(words: openArray[Word]): seq[Term] =
  ## Read each gismu alone as term.
  words.mapIt readTerm($it)


func union(index: Index, term: Term): tuple[found: seq[string], widest: int] =
  ## Find names any meaning of term finds as gismu, in order of index, and most one meaning finds.
  var names_union: seq[string]
  for meaning in term.meanings:
    let found = index.find(termsGismu(meaning.words)).names
    names_union.add found
    result.widest = max(result.widest, found.len)
  result.found = index.entities.names.filterIt(it in names_union)



suite "Internal: Search":
  test "more tags never lose entity, fewer never gain one, and change moves its entity alone":
    randomize(SEED)
    let pool = poolSamples(englishPool())
    var (count_gained, count_lost) = (0, 0)
    for sample in served(pool):
      let found = sample.index.find(sample.terms).names
      var added = sample.index
      added.addTags(sample.name, [sample.tag])
      let found_added = added.find(sample.terms).names
      check found.allIt(it in found_added)  # monotonic in tags added
      check found_added.allIt(it in found or it == sample.name)  # entity tagged alone joins
      if found_added != found: inc count_gained
      if sample.index.entities.len == 0: continue
      let (name, tag) = sample.index.held(sample.pick)
      var removed = sample.index
      removed.removeTags(name, [tag])
      let found_removed = removed.find(sample.terms).names
      check found_removed.allIt(it in found)  # monotonic in tags removed
      check found.allIt(it in found_removed or it == name)  # entity stripped alone leaves
      if found_removed != found: inc count_lost
    check count_gained >= FLOOR_GAINED  # tag added changes what query finds often
    check count_lost >= FLOOR_LOST  # tag removed changes what query finds often


  test "query finds what each of its terms finds, in order of index":
    randomize(SEED)
    let pool = poolSamples(englishPool())
    for sample in served(pool):
      let found = sample.index.find(sample.terms).names
      var expected = sample.index.entities.names
      for term in sample.terms: expected = expected.filterIt(it in sample.index.find([term]).names)
      check found == expected  # conjunction, i.e. intersection of each term's entities
      check sample.index.find(sample.terms.reversed).names == found  # order of terms is free
      check sample.index.find(sample.terms & sample.terms).names == found  # repeat changes nothing


  test "lujvo term finds what its gismu terms find together":
    randomize(SEED)
    let pool = poolSamples(englishPool())
    var passed = 0
    for sample in served(pool):
      let term = readTerm($sample.lujvo)
      if not term.reading.is_tag or term.reading.tag != sample.lujvo: continue
      inc passed
      let expected = sample.index.find(termsGismu(sample.lujvo.words)).names
      check sample.index.find([term]).names == expected  # lujvo reduces to conjunction of gismu
    check passed >= FLOOR_LUJVO  # guard leaves enough lujvo reading back as their tag


  test "English term finds union of what each of its meanings finds":
    randomize(SEED)
    let
      english = englishPool()
      terms_english = english.mapIt(readTerm(it))
      pool = poolUnion(english.filterIt(it.isWide))
    var (passed, count_wider) = (0, 0)
    for sample in served(pool):
      for term in sample.terms & terms_english:  # sampled term, then every English word of `POOL`
        if term.reading.is_tag or term.meanings.len == 0: continue
        inc passed
        check sample.index.find([term]).names == sample.index.union(term).found  # disjunction
      let (found, widest) = sample.index.union(sample.terms[0])
      if found.len > widest: inc count_wider
    check passed >= FLOOR_ENGLISH  # guard leaves enough English read as English
    check count_wider >= FLOOR_WIDER  # union outgrows every meaning alone often


  test "unknown English and empty query find nothing":
    check readTerm(UNKNOWN).alternatives.len == 0  # neither tag nor English of lists
    check readTerm("the of").alternatives.len == 0  # function words alone lead nowhere
    randomize(SEED)
    let pool = poolSamples(englishPool())
    for sample in served(pool):
      check sample.index.find([readTerm(UNKNOWN)]).len == 0  # unknown term finds nothing
      check sample.index.find(sample.terms & readTerm(UNKNOWN)).len == 0  # nor in conjunction
      check sample.index.find(newSeq[Term]()).len == 0  # empty query finds nothing


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
