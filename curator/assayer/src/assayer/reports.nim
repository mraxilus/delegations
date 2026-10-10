## Write each line assayer prints, as test runners that read well write theirs (nextest, pytest,
##   testament).
##   Report opens with line naming what starts (`lineStart`), as nextest opens: something prints at
##     once, and it says how many runs go, of how many files, how many at once.
##   Refused file prints as `error: <path>: <reason>` (`lineRefusal`), as compiler prints error;
##     reason is lowercase with no period, after rustc.
##   Run line opens with status word, `PASS` or `FAIL`, then duration, file, backend and
##     configuration, each in column of its own (`lineRun`): eye scans first column, and `FAIL`
##     greps, as testament means its `FAIL:`. Widths come from plan (`widthsOf`), so columns align
##     from first line however lines arrive. Word, not symbol, so text reads same without color.
##   Failure prints after every run line, as pytest prints it, so list stays one line for each run
##     (`linesFailure`): header naming run and reason, excerpt of output of step that failed,
##     command that reproduces it, and log holding whole output (`textLog`).
##   Excerpt drops what explains nothing (`excerptOf`): hints and progress dots of compiler, frames
##     of traceback outside working directory, tests `std/unittest` passed or skipped, and suite
##     left empty. Then it keeps last
##     `LINES_EXCERPT_MAX` lines, since compiler and program both end on their error, and says how
##     many it cut. Common indent goes, so excerpt keeps its shape under one indent.
##   Count closes report (`lineSummary`): runs, time, passed, then failed and refused files where
##     any, since clig.dev puts what matters most at end.
##   Path below working directory prints relative to it (`relative`), in every line.
##   Color marks status, reason and count, and only where `as_color` asks (`painted`); caller
##     decides it from terminal and environment (`command.nim`).
##
##   Cost: line wider than terminal wraps; no line is cut, so text stays whole for search.
##   Cost: duration over `99.9s` widens its column, and shifts columns after it on that line.

{.experimental: "strictFuncs".}

import std/[options, os, strutils, times]
from std/unicode import runeLen
import ./[plans, runs]


const
  STATUS_PASS* = "PASS"  ## Status word of run that passed.
  STATUS_FAIL* = "FAIL"  ## Status word of run that failed.
  LINES_EXCERPT_MAX* = 20  ## Lines excerpt keeps at most, counted from end of output.
  WIDTH_DURATION = 5  ## Columns duration takes, right-aligned, as `99.9s`.
  GAP = "  "  ## Space between two columns of run line.
  INDENT_EXCERPT = "    "  ## Indent of each line of excerpt, under header of failure.
  INDENT_NOTE = "  "  ## Indent of command and log, under header of failure.
  CODE_RESET = "\e[0m"  ## Escape ending color.
  CODE_BOLD = "\e[1m"  ## Escape opening bold.
  CODE_DIM = "\e[2m"  ## Escape opening dim text.
  CODE_RED = "\e[31m"  ## Escape opening red.
  CODE_GREEN = "\e[32m"  ## Escape opening green.


type Widths* = object  ## Define columns of run line, read from plan, so every line aligns.
  file*: int  ## Width of widest file, in runes.
  target*: int  ## Width of widest backend word.


func painted(text, code: string; as_color: bool): string =
  ## Write text in color code where `as_color` asks; text alone otherwise.
  if as_color: code & text & CODE_RESET else: text


func plural(count: int, noun: string): string =
  ## Write count and noun, plural where count is other than one.
  $count & " " & noun & (if count == 1: "" else: "s")


func padded(text: string, width: int): string =
  ## Write text padded with spaces to width, counted in runes, so path beyond ASCII aligns too.
  text & ' '.repeat(max(0, width - text.runeLen))


func relative*(text, root: string): string =
  ## Write text with each path below `root` relative to it, as reader at `root` names it; root of
  ##   file system leaves text as written, since its prefix is every separator.
  let prefix = if root.endsWith(DirSep): root else: root & DirSep
  if prefix.len <= 1: text else: text.replace(prefix, "")


func shown*(path, root: string): string =
  ## Write path of test file as report shows it: normalized, and relative where below `root`.
  path.absoluteOf(root).relative(root)


func seconds*(duration: Duration): string =
  ## Write duration in seconds to one decimal, as `6.1s`.
  formatFloat(float(duration.inMilliseconds) / 1000, ffDecimal, 1) & "s"


func widthsOf*(runs: openArray[Run], root: string): Widths =
  ## Read widths of file and backend columns: widest of each among runs.
  for run in runs:
    result.file = max(result.file, run.file.shown(root).runeLen)
    result.target = max(result.target, len($run.target))


func lineStart*(runs, files, threads: int): string =
  ## Write line opening report: how many runs start, of how many files, how many at once.
  "Starting " & plural(runs, "run") & " of " & plural(files, "file") & ", " & $threads &
      " at once"


func lineRefusal*(path, refusal, root: string; as_color = false): string =
  ## Write line of refused file: `error:`, path, then reason.
  painted("error:", CODE_BOLD & CODE_RED, as_color) & " " & path.shown(root) & ": " &
      refusal.relative(root)


func lineRun*(run: Run, outcome: Outcome, widths: Widths, root: string, as_color = false): string =
  ## Write line of run: status, duration, file, backend, then configuration where it has one.
  let status =
    if run.failureOf(outcome).len == 0: painted(STATUS_PASS, CODE_GREEN, as_color)
    else: painted(STATUS_FAIL, CODE_BOLD & CODE_RED, as_color)
  [
    status,
    painted(outcome.durationOf.seconds.align(WIDTH_DURATION), CODE_DIM, as_color),
    run.file.shown(root).padded(widths.file),
    ($run.target).padded(widths.target),
    run.configuration,
  ].join(GAP).strip(leading = false)


func isFrameOutside(line: string): bool =
  ## Decide whether line is frame of traceback outside working directory, i.e. absolute path,
  ##   position in brackets, then routine alone, as `/nim/lib/system/fatal.nim(62) sysFatal`.
  ##   Position is line, or line and column as frame of compile time prints it; error line names
  ##     more than routine after its position, so it stays.
  ##   Line is read relative already (`relative`), so frame below working directory stays.
  let s = line.strip
  if not s.isAbsolute: return false
  let
    opening = s.rfind('(')
    closing = s.find(')', max(0, opening))
  opening > 0 and closing > opening + 1 and
      s[opening+1..<closing].replace(", ", "").allCharsInSet(Digits) and
      s.continuesWith(" ", closing + 1) and ' ' notin s[closing+2 .. ^1]


func isNoise(line: string): bool =
  ## Decide whether line of output explains nothing of failure: hint or progress of compiler, frame
  ##   of traceback outside working directory, or test `std/unittest` passed or skipped.
  let s = line.strip
  (s.len > 0 and s.allCharsInSet({'.'})) or s.startsWith("CC: ") or
      (s.endsWith("]") and (s.startsWith("Hint: ") or " Hint: " in s)) or line.isFrameOutside or
      s.startsWith("[OK] ") or s.startsWith("[SKIPPED] ")


func excerptOf*(output, root: string): tuple[lines: seq[string], cut: int] =
  ## Read lines of output that explain failure, at most `LINES_EXCERPT_MAX` from its end, common
  ##   indent taken off; `cut` counts lines left above.
  ##   Noise goes (`isNoise`), then each suite left empty, i.e. next line with text opens suite
  ##     too, or none follows; blank lines join into one, and none stands at either end.
  var lines: seq[string]
  for line in output.relative(root).splitLines:
    if not line.isNoise: lines.add line.strip(leading = false)

  # Drop each suite left empty, and each blank line that follows another or opens excerpt.
  var kept: seq[string]
  for k, line in lines:
    if line.strip.startsWith("[Suite] "):
      var j = k + 1
      while j < lines.len and lines[j].len == 0: inc j
      if j == lines.len or lines[j].strip.startsWith("[Suite] "): continue
    if line.len == 0 and (kept.len == 0 or kept[^1].len == 0): continue
    kept.add line
  while kept.len > 0 and kept[^1].len == 0: kept.setLen(kept.len - 1)

  # Keep tail, then take indent all its lines share off.
  result.cut = max(0, kept.len - LINES_EXCERPT_MAX)
  var indent = int.high
  for line in kept[result.cut .. ^1]:
    if line.len > 0: indent = min(indent, line.len - line.strip(trailing = false).len)
  for line in kept[result.cut .. ^1]:
    result.lines.add (if line.len == 0: line else: line[indent .. ^1])


func linesFailure*(run: Run, outcome: Outcome, root: string, as_color = false): seq[string] =
  ## Write block of failed run: header naming run and reason, excerpt of output of step that
  ##   failed, then command reproducing that step, and log holding whole output.
  ##   Step that failed is program where it ran, since program runs only after clean compile.
  ##     Program reruns as it ran; compile reruns without cache or program of run (`Run.rerun`).
  ##   Refused run ran nothing, so its block is header alone.
  let name = [run.file.shown(root), $run.target, run.configuration].join(" ").strip
  result.add painted(STATUS_FAIL, CODE_BOLD & CODE_RED, as_color) & " " & name & ": " &
      run.failureOf(outcome).relative(root)
  let step = outcome.execution.get(outcome.compile)
  if step.command.len == 0: return
  let (lines, cut) = step.output.excerptOf(root)
  if cut > 0: result.add INDENT_EXCERPT & painted("… " & plural(cut, "line") & " above", CODE_DIM,
      as_color)
  for line in lines: result.add (INDENT_EXCERPT & line).strip(leading = false)
  let rerun = if outcome.execution.isSome: step.command else: run.rerun
  result.add INDENT_NOTE & painted("rerun:", CODE_DIM, as_color) & " " & rerun.relative(root)
  result.add INDENT_NOTE & painted("log:", CODE_DIM, as_color) & " " & run.logOf.relative(root)


func textLog*(outcome: Outcome): string =
  ## Write log of run: each step's command, its whole output, then its exit code and time.
  for step in [some(outcome.compile), outcome.execution]:
    if step.isNone: continue
    result.add "$ " & step.get.command & "\n" & step.get.output
    if step.get.output.len > 0 and not step.get.output.endsWith("\n"): result.add "\n"
    result.add(
      if step.get.failure.len > 0: "[cannot start: " & step.get.failure & "]\n"
      else: "[exit " & $step.get.code & " in " & step.get.duration.seconds & "]\n"
    )


func lineSummary*(runs, failed, refused: int; duration: Duration; as_color = false): string =
  ## Write line closing report: runs and time, passed, then failed and refused files where any.
  var text = plural(runs, "run") & " in " & duration.seconds & ": " & $(runs - failed) & " passed"
  if failed > 0: text.add ", " & $failed & " failed"
  if refused > 0: text.add "; " & plural(refused, "file") & " refused"
  let code = if failed > 0 or refused > 0: CODE_BOLD & CODE_RED else: CODE_BOLD & CODE_GREEN
  painted(text, code, as_color)
