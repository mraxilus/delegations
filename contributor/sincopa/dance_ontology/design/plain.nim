## Read prose off page, and hold it to two countable rules of Simplified Technical English
## (`GUIDE.md`, Article VI.8).
##
##   Two rules of subset can be counted: sentence's words and paragraph's sentences.  Rest of
##     subset, from approved word to active voice, is read rather than counted, so nothing here
##     claims to check it.
##   Prose is `p` and `li` text alone.  Caption, swatch label and heading are set in fragments
##     nobody writes sentences in, and to hold them to sentence rule would count label as
##     sentence without full stop.
##   Cost: markup is read by line forms, never parsed, exactly as curator's record checks are.
##     Page carries no comment or fenced block inside its prose, and script and style are cut
##     before reading.

{.experimental: "strictFuncs".}

import std/[strutils]


const
  WORDS* = 25
    ## Words one sentence of description may hold (`GUIDE.md`, "one instruction in one
    ##   sentence").  Instruction takes 20, which is not counted apart here: page describes.
  SENTENCES* = 6
    ## Sentences one paragraph may hold, opened by one that says topic.


func cut(markup, opens, shuts: string): string =
  ## Drop every element of this kind, tag to tag.
  result = markup
  while true:
    let a = result.find(opens)
    if a < 0: return
    let b = result.find(shuts, a)
    if b < 0: return
    result = result[0 ..< a] & " " & result[b + shuts.len .. ^1]


func plain(markup: string): string =
  ## Text of markup: tags out, entities said as what they stand for.
  var out_text = newStringOfCap(markup.len)
  var inside = false
  for ch in markup:
    case ch
    of '<': inside = true
    of '>': inside = false; out_text.add ' '
    else:
      if not inside: out_text.add ch
  out_text.multiReplace(
    ("&mdash;", "-"), ("&nbsp;", " "), ("&middot;", "-"), ("&amp;", "and"),
    ("&frac12;", "half"), ("&#189;", "half"), ("&#188;", "quarter"), ("&frac14;", "quarter"),
    ("&frac34;", "three quarters"), ("&#8722;", "minus"), ("&#10005;", "cross"),
    ("&rsquo;", "'"), ("&ldquo;", "\""), ("&rdquo;", "\""), ("&hellip;", "..."),
    ("&minus;", "minus"), ("&larr;", "left"), ("&rarr;", "right"), ("&#10003;", "tick"),
    ("&#42;", "star"), ("&lt;", "less"), ("&gt;", "more"),
  )


func prose*(markup: string): seq[string] =
  ## Every paragraph of prose on page, as text.
  let body = markup.cut("<script", "</script>").cut("<style", "</style>")
                   .cut("<!--", "-->")
  for kind in ["p", "li"]:
    var at = 0
    while true:
      let opens = body.find("<" & kind, at)
      if opens < 0 or opens + 1 + kind.len >= body.len: break
      # Element of another kind whose name starts same way, such as `path` or `line`.  Step
      #   over its opening tag alone: closing tag reader would find is next paragraph's, so
      #   jumping there skipped every paragraph that stands behind drawing (`tplain.nim`).
      if body[opens + 1 + kind.len] notin {' ', '>'}:
        at = opens + 1
        continue
      let head = body.find('>', opens)
      let shuts = body.find("</" & kind & ">", head)
      if head < 0 or shuts < 0: break
      at = shuts + 1
      let said = body[head + 1 ..< shuts].plain.splitWhitespace.join(" ")
      if said.len > 0: result.add said


func sentences*(paragraph: string): seq[string] =
  ## Sentences of paragraph, split at full stop, question mark and exclamation.
  var said = ""
  for word in paragraph.splitWhitespace:
    said.add (if said.len > 0: " " else: "") & word
    if word.len > 0 and word[^1] in {'.', '!', '?'} and not word.endsWith("..."):
      result.add said
      said = ""
  if said.strip.len > 0: result.add said


func longSentences*(markup: string): seq[string] =
  ## Every sentence of prose over `WORDS` words, whole, so failure names what to split.
  for paragraph in markup.prose:
    for said in paragraph.sentences:
      if said.splitWhitespace.len > WORDS: result.add said


func longParagraphs*(markup: string): seq[string] =
  ## Every paragraph of prose over `SENTENCES` sentences, by its first sentence.
  for paragraph in markup.prose:
    let said = paragraph.sentences
    if said.len > SENTENCES: result.add said[0]
