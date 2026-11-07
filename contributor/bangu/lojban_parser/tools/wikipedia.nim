## Render long articles of lojban Wikipedia as typed Nim module holding verdict parser gives each
##   paragraph; `build.nim` runs it.
##   Reads answers of API of Wikipedia saved in one directory, one file to article, as `QUERY`
##   asks for plain text and revision of page; renders `tests/articles_wikipedia/articles.nim`,
##   and `NOTICE.md` beside it.
##
##   Ruling `D5 c` of #819: folder of repository holds long articles under CC BY-SA, which each
##     run reads, with verdict for each part. Part is paragraph: line of plain text, heading left
##     out, so suite reads connected text of several sentences as one text of 21.1.
##   Answers are pinned by one SHA-256 over output of `sha256sum` given every file in order of
##     name, as `cll.nim` pins pages. Plain text is of revision answer names; revision is pinned
##     too, since newer revision changes digest.
##   Verdict is what parser gives at render, as `tatoeba.nim` reads it; suite fails at each
##     verdict that changes.
##   Cost: JSON is read here alone, since API of Wikipedia answers in it; no node of it leaves
##     this module (CONTRIBUTOR.md, Data).

{.experimental: "strictFuncs".}

import std/[algorithm, json, os, osproc, sequtils, strutils]

import ./[literals, tatoeba]


type
  Paragraph* = object  ## Define one paragraph of article: text, and verdict parser gives it.
    text*: string  ## Line of plain text, as answer gives it.
    verdict*: string  ## Refusal and rule parser gives; empty where paragraph reads.

  Article* = object  ## Define one article as answer gives it.
    title*: string  ## Title of page.
    page*: int  ## Number Wikipedia gives page.
    revision*: int  ## Revision plain text comes from.
    paragraphs*: seq[Paragraph]  ## Paragraphs in order of article.

  Articles* = object  ## Define every article read, and digest of answers.
    articles*: seq[Article]  ## Articles in order of file name.
    digest*: string  ## SHA-256 over output of `sha256sum` given every answer, by name.


const
  DIGEST_WIKIPEDIA* = "6bbe766025354f3dd9e7335ccd779cc868dbaddd9d8f2071eeb9680a0a3d0c21"
    ## SHA-256 over answers for pages 4044, 19 and 70, saved 2026-11-06.
  URL_API* = "https://jbo.wikipedia.org/w/api.php"  ## Address of API answers come from.
  QUERY* = "action=query&prop=extracts|revisions&explaintext=1&rvprop=ids|timestamp&" &
      "format=json&formatversion=2&pageids="
    ## Query each answer gives, before number of page.
  URL_LICENCE_WIKIPEDIA* = "https://creativecommons.org/licenses/by-sa/4.0/"
    ## Licence of text of lojban Wikipedia.
  URL_PAGE* = "https://jbo.wikipedia.org/w/index.php?"  ## Address of page, before its query.
  PATH_ARTICLES* = "tests/articles_wikipedia/articles.nim"  ## Module articles render to.
  PATH_NOTICE_WIKIPEDIA* = "tests/articles_wikipedia/NOTICE.md"  ## Notice of licence beside it.
  MARK_HEADING = '='  ## Character opening heading of plain text, left out.



#[ Reading ]#

proc readArticle(path: string): Article =
  ## Read one answer: title, page, revision, and each paragraph with its verdict.
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
  ## Read every answer of directory, in order of name, with digest of answers.
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



#[ Rendering ]#

func linesParagraph(article: Article, index: int, paragraph: Paragraph): seq[string] =
  ## Render one paragraph as constructor, one field to line, text split to fit.
  result.add "    ParagraphWikipedia("
  result.add "      article: " & article.title.toLiteral & ","
  result.add "      index: " & $index & ","
  let text = paragraph.text.linesLiteral(12, ",")  # pieces fit first line, widest
  result.add "      text: " & text[0].strip(trailing = false)
  for line in text[1 .. ^1]: result.add repeat(' ', 10) & line.strip(trailing = false)
  result.add "      verdict: " & paragraph.verdict.toLiteral & ","
  result.add "    ),"


func toModuleArticles*(articles: Articles): string =
  ## Render articles as committed module text.
  var lines = @[
    "## Hold long articles of lojban Wikipedia, with verdict parser gave each paragraph, for " &
    "suite.",
    "##   Written by `nim r tools/build.nim wikipedia <directory>` from answers of API of",
    "##   Wikipedia, SHA-256 `" & articles.digest[0..31] & "`",
    "##   `" & articles.digest[32 .. ^1] & "`; never edit by hand, run verb again.",
    "##   Text of lojban Wikipedia, under licence CC BY-SA 4.0; folder holding module is",
    "##     distributed under that licence, as `NOTICE.md` beside module gives, never under",
    "##     licence of repository.",
    "",
    "{.experimental: \"strictFuncs\".}",
    "",
    "",
    "type",
    "  ArticleWikipedia* = object  ## Define one article: title, and revision text comes from.",
    "    title* {.requiresInit.}: string  ## Title of page.",
    "    revision* {.requiresInit.}: int  ## Revision plain text comes from.",
    "",
    "  ParagraphWikipedia* = object  ## Define one paragraph: article, place, text and verdict.",
    "    article* {.requiresInit.}: string  ## Title of article holding paragraph.",
    "    index* {.requiresInit.}: int  ## Place of paragraph in its article, from one.",
    "    text* {.requiresInit.}: string  ## Line of plain text, as answer gives it.",
    "    verdict* {.requiresInit.}: string  ## Refusal and rule parser gave; empty where read.",
    "",
    "",
    "const",
    "  ARTICLES_WIKIPEDIA* = [",
  ]
  for article in articles.articles:
    lines.add "    ArticleWikipedia(title: " & article.title.toLiteral & ", revision: " &
        $article.revision & "),"
  lines.add "  ]"
  lines.add "    ## Articles, in order of number of page as text."
  lines.add "  PARAGRAPHS_WIKIPEDIA* = ["
  for article in articles.articles:
    for i, paragraph in article.paragraphs: lines.add article.linesParagraph(i + 1, paragraph)
  lines.add "  ]"
  lines.add "    ## Paragraphs of each article, in order."
  lines.join("\n") & "\n"


func toNotice*(articles: Articles): string =
  ## Render notice of licence, with changes made and each article credited by its history.
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
