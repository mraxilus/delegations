## Lay out frame page: what held pair of hands looks like, how it
## moves.
##
##   Presentation only -- every claim any figure makes is generated and
##     asserted elsewhere, so this module is nothing but argument's
##     layout.  Turn sign is separate exploration on separate page;
##     see `sign_page.nim`.
##   Body is `{marker}` template and fills close it, so page
##     reads as page it is and unfilled hole refuses to build.
##     Cost of keeping every claim's proof elsewhere: figure's caption and
##       assert that backs it live in different files, held open
##       together.  Accepted -- page stays argument, not program.
##   Body template's lines are held under hundred-column rule by closing and reopening
##     literal at structural points (`<br>`, `<td>`, `<figcaption>`), never inside
##     expression; bytes are page's bytes still, verified once by writing split and
##     unsplit constants to files and comparing them (identical).
##     Cost: template reads as markup broken by `""" &`, which is what repository's form
##       rule costs here.

{.experimental: "strictFuncs".}

import std/[strformat, tables]

import ./[page, parts, rules]


const TITLE* = "The frame, so far"
  ## What page calls itself, in its tab and at its head.


const BODY = """

<div class="sheet">

<header class="top">
  <p class="kicker">Dance ontology · rotation · the frame</p>
  <h1>The frame, so far</h1>
  <p class="standfirst">Each dancer is a plain circle with a small chevron at
  its centre for the facing. A connection runs hand to hand as a taut string
  that wraps a body rather than crossing it, drawn in <b>its two hands' own
  colours</b>, meeting at the middle. <b>A settled hand is in one of six
  places</b> — its own side or the other one, and on each of those where the
  arm hangs, a little towards the front, or a little towards the back —
  decided by the hold's level and by whether it locks or wraps, with the place
  it left drawn as a grey ghost. <b>The hold says which way the line goes
  round</b> too: wraps round the front, locks round the back. And <b>a lock or
  wrap only exists where the line really goes round the body</b>, which turns
  out to rule most of them out most of the time.
  A move animates in two stages: travel, then turn the world until <b>the lead
  faces up</b> again. That second stage collapses every pose that is the same
  configuration onto one picture, and shows that <b>an orbit lands where the
  other dancer's axis turn lands</b> — while an orbit walked keeping one's own
  bearing lands somewhere of its own. And <b>only an <em>above</em> connection may
  ever cross a body</b> — at every instant a moving picture draws, not merely
  at the frames it is sampled at.</p>
  <p class="sibling"><b>The turn sign is on its own page.</b> It answers a
  different question — how to label an <em>edge</em> — and only meets this one
  at the levels and the arm inks, which the two pages share.</p>
</header>

<section>
  <div class="head"><span class="n">Settled</span><h2>Level, and whose hand it
  is</h2></div>
  <p>The fill says level, and <b>the break in the under-arm stays</b> — it
  reinforces the shading rather than repeating it, and it is the mark that
  survives node size when a fill will not. Each hand is in its own side's
  colour, and in its owner's shade of it: the lead's squares deep, the follow's
  circles plain. So the swatches come in pairs, and a pair is a whole hold.</p>
  <div class="plate">
    <div class="key">
      {sw_free}
      <span><b>faded</b> — nobody is holding this hand</span>
      {sw_none}
      <span><b>full, hollow</b> — held, level unsaid</span>
      {sw_low}
      <span><b>solid</b> — low, below the shoulder</span>
      {sw_high}
      <span><b>dot</b> — high, above the shoulder</span>
      {sw_above}
      <span><b>hatched</b> — above, over the head</span>
    </div>
    <div class="row">
      <figure>{f_none}<figcaption>held<br><b>no level</b></figcaption></figure>
      <figure>{f_low}<figcaption><b>low</b></figcaption></figure>
      <figure>{f_high}<figcaption><b>high</b></figcaption></figure>
      <figure>{f_above}<figcaption><b>above</b></figcaption></figure>
      <figure>{f_over}<figcaption>Left <b>high</b>, Right <b>low</b>""" &
        """<br>and the break says it too</figcaption></figure>
    </div>
  </div>
</section>

<section>
  <div class="head"><span class="n">One</span><h2>Circles, and a line that
  wraps</h2></div>
  <p><b>The body is a plain circle, and the facing is a small chevron at its
  centre.</b> The rim says nothing but <em>here is a body</em>: it is drawn
  once, quiet, at one width, and it breaks around every hand mark so nothing on
  the boundary runs through one. It used to fill up in an arm's colour as that
  arm wound round — a progress ring going the long way round the outside — and
  that is gone. <b>The wrap on the connection is the indicator</b>, and one
  indicator is enough.</p>
  <p><b>The reach wraps, and by default it takes the short way.</b> It starts
  on the edge of the hand's own mark, not at its centre, and where the straight
  way to the partner would pass through a body it runs <em>along the rim</em>
  instead — to the first place it can leave on a tangent, then straight, then
  along the other rim to the other hand. That hug <em>is</em> the wrap: the arm
  going round a body is the thing a lock is made of. Nothing prefers the front
  any more; with nothing said, the line simply takes the shorter way round.</p>
  <p><b>A whole move goes one way round.</b> Which side of each body the line
  passes is settled once, before the first frame is drawn, and every frame of
  that move uses it — the way that every frame can actually be routed, and the
  shortest of those. Not a preference: a rule, and the note below says what it
  is guarding against.</p>
  <p><b>The line is its two hands' own colours.</b> Each half is exactly the
  mark it ends on — the lead's in their arm's ink and the deep shade, the
  follow's in theirs and the plain one, the two meeting at the middle. So
  <em>Left to right</em> is drawn blue-to-orange along its whole length rather
  than only at two marks that vanish at node size, and the shade still says
  which end is the lead's when both hands share a hue.</p>
  <p><b>The lead always faces up.</b> That is what the second stage of a move
  aims at — not standing the pair upright, but standing the <em>lead</em>
  upright. Everything is read from them, so they hold still and where the follow
  has got to becomes part of what the picture says rather than something the
  framing throws away.</p>
  <p>An orbit goes round the <em>other dancer</em>, so a dashed ring appears
  only while one is happening, centred on whoever is standing still: the lead,
  the follow, or the midpoint when both travel. Nothing else in the picture is
  dashed.</p>

  <div class="plate">
    <h3>At rest, no ring</h3>
    <p>Which column a hand sits in is decided by which way its owner faces, so
    a row read across is that dancer's orientation and the four facings are
    distinct without a new mark.</p>
    <div class="row">
      <figure>{or_free_0}<figcaption>face to face</figcaption></figure>
      <figure>{or_free_1}<figcaption>the follow<br>faces away</figcaption></figure>
      <figure>{or_free_2}<figcaption>the lead<br>faces away</figcaption></figure>
      <figure>{or_free_3}<figcaption>back to back</figcaption></figure>
    </div>
    <div class="row">
      <figure>{or_held_0}<figcaption>holding <em>Left to left</em></figcaption></figure>
      <figure>{or_tiny_1}<figcaption>node size</figcaption></figure>
    </div>
  </div>

  <div class="plate">
    <h3>A settled hand is in one of six places</h3>
    <p><b>Nothing is solved and nothing is asked for.</b> A hand at rest sits
    where the arm hangs, or a little round towards its dancer's <b>front</b>,
    or a little round towards their <b>back</b> — two sides, three places on
    each, six in all. Which one is decided by the hand's own side, the hold's
    level, and whether the hold is a <b>lock</b> or a <b>wrap</b>.</p>
    <p>They are measured off the dancer's <b>own facing</b>, never off the
    page — which is what <em>front</em> and <em>back</em> name and what
    <em>above</em> and <em>below</em> did not. The chart is drawn on a body
    turned off the vertical, where that is visible rather than merely true.</p>
    <div class="row mid">
      <figure>{slot_chart}<figcaption>the six, on a turned body""" &
        """<br>— the four a Left hand uses, in its ink</figcaption></figure>
      <figure><table class="slots">
        <tr><th></th><th>Left hand</th><th>Right hand</th><th>the line goes</th></tr>
        <tr><td>no level, or no way said</td><td>left · side</td><td>right · side</td>""" &
        """<td>the short way</td></tr>
        <tr><td><em>high</em> wrap</td><td>right · front</td><td>left · front</td>""" &
        """<td>round the front</td></tr>
        <tr><td><em>low</em> wrap</td><td>right · front</td><td>left · front</td>""" &
        """<td>round the front</td></tr>
        <tr><td><em>low</em> lock</td><td>right · back</td><td>left · back</td>""" &
        """<td>round the back</td></tr>
        <tr><td><em>high</em> lock</td><td>left · back</td><td>right · back</td>""" &
        """<td>round the back</td></tr>
        <tr><td><em>above</em></td><td>left · side</td><td>right · side</td>""" &
        """<td>straight over</td></tr>
      </table></figure>
    </div>
    <p><b>Lock or wrap is state the hold carries</b>, and it has to be: the
    place cannot be chosen without it. A hold that names a level but not which
    of the two it is leaves its hands where the arm hangs — the height does not
    tell you which side the hand went to, so the picture does not guess.</p>
    <p><b>And where a hand has gone, the place it left is drawn as a grey
    outline</b>, so a picture says both where the hand is and where it came
    from. The two wraps share a spot; the fill is what tells them apart.</p>
    <p>Each of these is drawn in an orientation that admits it, which is not a
    detail — see the plate after next.</p>
    <div class="row">{settlings}</div>
    <p>Discrete at rest, but not discrete in between: a move that changes a
    hold slides its hands from one spot to the next, so the four are where a
    picture <em>settles</em>, not a set of places it jumps between.</p>
  </div>

  <div class="plate">
    <h3>And the hold says which way round<span class="tag">a rule</span></h3>
    <p>The line no longer takes whichever way is shorter when the hold has
    something to say about it. <b>Both wraps come round the front</b>, to the
    front of the other hand; <b>both locks go round the back</b> — the low one
    to the back of the other hand, the high one to the back of its own.</p>
    <div class="row">
      <figure>{route_wrap}<figcaption><em>low</em> wrap<br>— round the front</figcaption></figure>
      <figure>{route_low}<figcaption><em>low</em> lock<br>— round the back</figcaption></figure>
      <figure>{route_high}<figcaption><em>high</em> lock""" &
        """<br>— round the back, its own side</figcaption></figure>
    </div>
  </div>

  <div class="plate pick">
    <h3>A wrap that does not wrap is not a wrap<span class="tag">the
    consequence</span></h3>
    <p><b>A lock or a wrap may only be used where the line goes round no less
    than just under half the circumference.</b> It does not mean anything to
    have a wrap without the line actually going round the body — and once that
    is a rule, most of these states stop existing most of the time. Measured,
    the arc a line hugs comes out quantised: 0°, 51°, 90°, 141°, 180°, so "just
    under a half" picks out the full half and nothing else.</p>
    <p>Which leaves this. Every cell the rule allows, drawn; every one it
    forbids, empty — an edge that is not drawn, the same convention the turn
    sign uses for a turn that cannot be danced.</p>
    {grid}
    <p><b>Face to face, neither wrap exists and both locks do</b>; turn the
    follow away and it is the other way about. So whether a hold can be locked
    or wrapped at all is a property of the orientation, not a free choice — and
    the build refuses to draw the states that fall short rather than showing a
    wrap with no wrap in it.</p>
  </div>

  <div class="plate">
    <h3><em>Above</em> has no lock and no wrap</h3>
    <p>A physical restriction rather than a drawing one: an arm over the head
    has nowhere to be carried to. So an <em>above</em> hold keeps its hands
    where the arm hangs, and asking it for a wrap changes nothing — the two
    below are the same picture. From <em>above</em> the only transitions are to
    an <b>upper wrap</b> or back to <b>default</b>.</p>
    <div class="row">
      <figure>{above_plain}<figcaption><em>above</em></figcaption></figure>
      <figure>{above_asked}<figcaption><em>above</em>, wrap asked for""" &
        """<br>— the same picture</figcaption></figure>
    </div>
    <p><em>Upper wrap</em> is read here as the high wrap; that reading is mine
    and not yours, and it is the one thing in this plate to check.</p>
  </div>

  <div class="note">
    <p><b>And in a moving picture, at every instant — not just at the frames.</b>
    A browser draws the states between two sampled frames by blending them
    point by point, so two neighbouring frames that disagree about which side
    of a body the line goes round are drawn, in between, as a line sweeping
    <em>through</em> that body. Which is what was happening: measured, the
    worst of it reached <b>19.9</b> units into a body of radius <b>20</b> — the
    line passed through the centre. The routes at each frame were all clean,
    which is why a check that looked only at those said nothing was wrong.</p>
    <p>The fix is to settle the way round <em>once for a whole move</em>,
    before any of it is routed, so no two frames can disagree. That is
    stronger than the counter-rotation preference it replaces, and the
    preference, its bias constant and the frame-to-frame hysteresis all came
    out with it. The check now samples the blend between every pair of frames,
    with the bodies interpolated too, and the worst incursion anywhere is
    <b>0.14</b> — under a fifth of a unit, well under a drawn pixel.</p>
  </div>

  <div class="plate">
    <h3>An orbit, in two stages</h3>
    <p><b>Stage one</b>: the follow walks the ring round the lead, who stands
    still — so the pair's axis tilts away from upright, which the old picture
    could not show at all. <b>Stage two</b>: the whole drawing is brought back
    until the <em>lead faces up</em> again. The follow does not have to come
    back overhead; where they have got to is part of what the picture says.</p>
    <p><b>An orbit faces the centre.</b> Whatever side of the walker faced
    their partner goes on facing them, so the follow turns as far as they
    travel — watch their chevron come round with the ring:</p>
    <div class="row mid">
      <figure>{walk_orbit_0}<figcaption>rest</figcaption></figure>
      <figure>{walk_orbit_1}<figcaption>stage one —<br>walking round</figcaption></figure>
      <figure>{walk_orbit_2}<figcaption>a quarter round</figcaption></figure>
      <figure>{walk_orbit_3}<figcaption>stage two —<br>the world comes back</figcaption></figure>
      <figure>{walk_orbit_4}<figcaption>home</figcaption></figure>
    </div>
    <p>And here the follow keeps their own bearing all the way round
    instead, arriving facing the way they set off. That is <b>two turns
    danced at once</b> — the orbit with a counter-turn in it — and it is
    worth naming as the compound it is, because it lands somewhere else
    entirely:</p>
    <div class="row mid">
      <figure>{walk_compound_0}<figcaption>rest</figcaption></figure>
      <figure>{walk_compound_1}<figcaption>stage one</figcaption></figure>
      <figure>{walk_compound_2}<figcaption>a quarter round</figcaption></figure>
      <figure>{walk_compound_3}<figcaption>stage two</figcaption></figure>
      <figure>{walk_compound_4}<figcaption>home</figcaption></figure>
    </div>
  </div>

  <div class="plate pick">
    <h3>What that shows<span class="tag">the point</span></h3>
    <p>Once stage two has run, the picture holds two numbers and nothing else,
    both measured against the lead: <em>where</em> the follow is round from
    them, and <em>how</em> the follow faces. Every rotation moves those two —
    and two different things collapse onto one picture, which is worth keeping
    apart.</p>
    <p><b>The compound by either dancer lands in the same place.</b> The
    follow walking a quarter round the lead keeping their own bearing, and the
    lead walking a quarter round the follow keeping theirs, arrive at exactly
    the same picture: only the pair's axis has swung, and both bearings are
    where they started. So <b>the drawing cannot say who walked</b> — only the
    path can.</p>
    <div class="row">
      <figure>{collapse_follow_walked}<figcaption>the follow walked""" &
        """<br>keeping their bearing</figcaption></figure>
      <figure>{collapse_lead_walked}<figcaption>the lead walked""" &
        """<br>keeping their bearing</figcaption></figure>
    </div>
    <p><b>And an orbit lands where an axis turn lands.</b> A follow who walks
    a quarter round the lead <em>keeping their side to the centre</em> arrives
    at exactly the state the lead reaches by turning a quarter on the spot.
    Not similar: the same drawing, mark for mark.</p>
    <div class="row">
      <figure>{collapse_orbit}<figcaption>the follow orbited""" &
        """<br>a quarter round</figcaption></figure>
      <figure>{collapse_axis}<figcaption>the lead turned""" &
        """<br>a quarter on the spot</figcaption></figure>
    </div>
    <p>Checked rather than claimed — the generator asserts each pair is one
    drawing, mark for mark, and refuses to build if it is not. It also asserts
    that the <em>compound</em> does <b>not</b> land on the axis turn, so the
    two really are two moves.</p>
    <p><b>So axis against orbit is a property of the move and not of the
    state</b>, exactly as this page first said. A position cannot tell an
    orbit from the other dancer's axis turn — they land in the same place —
    and it cannot tell who did the walking either. The node never needs to
    know; only the edge does. Which is why the two stages are worth animating:
    the difference is a path, and only a path can show it. It also settles the
    turn sign's dash on the other page — the dash is describing an edge, and
    the sign labels edges, so it survives.</p>
    <p><b>This page has been corrected twice, and is back where it began.</b>
    Rule 20 once made an orbit keep its bearing, which put the collapse on the
    compound instead; rule 32 reverses it, because an orbiter who keeps their
    bearing never turns relative to their partner and so half a turn of it
    winds nothing — and then the halves cannot be equated across the ways of
    turning.</p>
  </div>

  <div class="plate">
    <h3>Moving<span class="tag">it runs here</span></h3>
    <p>Four moves, each a full cycle: go, come home, go back, come home — so it
    returns to exactly where it started rather than snapping. Watch what the new
    rule does to the first one: <b>a lead turning on the spot now has plenty to
    bring home</b>, because their facing has to come back up — so stage two
    swings the follow round them. It is the <em>follow</em> turning that would
    have nothing to do in stage two. Both dancers going round each other comes
    home to the picture it left, though on the floor they have travelled.</p>
    <div class="row">
      <figure>{mv_lead_axis}{mv_lead_axis_still}<figcaption>the lead turns""" &
        """<br>on their own axis</figcaption></figure>
      <figure>{mv_follow_orbits_the_lead}{mv_follow_orbits_the_lead_still}""" &
        """<figcaption>the follow orbits<br>the lead</figcaption></figure>
      <figure>{mv_the_lead_orbits_the_follow}{mv_the_lead_orbits_the_follow_still}""" &
        """<figcaption>the lead orbits<br>the follow</figcaption></figure>
      <figure>{mv_both_round_each_other}{mv_both_round_each_other_still}""" &
        """<figcaption>both, round each other<br>— a picture no-op</figcaption></figure>
    </div>
  </div>

  <div class="plate">
    <h3>What the pair of colours at the two ends says</h3>
    <p>The line is now the pair itself: it starts in the lead's hand's ink and
    ends in the follow's, so it <em>draws</em> <b>which named hands are
    joined</b> rather than leaving it to two marks. <em>Left to left</em> is
    blue all the way, <em>Left to right</em> runs blue into orange, whoever
    faces where — and whether it crosses says whether the hold is crossed now.
    The deep half is always the lead's, so the reading survives a hold turned
    round, and survives both hands sharing a hue.</p>
    <div class="row">
      <figure>{pair_ll}<figcaption><b>Left to left</b>""" &
        """<br>blue to blue · crossed</figcaption></figure>
      <figure>{pair_ll_turned}<figcaption>follow turned""" &
        """<br>still blue to blue · not crossed</figcaption></figure>
      <figure>{pair_lr}<figcaption><b>Left to right</b>""" &
        """<br>blue to orange · not crossed</figcaption></figure>
      <figure>{pair_lr_turned}<figcaption>follow turned""" &
        """<br>still blue to orange · crossed</figcaption></figure>
    </div>
  </div>

  <div class="plate">
    <h3>A free hand keeps its hue</h3>
    <p>Grey said <em>not held</em>, but colour carries orientation and the
    <code>free</code> frame is four free hands — which is where its name comes
    from. So a free hand fades rather than greying, and there is no line to
    cover the case grey would have broken.</p>
    <div class="row">
      <figure>{free_fade}<figcaption>faded</figcaption></figure>
      <figure>{free_grey}<figcaption>grey</figcaption></figure>
      <figure>{free_fade_tiny}<figcaption>faded · node size</figcaption></figure>
      <figure>{free_grey_tiny}<figcaption>grey · node size</figcaption></figure>
    </div>
  </div>

  <div class="note">
    <p><b>The couple rotation is a picture no-op, and that is correct.</b> Both
    dancers going round each other changes nothing the drawing holds — which is
    exactly what the model says: a rotation of the whole couple stores no twist.
    It is still a real thing on the floor, and the picture is honest about not
    tracking it: what it draws is the couple, not the room.</p>
    <p><b>Two dancers turning half a turn each still collides.</b> The four
    orientations are two bits and <code>twist</code> is one, its parity, so
    <code>isFacing(twist)</code> cannot tell face to face from back to back. The
    two relative facings this picture is now built on are exactly the pair
    <code>rotation.nim</code> would need.</p>
    <p><b>Knock-on, flagged not acted on.</b> Static frames keep a square
    <code>120 × 120</code> box; the moving ones are given a box fitted to
    everything they touch, which is why they are not all the same size — they
    are all at the same scale instead. <code>frameHeight</code>, the matrix
    cells and the map nodes still assume the old <code>100 × 116</code>.</p>
  </div>
</section>

<div class="foot">
  <p><b>Still not in the app.</b> The rotation views came off the page on purpose
  and go back when the marks are settled and the ontology is finished. The frame
  pictures are unchanged either way — the break stays, and the hand-to-hand half
  leaves its levels unsaid.</p>
  <p>Yours to settle on this page: whether <b>upper wrap</b> means the high
  wrap, which is the one reading in the rules that is mine rather than yours;
  <code>SLOT_OFFSET</code>, how far round the rim <em>front</em> and
  <em>back</em> sit, which is a drawn convention and nothing the dance says;
  the bow for contact with the body; what an orbit stores; and when an arm
  above the head blocks.</p>
</div>

</div>
"""


func render*(P: Parts): string =
  ## Lay frame page out around given figures.
  var settlings: string
  for k, s in SETTLINGS:
    settlings.add fig(P[&"settle_{k}"], s.caption)

  # Which locks and wraps exist in which orientation: cells left empty
  # by wrap rule are states that cannot be danced.
  let turned = ["face to face", "the follow<br>a quarter turned",
                "the follow<br>turned away", "the follow<br>three quarters"]
  var grid = """<table class="grid"><tr><th></th>"""
  for s in GRID_STATES:
    grid.add &"<th><em>{word(s.level)}</em> {word(s.way)}</th>"
  grid.add "</tr>"
  for i, turn in GRID_TURNS:
    grid.add &"<tr><th>{turned[i]}</th>"
    for s in GRID_STATES:
      let cell = P[&"grid_{word(s.level)}_{word(s.way)}_{int(turn)}"]
      grid.add "<td>" & (if cell.len > 0: cell else: "&mdash;") & "</td>"
    grid.add "</tr>"
  grid.add "</table>"

  var fills = @[
    ("sw_free", swatch(Swatch.Free)), ("sw_none", swatch(Swatch.Unsaid)),
    ("sw_low", swatch(Swatch.Low)), ("sw_high", swatch(Swatch.High)),
    ("sw_above", swatch(Swatch.Above)),
    ("settlings", settlings), ("grid", grid),
  ]
  # Turning figures swap in `moving` class so reduced motion can swap
  # them out; their stills ride along under their own markers.
  for m in ["lead_axis", "follow_orbits_the_lead",
            "the_lead_orbits_the_follow", "both_round_each_other"]:
    fills.add (&"mv_{m}", P[&"mv_{m}"].replaceFirst(
      "class=\"mv\"", "class=\"mv moving\""))
    fills.add (&"mv_{m}_still", P[&"mv_{m}_still"])
  for key in ["f_none", "f_low", "f_high", "f_above", "f_over",
              "or_free_0", "or_free_1", "or_free_2", "or_free_3",
              "or_held_0", "or_tiny_1", "slot_chart",
              "route_wrap", "route_low", "route_high",
              "above_plain", "above_asked",
              "walk_orbit_0", "walk_orbit_1", "walk_orbit_2",
              "walk_orbit_3", "walk_orbit_4",
              "walk_compound_0", "walk_compound_1", "walk_compound_2",
              "walk_compound_3", "walk_compound_4",
              "collapse_follow_walked", "collapse_lead_walked",
              "collapse_orbit", "collapse_axis",
              "pair_ll", "pair_ll_turned", "pair_lr", "pair_lr_turned",
              "free_fade", "free_grey", "free_fade_tiny", "free_grey_tiny"]:
    fills.add (key, P[key])
  document(TITLE, BODY.filled(fills))
