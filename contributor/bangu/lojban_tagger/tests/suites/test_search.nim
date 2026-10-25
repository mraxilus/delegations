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
##   Ranking law adds tag of `se` or `te` and one gismu of `POOL` to one to three names, so term
##     holding cmavo ranks some entity often. To up to two names it adds that run inside tanru
##     of three words; to up to two more, tanru of three holding same cmavo and gismu apart. So
##     entity ranked by run in longer tanru alone, and entity holding both words yet unranked,
##     come often; floors hold both counts, and count where order moved.
##   Ranking oracle compares tanru as text joined by `+`, so it shares no code with `positions`.
##   Samples are drawn into pools allocated once, after one seeding per test, and served by
##     `served`.
##   Corpus holds no index of more than thirteen names: ten random, three tagged by meanings. No
##     query holds more than six terms: three drawn, doubled where repetition is tested.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[algorithm, options, random, sequtils, strutils, unittest]

import ../../src/lojban_tagger/[dictionary, english, index, search, tags, units]


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
  FLOOR_WIDER = 160  ## Fewest cases where union outgrows every meaning alone; 228 read at `SEED`.
  FLOOR_REORDERED = 180  ## Fewest cases where ranking moves entity; 244 read at `SEED`.
  FLOOR_INSIDE = 180  ## Fewest cases ranking entity by run in longer tanru; 240 read at `SEED`.
  FLOOR_APART = 155  ## Fewest cases leaving cmavo apart from head unranked; 208 read at `SEED`.
  LENGTH_TANRU = 4  ## Longest tanru `positions` is checked over, every one of three words.
  LENGTH_RUN = 3  ## Longest run `positions` looks for, every one of three words.
  COUNT_HOLDING = 121 * 40  ## Pairs checked: 1+3+9+27+81 tanru, 1+3+9+27 runs.
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


func isHoldingText(tag: Tag, run: string): bool =
  ## Test tanru `run`, words joined by `+`, stands unbroken in tanru of tag, compared as text.
  ("+" & tag.toTanru & "+").contains("+" & run & "+")


func isHoldingAll(tag: Tag, words: openArray[Word]): bool =
  ## Test tag holds every word of `words`, in any order, unbroken or not.
  words.allIt(it in tag.words)


func termsGismu(words: openArray[Word]): seq[Term] =
  ## Read each gismu alone as term.
  words.mapIt readTerm($it)


func union(index: Index, term: Term): tuple[found: seq[string], widest: int] =
  ## Find names any meaning of term finds by its gismu, in order of index, and most one finds.
  var names_union: seq[string]
  for meaning in term.meanings:
    let found = index.find(termsGismu(meaning.words.filterIt(it.kind == Kind.Gismu))).names
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


  test "Lojban term holding cmavo ranks its own tag first, as Architect ruled":
    let
      selcia = readTag("selci'a").tag
      (ciska, notci) = (readTag("ciska").tag, readTag("notci").tag)
    var index: Index
    index.addTags("a/writer", [ciska])
    index.addTags("m/notes", [ciska, notci])
    index.addTags("z/letter", [selcia, notci])
    check index.find([readTerm("selci'a")]).names ==
        @["z/letter", "a/writer", "m/notes"]  # ruling: own tag first, rest in order of index
    check index.find([readTerm("ciska")]).names ==
        @["a/writer", "m/notes", "z/letter"]  # ruling: gismu term ranks nothing
    check index.find([readTerm("selci'a"), readTerm("notci")]).names ==
        @["z/letter", "m/notes"]  # ranked tier first, conjunction kept
    check readTerm("selci'a").alternatives == readTerm("ciska").alternatives  # acts as `ciska`
    check readTerm("selci'a").specific == selcia.units  # term keeps units it ranks by
    check readTerm("ciska").specific.len == 0  # gismu term holds no tanru to rank by
    check readTerm("write").specific.len == 0  # English term ranks nothing


  test "Lojban term holding cmavo ranks tag holding its units unbroken, as Architect ruled":
    var index: Index
    for (name, text) in [
      ("a/jobs", "ci'arseljibri"),  # `ciska` then `se jibri`: both held, `se` not before `ciska`
      ("b/record", "selci'avei"),  # `se ciska` opens tanru
      ("c/plain", "ciska"),
      ("d/apart", "selveici'a"),  # `se vreji ciska`: `se` and `ciska` apart
      ("e/minutes", "veirselci'a"),  # `se ciska` closes tanru
      ("f/grouped", "selkemci'avei"),  # `se ke ciska vreji`: `se` converts group (5.11)
      ("g/cancel", "selselci'a"),  # `se se ciska` is `ciska` (12.11)
      ("h/medium", "terselci'a"),  # `te se ciska`: x1 is medium (9.4)
      ("i/negated", "nalselci'a"),  # `na'e` negates `se ciska` (15.4)
      ("j/closed", "selci'aveike'egu'a"),  # `ke'e` implies `ke` after `se` (15.4)
      ("k/converse", "selselci'avei"),  # `se ke se ciska vreji` keeps `se ciska` (12.11)
      ("l/figure", "pevyselci'a"),  # cost: `pe'a` binds nothing, though figurative (13.13)
      ("m/reclining", "vreselci'avei"),  # cost: run read whole, though `vreta` groups first
      ("n/head", "selkemveiselci'a"),  # `se ke vreji se ciska`: `se` converts head (5.11)
      ("o/denied", "nalkemselci'avei"),  # `na'e ke se ciska vreji`: group denied (15.4)
    ]:
      index.addTags(name, [readTag(text).tag])
    check index.find([readTerm("selci'a")]).names == @[
      "b/record", "e/minutes", "k/converse", "l/figure", "m/reclining", "a/jobs", "c/plain",
      "d/apart", "f/grouped", "g/cancel", "h/medium", "i/negated", "j/closed", "n/head",
      "o/denied",
    ]  # ruling: unit `se ciska` ranks first wherever it stands, net of cmavo around it
    check index.find([readTerm("ciska")]).names ==
        index.entities.names  # ruling: gismu term ranks nothing
    check index.find([readTerm("selselci'a")]).names ==
        index.entities.names  # term whose cmavo fold away ranks nothing, as `ciska`
    check readTerm("selselci'a").specific.len == 0  # its two `se` cancel (12.11)
    check index.find([readTerm("selci'avei")]).names == @[
      "b/record", "m/reclining", "d/apart", "e/minutes", "f/grouped", "j/closed", "k/converse",
      "n/head", "o/denied",
    ]  # ruling: units of longer term stand unbroken; `k/converse` converts them whole (12.11)
    check index.find([readTerm("selci'a"), readTerm("vreji")]).names == @[
      "b/record", "e/minutes", "k/converse", "m/reclining", "d/apart", "f/grouped", "j/closed",
      "n/head", "o/denied",
    ]  # ranked tier first, conjunction kept


  test "Lojban term whose only cmavo binds nothing ranks tag holding its units":
    let figure = readTag("pevrisnyjelca").tag
    var index: Index
    index.addTags("a/burn", [readTag("risnyjelca").tag])
    index.addTags("b/figure", [figure])
    check readTerm("pevrisnyjelca").specific == figure.units  # `pe'a` stays unit, at cost
    check index.find([readTerm("pevrisnyjelca")]).names ==
        @["b/figure", "a/burn"]  # its own tag first, though `pe'a` binds nothing
    check index.find([readTerm("risnyjelca")]).names ==
        @["a/burn", "b/figure"]  # gismu term ranks nothing


  test "run stands in tanru exactly where its text does, over every short tanru":
    let alphabet = ["se", "ciska", "vreji"].mapIt(it.word.get)
    var tanru: seq[seq[Word]] = @[newSeq[Word]()]
    for length in 1..LENGTH_TANRU:
      for prefix in tanru.filterIt(it.len == length - 1):
        for word in alphabet: tanru.add prefix & word
    var count = 0
    for words in tanru:
      for run in tanru.filterIt(it.len <= LENGTH_RUN):
        inc count
        let text = Tag(words: run).toTanru
        var expected: seq[int]
        if run.len > 0:
          for start in 0 .. words.len - run.len:
            if Tag(words: words[start ..< start + run.len]).toTanru == text: expected.add start
        check words.positions(run) == expected  # every place run stands, unbroken, in order
        check (expected.len > 0) ==
            (run.len > 0 and Tag(words: words).isHoldingText(text))  # oracles agree
    check count == COUNT_HOLDING  # every pair of short tanru and run checked


  test "ranking reorders what gismu find, never adds or drops":
    randomize(SEED)
    var samples: seq[tuple[index: Index, term, plain: Term]]
    for _ in 1..SAMPLES:
      var index = indexRandom()
      let
        (cmavo, head) = (["se", "te"].sample, POOL.sample)
        converted = readTanru(cmavo & "+" & head).get
      for _ in 1..rand(1..3): index.addTags($rand(0..9), [converted])
      for _ in 1..rand(0..2):  # tanru holding run, after or before other gismu
        let other = POOL.sample
        index.addTags($rand(0..9), [readTanru(
          if rand(1) == 0: other & "+" & converted.toTanru else: converted.toTanru & "+" & other
        ).get])
      for _ in 1..rand(0..2):  # tanru holding cmavo and head apart
        index.addTags($rand(0..9), [readTanru(cmavo & "+" & POOL.sample & "+" & head).get])
      samples.add (index, readTerm($converted), readTerm(head))
    var (count_reordered, count_inside, count_apart) = (0, 0, 0)
    for sample in samples.served:
      let
        specific = sample.term.reading.tag.words
        run = Tag(words: specific).toTanru
        found = sample.index.find([sample.term])
        found_plain = sample.index.find([sample.plain])
        ranked = found_plain.filterIt(it.tags.anyIt(it.isHoldingText(run)))
      check found.names.sorted == found_plain.names.sorted  # ruling: matched by gismu alone
      check found.names ==
          ranked.names & found_plain.filterIt(it notin ranked).names  # run first, tiers kept
      check found_plain.names ==
          sample.index.entities.names.filterIt(it in found_plain.names)  # gismu term ranks none
      if found.names != found_plain.names: inc count_reordered
      if ranked.anyIt(it.tags.allIt(it.words != specific)): inc count_inside
      if found_plain.anyIt(it notin ranked and it.tags.anyIt(it.isHoldingAll(specific))):
        inc count_apart
    check count_reordered >= FLOOR_REORDERED  # ranking moves entities often enough to test
    check count_inside >= FLOOR_INSIDE  # run inside longer tanru ranks often
    check count_apart >= FLOOR_APART  # cmavo apart from head leaves entity unranked often
