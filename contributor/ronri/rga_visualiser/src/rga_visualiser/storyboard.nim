## Replay construction one operation per step, for capture without hand on mouse.
##
## Each step goes through same `applyOperation` and `addObject` GUI's apply button calls, so
## exported frames show what clicking would have produced.
##   Doubles as visual regression harness: frames are comparable between builds.
## Steps name operands by index into scene, which is dense and grows by one per step, so
## index is stable once written.
##   Seeds occupy indices 0 to 4; every later index is step that produced it.
##
##   |-------|-------------------|--------------------------------------------------|
##   | Index | Object            | Origin                                           |
##   |-------|-------------------|--------------------------------------------------|
##   | 0,1,2 | `a`, `b`, `c`     | Seed points, placed by hand.                     |
##   | 3     | o                 | World origin, placed by hand; kept off `G` (see  |
##   |       |                   |   step 08) so it has something to project onto.  |
##   | 4     | ground            | Seed plane, joined from three points at z = 0.   |
##   | 5+    | one per step      | Result of step's own operation.                  |
##   |-------|-------------------|--------------------------------------------------|
##
## Shared by desktop (`visualiser.nim`) and browser (`bridge.nim`) render paths.

{.experimental: "strictFuncs".}

import std/strformat

import pga
import ./[boundary, tessellate, scene]



#[ Type Definitions ]#

type Step* = object ## Define one scripted construction step.
  stem*: string ## File name stem frame after this step is written under.
  label*: string ## Name derived object carries in scene.
  operation*: Operation ## Operation applied to operands below.
  index_first*: int ## Scene index of left operand.
  index_second*: int ## Scene index of right operand; ignored where operation is unary.
  ink*: Ink ## Palette slot derived object is drawn with.



#[ Scripted Construction ]#

const STEPS*: array[11, Step] = [
  Step(stem: "01_join_line", label: "L = a ∧ b",
    operation: Operation.Wedge, index_first: 0, index_second: 1, ink: Ink.Jade),
  Step(stem: "02_join_plane", label: "G = L ∧ c",
    operation: Operation.Wedge, index_first: 5, index_second: 2, ink: Ink.Cobalt),
  Step(stem: "03_meet_line", label: "ground v G",
    operation: Operation.WedgeAnti, index_first: 4, index_second: 6, ink: Ink.Copper),
  Step(stem: "04_meet_point", label: "L v ground",
    operation: Operation.WedgeAnti, index_first: 5, index_second: 4, ink: Ink.Rose),
  Step(stem: "05_support", label: "sup(L)",
    operation: Operation.Support, index_first: 5, index_second: 0, ink: Ink.Rose),
  Step(stem: "06_attitude", label: "att(L)",
    operation: Operation.Attitude, index_first: 5, index_second: 0, ink: Ink.Cobalt),
  Step(stem: "07_expand_weight", label: "a ∧ L☆  perp plane",
    operation: Operation.ExpandWeight, index_first: 0, index_second: 5, ink: Ink.Olive),
  # Project `o`, only seed off `G`.
  #   `a`, `b`, `c` lie on `G` by construction, so their projection would show nothing.
  Step(stem: "08_project", label: "o onto G",
    operation: Operation.ProjectOrthogonal, index_first: 3, index_second: 6, ink: Ink.Rose),
  # Take attitude down grade by grade.
  #   Line gave point at horizon (06); plane gives line at horizon; grade-4 volume gives
  #   plane at horizon, one universal object every plane at horizon is.
  #   See `objects.directionNormalHorizon`.
  Step(stem: "09_attitude_line_horizon", label: "Lh = att(G)",
    operation: Operation.Attitude, index_first: 6, index_second: 0, ink: Ink.Jade),
  Step(stem: "10_wedge_volume", label: "a ∧ ground",
    operation: Operation.Wedge, index_first: 0, index_second: 4, ink: Ink.Copper),
  Step(stem: "11_attitude_plane_horizon", label: "Ph = att(a ∧ ground)",
    operation: Operation.Attitude, index_first: 14, index_second: 0, ink: Ink.Cobalt),
] ## Script of every step, in order.
  ##   Line from two points, plane from that line, then meet, measure and project.
  ##   Closes with attitude taken down to line, then plane, at horizon.


const
  INK_SEED_GROUND* = Ink.Olive
    ## Reserve ink startup scene's ground plane wears.
    ##   Reserved rather than cycled: `ground` is seed every later step derives against, and
    ##   reader learns to find it by colour.

  INK_SEED_ORIGIN* = Ink.Copper
    ## Reserve ink startup scene's origin point wears.
    ##   Reserved as `INK_SEED_GROUND` is: origin is one point not arbitrary.
    ##   `a`, `b` and `c` step over both reserved hues, leaving them exactly three
    ##   categorical run has left.


proc constructSeeds*(scene: var Scene, now: float = 0.0) =
  ## Place three points and ground plane every later step derives from.
  ##   `now` is forwarded to `addObject` untouched, so seeds animate in as any object does.
  let
    point_a = toMultivector(Position(x: 3.0, y: -2.0, z: 2.5))
    point_b = toMultivector(Position(x: -2.5, y: 2.0, z: 5.5))
    point_c = toMultivector(Position(x: 1.0, y: 4.0, z: 3.0))
    point_origin = toMultivector(Position(x: 0, y: 0, z: 0))
    point_x = toMultivector(Position(x: 1, y: 0, z: 0))
    point_y = toMultivector(Position(x: 0, y: 1, z: 0))
    ground = point_origin ∧ point_x ∧ point_y
    # Centre ground's circle on three points that built it.
    #   `creationAnchor` does same for every later plane; plane built from three points at
    #   once goes through no single `Operation`.
    #   Each point unitized so sum's weight is three and position is centroid.
    anchor_ground = position(
      add(add(unitize(point_origin), unitize(point_x)), unitize(point_y))
    )
  # Give each seed own hue, skipping two reserved ones, so nothing collides.
  var index_ink = 0
  proc inkNext(): Ink =
    while inkCycled(index_ink) in [INK_SEED_GROUND, INK_SEED_ORIGIN]: inc index_ink
    result = inkCycled(index_ink)
    inc index_ink
  scene.addObject(point_a, "a", inkNext(), now)
  scene.addObject(point_b, "b", inkNext(), now)
  scene.addObject(point_c, "c", inkNext(), now)
  scene.addObject(point_origin, "o", INK_SEED_ORIGIN, now)
  scene.addObject(ground, "ground", INK_SEED_GROUND, now, anchor_ground)


func applyStep*(scene: var Scene, step: Step, now: float = 0.0): Multivector {.discardable.} =
  ## Apply one step, appending its result exactly as GUI's apply button would.
  ##   Reports derived geometry directly: caller naming what step produced cannot assume
  ##   it landed in last handle of dense array.
  doAssert scene.isAlive(step.index_first) and scene.isAlive(step.index_second),
    &"Storyboard step must name operands scene has built; got `{step.index_first}` and " &
      &"`{step.index_second}`."
  let
    operand_first = scene[step.index_first].geometry
    operand_second = scene[step.index_second].geometry
  result = applyOperation(step.operation, operand_first, operand_second)
  let anchor = creationAnchor(step.operation, operand_first, operand_second, result)
  scene.addObject(result, step.label, step.ink, now, anchor)
