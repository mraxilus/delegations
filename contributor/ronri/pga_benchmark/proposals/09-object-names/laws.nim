## Hold names of geometric objects as aliases of basis-set types (`object-names`).
##   Evaluation compiles this against library with change applied, at each algebra its claim
##     names; exit code is verdict: every law below holds, or program stops on assertion.
##   Names stand at rga4d and cga5d alone, algebras of 3D space book uses. Each name is alias of
##     named basis-set type of library, so it adds no type: product of P04 that reaches its bases
##     is that object, and value is library's.
##   Laws: at rga4d, wedge of two points is line and of three is plane, and motor and flector hold
##     8 coefficients of one parity; at cga5d, wedge of two round points is dipole, of three circle,
##     of four sphere. Each wedge equals library's on whole multivectors.
##   Prints name compiler gives type of wedge of two points, and of binding declared with object
##     name, since alias adds no type to print.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[random, strformat, typetraits]

import pga


static:
  doAssert (DIMENSIONS == 4 and IS_RIGID) or (DIMENSIONS == 5 and IS_CONFORMAL),
    &"Names stand at rga4d and cga5d alone; got `{DIMENSIONS=}`, `{IS_CONFORMAL=}`."

const
  SAMPLES = 256  ## Seeded samples each law is checked on.
  SEED = 0  ## Seed of sample generator, so every run checks same samples.



#[ Laws ]#

func bases[B: static Bases](t: typedesc[MultivectorOf[B]]): Bases = B
  ## Get bases basis-set type holds.


proc sample[B: static Bases](t: typedesc[MultivectorOf[B]]): MultivectorOf[B] =
  ## Sample basis-set type with each coefficient uniform in [-1, 1], narrowed from multivector.
  var m: Multivector
  for basis in B: m[basis] = Coefficient(rand(-1.0..1.0))
  toMultivectorOf[bases(Multivector), B](m)


func holdParity(m: Multivector, is_even: bool) =
  ## Hold that widened multivector lies in grades of one parity alone.
  for basis in Basis:
    if (int(basis.grade) mod 2 == 0) != is_even:
      doAssert m[basis] == 0,
        &"Basis-set type of one parity must hold no basis of other; got `{m[basis]}` at `{basis}`."


proc main(): int =
  ## Hold laws on seeded samples; print where they hold and name compiler prints, and exit zero.
  randomize(SEED)
  when IS_RIGID:
    doAssert sizeof(Motor) == 8 * sizeof(Coefficient),
      &"Motor must hold 8 coefficients, as Lengyel's; got `{sizeof(Motor)}` bytes."
    doAssert sizeof(Flector) == 8 * sizeof(Coefficient),
      &"Flector must hold 8 coefficients, as Lengyel's; got `{sizeof(Flector)}` bytes."
    for _ in 1..SAMPLES:
      let (p, q, r) = (sample(Point), sample(Point), sample(Point))
      doAssert (p ∧ q) is Line, "Point wedge point must be line."
      doAssert (p ∧ q ∧ r) is Plane, "Wedge of three points must be plane."
      doAssert (p ∧ q).toMultivector =~ (p.toMultivector ∧ q.toMultivector),
        &"Line must equal library's wedge; got `{(p ∧ q).toMultivector}`."
      doAssert (p ∧ q ∧ r).toMultivector =~
          (p.toMultivector ∧ q.toMultivector ∧ r.toMultivector),
        &"Plane must equal library's wedge; got `{(p ∧ q ∧ r).toMultivector}`."
      holdParity(sample(Motor).toMultivector, is_even = true)
      holdParity(sample(Flector).toMultivector, is_even = false)
    let
      (p, q) = (sample(Point), sample(Point))
      line: Line = p ∧ q
    echo "object-names: laws hold at 4D rigid; type of point wedge point prints as ",
      name(typeof(p ∧ q)), ", and binding declared as line prints as ", name(typeof(line))
  else:
    for _ in 1..SAMPLES:
      let (a, b, c, d) = (sample(PointRound), sample(PointRound), sample(PointRound),
          sample(PointRound))
      doAssert (a ∧ b) is Dipole, "Round point wedge round point must be dipole."
      doAssert (a ∧ b ∧ c) is Circle, "Wedge of three round points must be circle."
      doAssert (a ∧ b ∧ c ∧ d) is Sphere, "Wedge of four round points must be sphere."
      doAssert (a ∧ b).toMultivector =~ (a.toMultivector ∧ b.toMultivector),
        &"Dipole must equal library's wedge; got `{(a ∧ b).toMultivector}`."
      doAssert (a ∧ b ∧ c).toMultivector =~
          (a.toMultivector ∧ b.toMultivector ∧ c.toMultivector),
        &"Circle must equal library's wedge; got `{(a ∧ b ∧ c).toMultivector}`."
      doAssert (a ∧ b ∧ c ∧ d).toMultivector =~
          (a.toMultivector ∧ b.toMultivector ∧ c.toMultivector ∧ d.toMultivector),
        &"Sphere must equal library's wedge; got `{(a ∧ b ∧ c ∧ d).toMultivector}`."
    let
      (a, b) = (sample(PointRound), sample(PointRound))
      dipole: Dipole = a ∧ b
    echo "object-names: laws hold at 5D conformal; type of round point wedge round point ",
      "prints as ", name(typeof(a ∧ b)), ", and binding declared as dipole prints as ",
      name(typeof(dipole))
  0


when isMainModule:
  quit main()
