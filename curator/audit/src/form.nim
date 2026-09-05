## Enforce form of source (Article X.1, VIII.5): width, whitespace, endings, banners.
##   Per line: no CR; no tab; no trailing whitespace; at most `LINE_MAX` characters counted
##   as Unicode runes, not bytes.
##   Per file: non-empty; ends with exactly one newline.
##   Per Nim banner `#[ Title ]#`: two blank lines before, exactly one after (X.2).
##
##   Cost: two-space indent unverified; indent width depends on syntax and stays with review.
##   Cost: banner tier is unmarked in syntax, so check demands second-tier minimum (two
##     blank lines before) of every banner and cannot tell tiers apart.
##   Cost: `LICENSE.md` exempt from width; third-party text stays verbatim (XI.3 spirit).

{.experimental: "strictFuncs".}

import std/[strutils, unicode]
import ./[findings, kinds]


const
  LINE_MAX* = 100
    ## Widest line allowed, in runes (Article X.1).
  WIDTH_EXEMPT = ["LICENSE.md"]
    ## Root paths whose width goes unchecked: third-party text kept verbatim.


func isBanner*(line: string): bool =
  ## Decide whether line is section banner, i.e. `#[ Title ]#` alone on line.
  line.len > 6 and line.startsWith("#[ ") and line.endsWith(" ]#")


func checkBanner(path: string, lines: seq[string], i: int): seq[Finding] =
  ## Report banner at index `i` lacking two blank lines before or exactly one after.
  let is_spaced_before = i >= 2 and lines[i - 1].len == 0 and lines[i - 2].len == 0
  let is_spaced_after = i + 2 < lines.len and lines[i + 1].len == 0 and lines[i + 2].len > 0
  if not is_spaced_before:
    result.add finding(path, i + 1, "Banner lacks two blank lines before it.")
  if not is_spaced_after:
    result.add finding(path, i + 1, "Banner lacks exactly one blank line after it.")


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
    if not is_width_exempt and width > LINE_MAX:
      result.add finding(
        path, number, "Line exceeds " & $LINE_MAX & " characters; got `" & $width & "`."
      )
    if rule.syntax == Syntax.Nim and line.isBanner:
      result.add checkBanner(path, lines, i)
