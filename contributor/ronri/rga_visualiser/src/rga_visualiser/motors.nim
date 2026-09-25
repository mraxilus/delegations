## Carry motors `pga` has not written yet, spelled as library's own operators define them.
##
## Motor is rigid motion of space held as one value: turn about line, and slide along that
## same line, together. Camera's stance is one.
##
## Transitional, and states its own end. At pinned pga head library declares no motor and
## names that absence twice as its own work: `multivectors.nim` asks for even-grade basis
## "namely for motors/flectors", and `operators.nim` names motors beside sandwich macro it
## leaves commented out. Project needs them now, so bodies stand here until library's return.
##   Library already carries every part these are built from: geometric antiproduct (`⟇`),
##   antireverse (`~∘`), weight and bulk split, and `unitize`. Nothing here reimplements one.
##   Guard below refuses to compile once pinned pga carries own `exp`, so stand-in can never
##   quietly shadow real thing, and moving pin is what removes this module.
##
## Motor lives in antiproduct's algebra rather than base product's. Table below was read off
## pinned tree by probe, never assumed, and suite pins every row:
##
##   |-----------------|---------------------------------------------------------------|
##   | Identity        | 𝟙 (`E1234`), since `⟇` is product motors compose through.     |
##   | Turn generator  | line direction (`E41`, `E42`, `E43`), which antisquares to -𝟙.|
##   | Slide generator | line moment (`E23`, `E31`, `E12`), which antisquares to 0.    |
##   | Sandwich        | `Q ⟇ m ⟇ ~∘Q`, one form for point, line and plane alike.      |
##   | Turn by +θ      | `exp(-(θ/2)𝐋̂)`, so `turnAbout` holds that sign for callers.  |
##   |-----------------|---------------------------------------------------------------|
##
##   Base product is not this algebra. Under `⟑` it is line *moment* that squares to -1, so
##   sandwich built there turns about line at infinity rather than about line meant. Trap
##   worth one line, since both products compile.
##
## Normalisation is library's `unitize`: weight norm of unit motor reads 1, for turn, slide
## and screw alike. Nothing here normalises, and finding against `unitize` belongs to library.
##
## Cost: every operation is dense 16-coefficient multivector, about 1 to 2 µs on JS backend
##   (`PROVENANCE.md`, Algebra boundary). Sandwich is two antiproducts, so about twice that.
##   Library names this as where geometric algebra falls behind linear algebra, and names
##   compact even-grade storage as its own remedy.
## Cost: `exp` and `log` split bivector through coefficient reads rather than through
##   `weight` and `bulk`, because both halves are wanted as three numbers, and named split
##   would cost two more dense multivectors for each call.

{.experimental: "strictFuncs".}

import std/[math, options]

import pga



#[ Withdrawal ]#

const HAS_OWN_MOTORS = compiles((block:
  var m: Multivector
  discard pga.exp(m)))
  ## Report whether pinned pga carries own motor exponential, i.e. whether module is spent.

when HAS_OWN_MOTORS:
  {.error: "pga at this pin defines its own `exp`; delete `motors.nim` and take motors " &
    "from `pga` in every module that imports it.".}



#[ Motor Configuration ]#

const
  BASES_TURN = [Basis.E41, Basis.E42, Basis.E43]
    ## Name bases carrying line's direction, which is half of bivector that turns.
  BASES_SLIDE = [Basis.E23, Basis.E31, Basis.E12]
    ## Name bases carrying line's moment, which is half of bivector that slides.
  ANGLE_SERIES = 1.0e-4
    ## Take series below this half-angle, in radians, rather than closed form.
    ##   `a*cos(a) - sin(a)` subtracts two values near `a` to reach one near `a³/3`, so it
    ##   loses about `3ε/a²` of its digits. At `a` of 1e-6 closed form keeps about four.
    ##   Series' own next term is `a⁴/840`, under 1e-19 here, so crossing is smooth.

const MOTOR_IDENTITY* = 1.0.e1234
  ## Hold motor that moves nothing, i.e. 𝟙.
  ##   Antiscalar rather than scalar: `⟇` is product motors compose through.



#[ Bivector Split ]#

func turnPartOf(b_line: Multivector): array[3, float] =
  ## Read direction of bivector, which is part that turns.
  for index, basis in BASES_TURN: result[index] = b_line[basis]


func slidePartOf(b_line: Multivector): array[3, float] =
  ## Read moment of bivector, which is part that slides.
  for index, basis in BASES_SLIDE: result[index] = b_line[basis]


func bivectorOf(turn, slide: array[3, float]): Multivector =
  ## Build bivector back from its two halves.
  for index, basis in BASES_TURN: result[basis] = turn[index]
  for index, basis in BASES_SLIDE: result[basis] = slide[index]


func magnitudeOf(v: array[3, float]): float =
  ## Measure length of one half of bivector.
  sqrt(v[0]*v[0] + v[1]*v[1] + v[2]*v[2])


func alignmentOf(a, b: array[3, float]): float =
  ## Measure how far one half of bivector runs along other, i.e. their dot product.
  ##   For motor's bivector this is pitch times turn's magnitude: slide along axis itself.
  a[0]*b[0] + a[1]*b[1] + a[2]*b[2]


func scalesOf(angle: float): (float, float) =
  ## Read two series that motor's exponential and logarithm share.
  ##   First is `sin(a)/a`, second is `(a*cos(a) - sin(a))/a³`. Both are finite at zero,
  ##   where they read 1 and -1/3, so neither `exp` nor `log` needs degenerate branch.
  ##   Series below `ANGLE_SERIES`, closed form above; see that constant for why.
  if abs(angle) < ANGLE_SERIES:
    let square = angle*angle
    (1.0 - square/6.0, -1.0/3.0 + square/30.0)
  else:
    let (cosine, sine) = (cos(angle), sin(angle))
    (sine/angle, (angle*cosine - sine)/(angle*angle*angle))



#[ Motors ]#

func exp*(b_line: Multivector): Multivector =
  ## Raise `e` to bivector, giving motor that carries screw it names.
  ##   Bivector's direction is half-angle turned, and its moment is half-distance slid.
  ##   `𝟙 cos(a) + sin(a)/a * 𝐁`, with dual angle `a + εb` carrying pitch; scalar term is
  ##   that dual part, which `log` reads back.
  ##   Total: pure slide falls out of same expression, since its direction is zero and both
  ##   series stay finite there. No branch, so no branch to get wrong.
  let
    (turn, slide) = (b_line.turnPartOf, b_line.slidePartOf)
    angle = turn.magnitudeOf
    along = alignmentOf(turn, slide)
    (scale_turn, scale_slide) = scalesOf(angle)
  var turned, slid: array[3, float]
  for index in 0 .. 2:
    turned[index] = scale_turn*turn[index]
    slid[index] = scale_turn*slide[index] + along*scale_slide*turn[index]
  result = bivectorOf(turned, slid)
  result[Basis.E1234] = cos(angle)
  result[Basis.scalar] = -along*scale_turn


func log*(motor: Multivector): Multivector =
  ## Read bivector whose exponential is `motor`.
  ##   Takes short way round: motor and its negation carry every point alike, so one with
  ##   negative antiscalar is read through its negation. `exp(log(q))` is then same *motion*
  ##   as `q`, and same coefficients only where `q` already turns by less than half turn.
  ##     Without it `log` of motor near full turn divides by `sin(a)/a` at `a` of π, which
  ##     is zero, and full turn names no axis to return.
  ##   Expects unit motor, which `exp` and `unitize` both give. Antiscalar and direction then
  ##   square to one together, so `cos(a)` and `sin(a)` are read straight off rather than
  ##   solved.
  let held = if motor[Basis.E1234] < 0.0: -motor else: motor
  let
    (turn, slide) = (held.turnPartOf, held.slidePartOf)
    angle = arctan2(turn.magnitudeOf, held[Basis.E1234])
    (scale_turn, scale_slide) = scalesOf(angle)
    # Recover pitch from scalar term `exp` wrote, which carried it alone.
    #   `scale_turn` never vanishes here: short way round holds `a` at or under π/2, where
    #   `sin(a)/a` stays above 0.63.
    along = -held[Basis.scalar]/scale_turn
  var turned, slid: array[3, float]
  for index in 0 .. 2:
    turned[index] = turn[index]/scale_turn
    slid[index] = (slide[index] - along*scale_slide*turned[index])/scale_turn
  bivectorOf(turned, slid)


func turnAbout*(axis: Multivector, radians: float): Option[Multivector] =
  ## Build motor turning `radians` about line `axis`, right-handed about its direction.
  ##   None where `axis` has no direction, i.e. where it lies in horizon and names no axis
  ##   to turn about. `unitize` would return such line unchanged rather than refuse.
  ##   Half-angle and its sign live here, so no caller holds either.
  if normWeight(axis)[Basis.scalarAnti] <= TOLERANCE_ABS: return
  some(exp(wedge(-0.5*radians, unitize(axis))))


func carried*(m, motor, motor_reversed: Multivector): Multivector =
  ## Carry `m` through rigid motion `motor`, whose antireverse caller already holds.
  ##   Lets caller carrying several operands through one motor take `~∘𝐐` once.
  ##   Spelled with operators: JS backend inlines neither `wedgeDotAnti` nor `reverseAnti`,
  ##   so each named call allocates and copies one more result (read in emitted JS).
  (motor ⟇ m) ⟇ motor_reversed


func carried*(m, motor: Multivector): Multivector =
  ## Carry `m` through rigid motion `motor`, i.e. 𝐐 ⟇ 𝐦 ⟇ ~∘𝐐.
  ##   One form for point, line and plane alike, since sandwich reads grade from `m`.
  ##   Expects unit motor: antireverse is inverse only there.
  carried(m, motor, ~∘ motor)
