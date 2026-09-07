## Track drag gesture from one scene object to another, and apply operation it makes.
##
## Press pivot chooses scheme; button chooses whether reader is asked.
##   Drag begins only when press lands on pickable object.
##   Press on empty space is left for camera orbit or pan, so two schemes never compete
##   for one click.
##   Left button decides, right asks, over same set of choices; neither reaches anything
##   other cannot.
## What drag applies is decided at release, from operands, not from button that started it.
##   `proposalFor` reads two grades, and drag shows its answer as ghost before committing.
## Ghost is always what letting go right now would commit.
##   Wedge cursor stands in once wheel is open and entered; `proposalFor`'s answer where
##   none is, dwell wheel nobody has entered included; see `endDrag`.
##   `Interaction.proposal` holds that one answer, `endDrag` obeys it, and `ReleaseEffect`
##   names three things it can amount to, i.e. nothing, refusal, object, which tints
##   rubber-band.
## Hover is tracked independently of dragging, every frame.
##   Object drag would start from shows before any button is pressed.
## Hold is touch counterpart, with no buttons to name operation.
##   Press object, keep still, and once press has lasted `SECONDS_LONG_PRESS` it selects object.
##   Elapsed fraction lives here rather than in either presentation layer: how long hold
##   takes and whether one is due are rules about gesture.
##   Both drive object's marker drawn part-built, which is what makes wait bearable.
##
## Shared between desktop (`visualiser.nim`) and browser (`browser_bridge.nim`) render
## paths; see `visualiser.nim`'s "Render Paths" table.

{.experimental: "strictFuncs".}

import std/[math, options, strformat]

# `pga` arrives through `projections`, which stands in for four it has withdrawn.
import ./projections
import ./[boundary, camera, format, tessellate, picking, scene]



#[ Gesture Configuration ]#

# Take every `now` in seconds, on whatever monotonic clock caller owns.
#   Same clock `scene.addObject` records birth on: one reading threaded through whole release
#   rather than two that could disagree.
#   Named in constants below, since browser's own clock reads milliseconds.

const
  SECONDS_DWELL_MENU* = 0.75
    ## Hold drag still over pivot this long and choice menu opens.
    ##   On pointer armed `MenuArming.OnDwell`, which means touch alone.
    ##   Still, not merely present: clock restarts whenever cursor moves further than
    ##   `PIXELS_TAP_SLOP` from where it last settled.
    ##     On presence alone, slow finger crossing ground plane tripped it mid-drag and
    ##     construction built nothing.
    ##   Longer than threshold triggered on its own would dare be.
    ##     Only has to be slow enough never to fire on hesitation; usual failure of dwell
    ##     menu is popping up at someone still moving.
    ##   Above `SECONDS_LONG_PRESS`, so stationary finger's two thresholds race in right
    ##   order.

  SECONDS_LONG_PRESS* = 0.50
    ## Hold touch this long on object to select it.
    ##   Long enough that tap, or first instant of drag meant to orbit camera, never matures.
    ##   Short enough that deliberate hold does not feel stuck.
    ##   Tolerable only because it is shown: `progressHold` drives object's marker drawn
    ##   part-built, so hold reads as filling rather than as nothing happening.

  SECONDS_SWELL_GROW* = 0.12
    ## Take this long to swell touched object's marker clear of finger, before its fill begins.
    ##   Own phase ahead of fill, so marker is already at size it fills at.
    ##     Bar that grows and fills at once is two motions saying one thing, and growing wins.
    ##   Quick enough to read as marker getting out of way rather than delay.
    ##   Lengthens press end to end, to `SECONDS_SWELL_GROW + SECONDS_LONG_PRESS`.
    ##     Fill keeps whole duration, so part reader watches is unchanged.

  SECONDS_SWELL_SHRINK* = 0.15
    ## Take this long to settle swollen marker back to true size after finger lifts.
    ##   Slower than grow: grow is getting out of way, this is marker arriving at what it
    ##   stays as, and outline that snaps reads as second marker replacing first.

  FACTOR_PAN_REACH_MAX* = 4.0
    ## Bound how far out along its sight ray pan may take hold, as multiple of orbit distance.
    ##   Level pan grabs is horizontal, so ray aimed near horizon meets it very far off, and
    ##   one pixel of drag there is hundreds of world units.
    ##   Hold point is clamped rather than movement, so rule stays continuous.
    ##     `min(reach, bound)` moves smoothly as cursor crosses bound; switching rule there
    ##     would jolt mid-drag.
    ##   Four rather than two: at opening placement, ray well inside window already reaches
    ##   past two distances, ordinary place to start drag from; figures in `PROVENANCE.md`.

  FRACTION_PAN_PIXEL* = 0.0016
    ## Slide pivot this fraction of orbit distance per dragged pixel, with nothing to grab.
    ##   Fallback only, for drag whose sight ray never meets level it would grab; see
    ##   `panAcross`.

  PIXELS_TAP_SLOP* = 12.0
    ## Move press further than this and it stops being press.
    ##   Which scheme gesture enters: press staying inside matures into selection; press
    ##   leaving becomes construction drag where it landed on object, camera move where it did
    ##   not.
    ##   Sized for fingertip: finger rolls few pixels on contact even held still, and
    ##   threshold tight enough for mouse makes long-press unreachable on touchscreen.

  PIXELS_CLICK_SLOP* = 6.0
    ## Move pointer press further than this and it stops being click.
    ##   Not `PIXELS_TAP_SLOP`: mouse resting on desk does not roll, so pointer that wandered
    ##   this far was moved on purpose.
    ##   Fingertip's allowance would swallow short deliberate drags between two objects
    ##   overlapping on screen.

  # Bound click by distance alone, never by time.
  #   Time bound dropped clicks hand lingered on; see `isClick`.

  PIXELS_MENU_REACH* = 76.0
    ## Reach from menu's centre to centre of each of its four wedges.
    ##   Wide enough that wedge clears cursor and object under it, and each is past WCAG
    ##   2.5.8's 24-pixel pivot once `PIXELS_MENU_DEADZONE` is subtracted.
    ##   Short enough to stay one wrist movement, since menu opens mid-drag.

  PIXELS_MENU_DEADZONE* = 26.0
    ## Choose nothing while cursor stands inside this distance of menu's centre.
    ##   Way out of opened menu without committing.
    ##   Reason dwell menu is safe to open unasked: it opens centred on cursor, so reader who
    ##   did not want it is already in deadzone.

  PIXELS_MENU_CORNER_FURTHEST* = 103.9
    ## Record furthest any wedge's outer corner sits from menu centre, measured.
    ##   Not derivable here: wedge is as wide as its label, and only render path knows what
    ##   its face laid that out as.
    ##     Read off drawn rects in browser build; all four labels are fixed, so one number.
    ##   Kept beside constant it justifies, so wider label or longer reach surfaces as number
    ##   no longer clearing `PIXELS_MENU_DISENGAGE`, not as menu closing on wedge.

  PIXELS_MENU_DISENGAGE* = 150.0
    ## Let open menu go of drag entirely past this distance from its centre.
    ##   Makes wheel opened on wrong object recoverable: it closes, drag stops being latched
    ##   to that destination, and travelling on to another object opens it there.
    ##     Source is never touched, so pair re-aims rather than chains.
    ##   Bounds `choiceAt`'s overshoot, unbounded on purpose for fast throw.
    ##     Both cannot hold; re-aiming was chosen.
    ##   Sited off `PIXELS_MENU_CORNER_FURTHEST`, leaving clearance past furthest point throw
    ##   could aim at.

const
  HEIGHT_MENU_WEDGE* = 30.0
    ## Size one wedge's short axis, in pixels.
    ##   Past WCAG 2.5.8's 24-pixel pivot on short axis, which binds.
    ##   Long axis comes from label, measured by render path drawing it.
  PADDING_MENU_WEDGE* = 22.0
    ## Pad wedge's label, so short name still reads as button.
  ROUNDING_MENU_WEDGE* = 8.0
    ## Round wedge's corners by this radius.
    ##   Selection menu's own button radius: this menu and that one are same control in two
    ##   postures.
  WIDTH_MENU_WEDGE_BORDER* = 1.0
    ## Stroke hairline round wedge this thick, matching selection menu's buttons.
  RADIUS_MENU_CENTRE* = 5.0
    ## Mark menu's centre, where nothing is chosen, with dot of this radius.
    ##   Well inside `PIXELS_MENU_DEADZONE`, so it reads as mark rather than boundary.
  ALPHA_MENU_WEDGE* = 0.96
    ## Fill choosable wedge at this opacity.
    ##   Near-solid: surface behind is popover tone, and chip must read as standing on scene
    ##   rather than tint over it.
  ALPHA_MENU_UNOFFERED* = 0.45
    ## Fill wedge that makes nothing at this opacity, drawn rather than dropped.
    ##   Gap is unreadable, and point of fixed compass is that choice never moves.
    ##   High enough that dark chip still reads against dark scene.



#[ Type Definitions ]#

type
  DragOperation* {.pure.} = enum ## Define operation released drag may apply.
    Join, ## Wedge: object through both operands.
    Meet, ## Antiwedge: where two operands cross.
    Project, ## Orthogonal projection of object dragged from onto one dragged to.

  DragChoice* {.pure.} = enum ## Define everything released drag may resolve to.
    ## Three operations plus way out to rest of catalogue.
    ##   Separate from `DragOperation` because `More` applies nothing itself: hands both
    ##   operands to apply section.
    Join, Meet, Project, More

  MenuArming* {.pure.} = enum ## Define how drag in progress may come to open its menu.
    ## What pointer chose at press, held for drag's whole life.
    ##   Three states rather than "forced" flag: mouse's left button takes pair's answer
    ##   and is never interrupted by menu, right button asks; only finger, with no second
    ##   button, waits.
    Never, ## Take proposal on release; no menu, however long drag stands still.
    OnDwell, ## Open after `SECONDS_DWELL_MENU` of standing still over pivot.
      ## Wheel invites itself under finger pausing to aim, which also covers it.
      ##   Until first entered it may not veto release; see `endDrag`.
    Always ## Open moment drag arrives over pivot.

  Compass* {.pure.} = enum ## Define where choice sits in menu, always.
    ## Fixed position per choice; unoffered ones are gaps, never packed out.
    ##   Menu whose objects move is one nobody learns to reach without reading.
    North, East, South, West

  Key* {.pure.} = enum ## Define key 3D view itself reacts to, in neither backend's naming.
    ## Both render paths name physical key (SDL scancode, DOM `KeyboardEvent.code`).
    ##   Each translates into this and asks `motionFor` or `actionFor`, as each translates
    ##   its mouse-button numbering into `PointerButton`.
    ##   Physical so W is same key under hand on every layout.
    ## Only keys view reacts to; accelerators reaching timeline and panels stay where they
    ## are, reached from anywhere.
    ## `Shift` is key rather than flag threaded through every call.
    ##   Held exactly as movement keys are, so one mechanism carries direction and speed.
    W, A, S, D, Q, E, F,
    Left, Right, Up, Down, BracketLeft, BracketRight, Minus, Plus, Enter, Home, Shift

  Motion* {.pure.} = enum ## Define way view keeps moving while key is held.
    ## Separate from `KeyAction`: motion is applied every frame its key is down, by
    ## `driveHeld`; action happens once, at press.
    Forward, Back, Left, Right, Down, Up,
    OrbitLeft, OrbitRight, OrbitUp, OrbitDown,
    DollyIn, DollyOut

  KeyAction* {.pure.} = enum ## Define what one press of key does to view.
    FocusPrevious, FocusNext,
    SelectFocused, ## Alone, or added to selection where shift is held.
    FrameSelection, ## Bring selection into view, through framing rule.
    ViewHome ## Return camera to placement both builds open at.

  Hold* = object ## Define press that selects its object once it has lasted long enough.
    handle*: int ## Object pressed, whose marker fills as press matures.
    started*: float ## When press landed, on clock every caller passes as `now`.
    is_taken*: bool ## Whether this hold's maturity has been acted on.
      ## One-shot lives here because hold outlives its release.
      ##   Flag release handler resets goes stale while hold settles, maturity test stays
      ##   true, and selection fires second time and undoes itself.
    released*: Option[float] ## When finger lifted, if it has.
      ## Marker stays swollen while finger is down, and settles only once this says it may.
      ##   Swell as function of fill was back to true size exactly when selection landed.

  Interaction* = object ## Define cursor, drag and press state held between frames.
    is_enabled*: bool ## Whether picking and overlay run at all; off during storyboard capture.
    cursor*: ScreenPosition ## Last known cursor position, in window pixels.
    index_hover*: Option[int] ## Object nearest cursor this frame, regardless of dragging.
    is_hover_backdrop*: bool ## Whether hovered object is backdrop: plane at horizon, or
      ## finite plane whose disc fills view; see `picking.isBackdropUnder`.
    count_hover_rivals*: int ## How many objects of hovered object's rank were in reach.
      ## `picking.PickReport.count_rivals`; one where hover is unambiguous, zero where
      ## nothing is hovered. Touch reads it through `canConstructByTouch`.
      ## Whole sky, which every ray meets, so true wherever nothing else is under cursor
      ## and sky is in scene.
      ## Recorded at `updateHover`, where scene is in hand, so `beginDrag` and `endDrag`
      ## refuse it without being handed scene.
      ## Refusing keeps camera working: press on empty space becomes orbit because
      ## `beginDrag` fails when nothing is hovered, and sky is hovered everywhere.
    index_focus*: Option[int] ## Object keyboard stands on.
      ## Drawn with hover's marker, so reader without pointer sees where they are.
      ## Separate from `index_hover`: `updateHover` recomputes hover every frame, so focus
      ## stored there would be erased before drawn once.
    is_dragging*: bool ## Whether construction drag is in progress.
      ## Not `Option[DragOperation]`: what drag applies is decided at release, so field
      ## holding operation could only hold placeholder, sentinel smuggled into value's range.
    index_source*: int ## Object drag started from; meaningful only while `is_dragging`.
    index_destination*: Option[int] ## Object drag points at, latched moment its menu opens.
      ## Readers ask `destinationOf` instead.
    pressed*: ScreenPosition ## Where last pointer press landed, whatever it became.
    started*: float ## When that press landed, on clock every caller passes as `now`.
      ## Read only through `isClick`.
    is_press_still*: bool ## Whether last press has stayed inside `PIXELS_CLICK_SLOP` of
      ## where it landed.
      ## Latched rather than recomputed: pointer that swung out and came back was still
      ## dragged.
      ## Stated as still so default is false: press that never went through `beginPress`
      ## is never mistaken for click.
    hold*: Option[Hold] ## Press maturing into selection, if one is in progress.
    is_over_target*: bool ## Whether drag points at object that is not its source.
      ## Distinct from `proposal` being none, which it also is over pair making nothing.
      ##   Those two want opposite feedback, neutral versus warning.
    proposal*: Option[DragChoice] ## What release right now would commit.
      ## Wedge cursor stands in while menu is open, `proposalFor`'s answer where none is.
      ##   Resolved in order `endDrag` resolves it, so preview and commit cannot come apart.
      ## None where release commits nothing: over no pivot, or at centre of menu that may
      ## veto.
      ##   Unentered dwell wheel may not, so pair's answer stands; see `endDrag`.
    preview*: Option[Preview] ## What proposal would make, for each render path to ghost.
      ## `scene.Preview`, same construction both apply pickers offer.
      ## None over nothing, over own source, over pair making nothing (only warning before
      ## refused release), and over `More`, which builds nothing itself.
    arming*: MenuArming ## How this drag may open its menu, as pointer chose at press.
    entered*: float ## When cursor last settled over pivot, for dwell to run from.
      ## Restarted when hovered object changes and when cursor moves away from `settled`.
    settled*: ScreenPosition ## Where cursor was when `entered` was last restarted.
    menu*: Option[ScreenPosition] ## Where choice menu is open, if it is.
    is_menu_entered*: bool ## Whether cursor has stood in any wedge of open menu since it
      ## opened, offered or not.
      ## Separates "lifted at centre without engaging wheel" from "walked into wedge and
      ## came back to cancel".
      ##   First may not veto dwell wheel's release, second always does; see `endDrag`.
      ## Reset each time menu opens.
    is_dragging_camera*: bool ## Whether pointer gesture is moving camera right now.
      ## Orbit or pan drag, or two fingers on canvas.
      ##   Each render path owns its drag state and says so here.
      ## Distinct from `is_dragging`, construction drag that keeps hovering.
    keys_held*: set[Key] ## Physical keys down right now, which `driveHeld` moves camera by
      ## once per frame.
      ## Set so two keys held together compose without enumerating pairs.
      ## Emptied by `releaseKeysAll` whenever view stops receiving key releases.
      ##   Key left here moves camera forever.
    index_disengaged*: Option[int] ## Pivot menu was let go of, while cursor is still over
      ## it.
      ## Without it wheel re-opens on same object next frame, since `MenuArming.Always` is
      ## due every frame over pivot.
      ## Cleared moment hover reports anything else.



#[ Operation Vocabulary ]#

type PointerButton* {.pure.} = enum ## Define physical mouse button, however numbered.
  ## SDL counts 1/2/3 and DOM 0/1/2 for left/middle/right.
  ##   Each render path translates into this and asks `armingOf`, so which button does what
  ##   is stated once.
  Left, Middle, Right


func motionFor*(key: Key): Option[Motion] =
  ## Say which way one key keeps moving view while held, or none where it moves nothing.
  ##   Half of binding table; `actionFor` is other half.
  ##     `help.nim` renders keyboard rows out of both, so rebinding key rewrites help.
  ##   WASD slides across ground, arrows orbit.
  ##     Every editor binding WASD (Unity, Unreal, Godot, Blender fly mode) means "move" by
  ##     it; Q and E lower and raise.
  ##     Shift changes no direction; it multiplies every rate by `FACTOR_HASTE`; see
  ##     `driveHeld`.
  ##   Total by construction: every key answers, so suite can walk whole table.
  case key
  of Key.W: some(Motion.Forward)
  of Key.S: some(Motion.Back)
  of Key.A: some(Motion.Left)
  of Key.D: some(Motion.Right)
  of Key.Q: some(Motion.Down)
  of Key.E: some(Motion.Up)
  of Key.Left: some(Motion.OrbitLeft)
  of Key.Right: some(Motion.OrbitRight)
  of Key.Up: some(Motion.OrbitUp)
  of Key.Down: some(Motion.OrbitDown)
  of Key.Minus: some(Motion.DollyOut)
  of Key.Plus: some(Motion.DollyIn)
  of Key.F, Key.BracketLeft, Key.BracketRight, Key.Enter, Key.Home, Key.Shift:
    none(Motion)


func actionFor*(key: Key): Option[KeyAction] =
  ## Say what one press of key does to view, or none where it does nothing at press.
  ##   Every key that moves view instead; see `motionFor`.
  ##   Tab is absent: cycling objects with it risks keyboard trap (WCAG 2.1.2), so
  ##   traversal took brackets and Tab keeps meaning "next control".
  ##   F frames selection, as Unity, Godot and Blender (numpad `.`) bind.
  ##   Home stays placement both builds open at.
  case key
  of Key.BracketLeft: some(KeyAction.FocusPrevious)
  of Key.BracketRight: some(KeyAction.FocusNext)
  of Key.Enter: some(KeyAction.SelectFocused)
  of Key.F: some(KeyAction.FrameSelection)
  of Key.Home: some(KeyAction.ViewHome)
  of Key.W, Key.A, Key.S, Key.D, Key.Q, Key.E, Key.Left, Key.Right, Key.Up, Key.Down,
      Key.Minus, Key.Plus, Key.Shift:
    none(KeyAction)


func nameOf*(key: Key): string =
  ## Name key as reader would say it, for help table.
  case key
  of Key.W: "w"
  of Key.A: "a"
  of Key.S: "s"
  of Key.D: "d"
  of Key.Q: "q"
  of Key.E: "e"
  of Key.F: "f"
  of Key.Shift: "shift"
  of Key.Left: "left"
  of Key.Right: "right"
  of Key.Up: "up"
  of Key.Down: "down"
  of Key.BracketLeft: "["
  of Key.BracketRight: "]"
  of Key.Minus: "-"
  of Key.Plus: "+"
  of Key.Enter: "enter"
  of Key.Home: "home"


func armingOf*(button: PointerButton): Option[MenuArming] =
  ## Say whether button starts construction drag, and how that drag reaches its menu.
  ##   None for button starting no drag.
  ##     Middle is such button: hardware most trackpads lack, so nothing lives behind it.
  ##   Mouse never waits: left takes whatever pair makes; right asks from moment it arrives.
  ##     Same operations, differing only in whether reader is asked: redundancy for
  ##     different expertise, not mode split.
  ##   `MenuArming.OnDwell` is reachable from no button; touch alone; see `MenuArming`.
  case button
  of PointerButton.Left: some(MenuArming.Never)
  of PointerButton.Right: some(MenuArming.Always)
  of PointerButton.Middle: none(MenuArming)


func revealsMenuOn*(button: PointerButton): bool =
  ## Say whether click of this button brings up selection menu on what it picked.
  ##   Left selects and nothing more.
  ##     Doing both left reader who only wanted to pick dismissing menu they never asked
  ##     for.
  ##   Right carries it, where every other tool keeps context menu.
  ##   Stated here so both render paths and help answer from one rule.
  button == PointerButton.Right


func revealsWithoutPicking*(has_selection, is_menu_shown: bool): bool =
  ## Say whether menu-revealing click should only reveal, leaving selection alone.
  ##   Selection standing with menu dismissed is reader who wants menu back, so click
  ##   reveals and picks nothing.
  ##   With menu already up, same click picks what it landed on.
  ##     Right-click once for menu, again to repivot.
  ##   Shift never comes here: shifted click always adds or drops, then reveals.
  ##     Caller applies that, knowing modifier.
  has_selection and not is_menu_shown


func toDrag*(choice: DragChoice): Option[DragOperation] =
  ## Read choice as operation it applies, if it applies one.
  case choice
  of DragChoice.Join: some(DragOperation.Join)
  of DragChoice.Meet: some(DragOperation.Meet)
  of DragChoice.Project: some(DragOperation.Project)
  of DragChoice.More: none(DragOperation)


func toOperation*(drag: DragOperation): Operation =
  ## Translate drag's vocabulary to library's operation catalogue.
  case drag
  of DragOperation.Join: Operation.Wedge
  of DragOperation.Meet: Operation.WedgeAnti
  of DragOperation.Project: Operation.ProjectOrthogonal


func compassOf*(choice: DragChoice): Compass =
  ## Place choice in menu, fixed for life of program; see `Compass`.
  ##   North is default plain release takes most often, nearest cursor's resting direction.
  case choice
  of DragChoice.Join: Compass.North
  of DragChoice.Meet: Compass.East
  of DragChoice.Project: Compass.South
  of DragChoice.More: Compass.West


func labelOf*(choice: DragChoice): string =
  ## Name choice as its wedge says it, in catalogue's symbols.
  ##   Very text apply picker offers, through `scene.notationSymbolic`.
  ##     Wheel and picker are same control in two postures, so whichever reader meets first
  ##     teaches other; words are taught once, in drawer's intro line.
  ##   Projection's notation (`𝐧 ∨ (𝐦 ∧ 𝐧☆)`) is near twice width of word it replaces.
  ##     Affordable only at `Compass.South`, clear of two wedges it could collide with.
  ##     Moving choice to different compass point is decision about this label too.
  ##   `More` takes bare ellipsis: beside three pieces of notation word is odd one out.
  ##   `proc` for reason `scene.notationSymbolic` is one: table it reads is `let`.
  case choice
  of DragChoice.Join, DragChoice.Meet, DragChoice.Project:
    notationSymbolic(toOperation(toDrag(choice).get))
  of DragChoice.More: "…"


func wordOf*(choice: DragChoice): string =
  ## Name choice in words, for one place each is taught rather than offered.
  ##   Wedge says `𝐦 ∧ 𝐧` (see `labelOf`), readable only once told it is `join`.
  ##   Telling is drawer's legend line; this keeps legend and help table naming three same
  ##   way.
  case choice
  of DragChoice.Join: "join"
  of DragChoice.Meet: "meet"
  of DragChoice.Project: "project"
  of DragChoice.More: "more"


func inkOf*(choice: DragChoice): Ink =
  ## Tint choice, for its wedge and for rubber-band pointing at it.
  ##   Here rather than in either render path, so neither keeps copy of this table.
  case choice
  of DragChoice.Join: Ink.Jade
  of DragChoice.Meet: Ink.Rose
  of DragChoice.Project: Ink.Olive
  of DragChoice.More: Ink.Guide


func offsetOf(compass: Compass): tuple[x, y: float] =
  ## Point from menu's centre toward one wedge, one reach away, in screen pixels.
  ##   Screen y grows downward, so south is positive.
  case compass
  of Compass.North: (0.0, -PIXELS_MENU_REACH)
  of Compass.East: (PIXELS_MENU_REACH, 0.0)
  of Compass.South: (0.0, PIXELS_MENU_REACH)
  of Compass.West: (-PIXELS_MENU_REACH, 0.0)


func anchorOf*(centre: ScreenPosition, choice: DragChoice): ScreenPosition =
  ## Place one wedge on screen, given where its menu opened.
  let offset = offsetOf(compassOf(choice))
  ScreenPosition(x: centre.x + offset.x, y: centre.y + offset.y, depth: centre.depth)


func choiceAt*(centre, cursor: ScreenPosition): Option[DragChoice] =
  ## Say which wedge of menu opened at `centre` cursor stands in, if any.
  ##   Wedges are quadrants rather than discs: every direction outside deadzone belongs to
  ##   exactly one, with no gap to release into by accident.
  ##   Distance is unbounded, so overshooting wedge still picks it, which makes fast
  ##   confident throw work.
  let
    dx = cursor.x - centre.x
    dy = cursor.y - centre.y
  if dx*dx + dy*dy < PIXELS_MENU_DEADZONE*PIXELS_MENU_DEADZONE: return none(DragChoice)
  let compass =
    if abs(dx) > abs(dy): (if dx > 0.0: Compass.East else: Compass.West)
    else: (if dy > 0.0: Compass.South else: Compass.North)
  for choice in DragChoice:
    if compassOf(choice) == compass: return some(choice)
  none(DragChoice)


func resultOf*(choice: DragChoice; m, n: Multivector): Option[Multivector] =
  ## Compute what choice would make of these two operands, if it makes anything.
  ##   None for `More`, and none wherever result has no drawable shape.
  ##     One test covers both ways construction comes to nothing: wrong grades landing on
  ##     scalar or antiscalar, and pair lying on each other giving zero.
  ##     `objects.kindOf` reads `grade`, which already tolerances near-zero away, so line of
  ##     negligible magnitude reports no shape.
  let drag = toDrag(choice)
  if drag.isNone: return
  let derived = applyOperation(drag.get.toOperation, m, n)
  if kindOf(derived).isNone: return
  some(derived)


func isOffered*(choice: DragChoice; m, n: Multivector): bool =
  ## Report whether choice would make something of these two operands.
  ##   `More` is always offered: only route from this gesture to rest of catalogue.
  choice == DragChoice.More or resultOf(choice, m, n).isSome


func proposalFor*(m, n: Multivector): Option[DragChoice] =
  ## Choose what plain release should make of these two operands, if anything.
  ##   Order, not ranking.
  ##     Over every ordered pair of point, line and plane, at most one of join and meet is
  ##     ever drawable, so there is never tie, and `project` picks up pairs where neither
  ##     is.
  ##     Suite pins that; it is whole reason this is order rather than table of nine cases.
  ##   None for pair making nothing (plane dragged onto point), so release refuses rather
  ##   than inventing something to add.
  for choice in [DragChoice.Join, DragChoice.Meet, DragChoice.Project]:
    if isOffered(choice, m, n): return some(choice)
  none(DragChoice)


func choosing*(interaction: Interaction): Option[DragChoice] =
  ## Say which wedge of open menu cursor stands in.
  ##   None where no menu is open and none where cursor has come back to open one's centre.
  ##   One statement of which wedge, so highlight each front-end draws, ghost `updateDrag`
  ##   shapes and object `endDrag` commits are never three opinions.
  if interaction.menu.isNone: return none(DragChoice)
  choiceAt(interaction.menu.get, interaction.cursor)


type ReleaseEffect* {.pure.} = enum ## Define what letting go right now would do.
  ## Three outcomes, not two.
  ##   Release that quietly does nothing and one that refuses want opposite feedback, and
  ##   once menu is open both are reachable over same pair.
  Nothing, ## End gesture and build nothing, with nothing to warn about.
    ## Over empty space, over drag's own source, or back at open menu's centre.
  Refused, ## Reach pair that makes nothing drawable, and say so.
  Builds, ## Add object; or, for `More`, hand pair to apply picker.
    ## Picker takes very hue wheel has been showing.


func effectOf*(interaction: Interaction): ReleaseEffect =
  ## Resolve what letting go right now would do, from drag's own state.
  ##   Reads `proposal` and `preview`, which `updateDrag` resolved in `endDrag`'s order,
  ##   rather than re-deriving: second derivation is second answer waiting to disagree.
  if not interaction.is_over_target: return ReleaseEffect.Nothing
  if interaction.proposal.isNone:
    # Tell two ways to have no answer apart.
    #   At centre of wheel that may veto, gesture is being called off; everywhere else pair
    #   makes nothing, refusal to warn about.
    #   Unentered dwell wheel already carries pair's answer, so none there means pair makes
    #   nothing.
    return
      if interaction.menu.isSome and
          (interaction.is_menu_entered or interaction.arming != MenuArming.OnDwell):
        ReleaseEffect.Nothing
      else: ReleaseEffect.Refused
  if interaction.proposal.get == DragChoice.More: return ReleaseEffect.Builds
  if interaction.preview.isSome: ReleaseEffect.Builds else: ReleaseEffect.Refused


func inkOfDrag*(interaction: Interaction, ink_next: Ink): Ink =
  ## Tint rubber-band of drag in progress by what releasing it would do.
  ##   One state per `ReleaseEffect`: neutral, reserved `Ink.Invalid` magenta for refusal,
  ##   and hue new object will actually be for build.
  ##     Warning arrives before release, and never by colour alone, since ghost
  ##     simultaneously fails to appear.
  ##   With wheel open all three are reachable without leaving pivot.
  ##     Centre is neutral where wheel may veto; unentered dwell wheel's centre keeps build
  ##     hue, since lifting there builds; see `endDrag`.
  ##     Greyed wedge magenta, offered wedge new object's hue.
  ##   `ink_next` is `scene.inkNext`, passed in since this has no scene.
  ##     Operation's own colour would say nothing about object reader is about to have.
  case interaction.effectOf
  of ReleaseEffect.Nothing: Ink.Guide
  of ReleaseEffect.Refused: Ink.Invalid
  of ReleaseEffect.Builds: ink_next



#[ Cursor And Hover ]#

func updateCursor*(interaction: var Interaction; x, y: float) =
  ## Record cursor's latest window position, and note whether press has become drag.
  interaction.cursor = ScreenPosition(x: x, y: y, depth: 0.0)
  if interaction.is_press_still:
    let
      dx = interaction.cursor.x - interaction.pressed.x
      dy = interaction.cursor.y - interaction.pressed.y
    if dx*dx + dy*dy > PIXELS_CLICK_SLOP*PIXELS_CLICK_SLOP:
      interaction.is_press_still = false


func isMovingCamera*(interaction: Interaction): bool =
  ## Report whether camera is being moved right now, by pointer or by key.
  ##   Key half answered here since `keys_held` is this module's.
  ##   `Key.Shift` alone is not movement, so this asks `motionFor` rather than counting
  ##   keys.
  if interaction.is_dragging_camera: return true
  for key in interaction.keys_held:
    if motionFor(key).isSome: return true
  false


proc updateHover*(
  interaction: var Interaction; scene: Scene; camera: Camera; scale: DrawExtent;
  view_projection: Matrix4; width, height: int; placed: openArray[Placement] = []
) =
  ## Recompute object nearest cursor, so overlay and drag-start agree on what stands under it.
  ##   Nothing is hovered while camera is moving.
  ##     Hover is recomputed every frame, so pan drag would highlight across every object
  ##     it sweeps, and held W would light up whatever slides under still cursor.
  ##     Ring comes back frame move ends.
  if interaction.is_enabled and not interaction.isMovingCamera:
    let report = pickAt(
      scene, camera, scale, view_projection, width, height, interaction.cursor, placed,
    )
    interaction.index_hover = report.handle
    interaction.count_hover_rivals = report.count_rivals
  else:
    interaction.index_hover = none(int)
    interaction.count_hover_rivals = 0
  # Note backdrop here, where scene is in hand; see `is_hover_backdrop`.
  interaction.is_hover_backdrop =
    interaction.index_hover.isSome and
    isBackdropUnder(scene, interaction.index_hover.get, scale, width, height)



#[ Keyboard ]#

proc dollyAt*(
  camera: var Camera; scene: Scene; factor: float; scale: DrawExtent;
  view_projection: Matrix4; width, height: int; cursor: ScreenPosition;
  placed: openArray[Placement] = []
) =
  ## Zoom camera by `factor` toward whatever `cursor` is over; see `dollyAtCursor`.
  ##   Cursor is parameter so pinch, which has no cursor, aims at frame's middle through
  ##   same rule; see `dollyAtCentre`.
  # Take caller's extent and matrix, not fresh derivations per notch; see
  #   `picking.anchorZoomAt`.
  let anchor = anchorZoomAt(
    scene, camera, scale, view_projection, width, height, cursor, placed,
  )
  if anchor.isNone:
    camera.dolly(factor)
    return
  camera.dollyToward(factor, anchor.get.at)
  if anchor.get.is_standing:
    # Depth from eye where it now stands, along sight direction zoom left unchanged.
    let eye = camera.eye
    let depth = dot(anchor.get.at - eye, camera.frame(eye).forward)
    if depth > 0.0: camera.repivotToDepth(depth)


proc dollyAtCentre*(
  camera: var Camera; scene: Scene; factor: float; scale: DrawExtent;
  view_projection: Matrix4; width, height: int; placed: openArray[Placement] = []
) =
  ## Zoom camera by `factor` toward whatever middle of frame is over; pinch's zoom.
  ##   Pinch has two fingers and no pointer, and zooming at their midpoint translated
  ##   view twice beside pan that carries same midpoint; middle of frame it is, aimed
  ##   through `dollyAt` so pivot still lands on point or line there.
  dollyAt(
    camera, scene, factor, scale, view_projection, width, height,
    ScreenPosition(x: float(width)/2.0, y: float(height)/2.0), placed,
  )


proc dollyAtCursor*(
  interaction: Interaction; camera: var Camera; scene: Scene; factor: float;
  scale: DrawExtent; view_projection: Matrix4; width, height: int;
  placed: openArray[Placement] = []
) =
  ## Zoom camera by `factor`, toward whatever cursor is over.
  ##   One statement of what wheel notch does, so both front-ends and pinch zoom same way.
  ##   `picking.anchorZoomAt` decides what "over" means: object under cursor, ground under
  ##   it, or level pivot sits on, in that order.
  ##   Falls back to plain `dolly` where none answers, cursor on empty sky above horizon.
  ##   Where anchor is point or line, pivot then follows its depth along sight line; see
  ##   `camera.repivotToDepth` and `picking.AnchorZoom`.
  dollyAt(camera, scene, factor, scale, view_projection, width, height, interaction.cursor,
    placed)


func panAcross*(
  camera: var Camera; before, after: ScreenPosition; width, height: int
) =
  ## Slide view so world point under `before` comes to lie under `after`.
  ##   Grab, not rate.
  ##     Rate per dragged pixel is right at one depth and tilt and wrong everywhere else.
  ##     `camera.pan` slides pivot within plane facing eye, which is tilted, so vertical
  ##     drag lifted pivot off ground, every later orbit swung about point on nothing, and
  ##     later zoom scaled by distance to nowhere.
  ##   Both rays meet horizontal plane through pivot, `positionUnderCursor`'s surface, so
  ##   translation between hits is horizontal by construction.
  ##     Plane rather than object under pointer because drag needs one surface for its
  ##     whole length.
  ##   Falls back to rate where either ray misses that plane: drag beginning or ending on
  ##   sky above horizon.
  let
    eye_point = toMultivector(camera.eye)
    pivot_point = toMultivector(camera.pivot)
    level = levelPlaneThrough(pivot_point)
    reach_max = FACTOR_PAN_REACH_MAX*camera.distance
  func heldFoot(hit: Option[Position]): Option[Multivector] =
    ## Draw hold point no further out than bound along its ray, then take its foot on level.
    ##   Both feet share level by construction, so step between them carries none of
    ##   clamp's vertical artefact.
    if hit.isNone: return
    var held = toMultivector(hit.get)
    let reach = distanceBetween(held, eye_point)
    if reach > reach_max and reach > 0.0:
      held = add(eye_point, wedge(reach_max/reach, subtract(held, eye_point)))
    some(unitize(projectOrthogonal(held, level)))
  let
    at_before = heldFoot(positionUnderCursor(camera, width, height, before))
    at_after = heldFoot(positionUnderCursor(camera, width, height, after))
  if at_before.isSome and at_after.isSome:
    let carried = position(add(
      pivot_point, subtract(at_before.get, at_after.get)
    ))
    if carried.isSome:
      camera.pivot = carried.get
      return
  camera.pan(
    -FRACTION_PAN_PIXEL*(after.x - before.x), FRACTION_PAN_PIXEL*(after.y - before.y)
  )


func holdKey*(interaction: var Interaction, key: Key) =
  ## Note key as held, so `driveHeld` moves camera by it every frame until released.
  ##   Harmless on key already held, which is what auto-repeat sends.
  interaction.keys_held.incl(key)


func releaseKey*(interaction: var Interaction, key: Key) =
  ## Note key as let go of.
  ##   Harmless on key not held, which is what release arriving after `releaseKeysAll` is.
  interaction.keys_held.excl(key)


func releaseKeysAll*(interaction: var Interaction) =
  ## Let go of every held key at once, for view that has stopped being told about releases.
  ##   Window losing focus, reader tabbing into panel.
  ##   Not nicety: release of key held at that moment is delivered elsewhere, so without
  ##   this camera moves forever.
  interaction.keys_held = {}


func driveHeld*(interaction: Interaction, camera: var Camera, seconds: float) =
  ## Move camera by every key currently held, for one frame of `seconds`.
  ##   Called once per frame by both render paths rather than at each key event.
  ##     Makes hold read as continuous movement rather than OS auto-repeat, and lets two
  ##     keys held together compose without enumerating pairs.
  ##   Every rate is per second, multiplied by `seconds`, so travel depends on how long key
  ##   was held rather than how fast machine draws.
  ##     Dolly compounds, so it takes `FACTOR_DOLLY_SECOND` to power of elapsed seconds.
  ##     Shift multiplies every rate by `FACTOR_HASTE`.
  if interaction.keys_held.len == 0: return
  let
    haste = if Key.Shift in interaction.keys_held: FACTOR_HASTE else: 1.0
    turn = TURN_SECOND*haste*seconds
    rise = RISE_SECOND*haste*seconds
    slide = SLIDE_SECOND*haste*seconds
    dolly = pow(FACTOR_DOLLY_SECOND, haste*seconds)
  for key in interaction.keys_held:
    let motion = motionFor(key)
    if motion.isNone: continue
    case motion.get
    of Motion.Forward: camera.slideGround(slide, 0.0, 0.0)
    of Motion.Back: camera.slideGround(-slide, 0.0, 0.0)
    of Motion.Left: camera.slideGround(0.0, -slide, 0.0)
    of Motion.Right: camera.slideGround(0.0, slide, 0.0)
    of Motion.Down: camera.slideGround(0.0, 0.0, -slide)
    of Motion.Up: camera.slideGround(0.0, 0.0, slide)
    of Motion.OrbitLeft: camera.orbit(-turn, 0.0)
    of Motion.OrbitRight: camera.orbit(turn, 0.0)
    of Motion.OrbitUp: camera.orbit(0.0, rise)
    of Motion.OrbitDown: camera.orbit(0.0, -rise)
    of Motion.DollyIn: camera.dolly(1.0/dolly)
    of Motion.DollyOut: camera.dolly(dolly)


func applyAction*(
  interaction: var Interaction, camera: var Camera, scene: Scene, action: KeyAction
): Option[int] =
  ## Carry out one keyboard action, and report which object caller should select.
  ##   Moves camera and focus, both its own state; does not touch selection, which each
  ##   render path owns differently.
  ##     Reporting handle leaves caller to read shift state and decide between replacing
  ##     selection and adding; see `KeyAction.SelectFocused`.
  ##   None for every action but select, and for select with nothing focused.
  ##   `FrameSelection` does nothing here.
  ##     Framing reads selection, and both paths already offer camera aim over it once per
  ##     frame (`framing.offerAim`).
  ##     Key only clears goal that offer holds, via `CameraTween.release` on each path's
  ##     tween.
  case action
  of KeyAction.FocusPrevious: interaction.index_focus = scene.handleStepped(
    interaction.index_focus, -1
  )
  of KeyAction.FocusNext: interaction.index_focus = scene.handleStepped(
    interaction.index_focus, 1
  )
  of KeyAction.SelectFocused:
    if interaction.index_focus.isSome and scene.isAlive(interaction.index_focus.get):
      return interaction.index_focus
  of KeyAction.FrameSelection: discard
  of KeyAction.ViewHome:
    # Return to placement both builds open at, so "home" means same as starting again.
    camera = initCameraDefault()
  none(int)


func pruneFocus*(interaction: var Interaction, scene: Scene) =
  ## Drop keyboard focus whose object has gone, same guard selection keeps.
  ##   Handle carried across frames may be freed by any other input path, and focus left
  ##   pointing at dead one would have marker drawn off freed storage.
  if interaction.index_focus.isSome and not scene.isAlive(interaction.index_focus.get):
    interaction.index_focus = none(int)



#[ Hold Lifecycle ]#

func beginHold*(interaction: var Interaction, handle: int, now: float) =
  ## Start press on `handle` that selects it once it has lasted long enough.
  interaction.hold = some(
    Hold(handle: handle, started: now, is_taken: false, released: none(float))
  )


func releaseHold*(interaction: var Interaction, now: float) =
  ## Note that finger has lifted, starting marker's settle back to true size.
  ##   Distinct from `cancelHold`: press ending as press is meant to settles; press that
  ##   stopped being one (moved into camera gesture, second finger, escape) snaps away.
  ##   Records moment rather than clearing hold: swell still has phase to run, and
  ##   `swellHold` retires hold once spent.
  if interaction.hold.isNone or interaction.hold.get.released.isSome: return
  interaction.hold.get.released = some(now)


func cancelHold*(interaction: var Interaction) =
  ## Abandon press in progress, selecting nothing.
  ##   For finger moved into camera gesture, second finger landing, early release, escape.
  interaction.hold = none(Hold)


func progressHold*(interaction: Interaction, now: float): float =
  ## Report how far press in progress has matured, 0 at press to 1 once due.
  ##   Zero with no press.
  ##   Clamped at both ends, so caller may keep asking after due and after clock jumps.
  ##   Linear, not through `tessellate.easeOutCubic`.
  ##     This is clock being shown, and eased clock reads as stalling just before it fires,
  ##     where reader decides whether hold works.
  ##   Starts only once `SECONDS_SWELL_GROW` has passed, so marker is at size it fills at
  ##   before filling; see `swellHold`.
  if interaction.hold.isNone: return 0.0
  let elapsed = now - interaction.hold.get.started - SECONDS_SWELL_GROW
  max(0.0, min(1.0, elapsed/SECONDS_LONG_PRESS))


func swellHold*(interaction: Interaction, now: float): float =
  ## Report how far touched object's marker is swollen clear of finger, 0 to 1.
  ##   Zero at true size, one fully out, zero with no press.
  ##   Own clock, not fill's, in four phases:
  ##
  ##   | Phase  | While                                        | Swell           |
  ##   |--------|----------------------------------------------|-----------------|
  ##   | grow   | first `SECONDS_SWELL_GROW`                   | 0 rising to 1   |
  ##   | fill   | `SECONDS_LONG_PRESS` after that              | 1               |
  ##   | held   | however long finger stays down past maturity | 1               |
  ##   | settle | `SECONDS_SWELL_SHRINK` after lift            | 1 falling to 0  |
  ##
  ##   Held phase is point of arrangement.
  ##     Swell as half sine over fill put marker back at true size exactly when selection
  ##     landed; it stays out until finger says otherwise.
  ##   Eased at both ends through `tessellate.easeOutCubic`, unlike `progressHold`: these
  ##   are transitions, that is clock.
  if interaction.hold.isNone: return 0.0
  let hold = interaction.hold.get
  if hold.released.isSome:
    let settling = (now - hold.released.get)/SECONDS_SWELL_SHRINK
    return 1.0 - easeOutCubic(clamp(settling, 0.0, 1.0))
  easeOutCubic(clamp((now - hold.started)/SECONDS_SWELL_GROW, 0.0, 1.0))


func isHoldSpent*(interaction: Interaction, now: float): bool =
  ## Report whether released hold has finished settling and may be forgotten.
  ##   Asked by caller owning frame loop, so hold retires on frame boundary.
  ##   Hold under finger is never spent.
  ##   Stated against `swellHold` rather than against `SECONDS_SWELL_SHRINK` again, as
  ##   `isHoldMature` does.
  ##     Two comparisons against one duration are two chances to disagree, and here they
  ##     would: subtracting two large timestamps loses precision, so elapsed time measures
  ##     hair under duration itself.
  interaction.hold.isSome and interaction.hold.get.released.isSome and
    swellHold(interaction, now) <= 0.0


func isHoldMature*(interaction: Interaction, now: float): bool =
  ## Report whether press in progress has lasted long enough to select its object.
  ##   Stated against `progressHold`, so moment marker finishes filling is moment
  ##   selection lands.
  interaction.hold.isSome and progressHold(interaction, now) >= 1.0


func takeHold*(interaction: var Interaction, now: float): Option[int] =
  ## Report handle matured hold selects, exactly once, and nothing on later calls.
  ##   None while hold is filling, none with no hold.
  ##   Replaces "is it mature" beside caller's "have I acted" flag.
  ##     Those stopped agreeing once hold outlived its release: caller cleared flag on lift
  ##     while hold was settling and still mature, so next frame selected object again and
  ##     toggled it off.
  ##   Taking does not end hold; what is spent is selection, not gesture.
  if interaction.hold.isNone or interaction.hold.get.is_taken: return
  if not isHoldMature(interaction, now): return
  interaction.hold.get.is_taken = true
  some(interaction.hold.get.handle)



#[ Drag Lifecycle ]#

func destinationOf*(interaction: Interaction): Option[int] =
  ## Say which object drag in progress points at, for its release to build with.
  ##   Hover while no menu is open; object menu opened over once one is.
  ##     Menu opens centred on cursor, so reaching wedge takes cursor off object, and
  ##     destination read from hover would go none exactly when release needs it.
  ##   None over sky, same refusal `beginDrag` makes.
  ##     Release over backdrop stays "nothing done" rather than taking whole sky as operand.
  if interaction.menu.isSome: interaction.index_destination
  elif interaction.is_hover_backdrop: none(int)
  else: interaction.index_hover


func beginPress*(interaction: var Interaction, now: float) =
  ## Note where and when pointer press landed, whatever that press turns out to be.
  ##   Every press goes through this, because `isClick` answers same question about all.
  ##     Click on object selects, click on empty space clears, neither is drag.
  ##   Call at press, before `beginDrag`, not from inside it.
  ##     Touch path reaches `beginDrag` once finger has travelled past tap, and
  ##     re-anchoring there would let short deliberate drag report itself as click.
  ##   Forgetting fails safe: `is_press_still` is false until this raises it.
  interaction.pressed = interaction.cursor
  interaction.started = now
  interaction.is_press_still = true


func isClick*(interaction: Interaction, now: float): bool =
  ## Report whether press in progress is still click rather than drag.
  ##   Distance alone decides: press within `PIXELS_CLICK_SLOP` of where it landed is
  ##   click however long held.
  ##     Asked at release by whichever path resolves press.
  ##   No deadline, deliberately.
  ##     Dwell is touch-only and mouse wheel opens on arriving over another object, so
  ##     deadline could only drop clicks hand lingered on.
  ##   `now` still taken, so caller need not know answer stopped needing it.
  discard now
  interaction.is_press_still


func canConstructByTouch*(interaction: Interaction): bool =
  ## Report whether press where finger stands may become construction drag.
  ##   Hovered, not sky, and unambiguous: exactly one object of winning rank in reach.
  ##   Finger sees no hover ring before it lands, so over crowd it cannot know which of
  ##   several it is dragging; where gesture is ambiguous, movement wins, and reader zooms
  ##   in until it is not. Mouse keeps its drag: ring showed it which one.
  ##   Asked by `beginDrag` at slop and by browser at press, so both agree; see
  ##   `glue.js`'s `is_touch_press_constructing`.
  interaction.index_hover.isSome and not interaction.is_hover_backdrop and
    interaction.count_hover_rivals <= 1


func beginDrag*(interaction: var Interaction, arming: MenuArming, now: float): bool =
  ## Start construction drag from object currently hovered.
  ##   Reports whether one started, so caller knows whether to fall back to camera.
  ##   `arming` is what pointer chose; see `MenuArming` and `armingOf`.
  ##   Expects `beginPress` to have run for same press.
  ##   Backdrop is click and hold pivot, never drag handle; see `is_hover_backdrop`.
  ##     Plane at horizon is drawn as dome over every direction, hovered wherever nothing
  ##     else is; press on it starting drag would stop press on empty space falling
  ##     through to camera. Plane filling view leaves no empty space at all, so press on
  ##     it starting drag left view unmovable. Dragging backdrop is moving view.
  ##   Touch, `MenuArming.OnDwell`, also refuses crowd; see `canConstructByTouch`.
  if interaction.index_hover.isNone or interaction.is_hover_backdrop: return false
  if arming == MenuArming.OnDwell and not interaction.canConstructByTouch: return false
  interaction.is_dragging = true
  interaction.index_source = interaction.index_hover.get
  interaction.index_destination = none(int)
  interaction.arming = arming
  interaction.entered = now
  interaction.settled = interaction.cursor
  interaction.menu = none(ScreenPosition)
  interaction.is_menu_entered = false
  interaction.index_disengaged = none(int) # Fresh drag holds nothing at arm's length.
  interaction.is_over_target = false
  interaction.proposal = none(DragChoice)
  interaction.preview = none(Preview)
  true


func cancelDrag*(interaction: var Interaction) =
  ## Abandon drag in progress without applying anything.
  interaction.is_dragging = false
  interaction.menu = none(ScreenPosition)
  interaction.is_menu_entered = false
  interaction.index_disengaged = none(int) # Or next drag opens no menu over that object.
  interaction.is_over_target = false
  interaction.proposal = none(DragChoice)
  interaction.preview = none(Preview)


func updateDrag*(
  interaction: var Interaction, scene: Scene, now: float
) =
  ## Recompute what drag in progress would make and whether its menu should be open.
  ##   For frame about to draw.
  ##   Called after `updateHover`, which decides where drag points.
  ##   Preview is whatever release would commit: wedge cursor stands in while menu is open,
  ##   `proposalFor`'s answer where none is.
  ##     One rule, drawn then obeyed; ghosting plain-release answer under open wheel had
  ##     reader aiming at `meet` watch ghost of `join`.
  if not interaction.is_dragging:
    interaction.is_over_target = false
    interaction.proposal = none(DragChoice)
    interaction.preview = none(Preview)
    interaction.menu = none(ScreenPosition)
    return

  # Let go of menu cursor has left.
  #   Wheel opened on wrong object then costs movement rather than whole gesture.
  #   Everything after reads `menu` again, so clearing it is whole of re-aiming;
  #   `index_source` is never touched; see `PIXELS_MENU_DISENGAGE`.
  if interaction.menu.isSome:
    let
      dx_menu = interaction.cursor.x - interaction.menu.get.x
      dy_menu = interaction.cursor.y - interaction.menu.get.y
    if dx_menu*dx_menu + dy_menu*dy_menu >
        PIXELS_MENU_DISENGAGE*PIXELS_MENU_DISENGAGE:
      interaction.menu = none(ScreenPosition)
      interaction.index_disengaged = interaction.index_destination
      interaction.entered = now
      interaction.settled = interaction.cursor

  # Latch what drag points at while no menu is open, so one that opens acts on it.
  if interaction.menu.isNone: interaction.index_destination = interaction.index_hover

  # Stop holding pivot at arm's length once drag has left it.
  if interaction.index_disengaged.isSome and
      interaction.index_hover != interaction.index_disengaged:
    interaction.index_disengaged = none(int)

  let over = destinationOf(interaction)
  interaction.is_over_target =
    over.isSome and over.get != interaction.index_source and
    scene.isAlive(over.get) and scene.isAlive(interaction.index_source)
  if not interaction.is_over_target:
    # Restart dwell wherever drag next arrives, having left pivot.
    interaction.proposal = none(DragChoice)
    interaction.preview = none(Preview)
    interaction.entered = now
    interaction.settled = interaction.cursor
    return

  # Restart dwell on movement, so it measures being still.
  #   On presence alone, slow drag over plane's disc spanning phone screen opened menu
  #   mid-gesture and built nothing.
  let
    dx = interaction.cursor.x - interaction.settled.x
    dy = interaction.cursor.y - interaction.settled.y
  if dx*dx + dy*dy > PIXELS_TAP_SLOP*PIXELS_TAP_SLOP:
    interaction.entered = now
    interaction.settled = interaction.cursor

  # Open menu before resolving release, since with one open answer is wedge cursor stands in.
  #   Resolved after, opening frame ghosted plain-release answer under wheel already
  #   standing over centre, which chooses nothing.
  let is_menu_due = case interaction.arming
    of MenuArming.Never: false
    of MenuArming.OnDwell: now - interaction.entered >= SECONDS_DWELL_MENU
    of MenuArming.Always: true
  if interaction.menu.isNone and is_menu_due and interaction.index_disengaged.isNone:
    interaction.menu = some(interaction.cursor)
    interaction.is_menu_entered = false

  let
    m = scene.geometryOf(interaction.index_source)
    n = scene.geometryOf(over.get)
  # Resolve in `endDrag`'s order.
  #   Wheel answers where open, `proposalFor` where none, except dwell wheel nobody has
  #   entered answers nothing at centre, so pair's answer stands.
  if interaction.menu.isSome and interaction.choosing.isSome:
    interaction.is_menu_entered = true
  interaction.proposal =
    if interaction.menu.isNone: proposalFor(m, n)
    elif interaction.choosing.isNone and not interaction.is_menu_entered and
        interaction.arming == MenuArming.OnDwell:
      proposalFor(m, n)
    else: interaction.choosing
  # Ghost through `scene.previewApplying`, same call both apply pickers offer from.
  #   Gesture's ghost and picker's ghost are one thing, anchor included; `More` previews
  #   nothing.
  let drag = if interaction.proposal.isSome: toDrag(interaction.proposal.get)
    else: none(DragOperation)
  interaction.preview =
    if drag.isSome:
      scene.previewApplying(
        drag.get.toOperation, interaction.index_source, over.get
      )
    else: none(Preview)


type DragOutcome* = object ## Define everything released drag did, for caller to act on.
  message*: string ## What to say happened, whether or not anything was built.
  index_created*: Option[int] ## Object added, where one was.
    ## None for refusal, for release choosing nothing, and for `More`.
  choice*: Option[DragChoice] ## What release resolved to.
    ## So caller recognises `More`, otherwise indistinguishable from refusal.
  operands*: Option[tuple[source, destination: int]] ## Two objects, where both were alive
    ## and distinct.
    ## What `More` hands to apply section; drag's state is cleared by time caller reads
    ## this.
  index_clicked*: Option[int] ## Object press that never became drag came down on, for
    ## caller to select.
    ## None for every actual drag.


func commitChoice*(
  interaction: var Interaction, scene: var Scene, choice: DragChoice, now: float
): DragOutcome =
  ## Apply one choice between drag's source and whatever it points at.
  ##   Split out of `endDrag` so menu choice and plain-release proposal reach scene through
  ##   identical path.
  ##   Refuses rather than adding object that draws nothing: message and no object, which is
  ##   why `index_created` is `Option`.
  ##     Menu greys wedges this would refuse.
  let over = destinationOf(interaction)
  # Stay silent as `endDrag` is.
  #   Reachable only through menu whose pivot went away under it.
  if over.isNone: return DragOutcome()
  if over.get == interaction.index_source:
    return DragOutcome(message: "Released on its own source; nothing done.")
  if not (scene.isAlive(interaction.index_source) and scene.isAlive(over.get)):
    return DragOutcome(message: "Source or destination no longer exists; nothing done.")

  let
    label_source = toText(scene.labelAt(interaction.index_source))
    label_destination = toText(scene.labelAt(over.get))
    m = scene.geometryOf(interaction.index_source)
    n = scene.geometryOf(over.get)
    operands = some((source: interaction.index_source, destination: over.get))
  if choice == DragChoice.More:
    return DragOutcome(
      message: &"{label_source} and {label_destination} ready to apply.",
      choice: some(choice),
      operands: operands,
    )

  # Name through catalogue's notation, as panel's apply button names same pair.
  #   Drag and panel apply then produce byte-identical labels.
  let
    operation = toDrag(choice).get.toOperation
    label = notationSubstituted(operation, label_source, label_destination)
    derived = resultOf(choice, m, n)
  if derived.isNone:
    return DragOutcome(
      message: &"{label} makes nothing drawable; nothing added.",
      choice: some(choice),
      operands: operands,
    )

  # Refuse gesture on full scene rather than asserting through it.
  #   Every panel path checks `isFull`; drag commits here in shared code, and preset can
  #   fill scene in one click.
  if scene.isFull:
    return DragOutcome(
      message: &"The scene holds all {OBJECTS_MAX} objects it can; {label} was not added.",
      choice: some(choice),
      operands: operands,
    )

  let
    anchor = creationAnchor(operation, m, n, derived.get)
    index_created =
      scene.addObject(derived.get, label, scene.takeInk(), now, anchor)
  DragOutcome(
    message: &"{label} gave {kindText(derived.get)}.",
    index_created: some(index_created),
    choice: some(choice),
    operands: operands,
  )


func endDrag*(
  interaction: var Interaction, scene: var Scene, now: float = 0.0
): DragOutcome =
  ## End drag in progress, applying whatever release resolved to.
  ##   One release rule: release commits whatever is under cursor.
  ##     With menu open, wedge cursor stands in, nothing at centre, unless menu is dwell
  ##     wheel nobody entered, which may not veto: there release takes `proposalFor`'s
  ##     answer as if wheel never opened.
  ##     With no menu, `proposalFor`'s answer.
  ##     Either way what `interaction.proposal` holds and what preview has ghosted;
  ##     `updateDrag` resolves in same order, off `choosing`.
  ##   Wedge resolved here rather than in each render path, so neither can disagree about
  ##   which wedge release landed in.
  ##   Always clears drag state; message names outcome even where nothing was done.
  let was_dragging = interaction.is_dragging
  defer:
    # Step palette whether or not gesture built.
    #   Offering same colour to next attempt reads as gesture never registering.
    #   Release that built took hue through `takeInk`; click is excluded (selecting is not
    #   constructing); `More` is excluded, since apply picker it opens takes hue wheel
    #   previewed.
    if was_dragging and result.index_clicked.isNone and result.index_created.isNone and
        result.choice != some(DragChoice.More):
      scene.skipInk()
    interaction.cancelDrag()
  if not interaction.is_dragging: return DragOutcome()

  # Treat press that never moved as click, which selects what it came down on.
  #   Answered here because drag it abandons was begun here: press over object starts drag
  #   eagerly, and whether it was one is knowable only at release.
  #   Open menu excludes click, not arming: wheel opens only over pivot other than source,
  #   so right press that never left its object opened none, and refusing it would leave
  #   right button doing nothing on plain click.
  if interaction.menu.isNone and interaction.isClick(now):
    return
      if scene.isAlive(interaction.index_source):
        DragOutcome(index_clicked: some(interaction.index_source))
      else:
        DragOutcome() # Removed under press; nothing to select and nothing to say.

  if interaction.menu.isSome:
    let choice = interaction.choosing
    if choice.isSome: return commitChoice(interaction, scene, choice.get, now)
    # Let wheel reader summoned veto release, never one that invited itself.
    #   Right press asked for wheel, so lifting at centre withdraws, as does lifting there
    #   after walking into wedge on any wheel.
    #   Dwell wheel arrives unasked under finger pausing to aim, covered by that finger;
    #   reading release as "chose nothing" before first entry eats build ghost promised.
    #   Pausing before lifting is common touch release, and it built nothing every time.
    if interaction.is_menu_entered or interaction.arming != MenuArming.OnDwell:
      return DragOutcome(message: "Released without choosing; nothing done.")

  let over = destinationOf(interaction)
  # Say nothing about release over nothing.
  #   Reader can see no object arrived, and message on every abandoned gesture fires on
  #   commonest thing reader does.
  #   Refusals below landed on something and still built nothing, which reader cannot read
  #   off screen.
  if over.isNone: return DragOutcome()
  if over.get == interaction.index_source:
    return DragOutcome(message: "Released on its own source; nothing done.")
  if not (scene.isAlive(interaction.index_source) and scene.isAlive(over.get)):
    return DragOutcome(message: "Source or destination no longer exists; nothing done.")

  let proposal = proposalFor(
    scene.geometryOf(interaction.index_source), scene.geometryOf(over.get)
  )
  if proposal.isNone:
    let
      label_source = toText(scene.labelAt(interaction.index_source))
      label_destination = toText(scene.labelAt(over.get))
    return DragOutcome(
      message: &"{label_source} and {label_destination} make nothing drawable; " &
        "nothing added.",
      operands: some((source: interaction.index_source, destination: over.get)),
    )
  commitChoice(interaction, scene, proposal.get, now)
