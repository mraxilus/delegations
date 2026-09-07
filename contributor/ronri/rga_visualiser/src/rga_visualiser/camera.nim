## Orbit camera about pivot, and assemble transforms OpenGL draws through.
##
## Camera's own frame is derived through RGA, exactly as objects it looks at are:
##
##   |-------------|---------------|-------------------------------------------------|
##   | Identifier  | Construction  | Meaning                                         |
##   |-------------|---------------|-------------------------------------------------|
##   | axis_sight  | 𝐞 ∧ 𝐭         | Line joining eye to pivot.                     |
##   | forward     | att(𝐋)        | Unit direction eye looks along.                 |
##   | axis_right  | -(𝐋 ∧ 𝐮)☆     | Unit direction of view's +x.                    |
##   | axis_up     | -(𝐋 ∧ 𝐫)☆     | Unit direction of view's +y.                    |
##   |-------------|---------------|-------------------------------------------------|
##
## Only projection is left to convention.
##   Perspective divide, depth range and clip volume belong to graphics pipeline rather
##   than to geometry, so they are written out directly.
## Stance is spherical about pivot, since that is what mouse drag turns.
##   Elevation is clamped short of poles, where up direction would run along sight axis
##   and joins above would collapse.
##
## Shared by desktop (`visualiser.nim`) and browser (`browser_bridge.nim`) render paths.

# Reorder so stance reads before frame derived from it, though `pan` calls `frame`.
#   Constants below stay in dependency order regardless, as reordering does not cover them.
{.experimental: "codeReordering".}
{.experimental: "strictFuncs".}

import std/[math, options, strformat]

import pga
import ./[boundary, tessellate]



#[ Camera Configuration ]#

const
  TOLERANCE_CULL_CLIP = 0.001
    ## Keep cull's near and far one part in thousand inside GPU's own clip.
    ##   Rounding then never culls point GPU would draw; see `viewBoundsFor`.
  UP_WORLD* = Direction(x: 0.0, y: 0.0, z: 1.0)
    ## Fix world's up direction, which azimuth turns about and elevation rises from.
  ELEVATION_LIMIT* = 0.5*PI - 0.02
    ## Bound elevation short of pole, where sight axis would run along `UP_WORLD`.
  DISTANCE_LIMIT_NEAR* = 0.05
    ## Bound how close eye may orbit to pivot, through `distanceHeld`.
    ##   Only bound on where camera may stand.
    ##     At orbit distance zero eye coincides with pivot, sight axis is undefined, and
    ##     every direction `frame` derives collapses.
    ##   No far bound: nothing downstream needs ceiling.
    ##     Clip planes are fractions of orbit distance (`FACTOR_CLIP_NEAR`,
    ##     `FACTOR_CLIP_FAR`), so frustum keeps shape, and grid bounds own line count
    ##     (`tessellate.CELLS_GRID_HALF_MAX`).
    ##     What degrades far out is `Vertex`'s float32 storage: past roughly million
    ##     units coordinate carries under tenth of unit.
  MARGIN_REACH_FAR* = 1.05
    ## Widen far clip past scene's reach by this, so farthest object never sits on plane.
  FACTOR_CLIP_FAR* = 20.0
    ## Set far clip plane this many orbit distances out, or at scene's reach where farther.
    ##   Scaled alone clipped field away as zoom carried orbit distance down to foreground
    ##   star: twenty of thirty units is six hundred, and field is three thousand across.
    ##   See `distanceFar` and `Camera.reach_scene`.
    ##   Scaled rather than fixed so everything meant to read at horizon
    ##   (`tessellate.radiusHorizonFor`, `tessellate.extentFurnitureFor`, far end of
    ##   every drawn line) stays past what frame shows at any orbit distance.
    ##   Fixed plane cannot: view's extent grows with distance while plane does not, so
    ##   dollying out brings line's far end inside frame, and clips pivot away once eye
    ##   orbits past it.
  FRACTION_VIEW_CENTRED* = 2.0/3.0
    ## Fix fraction of frame that counts as being looked at.
    ##   This much of height, and this much of width *or height, whichever is less*;
    ##   `reachCentred` writes that shape down.
    ##   Box rather than whole frame: object clinging to edge is on screen without being
    ##   what view is about, and marker ringing it is half off-frame.
    ##   Not exact middle: selection is *framed* inside box, spread across it.
    ##   Here rather than beside pixel test in `picking` because camera needs it too, to
    ##   solve how far back eye must stand (`distanceFitting`), and `picking` imports this.
  FACTOR_CLIP_NEAR* = 1.0/400.0
    ## Set near clip plane this fraction of orbit distance out.
    ##   Scaled beside `FACTOR_CLIP_FAR` so frustum stays same shape at every distance,
    ##   holding depth-buffer precision, function of far-to-near ratio, constant.
  RATIO_CLIP_MAX* = 100_000.0
    ## Bound far-to-near ratio, by raising near where far plane reaches scene.
    ##   Far plane at scene's reach over orbit of 0.7 units put ratio at 1.8 million:
    ##   24-bit depth then resolves 3 units at depth 300 and 34 at 1,000, and stars
    ##   quantised behind translucent discs and dome striped and faded on device. At
    ##   this bound depth 300 resolves to 0.17 units.
  FRACTION_NEAR_OF_ORBIT* = 0.5
    ## Bound how far out ratio may push near plane, as fraction of orbit distance.
    ##   Pivot itself must never clip, whatever scene's reach asks.

const
  ## Fix rates held key moves camera at, per second of holding.
  ##   Shared by both front-ends, unlike per-pixel drag rates: `visualiser.SPEED_ORBIT` is
  ##   radians per pixel and `glue.js` works in fractions of canvas width. Held key has no
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
  SLIDE_SECOND* = 1.2 ## Ground distance held key slides per second, as fraction of orbit.
    ## Reader zoomed onto one object crosses it at same apparent speed as one viewing
    ## whole scene.
  FACTOR_DOLLY_SECOND* = 4.0 ## Orbit distance held key scales by per second, dollying out.
    ## Reciprocal dollies in, so second each way returns exactly.
    ## Compounded as power of elapsed seconds, never multiplied per frame: per-frame
    ## scale would move 144 Hz reader more than twice as far as 60 Hz one.
  FACTOR_HASTE* = 4.0 ## Multiply every rate above by this while shift is held.
    ## Shift means *faster* on every movement key rather than something different on
    ## each: what Blender, Unity, Unreal and Godot all do.



#[ Type Definitions ]#

type
  Matrix4* = object ## Define 4x4 transform in column-major order, as OpenGL expects.
    elements: array[16, float32]

  Camera* = object ## Define stance of eye about pivot, and lens it looks through.
    pivot*: Position ## Point orbit turns about.
    distance*: float ## Separation of eye from pivot.
    azimuth*: float ## Angle about world up, in radians.
    elevation*: float ## Angle above horizon, in radians.
    degrees_field_of_view*: float ## Vertical field of view, in degrees.
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

func at*(matrix: Matrix4; row, column: int): float32 = matrix.elements[4*column + row]
  ## Read element of matrix, addressed as reader writes it rather than as GPU stores it.


func elementsAddress*(matrix: Matrix4): ptr float32 =
  ## Point at first element, for handing whole matrix to OpenGL.
  unsafeAddr matrix.elements[0]


func `*`*(a, b: Matrix4): Matrix4 =
  ## Compose transforms, applying `b` before `a`.
  for row in 0 .. 3:
    for column in 0 .. 3:
      var sum = 0.0'f32
      for i in 0 .. 3:
        sum += a.at(row, i) * b.at(i, column)
      result.elements[4*column + row] = sum


func initMatrixProjection*(
  degrees_field_of_view, aspect, distance_near, distance_far: float
): Matrix4 =
  ## Construct perspective projection onto OpenGL's clip volume.
  ##   Depth maps to -1 .. 1, and camera looks along its own -z, as pipeline expects.
  let
    focal = 1.0 / tan(0.5 * degToRad(degrees_field_of_view))
    span = distance_near - distance_far
  result.elements[0] = float32(focal / aspect)
  result.elements[5] = float32(focal)
  result.elements[10] = float32((distance_far + distance_near) / span)
  result.elements[11] = -1.0
  result.elements[14] = float32(2.0 * distance_far * distance_near / span)


func initMatrixView*(eye: Position, frame: FrameCamera): Matrix4 =
  ## Construct transform carrying world into camera's own frame.
  ##   Rows hold camera axes, so transform is inverse of camera's stance.
  let (right, up, forward) = (frame.axis_right, frame.axis_up, frame.forward)
  let offset = eye - Position(x: 0, y: 0, z: 0)
  result.elements = [
    float32(right.x), float32(up.x), float32(-forward.x), 0.0,
    float32(right.y), float32(up.y), float32(-forward.y), 0.0,
    float32(right.z), float32(up.z), float32(-forward.z), 0.0,
    float32(-dot(right, offset)), float32(-dot(up, offset)), float32(dot(forward, offset)),
    1.0,
  ]



#[ Camera Stance ]#

func distanceHeld*(distance: float): float = max(distance, DISTANCE_LIMIT_NEAR)
  ## Hold orbit distance off one value it may not take; see `DISTANCE_LIMIT_NEAR`.
  ##   Every path writing distance goes through here (construction, dolly, both
  ##   front-ends' numeric fields, fitted distance framing solves), so floor is stated
  ##   once.
  ##   Replaced `clamp` written at each site, shape limit takes when site is missed.


func initCamera*(pivot: Position; distance, azimuth, elevation: float): Camera =
  ## Construct camera orbiting `pivot` at given separation and angles.
  Camera(
    pivot: pivot,
    distance: distanceHeld(distance),
    azimuth: azimuth,
    elevation: clamp(elevation, -ELEVATION_LIMIT, ELEVATION_LIMIT),
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


func distanceFar*(camera: Camera): float =
  ## Read farthest depth clip volume keeps; see `distanceNear` for why derived.
  ##   Twenty orbit distances, or eye's distance to origin plus scene's reach where that
  ##   is farther, so no zoom clips scene away; see `FACTOR_CLIP_FAR`.
  ##   Near stays scaled, so ratio rises at close zoom over wide scene: three thousand
  ##   units over orbit of twelve is ratio of hundred thousand, inside 24-bit depth for
  ##   points and lines.
  let eye = camera.eye
  let away = sqrt(eye.x*eye.x + eye.y*eye.y + eye.z*eye.z)
  max(camera.distance*FACTOR_CLIP_FAR, away + camera.reach_scene*MARGIN_REACH_FAR)


func distanceNear*(camera: Camera): float =
  ## Read nearest depth clip volume keeps.
  ##   Derived from orbit distance rather than stored, so it cannot go stale through dolly.
  ##   One four-hundredth of orbit distance, raised where far plane reaching scene would
  ##   put far-to-near ratio past `RATIO_CLIP_MAX`, and never past half orbit distance.
  let near_scaled = camera.distance*FACTOR_CLIP_NEAR
  let near_bounded = min(camera.distanceFar/RATIO_CLIP_MAX, camera.distance*FRACTION_NEAR_OF_ORBIT)
  max(near_scaled, near_bounded)


func eye*(camera: Camera): Position =
  ## Place eye on sphere about pivot, from azimuth and elevation.
  ##   Angles are parametrization (trig scalars are ground field), and *point* they place
  ##   is assembled through algebra: pivot plus one spherical offset direction, read
  ##   back at end.
  ##   Held equal to spherical closed form by suite case.
  let
    radius = camera.distance * cos(camera.elevation)
    offset = toMultivector(Direction(
      x: radius * cos(camera.azimuth),
      y: radius * sin(camera.azimuth),
      z: camera.distance * sin(camera.elevation),
    ))
    placed = position(add(toMultivector(camera.pivot), offset))
  # Fall back to pivot only in name.
  #   Unit-weight point plus weightless direction is unit-weight point, so read cannot
  #   refuse.
  if placed.isSome: placed.get else: camera.pivot


func azimuthElevationFor*(heading: Direction): (float, float) =
  ## Solve orbit angles camera needs to look along `heading`.
  ##   Regardless of pivot or distance: `eye`'s formula cancels pivot out of `forward`
  ##   entirely, so this is plain spherical-coordinates inverse of same offset.
  ##   For aiming capture at horizon object's direction: unlike finite one, it is not
  ##   anchored anywhere fixed demo angle frames.
  let elevation = arcsin(clamp(-heading.z, -1.0, 1.0))
  let azimuth = arctan2(-heading.y, -heading.x)
  (azimuth, elevation)


func orbit*(camera: var Camera; turn, rise: float) =
  ## Turn eye about pivot by given angles, keeping elevation short of poles.
  camera.azimuth += turn
  camera.elevation = clamp(camera.elevation + rise, -ELEVATION_LIMIT, ELEVATION_LIMIT)


func dolly*(camera: var Camera, factor: float) =
  ## Scale separation of eye from pivot, holding it off near bound.
  camera.distance = distanceHeld(camera.distance * factor)


func dollyToward*(camera: var Camera, factor: float, anchor: Position) =
  ## Scale separation of eye from pivot by `factor`, moving eye along its line to `anchor`.
  ##   Rather than straight in, so whatever stands there keeps its pixel: how map zooms,
  ##   wheel taking reader toward what they point at, not middle of frame.
  ##   Why anchor keeps pixel: angles do not change, so sight direction is fixed, and eye
  ##   stays on line joining it to `anchor`; point on view ray through pixel is still on
  ##   it afterwards.
  ##   Scale applied is read back from `distanceHeld` rather than assumed, so zoom
  ##   stopped by near floor moves eye by exactly as much as distance allowed.
  let
    eye_point = toMultivector(camera.eye)
    pivot_point = toMultivector(camera.pivot)
    anchor_point = toMultivector(anchor)
    distance_settled = distanceHeld(camera.distance*factor)
    scale = distance_settled/camera.distance
    # Assemble new pivot as one multivector expression.
    #   Anchor plus old offset scaled, walked back along pivot-to-eye direction.
    #   Every difference of unit-weight points is direction, so sum stays unit-weight
    #   point throughout.
    settled = position(subtract(
      add(anchor_point, wedge(scale, subtract(eye_point, anchor_point))),
      wedge(distance_settled/camera.distance, subtract(eye_point, pivot_point)),
    ))
  if settled.isSome: camera.pivot = settled.get
  camera.distance = distance_settled


func repivotToDepth*(camera: var Camera, depth: float) =
  ## Move pivot along sight line to `depth` from eye, leaving picture unchanged.
  ##   Eye and sight direction stay; only separation moves, so nothing on screen shifts.
  ##   What turntable revolves about, and what every rate scaled by orbit distance reads,
  ##   then follows what reader looks at: zoom that carried eye up to planet while pivot
  ##   stayed on Sol far behind left every orbit swinging planet across frame.
  ##   Held off near floor as every distance is.
  let
    eye = camera.eye
    forward = camera.frame(eye).forward
    settled = distanceHeld(depth)
  camera.pivot = Position(
    x: eye.x + settled*forward.x, y: eye.y + settled*forward.y, z: eye.z + settled*forward.z
  )
  camera.distance = settled


func pan*(camera: var Camera; across, up: float) =
  ## Slide pivot within plane facing eye, so whole view shifts with it.
  ##   Slide is multivector sum along frame's own two axes.
  let
    axes = camera.frame(camera.eye)
    slid = position(add(toMultivector(camera.pivot), add(
      wedge(across * camera.distance, toMultivector(axes.axis_right)),
      wedge(up * camera.distance, toMultivector(axes.axis_up)),
    )))
  if slid.isSome: camera.pivot = slid.get


func headingGround*(camera: Camera): Direction =
  ## Read way camera faces, flattened onto ground.
  ##   Direction reader means by forward, looking at scene standing on ground plane.
  ##   Solved from azimuth rather than by flattening `frame.forward` and normalising.
  ##     At elevation limit sight direction is within 0.02 radians of `UP_WORLD`, so
  ##     horizontal part is rounding error scaled to unit length.
  ##     `eye` puts eye at `pivot + radius*(cos azimuth, sin azimuth, ...)`, so way back
  ##     is negation, elevation dropping out.
  Direction(x: -cos(camera.azimuth), y: -sin(camera.azimuth), z: 0.0)


func slideGround*(camera: var Camera; ahead, across, rise: float) =
  ## Slide pivot across world, leaving eye's stance about it alone.
  ##   Forward along `headingGround`, sideways along camera's right, up along world up,
  ##   so whole view travels without turning.
  ##   *Map* reading of movement key rather than *fly* one.
  ##     Forward keeps camera's height whatever it looks at, so holding W skims ground
  ##     instead of diving into it.
  ##     What Supreme Commander and Google Maps do, and reading that goes with
  ##     cursor-aimed zoom.
  ##   `across` reuses frame's `axis_right`, already horizontal (join of sight line and
  ##   world up, dualised), rather than second side direction that could disagree in sign
  ##   with mouse pan.
  ##   All three are fractions of orbit distance, as `pan`'s arguments are.
  let
    axes = camera.frame(camera.eye)
    slid = position(add(toMultivector(camera.pivot), add(
      add(
        wedge(ahead * camera.distance, toMultivector(camera.headingGround)),
        wedge(across * camera.distance, toMultivector(axes.axis_right)),
      ),
      wedge(rise * camera.distance, toMultivector(UP_WORLD)),
    )))
  if slid.isSome: camera.pivot = slid.get



#[ Camera Frame ]#

func frame*(camera: Camera, eye: Position): FrameCamera =
  ## Derive camera's orthonormal axes from its stance, through joins and antiduals.
  ##   Elevation clamp keeps sight axis off world up, so every join below stays defined.
  ##   Takes eye explicitly, so caller already holding it, or calling once per frame
  ##   across many objects, need not pay same trig again.
  let
    axis_sight = toMultivector(eye) ∧ toMultivector(camera.pivot)
    forward = direction(axis_sight)
  doAssert forward.isSome,
    &"Camera eye and pivot must differ, orbit distance is bounded away from zero; got " &
      &"`{eye}` and `{camera.pivot}`."

  let axis_right = directionNormal(axis_sight ∧ toMultivector(UP_WORLD))
  doAssert axis_right.isSome,
    &"Camera sight axis must not run along world up, elevation is clamped short of " &
      &"poles; got `{axis_sight}`."

  let axis_up = directionNormal(axis_sight ∧ toMultivector(axis_right.get))
  doAssert axis_up.isSome,
    &"Camera sight axis and right direction must span plane, being perpendicular; got " &
      &"`{axis_right.get}`."

  # Pin view's +y to world up, as antidual fixes axis only up to sign.
  #   Alignment is library's inner product of two directions, read at scalar.
  let orientation =
    if dot(toMultivector(axis_up.get), toMultivector(UP_WORLD))[Basis.scalar] < 0: -1.0
    else: 1.0
  FrameCamera(
    axis_right: axis_right.get,
    axis_up: orientation * axis_up.get,
    forward: forward.get,
  )


type SettingsFurniture* = tuple
  ## Define everything ground grid and world axes are built from.
  ##   `drawExtentFor` derives every field furniture reads from exactly these, so two
  ##   frames agreeing here draw same furniture, vertex for vertex: what lets front-end
  ##   keep last frame's meshes.
  ##     Field added to `Camera` that `drawExtentFor` reads must be added here too, or
  ##     frame holds furniture no longer matching view.
  ##   Here rather than in each front-end: two private copies would be drift sibling rule
  ##   warns about.
  pivot_x, pivot_y, pivot_z: float
  distance, azimuth, elevation, degrees_field_of_view, reach_scene: float
  height_pixels: int
  is_axes_shown, is_grid_shown: bool


func settingsFurnitureFor*(
  camera: Camera; height_pixels: int; is_axes_shown, is_grid_shown: bool
): SettingsFurniture =
  ## Read furniture's inputs off this camera and frame, for hold comparison.
  ##   Compared exactly by callers: question is whether anything moved at all.
  (
    camera.pivot.x, camera.pivot.y, camera.pivot.z, camera.distance,
    camera.azimuth, camera.elevation, camera.degrees_field_of_view, camera.reach_scene,
    height_pixels, is_axes_shown, is_grid_shown,
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
    frame = camera.frame(eye)
  # Derive four multivector twins through `algebraFilled`.
  #   One derivation point shared with every hand-built extent.
  algebraFilled(DrawExtent(
    scale: DrawScale(
      extent_furniture: extentFurnitureFor(camera.distanceFar),
      eye: eye,
      radius_horizon: radiusHorizonFor(camera.distanceFar),
      forward: frame.forward,
      axis_right: frame.axis_right,
      axis_up: frame.axis_up,
      tangent_half_view: tan(0.5*degToRad(camera.degrees_field_of_view)),
      height_pixels: height_pixels,
      depth_near: camera.distanceNear,
    ),
  ))


func viewBoundsFor*(camera: Camera, scale: DrawExtent, aspect: float): ViewBounds =
  ## Derive frustum points are culled against, once per frame; see `tessellate.isPointInView`.
  ##   Margin is least on-screen radius and one pixel more, as tangent per unit of depth,
  ##   so smallest disc straddling edge is still emitted whatever GPU does with centre
  ##   just outside; point's own radius is added per point by `isPointInView`.
  ##   `aspect` is framebuffer's width over height, which `drawExtentFor` never needs.
  let eye = camera.eye
  let frame = camera.frame(eye)
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


func initMatrixViewProjection*(camera: Camera, aspect: float): Matrix4 =
  ## Compose whole transform from world space to clip space.
  let eye = camera.eye
  initMatrixProjection(
    camera.degrees_field_of_view, aspect, camera.distanceNear, camera.distanceFar
  ) * initMatrixView(eye, camera.frame(eye))



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
    heading*: Option[Direction] ## Direction of horizon objects to face, or none.
      ## Merged where several were asked for: sum of unit directions is nearest thing to
      ## one facing two stars.
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
    pivot*: Position ## Point orbit turns about.
    distance*: float ## Separation of eye from pivot.
    azimuth*, elevation*: float ## Orbit angles, in radians.

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
    anchor_held*: Option[Position] ## World point ease keeps on its pixel, or none.
      ## Set by pointer pick: object clicked stays under pointer while camera comes in.
      ## Ease then runs `towardHoldingAnchor` rather than `toward`; see `advance`.
      ## Meaningless while `goal` is none; set beside it and cleared with it.


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
  if a.heading.isSome != b.heading.isSome: return false
  if a.heading.isNone: return true
  let (d, e) = (a.heading.get, b.heading.get)
  d.x == e.x and d.y == e.y and d.z == e.z


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
  ##   Unchanged by geometry drawing nothing, and by plane at horizon, in view from every
  ##   camera.
  ##   Point at horizon is fixed star, faced along own direction.
  ##   Line at horizon is whole great circle, so first axis spanning perpendicular to its
  ##   normal is picked, putting some of circle in view.
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
    var heading = none(Direction)
    case shape_m.get
    of Kind.Point: heading = directionHorizon(m)
    of Kind.Line:
      let normal = directionNormalHorizon(m)
      if normal.isSome:
        let axes = spanPerpendicular(ORIGIN_WORLD, normal.get)
        if axes.isSome: heading = some(axes.get[0])
    of Kind.Plane: discard
    if heading.isNone: return aim
    let merged =
      if grown.heading.isNone: heading
      # Merge headings as sum of horizon points, read back through horizon reader.
      #   Reader also refuses cancelling pair.
      else: directionHorizon(add(
        toMultivector(grown.heading.get), toMultivector(heading.get)
      ))
    # Leave first heading standing where two cancel outright: neither turn shows both.
    grown.heading = if merged.isSome: merged else: grown.heading
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
  ##   For pointer pick's approach; see `framing.stanceUnderPointer`.
  let tangent_half = tan(0.5*degToRad(camera.degrees_field_of_view))
  distanceHeld(diameter/(2.0*max(fraction, 1.0e-6)*max(tangent_half, 1.0e-6)))


func isGoalHeld*(tween: CameraTween, goal: CameraAim): bool =
  ## Report whether `goal` is one this tween already holds, and would ignore.
  ##   For caller whose preparation is worth skipping: `framing.offerAim` projects every
  ##   selected object several times over, and re-offers same goal every frame.
  tween.goal.isSome and tween.goal.get == goal


func stanceOf*(camera: Camera): CameraStance =
  ## Read where `camera` already stands as stance of its own.
  CameraStance(
    pivot: camera.pivot,
    distance: camera.distance,
    azimuth: camera.azimuth,
    elevation: camera.elevation,
  )


func placed*(camera: Camera, stance: CameraStance): Camera =
  ## Put copy of `camera` at `stance`, lens untouched.
  result = camera
  result.pivot = stance.pivot
  result.distance = stance.distance
  result.azimuth = stance.azimuth
  result.elevation = stance.elevation


func toward*(from_stance, to_stance: CameraStance; progress: float): CameraStance =
  ## Step `progress` of way from one stance to another.
  ##   Distance moves geometrically where everything else moves linearly.
  ##     Distance is multiplicative, and linear ease from 12 to 300 covers most visible
  ##     change in first few frames then crawls.
  # Turn short way round: destination just past -pi is next door to camera short of +pi.
  var delta = to_stance.azimuth - from_stance.azimuth
  while delta > PI: delta -= 2.0*PI
  while delta < -PI: delta += 2.0*PI
  let (near, far) = (max(from_stance.distance, 1.0e-6), max(to_stance.distance, 1.0e-6))
  let stepped = position(add(toMultivector(from_stance.pivot), wedge(
    progress, subtract(
      toMultivector(to_stance.pivot), toMultivector(from_stance.pivot)
    )
  )))
  CameraStance(
    pivot: (if stepped.isSome: stepped.get else: to_stance.pivot),
    distance: near*pow(far/near, progress),
    azimuth: from_stance.azimuth + progress*delta,
    elevation: from_stance.elevation +
      progress*(to_stance.elevation - from_stance.elevation),
  )


func towardHoldingAnchor*(
  from_stance, to_stance: CameraStance; anchor: Position; camera: Camera;
  progress: float
): CameraStance =
  ## Step `progress` of way between stances sharing angles, keeping `anchor` on its pixel.
  ##   Eye stays on line from where it began to `anchor`, its depth to anchor moving
  ##   geometrically, so anchor's direction from eye never changes and nor does its pixel.
  ##   `toward` cannot serve: pivot linear and distance geometric take eye off that line
  ##   mid-ease (168 to 10 puts halfway eye at 41 by one curve, 89 by other), and object
  ##   swung off pointer before swinging back.
  ##   Distance still geometric, pivot read back as eye plus distance along sight.
  ##   `camera` lends its lens and angles: eye of each stance needs them.
  let
    forward = camera.placed(from_stance).frame(camera.placed(from_stance).eye).forward
    eye_from = camera.placed(from_stance).eye
    eye_to = camera.placed(to_stance).eye
    depth_from = max(dot(anchor - eye_from, forward), 1.0e-6)
    depth_to = max(dot(anchor - eye_to, forward), 1.0e-6)
    depth = depth_from*pow(depth_to/depth_from, progress)
    (near, far) = (max(from_stance.distance, 1.0e-6), max(to_stance.distance, 1.0e-6))
    distance = near*pow(far/near, progress)
    # Assemble eye as anchor plus scaled offset back toward where eye began.
    eye = position(add(
      toMultivector(anchor),
      wedge(depth/depth_from, subtract(toMultivector(eye_from), toMultivector(anchor))),
    ))
  if eye.isNone: return to_stance
  CameraStance(
    pivot: Position(
      x: eye.get.x + distance*forward.x,
      y: eye.get.y + distance*forward.y,
      z: eye.get.z + distance*forward.z,
    ),
    distance: distance,
    azimuth: from_stance.azimuth,
    elevation: from_stance.elevation,
  )


func `==`*(a, b: CameraStance): bool =
  ## Compare two stances exactly, for caller asking whether camera would move at all.
  a.pivot.x == b.pivot.x and a.pivot.y == b.pivot.y and a.pivot.z == b.pivot.z and
    a.distance == b.distance and a.azimuth == b.azimuth and a.elevation == b.elevation


func aimAt*(
  tween: var CameraTween; camera: Camera; goal: CameraAim; destination: CameraStance;
  now, duration: float; anchor_held = none(Position); is_renewed = false
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
  ##   `anchor_held` asks ease to keep that world point on its pixel; see `anchor_held`.
  if tween.isGoalHeld(goal) and not is_renewed: return
  tween.goal = some(goal)
  tween.destination = destination
  tween.anchor_held = anchor_held
  # Mark arrived outright where camera already stands on destination.
  #   Easing through whole duration would write reading it holds and fight user who
  #   orbits.
  tween.is_arrived = destination == camera.stanceOf
  tween.started = now
  tween.duration = duration
  tween.stance_from = camera.stanceOf


func advance*(
  tween: var CameraTween, camera: var Camera, now: float,
  ease: proc(t: float): float {.noSideEffect.},
) =
  ## Carry camera one frame further toward destination, and mark it arrived there.
  ##   `ease` is passed in rather than imported so module stays independent of where
  ##   project keeps easing curve.
  ##     Callers hand `tessellate.easeOutCubic`, same curve and duration freshly added
  ##     object grows in with.
  if tween.goal.isNone or tween.is_arrived: return
  let progress = ease(clamp((now - tween.started) / max(tween.duration, 1.0e-6), 0.0, 1.0))
  camera = camera.placed(
    if tween.anchor_held.isSome:
      towardHoldingAnchor(
        tween.stance_from, tween.destination, tween.anchor_held.get, camera, progress
      )
    else: tween.stance_from.toward(tween.destination, progress)
  )
  if now - tween.started >= tween.duration: tween.is_arrived = true


func settle*(tween: var CameraTween, camera: var Camera) =
  ## Put camera on destination at once.
  ##   For caller that must not show half-finished pan, such as storyboard frame about to
  ##   be captured.
  if tween.goal.isNone or tween.is_arrived: return
  camera = camera.placed(tween.destination)
  tween.is_arrived = true


func release*(tween: var CameraTween) =
  ## Withdraw whatever camera was aimed at, leaving it wherever it stands.
  ##   For whoever offers aim, once it has nothing to offer: selection cleared, edit
  ##   session closed.
  ##   Clearing goal outright lets picking same object again aim afresh.
  ##   Not for camera *user* just moved: see `abandon`.
  tween.goal = none(CameraAim)
  tween.is_arrived = false
  tween.anchor_held = none(Position)


func abandon*(tween: var CameraTween) =
  ## Stop carrying camera, but remember what it was carrying it toward.
  ##   For every path moving camera on user's own instruction: orbit, pan or dolly half
  ##   second into ease should win outright.
  ##   Deliberately not `release`.
  ##     Aim is standing offer re-made every frame, so goal cleared here is offered again
  ##     next frame and camera is taken straight back off user.
  ##     Keeping goal and marking it done makes standing offer read as already answered.
  if tween.goal.isSome: tween.is_arrived = true
