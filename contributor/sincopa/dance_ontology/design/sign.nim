## Draw turn sign: gauge of quarter turns, read like frame
## pictures.
##
##   Outline holds exactly one full turn and rows pack up from foot,
##     so how far turn goes is how full sign is.
##     Cost of fixed height: sign for more than full turn needs
##       ending mark rather than taller box; candidates are drawn on
##       page and none is chosen yet.
##   Column is one of lead's arms, pip's shape says whose quarter it
##     is, its fill says that arm's level, and dashed outline says turn
##     travels round couple -- every convention borrowed from frame
##     picture, so both read as one vocabulary.

{.experimental: "strictFuncs".}

import std/[math, options, strformat, strutils]

import ./rules
import ../src/dance_ontology/draw/[body, geometry, pose, style]

# What turn goes round is one idea, and it lives with turning in
# `pose`; sign borrows it rather than keeping second copy.
export About


const
  TAN* = 0.25                    ## Sign's lean, across per down.
  THETA = arctan(TAN)
  LEAN_SIN* = sin(THETA)         ## Lean, as sine every corner uses.
  LEAN_COS* = cos(THETA)         ## And its cosine: leaning height's drop.
  PAD* = 5.0                     ## Margin sign keeps inside its viewBox.

const
  PIP* = 11.0                    ## Pip width, across sign.
  GAP_X* = 4.0                   ## Margin, and gutter between arms.
  SIGN_BODY* = 2 * PIP + 3 * GAP_X   ## Width between slanting edges.
  QUARTERS* = 4                  ## Rows in full turn.
  HEIGHT* = float(QUARTERS) * PIP + float(QUARTERS + 1) * GAP_X
    ## So full sign is exactly full turn.
  OVER* = PIP                    ## How far open end runs on.
  INSET = 0.76                   ## How far dashed pip's fill pulls in.


type
  Row* {.pure.} = enum ## Say what one row of sign holds.
    Lead,              ## Quarter danced by lead: leaning square.
    Follow,            ## Quarter danced by follow: circle.
    Ellipsis,          ## Row that counts nothing: count runs on across.
    Repeat             ## Likewise, said as music's repeat colon.
  Lean* {.pure.} = enum ## Which way sign leans: way turn goes.
    Cw, Acw
  Ending* {.pure.} = enum ## How sign for unfixed amount ends.
    Open, Spill, EllipsisEnd, RepeatEnd, Loop
  SignArm* = tuple ## One column of sign: whether drawn, and its level.
    shown: bool
    level: Option[Level]
  SignArms* = array[Arm, SignArm]

const BOTH_UNSAID: SignArms = [(true, none(Level)), (true, none(Level))]
  ## Both columns drawn, neither level said -- default sign.


func dashes*(perimeter: float; count: int; duty = 0.58): string =
  ## Get dash pattern that closes on itself, so no stub shows at join.
  let period = perimeter / float(count)
  &"{n(period * duty)} {n(period * (1 - duty))}"


func scaled*(points: seq[Point]; factor: float): seq[Point] =
  ## Pull polygon in towards its own centre.
  var cx, cy = 0.0
  for p in points:
    cx += p.x
    cy += p.y
  cx = cx / float(points.len)
  cy = cy / float(points.len)
  for p in points:
    result.add (cx + (p.x - cx) * factor, cy + (p.y - cy) * factor)


func poly(points: seq[Point]; close = true): string =
  ## Write polygon as path data.
  var joined: seq[string]
  for p in points:
    joined.add &"{n(p.x)} {n(p.y)}"
  let d = "M" & joined.join(" L")
  if close: d & " Z" else: d


func pip*(dancer: Dancer; ax, ay, dxs, dys: float; arm: Arm;
    level: Option[Level]; about = none(About)): string =
  ## Draw one quarter turn: shape says whose, column and ink which arm, fill
  ## its level.
  ##   Given `about`, pip carries axis-against-orbit itself, which
  ##     needs fill pulled in off outline -- low pip is filled in
  ##     arm's own ink, and dashed stroke of that ink on top of it
  ##     would be no stroke at all.
  ##   Pip takes shade of hand it stands for, lead's deep and
  ##     follow's plain, so sign and frame picture read same way
  ##     round.
  let
    leads = dancer == Dancer.Lead
    ink = if leads: DEEP[arm] else: INK[arm]
    fill = fillOf(level, arm, leads)
    cx = ax + PIP / 2 + dxs / 2
    cy = ay + dys / 2
    pts: seq[Point] = @[(ax, ay), (ax + PIP, ay), (ax + PIP + dxs, ay + dys),
                        (ax + dxs, ay + dys)]
    perimeter = if leads: 2 * PIP + 2 * hypot(dxs, dys)
                else: 2 * PI * (PIP / 2)

  func shape(inset: float; style: string): string =
    ## One outline or fill, as dancer's own mark: path or circle.
    if leads:
      let d = if inset == 1.0: poly(pts) else: poly(scaled(pts, inset))
      &"""<path d="{d}" {style}/>"""
    else:
      &"""<circle cx="{n(cx)}" cy="{n(cy)}" r="{n(PIP / 2 * inset)}" {style}/>"""

  var bits: seq[string]
  if about.isNone:
    bits.add shape(1.0,
      &"""fill="{fill}" stroke="{ink}" stroke-width="1.4"""" &
        """ stroke-linejoin="round"""")
  else:
    if fill != "none":
      bits.add shape(INSET, &"""fill="{fill}" stroke="none"""")
    let dash = if about == some(About.Orbit):
                 &""" stroke-dasharray="{dashes(perimeter, 8)}""""
               else: ""
    bits.add shape(1.0,
      &"""fill="none" stroke="{ink}" stroke-width="1.4"""" &
        &""" stroke-linejoin="round"{dash}""")
  if level == some(Level.High):
    bits.add &"""<circle cx="{n(cx)}" cy="{n(cy)}" r="2.5" fill="{ink}"/>"""
  bits.join("")


func marker*(kind: Row; ax, ay, dxs, dys: float; arm: Arm): string =
  ## Draw row that counts nothing: it says count does not end.
  let
    ink = INK[arm]
    cx = ax + PIP / 2 + dxs / 2
    cy = ay + dys / 2
  if kind == Row.Ellipsis:               # and so on, across
    for d in [-3.7, 0.0, 3.7]:
      result.add &"""<circle cx="{n(cx + d)}" cy="{n(cy)}" r="1.7"""" &
        &""" fill="{ink}"/>"""
  else:
    for d in [-3.1, 3.1]:
      result.add &"""<circle cx="{n(cx)}" cy="{n(cy + d)}" r="1.9"""" &
        &""" fill="{ink}"/>"""


func signBody(slots: seq[Row]; lean: Lean; arms: SignArms; x0, y_foot: float;
    about: Option[About]; pip_about: seq[About]; ending: Option[Ending];
    packed = true): tuple[markup: string, box: tuple[x0, y0, x1, y1: float]] =
  ## Draw sign at given place, returning markup and box it fills.
  ##   `slots` reads downwards, one entry per quarter turn, follow's
  ##     first, so mixed sign has one picture rather than two.
  ##   Stack packs up from foot: outline holds full turn, so
  ##     how full it is is how far it goes, and count is check on
  ##     reading rather than whole of it.
  let
    y_bot = y_foot + HEIGHT
    y_top = y_foot
    slope = HEIGHT * TAN
    over = if ending in [some(Ending.Open), some(Ending.Spill)]: OVER else: 0.0
    slant = if lean == Lean.Cw: -LEAN_SIN else: LEAN_SIN

  func leftAt(y: float): float =
    ## Slanting left edge, at given height.
    if lean == Lean.Cw: x0 + (y_bot - y) * TAN    # leans right going up
    else: x0 + (y - y_top) * TAN

  func slotTop(place: int): float =
    ## Top of slot `place` rows up from foot.
    y_bot - GAP_X - float(place) * (PIP + GAP_X) - PIP

  let
    foot: seq[Point] = @[(leftAt(y_bot), y_bot),
                         (leftAt(y_bot) + SIGN_BODY, y_bot)]
    head: seq[Point] = @[(leftAt(y_top), y_top),
                         (leftAt(y_top) + SIGN_BODY, y_top)]
    perimeter = 2 * SIGN_BODY + 2 * hypot(slope, HEIGHT)
    # Couple's centre line is dashed in every frame picture, so turn
    # that goes round that centre is dashed too, not new mark.
    dash = if about == some(About.Orbit):
             &""" stroke-dasharray="{dashes(perimeter, 20)}""""
           else: ""
    style = """fill="none" stroke="var(--ink)" stroke-width="2"""" &
      &""" stroke-linejoin="round" stroke-linecap="round"{dash}"""
    outline =
      if over > 0:
        # No lid, and sides run on past where one would be: box that
        # never closes is count that never finishes.
        let tips: seq[Point] = @[(leftAt(y_top - over), y_top - over),
                                 (leftAt(y_top - over) + SIGN_BODY,
                                  y_top - over)]
        poly(@[tips[0], foot[0], foot[1], tips[1]], close = false)
      else:
        poly(@[foot[0], head[0], head[1], foot[1]])
  var bits = @[&"""<path d="{outline}" {style}/>"""]

  if ending == some(Ending.Loop):
    # Graph's own loop edge, drawn on its label.
    let
      (ax0, ay0) = head[0]
      (bx0, by0) = foot[0]
      reach = 15.0
    bits.add &"""<path d="M{n(ax0 - 2)} {n(ay0 + 5)} C{n(ax0 - reach)}""" &
      &""" {n(ay0 + 6)} {n(bx0 - reach)} {n(by0 - 6)} {n(bx0 - 3)}""" &
      &""" {n(by0 - 5)}" fill="none" stroke="var(--ink)"""" &
      """ stroke-width="1.6" stroke-linecap="round"/>"""
    bits.add &"""<path d="M{n(bx0 - 8)} {n(by0 - 8.5)} L{n(bx0 - 3)}""" &
      &""" {n(by0 - 5)} L{n(bx0 - 8.5)} {n(by0 - 2.5)}" fill="none"""" &
      """ stroke="var(--ink)" stroke-width="1.6"""" &
      """ stroke-linecap="round" stroke-linejoin="round"/>"""

  let
    total = slots.len
    spread = (HEIGHT - float(total) * PIP) / float(total + 1)
  for i, what in slots:
    var top = if packed: slotTop(total - 1 - i)
              else: y_top + spread + float(i) * (PIP + spread)
    top += (PIP - PIP * LEAN_COS) / 2
    for col, arm in [Arm.L, Arm.R]:
      if not arms[arm].shown:
        continue
      let ax = leftAt(top) + GAP_X + float(col) * (PIP + GAP_X)
      if what in [Row.Lead, Row.Follow]:
        let row_about = if pip_about.len > 0: some(pip_about[i])
                        else: none(About)
        bits.add pip(
          (if what == Row.Lead: Dancer.Lead else: Dancer.Follow),
          ax, top, PIP * slant, PIP * LEAN_COS, arm, arms[arm].level,
          row_about)
      else:
        bits.add marker(what, ax, top, PIP * slant, PIP * LEAN_COS, arm)

  var
    xs: seq[float]
    ys = @[y_bot, y_top - over]
  for y in ys:
    xs.add leftAt(y)
  for y in ys:
    xs.add leftAt(y) + SIGN_BODY
  if ending == some(Ending.Loop):
    xs.add min(foot[0].x, head[0].x) - 16
  (bits.join("\n        "), (min(xs), y_top - over, max(xs), y_bot))


func sign*(slots: seq[Row]; lean = Lean.Cw; arms = BOTH_UNSAID;
    about = none(About); pip_about: seq[About] = @[];
    ending = none(Ending); scale = 1.2; packed = true): string =
  ## Draw one turn sign: quarter turns up from foot, arms across, one
  ## height for every sign.
  let rows =
    if ending == some(Ending.EllipsisEnd): @[Row.Ellipsis] & slots
    elif ending == some(Ending.RepeatEnd): @[Row.Repeat] & slots
    elif ending == some(Ending.Spill):
      # Pip cut by missing lid repeats whoever top quarter is.
      @[slots[0]] & slots
    else: slots
  let
    (markup, box) = signBody(
      rows,
      lean,
      arms,
      x0 = PAD,
      y_foot = PAD + OVER,
      about = about,
      pip_about = pip_about,
      ending = ending,
      packed = packed,
    )
    w = box.x1 - box.x0 + 2 * PAD
    h = box.y1 - box.y0 + 2 * PAD
  &"""<svg viewBox="{n(box.x0 - PAD)} {n(box.y0 - PAD)} {n(w)} {n(h)}"""" &
    &""" width="{n(w * scale)}" height="{n(h * scale)}">""" &
    &"\n        {markup}\n      </svg>"
