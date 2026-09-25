## Orbit camera about pivot, and assemble transforms OpenGL draws through.
##
## Stance is one rigid motion. `Camera.motor` carries reference stance to where camera
## stands, and everything below is read off it:
##
##   |-------------|------------------------|--------------------------------------------|
##   | Identifier  | Construction           | Meaning                                    |
##   |-------------|------------------------|--------------------------------------------|
##   | eye         | 𝐐 ⟇ 𝐨 ⟇ ~∘𝐐            | Point eye stands at.                       |
##   | forward     | 𝐐 ⟇ 𝐟 ⟇ ~∘𝐐            | Unit direction eye looks along.            |
##   | axis_right  | 𝐐 ⟇ 𝐫 ⟇ ~∘𝐐            | Unit direction of view's +x.               |
##   | axis_up     | 𝐐 ⟇ 𝐮 ⟇ ~∘𝐐            | Unit direction of view's +y.               |
##   | pivot       | eye + depth * forward   | Point orbit turns about.                   |
##   | azimuth     | arctan2(-fʸ, -fˣ)       | Angle about world up.                      |
##   | elevation   | arcsin(-fᶻ)             | Angle above horizon.                       |
##   |-------------|------------------------|--------------------------------------------|
##
##   `𝐨`, `𝐟`, `𝐫` and `𝐮` are `EYE_REFERENCE`, `FORWARD_REFERENCE`, `RIGHT_REFERENCE` and
##   `UP_REFERENCE`. Motion itself is `motors.nim`, which stands in until library writes it.
##
## Pivot and both angles are read out rather than stored.
##   Stored beside stance, one could go stale against another: dolly left pivot where no
##   angle pointed.
##   Rotor has no pole, so `frame` needs no clamp. `ELEVATION_LIMIT` bounds only stance
##   rebuilt from angles, and nothing derives through it.
## Only projection is left to convention.
##   Perspective divide, depth range and clip volume belong to graphics pipeline rather
##   than to geometry, so they are written out directly.
## Stance is turntable, since that is what mouse drag turns.
##   `orbit` rebuilds motion from four turntable numbers, so no roll creeps in. Every other
##   verb composes motion directly, because none of them turns.
##
## Shared by desktop (`visualiser.nim`) and browser (`bridge.nim`) render paths.

# Reorder so stance reads before frame derived from it, though `pan` calls `frame`.
#   Constants below stay in dependency order regardless, as reordering does not cover them.
{.experimental: "codeReordering".}
{.experimental: "strictFuncs".}

import std/[math, options]

# `pga` arrives through `projections`, which stands in for four it has withdrawn.
import ./projections
import ./[boundary, motors, tessellate]



#[ Camera Configuration ]#

const
  TOLERANCE_CULL_CLIP = 0.001
    ## Keep cull's near and far one part in thousand inside GPU's own clip.
    ##   Rounding then never culls point GPU would draw; see `viewBoundsFor`.
  UP_WORLD* = Direction(x: 0.0, y: 0.0, z: 1.0)
    ## Fix world's up direction, which azimuth turns about and elevation rises from.
  EYE_REFERENCE* = Position(x: 0.0, y: 0.0, z: 0.0)
    ## Place reference stance's eye, which `Camera.motor` carries to where eye stands.
  RIGHT_REFERENCE* = Direction(x: 0.0, y: 1.0, z: 0.0)
    ## Fix reference stance's +x across, which motor carries to `FrameCamera.axis_right`.
  UP_REFERENCE* = Direction(x: 0.0, y: 0.0, z: 1.0)
    ## Fix reference stance's +y up, which motor carries to `FrameCamera.axis_up`.
  FORWARD_REFERENCE* = Direction(x: -1.0, y: 0.0, z: 0.0)
    ## Fix reference stance's sight direction, which motor carries to `FrameCamera.forward`.
    ##   Three above are turntable's own axes at azimuth 0 and elevation 0, and not OpenGL's
    ##   reference triple. Taking OpenGL's would put fixed 120 degree turn in every
    ##   construction, for no reader's benefit: `initMatrixView` reads axes, never motor.
  ELEVATION_LIMIT* = 0.5*PI - 0.02
    ## Bound elevation short of pole, where sight axis would run along `UP_WORLD`.
  COSINE_POLE_ROLL* = 0.996
    ## Bound how near sight may come to `UP_WORLD` and still have roll read off it.
    ##   Five degrees. Roll against world up is angle between camera's own up and that
    ##   direction projected across sight, and sight running along it leaves nothing to
    ##   project: reading is noise before it is undefined. See `rollHeld`.
  DISTANCE_LIMIT_NEAR* = 1.0e-9
    ## Bound how close eye may orbit to pivot, through `distanceHeld`.
    ##   Only bound on where camera may stand.
    ##     At orbit distance zero eye coincides with pivot, sight axis is undefined, and
    ##     every direction `frame` derives collapses.
    ##   Tiny, not small: demo's moons ring their planets at thousandths of unit and are
    ##   millionths wide, and floor of twentieth kept camera outside every one of them.
    ##     Records are stored about pivot (`mesh.MeshSet.origin`), so float32 holds this
    ##     close-up wherever pivot stands; see `initMatrixViewProjection`.
    ##   No far bound: nothing downstream needs ceiling.
    ##     Clip planes are fractions of orbit distance (`FACTOR_CLIP_NEAR`,
    ##     `FACTOR_CLIP_FAR`), so frustum keeps shape, and grid bounds own line count
    ##     (`tessellate.CELLS_GRID_HALF_MAX`).
    ##     What degrades far out is float32 in what stands far from pivot: object million
    ##     units from it carries under tenth of unit, which is invisible at that reach.
  MARGIN_REACH_FAR* = 1.05
    ## Widen far bound past scene's reach by this, so farthest object never sits on it.
  SLACK_CLIP_FAR* = 1.0/1024.0
    ## Hold projective depth this far under far plane at any depth: `initMatrixProjection`
    ##   sends depth toward `1 - SLACK_CLIP_FAR` rather than 1, so nothing far clips.
    ##   Depth buffer takes fragment's logarithm (`depthOf`), so projective depth only
    ##   clips, and slack costs nothing.
    ##   Not `(far + near)/(far - near)` with far at star field's reach: farthest stars and
    ##   sky dome then sat within two float32 ulps of far plane, and Android GPU's rounding
    ##   clipped them, points flickering as camera moved and dome drawn in patches.
    ##   Suite reads flattened float32 matrix for farthest star and dome at four orbit
    ##   distances and holds margin over half of this.
  FACTOR_CLIP_FAR* = 20.0
    ## Set far bound this many orbit distances out, or at scene's reach where farther.
    ##   Scaled alone clipped field away as zoom carried orbit distance down to foreground
    ##   star: twenty of thirty units is six hundred, and field is three thousand across.
    ##   See `distanceFar` and `Camera.reach_scene`.
    ##   Scaled rather than fixed so everything meant to read in horizon
    ##   (`tessellate.radiusHorizonFor`, `tessellate.extentFurnitureFor`, far end of
    ##   every drawn line) stays past what frame shows at any orbit distance.
    ##   Fixed plane cannot: view's extent grows with distance while plane does not, so
    ##   dollying out brings line's far end inside frame, and clips pivot away once eye
    ##   orbits past it.
  STEP_SINGLE* = 1.0/16_777_216.0
    ## Fix float32's own relative step, which is two to power of minus twenty-four.
    ##   Position stored `r` from records' origin carries about `r*STEP_SINGLE` of error.
  FRACTION_ORIGIN_HOLD* = 0.25
    ## Spend at most this fraction of near clip on float32 error about records' origin.
    ##   Nothing nearer than near clip is drawn, so near clip is finest thing on screen,
    ##   and quarter of it is error no reader resolves.
    ##   Sets how far camera travels before origin follows; see `originHeld`.
  FRACTION_VIEW_CENTRED* = 2.0/3.0
    ## Fix fraction of frame that counts as being looked at.
    ##   This much of height, and this much of width *or height, whichever is less*;
    ##   `reachCentred` writes that shape down.
    ##   Box rather than whole frame: object clinging to edge is on screen without being
    ##   what view is about, and marker ringing it is half off-frame.
    ##   Not exact middle: selection is *framed* inside box, spread across it.
    ##   Here rather than beside pixel test in `picking` because camera needs it too, to
    ##   solve how far back eye must stand (`distanceFitting`), and `picking` imports this.
  FRACTION_HELD_CANVAS* = 1.0/3.0
    ## Fix smallest sphere finger's orbit holds, as share of canvas's short side at pivot.
    ##   Centre of it then turns about as fast as half turn per short side did, which
    ##   Architect found almost right; see `radiusHeld`.
  FRACTION_HELD_INSIDE* = 0.9
    ## Bound sphere finger's orbit holds to this share of eye's separation from pivot.
    ##   Eye inside sphere would meet it from behind, and hold point it cannot see.
  FACTOR_CLIP_NEAR* = 1.0/400.0
    ## Set near clip plane this fraction of orbit distance out.
    ##   Scaled beside `FACTOR_CLIP_FAR` so frustum stays same shape at every distance.
    ##   Never raised: depth is logarithmic (`depthOf`), so far plane reaching scene
    ##   millions of units out costs near end nothing, where linear depth had near raised
    ##   to half orbit distance to hold ratio and still lost far field on device.

const
  ## Fix rates held key moves camera at, per second of holding.
  ##   Shared by both front-ends, unlike per-pixel drag rates: `visualiser.SPEED_ORBIT` is
  ##   radians per pixel and browser scripts works in fractions of canvas width. Held key has no
  ##   pixels in it.
  ##   Per second, not per press.
  ##     Per-press steps leaned on operating system's auto-repeat: movement began after
  ##     repeat delay and arrived in stutters.
  ##     `interaction.driveHeld` applies these once per frame, scaled by elapsed time, so
  ##     distance depends on hold length, not draw rate.
  ##   Sized so reader crosses useful range in second or two of holding, while still
  ##   controllable in short taps.
  TURN_SECOND* = 1.4 ## Azimuth held arrow turns through per second, in radians.
  RISE_SECOND* = 1.1 ## Elevation held arrow rises through per second, in radians.
  FACTOR_DOLLY_SECOND* = 4.0 ## Orbit distance held key scales by per second, dollying out.
    ## Reciprocal dollies in, so second each way returns exactly.
    ## Compounded as power of elapsed seconds, never multiplied per frame: per-frame
    ## scale would move 144 Hz reader more than twice as far as 60 Hz one.
  FACTOR_HASTE* = 4.0 ## Multiply every rate above by this while shift is held.
    ## Shift means *faster* on every movement key rather than something different on
    ## each: what Blender, Unity, Unreal and Godot all do.
  ROLL_SECOND* = 1.4 ## Angle held roll key turns sight axis through per second, in radians.
    ## Same rate as `TURN_SECOND`: both are turns of whole view, and reader learns one feel.

const
  ## Fix speed curve free flight accelerates along while movement key is held.
  ##   Held key climbs toward cap and never reaches it, so reader crosses decades of scale
  ##   with one key rather than reaching for haste at every one.
  ##   Cap is smaller of two figures, and `capTravelling` takes that minimum.
  SECONDS_SPEED_RISE* = 0.6
    ## Set time constant of climb toward cap, in seconds of holding.
    ##   Speed reaches 63 percent of cap at this, 95 percent at three of these.
    ##   Sized so tap of quarter second still moves camera about third of cap's rate,
    ##   while hold of two seconds is at full rate.
  FACTOR_SPEED_LOCAL* = 1.2
    ## Cap speed at this many depths under pointer per second.
    ##   Reader pointing at moon crosses moon's own distance in same time as one pointing
    ##   at star crosses star's, so one key serves every scale in orrery.
    ##   Equals flat rate ground slide ran at before free flight, so long hold settles on
    ##   speed that build already had.
  SPEED_CEILING* = 300_000.0
    ## Cap speed at this many units per second, whatever pointer reports.
    ##   Reached where pointer is over empty sky, which has no depth to scale by.
    ##   Crosses star field's reach of about 6.5 million units in about 22 seconds, so
    ##   farthest catalogued star is minute away and nothing is unreachable.
    ##   Fixed rather than read from scene: `reach_scene` is stamped by whoever owns scene,
    ##   and speed that changed as objects were added would be speed nobody learns.
  SPEED_LIGHT* = 1.0/499.0
    ## Fix speed of light in this world's own units, at one unit one astronomical unit.
    ##   Light crosses astronomical unit in 499 seconds; see `orrery.nim`.
    ##   Reporting unit alone. Panel divides speed by this, so reader reads multiple of
    ##   `c` rather than units per second, which matches scale bar's own reading.
    ##   Never cap: `SPEED_CEILING` is about 1.5e8 of these, and camera held to `c` would
    ##   take two and half hours to cross opening view of 19 units.



#[ Type Definitions ]#

type
  Matrix4* = object ## Define 4x4 transform in column-major order, as OpenGL expects.
    ## Double precision: picking reads it against world coordinates of millions of units,
    ## where float32 translation column carried tenths of unit of error. GPU takes float32
    ## copy through `flattened`, of transform about frame's origin, whose translation is
    ## small; see `initMatrixViewProjection`.
    elements: array[16, float]

  Camera* = object ## Define stance of eye about pivot, and lens it looks through.
    ## Stance is one rigid motion and one depth. Where eye stands and which way it faces are
    ## `motor` alone; pivot is read off sight line at `depth_pivot`.
    ##   Orbit angles are read out rather than stored; see `azimuth` and `elevation`.
    ##   Rotor has no pole, so `ELEVATION_LIMIT` bounds only stance rebuilt from angles, never
    ##   derivation.
    motor*: Motor ## Rigid motion carrying reference stance to this one.
      ## Reference stance places eye at world origin, facing `FORWARD_REFERENCE`, with
      ## `RIGHT_REFERENCE` across and `UP_REFERENCE` up. Turntable at azimuth 0, elevation
      ## 0, distance 0, pivot at origin, which is why `initCamera` reads as two turns.
    depth_pivot: float ## How far along sight line pivot stands from eye.
      ## Private, and read through `distance`.
      ##   Pivot is derived here where it was stored before, so assignment to it would move
      ##   pivot while eye stood, where it once moved eye while pivot stood. Opposite
      ##   readings of one spelling, so spelling is withdrawn and `dolly`, `dollyTo` and
      ##   `repivotToDepth` say which is meant.
    degrees_field_of_view*: float ## Vertical field of view, in degrees.
    reach_near*: float ## How far nearest drawn object stands ahead of eye, along sight.
      ## Scale frustum and furniture take, in place of separation from pivot; see
      ## `scaleLocal`.
      ##   Zero where nothing is drawn ahead, which hands scale back to separation.
      ##   Stamped by whoever owns scene, as `reach_scene` is, and once for each frame
      ##   rather than for each overlay call: it reads every placement, and
      ##   `ensureViewOverlay` runs many times over one frame.
      ##   Depth along sight rather than distance, and never behind eye: what reader turned
      ##   away from is not drawn, and scale read off it would follow that.
    reach_scene*: float ## How far farthest finite object stands from world origin.
      ## Disc's own reach included; zero for empty scene, which leaves far clip scaled alone.
      ## Stamped by whoever owns scene at each derivation point, from `framing.reachOf`;
      ## `distanceFar` reads it so far clip never cuts scene away. Never trusted across
      ## replacement of camera value: `home` builds fresh camera carrying zero.

  FrameCamera* = object ## Define orthonormal directions of camera's own axes.
    axis_right*: Direction ## Unit direction of view's +x.
    axis_up*: Direction ## Unit direction of view's +y.
    forward*: Direction ## Unit direction eye looks along.



#[ Matrix Arithmetic ]#

func at*(matrix: Matrix4; row, column: int): float = matrix.elements[4*column + row]
  ## Read element of matrix, addressed as reader writes it rather than as GPU stores it.


func flattened*(matrix: Matrix4): array[16, float32] =
  ## Copy matrix into float32 in GPU's own order, for uniform upload on either front-end.
  for index in 0 .. 15: result[index] = float32(matrix.elements[index])


func `*`*(a, b: Matrix4): Matrix4 =
  ## Compose transforms, applying `b` before `a`.
  for row in 0 .. 3:
    for column in 0 .. 3:
      var sum = 0.0
      for i in 0 .. 3:
        sum += a.at(row, i) * b.at(i, column)
      result.elements[4*column + row] = sum


func initMatrixProjection*(degrees_field_of_view, aspect, distance_near: float): Matrix4 =
  ## Construct perspective projection onto OpenGL's clip volume, with no far plane.
  ##   Camera looks along its own -z, as pipeline expects. Depth `D` maps to
  ##   `(1 - slack) - (2 - slack)*near/D`: -1 at near plane, toward `1 - SLACK_CLIP_FAR`
  ##   as depth grows, never reaching 1, so far plane clips nothing at any depth; see
  ##   `SLACK_CLIP_FAR`. Depth buffer itself takes `depthOf` per fragment.
  let focal = 1.0 / tan(0.5 * degToRad(degrees_field_of_view))
  result.elements[0] = focal / aspect
  result.elements[5] = focal
  result.elements[10] = -(1.0 - SLACK_CLIP_FAR)
  result.elements[11] = -1.0
  result.elements[14] = -(2.0 - SLACK_CLIP_FAR) * distance_near


func initMatrixView*(eye: Position, frame: FrameCamera): Matrix4 =
  ## Construct transform carrying world into camera's own frame.
  ##   Rows hold camera axes, so transform is inverse of camera's stance.
  let (right, up, forward) = (frame.axis_right, frame.axis_up, frame.forward)
  let offset = eye - Position(x: 0, y: 0, z: 0)
  result.elements = [
    right.x, up.x, -forward.x, 0.0,
    right.y, up.y, -forward.y, 0.0,
    right.z, up.z, -forward.z, 0.0,
    -dot(right, offset), -dot(up, offset), dot(forward, offset),
    1.0,
  ]



#[ Camera Stance ]#

func distanceHeld*(distance: float): float = max(distance, DISTANCE_LIMIT_NEAR)
  ## Hold orbit distance off one value it may not take; see `DISTANCE_LIMIT_NEAR`.
  ##   Every path writing distance goes through here (construction, dolly, both
  ##   front-ends' numeric fields, fitted distance framing solves), so floor is stated
  ##   once.
  ##   Replaced `clamp` written at each site, shape limit takes when site is missed.


func motorTurntable*(pivot: Position; distance, azimuth, elevation: float): Motor =
  ## Build rigid motion carrying reference stance to turntable stance named.
  ##   Three motions, rightmost first, since motors compose right to left.
  ##     Slide reference eye to `pivot` plus `distance` along +x, where reference faces -x.
  ##     Turn by `-elevation` about line through pivot along +y, which raises eye.
  ##     Turn by `azimuth` about line through pivot along world up, which swings it round.
  ##   Every axis is line through pivot, so neither turn moves pivot, and `distance` and
  ##   pivot survive both.
  ##   Held equal to `eye` and `frame` of stance built from same four numbers, by suite case.
  let
    pivot_point = toMultivector(pivot)
    axis_azimuth = pivot_point ∧ toMultivector(UP_WORLD)
    axis_elevation = pivot_point ∧ toMultivector(RIGHT_REFERENCE)
    slid = motorSliding(toMultivector(Direction(
      x: pivot.x + distance, y: pivot.y, z: pivot.z
    )))
  # Fall back to slide alone where pivot lies on either axis line.
  #   Cannot happen: axis is join of pivot with direction, so it always carries that
  #   direction, and `turnAbout` refuses only line with none.
  let turn_azimuth = turnAbout(axis_azimuth, azimuth)
  let turn_elevation = turnAbout(axis_elevation, -elevation)
  if turn_azimuth.isNone or turn_elevation.isNone: return motorOf(slid)
  motorOf(wedgeDotAnti(
    wedgeDotAnti(turn_azimuth.get, turn_elevation.get), slid
  ))


func initCamera*(pivot: Position; distance, azimuth, elevation: float): Camera =
  ## Construct camera orbiting `pivot` at given separation and angles.
  ##   Angles are parametrisation of one stance, and not what stance holds; see `Camera`.
  let settled = distanceHeld(distance)
  Camera(
    motor: motorTurntable(
      pivot, settled, azimuth, clamp(elevation, -ELEVATION_LIMIT, ELEVATION_LIMIT)
    ),
    depth_pivot: settled,
    degrees_field_of_view: 45.0,
  )


func initCameraDefault*(): Camera =
  ## Place camera where both front-ends open, and where `home` puts it back.
  ##   One statement: stance written out in each front-end and key returning to it
  ##   would be three copies.
  ##   Shows seed scene whole, slightly above ground so plane reads as plane rather than
  ##   line.
  initCamera(
    pivot = Position(x: 0, y: 0, z: 1), distance = 19.0, azimuth = 1.05, elevation = 0.42
  )


func rollHeld*(camera: Camera): Option[float] =
  ## Read camera's roll about its sight, against `UP_WORLD`, or none near pole.
  ##   Positive `roll` lowers this reading.
  ##   Read by suite, which holds page's drag in `interaction.turnFollowing` to leaving it.
  let frame = camera.frame
  if abs(dot(frame.forward, UP_WORLD)) >= COSINE_POLE_ROLL: return none(float)
  some(arctan2(dot(frame.axis_right, UP_WORLD), dot(frame.axis_up, UP_WORLD)))


func scaleLocal*(camera: Camera): float =
  ## Read distance frustum and furniture take their scale from.
  ##   Reach to nearest drawn object where one is stamped, and separation from pivot where
  ##   none is.
  ##     Separation alone kept scale of stance reader set off from: near clip is one
  ##     four-hundredth of it, and camera flying from opening stance at planet met that
  ##     plane long before planet.
  ##     Never pointer's own depth, which `capTravelling` reads: `SettingsFurniture`
  ##     compares exactly, so pointer figure would rebuild grid at every pointer move, and
  ##     would move `depthLogScale` while camera stood still.
  ##   Held off zero, since every reader divides or scales by it.
  if camera.reach_near > 0.0: camera.reach_near else: max(camera.distance, DISTANCE_LIMIT_NEAR)


func distanceFar*(camera: Camera): float =
  ## Read far bound depth's logarithm spans and horizon stands within; see `distanceNear`
  ##   for why derived. Nothing clips at it: see `initMatrixProjection`.
  ##   Twenty orbit distances, or eye's distance to origin plus scene's reach where that
  ##   is farther, so logarithm spans whole scene; see `FACTOR_CLIP_FAR`.
  ##   Ratio to near is unbounded; `depthOf` is what makes that affordable.
  let eye = camera.eye
  let away = sqrt(eye.x*eye.x + eye.y*eye.y + eye.z*eye.z)
  max(camera.scaleLocal*FACTOR_CLIP_FAR, away + camera.reach_scene*MARGIN_REACH_FAR)


func distanceNear*(camera: Camera): float =
  ## Read nearest depth clip volume keeps.
  ##   Derived from local scale rather than stored, so it cannot go stale through dolly.
  ##   One four-hundredth of that scale; see `FACTOR_CLIP_NEAR` and `scaleLocal`.
  camera.scaleLocal*FACTOR_CLIP_NEAR


func depthLogScale*(camera: Camera): float =
  ## Read scale depth's logarithm is mapped by this frame; see `depthOf`.
  2.0/log2(camera.distanceFar/camera.distanceNear)


func depthOf*(camera: Camera, depth: float): float =
  ## Map view depth to clip depth, in -1 .. 1, as every shader does.
  ##   Logarithmic: `log2(depth/near)` over `log2(far/near)`, so buffer's steps are spread
  ##   evenly over decades and resolution is fixed fraction of distance at every distance.
  ##     Linear depth spends nearly all of its steps inside first few orbit distances:
  ##     with far at scene's reach millions of units out, whole star field and sky dome
  ##     fell into buffer's last steps, and on device with coarse depth every object past
  ##     few hundred thousand units failed test and vanished, while sixteen-bit buffer
  ##     could not hold moon before its planet at same time.
  ##   Reference of every fragment shader on both front-ends: each writes this of its own
  ##   view depth, through `EXT_frag_depth` or GL 3.3's `gl_FragDepth`. Page without
  ##   extension keeps linear depth. Suite pins this against sixteen-bit step for moon
  ##   before planet, star before sky, and monotone across every decade scene spans.
  ##   Fragment only, never clip position: clipper interpolates clip coordinates linearly
  ##   and cuts where interpolated depth meets plane, so corner behind eye mapped far past
  ##   far plane had its triangle cut beside its front corner, and plane's disc ended at
  ##   hard chord under camera standing inside it. Projective clip depth keeps near cut
  ##   where it belongs and never far clips; driven check reads disc under camera.
  log2(depth/camera.distanceNear)*camera.depthLogScale - 1.0


func distance*(camera: Camera): float = camera.depth_pivot
  ## Read separation of eye from pivot.
  ##   Read-only: see `Camera.depth_pivot` for why no spelling assigns to it.


func eyeCarried(motion, motion_reversed: Multivector): Position =
  ## Carry reference stance's own eye through lifted motion and its antireverse.
  let placed = position(toMultivector(EYE_REFERENCE).carried(motion, motion_reversed))
  # Fall back to reference eye only in name.
  #   Unit motor carries unit-weight point to unit-weight point, so read cannot refuse.
  if placed.isSome: placed.get else: EYE_REFERENCE


func borne(motion, motion_reversed: Multivector; d: Direction): Direction =
  ## Carry reference direction through lifted motion, and read back weightless result.
  let carried_direction = toMultivector(d).carried(motion, motion_reversed)
  Direction(
    x: carried_direction[Basis.E1],
    y: carried_direction[Basis.E2],
    z: carried_direction[Basis.E3],
  )


func frameCarried(motion, motion_reversed: Multivector): FrameCamera =
  ## Carry reference stance's three axes through lifted motion and its antireverse.
  ##   Motor is rigid, so three carried directions stay orthonormal and stay weightless:
  ##   no join to refuse, no antidual sign to pin, and no clamp to keep them defined.
  FrameCamera(
    axis_right: borne(motion, motion_reversed, RIGHT_REFERENCE),
    axis_up: borne(motion, motion_reversed, UP_REFERENCE),
    forward: borne(motion, motion_reversed, FORWARD_REFERENCE),
  )


func eye*(camera: Camera): Position =
  ## Place eye by carrying reference stance's own eye through camera's motion.
  ##   Held equal to spherical closed form by suite case, which is what `motorTurntable`
  ##   reproduces.
  let motion = toMultivector(camera.motor)
  eyeCarried(motion, ~∘ motion)


func frame*(camera: Camera): FrameCamera =
  ## Derive camera's orthonormal axes by carrying reference stance's three through motion.
  let motion = toMultivector(camera.motor)
  frameCarried(motion, ~∘ motion)


func sight*(camera: Camera): (Position, FrameCamera) =
  ## Read eye and frame together, off one lift of motor and one antireverse.
  ##   Caller wanting both reads this rather than `eye` and `frame`, which lift motor and
  ##   take its antireverse once each. Per event on finger's and mouse's turn.
  let motion = toMultivector(camera.motor)
  let motion_reversed = ~∘ motion
  (eyeCarried(motion, motion_reversed), frameCarried(motion, motion_reversed))


func pivot*(camera: Camera): Position =
  ## Place point orbit turns about, on sight line at `distance` from eye.
  ##   Derived where it was stored before, so dolly cannot leave it stale.
  ##   Carries eye and forward alone: other two axes do not place it.
  let motion = toMultivector(camera.motor)
  let motion_reversed = ~∘ motion
  let (eye, forward) = (
    eyeCarried(motion, motion_reversed), borne(motion, motion_reversed, FORWARD_REFERENCE)
  )
  Position(
    x: eye.x + camera.depth_pivot*forward.x,
    y: eye.y + camera.depth_pivot*forward.y,
    z: eye.z + camera.depth_pivot*forward.z,
  )


func depthAlong*(eye: Position; forward: Direction; place: Position): float =
  ## Measure signed depth of `place` along sight: its height over plane through eye square
  ##   to `forward`, positive ahead. `objects.depthAgainst` on `objects.planeThrough`.
  ##   For camera's own geometry: which way it turns, how far it repivots, what it frames.
  ##   Depth that only clips or sizes picture is picture's, and stays there.
  depthAgainst(planeThrough(toMultivector(eye), toMultivector(forward)), toMultivector(place))


func azimuthElevationFor*(heading: Direction): (float, float) =
  ## Solve orbit angles camera needs to look along `heading`.
  ##   Regardless of pivot or distance: `eye`'s formula cancels pivot out of `forward`
  ##   entirely, so this is plain spherical-coordinates inverse of same offset.
  ##   For aiming capture of horizon object's direction: unlike finite one, it is not
  ##   anchored anywhere fixed demo angle frames.
  let elevation = arcsin(clamp(-heading.z, -1.0, 1.0))
  let azimuth = arctan2(-heading.y, -heading.x)
  (azimuth, elevation)


func azimuth*(camera: Camera): float = camera.frame.forward.azimuthElevationFor[0]
  ## Read angle about world up, in radians.
  ##   Read off sight direction rather than stored; see `Camera`.


func elevation*(camera: Camera): float = camera.frame.forward.azimuthElevationFor[1]
  ## Read angle above horizon, in radians.
  ##   Read off sight direction rather than stored; see `Camera`.


func slideBy*(camera: var Camera, offset: Multivector) =
  ## Slide whole camera by weightless `offset` point, leaving which way it faces alone.
  ##   World slide composed on left, so it moves eye and leaves every axis: slide carries
  ##   weightless direction unchanged.
  ##   Every caller assembles its offset as multivector sum, so nothing reads coefficients
  ##   out and back in on this path.
  camera.motor = motorOf(wedgeDotAnti(
    motorSliding(offset), toMultivector(camera.motor)
  ))


func turnedAboutPivot(camera: Camera; pivot: Position; along: Direction, radians: float): Motor =
  ## Turn stance about line through `pivot` along `along`, leaving pivot where it stands.
  ##   Sibling of `turnedAboutEye`, with pivot where eye was: that is what makes this
  ##   orbit rather than look.
  ##   Composed on left, so angle is read in world rather than in reference stance.
  ##   Pivot comes from caller, which has read it off this same stance with frame it needs.
  let axis = toMultivector(pivot) ∧ toMultivector(along)
  let turn = turnAbout(axis, radians)
  if turn.isNone: return camera.motor
  motorOf(wedgeDotAnti(turn.get, toMultivector(camera.motor)))


func orbit*(camera: var Camera; turn, rise: float) =
  ## Turn eye about pivot by given angles, about camera's own axes.
  ##   Composed rather than rebuilt from four turntable numbers, which carry no roll.
  ##     Sphere about bare point has no pole, so there is no clamp either.
  ##     `ELEVATION_LIMIT` is left to stances rebuilt from angles, which do collapse at pole.
  ##   Arguments read as `look`'s do, and with same signs, so one drag feeds either verb.
  ##   Pivot and separation both survive, because both axes run through pivot.
  ##   Frame is read again between two turns, for reason `look` gives.
  block:
    let (eye, frame) = camera.sight
    camera.motor = camera.turnedAboutPivot(
      eye + camera.depth_pivot*frame.forward, frame.axis_up, turn
    )
  block:
    let (eye, frame) = camera.sight
    camera.motor = camera.turnedAboutPivot(
      eye + camera.depth_pivot*frame.forward, frame.axis_right, -rise
    )


func acrossLevel(frame: FrameCamera): Direction =
  ## Read level axis at right angles to sight, signed to agree with camera's own across.
  ##   Normal to pencil sight and world up span: their join is horizon line, and
  ##   `directionNormalHorizon` reads its normal. Unit.
  ##   Camera's own across where sight runs along world up, pencil collapses, and no level
  ##   axis is named.
  let level = directionNormalHorizon(toMultivector(frame.forward) ∧ toMultivector(UP_WORLD))
  if level.isNone: return frame.axis_right
  if innerOf(toMultivector(level.get), toMultivector(frame.axis_right)) >= 0.0: level.get
  else: -level.get


func dolly*(camera: var Camera, factor: float) =
  ## Scale separation of eye from pivot, holding it off near bound.
  ##   Eye slides along sight line and pivot stands, which is what dolly means.
  ##     Pivot is derived now, so holding it means sliding eye by what separation gave up,
  ##     then naming new separation.
  let settled = distanceHeld(camera.depth_pivot*factor)
  camera.slideBy(wedge(
    camera.depth_pivot - settled, toMultivector(camera.frame.forward)
  ))
  camera.depth_pivot = settled


func dollyTo*(camera: var Camera, distance: float) =
  ## Set separation of eye from pivot outright, holding it off near bound.
  ##   For reader typing figure into numeric field, where `dolly` takes factor.
  ##   Through `dolly`, so one statement says what holding pivot means.
  if camera.depth_pivot <= 0.0: return
  camera.dolly(distanceHeld(distance)/camera.depth_pivot)


func dollyToward*(camera: var Camera, factor: float, anchor: Position) =
  ## Scale separation of eye from pivot by `factor`, moving eye along its line to `anchor`.
  ##   Rather than straight in, so whatever stands there keeps its pixel: how map zooms,
  ##   wheel taking reader toward what they point at, not middle of frame.
  ##   Why anchor keeps pixel: angles do not change, so sight direction is fixed, and eye
  ##   stays on line joining it to `anchor`; point on view ray through pixel is still on
  ##   it afterwards.
  ##   Scale applied is read back from `distanceHeld` rather than assumed, so zoom
  ##   stopped by near floor moves eye by exactly as much as distance allowed.
  ##   Pivot needs no arithmetic of its own: it is read off sight line at separation, so
  ##   naming new separation lands it where old body assembled it by hand.
  if camera.depth_pivot <= 0.0: return
  let
    distance_settled = distanceHeld(camera.depth_pivot*factor)
    scale = distance_settled/camera.depth_pivot
    # Step eye along its own line to anchor, as one multivector expression.
    #   Difference of two unit-weight points is direction, and scaling one leaves it
    #   direction, so this is weightless throughout.
    step = wedge(scale - 1.0, subtract(
      toMultivector(camera.eye), toMultivector(anchor)
    ))
  camera.slideBy(step)
  camera.depth_pivot = distance_settled


func repivotToDepth*(camera: var Camera, depth: float) =
  ## Move pivot along sight line to `depth` from eye, leaving picture unchanged.
  ##   Eye and sight direction stay; only separation moves, so nothing on screen shifts.
  ##   What turntable revolves about, and what every rate scaled by orbit distance reads,
  ##   then follows what reader looks at: zoom that carried eye up to planet while pivot
  ##   stayed on Sol far behind left every orbit swinging planet across frame.
  ##   Held off near floor as every distance is.
  ##   One assignment now: pivot is read off sight line at this depth, so naming depth moves
  ##   it and moves nothing else. Eye and every axis live in `motor`, which stands.
  camera.depth_pivot = distanceHeld(depth)


#[ Camera Flight ]#

func turnedAboutEye(camera: Camera; along: Direction, radians: float): Motor =
  ## Turn stance about line through eye along `along`, leaving eye where it stands.
  ##   Axis is join of eye with direction, so turn fixes eye and carries every axis.
  ##     Same construction `motorTurntable` turns about, with eye where pivot was.
  ##   Composed on left, so angle is read in world rather than in reference stance.
  ##   Falls back to stance standing where direction is weightless, which carried axis
  ##   never is.
  let axis = toMultivector(camera.eye) ∧ toMultivector(along)
  let turn = turnAbout(axis, radians)
  if turn.isNone: return camera.motor
  motorOf(wedgeDotAnti(turn.get, toMultivector(camera.motor)))


func turnAboutEye*(camera: var Camera; along: Direction, radians: float) =
  ## Turn camera about line through eye along `along`, leaving eye where it stands.
  ##   For caller whose axis is neither of camera's own: horizon bounds turn about axis
  ##   solved from where star stands, and nothing about frame names it.
  camera.motor = camera.turnedAboutEye(along, radians)


func look*(camera: var Camera; turn, rise: float) =
  ## Turn which way eye faces, leaving eye where it stands.
  ##   Arguments read as `orbit`'s do, so one drag feeds either verb unchanged: `turn`
  ##   swings sight as azimuth does, `rise` raises eye's own reading as elevation does.
  ##     Signs match `motorTurntable`, which turns by `+azimuth` about up and `-elevation`
  ##     about across.
  ##   Axes are camera's own, never world's, so there is no pole and no clamp.
  ##     Yaw about world up would tip sight as roll accumulated, and would stall at pole.
  ##   Pivot rides along, since it is read off sight line: free flight turns about eye, and
  ##   nothing anchors what `distance` separates from.
  ##   Frame is read again between two turns. Across axis after yaw is not across axis
  ##   before it, and pitching about stale one tips up axis off sight: that is roll nobody
  ##   asked for.
  camera.motor = camera.turnedAboutEye(camera.frame.axis_up, turn)
  camera.motor = camera.turnedAboutEye(camera.frame.axis_right, -rise)


func wrapAngle(radians: float): float =
  ## Bring angle into half-open turn about zero, so smaller of two turns reads smaller.
  floorMod(radians + PI, 2.0*PI) - PI


func turnsCarrying(frame: FrameCamera; held, under: Direction): (Direction, float, float) =
  ## Solve turntable's turn that carries `under` onto `held`: level axis, pitch, yaw.
  ##   Pitch about level across axis first, by what lifts `under` to `held`'s height; then
  ##   yaw about world up, by what closes their bearings. Neither changes roll.
  ##     Two pitches reach that height, and each has its yaw. Pair that turns least is
  ##     taken: other one flips sight half turn about world up, and carries just as
  ##     exactly.
  ##   Height out of pitch's reach, as for pixel far off middle near pole, takes nearest
  ##   height it reaches, and what finger holds slips under it there.
  ##   Neither direction needs to be unit. Directions only: where turn stands is caller's.
  ##   Geometry is algebra's: directions are weightless points, `ahead` is normal to pencil
  ##   of world up and `across`, heights are inner products, and lift is sandwich through
  ##   `turnAbout`'s motor. Angles are read out of what those return.
  let
    across = frame.acrossLevel
    up = toMultivector(UP_WORLD)
    level = toMultivector(across)
    ahead = toMultivector(directionNormalHorizon(up ∧ level).get(frame.forward))
    toward = ^∙ toMultivector(under)
    target = ^∙ toMultivector(held)
    along_ahead = innerOf(toward, ahead)
    along_up = innerOf(toward, up)
    reach = hypot(along_ahead, along_up)
    axis = 1.0.e4 ∧ level
  func lifted(pitch: float): Multivector =
    ## Carry `toward` about `across` by `pitch`, as right hand turns.
    let turn = turnAbout(axis, pitch)
    if turn.isNone: toward else: toward.carried(turn.get)
  func bearing(pitch: float): float =
    ## Solve yaw about world up that closes bearing of lifted `toward` on `target`'s.
    let raised = lifted(pitch)
    let
      (raised_x, raised_y) = (raised[Basis.E1], raised[Basis.E2])
      (target_x, target_y) = (target[Basis.E1], target[Basis.E2])
    if hypot(raised_x, raised_y) <= 1.0e-12 or hypot(target_x, target_y) <= 1.0e-12:
      return 0.0
    wrapAngle(arctan2(target_y, target_x) - arctan2(raised_y, raised_x))
  # Turning by `pitch` about `across` takes `ahead` toward `UP_WORLD`, so height becomes
  #   `reach*cos(pitch - phase)`.
  #   Each pitch's bearing is one sandwich, so each is taken once and kept.
  if reach <= 1.0e-12: return (across, 0.0, bearing(0.0))
  let
    phase = arctan2(along_ahead, along_up)
    spread = arccos(clamp(innerOf(target, up)/reach, -1.0, 1.0))
    rising = wrapAngle(phase + spread)
    falling = wrapAngle(phase - spread)
    (bearing_rising, bearing_falling) = (bearing(rising), bearing(falling))
  if rising^2 + bearing_rising^2 <= falling^2 + bearing_falling^2:
    (across, rising, bearing_rising)
  else:
    (across, falling, bearing_falling)


func lookCarrying*(camera: var Camera; held, under: Direction) =
  ## Turn which way eye faces as turntable does, so `held` comes to be seen where `under` is.
  ##   Finger's free aim: `held` runs through pixel finger left, `under` through pixel it
  ##   reached, both read off this frame. So sky under finger moves with finger, pixel for
  ##   pixel, and drag that comes back brings camera back. See `turnsCarrying`.
  let (across, pitch, bearing) = camera.frame.turnsCarrying(held, under)
  camera.motor = camera.turnedAboutEye(across, pitch)
  camera.motor = camera.turnedAboutEye(UP_WORLD, bearing)


func radiusHeld*(camera: Camera; width, height: int; reach_selection: float): float =
  ## Size sphere about pivot that finger's orbit holds.
  ##   Selection's own reach from pivot, so what is picked follows finger over its extent;
  ##   no smaller than `FRACTION_HELD_CANVAS` of short side at pivot's depth, so single
  ##   point still gives finger something to hold; inside `FRACTION_HELD_INSIDE` of
  ##   separation, so eye stays outside it.
  let
    half_height = tan(0.5*degToRad(camera.degrees_field_of_view))
    per_pixel = 2.0*camera.distance*half_height/float(height)
    least = FRACTION_HELD_CANVAS*per_pixel*float(min(width, height))
  min(max(reach_selection, least), FRACTION_HELD_INSIDE*camera.distance)


func pointHeld*(eye, pivot: Position; heading: Direction; radius: float): Position =
  ## Place point finger's orbit holds along sight `heading` from `eye`.
  ##   On sphere of `radius` about `pivot`, nearer side, where ray passes within
  ##   `radius/sqrt(2)` of pivot. Beyond, on sheet that ray's miss sets: lifted toward eye
  ##   by `radius^2/(2*miss)`, which meets sphere at that bound with same slope.
  ##     Sphere alone runs out at its rim, where tiny drag asks for whole quarter turn;
  ##     sheet carries on past it, and finger off sphere still turns view.
  ##   Always on ray, so point held is under pixel exactly; only its distance from pivot
  ##   leaves sphere, and there turn carries direction and lets distance slip.
  ##   Eye and pivot passed in, not camera: per finger event, twice, and each is sandwich.
  ##   Algebra's: ray is join of eye with heading, `nearest` is pivot's depth over plane
  ##   through eye square to it, and `miss` is pivot's distance from its orthogonal
  ##   projection onto ray. Point held is eye plus weightless heading, scaled.
  let
    place_eye = toMultivector(eye)
    place_pivot = toMultivector(pivot)
    along = ^∙ toMultivector(heading)
    ray = place_eye ∧ along
    nearest = depthAgainst(planeThrough(place_eye, along), place_pivot)
    miss = distanceBetween(^ projectOrthogonal(place_pivot, ray), place_pivot)
    back =
      if miss <= radius/sqrt(2.0): sqrt(radius*radius - miss*miss)
      else: radius*radius/(2.0*miss)
  position(place_eye + (nearest - back)*along).get(eye)


func orbitCarrying*(camera: var Camera; held, under: Direction) =
  ## Turn eye about pivot as turntable does, so point `held` off pivot comes to be seen
  ## where point `under` off pivot is seen now.
  ##   Finger's orbit: both are points `pointHeld` places under pixel finger left and pixel
  ##   it reached, less pivot. Turn about pivot keeps sphere they lie on, so point finger
  ##   took moves with finger, pixel for pixel. See `turnsCarrying`.
  let (eye, frame) = camera.sight
  camera.orbitCarrying(held, under, frame, eye + camera.depth_pivot*frame.forward)


func orbitCarrying*(
  camera: var Camera; held, under: Direction; frame: FrameCamera; pivot: Position
) =
  ## Turn as `orbitCarrying` above, with frame and pivot caller has already read off stance.
  ##   Finger's turn reads them once for both pixels it maps, so stance is read once per event.
  ##   Second turn reads pivot again rather than reuse it: turn about pivot leaves pivot, but
  ##   only to rounding, and one read keeps result bit for bit what it was.
  let (across, pitch, bearing) = frame.turnsCarrying(held, under)
  camera.motor = camera.turnedAboutPivot(pivot, across, pitch)
  camera.motor = camera.turnedAboutPivot(camera.pivot, UP_WORLD, bearing)


func roll*(camera: var Camera, radians: float) =
  ## Turn camera about its own sight axis, leaving eye and sight direction alone.
  ##   Positive tips up axis toward across axis, which reader reads as clockwise roll.
  ##   Only verb reaching sixth degree of freedom. Turntable had none: `motorTurntable`
  ##   rebuilds from four numbers, and roll is not one of them.
  camera.motor = camera.turnedAboutEye(camera.frame.forward, radians)


func travel*(camera: var Camera; ahead, across, rise: float) =
  ## Slide camera along its own three axes, leaving which way it faces alone.
  ##   World units, unlike drag rates, which take fractions of separation.
  ##     Caller scales: free flight reads its own speed curve, which has no separation in
  ##     it; see `speedTravelling`.
  ##   `ahead` dives where sight dives: fly reading, not map one.
  let axes = camera.frame
  camera.slideBy(add(
    add(
      wedge(ahead, toMultivector(axes.forward)),
      wedge(across, toMultivector(axes.axis_right)),
    ),
    wedge(rise, toMultivector(axes.axis_up)),
  ))


func travelAlong*(camera: var Camera; step: float; heading: Direction) =
  ## Slide camera by `step` units along `heading`, leaving which way it faces alone.
  ##   For wheel travelling pointer's own ray, which is no axis of camera's frame.
  ##   Caller hands unit direction; length of one passed in scales step with it.
  camera.slideBy(wedge(step, toMultivector(heading)))


func travelToward*(camera: var Camera; factor: float; anchor: Position; floor_reach: float) =
  ## Carry eye along its own line to `anchor`, scaling what separates them by `factor`.
  ##   Whatever stands at `anchor` keeps its pixel, on same reading `dollyToward` holds:
  ##   sight direction never moves, so point on view ray is still on it afterwards.
  ##   Floor is reach caller names, object's own drawn radius where object stands there,
  ##   so wheel stops at its surface rather than carrying eye through it.
  ##     Floor never pushes eye out: it applies only where eye is already further out.
  ##   Separation from pivot is left to caller, which knows anchor's own depth.
  let
    (place_anchor, place_eye) = (toMultivector(anchor), toMultivector(camera.eye))
    reach = distanceBetween(place_anchor, place_eye)
  if reach <= 0.0: return
  let settled = max(reach*factor, min(max(floor_reach, DISTANCE_LIMIT_NEAR), reach))
  # Difference of two unit points is weightless point running from one to other.
  camera.slideBy(wedge((reach - settled)/reach, place_anchor - place_eye))


func flyAhead*(camera: var Camera, step: float) =
  ## Travel `step` units along sight, holding pivot where it stands in world.
  ##   Separation follows, so frustum's scale and furniture's extent track flight.
  ##     Sliding whole camera keeps separation, and near clip of stance reader set off
  ##     from then ate planet before eye reached it: near is one four-hundredth of
  ##     separation, which is fortieth of unit at opening stance, and planet is
  ##     millionths wide.
  ##   Same motion `dolly` makes, named in units rather than as factor: speed curve
  ##   reports units, and factor would have to be read back out of them.
  ##   Floored as every separation is; see `distanceHeld`.
  ##   Strafe and rise carry pivot along instead, because what stands ahead keeps its
  ##   depth as camera steps sideways.
  camera.travel(step, 0.0, 0.0)
  camera.depth_pivot = distanceHeld(camera.depth_pivot - step)


func originHeld*(camera: Camera, origin: Position): Position =
  ## Say where records are stored from, given where they were stored from last.
  ##   Eye, held where it stands until travel spends float32's precision about it.
  ##     Eye rather than pivot: free flight turns about eye, so pivot swings through whole
  ##     arc while eye stands, and what reader is about to reach stands near eye.
  ##     Records are float32, and one stored `r` out carries about `r*STEP_SINGLE`.
  ##   Held rather than followed: origin that moved every frame rebuilt every record of
  ##   every held frame, which is what those holds exist to skip.
  ##   Bound is `FRACTION_ORIGIN_HOLD` of near clip, divided by float32's step: about 199
  ##   thousand units at opening stance, and less as close work draws near clip in.
  ##   One origin for both mesh sets, since one transform draws them; see
  ##   `initMatrixViewProjection`.
  let
    eye = camera.eye
    reach = norm(eye - origin)
  if reach*STEP_SINGLE <= FRACTION_ORIGIN_HOLD*camera.distanceNear: origin else: eye


func capTravelling*(depth_pointer: Option[float]; scale_local, haste: float): float =
  ## Read fastest free flight may travel right now, in units per second.
  ##   Smaller of two figures, as `SPEED_CEILING` says: local scale, and fixed ceiling.
  ##   Haste scales both, so shift is still one multiplier on every rate.
  ##   Local scale is depth under pointer where pointer is over something, and camera's
  ##   own scale where it is over empty sky.
  ##     Ceiling alone over empty sky threw reader out of solar system in half second:
  ##     ceiling bounds local reading, and is no reading of its own.
  ##   Depths held off negative: pointer behind eye is no reading, and camera at floor
  ##   would otherwise freeze rather than crawl.
  let reach =
    if depth_pointer.isSome: max(depth_pointer.get, 0.0) else: max(scale_local, 0.0)
  min(FACTOR_SPEED_LOCAL*reach*haste, SPEED_CEILING*haste)


func speedTravelling*(seconds_held, cap: float): float =
  ## Read speed hold of `seconds_held` has climbed to, in units per second.
  ##   Cap times `1 - exp(-t/SECONDS_SPEED_RISE)`, so cap is approached and never reached.
  ##   Panel's reading, and nothing else: `distanceTravelled` is what moves camera.
  cap*(1.0 - exp(-max(seconds_held, 0.0)/SECONDS_SPEED_RISE))


func distanceTravelled*(seconds_before, seconds_after, cap: float): float =
  ## Read distance one hold covers between two of its own ages, in units.
  ##   Integral of `speedTravelling` across that span, written out rather than sampled.
  ##     Speed at one end times frame's length is wrong by square of frame's length, so
  ##     144 Hz reader would part from 60 Hz one over same hold. Same rule `dolly`
  ##     compounds under; see `FACTOR_DOLLY_SECOND`.
  ##   Suite holds sum of halves equal to whole, and holds long hold to cap times span
  ##   less cap times time constant.
  let (before, after) = (max(seconds_before, 0.0), max(seconds_after, 0.0))
  cap*((after - before) + SECONDS_SPEED_RISE*(
    exp(-after/SECONDS_SPEED_RISE) - exp(-before/SECONDS_SPEED_RISE)
  ))



#[ Camera Frame ]#

type SettingsFurniture* = tuple
  ## Define everything ground grid and world axes are built from.
  ##   `drawExtentFor` derives every field furniture reads from exactly these, so two
  ##   frames agreeing here draw same furniture, vertex for vertex: what lets front-end
  ##   keep last frame's meshes.
  ##     Field added to `Camera` that `drawExtentFor` reads must be added here too, or
  ##     frame holds furniture no longer matching view.
  ##   Here rather than in each front-end: two private copies would be drift sibling rule
  ##   warns about.
  ##   Keyed on what camera *holds*, and never on what it reads out.
  ##     Motor and depth are stance itself, so two frames agreeing on them agree on eye,
  ##     every axis, pivot and both angles, which is stronger than keying on those.
  ##     Reading pivot and both angles out to key on them costs eighteen sandwiches, and
  ##     hold exists to save less work than that; see `drivePinAnchor`.
  motor: Motor
  distance, degrees_field_of_view, reach_near, reach_scene: float
  height_pixels: int
  is_axes_shown, is_grid_shown: bool


func settingsFurnitureFor*(
  camera: Camera; height_pixels: int; is_axes_shown, is_grid_shown: bool
): SettingsFurniture =
  ## Read furniture's inputs off this camera and frame, for hold comparison.
  ##   Compared exactly by callers: question is whether anything moved at all.
  ##   Every field is plain read, so key costs nothing to build.
  (
    camera.motor, camera.distance, camera.degrees_field_of_view, camera.reach_near,
    camera.reach_scene, height_pixels, is_axes_shown, is_grid_shown,
  )


func drawExtentFor*(camera: Camera, height_pixels: int): DrawExtent =
  ## Derive this frame's draw scale from camera.
  ##   How far geometry reaches, where from, and everything ribbon needs to hold constant
  ##   width on screen.
  ##   One constructor: literal copies in each front-end drifted.
  ##     Here rather than `tessellate` because it reads `Camera`, and `camera` imports
  ##     `tessellate`.
  ##   `height_pixels` is framebuffer's, not window's: ribbon's width is measured in
  ##   pixels actually drawn.
  let
    eye = camera.eye
    frame = camera.frame
  # Derive four multivector twins through `algebraFilled`.
  #   One derivation point shared with every hand-built extent.
  algebraFilled(DrawExtent(
    scale: DrawScale(
      # Furniture follows local scale, not scene's reach; see `mesh.extentFurnitureFor`.
      extent_furniture: extentFurnitureFor(camera.scaleLocal*FACTOR_CLIP_FAR),
      eye: eye,
      radius_horizon: radiusHorizonFor(camera.distanceFar),
      forward: frame.forward,
      axis_right: frame.axis_right,
      axis_up: frame.axis_up,
      tangent_half_view: tan(0.5*degToRad(camera.degrees_field_of_view)),
      height_pixels: height_pixels,
      depth_near: camera.distanceNear,
      depth_log: camera.depthLogScale,
    ),
  ))


func viewBoundsFor*(camera: Camera, scale: DrawExtent, aspect: float): ViewBounds =
  ## Derive frustum points are culled against, once per frame; see `tessellate.isPointInView`.
  ##   Margin is least on-screen radius and one pixel more, as tangent per unit of depth,
  ##   so smallest disc straddling edge is still emitted whatever GPU does with centre
  ##   just outside; point's own radius is added per point by `isPointInView`.
  ##   `aspect` is framebuffer's width over height, which `drawExtentFor` never needs.
  let eye = camera.eye
  let frame = camera.frame
  let margin = (0.5*float(DIAMETER_POINT_LEAST) + 1.0)*scale.scale.radiansPerPixel
  ViewBounds(
    eye: eye,
    forward: frame.forward,
    right: frame.axis_right,
    up: frame.axis_up,
    depth_near: camera.distanceNear*(1.0 - TOLERANCE_CULL_CLIP),
    depth_far: camera.distanceFar*(1.0 + TOLERANCE_CULL_CLIP),
    bound_width: scale.tangentHalfView*aspect + margin,
    bound_height: scale.tangentHalfView + margin,
  )


func initMatrixViewProjection*(
  camera: Camera, aspect: float, origin: Position = Position(x: 0, y: 0, z: 0)
): Matrix4 =
  ## Compose whole transform from world space to clip space.
  ##   `origin` is point coordinates handed to transform are measured from: world origin
  ##   for picking and markers, which read world coordinates; frame's own origin,
  ##   `mesh.MeshSet.origin`, for GPU, whose records are stored about it. Same transform
  ##   either way, translated: only translation column moves, by eye's offset from origin.
  ##     Point stored as float32 million units from world origin carries tenth of unit;
  ##     stored about pivot it carries what pivot's own close-up needs.
  let eye = camera.eye
  initMatrixProjection(camera.degrees_field_of_view, aspect, camera.distanceNear) *
    initMatrixView(eye - (origin - Position(x: 0, y: 0, z: 0)), camera.frame)



#[ Aiming And Easing ]#

type
  SphereWorld* = object ## Define bound of world points by centre and radius.
    ## What selection means to camera framing it: everything finite it was asked to show
    ## sits inside, so distance fitting sphere fits every one.
    centre*: Position ## Point orbit should turn about.
    radius*: float ## How far furthest object stands from `centre`. Zero for one point.

  CameraAim* = object ## Define what camera has been asked to bring into view.
    ## Not stance: *requirement*, derived from geometry alone and nothing about where
    ## camera stands.
    ##   Lets caller re-offer same selection every frame and have it recognised as same
    ##   request; see `CameraTween.goal`.
    ## Two halves are reached differently.
    ##   Finite object is somewhere, so camera moves pivot onto it and pulls back until
    ##   several fit.
    ##   Horizon object is only direction, drawn fixed to eye, so camera turns to face
    ##   along it and leaves pivot and distance alone.
    sphere*: Option[SphereWorld] ## Finite objects to frame, or none where there are none.
    is_bound_by_fitted*: bool ## Whether `sphere` is over objects that have to *fit* alone.
      ## Point and finite plane are drawn at size camera does not set, so each fits
      ## inside centred box; line is drawn out to horizon and has only to cross it.
      ## Whatever has to fit is what camera centres and sizes on; otherwise line whose
      ## support stands hundred units away drags view off point beside it.
      ## Where nothing has to fit (lines alone) sphere falls back to their support points.
    heading*: Option[Direction] ## Direction of horizon points to face, or none.
      ## Merged where several were asked for: sum of unit directions is nearest thing to
      ## one facing two stars.
      ## Binds two degrees of freedom: star has to be on screen, so sight has to come
      ## within centred box's own half-angle of it.
    normal_crossing*: Option[Direction] ## Normal of horizon lines' great circle, or none.
      ## Horizon line is drawn as whole great circle, and seeing it means that circle
      ## crossing frame, which binds one degree of freedom rather than two.
      ##   Circle crosses centred box exactly where sight stands within that box's
      ## half-angle of that circle's own plane; see `framing.holdHorizon`.
      ## Merged as headings are, and kept apart from them: point is stricter, so where
      ## both were asked for point is what binds.
    centroid_sum*: Option[Multivector] ## Middle of same finite objects `sphere` is over.
      ## Carried as sum algebra makes it out of, rather than as place.
      ##   Sum's weight is how many places it is middle of, and `centroid` reads mean
      ##   straight out: division reading point out *is* averaging.
      ##   Rebuilt from nothing on every `aimFor`, so it never accumulates across frames;
      ##   restart is what makes aim compare equal to itself.
      ## What orbit turns about once selection stands.
      ##   Sphere's centre is wherever holding everything put it; this is middle of what
      ##   was picked, point reader means.
      ## Over same objects as `sphere`, for reason `is_bound_by_fitted` gives. None where
      ## no finite objects.

  CameraStance* = object ## Define where camera stands: everything ease moves.
    ## Lens is not here: field of view is reader's setting, and nothing aiming camera may
    ## rewrite it.
    ## Same pair `Camera` holds, so stance crossing ease loses nothing it carried.
    ##   Four turntable numbers named it before, and roll is not one of them: rolling and
    ##   then framing snapped view upright. `stanceTurntable` builds one from those four
    ##   where caller has them.
    motor*: Motor ## Rigid motion carrying reference stance to this one.
    distance*: float ## Separation of eye from pivot.

  CameraTween* = object ## Define ease carrying camera from where it was toward its goal.
    ## Eased over `duration`, so camera jumping to freshly built object is followed
    ## rather than teleported after. Empty until something aims it.
    ##   Repivoting captures wherever tween had reached as new start (see `aimAt`),
    ##   which lets goal moving every frame (staged geometry of open edit session) read
    ##   as one chase.
    goal*: Option[CameraAim] ## What camera is watching, or has settled on.
      ## None only while nothing is aimed at all.
      ## *Requirement*, not stance: derived from selected geometry alone, so re-offer
      ## compares equal every frame.
      ##   Ignore rule in `aimAt` and standing-offer rule in `abandon` both rest on it;
      ##   where ease ends is kept separately below.
    destination*: CameraStance ## Where ease ends.
      ## Goal resolved against camera as it stood when goal was armed; see
      ## `framing.stanceFor` and `framing.offerAim`.
      ## Meaningless while `goal` is none; set beside it and never alone.
    is_arrived*: bool ## Whether `destination` has been reached.
      ## Set once ease runs out, stopping `advance` writing camera from then on.
      ##   Caller offering same goal every frame must not keep holding camera there, or
      ##   user's own orbit, pan and dolly are overridden.
      ## `goal` is kept rather than cleared, so same offer is recognised as delivered
      ## instead of re-arming ease.
    started*: float ## Clock reading `goal` was last set or repivoted at.
    duration*: float ## Seconds ease takes, end to end.
    stance_from*: CameraStance ## Where current ease began.
    progress_last*: float ## Eased progress `advance` last carried camera to.
      ## What next step is measured from once reader holds camera; see `is_yielded`.
    is_yielded*: bool ## Whether reader has taken camera mid-ease; see `abandon`.
      ## Ease then carries pivot alone, by each frame's own share of its path, and way
      ## round and distance stay reader's.
    is_adopting*: bool ## Whether next offer takes its aim as delivered; see `adoptNext`.


func `==`*(a, b: SphereWorld): bool =
  ## Compare two bounds exactly; see `CameraAim`'s `==` for why exactly.
  a.centre.x == b.centre.x and a.centre.y == b.centre.y and a.centre.z == b.centre.z and
    a.radius == b.radius


func centroid*(aim: CameraAim): Option[Position] =
  ## Read middle of what was picked, as place to point camera at.
  ##   Sum's weight is count, so read-out's division is averaging; see `centroid_sum`.
  ##   None where nothing finite was picked.
  if aim.centroid_sum.isNone: return
  position(aim.centroid_sum.get)


func `==`*(a, b: CameraAim): bool =
  ## Compare two aims exactly, where reason for comparison is stated.
  ##   Exact, not approximate: answers whether this is same request already given, so
  ##   caller offering same selection every frame does not restart ease.
  ##   Selection moved by hair should restart it.
  if a.sphere.isSome != b.sphere.isSome: return false
  if a.sphere.isSome and not (a.sphere.get == b.sphere.get): return false
  if a.is_bound_by_fitted != b.is_bound_by_fitted: return false
  if a.centroid_sum.isSome != b.centroid_sum.isSome: return false
  # Compare sum's four coefficients, not place it reads to.
  #   Weight is count, so this is same middle *and* same number of things in one field.
  #   Sum of points is grade 1.
  if a.centroid_sum.isSome:
    let (m, n) = (a.centroid_sum.get, b.centroid_sum.get)
    for handle in [Basis.E1, Basis.E2, Basis.E3, Basis.E4]:
      if m[handle] != n[handle]: return false
  func sameWay(one, other: Option[Direction]): bool =
    ## Compare two optional directions coefficient by coefficient.
    if one.isSome != other.isSome: return false
    if one.isNone: return true
    let (d, e) = (one.get, other.get)
    d.x == e.x and d.y == e.y and d.z == e.z
  sameWay(a.heading, b.heading) and sameWay(a.normal_crossing, b.normal_crossing)


func widened*(bound: SphereWorld, place: Position, reach: float): SphereWorld =
  ## Grow bound just enough to contain one more ball.
  ##   Point where `reach` is zero, plane's whole disc where it is
  ##   `tessellate.EXTENT_PLANE_F`.
  ##   Incremental rather than fit over whole set, so caller folding selection allocates
  ##   nothing.
  ##     Result depends on arrival order and can be little wider than tightest sphere;
  ##     always true bound, which is all framing needs.
  let
    centre_point = toMultivector(bound.centre)
    place_point = toMultivector(place)
    away = distanceBetween(centre_point, place_point)
  if away + reach <= bound.radius: return bound
  # Handle new ball swallowing old one apart.
  #   Arithmetic below would slide centre past `place`, and concentric pair has no
  #   direction to slide along.
  if away + bound.radius <= reach: return SphereWorld(centre: place, radius: reach)
  let
    radius = 0.5*(away + bound.radius + reach)
    # Slide centre toward new ball by exactly what far side gives up.
    #   Old sphere then stays enclosed.
    slid = position(add(centre_point, wedge(
      (radius - bound.radius)/away, subtract(place_point, centre_point)
    )))
  SphereWorld(
    centre: (if slid.isSome: slid.get else: place),
    radius: radius,
  )


func aimIncluding*(
  aim: Option[CameraAim], m: Multivector, scale: DrawExtent,
  anchor_override: Option[Position] = none(Position)
): Option[CameraAim] =
  ## Fold one more object into aim, or start one where there was none.
  ##   Unchanged by geometry drawing nothing, and by horizon plane, in view from every
  ##   camera.
  ##   Horizon point is fixed star, faced along own direction.
  ##   Horizon line keeps its circle's normal instead, because crossing frame is what
  ##   seeing it means; `framing.headingFacing` reads which way to face from either.
  ##   Everything finite widens sphere about `anchorFor`'s point; finite plane widens it
  ##   by whole disc round that point.
  ##     Except first object that has to *fit* throws away whatever lines contributed,
  ##     and they contribute nothing thereafter; see `CameraAim.is_bound_by_fitted`.
  ##     Which objects contribute does not depend on order.
  ##   `anchor_override` centres plane's disc there instead of on support, read as
  ##   `tessellate.addPlane` reads it; ignored for every other kind.
  ##   Horizon objects widen nothing.
  ##     `anchorFor` places star at `scale.eye`, and goal built from where camera stands
  ##     would stop comparing equal frame to frame.
  ##     Twice over for centroid: middle moving with eye would re-aim camera every frame.
  let shape_m = kindOf(m)
  if shape_m.isNone: return aim
  var grown = if aim.isSome: aim.get else: CameraAim()

  if isHorizon(m):
    # Merge directions as sum of horizon points, read back through horizon reader.
    #   Reader also refuses cancelling pair, and first one standing is kept then: neither
    #   turn shows both.
    func folded(held, one: Option[Direction]): Option[Direction] =
      if one.isNone: return held
      if held.isNone: return one
      let merged = directionHorizon(add(
        toMultivector(held.get), toMultivector(one.get)
      ))
      if merged.isSome: merged else: held
    case shape_m.get
    of Kind.Point:
      let heading = directionHorizon(m)
      if heading.isNone: return aim
      grown.heading = folded(grown.heading, heading)
    of Kind.Line:
      # Line's own normal, and not one axis of its circle: circle crossing frame is what
      #   seeing it means, and only normal states that.
      let normal = directionNormalHorizon(m)
      if normal.isNone: return aim
      grown.normal_crossing = folded(grown.normal_crossing, normal)
    of Kind.Plane: discard
    return some(grown)

  let is_plane = shape_m.get == Kind.Plane
  var anchor = anchorFor(m, scale)
  if is_plane and anchor_override.isSome: anchor = anchor_override
  if anchor.isNone: return aim
  let
    # Fit whole ball plane's disc is drawn as, not anchor alone.
    reach = if is_plane: EXTENT_PLANE_F else: 0.0
    does_fit = shape_m.get in {Kind.Point, Kind.Plane}
  if grown.is_bound_by_fitted and not does_fit: return some(grown)
  # Start bound afresh at first object that has to fit, discarding lines that only cross.
  if does_fit and not grown.is_bound_by_fitted:
    return some(CameraAim(
      sphere: some(SphereWorld(centre: anchor.get, radius: reach)),
      is_bound_by_fitted: true, heading: grown.heading,
      # Restart middle with bound: centre still holding lines would sit off everything left.
      centroid_sum: some(toMultivector(anchor.get)),
    ))
  grown.sphere =
    if grown.sphere.isNone: some(SphereWorld(centre: anchor.get, radius: reach))
    else: some(grown.sphere.get.widened(anchor.get, reach))
  # Fold middle through algebra's reading of one (`objects.centroidFolded`).
  #   Plane folds in by disc's centre, not whole ball. Nothing is read out or scaled here.
  grown.centroid_sum =
    if grown.centroid_sum.isNone: some(toMultivector(anchor.get))
    else: some(centroidFolded(grown.centroid_sum.get, toMultivector(anchor.get)))
  some(grown)


func aimFor*(
  m: Multivector, scale: DrawExtent, anchor_override: Option[Position] = none(Position)
): Option[CameraAim] =
  ## Resolve what camera has been asked to show for one object alone.
  ##   None where it draws nothing. One-object case of `aimIncluding`.
  aimIncluding(none(CameraAim), m, scale, anchor_override)


func reachCentred*(width, height: int; inset: float): (float, float) =
  ## Measure centred box, across and down, in pixels of `width` x `height` frame.
  ##   One statement of box's shape: `picking` turns it into pixel margins, and
  ##   `halfAngleCentred` into cone `distanceFitting` solves. Written twice, two drifted.
  ##   Width is capped at height.
  ##     Field of view is vertical, so fraction of width is `aspect` times as much
  ##     *world*; on wide desktop window picking object then almost never moved camera.
  ##     Capping makes reach same in angle both ways.
  ##   Cap is one-sided: on frame taller than wide width is already shorter side, so touch
  ##   keeps behaviour it had.
  ##     `min` on both axes would tighten phone's vertical band to under third of frame.
  ##   `inset` pulls box in by that many pixels on every side.
  ##     `framing` passes room point's dot takes, so distance solved here satisfies pixel
  ##     test in `picking`, which insets by same amount.
  ##     Box inset past nothing collapses to middle rather than turning inside out.
  (
    max(FRACTION_VIEW_CENTRED*float(min(width, height)) - 2.0*inset, 0.0),
    max(FRACTION_VIEW_CENTRED*float(height) - 2.0*inset, 0.0),
  )


func halfAngleCentred*(camera: Camera; width, height: int; inset: float): float =
  ## Measure half-angle, from sight axis, centred box covers.
  ##   Narrower of its two, so anything inside that cone is inside box both ways.
  ##   Box is fraction of frame *in projection plane*, not in angle, so its half-angles
  ##   come from scaling tangents.
  ##     Both scale by frame's height, dimension vertical field of view sizes; box's
  ##     width already carries what aspect did to it.
  let
    tangent_half = tan(0.5*degToRad(camera.degrees_field_of_view))
    (reach_across, reach_down) = reachCentred(width, height, inset)
    tangent_down = max(reach_down/float(height), 1.0e-6)*tangent_half
    tangent_across = max(reach_across/float(height), 1.0e-6)*tangent_half
  arctan(min(tangent_down, tangent_across))


func stepOutTo*(eye, centre: Position; heading: Direction; reach: float): float =
  ## Solve least step along `heading` carrying `eye` out to `reach` from `centre`.
  ##   `|offset + r*heading| = reach` with `offset` from centre to eye and unit `heading`,
  ##   which is one quadratic in `r`: `r² + 2r(offset·heading) + (|offset|² − reach²) = 0`.
  ##   Both coefficients are algebra's: `offset·heading` is eye's depth over plane through
  ##   centre square to heading, and `|offset|` is distance between them.
  ##   Positive root is answer, and it always exists where offset falls short: term under
  ##   root is `along² − outside`, and `outside` is negative exactly then, so root exceeds
  ##   `|along|` and difference is positive whichever way `along` points.
  ##   Zero where offset already reaches that far, which is what makes frame rule floor
  ##   rather than fit.
  ##   Replaced bisection over `framing.isShownAll`, about 25 projections of every watched
  ##   object for each pick.
  let
    (place_eye, place_centre) = (toMultivector(eye), toMultivector(centre))
    along = depthAgainst(planeThrough(place_centre, toMultivector(heading)), place_eye)
    gap = distanceBetween(place_eye, place_centre)
    outside = gap*gap - reach*reach
  if outside >= 0.0: return 0.0
  sqrt(along*along - outside) - along


func distanceFitting*(radius: float; camera: Camera; width, height: int; inset: float): float =
  ## Solve how far eye must stand from sphere's centre for whole of it to fit centred box.
  ##   Sphere's tangent condition, `sin`, not flat one, `tan`: near side stands as far off
  ##   sight axis as far side while closer, so subtends more.
  ##   Held off near bound as user's dolly is, and unbounded above: nothing about frustum
  ##   or furniture stops working at distance.
  ##   Solves centred box, what point is held to and stricter than plane's rim
  ##   (`picking.isPlaneShownCentrally` holds that to frame).
  ##     Keeps this valid *upper bracket* for `framing.stanceFor`'s bisection, never
  ##     answer.
  let sine = sin(halfAngleCentred(camera, width, height, inset))
  distanceHeld(radius/max(sine, 1.0e-6))


func depthSpanning*(diameter, fraction: float; camera: Camera): float =
  ## Solve depth along sight line at which world `diameter` spans `fraction` of frame's height.
  ##   Flat projection: span in pixels is diameter over world-per-pixel at that depth
  ##   (`mesh.worldPerPixelAt`), and disc's projected major axis is its diameter whatever
  ##   its tilt, so one formula sizes point's ball and plane's disc alike.
  ##   Held off near floor as every depth is.
  ##   For pointer pick's approach; see `framing.stanceApproaching`.
  let tangent_half = tan(0.5*degToRad(camera.degrees_field_of_view))
  distanceHeld(diameter/(2.0*max(fraction, 1.0e-6)*max(tangent_half, 1.0e-6)))


func isGoalHeld*(tween: CameraTween, goal: CameraAim): bool =
  ## Report whether `goal` is one this tween already holds, and would ignore.
  ##   For caller whose preparation is worth skipping: `framing.offerAim` projects every
  ##   selected object several times over, and re-offers same goal every frame.
  tween.goal.isSome and tween.goal.get == goal


func stanceTurntable*(pivot: Position; distance, azimuth, elevation: float): CameraStance =
  ## Build stance from four turntable numbers, for caller that has them.
  ##   Carries no roll, because those four name none; see `CameraStance`.
  let settled = distanceHeld(distance)
  CameraStance(
    motor: motorTurntable(pivot, settled, azimuth, elevation), distance: settled
  )


func stanceOf*(camera: Camera): CameraStance =
  ## Read where `camera` already stands as stance of its own.
  CameraStance(motor: camera.motor, distance: camera.distance)


func stanceDollied*(camera: Camera; stance: CameraStance; distance: float): CameraStance =
  ## Read `stance` with its separation set to `distance`, pivot standing.
  ##   Separation is depth of pivot along sight now, so naming it alone moves pivot and
  ##   leaves eye. Dolly is what moves eye and holds pivot; see `dollyTo`.
  ##     Four turntable numbers named stance before, and separation was one of them, so
  ##     writing it rebuilt eye. Whoever wrote it now writes this.
  var held = camera.placed(stance)
  held.dollyTo(distance)
  held.stanceOf


func stanceRepivoted*(camera: Camera, pivot: Position): CameraStance =
  ## Read stance camera would stand at with its pivot moved to `pivot`.
  ##   Whole camera slides by step between two pivots, so eye follows exactly as far as
  ##   turntable rebuild moved it, and roll survives.
  ##   Sight direction and separation both stand, so nothing turns and nothing zooms.
  CameraStance(
    motor: motorOf(wedgeDotAnti(
      motorSliding(subtract(toMultivector(pivot), toMultivector(camera.pivot))),
      toMultivector(camera.motor),
    )),
    distance: camera.distance,
  )


func placed*(camera: Camera, stance: CameraStance): Camera =
  ## Put copy of `camera` at `stance`, lens untouched.
  ##   Whole motion crosses, so roll crosses with it.
  result = camera
  result.motor = stance.motor
  result.depth_pivot = distanceHeld(stance.distance)


func placedAtPivot*(camera: Camera, pivot: Position): Camera =
  ## Put copy of `camera` at same stance but this pivot, eye following as it always did.
  ##   Four of these stand where assignment to field stood, because pivot and both angles
  ##   are read-outs now; see `Camera`. Written as calls rather than setters, so reader
  ##   sees that whole motion is rebuilt rather than one number written (Article VII.1).
  ##   Slides rather than rebuilds, so roll survives pivot typed into panel's field.
  camera.placed(camera.stanceRepivoted(pivot))


func motorRigid*(m: Multivector): Option[Motor] =
  ## Read rigid motion `m` names, for coefficients reader types into panel.
  ##   Odd grades name no rigid motion, and drop. Even part is unitized, then carried
  ##   through `log` and `exp`, whose round trip lands on unit motor meeting rigid
  ##   condition whatever was typed: its turn, and slide consistent with that turn.
  ##     `unitize` alone leaves slide that turn does not allow, which carries eye off
  ##     orthonormal frame rather than moving it.
  ##   Library's own `unitize`, `log` and `exp` throughout; nothing here normalises.
  ##   None where even part carries no weight, i.e. names no motion at all.
  let even = toMultivector(motorOf(m))
  if normWeight(even)[Basis.scalarAnti] <= TOLERANCE_ABS: return
  some(motorOf(exp(log(unitize(even)))))


func placedAtMotor*(camera: Camera, motor: Motor): Camera =
  ## Put copy of `camera` at rigid motion `motor`, keeping its separation and its lens.
  camera.placed(CameraStance(motor: motor, distance: camera.distance))


func placedAtDistance*(camera: Camera, distance: float): Camera =
  ## Put copy of `camera` at same stance but this separation, pivot standing.
  ##   Same reading as `dolly`, which reaches it by factor.
  camera.placed(stanceTurntable(
    camera.pivot, distance, camera.azimuth, camera.elevation
  ))


func placedAtAzimuth*(camera: Camera, azimuth: float): Camera =
  ## Put copy of `camera` at same stance but this azimuth.
  camera.placed(stanceTurntable(
    camera.pivot, camera.distance, azimuth, camera.elevation
  ))


func placedAtElevation*(camera: Camera, elevation: float): Camera =
  ## Put copy of `camera` at same stance but this elevation, held short of poles.
  camera.placed(stanceTurntable(
    camera.pivot, camera.distance, camera.azimuth,
    clamp(elevation, -ELEVATION_LIMIT, ELEVATION_LIMIT),
  ))


func toward*(from_stance, to_stance: CameraStance; progress: float): CameraStance =
  ## Step `progress` of way from one stance to another.
  ##   Motion eases as one screw, and separation eases geometrically beside it.
  ##   Screw rather than four numbers eased apart.
  ##     Roll survives, which four turntable numbers cannot carry: rolling and then
  ##     framing snapped view upright.
  ##     Turn takes short way round without being told to. `motors.log` flips sign of
  ##     motion whose antiscalar is negative, which is same motion by shorter arc, so
  ##     destination just past -pi stays next door to camera short of +pi.
  ##     One path, rather than pivot linear and separation geometric pulling apart
  ##     mid-ease.
  ##   Separation is multiplicative, and linear ease from 12 to 300 covers most visible
  ##   change in first few frames then crawls.
  let
    (near, far) = (max(from_stance.distance, 1.0e-6), max(to_stance.distance, 1.0e-6))
    held = toMultivector(from_stance.motor)
    # Motion carrying one stance to other, logged, scaled, and put back on.
    step = wedgeDotAnti(toMultivector(to_stance.motor), reverseAnti(held))
    eased = exp(wedge(progress, log(step)))
  CameraStance(
    motor: motorOf(wedgeDotAnti(eased, held)),
    distance: near*pow(far/near, progress),
  )


func `==`*(a, b: CameraStance): bool =
  ## Compare two stances exactly, for caller asking whether camera would move at all.
  ##   Motor is stored state, so two stances agreeing here agree on eye, every axis,
  ##   pivot and both angles; same key `SettingsFurniture` holds.
  a.motor == b.motor and a.distance == b.distance


func aimAt*(
  tween: var CameraTween; camera: Camera; goal: CameraAim; destination: CameraStance;
  now, duration: float; is_renewed = false
) =
  ## Set camera watching `goal` and ease it to `destination`, from where it stands now.
  ##   Requirement and stance, not one thing twice: `goal` is what re-offer is
  ##   recognised by, `destination` where that puts camera once resolved.
  ##   Start is read off live camera rather than previous goal, so moving goal stays
  ##   smooth: `advance` has already eased partway, and next ease continues motion.
  ##   Re-aiming at goal already set is ignored, so caller may offer same goal every
  ##   frame without ease restarting forever.
  ##     Holds after arrival too, keeping standing offer from taking camera back off user
  ##     each frame. `release` withdraws offer; only then does same goal aim camera again.
  ##     `is_renewed` overrides: pointer pick of object already held aims afresh, since
  ##     reader who clicks again means to be taken there again.
  if tween.isGoalHeld(goal) and not is_renewed: return
  tween.goal = some(goal)
  tween.destination = destination
  # Mark arrived outright where camera already stands on destination.
  #   Easing through whole duration would write reading it holds and fight user who
  #   orbits.
  tween.is_arrived = destination == camera.stanceOf
  tween.started = now
  tween.duration = duration
  tween.stance_from = camera.stanceOf
  tween.progress_last = 0.0
  tween.is_yielded = false


func slideOwed(tween: CameraTween; camera: Camera; progress: float): Multivector =
  ## Read slide carrying pivot from where ease last stood it to where `progress` stands it.
  ##   Both read off ease's own path, so pivot held by reader follows same track ease
  ##   would have, and lands where it would have.
  let
    was = camera.placed(tween.stance_from.toward(tween.destination, tween.progress_last))
    now_at = camera.placed(tween.stance_from.toward(tween.destination, progress))
  subtract(toMultivector(now_at.pivot), toMultivector(was.pivot))


func advance*(
  tween: var CameraTween, camera: var Camera, now: float,
  ease: proc(t: float): float {.noSideEffect.},
) =
  ## Carry camera one frame further toward destination, and mark it arrived there.
  ##   `ease` is passed in rather than imported so module stays independent of where
  ##   project keeps easing curve.
  ##     Callers hand `tessellate.easeOutCubic`, same curve and duration freshly added
  ##     object grows in with.
  ##   Held by reader, it slides camera by this frame's share of pivot's path and does
  ##   nothing else, so their turn and their distance stand; see `abandon`.
  if tween.goal.isNone or tween.is_arrived: return
  let progress = ease(clamp((now - tween.started) / max(tween.duration, 1.0e-6), 0.0, 1.0))
  if tween.is_yielded: camera.slideBy(tween.slideOwed(camera, progress))
  else: camera = camera.placed(tween.stance_from.toward(tween.destination, progress))
  tween.progress_last = progress
  if now - tween.started >= tween.duration: tween.is_arrived = true


func settle*(tween: var CameraTween, camera: var Camera) =
  ## Put camera on destination at once.
  ##   For caller that must not show half-finished pan, such as storyboard frame about to
  ##   be captured.
  ##   Held by reader, only pivot's remaining slide is put on, as `advance` would.
  if tween.goal.isNone or tween.is_arrived: return
  if tween.is_yielded: camera.slideBy(tween.slideOwed(camera, 1.0))
  else: camera = camera.placed(tween.destination)
  tween.progress_last = 1.0
  tween.is_arrived = true


func release*(tween: var CameraTween) =
  ## Withdraw whatever camera was aimed at, leaving it wherever it stands.
  ##   For whoever offers aim, once it has nothing to offer: selection cleared, edit
  ##   session closed.
  ##   Clearing goal outright lets picking same object again aim afresh.
  ##   Not for camera *user* just moved: see `abandon`.
  tween.goal = none(CameraAim)
  tween.is_arrived = false
  tween.is_adopting = false


func abandon*(tween: var CameraTween) =
  ## Hand camera to reader mid-ease, and let pivot alone finish arriving.
  ##   For path turning or scaling camera about pivot it already has: orbit, look, roll,
  ##   plain dolly and keys. Reader wins way round and distance outright, and `advance`
  ##   carries pivot rest of its path underneath, so what they turn about is still what
  ##   was picked. Path placing pivot itself halts instead; see `halt`.
  ##     Stopping outright left pivot partway, and nothing aimed again: reader who added
  ##     object and turned at once turned about empty point short of group's middle.
  ##   Deliberately not `release`.
  ##     Aim is standing offer re-made every frame, so goal cleared here is offered again
  ##     next frame and camera is taken straight back off user.
  ##     Keeping goal makes standing offer read as already answered.
  if tween.goal.isSome and not tween.is_arrived: tween.is_yielded = true


func halt*(tween: var CameraTween) =
  ## Stop carrying camera where it stands, and remember what it was carrying it toward.
  ##   For path placing pivot itself: pan, zoom landing pivot on what pointer or frame's
  ##   middle is over, figure typed into view fields, and placement undo restores. Pivot
  ##   still arriving would slide camera off what reader set.
  ##   Not `release`, for reason `abandon` gives.
  if tween.goal.isSome: tween.is_arrived = true


func adoptNext*(tween: var CameraTween) =
  ## Halt, and take whatever next offer aims at as delivered where camera then stands.
  ##   For placement undo and redo restore, along with selection kept across it. Aim that
  ##   restored scene reads is new wherever step changed what is picked, and new aim eases
  ##   camera off stance just restored, framed or not.
  ##   Frame rule alone moves camera then: restored stance that breaks it eases back into
  ##   range, as resized window does; see `framing.offerAim`.
  tween.halt()
  tween.is_adopting = true
