## Sample main thread's call stack on timer, and count whose code each sample was in.
##
## Timer counts main thread's own CPU time, so every sample is busy one.
##   Wait in vsync or in event poll spends no CPU, so it is never sampled.
##   `timer_create` on `CLOCK_THREAD_CPUTIME_ID`, delivering `SIGPROF` to that thread alone
##   (`SIGEV_THREAD_ID`), which is Linux's own.
##     macOS would need `setitimer(ITIMER_PROF)`, and Windows has no `SIGPROF`; sampler is
##     unavailable there, and panel says so.
## Handler walks Nim's own frames (`getFrame`), which build keeps only where stack traces are on.
##   Debug build `tools/build.nim desktop` makes keeps them; release build does not, and
##   sampler is then unavailable rather than wrong.
##   Sample landing in frame push or pop of tiny library proc, as `[]`, misses its frame, so
##   share reads low against native unwinding; figures in `PROVENANCE.md`.
## Handler allocates nothing and takes no lock.
##   It walks frames from innermost out to first one `share.ownerOfPath` names side for, as
##   `share` rules, and adds one to that side atomically.
##   Main thread drains counts by atomic exchange, so no sample is lost or counted twice.

{.experimental: "strictFuncs".}

import ../rga_visualiser/share


const
  IS_SAMPLER_BUILT* = defined(linux) and compileOption("stacktrace")
    ## Say whether this build can sample at all: Linux timer, and Nim's frames to walk.
  NANOSECONDS_SAMPLE = 4_000_000
    ## Set CPU time between two samples: 250 each busy second.
    ##   Overhead measured as none at that rate; figures in `PROVENANCE.md`.



#[ Sampling ]#

var COUNTS_SAMPLED: CountsShare
  ## Count samples by owner since last `drainSamples`.
  ##   Written by signal handler, drained by main thread, both atomically.


proc ownerOfFrames*(innermost: PFrame): Owner {.stackTrace: off.} =
  ## Name owner of stack whose innermost frame is `innermost`: first frame out that has one.
  ##   Reads and allocates nothing beyond frames, so signal handler may call it.
  var frame = innermost
  while frame != nil:
    let owner = ownerOfPath(frame.filename)
    if owner != Owner.Rest: return owner
    frame = frame.prev
  Owner.Rest

when IS_SAMPLER_BUILT:
  {.emit: """
#include <signal.h>
#include <time.h>
#include <unistd.h>
#include <sys/syscall.h>
#ifndef SIGEV_THREAD_ID
#define SIGEV_THREAD_ID 4
#endif

static timer_t timer_sampler;
static int is_timer_sampler = 0;

static int samplerArm(long nanoseconds, void (*handler)(int)) {
  if (!is_timer_sampler) {
    struct sigaction action = {0};
    action.sa_handler = handler;
    action.sa_flags = SA_RESTART;
    sigemptyset(&action.sa_mask);
    if (sigaction(SIGPROF, &action, NULL) != 0) return -1;
    struct sigevent event = {0};
    event.sigev_notify = SIGEV_THREAD_ID;
    event.sigev_signo = SIGPROF;
#ifdef sigev_notify_thread_id
    event.sigev_notify_thread_id = (pid_t)syscall(SYS_gettid);
#else
    event._sigev_un._tid = (pid_t)syscall(SYS_gettid);
#endif
    if (timer_create(CLOCK_THREAD_CPUTIME_ID, &event, &timer_sampler) != 0) return -1;
    is_timer_sampler = 1;
  }
  struct itimerspec spec = {{0, nanoseconds}, {0, nanoseconds}};
  return timer_settime(timer_sampler, 0, &spec, NULL);
}

static int samplerDisarm(void) {
  if (!is_timer_sampler) return 0;
  struct itimerspec spec = {{0, 0}, {0, 0}};
  return timer_settime(timer_sampler, 0, &spec, NULL);
}
""".}

  proc samplerArm(nanoseconds: clong, handler: proc (signal: cint) {.noconv.}): cint
    {.importc, nodecl.}
  proc samplerDisarm(): cint {.importc, nodecl.}

  proc onSample(signal: cint) {.noconv, stackTrace: off.} =
    ## Name owner of stack this sample interrupted, and count it.
    ##   Pushes no frame of its own: it walks frames that interrupted code pushed.
    atomicInc(COUNTS_SAMPLED[ownerOfFrames(getFrame())])


var IS_SAMPLING = false  ## Say whether timer is armed.

proc startSampling*(): bool =
  ## Arm timer on calling thread, which must be main thread; report whether it is armed.
  ##   Arming twice is harmless; build that cannot sample reports false.
  when IS_SAMPLER_BUILT:
    if not IS_SAMPLING:
      IS_SAMPLING = samplerArm(clong(NANOSECONDS_SAMPLE), onSample) == 0
  IS_SAMPLING


proc stopSampling*() =
  ## Disarm timer; counts not yet drained stay until `drainSamples`.
  when IS_SAMPLER_BUILT:
    if IS_SAMPLING: discard samplerDisarm()
  IS_SAMPLING = false


proc isSampling*(): bool = IS_SAMPLING
  ## Report whether timer is armed.


proc drainSamples*(): CountsShare =
  ## Take every count since last drain, and leave zero behind.
  for owner in Owner:
    result[owner] = atomicExchangeN(addr COUNTS_SAMPLED[owner], 0, ATOMIC_RELAXED)
