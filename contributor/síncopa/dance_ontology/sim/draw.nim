## Draw state of sim, straight from state.
##
##   Two views of one value: from above, where turn is, and from
##     side, where height is -- which of two crossing arms is over, and
##     whether elbow is up or down, are only there.
##   Nothing here is symbol standing for something.  Ellipse is torso
##     seen from above at size torso is, and line is where
##     solver put arm, as thick as arm is.  If drawing looks
##     wrong, model is wrong.

{.experimental: "strictFuncs".}

import std/[math, strformat, strutils]

import ./[body, limb, rig, solve, vec]


const
  PX* = 250.0 ## Pixels to metre.
  INKS* = ["var(--rope-a, #3d7fd0)", "var(--rope-b, #d0763d)",
           "var(--rope-c, #4f9d69)", "var(--rope-d, #9a6fc0)"]
    ## One colour per connection.


func n*(v: float): string =
  ## Write number for markup, without trailing point or minus zero.
  result = formatFloat(v, ffDecimal, 1)
  if result == "-0.0": result = "0.0"

func m*(v: float): string = formatFloat(v, ffDecimal, 3)
  ## Write length in metres, to millimetre.


func px(x: float): string = n(x * PX)


func planBody(rig: Rig; st: Stance; ink: string): string =
  ## One body from above: torso ellipse, neck and head circles, facing tick.
  let
    cx = st.centre.x
    cy = -st.centre.y
    deg = -st.facing * 180.0 / PI
  result.add &"<g transform=\"translate({px(cx)} {px(cy)}) rotate({n(deg)})\">"
  result.add &"<ellipse rx=\"{px(halfDepth(rig, Part.Torso))}\" " &
    &"ry=\"{px(halfBreadth(rig, Part.Torso))}\" fill=\"{ink}\" fill-opacity=\"0.10\" " &
    &"stroke=\"{ink}\" stroke-width=\"1.5\"/>"
  result.add &"<circle r=\"{px(halfBreadth(rig, Part.Head))}\" fill=\"none\" " &
    &"stroke=\"{ink}\" stroke-width=\"1\" stroke-dasharray=\"3 3\"/>"
  result.add &"<circle r=\"{px(halfBreadth(rig, Part.Neck))}\" fill=\"{ink}\" " &
    &"fill-opacity=\"0.25\" stroke=\"none\"/>"
  result.add &"<line x1=\"0\" y1=\"0\" x2=\"{px(halfDepth(rig, Part.Torso) + 0.04)}\" " &
    &"y2=\"0\" stroke=\"{ink}\" stroke-width=\"2\"/>"
  result.add "</g>"


func planArm(rig: Rig; p: ArmPose; ink: string; dashed: bool): string =
  ## One arm from above, as thick as it is, joints marked.
  let pts = [p.s, p.e, p.w, p.g]
  var d = ""
  for i, q in pts:
    d.add (if i == 0: "M" else: "L") & px(q.x) & " " & px(-q.y) & " "
  let dash = if dashed: " stroke-dasharray=\"6 4\"" else: ""
  result.add &"<path d=\"{d}\" fill=\"none\" stroke=\"{ink}\" " &
    &"stroke-width=\"{px(2.0 * rig.limb)}\" stroke-opacity=\"0.55\" " &
    &"stroke-linecap=\"round\" stroke-linejoin=\"round\"{dash}/>"
  result.add &"<path d=\"{d}\" fill=\"none\" stroke=\"{ink}\" stroke-width=\"1.5\" " &
    &"stroke-linejoin=\"round\"/>"
  for q in [p.e, p.w]:
    result.add &"<circle cx=\"{px(q.x)}\" cy=\"{px(-q.y)}\" r=\"3\" " &
      &"fill=\"var(--page, #fff)\" stroke=\"{ink}\" stroke-width=\"1.5\"/>"
  result.add &"<rect x=\"{n(p.s.x * PX - 4)}\" y=\"{n(-p.s.y * PX - 4)}\" " &
    &"width=\"8\" height=\"8\" fill=\"{ink}\"/>"


func sideBody(rig: Rig; st: Stance; mid: tuple[x, y: float]; dir: Vec;
              ink: string): string =
  ## One body from side, looking across line between two axes:
  ## height of each part and how deep it shows at its facing.
  let
    right: Vec = (sin(st.facing), -cos(st.facing), 0.0)
    fore: Vec = (cos(st.facing), sin(st.facing), 0.0)
    along = (st.centre.x - mid.x) * dir.x + (st.centre.y - mid.y) * dir.y
    dr = dir.x * right.x + dir.y * right.y
    df = dir.x * fore.x + dir.y * fore.y
  for part in Part:
    let
      a = halfBreadth(rig, part)
      b = halfDepth(rig, part)
      half = sqrt((a * dr) * (a * dr) + (b * df) * (b * df))
      y0 = -(along + half)
      z0 = -rig.top[part]
      h = rig.top[part] - bottom(rig, part)
    result.add &"<rect x=\"{px(y0)}\" y=\"{px(z0)}\" width=\"{px(2.0 * half)}\" " &
      &"height=\"{px(h)}\" fill=\"{ink}\" fill-opacity=\"0.10\" " &
      &"stroke=\"{ink}\" stroke-width=\"1\"/>"


func sideArm(rig: Rig; p: ArmPose; mid: tuple[x, y: float]; dir: Vec;
             ink: string): string =
  func across(q: Vec): string =
    px(-((q.x - mid.x) * dir.x + (q.y - mid.y) * dir.y))
  let pts = [p.s, p.e, p.w, p.g]
  var d = ""
  for i, q in pts:
    d.add (if i == 0: "M" else: "L") & across(q) & " " & px(-q.z) & " "
  result.add &"<path d=\"{d}\" fill=\"none\" stroke=\"{ink}\" " &
    &"stroke-width=\"{px(2.0 * rig.limb)}\" stroke-opacity=\"0.55\" " &
    &"stroke-linecap=\"round\" stroke-linejoin=\"round\"/>"
  result.add &"<path d=\"{d}\" fill=\"none\" stroke=\"{ink}\" stroke-width=\"1.5\" " &
    &"stroke-linejoin=\"round\"/>"
  for q in [p.e, p.w]:
    result.add &"<circle cx=\"{across(q)}\" cy=\"{px(-q.z)}\" r=\"3\" " &
      &"fill=\"var(--page, #fff)\" stroke=\"{ink}\" stroke-width=\"1.5\"/>"


func plan*(s: State; v: Verdict; half = 0.80): string =
  ## Couple from above, in square `2 * half` metres wide about
  ## midpoint of two bodies.
  let
    mx = (s.stance[Body.One].centre.x + s.stance[Body.Two].centre.x) / 2.0
    my = (s.stance[Body.One].centre.y + s.stance[Body.Two].centre.y) / 2.0
  result.add &"<svg viewBox=\"{px(mx - half)} {px(-my - half)} " &
    &"{px(2.0 * half)} {px(2.0 * half)}\" width=\"100%\" style=\"max-height: 26rem\" " &
    &"xmlns=\"http://www.w3.org/2000/svg\">"
  for who in Body:
    result.add planBody(s.rig, s.stance[who],
      (if who == Body.One: "var(--ink, #222)" else: "var(--dim, #777)"))
  for i in 0 ..< v.n:
    for k in 0 .. 1:
      result.add planArm(s.rig, v.fits[i].arms[k], INKS[i mod INKS.len], k == 1)
  result.add "</svg>"


func elevation*(s: State; v: Verdict; half = 0.80): string =
  ## Couple from side, looking across line between their two
  ## axes, floor to over heads: whichever way they have turned or
  ## walked, side view keeps them side by side.
  let
    c1 = s.stance[Body.One].centre
    c2 = s.stance[Body.Two].centre
    mid = ((c1.x + c2.x) / 2.0, (c1.y + c2.y) / 2.0)
    span = sqrt((c2.x - c1.x) * (c2.x - c1.x) + (c2.y - c1.y) * (c2.y - c1.y))
    dir: Vec = if span < 1e-9: (0.0, 1.0, 0.0)
               else: ((c2.x - c1.x) / span, (c2.y - c1.y) / span, 0.0)
  result.add &"<svg viewBox=\"{px(-half)} {px(-2.1)} {px(2.0 * half)} {px(1.4)}\" " &
    &"width=\"100%\" style=\"max-height: 16rem\" xmlns=\"http://www.w3.org/2000/svg\">"
  for who in Body:
    result.add sideBody(s.rig, s.stance[who], mid, dir,
      (if who == Body.One: "var(--ink, #222)" else: "var(--dim, #777)"))
  for i in 0 ..< v.n:
    for k in 0 .. 1:
      result.add sideArm(s.rig, v.fits[i].arms[k], mid, dir, INKS[i mod INKS.len])
  result.add "</svg>"
