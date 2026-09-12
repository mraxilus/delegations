## Viewer for sweeps `design/rig` recorded: draws what engine collides.
##
##   Debug view, not illustration.  Every capsule engine was handed is drawn, at
##     world ends engine reports, at radius engine collides on.  Nothing is added
##     for looks and nothing is left out: arm that is not holding is still drawn,
##     because arm that is not holding is still in room.
##   Projection is orthographic on purpose.  Under it capsule's outline is exactly
##     stadium -- round capped line from one end to other, as wide as twice its
##     radius -- so line drawn with round cap *is* shape, not likeness of it.
##     Under perspective it is not, and drawing would quietly stop being true at
##     angles where it mattered most.
##   Painter's order by depth of far end.  Two capsules that run through each
##     other can still come out wrong way round; they are drawn at half weight
##     where they overlap rather than pretending otherwise.
##   Data is read in place through `jsffi`, never copied into Nim values: every
##     copy on JS backend is deep (STYLE.md), and this is read sixty times per
##     second.

{.experimental: "strictFuncs".}

import std/[dom, jsffi, math]


func rig(): JsObject {.importjs: "RIG@".}
func ctxOf(id: cstring): JsObject {.importjs:
  "document.getElementById(#).getContext('2d')".}
func canvasOf(id: cstring): JsObject {.importjs: "document.getElementById(#)".}
func toFixed(x: float; places: int): cstring {.importjs: "(#).toFixed(#)".}
func num(x: JsObject): float {.importjs: "(#)".}
func count(x: JsObject): int {.importjs: "(#).length".}
func text(x: JsObject): cstring {.importjs: "(#)".}
func truth(x: JsObject): bool {.importjs: "(#)".}


func styleOf(name: cstring): cstring {.importjs:
  "getComputedStyle(document.documentElement).getPropertyValue(#).trim()".}
  ## Colours come from page's own custom properties rather than being written
  ## twice.  `draw/style` names same four for arms, so arm here and arm on
  ## reference page are one arm to reader, and dark scheme moves both together.

proc inkOf(side, who: int): cstring =
  ## Hue is side, shade is whose: plain for follow, deep for lead.
  const NAMES = [[cstring"--left-deep", cstring"--left"],
                 [cstring"--right-deep", cstring"--right"]]
  styleOf(NAMES[side][who])

const
  NEAR = 5.0 * PI / 180.0   ## Within this of an end, joint reads as spent.
  DOFS = [cstring"extend", cstring"across", cstring"twist",
          cstring"bend", cstring"wrist"]
  SIDES = [cstring"left", cstring"right"]
  WHOSE = [cstring"lead", cstring"follow"]

var
  az = 0.6      ## Camera round world's up, radians.
  el = 0.18     ## And tilt above floor.
  zoom = 1.0
  lift = 0.95   ## Height camera looks at, metres.
  mid: array[3, float] = [0.0, 0.0, 0.95] ## Middle of what this sweep covers.
  reach = 1.2   ## And half of how far it spreads, so view frames it.
  pick = 0      ## Which sweep.
  frame = 0     ## Which moment of it.
  playing = true
  dragging = false
  lastX, lastY = 0.0


proc sweep(): JsObject = rig().sweeps[pick]
proc moments(): int = count(sweep().at)
proc bars(): int = count(sweep().rad)


type Spot = tuple[x, y, z: float] ## One point in world, metres, z up.

proc seen(p: Spot): tuple[x, y, d: float] =
  ## Project one world point: screen across, screen down, and depth toward eye.
  ##   Orthographic, so scale does not fall off with depth and capsule's outline
  ##     stays exactly stadium however far away it is.
  ##   Screen's down is world's up negated: canvas counts y downward, so point
  ##     higher off floor has to come out smaller.  Signed other way, floor grid
  ##     draws above dancers standing on it.
  let
    (ca, sa) = (cos(az), sin(az))
    (ce, se) = (cos(el), sin(el))
    (x, y, z) = (p.x - mid[0], p.y - mid[1], p.z - mid[2])
  (x: -sa * x + ca * y,
   y: ca * se * x + sa * se * y - ce * z,
   d: ca * ce * x + sa * ce * y + se * z)


proc ends(i, at: int): tuple[a, z: Spot] =
  ## Capsule `i`'s two world ends at moment `at`.
  let
    row = sweep().p[at]
    k = i * 6
  ((x: num(row[k]), y: num(row[k + 1]), z: num(row[k + 2])),
   (x: num(row[k + 3]), y: num(row[k + 4]), z: num(row[k + 5])))


proc paint() =
  let
    cv = canvasOf("view")
    ctx = ctxOf("view")
    w = num(cv.width)
    h = num(cv.height)
    scale = min(w, h) / (2.2 * reach) * zoom
    cx = w / 2.0
    cy = h / 2.0
  discard ctx.clearRect(0, 0, w, h)

  # Floor, so height and distance have something to be read against.
  ctx.lineWidth = 1.0.toJs
  ctx.strokeStyle = styleOf("--rule").toJs
  let span = 1.5
  var g = -span
  while g <= span + 0.001:
    for way in 0 .. 1:
      let
        a: Spot = (if way == 0: (mid[0] + g, mid[1] - span, 0.0)
                   else: (mid[0] - span, mid[1] + g, 0.0))
        b: Spot = (if way == 0: (mid[0] + g, mid[1] + span, 0.0)
                   else: (mid[0] + span, mid[1] + g, 0.0))
        pa = seen(a)
        pb = seen(b)
      discard ctx.beginPath()
      discard ctx.moveTo(cx + pa.x * scale, cy + pa.y * scale)
      discard ctx.lineTo(cx + pb.x * scale, cy + pb.y * scale)
      discard ctx.stroke()
    g += 0.5

  # Capsules, furthest first.  Order is by far end's depth: near enough for
  # bodies that do not pass through one another, and they are filtered not to.
  var order: seq[(float, int)]
  for i in 0 ..< bars():
    let (a, z) = ends(i, frame)
    order.add (max(seen(a).d, seen(z).d), i)
  for pass in 0 ..< order.len:
    for i in 0 ..< order.len - 1 - pass:
      if order[i][0] > order[i + 1][0]:
        swap(order[i], order[i + 1])

  ctx.lineCap = cstring("round").toJs
  for (_, i) in order:
    let
      tag = sweep().tag[i]
      mark = num(tag[2]).int
      (a, z) = ends(i, frame)
      pa = seen(a)
      pz = seen(z)
      r = num(sweep().rad[i])
    ctx.lineWidth = (2.0 * r * scale).toJs
    ctx.strokeStyle = (if mark == 0: styleOf("--rule-strong")
                       else: inkOf(num(tag[1]).int, num(tag[0]).int)).toJs
    discard ctx.beginPath()
    discard ctx.moveTo(cx + pa.x * scale, cy + pa.y * scale)
    discard ctx.lineTo(cx + pz.x * scale, cy + pz.y * scale)
    discard ctx.stroke()

  # Where hands are joined, and how far engine has pulled them apart.
  let grip = sweep().g[frame]
  for k in 0 ..< count(grip) div 3:
    let p = seen((x: num(grip[k * 3]), y: num(grip[k * 3 + 1]),
                  z: num(grip[k * 3 + 2])))
    ctx.fillStyle = styleOf("--ink").toJs
    discard ctx.beginPath()
    discard ctx.arc(cx + p.x * scale, cy + p.y * scale, 3.0, 0.0, 2.0 * PI)
    discard ctx.fill()


proc readout() =
  ## Every joint of every arm, beside range it is held between.
  let
    sw = sweep()
    js = sw.j[frame]
  var html = cstring""
  for a in 0 ..< count(sw.arm):
    let
      who = num(sw.arm[a][0]).int
      side = num(sw.arm[a][1]).int
    html = html & cstring"<div class='arm'><h4><i style='background:" &
      inkOf(side, who) & cstring"'></i>" & WHOSE[who] & cstring" " &
      SIDES[side] & cstring"</h4>"
    for d in 0 ..< DOFS.len:
      let
        k = a * DOFS.len + d
        v = num(js[k])
        lo = num(sw.lo[k])
        hi = num(sw.hi[k])
        span = (if hi - lo > 1e-9: hi - lo else: 1.0)
        at = (v - lo) / span
        spent = v <= lo + NEAR or v >= hi - NEAR
      html = html & cstring"<div class='dof" &
        (if spent: cstring" spent" else: cstring"") & cstring"'><span>" &
        DOFS[d] & cstring"</span><div class='track'><b style='left:" &
        toFixed(max(0.0, min(1.0, at)) * 100.0, 1) & cstring"%'></b></div><em>" &
        toFixed(v * 180.0 / PI, 0) & cstring"°</em><u>" &
        toFixed(lo * 180.0 / PI, 0) & cstring"…" &
        toFixed(hi * 180.0 / PI, 0) & cstring"</u></div>"
    html = html & cstring"</div>"
  document.getElementById("reads").innerHTML = html


proc caption() =
  let
    sw = sweep()
    turned = num(sw.at[frame])
  document.getElementById("where").innerHTML =
    cstring"<b>" & toFixed(turned, 2) & cstring"</b> turns · stood <b>" &
    toFixed(num(sw.apart), 2) & cstring"</b> m apart"
  document.getElementById("verdict").innerHTML =
    (if truth(sw.stopped):
       cstring"Stops at <b>" & toFixed(num(sw.turns), 2) & cstring"</b> turns: " &
         text(sw.says)
     else:
       cstring"Nothing stops it inside the turns tried.")


proc fit() =
  ## Frame this sweep to what it holds, over every moment of it, so view does
  ## not jump as couple turn and nothing wanders off edge part way through.
  let sw = sweep()
  var lo = [1e9, 1e9, 1e9]
  var hi = [-1e9, -1e9, -1e9]
  for t in 0 ..< moments():
    let row = sw.p[t]
    for k in 0 ..< count(row) div 3:
      for d in 0 .. 2:
        let v = num(row[k * 3 + d])
        lo[d] = min(lo[d], v)
        hi[d] = max(hi[d], v)
  ## Framed to capsules, not to floor.  Rig is trunk upward and has no legs, so
  ## forcing floor into frame spends half of it on gap where legs would be;
  ## grid is still drawn at nought and comes into view on zooming out.
  for d in 0 .. 2:
    mid[d] = (lo[d] + hi[d]) / 2.0
  reach = max(max(hi[0] - lo[0], hi[1] - lo[1]), hi[2] - lo[2]) / 2.0 + 0.15

proc show() =
  paint()
  readout()
  caption()
  let bar = canvasOf("scrub")
  bar.value = frame.toJs


proc size() =
  let cv = canvasOf("view")
  cv.width = (num(cv.clientWidth) * 2.0).toJs
  cv.height = (num(cv.clientHeight) * 2.0).toJs
  show()


proc tick() =
  if playing and moments() > 1:
    frame = (frame + 1) mod moments()
    show()

proc choose() =
  pick = num(canvasOf("pick").value).int
  frame = 0
  fit()
  canvasOf("scrub").max = (moments() - 1).toJs
  show()


proc start() =
  # Sweep picker, named by hold and band.
  var opts = cstring""
  for i in 0 ..< count(rig().sweeps):
    let s = rig().sweeps[i]
    opts = opts & cstring"<option value='" & toFixed(i.float, 0) &
      cstring"'>" & text(s.hold) & cstring" · " & text(s.band) & cstring"</option>"
  document.getElementById("pick").innerHTML = opts
  canvasOf("scrub").max = (moments() - 1).toJs

  document.getElementById("pick").addEventListener("change", proc (e: Event) = choose())
  document.getElementById("play").addEventListener("click", proc (e: Event) =
    playing = not playing
    document.getElementById("play").innerHTML =
      (if playing: cstring"Pause" else: cstring"Play"))
  document.getElementById("scrub").addEventListener("input", proc (e: Event) =
    playing = false
    document.getElementById("play").innerHTML = cstring"Play"
    frame = num(canvasOf("scrub").value).int
    show())

  let cv = canvasOf("view")
  cv.addEventListener(cstring"pointerdown", proc (e: Event) =
    dragging = true
    lastX = num(e.toJs.clientX)
    lastY = num(e.toJs.clientY))
  document.addEventListener("pointerup", proc (e: Event) = dragging = false)
  document.addEventListener("pointermove", proc (e: Event) =
    if dragging:
      let
        x = num(e.toJs.clientX)
        y = num(e.toJs.clientY)
      az += (x - lastX) * 0.01
      el = max(-1.4, min(1.4, el + (y - lastY) * 0.01))
      lastX = x
      lastY = y
      paint())
  cv.addEventListener(cstring"wheel", proc (e: Event) =
    e.preventDefault()
    zoom = max(0.35, min(4.0, zoom * (if num(e.toJs.deltaY) > 0.0: 0.92 else: 1.08)))
    paint())

  fit()
  window.addEventListener("resize", proc (e: Event) = size())
  discard window.setInterval(proc () = tick(), 40)
  size()


when isMainModule:
  window.addEventListener("DOMContentLoaded", proc (e: Event) = start())
