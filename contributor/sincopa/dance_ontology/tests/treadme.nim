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

import std/[os, strutils, unittest]

import ../design/plain


const WRITTEN = ["sim/README.md"]
  ## READMEs held so far.  `design/README.md` joins when it is written again.


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
