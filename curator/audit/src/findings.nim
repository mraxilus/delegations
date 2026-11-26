## Define finding record every check emits, plus its order and report form; and render each
##   report of knoller as finding, citing article of its rule.
##   One record shape keeps umbrella trivial: collect, sort, print, count.
##   Message convention (Article IV.4): end by echoing offending value in backticks.
##   Knoller names rule of each report and cites no article; `CITATIONS` holds article of each,
##     indexed by `Rule`, so rule knoller adds without citation fails to compile here.
##     Rewrite renders as `<rule> (<article>)`, so `koch fix` prints `path:line: <rule> fixed`
##     through `render`, as check prints its own, and its dry run prints `path:line: <rule> to
##     fix` from same report.
##     Message of knoller's check reads `<sentence>; got <value>.`, or `<sentence>.`, and names
##       no article (ruling D2 of #505); finding takes article where sentence ends, as
##       `<sentence> (<article>); got <value>.`, which `koch check` and `koch fix` print.
##     Sentence ends at first `; got ` outside code span, span running to next run of as many
##       backticks, so sentence quoting ``…; got `{value}`.`` ends after quote.
##
##   Cost: rule takes one article, so finding of rule two articles state cites one, as its
##     rewrite does: bracket of one module cites X.5, though STYLE.md §5 states it; signature
##     and call wrapping cite X.3, and operator wrapping STYLE.md §5, though X.1 states it too.
##   Cost: line `0` marks whole-file findings, so `0` never means first line.
##   Cost: empty path marks branch-level findings (scope, commits) with no file to open.
##   Propagation flag marks finding that rules change leaves for curator wherever it lands,
##     such as stale stamp in contributor record; `scope.isHeld` never holds it.
##   Finding prints through renderer of knoller (`report.nim`, STYLE.md §3), in form caller asks:
##     message cut where its sentence ends, as each report of knoller is (`initNotice`), so
##     summary keeps its article (D1 of #1002). Rule, expected value, help, column and span
##     print where check gives them; report of knoller gives each of its own (`toFinding`).
##     Short text of those parts is what each suite compares (`brief`, D3 of #1002).
##   Rewrite is no finding, so `koch fix` prints it on one line of its own (`render`).

{.experimental: "strictFuncs".}

import std/[algorithm, options, sequtils, strutils, tables]
import ../../knoller/src/knoller
import ./checks

export checks


type Finding* = object  ## Define one rule violation located at path and line.
  path*: string  ## Repository-relative path, `/` separated; empty for branch-level.
  line*: int  ## One-based line; `0` when finding concerns whole file.
  rule*: string  ## Id of rule finding breaks; empty where check names none.
  message*: string  ## Telegraphic statement, ending with echoed value where one exists.
  expected*: Option[string]  ## Value rule asks for, beside sentence; none where check gives none.
  help*: string  ## What reader does about finding; empty where check gives none.
  column*: int  ## One-based column, in runes; `0` where check names none.
  span*: int  ## Runes finding covers from column; `0` where check names none.
  is_propagation*: bool  ## Curator's to fix wherever it lands: rules change carried out.
  is_scope*: bool  ## Branch's own to fix wherever it lies: path outside its scope.


const CITATIONS*: array[Rule, string] = [
  Rule.Conversion: "STYLE.md §5",
  Rule.UsedMarker: "STYLE.md §5",
  Rule.PureFunc: "STYLE.md §1",
  Rule.WhitespaceTrailing: "VIII.5",
  Rule.FileEnding: "VIII.5",
  Rule.LineEnding: "VIII.5",
  Rule.TabInString: "X.1",
  Rule.Tab: "X.1",
  Rule.LineWidth: "X.1",
  Rule.CommentTrailing: "X.9",
  Rule.SpacingBanner: "X.2",
  Rule.BlockEntry: "V.10",
  Rule.Abbreviation: "V.6",
  Rule.VerbAction: "V.3",
  Rule.NameBoolean: "V.4",
  Rule.TableLookup: "V.5",
  Rule.CaseName: "V.1",
  Rule.CaseMember: "V.11",
  Rule.LetterPlaceholder: "V.12",
  Rule.Notation: "III.5",
  Rule.WordGlobal: "V.10",
  Rule.HeadRepresentation: "V.2",
  Rule.CutName: "V.2",
  Rule.SuffixRoutine: "V.3",
  Rule.SuffixGeneric: "V.13",
  Rule.NameCollection: "V.6",
  Rule.AliasLandmark: "V.8",
  Rule.ArticleInComment: "VI.5",
  Rule.FormComment: "VI.10",
  Rule.OutlineDoc: "VI.2",
  Rule.SummaryDoc: "VI.1",
  Rule.ValueMessage: "IV.4",
  Rule.BracesInterpolation: "STYLE.md §3",
  Rule.EchoMessage: "IV.4",
  Rule.AndWithOr: "X.4",
  Rule.NotOverBinary: "X.4",
  Rule.ParenthesesNeedless: "X.4",
  Rule.SubjectTarget: "STYLE.md §5",
  Rule.PrefixConversion: "STYLE.md §5",
  Rule.CallGeneration: "STYLE.md §5",
  Rule.CommandDotted: "STYLE.md §5",
  Rule.ReturnResult: "STYLE.md §5",
  Rule.ImportBracket: "X.5",
  Rule.RankImport: "X.5",
  Rule.BracketsImport: "X.5",
  Rule.BracketModule: "STYLE.md §5",
  Rule.BindingsSingle: "X.5",
  Rule.StrictFuncs: "STYLE.md §2",
  Rule.ImportProfiler: "STYLE.md §3",
  Rule.KeysStub: "STYLE.md §6",
  Rule.ConsumerUsed: "STYLE.md §2",
  Rule.PushForeign: "STYLE.md §2",
  Rule.FamilyCompileTime: "STYLE.md §2",
  Rule.StaticWhen: "STYLE.md §3",
  Rule.SeedRandom: "STYLE.md §6",
  Rule.HeaderStub: "STYLE.md §6",
  Rule.OutputDebug: "VIII.5",
  Rule.ReasonSkip: "IX.9",
  Rule.WaitFixed: "IX.12",
  Rule.ListUnordered: "X.10",
  Rule.BlockConfiguration: "X.11",
  Rule.LinesBlankTest: "X.2",
  Rule.LinesBlankHelper: "STYLE.md §1",
  Rule.LinesBlankDefinition: "X.2",
  Rule.PositionDoc: "STYLE.md §5",
  Rule.DefaultLiteral: "X.12",
  Rule.SpacingExpression: "X.9",
  Rule.SeparatorsParameter: "STYLE.md §5",
  Rule.SeparatorsTuple: "STYLE.md §5",
  Rule.WrappingSignature: "X.3",
  Rule.WrappingCall: "X.3",
  Rule.WrappingOperator: "STYLE.md §5",
  Rule.IndentContinuation: "STYLE.md §5",
  Rule.DocMissing: "VI.1",
  Rule.CommentAbove: "X.1",
  Rule.CommentStage: "VI.4",
  Rule.Fence: "X.1",
  Rule.FenceHeld: "X.1",
]
  ## Article each rule of knoller holds, as its report cites it.


func finding*(
  path: string,
  line: int,
  message: string,
  is_propagation = false,
  is_scope = false,
  rule = "",
  expected = none(string),
  help = "",
  column = 0,
  span = 0,
): Finding =
  ## Construct finding.
  Finding(
    path: path,
    line: line,
    rule: rule,
    message: message,
    expected: expected,
    help: help,
    column: column,
    span: span,
    is_propagation: is_propagation,
    is_scope: is_scope,
  )


func finding*(
  path: string,
  line: int,
  check: Check,
  message: string,
  expected = none(string),
  help = "",
  column = 0,
  span = 0,
  is_propagation = false,
  is_scope = false,
): Finding =
  ## Construct finding of check of koch, under its id (D4 of #1002).
  finding(
    path,
    line,
    message,
    is_propagation,
    is_scope,
    check.id,
    expected,
    help,
    column,
    span,
  )


func toFinding*(report: Report): Finding =
  ## Render report of knoller as finding, citing article of its rule: rewrite as rule and
  ##   article, i.e. `expression spacing (X.9)`; check's message with article where sentence
  ##   ends, i.e. ``Range operator takes no space (X.9); got `0 .. n`.``. Knoller finds where
  ##   sentence ends (`sentenceEnd`), as renderer cuts message there too. Finding takes id of
  ##   rule, and expected value, help, column and span of report.
  let
    article = " (" & CITATIONS[report.rule] & ")"
    at = report.message.sentenceEnd
    message =
      if report.message.len == 0: $report.rule & article
      else: report.message[0..<at] & article & report.message[at .. ^1]
  finding(
    report.path,
    report.line,
    message,
    rule = report.rule.id,
    expected = report.expected,
    help = report.help,
    column = report.column,
    span = report.span,
  )


func toFindings*(reports: openArray[Report]): seq[Finding] =
  ## Render each report of knoller as finding, in order given.
  reports.mapIt(it.toFinding)


func `<`*(a, b: Finding): bool =
  ## Order findings by path, then line, then message, so reports are stable.
  if a.path != b.path: return a.path < b.path
  if a.line != b.line: return a.line < b.line
  a.message < b.message


func render*(f: Finding): string =
  ## Render finding as `path:line: message`, as rewrite prints; line omitted when `0`, path when
  ##   empty.
  if f.path.len == 0: return f.message
  let location = if f.line == 0: f.path else: f.path & ":" & $f.line
  location & ": " & f.message


func toNotice*(f: Finding, source = none(string), is_warning = false): Notice =
  ## Read finding as renderer prints it (STYLE.md §3), message cut where its sentence ends, so
  ##   summary keeps article (D1 of #1002); text of its line where caller read it.
  initNotice(
    f.path, f.line, f.rule, f.message, f.expected, f.help, f.column, f.span, source, is_warning
  )


func brief*(f: Finding): string =
  ## Read short text of parts of finding, as each suite compares it (D3 of #1002).
  f.toNotice.brief


func rendered*(
  findings: openArray[Finding],
  form: Form,
  is_colored = false,
  sources = initTable[string, string](),
  is_warning = false,
): seq[string] =
  ## Render each finding, sorted, through renderer in form asked, with text of its line where
  ##   `sources` holds its file by path; terminal form takes blank line before each finding.
  for f in findings.sorted:
    let
      lines = sources.getOrDefault(f.path).split('\n')
      source =
        if f.line > 0 and f.line <= lines.len and f.path in sources: some(lines[f.line - 1])
        else: none(string)
    if form == Form.Terminal: result.add ""
    result.add f.toNotice(source, is_warning).render(form, is_colored)


proc report*(
  findings: seq[Finding],
  form = Form.Line,
  is_colored = false,
  sources = initTable[string, string](),
) =
  ## Print findings sorted, through renderer in form asked (`rendered`), then count; terminal
  ##   form takes blank line before count where any finding printed.
  for line in findings.rendered(form, is_colored, sources): echo line
  if form == Form.Terminal and findings.len > 0: echo ""
  echo $findings.len & " finding(s)."
