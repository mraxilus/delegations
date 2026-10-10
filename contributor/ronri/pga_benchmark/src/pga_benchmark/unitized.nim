## Time point operations of Lengyel's code in homogeneous form against unitized form:
##   `unitized <output.json>`, run by driver's `unitized` verb.
##   Lengyel's `Unitize` divides point by signed weight and returns `Point3D`, three floats with
##     implicit w = 1, and his operations on that type skip each product with w. Library keeps
##     book's rule, which keeps sign of weight, so this program measures what that rule forgoes.
##   Each pair transcribes scalar path of `TSRigid3D.h` and `TSMotor3D.cpp` into 64-bit floats,
##     as references here are; it copies no code, and counts in each doc are those of that path.
##   Forms and their types are exported, so suites hold each form to its pair and read its C.
##   Three layouts: homogeneous point of four floats, his unitized point of three, and unitized
##     point padded to four, so saved arithmetic shows apart from smaller layout.
##   Two pool sizes: one that cache holds, and one that streams from memory.
##   Each operation runs behind call that optimiser does not inline, and writes its result in
##     place, as return value optimisation of C++ does; returned by value, result passes through
##     temporary whose copy reloads stores callee just made, and that stall swamps arithmetic.
##   Layouts alternate within each pass, rotated pass by pass, `PASSES` times; median of rounds
##     is one pass, and median of passes is figure. Null pair times homogeneous form against
##     itself, so spread of unchanged code stands beside each ratio (Article VII.9).
##
##   Cost: pools of largest size hold about 400 MB; seeded once, never on timed path.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import std/[algorithm, json, math, monotimes, os, random, strformat, times]

import ./report


const
  PASSES = 7  ## Alternating passes per pair; median of passes is figure.
  SEED = 0  ## Seed of pools, so every run times same operands.
  SIZES = [1024, 1_048_576]  ## Objects per pool: cache-resident, then streamed from memory.
  ROUNDS_FEWEST = 5  ## Rounds of largest pool; smaller pools take more, to time similar spans.
  ALIGNMENT = 64  ## Bytes of cache line each pool starts on.


type
  PointHomogeneous* {.byref.} = object  ## Define point x e1 + y e2 + z e3 + w e4, as `FlatPoint3D`.
    x*, y*, z*, w*: float
  PointUnitized* {.byref.} = object  ## Define point with implicit w = 1, as `Point3D`.
    x*, y*, z*: float
  PointPadded* {.byref.} = object  ## Define unitized point padded to four floats; pad unread.
    x*, y*, z*, pad*: float
  Line* {.byref.} = object  ## Define line: direction v on e41 e42 e43, moment m on e23 e31 e12.
    vx*, vy*, vz*, mx*, my*, mz*: float
  Plane* {.byref.} = object  ## Define plane x e423 + y e431 + z e412 + w e321.
    x*, y*, z*, w*: float
  Motor* {.byref.} = object  ## Define motor: v on e41 e42 e43 𝟙, m on e23 e31 e12 𝟏.
    vx*, vy*, vz*, vw*, mx*, my*, mz*, mw*: float
  Unitized* = PointUnitized | PointPadded  ## Define either layout of unitized point.



#[ Operations ]#

func join*(p, q: PointHomogeneous, line: var Line) {.noinline.} =
  ## Join two points into line, i.e. 𝐩 ∧ 𝐪; 12 mul, 6 sub.
  line = Line(
    vx: p.w * q.x - p.x * q.w, vy: p.w * q.y - p.y * q.w, vz: p.w * q.z - p.z * q.w,
    mx: p.y * q.z - p.z * q.y, my: p.z * q.x - p.x * q.z, mz: p.x * q.y - p.y * q.x,
  )


func join*[U: Unitized](p, q: U, line: var Line) {.noinline.} =
  ## Join two unitized points into line, i.e. 𝐩 ∧ 𝐪 with w = 1; 6 mul, 6 sub.
  line = Line(
    vx: q.x - p.x, vy: q.y - p.y, vz: q.z - p.z,
    mx: p.y * q.z - p.z * q.y, my: p.z * q.x - p.x * q.z, mz: p.x * q.y - p.y * q.x,
  )


func join*(l: Line, p: PointHomogeneous, plane: var Plane) {.noinline.} =
  ## Join line and point into plane, i.e. 𝐥 ∧ 𝐩; 12 mul, 8 add.
  plane = Plane(
    x: l.vy * p.z - l.vz * p.y + l.mx * p.w,
    y: l.vz * p.x - l.vx * p.z + l.my * p.w,
    z: l.vx * p.y - l.vy * p.x + l.mz * p.w,
    w: -l.mx * p.x - l.my * p.y - l.mz * p.z,
  )


func join*[U: Unitized](l: Line, p: U, plane: var Plane) {.noinline.} =
  ## Join line and unitized point into plane, i.e. 𝐥 ∧ 𝐩 with w = 1; 9 mul, 8 add.
  plane = Plane(
    x: l.vy * p.z - l.vz * p.y + l.mx,
    y: l.vz * p.x - l.vx * p.z + l.my,
    z: l.vx * p.y - l.vy * p.x + l.mz,
    w: -l.mx * p.x - l.my * p.y - l.mz * p.z,
  )


func meet*(p: PointHomogeneous, g: Plane): float {.noinline.} =
  ## Meet point and plane, i.e. 𝐩 ∨ 𝐠, weighted distance; 4 mul, 3 add.
  p.x * g.x + p.y * g.y + p.z * g.z + p.w * g.w


func meet*[U: Unitized](p: U, g: Plane): float {.noinline.} =
  ## Meet unitized point and plane, i.e. 𝐩 ∨ 𝐠 with w = 1, signed distance; 3 mul, 3 add.
  p.x * g.x + p.y * g.y + p.z * g.z + g.w


func antisupport*(p: PointHomogeneous, plane: var Plane) {.noinline.} =
  ## Get plane through point, normal to its direction from origin; 6 mul, 2 add.
  plane = Plane(x: -p.x * p.w, y: -p.y * p.w, z: -p.z * p.w, w: p.x * p.x + p.y * p.y + p.z * p.z)


func antisupport*[U: Unitized](p: U, plane: var Plane) {.noinline.} =
  ## Get plane through unitized point, normal to its direction from origin; 3 mul, 2 add.
  plane = Plane(x: -p.x, y: -p.y, z: -p.z, w: p.x * p.x + p.y * p.y + p.z * p.z)


func transform*(p: PointHomogeneous, q: Motor, moved: var PointHomogeneous) {.noinline.} =
  ## Move point by motor, i.e. 𝐐 ⟇ 𝐩 ⟇ 𝐐̰; 25 mul, 18 add.
  let
    ax = q.vy * p.z - q.vz * p.y + q.mx * p.w
    ay = q.vz * p.x - q.vx * p.z + q.my * p.w
    az = q.vx * p.y - q.vy * p.x + q.mz * p.w
    weighted = q.mw * p.w
    ux = q.vy * az - q.vz * ay + ax * q.vw - q.vx * weighted
    uy = q.vz * ax - q.vx * az + ay * q.vw - q.vy * weighted
    uz = q.vx * ay - q.vy * ax + az * q.vw - q.vz * weighted
  moved = PointHomogeneous(x: p.x + 2 * ux, y: p.y + 2 * uy, z: p.z + 2 * uz, w: p.w)


func transform*[U: Unitized](p: U, q: Motor, moved: var U) {.noinline.} =
  ## Move unitized point by motor, i.e. 𝐐 ⟇ 𝐩 ⟇ 𝐐̰ with w = 1; 21 mul, 18 add.
  let
    ax = q.vy * p.z - q.vz * p.y + q.mx
    ay = q.vz * p.x - q.vx * p.z + q.my
    az = q.vx * p.y - q.vy * p.x + q.mz
    ux = q.vy * az - q.vz * ay + ax * q.vw - q.vx * q.mw
    uy = q.vz * ax - q.vx * az + ay * q.vw - q.vy * q.mw
    uz = q.vx * ay - q.vy * ax + az * q.vw - q.vz * q.mw
  moved.x = p.x + 2 * ux
  moved.y = p.y + 2 * uy
  moved.z = p.z + 2 * uz


func unitizeBook*(p: PointHomogeneous, unit: var PointHomogeneous) {.noinline.} =
  ## Unitize point by size of weight, as book does, so sign of w stays; 1 abs, 1 div, 4 mul.
  let n = 1 / abs(p.w)
  unit = PointHomogeneous(x: p.x * n, y: p.y * n, z: p.z * n, w: p.w * n)


func unitizeCode*[U: Unitized](p: PointHomogeneous, unit: var U) {.noinline.} =
  ## Unitize point by signed weight, as Lengyel's code does, so w = 1 and drops; 1 div, 3 mul.
  let n = 1 / p.w
  unit.x = p.x * n
  unit.y = p.y * n
  unit.z = p.z * n



#[ Pools ]#

type
  Pool[T] = object  ## Define objects of one type, first on cache line, so no layout starts split.
    storage: seq[byte]
    items: ptr UncheckedArray[T]


proc initPool[T](count: int): Pool[T] =
  ## Make pool of count objects on cache line; proc, since its address is allocator's choice.
  result.storage = newSeq[byte](count * sizeof(T) + ALIGNMENT)
  let address = cast[uint](result.storage[0].addr)
  result.items = cast[ptr UncheckedArray[T]](
    (address + uint(ALIGNMENT - 1)) and not uint(ALIGNMENT - 1)
  )


template `[]`[T](pool: Pool[T], index: int): var T =
  ## Get object at index of pool.
  pool.items[index]


type
  Pools = object  ## Define operands and results of every operation at one size.
    homogeneous, homogeneous_out: Pool[PointHomogeneous]
    unitized, unitized_out: Pool[PointUnitized]
    padded, padded_out: Pool[PointPadded]
    lines, lines_out: Pool[Line]
    planes, planes_out: Pool[Plane]
    motors: Pool[Motor]
    distances: Pool[float]


proc initPools(count: int): Pools =
  ## Draw operands: weight near one, as bench draws it, and same points in every layout.
  result = Pools(
    homogeneous: initPool[PointHomogeneous](count),
    homogeneous_out: initPool[PointHomogeneous](count),
    unitized: initPool[PointUnitized](count),
    unitized_out: initPool[PointUnitized](count),
    padded: initPool[PointPadded](count),
    padded_out: initPool[PointPadded](count),
    lines: initPool[Line](count),
    lines_out: initPool[Line](count),
    planes: initPool[Plane](count),
    planes_out: initPool[Plane](count),
    motors: initPool[Motor](count),
    distances: initPool[float](count),
  )
  for i in 0..<count:
    let
      weight = gauss(1.0, 0.25)
      (x, y, z) = (gauss(0.0, 1.0), gauss(0.0, 1.0), gauss(0.0, 1.0))
      angle = rand(PI)
    result.homogeneous[i] = PointHomogeneous(x: x, y: y, z: z, w: weight)
    result.unitized[i] = PointUnitized(x: x / weight, y: y / weight, z: z / weight)
    result.padded[i] = PointPadded(x: x / weight, y: y / weight, z: z / weight)
    result.lines[i] = Line(
      vx: gauss(0.0, 1.0), vy: gauss(0.0, 1.0), vz: gauss(0.0, 1.0),
      mx: gauss(0.0, 1.0), my: gauss(0.0, 1.0), mz: gauss(0.0, 1.0),
    )
    result.planes[i] = Plane(
      x: gauss(0.0, 1.0), y: gauss(0.0, 1.0), z: gauss(0.0, 1.0), w: gauss(0.0, 1.0)
    )
    result.motors[i] = Motor(vx: sin(angle), vw: cos(angle), mx: 0.1, my: 0.2, mz: 0.3)



#[ Timing ]#

type
  Layout {.pure.} = enum  ## Define what one figure of row times.
    Homogeneous, Null, Unitized, Padded
  Row = object  ## Define one operation: name, multiplies its unitized form saves, figures.
    name: string
    saved: int
    figures: array[Layout, seq[float]]


template timed(count, rounds: int, body: untyped): float =
  ## Time body over every slot of pool `rounds` times; median nanoseconds per object.
  ##   Operands pair slot i with slot j = (7i + 3) mod count, as bench pairs them.
  var spans = newSeq[int64](rounds)
  for round in 0..<rounds:
    let started = getMonoTime()
    for i {.inject.} in 0..<count:
      let j {.inject.} = (i * 7 + 3) mod count
      body
    spans[round] = (getMonoTime() - started).inNanoseconds
  spans.sort
  float(spans[rounds div 2]) / float(count)


proc pass(pools: var Pools, count, rounds, order: int, rows: var seq[Row]) =
  ## Time every operation once in each layout, layouts rotated by order.
  template each(index: int, name_row: string, saved_row: int, h, u, p: untyped) =
    if rows.len <= index: rows.add Row(name: name_row, saved: saved_row)
    for step in 0..3:
      case Layout((step + order) mod 4)
      of Layout.Homogeneous: rows[index].figures[Layout.Homogeneous].add timed(count, rounds, h)
      of Layout.Null: rows[index].figures[Layout.Null].add timed(count, rounds, h)
      of Layout.Unitized: rows[index].figures[Layout.Unitized].add timed(count, rounds, u)
      of Layout.Padded: rows[index].figures[Layout.Padded].add timed(count, rounds, p)
  each(0, "join two points", 6,
    join(pools.homogeneous[i], pools.homogeneous[j], pools.lines_out[i]),
    join(pools.unitized[i], pools.unitized[j], pools.lines_out[i]),
    join(pools.padded[i], pools.padded[j], pools.lines_out[i]))
  each(1, "join line and point", 3,
    join(pools.lines[i], pools.homogeneous[j], pools.planes_out[i]),
    join(pools.lines[i], pools.unitized[j], pools.planes_out[i]),
    join(pools.lines[i], pools.padded[j], pools.planes_out[i]))
  each(2, "meet point and plane", 1,
    (pools.distances[i] = meet(pools.homogeneous[i], pools.planes[j])),
    (pools.distances[i] = meet(pools.unitized[i], pools.planes[j])),
    (pools.distances[i] = meet(pools.padded[i], pools.planes[j])))
  each(3, "antisupport", 3,
    antisupport(pools.homogeneous[i], pools.planes_out[i]),
    antisupport(pools.unitized[i], pools.planes_out[i]),
    antisupport(pools.padded[i], pools.planes_out[i]))
  each(4, "transform by motor", 4,
    transform(pools.homogeneous[i], pools.motors[j], pools.homogeneous_out[i]),
    transform(pools.unitized[i], pools.motors[j], pools.unitized_out[i]),
    transform(pools.padded[i], pools.motors[j], pools.padded_out[i]))
  each(5, "unitize, book against code", -1,
    unitizeBook(pools.homogeneous[i], pools.homogeneous_out[i]),
    unitizeCode(pools.homogeneous[i], pools.unitized_out[i]),
    unitizeCode(pools.homogeneous[i], pools.padded_out[i]))


func median(figures: seq[float]): float =
  ## Get median of figures.
  var sorted = figures
  sorted.sort
  sorted[sorted.len div 2]



#[ Entry Point ]#

proc main(): int =
  ## Time every pair at every size, print medians and ratios, write take as JSON, then sink.
  randomize(SEED)
  var
    sink = 0.0
    sizes = newJObject()
  for count in SIZES:
    var
      pools = initPools(count)
      rows: seq[Row]
    let rounds = max(ROUNDS_FEWEST, ROUNDS_FEWEST * SIZES[^1] div (count * 128))
    for order in 0..<PASSES: pools.pass(count, rounds, order, rows)
    echo &"{count} objects, {rounds} rounds, {PASSES} passes; median ns per object"
    echo "operation                    saved  homog   null unitized padded  ×unit  ×pad ×null"
    var named = newJObject()
    for row in rows:
      let
        homogeneous = row.figures[Layout.Homogeneous].median
        null = row.figures[Layout.Null].median
        unitized = row.figures[Layout.Unitized].median
        padded = row.figures[Layout.Padded].median
      echo &"{row.name:<28} {row.saved:5} {homogeneous:6.2f} {null:6.2f} {unitized:8.2f} " &
        &"{padded:6.2f} {unitized / homogeneous:6.2f} {padded / homogeneous:5.2f} " &
        &"{null / homogeneous:5.2f}"
      named[row.name] = %*{
        "saved": row.saved, "homogeneous": homogeneous, "null": null, "unitized": unitized,
        "padded": padded,
      }
    sizes[$count] = %*{"rounds": rounds, "rows": named}
    for i in 0..<count:
      sink += pools.lines_out[i].vx + pools.planes_out[i].w + pools.distances[i] +
        pools.homogeneous_out[i].x + pools.unitized_out[i].y + pools.padded_out[i].z
  echo &"sink {sink:.6f}"
  var taken = takenNow()
  taken.delete("pga")  # program imports no library code, so no library commit bears on it
  taken["passes"] = %PASSES
  if paramCount() >= 1:
    writeFile(paramStr(1), pretty(%*{
      "schema": SCHEMA, "kind": "unitized", "taken": taken, "sizes": sizes,
    }) & "\n")
  0


when isMainModule:
  quit main()
