## spuda ro minde pe le vi se gunka
##   .i le minde cu se pilno sepi'o `nim r tools/build.nim <command>` bu'u le vasru pe le vi se
##     gunka
##
##   |----------------|----------------------------------------------------------------------------|
##   | lo minde       | lo jalge                                                                   |
##   |----------------|----------------------------------------------------------------------------|
##   | `lists`        | tcidu `gismu.txt` .e `cmavo.txt` vu'o noi `lojban-common` cu punji ke'a    |
##   |                | .i karbi ro sinxa namcu lo stodi pe le sinxa namcu                         |
##   |                | .i ciska le re datnyvei poi ponse lo klesi ku'o ne'i `src/`                |
##   | `head`         | rapli tcidu `gismu.txt` .e `lujvo.txt` .e `cmavo.txt`                      |
##   |                | .i karbi ro sinxa namcu lo stodi pe le sinxa namcu                         |
##   |                | .i karbi le re datnyvei poi se zbasu ku'o le se punji                      |
##   |                | .i sisti sepi'o li pa va'o lo nu su'o da cu frica                          |
##   |                | .i le nu frica cu sinxa lo nu la'o gy. Debian .gy. pu galfi lo liste       |
##   | `cll`          | tcidu lo papri be la'o gy. CLL 1.1 .gy. noi se ralte ne'i pa vasru         |
##   |                | .i lo cmene be le vasru cu se lidne le minde                               |
##   |                | .i karbi lo sinxa namcu pe le papri lo stodi pe le sinxa namcu             |
##   |                | .i ciska lo mupli .e lo notci ne'i `tests/cll/`                            |
##   | `tatoeba`      | tcidu lo vreji pe la'o gy. Tatoeba .gy.                                    |
##   |                | .i lo cmene be le vreji cu se lidne le minde                               |
##   |                | .i karbi lo sinxa namcu pe le vreji lo stodi pe le sinxa namcu             |
##   |                | .i ciska le stodi mupli .e lo notci ne'i `tests/sample_tatoeba/`           |
##   |                | .i kancu lo jufra pe le mulno vreji ja'i ro se jdice gi'e cusku lo namcu   |
##   | `wikipedia`    | tcidu lo te spuda be fi la'o gy. API .gy. pe la'o gy. Wikipedia .gy.       |
##   |                | .i la'o gy. Wikipedia .gy. cu se bangu la lojban.                          |
##   |                | .i le te spuda cu zvati pa vasru                                           |
##   |                | .i lo cmene be le vasru cu se lidne le minde                               |
##   |                | .i karbi lo sinxa namcu pe le te spuda lo stodi pe le sinxa namcu          |
##   |                | .i ciska lo prosa .e lo notci ne'i `tests/articles_wikipedia/`             |
##   | `translations` | cpacu la'o gy. Alice .gy. .e la'o gy. Oz .gy.                              |
##   |                | .i punji le re prosa `build/translations/`                                 |
##   |                | .i karbi ro sinxa namcu lo stodi pe le sinxa namcu                         |
##   |                | .i kancu lo pagbu be le re prosa ja'i ro se jdice gi'e cusku lo namcu      |
##   | `javascript`   | fanva le mulno genturfa'i fi la'o gy. JavaScript .gy.                      |
##   |                | .i `src/javascript/bridge.nim` cu dunda le genturfa'i lo drata samtci      |
##   |                | .i le xe fanva cu zvati `build/lojban_parser.js`                           |
##   |                | .i cusku lo judri .e lo ni le datnyvei cu barda                            |
##   | `page`         | zbasu le papri pe lo jmive se ciska fi `pages/live.html` ne'i `build/`     |
##   |                | .i le papri cu vasru lo lerfu tarmi poi lo sorcu cu sabji ke'a             |
##   |                | .i le papri cu vasru le samtci ne'i le mintu datnyvei                      |
##   |                | .i `tools/page.nim` cu zbasu le papri                                      |
##   | `drive`        | zbasu le samtci gi'e jitro ro cipra pe `tests/browser/`                    |
##   |                | .i ro le cipra cu fasnu ne'i la'o gy. headless Chromium .gy.               |
##   |                | .i crepu le jitro papri poi `koch drive` cu ciska ke'a                     |
##   |                | .i `tools/browser.nim` cu gasnu le vi minde                                |
##   | `system`       | cusku lo bakfu poi lo minde .e lo cipra cu nitcu ke'a                      |
##   |                | .i ro linji cu cusku pa bakfu                                              |
##   |----------------|----------------------------------------------------------------------------|
## ni'o le jitro samtci cu sisti sepi'o li no va'o lo nu le minde cu mulno
##   .i le jitro samtci cu sisti sepi'o li pa va'o lo nu le minde cu fliba .a lo nu lo liste cu
##     frica .a lo nu pa cipra cu fliba
##   .i le jitro samtci cu sisti sepi'o li re va'o lo nu lo nu pilno cu srera
##
## ni'o lo minde po'u `lists` .e `head` pe `lojban_tagger/tools/build.nim` cu tunba le vi minde gi'e
##   pilno le mintu tadji ne'i lo liste pe `lojban_tagger` gi'e tcidu le mintu krasi ja'i le mintu
##   stodi to `tools/lists.nim` toi
##   .i no jitro samtci cu dunda pa minde lo drata samtci
##   .i se ki'u bo le tadji cu zvati ro le re jitro samtci to `II.9` toi
##   .i va'o lo nu le drata na se cipra kei lo nu cikre pa le re jitro samtci cu na mulno
##   .i `CONTRIBUTOR.md` cu cusku lo minde po'u `head` tezu'e lo nu cipra lo bartu se sitna poi
##     cenba
##   .i lo bakfu cu ka'e bevri lo cnino liste ca lo nu no da cu se punji vi
##   .i no nu jmina cu denpa lo minde po'u `head`
##   .i lo minde po'u `head` cu tcidu `lujvo.txt` tezu'e lo sinxa namcu po'o
##   .i ki'u bo lo cipra cu tcidu `lujvo.txt` ta'i lo drata se ciska gi'e zbasu no datnyvei fi
##     `lujvo.txt`
##   .i se to'e cuxna fa lo nu tcidu lo liste fi le vasru pe le bakfu ca lo nu fanva kei noi rinka
##     lo nu ro nu zbasu cu nitcu le bakfu
##   .i lo liste poi se punji cu sabji ro nu zbasu
##   .i lo minde po'u `head` cu zgana lo krasi be le liste
##   .i jdima fa lo nu le jitro samtci cu se pilno bu'u le vasru pe le vi se gunka
##   .i ki'u bo ro judri vi cu se krasi le vasru

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[algorithm, options, os, sequtils, tables]

import ./[browser, cll, lists, page, tatoeba, translations, wikipedia]


const
  USAGE = "Usage: nim r tools/build.nim <lists|head|javascript|page|drive|system|translations>\n" &
      "       nim r tools/build.nim cll <directory>\n" &
      "       nim r tools/build.nim tatoeba <export>\n" &
      "       nim r tools/build.nim wikipedia <directory>\n"
    ## le se ciska poi se cusku va'o lo nu lo nu pilno cu srera
  SYSTEM = [
    ("lojban-common", "word lists of Logical Language Group, read by `lists`, `head` and suites"),
    ("coreutils",
      "`sha256sum`, which `lists`, `head` and four verbs of texts check digest with, and " &
      "`sleep`, which fake of Chromium of `test_drive.nim` blocks in"),
    ("curl",
      "fetcher of pages, which verb `translations` fetches Alice and Oz with, and fake of " &
      "Chromium of `test_drive.nim` reports end of run with"),
    ("unzip", "unpacker of archive of Chromium, which store serves and verb `drive` drives"),
    ("libbrotli1", "decoder of `woff2`, which `koch drive` reads font faces of page through"),
  ]
    ## lo bakfu poi lo minde cu nitcu ke'a
    ##   .i ro le bakfu cu kansa lo krinu to `Article II.8` toi
    ##   .i lo minde po'u `system` cu cusku lo cmene po'o



#[ ni'o ni'o ni'o lo minde ]#

proc refuseDigests(sources: openArray[(string, string, string)], module = "lists.nim"): int =
  ## cusku ro krasi poi lo sinxa namcu pe ke'a cu cliva lo stodi pe ke'a
  ##   .i ro krasi cu se dunda ta'i lo cmene .e lo sinxa namcu .e lo stodi
  ##   .i kancu lo se cusku
  for (name, digest, pin) in sources:
    if digest == pin: continue
    stderr.writeLine "Source moved from its pin in `tools/" & module & "`; read diff, then " &
        "move pin; got `" & digest & "` for `" & name & "`."
    inc result


proc writeLists(): int =
  ## ciska le re datnyvei va'o lo nu ro le re sinxa namcu cu mapti lo stodi pe vo'a
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
  ## karbi ro sinxa namcu lo stodi pe le sinxa namcu
  ##   .i karbi le re datnyvei poi se zbasu ku'o le re datnyvei poi se punji
  ##   .i jarco li pa va'o lo nu su'o da cu frica
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
  ## ciska lo mupli .e lo notci vu'o pe la'o gy. CLL 1.1 .gy. va'o lo nu lo sinxa namcu pe le papri
  ##   poi se tcidu cu mapti lo stodi pe vo'a
  let book = readBook(directory)
  if refuseDigests([("pages of CLL 1.1", book.digest, DIGEST_CLL)], "cll.nim") > 0: return 1
  createDir(PATH_EXAMPLES.parentDir)
  writeFile(PATH_EXAMPLES, book.toModuleExamples)
  writeFile(PATH_NOTICE, book.toNotice)
  echo PATH_EXAMPLES
  echo PATH_NOTICE


proc writeTatoeba(path: string): int =
  ## ciska le stodi mupli pe la'o gy. Tatoeba .gy. ge'u .e lo notci pe le mupli va'o lo nu lo sinxa
  ##   namcu pe le vreji cu mapti lo stodi pe vo'a
  ##   .i kancu lo jufra pe le mulno vreji ja'i ro se jdice gi'e cusku lo namcu
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
  ## ciska lo prosa pe la'o gy. Wikipedia .gy. ge'u .e lo notci pe le prosa va'o lo nu lo sinxa
  ##   namcu pe le te spuda cu mapti lo stodi pe vo'a
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
  ## cpacu ro xe fanva gi'e karbi lo sinxa namcu pe le xe fanva lo stodi pe le sinxa namcu
  ##   .i kancu lo pagbu be le xe fanva ja'i ro se jdice gi'e cusku lo namcu
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


proc writeJavascript(): int =
  ## fanva `PATH_BRIDGE` jo'u le mulno genturfa'i fu `PATH_SCRIPT` gi'e cusku lo judri .e lo ni le
  ##   datnyvei cu barda
  ##   .i le fanva cu du le fanva poi pu fanva le vi jitro samtci
  ##   .i le jitro samtci no roi pilno lo drata fanva po'u `nim` poi `PATH` cu vasru ke'a
  ##   .i `-d:release` cu ralte ro cipra gi'e vimcu lo vreji be lo nu pilno lo fancu kei be'o .e lo
  ##     vreji be lo linji to `config/nim.cfg` pe le se stodi fanva toi
  ##   .i lo cipra pe `tests/browser/` cu se fanva sepi'o `-d:release` ji'a
  ##   .i se ki'u bo le cipra cu cipra le se zbasu poi se benji lo pilno
  ##   .i se to'e cuxna fa `-d:danger` noi vimcu ro cipra be lo korbi .e lo se kuspe le se zbasu poi
  ##     lo pilno cu pilno ke'a
  if compileJs(PATH_BRIDGE, PATH_SCRIPT) != 0: return 1
  echo PATH_SCRIPT
  echo "bytes ", getFileSize(PATH_SCRIPT)


proc main(): int =
  ## gasnu le minde poi le pamoi sumti cu cmene ke'a
  ##   .i lo minde po'u `cll` .e `tatoeba` .e `wikipedia` cu cpacu lo judri ta'i le remoi sumti
  ##   .i le pagbu poi cuxna lo minde cu se krasi `case paramStr(1)` ta'i lo nu la'o gy. koch .gy.
  ##     cu tcidu le pagbu
  ##   .i la'o gy. koch .gy. cu cpacu `drive` .e `head` .e `system` le pagbu po'o to
  ##     `test_driver.nim` toi
  if paramCount() == 2 and paramStr(1) == "cll": return writeCll(paramStr(2))
  if paramCount() == 2 and paramStr(1) == "tatoeba": return writeTatoeba(paramStr(2))
  if paramCount() == 2 and paramStr(1) == "wikipedia": return writeWikipedia(paramStr(2))
  if paramCount() != 1:
    stderr.write USAGE
    return 2
  case paramStr(1)
  of "lists": writeLists()
  of "head": compareLists()
  of "translations": writeTranslations()
  of "javascript": writeJavascript()
  of "page": writePage()
  of "drive": runDrive()
  of "system":
    for (name, _) in SYSTEM: echo name
    0
  else:
    stderr.write USAGE
    2


when isMainModule:
  quit main()
