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
    "half a turn with them. Nobody travels and nothing needs bringing back " &
    "afterwards, so this is the plainest of the four: one stage, and the " &
    "arms wind as it goes.",
  "The lead turns half a circle on the spot. A lead's turn winds the pair " &
    "the opposite way to a follow's, so to take the <em>same</em> step of " &
    "the chain they turn the other way round — turning both the same " &
    "way sent this row off the end of the chain and drew a second diamond. " &
    "<b>Stage one</b> is the turn with the room held still; <b>stage two</b> " &
    "brings the picture back to the lead facing up, which swings the follow " &
    "round them and leaves the wind exactly where the turn put it.",
  "The follow walks half a circle round the lead \u2014 the dashed ring says " &
    "who is standing still \u2014 <b>keeping whatever side of them faced the " &
    "lead facing them</b>, so they turn as far as they travel (rule 32). " &
    "That winds the pair a half turn, the same half turn an axis turn " &
    "winds: it walks the chain, and it lands on the very position the " &
    "<em>lead's</em> axis turn lands on.",
  "The lead walks the half circle instead, facing the centre the same way, " &
    "and it winds the pair a half turn too. It is the one manner of the four " &
    "that takes the lead off their spot, so it is the one whose second " &
    "stage has both the travelling and the turning to bring back.",
] ## What each manner of turn does to pair, in this page's terms.
  ##   Not `MANNERS`'s own blurbs: those speak of single hand
  ##     coming round, and here orientation is exactly what returns.


func plates(P: Parts): string =
  ## Lay out four manners of turn, each walking every edge of chain.
  for manner in Manner:
    let w = MANNERS[manner]
    result.add &"""<div class="plate"><h3>{w.title}</h3>"""
    result.add &"<p>{WINDING[manner]}</p>"
    result.add """<p>Every edge of the chain, each rocking between its two
      ends so the half turn reads both ways:</p>"""
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
  <p class="standfirst">Both hands held, uncrossed — the lead's Left in the
  follow's right, the lead's Right in the follow's left — and both arms
  carried <b>above</b>, as everything in this scope is. <b>This page is the
  single-hand page turned inside out.</b> One hand held above turns for
  ever, so how far it has wound is not part of its state and where the pair
  is pointing is all of it. Hold both and it is the other way about: a whole
  turn puts every facing and every place back exactly where it was, so the
  pointing says nothing and <b>the wind is the state</b>. A turn and a half
  each way, by halves: seven positions.</p>
  <p class="sibling"><b>The crossed pair comes next</b>, on its own page —
  and it is <em>this</em> chain, read half a turn along, so what is left is
  to draw it.</p>
</header>

<section>
  <div class="head"><span class="n">What is here</span><h2>Seven positions,
  a half turn apart</h2></div>
  <p><b>The middle one is the app's own frame</b>, drawn exactly as the app
  draws it: two connections running side by side, crossing nothing. Each
  half turn from there winds the pair one step further, and the chain runs
  out at a turn and a half each way.</p>
  <p><b>Which way the partners face follows from the wind</b>, so the
  captions leave it out and it is said once here: <b>face-to-face</b> at a
  whole number of turns — the frame and the diamonds — and <b>pillion
  lead</b> at a half — the crosses and the swans.</p>
  <p><b>A half turn makes a cross.</b> The partners end up pillion lead, both
  facing one way with the lead behind, and the two connections cross once
  overhead — the plain crossing the app already uses for a crossed pair, with
  the over-and-under break saying which arm is on top. <b>A whole turn makes a
  diamond</b>: the pair crosses <em>twice</em>, once by the lead and once by
  the follow, and what the two
  crossings enclose is the shape rule 27 named. <b>The two crossings say
  opposite things</b> — whichever connection is over at the lead's end is
  under at the follow's, because that is what being wound together means.</p>
  <p><b>A turn and a half makes a swan</b>, and it is where the pair stops
  being symmetric. Wound that far the two arms cannot both keep swinging:
  one pulls taut and runs straight through the middle while the other wraps
  it, over and under and over, in two long loops — the necks of two mating
  swans round a straight neck between them, which is the picture and the
  name. It crosses three times, and it is emphatically <em>not</em> two
  diamonds stacked; that drawing was refused (rule 30) and this is what
  replaced it.</p>
  <p><b>Nothing here is imposed.</b> How far a pair has wound is
  <em>measured</em>: each held hand sits on its own body's rim and both
  bodies stand on the pair's axis, so the angle a hand makes with that axis
  is what going round means, and the difference between the two ends is the
  wind. A reach is then just the shadow of a wound arm from above — its
  offset from the axis swinging as far round as the pair has. Straight at
  none, a cross at a half, a diamond at a whole, and every frame in between
  following from the same measure, which is what stops a turn snapping into
  its final shape.</p>
  <p><b>All four manners of turn wind, and by the same half turn.</b> That
  is rule 32's doing and its whole reason: an orbiter keeps whatever side of
  them faced the centre facing it, so they turn as far as they travel and
  the pair winds with them. A half turn is then a half turn however it is
  danced, and the four manners can be equated. <b>An orbit even lands on the
  same position the other dancer's axis turn lands on</b> — measured, and
  asserted on every build.</p>
  <p><b>It was not always so.</b> An earlier rule had an orbiter keep their
  own bearing, and a walker who does that never turns relative to their
  partner: measured, that orbit wound nothing at all, and only two of the
  four manners walked this chain. Keeping the bearing is still a move — it is
  the orbit with a counter-turn danced into it — but it is not the orbit.</p>
  <p><b>The names are preliminary and yours.</b> <em>Left over Right</em> is
  the position where the lead's Left connection passes over the Right at the
  lead's own crossover; <em>Right over Left</em> is its mirror. The cross,
  the diamond and the swan a step apart share a name because they are the same
  winding, carried further.</p>
</section>

<section>
  <div class="head"><span class="n">One chain</span><h2>Both patterns, half
  a turn apart</h2></div>
  <p><b>Hand to hand and the crossed pair are the same chain.</b> A hold has
  one position where its two connections run parallel and cross nothing —
  and that position sits at a different <em>facing</em> for each of them.
  Hand to hand is parallel with the partners <b>face-to-face</b>; hold left
  to left and right to right instead and it is parallel <b>pillion lead</b>,
  which on this page's chain is half a turn along. Every
  step after that is the same step: cross, diamond, swan, out to a turn and
  a half each way.</p>
  <p><b>So the phase is measured, not written down.</b> The build turns the
  follow to each candidate and asks which one leaves the hold unwound, using
  the same measure everything else here uses. This page comes out at nothing;
  the crossed pair will come out at a half turn, and it will be this code
  with a different hold rather than a second drawing of the same idea.</p>
  <p><b>What this settles</b> is rule 13's <em>"the two sides with an extra
  arm twist, in either direction"</em>. That extra twist was thought to
  belong to the crossed pair alone. It does not: it is the swan, and hand to
  hand has one at each end too.</p>
</section>

<section>
  <div class="head"><span class="n">The chain</span><h2>The seven, in
  order</h2></div>
  <p>All four manners of turn reach these same seven, so they are drawn once
  rather than four times over. Which dancer turned is not something a position
  can say — only the path can, which is why every manner is animated below.</p>
  <div class="row mid">
    {chain}
  </div>
</section>

{plates}

<div class="note">
  <p><b>A moving crossing says which arm is on top, the same as a still
  one.</b> It cannot say it the same way: a still reach is cut into pieces
  at the break, and how many pieces that makes changes with the number of
  crossings — which is the one thing a morph cannot follow. So a moving
  reach keeps its single piece and wears the break as a <em>dash</em>
  instead, travelling with the crossing and closing to nothing where there
  is no crossing to mark. Watch a whole turn wind on and you can see the
  break appear at a hand and slide inward as the crossing does.</p>
  <p><b>What is not drawn:</b> anything past a turn and a half. The swans
  are the ends of the chain and they hold — no frame of any animation is
  wound further, and no position anywhere draws two diamonds stacked. Which
  way a turn goes is chosen for it: whichever way walks the chain
  <em>inward</em>, measured per manner rather than assumed. The chain runs out
  where this scope does, not where the dance does — a pair can keep
  winding, and what lies past the swan is yours to settle.</p>
</div>

<div class="foot">
  <p><b>Still not in the app.</b> Same standing as the other pages: the app
  keeps drawing the eight frames and nothing else until the marks are
  settled.</p>
  <p>Yours to settle on this page: whether the two ends should be named for
  the lead's crossover as they are here or for the whole shape; how wide the
  diamond should open; and whether an edge should carry the turn sign, which
  was built for exactly this job.</p>
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
