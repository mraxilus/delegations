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


const TITLE* = "The Frame, So Far"
  ## What page calls itself, in its tab and at its head.


const BODY = """

<div class="sheet">

<header class="top">
  <p class="kicker">Dance ontology · rotation · the frame</p>
  <h1>The frame, so far</h1>
  <p class="standfirst">Each dancer is a plain circle, with a small chevron at its centre for
  the facing. A connection runs hand to hand as a taut string, in the colours of its own two hands.
  It goes round a body and never through one.</p>
  <p class="standfirst">A settled hand stands in one
  of six places. The level of
  the hold, and its lock or wrap, decide which place. The hold also says which way
  round the line goes: a wrap comes round the front, and a lock goes round the back. A lock or a
  wrap exists only where the line truly goes round a body. That rules out most of these states in
  most orientations.</p>
  <p class="standfirst">A move runs in two stages. First the dancers travel. Then the whole
  drawing turns back until the lead faces up again. That second stage is why an orbit lands where
  the other dancer's axis turn lands. An orbit walked on the walker's own bearing lands somewhere
  else. Only an <em>above</em> connection may pass over a body, and that holds at every instant of
  a moving picture.</p>
  <p class="sibling"><b>The turn sign is on its own page.</b> It answers another question, which
  is how to label an edge. The two pages meet at the levels and the arm inks, which they
  share.</p>
</header>

<section>
  <div class="head"><span class="n">Settled</span><h2>Level, and whose hand it
  is</h2></div>
  <p>The fill of a hand says its level, and the break in the arm that goes under says it again. A
    break still reads where the mark is small, and a fill does not. Each hand carries the colour
    of its own side, in the shade of its owner. The squares of the lead are deep, and the circles
    of the follow are plain. So the swatches come in pairs, and one pair is a whole hold.</p>
  <div class="plate">
    <div class="key">
      {sw_free}
      <span><b>faded</b>: nobody holds this hand</span>
      {sw_none}
      <span><b>full, hollow</b>: held, with no level said</span>
      {sw_low}
      <span><b>solid</b>: low, below the shoulder</span>
      {sw_high}
      <span><b>dot</b>: high, above the shoulder</span>
      {sw_above}
      <span><b>hatched</b>: above, over the head</span>
    </div>
    <div class="row">
      <figure>{f_none}<figcaption>held<br><b>no level</b></figcaption></figure>
      <figure>{f_low}<figcaption><b>low</b></figcaption></figure>
      <figure>{f_high}<figcaption><b>high</b></figcaption></figure>
      <figure>{f_above}<figcaption><b>above</b></figcaption></figure>
      <figure>{f_over}<figcaption>Left <b>high</b>, Right <b>low</b>
        <br>and the break says it too</figcaption></figure>
    </div>
  </div>
</section>

<section>
  <div class="head"><span class="n">One</span><h2>Circles, and a line that
  wraps</h2></div>
  <p><b>A body is a plain circle, and the chevron at its centre is the facing.</b> The rim says
  no more than that a body is here. It is one line of one width, and it breaks around every hand
  mark, so no line runs through a mark. The wrap on the connection is the only sign that an arm
  has wound.</p>
  <p><b>A connection goes round a body, and it takes the shorter way where the hold says
  nothing.</b> It starts
  on the edge of the hand's own mark rather than at its centre. Where the straight way to the
  partner would pass through a body, the reach runs along the rim instead. It leaves at the
  first tangent, runs straight, and follows the other rim to the other hand. That arc round the
  rim is what a wrap and a lock are drawn from.</p>
  <p><b>Every frame of a move goes the same way round.</b> The build settles which side of each
    body the line passes before it draws the first frame, and every frame of that move keeps it.
    It picks the shortest way that works for every frame of that move. The note below says what
    that guards against.</p>
  <p><b>The line carries the colours of its own two hands.</b> Each half carries the colour of the
    hand it ends on. The half of the lead carries the ink of that arm in the deep shade, and the
    half of the follow carries the plain one. So <em>Left to right</em> is drawn blue into orange
    along its whole length. The shade says which end is the lead's where both hands share a
    hue.</p>
  <p><b>The lead always faces up.</b> The second stage of a move stands the lead upright, and
  not the pair. Everything is read from the lead, so the lead holds still, and where the follow
  stands becomes part of what the picture says.</p>
  <p>An orbit goes round the other dancer, so a dashed ring appears only while an orbit runs. The
  ring is centred on whoever stands still: the lead, the follow, or the midpoint where both
  travel. Nothing else in the picture is dashed.</p>

  <div class="plate">
    <h3>At rest, no ring</h3>
    <p>The facing of a dancer decides which column their hand sits in. So a row read across holds
    one orientation, and the four facings stay distinct with no new mark.</p>
    <div class="row">
      <figure>{or_free_0}<figcaption>face-to-face</figcaption></figure>
      <figure>{or_free_1}<figcaption>pillion<br>lead</figcaption></figure>
      <figure>{or_free_2}<figcaption>pillion<br>follow</figcaption></figure>
      <figure>{or_free_3}<figcaption>back-to-back</figcaption></figure>
    </div>
    <div class="row">
      <figure>{or_held_0}<figcaption>holding <em>Left to left</em></figcaption></figure>
      <figure>{or_tiny_1}<figcaption>node size</figcaption></figure>
    </div>
  </div>

  <div class="plate">
    <h3>A settled hand is in one of six places</h3>
    <p><b>This chart asks the sim nothing, and it solves nothing.</b> A hand at rest sits where
      the arm hangs. It may also sit round toward the front of that dancer, or round toward their
      back. That gives three places on each side of the body. The hand's own side, the level of
      the hold, and its lock or wrap decide which place it takes.</p>
    <p>Each place is measured from the way that dancer faces, and never from the page. That is
    what <em>front</em> and <em>back</em> name. The chart is drawn on a body turned off the
    vertical, so you can see that rather than take it on trust.</p>
    <div class="row mid">
      <figure>{slot_chart}<figcaption>the six, on a turned body
        <br>the four a Left hand uses, in its ink</figcaption></figure>
      <figure><table class="slots">
        <tr><th></th><th>Left hand</th><th>Right hand</th><th>the line goes</th></tr>
        <tr><td>no level, or no way said</td><td>left · side</td><td>right · side</td>
        <td>the short way</td></tr>
        <tr><td><em>high</em> wrap</td><td>right · front</td><td>left · front</td>
        <td>round the front</td></tr>
        <tr><td><em>low</em> wrap</td><td>right · front</td><td>left · front</td>
        <td>round the front</td></tr>
        <tr><td><em>low</em> lock</td><td>right · back</td><td>left · back</td>
        <td>round the back</td></tr>
        <tr><td><em>high</em> lock</td><td>left · back</td><td>right · back</td>
        <td>round the back</td></tr>
        <tr><td><em>above</em></td><td>left · side</td><td>right · side</td>
        <td>straight over</td></tr>
      </table></figure>
    </div>
    <p><b>A hold must carry its lock or wrap</b>, because the place cannot be chosen without it. A
      hold that names a level, and not which of the two it is, leaves its hands where the arm
      hangs. The height does not say which side the hand went to, so the picture does not
      guess.</p>
    <p><b>Where a hand has gone, the place it left is drawn as a grey outline.</b> So a picture
    says where the hand is and where it came from. The two wraps share one place, and the fill
    tells them apart.</p>
    <p>Each of these is drawn in an orientation that allows it. The plate after next says which
    orientation allows what.</p>
    <div class="row">{settlings}</div>
    <p>The six places are discrete at rest, and not in between. A move that changes a hold slides
    its hands from one place to the next, so these are where a picture settles.</p>
  </div>

  <div class="plate">
    <h3>And the hold says which way round<span class="tag">a rule</span></h3>
    <p>Where the hold says which way round, the line no longer takes the shorter way. <b>Both
    wraps come round the front</b>, to the front of the other hand. <b>Both locks go round the
    back.</b> The low lock goes to the back of the other hand, and the high lock to the back of its
    own.</p>
    <div class="row">
      <figure>{route_wrap}<figcaption><em>low</em> wrap<br>round the front</figcaption></figure>
      <figure>{route_low}<figcaption><em>low</em> lock<br>round the back</figcaption></figure>
      <figure>{route_high}<figcaption><em>high</em> lock
        <br>round the back, its own side</figcaption></figure>
    </div>
  </div>

  <div class="plate pick">
    <h3>A wrap that does not wrap is not a wrap<span class="tag">the
    consequence</span></h3>
    <p><b>A lock or a wrap holds only where the line hugs almost half the rim or more.</b> A wrap
    with no arm round a body means nothing. Once that is a rule, most of these states no longer
    exist in most orientations. Measured, the arc a line hugs takes one of five values: 0, 51, 90,
    141 and 180 degrees. A bound just under a half therefore picks out 180 degrees alone.</p>
    <p>This is what the rule leaves. Every cell it allows is drawn, and every cell it forbids is
    empty.</p>
    {grid}
    <p><b>Face to face, neither wrap exists and both locks do.</b> Turn the follow away and it is
    the other way about. So the orientation decides whether a hold can be locked or wrapped at
    all, and the build refuses to draw a state that falls short.</p>
  </div>

  <div class="plate">
    <h3><em>Above</em> has no lock and no wrap</h3>
    <p>The body stops this, and not the drawing: an arm over the head has nowhere to go. So an
      <em>above</em> hold keeps its hands where the arm hangs, and a wrap asked of it changes
      nothing. The two figures below are one picture. From <em>above</em> the only moves are to an
      <b>upper wrap</b>, or back to where the arm hangs.</p>
    <div class="row">
      <figure>{above_plain}<figcaption><em>above</em></figcaption></figure>
      <figure>{above_asked}<figcaption><em>above</em>, wrap asked for
        <br>the same picture</figcaption></figure>
    </div>
    <p>This page reads <em>upper wrap</em> as the high wrap. That reading is the model's rather
    than the Architect's, and it is the one thing in this plate to check.</p>
  </div>

  <div class="note">
    <p><b>A moving picture keeps the line out of a body at every instant, and not only at the
    frames it is sampled at.</b> A browser draws the states between two sampled frames point by
    point. So two frames that disagree about which side of a body the line passes are drawn, in
    between, as a line through that body. The build settles the way round once for a
    whole move, before it routes any frame, so no two frames can disagree.</p>
    <p>The check samples the blend between every pair of frames, with the bodies interpolated
    too. The worst reach into a body anywhere is 0.14 of a unit, which is well under a drawn
    pixel.</p>
  </div>

  <div class="plate">
    <h3>An orbit, in two stages</h3>
    <p><b>Stage one.</b> The follow walks the ring round the lead, who stands still, so the axis
    of the pair tilts away from upright. <b>Stage two.</b> The whole drawing comes back until the
    lead faces up again. The follow need not come back overhead, and where they stand is part of
    what the picture says.</p>
    <p><b>An orbit faces the centre.</b> Whichever side of the walker faced their partner goes on
    facing them. So the follow turns as far as they travel. The chevron of the follow comes round
    with the ring.</p>
    <div class="row mid">
      <figure>{walk_orbit_0}<figcaption>rest</figcaption></figure>
      <figure>{walk_orbit_1}<figcaption>stage one,<br>the walk round</figcaption></figure>
      <figure>{walk_orbit_2}<figcaption>a quarter round</figcaption></figure>
      <figure>{walk_orbit_3}<figcaption>stage two,<br>the world comes back</figcaption></figure>
      <figure>{walk_orbit_4}<figcaption>home</figcaption></figure>
    </div>
    <p>Here the follow keeps their own bearing instead, and arrives facing the way they set off.
    That is two turns danced at once, which is the orbit with a counter-turn in it. It lands
    somewhere else, so it takes the name of the compound turn.</p>
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
    <p>Once stage two has run, the picture holds two numbers and nothing else, both measured
    against the lead. They are how far round the lead the follow stands, and which way the follow
    faces.
    Every rotation moves those two numbers, and two different moves land on one picture.</p>
    <p><b>The compound by either dancer lands in the same place.</b> The follow walks a quarter
    round the lead on their own bearing, and the lead walks a quarter round the follow on theirs.
    Both arrive at one picture: the axis of the pair has swung, and both bearings stand where
    they started. So <b>the drawing cannot say who walked</b>, and only the path says that.</p>
    <div class="row">
      <figure>{collapse_follow_walked}<figcaption>the follow walked
        <br>keeping their bearing</figcaption></figure>
      <figure>{collapse_lead_walked}<figcaption>the lead walked
        <br>keeping their bearing</figcaption></figure>
    </div>
    <p><b>An orbit lands where an axis turn lands.</b> A follow walks a quarter round the lead with
    their side to the centre. They arrive at the state the lead reaches by a quarter axis turn. It
    is the same drawing, mark for mark.</p>
    <div class="row">
      <figure>{collapse_orbit}<figcaption>the follow orbited
        <br>a quarter round</figcaption></figure>
      <figure>{collapse_axis}<figcaption>the lead turned
        <br>a quarter on the spot</figcaption></figure>
    </div>
    <p>The build checks this rather than claims it. It asserts that each pair is one drawing,
    mark for mark, and refuses to build where it is not. It asserts that the compound does not
    land on the axis turn, so the two are two moves.</p>
    <p><b>So an axis turn against an orbit is a property of the move, and not of the state.</b> A
    position cannot tell an orbit from the axis turn of the other dancer, because they land in one
    place. It cannot say who walked either. The node never needs to know, and only the edge
    does. That is why the two stages are worth an animation: the difference is a path and not a
    state.</p>
  </div>

  <div class="plate">
    <h3>In motion<span class="tag">it runs here</span></h3>
    <p>Four moves run here, each one a whole cycle: out, home, back, and home again. So each one
      comes back to where it started, and nothing jumps. A lead who turns on the spot leaves stage
      two much to do, because their facing must come back up. So stage two swings the follow round
      them. A follow who turns on the spot leaves stage two nothing to do. Where both dancers go
      round each other, the picture comes home to where it began, although on the floor they have
      travelled.</p>
    <div class="row">
      <figure>{mv_lead_axis}{mv_lead_axis_still}<figcaption>the lead turns
        <br>on their own axis</figcaption></figure>
      <figure>{mv_follow_orbits_the_lead}{mv_follow_orbits_the_lead_still}
        <figcaption>the follow orbits<br>the lead</figcaption></figure>
      <figure>{mv_the_lead_orbits_the_follow}{mv_the_lead_orbits_the_follow_still}
        <figcaption>the lead orbits<br>the follow</figcaption></figure>
      <figure>{mv_both_round_each_other}{mv_both_round_each_other_still}
        <figcaption>both, round each other<br>the picture holds still</figcaption></figure>
    </div>
  </div>

  <div class="plate">
    <h3>What the pair of colours at the two ends says</h3>
    <p>The line is the pair itself. It starts in the ink of the lead's hand and ends in the ink of
    the follow's, so it draws which named hands are joined. <em>Left to left</em> is blue all the
    way, and <em>Left to right</em> runs blue into orange, whoever faces where. Whether the line
    crosses says whether the hold is crossed. The deep half is always the lead's, so the reading
    holds when the hold turns round, and when two hands share a hue.</p>
    <div class="row">
      <figure>{pair_ll}<figcaption><b>Left to left</b>
        <br>blue to blue · crossed</figcaption></figure>
      <figure>{pair_ll_turned}<figcaption>follow turned
        <br>still blue to blue · not crossed</figcaption></figure>
      <figure>{pair_lr}<figcaption><b>Left to right</b>
        <br>blue to orange · not crossed</figcaption></figure>
      <figure>{pair_lr_turned}<figcaption>follow turned
        <br>still blue to orange · crossed</figcaption></figure>
    </div>
  </div>

  <div class="plate">
    <h3>A free hand keeps its hue</h3>
    <p>A free hand fades, and it keeps the colour of its own side. The colour carries the
    orientation, and the <code>free</code> frame is four free hands, which is where its name comes
    from. A free hand has no line on it, so the fade is the whole mark.</p>
    <div class="row">
      <figure>{free_fade}<figcaption>faded</figcaption></figure>
      <figure>{free_grey}<figcaption>grey</figcaption></figure>
      <figure>{free_fade_tiny}<figcaption>faded · node size</figcaption></figure>
      <figure>{free_grey_tiny}<figcaption>grey · node size</figcaption></figure>
    </div>
  </div>

  <div class="note">
    <p><b>Where both dancers go round each other, nothing in the picture moves, and that is
    correct.</b> The
    model stores no twist for a rotation of the whole couple. It is still a real thing on the
    floor, and the picture draws the couple rather than the room.</p>
    <p><b>Two dancers who each turn half a turn still collide.</b> The four orientations take two
    bits, and <code>twist</code> carries one of them, its parity. So the twist cannot tell
    face-to-face from back-to-back. So this picture stands on the two relative facings, which is
    what <code>rotation.nim</code> needs.</p>
    <p><b>Known and not mended.</b> A static frame keeps a square box of 120 by 120. A moving
    frame takes a box fitted to everything it touches, so the moving frames differ in size and
    stand at one scale instead. <code>frameHeight</code>, the cells of the matrix and the nodes of
    the map still assume the old box of 100 by 116.</p>
  </div>
</section>

<div class="foot">
  <p><b>Not in the app yet.</b> The rotation views come back to the app once the marks are settled
  and the ontology is finished. The frame pictures do not change either way: the break stays, and
  the hand-to-hand half leaves its levels unsaid.</p>
  <p>Yours to settle on this page:</p>
  <ul>
    <li>whether <b>upper wrap</b> means the high wrap, which is the one reading here that is the
    model's rather than yours;</li>
    <li><code>SLOT_OFFSET</code>, how far round the rim <em>front</em> and <em>back</em> sit,
    which is a drawn convention and nothing the dance says;</li>
    <li>the bow for contact with the body;</li>
    <li>what an orbit stores;</li>
    <li>when an arm over the head blocks.</li>
  </ul>
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
  let turned = ["face-to-face", "the follow<br>a quarter turned",
                "pillion lead", "the follow<br>three quarters"]
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
