## Enforce record body shape (provenance guide, "Prune, never narrate"; Article VIII.6).
##   Body is read as `#` heading lines with fenced code blanked first, and held to what guide
##     states: no section is headed by date, `## Open questions` is last section, no heading
##     appears twice, and headings are ATX, since every reader here sees `#` lines only and
##     underlined title is invisible to all of them.
##   Length: record over `RECORD_LINES`, or `##` section over `SECTION_LINES`, is finding
##     asking for prune to log (curator review, C8). Section catches narration that whole-file
##     ceiling misses, since one long section hides inside short record. Header may carry
##     `Pruned` row naming commit before last prune; its form is checked here and its existence
##     by koch against file's own log, since git is outside pure check.
##
##   Cost: rules are line forms, never Markdown parse: heading inside HTML comment counts,
##     and front matter is not skipped; governed record carries neither.

{.experimental: "strictFuncs".}

import std/[strutils, tables]
import ./[findings, markdown, provenance]


const
  SECTION_LINES* = 200
    ## Lines one `##` section may hold before prune to log is asked.
    ##   Record's own ceiling is crude: it punishes wide project and lets narrow one narrate
    ##     freely. Measured over 93 sections of five records, median is 34 lines and p90 is
    ##     137, while longest is 505 and holds 39% of its record. Section is where narration
    ##     collects, so section is where it is caught.
    ##   200 rather than 150: measured then, 150 flagged three sections of three projects and
    ##     200 flagged one, and both flagged same narration.
  RECORD_LINES* = 3000
    ## Lines record may hold before prune to log is asked.
    ##   Was 2,000 while records were written in ordinary English. Simplified Technical English
    ##     (Article VI.8) costs about 20% more lines, measured over five records, since one long
    ##     sentence becomes two short ones.
    ##   2,500 scaled old number by that cost and kept old headroom, which was none: largest
    ##     record stood at ceiling before and after. Two merges spent 17 lines of margin inside
    ##     one day, and next sentence anybody wrote reddened `main`. Backstop that fires on
    ##     ordinary work reports growth rather than narration, so this one carries 20% clear.
    ##   `SECTION_LINES` is instrument that reads narration. This is only backstop.
  OPEN_QUESTIONS* = "## Open questions"
    ## Heading of section that must come last; matched without case.
  PRUNED* = "Pruned"
    ## Optional header row naming commit before last prune, 7 to 40 hex digits.


func hasIsoDate*(s: string): bool =
  ## Decide whether `s` holds `YYYY-MM-DD` anywhere, digits bounded by non-digits.
  for i in 0 .. s.len - 10:
    if s[i ..< i + 10].isIsoDate and (i == 0 or s[i - 1] notin Digits) and
        (i + 10 == s.len or s[i + 10] notin Digits):
      return true
  false


func isUnderline(line: string): bool =
  ## Decide whether line is setext underline, i.e. only `=` or only `-`.
  let s = line.strip
  s.len > 0 and (s.allCharsInSet({'='}) or s.allCharsInSet({'-'}))


func headingText(line: string): string =
  ## Read heading's text without its marks.
  line.strip(chars = {'#', ' '})


func checkHeadings(path, source: string): seq[Finding] =
  ## Report dated heading, `## Open questions` not last, heading twice, and underlined title.
  let lines = source.fencedOut.splitLines
  var seen: seq[string]
  var open_at, last_at = 0
  for i, line in lines:
    if line.startsWith("#"):
      let text = line.headingText
      if line.hasIsoDate:
        result.add finding(
          path, i + 1,
          "Section is headed by date; record describes what is and log holds when " &
            "(provenance guide); got `" & line & "`.",
        )
      if text in seen:
        result.add finding(path, i + 1, "Heading appears twice; got `" & line & "`.")
      seen.add text
      if line.startsWith("## "):
        last_at = i + 1
        if line.toLowerAscii.startsWith(OPEN_QUESTIONS.toLowerAscii): open_at = i + 1
    elif i + 1 < lines.len and lines[i + 1].isUnderline:
      let s = line.strip
      if s.len > 0 and not s.startsWith("|"):
        let mark = if lines[i + 1].strip[0] == '=': "# " else: "## "
        result.add finding(
          path, i + 1,
          "Heading is underlined, which no reader here sees; write `" & mark & s & "`.",
        )
  if open_at > 0 and open_at != last_at:
    result.add finding(
      path, open_at,
      "`## Open questions` must be last section (provenance guide); got section at line " &
        $last_at & " after it.",
    )


func checkLength(path, source: string): seq[Finding] =
  ## Report record over `RECORD_LINES`, lines counted as `wc -l` counts them.
  let count = source.count('\n') + (if source.len > 0 and source[^1] != '\n': 1 else: 0)
  if count > RECORD_LINES:
    result.add finding(
      path, 0,
      "Record over " & $RECORD_LINES & " lines; prune to log and set `" & PRUNED &
        "` row (provenance guide); got " & $count & ".",
    )


func checkSections*(path, source: string): seq[Finding] =
  ## Report `##` section over `SECTION_LINES`, since narration collects inside one section.
  let lines = source.fencedOut.splitLines
  # Final newline leaves empty last element; counting it would charge last section one line.
  let body = if lines.len > 0 and lines[^1].len == 0: lines.len - 1 else: lines.len
  var opened: seq[int]
  for i, line in lines:
    if line.startsWith("## "): opened.add i
  for k, start in opened:
    let stop = if k + 1 < opened.len: opened[k + 1] else: body
    let count = stop - start - 1
    if count > SECTION_LINES:
      result.add finding(
        path, start + 1,
        "Section over " & $SECTION_LINES & " lines; prune to log or split it (provenance " &
          "guide); got " & $count & ".",
      )


func isCommitId*(s: string): bool =
  ## Decide whether `s` is 7 to 40 lowercase hex digits, as git abbreviates commits.
  s.len in 7 .. 40 and s.allCharsInSet({'0' .. '9', 'a' .. 'f'})


func prunedOf*(source: string): string =
  ## Read `Pruned` row's value; empty when row is absent.
  let fields = source.headerFields
  if PRUNED in fields: fields[PRUNED] else: ""


func checkPrunedRow(path, source: string): seq[Finding] =
  ## Report `Pruned` row whose value is not commit id.
  let value = source.prunedOf
  if value.len > 0 and not value.isCommitId:
    result.add finding(
      path, 0,
      "`" & PRUNED & "` must name commit as 7 to 40 hex digits; got `" & value & "`.",
    )


func checkRecord*(path, source: string): seq[Finding] =
  ## Run every body-shape check over one record.
  result = checkHeadings(path, source)
  result.add checkLength(path, source)
  result.add checkSections(path, source)
  result.add checkPrunedRow(path, source)
