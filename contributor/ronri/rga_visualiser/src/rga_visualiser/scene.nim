## Hold objects visualiser draws, and catalogue of operations that derive new ones.
##
## Scene is fixed-capacity and owned by caller, so nothing is allocated after setup.
##   Storage is structure-of-arrays, one array per field, addressed by slot rather than
##   dense position: slot is assigned once, on `addItem`, and never moves again.
##   Label is fixed char storage rather than string, so GUI can edit it in place.
## Free slots thread onto intrusive singly-linked list, `next_free`.
##   `addItem` and `removeItem` run in constant time however many items scene holds.
##   Link lives inside slot array itself; dead slot's `next_free` costs nothing beyond what
##   slot carries while alive.
##   Stable slot keeps every cross-frame index GUI holds (operands picked, item hovered,
##   item mid-drag) valid, narrowing staleness to removed item's own references, without
##   generation counter.
## Operation catalogue is what makes scene live rather than scripted.
##   Every entry is one of library's named aliases, applied to items user picks.
##
##   |---------|--------------------------------|--------------------------------------|
##   | Arity   | Operations                     | Meaning                              |
##   |---------|--------------------------------|--------------------------------------|
##   | One     | ⊖ ∩ ∪ \ / ★ ☆ ~ ~∘ - ^ ∙ ∘     | Attitude, support, duals, norms.     |
##   | Two     | + - ∧ ∨ ⟑ ⟇ ∙ ∘ ∧★ ∧☆ ∨★ ∨☆    | Join, meet, geometric products.      |
##   |---------|--------------------------------|--------------------------------------|
##
## Shared by desktop (`visualiser.nim`) and browser (`browser_bridge.nim`) render paths.
##   `saveScene`/`loadScene` are native-only (`when not defined(js)`); browser saves and
##   loads via download/upload.

{.experimental: "strictFuncs".}

import std/[math, options, strformat, strutils, unicode]

# `pga` arrives through `projections`, which stands in for four it has withdrawn.
import ./projections
import ./[boundary, format, tessellate]



#[ Scene Configuration ]#

# Allow caller to resize scene without editing source.
#   E.g. `--define:visualiser.items_max=128 --define:visualiser.label_max=48`.
const
  ITEMS_MAX* {.define: "visualiser.items_max".} = 5040
    ## Bound items scene may hold at once.
    ##   Sized so demo holds real solar neighbourhood; see `orrery`.
    ##   Four capacities in `mesh` are sized against this and checked below, since `mesh`
    ##   cannot see it from where it sits in import order.
  LABEL_MAX* {.define: "visualiser.label_max".} = 40
    ## Bound characters label may hold.
static:
  doAssert ITEMS_MAX > 0, &"Scene capacity must be positive; got `{ITEMS_MAX}`."
  doAssert LABEL_MAX >= 8, &"Label must hold 8 characters; got `{LABEL_MAX}`."

  # Tie mesh's capacities to this one where both are visible.
  #   Overflowing any is `doAssert` at draw time, dead page, so raising `ITEMS_MAX` fails
  #   to compile instead.
  doAssert VERTICES_MAX >= 2*ITEMS_MAX,
    &"`mesh.VERTICES_MAX` must hold every point drawn twice, `{2*ITEMS_MAX}` at this " &
      &"capacity; got `{VERTICES_MAX}`."
  doAssert DISCS_MAX >= 2*ITEMS_MAX + 1,
    &"`mesh.DISCS_MAX` must hold every plane drawn twice plus a ghost, " &
      &"`{2*ITEMS_MAX + 1}` at this capacity; got `{DISCS_MAX}`."
  doAssert DOMES_MAX >= 2*ITEMS_MAX + 1,
    &"`mesh.DOMES_MAX` must hold every plane at horizon drawn twice plus a ghost, " &
      &"`{2*ITEMS_MAX + 1}` at this capacity; got `{DOMES_MAX}`."
  doAssert RINGS_MAX >= 2*ITEMS_MAX + 1,
    &"`mesh.RINGS_MAX` must hold every plane's rim drawn twice plus a ghost, " &
      &"`{2*ITEMS_MAX + 1}` at this capacity; got `{RINGS_MAX}`."
  # Bind on scene of lines.
  #   Rim is one ring record, so what fills ribbons is two segments `tessellate.addLine`
  #   steps out per anchor, drawn twice.
  doAssert RIBBONS_MAX >= 4*ITEMS_MAX + 1,
    &"`mesh.RIBBONS_MAX` must hold a scene of lines, each two segments drawn twice, " &
      &"plus a ghost, `{4*ITEMS_MAX + 1}` at this capacity; got `{RIBBONS_MAX}`."



#[ Type Definitions ]#

type
  Label* = array[LABEL_MAX, char]
    ## Define item's display text, terminated by 0, so GUI may edit it without allocating.

  Item* = object ## Define handle onto one live slot's data.
    ## View on native builds, copy under JS backend, where value parameter's address does
    ## not carry across calls.
    ## Holds pointer into `scene`'s storage plus slot number.
    ##   Reading `.geometry`, `.label`, `.ink`, `.isVisible` or `.born` resolves into that
    ##   storage each time.
    ##   Do not hold one across mutation of its own slot (`removeItem` then `addItem`).
    when defined(js):
      scene: Scene
    else:
      scene: ptr Scene
    slot: int

  Scene* = object ## Define fixed-capacity arena of items, addressed by stable slot.
    geometries: array[ITEMS_MAX, Multivector] ## Per-slot geometry.
    labels: array[ITEMS_MAX, Label] ## Per-slot display label.
    inks: array[ITEMS_MAX, Ink] ## Per-slot palette entry.
    radii: array[ITEMS_MAX, float] ## Per-slot drawn radius, in world units; see `radiusAt`.
      ## Read only for point: line and plane take their size from camera and horizon.
    are_shining: array[ITEMS_MAX, bool] ## Per-slot whether item lights others; see
      ## `shinesAt`.
    are_visible: array[ITEMS_MAX, bool] ## Per-slot visibility.
    are_alive: array[ITEMS_MAX, bool] ## Per-slot occupancy; false where slot is free.
    borns: array[ITEMS_MAX, float] ## Per-slot moment item was added, for appear animation.
      ## Not written to scene file, since clock reading means nothing across runs.
      ## Loaded item is stamped all same, so file replays own construction; see
      ## `bornReplaying`.
    revisions_placing: array[ITEMS_MAX, int] ## Per-slot revision at which slot's placing
      ## inputs last changed; see `revisionPlacingAt`.
      ## Placing inputs are geometry and anchor override.
    orders: array[ITEMS_MAX, uint32] ## Per-slot creation ordinal.
      ## How many items scene had ever been given when this one arrived.
      ## Separate from `borns` because clock reading cannot answer this.
      ##   Two items added in one frame share reading, loaded readings are stamped for
      ##   replay, and refilled slot keeps old reading until overwritten.
      ## Only ever increases, is never reused, and survives save and load because file's
      ## item sequence is this order.
      ##   Buys `saveScene` writing items in order built, so reload replays construction
      ##   even after removals scrambled slot order.
    anchor_overrides: array[ITEMS_MAX, Option[Position]] ## Where plane's circle should
      ## centre, for item whose construction fixes that more specifically than its
      ## closest-to-origin support; see `creationAnchor`.
      ## None for anything else.
      ## Not saved or loaded: rendering hint recomputed from how item was built.
    next_free: array[ITEMS_MAX, Option[int]] ## Link to next free slot; intrusive free list.
    slot_free_first: Option[int] ## Head of free list; none where scene is full.
    count_live: int ## Number of occupied slots, so `len` need not rescan `are_alive`.
    slot_live_last: int ## One past highest slot ever occupied; see `bound`.
    count_created: uint32 ## Ordinals handed out so far, and next one to hand out.
      ## Counts additions over scene's whole life, never removals.
    count_edits: int ## How many times scene's drawn content has changed; see `revision`.
    index_ink: int ## How far categorical cycle has been walked; next hue to hand out.
      ## Own counter rather than `len`, because drag that built nothing still steps
      ## palette.
      ##   Reader watched colour on band and it should not be offered again.
      ## Undo restores it with rest of scene.
      ## Not written to file: `loadScene` sets it from item count.

  Arity* {.pure.} = enum ## Define count of operands operation consumes.
    One, Two

  Operation* {.pure.} = enum ## Define every operation GUI may apply to scene's items.
    ## Name one-operand operations, in order library's own documentation lists them.
    Attitude, Support, SupportAnti, Bulk, Weight, Unitize,
    ComplementLeft, ComplementRight, DualBulk, DualWeight,
    Reverse, ReverseAnti, Negate,
    ## Name two-operand operations, likewise.
    Add, Subtract, Wedge, WedgeAnti, WedgeDot, WedgeDotAnti, Dot, DotAnti,
    ExpandBulk, ExpandWeight, ContractBulk, ContractWeight,
    ProjectCentral, ProjectOrthogonal,



#[ Operation Catalogue ]#

const lut_operation_to_arity*: array[Operation, Arity] = [
  Operation.Attitude: Arity.One,
  Operation.Support: Arity.One,
  Operation.SupportAnti: Arity.One,
  Operation.Bulk: Arity.One,
  Operation.Weight: Arity.One,
  Operation.Unitize: Arity.One,
  Operation.ComplementLeft: Arity.One,
  Operation.ComplementRight: Arity.One,
  Operation.DualBulk: Arity.One,
  Operation.DualWeight: Arity.One,
  Operation.Reverse: Arity.One,
  Operation.ReverseAnti: Arity.One,
  Operation.Negate: Arity.One,
  Operation.Add: Arity.Two,
  Operation.Subtract: Arity.Two,
  Operation.Wedge: Arity.Two,
  Operation.WedgeAnti: Arity.Two,
  Operation.WedgeDot: Arity.Two,
  Operation.WedgeDotAnti: Arity.Two,
  Operation.Dot: Arity.Two,
  Operation.DotAnti: Arity.Two,
  Operation.ExpandBulk: Arity.Two,
  Operation.ExpandWeight: Arity.Two,
  Operation.ContractBulk: Arity.Two,
  Operation.ContractWeight: Arity.Two,
  Operation.ProjectCentral: Arity.Two,
  Operation.ProjectOrthogonal: Arity.Two,
] ## Map operation to number of operands it consumes.


const lut_operation_to_notation* = [
  Operation.Attitude: "𝐦⊖  attitude",
  Operation.Support: "𝐦∩  support",
  Operation.SupportAnti: "𝐦∪  antisupport",
  Operation.Bulk: "𝐦∙  bulk",
  Operation.Weight: "𝐦∘  weight",
  Operation.Unitize: "𝐦ˆ  unitize",
  Operation.ComplementLeft: "𝐦ˍ  left complement",
  Operation.ComplementRight: "𝐦¯  right complement",
  Operation.DualBulk: "𝐦★  bulk dual",
  Operation.DualWeight: "𝐦☆  weight dual",
  Operation.Reverse: "𝐦˜  reverse",
  Operation.ReverseAnti: "𝐦˷  antireverse",
  Operation.Negate: "−𝐦  negate",
  Operation.Add: "𝐦 + 𝐧  add",
  Operation.Subtract: "𝐦 - 𝐧  subtract",
  Operation.Wedge: "𝐦 ∧ 𝐧  wedge (join)",
  Operation.WedgeAnti: "𝐦 ∨ 𝐧  antiwedge (meet)",
  Operation.WedgeDot: "𝐦 ⟑ 𝐧  geometric product",
  Operation.WedgeDotAnti: "𝐦 ⟇ 𝐧  geometric antiproduct",
  Operation.Dot: "𝐦 ∙ 𝐧  inner product",
  Operation.DotAnti: "𝐦 ∘ 𝐧  inner antiproduct",
  Operation.ExpandBulk: "𝐦 ∧ 𝐧★  bulk expansion",
  Operation.ExpandWeight: "𝐦 ∧ 𝐧☆  weight expansion",
  Operation.ContractBulk: "𝐦 ∨ 𝐧★  bulk contraction",
  Operation.ContractWeight: "𝐦 ∨ 𝐧☆  weight contraction",
  Operation.ProjectCentral: "𝐧 ∨ (𝐦 ∧ 𝐧★)  central projection",
  Operation.ProjectOrthogonal: "𝐧 ∨ (𝐦 ∧ 𝐧☆)  orthogonal projection",
] ## Map operation to notation and name GUI offers it under, for both render paths.
  ##   Operands in Lengyel's mathematical bold, every symbol's placement his.
  ##   Written with spacing modifier letters (`ˆ` U+02C6, `ˍ` U+02CD, `¯` U+00AF, `˜`
  ##   U+02DC, `˷` U+02F7) rather than combining marks.
  ##     Combining marks need shaper Dear ImGui lacks, landing beside operand instead of
  ##     over it; spacing modifier carries own advance, so both renderers place it same
  ##     way.
  ##   Not second plain-ASCII table: atlas merges faces carrying astral-plane glyphs (see
  ##   `visualiser.PATH_FONT_MATH`).
  ##   `const` of `string`, with `cstring` array picker needs built from it below.
  ##     `help.nim` builds own table at compile time, so catalogue tab needs text before
  ##     program runs; addresses derive from text, never text from addresses.


let lut_operation_to_notation_c* = block:
  ## Map operation to same entries as `cstring`, what picker offers.
  ##   Dear ImGui takes address of first and reads them for life of combo.
  ##   Built from table above rather than written beside it.
  var lut: array[Operation, cstring]
  for operation in Operation: lut[operation] = cstring(lut_operation_to_notation[operation])
  lut


const
  COUNT_OPERATION* = ord(Operation.high) + 1
    ## Count operations, for handing whole catalogue to picker.

  lut_operation_split* = block:
    ## Map operation to its two halves: symbols it is written with, and English name after.
    ##   One split, at one place, i.e. double space between them, so no caller cuts at
    ##   second place that drifts.
    ##   `const`, so `help.nim` can build catalogue tab from it at compile time.
    var lut: array[Operation, tuple[symbols, name: string]]
    for operation in Operation:
      let full = lut_operation_to_notation[operation]
      let cutoff = full.find("  ")
      lut[operation] =
        if cutoff >= 0: (symbols: full[0 ..< cutoff], name: full[cutoff + 2 .. ^1].strip())
        else: (symbols: full, name: "")
    lut


func notationSymbolic*(operation: Operation): string =
  ## Report symbols operation is written with, without English name.
  ##   `𝐦 ∧ 𝐧`, not `𝐦 ∧ 𝐧  wedge (join)`.
  ##   What picker offers on both front-ends: full entry is several times wider, and
  ##   pushes selection menu's popover past what hand can reach on phone.
  lut_operation_split[operation].symbols


func notationNamed*(operation: Operation): string =
  ## Report English name operation is offered under, other half of `notationSymbolic`.
  ##   `wedge (join)`, not `𝐦 ∧ 𝐧`.
  ##   What help's catalogue tab reads, so tab says exactly what every picker offers.
  lut_operation_split[operation].name


func notationSubstituted*(operation: Operation; name_first, name_second: string): string =
  ## Build label text applied operation reads as, with real operand names in place.
  ##   Substitutes template's `𝐦`/`𝐧`: `Operation.Wedge` with `a`/`b` gives `a ∧ b`.
  ##   Matches bold operands, not plain ASCII `m`/`n`: English description after symbols
  ##   contains ordinary `m` and `n` constantly.
  ##   Swaps through two passes via sentinel bytes no label contains.
  ##     Operand name containing placeholder is never re-touched, and template where `𝐧`
  ##     appears twice (ProjectCentral/ProjectOrthogonal) substitutes both.
  const
    OPERAND_FIRST = "𝐦"
    OPERAND_SECOND = "𝐧"
    SENTINEL_M = "\x01"
    SENTINEL_N = "\x02"
  let staged = notationSymbolic(operation)
    .replace(OPERAND_FIRST, SENTINEL_M).replace(OPERAND_SECOND, SENTINEL_N)
  result = staged.replace(SENTINEL_M, name_first).replace(SENTINEL_N, name_second)


func applyOperation*(operation: Operation; m, n: Multivector): Multivector =
  ## Apply operation to operands, ignoring `n` where operation is unary.
  case operation
  of Operation.Attitude: attitude(m)
  of Operation.Support: support(m)
  of Operation.SupportAnti: supportAnti(m)
  of Operation.Bulk: bulk(m)
  of Operation.Weight: weight(m)
  of Operation.Unitize: unitize(m)
  of Operation.ComplementLeft: complementLeft(m)
  of Operation.ComplementRight: complementRight(m)
  of Operation.DualBulk: dualBulk(m)
  of Operation.DualWeight: dualWeight(m)
  of Operation.Reverse: reverse(m)
  of Operation.ReverseAnti: reverseAnti(m)
  of Operation.Negate: negate(m)
  of Operation.Add: add(m, n)
  of Operation.Subtract: subtract(m, n)
  of Operation.Wedge: wedge(m, n)
  of Operation.WedgeAnti: wedgeAnti(m, n)
  of Operation.WedgeDot: wedgeDot(m, n)
  of Operation.WedgeDotAnti: wedgeDotAnti(m, n)
  of Operation.Dot: dot(m, n)
  of Operation.DotAnti: dotAnti(m, n)
  of Operation.ExpandBulk: expandBulk(m, n)
  of Operation.ExpandWeight: expandWeight(m, n)
  of Operation.ContractBulk: contractBulk(m, n)
  of Operation.ContractWeight: contractWeight(m, n)
  of Operation.ProjectCentral: projectCentral(m, n)
  of Operation.ProjectOrthogonal: projectOrthogonal(m, n)


func creationAnchor*(operation: Operation; m, n, derived: Multivector): Option[Position] =
  ## Resolve point freshly derived plane's circle should centre on, from how it was built.
  ##   Rather than from closest-to-origin support, so it reads as centred where
  ##   construction happened.
  ##   Computed through same operators construction used.
  ##   None for operation or operand shape not recognised here; caller falls back to
  ##   plane's support (`objects.positionAnchor`).
  case operation
  of Operation.Wedge:
    # Centre between point and line's closest approach to it.
    #   Line wedged with point gives plane line lies within, meeting at no single point.
    #   Both unitized first, so sum's weight is exactly two and position read back is
    #   plain midpoint.
    let (line, point) =
      if shape(m) == some(Shape.Line) and shape(n) == some(Shape.Point): (m, n)
      elif shape(n) == some(Shape.Line) and shape(m) == some(Shape.Point): (n, m)
      else: return none(Position)
    position(add(unitize(point), unitize(projectOrthogonal(point, line))))

  of Operation.ExpandWeight:
    # Meet line with plane built perpendicular to it, which crosses at exactly one point.
    let line =
      if shape(m) == some(Shape.Line): m
      elif shape(n) == some(Shape.Line): n
      else: return none(Position)
    position(wedgeAnti(line, derived))

  else: none(Position)



#[ Multivector Formatting ]#

const lut_basis_to_name* = block:
  ## Name each basis element as library's `$` names it.
  ##   `𝟏` for scalar, `𝟙` for antiscalar, bold `𝐞` carrying subscript digits for rest.
  ##   Exported so both GUIs label coefficient with its basis element, reading same as
  ##   multivector text beside them.
  ##   Derived rather than transcribed, so build of another dimension names own elements.
  ##     Rule is second copy of one inside `pga/multivectors.nim`'s `$`, which does not
  ##     expose it; check that one whenever this is touched.
  const
    NAME_SCALAR = "\u{1D7CF}" # Mathematical bold digit one.
    NAME_SCALAR_ANTI = "\u{1D7D9}" # Mathematical double-struck digit one.
    NAME_VECTOR = "\u{1D41E}" # Mathematical bold small e.
    CODEPOINT_SUBSCRIPT_ZERO = 0x2080
  var lut: array[Basis, string]
  for b in Basis:
    lut[b] =
      case b
      of Basis.scalar: NAME_SCALAR
      of Basis.scalarAnti: NAME_SCALAR_ANTI
      else:
        # Read index list behind `E` in enum's name, one digit per factor.
        var name = NAME_VECTOR
        for digit in ($b)[1 .. ^1]:
          name &= $Rune(CODEPOINT_SUBSCRIPT_ZERO + ord(digit) - ord('0'))
        name
  lut


const
  WIDTH_TERM = 32
    ## Bound one printed term in bytes.
    ##   Separator, magnitude at `DIGITS_SIGNIFICANT` with sign and exponent, space, and
    ##   basis name in mathematical bold with subscripts at up to 13 bytes.
    ##   Bytes, since that is what buffer holds.
  WIDTH_MULTIVECTOR* = (ord(Basis.high) + 1)*WIDTH_TERM + 1
    ## Bound one printed multivector: every basis term at `WIDTH_TERM`, plus terminator.
    ##   Derived from `Basis`, so build of another dimension sizes own buffers.


func formatMultivector*(m: Multivector, storage: var openArray[char], cursor: var int) =
  ## Print multivector into fixed storage, in same shape library's `$` uses.
  ##   Basis elements named exactly as library names them; both GUIs carry faces covering
  ##   those codepoints.
  ##   Magnitudes stay project's four significant digits.
  ##   Appends from `cursor` rather than returning `string`, so redrawing every visible
  ##   item's coefficients every frame never touches heap.
  var wrote_any = false
  for b in Basis:
    if abs(m[b]) <= TOLERANCE_ABS: continue
    if m[b] < 0: appendChars(storage, cursor, " - ")
    elif wrote_any: appendChars(storage, cursor, " + ")
    appendMagnitude(storage, cursor, abs(m[b]))
    appendChars(storage, cursor, " ")
    appendChars(storage, cursor, lut_basis_to_name[b])
    wrote_any = true
  if not wrote_any:
    appendChars(storage, cursor, "0 ")
    appendChars(storage, cursor, lut_basis_to_name[Basis.scalar])


const WIDTH_SHAPE_WORD* = 32
  ## Bound shape word alone, longest being "mixed grade, nothing to draw".


func describeShape*(m: Multivector, storage: var openArray[char], cursor: var int) =
  ## Name geometry multivector stands for into fixed storage, for reporting to user.
  ##   Appends from `cursor` onward; see `formatMultivector`.
  let shape = shape(m)
  appendChars(storage, cursor,
    if shape.isNone: "mixed grade, nothing to draw"
    else:
      case shape.get
      of Shape.Point: (if m.isHorizon: "point at horizon" else: "point")
      of Shape.Line: (if m.isHorizon: "line at horizon" else: "line")
      of Shape.Plane: (if m.isHorizon: "plane at horizon" else: "plane")
  )


func multivectorText*(m: Multivector): string =
  ## Print `m` as string, for caller with nowhere fixed to put it.
  ##   Wraps `formatMultivector`, so same object reads same in both front-ends.
  var
    storage: array[WIDTH_MULTIVECTOR, char]
    cursor = 0
  formatMultivector(m, storage, cursor)
  finishChars(storage, cursor)
  toText(storage)


func shapeText*(m: Multivector): string =
  ## Name geometry `m` stands for, as string, for caller with nowhere fixed to put it.
  ##   Wraps `describeShape` rather than restating words, so status line, panel row and
  ##   browser item list cannot drift.
  ##   Allocating is affordable here: called on user action, not per visible item per
  ##   frame.
  var
    storage: array[WIDTH_SHAPE_WORD, char]
    cursor = 0
  describeShape(m, storage, cursor)
  finishChars(storage, cursor)
  toText(storage)



#[ Label Storage ]#

const ELLIPSIS_LABEL = "…"
  ## Mark label that did not fit, so shortened name says it was shortened.
  ##   Three bytes of buffer it warns about.
  ##   Derived names compound, so few steps in every name is long enough to cut, and one
  ##   ending mid-word reads as name someone chose.

func toChars*(text: string, storage: var openArray[char]) =
  ## Copy text into fixed char storage, marking it with `…` where it will not fit.
  ##   Truncation is deliberate: storage is display only, and GUI must never overrun it.
  ##   Room for mark is measured by `lengthFitting` against smaller capacity rather than
  ##   by backing up over what was written, so rewind never lands inside character.
  let capacity = len(storage) - 1
  var cursor = 0
  if lengthFitting(text, capacity) == len(text):
    appendChars(storage, cursor, text)
  else:
    let kept = lengthFitting(text, capacity - len(ELLIPSIS_LABEL))
    if kept > 0: appendChars(storage, cursor, text.toOpenArray(0, kept - 1))
    appendChars(storage, cursor, ELLIPSIS_LABEL)
  finishChars(storage, cursor)


when not defined(js):
  template toCstring*(storage: untyped): cstring = cast[cstring](unsafeAddr storage[0])
    ## Point at fixed char storage, for handing to GUI as pointer C expects.
    ##   Template rather than function, so address is taken of caller's own storage.
    ##   Desktop-only, guarded rather than policed by comment.
    ##     Address is meaningless on JS backend, so shared module reading storage as text
    ##     wants `toText`.



#[ Scene Editing ]#

func initScene*(): Scene =
  ## Construct empty scene, threading every slot onto free list ahead of first use.
  for slot in 0 ..< ITEMS_MAX - 1:
    result.next_free[slot] = some(slot + 1)
  result.slot_free_first = some(0)


func len*(scene: Scene): int = scene.count_live
  ## Count live items held by scene.


func bound*(scene: Scene): int = scene.slot_live_last
  ## Report one past highest slot this scene has ever occupied.
  ##   What walk over "every slot" runs to.
  ##     Slots are stable addresses, so by-slot reader sweeps range rather than dense list,
  ##     and at capacity that means testing every slot per frame to draw few.
  ##   High-water mark rather than live count, because freed slot in middle leaves ones
  ##   above occupied; only ever rises.
  ##   Three walks stay at capacity, each saying so where it stands: free list `initScene`
  ##   threads, and two object-pool strips, whose subject is how much room is left.
  ##   Not `len`: living are not packed at bottom.


func revision*(scene: Scene): int = scene.count_edits
  ## Report how many times scene's drawn content has changed.
  ##   Named apart from field, as `len` and `bound` are: reader named for field it reads
  ##   recurses under this module's scoping.
  ##   For holding last frame's meshes and placements, nothing else.
  ##     Front-end compares against what it saw last frame, equality only, and rebuilds
  ##     where it differs.
  ##     Not version number user sees, not saved.
  ##   Everything changing what is drawn bumps it, and ways to do that are closed.
  ##     Geometry through `setGeometryAt`, ink through `setInk`, visibility through
  ##     `setVisible`, existence through `addItem`/`removeItem`, birth stamps through
  ##     `replayFrom`; all here, since fields are private.
  ##     Label is not among them: labels are never tessellated.
  ##   Never assign whole scene over live one; go through `restoreFrom`.
  ##     Assignment restores snapshot's own revision, and bump after it lands on number
  ##     already seen, i.e. edit being undone; reader holding meshes on that number draws
  ##     undone object until camera moves.

func markEdited*(scene: var Scene) =
  ## Say that scene's drawn content just changed; see `revision`.
  ##   Called by every writer in this module.
  ##   Caller wanting this for anything else is writing to scene by route that ought to be
  ##   proc here.
  inc scene.count_edits


func restoreFrom*(scene: var Scene, snapshot: Scene) =
  ## Replace scene's whole content with snapshot, at revision no earlier state carried.
  ##   Every whole-scene replacement, i.e. undo, redo, clear, load, comes through here.
  ##     Revision only ever rises and no two states front-end has drawn share one.
  ##   Every live slot is stamped as re-placed, since any of them may differ from what
  ##   cache holds.
  let revision_live = scene.count_edits
  scene = snapshot
  scene.count_edits = max(revision_live, snapshot.count_edits) + 1
  for slot in 0 ..< scene.bound:
    if scene.are_alive[slot]: scene.revisions_placing[slot] = scene.count_edits


func revisionPlacingAt*(scene: Scene, slot: int): int =
  ## Report revision at which slot's placing inputs last changed.
  ##   Front-end caching `tessellate.placeObject`'s answer per slot re-places only slots
  ##   stamped past what it holds: one slot per edit, every slot after `restoreFrom`.
  ##   Re-placing whole scene per edit is whole frame at capacity; figures in
  ##   `PROVENANCE.md`.
  scene.revisions_placing[slot]


func isFull*(scene: Scene): bool = scene.count_live >= ITEMS_MAX
  ## Report whether scene has no room for another item.


func isAlive*(scene: Scene, slot: int): bool =
  ## Report whether slot currently holds live item.
  ##   For slot read back across frame boundary, e.g. operand picked earlier.
  ##   Two comparisons, not `slot in 0 ..< ITEMS_MAX`.
  ##     JS backend builds slice object per call, and every by-slot reader asserts through
  ##     here, so one moving frame at capacity allocated one per slot.
  slot >= 0 and slot < ITEMS_MAX and scene.are_alive[slot]


func slotStepped*(scene: Scene, slot: Option[int], step: int): Option[int] =
  ## Walk to next live slot `step` places on from `slot`, wrapping past both ends.
  ##   None where scene holds nothing; first live slot from start where `slot` is none.
  ##   Slots are sparse, so this searches rather than computes; `ITEMS_MAX` bounds search.
  ##   Wraps deliberately: drives keyboard traversal, and walk stopping dead leaves reader
  ##   pressing key that silently stopped working.
  if scene.len == 0: return none(int)
  doAssert step != 0, &"Step must be non-zero, or search runs forever; got `{step}`."
  let start = if slot.isSome: slot.get else: -1
  for offset in 1 .. ITEMS_MAX:
    let candidate = floorMod(start + step*offset, ITEMS_MAX)
    if scene.isAlive(candidate): return some(candidate)
  none(int)


func `[]`*(scene: Scene, slot: int): Item =
  ## Read item by slot: handle onto `scene`'s storage, not copy of it.
  doAssert scene.isAlive(slot), &"Item slot must be alive; got `{slot}`."
  when defined(js):
    Item(scene: scene, slot: slot)
  else:
    Item(scene: unsafeAddr scene, slot: slot)


func geometry*(item: Item): lent Multivector = item.scene.geometries[item.slot]
  ## Read item's geometry, straight out of scene handle points at.


func label*(item: Item): lent Label = item.scene.labels[item.slot]
  ## Read item's label, straight out of scene handle points at.


func ink*(item: Item): Ink = item.scene.inks[item.slot]
  ## Read item's palette slot, straight out of scene handle points at.


func isVisible*(item: Item): bool = item.scene.are_visible[item.slot]
  ## Read item's visibility, straight out of scene handle points at.


func radius*(item: Item): float = item.scene.radii[item.slot]
  ## Read item's drawn radius, straight out of scene handle points at; see `radiusAt`.


func shines*(item: Item): bool = item.scene.are_shining[item.slot]
  ## Read whether item lights others, straight out of scene handle points at.


func born*(item: Item): float = item.scene.borns[item.slot]
  ## Read item's `born` reading, straight out of scene handle points at.


func anchorOverride*(item: Item): Option[Position] = item.scene.anchor_overrides[item.slot]
  ## Read where item's circle should centre, if construction fixed that.
  ##   See `creationAnchor`.


func geometryOf*(scene: Scene, slot: int): lent Multivector =
  ## Read item's geometry in place, by slot, without mutable scene.
  ##   `lent`, not `var`: `var`-returning accessor read rather than written miscompiles
  ##   under JS backend; borrow cannot be written through.
  ##   `lent` pays only where result is never bound.
  ##     Returning by value allocates fresh `Multivector` and `nimCopy`s field into it on
  ##     JS backend, once per call.
  ##     Confirmed in generated JavaScript that `lent` removes copy and binding result to
  ##     `let` puts it back, so caller wanting saving uses call inline.
  ##   Borrow lives only while scene is unchanged; do not hold one across edit.
  doAssert scene.isAlive(slot), &"Item slot must be alive; got `{slot}`."
  scene.geometries[slot]


func setGeometryAt*(scene: var Scene, slot: int, geometry: Multivector) =
  ## Write item's geometry, by slot, only way live item's geometry changes.
  ##   Setter rather than `var Multivector`, for reason `geometryOf` gives and second.
  ##     Front-end holding last frame's meshes can only know scene changed if every write
  ##     passes one door; see `revision`.
  doAssert scene.isAlive(slot), &"Item slot must be alive; got `{slot}`."
  scene.geometries[slot] = geometry
  scene.markEdited()
  scene.revisions_placing[slot] = scene.count_edits


func labelAt*(scene: var Scene, slot: int): var Label =
  ## Reach item's label for editing, by slot.
  doAssert scene.isAlive(slot), &"Item slot must be alive; got `{slot}`."
  scene.labels[slot]


func isVisible*(scene: Scene, slot: int): bool =
  ## Read item's visibility by value, by slot rather than through `Item`; see `inkAt`.
  ##   Read and written through plain accessor pair, never `var bool`-returning one.
  ##     Proc handing back `var bool` over `array[N, bool]` miscompiles under JS backend,
  ##     reading `undefined` and writing to dropped copy; `setVisible` is writer.
  scene.are_visible[slot]


func inkAt*(scene: Scene, slot: int): Ink =
  ## Read item's palette slot, by slot rather than through `Item` handle.
  ##   Beside `Item.ink` for caller reading many items per frame.
  ##     Under JS backend `Item` holds `Scene` by value, so constructing one to read single
  ##     field copies whole scene.
  doAssert scene.isAlive(slot), &"Item slot must be alive; got `{slot}`."
  scene.inks[slot]


func radiusAt*(scene: Scene, slot: int): float =
  ## Read item's drawn radius, in world units, by slot rather than through `Item`.
  ##   Beside `Item.radius` for same reason `inkAt` sits beside `Item.ink`.
  ##   World units rather than pixels, so item shrinks with distance as everything else
  ##   drawn at position does; front-end holds least on-screen size, not this.
  doAssert scene.isAlive(slot), &"Item slot must be alive; got `{slot}`."
  scene.radii[slot]


func shinesAt*(scene: Scene, slot: int): bool =
  ## Read whether item lights others, by slot rather than through `Item`; see `inkAt`.
  ##   Sun: point every other point takes its shading from, and drawn flat itself; see
  ##   `lighting`. Meaningful for point alone.
  doAssert scene.isAlive(slot), &"Item slot must be alive; got `{slot}`."
  scene.are_shining[slot]


func bornAt*(scene: Scene, slot: int): float =
  ## Read moment item arrived, by slot rather than through `Item` handle; see `inkAt`.
  doAssert scene.isAlive(slot), &"Item slot must be alive; got `{slot}`."
  scene.borns[slot]


func orderOf*(scene: Scene, slot: int): uint32 =
  ## Read where item stands in order this scene's items were created, by slot.
  ##   Comparable only within one scene: counts additions to this arena, says nothing
  ##   about wall-clock time or another scene's ordinals.
  doAssert scene.isAlive(slot), &"Item slot must be alive; got `{slot}`."
  scene.orders[slot]


func siftDown(scene: Scene; slots: var array[ITEMS_MAX, int]; root, count: int) =
  ## Sift slot at `root` down until neither child carries later ordinal, over first `count`.
  var parent = root
  while true:
    var child = 2*parent + 1
    if child >= count: return
    if child + 1 < count and scene.orders[slots[child + 1]] > scene.orders[slots[child]]:
      inc child
    if scene.orders[slots[parent]] >= scene.orders[slots[child]]: return
    swap(slots[parent], slots[child])
    parent = child


func slotsCreated*(scene: Scene, slots: var array[ITEMS_MAX, int]): int =
  ## Fill `slots` with every live slot, oldest creation first; report how many were filled.
  ##   Caller's own array rather than `seq`, so no allocation on either backend.
  ##   Heapsort on `orders`, in place, O(n log n).
  ##     Runs per drawer refresh on browser and per edit on desktop, not once per save;
  ##     quadratic sort here was most of desktop frame at capacity; figures in
  ##     `PROVENANCE.md`.
  ##   To `bound`, by slot: no slot above watermark has ever held anything.
  for slot in 0 ..< scene.bound:
    if not scene.are_alive[slot]: continue
    slots[result] = slot
    inc result
  for root in countdown(result div 2 - 1, 0): siftDown(scene, slots, root, result)
  for last in countdown(result - 1, 1):
    swap(slots[0], slots[last])
    siftDown(scene, slots, 0, last)


func anchorOverrideAt*(scene: Scene, slot: int): Option[Position] =
  ## Read where item's circle should centre, by slot rather than through `Item` handle.
  ##   See `inkAt`.
  doAssert scene.isAlive(slot), &"Item slot must be alive; got `{slot}`."
  scene.anchor_overrides[slot]



#[ Previewing Construction ]#

type Preview* = object ## Define what applying operation would build, ready to draw and frame.
  ## One statement of uncommitted construction, shared by every path offering one.
  ##   Drag's rubber-band answer and both apply pickers.
  geometry*: Multivector ## What operation makes of its operands.
  anchor*: Option[Position] ## Where plane's disc should centre, from `creationAnchor`.
    ## None for every other shape.
    ## Carried so ghosted plane is drawn exactly where commit will put it.
  operands*: Option[(int, int)] ## Slots this was derived from.
    ## For camera framing preview to keep in view beside it.
    ## None where there are none to name: staged edit replaces very object it would be
    ## framed against.
  radius*: float ## Drawn radius ghost takes, where it is point; see `radiusAt`.
    ## Staged session's own, so editing moon ghosts moon-sized; derived preview takes
    ## `RADIUS_ITEM_DEFAULT`, what commit gives it.


func previewApplying*(
  scene: Scene; operation: Operation; first, second: int
): Option[Preview] =
  ## Resolve what applying `operation` to these two slots would build.
  ##   None where it would build nothing worth showing.
  ##     Either slot dead, since picker left open across delete is ordinary.
  ##     Result with no drawable shape, covering wrong grades and pair already lying on
  ##     each other.
  ##   Takes slots rather than multivectors so operands travel with answer.
  ##   Unary operation ignores `second`; pass first slot again, as every commit path does.
  if not (scene.isAlive(first) and scene.isAlive(second)): return
  let
    m = scene.geometryOf(first)
    n = scene.geometryOf(second)
    derived = applyOperation(operation, m, n)
  if shape(derived).isNone: return
  some(Preview(
    geometry: derived,
    anchor: creationAnchor(operation, m, n, derived),
    operands: some((first, second)),
    radius: RADIUS_ITEM_DEFAULT,
  ))


func previewStaging*(geometry: Multivector, radius: float): Preview =
  ## Hold open edit session's staged geometry as preview, at session's own radius.
  ##   No anchor and no operands: neither front-end draws that ghost about stored point,
  ##   and object it would be framed against is one it replaces; see `Preview`.
  ##   Radius is staged one, or ghost of moon under edit was drawn at default and read as
  ##   grey disc three times its size.
  Preview(
    geometry: geometry, anchor: none(Position), operands: none((int, int)), radius: radius
  )


func setInk*(scene: var Scene, slot: int, ink: Ink) =
  ## Rewrite item's palette slot, by slot.
  doAssert scene.isAlive(slot), &"Item slot must be alive; got `{slot}`."
  scene.inks[slot] = ink
  scene.markEdited()


func setRadius*(scene: var Scene, slot: int, radius: float) =
  ## Rewrite item's drawn radius, by slot, mirroring `setInk`.
  ##   Bumps `revision` only: radius is not placing input, nothing about where item
  ##   stands changes.
  doAssert scene.isAlive(slot), &"Item slot must be alive; got `{slot}`."
  doAssert radius > 0.0, &"Item radius must be positive; got `{radius}`."
  scene.radii[slot] = radius
  scene.markEdited()


func setShining*(scene: var Scene, slot: int, shines: bool) =
  ## Rewrite whether item lights others, by slot, mirroring `setInk`.
  doAssert scene.isAlive(slot), &"Item slot must be alive; got `{slot}`."
  scene.are_shining[slot] = shines
  scene.markEdited()


func setVisible*(scene: var Scene, slot: int, is_visible: bool) =
  ## Rewrite item's visibility, by slot, mirroring `setInk`.
  ##   Only writer: `isVisibleAt(...) = visible` accessor silently lands on copied
  ##   primitive under JS backend; see `isVisible`.
  doAssert scene.isAlive(slot), &"Item slot must be alive; got `{slot}`."
  scene.are_visible[slot] = is_visible
  scene.markEdited()


iterator items*(scene: Scene): Item =
  ## Yield each live item, in slot order.
  ##   Walks to `bound`, as sibling `pairs` does; check both when either changes.
  for slot in 0 ..< scene.bound:
    if scene.are_alive[slot]: yield scene[slot]


iterator pairs*(scene: Scene): (int, Item) =
  ## Yield each live item together with slot it stands at, in slot order.
  ##   Walks to `bound` rather than capacity, so every consumer stops sweeping empty slots
  ##   at once; sibling of `items`.
  for slot in 0 ..< scene.bound:
    if scene.are_alive[slot]: yield (slot, scene[slot])


func addItem*(
  scene: var Scene, geometry: Multivector, label: string, ink: Ink, now: float = 0.0,
  anchor_override: Option[Position] = none(Position), radius: float = RADIUS_ITEM_DEFAULT,
  shines: bool = false
): int {.discardable.} =
  ## Insert object into scene at first free slot, visible; report slot used.
  ##   Silently refuses nothing: caller checks `isFull` first, as scene cannot grow.
  ##   `now` is stamped as item's `born` reading.
  ##     Default reads as "born at dawn of time" and never animates.
  ##   `anchor_override` is where plane's circle should centre instead of support, where
  ##   construction fixes that; see `creationAnchor`.
  ##   `radius` is how large point is drawn, in world units; see `radiusAt`.
  ##   `shines` says point lights others; see `shinesAt`.
  doAssert not scene.isFull,
    &"Scene holds at most {ITEMS_MAX} items, raise `--define:visualiser.items_max`; got " &
      &"`{scene.len}`."
  result = scene.slot_free_first.get
  scene.slot_free_first = scene.next_free[result]
  scene.geometries[result] = geometry
  toChars(label, scene.labels[result])
  scene.inks[result] = ink
  doAssert radius > 0.0, &"Item radius must be positive; got `{radius}`."
  scene.radii[result] = radius
  scene.are_shining[result] = shines
  scene.are_visible[result] = true
  scene.are_alive[result] = true
  scene.borns[result] = now
  scene.anchor_overrides[result] = anchor_override
  # Stamp arrival relative to everything else, which slot cannot say.
  #   Refilled slot sits wherever free list put it.
  scene.orders[result] = scene.count_created
  inc scene.count_created
  inc scene.count_live
  scene.slot_live_last = max(scene.slot_live_last, result + 1)
  scene.markEdited()
  scene.revisions_placing[result] = scene.count_edits


func removeItem*(scene: var Scene, slot: int) =
  ## Drop item at slot, in constant time: slot returns to free list, nothing moves.
  doAssert scene.isAlive(slot), &"Item slot must be alive; got `{slot}`."
  scene.are_alive[slot] = false
  scene.next_free[slot] = scene.slot_free_first
  scene.slot_free_first = some(slot)
  dec scene.count_live
  scene.markEdited()



#[ Scene Persistence ]#

## Define binary format project invents for itself.
##   Every multi-byte field is little-endian, rule rather than habit.
##     `glue.js` writes and reads same file through `DataView`, which demands explicit
##     order and is given `true`.
##     Host-native layout leaves two agreeing only while every machine is little-endian;
##     on big-endian one desktop would write file its own browser build could not read.
##   Little-endian because it is what every file written so far contains, so rule cost no
##   format version.
##
##   |----------|--------------------------------------------------------------|
##   | Bytes    | Field                                                        |
##   |----------|--------------------------------------------------------------|
##   | 4        | Magic `RGAS`, to catch wrong file at glance.                 |
##   | 1        | Format version.                                              |
##   | 1        | Basis count (terms per multivector); must match this build's |
##   |          |   own count, or file was saved under different PGA dimension |
##   |          |   or metric and cannot be read here.                         |
##   | 4        | Item count, little-endian `uint32`.                          |
##   | per item | Ink (1), visibility (1), label length (1) then that many     |
##   |          |   bytes, one little-endian `float` per basis term, radius as |
##   |          |   one more little-endian `float`, then shines (1).           |
##   |----------|--------------------------------------------------------------|
##
## Only live items are written, in order created, whole of what version 3 added.
##   Slot numbers mean nothing once reloaded; sequence carries ordering, so no ordinal is
##   written beside each item.
##   `born` is not written: clock reading meaningless across runs.
##     Loaded item is stamped by `bornReplaying`, so file plays back own construction.
##   Label is written as exactly as many bytes as it holds, not padded to `LABEL_MAX`.
## Every version ever written is still readable.
##   Scene file is reader's own work; build refusing it has destroyed it.
##
##   |---------|-------------------------------------------------------------------|
##   | Version | Read as                                                           |
##   |---------|-------------------------------------------------------------------|
##   | 6       | Exactly.                                                          |
##   | 5       | Exactly, except palette had one more structural slot, `Algebra`,  |
##   |         |   at ordinal 7; every hue past it moves one down; see             |
##   |         |   `upgradedFrom5`.                                                |
##   | 4       | Exactly, except nothing shines, so every point draws flat; see    |
##   |         |   `upgradedFrom4`.                                                |
##   | 3       | Exactly, except every item is drawn at `RADIUS_ITEM_DEFAULT`, size |
##   |         |   version 3 drew everything at; see `upgradedFrom3`.              |
##   | 2       | Exactly, except item sequence is slot order, so scene whose       |
##   |         |   objects were removed and re-added replays out of build order.   |
##   |         |   Byte-identical to version 3 but for version itself.             |
##   | 1       | Geometry, label and visibility exactly; colours one hue along     |
##   |         |   for three that were retired; see `upgradedFrom1`.               |
##   |---------|-------------------------------------------------------------------|
##
## Old file is upgraded to today's shape, never read in old build's dialect.
##   Reading is written once, against `VERSION_SCENE`.
##   Everything past version did differently lives in one `upgradedFrom<n>` per boundary,
##   and `itemUpgraded` walks items up chain one step at time.
##   Reader branching on version at each field spreads every past decision across whole
##   reader, and version that breaks is one nobody has file of to notice.
##   Adding version means adding one func.

const
  MAGIC_SCENE* = "RGAS"
    ## Open every `.rgascene` file with these four bytes.
  VERSION_SCENE* = 6'u8
    ## Stamp format version this build writes.
    ##   Every version down to `VERSION_SCENE_LEAST` is still read; see table above.
    ##   Version 2 moved every stored ink ordinal, when `Ink` gained reserved `Invalid`
    ##   slot and lost three categorical ones.
    ##   Version 3 began writing items in creation order.
    ##     Bytes are shaped identically, so this number alone says whether sequence is
    ##     build order or slot order.
    ##   Version 4 appended one float64 radius to each item, after its geometry.
    ##   Version 5 appended one shines byte to each item, after its radius.
  VERSION_SCENE_RADIUS* = 4'u8
    ## Record first version whose items carry radius; see `hasRadius`.
  VERSION_SCENE_SHINE* = 5'u8
    ## Record first version whose items carry shines byte; see `hasShine`.
  VERSION_SCENE_LEAST* = 1'u8
    ## Bound oldest format version this build still reads.
    ##   One, and it stays one: version floor that rises throws reader's work away.
    ##   Reading old version costs mapping func and suite case; refusing costs scene.

func inkCycled*(index: int): Ink = inkCategorical(index mod COUNT_INK_CATEGORICAL)
  ## Choose palette slot for item at given position, cycling categorical slots.
  ##   Same run colour picker offers, so nothing cycles to colour user could not have
  ##   chosen.


func inkNext*(scene: Scene): Ink = inkCycled(scene.index_ink)
  ## Read hue next object built will wear, without taking it.
  ##   What drag in flight is drawn in, so band, comet and ghost show colour thing being
  ##   built will be; see `interaction.inkOfDrag`.
  ##   Peeking and taking are separate because previewing happens every frame.


func takeInk*(scene: var Scene): Ink =
  ## Read hue for object being built, and step cycle past it.
  result = scene.inkNext
  inc scene.index_ink


func skipInk*(scene: var Scene) =
  ## Step cycle without building anything.
  ##   For construction gesture that ended in no object: reader was shown colour for whole
  ##   drag, and offering same colour again reads as gesture not registering.
  inc scene.index_ink

const
  ORDINAL_INK_CATEGORICAL_V1* = 7
    ## Record where categorical hues began in `Ink` version-1 file was written under.
    ##   That palette ran `Backdrop, AxisX, AxisY, AxisZ, Grid, Guide, Outline` then eight
    ##   hues `Rose, Copper, Olive, Jade, Cobalt, Violet, Magenta, Cerise`.
    ##   Seven structural slots are unchanged; structural slot reserved after them,
    ##   `Invalid`, moves hues along, so fold reads today's start through `inkCycled`.
    ##   Recorded as number because enum it indexes no longer exists.
  ORDINAL_INK_HIGH_V1* = 14
    ## Record last palette slot version-1 file could name, `Cerise`'s.
    ##   Bounded because fold would otherwise turn any number into some hue, and quietly
    ##   colouring corrupt byte is guessing format refuses everywhere else.


func readsSceneVersion*(version: uint8): bool =
  ## Report whether this build can read scene file stamped with this version.
  version >= VERSION_SCENE_LEAST and version <= VERSION_SCENE


func hasRadius*(version: uint8): bool = version >= VERSION_SCENE_RADIUS
  ## Report whether file of this version carries radius after each item's geometry.
  ##   Both readers ask this rather than compare against literal; see `nimSceneHasRadius`.


func hasShine*(version: uint8): bool = version >= VERSION_SCENE_SHINE
  ## Report whether file of this version carries shines byte after each item's radius.
  ##   Asked as `hasRadius` is; see `nimSceneHasShine`.


type ItemSaved* = object
  ## Define one item exactly as scene file holds it, at whatever version wrote file.
  ##   Shape reading works in, and thing `upgradedFrom<n>` carries between versions.
  ##   Distinct from `Item`: value read off bytes that may not describe anything this
  ##   build can make yet.
  ink_ordinal*: int ## Palette slot, as writing version's `Ink` numbered it.
  is_visible*: bool ## Whether item was hidden when saved.
  label*: string ## Display label, decoded from file's UTF-8 bytes.
  geometry*: Multivector ## Object itself, one coefficient per basis term.
  radius*: float ## Drawn radius, in world units; `RADIUS_ITEM_DEFAULT` before version 4.
  shines*: bool ## Whether item lights others; false before version 5.


const ORDINAL_INK_ALGEBRA_V5 = 7
  ## Record structural slot `Algebra`, debug layer's hue, held in palette up to version 5.
  ##   Sat after `Outline` and before `Invalid`, so every slot past it is one down today.
  ##   Recorded as number because enum entry it indexes no longer exists.


func upgradedFrom1(item: ItemSaved): Option[ItemSaved] =
  ## Carry one item from what version 1 meant to what version 2 means.
  ##   None where version 1 could not have written it.
  ##   Only palette moved: version 1's hues began earlier and ran three longer.
  ##     Seven structural slots untouched, five surviving hues land on today's first five,
  ##     three retired ones fold onto hues by same cycle `inkCycled` walks.
  ##   One file this gets wrong is browser's own, which stamped version 1 onto version-2
  ##   content for while; nothing in bytes tells it apart.
  ##     Its colours come back one hue along; saving restamps it.
  ##     Treating version 1 as 2 would refuse genuine version-1 file whose `Magenta` and
  ##     `Cerise` fall past palette.
  if item.ink_ordinal < 0 or item.ink_ordinal > ORDINAL_INK_HIGH_V1: return none(ItemSaved)
  var carried = item
  if carried.ink_ordinal >= ORDINAL_INK_CATEGORICAL_V1:
    # Land in version 2's palette, not today's: hues there sat one past `Algebra`.
    #   `upgradedFrom5` takes them down, as it does for every file of versions 2 to 5.
    carried.ink_ordinal =
      ord(inkCycled(carried.ink_ordinal - ORDINAL_INK_CATEGORICAL_V1)) + 1
  some(carried)


func upgradedFrom2(item: ItemSaved): Option[ItemSaved] = some(item)
  ## Carry one item from what version 2 meant to what version 3 means, which is nothing.
  ##   Version 3 changed only what sequence promises, and item alone carries no sequence.
  ##     Version-2 file's order is taken as creation order, closest thing it has.
  ##   Kept as explicit step so chain has one entry per boundary.


func upgradedFrom3(item: ItemSaved): Option[ItemSaved] =
  ## Carry one item from what version 3 meant to what version 4 means.
  ##   Version 3 wrote no radius, and drew every point at one fixed pixel size.
  ##     Reader fills `RADIUS_ITEM_DEFAULT`, that size at opening camera, so old scene
  ##     opens looking as it was saved.
  var carried = item
  carried.radius = RADIUS_ITEM_DEFAULT
  some(carried)


func upgradedFrom4(item: ItemSaved): Option[ItemSaved] =
  ## Carry one item from what version 4 meant to what version 5 means.
  ##   Version 4 knew no sun, so nothing shines and every point draws flat, as it did.
  var carried = item
  carried.shines = false
  some(carried)


func upgradedFrom5(item: ItemSaved): Option[ItemSaved] =
  ## Carry one item from what version 5 meant to what version 6 means.
  ##   Version 6 dropped `Algebra` from palette; hues past it move one down.
  ##   None for item wearing it: structural slot no build ever assigned to object, so
  ##   byte saying so is corrupt, refused as every other unwritable byte is.
  if item.ink_ordinal == ORDINAL_INK_ALGEBRA_V5: return none(ItemSaved)
  var carried = item
  if carried.ink_ordinal > ORDINAL_INK_ALGEBRA_V5: dec carried.ink_ordinal
  some(carried)


func itemUpgraded*(item: ItemSaved, version: uint8): Option[ItemSaved] =
  ## Carry item read from file of `version` up to shape this build works in.
  ##   One boundary at time; none where no version could have written it.
  ##   On success every field is at `VERSION_SCENE`'s meaning, so caller may take
  ##   `Ink(ink_ordinal)` without further check.
  ##     Last guard here buys that, checked once at end.
  if not readsSceneVersion(version): return none(ItemSaved)
  var carried = item
  for boundary in version ..< VERSION_SCENE:
    let stepped =
      case boundary
      of 1'u8: carried.upgradedFrom1
      of 2'u8: carried.upgradedFrom2
      of 3'u8: carried.upgradedFrom3
      of 4'u8: carried.upgradedFrom4
      of 5'u8: carried.upgradedFrom5
      else: none(ItemSaved) # Unreachable: `readsSceneVersion` bounds walk above.
    if stepped.isNone: return none(ItemSaved)
    carried = stepped.get
  if carried.ink_ordinal notin ord(Ink.low) .. ord(Ink.high): return none(ItemSaved)
  # Refuse radius no build could have written, as palette slot is refused above.
  #   Zero or negative would draw nothing and trip `addItem`; NaN compares false to both.
  if not (carried.radius > 0.0): return none(ItemSaved)
  some(carried)


const
  SECONDS_REPLAY_STEP* = 0.12
    ## Space one loaded object's appearance from next by this beat.
    ##   Shorter than `tessellate.ANIMATION_SECONDS`, so each object is still growing as
    ##   next arrives: replay reads as one construction unfolding.
  SECONDS_REPLAY_WHOLE* = 2.5
    ## Bound how long whole replay may take, however many objects arrive.
    ##   Full `ITEMS_MAX` scene at full beat would take many times longer; beat shortens
    ##   instead, keeping order legible while bounding wait.


func bornReplaying*(index, count: int; now: float): float =
  ## Stamp `index`-th of `count` objects arriving together, one after another from `now`.
  ##   One rule both loaders use, i.e. desktop's `loadScene` and browser's
  ##   `browser_bridge.nimSceneAddRaw`, because beat computed twice drifts.
  ##   `count` is whole arrival, so beat can be shortened to fit cap.
  ##     Caller not knowing whole passes own index plus one and gets unbounded beat.
  let step =
    if count <= 1: SECONDS_REPLAY_STEP
    else: min(SECONDS_REPLAY_STEP, SECONDS_REPLAY_WHOLE/float(count - 1))
  now + float(index)*step


func replayFrom*(scene: var Scene, now: float) =
  ## Stamp every live item to arrive one after another from `now`, oldest creation first.
  ##   Scene assembled at once then plays back as construction it is.
  ##   For arrivals reader did not build and is about to be shown whole, i.e. opening
  ##   scene and demo preset; scene built by hand never wants this.
  ##   `loadScene` and `nimSceneAddRaw` stamp as they add instead; this is same rule
  ##   applied after fact.
  var slots: array[ITEMS_MAX, int]
  let count = scene.slotsCreated(slots)
  for position in 0 ..< count:
    scene.borns[slots[position]] = bornReplaying(position, count, now)
  scene.markEdited()


## Keep constants above outside desktop-only guard below, exported.
##   They describe format rather than file handling: browser build gets them via
##   `browser_bridge.nimSceneMagic`/`nimSceneVersion` rather than literals of own.
##   Derived value behind export cannot drift; literal in other language did, stamping
##   version 1 on version-2 content and refusing every desktop file.

when not defined(js):
  # Import filesystem here, under guard excluding save and load.
  #   JS build then never warns about imports nothing on its path uses.
  #   `endians` joins them because byte order is property of file.
  import std/[endians, os, syncio]

  proc writeLittle[T](file: File, value: T) =
    ## Write one multi-byte field in file's little-endian order.
    ##   Through staging array: `littleEndian32`/`64` write into destination, and handing
    ##   caller's variable would byte-swap live value on big-endian host.
    ##   Sized off `T`, so field can never be written at width its type lacks.
    var bytes: array[sizeof(T), byte]
    when sizeof(T) == 4: littleEndian32(addr bytes[0], unsafeAddr value)
    elif sizeof(T) == 8: littleEndian64(addr bytes[0], unsafeAddr value)
    else: {.error: "Scene fields are written as 4- or 8-byte little-endian values only.".}
    discard file.writeBuffer(addr bytes[0], sizeof(T))


  proc readLittle[T](file: File, value: var T): bool =
    ## Read one multi-byte little-endian field into host order.
    ##   Reports whether file held that many bytes, so caller can name truncation.
    var bytes: array[sizeof(T), byte]
    if file.readBuffer(addr bytes[0], sizeof(T)) != sizeof(T): return false
    when sizeof(T) == 4: littleEndian32(addr value, addr bytes[0])
    elif sizeof(T) == 8: littleEndian64(addr value, addr bytes[0])
    else: {.error: "Scene fields are read as 4- or 8-byte little-endian values only.".}
    true


  proc saveScene*(scene: Scene, path: string): string =
    ## Write every live item to `path`, in format documented above; report outcome.
    if len(path) == 0: return "Save path is empty; nothing written."
    let file = open(path, fmWrite)
    defer: file.close

    discard file.writeChars(MAGIC_SCENE, 0, len(MAGIC_SCENE))
    file.write(char(VERSION_SCENE))
    file.write(char(ord(Basis.high) + 1))
    file.writeLittle(uint32(scene.len))

    # Write in creation order, whole of what sequence means from version 3 on.
    var slots: array[ITEMS_MAX, int]
    let count = scene.slotsCreated(slots)
    for position in 0 ..< count:
      let item = scene[slots[position]]
      file.write(char(ord(item.ink)))
      file.write(char(ord(item.isVisible)))
      let
        text = toText(item.label)
        geometry = item.geometry
      file.write(char(len(text)))
      discard file.writeChars(text, 0, len(text))
      for b in Basis: file.writeLittle(geometry[b])
      file.writeLittle(item.radius)
      file.write(char(ord(item.shines)))

    &"Saved {scene.len} object(s) to `{path}`."


  proc loadScene*(scene: var Scene, path: string, now: float = 0.0): string =
    ## Replace scene's contents with what `path` holds; report outcome for display.
    ##   Parses into scene of own and replaces caller's only on complete success, so bad
    ##   or foreign file leaves scene untouched rather than half-overwritten.
    ##   `now` is clock arrival is staggered from (see `bornReplaying`).
    ##     Default lands every object long in past, fully grown.
    ##   Reads every version down to `VERSION_SCENE_LEAST`; see format table.
    ##   Exceeds 60-line default: format is strict sequence of fixed-size fields, each
    ##   needing own guard against truncated or foreign file.
    if len(path) == 0: return "Load path is empty; nothing read."
    if not fileExists(path): return &"No such file `{path}`."

    let file = open(path, fmRead)
    defer: file.close

    var magic = newString(len(MAGIC_SCENE))
    if file.readChars(magic) != len(MAGIC_SCENE) or magic != MAGIC_SCENE:
      return &"`{path}` is not a scene file."

    var version_byte: array[1, char]
    if file.readChars(version_byte) != 1 or not readsSceneVersion(uint8(version_byte[0])):
      return &"`{path}` is a scene file of a version this build cannot read."
    let version = uint8(version_byte[0])

    let basis_count_here = ord(Basis.high) + 1
    var basis_count: array[1, char]
    if file.readChars(basis_count) != 1 or int(uint8(basis_count[0])) != basis_count_here:
      return &"`{path}` was saved under a different PGA dimension or metric; " &
        &"this build reads {basis_count_here}-term multivectors."

    var count: uint32
    if not file.readLittle(count):
      return &"`{path}` is truncated; no item count."
    if int(count) > ITEMS_MAX:
      return &"`{path}` holds {count} objects, more than this build's {ITEMS_MAX}-item " &
        "capacity; raise `--define:visualiser.items_max`."

    var staging = initScene()
    for index in 0 ..< int(count):
      var ink_byte, visible_byte, length_byte: array[1, char]
      if file.readChars(ink_byte) != 1 or file.readChars(visible_byte) != 1 or
          file.readChars(length_byte) != 1:
        return &"`{path}` is truncated partway through object {index}."

      let length = int(uint8(length_byte[0]))
      var label = newString(length)
      if length > 0 and file.readChars(label) != length:
        return &"`{path}` is truncated partway through object {index}'s label."

      var geometry: Multivector
      for b in Basis:
        var coefficient: float
        if not file.readLittle(coefficient):
          return &"`{path}` is truncated partway through object {index}'s geometry."
        geometry[b] = coefficient

      # Read radius only where file has one; earlier versions take it from upgrade.
      var radius = RADIUS_ITEM_DEFAULT
      if hasRadius(version) and not file.readLittle(radius):
        return &"`{path}` is truncated partway through object {index}'s radius."

      # Read shines byte only where file has one, as radius above.
      var shines = false
      if hasShine(version):
        var shine_byte: array[1, char]
        if file.readChars(shine_byte) != 1:
          return &"`{path}` is truncated partway through object {index}'s shine."
        shines = uint8(shine_byte[0]) != 0

      # Read at file's version, then carry up to this build's.
      #   Every field below means what `VERSION_SCENE` says.
      let carried = itemUpgraded(
        ItemSaved(
          ink_ordinal: int(uint8(ink_byte[0])),
          is_visible: uint8(visible_byte[0]) != 0,
          label: label,
          geometry: geometry,
          radius: radius,
          shines: shines,
        ),
        version,
      )
      if carried.isNone:
        return &"`{path}` names an unknown palette slot or radius for object {index}."

      # Add in file order, so staging scene's ordinals come out as file's sequence.
      let slot = staging.addItem(
        carried.get.geometry, carried.get.label, Ink(carried.get.ink_ordinal),
        bornReplaying(index, int(count), now), radius = carried.get.radius,
        shines = carried.get.shines,
      )
      staging.setVisible(slot, carried.get.is_visible)

    # Carry palette on past what was loaded.
    #   Next object built then does not repeat first object's hue.
    #   Not stored in file: count places cycle.
    staging.index_ink = int(count)
    scene = staging
    &"Loaded {count} object(s) from `{path}`."


type OperationMemory* = object ## Define memory of operation last applied, one per arity.
  ## Picker opens on what reader last reached for.
  ##   Reader applying five wedges in row picks operation once.
  ## Per arity because two pickers offer disjoint lists.
  ## Plain value type with no refs, like `Selection`, so GUI holds one by value.
  unary: Operation
  binary: Operation
  is_started: bool ## Whether two above have been set; false leaves defaults below.


const
  OPERATION_FIRST_UNARY* = Operation.Attitude
    ## Open one-operand picker on this until something else is applied.
    ##   One unary operation whose result is drawn somewhere new rather than on top of own
    ##   operand.
  OPERATION_FIRST_BINARY* = Operation.Wedge
    ## Open two-operand picker on this until something else is applied.
    ##   Join, what two objects picked in order most often mean.


func lastOf*(memory: OperationMemory, arity: Arity): Operation =
  ## Read operation picker of this arity should open on.
  if not memory.is_started:
    return if arity == Arity.One: OPERATION_FIRST_UNARY else: OPERATION_FIRST_BINARY
  if arity == Arity.One: memory.unary else: memory.binary


func remember*(memory: var OperationMemory, operation: Operation) =
  ## Note operation as one its arity should open on next.
  ##   Call from every path applying one, drag menu's `more…` handover included, or picker
  ##   forgets what was reached for by another route.
  if not memory.is_started:
    memory.unary = OPERATION_FIRST_UNARY
    memory.binary = OPERATION_FIRST_BINARY
    memory.is_started = true
  if lut_operation_to_arity[operation] == Arity.One: memory.unary = operation
  else: memory.binary = operation
