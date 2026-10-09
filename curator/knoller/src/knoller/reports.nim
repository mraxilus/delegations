## Define report every fixer and check of knoller emits, and fix record every fixer returns.
##   Report names rule rewritten or broken, at path and line; finding of check carries its
##     message too, ending with echoed value (Article IV.4). Caller renders both:
##     `curator/audit` cites article of each rule, so `koch fix` prints `path:line: <rule>
##     (<article>) fixed`.
##   Message reads `<sentence>; got <value>.`, or `<sentence>.`, and names no article, since
##     knoller runs on any repository; caller cites article where sentence ends (`findingOf` of
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
##     line on every platform (`command.layoutOf`). Rule reading layout from it reads test file
##     and stub here alone, both from last directory `tests` (`partTests`), so each meaning is
##     written once; drive file, where command line reads fixed waits, too (`isFileDrive`).
##   Stub is read as testament reads category (#443), i.e. directory directly under `tests`,
##     whose tests are files `t*.nim` at any depth (`isTestFile`, `processCategory` of
##     `testament/categories.nim`): file there is stub where its source opens with testament
##     header, and suite module, which opens with none, stays suite. Stub `test_*` directly
##     under `tests` holds with header or without, so its missing header stays finding. So
##     `isStub` takes source beside path, and each caller passes source it holds.
##   Rejected: path alone, which reads each suite module of category as stub, so missing header
##     and profiler import would report on each, e.g. `tests/suites/test_names.nim`; header
##     test at each caller, which writes category rule three times.
##
##   Cost: line `0` marks whole-file report, so `0` never means first line.
##   Cost: header of category file reads at its first byte alone, where testament reads it
##     anywhere in first ten lines with no space before it; file of category whose header stands
##     lower is no stub, so it takes no stub rule. Stub of STYLE.md §6 opens with header.
##   Cost: absolute path reads directories above repository too, so file under directory
##     `tests` there reads as test file from command line.
##   Cost: drive file is file under directory `tests` or `tools` at any depth, wider than
##     `curator/audit` reads it (those of each project alone), since command line knows no
##     project; so command line reports fixed wait static pass passes over.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, strutils, tables]
import ./rules

export rules


type
  Report* = object  ## Define one rewrite or finding, located at path and line.
    path*: string  ## Path fixer read, `/` separated: repository-relative, or absolute.
    line*: int  ## One-based line; `0` when report concerns whole file.
    rule*: Rule  ## Rule rewritten or broken.
    message*: string  ## Finding's statement, ending with echoed value; empty for rewrite.

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

  KindStep* {.pure.} = enum  ## Define how step reads lines held and answers of parser.
    Guarded  ## Fixer guarded on every line.
    Widening  ## Widener, off held lines.
    Proving  ## Fixer writing what parser proves, guarded on every line.

  Step* = object  ## Define one fixer of chain, of one kind.
    case kind*: KindStep
    of KindStep.Guarded: fixer*: Fixer
    of KindStep.Widening: widener*: Widener
    of KindStep.Proving: proven*: Proven

  Dialect* {.pure.} = enum  ## Define which Nim source file holds, which decides fixers it takes.
    Module  ## `.nim`, which module's idiom checks and fixers read too.
    Script  ## `.nims`.
    Package  ## `.nimble`.


const
  EVERY* = Held(is_every: true)  ## Held of every line, as each widener's two-argument form.
  DIRECTORIES_DRIVE = ["tests", "tools"]  ## Directories whose files command line reads as drive.
  EXTENSIONS*: array[Dialect, string] = [".nim", ".nims", ".nimble"]
    ## Extension of file of each dialect.
  HEADER_TESTAMENT* = "discard \"\"\""
    ## Opening of stub's testament header, which stands before module's header docs.


func initReport*(path: string, line: int, rule: Rule, message = ""): Report =
  ## Construct report: rewrite where message is empty, finding of check otherwise.
  Report(path: path, line: line, rule: rule, message: message)


func partTests(path: string): seq[string] =
  ## Read names of path below its last directory `tests`; empty where no directory is so named.
  let parts = path.split('/')
  for k in countdown(parts.high - 1, 0):
    if parts[k] == "tests": return parts[k + 1 .. ^1]


func isFileTest*(path: string): bool =
  ## Decide whether path lies under directory `tests`, at any depth.
  path.partTests.len > 0


func isStub*(path, source: string): bool =
  ## Decide whether file is testament stub: `test_*` directly under directory `tests`, or
  ##   `t*.nim` at any depth inside category whose source opens with testament header.
  let part = path.partTests
  if part.len == 1: return part[0].startsWith("test_")
  part.len > 1 and part[^1].startsWith('t') and part[^1].endsWith(EXTENSIONS[Dialect.Module]) and
      source.startsWith(HEADER_TESTAMENT)


func isFileDrive*(path: string): bool =
  ## Decide whether path lies under directory `tests` or `tools`, at any depth: drive code, where
  ##   command line reads fixed waits.
  let parts = path.split('/')
  parts[0 ..< parts.high].anyIt(it in DIRECTORIES_DRIVE)


func guarded*(fixer: Fixer): Step =
  ## Construct step of fixer guarded on every line.
  Step(kind: KindStep.Guarded, fixer: fixer)


func widening*(widener: Widener): Step =
  ## Construct step of widener, which reads held lines.
  Step(kind: KindStep.Widening, widener: widener)


func proving*(proven: Proven): Step =
  ## Construct step of fixer whose rewrite parser proves, which reads answers.
  Step(kind: KindStep.Proving, proven: proven)


func run*(step: Step; path, source: string; held: Held; proofs = Proofs()): Fix =
  ## Run step on source: widener reads held lines, prover step reads answers, guarded fixer
  ##   reads neither.
  case step.kind
  of KindStep.Guarded: step.fixer(path, source)
  of KindStep.Widening: step.widener(path, source, held)
  of KindStep.Proving: step.proven(path, source, proofs)


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
