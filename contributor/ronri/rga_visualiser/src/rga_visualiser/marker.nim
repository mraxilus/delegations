## Kind selection or hover marker to object it marks, in screen pixels.
##
## Marker says "this one", and says it best when its outline echoes thing it surrounds.
##   Ring reads as *that point*, pair of rails as *that line*, circle lying on plane as
##   *that plane*.
##   One screen-space circle for all three said only "something here", and on plane said
##   it in wrong place: centred on support disc is not drawn around.
## Every marker keeps same clear space, `GAP_MARKER` pixels, between object's drawn edge
## and its outline, so three read as one family.
##   Gap is measured from sizes object is drawn at (`mesh.radiusPixelsAt`,
##   `mesh.WIDTH_LINE_OBJECT`, `mesh.EXTENT_PLANE_F`), so changing draw size moves marker
##   with it.
##
##   |------------------|---------------------------------------------------------------|
##   | Kind            | Marker                                                        |
##   |------------------|---------------------------------------------------------------|
##   | Point            | `Ring`: circle in screen space, about drawn point.            |
##   | Line             | `Rails`: two screen-space segments flanking its projection.   |
##   | Plane            | `Loop`: circle lying *on plane*, outside its own rim.         |
##   | Line at horizon  | `Bands`: two small circles on sky flanking great circle       |
##   |                  |   line itself is drawn as.                                    |
##   | Plane at horizon | `Frame`: boundary around whole viewport, since object it      |
##   |                  |   marks is whole sky.                                         |
##   | Point at horizon | `Ring`, about star it is drawn as.                            |
##   |------------------|---------------------------------------------------------------|
##
## Last two draw fixed to eye rather than around point in scene.
##   What marker surrounds is *whatever is drawn*, and both are drawn: great circle and
##   whole sky.
## Markers are described here and drawn by each render path's foreground layer
## (`visualiser.drawSelectionMarker`, browser scripts's SVG overlay), never as scene geometry.
##   Loop lying exactly on plane would z-fight with its fill, and marker occluded by
##   object it marks is not marker.
##
## Shared by desktop (`visualiser.nim`) and browser (`bridge.nim`) render paths.

{.experimental: "strictFuncs".}

import std/[math, options, strformat]

import pga
import ./[boundary, camera, tessellate, picking]



#[ Marker Configuration ]#

const
  GAP_MARKER* = 6.0
    ## Set clear space between object's drawn edge and its marker, in pixels.
    ##   One number for all three shapes: consistent band of untouched background is
    ##   what makes selection legible.
    ##   Held tight: wide band reads as second object, and on several selected objects
    ##   bands become busiest thing on screen.
  HEIGHT_MARKER_LABEL* = 16.0
    ## Set nominal height of selected object's name label, in pixels.
    ##   Label's centre is placed half this above marker's top, so text box sits clear
    ##   of outline whichever face each front-end sets; faces differ, metrics stay theirs.
    ##   Fourteen is comfortable floor glanceable on-screen text research puts on face
    ##   size, and read small over scene; sixteen asked for by eye, at semibold weight.
  WIDTH_MARKER_LABEL_HALO* = 2.0
    ## Set width of halo around label's letters, in pixels.
    ##   Halo wears scene's backdrop colour, not marker's white: halo that blends with
    ##   ground knocks surroundings out of letters, one that contrasts dominates them
    ##   (cartographic label practice). Two pixels clears disc under label without
    ##   thickening strokes.
  ALPHA_MARKER_LABEL_HALO* = 0.85'f32
    ## Set halo's opacity.
    ##   Solid enough to clear, soft enough to keep object's edge showing beside letters.
  MARGIN_LABEL_VIEW* = 40.0
    ## Set how far in from view's edge line's label anchor is held, in pixels, along line.
    ##   Support off screen slides anchor along visible stretch to this far from edge it
    ##   left through; whole label then stays readable rather than half cut.
  WIDTH_MARKER_COMET* = 3.5'f32
    ## Widen comet to this thickness at head, in pixels, tapering to `WIDTH_MARKER`.
    ##   Thicker than `WIDTH_MARKER`, whole of how it reads: weight separates lit part
    ##   from rest, since marker is already pure white with nowhere brighter to go.
    ##   Tail meets line at *exactly* its width, so only head is edge.
    ##   One width for orientation pulse and drag band alike: same mark saying same thing.
  WIDTH_MARKER* = 1.5'f32
    ## Set thickness of every marker outline, and of drag rubber-band, in pixels.
    ##   Thinner than object it marks (`WIDTH_LINE_OBJECT`), so marker reads as
    ##   annotation rather than heavier geometry.
  ALPHA_MARKER_SELECTED* = 0.9'f32
    ## Draw selection's marker this much of full opacity.
    ##   Short of full: pure white at full strength is brighter than any object it
    ##   surrounds, inverting emphasis. Hair of transparency settles it behind geometry.
  ALPHA_MARKER_HOVER* = 0.6'f32
    ## Draw hover's marker this much of full opacity.
    ##   Hover wears same outline selection does, so hovering line previews exactly rails
    ##   selecting it would draw; weight alone tells two apart.
  SEGMENTS_MARKER_LOOP* = 64
    ## Cut plane's marker circle into this many pieces before projecting.
    ##   Fewer than rim's `SEGMENTS_CIRCLE_HORIZON`: thin overlay whose corners fall below
    ##   pixel well before visible.

const
  SEGMENTS_MARKER_RAILS* = 4
    ## Bound how many segments line's rails come to.
    ##   One each side, each cut into two halves `tessellate.addLine` draws line as.
    ## Place point's ring this far from point, in pixels.
  OFFSET_MARKER_RAIL* = 0.5*float(WIDTH_LINE_OBJECT) + GAP_MARKER
    ## Place each of line's rails this far from line, in pixels.
    ##   Exactly, everywhere along it, at every orientation and distance, since offset is
    ##   applied in screen space rather than as world step. See `markerRails`.
    ##   World offset read well in common case, parallel lines sharing vanishing point,
    ##   but *rate* of convergence was perspective's, and along half whose far point lies
    ##   behind eye it was flare, not convergence.
    ##     Measured over three cameras on demo's line; figures in `PROVENANCE.md`.
    ##     With screen offset every flat half reads stated gap at every sample, and
    ##     converging halves still close on vanishing point.
    ##   Ceiling on gap *at support* alone left flare along half untouched.
  PASSES_MARKER_RAIL* = 4
    ## Fix how many times line's rails settle toward gap they may read.
    ##   Each pass narrows offset by factor last reading was over by; narrowing moves
    ##   where each rail leaves viewport, so extent shifts under answer.
    ##   Measured over camera sweep: two passes settle every camera exactly.
    ##     Four because loop stops when reading is inside ceiling, so spare passes cost
    ##     nothing.
  CLEARANCE_MARKER_TOUCH* = 54.5
    ## Push every marker outward by up to this many pixels partway through touch hold.
    ##   Settles back as hold completes.
    ##   Fingertip covers what it presses, so marker filling underneath says nothing to
    ##   person filling it.
    ##   Sized from far end: point's ring reaches about twice thumb's contact patch at
    ##   peak, in framebuffer pixels and CSS pixels alike; see browser scripts on two layers.
    ##   Added in pixels rather than multiplied, so it means one thing on point's ring
    ##   and on rim hundreds of pixels across. Mouse never sees it: cursor hides nothing.
  SEGMENTS_MARKER_BANDS* = 48
    ## Cut each of horizon line's two flanking circles into this many pieces.
    ##   Fewer than `SEGMENTS_CIRCLE_HORIZON`, for reason `SEGMENTS_MARKER_LOOP` gives.
  POINTS_MARKER_BAND* = SEGMENTS_MARKER_BANDS + 2
    ## Bound points one band is drawn through, sampling and cut ends together.
    ##   Two past sampling: band edge of view cuts carries crossing point at each end.
  SEGMENTS_MARKER_FRAME* = 64
    ## Cut horizon plane's boundary into this many even angular steps.
    ##   Four corner directions are merged in on top.
    ##   Multiple of four, so four edge midpoints, first places expanding circle meets
    ##   screen, are sampled exactly rather than straddled.
  CORNERS_MARKER_FRAME* = 4
    ## Sample this many corner directions on top of even steps.
    ##   Corner missed by fraction of step is corner visibly cut off finished frame.
    ##   Points on straight edge lie *on* it by construction.
  SEGMENTS_MARKER_PULSE* = 16
    ## Cut travelling pulse's spine into this many points.
    ##   Enough for run to bend with curved outline; coarse spine reads as steps rather
    ##   than thinning once run tapers.
  SEGMENTS_MARKER_CAP* = 3
    ## Round pulse's head with this many points between its two sides.
    ##   Head is one end that is edge, and flat cut at `WIDTH_MARKER_COMET` reads as run
    ##   chopped. Tail needs none: it ends at outline's own width.
  POINTS_MARKER_PULSE* = 2*SEGMENTS_MARKER_PULSE + SEGMENTS_MARKER_CAP
    ## Bound points in one run's finished outline: both sides of spine, plus head's cap.
  SEGMENTS_MARKER_OUTLINE* = SEGMENTS_MARKER_LOOP
    ## Bound segments of any outline pulse may be laid along.
    ##   Plane's loop is longest. Sized here because `samplePulse` measures whatever it is
    ##   handed; assertion below keeps that true.
  RUNS_MARKER_PULSE* = 2
    ## Bound how many separate runs one marker's pulse comes in.
    ##   Two, because shapes drawn in pieces are drawn in two: line's pair of rails,
    ##   horizon line's pair of bands. Both pieces pulse, or still one reads as broken.
    ##   Rail's halves are walked as one path; pulsing each half separately put four
    ##   comets at four unrelated places.
  LENGTH_MARKER_COMET* = 64.0
    ## Light this much of line into head, in pixels, measured back from head.
    ##   Pixels rather than share of what it runs along.
    ##     Share made mark's size property of thing it annotates: short along rail
    ##     against long round plane's circle seen close, from one constant.
    ##   Line shorter than this lights all of itself; see `FRACTION_MARKER_PULSE`.
  FRACTION_MARKER_PULSE* = 0.35
    ## Bound how much of outline pulse may cover.
    ##   Cap, not size: on marker smaller than run, fixed length lights most of outline
    ##   with nothing plain to read against, and run lapping own tail states no direction.
  FALLOFF_MARKER_COMET* = 1.2
    ## Shrink comet down its tail on this power of distance from head.
    ##   Above 1, so run loses width slowly near head and quickly at tail, making head
    ##   read as front. Sharper powers put nearly all width in first fifth.
  SPEED_MARKER_PULSE* = 60.0
    ## Carry pulse along its outline at this many pixels per second.
    ##   Speed, not lap time: one lap per fixed time makes how fast mark *moves* property
    ##   of outline, drift on one shape and scurry on another.
    ##   Sixty is speed lap was chosen at over 300 px specimens.
    ##     Slow enough to read as circulation rather than spinner; *direction* is whole
    ##     message.
  ANGLE_MARKER_BANDS_OPEN* = 0.5*PI
    ## Start horizon line's bands this far off it, in radians, at zero progress.
    ##   Quarter turn is pole of sphere line's great circle runs around, reliably outside
    ##   any field of view.
    ##   Bands are single points there and open into rings as they close, reading as
    ##   arriving from outside: horizon line has no support to grow from.

static:
  doAssert GAP_MARKER > 0, &"Marker clearance must be positive; got `{GAP_MARKER}`."
  doAssert WIDTH_MARKER < WIDTH_LINE_OBJECT,
    &"A marker must draw thinner than the line it marks; got `{WIDTH_MARKER}` >= " &
    &"`{WIDTH_LINE_OBJECT}`."
  doAssert ALPHA_MARKER_HOVER < ALPHA_MARKER_SELECTED,
    &"Hover must read fainter than a selection; got `{ALPHA_MARKER_HOVER}` >= " &
    &"`{ALPHA_MARKER_SELECTED}`."
  doAssert SEGMENTS_MARKER_LOOP >= 12,
    &"A plane's marker needs 12 segments to read as a circle; got " &
    &"`{SEGMENTS_MARKER_LOOP}`."
  doAssert SEGMENTS_MARKER_FRAME mod 4 == 0,
    &"A frame's steps must land on the four edge midpoints; got " &
    &"`{SEGMENTS_MARKER_FRAME}`."
  doAssert POINTS_MARKER_BAND <= SEGMENTS_MARKER_OUTLINE,
    &"A pulse must fit every outline it rides; bands are `{POINTS_MARKER_BAND}` against " &
    &"`{SEGMENTS_MARKER_OUTLINE}`."
  doAssert FRACTION_MARKER_PULSE < 0.5,
    &"A pulse covering half its outline states no direction; got " &
    &"`{FRACTION_MARKER_PULSE}`."



#[ Type Definitions ]#

type
  MarkerKind* {.pure.} = enum ## Define which outline marker is drawn as.
    Ring, ## Circle in screen space, for point.
    Rails, ## Pair of world-space lines flanking line, converging as it does.
    Loop, ## Polyline lying on plane in world space, projected, for plane.
    Bands, ## Pair of circles on sky flanking horizon line's great circle.
    Frame, ## Boundary around whole viewport, for whole sky horizon plane is.
      ## Circle while it expands, viewport's rectangle once it arrives.

  Marker* = object ## Define one object's marker, ready to draw on foreground layer.
    anchors_pulse*: array[RUNS_MARKER_PULSE, ScreenPosition] ## Where each run below
      ## measured its travel from, in screen space.
      ## Reported as `lap` is: fact about marker only shaping knew, and one deciding
      ## whether comet holds still under moving camera.
      ##   Unasserted from outside is how sliding comet shipped twice.
    lap*: float ## Distance pulse travels before it is back where it began, in pixels.
      ## 0 where nothing pulses.
      ## Not length of outline: rail's drawn length is viewport-clip artefact, and line's
      ## two rails are clipped hundreds to one apart.
      ##   This is stretch both lap against, shorter one, which lets
      ##   `selection.PulseClock` reduce travel it cannot measure itself.
    count_run_pulse*: int ## Runs used of `pulses` below; 0 where nothing pulses.
    counts_pulse*: array[RUNS_MARKER_PULSE, int] ## Outline points used of each run.
    has_label*: bool ## Whether `label_at` holds place for object's name.
      ## False where outline has no top to sit above: rails with both supports cut away.
    label_at*: ScreenPosition ## Where name label is centred, in screen space.
      ## `GAP_MARKER` plus half `HEIGHT_MARKER_LABEL` above outline's top at object's own
      ## place: ring's top, loop's true top on disc's column, bands' highest point. Frame
      ## is whole view, so its label sits just inside top edge instead.
      ## Rails: anchor *on* line instead, with label pushed off it; see `is_label_beside`.
      ## Decided here with rest of marker so both front-ends agree by construction; each
      ## centres its own text on it.
    is_label_beside*: bool ## Whether `label_at` is anchor on outline, label pushed off it.
      ## Rails: `label_at` lies on line at its support, clamped into view, and front-end
      ## sets centre `clearanceBeside` along `label_away_x`/`label_away_y`, measured with
      ## its own text box. False elsewhere: `label_at` is centre itself.
    label_away_x*, label_away_y*: float ## Unit direction label is pushed along, on screen.
      ## Line's own left, from its direction as projected: side fixed by geometry, not by
      ## screen, which is what makes it continuous through every turn; see
      ## `placeLabelBesideLine`.
    pulses*: array[
      RUNS_MARKER_PULSE, array[POINTS_MARKER_PULSE, ScreenPosition]
    ] ## Short runs travelling along marker's outline, in screen space.
      ## Render paths *fill* them over outline.
      ## Which way they travel is object's orientation: what plane's normal shaft used
      ## to say, said only about object asked about.
      ## Each run is one closed outline, not spine: run tapers, and stroke carries one
      ## width.
      ##   Shaped here because ribbon worked out twice drifts, and neither Dear ImGui nor
      ##   SVG offers varying-width stroke.
      ## Points rather than index span into outline, because `Rails` is segments while
      ## `Loop`, `Bands` and `Frame` are polylines.
      ## Common to every kind: what pulses varies, that marker may pulse does not.
    case kind*: MarkerKind
    of MarkerKind.Ring:
      centre*: ScreenPosition ## Where point itself projects.
      radius*: float ## Ring radius, in pixels.
      fraction*: float ## How much of circle to stroke, clockwise from twelve, in 0 .. 1.
        ## Whole ring at 1; less only while hold is filling it.
        ## Clockwise from top because that is how every other progress dial is drawn.
    of MarkerKind.Rails:
      count_segment*: int ## Segments used of `segments` below.
      segments*: array[SEGMENTS_MARKER_RAILS, array[2, ScreenPosition]]
        ## Hold endpoints of each drawn piece.
        ##   One rail each side, each in up to two halves line itself is drawn as.
        ##   Fewer where half was clipped away.
    of MarkerKind.Loop:
      count_point*: int ## Points used of `points` below.
      is_closed*: bool ## Whether last point joins back to first.
        ## False where part of circle fell behind eye and was cut away; closed loop drawn
        ## through cut would run straight across view.
      points*: array[SEGMENTS_MARKER_LOOP, ScreenPosition]
        ## Hold circle's points, in order around plane, already projected.
    of MarkerKind.Bands:
      counts_band*: array[2, int] ## Points used of each band below.
      are_closed_band*: array[2, bool] ## Whether each band joins back to own first point.
        ## False where eye or edge of view cut it into arc: `Loop`'s rule, one cut further.
      points_band*: array[2, array[POINTS_MARKER_BAND, ScreenPosition]]
        ## Hold each band's points, in order around sky, projected.
        ##   Only stretch inside viewport.
    of MarkerKind.Frame:
      count_frame*: int ## Points used of `points_frame` below.
      points_frame*: array[
        SEGMENTS_MARKER_FRAME + CORNERS_MARKER_FRAME, ScreenPosition
      ] ## Boundary's points, in order around centre of view.
        ## Screen space throughout: sky has no place in scene to surround, so marker
        ## surrounds view. Always closed.



#[ Orientation Pulse ]#

func lengthOfOutline*(
  points: openArray[ScreenPosition], count: int, is_closed: bool
): float =
  ## Measure outline right round, in screen pixels.
  ##   Primitive `trackAlong` is built from, and what caller needs for how far pulse may
  ##   run before it laps.
  ##   `samplePulse` walks same points again for its own table, price of lap being
  ##   caller's to say, or line's two rails would keep own clocks.
  if count < 2: return
  let last = if is_closed: count else: count - 1
  for i in 0 ..< last:
    let after = points[(i + 1) mod count]
    result += hypot(after.x - points[i].x, after.y - points[i].y)


type PulseTrack* = object ## Define where pulse's travel is measured from along outline.
  ## Also how far it may run either way before it laps.
  ## `origin` names view-independent feature of object (line's support, circle's angle
  ## zero) rather than whichever point was emitted first.
  ##   Outline's first point is cut: rail's is where it crosses window edge, cut ring's
  ##   wherever eye plane sliced it.
  ##   Measuring from cut lets camera decide where comet is, fault this type removes.
  origin*: int ## Index of point travel is measured from.
  behind*: float ## Outline available before that point, in pixels.
  ahead*: float ## Outline available after it, in pixels.


func lap*(track: PulseTrack): float = track.behind + track.ahead
  ## Report distance after which pulse on this track is back where it started.


func trackAlong*(
  points: openArray[ScreenPosition], count: int, is_closed: bool, origin: int = 0
): PulseTrack =
  ## Measure outline either side of point travel is anchored at, in screen pixels.
  ##   Closed outline laps on itself, so all of it lies `ahead` and origin decides only
  ##   where lap zero begins; open one is cut arc with genuine before and after.
  if count < 2 or origin < 0 or origin >= count: return
  result.origin = origin
  if is_closed:
    result.ahead = lengthOfOutline(points, count, true)
    return
  for i in 0 ..< count - 1:
    let step = hypot(points[i + 1].x - points[i].x, points[i + 1].y - points[i].y)
    if i < origin: result.behind += step else: result.ahead += step


func originAfterCut*(count_ring, start, count_emitted: int; count_before: int = 0): int =
  ## Say where ring's angle-zero point sits in arc that survived cut.
  ##   Cut ring is emitted from `start`, first point whose predecessor was cut, so
  ##   emitted index zero is wherever eye sliced it: camera's answer.
  ##   Angle zero is generated from object's own frame and is anchor pulse measures from,
  ##   so this walks it back.
  ##   Falls back to arc's start where angle zero is itself behind eye, one case with no
  ##   view-independent point left on screen.
  ##     Comet is anchored to cut for as long as that lasts.
  ##   `count_before` counts points placed ahead of surviving samples (band's crossing
  ##   point at edge it enters through), shifting every sample along without being
  ##   samples. `count_emitted` stays count of samples.
  if count_ring <= 0 or count_emitted <= 0: return
  result = (count_ring - start) mod count_ring
  if result >= count_emitted: return 0
  result += count_before


func shared*(track: PulseTrack; behind, ahead: float): PulseTrack =
  ## Put track on extents shared with another piece of same marker.
  ##   Line's two rails are clipped to window on own, lengths differing hundreds to one;
  ##   lapping each against own puts two heads at different places, so both take one
  ##   reach.
  ##   Shorter of two, so neither rail is asked for outline it lacks.
  ##     Longer, on theory that rail near edge shrinks shared lap, measured as changing
  ##     nothing over four orbit rates.
  PulseTrack(
    origin: track.origin,
    behind: min(track.behind, behind),
    ahead: min(track.ahead, ahead),
  )


func travelAdvanced*(travelled, lap, seconds: float): float =
  ## Carry pulse's travel forward by `seconds`, reduced into lap `lap` pixels long.
  ##   Advance, not position, and step in pixels rather than laps.
  ##     Position read off clock, `frac(now·speed ÷ around)`, is thrown most of lap by
  ##     one-percent change in outline length while orbiting.
  ##     Carried *fraction* still had to be multiplied by view-dependent length, sliding
  ##     head again.
  ##     `seconds*SPEED_MARKER_PULSE` mentions no camera quantity, so screen pace is exact.
  ##   Reducing every step keeps this from being first fault again.
  ##     Unbounded travel modulo lap amplifies change in lap by laps gone by; travel
  ##     below one lap by one.
  ##   Unchanged for outline of no length. `selection.PulseClock` owns travel this
  ##   returns.
  if lap <= 0.0: return travelled
  let carried = travelled + seconds*SPEED_MARKER_PULSE
  carried - floor(carried/lap)*lap


func ribbonAlong(
  spine: openArray[ScreenPosition]; count: int; width_head, width_tail: float;
  outline: var openArray[ScreenPosition]
): int =
  ## Wrap `count` points of run's spine in one closed outline; report points filled.
  ##   Tapers from `width_head` at `spine[0]` to `width_tail` at last point.
  ##   Ribbon rather than stroke because width changes along run, and no stroke either
  ##   render path offers does that.
  ##   Taper is spread over whatever length run came out at, so run cut short is shorter
  ##   comet rather than front half of one.
  ##   Each point's normal comes from own neighbours on spine, not second sample guessed
  ##   step away, which at either end falls off run.
  if count < 2 or outline.len < 2*count + SEGMENTS_MARKER_CAP: return
  var
    normal_x = 0.0
    normal_y = 0.0
  for i in 0 ..< count:
    let
      before = spine[max(0, i - 1)]
      after = spine[min(count - 1, i + 1)]
      dx = after.x - before.x
      dy = after.y - before.y
      span = hypot(dx, dy)
    if span > 0.0:
      normal_x = -dy/span
      normal_y = dx/span
    let
      falling = pow(1.0 - float(i)/float(count - 1), FALLOFF_MARKER_COMET)
      half = 0.5*(width_tail + (width_head - width_tail)*falling)
    # Fill both sides at once, far one from back.
    #   Outline then closes as one loop rather than crossing itself at tail.
    outline[i] = ScreenPosition(
      x: spine[i].x + normal_x*half,
      y: spine[i].y + normal_y*half,
      depth: spine[i].depth,
    )
    outline[2*count - 1 - i] = ScreenPosition(
      x: spine[i].x - normal_x*half,
      y: spine[i].y - normal_y*half,
      depth: spine[i].depth,
    )
  result = 2*count

  # Round head, sweeping from far side through straight ahead to near one.
  let
    dx = spine[0].x - spine[1].x
    dy = spine[0].y - spine[1].y
    ahead = hypot(dx, dy)
  var
    forward_x = 0.0
    forward_y = 0.0
  if ahead > 0.0:
    forward_x = dx/ahead
    forward_y = dy/ahead
  let half_head = 0.5*width_head
  # Recover head normal from outline's first point rather than variable kept across walk.
  let
    head_x = (outline[0].x - spine[0].x)/half_head
    head_y = (outline[0].y - spine[0].y)/half_head
  for j in 1 .. SEGMENTS_MARKER_CAP:
    let
      turn = PI*float(j)/float(SEGMENTS_MARKER_CAP + 1)
      swing_x = -head_x*cos(turn) + forward_x*sin(turn)
      swing_y = -head_y*cos(turn) + forward_y*sin(turn)
    outline[result] = ScreenPosition(
      x: spine[0].x + swing_x*half_head,
      y: spine[0].y + swing_y*half_head,
      depth: spine[0].depth,
    )
    inc result


func samplePulse(
  points: openArray[ScreenPosition], count: int, is_closed: bool, track: PulseTrack,
  travelled: float, run: var array[SEGMENTS_MARKER_PULSE, ScreenPosition]
): int =
  ## Lay pulse along `count` points of outline; report how many of `run` were used.
  ##   `travelled` pixels from `track`'s anchor.
  ##   Walks stored order, whole mechanism.
  ##     Plane's loop is generated around own frame, so *projection decides* whether
  ##     order comes out clockwise on screen, and pulse reverses of own accord as camera
  ##     crosses plane. Nothing here computes sense.
  ##   Run trails *behind* leading point, so outline it just covered is lit: head with
  ##   tail reads as travel, even band as gap.
  ##   Measured from `track.origin`, not outline's first point; see `PulseTrack`.
  ##   Head wraps and tail clamps.
  ##     Wrapping tail too puts spine points at both ends of open arc, and `ribbonAlong`
  ##     joins consecutive points, drawing chord across view.
  ##     Clamping shortens run to nothing as head crosses wrap and grows it back, reading
  ##     as comet leaving one edge and re-entering at other.
  ##   Reports 0 where too little survives to draw.
  ##   Walked by pixels along outline, not by index: stepping by index makes run's length
  ##   share of outline, stretched wherever perspective bunches points.
  if count < 2 or count > SEGMENTS_MARKER_OUTLINE: return

  # Tabulate where each segment starts, measured along outline, whole length last.
  var starts: array[SEGMENTS_MARKER_OUTLINE + 1, float]
  let last = if is_closed: count else: count - 1
  for i in 0 ..< last:
    let after = points[(i + 1) mod count]
    starts[i + 1] = starts[i] + hypot(after.x - points[i].x, after.y - points[i].y)
  let total = starts[last]
  if total <= 0.0: return

  # Size run against track's stretch, not whole outline.
  #   Ring eye has cut carries near-plane segment of enormous projected length.
  let window = track.lap
  if window <= 0.0 or track.origin < 0 or track.origin >= count: return
  let
    reach = min(LENGTH_MARKER_COMET, FRACTION_MARKER_PULSE*window)
    begin = starts[track.origin] - track.behind
    carried = travelled + track.behind
    head = begin + (carried - floor(carried/window)*window)
  for i in 0 ..< SEGMENTS_MARKER_PULSE:
    var along = head - reach*(float(i)/float(SEGMENTS_MARKER_PULSE - 1))
    if is_closed: along = along - floor(along/total)*total
    # Stop at first sample off run: `along` only decreases.
    elif along < begin or along > total: break
    var segment = last - 1
    for j in 0 ..< last:
      if along < starts[j + 1]:
        segment = j
        break
    let width = starts[segment + 1] - starts[segment]
    run[result] = points[segment].towards(
      points[(segment + 1) mod count], (if width > 0.0: (along - starts[segment])/width else: 0.0)
    )
    inc result
  if result < 2: result = 0 # Too little left of it to read as anything.


func addPulse(
  marker: var Marker, points: openArray[ScreenPosition], count: int, is_closed: bool,
  track: PulseTrack, travelled: float
) =
  ## Add one run of pulse to `marker`, taken along `count` points of one outline.
  ##   Silently adds nothing where run came out too short or marker holds every run it
  ##   has room for: no more to say here, not failures.
  if marker.count_run_pulse >= RUNS_MARKER_PULSE: return
  var spine: array[SEGMENTS_MARKER_PULSE, ScreenPosition]
  let sampled = samplePulse(points, count, is_closed, track, travelled, spine)
  if sampled == 0: return
  let used = ribbonAlong(
    spine, sampled, float(WIDTH_MARKER_COMET), float(WIDTH_MARKER),
    marker.pulses[marker.count_run_pulse],
  )
  if used == 0: return
  marker.anchors_pulse[marker.count_run_pulse] = points[track.origin]
  marker.counts_pulse[marker.count_run_pulse] = used
  inc marker.count_run_pulse



#[ Drag Comet ]#

func cometFor*(
  tail, head: ScreenPosition
): Option[array[POINTS_MARKER_PULSE, ScreenPosition]] =
  ## Kind head of drag band running `tail` -> `head` as closed outline, in pixels.
  ##   Render path fills it over band.
  ##   Drag is not symmetric: `a ∨ b` and `b ∨ a` differ, and bare line draws
  ##   identically for either. Head says which way round pair is taken, at end where
  ##   answer lands.
  ##   Band swelling into own last stretch, same shape orientation pulse wears through
  ##   same `ribbonAlong`, so reader meets one vocabulary for direction.
  ##   None where two coincide: cursor resting on own source, ordinary moment.
  let
    dx = head.x - tail.x
    dy = head.y - tail.y
    length = hypot(dx, dy)
  if length <= 0.0: return
  # Light all of band shorter than comet, rather than reaching past its source.
  let reach = min(LENGTH_MARKER_COMET, length)
  var spine: array[SEGMENTS_MARKER_PULSE, ScreenPosition]
  for i in 0 ..< SEGMENTS_MARKER_PULSE:
    let back = reach*float(i)/float(SEGMENTS_MARKER_PULSE - 1)
    spine[i] = ScreenPosition(
      x: head.x - dx/length*back,
      y: head.y - dy/length*back,
      depth: head.depth,
    )
  var outline: array[POINTS_MARKER_PULSE, ScreenPosition]
  let used = ribbonAlong(
    spine, SEGMENTS_MARKER_PULSE, float(WIDTH_MARKER_COMET), float(WIDTH_MARKER), outline
  )
  if used == 0: return
  some(outline)



#[ Touch Clearance ]#

func clearanceTouch*(swell: float, is_touch: bool): float =
  ## Measure how far outward to push marker, in pixels, at this much of swell.
  ##   Plain scaling of `CLEARANCE_MARKER_TOUCH`; *shape* of swell is caller's
  ##   (`interaction.swellHold`, four phases).
  ##     Half sine over fill had marker back to true size exactly as selection landed.
  ##   Zero for mouse: cursor hides nothing.
  if not is_touch: return 0.0
  CLEARANCE_MARKER_TOUCH*clamp(swell, 0.0, 1.0)



#[ Point And Line ]#

func placeLabelAbove(marker: var Marker, x, top: float) =
  ## Place name label centred `GAP_MARKER` and half its height above outline's top at `x`.
  marker.has_label = true
  marker.label_at = ScreenPosition(
    x: x, y: top - GAP_MARKER - 0.5*HEIGHT_MARKER_LABEL, depth: 1.0
  )


func clearanceBeside*(away_x, away_y, half_width: float): float =
  ## Measure how far label's centre stands off line along `away`, for label pushed beside.
  ##   Rail, gap, then label's own box's half-extent in that direction: wide name beside
  ##   steep line clears it, where fixed lift put letters across it.
  ##   `half_width` is front-end's measured text, half; height is nominal one shared.
  OFFSET_MARKER_RAIL + GAP_MARKER + abs(away_x)*half_width +
    abs(away_y)*0.5*HEIGHT_MARKER_LABEL


func clipToView(tail, head: ScreenPosition; width, height: int): Option[(float, float)] =
  ## Clip screen segment to viewport, as fractions along it; none where it misses.
  ##   Liang–Barsky, both ends free, where `fractionLeavingView` clips outward from tail
  ##   already inside.
  var (f0, f1) = (0.0, 1.0)
  let (dx, dy) = (head.x - tail.x, head.y - tail.y)
  for (rate, room) in [
    (-dx, tail.x), (dx, float(width) - tail.x), (-dy, tail.y), (dy, float(height) - tail.y)
  ]:
    if rate == 0.0:
      if room < 0.0: return
      continue
    let f = room/rate
    if rate < 0.0:
      if f > f1: return
      if f > f0: f0 = f
    else:
      if f < f0: return
      if f < f1: f1 = f
  some((f0, f1))


func placeLabelBesideLine(
  marker: var Marker; anchor: Position; axis: Direction; scale: DrawExtent;
  view_projection: Matrix4; width, height: int
) =
  ## Place line's label on line at its support, clamped into view, pushed to line's left.
  ##   Left of line's *own* direction, as projected: choice of side on unoriented line
  ##   cannot be continuous (it flips at vertical), and side of oriented one is. Label
  ##   may stand below line after half turn, and never hops.
  ##   Anchor is support's projection while that is in view, `MARGIN_LABEL_VIEW` inside;
  ##   past that it slides along visible stretch, and support behind eye anchors at
  ##   near-plane crossing, nearest visible point to it.
  ##   Both ends of line in front of eye are found as `railsAt` finds rails', through
  ##   `clipToEyeSide`; nothing visible leaves label off.
  ##   Chosen over four others on animated mock-ups: above upper rail hopped at vertical
  ##   and overlapped steep line; upward side sliding through line overlapped at vertical;
  ##   visible midpoint followed viewport rather than line; text along line flipped.
  let
    anchor_point = toMultivector(anchor)
    axis_point = toMultivector(axis)
  var
    ends: array[2, Option[(ScreenPosition, ScreenPosition)]] ## (tail, head) per half.
  for index_half, reach in [-scale.radiusHorizon, scale.radiusHorizon]:
    let clipped = clipToEyeSide(
      anchor, pointFrom(add(scale.eye_point, wedge(reach, axis_point))), scale.plane_near
    )
    if clipped.isNone: continue
    let
      tail = projectToScreen(view_projection, width, height, clipped.get[0])
      head = projectToScreen(view_projection, width, height, clipped.get[1])
    if tail.isInFront and head.isInFront: ends[index_half] = some((tail, head))
  if ends[0].isNone and ends[1].isNone: return
  # Order stretch along `axis`, and note where support, or nearest point to it, falls.
  var (a, b, at_support) = (ScreenPosition(), ScreenPosition(), ScreenPosition())
  if ends[0].isSome and ends[1].isSome:
    (a, b, at_support) = (ends[0].get[1], ends[1].get[1], ends[1].get[0])
  elif ends[1].isSome: (a, b, at_support) = (ends[1].get[0], ends[1].get[1], ends[1].get[0])
  else: (a, b, at_support) = (ends[0].get[1], ends[0].get[0], ends[0].get[0])
  let
    (dx, dy) = (b.x - a.x, b.y - a.y)
    length = sqrt(dx*dx + dy*dy)
  if length < 1.0e-6: return
  let clipped = clipToView(a, b, width, height)
  if clipped.isNone: return
  let
    (f0, f1) = clipped.get
    inset = min(MARGIN_LABEL_VIEW/length, 0.5*(f1 - f0))
    f_support = ((at_support.x - a.x)*dx + (at_support.y - a.y)*dy)/(length*length)
    f = clamp(f_support, f0 + inset, f1 - inset)
  marker.has_label = true
  marker.is_label_beside = true
  marker.label_at = ScreenPosition(x: a.x + f*dx, y: a.y + f*dy, depth: 1.0)
  (marker.label_away_x, marker.label_away_y) = (dy/length, -dx/length)


func placeLabelAboveTopmost(
  marker: var Marker, points: openArray[ScreenPosition], count: int
) =
  ## Place name label centred above highest of `count` outline points, keeping any higher one.
  ##   Called once per run, so bands' two runs settle on higher of their two tops.
  for i in 0 ..< count:
    if not marker.has_label or
        points[i].y < marker.label_at.y + GAP_MARKER + 0.5*HEIGHT_MARKER_LABEL:
      marker.placeLabelAbove(points[i].x, points[i].y)


func topmostOnCircle*(
  centre: Position; arm_first, arm_second: Direction; view_projection: Matrix4;
  width, height: int
): Option[ScreenPosition] =
  ## Solve highest screen point of world circle `centre + cos·arm_first + sin·arm_second`.
  ##   Closed form, so label above plane's circle glides as camera orbits.
  ##     Highest of sampled vertices hopped segment by segment, label with it.
  ##   Clip y and clip w are affine in (cos, sin): `N = a·cos + b·sin + c`,
  ##   `D = d·cos + e·sin + f`. Screen y is monotone in `N/D`, stationary where
  ##   `(b·d - a·e) + (c·d - a·f)·sin + (b·f - c·e)·cos = 0`, i.e. `R·cos + Q·sin = -P`,
  ##   so angle is `atan2(Q, R) ± arccos(-P/√(Q²+R²))`: top and bottom, whichever is in
  ##   front and higher.
  ##   Continuous in camera, so caller's label glides; its height alone is read where
  ##   flip matters, see `markerLoop`.
  ##   None where circle is degenerate on screen (`√(Q²+R²)` vanishing) or neither
  ##   candidate is in front of eye; caller falls back to sampled top.
  template rowDot(row: int, d: Direction): float =
    float(view_projection.at(row, 0))*d.x + float(view_projection.at(row, 1))*d.y +
      float(view_projection.at(row, 2))*d.z
  template rowAt(row: int, p: Position): float =
    float(view_projection.at(row, 0))*p.x + float(view_projection.at(row, 1))*p.y +
      float(view_projection.at(row, 2))*p.z + float(view_projection.at(row, 3))
  let
    (a, b, c) = (rowDot(1, arm_first), rowDot(1, arm_second), rowAt(1, centre))
    (d, e, f) = (rowDot(3, arm_first), rowDot(3, arm_second), rowAt(3, centre))
    (p, q, r) = (b*d - a*e, c*d - a*f, b*f - c*e)
    reach = sqrt(q*q + r*r)
  if reach < 1.0e-12: return
  let
    phase = arctan2(q, r)
    spread = arccos(clamp(-p/reach, -1.0, 1.0))
  for angle in [phase + spread, phase - spread]:
    let at = projectToScreen(
      view_projection, width, height,
      onCircleAt(centre, arm_first, arm_second, cos(angle), sin(angle)),
    )
    if not at.isInFront: continue
    if result.isNone or at.y < result.get.y: result = some(at)


func markerRing(
  geometry: Multivector; radius: float; scale: DrawExtent; view_projection: Matrix4;
  width, height: int; progress, clearance: float; marker: var Marker
): bool =
  ## Build point's ring, about wherever that point is drawn and just outside its disc.
  ##   Fills caller's `marker` and reports whether one was shaped; see `markerFor`.
  ##   Screen-space rather than world circle facing camera: point has no orientation to
  ##   echo, and every facing looks same from one angle it is seen from.
  ##   `radius` is object's drawn radius, in world units; ring sits `GAP_MARKER` outside
  ##   pixels that spans at point's depth, so it hugs sun and dot alike.
  ##   `progress` sweeps ring rather than growing it: ring growing outward reads as point
  ##   swelling, inward collides with it.
  let anchor = anchorFor(geometry, scale)
  if anchor.isNone: return
  let centre = projectToScreen(view_projection, width, height, anchor.get)
  if not centre.isInFront: return
  marker = Marker(
    kind: MarkerKind.Ring,
    centre: centre,
    radius: radiusPixelsAt(radius, anchor.get, scale.scale) + GAP_MARKER + clearance,
    fraction: progress,
  )
  marker.placeLabelAbove(centre.x, centre.y - marker.radius)
  true


func offsetMarkerRail(anchor: Position, scale: DrawExtent, clearance: float = 0.0): float =
  ## Size how far to each side of line its rails stand, in world units.
  ##   *World* offset, so rails are lines genuinely parallel to one they flank, sharing
  ##   its vanishing points, each one straight line.
  ##     Screen offset bought flat gap at price of bend where rail's halves met; see
  ##     `markerRails`.
  ##   Reads as `OFFSET_MARKER_RAIL` pixels at support and less further off; caller does
  ##   not take figure as final, see `apartWidest`.
  ##   `clearance` widens pair by that many further pixels, for touch hold.
  (OFFSET_MARKER_RAIL + clearance)*worldPerPixelAt(anchor, scale)


func directionAcross(geometry: Multivector, eye: Position): Option[Direction] =
  ## Resolve which way to step off line so rails land either side on screen.
  ##   Join of line with eye is one plane containing both; its normal is perpendicular to
  ##   line and to every sight ray reaching it, direction that shows as sideways.
  ##   Perpendicular to sight ray reaching line rather than camera's axis, so rails
  ##   straddle plane line's projection is, symmetric from any angle.
  ##     Cost is step tilting hair out of plane perspective divides by, under pixel.
  ##   None where eye lies on line itself, edge-on with no side to flank.
  directionNormal(geometry ∧ toMultivector(eye))


func awayFromScreen*(point, first, second: ScreenPosition): float =
  ## Measure perpendicular distance from screen point to infinite line through two others.
  ##   Gap at that point, when two others are line's projection: straight world line
  ##   projects to straight screen line.
  ##   Never distance between two rails' drawn endpoints: `fractionLeavingView` cuts each
  ##   at own fraction, so those measure nothing.
  let (dx, dy) = (second.x - first.x, second.y - first.y)
  let length = hypot(dx, dy)
  if length <= 0.0: return hypot(point.x - first.x, point.y - first.y)
  abs((point.x - first.x)*dy - (point.y - first.y)*dx)/length


func fractionLeavingView*(tail, head: ScreenPosition; width, height: int): float =
  ## Say how far along `tail` -> `head` segment is still inside viewport, in 0 .. 1.
  ##   Takes 1 where it ends inside.
  ##   What growing marker measures itself against.
  ##     Rail runs to vanishing point, not useful screen distance: one half's projected
  ##     length can be hundreds of times other's, so growing each by fraction of own
  ##     length finished one far sooner and put both off screen in first percent.
  ##     Bounding reach at edge makes halves comparable and whole growth visible.
  ##   Zero where segment heads away from viewport it already left.
  result = 1.0
  let (dx, dy) = (head.x - tail.x, head.y - tail.y)
  # Bound parameter at each edge only where segment crosses it *outward*.
  template limit(rate, room: float) =
    if rate > 0.0: result = min(result, room/rate)
  limit(-dx, tail.x)
  limit(dx, float(width) - tail.x)
  limit(-dy, tail.y)
  limit(dy, float(height) - tail.y)
  result = max(result, 0.0)


func isWithinView*(point: ScreenPosition; width, height: int): bool =
  ## Say whether projected point stands inside viewport it was projected for.
  ##   In front of eye as well as within bounds: point behind eye projects through
  ##   negative divide, and where it lands says nothing about where it would be seen.
  ##   Bounds closed, matching `fractionLeavingView`.
  point.isInFront and
    point.x >= 0.0 and point.x <= float(width) and
    point.y >= 0.0 and point.y <= float(height)


func railsAt(
  anchor: Position; axis, across: Direction; offset: float; scale: DrawExtent;
  view_projection: Matrix4; width, height: int;
  progress: float; marker: var Marker;
  walks: var array[2, array[3, Option[ScreenPosition]]]
) =
  ## Lay both rails out at one world offset.
  ##   Drawn screen segments, and walk each rail is read along for its pulse.
  ##   Own routine because `markerRails` runs it twice: once to find how wide pair comes
  ##   out on screen, once at offset that answer asks for.
  ##   Each rail is one straight world line: halves start from same offset support and
  ##   run to two vanishing points, meeting at no angle.
  marker.count_segment = 0
  walks = default(array[2, array[3, Option[ScreenPosition]]])
  # Hoist rail frame: anchor point, across arm and axis arm as multivectors, once per call.
  let
    anchor_point = toMultivector(anchor)
    across_point = toMultivector(across)
    axis_point = toMultivector(axis)
  for index_side, side in [offset, -offset]:
    let rail_base = pointFrom(add(anchor_point, wedge(side, across_point)))
    for index_half, reach in [scale.radiusHorizon, -scale.radiusHorizon]:
      let clipped = clipToEyeSide(
        rail_base, pointFrom(add(scale.eye_point, wedge(reach, axis_point))),
        scale.plane_near,
      )
      if clipped.isNone: continue
      let (position_tail, position_head) = clipped.get
      let
        tail = projectToScreen(view_projection, width, height, position_tail)
        head = projectToScreen(view_projection, width, height, position_head)
      if not (tail.isInFront and head.isInFront): continue
      let drawn =
        [tail, tail.towards(head, progress*fractionLeavingView(tail, head, width, height))]
      marker.segments[marker.count_segment] = drawn
      inc marker.count_segment
      # Order along line: `-axis` end, support, then `+axis` end.
      walks[index_side][1] = some(drawn[0]) # Same point for either half.
      walks[index_side][if index_half == 0: 2 else: 0] = some(drawn[1])


func apartWidest(walks: array[2, array[3, Option[ScreenPosition]]]): float =
  ## Report widest pair reads apart anywhere reader can see it, in pixels.
  ##   One rail against other, gap reader sees, rather than either against line between.
  ##     All three meet at same vanishing point, so measures differ by few percent where
  ##     they converge hardest.
  ##   Each rail's drawn points against infinite line through other's.
  ##     Distance between two straight screen lines is linear along either, so its
  ##     greatest value over drawn stretch is at one of that stretch's ends.
  var
    points: array[2, array[3, ScreenPosition]]
    counts: array[2, int]
  for side in 0 .. 1:
    for at in walks[side]:
      if at.isNone: continue
      points[side][counts[side]] = at.get
      inc counts[side]
  if counts[0] < 2 or counts[1] < 2: return
  for side in 0 .. 1:
    let other = 1 - side
    for i in 0 ..< counts[side]:
      result = max(result, awayFromScreen(
        points[side][i], points[other][0], points[other][counts[other] - 1],
      ))


func markerRails(
  geometry: Multivector; scale: DrawExtent;
  view_projection: Matrix4; width, height: int; progress, clearance: float;
  travel: Option[float]; marker: var Marker
): bool =
  ## Build line's pair of rails: two straight screen lines flanking it.
  ##   Hold `OFFSET_MARKER_RAIL` pixels of clear space and close only on vanishing point
  ##   reader can see.
  ##   Offset in screen pixels, not world units.
  ##     World offset hands *rate* of convergence to perspective, stretching it to
  ##     nothing at one end and flaring at other; see `OFFSET_MARKER_RAIL`.
  ##     Gap is stated in units it is read in.
  ##   Still meets vanishing point, where there is one.
  ##     Each half runs to `eye ± radius_horizon*axis`, and exactly one lies in front of
  ##     eye unless line is square on.
  ##     Half that has one sheds offset at head; half whose head is near-plane cut stays
  ##     dead parallel. Line square on stays parallel both ways: no visible vanishing
  ##     point.
  ##   `progress` runs both rails out from support toward each horizon, measured against
  ##   edge of view; see `fractionLeavingView`.
  ##     Shortened *after* projection, along screen segment, since scaling world reach
  ##     walks head back to camera.
  ##   `travel` places one pulse along each rail, in line's direction.
  ##     Each rail is *drawn* as two halves but *walked* as one path from far horizon
  ##     through support to near one, so line wears one comet rather than four.
  ##     Measured from support, lapped against shorter rail, so camera restretching
  ##     rails does not move comet, and pair cannot drift apart. None leaves rails still.
  ##   None at horizon, and none where line collapses to point on screen.
  let
    anchor = positionAnchor(geometry)
    axis = direction(geometry)
    across = directionAcross(geometry, scale.eye)
  if anchor.isNone or axis.isNone or across.isNone: return

  marker = Marker(kind: MarkerKind.Rails)
  var
    walks: array[2, array[3, Option[ScreenPosition]]]
    rails: array[2, array[3, ScreenPosition]] ## Each side compacted to what survived.
    counts: array[2, int] ## How many of each side's three points that was.
    origins: array[2, int] ## Where support landed in each, for pulse to measure on.
    tracks: array[2, PulseTrack] ## Each side's reach either way from that support.
  let offset_stated = offsetMarkerRail(anchor.get, scale, clearance)
  # Settle against finished rail, then draw at progress asked for.
  #   Settling against partial rail made gap widen as hold filled, pair breathing
  #   sideways.
  railsAt(
    anchor.get, axis.get, across.get, offset_stated, scale,
    view_projection, width, height, 1.0, marker, walks,
  )
  if marker.count_segment == 0: return

  # Size by widest pair reads, not gap at support.
  #   Stated figure becomes ceiling, and offset is scaled until widest reading meets it.
  #   Only ever narrows, with no floor under narrowing: floor let splay through, and
  #   ceiling on *widest* reading is itself guarantee of visibility.
  #   Settled over passes because narrowing moves where rail leaves viewport; see
  #   `PASSES_MARKER_RAIL`.
  let ceiling = 2.0*(OFFSET_MARKER_RAIL + clearance)
  var offset = offset_stated
  for _ in 0 ..< PASSES_MARKER_RAIL:
    let widest = apartWidest(walks)
    if widest <= ceiling: break
    offset = offset*ceiling/widest
    railsAt(
      anchor.get, axis.get, across.get, offset, scale,
      view_projection, width, height, 1.0, marker, walks,
    )
    if marker.count_segment == 0: return

  if progress < 1.0:
    railsAt(
      anchor.get, axis.get, across.get, offset, scale,
      view_projection, width, height, progress, marker, walks,
    )
    if marker.count_segment == 0: return

  for index_side in 0 .. 1:
    let (end_before, support, end_after) =
      (walks[index_side][0], walks[index_side][1], walks[index_side][2])
    # Walk rail as one path ordered along line, from `-axis` end through support to `+axis`.
    #   Either end may be clipped away.
    #   Support's position is recorded by place in source triple, never by comparing
    #   points, since two can coincide.
    for index_source, point in [end_before, support, end_after]:
      if point.isNone: continue
      if index_source == 1: origins[index_side] = counts[index_side]
      rails[index_side][counts[index_side]] = point.get
      inc counts[index_side]
    if counts[index_side] >= 2:
      tracks[index_side] = trackAlong(
        rails[index_side], counts[index_side], is_closed = false, origins[index_side]
      )

  # Label beside line on its own left, anchored at support clamped into view.
  marker.placeLabelBesideLine(
    anchor.get, axis.get, scale, view_projection, width, height
  )

  if travel.isSome:
    # Lap both rails against one shared reach either way; see `shared`.
    var (behind, ahead) = (Inf, Inf)
    for index_side in 0 .. 1:
      if counts[index_side] < 2: continue
      behind = min(behind, tracks[index_side].behind)
      ahead = min(ahead, tracks[index_side].ahead)
    if behind < Inf and ahead < Inf:
      marker.lap = behind + ahead
      for index_side in 0 .. 1:
        if counts[index_side] < 2: continue
        marker.addPulse(
          rails[index_side], counts[index_side], is_closed = false,
          tracks[index_side].shared(behind, ahead), travel.get,
        )
  true



#[ Plane ]#

func radiusMarkerLoop*(
  centre: Position, scale: DrawExtent, placement: Camera, height: int,
  clearance: float = 0.0
): float =
  ## Size plane's marker circle so gap reads as `GAP_MARKER` pixels at disc's depth.
  ##   Circle lies on plane, so clearance is world distance worth one pixel count at one
  ##   depth, disc's centre.
  ##     Elsewhere gap foreshortens as disc does; constant pixel ring would sit off plane
  ##     and read as floating.
  ##   `clearance` widens gap through same conversion, so swollen circle still lies on
  ##   plane.
  EXTENT_PLANE_F + (GAP_MARKER + clearance)*worldPerPixelAt(centre, scale)


let
  UNIT_RING_LOOP* = unitRing[SEGMENTS_MARKER_LOOP](SEGMENTS_MARKER_LOOP)
    ## Hold plane's marker circle's fixed ring of angles, from `euclid.unitRing`.
    ##   No entry past wrap: marker's outline closes on own first point rather than
    ##   emitting last segment.
  UNIT_RING_BANDS* = unitRing[SEGMENTS_MARKER_BANDS](SEGMENTS_MARKER_BANDS)
    ## Hold horizon line's marker bands' ring, by same rule.


proc positionsMarkerLoop*(
  centre: Position, axes: FramePlane, radius: float
): array[SEGMENTS_MARKER_LOOP, Position] =
  ## Trace plane's marker circle in world space, in order around it.
  ##   Every point is `centre` plus combination of two axes spanning plane, so whole
  ##   circle lies *on* plane by construction. Asserted in suite, point by point.
  # Hoist circle's frame once, then step off fixed table.
  #   Arithmetic, as disc rim it is concentric with; suite holds this equal to
  #   multivector sums it replaced.
  let
    arm_first = radius*axes.axis_first
    arm_second = radius*axes.axis_second
  for i in 0 ..< SEGMENTS_MARKER_LOOP:
    result[i] = onCircleAt(
      centre, arm_first, arm_second,
      UNIT_RING_LOOP[i].cos_angle, UNIT_RING_LOOP[i].sin_angle,
    )


proc markerLoop(
  geometry: Multivector; anchor_override: Option[Position]; scale: DrawExtent;
  placement: Camera; view_projection: Matrix4; width, height: int;
  progress, clearance: float; travel: Option[float]; marker: var Marker
): bool =
  ## Build plane's marker circle, concentric with disc actually drawn.
  ##   Reads `anchor_override` as `tessellate.addPlane` does, so marker is concentric
  ##   with drawn disc rather than plane's support.
  ##   Cuts circle to what stays in front of eye and reports remainder as arc.
  ##     Camera close to large plane puts part of rim behind eye, exactly when selection
  ##     needs saying.
  ##   `progress` scales circle's radius, in world units on plane, so filling hold opens
  ##   it outward from disc's centre while every intermediate circle lies on plane.
  ##   `travel` places pulse round circle, anticlockwise on screen exactly when plane's
  ##   normal points at eye.
  ##     Points are generated around plane's frame, and projection answers which way
  ##     that order reads. None leaves circle still.
  ##   None at horizon, where plane draws as dome fixed to eye.
  let
    anchor = if anchor_override.isSome: anchor_override else: positionAnchor(geometry)
    axes = frame(geometry)
  if anchor.isNone or axes.isNone: return

  let radius_loop = progress*radiusMarkerLoop(anchor.get, scale, placement, height, clearance)
  let positions = positionsMarkerLoop(anchor.get, axes.get, radius_loop)
  var
    ring: array[SEGMENTS_MARKER_LOOP, ScreenPosition]
    are_in_front: array[SEGMENTS_MARKER_LOOP, bool]
    count_in_front = 0
  for i in 0 ..< SEGMENTS_MARKER_LOOP:
    ring[i] = projectToScreen(view_projection, width, height, positions[i])
    are_in_front[i] = ring[i].isInFront
    if are_in_front[i]: inc count_in_front
  if count_in_front == 0: return

  marker = Marker(
    kind: MarkerKind.Loop,
    is_closed: count_in_front == SEGMENTS_MARKER_LOOP,
  )
  # Start arc at first point whose predecessor was cut.
  #   Surviving run is then emitted unbroken instead of wrapping cut and drawing chord
  #   across view.
  var start = 0
  if not marker.is_closed:
    for i in 0 ..< SEGMENTS_MARKER_LOOP:
      let before = (i + SEGMENTS_MARKER_LOOP - 1) mod SEGMENTS_MARKER_LOOP
      if are_in_front[i] and not are_in_front[before]:
        start = i
        break
  for step in 0 ..< SEGMENTS_MARKER_LOOP:
    let i = (start + step) mod SEGMENTS_MARKER_LOOP
    if not are_in_front[i]: break
    marker.points[marker.count_point] = ring[i]
    inc marker.count_point
  # Place label on disc centre's column, at height of circle's true top.
  #   Both continuous in camera, so label glides, and passes flip unseen: far rim's top
  #   and near rim's top part in x for disc off sight axis, centre's column does not.
  #   Sampled top only where true top is cut away.
  let
    top = topmostOnCircle(
      anchor.get, radius_loop*axes.get.axis_first, radius_loop*axes.get.axis_second,
      view_projection, width, height,
    )
    centre = projectToScreen(view_projection, width, height, anchor.get)
  if top.isSome and centre.isInFront: marker.placeLabelAbove(centre.x, top.get.y)
  else: marker.placeLabelAboveTopmost(marker.points, marker.count_point)
  if travel.isSome:
    # Anchor at circle's angle zero, walked back through cut; see `originAfterCut`.
    let track = trackAlong(
      marker.points, marker.count_point, marker.is_closed,
      originAfterCut(SEGMENTS_MARKER_LOOP, start, marker.count_point),
    )
    marker.lap = track.lap
    marker.addPulse(
      marker.points, marker.count_point, marker.is_closed, track, travel.get
    )
  true



#[ Horizon ]#

func angleMarkerBands*(scale: DrawExtent; progress, clearance: float): float =
  ## Size how far off horizon line its two bands stand, in radians, at this progress.
  ##   Closes from `ANGLE_MARKER_BANDS_OPEN` (pole of sky, outside any view) in to
  ##   separation reading as `OFFSET_MARKER_RAIL` pixels, gap *finite* line's rails keep.
  ##     Two kinds of line wear same marker; only arrival differs.
  ##   Angle rather than screen offset because horizon geometry is placed by direction:
  ##   `radiansPerPixel` converts pixel gap, holding under any camera.
  let angle_closed = (OFFSET_MARKER_RAIL + clearance)*radiansPerPixel(scale)
  angle_closed + (1.0 - clamp(progress, 0.0, 1.0))*(ANGLE_MARKER_BANDS_OPEN - angle_closed)


func runShownLongest*(
  ring: openArray[ScreenPosition], are_shown: openArray[bool]
): (int, int) =
  ## Find longest unbroken stretch of sampled ring that is shown.
  ##   As index it starts at and how many samples it runs for.
  ##   Cyclic, so stretch straddling sample zero counts as one.
  ##   Longest, not first: ring can cross viewport more than once (band seen nearly end
  ##   on enters and leaves screen twice), and one outline per band is what
  ##   `points_band` holds.
  ##   Longest in screen pixels, not samples: samples are even in angle and wildly
  ##   uneven projected, tiny across middle against enormous near vanishing point.
  ##   `(0, 0)` where nothing is shown, whole ring where all of it is.
  let count = are_shown.len
  var count_shown = 0
  for shown in are_shown:
    if shown: inc count_shown
  if count_shown == 0: return (0, 0)
  if count_shown == count: return (0, count)
  var
    found_stretch = false
    length_best = 0.0
  for start in 0 ..< count:
    # Find each stretch once, from sample whose predecessor was cut.
    if not are_shown[start] or are_shown[(start + count - 1) mod count]: continue
    var
      length = 0.0
      taken = 0
    while taken < count and are_shown[(start + taken) mod count]:
      if taken > 0:
        let
          at = ring[(start + taken) mod count]
          before = ring[(start + taken - 1) mod count]
        length += hypot(at.x - before.x, at.y - before.y)
      inc taken
    if not found_stretch or length > length_best:
      found_stretch = true
      length_best = length
      result = (start, taken)


proc markerBands(
  geometry: Multivector; scale: DrawExtent; view_projection: Matrix4; width, height: int;
  progress, clearance: float; travel: Option[float]; marker: var Marker
): bool =
  ## Build horizon line's pair of bands: two circles on sky, one each side of great circle.
  ##   Each band is *small* circle of same sphere, centre stepped along great circle's
  ##   normal, radius shrunk to stay on sphere: what parallel to great circle means
  ##   there.
  ##     Built from `directionNormalHorizon` and `spanPerpendicular`, same pair
  ##     `tessellate.addLine` builds great circle from.
  ##   Cuts each band to what stays in front of eye and inside viewport, reporting
  ##   remainder as arc: half sky is behind camera at all times.
  ##     Second cut is what `fractionLeavingView` does for rail: uncut band laps in
  ##     hundreds of times pixels on screen, comet visible few frames in thousand.
  ##   `travel` places pulse round both bands, sense from great circle's normal as
  ##   `markerLoop`'s from plane's. Both bands, or one still reads as broken.
  let normal = directionNormalHorizon(geometry)
  if normal.isNone: return
  let axes = spanPerpendicular(ORIGIN_WORLD, normal.get)
  if axes.isNone: return
  let
    (axis_first, axis_second) = axes.get
    angle = angleMarkerBands(scale, progress, clearance)
    radius = scale.radiusHorizon*cos(angle)
    offset = scale.radiusHorizon*sin(angle)

  marker = Marker(kind: MarkerKind.Bands)
  # Place each band's centre through algebra, eye stepped along normal, and ring off table.
  #   Two rings of multivector sums per frame was cost before.
  let
    normal_point = toMultivector(normal.get)
    arm_first = radius*axis_first
    arm_second = radius*axis_second
  for side in 0 .. 1:
    let centre = pointFrom(add(
      scale.eye_point, wedge((if side == 0: offset else: -offset), normal_point)
    ))
    var
      ring: array[SEGMENTS_MARKER_BANDS, ScreenPosition]
      are_shown: array[SEGMENTS_MARKER_BANDS, bool]
    for i in 0 ..< SEGMENTS_MARKER_BANDS:
      ring[i] = projectToScreen(
        view_projection, width, height,
        onCircleAt(
          centre, arm_first, arm_second,
          UNIT_RING_BANDS[i].cos_angle, UNIT_RING_BANDS[i].sin_angle,
        ),
      )
      are_shown[i] = ring[i].isWithinView(width, height)
    # Emit one unbroken stretch, so arc does not wrap cut and draw chord across view.
    let (start, count_shown) = runShownLongest(ring, are_shown)
    if count_shown == 0: continue

    marker.are_closed_band[side] = count_shown == SEGMENTS_MARKER_BANDS
    # Reach edge band leaves through, rather than stopping up to whole step short of it.
    #   Only where sample past edge is in front of eye.
    template placeCrossing(inside, outside: int) =
      if ring[outside].isInFront:
        marker.points_band[side][marker.counts_band[side]] = ring[inside].towards(
          ring[outside], fractionLeavingView(ring[inside], ring[outside], width, height)
        )
        inc marker.counts_band[side]
    if not marker.are_closed_band[side]:
      placeCrossing(start, (start + SEGMENTS_MARKER_BANDS - 1) mod SEGMENTS_MARKER_BANDS)
    let count_before = marker.counts_band[side]
    for step in 0 ..< count_shown:
      let i = (start + step) mod SEGMENTS_MARKER_BANDS
      marker.points_band[side][marker.counts_band[side]] = ring[i]
      inc marker.counts_band[side]
    if not marker.are_closed_band[side]:
      placeCrossing(
        (start + count_shown - 1) mod SEGMENTS_MARKER_BANDS,
        (start + count_shown) mod SEGMENTS_MARKER_BANDS,
      )
    if travel.isSome:
      # Anchor each band at own angle zero, fixed from geometry alone.
      #   Bands stay in step through cut; lap against first band that produced one.
      let track = trackAlong(
        marker.points_band[side], marker.counts_band[side], marker.are_closed_band[side],
        originAfterCut(SEGMENTS_MARKER_BANDS, start, count_shown, count_before),
      )
      if marker.lap <= 0.0: marker.lap = track.lap
      marker.addPulse(
        marker.points_band[side], marker.counts_band[side],
        marker.are_closed_band[side], track, travel.get,
      )
  if marker.counts_band[0] == 0 and marker.counts_band[1] == 0: return
  for side in 0 .. 1:
    marker.placeLabelAboveTopmost(marker.points_band[side], marker.counts_band[side])
  true


func radiusToEdge(half_width, half_height, angle: float): float =
  ## Measure how far edge of axis-aligned rectangle stands from its centre along `angle`.
  ##   Whichever bound ray reaches sooner.
  ##   Ray straight along axis never reaches pair parallel to it, so that term is dropped
  ##   rather than divided by zero.
  let (across, down) = (abs(cos(angle)), abs(sin(angle)))
  if across <= 0.0: return half_height/down
  if down <= 0.0: return half_width/across
  min(half_width/across, half_height/down)


func markerFrame(width, height: int; progress, clearance: float; marker: var Marker): bool =
  ## Build horizon plane's frame: boundary around viewport.
  ##   Expands from centre as circle and settles as viewport's rectangle.
  ##   Plane at horizon is whole sky, drawn as dome filling every direction, so honest
  ##   marker surrounds view. It does not move with camera; what it marks does not either.
  ##   `progress` sets one reach in pixels, and each direction's boundary point stands at
  ##   that reach *or* screen edge, whichever is nearer.
  ##     Circle while it fits, then edge piece by piece: midpoints first, corners last.
  ##     Rectangle scaled about centre read as shrunken copy of screen.
  ##     Full reach is half-diagonal, corners' distance.
  ##   `clearance` pushes it outward past inset: frame is never under finger, and
  ##   shrinking would read as retreating.
  ##   No pulse: pulse's message is orientation, and plane at horizon has none.
  ##     `frame`, `directionNormal` and `direction` all report nothing, negated or not.
  ##   None only for viewport too small to hold inset.
  let
    inset = GAP_MARKER - clearance
    (centre_x, centre_y) = (0.5*float(width), 0.5*float(height))
    (half_width, half_height) = (centre_x - inset, centre_y - inset)
  if half_width <= 0.0 or half_height <= 0.0: return
  let
    reach = clamp(progress, 0.0, 1.0)*hypot(half_width, half_height)
    turn_corner = arctan2(half_height, half_width)
    # Ascending; corners are only directions even sampling cannot be trusted to land on.
    turns_corner = [
      turn_corner, PI - turn_corner, PI + turn_corner, 2.0*PI - turn_corner
    ]
  marker = Marker(kind: MarkerKind.Frame)
  template emit(angle: float) =
    let radius = min(reach, radiusToEdge(half_width, half_height, angle))
    marker.points_frame[marker.count_frame] = ScreenPosition(
      x: centre_x + radius*cos(angle),
      y: centre_y + radius*sin(angle),
      depth: 1.0,
    )
    inc marker.count_frame
  # Merge two ascending runs of angles into one, so boundary strokes as simple closed outline.
  var next_corner = 0
  for step in 0 ..< SEGMENTS_MARKER_FRAME:
    let angle = (2.0*PI*float(step))/float(SEGMENTS_MARKER_FRAME)
    while next_corner < CORNERS_MARKER_FRAME and turns_corner[next_corner] <= angle:
      # Skip corner landing exactly on step, which step itself emits.
      if turns_corner[next_corner] < angle: emit(turns_corner[next_corner])
      inc next_corner
    emit(angle)
  while next_corner < CORNERS_MARKER_FRAME:
    emit(turns_corner[next_corner])
    inc next_corner
  # Inside top edge: frame is whole view, and above it is off screen.
  marker.has_label = true
  marker.label_at = ScreenPosition(
    x: centre_x, y: inset + GAP_MARKER + 0.5*HEIGHT_MARKER_LABEL, depth: 1.0,
  )
  true



#[ Marker Dispatch ]#

proc markerFor*(
  geometry: Multivector; anchor_override: Option[Position]; radius: float;
  scale: DrawExtent; placement: Camera; view_projection: Matrix4; width, height: int;
  marker: var Marker; progress: float = 1.0;
  is_touch: bool = false; travel: Option[float] = none(float); swell: float = 0.0
): bool =
  ## Kind marker for one object, dispatching on its grade and whether it is at horizon.
  ##   Fills caller's `marker` and reports whether one was shaped, not `Option[Marker]`.
  ##     `Marker` reserves every kind's fixed arrays, and on JS backend each return, `get`
  ##     and assignment walked all of it through `nimCopy` (Art. VII.1).
  ##     On `false` storage holds nothing readable.
  ##   `anchor_override` is object's stored creation anchor, used for plane and ignored
  ##   otherwise, as `tessellate.addObject` treats it.
  ##   `radius` is object's drawn radius, used for point and ignored otherwise, likewise.
  ##   `progress` draws marker part-built, for press maturing into selection; 1 is
  ##   finished marker.
  ##     How partial marker is shaped is each outline's business: ring sweeps, rails run
  ##     outward, circle opens, bands close inward, frame opens from middle.
  ##   `is_touch` says hold is finger's, and `swell` how far clear every outline is
  ##   pushed; see `clearanceTouch` and `interaction.swellHold`.
  ##   `travel` places orientation pulse round outline, and is what caller passes to say
  ##   object is selected: hover and keyboard focus pass none.
  ##     Distance in screen pixels from outline's anchor, from `selection.PulseClock`.
  ##     None where object has no orientation: point, and plane at horizon (see
  ##     `markerFrame`).
  ##   None only where object has no drawable geometry. Every drawn shape has marker.
  let shape = kindOf(geometry)
  if shape.isNone: return
  let
    is_horizon = geometry.isHorizon
    clearance = clearanceTouch(swell, is_touch)
  case shape.get
  # Ring point at horizon about fixed star `anchorFor` places, so it needs no branch.
  #   Two below are drawn as great circle and whole sky with no anchor.
  of Kind.Point:
    markerRing(
      geometry, radius, scale, view_projection, width, height, progress, clearance, marker
    )
  of Kind.Line:
    if is_horizon:
      markerBands(
        geometry, scale, view_projection, width, height, progress, clearance, travel,
        marker,
      )
    else:
      markerRails(
        geometry, scale, view_projection, width, height, progress, clearance, travel,
        marker,
      )
  of Kind.Plane:
    if is_horizon: markerFrame(width, height, progress, clearance, marker)
    else:
      markerLoop(
        geometry, anchor_override, scale, placement, view_projection, width, height,
        progress, clearance, travel, marker,
      )
