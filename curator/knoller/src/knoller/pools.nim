## Run independent jobs on threads of pool, at most one for each core, and return each answer in
##   order of its job, as one loop over jobs would return them.
##   Semantic pass asks compiler once for each job and waits on answer: at `b585ea65`, before
##     pool, 59 calls of rules 7 and 11 in `koch fix --dry-run curator/knoller` take 61 s of 111 s,
##     one after another, while three of four cores wait (profile of #1001, 2026-11-21).
##   Fix of each file reads its own file and what run read, and waits on no other: at `2d496af8`,
##     it takes 26.6 s of 65.0 s of same command, one file after another (profile of #1001,
##     2026-11-26).
##   Job and answer hold no `ref`: ORC counts references without atomics, so object two threads
##     count would race. Thread reads its job in place, and its answer moves into sequence of
##     caller.
##   Thread takes next job by atomic counter, so long job delays no job queued behind it.
##   Pool of one thread is caller itself, so caller of one job starts no thread.
##   Exception of job is caught in its thread, and caller raises it again once every thread
##     ended: first in order of jobs, as one loop would raise it. It is raised as
##     `CatchableError` with its message, whatever count of threads ran, since exception object,
##     which ORC counts, stays in thread that raised it.
##
##   Rejected: pool of compiler processes, which turns loop of each prover into state machine
##     across files; thread runs each loop as written.
##   Rejected: `malebolgia` or `taskpools`, first dependency of knoller for one routine.
##   Cost: job after first that raised runs too, and its answer is dropped.

{.experimental: "strictFuncs".}

import std/[atomics, cpuinfo, typedthreads]


type Pool[T, U] = object  ## Define jobs, answers and counter threads of pool share.
  jobs: ptr UncheckedArray[T]  ## Jobs caller holds.
  answers: ptr UncheckedArray[U]  ## Answer of each job, at its index.
  raised: ptr UncheckedArray[bool]  ## Whether each job raised.
  failures: ptr UncheckedArray[string]  ## Message of exception each job raised.
  count: int  ## Jobs in all.
  next: Atomic[int]  ## Index of next job any thread takes.
  run: proc (job: T): U {.nimcall, gcsafe.}  ## Routine answering one job.


proc work[T, U](pool: ptr Pool[T, U]) {.thread.} =
  ## Answer each job counter gives thread, until none is left.
  while true:
    let k = pool.next.fetchAdd(1)
    if k >= pool.count: return
    try: pool.answers[k] = pool.run(pool.jobs[k])
    except CatchableError as e:
      pool.raised[k] = true
      pool.failures[k] = e.msg


proc mapParallel*[T, U](
  jobs: openArray[T]; run: proc (job: T): U {.nimcall, gcsafe.}; threads = countProcessors()
): seq[U] =
  ## Answer each job by `run`, on `threads` at once at most, one for each core where caller
  ##   names none; answers stand in order of their jobs.
  result = newSeq[U](jobs.len)
  if jobs.len == 0: return
  var
    raised = newSeq[bool](jobs.len)
    failures = newSeq[string](jobs.len)
    pool = Pool[T, U](
      jobs: cast[ptr UncheckedArray[T]](jobs[0].addr),
      answers: cast[ptr UncheckedArray[U]](result[0].addr),
      raised: cast[ptr UncheckedArray[bool]](raised[0].addr),
      failures: cast[ptr UncheckedArray[string]](failures[0].addr),
      count: jobs.len,
      run: run,
    )
  let count = min(max(threads, 1), jobs.len)
  if count == 1: work(pool.addr)
  else:
    var running = newSeq[Thread[ptr Pool[T, U]]](count)
    for thread in running.mitems: createThread(thread, work[T, U], pool.addr)
    joinThreads(running)
  for k in 0 ..< jobs.len:
    if raised[k]: raise newException(CatchableError, failures[k])
