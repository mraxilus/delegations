## Draw rotation axis as what it is: one line, with couple on it.
##
##   Hand-to-hand half is graph, so it is drawn as graph.  Rotation
##     is not -- it is single quantity, twist, and every posture of one
##     frame held at one height is somewhere along it.  So it is drawn as
##     axle: postures laid out in order they are turned into,
##     couple standing on one, and every turn out of it as arc from where
##     they are to where it would put them.
##   Turns that cannot be taken are drawn too, dashed and dimmed, for
##     same reason map draws frames you cannot reach.
##     Cost of drawing refused: ink and room spent on turns couple
##       cannot take.  Accepted -- drawing that showed only what is
##       allowed would be menu, and what makes this validator is that
##       it can show turn and refuse it in same breath.
##   Nothing places this drawing yet.  App's Dance view is graph-first
##     and rotation exploration moved to design workbench, so
##     axle waits for page that stands postures in links.  `taxle`
##     holds its laws green in meantime, so wait cannot rot.

{.experimental: "strictFuncs".}

import std/options

import ./diagram
import ./map
import ./motion
import ./rotation



#[ Layout ]#

const
  AXLE_HEIGHT* = 360 ## Height axle drawing asks its viewBox for.
  NODE_WIDTH = 84   ## Width posture is drawn at along axle.
  STEP = 132       ## Distance along axle between one half turn and next.
  AXLE_Y = 250     ## Row postures are drawn in, under their arcs.
  NAME_RISE = 14   ## Distance from top of picture up to its name.
  ARC_RISE = 100   ## How far above axle shortest turn's arc reaches.
  LABEL_FONT = "font: 11px ui-sans-serif, system-ui, sans-serif"


func axleWidth*: int =
  ## Get how wide axle has to be for postures that stand on it.
  ##   Constant expression today -- every posture stands on same axle
  ##     -- and callable so width can start depending on posture
  ##     without callers changing.  It used to take posture and
  ##     read nothing from it, which promised dependence untruthfully.
  2 * (MOST_TURN * STEP) + NODE_WIDTH + 60


func centreOf*(stood: Posture; twist: HalfTurns): (int, int) =
  ## Get where twist sits along axle.
  ##   Placed by twist itself rather than by index, so distance
  ##     between two postures on drawing is size of turn between
  ##     them.  Half turn is one step wherever it is taken.
  (axleWidth() div 2 + twist * STEP, AXLE_Y)


func standing*(stood: Posture): seq[HalfTurns] =
  ## Get every twist this frame, held at these heights, can stand at.
  for twist in -MOST_TURN .. MOST_TURN:
    if stood.holds(twist):
      result.add twist



#[ Drawing ]#

func arc(stood: Posture; twist: HalfTurns; refused: bool): string =
  ## Draw one landing as arc from where couple are to where it puts
  ## them.
  ##   One arc per place turn lands, not one per turn.  Twelve turns land
  ##     in six places, because turn is stored as one number for
  ##     couple and that number does not care which of them moved -- so
  ##     twelve arcs would be six drawn twice, on top of each other, saying
  ##     same thing.  Which dancer takes it is in list beside
  ##     drawing, where there is room to say it.
  let
    (ax, ay) = centreOf(stood, stood.twist)
    (bx, by) = centreOf(stood, twist)
    reach = abs(twist - stood.twist)
    # Stacked by how far turn goes, so long arc clears short one rather
    # than crossing it twice.
    lift = ARC_RISE + reach * 30
    (mx, my) = ((ax + bx) div 2, ay - lift)
    told = TURN_NAMES[min(reach, TURN_NAMES.high)] &
      (if twist > stood.twist: " right" else: " left")
  result = "<g class=\"turn" & (if refused: " refused" else: "") & "\">" &
    "<path class=\"turn-line\" d=\"M" & $ax & " " & $(ay - 58) & "Q" & $mx &
    " " & $my & " " & $bx & " " & $(by - 58) & "\"/>"
  let (nx, ny) = (mx, ay - lift * 3 div 4)
  result.add "<rect class=\"turn-plate\" x=\"" & $(nx - told.len * 3 - 5) &
    "\" y=\"" & $(ny - 9) & "\" width=\"" & $(told.len * 6 + 10) &
    "\" height=\"15\" rx=\"3\"/>"
  result.add "<text class=\"turn-name\" x=\"" & $nx & "\" y=\"" & $(ny + 3) &
    "\" text-anchor=\"middle\" style=\"" & LABEL_FONT & "\">" & told & "</text>"
  result.add "</g>"


func renderAxle*(stood: Posture; motion = Motion.Still;
    taken = none(HalfTurns)): string =
  ## Draw twist axis, postures on it, and every turn out of one held.
  let
    width = axleWidth()
    leaving = motion == Motion.Leaving and taken.isSome
    here = if leaving: taken.get else: stood.twist
  result = "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 " & $width &
    " " & $AXLE_HEIGHT & "\" class=\"axle" & (if leaving: " leaving" else: "") &
    "\" style=\"" & passStyle(WIDE_TEMPO) & "\" role=\"img\">" &
    "<title>" & stood.describe & ", and every turn out of it</title>"

  # Axle itself, drawn width of what stands on it and no wider.
  let ends = standing(stood)
  if ends.len > 0:
    result.add "<line class=\"axle-line\" x1=\"" &
      $(centreOf(stood, ends[0])[0]) & "\" y1=\"" & $AXLE_Y & "\" x2=\"" &
      $(centreOf(stood, ends[^1])[0]) & "\" y2=\"" & $AXLE_Y & "\"/>"

  # Arcs: one per place turn can land, refused ones included.
  var drawn: seq[HalfTurns] = @[]
  for offer in turnsOf(stood):
    if offer.to.twist == stood.twist or offer.to.twist in drawn:
      continue
    drawn.add offer.to.twist
    result.add arc(stood, offer.to.twist, offer.refused.isSome)

  # Postures standing on axle, each named for its turn and its arms.
  for twist in ends:
    var landing = stood
    landing.twist = twist
    let
      (cx, cy) = centreOf(stood, twist)
      reachable = twist != stood.twist
      classes = "node" & (if twist == here: " here" else: "") &
        (if reachable: " reachable" else: "")
    result.add "<g class=\"" & classes & "\" data-posture=\"" & landing.key &
      "\">"
    result.add "<rect class=\"node-plate\" x=\"" & $(cx - NODE_WIDTH div 2 - 5) &
      "\" y=\"" & $(cy - frameHeight(NODE_WIDTH) div 2 - 5) & "\" width=\"" &
      $(NODE_WIDTH + 10) & "\" height=\"" & $(frameHeight(NODE_WIDTH) + 10) &
      "\" rx=\"6\"/>"
    result.add renderFramePlaced(landing.frame, cx - NODE_WIDTH div 2,
      cy - frameHeight(NODE_WIDTH) div 2, NODE_WIDTH, twist)
    let name = turnName(twist)
    result.add "<text class=\"node-name\" x=\"" & $cx & "\" y=\"" &
      $(cy - frameHeight(NODE_WIDTH) div 2 - NAME_RISE) &
      "\" text-anchor=\"middle\" style=\"" & LABEL_FONT & "\">" & name & "</text>"
    let arms = landing.armName
    if arms.len > 0:
      result.add "<text class=\"node-arms\" x=\"" & $cx & "\" y=\"" &
        $(cy + frameHeight(NODE_WIDTH) div 2 + 18) &
        "\" text-anchor=\"middle\" style=\"" & LABEL_FONT & "\">" & arms &
        "</text>"
    result.add "</g>"

  # Mark carries distance to where it is going, so taking turn is
  # mark travelling along axle, which is what move is.
  let
    (hx, hy) = centreOf(stood, stood.twist)
    (tx, _) = centreOf(stood, here)
  result.add markAt(hx, hy, NODE_WIDTH, " style=\"--mx: " & $(tx - hx) &
    "px; --my: 0px\"")
  result.add "</svg>"
