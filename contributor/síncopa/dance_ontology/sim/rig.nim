## Every measurement sim is built from, each with where it came from.
##
##   Rig is tape's numbers: rounds of torso, neck and head,
##     lengths of arm's three links, and how far each joint will go before
##     it hurts.  Radii and reaches are derived from them, never entered.
##   Figures are mixed-sex midpoints of ANSUR II (2012) medians, with
##     NASA-STD-3000 and AAOS tables for joints.  Male / female:
##       chest round 1.00 / 0.92 and waist 0.94 / 0.86, so one-cylinder
##         torso takes 0.95;  neck round 0.39 / 0.34 -> 0.37;  head 0.57 / 0.55
##         -> 0.56;  stature 1.76 / 1.62 -> crown at 1.69;  acromion height
##         1.44 / 1.33 -> shoulders at 1.40;  biacromial breadth 0.40 / 0.36
##         with joint's centre two centimetres or so inside bone
##         -> shoulders 0.18 out from axis;  acromion to radiale 0.34 /
##         0.31 less that offset -> upper arm of 0.31;  radiale to stylion
##         0.27 / 0.24 -> forearm of 0.25;  grip's centre about 0.08
##         past wrist crease;  forearm round 0.27 -> limb radius 0.045.
##       Shoulder extension 50-60 degrees and horizontal abduction 40-45 are
##         held to 45 behind frontal plane; adduction across body to
##         45 past sagittal plane; humeral rotation 70 in and 90 out;
##         elbow flexion 140-150 held to 140; wrist flexion 75 and extension
##         70 taken as one 60 degree cone, since forearm's own rotation
##         can turn plane it bends in.
##   Ranges are what dancer will do without pain, not what joint can
##     be forced to.  Past range is refused, and joint is named;
##     last stretch before it is reported as strain, so pose near its edge
##     is seen coming.
##   Torso's section is ellipse of tape's round: chest and waist
##     are about three quarters as deep as they are broad (ANSUR chest depth
##     0.25 to breadth 0.31, waist 0.22 to 0.30), and round section of
##     same girth stands 3 cm too far out at front and 3 cm too far in at
##     flank -- enough to refuse forearm laid across one's own belly,
##     which is first thing crossed hold does.  Neck and head stay
##     round.
##     Cost: one more number in rig, and contact test that scales
##       section to circle first.  Accepted -- alternative is model
##       that reports handshake as strain.

{.experimental: "strictFuncs".}

import std/math


type
  Part* {.pure.} = enum ## Three cylinders body is made of, floor upward.
    Torso, Neck, Head

  Band* {.pure.} = enum ## Where pair of joined hands is carried.
    ##   Named for body part, not for word of dance: which of
    ##     these is "low" is put on outside sim.
    Torso, ## About chest, below shoulder line.
    Neck,  ## About neck, between shoulders and chin.
    Crown  ## Over head, clear of it.

  Dof* {.pure.} = enum ## Freedoms of arm that have ends.
    Extend, ## Upper arm behind frontal plane, in degrees of angle.
    Across, ## Upper arm across body, past sagittal plane.
    Twist,  ## Upper arm turned about its own length: in is negative.
    Bend,   ## Elbow, nought when straight.
    Wrist   ## Hand off line of forearm, whichever way.

  Range* = object ## How far one freedom goes, and where it starts to strain.
    lo*, hi*: float     ## Ends, radians.  Past either is refused.
    easeLo*, easeHi*: float ## How far short of each end strain begins;
                        ## nought where end is stop that can be leant on.
    neutral*: float     ## Where joint rests; solver prefers it.

  Rig* = object ## Tape's numbers, and joints' ranges.
    round*: array[Part, float] ## Circumferences, metres.
    flat*: array[Part, float]  ## Depth over breadth of section: one is
                               ## round; chest is about three quarters.
    top*: array[Part, float]   ## Height each part stops at.  Torso
                               ## stops under shoulder joints by slope
                               ## of shoulders, so raised arm clears it.
    hip*: float                ## Where torso starts.
    shoulderOut*: float        ## Each shoulder joint from axis, sideways.
    shoulderUp*: float         ## And its height.
    upper*, fore*, hand*: float ## Shoulder to elbow, elbow to wrist, wrist to grip.
    limb*: float               ## Half of arm's thickness.
    range*: array[Dof, Range]
    band*: array[Band, tuple[lo, hi: float]] ## Hand heights offered per band.


func deg(d: float): float = d * PI / 180.0


const HUMAN* = Rig(
  round: [0.95, 0.37, 0.56],
  flat: [0.75, 1.0, 1.0],
  top: [1.36, 1.50, 1.69],
  hip: 0.80,
  shoulderOut: 0.18, shoulderUp: 1.40,
  upper: 0.31, fore: 0.25, hand: 0.08,
  limb: 0.045,
  range: [
    Range(lo: deg(-90), hi: deg(45), easeLo: 0.0, easeHi: deg(20), neutral: 0.0),
    Range(lo: deg(-90), hi: deg(45), easeLo: 0.0, easeHi: deg(20), neutral: 0.0),
    Range(lo: deg(-70), hi: deg(90), easeLo: deg(25), easeHi: deg(25), neutral: 0.0),
    Range(lo: 0.0, hi: deg(140), easeLo: 0.0, easeHi: deg(35), neutral: deg(30)),
    Range(lo: 0.0, hi: deg(60), easeLo: 0.0, easeHi: deg(20), neutral: 0.0)],
  band: [(1.00, 1.35), (1.40, 1.50), (1.735, 2.00)])
  ## Average adult.  Crown band starts limb's radius over head
  ## so hand carried there clears it by construction.


func halfBreadth*(rig: Rig; part: Part): float =
  ## Side to side, from axis: what tape's round makes ellipse of
  ## part's flatness (Ramanujan's perimeter, inverted).
  let q = rig.flat[part]
  rig.round[part] / (PI * (3.0 * (1.0 + q) - sqrt((3.0 + q) * (1.0 + 3.0 * q))))

func halfDepth*(rig: Rig; part: Part): float =
  ## Front to back, from axis.
  halfBreadth(rig, part) * rig.flat[part]

func radius*(rig: Rig; part: Part): float = rig.round[part] / (2.0 * PI)
  ## Round as one number: radius of circle of that round.

func bottom*(rig: Rig; part: Part): float =
  ## Height part starts at: hip, or top of part below.
  case part
  of Part.Torso: rig.hip
  of Part.Neck: rig.top[Part.Torso]
  of Part.Head: rig.top[Part.Neck]

func reach*(rig: Rig): float = rig.upper + rig.fore + rig.hand
  ## Shoulder to grip with everything straight: as far as hand goes.

func touching*(rig: Rig): float = 2.0 * halfDepth(rig, Part.Torso)
  ## Closest two bodies stand: chest to chest.

func margin*(range: Range; value: float): float =
  ## How far `value` is inside range, in units of ease at nearer
  ## end: one and more is comfortable, nought is edge, negative is past it.
  ##   End with no ease is stop that costs nothing to lean on, so
  ##     margin there is counted in other end's ease and is only ever
  ##     negative when value is past stop.
  let
    fromLo = value - range.lo
    fromHi = range.hi - value
    unitLo = if range.easeLo > 0.0: range.easeLo else: range.easeHi
    unitHi = if range.easeHi > 0.0: range.easeHi else: range.easeLo
  var
    mLo = if range.easeLo > 0.0: fromLo / unitLo
          elif fromLo < 0.0: fromLo / unitLo
          else: Inf
    mHi = if range.easeHi > 0.0: fromHi / unitHi
          elif fromHi < 0.0: fromHi / unitHi
          else: Inf
  min(mLo, mHi)

func eased*(range: Range; value: float): float =
  ## Distance from joint's neutral, as fraction of way to
  ## farther end: smooth cost solver minimises.
  let span = max(range.hi - range.neutral, range.neutral - range.lo)
  (value - range.neutral) / span
