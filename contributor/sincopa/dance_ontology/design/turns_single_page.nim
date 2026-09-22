## Lay out single-hand turns page: every position, every transition.
##
##   First of one mock-up per kind of turn (rule 15).  Held above,
##     single hand turns for ever (rules 16 and 17), so this page has no
##     refusals in it: what it holds is four quarter-turn orientations
##     of each of app's four single-hand frames, under each of four
##     manners of turn (rule 19), and animation of every edge between
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


const TITLE* = "Single-Hand Turns, So Far"
  ## What page calls itself, in its tab and at its head.


const QUARTER_NAMES = ["none", "&#188;", "&#189;", "&#190;"]
  ## How far round from app's own frame, in quarters.


func plates(P: Parts; manner: Manner): string =
  ## Lay out one manner of turn: one plate per connection, positions then
  ## edges.
  let tag = MANNERS[manner].tag
  for c, single in SINGLES:
    result.add &"""<div class="plate"><h3>{single.name}</h3>"""
    result.add """<p>Every position this manner reaches, a quarter turn """ &
      """apart. The fourth quarter comes back to the first, so the round """ &
      """closes and nothing is refused.</p>"""
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
    result.add """<p>And every transition between them. Each one rocks """ &
      """between its two positions, so the turn reads both ways:</p>"""
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
  <p class="standfirst">One kind of turn, on its own. The held arm is carried <b>above</b>, over
  the head, on the axis the couple turn about. A wrap or a lock is made at <em>high</em> or
  <em>low</em>, and above is the one level that has neither. From there a single-hand connection
  turns for ever either way, so nothing is refused and the round closes.</p>
  <p
  class="standfirst"><b>How far it has wound is then no part of the state.</b> A turn that never
  ends has no wound out end to stand at. What is
  left is where the pair points, which is four quarter turn orientations for each of
  the four single-hand frames of the app.</p>
  <p class="sibling"><b>Hand to hand and the crossed pair come next</b>, each on its own page.
  They go together once each one is right.</p>
</header>

<section>
  <div class="head"><span class="n">What is here</span><h2>Four manners of
  turn, and two sets of places they reach</h2></div>
  <p><b>A position is a frame and a quarter.</b> A turn does not change which hands are held, so
  it does not change the frame. It changes where the pair points. The first cell of every row is the
  frame as the app draws it. Each step is a quarter turn, and the fourth brings the round back to
  the first.</p>
  <p><b>There are four manners of turn, and not two.</b> Either dancer turns on their own axis,
  and either orbits the other, so all four are drawn. <b>A dashed ring says an orbit</b>, centred
  on whoever stands still. It is the dash the frame picture uses, and nothing else here is
  dashed.</p>
  <p><b>An orbit faces the centre.</b> Whichever side of the walker faced their partner goes on
  facing them. So the walker turns as far as they travel, and their chevron comes round with the
  ring. A walker who keeps their own bearing dances an orbit and a counter-turn at once. That is
  the <em>compound</em>, which is another move, and these sections do not draw it.</p>
  <p><b>That is what makes the manners comparable.</b> A walker who keeps their bearing never
  turns relative to their partner, so half a turn of that orbit is half a turn of nothing. An
  orbit that faces the centre turns the pair as far as an axis turn does. It lands on the very
  pictures that the axis turn of the <em>other</em> dancer reaches.</p>
  <p><b>The lead is the still point.</b> Every picture is framed on the lead. They stand on one
  spot in every cell of a row, facing up, and the follow goes round them. That takes the second
  stage out of three of the four manners. An orbit by the follow moves the lead not at all, so
  nothing comes back and the figure is the walk.</p>
  <p><b>Where a second stage remains, the figure is danced in two.</b> <b>Stage one</b> is the
  turn itself, seen from where the room stands, so the picture leans off upright or slides off
  centre with the dancers. <b>Stage two</b> brings it back, with the lead facing up and on their
  own spot. An axis turn by the lead swings the follow around them. An orbit by the lead is the one
  move that carries the lead off their spot. Its second stage undoes the travel and the turn that
  came with it.</p>
  <p><b>The two stages do not share the clock.</b> The turn is what the figure shows, and the
  second stage is the picture as it catches up. So the second stage ranks below the turn three
  ways. It runs in well under half the time the turn takes. A beat is held on the landing of the
  turn, so the two never blur into one long motion. It starts and stops softly, because an abrupt
  start is the one thing that would pull the eye back to it.</p>
  <p><b>A settled reach bends round what it does not hold.</b> A line laid across a hand cell says
  that hand is in the hold. A line laid across a chevron hides which way its dancer faces. So the
  connection of a still figure is a band pulled taut past every mark it does not
  join. It bends round each mark and runs straight everywhere else.</p>
  <p>The clearance is
  measured off what is drawn: the corner of a square, the edge of a circle, and the two strokes of
  a chevron.
  Every build asserts it.</p>
  <p><b>A reach takes the plainest way past a mark, and not the shortest.</b> The shortest way
  weaves, with one mark passed on the left and the next on the right. Every change of direction is a
  turn the reader must follow. So a bend costs line, and the way round that bends
  once wins wherever it costs no more. Here that is every bending reach on the page, and usually
  the shorter line as well.</p>
   <p><b>A reach bends rather than breaks.</b> One gentle curve runs from hand
  to hand, and nothing on the page changes direction by more than a few degrees. <b>A moving
  connection stays straight</b>, because a smooth pass across a mark is what a turn does. A bend
  that came and went mid-turn would be a mark of its own.</p>
  <p><b>Two rounds, and not four.</b> Every build measures this: <b>one axis turn and the orbit
  of the other dancer reach each round</b>. The follow in orbit of the lead arrives at the pictures
  that the axis turn of the lead reaches. The lead in orbit of the follow arrives at those of the
  follow. Rule 32 does that, because an orbit that faces the centre turns the pair as far
  as it carries the walker. The drawing cannot say which of the two was danced, and only the path
  can, which is why all four are here.</p>
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
  <p><b>What the two rounds cost.</b> Where two manners reach one round, a position cannot say
  which of them was danced, and only the edge can. That holds for every manner in pairs, so the
  state graph under these four sections holds <b>two rounds</b> rather than four. Whether the
  page should lead with the two rounds, and put the four manners under them, is yours to call.</p>
  <p><b>An orbit lands where an axis turn lands.</b> So no position tells an orbit from the axis
  turn of the other dancer, and the difference belongs to the move. The compound lands somewhere
  of its own, and it is an orbit walked while the walker turns the other way. The frame page says
  the same.</p>
  <p><b>What is not drawn:</b> anything that runs out. No refusal appears here, because above has
  no ceiling. Ceilings and refusals come back with the first level that locks or wraps.</p>
</div>

<div class="foot">
  <p><b>Not in the app yet.</b> The app keeps drawing the eight frames and nothing else until the
  marks are settled.</p>
  <p>Yours to settle on this page:</p>
  <ul>
    <li>whether the two rounds should lead the page rather than the four manners;</li>
    <li>whether a quarter is the right grain, or whether an eighth is danced;</li>
    <li>what mark, if any, the edges should carry: the turn sign was built for this job, and
    these are the first edges it could label.</li>
  </ul>
</div>

</div>
"""


func render*(P: Parts): string =
  ## Lay single-hand turns page out around given figures.
  var fills: seq[tuple[marker, value: string]]
  for manner in Manner:
    let w = MANNERS[manner]
    fills.add (&"{w.tag}_title", w.title)
    fills.add (&"{w.tag}_blurb", w.blurb)
    fills.add (&"{w.tag}_plates", plates(P, manner))
  document(TITLE, BODY.filled(fills))
