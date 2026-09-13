## Hold every rule mock-ups were given, in words it arrived in.
##
##   This module is authority workbench replicates: ledger
##     README mirrors entry for entry, and checks cite by number.
##     Cost of keeping it as data nothing loads: copies can drift, and
##       only reader diffing them would notice.  Accepted for now --
##       checks' printed lines are worded for what was measured, not for
##       rule's own phrasing, and rewording them to quote this ledger
##       would change what every build prints.
##   Vocabulary rules speak in -- sides, levels, holds, settle
##     table -- lives in `dance_ontology/draw/terms` now, and this re-exports it
##     so reader of ledger still has words in scope.  It moved
##     because app draws these marks now: words belong beside
##     drawing, and argument for them belongs here.
##   Rule that is only implemented and not asserted quietly stops being
##     true; checkers in `checks.nim` verify standing ones on every
##     build -- twenty-nine lines for forty rules, superseded six living
##     here with their corrections and sheet's five (36 to 40) checked
##     by sim's instrument rather than workbench's.

# TODO: Make ledger load-bearing.
#   Checks could assert their rule numbers against `RULES`, or
#   README's ledger section could be generated from it.  Either buys
#   drift-proofing at cost of freezing wordings into build's
#   output; needs decision on what printed lines should say.

{.experimental: "strictFuncs".}

import std/options

import ../src/dance_ontology/draw/terms
export terms


const RULES* = [
  "the hands should only pass through the circle when the hand positions " &
    "are above",
  "the hands can only move from their positions at the side of the body " &
    "only if a level is specified",
  "the slots are relative to the front facing side of the lead/follow, " &
    "not from the diagram itself",
  "high and low wraps go around to the front of the other hand",
  "low lock goes around the back to the back of the other hand",
  "in high lock the line goes around the back of the modified body",
  "lock/wrap positions can only be used when the connecting line goes " &
    "around no less than just under 1/2 of the circumference",
  "above has no locks/wraps and can only transition to upper wrap or back " &
    "to default (physical restrictions)",
  "the connection is drawn in its two hands' own colours, meeting at its " &
    "middle, the lead's end in the deep shade",
  "using only the rotations that allow us to change between just those " &
    "(i.e. assumed all rotations are high so no wraps/locks)",
  "no additional frame positions, just the addition of rotations that let " &
    "us travel between them",
  "hand to hand should have 3 positions allowed by rotation",
  "left to left and right to right should technically have 4 (left over " &
    "right, right over left, and the two sides with an extra arm twist, " &
    "in either direction)",
  "the rotations should be high, such that there should be no body " &
    "wrapping, also make sure any twists are visually clear just like the " &
    "crossover",
  "for each mock up, a static image version of every derived position and " &
    "full set of animated transitions between states",
  "if held high, they can turn infinitely in either direction, so all we " &
    "add is the additional quarter turn orientations for each of the 4 " &
    "single hand connections",
  "all turns should be in the \"above\" position, not the high. high/low " &
    "causes wraps/locks, so we're currently making the assumption to avoid " &
    "those",
  "the leads' transitions should still be in the 2 stage form, stage 1 is " &
    "the lead turns with the original perspective stage 2 is reorienting " &
    "the perspective",
  "you should also include orbit turns not just the axis turns",
  "make sure orbit turns keep their bearing, youre currently combining " &
    "orbit and axis turns to keep the partner facing the other",
  "also, the animations should also have the above level as that's the " &
    "only valid one for the current scope",
  "an arm shouldn't settle in a hand cell it's not connected to. it " &
    "should bend around all hand cells and chevrons as to not imply " &
    "connection and not obscure direction. it is however fine to animate " &
    "smoothly past it as it would do now for a full turn for example",
  "the current line finding does a good job of finding the shortest line, " &
    "but we also need to balance simplicity. prefer paths that have fewers " &
    "bends (ideally 1) as well as length. in many cases I see, 1 bend can " &
    "be used with minimal change to the overall line",
  "prefer smooth long curves instead of sharp breaks as well. some of " &
    "these can be accomplished with a singular bezier with a more gentle " &
    "curvature just as well as the current sharp direction changes",
  "reposition the lead such that when the follow orbits or the lead turns " &
    "on axis, the 2nd animation stage doesn't have to move the result " &
    "around, i.e. lead position should remain fixed as much as possible " &
    "(obviously this can't really be the case when the lead orbits, a " &
    "reposition/re entering) will still be necessary I think",
  "make the second animation stage quicker or something so it has less " &
    "emphasis. or whatever the recommended UX is to make it less " &
    "noticeable than the actual rotation itself",
  "the two twisted ends in reality the arms make an overlapping box " &
    "shape. on one side of the twist the lead left is over the right " &
    "(reversed for other end of twist). the arms should reflect that " &
    "visual on both ends of the twist. there should be two crossovers one " &
    "on the leads side of the arms, one on the follows. for both sides of " &
    "the twist chain. there should be a visible box/diamond between the " &
    "crossovers (hence the preliminary names, Left over Right box, Right " &
    "over Left box)",
  "the animations are very jankey and tied to the final visual " &
    "representations of the box/diamond state, add the half turns which " &
    "should actually form an X overhead when partners are facing the same " &
    "direction (similar to the existing L-over-R etc. when facing one " &
    "another) as states in-between the outside 2",
  "the animations don't have the proper breaks that the static images do, " &
    "they seem to not be tracking which arms are over/under because of " &
    "this and they are instances where they end up on the wrong z order, " &
    "fix",
  "the boxes/diamonds are the ends of the turn chain this highlighted is " &
    "not allowed. all I'm referring to is that double box is not allowed",
  "both hand to hand and the overs are essentially the same thing but with " &
    "one half turn of offset. the neutral (non crossed) state in hand to " &
    "hand is when partners are facing, and the same state in the other set " &
    "is when a partner is facing away (in between Left over and Right " &
    "over). hand to hand actually has an extra half turn on both ends " &
    "(which I previously thought only the other pattern had). this means " &
    "both patterns follow the same logic, just one starts with the " &
    "partners facing each other, and the other starts with both partners " &
    "facing the same way",
  "orbit should not maintain bearing, but instead keep whatever side faces " &
    "the center, facing the center otherwise we can't equate the 1/2 turns",
  "the swan zig zag is a bit to large, make it tighter so it looks more " &
    "readable. also, the above level hatching appears to be a background " &
    "that moves around a lot as the squares/circles move, it should stay " &
    "visually consistent during animation",
  "the hatching is good, but revert the swan change, it looks worse",
  "they both have the same issue, go back to the tighter version try to " &
    "make the swan arm, even tighter to the straighter arm, but make it " &
    "smoother (a simpler curved, right now it looks jagged/sharp)",
  "above: connection held above head. high: connection held above shoulder " &
    "level (about neck). low: connection held below shoulder level (about " &
    "torso)",
  "lock: where a lead/follow's arm is bent behind their back (low) or bent " &
    "to the shoulder of the same arm. To get into low lock, the form must " &
    "enter from a low position only due to physical/safety limitations",
  "wrap: where a lead/follow's arm is crossed around the front of their " &
    "body under (low) or over (high) their other arm",
  "generated two hand combinations for up to 1 modifier per lead/follow " &
    "(maximum 2 total across all 4 hands); permutations with 2 modifiers " &
    "for a single person are excluded, until deemed necessary",
  "half-closed, Left to left held low: wrap at left@0.5, lock at right@1",
] ## Each rule verbatim, one-indexed in prose as `RULES[i - 1]`.
  ##   Rules 10 to 14 govern rotation page: rotation as edges over
  ##     app's eight frames, everything held high.
  ##   In rule 13 twisted states are ends of chain, not cycle --
  ##     middle edge is full turn that swaps which arm is over.
  ##     That chain shape is implementer's reading of words, flagged
  ##       on page as thing to check.
  ##   Rule 14 rules out drawing first draft reached for: at high
  ##     arms are up, so connection passes *over* turning body and
  ##     never routes round one.  Twist is said as crossover is
  ##     said -- lines crossing, with over-under break naming which is
  ##     on top -- and never by which side of body line hugs.
  ##   Rules 15 and 16 turn work into one mock-up per kind of turn, and
  ##     rule 16 takes ceiling off high single hand.
  ##     Hold that turns for ever has no wound-out end, so how far it has
  ##       wound is not part of its state; only orientation is, which is
  ##       why single hand has exactly four positions and no more.
  ##     That retires rule 14's pigtail for single hands: it was invented to
  ##       tell one wind from its mirror, and with no ceiling there is
  ##       nothing left for it to tell apart.  Crossing convention
  ##       stands for pairs, where geometry makes crossing itself.
  ##   Rule 17 moves assumption from `high` to `above`, and says why:
  ##     high and low are levels wrap or lock is made at, so turn
  ##     drawn at either invites very states this work is holding out
  ##     of scope.  Above is over head, on axis couple turns
  ##     about, and has no lock and no wrap by rule 8.
  ##   Rule 18 keeps two stages frame page dances lead's move in:
  ##     lead turns while world holds still, and only then does
  ##     picture turn back to face them up.
  ##   Rule 19 adds orbit turns beside axis turns.
  ##   Rule 20 said what orbit is: orbiter walks ring and keeps
  ##     their own bearing, arriving facing way they set off.
  ##     **Rule 32 has since reversed this**, and paragraphs below are
  ##       kept for what they measured rather than for what they concluded.
  ##     `pose.orbit` has always had this as `locked = false`; locked
  ##       form keeps orbiter's face to their partner, which is
  ##       orbit and axis turn danced together, not orbit.
  ##     Measured with bearing kept: two orbits reach one round of
  ##       positions -- drawing cannot say which dancer walked -- and
  ##       that round is not either axis round.  Four manners of turn,
  ##       three rounds of positions.
  ##   Rule 21 puts level on moving hand as well as still one; on
  ##     turns pages that is above, only level in scope.
  ##   Rule 22 keeps settled reach out of marks it does not join.
  ##     Line through hand cell says hand is held, and line
  ##       through chevron hides which way its dancer faces; settled
  ##       picture must say neither.
  ##     Exemption for moving reach is rule's own: passing
  ##       smoothly across mark is what turn does, and bend that
  ##       appeared and vanished mid-move would be mark of its own.
  ##   Rule 23 says shortest way past those marks is not plainest:
  ##     line that weaves -- one mark on left, next on right --
  ##     costs reader one turn to follow at every change of direction.
  ##     So length is not only price route pays.  Bend is worth
  ##       `route.BEND_COST` of line, and route is chosen on both
  ##       together; rule's own reading of "ideally 1" is that route
  ##       is left alone once it turns no more than once.
  ##   Rule 24 asks one bend to be curve rather than corner.  Rule
  ##     23's one-bend route was hull of marks, and hull is
  ##     polyline: its apex is break.  Quadratic bezier over same
  ##     apex says same thing, turns one way only, and has no corner in
  ##     it anywhere.
  ##   Rule 25 frames picture on lead rather than on pair.
  ##     `canonicalise` turned world about couple's midpoint, so
  ##       move that shifts that midpoint carried lead across box
  ##       in second stage, and reader had to find them again.
  ##     Turning about lead's own place instead: follow's orbit needs
  ##       no second stage at all, lead's axis turn swings only
  ##       follow, and lead's own orbit -- one case rule allows
  ##       -- comes home as straight slide.
  ##   Rule 26 makes second stage subordinate to first.
  ##     Two stages had sample each way and so share of clock
  ##       each way, which read as one long motion in two halves rather
  ##       than turn and picture following it.
  ##     Three things carry ranking, and they are what motion design
  ##       does with any secondary or camera move: re-framing takes far
  ##       less of clock than turn (`RE_FRAME_PACE`), beat is
  ##       held on turn's landing so two do not blur into one
  ##       (`ARRIVAL_HOLD`), and it still starts and ends softly, because
  ##       abrupt start is one thing that would pull eye back to
  ##       it.
  ##     How long each stage lasts is now drawing's business rather
  ##       than side effect of how finely it was sampled: walk carries
  ##       when each of its frames is due, and markup says so.
  ##   Rule 27 says what twisted ends of two-hand chain look like.
  ##     Parallel pair does not cross; pair wound whole turn crosses
  ##       twice, once by each dancer, and what two crossings enclose
  ##       is diamond rule names.
  ##     Two answers settle how it is read.  *"three positions, full turn
  ##       required between them"*: step on that page is whole turn,
  ##       which is what makes rule 12's three into chain -- whole turn puts
  ##       every place and every facing back where it was, and what it
  ##       leaves behind is wind.  And *"they alternate"*: whichever
  ##       connection is over at lead's crossover is under at
  ##       follow's, because that is what being wound together means.  Two
  ##       crossings same way round would be one arm lying on another.
  ##     So both pages are duals.  Single hand turns for ever, so its
  ##       wind is not part of its state and its orientation is all of it
  ##       (rule 16); hold both hands and whole turn returns every
  ##       orientation, so wind is all of it instead.
  ##   Rule 28 adds half turns, and in doing so says where rule 27's
  ##     first drawing went wrong.
  ##     At half turn partners face same way and pair makes
  ##       **cross**, which is crossing geometry itself gives --
  ##       same mark app already uses for crossed pair.  So chain
  ##       is five: diamond, cross, frame, cross, diamond, half turn apart.
  ##     `"tied to the final visual representations"` is fault named:
  ##       wind was number handed to drawing, and diamond was swelled
  ##       by it on top of geometry that was not winding at all.  It is now
  ##       **measured** instead -- angle each held hand makes with
  ##       pair's own axis, and difference between two ends is
  ##       wind.  Reach is then shadow of wound arm: its offset
  ##       from axis swings as far round as pair has wound, which
  ##       is straight at none, cross at half, and diamond at whole,
  ##       with nothing imposed and nothing to jump.
  ##     Measured that way, orbit that keeps its bearing does not wind
  ##       pair at all: such walker never turns relative to their
  ##       partner.  First drawing claimed all four manners wound, which
  ##       was only true because all four were told to.
  ##     **Rule 32 has since made that finding moot** by changing what
  ##       orbit is.  Walker who keeps their side to centre does turn
  ##       relative to their partner, so all four manners wind after all --
  ##       and this time it is measured rather than claimed.
  ##   Rule 29 gives moving crossing break that still one has.
  ##     Still reach is cut into runs at every crossing it dives under,
  ##       and how many runs that makes depends on how many crossings there
  ##       are -- which is why moving reach was left whole: path whose
  ##       number of pieces changes cannot be morphed between frames.  With
  ##       nothing broken, which strand is on top was decided by order
  ##       both were written in, so one of them was over at *both*
  ##       crossings.  That is not twist, and it disagreed with still
  ##       move landed on.
  ##     Gap in stroke is not same thing as gap in path,
  ##       though.  Moving reach keeps its one piece and carries
  ##       break as dash instead, which travels with crossing and
  ##       closes to nothing where there is no crossing to mark -- so
  ##       markup never changes shape and there is nothing to jump.
  ##     Which arm dives is not new decision: crossings are found as
  ##       stills find them, diving arm alternates from first
  ##       as stills alternate it, and first is named by sign
  ##       of measured wind -- so moving figure and still it
  ##       lands on cannot disagree.
  ##   Rule 30 says chain is chain and not cycle, and that its ends
  ##     hold: whole turn either way is as far as this scope winds, so
  ##     nothing may be drawn wound one and half turns.
  ##     Fault was in turning, not drawing.  Every edge was
  ##       built with same positive half turn, but two axis turns
  ##       wind opposite ways -- positive turn by lead unwinds what
  ##       positive turn by follow winds.  Chain's winds are
  ##       follow's way round, so lead's edges were walking backwards
  ##       off end: from diamond at whole turn out to one and half
  ##       turns, which drew third crossing and second diamond.
  ##     So each way's sense is **measured**, as rule 28 measures wind
  ##       itself: turn quarter from frame and see which way pair
  ##       wound.  Quarter and not half, because half turn's wind is
  ##       exactly wrap point of `wrap180` and carries no sign.  Way
  ##       that winds nothing -- either orbit, as orbits then were -- takes
  ##       positive sense, since it has real half turn to travel and no
  ##       end to walk off.  **Rule 32 has since left no such way**: every one
  ##       of four winds, so that fallback is unreachable and stands only
  ##       so way that stopped winding could not silently freeze.
  ##     Rule 31 has since moved those ends: they are swans, at one
  ##       and half turns.  Rule was that chain *has* ends and they
  ##       hold, never that they sat at whole turn -- and what it refused,
  ##       double box, is refused still, by swan being drawn as
  ##       swan rather than as two diamonds stacked.
  ##   Rule 31 makes two two-hand patterns one chain, and hands this
  ##     page two positions it was missing.
  ##     Rule 13 had already said crossed pair has `"the two sides with`
  ##       `an extra arm twist, in either direction"`, and that extra twist
  ##       was read as belonging to that pattern alone.  It does not: hand
  ##       to hand has one at each end too, so chain is seven -- swan,
  ##       diamond, cross, frame, cross, diamond, swan.
  ##     What differs between two holds is only *where chain sits*.
  ##       Hold is unwound where its two connections run parallel, and
  ##       that falls at different facing for each: hand to hand
  ##       face-to-face, crossed pair pillion lead.  So
  ##       phase is measured -- turn follow to each candidate and see
  ##       which leaves hold unwound -- and crossed page becomes
  ##       this page's code with different hold rather than rewrite.
  ##     What one and half turns looks like is rule's own answer: *`"don't`
  ##       `draw it as a double box, draw it as one connection being straight`
  ##       `and the other snaking around it (as that's how it looks in`
  ##       `reality when I tried it). I'm giving it the preliminary name of`
  ##       `swan, as it looks like the necks of two mating swans surrounding`
  ##       `a center straight connection."`*
  ##     Which geometry now does rather than fakes: past whole turn
  ##       pair stops sharing its swing evenly and hands it over, so at
  ##       one and half turns one reach is plain chord between its own
  ##       hands and other carries all of it.  Handed *over* and not
  ##       merely given up, or loops would be too shallow to read as
  ##       thing going round.
  ##     And straight one is one on top at first crossing, which
  ##       by alternation dives only once: broken twice, there would be
  ##       no straight line left in middle for anything to surround.
  ##   Rule 32 corrects rule 20, and says what orbit is for good:
  ##     walker keeps **whatever side of them faced centre facing it**,
  ##     so they turn as far as they travel.
  ##     Reason given is one that matters, and is about whole
  ##       scheme rather than about orbits: *`"otherwise we can't equate the`
  ##       `1/2 turns"`*.  Rule 20's orbit turned walker not at all
  ##       relative to their partner, so -- measured, under rule 28 -- it
  ##       wound pair by nothing.  Half turn of it was half turn of
  ##       no quantity, and two of four manners of turn did not walk
  ##       chain at all.  Facing centre, orbit winds exactly as far
  ##       as it carries, and every way steps one position per half turn.
  ##     `pose.orbit` has always had this as `locked = true`; rule 20 turned
  ##       it off and rule 32 turns it back on.  What rule 20 objected to --
  ##       *"combining orbit and axis turns"* -- is same arithmetic seen
  ##       from other side, and it is bearing-keeping walk that is
  ##       compound now: orbit with counter-turn danced into it.
  ##     Consequence runs through everything.  Orbit lands where
  ##       *other* dancer's axis turn lands, so four manners walk **two**
  ##       rounds of positions rather than three, each round reached by one
  ##       axis turn and by other dancer's orbit.  All four are still
  ##       drawn: which dancer walked is fact about path, and only
  ##       path can say it.
  ##     And on frame page two collapse figures swap over.  It is
  ##       orbit that now lands on matching axis turn, and
  ##       bearing-keeping compound that lands somewhere of its own --
  ##       one picture either dancer's compound reaches, since only
  ##       pair's axis has swung.
  ##   Rule 33 tightens swan and fixes mark that would not hold still.
  ##     Swan's snake took whole of straight connection's swing
  ##       as well as its own, which opened loops wider than pair they
  ##       belong to.  `route.SWAN_SWING` says how much it ends up carrying
  ##       instead: enough to read as going *round* straight one, not so
  ##       much that zig-zag leaves figure.
  ##     Hatch is other half, and it was real fault rather than
  ##       matter of taste.  `above` fill is SVG pattern anchored to
  ##       **user space**, so mark that animates its own coordinates
  ##       slides across hatch that is standing still, and fill swims
  ##       about inside its own outline.  Moving hand is drawn once at
  ##       origin and carried by transform now, exactly as body is:
  ##       hatch is carried with it and holds its place (rule 21).
  ##   Rule 34 keeps hatch and takes tightening back: *`"the hatching`
  ##     `is good, but revert the swan change, it looks worse."`*
  ##     So `SWAN_SWING` went back to two, which is whole of what
  ##       straight connection gives up, and check's upper bound on
  ##       bow dropped back to backstop -- far enough out to catch snake
  ##       that has left figure, and no opinion within that.  **Rule 35
  ##       has since set width again**; backstop is what stayed.
  ##     Two halves of rule 33 were one instruction and turned out to be
  ##       two different kinds of thing.  One was fault drawing could
  ##       be held to; other was matter of looks, and looks are
  ##       settled by looking.  Naming knob was worth doing anyway --
  ##       what it is set to is author's call, not checker's.
  ##   Rule 35 finds what was actually wrong with both swans, and it was
  ##     never width: *`"they both have the same issue ... it looks`
  ##     `jagged/sharp."`*
  ##     Reach is held as `ROUTE_N` points because that is what lets it
  ##       morph, and it was **drawn** between them with straight bits.
  ##       Everywhere else on every page that is invisible -- rule 24 keeps
  ##       settled reach turning few degrees per corner -- but swan's
  ##       lobes double back inside handful of points, so polygon it
  ##       is stored as was exactly what was on screen.  Widening or
  ##       narrowing it only changed how big facets were.
  ##     So reach is drawn as quadratics now (`route.smoothed`):
  ##       sampled points become control points and midpoints between
  ##       them places curve passes through.  Corners round off,
  ##       ends stay on their hands, line that hardly turns moves by
  ##       fraction of its own width -- and command count still follows
  ##       point count, so it morphs as before.
  ##     Width comes down as well, and rule asks for tighter than
  ##       either width that was tried -- so `SWAN_SWING` goes below both,
  ##       and snake keeps in closer to straight connection than any
  ##       version before it.  What it is set to remains author's call
  ##       and not checker's (rule 34); check is only backstop.
  ##   Rules 36 to 40 arrive from ontology sheet's own vocabulary and
  ##     rotation tables, and 36 corrects reading this codebase had held:
  ##     **every level is height**.  Low and high were documented here as
  ##     relative -- which arm lies over which -- and that was wrong:
  ##     over-under of two arms is part of what *wrap* is (rule 38, under
  ##     other arm low, over it high), while level says only where
  ##     on body connection rides.
  ##   Rule 37 settles what high lock is: arm bent to shoulder of
  ##     *same* arm.  Rule 6 said its line goes around back of
  ##     modified body, and both are one shape -- hand comes round
  ##     back up to its own shoulder, hammerlock -- so settle
  ##     table's `(Own, Back)` stands.  Entry note is transition
  ##     fact, first ledger has that is about safety rather than
  ##     shape; `sim/verdicts.md` records what jointed-arm sim makes of
  ##     low lock: hand led behind back at whole turn,
  ##     block just past it.
  ##   Rule 38's under-or-over *other* arm is mark no drawing here
  ##     makes yet: settled reach bends around hands it does not join
  ##     (rule 22), so crossing wrap makes with its dancer's other
  ##     arm -- very thing that tells low wrap from high one -- is
  ##     exactly what routing avoids drawing.  Recorded as open rather
  ##     than patched: saying it needs other arm in picture, and
  ##     decision about rule 22's scope.
  ##   Rule 39 makes modifiers per-arm for either dancer, up to one
  ##     each.  Drawing model holds level and way per *connection*
  ##     and settles only follow, which covers sheet's validated
  ##     rows but not its enumeration; widening it is restructure, noted
  ##     in README's open questions rather than done quietly here.
  ##   Rule 40 is sheet's one filled rotation row, and sim asks it
  ##     independently (`sim/verdicts.md`): from Left to left held low,
  ##     jointed-arm sim reads lock way as row does -- hand led
  ##     behind back, whole turn reached -- and blocks wrap way
  ##     at three tenths of turn, at his shoulder's twist, short of
  ##     row's half.  One place row and sim differ, recorded;
  ##     neither was told other's answer.


const FROM_ABOVE*: array[2, tuple[level: Option[Level], way: Option[Way]]] = [
  (some Level.High, some Way.Wrap),
  (none Level, none Way),
] ## Only transitions out of `above`, per rule 8: upper wrap, or back
  ## to default.
  ##   *Upper wrap* is read as high wrap; that reading is
  ##     implementer's, not rule's, and page flags it as such.
  ##   Ledger data like `RULES`: nothing loads it yet.  Check used to
  ##     doAssert it against its own spelled-out copy, which checked
  ##     nothing and is gone; making it load-bearing is same open TODO.
