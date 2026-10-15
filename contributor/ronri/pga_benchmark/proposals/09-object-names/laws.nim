## Hold names of geometric objects as aliases of basis-set types of P04 (`object-names`).
##   Evaluation compiles this against library at pin, at each algebra its claim names; exit code
##     is verdict: every law below holds, or program stops on assertion.
##   Names stand at rga4d and cga5d alone, algebras of 3D space book uses. Each name is alias of
##     named basis-set type of P04, so it adds no type: product that reaches its bases is that
##     object, and value is library's.
##   Laws: at rga4d, wedge of two points is line and of three is plane, and motor and flector hold
##     8 floats of one parity; at cga5d, wedge of two round points is dipole, of three circle,
##     of four sphere. Each wedge equals library's on whole multivectors.
##   Prints name compiler gives type of wedge of two points, and of binding declared with object
##     name, since alias adds no type to print.
##
##   Cost: imports prototype of P04, since its basis-set types live there alone; record says so.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[importutils, random, strformat, typetraits]

import pga

import "../04-exact-kinds/prototype"


static:
  doAssert (DIMENSIONS == 4 and IS_RIGID) or (DIMENSIONS == 5 and IS_CONFORMAL),
    &"names stand at rga4d and cga5d alone; got `{DIMENSIONS=}`, `{IS_CONFORMAL=}`."

when IS_RIGID:
  type
    Point* = Kvector1  ## Define point of 3D space, grade 1 of rga4d.
    Line* = Kvector2  ## Define line, grade 2 of rga4d.
    Plane* = Kvector3  ## Define plane, grade 3 of rga4d.
    Motor* = MultivectorEven  ## Define motor, even grades of rga4d.
    Flector* = MultivectorOdd  ## Define flector, odd grades of rga4d.
else:
  type
    RoundPoint* = Kvector1  ## Define round point of 3D space, grade 1 of cga5d.
    Dipole* = Kvector2  ## Define dipole, grade 2 of cga5d.
    Circle* = Kvector3  ## Define circle, grade 3 of cga5d.
    Sphere* = Kvector4  ## Define sphere, grade 4 of cga5d.

const
  SAMPLES = 256  ## Seeded samples each law is checked on.
  SEED = 0  ## Seed of sample generator, so every run checks same samples.



#[ Laws ]#

proc draw[B: static set[Basis]](kind: typedesc[MultivectorOf[B]]): MultivectorOf[B] =
  ## Draw basis-set type with every slot uniform in [-1, 1].
  ##   Writes private field, as prototype's own sampler does, since no product starts from nothing.
  privateAccess(MultivectorOf)
  for index in 0..<result.elements.len: result.elements[index] = rand(-1.0..1.0)


proc holdParity(m: Multivector, is_even: bool) =
  ## Hold that widened multivector lies in grades of one parity alone.
  for basis in Basis:
    if (int(basis.grade) mod 2 == 0) != is_even:
      doAssert m[basis] == 0, "basis-set type of one parity holds no basis of other"


proc main(): int =
  ## Hold laws on seeded samples; print where they hold and name compiler prints, and exit zero.
  randomize(SEED)
  when IS_RIGID:
    doAssert sizeof(Motor) == 8 * sizeof(float), "motor holds 8 floats, as Lengyel's"
    doAssert sizeof(Flector) == 8 * sizeof(float), "flector holds 8 floats, as Lengyel's"
    for _ in 1..SAMPLES:
      let (p, q, r) = (draw(Point), draw(Point), draw(Point))
      doAssert (p ∧ q) is Line, "point wedge point is line"
      doAssert (p ∧ q ∧ r) is Plane, "wedge of three points is plane"
      doAssert (p ∧ q).toMultivector =~ (p.toMultivector ∧ q.toMultivector),
        "line equals library's wedge"
      doAssert (p ∧ q ∧ r).toMultivector =~
          (p.toMultivector ∧ q.toMultivector ∧ r.toMultivector),
        "plane equals library's wedge"
      holdParity(draw(Motor).toMultivector, is_even = true)
      holdParity(draw(Flector).toMultivector, is_even = false)
    let
      (p, q) = (draw(Point), draw(Point))
      line: Line = p ∧ q
    echo "object-names: laws hold at 4D rigid; type of point wedge point prints as ",
      name(typeof(p ∧ q)), ", and binding declared as line prints as ", name(typeof(line))
  else:
    for _ in 1..SAMPLES:
      let (a, b, c, d) = (draw(RoundPoint), draw(RoundPoint), draw(RoundPoint), draw(RoundPoint))
      doAssert (a ∧ b) is Dipole, "round point wedge round point is dipole"
      doAssert (a ∧ b ∧ c) is Circle, "wedge of three round points is circle"
      doAssert (a ∧ b ∧ c ∧ d) is Sphere, "wedge of four round points is sphere"
      doAssert (a ∧ b).toMultivector =~ (a.toMultivector ∧ b.toMultivector),
        "dipole equals library's wedge"
      doAssert (a ∧ b ∧ c ∧ d).toMultivector =~
          (a.toMultivector ∧ b.toMultivector ∧ c.toMultivector ∧ d.toMultivector),
        "sphere equals library's wedge"
    let
      (a, b) = (draw(RoundPoint), draw(RoundPoint))
      dipole: Dipole = a ∧ b
    echo "object-names: laws hold at 5D conformal; type of round point wedge round point ",
      "prints as ", name(typeof(a ∧ b)), ", and binding declared as dipole prints as ",
      name(typeof(dipole))
  0


when isMainModule:
  quit main()
