## Probe every mechanism audit enforces, on domain-neutral ring of steps modulo `MODULUS`.
##   Project exists to be checked, not used: build-time configuration validated statically,
##   distinct type over range, symbolic operator with named alias, poisoned operator,
##   Unicode identifier, banner, matrix test. Merge-process probes branch from
##   `curator/probe/probe-<name>` and touch README.md only.
##
##   |----------|----------|---------------------------------------|
##   | Code     | Notation | Meaning                               |
##   |----------|----------|---------------------------------------|
##   | Step     | s        | position on ring, 0 .. MODULUS − 1    |
##   | x ⊕ y    | x ⊕ y    | advance x by y, modulo MODULUS        |
##   | s.invert | −s       | step returning s to 𝟎                 |
##   | 𝟎        | 0        | identity step                         |
##   |----------|----------|---------------------------------------|
##
##   Cost: `+` on steps is poisoned, so plain integer arithmetic never leaks modulus.
##   Cost model unread: no hot path exists; every operation is one addition (unmeasured).

{.experimental: "strictFuncs".}


const MODULUS* {.define: "probe.modulus".} = 4
  ## Ring size; validated statically below.

static:
  doAssert MODULUS in 2 .. 16, "Modulus should be in range 2..16; got `" & $MODULUS & "`."


type Step* = distinct range[0 .. MODULUS - 1]
  ## Define position on ring of `MODULUS` steps.


const 𝟎* = Step(0)
  ## Identity step; Unicode identifier exercises rune-counted width and prose scanner.


func `==`*(a, b: Step): bool {.borrow.}
  ## Compare steps by position.

func position*(s: Step): int {.inline.} = int(s)
  ## Read position of step.



#[ Ring ]#

func `⊕`*(x, y: Step): Step =
  ## Advance step `x` by step `y`, i.e. (x + y) mod MODULUS.
  Step((x.position + y.position) mod MODULUS)

func advance*(x, y: Step): Step {.inline.} = x ⊕ y
  ## Advance step by step.
  ##   I.e. add through `⊕`; reach for name in prose, symbol in equations.

func invert*(s: Step): Step =
  ## Read step that advances `s` back to `𝟎`, i.e. (MODULUS − s) mod MODULUS.
  Step((MODULUS - s.position) mod MODULUS)

func `+`*(x, y: Step): Step {.error: "Use `⊕` or `advance`; plain `+` ignores modulus.".}
  ## Poison plain sum of steps.

func `$`*(s: Step): string =
  ## Render step as its position.
  $s.position
