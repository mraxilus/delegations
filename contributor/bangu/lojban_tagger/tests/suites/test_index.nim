## Hold index of `index.nim` to its laws: text written reads back as index it came from, changes
##   keep names sorted and distinct, and reader refuses bad line by its number and its text.
##   CLL covers no index, so suite is `Internal:`, tests named by behaviour (Article IX.10).
##   Random indexes are built through `addTags` alone, so corpus holds what changes make. Names
##     are spelled from five pieces, space, `/` and `é` among them, so names collide and share
##     prefixes often; tags draw one to three gismu from every gismu of list (Article IX.3).
##   Corpus never holds name of more than four pieces, or entity of more than three tags.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[options, random, sequtils, strutils, unittest]

import ../../src/lojban_tagger/[dictionary, index, tags]
import ../../src/lojban_tagger/lists/gismu


const
  SEED = 1997  ## Seed of every random draw, year of CLL first edition.
  SAMPLES = 400  ## Random indexes each law is checked over.
  SAMPLES_FLOOR = 200  ## Fewest samples guard must pass, so guard rejecting most fails.
  CHANGES = 40  ## Changes in each random walk of changes.
  PIECES_NAME = ["a", "b", " ", "/", "é"]  ## Pieces random name is spelled from.
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



suite "Internal: Index":
  test "text written reads back as index it came from":
    randomize(SEED)
    for _ in 1..SAMPLES:
      let
        index = indexRandom()
        loaded = index.toText.readIndex
      check loaded.is_loaded  # writer emits only what reader accepts
      if not loaded.is_loaded: continue
      check loaded.index == index  # round trip, text to index
      check loaded.index.toText == index.toText  # round trip, index to text
    check readIndex(HEADER & "\n").index.entities.len == 0  # empty index is header alone
    check readIndex(HEADER).is_loaded  # final line feed optional
    let unfinished = readIndex(HEADER & "\nnotes\tdatni")
    check unfinished.is_loaded and unfinished.index.names == @["notes"]  # final line feed optional
    let repeated = readIndex(HEADER & "\nnotes\tdatni datni")
    check repeated.is_loaded and repeated.index.entities[0].tags.len == 1  # tags distinct on read


  test "adding tags twice changes nothing adding once did not":
    randomize(SEED)
    for _ in 1..SAMPLES:
      let (before, name, tags) = (indexRandom(), nameRandom(), tagsRandom())
      var once, twice, doubled = before
      once.addTags(name, tags)
      twice.addTags(name, tags)
      twice.addTags(name, tags)
      doubled.addTags(name, tags & tags)
      check twice == once  # idempotence
      check doubled == once  # tag given twice in one call is added once
      check once.entity(name).isSome  # entity is made where index holds none
      for tag in tags:
        check tag in once.entity(name).get.tags  # every tag given is held


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
    var passed = 0
    for _ in 1..SAMPLES:
      let (before, name, tags) = (indexRandom(), nameRandom(), tagsRandom())
      if before.entity(name).isSome: continue
      inc passed
      var after = before
      after.addTags(name, tags)
      after.removeTags(name, tags)
      check after == before  # inverse on fresh entity
    check passed >= SAMPLES_FLOOR  # guard leaves enough fresh names


  test "names stay sorted and distinct, tags distinct, after any changes":
    randomize(SEED)
    for _ in 1 .. SAMPLES div 10:
      var index = indexRandom()
      for _ in 1..CHANGES:
        let (name, tags) = (nameRandom(), tagsRandom())
        if rand(1) == 0: index.addTags(name, tags)
        else: index.removeTags(name, tags)
        check index.isOrdered  # names sorted and distinct
        for entity in index.entities:
          check entity.tags.len > 0  # entity holds at least one tag
          check entity.tags.deduplicate == entity.tags  # tags distinct, order kept
        check index.toText.readIndex.is_loaded  # text written after any change reads back


  test "entity left with no tag leaves index":
    randomize(SEED)
    for _ in 1..SAMPLES:
      var index = indexRandom()
      let (name, tag) = (nameRandom(), tagRandom())
      index.addTags(name, [tag])
      let held = index.entity(name).get.tags
      index.removeTags(name, held)
      check index.entity(name).isNone  # last tag removed takes entity with it
      check name notin index.names  # no entity holds name
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
    for _ in 1..SAMPLES:
      let
        index = indexRandom()
        lines = index.toText.splitLines
        at = rand(1..lines.high)  # before any entity line, or before final line feed
        bad = sample(["beta datni", "beta\tdatni\tvreji", "", "\tdatni"])
        text = (lines[0..<at] & bad & lines[at .. ^1]).join("\n")
      check readIndex(text).isRefused(at + 1, bad)  # first bad line named, counted from one


  test "name is any text but empty, tab, carriage return or line feed":
    check not isNameValid("")  # empty
    for character in '\0'..'\255':  # every byte, exhaustive
      let is_forbidden = character in {'\t', '\r', '\n'}
      check isNameValid($character) == not is_forbidden  # forbidden byte alone
      check isNameValid("a" & character & "b") == not is_forbidden  # forbidden byte inside
    for name in ["notes/plan.md", "https://lojban.org/?q=1", " ", "é", "datni vreji"]:
      check isNameValid(name)  # path, URL, title: any other text
