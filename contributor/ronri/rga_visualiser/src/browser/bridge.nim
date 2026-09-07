## Bridge interactive RGA panel to WebGL front end, compiled through Nim's JS backend.
##
## Every join, meet, attitude, support, expansion, projection, pick and drag browser
## offers is computed by same modules desktop draws through.
##   `pga`, `objects`, `mesh`, `camera`, `scene`, `picking`, `interaction` and
##   `storyboard`.
##   Only presentation (WebGL calls, DOM, pointer input) is JS's own, as OpenGL/SDL/Dear
##   ImGui are desktop's presentation over same CPU-side geometry.
## Full parity with desktop.
##   Add point, apply any catalogue operation to two picked operands, drag from one object
##   onto another to derive third, edit any object's label, palette slot, visibility or
##   raw coefficients, remove object, save or load scene, and orbit/pan/dolly camera by
##   drag or typed numbers.
##   Entire surface `panel.nim` lays out for Dear ImGui, offered as exported procs
##   hand-written presentation layer drives.
## Not carried over: `scene.toCstring`, `format.appendMagnitude` and every desktop-only
## diagnostic.
##   Arena accounting and SDL/OpenGL loop timing depend on C FFI or on addresses JS has
##   no notion of.
##   What coefficient should read as is this project's rule, so `nimFormatNumber` answers
##   from `format.formatMagnitude` rather than JS `toFixed`.
##   Browser diagnostics substitute (frame time via `requestAnimationFrame`, JS heap where
##   available) covers same purpose without pretending to same numbers.
## Desktop's file-path save/load becomes browser download/upload of identical `.rgascene`
## binary; see `scene.nim`.
##   This module exposes raw per-object fields rather than bytes, since packing IEEE-754
##   doubles by hand in Nim/JS would reinvent browser's `DataView`.
##
## Browser entry point; see `visualiser.nim`'s "Render Paths" table for module split.

{.experimental: "strictFuncs".}

import std/[options, strformat]

import pga
import ../rga_visualiser/[
  lighting,
  boundary, camera, format, framing, help, history,
  interaction, marker, orrery, picking, ramp, scene, selection, storyboard, tessellate,
  timings,
]


var SCRATCH: DrawScratch
  ## Hold where tessellation step assembles ribbon pieces before emitting them.
  ##   Fixed buffer rather than desktop's frame arena, which casts pointer over global and
  ##   carves typed slices, neither possible on JS backend.
  ##   Sized by `LINES_GRID_MAX`, most one-piece chords grid family can lay.

proc performanceNow(): float {.importjs: "performance.now()", sideEffect.}
  ## Read page's monotonic clock, in milliseconds.
  ##   Bridge's one piece of interop beyond exports: per-phase draw timings bracket work
  ##   inside one call, which single caller-supplied reading cannot.
  ##   Confined to timing; no rule may read it.


type
  FlatBuffer = ref object of RootObj
    ## Define opaque handle on JS `Float32Array`, never constructed in Nim.
    ##   Page's own memory, filled from here.
    ##     `seq[float32]` on this backend is JS `Array` of boxed doubles, converted element
    ##     by element into staging `Float32Array` `gl.bufferData` wants, paid per frame
    ##     purely as representation.
    ##     Written straight into typed array, `uploadBuffer` hands it to driver untouched.
    ##   Narrowing to `float32` moves from upload to fill; uploaded bytes are identical.

  FlatFloats = object
    ## Define flat buffer at full capacity, and how much of it this frame filled.
    ##   Allocated once at cap matching mesh is bounded by, never grown: fixed-capacity
    ##   rule `mesh.nim`'s caps state.
    values: FlatBuffer
    used: int

# Mark every binding `sideEffect`.
#   Compiler assumes imported body is pure, so `func` calling one would compile; marked,
#   only `proc` may reach effects, which is what makes `func` mean anything here.
proc newFlatBuffer(count: int): FlatBuffer {.importjs: "new Float32Array(#)", sideEffect.}
  ## Allocate typed array of `count` floats, once.

proc `[]=`(buffer: FlatBuffer, index: int, value: float32) {.importjs: "#[#] = #", sideEffect.}
  ## Write one float in place, compiling to plain indexed store.

proc prefix(buffer: FlatBuffer, count: int): FlatBuffer {.importjs: "#.subarray(0, #)", sideEffect.}
  ## Report first `count` entries as view.
  ##   No copy, and `instanceof Float32Array` still holds, so browser scripts uploads it with
  ##   nothing in between.

proc initFlatFloats(capacity: int): FlatFloats =
  ## Reserve flat buffer of `capacity` floats, empty.
  FlatFloats(values: newFlatBuffer(capacity), used: 0)

proc view(flat: FlatFloats): FlatBuffer = flat.values.prefix(flat.used)
  ## Report just part this frame filled, for upload.
  ##   One small view object per buffer per frame, seven in all, against whole buffer of
  ##   element-by-element conversion it replaces.

proc `[]=`(flat: var FlatFloats, index: int, value: float32) = flat.values[index] = value
  ## Write one float into flat buffer.

# Fill fixed-size answers by template, not `openArray`.
#   Array literal passed to proc is `new Float32Array` per call on this backend; template
#   expands to plain stores (read in emitted JS).
template emptied(flat: var FlatFloats): FlatBuffer =
  ## Report flat buffer as empty view.
  flat.used = 0
  flat.view

template fill2(flat: var FlatFloats, a, b: float32): FlatBuffer =
  ## Replace contents with two floats, and report them as view.
  flat[0] = a
  flat[1] = b
  flat.used = 2
  flat.view

template fill3(flat: var FlatFloats, a, b, c: float32): FlatBuffer =
  ## Replace contents with three floats, and report them as view.
  flat[0] = a
  flat[1] = b
  flat[2] = c
  flat.used = 3
  flat.view

template fill6(flat: var FlatFloats, a, b, c, d, e, f: float32): FlatBuffer =
  ## Replace contents with six floats, and report them as view.
  flat[0] = a
  flat[1] = b
  flat[2] = c
  flat[3] = d
  flat[4] = e
  flat[5] = f
  flat.used = 6
  flat.view



#[ Panel State ]#

# Read `SettingsFurniture` from `camera`, shared with desktop's hold.


type SettingsOverlay = tuple
  ## Define everything overlay's shared draw extent and view-projection depend on.
  ##   Camera's whole placement and viewport asked about.
  pivot_x, pivot_y, pivot_z: float
  distance, azimuth, elevation, degrees_field_of_view, reach_scene: float
  width, height: int

type ShapedMarker = tuple
  ## Define one shaped marker beside everything it was shaped from; see `MARKER_SHAPED`.
  handle: int
  width, height: int
  progress: float
  is_touch: bool
  swell: float
  travel: float
  settings: SettingsOverlay
  marker: ref Marker ## Boxed, and box is point.
    ##   `Marker` is wide variant object (two pulse runs, loop, both bands), and JS backend
    ##   deep-copies every value assignment through `nimCopy`.
    ##   Stored by value, memo's store-and-read copies marker twice and costs as much as
    ##   shaping it replaces; behind ref, one copy at store, none at read.


type SettingsScene = tuple
  ## Define everything scene's own meshes are built from.
  ##   `SettingsFurniture`'s rule, one layer out: two frames agreeing here draw same scene
  ##   records, so second may keep first's.
  ##   Furniture tuple is carried whole, since it names camera, framebuffer height and
  ##   field of view: everything `drawExtentFor` reads.
  ##     It also names two furniture toggles scene does not read; over-approximation
  ##     costing one rebuilt frame when reader switches grid off.
  ##   `aspect` is here because view-projection matrix reads it and furniture does not.
  ##   `revision` is scene's own; see `scene.revision`.
  ##   Two things are guards instead; see `nimBuildFrame`.
  ##     Preview or drag preview standing (moves with pointer), appear animation running.
  furniture: SettingsFurniture
  aspect: float
  revision: int
  revision_selection: int ## `selection.revision`, never selection itself.
    ## Comparing and copying `OBJECTS_MAX` ints per frame is capacity-scaled work for scene
    ## of five.
  is_culling: bool ## Whether points outside view are skipped; see `IS_CULLING`.


var
  SCENE: Scene
  CAMERA: Camera
  MESHES_FURNITURE, MESHES: MeshSet ## Hold meshes at module scope, reused every frame.
    ## Cleared through `clearMeshes` rather than declared per frame.
    ## `clearMeshes` resets each mesh's `count_vertices`, not storage, mirroring
    ## `visualiser.nim`'s `MESHES`/`MESHES_FURNITURE`.
    ## As `nimBuildFrame` locals, each call reallocates and zero-fills whole fixed
    ## storage regardless of object count: `MeshSet` reserves it up front, and JS backend
    ## has no stack allocation.
  SETTINGS_SCENE_HELD = none(SettingsScene) ## What scene meshes standing in `MESHES` were
    ## built from, or none before first build.
    ## Furniture's hold, one layer out; see `SettingsScene` and `FrameData.is_scene_held`.
  SETTINGS_FURNITURE_HELD = none(SettingsFurniture) ## What furniture standing in
    ## `MESHES_FURNITURE` was built from, or none before first build.
    ## See `FrameData.is_furniture_held`.
  COUNT_GRID_SEGMENTS = 0 ## How many ribbon segments ground grid alone was last built
    ## from, axes' fixed share excluded.
    ## Kept beside furniture rather than recounted: held frame draws grid it had and
    ## should report that grid's count rather than zero.
  SETTINGS_OVERLAY_HELD = none(SettingsOverlay) ## What `SCALE_OVERLAY` and
    ## `VIEW_PROJECTION_OVERLAY` were derived from, or none before first derivation.
  SCALE_OVERLAY: DrawExtent ## Draw extent overlay calls share; see `ensureViewOverlay`.
  VIEW_PROJECTION_OVERLAY: Matrix4 ## View-projection those same calls share.
  BOX_MARKER: ref Marker = new(Marker) ## One box every shaping fills.
    ## Allocated once.
    ##   `Marker` reserves every marker kind's fixed arrays, so `new` per shaping is
    ##   kilobytes allocated and zeroed per selected object per frame.
    ## `markerFor` fills caller storage, so one box serves every call and
    ## `nimSelectionPulse` reads back what `nimSelectionMarker` filled.
  MARKER_SHAPED = none(ShapedMarker) ## Marker `nimSelectionMarker` last shaped, with
    ## everything it was shaped from.
    ## `nimSelectionPulse` asked same question in same frame reads answer instead of
    ## shaping again.
    ## Sound because overlay draws each handle marker-then-pulse back to back in one
    ## synchronous pass, and marker call always shapes fresh and overwrites this.
    ##   Key carries every non-scene input, so pulse asked at other settings shapes for
    ##   itself.
  INTERACTION = Interaction(is_enabled: true) ## Picking and drag, always live here.
    ## No storyboard-capture mode to switch them off for.
  POINTER_PICK: Option[PointerPick] ## Pick made by pointer since camera was last offered.
    ## Consumed by `framing.offerAim` in `nimBuildFrame`; see `nimPickByPointer`.
  PLACEMENTS: array[OBJECTS_MAX, Placement] ## What algebra says about each live handle.
    ## Placement once per edit, emitted every frame.
    ##   Nothing in `tessellate.Placement` reads camera, so placement stays true while view
    ##   orbits; recomputing every orbit frame is most of moving frame; figures in
    ##   `PROVENANCE.md`.
    ## Held for scene's handles only: preview and drag preview move with pointer, so both are
    ## placed where drawn.
    ## Dead handles hold whatever last occupant left; every walk skips them.
  LIGHTS: LightCache ## Per-handle direction toward its sun; see `lighting.LightCache`.
    ## Refreshed with `PLACEMENTS`, since it reads them.
  REVISION_PLACED = none(int) ## Scene revision `PLACEMENTS` was filled at, or none before
    ## first fill.
  BORN_LAST = 0.0 ## Latest birth stamp `stampBorn` has written.
    ## What says scene has stopped animating.
    ##   Every object fades in over `mesh.ANIMATION_SECONDS` from its stamp, so frame past
    ##   this plus window draws every object at full progress and next draws it identically:
    ##   condition scene hold needs.
    ## Watermark rather than scan of all `OBJECTS_MAX` stamps per frame; only rises.
  BORNS: array[OBJECTS_MAX, float] ## Birth stamps, one per handle, moment object is added.
    ## Read by `nimBuildFrame` so it animates in as desktop's newly-added object does.
  SELECTION: Selection ## Objects picked right now, in pick order.
    ## Each ringed by presentation layer's `refreshOverlay`.
    ## Replaced by every construction path, driven by touch/click gestures through
    ## `nimSelectOnly`/`nimSelectToggle`/`nimSelectClear`.
    ## Presentation layer keeps no list: pick order names operands, so it lives in
    ## `selection.nim`.
  OPERATIONS: OperationMemory ## Which operation each arity's picker opens on.
    ## Carried from last apply.
  CLOCK_PULSE: PulseClock ## Each selected object's orientation-pulse phase, carried
    ## between frames.
    ## See `selection.PulseClock` for why phase off clock teleports.
  SECONDS_STEP_PULSE: float ## How long frame being drawn is, for that clock.
    ## Held because `nimTickPulse` takes one reading and every `nimSelectionPulse` after
    ## it in same frame must advance by same step.
  TWEEN_CAMERA: CameraTween ## Carries camera toward whatever is being built or edited.
    ## See `camera.CameraTween`; aimed and advanced inside `nimBuildFrame`, from same rule
    ## desktop uses.
  HISTORY: History ## Undo/redo timeline of scene-content edits.
    ## Scoped as `visualiser.HISTORY` is; see `history.nim`.
    ## Seeded via `initHistory` wherever `SCENE` is replaced (`nimInit`, `nimLoadDemo`,
    ## `nimSceneClear`).
  GHOST = none(Multivector) ## Multivector open edit session is staging.
  RADIUS_GHOST = RADIUS_OBJECT_DEFAULT ## Radius that session stages beside it.
    ## Rendered every frame like live object but never added to `SCENE`:
    ## `nimSceneHandles`, undo, save, picking never see it.
    ## Serves both session modes, composing and editing.
    ## None where no session is open, or last committed or was abandoned.
  PREVIEW_APPLY = none(Preview) ## What open apply control would build.
    ## Previewed while reader is choosing, as drag's rubber-band does.
    ## Own handle rather than `GHOST`'s, so which shows is decided by `staged` in Nim.
    ## Written by `nimPreviewOperation`, dropped by `nimClearPreview`.

const INK_PREVIEW = Ink.Guide
  ## Tint preview in this palette slot, muted, reusing `Ink.Guide`'s "construction helper" role.


func toRgbSeq(c: Rgba): seq[float32] = @[c.red, c.green, c.blue]
  ## Format colour as `[r, g, b]` triple, for caller formatting CSS colour string itself.


func countOverlay(mesh: Mesh): int =
  ## Count how many of one mesh's vertices are its overlay run, drawn over cleared depth.
  ##   Zero where nothing asked to be drawn over; see `mesh.Mesh.index_overlay`.
  if mesh.index_overlay.isNone: return 0
  max(0, mesh.count_vertices - clamp(mesh.index_overlay.get, 0, mesh.count_vertices))


var
  # Hold one flat buffer per primitive, refilled in place every frame.
  #   Fresh sequences would be allocations per frame feeding collector for data living
  #   one frame.
  #   Consumer uploads or reads within same frame and holds nothing across two.
  FLAT_RIBBON = initFlatFloats(RIBBONS_MAX*16)
  FLAT_FURNITURE = initFlatFloats(RIBBONS_MAX*16)
  FLAT_POINT = initFlatFloats(VERTICES_MAX*11)
  FLAT_RING = initFlatFloats(RINGS_MAX*14)
  FLAT_DISC = initFlatFloats(DISCS_MAX*13)
  FLAT_DOME = initFlatFloats(DOMES_MAX*8)
  FLAT_RUNS = initFlatFloats((DISCS_MAX + DOMES_MAX)*3)
  # Hold small overlay answers asked per frame, refilled in place through `fill`.
  #   Fresh sequence per call was allocation per frame of every drag and open menu.
  FLAT_ANCHOR = initFlatFloats(3)
  FLAT_TINT = initFlatFloats(3)
  FLAT_COMET = initFlatFloats(2*POINTS_MARKER_PULSE)
  FLAT_GRID = initFlatFloats(2)
  FLAT_TARGET = initFlatFloats(3)
  FLAT_EYE = initFlatFloats(3)
  FLAT_LABEL = initFlatFloats(6)
  FLAT_ANCHOR_WORLD = initFlatFloats(3)
  FLAT_MENU = initFlatFloats(3*(ord(DragChoice.high) + 1))
  FLAT_MENU_CENTRE = initFlatFloats(2)
  FLAT_VIEW: seq[float32] = newSeq[float32](16)
  IS_CULLING = true ## Whether points outside view are skipped before emitting.
    ## Off only through `nimSetCulling`, for check that culling changes no pixel.
  REACH_SCENE = 0.0 ## Scene's reach from origin, refreshed with placements; see `ensurePlacement`.


proc flattenRibbonsInto(ribbons: RibbonMesh, dest: var FlatFloats) =
  ## Interleave one frame's ribbon records for instanced upload, sixteen floats each.
  ##   Tail xyz, head xyz, width, fog, tail rgba, head rgba: `RibbonRecord`'s field order,
  ##   which attribute setup in browser scripts reads back apart.
  dest.used = ribbons.count * 16
  for i in 0 ..< ribbons.count:
    template r: untyped = ribbons.records[i]
    dest[16*i + 0] = r.tail_x
    dest[16*i + 1] = r.tail_y
    dest[16*i + 2] = r.tail_z
    dest[16*i + 3] = r.head_x
    dest[16*i + 4] = r.head_y
    dest[16*i + 5] = r.head_z
    dest[16*i + 6] = r.width
    dest[16*i + 7] = r.fog
    dest[16*i + 8] = r.tail_red
    dest[16*i + 9] = r.tail_green
    dest[16*i + 10] = r.tail_blue
    dest[16*i + 11] = r.tail_alpha
    dest[16*i + 12] = r.head_red
    dest[16*i + 13] = r.head_green
    dest[16*i + 14] = r.head_blue
    dest[16*i + 15] = r.head_alpha


proc flattenDiscsInto(discs: DiscMesh, dest: var FlatFloats) =
  ## Interleave one frame's disc records for instanced upload, thirteen floats each.
  ##   Centre xyz, first arm xyz, second arm xyz, fill rgba: `DiscRecord`'s field order.
  dest.used = discs.count * 13
  for i in 0 ..< discs.count:
    template r: untyped = discs.records[i]
    dest[13*i + 0] = r.centre_x
    dest[13*i + 1] = r.centre_y
    dest[13*i + 2] = r.centre_z
    dest[13*i + 3] = r.arm_first_x
    dest[13*i + 4] = r.arm_first_y
    dest[13*i + 5] = r.arm_first_z
    dest[13*i + 6] = r.arm_second_x
    dest[13*i + 7] = r.arm_second_y
    dest[13*i + 8] = r.arm_second_z
    dest[13*i + 9] = r.fill_red
    dest[13*i + 10] = r.fill_green
    dest[13*i + 11] = r.fill_blue
    dest[13*i + 12] = r.fill_alpha


proc flattenRingsInto(rings: RingMesh, dest: var FlatFloats) =
  ## Interleave one frame's ring records for instanced upload, fourteen floats each.
  ##   `DiscRecord`'s thirteen in same order, then width, so ring and disc attribute
  ##   setups in browser scripts differ by one trailing attribute.
  dest.used = rings.count * 14
  for i in 0 ..< rings.count:
    template r: untyped = rings.records[i]
    dest[14*i + 0] = r.centre_x
    dest[14*i + 1] = r.centre_y
    dest[14*i + 2] = r.centre_z
    dest[14*i + 3] = r.arm_first_x
    dest[14*i + 4] = r.arm_first_y
    dest[14*i + 5] = r.arm_first_z
    dest[14*i + 6] = r.arm_second_x
    dest[14*i + 7] = r.arm_second_y
    dest[14*i + 8] = r.arm_second_z
    dest[14*i + 9] = r.red
    dest[14*i + 10] = r.green
    dest[14*i + 11] = r.blue
    dest[14*i + 12] = r.alpha
    dest[14*i + 13] = r.width


proc flattenDomesInto(domes: DomeMesh, dest: var FlatFloats) =
  ## Interleave one frame's dome records for instanced upload, eight floats each.
  ##   Centre xyz, radius, rgba: `DomeRecord`'s field order.
  dest.used = domes.count * 8
  for i in 0 ..< domes.count:
    template r: untyped = domes.records[i]
    dest[8*i + 0] = r.centre_x
    dest[8*i + 1] = r.centre_y
    dest[8*i + 2] = r.centre_z
    dest[8*i + 3] = r.radius
    dest[8*i + 4] = r.red
    dest[8*i + 5] = r.green
    dest[8*i + 6] = r.blue
    dest[8*i + 7] = r.alpha


proc flattenVeilRunsInto(veils: VeilRuns, dest: var FlatFloats) =
  ## Interleave veil draw order, three floats per run: kind ordinal, first, count.
  dest.used = veils.count * 3
  for i in 0 ..< veils.count:
    dest[3*i + 0] = float32(ord(veils.runs[i].kind))
    dest[3*i + 1] = float32(veils.runs[i].first)
    dest[3*i + 2] = float32(veils.runs[i].count)


proc stampBorn(handle: int, born: float) =
  ## Record when object in `handle` arrived, and carry watermark with it.
  ##   One door birth stamps go through, so `BORN_LAST` cannot fall behind stamp written
  ##   directly, which would let scene hold engage over object still fading in.
  BORNS[handle] = born
  BORN_LAST = max(BORN_LAST, born)


proc flattenInto(mesh: Mesh, dest: var FlatFloats) =
  ## Interleave point records as `x, y, z, radius, light xyz, r, g, b, a, ...` into `dest`.
  ##   Ready for `gl.bufferData`; `mesh.Vertex`'s field order.
  dest.used = mesh.count_vertices * 11
  for i in 0 ..< mesh.count_vertices:
    template v: untyped = mesh.vertices[i]
    dest[11*i + 0] = v.x
    dest[11*i + 1] = v.y
    dest[11*i + 2] = v.z
    dest[11*i + 3] = v.radius
    dest[11*i + 4] = v.light_x
    dest[11*i + 5] = v.light_y
    dest[11*i + 6] = v.light_z
    dest[11*i + 7] = v.red
    dest[11*i + 8] = v.green
    dest[11*i + 9] = v.blue
    dest[11*i + 10] = v.alpha



#[ Setup ]#

proc placeSeeds(now: float) =
  ## Build same default scene desktop opens on with no saved scene.
  ##   Five seeds, nothing derived; mirrors `visualiser.main`'s startup.
  ##   Arrives as replay, like demo and loaded file: watching it build states that these
  ##   were placed one at time and everything else is derived from them.
  SCENE.restoreFrom(initScene())
  constructSeeds(SCENE, now)
  SCENE.replayFrom(now)
  for handle in 0 ..< SCENE.len: stampBorn(handle, SCENE.bornAt(handle))


proc nimInit(now: cfloat) {.exportc.} =
  ## Build default interactive scene and place camera at default orbit desktop opens on.
  placeSeeds(float(now))
  CAMERA = initCameraDefault()
  SELECTION.clear()
  HISTORY.initHistory(SCENE, CAMERA)


proc nimSetCulling(is_on: bool) {.exportc.} =
  ## Turn culling of points outside view on or off.
  ##   Instrument for driven check that culling changes no pixel. Part of scene's hold
  ##   key, so next frame rebuilds either way.
  IS_CULLING = is_on


proc nimLoadDemo(scale_ordinal: cint; now: cfloat; width, height: cint) {.exportc.} =
  ## Replace current scene with orrery, as ordinary live objects.
  ##   One-click preset, every object as editable, removable and pickable as anything
  ##   built by hand, free handles there to build in.
  ##   Heaviest scene this build draws, at largest size, which is what demo is for.
  ##     Storyboard is unchanged and still what `visualiser --storyboard` captures; see
  ##     `orrery` and `storyboard.STEPS`.
  ##   Scene and camera come from `orrery.showOrrery`, which desktop's `--demo` calls too.
  ##     Preset is one copy shared by both front-ends; left here is only what this side
  ##     keeps of its own about scene.
  ##   `scale_ordinal` names one of `orrery.ScaleOrrery`'s three sizes; see `nimDemoObjects`.
  let clock = float(now)
  showOrrery(SCENE, CAMERA, int(width), int(height), ScaleOrrery(scale_ordinal), clock)
  for handle in 0 ..< SCENE.len: stampBorn(handle, SCENE.bornAt(handle))
  SELECTION.clear()
  HISTORY.initHistory(SCENE, CAMERA)


proc nimDemoScales(): seq[cint] {.exportc.} =
  ## Report every size demo can be loaded at, smallest first, as `nimLoadDemo` ordinals.
  ##   Page builds one button per entry rather than carrying its own list.
  for scale in ScaleOrrery: result.add(cint(ord(scale)))


proc nimDemoObjects(scale_ordinal: cint): cint {.exportc.} =
  ## Report how many objects demo comes to at one size, for button that loads it.
  cint(objectsOf(ScaleOrrery(scale_ordinal)))


proc nimDemoScaleDefault(): cint {.exportc.} = cint(ord(SCALE_ORRERY_DEFAULT))
  ## Report which size demo opens on when nobody has asked for another.



#[ Scene Inspection ]#

proc nimSceneCount(): cint {.exportc.} = cint(SCENE.len)
  ## Report how many objects are alive in scene.

proc nimSceneCapacity(): cint {.exportc.} = cint(OBJECTS_MAX)
  ## Report fixed number of object handles this build reserves.

proc nimSceneRevision(): cint {.exportc.} =
  ## Report how many times scene's drawn content has changed; see `scene.revision`.
  ##   For presentation layer holding something derived from scene: object-pool strip
  ##   redraws its cells when this moves and at no other time.
  cint(SCENE.revision)


proc nimSceneHandles(): seq[cint] {.exportc.} =
  ## Report every live handle, in handle order.
  ##   Same dense-position-to-handle mapping `panel.layoutOperation`'s combo boxes rely on.
  ##   Walks handles directly rather than through `pairs`: that iterator yields `Object` per
  ##   live handle, and under JS backend constructing `Object` copies whole `Scene` by value.
  for handle in 0 ..< SCENE.bound:
    if SCENE.isAlive(handle): result.add(cint(handle))


proc nimSceneHandlesCreated(): seq[cint] {.exportc.} =
  ## Report every live handle, oldest creation first, for browser scripts's scene writer.
  ##   Handle order and creation order part company once anything is removed; version-3
  ##   file promises latter.
  ##   Own export rather than reordering `nimSceneHandles`, whose callers want dense
  ##   positions their combo boxes index.
  var handles: array[OBJECTS_MAX, int]
  let count = SCENE.handlesCreated(handles)
  for position in 0 ..< count: result.add(cint(handles[position]))


proc nimIsAlive(handle: cint): bool {.exportc.} = SCENE.isAlive(int(handle))
  ## Report whether handle holds live object.

proc nimObjectLabel(handle: cint): cstring {.exportc.} =
  ## Report object's display label, by handle.
  cstring(toText(SCENE.labelAt(int(handle))))


proc nimObjectInk(handle: cint): cint {.exportc.} = cint(SCENE.inkAt(int(handle)))
  ## Report object's palette slot, by handle.

proc nimObjectVisible(handle: cint): bool {.exportc.} = SCENE.isVisible(int(handle))
  ## Report object's visibility, by handle.

proc nimObjectRadius(handle: cint): cfloat {.exportc.} = cfloat(SCENE.radiusAt(int(handle)))
  ## Report object's drawn radius, in world units, by handle.

proc nimObjectShines(handle: cint): bool {.exportc.} = SCENE.shinesAt(int(handle))
  ## Report whether object lights others, by handle.

proc nimDefaultRadius(): cfloat {.exportc.} = cfloat(RADIUS_OBJECT_DEFAULT)
  ## Report radius freshly composed object starts out with.

proc nimLeastRadius(): cfloat {.exportc.} = cfloat(RADIUS_OBJECT_LEAST)
  ## Report smallest radius size field accepts; see `scene.RADIUS_OBJECT_LEAST`.

proc nimObjectBorn(handle: cint): cfloat {.exportc.} = cfloat(BORNS[int(handle)])
  ## Report moment object was added, by handle, on same clock as every `now` here.
  ##   Lets browser's Objects panel sort by recency.

proc nimObjectKindWord(handle: cint): cstring {.exportc.} =
  ## Report object's kind, by handle, in words `scene.kindText` names it.
  ##   Same words desktop status line uses, same call.
  cstring(kindText(SCENE.geometryOf(int(handle))))


proc nimObjectCoefficients(handle: cint): seq[float] {.exportc.} =
  ## Report all sixteen basis coefficients of object's multivector, in library's `Basis` order.
  ##   Same order `scene.saveScene`/`loadScene` and `panel.layoutCoefficients` use.
  let geometry = SCENE.geometryOf(int(handle))
  result = newSeq[float](ord(Basis.high) + 1)
  for b in Basis: result[ord(b)] = geometry[b]


proc nimFormatNumber(value: float): cstring {.exportc.} =
  ## Format one number for field, to same four significant digits desktop's drag widget shows.
  ##   3.5 reads `3.5`, not `3.5000`.
  ##   Every editable number goes through here.
  ##     Exported rather than left to JS `toFixed`: how many digits number is worth is
  ##     decision about this project's numbers.
  ##   `format.formatMagnitude` rather than `format.appendMagnitude`, whose `snprintf`
  ##   needs C runtime; suite holds two to same answer.
  cstring(formatMagnitude(value))


proc nimFormatMultivector(handle: cint): cstring {.exportc.} =
  ## Format object's multivector for display, by handle, through `scene.multivectorText`.
  ##   Same writer desktop panel's object line uses; library's `$` writes at library's `%G`,
  ##   not this project's four significant digits.
  cstring(multivectorText(SCENE.geometryOf(int(handle))))



#[ Scene Mutation ]#

proc nimDefaultLabel(): cstring {.exportc.} = cstring(&"m{SCENE.len}")
  ## Report label freshly composed object starts out carrying.
  ##   For pre-filling edit session.

proc nimDefaultInk(): cint {.exportc.} = cint(SCENE.inkNext)
  ## Report palette slot freshly composed object starts out carrying.
  ##   Cycled as every construction path cycles it.

proc nimAddObject(
  coefficients: seq[float], label: cstring, ink_ordinal: cint, radius: cfloat, shines: bool,
  now: cfloat
): cint {.exportc.} =
  ## Commit composing edit session as fresh scene object.
  ##   Takes label, palette slot, radius and shines session staged; all are editable
  ##   before commit, unlike every other construction path.
  ##   Builds `geometry` coefficient by coefficient rather than reusing `nimSceneAddRaw`.
  ##     That one skips `HISTORY.record`, stamps `BORNS` to 0.0 and never touches
  ##     `SELECTION`, all three of which user-driven add must do.
  var geometry: Multivector
  for b in Basis: geometry[b] = coefficients[ord(b)]
  result = cint(SCENE.addObject(
    geometry, $label, Ink(ink_ordinal), float(now), radius = float(radius), shines = shines
  ))
  stampBorn(int(result), float(now))
  SELECTION.selectOnly(int(result))
  HISTORY.record(SCENE, CAMERA)


proc nimCommitObject(
  handle: cint, coefficients: seq[float], label: cstring, ink_ordinal: cint, radius: cfloat,
  shines: bool
) {.exportc.} =
  ## Commit editing session onto object it was opened against.
  ##   Writes every staged field at once and records history exactly once.
  ##   "Edit committed" boundary `history.nim` asks of continuous widgets: timeline gains
  ##   one entry per save rather than one per frame of input.
  let index = int(handle)
  var geometry = SCENE.geometryOf(index)
  for b in Basis: geometry[b] = coefficients[ord(b)]
  SCENE.setGeometryAt(index, geometry)
  toChars($label, SCENE.labelAt(index))
  SCENE.setInk(index, Ink(ink_ordinal))
  SCENE.setRadius(index, float(radius))
  SCENE.setShining(index, shines)
  HISTORY.record(SCENE, CAMERA)


type OperationResult = object ## Define what applying catalogue operation produced.
  created_handle: cint ## Handle derived object was added at.
  message: cstring ## Outcome, for display as desktop panel's status line.
  shape_word: cstring ## What derived object turned out to be.


proc nimApplyOperation(
  operation_ordinal, handle_first, handle_second: cint; now: cfloat
): OperationResult {.exportc.} =
  ## Derive fresh object by applying catalogue operation to two picked operands.
  ##   As `panel.layoutOperation`'s apply button does.
  let
    operation = Operation(operation_ordinal)
    operand_first = SCENE.geometryOf(int(handle_first))
    operand_second = SCENE.geometryOf(int(handle_second))
    derived = applyOperation(operation, operand_first, operand_second)
    anchor = creationAnchor(operation, operand_first, operand_second, derived)
    name_first = toText(SCENE.labelAt(int(handle_first)))
    name_second = toText(SCENE.labelAt(int(handle_second)))
    label = notationSubstituted(operation, name_first, name_second)
    handle_created =
      SCENE.addObject(derived, label, SCENE.takeInk(), float(now), anchor)
  OPERATIONS.remember(operation)
  CLOCK_PULSE.forget(handle_created) # Fresh object starts its comet at head.
  stampBorn(handle_created, float(now))
  SELECTION.selectOnly(handle_created)
  HISTORY.record(SCENE, CAMERA)
  let shape_word = kindText(derived)
  OperationResult(
    created_handle: cint(handle_created),
    message: cstring(&"{label} gave {shape_word}."),
    shape_word: cstring(shape_word),
  )


proc nimOperationRemembered(arity: cint): cint {.exportc.} =
  ## Report operation picker of this arity should open on.
  ##   Whatever was last applied at that arity, or catalogue's first choice.
  cint(ord(OPERATIONS.lastOf(if arity == 0: Arity.One else: Arity.Two)))


proc nimPreviewOperation(operation_ordinal, handle_first, handle_second: cint): bool
  {.exportc.} =
  ## Stage what applying operation to these operands would build, as preview.
  ##   Preview appearance open edit session wears, without touching scene or undo timeline.
  ##   Picker previews its answer moment one is chosen rather than once apply is pressed.
  ##   Through `scene.previewApplying`, so preview carries anchor and operands camera keeps
  ##   in view, same construction drag offers.
  ##   False, and no preview, where either operand is gone or pair makes nothing drawable.
  PREVIEW_APPLY = SCENE.previewApplying(
    Operation(operation_ordinal), int(handle_first), int(handle_second)
  )
  PREVIEW_APPLY.isSome


proc nimClearPreview() {.exportc.} =
  ## Drop whatever apply control was previewing, for one that has gone off screen.
  ##   Own call: presentation layer knows section has collapsed or picker has closed.
  PREVIEW_APPLY = none(Preview)


proc staged(): Option[Preview] =
  ## Resolve what this build offers as not-yet-committed.
  ##   Open edit session's geometry, else whatever apply control is previewing, else
  ##   nothing.
  ##   Session wins: session is being typed into, preview is passive reading of two
  ##   pickers.
  ##   Sibling is `panel.staged`; fix both or neither.
  if GHOST.isSome: return some(previewStaging(GHOST.get, RADIUS_GHOST))
  PREVIEW_APPLY


proc nimSetVisible(handle: cint, is_visible: bool) {.exportc.} =
  ## Rewrite object's visibility, by handle.
  SCENE.setVisible(int(handle), is_visible)
  HISTORY.record(SCENE, CAMERA)


proc nimSetLabel(handle: cint, text: cstring) {.exportc.} =
  ## Rewrite object's display label, by handle.
  toChars($text, SCENE.labelAt(int(handle)))


proc nimSetInk(handle: cint, ink_ordinal: cint) {.exportc.} =
  ## Rewrite object's palette slot, by handle.
  SCENE.setInk(int(handle), Ink(ink_ordinal))
  HISTORY.record(SCENE, CAMERA)


proc nimSetRadius(handle: cint, radius: cfloat) {.exportc.} =
  ## Rewrite object's drawn radius, by handle.
  SCENE.setRadius(int(handle), float(radius))
  HISTORY.record(SCENE, CAMERA)


proc nimSetShining(handle: cint, shines: bool) {.exportc.} =
  ## Rewrite whether object lights others, by handle.
  SCENE.setShining(int(handle), shines)
  HISTORY.record(SCENE, CAMERA)


proc nimSetCoefficient(handle, basis_index: cint; value: cfloat) {.exportc.} =
  ## Rewrite one basis coefficient of object's multivector, by handle.
  var geometry = SCENE.geometryOf(int(handle))
  geometry[Basis(basis_index)] = float(value)
  SCENE.setGeometryAt(int(handle), geometry)


proc nimRemoveObject(handle: cint) {.exportc.} =
  ## Drop object from scene, freeing its handle for reuse.
  ##   Drops handle from selection too: freed handle goes straight to next add, so pick left
  ##   behind would reattach to unrelated new object.
  SCENE.removeObject(int(handle))
  SELECTION.pruneDead(SCENE)
  HISTORY.record(SCENE, CAMERA)



#[ Preview Preview ]#

proc nimSetPreviewStaged(coefficients: seq[float], radius: cfloat) {.exportc.} =
  ## Rewrite staged preview multivector wholesale, from open session's JS-side state array.
  ##   On every `input` event, so preview tracks keystroke rather than blur.
  ##   `nimBuildFrame` reads it next frame and draws it tinted `INK_PREVIEW`, muted, at
  ##   `radius` where it is point.
  var geometry: Multivector
  for b in Basis: geometry[b] = coefficients[ord(b)]
  GHOST = some(geometry)
  RADIUS_GHOST = float(radius)


proc nimDescribeCoefficients(coefficients: seq[float]): cstring {.exportc.} =
  ## Report same `shape: equation` line object row shows, for staged multivector with no handle.
  ##   Composed row then previews exactly what it reads as once committed.
  var geometry: Multivector
  for b in Basis: geometry[b] = coefficients[ord(b)]
  cstring(kindText(geometry) & ": " & multivectorText(geometry))


proc nimClearPreviewStaged() {.exportc.} =
  ## Discard preview, so `nimBuildFrame` stops drawing it.
  ##   Called once session commits or is abandoned.
  GHOST = none(Multivector)



#[ Catalogue Metadata ]#

proc nimOperationCount(): cint {.exportc.} = cint(COUNT_OPERATION)
  ## Report how many catalogue operations exist.

proc nimOperationNotation(index: cint): cstring {.exportc.} =
  ## Report Nth catalogue operation's notation, symbols alone.
  ##   English name after them is several times wider and pushes picker's popover past
  ##   hand's reach on phone.
  ##   From one table both render paths read.
  cstring(notationSymbolic(Operation(index)))


proc nimOperationArity(index: cint): cint {.exportc.} =
  ## Report 0 for operation reading one operand, 1 for one reading two.
  ##   Matches `panel.layoutOperation`'s disabling of second operand picker.
  cint(lut_operation_to_arity[Operation(index)])


proc nimBasisCount(): cint {.exportc.} = cint(ord(Basis.high) + 1)
  ## Report how many basis coefficients multivector carries in this build's dimension.

proc nimBasisName(index: cint): cstring {.exportc.} = cstring(lut_basis_to_name[Basis(index)])
  ## Report Nth basis element's name.

proc nimBasisGrade(index: cint): cint {.exportc.} = cint(ord(Basis(index).grade))
  ## Report Nth basis element's grade, for grouping coefficient grid.

proc nimInkChoosableSlots(): seq[int] {.exportc.} =
  ## List palette slots colour picker may offer, as whole-palette ordinals.
  ##   For `nimInkName` and `nimInkColor`.
  ##   Structural slots left out: object wearing backdrop, world axis or selection outline
  ##   is invisible or reads as something it is not.
  for index in 0 ..< COUNT_INK_CATEGORICAL: result.add(ord(inkCategorical(index)))


proc nimInkName(index: cint): cstring {.exportc.} = lut_ink_to_name[Ink(index)]


proc nimInkCount(): cint {.exportc.} = cint(ord(Ink.high) + 1)
  ## Report how many inks palette holds, structural and assignable alike.
  ##   Glue reads every ink's colour once at start-up, indexed by ordinal.
  ## Report Nth palette entry's name.

proc nimInkColor(index: cint): seq[float32] {.exportc.} = toRgbSeq(Ink(index).colour)


proc nimInkBackdrop(): cint {.exportc.} = cint(ord(Ink.Backdrop))
  ## Report backdrop's palette slot, for label halo drawn in scene's own ground colour.
  ## Report Nth palette entry's colour, as `[r, g, b]` triple.

proc nimBackdropColor(): seq[float32] {.exportc.} = toRgbSeq(Ink.Backdrop.colour)
  ## Report canvas backdrop's colour, as `[r, g, b]` triple.


const INK_POOL_FREE = Ink.Grid
  ## Mirror `panel.INK_POOL_FREE`, duplicated since `panel` is desktop-only.
  ##   Palette's recessive furniture colour, which is what free object-pool handle is.


var FLAT_POOL: seq[float32] = newSeq[float32](OBJECTS_MAX*3)
  ## Hold what `nimPoolCellColors` writes, kept across calls so it never allocates.

proc nimPoolCellColors(): seq[float32] {.exportc.} =
  ## Report object-pool strip's colours, one `[r, g, b]` triple per handle in handle order.
  ##   Cell wears ink of whatever object holds it and free one stays recessive; mirrors
  ##   `panel.layoutDiagnosticsObjectPool`'s cell loop.
  ##   Capacity, not watermark: strip whose subject is how much room is left has to show
  ##   room.
  ##   Fills kept buffer rather than growing fresh sequence: runs inside panel's per-frame
  ##   refresh.
  for handle in 0 ..< OBJECTS_MAX:
    let colour =
      if SCENE.isAlive(handle): SCENE.inkAt(handle).colour else: INK_POOL_FREE.colour
    FLAT_POOL[3*handle] = colour.red
    FLAT_POOL[3*handle + 1] = colour.green
    FLAT_POOL[3*handle + 2] = colour.blue
  FLAT_POOL



#[ Render Metrics ]#

proc nimRenderLineWidths(): seq[float32] {.exportc.} =
  ## Report `[least_point_diameter, furniture_line_width, object_line_width]`.
  ##   Browser's uniforms then draw at sizes desktop's `renderer.nim` does, without
  ##   hand-copied literal.
  @[DIAMETER_POINT_LEAST, WIDTH_LINE_FURNITURE, WIDTH_LINE_OBJECT]


proc nimPointCorners(): seq[float32] {.exportc.} = pointCorners()
  ## Report point quad's static corner buffer; see `mesh.pointCorners`.

proc nimShadeAmbient(): cfloat {.exportc.} = cfloat(FRACTION_AMBIENT_SHADE)
  ## Report lit point's night-side brightness, for point fragment shader's uniform.


proc nimRampTree(): seq[float32] {.exportc.} =
  ## Report diagnostics tree's colour ramp, six floats per step.
  ##   Row's label rgb then value rgb, `STEPS_RAMP_TREE` steps from sliver of frame to
  ##   half of it.
  ##   Exported as every derived value is: `ramp.nim` is table `tools/check_ramp`
  ##   regenerates from CET-I1, and second copy in presentation layer would drift.
  for i in 0 ..< STEPS_RAMP_TREE:
    let (label, value) = (RAMP_TREE_LABEL[i], RAMP_TREE_VALUE[i])
    result.add([
      float32(label[0]), float32(label[1]), float32(label[2]),
      float32(value[0]), float32(value[1]), float32(value[2]),
    ])


proc nimDiscCorners(): seq[float32] {.exportc.} =
  ## Report disc fan's static corner buffer, uploaded once at start-up.
  ##   `mesh.discCorners`, one source desktop uploads from too, so browser carries no
  ##   table drifting from `mesh.expandDiscVertex`.
  discCorners()


proc nimRingCorners(): seq[float32] {.exportc.} =
  ## Report ring's static corner buffer, uploaded once at start-up.
  ##   Same one-source rule as `nimDiscCorners`, against `mesh.expandRingVertex`.
  ringCorners()


proc nimDomeCorners(): seq[float32] {.exportc.} =
  ## Report dome's static unit-sphere corner buffer, uploaded once at start-up.
  ##   Same rule, against `mesh.expandDomeVertex`.
  domeCorners()


proc nimOverlayMetrics(): seq[float32] {.exportc.} =
  ## Report overlay's weights: line width, two alphas, label height, halo width and alpha.
  ##   In that order, as `[overlay_line_width, selected_alpha, hover_alpha, label_height,
  ##   halo_width, halo_alpha]`.
  ##   Browser's SVG overlay then strokes markers and drag rubber-band at weights
  ##   desktop's `visualiser.drawMarker` does, sizes name label's face to
  ##   `marker.HEIGHT_MARKER_LABEL` and its halo to `WIDTH_MARKER_LABEL_HALO` at
  ##   `ALPHA_MARKER_LABEL_HALO`.
  ##   Marker's size is not here: depends on shape marked, and comes back from
  ##   `nimSelectionMarker`.
  ##   Neither is orientation pulse's, shaped into outline `nimSelectionPulse` reports and
  ##   filled rather than stroked.
  @[
    WIDTH_MARKER, ALPHA_MARKER_SELECTED, ALPHA_MARKER_HOVER, float32(HEIGHT_MARKER_LABEL),
    float32(WIDTH_MARKER_LABEL_HALO), ALPHA_MARKER_LABEL_HALO,
  ]


proc ensurePlacement() =
  ## Refresh `PLACEMENTS`, whole placing side for every live handle, where scene has moved.
  ##   Placing side reads no camera, so camera move never reaches this; only edit does.
  ##   Called by frame build and by hover pick, which can run before build on frame where
  ##   scene has just changed, so whichever comes first fills it.
  if REVISION_PLACED == some(SCENE.revision): return
  # Re-place only handles stamped since last fill: one per edit, all after restore.
  #   Re-placing every handle per edit is whole frame at capacity; figures in
  #   `PROVENANCE.md`.
  for handle in 0 ..< SCENE.bound:
    let is_stale = REVISION_PLACED.isNone or
      SCENE.revisionPlacingAt(handle) > REVISION_PLACED.get
    if SCENE.isAlive(handle) and is_stale:
      PLACEMENTS[handle] = placeObject(
        SCENE.geometryOf(handle), SCENE.anchorOverrideAt(handle),
      )
  # Scene's reach moves with same edits, so far clip follows; see `camera.distanceFar`.
  #   Held here and stamped onto camera at each derivation point, never kept in camera:
  #   `home` and every path replacing camera value would drop it.
  REACH_SCENE = reachOf(PLACEMENTS, SCENE)
  # Suns move with same edits, so lights follow, as far as edit reached.
  refreshLights(LIGHTS, SCENE, PLACEMENTS, REVISION_PLACED)
  REVISION_PLACED = some(SCENE.revision)


proc ensureViewOverlay(width, height: int) =
  ## Refresh draw extent and view-projection overlay calls share.
  ##   `SCALE_OVERLAY` and `VIEW_PROJECTION_OVERLAY`, derived only when camera or viewport changed.
  ##   Every overlay call (anchor, each marker, each pulse, hover ring) would otherwise
  ##   derive both for itself, each derivation running `camera.frame`'s joins twice.
  ##     Within one frame all are same answer: functions of placement and viewport alone,
  ##     which is what key holds.
  ##   Callers read globals rather than copies: returning pair deep-copies `DrawExtent`
  ##   full of multivectors per call on JS backend, cache hit or not.
  CAMERA.reach_scene = REACH_SCENE # Stamped as frame build does; see `ensurePlacement`.
  let settings: SettingsOverlay = (
    CAMERA.pivot.x, CAMERA.pivot.y, CAMERA.pivot.z, CAMERA.distance,
    CAMERA.azimuth, CAMERA.elevation, CAMERA.degrees_field_of_view, CAMERA.reach_scene,
    width, height,
  )
  if SETTINGS_OVERLAY_HELD.isNone or SETTINGS_OVERLAY_HELD.get != settings:
    SETTINGS_OVERLAY_HELD = some(settings)
    SCALE_OVERLAY = CAMERA.drawExtentFor(height)
    VIEW_PROJECTION_OVERLAY = CAMERA.initMatrixViewProjection(float(width)/float(height))



#[ Camera ]#

proc nimCameraOrbit(turn, rise: cfloat) {.exportc.} =
  ## Rotate camera about its pivot by turn (azimuth) and rise (elevation), radians.
  TWEEN_CAMERA.abandon()
  camera.orbit(CAMERA, float(turn), float(rise))


proc nimCameraDolly(factor: cfloat) {.exportc.} =
  ## Scale camera's distance from pivot by factor.
  TWEEN_CAMERA.abandon()
  camera.dolly(CAMERA, float(factor))


proc nimCameraDollyCentred(factor: cfloat; width, height: cint) {.exportc.} =
  ## Scale camera's distance from pivot by factor, toward whatever frame's middle is over.
  ##   Pinch's zoom; see `interaction.dollyAtCentre`. Reads caches as `nimCameraDollyAt`.
  TWEEN_CAMERA.abandon()
  ensureViewOverlay(int(width), int(height))
  ensurePlacement()
  dollyAtCentre(
    CAMERA, SCENE, float(factor), SCALE_OVERLAY, VIEW_PROJECTION_OVERLAY,
    int(width), int(height), PLACEMENTS,
  )


proc nimCameraDollyAt(factor: cfloat; width, height: cint) {.exportc.} =
  ## Scale camera's distance from pivot by factor, toward whatever cursor is over.
  ##   See `interaction.dollyAtCursor`.
  ##   Reads cursor this build tracks (`nimUpdateCursor`), so caller aiming zoom (wheel at
  ##   pointer, pinch at midpoint) says where by moving cursor there first, as picking
  ##   does.
  TWEEN_CAMERA.abandon()
  # Read through overlay cache.
  #   Wheel arrives in bursts, and each notch would derive fresh extent and matrix for
  #   camera that only changes as result of notch.
  ensureViewOverlay(int(width), int(height))
  # Read through frame's placements.
  #   `dollyAtCursor` asks `anchorZoomAt` what cursor is over, which is full pick.
  ensurePlacement()
  INTERACTION.dollyAtCursor(
    CAMERA, SCENE, float(factor), SCALE_OVERLAY, VIEW_PROJECTION_OVERLAY,
    int(width), int(height), PLACEMENTS,
  )


proc nimCameraPan(across, up: cfloat) {.exportc.} =
  ## Slide camera's pivot sideways and vertically in its view plane.
  ##   Rate reading of pan, for caller with only step to give; `nimCameraPanAt` is what
  ##   drag uses.
  TWEEN_CAMERA.abandon()
  camera.pan(CAMERA, float(across), float(up))


proc nimCameraPanAt(
  before_x, before_y, after_x, after_y: cfloat; width, height: cint
) {.exportc.} =
  ## Slide view so world point under `before` comes to lie under `after`.
  ##   See `interaction.panAcross`.
  ##   Both ends of pointer's step rather than its length: grab needs where it started.
  TWEEN_CAMERA.abandon()
  panAcross(
    CAMERA, ScreenPosition(x: float(before_x), y: float(before_y)),
    ScreenPosition(x: float(after_x), y: float(after_y)), int(width), int(height),
  )


proc nimCameraAzimuth(): cfloat {.exportc.} = cfloat(CAMERA.azimuth)
  ## Report angle about world up, in radians.

proc nimCameraElevation(): cfloat {.exportc.} = cfloat(CAMERA.elevation)
  ## Report angle above horizontal plane, in radians.

proc nimCameraDistance(): cfloat {.exportc.} = cfloat(CAMERA.distance)
  ## Report distance from pivot, in world units.

proc nimCameraFov(): cfloat {.exportc.} = cfloat(CAMERA.degrees_field_of_view)
  ## Report vertical field of view, in degrees.

proc nimCameraPivot(): FlatBuffer {.exportc.} =
  ## Report point camera orbits around, as `[x, y, z]` view over `FLAT_TARGET`.
  ##   Refilled per call; camera fields' tick asks five times second and compares before
  ##   writing, so fresh sequence here was allocation per tick.
  FLAT_TARGET.fill3(cfloat(CAMERA.pivot.x), cfloat(CAMERA.pivot.y), cfloat(CAMERA.pivot.z))


proc nimCameraEye(): FlatBuffer {.exportc.} =
  ## Report where eye stands, as `[x, y, z]` view over `FLAT_EYE`.
  ##   Driven checks read sight line off eye and pivot, to tell zoom along it from
  ##   slide across it; nothing on page asks.
  let eye = CAMERA.eye
  FLAT_EYE.fill3(cfloat(eye.x), cfloat(eye.y), cfloat(eye.z))


proc nimSetCameraAzimuth(v: cfloat) {.exportc.} =
  ## Rewrite angle about world up, in radians.
  TWEEN_CAMERA.abandon()
  CAMERA.azimuth = float(v)


proc nimSetCameraElevation(v: cfloat) {.exportc.} =
  ## Rewrite angle above horizontal plane, in radians.
  ##   Clamped to bound `panel.layoutView`'s drag widget uses.
  TWEEN_CAMERA.abandon()
  CAMERA.elevation = clamp(float(v), -ELEVATION_LIMIT, ELEVATION_LIMIT)


proc nimSetCameraDistance(v: cfloat) {.exportc.} =
  ## Rewrite distance from pivot, in world units.
  ##   Held off one bound orbit distance has; see `camera.distanceHeld`.
  TWEEN_CAMERA.abandon()
  CAMERA.distance = distanceHeld(float(v))


proc nimSetCameraFov(v: cfloat) {.exportc.} = CAMERA.degrees_field_of_view = float(v)
  ## Rewrite vertical field of view, in degrees.

proc nimSetCameraPivot(x, y, z: cfloat) {.exportc.} =
  ## Rewrite point camera orbits around.
  TWEEN_CAMERA.abandon()
  CAMERA.pivot = Position(x: float(x), y: float(y), z: float(z))


proc nimCameraLimits(): seq[float32] {.exportc.} =
  ## Report bounds camera placement is held to, for caller offering numeric input.
  ##   Elevation either side of horizon, and one floor orbit distance has.
  ##   No third entry: nothing bounds how far out camera may orbit; see
  ##   `camera.DISTANCE_LIMIT_NEAR`.
  @[cfloat(ELEVATION_LIMIT), cfloat(DISTANCE_LIMIT_NEAR)]



#[ Picking And Drag ]#

const SLOT_NONE = -1'i32
  ## Cross `{.exportc.}` boundary as "no handle".
  ##   `cint` cannot carry `Option[int]` into JS, so every exported proc reporting optional
  ##   handle translates through this one constant at its return.
  ##   Everything on this side of that translation stays `Option[int]`.

proc nimUpdateCursor(x, y: cfloat) {.exportc.} =
  ## Forward to `interaction.updateCursor`.
  interaction.updateCursor(INTERACTION, float(x), float(y))


proc nimSetCameraDragging(is_dragging: bool) {.exportc.} =
  ## Say whether pointer gesture is moving camera right now.
  ##   Orbit or pan drag, or two fingers on canvas.
  ##   What that means for hover is `interaction.updateHover`'s to say.
  INTERACTION.is_dragging_camera = is_dragging


proc nimUpdateHover(width, height: cint) {.exportc.} =
  ## Forward to `interaction.updateHover`.
  # Charge to record rather than phase.
  #   Runs from event handler, so frame reporting it is next one.
  #   Accumulated: pointer can move many times between two frames.
  let ms_entered_hover = nowMilliseconds()
  # Read through overlay cache.
  #   Each move would rebuild view matrix for camera that cannot have changed, since
  #   hover skips while camera moves.
  ensureViewOverlay(int(width), int(height))
  # Read through frame's placements, so pick ranks what was drawn.
  #   `ensurePlacement` first, since pick can be first of two to run after edit.
  ensurePlacement()
  interaction.updateHover(
    INTERACTION, SCENE, CAMERA, SCALE_OVERLAY, VIEW_PROJECTION_OVERLAY,
    int(width), int(height), PLACEMENTS,
  )
  recordThisFrame().ms_hover_pick += nowMilliseconds() - ms_entered_hover


proc nimHoverHandle(): cint {.exportc.} =
  ## Report handle hovered, or `SLOT_NONE` where nothing is.
  if INTERACTION.index_hover.isSome: cint(INTERACTION.index_hover.get) else: SLOT_NONE


proc nimIsHoverBackdrop(): bool {.exportc.} = INTERACTION.is_hover_backdrop
  ## Report whether hovered object is plane at horizon.

proc nimCanTouchConstruct(): bool {.exportc.} = INTERACTION.canConstructByTouch
  ## Report whether finger's press where it stands may become construction drag.
  ##   Same answer `beginDrag` gives touch at slop; see `interaction.canConstructByTouch`.

proc nimHoverRivals(): cint {.exportc.} = cint(INTERACTION.count_hover_rivals)
  ## Report how many objects of hovered object's rank stood in reach; for driven checks.
  ## Report whether finger's press where it stands may become construction drag.
  ##   Same answer `beginDrag` gives touch at slop; see `interaction.canConstructByTouch`.
  ## Report whether what is hovered is whole sky, plane at horizon.
  ##   True wherever nothing else is under pointer and such plane is in scene.
  ##   One hovered thing that must not act like one: starts no drag (see
  ##   `interaction.beginDrag`), and tap on it means "empty space" to touch flow.

proc nimClearHover() {.exportc.} =
  ## Discard whatever is hovered.
  ##   Touch has no continuous pointer position: `nimUpdateHover` runs only at touch-down
  ##   point, so once finger lifts last reading would sit stale and hover ring would keep
  ##   drawing, reading as second selected object.
  INTERACTION.index_hover = none(int)


proc nimSelectionHandles(): seq[int] {.exportc.} =
  ## List picked handles in pick order.
  ##   `refreshOverlay` rings each, object rows tick their checkboxes.
  for position in 0 ..< SELECTION.len: result.add(SELECTION.at(position))


proc nimSelectionCount(): cint {.exportc.} = cint(SELECTION.len)
  ## Count picked objects.

proc nimSelectionArity(): cint {.exportc.} = cint(ord(SELECTION.impliedArity))
  ## Report arity current selection implies; see `selection.impliedArity`.
  ##   Matches `nimOperationArity`'s convention: 0 unary, 1 binary.

proc nimSelectOnly(handle: cint) {.exportc.} = SELECTION.selectOnly(int(handle))
  ## Replace whole selection with one handle.

proc nimSelectToggle(handle: cint) {.exportc.} = SELECTION.toggle(int(handle))
  ## Add handle to end of selection, or drop it where already picked.
  ##   Pick order names operands m and n.

proc nimPickByPointer(handle: cint) {.exportc.} =
  ## Note that `handle` was just picked by pointer standing at `INTERACTION.cursor`.
  ##   Camera then keeps it under pointer as it comes in; see `framing.PointerPick`.
  ##   Beside `nimSelectOnly`/`nimSelectToggle` rather than folded into them: list and
  ##   keyboard pick through those too, with no pointer to hold.
  POINTER_PICK = some(PointerPick(handle: int(handle), cursor: INTERACTION.cursor))


proc nimSelectClear() {.exportc.} = SELECTION.clear()
  ## Drop every pick.

proc nimSelectionAllHidden(): bool {.exportc.} =
  ## Forward to `selection.isAllHidden`.
  SELECTION.isAllHidden(SCENE)


proc nimAnimationMilliseconds(): cint {.exportc.} = cint(ANIMATION_MILLISECONDS)
  ## Report how long this build eases animation for.
  ##   Same `mesh` constant added object grows over, so presentation layer's transitions
  ##   run to it.

proc nimUndo(): bool {.exportc.} =
  ## Move scene back one step on its edit timeline; report whether there was earlier step.
  ##   Puts view back where that step was made from.
  ##   Clears selection on success, since restored snapshot's handle numbers may not match.
  ##   Abandons standing camera tween too, or aim it carried drags view off placement just
  ##   restored; same pairing `panel.stepHistory` makes.
  result = HISTORY.undo(SCENE, CAMERA)
  if result:
    SELECTION.clear()
    TWEEN_CAMERA.abandon()


proc nimRedo(): bool {.exportc.} =
  ## Move scene forward one step on its edit timeline; report whether there was later step.
  ##   View and all; clears selection and abandons tween as `nimUndo` does.
  result = HISTORY.redo(SCENE, CAMERA)
  if result:
    SELECTION.clear()
    TWEEN_CAMERA.abandon()


proc nimCanUndo(): bool {.exportc.} =
  ## Report whether `nimUndo` would move anywhere, so UI can disable its undo button.
  HISTORY.canUndo


proc nimCanRedo(): bool {.exportc.} =
  ## Report whether `nimRedo` would move anywhere, mirroring `nimCanUndo`.
  HISTORY.canRedo


proc nimDragKindForButton(dom_button: cint): cint {.exportc.} =
  ## Say what pointer button starts.
  ##   `SLOT_NONE` for no drag, otherwise ordinal of `interaction.MenuArming` drag from
  ##   that button carries.
  ##   Only numbering is this build's own: `PointerEvent.button` counts 0 left, 1 middle,
  ##   2 right; each render path translates into `interaction.PointerButton` and asks one
  ##   shared rule.
  let button = case dom_button
    of 0: some(PointerButton.Left)
    of 1: some(PointerButton.Middle)
    of 2: some(PointerButton.Right)
    else: none(PointerButton)
  if button.isNone: return SLOT_NONE
  let arming = armingOf(button.get)
  if arming.isNone: SLOT_NONE else: cint(ord(arming.get))


proc nimRevealsMenuOnButton(dom_button: cint): bool {.exportc.} =
  ## Say whether click of this pointer button brings selection menu up with it.
  ##   Same translation as `nimDragKindForButton`; what button means is `interaction`'s.
  case dom_button
  of 0: revealsMenuOn(PointerButton.Left)
  of 1: revealsMenuOn(PointerButton.Middle)
  of 2: revealsMenuOn(PointerButton.Right)
  else: false


proc nimRevealsWithoutPicking(has_selection, is_menu_shown: bool): bool {.exportc.} =
  ## Say whether menu-revealing click should only reveal, leaving selection alone.
  ##   Forwards to `interaction.revealsWithoutPicking`; desktop asks identical question.
  revealsWithoutPicking(has_selection, is_menu_shown)


proc nimHelpEntries(): seq[cstring] {.exportc.} =
  ## Report every help entry flat, four strings each.
  ##   Tab, action, outcome, and `"touch"` or `""`.
  ##   Flat rather than array of records, as `nimSelectionMarker` is: object crossing this
  ##   boundary is second shape to keep in step.
  ##   Entries are `help.lut_help_entries`, which desktop panel renders too.
  for entry in lut_help_entries:
    result.add([
      cstring(titleOf(entry.path)), cstring(entry.action), cstring(entry.outcome),
      cstring(if entry.is_touch: "touch" else: ""),
    ])


proc nimHelpDescriptions(): seq[cstring] {.exportc.} =
  ## Report what each tab is about, flat, two strings each.
  ##   Tab's title and its one-line description.
  ##   Own export rather than fifth string on `nimHelpEntries`, which is per row.
  ##   Keyed by title entries carry, so presentation layer joins on string it groups rows
  ##   by.
  for path in HelpPath:
    result.add([cstring(titleOf(path)), cstring(descriptionOf(path))])


proc nimBeginHold(handle: cint, now: cfloat) {.exportc.} =
  ## Forward to `interaction.beginHold`.
  interaction.beginHold(INTERACTION, int(handle), float(now))


proc nimCancelHold() {.exportc.} =
  ## Forward to `interaction.cancelHold`.
  interaction.cancelHold(INTERACTION)


proc nimHoldHandle(): cint {.exportc.} =
  ## Report which object press in progress is filling, or `SLOT_NONE` where none is.
  if INTERACTION.hold.isSome: cint(INTERACTION.hold.get.handle) else: SLOT_NONE


proc nimTakeMaturedHold(now: cfloat): cint {.exportc.} =
  ## Forward to `interaction.takeHold`.
  ##   Handle matured hold selects, reported exactly once, or `SLOT_NONE` where nothing to
  ##   take.
  ##   One question rather than "is it mature" beside caller's flag; see `takeHold`.
  let taken = interaction.takeHold(INTERACTION, float(now))
  if taken.isNone: SLOT_NONE else: cint(taken.get)


proc nimReleaseHold(now: cfloat) {.exportc.} =
  ## Forward to `interaction.releaseHold`.
  interaction.releaseHold(INTERACTION, float(now))


proc nimSwellHold(now: cfloat): cfloat {.exportc.} =
  ## Forward to `interaction.swellHold`.
  cfloat(interaction.swellHold(INTERACTION, float(now)))


proc nimIsHoldSpent(now: cfloat): bool {.exportc.} =
  ## Forward to `interaction.isHoldSpent`.
  interaction.isHoldSpent(INTERACTION, float(now))


proc nimHoldProgress(now: cfloat): cfloat {.exportc.} =
  ## Forward to `interaction.progressHold`.
  ##   Exported rather than left to subtraction in presentation layer: how long hold takes
  ##   is rule about gesture.
  cfloat(progressHold(INTERACTION, float(now)))


proc nimHoldMature(now: cfloat): bool {.exportc.} =
  ## Forward to `interaction.isHoldMature`.
  isHoldMature(INTERACTION, float(now))


func keyFor(code: string): Option[Key] =
  ## Translate one DOM `KeyboardEvent.code` into key view knows it by, if it is one.
  ##   `code`, not `key`: names physical key, as desktop's scancodes do, so W is same key
  ##   under hand on every layout.
  ##     `key` binds browser to whatever layout prints (AZERTY names desktop's Z) and
  ##     changes under shift, which means "faster".
  ##   What each key does is `interaction.motionFor` and `interaction.actionFor`'s.
  case code
  of "KeyW": some(Key.W)
  of "KeyA": some(Key.A)
  of "KeyS": some(Key.S)
  of "KeyD": some(Key.D)
  of "KeyQ": some(Key.Q)
  of "KeyE": some(Key.E)
  of "KeyF": some(Key.F)
  of "ShiftLeft", "ShiftRight": some(Key.Shift)
  of "ArrowLeft": some(Key.Left)
  of "ArrowRight": some(Key.Right)
  of "ArrowUp": some(Key.Up)
  of "ArrowDown": some(Key.Down)
  of "BracketLeft": some(Key.BracketLeft)
  of "BracketRight": some(Key.BracketRight)
  of "Minus": some(Key.Minus)
  # Map `Equal` to plus: physical key most layouts print `+` on carries `=`.
  of "Equal": some(Key.Plus)
  of "Enter": some(Key.Enter)
  of "Home": some(Key.Home)
  else: none(Key)


proc nimKeyBound(code: cstring): bool {.exportc.} =
  ## Report whether view answers this key at all.
  ##   Caller then knows whether to keep browser's default for it: arrow scrolling page
  ##   under canvas is case that matters.
  keyFor($code).isSome


proc nimKeyDown(code: cstring): cint {.exportc.} =
  ## Take one key press; report handle caller should select, or `SLOT_NONE`.
  ##   Holds it for `nimDriveHeld`, and carries out whatever it does at press.
  ##   One entry point for both kinds of binding, so browser scripts carries no opinion about
  ##   which keys move view.
  ##   Idempotent on key already down, which is what auto-repeat sends; re-run action is
  ##   harmless for all four.
  let key = keyFor($code)
  if key.isNone: return SLOT_NONE
  INTERACTION.holdKey(key.get)
  let action = actionFor(key.get)
  if action.isNone:
    # Abandon tween: key moving camera is camera move like any other.
    TWEEN_CAMERA.abandon()
    return SLOT_NONE
  let handle = applyAction(INTERACTION, CAMERA, SCENE, action.get)
  # Let go of goal standing offer holds, so next frame aims afresh.
  #   Framing is standing offer's job (`framing.offerAim`).
  if action.get == KeyAction.FrameSelection: TWEEN_CAMERA.release()
  else: TWEEN_CAMERA.abandon()
  if handle.isNone: SLOT_NONE else: cint(handle.get)


proc nimKeyUp(code: cstring) {.exportc.} =
  ## Take one key release, so whatever it was moving stops.
  let key = keyFor($code)
  if key.isSome: INTERACTION.releaseKey(key.get)


proc nimReleaseKeysAll() {.exportc.} =
  ## Let go of every held key, for page that has stopped being told about releases.
  ##   Window losing focus, tab going to background; without it camera moves forever.
  INTERACTION.releaseKeysAll()


proc nimDriveHeld(seconds: cfloat) {.exportc.} =
  ## Move camera by every held key, for one frame of `seconds`.
  ##   See `interaction.driveHeld`.
  ##   Abandons tween only when something is held, so frame with no key down leaves ease
  ##   alone.
  if INTERACTION.keys_held.len == 0: return
  INTERACTION.driveHeld(CAMERA, float(seconds))
  TWEEN_CAMERA.abandon()


proc nimFocusHandle(): cint {.exportc.} =
  ## Report which object keyboard stands on, or `SLOT_NONE`.
  if INTERACTION.index_focus.isSome: cint(INTERACTION.index_focus.get) else: SLOT_NONE


proc nimTapSlop(): cfloat {.exportc.} = cfloat(PIXELS_TAP_SLOP)
  ## Report how far press may move and still be press; see `interaction.PIXELS_TAP_SLOP`.

proc nimBeginPress(now: cfloat) {.exportc.} =
  ## Forward to `interaction.beginPress`; every press goes through it, camera ones too.
  interaction.beginPress(INTERACTION, float(now))


proc nimIsClick(now: cfloat): bool {.exportc.} =
  ## Forward to `interaction.isClick`.
  ##   Reached directly only for press over empty space, which begins no drag and has no
  ##   `nimEndDrag` to report through.
  isClick(INTERACTION, float(now))


proc nimBeginDrag(arming_ordinal: cint, now: cfloat): bool {.exportc.} =
  ## Forward to `interaction.beginDrag`.
  ##   Arming as ordinal rather than flag: three of them, two reachable from mouse.
  ##   `nimDragArmingOnDwell` names one touch uses.
  let arming = MenuArming(clamp(int(arming_ordinal), ord(low(MenuArming)), ord(high(MenuArming))))
  interaction.beginDrag(INTERACTION, arming, float(now))


proc nimDragArmingOnDwell(): cint {.exportc.} =
  ## Report arming pointer with no second button starts drag with: touch alone.
  ##   Exported rather than literal in glue: enum reordered in `interaction.nim` must not
  ##   leave number here meaning something else.
  cint(ord(MenuArming.OnDwell))


proc nimUpdateDrag(now: cfloat) {.exportc.} =
  ## Forward to `interaction.updateDrag`.
  ##   Once per frame, after `nimUpdateHover`, before frame reading preview is built,
  ##   order `visualiser.renderFrame` runs them in.
  interaction.updateDrag(INTERACTION, SCENE, float(now))


proc nimCancelDrag() {.exportc.} =
  ## Forward to `interaction.cancelDrag`.
  interaction.cancelDrag(INTERACTION)


proc nimDragActive(): bool {.exportc.} = INTERACTION.is_dragging
  ## Report whether drag is in progress.

proc nimDragSourceHandle(): cint {.exportc.} = cint(INTERACTION.index_source)
  ## Report object drag started from; meaningful only while `nimDragActive()`.
  ##   Mirrors `interaction.index_source`, field already paired with that guard.

proc nimDragTint(): FlatBuffer {.exportc.} =
  ## Report colour rubber-band wears right now, as `[r, g, b]` triple.
  ##   From `interaction.inkOfDrag`, so this file keeps no copy of operation-to-ink table.
  ##   View over `FLAT_TINT`, refilled per frame of drag.
  # Bind ink, not colour: `colour` is `lent`, and bound to `let` it copies (read in emitted
  #   JS); read inline three times instead.
  let ink = inkOfDrag(INTERACTION, SCENE.inkNext)
  FLAT_TINT.fill3(ink.colour.red, ink.colour.green, ink.colour.blue)


proc nimDragComet(width, height: cint): FlatBuffer {.exportc.} =
  ## Report drag band's head flat, `[x0, y0, x1, y1, ...]`, as one closed outline.
  ##   For overlay to fill over band.
  ##   View over `FLAT_COMET`, refilled per frame of drag.
  ##   Shaped by `marker.cometFor`, aimed from where drag source is drawn (plane's creation
  ##   anchor included) at this module's cursor rather than presentation layer's.
  ##     Geometry belongs on side owning gesture.
  ##   Empty where no drag is in flight, source's anchor is behind eye, or cursor rests on
  ##   anchor.
  if not INTERACTION.is_dragging: return FLAT_COMET.emptied
  # Read through overlay cache and by-handle readers.
  #   Runs per frame of every drag; fresh extent and matrix plus whole-scene copy through
  #   `SCENE[handle]` would be paid each time.
  ensureViewOverlay(int(width), int(height))
  let anchor = anchorFor(
    SCENE.geometryOf(INTERACTION.index_source),
    SCENE.anchorOverrideAt(INTERACTION.index_source), SCALE_OVERLAY,
  )
  if anchor.isNone: return FLAT_COMET.emptied
  let screen = projectToScreen(VIEW_PROJECTION_OVERLAY, int(width), int(height), anchor.get)
  if not screen.isInFront: return FLAT_COMET.emptied
  let comet = cometFor(screen, INTERACTION.cursor)
  if comet.isNone: return FLAT_COMET.emptied
  for i, point in comet.get:
    FLAT_COMET[2*i] = float32(point.x)
    FLAT_COMET[2*i + 1] = float32(point.y)
  FLAT_COMET.used = 2*len(comet.get)
  FLAT_COMET.view


proc nimMenuMetrics(): seq[float32] {.exportc.} =
  ## Report sizes choice menu is drawn at.
  ##   Wedge height, label padding, corner rounding, border thickness, centre-dot radius,
  ##   opacity of offered wedge then unoffered one.
  ##   Same arrangement `nimOverlayMetrics` uses for marker's sizes.
  @[
    float32(HEIGHT_MENU_WEDGE), float32(PADDING_MENU_WEDGE),
    float32(ROUNDING_MENU_WEDGE), float32(WIDTH_MENU_WEDGE_BORDER),
    float32(RADIUS_MENU_CENTRE),
    float32(ALPHA_MENU_WEDGE), float32(ALPHA_MENU_UNOFFERED),
  ]


proc nimDragMenuOpen(): bool {.exportc.} = INTERACTION.menu.isSome
  ## Report whether choice menu is open on drag in progress.

proc nimDragMenuCentre(): FlatBuffer {.exportc.} =
  ## Report where open menu is centred, in canvas pixels, or empty where none is.
  ##   View over `FLAT_MENU_CENTRE`, refilled per frame menu is open.
  if INTERACTION.menu.isNone: return FLAT_MENU_CENTRE.emptied
  FLAT_MENU_CENTRE.fill2(float32(INTERACTION.menu.get.x), float32(INTERACTION.menu.get.y))


proc nimDragMenuLabels(): seq[cstring] {.exportc.} =
  ## Name every wedge, in `DragChoice` order, order layout below is in.
  for choice in DragChoice: result.add(cstring(labelOf(choice)))


proc nimDragMenuLayout(): FlatBuffer {.exportc.} =
  ## Lay open menu out, three floats per wedge in `DragChoice` order.
  ##   Centre x and y in canvas pixels, then offered as 1 or 0.
  ##   Flat as `nimSelectionMarker` is, view over `FLAT_MENU` refilled per frame menu is
  ##   open.
  ##   No hue: label wears `--ink`; `interaction.inkOf` answers for rubber-band and
  ##   drawer's legend.
  ##   Empty where no menu is open.
  if INTERACTION.menu.isNone: return FLAT_MENU.emptied
  let
    centre = INTERACTION.menu.get
    over = destinationOf(INTERACTION)
    is_pair_live =
      over.isSome and over.get != INTERACTION.index_source and
      SCENE.isAlive(over.get) and SCENE.isAlive(INTERACTION.index_source)
  for choice in DragChoice:
    let
      at = anchorOf(centre, choice)
      is_offered =
        choice == DragChoice.More or
        (is_pair_live and isOffered(
          choice, SCENE.geometryOf(INTERACTION.index_source),
          SCENE.geometryOf(over.get),
        ))
    let base = 3*ord(choice)
    FLAT_MENU[base] = float32(at.x)
    FLAT_MENU[base + 1] = float32(at.y)
    FLAT_MENU[base + 2] = float32(ord(is_offered))
  FLAT_MENU.used = 3*(ord(DragChoice.high) + 1)
  FLAT_MENU.view


proc nimDragMenuHighlighted(): cint {.exportc.} =
  ## Report which wedge cursor stands in as `DragChoice` ordinal, or `SLOT_NONE` at centre.
  ##   From `interaction.choosing`, same call release resolves through and preview is shaped
  ##   from.
  let choice = INTERACTION.choosing
  if choice.isNone: SLOT_NONE else: cint(ord(choice.get))


type DragResult = object ## Define what ending drag produced.
  created_handle: cint ## Handle added, or `SLOT_NONE` where nothing was.
    ## Over empty space, on own source, on pair making nothing, or on `more…`.
  message: cstring ## Outcome, for display as desktop panel's status line.
  is_more: bool ## Whether release chose `more…`.
    ## Builds nothing and leaves both operands selected for apply section.
  clicked_handle: cint ## Object press that never became drag came down on.
    ## `SLOT_NONE` for every actual drag.
    ## Caller selects it, alone or added where shift is held.


proc nimEndDrag(now: cfloat): DragResult {.exportc.} =
  ## End drag in progress, applying whatever release resolved to.
  ##   Straight into `interaction.endDrag` for everything it reports, adding only this
  ##   build's business: birth clock, selection, history entry.
  ##   `scene.toText` reads labels same on both backends; `$toCstring` is empty under JS.
  let outcome = interaction.endDrag(INTERACTION, SCENE, float(now))
  if outcome.index_clicked.isSome:
    # Report press that never moved rather than act on it.
    #   Replace or join selection is shift key's to say, and caller reads that.
    return DragResult(
      created_handle: SLOT_NONE,
      clicked_handle: cint(outcome.index_clicked.get),
    )
  if outcome.index_created.isSome:
    let handle = outcome.index_created.get
    stampBorn(handle, float(now))
    SELECTION.selectOnly(handle)
    HISTORY.record(SCENE, CAMERA)
    return DragResult(
      created_handle: cint(handle),
      message: cstring(outcome.message),
      clicked_handle: SLOT_NONE,
    )
  if outcome.choice == some(DragChoice.More) and outcome.operands.isSome:
    # Select both operands in drag order, which apply section reads as m then n.
    #   Way out of gesture's three operations into rest of catalogue.
    SELECTION.selectOnly(outcome.operands.get.source)
    SELECTION.toggle(outcome.operands.get.destination)
    return DragResult(
      created_handle: SLOT_NONE,
      message: cstring(outcome.message),
      is_more: true,
      clicked_handle: SLOT_NONE,
    )
  DragResult(
    created_handle: SLOT_NONE,
    message: cstring(outcome.message),
    clicked_handle: SLOT_NONE,
  )


proc nimGridMetrics(width, height: cint): FlatBuffer {.exportc.} =
  ## Report `[size_cell, world_per_pixel]` for ground grid as drawn right now.
  ##   View over `FLAT_GRID`, refilled per frame.
  ##   Cell's size in world units, and how much world one screen pixel spans at height
  ##   grid is laid at.
  ##   `[0, 0]` where no ground is drawn (eye above fog's reach), read as "no scale to
  ##   show".
  ##   Exported as `nimRenderLineWidths` is: number reader is shown has to be number grid
  ##   was built with; both from `mesh.sizeCellGridAt`, which `addGrid` reads.
  ##   Through `ensureViewOverlay`, so extent is overlay's own, built at CSS height.
  ##     Scale bar is drawn in pixels pointer works in; see browser scripts.
  ensureViewOverlay(int(width), int(height))
  template scale: DrawExtent = SCALE_OVERLAY
  let size_cell = sizeCellGridAt(scale.extentFurniture, scale)
  if size_cell.isNone: return FLAT_GRID.fill2(0.0'f32, 0.0'f32)
  # Measure at ground point below eye, where reported cell is laid.
  #   Pixel spans more world further away.
  let below = position(wedgeAnti(
    wedge(scale.eye_point, toMultivector(Direction(x: 0, y: 0, z: -1))), groundPlane()
  ))
  # Pass place straight through, since `Position` bound to `let` is `nimCopy` per frame.
  #   Read in emitted JS.
  let world_per_pixel =
    if below.isSome: worldPerPixelAt(below.get, scale) else: worldPerPixelAt(scale.eye, scale)
  FLAT_GRID.fill2(float32(size_cell.get), float32(world_per_pixel))


proc nimAnchorScreen(handle, width, height: cint): FlatBuffer {.exportc.} =
  ## Project object's representative point onto screen pixels, as `[x, y, is_in_front]`.
  ##   View over `FLAT_ANCHOR`, refilled per call: asked per frame for band's source and
  ##   for menu's anchor.
  ##   Point `mesh.anchorFor` and `visualiser.drawInteractionOverlay` use, so browser's
  ##   hover ring and drag rubber-band draw as 2D overlay where desktop draws them.
  ##   Object's drawn centre, through anchor-aware `anchorFor`.
  ##     Plane's disc is centred on stored creation anchor, so band answering from support
  ##     would meet plane nowhere on circle.
  ##   `is_in_front` is 0 or 1: caller draws nothing where 0, matching
  ##   `picking.isInFront`.
  ##     Also 0 where handle no longer holds live object, since every caller reads handle
  ##     carried across frames that can go stale when object is removed.
  ##   Plane at horizon reports middle of view: it has no place in scene, so menu goes to
  ##   centre of frame `marker.markerFrame` draws around it.
  ##   Duplicated by constraint in `visualiser.anchorOfSelection`; fix both or neither.
  if not SCENE.isAlive(int(handle)): return FLAT_ANCHOR.fill3(0.0'f32, 0.0'f32, 0.0'f32)
  if SCENE.geometryOf(int(handle)).isHorizonPlane:
    return FLAT_ANCHOR.fill3(0.5'f32*float32(width), 0.5'f32*float32(height), 1.0'f32)
  ensureViewOverlay(int(width), int(height))
  # Read by handle, never `SCENE[handle]`.
  #   `Object` holds `Scene` by value on JS backend, so constructing one copies whole scene.
  let anchor = anchorFor(
    SCENE.geometryOf(int(handle)), SCENE.anchorOverrideAt(int(handle)), SCALE_OVERLAY
  )
  if anchor.isNone: return FLAT_ANCHOR.fill3(0.0'f32, 0.0'f32, 0.0'f32)
  let screen = projectToScreen(VIEW_PROJECTION_OVERLAY, int(width), int(height), anchor.get)
  FLAT_ANCHOR.fill3(
    float32(screen.x), float32(screen.y), (if screen.isInFront: 1.0'f32 else: 0.0'f32)
  )


proc nimAnchorWorld(handle: cint): FlatBuffer {.exportc.} =
  ## Report object's representative point in world, as `[x, y, z, is_placed]`.
  ##   Same point `nimAnchorScreen` projects, before projection; driven checks read
  ##   depth of zoomed-onto object off it. `is_placed` 0 for dead handle and for plane at
  ##   horizon, which stands nowhere.
  if not SCENE.isAlive(int(handle)) or SCENE.geometryOf(int(handle)).isHorizonPlane:
    return FLAT_ANCHOR_WORLD.fill3(0.0'f32, 0.0'f32, 0.0'f32)
  ensurePlacement()
  let anchor = anchorFor(
    SCENE.geometryOf(int(handle)), SCENE.anchorOverrideAt(int(handle)), SCALE_OVERLAY
  )
  if anchor.isNone: return FLAT_ANCHOR_WORLD.fill3(0.0'f32, 0.0'f32, 0.0'f32)
  FLAT_ANCHOR_WORLD.fill3(float32(anchor.get.x), float32(anchor.get.y), float32(anchor.get.z))


proc nimSelectionMarker(
  handle, width, height: cint; progress: cfloat; is_touch: bool; swell: cfloat = 0.0
): seq[float32] {.exportc.} =
  ## Kind this object's selection/hover marker and report it flat, for SVG overlay to stroke.
  ##   `[kind, first, second, third, x0, y0, x1, y1, ...]`.
  ##   `kind` is `marker.MarkerKind`'s ordinal; three header handles after it mean whatever
  ##   that kind needs, so overlay reads fixed prefix then points:
  ##
  ##   | Kind      | first        | second        | third         | Points               |
  ##   |-----------|--------------|---------------|---------------|----------------------|
  ##   | 0 `Ring`  | --           | radius        | swept fraction| centre               |
  ##   | 1 `Rails` | --           | --            | --            | two per drawn piece  |
  ##   | 2 `Loop`  | closed       | --            | --            | around plane         |
  ##   | 3 `Bands` | first closed | first's count | second closed | both bands, in order |
  ##   | 4 `Frame` | closed       | --            | --            | around view          |
  ##
  ##   Point count is whatever is left, except `Bands`, which carries two runs and says
  ##   where first ends.
  ##   `is_touch` says finger is holding and `swell` how far clear of it outline stands.
  ##     `nimSwellHold`'s answer, on its own clock; see `interaction.swellHold`.
  ##   `progress` draws marker part-built for press maturing into selection; pass 1 for
  ##   finished one.
  ##     What partial marker looks like is `marker.markerFor`'s decision.
  ##   Empty where nothing to draw: dead handle, or geometry with no shape.
  ##     Callers read handle carried across frames, so any can go stale when object is removed.
  if not SCENE.isAlive(int(handle)): return
  ensureViewOverlay(int(width), int(height))
  # Kind with handle's current travel, though this call reports no pulse.
  #   Outline is identical either way, and shaping whole marker once lets
  #   `nimSelectionPulse` reuse it.
  #   Clock is not advanced here; that stays pulse call's job.
  let travel = CLOCK_PULSE.travelAt(int(handle))
  # Kind straight into shared box pulse call reads back.
  #   Nothing allocates or copies `Marker`.
  if not markerFor(
    SCENE.geometryOf(int(handle)), SCENE.anchorOverrideAt(int(handle)), SCENE.radiusAt(int(handle)),
    SCALE_OVERLAY, CAMERA, VIEW_PROJECTION_OVERLAY, int(width), int(height), BOX_MARKER[],
    float(progress), is_touch, travel = some(travel), swell = float(swell),
  ):
    MARKER_SHAPED = none(ShapedMarker)
    return

  template marker: Marker = BOX_MARKER[]
  MARKER_SHAPED = some((
    int(handle), int(width), int(height), float(progress), is_touch, float(swell),
    travel, SETTINGS_OVERLAY_HELD.get, BOX_MARKER,
  ))
  result = @[cfloat(ord(marker.kind)), 0.0'f32, 0.0'f32, 0.0'f32]
  case marker.kind
  of MarkerKind.Ring:
    result[2] = cfloat(marker.radius)
    result[3] = cfloat(marker.fraction)
    result.add([cfloat(marker.centre.x), cfloat(marker.centre.y)])
  of MarkerKind.Rails:
    for i in 0 ..< marker.count_segment:
      for point in marker.segments[i]:
        result.add([cfloat(point.x), cfloat(point.y)])
  of MarkerKind.Loop:
    result[1] = (if marker.is_closed: 1.0'f32 else: 0.0'f32)
    for i in 0 ..< marker.count_point:
      result.add([cfloat(marker.points[i].x), cfloat(marker.points[i].y)])
  of MarkerKind.Bands:
    result[1] = (if marker.are_closed_band[0]: 1.0'f32 else: 0.0'f32)
    result[2] = cfloat(marker.counts_band[0])
    result[3] = (if marker.are_closed_band[1]: 1.0'f32 else: 0.0'f32)
    for side in 0 .. 1:
      for i in 0 ..< marker.counts_band[side]:
        result.add([
          cfloat(marker.points_band[side][i].x), cfloat(marker.points_band[side][i].y)
        ])
  of MarkerKind.Frame:
    result[1] = 1.0'f32 # Always closed: frame is screen space, never cut by eye.
    for i in 0 ..< marker.count_frame:
      result.add([cfloat(marker.points_frame[i].x), cfloat(marker.points_frame[i].y)])


proc nimTickPulse(now: cfloat) {.exportc.} =
  ## Take frame's clock reading for every orientation pulse on screen.
  ##   Once per frame, before any `nimSelectionPulse`, so each selected object advances by
  ##   same step; clock ticked per call would hand whole step to first handle asked.
  SECONDS_STEP_PULSE = CLOCK_PULSE.secondsStep(float(now))
  CLOCK_PULSE.tick(float(now))


proc nimSelectionLabelAt(handle, width, height: cint): FlatBuffer {.exportc.} =
  ## Report where this object's name label goes, over `FLAT_LABEL`.
  ##   Six floats: `[x, y, is_shown, is_beside, away_x, away_y]`.
  ##   Place is marker's own (`marker.Marker.label_at`), so label sits above outline
  ##   actually drawn, swollen or not. Reads marker `nimSelectionMarker` just shaped for
  ##   this handle wherever it stands in `MARKER_SHAPED`, and shapes plain one otherwise.
  ##   `is_shown` 0 for dead handle, no marker, or outline with no top to sit above.
  ##   `is_beside` 1 where `x, y` is anchor on line and glue pushes label off it along
  ##   `away` by `nimLabelClearance`, measured with its own text; see
  ##   `marker.Marker.is_label_beside`.
  if not SCENE.isAlive(int(handle)):
    return FLAT_LABEL.fill6(0.0'f32, 0.0'f32, 0.0'f32, 0.0'f32, 0.0'f32, 0.0'f32)
  ensureViewOverlay(int(width), int(height))
  let at = int(handle) ## Handle as scene indexes it, read once for every reader below.
  var held = (ref Marker)(nil)
  if MARKER_SHAPED.isSome:
    let stored = MARKER_SHAPED.get
    if stored.handle == at and stored.width == int(width) and
        stored.height == int(height):
      held = stored.marker
  if held == nil:
    MARKER_SHAPED = none(ShapedMarker)
    held = BOX_MARKER
    if not markerFor(
      SCENE.geometryOf(at), SCENE.anchorOverrideAt(at), SCENE.radiusAt(at),
      SCALE_OVERLAY, CAMERA, VIEW_PROJECTION_OVERLAY, int(width), int(height), held[],
    ): return FLAT_LABEL.fill6(0.0'f32, 0.0'f32, 0.0'f32, 0.0'f32, 0.0'f32, 0.0'f32)
  template marker: Marker = held[]
  if not marker.has_label:
    return FLAT_LABEL.fill6(0.0'f32, 0.0'f32, 0.0'f32, 0.0'f32, 0.0'f32, 0.0'f32)
  FLAT_LABEL.fill6(
    float32(marker.label_at.x), float32(marker.label_at.y), 1.0'f32,
    float32(ord(marker.is_label_beside)), float32(marker.label_away_x),
    float32(marker.label_away_y),
  )


proc nimLabelClearance(away_x, away_y, half_width: cfloat): cfloat {.exportc.} =
  ## Report how far label centre stands off line along `away`; see `marker.clearanceBeside`.
  ##   `half_width` is glue's measured text, half.
  cfloat(clearanceBeside(float(away_x), float(away_y), float(half_width)))


proc nimSelectionPulse(
  handle, width, height: cint; progress: cfloat; is_touch: bool; swell: cfloat = 0.0
): seq[float32] {.exportc.} =
  ## Report orientation pulse travelling along this object's marker, flat.
  ##   Run count then each run's point count followed by its points: `[runs, count0, x,
  ##   y, ..., count1, x, y, ...]`.
  ##   Each run is closed outline to fill: run tapers, stroke has one width.
  ##   Own call rather than tail on `nimSelectionMarker`, whose format promises points are
  ##   "whatever is left".
  ##     Marker is still shaped once: that call leaves result in `MARKER_SHAPED`, and
  ##     this reuses it wherever every input matches.
  ##   Takes same `progress` and `is_touch` marker was asked for, so pulse lies on outline
  ##   actually drawn; swollen marker's pulse swells with it.
  ##   Empty for anything with no orientation: point, plane at horizon, dead handle, no
  ##   shape; see `marker.markerFor`.
  ##   Clock is advanced whether or not run came out.
  ##     Returning early on empty run deadlocks line: every phase starts at 0,
  ##     `samplePulse` clamps on open outline, so rail at phase 0 yields nothing, which
  ##     would skip advance, for ever.
  ##     Plane's loop is closed and wraps, so only lines would stall.
  ##   Mirrors `visualiser.drawSelectionMarker`.
  if not SCENE.isAlive(int(handle)): return
  ensureViewOverlay(int(width), int(height))
  let travel = CLOCK_PULSE.travelAt(int(handle))
  let at = int(handle) ## Handle as scene indexes it, read once for every reader below.
  var held = (ref Marker)(nil)
  if MARKER_SHAPED.isSome:
    let stored = MARKER_SHAPED.get
    if stored.handle == at and stored.width == int(width) and
        stored.height == int(height) and stored.progress == float(progress) and
        stored.is_touch == is_touch and stored.swell == float(swell) and
        stored.travel == travel and stored.settings == SETTINGS_OVERLAY_HELD.get:
      held = stored.marker
  if held == nil:
    # Reuse shared box, dropping its entry: stale key must not outlive overwrite.
    MARKER_SHAPED = none(ShapedMarker)
    held = BOX_MARKER
    if not markerFor(
      SCENE.geometryOf(at), SCENE.anchorOverrideAt(at), SCENE.radiusAt(at),
      SCALE_OVERLAY, CAMERA, VIEW_PROJECTION_OVERLAY, int(width), int(height), held[],
      float(progress), is_touch, travel = some(travel), swell = float(swell),
    ): return

  template marker: Marker = held[]
  # Advance against length this marker came out at; see `selection.PulseClock`.
  #   Orbiting then changes how fast comet travels and never where it is.
  CLOCK_PULSE.advance(int(handle), marker.lap, SECONDS_STEP_PULSE)
  if marker.count_run_pulse == 0: return
  result = @[cfloat(marker.count_run_pulse)]
  for run in 0 ..< marker.count_run_pulse:
    result.add(cfloat(marker.counts_pulse[run]))
    for i in 0 ..< marker.counts_pulse[run]:
      result.add([cfloat(marker.pulses[run][i].x), cfloat(marker.pulses[run][i].y)])



#[ Scene Save/Load Primitives ]#

proc nimSceneMagic(): cstring {.exportc.} = cstring(MAGIC_SCENE)
  ## Report four bytes `.rgascene` file opens with, for packer in browser scripts.

proc nimSceneVersion(): cint {.exportc.} = cint(VERSION_SCENE)
  ## Report format version this build writes, for that packer.
  ##   Exported rather than written again in JavaScript, where literal survives bump and
  ##   browser stamps old version onto new content; see `scene.MAGIC_SCENE`.

proc nimSceneReadsVersion(version: cint): bool {.exportc.} =
  ## Report whether this build can read scene file stamped with this version.
  ##   Rule rather than number: what build reads is range, two literals to drift.
  version >= 0 and version <= int(high(uint8)) and readsSceneVersion(uint8(version))

proc nimSceneHasRadius(version: cint): bool {.exportc.} =
  ## Report whether file of this version carries radius after each object's geometry.
  ##   Parser asks this rather than compare against literal; see `scene.hasRadius`.
  version >= 0 and version <= int(high(uint8)) and hasRadius(uint8(version))

proc nimSceneHasShine(version: cint): bool {.exportc.} =
  ## Report whether file of this version carries shines byte after each object's radius.
  version >= 0 and version <= int(high(uint8)) and hasShine(uint8(version))


proc nimSceneClear() {.exportc.} =
  ## Discard live scene and start fresh empty one.
  SCENE.restoreFrom(initScene())
  SELECTION.clear()
  HISTORY.initHistory(SCENE, CAMERA)


proc nimSceneAddRaw(
  version: cint, ink_ordinal: cint, is_visible: bool, label: cstring,
  coefficients: seq[float], radius: cfloat, shines: bool, count_total: cint, now: cfloat
): cint {.exportc.} =
  ## Add one object straight from parsed `.rgascene` fields, for load path.
  ##   Presentation layer parses bytes into these fields and calls this once per object, in
  ##   file order.
  ##   `version` is file's own; object is carried up by `scene.objectUpgraded`, same chain
  ##   desktop's `loadScene` walks.
  ##     `SLOT_NONE` where no version could have written object: corrupt or foreign file.
  ##   `radius` is whatever parser read, or anything at all where version wrote none:
  ##   upgrade chain fills it there.
  ##   `count_total` is file's whole object count and `now` this frame's clock, so arrival
  ##   is staggered by `scene.bornReplaying`, same rule desktop stamps with.
  var geometry: Multivector
  for b in Basis: geometry[b] = coefficients[ord(b)]
  let carried = objectUpgraded(
    ObjectSaved(
      ink_ordinal: int(ink_ordinal),
      is_visible: is_visible,
      label: $label,
      geometry: geometry,
      radius: float(radius),
      shines: shines,
    ),
    uint8(version),
  )
  if carried.isNone: return SLOT_NONE
  # Take how many scene holds as this object's position in file.
  #   Scene was cleared before first of these.
  let born = bornReplaying(SCENE.len, int(count_total), float(now))
  let handle = SCENE.addObject(
    carried.get.geometry, carried.get.label, Ink(carried.get.ink_ordinal), born,
    radius = carried.get.radius, shines = carried.get.shines,
  )
  SCENE.setVisible(handle, carried.get.is_visible)
  # Stamp rather than leave alone: handle could hold stale reading from earlier occupant.
  stampBorn(handle, born)
  cint(handle)



#[ Frame Assembly ]#

type FrameData = object
  ## Define one frame's vertex data plus transform it is drawn through.
  ##   Everything caller needs to issue this frame's `gl.drawArrays` calls.
  ribbon_verts, point_verts: FlatBuffer
  ring_records: FlatBuffer ## Fourteen floats per ring, `mesh.RingRecord`'s field order.
    ## One record per rim, where ribbon records per segment were most of all ribbon
    ## traffic; figures in `PROVENANCE.md`.
  disc_records: FlatBuffer ## Thirteen floats per disc, `mesh.DiscRecord`'s field order.
    ## For instanced fan draw.
  dome_records: FlatBuffer ## Eight floats per dome, `mesh.DomeRecord`'s field order.
    ## For instanced sphere draw.
  veil_runs: FlatBuffer ## Translucent pass's draw order, three floats per run.
    ## Kind (`mesh.VeilKind` ordinal), first record, count.
    ## Walked in sequence so two veils blend in order scene emitted them; see
    ## `mesh.VeilRuns`.
  view_projection: seq[float32]
  furn_ribbon_verts: FlatBuffer ## Ground grid and world axes alone, drawn first.
    ## Built at own thinner width (`mesh.WIDTH_LINE_FURNITURE`), since ribbon carries
    ## width as geometry.
    ## Empty where `is_furniture_held`, meaning "furniture you already have".
  is_scene_held: bool ## Whether scene records are unchanged from last frame.
    ## Every buffer below then already holds what it should and none needs re-uploading.
    ## See `SettingsScene` for what has to match and three states refusing hold.
  is_furniture_held: bool ## Whether furniture is unchanged from last frame.
    ## Caller then keeps buffer it uploaded rather than reading empty `furn_ribbon_verts`
    ## as empty world.
    ## Furniture is function of camera alone, and camera is still for most frames of
    ## ordinary session.
    ##   Furniture is moving frame's largest phase on JS backend (diagnostics scenery row
    ##   is live figure), so still frame skipping it does most of frame less work.
  ms_build, ms_furniture, ms_scene, ms_flatten: float32
    ## Record what this frame's assembly cost, in milliseconds.
    ##   Whole of `nimBuildFrame`, and its three phases: furniture, scene's objects (preview
    ##   and preview included), and flatten of every mesh into arrays above.
    ##   Phases bridge cannot see (GL upload, SVG overlay) are timed by browser scripts.
    ##   Held furniture frame reports near-zero furniture.
  camera_eye_x, camera_eye_y, camera_eye_z: float32
  camera_forward_x, camera_forward_y, camera_forward_z: float32
  camera_depth_near, camera_tangent_half_view, camera_height_pixels: float32
    ## Carry what ribbon vertex shader needs of camera.
    ##   Exactly `mesh.DrawScale`'s same-named fields.
    ##   Widening, near clip and screen-constant width run on GPU.
  camera_right_x, camera_right_y, camera_right_z: float32
  camera_up_x, camera_up_y, camera_up_z: float32
    ## Carry camera's screen axes, point vertex shader spans each disc across.
    ##   `mesh.DrawScale.axis_right` and `axis_up`.
  fog_radius_full, fog_radius_gone: float32
    ## Carry furniture fog's two radii, for ribbon fragment shader's fade of fogged records.
    ##   `mesh.fogFurnitureFor`'s answer for this frame's reach.
  ms_camera, ms_matrix, ms_unaccounted: float32
    ## Record three spans of `nimBuildFrame` that belong to no row.
    ##   `ms_camera` is prologue: focus pruning, tween, `DrawExtent`, `framing.offerAim`.
    ##   `ms_matrix` is view-projection build.
    ##   `ms_unaccounted` is whatever phases fail to cover, shown rather than inferred:
    ##   breakdown whose parts do not sum is worse than coarse one.
  ms_placing, ms_emitting: float32
    ## Cut same milliseconds second way, not stage of its own.
    ##   How frame divided between working out where geometry goes and turning places into
    ##   vertices, which is question this project exists to ask.
    ##   `ms_emitting` is pure by construction: reached through `mesh`, which imports
    ##   `euclid` alone.
    ##   `ms_placing` carries little Euclidean arithmetic inside its loops; see `timings`.
  ms_hover_pick: float32
    ## Record what picking under cursor cost, measured between frames, reported by one after.
    ##   `updateHover` runs from event handlers, so no bracket inside this proc sees it.
    ##   Carried on `timings.FrameRecord`.
  ms_grid, ms_axes: float32
    ## Record what two halves of scenery cost, inside `ms_furniture`.
    ##   Axes are three lines however far camera stands; grid is however many ground reach
    ##   asks for.
  count_grid_segments: int
    ## Count ribbon records ground grid is drawn from, one per lattice line.
    ##   Bounded per family by `mesh.LINES_GRID_MAX`.
    ##   Axes excluded, so budgeted number matches its budget.
  ms_points, ms_lines, ms_planes, ms_sky, ms_preview, ms_selected: float32
    ## Record what each kind of scene object cost inside `ms_scene`, with counts below.
    ##   Kinds differ by order of magnitude: point is single vertex, plane places rim of
    ##   `mesh.SEGMENTS_CIRCLE_HORIZON` segments.
    ##   `sky` is horizon planes drawn first; `preview` is staged edit and drag preview
    ##   together; `selected` is overlay tail, drawn again over cleared depth.
    ##   Timed by clock read once per object: mark from end of one is start of next.
    ##     Clock's own overhead lands inside `ms_scene`; figures in `PROVENANCE.md`.
  count_points, count_lines, count_planes, count_sky, count_preview, count_selected: int
    ## Count objects of each kind times above are for.
    ##   Reader can divide: "is one expensive, or are there many?".
  count_points_culled: int ## Count points skipped for lying outside view.
    ## Beside `count_points`, so panel can say drawn of standing; see `isPointInView`.
  ribbon_over, ring_over, point_over, veil_run_over: int ## How much of each stream's end
    ## is overlay run, drawn after rest over cleared depth.
    ## Count of tail rather than index it starts at, so glue subtracts nothing; see
    ## `mesh.Mesh.index_overlay` and `renderer.drawRun`.
    ## Vertices for points, records for ribbons and rings, whole runs for veils.


type SceneCost = object
  ## Define tally of what each kind of scene object cost this frame, and how many there were.
  ##   One clock read per object: mark closing one object opens next.
  ##   Preview and overlay tail are kinds of their own because neither is scene object
  ##   reader counted.
  ms_points, ms_lines, ms_planes, ms_sky, ms_preview, ms_selected: float
  count_points, count_lines, count_planes, count_sky, count_preview, count_selected: int
  count_points_culled: int ## Count points skipped for lying outside view; see `chargeCulled`.
  mark: float ## When object now being drawn started, on `performanceNow`'s clock.


var COUNTS_SCENE: SceneCost ## What scene meshes standing in `MESHES` are made of.
  ## Only counts are read back, on held frame; times belong to frame that did work.
  ##   Held frame draws what it had and should say what that is rather than report empty
  ##   scene.
  ## Here rather than in module's `var` block because `SceneCost` is declared just above.

proc openTally(cost: var SceneCost) =
  ## Start tally's clock, so first object measures from here rather than from zero.
  ##   Only where breakdown is being read; see `timings.IS_TALLYING`.
  if isTallying(): cost.mark = performanceNow()


proc chargeTally(cost: var SceneCost; kind: Case; is_sky, is_preview, is_selected: bool) =
  ## Charge whatever has been drawn since last mark to kind it belongs to.
  ##   Takes kind placement settled on rather than reading shape again: reading twice is
  ##   second multivector walk per object per frame, on path this tally measures.
  ##   Counts are gathered either way; only times are gated; see `timings.IS_TALLYING`.
  ##     Count is one increment; time is clock read per object, which at capacity is
  ##     sizeable share of frame; figures in `PROVENANCE.md`.
  var spent = 0.0
  if isTallying():
    let now_mark = performanceNow()
    spent = now_mark - cost.mark
    cost.mark = now_mark
  if is_preview:
    cost.ms_preview += spent
    cost.count_preview += 1
    return
  if is_selected:
    cost.ms_selected += spent
    cost.count_selected += 1
    return
  if is_sky:
    cost.ms_sky += spent
    cost.count_sky += 1
    return
  case kind
  of Case.Nothing: discard # Nothing drawable was drawn, so nothing to charge.
  of Case.PointAt, Case.PointToward:
    cost.ms_points += spent
    cost.count_points += 1
  of Case.LineThrough, Case.LineAcross:
    cost.ms_lines += spent
    cost.count_lines += 1
  of Case.PlaneOn, Case.PlaneEverywhere:
    cost.ms_planes += spent
    cost.count_planes += 1


proc chargeCulled(cost: var SceneCost) =
  ## Charge point skipped for lying outside view: its test to points, its count to culled.
  if isTallying():
    let now_mark = performanceNow()
    cost.ms_points += now_mark - cost.mark
    cost.mark = now_mark
  cost.count_points_culled += 1


proc nimBuildFrame(
  aspect, now: cfloat; height_pixels: cint;
  is_axes_shown, is_grid_shown: bool; is_tally_skipped: bool = false
): FrameData {.exportc.} =
  ## Tessellate every visible object in live scene, at camera's current placement.
  ##   Through same `mesh.addObject` dispatch and `camera` transforms desktop draws
  ##   through, every object at full colour as desktop's interactive `assembleMeshes` draws.
  ##   Exceeds sixty-line default.
  ##     Mirrors `visualiser.assembleMeshes`'s two-pass draw-order invariant and packs
  ##     view-projection plus whole `FrameData`, packaging desktop never needs.
  ##     Splitting packaging out would return partial results across extra boundary for no
  ##     reader benefit.
  ##   Draws `GHOST` too, tinted `INK_PREVIEW` and muted; see that var.
  # Read one clock per phase boundary, so diagnostics tab shows each step.
  #   `performanceNow` is timing-only.
  let ms_entered = performanceNow()
  # Say once, at top, whether this frame tallies, so whole frame agrees.
  #   Flag read part-way through would mix two frames' worth of instrumentation.
  #   Stated as "skipped" on purpose: Nim default does not survive into JS signature, and
  #   caller omitting it passes `undefined`, falsy, so natural way round would silently
  #   turn measurement off.
  setTallying(not is_tally_skipped)
  # Forget last frame's two sides, and turn record pair over.
  #   What was measured between frames (hover picking) is then readable while this frame
  #   reports it.
  openFrameTimings()
  # Guard focus as selection is guarded: handle carried across frames may have died.
  INTERACTION.pruneFocus(SCENE)

  # Carry camera one frame further toward whatever is being worked on, then aim it again.
  #   From what this frame holds, same rule `visualiser.assembleMeshes` applies.
  #   Advancing before `scale` is read keeps furniture extent consistent with where camera
  #   is.
  TWEEN_CAMERA.advance(CAMERA, float(now), easeOutCubic)
  # Take framebuffer's height, not window's.
  #   Ribbon's width is measured in pixels drawn, and this build renders at
  #   device-pixel-ratio multiple.
  # Place first, so scene's reach is this frame's before extent reads far clip.
  ensurePlacement()
  CAMERA.reach_scene = REACH_SCENE
  let scale = CAMERA.drawExtentFor(int(height_pixels))
  # Derive frustum once, for cull of every point below; see `isPointInView`.
  let bounds = CAMERA.viewBoundsFor(scale, float(aspect))
  # Recover width of centred box from aspect, since this build is handed that.
  let preview = staged()
  TWEEN_CAMERA.offerAim(
    CAMERA, SCENE, SELECTION, preview, scale, int(float(aspect)*float(height_pixels)),
    int(height_pixels), float(now), ANIMATION_SECONDS, POINTER_PICK,
  )

  # Hold furniture where settings match last frame's.
  #   Everything `drawExtentFor` reads, and two toggles: frame whose settings match is
  #   drawing same vertices and may keep them.
  #   Compared exactly: question is "did anything move at all".
  let settings_furniture =
    settingsFurnitureFor(CAMERA, int(height_pixels), is_axes_shown, is_grid_shown)
  let is_furniture_held =
    SETTINGS_FURNITURE_HELD.isSome and SETTINGS_FURNITURE_HELD.get == settings_furniture
  let ms_after_camera = performanceNow()
  let ms_before_furniture = ms_after_camera
  var
    ms_grid = 0.0
    ms_axes = 0.0
  if not is_furniture_held:
    SETTINGS_FURNITURE_HELD = some(settings_furniture)
    clearMeshes(MESHES_FURNITURE)
    # Clock grid and axes apart: axes are three lines, grid is however many ground reaches.
    let ms_before_grid = performanceNow()
    if is_grid_shown:
      addGrid(MESHES_FURNITURE, SCRATCH, scale.extentFurniture, scale)
    # Count between two, so figure is grid's own; see `mesh.addSegmentAcross`.
    COUNT_GRID_SEGMENTS = MESHES_FURNITURE.ribbons.count
    let ms_before_axes = performanceNow()
    if is_axes_shown:
      addAxes(MESHES_FURNITURE, SCRATCH, scale.extentFurniture, scale)
    ms_grid = ms_before_axes - ms_before_grid
    ms_axes = performanceNow() - ms_before_axes
  let ms_after_furniture = performanceNow()

  # Hold scene where settings match last frame's, one layer out from furniture's hold.
  #   Frame whose settings match tessellates same records, so keeps them, flattens and
  #   uploads together: whole scene phase.
  #   Two states refuse hold outright rather than being encoded: preview or preview
  #   follows pointer; object inside appear animation is drawn differently every frame.
  #   Cost of refusing is one rebuilt frame; cost of holding wrongly is frozen picture.
  let settings_scene: SettingsScene = (
    furniture: settings_furniture,
    aspect: float(aspect),
    revision: SCENE.revision,
    revision_selection: SELECTION.revision,
    is_culling: IS_CULLING,
  )
  let is_scene_settled =
    preview.isNone and INTERACTION.preview.isNone and
      float(now) >= BORN_LAST + ANIMATION_SECONDS
  let is_scene_held =
    is_scene_settled and SETTINGS_SCENE_HELD.isSome and SETTINGS_SCENE_HELD.get == settings_scene
  if not is_scene_held:
    SETTINGS_SCENE_HELD = (if is_scene_settled: some(settings_scene) else: none(SettingsScene))

  # Declare tally out here because frame reports it either way.
  #   On held frame times are zero and counts are last frame's, still what scene holds.
  var cost: SceneCost
  var ms_after_scene = ms_after_furniture
  if is_scene_held:
    cost.count_points = COUNTS_SCENE.count_points
    cost.count_lines = COUNTS_SCENE.count_lines
    cost.count_planes = COUNTS_SCENE.count_planes
    cost.count_sky = COUNTS_SCENE.count_sky
    cost.count_preview = COUNTS_SCENE.count_preview
    cost.count_selected = COUNTS_SCENE.count_selected
    cost.count_points_culled = COUNTS_SCENE.count_points_culled
  # Refresh placement cache only where scene moved; see `ensurePlacement`.
  ensurePlacement()

  if not is_scene_held:
    clearMeshes(MESHES)
    cost.openTally()
    # Emit horizon plane's dome first, before anything sharing translucent veil pass.
    #   Veil runs draw in append order, unsorted by depth, so dome first guarantees every
    #   ordinary plane's fill blends over it; see `visualiser.assembleMeshes`.
    #   By-handle "At" accessors rather than `pairs`: under JS backend `Object` holds `Scene`
    #   by value, so constructing one per live handle copies entire scene.
    #   To watermark, not capacity: `scene.bound` is high-water mark, which only rises;
    #   sibling walk below takes same bound.
    #   Placement once, emitted every frame: placement already answered sky or not, so walks
    #   sort on `PLACEMENTS[handle].kind` rather than reading multivector per handle per walk.
    for handle in 0 ..< SCENE.bound:
      if not SCENE.isAlive(handle) or handle in SELECTION: continue
      if SCENE.isVisible(handle):
        # Index in place, never bind to local; see `emitObject`.
        #   `let placed = PLACEMENTS[handle]` is deep copy under JS backend, once per object
        #   per frame.
        if PLACEMENTS[handle].kind == Case.PlaneEverywhere:
          let progress = animationProgress(float(now), BORNS[handle])
          discard MESHES.emitObject(
            PLACEMENTS[handle], SCENE.inkAt(handle).colour, scale, progress,
          )
          cost.chargeTally(
            PLACEMENTS[handle].kind, is_sky = true, is_preview = false, is_selected = false,
          )

    for handle in 0 ..< SCENE.bound:
      if not SCENE.isAlive(handle) or handle in SELECTION: continue
      if SCENE.isVisible(handle):
        if PLACEMENTS[handle].kind != Case.PlaneEverywhere:
          # Skip point outside view before it costs emitting, flatten and upload.
          if IS_CULLING and not isPointInView(PLACEMENTS[handle], SCENE.radiusAt(handle), bounds):
            cost.chargeCulled()
            continue
          let progress = animationProgress(float(now), BORNS[handle])
          discard MESHES.emitObject(
            PLACEMENTS[handle], SCENE.inkAt(handle).colour, scale, progress, SCENE.radiusAt(handle),
            LIGHTS.lights[handle],
          )
          cost.chargeTally(
            PLACEMENTS[handle].kind, is_sky = false, is_preview = false, is_selected = false,
          )

    # Emit open session's staged geometry, or apply control's preview where none.
    #   One preview for both; `staged` decides order.
    #   Centred on anchor commit stores, so previewed plane stays where previewed.
    #   `preview` read once in prologue; nothing since has touched session.
    if preview.isSome:
      # Place here rather than cache: preview is not handle and moves with pointer.
      var placement_staged = placeObject(preview.get.geometry, preview.get.anchor)
      discard MESHES.emitObject(
        placement_staged, INK_PREVIEW.colour.muted(), scale, radius = preview.get.radius
      )
      cost.chargeTally(
        placement_staged.kind, is_sky = false, is_preview = true, is_selected = false
      )

    # Emit what drag in progress would build, in same preview ink.
    #   Reader learns one "not committed yet" appearance; mirrors
    #   `visualiser.assembleMeshes`.
    if INTERACTION.preview.isSome:
      var placement_derived = placeObject(
        INTERACTION.preview.get.geometry, INTERACTION.preview.get.anchor,
      )
      discard MESHES.emitObject(placement_derived, INK_PREVIEW.colour.muted(), scale)
      cost.chargeTally(
        placement_derived.kind, is_sky = false, is_preview = true, is_selected = false
      )

    # Emit everything selected last, drawn over cleared depth.
    #   Picked object is then never buried.
    #   Mirrors `visualiser.assembleMeshes`.
    markOverlay(MESHES)
    for position in 0 ..< SELECTION.len:
      let handle = SELECTION.at(position)
      if not SCENE.isAlive(handle) or not SCENE.isVisible(handle): continue
      if IS_CULLING and not isPointInView(PLACEMENTS[handle], SCENE.radiusAt(handle), bounds):
        cost.chargeCulled()
        continue
      let progress = animationProgress(float(now), BORNS[handle])
      discard MESHES.emitObject(
        PLACEMENTS[handle], SCENE.inkAt(handle).colour, scale, progress, SCENE.radiusAt(handle),
        LIGHTS.lights[handle],
      )
      cost.chargeTally(
        PLACEMENTS[handle].kind, is_sky = false, is_preview = false, is_selected = true
      )

    ms_after_scene = performanceNow()
    COUNTS_SCENE = cost

  let vp = CAMERA.initMatrixViewProjection(float(aspect))
  for row in 0 .. 3:
    for column in 0 .. 3:
      FLAT_VIEW[4*column + row] = vp.at(row, column)

  # Flatten into locals rather than in constructor.
  #   Pack phase then has start and end clock can bracket.
  let ms_after_matrix = performanceNow()
  let ms_before_flatten = ms_after_matrix
  # Hold flatten with tessellation.
  #   Records did not change, so flat buffers already hold exactly what rerun would
  #   write; browser scripts skips uploads on same flag.
  if not is_scene_held:
    flattenDiscsInto(MESHES.discs, FLAT_DISC)
    flattenRingsInto(MESHES.rings, FLAT_RING)
    flattenDomesInto(MESHES.domes, FLAT_DOME)
    flattenVeilRunsInto(MESHES.veils, FLAT_RUNS)
    flattenRibbonsInto(MESHES.ribbons, FLAT_RIBBON)
    flattenInto(MESHES.points, FLAT_POINT)
  if is_furniture_held: FLAT_FURNITURE.used = 0
  else: flattenRibbonsInto(MESHES_FURNITURE.ribbons, FLAT_FURNITURE)
  let ms_done = performanceNow()

  var data = FrameData(
    ring_records: FLAT_RING.view,
    disc_records: FLAT_DISC.view,
    dome_records: FLAT_DOME.view,
    veil_runs: FLAT_RUNS.view,
    ribbon_verts: FLAT_RIBBON.view,
    point_verts: FLAT_POINT.view,
    view_projection: FLAT_VIEW,
    furn_ribbon_verts: FLAT_FURNITURE.view,
    is_scene_held: is_scene_held,
    is_furniture_held: is_furniture_held,
    camera_eye_x: float32(scale.eye.x), camera_eye_y: float32(scale.eye.y),
    camera_eye_z: float32(scale.eye.z),
    camera_forward_x: float32(scale.forward.x), camera_forward_y: float32(scale.forward.y),
    camera_forward_z: float32(scale.forward.z),
    camera_depth_near: float32(scale.depthNear),
    camera_tangent_half_view: float32(scale.tangentHalfView),
    camera_height_pixels: float32(scale.heightPixels),
    camera_right_x: float32(scale.axisRight.x), camera_right_y: float32(scale.axisRight.y),
    camera_right_z: float32(scale.axisRight.z),
    camera_up_x: float32(scale.axisUp.x), camera_up_y: float32(scale.axisUp.y),
    camera_up_z: float32(scale.axisUp.z),
    fog_radius_full: float32(fogFurnitureFor(scale.extentFurniture).radius_full),
    fog_radius_gone: float32(fogFurnitureFor(scale.extentFurniture).radius_gone),
    ms_grid: float32(ms_grid),
    ms_axes: float32(ms_axes),
    count_grid_segments: COUNT_GRID_SEGMENTS,
    ms_points: float32(cost.ms_points),
    ms_lines: float32(cost.ms_lines),
    ms_planes: float32(cost.ms_planes),
    ms_sky: float32(cost.ms_sky),
    ms_preview: float32(cost.ms_preview),
    ms_selected: float32(cost.ms_selected),
    count_points: cost.count_points,
    count_points_culled: cost.count_points_culled,
    count_lines: cost.count_lines,
    count_planes: cost.count_planes,
    count_sky: cost.count_sky,
    count_preview: cost.count_preview,
    count_selected: cost.count_selected,
    ms_build: float32(ms_done - ms_entered),
    ms_furniture: float32(ms_after_furniture - ms_before_furniture),
    # Take scene phase as everything between furniture and flatten.
    #   Clearing, both passes, preview and preview, overlay marking.
    ms_scene: float32(ms_after_scene - ms_after_furniture),
    ms_flatten: float32(ms_done - ms_before_flatten),
    ms_camera: float32(ms_after_camera - ms_entered),
    ms_matrix: float32(ms_after_matrix - ms_after_scene),
    # Report what named phases still do not cover.
    #   Never negative: clock going backwards is coarsened timer, not phase running for
    #   less than nothing.
    ms_unaccounted: float32(max(0.0,
      (ms_done - ms_entered) - (ms_after_camera - ms_entered) -
      (ms_after_furniture - ms_before_furniture) - (ms_after_scene - ms_after_furniture) -
      (ms_after_matrix - ms_after_scene) - (ms_done - ms_before_flatten))),
    ms_placing: float32(spentOn(Side.Placing)),
    ms_emitting: float32(spentOn(Side.Emitting)),
    ms_hover_pick: float32(recordLastFrame().ms_hover_pick),
    # Split ribbons in records, veils in whole runs.
    #   Instanced draws take ranges of instances.
    ribbon_over: (if MESHES.ribbons.index_overlay.isSome:
      max(0, MESHES.ribbons.count - MESHES.ribbons.index_overlay.get) else: 0),
    ring_over: (if MESHES.rings.index_overlay.isSome:
      max(0, MESHES.rings.count - MESHES.rings.index_overlay.get) else: 0),
    point_over: countOverlay(MESHES.points),
    veil_run_over: (if MESHES.veils.index_overlay.isSome:
      max(0, MESHES.veils.count - MESHES.veils.index_overlay.get) else: 0),
  )
  # Stamp whole of proc after record is built.
  #   Overlay scans and record's construction fall past `ms_done`, so tail would belong to
  #   no row; residue widens by same span, so rows still sum.
  let ms_returned = performanceNow()
  data.ms_build = float32(ms_returned - ms_entered)
  data.ms_unaccounted += float32(ms_returned - ms_done)
  data
