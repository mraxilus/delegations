## Turn RGA objects into records and vertices renderer can draw, natively or in browser.
##
## Finite objects are tessellated about support point, i.e. point nearest origin.
##   Line becomes segment along its attitude: `DrawExtent.radiusHorizon` backward from
##   support, same radius forward from eye, so forward end lands exactly on
##   `eye + radius_horizon*axis`, where horizon marker for its attitude would be drawn.
##   Plane becomes flat translucent disc at fixed radius (`EXTENT_PLANE`) plus rim marking
##   its edge, spanned by own frame.
##     Fixed rather than camera-relative, so plane holds one size in world units as
##     camera dollies or orbits.
## Object at horizon (infinitely far, no support point) is drawn fixed to `DrawExtent.eye`
## at `DrawExtent.radiusHorizon`, near far clip plane.
##   Point becomes marker standing in fixed direction; line becomes great circle of
##   directions its pencil spans; plane, unique universal whole-sky object every plane at
##   horizon is, becomes dome over entire sky.
##   Fixed to eye rather than origin, so orbiting or dollying leaves each in same apparent
##   direction, as real stars would.
## World furniture (ground grid, world axes) reaches `DrawExtent.extentFurniture`.
##   Tied to far clip distance rather than orbit distance (`extentFurnitureFor`), so it
##   reads as extending indefinitely.
##   Drawn as fog about eye (`fogFurnitureFor`): solid nearby, faded to nothing at that
##   reach, laid wherever camera has flown.
##   Finite *line object* reaches same extent from own support, since it is content and
##   not reference.
## Storage is fixed and owned by caller: meshes are cleared and refilled every frame.
##
##   |--------|-----------------------|----------------------------------------------|
##   | Kind   | Crosses wire as       | Carries                                      |
##   |--------|-----------------------|----------------------------------------------|
##   | Ribbon | `RibbonRecord` x1     | Lines, plane rims, horizon circles, axes,    |
##   |        |                       | ground grid.                                 |
##   | Disc   | `DiscRecord` x1       | Finite plane's translucent fill.             |
##   | Dome   | `DomeRecord` x1       | Horizon plane's whole-sky wash.              |
##   | Point  | `Vertex` per point    | Points, stars.                               |
##   |--------|-----------------------|----------------------------------------------|
##
## Every kind but point is one compact record per shape, widened into triangles by own
## vertex shader.
##   Each record type's doc states expansion, and `expand*` reference proc beside it is
##   what suite pins and shaders are checked against.
## Line is drawn as ribbon, quad sized to width in screen pixels, never `GL_LINES`.
##   Line width is hint target may ignore: most WebGL implementations clamp it to one
##   pixel. See `addSegment`.
##   Ribbons draw apart from washes because state differs: ribbon writes depth,
##   translucent wash does not.
##
## Shared by desktop (`visualiser.nim`) and browser (`browser_bridge.nim`) render paths.

{.experimental: "strictFuncs".}

import std/[math, options, strformat]

import ./euclid



#[ Mesh Configuration ]#

# Allow caller to resize plane's drawn radius and vertex storage without editing source.
#   E.g. `--define:visualiser.extent_plane=20 --define:visualiser.vertices_max=32768`.
#   `.define` takes only integers, bools or strings, so plain ratios below stay ordinary
#   constants.
const
  EXTENT_PLANE* {.define: "visualiser.extent_plane".} = 8
    ## Fix how far plane's disc and rim reach from support point, in world units.
    ##   Independent of camera, so plane holds one size as camera dollies or orbits.
  FRACTION_HORIZON* = 0.9
    ## Place horizon geometry this fraction of way to far clip plane.
    ##   Star, great circle, whole sky.
    ##   Reads as farthest thing without being clipped away.
  FRACTION_FURNITURE* = 0.95
    ## Reach world axes, ground grid and every finite line this far toward far clip plane.
    ##   Tied to that depth rather than orbit distance, so all three read as extending
    ##   indefinitely.
  FRACTION_GRID_FADE_START* = 0.06
    ## Hold ground grid lines at full alpha out to this fraction of reach.
    ##   Rest fades toward `FRACTION_GRID_FADE_END`: past that, cells crowd into few
    ##   pixels under perspective and read as aliasing noise.
    ##   Measured by rendering: fog is about eye, which stands whole orbit distance from
    ##   content, and smaller fraction left ground under target already fading.
    ##     0.06 of reach is 1.14 orbit distances, target inside solid core.
  FRACTION_GRID_FADE_END* = 0.20
    ## Cut ground grid lines off entirely at this fraction of reach.
    ##   Faint line still aliases, so fix is to stop drawing it, not dim it further.
    ##   0.20 of reach is 3.8 orbit distances, fog's edge about 2.8 distances beyond
    ##   target.
  RIBBONS_MAX* {.define: "visualiser.ribbons_max".} = 20161
    ## Bound how many ribbon segments one frame holds.
    ##   Binding case is scene filled to `scene.ITEMS_MAX` with *lines*, each two
    ##   segments `tessellate.addLine` steps out, every one selected and drawn twice,
    ##   plus ghost.
    ##   Furniture set, sharing this cap, wants `2*LINES_GRID_MAX` lattice lines and axes.
    ##   `scene.nim` carries `static` check tying this to `ITEMS_MAX`, which this module
    ##   cannot see. Overflow is `doAssert`, dead page rather than dropped triangle.
  VERTICES_MAX* {.define: "visualiser.vertices_max".} = 10080
    ## Bound how many vertices point mesh holds, per frame.
    ##   Points are all that is left in vertex form; every other kind is record bounded
    ##   by own cap.
    ##   Binding case: scene filled with points, every one selected, drawn twice.
  DISCS_MAX* {.define: "visualiser.discs_max".} = 10081
    ## Bound how many disc records one frame holds.
    ##   Binding case: scene filled with finite planes, every one selected and drawn
    ##   twice, plus ghost.
  RINGS_MAX* {.define: "visualiser.rings_max".} = 10081
    ## Bound how many ring records one frame holds, by same worst case as `DISCS_MAX`.
    ##   Plane draws fill and rim together, so two caps move as pair.
  DOMES_MAX* {.define: "visualiser.domes_max".} = 10081
    ## Bound how many dome records one frame holds, by same worst case as `DISCS_MAX`.
    ##   With every plane at horizon.
  ANIMATION_MILLISECONDS* {.define: "visualiser.animation_milliseconds".} = 350
    ## Set how long freshly added object takes to grow and fade fully into view.
    ##   Milliseconds rather than seconds, as `.define` takes integer.
  DIAMETER_POINT_LEAST* = 6.0'f32
    ## Bound smallest diameter point is drawn at, in pixels.
    ##   Point carries world radius and shrinks with distance (see `radiusDrawnAt`); this
    ##   floor keeps distant one readable dot rather than sub-pixel flicker.
    ##   Both render targets read it: desktop as uniform, browser through
    ##   `nimRenderLineWidths`.
  RADIUS_ITEM_DEFAULT* = 0.08
    ## Set drawn radius, in world units, item takes when nothing chose one.
    ##   What nine-pixel dot every point once wore spans at opening camera: 19 units of
    ##   orbit over 900 pixels of height, so old scenes and fresh constructions look as
    ##   they did from there and only gain perspective.
  RADIUS_ITEM_LEAST* = 0.001
    ## Bound smallest radius either editor lets reader type.
    ##   Model refuses only zero and below; this keeps typed size above what any camera
    ##   in demo resolves, so item never vanishes into least on-screen size for good.
  FRACTION_AMBIENT_SHADE* = 0.25'f32
    ## Set how bright lit point's night side is drawn, as fraction of its colour.
    ##   Rest is Lambert's cosine toward its sun; see `Vertex.light`.
    ##   Quarter: dark side still reads as body in its own hue, not hole in field.
    ##   Both render targets read it as uniform, browser through `nimShadeAmbient`.
  LIGHT_NONE* = Direction(x: 0.0, y: 0.0, z: 0.0)
    ## Name absence of light: zero vector, which both vertex shaders read as flat.
    ##   Zero rather than option: it crosses wire as three floats per point, and shader
    ##   has no option to unwrap. Sun, ghost, star at horizon and point with no sun all
    ##   take it.
  RADIUS_ITEM_MOST* = 1.0e6
    ## Bound largest radius either editor lets reader type.
    ##   Desktop's drag widget takes no upper bound as no bounds at all, so one is named;
    ##   far past any scene here, which spans about 3,000 units.
  WIDTH_LINE_FURNITURE* = 1.5'f32
    ## Set width of ground grid and world axes, in pixels.
    ##   Thinner than scene line object (`WIDTH_LINE_OBJECT`), so reference recedes
    ##   behind content.
  WIDTH_LINE_OBJECT* = 2.5'f32
    ## Set width of scene line object, in pixels.
    ##   Wider than furniture, so it reads as content.

static:
  doAssert EXTENT_PLANE > 0, &"Plane radius must be positive; got `{EXTENT_PLANE}`."
  doAssert FRACTION_HORIZON > 0 and FRACTION_HORIZON < 1.0,
    &"Horizon fraction must fall strictly between 0 and 1; got `{FRACTION_HORIZON}`."
  doAssert FRACTION_FURNITURE > 0 and FRACTION_FURNITURE < 1.0,
    &"Furniture fraction must fall strictly between 0 and 1; got `{FRACTION_FURNITURE}`."
  doAssert FRACTION_GRID_FADE_START > 0 and FRACTION_GRID_FADE_START < 1.0,
    &"Grid fade start fraction must fall strictly between 0 and 1; got " &
    &"`{FRACTION_GRID_FADE_START}`."
  doAssert FRACTION_GRID_FADE_END > FRACTION_GRID_FADE_START and FRACTION_GRID_FADE_END <= 1.0,
    &"Grid fade end fraction must exceed the start fraction and fall within 0 and 1; " &
    &"got `{FRACTION_GRID_FADE_END}`."
  doAssert VERTICES_MAX >= 1024, &"Vertex storage must hold 1024; got `{VERTICES_MAX}`."
  doAssert ANIMATION_MILLISECONDS > 0,
    &"Appear animation must take positive time; got `{ANIMATION_MILLISECONDS}` ms."
  doAssert WIDTH_LINE_OBJECT > WIDTH_LINE_FURNITURE,
    &"Object line width must exceed furniture's; got `{WIDTH_LINE_OBJECT}` <= " &
    &"`{WIDTH_LINE_FURNITURE}`."


const
  EXTENT_PLANE_F* = float(EXTENT_PLANE)
    ## Hold `EXTENT_PLANE` as float.
    ##   `.define` cannot take float literal, and every use wants float.

  ANIMATION_SECONDS* = float(ANIMATION_MILLISECONDS) / 1000.0
    ## Convert configured duration to seconds `animationProgress` works in.

const
  SIZE_CELL_GRID* = 10.0
    ## Set ground grid's cell size, in world units, at every reach.
    ##   One size: grid stepping its cell with reach re-scaled ground silently under
    ##   reader, so no distance read off it was comparable with last.
    ##     Fixed cell is ruler; stepping one is not.
    ##   `sizeCellGridFor` steps it by decades past 1,200 units of ground reach, where
    ##   alternative is no ground at all.
    ##   Ten rather than hundred, measured by rendering both: at opening placement
    ##   hundred-unit cell put at most one line in view.
  CELLS_GRID_HALF_MAX* = 120
    ## Bound how many cells ground grid lays between camera and edge of reach, each way.
    ##   Reach follows far clip plane, which follows orbit distance, so unbounded reach
    ##   multiplies lines without limit as camera pulls back.
    ##   `sizeCellGridFor` spends this on cell, not reach.
    ##     Cutting *reach* against it left camera past 1,200 units with ground stopping
    ##     short, and past twice that with black void.
    ##     Stepping cell keeps same line count across reach camera has.
    ##   Sized by rendering: fewer cells left grid patch floating in near field at orbit
    ##   distance 300.
  ALPHA_GRID* = 0.75'f32
    ## Scale ground grid's opacity by this, on top of `alphaGridFade`.
    ##   Width alone was not carrying difference from drawn line; readers read ruled
    ##   ground as content.
    ##   Quarter off rather than half: grid colour already sits close to backdrop, and
    ##   half off rendered ground that read as absent.
    ##   Applied where grid is built rather than to `Ink.Grid`, which is also
    ##   `INK_POOL_FREE`; dimming entry would make that object translucent.
  LINES_GRID_MAX* = 2*CELLS_GRID_HALF_MAX + 1
    ## Bound how many lattice lines one grid family lays, also how many ribbon records.
    ##   Line is one record spanning whole chord of fog disc, faded per fragment.
    ##   Per-fragment fade needs no piece boundaries and is exact, where cutting each
    ##   line into pieces to sample fade cost boundary sums per moving frame.
  SEGMENTS_CIRCLE_HORIZON* = 96
    ## Set segment count in horizon line's great circle, or finite plane's rim.
    ##   Dense enough to read as circular.
  LATITUDES_HORIZON* = 12
  LONGITUDES_HORIZON* = 24
    ## Set band counts in horizon plane's whole-sky dome.
  ORIGIN_WORLD* = Position(x: 0, y: 0, z: 0)
    ## Set world origin, which objects through it are drawn about.
  ALPHA_WASH* = 0.16'f32
    ## Set opacity of finite plane's fill.
    ##   Flat across disc, since rim marks edge; low enough that whatever sits behind,
    ##   including crossing plane, stays legible.
  ALPHA_WASH_SKY* = 0.22'f32
    ## Set opacity of horizon plane's sky dome.
    ##   No edge to fade toward, covering whole sphere, so it must read as coloured sky
    ##   without overwhelming what depth test lets show through.
  FRACTION_DIMMED_ALPHA* = 0.55'f32
    ## Scale non-focal constructed object's alpha by this.
    ##   Stays legible as context while receding behind what step showcases.
  MUTE_DESATURATION* = 0.6'f32
    ## Blend muted object's colour this far toward own grayscale, short of replacing it.
    ##   Dulled hint of hue rather than every muted object converging to one grey.
  MUTE_AXIS_TOWARD_GREY* = 0.45'f32
    ## Blend world axis's colour this far toward own grayscale, no alpha change.
    ##   Permanent palette entry, unlike `muted()`.
    ##   Enough that red/green/blue trio stops competing with categorical colours, not so
    ##   much axes stop reading as axes; readers once took axes for drawn lines.
    ##   Read by `axisTinted`, which builds three palette entries from it.
    ##     Hand-applied blend in literals drifted from number describing it.
  SCALE_AXIS_LUMINANCE* = 0.50'f32
    ## Scale world axis's blended colour down by this, after grey blend.
    ##   Desaturating alone leaves three mid-grey lines as conspicuous as objects;
    ##   together these put axes between ground grid and drawn object in weight.

static:
  doAssert SIZE_CELL_GRID > 0, &"Grid cell size must be positive; got `{SIZE_CELL_GRID}`."
  doAssert CELLS_GRID_HALF_MAX > 0,
    &"Grid must lay at least one cell each way; got `{CELLS_GRID_HALF_MAX}`."
  doAssert ALPHA_GRID > 0 and ALPHA_GRID < 1.0,
    &"Grid opacity must fall strictly between 0 and 1; got `{ALPHA_GRID}`."
  doAssert FRACTION_DIMMED_ALPHA > 0 and FRACTION_DIMMED_ALPHA < 1.0,
    &"Dimmed alpha fraction must fall strictly between 0 and 1; got `{FRACTION_DIMMED_ALPHA}`."
  doAssert MUTE_DESATURATION > 0 and MUTE_DESATURATION <= 1.0,
    &"Mute desaturation must fall between 0 and 1; got `{MUTE_DESATURATION}`."
  doAssert MUTE_AXIS_TOWARD_GREY > 0 and MUTE_AXIS_TOWARD_GREY <= 1.0,
    &"Axis mute fraction must fall between 0 and 1; got `{MUTE_AXIS_TOWARD_GREY}`."
  doAssert SCALE_AXIS_LUMINANCE > 0 and SCALE_AXIS_LUMINANCE <= 1.0,
    &"Axis luminance scale must fall between 0 and 1; got `{SCALE_AXIS_LUMINANCE}`."



#[ Type Definitions ]#

type
  Ink* {.pure.} = enum ## Define palette slot, so every colour in output lives in one table.
    ## Structural slots, spent on furniture of drawing itself.
    Backdrop, ## Colour framebuffer is cleared to.
    AxisX, ## World x axis through origin; standard convention is red.
    AxisY, ## World y axis through origin; standard convention is green.
    AxisZ, ## World z axis through origin; standard convention is blue.
    Grid, ## World reference grid on ground.
    Guide, ## Construction helper, e.g. plane normal.
    Outline, ## Selection outline drawn around highlighted object.
      ## Never cycled to, only drawn where caller names slot as highlighted (see
      ## `renderer.drawOutline`).
    Invalid, ## Reserved for object that is wrong rather than merely coloured.
      ## Magenta no object may be assigned, so seeing it always means something is
      ## invalid.
      ##   Worn by rubber-band of drag over pair that makes nothing
      ##   (`interaction.inkOfDrag`), warning arriving before release.
      ##   Never leaned on alone: magenta reads as blue under deuteranopia, so that drag
      ##   also shows no ghost.
    ## Categorical slots, spent by caller on telling one object from another.
    ##   Named by hue rather than role, as caller alone knows what objects mean.
    ##     Grade is legible from shape, so colour carries identity.
    ##   Declared in this order for cycling: consecutive names sit far apart on wheel, so
    ##   two objects added one after another read as different even under colour-vision
    ##   deficiency.
    ##   Five slots, not sixteen and not eight.
    ##     Sixteen packed into band clear of three axis colours left every slot reading
    ##     as shade of teal, blue, violet or magenta; reserving magenta for `Invalid`
    ##     cost three more.
    ##     Adding hues back was measured and reproduced sixteen-slot failure; see
    ##     `lut_ink_to_rgba`.
    Rose, Copper, Olive, Jade, Cobalt,

  Placement* {.pure.} = enum ## Define what became of object once drawn.
    Finite, ## Object had finite extent and was drawn where it stands.
    Horizon, ## Object lay wholly at horizon; only its direction could be drawn.
    Empty, ## Multivector carried no drawable geometry at all.

  Rgba* = object ## Define colour channels, in 0 .. 1.
    red*, green*, blue*, alpha*: float32

  Vertex* = object ## Define one point record exactly as it is uploaded.
    ## One instance per point: vertex shader fans it into camera-facing quad of
    ## `pointCorners`, and fragment stage rounds quad into disc; see `radiusDrawnAt`.
    x*, y*, z*: float32
    radius*: float32 ## Drawn radius, in world units.
    light_x*, light_y*, light_z*: float32 ## Unit direction toward point's sun, or zero.
      ## Fragment stage shades disc as sphere lit from there; zero draws flat. See
      ## `lighting.lightsFor` and `FRACTION_AMBIENT_SHADE`.
    red*, green*, blue*, alpha*: float32

  Mesh* = object ## Define point vertices, in storage fixed at compile time.
    ## One shape still uploaded as vertices; every widened kind crosses wire as records.
    vertices*: array[VERTICES_MAX, Vertex]
    count_vertices*: int
    index_overlay*: Option[int] ## Where overlay run begins, if this mesh has one.
      ## Vertices below it are drawn against depth buffer; rest are drawn after against
      ## depth cleared first, landing over whatever is there and in depth order among
      ## themselves.
      ##   `markOverlay` sets it, and each render path draws two runs as two calls; see
      ##   `renderer.drawRun`.
      ## None where nothing asked to be drawn over; zero means whole mesh is overlay.
      ## Watermark rather than second `MeshSet`, since set reserves whole storage for run
      ## that is usually one object.
      ##   Order already decides buckets (see `visualiser.assembleMeshes`), so index into
      ##   order costs nothing.

  RibbonRecord* = object ## Define one line segment exactly as it is uploaded.
    ## Vertex shader's input, not vertex.
    ##   Each record is drawn as one instance of six corners.
    ##   Shader clips to near plane, derives across as `cross(head - tail, eye - tail)`,
    ##   and steps each corner off by half width of own end's world-per-pixel: work
    ##   `expandRibbon` states in Nim, reference shaders are held to.
    ##   Sixteen floats against forty-two for six expanded vertices, and no arithmetic
    ##   on CPU.
    tail_x*, tail_y*, tail_z*: float32
    head_x*, head_y*, head_z*: float32
    width*: float32
    fog*: float32 ## Whether fragment shader fades this record by distance from eye.
      ## 1 for world furniture, 0 otherwise.
      ## `alphaGridFade` states fade; flag on record lets fogged and unfogged ribbons
      ## share one buffer in any order.
    tail_red*, tail_green*, tail_blue*, tail_alpha*: float32
    head_red*, head_green*, head_blue*, head_alpha*: float32

  RibbonMesh* = object ## Define every ribbon segment of one frame, in fixed storage.
    records*: array[RIBBONS_MAX, RibbonRecord]
    count*: int
    index_overlay*: Option[int] ## Where overlay run begins; see `Mesh.index_overlay`.

  DiscRecord* = object ## Define one filled disc exactly as it is uploaded.
    ## Disc-fill vertex shader's input, not vertex.
    ##   Each record is drawn as one instance of static fan of
    ##   `3 * SEGMENTS_CIRCLE_HORIZON` unit-circle corners.
    ##   Shader places every corner at `centre + cos*arm_first + sin*arm_second`: work
    ##   `expandDiscVertex` states in Nim.
    ##   Thirteen floats against fanned vertices, and no per-frame trigonometry on CPU.
    ## Arms arrive already scaled by radius, so record needs no radius.
    centre_x*, centre_y*, centre_z*: float32
    arm_first_x*, arm_first_y*, arm_first_z*: float32
    arm_second_x*, arm_second_y*, arm_second_z*: float32
    fill_red*, fill_green*, fill_blue*, fill_alpha*: float32

  DomeRecord* = object ## Define one whole-sky sphere exactly as it is uploaded.
    ## Dome vertex shader's input, not vertex.
    ##   Each record is drawn as one instance of static lat/long sphere of unit
    ##   directions; shader places every corner at `centre + radius*direction`, stated
    ##   in `expandDomeVertex`.
    ## Orientation is not field because full sphere has none (see `tessellate.addPlane`).
    centre_x*, centre_y*, centre_z*, radius*: float32
    red*, green*, blue*, alpha*: float32

  DiscMesh* = object ## Define every disc record of one frame, in fixed storage.
    records*: array[DISCS_MAX, DiscRecord]
    count*: int

  RingRecord* = object ## Define one plane's rim exactly as it is uploaded.
    ## Ring vertex shader's input, not vertex.
    ##   `DiscRecord` with width: same centre and same two radius-scaled arms, drawn as
    ##   one instance of `SEGMENTS_CIRCLE_HORIZON` quads rather than fan of triangles.
    ## Record that took rim off CPU.
    ##   Rim stepped and emitted as ninety-six separate ribbons per plane was nearly all
    ##   ribbon traffic on scene of planes; one record now, and rim costs what fill costs.
    ## Width is *pixel* width, so shader widens each segment in screen space exactly as
    ## ribbon.
    ##   `ribbonOfRing` derives very `RibbonRecord` segment would have been, and
    ##   `expandRingVertex` is `expandRibbon` of it.
    centre_x*, centre_y*, centre_z*: float32
    arm_first_x*, arm_first_y*, arm_first_z*: float32
    arm_second_x*, arm_second_y*, arm_second_z*: float32
    red*, green*, blue*, alpha*: float32
    width*: float32

  RingMesh* = object ## Define every ring record of one frame, in fixed storage.
    records*: array[RINGS_MAX, RingRecord]
    count*: int
    index_overlay*: Option[int] ## Where overlay run begins; see `Mesh.index_overlay`.
      ## Rim needs own split as line does: selected plane is tessellated second time
      ## after `markOverlay`, and without mark second rim draws behind own translucent
      ## fill, exactly highlight it exists to draw.

  DomeMesh* = object ## Define every dome record of one frame, in fixed storage.
    records*: array[DOMES_MAX, DomeRecord]
    count*: int

  WashKind* {.pure.} = enum ## Define which record array one wash run draws from.
    Disc, Dome

  WashRun* = object ## Define one stretch of same-kind wash records, drawn as one call.
    kind*: WashKind
    first*: int32 ## Index of run's first record, within own kind's array.
    count*: int32

  WashRuns* = object ## Define frame's wash draw order, across both record kinds.
    ## Translucent pass's memory of scene order.
    ##   Discs and domes land in two arrays, but two washes crossing still blend in order
    ##   scene emitted them.
    ##   Each append extends current run where it can and opens new one where kind
    ##   changes, and each render path walks runs in sequence.
    ##   Usually one run per object, of one record.
    runs*: array[DISCS_MAX + DOMES_MAX, WashRun]
    count*: int
    index_overlay*: Option[int] ## Index of first *run* of overlay pass.
      ## `Mesh.index_overlay`'s rule at run grain, since run never straddles mark:
      ## `markOverlay` seals current run, and append refuses to extend across it.

  MeshSet* = object ## Define everything one frame draws: vertices and every record kind.
    ## Points are one shape still assembled as vertices; rest cross wire as records.
    points*: Mesh
    ribbons*: RibbonMesh
    discs*: DiscMesh
    rings*: RingMesh
    domes*: DomeMesh
    washes*: WashRuns

  DrawScale* = object ## Define how far this frame's geometry reaches, and from where.
    ## Euclidean half of frame's camera.
    ##   Everything ribbon needs to hold constant width on screen, and everything picture
    ##   is measured against.
    ##   Algebra's reading of same camera lives beside it in `tessellate.DrawExtent`,
    ##   which carries this whole record and adds multivector twins; this module cannot
    ##   name those, point of split.
    extent_furniture*: float ## How far ground grid, world axes and finite lines extend.
      ## From origin or support; tied to far clip distance via `extentFurnitureFor`, not
      ## orbit distance, so all read as reaching indefinitely.
    eye*: Position ## Camera's eye position, horizon geometry is anchored to.
      ## Stays in fixed apparent direction as camera pans or dollies.
    radius_horizon*: float ## How far from `eye` horizon geometry is drawn.
    forward*: Direction ## Camera's sight axis, depth is measured along.
    axis_right*: Direction ## Camera's screen-right axis; point's disc spans it.
    axis_up*: Direction ## Camera's screen-up axis; point's disc spans it.
    tangent_half_view*: float ## Tangent of half vertical field of view.
    height_pixels*: int ## Framebuffer height, which vertical field of view spans.
    depth_near*: float ## Camera's near clip distance, depth is clamped at.
      ## Nothing nearer is drawn, and without clamp segment past eye reads negative depth
      ## and turns ribbon inside out.



#[ Camera-Relative Scale ]#

func radiansPerPixel*(scale: DrawScale): float =
  ## Measure how much of camera's angular field one pixel of height spans.
  ##   Small-angle reading of `worldPerPixelAt` at unit depth, right unit for anything
  ##   placed by *direction*: horizon geometry sits on sphere about eye, where pixel is
  ##   angle and not distance.
  2.0*scale.tangentHalfView/float(max(scale.heightPixels, 1))


func worldPerPixelAt*(place: Position, scale: DrawScale): float =
  ## Measure how much world distance one screen pixel spans at `place`'s depth.
  ##   Turns width or clearance stated in pixels into world offset, wherever anchored.
  ##     Every ribbon's half-width and every marker's clearance come through here.
  ##   Depth along sight axis, not distance from eye: perspective divides by former, and
  ##   two differ by cosine of off-axis angle, over percent even near middle of frame.
  ##   Clamped at near plane: depth goes negative behind eye, and negative half-width
  ##   folds ribbon over on itself.
  let depth = max(dot(place - scale.eye, scale.forward), scale.depthNear)
  2.0*depth*scale.tangentHalfView/float(max(scale.heightPixels, 1))


func radiusDrawnAt*(radius: float, place: Position, scale: DrawScale): float =
  ## Measure radius point is drawn at, in world units.
  ##   Its own, or least on-screen size where that is larger.
  ##   Rule both vertex shaders apply, stated once here for marker and pick to follow.
  ##   Perspective alone: radius stays fixed and disc shrinks as depth grows, until floor
  ##   `DIAMETER_POINT_LEAST` holds it at readable dot.
  max(radius, 0.5*float(DIAMETER_POINT_LEAST)*worldPerPixelAt(place, scale))


func radiusPixelsAtDepth*(radius: float, depth: float, scale: DrawScale): float =
  ## Measure radius point at `depth` along sight axis is drawn at, in pixels.
  ##   `radiusDrawnAt` divided back out, for caller already holding depth: pick reads it
  ##   off projection for every point, and building position's offset from eye per
  ##   point per walk allocated on JS backend. Same clamp at near plane as
  ##   `worldPerPixelAt`.
  let per_pixel =
    2.0*max(depth, scale.depthNear)*scale.tangentHalfView/float(max(scale.heightPixels, 1))
  max(radius/per_pixel, 0.5*float(DIAMETER_POINT_LEAST))


func radiusPixelsAt*(radius: float, place: Position, scale: DrawScale): float =
  ## Measure radius point is drawn at, in pixels; `radiusDrawnAt` divided back out.
  ##   For marker's ring and pick's disc, both measured on screen.
  radiusPixelsAtDepth(radius, dot(place - scale.eye, scale.forward), scale)


func radiusHorizonFor*(distance_far: float): float =
  ## Compute how far from eye horizon geometry sits this frame, given far clip distance.
  ##   Infinitely far sits near renderer's outer depth limit at any orbit distance.
  distance_far * FRACTION_HORIZON


func alphaGridFade*(radius, radius_fade_start, radius_end: float): float =
  ## Fade from full alpha at `radius_fade_start` to none at `radius_end`.
  ##   Past fade start grid cells crowd into few pixels under perspective, and fading
  ##   them trades aliasing noise for clean horizon.
  ##   `radius` is distance from eye, bounds from `fogFurnitureFor`.
  ##     One schedule for all furniture (grid, axes), so reference ends
  ##     at one horizon.
  ##   Reference fog half of both ribbon fragment shaders is held to.
  ##     Change to this, GLSL 3.30 in `renderer.nim` or WebGL source in `glue.js` is not
  ##     finished until other two are checked.
  ##     Runs per fragment there against interpolated world position, exact where
  ##     per-piece sampling was piecewise-linear.
  1.0 - clamp((radius - radius_fade_start) / (radius_end - radius_fade_start), 0.0, 1.0)


func fogFurnitureFor*(extent: float): tuple[radius_full, radius_gone: float] =
  ## Solve where world furniture's fog begins and ends, as distances from eye.
  ##   Grid line or axis holds full strength within `radius_full` and has faded by
  ##   `radius_gone`, where `addGrid` and `addAxes` cut geometry off.
  ##   Fog rather than halo about world origin.
  ##     Halo made origin place reader may not leave: pan hundred units away and ground
  ##     was gone. Measured from eye so what is near reader is solid whichever way they
  ##     look.
  ##   Uncapped: outer radius stopping at `CELLS_GRID_HALF_MAX` cells left camera far out
  ##   in black void, axes included.
  ##     Line count is bounded by `sizeCellGridFor` stepping *cell* instead.
  let radius_gone = FRACTION_GRID_FADE_END*extent
  # Hold inner radius as ratio of outer, so two keep same proportion at any reach.
  (radius_full: radius_gone*(FRACTION_GRID_FADE_START/FRACTION_GRID_FADE_END),
   radius_gone: radius_gone)


func sizeCellGridFor*(radius_ground: float): float =
  ## Choose ground grid's cell size for ground disc of `radius_ground`.
  ##   `SIZE_CELL_GRID` wherever that lays no more than `CELLS_GRID_HALF_MAX` cells
  ##   across radius, ten times it for every further factor of ten needed.
  ##   Stepping cell, which `SIZE_CELL_GRID` argues against, and argument holds where
  ##   made.
  ##     Answered here is case that rule left with nothing: reach past which fixed cell
  ##     lays tens of thousands of lines, choice being stepped cell or no ground.
  ##   Decades, so coarser grid's lines are finer grid's lines: step coarsens without
  ##   moving anything. 1-2-5 sequence does not nest.
  ##   First step at 1,200 units of ground reach, about orbit distance 316, far past
  ##   anything reader reads distances off.
  ##   `SIZE_CELL_GRID` itself for disc of no radius.
  let radius_cells = float(CELLS_GRID_HALF_MAX)*SIZE_CELL_GRID
  if radius_ground <= radius_cells: return SIZE_CELL_GRID
  SIZE_CELL_GRID*pow(10.0, ceil(log10(radius_ground/radius_cells)))


func extentFurnitureFor*(distance_far: float): float =
  ## Compute how far ground grid, world axes and every finite line reach this frame.
  ##   Given far clip distance, independent of orbit distance, so all read as extending
  ##   indefinitely rather than shrinking back when camera does.
  distance_far * FRACTION_FURNITURE



#[ Palette ]#

func axisTinted(base: Rgba): Rgba =
  ## Tint one full-strength axis hue down into reference mark it should read as.
  ##   Blends toward luminance-grey by `MUTE_AXIS_TOWARD_GREY`, using `muted()`'s
  ##   0.299/0.587/0.114 weights, then scales by `SCALE_AXIS_LUMINANCE`.
  ##   Alpha untouched: permanent palette entry, not per-frame dim.
  ##   Evaluated at compile time into table below, so axes *are* what constants say.
  let grey = 0.299*base.red + 0.587*base.green + 0.114*base.blue
  func softened(channel: float32): float32 =
    SCALE_AXIS_LUMINANCE*((1.0'f32 - MUTE_AXIS_TOWARD_GREY)*channel +
      MUTE_AXIS_TOWARD_GREY*grey)
  Rgba(
    red: softened(base.red),
    green: softened(base.green),
    blue: softened(base.blue),
    alpha: base.alpha,
  )


const lut_ink_to_rgba: array[Ink, Rgba] = [
  Ink.Backdrop: Rgba(red: 0.063, green: 0.075, blue: 0.102, alpha: 1.0),
  # Soften standard convention at full strength through `axisTinted`.
  #   Hue says which axis; softening keeps it from saying drawn object.
  Ink.AxisX: axisTinted(Rgba(red: 0.85, green: 0.22, blue: 0.22, alpha: 1.0)),
  Ink.AxisY: axisTinted(Rgba(red: 0.26, green: 0.80, blue: 0.26, alpha: 1.0)),
  Ink.AxisZ: axisTinted(Rgba(red: 0.24, green: 0.42, blue: 0.90, alpha: 1.0)),
  Ink.Grid: Rgba(red: 0.180, green: 0.204, blue: 0.259, alpha: 1.0),
  Ink.Guide: Rgba(red: 0.286, green: 0.322, blue: 0.400, alpha: 1.0),
  Ink.Outline: Rgba(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
  Ink.Invalid: Rgba(red: 0.612, green: 0.000, blue: 0.722, alpha: 1.0),
  Ink.Rose: Rgba(red: 0.690, green: 0.090, blue: 0.373, alpha: 1.0),
  Ink.Copper: Rgba(red: 0.812, green: 0.451, blue: 0.275, alpha: 1.0),
  Ink.Olive: Rgba(red: 0.341, green: 0.431, blue: 0.000, alpha: 1.0),
  Ink.Jade: Rgba(red: 0.133, green: 0.655, blue: 0.478, alpha: 1.0),
  Ink.Cobalt: Rgba(red: 0.357, green: 0.565, blue: 0.780, alpha: 1.0),
] ## Map palette slot to colour: five assignable hues, magenta `Invalid` held out of run.
  ##   Held to floors `REQUIREMENTS.md` states by `tools/check_palette`, which reads this
  ##   table itself: typical vision, red-green deficiency, tritanopia, and every hue
  ##   against `Invalid` and each axis.
  ##     One declared exception, `Jade`/`Cobalt` under tritanopia, argued in that tool.
  ##   Every assignable hue is held clear of `Invalid`: fine as categorical peer is not
  ##   fine once magenta means wrong, and blue and magenta converge under deuteranopia.
  ##   Do not fill remaining arc back to eight: seven-hue set measured two greens
  ##   indistinguishable under deficiency. Five is what fits honestly.


const
  COUNT_INK* = ord(Ink.high) + 1
    ## Count palette slots, structural and categorical alike.

  INK_CATEGORICAL_FIRST* = Ink.Rose
    ## Name where categorical run begins.
    ##   Everything before it is structural, and offering one as object's colour would let
    ##   object wear backdrop, world axis or outline.

  COUNT_INK_CATEGORICAL* = ord(Ink.high) - ord(INK_CATEGORICAL_FIRST) + 1
    ## Count slots colour picker may offer.
    ##   Callers walk run as one contiguous block, so `Ink`'s declaration order is
    ##   load-bearing: every categorical slot follows every structural one.
    ##     `static` assertion below enforces it.

static:
  doAssert COUNT_INK_CATEGORICAL == 5,
    &"Ink's categorical slots must stay one contiguous run of five ending at Ink.high, " &
      &"or a colour picker offers a different run; got `{COUNT_INK_CATEGORICAL}`."


func inkCategorical*(index: int): Ink = Ink(ord(INK_CATEGORICAL_FIRST) + index)
  ## Read palette slot at position within categorical run.


func categoricalIndex*(ink: Ink): int = ord(ink) - ord(INK_CATEGORICAL_FIRST)
  ## Read palette slot's position within categorical run. Negative for structural slot.


let lut_ink_to_name* = block:
  ## Name each palette slot, for offering them in picker.
  ##   Bound as `let` rather than `const`, since picker needs address of first entry.
  var lut: array[Ink, cstring]
  for ink in Ink: lut[ink] = cstring($ink)
  lut


func colour*(ink: Ink): lent Rgba = lut_ink_to_rgba[ink]
  ## Read colour of palette slot.
  ##   Borrowed, not returned by value: JS backend deep-copied entry per call, once per
  ##   object per frame (Art. VII.1).


func fade*(base: Rgba, alpha: float32): Rgba =
  ## Rewrite colour's opacity, leaving its hue alone.
  Rgba(red: base.red, green: base.green, blue: base.blue, alpha: alpha)


func muted*(base: Rgba): Rgba =
  ## Blend colour partway toward own grayscale, cutting opacity to `FRACTION_DIMMED_ALPHA`.
  ##   For constructed object not in focus: shown as context rather than hidden.
  ##   Blended toward own luminance, not replaced by `Ink.Grid.colour`: fading every hue
  ##   to one grey made muted line indistinguishable from grid and lost identity.
  let luminance = 0.299'f32*base.red + 0.587'f32*base.green + 0.114'f32*base.blue
  Rgba(
    red: base.red + (luminance - base.red)*MUTE_DESATURATION,
    green: base.green + (luminance - base.green)*MUTE_DESATURATION,
    blue: base.blue + (luminance - base.blue)*MUTE_DESATURATION,
    alpha: base.alpha*FRACTION_DIMMED_ALPHA,
  )



#[ Appear Animation ]#

func easeOutCubic*(t: float): float =
  ## Ease progress toward 1, quickly at first then settling, for materialising feel.
  let u = 1.0 - clamp(t, 0.0, 1.0)
  1.0 - u*u*u


func animationProgress*(now, born: float): float =
  ## Report how much of appear animation item born at `born` has completed by `now`.
  ##   Clamped and eased, so caller may pass any `now - born` and always get value to
  ##   scale or fade by.
  easeOutCubic((now - born) / ANIMATION_SECONDS)



#[ Vertex Assembly ]#

func clearMeshes*(meshes: var MeshSet) =
  ## Drop every vertex and record assembled so far, so frame may be rebuilt from scratch.
  meshes.points.count_vertices = 0
  meshes.points.index_overlay = none(int)
  meshes.ribbons.count = 0
  meshes.ribbons.index_overlay = none(int)
  meshes.discs.count = 0
  meshes.rings.count = 0
  meshes.rings.index_overlay = none(int)
  meshes.domes.count = 0
  meshes.washes.count = 0
  meshes.washes.index_overlay = none(int)


func markOverlay*(meshes: var MeshSet) =
  ## Say that everything appended from here on is drawn over what came before.
  ##   Called once, between ordinary objects and selected ones.
  ##   Calling twice moves boundary rather than adding second one: assembly order
  ##   decides what is over what.
  meshes.points.index_overlay = some(meshes.points.count_vertices)
  meshes.ribbons.index_overlay = some(meshes.ribbons.count)
  meshes.rings.index_overlay = some(meshes.rings.count)
  meshes.washes.index_overlay = some(meshes.washes.count)


func addMarker*(
  meshes: var MeshSet, at: Position, radius: float, light: Direction, tint: Rgba,
  alpha: float32
) =
  ## Append point marking single position at `radius`, in `tint`'s hue at `alpha`.
  ##   Lit from `light`, unit direction toward sun, or `LIGHT_NONE` for flat disc.
  ##   Alpha apart from tint so caller fading point need not build faded `Rgba` first.
  ##     `fade` per point was two allocations and copy, once per point per frame.
  ##   `radius` is world units; shader floors it at `DIAMETER_POINT_LEAST` on screen.
  let count = meshes.points.count_vertices
  doAssert count < VERTICES_MAX,
    &"Mesh holds at most {VERTICES_MAX} vertices, raise `--define:visualiser.vertices_max`; " &
      &"got `{count}`."
  # Write fields in place.
  #   `Vertex` literal assigned here was deep copy per point on JS backend (Art. VII.1).
  template vertex: untyped = meshes.points.vertices[count]
  vertex.x = float32(at.x)
  vertex.y = float32(at.y)
  vertex.z = float32(at.z)
  vertex.radius = float32(radius)
  vertex.light_x = float32(light.x)
  vertex.light_y = float32(light.y)
  vertex.light_z = float32(light.z)
  vertex.red = tint.red
  vertex.green = tint.green
  vertex.blue = tint.blue
  vertex.alpha = alpha
  meshes.points.count_vertices = count + 1


func blend(first, second: Rgba; fraction: float): Rgba =
  ## Read colour fraction of way between two tints, for ribbon end near clip has moved.
  ##   At module scope rather than nested in `addSegment`: JS backend materialises nested
  ##   routine on every call of its parent, thousands of times per frame.
  let (a, b) = (1.0 - fraction, fraction)
  Rgba(
    red: float32(a*float(first.red) + b*float(second.red)),
    green: float32(a*float(first.green) + b*float(second.green)),
    blue: float32(a*float(first.blue) + b*float(second.blue)),
    alpha: float32(a*float(first.alpha) + b*float(second.alpha)),
  )


const POINTS_SCRATCH_MAX* = SEGMENTS_CIRCLE_HORIZON + 1
  ## Bound places tessellation step may assemble before emitting them.
  ##   Horizon line's great circle is largest, one extra boundary so closing segment ends
  ##   on place stepped at angle loop would have used.


type RibbonPiece* = object
  ## Define one ribbon segment, fully resolved: where it runs, and colour of each end.
  ##   Record algebra hands picture.
  ##     Assembling whole family into these first and emitting after makes seam line in
  ##     code rather than claim in comment, which lets panel say what each side cost.
  ##   Everything here is Euclidean.
  tail*, head*: Position
  tint_tail*, tint_head*: Rgba


type DrawScratch* = object
  ## Define working space tessellation step assembles into before it emits anything.
  ##   One object rather than buffer per shape, so caller supplies scratch once.
  ##     Desktop carves this from frame arena and browser holds one; neither allocates
  ##     per frame, and suite's copy is same shape.
  ##   Both members are written and read within single step, so they carry nothing
  ##   between callers and need no clearing.
  ribbons*: array[LINES_GRID_MAX, RibbonPiece] ## One piece per lattice line or axis chord.
    ## Sized for larger grid family.
  places*: array[POINTS_SCRATCH_MAX, Position]


func directionAcross*(tail, head, eye: Position): Option[Direction] =
  ## Resolve which way to step off segment so its two edges land either side on screen.
  ##   Perpendicular to segment and to sight ray reaching it: cross product of two edges
  ##   leaving `tail`.
  ##   Picture's quantity, not geometry's.
  ##     Join `directionNormal(tail ∧ head ∧ eye)` ran per segment per moving frame,
  ##     walking 16x16 coefficient pairs through `nimCopy` on JS backend.
  ##     Suite holds this cross equal to that join, sign included.
  ##   None where eye lies on segment's line, or segment has no length.
  normalize(cross(head - tail, eye - tail))


func expandRibbon*(record: RibbonRecord, scale: DrawScale): array[6, Vertex] =
  ## Expand one ribbon record into six vertices shader will make of it.
  ##   Reference implementation of ribbon vertex shader; nothing else runs it.
  ##     Both render targets carry same arithmetic in GLSL (`renderer.nim` and `glue.js`,
  ##     sibling copies); change to any of three is not finished until other two are
  ##     checked.
  ##     Suite holds this against algebra (near clip equal to `clipToEyeSide`, across
  ##     equal to join through `directionAcross`), so chain runs shader ≡ this ≡ algebra.
  ##   Quad rather than `GL_LINES` because line width is *hint* both targets may ignore.
  ##   Each end is offset by half width of *its own* world-per-pixel, so ribbon narrows
  ##   with distance as line does, and two parallel lines keep shared vanishing point.
  ##   Clipped to near plane first.
  ##     World offset proportional to depth gives constant screen width only while quad's
  ##     edges interpolate depth linear along segment, false once one end stands behind
  ##     eye; unclipped world axis drew twenty pixels wide near origin.
  ##   Segment entirely behind eye, or one eye stands on, comes back as six coincident
  ##   zero-alpha vertices: quad rasterising nothing, as shader leaves it.
  let
    tail = Position(x: record.tail_x, y: record.tail_y, z: record.tail_z)
    head = Position(x: record.head_x, y: record.head_y, z: record.head_z)
    tint_tail = Rgba(red: record.tail_red, green: record.tail_green,
      blue: record.tail_blue, alpha: record.tail_alpha)
    tint_head = Rgba(red: record.head_red, green: record.head_green,
      blue: record.head_blue, alpha: record.head_alpha)
    depth_tail = dot(tail - scale.eye, scale.forward)
    depth_head = dot(head - scale.eye, scale.forward)
    across = directionAcross(tail, head, scale.eye)
  if (depth_tail < scale.depthNear and depth_head < scale.depthNear) or across.isNone:
    return

  var
    (near, far) = (tail, head)
    (tint_near, tint_far) = (tint_tail, tint_head)
  if depth_tail < scale.depthNear:
    let fraction = (scale.depthNear - depth_tail)/(depth_head - depth_tail)
    near = tail + fraction*(head - tail)
    tint_near = blend(tint_tail, tint_head, fraction)
  elif depth_head < scale.depthNear:
    let fraction = (scale.depthNear - depth_head)/(depth_tail - depth_head)
    far = head + fraction*(tail - head)
    tint_far = blend(tint_head, tint_tail, fraction)

  let
    offset_near = 0.5*float(record.width)*worldPerPixelAt(near, scale)*across.get
    offset_far = 0.5*float(record.width)*worldPerPixelAt(far, scale)*across.get
    corners = [
      near - offset_near, far - offset_far, far + offset_far, near + offset_near,
    ]
    tints = [tint_near, tint_far, tint_far, tint_near]
  for slot, index in [0, 1, 2, 0, 2, 3]:
    result[slot] = Vertex(
      x: float32(corners[index].x),
      y: float32(corners[index].y),
      z: float32(corners[index].z),
      red: tints[index].red,
      green: tints[index].green,
      blue: tints[index].blue,
      alpha: tints[index].alpha,
    )


func addRibbon*(
  meshes: var MeshSet; tail, head: Position; tint_tail, tint_head: Rgba; width: float32;
  is_fogged: bool = false
) =
  ## Append one line segment as ribbon record, for vertex shader to widen.
  ##   No camera needed: near clip, across direction and screen-constant width all moved
  ##   to GPU (see `expandRibbon`).
  ##   `is_fogged` says whether fragment shader also fades record by distance from eye
  ##   (see `RibbonRecord.fog`).
  ##   Emit half of boundary is sixteen-float copy.
  let count = meshes.ribbons.count
  doAssert count < RIBBONS_MAX,
    &"Frame holds at most {RIBBONS_MAX} ribbons, raise `--define:visualiser.ribbons_max`; " &
      &"got `{count}`."
  meshes.ribbons.records[count] = RibbonRecord(
    tail_x: float32(tail.x),
    tail_y: float32(tail.y),
    tail_z: float32(tail.z),
    head_x: float32(head.x),
    head_y: float32(head.y),
    head_z: float32(head.z),
    width: width,
    fog: (if is_fogged: 1.0'f32 else: 0.0'f32),
    tail_red: tint_tail.red,
    tail_green: tint_tail.green,
    tail_blue: tint_tail.blue,
    tail_alpha: tint_tail.alpha,
    head_red: tint_head.red,
    head_green: tint_head.green,
    head_blue: tint_head.blue,
    head_alpha: tint_head.alpha,
  )
  meshes.ribbons.count = count + 1


func addRibbonPieces*(
  meshes: var MeshSet, pieces: openArray[RibbonPiece], width: float32,
  is_fogged: bool = false
) =
  ## Append every assembled piece as ribbon record.
  ##   Emit half of seam: no multivector is named here, and none can be.
  for piece in pieces:
    meshes.addRibbon(
      piece.tail, piece.head, piece.tint_tail, piece.tint_head, width, is_fogged
    )


func addSegment*(
  meshes: var MeshSet; tail, head: Position; tint: Rgba; width: float32
) =
  ## Append ribbon of one tint end to end.
  meshes.addRibbon(tail, head, tint, tint, width)


let UNIT_CIRCLE_RIM* = unitRing[SEGMENTS_CIRCLE_HORIZON + 1](SEGMENTS_CIRCLE_HORIZON)
  ## Hold rim's fixed ring of angles, resolved once at start-up by `euclid.unitRing`.
  ##   One boundary past wrap rather than reuse of first entry, so closing segment ends
  ##   on value `cos(2*PI)` takes, hair off `cos(0)`'s.
  ##   Exported for other walkers of same ring: horizon line's great circle (through
  ##   `addRing`) and `picking`'s sampling of it, which must step very angles drawn one
  ##   does.


proc ribbonOfRing*(record: RingRecord, segment: int): RibbonRecord =
  ## Report ribbon one segment of ring *is*: one place ring becomes line.
  ##   Ring is closed walk of `SEGMENTS_CIRCLE_HORIZON` segments around circle its centre
  ##   and arms describe, each ordinary ribbon of ring's tint and width.
  ##   Stating it as derivation keeps ring shader honest: `expandRingVertex` is
  ##   `expandRibbon` of this, so build has exactly one screen-space widening.
  ##   `proc` rather than `func` only because it reads `UNIT_CIRCLE_RIM`, which
  ##   `strictFuncs` counts as effect.
  let
    centre = Position(x: record.centre_x, y: record.centre_y, z: record.centre_z)
    arm_first = Direction(x: record.arm_first_x, y: record.arm_first_y,
      z: record.arm_first_z)
    arm_second = Direction(x: record.arm_second_x, y: record.arm_second_y,
      z: record.arm_second_z)
    at_tail = UNIT_CIRCLE_RIM[segment]
    at_head = UNIT_CIRCLE_RIM[segment + 1]
    tail = onCircleAt(centre, arm_first, arm_second, at_tail.cos_angle, at_tail.sin_angle)
    head = onCircleAt(centre, arm_first, arm_second, at_head.cos_angle, at_head.sin_angle)
  RibbonRecord(
    tail_x: float32(tail.x),
    tail_y: float32(tail.y),
    tail_z: float32(tail.z),
    head_x: float32(head.x),
    head_y: float32(head.y),
    head_z: float32(head.z),
    width: record.width,
    fog: 0.0,
    tail_red: record.red,
    tail_green: record.green,
    tail_blue: record.blue,
    tail_alpha: record.alpha,
    head_red: record.red,
    head_green: record.green,
    head_blue: record.blue,
    head_alpha: record.alpha,
  )


proc expandRingVertex*(
  record: RingRecord, segment: int, scale: DrawScale
): array[6, Vertex] =
  ## Expand one segment of ring into six vertices shader will make of it.
  ##   Reference implementation of ring vertex shader; nothing else runs it.
  ##     Both render targets carry same arithmetic in GLSL, sibling copies as
  ##     `expandRibbon` and `expandDiscVertex` have.
  ##   `expandRibbon` of `ribbonOfRing`, and nothing more: ring adds *where* segment is,
  ##   nothing to how line is widened.
  expandRibbon(ribbonOfRing(record, segment), scale)


func addRing*(
  meshes: var MeshSet; centre: Position; axis_first, axis_second: Direction;
  radius: float; tint: Rgba; width: float
) =
  ## Append one plane's rim as single record: circle `addDisc` fills, outlined.
  ##   Arms arrive already scaled by radius, as `addDisc`'s do.
  doAssert meshes.rings.count < RINGS_MAX,
    &"Ring storage holds {RINGS_MAX} records, raise `--define:visualiser.rings_max`; got " &
      &"`{meshes.rings.count}`."
  let
    arm_first = radius*axis_first
    arm_second = radius*axis_second
  meshes.rings.records[meshes.rings.count] = RingRecord(
    centre_x: float32(centre.x),
    centre_y: float32(centre.y),
    centre_z: float32(centre.z),
    arm_first_x: float32(arm_first.x),
    arm_first_y: float32(arm_first.y),
    arm_first_z: float32(arm_first.z),
    arm_second_x: float32(arm_second.x),
    arm_second_y: float32(arm_second.y),
    arm_second_z: float32(arm_second.z),
    red: float32(tint.red),
    green: float32(tint.green),
    blue: float32(tint.blue),
    alpha: float32(tint.alpha),
    width: float32(width),
  )
  inc meshes.rings.count


func expandDiscVertex*(record: DiscRecord; cos_angle, sin_angle: float): Vertex =
  ## Widen one disc record into fan corner given table entry stands for.
  ##   Reference disc-fill vertex shaders are held to, beside `expandRibbon`.
  ##     Change to it, GLSL in `renderer.nim` or WebGL source in `glue.js` is not
  ##     finished until other two are checked.
  ##   One statement: centre plus two radius-scaled arms weighted by corner's cosine and
  ##   sine, i.e. `euclid.onCircleAt`, centre corner carrying zero for both.
  ##   Flat tint across fan; see `addDisc`.
  let at = onCircleAt(
    Position(
      x: float(record.centre_x),
      y: float(record.centre_y),
      z: float(record.centre_z),
    ),
    Direction(
      x: float(record.arm_first_x),
      y: float(record.arm_first_y),
      z: float(record.arm_first_z),
    ),
    Direction(
      x: float(record.arm_second_x),
      y: float(record.arm_second_y),
      z: float(record.arm_second_z),
    ),
    cos_angle, sin_angle,
  )
  Vertex(
    x: float32(at.x),
    y: float32(at.y),
    z: float32(at.z),
    red: record.fill_red,
    green: record.fill_green,
    blue: record.fill_blue,
    alpha: record.fill_alpha,
  )


func expandDomeVertex*(record: DomeRecord, unit: Direction): Vertex =
  ## Widen one dome record into sphere corner given unit direction stands for.
  ##   Reference dome vertex shaders are held to; same three-way rule as
  ##   `expandDiscVertex`.
  ##   One statement: centre plus unit direction scaled by radius.
  ##     Sum `spherePoint` walked through algebra before sphere became static geometry,
  ##     which suite still holds it equal to.
  Vertex(
    x: float32(float(record.centre_x) + float(record.radius)*unit.x),
    y: float32(float(record.centre_y) + float(record.radius)*unit.y),
    z: float32(float(record.centre_z) + float(record.radius)*unit.z),
    red: record.red,
    green: record.green,
    blue: record.blue,
    alpha: record.alpha,
  )


proc discCorners*(): seq[float32] =
  ## Emit disc fan's static corner buffer.
  ##   `(cos, sin)` per corner, three corners per rim segment, wound centre, this
  ##   segment's boundary, next one's.
  ##   Centre corner is `(0, 0)`, which `expandDiscVertex` lands on centre exactly.
  ##   One source for both render targets: desktop uploads from Nim and browser through
  ##   `nimDiscCorners`, so neither carries hand-copied table.
  result = newSeq[float32](2*3*SEGMENTS_CIRCLE_HORIZON)
  for i in 0 ..< SEGMENTS_CIRCLE_HORIZON:
    let at = 6*i
    result[at + 0] = 0.0
    result[at + 1] = 0.0
    result[at + 2] = float32(UNIT_CIRCLE_RIM[i].cos_angle)
    result[at + 3] = float32(UNIT_CIRCLE_RIM[i].sin_angle)
    result[at + 4] = float32(UNIT_CIRCLE_RIM[i + 1].cos_angle)
    result[at + 5] = float32(UNIT_CIRCLE_RIM[i + 1].sin_angle)


const COUNT_CORNERS_POINT* = 4
  ## Count corners point quad is drawn from: one triangle strip.
  ##   Strip rather than two triangles: third less vertex work per point, and instanced
  ##   strips restart per instance, so quads never join.


proc pointCorners*(): seq[float32] =
  ## Emit point's static corner buffer: `(across, up)` in -1 .. 1, strip order.
  ##   Vertex shader steps `across*radius` along `DrawScale.axis_right` and `up*radius`
  ##   along `axis_up` from record's centre, and fragment stage discards outside unit
  ##   circle of same pair; see `radiusDrawnAt`.
  ##   One source for both render targets, as `discCorners` is.
  @[-1.0'f32, -1.0'f32, 1.0'f32, -1.0'f32, -1.0'f32, 1.0'f32, 1.0'f32, 1.0'f32]


proc ringCorners*(): seq[float32] =
  ## Emit ring's static corner buffer.
  ##   Six floats per corner: tail angle's `(cos, sin)`, head angle's `(cos, sin)`, then
  ##   `(end, side)` pair `expandRibbon`'s six corners are wound in.
  ##   Six corners per rim segment, all segments laid end to end.
  ##   Every ring instance draws whole buffer, so one `RingRecord` becomes entire rim in
  ##   one draw.
  ##     `expandRingVertex` states what shader does with each corner, and this table is
  ##     only *where* on circle each sits.
  ##   Angles come off `UNIT_CIRCLE_RIM`, so drawn circle is unchanged.
  ##   One source for both render targets, as `discCorners` is.
  const WINDING = [(0.0'f32, -1.0'f32), (1.0'f32, -1.0'f32), (1.0'f32, 1.0'f32),
    (0.0'f32, -1.0'f32), (1.0'f32, 1.0'f32), (0.0'f32, 1.0'f32)]
  result = newSeq[float32](6*6*SEGMENTS_CIRCLE_HORIZON)
  var at = 0
  for segment in 0 ..< SEGMENTS_CIRCLE_HORIZON:
    let
      tail = UNIT_CIRCLE_RIM[segment]
      head = UNIT_CIRCLE_RIM[segment + 1]
    for (which_end, side) in WINDING:
      result[at + 0] = float32(tail.cos_angle)
      result[at + 1] = float32(tail.sin_angle)
      result[at + 2] = float32(head.cos_angle)
      result[at + 3] = float32(head.sin_angle)
      result[at + 4] = which_end
      result[at + 5] = side
      at += 6


func domeCorners*(): seq[float32] =
  ## Emit dome's static corner buffer.
  ##   One unit direction per corner, six corners per lat/long quad, wound as CPU quads
  ##   were. `expandDomeVertex` says what each becomes.
  ##   One source for both render targets, as `discCorners` is.
  result = newSeq[float32](3*6*LATITUDES_HORIZON*LONGITUDES_HORIZON)
  var at = 0
  for lat in 0 ..< LATITUDES_HORIZON:
    for lon in 0 ..< LONGITUDES_HORIZON:
      # Wind quad's four unit directions [0, 1, 2, 0, 2, 3] as `addQuad` wound it.
      var corners: array[4, tuple[theta, phi: float]]
      corners[0] = (theta: PI*float(lat)/float(LATITUDES_HORIZON),
        phi: 2.0*PI*float(lon)/float(LONGITUDES_HORIZON))
      corners[1] = (theta: PI*float(lat)/float(LATITUDES_HORIZON),
        phi: 2.0*PI*float(lon + 1)/float(LONGITUDES_HORIZON))
      corners[2] = (theta: PI*float(lat + 1)/float(LATITUDES_HORIZON),
        phi: 2.0*PI*float(lon + 1)/float(LONGITUDES_HORIZON))
      corners[3] = (theta: PI*float(lat + 1)/float(LATITUDES_HORIZON),
        phi: 2.0*PI*float(lon)/float(LONGITUDES_HORIZON))
      for index in [0, 1, 2, 0, 2, 3]:
        let (theta, phi) = corners[index]
        result[at + 0] = float32(sin(theta)*cos(phi))
        result[at + 1] = float32(sin(theta)*sin(phi))
        result[at + 2] = float32(cos(theta))
        at += 3


func appendWashRun(meshes: var MeshSet, kind: WashKind) =
  ## Note one more record of `kind` in wash draw order.
  ##   Extends current run where it is same kind and this side of overlay mark, opens
  ##   new one otherwise. See `WashRuns`.
  let count = meshes.washes.count
  if count > 0 and meshes.washes.runs[count - 1].kind == kind and
      meshes.washes.index_overlay != some(count):
    meshes.washes.runs[count - 1].count += 1
    return
  doAssert count < len(meshes.washes.runs),
    &"Frame holds at most {len(meshes.washes.runs)} wash runs; got `{count}`."
  meshes.washes.runs[count] = WashRun(
    kind: kind,
    first: int32(if kind == WashKind.Disc: meshes.discs.count else: meshes.domes.count),
    count: 1,
  )
  meshes.washes.count = count + 1


func addDisc*(
  meshes: var MeshSet; center: Position; axis_first, axis_second: Direction;
  radius: float; tint: Rgba
) =
  ## Append flat, uniformly translucent disc record filling circle `addRing` outlines.
  ##   For disc-fill vertex shader to fan out.
  ##   Flat rather than faded toward rim, since rim marks boundary.
  ##     Tilt still reads through foreshortened ellipse, and low constant alpha keeps
  ##     whatever sits behind legible.
  let count = meshes.discs.count
  doAssert count < DISCS_MAX,
    &"Frame holds at most {DISCS_MAX} discs, raise `--define:visualiser.discs_max`; got " &
      &"`{count}`."
  meshes.appendWashRun(WashKind.Disc)
  let
    arm_first = radius*axis_first
    arm_second = radius*axis_second
  meshes.discs.records[count] = DiscRecord(
    centre_x: float32(center.x),
    centre_y: float32(center.y),
    centre_z: float32(center.z),
    arm_first_x: float32(arm_first.x),
    arm_first_y: float32(arm_first.y),
    arm_first_z: float32(arm_first.z),
    arm_second_x: float32(arm_second.x),
    arm_second_y: float32(arm_second.y),
    arm_second_z: float32(arm_second.z),
    fill_red: tint.red,
    fill_green: tint.green,
    fill_blue: tint.blue,
    fill_alpha: tint.alpha,
  )
  meshes.discs.count = count + 1


func addDome*(meshes: var MeshSet, center: Position, radius: float, tint: Rgba) =
  ## Append whole-sky sphere record around `center`, for dome vertex shader to widen.
  ##   Plane at horizon is unique universal whole-sky object, same regardless of which
  ##   points produced it (see `directionNormalHorizon`), so only `radius` and `tint`
  ##   decide its shape.
  ##   Every direction camera can see sky in shows it, looking down across ground
  ##   included.
  ##     Dome stopped at eye's horizontal cut off sky camera genuinely sees.
  ##     Occlusion against nearer things is depth test's job.
  let count = meshes.domes.count
  doAssert count < DOMES_MAX,
    &"Frame holds at most {DOMES_MAX} domes, raise `--define:visualiser.domes_max`; got " &
      &"`{count}`."
  meshes.appendWashRun(WashKind.Dome)
  meshes.domes.records[count] = DomeRecord(
    centre_x: float32(center.x),
    centre_y: float32(center.y),
    centre_z: float32(center.z),
    radius: float32(radius),
    red: tint.red,
    green: tint.green,
    blue: tint.blue,
    alpha: tint.alpha,
  )
  meshes.domes.count = count + 1
