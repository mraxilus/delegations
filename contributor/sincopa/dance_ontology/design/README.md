# The rotation mark workbench

The visual language for the rotation half of the ontology, worked out as
published pages of mock-ups before any of it is built into the app.  The app
deliberately excludes rotation until these marks are settled and the ontology
is finished — see `../src/dance_ontology/rotation.nim` for what the model already
knows, and the repository README for why the views came out.

Four pages, because they are four explorations that happen to be related:
`frames.html` is the frame picture (what a held pair of hands looks like, and
how a move changes it), `signs.html` is the turn sign (how to label an *edge*
with an amount of turning), and `turns-single.html` and `turns-hands.html`
are the turn mock-ups so far -- every position a hold turns through and every
transition between them, for one hand and for two.  The second is where a
pair's winding is worked out, and the drawing of it is measured off the pose
rather than told (rule 28).  They share the palette,
the level fills and the two arm inks, which live in `page.nim` and `body.nim`
so they cannot drift.

The turn mock-ups are being drawn one kind at a time and combined only once
each is right: single hands first, then hand to hand, then the crossed
pair.  An earlier `rotations.html` tried all three at once and is retired --
it was built on a ceiling rule 16 has since removed.  Its page module went
with it, and so has the drawing machinery only it used.  What was published
under its old name is not the record of what it claimed: the log is, and the
rules below, which say for each what replaced it.

The first two turn pages are duals, which is the shape of the whole scope: a
single hand above turns for ever, so its wind is not part of its state and its
orientation is all of it; hold both hands and a whole turn returns every
orientation, so the wind is all of it instead.

```
nim r tools/build.nim pages                       # checks everything, writes all pages
nim c -r --hints:off design/marks.nim build/design # the four, by hand, from the project
```

The build refuses to write a page whose claims fail: the checks in
`checks.nim` run between building a page's parts and writing it, and several
figures are asserted during their own construction.
Every page is a build product under `build/design/`, never committed: the
repository reads only registered file kinds.  Each is published at a fixed
URL, and republishing the rebuilt file to that URL is the whole release step.
Every one of them is a mock-up rather than a page the project stands behind,
and its published title says so.  The URLs are listed once, with every other
page this project publishes, in `../README.md`.

`wholecloth.html` is the one hand-drawn page, written by hand as
`../mockups/wholecloth.html`:
the ontology redrawn from the ground up and reviewed plate by plate.  Its one
generated part is the turns
panel, which animates a hold turning by drawing what the body sim found --
`turns.nim` runs `../sim` natively, sweeps every hold at every height a
fiftieth of a turn at a time, and writes every moment as data: where the
bodies stand, where each joint of each held arm is, which way each arm lies,
and where the turn runs out and why; the page only draws, through
`wholecloth_turns.nim`, compiled to JavaScript.  The turn stops
where a joint or a body refuses.  Rebuild and splice it with:

```
nim r tools/build.nim pages   # sweeps with design/turns.nim; wholecloth.nim splices it
```

`turns.js` and the spliced page are both build products under `build/design/`.

To screenshot them (the animations need a browser):

```
make shot                                       # builds build/design/shot.js
node build/design/shot.js build/design/frames.html out-prefix
```


## Rules as given

Every rule stated for this drawing, in the words it arrived in, and the check
that holds the drawing to it.  The wordings live as data in `rules.nim`, the
ledger this list mirrors entry for entry — mirrors by hand: nothing loads the
ledger yet, and `rules.nim` records making it load-bearing as an open
question.  The checkers run on every build and print one line per standing
rule, twenty-nine lines for the forty entries here.  A rule that is only
implemented and not asserted is a rule that quietly stops being true, which
has happened here more than once.

1. **"the hands should only pass through the circle when the hand positions are
   above."**  And at *every instant a moving picture draws*, not merely at the
   frames it is sampled at: a browser blends two sampled frames point by point,
   so two that disagree about which side of a body the line passes are drawn,
   in between, as a line sweeping straight through it.  `oneWayRound` settles
   the way round once for a whole move so no two frames can disagree, and the
   check samples the blend.  *This one got past two rounds of checks that looked
   only at the frames.*
2. **"the hands can only move from their positions at the side of the body only
   if a level is specified"** — and a level alone is not enough: without knowing
   whether the hold locks or wraps there is no knowing which side the hand went
   to, so both must be named.
3. **"the slots are relative to the front facing side of the lead/follow, not
   from the diagram itself."**  Six spots, `{left, right} × {front, default,
   back}`, every one a bearing off that dancer's own facing.  `SLOT_OFFSET` is
   44°, and two marks need 34.9°, so none of them touch.
4. **"high and low wraps go around to the front of the other hand."**
5. **"low lock goes around the back to the back of the other hand."**
6. **"in high lock the line goes around the back of the modified body"**, to the
   back of the current hand.
7. **"lock/wrap positions can only be used when the connecting line goes around
   no less than just under 1/2 of the circumference.  it doesn't make sense to
   have a wrap or a lock without the line actually going around the body."**
   The arcs this geometry makes are quantised, so `WRAP_MIN` at 170° picks out
   the full half and nothing else — and most states stop existing in most
   orientations.  The build refuses to draw one that falls short; the frame page
   draws the whole grid of which exist where.
8. **"above has no locks/wraps and can only transition to upper wrap or back to
   default (physical restrictions)."**  `FROM_ABOVE` records the two.  *Upper
   wrap* is read as the high wrap — that reading is mine, not the rule's.
9. **The connection is drawn in its two hands' own colours**, meeting at its
   middle, the lead's end in the deep shade.
10. **"using only the rotations that allow us to change between just those
    (i.e. assumed all rotations are high so no wraps/locks)."**  The rotation
    page's standing assumption: every held connection carries the high dot,
    no way is ever named, and nothing settles off its side.
    *The page is retired and the assumption inverted since: rule 17 carries
    a turning hold `above`, and the build now asserts the high dot is
    absent from the turn figures.*
11. **"no additional frame positions, just the addition of rotations that
    let us travel between them."**  Every position the rotation page draws is
    one of the app's eight frames, wound.
    *The rotation page is retired; the standing form of the rule lives on
    the turn pages, whose positions are the app's four single-hand frames
    in their four orientations, and the crossed pair along its chain.*
12. **"hand to hand should have 3 positions allowed by rotation."**  Half a
    turn each way and no further -- two connections halve the ceiling.  A
    single hold gets five, a full turn each way, the model's own measured
    capacity.
    *The single-hold half is superseded too: rule 16 removed the ceiling a
    lone hand was counted against, so it has four orientations and no
    wound-out end rather than five positions.*
    *The count has grown twice since, on the rules' own instruction: rule 28
    put an X between each pair, making five, and rule 31 a swan beyond each
    end, making seven.  What held is the shape -- a chain with ends, not a
    cycle.*
13. **"left to left and right to right should technically have 4 (left over
    right, right over left, and the two sides with an extra arm twist, in
    either direction)."**  The twisted states are the ends: the middle edge
    is the full turn that swaps which arm is over.  *That chain shape is the
    implementer's reading of the words, flagged on the page as the thing to
    check.*
14. **"the rotations should be high, such that there should be no body
    wrapping, also make sure any twists are visually clear just like the
    crossover."**  At high the arms are up, so every connection on the
    rotation page runs straight and passes *over* what it meets; no route
    hugs a rim, and the check measures it.  A twist is said as a crossing
    with the crossover's own over-under break -- free from the geometry for
    a pair, since half a turn swaps parallel for crossed; drawn as a rope
    of three crossings where a pair is wound a whole turn; and as a pigtail
    where a lone connection has no partner to cross.  *The pigtail is the
    implementer's invention and is flagged on the page.*  Rule 16 has since
    retired the pigtail for single hands -- see below.
    *Neither the pigtail nor the rope-of-three is in the code any more.  Rule
    16 took the ceiling the pigtail marked, and rule 28 replaced the drawn
    braid with a wind that is measured off the pose, so both drawing channels
    lost their last caller and have been removed along with the page that
    owned them.*
15. **"for each mock up, a static image version of every derived position
    and full set of animated transitions between states."**  One mock-up
    per kind of turn, each holding every position it derives and an
    animation of every edge between them.  The counts are checked against
    the state graph rather than against a number typed in.
16. **"if held high, they can turn infinitely in either direction, so all
    we add is the additional quarter turn orientations for each of the 4
    single hand connections."**  Nothing on the single-hand page is ever
    refused, and the round closes.  It also takes the wind out of the
    state: a hold that turns for ever has no wound-out end, so how far it
    has wound cannot be part of what it is, and only the orientation is
    left.  That retires rule 14's pigtail for single hands.
17. **"all turns should be in the "above" position, not the high. high/low
    causes wraps/locks, so we're currently making the assumption to avoid
    those."**  The turns pages hold every arm above -- over the head, on
    the axis the couple turns about -- which is the one level rule 8 gives
    no lock and no wrap, and the one that draws its connection straight
    over everything.
18. **"the leads' transitions should still be in the 2 stage form, stage 1
    is the lead turns with the original perspective stage 2 is reorienting
    the perspective."**  A lead's turn is animated as the dance has it: the
    room holds still while they turn, and only then does the picture come
    back to facing them up.  A follow's turn leaves the lead facing up
    already, so it needs only the one stage -- measured, not assumed.
19. **"you should also include orbit turns not just the axis turns."**
    Four manners: each dancer's own axis turn and each dancer's orbit of the
    other, the orbits marked by the dashed ring while they happen.
20. **"make sure orbit turns keep their bearing, youre currently combining
    orbit and axis turns to keep the partner facing the other."**  The
    walker arrives facing the way they set off; `pose.orbit`'s `locked`
    form, which keeps their face to their partner, is an orbit *and* an
    axis turn danced together and is named as the compound it is.
    Measured with the bearing kept: the two orbits walk **one** round
    between them -- the drawing cannot say who walked -- and that round is
    neither axis round.  Four manners of turn, three rounds of positions.
    ***Reversed by rule 32***, which is what the code does now: the
    bearing-keeping walk is the compound and the locked form is the orbit.
    This entry is kept for what it measured, not for what it concluded.
21. **"also, the animations should also have the above level as that's the
    only valid one for the current scope."**  A moving hand wears its
    level as a still one does; every transition on the turns page carries
    the above hatch, counted on each build.
22. **"an arm shouldn't settle in a hand cell it's not connected to. it
    should bend around all hand cells and chevrons as to not imply
    connection and not obscure direction. it is however fine to animate
    smoothly past it as it would do now for a full turn for example."**  A
    settled reach is a band pulled taut *past* every mark it does not join
    -- both chevrons and every hand but its own two -- bending locally round
    each and running straight where nothing is in the way.  The clearance is
    taken from what is actually drawn: a square's corner, a circle's edge, a
    chevron's own two strokes, each plus the connection's half width and a
    seen gap.  The exemption for a moving reach is the rule's own, and the
    check asserts *both* halves -- statics clear every mark, animations stay
    straight.  *Carried on the turns pages first; the frame page's straight
    and wrapping reaches are the next piece, and `figure.renderFigure`'s
    `clear_marks` parameter is the switch that will do it.*
23. **"the current line finding does a good job of finding the shortest
    line, but we also need to balance simplicity. prefer paths that have
    fewers bends (ideally 1) as well as length. in many cases I see, 1 bend
    can be used with minimal change to the overall line."**  The shortest
    way past the marks is not the plainest: it weaves, one mark passed on
    the left and the next on the right, and a reader has to follow every
    change of direction.  So a reach is judged on **length and turns
    together** -- a turn is worth `BEND_COST` of line -- and beside the
    shortest way two more are worked out: the taut string held to one side
    of the chord, which is the upper hull of the marks on that side and so
    is a single bend by construction.  The rule's "ideally 1" is read as
    *leave alone anything already turning once or not at all*.  Measured on
    the build: of the sixty-four settled reaches the single-hand page draws,
    fifty-six ran straight, eight bent exactly once and none bent twice —
    and the one-bend way is usually the **shorter** line as well.  (A
    snapshot: the build prints the live split and asserts only that nothing
    bends three times.)
24. **"prefer smooth long curves instead of sharp breaks as well. some of
    these can be accomplished with a singular bezier with a more gentle
    curvature just as well as the current sharp direction changes."**  Rule
    23's one-bend route was the hull of the marks, and a hull is a
    polyline: its apex is a *break*.  The hull is now read as a guide --
    where the bulge belongs and how far out it has to reach -- and the line
    drawn is a **single quadratic bezier** over that apex, swelled until it
    clears every mark.  A bezier turns one way only, so the route is still
    one bend, and it has no corner in it.  A route that already runs plain
    is only left alone if it is *also* smooth, so a break is never kept for
    being short.  Measured when the rule landed: the sharpest corner then
    turned 6.5 degrees.  (A snapshot from before rule 35's quadratics; the
    build asserts the corner of the stored polyline, and the drawn curve is
    smoother than what it measures.)
25. **"reposition the lead such that when the follow orbits or the lead
    turns on axis, the 2nd animation stage doesn't have to move the result
    around, i.e. lead position should remain fixed as much as possible
    (obviously this can't really be the case when the lead orbits, a
    reposition/re entering) will still be necessary I think."**
    `canonicalise` turned the world about the couple's **midpoint**, so any
    move that shifted that midpoint carried the lead across the box in the
    second stage.  It now takes an `Anchor`, and the turns pages frame on
    `Anchor.Lead`: the turning goes round the lead's own place and that
    place is what comes back to the middle.  A follow's orbit then needs
    **no second stage at all**, a lead's axis turn swings only the follow,
    and a lead's orbit -- the case the rule allows -- is the one move with
    anything to bring back.  *It brings back both halves now: under rule 32
    an orbiter turns as far as they travel, so the lead comes home with a
    quarter of rotation to undo as well as the slide.  Under rule 20 it was
    the slide alone.*  Measured: the lead holds one spot through three of
    the four manners of turn and across every position of every round.
    *The frame page keeps the midpoint anchor for now, which is what holds
    `frames.html` still; carrying it over is the same piece of work as
    rule 22's.*
26. **"make the second animation stage quicker or something so it has less
    emphasis. or whatever the recommended UX is to make it less noticeable
    than the actual rotation itself."**  The two stages had a sample each
    way and so a share of the clock each way, which read as one long motion
    in two halves.  A `Walk` now carries **when each of its frames is due**
    as well as where it is, and the markup says so in `keyTimes`, so how
    long a stage lasts is the drawing's decision rather than a side effect
    of how finely it was sampled.  Three things rank the stages, which is
    what motion design does with any secondary or camera move: the
    re-framing is paced at a fraction of the turn (`RE_FRAME_PACE` is 0.4;
    the clock the markup carried measured 35% when this was written, and
    the build asserts only that it stays under half the turn's), a beat is
    held on the turn's landing so the two do not blur together
    (`ARRIVAL_HOLD`), and it still starts and ends softly, because an
    abrupt start is the one thing that would pull an eye back to it.  The
    check measures it on the emitted clock, not on the constants: an
    interval where the pair's own configuration changes is the turn, one
    where the whole picture moves rigidly is the re-framing.
27. **"the two twisted ends in reality the arms make an overlapping box
    shape. on one side of the twist the lead left is over the right
    (reversed for other end of twist). the arms should reflect that visual
    on both ends of the twist. there should be two crossovers one on the
    leads side of the arms, one on the follows. for both sides of the twist
    chain. there should be a visible box/diamond between the crossovers
    (hence the preliminary names, Left over Right box, Right over Left
    box)."**  Two answers fix how it is read: *"three positions, full turn
    required between them"*, so a step on the hand-to-hand page is a **whole
    turn** -- which is what makes rule 12's three a chain, since a whole
    turn puts every place and every facing back where it was and leaves only
    the wind; and *"they alternate"*, so whichever connection is over at the
    lead's crossover is under at the follow's, because that is what being
    wound together means.
    Each reach runs its own side clear of the body it leaves, swings the
    whole way over to its partner's side and swings back, the two at their
    widest in the middle -- a **diamond** coming to a point at each
    crossover, not a four-square box, which is the shape asked for on
    seeing it drawn both ways.  Starting the swing at the hand instead
    would cross the pair over the body it left, where the chevron is, and
    no swing wide enough to make the shape could clear it.
    *Rule 28 has since replaced the drawn version of this with a measured
    one -- see below.*
28. **"the animations are very jankey and tied to the final visual
    representations of the box/diamond state, add the half turns which
    should actually form an X overhead when partners are facing the same
    direction (similar to the existing L-over-R etc. when facing one
    another) as states in-between the outside 2."**  Two things, and the
    second explains the first.
    **Five positions**, a half turn apart: box, X, the frame, X, box.
    *Rule 31 has since added a swan beyond each box, making it seven.*  At a
    half turn the partners face the same way and the pair crosses once --
    the plain X the app already uses for a crossed pair -- and at a whole
    turn it crosses twice with rule 27's diamond between.
    **And the wind is now measured, not handed over.**  Each held hand sits
    on its own body's rim and both bodies stand on the pair's axis, so the
    angle a hand makes with that axis is what going round means; the
    difference between the two ends is the wind.  A reach is then the
    shadow of a wound arm from above: its offset from the axis swings as
    far round as the pair has wound, nipping in between the hands the way
    wound strands do.  Straight at none, an X at a half, a diamond at a
    whole, every frame between following from the same measure -- which is
    what stops a turn snapping into a shape it was told to end in.  Only
    the whole turns already in a hold have to be said, since a whole turn
    puts every hand back where it was.
    *And it corrected the page: an orbit that keeps its bearing turns
    nobody, so it winds nothing.  The two axis turns walk this chain; the
    two orbits carry the pair around it.  The first draft claimed all four
    wound, which was only true because all four had been told to.*
    ***Rule 32 has since made that finding moot*** by changing what an orbit
    is.  A walker who keeps their side to the centre does turn relative to
    their partner, so all four manners wind after all — and this time it is
    measured rather than claimed.  What survived the reversal untouched is
    the measuring itself.
29. **"the animations don't have the proper breaks that the static images
    do, they seem to not be tracking which arms are over/under because of
    this and they are instances where they end up on the wrong z order,
    fix."**  A still reach is *cut* into runs where it dives under its
    partner, and how many runs that makes changes with the number of
    crossings -- which a morph cannot follow, so a moving reach had been
    left whole.  With nothing broken, which strand is on top was decided by
    the order the two were written in, so one of them was over at *both*
    crossings: not a twist at all, and a contradiction of the still it
    landed on.
    A gap in a stroke is not a gap in a path, though.  A moving reach keeps
    its one piece and wears the break as an animated `stroke-dasharray`,
    which travels with its crossing and closes to nothing where there is no
    crossing -- so the markup never changes shape.  *The pattern is written
    a gap longer than it needs and started a gap in, because a zero-length
    dash under a round cap is drawn as a dot.*
    Which arm dives is not a new decision: the crossings are found as the
    stills find them, the diving arm alternates from the first as the
    stills alternate it, and the first is named by the sign of the measured
    wind -- and the check measures that a moving figure and the still it
    lands on break the same arm.
    *Two real faults fell out of writing that check.  `crossingsOf` was
    finding crossings by how near two reaches' sampled points came, and two
    lines crossing steeply pass between one another's points without any
    pair being near -- so an X was drawn with no break at all.  It tests
    segment against segment now.  And counting the pieces a reach is drawn
    in cannot see a break that falls where its two shades meet, since that
    makes one piece of each rather than two of one; the checks measure
    drawn length instead, which sees a break wherever it lands.*
30. **"the boxes/diamonds are the ends of the turn chain this highlighted is
    not allowed. all I'm referring to is that double box is not allowed."**
    The chain is a chain and not a cycle: a whole turn each way is as far as
    this scope winds, so nothing may be drawn wound a turn and a half.
    The fault was in the turning, not the drawing.  Every edge of every way
    was built with the same *positive* half turn, but the two axis turns
    wind opposite ways -- a positive turn by the lead unwinds what a
    positive turn by the follow winds.  The chain's winds run the follow's
    way round, so the lead's row was walking backwards off the end: from the
    diamond at a whole turn out to a turn and a half, which drew a third
    crossing and a second diamond.
    So each way's winding sense is **measured**, as rule 28 measures the
    wind itself: turn a quarter from the frame and read the wind off the
    farthest pose the walk passes through.  *The farthest, not the last,
    because a walk rocks out to its turn and back again and so ends where it
    began; and a quarter, not a half, because a half turn's wind sits
    exactly on `wrap180`'s seam and carries no sign.*  A way that winds
    nothing -- either orbit, as orbits then were -- takes the forward sense:
    it has a real half turn to travel and no end to walk off.  *Rule 32 has
    since left no such way; that fallback is unreachable now and stands only
    so a way that stopped winding could not silently freeze.*
    The check reads the wind on every frame of every edge of every way: none
    beyond a whole turn, each edge starting and ending on its own position,
    and each winding edge reaching the position the chain says comes next --
    which is also what the caption under it had been promising.
    *Rule 31 has since moved those ends out to a turn and a half.  The rule
    was that the chain has ends and they hold, not that they sat at a whole
    turn; what it refused -- the double box -- is refused still, by the swan
    being drawn as a swan.*
31. **"both hand to hand and the overs are essentially the same thing but
    with one half turn of offset ... hand to hand actually has an extra half
    turn on both ends (which I previously thought only the other pattern
    had). this means both patterns follow the same logic, just one starts
    with the partners facing each other, and the other starts with both
    partners facing the same way."**  Checked physically, and it settles
    rule 13's *"two sides with an extra arm twist, in either direction"*:
    that extra twist is not the crossed pair's alone.  Hand to hand has one
    at each end too, so the chain is **seven** -- swan, diamond, X, the
    frame, X, diamond, swan.
    What differs between the two holds is only *where the chain sits*.  A
    hold is unwound where its two connections run parallel, and that falls
    at a different facing for each of them: hand to hand face to face, the
    crossed pair with one partner facing away.  So `parts.phaseOf` measures
    it -- turn the follow to each candidate and see which leaves the hold
    unwound -- `parts.chainFor` lays the seven steps out from there, and the
    crossed-pair page becomes this page's code with a different hold.
    **The swan.**  Asked what a turn and a half looks like: *"don't draw it
    as a double box, draw it as one connection being straight and the other
    snaking around it (as that's how it looks in reality when I tried it).
    I'm giving it the preliminary name of swan, as it looks like the necks
    of two mating swans surrounding a center straight connection."*
    So past a whole turn the pair stops sharing its swing evenly: `route.
    windShare` hands it over, and at a turn and a half one reach is the
    plain chord between its own hands while the other carries the lot.
    Handed *over* rather than merely given up -- the straight one's share
    goes to the snake -- because a snake that only kept its own swing made
    loops too shallow to read as going round anything.  And the straight one
    is the one on top at the first crossing, which by the alternation dives
    only once: broken twice, there is no straight line left in the middle
    for anything to surround.
    *Two latent faults fell out of drawing it.  `dashedAt` decided which
    half of a reach a break belonged to by how near the crossing was in the
    plane -- fine for a line that only ever goes one way, wrong for one that
    snakes back past itself, and it drew breaks where there was no crossing.
    It takes the dive as a distance **along** the reach now (`route.
    alongAt`).  And a moving reach had room for exactly one break; a swan
    puts two on one connection, so the dash pattern carries `GAPS_DRAWN` of
    them, written every frame and mostly zero long.*
32. **"orbit should not maintain bearing, but instead keep whatever side
    faces the center, facing the center otherwise we can't equate the 1/2
    turns."**  This **reverses rule 20**, and the reason given is the one
    that matters: it is about the whole scheme, not about orbits.  Rule 20's
    orbiter never turned relative to their partner, so -- measured, under
    rule 28 -- that orbit wound the pair by *nothing*.  Half a turn of it was
    half a turn of no quantity, and two of the four manners of turn did not
    walk the chain at all.  An orbiter who keeps their side to the centre
    turns as far as they travel, so an orbit winds exactly as far as it
    carries, and every way steps one position per half turn.
    `pose.orbit` has always had this as `locked = true`; rule 20 turned it
    off and rule 32 turns it back on.  What rule 20 objected to -- *"combining
    orbit and axis turns"* -- is the same arithmetic seen from the other
    side, and it is the bearing-keeping walk that is the compound now: an
    orbit with a counter-turn danced into it.
    **The consequence runs through everything.**  An orbit lands where the
    *other* dancer's axis turn lands, so the four manners walk **two** rounds of
    positions rather than three, each reached by one axis turn and by the
    other dancer's orbit.  All four stay drawn: which dancer walked is a fact
    about the path, and only the path can say it.  On the frame page the two
    collapse figures swap over -- the orbit is what lands on the matching
    axis turn now, and the compound is what lands somewhere of its own,
    reached by either dancer since only the pair's axis has swung.  *That
    page is back where it began: it said axis against orbit was a property
    of the move and not of the state, rule 20 made that false, and rule 32
    makes it true again.*
33. **"the swan zig zag is a bit to large, make it tighter so it looks more
    readable. also, the above level hatching appears to be a background that
    moves around a lot as the squares/circles move, it should stay visually
    consistent during animation."**  Two things, and the second was a real
    fault rather than a matter of taste.
    **The swan.**  Tried, and **taken back by rule 34** — see below.  What
    survives is that how much swing the snake carries is now a named knob,
    `route.SWAN_SWING`, rather than an expression.
    **The hatch.**  An `above` fill is an SVG `<pattern>` with
    `patternUnits="userSpaceOnUse"`, so it is anchored to the drawing rather
    than to the shape.  A moving hand animated its own `x`/`y` or `cx`/`cy`,
    which slid the mark across a hatch that was standing still — so the fill
    swam about inside its own outline.  A moving hand is now drawn once at
    the origin and carried by a transform, exactly as a body is: the
    transform establishes the user space the pattern is read in, so the
    hatch travels with the mark.  *It also let the high dot go back inside
    `hand()` — a group can hold two elements where `paired` reopens one.*
    The check is that a hatched mark is childless: an element that animates
    nothing of its own has no coordinates to slide.
34. **"the hatching is good, but revert the swan change, it looks worse."**
    So `SWAN_SWING` went back to two — the whole of what the straight
    connection gives up — and the check's upper bound on the bow dropped
    back to a backstop: far enough out to catch a snake that has left the
    figure, and no opinion within that.  *Rule 35 sets the width again; the
    backstop is what stayed.*
    *Rule 33 was one instruction and turned out to be two different kinds of
    thing.  The hatch was a fault the drawing could be held to; the width of
    the swan was a matter of looks, and looks are settled by looking.
    Naming the knob was worth doing either way — what it is set to is the
    author's call and not the checker's, and the check should say so.*
35. **"they both have the same issue, go back to the tighter version try to
    make the swan arm, even tighter to the straighter arm, but make it
    smoother (a simpler curved, right now it looks jagged/sharp)."**  Which
    finds what was actually wrong with both swans, and it was never the
    width.
    A reach is held as `ROUTE_N` points because that is what lets it morph,
    and it was **drawn** between them with straight bits.  Everywhere else on
    every page that is invisible — rule 24 keeps a settled reach turning a
    few degrees a corner — but a swan's lobes double back inside a handful of
    points, so the polygon it is stored as was exactly what was on the
    screen.  Widening or narrowing it only changed how big the facets were.
    So `route.smoothed` draws a reach as quadratics: the sampled points
    become the *control* points and the midpoints between them the places the
    curve passes through.  Corners round off by half their own segments, the
    ends stay exactly on their hands, a line that hardly turns moves by a
    fraction of its own width — and the command count still follows the point
    count, so a smoothed reach morphs exactly as a straight-sided one did.
    *`inkOf` reads the anchors back out of the curve — a `Q`'s control point
    is the routed point — so every length the checks measure is the length
    they always measured.*  The width comes down as well: the rule asks for
    tighter than either version tried, so `SWAN_SWING` goes below both of
    them and the snake keeps in closer to the straight connection than it
    ever has.  The check on it stays a backstop — that the snake goes round
    something and stays inside its own figure — because what it is set to is
    the author's call and not the checker's.
36. **"above: connection held above head. high: connection held above
    shoulder level (about neck). low: connection held below shoulder level
    (about torso)."**  Every level is a height.  This corrects a reading the
    codebase had held — low and high documented as which arm lies over which
    — which was never the level's business: the over-under of two arms is
    part of what a *wrap* is (rule 38).  The legends and the term docs say
    heights now.
37. **"lock: where a lead/follow's arm is bent behind their back (low) or
    bent to the shoulder of the same arm.  To get into low lock, the form
    must enter from a low position only due to physical/safety
    limitations."**  The high lock and rule 6 are one shape — round the back
    up to the arm's own shoulder, a hammerlock — so the settle table stands.
    The entry note is the ledger's first transition-safety fact; the sim
    reads it geometrically in `sim/verdicts.md`.
38. **"wrap: where a lead/follow's arm is crossed around the front of their
    body under (low) or over (high) their other arm."**  The under-or-over
    mark is one no drawing here makes yet: a settled reach bends around the
    hands it does not join (rule 22), so the crossing a wrap makes with its
    dancer's *other* arm is exactly what the routing avoids.  Open, not
    patched — see the open questions.
39. **"generated two hand combinations for up to 1 modifier per lead/follow
    (maximum 2 total across all 4 hands); permutations with 2 modifiers for
    a single person are excluded, until deemed necessary."**  Modifiers are
    per-arm, for either dancer.  The drawing model holds one level and one
    way per connection and settles only the follow; widening it is a
    restructure, held in the open questions rather than done quietly.
40. **"half-closed, Left to left held low: wrap at left@0.5, lock at
    right@1."**  The sheet's one filled rotation row, and the sim derives it
    independently (`sim/verdicts.md`): half a turn one way lies the arm
    across the front — the wrap — while the lock takes a *whole* turn the
    other way, the rope merely leading the hand behind the back at its half.
    Neither the row nor the rope was told the other's answer.

## What is settled

Decisions the pages record, each with the reason it went that way.  These are
the compact form of a long design conversation; changing one should change the
page and this list together.

**The frame picture.**

- Every hand is drawn in **its own side's colour** — `--left` blue, `--right`
  orange — for both dancers, and in **its owner's shade** of it: the lead's
  deep, the follow's plain.  Each of the four is named as a custom property
  **with a fallback**, `var(--left, #3d7fd0)`, so a picture follows the page it
  is on and still draws in chosen ink when it is opened on its own — which the
  app's `doc/frames/*.svg` are, and `tests/treview` holds every colour to it.
  Which column a hand occupies is decided by which
  way its owner faces, so a row read across is that dancer's orientation, and
  the four facings (face to face, either turned, back to back) are distinct
  without a new mark.
- **Shape says whose hand it is**: the lead's are squares, the follow's
  circles.  This is the vocabulary's own convention, carried by the mark
  itself so it survives any size.
- A connection is drawn in **its two hands' own colours, meeting at its
  middle**: the lead's half in their arm's ink and the deep shade, the follow's
  in theirs and the plain one.  So the line *draws* which named hands are
  joined — `Left to right` runs blue into orange along its whole length —
  instead of leaving it to two marks that vanish at node size, and the deep
  half still says which end is the lead's when both hands share a hue.  Its
  geometry says whether the hold is crossed *now*.
- **Level is a fill** on both ends of a connection: hollow = unsaid, solid =
  low (below the shoulder, about the torso), centre dot = high (above the
  shoulder, about the neck), hatched = above (over the head).  Every level is
  a height (rule 36); which arm passes over which is the wrap's business, not
  the level's (rule 38).  A crossed hold's drawn break stays: it reinforces
  the geometry and survives node size.
- A hand nobody holds **fades to half strength but keeps its hue**, because the
  `free` frame is four free hands — which is where its name comes from — and
  greying them would erase orientation exactly where nothing else can say it.
- A **body is a plain circle with a small chevron at its centre** for the
  facing — the centre is the one part of a dancer nothing else uses.  The
  boundary stays one polar function (`outlineR`) so the routing and the
  drawing cannot disagree about it.
- The **rim says nothing but *here is a body***: one quiet stroke, drawn once,
  breaking around every hand mark (`HAND_GAP`, the reach's own clearance turned
  into arc).  It used to fill up in an arm's colour as that arm wound — a
  progress ring round the outside — and that is gone, because the connection
  already wraps.  One indicator, not two.  What that costs is in the open
  questions.
- A **reach is a taut string**: it starts on the border of the hand's own mark,
  hugs the rim exactly where the straight way would cross a body, and is
  straight everywhere else.  With nothing said it takes the **short way** —
  there is no standing preference for a dancer's front.
- A settled hand is in **one of six spots** and the routing follows from the
  hold; both are rules as given, so see the ledger above rather than here.
- `SLOT_OFFSET` is how far round the rim `front` and `back` sit from a side --
  a drawn convention, wide enough that a mark never touches the grey ghost of
  the place it left, which is asserted.
- **Where a hand has left its default, the place it left is drawn as a grey
  outline** (`figure.ghosts`), so a picture says both where the hand is and
  where it came from.
- A move's **way round is settled once, for the whole move** (`oneWayRound`),
  and every frame of it uses that one.  A stronger thing than the
  counter-rotation preference it replaced, and it is why `SIDE_BIAS`,
  `HYSTERESIS`, `prefer` and `trailing` are all gone.
- Only **`above` passes through a body**: it is over the head, so from overhead
  nothing is under it and it is drawn straight (`route.straightReach`).  Every
  other level, and no level, goes round.
- **The lead always faces up.**  Poses live in world coordinates and are drawn
  through `canonicalise`, which turns the world until the lead faces up — so
  every pose that is the same configuration is the same picture, and the whole
  state is two numbers: where the follow is round from the lead, and how the
  follow faces.
- A move animates in **two stages** — travel, then canonicalise — and a cycle
  (go, home, back, home) closes exactly, so animations loop without a snap.
  Bodies are rigid and are carried by transforms, on a **continuous** facing
  sequence (`geometry.continuous`): a wrapped one steps from 179 to −179 at a
  half turn and is interpolated as most of a turn backwards, which is a body
  spinning the wrong way while its own hands travel the right way.  Only the
  reach re-routes per frame, and it re-routes with the one way round the move
  settled before any of it was drawn — see the bullet above.
- An **orbit goes round the other dancer**; a dashed ring appears only while
  one is happening, centred on whoever stands still.  Nothing else is dashed.
- **What collapses** (checked, not argued).  A quarter **orbit** — the walker
  keeping their side to the centre, which is what an orbit is under rule 32 —
  lands on the byte-identical picture the *other* dancer's quarter axis turn
  lands on.  So a position cannot tell an orbit from an axis turn: which was
  danced is an edge label, never a node's concern.  And the **compound** — an
  orbit walked while counter-turning, so the walker keeps their own bearing —
  lands on one picture whichever dancer walks it, since only the pair's axis
  has swung, so the drawing cannot say **who walked** either.  What does
  **not** collapse: the compound against an axis turn.  They land in different
  places, so the two really are two moves.  *This bullet has been round the
  houses: rule 20 put the collapse on the compound and rule 32 put it back on
  the orbit, which is where the page first had it.*  Likewise both dancers
  going round each other is a picture no-op, which matches the model: a couple
  rotation stores no twist.

**The turn sign.**

- A leaning box that holds **exactly one full turn**; rows are **quarter
  turns**, packed up from the foot, so amount reads as fullness before it
  reads as a count.
- Columns are the **lead's two arms**, in the frame picture's own order and
  inks; a pip's **shape** says whose quarter it is (leaning square = lead,
  circle = follow), its **shade** says the same thing a second time (deep for
  the lead, plain for the follow, as the hands do), and its **fill** is that
  arm's level, reusing the hand fills.
- Rows may **mix dancers** (follow's rows always on top), so a turn shared
  between the two is one sign.
- A **dashed outline** marks a turn that travels round the couple — an edge
  label, consistent with the collapse above.
- There is **no refused sign**: a turn that cannot be danced is an edge that
  is not drawn.


## What is still open

The user's side of the table, as of the last iteration:

- **Whether *upper wrap* means the high wrap** in rule 8, which is the one
  reading in the ledger that is mine rather than given.
- **`SLOT_OFFSET`**, how far round the rim *front* and *back* sit from a side.
  A drawn convention rather than anything the dance says, floored by a mark not
  being allowed to touch its own ghost.
- The mark for **any amount** of turn: five candidates are drawn on the sign
  page (open-ended box — recommended; open with a spilling pip; ellipsis row;
  music's repeat colon; a loop arrow).  None chosen yet.
- Whether the turn sign **survives at all** now that axis-against-orbit is an
  edge property the frame pictures can animate.
- Whether `rotation.nim` gains **per-dancer facing**: the four orientations are
  two bits and `twist` carries only their parity, so `isFacing` cannot tell
  face-to-face from back-to-back.  The two relative facings the canonical
  picture is built on are exactly the pair the model would need.
- Whether an arm **carried past some ceiling** is marked at all, now that
  nothing on the rim counts and the quantity lives in where the hand sits.
- The **bow** for contact with the body, the **staff** for sequences, what an
  orbit stores, and when an arm above the head blocks.
- How a wrap's **under-or-over the other arm** (rule 38) gets drawn: it is a
  crossing with the dancer's *other* arm, and rule 22 keeps a settled reach
  away from exactly that hand.  Saying it needs the other arm in the picture
  and a decision about rule 22's scope — until then a low wrap and a high one
  differ only by their fill.
- Whether the model goes **per-arm on modifiers** (rule 39): the sheet gives
  either dancer up to one modified arm, while the drawing holds one level and
  one way per connection and settles only the follow.  A restructure, waiting
  on whether the sheet's enumeration is the shape wanted — the same open
  question as whether `Left-to-left and Right-to-right`'s over-variants merge
  (the sheet leans to one hold; the app draws eight frames).


## Layout

All Nim, like the ontology it serves.  **The drawing itself is no longer
here.**  It was settled in this workbench and has moved to
`../src/dance_ontology/draw/`, because the app draws these marks now and the two
must not drift; the workbench imports it from there.  What is left in
`design/` is the argument — the rules, the checks and the four pages.

```
../src/dance_ontology/draw/
  terms.nim     the vocabulary the rules speak in: sides, levels, holds
  geometry.nim  scalars and vectors, in the drawing's conventions
  style.nim     the palette, two shades a side, and the connection stroke
  pose.nim      the couple in world coordinates, and every rotation
  body.nim      one dancer: outline, spots, hands, captions
  route.nim     the taut string a connection is routed as
  figure.nim    whole pictures, still and moving
  scene.nim     the app's own frames, drawn through all of the above
```

and `marks.nim` is the build, over the rest of these in this order:

```
rules.nim       the ledger above as data; re-exports draw/terms
sign.nim        the quarter-turn sign
parts.nim       every figure the four pages place, keyed as they use them
checks.nim      every claim the pages make, asserted and spoken
page.nim        the chrome the four pages share: style sheet, key, wrapper
frame_page.nim  the frame page's prose and layout
sign_page.nim   the turn-sign page's prose and layout
turns_single_page.nim  the single-hand turns page, generated as a table
hands_page.nim  the hand-to-hand turns page, the chain and its four walkers
marks.nim       build: parts, checks, pages, files
shot.nim        screenshot helper (light and dark, full page), nim js
wholecloth_turns.nim  its turns panel, ported to nim js
wholecloth.nim        splices ../mockups/wholecloth.html, sweeps and panel
                      into build/design/
```
