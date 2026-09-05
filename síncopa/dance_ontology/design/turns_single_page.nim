## Lay out single-hand turns page: every position, every transition.
##
##   First of one mock-up per kind of turn (rule 15).  Held above,
##     single hand turns for ever (rules 16 and 17), so this page has no
##     refusals in it: what it holds is four quarter-turn orientations
##     of each of app's four single-hand frames, under each of four
##     ways of turning (rule 19), and animation of every edge between
##     them -- lead's in two stages rule 18 asks for.
##   Plates are generated rather than written out, because sixty-four
##     positions and sixty-four transitions are table, not argument.
##     Cost of generating them: prose cannot speak to one figure in
##       particular, only to whole set.  Accepted -- what is being shown
##       here is pattern, and pattern read cell by cell is not
##       read at all.

{.experimental: "strictFuncs".}

import std/[strformat, tables]

import ./[page, parts]


const TITLE* = "Single-hand turns, so far"
  ## What page calls itself, in its tab and at its head.


const QUARTER_NAMES = ["none", "&#188;", "&#189;", "&#190;"]
  ## How far round from app's own frame, in quarters.


func plates(P: Parts; way: TurnWay): string =
  ## Lay out one way of turning: one plate per connection, positions then
  ## edges.
  let tag = WAYS_OF_TURNING[way].tag
  for c, single in SINGLES:
    result.add &"""<div class="plate"><h3>{single.name}</h3>"""
    result.add """<p>Every position this way reaches, a quarter turn """ &
      """apart. The fourth quarter comes back to the first: the round """ &
      """closes, and nothing is ever refused.</p>"""
    result.add """<div class="row mid">"""
    for quarter in 0 ..< QUARTERS_ROUND:
      if quarter > 0:
        result.add P["g_quarter"]
      let caption =
        if quarter == 0: "<b>none</b><br>the app's frame"
        else: &"<b>{QUARTER_NAMES[quarter]}</b> turn"
      result.add fig(P[&"st_{tag}_{c}_{quarter}"], caption)
    result.add P["g_quarter"]
    result.add fig(P[&"st_{tag}_{c}_0"], "<b>none</b><br>round again")
    result.add "</div>"
    result.add """<p>And every transition between them, each rocking """ &
      """between its two positions so the turn reads both ways:</p>"""
    result.add """<div class="row mid">"""
    for quarter in 0 ..< QUARTERS_ROUND:
      let
        to = (quarter + 1) mod QUARTERS_ROUND
        moving = P[&"tr_{tag}_{c}_{quarter}_{to}"].replaceFirst(
          "class=\"mv\"", "class=\"mv moving\"")
        still = P[&"tr_{tag}_{c}_{quarter}_{to}_still"]
        caption = &"{QUARTER_NAMES[quarter]} &rarr; {QUARTER_NAMES[to]}"
      result.add &"<figure>{moving}{still}" &
        &"<figcaption>{caption}</figcaption></figure>"
    result.add "</div></div>"


const BODY = """

<div class="sheet">

<header class="top">
  <p class="kicker">Dance ontology · rotation · single-hand turns</p>
  <h1>Single-hand turns, so far</h1>
  <p class="standfirst">One kind of turn, on its own. The held arm is
  carried <b>above</b> — over the head, on the axis the couple turns about
  — because <em>high</em> and <em>low</em> are the levels a wrap or a lock
  is made at, and above is the one level that has neither. From there a
  single-hand connection turns <b>for ever</b> in either direction, so
  nothing is refused and the round closes. That has a consequence worth
  saying plainly: <b>how far it has wound is not part of the state</b>. If
  the turning never ends there is no wound-out end to be at, and what is
  left is <b>where the pair is pointing</b> — four quarter-turn
  orientations for each of the app's four single-hand frames.</p>
  <p class="sibling"><b>Hand to hand and the crossed pair come next</b>,
  each on its own page, and all of them go together once each is right.</p>
</header>

<section>
  <div class="head"><span class="n">What is here</span><h2>Four ways to
  turn, and two sets of places they reach</h2></div>
  <p><b>A position is a frame plus a quarter.</b> Turning does not change
  which hands are held, so it does not change the frame — it changes which
  way the pair is pointing. The first cell of every row is the frame
  exactly as the app draws it; each step is a quarter turn; the fourth
  brings the round back to the first.</p>
  <p><b>Four ways of turning, not two.</b> Either dancer can turn on their
  own axis, and either can orbit the other — so all four are drawn.
  <b>A dashed ring says an orbit</b>, centred on whoever is standing still;
  it is the same dash the frame picture uses, and nothing else on this page
  is dashed.</p>
  <p><b>An orbit faces the centre.</b> Whatever side of the walker faced
  their partner goes on facing them the whole way round, so the walker
  turns as far as they travel and their chevron comes round with the ring.
  A walker who kept their own bearing instead would be dancing an orbit and
  a counter-turn at once — the <em>compound</em>, which is a different move
  and is not what these sections draw.</p>
  <p><b>Which is what makes the ways comparable.</b> A bearing-keeping
  walker never turns relative to their partner, so a half turn of that
  orbit would not be half a turn of anything. Facing the centre, an orbit
  turns the pair exactly as far as an axis turn does — and lands on the
  very pictures the <em>other</em> dancer's axis turn reaches.</p>
  <p><b>The lead is the still point.</b> Every picture here is framed on
  them: they stand on the same spot in every cell of a row, facing up, and
  what you watch is the follow going round them. That is not only tidier —
  it takes the second stage out of three of the four ways of turning. A
  follow's orbit moves the lead not at all, so there is nothing to bring
  back and the animation is simply the walk.</p>
  <p><b>Where a second stage remains, it is danced in two.</b> <b>Stage
  one</b> is the turn itself, seen from where the room stands: the picture
  leans off upright, or slides off centre, with the dancers. <b>Stage
  two</b> brings it back — the lead facing up and on their own spot. A
  lead's axis turn swings the follow around them; a lead's orbit, the one
  move that carries the lead off their spot, has both to undo: the
  travelling and the turning that came with it.</p>
  <p><b>The two stages do not share the clock.</b> The turn is what the
  figure is <em>of</em>; the re-framing is the picture catching up with it,
  and is ranked below it three ways: it runs in well under half the time
  the turn takes, a beat is held on the turn's landing so the two never
  blur into one long motion, and it still starts and stops softly, since an
  abrupt start is the one thing that would pull your eye back to it.</p>
  <p><b>A settled reach bends round what it does not hold.</b> A line laid
  across a hand cell says that hand is in the hold, and a line laid across a
  chevron hides which way its dancer is facing — so a still figure's
  connection is a band pulled taut <em>past</em> every mark it does not join,
  bending locally round each and running straight everywhere else. The
  clearance is measured from what is actually drawn — a square's corner, a
  circle's edge, a chevron's two strokes — and asserted on every build.
  <b>It takes the plainest way past them, not merely the shortest</b>: the
  shortest way weaves, one mark passed on the left and the next on the
  right, and every change of direction is a turn a reader has to follow. So
  a bend is priced in line, and the way round that bends once is taken
  wherever it does not cost more than that — which here is every bending
  reach on the page, and usually the shorter line as well. <b>And it bends
  rather than breaks</b>: that single bend is one gentle curve from hand to
  hand, not a corner turned at a point, so nothing on the page changes
  direction by more than a few degrees anywhere along it.
  <b>A moving connection is exempt</b>, and stays straight: passing smoothly
  across a mark is what a turn does, and a bend that appeared and vanished
  mid-turn would be a mark of its own.</p>
  <p><b>Two rounds, not four.</b> Measured, and asserted on every build:
  <b>each round is reached by one axis turn and by the other dancer's
  orbit</b> — the follow orbiting the lead arrives at the pictures the
  lead's own axis turn reaches, and the lead orbiting the follow at the
  follow's. That is rule 32's doing: an orbit that faces the centre turns
  the pair as far as it carries the walker, so the two acts come to the
  same place by different routes. The drawing cannot say <em>which</em> was
  danced; only the path can, which is why all four are here.</p>
</section>

<section>
  <div class="head"><span class="n">One · axis</span><h2>{fa_title}</h2></div>
  <p>{fa_blurb}</p>
  {fa_plates}
</section>

<section>
  <div class="head"><span class="n">Two · axis</span><h2>{la_title}</h2></div>
  <p>{la_blurb}</p>
  {la_plates}
</section>

<section>
  <div class="head"><span class="n">Three · orbit</span><h2>{fo_title}</h2></div>
  <p>{fo_blurb}</p>
  {fo_plates}
</section>

<section>
  <div class="head"><span class="n">Four · orbit</span><h2>{lo_title}</h2></div>
  <p>{lo_blurb}</p>
  {lo_plates}
</section>

<div class="note">
  <p><b>What the collapse costs, and what it buys.</b> Where two ways reach
  one round, a position cannot say which of them was danced — only the edge
  can. That now holds for every way in pairs, so the state graph underneath
  these four sections has <b>two rounds</b> in it, not four. Whether the
  page should be reorganised to say that first — two rounds, four ways of
  walking them — is yours to call, and the case for it is stronger than it
  was.</p>
  <p><b>What it costs is the distinction the frame page once drew.</b> That
  page said axis against orbit was a property of the move rather than the
  state, and for a while this page said the opposite. Under rule 32 the
  frame page was right after all: an orbit lands exactly where the other
  dancer's axis turn lands, so no <em>position</em> tells them apart. What
  does land somewhere of its own is the compound — an orbit walked while
  turning the other way — and both pages now say so.</p>
  <p><b>What is not drawn:</b> anything that runs out. No refusal appears
  on this page because above has no ceiling; the moment a level that locks
  or wraps comes back into scope, ceilings and refusals come with it.</p>
</div>

<div class="foot">
  <p><b>Still not in the app.</b> Same standing as the other pages: the app
  keeps drawing the eight frames and nothing else until the marks are
  settled.</p>
  <p>Yours to settle on this page: whether the two rounds should lead the
  page rather than the four ways; whether a quarter is the right grain, or
  whether an eighth is danced; and what mark, if any, the edges themselves
  should carry — the turn sign was built for exactly this job and these are
  the first edges it could label.</p>
</div>

</div>
"""


func render*(P: Parts): string =
  ## Lay single-hand turns page out around given figures.
  var fills: seq[tuple[marker, value: string]]
  for way in TurnWay:
    let w = WAYS_OF_TURNING[way]
    fills.add (&"{w.tag}_title", w.title)
    fills.add (&"{w.tag}_blurb", w.blurb)
    fills.add (&"{w.tag}_plates", plates(P, way))
  document(TITLE, BODY.filled(fills))
