## Check form of text, fix form of Nim source (Article X.1, X.2, X.9, VIII.5), and read width
##   each fixer guards.
##   Width: line holds at most `LINE_MAX` runes, not bytes. Line over width passes only when
##     breaking cannot fix it: one whitespace-free token with its indent already exceeds limit,
##     that token is no longer than `TOKEN_MAX`, and rest of line fits without it. URL has no
##     whitespace to break at; prose always does, and machine output is one run far past
##     `TOKEN_MAX`.
##   Trailing comment takes exactly two spaces before its marker (X.9). Marker is first `#`
##     after code, read on code-only view and on code-and-comments view (`views.nim`), so `#`
##     inside string never trips it. Line holding no code, i.e. whole comment, doc comment, or
##     text inside block comment or long string, holds no trailing comment.
##   Exact X.2 (`checkBanners`): first tier takes exactly three blank lines before, second tier
##     exactly two, either exactly one after; second tier following its parent at once keeps its
##     own two. Banner opening file, run ending file, and banner after banner other than parent
##     and child stand outside rule, since X.2 gives no count there.
##   Checks of whitespace, line ending, file ending, tab and width read text alone, never Nim
##     (`checkForm`): line splits on LF only, so CR survives to be read, and line after final
##     newline is none. So they serve every kind of text, and `curator/audit` runs them on each
##     kind it reads; fixers here are Nim's.
##
##   Fixers share each check's own predicate, so each rule is written once (Article II.1):
##     trailing whitespace is cut, CR of CRLF ending among it; ending becomes exactly one
##     newline; gap before trailing comment becomes two spaces; run of blank lines beside
##     banner takes count exact X.2 check reads.
##   Tab and comment fixers are wideners (`reports.nim`): off held line they write gap or
##     escape that widens line past `LINE_MAX`, and chain wraps line after; on held line, as in
##     their two-argument form, gap or escape that would widen narrow line stays, finding and all.
##   Plain `#` trailing comment on line wider than `LINE_MAX` moves to own line above, at
##     indent of its line, where it fits there (`fixCommentsAbove`); lexer drops `#` comment, so
##     tree stays, and wrapping reads line left behind in next round. Doc `##` and block comment
##     stay, as does line inside token spanning lines, where line above lies inside that token.
##   Tab inside one-line string that is neither raw nor long is written `\t`: escape reads as
##     same byte, so string is unchanged.
##   No fixer: other tab, since its width is guess, and raw or long string reads `\t` as two
##     characters; lone CR, which is line break or stray byte; width, which reflow, wrap or
##     rename each fix; empty file.
##
##   Cost: column of aligned trailing comments reads as finding, and fixer sets each to two.
##     Architect's ruling: X.9 asks exactly two, since column breaks on rename; one longer
##     name moves every comment of block, so one-line change rewrites whole column.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, strutils, unicode]
import ./[reports, tokens, views]


const
  LINE_MAX* = 100  ## Widest line allowed, in runes (Article X.1).
  TOKEN_MAX* = 400
    ## Longest unbreakable token exemption covers, in runes.
    ##   Font and data URLs run to few hundred characters; minified markup runs to thousands,
    ##   and belongs under `build/`, never committed.
  COMMENT_GAP* = 2  ## Spaces before trailing comment's marker (Article X.9).
  TRAILING_WHITESPACE = {' ', '\t', '\r'}
    ## Characters line never ends with (VIII.5); CR among them, so CRLF ending is one.
  LUT_BLANKS_BY_TIER: array[1 .. 2, int] = [3, 2]
    ## Blank lines banner of each tier takes before it (X.2).
  BLANKS_AFTER_BANNER = 1  ## Blank lines either banner takes after it (X.2).
  LONG_QUOTE = "\"\"\""  ## Delimiter of long string, which reads backslash as itself.
  IDENTIFIER_CHARS = {'a' .. 'z', 'A' .. 'Z', '0' .. '9', '_', '\x80' .. '\xFF'}
    ## Characters whose glue before quote makes string raw (`r"…"`, `fmt"…"`).


type
  Gap = object
    ## Define space before one trailing comment: line, marker index, spaces before marker.
    line: int  ## Zero-based line in source split on newline.
    at: int  ## Index of marker, i.e. first `#` after code.
    spaces: int  ## Spaces between last code character and marker.

  BlankRun = object  ## Define run of blank lines beside banner whose count X.2 reads otherwise.
    first: int  ## Zero-based line run opens on, i.e. line after one above it.
    count: int  ## Blank lines run holds.
    wanted: int  ## Blank lines X.2 asks.
    banner: int  ## Zero-based line of banner run stands beside.
    tier: int  ## Tier of that banner.
    is_before: bool  ## Run stands before banner, else after it.


func tierOfBanner*(line: string): int =
  ## Read tier of section banner alone on line: 1 for `#[ Title ]#`, 2 for `#[[ Title ]]#`.
  ##   Zero for any other line.
  if line.len > 8 and line.startsWith("#[[ ") and line.endsWith(" ]]#"): 2
  elif line.len > 6 and line.startsWith("#[ ") and line.endsWith(" ]#"): 1
  else: 0


func isUnbreakable*(line: string): bool =
  ## Decide whether line exceeds limit only through one whitespace-free token, e.g. URL.
  ##   True when no reflow helps: longest token with indent overruns limit, token is within
  ##   `TOKEN_MAX`, and rest of line fits once that token is removed.
  let indent = line.len - line.strip(trailing = false).len
  var longest = 0
  for token in strutils.splitWhitespace(line):
    longest = max(longest, token.runeLen)
  longest + indent > LINE_MAX and longest <= TOKEN_MAX and line.runeLen - longest <= LINE_MAX


func isWide*(line: string): bool =
  ## Decide whether width check reports line: over `LINE_MAX` runes, and breakable.
  line.runeLen > LINE_MAX and not line.isUnbreakable


func isEndedInWhitespace(line: string): bool =
  ## Decide whether line ends with space, tab or CR (VIII.5).
  line.len > 0 and line[^1] in TRAILING_WHITESPACE


func checkForm*(path, source: string): seq[Report] =
  ## Report text that breaks form: empty file, ending other than one newline, CR, tab, trailing
  ##   whitespace, and width break can fix (X.1, VIII.5).
  if source.len == 0: return @[initReport(path, 0, Rule.FileEnding, "File is empty.")]
  if not source.endsWith("\n"):
    result.add initReport(path, 0, Rule.FileEnding, "File lacks final newline.")
  elif source.endsWith("\n\n"):
    result.add initReport(path, 0, Rule.FileEnding, "File ends with blank line.")

  # Split on LF only so CR survives for detection; drop phantom line after final newline.
  var lines = source.split('\n')
  if source.endsWith("\n"): lines.setLen(lines.len - 1)
  for i, line in lines:
    if '\r' in line:
      result.add initReport(path, i + 1, Rule.LineEnding, "Line ends with CR; got CRLF.")
    if '\t' in line: result.add initReport(path, i + 1, Rule.Tab, "Line holds tab.")
    if line.isEndedInWhitespace:
      result.add initReport(path, i + 1, Rule.TrailingWhitespace, "Line ends with whitespace.")
    if line.isWide:
      result.add initReport(
        path,
        i + 1,
        Rule.LineWidth,
        "Line exceeds " & $LINE_MAX & " characters; got `" & $line.runeLen & "`.",
      )


func gaps(source: string): seq[Gap] =
  ## Find each trailing comment of Nim source, with spaces before its marker.
  let
    lines = source.split('\n')
    code = source.codeOnly.split('\n')
    kept = source.codeAndComments.split('\n')
  for i, line in lines:
    let ending = code[i].strip(leading = false).len
    if ending == 0: continue
    let at = kept[i].find('#', ending)
    if at < 0: continue
    var spaces = 0
    while line[at - spaces - 1] == ' ': inc spaces
    result.add Gap(line: i, at: at, spaces: spaces)


func checkComments*(path, source: string): seq[Report] =
  ## Report trailing comment without exactly two spaces before its marker (X.9).
  ##   Named by its suite alone until `checkForm` calls it; header says why.
  for gap in source.gaps:
    if gap.spaces == COMMENT_GAP: continue
    result.add initReport(
      path,
      gap.line + 1,
      Rule.TrailingComment,
      "Trailing comment takes two spaces before its marker; got `" & $gap.spaces & "`.",
    )


func liftedComments(source: string): seq[Gap] =
  ## Find each plain `#` trailing comment of wide line whose comment fits own line above, at
  ##   indent of its line; line inside or closing token spanning lines has no line above to take.
  let lines = source.split('\n')
  var spanned = newSeq[bool](lines.len)
  for t in source.tokens:
    for line in t.line + 1 .. t.lastLine(source): spanned[line] = true
  for gap in source.gaps:
    let
      line = lines[gap.line]
      comment = line[gap.at .. ^1]
    if not line.isWide or spanned[gap.line] or comment.startsWith("##") or
        comment.startsWith("#["):
      continue
    if (' '.repeat(line.indentOf) & comment).isWide: continue
    result.add gap


func checkCommentsAbove*(path, source: string): seq[Report] =
  ## Report plain `#` trailing comment that widens its line past `LINE_MAX` and fits above it.
  for gap in source.liftedComments:
    result.add initReport(
      path,
      gap.line + 1,
      Rule.CommentAbove,
      "Trailing comment widening line past `" & $LINE_MAX & "` takes own line above; got `" &
          $source.split('\n')[gap.line].runeLen & "` runes.",
    )


func fixCommentsAbove*(path, source: string): Fix =
  ## Move each comment check reports to own line above, last first; both lines trace to its line.
  let found = source.liftedComments
  var
    lines = source.split('\n')
    origin = toSeq(1 .. lines.len)
  for gap in found.reversed:
    let
      line = lines[gap.line]
      lifted = @[' '.repeat(line.indentOf) & line[gap.at .. ^1], line[0 ..< gap.at - gap.spaces]]
    lines = lines[0 ..< gap.line] & lifted & lines[gap.line + 1 .. ^1]
    origin = origin[0 ..< gap.line] & origin[gap.line].repeat(2) & origin[gap.line + 1 .. ^1]
  result.source = lines.join("\n")
  for gap in found: result.fixed.add initReport(path, gap.line + 1, Rule.CommentAbove)
  if found.len > 0: result.origin = origin


func fixWhitespace*(path, source: string): Fix =
  ## Cut whitespace each line ends with, CR of CRLF ending included.
  var lines = source.split('\n')
  for i, line in lines.mpairs:
    if not line.isEndedInWhitespace: continue
    line = line.strip(leading = false, chars = TRAILING_WHITESPACE)
    result.fixed.add initReport(path, i + 1, Rule.TrailingWhitespace)
  result.source = lines.join("\n")


func fixEnding*(path, source: string): Fix =
  ## End non-empty source with exactly one newline; empty source has no one fix.
  result.source = source
  if source.len == 0 or (source.endsWith("\n") and not source.endsWith("\n\n")): return
  result.source = source.strip(leading = false, chars = {'\n'}) & "\n"
  result.fixed.add initReport(path, 0, Rule.FileEnding)


func tabsInStrings(source: string): seq[int] =
  ## Find byte offset of each tab inside one-line string that is neither raw nor long.
  ##   Raw string, i.e. one glued after identifier (`r"…"`, `fmt"…"`), reads backslash as itself.
  for t in source.tokens:
    if t.kind != TokenKind.Text or t.lastLine(source) != t.line: continue
    if source.continuesWith(LONG_QUOTE, t.first): continue
    if t.first > 0 and source[t.first - 1] in IDENTIFIER_CHARS: continue
    for k in t.first ..< t.after:
      if source[k] == '\t': result.add k


func fixTabs(path, source: string; held: Held): Fix =
  ## Write each tab `tabsInStrings` finds as `\t`, last first, unless held line would be wide.
  let
    tabs = source.tabsInStrings
    starts = source.lineStarts
  var lines = source.split('\n')
  for line in 0 ..< lines.len:
    let
      first = starts[line]
      after = first + lines[line].len
      found = tabs.filterIt(it >= first and it < after)
    if found.len == 0: continue
    var shaped = lines[line]
    for k in found.reversed: shaped = shaped[0 ..< k - first] & "\\t" & shaped[k - first + 1 .. ^1]
    if held.isHeld(line + 1) and shaped.isWide and not lines[line].isWide: continue
    lines[line] = shaped
    result.fixed.add initReport(path, line + 1, Rule.TabInString)
  result.source = lines.join("\n")


func fixComments*(path, source: string; held: Held): Fix =
  ## Set two spaces before each trailing comment's marker, unless held line would then be wide.
  var lines = source.split('\n')
  for gap in source.gaps:
    if gap.spaces == COMMENT_GAP: continue
    let
      line = lines[gap.line]
      spaced = line[0 ..< gap.at - gap.spaces] & ' '.repeat(COMMENT_GAP) & line[gap.at .. ^1]
    if held.isHeld(gap.line + 1) and spaced.isWide and not line.isWide: continue
    lines[gap.line] = spaced
    result.fixed.add initReport(path, gap.line + 1, Rule.TrailingComment)
  result.source = lines.join("\n")


func blankRuns(lines: seq[string]): seq[BlankRun] =
  ## Find each run of blank lines beside banner whose count breaks X.2, run between two lines
  ##   of text; banner after banner other than parent and child gets no count from X.2.
  var above = -1
  for i, line in lines:
    if line.len == 0: continue
    if above >= 0:
      let (upper, lower) = (lines[above].tierOfBanner, line.tierOfBanner)
      var run = BlankRun(first: above + 1, count: i - above - 1, wanted: -1)
      if lower > 0 and (upper == 0 or (upper == 1 and lower == 2)):
        run.wanted = LUT_BLANKS_BY_TIER[lower]
        run.banner = i
        run.tier = lower
        run.is_before = true
      elif upper > 0 and lower == 0:
        run.wanted = BLANKS_AFTER_BANNER
        run.banner = above
        run.tier = upper
      if run.wanted >= 0 and run.count != run.wanted: result.add run
    above = i


func checkBanners*(path, source: string): seq[Report] =
  ## Report blank lines beside banner other than X.2 asks: three before first tier, two before
  ##   second, one after either.
  ##   Named by its suite and `fixes.nim` alone until static pass calls it (`fixes.nim`).
  let runs = source.split('\n').blankRuns
  for run in runs:
    let message =
      if not run.is_before: "Banner takes one blank line after it"
      elif run.tier == 1: "First-tier banner takes three blank lines before it"
      else: "Second-tier banner takes two blank lines before it"
    result.add initReport(
      path,
      run.banner + 1,
      Rule.BannerSpacing,
      message & "; got `" & $run.count & "`.",
    )


func fixBanners(path, source: string): Fix =
  ## Set each run of blank lines check reports to count X.2 asks, last run first.
  var
    lines = source.split('\n')
    origin = toSeq(1 .. lines.len)
  let runs = lines.blankRuns
  for run in runs.reversed:
    let
      after = run.first + run.count
      kept = origin[run.first ..< run.first + min(run.count, run.wanted)]
      inserted = newSeq[int](run.wanted - kept.len)
    lines = lines[0 ..< run.first] & newSeq[string](run.wanted) & lines[after .. ^1]
    origin = origin[0 ..< run.first] & kept & inserted & origin[after .. ^1]
  result.source = lines.join("\n")
  for run in runs: result.fixed.add initReport(path, run.banner + 1, Rule.BannerSpacing)
  if runs.len > 0: result.origin = origin


const FORM_STEPS*: array[5, Step] = [
  guarded(fixWhitespace),
  guarded(fixEnding),
  widening(fixTabs),
  widening(fixComments),
  guarded(fixBanners),
]
  ## Form fixers of Nim source in order they run: line ends and ending first, so later fixers
  ##   read clean line ends, which tab, comment and banner fixers each read.
