## Replicate pool of threads of `pools.nim` header: answers in order of jobs, jobs side by side,
##   and exception of job raised again in caller once every job ran.

{.experimental: "strictFuncs".}

import std/[atomics, sequtils, typedthreads, unittest]
import ../../src/knoller/pools


const BARRIER = 4  ## Jobs that must stand at barrier at once before any leaves it.

var
  ARRIVED: Atomic[int]  ## Jobs that reached barrier of side-by-side test.
  STARTED: Atomic[int]  ## Jobs that started in test of exception.


func squared(n: int): int = n * n  ## Answer square of job, so answer names job it came from.


func spelled(n: int): seq[string] = newSeqWith(n mod 7 + 1, $n)
  ## Answer job spelled out, one to seven times, so answer holds memory its thread allocated.


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



suite "Pools":
  test "answers keep order of their jobs, whatever thread answers each":
    check mapParallel(toSeq(1 .. 100), squared, threads = 4) == toSeq(1 .. 100).mapIt(it * it)
    check mapParallel(toSeq(1 .. 3), squared, threads = 1) == @[1, 4, 9]  # caller alone
    check mapParallel(@[2], squared) == @[4]  # one for each core
    check mapParallel(newSeq[int](), squared, threads = 4).len == 0  # no job


  test "answers holding text that thread allocated reach caller whole":
    check mapParallel(toSeq(1 .. 200), spelled, threads = 4) == toSeq(1 .. 200).mapIt(it.spelled)


  test "jobs run side by side, one for each thread":
    ARRIVED.store(0)
    check mapParallel(toSeq(1 .. BARRIER), waited, threads = BARRIER) == repeat(BARRIER, BARRIER)


  test "pool of one thread answers in thread of caller, and larger pool in threads of its own":
    let caller = getThreadId()
    check mapParallel(toSeq(1 .. 3), thread, threads = 1).allIt(it == caller)
    check mapParallel(toSeq(1 .. 3), thread, threads = 3).allIt(it != caller)


  test "exception of first job that raised is raised again in caller, once every job ran":
    for threads in [1, 4]:
      STARTED.store(0)
      var message = ""
      try: discard mapParallel(toSeq(1 .. 8), raised, threads = threads)
      except CatchableError as e: message = e.msg
      check message == "job 3 failed"  # first in order of jobs, not first to finish
      check STARTED.load == 8  # each job ran, so pool of one thread reads as larger one does
