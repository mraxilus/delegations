## ciska lo claro'a pe `Wikipedia` pe la lojban. ta'i pa samtci datnyvei pe `Nim` zi'e poi ponse lo
##     klesi gi'e vasru lo seljdi be le genturfa'i bei ro ju'agri
##   .i `build.nim` pilno le vi datnyvei
##
## ni'o tcidu lo danfu pe `API` pe `Wikipedia`
##   .i le danfu cu selra'e ne'i pa datnyveiste
##   .i ro prosa cu ponse pa datnyvei
##   .i `QUERY` cpedu lo sapselci'a .e lo terga'i be le papri
##   .i ciska `tests/articles_wikipedia/articles.nim` .e `NOTICE.md` noi lamji `articles.nim`
##
## ni'o `Architect` jdice `D5 c` bu'u `#819`
##   .i pa datnyveiste pe `delegations` vasru lo claro'a poi seljva `CC BY-SA`
##   .i ro nu cipra cu tcidu le prosa
##   .i le datnyveiste cu vasru lo seljdi pe ro pagbu
##
## ni'o lo pagbu cu du lo ju'agri noi du pa linji pe lo sapselci'a
##   .i lo cmene be lo ckupaupau cu na se tcidu
##   .i se ki'u bo le cipra cu tcidu lo jonselci'a poi vasru su'o re jufra ku'o ta'i pa selci'a pe
##       `CLL 21.1`
##
## ni'o pa snina'u pe `SHA-256` stosni le danfu
##   .i le snina'u cu selzba fi lo selsku be `sha256sum` poi tcidu ro datnyvei ja'i lo porsi be lo
##       cmene
##   .i `cll.nim` stosni lo papri ta'i le mintu
##   .i le sapselci'a cu selkra le terga'i poi le danfu cu cusku lo namcu pe ke'a
##   .i le terga'i cu selstosni
##   .i ki'u bo lo ninterga'i cu galfi le snina'u
##
## ni'o lo seljdi cu du lo seldu'a be le genturfa'i ca lo nu ciska kei gi'e se tcidu ja'i
##     `tatoeba.nim`
##   .i le cipra cu fliba ca ro nu pa seljdi cu cenba
##
## ni'o jdima fa lo nu `JSON` se tcidu ne'i le vi datnyvei po'o
##   .i ki'u bo `API` pe `Wikipedia` spuda sepi'o `JSON`
##   .i no jgena pe `JSON` cliva le vi datnyvei to le pagbu poi selcme zoi gy. Data .gy. ne'i
##       `CONTRIBUTOR.md` toi

{.experimental: "strictFuncs".}

import std/[algorithm, json, os, osproc, sequtils, strutils]

import ./[literals, tatoeba]


type
  Paragraph* = object
    ## pa ju'agri pe pa prosa
    ##   .i le klesi cu vasru lo selci'a .e lo seljdi poi le genturfa'i cu dunda ke'a le ju'agri
    text*: string  ## pa linji pe lo sapselci'a ta'i lo nu le danfu cu dunda le linji
    verdict*: string
      ## lo nu to'e curmi kei jo'u lo javni vu'o poi le genturfa'i cu dunda ke'a
      ##   .i va'o lo nu le ju'agri cu se tcidu kei le seljdi cu kunti

  Article* = object  ## pa prosa ta'i lo nu le danfu cu dunda le prosa
    title*: string  ## lo cmene be le papri
    page*: int  ## lo namcu poi `Wikipedia` dunda ke'a le papri
    revision*: int  ## le terga'i poi le sapselci'a cu selkra ke'a
    paragraphs*: seq[Paragraph]  ## lo ju'agri ta'i lo porsi pe le prosa

  Articles* = object  ## ro prosa poi se tcidu ku'o .e lo snina'u be le danfu
    articles*: seq[Article]  ## lo prosa ta'i lo porsi be lo cmene be lo datnyvei
    digest*: string
      ## `SHA-256` pe lo selsku be `sha256sum` poi tcidu ro danfu ja'i lo porsi be lo cmene


const
  DIGEST_WIKIPEDIA* = "6bbe766025354f3dd9e7335ccd779cc868dbaddd9d8f2071eeb9680a0a3d0c21"
    ## `SHA-256` pe le danfu pe le ci papri poi lo namcu pe ke'a du li 4044 .a li 19 .a li
    ##     70
    ##   .i le danfu cu selra'e de'i `2026-11-06`
  URL_API* = "https://jbo.wikipedia.org/w/api.php"
    ## le judri be `API` poi le danfu cu selkra ke'a
  QUERY* = "action=query&prop=extracts|revisions&explaintext=1&rvprop=ids|timestamp&" &
      "format=json&formatversion=2&pageids="
    ## lo preti poi ro danfu cu spuda ke'a
    ##   .i lo namcu pe le papri cu se jmina fi le fanmo be le preti
  URL_LICENCE_WIKIPEDIA* = "https://creativecommons.org/licenses/by-sa/4.0/"
    ## le crujva pe lo selci'a pe `Wikipedia` pe la lojban.
  URL_PAGE* = "https://jbo.wikipedia.org/w/index.php?"
    ## le judri be lo papri
    ##   .i lo preti pe le papri cu se jmina fi le fanmo be le judri
  PATH_ARTICLES* = "tests/articles_wikipedia/articles.nim"
    ## lo datnyvei poi le prosa cu selci'a fi ke'a
  PATH_NOTICE_WIKIPEDIA* = "tests/articles_wikipedia/NOTICE.md"
    ## lo notci be le crujva
    ##   .i le notci cu lamji le samtci datnyvei
  MARK_HEADING = '='
    ## lo lerfu poi cfari lo cmene be lo ckupaupau pe lo sapselci'a
    ##   .i lo cmene be lo ckupaupau cu selvi'u



#[ ni'o ni'o ni'o lo nu tcidu ]#

proc readArticle(path: string): Article =
  ## tcidu pa danfu
  ##   .i le danfu cu vasru lo cmene .e lo namcu pe le papri ge'u .e lo terga'i .e ro ju'agri jo'u
  ##       le seljdi pe le ju'agri
  let node =
    try: parseFile(path)
    except JsonParsingError as error: quit "Answer is no JSON; got `" & error.msg & "`.", 1
  let page = node["query"]["pages"][0]
  result = Article(
    title: page["title"].getStr,
    page: page["pageid"].getInt,
    revision: page["revisions"][0]["revid"].getInt,
  )
  for line in page["extract"].getStr.splitLines:
    let text = line.strip
    if text.len == 0 or text[0] == MARK_HEADING: continue
    result.paragraphs.add Paragraph(text: text, verdict: text.reading.verdict)


proc readArticles*(directory: string): Articles =
  ## tcidu ro danfu pe lo datnyveiste ta'i lo porsi be lo cmene gi'e dunda lo snina'u be le danfu
  var names: seq[string]
  for kind, name in walkDir(directory, relative = true):
    if kind == pcFile and name.endsWith(".json"): names.add name
  if names.len == 0: quit "Answers are missing; save `" & URL_API & "`; got `" & directory & "`.", 1
  names.sort
  for name in names: result.articles.add readArticle(directory / name)
  let (output, code) = execCmdEx(
    "sha256sum " & names.mapIt(quoteShell(it)).join(" "), workingDir = directory
  )
  if code != 0: quit "Digest could not be read; got `" & output.strip & "`.", 1
  let (total, code_total) = execCmdEx("sha256sum", input = output)
  if code_total != 0: quit "Digest could not be read; got `" & total.strip & "`.", 1
  result.digest = total.splitWhitespace[0]



#[ ni'o ni'o ni'o lo nu ciska ]#

func linesParagraph(article: Article, index: int, paragraph: Paragraph): seq[string] =
  ## ciska pa ju'agri ta'i lo zbafancu
  ##   .i ro datnypau cu selci'a fi pa linji
  ##   .i le selci'a cu se fendi mu'i lo nu mapti
  result.add "    ParagraphWikipedia("
  result.add "      article: " & article.title.toLiteral & ","
  result.add "      index: " & $index & ","
  # ro pagbu cu mapti le pamoi linji
  #   .i lo selci'a pe le pamoi linji cu cfari bu'u lo stuzi poi traji lo ka darno
  let text = paragraph.text.linesLiteral(12, ",")
  result.add "      text: " & text[0].strip(trailing = false)
  for line in text[1 .. ^1]: result.add repeat(' ', 10) & line.strip(trailing = false)
  result.add "      verdict: " & paragraph.verdict.toLiteral & ","
  result.add "    ),"


func toModuleArticles*(articles: Articles): string =
  ## ciska le prosa ta'i lo selci'a be fi le datnyvei poi selra'e
  var lines = @[
    "## ralte lo claro'a pe `Wikipedia` pe la lojban. mu'i le cipra",
    "##   .i le vi datnyvei cu vasru lo seljdi be le genturfa'i bei ro ju'agri",
    "##   .i lo minde po'u `nim r tools/build.nim wikipedia <directory>` ciska le vi datnyvei " &
    "ra'i lo",
    "##       danfu pe `API` pe `Wikipedia`",
    "##   .i lo snina'u be le danfu cu du zoi ky. SHA-256 `" & articles.digest[0..31] & "`",
    "##       `" & articles.digest[32 .. ^1] & "` .ky.",
    "##   .i lo nu xanga'i le vi datnyvei cu na drani",
    "##   .i lo nu galfi le vi datnyvei cu nitcu lo nu rapypli le minde",
    "##   .i lo selci'a pe `Wikipedia` pe la lojban. seljva `CC BY-SA 4.0`",
    "##   .i `NOTICE.md` noi lamji le vi datnyvei cu cusku lo du'u le datnyveiste poi vasru le vi",
    "##       datnyvei cu seljva le crujva gi'e no roi seljva le crujva pe `delegations`",
    "",
    "{.experimental: \"strictFuncs\".}",
    "",
    "",
    "type",
    "  ArticleWikipedia* = object",
    "    ## pa prosa",
    "    ##   .i le klesi cu vasru lo cmene .e le terga'i poi le selci'a cu selkra ke'a",
    "    title* {.requiresInit.}: string  ## lo cmene be le papri",
    "    revision* {.requiresInit.}: int  ## le terga'i poi le sapselci'a cu selkra ke'a",
    "",
    "  ParagraphWikipedia* = object",
    "    ## pa ju'agri",
    "    ##   .i le klesi cu vasru lo prosa .e lo stuzi .e lo selci'a .e lo seljdi",
    "    article* {.requiresInit.}: string  ## lo cmene be le prosa poi vasru le ju'agri",
    "    index* {.requiresInit.}: int",
    "      ## lo namcu pe le ju'agri ne'i le prosa",
    "      ##   .i le namcu pe le pamoi ju'agri cu du li pa",
    "    text* {.requiresInit.}: string",
    "      ## pa linji pe lo sapselci'a ta'i lo nu le danfu cu dunda le linji",
    "    verdict* {.requiresInit.}: string",
    "      ## lo nu to'e curmi kei jo'u lo javni vu'o poi le genturfa'i pu dunda ke'a",
    "      ##   .i va'o lo nu le ju'agri cu se tcidu kei le seljdi cu kunti",
    "",
    "",
    "const",
    "  ARTICLES_WIKIPEDIA* = [",
  ]
  for article in articles.articles:
    lines.add "    ArticleWikipedia(title: " & article.title.toLiteral & ", revision: " &
        $article.revision & "),"
  lines.add "  ]"
  lines.add "    ## lo prosa ja'i lo lerpoi porsi be lo namcu pe lo papri"
  lines.add "  PARAGRAPHS_WIKIPEDIA* = ["
  for article in articles.articles:
    for i, paragraph in article.paragraphs: lines.add article.linesParagraph(i + 1, paragraph)
  lines.add "  ]"
  lines.add "    ## lo ju'agri pe ro prosa ta'i lo porsi"
  lines.join("\n") & "\n"


func toNotice*(articles: Articles): string =
  ## ciska lo notci be le crujva
  ##   .i le notci cu cusku ro nu galfi kei gi'e sitna ro prosa sepi'o lo citri be le prosa
  var lines = @[
    "# Notice",
    "",
    "The file `articles.nim` in this folder holds the text of articles of the lojban Wikipedia,",
    "at <https://jbo.wikipedia.org>. The Wikipedia releases its text under the Creative Commons",
    "Attribution-ShareAlike licence (CC BY-SA), now version 4.0, at",
    "<" & URL_LICENCE_WIKIPEDIA & ">.",
    "",
    "Text written before the Wikipedia moved to version 4.0 came under version 3.0. Version 3.0",
    "lets an adaptation be shared under a later version. So this folder is not under the licence",
    "of the repository, and it is distributed under CC BY-SA 4.0.",
    "",
    "These are the changes:",
    "",
    "- The API of the Wikipedia gives the plain text of each article, without its markup.",
    "- Each heading is left out, and each line of the text is one paragraph.",
    "- The text of each paragraph does not change.",
    "",
    "The command `nim r tools/build.nim wikipedia <directory>` writes this folder. Each article",
    "names its authors in its history. These are the articles, each with the revision that the",
    "text comes from, and its history:",
    "",
  ]
  for article in articles.articles:
    lines.add "- `" & article.title & "`, revision " & $article.revision & ":"
    lines.add "  <" & URL_PAGE & "oldid=" & $article.revision & ">,"
    lines.add "  <" & URL_PAGE & "curid=" & $article.page & "&action=history>"
  lines.join("\n") & "\n"
