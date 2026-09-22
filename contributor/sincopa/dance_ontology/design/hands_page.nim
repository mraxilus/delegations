## Lay out hand-to-hand turns page: seven positions, half turn apart.
##
##   Second of one mock-up per kind of turn (rule 15), and dual of
##     first.  Single hand turns for ever, so its wind is not part of
##     its state and its orientation is all of it (rule 16); hold both hands
##     and whole turn puts every orientation back where it was, so
##     wind is all of it instead -- turn and half each way, by halves.
##   And same chain as crossed pair walks, read half turn along:
##     hold is unwound where its two connections run parallel, and that
##     falls at different facing for each of those two (rule 31).
##   What wound pair looks like is rule 27's: two crossovers, one by each
##     dancer, with diamond between them -- and rule 28 turned that from
##     drawn convention into measurement.  Reach is shadow that wound
##     arm casts from above, so crossings are what wind makes rather
##     than something page arranges: none at frame, one at half
##     turn, two at whole one, three at swan.
##     Cost of presenting chain as single-hand page's dual:
##       reader who has not met that page reads these captions cold.
##       Accepted -- both pages are one argument and are read together.

{.experimental: "strictFuncs".}

import std/[strformat, tables]

import ./[page, parts]


const TITLE* = "Hand-to-Hand Turns, So Far"
  ## What page calls itself, in its tab and at its head.


const WINDING: array[Manner, string] = [
  "The follow turns half a circle where they stand, and the pair winds " &
    "half a turn with them. Nobody travels, and nothing comes back " &
    "afterward, so this is the plainest of the four: one stage, and the " &
    "arms wind as it runs.",
  "The lead turns half a circle on the spot. A turn by the lead winds the " &
    "pair the opposite way to a turn by the follow. So to take the " &
    "<em>same</em> step of the chain, the lead turns the other way round. " &
    "<b>Stage one</b> is the turn with the room held still. <b>Stage " &
    "two</b> brings the picture back to the lead facing up. That swings " &
    "the follow round them, and leaves the wind where the turn put it.",
  "The follow walks half a circle round the lead, and the dashed ring says " &
    "who stands still. They keep <b>whichever side of them faced the lead " &
    "facing them</b>, so they turn as far as they travel (rule 32). That " &
    "winds the pair half a turn, which is the half turn an axis turn " &
    "winds. So it walks the chain, and it lands on the position that the " &
    "axis turn of the <em>lead</em> lands on.",
  "The lead walks the half circle instead, and faces the centre the same " &
    "way, so it winds the pair half a turn too. It is the one manner of " &
    "the four that takes the lead off their spot. Its second stage brings " &
    "back the travel and the turn together.",
] ## What each manner of turn does to pair, in this page's terms.
  ##   Not `MANNERS`'s own blurbs: those speak of single hand
  ##     coming round, and here orientation is exactly what returns.


func plates(P: Parts): string =
  ## Lay out four manners of turn, each walking every edge of chain.
  for manner in Manner:
    let w = MANNERS[manner]
    result.add &"""<div class="plate"><h3>{w.title}</h3>"""
    result.add &"<p>{WINDING[manner]}</p>"
    result.add """<p>Every edge of the chain. Each one rocks between its two
      ends, so the half turn reads both ways:</p>"""
    result.add """<div class="row mid">"""
    for i in 0 ..< CHAIN.len - 1:
      let
        moving = P[&"hw_{w.tag}_{i}"].replaceFirst(
          "class=\"mv\"", "class=\"mv moving\"")
        still = P[&"hw_{w.tag}_{i}_still"]
      # Every manner walks chain now, orbits included (rule 32), so every
      # cell says position it lands on.
      result.add &"<figure>{moving}{still}<figcaption>{CHAIN[i].name}" &
        &"<br>&rarr; <b>{CHAIN[i + 1].name}</b></figcaption></figure>"
    result.add "</div></div>"


const BODY = """

<div class="sheet">

<header class="top">
  <p class="kicker">Dance ontology · rotation · hand-to-hand turns</p>
  <h1>Hand-to-hand turns, so far</h1>
  <p class="standfirst">Both hands are held and uncrossed. The Left of the lead holds the right of
  the follow, and the Right of the lead holds the left. Both arms are carried <b>above</b>, as
  everything in this scope is.</p>
  <p class="standfirst"><b>This page is the single-hand page
  turned inside out.</b> One
  hand held above turns for ever, so the wind is no part of the state and where the pair points
  is all of it. Hold both hands and it is the other way about. A whole turn puts every facing and
  every place back where it was. So the pointing says nothing, and <b>the wind is the state</b>.
  That is a turn and a half each way, by halves, which is seven positions.</p>
  <p class="sibling"><b>The crossed pair comes next</b>, on its own page. It is this chain, read
  half a turn along, so what is left is to draw it.</p>
</header>

<section>
  <div class="head"><span class="n">What is here</span><h2>Seven positions,
  a half turn apart</h2></div>
  <p><b>The middle position is the frame of the app</b>, drawn as the app draws it. Its two
  connections run side by side and cross nothing. Each half turn from there winds the pair
  one step further, and the chain runs out at a turn and a half each way.</p>
  <p><b>The wind says which way the partners face</b>, so the captions leave it out and this page
  says it once. The partners are <b>face-to-face</b> at a whole number of turns, which is the
  frame and the diamonds. They are <b>pillion lead</b> at a half, which is the crosses and the
  swans.</p>
  <p><b>A half turn makes a cross.</b> The partners stand pillion lead, both faced one way with
  the lead behind, and the two connections cross once overhead. That is the plain crossing the
  app already draws for a crossed pair, and the break says which arm lies on top.</p>
  <p><b>A whole
  turn makes a diamond.</b> The pair crosses twice, once at the lead and once at the follow, and
  the two
  crossings enclose the shape that rule 27 named. <b>The two crossings say opposite things.</b>
  Whichever connection lies over at the end of the lead lies under at the end of the follow. That
  is what a wound pair is.</p>
  <p><b>A turn and a half makes a swan</b>, and there the pair stops being symmetric. Wound that
  far, the two arms cannot both go on swinging. One pulls taut and runs straight through the
  middle, and the other wraps it over and under and over, in two long loops. Those are the necks
  of two mating swans round a straight neck between them, which is the picture and the name. It
  crosses three times, and it is not two diamonds stacked, which rule 30 refused.</p>
  <p><b>Nothing here is imposed, and the wind is measured.</b> Each held hand sits on the rim of
  its own body, and both bodies stand on the axis of the pair. So the angle a hand makes with
  that axis is what round means, and the difference between the two ends is the wind.</p>
  <p>A
  reach is then the shadow of a wound arm from above. Its offset from the axis swings as far round
  as the
  pair has. It is straight at none, a cross at a half, and a diamond at a whole, and every
  frame between follows from the same measure. That is what stops a turn from snapping into its
  final shape.</p>
  <p><b>All four manners of turn wind, and by the same half turn.</b> Rule 32 does that. A walker in
  orbit keeps whichever side of them faced the centre facing it. So they turn as far as they travel,
  and the pair winds with them. A half turn is then a half turn however it is danced, and
  the four manners can be equated. <b>An orbit lands on the position that the axis turn of the
  other dancer lands on</b>, measured on every build.</p>
  <p><b>The names are preliminary, and yours.</b> <em>Left over Right</em> is the position where the
  Left connection of the lead passes over the Right at the crossover of the lead. <em>Right over
  Left</em> is its mirror. The cross, the diamond and the swan one step apart
  share a name, because they are one winding carried further.</p>
</section>

<section>
  <div class="head"><span class="n">One chain</span><h2>Both patterns, half
  a turn apart</h2></div>
  <p><b>Hand to hand and the crossed pair are one chain.</b> A hold has one position where its two
  connections run parallel and cross nothing. That position sits at a different facing for each of
  the two holds. Hand to hand runs parallel with the partners <b>face-to-face</b>. Hold left
  to left and right to right instead, and it runs parallel <b>pillion lead</b>, which is half a
  turn along this chain. Every step after that is the same step: cross, diamond and swan, out to
  a turn and a half each way.</p>
  <p><b>The build measures the phase rather than writes it down.</b> It turns the follow to each
  candidate and asks which one leaves the hold unwound, by the measure everything else here uses.
  This page comes out at nothing. The crossed pair comes out at a half turn, from this code with
  another hold rather than from a second drawing of one idea.</p>
  <p><b>This settles rule 13</b>, which reads <em>"the two sides with an extra arm twist, in
  either direction"</em>. That extra twist was taken to belong to the crossed pair alone. It does
  not: it is the swan, and hand to hand carries one at each end.</p>
</section>

<section>
  <div class="head"><span class="n">The chain</span><h2>The seven, in
  order</h2></div>
  <p>All four manners of turn reach these same seven, so they are drawn once rather than four
  times over. A position cannot say which dancer turned, and only the path can, which is why
  every manner is drawn in motion below.</p>
  <div class="row mid">
    {chain}
  </div>
</section>

{plates}

<div class="note">
  <p><b>A moving crossing says which arm lies on top, as a still one does.</b> It cannot say it
  the same way. A still reach is cut into pieces at the break. The number of pieces changes with the
  number of crossings, which is the one thing a morph cannot follow.</p>
  <p>So a moving reach keeps
  its single piece and wears the break as a <em>dash</em>. The dash travels with the
  crossing, and it closes to nothing where no crossing is there to mark. Watch a whole turn wind
  on, and the break appears at a hand and slides inward as the crossing does.</p>
  <p><b>What is not drawn:</b> anything past a turn and a half. The swans are the ends of the
  chain and they hold. No frame of any animation is wound further, and no position draws two
  diamonds stacked. The build chooses which way a turn goes, which is whichever way walks the
  chain inward, measured for each manner rather than assumed. The chain runs out where this scope
  does, and not where the dance does. A pair can keep winding, and what lies past the swan is
  yours to settle.</p>
</div>

<div class="foot">
  <p><b>Not in the app yet.</b> The app keeps drawing the eight frames and nothing else until the
  marks are settled.</p>
  <p>Yours to settle on this page:</p>
  <ul>
    <li>whether the two ends are named for the crossover of the lead, as they are here, or for
    the whole shape;</li>
    <li>how wide the diamond should open;</li>
    <li>whether an edge should carry the turn sign, which was built for this job.</li>
  </ul>
</div>

</div>
"""


func render*(P: Parts): string =
  ## Lay hand-to-hand turns page out around given figures.
  var chain: string
  for i, position in CHAIN:
    if i > 0:
      chain.add P["g_half"]
    chain.add fig(P[&"hh_{i}"], &"<b>{position.name}</b><br>{position.note}")
  document(TITLE, BODY.filled(@[("chain", chain), ("plates", plates(P))]))
