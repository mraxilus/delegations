## Run `Scene` suite: one module of shared suite, which `../suites.nim` imports in order.

import ./fixtures


suite "Scene":
  test "the startup scene gives every seed point a colour of its own":
    # Four points wearing one hue say they are one kind of thing, which is opposite of.
    #   what categorical palette is for; hand-added object takes next hue, so these
    #   should too. `ground` and `o` keep hues reader learns to find them by.
    var scene = initScene()
    constructSeeds(scene)
    var inks: seq[Ink]
    for handle in 0 ..< scene.len:
      case toText(scene.labelAt(handle))
      of "ground": check scene.inkAt(handle) == INK_SEED_GROUND
      of "o": check scene.inkAt(handle) == INK_SEED_ORIGIN
      else: inks.add(scene.inkAt(handle))
    check inks.len == 3
    for i in 0 ..< inks.len:
      check inks[i] notin [INK_SEED_GROUND, INK_SEED_ORIGIN]
      for j in i + 1 ..< inks.len: check inks[i] != inks[j]


  test "objects are held in order added":
    var scene = initScene()
    for i in 0 ..< 5:
      scene.addObject(POINTS[i], "p" & $i, inkCycled(i))
    check scene.len == 5
    var count_seen = 0
    for one in scene:
      check one.geometry =~ POINTS[count_seen]
      check one.isVisible
      inc count_seen
    check count_seen == 5


  test "removeObject drops one handle without moving any other object":
    var scene = initScene()
    for i in 0 ..< 5:
      scene.addObject(POINTS[i], "p" & $i, inkCycled(i))
    scene.removeObject(2)
    check scene.len == 4
    check not scene.isAlive(2)
    for handle in [0, 1, 3, 4]:
      check scene.isAlive(handle)
      check scene[handle].geometry =~ POINTS[handle]


  test "freed handle is reused by the next addObject, most recently freed first":
    var scene = initScene()
    for i in 0 ..< 5:
      scene.addObject(POINTS[i], "p" & $i, inkCycled(i))
    scene.removeObject(2)
    scene.removeObject(0)
    check scene.addObject(POINTS[5 mod SAMPLES], "p5", Ink.Rose) == 0
    check scene.addObject(POINTS[6 mod SAMPLES], "p6", Ink.Rose) == 2


  test "scene drains to empty regardless of removal order":
    var scene = initScene()
    for i in 0 ..< 5:
      scene.addObject(POINTS[i], "p" & $i, inkCycled(i))
    for handle in [2, 0, 4, 1, 3]:
      scene.removeObject(handle)
    check scene.len == 0
    check not scene.isFull


  test "isAlive rejects a removed handle and any handle out of range":
    var scene = initScene()
    discard scene.addObject(POINTS[0], "a", Ink.Rose)
    check scene.isAlive(0)
    scene.removeObject(0)
    check not scene.isAlive(0)
    check not scene.isAlive(-1)
    check not scene.isAlive(OBJECTS_MAX)


  test "scene fills to capacity and reports it":
    var scene = initScene()
    for i in 0 ..< OBJECTS_MAX:
      check not scene.isFull
      scene.addObject(POINTS[i mod SAMPLES], "p", Ink.Rose)
    check scene.isFull
    check scene.len == OBJECTS_MAX


  test "unary operations ignore their second operand":
    for operation in Operation:
      if lut_operation_to_arity[operation] != Arity.One: continue
      for i in 0 ..< SAMPLES:
        let (m, n, o) = (POINTS[i], LINES[i], PLANES[i])
        check applyOperation(operation, m, n) =~ applyOperation(operation, m, o)


  test "every operation names itself and is offered once":
    var seen: array[Operation, int]
    for operation in Operation:
      check len(lut_operation_to_notation[operation]) > 0
      inc seen[operation]
    for operation in Operation:
      check seen[operation] == 1
    check COUNT_OPERATION == ord(Operation.high) + 1


  test "join and meet recover the geometry they are named for":
    for i in 0 ..< SAMPLES:
      let
        j = (i + 1) mod SAMPLES
        line = applyOperation(Operation.Wedge, POINTS[i], POINTS[j])
        plane = applyOperation(Operation.Wedge, line, POINTS[(i + 2) mod SAMPLES])
        crossed = applyOperation(Operation.WedgeAnti, plane, PLANES[(i + 7) mod SAMPLES])
      check kindOf(line) == some(Kind.Line)
      check kindOf(plane) == some(Kind.Plane)
      check kindOf(crossed) == some(Kind.Line)
      # Both seed points must lie on line joining them.
      check POINTS[i] ∧ line =~ 0
      check POINTS[j] ∧ line =~ 0


  test "meet finds where a line crosses a plane even far outside its own drawn disc":
    # `mesh.addPlane`'s disc is only rendering choice -- plane it represents is.
    #   same infinite object algebraically either way, and `WedgeAnti` (meet) reads
    #   straight off that Multivector, never consulting `EXTENT_PLANE_F` or anything
    #   drawn. Crossing plane three disc-radii out from its own drawn centre, well
    #   outside circle `mesh.addPlane` actually fills, exercises that directly.
    for i in 0 ..< SAMPLES:
      let
        plane = PLANES[i]
        anchor = positionAnchor(plane)
        axes = frame(plane)
      check anchor.isSome
      check axes.isSome
      let
        far_on_plane = anchor.get + (3.0*EXTENT_PLANE_F)*axes.get.axis_first
        off_plane = toMultivector(far_on_plane + axes.get.normal)
        line = toMultivector(far_on_plane) ∧ off_plane
        crossing = applyOperation(Operation.WedgeAnti, line, plane)
      check kindOf(crossing) == some(Kind.Point)
      let place = position(crossing)
      check place.isSome
      check place.get =~ far_on_plane


  test "orthogonal projection lands on the object projected onto":
    for i in 0 ..< SAMPLES:
      # Point must not be one of three that built plane, or it lies on it already.
      let
        plane = PLANES[i]
        point = POINTS[(i + 9) mod SAMPLES]
        projected = applyOperation(Operation.ProjectOrthogonal, point, plane)
      check kindOf(projected) == some(Kind.Point)
      let place = position(projected)
      check place.isSome
      check toMultivector(place.get) ∧ plane =~ 0


  test "creation anchor for a plane wedged from a line and a point sits at their midpoint":
    for i in 0 ..< SAMPLES:
      let
        line = LINES[i]
        point = POINTS[(i + 5) mod SAMPLES]
        plane = applyOperation(Operation.Wedge, line, point)
        anchor = creationAnchor(Operation.Wedge, line, point, plane)
        anchor_swapped = creationAnchor(Operation.Wedge, point, line, plane)
        expected = position(add(unitize(point), unitize(projectOrthogonal(point, line))))
      check anchor.isSome
      check anchor_swapped.isSome
      check expected.isSome
      check anchor.get =~ expected.get
      check anchor_swapped.get =~ expected.get


  test "creation anchor for a perpendicular plane sits where its line pierces it":
    for i in 0 ..< SAMPLES:
      let
        point = POINTS[i]
        line = LINES[(i + 11) mod SAMPLES]
        plane = applyOperation(Operation.ExpandWeight, point, line)
        anchor = creationAnchor(Operation.ExpandWeight, point, line, plane)
        anchor_swapped = creationAnchor(Operation.ExpandWeight, line, point, plane)
        expected = position(wedgeAnti(line, plane))
      check anchor.isSome
      check anchor_swapped.isSome
      check expected.isSome
      check anchor.get =~ expected.get
      check anchor_swapped.get =~ expected.get


  test "creation anchor is none for operations or shapes it does not special-case":
    check creationAnchor(Operation.WedgeAnti, PLANES[0], PLANES[1], LINES[0]).isNone
    check creationAnchor(Operation.Wedge, POINTS[0], POINTS[1], LINES[0]).isNone
    check creationAnchor(Operation.Wedge, PLANES[0], POINTS[0], PLANES[0]).isNone
    check creationAnchor(Operation.ProjectOrthogonal, POINTS[0], PLANES[0], POINTS[0]).isNone


  test "notation substitutes real operand names for the table's own bold placeholders":
    # One table serves both render paths, so this is also what browser's own.
    #   `nimOperationNotation` hands out -- there is no second table to keep in step.
    check notationSubstituted(Operation.Wedge, "a", "b") == "a ∧ b"
    check notationSubstituted(Operation.Attitude, "L", "unused") == "L⊖"
    # English name after symbols is full of ordinary m's and n's and must never.
    #   reach label; only symbolic prefix is substituted.
    check notationSubstituted(Operation.DualWeight, "g", "unused") == "g☆"
    check "weight dual" notin notationSubstituted(Operation.DualWeight, "g", "unused")
    # `𝐧` appears twice in projections, and both occurrences take operand name.
    check notationSubstituted(Operation.ProjectCentral, "a", "G") == "G ∨ (a ∧ G★)"
    # Operand whose own name contains placeholder letters survives untouched.
    check notationSubstituted(Operation.Wedge, "mn", "nm") == "mn ∧ nm"


  test "a composite operand is parenthesised where the formula needs it, flat where not":
    # Bug this guards: derived name was substituted bare, so meet of `a ∧ b` with `c` read
    #   `a ∧ b ∨ c`, and expansion of `p` by `L ∨ G` read `p ∧ L ∨ G★`, naming other objects.
    # Chain of one associative operator stays flat; any other binding wraps.
    check notationSubstituted(Operation.Wedge, "a ∧ b", "c") == "a ∧ b ∧ c"
    check notationSubstituted(Operation.Wedge, "a", "b ∧ c") == "a ∧ b ∧ c"
    check notationSubstituted(Operation.WedgeAnti, "a ∧ b", "c") == "(a ∧ b) ∨ c"
    check notationSubstituted(Operation.Wedge, "L ∨ G", "p") == "(L ∨ G) ∧ p"
    check notationSubstituted(Operation.WedgeAnti, "P ∨ Q", "R ∨ S") == "P ∨ Q ∨ R ∨ S"
    check notationSubstituted(Operation.Add, "a + b", "c") == "a + b + c"
    # Subtraction is not associative: both sides wrap.
    check notationSubstituted(Operation.Subtract, "a - b", "c") == "(a - b) - c"
    check notationSubstituted(Operation.Subtract, "a", "b - c") == "a - (b - c)"
    # Postfix binds tighter than anything: composite under it always wraps.
    check notationSubstituted(Operation.ExpandBulk, "p", "L ∨ G") == "p ∧ (L ∨ G)★"
    check notationSubstituted(Operation.Attitude, "a ∧ b", "unused") == "(a ∧ b)⊖"
    check notationSubstituted(Operation.DualWeight, "a + b", "unused") == "(a + b)☆"
    # Negation wraps composite, and negated name wraps under anything.
    check notationSubstituted(Operation.Negate, "a + b", "unused") == "−(a + b)"
    check notationSubstituted(Operation.Negate, "a", "unused") == "−a"
    check notationSubstituted(Operation.DualBulk, "−a", "unused") == "(−a)★"
    check notationSubstituted(Operation.Wedge, "−a", "b") == "(−a) ∧ b"
    # Projection binds `𝐧` twice, once by meet and once by star.
    check notationSubstituted(Operation.ProjectCentral, "p ∧ q", "a ∨ b") ==
      "a ∨ b ∨ (p ∧ q ∧ (a ∨ b)★)"
    check notationSubstituted(Operation.ProjectOrthogonal, "p", "G") == "G ∨ (p ∧ G☆)"
    # Postfix name is atomic, and name already wrapped is not wrapped again.
    check notationSubstituted(Operation.Wedge, "L⊖", "p") == "L⊖ ∧ p"
    check notationSubstituted(Operation.WedgeAnti, "(a ∧ b)", "c") == "(a ∧ b) ∨ c"
    check notationSubstituted(Operation.WedgeAnti, "(a ∧ b) ∧ (c ∧ d)", "e") ==
      "((a ∧ b) ∧ (c ∧ d)) ∨ e"
    # Name with spaces but no operator is atomic: reader's own label stays bare.
    check notationSubstituted(Operation.Wedge, "my point", "q") == "my point ∧ q"


  test "labels truncate and stay terminated":
    var storage: Label
    toChars("short", storage)
    check toText(storage) == "short"
    toChars('x'.repeat(LABEL_MAX*2), storage)
    check len(toText(storage)) <= LABEL_MAX - 1
    check toText(storage).endsWith("…") # Says it was shortened rather than reading whole.


  test "a truncated label never splits a character, whatever the buffer lands on":
    # Bug this pins: bytes were copied until buffer filled, so three-byte.
    #   operator could be cut in half. Invalid tail reached browser as literal
    #   `%e2%8a` where glyph belonged -- Nim's JS backend percent-escapes what it cannot
    #   decode -- which is how it was found, in screenshot of objects list.
    #   Every offset is walked, so whichever byte of operator cut lands on is
    #   covered rather than whichever one this test's own text happens to produce.
    for pad in 0 .. 6:
      var storage: Label
      let text = 'x'.repeat(pad) & "∧∨⊖".repeat(LABEL_MAX)
      toChars(text, storage)
      let kept = toText(storage)
      check kept.validateUtf8 == -1 # -1 is "valid throughout"; any other value is index.
      check kept.endsWith("…")
      check len(kept) <= LABEL_MAX - 1

    # Text that fits exactly is left alone: no mark, nothing dropped.
    var storage: Label
    let exact = "∧".repeat((LABEL_MAX - 1) div 3)
    toChars(exact, storage)
    check toText(storage) == exact


  # Every magnitude two front-ends show has to read same in both, and values.
  #   most likely to break that are exact binary ties -- coefficient of 10.125 or 12345,
  #   which user can simply type. C rounds tie to even and JavaScript rounds it away
  #   from zero, so formatter that delegates to runtime disagrees with itself across
  #   backends. Measured before rule was stated here: 330 of 7000 values differed.
  const MAGNITUDES = [
    0.0, 1.0, -1.0, 3.5, -2.0, 0.25, 1664.0, 1234567.0, 0.00012345, 1e-7, 1e7,
    99999.0, 0.099999, 123.456, -0.0001, 1e-5, 9.9999e-5, 1000.0, 999.95, 6.02e23,
    10.125, 12345.0, 0.125, 1.0005, 9999.6, -10.125, 2.5, 0.5, 1.5, 1012.5,
  ]

  test "magnitudes read the same whichever backend formats them":
    # Pinned as text rather than against reference backend supplies, because that is.
    #   exactly what differs. These are what C's own `%.4g` writes, verified against it.
    check formatMagnitude(10.125) == "10.12"   # Tie, rounds to even.
    check formatMagnitude(-10.125) == "-10.12"
    check formatMagnitude(12345.0) == "1.234e+04"
    check formatMagnitude(0.125) == "0.125"
    check formatMagnitude(2.5) == "2.5"
    check formatMagnitude(1012.5) == "1012"    # Tie at fourth digit, rounds to even.
    check formatMagnitude(9999.6) == "1e+04"   # Rounding carries into another digit.
    check formatMagnitude(0.0) == "0"
    check formatMagnitude(-0.0) == "0"         # Sign on nothing reads as bug.

  test "magnitudesAgree: the browser's own formatter answers what C's does":
    # One rule, two mechanisms: desktop reaches C's `%.4g` through `snprintf`, which.
    #   browser build has no runtime for, so `formatMagnitude` states same rule in
    #   plain Nim. Only this test holds two together -- run it before changing either.
    #   Skipped on JS backend, which has no `snprintf` to compare against; test
    #   above is what runs there, and it pins text rather than second mechanism.
    when not defined(js):
      for value in MAGNITUDES:
        if value == 0.0: continue  # C signs zero, this does not; pinned above.
        var
          storage: array[64, char]
          cursor = 0
        appendMagnitude(storage, cursor, value)
        check formatMagnitude(value) == toText(storage)


  test "multivectors print every term they carry, and nothing else":
    # Significant digits, not fixed decimal places: whole number reads as one, and.
    #   coefficient keeps only digits it actually carries. Basis elements are named
    #   as library's own `$` names them, which is what keeps two GUIs 1-1.
    check formatMultivectorString(initElement(Basis.scalar, 0.0)) == "0 𝟏"
    check formatMultivectorString(toMultivector(Position(x: 2, y: 0, z: -3))) ==
      "2 𝐞₁ - 3 𝐞₃ + 1 𝐞₄"
    check formatMultivectorString(toMultivector(Position(x: 3.5, y: 0, z: 0))) ==
      "3.5 𝐞₁ + 1 𝐞₄"
    check formatMultivectorString(initElement(Basis.scalar, 0.00012345)) == "0.0001234 𝟏"
    # Match every basis name against what library writes for that element on its own.
    #   Never trusted to table transcribed by hand.
    for b in Basis:
      let named = ($initElement(b, 1.0)).strip()
      check lut_basis_to_name[b] == named
    for i in 0 ..< SAMPLES:
      check kindText(POINTS[i]) == "point"
      check kindText(LINES[i]) == "line"
      check kindText(PLANES[i]) == "plane"
      # Attitude of line is its direction, which is point lying in horizon.
      check kindText(⊖ LINES[i]) == "horizon point"
    check kindText(1.0 + POINTS[0]) == "mixed grade, nothing to draw"


  test "handlesCreated walks creation order, whatever order the handles fell in":
    # Arena reuses most recently freed handle, so handle order stops being creation.
    #   order moment anything is removed. This is what save path walks, and what
    #   `born`-sorted list could not answer: two objects added in one frame share reading,
    #   and replayed object's own born is stamped into future.
    var scene = initScene()
    for i in 0 ..< 6:
      discard scene.addObject(POINTS[i], "p" & $i, inkCycled(i))
    scene.removeObject(4)
    scene.removeObject(1)
    let handle_first = scene.addObject(POINTS[6], "seventh", Ink.Rose)  # lands in handle 1
    let handle_second = scene.addObject(POINTS[7], "eighth", Ink.Rose)  # lands in handle 4
    check handle_first == 1
    check handle_second == 4

    var handles: array[OBJECTS_MAX, int]
    let count = scene.handlesCreated(handles)
    check count == scene.len
    var labels: seq[string]
    for position in 0 ..< count:
      labels.add(toText(scene.labelAt(handles[position])))
    check labels == @["p0", "p2", "p3", "p5", "seventh", "eighth"]
    # Which is ordinals in order, and every one of them distinct.
    for position in 1 ..< count:
      check scene.orderOf(handles[position]) > scene.orderOf(handles[position - 1])

    # Empty scene fills nothing rather than reporting handle that is not there.
    let empty = initScene()
    check empty.handlesCreated(handles) == 0


  test "handlesCreated orders a scrambled arena of hundreds, not just a handful":
    # Heapsort has cases insertion sort never exercised: many objects, handles freed and.
    #   refilled throughout, so ordinals sit nowhere near their handles.
    var scene = initScene()
    let count_wanted = min(OBJECTS_MAX, 300)
    for i in 0 ..< count_wanted:
      discard scene.addObject(POINTS[i mod SAMPLES], "p", Ink.Rose)
    var rng = initRand(7)
    for _ in 0 ..< count_wanted div 2:
      let handle = rng.rand(count_wanted - 1)
      if scene.isAlive(handle): scene.removeObject(handle)
    for i in 0 ..< count_wanted div 3:
      discard scene.addObject(POINTS[i mod SAMPLES], "r", Ink.Rose)
    var handles: array[OBJECTS_MAX, int]
    let count = scene.handlesCreated(handles)
    check count == scene.len
    for position in 1 ..< count:
      check scene.orderOf(handles[position]) > scene.orderOf(handles[position - 1])


  test "revisionPlacingAt stamps the handle an edit touched, and every handle after a restore":
    # Front-end re-places only handles stamped past what it holds, so stamp must move for.
    #   exactly handles whose placing inputs did.
    var scene = initScene()
    for i in 0 ..< 4: discard scene.addObject(POINTS[i], "p" & $i, inkCycled(i))
    let revision_built = scene.revision
    for handle in 0 ..< 4: check scene.revisionPlacingAt(handle) <= revision_built
    scene.setGeometryAt(2, POINTS[5])
    check scene.revisionPlacingAt(2) == scene.revision
    for handle in [0, 1, 3]: check scene.revisionPlacingAt(handle) < scene.revision
    # Ink and visibility change nothing about placement.
    scene.setInk(1, Ink.Rose)
    scene.setVisible(3, false)
    for handle in [0, 1, 3]: check scene.revisionPlacingAt(handle) < scene.revision
    # Restore may change any handle, so every live one is stamped at new revision.
    var snapshot = initScene()
    for i in 0 ..< 3: discard snapshot.addObject(POINTS[i + 5], "s" & $i, inkCycled(i))
    scene.restoreFrom(snapshot)
    check scene.len == 3
    for handle in 0 ..< 3: check scene.revisionPlacingAt(handle) == scene.revision


  test "restoreFrom lands on a revision no earlier state carried":
    # Assignment restored snapshot's own revision, and bump after it landed on very.
    #   number of edit being undone -- so front-end holding meshes on it drew
    #   undone object until camera moved. Measured on built page.
    var scene = initScene()
    discard scene.addObject(POINTS[0], "a", Ink.Rose)
    let snapshot = scene
    discard scene.addObject(POINTS[1], "b", Ink.Rose)
    let revision_edit = scene.revision
    scene.restoreFrom(snapshot)
    check scene.len == 1
    check scene.revision > revision_edit
    # And from snapshot ahead of live scene, past that snapshot's own.
    var ahead = snapshot
    for i in 0 ..< 5: discard ahead.addObject(POINTS[i], "x" & $i, Ink.Rose)
    scene.restoreFrom(ahead)
    check scene.len == 6
    check scene.revision > ahead.revision
    check scene.revision > revision_edit


  # Where versions 2 to 5 wrote `Rose`: one past today's, palette then holding retired.
  #   structural slot `Algebra` at ordinal 7 before every hue; see `scene.upgradedFrom5`.
  const ORDINAL_INK_ROSE_V5 = ord(Ink.Rose) + 1
  const ORDINAL_INK_ALGEBRA_V5 = 7

  proc savedWith(ordinal: int, radius = RADIUS_OBJECT_DEFAULT): ObjectSaved =
    ## Build object differing from its neighbours only in palette slot and radius.
    ##   Two fields version boundaries have ever changed and kept; radius defaults, since
    ##   most cases care about palette alone.
    ObjectSaved(
      ink_ordinal: ordinal, is_visible: true, label: "x", geometry: POINTS[0], radius: radius,
    )


  test "an object already at this version is carried up unchanged":
    # Chain has to be no-op on file this build wrote, or every save/load round.
    #   trip quietly rewrites something.
    for ordinal in ord(Ink.low) .. ord(Ink.high):
      let carried = objectUpgraded(savedWith(ordinal), VERSION_SCENE)
      check carried.isSome
      check carried.get.ink_ordinal == ordinal
      check carried.get.is_visible
      check carried.get.label == "x"
      check carried.get.geometry =~ POINTS[0]
      check carried.get.radius == RADIUS_OBJECT_DEFAULT
    # And ordinal no palette answers to is refused rather than clamped into one.
    check objectUpgraded(savedWith(ord(Ink.high) + 1), VERSION_SCENE).isNone
    check objectUpgraded(savedWith(-1), VERSION_SCENE).isNone
    # Radius this build keeps is whatever file said, so long as it could draw something.
    check objectUpgraded(savedWith(0, 2.5), VERSION_SCENE).get.radius == 2.5
    check objectUpgraded(savedWith(0, 0.0), VERSION_SCENE).isNone
    check objectUpgraded(savedWith(0, -1.0), VERSION_SCENE).isNone
    check objectUpgraded(savedWith(0, NaN), VERSION_SCENE).isNone


  test "a version-3 object is given the radius version 3 drew everything at":
    # Version 3 wrote no radius, so whatever reader had in field is overwritten, not.
    #   trusted: parser passing garbage or zero there must still land on default.
    for stale in [0.0, -1.0, 7.0, NaN]:
      let carried = objectUpgraded(savedWith(ORDINAL_INK_ROSE_V5, stale), 3'u8)
      check carried.isSome
      check carried.get.radius == RADIUS_OBJECT_DEFAULT
      check carried.get.ink_ordinal == ord(Ink.Rose)
    # Same for every older version: radius joins chain at its boundary, once.
    for version in VERSION_SCENE_LEAST ..< VERSION_SCENE_RADIUS:
      check not hasRadius(version)
      # First hue in each version's own palette; see `ORDINAL_INK_ROSE_V5`.
      let ordinal = if version == 1'u8: ORDINAL_INK_CATEGORICAL_V1 else: ORDINAL_INK_ROSE_V5
      check objectUpgraded(savedWith(ordinal, 0.0), version).get.radius == RADIUS_OBJECT_DEFAULT
    check hasRadius(VERSION_SCENE)


  test "only versions 5 and 6 carry a shines byte, and this build writes none":
    # Byte is skipped on reading and nothing is carried from it, so whole of what.
    #   version pair means is which offsets bytes after it parse from; see `sceneFileOf`.
    for version in VERSION_SCENE_LEAST ..< VERSION_SCENE_SHINE:
      check not hasShine(version)
    for version in VERSION_SCENE_SHINE .. VERSION_SCENE_SHINE_LAST:
      check hasShine(version)
      check objectUpgraded(savedWith(ORDINAL_INK_ROSE_V5), version).isSome
    check not hasShine(VERSION_SCENE)
    check VERSION_SCENE > VERSION_SCENE_SHINE_LAST


  test "a version-5 hue past the retired debug slot moves one down, and the slot is refused":
    # Version 6 dropped structural `Algebra` from palette; ordinals past it shift, ones.
    #   before it stand, and byte naming slot no build ever assigned is corrupt.
    for ordinal in 0 ..< ORDINAL_INK_ALGEBRA_V5:
      check objectUpgraded(savedWith(ordinal), 5'u8).get.ink_ordinal == ordinal
    check objectUpgraded(savedWith(ORDINAL_INK_ALGEBRA_V5), 5'u8).isNone
    for ordinal in ORDINAL_INK_ALGEBRA_V5 + 1 .. ord(Ink.high) + 1:
      check objectUpgraded(savedWith(ordinal), 5'u8).get.ink_ordinal == ordinal - 1
    check objectUpgraded(savedWith(ORDINAL_INK_ROSE_V5), 5'u8).get.ink_ordinal == ord(Ink.Rose)
    # Past what version 5 could name is refused, as ever.
    check objectUpgraded(savedWith(ord(Ink.high) + 2), 5'u8).isNone


  test "a version-2 object needs nothing doing to it but is walked all the same":
    # Version 2 and 3 differ only in what object *sequence* promises, so object's own.
    #   fields come through untouched -- and must not be folded by version-1 step.
    #   Compared field by field rather than through `==`, which `Multivector` makes
    #   compile error on purpose; geometry is checked with approximate operator.
    # Palette ordinals are version 5's, one past today's beyond retired slot, so.
    #   both walks land on same hue only where they start from what each wrote.
    for ordinal in ord(Ink.low) .. ord(Ink.high) + 1:
      if ordinal == ORDINAL_INK_ALGEBRA_V5: continue
      let
        today = if ordinal > ORDINAL_INK_ALGEBRA_V5: ordinal - 1 else: ordinal
        from_two = objectUpgraded(savedWith(ordinal), 2'u8)
        from_three = objectUpgraded(savedWith(today), VERSION_SCENE)
      check from_two.isSome
      check from_three.isSome
      check from_two.get.ink_ordinal == today
      check from_two.get.ink_ordinal == from_three.get.ink_ordinal
      check from_two.get.is_visible == from_three.get.is_visible
      check from_two.get.label == from_three.get.label
      check from_two.get.geometry =~ from_three.get.geometry


  test "a version-1 object is carried onto today's palette, hue by hue":
    # Version 1 had no `Invalid` and three more hues, so every ordinal it could hold is.
    #   walked here rather than only two ends.
    for ordinal in 0 ..< ORDINAL_INK_CATEGORICAL_V1:
      # Structural slots are unmoved to this day.
      let carried = objectUpgraded(savedWith(ordinal), 1'u8)
      check carried.isSome
      check carried.get.ink_ordinal == ordinal
    for step in 0 ..< 8:
      # Its eight hues all land on hue -- never on `Invalid`, never off end.
      let carried = objectUpgraded(savedWith(ORDINAL_INK_CATEGORICAL_V1 + step), 1'u8)
      check carried.isSome
      let ink = Ink(carried.get.ink_ordinal)
      check ink == inkCycled(step)
      check ink != Ink.Invalid
      check ink in inkCategorical(0) .. inkCategorical(COUNT_INK_CATEGORICAL - 1)
    # Deliberately *not* pinned to fixed shift from version 1's own start. Structural.
    #   slot reserved since -- `Invalid`, then `Algebra` -- moves every hue along by one
    #   more while leaving fold correct, so such assertion fails on legitimate
    #   palette change and catches no real fault. Where each hue lands is stated above,
    #   through `inkCycled`, which is what fold actually promises.
    # Ordinals version 1 could never have written are corrupt file, not another hue.
    check objectUpgraded(savedWith(ORDINAL_INK_HIGH_V1 + 1), 1'u8).isNone
    check objectUpgraded(savedWith(-1), 1'u8).isNone
    # Everything that is not palette rides through whole chain untouched.
    let carried = objectUpgraded(savedWith(ORDINAL_INK_HIGH_V1), 1'u8)
    check carried.get.label == "x"
    check carried.get.geometry =~ POINTS[0]


  test "a version outside what this build reads is refused by the chain itself":
    # Guard lives with walk rather than only at each call site, so caller that.
    #   forgets to check `readsSceneVersion` still cannot get half-upgraded object.
    check objectUpgraded(savedWith(ord(Ink.Rose)), 0'u8).isNone
    check objectUpgraded(savedWith(ord(Ink.Rose)), VERSION_SCENE + 1'u8).isNone
    for version in VERSION_SCENE_LEAST .. VERSION_SCENE:
      check readsSceneVersion(version)
      # First hue in each version's own palette; see `ORDINAL_INK_ROSE_V5`.
      let ordinal =
        if version == 1'u8: ORDINAL_INK_CATEGORICAL_V1
        elif version < VERSION_SCENE: ORDINAL_INK_ROSE_V5
        else: ord(Ink.Rose)
      check objectUpgraded(savedWith(ordinal), version).isSome


  test "bornReplaying staggers an arrival in order and never runs past the cap":
    const CLOCK = 12.5
    # Handful of objects get full beat: legible, and short enough to still overlap.
    check bornReplaying(0, 4, CLOCK) =~ CLOCK
    for index in 1 ..< 4:
      check bornReplaying(index, 4, CLOCK) =~ CLOCK + float(index)*SECONDS_REPLAY_STEP
    # Single object arriving alone has nothing to stagger against.
    check bornReplaying(0, 1, CLOCK) =~ CLOCK
    # However many arrive, last of them lands within cap -- and in order.
    for count in 1 .. OBJECTS_MAX:
      var previous = low(float)
      for index in 0 ..< count:
        let born = bornReplaying(index, count, CLOCK)
        check born > previous
        check born >= CLOCK
        previous = born
      check previous - CLOCK <= SECONDS_REPLAY_WHOLE + TOLERANCE_TEST
    # And beat only ever shortens to make that fit, never lengthens.
    check bornReplaying(1, OBJECTS_MAX, CLOCK) - CLOCK < SECONDS_REPLAY_STEP


  test "replayFrom restamps a whole scene into an arrival, in creation order":
    # What opening scene and demo preset both go through: built all at once, then.
    #   handed to reader as construction it is. Handle order is scrambled first, so
    #   this pins that restamp follows creation order rather than arena's layout.
    var scene = initScene()
    for i in 0 ..< 5:
      discard scene.addObject(POINTS[i], "p" & $i, inkCycled(i), 99.0)
    scene.removeObject(1)
    let handle_late = scene.addObject(POINTS[5], "late", Ink.Rose, 99.0)
    check handle_late == 1

    const CLOCK = 7.5
    scene.replayFrom(CLOCK)
    var handles: array[OBJECTS_MAX, int]
    let count = scene.handlesCreated(handles)
    check count == 5
    check scene.bornAt(handles[0]) =~ CLOCK
    for position in 1 ..< count:
      check scene.bornAt(handles[position]) > scene.bornAt(handles[position - 1])
    check toText(scene.labelAt(handles[count - 1])) == "late"
    check scene.bornAt(handles[count - 1]) - CLOCK <= SECONDS_REPLAY_WHOLE + TOLERANCE_TEST
    # Same beat file of this size would arrive on -- one rule, not two.
    for position in 0 ..< count:
      check scene.bornAt(handles[position]) =~ bornReplaying(position, count, CLOCK)

    # Empty scene has nothing to restamp and must not fall over reaching for handle zero.
    var empty = initScene()
    empty.replayFrom(CLOCK)
    check empty.len == 0


  test "the opening scene arrives as a replay rather than all at once":
    # Startup seeds are construction somebody else made, exactly as loaded file.
    #   is, so both front-ends stagger them. `constructSeeds` itself deliberately does
    #   not: `runStoryboard` calls it too and sweeps each step on clock of its own.
    const CLOCK = 4.0
    var placed = initScene()
    constructSeeds(placed, CLOCK)
    for handle in 0 ..< placed.len:
      check placed.bornAt(handle) == CLOCK # Untouched by constructor itself.

    var opened = initScene()
    constructSeeds(opened, CLOCK)
    opened.replayFrom(CLOCK)
    check opened.len >= 2
    for handle in 1 ..< opened.len:
      check opened.bornAt(handle) > opened.bornAt(handle - 1)
    # Still on screen quickly: opening scene reader waits through is worse opening.
    #   scene than one that simply appeared.
    check opened.bornAt(opened.len - 1) - CLOCK <= SECONDS_REPLAY_WHOLE + TOLERANCE_TEST


  test "a replay stamp in the future draws its object at no size yet":
    # What makes stagger visible rather than merely recorded: `mesh.animationProgress`.
    #   reads born clock has not reached as zero progress, so object waiting its
    #   turn is drawn at nothing and grows in when its beat arrives.
    const CLOCK = 3.0
    let born_second = bornReplaying(1, 4, CLOCK)
    check animationProgress(CLOCK, born_second) == 0.0
    check animationProgress(born_second, born_second) == 0.0
    check animationProgress(born_second + ANIMATION_SECONDS, born_second) == 1.0
    check animationProgress(CLOCK, bornReplaying(0, 4, CLOCK)) == 0.0


  # Saving and loading name filesystem, which browser has none of: `scene.nim`.
  #   declares that pair for desktop backend alone, so their tests are guarded to
  #   match. Every other invariant in this suite holds on both backends and is checked
  #   on both.
  when not defined(js):
    test "save then load reproduces every live object, compacting freed handles":
      var original = initScene()
      discard original.addObject(POINTS[0], "a", Ink.Rose)
      discard original.addObject(POINTS[1], "bb", Ink.Jade, radius = 0.6)
      let handle_doomed = original.addObject(POINTS[2], "doomed", Ink.Olive)
      original.removeObject(handle_doomed) # leaves hole fresh load must not reproduce
      let handle_last = original.addObject(POINTS[3], "d", Ink.Cobalt)
      original.setVisible(handle_last, false)

      let path = getTempDir() / "visualiser_suite_scene.rgascene"
      check saveScene(original, path).contains("Saved 3")
      defer: removeFile(path)

      var loaded = initScene()
      discard loaded.addObject(POINTS[9], "stale", Ink.Cobalt) # load must replace, not merge
      check loadScene(loaded, path).contains("Loaded 3")
      check loaded.len == 3

      # Freed handle 2 is compacted away: loaded objects land at handles 0, 1, 2 in save order.
      check loaded[0].geometry =~ POINTS[0]
      check toText(loaded[0].label) == "a"
      check loaded[0].ink == Ink.Rose
      check loaded[0].isVisible
      check loaded[0].born == 0.0 # dawn of time, not mid-appear-in-animation
      check loaded[0].radius == RADIUS_OBJECT_DEFAULT

      check loaded[1].geometry =~ POINTS[1]
      check toText(loaded[1].label) == "bb"
      check loaded[1].ink == Ink.Jade
      check loaded[1].isVisible
      check loaded[1].radius == 0.6

      check loaded[2].geometry =~ POINTS[3]
      check toText(loaded[2].label) == "d"
      check loaded[2].ink == Ink.Cobalt
      check not loaded[2].isVisible


    test "every multi-byte field is written little-endian, whatever the host":
      # Bytes themselves, not round trip: round trip passes on any byte order as.
      #   long as one build writes and reads it, and second implementation of this
      #   format is browser scripts, which hands `DataView` explicit `true` at every call and
      #   cannot be asked what desktop felt like doing. Pinning layout here is what
      #   keeps two from drifting apart on host that is not little-endian.
      var scene = initScene()
      var geometry: Multivector
      geometry[Basis.low] = 2.0 # 0x4000000000000000, whose bytes are unambiguous either way
      discard scene.addObject(geometry, "e", Ink.Rose)
      let path = getTempDir() / "visualiser_suite_scene_endian.rgascene"
      check saveScene(scene, path).contains("Saved 1")
      defer: removeFile(path)

      let bytes = readFile(path)
      check bytes[0 ..< len(MAGIC_SCENE)] == MAGIC_SCENE
      check uint8(bytes[len(MAGIC_SCENE)]) == VERSION_SCENE

      # Object count, four bytes straight after magic, version and basis count.
      let start_count = len(MAGIC_SCENE) + 2
      check uint8(bytes[start_count]) == 1'u8
      for offset in 1 .. 3: check uint8(bytes[start_count + offset]) == 0'u8

      # First coefficient, past count and this object's ink, visibility, label length and.
      #   one byte of label itself.
      let start_first = start_count + 4 + 3 + 1
      check uint8(bytes[start_first + 6]) == 0x00'u8
      check uint8(bytes[start_first + 7]) == 0x40'u8 # High byte last: little-endian.


    test "empty scene round-trips":
      let original = initScene()
      let path = getTempDir() / "visualiser_suite_scene_empty.rgascene"
      check saveScene(original, path).contains("Saved 0")
      defer: removeFile(path)

      var loaded = initScene()
      discard loaded.addObject(POINTS[0], "will be cleared", Ink.Rose)
      check loadScene(loaded, path).contains("Loaded 0")
      check loaded.len == 0


    test "loading a foreign file leaves scene untouched and reports why":
      var scene = initScene()
      discard scene.addObject(POINTS[0], "keep", Ink.Rose)
      let path = getTempDir() / "visualiser_suite_scene_bogus.rgascene"
      writeFile(path, "not a scene file at all")
      defer: removeFile(path)

      check loadScene(scene, path).contains("not a scene file")
      check scene.len == 1
      check toText(scene[0].label) == "keep"


    test "loading a file saved under a different PGA dimension is rejected":
      var scene = initScene()
      discard scene.addObject(POINTS[0], "keep", Ink.Rose)
      let path = getTempDir() / "visualiser_suite_scene_wrongbasis.rgascene"
      writeFile(path, "RGAS" & char(2) & char(99)) # no build here carries 99 basis terms
      defer: removeFile(path)

      check loadScene(scene, path).contains("different PGA dimension")
      check scene.len == 1


    proc sceneFileOf(version: uint8, saved: seq[(int, bool, string, Multivector)]): string =
      ## Build bytes of scene file by hand, at whatever version is asked for.
      ##   Hand-built rather than saved by this build, because point of cases
      ##   below is to read version this build can no longer *write*: asking `saveScene`
      ##   for one would only ever produce today's, and reading it exercised would be
      ##   its own writing spelled backwards. Ink is taken as raw ordinal for same
      ##   reason -- old file's ordinals name enum that is gone.
      result = MAGIC_SCENE & char(version) & char(ord(Basis.high) + 1)
      var count = uint32(len(saved))
      var count_bytes = newString(4)
      littleEndian32(addr count_bytes[0], addr count)
      result &= count_bytes
      for (ordinal, is_visible, label, geometry) in saved:
        result &= char(ordinal) & char(ord(is_visible)) & char(len(label)) & label
        for b in Basis:
          var
            coefficient = geometry[b]
            bytes = newString(8)
          littleEndian64(addr bytes[0], addr coefficient)
          result &= bytes
        # Radius only from version that carries one; older bytes stop at geometry.
        if hasRadius(version):
          var
            radius = 2.0*RADIUS_OBJECT_DEFAULT
            bytes = newString(8)
          littleEndian64(addr bytes[0], addr radius)
          result &= bytes
        # Shine byte only from version that carries one, set so reader can tell.
        if hasShine(version): result &= char(1)


    test "a scene file from before the palette changed is read, not refused":
      # Object's ink is stored as `Ink`'s own ordinal, and reserving `Invalid` renumbered.
      #   that enum -- version-1 file's bytes name different colours now. Reading it
      #   through palette it was written under is what keeps somebody's scene;
      #   three hues that no longer exist fold onto ones that do, which is recoverable
      #   wrong colour rather than unrecoverable refusal.
      var scene = initScene()
      discard scene.addObject(POINTS[9], "replaced", Ink.Rose)
      let path = getTempDir() / "visualiser_suite_scene_v1.rgascene"
      writeFile(path, sceneFileOf(1'u8, @[
        (4, true, "grid-hued", POINTS[0]),  # Structural slot, unmoved between palettes.
        (7, true, "was rose", POINTS[1]),   # First categorical hue of old palette.
        (11, false, "was cobalt", POINTS[2]),
        (13, true, "was magenta", POINTS[3]), # Retired; folds onto hue that survives.
      ]))
      defer: removeFile(path)

      check loadScene(scene, path).contains("Loaded 4")
      check scene.len == 4
      check scene[0].ink == Ink.Grid
      check scene[1].ink == Ink.Rose
      check scene[2].ink == Ink.Cobalt
      check scene[3].ink == inkCycled(13 - ORDINAL_INK_CATEGORICAL_V1)
      # Everything but colour of retired hue comes back exactly.
      for handle in 0 ..< 4:
        check scene[handle].geometry =~ POINTS[handle]
      check toText(scene[1].label) == "was rose"
      check scene[1].isVisible
      check not scene[2].isVisible


    test "a version-2 file's hues come down past the retired debug slot, nothing folded":
      # Version 2 and 3 differ only in what object *sequence* promises, so version-2.
      #   file's ordinals must not be folded through version-1 rule; they are version
      #   5's, one past today's beyond retired `Algebra` slot, and `upgradedFrom5` alone
      #   takes them down.
      var scene = initScene()
      let path = getTempDir() / "visualiser_suite_scene_v2.rgascene"
      writeFile(path, sceneFileOf(2'u8, @[
        (ord(Ink.Grid), true, "structural", POINTS[0]),
        (ord(Ink.Rose) + 1, true, "first hue", POINTS[1]),
        (ord(Ink.Cobalt) + 1, false, "last hue", POINTS[2]),
      ]))
      defer: removeFile(path)

      check loadScene(scene, path).contains("Loaded 3")
      check scene[0].ink == Ink.Grid
      check scene[1].ink == Ink.Rose
      check scene[2].ink == Ink.Cobalt
      check not scene[2].isVisible


    test "a version-3 file is read with every object at the default radius":
      # Version 3 stopped at geometry, so bytes run straight from one object's last.
      #   coefficient into next object's ink: reading radius there would parse whole
      #   rest of file from wrong offset.
      var scene = initScene()
      let path = getTempDir() / "visualiser_suite_scene_v3.rgascene"
      writeFile(path, sceneFileOf(3'u8, @[
        (ord(Ink.Rose), true, "first", POINTS[0]),
        (ord(Ink.Cobalt), false, "second", POINTS[1]),
      ]))
      defer: removeFile(path)

      check loadScene(scene, path).contains("Loaded 2")
      check scene[0].radius == RADIUS_OBJECT_DEFAULT
      check scene[1].radius == RADIUS_OBJECT_DEFAULT
      check scene[1].geometry =~ POINTS[1]
      check toText(scene[1].label) == "second"
      check not scene[1].isVisible
      # And today's file carries radius through, wherever writer put it.
      let path_now = getTempDir() / "visualiser_suite_scene_v4.rgascene"
      writeFile(path_now, sceneFileOf(VERSION_SCENE, @[
        (ord(Ink.Rose), true, "sized", POINTS[0]),
      ]))
      defer: removeFile(path_now)
      check loadScene(scene, path_now).contains("Loaded 1")
      check scene[0].radius == 2.0*RADIUS_OBJECT_DEFAULT
      # Version-4 file stops at radius, and bytes parse from right offset.
      let path_four = getTempDir() / "visualiser_suite_scene_v4_only.rgascene"
      writeFile(path_four, sceneFileOf(4'u8, @[
        (ord(Ink.Rose), true, "sized", POINTS[0]),
        (ord(Ink.Cobalt), false, "second", POINTS[1]),
      ]))
      defer: removeFile(path_four)
      check loadScene(scene, path_four).contains("Loaded 2")
      check scene[0].radius == 2.0*RADIUS_OBJECT_DEFAULT
      check not scene[1].isVisible
      # Version-6 file carries shines byte after radius: skipped, and every object after it
      #   still parses from right offset, which is whole of what reading it costs.
      let path_six = getTempDir() / "visualiser_suite_scene_v6_shine.rgascene"
      writeFile(path_six, sceneFileOf(VERSION_SCENE_SHINE_LAST, @[
        (ord(Ink.Rose), true, "shone", POINTS[0]),
        (ord(Ink.Cobalt), false, "second", POINTS[1]),
      ]))
      defer: removeFile(path_six)
      check loadScene(scene, path_six).contains("Loaded 2")
      check scene[0].radius == 2.0*RADIUS_OBJECT_DEFAULT
      check toText(scene[1].label) == "second"
      check scene[1].geometry =~ POINTS[1]
      check not scene[1].isVisible


    test "a file from a version this build predates is refused rather than guessed at":
      # Floor never rises, so only ceiling can refuse: later format may mean.
      #   anything at all by these bytes, and there is nothing honest to do but say so.
      var scene = initScene()
      discard scene.addObject(POINTS[0], "keep", Ink.Rose)
      let path = getTempDir() / "visualiser_suite_scene_ahead.rgascene"
      writeFile(path, sceneFileOf(VERSION_SCENE + 1'u8, @[
        (ord(Ink.Rose), true, "future", POINTS[1]),
      ]))
      defer: removeFile(path)

      check loadScene(scene, path).contains("version this build cannot read")
      check scene.len == 1
      check toText(scene[0].label) == "keep"
      check not readsSceneVersion(0'u8) # Version byte of zero was never written either.


    test "a saved scene keeps creation order however its handles were reused":
      # What version 3 is for. Removing and re-adding drops new object into freed.
      #   handle, so handle order and creation order disagree -- and it is creation order
      #   replay has to walk, or file plays back construction that never happened.
      var original = initScene()
      for i in 0 ..< 4:
        discard original.addObject(POINTS[i], "p" & $i, inkCycled(i))
      original.removeObject(1)
      discard original.addObject(POINTS[4], "late", Ink.Rose) # reuses handle 1
      check original.len == 4

      let path = getTempDir() / "visualiser_suite_scene_order.rgascene"
      check saveScene(original, path).contains("Saved 4")
      defer: removeFile(path)

      var loaded = initScene()
      check loadScene(loaded, path).contains("Loaded 4")
      check toText(loaded[0].label) == "p0"
      check toText(loaded[1].label) == "p2"
      check toText(loaded[2].label) == "p3"
      check toText(loaded[3].label) == "late"
      # And order survives second trip, since loading rebuilds ordinals from.
      #   file's own sequence rather than from wherever handles landed.
      check saveScene(loaded, path).contains("Saved 4")
      var again = initScene()
      check loadScene(again, path).contains("Loaded 4")
      for handle in 0 ..< 4:
        check toText(again[handle].label) == toText(loaded[handle].label)


    test "a loaded scene arrives one object at a time, replaying its construction":
      # Load stamps borns from caller's clock forward, which is what makes each.
      #   object still be growing in when next arrives (`mesh.animationProgress` reads
      #   born in future as zero size). Checked against file, not against
      #   scene it came from: whole point is that replay is reconstructed from
      #   sequence rather than from clock reading nobody saved.
      var original = initScene()
      for i in 0 ..< 5:
        discard original.addObject(POINTS[i], "p" & $i, inkCycled(i))
      let path = getTempDir() / "visualiser_suite_scene_replay.rgascene"
      check saveScene(original, path).contains("Saved 5")
      defer: removeFile(path)

      const CLOCK = 40.0
      var loaded = initScene()
      check loadScene(loaded, path, CLOCK).contains("Loaded 5")
      check loaded[0].born =~ CLOCK
      for handle in 1 ..< 5:
        check loaded[handle].born > loaded[handle - 1].born
        # Still growing in as next one lands, rather than queue of separate pop-ins.
        check loaded[handle].born - loaded[handle - 1].born < ANIMATION_SECONDS
      check loaded[4].born - loaded[0].born <= SECONDS_REPLAY_WHOLE

      # No clock, no replay: caller with nothing to animate for gets grown scene.
      var batched = initScene()
      check loadScene(batched, path).contains("Loaded 5")
      check batched[0].born == 0.0


    test "loading a missing path reports cleanly and leaves scene untouched":
      var scene = initScene()
      discard scene.addObject(POINTS[0], "keep", Ink.Rose)
      let path = getTempDir() / "visualiser_suite_scene_does_not_exist.rgascene"

      check loadScene(scene, path).contains("No such file")
      check scene.len == 1


    test "loading a file naming more objects than this build's capacity is rejected":
      var scene = initScene()
      discard scene.addObject(POINTS[0], "keep", Ink.Rose)

      var
        count = uint32(OBJECTS_MAX + 1)
        count_bytes = newString(4)
      copyMem(addr count_bytes[0], addr count, 4)
      let path = getTempDir() / "visualiser_suite_scene_toobig.rgascene"
      writeFile(path, "RGAS" & char(2) & char(ord(Basis.high) + 1) & count_bytes)
      defer: removeFile(path)

      check loadScene(scene, path).contains("more than")
      check scene.len == 1
