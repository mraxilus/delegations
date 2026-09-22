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
  <p class="standfirst">A leaning box holds exactly one full turn. Its rows are <b>quarter
  turns</b>, packed up from the foot, so an amount reads as fullness before it reads as a count.
  Its columns are the two arms of the lead. The shape of a pip says whose quarter it is, and its
  fill says the level of that arm.</p>
   <p class="standfirst">Two things stay open. One is the mark for <em>any amount</em>.
  The other is whether a sign that labels edges alone is worth keeping, now that the frame pictures
  animate a move.</p>
  <p class="sibling"><b>The frame picture is on its own page.</b> It settles what a held pair of
  hands looks like, and what an orbit does to it. This page borrows the level fills and the two
  arm inks, and nothing else.</p>
</header>

<section>
  <div class="head"><span class="n">Shared</span><h2>The fills it borrows</h2></div>
  <p>The fill of a pip is the fill that the hand it stands for carries. So a sign and a frame
  picture never disagree about a level. The shade of the lead is the deep one, and the shade of
  the follow is the plain one, as on the frame page.</p>
  <div class="plate">
    <div class="key">
      {sw_none}
      <span><b>hollow</b>: no level said</span>
      {sw_low}
      <span><b>solid</b>: low, below the shoulder</span>
      {sw_high}
      <span><b>dot</b>: high, above the shoulder</span>
      {sw_above}
      <span><b>hatched</b>: above, over the head</span>
    </div>
  </div>
</section>

<section>
  <div class="head"><span class="n">One</span><h2>Quarters, and the sign becomes
  a gauge</h2></div>
  <p>The box holds one full turn in four rows. The rows pack up from the foot, so the amount
  reads as how full the sign is. The count of pips then confirms that reading rather than
  carrying it alone. A Laban staff fills upward for the same reason.</p>

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
    <p>At the size an edge label takes, the fullness does the work alone:</p>
    <div class="row mid">
      <figure>{q_lead_1_small}<figcaption>¼</figcaption></figure>
      <figure>{q_lead_2_small}<figcaption>½</figcaption></figure>
      <figure>{q_lead_3_small}<figcaption>¾</figcaption></figure>
      <figure>{q_lead_4_small}<figcaption>1</figcaption></figure>
    </div>
  </div>

  <div class="plate">
    <h3>The alternative, for comparison</h3>
    <p>Here the pips spread evenly rather than pack. A spread sign still counts. A quarter and three
    quarters no longer differ at a glance, because the pip moves and the sign does not fill.</p>
    <div class="row">
      <figure>{u_lead_1}<figcaption>spread · <b>¼</b></figcaption></figure>
      <figure>{u_lead_3}<figcaption>spread · <b>¾</b></figcaption></figure>
      <figure>{q_lead_1_again}<figcaption>packed · <b>¼</b></figcaption></figure>
      <figure>{q_lead_3_again}<figcaption>packed · <b>¾</b></figcaption></figure>
    </div>
  </div>

  <div class="plate">
    <h3>Whose quarter, which arm, at what height</h3>
    <p>A square pip is the lead, and a round pip is the follow. The column and the ink say which
    arm of the lead it is, in the order the frame picture uses. The fill says the level of that arm,
    on the pips of the follow as well. The level belongs to the arm that carries the connection,
    whoever turns. An empty column is a hand that nobody holds.</p>
    <div class="row">
      <figure>{s_split}<figcaption>lead · <b>½</b>
        <br>Left <b>low</b>, Right <b>high</b></figcaption></figure>
      <figure>{s_acw}<figcaption>lead · <b>¾</b><br>anticlockwise</figcaption></figure>
      <figure>{s_one_hand}<figcaption>follow · <b>½</b>
        <br>one hand, Left <b>low</b></figcaption></figure>
      <figure>{s_above}<figcaption>follow · <b>1</b><br>both <b>above</b></figcaption></figure>
      <figure>{s_unsaid}<figcaption>lead · <b>¼</b><br>levels unsaid</figcaption></figure>
      <figure>{s_lead_small}<figcaption>lead · small</figcaption></figure>
      <figure>{s_foll_small}<figcaption>follow · small</figcaption></figure>
    </div>
  </div>

  <div class="note">
    <p><b>Known and not mended, from the frame page.</b> The two columns of the sign are the arms
    of the lead. The hands of the follow now carry their own sides, so a blue column no longer
    means the Left of the lead alone. It means the arm that carries that connection, which the
    frame picture names from either end.</p>
    <p><b>One thing to watch at four rows.</b> A column repeats its level fill once for each row. So
    a full turn on two hands is eight pips that carry two pieces of information. Any single
    row reads complete, and at four rows that is loud. Where it reads as noise, the mend is to
    fill the row nearest the foot and leave the rest as plain counters.</p>
  </div>
</section>

<section>
  <div class="head"><span class="n">Two</span><h2>Mixed, with room to be
  uneven</h2></div>
  <p>Four rows draw any split between the two dancers. Three slots could not, which is what held
  a mixed sign at half a turn each. The rows of the follow stay on top.</p>
  <div class="plate">
    <div class="row">
      <figure>{m_11}<figcaption><b>¼</b> each<br>= ½ turn</figcaption></figure>
      <figure>{m_12}<figcaption>follow <b>¼</b>, lead <b>½</b><br>= ¾ turn</figcaption></figure>
      <figure>{m_22}<figcaption><b>½</b> each<br>= 1 turn</figcaption></figure>
      <figure>{m_31}<figcaption>follow <b>¾</b>, lead <b>¼</b><br>= 1 turn</figcaption></figure>
      <figure>{m_22_small}<figcaption>mixed · small</figcaption></figure>
    </div>
    <p>The rows of the follow always sit on top. So a mixed turn has one picture rather than two,
    and the order carries nothing to read into.</p>
  </div>
</section>

<section>
  <div class="head"><span class="n">Three</span><h2>Five ways to say
  <em>any amount</em></h2></div>
  <p>Three rows now mean three quarters, so <em>any</em> needs a mark of its own. Labanotation
  offers none, because a turn sign there carries a measured degree. So four of these five marks
  are this project's own, and the fourth takes the <em>repeat ad libitum</em> of music. Each one
  is drawn full size, small, and once for the follow, beside a plain full turn.</p>

  <div class="plate pick">
    <h3>One, the box never closes<span class="tag">recommended</span></h3>
    <p>The lid is not drawn, and the two long edges run on past it. That adds nothing and removes
    one stroke, and it composes with the gauge. A box that never closes can never be full, so
    nothing reads it as a count. It is the one candidate that costs nothing at small size. A missing
    line says it, rather than a new mark inside a busy one.</p>
    <div class="row">
      <figure>{any_full}<figcaption>a plain <b>1</b> turn<br>for comparison</figcaption></figure>
      <figure>{any_open}<figcaption><b>any</b>, open</figcaption></figure>
      <figure>{any_open_foll}<figcaption>follow · <b>any</b></figcaption></figure>
      <figure>{any_open_small}<figcaption>small</figcaption></figure>
    </div>
  </div>

  <div class="plate">
    <h3>Two, open with the next one showing</h3>
    <p>The same open box, and a fifth pip up in the run-on. It says that the count keeps going
    rather than that the drawing stops. It costs a taller mark and one more thing inside it.</p>
    <div class="row">
      <figure>{any_spill}<figcaption><b>any</b>, spilling</figcaption></figure>
      <figure>{any_spill_foll}<figcaption>follow · <b>any</b></figcaption></figure>
      <figure>{any_spill_small}<figcaption>small</figcaption></figure>
    </div>
  </div>

  <div class="plate">
    <h3>Three, an ellipsis in the top row</h3>
    <p>The box stays closed, and the fourth row holds three dots for each column rather than a
    pip. It reads as three quarters, and so on. It is plain at size, and small the three dots
    merge into one blob, which reads as a fourth pip.</p>
    <div class="row">
      <figure>{any_ellipsis}<figcaption><b>any</b>, ellipsis</figcaption></figure>
      <figure>{any_ellipsis_foll}<figcaption>follow · <b>any</b></figcaption></figure>
      <figure>{any_ellipsis_small}<figcaption>small</figcaption></figure>
    </div>
  </div>

  <div class="plate">
    <h3>Four, the repeat mark of music</h3>
    <p>The ad libitum colon sits in the top row, and it says to play as many times as you like.
    It is a real convention with a long history, and anyone who reads music reads it at once.
    Those are not the same people as those who dance.</p>
    <div class="row">
      <figure>{any_repeat}<figcaption><b>any</b>, repeat</figcaption></figure>
      <figure>{any_repeat_foll}<figcaption>follow · <b>any</b></figcaption></figure>
      <figure>{any_repeat_small}<figcaption>small</figcaption></figure>
    </div>
  </div>

  <div class="plate">
    <h3>Five, the loop drawn on its own label</h3>
    <p>An arrow curls from the head back to the foot, which is the loop edge of the graph drawn
    on the label of that edge. It is the most explicit of the five, and the one that says why the
    count does not end. It is also the widest, and the curl is the first thing to go at small
    size.</p>
    <div class="row">
      <figure>{any_loop}<figcaption><b>any</b>, loop</figcaption></figure>
      <figure>{any_loop_foll}<figcaption>follow · <b>any</b></figcaption></figure>
      <figure>{any_loop_small}<figcaption>small</figcaption></figure>
    </div>
  </div>
</section>

<section>
  <div class="head"><span class="n">Four</span><h2>On its own axis, or round
  the couple</h2></div>
  <p><b>A solid outline stays on the spot, and a dashed one travels round the couple.</b> That is
  the dash the frame page puts on the ring of an orbit, and it is the mark for a path round
  something. The distinction has to live on the edge: an orbit lands where an axis turn lands, so
  no node can hold it.</p>
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
    <p><b>The outline still collides with a mixed sign.</b> The outline carries one value, and a
    mixed sign holds two dancers. A lead who turns on the spot while the follow travels round
    them is ordinary, and not a corner case. The pips can carry it instead, which costs pulling
    each fill in off its outline, so that a dashed stroke has something to show against.</p>
    <div class="row mid">
      <figure>{p_split}<figcaption>follow <b>orbits</b>,
        <br>lead on <b>axis</b></figcaption></figure>
      <figure>{p_split_small}<figcaption>small</figcaption></figure>
    </div>
  </div>
</section>

<div class="foot">
  <p><b>Not in the app yet.</b> The rotation views come back to the app once the marks are settled
  and the ontology is finished.</p>
  <p>Yours to settle on this page:</p>
  <ul>
    <li>which <em>any</em> mark;</li>
    <li>whether the orbit stays on the outline or moves to the pips;</li>
    <li>whether the level fill repeats down every row;</li>
    <li>whether the sign survives at all, now that the frame pictures animate a move;</li>
    <li>the staff for a sequence.</li>
  </ul>
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
