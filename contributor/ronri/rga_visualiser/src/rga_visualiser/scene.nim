## Hold objects visualiser draws, and catalogue of operations that derive new ones.
##
## Scene is fixed-capacity and owned by caller, so nothing is allocated after setup.
##   Storage is structure-of-arrays, one array per field, addressed by handle rather than
##   dense position: handle is assigned once, on `addObject`, and never moves again.
##   Label is fixed char storage rather than string, so GUI can edit it in place.
## Free handles thread onto intrusive singly-linked list, `next_free`.
##   `addObject` and `removeObject` run in constant time however many objects scene holds.
##   Link lives inside handle array itself; dead handle's `next_free` costs nothing beyond what
##   handle carries while alive.
##   Stable handle keeps every cross-frame index GUI holds (operands picked, object hovered,
##   object mid-drag) valid, narrowing staleness to removed object's own references, without
##   generation counter.
## Each object is stored about exact anchor of its own, and read about world origin.
##   Anchor is place in doubles, never computed again once chosen; coefficients are held
##   about it, so object far out keeps scale of its own.
##     Two points metre apart beside HD 222237 b stay metre apart about anchor there,
##     where about Sol double steps 17 to 35 m and stores pair as one point.
##   Geometry about world origin is derived from anchor and coefficients on each edit,
##   through library's own slide, and never written back to storage.
##     Every per-frame reader reads that cache: desktop places every object each frame.
##     Rejected: storage rewritten about each new centre, which loses metre pair beside
##     star after one move there and back.
##   Cost: anchor and coefficients about it beside cached geometry, 152 bytes more per
##   handle in scene and in each step of undo timeline; one slide per edit of object
##   anchored away from world origin.
## Operation catalogue is what makes scene live rather than scripted.
##   Every entry is one of library's named aliases, applied to objects user picks.
##
##   |---------|--------------------------------|--------------------------------------|
##   | Arity   | Operations                     | Meaning                              |
##   |---------|--------------------------------|--------------------------------------|
##   | One     | ⊖ ∩ ∪ \ / ★ ☆ ~ ~∘ - ^ ∙ ∘     | Attitude, support, duals, norms.     |
##   | Two     | + - ∧ ∨ ⟑ ⟇ ∙ ∘ ∧★ ∧☆ ∨★ ∨☆    | Join, meet, geometric products.      |
##   |---------|--------------------------------|--------------------------------------|
##
## Shared by desktop (`main.nim`) and browser (`bridge.nim`) render paths.
##   `saveScene`/`loadScene` are native-only (`when not defined(js)`); browser saves and
##   loads via download/upload.

{.experimental: "strictFuncs".}

import std/[math, options, strformat, strutils, unicode]

# `pga` arrives through `projections`, which stands in for four it has withdrawn.
import ./[boundary, format, motors, projections, tessellate]



#[ Scene Configuration ]#

# Allow caller to resize scene without editing source.
#   E.g. `--define:visualiser.objects_max=128 --define:visualiser.label_max=48`.
const
  OBJECTS_MAX* {.define: "visualiser.objects_max".} = 5040
    ## Bound objects scene may hold at once.
    ##   Sized so demo holds real solar neighbourhood; see `orrery`.
    ##   Four capacities in `mesh` are sized against this and checked below, since `mesh`
    ##   cannot see it from where it sits in import order.
  LABEL_MAX* {.define: "visualiser.label_max".} = 40  ## Bound characters label may hold.
static:
  doAssert OBJECTS_MAX > 0, &"Scene capacity must be positive; got `{OBJECTS_MAX}`."
  doAssert LABEL_MAX >= 8, &"Label must hold 8 characters; got `{LABEL_MAX}`."

  # Tie mesh's capacities to this one where both are visible.
  #   Overflowing any is `doAssert` at draw time, dead page, so raising `OBJECTS_MAX` fails
  #   to compile instead.
  doAssert VERTICES_MAX >= 2 * OBJECTS_MAX,
    &"`mesh.VERTICES_MAX` must hold every point drawn twice, `{2*OBJECTS_MAX}` at this " &
    &"capacity; got `{VERTICES_MAX}`."
  doAssert DISCS_MAX >= 2 * OBJECTS_MAX + 1,
    &"`mesh.DISCS_MAX` must hold every plane drawn twice plus a preview, " &
    &"`{2*OBJECTS_MAX + 1}` at this capacity; got `{DISCS_MAX}`."
  doAssert DOMES_MAX >= 2 * OBJECTS_MAX + 1,
    &"`mesh.DOMES_MAX` must hold every horizon plane drawn twice plus a preview, " &
    &"`{2*OBJECTS_MAX + 1}` at this capacity; got `{DOMES_MAX}`."
  doAssert RINGS_MAX >= 2 * OBJECTS_MAX + 1,
    &"`mesh.RINGS_MAX` must hold every plane's rim drawn twice plus a preview, " &
    &"`{2*OBJECTS_MAX + 1}` at this capacity; got `{RINGS_MAX}`."
  # Bind on scene of lines.
  #   Rim is one ring record, so what fills ribbons is two segments `tessellate.addLine`
  #   steps out per anchor, drawn twice.
  doAssert RIBBONS_MAX >= 4 * OBJECTS_MAX + 1,
    &"`mesh.RIBBONS_MAX` must hold a scene of lines, each two segments drawn twice, " &
    &"plus a preview, `{4*OBJECTS_MAX + 1}` at this capacity; got `{RIBBONS_MAX}`."



#[ Type Definitions ]#

type
  Label* = array[LABEL_MAX, char]
    ## Define object's display text, terminated by 0, so GUI may edit it without allocating.

  Object* = object  ## Define handle onto one live handle's data.
    ## View on native builds, copy under JS backend, where value parameter's address does
    ## not carry across calls.
    ## Holds pointer into `scene`'s storage plus handle number.
    ##   Reading `.geometry`, `.label`, `.ink`, `.isVisible` or `.born` resolves into that
    ##   storage each time.
    ##   Do not hold one across mutation of its own handle (`removeObject` then `addObject`).
    when defined(js):
      scene: Scene
    else:
      scene: ptr Scene
    handle: int

  Anchored* = object  ## Define object as scene stores it: exact anchor, and coefficients about it.
    anchor*: Position  ## Place coefficients stand about, never computed again once chosen.
    local*: Multivector  ## Object about `anchor`.

  SceneStored* = object  ## Define everything scene stores: each field but geometry it derives.
    ## Held apart from that cache, so value holding what scene stores carries none of it.
    anchors: array[OBJECTS_MAX, Position]  ## Per-handle place geometry is stored about.
    locals: array[OBJECTS_MAX, Multivector]  ## Per-handle geometry about its anchor, as stored.
    labels: array[OBJECTS_MAX, Label]  ## Per-handle display label.
    inks: array[OBJECTS_MAX, Ink]  ## Per-handle palette entry.
    radii: array[OBJECTS_MAX, float]  ## Per-handle drawn radius, in world units; see `radiusAt`.
      ## Read only for point: line and plane take their size from camera and horizon.
    are_visible: array[OBJECTS_MAX, bool]  ## Per-handle visibility.
    are_alive: array[OBJECTS_MAX, bool]  ## Per-handle occupancy; false where handle is free.
    borns: array[OBJECTS_MAX, float]  ## Per-handle moment object was added, for appear animation.
      ## Not written to scene file, since clock reading means nothing across runs.
      ## Loaded object is stamped all same, so file replays own construction; see
      ## `bornReplaying`.
    revisions_placing: array[OBJECTS_MAX, int]  ## Per-handle revision at which handle's placing
      ## inputs last changed; see `revisionPlacingAt`.
      ## Placing inputs are geometry, its anchor and anchor override.
    orders: array[OBJECTS_MAX, uint32]  ## Per-handle creation ordinal.
      ## How many objects scene had ever been given when this one arrived.
      ## Separate from `borns` because clock reading cannot answer this.
      ##   Two objects added in one frame share reading, loaded readings are stamped for
      ##   replay, and refilled handle keeps old reading until overwritten.
      ## Only ever increases, is never reused, and survives save and load because file's
      ## object sequence is this order.
      ##   Buys `saveScene` writing objects in order built, so reload replays construction
      ##   even after removals scrambled handle order.
    anchor_overrides: array[OBJECTS_MAX, Option[Position]]  ## Where plane's circle should
      ## centre, for object whose construction fixes that more specifically than its
      ## closest-to-origin support; see `creationAnchor`.
      ## Held about object's anchor, as its coefficients are; see `anchorOverrideAt`.
      ## None for anything else.
      ## Not saved or loaded: rendering hint recomputed from how object was built.
    next_free: array[OBJECTS_MAX, Option[int]]  ## Link to next free handle; intrusive free list.
    handle_free_first: Option[int]  ## Head of free list; none where scene is full.
    count_live: int  ## Number of occupied handles, so `len` need not rescan `are_alive`.
    handle_live_last: int  ## One past highest handle ever occupied; see `bound`.
    count_created: uint32  ## Ordinals handed out so far, and next one to hand out.
      ## Counts additions over scene's whole life, never removals.
    count_edits: int  ## How many times scene's drawn content has changed; see `revision`.
    index_ink: int  ## How far categorical cycle has been walked; next hue to hand out.
      ## Own counter rather than `len`, because drag that built nothing still steps
      ## palette.
      ##   Reader watched colour on band and it should not be offered again.
      ## Undo restores it with rest of scene.
      ## Not written to file: `loadScene` sets it from object count.

  Scene* = object  ## Define fixed-capacity arena of objects, addressed by stable handle.
    stored: SceneStored  ## Everything scene stores; see `SceneStored`.
    geometries: array[OBJECTS_MAX, Multivector]  ## Per-handle geometry about world origin.
      ## Derived from anchor and local coefficients on each edit, never written back.

  Arity* {.pure.} = enum  ## Define count of operands operation consumes.
    One, Two

  Operation* {.pure.} = enum  ## Define every operation GUI may apply to scene's objects.
    ## Name one-operand operations, in order library's own documentation lists them.
    Attitude, Support, SupportAnti, Bulk, Weight, Unitize,
    ComplementLeft, ComplementRight, DualBulk, DualWeight,
    Reverse, ReverseAnti, Negate,
    ## Name two-operand operations, likewise.
    Add, Subtract, Wedge, WedgeAnti, WedgeDot, WedgeDotAnti, Dot, DotAnti,
    ExpandBulk, ExpandWeight, ContractBulk, ContractWeight,
    ProjectCentral, ProjectOrthogonal,

  Preview* = object  ## Define what applying operation would build, ready to draw and frame.
    ## One statement of uncommitted construction, shared by every path offering one.
    ##   Drag's rubber-band answer and both apply pickers.
    geometry*: Multivector  ## What operation makes of its operands.
    anchor*: Option[Position]  ## Where plane's disc should centre, from `creationAnchor`.
      ## None for every other kind.
      ## Carried so previewed plane is drawn exactly where commit will put it.
    operands*: Option[(int, int)]  ## Handles this was derived from.
      ## For camera framing preview to keep in view beside it.
      ## None where there are none to name: staged edit replaces very object it would be
      ## framed against.
    radius*: float  ## Drawn radius preview takes, where it is point; see `radiusAt`.
      ## Staged session's own, so editing moon previews moon-sized; derived preview takes
      ## `RADIUS_OBJECT_DEFAULT`, what commit gives it.

  ObjectSaved* = object
    ## Define one object exactly as scene file holds it, at whatever version wrote file.
    ##   Kind reading works in, and thing `upgradedFrom<n>` carries between versions.
    ##   Distinct from `Object`: value read off bytes that may not describe anything this
    ##   build can make yet.
    ink_ordinal*: int  ## Palette slot, as writing version's `Ink` numbered it.
    is_visible*: bool  ## Whether object was hidden when saved.
    label*: string  ## Display label, decoded from file's UTF-8 bytes.
    geometry*: Multivector  ## Object about `anchor`, one coefficient per basis term.
    radius*: float  ## Drawn radius, in world units; `RADIUS_OBJECT_DEFAULT` before version 4.
    anchor*: Position  ## Place `geometry` stands about; world origin before version 8.

  OperationMemory* = object  ## Define memory of operation last applied, one per arity.
    ## Picker opens on what reader last reached for.
    ##   Reader applying five wedges in row picks operation once.
    ## Per arity because two pickers offer disjoint lists.
    ## Plain value type with no refs, like `Selection`, so GUI holds one by value.
    unary: Operation
    binary: Operation
    is_started: bool  ## Whether two above have been set; false leaves defaults below.



#[ Operation Catalogue ]#

const LUT_ARITY_BY_OPERATION*: array[Operation, Arity] = [
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
]  ## Map operation to number of operands it consumes.


const LUT_NOTATION_BY_OPERATION* = [
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
]  ## Map operation to notation and name GUI offers it under, for both render paths.
  ##   Operands in Lengyel's mathematical bold, every symbol's placement his.
  ##   Written with spacing modifier letters (`ˆ` U+02C6, `ˍ` U+02CD, `¯` U+00AF, `˜`
  ##   U+02DC, `˷` U+02F7) rather than combining marks.
  ##     Combining marks need shaper Dear ImGui lacks, landing beside operand instead of
  ##     over it; spacing modifier carries own advance, so both renderers place it same
  ##     way.
  ##   Not second plain-ASCII table: atlas merges faces carrying astral-plane glyphs (see
  ##   `visualiser.face_font_math`).
  ##   `const` of `string`, with `cstring` array picker needs built from it below.
  ##     `help.nim` builds own table at compile time, so catalogue tab needs text before
  ##     program runs; addresses derive from text, never text from addresses.


let LUT_NOTATION_CSTRING_BY_OPERATION* = block:
  ## Map operation to same entries as `cstring`, what picker offers.
  ##   Dear ImGui takes address of first and reads them for life of combo.
  ##   Built from table above rather than written beside it.
  var lut: array[Operation, cstring]
  for operation in Operation: lut[operation] = cstring(LUT_NOTATION_BY_OPERATION[operation])
  lut


const
  COUNT_OPERATION* = ord(Operation.high) + 1
    ## Count operations, for handing whole catalogue to picker.

  LUT_SPLIT_BY_OPERATION* = block:
    ## Map operation to its two halves: symbols it is written with, and English name after.
    ##   One split, at one place, i.e. double space between them, so no caller cuts at
    ##   second place that drifts.
    ##   `const`, so `help.nim` can build catalogue tab from it at compile time.
    var lut: array[Operation, tuple[symbols, name: string]]
    for operation in Operation:
      let
        full = LUT_NOTATION_BY_OPERATION[operation]
        cutoff = full.find("  ")
      lut[operation] =
        if cutoff >= 0: (symbols: full[0..<cutoff], name: full[cutoff+2 .. ^1].strip())
        else: (symbols: full, name: "")
    lut


func notationSymbolic*(operation: Operation): string =
  ## Report symbols operation is written with, without English name.
  ##   `𝐦 ∧ 𝐧`, not `𝐦 ∧ 𝐧  wedge (join)`.
  ##   What picker offers on both front-ends: full entry is several times wider, and
  ##   pushes selection menu's popover past what hand can reach on phone.
  LUT_SPLIT_BY_OPERATION[operation].symbols


func notationNamed*(operation: Operation): string =
  ## Report English name operation is offered under, other half of `notationSymbolic`.
  ##   `wedge (join)`, not `𝐦 ∧ 𝐧`.
  ##   What help's catalogue tab reads, so tab says exactly what every picker offers.
  LUT_SPLIT_BY_OPERATION[operation].name


const
  SYMBOLS_OPERATOR_BINARY = ["∧", "∨", "⟑", "⟇", "∙", "∘", "+", "-"]
    ## List binary operators as templates write them, one token between spaces.
  SYMBOLS_OPERATOR_ASSOCIATIVE = ["∧", "∨", "+"]
    ## List binary operators whose chain reads one way however it is bracketed.
    ##   Products are associative too, but chain of them is rare and brackets cost nothing.
  SYMBOLS_OPERATOR_POSTFIX = ["⊖", "★", "☆", "¯", "˜", "˷", "ˆ", "ˍ"]
    ## List unary operators templates write after operand, binding tighter than any binary.
  SYMBOL_NEGATE = "−"  ## Unary operator templates write before operand, U+2212.


func operatorsOutermost(name: string): seq[string] =
  ## List operators standing at name's top level, outside every parenthesis.
  ##   Binary symbols between spaces, and negation leading name. Empty for atomic name,
  ##   and for one whose only operators are postfix, `L⊖`.
  if name.startsWith(SYMBOL_NEGATE): result.add(SYMBOL_NEGATE)
  var depth = 0
  for token in name.split(' '):
    if depth == 0 and token in SYMBOLS_OPERATOR_BINARY and token notin result:
      result.add(token)
    depth += token.count('(') - token.count(')')


func isParenthesised(name: string): bool =
  ## Report whether one pair of parentheses encloses whole name.
  if name.len < 2 or name[0] != '(' or name[^1] != ')': return false
  var depth = 0
  for i, c in name:
    if c == '(': inc depth
    elif c == ')':
      dec depth
      if depth == 0 and i < name.high: return false
  depth == 0


func nameInContext(name, operator_binding: string; is_unary: bool): string =
  ## Wrap composite operand name in parentheses where template binds it tighter than its
  ##   own outermost operator; leave atomic or already wrapped name alone.
  ##   Under postfix or negation, every composite is wrapped: `(a ∧ b)★`. Under binary
  ##   operator, composite whose only outermost operator is that same associative one
  ##   stays flat, `a ∧ b ∧ c`; any other is wrapped, `(a ∧ b) ∨ c`, `a - (b - c)`.
  ##   Not bare substitution, which read `a ∧ b ∨ c` and named another object.
  if isParenthesised(name): return name
  let outer = operatorsOutermost(name)
  if outer.len == 0: return name
  if not is_unary and outer.len == 1 and outer[0] == operator_binding and
      operator_binding in SYMBOLS_OPERATOR_ASSOCIATIVE:
    return name
  "(" & name & ")"


func notationSubstituted*(operation: Operation; name_first, name_second: string): string =
  ## Build label text applied operation reads as, with real operand names in place.
  ##   Substitutes template's `𝐦`/`𝐧`: `Operation.Wedge` with `a`/`b` gives `a ∧ b`.
  ##   Matches bold operands, not plain ASCII `m`/`n`: English description after symbols
  ##   contains ordinary `m` and `n` constantly.
  ##   Walks template token by token, so operand name is inserted once and never rescanned
  ##   (name containing placeholder survives), and template where `𝐧` appears twice
  ##   (ProjectCentral/ProjectOrthogonal) substitutes both. Each occurrence is wrapped for
  ##   its own binding, `nameInContext`: postfix symbol right after it or negation right
  ##   before it is unary; otherwise binary operator token beside it binds it.
  const
    operand_first = "𝐦"
    operand_second = "𝐧"
  var tokens = notationSymbolic(operation).split(' ')
  for i in 0..<tokens.len:
    let
      token = tokens[i]
      (placeholder, name) =
        if operand_first in token: (operand_first, name_first)
        elif operand_second in token: (operand_second, name_second)
        else: continue
    let
      at = token.find(placeholder)
      before = token[0..<at]
      after = token[at+placeholder.len .. ^1]
    var is_unary = before.endsWith(SYMBOL_NEGATE)
    for symbol in SYMBOLS_OPERATOR_POSTFIX:
      if after.startsWith(symbol): is_unary = true
    var binding = ""
    if not is_unary:
      if i + 1 < tokens.len and tokens[i+1] in SYMBOLS_OPERATOR_BINARY:
        binding = tokens[i+1]
      elif i > 0 and tokens[i-1] in SYMBOLS_OPERATOR_BINARY:
        binding = tokens[i-1]
    tokens[i] = before & nameInContext(name, binding, is_unary) & after
  tokens.join(" ")


const OPERATIONS_SLIDING = {
  Operation.Add, Operation.Attitude, Operation.ContractWeight, Operation.DotAnti,
  Operation.DualWeight, Operation.ExpandWeight, Operation.Negate, Operation.ProjectOrthogonal,
  Operation.Reverse, Operation.ReverseAnti, Operation.Subtract, Operation.Unitize,
  Operation.Wedge, Operation.WedgeAnti, Operation.WedgeDotAnti,
}
  ## Name operations that commute with slide: run about any origin, then slid back, each gives
  ##   what it gives about Sol, so `applyOperation` runs each about point near its operands.
  ##   Other twelve read origin itself (support, bulk, weight dot, complements, central
  ##   projection), and run about Sol, which is origin they mean.
  ##   Suite holds set to exactly operations that commute; reached there through `{.all.}`.


func slid(m: Multivector, offset: Direction): Multivector =
  ## Slide `m` by `offset` through library's own motor, keeping only grades `m` occupies.
  ##   Slide keeps every grade, so what lands on another is sandwich's rounding: about `ε`
  ##   of distance slid, against `m`. Join metre across one unit out reads it as mixed.
  ##   `m` itself, bit for bit, where offset is zero: object read about own anchor pays
  ##   nothing, and slide by zero would round nothing anyway.
  if offset.x == 0.0 and offset.y == 0.0 and offset.z == 0.0: return m
  let
    motor = motorSliding(offset.toMultivector)
    moved = m.carried(motor, ~∘motor)
  var occupied: array[0..DIMENSIONS, bool]
  for b in Basis:
    if m[b] != 0.0: occupied[int(b.grade)] = true
  for b in Basis:
    if occupied[int(b.grade)]: result[b] = moved[b]


func geometryAbout*(anchored: Anchored, centre: Position): Multivector =
  ## Read object about `centre`: its coefficients slid by its anchor less `centre`.
  ##   Exact where anchor is `centre`; else rounding is `ε` of distance slid, never of
  ##   distance either stands from Sol.
  slid(anchored.local, anchored.anchor - centre)


func overrideAbout(held: Option[Position]; anchor, centre: Position): Option[Position] =
  ## Read anchor override held about `anchor` as it stands about `centre`.
  ##   Hint for picture, where plane's disc centres, so offset by Euclidean sum, as disc is
  ##   drawn; exact where anchor is `centre`.
  ##   Per-frame reader checks `held` before calling: most objects hold none, and anchor read
  ##   for each was measurable share of desktop's frame.
  if held.isNone: return
  some(held.get + (anchor - centre))


func operated(operation: Operation; m, n: Multivector): Multivector =
  ## Apply catalogue's operation as library names it, about origin operands stand about.
  ##   Suite reaches it through `{.all.}`, as reference `applyOperation` is held to.
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


func applyOperation*(operation: Operation; m, n: Anchored): Anchored =
  ## Apply operation to operands as scene stores them, ignoring `n` where operation is unary.
  ##   Answer is anchored at origin operation ran about, coefficients about it.
  ##   Operation that commutes with slide (`OPERATIONS_SLIDING`) runs about point near its
  ##   operands: each is slid there from own anchor, through library's own motor.
  ##     Join of two points metre apart one unit out then holds both to micrometres, and
  ##     beside HD 222237 b, anchored there, to nanometres.
  ##     Never about Sol: its moment, `p × q`, cancels to about 1e-5 of itself there, and
  ##     both points stand hundreds of kilometres off it.
  ##     Slide adds `t × d` to small moment, cancelling nothing: rounding is `ε` of
  ##     distance slid.
  ##   Origin is point operand's own place, first operand's first: cancellation is about
  ##   point joined. Else first finite operand's anchor for drawing, its support. Else Sol,
  ##   where no operand stands anywhere finite.
  ##     Each is read about operand's anchor, then offset by it: origin need only stand
  ##     near, and anchor less origin is then exact where two stand within factor two.
  ##   Every other operation runs about Sol, origin it means, and its answer is anchored
  ##   there.
  ##   Each slide keeps only grades its multivector occupies; see `slid`.
  ##   Result within rounding of zero, judged against operands that made it, is zero:
  ##   point lying on line joins with it to nothing, never to rounding.
  ##     `objects.kindOf` reads object at its own scale, so rounding left standing reads
  ##     as plane, and every path building from catalogue builds through here.
  ##     Judged on operands as slid, against farthest either was slid, at least one: each
  ##     carries rounding of where it stood, so far out rounding still reads as zero.
  ##   Sum is judged against its larger operand, as it rounds to that.
  ##   Every other operation is homogeneous in each operand, so it runs again on
  ##   `scaleFree` copies: positive multiple of result, rounding at `TOLERANCE_ROUNDING`
  ##   of one whatever degree operation has in each operand.
  ##   Cost: two slides, two antiproducts each, and second run of operation, once for each
  ##   preview and each build; third slide where caller reads answer about world origin.

  func originLocal(m, n: Anchored): Option[Position] =
    ## Choose point to run about: point operand's own place, else finite operand's anchor.
    for operand in [m, n]:
      if kindOf(operand.local) == some(Kind.Point):
        let place = position(operand.local)
        if place.isSome: return some(operand.anchor + (place.get - ORIGIN_WORLD))
    for operand in [m, n]:
      if kindOf(operand.local).isSome:
        let anchor = positionAnchor(operand.local)
        if anchor.isSome: return some(operand.anchor + (anchor.get - ORIGIN_WORLD))

  # Slide operands to origin chosen, or to Sol.
  let origin =
    if operation in OPERATIONS_SLIDING: originLocal(m, n).get(ORIGIN_WORLD)
    else: ORIGIN_WORLD
  let
    (offset_m, offset_n) = (m.anchor - origin, n.anchor - origin)
    (m_local, n_local) = (slid(m.local, offset_m), slid(n.local, offset_n))
    scale_origin = max(
      1.0,
      max(offset_m.toMultivector.coefficientLargest, offset_n.toMultivector.coefficientLargest),
    )
  result.anchor = origin
  result.local = operated(operation, m_local, n_local)

  # Answer zero where that is rounding of zero.
  let is_rounding =
    case operation
    of Operation.Add, Operation.Subtract:
      result.local.isRoundingOf(
        max(m_local.coefficientLargest, n_local.coefficientLargest) * scale_origin,
      )
    else:
      operated(operation, m_local.scaleFree, n_local.scaleFree).isRoundingOf(scale_origin)
  if is_rounding: result.local = Multivector()


func applyOperation*(operation: Operation; m, n: Multivector): Multivector =
  ## Apply operation to operands about world origin, ignoring `n` where operation is unary.
  ##   Each is read as anchored at world origin, and answer is read back about it; see
  ##   sibling taking `Anchored` for where operation runs.
  ##   For caller holding multivectors alone; scene's own builds go through sibling.
  applyOperation(
    operation, Anchored(anchor: ORIGIN_WORLD, local: m), Anchored(anchor: ORIGIN_WORLD, local: n)
  ).geometryAbout(ORIGIN_WORLD)


func creationAnchor*(operation: Operation; m, n, derived: Multivector): Option[Position] =
  ## Resolve point freshly derived plane's circle should centre on, from how it was built.
  ##   Rather than from closest-to-origin support, so it reads as centred where
  ##   construction happened.
  ##   Computed through same operators construction used.
  ##   None for operation or operand kind not recognised here; caller falls back to
  ##   plane's support (`objects.positionAnchor`).
  case operation
  of Operation.Wedge:
    # Centre between point and line's closest approach to it.
    #   Line wedged with point gives plane line lies within, meeting at no single point.
    #   Both unitized first, so sum's weight is exactly two and position read back is
    #   plain midpoint.
    let (line, point) =
      if kindOf(m) == some(Kind.Line) and kindOf(n) == some(Kind.Point): (m, n)
      elif kindOf(n) == some(Kind.Line) and kindOf(m) == some(Kind.Point): (n, m)
      else: return none(Position)
    position(add(unitize(point), unitize(projectOrthogonal(point, line))))

  of Operation.ExpandWeight:
    # Meet line with plane built perpendicular to it, which crosses at exactly one point.
    let line =
      if kindOf(m) == some(Kind.Line): m
      elif kindOf(n) == some(Kind.Line): n
      else: return none(Position)
    position(wedgeAnti(line, derived))

  else: none(Position)


const OPERATIONS_CENTRING = {Operation.ExpandWeight, Operation.Wedge}
  ## Name operations `creationAnchor` centres plane of; every other answers none.
  ##   Lets anchored sibling slide no operand for operation it would answer none for.
  ##   Suite holds set to cases sibling answers; reached there through `{.all.}`.


func creationAnchor*(operation: Operation; m, n, derived: Anchored): Option[Position] =
  ## Resolve where freshly derived plane's circle should centre, about anchor `derived` holds.
  ##   Operands are slid to that anchor first, so all three stand about one point, near
  ##   them; then as sibling resolves it.
  ##   Covariant, as every operator it reads commutes with slide: same place about any
  ##   origin, read there.
  if operation notin OPERATIONS_CENTRING: return
  creationAnchor(
    operation,
    m.geometryAbout(derived.anchor),
    n.geometryAbout(derived.anchor),
    derived.local,
  )



#[ Multivector Formatting ]#

const LUT_NAME_BY_BASIS* = block:
  ## Name each basis element as library's `$` names it.
  ##   `𝟏` for scalar, `𝟙` for antiscalar, bold `𝐞` carrying subscript digits for rest.
  ##   Exported so both GUIs label coefficient with its basis element, reading same as
  ##   multivector text beside them.
  ##   Derived rather than transcribed, so build of another dimension names own elements.
  ##     Rule is second copy of one inside `pga/multivectors.nim`'s `$`, which does not
  ##     expose it; check that one whenever this is touched.
  const
    name_scalar = "\u{1D7CF}"  # Mathematical bold digit one.
    name_scalar_anti = "\u{1D7D9}"  # Mathematical double-struck digit one.
    name_vector = "\u{1D41E}"  # Mathematical bold small e.
    codepoint_subscript_zero = 0x2080
  var lut: array[Basis, string]
  for b in Basis:
    lut[b] =
      case b
      of Basis.scalar: name_scalar
      of Basis.scalarAnti: name_scalar_anti
      else:
        # Read index list behind `E` in enum's name, one digit per factor.
        var name = name_vector
        for digit in ($b)[1 .. ^1]:
          name &= $Rune(codepoint_subscript_zero + ord(digit) - ord('0'))
        name
  lut


const
  WIDTH_TERM = 32
    ## Bound one printed term in bytes.
    ##   Separator, magnitude at `DIGITS_SIGNIFICANT` with sign and exponent, space, and
    ##   basis name in mathematical bold with subscripts at up to 13 bytes.
    ##   Bytes, since that is what buffer holds.
  WIDTH_MULTIVECTOR* = (ord(Basis.high) + 1) * WIDTH_TERM + 1
    ## Bound one printed multivector: every basis term at `WIDTH_TERM`, plus terminator.
    ##   Derived from `Basis`, so build of another dimension sizes own buffers.


func formatMultivector*(m: Multivector, storage: var openArray[char], cursor: var int) =
  ## Print multivector into fixed storage, in same shape library's `$` uses.
  ##   Basis elements named exactly as library names them; both GUIs carry faces covering
  ##   those codepoints.
  ##   Magnitudes stay project's four significant digits.
  ##   Appends from `cursor` rather than returning `string`, so redrawing every visible
  ##   object's coefficients every frame never touches heap.
  ##   Term prints where it stands over billionth of largest, as `objects.kindOf` reads it.
  ##     Never against library's absolute tolerance, as `$` judges: line metre long one
  ##     unit out carries coefficients near 1e-12, which that prints as zero.
  let floor = TOLERANCE_ABS * m.coefficientLargest
  var has_written = false
  for b in Basis:
    if abs(m[b]) <= floor: continue
    if m[b] < 0: appendChars(storage, cursor, " - ")
    elif has_written: appendChars(storage, cursor, " + ")
    appendMagnitude(storage, cursor, abs(m[b]))
    appendChars(storage, cursor, " ")
    appendChars(storage, cursor, LUT_NAME_BY_BASIS[b])
    has_written = true
  if not has_written:
    appendChars(storage, cursor, "0 ")
    appendChars(storage, cursor, LUT_NAME_BY_BASIS[Basis.scalar])


const WIDTH_KIND_WORD* = 32  ## Bound kind word alone, longest being "mixed grade, nothing to draw".


func describeKind*(m: Multivector, storage: var openArray[char], cursor: var int) =
  ## Name geometry multivector stands for into fixed storage, for reporting to user.
  ##   Appends from `cursor` onward; see `formatMultivector`.
  let kind = kindOf(m)
  appendChars(storage, cursor,
    if kind.isNone: "mixed grade, nothing to draw"
    else:
      case kind.get
      of Kind.Point: (if m.isHorizon: "horizon point" else: "point")
      of Kind.Line: (if m.isHorizon: "horizon line" else: "line")
      of Kind.Plane: (if m.isHorizon: "horizon plane" else: "plane")
  )


func multivectorText*(m: Multivector): string =
  ## Print `m` as string, for caller with nowhere fixed to put it.
  ##   Wraps `formatMultivector`, so same object reads same in both front-ends.
  var
    storage: array[WIDTH_MULTIVECTOR, char]
    cursor = 0
  formatMultivector(m, storage, cursor)
  finishChars(storage, cursor)
  storage.toText


func kindText*(m: Multivector): string =
  ## Name geometry `m` stands for, as string, for caller with nowhere fixed to put it.
  ##   Wraps `describeKind` rather than restating words, so status line, panel row and
  ##   browser object list cannot drift.
  ##   Allocating is affordable here: called on user action, not per visible object per
  ##   frame.
  var
    storage: array[WIDTH_KIND_WORD, char]
    cursor = 0
  describeKind(m, storage, cursor)
  finishChars(storage, cursor)
  storage.toText



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
  ## Construct empty scene, threading every handle onto free list ahead of first use.
  for handle in 0 ..< OBJECTS_MAX - 1:
    result.stored.next_free[handle] = some(handle + 1)
  result.stored.handle_free_first = some(0)


func len*(scene: Scene): int = scene.stored.count_live
  ## Count live objects held by scene.


func bound*(scene: Scene): int = scene.stored.handle_live_last
  ## Report one past highest handle this scene has ever occupied.
  ##   What walk over "every handle" runs to.
  ##     Handles are stable addresses, so by-handle reader sweeps range rather than dense list,
  ##     and at capacity that means testing every handle per frame to draw few.
  ##   High-water mark rather than live count, because freed handle in middle leaves ones
  ##   above occupied; only ever rises.
  ##   Three walks stay at capacity, each saying so where it stands: free list `initScene`
  ##   threads, and two object-pool strips, whose subject is how much room is left.
  ##   Not `len`: living are not packed at bottom.


func revision*(scene: Scene): int = scene.stored.count_edits
  ## Report how many times scene's drawn content has changed.
  ##   Named apart from field, as `len` and `bound` are: reader named for field it reads
  ##   recurses under this module's scoping.
  ##   For holding last frame's meshes and placements, nothing else.
  ##     Front-end compares against what it saw last frame, equality only, and rebuilds
  ##     where it differs.
  ##     Not version number user sees, not saved.
  ##   Everything changing what is drawn bumps it, and ways to do that are closed.
  ##     Geometry through `setGeometryAt`, ink through `setInk`, visibility through
  ##     `setVisible`, existence through `addObject`/`removeObject`, birth stamps through
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
  inc scene.stored.count_edits


func restoreFrom*(scene: var Scene, snapshot: Scene) =
  ## Replace scene's whole content with snapshot, at revision no earlier state carried.
  ##   Every whole-scene replacement, i.e. undo, redo, clear, load, comes through here.
  ##     Revision only ever rises and no two states front-end has drawn share one.
  ##   Every live handle is stamped as re-placed, since any of them may differ from what
  ##   cache holds.
  let revision_live = scene.stored.count_edits
  scene = snapshot
  scene.stored.count_edits = max(revision_live, snapshot.stored.count_edits) + 1
  for handle in 0..<scene.bound:
    if scene.stored.are_alive[handle]:
      scene.stored.revisions_placing[handle] = scene.stored.count_edits


func revisionPlacingAt*(scene: Scene, handle: int): int =
  ## Report revision at which handle's placing inputs last changed.
  ##   Front-end caching `tessellate.placeObject`'s answer per handle re-places only handles
  ##   stamped past what it holds: one handle per edit, every handle after `restoreFrom`.
  ##   Re-placing whole scene per edit is whole frame at capacity; figures in
  ##   `PROVENANCE.md`.
  scene.stored.revisions_placing[handle]


func isFull*(scene: Scene): bool = scene.stored.count_live >= OBJECTS_MAX
  ## Report whether scene has no room for another object.


func isAlive*(scene: Scene, handle: int): bool =
  ## Report whether handle currently holds live object.
  ##   For handle read back across frame boundary, e.g. operand picked earlier.
  ##   Two comparisons, not `handle in 0 ..< OBJECTS_MAX`.
  ##     JS backend builds slice object per call, and every by-handle reader asserts through
  ##     here, so one moving frame at capacity allocated one per handle.
  handle >= 0 and handle < OBJECTS_MAX and scene.stored.are_alive[handle]


func handleStepped*(scene: Scene, handle: Option[int], step: int): Option[int] =
  ## Walk to next live handle `step` places on from `handle`, wrapping past both ends.
  ##   None where scene holds nothing; first live handle from start where `handle` is none.
  ##   Handles are sparse, so this searches rather than computes; `OBJECTS_MAX` bounds search.
  ##   Wraps deliberately: drives keyboard traversal, and walk stopping dead leaves reader
  ##   pressing key that silently stopped working.
  if scene.len == 0: return none(int)
  doAssert step != 0, &"Step must be non-zero, or search runs forever; got `{step}`."
  let start = if handle.isSome: handle.get else: -1
  for offset in 1..OBJECTS_MAX:
    let candidate = floorMod(start + step * offset, OBJECTS_MAX)
    if scene.isAlive(candidate): return some(candidate)
  none(int)


func `[]`*(scene: Scene, handle: int): Object =
  ## Read object by handle: handle onto `scene`'s storage, not copy of it.
  doAssert scene.isAlive(handle), &"Object handle must be alive; got `{handle}`."
  when defined(js):
    Object(scene: scene, handle: handle)
  else:
    Object(scene: unsafeAddr scene, handle: handle)


func geometry*(one: Object): lent Multivector = one.scene.geometries[one.handle]
  ## Read object's geometry about world origin, straight out of scene handle points at.


func label*(one: Object): lent Label = one.scene.stored.labels[one.handle]
  ## Read object's label, straight out of scene handle points at.


func ink*(one: Object): Ink = one.scene.stored.inks[one.handle]
  ## Read object's palette slot, straight out of scene handle points at.


func isVisible*(one: Object): bool = one.scene.stored.are_visible[one.handle]
  ## Read object's visibility, straight out of scene handle points at.


func radius*(one: Object): float = one.scene.stored.radii[one.handle]
  ## Read object's drawn radius, straight out of scene handle points at; see `radiusAt`.


func born*(one: Object): float = one.scene.stored.borns[one.handle]
  ## Read object's `born` reading, straight out of scene handle points at.


func anchorOverride*(one: Object): Option[Position] =
  ## Read where object's circle should centre about world origin, if construction fixed that.
  ##   See `creationAnchor`.
  if one.scene.stored.anchor_overrides[one.handle].isNone: return
  overrideAbout(
    one.scene.stored.anchor_overrides[one.handle],
    one.scene.stored.anchors[one.handle],
    ORIGIN_WORLD,
  )


func geometryOf*(scene: Scene, handle: int): lent Multivector =
  ## Read object's geometry about world origin in place, by handle, without mutable scene.
  ##   Cached from anchor and local coefficients on each edit, so reading slides nothing.
  ##   `lent`, not `var`: `var`-returning accessor read rather than written miscompiles
  ##   under JS backend; borrow cannot be written through.
  ##   `lent` pays only where result is never bound.
  ##     Returning by value allocates fresh `Multivector` and `nimCopy`s field into it on
  ##     JS backend, once per call.
  ##     Confirmed in generated JavaScript that `lent` removes copy and binding result to
  ##     `let` puts it back, so caller wanting saving uses call inline.
  ##   Borrow lives only while scene is unchanged; do not hold one across edit.
  doAssert scene.isAlive(handle), &"Object handle must be alive; got `{handle}`."
  scene.geometries[handle]


func anchoredAt*(scene: Scene, handle: int): Anchored =
  ## Read object as storage holds it, by handle: its anchor, and coefficients about it.
  ##   What every operation reads its operands as; see `applyOperation`.
  doAssert scene.isAlive(handle), &"Object handle must be alive; got `{handle}`."
  Anchored(anchor: scene.stored.anchors[handle], local: scene.stored.locals[handle])


func geometryAbout*(scene: Scene, handle: int, centre: Position): Multivector =
  ## Read object's geometry about `centre`, by handle, slid afresh from what storage holds.
  ##   For reader standing about point other than world origin; per-frame reader takes
  ##   `geometryOf`, which slides nothing.
  ##   Reads storage and writes nothing, so object read about any centre, any number of
  ##   times, keeps anchor and coefficients bit for bit.
  doAssert scene.isAlive(handle), &"Object handle must be alive; got `{handle}`."
  slid(scene.stored.locals[handle], scene.stored.anchors[handle] - centre)


func deriveGeometryAt(scene: var Scene, handle: int) =
  ## Derive object's geometry about world origin from its anchor and local coefficients.
  ##   One statement of cache's rule, for every writer of either.
  scene.geometries[handle] =
    slid(scene.stored.locals[handle], scene.stored.anchors[handle] - ORIGIN_WORLD)


func setGeometryAt*(scene: var Scene, handle: int, geometry: Multivector) =
  ## Write object's geometry about world origin, by handle: only way its geometry changes.
  ##   Setter rather than `var Multivector`, for reason `geometryOf` gives and second.
  ##     Front-end holding last frame's meshes can only know scene changed if every write
  ##     passes one door; see `revision`.
  ##   Object is anchored again at world origin, where `geometry` stands as reader typed it.
  ##     Anchor override moves with it, so plane's circle stays where it was drawn.
  ##   Geometry object reads already, coefficient for coefficient, writes nothing.
  ##     Edit saved with no coefficient changed keeps object at its own anchor, to precision
  ##     it holds there rather than to that of world origin.
  doAssert scene.isAlive(handle), &"Object handle must be alive; got `{handle}`."
  var is_unchanged = true
  for b in Basis:
    if geometry[b] != scene.geometries[handle][b]: is_unchanged = false
  if is_unchanged: return
  scene.stored.anchor_overrides[handle] =
    overrideAbout(scene.stored.anchor_overrides[handle], scene.stored.anchors[handle], ORIGIN_WORLD)
  scene.stored.anchors[handle] = ORIGIN_WORLD
  scene.stored.locals[handle] = geometry
  scene.deriveGeometryAt(handle)
  scene.markEdited()
  scene.stored.revisions_placing[handle] = scene.stored.count_edits


func labelAt*(scene: var Scene, handle: int): var Label =
  ## Reach object's label for editing, by handle.
  doAssert scene.isAlive(handle), &"Object handle must be alive; got `{handle}`."
  scene.stored.labels[handle]


func isVisible*(scene: Scene, handle: int): bool =
  ## Read object's visibility by value, by handle rather than through `Object`; see `inkAt`.
  ##   Read and written through plain accessor pair, never `var bool`-returning one.
  ##     Proc handing back `var bool` over `array[N, bool]` miscompiles under JS backend,
  ##     reading `undefined` and writing to dropped copy; `setVisible` is writer.
  scene.stored.are_visible[handle]


func inkAt*(scene: Scene, handle: int): Ink =
  ## Read object's palette slot, by handle rather than through `Object`.
  ##   Beside `Object.ink` for caller reading many objects per frame.
  ##     Under JS backend `Object` holds `Scene` by value, so constructing one to read single
  ##     field copies whole scene.
  doAssert scene.isAlive(handle), &"Object handle must be alive; got `{handle}`."
  scene.stored.inks[handle]


func radiusAt*(scene: Scene, handle: int): float =
  ## Read object's drawn radius, in world units, by handle rather than through `Object`.
  ##   Beside `Object.radius` for same reason `inkAt` sits beside `Object.ink`.
  ##   World units rather than pixels, so object shrinks with distance as everything else
  ##   drawn at position does; front-end holds least on-screen size, not this.
  doAssert scene.isAlive(handle), &"Object handle must be alive; got `{handle}`."
  scene.stored.radii[handle]


func bornAt*(scene: Scene, handle: int): float =
  ## Read moment object arrived, by handle rather than through `Object`; see `inkAt`.
  doAssert scene.isAlive(handle), &"Object handle must be alive; got `{handle}`."
  scene.stored.borns[handle]


func orderOf*(scene: Scene, handle: int): uint32 =
  ## Read where object stands in order this scene's objects were created, by handle.
  ##   Comparable only within one scene: counts additions to this arena, says nothing
  ##   about wall-clock time or another scene's ordinals.
  ##   Steps of one undo timeline count as one scene: each restores count beside its
  ##   objects, and edit after undo truncates future that held any ordinal it reuses.
  doAssert scene.isAlive(handle), &"Object handle must be alive; got `{handle}`."
  scene.stored.orders[handle]


func siftDown(scene: Scene; handles: var array[OBJECTS_MAX, int]; root, count: int) =
  ## Sift handle at `root` down until neither child carries later ordinal, over first `count`.
  var parent = root
  while true:
    var child = 2 * parent + 1
    if child >= count: return
    if child + 1 < count and
        scene.stored.orders[handles[child+1]] > scene.stored.orders[handles[child]]:
      inc child
    if scene.stored.orders[handles[parent]] >= scene.stored.orders[handles[child]]: return
    swap(handles[parent], handles[child])
    parent = child


func handlesCreated*(scene: Scene, handles: var array[OBJECTS_MAX, int]): int =
  ## Fill `handles` with every live handle, oldest creation first; report how many were filled.
  ##   Caller's own array rather than `seq`, so no allocation on either backend.
  ##   Heapsort on `orders`, in place, O(n log n).
  ##     Runs per drawer refresh on browser and per edit on desktop, not once per save;
  ##     quadratic sort here was most of desktop frame at capacity; figures in
  ##     `PROVENANCE.md`.
  ##   To `bound`, by handle: no handle above watermark has ever held anything.
  for handle in 0..<scene.bound:
    if not scene.stored.are_alive[handle]: continue
    handles[result] = handle
    inc result
  for root in countdown(result div 2 - 1, 0): siftDown(scene, handles, root, result)
  for last in countdown(result - 1, 1):
    swap(handles[0], handles[last])
    siftDown(scene, handles, 0, last)


func anchorOverrideAt*(scene: Scene, handle: int): Option[Position] =
  ## Read where object's circle should centre about world origin, by handle; see `inkAt`.
  ##   Held about object's anchor and offset here, three sums for object carrying one.
  doAssert scene.isAlive(handle), &"Object handle must be alive; got `{handle}`."
  if scene.stored.anchor_overrides[handle].isNone: return
  overrideAbout(scene.stored.anchor_overrides[handle], scene.stored.anchors[handle], ORIGIN_WORLD)



#[ Searching Objects ]#

const BLANKS_SEARCH = {' ', '\t'}  ## Name characters parting one word of search from next.


func isSearching*(query: openArray[char]): bool =
  ## Report whether `query` holds any word, rather than nothing or blanks alone.
  ##   Blank query narrows nothing, so front-end shows no count and no `select all` for it.
  ##   Reads to terminator or to end, as `isMatchingSearch` does.
  for ch in query:
    if ch == '\0': return false
    if ch notin BLANKS_SEARCH: return true
  false


func isMatchingSearch*(scene: Scene, handle: int, query: openArray[char]): bool =
  ## Report whether object answers `query`: each word of it stands in label or kind word.
  ##   Word matches anywhere, ASCII case folded, so `jup` finds `Jupiter` and `horizon` finds
  ##   every horizon object, whatever it is called.
  ##   Every word must stand, each in either place: `horizon m1` is horizon object whose label
  ##   holds `m1`.
  ##   Blank query answers every object, since list with nothing typed is whole list.
  ##   Reads to terminator or to end, so fixed buffer desktop types into and string page sends
  ##   read same.
  ##   Kind word is described only where label misses word, since it is dearer of two reads.
  ##   Cost: fold is ASCII alone, so non-ASCII byte matches only itself; `é` does not find `É`.

  func lengthOf(text: openArray[char]): int =
    ## Count characters ahead of terminator, or all of them where none stands.
    while result < text.len and text[result] != '\0': inc result

  func isHoldingWord(text, query: openArray[char]; start, stop: int): bool =
    ## Report whether `query[start ..< stop]` stands in `text` ahead of its terminator, folded.
    let
      length_text = lengthOf(text)
      length_word = stop - start
    for at in 0 .. length_text - length_word:
      var offset = 0
      while offset < length_word and
          text[at+offset].toLowerAscii == query[start+offset].toLowerAscii:
        inc offset
      if offset == length_word: return true
    false

  doAssert scene.isAlive(handle), &"Object handle must be alive; got `{handle}`."
  var
    kind: array[WIDTH_KIND_WORD, char]
    is_kind_described = false
    start = 0
  let length_query = lengthOf(query)
  while start < length_query:
    if query[start] in BLANKS_SEARCH:
      inc start
      continue
    var stop = start
    while stop < length_query and query[stop] notin BLANKS_SEARCH: inc stop
    if not isHoldingWord(scene.stored.labels[handle], query, start, stop):
      if not is_kind_described:
        var cursor = 0
        describeKind(scene.geometries[handle], kind, cursor)
        finishChars(kind, cursor)
        is_kind_described = true
      if not isHoldingWord(kind, query, start, stop): return false
    start = stop
  true


func handlesMatching*(
  scene: Scene, query: openArray[char], handles: var array[OBJECTS_MAX, int], kept: openArray[int]
): tuple[count_shown, count_matched: int] =
  ## Fill `handles` with every live handle `query` matches or `kept` names, oldest creation
  ## first; report how many were filled, and how many of those `query` matches.
  ##   `kept` stays whatever query says: selection, and row open for edit, never leave list
  ##   under reader searching past them.
  ##   Kept handle sits in creation order among matches, where it sits without search.
  ##   Count matched is what query alone lists, so front-end can say that nothing matched
  ##   while kept rows still stand.
  ##   Filters `handlesCreated` in place, so order is creation order.
  ##     Marks kept handles once, rather than scanning `kept` per handle: whole selection can
  ##     be kept, and scan per handle costs 25 million comparisons at capacity.
  var is_kept: array[OBJECTS_MAX, bool]
  for handle in kept:
    doAssert handle in 0..<OBJECTS_MAX, &"Kept handle must be in range; got `{handle}`."
    is_kept[handle] = true
  let count = scene.handlesCreated(handles)
  for position in 0..<count:
    let
      handle = handles[position]
      is_matched = scene.isMatchingSearch(handle, query)
    if is_matched: inc result.count_matched
    if is_matched or is_kept[handle]:
      handles[result.count_shown] = handle
      inc result.count_shown



#[ Previewing Construction ]#

func previewApplying*(scene: Scene; operation: Operation; first, second: int): Option[Preview] =
  ## Resolve what applying `operation` to these two handles would build.
  ##   None where it would build nothing worth showing.
  ##     Either handle dead, since picker left open across delete is ordinary.
  ##     Result with no drawable kind, covering wrong grades and pair already lying on
  ##     each other.
  ##   Takes handles rather than multivectors so operands travel with answer.
  ##   Unary operation ignores `second`; pass first handle again, as every commit path does.
  ##   Built from operands as stored, as commit builds it, then read about world origin as
  ##   commit's cache reads it: preview and object built are same bits.
  if not (scene.isAlive(first) and scene.isAlive(second)): return
  let
    m = scene.anchoredAt(first)
    n = scene.anchoredAt(second)
    derived = applyOperation(operation, m, n)
  if kindOf(derived.local).isNone: return
  some(Preview(
    geometry: derived.geometryAbout(ORIGIN_WORLD),
    anchor: overrideAbout(creationAnchor(operation, m, n, derived), derived.anchor, ORIGIN_WORLD),
    operands: some((first, second)),
    radius: RADIUS_OBJECT_DEFAULT,
  ))


func previewStaging*(geometry: Multivector, radius: float): Preview =
  ## Hold open edit session's staged geometry as preview, at session's own radius.
  ##   No anchor and no operands: neither front-end draws that preview about stored point,
  ##   and object it would be framed against is one it replaces; see `Preview`.
  ##   Radius is staged one, or preview of moon under edit was drawn at default and read as
  ##   grey disc three times its size.
  Preview(geometry: geometry, anchor: none(Position), operands: none((int, int)), radius: radius)


func setInk*(scene: var Scene, handle: int, ink: Ink) =
  ## Rewrite object's palette slot, by handle.
  doAssert scene.isAlive(handle), &"Object handle must be alive; got `{handle}`."
  scene.stored.inks[handle] = ink
  scene.markEdited()


func setRadius*(scene: var Scene, handle: int, radius: float) =
  ## Rewrite object's drawn radius, by handle, mirroring `setInk`.
  ##   Bumps `revision` only: radius is not placing input, nothing about where object
  ##   stands changes.
  doAssert scene.isAlive(handle), &"Object handle must be alive; got `{handle}`."
  doAssert radius > 0.0, &"Object radius must be positive; got `{radius}`."
  scene.stored.radii[handle] = radius
  scene.markEdited()


func setVisible*(scene: var Scene, handle: int, is_visible: bool) =
  ## Rewrite object's visibility, by handle, mirroring `setInk`.
  ##   Only writer: `isVisibleAt(...) = visible` accessor silently lands on copied
  ##   primitive under JS backend; see `isVisible`.
  doAssert scene.isAlive(handle), &"Object handle must be alive; got `{handle}`."
  scene.stored.are_visible[handle] = is_visible
  scene.markEdited()


iterator items*(scene: Scene): Object =
  ## Yield each live object, in handle order.
  ##   Walks to `bound`, as sibling `pairs` does; check both when either changes.
  for handle in 0..<scene.bound:
    if scene.stored.are_alive[handle]: yield scene[handle]


iterator pairs*(scene: Scene): (int, Object) =
  ## Yield each live object together with handle it stands at, in handle order.
  ##   Walks to `bound` rather than capacity, so every consumer stops sweeping empty handles
  ##   at once; sibling of `objects`.
  for handle in 0..<scene.bound:
    if scene.stored.are_alive[handle]: yield (handle, scene[handle])


func addObject*(
  scene: var Scene,
  anchored: Anchored,
  label: string,
  ink: Ink,
  now = 0.0,
  anchor_override = none(Position),
  radius: float = RADIUS_OBJECT_DEFAULT,
): int {.discardable.} =
  ## Insert object as anchored into scene at first free handle, visible; report handle used.
  ##   Silently refuses nothing: caller checks `isFull` first, as scene cannot grow.
  ##   `now` is stamped as object's `born` reading.
  ##     Default reads as "born at dawn of time" and never animates.
  ##   `anchor_override` is where plane's circle should centre instead of support, where
  ##   construction fixes that; see `creationAnchor`.
  ##     Held about `anchored.anchor`, as coefficients are.
  ##   `radius` is how large point is drawn, in world units; see `radiusAt`.
  doAssert not scene.isFull,
    &"Scene holds at most {OBJECTS_MAX} objects, raise `--define:visualiser.objects_max`; got " &
    &"`{scene.len}`."
  result = scene.stored.handle_free_first.get
  scene.stored.handle_free_first = scene.stored.next_free[result]
  scene.stored.anchors[result] = anchored.anchor
  scene.stored.locals[result] = anchored.local
  scene.deriveGeometryAt(result)
  toChars(label, scene.stored.labels[result])
  scene.stored.inks[result] = ink
  doAssert radius > 0.0, &"Object radius must be positive; got `{radius}`."
  scene.stored.radii[result] = radius
  scene.stored.are_visible[result] = true
  scene.stored.are_alive[result] = true
  scene.stored.borns[result] = now
  scene.stored.anchor_overrides[result] = anchor_override
  # Stamp arrival relative to everything else, which handle cannot say.
  #   Refilled handle sits wherever free list put it.
  scene.stored.orders[result] = scene.stored.count_created
  inc scene.stored.count_created
  inc scene.stored.count_live
  scene.stored.handle_live_last = max(scene.stored.handle_live_last, result + 1)
  scene.markEdited()
  scene.stored.revisions_placing[result] = scene.stored.count_edits


func addObject*(
  scene: var Scene,
  geometry: Multivector,
  label: string,
  ink: Ink,
  now = 0.0,
  anchor_override = none(Position),
  radius: float = RADIUS_OBJECT_DEFAULT,
): int {.discardable.} =
  ## Insert object standing about world origin, anchored there; report handle used.
  ##   For object reader composes, and caller holding geometry about world origin alone.
  ##   `anchor_override` stands about world origin too; see sibling taking `Anchored`.
  scene.addObject(
    Anchored(anchor: ORIGIN_WORLD, local: geometry), label, ink, now, anchor_override, radius
  )


func removeObject*(scene: var Scene, handle: int) =
  ## Drop object at handle, in constant time: handle returns to free list, nothing moves.
  doAssert scene.isAlive(handle), &"Object handle must be alive; got `{handle}`."
  scene.stored.are_alive[handle] = false
  scene.stored.next_free[handle] = scene.stored.handle_free_first
  scene.stored.handle_free_first = some(handle)
  dec scene.stored.count_live
  scene.markEdited()



#[ Scene Persistence ]#

## Define binary format project invents for itself.
##   Every multi-byte field is little-endian, rule rather than habit.
##     browser scripts writes and reads same file through `DataView`, which demands explicit
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
##   | 4        | Object count, little-endian `uint32`.                          |
##   | per object | Ink (1), visibility (1), label length (1) then that many     |
##   |          |   bytes, one little-endian `float` per basis term about      |
##   |          |   object's anchor, radius as one more little-endian `float`, |
##   |          |   then anchor's x, y and z as three more.                    |
##   |----------|--------------------------------------------------------------|
##
## Each object is written as stored: coefficients about its anchor, and anchor exactly.
##   Pair metre apart far out then reloads metre apart; written about Sol it reloads as one
##   point. Version 8 added anchor.
## Only live objects are written, in order created, whole of what version 3 added.
##   Handle numbers mean nothing once reloaded; sequence carries ordering, so no ordinal is
##   written beside each object.
##   `born` is not written: clock reading meaningless across runs.
##     Loaded object is stamped by `bornReplaying`, so file plays back own construction.
##   Label is written as exactly as many bytes as it holds, not padded to `LABEL_MAX`.
## Every version ever written is still readable.
##   Scene file is reader's own work; build refusing it has destroyed it.
##
##   |---------|-------------------------------------------------------------------|
##   | Version | Read as                                                           |
##   |---------|-------------------------------------------------------------------|
##   | 8       | Exactly.                                                          |
##   | 7       | Exactly, with every object anchored at world origin, which its    |
##   |         |   coefficients stand about; see `upgradedFrom7`.                  |
##   | 6       | Exactly, except one byte follows each object's radius, saying     |
##   |         |   whether it shone; read and dropped; see `upgradedFrom6`.        |
##   | 5       | As 6, and palette had one more structural slot, `Algebra`, at     |
##   |         |   ordinal 7; every hue past it moves one down; see                |
##   |         |   `upgradedFrom5`.                                                |
##   | 4       | Exactly; see `upgradedFrom4`.                                     |
##   | 3       | Exactly, except every object is drawn at `RADIUS_OBJECT_DEFAULT`, size |
##   |         |   version 3 drew everything at; see `upgradedFrom3`.              |
##   | 2       | Exactly, except object sequence is handle order, so scene whose       |
##   |         |   objects were removed and re-added replays out of build order.   |
##   |         |   Byte-identical to version 3 but for version itself.             |
##   | 1       | Geometry, label and visibility exactly; colours one hue along     |
##   |         |   for three that were retired; see `upgradedFrom1`.               |
##   |---------|-------------------------------------------------------------------|
##
## Old file is upgraded to today's shape, never read in old build's dialect.
##   Reading is written once, against `VERSION_SCENE`.
##   Everything past version did differently lives in one `upgradedFrom<n>` per boundary,
##   and `objectUpgraded` walks objects up chain one step at time.
##   Reader branching on version at each field spreads every past decision across whole
##   reader, and version that breaks is one nobody has file of to notice.
##   Adding version means adding one func.

const
  MAGIC_SCENE* = "RGAS"  ## Open every `.rgascene` file with these four bytes.
  VERSION_SCENE* = 8'u8
    ## Stamp format version this build writes.
    ##   Every version down to `VERSION_SCENE_LEAST` is still read; see table above.
    ##   Version 2 moved every stored ink ordinal, when `Ink` gained reserved `Invalid`
    ##   handle and lost three categorical ones.
    ##   Version 3 began writing objects in creation order.
    ##     Bytes are shaped identically, so this number alone says whether sequence is
    ##     build order or handle order.
    ##   Version 4 appended one float64 radius to each object, after its geometry.
    ##   Version 5 appended one shines byte to each object, after its radius.
    ##   Version 7 dropped it: nothing shines, every point is shaded from world's up.
    ##   Version 8 appended each object's anchor after its radius, and wrote coefficients
    ##   about it.
  VERSION_SCENE_RADIUS* = 4'u8
    ## Record first version whose objects carry radius; see `isCarryingRadius`.
  VERSION_SCENE_SHINE* = 5'u8
  VERSION_SCENE_SHINE_LAST* = 6'u8
    ## Record first and last version whose objects carry shines byte; see `isCarryingShine`.
  VERSION_SCENE_ANCHOR* = 8'u8
    ## Record first version whose objects carry anchor; see `isCarryingAnchor`.
  VERSION_SCENE_LEAST* = 1'u8
    ## Bound oldest format version this build still reads.
    ##   One, and it stays one: version floor that rises throws reader's work away.
    ##   Reading old version costs mapping func and suite case; refusing costs scene.

func inkCycled*(index: int): Ink = inkCategorical(index mod COUNT_INK_CATEGORICAL)
  ## Choose palette slot for object at given position, cycling categorical slots.
  ##   Same run colour picker offers, so nothing cycles to colour user could not have
  ##   chosen.


func inkNext*(scene: Scene): Ink = inkCycled(scene.stored.index_ink)
  ## Read hue next object built will wear, without taking it.
  ##   What drag in flight is drawn in, so band, comet and preview show colour thing being
  ##   built will be; see `interaction.inkOfDrag`.
  ##   Peeking and taking are separate because previewing happens every frame.


func takeInk*(scene: var Scene): Ink =
  ## Read hue for object being built, and step cycle past it.
  result = scene.inkNext
  inc scene.stored.index_ink


func skipInk*(scene: var Scene) =
  ## Step cycle without building anything.
  ##   For construction gesture that ended in no object: reader was shown colour for whole
  ##   drag, and offering same colour again reads as gesture not registering.
  inc scene.stored.index_ink

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


func isSceneVersionReadable*(version: uint8): bool =
  ## Report whether this build can read scene file stamped with this version.
  version >= VERSION_SCENE_LEAST and version <= VERSION_SCENE


func isCarryingRadius*(version: uint8): bool = version >= VERSION_SCENE_RADIUS
  ## Report whether file of this version carries radius after each object's geometry.
  ##   Both readers ask this rather than compare against literal; see `nimSceneHasRadius`.


func isCarryingShine*(version: uint8): bool =
  ## Report whether file of this version carries shines byte after each object's radius.
  ##   Reader skips it: no build reads it into anything since version 7.
  ##   Asked as `isCarryingRadius` is; see `nimSceneHasShine`.
  version >= VERSION_SCENE_SHINE and version <= VERSION_SCENE_SHINE_LAST


func isCarryingAnchor*(version: uint8): bool = version >= VERSION_SCENE_ANCHOR
  ## Report whether file of this version carries anchor after each object's radius.
  ##   Asked as `isCarryingRadius` is; see `nimSceneHasAnchor`.


const ORDINAL_INK_ALGEBRA_V5 = 7
  ## Record structural slot `Algebra`, debug layer's hue, held in palette up to version 5.
  ##   Sat after `Outline` and before `Invalid`, so every handle past it is one down today.
  ##   Recorded as number because enum entry it indexes no longer exists.


func upgradedFrom1(saved: ObjectSaved): Option[ObjectSaved] =
  ## Carry one object from what version 1 meant to what version 2 means.
  ##   None where version 1 could not have written it.
  ##   Only palette moved: version 1's hues began earlier and ran three longer.
  ##     Seven structural slots untouched, five surviving hues land on today's first five,
  ##     three retired ones fold onto hues by same cycle `inkCycled` walks.
  ##   One file this gets wrong is browser's own, which stamped version 1 onto version-2
  ##   content for while; nothing in bytes tells it apart.
  ##     Its colours come back one hue along; saving restamps it.
  ##     Treating version 1 as 2 would refuse genuine version-1 file whose `Magenta` and
  ##     `Cerise` fall past palette.
  if saved.ink_ordinal < 0 or saved.ink_ordinal > ORDINAL_INK_HIGH_V1: return none(ObjectSaved)
  var carried = saved
  if carried.ink_ordinal >= ORDINAL_INK_CATEGORICAL_V1:
    # Land in version 2's palette, not today's: hues there sat one past `Algebra`.
    #   `upgradedFrom5` takes them down, as it does for every file of versions 2 to 5.
    carried.ink_ordinal =
      ord(inkCycled(carried.ink_ordinal - ORDINAL_INK_CATEGORICAL_V1)) + 1
  some(carried)


func upgradedFrom2(saved: ObjectSaved): Option[ObjectSaved] = some(saved)
  ## Carry one object from what version 2 meant to what version 3 means, which is nothing.
  ##   Version 3 changed only what sequence promises, and object alone carries no sequence.
  ##     Version-2 file's order is taken as creation order, closest thing it has.
  ##   Kept as explicit step so chain has one entry per boundary.


func upgradedFrom3(saved: ObjectSaved): Option[ObjectSaved] =
  ## Carry one object from what version 3 meant to what version 4 means.
  ##   Version 3 wrote no radius, and drew every point at one fixed pixel size.
  ##     Reader fills `RADIUS_OBJECT_DEFAULT`, that size at opening camera, so old scene
  ##     opens looking as it was saved.
  var carried = saved
  carried.radius = RADIUS_OBJECT_DEFAULT
  some(carried)


func upgradedFrom4(saved: ObjectSaved): Option[ObjectSaved] = some(saved)
  ## Carry one object from what version 4 meant to what version 5 means, which is nothing.
  ##   Version 5 added byte saying whether point shone, which no build reads any more.
  ##   Kept as explicit step so chain has one entry per boundary.


func upgradedFrom5(saved: ObjectSaved): Option[ObjectSaved] =
  ## Carry one object from what version 5 meant to what version 6 means.
  ##   Version 6 dropped `Algebra` from palette; hues past it move one down.
  ##   None for object wearing it: structural slot no build ever assigned to object, so
  ##   byte saying so is corrupt, refused as every other unwritable byte is.
  if saved.ink_ordinal == ORDINAL_INK_ALGEBRA_V5: return none(ObjectSaved)
  var carried = saved
  if carried.ink_ordinal > ORDINAL_INK_ALGEBRA_V5: dec carried.ink_ordinal
  some(carried)


func upgradedFrom6(saved: ObjectSaved): Option[ObjectSaved] = some(saved)
  ## Carry one object from what version 6 meant to what version 7 means, which is nothing.
  ##   Version 7 dropped shines byte; reader skipped it before this step, and object
  ##   carries nothing from it.


func upgradedFrom7(saved: ObjectSaved): Option[ObjectSaved] =
  ## Carry one object from what version 7 meant to what version 8 means.
  ##   Version 7 wrote no anchor, and every coefficient about world origin, where Sol stands.
  ##     Reader fills world origin, so object stands where it was saved, to bit.
  var carried = saved
  carried.anchor = ORIGIN_WORLD
  some(carried)


func objectUpgraded*(saved: ObjectSaved, version: uint8): Option[ObjectSaved] =
  ## Carry object read from file of `version` up to shape this build works in.
  ##   One boundary at time; none where no version could have written it.
  ##   On success every field is at `VERSION_SCENE`'s meaning, so caller may take
  ##   `Ink(ink_ordinal)` without further check.
  ##     Last guard here buys that, checked once at end.
  if not isSceneVersionReadable(version): return none(ObjectSaved)
  var carried = saved
  for boundary in version..<VERSION_SCENE:
    let stepped =
      case boundary
      of 1'u8: carried.upgradedFrom1
      of 2'u8: carried.upgradedFrom2
      of 3'u8: carried.upgradedFrom3
      of 4'u8: carried.upgradedFrom4
      of 5'u8: carried.upgradedFrom5
      of 6'u8: carried.upgradedFrom6
      of 7'u8: carried.upgradedFrom7
      else: none(ObjectSaved)  # Unreachable: `isSceneVersionReadable` bounds walk above.
    if stepped.isNone: return none(ObjectSaved)
    carried = stepped.get
  if carried.ink_ordinal notin ord(Ink.low)..ord(Ink.high): return none(ObjectSaved)
  # Refuse radius no build could have written, as palette slot is refused above.
  #   Zero or negative would draw nothing and trip `addObject`; NaN compares false to both.
  if not (carried.radius > 0.0): return none(ObjectSaved)
  # Refuse anchor no build could have written: place every coefficient is slid by.
  #   Infinite or NaN would slide object to NaN, which draws nothing and frames nothing.
  for coordinate in [carried.anchor.x, carried.anchor.y, carried.anchor.z]:
    if coordinate.classify in {fcInf, fcNan, fcNegInf}: return none(ObjectSaved)
  some(carried)


const
  SECONDS_REPLAY_STEP* = 0.12
    ## Space one loaded object's appearance from next by this beat.
    ##   Shorter than `tessellate.ANIMATION_SECONDS`, so each object is still growing as
    ##   next arrives: replay reads as one construction unfolding.
  SECONDS_REPLAY_WHOLE* = 2.5
    ## Bound how long whole replay may take, however many objects arrive.
    ##   Full `OBJECTS_MAX` scene at full beat would take many times longer; beat shortens
    ##   instead, keeping order legible while bounding wait.


func bornReplaying*(index, count: int; now: float): float =
  ## Stamp `index`-th of `count` objects arriving together, one after another from `now`.
  ##   One rule both loaders use, i.e. desktop's `loadScene` and browser's
  ##   `bridge.nimSceneAddRaw`, because beat computed twice drifts.
  ##   `count` is whole arrival, so beat can be shortened to fit cap.
  ##     Caller not knowing whole passes own index plus one and gets unbounded beat.
  let step =
    if count <= 1: SECONDS_REPLAY_STEP
    else: min(SECONDS_REPLAY_STEP, SECONDS_REPLAY_WHOLE / float(count - 1))
  now + float(index) * step


func replayFrom*(scene: var Scene, now: float) =
  ## Stamp every live object to arrive one after another from `now`, oldest creation first.
  ##   Scene assembled at once then plays back as construction it is.
  ##   For arrivals reader did not build and is about to be shown whole, i.e. opening
  ##   scene and demo preset; scene built by hand never wants this.
  ##   `loadScene` and `nimSceneAddRaw` stamp as they add instead; this is same rule
  ##   applied after fact.
  var handles: array[OBJECTS_MAX, int]
  let count = scene.handlesCreated(handles)
  for position in 0..<count:
    scene.stored.borns[handles[position]] = bornReplaying(position, count, now)
  scene.markEdited()


## Keep constants above outside desktop-only guard below, exported.
##   They describe format rather than file handling: browser build gets them via
##   `bridge.nimSceneMagic`/`nimSceneVersion` rather than literals of own.
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
    ## Write every live object to `path`, in format documented above; report outcome.
    if len(path) == 0: return "Save path is empty; nothing written."
    let file = open(path, fmWrite)
    defer: file.close

    discard file.writeChars(MAGIC_SCENE, 0, len(MAGIC_SCENE))
    file.write char(VERSION_SCENE)
    file.write char(ord(Basis.high) + 1)
    file.writeLittle uint32(scene.len)

    # Write in creation order, whole of what sequence means from version 3 on.
    var handles: array[OBJECTS_MAX, int]
    let count = scene.handlesCreated(handles)
    for position in 0..<count:
      let
        handle = handles[position]
        one = scene[handle]
      file.write char(ord(one.ink))
      file.write char(ord(one.isVisible))
      let
        text = one.label.toText
        anchored = scene.anchoredAt(handle)
      file.write char(len(text))
      discard file.writeChars(text, 0, len(text))
      for b in Basis: file.writeLittle(anchored.local[b])
      file.writeLittle(one.radius)
      for coordinate in [anchored.anchor.x, anchored.anchor.y, anchored.anchor.z]:
        file.writeLittle(coordinate)

    &"Saved {scene.len} object(s) to `{path}`."


  proc loadScene*(scene: var Scene, path: string, now = 0.0): string =
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
    if file.readChars(version_byte) != 1 or not isSceneVersionReadable(uint8(version_byte[0])):
      return &"`{path}` is a scene file of a version this build cannot read."
    let version = uint8(version_byte[0])

    let basis_count_here = ord(Basis.high) + 1
    var basis_count: array[1, char]
    if file.readChars(basis_count) != 1 or int(uint8(basis_count[0])) != basis_count_here:
      return &"`{path}` was saved under a different PGA dimension or metric; " &
          &"this build reads {basis_count_here}-term multivectors."

    var count: uint32
    if not file.readLittle(count):
      return &"`{path}` is truncated; no object count."
    if int(count) > OBJECTS_MAX:
      return &"`{path}` holds {count} objects, more than this build's {OBJECTS_MAX}-object " &
          "capacity; raise `--define:visualiser.objects_max`."

    var staging = initScene()
    for index in 0..<int(count):
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
      var radius = RADIUS_OBJECT_DEFAULT
      if isCarryingRadius(version) and not file.readLittle(radius):
        return &"`{path}` is truncated partway through object {index}'s radius."

      # Skip shines byte where file has one; nothing reads it since version 7.
      if isCarryingShine(version):
        var shine_byte: array[1, char]
        if file.readChars(shine_byte) != 1:
          return &"`{path}` is truncated partway through object {index}'s shine."

      # Read anchor only where file has one; earlier versions take it from upgrade.
      var anchor = ORIGIN_WORLD
      if isCarryingAnchor(version):
        let is_read =
          file.readLittle(anchor.x) and file.readLittle(anchor.y) and file.readLittle(anchor.z)
        if not is_read: return &"`{path}` is truncated partway through object {index}'s anchor."

      # Read at file's version, then carry up to this build's.
      #   Every field below means what `VERSION_SCENE` says.
      let carried = objectUpgraded(
        ObjectSaved(
          ink_ordinal: int(uint8(ink_byte[0])),
          is_visible: uint8(visible_byte[0]) != 0,
          label: label,
          geometry: geometry,
          radius: radius,
          anchor: anchor,
        ),
        version,
      )
      if carried.isNone:
        return &"`{path}` names an unknown palette slot, radius or anchor for object {index}."

      # Add in file order, so staging scene's ordinals come out as file's sequence.
      let handle = staging.addObject(
        Anchored(anchor: carried.get.anchor, local: carried.get.geometry),
        carried.get.label,
        Ink(carried.get.ink_ordinal),
        bornReplaying(index, int(count), now),
        radius = carried.get.radius,
      )
      staging.setVisible(handle, carried.get.is_visible)

    # Carry palette on past what was loaded.
    #   Next object built then does not repeat first object's hue.
    #   Not stored in file: count places cycle.
    staging.stored.index_ink = int(count)
    scene = staging
    &"Loaded {count} object(s) from `{path}`."


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
  if LUT_ARITY_BY_OPERATION[operation] == Arity.One: memory.unary = operation
  else: memory.binary = operation
