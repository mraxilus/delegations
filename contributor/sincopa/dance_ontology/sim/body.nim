## Two bodies standing somewhere and facing some way, and where their
## shoulders are.
##
##   Body is rig's stack of cylinders on vertical axis, so all it has of
##     its own is plan position and facing.  Facing accumulates: two
##     whole turns are not no turns to anyone counting them, and couple's
##     twist is read off difference.
##   Sim has its own `Arm` and `Body` on purpose: ontology next door
##     has enums near these in meaning and this directory shares nothing with
##     it, so that what sim says is evidence rather than echo.

{.experimental: "strictFuncs".}

import std/math

import ./[rig, vec]


type
  Arm* {.pure.} = enum ## One of body's two arms, from its own point of view.
    Left, Right

  Body* {.pure.} = enum ## One of two bodies.
    One, Two

  Hand* = tuple[body: Body, arm: Arm] ## Names one of four hands.

  Stance* = object ## Where one body stands and which way it is turned.
    centre*: tuple[x, y: float] ## Plan position of its axis, metres.
    facing*: float ## Radians anticlockwise from x axis, laps and all.

  Axes* = object ## Body's own directions, in world terms.
    origin*: Vec ## Axis at floor level.
    right*, fore*: Vec ## Unit, horizontal.  Up is up.


func facing*(rig: Rig; apart: float): array[Body, Stance] =
  ## Stand two face to face, `apart` metres axis to axis: One at
  ## origin facing +y, Two along +y facing back.
  [Stance(centre: (0.0, 0.0), facing: PI / 2.0),
   Stance(centre: (0.0, apart), facing: -PI / 2.0)]

func axesOf*(st: Stance): Axes =
  ## Body's own right and forward, in world.
  let
    c = cos(st.facing)
    s = sin(st.facing)
  Axes(origin: (st.centre.x, st.centre.y, 0.0),
       right: (s, -c, 0.0), fore: (c, s, 0.0))

func toBody*(ax: Axes; p: Vec): Vec =
  ## World point in body's own terms: x to its right, y forward, z up.
  let d = p - ax.origin
  (dot(d, ax.right), dot(d, ax.fore), d.z)

func toWorld*(ax: Axes; p: Vec): Vec =
  ## Body's own terms back in world.
  ax.origin + ax.right * p.x + ax.fore * p.y + (0.0, 0.0, p.z)

func mirrored*(p: Vec): Vec = (-p.x, p.y, p.z)
  ## Body's own terms seen in mirror: left arm is right arm here.

func side*(arm: Arm): float = (if arm == Arm.Right: 1.0 else: -1.0)
  ## Which way along body's right each arm's shoulder lies.

func shoulder*(rig: Rig; st: Stance; arm: Arm): Vec =
  ## Joint's centre in world.
  toWorld(axesOf(st), (side(arm) * rig.shoulderOut, 0.0, rig.shoulderUp))

func twist*(st: array[Body, Stance]): float =
  ## How far Two has turned relative to One, radians, from face-to-face.
  st[Body.Two].facing - st[Body.One].facing + PI

func turned*(st: array[Body, Stance]; who: Body; turns: float): array[Body, Stance] =
  ## Stances with one body turned on its spot by `turns` whole turns,
  ## anticlockwise seen from above.
  result = st
  result[who].facing = result[who].facing + turns * 2.0 * PI

func lifted*(p: Vec; dz: float): Vec = (p.x, p.y, p.z + dz)
