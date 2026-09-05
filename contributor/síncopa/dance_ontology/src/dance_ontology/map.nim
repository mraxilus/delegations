## Draw whole ontology as one picture: frames as places, moves as
## ways between them.
##
##   Graph is laid out in rows by how many connections frame carries,
##     which makes direction of move readable from drawing alone:
##     every step up page adds connection and is `collect`, every
##     step down releases one and is `drop`.  So edge needs to say only
##     which arm acts, and row it moves between says rest.
##     Cost of rows by count: where frame sits is fixed by what it holds,
##       so only order within row (`NODE_ORDER`) is free to keep lines
##       from crossing.  Accepted -- rows say collect or drop for every
##       edge at once.
##   `free` is at bottom and two-handed frames are at top,
##     because collect builds frame up and drop lets it fall.
##     Rows are tower rather than list, and whole page keeps that
##     sense: close drawing points its ways out same way, and
##     matrix orders its axes down it.
##   Each edge stands for pair of moves that cross it, because every
##     move reverses.  Twenty moves are ten lines.
##     Cost of one line for two moves: line cannot name both, so which
##       move it is named for has to be settled per reader (see `edge`).
##       Accepted -- twenty moves are ten lines.
##   Compounds are drawn too, dashed and curved, because they join
##     frames that no single move joins: they are shape of graph
##     rather than edge of it.
##     Cost of drawing compounds: curves hang below their rows, and
##       drawing carries height they need (`ARC_DIP`, `MAP_HEIGHT`).
##       Accepted -- map missing them would be missing graph's shape.

{.experimental: "strictFuncs".}

import std/[algorithm, math, options, strutils]

import ./diagram
import ./frame
import ./motion
import ./transition
import ./draw/[style, terms]



#[ Layout ]#

const
  MAP_WIDTH* = 780
    ## Width map asks for; `--wide` in app's stylesheet is
    ## derived from it plus page's margins.
  MAP_HEIGHT* = 570
    ## Measured, not chosen: tallest drawing gets in any of
    ## states it can be read in.
    ##   Compounds hang below their own row, and row that has none
    ##     of them is now bottom one, so turning tower up right
    ##     way left old height carrying eighty pixels of nothing.
  MARGIN = 44
  ROW_Y = [510, 265, 70]
    ## Row for each number of connections frame can carry.
    ##   Descending, because tower is built upwards: hold nothing and
    ##     you are at bottom, hold both hands and you are at top.
  NODE_WIDTH* = 74
    ## Width frame's picture is drawn at on map.
  NAME_RISE = 12 ## Distance from top of picture up to its name.
  ARC_DIP = 100  ## How far compound curve hangs below row it joins.


const NODE_ORDER* = ["--.", "-r.", "l-.", "-l.", "r-.", "lrL", "lrR", "rl."]
  ## Order frames along their rows, left to right.
  ##   Drawing decision rather than fact about dancing: order is
  ##     one that leaves fewest lines crossing.
  ##   `tests/tmap.nim` holds it to naming every frame exactly once, so
  ##     frame cannot be added to ontology and quietly left out of
  ##     picture.


func rowOf(target: Frame): int = target.countHolds
  ## Get row that frame is drawn in.


func towerOrder*(): seq[Frame] =
  ## Get every frame in order tower stacks them, top row first.
  ##   Here rather than where it is read, because where frame goes is what
  ##     this module already decides, for `NODE_ORDER` and `rowOf` alike.
  ##   Anything else that puts frames in order -- matrix orders both
  ##     its axes down tower, so that reading it and reading map are
  ##     same reading -- takes order from here and cannot drift from
  ##     drawing.
  for row in countdown(ROW_Y.high, 0):
    for key in NODE_ORDER:
      let candidate = fromKey(key)
      if candidate.isSome and rowOf(candidate.get) == row:
        result.add candidate.get


func placeOf(target: Frame): int =
  ## Get position of frame along its row, counting from left.
  for key in NODE_ORDER:
    let candidate = fromKey(key)
    if candidate.isNone or candidate.get == target:
      break
    if rowOf(candidate.get) == rowOf(target):
      inc result


func rowSize(row: int): int =
  ## Count frames drawn in one row.
  for key in NODE_ORDER:
    let candidate = fromKey(key)
    if candidate.isSome and rowOf(candidate.get) == row:
      inc result


func centreOf*(target: Frame): (int, int) =
  ## Get middle of place frame is drawn in.
  let
    span = MAP_WIDTH - 2 * MARGIN
    size = rowSize(rowOf(target))
    step = span div size
  (MARGIN + step * placeOf(target) + step div 2, ROW_Y[rowOf(target)])



#[ Ink ]#

const
  COLOUR_INK = "var(--ink, #1a1f1e)"
  COLOUR_DIM = "var(--dim, #6b716e)"
  LABEL_FONT = "font: 11px ui-sans-serif, system-ui, sans-serif"
  LINE_HEIGHT* = 12 ## Height of one line of stacked name.
  NAME_FONT = "font: 11px ui-sans-serif, system-ui, sans-serif"


func armColour*(side: Side): string =
  ## Get ink one arm of lead is drawn in.
  ##   **Deep** shade, because line on this map is lead acting: they
  ##     are one who collects and drops, and deep shade is theirs
  ##     wherever two dancers are told apart (`draw/style`).  It used to be
  ##     plain one, which is follow's -- so every line said right
  ##     arm in wrong voice, and key beside it said so too.
  ##   Asked of shared palette rather than kept here.  This module and
  ##     `spokes` each had their own copy, and copies had already drifted
  ##     from frame pictures' by whole hue.
  DEEP[if side == Side.Left: Arm.L else: Arm.R]


func followColour*(site: Site): string =
  ## Get ink one hand of follow is drawn in.
  ##   Plain shade, which is theirs wherever two dancers are told
  ##     apart -- same ink that hand's own mark carries in every frame
  ##     picture on page.
  INK[if site == Site.LeftHand: Arm.L else: Arm.R]


func labelled*(line: string): string =
  ## Say one line of name as markup, each hand in its own dancer's ink.
  ##   Name says which hands it joins, and until now said it in one voice:
  ##     `collect right` was all of it acting arm's deep ink, while
  ##     `right` there is *follow's* hand and is drawn in their plain
  ##     shade everywhere else on page.  Inked apart, words draw
  ##     connection they name -- deep running into plain, hand to hand,
  ##     way picture beside them does (rule 9).
  ##   Every name drawing writes, and not only move's: frame is called
  ##     `Left to left` because those are two hands it joins, so it is
  ##     drawn in them for same reason line beside it is.  Reader
  ##     who has learnt two shades anywhere has learnt them everywhere.
  ##   Only stretch that names hand is wrapped, so line with no hand in
  ##     it -- `over`, `cut`, `two moves`, `free` -- stays one plain text
  ##     node it always was, and space before hand stays outside
  ##     wrapping so words are still words.
  ##   Line's own width is measured before this, on plain text, since
  ##     what plate has to cover is letters and not markup.
  for run in named(line):
    if run.lead.isNone and run.follow.isNone:
      result.add run.text
      continue
    let ink = if run.lead.isSome: armColour(run.lead.get)
              else: followColour(run.follow.get)
    result.add "<tspan style=\"fill: " & ink & "\">" & run.text & "</tspan>"



#[ Elements ]#

func text(x, y: int; body, style: string; classes = "map-label"): string =
  ## Draw one label, centred on point, in hands words name.
  ##   Every word drawing writes goes through here -- line's name,
  ##     curve's, frame's -- so hands are inked one way in all of
  ##     them and no caller has to remember to ask.
  "<text class=\"" & classes & "\" x=\"" & $x & "\" y=\"" & $y &
    "\" text-anchor=\"middle\" style=\"" & style & "\">" & labelled(body) &
    "</text>"


func widest*(lines: seq[string]): int =
  ## Get length of longest line, in characters.
  for line in lines:
    result = max(result, line.len)


func plateSpan*(lines: seq[string]): (int, int) =
  ## Get width and height of plate stacked label sits on.
  ##   One encoding of plate rule.  This module and `spokes` each
  ##     had copy, character for character, which is drift shared
  ##     palette was made to end for inks.
  (widest(lines) * 6 + 14, lines.len * LINE_HEIGHT + 4)


func stack*(x, y: int; lines: seq[string]; style, plate_class: string): string =
  ## Draw label of several short lines, centred on point, over plate.
  ##   Stacking is what lets label sit beside line without reaching
  ##     across drawing: three short words are third of width of
  ##     one long phrase.
  let
    (width, height) = plateSpan(lines)
    top = y - height div 2
  result = "<rect class=\"" & plate_class & "\" x=\"" & $(x - width div 2) &
    "\" y=\"" & $top & "\" width=\"" & $width & "\" height=\"" & $height &
    "\" rx=\"3\"/>"
  for index, line in lines:
    result.add text(x, top + LINE_HEIGHT * (index + 1) - 1, line, style)


func waking(is_standing, was_standing, is_moving: bool): string =
  ## Say how something's standing is changing while mark is on its way.
  ##   Map is drawn as frame being reached will have it, and whatever
  ##     that changes is faded from how frame being left had it.  What is
  ##     left when mark lands is then already drawing for where it
  ##     landed, so page can replace one with other and nothing
  ##     moves.
  if not is_moving or is_standing == was_standing: ""
  elif is_standing: " waking"
  else: " dozing"


type Box* = tuple[x, y, w, h: int] ## Room something takes up in drawing.


func overlaps*(a, b: Box): bool =
  ## Test whether two things in drawing would be drawn over each other.
  a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h


func labelBox(x, y: int; lines: seq[string]): Box =
  ## Get room name takes up, centred on point.
  let (w, h) = plateSpan(lines)
  (x - w div 2, y - h div 2, w, h)


func nameBox*(target: Frame; cx, cy, width: int): Box =
  ## Get room frame's name takes up, above frame it names.
  ##   One answer, used both to draw plate that keeps lines off
  ##     words and to keep other names away from them, so two cannot
  ##     drift apart.
  let
    height = frameHeight(width)
    named = target.describe.len * 6 + 10
  (cx - named div 2, cy - height div 2 - NAME_RISE - 11, named, 15)


func frameBoxes*(): seq[Box] =
  ## Get room every frame on map takes up: its picture, and its name.
  ##   Two boxes rather than one around both, because frame's name is
  ##     often much wider than frame and sits only above it.  One box
  ##     around pair would claim space either side of picture
  ##     that nothing is in, and there is little enough room on this drawing
  ##     as it is.
  for target in FRAMES:
    let
      (cx, cy) = centreOf(target)
      h = frameHeight(NODE_WIDTH)
    result.add (cx - NODE_WIDTH div 2 - 8, cy - h div 2 - 6,
      NODE_WIDTH + 16, h + 12)
    result.add nameBox(target, cx, cy, NODE_WIDTH)


const
  LABEL_ALONGS = [62, 44, 76, 34, 86, 26, 53, 69, 39, 81, 30, 90]
    ## Places along line where name will sit, in hundredths, in order of preference.
  LABEL_ASIDES = [0, -26, 26, -48, 48, -72, 72, -96, 96]
    ## Distances name may be nudged off its line, if nowhere on it is clear.
    ##   Naming every line rather than only ones underfoot means ten
    ##     names in drawing that used to hold three, and at one fixed
    ##     place along they land on top of each other where lines
    ##     converge.
    ##   Name takes first place that is clear of everything already
    ##     drawn, so drawing spreads them out itself rather than being
    ##     hand-placed and going stale next time frame or word
    ##     changes.


const
  LABEL_AIR = 5
    ## Daylight between line's cut end and box of name that cut it.
  LONG_ENOUGH = 999
    ## Dash longer than any line on map, for stretch after gap.


func gapAt(ax, ay, bx, by: int; box: Box): Option[(int, int)] =
  ## Get where name's box crosses its own line: how far line runs before
  ## break, and how long break is.
  ##   Nothing, where name sits clear of line -- which is what
  ##     `placeLabel` arranges whenever it can find room -- and typed
  ##     absence rather than zero reader must know to test for.
  ##   Box is clipped against line rather than measured from its
  ##     middle, so break is as wide as name really is at angle
  ##     line really crosses it.  Name met corner-on cuts less than one met
  ##     square, which is what eye expects.
  let
    run = float(bx - ax)
    rise = float(by - ay)
    length = sqrt(run * run + rise * rise)
  if length < 1:
    return none((int, int))
  var
    lo = 0.0
    hi = 1.0
  for (start, delta, near, far) in [
      (float(ax), run, float(box.x), float(box.x + box.w)),
      (float(ay), rise, float(box.y), float(box.y + box.h))]:
    if abs(delta) < 1e-9:
      if start < near or start > far:
        return none((int, int))        # runs parallel to box and outside it
    else:
      var
        t0 = (near - start) / delta
        t1 = (far - start) / delta
      if t0 > t1:
        swap t0, t1
      lo = max(lo, t0)
      hi = min(hi, t1)
  if hi <= lo:
    return none((int, int))            # name is not on this line at all
  let
    opens = max(lo * length - float(LABEL_AIR), 1.0)
    shuts = min(hi * length + float(LABEL_AIR), length)
  if shuts <= opens or int(shuts - opens) <= 0:
    return none((int, int))
  some((int(opens), int(shuts - opens)))


func isClear(box: Box; used: seq[Box]): bool =
  ## Test whether something can be drawn here without landing on anything else.
  for other in used:
    if overlaps(box, other):
      return false
  true


func placeBelow(x, y: int; lines: seq[string]; used: var seq[Box]): (int, int) =
  ## Get where curve's name can sit, sinking it until it is clear.
  for drop in [0, 22, -22, 44, -44, 66, 88]:
    let box = labelBox(x, y + drop, lines)
    if box.isClear(used):
      used.add box
      return (x, y + drop)
  used.add labelBox(x, y, lines)
  (x, y)


func placeLabel(ax, ay, bx, by: int; lines: seq[string];
    used: var seq[Box]): (int, int) =
  ## Get where name can sit near its line without landing on anything else.
  let
    run = bx - ax
    rise = by - ay
    length = max(1, int(sqrt(float(run * run + rise * rise))))
  for aside in LABEL_ASIDES:
    for along in LABEL_ALONGS:
      let
        x = ax + run * along div 100 - rise * aside div length
        y = ay + rise * along div 100 + run * aside div length
        box = labelBox(x, y, lines)
      if box.isClear(used):
        used.add box
        return (x, y)
  # Nowhere is clear, so take place it would have had and let it crowd:
  # name in wrong place still says more than no name at all.
  let
    x = ax + run * LABEL_ALONGS[0] div 100
    y = ay + rise * LABEL_ALONGS[0] div 100
  used.add labelBox(x, y, lines)
  (x, y)


func edge(a, b: Frame; side: Side; standing, was, taken: Option[Frame];
    used: var seq[Box]): (string, string) =
  ## Draw pair of moves that join two frames, and name them.
  ##   Ink and name come back apart so that drawing can put
  ##     every line down before it writes single word.  Together, line
  ##     drawn later crossed plate of name written earlier and struck
  ##     it through -- plate can only hide what is already under it.
  ##   Line is two moves, one each way, and it is named for one
  ##     reader could make: move *away* from where they stand, when they
  ##     stand on end of it.  Named for collect either way, line
  ##     leaving frame held upwards would be labelled with move that
  ##     comes back down it -- one thing reader cannot do from
  ##     there.
  ##   Line nobody stands on has no away, so it keeps reading that
  ##     needs no reader: move that adds connection, which is one
  ##     that runs up page.  Naming those too is what lets map be
  ##     read as map rather than only from where you happen to be.
  let
    (ax, ay) = centreOf(a)
    (bx, by) = centreOf(b)
    is_lit = standing == some(a) or standing == some(b)
    was_lit = was == some(a) or was == some(b)
    # Line mark is travelling along, while it is travelling along it.
    is_taken = (was == some(a) and taken == some(b)) or
      (was == some(b) and taken == some(a))
    marks = (if is_lit: " lit" else: "") & (if is_taken: " taking" else: "") &
      waking(is_lit, was_lit, was.isSome)
  # Two ends, asked for two different reasons, and since tower was turned up
  # right way they are no longer same end: what line is *called* is
  # read from frame holding less, and where name is *written* is
  # measured from whichever end is higher up drawing.
  let
    fewer = if rowOf(a) < rowOf(b): a else: b
    more = if rowOf(a) < rowOf(b): b else: a
    # Read from where couple stand if they stand here, and from frame
    # holding less otherwise, so line nobody stands on is named for move
    # that builds rather than one that lets go.
    source = if is_lit and standing == some(more): more else: fewer
    destination = if source == fewer: more else: fewer
    helper = classify(source, destination).get
    naming = label(source, Move(helper: helper, side: side, to: destination))
    # Measured from top either way, so that line's name does not jump from
    # one end to other as couple move: what move is called can change
    # under reader, where it is written should not.
    top = if centreOf(a)[1] <= centreOf(b)[1]: a else: b
    bottom = if top == a: b else: a
    (sx, sy) = centreOf(top)
    (dx, dy) = centreOf(bottom)
  # Name sits along line, wherever along it there is room.
  let (nx, ny) = placeLabel(sx, sy, dx, dy, naming, used)
  # And where it lands on line, line is *cut* for it rather than
  # painted over.  Plate hides what is under it and leaves hole with square
  # ends, which since frame pictures learned to break connection is
  # mark that means something else: gap says this one passes underneath.  So
  # line wears its own break, same way moving reach does -- dash
  # pattern, because element cut into pieces is different number of
  # pieces -- and round cap on each side says ending was meant.
  let
    cut = gapAt(ax, ay, bx, by, labelBox(nx, ny, naming))
    broken = if cut.isNone: ""
             else: "; stroke-dasharray: " & $cut.get[0] & " " & $cut.get[1] &
               " " & $LONG_ENOUGH
  # Line and name of line are one thing, and dim or come forward as
  # one: name without its line to belong to says nothing.  So two are put
  # in two groups wearing same marks rather than in one group.
  let ink = "<g class=\"way" & marks & "\">" &
    "<line class=\"edge\" x1=\"" & $ax & "\" y1=\"" & $ay &
    "\" x2=\"" & $bx & "\" y2=\"" & $by & "\" style=\"stroke: " &
    armColour(side) & "; stroke-linecap: round" & broken & "\"/></g>"
  (ink, "<g class=\"way naming" & marks & "\">" &
    stack(nx, ny, naming, LABEL_FONT & "; fill: " & armColour(side),
      "edge-plate") & "</g>")


func arcName(a, b: Frame; standing: Option[Frame]): string =
  ## Name compound that curve stands for, and hand it moves where it
  ## can.
  ##   Stood on one end, curve has direction like any other line, so it
  ##     can be named for move away from reader -- hand and all.
  ##   Stood on neither, it is one drawing of move that can be led either
  ##     way.  `place` carries same hand of follow whichever way
  ##     it is led, so it can still be named for that hand.  `cut` carries
  ##     whichever hand ends up on top, which is other one going
  ##     other way, so curve that named one of them would be wrong on half
  ##     of times it was read.  There it says only what it is.
  let helper = compound(a, b)
  if helper.isNone:
    return ""
  if standing == some(a):
    return compoundName(a, b)
  if standing == some(b):
    return compoundName(b, a)
  let there = compoundName(a, b)
  if there == compoundName(b, a): there else: ($helper.get).toLowerAscii


func arc(a, b: Frame; name: string; standing, was: Option[Frame];
    used: var seq[Box]): (string, string) =
  ## Draw compound as curve, since no single move joins two frames.
  ##   Ink and name apart, for reason `edge` parts them.
  let
    (ax, ay) = centreOf(a)
    (bx, by) = centreOf(b)
    mx = (ax + bx) div 2
    dip = ARC_DIP + (abs(ax - bx) div 5)
    is_lit = standing == some(a) or standing == some(b)
    was_lit = was == some(a) or was == some(b)
    lit = (if is_lit: " lit" else: "") & waking(is_lit, was_lit, was.isSome)
  # Drawn as two halves, each in ink of arm that acts as you travel into
  # it.  Ordinary line has one ink because same arm acts whichever way it
  # is read; compound has two because it hands follow's hand from one of
  # lead's arms to other, and which arm that is depends on which way you
  # are going.  Splitting curve is what lets it say both without lying about
  # either, and it stays dashed, because it is still two moves.
  let
    (px, py) = (mx, max(ay, by) + dip)
    (fx, fy) = ((ax + px) div 2, (ay + py) div 2)
    (gx, gy) = ((px + bx) div 2, (py + by) div 2)
    (hx, hy) = ((fx + gx) div 2, (fy + gy) div 2)
  func ink(side: Option[Side]): string =
    ## Half's own arm's ink, or quiet ink where no arm acts.
    if side.isSome: armColour(side.get) else: COLOUR_DIM
  var curve = "<g class=\"join" & lit & "\">" &
    "<path class=\"arc\" d=\"M" & $ax & " " & $ay & "Q" & $fx & " " & $fy &
    " " & $hx & " " & $hy & "\" style=\"stroke: " & ink(compoundSide(b, a)) &
    "\"/>" &
    "<path class=\"arc\" d=\"M" & $hx & " " & $hy & "Q" & $gx & " " & $gy &
    " " & $bx & " " & $by & "\" style=\"stroke: " & ink(compoundSide(a, b)) &
    "\"/>"
  curve.add "</g>"
  # Curve is at its lowest halfway along, which is half dip below row.
  let (nx, ny) = placeBelow(mx, max(ay, by) + dip div 2 + 4, @[name], used)
  (curve, "<g class=\"join naming" & lit & "\">" &
    stack(nx, ny, @[name], LABEL_FONT & "; fill: " & COLOUR_DIM, "arc-plate") &
    "</g>")


func nodeAt*(target: Frame; cx, cy, width: int; classes: string;
    extra = ""): string =
  ## Draw one frame at place, with its name above it.
  ##   Both drawings put frames somewhere; only they know where.  Keeping
  ##     drawing of node here means two agree on what frame
  ##     looks like even though they disagree about everything else.
  let height = frameHeight(width)
  result = "<g class=\"node " & classes & "\" data-frame=\"" & target.key &
    "\"" & extra & ">"
  result.add "<rect class=\"node-plate\" x=\"" & $(cx - width div 2 - 8) &
    "\" y=\"" & $(cy - height div 2 - 6) & "\" width=\"" & $(width + 16) &
    "\" height=\"" & $(height + 12) & "\" rx=\"8\"/>"
  result.add renderFramePlaced(target, cx - width div 2, cy - height div 2, width)
  # Name goes above picture, leaving space below for curves, and
  # gets plate of its own as every other name in drawing has: lines leave
  # frame from its middle, so they run out through words above it, and word
  # with line drawn through it is not word.
  let (nx, ny, nw, nh) = nameBox(target, cx, cy, width)
  result.add "<rect class=\"name-plate\" x=\"" & $nx & "\" y=\"" & $ny &
    "\" width=\"" & $nw & "\" height=\"" & $nh & "\" rx=\"3\"/>"
  result.add text(cx, cy - height div 2 - NAME_RISE, target.describe,
    NAME_FONT & "; fill: " & COLOUR_INK, "node-name")
  result.add "</g>"


func standingOf(target: Frame; where: Option[Frame]): (bool, bool, bool) =
  ## Get how frame stands to wherever couple are: held, reachable, or two.
  if where.isNone:
    return (false, false, false)
  (where == some(target), classify(where.get, target).isSome,
    compound(where.get, target).isSome)


func markAt*(cx, cy, width: int; extra = ""): string =
  ## Draw mark that says which frame is being held.
  ##   Its own element rather than heavier line on frame's own plate,
  ##     because it has to be able to leave one frame and arrive at another:
  ##     taking move is mark passing along way taken, and mark
  ##     that were part of frame could only blink from one to other.
  ##   Drawn to shape of frame's plate, from same numbers, so that
  ##     both drawings say *here* with same ring in same place.
  ##     Drawing that also thickened plate underneath would be saying it
  ##     twice.
  let height = frameHeight(width)
  "<rect class=\"mark\" x=\"" & $(cx - width div 2 - 8) & "\" y=\"" &
    $(cy - height div 2 - 6) & "\" width=\"" & $(width + 16) & "\" height=\"" &
    $(height + 12) & "\" rx=\"8\"" & extra & "/>"


func node(target: Frame; standing, was: Option[Frame]): string =
  ## Draw one frame in its row, on map of everything.
  let
    (cx, cy) = centreOf(target)
    (is_here, is_reachable, is_compound) = standingOf(target, standing)
    (was_here, was_reachable, was_compound) = standingOf(target, was)
    within = is_here or is_reachable or is_compound
  nodeAt(target, cx, cy, NODE_WIDTH,
    (if is_here: "here " else: "") & (if is_reachable: "reachable " else: "") &
    (if is_compound: "two" else: "") &
    waking(within, was_here or was_reachable or was_compound, was.isSome))



#[ Map ]#

const WIDE_TEMPO* = Tempo(
  ## Hold how long this drawing takes to say move.
  ##   Every frame is already drawn and in its place, so there is nothing to
  ##     clear before mark can move and nothing to build after it:
  ##     mark goes, what is within reach of it changes as it goes, and
  ##     drawing has finished.  Made to wait out close drawing's clauses
  ##     it would only look stuck.
  pass_at: 0,
  pass: 260,
  settle: SEAM_MARGIN,
  grown: 0,
)


func renderMap*(here: Option[Frame]; motion = Motion.Still;
    taken = none(Frame)): string =
  ## Draw graph, with couple standing on one frame if they are
  ## dancing.
  ##   While move is being made this is drawn as frame being *reached*
  ##     will have it, with whatever that changes fading from how frame
  ##     being left had it.  Mark is exception: it starts where
  ##     couple are and carries distance to where they are going, which
  ##     is move itself.  So what drawing settles into is already
  ##     drawing for where mark lands.
  let
    leaving = motion == Motion.Leaving and taken.isSome
    standing = if leaving: taken else: here
    was = if leaving: here else: none(Frame)
  result = "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 " &
    $MAP_WIDTH & " " & $MAP_HEIGHT & "\" class=\"map" &
    (if leaving: " leaving" else: "") &
    (if here.isNone: " unread" else: "") & "\" style=\"" &
    passStyle(WIDE_TEMPO) & "\" role=\"img\">" &
    "<title>Every frame, and every move between them</title>"

  # Every line goes down before any word does.  Name carries plate to keep
  # drawing out from under it, and plate can only hide what is already
  # there: written as each line was drawn, name was struck through by next
  # line to cross it.  So ink and names are gathered apart and laid in turn.
  #
  # Names are *placed* in other order.  Curves are placed first because
  # each has only one place it can be named, and every name after has to
  # keep clear of ones already put down.
  var used = frameBoxes()
  var ink, names = ""
  var curve_ink, curve_names = ""
  var drawn: seq[string] = @[]
  for source in FRAMES:
    for target in FRAMES:
      let helper = compound(source, target)
      if helper.isNone:
        continue
      let pair = sorted(@[source.key, target.key]).join("-")
      if pair in drawn:
        continue
      drawn.add pair
      let (drawing, naming) = arc(source, target,
        arcName(source, target, standing), standing, was, used)
      curve_ink.add drawing
      curve_names.add naming

  # Straight lines, their names taking whatever room curves' left.
  drawn = @[]
  for source in FRAMES:
    for move in moves(source):
      let pair = sorted(@[source.key, move.to.key]).join("-")
      if pair in drawn:
        continue
      drawn.add pair
      let (drawing, naming) = edge(source, move.to, move.side, standing, was,
        taken, used)
      ink.add drawing
      names.add naming
  result.add ink & curve_ink & names & curve_names

  # Frames go over lines, their plates hiding what runs beneath.
  for target in FRAMES:
    result.add node(target, standing, was)

  if here.isSome:
    # Mark sits on frame held and, while move is being made, carries
    # distance to frame chosen: taking move is mark passing along
    # line between them, which is same thing close drawing says.
    let
      (hx, hy) = centreOf(here.get)
      (tx, ty) = if leaving: centreOf(taken.get) else: (hx, hy)
    # Placed by where it is rather than moved to it, so that distance it
    # carries is distance to travel and not place to jump to.
    result.add markAt(hx, hy, NODE_WIDTH, " style=\"--mx: " & $(tx - hx) &
      "px; --my: " & $(ty - hy) & "px\"")
  result.add "</svg>"
