## Replicate making and judging of runs in `runs.nim`: verdict as testament gives it, outcomes in
##   plan order, each from real processes under POSIX shell.

{.experimental: "strictFuncs".}

import std/[algorithm, options, os, sequtils, strutils, tempfiles, times, unittest]
import ../../src/assayer/[headers, plans, runs]


const
  FILE = "tests/test_k.nim"  ## Test file each judged run names.
  CODES_COMPILE = [0, 1, 2]  ## Exit codes of compile law enumerates.
  ERRORS = [none(string), some("test_k.nim"), some("other.nim"), some("")]
    ## Last error compile prints, law enumerates: none, in test file, elsewhere, naming no file.
  CODES_PROGRAM = [none(int), some(0), some(1)]
    ## Exit code of program law enumerates; `none` where compile wrote none.
  COUNT_ARRIVALS = 4  ## Runs whose every order of arrival release law enumerates.
  COUNT_LINES_LARGE = 300_000  ## Lines one command prints, past what pipe buffer holds.


func outputOf(error: Option[string]): string =
  ## Write compile output whose last error line names error's file.
  if error.isNone: "Hint: built\n"
  elif error.get.len == 0: "Error: unhandled exception\n"
  else: "/work/tests/" & error.get & "(3, 5) Error: undeclared identifier: 'x'\n"


func runShell(place: int, directory: string, command: string, action = Action.Run): Run =
  ## Construct run whose compile is shell command, and whose program is `program_<place>`.
  let executable = directory / "program_" & $place
  Run(file: FILE, action: action, command: command, executable: executable,
      execution: @[executable])


func scriptOf(executable, body: string): string =
  ## Write shell command writing executable script of body to executable.
  "printf '#!/bin/sh\\n" & body & "\\n' > " & executable.quoteShell & " && chmod +x " &
      executable.quoteShell



suite "Runs":
  test "last error line names file as testament reads it":
    check errorLast("a.nim(3, 5) Error: undeclared identifier: 'x'\n") == some("a.nim")  # file
    check errorLast("/w/my src/a.nim(3, 5) Error: x") == some("a.nim")  # file name alone
    check errorLast("Error: unhandled exception\n") == some("")  # bare error names no file
    check errorLast("a.nim(3, 5) Warning: x\nHint: y\n").isNone  # no error
    check errorLast("a.nim(3) Error: x").isNone  # column missing, so no error line
    check errorLast("a(1, 2)b(3, 4) Error: x").isNone  # file holds no `(`
    check errorLast("a.nim(1, 1) Error: x\nError: y") == some("")  # last line wins
    check errorLast("Error: y\nb.nim(2, 2) Error: z") == some("b.nim")  # last line wins
    check errorLast("").isNone  # no output


  test "verdict follows action, in every combination of compile, error and program":
    for action in Action:
      for code in CODES_COMPILE:
        for error in ERRORS:
          for program in CODES_PROGRAM:
            let
              run = Run(file: FILE, action: action, executable: "/work/program")
              execution =
                if program.isNone: none(Step)
                else: some(Step(command: "/work/program", code: program.get))
              outcome = Outcome(compile: Step(output: error.outputOf, code: code),
                  execution: execution)
              is_passed =
                case action
                of Action.Run: code == 0 and error.isNone and program == some(0)
                of Action.Compile: code == 0 and error.isNone
                of Action.Reject: code == 1 and error == some("test_k.nim")
            check (run.failureOf(outcome).len == 0) == is_passed  # pass, as testament judges


  test "failure says why, step by step":
    let
      run = Run(file: FILE, action: Action.Run, executable: "/work/program")
      reject = Run(file: FILE, action: Action.Reject)
      clean = Step(code: 0)
    check Run(refusal: "no Node.js").failureOf(Outcome()) == "no Node.js"  # refusal itself
    check run.failureOf(Outcome(compile: Step(failure: "no shell"))) ==
        "compile cannot start: no shell"
    check run.failureOf(Outcome(compile: Step(code: 1))) == "compile exits 1"
    check run.failureOf(Outcome(compile: Step(output: "Error: x"))) ==
        "compile exits 0, yet prints an error"
    check run.failureOf(Outcome(compile: clean)) == "compile writes no program at `/work/program`"
    check run.failureOf(Outcome(compile: clean, execution: some(Step(code: 3)))) ==
        "program exits 3"
    check run.failureOf(Outcome(compile: clean, execution: some(Step(failure: "denied")))) ==
        "program cannot start: denied"
    check reject.failureOf(Outcome(compile: clean)) ==
        "compiles, where the header asks for rejection"
    check reject.failureOf(Outcome(compile: Step(code: 2))) ==
        "compile exits 2, where rejection exits 1"
    check reject.failureOf(Outcome(compile: Step(code: 1))) == "compile exits 1 with no error line"
    check reject.failureOf(Outcome(compile: Step(code: 1, output: "Error: x"))) ==
        "compile rejects with an error that names no file"
    check reject.failureOf(Outcome(compile: Step(code: 1, output: some("other.nim").outputOf))) ==
        "compile rejects in `other.nim`, not in the test file"


  test "duration of run is compile, then program where it ran":
    let
      compile = Step(duration: initDuration(milliseconds = 1200))
      program = Step(duration: initDuration(milliseconds = 300))
    check Outcome(compile: compile).durationOf == initDuration(milliseconds = 1200)  # no program
    check Outcome(compile: compile, execution: some(program)).durationOf ==
        initDuration(milliseconds = 1500)  # both steps


  test "outcome releases in plan order as soon as every run before it has one, in every order":
    var order = toSeq(0..<COUNT_ARRIVALS)
    while true:
      var
        arrived = newSeq[bool](COUNT_ARRIVALS)
        next = 0
        released_all: seq[int]
      for place in order:
        arrived[place] = true
        let after = arrived.released(next)
        for k in next..<after: released_all.add k
        next = after
        check next == arrived.find(false).max(0) or arrived.allIt(it)  # first gap, no later
      check released_all == toSeq(0..<COUNT_ARRIVALS)  # each once, in plan order
      if not order.nextPermutation: break


  test "threads number jobs, never more than runs, never fewer than one":
    check countThreads(4, 8) == 4  # jobs bound
    check countThreads(8, 3) == 3  # runs bound
    check countThreads(4, 0) == 1 and countThreads(0, 5) == 1  # at least one


  test "each outcome lands at place of its run, released in plan order":
    let directory = createTempDir("assayer_", "")
    defer: removeDir(directory)
    var plan: seq[Run]
    for place in 0..<6:
      let executable = directory / "program_" & $place
      plan.add runShell(place, directory,
          scriptOf(executable, "echo out " & $place & "; exit " & $place))
    var places: seq[int]
    let outcomes = plan.runAll(3) do (place: int, outcome: Outcome): places.add place
    check places == toSeq(0..<6)  # plan order
    for place, outcome in outcomes:
      check outcome.compile.code == 0 and outcome.execution.isSome  # compiled, then ran
      check outcome.execution.get.output == "out " & $place & "\n"  # its own output
      check outcome.execution.get.code == place  # its own exit code
      check plan[place].failureOf(outcome) ==
          (if place == 0: "" else: "program exits " & $place)


  test "output past pipe buffer reads whole, and blocks no thread":
    let directory = createTempDir("assayer_", "")
    defer: removeDir(directory)
    let plan = toSeq(0..<4).mapIt(runShell(it, directory, "seq 1 " & $COUNT_LINES_LARGE,
        action = Action.Compile))
    let outcomes = plan.runAll(2) do (place: int, outcome: Outcome): discard
    for outcome in outcomes:
      check outcome.compile.output.countLines == COUNT_LINES_LARGE + 1  # every line, then end
      check outcome.compile.output.splitLines[^2] == $COUNT_LINES_LARGE  # last number arrived


  test "program left by earlier run never runs, and program that cannot start fails run":
    let directory = createTempDir("assayer_", "")
    defer: removeDir(directory)
    let
      stale = runShell(0, directory, "true")
      blocked = runShell(1, directory, "touch " & (directory / "program_1").quoteShell)
    writeFile(stale.executable, "#!/bin/sh\nexit 0\n")
    setFilePermissions(stale.executable, {fpUserExec, fpUserRead, fpUserWrite})
    let outcomes = @[stale, blocked].runAll(2) do (place: int, outcome: Outcome): discard
    check stale.failureOf(outcomes[0]) ==
        "compile writes no program at `" & stale.executable & "`"  # stale one deleted first
    check blocked.failureOf(outcomes[1]).startsWith("program cannot start: ")  # not exec


  test "compile and reject judge real compiler output, and refused run makes nothing":
    let directory = createTempDir("assayer_", "")
    defer: removeDir(directory)
    let
      rejected = runShell(0, directory, "echo '/w/tests/test_k.nim(1, 1) Error: x'; exit 1",
          action = Action.Reject)
      compiled = runShell(1, directory, "echo 'Hint: built'", action = Action.Compile)
      refused = Run(file: FILE, refusal: "No Node.js on PATH, which JavaScript run needs.")
      outcomes = @[rejected, compiled, refused].runAll(3) do (place: int, outcome: Outcome):
        discard
    check rejected.failureOf(outcomes[0]) == ""  # rejected in test file
    check compiled.failureOf(outcomes[1]) == "" and outcomes[1].execution.isNone  # no program
    check outcomes[2] == Outcome()  # nothing ran
    check refused.failureOf(outcomes[2]) == refused.refusal  # refusal fails it
