## Draw only where couple are and where they can go next.
##
##   Map of everything answers "what is there"; this answers "what now".
##     Frame couple hold sits in middle, and every move away
##     from it is spoke: nothing else is drawn.
##     Cost of drawing nothing else: whole ontology is not visible here
##       -- map keeps that job.  Accepted -- everything else is
##       distraction from one decision being made.
##   Spokes keep map's sense of direction.  `collect` takes
##     hand, so it points up; `drop` releases one, so it points down;
##     compound is two moves and goes out to side.  Dancer who has
##     read one drawing can read other.
##   Frame couple came from is remembered so that drawing can
##     start it where it was and let it arrive: spoke that was taken
##     becomes middle, which is what taking it means.
##   Every frame is drawn in one fixed space, so coordinate means same
##     place whichever frame is held, and node can travel from where it
##     was to where it is.  What changes between frames is *window* on
##     that space, cut to what that frame needs: frame whose ways out all
##     point up has nothing below it and is seen through shorter window
##     than one with ways out both ways.
##     Cost of one space for every frame: any one frame fills corner of
##       it, so each must be seen through its own window, and window and
##       drawing have to move together -- which is what makes change of
##       frame one movement rather than cut.

{.experimental: "strictFuncs".}

import std/[math, options, strutils]

import ./diagram
import ./frame
import ./map
import ./motion
import ./transition



#[ Layout ]#

const
  CENTRE_X = 330
  CENTRE_Y = 268
  NODE_WIDTH = 112
    ## Width every frame in drawing is drawn at, one held included.
    ##   One size for all of them, because frame chosen stays on
    ##     screen across moment drawing is replaced: drawn at two
    ##     sizes it would have to be scaled from one to other, and
    ##     node's plate and its name do not scale with its width, so two
    ##     would never quite line up.  Which frame is held is said by
    ##     mark around it instead of by its size.
  SPOKE_RADIUS = 240 ## Length of lone spoke; crowded one reaches further.
  SPOKE_STEP = 40.0  ## Angle between two spokes of same kind, in degrees.
  LABEL_SIZE* = 11   ## Size name is drawn at, in drawing's own units.
  LEAST_READABLE* = 8
    ## Smallest name may end up on screen, once drawing has been
    ## shrunk.
    ##   Drawing shrinks to whatever room there is, and whole of it
    ##     shrinks together, names included.  Past this names are shapes
    ##     rather than words, and drawing of your options whose options
    ##     cannot be read is not worth fitting: below it drawing keeps
    ##     its size and scrolls instead.
  NAME_ROOM = 24     ## Room frame's own name takes above it.
  LABEL_DROP = 6     ## Gap between frame and name of move that reaches it.
  ##   Move is named under frame it arrives in rather than along
  ##     line that leads there.  Along line, four names leaving one
  ##     middle crowd each other however far out they are put; under
  ##     frames, they are as far apart as frames are.
  UP = 270.0        ## Direction collect points, in degrees clockwise from east.
  DOWN = 90.0       ## Direction drop points.
  ASIDE = 0.0       ## Direction compound points.



#[ Tempo ]#

const
  FOLD_SPREAD* = 60
    ## Budget for starting one way folding after another, in milliseconds.
  FOLD_LAG* = 50
    ## How far behind its own leaf branch begins to fold.
  FOLD_LEAF* = 120
    ## Folding one leaf away: leaf growing, run backwards.
  FOLD_BRANCH* = 110
    ## Folding one branch back into middle: branch growing, run backwards.
  SHRINK_TIME* = 140
    ## Shrinking away frame left behind, once mark has left it.
  CENTRE_TIME* = 340
    ## Recentring drawing on frame reached, which is now all there is.
  GROW_DELAY* = 50
    ## Wait after drawing is replaced before first new way grows.
  GROW_SPREAD* = 90
    ## Budget for starting one way growing after another.
  LEAF_DELAY* = 100
    ## Wait between branch growing and its own leaf, which is what makes
    ## drawing read as branches first and leaves after rather than as one bloom.
  GROW_TIME* = 170
    ## Growing one branch, or one leaf once its branch has arrived.


const CLOSE_TEMPO* = Tempo(
  ## Hold how long this drawing takes to say move.
  ##   It has most to do of any of them: ways not taken have to be
  ##     out of way before mark can move, and ways out of
  ##     frame reached have to be built afterwards, so mark sets off
  ##     late and drawing is still working long after it has arrived.
  pass_at: FOLD_SPREAD + FOLD_LAG + FOLD_BRANCH,
  pass: 200,
  settle: SHRINK_TIME + CENTRE_TIME + SEAM_MARGIN,
  grown: GROW_DELAY + GROW_SPREAD + LEAF_DELAY + GROW_TIME,
)


const
  SHRINK_AT* = CLOSE_TEMPO.pass_at + CLOSE_TEMPO.pass
    ## When frame left behind starts to go, which is once mark has left.
  CENTRE_AT* = SHRINK_AT + SHRINK_TIME
    ## When drawing starts recentring on one frame left in it.


func closeStyle*(): string =
  ## Write this drawing's own times onto it, beside ones every drawing has.
  passStyle(CLOSE_TEMPO) & "; --fold-spread: " & $FOLD_SPREAD &
    "ms; --fold-lag: " & $FOLD_LAG & "ms; --fold-leaf: " & $FOLD_LEAF &
    "ms; --fold-branch: " & $FOLD_BRANCH & "ms; --shrink-at: " & $SHRINK_AT &
    "ms; --shrink: " & $SHRINK_TIME & "ms; --centre-at: " & $CENTRE_AT &
    "ms; --centre: " & $CENTRE_TIME & "ms; --grow-delay: " & $GROW_DELAY &
    "ms; --grow-spread: " & $GROW_SPREAD & "ms; --leaf-delay: " & $LEAF_DELAY &
    "ms; --grow: " & $GROW_TIME & "ms" &
    # Drawing is laid out in numbers rather than lengths so that
    # stylesheet can divide room it has by them; these are what it
    # multiplies them back up by, and how far down it may go.
    "; --least-unit: " & formatFloat(LEAST_READABLE / LABEL_SIZE, ffDecimal, 3) &
    "px"



#[ Concepts ]#

type
  Spoke* = object ## Hold one way out of frame couple are holding.
    to*: Frame           ## Frame it arrives in.
    side*: Side          ## Arm that acts, which is ink it is drawn in.
    lines*: seq[string]  ## Name of move, line by line.
    is_compound*: bool   ## Whether it is two moves rather than one.
    back*: Option[Side]  ## Arm that acts coming other way, where they differ.
    angle*: float        ## Direction it leaves middle, in degrees.
    radius*: int         ## How far out it puts frame it arrives in.
    turn*: int           ## Its place in order ways grow and fold.


func spokesOf*(here: Frame): seq[Spoke] =
  ## Get every way out of frame, in order they are drawn.
  ##   Collects, then drops, then compounds: order eye reads them
  ##     in, up page and then down it and then out to side.
  for helper in [Helper.Collect, Helper.Drop]:
    var kin: seq[Spoke] = @[]
    for move in moves(here):
      if move.helper != helper:
        continue
      kin.add Spoke(
        to: move.to,
        side: move.side,
        lines: label(here, move),
        is_compound: false,
      )
    # Crowded fan reaches further out, so that its spokes end up as far apart
    # as pair of them would be.
    let base = if helper == Helper.Collect: UP else: DOWN
    for index, spoke in kin:
      var placed = spoke
      placed.angle = base + (index.float - (kin.len - 1).float / 2) * SPOKE_STEP
      placed.radius = SPOKE_RADIUS + (kin.len - 1) * 30
      result.add placed

  var named: seq[Spoke] = @[]
  for target in FRAMES:
    let compounded = compound(here, target)
    if compounded.isNone:
      continue
    # Compound hands follow's hand from one of lead's arms to
    # other, so it has arm going out and different one coming back.
    # Drawing is inked in both: one arm for line that only ever means one.
    named.add Spoke(
      to: target,
      side: compoundSide(here, target).get,
      back: compoundSide(target, here),
      lines: @[compoundName(here, target), "two moves"],
      is_compound: true,
    )
  for index, spoke in named:
    var placed = spoke
    placed.angle = ASIDE + (index.float - (named.len - 1).float / 2) * SPOKE_STEP
    placed.radius = SPOKE_RADIUS + (named.len - 1) * 30
    result.add placed

  for index in 0 ..< result.len:
    result[index].turn = index


func endOf*(spoke: Spoke): (int, int) =
  ## Get where spoke puts frame it arrives in.
  let radians = spoke.angle * PI / 180
  (CENTRE_X + int(round(cos(radians) * spoke.radius.float)),
    CENTRE_Y + int(round(sin(radians) * spoke.radius.float)))


func labelAt*(spoke: Spoke): (int, int) =
  ## Get where name of spoke sits, under frame it arrives in.
  let (x, y) = endOf(spoke)
  (x, y + frameHeight(NODE_WIDTH) div 2 + LABEL_DROP +
    plateSpan(spoke.lines)[1] div 2)



#[ Ink ]#

const
  COLOUR_QUIET = "var(--dim, #6b716e)"
    ## Ink for name whose line has no one ink of its own to lend it.
  LABEL_FONT = "font: " & $LABEL_SIZE & "px 'Noto Sans', ui-sans-serif, system-ui, sans-serif"

  # Arm inks come from `map.armColour` and label plates from
  # `map.stack`, which this drawing shares rather than repeats: two views
  # draw one ontology and reader moves between them, so line that changed
  # hue on way, or name that changed its plate, would be saying
  # something.


func textHalf(text: string): int = text.len * 3 + 7
  ## Get how far line of text reaches either side of point it is centred on.


func naming(x, y: int; lines: seq[string]; colour: string): string =
  ## Draw name of spoke, over plate so that it reads across its line.
  ##   `map.stack`, in this drawing's own font and ink: one plate rule, worn
  ##     by both views.
  stack(x, y, lines, LABEL_FONT & "; fill: " & colour, "spoke-plate")



#[ Space and Window ]#

func extentOf(here: Frame): (int, int, int, int) =
  ## Get box one frame's drawing needs, and no more.
  ##   Frame with only collects has nothing below it and frame with only
  ##     drops has nothing above, so box that holds one frame is not
  ##     box that holds another.  This is what window is cut to; it is
  ##     not what frame is drawn in.
  const PAD = 14
  # Frame's name is often wider than frame it names, and name is part of
  # drawing: box measured to pictures alone would cut words off.
  var
    left = CENTRE_X - max(NODE_WIDTH div 2 + 8, textHalf(here.describe))
    right = CENTRE_X + max(NODE_WIDTH div 2 + 8, textHalf(here.describe))
    top = CENTRE_Y - frameHeight(NODE_WIDTH) div 2 - NAME_ROOM
    bottom = CENTRE_Y + frameHeight(NODE_WIDTH) div 2 + 6
  for spoke in spokesOf(here):
    let
      (x, y) = endOf(spoke)
      (_, ly) = labelAt(spoke)
      # Measured at size way out grows to when it is one taken, since
      # it grows where it stands and window cut any tighter would clip it.
      half = max(max(widest(spoke.lines), spoke.to.describe.len) * 3 + 7,
        NODE_WIDTH div 2 + 8)
    left = min(left, x - half)
    right = max(right, x + half)
    top = min(top, y - frameHeight(NODE_WIDTH) div 2 - NAME_ROOM)
    bottom = max(bottom, max(ly + plateSpan(spoke.lines)[1] div 2,
      y + frameHeight(NODE_WIDTH) div 2))
  (left - PAD, top - PAD, right - left + 2 * PAD, bottom - top + 2 * PAD)


func spokesBox(): (int, int, int, int) {.compileTime.} =
  ## Get one space every frame is drawn in: box that holds them all.
  ##   Fitting space to each frame would move middle from frame to
  ##     frame, and node travelling in from where it was would be
  ##     travelling in coordinate system that had changed under it.  One
  ##     space for all of them means place is place, and window does
  ##     fitting instead.
  var (left, top, right, bottom) = (CENTRE_X, CENTRE_Y, CENTRE_X, CENTRE_Y)
  for here in FRAMES:
    let (x, y, w, h) = extentOf(here)
    left = min(left, x)
    top = min(top, y)
    right = max(right, x + w)
    bottom = max(bottom, y + h)
  (left, top, right - left, bottom - top)


const SPOKES_BOX* = spokesBox()
  ## Hold space every frame is drawn in, as `x`, `y`, `width`, `height`.


const MIDDLE* = (CENTRE_X, CENTRE_Y)
  ## Hold one place frame being held is drawn, in every frame.


func windowOf*(here: Frame): (int, int, int, int) =
  ## Get window one frame is seen through: exactly what that frame needs.
  ##   Frame with only collects has nothing below it, so window that
  ##     reserved room below would be mostly empty.  Window is cut to
  ##     drawing and drawing slides under it, which is why both have
  ##     to move together.
  extentOf(here)


func panOf*(window: (int, int, int, int)): (int, int) =
  ## Get where drawing sits behind window, so window shows that part.
  (SPOKES_BOX[0] - window[0], SPOKES_BOX[1] - window[1])



#[ Drawing ]#

func spokeClass(spoke: Spoke; motion: Motion; taken: Option[Frame]): string =
  ## Say what one way out of frame is doing while couple move.
  result = "spoke" & (if spoke.is_compound: " two" else: "")
  if motion != Motion.Leaving:
    return
  result.add(if taken == some(spoke.to): " taken" else: " going")


func renderSpokes*(here: Frame; motion = Motion.Still;
    taken = none(Frame)): string =
  ## Draw frame couple hold, every way out of it, and move being
  ## made.
  ##   While move is being told, this draws frame it is being made
  ##     *from*: whole sentence -- ways not taken folding, mark
  ##     passing along way taken, frame left behind going,
  ##     drawing recentring on frame reached -- happens in this one
  ##     drawing, without page touching it again.
  ##   What that leaves at end is one frame, marked, in middle of
  ##     window cut for it, with nothing around it.  That is exactly
  ##     drawing this function returns for that frame standing still, which
  ##     is why page can replace one with other there and no
  ##     reader can tell.
  let
    (bx, by, bw, bh) = SPOKES_BOX
    leaving = motion == Motion.Leaving and taken.isSome
    window = windowOf(here)
    (px, py) = panOf(window)
  # Where drawing has to end up for frame reached to be sitting where
  # frame it is holding sits: its own window, shifted by distance from
  # middle out to wherever along drawing that frame is standing now.
  var
    reached = window
    (qx, qy) = (px, py)
    (mx, my) = (0, 0)
  if leaving:
    for spoke in spokesOf(here):
      if spoke.to != taken.get:
        continue
      let (ex, ey) = endOf(spoke)
      reached = windowOf(taken.get)
      let (rx, ry) = panOf(reached)
      (qx, qy) = (rx + CENTRE_X - ex, ry + CENTRE_Y - ey)
      (mx, my) = (ex - CENTRE_X, ey - CENTRE_Y)

  # Every number animation spends is written here, so that stylesheet
  # holds shape of movement and this holds its size.
  # Window and pan are bare numbers, not lengths.  Stylesheet has to
  # divide room it has by width drawing wants, and length cannot
  # be divided by length -- so drawing hands over numbers and takes
  # back one unit to multiply them by.  Everything drawing is made of is
  # multiple of that one unit, so scaling it is one value changing.
  #
  # `--mx`, `--my`, `--ox` and `--oy` stay lengths: they are read inside
  # picture, in its own units, and scale with it already.
  result = "<div class=\"viewport " & phase(motion) & "\" style=\"" &
    closeStyle() & "; --bw: " & $bw & "; --bh: " & $bh &
    "; --w: " & $window[2] & "; --h: " & $window[3] &
    "; --px: " & $px & "; --py: " & $py &
    "; --to-w: " & $reached[2] & "; --to-h: " & $reached[3] &
    "; --to-px: " & $qx & "; --to-py: " & $qy &
    "; --mx: " & $mx & "px; --my: " & $my &
    "px; --ox: " & $CENTRE_X & "px; --oy: " & $CENTRE_Y & "px\">"
  result.add "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"" & $bx & " " &
    $by & " " & $bw & " " & $bh & "\" width=\"" & $bw & "\" height=\"" & $bh &
    "\" class=\"spokes\" role=\"img\">" &
    "<title>" & here.describe & ", and every move away from it</title>"

  # Each way out in turn: its branch from middle, then frame and
  # name it carries.
  let ways = spokesOf(here)
  for spoke in ways:
    let
      (x, y) = endOf(spoke)
      (lx, ly) = labelAt(spoke)
      colour = armColour(spoke.side)
      # Stagger is share of one budget rather than step of its own, so
      # last way out finishes when phase does however many there are.
      share =
        if ways.len < 2: "0"
        else: formatFloat(spoke.turn / (ways.len - 1), ffDecimal, 3)
    result.add "<g class=\"" & spokeClass(spoke, motion, taken) &
      "\" style=\"--turn: " & share & "; --lx: " & $x & "px; --ly: " & $y &
      "px\">"
    # Branch grows out of middle and leaf out of its own place, so each
    # carries point it moves about rather than borrowing drawing's.
    result.add "<g class=\"branch\">"
    if spoke.back.isSome and spoke.back.get != spoke.side:
      # Two moves, two arms: inked from middle out in arm that acts
      # coming back, and from halfway out in arm that acts going.
      let (hx, hy) = ((CENTRE_X + x) div 2, (CENTRE_Y + y) div 2)
      result.add "<line class=\"spoke-line\" x1=\"" & $CENTRE_X & "\" y1=\"" &
        $CENTRE_Y & "\" x2=\"" & $hx & "\" y2=\"" & $hy & "\" style=\"stroke: " &
        armColour(spoke.back.get) & "\"/>"
      result.add "<line class=\"spoke-line\" x1=\"" & $hx & "\" y1=\"" & $hy &
        "\" x2=\"" & $x & "\" y2=\"" & $y & "\" style=\"stroke: " & colour &
        "\"/>"
    else:
      result.add "<line class=\"spoke-line\" x1=\"" & $CENTRE_X & "\" y1=\"" &
        $CENTRE_Y & "\" x2=\"" & $x & "\" y2=\"" & $y & "\" style=\"stroke: " &
        colour & "\"/>"
    result.add "</g>"
    result.add "<g class=\"leaf\">"
    result.add "<g class=\"bud\">" & nodeAt(spoke.to, x, y, NODE_WIDTH,
      (if spoke.is_compound: "two" else: "reachable")) & "</g>"
    result.add "<g class=\"tag\">" & naming(lx, ly, spoke.lines,
      (if spoke.is_compound: COLOUR_QUIET else: colour)) & "</g>"
    result.add "</g></g>"

  # Frame held, and then mark on it: mark is drawn last so that it
  # reads over whatever it is marking, and can leave without taking it along.
  result.add "<g class=\"core\">" &
    nodeAt(here, CENTRE_X, CENTRE_Y, NODE_WIDTH, "held") & "</g>"
  result.add markAt(CENTRE_X, CENTRE_Y, NODE_WIDTH)
  result.add "</svg></div>"
