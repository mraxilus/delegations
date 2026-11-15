## ciska lo clani prosa pe la'o gy. Wikipedia .gy. pe la lojban. ta'i pa samtci datnyvei pe la'o gy.
##   Nim .gy. zi'e poi ponse lo klesi gi'e vasru lo se jdice be le genturfa'i bei ro ju'agri
##   .i `build.nim` cu pilno le vi datnyvei
##   .i tcidu lo danfu pe la'o gy. API .gy. pe la'o gy. Wikipedia .gy.
##   .i le danfu cu se ralte ne'i pa datnyveiste
##   .i ro prosa cu ponse pa datnyvei
##   .i `QUERY` cu cpedu lo sampu se ciska .e lo te galfi be le papri
##   .i ciska `tests/articles_wikipedia/articles.nim` .e `NOTICE.md` noi lamji `articles.nim`
##
## ni'o la'o gy. Architect .gy. cu jdice `D5 c` bu'u `#819`
##   .i pa datnyveiste pe la'o gy. delegations .gy. cu vasru lo clani prosa poi se javni la'o gy. CC
##     BY-SA .gy.
##   .i ro nu cipra cu tcidu le prosa
##   .i le datnyveiste cu vasru ji'a lo se jdice pe ro pagbu
##   .i lo pagbu cu du lo ju'agri
##   .i lo ju'agri cu du pa linji pe lo sampu se ciska
##   .i lo cmene be lo ckupaupau cu na se tcidu
##   .i se ki'u bo le cipra cu tcidu lo jorne se ciska poi vasru su'o re jufra ku'o ta'i pa se ciska
##     pe `CLL 21.1`
##   .i pa sinxa namcu pe la'o gy. SHA-256 .gy. cu stodi sinxa le danfu
##   .i le sinxa namcu cu se zbasu fi lo se cusku be `sha256sum` poi tcidu ro datnyvei ja'i lo porsi
##     be lo cmene
##   .i `cll.nim` cu stodi sinxa lo papri ta'i le mintu
##   .i le sampu se ciska cu se krasi le te galfi poi le danfu cu cusku lo namcu pe ke'a
##   .i le te galfi cu se stodi sinxa ji'a
##   .i ki'u bo lo cnino te galfi cu galfi le sinxa namcu
##   .i lo se jdice cu du lo se dunda be le genturfa'i ca lo nu ciska
##   .i le se jdice cu se tcidu ja'i `tatoeba.nim`
##   .i le cipra cu fliba ca ro nu pa se jdice cu cenba
##   .i jdima fa lo nu la'o gy. JSON .gy. cu se tcidu ne'i le vi datnyvei po'o
##   .i ki'u bo la'o gy. API .gy. pe la'o gy. Wikipedia .gy. cu spuda sepi'o la'o gy. JSON .gy.
##   .i no jgena pe la'o gy. JSON .gy. cu cliva le vi datnyvei to le pagbu poi se cmene zoi gy. Data
##     .gy. ne'i `CONTRIBUTOR.md` toi

{.experimental: "strictFuncs".}

import std/[algorithm, json, os, osproc, sequtils, strutils]

import ./[literals, tatoeba]


type
  Paragraph* = object
    ## pa ju'agri pe pa prosa
    ##   .i le klesi cu vasru lo se ciska .e lo se jdice poi le genturfa'i cu dunda ke'a le ju'agri
    text*: string  ## pa linji pe lo sampu se ciska ta'i lo nu le danfu cu dunda le linji
    verdict*: string
      ## lo nu to'e curmi kei jo'u lo javni vu'o poi le genturfa'i cu dunda ke'a
      ##   .i va'o lo nu le ju'agri cu se tcidu kei le se jdice cu kunti

  Article* = object  ## pa prosa ta'i lo nu le danfu cu dunda le prosa
    title*: string  ## lo cmene be le papri
    page*: int  ## lo namcu poi la'o gy. Wikipedia .gy. cu dunda ke'a le papri
    revision*: int  ## le te galfi poi le sampu se ciska cu se krasi ke'a
    paragraphs*: seq[Paragraph]  ## lo ju'agri ta'i lo porsi pe le prosa

  Articles* = object  ## ro prosa poi se tcidu ku'o .e lo sinxa namcu be le danfu
    articles*: seq[Article]  ## lo prosa ta'i lo porsi be lo cmene be lo datnyvei
    digest*: string
      ## la'o gy. SHA-256 .gy. pe lo se cusku be `sha256sum` poi tcidu ro danfu ja'i lo porsi be lo
      ##   cmene


const
  DIGEST_WIKIPEDIA* = "6bbe766025354f3dd9e7335ccd779cc868dbaddd9d8f2071eeb9680a0a3d0c21"
    ## la'o gy. SHA-256 .gy. pe le danfu pe le ci papri poi lo namcu pe ke'a cu du li vonovovo .a li
    ##   paso .a li zeno
    ##   .i le danfu cu se ralte de'i `2026-11-06`
  URL_API* = "https://jbo.wikipedia.org/w/api.php"
    ## le judri be la'o gy. API .gy. poi le danfu cu se krasi ke'a
  QUERY* = "action=query&prop=extracts|revisions&explaintext=1&rvprop=ids|timestamp&" &
      "format=json&formatversion=2&pageids="
    ## lo preti poi ro danfu cu spuda ke'a
    ##   .i lo namcu pe le papri cu se jmina fi le fanmo be le preti
  URL_LICENCE_WIKIPEDIA* = "https://creativecommons.org/licenses/by-sa/4.0/"
    ## le curmi javni pe lo se ciska pe la'o gy. Wikipedia .gy. pe la lojban.
  URL_PAGE* = "https://jbo.wikipedia.org/w/index.php?"
    ## le judri be lo papri
    ##   .i lo preti pe le papri cu se jmina fi le fanmo be le judri
  PATH_ARTICLES* = "tests/articles_wikipedia/articles.nim"
    ## lo datnyvei poi le prosa cu se ciska fi ke'a
  PATH_NOTICE_WIKIPEDIA* = "tests/articles_wikipedia/NOTICE.md"
    ## lo notci be le curmi javni
    ##   .i le notci cu lamji le samtci datnyvei
  MARK_HEADING = '='
    ## lo lerfu poi cfari lo cmene be lo ckupaupau pe lo sampu se ciska
    ##   .i lo cmene be lo ckupaupau cu se vimcu



#[ ni'o ni'o ni'o lo nu tcidu ]#

proc readArticle(path: string): Article =
  ## tcidu pa danfu
  ##   .i le danfu cu vasru lo cmene .e lo namcu pe le papri ge'u .e lo te galfi .e ro ju'agri jo'u
  ##     le se jdice pe le ju'agri
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
  ## tcidu ro danfu pe lo datnyveiste ta'i lo porsi be lo cmene gi'e dunda lo sinxa namcu be le
  ##   danfu
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
  ## ciska pa ju'agri ta'i lo zbasu fancu
  ##   .i ro datni pagbu cu se ciska fi pa linji
  ##   .i le se ciska cu se fendi mu'i lo nu mapti
  result.add "    ParagraphWikipedia("
  result.add "      article: " & article.title.toLiteral & ","
  result.add "      index: " & $index & ","
  # ro pagbu cu mapti le pamoi linji
  #   .i lo se ciska pe le pamoi linji cu cfari bu'u lo stuzi poi traji lo ka darno
  let text = paragraph.text.linesLiteral(12, ",")
  result.add "      text: " & text[0].strip(trailing = false)
  for line in text[1 .. ^1]: result.add repeat(' ', 10) & line.strip(trailing = false)
  result.add "      verdict: " & paragraph.verdict.toLiteral & ","
  result.add "    ),"


func toModuleArticles*(articles: Articles): string =
  ## ciska le prosa ta'i lo se ciska be fi le datnyvei poi se ralte
  var lines = @[
    "## ralte lo clani prosa pe la'o gy. Wikipedia .gy. pe la lojban. mu'i le cipra",
    "##   .i le vi datnyvei cu vasru lo se jdice be le genturfa'i bei ro ju'agri",
    "##   .i lo minde po'u `nim r tools/build.nim wikipedia <directory>` cu ciska le vi datnyvei " &
    "ra'i lo",
    "##     danfu pe la'o gy. API .gy. pe la'o gy. Wikipedia .gy.",
    "##   .i lo sinxa namcu be le danfu cu du zoi ky. SHA-256 `" & articles.digest[0..31] & "`",
    "##     `" & articles.digest[32 .. ^1] & "` .ky.",
    "##   .i lo nu xance galfi le vi datnyvei cu na drani",
    "##   .i lo nu galfi le vi datnyvei cu nitcu lo nu rapli pilno le minde",
    "##   .i lo se ciska pe la'o gy. Wikipedia .gy. pe la lojban. cu se javni la'o gy. CC BY-SA " &
    "4.0 .gy.",
    "##   .i `NOTICE.md` noi lamji le vi datnyvei cu cusku lo du'u le datnyveiste poi vasru le vi",
    "##     datnyvei cu se javni le curmi javni gi'e no roi se javni le curmi javni pe la'o gy.",
    "##     delegations .gy.",
    "",
    "{.experimental: \"strictFuncs\".}",
    "",
    "",
    "type",
    "  ArticleWikipedia* = object",
    "    ## pa prosa",
    "    ##   .i le klesi cu vasru lo cmene .e le te galfi poi le se ciska cu se krasi ke'a",
    "    title* {.requiresInit.}: string  ## lo cmene be le papri",
    "    revision* {.requiresInit.}: int  ## le te galfi poi le sampu se ciska cu se krasi ke'a",
    "",
    "  ParagraphWikipedia* = object",
    "    ## pa ju'agri",
    "    ##   .i le klesi cu vasru lo prosa .e lo stuzi .e lo se ciska .e lo se jdice",
    "    article* {.requiresInit.}: string  ## lo cmene be le prosa poi vasru le ju'agri",
    "    index* {.requiresInit.}: int",
    "      ## lo namcu pe le ju'agri ne'i le prosa",
    "      ##   .i le namcu pe le pamoi ju'agri cu du li pa",
    "    text* {.requiresInit.}: string",
    "      ## pa linji pe lo sampu se ciska ta'i lo nu le danfu cu dunda le linji",
    "    verdict* {.requiresInit.}: string",
    "      ## lo nu to'e curmi kei jo'u lo javni vu'o poi le genturfa'i pu dunda ke'a",
    "      ##   .i va'o lo nu le ju'agri cu se tcidu kei le se jdice cu kunti",
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
  ## ciska lo notci be le curmi javni
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
