## Make each planned run, all in parallel: compile it, execute what compile writes, and judge it as
##   testament judges it (`testSpecHelper` of `testament/testament.nim`, Nim 2.2.12).
##   Threads, `jobs` of them at most, take runs off one channel and send each outcome back
##     on another (`runAll`). Channel copies value whole, so no thread frees memory of another.
##   Each command starts under one lock (`Pool.lock_pipes`): pipe of child carries no close-on-exec
##     flag, so child started meanwhile by other thread would inherit its write end, and reader
##     would wait on both children. Input of child closes under same lock, for same reason.
##   Process closes under that lock too: with stderr joined, `close` of `std/osproc` frees one
##     descriptor twice, and number freed between could meanwhile name pipe of other thread.
##   No command takes working directory of its own: spawn on POSIX gives one by changing directory
##     of whole process, under every other thread. Every path run holds is absolute.
##   Output is read to end before exit is waited on, so pipe never fills and blocks child; stderr
##     joins stdout, as testament joins them.
##   Compile runs through shell, since command is shell text, as testament runs it; program runs
##     with no shell between.
##   Program left by earlier run is deleted before compile, so compile writing none fails run
##     rather than runs stale program.
##   Verdict (`failureOf`):
##     - `run` passes where compile exits 0 printing no error, then program exits 0;
##     - `compile` passes where compile exits 0 printing no error;
##     - `reject` passes where compile exits 1, its last error naming test file.
##     Error is line testament reads as one (`errorLast`).
##   Outcomes arrive in any order, and each is released in plan order once every run before it has
##     one (`released`), so report prints same lines in same order every time.
##
##   Cost: run that never ends holds its thread forever, since no limit on time decides verdict
##     (Article IX.12).

{.experimental: "strictFuncs".}

import std/[locks, options, os, osproc, parseutils, streams, strutils, typedthreads]
import ./[headers, plans]


type
  Step* = object  ## Define what one command did.
    command*: string  ## Command as run.
    output*: string  ## Its stdout and stderr together.
    code*: int  ## Its exit code.
    failure*: string  ## Why command could not start; empty where it started.

  Outcome* = object  ## Define what one run did.
    compile*: Step  ## Compile.
    execution*: Option[Step]  ## Program; `none` where compile wrote none or action asks none.

  Pool = object  ## Define what threads share, in shared memory.
    jobs: Channel[(int, Run)]  ## Runs waiting for thread, each with place in plan; negative stops.
    outcomes: Channel[(int, Outcome)]  ## Outcomes waiting for release, each with place in plan.
    lock_pipes: Lock  ## Lock held while command starts or closes (`captured`).


func errorLast*(output: string): Option[string] =
  ## Read file named by last line of compile output testament reads as error; `some("")` where
  ##   that line names no file, `none` where no line is error.
  ##   Error line is `<file>(<line>, <column>) Error: ...`, its file holding no `(`, else line
  ##     opening `Error:`, as testament tries `pegLineError`, then `pegOtherError`.
  for line in output.splitLines:
    let
      opening = line.find('(')
      digits_line = if opening < 0: 0 else: line.skipWhile(Digits, opening + 1)
      column = opening + 1 + digits_line + 2
      digits_column = if digits_line == 0: 0 else: line.skipWhile(Digits, column)
      is_positioned =
          digits_column > 0 and line.continuesWith(", ", opening + 1 + digits_line) and
          line.continuesWith(") Error:", column + digits_column)
    if is_positioned: result = some(line[0..<opening].extractFilename)
    elif line.startsWith("Error:"): result = some("")


func failureOf*(run: Run, outcome: Outcome): string =
  ## Read why run failed, as testament judges it; empty where it passed.
  if run.refusal.len > 0: return run.refusal
  let
    compile = outcome.compile
    error = compile.output.errorLast
  if compile.failure.len > 0: return "Compile cannot start; got `" & compile.failure & "`."
  if run.action == Action.Reject:
    if compile.code != 1: return "Compile exits " & $compile.code & ", where rejection exits 1."
    if error.isNone: return "Compile exits 1, printing no error."
    if error.get.len == 0: return "Compile rejects with error naming no file."
    if error.get != run.file.extractFilename:
      return "Compile rejects in `" & error.get & "`, not in test file."
    return ""
  if compile.code != 0: return "Compile exits " & $compile.code & "."
  if error.isSome: return "Compile exits 0, printing error."
  if run.action == Action.Compile: return ""
  if outcome.execution.isNone: return "Compile writes no program at `" & run.executable & "`."
  let execution = outcome.execution.get
  if execution.failure.len > 0: return "Program cannot start; got `" & execution.failure & "`."
  if execution.code != 0: return "Program exits " & $execution.code & "."
  ""


proc captured(
  command: string, arguments: openArray[string], lock_pipes: var Lock, as_shell = false
): Step =
  ## Run command, read its output to end, then wait for its exit code.
  ##   With `as_shell`, shell reads command and `arguments` is empty; otherwise command is program.
  result.command = if as_shell: command else: quoteShellCommand(@[command] & @arguments)
  var process: Process
  try:
    withLock lock_pipes:
      process = startProcess(
        command,
        args = arguments,
        options = if as_shell: {poEvalCommand, poStdErrToStdOut} else: {poStdErrToStdOut},
      )
      process.inputStream.close
  except OSError as e:
    result.failure = e.msg
    return
  try:
    result.output = process.outputStream.readAll
    result.code = process.waitForExit
  finally:
    withLock lock_pipes: process.close


proc outcomeOf*(run: Run, lock_pipes: var Lock): Outcome =
  ## Compile run, then execute what compile writes where action asks it; refused run does neither.
  if run.refusal.len > 0: return
  try: removeFile(run.executable)
  except OSError as e:
    result.compile.failure = e.msg
    return
  result.compile = captured(run.command, [], lock_pipes, as_shell = true)
  let is_clean =
      result.compile.failure.len == 0 and result.compile.code == 0 and
      result.compile.output.errorLast.isNone
  if run.action != Action.Run or not is_clean or not fileExists(run.executable): return
  result.execution = some(captured(run.execution[0], run.execution[1 .. ^1], lock_pipes))


proc work(pool: ptr Pool) {.thread.} =
  ## Make each run channel brings, sending each outcome back, until negative place arrives.
  while true:
    let (place, run) = pool.jobs.recv
    if place < 0: break
    pool.outcomes.send (place, outcomeOf(run, pool.lock_pipes))


func released*(arrived: openArray[bool], next: int): int =
  ## Read place of first run left to release, once each run from `next` on whose outcome arrived is
  ##   released, in plan order.
  result = next
  while result < arrived.len and arrived[result]: inc result


func countThreads*(jobs, runs: int): int =
  ## Read threads `runAll` starts: `jobs`, but never more than runs, and never fewer than one.
  max(1, min(jobs, runs))


proc runAll*(
  runs: openArray[Run], jobs: int, release: proc(place: int, outcome: Outcome)
): seq[Outcome] =
  ## Make every run, `jobs` at once at most, and return outcomes in plan order; `release` takes
  ##   each in plan order, once every run before it has one.
  if runs.len == 0: return
  let pool = cast[ptr Pool](allocShared0(sizeof(Pool)))
  pool.jobs.open
  pool.outcomes.open
  initLock pool.lock_pipes

  # Queue every run, then one stop for each thread, before any thread starts.
  for place, run in runs: pool.jobs.send (place, run)
  var threads = newSeq[Thread[ptr Pool]](countThreads(jobs, runs.len))
  for _ in 1..threads.len: pool.jobs.send (-1, Run())
  for thread in threads.mitems: createThread(thread, work, pool)

  # Release each outcome in plan order, as soon as every run before it has one.
  var
    arrived = newSeq[bool](runs.len)
    next = 0
  result = newSeq[Outcome](runs.len)
  for _ in runs:
    let (place, outcome) = pool.outcomes.recv
    result[place] = outcome
    arrived[place] = true
    let after = arrived.released(next)
    for k in next..<after: release(k, result[k])
    next = after

  # Stop threads, then free what they shared.
  joinThreads(threads)
  deinitLock pool.lock_pipes
  pool.jobs.close
  pool.outcomes.close
  deallocShared(pool)
