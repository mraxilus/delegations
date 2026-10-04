## Record what rig viewer plays and what reference's tags say in one pool: every job of both
## recordings in one queue, slowest first, each result kept as it comes, so restarted run asks
## only what has no result yet.
##
##   One queue: worker takes next job as it ends last one, so no worker waits while another
##     still holds several.  Each verb split its own jobs by worker, `k`, `k + cores` onward,
##     and one worker held rig 5.7 h where three ended at 3.1 to 3.8 h; modelled then took 3.0
##     h after it.  Estimated 2026-10-03 from job times of one run.
##   Slowest first (`SLOWEST`): last job to start is short, so every worker ends near same
##     time.  Over 25.0 h of one core, four workers took 6.3 h, where ideal is 6.2 h, measured
##     2026-10-03.  Order is measured and goes stale as simulation changes; wrong order costs
##     time and never changes answer.
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
##   Usage: record [rig | modelled]   writes `design/rig.json` and `design/modelled.json`, or
##                                    one of them

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import std/[algorithm, atomics, cpuinfo, json, os, strformat, strutils, tables, times,
            typedthreads]

import ./[modelled, rig]


type
  Recording* {.pure.} = enum  ## Kept file one job belongs to.
    Rig, Modelled

  Task* = tuple[recording: Recording, index: int]
    ## One job, by its recording and its place in that recording's own list.

  Ask* = proc(task: Task): string {.gcsafe, nimcall.}
    ## Answer one job as text: what its result file keeps.


const SLOWEST* = ["rig D1", "rig D7", "rig C1", "rig C7", "rig C2", "rig C6", "modelled pw_fa_5",
                  "modelled pw_lo_5", "modelled pw_fa_0", "modelled pw_lo_0", "modelled pc_lo",
                  "modelled pc_fa", "modelled D1", "modelled D7", "rig A11", "rig D3"]
  ## Jobs slowest first, as one run measured them on 2026-10-03: rig D1 and D7 3.5 h each, C1
  ## and C7 3.0 h, C2 and C6 0.9 h, every modelled job here 0.8 h, A11 and D3 0.2 h.  Every
  ## other job took 0.14 h or less.  Each is planned card: carried walk reaches none of them.

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
      if k >= QUEUE.len: break
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
  for recording in Recording: createDir(root / &"{recording}-{stamps[recording]}")
  (QUEUE, ROOT, STAMPS, ASKED) = (tasks, root, stamps, ask)
  NEXT.store(0)
  var threads = newSeq[Thread[int]](workers)
  for worker in 0..<workers: createThread(threads[worker], work, worker)
  joinThreads(threads)



#[ Both Recordings ]#

proc nameOf(task: Task): string =
  ## Name of one job, as `SLOWEST` names it.
  case task.recording
  of Recording.Rig: "rig " & nameOf(jobs()[task.index])
  of Recording.Modelled: "modelled " & questions()[task.index].key

proc askedOf(task: Task): string =
  ## Answer one job as its result file keeps it, and say so with its time.
  ##   Rig job keeps its line of what it found first, then its text.
  let start = epochTime()
  case task.recording
  of Recording.Rig:
    let (note, text) = recorded(jobs()[task.index])
    result = note & "\n" & text
    echo &"{nameOf(task)}: {note} ({epochTime() - start:.0f} s)"
  of Recording.Modelled:
    let is_modelled = answered(questions()[task.index])
    result = $is_modelled
    echo &"{nameOf(task)}: {is_modelled} ({epochTime() - start:.0f} s)"

proc isKept(path, stamp: string): bool =
  ## Whether kept file already carries this stamp, so nothing need be asked again.
  fileExists(path) and parseFile(path){"stamp"}.getStr == stamp



when isMainModule:
  let
    asked = commandLineParams()
    wanted = (if asked.len == 0: @[Recording.Rig, Recording.Modelled]
              elif asked == @["rig"]: @[Recording.Rig]
              elif asked == @["modelled"]: @[Recording.Modelled]
              else: quit("Usage: record [rig | modelled]; got `" & asked.join(" ") & "`.", 2))
    stamps: array[Recording, string] = [rigStamp(), modelledStamp()]
    counts: array[Recording, int] = [jobs().len, questions().len]
    kept_paths: array[Recording, string] = [KEPT_RIG, KEPT_MODELLED]
    root = "build" / "record"
  var
    tasks: seq[Task]
    names: seq[string]
  for recording in wanted:
    if isKept(kept_paths[recording], stamps[recording]):
      echo &"{kept_paths[recording]} is up to date: {stamps[recording]}"
      continue
    for i in 0..<counts[recording]:
      tasks.add (recording, i)
      names.add nameOf((recording, i))
  echo &"{tasks.len} jobs to ask"
  runQueue(ordered(tasks, names, SLOWEST), root, stamps, max(1, countProcessors()), askedOf)

  # Assemble each kept file in its recording's own order, then drop its results.
  for recording in wanted:
    if isKept(kept_paths[recording], stamps[recording]): continue
    case recording
    of Recording.Rig:
      var texts: seq[string]
      for i in 0..<counts[recording]:
        let saved = readFile(pathOf(root, stamps, (recording, i)))
        texts.add saved[saved.find('\n') + 1..^1]
      writeFile(KEPT_RIG, assembled(stamps[recording], texts))
    of Recording.Modelled:
      var told = initOrderedTable[string, bool]()
      for i, question in questions():
        told[question.key] = readFile(pathOf(root, stamps, (recording, i))) == "true"
      writeFile(KEPT_MODELLED, kept(stamps[recording], told))
    removeDir(root / &"{recording}-{stamps[recording]}")
    echo &"wrote {kept_paths[recording]}"
