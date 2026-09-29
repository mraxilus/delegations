## Enforce form of source (Article X.1, VIII.5): width, whitespace, endings, banners.
##   Per line: no CR; no tab; no trailing whitespace; at most `LINE_MAX` characters counted
##   as Unicode runes, not bytes.
##   Per file: non-empty; ends with exactly one newline.
##   Per Nim banner, first tier `#[ Title ]#` or second tier `#[[ Title ]]#`: two blank lines
##     before, exactly one after (X.2). First-tier banner followed at once by second-tier
##     banner leaves spacing between them to child's own two-before check.
##
##   Line over width passes only when breaking cannot fix it: one whitespace-free token with
##     its indent already exceeds limit, that token is no longer than `TOKEN_MAX`, and rest of
##     line fits without it. URL has no whitespace to break at; prose always does, and
##     machine output is one run far past `TOKEN_MAX`.
##
##   Cost: two-space indent unverified; indent width depends on syntax and stays with review.
##   Cost: first tier takes three blank lines before (X.2), yet check demands two of every
##     banner. Tightening reddens contributor banners still spaced at two, so it waits on
##     their fixes (CURATOR.md, duty 3).
##   Cost: `LICENSE.md` exempt from width; third-party text stays verbatim (XI.3 spirit).

{.experimental: "strictFuncs".}

import std/[strutils, unicode]
import ./[findings, kinds]


const
  LINE_MAX* = 100
    ## Widest line allowed, in runes (Article X.1).
  TOKEN_MAX* = 400
    ## Longest unbreakable token exemption covers, in runes.
    ##   Font and data URLs run to few hundred characters; minified markup runs to thousands,
    ##   and belongs under `build/`, never committed.
  WIDTH_EXEMPT = ["LICENSE.md"]
    ## Root paths whose width goes unchecked: third-party text kept verbatim.


func tierOfBanner(line: string): int =
  ## Read tier of section banner alone on line: 1 for `#[ Title ]#`, 2 for `#[[ Title ]]#`.
  ##   Zero for any other line.
  if line.len > 8 and line.startsWith("#[[ ") and line.endsWith(" ]]#"): 2
  elif line.len > 6 and line.startsWith("#[ ") and line.endsWith(" ]#"): 1
  else: 0


func checkBanner(path: string, lines: seq[string], i: int): seq[Finding] =
  ## Report banner at index `i` lacking two blank lines before or exactly one after.
  var blanks = 0
  while i + blanks + 1 < lines.len and lines[i + blanks + 1].len == 0: inc blanks
  let
    next = i + blanks + 1
    is_child_next = lines[i].tierOfBanner == 1 and next < lines.len and
      lines[next].tierOfBanner == 2
    is_spaced_before = i >= 2 and lines[i - 1].len == 0 and lines[i - 2].len == 0
    is_spaced_after = is_child_next or (blanks == 1 and next < lines.len)
  if not is_spaced_before:
    result.add finding(path, i + 1, "Banner lacks two blank lines before it.")
  if not is_spaced_after:
    result.add finding(path, i + 1, "Banner lacks exactly one blank line after it.")


func isUnbreakable*(line: string): bool =
  ## Decide whether line exceeds limit only through one whitespace-free token, e.g. URL.
  ##   True when no reflow helps: longest token with indent overruns limit, token is within
  ##   `TOKEN_MAX`, and rest of line fits once that token is removed.
  let indent = line.len - line.strip(trailing = false).len
  var longest = 0
  for token in strutils.splitWhitespace(line):
    longest = max(longest, token.runeLen)
  longest + indent > LINE_MAX and longest <= TOKEN_MAX and line.runeLen - longest <= LINE_MAX


func checkForm*(path, source: string, rule: KindRule): seq[Finding] =
  ## Report form violations of source under kind rule.
  if source.len == 0: return @[finding(path, 0, "File is empty.")]
  if not source.endsWith("\n"): result.add finding(path, 0, "File lacks final newline.")
  elif source.endsWith("\n\n"): result.add finding(path, 0, "File ends with blank line.")

  # Split on LF only so CR survives for detection; drop phantom line after final newline.
  var lines = source.split('\n')
  if source.endsWith("\n"): lines.setLen(lines.len - 1)
  let is_width_exempt = path in WIDTH_EXEMPT

  for i, line in lines:
    let number = i + 1
    if line.contains('\r'):
      result.add finding(path, number, "Line ends with CR; got CRLF.")
    if line.contains('\t'): result.add finding(path, number, "Line holds tab.")
    if line.len > 0 and line[^1] in {' ', '\t', '\r'}:
      result.add finding(path, number, "Line ends with whitespace.")
    let width = line.runeLen
    if not is_width_exempt and width > LINE_MAX and not line.isUnbreakable:
      result.add finding(
        path, number, "Line exceeds " & $LINE_MAX & " characters; got `" & $width & "`."
      )
    if rule.syntax == Syntax.Nim and line.tierOfBanner > 0:
      result.add checkBanner(path, lines, i)
