## Draw turn sign: gauge of quarter turns, read like frame
## pictures.
##
##   Outline holds exactly one full turn and rows pack up from foot,
##     so how far turn goes is how full sign is.
##     Cost of fixed height: sign for more than full turn needs
##       ending mark rather than taller gauge; candidates are drawn on
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
  TANGENT* = 0.25  ## Sign's lean, across per down.
  THETA = arctan(TANGENT)
  LEAN_SINE* = sin(THETA)  ## Lean, as sine every corner uses.
  LEAN_COSINE* = cos(THETA)  ## And its cosine: leaning height's drop.
  PAD* = 5.0  ## Margin sign keeps inside its viewBox.

const
  PIP* = 11.0  ## Pip width, across sign.
  GAP_X* = 4.0  ## Margin, and gutter between arms.
  SIGN_BODY* = 2 * PIP + 3 * GAP_X  ## Width between slanting edges.
  QUARTERS* = 4  ## Rows in full turn.
  HEIGHT* = float(QUARTERS) * PIP + float(QUARTERS + 1) * GAP_X
    ## So full sign is exactly full turn.
  OVER* = PIP  ## How far open end runs on.
  INSET = 0.76  ## How far dashed pip's fill pulls in.


type
  Row* {.pure.} = enum  ## Say what one row of sign holds.
    Lead,  ## Quarter danced by lead: leaning square.
    Follow,  ## Quarter danced by follow: circle.
    Ellipsis,  ## Row that counts nothing: count runs on across.
    Repeat  ## Likewise, said as music's repeat colon.
  Lean* {.pure.} = enum  ## Which way sign leans: way turn goes.
    Clockwise, Anticlockwise
  Ending* {.pure.} = enum  ## How sign for unfixed amount ends.
    Open, Spill, EllipsisEnd, RepeatEnd, Loop
  SignArm* = tuple  ## One column of sign: whether drawn, and its level.
    is_shown: bool
    level: Option[Level]
  SignArms* = array[Arm, SignArm]

const BOTH_UNSAID: SignArms = [(true, none(Level)), (true, none(Level))]
  ## Both columns drawn, neither level said -- default sign.


func dashes*(perimeter: float, count: int, duty = 0.58): string =
  ## Get dash pattern that closes on itself, so no stub shows at join.
  let period = perimeter / float(count)
  &"{numeral(period * duty)} {numeral(period * (1 - duty))}"


func scaled*(points: seq[Point], factor: float): seq[Point] =
  ## Pull polygon in towards its own centre.
  var centre_x, centre_y = 0.0
  for point in points:
    centre_x += point.x
    centre_y += point.y
  centre_x = centre_x / float(points.len)
  centre_y = centre_y / float(points.len)
  for point in points:
    result.add (centre_x + (point.x - centre_x) * factor, centre_y + (point.y - centre_y) * factor)


func polygon(points: seq[Point], should_close = true): string =
  ## Write polygon as path data.
  var joined: seq[string]
  for point in points:
    joined.add &"{numeral(point.x)} {numeral(point.y)}"
  let path = "M" & joined.join(" L")
  if should_close: path & " Z" else: path


func pip*(
  dancer: Dancer;
  corner_x, corner_y, side_x, side_y: float;
  arm: Arm;
  level: Option[Level];
  about = none(About);
): string =
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
    is_leading = dancer == Dancer.Lead
    ink = if is_leading: DEEP[arm] else: INK[arm]
    fill = fillOf(level, arm, is_leading)
    centre_x = corner_x + PIP / 2 + side_x / 2
    centre_y = corner_y + side_y / 2
    points: seq[Point] = @[
      (corner_x, corner_y),
      (corner_x + PIP, corner_y),
      (corner_x + PIP + side_x, corner_y + side_y),
      (corner_x + side_x, corner_y + side_y),
    ]
    perimeter = if is_leading: 2 * PIP + 2 * hypot(side_x, side_y)
                else: 2 * PI * (PIP / 2)

  func shape(inset: float, style: string): string =
    ## One outline or fill, as dancer's own mark: path or circle.
    if is_leading:
      let path = if inset == 1.0: polygon(points) else: polygon(scaled(points, inset))
      &"""<path d="{path}" {style}/>"""
    else:
      &"""<circle cx="{numeral(centre_x)}" cy="{numeral(centre_y)}"""" &
          &""" r="{numeral(PIP / 2 * inset)}" {style}/>"""

  var bits: seq[string]
  if about.isNone:
    bits.add shape(
      1.0,
      &"""fill="{fill}" stroke="{ink}" stroke-width="1.4"""" & """ stroke-linejoin="round"""",
    )
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
    bits.add &"""<circle cx="{numeral(centre_x)}" cy="{numeral(centre_y)}" r="2.5" fill="{ink}"/>"""
  bits.join("")


func marker*(kind: Row; corner_x, corner_y, side_x, side_y: float; arm: Arm): string =
  ## Draw row that counts nothing: it says count does not end.
  let
    ink = INK[arm]
    centre_x = corner_x + PIP / 2 + side_x / 2
    centre_y = corner_y + side_y / 2
  if kind == Row.Ellipsis:  # and so on, across
    for offset in [-3.7, 0.0, 3.7]:
      result.add &"""<circle cx="{numeral(centre_x + offset)}" cy="{numeral(centre_y)}" r="1.7"""" &
          &""" fill="{ink}"/>"""
  else:
    for offset in [-3.1, 3.1]:
      result.add &"""<circle cx="{numeral(centre_x)}" cy="{numeral(centre_y + offset)}" r="1.9"""" &
          &""" fill="{ink}"/>"""


func signBody(
  slots: seq[Row];
  lean: Lean;
  arms: SignArms;
  x_left, y_foot: float;
  about: Option[About];
  pip_about: seq[About];
  ending: Option[Ending];
  is_packed = true;
): tuple[markup: string, bounds: tuple[left, top, right, bottom: float]] =
  ## Draw sign at given place, returning markup and bounds it fills.
  ##   `slots` reads downwards, one entry per quarter turn, follow's
  ##     first, so mixed sign has one picture rather than two.
  ##   Stack packs up from foot: outline holds full turn, so
  ##     how full it is is how far it goes, and count is check on
  ##     reading rather than whole of it.
  let
    y_bottom = y_foot + HEIGHT
    y_top = y_foot
    slope = HEIGHT * TANGENT
    over = if ending in [some(Ending.Open), some(Ending.Spill)]: OVER else: 0.0
    slant = if lean == Lean.Clockwise: -LEAN_SINE else: LEAN_SINE

  func leftAt(y: float): float =
    ## Slanting left edge, at given height.
    if lean == Lean.Clockwise: x_left + (y_bottom - y) * TANGENT  # leans right going up
    else: x_left + (y - y_top) * TANGENT

  func slotTop(place: int): float =
    ## Top of slot `place` rows up from foot.
    y_bottom - GAP_X - float(place) * (PIP + GAP_X) - PIP

  let
    foot: seq[Point] = @[(leftAt(y_bottom), y_bottom),
                         (leftAt(y_bottom) + SIGN_BODY, y_bottom)]
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
        # No lid, and sides run on past where one would be: gauge that
        # never closes is count that never finishes.
        let tips: seq[Point] = @[(leftAt(y_top - over), y_top - over),
                                 (leftAt(y_top - over) + SIGN_BODY,
                                  y_top - over)]
        polygon(@[tips[0], foot[0], foot[1], tips[1]], should_close = false)
      else:
        polygon(@[foot[0], head[0], head[1], foot[1]])
  var bits = @[&"""<path d="{outline}" {style}/>"""]

  if ending == some(Ending.Loop):
    # Graph's own loop edge, drawn on its label.
    let
      (top_left_x, top_left_y) = head[0]
      (bottom_left_x, bottom_left_y) = foot[0]
      reach = 15.0
    bits.add &"""<path d="M{numeral(top_left_x - 2)} {numeral(top_left_y + 5)}""" &
        &""" C{numeral(top_left_x - reach)} {numeral(top_left_y + 6)}""" &
        &""" {numeral(bottom_left_x - reach)} {numeral(bottom_left_y - 6)}""" &
        &""" {numeral(bottom_left_x - 3)}""" &
        &""" {numeral(bottom_left_y - 5)}" fill="none" stroke="var(--ink)"""" &
        """ stroke-width="1.6" stroke-linecap="round"/>"""
    bits.add &"""<path d="M{numeral(bottom_left_x - 8)} {numeral(bottom_left_y - 8.5)}""" &
        &""" L{numeral(bottom_left_x - 3)} {numeral(bottom_left_y - 5)}""" &
        &""" L{numeral(bottom_left_x - 8.5)} {numeral(bottom_left_y - 2.5)}" fill="none"""" &
        """ stroke="var(--ink)" stroke-width="1.6"""" &
        """ stroke-linecap="round" stroke-linejoin="round"/>"""

  let
    total = slots.len
    spread = (HEIGHT - float(total) * PIP) / float(total + 1)
  for i, what in slots:
    var top = if is_packed: slotTop(total - 1 - i)
              else: y_top + spread + float(i) * (PIP + spread)
    top += (PIP - PIP * LEAN_COSINE) / 2
    for column, arm in [Arm.Left, Arm.Right]:
      if not arms[arm].is_shown:
        continue
      let corner_x = leftAt(top) + GAP_X + float(column) * (PIP + GAP_X)
      if what in [Row.Lead, Row.Follow]:
        let row_about = if pip_about.len > 0: some(pip_about[i])
                        else: none(About)
        bits.add pip(
          (if what == Row.Lead: Dancer.Lead else: Dancer.Follow),
          corner_x, top, PIP * slant, PIP * LEAN_COSINE, arm, arms[arm].level,
          row_about)
      else:
        bits.add marker(what, corner_x, top, PIP * slant, PIP * LEAN_COSINE, arm)

  var
    x_values: seq[float]
    y_values = @[y_bottom, y_top - over]
  for y in y_values:
    x_values.add leftAt(y)
  for y in y_values:
    x_values.add leftAt(y) + SIGN_BODY
  if ending == some(Ending.Loop):
    x_values.add min(foot[0].x, head[0].x) - 16
  (bits.join("\n        "), (min(x_values), y_top - over, max(x_values), y_bottom))


func sign*(
  slots: seq[Row],
  lean = Lean.Clockwise,
  arms = BOTH_UNSAID,
  about = none(About),
  pip_about: seq[About] = @[],
  ending = none(Ending),
  scale = 1.2,
  is_packed = true,
): string =
  ## Draw one turn sign: quarter turns up from foot, arms across, one
  ## height for every sign.
  let
    rows =
      if ending == some(Ending.EllipsisEnd): @[Row.Ellipsis] & slots
      elif ending == some(Ending.RepeatEnd): @[Row.Repeat] & slots
      elif ending == some(Ending.Spill):
        # Pip cut by missing lid repeats whoever top quarter is.
        @[slots[0]] & slots
      else: slots
    (markup, bounds) = signBody(
      rows,
      lean,
      arms,
      x_left = PAD,
      y_foot = PAD + OVER,
      about = about,
      pip_about = pip_about,
      ending = ending,
      is_packed = is_packed,
    )
    view_width = bounds.right - bounds.left + 2 * PAD
    view_height = bounds.bottom - bounds.top + 2 * PAD
  &"""<svg viewBox="{numeral(bounds.left - PAD)} {numeral(bounds.top - PAD)}""" &
      &""" {numeral(view_width)} {numeral(view_height)}"""" &
      &""" width="{numeral(view_width * scale)}" height="{numeral(view_height * scale)}">""" &
      &"\n        {markup}\n      </svg>"
