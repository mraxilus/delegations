## Record every kept file of simulation in one pool: rig viewer's stills and sweeps, reference's
## badges, whole-cloth turns, rig suite's answers and report's readings.  Every job of five
## recordings is in one queue, slowest first, and each result is kept as it comes, so restarted
## run asks only what has no result yet.
##
##   One queue: worker takes next job as it ends last one, so no worker waits while another
##     still holds several.  Each verb split its own jobs by worker, `k`, `k + cores` onward,
##     and one worker held rig 5.7 h where three ended at 3.1 to 3.8 h; modelled then took 3.0
##     h after it.  Estimated 2026-10-03 from job times of one run.
##   One run asks each question once (`walk.keepAnswers`): report sweeps holds whole-cloth page
##     sweeps, and rig and modelled stand same stills, so each reads what first job answered.
##   Slowest first (`SLOWEST`): last job to start is short, so every worker ends near same
##     time.  Order is measured and goes stale as simulation changes; wrong order costs time
##     and never changes answer.
##   Idle workers lend their cores (`walk.SPARE`): as queue empties, search of its last jobs
##     walks distances on cores others left.
##   Resumable: each result is written under its recording's stamp as it comes (`build/record/`).
##     Restart asks only jobs with no result, and directory goes once its kept file is written.
##     Artifact, never committed.  File is renamed into place, so worker stopped mid-write
##     leaves no result: intended, since no law stops worker mid-write.
##   Same bytes: kept file is assembled from results in recording's own order, so recording
##     made in two parts is recording made in one (`suites/test_record.nim`).
##   Workers share plain values alone (`Task`): each lists jobs for itself, since one list of
##     strings read by four threads raced on its counts, and verb died inside engine every
##     other run.
##
##   Usage: record [rig] [modelled] [turns] [answers] [verdicts]   writes kept file of each
##                                    recording named, or of all five

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import std/[algorithm, atomics, cpuinfo, json, os, strformat, strutils, tables, times,
            typedthreads]

import ../simulation/[answers, readings, verdicts, walk]
import ./[modelled, rig, turns]


type
  Recording* {.pure.} = enum  ## Kept file one job belongs to.
    Rig, Modelled, Turns, Answers, Verdicts

  Task* = tuple[recording: Recording, index: int]
    ## One job, by its recording and its place in that recording's own list.

  Ask* = proc(task: Task): string {.gcsafe, nimcall.}
    ## Answer one job as text: what its result file keeps.


const SLOWEST* = ["rig D01", "modelled hc_la", "rig C01", "rig C02", "modelled hw_la_0",
                  "verdicts sweep 0|0|false|0.0|00", "modelled pc_la", "modelled pw_la_0"]
  ## Jobs slowest first, by their times in full run of 2026-10-04 that set this order, four at
  ##   once: rig D01 391 s, modelled hc_la 379 s, rig C01 365 s and C02 227 s, modelled hw_la_0
  ##   152 s, report's sweep turning lead 116 s, modelled pc_la 88 s and pw_la_0 76 s.  Each
  ##   still plans 32 paths on every core (`walk.planAhead`), which modelled's planned
  ##   questions find kept.  C07 and C06 take C01 and C02 reflected (`walk.twinOf`), and D07 takes
  ##   D01's paths kept, so they follow in order of `wanted`, as every other job does:
  ##   whole-cloth turns first, which walk every distance.

# Mutable and global: thread takes one argument, so workers read queue and what answers it here.
var
  QUEUE: seq[Task]  ## Every job to ask, in order asked.
  NEXT: Atomic[int]  ## Place in `QUEUE` of next job to take.
  ROOT: string  ## Directory results are kept under.
  STAMPS: array[Recording, string]  ## Stamp of each recording: results of other stamp are other.
  ASKED: Ask  ## What answers one job.



#[ Queue ]#

func pathOf*(root: string, stamps: array[Recording, string], task: Task): string =
  ## Where one job's result is kept: under its recording and that recording's stamp.
  root / &"{task.recording}-{stamps[task.recording]}" / &"{task.index}.txt"

func ordered*(tasks: seq[Task], names: seq[string], slowest: openArray[string]): seq[Task] =
  ## Same jobs, those named in `slowest` first in its order, then every other in order given.
  ##   `names[i]` names `tasks[i]`.
  var first: seq[(int, Task)]
  for i, task in tasks:
    let rank = slowest.find(names[i])
    if rank >= 0: first.add (rank, task)
    else: result.add task
  first.sort(proc(a, b: (int, Task)): int = cmp(a[0], b[0]))
  var lead: seq[Task]
  for (_, task) in first: lead.add task
  lead & result

proc work(worker: int) {.thread.} =
  ## Take next job from queue until none is left; keep each result as it comes.
  {.cast(gcsafe).}:
    while true:
      let k = NEXT.fetchAdd(1)
      if k >= QUEUE.len:
        discard SPARE.fetchAdd(1)
        break
      let path = pathOf(ROOT, STAMPS, QUEUE[k])
      if fileExists(path): continue
      let text = ASKED(QUEUE[k])
      writeFile(path & ".part", text)
      moveFile(path & ".part", path)

proc runQueue*(
  tasks: seq[Task], root: string, stamps: array[Recording, string], workers: int, ask: Ask
) =
  ## Ask every job of `tasks` that has no result under `root`, in order given, on `workers`
  ## threads, and keep each result as it comes.
  for task in tasks: createDir(root / &"{task.recording}-{stamps[task.recording]}")
  (QUEUE, ROOT, STAMPS, ASKED) = (tasks, root, stamps, ask)
  NEXT.store(0)
  SPARE.store(0)
  var threads = newSeq[Thread[int]](workers)
  for worker in 0..<workers: createThread(threads[worker], work, worker)
  joinThreads(threads)



#[ Every Recording ]#

# Mutable and global: report's readings are listed once, by render, before any thread starts.
var
  READ_SWEEPS: seq[SweepAsk]  ## Sweeps report lacks, plain values each worker copies.
  READ_RUNGS: seq[RungAsk]  ## Rungs report lacks; their jobs come first.

proc nameOf(task: Task): string =
  ## Name of one job, as `SLOWEST` names it.
  case task.recording
  of Recording.Rig: "rig " & nameOf(jobs()[task.index])
  of Recording.Modelled: "modelled " & questions()[task.index].key
  of Recording.Turns:
    let sweep = sweeps()[task.index]
    &"turns {sweep.hold} {sweep.word}"
  of Recording.Answers: &"answers {tasks()[task.index]}"
  of Recording.Verdicts:
    if task.index < READ_RUNGS.len: &"verdicts rung {keyOf(READ_RUNGS[task.index])}"
    else: &"verdicts sweep {keyOf(READ_SWEEPS[task.index - READ_RUNGS.len])}"

proc askedOf(task: Task): string =
  ## Answer one job as its result file keeps it, and say so with its time.
  ##   Rig job keeps its line of what it found first, then its text.
  ##   Report's readings are read from lists set before any thread starts, and only read.
  {.cast(gcsafe).}:
    let start = epochTime()
    case task.recording
    of Recording.Rig:
      let (note, text) = recorded(jobs()[task.index])
      result = note & "\n" & text
      echo &"{nameOf(task)}: {note} ({epochTime() - start:.0f} s)"
      return
    of Recording.Modelled: result = $answered(questions()[task.index])
    of Recording.Turns: result = sweepText(sweeps()[task.index])
    of Recording.Answers: result = taskText(tasks()[task.index])
    of Recording.Verdicts:
      result = (if task.index < READ_RUNGS.len: rungText(READ_RUNGS[task.index])
                else: sweepText(READ_SWEEPS[task.index - READ_RUNGS.len]))
    echo &"{nameOf(task)}: {result.len} bytes ({epochTime() - start:.0f} s)"

proc isKept(path, stamp: string): bool =
  ## Whether kept file already carries this stamp, so nothing need be asked again.
  fileExists(path) and parseFile(path){"stamp"}.getStr == stamp



proc main() =
  ## Record each recording named on command line, or all five, from one queue, and assemble
  ## each kept file.
  let asked = commandLineParams()
  var wanted: seq[Recording]
  for word in asked:
    var is_known = false
    for recording in Recording:
      if word == toLowerAscii($recording):
        wanted.add recording
        is_known = true
    if not is_known:
      quit("Usage: record [rig] [modelled] [turns] [answers] [verdicts]; got `" &
           asked.join(" ") & "`.", 2)
  if wanted.len == 0:
    # Sweeps of whole-cloth page first: report and rig viewer sweep same holds, and find
    # them kept.  Report's rungs next, which nothing else asks.  Rig's stills before
    # modelled's, which ask same stills again.
    wanted = @[Recording.Turns, Recording.Verdicts, Recording.Rig, Recording.Answers,
               Recording.Modelled]
  (READ_SWEEPS, READ_RUNGS) = verdicts.wanted()
  let
    stamps: array[Recording, string] = [rigStamp(), modelledStamp(), turnsStamp(),
                                         answers.stamp(), physics()]
    counts: array[Recording, int] = [jobs().len, questions().len, sweeps().len, tasks().len,
                                     READ_RUNGS.len + READ_SWEEPS.len]
    root = "build" / "record"
  # Turns keep no stamp, so are recorded every time; report renders every time, and reads
  # only readings it lacks.
  var is_due: array[Recording, bool]
  is_due[Recording.Rig] = not isKept(KEPT_RIG, stamps[Recording.Rig])
  is_due[Recording.Modelled] = not isKept(KEPT_MODELLED, stamps[Recording.Modelled])
  is_due[Recording.Turns] = true
  is_due[Recording.Answers] = not isKept(answers.KEPT, stamps[Recording.Answers])
  is_due[Recording.Verdicts] = true
  var
    tasks_all: seq[Task]
    names: seq[string]
  for recording in wanted:
    if not is_due[recording]:
      echo &"{recording} is up to date: {stamps[recording]}"
      continue
    for i in 0..<counts[recording]:
      tasks_all.add (recording, i)
      names.add nameOf((recording, i))
  echo &"{tasks_all.len} jobs to ask"
  keepAnswers()
  runQueue(ordered(tasks_all, names, SLOWEST), root, stamps, max(1, countProcessors()), askedOf)

  # Assemble each kept file in its recording's own order, then drop its results.
  for recording in wanted:
    if not is_due[recording]: continue
    var texts: seq[string]
    for i in 0..<counts[recording]: texts.add readFile(pathOf(root, stamps, (recording, i)))
    case recording
    of Recording.Rig:
      var bodies: seq[string]
      for text in texts: bodies.add text[text.find('\n') + 1..^1]
      writeFile(KEPT_RIG, assembled(stamps[recording], bodies))
    of Recording.Modelled:
      var told = initOrderedTable[string, bool]()
      for i, question in questions(): told[question.key] = texts[i] == "true"
      writeFile(KEPT_MODELLED, kept(stamps[recording], told))
    of Recording.Turns: writeFile("design/turns.json", bridged(texts))
    of Recording.Answers: writeFile(answers.KEPT, answers.assembled(texts))
    of Recording.Verdicts:
      writeFile("simulation/verdicts.md", verdicts.assembled(
        READ_SWEEPS, texts[READ_RUNGS.len..^1], READ_RUNGS, texts[0..<READ_RUNGS.len]))
    removeDir(root / &"{recording}-{stamps[recording]}")
    echo &"wrote {recording}"


when isMainModule:
  main()
