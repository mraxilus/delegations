## Every measurement simulation is built from, each with where it came from.
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
##         45 past sagittal plane; humeral rotation 90 in and 105 out, with
##         ease of 25 at either end, so that rotation costs nothing to 65 in
##         and 80 out (AAOS: 70 and 90) and is refused past 90 and 105 (AMA
##         Guides: 90 in; Boone and Azen 1979: 104 out) -- tables disagree by
##         about ease's width, and ease is where they disagree;
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
  Part* {.pure.} = enum  ## Three cylinders body is made of, floor upward.
    Torso, Neck, Head

  Band* {.pure.} = enum  ## Where pair of joined hands is carried.
    ##   Named for body part, not for word of dance: which of
    ##     these is "low" is put on outside simulation.
    Torso,  ## About chest, below shoulder line.
    Neck,  ## About neck, between shoulders and chin.
    Crown  ## Over head, clear of it.

  Dof* {.pure.} = enum  ## Freedoms of arm that have ends.
    Extend,  ## Upper arm behind frontal plane, in degrees of angle.
    Across,  ## Upper arm across body, past sagittal plane.
    Twist,  ## Upper arm turned about its own length: in is negative.
    Bend,  ## Elbow, nought when straight.
    Wrist  ## Hand off line of forearm, whichever way.

  Collar* {.pure.} = enum  ## Freedoms of shoulder girdle on its collarbone, at breastbone.
    Fore,  ## Girdle swung about trunk's up: protraction positive, retraction negative.
    Up  ## Girdle swung about trunk's fore: elevation positive, depression negative.

  Range* = object  ## How far one freedom goes, and where it starts to strain.
    lower*, upper*: float  ## Ends, radians.  Past either is refused.
    ease_lower*, ease_upper*: float  ## How far short of each end strain begins;
                        ## nought where end is stop that can be leant on.
    neutral*: float  ## Where joint rests; solver prefers it.

  Rig* = object  ## Tape's numbers, and joints' ranges.
    round*: array[Part, float]  ## Circumferences, metres.
    flat*: array[Part, float]  ## Depth over breadth of section: one is
                               ## round; chest is about three quarters.
    top*: array[Part, float]  ## Height each part stops at.  Torso
                               ## stops under shoulder joints by slope
                               ## of shoulders, so raised arm clears it.
    hip*: float  ## Where torso starts.
    shoulder_out*: float  ## Each shoulder joint from axis, sideways.
    shoulder_up*: float  ## And its height.
    upper*, fore*, hand*: float  ## Shoulder to elbow, elbow to wrist, wrist to grip.
    limb*: float  ## Half of arm's thickness.
    range*: array[Dof, Range]
    waist*: Range  ## Thoracic rotation: shoulders yawing on hips.
    collar*: array[Collar, Range]  ## Girdle's two swings about where collarbone
                               ## meets breastbone, each with its ease.
    band*: array[Band, tuple[lower, upper: float]]  ## Hand heights offered per band.


func toRadians(degrees: float): float = degrees * PI / 180.0
  ## Convert degrees to radians.

const
  ACROSS_UPPER = toRadians(130)
    ## Adduction at clinical *horizontal* adduction, not hanging arm's.  Forty
    ## five is how far arm goes across with arm hanging, and what stops it there
    ## is belly; raised, arm passes in front of chest to about hundred and
    ## thirty, and what stops it then is chest.  Either way limit is trunk, which
    ## simulation collides already.  Reading is arcsin and cannot pass ninety, so at
    ## this figure cap never binds and body does stopping -- as in life.
    ##   Measured: every chain jammed on old cap with arm raised.  Freed, chains
    ##     go from 18 to 47 of 56 questions and reference from 193 to 223 of 231,
    ##     with nothing lost; every law holds, and mirror law was corrected on way.
  WRIST_UPPER = toRadians(60)
    ## Cone under clinical flexion and extension, which are seventy to eighty.
    ## Widened to seventy five and measured: chains carry 47 of 56 questions
    ## either way, gaining one manner and losing another, so it is not what
    ## binds and is left where tape had it until something shows it does.


const HUMAN* = Rig(
  round: [0.95, 0.37, 0.56],
  flat: [0.75, 1.0, 1.0],
  top: [1.36, 1.50, 1.69],
  hip: 0.80,
  shoulder_out: 0.18,
  shoulder_up: 1.40,
  upper: 0.31,
  fore: 0.25,
  hand: 0.08,
  limb: 0.045,
  range: [
    Range(
      lower: toRadians(-90),
      upper: toRadians(45),
      ease_lower: 0.0,
      ease_upper: toRadians(20),
      neutral: 0.0,
    ),
    Range(
      lower: toRadians(-90),
      upper: ACROSS_UPPER,
      ease_lower: 0.0,
      ease_upper: toRadians(20),
      neutral: 0.0,
    ),
    Range(
      lower: toRadians(-90),
      upper: toRadians(105),
      ease_lower: toRadians(25),
      ease_upper: toRadians(25),
      neutral: 0.0,
    ),
    Range(
      lower: 0.0,
      upper: toRadians(140),
      ease_lower: 0.0,
      ease_upper: toRadians(35),
      neutral: toRadians(30),
    ),
    Range(lower: 0.0, upper: WRIST_UPPER, ease_lower: 0.0, ease_upper: toRadians(20), neutral: 0.0),
  ],
  waist: Range(
    lower: toRadians(-40),
    upper: toRadians(40),
    ease_lower: toRadians(15),
    ease_upper: toRadians(15),
    neutral: 0.0,
  ),
  collar: [
    Range(
      lower: toRadians(-25),
      upper: toRadians(25),
      ease_lower: toRadians(10),
      ease_upper: toRadians(10),
      neutral: 0.0,
    ),
    Range(
      lower: toRadians(-10),
      upper: toRadians(40),
      ease_lower: toRadians(5),
      ease_upper: toRadians(10),
      neutral: 0.0,
    ),
  ],
  band: [(1.00, 1.35), (1.40, 1.50), (1.735, 2.00)],
)
  ## Average adult.  Crown band starts limb's radius over head
  ## so hand carried there clears it by construction.
  ##   Waist is thoracic rotation, forty degrees each way, clinical; its ease is
  ##     assumed at fifteen, since tables give end and not where end starts to
  ##     cost.
  ##   Collar is shoulder girdle swinging on collarbone about its joint at
  ##     breastbone (Kapandji): protraction and retraction about twenty five
  ##     degrees each way, elevation forty and depression ten.  Twelve
  ##     centimetres out from that joint, twenty five degrees carries shoulder
  ##     five centimetres fore or aft and forty carries it eight up: shrug and
  ##     roll of shoulder that tape does not have and dancer does.  Eases
  ##     assumed, as waist's is.


func halfBreadth*(rig: Rig, part: Part): float =
  ## Side to side, from axis: what tape's round makes ellipse of
  ## part's flatness (Ramanujan's perimeter, inverted).
  let flatness = rig.flat[part]
  rig.round[part] / (PI * (3.0 * (1.0 + flatness) -
                           sqrt((3.0 + flatness) * (1.0 + 3.0 * flatness))))

func halfDepth*(rig: Rig, part: Part): float =
  ## Front to back, from axis.
  halfBreadth(rig, part) * rig.flat[part]

func radius*(rig: Rig, part: Part): float = rig.round[part] / (2.0 * PI)
  ## Round as one number: radius of circle of that round.

func bottom*(rig: Rig, part: Part): float =
  ## Height part starts at: hip, or top of part below.
  case part
  of Part.Torso: rig.hip
  of Part.Neck: rig.top[Part.Torso]
  of Part.Head: rig.top[Part.Neck]

func span*(rig: Rig): float = rig.upper + rig.fore + rig.hand
  ## Shoulder to grip with everything straight: as far as hand goes.

func touching*(rig: Rig): float = 2.0 * halfDepth(rig, Part.Torso)
  ## Closest two bodies stand: chest to chest.

const SLACK* = toRadians(0.5)
  ## Past stop that has no ease by less than this is at that stop: engine solves
  ## its limits rather than clamping them, so joint leant on its stop reads hair
  ## past it.

func strainOf*(range: Range, value: float): float =
  ## How far into ease before either end `value` sits: nought outside every
  ## ease, one at end, more past it.  Stop with no ease costs nothing to lean
  ## on, and counts only once value is past it by more than `SLACK`, in units of
  ## whole range.
  let width = range.upper - range.lower
  var worst = 0.0
  if range.ease_upper > 0.0:
    worst = max(worst, 1.0 - (range.upper - value) / range.ease_upper)
  elif value > range.upper + SLACK:
    worst = max(worst, 1.0 + (value - range.upper) / width)
  if range.ease_lower > 0.0:
    worst = max(worst, 1.0 - (value - range.lower) / range.ease_lower)
  elif value < range.lower - SLACK:
    worst = max(worst, 1.0 + (range.lower - value) / width)
  max(0.0, worst)

func margin*(range: Range, value: float): float =
  ## How far `value` is inside range, in units of ease at nearer
  ## end: one and more is comfortable, nought is edge, negative is past it.
  ##   End with no ease is stop that costs nothing to lean on, so
  ##     margin there is counted in other end's ease and is only ever
  ##     negative when value is past stop.
  let
    from_lower = value - range.lower
    from_upper = range.upper - value
    unit_lower = if range.ease_lower > 0.0: range.ease_lower else: range.ease_upper
    unit_upper = if range.ease_upper > 0.0: range.ease_upper else: range.ease_lower
  var
    margin_lower = if range.ease_lower > 0.0: from_lower / unit_lower
          elif from_lower < 0.0: from_lower / unit_lower
          else: Inf
    margin_upper = if range.ease_upper > 0.0: from_upper / unit_upper
          elif from_upper < 0.0: from_upper / unit_upper
          else: Inf
  min(margin_lower, margin_upper)

func eased*(range: Range, value: float): float =
  ## Distance from joint's neutral, as fraction of way to
  ## farther end: smooth cost solver minimises.
  let width = max(range.upper - range.neutral, range.neutral - range.lower)
  (value - range.neutral) / width
