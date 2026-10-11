## Measure limits of one unitize rule over long chains of moves and over frames
##   (`unitize-general`).
##   Evaluation compiles this against changed library at each algebra its claim names; exit code
##     is verdict: chain of million moves never passes tolerance of grade test, and pattern of
##     one frame holds within its bound.
##   Each move is product of two nearby reflections, as animation steps: planes for rigid moves,
##     spheres or planes for conformal moves. Residue is largest coefficient outside grade of
##     object, over largest coefficient: rounding leaves it, and grade test must ignore it.
##   Figures it prints are evidence that never gates: first move past each tolerance, residue
##     with and without grade selection, composed operator against step by step, frames, and
##     pose drift of motor stored at 32 bits.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import std/[math, random, strformat]

import pga


const
  MOVES = 1_000_000  ## Moves in each chain.
  CHAINS = 4  ## Chains of each kind, each from its own objects.
  SEED = 0  ## Seed of sample generator, so every run reads same moves.
  TOLERANCES = [1e-13, 1e-12, 1e-11, 1e-10, 1e-9]  ## Tolerances of grade test, relative.
  TOLERANCE_GRADE = 1e-9  ## Tolerance P11 sets: chains must stay under it.
  STEP = 0.01  ## Size of each move: distance between its two reflections.
  DEPTHS = [1, 16, 64, 256]  ## Depths of hierarchy composed in one frame.
  FRAMES_HOUR = 216_000  ## Frames in one hour at 60 frames each second.
  FRAMES_POSE = [3_600, 216_000, 1_296_000]  ## One minute, one hour and six hours at 60 fps.
  OBJECTS_FRAME = 16  ## Objects each frame moves.


func largest(m: Multivector): float =
  ## Get largest absolute coefficient of multivector; infinity where any coefficient is NaN.
  for b in Basis:
    if m[b] != m[b]: return Inf
    result = max(result, abs(m[b]))


func antidot(m: Multivector): float =
  ## Get antiscalar part of antidot product of multivector with itself.
  (m ∘ m)[Basis.scalarAnti]


func residue(m: Multivector; grade: Grade): float =
  ## Get largest coefficient outside grade, over largest coefficient.
  for b in Basis:
    if b.grade != grade: result = max(result, abs(m[b]))
  result /= m.largest


func selected(m: Multivector; grade: Grade): Multivector =
  ## Keep coefficients of grade alone.
  for b in Basis:
    if b.grade == grade: result[b] = m[b]


proc drawPoint(spread = 1.0): Multivector =
  ## Draw point at random position: round point of radius zero in CGA, unit point in RGA.
  var distance_squared = 0.0
  for b in Basis.scalar.succ .. Basis.origin.pred:
    result[b] = gauss() * spread
    distance_squared += result[b]^2
  result[Basis.origin] = 1
  when IS_CONFORMAL: result[Basis.infinity] = distance_squared / 2


proc drawReflector(is_plane: bool): Multivector =
  ## Draw random element of antigrade one: plane where asked, else sphere or plane in CGA.
  if is_plane:
    result = drawPoint()
    when IS_CONFORMAL:
      for _ in 2 ..< DIMENSIONS - 1: result = result ∧ drawPoint()
      result = result ∧ Basis.infinity.initElement()
    else:
      for _ in 2 ..< DIMENSIONS: result = result ∧ drawPoint()
  else:
    for b in Basis:
      if b.grade == Grade.high.pred: result[b] = gauss()


func unitVersor(versor: Multivector): Multivector =
  ## Scale versor so that its antidot square is ±𝟙.
  versor * (1 / sqrt(abs(versor.antidot)))


proc drawMove(is_rigid: bool; size: float): Multivector =
  ## Draw unit versor of two reflections at distance size: near identity where size is small.
  let first = unitVersor(drawReflector(is_rigid))
  var second = first
  for b in Basis:
    if b.grade == Grade.high.pred: second[b] += gauss() * size
  unitVersor(unitVersor(second) ⟇ first)


func moved(element, versor: Multivector): Multivector =
  ## Move element by versor, as antisandwich 𝐯 ⟇ 𝐮 ⟇ ~𝐯.
  (versor ⟇ element) ⟇ ~∘versor


proc drawObjects(): seq[(Multivector, Grade)] =
  ## Draw point and largest object: sphere in CGA, plane in RGA, with grade of each.
  var largest_object = drawPoint()
  for _ in 2 ..< DIMENSIONS: largest_object = largest_object ∧ drawPoint()
  @[(drawPoint(), Grade.low.succ), (largest_object, Grade.high.pred)]


func drift(point: Multivector): float =
  ## Get drift of round point from radius zero, over its scale squared.
  abs(point.antidot) / point.largest^2


proc chains(is_rigid, should_unitize: bool) =
  ## Move objects million times; print first move past each tolerance, and drift.
  var
    moves_first: array[TOLERANCES.len, seq[int]]
    residue_worst, residue_selected, residue_composed, drift_moved, drift_selected = 0.0
  for _ in 1..CHAINS:
    let objects_start = drawObjects()
    var
      objects = objects_start
      objects_selected = objects_start
      composed: Multivector
      moves_found: array[TOLERANCES.len, int]
    composed[Basis.scalarAnti] = 1
    for move in 1..MOVES:
      let versor = drawMove(is_rigid, STEP)
      composed = versor ⟇ composed
      if should_unitize: composed = ^composed
      for i in 0 ..< objects.len:
        objects[i][0] = objects[i][0].moved(versor)
        objects_selected[i][0] = objects_selected[i][0].moved(versor).selected(objects[i][1])
        if should_unitize:
          objects[i][0] = ^objects[i][0]
          objects_selected[i][0] = ^objects_selected[i][0]
        let found = objects[i][0].residue(objects[i][1])
        residue_worst = max(residue_worst, found)
        for t, tolerance in TOLERANCES:
          if moves_found[t] == 0 and found > tolerance: moves_found[t] = move
    for t in 0 ..< TOLERANCES.len: moves_first[t].add moves_found[t]
    for i in 0 ..< objects.len:
      let once = objects_start[i][0].moved(composed)
      residue_composed = max(residue_composed, once.residue(objects[i][1]))
      residue_selected = max(residue_selected, objects_selected[i][0].residue(objects[i][1]))
    when IS_CONFORMAL:
      drift_moved = max(drift_moved, objects[0][0].drift)
      drift_selected = max(drift_selected, objects_selected[0][0].drift)
  let
    kind = (if is_rigid: "rigid moves" else: "conformal moves") &
      (if should_unitize: ", unitized each move" else: ", never unitized")
    algebra = (if IS_CONFORMAL: "cga" else: "rga") & $DIMENSIONS & "d"
  echo &"{algebra}: {kind}: worst residue {residue_worst:.1e} in {MOVES} moves, " &
    &"composed and applied once {residue_composed:.1e}, selected each move {residue_selected:.1e}"
  when IS_CONFORMAL:
    echo &"{algebra}: {kind}: round point drift from null, moved {drift_moved:.1e}, " &
      &"selected each move {drift_selected:.1e}"
  for t, tolerance in TOLERANCES:
    var line = &"{algebra}: {kind}: first move past {tolerance:.0e}:"
    for found in moves_first[t]: line &= (if found == 0: " never" else: &" {found}")
    echo line
  doAssert residue_worst < TOLERANCE_GRADE,
    &"chain stays under tolerance of grade test; got `{residue_worst}`."


proc frames() =
  ## Compose hierarchy in one frame, apply once, unitize once; then carry operator one hour.
  let algebra = (if IS_CONFORMAL: "cga" else: "rga") & $DIMENSIONS & "d"
  var points: array[OBJECTS_FRAME, Multivector]
  for point in points.mitems: point = drawPoint(10)
  for depth in DEPTHS:
    var
      error = 0.0
      size = 0.0
      versors: seq[Multivector]
      composed: Multivector
    composed[Basis.scalarAnti] = 1
    for _ in 1..depth:
      versors.add unitVersor(drawReflector(not IS_CONFORMAL) ⟇ drawReflector(not IS_CONFORMAL))
      composed = versors[^1] ⟇ composed
    size = composed.largest
    for point in points:
      let once = ^point.moved(composed)
      var stepped = point
      for versor in versors: stepped = ^stepped.moved(versor)
      var difference = 0.0
      for b in Basis: difference = max(difference, abs(once[b] - stepped[b]))
      error = max(error, difference / stepped.largest)
    echo &"{algebra}: one frame of depth {depth}: composed, applied once and unitized once, " &
      &"against step by step {error:.1e}, largest coefficient of composed {size:.1e}"
    doAssert error < 1e-6, &"one frame holds against step by step; got `{error}`."
  for should_unitize in [true, false]:
    var
      operator: Multivector
      size_worst = 0.0
      overflow = 0
    operator[Basis.scalarAnti] = 1
    for frame in 1..FRAMES_HOUR:
      operator = drawMove(not IS_CONFORMAL, STEP) ⟇ operator
      if should_unitize: operator = ^operator
      size_worst = max(size_worst, operator.largest)
      if overflow == 0 and not (operator.largest < 1e300): overflow = frame
    var
      error = 0.0
      is_lost = false
    for i in 0 ..< OBJECTS_FRAME - 1:
      let (moved_a, moved_b) = (^points[i].moved(operator), ^points[i + 1].moved(operator))
      if moved_a.largest in [0.0, Inf] or moved_b.largest in [0.0, Inf]: is_lost = true
      when IS_CONFORMAL:
        error = max(error, moved_a.drift)
      else:
        var (distance, distance_start) = (0.0, 0.0)
        for b in Basis.scalar.succ .. Basis.origin.pred:
          distance += (moved_a[b] - moved_b[b])^2
          distance_start += (points[i][b] - points[i + 1][b])^2
        error = max(error, abs(sqrt(distance) / sqrt(distance_start) - 1))
    let
      tag = (if should_unitize: "unitized each frame" else: "never unitized")
      found =
        if is_lost: "points lost to overflow" else: &"error of points it moves {error:.1e}"
    echo &"{algebra}: operator carried one hour, {tag}: {found}, " &
      &"largest coefficient {size_worst:.1e}" &
      (if overflow > 0: &", past 1e300 at frame {overflow}" else: "")


when not IS_CONFORMAL:
  func stored32(m: Multivector): Multivector =
    ## Round every coefficient to 32 bits, as frame stores state.
    for b in Basis: result[b] = float(float32(m[b]))


  proc poses() =
    ## Carry motor at 32 bits and at 64 bits through same steps; print pose drift.
    let algebra = "rga" & $DIMENSIONS & "d"
    var points: array[OBJECTS_FRAME, Multivector]
    for point in points.mitems: point = drawPoint(10)
    for should_unitize in [false, true]:
      var
        motor_wide, motor_narrow: Multivector
        checkpoint = 0
      motor_wide[Basis.scalarAnti] = 1
      motor_narrow[Basis.scalarAnti] = 1
      for frame in 1..FRAMES_POSE[^1]:
        let step = drawMove(true, STEP)
        motor_wide = step ⟇ motor_wide
        motor_narrow = step ⟇ motor_narrow
        if should_unitize:
          motor_wide = ^motor_wide
          motor_narrow = ^motor_narrow
        motor_narrow = motor_narrow.stored32
        if frame == FRAMES_POSE[checkpoint]:
          var drift = 0.0
          for point in points:
            let (wide, narrow) = (^point.moved(motor_wide), ^point.moved(motor_narrow))
            for b in Basis: drift = max(drift, abs(wide[b] - narrow[b]) / 10)
          let tag = (if should_unitize: "unitized each frame" else: "never unitized")
          echo &"{algebra}: motor stored at 32 bits, {tag}, after {frame} frames: " &
            &"pose drift over scene size {drift:.1e}"
          inc checkpoint


proc main() =
  ## Run chains, frames and poses; print figures; stop on any bound passed.
  randomize(SEED)
  chains(is_rigid = true, should_unitize = false)
  when IS_CONFORMAL: chains(is_rigid = false, should_unitize = true)
  frames()
  when not IS_CONFORMAL: poses()


when isMainModule: main()
