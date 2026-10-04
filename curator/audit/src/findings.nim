## Define finding record every check emits, plus its order and report form; and render each
##   report of knoller as finding, citing article of its rule.
##   One record shape keeps umbrella trivial: collect, sort, print, count.
##   Message convention (Article IV.4): end by echoing offending value in backticks.
##   Knoller names rule of each report and cites no article; `CITATIONS` holds article of each,
##     indexed by `Rule`, so rule knoller adds without citation fails to compile here.
##     Rewrite renders as `<rule> (<article>)`, so `koch fix` prints `path:line: <rule> fixed`
##     through `render`, as check prints its own, and its dry run prints `path:line: <rule> to
##     fix` from same report. Finding of knoller's check renders its message as written.
##
##   Cost: line `0` marks whole-file findings, so `0` never means first line.
##   Cost: empty path marks branch-level findings (scope, commits) with no file to open.
##   Propagation flag marks finding that rules change leaves for curator wherever it lands,
##     such as stale stamp in contributor record; `scope.isHeld` never holds it.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils]
import ../../knoller/src/knoller


type Finding* = object  ## Define one rule violation located at path and line.
  path*: string  ## Repository-relative path, `/` separated; empty for branch-level.
  line*: int  ## One-based line; `0` when finding concerns whole file.
  message*: string  ## Telegraphic statement, ending with echoed value where one exists.
  is_propagation*: bool  ## Curator's to fix wherever it lands: rules change carried out.


const CITATIONS*: array[Rule, string] = [
  Rule.TrailingWhitespace: "VIII.5",
  Rule.FileEnding: "VIII.5",
  Rule.TabInString: "X.1",
  Rule.TrailingComment: "X.9",
  Rule.BannerSpacing: "X.2",
  Rule.EntryBlock: "V.10",
  Rule.ArticleInComment: "VI.5",
  Rule.TableAlignment: "I.4",
  Rule.MessageValue: "IV.4",
  Rule.AndWithOr: "X.4",
  Rule.NotOverBinary: "X.4",
  Rule.TargetSubject: "STYLE.md §5",
  Rule.DottedCommand: "STYLE.md §5",
  Rule.ReturnResult: "STYLE.md §5",
  Rule.BracketImport: "X.5",
  Rule.ImportRank: "X.5",
  Rule.ImportBrackets: "X.5",
  Rule.SingleBindings: "X.5",
  Rule.StrictFuncs: "STYLE.md §2",
  Rule.ProfilerImport: "STYLE.md §3",
  Rule.StubKeys: "STYLE.md §6",
  Rule.UnorderedList: "X.10",
  Rule.TestBlankLines: "X.2",
  Rule.HelperBlankLines: "STYLE.md §1",
  Rule.DocPosition: "STYLE.md §5",
  Rule.LiteralDefault: "X.12",
  Rule.ExpressionSpacing: "X.9",
  Rule.ParameterSeparators: "STYLE.md §5",
  Rule.TupleSeparators: "STYLE.md §5",
  Rule.SignatureWrapping: "X.3",
  Rule.CallWrapping: "X.3",
  Rule.OperatorWrapping: "STYLE.md §5",
  Rule.ContinuationIndent: "STYLE.md §5",
  Rule.TrailingSeparator: "X.3",
  Rule.CommentAbove: "X.1",
  Rule.Fence: "X.1",
  Rule.FenceHeld: "X.1",
  Rule.Unsettled: "STYLE.md §5",
]
  ## Article each rule of knoller holds, as its report cites it.


func finding*(path: string, line: int, message: string, is_propagation = false): Finding =
  ## Construct finding.
  Finding(path: path, line: line, message: message, is_propagation: is_propagation)


func findingOf*(report: Report): Finding =
  ## Render report of knoller as finding: check's message as written, or rewrite as its rule
  ##   and article, i.e. `expression spacing (X.9)`.
  let message =
    if report.message.len > 0: report.message
    else: $report.rule & " (" & CITATIONS[report.rule] & ")"
  finding(report.path, report.line, message)


func findingsOf*(reports: openArray[Report]): seq[Finding] =
  ## Render each report of knoller as finding, in order given.
  reports.mapIt(it.findingOf)


func `<`*(a, b: Finding): bool =
  ## Order findings by path, then line, then message, so reports are stable.
  if a.path != b.path: return a.path < b.path
  if a.line != b.line: return a.line < b.line
  a.message < b.message


func render*(f: Finding): string =
  ## Render finding as `path:line: message`; line omitted when `0`, path when empty.
  if f.path.len == 0: return f.message
  let location = if f.line == 0: f.path else: f.path & ":" & $f.line
  location & ": " & f.message


proc report*(findings: seq[Finding]) =
  ## Print findings sorted, one per line, then count.
  for f in findings.sorted: echo f.render
  echo $findings.len & " finding(s)."
