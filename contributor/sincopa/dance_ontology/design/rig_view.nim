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

when compileOption("profiler"): import std/nimprof

import std/[dom, jsffi, math, strutils]

import ./drawn


const VERDICTS* = [
  "Holds. The sim wound the couple here from rest, lifted their joined hands, and let the " &
    "pose settle.",
  "No pose holds, at any distance the couple can stand.",
  "Nothing stops the turn inside the range this sweep tried.",
]
  ## Every whole sentence viewer shows as its verdict, in one table.
  ##   Page is built in browser, so no page on disk carries these sentences and
  ##     `tmarks` cannot read them.  Table is what `tsaid` counts instead, which
  ##     holds them to same two rules as prose written into markup (Article VI.8).
  ##   Fourth verdict is not whole sentence: it opens `Stops at <b>N</b> turns:`
  ##     and closes with reason recorded by sim, so it is built at reading time
  ##     and counted by nothing.


# Browser's own calls, one line each.
func rig(): JsObject {.importjs: "RIG@".}
func contextOf(id: cstring): JsObject {.importjs:
  "document.getElementById(#).getContext('2d')".}
  ## Get drawing context of canvas named `id`.
func canvasOf(id: cstring): JsObject {.importjs: "document.getElementById(#)".}
func contextOf(canvas: JsObject): JsObject {.importjs: "(#).getContext('2d')".}
func toFixed(x: float; places: int): cstring {.importjs: "(#).toFixed(#)".}
func toFloat(x: JsObject): float {.importjs: "(#)".}
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
  AZIMUTH_START = 0.6      ## Camera round world's up at start, radians.
  ELEVATION_START = 0.18     ## And tilt above floor.

# Mutable: viewer's state, which every handler reads and changes.  Browser calls
# handlers with nothing of their own, so state lives here.
var
  AZIMUTH = AZIMUTH_START
  ELEVATION = ELEVATION_START
  ZOOM = 1.0
  FRAMING_SHOWN: Framing = ([0.0, 0.0, 0.95], 1.2)
  ENTRIES_ALL: JsObject ## Every still, then every sweep.
  PICK = 0      ## Which entry.
  MOMENT_SHOWN = 0     ## Which moment of it.
  IS_PLAYING = true
  IS_DRAGGING = false
  X_PREV, Y_PREV = 0.0
  LUT_CARD_BY_ENTRY: seq[cstring]  ## Reference cell each entry belongs to, or empty.
  LUT_CELL_BY_ENTRY: seq[Element]  ## And cell itself, or nil.


# Entries of recording, read as viewer reads them.
proc entry(i: int): JsObject = ENTRIES_ALL[i]
proc sweep(): JsObject = entry(PICK)
proc momentsOf(e: JsObject): int = (if has(e, "at"): count(e.at) else: 0)
proc moments(): int = momentsOf(sweep())
proc isStill(e: JsObject): bool = has(e, "key")


proc ends(e: JsObject; i, at: int): tuple[a, z: Spot] =
  ## Capsule `i`'s two world ends at moment `at` of entry `e`.
  let
    row = e.p[at]
    k = i * 6
  ((x: toFloat(row[k]), y: toFloat(row[k + 1]), z: toFloat(row[k + 2])),
   (x: toFloat(row[k + 3]), y: toFloat(row[k + 4]), z: toFloat(row[k + 5])))


proc paintOn(canvas: JsObject; e: JsObject; at: int; azimuth, elevation, zoom: float;
             f: Framing) =
  ## Draw one moment of one entry on one canvas, seen from one place.
  let
    context = contextOf(canvas)
    w = toFloat(canvas.width)
    h = toFloat(canvas.height)
    scale = min(w, h) / (2.2 * f.reach) * zoom
    cx = w / 2.0
    cy = h / 2.0
  discard context.clearRect(0, 0, w, h)
  if momentsOf(e) == 0:
    return

  # Floor, so height and distance have something to be read against.
  context.lineWidth = 1.0.toJs
  context.strokeStyle = styleOf("--rule").toJs
  let span = 1.5
  var g = -span
  while g <= span + 0.001:
    for way in 0 .. 1:
      let
        a: Spot = (if way == 0: (f.mid[0] + g, f.mid[1] - span, 0.0)
                   else: (f.mid[0] - span, f.mid[1] + g, 0.0))
        b: Spot = (if way == 0: (f.mid[0] + g, f.mid[1] + span, 0.0)
                   else: (f.mid[0] + span, f.mid[1] + g, 0.0))
        pa = seen(a, azimuth, elevation, f)
        pb = seen(b, azimuth, elevation, f)
      discard context.beginPath()
      discard context.moveTo(cx + pa.x * scale, cy + pa.y * scale)
      discard context.lineTo(cx + pb.x * scale, cy + pb.y * scale)
      discard context.stroke()
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
      here: Spot = (toFloat(look[k]), toFloat(look[k + 1]), 0.0)
      ahead: Spot = (here.x + toFloat(look[k + 2]), here.y + toFloat(look[k + 3]), 0.0)
      (ph, pf) = (seen(here, azimuth, elevation, f), seen(ahead, azimuth, elevation, f))
    facing[who] = (x: pf.x - ph.x, y: pf.y - ph.y, d: pf.d - ph.d)
  let
    shade = $styleOf("--body-shade")
    lit = $styleOf("--body-lit")

  # Capsules, furthest first, in order `drawn` gives.
  var capsules: seq[tuple[a, z: Spot]]
  for i in 0 ..< count(e.rad):
    capsules.add ends(e, i, at)
  context.lineCap = cstring("round").toJs
  for piece in drawOrder(capsules, azimuth, elevation, f):
    let
      i = piece.capsule
      tag = e.tag[i]
      mark = int(toFloat(tag[2]))
      (a, z) = (piece.a, piece.z)
      pa = seen(a, azimuth, elevation, f)
      pz = seen(z, azimuth, elevation, f)
      r = toFloat(e.rad[i])
    var ink: JsObject
    if mark == 0 or mark == 4:
      # Trunk and girdle: light across from back edge to front edge, along
      # facing's image on screen, through piece's middle.
      let
        axis: Seen = (x: pz.x - pa.x, y: pz.y - pa.y, d: 0.0)
        fore = lightAcross(facing[int(toFloat(tag[0]))], axis)
        across = sqrt(fore.x * fore.x + fore.y * fore.y)
        (mx, my) = (cx + (pa.x + pz.x) / 2.0 * scale, cy + (pa.y + pz.y) / 2.0 * scale)
      if across < 0.02:
        ink = cstring(mixHex(shade, lit, litAt(fore, 0.0))).toJs
      else:
        let
          (ux, uy) = (fore.x / across * r * scale, fore.y / across * r * scale)
          grad = context.createLinearGradient(mx - ux, my - uy, mx + ux, my + uy)
        for (stop, s) in [(0.0, -1.0), (0.5, 0.0), (1.0, 1.0)]:
          discard grad.addColorStop(stop, cstring(mixHex(shade, lit, litAt(fore, s))))
        ink = grad
    else:
      ink = inkOf(int(toFloat(tag[1])), int(toFloat(tag[0]))).toJs
    case drawnAs(a, z)
    of Drawn.Stroke:
      context.lineWidth = (2.0 * r * scale).toJs
      context.strokeStyle = ink
      discard context.beginPath()
      discard context.moveTo(cx + pa.x * scale, cy + pa.y * scale)
      discard context.lineTo(cx + pz.x * scale, cy + pz.y * scale)
      discard context.stroke()
    of Drawn.Disc:
      context.fillStyle = ink
      discard context.beginPath()
      discard context.arc(cx + pa.x * scale, cy + pa.y * scale, r * scale, 0.0, 2.0 * PI)
      discard context.fill()

  # Where hands are joined, and how far engine has pulled them apart.
  let grip = e.g[at]
  for k in 0 ..< count(grip) div 3:
    let p = seen((x: toFloat(grip[k * 3]), y: toFloat(grip[k * 3 + 1]),
                  z: toFloat(grip[k * 3 + 2])), azimuth, elevation, f)
    context.fillStyle = styleOf("--ink").toJs
    discard context.beginPath()
    discard context.arc(cx + p.x * scale, cy + p.y * scale, 3.0, 0.0, 2.0 * PI)
    discard context.fill()


proc paint() =
  ## Draw entry chosen, at moment shown, on stage.
  paintOn(canvasOf("view"), sweep(), MOMENT_SHOWN, AZIMUTH, ELEVATION, ZOOM, FRAMING_SHOWN)


proc readout() =
  ## Every joint of every arm, beside range it is held between.
  let sweep_shown = sweep()
  var html = cstring""
  if moments() > 0:
    let js = sweep_shown.j[MOMENT_SHOWN]
    for a in 0 ..< count(sweep_shown.arm):
      let
        who = int(toFloat(sweep_shown.arm[a][0]))
        side = int(toFloat(sweep_shown.arm[a][1]))
      # Label, not heading: heading would take serif face (Article X.8).
      html = html & cstring"<div class='arm'><p class='who'><i style='background:" &
        inkOf(side, who) & cstring"'></i>" & WHOSE[who] & cstring" " &
        SIDES[side] & cstring"</p>"
      for d in 0 ..< DOFS.len:
        let
          k = a * DOFS.len + d
          v = toFloat(js[k])
          lower = toFloat(sweep_shown.lo[k])
          upper = toFloat(sweep_shown.hi[k])
          span = (if upper - lower > 1e-9: upper - lower else: 1.0)
          at = (v - lower) / span
          spent = v <= lower + NEAR or v >= upper - NEAR
        html = html & cstring"<div class='dof" &
          (if spent: cstring" spent" else: cstring"") & cstring"'><span>" &
          DOFS[d] & cstring"</span><div class='track'><b style='left:" &
          toFixed(max(0.0, min(1.0, at)) * 100.0, 1) & cstring"%'></b></div><em>" &
          toFixed(v * 180.0 / PI, 0) & cstring"°</em><u>" &
          toFixed(lower * 180.0 / PI, 0) & cstring"…" &
          toFixed(upper * 180.0 / PI, 0) & cstring"</u></div>"
      html = html & cstring"</div>"
  document.getElementById("reads").innerHTML = html


proc caption() =
  ## Say what entry shows: its turns and distance, or what stopped it.
  let sweep_shown = sweep()
  if isStill(sweep_shown):
    document.getElementById("where").innerHTML =
      (if moments() > 0:
         cstring"<b>" & toFixed(toFloat(sweep_shown.turns), 2) & cstring"</b> turns · stood <b>" &
           toFixed(toFloat(sweep_shown.apart), 2) & cstring"</b> m apart"
       else:
         cstring"<b>" & toFixed(toFloat(sweep_shown.turns), 2) &
           cstring"</b> turns · no pose holds")
    document.getElementById("verdict").innerHTML =
      (if moments() > 0: cstring(VERDICTS[0]) else: cstring(VERDICTS[1]))
  else:
    let turned = toFloat(sweep_shown.at[MOMENT_SHOWN])
    document.getElementById("where").innerHTML =
      cstring"<b>" & toFixed(turned, 2) & cstring"</b> turns · stood <b>" &
      toFixed(toFloat(sweep_shown.apart), 2) & cstring"</b> m apart"
    document.getElementById("verdict").innerHTML =
      (if truth(sweep_shown.stopped):
         cstring"Stops at <b>" & toFixed(toFloat(sweep_shown.turns), 2) & cstring"</b> turns: " &
           text(sweep_shown.says)
       else:
         cstring(VERDICTS[2]))


proc framingOf(e: JsObject): Framing =
  ## Frame one entry to what it holds, over every moment of it, so view does
  ## not jump as couple turn and nothing wanders off edge part way through.
  var
    lower = [1e9, 1e9, 1e9]
    upper = [-1e9, -1e9, -1e9]
  for t in 0 ..< momentsOf(e):
    let row = e.p[t]
    for k in 0 ..< count(row) div 3:
      for d in 0 .. 2:
        let v = toFloat(row[k * 3 + d])
        lower[d] = min(lower[d], v)
        upper[d] = max(upper[d], v)
  ## Framed to capsules, not to floor.  Rig is trunk upward and has no legs, so
  ## forcing floor into frame spends half of it on gap where legs would be;
  ## grid is still drawn at nought and comes into view on zooming out.
  for d in 0 .. 2:
    result.mid[d] = (lower[d] + upper[d]) / 2.0
  result.reach =
    max(max(upper[0] - lower[0], upper[1] - lower[1]), upper[2] - lower[2]) / 2.0 + 0.15

proc fit() =
  ## Frame camera to entry chosen, where it has any moment.
  if moments() > 0:
    FRAMING_SHOWN = framingOf(sweep())


proc reference() =
  ## Reference's own drawing of this entry's cell beside stage, and cell marked.
  for i, cell in LUT_CELL_BY_ENTRY:
    if cell != nil:
      cell.classList.remove(cstring"picked")
  let cell = LUT_CELL_BY_ENTRY[PICK]
  if cell == nil:
    document.getElementById("ref").innerHTML = cstring""
    return
  cell.classList.add(cstring"picked")
  let
    art = cell.querySelector(".art")
    caption = cell.querySelector("figcaption")
  document.getElementById("ref").innerHTML =
    cstring"<div class='art'>" & art.innerHTML & cstring"</div>" & caption.outerHTML

proc show() =
  ## Redraw stage, readout and caption, and move scrub bar to moment shown.
  paint()
  readout()
  caption()
  let bar = canvasOf("scrub")
  bar.value = MOMENT_SHOWN.toJs


proc size() =
  ## Match canvas to its box at twice its pixels, then redraw.
  let canvas = canvasOf("view")
  canvas.width = (toFloat(canvas.clientWidth) * 2.0).toJs
  canvas.height = (toFloat(canvas.clientHeight) * 2.0).toJs
  show()


proc thumbs() =
  ## Every still drawn small beside its own cell, from one fixed place.
  for node in document.querySelectorAll("canvas.thumb"):
    let
      canvas = node.toJs
      k = parseInt($node.getAttribute("data-entry"))
      e = entry(k)
      w = toFloat(canvas.clientWidth) * 2.0
    canvas.width = w.toJs
    canvas.height = w.toJs
    if momentsOf(e) > 0:
      paintOn(canvas, e, 0, AZIMUTH_START, ELEVATION_START, 1.0, framingOf(e))


proc tick() =
  ## Step to next moment while playing, and redraw.
  if IS_PLAYING and moments() > 1:
    MOMENT_SHOWN = (MOMENT_SHOWN + 1) mod moments()
    show()

proc choose(i: int) =
  ## Choose entry `i`, wrapped round, from its first moment.
  PICK = ((i mod count(ENTRIES_ALL)) + count(ENTRIES_ALL)) mod count(ENTRIES_ALL)
  MOMENT_SHOWN = 0
  fit()
  canvasOf("pick").value = toFixed(float(PICK), 0).toJs
  canvasOf("scrub").max = (max(0, moments() - 1)).toJs
  document.getElementById("transport").toJs.hidden = (moments() <= 1).toJs
  reference()
  show()


proc start() =
  ## Read recording, tie each entry to its reference cell, and draw first.
  ENTRIES_ALL = joined(rig().stills, rig().sweeps)
  # Which cell of reference each entry belongs to, read off page itself.
  for i in 0 ..< count(ENTRIES_ALL):
    LUT_CARD_BY_ENTRY.add cstring""
    LUT_CELL_BY_ENTRY.add nil
  for node in document.querySelectorAll("figure[data-entries]"):
    let cell = Element(node)
    for word in ($cell.getAttribute("data-entries")).split(' '):
      if word.len == 0: continue
      let k = parseInt(word)
      LUT_CARD_BY_ENTRY[k] = cell.getAttribute("data-id")
      LUT_CELL_BY_ENTRY[k] = cell
    cell.addEventListener("click", proc (e: Event) =
      let first = ($entriesOn(e)).split(' ')
      if first.len > 0 and first[0].len > 0:
        choose(parseInt(first[0]))
        window.scrollTo(0, 0))

  # Picker, stills by cell and question, sweeps by hold and band.
  var option_list = cstring""
  for i in 0 ..< count(ENTRIES_ALL):
    let
      e = entry(i)
      name = (if isStill(e): LUT_CARD_BY_ENTRY[i] & cstring" · " & text(e.key)
              else: text(e.hold) & cstring" · " & text(e.band))
    option_list = option_list & cstring"<option value='" & toFixed(float(i), 0) &
      cstring"'>" & name & cstring"</option>"
  document.getElementById("pick").innerHTML = option_list

  document.getElementById("pick").addEventListener("change", proc (e: Event) =
    choose(parseInt($text(canvasOf("pick").value))))
  document.getElementById("prev").addEventListener("click", proc (e: Event) =
    choose(PICK - 1))
  document.getElementById("next").addEventListener("click", proc (e: Event) =
    choose(PICK + 1))
  document.addEventListener("keydown", proc (e: Event) =
    let tag = $text(e.target.toJs.tagName)
    if tag == "SELECT" or tag == "INPUT": return
    let key = $text(e.toJs.key)
    if key == "ArrowLeft": choose(PICK - 1)
    elif key == "ArrowRight": choose(PICK + 1))
  document.getElementById("play").addEventListener("click", proc (e: Event) =
    IS_PLAYING = not IS_PLAYING
    document.getElementById("play").innerHTML =
      (if IS_PLAYING: cstring"Pause" else: cstring"Play"))
  document.getElementById("scrub").addEventListener("input", proc (e: Event) =
    IS_PLAYING = false
    document.getElementById("play").innerHTML = cstring"Play"
    MOMENT_SHOWN = int(toFloat(canvasOf("scrub").value))
    show())

  let canvas = canvasOf("view")
  canvas.addEventListener(cstring"pointerdown", proc (e: Event) =
    IS_DRAGGING = true
    X_PREV = toFloat(e.toJs.clientX)
    Y_PREV = toFloat(e.toJs.clientY))
  document.addEventListener("pointerup", proc (e: Event) = IS_DRAGGING = false)
  document.addEventListener("pointermove", proc (e: Event) =
    if IS_DRAGGING:
      let
        x = toFloat(e.toJs.clientX)
        y = toFloat(e.toJs.clientY)
      AZIMUTH += (x - X_PREV) * 0.01
      ELEVATION = max(-1.4, min(1.4, ELEVATION + (y - Y_PREV) * 0.01))
      X_PREV = x
      Y_PREV = y
      paint())
  canvas.addEventListener(cstring"wheel", proc (e: Event) =
    e.preventDefault()
    ZOOM = max(0.35, min(4.0, ZOOM * (if toFloat(e.toJs.deltaY) > 0.0: 0.92 else: 1.08)))
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
