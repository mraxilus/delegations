## Two bodies standing somewhere and facing some way, and where their
## shoulders are.
##
##   Body is rig's stack of cylinders on vertical axis, so all it has of
##     its own is plan position and facing.  Facing accumulates: two
##     whole turns are not no turns to anyone counting them, and couple's
##     twist is read off difference.
##   Simulation has its own `Arm` and `Body` on purpose: ontology next door
##     has enums near these in meaning and this directory shares nothing with
##     it, so that what simulation says is evidence rather than echo.

{.experimental: "strictFuncs".}

import std/[math, options]

import ./[rig, vector]


type
  Arm* {.pure.} = enum  ## One of body's two arms, from its own point of view.
    Left, Right

  Body* {.pure.} = enum  ## One of two bodies.
    One, Two

  Hand* = tuple[body: Body, arm: Arm]  ## Names one of four hands.

  Stance* = object  ## Where one body stands and which way it is turned.
    centre*: tuple[x, y: float]  ## Plan position of its axis, metres.
    facing*: float  ## Radians anticlockwise from x axis, laps and all.

  Axes* = object  ## Body's own directions, in world terms.
    origin*: Vector  ## Axis at floor level.
    right*, fore*: Vector  ## Unit, horizontal.  Up is up.


func facing*(rig: Rig, apart: float): array[Body, Stance] =
  ## Stand two face to face, `apart` metres axis to axis: One at
  ## origin facing +y, Two along +y facing back.
  [Stance(centre: (0.0, 0.0), facing: PI / 2.0),
   Stance(centre: (0.0, apart), facing: -PI / 2.0)]

func axesOf*(stance: Stance): Axes =
  ## Body's own right and forward, in world.
  let
    c = cos(stance.facing)
    s = sin(stance.facing)
  Axes(origin: (stance.centre.x, stance.centre.y, 0.0), right: (s, -c, 0.0), fore: (c, s, 0.0))

func toBody*(axes: Axes, point: Vector): Vector =
  ## World point in body's own terms: x to its right, y forward, z up.
  let d = point - axes.origin
  (dot(d, axes.right), dot(d, axes.fore), d.z)

func toWorld*(axes: Axes, point: Vector): Vector =
  ## Body's own terms back in world.
  axes.origin + axes.right * point.x + axes.fore * point.y + (0.0, 0.0, point.z)

func mirrored*(point: Vector): Vector = (-point.x, point.y, point.z)
  ## Body's own terms seen in mirror: left arm is right arm here.

func side*(arm: Arm): float = (if arm == Arm.Right: 1.0 else: -1.0)
  ## Which way along body's right each arm's shoulder lies.

func shoulder*(rig: Rig, stance: Stance, arm: Arm): Vector =
  ## Joint's centre in world.
  toWorld(axesOf(stance), (side(arm) * rig.shoulder_out, 0.0, rig.shoulder_up))

func twist*(stance: array[Body, Stance]): float =
  ## How far Two has turned relative to One, radians, from face-to-face.
  stance[Body.Two].facing - stance[Body.One].facing + PI

func turned*(stance: array[Body, Stance], who: Body, turns: float): array[Body, Stance] =
  ## Stances with one body turned on its spot by `turns` whole turns,
  ## anticlockwise seen from above.
  result = stance
  result[who].facing = result[who].facing + turns * 2.0 * PI

func quartersTo*(stance: array[Body, Stance], who: Body): Option[int] =
  ## Where this body sees other, in whole quarter turns clockwise from its own
  ## front: nought ahead, one at its right, two behind, three at its left.
  ##   Clockwise, so turning on spot to right steps through them in order.
  ##   None between quarters: body there sees other at no one side.
  let
    here = stance[who]
    there = stance[if who == Body.One: Body.Two else: Body.One]
    bearing = arctan2(there.centre.y - here.centre.y, there.centre.x - here.centre.x)
    quarters = floorMod(here.facing - bearing, 2.0 * PI) / (PI / 2.0)
  if abs(quarters - round(quarters)) < 1e-6: some(int(round(quarters)) mod 4)
  else: none(int)

func lifted*(point: Vector, delta_z: float): Vector = (point.x, point.y, point.z + delta_z)
  ## Raise point by `delta_z`.
