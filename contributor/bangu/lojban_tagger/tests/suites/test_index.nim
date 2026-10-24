## Hold index of `index.nim` to its laws: text written reads back as index it came from, and
##   canonical text read writes back as it was; changes keep names sorted and distinct, and touch
##   named entity alone; reader refuses bad line by its number and its text.
##   CLL covers no index, so suite is `Internal:`, tests named by behaviour (Article IX.10).
##   Random indexes are built through `addTags` alone, so corpus holds what changes make. Names
##     are spelled from five pieces, space, `/` and `é` among them, so names collide and share
##     prefixes often; tags draw one to three gismu from every gismu of list (Article IX.3).
##   Canonical text is written by suite, never by `toText`: names sorted and distinct, tags
##     distinct and spelled as gismu joined by `+`, so reader and writer are held apart.
##   Steps of random walk change entity index holds three times in four, and removal takes tags
##     entity holds three times in four, all of them one time in three, so removals that change
##     index and that drop entity are common; floors hold both counts.
##   Samples are drawn into pools allocated once, after one seeding per test, and served by
##     `served`; steps of walk are drawn before walk reads index they change.
##   Corpus holds no name of more than four pieces, and no tag of more than three gismu. Entity
##     holds at most 8 tags in random indexes and 19 in walks, measured at `SEED`, since names
##     collide and changes merge.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[algorithm, options, random, sequtils, strutils, unittest]

import ../../src/lojban_tagger/[dictionary, index, tags]
import ../../src/lojban_tagger/lists/gismu


type
  Sample = object  ## Define one random case: index, name and tags to change it by, bad line.
    index: Index  ## Index built through `addTags`.
    name: string  ## Name to change.
    tags: seq[Tag]  ## Tags to add or remove.
    bad: string  ## Bad line to insert.
    pick: int  ## Natural number choosing line bad one goes before.

  Source {.pure.} = enum  ## Define where tags removed by step of walk come from.
    Held  ## Tags entity holds, chosen by mask.
    Mixed  ## Tags entity holds, chosen by mask, and random tags.
    Drawn  ## Random tags alone, rarely held.

  Step = object  ## Define one change of walk, drawn before walk reads index it changes.
    is_adding: bool  ## Add tags, else remove them.
    is_held: bool  ## Change entity index holds, chosen by `pick`, where index holds any.
    name: string  ## Name changed where `is_held` is false or index is empty.
    tags: seq[Tag]  ## Random tags added, or removed where `source` is not `Held`.
    source: Source  ## Where tags removed come from.
    is_every: bool  ## Remove every tag held, else tags `mask` chooses.
    mask: int  ## Bits choosing which tags held are removed.
    pick: int  ## Natural number choosing entity held.

  Walk = object  ## Define one random walk: index it starts from, and its changes.
    start: Index  ## Index walk starts from.
    steps: seq[Step]  ## Changes, in order.


const
  SEED = 1997  ## Seed of every random draw, year of CLL first edition.
  SAMPLES = 400  ## Random cases each law is checked over.
  FLOOR_FRESH = 300  ## Fewest cases whose name index lacks; 380 read at `SEED`.
  WALKS = 40  ## Random walks of changes.
  CHANGES = 40  ## Changes in each random walk.
  FLOOR_CHANGING = 300  ## Fewest removals in walks that change index; 396 of 807 read at `SEED`.
  FLOOR_DROPPING = 140  ## Fewest removals in walks that drop entity; 187 read at `SEED`.
  PIECES_NAME = ["a", "b", " ", "/", "é"]  ## Pieces random name is spelled from.
  LINES_BAD = ["beta datni", "beta\tdatni\tvreji", "", "\tdatni"]  ## Bad lines cases insert.
  TEXTS_CANONICAL = [
    HEADER & "\n",
    HEADER & "\nnotes\tdatni\n",
    HEADER & "\n a\tdatni+vreji cukta\nnotes/plan.md\tvreji datni datni+datni\né\tmlatu+zdani\n",
  ]
    ## Canonical texts written by hand: empty index, one entity, names of space, path and `é`.
  WORDS_GISMU = block:
    ## Every gismu of list, cmavo left out, since tag holds gismu alone.
    var words: seq[Word]
    for i in 0..<LIST_GISMU.len:
      if Word(i).kind == Kind.Gismu: words.add Word(i)
    words


proc tagRandom(): Tag =
  ## Draw tag of one to three random gismu, repeats allowed.
  for _ in 1..rand(1..3): result.words.add WORDS_GISMU.sample


proc tagsRandom(): seq[Tag] =
  ## Draw one to three random tags.
  for _ in 1..rand(1..3): result.add tagRandom()


proc nameRandom(): string =
  ## Draw name of one to four pieces of `PIECES_NAME`.
  for _ in 1..rand(1..4): result.add PIECES_NAME.sample


proc indexRandom(): Index =
  ## Build index of up to eight changes through `addTags`.
  for _ in 1..rand(0..8): result.addTags(nameRandom(), tagsRandom())


proc textCanonicalRandom(): string =
  ## Write canonical text by hand, never through `toText`: up to eight names, sorted and
  ##   distinct, each with one to three distinct tags spelled as gismu joined by `+`.
  var names: seq[string]
  for _ in 1..rand(0..8): names.add nameRandom()
  result = HEADER & "\n"
  for name in names.deduplicate.sorted:
    var spellings: seq[string]
    for _ in 1..rand(1..3): spellings.add tagRandom().words.mapIt($it).join("+")
    result.add name & "\t" & spellings.deduplicate.join(" ") & "\n"


proc poolSamples(): seq[Sample] =
  ## Draw `SAMPLES` random cases into pool allocated once; caller seeds first.
  result = newSeqOfCap[Sample](SAMPLES)
  for _ in 1..SAMPLES:
    result.add Sample(
      index: indexRandom(),
      name: nameRandom(),
      tags: tagsRandom(),
      bad: LINES_BAD.sample,
      pick: rand(int.high),
    )


proc poolTexts(): seq[string] =
  ## Draw `SAMPLES` canonical texts into pool allocated once; caller seeds first.
  result = newSeqOfCap[string](SAMPLES)
  for _ in 1..SAMPLES: result.add textCanonicalRandom()


proc poolWalks(): seq[Walk] =
  ## Draw `WALKS` random walks of `CHANGES` steps into pool allocated once; caller seeds first.
  ##   Step changes entity held three times in four; removal takes tags held three times in
  ##   four, every one of them one time in three.
  result = newSeqOfCap[Walk](WALKS)
  for _ in 1..WALKS:
    var walk = Walk(start: indexRandom(), steps: newSeqOfCap[Step](CHANGES))
    for _ in 1..CHANGES:
      walk.steps.add Step(
        is_adding: rand(1) == 0,
        is_held: rand(3) > 0,
        name: nameRandom(),
        tags: tagsRandom(),
        source: [Source.Held, Source.Held, Source.Mixed, Source.Drawn].sample,
        is_every: rand(2) == 0,
        mask: rand(int.high),
        pick: rand(int.high),
      )
    result.add walk


iterator served[T](pool: seq[T]): lent T =
  ## Serve each sample of pool in order, with no copy.
  for i in 0..<pool.len: yield pool[i]


func names(index: Index): seq[string] =
  ## List names of entities, in order of index.
  index.entities.mapIt(it.name)


func isOrdered(index: Index): bool =
  ## Test names strictly increase, i.e. sorted and distinct.
  for i in 1..<index.entities.len:
    if index.entities[i-1].name >= index.entities[i].name: return false
  true


func isRefused(loaded: Loaded, line: int, offending: string): bool =
  ## Test reader refused at `line`, with problem ending in `offending` in backticks.
  not loaded.is_loaded and loaded.line == line and
      loaded.problem.endsWith("`" & offending & "`.")


func tagsHeld(index: Index, name: string): seq[Tag] =
  ## Read tags of entity named `name`; empty where index holds none.
  let found = index.entity(name)
  if found.isSome: found.get.tags else: @[]


func others(index: Index, name: string): seq[Entity] =
  ## List every entity not named `name`, in order of index.
  index.entities.filterIt(it.name != name)


func nameStep(index: Index, step: Step): string =
  ## Choose name step changes: entity held that `pick` chooses, else random name of step.
  if step.is_held and index.entities.len > 0: index.entities[step.pick mod index.entities.len].name
  else: step.name


func tagsRemoved(held: openArray[Tag], step: Step): seq[Tag] =
  ## Choose tags step removes: tags held that mask chooses, random tags, or both, by source.
  if step.source != Source.Drawn:
    for i, tag in held:
      if step.is_every or ((step.mask shr (i mod 62)) and 1) == 1: result.add tag
  if step.source != Source.Held: result.add step.tags



suite "Internal: Index":
  test "text written reads back as index, and canonical text read writes back as it was":
    randomize(SEED)
    let (pool, texts) = (poolSamples(), poolTexts())
    for sample in served(pool):
      let loaded = sample.index.toText.readIndex
      check loaded.is_loaded  # writer emits only what reader accepts
      if loaded.is_loaded: check loaded.index == sample.index  # round trip, index through text
    for text in served(texts):  # canonical text written by suite
      let loaded = text.readIndex
      check loaded.is_loaded  # reader accepts canonical text
      if loaded.is_loaded: check loaded.index.toText == text  # round trip, text through index
    for text in TEXTS_CANONICAL:
      let loaded = text.readIndex
      check loaded.is_loaded and loaded.index.toText == text  # round trip, text by hand
    let unfinished = readIndex(HEADER & "\nnotes\tdatni")
    check unfinished.is_loaded and unfinished.index.names == @["notes"]  # final line feed optional
    for (text, canonical) in [  # non-canonical text: line feed missing, tag repeated, spaces
      (HEADER, HEADER & "\n"),
      (HEADER & "\nnotes\tdatni datni\n", HEADER & "\nnotes\tdatni\n"),
      (HEADER & "\nnotes\t datni   vreji \n", HEADER & "\nnotes\tdatni vreji\n"),
    ]:
      let loaded = text.readIndex
      check loaded.is_loaded and loaded.index.toText == canonical  # normalises to canonical


  test "adding tags twice changes nothing adding once did not":
    randomize(SEED)
    let pool = poolSamples()
    for sample in served(pool):
      var once, twice, doubled = sample.index
      once.addTags(sample.name, sample.tags)
      twice.addTags(sample.name, sample.tags)
      twice.addTags(sample.name, sample.tags)
      doubled.addTags(sample.name, sample.tags & sample.tags)
      check twice == once  # idempotence
      check doubled == once  # tag given twice in one call is added once
      check once.entity(sample.name).isSome  # entity is made where index holds none
      for tag in sample.tags:
        check tag in once.entity(sample.name).get.tags  # every tag given is held


  test "adding no tag changes nothing, so text written still reads back":
    # Regression: `addTags(name, [])` made entity with no tag, whose written line reader refuses.
    var index: Index
    index.addTags("notes", [])
    check index.entity("notes").isNone  # case as found: no entity made
    check index.toText.readIndex.is_loaded  # case as found: text reads back
    randomize(SEED)
    for _ in 1..SAMPLES:  # domain: no tag added to random name of random index
      let (before, name) = (indexRandom(), nameRandom())
      var after = before
      after.addTags(name, [])
      check after == before  # domain: no tag changes nothing
      check after.toText.readIndex.is_loaded  # domain: text reads back


  test "removing tags added to fresh entity restores index":
    randomize(SEED)
    let pool = poolSamples()
    var passed = 0
    for sample in served(pool):
      if sample.index.entity(sample.name).isSome: continue
      inc passed
      var after = sample.index
      after.addTags(sample.name, sample.tags)
      after.removeTags(sample.name, sample.tags)
      check after == sample.index  # inverse on fresh entity
    check passed >= FLOOR_FRESH  # guard leaves enough fresh names


  test "names stay sorted and distinct, and change touches named entity alone, in any walk":
    randomize(SEED)
    let pool = poolWalks()
    var (count_changing, count_dropping) = (0, 0)
    for walk in served(pool):
      var index = walk.start
      for step in walk.steps:
        let
          before = index
          name = before.nameStep(step)
          held = before.tagsHeld(name)
          removed = (if step.is_adding: @[] else: held.tagsRemoved(step))
        if step.is_adding: index.addTags(name, step.tags)
        else: index.removeTags(name, removed)
        let after = index.tagsHeld(name)
        check index.isOrdered  # names sorted and distinct
        for entity in index.entities:
          check entity.tags.len > 0  # entity holds at least one tag
          check entity.tags.deduplicate == entity.tags  # tags distinct
        check index.toText.readIndex.is_loaded  # text written after any change reads back
        check index.others(name) == before.others(name)  # change touches named entity alone
        if step.is_adding:
          check after.len >= held.len and after[0..<held.len] == held  # tags held keep place
          check step.tags.allIt(it in after)  # every tag given is held
          check after.allIt(it in held or it in step.tags)  # no tag held but those given
        else:
          check after == held.filterIt(it notin removed)  # every other tag stays, in order
          if index != before: inc count_changing
          if index.entities.len < before.entities.len: inc count_dropping
    check count_changing >= FLOOR_CHANGING  # removals change index often
    check count_dropping >= FLOOR_DROPPING  # removals drop entity often


  test "entity left with no tag leaves index":
    randomize(SEED)
    let pool = poolSamples()
    for sample in served(pool):
      var index = sample.index
      index.addTags(sample.name, sample.tags)
      index.removeTags(sample.name, index.tagsHeld(sample.name))
      check index.entity(sample.name).isNone  # last tag removed takes entity with it
      check sample.name notin index.names  # no entity holds name
    var index: Index
    let (datni, vreji) = (readTanru("datni").get, readTanru("vreji").get)
    index.addTags("notes", [datni, vreji])
    index.removeTags("notes", [datni])
    check index.entity("notes").get.tags == @[vreji]  # entity keeping tag stays
    index.removeTags("missing", [vreji])
    check index.names == @["notes"]  # removing from missing entity changes nothing
    index.removeTags("notes", [datni])
    check index.entity("notes").get.tags == @[vreji]  # removing tag not held changes nothing


  test "reader refuses bad header at line 1, ending in text read":
    check readIndex("").isRefused(1, "")  # empty file holds no header
    check readIndex("lojban_tagger index 2\n").isRefused(1, "lojban_tagger index 2")  # version
    check readIndex("notes\tdatni\n").isRefused(1, "notes\tdatni")  # entity before header
    check readIndex(" " & HEADER & "\n").isRefused(1, " " & HEADER)  # header read exactly


  test "reader refuses bad line by its number, ending in text read":
    let opening = HEADER & "\nalpha\tdatni\n"
    check readIndex(opening & "beta datni\n").isRefused(3, "beta datni")  # tab missing
    check readIndex(opening & "beta\tdatni\tvreji\n").isRefused(3, "beta\tdatni\tvreji")  # 2 tabs
    check readIndex(opening & "\tdatni\n").isRefused(3, "\tdatni")  # empty name
    check readIndex(opening & "\n\nbeta\tdatni\n").isRefused(3, "")  # blank line inside
    check readIndex(opening & "\n\n").isRefused(3, "")  # blank line before final line feed
    check readIndex(opening & "aaa\tdatni\n").isRefused(3, "aaa")  # names unsorted
    check readIndex(opening & "alpha\tvreji\n").isRefused(3, "alpha")  # names repeated
    check readIndex(opening & "beta\tdatni+qqqqq\n").isRefused(3, "datni+qqqqq")  # no gismu
    check readIndex(opening & "beta\tbi\n").isRefused(3, "bi")  # cmavo is no gismu of tag
    check readIndex(opening & "beta\tdatnyvei\n").isRefused(3, "datnyvei")  # lujvo is no tanru
    check readIndex(opening & "beta\tdatni+\n").isRefused(3, "datni+")  # empty part
    check readIndex(opening & "beta\t\n").isRefused(3, "beta")  # entity with no tag
    check readIndex(opening & "beta\t   \n").isRefused(3, "beta")  # spaces hold no tag
    randomize(SEED)
    let pool = poolSamples()
    for sample in served(pool):
      let
        lines = sample.index.toText.splitLines
        at = 1 + sample.pick mod lines.high  # before any entity line, or before final line feed
        text = (lines[0..<at] & sample.bad & lines[at .. ^1]).join("\n")
      check readIndex(text).isRefused(at + 1, sample.bad)  # first bad line named, counted from 1


  test "name is any text but empty, tab, carriage return or line feed":
    check not isNameValid("")  # empty
    for character in '\0'..'\255':  # every byte, exhaustive
      let is_forbidden = character in {'\t', '\r', '\n'}
      check isNameValid($character) == not is_forbidden  # forbidden byte alone
      check isNameValid("a" & character & "b") == not is_forbidden  # forbidden byte inside
    for name in ["notes/plan.md", "https://lojban.org/?q=1", " ", "é", "datni vreji"]:
      check isNameValid(name)  # path, URL, title: any other text
