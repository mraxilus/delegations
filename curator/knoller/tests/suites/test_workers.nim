## Replicate worker pool of `workers.nim` header: answers in order of jobs, jobs side by side,
##   and exception of job raised again in caller once every job ran.

{.experimental: "strictFuncs".}

import std/[atomics, sequtils, typedthreads, unittest]
import ../../src/knoller/workers


const BARRIER = 4  ## Jobs that must stand at barrier at once before any leaves it.

var
  ARRIVED: Atomic[int]  ## Jobs that reached barrier of side-by-side test.
  STARTED: Atomic[int]  ## Jobs that started in test of exception.


func squared(n: int): int = n * n  ## Answer square of job, so answer names job it came from.


proc thread(n: int): int = getThreadId()  ## Answer id of thread job ran in.


proc waited(n: int): int =
  ## Arrive at barrier, then wait until `BARRIER` jobs stand there; answer arrivals job saw.
  ##   Jobs running in turn never leave it, so check running them so hangs, and never passes; no
  ##   span of real time decides verdict (IX.12).
  {.cast(gcsafe).}:  # counter is atomic, and test alone reads it
    discard ARRIVED.fetchAdd(1)
    while ARRIVED.load < BARRIER: cpuRelax()
    ARRIVED.load


proc raised(n: int): int =
  ## Count start, then raise for jobs 3 and 6, else answer job.
  {.cast(gcsafe).}:  # counter is atomic, and test alone reads it
    discard STARTED.fetchAdd(1)
  if n in [3, 6]: raise newException(ValueError, "job " & $n & " failed")
  n



suite "Workers":
  test "answers keep order of their jobs, whatever worker answers each":
    check mapParallel(toSeq(1 .. 100), squared, workers = 4) == toSeq(1 .. 100).mapIt(it * it)
    check mapParallel(toSeq(1 .. 3), squared, workers = 1) == @[1, 4, 9]  # caller alone
    check mapParallel(@[2], squared) == @[4]  # one for each core
    check mapParallel(newSeq[int](), squared, workers = 4).len == 0  # no job


  test "jobs run side by side, one for each worker":
    ARRIVED.store(0)
    check mapParallel(toSeq(1 .. BARRIER), waited, workers = BARRIER) == repeat(BARRIER, BARRIER)


  test "one worker answers in thread of caller, and several answer in threads of their own":
    let caller = getThreadId()
    check mapParallel(toSeq(1 .. 3), thread, workers = 1).allIt(it == caller)
    check mapParallel(toSeq(1 .. 3), thread, workers = 3).allIt(it != caller)


  test "exception of first job that raised is raised again in caller, once every job ran":
    for workers in [1, 4]:
      STARTED.store(0)
      var message = ""
      try: discard mapParallel(toSeq(1 .. 8), raised, workers = workers)
      except CatchableError as e: message = e.msg
      check message == "job 3 failed"  # first in order of jobs, not first to finish
      check STARTED.load == 8  # each job ran, so one worker reads as several do
