## Draw each of app's frames, through marks workbench settled.
##
##   This is only place two vocabularies meet.  Model says `Side`
##     and `Site` -- hand of lead, hand of follow, told apart by
##     their types -- and drawing says `Arm` for either, told apart by
##     which dancer is holding it.  Translating is whole of this module.
##   It reaches model through `../frame` and **never** through
##     `../rotation`, which is not oversight: rotation names `Dancer`,
##     `Level` and `Way` of its own, and its `Way` is clockwise against
##     anticlockwise where drawing's is lock against wrap.  Module that
##     imported both would have to say which it meant at every use, and would
##     eventually say wrong one.  So this takes plain `facing: bool` and
##     lets `diagram` do arithmetic that needs rotation's words.
##   Every scene is built **at compile time**.  Nothing here has side
##     effect, so whole chain -- settling hands, routing each
##     connection round bodies, breaking one that passes underneath
##     -- runs in compiler and what ships is sixteen strings.
##     Which is worth more than speed: app regenerates its whole page
##       on every interaction, and router that ran per draw would run
##       thousands of times per second for answer that never changes.  It
##       also keeps routing out of browser bundle entirely, and it
##       formats every coordinate once, in one backend, so JS build
##       cannot round last digit differently from C one.
##     Cost of building them all: every frame is drawn whether session
##       ever shows it or not.  Accepted -- there are sixteen, and whole
##       table is smaller than code that would make one.

{.experimental: "strictFuncs".}

import std/[options, strutils]

import ../frame
import ./[figure, pose, terms]


const HOW_MANY = FRAMES.len * 2
  ## Every frame, facing and turned: whole of what picture can say.
  ##   Follow's facing is only rotation frame picture carries, and
  ##     only its parity, so half turn and one and one-half turns draw alike.


func armOf(side: Side): Arm {.compileTime.} =
  ## Read hand of lead as side of body.
  case side
  of Side.Left: Arm.L
  of Side.Right: Arm.R

func armOf(site: Site): Arm {.compileTime.} =
  ## Read hand of follow same way.
  ##   Two are separate types in model so that nothing can hold one
  ##     where it means other; here they land on one word, because
  ##     drawing puts them on same two sides of two bodies.
  case site
  of Site.LeftHand: Arm.L
  of Site.RightHand: Arm.R


func holdsOf(target: Frame): Holds {.compileTime.} =
  ## Say what each of lead's arms holds, as drawing takes it.
  for side in Side:
    if target.hold[side].isSome:
      result[armOf(side)] = some armOf(target.hold[side].get)


func poseFor(facing: bool): Pose {.compileTime.} =
  ## Stand couple up: lead facing up page, follow facing them
  ## or facing away.
  ##   Canonicalised like every other pose, though at rest it changes nothing,
  ##     because that is what makes two poses of same configuration
  ##     same picture and this should not be one place it is skipped.
  canonicalise(spinAbout(rest(), Dancer.Follow, if facing: 0.0 else: 180.0))


func sceneOf(target: Frame; facing: bool): string {.compileTime.} =
  ## Draw one frame: two bodies, their hands, and what joins them.
  ##   No level is said, because `Frame` does not carry one -- levels live
  ##     in `rotation.Posture` and nothing hands them here yet.  So every
  ##     hand draws hollow, which is what unsaid level looks like, and
  ##     free hand is same outline at half strength.  What is held is
  ##     said by connection running out of it.
  ##   No captions: this picture is drawn as small as node on map, where
  ##     word beside hand is smudge.  Shape says whose hand it is and
  ##     colour says which side, and both survive any size.
  partsOf(poseFor(facing), holdsOf(target), captions = false,
          over = (if target.over.isSome: some armOf(target.over.get)
                  else: none(Arm))).join("")


func buildScenes(): array[HOW_MANY, string] {.compileTime.} =
  ## Draw every frame model has, both ways round, once and for all.
  for i, target in FRAMES:
    for k, facing in [true, false]:
      result[i * 2 + k] = sceneOf(target, facing)


const SCENES = buildScenes()
  ## Every frame picture, drawn in compiler and shipped as text.


func sceneFor*(target: Frame; facing: bool): string =
  ## Get picture of this frame, seen with follow facing or turned.
  ##   Invalid frame has no picture rather than blank one: it is not
  ##     state, so there is nothing to draw and nothing to make up.
  let at = frameIndex(target)
  if at.isNone:
    return ""
  SCENES[at.get * 2 + (if facing: 0 else: 1)]
