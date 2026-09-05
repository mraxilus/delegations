## Host review page's prose: every number and picture is marker `{{name}}` that
##   `tools/review` fills from model, so nothing here is transcribed.
##   Lives in Nim because repository reads only registered file kinds; comments inside
##     markup are telegraphic by hand, since checker cannot see inside string.
##   Plain constant, never format string: style and prose are full of braces.
##   Cost of template with markers: marker is text compiler never sees, so misspelt or
##     unfilled one is caught by assertion in `renderReview` rather than by compile error.

const TEMPLATE* = """
<title>Partner Work — reading the ontology back</title>

<style>
:root {
  --ground: #eceeec;
  --panel: #f7f8f7;
  --ink: #1a1f1e;
  --dim: #6b716e;
  --faint: #9aa19d;
  --rule: #d4d8d4;
  --rule-strong: #b9bfba;
  --left: #2b6c8c;
  --right: #a85f22;
  /* Deep shade of each hue, for lead's end of connection; plain one above is
     follow's. Frame picture reads whose end is whose off pair. */
  --left-deep: #14374a;
  --right-deep: #5c3413;
  --agree: #3f7550;
  --accent: #a85f22;
  --accent-cool: #2b6c8c;
  --shadow: 0 1px 2px rgba(26, 31, 30, .05);
  --display: ui-serif, "Iowan Old Style", "Palatino Linotype", Palatino, Georgia, serif;
  --body: ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
  --data: ui-monospace, "SF Mono", "Cascadia Mono", Menlo, Consolas, monospace;
}
@media (prefers-color-scheme: dark) {
  :root {
    --ground: #141716;
    --panel: #1b201e;
    --ink: #e7eae7;
    --dim: #99a09c;
    --faint: #6d7571;
    --rule: #2e3532;
    --rule-strong: #414945;
    --left: #6aa9c7;
    --right: #dd8f4d;
    --left-deep: #2f6a85;
    --right-deep: #8a5622;
    --agree: #6cab80;
    --accent: #dd8f4d;
    --accent-cool: #6aa9c7;
    --shadow: none;
  }
}
:root[data-theme="dark"] {
  --ground: #141716;
  --panel: #1b201e;
  --ink: #e7eae7;
  --dim: #99a09c;
  --faint: #6d7571;
  --rule: #2e3532;
  --rule-strong: #414945;
  --left: #6aa9c7;
  --right: #dd8f4d;
  --left-deep: #2f6a85;
  --right-deep: #8a5622;
  --agree: #6cab80;
  --shadow: none;
}
:root[data-theme="light"] {
  --ground: #eceeec;
  --panel: #f7f8f7;
  --ink: #1a1f1e;
  --dim: #6b716e;
  --faint: #9aa19d;
  --rule: #d4d8d4;
  --rule-strong: #b9bfba;
  --left: #2b6c8c;
  --right: #a85f22;
  /* Deep shade of each hue, for lead's end of connection; plain one above is
     follow's. Frame picture reads whose end is whose off pair. */
  --left-deep: #14374a;
  --right-deep: #5c3413;
  --agree: #3f7550;
  --accent: #a85f22;
  --accent-cool: #2b6c8c;
  --shadow: 0 1px 2px rgba(26, 31, 30, .05);
}

* { box-sizing: border-box; }

body {
  margin: 0;
  background: var(--ground);
  color: var(--ink);
  font-family: var(--body);
  font-size: 16.5px;
  line-height: 1.6;
  -webkit-font-smoothing: antialiased;
}

.page {
  max-width: 60rem;
  margin: 0 auto;
  padding: 3.5rem 1.5rem 6rem;
  display: flex;
  flex-direction: column;
  gap: 4.5rem;
}

section { display: flex; flex-direction: column; gap: 1.25rem; }

p, li { max-width: 63ch; }
p { margin: 0; }

h1, h2, h3 { font-family: var(--display); font-weight: 600; text-wrap: balance;
  margin: 0; line-height: 1.15; }
h1 { font-size: clamp(2.1rem, 5.5vw, 3.1rem); letter-spacing: -.015em; }
h2 { font-size: clamp(1.45rem, 3.2vw, 1.9rem); letter-spacing: -.01em; }
h3 { font-size: 1.12rem; }

.eyebrow {
  font-family: var(--data);
  font-size: .7rem;
  letter-spacing: .18em;
  text-transform: uppercase;
  color: var(--faint);
  margin: 0 0 .35rem;
}

.lede { font-family: var(--display); font-size: clamp(1.1rem, 2.4vw, 1.3rem);
  line-height: 1.5; color: var(--ink); max-width: 46ch; }

.dim { color: var(--dim); }
strong { font-weight: 650; }
em.term { font-style: normal; font-family: var(--data); font-size: .92em;
  color: var(--dim); }

code { font-family: var(--data); font-size: .88em; background: var(--panel);
  border: 1px solid var(--rule); border-radius: 4px; padding: .06em .32em; }

a { color: inherit; text-underline-offset: .18em; }

/* ---------- header ---------- */

.masthead { display: flex; flex-direction: column; gap: 1.75rem; }
.masthead .rule { height: 1px; background: var(--rule-strong); }

.stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(8.5rem, 1fr));
  gap: 1px;
  background: var(--rule);
  border: 1px solid var(--rule);
}
.stat { background: var(--ground); padding: .9rem 1rem; }
.stat b { display: block; font-family: var(--data); font-size: 1.6rem;
  font-variant-numeric: tabular-nums; font-weight: 500; letter-spacing: -.02em; }
.stat span { display: block; font-size: .78rem; color: var(--dim);
  line-height: 1.35; margin-top: .15rem; }
.stat.good b { color: var(--agree); }

/* ---------- frame gallery ---------- */

.gallery {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(11rem, 1fr));
  gap: .75rem;
}
.card {
  background: var(--panel);
  border: 1px solid var(--rule);
  border-radius: 3px;
  padding: .75rem .8rem .65rem;
  box-shadow: var(--shadow);
  display: flex;
  flex-direction: column;
  gap: .5rem;
}
.card svg { width: 100%; max-width: 128px; height: auto; display: block;
  margin: 0 auto; }
.card .name { font-size: .82rem; line-height: 1.3; }
.card .meta { font-family: var(--data); font-size: .68rem; color: var(--faint);
  letter-spacing: .06em; text-transform: uppercase; }
.card.absent { border-style: dashed; border-color: var(--rule-strong); }
.card.absent .meta { color: var(--accent); }

.legend { display: flex; flex-wrap: wrap; gap: 1.25rem; font-size: .8rem;
  color: var(--dim); align-items: center; }
.swatch { display: inline-flex; align-items: center; gap: .4rem; }
.swatch i { width: 1.4rem; height: 3px; border-radius: 2px; display: block; }

/* ---------- matrix ---------- */

.scroll { overflow-x: auto; padding-bottom: .5rem; }
table.matrix { border-collapse: collapse; font-family: var(--data);
  font-size: .8rem; }
table.matrix th { font-weight: 400; }
table.matrix thead th { padding: .35rem 0 .45rem; vertical-align: bottom; }
table.matrix thead th svg { width: 42px; height: 49px; display: block;
  margin: 0 auto; }
table.matrix thead th .caption { display: none; }
table.matrix th.row { text-align: right; padding: 0 .7rem 0 0; color: var(--dim);
  font-family: var(--body); font-size: .78rem; white-space: nowrap; }
table.matrix td { width: 2.1rem; height: 2.1rem; text-align: center;
  border: 1px solid var(--rule); }
table.matrix td.on { background: var(--panel); font-weight: 600;
  box-shadow: inset 0 0 0 100px color-mix(in srgb, var(--ink) 4%, transparent); }
table.matrix td.new { border-color: var(--accent); color: var(--accent);
  box-shadow: inset 0 0 0 100px color-mix(in srgb, var(--accent) 10%, transparent); }
table.matrix td.self { background: var(--rule); border-color: var(--rule); }
table.matrix td.two { color: var(--dim); font-style: italic; font-weight: 400; }

/* ---------- map ---------- */

.map { width: 100%; min-width: 620px; height: auto; display: block;
  margin: .5rem auto; }
.map .edge { stroke-width: 2; opacity: .3; }
.map.unread .edge { opacity: .75; }
.map .edge.lit { opacity: 1; }
.map .arc { fill: none; stroke-width: 1.5;
  stroke-dasharray: 5 4; }
/* Name's plate keeps drawing out from under words and nothing more: no border,
   because line already says where name is. It stops short with round end either
   side (`map.gapAt`), which is same break connection wears where it passes
   underneath, so interruption reads as deliberate without plate having to be
   seen at all. */
.map .arc-plate, .map .edge-plate, .map .name-plate { fill: var(--ground); }
.map .node-plate { fill: var(--panel); stroke: var(--rule); stroke-width: 1; }
.map .node-name { fill: var(--ink); }
.swatch i.arm-left { background: var(--left-deep); }
.swatch i.arm-right { background: var(--right-deep); }

/* ---------- findings ---------- */

.findings { display: flex; flex-direction: column; gap: 1rem; }
.finding {
  background: var(--panel);
  border: 1px solid var(--rule);
  border-left: 3px solid var(--rule-strong);
  border-radius: 0 3px 3px 0;
  padding: 1.1rem 1.25rem;
  display: flex;
  flex-direction: column;
  gap: .6rem;
  box-shadow: var(--shadow);
}
.finding.add { border-left-color: var(--accent); }
.finding.defer { border-left-color: var(--accent-cool); }
.finding.tidy { border-left-color: var(--rule-strong); }
.finding .head { display: flex; flex-wrap: wrap; align-items: baseline;
  gap: .6rem; }
.finding h3 { flex: 1 1 18rem; }
.chip {
  font-family: var(--data); font-size: .64rem; letter-spacing: .14em;
  text-transform: uppercase; color: var(--dim);
  border: 1px solid var(--rule-strong); border-radius: 100px;
  padding: .18rem .55rem; white-space: nowrap;
}
.finding .do { font-size: .88rem; color: var(--dim); border-top: 1px solid var(--rule);
  padding-top: .6rem; }
.finding .do b { color: var(--ink); font-weight: 600; }

blockquote {
  margin: 0; padding: .1rem 0 .1rem 1.1rem;
  border-left: 2px solid var(--rule-strong);
  font-family: var(--display); font-style: italic; color: var(--dim);
  max-width: 58ch;
}

/* ---------- q&a ---------- */

.qa { display: flex; flex-direction: column; gap: 2rem; }
.qa > div { display: flex; flex-direction: column; gap: .75rem; }
.answer { font-weight: 600; }

/* ---------- small tables ---------- */

table.plain { border-collapse: collapse; font-size: .88rem; width: 100%;
  max-width: 40rem; }
table.plain th, table.plain td { text-align: left; padding: .45rem .8rem .45rem 0;
  border-bottom: 1px solid var(--rule); vertical-align: baseline; }
table.plain thead th { font-family: var(--data); font-size: .68rem;
  letter-spacing: .12em; text-transform: uppercase; color: var(--faint);
  font-weight: 400; border-bottom-color: var(--rule-strong); }
table.plain td.num { font-family: var(--data); font-variant-numeric: tabular-nums;
  white-space: nowrap; }

/* ---------- experiment ---------- */

.experiment { display: grid; gap: 1px; background: var(--rule);
  border: 1px solid var(--rule); grid-template-columns: repeat(auto-fit, minmax(11rem, 1fr)); }
.cell { background: var(--panel); padding: .9rem 1rem; display: flex;
  flex-direction: column; gap: .3rem; }
.cell .label { font-family: var(--data); font-size: .95rem; }
.cell .a { font-size: .78rem; color: var(--left); }
.cell .b { font-size: .78rem; color: var(--right); }

.build { display: grid; gap: 1px; background: var(--rule); border: 1px solid var(--rule);
  grid-template-columns: repeat(auto-fit, minmax(15rem, 1fr)); }
.build > div { background: var(--panel); padding: 1rem 1.1rem; }
.build h3 { font-size: .95rem; margin-bottom: .3rem; }
.build p { font-size: .85rem; color: var(--dim); }
pre { font-family: var(--data); font-size: .8rem; background: var(--panel);
  border: 1px solid var(--rule); padding: .9rem 1rem; overflow-x: auto;
  margin: 0; border-radius: 3px; line-height: 1.7; }

footer { border-top: 1px solid var(--rule-strong); padding-top: 1.25rem;
  font-size: .82rem; color: var(--faint); }

@media (prefers-reduced-motion: no-preference) {
  .reveal { animation: rise .5s ease-out both; }
  @keyframes rise { from { opacity: 0; transform: translateY(6px); } }
}
</style>

<div class="page">

<header class="masthead reveal">
  <div>
    <p class="eyebrow">Ontology review &middot; dance ontology</p>
    <h1>{{frames}} frames, {{moves}} moves, and three things left to settle</h1>
  </div>
  <p class="lede">Your <code>base</code> sheet was rebuilt from first principles
  and then checked against itself. The hand-to-hand half of it is complete and
  correct &mdash; every cell, the right primitive, and no move missing.</p>
  <div class="rule"></div>
  {{stats}}
</header>

<section>
  <div>
    <p class="eyebrow">The state space</p>
    <h2>Every frame two facing bodies can hold, hand to hand</h2>
  </div>
  <p>A <strong>frame</strong> is what each of the lead's hands holds, plus which
  arm lies on top where the forearms overlap. Two laws close it: a hand of the
  follow is held by at most one hand of the lead, and an arm order is recorded
  exactly where the forearms overlap. That is the whole state space.</p>
  {{gallery}}
  <div class="legend">
    <span class="swatch"><i style="background: var(--left-deep)"></i> lead&rsquo;s Left arm</span>
    <span class="swatch"><i style="background: var(--right-deep)"></i> lead&rsquo;s Right arm</span>
    <span class="dim">Seen from above &middot; lead at the bottom in squares,
    follow at the top in circles, each with a chevron for the way they face
    &middot; a connection goes <em>round</em> a body rather than through one,
    so a crossed hold is drawn crossing</span>
  </div>
  <p><strong>Crossing is derived, not listed.</strong> Facing partners are in
  mirror, so the lead's Left faces the follow's <em>right</em>. A connection is
  parallel when it joins opposite-named hands and crossed when it joins
  same-named hands. Two connections overlap only when both cross &mdash; which
  happens for exactly one pair of holds. That is why
  <em class="term">Left-to-left and Right-to-right</em> has an over/under
  distinction and <em class="term">Left-to-right and Right-to-left</em> does not,
  and your sheet already has it exactly that way. Nothing has to remember the
  rule; it falls out of who faces whom.</p>
</section>

<section>
  <div>
    <p class="eyebrow">The shape of it</p>
    <h2>Every frame, and every move between them</h2>
  </div>
  <p>Each row holds one more connection than the row below, so the direction of
  a move is readable from the drawing: a step up the page is a
  <code>collect</code> and a step down is a <code>drop</code>. The tower is
  built upwards &mdash; <code>free</code> at its foot, both hands held at its
  head &mdash; because a collect builds the frame up and a drop lets it fall.
  So a line says three things and no more: the direction, in which way up it
  runs; the hand of the follow it takes or lets go of, in the word written on
  it &mdash; and that word is in the follow's own colour, the plain shade; and
  which of the lead's arms does it, in the ink the line and the rest of the name
  are written in &mdash; the deep shade, because the lead is the one acting. So
  a name runs deep into plain, the same way the connection it makes does.
  Where a name lies across its own line the line is cut for it, round-ended
  either side, so the break reads as a name put there rather than as a line
  stopping.</p>
  {{arms}}
  <div class="scroll">
    {{map}}
  </div>
  <p>One line stands for two moves, because every move reverses; twenty moves
  are ten lines. The dashed curves are the compounds, drawn apart from the lines
  because they are not moves &mdash; a <code>place</code> is the two ways in and
  out of <em class="term">free</em> taken together, and a <code>cut</code> is the
  two ways in and out of a single hold.</p>
  <p>The picture also shows the ontology has no dead ends and no islands: from
  any frame you can reach any other, and the longest way round is
  {{diameter}} moves.</p>
</section>

<section>
  <div>
    <p class="eyebrow">The verdict</p>
    <h2>Every cell you filled in is the right one</h2>
  </div>
  <p>{{checkable}} of your {{cells}} cells hold between two hand-to-hand frames.
  All {{checkable}} name exactly what the model derives independently &mdash;
  {{primitive_cells}} of them a primitive, {{compound_cells}} of them one of the
  two compounds &mdash; and together they are <em>every</em> move that exists
  between the {{named}} states they name. Nothing missing, nothing spare. For a
  hand-written 9&times;9 matrix that is not a small thing.</p>
  <div class="scroll">
    {{matrix}}
  </div>
  <p class="dim" style="font-size: .85rem">Rows are the frame danced from,
  columns the frame danced to. {{legend}}.
  Outlined cells are moves the model derives that your sheet has no row for
  &mdash; every one of them touches <em class="term">free</em>. Faded cells are
  the compounds.</p>

  <h3>{{primitive_count}} primitives, not six</h3>
  {{primitives}}
  <p>Your vocabulary marks two of its six helpers with an asterisk, and gives
  each the same shape: <em class="term">place*</em> is &ldquo;collect then
  drop&rdquo;, <em class="term">cut*</em> is &ldquo;drop then collect&rdquo;,
  both keeping contact through a trace &mdash; <code>cut</code> with an
  obstruction in the way, <code>place</code> without. The asterisks are right. Neither is a
  unit &mdash; each is two moves that a lead thinks of as one, which is worth a
  name but not a place in the alphabet.</p>
  <p>Of the four left, <code>flick</code> changes no frame, so it is a manner of
  <code>drop</code> rather than a helper of its own; and
  <code>trace</code>/<code>slide</code> has nothing to do here at all, because it
  slides a hand <em>along</em> the partner and the space between the follow's two
  hands is empty air. It comes back with the body, below. Two primitives are
  left, and they are the two that change what is held.</p>

  <h3>{{compound_count}} compounds worth naming</h3>
  {{compounds}}
  <p>The difference between them is only whether the other arm is in the way. A
  <code>place</code> has a clear path, so the hands can overlap on the way past
  and the couple never quite lets go. A <code>cut</code> does not, so the arm
  must be released and re-taken on the far side of the one obstructing it
  &mdash; which is why it is the only way between the two crossing orders.</p>
</section>

<section>
  <div>
    <p class="eyebrow">Outstanding &middot; in order of size</p>
    <h2>Three things left to settle</h2>
  </div>
  <div class="findings">

    <div class="finding add">
      <div class="head">
        <h3>1. There is no <em class="term">free</em> &mdash; and it is
        {{free_moves}} of the {{moves}} moves</h3>
        <span class="chip">add a row</span>
      </div>
      <p><em class="term">free</em> is the frame with nothing held: four free
      hands, which is where the name comes from. It is deliberately
      <em>not</em> called <em class="term">open</em>, because you and every
      other dancer already use &ldquo;open position&rdquo; for something else
      &mdash; the hand-to-hand frame, which this ontology calls
      <em class="term">Left-to-right and Right-to-left</em>. Naming the empty
      frame <em class="term">open</em> would have put the two under one word.</p>
      <p>Every single-hold state in your sheet has a <code>drop</code> that leads
      nowhere, because a frame with no connection is not in the sheet. Without it
      the matrix is not closed under <code>drop</code>, which means the sheet
      cannot express &ldquo;let go&rdquo;.</p>
      <p>It matters more now that <code>place</code> is two moves rather than
      one: every hand-off in your sheet &mdash; all four <em
      class="term">pass</em> cells &mdash; is a drop and a collect, and the frame
      in between the two is precisely <em class="term">free</em>. The sheet
      names four routes through a state it does not have.</p>
      <p class="do"><b>Do:</b> add one row and one column. Four collects out,
      four drops in, and the graph closes.</p>
    </div>

    <div class="finding defer">
      <div class="head">
        <h3>2. <em class="term">closed</em> and <em class="term">half-closed</em> are not
        hand positions</h3>
        <span class="chip">{{deferred}} cells depend on it</span>
      </div>
      <p>These two are the only states in your sheet that are not hand-to-hand,
      and the cells reaching them say what they are:</p>
      <blockquote>half-closed &mdash;slide&rarr; Right to left<br>
      closed &mdash;slide&rarr; Left-to-right and Right-to-left</blockquote>
      <p>A <code>slide</code> keeps contact, and contact can only travel along a
      body &mdash; there is no path from one of the follow's hands to the other.
      So in both cells the lead's right hand must <em>start on the follow's
      body</em> and slide down the arm it is already touching to reach the
      follow's left hand. That is the classic closed hold: left hand to the follow's right,
      right hand on the follow's back.</p>
      <p>Reading them the way <code>vocabulary</code> does instead &mdash;
      <em class="term">half-closed</em> = <em class="term">Left to right</em>,
      <em class="term">closed</em> = <em class="term">Left-to-left and
      Right-to-right</em> &mdash; makes them duplicates of rows you already have,
      and contradicts six of your own cells.</p>
      <p class="do"><b>Do:</b> hold them out until the body vocabulary lands with
      rotation. They are not lost, they are queued &mdash; along with
      <code>trace</code>, which needs the same thing.</p>
    </div>

    <div class="finding tidy">
      <div class="head">
        <h3>3. Two words have drifted between the sheets</h3>
        <span class="chip">naming</span>
      </div>
      <p><code>base</code> uses <em class="term">slide</em> and
      <em class="term">pass</em>. <code>vocabulary</code> defines
      <em class="term">trace</em> and <em class="term">place</em>, and never uses
      the other two. They are the same pairs &mdash; pick one word each.</p>
      <p>Separately: <em class="term">Left-to-left around Right-to-right</em>
      sits in the same variant list as <em class="term">&hellip; over
      &hellip;</em>. <strong>Over</strong> is part of the state &mdash; which arm
      is on top. <strong>Around</strong> is a wrap, a modifier that rotation
      produces. Keep them in one list and the position list grows every time an
      arm does something.</p>
      <p class="do"><b>Do:</b> one word per primitive, and move
      <em class="term">around</em> out of the position variants and into the
      modifiers.</p>
    </div>

  </div>
  <h3>What the audit prints</h3>
  {{audit}}
</section>

<section>
  <div>
    <p class="eyebrow">Your notes</p>
    <h2>The three questions in the margins</h2>
  </div>
  <div class="qa">

    <div>
      <blockquote>Unsure if it is correct to either separate or combine these
      positions? I'm leaning heavily towards them being the same thing. Perhaps I
      need a clearer definition of what a frame position is.</blockquote>
      <p class="answer">One position, two states. Keep both readings.</p>
      <p>A <strong>frame position</strong> is which hands hold what &mdash;
      <em class="term">Left-to-left and Right-to-right</em>. It is what you call
      out on the floor. A <strong>frame</strong> is a position plus the arm
      order. It is what the state machine moves between.</p>
      <p>The test is whether a dancer can pass between them for free. They
      cannot: going from over-Left to over-Right takes a <code>cut</code>. Merge
      them and the machine offers a move the arms forbid; name them separately
      everywhere and you report a new position every time an arm changes height.
      In the code this costs one function &mdash; <code>describe</code> gives the
      state, <code>position</code> gives the class.</p>
    </div>

    <div>
      <blockquote>Technically you can wrap around neck or torso&hellip; possibly
      can have lower and upper wrap as separate frame modifiers?</blockquote>
      <p class="answer">No &mdash; the level you already record does it.</p>
      <p>Your own definitions say a low lock is behind the back and a high lock
      is at the shoulder of the same arm; a low wrap crosses under the other arm
      and a high wrap over it. So the place on the body is <em>derived</em> from
      modifier and level rather than named separately:</p>
      <table class="plain">
        <thead><tr><th>Modifier</th><th>Level</th><th>Lands on</th></tr></thead>
        <tbody>
          <tr><td>wrap</td><td>low</td><td>torso</td></tr>
          <tr><td>wrap</td><td>high</td><td>neck</td></tr>
          <tr><td>lock</td><td>low</td><td>waist, behind the back</td></tr>
          <tr><td>lock</td><td>high</td><td>shoulder</td></tr>
        </tbody>
      </table>
      <p>Two modifiers &times; two levels, not four modifiers. The same
      vocabulary of body places also serves the <code>cut</code> variants you
      already list &mdash; wrist, torso, neck.</p>
    </div>

    <div>
      <blockquote>Technically there's also Left-to-all and Right-to-all; I think
      I'll leave them out of this ontology.</blockquote>
      <p class="answer">Agreed &mdash; and the ambiguity cuts both ways.</p>
      <p>One lead hand holding both of the follow's hands is a hand joined to two
      things, which is an ambiguous lead and is also what would make the state
      space stop being countable. The law that rules it out is symmetric, so it
      rules out the mirrored case too: two lead hands holding one hand of the
      follow.</p>
      <p>That second case is not hypothetical &mdash; it is the moment a
      <code>place</code> passes through if the couple never lets go. So the model
      routes a hand-off through <em class="term">free</em> instead: let go, take
      again. Keeping contact through it is a quality of the leading, which is
      exactly what your note means by &ldquo;maintaining a connection via a
      trace&rdquo;. The frames either side are the same either way.</p>
    </div>

  </div>
</section>

<section>
  <div>
    <p class="eyebrow">Per your call</p>
    <h2>The body enters once, and it enters at rotation</h2>
  </div>
  <p>A hand resting on the partner is now out of the frame entirely. It earns its
  place in exactly two ways, and both of them are about turning:</p>
  <table class="plain">
    <thead><tr><th>What it does</th><th>Why</th></tr></thead>
    <tbody>
      <tr><td><strong>Blocks the turn</strong></td><td>an arm already around a
      partner has no twist left to give &mdash; which is precisely why a turn out
      of closed position needs the right hand to leave the back first</td></tr>
      <tr><td><strong>Catches a wound arm</strong></td><td>waist, torso,
      shoulder, neck: the places a <code>wrap</code> or a <code>lock</code> is
      named by, per the table above</td></tr>
    </tbody>
  </table>
  <p>So one body vocabulary, introduced once in the rotation layer, serves the
  two deferred states, the wraps, the locks, and the <code>cut</code> variants at
  the same time. Nothing about it touches the eight frames.</p>
</section>

<section>
  <div>
    <p class="eyebrow">Rotation</p>
    <h2>What follows for free, and what needs measuring</h2>
  </div>
  <p>The twelve turn sheets are empty, so this is a proposal rather than a
  reading. The quantity a turn adds is <strong>twist</strong>: how far the
  follow's body has turned relative to the lead's. It is one number for the
  couple, not one per arm, because both bodies are rigid and both arms see the
  same relative rotation.</p>

  <h3>Two things that need no measurement at all</h3>
  <p><strong>A rotation of the whole couple stores no twist.</strong> It is why
  you can travel round the floor without unwinding &mdash; and why a model that
  added up each dancer's turns separately would be wrong.</p>
  <p><strong>The parity of the twist re-reads the whole base matrix.</strong> At
  half a turn the follow's back is to the lead, the follow's left hand is now on
  the lead's left, and every connection that was crossed is parallel. The frames do
  not change; the way they are read does. That is one function, not a second
  matrix.</p>

  <h3>Three numbers that do</h3>
  <p>From the one datum available &mdash; <em>&ldquo;if you're hand to hand you
  can only do 1 full rotation comfortably&rdquo;</em>:</p>
  <table class="plain">
    <thead><tr><th>What joins the bodies</th><th>Capacity</th><th>Why</th></tr></thead>
    <tbody>
      <tr><td>one hand-to-hand connection</td><td class="num">1 turn</td>
        <td>both dancers share the twist across two arms</td></tr>
      <tr><td>two hand-to-hand connections</td><td class="num">&frac12; turn</td>
        <td>the arms form a loop and bind</td></tr>
      <tr><td>a hand on the body</td><td class="num">none</td>
        <td>the arm is already around the partner</td></tr>
    </tbody>
  </table>
  <p>Three numbers, and they already predict three things that match the floor: a
  wrap is led from a two-hand hold and a lock from a one-hand hold; a turn out of
  closed needs the back hand to leave first; and a full turn on two hands is not
  comfortable.</p>

  <h3>The four cells worth dancing</h3>
  <p>Your <code>rotations</code> sheet has two filled cells, both for
  <em class="term">Left to left</em> held low: half a turn left gives a
  <em class="term">wrap</em>, a full turn right gives a
  <em class="term">lock</em>. Two different rules fit both cells &mdash;
  <span style="color: var(--left)">magnitude only</span> (one half-turn wraps,
  two lock) and <span style="color: var(--right)">direction decides</span> (one
  way carries the arm across the front and wraps, the other behind the back and
  locks, at either size). They disagree about exactly four cells nobody has
  filled in:</p>
  <div class="experiment">
    <div class="cell"><span class="label">left@0.5</span>
      <span class="a">magnitude &rarr; wrap</span><span class="b">direction &rarr; wrap</span></div>
    <div class="cell"><span class="label">left@1</span>
      <span class="a">magnitude &rarr; lock</span><span class="b">direction &rarr; wrap</span></div>
    <div class="cell"><span class="label">right@0.5</span>
      <span class="a">magnitude &rarr; wrap</span><span class="b">direction &rarr; lock</span></div>
    <div class="cell"><span class="label">right@1</span>
      <span class="a">magnitude &rarr; lock</span><span class="b">direction &rarr; lock</span></div>
  </div>
  <p>All four are <em class="term">Left to left</em>, held low. Dance them, write
  down what the arm does, and the twelve turn sheets stop being twelve matrices
  to fill in and become one function of three numbers. That is worth more than
  the other 760 empty cells put together.</p>
</section>

<section>
  <div>
    <p class="eyebrow">What is running</p>
    <h2>The model, the validator, and the laws</h2>
  </div>
  <div class="build">
    <div>
      <h3>One state, one relation</h3>
      <p>A move exists between two frames exactly when the difference between
      them is one primitive. The names, the routes, the app and the audit are all
      derived from that &mdash; there is no table of moves to maintain.</p>
    </div>
    <div>
      <h3>A validator, not a toy</h3>
      <p>The browser app shows the frame you are in, every frame one move away,
      and every frame that is not &mdash; with how far away it is. Only what is
      offered can be clicked, so a move the ontology does not derive cannot be
      danced.</p>
    </div>
    <div>
      <h3>Laws, not examples</h3>
      <p>{{laws}} tests over all {{pairs}} ordered pairs of frames:
      reversibility, mirror symmetry, one law per primitive, full connectivity,
      and every cell of your sheet checked against the model.</p>
    </div>
  </div>
  <pre>síncopa/dance_ontology/
  src/dance_ontology/frame.nim       frames, their laws, their names, reflection
  src/dance_ontology/transition.nim  the four primitives and the routes between frames
  src/dance_ontology/diagram.nim     one drawing of a frame, for everything that shows one
  src/dance_ontology/workbook.nim    your base sheet as data, and the audit against it
  src/dance_ontology/rotation.nim    twist, capacity, wraps and locks &mdash; provisional
  app/app.nim, app/shell.nim         the validator: its script and its page shell
  tools/review.nim                   writes this page from the model
  tools/review_prose.nim             the prose of this page; every number is a marker
  build/review/review.html           this page, rebuilt by <code>make pages</code>
  build/review/frames/*.svg          one picture per frame, for anything that is not HTML

make check     # the laws, including that this page renders whole
make pages     # rebuild the validator, this page and the frame pictures</pre>
  <p class="dim" style="font-size: .88rem">Nim throughout, compiled to JavaScript
  for the browser.</p>
</section>

<footer>
  Every number on this page is also a test, and the page is rebuilt from the
  model by <code>make pages</code>.
</footer>

</div>
"""
