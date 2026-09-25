## Hold table report shows to words report can say.
##   `sim/words` is one translation table, and `sim/verdicts.md` opens by
##     printing it, so reader knows what each phrase means.  Printed table is
##     written out by hand, and it is derived view of `said` (Article I.4).
##   Nothing read it back, so it went stale: `said` grew `elbow forward` and
##     table never named it, while every other law passed.
##   Law walks every phrase `said` can return, strikes out each term table
##     names, and demands nothing is left over.  Residue is word reader meets
##     with no entry to read it by.

import std/[algorithm, options, os, strutils, unittest]

import ../../sim/[read, rig, words]


const REPORT = currentSourcePath().parentDir.parentDir.parentDir / "sim" / "verdicts.md"
  ## Report sim writes, which opens by printing its translation table.


iterator phrases(): string =
  ## Every phrase `said` can return, over every reading pose can carry.
  for band in Band:
    yield said(none(Lying), band)
    for aspect in Aspect:
      for pressing in [false, true]:
        for elbow_fore in [false, true]:
          yield said(some(Lying(aspect: aspect, band: band, pressing: pressing,
                                elbowFore: elbow_fore)), band)


func shown(report: string): seq[string] =
  ## Read right-hand column of table report prints, longest term first.
  ##   Longest first so striking out never leaves tail of longer term.
  var inside = false
  for line in report.splitLines:
    let bare = line.strip
    if bare.startsWith("| the sim says |"):
      inside = true
      continue
    if not inside: continue
    if not bare.startsWith("|"): break
    if bare.startsWith("|---"): continue
    let cells = bare.strip(chars = {'|', ' '}).split('|')
    if cells.len < 2: continue
    result.add cells[1].strip
  result.sort(proc (a, b: string): int = cmp(b.len, a.len))


func residue(phrase: string; terms: seq[string]): string =
  ## Strike every term out of phrase, leaving what table does not name.
  result = phrase
  for term in terms:
    result = result.replace(term, "")
  result = result.strip(chars = {' ', ',', '(', ')'})


suite "the report shows every word it says":
  let
    report = readFile(REPORT)
    terms = shown(report)

  test "report still prints its translation table":
    # Law below says nothing where table is missing, so terms are demanded
    # first.
    check terms.len > 0
    check "wrap" in terms
    check "lock" in terms

  test "every phrase the sim says is named by the table":
    for phrase in phrases():
      let left = residue(phrase, terms)
      if left.len > 0:
        checkpoint "table names no `" & left & "`, said in: " & phrase
        fail()
