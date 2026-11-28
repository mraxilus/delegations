## Define report every fixer and check of knoller emits, and fix record every fixer returns.
##   Report names rule rewritten or broken, at path and line; finding of check carries its
##     message too, ending with echoed value (Article IV.4). Caller renders both:
##     `curator/audit` cites article of each rule, so `koch fix` prints `path:line: <rule>
##     (<article>) fixed`.
##   Message reads `<sentence>; got <value>.`, or `<sentence>.`, and names no article, since
##     knoller runs on any repository; caller cites article where sentence ends (`toFinding` of
##     `curator/audit`), and command line names rule by id.
##   Fixer that inserts or deletes lines records input line each output line came from, and
##     `chain` traces every later report through it. So each report names line of source as
##     given, whatever fixers ran before; fixer keeping its lines records nothing.
##   Widener is fixer whose rewrite may widen its line past `LINE_MAX`: off held line it
##     rewrites freely, and wrapping that runs after it breaks line; on held line it keeps
##     width guard, i.e. refuses rewrite that makes narrow line wide. Held lines are sorted
##     `seq`, never set or table, so every reading of them runs in one order.
##   Prover step's rewrite stands only where parser of code's compiler proves it (`Proofs`):
##     step reads answer for source it sees, and where none is held, writes nothing and asks
##     (`Fix.asked`). Caller runs compiler on what is asked and runs chain again, so chain stays
##     pure, and same answers give same output.
##   Dialect of Nim file, module, script or package, decides which idiom checks and fixers it
##     takes; `idioms.nim` and `chain.nim` both read it, so it stands here, below both.
##   Path fixer reads is `/` separated: repository-relative from `koch`, absolute from command
##     line on every platform (`command.toAbsolute`). Rule reading layout from it reads test file,
##     stub and umbrella here alone, each from names of path below folder of its package
##     (`partPackage`), so each meaning is written once.
##   Folder of nearest nimble file is root of package (#886): test file lies below `tests`
##     of root (`partTests`), and umbrella is `src/<name>.nim` beside `<name>.nimble`, whatever
##     folder holds both (`isUmbrella`).
##   Caller names nimble file nearest each file, written as its path is, empty where none stands
##     above (`nimble`); placed fixer takes it (`Placed`), as prover step takes answers. Lookup
##     reads file system, so caller makes it, and every rule here stays pure.
##   Caller names constants other modules of package export, too (`constants`), and reading
##     fixer takes them (`Reader`): rule reads one file, and caller reads its package.
##   Stub is read as testament reads category (#443), i.e. directory directly under `tests` of
##     package, whose tests are files `t*.nim` at any depth (`isTestFile`, `processCategory` of
##     `testament/categories.nim`): file there is stub where its source opens with testament
##     header, and suite module, which opens with none, stays suite. Stub `test_*` directly
##     under `tests` holds with header or without, so its missing header stays finding. So
##     `isStub` takes source beside path, and each caller passes source it holds.
##   Rejected: path alone, which reads each suite module of category as stub, so missing header
##     and profiler import would report on each, e.g. `tests/suites/test_names.nim`; header
##     test at each caller, which writes category rule three times.
##   Rejected: last directory `tests` of whole path, and umbrella as `<folder>/src/<folder>.nim`,
##     which read directories above repository and name of its clone; folder and name of
##     package passed apart, two values that can disagree, where nimble file gives both.
##
##   Cost: line `0` marks whole-file report, so `0` never means first line.
##   Cost: header of category file reads at its first byte alone, where testament reads it
##     anywhere in first ten lines with no space before it; file of category whose header stands
##     lower is no stub, so it takes no stub rule. Stub of STYLE.md §6 opens with header.
##   Cost: file whose caller names no nimble file takes no rule of test file, stub or umbrella:
##     fewer findings, never false one.
##   Cost: package whose `srcDir` is not `src` has no umbrella here.

{.experimental: "strictFuncs".}

import std/[algorithm, options, sequtils, strutils, tables]
import ./[report, rules]

export rules


type  # TODO: Document.
  Report* = object  ## Define one rewrite or finding, located at path and line.
    path*: string  ## Path fixer read, `/` separated: repository-relative, or absolute.
    line*: int  ## One-based line; `0` when report concerns whole file.
    rule*: Rule  ## Rule rewritten or broken.
    message*: string  ## Finding's statement, ending with echoed value; empty for rewrite.
    expected*: Option[string]  ## Value rule asks for, beside sentence; none where check gives none.
    help*: string  ## What reader does about finding; empty where check gives none.
    column*: int  ## One-based column, in runes; `0` where check names none.
    span*: int  ## Runes finding covers from column; `0` where check names none.

  Fix* = object  ## Define source fixer returns, with one report per rewrite.
    source*: string  ## Text after fix; input itself where nothing broke rule.
    fixed*: seq[Report]  ## Path and line of input rewritten, with rule fixed.
    origin*: seq[int]  ## Input line of each output line, `0` where inserted; empty if none moved.
    unsettled*: string
      ## Why fix leaves source as written, as fixers still change it after last round; empty
      ##   where it settles. No rule names it, since fault is tool's.
    asked*: seq[string]  ## Source whose rewrite parser must prove and no answer holds yet.

  Held* = object  ## Define lines whose width guard holds: every line, or lines listed.
    is_every*: bool  ## Every line held, so widener writes no wide line, as fixer before it.
    lines*: seq[int]  ## One-based lines held, sorted, each once; read where not every.

  Fixer* = proc (path, source: string): Fix {.nimcall, noSideEffect.}
    ## Define fixer of one rule: source in, fixed source and its reports out.

  Widener* = proc (path, source: string; held: Held): Fix {.nimcall, noSideEffect.}
    ## Define fixer whose rewrite may widen line: free off held lines, width guard on them.

  Proofs* = object  ## Define answers of parser of code's compiler, by source it was asked.
    answers*: Table[string, seq[int]]
      ## Byte offset of `(` of each group whose removal parser reads as same tree.

  Proven* = proc (path, source: string; proofs: Proofs): Fix {.nimcall, noSideEffect.}
    ## Define fixer whose rewrite parser must prove: writes what proofs answer, asks for rest.

  Placed* = proc (path, source, nimble: string): Fix {.nimcall, noSideEffect.}
    ## Define fixer whose rule reads where file lies in its package, from nimble file nearest it.
  Reader* = proc (path, source: string; constants: seq[string]): Fix {.nimcall, noSideEffect.}
    ## Define fixer whose rule reads names of constants other modules of its package export.

  Configurations* = object
    ## Define default of each configuration constant of package, as its define gives it.
    defaults*: Table[string, bool]  ## Value constant takes in build with no define, by name.
    complements*: Table[string, string]  ## Constant written `not` of other, both ways, by name.

  Configuring* =
    proc (path, source: string; configurations: Configurations): Fix {.nimcall, noSideEffect.}
    ## Define fixer whose rule reads default of each configuration of package.

  KindStep* {.pure.} = enum
    ## Define how step reads lines held, answers of parser, nimble file nearest file, constants
    ##   of package and defaults of its configurations.
    Guarded  ## Fixer guarded on every line.
    Widening  ## Widener, off held lines.
    Proving  ## Fixer writing what parser proves, guarded on every line.
    Placing  ## Fixer reading nimble file nearest file, guarded on every line.
    Reading  ## Fixer reading constants other modules of package export, guarded on every line.
    Configuring  ## Fixer reading defaults of configurations, guarded on every line.

  Step* = object  ## Define one fixer of chain, of one kind.
    case kind*: KindStep
    of KindStep.Guarded: fixer*: Fixer
    of KindStep.Widening: widener*: Widener
    of KindStep.Proving: proven*: Proven
    of KindStep.Placing: placed*: Placed
    of KindStep.Reading: reader*: Reader
    of KindStep.Configuring: configuring*: Configuring

  Dialect* {.pure.} = enum  ## Define which Nim source file holds, which decides fixers it takes.
    Module  ## `.nim`, which module's idiom checks and fixers read too.
    Script  ## `.nims`.
    Package  ## `.nimble`.


const  # TODO: Document.
  EVERY* = Held(is_every: true)  ## Held of every line, as each widener's two-argument form.
  DIRECTORY_SOURCE = "src"  ## Directory of package that nimble puts its umbrella in.
  DIRECTORY_TESTS = "tests"  ## Directory of package that testament reads its tests from.
  DIRECTORY_TOOLS = "tools"  ## Directory of package that holds its programs of build and check.
  EXTENSIONS*: array[Dialect, string] = [".nim", ".nims", ".nimble"]
    ## Extension of file of each dialect.
  HEADER_TESTAMENT* = "discard \"\"\""
    ## Opening of stub's testament header, which stands before module's header docs.
  PREFIX_GOT = "; got "  ## Text that ends sentence of message, before value it echoes.


func initReport*(
  path: string,
  line: int,
  rule: Rule,
  message = "",
  expected = none(string),
  help = "",
  column = 0,
  span = 0,
): Report =
  ## Construct report: rewrite where message is empty, finding of check otherwise.
  Report(
    path: path,
    line: line,
    rule: rule,
    message: message,
    expected: expected,
    help: help,
    column: column,
    span: span,
  )


func sentenceEnd*(message: string): int =
  ## Find offset where sentence of message ends: first `; got ` outside code span, else its
  ##   closing `.`, else its end. Code span runs to next run of as many backticks, so sentence
  ##   quoting ``…; got `{value}`.`` ends after quote.

  func backticksAt(at: int): int =
    ## Count backticks of run opening at offset of message.
    while at + result < message.len and message[at+result] == '`': inc result

  var k = 0
  while k < message.len:
    let run = backticksAt(k)
    if run > 0:
      # Skip code span to next run of as many backticks; run none closes is plain text.
      var close = k + run
      while close < message.len and backticksAt(close) != run:
        close += max(1, backticksAt(close))
      k = if close < message.len: close + run else: k + run
    elif message.continuesWith(PREFIX_GOT, k): return k
    else: inc k
  if message.endsWith('.'): message.high else: message.len


func lowercased(sentence: string): string =
  ## Lowercase first letter of sentence, where its first word is no word in capitals, as `CRLF`.
  if sentence.len > 1 and sentence[0] in {'A' .. 'Z'} and sentence[1] notin {'A' .. 'Z'}:
    sentence[0].toLowerAscii & sentence[1 .. ^1]
  else: sentence


func unspanned(value: string): string =
  ## Drop code span that value stands in whole, as `` `x` `` reads `x`, and `` `` `` reads empty;
  ##   value holding other text stays as written.
  if value == "``": return ""
  var run = 0
  while run < value.len and value[run] == '`': inc run
  if run == 0 or value.len <= 2 * run or not value.endsWith('`'.repeat(run)) or
      value[^(run + 1)] == '`':
    return value
  let inner = value[run ..< value.len - run]
  if '`'.repeat(run) in inner: return value
  if run > 1 and inner.len > 1 and inner[0] == ' ' and inner[^1] == ' ': inner[1 .. ^2] else: inner


func initNotice*(
  path: string,
  line: int,
  rule, message: string,
  expected = none(string),
  help = "",
  column = 0,
  span = 0,
  source = none(string),
  is_warning = false,
): Notice =
  ## Read message of check as finding renderer prints (STYLE.md §3), under id of rule caller
  ##   gives: summary, sentence of message with first letter lowercase; actual, value after
  ##   `; got `, out of code span it stands in whole; text of its line where caller read it.
  ##   Check of any tool whose message reads `<sentence>; got <value>.` reads so, as of koch.
  let
    at = message.sentenceEnd
    rest = message[at .. ^1]
  var actual = none(string)
  if rest.startsWith(PREFIX_GOT):
    let value = rest[PREFIX_GOT.len .. ^1]
    actual = some((if value.endsWith('.'): value[0 ..< ^1] else: value).unspanned)
  Notice(
    path: path,
    line: line,
    column: column,
    span: span,
    rule: rule,
    summary: message[0 ..< at].lowercased,
    actual: actual,
    expected: expected,
    help: help,
    source: source,
    is_warning: is_warning,
  )


func toNotice*(report: Report, source = none(string), is_warning = false): Notice =
  ## Read report as finding renderer prints, under id of its rule (`initNotice`).
  initNotice(
    report.path,
    report.line,
    report.rule.id,
    report.message,
    report.expected,
    report.help,
    report.column,
    report.span,
    source,
    is_warning,
  )


func brief*(report: Report): string =
  ## Read short text of parts of report, as test of each check compares it.
  report.toNotice.brief


func partPackage(path, nimble: string): seq[string] =
  ## Read names of path below folder of nimble file nearest it, both written alike; empty where
  ##   none stands above, or path lies outside that folder.
  if nimble.len == 0: return
  let folder = nimble[0..nimble.rfind('/')]
  if path.startsWith(folder): path[folder.len .. ^1].split('/') else: @[]


func partTests(path, nimble: string): seq[string] =
  ## Read names of path below directory `tests` of its package; empty where it lies elsewhere.
  let part = path.partPackage(nimble)
  if part.len > 1 and part[0] == DIRECTORY_TESTS: part[1 .. ^1] else: @[]


func isFileTool*(path, nimble: string): bool =
  ## Decide whether path lies under directory `tools` of its package, at any depth; `nimble` is
  ##   nimble file nearest path, as `isFileTest` reads it.
  let part = path.partPackage(nimble)
  part.len > 1 and part[0] == DIRECTORY_TOOLS


func isFileTest*(path, nimble: string): bool =
  ## Decide whether path lies under directory `tests` of its package, at any depth; `nimble` is
  ##   nimble file nearest path, written as path is, empty where none stands above.
  path.partTests(nimble).len > 0


func isStub*(path, source, nimble: string): bool =
  ## Decide whether file is testament stub: `test_*` directly under `tests` of its package, or
  ##   `t*.nim` at any depth inside category whose source opens with testament header.
  let part = path.partTests(nimble)
  if part.len == 1: return part[0].startsWith("test_")
  part.len > 1 and part[^1].startsWith('t') and part[^1].endsWith(EXTENSIONS[Dialect.Module]) and
      source.startsWith(HEADER_TESTAMENT)


func isUmbrella*(path, nimble: string): bool =
  ## Decide whether path is library umbrella, which nimble puts in `src` of its package under name
  ##   of nimble file: `src/<name>.nim` beside `<name>.nimble`.
  let
    file = nimble[nimble.rfind('/')+1 .. ^1]
    extension = EXTENSIONS[Dialect.Package]
  if file.len <= extension.len or not file.endsWith(extension): return false
  let name = file[0..<file.len-extension.len]
  path.partPackage(nimble) == @[DIRECTORY_SOURCE, name & EXTENSIONS[Dialect.Module]]


func guarded*(fixer: Fixer): Step =
  ## Construct step of fixer guarded on every line.
  Step(kind: KindStep.Guarded, fixer: fixer)


func widening*(widener: Widener): Step =
  ## Construct step of widener, which reads held lines.
  Step(kind: KindStep.Widening, widener: widener)


func proving*(proven: Proven): Step =
  ## Construct step of fixer whose rewrite parser proves, which reads answers.
  Step(kind: KindStep.Proving, proven: proven)


func placing*(placed: Placed): Step =
  ## Construct step of fixer whose rule reads nimble file nearest file.
  Step(kind: KindStep.Placing, placed: placed)


func reading*(reader: Reader): Step =
  ## Construct step of fixer reading constants other modules of package export.
  Step(kind: KindStep.Reading, reader: reader)


func configuring*(configuring: Configuring): Step =
  ## Construct step of fixer whose rule reads defaults of configurations of package.
  Step(kind: KindStep.Configuring, configuring: configuring)


func run*(
  step: Step;
  path, source: string;
  held: Held;
  proofs = Proofs();
  nimble = "";
  constants: seq[string] = @[];
  configurations = Configurations();
): Fix =
  ## Run step on source: widener reads held lines, prover step reads answers, placed fixer reads
  ##   nimble file nearest file, reading fixer reads constants of package, configuring fixer
  ##   reads defaults of configurations, guarded fixer reads none of them.
  case step.kind
  of KindStep.Guarded: step.fixer(path, source)
  of KindStep.Widening: step.widener(path, source, held)
  of KindStep.Proving: step.proven(path, source, proofs)
  of KindStep.Placing: step.placed(path, source, nimble)
  of KindStep.Reading: step.reader(path, source, constants)
  of KindStep.Configuring: step.configuring(path, source, configurations)


func isHeld*(held: Held, line: int): bool =
  ## Decide whether one-based line keeps width guard.
  held.is_every or held.lines.binarySearch(line) >= 0


func traced*(fix: Fix, line: int): int =
  ## Read input line that output line of fix came from; `0` stays whole file or inserted line.
  if line == 0 or fix.origin.len == 0: line else: fix.origin[line - 1]


func chain*(fix, step: Fix): Fix =
  ## Chain fixer's step after fix: step's source, reports of both traced to fix's input, and
  ##   why fix leaves source as written, step's else fix's.
  result.source = step.source
  result.fixed = fix.fixed
  for f in step.fixed:
    var report_traced = f
    report_traced.line = fix.traced(f.line)
    result.fixed.add report_traced
  result.unsettled = if step.unsettled.len > 0: step.unsettled else: fix.unsettled
  result.origin =
    if step.origin.len == 0: fix.origin
    else: step.origin.mapIt(fix.traced(it))
  result.asked = fix.asked
  for asked in step.asked:
    if asked notin result.asked: result.asked.add asked
