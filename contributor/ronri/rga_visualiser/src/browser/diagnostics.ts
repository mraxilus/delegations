// Diagnostics section, its canvases and curves; not Nim because these reach browser APIs Nim's JS
//   backend does not express.
//   Presentation alone: every join, meet, pick, drag and camera move is computed by
//   bridge, compiled from same modules desktop draws through (Article II.9).
//   Concatenated into page in order `tools/build.nim` names; see its `SCRIPTS`.

/* ---------------------------------------------------------------------- */
/* Diagnostics: browser-appropriate stand-ins for desktop build's own     */
/* arena/frame-time section -- see `bridge.nim`'s own doc comment   */
/* for why numbers differ in kind. Drawer states none of this:            */
/* reader opening diagnostics section wants numbers, not essay.             */
/* ---------------------------------------------------------------------- */

const FRAMES_HISTORY = 240;
const history_frame = new Array(FRAMES_HISTORY).fill(16.6);
let index_history_frame = 0;
let time_frame_last = performance.now();
const sparkline = elementById<HTMLCanvasElement>('sparkline');
const context_sparkline_found = sparkline.getContext('2d');
if (context_sparkline_found === null) throw new Error('Sparkline canvas has no context.');
const context_sparkline: CanvasRenderingContext2D = context_sparkline_found;
const size_sparkline = sizeObserved(sparkline, () => askSlowPass(false, true, false, false));
const diagnostic_frame_time = elementById('diagnostic-frametime');
const diagnostic_slowest = elementById('diagnostic-slowest');
const diagnostic_slowest_split = elementById('diagnostic-slowest-split');
const diagnostic_heap = elementById('diagnostic-heap');
const diagnostic_pool = elementById('diagnostic-pool');
const grid_pool = elementById<HTMLCanvasElement>('pool-grid');
grid_pool.title = nimWording(Wording.TipDiagPool);
const context_pool = grid_pool === null ? null : grid_pool.getContext('2d');
// Scene revision grid was last drawn at; -1 until it has been drawn once. Grid.
//   is picture of which handles are occupied and in what ink, so it changes exactly when
//   scene does -- see `scene.revision`, same counter frame hold reads. Its own
//   geometry joins key because canvas cleared by resize has to be redrawn whatever
//   scene did, and because section opens onto canvas that had no size at all.
let revision_pool_last = -1;
let ratio_pool_last = 0;
// Redraw owed for canvas's own reasons: resized, or never drawn.
//   Set by observer below, which fires once when it starts watching -- what makes first
//   draw happen.
let is_pool_stale = true;
// What last draw actually chose, for check to read rather than re-derive.
//   derivation is thing being checked, so test that repeated it would agree with
//   itself no matter what reached canvas.
let geometry_pool_drawn = { cell: 0, gap: 0, columns: 0, rows: 0, height: 0 };
// **One square per handle, wrapped**, at largest size that keeps whole grid inside.
//   block rather than page. Cell cannot be constant: at 1,024 handles six pixels with
//   gap is 53 columns of 20 rows and 139px tall, and at 10,080 same cell is 191 rows
//   and over 1,300px -- which is not grid reader scans, it is scroll. So size is
//   chosen against capacity and measured width, largest first, and gap goes
//   before cell does: below four pixels one-pixel gap is half strip.
//   At 10,080 handles in 371px drawer this lands on 2px cells, 185 columns by 55 rows and
//   110px tall -- density map rather than set of squares, which is honest reading at
//   ten thousand.
const CELLS_POOL: Array<[number, number]> = [[6, 1], [5, 1], [4, 1], [3, 0], [2, 0], [1, 0]];
const HEIGHT_POOL_MAX = 150;
// CSS colour per packed triple, so palette that cycles is converted dozen times.
//   rather than thousand. Cleared with nothing: palette is fixed, so it converges.
const css_pool = new Map();
// Width last draw laid grid out for; `NaN` before first, equal to nothing.
let width_pool_drawn = NaN;
// Watched in its own box rather than window's:
//   drawer is fixed-width column on wide screen and full-width sheet on narrow one, and
//   either can change without window doing so. Width alone: draw sets canvas's own
//   height, and observer answering that with second identical draw was 4 ms for nobody.
const size_pool = sizeObserved(grid_pool, () => {
  if (size_pool.width !== width_pool_drawn) is_pool_stale = true;
});

// Keep one ring per step of drawing process.
//   Diagnostics tab can then show where frame actually went rather than one opaque
//   total.
//   Bridge reports its own three phases on FrameData (build = furniture + scene +
//   flatten, timed inside nimBuildFrame where only it can see them); this side times
//   what only it can see: GL upload+draw, SVG overlay, selection menu, and low-cadence
//   UI block.
//   Rings rather than latest value, so each row can show rolling median beside
//   instantaneous number.
//     Single frame's reading flickers too fast to read, and median is what reader means
//     by "how long does this step take".
const PHASES_DIAGNOSTIC: Array<[string, string]> = [
  ['build', 'diagnostic-build'], ['camera', 'diagnostic-camera'],
  ['furniture', 'diagnostic-furniture'],
  ['grid', 'diagnostic-grid'], ['axes', 'diagnostic-axes'], ['scene', 'diagnostic-scene'],
  ['points', 'diagnostic-points'], ['lines', 'diagnostic-lines'], ['planes', 'diagnostic-planes'],
  ['sky', 'diagnostic-sky'], ['preview', 'diagnostic-preview'], ['selected', 'diagnostic-selected'],
  ['matrix', 'diagnostic-matrix'],
  ['flatten', 'diagnostic-flatten'],
  ['unaccounted', 'diagnostic-unaccounted'],
  // Second cut, not stages: these re-divide very milliseconds above them.
  ['placing', 'diagnostic-placing'], ['emitting', 'diagnostic-emitting'],
  ['hover', 'diagnostic-hover'], ['upload', 'diagnostic-upload'], ['overlay', 'diagnostic-overlay'],
  ['ui', 'diagnostic-ui'], ['idle', 'diagnostic-idle'],
  // Third cut: browser's main-thread share of `idle`; see `markRendered`.
  ['render', 'diagnostic-render'],
];
// Rows that re-divide time already counted elsewhere. They must stay out of every sum.
//   -- idle derivation below, and cost tint's own denominator -- or frame would
//   appear to have spent its drawing twice.
const PHASES_CUT_DIAGNOSTIC = ['placing', 'emitting', 'render'];
// Name phases nothing else contains.
//   Their sum is everything this page spent on frame, and rest of frame is `idle`
//   below.
//   `build` holds bridge's own three, and those hold scenery halves and object kinds,
//   so counting any of them here would count same milliseconds twice.
const PHASES_TOP_DIAGNOSTIC = ['build', 'hover', 'upload', 'overlay', 'ui'];
// Rows that carry count beside their time, and ring each count is written to.
//   Time alone cannot tell "one of these is expensive" from "there are many of them",
//   which is whole question reader opens this branch to answer.
const COUNTS_DIAGNOSTIC: Record<string, keyof FrameData> = {
  grid: 'count_grid_segments',
  points: 'count_points', lines: 'count_lines', planes: 'count_planes',
  sky: 'count_sky', preview: 'count_preview', selected: 'count_selected',
};
// Every phase ring and element is keyed by phase name, which `PHASES_DIAGNOSTIC`
//   and `COUNTS_DIAGNOSTIC` supply; maps are open rather than fixed shapes, since
//   that table is what says which phases exist.
const count_phase: Record<string, number> = {};
let count_points_culled = 0; // Points skipped this frame for lying outside view.
const history_phase: Record<string, Float64Array> = {};
// **Whether phase ran is kept beside its time, never inside it.** Sentinel in.
//   value's own range was doing that job, and duration has no room for one: every mobile
//   browser coarsens and jitters `performance.now` against timing attacks, so
//   sub-millisecond step can measure as zero or below, and real reading then becomes
//   indistinguishable from "never ran". That is precisely what left every sub-millisecond
//   row of tree em dash on phone while six-millisecond ones read fine.
const written_phase: Record<string, Uint8Array> = {};
const element_phase: Record<string, HTMLElement | null> = {};
const element_row: Record<string, Element | null> = {};
const element_tally: Record<string, Element | null> = {};
// Read phase's own ring, which loop below builds for every name `PHASES_DIAGNOSTIC`
//   carries; asking for any other name is defect, named here rather than read as nothing.
function ringOf(name: string): Float64Array {
  const ring = history_phase[name];
  if (ring === undefined) throw new Error('No ring for phase `' + name + '`.');
  return ring;
}

function writtenOf(name: string): Uint8Array {
  const written = written_phase[name];
  if (written === undefined) throw new Error('No written flags for phase `' + name + '`.');
  return written;
}


for (const [name, id] of PHASES_DIAGNOSTIC) {
  history_phase[name] = new Float64Array(FRAMES_HISTORY);
  written_phase[name] = new Uint8Array(FRAMES_HISTORY);
  element_phase[name] = elementIfPresent(id);
  // Whole row as well as its number, so row can be tinted entire. `closest` rather.
  //   than `parentElement`: leaf's value sits in plain div and parent's in button,
  //   and both carry `.diagnostic-line`.
  const element = element_phase[name] ?? null;
  element_row[name] = element === null ? null : element.closest('.diagnostic-line');
  // And slot beside row's own name where its count goes, on rows that have one.
  //   Written into rather than label being rewritten, so label's words stay in
  //   markup and this file never holds second copy of them to keep in step.
  const row = element_row[name] ?? null;
  element_tally[name] = row === null ? null : row.querySelector('.diagnostic-tally');
}
for (const name in COUNTS_DIAGNOSTIC) count_phase[name] = 0;
function recordPhaseTime(name: string, delta_milliseconds: number) {
  // Share frame ring's own index, advanced once per frame by recordFrameTime.
  //   Every ring then lines up frame for frame; UI phase only runs one frame in several
  //   and leaves its other slots unwritten, which readings below skip.
  if (!Number.isFinite(delta_milliseconds)) return; // Nothing measured; leave it absent.
  // Clamped at zero: negative elapsed time is artefact of coarsened clock, not.
  //   duration, and honest reading of it is "too short to measure".
  ringOf(name)[index_history_frame] =
    delta_milliseconds > 0 ? delta_milliseconds : 0;
  writtenOf(name)[index_history_frame] = 1;
}
// Add to phase's slot rather than replace it:
//   `ui` is written more than once per frame -- tick inside frame's callback, glide
//   redraw beside it, slow pass in idle time after it -- all before `recordFrameTime`
//   closes slot at next frame's start, so every one lands in frame it belongs to.
function addPhaseTime(name: string, delta_milliseconds: number) {
  if (!Number.isFinite(delta_milliseconds)) return; // Nothing measured; leave it as is.
  const at = index_history_frame;
  const ring = ringOf(name), written = writtenOf(name);
  const held = written[at] === 1 ? ring[at] ?? 0 : 0;
  ring[at] = held + (delta_milliseconds > 0 ? delta_milliseconds : 0);
  written[at] = 1;
}

// **How long reading is averaged over, and how often it is rewritten.** Single frame's.
//   number changes faster than anyone can read it, which is what made these rows flicker.
//   200 ms is settling time performance readout is conventionally given: long enough
//   that digits hold still, short enough that stall is still on screen while it is
//   happening. Same span governs averaging and refresh, so number shown is
//   number for interval since last one -- not average over one window
//   sampled on cadence of another.
const MILLISECONDS_WINDOW_READING = 200;
// How many frames back that span reaches, measured in frames' own durations rather.
//   than assumed from frame rate: at 60 fps it is dozen, on labouring phone it is
//   two, and either way it is last 200 ms.
function framesRecent() {
  let spanned = 0;
  for (let i = 0; i < FRAMES_HISTORY; i += 1) {
    spanned += history_frame[(index_history_frame + FRAMES_HISTORY - 1 - i) % FRAMES_HISTORY];
    if (spanned >= MILLISECONDS_WINDOW_READING) return i + 1;
  }
  return FRAMES_HISTORY;
}
// Phase's mean over those frames, skipping ones it did not run in. Mean rather.
//   than latest: whole complaint about latest is that one frame decides it.
function meanPhase(name: string, frames: number) {
  const ring = ringOf(name);
  const written = writtenOf(name);
  let total = 0;
  let count = 0;
  for (let i = 0; i < frames; i += 1) {
    const at = (index_history_frame + FRAMES_HISTORY - 1 - i) % FRAMES_HISTORY;
    if (written[at] === 0) continue;
    total += ring[at] ?? 0;
    count += 1;
  }
  return count === 0 ? null : total / count;
}
// Scratch median borrows rather than allocating: this runs per phase per refresh, and.
//   rows tree can hold grow faster than frames between refreshes do. Filter
//   plus sort built two arrays each time and threw both away.
const scratch_median = new Array(FRAMES_HISTORY);
function medianPhase(name: string) {
  const ring = ringOf(name);
  const written = writtenOf(name);
  let count = 0;
  for (let i = 0; i < FRAMES_HISTORY; i += 1) {
    if (written[i] === 1) { scratch_median[count] = ring[i]; count += 1; }
  }
  if (count === 0) return null;
  // Insertion sort over written part: ring is nearly sorted only by accident, but.
  //   it is small and this beats allocating fresh sorted copy of it every refresh.
  for (let i = 1; i < count; i += 1) {
    const value = scratch_median[i];
    let j = i - 1;
    while (j >= 0 && scratch_median[j] > value) {
      scratch_median[j + 1] = scratch_median[j];
      j -= 1;
    }
    scratch_median[j + 1] = value;
  }
  return scratch_median[count >> 1];
}
// Each row's last median, so 200 ms rows can state one without re-sorting ring that.
//   is four seconds long. Refreshed by `recomputeMedians` on slow pass; `undefined`
//   means never computed, which is not same as `null` -- that is phase which has
//   genuinely never run, and row is left as em dash for it.
const median_phase_last: Record<string, number | null | undefined> = {};
function medianPhaseHeld(name: string) {
  // Ask on spot where nothing is held, or what is held says never ran.
  //   Cheap to ask, and row coming alive between slow passes would otherwise stay em
  //   dash for up to second.
  const held = median_phase_last[name];
  if (held === undefined || held === null) median_phase_last[name] = medianPhase(name);
  return median_phase_last[name];
}
// Re-sort every shown row's median from ring. Rows inside closed node keep theirs:
//   nobody is reading them, and each is 240-entry insertion sort.
function recomputeMedians() {
  for (const [name] of PHASES_DIAGNOSTIC) {
    if (isPhaseShown(name)) median_phase_last[name] = medianPhase(name);
  }
}

// Rows that have children, and whether each is open. **Every one starts closed**:
//   reader opens diagnostics section to see whether frame is slow, and goes looking for
//   which step only once it is. Closed node's rows are skipped by `refreshDiagnostics`
//   entirely, so subtotal nobody is reading costs nothing to keep offering.
//   Nesting is read off markup itself rather than declared here second time:
//   tree's shape used to live in both places, agreeing only by care, and row moved
//   in one without other would silently stop hiding -- or stop updating -- with its
//   branch. DOM is one copy now, and this file only asks it questions.
for (const node of document.querySelectorAll('.diagnostic-node')) {
  // Node's *own* parent row, not descendant's: nested branch puts another.
  //   `.diagnostic-parent` inside this one, and `querySelector` would find that one first.
  const header = node.querySelector(':scope > .diagnostic-parent');
  if (header === null) throw new Error('Diagnostic node carries no header.');
  header.addEventListener('click', () => {
    const is_open = node.classList.toggle('open');
    header.setAttribute('aria-expanded', String(is_open));
  });
  header.setAttribute('aria-expanded', 'false');
}
function isPhaseShown(name: string) {
  // Walk up: row is shown only where every branch holding it is open. Branch's own.
  //   header row starts walk *above* its node -- header is what reader clicks
  //   to open it, so it stays visible while its node is closed.
  const row = element_row[name] ?? null;
  if (row === null) return false;
  let node = row.closest('.diagnostic-node');
  if (node !== null && row.classList.contains('diagnostic-parent')) {
    node = node.parentElement?.closest('.diagnostic-node') ?? null;
  }
  while (node !== null) {
    if (!node.classList.contains('open')) return false;
    node = node.parentElement?.closest('.diagnostic-node') ?? null;
  }
  return true;
}

// **How often frame runs long, over window long enough to answer that.**
//   sparkline holds four seconds and shows *when*; reader chasing stall that happens
//   once minute needs *how often*, which is distribution rather than trace. Kept as
//   rolling window of last `FRAMES_EXCEEDANCE` frames -- about seventeen seconds at
//   60 fps, which is long enough to hold stall and short enough that one ages out again
//   rather than flattening chart for minute -- summarised as share of them at or
//   over each duration.
//   Window is ring of samples *and* histogram of same samples, maintained
//   together: frame entering increments its bucket, frame it evicts decrements
//   one it was in. That keeps per-frame cost couple of array writes -- this runs on
//   every frame, including ones being measured -- and leaves curve single
//   suffix scan over buckets, done only when section is actually open.
const FRAMES_EXCEEDANCE = 1024;
const MILLISECONDS_BUCKET = 0.5; // Fine enough to separate 16.7 ms frame from 17.2.
// **Slowest chart marks**, in frames per second, and reach of.
//   histogram folded from it. Two have to agree or mark is unreachable: axis
//   only ever runs as far as slowest bucket holding frame, so mark past last
//   bucket is skipped by `drawExceedance` on every draw and simply never appears. Adding
//   1 fps line to `MARKS_EXCEEDANCE` alone did exactly that, silently, against
//   histogram that stopped at 128 ms. Folded here so next mark cannot repeat it.
//   Extra bucket is what puts mark *inside* reachable range rather than exactly
//   at its edge.
const RATE_MARK_SLOWEST = 1;
const BUCKETS_EXCEEDANCE =
  Math.ceil((1000 / RATE_MARK_SLOWEST) / MILLISECONDS_BUCKET) + 1;
const history_exceedance = new Float32Array(FRAMES_EXCEEDANCE);
const buckets_exceedance = new Int32Array(BUCKETS_EXCEEDANCE);
let index_exceedance = 0;
let count_exceedance = 0; // Rises to window's own size, then stays there.
const exceedance = elementById<HTMLCanvasElement>('exceedance');
const context_exceedance = exceedance === null ? null : exceedance.getContext('2d');
const size_exceedance = sizeObserved(exceedance, () => askSlowPass(true, false, false, false));
const diagnostic_exceedance = elementById('diagnostic-exceedance');
const label_exceedance_axis = elementById('diagnostic-exceedance-axis');
// Vertical axis's own switch, wired here rather than beside header's chips because.
//   it reads chart it belongs to. Linear by default: chart exists to say what share
//   of session ran at each speed, and proportion reads as proportion on linear
//   axis. Log answers narrower question -- how bad slowest one percent is, which
//   linear squeezes flat against ceiling -- so it is offered rather than assumed.
const toggle_exceedance_log = elementIfPresent('toggle-exceedance-log');
let is_exceedance_log = false;
if (toggle_exceedance_log !== null) {
  toggle_exceedance_log.addEventListener('click', (e) => {
    is_exceedance_log = !is_exceedance_log;
    (e.currentTarget as HTMLElement).classList.toggle('on', is_exceedance_log);
    // Redrawn on spot rather than at diagnostics section's own six-frame cadence:
    //   switch that answers sixth of second late reads as one that did not work.
    drawExceedance();
  });
}

function bucketOf(milliseconds: number) {
  const index = Math.floor(milliseconds / MILLISECONDS_BUCKET);
  // Anything past last bucket lands *in* it rather than being dropped: 300 ms stall.
  //   is most important sample window ever holds, and curve that discarded it
  //   would read as calmer than session actually was.
  return Math.max(0, Math.min(BUCKETS_EXCEEDANCE - 1, index));
}

function recordExceedance(delta_milliseconds: number) {
  if (count_exceedance === FRAMES_EXCEEDANCE) {
    const bucket_leaving = bucketOf(flatAt(history_exceedance, index_exceedance));
    buckets_exceedance[bucket_leaving] = flatAt(buckets_exceedance, bucket_leaving) - 1;
  } else {
    count_exceedance += 1;
  }
  history_exceedance[index_exceedance] = delta_milliseconds;
  const bucket_arriving = bucketOf(delta_milliseconds);
  buckets_exceedance[bucket_arriving] = flatAt(buckets_exceedance, bucket_arriving) + 1;
  index_exceedance = (index_exceedance + 1) % FRAMES_EXCEEDANCE;
}

// Complementary distribution, as share of window per bucket, scanned from.
//   slow end so each entry is "this many frames took at least this long". Written into
//   buffer caller owns so scan allocates nothing on path that runs ten times
//   second; returns how much of it is meaningful.
const shares_exceedance = new Float64Array(BUCKETS_EXCEEDANCE);
function scanExceedance() {
  let running = 0;
  for (let i = BUCKETS_EXCEEDANCE - 1; i >= 0; i -= 1) {
    running += flatAt(buckets_exceedance, i);
    shares_exceedance[i] = count_exceedance === 0 ? 0 : running / count_exceedance;
  }
  return count_exceedance;
}

function recordFrameTime(delta_milliseconds: number) {
  history_frame[index_history_frame] = delta_milliseconds;
  // **Everything page did not spend itself**: waiting on display, and browser's.
  //   own style, layout, paint, compositing and collection. Without it breakdown
  //   accounted for fraction of frame and left rest unexplained, so spike could
  //   not be told from stall in page's own code -- which is first question
  //   reader has. Computed here because this is one moment frame's duration and its
  //   own phases sit in same slot: delta written just above measures frame
  //   whose phases were recorded into this index, and advance below moves past both.
  let spent = 0;
  for (const name of PHASES_TOP_DIAGNOSTIC) {
    if (writtenOf(name)[index_history_frame] === 1) {
      spent += flatAt(ringOf(name), index_history_frame);
    }
  }
  recordPhaseTime('idle', delta_milliseconds - spent);
  recordExceedance(delta_milliseconds);
  index_history_frame = (index_history_frame + 1) % FRAMES_HISTORY;
  // Clear slot phases are about to write into, up front.
  //   Phase that does not run this frame (UI block, held furniture build) then reads as
  //   absent rather than as whatever it cost one ring ago.
  for (const [name] of PHASES_DIAGNOSTIC) writtenOf(name)[index_history_frame] = 0;
}

// How far log axis runs, when reader switches to it: decades from every frame down.
//   to one in thousand, which is as fine as window of thousand frames can resolve.
const DECADES_EXCEEDANCE = 3;
// **Axis follows window, but never closes below slowest mark plus room to.
//   name it.** Fitting it to slowest frame is what makes max readable -- curve
//   reaches 100% exactly there -- and floor is what stops fast session zooming into
//   its own noise: at 30 fps and better axis stands still and mark lines keep
//   their places, so two readings of healthy session compare directly. It is bands
//   that made this affordable: axis that moves is legible when colours and
//   labelled lines say where marks stand regardless of how far it runs.
//   Stated as share of axis slowest labelled mark stands at, not as that
//   mark's own duration. At exactly `1000 / 30` 30 fps line landed on right edge:
//   half pixel outside canvas, and its label flipped to cramped inside-left
//   branch below, alone among marks in reading right to left. Margin has to be
//   share because canvas is responsive -- fixed number of milliseconds buys
//   different number of pixels at every drawer width -- and 14% clears label's own
//   14px threshold down to about 110px canvas.
// What label is haloed against where curve runs through it: drawer's own solid.
//   surface, which is what shows through this canvas, at most of full strength -- enough to
//   part curve around digits, little enough that it reads as ground rather than
//   as box drawn behind them.
const HALO_LABEL_EXCEEDANCE = 'rgba(22, 27, 34, 0.85)';
const SHARE_MARK_LEAST = 0.86;
const MILLISECONDS_AXIS_LEAST = (1000 / 30) / SHARE_MARK_LEAST;
// Frame marks reader actually aims at, each named by rate it is: duration.
//   means nothing to most people and "60" means something to everyone.
//   This list is both marks and colour bands: `bandOfExceedance` indexes it and
//   `colours_exceedance` maps over it. 15 fps entry therefore carries *poor band's
//   own token* on purpose -- it is mark reader asked for, not fifth band. Anything
//   past 33.3 ms is poor whichever side of 66.7 it falls, so curve merely splits into
//   two runs there and strokes them same colour. **Do not tidy repeated token
//   away**: dropping it would either lose mark or invent band. 1 fps entry below is
//   same case second time, and is there for same reason: loading largest size
//   is frame of *seconds*, and chart whose slowest mark is 66.7 ms cannot say how bad
//   that is -- it can only say `past the end`. Mark at 1,000 ms gives spike ruler.
//   Its own consequence, stated rather than discovered: window holding one-second frame
//   stretches axis until 8.3, 16.7 and 33.3 crowd into its leftmost tenth. That is
//   self-limiting, since axis eases back as spike ages out of 1,024-frame
//   window, and it is honest picture of window that really did hold such frame.
//   10 and 5 fps marks fill stretch between 15 and 1, which is where labouring
//   frame actually lands and where axis otherwise ran decade unlabelled. They need no
//   room histogram does not already have: at 100 ms and 200 ms they sit well inside
//   reach `RATE_MARK_SLOWEST` folds. **Kept in ascending order of duration** --
//   `bandOfExceedance` returns first entry reading falls under, so entry out of
//   order would silently mis-band every frame past it.
const MARKS_EXCEEDANCE = [
  { milliseconds: 1000 / 120, label: '120', token: '--speed-fast' },
  { milliseconds: 1000 / 60, label: '60', token: '--speed-good' },
  { milliseconds: 1000 / 30, label: '30', token: '--speed-fair' },
  { milliseconds: 1000 / 15, label: '15', token: '--speed-poor' },
  { milliseconds: 1000 / 10, label: '10', token: '--speed-poor' },
  { milliseconds: 1000 / 5, label: '5', token: '--speed-poor' },
  { milliseconds: 1000 / RATE_MARK_SLOWEST, label: String(RATE_MARK_SLOWEST),
    token: '--speed-poor' },
  { milliseconds: Infinity, label: '', token: '--speed-poor' },
];
// Read once from stylesheet, which is where they are set and tuned; see tokens'.
//   own comment in `shell.html` for how four were screened.
// Resolved once, like colours below: this is redrawn at frame rate while axis.
//   glides, and each draw was asking layout for same font token.
const FONT_EXCEEDANCE = '9px ' +
  (getComputedStyle(document.documentElement).getPropertyValue('--mono').trim() ||
    'monospace');
const colours_exceedance = MARKS_EXCEEDANCE.map((mark) =>
  getComputedStyle(document.documentElement).getPropertyValue(mark.token).trim() ||
    '#00a7a5');
// **Which timing rows are expensive, said in colour.** Twenty-odd numbers down drawer,
//   and nothing in them says which one to look at. Each row's colour answers one question
//   -- what fraction of this frame went here -- read continuously off CET-I1.
//   **Denominator is whole frame, idle included, and ramp spans all of it.**
//   row is drawn at fraction it actually occupies, so scale is absolute: tenth of
//   fast frame and tenth of slow one wear same colour, and curve above says
//   which of two session is in. Shares nest correctly, parent's being sum
//   of its children's, and they sum with `idle` to whole ramp.
// **Where ramp reaches its far end**:
//   row costing this share of frame is drawn in map's last colour.
//   At whole frame far end means step that *is* frame.
const SHARE_RAMP_FULL_DIAGNOSTIC = 1.0;
// **Ramp is walked by ratio, not by difference.** Laid out linearly over whole.
//   frame, every row on comfortable session lands in first two steps and tree
//   reads as one colour: page waiting on display spends most of frame idle, so
//   drawing's own rows are all small fractions and interesting differences between them
//   -- one row ten times another -- are differences far end of scale cannot show.
//   Measured that way at 28.8 ms: costliest row at 12.7% and floor at 0.3% sat 30
//   units of blue apart out of ramp's 131, and rows between them were one colour.
//   On this scale **equal distance along ramp is equal ratio of cost**, which is
//   comparison reader is actually making, and spread no longer depends on whether
//   frame happened to be busy.
//   Knee is where scale stops being logarithmic and goes linear, so row costing
//   nothing has somewhere to sit -- log has no zero. Hundredth of frame is
//   choice: below it row is not one to look at whatever it sits next to.
//   **symlog** proper, linear under knee and logarithmic over it, rather than
//   `log1p` that smooths join. `log1p` is only asymptotically logarithmic, so its
//   decades are not equal -- measured, decade above knee spanned 0.37 of ramp
//   where top one spanned 0.48 -- and equal-ratio-equal-distance promise above is
//   whole point. Seam costs kink in rate at knee and buys exactness.
//   Linear toe is worth **one decade of ramp**, usual convention, which makes
//   whole scale legible as sentence: below hundredth of frame, then hundredth to
//   tenth, then tenth to all of it -- third of ramp each.
const SHARE_RAMP_KNEE_DIAGNOSTIC = 0.01;
const DECADES_RAMP_TREE = Math.log10(SHARE_RAMP_FULL_DIAGNOSTIC / SHARE_RAMP_KNEE_DIAGNOSTIC);
const UNITS_RAMP_TREE = DECADES_RAMP_TREE + 1; // Decades, plus toe's own decade.
function positionRampTree(share: number) {
  // Where share falls along ramp, from nothing at 0 to all of it at whole frame.
  const held = Math.min(Math.max(share, 0), SHARE_RAMP_FULL_DIAGNOSTIC);
  if (held <= SHARE_RAMP_KNEE_DIAGNOSTIC) {
    return held / SHARE_RAMP_KNEE_DIAGNOSTIC / UNITS_RAMP_TREE;
  }
  return (1 + Math.log10(held / SHARE_RAMP_KNEE_DIAGNOSTIC)) / UNITS_RAMP_TREE;
}
// Tree's ramp, from `ramp.nim` through `nimRampTree`:
//   six floats step, row's label rgb then its value rgb.
//   What ramp is -- CET-I1 re-lit to this drawer's own text tones -- and what holds it to that is
//   `tools/check_ramp.nim`; nothing here knows anything about it beyond how to walk it.
const RAMP_TREE: Array<{ label: number[]; value: number[] }> = (() => {
  const flat = nimRampTree();
  const steps: Array<{ label: number[]; value: number[] }> = [];
  for (let at = 0; at < flat.length; at += 6) {
    steps.push({
      label: [flatAt(flat, at), flatAt(flat, at + 1), flatAt(flat, at + 2)],
      value: [flatAt(flat, at + 3), flatAt(flat, at + 4), flatAt(flat, at + 5)],
    });
  }
  return steps;
})();

// Legend bar is ramp **as rows are actually tinted**:
//   across its width sits share, not ramp position, so colours crowd into its left exactly as they
//   do down tree and reader can lay row's colour against it and read share off.
//   Painted by calling same function rows are tinted by, so key that disagreed with tree would have
//   to be bug in one line rather than second declaration left behind.
const STOPS_LEGEND_RAMP = 48;
(() => {
  const bar = elementIfPresent('diagnostic-legend-ramp');
  if (bar === null) return;
  const stops = [];
  for (let i = 0; i <= STOPS_LEGEND_RAMP; i += 1) {
    const share = i / STOPS_LEGEND_RAMP;
    stops.push(`${rampTreeAt(share).label} ${(share * 100).toFixed(1)}%`);
  }
  bar.style.background = `linear-gradient(to right, ${stops.join(', ')})`;
})();

// Read one stop of tree's ramp, which caller has already clamped inside its bounds.
function stopRampTree(index: number): { label: number[]; value: number[] } {
  const stop = RAMP_TREE[index];
  if (stop === undefined) throw new Error('Ramp carries no stop `' + index + '`.');
  return stop;
}


function rampTreeAt(share: number) {
  // Sample ramp at one row's share of frame, interpolating between shipped.
  //   steps so row's colour moves as its cost does rather than stepping between bands.
  //   `check_ramp` measures what interpolating costs against map's full 256 entries.
  const position = positionRampTree(share) * (RAMP_TREE.length - 1);
  const below = Math.min(Math.floor(position), RAMP_TREE.length - 2);
  const fraction = position - below;
  const mix = (first: number[], second: number[]) => rgbToCss([0, 1, 2].map(
    (channel) => flatAt(first, channel) * (1 - fraction)
      + flatAt(second, channel) * fraction));
  return {
    label: mix(stopRampTree(below).label, stopRampTree(below + 1).label),
    value: mix(stopRampTree(below).value, stopRampTree(below + 1).value),
  };
}
// **Axis follows window, but not at window's own speed.** Fitted frame for.
//   frame it snapped: one slow frame widened it, and moment that frame aged out of
//   window it snapped back, so curve jumped about and two glances second apart could
//   not be compared. Two things fix that without going back to fixed axis.
//   *Wait before anything moves.* Extent that differs from what is drawn starts
//   clock, and only difference that stands for `MILLISECONDS_AXIS_WAIT` moves axis at
//   all -- so window that dips and comes back, which is what ageing spike does, leaves
//   axis exactly where it was rather than travelling out and back.
//   *Then glide, not jump.* Exponential ease toward extent, on time constant
//   rather than step count, so it runs at same speed however often it is drawn.
//   Deadband is proportional: half millisecond matters on 33 ms axis and is noise
//   on 130 ms one.
const MILLISECONDS_AXIS_WAIT = 400;
const MILLISECONDS_AXIS_EASE = 420;
const SHARE_AXIS_DEADBAND = 0.02;
let milliseconds_axis = 0; // What is drawn; zero until first extent arrives.
let ms_axis_restless = 0; // When extent first differed from it; zero while settled.
let ms_axis_eased = 0; // Last ease, for elapsed time glide is scaled by.
// True while axis is still travelling, so frame loop can redraw curve at its.
//   own rate instead of section's five-a-second, which would show glide as steps.
let is_axis_gliding = false;
function axisEased(milliseconds_wanted: number) {
  const now = performance.now();
  const since = ms_axis_eased === 0 ? 0 : now - ms_axis_eased;
  ms_axis_eased = now;
  // First extent is simply adopted: there is nothing to ease from.
  if (milliseconds_axis === 0) milliseconds_axis = milliseconds_wanted;
  const apart = Math.abs(milliseconds_wanted - milliseconds_axis);
  if (apart <= SHARE_AXIS_DEADBAND * milliseconds_axis) {
    ms_axis_restless = 0; // Settled: clock only runs while two are apart.
    is_axis_gliding = false;
    return milliseconds_axis;
  }
  if (ms_axis_restless === 0) ms_axis_restless = now;
  if (now - ms_axis_restless < MILLISECONDS_AXIS_WAIT) {
    is_axis_gliding = false;
    return milliseconds_axis; // Still inside wait; extent may yet come back.
  }
  is_axis_gliding = true;
  milliseconds_axis +=
    (milliseconds_wanted - milliseconds_axis) * (1 - Math.exp(-since / MILLISECONDS_AXIS_EASE));
  return milliseconds_axis;
}
function spanExceedance() {
  // Window's own bounds, in buckets: fastest frame it holds and slowest.
  //   curve is drawn between exactly these, so it leaves 0% at one and reaches 100% at
  //   other instead of running flat along both edges -- which is what makes two of them
  //   readable rather than merely present. Both extremes are window's own: lone
  //   collection pause belongs on chart of what session actually did, and it is
  //   axis's easing, not trim, that stops one deciding how rest is drawn.
  //   Read by curve alone now: timing rows below it used to be capped at worst
  //   band this reported, which tree's own absolute ramp made unnecessary.
  let first = -1;
  let last = 0;
  for (let i = 0; i < BUCKETS_EXCEEDANCE; i += 1) {
    if (buckets_exceedance[i] === 0) continue;
    if (first < 0) first = i;
    last = i;
  }
  return { first, last };
}

function bandOfExceedance(milliseconds: number) {
  for (let i = 0; i < MARKS_EXCEEDANCE.length; i += 1) {
    const mark = MARKS_EXCEEDANCE[i];
    if (mark !== undefined && milliseconds < mark.milliseconds) return i;
  }
  return MARKS_EXCEEDANCE.length - 1;
}
// Axis layer of exceedance curve: rules, marks and their labels, cached between draws.
//   Same size as curve's canvas; `drawExceedance` composites it under curve.
const axis_exceedance = document.createElement('canvas');
const context_axis_found = axis_exceedance.getContext('2d');
if (context_axis_found === null) throw new Error('Axis canvas has no context.');
const context_axis_exceedance: CanvasRenderingContext2D = context_axis_found;
let key_axis_exceedance = ''; // Size, extent and mode layer was drawn for; empty before first.

function drawAxisExceedance(
  context: CanvasRenderingContext2D, w: number, h: number, milliseconds_full: number,
  xOf: (milliseconds: number) => number, yOf: (share_below: number) => number,
) {
  if (axis_exceedance.width !== w) axis_exceedance.width = w;
  if (axis_exceedance.height !== h) axis_exceedance.height = h;
  context.clearRect(0, 0, w, h);
  context.font = FONT_EXCEEDANCE;
  context.textBaseline = 'top';
  // Recessive rules at heights axis actually resolves, each named except floor.
  //   Linear takes quarter at time up to 100%, which is what curve's own arrival is
  //   read against. Log takes decades instead, up to 99.9% its three decades
  //   actually reach -- ceiling is whole reason to switch to it, so it is last
  //   thing that should go unnamed. **Neither names 0%**: it is where every curve starts,
  //   so label states what shape already says, and at very bottom of canvas
  //   it has nowhere to sit that is not either off plot or on top of label above.
  const gridlines = is_exceedance_log
    ? [{ share: 0 }, { share: 0.9, label: '90%' }, { share: 0.99, label: '99%' },
      { share: 0.999, label: '99.9%' }]
    : [{ share: 0 }, { share: 0.25, label: '25%' }, { share: 0.5, label: '50%' },
      { share: 0.75, label: '75%' }, { share: 1, label: '100%' }];
  context.strokeStyle = 'rgba(139, 150, 163, 0.18)';
  context.lineWidth = 1;
  for (const gridline of gridlines) {
    // Held half-pixel inside canvas at two ends, where line would otherwise.
    //   straddle edge and render at half its weight or not at all.
    const y = Math.min(h - 0.5, Math.max(0.5, Math.round(yOf(gridline.share)) + 0.5));
    context.beginPath();
    context.moveTo(0, y);
    context.lineTo(w, y);
    context.stroke();
    if (gridline.label === undefined) continue;
    // Under its own line and at left margin, which rates along top and.
    //   curve's own climb both leave clear.
    context.fillStyle = 'rgba(139, 150, 163, 0.75)';
    context.fillText(gridline.label, 2, y + 1);
  }
  // Marks themselves, **each named twice**: rate at top of line and.
  //   duration at its foot, so one dashed mark answers both "how smooth is that" and "how
  //   long is that" and reader never has to convert between them in their head.
  //   Both sit *over* plot rather than in rows of their own. Rows were tried, and they
  //   do buy clearance -- curve reaches 100% in top right, under slowest mark's
  //   label, and 0% in bottom left, under fastest mark's duration -- but they cost
  //   22px of drawer that has none to spare, and number reader can find beside its
  //   own line is worth more than guarantee it is never crossed. Labels are drawn
  //   before curve, so where two meet it is curve that reads as continuous.
  //   Drawn only where axis actually reaches them: window with nothing slower than
  //   120 fps in it has no business drawing others, and 15 fps mark stays away
  //   until window holds frame that slow. Floor is set so slowest mark
  //   axis is guaranteed to reach -- 30 fps -- stands clear of right edge with room
  //   for its own labels; see `SHARE_MARK_LEAST`.
  context.setLineDash([2, 3]);
  for (const mark of MARKS_EXCEEDANCE) {
    if (!Number.isFinite(mark.milliseconds)) continue;
    if (mark.milliseconds > milliseconds_full) continue;
    const x = Math.round(xOf(mark.milliseconds)) + 0.5;
    context.strokeStyle = 'rgba(139, 150, 163, 0.30)';
    context.beginPath();
    context.moveTo(x, 0);
    context.lineTo(x, h);
    context.stroke();
    context.fillStyle = 'rgba(139, 150, 163, 0.75)';
    // Inside line where it would otherwise run off right edge. Both rows take.
    //   same side, so rate and its duration stay in one column whichever way they go.
    const is_room = x + 14 < w;
    context.textAlign = is_room ? 'left' : 'right';
    const x_label = x + (is_room ? 2 : -2);
    // Haloed against drawer's own surface before being filled. These sit over plot.
    //   and curve crosses fastest ones outright -- duration bisected by stroke
    //   of same weight is unreadable, and this is what buys numbers their place
    //   inside without asking chart for height it does not have.
    const write = (text: string, y: number, baseline: CanvasTextBaseline) => {
      context.textBaseline = baseline;
      context.strokeStyle = HALO_LABEL_EXCEEDANCE;
      context.lineWidth = 3;
      context.setLineDash([]);
      context.strokeText(text, x_label, y);
      context.fillText(text, x_label, y);
      context.lineWidth = 1;
      context.setLineDash([2, 3]);
    };
    write(mark.label, 1, 'top');
    write(mark.milliseconds.toFixed(1), h - 1, 'bottom');
  }
  context.setLineDash([]);
  context.textAlign = 'left';
  context.textBaseline = 'top';
}

function drawExceedance() {
  if (context_exceedance === null) return;
  // Observer's size, not canvas's own; see `sizeObserved`.
  //   Fallback stands for canvas without layout, as inside shut section; checks drawing
  //   with drawer shut lean on it.
  const w = size_exceedance.width || 300, h = size_exceedance.height || 74;
  if (exceedance.width !== w) exceedance.width = w;
  if (exceedance.height !== h) exceedance.height = h;
  context_exceedance.clearRect(0, 0, w, h);
  const counted = scanExceedance();
  if (counted === 0) return;

  const { first: bucket_first, last: bucket_last } = spanExceedance();
  if (bucket_first < 0) return;
  const milliseconds_full = axisEased(
    Math.max(MILLISECONDS_AXIS_LEAST, (bucket_last + 1) * MILLISECONDS_BUCKET),
  );
  const xOf = (milliseconds: number) => (milliseconds / milliseconds_full) * w;
  // Proportion **below**, rising: question reader is asking is how much of.
  //   session came in under duration, and curve that answers it climbing left to right
  //   is read without translation.
  //   Linear, where axis is proportion itself; or, on switch, three decades of
  //   distance from top -- share still at or over -- which is only way
  //   slowest one percent is legible at all, since linear squeezes it flat against
  //   ceiling for last third of chart.
  const yOf = is_exceedance_log
    ? (share_below: number) => {
        const share_over = Math.max(1 - share_below, Math.pow(10, -DECADES_EXCEEDANCE));
        return h * (1 + Math.log10(share_over) / DECADES_EXCEEDANCE);
      }
    : (share_below: number) => h - share_below * h;

  // Rules, marks and labels come off cached layer, redrawn only where axis moved.
  //   Some thirty text operations, each haloed, were most of what drawing curve cost, for
  //   axis that changes only while it glides; figures in `PROVENANCE.md`.
  const key_axis =
    w + 'x' + h + '@' + milliseconds_full.toFixed(3) + (is_exceedance_log ? 'L' : 'l');
  if (key_axis !== key_axis_exceedance) {
    key_axis_exceedance = key_axis;
    drawAxisExceedance(context_axis_exceedance, w, h, milliseconds_full, xOf, yOf);
  }
  context_exceedance.drawImage(axis_exceedance, 0, 0);
  context_exceedance.textAlign = 'left';
  context_exceedance.textBaseline = 'top';

  // Curve, in one run per band, each stroked in that band's own colour and each.
  //   starting where last ended so line is continuous across change. Drawn
  //   band by band rather than sampling colour per segment: run is one path and one
  //   stroke, and join at boundary is exact rather than pixel of wrong hue.
  context_exceedance.lineWidth = 1.5;
  let band_open = -1;
  for (let i = bucket_first; i <= bucket_last; i += 1) {
    const milliseconds = i * MILLISECONDS_BUCKET;
    const band = bandOfExceedance(milliseconds);
    // `shares_exceedance[i]` is share at or over this duration, so its complement is.
    //   share below it -- histogram stays exceedance and only drawing turns
    //   over, which is what keeps scan plain suffix sum.
    const point: [number, number] =
      [xOf(milliseconds), yOf(1 - flatAt(shares_exceedance, i))];
    if (band !== band_open) {
      if (band_open >= 0) {
        // Carry run into boundary before closing it, so two runs meet on.
        //   dashed line rather than bucket short of it.
        context_exceedance.lineTo(point[0], point[1]);
        context_exceedance.stroke();
      }
      context_exceedance.beginPath();
      context_exceedance.moveTo(point[0], point[1]);
      context_exceedance.strokeStyle = colours_exceedance[band] ?? '';
      band_open = band;
    } else {
      context_exceedance.lineTo(point[0], point[1]);
    }
  }
  // Last bucket's own upper edge, where share below reaches one: slowest frame.
  //   window holds, standing at 100% and at axis's own end.
  context_exceedance.lineTo(xOf((bucket_last + 1) * MILLISECONDS_BUCKET), yOf(1));
  if (band_open >= 0) context_exceedance.stroke();

  // One number worth stating outright beside curve: what slowest frame in.
  //   hundred took. Reader tuning for smoothness is tuning that, not median.
  let milliseconds_p99 = 0;
  for (let i = BUCKETS_EXCEEDANCE - 1; i >= 0; i -= 1) {
    if (flatAt(shares_exceedance, i) >= 0.01) {
      milliseconds_p99 = i * MILLISECONDS_BUCKET;
      break;
    }
  }
  writeText(diagnostic_exceedance,
    '1 in 100: ' + milliseconds_p99.toFixed(1) + ' ms \u00b7 ' + counted + ' frames');
  // Axis's own extent, said where reader is looking rather than left to be.
  //   inferred from curve that now moves with window.
  if (label_exceedance_axis !== null) {
    // Mode is named in caption as well as lit on its own pill, so screenshot of.
    //   drawer says which axis curve in it was read against.
    writeText(label_exceedance_axis,
      'frames under \u00b7 0\u2013' + milliseconds_full.toFixed(0) + ' ms' +
      (is_exceedance_log ? ' \u00b7 log' : ''));
  }
}

// Scale bar's own reading, as map carries one: span of ground drawn at its true.
//   screen length, with distance it covers written under it, and **ground grid's
//   own cell size beside that** -- which is what makes ruled ground measurable rather
//   than decorative. Span is chosen 1-2-5 by decade to land near
//   `PIXELS_RULER_WANTED`, way every map scale is stepped: bar tied rigidly to one
//   cell runs off screen when camera is close and shrinks to nothing when it is
//   far, because cell steps by decades while projection does not.
//   Cell comes from `nimGridMetrics`, which reads same `mesh.sizeCellGridAt`
//   grid is laid with; nothing here re-derives cell size of its own.
const ruler = elementIfPresent('ruler');
const ruler_bar = elementById('ruler-bar');
const ruler_label = elementById('ruler-label');
const PIXELS_RULER_WANTED = 130;
const STEPS_RULER = [1, 2, 5];
// Reading bar was last laid out for, so still ground formats and writes nothing.
//   Both `NaN` before first tick: equal to nothing, so first comparison always writes.
let cell_ruler_written = NaN;
let scale_ruler_written = NaN;
function refreshRuler() {
  if (ruler === null) return;
  // Observer's size, not canvas's own; see `sizeObserved`.
  const metrics = nimGridMetrics(size_canvas.width, size_canvas.height);
  const size_cell = flatAt(metrics, 0), world_per_pixel = flatAt(metrics, 1);
  if (size_cell === cell_ruler_written && world_per_pixel === scale_ruler_written) return;
  cell_ruler_written = size_cell;
  scale_ruler_written = world_per_pixel;
  // No ground drawn -- eye above fog's own reach -- so there is nothing to measure.
  if (!(size_cell > 0) || !(world_per_pixel > 0)) { ruler.hidden = true; return; }
  const world_wanted = PIXELS_RULER_WANTED * world_per_pixel;
  const decade = Math.pow(10, Math.floor(Math.log10(world_wanted)));
  let span = decade;
  for (const step of STEPS_RULER) {
    // Largest 1-2-5 step still at or under target: bar that overshoots crowds.
    //   corner it sits in, while one that undershoots is only harder to read against.
    if (step * decade <= world_wanted) span = step * decade;
  }
  ruler.hidden = false;
  ruler_bar.style.width = (span / world_per_pixel).toFixed(1) + 'px';
  // Thousands separated with thin space rather than comma: comma reads as decimal.
  //   point to much of world, and these numbers are what bar is claiming.
  const written = (value: number) => (value >= 1000
    ? value.toLocaleString('en-US').replace(/,/g, '\u2009')
    : String(Number(value.toPrecision(3))));
  ruler_label.textContent = span === size_cell
    ? written(span) + ' units, one grid cell'
    : written(span) + ' units \u00b7 grid ' + written(size_cell);
}

// **Write only where value moved.** Every one of these is text node or inline.
//   style browser must re-style and re-lay out afterwards, and measured on full tree
//   only about **10 of 29 rows actually change** -- so two thirds of writes were
//   dirtying layout to set string that was already there. Same rule pool strip
//   and objects list already follow, at grain of single element.
//   `WeakMap` rather than table keyed by row name: row's element can be replaced, and
//   stale entry keyed by name would then suppress first write to its successor.
const text_written = new WeakMap();
const colour_written = new WeakMap<Element, string>();

function writeText(element: HTMLElement | Element | null, value: string) {
  if (element === null || element === undefined) return;
  if (text_written.get(element) === value) return;
  text_written.set(element, value);
  element.textContent = value;
}

function writeColour(element: HTMLElement | Element | null, value: string) {
  if (element === null || element === undefined) return;
  if (!(element instanceof HTMLElement)) return;
  if (colour_written.get(element) === value) return;
  colour_written.set(element, value);
  element.style.color = value;
}

// Panel's own collapsible section, read by guard below rather than by class on.
//   drawer: drawer holds several sections and only this one owns these figures.
const section_diagnostics_found =
  document.querySelector('.section[data-section="diagnostics"]');
if (section_diagnostics_found === null) throw new Error('Missing diagnostics section.');
const section_diagnostics: Element = section_diagnostics_found;
// Report whether figures are on screen at all: drawer open, and section open inside it.
function isDiagnosticsShown() {
  return drawer.classList.contains('open') && section_diagnostics.classList.contains('open');
}

// **Figures are redrawn on cadence of window they are averaged over, not on section's.**
//   Rows are 200 ms readings and belong at 200 ms. Sparkline holds four seconds, ring
//   medians four, exceedance curve seventeen, and pool grid changes with scene: none
//   can visibly change in fifth of second, and redrawing them at that rate was single
//   most expensive thing page did -- 0.31 ms for curve and 0.27 for medians out of
//   1.17 ms tick. Not slower still: second is longest reader will watch curve without
//   deciding it has stopped, and sparkline has to scroll rather than jump.
//   One job per tick rather than three on one: three together made one tick in five
//   cost three to four times its neighbours, spike reader saw once second on
//   `ui refresh`. Jobs run off frame besides -- see `askSlowPass` -- and each is
//   still kept short for idle window it runs in.
//   Every job runs on first tick after section is shown, so section never opens half
//   drawn.
const TICKS_DISTRIBUTION = 5; // Five 200 ms ticks is window's own second.
const TICK_CURVE = 0;
const TICK_SPARKLINE = 2;
const TICK_MEDIANS = 4;
let ticks_diagnostics = 0; // Ticks since section was shown, driving rota above.
let is_diagnostics_shown_last = false; // Whether last tick found section open.

// **Slow pass runs in idle time, off frame.** Tick only asks; `runSlowPass` draws.
//   Curve, sparkline, medians and pool grid are drawn in `requestIdleCallback`, between
//   one frame's callback and next, where page was waiting on display anyway. Its
//   clock reads go into same frame's `ui` reading through `addPhaseTime`, so row
//   still states everything section cost -- on frame's path or off it -- and frame-time
//   row above it is what says whether frame stalled.
//   Timeout is one reading window: browser finding no idle time still draws figure
//   within 200 ms rather than never.
//   `setTimeout` where idle callbacks are missing: still task of its own, off frame's
//   callback, only without browser's word that frame had slack.
const MILLISECONDS_SLOW_PASS_LATEST = MILLISECONDS_WINDOW_READING;
// Deadline stand-in where engine offers no idle callback: nothing is known about
//   frame's slack, so pass runs as if hurried and jobs decide for themselves.
const DEADLINE_HURRIED: IdleDeadline =
  { didTimeout: true, timeRemaining: () => 0 };
const scheduleIdle: (job: IdleRequestCallback) => void =
  typeof requestIdleCallback === 'function'
  ? (job: IdleRequestCallback) => {
      requestIdleCallback(job, { timeout: MILLISECONDS_SLOW_PASS_LATEST });
    }
  : (job: IdleRequestCallback) => { setTimeout(() => job(DEADLINE_HURRIED), 0); };
// Jobs of slow pass, in order pass runs them.
const JOBS_SLOW_PASS: Record<string, () => void> = {
  curve: () => drawExceedance(),
  sparkline: () => drawSparkline(),
  medians: () => recomputeMedians(),
  pool: () => drawPoolGrid(nimSceneCount(), nimSceneCapacity()),
};
// Jobs owed, each once however many ticks asked before pass ran.
const due_slow_pass: Record<string, boolean> =
  { curve: false, sparkline: false, medians: false, pool: false };
// What each job cost last time, weighed against idle period's remaining time.
//   2 ms before first run: first draws measured 2.6 and 6.1 ms on desktop, so first
//   period is asked for room rather than assumed to have it.
const ms_job_slow_pass: Record<string, number> =
  { curve: 2, sparkline: 2, medians: 2, pool: 2 };
let is_slow_pass_scheduled = false;
function askSlowPass(
  is_curve: boolean, is_sparkline: boolean, is_medians: boolean, is_pool: boolean,
) {
  if (is_curve) due_slow_pass.curve = true;
  if (is_sparkline) due_slow_pass.sparkline = true;
  if (is_medians) due_slow_pass.medians = true;
  if (is_pool) due_slow_pass.pool = true;
  if (is_slow_pass_scheduled) return;
  is_slow_pass_scheduled = true;
  scheduleIdle(runSlowPass);
}
function runSlowPass(deadline: IdleDeadline) {
  is_slow_pass_scheduled = false;
  const ms_before = performance.now();
  // Section shut since ask: owed jobs are dropped.
  //   First tick after it is shown again asks for all of them.
  const is_shown = isDiagnosticsShown();
  // Callback without deadline, or past its timeout, runs every job:
  //   `setTimeout` fallback has no deadline, and timeout promised figure within window,
  //   whatever frame is doing.
  const is_hurried = deadline === undefined || deadline.didTimeout;
  let is_owed = false;
  for (const name in JOBS_SLOW_PASS) {
    if (!due_slow_pass[name]) continue;
    if (!is_shown) { due_slow_pass[name] = false; continue; }
    // Job that would overrun idle period waits for next one:
    //   overrun lands on very frame job was moved off, and browser's own estimate of
    //   period's end is only word there is on when that frame is due.
    if (!is_hurried && deadline.timeRemaining() < (ms_job_slow_pass[name] ?? 0)) {
      is_owed = true;
      continue;
    }
    const ms_job = performance.now();
    const job = JOBS_SLOW_PASS[name];
    if (job === undefined) continue;
    job();
    ms_job_slow_pass[name] = performance.now() - ms_job;
    due_slow_pass[name] = false;
  }
  addPhaseTime('ui', performance.now() - ms_before);
  if (is_owed) { is_slow_pass_scheduled = true; scheduleIdle(runSlowPass); }
}

// Draw last four seconds of frame times as one line, scaled to slowest of them.
function drawSparkline() {
  // Observer's size, not canvas's own; see `sizeObserved`.
  const w = size_sparkline.width || 300, h = size_sparkline.height || 40;
  if (sparkline.width !== w) sparkline.width = w;
  if (sparkline.height !== h) sparkline.height = h;
  let highest = 16.6;
  for (const v of history_frame) if (v > highest) highest = v;
  context_sparkline.clearRect(0, 0, w, h);
  context_sparkline.strokeStyle = '#00a7a5';
  context_sparkline.lineWidth = 1.5;
  context_sparkline.beginPath();
  for (let i = 0; i < FRAMES_HISTORY; i++) {
    const v = flatAt(history_frame, (index_history_frame + i) % FRAMES_HISTORY);
    const x = (i / (FRAMES_HISTORY - 1)) * w;
    const y = h - (Math.min(v, highest) / highest) * h;
    if (i === 0) context_sparkline.moveTo(x, y); else context_sparkline.lineTo(x, y);
  }
  context_sparkline.stroke();
}

function refreshDiagnostics() {
  // **Nothing here is worth millisecond while drawer is shut.** Every figure this.
  //   writes is inside it, and with drawer closed whole refresh was still running
  //   five times second: measured on 1,024-object demo at 2.8 ms typical and 5.7 ms
  //   worst, landing on one frame in twelve. On frame that otherwise costs about
  //   millisecond -- which is what scene hold made still case -- that is not
  //   overhead, it is stutter reader can see, and it was largest single source of
  //   frame-time variance left in build.
  //   Two canvases could not skip themselves either: each fell back to 300-pixel
  //   width where its own was zero, so canvas nobody could see was drawn at made-up
  //   size. That fallback is for canvas that has not been laid out yet, not for one
  //   inside closed drawer, and this guard is what tells two apart.
  //   **And same argument one level down**: diagnostics section is collapsible
  //   inside open drawer, and collapsed one gave both canvases zero width again --
  //   so they fell back to 300 pixels and drew, five times second, for reader looking
  //   at objects list. Drawer guard above did not catch it because drawer is
  //   genuinely open.
  if (!isDiagnosticsShown()) { is_diagnostics_shown_last = false; return; }
  // Which slow-pass job this tick asks for; see `TICKS_DISTRIBUTION` and `askSlowPass`.
  //   Numeric rows below run every tick, here on frame.
  const is_first_shown = !is_diagnostics_shown_last;
  is_diagnostics_shown_last = true;
  if (is_first_shown) ticks_diagnostics = 0;
  const slot_distribution = ticks_diagnostics % TICKS_DISTRIBUTION;
  ticks_diagnostics += 1;
  askSlowPass(
    is_first_shown || slot_distribution === TICK_CURVE,
    is_first_shown || slot_distribution === TICK_SPARKLINE,
    is_first_shown || slot_distribution === TICK_MEDIANS,
    isPoolGridStale(),
  );

  // Averaged over last 200 ms rather than taken from newest frame: per-frame.
  //   reading changes several times faster than it can be read, and frame rate quoted
  //   off one frame swings by tens of fps between glances.
  const frames_recent = framesRecent();
  let total_recent = 0;
  for (let i = 0; i < frames_recent; i += 1) {
    total_recent += history_frame[(index_history_frame + FRAMES_HISTORY - 1 - i) % FRAMES_HISTORY];
  }
  const mean_frame = total_recent / frames_recent;
  // **No band ceiling any more, and no share-of-work denominator.** Both belonged to.
  //   four-band tint this replaced: bands had to agree with curve above them, so
  //   tree was capped at whatever band that curve was drawing. Ramp is absolute --
  //   row's share of *frame*, over whole of it -- so it says same thing
  //   whatever curve happens to show, and there is nothing left to contradict.
  writeText(diagnostic_frame_time,
    mean_frame.toFixed(2) + ' ms (' + Math.round(1000 / Math.max(mean_frame, 1)) + ' fps)');
  // Slowest frame ring holds, split from its own slots between page and browser.
  //   Rows below are 200 ms means, which dilute one spike past telling whether page
  //   authored it; every phase was recorded frame by frame, so one frame can be read
  //   back exactly. Largest page phase is named beside page's sum.
  //   Slot about to be written is skipped: its phases are cleared and its frame is
  //   ring-old.
  let at_slowest = -1;
  for (let i = 0; i < FRAMES_HISTORY; i += 1) {
    if (i === index_history_frame) continue;
    if (at_slowest < 0 || history_frame[i] > history_frame[at_slowest]) at_slowest = i;
  }
  let page = 0;
  let largest = 0;
  let name_largest = '';
  for (const name of PHASES_TOP_DIAGNOSTIC) {
    if (writtenOf(name)[at_slowest] !== 1) continue;
    const spent = flatAt(ringOf(name), at_slowest);
    page += spent;
    if (spent > largest) { largest = spent; name_largest = name; }
  }
  const browser = flatAt(writtenOf('idle'), at_slowest) === 1
    ? flatAt(ringOf('idle'), at_slowest) : 0;
  // Browser's share split where timer measured it; see `markRendered`.
  const render = flatAt(writtenOf('render'), at_slowest) === 1
    ? ' (render ' + flatAt(ringOf('render'), at_slowest).toFixed(1) + ')' : '';
  writeText(diagnostic_slowest, flatAt(history_frame, at_slowest).toFixed(1) + ' ms');
  writeText(diagnostic_slowest_split,
    page.toFixed(1) +
    (name_largest === '' ? '' : ' (' + name_largest + ' ' + largest.toFixed(1) + ')') +
    ' \u00b7 ' + browser.toFixed(1) + render);

  // Each step of drawing process, as `mean over 200 ms (median over the ring)`:
  //   short mean is what reader watches while changing something, long median is settled figure to
  //   act on.
  //   Phase that has not run at all stays em dash.
  for (const [name] of PHASES_DIAGNOSTIC) {
    if (!isPhaseShown(name)) continue; // Inside closed node; nobody is reading it.
    const median = medianPhaseHeld(name);
    if (median === null) continue;
    // Phase idle for whole window shows its median rather than nothing: it is step.
    //   that runs, and "0.00" would claim it had run for free this window.
    const recent = meanPhase(name, frames_recent);
    const shown = recent === null ? median : recent;
    writeText(
      element_phase[name] ?? null,
      (shown ?? 0).toFixed(2) + ' (' + (median ?? 0).toFixed(2) + ') ms');
    // Count beside row's own name, so **every** value ends in `ms` and times.
    //   down tree finish in one column. Zero is shown rather than left off: kind
    //   present but empty says something kind that is absent does not.
    // Points drawn of points standing, where cull skipped any; see `isPointInView`.
    const tally = name === 'points' && count_points_culled > 0
      ? ' (' + (count_phase[name] ?? 0) + ' of '
        + ((count_phase[name] ?? 0) + count_points_culled) + ')'
      : ' (' + (count_phase[name] ?? 0) + ')';
    writeText(element_tally[name] ?? null, tally);
    // And what that number is worth, in curve's own colours.
    if (element_row[name] === null) continue;
    // Some rows keep neutral ink instead. **`idle` always**: it is frame's.
    //   leftover rather than work done, so on healthy frame it is largest share of
    //   all and tinting it would paint best case in ramp's loudest colour. And
    //   where nothing has been measured yet there is no share to take.
    if (name === 'idle' || !(mean_frame > 0)) {
      writeColour(element_row[name] ?? null, '');
      writeColour(element_phase[name] ?? null, '');
      continue;
    }
    // **Against whole frame, not against work in it.** Row's colour answers.
    //   `how much of a frame goes here`, so denominator is frame -- which makes
    //   ramp absolute reading reader can compare between sessions, rather than
    //   share of total that shrinks as page gets faster and repaints every row
    //   louder for it.
    const tint = rampTreeAt((shown ?? 0) / mean_frame);
    writeColour(element_row[name] ?? null, tint.label);
    writeColour(element_phase[name] ?? null, tint.value);
  }

  const memory = (performance as Performance & {
    memory?: { usedJSHeapSize: number; jsHeapSizeLimit: number };
  }).memory;
  if (memory !== undefined) {
    writeText(diagnostic_heap,
      (memory.usedJSHeapSize / (1024 * 1024)).toFixed(1) + ' / ' +
      (memory.jsHeapSizeLimit / (1024 * 1024)).toFixed(0) + ' MB');
  }

  writeText(diagnostic_pool, nimSceneCount() + ' / ' + nimSceneCapacity());
}

// Object pool, one square per handle in ink of whatever object holds it.
//   `nimPoolCellColors` decides every cell's colour, free ones included, so no palette rule
//   lives out here -- it returns one [r, g, b] triple per handle, in handle order, and this only
//   arranges them.
//   **Drawn when scene changes and at no other time.** At capacity of 1,024 walk
//   that fills that buffer is about millisecond, and this refresh runs five times second
//   for picture that moves when object is added or removed. Scene's own revision is
//   exactly that question, and it is same counter frame hold is keyed on.
//   canvas's own geometry is part of key as well, because resize clears what was drawn
//   and because section opens onto canvas that had no size until it did.
// Report whether grid's picture is behind:
//   scene edited, pixel ratio moved, or canvas itself resized or never drawn. Plain
//   reads all; tick asks this and slow pass draws.
function isPoolGridStale() {
  const ratio = Math.min(window.devicePixelRatio || 1, 2.5);
  return is_pool_stale || revision_pool_last !== nimSceneRevision() || ratio_pool_last !== ratio;
}

function drawPoolGrid(count: number, capacity: number) {
  if (context_pool === null) return;
  const ratio = Math.min(window.devicePixelRatio || 1, 2.5);
  // Observer's width, not canvas's own; see `sizeObserved`.
  const width = size_pool.width;
  if (!(width > 0)) return; // Laid out inside something closed; nothing to draw on.
  revision_pool_last = nimSceneRevision();
  ratio_pool_last = ratio;
  is_pool_stale = false;
  width_pool_drawn = width;

  // First size whose grid fits budget, or smallest offered where none does.
  const smallest = CELLS_POOL[CELLS_POOL.length - 1];
  if (smallest === undefined) throw new Error('Pool offers no cell sizes.');
  let [cell, gap] = smallest;
  let columns = 1, rows = capacity, height = 0;
  for (const [side, between] of CELLS_POOL) {
    const pitch_try = side + between;
    const columns_try = Math.max(1, Math.floor((width + between) / pitch_try));
    const rows_try = Math.ceil(capacity / columns_try);
    const height_try = rows_try * pitch_try - between;
    if (height_try > HEIGHT_POOL_MAX && side !== smallest[0]) continue;
    cell = side; gap = between;
    columns = columns_try; rows = rows_try; height = height_try;
    break;
  }
  const pitch = cell + gap;
  // **Drawn at device resolution, unlike its two neighbours.** Curve and sparkline.
  //   are 1.5px strokes and lose nothing to doubled display; grid of hard-edged squares
  //   this small does, and every cell edge would be soft on tablet this is read on.
  geometry_pool_drawn = { cell, gap, columns, rows, height };
  grid_pool.style.height = height + 'px';
  grid_pool.width = Math.round(width * ratio);
  grid_pool.height = Math.round(height * ratio);
  context_pool.setTransform(ratio, 0, 0, ratio, 0, 0);
  context_pool.clearRect(0, 0, width, height);
  const cells = nimPoolCellColors();
  for (let handle = 0; handle < capacity; handle += 1) {
    const at = handle * 3;
    // Keyed on bytes rather than floats, so triple that rounds to same colour.
    //   is same entry; `rgbToCss` rounds to bytes anyway.
    const red = flatAt(cells, at), green = flatAt(cells, at + 1);
    const blue = flatAt(cells, at + 2);
    const key = (Math.round(red * 255) << 16) | (Math.round(green * 255) << 8) |
      Math.round(blue * 255);
    let colour = css_pool.get(key);
    if (colour === undefined) {
      colour = rgbToCss([red, green, blue]);
      css_pool.set(key, colour);
    }
    context_pool.fillStyle = colour;
    context_pool.fillRect(
      (handle % columns) * pitch, Math.floor(handle / columns) * pitch, cell, cell,
    );
  }
  // What picture says, for reader who cannot see it. `title` beside it in.
  //   markup carries legend, which does not change.
  grid_pool.setAttribute(
    'aria-label', count + ' of ' + capacity + ' object handles in use, one cell each',
  );
}
