## Lay out turn-sign page: how to label edge with amount of
## turning.
##
##   Separate exploration from frame picture, on separate page,
##     because it answers separate question -- what goes on *edge*, not
##     what *node* looks like.
##   These two meet only at levels and arm inks, which shared
##     chrome keeps identical.
##     Cost of split: reader meets sign without frames it
##       will annotate.  Accepted -- edge label and node picture
##       answer different questions, and key joins them later.
##   Body template's lines are held under hundred-column rule by closing and reopening
##     literal at structural points (`<br>`, `<td>`, `<figcaption>`), never inside
##     expression; bytes are page's bytes still, verified once by writing split and
##     unsplit constants to files and comparing them (identical).
##     Cost: template reads as markup broken by `""" &`, which is what repository's form
##       rule costs here.

{.experimental: "strictFuncs".}

import std/tables

import ./[page, parts]


const TITLE* = "The Turn Sign, So Far"
  ## What page calls itself, in its tab and at its head.


const BODY = """

<div class="sheet">

<header class="top">
  <p class="kicker">Dance ontology · rotation · the turn sign</p>
  <h1>The turn sign, so far</h1>
  <p class="standfirst">A leaning box that holds exactly one full turn. Rows are
  <b>quarter turns</b>, packed up from the foot, so an amount reads as fullness
  before it reads as a count. Columns are the lead's two arms; a pip's shape
  says whose quarter it is and its fill says that arm's level. Still open: the
  mark for <em>any amount</em>, and whether a sign that only labels edges is
  worth keeping once the frame pictures can animate the move itself.</p>
  <p class="sibling"><b>The frame picture is on its own page.</b> It settles
  what a held pair of hands looks like and what an orbit does to it; this page
  borrows its level fills and its two arm inks and nothing else.</p>
</header>

<section>
  <div class="head"><span class="n">Shared</span><h2>The fills it borrows</h2></div>
  <p>A pip's fill is the fill the hand it stands for would carry, so a sign and
  a frame picture never disagree about a level. The lead's shade is the deep one
  and the follow's the plain one, as on the frame page.</p>
  <div class="plate">
    <div class="key">
      {sw_none}
      <span><b>hollow</b> — level unsaid</span>
      {sw_low}
      <span><b>solid</b> — low, below the shoulder</span>
      {sw_high}
      <span><b>dot</b> — high, above the shoulder</span>
      {sw_above}
      <span><b>hatched</b> — above, over the head</span>
    </div>
  </div>
</section>

<section>
  <div class="head"><span class="n">One</span><h2>Quarters, and the sign becomes
  a gauge</h2></div>
  <p>Four rows will not fit the old sign, so it grows to
  <code>4 × 11 + 5 × 4 = 64</code> — and that is worth having rather than
  working around, because once the box is exactly a full turn the rows can
  <b>pack up from the foot</b> and the amount reads as how full it is. Counting
  the pips then confirms the reading instead of being the whole of it, which
  matters more at four than it did at two. Filling upward is also how a Laban
  staff is read.</p>

  <div class="plate">
    <h3>A quarter at a time</h3>
    <div class="row">
      <figure>{q_lead_1}<figcaption>lead · <b>¼</b></figcaption></figure>
      <figure>{q_lead_2}<figcaption><b>½</b></figcaption></figure>
      <figure>{q_lead_3}<figcaption><b>¾</b></figcaption></figure>
      <figure>{q_lead_4}<figcaption><b>1</b> turn</figcaption></figure>
      <figure>{q_foll_1}<figcaption>follow · <b>¼</b></figcaption></figure>
      <figure>{q_foll_2}<figcaption><b>½</b></figcaption></figure>
      <figure>{q_foll_3}<figcaption><b>¾</b></figcaption></figure>
      <figure>{q_foll_4}<figcaption><b>1</b> turn</figcaption></figure>
    </div>
    <p>At the size an edge label ends up, where the fullness has to do the work
    on its own:</p>
    <div class="row mid">
      <figure>{q_lead_1_small}<figcaption>¼</figcaption></figure>
      <figure>{q_lead_2_small}<figcaption>½</figcaption></figure>
      <figure>{q_lead_3_small}<figcaption>¾</figcaption></figure>
      <figure>{q_lead_4_small}<figcaption>1</figcaption></figure>
    </div>
  </div>

  <div class="plate">
    <h3>The alternative, for comparison</h3>
    <p>Spread evenly instead of packed, which is what the sign did when it held
    three. It still counts, but a quarter and three quarters no longer look
    different at a glance — the pip just moves rather than the sign filling.</p>
    <div class="row">
      <figure>{u_lead_1}<figcaption>spread · <b>¼</b></figcaption></figure>
      <figure>{u_lead_3}<figcaption>spread · <b>¾</b></figcaption></figure>
      <figure>{q_lead_1_again}<figcaption>packed · <b>¼</b></figcaption></figure>
      <figure>{q_lead_3_again}<figcaption>packed · <b>¾</b></figcaption></figure>
    </div>
  </div>

  <div class="plate">
    <h3>Whose quarter, which arm, at what height</h3>
    <p>Square for the lead and round for the follow; the column and the ink say
    which of the lead's arms, in the same order as the frame picture; the fill
    says that arm's level, on the follow's pips too, because the level belongs
    to the arm carrying the connection whoever is turning. An empty column is a
    hand that is not held.</p>
    <div class="row">
      <figure>{s_split}<figcaption>lead · <b>½</b>""" &
        """<br>Left <b>low</b>, Right <b>high</b></figcaption></figure>
      <figure>{s_acw}<figcaption>lead · <b>¾</b><br>anticlockwise</figcaption></figure>
      <figure>{s_one_hand}<figcaption>follow · <b>½</b>""" &
        """<br>one hand, Left <b>low</b></figcaption></figure>
      <figure>{s_above}<figcaption>follow · <b>1</b><br>both <b>above</b></figcaption></figure>
      <figure>{s_unsaid}<figcaption>lead · <b>¼</b><br>levels unsaid</figcaption></figure>
      <figure>{s_lead_small}<figcaption>lead · small</figcaption></figure>
      <figure>{s_foll_small}<figcaption>follow · small</figcaption></figure>
    </div>
  </div>

  <div class="note">
    <p><b>A knock-on from the frame page, not acted on.</b> The sign's two
    columns are the <em>lead's</em> arms. Now that the follow's hands carry their
    own sides, a blue column no longer unambiguously means the lead's Left — it
    means the arm that carries that connection, which the frame picture would now
    let you name from either end. Worth revisiting when the sign is redesigned;
    not worth churning the sign for on its own.</p>
    <p><b>One thing to watch at four rows.</b> A column repeats its level fill
    once per row, so a full turn on two hands is eight pips carrying two pieces
    of information. That redundancy was deliberate at two rows — any single row
    reads complete — but at four it is loud. If it reads as noise rather than
    reinforcement, the fix is to fill only the row nearest the foot and leave the
    rest as plain counters. Flagged rather than chosen.</p>
  </div>
</section>

<section>
  <div class="head"><span class="n">Two</span><h2>Mixed, with room to be
  uneven</h2></div>
  <p>And here is where quarters pay for themselves. Last round a mixed sign was
  stuck at half a turn each, and I said that fell out of the model — it did not.
  It fell out of there being three slots. At four, any split is drawable, with
  the follow's rows still on top.</p>
  <div class="plate">
    <div class="row">
      <figure>{m_11}<figcaption><b>¼</b> each<br>= ½ turn</figcaption></figure>
      <figure>{m_12}<figcaption>follow <b>¼</b>, lead <b>½</b><br>= ¾ turn</figcaption></figure>
      <figure>{m_22}<figcaption><b>½</b> each<br>= 1 turn</figcaption></figure>
      <figure>{m_31}<figcaption>follow <b>¾</b>, lead <b>¼</b><br>= 1 turn</figcaption></figure>
      <figure>{m_22_small}<figcaption>mixed · small</figcaption></figure>
    </div>
    <p>The follow's rows always sit on top, so a mixed turn has one picture
    rather than two and there is nothing to read into the order.</p>
  </div>
</section>

<section>
  <div class="head"><span class="n">Three</span><h2>Five ways to say
  <em>any amount</em></h2></div>
  <p>Three rows is three quarters now, so <em>any</em> needs a mark of its own.
  I could not find a Labanotation convention for an indeterminate amount — turn
  signs there carry a measured degree — so this is not a borrowing, except for
  the fourth candidate, which takes music's <em>repeat ad libitum</em>. Each is
  drawn full size, small, and once for the follow, against a plain full turn for
  comparison.</p>

  <div class="plate pick">
    <h3>One — the box never closes<span class="tag">recommended</span></h3>
    <p>The lid is simply not drawn and the two long edges run on past where it
    would be. Nothing added, one stroke removed, and it composes exactly with the
    gauge: a box that never closes can never be full, so it cannot be read as a
    count. It is also the only candidate that costs nothing at small size,
    because what says it is the absence of a line rather than a new mark inside
    an already busy one.</p>
    <div class="row">
      <figure>{any_full}<figcaption>a plain <b>1</b> turn<br>for comparison</figcaption></figure>
      <figure>{any_open}<figcaption><b>any</b> — open</figcaption></figure>
      <figure>{any_open_foll}<figcaption>follow · <b>any</b></figcaption></figure>
      <figure>{any_open_small}<figcaption>small</figcaption></figure>
    </div>
  </div>

  <div class="plate">
    <h3>Two — open, with the next one showing</h3>
    <p>The same, plus a fifth pip up in the run-on. Says "and it keeps going"
    rather than "and it stops being drawn", at the cost of a taller mark and one
    more thing in it.</p>
    <div class="row">
      <figure>{any_spill}<figcaption><b>any</b> — spilling</figcaption></figure>
      <figure>{any_spill_foll}<figcaption>follow · <b>any</b></figcaption></figure>
      <figure>{any_spill_small}<figcaption>small</figcaption></figure>
    </div>
  </div>

  <div class="plate">
    <h3>Three — an ellipsis in the top row</h3>
    <p>The box stays closed and the fourth row holds three dots per column
    instead of a pip: three quarters, and so on. Unmistakable at size; the three
    dots merge into one blob small, at which point it reads as a fourth pip.</p>
    <div class="row">
      <figure>{any_ellipsis}<figcaption><b>any</b> — ellipsis</figcaption></figure>
      <figure>{any_ellipsis_foll}<figcaption>follow · <b>any</b></figcaption></figure>
      <figure>{any_ellipsis_small}<figcaption>small</figcaption></figure>
    </div>
  </div>

  <div class="plate">
    <h3>Four — music's repeat mark</h3>
    <p>The ad-lib colon in the top row: play it as many times as you like. A real
    convention with a long history, and read instantly by anyone who reads music
    — which is not the same set as anyone who dances.</p>
    <div class="row">
      <figure>{any_repeat}<figcaption><b>any</b> — repeat</figcaption></figure>
      <figure>{any_repeat_foll}<figcaption>follow · <b>any</b></figcaption></figure>
      <figure>{any_repeat_small}<figcaption>small</figcaption></figure>
    </div>
  </div>

  <div class="plate">
    <h3>Five — the loop drawn on its own label</h3>
    <p>An arrow curling from the head back to the foot: the graph's loop edge,
    on the edge's own label. The most explicit of the five and the only one that
    says <em>why</em> the count does not end. It is also the widest, and the curl
    is the first thing to go small.</p>
    <div class="row">
      <figure>{any_loop}<figcaption><b>any</b> — loop</figcaption></figure>
      <figure>{any_loop_foll}<figcaption>follow · <b>any</b></figcaption></figure>
      <figure>{any_loop_small}<figcaption>small</figcaption></figure>
    </div>
  </div>
</section>

<section>
  <div class="head"><span class="n">Four</span><h2>On its own axis, or round
  the couple</h2></div>
  <p><b>Solid stays on the spot, dashed travels round the couple</b> — the same
  dash the frame page puts on an orbit's ring, and for the same reason: it is
  the mark for going round something. The frame page shows why the distinction
  has to live here rather than on a node: an orbit <em>lands</em> where an axis
  turn lands, so only the edge can tell them apart.</p>
  <div class="plate">
    <div class="row">
      <figure>{o_axis}<figcaption>on <b>axis</b></figcaption></figure>
      <figure>{o_orbit}<figcaption>on <b>orbit</b></figcaption></figure>
      <figure>{o_orbit_acw}<figcaption>follow · <b>orbit</b><br>anticlockwise</figcaption></figure>
      <figure>{o_axis_small}<figcaption>axis · small</figcaption></figure>
      <figure>{o_orbit_small}<figcaption>orbit · small</figcaption></figure>
    </div>
  </div>
  <div class="note">
    <p><b>Still colliding with mixed signs.</b> The outline is one value and a
    mixed sign holds two dancers — the lead turning on the spot while the follow
    travels round them is ordinary, not a corner case. Putting it on the pips
    instead writes that case, at the cost of pulling each fill in off its
    outline so a dashed stroke has something to show against.</p>
    <div class="row mid">
      <figure>{p_split}<figcaption>follow <b>orbits</b>,""" &
        """<br>lead on <b>axis</b></figcaption></figure>
      <figure>{p_split_small}<figcaption>small</figcaption></figure>
    </div>
  </div>
</section>

<div class="foot">
  <p><b>Still not in the app.</b> The rotation views came off the page on purpose
  and go back when the marks are settled and the ontology is finished.</p>
  <p>Yours to settle on this page: which <em>any</em> mark; whether orbit stays
  on the outline or moves to the pips; whether the level fill repeats down every
  row; whether the sign survives at all now that the frame pictures can animate
  the move; and the staff for a sequence.</p>
</div>

</div>
"""


func render*(P: Parts): string =
  ## Lay turn-sign page out around given figures.
  var fills = @[
    ("sw_none", swatch(Swatch.Unsaid)), ("sw_low", swatch(Swatch.Low)),
    ("sw_high", swatch(Swatch.High)), ("sw_above", swatch(Swatch.Above)),
    # Comparison plate re-places two of packed quarters, and each
    # marker can be filled once, so seconds ride under their own names.
    ("q_lead_1_again", P["q_lead_1"]), ("q_lead_3_again", P["q_lead_3"]),
  ]
  for key in ["q_lead_1", "q_lead_2", "q_lead_3", "q_lead_4",
              "q_foll_1", "q_foll_2", "q_foll_3", "q_foll_4",
              "q_lead_1_small", "q_lead_2_small", "q_lead_3_small",
              "q_lead_4_small", "u_lead_1", "u_lead_3",
              "s_split", "s_acw", "s_one_hand", "s_above", "s_unsaid",
              "s_lead_small", "s_foll_small",
              "m_11", "m_12", "m_22", "m_31", "m_22_small",
              "any_full", "any_open", "any_open_foll", "any_open_small",
              "any_spill", "any_spill_foll", "any_spill_small",
              "any_ellipsis", "any_ellipsis_foll", "any_ellipsis_small",
              "any_repeat", "any_repeat_foll", "any_repeat_small",
              "any_loop", "any_loop_foll", "any_loop_small",
              "o_axis", "o_orbit", "o_orbit_acw", "o_axis_small",
              "o_orbit_small", "p_split", "p_split_small"]:
    fills.add (key, P[key])
  document(TITLE, BODY.filled(fills))
