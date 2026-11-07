## Answer every verb of this project: `nim r tools/build.nim <command>`, from project directory.
##
##   |-----------|--------------------------------------------------------------------------|
##   | Command   | Effect                                                                   |
##   |-----------|--------------------------------------------------------------------------|
##   | lists     | read `gismu.txt` and `cmavo.txt` lojban-common installs, check each      |
##   |           | digest against its pin, and write both typed modules under `src/`        |
##   | head      | read `gismu.txt`, `lujvo.txt` and `cmavo.txt` again, compare each digest |
##   |           | with its pin, and both rendered modules with what is committed; exit 1   |
##   |           | where any differs, i.e. Debian moved list                                |
##   | cll       | read saved pages of CLL 1.1 from directory named after verb, check their |
##   |           | digest against its pin, and write examples and notice under `tests/cll/` |
##   | tatoeba   | read export of Tatoeba named after verb, check its digest against its    |
##   |           | pin, write fixed sample and notice under `tests/sample_tatoeba/`, and    |
##   |           | print count of each verdict over whole export                            |
##   | wikipedia | read answers of API of lojban Wikipedia from directory named after verb, |
##   |           | check their digest against its pin, and write articles and notice under  |
##   |           | `tests/articles_wikipedia/`                                              |
##   | translations | fetch Alice and Oz into `build/translations/`, check each digest     |
##   |           | against its pin, and print count of each verdict of their paragraphs     |
##   | system    | print packages verbs and suites need, one per line                       |
##   |-----------|--------------------------------------------------------------------------|
##   Exit: 0 done, 1 command failed or lists differ, 2 usage error.
##
##   Sibling `lojban_tagger/tools/build.nim` holds earlier copy of `lists` and `head`, which
##     render lujvo list too, until #809 (II.9).
##   `head` is verb CONTRIBUTOR.md gives check against outside reference that moves: package
##     can carry new list with no commit here, and no merge waits on it. It reads `lujvo.txt`
##     for digest alone, since suites read it as outside text and render nothing of it.
##   Rejected: reading lists at compile time from package directory, which would make every
##     build need package; committed lists serve every build, and `head` watches upstream.
##   Cost: driver runs from project directory, since every path here is relative to it.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[algorithm, options, os, sequtils, tables]

import ./[cll, lists, tatoeba, translations, wikipedia]


const
  USAGE = "Usage: nim r tools/build.nim <lists|head|system|translations>\n" &
      "       nim r tools/build.nim cll <directory>\n" &
      "       nim r tools/build.nim tatoeba <export>\n" &
      "       nim r tools/build.nim wikipedia <directory>\n"
    ## Text printed on usage error.
  SYSTEM = [
    ("lojban-common", "word lists of Logical Language Group, read by `lists`, `head` and suites"),
    ("coreutils", "`sha256sum`, which `lists`, `head` and four verbs of texts check digest with"),
    ("curl", "fetcher of pages, which verb `translations` fetches Alice and Oz with"),
  ]
    ## Packages verbs need, each with reason (Article II.8); `system` prints names alone.



#[ Verbs ]#

proc refuseDigests(sources: openArray[(string, string, string)], module = "lists.nim"): int =
  ## Report each source whose digest left its pin, given as name, digest and pin; count reports.
  for (name, digest, pin) in sources:
    if digest == pin: continue
    stderr.writeLine "Source moved from its pin in `tools/" & module & "`; read diff, then " &
        "move pin; got `" & digest & "` for `" & name & "`."
    inc result


proc writeLists(): int =
  ## Write both modules where both digests match their pins.
  let
    gismu = readSource("gismu.txt")
    cmavo = readSource("cmavo.txt")
  if refuseDigests([
    ("gismu.txt", gismu.digest, DIGEST_GISMU),
    ("cmavo.txt", cmavo.digest, DIGEST_CMAVO),
  ]) > 0:
    return 1
  createDir(PATH_GISMU.parentDir)
  writeFile(PATH_GISMU, toModuleGismu(gismu.text.toEntriesGismu, gismu.digest))
  writeFile(PATH_CMAVO, toModuleCmavo(cmavo.text.toEntriesCmavo, cmavo.digest))
  echo PATH_GISMU
  echo PATH_CMAVO


proc compareLists(): int =
  ## Compare each digest, and both rendered modules with committed ones; 1 where any differs.
  let
    gismu = readSource("gismu.txt")
    lujvo = readSource("lujvo.txt")
    cmavo = readSource("cmavo.txt")
    rendered = [
      (PATH_GISMU, toModuleGismu(gismu.text.toEntriesGismu, gismu.digest)),
      (PATH_CMAVO, toModuleCmavo(cmavo.text.toEntriesCmavo, cmavo.digest)),
    ]
  var count_differing = refuseDigests([
    ("gismu.txt", gismu.digest, DIGEST_GISMU),
    ("lujvo.txt", lujvo.digest, DIGEST_LUJVO),
    ("cmavo.txt", cmavo.digest, DIGEST_CMAVO),
  ])
  for (path, text) in rendered:
    if fileExists(path) and readFile(path) == text: continue
    stderr.writeLine "Committed list differs from list rendered again; run `lists`; got `" &
        path & "`."
    inc count_differing
  if count_differing > 0: 1 else: 0


proc writeCll(directory: string): int =
  ## Write examples and notice of CLL 1.1 where digest of pages read matches its pin.
  let book = readBook(directory)
  if refuseDigests([("pages of CLL 1.1", book.digest, DIGEST_CLL)], "cll.nim") > 0: return 1
  createDir(PATH_EXAMPLES.parentDir)
  writeFile(PATH_EXAMPLES, book.toModuleExamples)
  writeFile(PATH_NOTICE, book.toNotice)
  echo PATH_EXAMPLES
  echo PATH_NOTICE


proc writeTatoeba(path: string): int =
  ## Write fixed sample of Tatoeba and its notice where digest of export matches its pin, and
  ##   print count of each verdict over whole export.
  let (sentences, digest) = readSentences(path)
  if refuseDigests([("export of Tatoeba", digest, DIGEST_TATOEBA)], "tatoeba.nim") > 0: return 1
  let sample = sentences.toSample(digest)
  createDir(PATH_SENTENCES.parentDir)
  writeFile(PATH_SENTENCES, sample.toModuleSentences)
  writeFile(PATH_NOTICE_TATOEBA, sample.toNotice)
  echo PATH_SENTENCES
  echo PATH_NOTICE_TATOEBA
  echo "sentences ", sample.count_sentences, ", sample ", sample.sentences.len, ", features ",
      sample.count_features
  var verdicts: seq[(int, string)]
  for verdict, count in sample.counts: verdicts.add (-count, verdict)
  for (count, verdict) in verdicts.sorted:
    echo -count, "\t", (if verdict.len == 0: "read" else: verdict)


proc writeWikipedia(directory: string): int =
  ## Write articles of Wikipedia and their notice where digest of answers matches its pin.
  let
    articles = readArticles(directory)
    digests = [("answers of Wikipedia", articles.digest, DIGEST_WIKIPEDIA)]
  if refuseDigests(digests, "wikipedia.nim") > 0: return 1
  createDir(PATH_ARTICLES.parentDir)
  writeFile(PATH_ARTICLES, articles.toModuleArticles)
  writeFile(PATH_NOTICE_WIKIPEDIA, articles.toNotice)
  echo PATH_ARTICLES
  echo PATH_NOTICE_WIKIPEDIA
  for article in articles.articles:
    echo article.title, ": paragraphs ", article.paragraphs.len, ", read ",
        article.paragraphs.countIt(it.verdict.len == 0)


proc writeTranslations(): int =
  ## Fetch each translation, check its digest, and print count of each verdict of its paragraphs.
  let root = getCurrentDir()
  for translation in TRANSLATIONS:
    let digest = translation.fetchTranslation(root)
    if refuseDigests([(translation.name, digest, translation.digest)], "translations.nim") > 0:
      result = 1
      continue
    let paragraphs = translation.readTranslation(root).get
    var counts: CountTable[string]
    for paragraph in paragraphs: counts.inc paragraph.reading.verdict
    echo translation.name, ": paragraphs ", paragraphs.len, ", read ", counts[""]
    var verdicts: seq[(int, string)]
    for verdict, count in counts:
      if verdict.len > 0: verdicts.add (-count, verdict)
    for (count, verdict) in verdicts.sorted: echo -count, "\t", verdict


proc main(): int =
  ## Dispatch command named as first argument; `cll`, `tatoeba` and `wikipedia` take path second.
  let arguments = commandLineParams()
  if arguments.len == 2 and arguments[0] == "cll": return writeCll(arguments[1])
  if arguments.len == 2 and arguments[0] == "tatoeba": return writeTatoeba(arguments[1])
  if arguments.len == 2 and arguments[0] == "wikipedia": return writeWikipedia(arguments[1])
  if arguments.len != 1:
    stderr.write USAGE
    return 2
  case arguments[0]
  of "lists": writeLists()
  of "head": compareLists()
  of "translations": writeTranslations()
  of "system":
    for (name, _) in SYSTEM: echo name
    0
  else:
    stderr.write USAGE
    2


when isMainModule:
  quit main()
