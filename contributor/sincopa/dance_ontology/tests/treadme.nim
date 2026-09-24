discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Hold READMEs this project writes to two countable rules its pages are held to.
##   Article VI.8 binds every Markdown file (`CONTRIBUTOR.md`, Boundaries).  Repository's
##     `english` check reads three records at project's root and nothing nested below it, so
##     READMEs under `sim/` and `design/` were read by nothing: 192 findings stood in them,
##     issue #239.
##   Held file by file as each is written again, so `WRITTEN` grows and never shrinks.
##   Words outside approved dictionary are not counted here, as they are not on pages: they
##     are read (`plain.nim`).
##   Rules design README quotes are words of Architect, so they are quoted and not rewritten.
##     `>` quotation carries no prose, so bounds skip it; its fidelity is held instead, to
##     ledger in `rules.nim`, which holds each rule as it arrived.

import std/[os, sequtils, strutils, unittest]

import ../design/[plain, rules]


const
  WRITTEN = ["sim/README.md", "design/README.md"]
    ## READMEs held so far.
  RULED = "design/README.md"
    ## README quoting ledger, one `### Rule N` heading per rule.
  HEADING = "### Rule "
    ## Opening of heading rule's quotation sits under.


func quoted(document: string): seq[tuple[rule: int, words: string]] =
  ## Each rule heading with quotation under it, its lines joined by one space.
  ##   Quotation is first run of `>` lines below heading; heading with none gives empty
  ##     words, so missing quotation fails as wrong one does.
  var quoting, closed = false
  for raw in document.splitLines:
    let line = raw.strip
    if line.startsWith(HEADING):
      result.add (line[HEADING.len .. ^1].parseInt, "")
      quoting = false
      closed = false
    elif result.len > 0 and not closed:
      if line.startsWith(">"):
        let words = line[1 .. ^1].strip
        result[^1].words = (if quoting: result[^1].words & " " & words else: words)
        quoting = true
      elif quoting:
        closed = true


suite "this project's own Markdown":
  test "every README held keeps each sentence and each paragraph to its bound":
    ## Failure names file and sentence, so it says what to split.
    for doc in WRITTEN:
      for said in readFile(currentSourcePath.parentDir / ".." / doc).markdownProse:
        let found = said.markdownSentences
        if found.len > SENTENCES:
          echo "    ", doc, ": paragraph of ", found.len, " sentences, from: ", found[0]
        check found.len <= SENTENCES
        for s in found:
          if s.splitWhitespace.len > WORDS:
            echo "    ", doc, ": sentence of ", s.splitWhitespace.len, " words: ", s
          check s.splitWhitespace.len <= WORDS

  test "design README quotes every rule of ledger once, in order, word for word":
    ## Failure names rule and both wordings, so it says which copy moved.
    var numbers: seq[int]
    for (rule, words) in readFile(currentSourcePath.parentDir / ".." / RULED).quoted:
      numbers.add rule
      let ledger = (if rule in 1 .. RULES.len: RULES[rule - 1] else: "")
      if words != ledger:
        echo "    rule ", rule, " quoted: ", words
        echo "    rule ", rule, " ledger: ", ledger
      check words == ledger
    check numbers == toSeq(1 .. RULES.len)
