discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Hold reader of prose to markup pages are really written in.
##   `plain.nim` reads prose off markup by line forms, so every element whose name opens same
##     way as `p` or `li` is one it must step over: `path`, `polyline`, `pattern` and
##     `polygon` for `p`, and `line` for `li`.  Drawn page carries hundreds of them.
##   Read of that kind went wrong once in way no page could show: reader stepped over drawn
##     element by jumping to next closing tag of kind it wanted, which is closing tag of next
##     real paragraph, so paragraph after any drawing was never read.  Sign page held 24
##     blocks of prose and reader saw 14.  Law then passed pages it had never read.
##   So bound is held here on markup written for test, where count is known, rather than only
##     on pages, where nothing says how many blocks there should be.

import std/[strutils, unittest]

import ../design/plain


suite "prose off markup":
  test "paragraph after drawn path is read":
    # Figure between two paragraphs is what every page does.
    let markup = """
      <p>First paragraph.</p>
      <svg><path d="M 0 0 L 1 1"/><polyline points="0,0 1,1"/></svg>
      <p>Second paragraph.</p>
    """
    check markup.prose == @["First paragraph.", "Second paragraph."]

  test "item after drawn line is read":
    # `line` opens same two letters as `li`.
    let markup = """
      <ul><li>First item.</li></ul>
      <svg><line x1="0" y1="0" x2="1" y2="1"/></svg>
      <ul><li>Second item.</li></ul>
    """
    check markup.prose == @["First item.", "Second item."]

  test "prose is text of paragraph and item alone":
    let markup = """
      <h2>Heading that is no sentence</h2>
      <p>Paragraph.</p>
      <figcaption>Caption that is no sentence</figcaption>
      <li>Item.</li>
      <script>var said = "<p>Not prose.</p>";</script>
      <style>p { color: red; }</style>
    """
    check markup.prose == @["Paragraph.", "Item."]

  test "sentence at the bound holds, and one word past it fails":
    let ok = "<p>" & "word ".repeat(WORDS - 1) & "end.</p>"
    let over = "<p>" & "word ".repeat(WORDS) & "end.</p>"
    check ok.longSentences.len == 0
    check over.longSentences.len == 1

  test "paragraph at the bound holds, and one sentence past it fails":
    let ok = "<p>" & "Sentence. ".repeat(SENTENCES) & "</p>"
    let over = "<p>" & "Sentence. ".repeat(SENTENCES + 1) & "</p>"
    check ok.longParagraphs.len == 0
    check over.longParagraphs.len == 1

  test "sentence ends at stop, and its words are counted whole":
    let markup = "<p>One sentence here. Two sentences now!  Three?</p>"
    check markup.prose[0].sentences.len == 3
    check markup.prose[0].sentences[0] == "One sentence here."


suite "prose off Markdown":
  ## Reader copies repository's `english` check rather than importing it (`markdownProse`), so
  ## each way it could part from that check is pinned here.  Checked against that check on
  ## nine documents of repository, 1158 blocks and 2746 sentences, every one same.

  test "fenced code is not read, however long its lines":
    let doc = "Before.\n\n```\n" & "word ".repeat(WORDS + 10) & "\n```\n\nAfter."
    check doc.markdownProse == @["Before.", "After."]

  test "quotation, table row, heading and rule carry no prose":
    let doc = "# Heading\n\n> Quoted words of somebody else.\n\n| a | b |\n\n---\n\nProse."
    check doc.markdownProse == @["Prose."]

  test "each list item is its own block, and blank line ends one":
    let doc = "- First item.\n- Second item,\n  wrapped.\n\nPlain line one.\nPlain line two."
    check doc.markdownProse ==
      @["First item.", "Second item, wrapped.", "Plain line one. Plain line two."]

  test "numbered item loses its number and keeps its words":
    check "12. Twelfth item.".markdownProse == @["Twelfth item."]

  test "backticked span is one word, however many it holds":
    let said = "Run `nim r tools/build.nim pages` now.".markdownProse[0]
    check said.splitWhitespace.len == 3

  test "sentence ends inside closing quote and emphasis, where page reader runs on":
    ## `**"Stop here."** Next.` is two sentences.  `sentences`, which reads pages, sees one,
    ## so seven sentences behind quoted rules would pass as six.
    let text = "**\"Stop here.\"** Next one."
    check text.markdownSentences.len == 2
    check text.sentences.len == 1
