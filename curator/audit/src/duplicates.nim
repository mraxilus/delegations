## Report Markdown paragraph written twice, in one file or across files (duty 10).
##   Two copies of one rule drift, and prompts drifted that way: rule kept in both prompts
##     with hand rule that change to either belongs in both (curator review, C6). Paragraph
##     of `PARAGRAPH_WORDS` or more, whitespace collapsed, seen again is finding at its
##     later place naming its first.
##   Fenced code, table rows and headings pass: example is quoted on purpose, table is data,
##     and heading twice is record check's own finding.
##
##   Cost: paragraph reworded by one word passes; check catches copy, never paraphrase.

{.experimental: "strictFuncs".}

import std/[strutils, tables]
import ./[findings, markdown]


const PARAGRAPH_WORDS* = 25
  ## Words paragraph must hold before second copy is finding; shorter one is phrase.


type Paragraph* = object
  ## Define one prose paragraph and where it starts.
  text*: string  ## Words joined by single space.
  line*: int     ## Line paragraph opens on, 1-based.


func paragraphs*(markdown: string): seq[Paragraph] =
  ## Collect prose paragraphs of document, fenced code, tables and headings left out.
  var words: seq[string]
  var opened = 0
  let lines = markdown.fencedOut.splitLines
  for i, line in lines:
    let s = line.strip
    let is_prose = s.len > 0 and not s.startsWith("|") and not s.startsWith("#")
    if is_prose:
      if words.len == 0: opened = i + 1
      words.add s.splitWhitespace
    elif words.len > 0:
      result.add Paragraph(text: words.join(" "), line: opened)
      words = @[]
  if words.len > 0: result.add Paragraph(text: words.join(" "), line: opened)


func checkDuplicates*(documents: openArray[(string, string)]): seq[Finding] =
  ## Report paragraph seen before, across documents given as path and content in order.
  var first = initTable[string, string]()
  for (path, content) in documents:
    for p in content.paragraphs:
      if p.text.count(' ') + 1 < PARAGRAPH_WORDS: continue
      if p.text in first:
        result.add finding(
          path, p.line,
          "Paragraph appears twice; write it once and point at it (duty 10); first at `" &
            first[p.text] & "`; got `" & p.text[0 ..< min(p.text.len, 60)] & "`.",
        )
      else:
        first[p.text] = path & ":" & $p.line
