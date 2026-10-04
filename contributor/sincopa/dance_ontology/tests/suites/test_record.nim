## Hold recorder's one queue to what its header claims: restart asks only jobs with no result,
## slowest job goes first, and recording made in two parts is recording made in one.
##   Jobs are stubs that answer at once, so laws read queue and its files, and never wait on
##     simulation: real job takes seconds to hours, and queue is same either way.

{.experimental: "strictFuncs".}

import std/[atomics, os, strformat, unittest]

import ../../design/record


const
  STAMPS: array[Recording, string] = ["stamp-of-rig", "stamp-of-modelled"]
    ## Stamp of each recording, as recorder keys its results.
  JOBS_RIG = 6  ## Rig jobs of stub recording.
  JOBS_MODELLED = 4  ## Modelled jobs of stub recording.
  WORKERS = 4  ## Threads queue runs on, as many as machine of record has cores.

# Mutable: workers count every job they ask, from every thread.
var CALLS: Atomic[int]  ## Jobs stub answered since law began.


proc stub(task: Task): string {.gcsafe, nimcall.} =
  ## Answer job with text of its own, whatever order it is asked in.
  discard CALLS.fetchAdd(1)
  &"{task.recording} {task.index}\n"

proc stubOrdered(task: Task): string {.gcsafe, nimcall.} =
  ## Answer job with how many jobs were asked before it.
  &"{CALLS.fetchAdd(1)}"

func tasksAll(): seq[Task] =
  ## Every job of stub recording: rig's first, then modelled's.
  for i in 0..<JOBS_RIG: result.add (Recording.Rig, i)
  for i in 0..<JOBS_MODELLED: result.add (Recording.Modelled, i)

proc rootFresh(name: string): string =
  ## Empty directory for one law's results.
  result = getTempDir() / &"test_record_{getCurrentProcessId()}_{name}"
  removeDir(result)



suite "Internal: Recording in one queue":
  test "restart asks only jobs with no result, and two parts keep bytes of one":
    let
      tasks = tasksAll()
      (whole, parts) = (rootFresh("whole"), rootFresh("parts"))
    CALLS.store(0)
    runQueue(tasks, whole, STAMPS, WORKERS, stub)
    check CALLS.load == tasks.len

    # First part stops after four jobs; second asks every job, and only rest are asked.
    CALLS.store(0)
    runQueue(tasks[0..<4], parts, STAMPS, WORKERS, stub)
    check CALLS.load == 4
    runQueue(tasks, parts, STAMPS, WORKERS, stub)
    check CALLS.load == tasks.len
    for task in tasks:
      let (one, two) = (pathOf(whole, STAMPS, task), pathOf(parts, STAMPS, task))
      check fileExists(two)
      check readFile(one) == readFile(two)
    removeDir(whole)
    removeDir(parts)


  test "jobs named slowest go first in their own order, every other after in order given":
    let
      tasks = tasksAll()
      names = @["rig a", "rig b", "rig c", "rig d", "rig e", "rig f", "modelled a",
                "modelled b", "modelled c", "modelled d"]
      queue = ordered(tasks, names, ["modelled c", "rig e", "rig b"])
    check queue[0..2] == @[(Recording.Modelled, 2), (Recording.Rig, 4), (Recording.Rig, 1)]
    check queue[3..^1] == @[(Recording.Rig, 0), (Recording.Rig, 2), (Recording.Rig, 3),
                            (Recording.Rig, 5), (Recording.Modelled, 0),
                            (Recording.Modelled, 1), (Recording.Modelled, 3)]

    # One worker asks queue in its order, so each job's count is its place.
    let root = rootFresh("order")
    CALLS.store(0)
    runQueue(queue, root, STAMPS, 1, stubOrdered)
    for place, task in queue:
      check readFile(pathOf(root, STAMPS, task)) == $place
    removeDir(root)
