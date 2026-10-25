## Hold each verb of `commands.nim` to what its header promises: what `run` prints, reports, exits
##   with, and does to index, for `tag`, `untag`, `find`, `show`, `read` and every usage error.
##   CLL covers no verb, so suite is `Internal:`, tests named by behaviour (Article IX.10).
##   Verbs are driven through `run` alone, with index built in memory; `test_tagger.nim` drives
##     built binary for wiring to file and streams (Article IX.5).
##   Random argument lists draw verb, name and word from small vocabularies holding refused,
##     misspelt and usage-breaking choices, so every exit code is reached (Article IX.3).
##   Samples are drawn into pools allocated once, after one seeding per test, and served by
##     `served`.
##   Corpus holds no argument list of more than four arguments after verb.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[options, random, sequtils, strutils, unittest]

import ../../src/lojban_tagger/[commands, dictionary, index, tags]


const
  SEED = 1997  ## Seed of every random draw, year of CLL first edition.
  SAMPLES = 800  ## Random argument lists, and random queries, each law is checked over.
  FLOOR_TAGGING = 160  ## Fewest argument lists done tagging; 215 of `SAMPLES` read at `SEED`.
  VERBS = ["tag", "untag", "find", "show", "read", "frob", "TAG"]  ## Verbs random lists draw.
  VERBS_TAGGING = ["tag", "untag"]  ## Verbs that change index, drawn half time.
  NAMES = ["cats", "notes", "photo", "missing"]  ## Names random lists draw.
  NAMES_REFUSED = ["a\tb", ""]  ## Names usage refuses, drawn one time in eight.
  WORDS = ["datni", "vreji", "datnyvei", "datnyvreji", "mlatu"]
    ## Words random lists draw: tags, two spellings of one tag among them.
  WORDS_REFUSED = ["bi", "qqqqq", "file", "qwzx"]
    ## Words reader refuses as tag, drawn one time in eight; English and unknown among them.
  REFUSED = [
    (Refusal.Empty, " "),
    (Refusal.Letter, "qqqqq"),
    (Refusal.Cmavo, "bi"),
    (Refusal.Unlisted, "datna"),
    (Refusal.Rafsi, "belvreji"),
    (Refusal.Ambiguous, "brodyzba"),
    (Refusal.Hyphen, "zaizbasu"),
    (Refusal.Shape, "xyz"),
  ]
    ## Word reader refuses for each reason.
  TERMS = @WORDS & @WORDS_REFUSED & @["pixra", "gerku"]  ## Terms random queries draw.


func toIndex(rows: openArray[(string, seq[string])]): Index =
  ## Build index tagging each name with each word, read as tag.
  for (name, words) in rows: result.addTags(name, words.mapIt(it.readTag.tag))


func definition(text: string): string =
  ## Read keyword and definition of gismu as `read` prints them.
  let entry = text.word.get.entry
  entry.keyword & "; " & entry.definition


func indexSample(): Index =
  ## Build index of three entities: lujvo alone, gismu alone, two gismu tags.
  toIndex([("notes", @["datnyvei"]), ("photo", @["pixra"]), ("cats", @["mlatu", "datni"])])


proc argumentsRandom(): seq[string] =
  ## Draw verb, then zero to four arguments: name first, then words; tagging verb is drawn half
  ##   time, and refused name or word one time in eight, so verb done tagging is common.
  result.add (if rand(1) == 0: VERBS_TAGGING.sample else: VERBS.sample)
  for i in 1..rand(0..4):
    let is_refused = rand(7) == 0
    if i == 1: result.add (if is_refused: NAMES_REFUSED.sample else: NAMES.sample)
    else: result.add (if is_refused: WORDS_REFUSED.sample else: WORDS.sample)


proc poolArguments(): seq[seq[string]] =
  ## Draw `SAMPLES` random argument lists into pool allocated once; caller seeds first.
  result = newSeqOfCap[seq[string]](SAMPLES)
  for _ in 1..SAMPLES: result.add argumentsRandom()


proc poolQueries(): seq[seq[string]] =
  ## Draw `SAMPLES` queries of one or two terms of `TERMS` into pool allocated once; caller
  ##   seeds first.
  result = newSeqOfCap[seq[string]](SAMPLES)
  for _ in 1..SAMPLES:
    result.add @[TERMS.sample] & (if rand(1) == 0: @[TERMS.sample] else: @[])


iterator served[T](pool: seq[T]): lent T =
  ## Serve each sample of pool in order, with no copy.
  for i in 0..<pool.len: yield pool[i]



suite "Internal: Commands":
  test "tag adds each tag, and prints entity line of name and tags":
    let first = run(["tag", "notes", "datni", "vreji"], Index())
    check first.code == 0 and first.report == ""  # done, nothing to report
    check first.output == "notes\tdatni vreji\n"  # name, tab, tags in order added
    check first.is_changed  # index changed, so caller writes it
    check first.index == toIndex([("notes", @["datni", "vreji"])])  # each tag added
    let second = run(["tag", "notes", "datnyvreji"], first.index)
    check second.output == "notes\tdatni vreji datnyvei\n"  # tag prints in preferred form
    check second.index.entity("notes").get.tags.len == 3  # lujvo is one tag, apart from gismu
    let again = run(["tag", "notes", "Datni", "datnyvei"], second.index)
    check again.code == 0 and not again.is_changed  # tags held already change nothing
    check again.output == second.output and again.index == second.index  # same line printed


  test "tag refuses every word where any one is no tag, naming each refusal":
    let
      before = indexSample()
      outcome = run(["tag", "notes", "datni", "qqqqq", "bi"], before)
    check outcome.code == 1 and outcome.output == ""  # refused, nothing printed
    check not outcome.is_changed and outcome.index == before  # all or nothing
    check outcome.report ==
        readTag("qqqqq").explain & "\n" & readTag("bi").explain & "\n"  # each refusal, in turn
    check outcome.report.splitLines[1] ==
        "Tag should end in gismu, as CLL 4.11 step 2 ends tanru; got cmavo `bi` in `bi`."  # cmavo
    var covered: set[Refusal]
    for (refusal, text) in REFUSED:
      let reading = readTag(text)
      check not reading.is_tag and reading.refusal == refusal  # sample refused for its reason
      if reading.is_tag: continue
      covered.incl refusal
      check reading.explain.endsWith("`" & reading.text & "`.")  # explain ends in text read
      check run(["tag", "notes", text], before).report == reading.explain & "\n"  # verb says it
    check covered == {Refusal.low..Refusal.high}  # every refusal, exhaustive


  test "untag removes each tag, and entity left with no tag leaves":
    let
      before = toIndex([("notes", @["datni", "vreji", "datnyvei"])])
      first = run(["untag", "notes", "datni", "datnyvreji"], before)
    check first.code == 0 and first.is_changed  # tags removed, lujvo by other spelling
    check first.output == "notes\tvreji\n"  # tag left printed
    let last = run(["untag", "notes", "vreji"], first.index)
    check last.code == 0 and last.is_changed  # last tag removed
    check last.output == "" and last.index.entity("notes").isNone  # entity leaves index
    let missing = run(["untag", "missing", "datni"], before)
    check missing.code == 0 and not missing.is_changed  # missing entity: nothing to remove
    check missing.output == "" and missing.index == before  # nothing printed, nothing changed
    let refused = run(["untag", "notes", "datni", "bi"], before)
    check refused.code == 1 and refused.index == before  # one refused word stops all


  test "find prints each entity satisfying every term, and reports each term":
    let
      index = indexSample()
      vreji = run(["find", "vreji"], index)
    check vreji.code == 0 and not vreji.is_changed  # found, index untouched
    check vreji.output == "notes\tdatnyvei\n"  # gismu finds lujvo holding it
    check vreji.report == "`vreji` reads as tag `vreji`.\n"  # term read as tag
    let datni = run(["find", "datni"], index)
    check datni.output == "cats\tmlatu datni\nnotes\tdatnyvei\n"  # every match, index order
    check run(["find", "datni", "mlatu"], index).output == "cats\tmlatu datni\n"  # conjunction
    let file = run(["find", "file"], index)
    check file.output == "notes\tdatnyvei\n"  # English leads to gismu of gloss
    check file.report.startsWith("`file` reads as English: datni+vreji (file")  # meaning named
    let none = run(["find", "gerku"], index)
    check none.code == 1 and none.output == ""  # nothing found exits 1, as `grep` does
    let unknown = run(["find", "qwzx"], index)
    check unknown.code == 1  # unknown term finds nothing
    check unknown.report == "`qwzx` reads as neither tag nor English of lists, so finds " &
        "nothing; " & readTag("qwzx").explain & "\n"  # report says why
    randomize(SEED)
    let pool = poolQueries()
    for terms in served(pool):
      let found = run(@["find"] & terms, index)
      var lines = ""
      for name in ["cats", "notes", "photo"]:
        if found.output.contains(name & "\t"): lines.add run(["show", name], index).output
      check found.output == lines  # each line found is line `show` prints for it
      check found.code == (if found.output.len > 0: 0 else: 1)  # exit follows output


  test "show prints every entity, or one, or refuses name index lacks":
    let
      index = indexSample()
      every = run(["show"], index)
    check every.code == 0 and not every.is_changed  # done, index untouched
    check every.output == "cats\tmlatu datni\nnotes\tdatnyvei\nphoto\tpixra\n"  # index order
    var lines = ""
    for entity in index.entities: lines.add run(["show", entity.name], index).output
    check every.output == lines  # every entity is each entity shown alone
    let missing = run(["show", "missing"], index)
    check missing.code == 1 and missing.output == ""  # name index lacks
    check missing.report == "Entity should be in index; got `missing`.\n"  # names it
    check run(["show"], Index()).output == "" and run(["show"], Index()).code == 0  # empty


  test "read explains rafsi, gismu, preferred form and English of each word":
    let datnyvei = run(["read", "datnyvei"], Index())
    check datnyvei.code == 0 and not datnyvei.is_changed  # explained, index untouched
    check datnyvei.output ==
        "`datnyvei`: tag `datni+vreji`, preferred form `datnyvei`, spelled `datny-vei`.\n" &
        "  datni: " & definition("datni") & "\n" &
        "  vreji: " & definition("vreji") & "\n"  # rafsi spelled, then each gismu
    let spelled = run(["read", "datnyvreji"], Index()).output.splitLines[0]
    check spelled == "`datnyvreji`: tag `datni+vreji`, preferred form `datnyvei`, " &
        "spelled `datny-vreji`."  # spelling as written, preferred form apart
    check run(["read", "datni"], Index()).output ==
        "`datni`: tag `datni`, preferred form `datni`.\n" &
        "  datni: " & definition("datni") & "\n"  # gismu alone spells no rafsi
    let refused = run(["read", "datni", "bi"], Index())
    check refused.code == 1  # any word refused exits 1
    check refused.output.endsWith(readTag("bi").explain & "\n")  # refusal explained in turn
    let file = run(["read", "file"], Index())
    check file.code == 1  # English is no tag
    let explained = readTag("file").explain & "\n`file` reads as English: "
    check file.output.startsWith(explained)  # refusal explained, then English it leads to


  test "usage error exits 2, prints usage, and changes nothing":
    let before = indexSample()
    for arguments in [
      newSeq[string](),
      @["frob"],
      @["TAG", "notes", "datni"],
      @["tag"],
      @["tag", "notes"],
      @["untag", "notes"],
      @["tag", "a\tb", "datni"],
      @["tag", "a\nb", "datni"],
      @["tag", "", "datni"],
      @["find"],
      @["read"],
      @["show", "cats", "notes"],
    ]:
      let outcome = run(arguments, before)
      check outcome.code == 2 and outcome.report == USAGE  # usage error, usage printed
      check outcome.output == "" and not outcome.is_changed  # nothing printed or written
      check outcome.index == before  # index untouched


  test "verb changes index only where it says so, and only `tag` and `untag` do":
    randomize(SEED)
    let pool = poolArguments()
    var passed = 0
    for arguments in served(pool):
      let
        before = indexSample()
        outcome = run(arguments, before)
      check outcome.code in [0, 1, 2]  # exit codes of header alone
      check outcome.is_changed == (outcome.index != before)  # flag tells caller truth
      check outcome.index.toText.readIndex.is_loaded  # index after verb stays writable
      if outcome.code == 2:
        check outcome.report == USAGE and not outcome.is_changed  # usage error writes nothing
      if arguments[0] notin ["tag", "untag"] or outcome.code != 0:
        check not outcome.is_changed  # only verb done tagging changes index
      if outcome.code != 0 or arguments[0] notin ["tag", "untag"]: continue
      inc passed
      let again = run(arguments, outcome.index)
      check not again.is_changed and again.output == outcome.output  # idempotent verb
    check passed >= FLOOR_TAGGING  # guard leaves enough tagging done
