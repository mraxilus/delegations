## Viewer for sweeps and stills `design/rig` recorded: draws what engine collides.
##
##   Debug view, not illustration.  Every capsule engine was handed is drawn, at
##     world ends engine reports, at radius engine collides on.  Nothing is added
##     for looks and nothing is left out: arm that is not holding is still drawn,
##     because arm that is not holding is still in room.
##   Projection, painter's order and what each capsule is put down as are
##     `drawn`'s, pure and held to laws natively; this file only puts ink on
##     canvas in that order.
##   One list of entries: every still of reference first, in page's order, then
##     every sweep.  Stage shows one; every still is also drawn small beside its
##     own cell of reference, and clicking cell puts it on stage.  Architect: lay
##     reference and sim side by side, with next and previous.
##   Data is read in place through `jsffi`, never copied into Nim values: every
##     copy on JS backend is deep (STYLE.md), and this is read sixty times per
##     second.

{.experimental: "strictFuncs".}

import std/[dom, jsffi, math, strutils]

import ./drawn


func rig(): JsObject {.importjs: "RIG@".}
func ctxOf(id: cstring): JsObject {.importjs:
  "document.getElementById(#).getContext('2d')".}
func canvasOf(id: cstring): JsObject {.importjs: "document.getElementById(#)".}
func contextOf(cv: JsObject): JsObject {.importjs: "(#).getContext('2d')".}
func toFixed(x: float; places: int): cstring {.importjs: "(#).toFixed(#)".}
func num(x: JsObject): float {.importjs: "(#)".}
func count(x: JsObject): int {.importjs: "(#).length".}
func text(x: JsObject): cstring {.importjs: "(#)".}
func truth(x: JsObject): bool {.importjs: "(#)".}
func has(x: JsObject; name: cstring): bool {.importjs: "((#)[#] !== undefined)".}
func joined(a, b: JsObject): JsObject {.importjs: "(#).concat(#)".}
func entriesOn(e: Event): cstring {.importjs:
  "(#).currentTarget.getAttribute('data-entries')".}
  ## Read off cell clicked at time of click: closure made in loop over cells
  ## saw every cell's number as last one's, and every click chose D7.


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
  NEAR = 5.0 * PI / 180.0   ## Within this of either end, joint reads as spent.
  DOFS = [cstring"extend", cstring"across", cstring"twist",
          cstring"bend", cstring"wrist"]
  SIDES = [cstring"left", cstring"right"]
  WHOSE = [cstring"lead", cstring"follow"]
  AZ = 0.6      ## Camera round world's up at start, radians.
  EL = 0.18     ## And tilt above floor.

var
  az = AZ
  el = EL
  zoom = 1.0
  framing: Framing = ([0.0, 0.0, 0.95], 1.2)
  entries: JsObject ## Every still, then every sweep.
  pick = 0      ## Which entry.
  frame = 0     ## Which moment of it.
  playing = true
  dragging = false
  lastX, lastY = 0.0
  cardOf: seq[cstring]  ## Reference cell each entry belongs to, or empty.
  cellOf: seq[Element]  ## And cell itself, or nil.


proc entry(i: int): JsObject = entries[i]
proc sweep(): JsObject = entry(pick)
proc momentsOf(e: JsObject): int = (if has(e, "at"): count(e.at) else: 0)
proc moments(): int = momentsOf(sweep())
proc isStill(e: JsObject): bool = has(e, "key")


proc ends(e: JsObject; i, at: int): tuple[a, z: Spot] =
  ## Capsule `i`'s two world ends at moment `at` of entry `e`.
  let
    row = e.p[at]
    k = i * 6
  ((x: num(row[k]), y: num(row[k + 1]), z: num(row[k + 2])),
   (x: num(row[k + 3]), y: num(row[k + 4]), z: num(row[k + 5])))


proc paintOn(cv: JsObject; e: JsObject; at: int; az, el, zoom: float;
             f: Framing) =
  ## Draw one moment of one entry on one canvas, seen from one place.
  let
    ctx = contextOf(cv)
    w = num(cv.width)
    h = num(cv.height)
    scale = min(w, h) / (2.2 * f.reach) * zoom
    cx = w / 2.0
    cy = h / 2.0
  discard ctx.clearRect(0, 0, w, h)
  if momentsOf(e) == 0:
    return

  # Floor, so height and distance have something to be read against.
  ctx.lineWidth = 1.0.toJs
  ctx.strokeStyle = styleOf("--rule").toJs
  let span = 1.5
  var g = -span
  while g <= span + 0.001:
    for way in 0 .. 1:
      let
        a: Spot = (if way == 0: (f.mid[0] + g, f.mid[1] - span, 0.0)
                   else: (f.mid[0] - span, f.mid[1] + g, 0.0))
        b: Spot = (if way == 0: (f.mid[0] + g, f.mid[1] + span, 0.0)
                   else: (f.mid[0] + span, f.mid[1] + g, 0.0))
        pa = seen(a, az, el, f)
        pb = seen(b, az, el, f)
      discard ctx.beginPath()
      discard ctx.moveTo(cx + pa.x * scale, cy + pa.y * scale)
      discard ctx.lineTo(cx + pb.x * scale, cy + pb.y * scale)
      discard ctx.stroke()
    g += 0.5

  # Where each dancer faces, on screen: body is lit from its own front, since
  # capsule cannot say -- torso's section is symmetric front to back and head
  # is sphere.  Facing is unit vector, and projection is linear, so its screen
  # image is difference of two projected points.
  let look = e.f[at]
  var facing: array[2, Seen]
  for who in 0 .. 1:
    let
      k = who * 4
      here: Spot = (num(look[k]), num(look[k + 1]), 0.0)
      ahead: Spot = (here.x + num(look[k + 2]), here.y + num(look[k + 3]), 0.0)
      (ph, pf) = (seen(here, az, el, f), seen(ahead, az, el, f))
    facing[who] = (x: pf.x - ph.x, y: pf.y - ph.y, d: pf.d - ph.d)
  let
    shade = $styleOf("--body-shade")
    lit = $styleOf("--body-lit")

  # Capsules, furthest first, in order `drawn` gives.
  var caps: seq[tuple[a, z: Spot]]
  for i in 0 ..< count(e.rad):
    caps.add ends(e, i, at)
  ctx.lineCap = cstring("round").toJs
  for piece in drawOrder(caps, az, el, f):
    let
      i = piece.cap
      tag = e.tag[i]
      mark = num(tag[2]).int
      (a, z) = (piece.a, piece.z)
      pa = seen(a, az, el, f)
      pz = seen(z, az, el, f)
      r = num(e.rad[i])
    var ink: JsObject
    if mark == 0 or mark == 4:
      # Trunk and girdle: light across from back edge to front edge, along
      # facing's image on screen, through piece's middle.
      let
        fore = facing[num(tag[0]).int]
        across = sqrt(fore.x * fore.x + fore.y * fore.y)
        (mx, my) = (cx + (pa.x + pz.x) / 2.0 * scale, cy + (pa.y + pz.y) / 2.0 * scale)
      if across < 0.02:
        ink = cstring(mixHex(shade, lit, litAt(fore, 0.0))).toJs
      else:
        let
          (ux, uy) = (fore.x / across * r * scale, fore.y / across * r * scale)
          grad = ctx.createLinearGradient(mx - ux, my - uy, mx + ux, my + uy)
        for (stop, s) in [(0.0, -1.0), (0.5, 0.0), (1.0, 1.0)]:
          discard grad.addColorStop(stop, cstring(mixHex(shade, lit, litAt(fore, s))))
        ink = grad
    else:
      ink = inkOf(num(tag[1]).int, num(tag[0]).int).toJs
    case drawnAs(a, z)
    of Drawn.Stroke:
      ctx.lineWidth = (2.0 * r * scale).toJs
      ctx.strokeStyle = ink
      discard ctx.beginPath()
      discard ctx.moveTo(cx + pa.x * scale, cy + pa.y * scale)
      discard ctx.lineTo(cx + pz.x * scale, cy + pz.y * scale)
      discard ctx.stroke()
    of Drawn.Disc:
      ctx.fillStyle = ink
      discard ctx.beginPath()
      discard ctx.arc(cx + pa.x * scale, cy + pa.y * scale, r * scale, 0.0, 2.0 * PI)
      discard ctx.fill()

  # Where hands are joined, and how far engine has pulled them apart.
  let grip = e.g[at]
  for k in 0 ..< count(grip) div 3:
    let p = seen((x: num(grip[k * 3]), y: num(grip[k * 3 + 1]),
                  z: num(grip[k * 3 + 2])), az, el, f)
    ctx.fillStyle = styleOf("--ink").toJs
    discard ctx.beginPath()
    discard ctx.arc(cx + p.x * scale, cy + p.y * scale, 3.0, 0.0, 2.0 * PI)
    discard ctx.fill()


proc paint() =
  paintOn(canvasOf("view"), sweep(), frame, az, el, zoom, framing)


proc readout() =
  ## Every joint of every arm, beside range it is held between.
  let sw = sweep()
  var html = cstring""
  if moments() > 0:
    let js = sw.j[frame]
    for a in 0 ..< count(sw.arm):
      let
        who = num(sw.arm[a][0]).int
        side = num(sw.arm[a][1]).int
      # Label, not heading: heading would take serif face (Article X.8).
      html = html & cstring"<div class='arm'><p class='who'><i style='background:" &
        inkOf(side, who) & cstring"'></i>" & WHOSE[who] & cstring" " &
        SIDES[side] & cstring"</p>"
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
  let sw = sweep()
  if isStill(sw):
    document.getElementById("where").innerHTML =
      (if moments() > 0:
         cstring"<b>" & toFixed(num(sw.turns), 2) & cstring"</b> turns · stood <b>" &
           toFixed(num(sw.apart), 2) & cstring"</b> m apart"
       else:
         cstring"<b>" & toFixed(num(sw.turns), 2) & cstring"</b> turns · no pose holds")
    document.getElementById("verdict").innerHTML =
      (if moments() > 0:
         cstring"Holds, standing still: wound there from rest with hands lifted, " &
           cstring"then left to stand."
       else:
         cstring"No pose holds here from any distance the couple may stand at.")
  else:
    let turned = num(sw.at[frame])
    document.getElementById("where").innerHTML =
      cstring"<b>" & toFixed(turned, 2) & cstring"</b> turns · stood <b>" &
      toFixed(num(sw.apart), 2) & cstring"</b> m apart"
    document.getElementById("verdict").innerHTML =
      (if truth(sw.stopped):
         cstring"Stops at <b>" & toFixed(num(sw.turns), 2) & cstring"</b> turns: " &
           text(sw.says)
       else:
         cstring"Nothing stops it inside the turns tried.")


proc framingOf(e: JsObject): Framing =
  ## Frame one entry to what it holds, over every moment of it, so view does
  ## not jump as couple turn and nothing wanders off edge part way through.
  var lo = [1e9, 1e9, 1e9]
  var hi = [-1e9, -1e9, -1e9]
  for t in 0 ..< momentsOf(e):
    let row = e.p[t]
    for k in 0 ..< count(row) div 3:
      for d in 0 .. 2:
        let v = num(row[k * 3 + d])
        lo[d] = min(lo[d], v)
        hi[d] = max(hi[d], v)
  ## Framed to capsules, not to floor.  Rig is trunk upward and has no legs, so
  ## forcing floor into frame spends half of it on gap where legs would be;
  ## grid is still drawn at nought and comes into view on zooming out.
  for d in 0 .. 2:
    result.mid[d] = (lo[d] + hi[d]) / 2.0
  result.reach = max(max(hi[0] - lo[0], hi[1] - lo[1]), hi[2] - lo[2]) / 2.0 + 0.15

proc fit() =
  if moments() > 0:
    framing = framingOf(sweep())


proc reference() =
  ## Reference's own drawing of this entry's cell beside stage, and cell marked.
  for i, cell in cellOf:
    if cell != nil:
      cell.classList.remove(cstring"picked")
  let cell = cellOf[pick]
  if cell == nil:
    document.getElementById("ref").innerHTML = cstring""
    return
  cell.classList.add(cstring"picked")
  let
    art = cell.querySelector(".art")
    cap = cell.querySelector("figcaption")
  document.getElementById("ref").innerHTML =
    cstring"<div class='art'>" & art.innerHTML & cstring"</div>" & cap.outerHTML

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


proc thumbs() =
  ## Every still drawn small beside its own cell, from one fixed place.
  for node in document.querySelectorAll("canvas.thumb"):
    let
      cv = node.toJs
      k = parseInt($node.getAttribute("data-entry"))
      e = entry(k)
      w = num(cv.clientWidth) * 2.0
    cv.width = w.toJs
    cv.height = w.toJs
    if momentsOf(e) > 0:
      paintOn(cv, e, 0, AZ, EL, 1.0, framingOf(e))


proc tick() =
  if playing and moments() > 1:
    frame = (frame + 1) mod moments()
    show()

proc choose(i: int) =
  pick = ((i mod count(entries)) + count(entries)) mod count(entries)
  frame = 0
  fit()
  canvasOf("pick").value = toFixed(pick.float, 0).toJs
  canvasOf("scrub").max = (max(0, moments() - 1)).toJs
  document.getElementById("transport").toJs.hidden = (moments() <= 1).toJs
  reference()
  show()


proc start() =
  entries = joined(rig().stills, rig().sweeps)
  # Which cell of reference each entry belongs to, read off page itself.
  for i in 0 ..< count(entries):
    cardOf.add cstring""
    cellOf.add nil
  for node in document.querySelectorAll("figure[data-entries]"):
    let cell = Element(node)
    for word in ($cell.getAttribute("data-entries")).split(' '):
      if word.len == 0: continue
      let k = parseInt(word)
      cardOf[k] = cell.getAttribute("data-id")
      cellOf[k] = cell
    cell.addEventListener("click", proc (e: Event) =
      let first = ($entriesOn(e)).split(' ')
      if first.len > 0 and first[0].len > 0:
        choose(parseInt(first[0]))
        window.scrollTo(0, 0))

  # Picker, stills by cell and question, sweeps by hold and band.
  var opts = cstring""
  for i in 0 ..< count(entries):
    let e = entry(i)
    let name = (if isStill(e): cardOf[i] & cstring" · " & text(e.key)
                else: text(e.hold) & cstring" · " & text(e.band))
    opts = opts & cstring"<option value='" & toFixed(i.float, 0) &
      cstring"'>" & name & cstring"</option>"
  document.getElementById("pick").innerHTML = opts

  document.getElementById("pick").addEventListener("change", proc (e: Event) =
    choose(parseInt($text(canvasOf("pick").value))))
  document.getElementById("prev").addEventListener("click", proc (e: Event) =
    choose(pick - 1))
  document.getElementById("next").addEventListener("click", proc (e: Event) =
    choose(pick + 1))
  document.addEventListener("keydown", proc (e: Event) =
    let tag = $text(e.target.toJs.tagName)
    if tag == "SELECT" or tag == "INPUT": return
    let key = $text(e.toJs.key)
    if key == "ArrowLeft": choose(pick - 1)
    elif key == "ArrowRight": choose(pick + 1))
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

  window.addEventListener("resize", proc (e: Event) =
    size()
    thumbs())
  discard window.setInterval(proc () = tick(), 40)
  choose(0)
  size()
  thumbs()


when isMainModule:
  window.addEventListener("DOMContentLoaded", proc (e: Event) = start())
