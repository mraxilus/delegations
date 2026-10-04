## Enforce form of source (Article X.1, X.9, VIII.5): width, whitespace, endings, banners.
##   Per line: no CR; no tab; no trailing whitespace; at most `LINE_MAX` characters counted
##   as Unicode runes, not bytes, where breaking can fix it (`isWide`, knoller's `form.nim`).
##   Per file: non-empty; ends with exactly one newline.
##   Per Nim banner, first tier `#[ Title ]#` or second tier `#[[ Title ]]#`: two blank lines
##     before, exactly one after (X.2). First-tier banner followed at once by second-tier
##     banner leaves spacing between them to child's own two-before check. Three blank lines
##     pass too, and side with no text beyond it, or with banner beyond it other than parent
##     above child, goes unread, so this lenient check accepts all exact one writes.
##   Static pass runs neither X.9 nor exact X.2 yet, which knoller holds (`checkComments`,
##     `checkBanners`): `koch fix` lands first, so each project clears its gaps by one command
##     on its own branch, and pull request after it wires `fixes.checkFormatting` into static
##     pass, exact banner check replacing lenient one (CURATOR.md, duty 3). Fixers run now,
##     since they report nothing new.
##   Fixer of each check here with one mechanical fix lives in knoller's `form.nim`;
##     `formFixers` lists those kind rule names.
##
##   Cost: two-space indent unverified; indent width depends on syntax and stays with review.
##   Cost: wired banner check demands two blank lines of every banner, where X.2 asks three of
##     first tier. Exact check replaces it once projects run `koch fix` (CURATOR.md, duty 3).
##   Cost: `LICENSE.md` exempt from width; third-party text stays verbatim (XI.3 spirit).
##   Cost: X.9 read in Nim syntax alone (Nim, NimScript, nimble); trailing comment of
##     TypeScript, C, C++, YAML, cfg and shell goes unread until each kind gets scanner.

{.experimental: "strictFuncs".}

import std/[strutils, unicode]
import ../../knoller/src/knoller
import ./[findings, kinds]


const
  WIDTH_EXEMPT = ["LICENSE.md"]
    ## Root paths whose width goes unchecked: third-party text kept verbatim.



func checkBanner(path: string, lines: seq[string], i: int): seq[Finding] =
  ## Report banner at index `i` lacking two blank lines before or exactly one after.
  ##   Side where exact check reads no count is not read: no text beyond it, or banner beyond
  ##   it other than parent above child.
  var
    blanks = 0
    above = i - 1
  while i + blanks + 1 < lines.len and lines[i + blanks + 1].len == 0: inc blanks
  while above >= 0 and lines[above].len == 0: dec above
  let
    next = i + blanks + 1
    is_parent_above = above >= 0 and lines[above].tierOfBanner == 1 and
      lines[i].tierOfBanner == 2
    is_read_before = above >= 0 and (lines[above].tierOfBanner == 0 or is_parent_above)
    is_read_after = next < lines.len and lines[next].tierOfBanner == 0
    is_spaced_before = i >= 2 and lines[i - 1].len == 0 and lines[i - 2].len == 0
  if is_read_before and not is_spaced_before:
    result.add finding(path, i + 1, "Banner lacks two blank lines before it.")
  if is_read_after and blanks != 1:
    result.add finding(path, i + 1, "Banner lacks exactly one blank line after it.")


func checkForm*(path, source: string; rule: KindRule): seq[Finding] =
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
    if line.isEndedInWhitespace:
      result.add finding(path, number, "Line ends with whitespace.")
    if not is_width_exempt and line.isWide:
      result.add finding(
        path,
        number,
        "Line exceeds " & $LINE_MAX & " characters; got `" & $line.runeLen & "`.",
      )
    if rule.syntax == Syntax.Nim and line.tierOfBanner > 0:
      result.add checkBanner(path, lines, i)


func formFixers*(rule: KindRule): seq[Fixer] =
  ## List form fixers kind rule names, in order they run: Nim syntax takes every fixer of
  ##   knoller's form, i.e. tabs in strings, comments and banners besides line ends and ending.
  if rule.syntax == Syntax.Nim: @FORM_FIXERS else: @[Fixer(fixWhitespace), fixEnding]


func fixForm*(path, source: string; rule: KindRule): Fix =
  ## Rewrite source so each form check with one mechanical fix holds; report each rewrite.
  result.source = source
  for fixer in rule.formFixers: result = result.chain(fixer(path, result.source))
