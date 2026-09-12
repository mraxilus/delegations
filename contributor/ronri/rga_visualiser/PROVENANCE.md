Provenance
===

_Who made this, from what, and how far it has been checked._

| Field  | Value |
|--------|-------|
| Agent  | Claude Code |
| Author | Claude Opus 5 and Claude Sonnet 5 |
| Date   | 2026-09-06 |
| Style  | CONSTITUTION.md and STYLE.md, followed. |
| Rules  | a58639b1bb0bbfef |
| Review | **Unreviewed.** Nothing here has been read line by line by a human. |

An interactive visualiser of rigid geometric algebra objects, built as a testbed for the
`pga` library: geometry and a scene model shared by two front-ends, plus the encoders a
scripted storyboard writes its frames through.

This file records the **current** design by subsystem and the reasoning behind decisions
that are not obvious from the code: what was chosen, what was rejected, and what the choice
costs. It is not a changelog. Where a rejected alternative is still a live trap it appears
as a terse "not X — Y" note; where a figure justified a constant it is kept beside that
constant, because the comments in the source no longer carry figures (Art. VII.5) and this
file is where they went.

**What is here, and what is not.** This project was ported from a prototype that lived
outside this repository, and it arrives in stages. Here now: the render-path-independent
core, the PNG and GIF encoders with the arena they write through, and the suite. Not here
yet: the browser front-end (its bridge, its page and its glue) and the desktop front-end
(its window, its panel and its OpenGL renderer). Their sections of this file travel with
their code rather than describing something a reader cannot open. Where a section kept here
mentions how a front-end draws what the core computes, that front-end is the one arriving
later; the claim about the core is the part this repository can be held to.

**How claims are marked.** Each subsystem closes with a *Checked* block. *Verified* means
the claim was established by running something — a suite case, a driven check, a render
looked at, a byte read back — and names what. *Assumed* means the claim rests on reasoning
alone. A figure without a *Verified* line beside it is a figure once read off a panel and
not re-measured since; treat it as indicative.

**Verification practice, applies throughout.** Every change is rebuilt and the full suite
rerun through `koch tests`, on the C backend at two capacities and on the JS backend.
**No human has driven either front-end, clicked a button, or seen this on real GPU
hardware**; every figure in this file was software-rendered, and every one of them was
taken on a different compiler from the one this repository builds with (see Measurements).


Open Questions
---
Recorded here and in the pull request body, per CONTRIBUTOR.md: a contributor neither works
around a rule nor edits it.

**System packages have no declared home in this repository.** Nim packages are declared in
`rga_visualiser.nimble` and pinned by `atlas.lock`; node packages in `package.json`, pinned by
`package-lock.json`. Desktop front-end links against SDL3, libGL and zlib, drives itself
headless through Xvfb and software GL, and compiles Dear ImGui from clone rather than linking
it -- and none of those five is expressible in either file. Prototype used
`dependencies.list`; that extension is not among thirteen kinds
`curator/audit/src/kinds.nim` registers, so committing one is finding rather than declaration.
  Named in `README.md`'s build section meanwhile, as table beside compiler pin already there,
  with ImGui's clone command under it. Honest and reader finds it, but nothing checks it, so it
  decays as any unrun check does. Asked as issue 60, with three ways out offered and no
  preference between them. Rejected as workaround: committing `dependencies.list` regardless,
  which is exactly rule CONTRIBUTOR.md forbids working around.

**The browser front-end waits on conventions for the repository's first TypeScript.** No `.ts`
file is committed anywhere, so this project's conversion of the browser glue — some 9,000
lines — would set the precedent for module system, build step, dependency pinning and how a
generated file is marked. Conventions were proposed rather than assumed, as issue 27, and are
unanswered. Rejected as a workaround: choosing them unilaterally and leaving a later ruling to
invalidate every line written under them.
Vocabulary
---
**Twenty-eight terms were selected by the Architect, in session, and are in `GLOSSARY.md`.**
None was written on sight: CONTRIBUTOR.md's glossary process says propose the term and let
the Architect choose, so each was put with its candidates and what each would displace. The
code was then made to say them, one commit per term or tight group.

**Every word turned out to name more than one thing, and only one sense moved.** This is the
finding worth carrying: a rename here is never a substitution, and what is spared is spared
by an explicit list rather than by a rule.
  `slot` meant three things — an object's address, a position in the `Ink` palette, and a
  per-phase timing array position in the diagnostics. Only the first became `handle`;
  `mesh` was left whole, holding no address sense at all.
  `target` meant five — the camera's orbit centre, the object a press points at, the DOM
  event target, a render target, and a plain goal figure. Only the first became `pivot`.
  `budget` meant two: the frame-rate lines, which are `mark`s because nothing is held to
  them, and real allowances of time, pixels and segments, which keep the word.

**Three names could not be taken, and each says why in place.** `object` is reserved in Nim,
so code-position `item` took a role instead — `one` where an object is reached through the
accessor, `saved` where a record is read out of a file. `handle` collides with std's
`typedthreads.handle`, which wins over an injected local inside a template, so `picking`
turns on `openSym`. `iterator items` keeps its name because it is Nim's own protocol:
renaming it would break every `for` loop with no word from the compiler.

**Two spec keys were nearly renamed, and neither would have failed loudly.** `targets: "js"`
is a testament key; renaming it would have run the browser suite on the wrong backend.
`visualiser.items_max` is a compile-time define named in the small suite's `matrix`; the
constant and the define moved together, and that they still meet was checked by compiling
against it rather than by reading both lines.

**`horizon` stays `pga`'s word** and has no entry here: the algebra's vocabulary belongs to
that library. What was corrected is this project's phrasing of it. An ideal object does not
sit *at* the horizon, it lies *in* it, so the kind words a reader sees are `horizon point`,
`horizon line` and `horizon plane`. The finite half — a plane meets the horizon in a line,
which is its direction — has no site here, since this project describes ideal objects alone.

*Checked.* Verified by running, after every rename: three suites pass unchanged at 323, 302
and 310 cases, which is what says no behaviour moved; `tsc` clean under its three flags after
`bridge.d.ts` is re-derived; `koch tree` at 0 findings; and the page built, loaded and driven
— object list, a pick, an orbit, undo, and the camera fields the pivot rename touched.
  **Unverified**: the desktop front-end is not in this repository yet, so no rename here has
  been compiled against it. Whatever it carries of this vocabulary arrives with it.

Driven Checks
---
**Suites test rules; this layer tests wiring.** What a slide does to pivot, what zoom does
to distance, is suite's. Nothing in suites presses key, turns wheel or puts two fingers on
canvas, so nothing in them catches rule wired to wrong event. `tools/drive/` does, through
Playwright, against page `tools/build.nim web` assembled. One command runs both:
`nim r tools/build.nim drive`.

**139 checks pass today**, one module per section of what page does:

| Module | Covers |
|--------|--------|
| `keys`, `wheel`, `pan` | held keys, wheel zoom, mouse pan, what zoom settles onto |
| `touch`, `construct`, `finger` | pinch, long press, drag construction, crowd, paused drag |
| `apply`, `framing`, `label` | pickers and menu route, what picking does to camera, names |
| `chrome`, `comet`, `ground` | hover during gesture, help, horizon comet, ground's reach |
| `frame`, `diagnostics`, `ramp` | frame's own clocks, tree, colour each row wears |
| `exceedance`, `rings` | distribution curve, its axis, rings each reading is taken over |
| `scenery`, `pins`, `hold`, `pool` | what scene costs, repaired faults, scene hold, drawer |
| `demo`, `loaded`, `objects` | preset, culling, occlusion, and what all of it costs loaded |

Figures from this environment, software-rendered: eight wheel notches take distance 19.00 to
5.28 and leave what pointer is over **0.00 px** from where it was; right-button drag moves
pivot 32.5 units at unchanged height; frame is assembled in 0.7 ms median, 0.9 ms at its
slowest tenth; hover pick over largest demo runs 2.0 ms median; edit past timeline capacity
costs 2.5 ms over 5,038 objects; closed rows hold 9.1 elements each over 5,040 of them.

**Accounting allows two frames of its sample to miss, as count rather than share.** Share of
0.995 was written after demanding *every* frame failed, and never took effect: `ceil(0.995n)`
equals `n` for every `n` under 200. Both call sites define what "enough frames accounted" means,
and neither can be fixed by growing sample -- misses are per frame, so larger sample brings
proportionally more chances to straddle collection and proportional allowance never pulls ahead.
Ruled on repository issue 47; one definition now, exported from `scenery` and imported by
`loaded`, since two copies are what let one site stay inert.
  Measured either side, which is what says where it bites: `scenery`'s sample is 485-549 frames,
  above 200, so share already allowed two there and count reproduces it exactly. `loaded`'s
  sample is 49-50, capped by its own sampling loop stopping at 25 heavy frames, so share allowed
  *zero* and count now allows two. Failing check was `loaded`'s, and that is why.
  Per-frame tolerances are untouched, and deliberately: every bit of detection power is in them,
  and real accounting fault misses on every frame rather than hiding inside two.
  Improvement is shape rather than rate. Two frames should put red runs near one in thousand if
  misses are independent, and materially worse if they cluster -- scheduler pause or collection
  cycle producing two straddles together is plausible and unmeasured.

**Timing-dependent quantities are asserted as bands, never figures.** How far held key
travels depends on frames drawn while it was down. Band that will not settle is widened with
reason recorded, never deleted and never narrowed to fit one lucky run.

**A count is only as steady as the thing counted, and the thing counted has to be what the
claim is about.** The panel's cadence check counted calls to `drawExceedance` to show the tick
asks for slow figures on a slower clock. Three callers reach that function: the tick's rota, the
axis switch on press, and the frame loop every frame while the axis glides. So the count was of
three mechanisms and the claim about one, and the verdict moved with whether the other two
happened to be quiet -- 138 of 138 on one run here and 137 on the next, on identical code.
  Counting the tick's own entry, `askSlowPass`, settles it by construction rather than by luck:
  the rota asks on tick 0 of every 5, so asks are `ceil(ticks/5)` and the band has margin at any
  window length. Measured 3 asks over 17 ticks against 7 redraws in the same window.
  The collapsed half moved the opposite way for the same reason. Its claim is that nothing is
  *drawn* while the section is shut; collapsing the canvas fires the resize observer, which
  asks, and the slow pass then drops the owed job. It counts draws and reports the dropped ask.
  Rejected: widening the band, which is what a run this shape invites and which would have kept
  a check that answers a question nobody asked. The rule the two waits races produced --
  settle on what moved -- has a sibling here: **count the mechanism the claim names.**
  Verified by breaking on purpose, and committed in that order: four presses of the axis switch
  inside the window give 7 redraws over 17 ticks, which the old instrument fails and the new one
  passes. The switch's own redraw is now a check rather than noise -- four presses, four redraws
  on the spot, none of them the tick's.

**Waits are conditions page reports, not spans of clock.** Harness opened with 115 fixed
waits against 3 conditions; it carries 16 fixed waits against 21 conditions and 33 frame
waits today. Four kinds of wait, and only two were races. Camera ease and settling after
click both become `waitForFunction` over what page says: stance standing still
(`settleCamera`), scene or selection count reached (`settleCount`, `settleSelection`),
drawer, help panel or tree branch carrying its class (`settleDrawer`, `settleHelp`,
`settleBranch`), panel's own five-a-second reading having run (`settleReading`). Pacing
inside drag loops becomes `waitFrames` -- kept rather than deleted, since steps are what
makes gesture real and frames are what page moves in.
  Remaining 16 are measurement windows, each saying so in comment at its own site: sampling
  span of real time is measurement rather than race, and so is check whose claim is that
  *nothing* happened, which has no event to wait on. Long press and held key stay wall time
  for same reason -- how long finger or key is down is what caller asked for.
  `settleReading` waits on `ms_refresh_ui`, tick's own clock, rather than on any row it is
  waited on for: ruler, camera fields, tree rows and curves are all written by that tick, and
  waiting on one of them would assert what check goes on to ask.

*Checked.* Verified by running: five runs after conversion pass 135 of 135, against three
before it, at unchanged sample sizes.
  **Unverified**: one run in six failed `and under it the same accounting still holds` at 49
  of 50 frames. `SHARE_KINDS_ACCOUNT` is 0.995, which over sample of 50 rounds up to *every*
  frame, so slack that constant exists to give straddling frame is not there at this sample
  size. Pre-existing, and left alone here: waits were not what decided it.

**Pixels are read through compositor, and reading carrying no picture is refused rather than
returned.** Context keeps no drawing buffer (`gl.ts` says why), so `readPixels` is sound only
from inside frame that drew. Five checks each held their own copy of that wrapper, and four
compared one reading against another -- so canvas reading back all zero passed all four, and
failed only fifth, which is what caught it. Reading now comes from
`page.locator('#gl').screenshot()`, decoded in page, through one `tools/drive/canvas.ts`: it is
what reader sees, and it is immune to buffer being taken after frame that filled it.
  Reading raises rather than reports: canvas nobody can read is instrument lost, not check
  failed, and reporting it would leave every later pixel check resting on nothing.
  **Refusal is of one colour, not of black.** First guard tested for all-zero, and runner
  answered with canvas-shaped sheet of *white*: `[255,255,255]` at moon where this machine reads
  `[44,6,24]`, seven of eight edits reporting canvas unchanged, every comparison agreeing with
  every other. Three checks went vacuous second time, on same nothing in other colour. What
  makes reading empty is that it carries one colour, whichever colour, so that is what is
  refused, and fixture drives black *and* white for that reason.
  That four were vacuous is arithmetic rather than inference. `pool`'s check reported hash
  1426046701 from runner; same FNV fold over all-zero 1200x900x4 buffer at its own stride
  gives exactly 1426046701, so it had compared nothing against nothing.
  Costs about 0.49 s per reading against microseconds for `readPixels` -- 0.43 s capture and
  0.06 s decode -- paid about 19 times over run rather than once per frame.
  **Element capture takes region page canvas occupies, not canvas alone**, so chrome
  composited over it lands in reading: first run of this reader failed held-placement check on
  2,411 pixels, and cropping them showed undo button lighting up after that check's own edit.
  Every sibling of canvas is hidden for length of capture and put back after, by `opacity`
  so nothing leaves layout and nothing is blurred.
  **Masking cannot serve here, which is worth one line so it is not retried:** `#overlay` spans
  viewport, so masking `body > *:not(#gl)` covers canvas whole. Probe returned one colour,
  centre `[255,0,255]`.
  **Capture waits on compositor rather than on one frame.** Hiding chrome injects style, style
  forces recomposite, and software rasteriser does not finish it inside single frame first
  version waited -- capture then catches page behind canvas, which is where sheet of white came
  from. Reading is taken again until it carries picture, up to ten times: settle on what
  arrives, not on clock, which is rule two sections above applied to instrument rather than to
  scene.
  **Unexplained**: why runner read blank through `readPixels`, and white through compositor.
  Neither Chromium here reproduces either: full browser and headless shell both read every one
  of 1,080,000 pixels lit, no GL error, default framebuffer bound, from inside and outside
  drawing frame alike. Runner's browser is different binary (see below) and was not obtainable
  here, so timing account above fits evidence rather than being driven against reproduction.
  **Verified on runner**: the reader reads the scene there, 138 of 138 on run 34218424425,
  after two runs that did not.
  **The rate is not settled, and no count belongs here.** Every runner run of this reader has been
  green since 34218424425, the first, and the old reader failed one run in three — so *n* greens
  in a row is what luck gives (2/3)^*n* of the time, which is 30% at three, 13% at five, and under
  2% at ten. That is the whole of what can be said without a number, and a number is exactly what
  this file cannot hold: only a push of this project adds a sample, so the merge carrying any
  tally invalidates it. Issue 77 carried the running count while the curator's next move turned
  on it; that move has been taken and the issue is closed, so what stands here in place of a
  tally is a boundary and a deduction, neither of which a later push can falsify.
  **The sample spans two browsers now, and the reader was green on both.** On `main` the runner
  drove the snap through run 34399034311 and drives what `package-lock.json` pins from 34404833659
  onward — the curator's `RGA_CHROMIUM` step went between those two runs (#98), and both are
  green. Every `push` run on `main` since 34294113589 has passed, which is a deduction rather
  than a tally — `driven` gates `audit`, so one red reader reddens the whole run, and none of
  them is red. The snap was the last variable standing when this section was written and it is
  not standing now; blankness has not returned without it. That moves the compositor reader from
  *consistent with the cause being gone* toward *the reading was the cause*, and it does not
  settle what the cause was, which stays **Unexplained** above: neither Chromium here ever
  reproduced it, so nothing has been driven against a reproduction.

**The harness resolves its own browser, and drives Playwright's pinned build by default.**
Order is what `RGA_CHROMIUM` names, else the build `package-lock.json` pins, else `chromium`
on `PATH`; `drive` fetches the pinned build first, exactly as it fetches faces. The lock fixes
`@playwright/test` at 1.63.0 and that version fixes the browser revision (1243 today), so this
machine and the runner drive one binary rather than two — which is the property a harness
comparing pixels wants. Ruled on repository issue 77: the curator's first ask was `PATH` first,
and the evidence below moved it.
  **The pin is a version, not a digest.** Playwright publishes no checksum for the archive it
  serves, so those bytes arrive on TLS alone, as the compiler tarballs do. Stated rather than
  implied. Rejected: digesting the extracted binary, which differs by platform and architecture,
  so pinning one would make the project unbuildable anywhere else without editing committed
  source. Measured on this container, 2026-09-09: 11 s cold, 0.8 s warm, since
  `playwright install` keeps a build already at the pinned revision.
  **`chromium` on `PATH` is last, it carries no version, and nothing here installs it.** Verified
  with `apt-cache showpkg chromium`: on Ubuntu 24.04 the name carries no version of its own and is
  provided solely by `chromium-browser 2:1snap1-0ubuntu2`, the snap transitional shim. It was
  declared in `SYSTEM` while the workflow named it; the workflow stopped (#98), so the package
  went with it (#96) and this rung is now whatever a machine happens to carry. It exists for a
  machine that cannot fetch Playwright's build at all, and on such a machine an unpinned browser
  beats no browser — that is the whole of its case.
  **The runner drives the pinned build now, and its own cache is keyed on the same lock.**
  `check.yml` caches `~/.cache/ms-playwright` on `package-lock.json`, which is the file that fixes
  the revision, so the tree the lock names is the tree the cache restores. Whether trading a snap
  install for that fetch is a net gain on the runner is unmeasured — both halves have not yet run
  enough for a figure, and the figure belongs on repository issue 79 rather than here.

  Guard is checked against fixture it stands up itself (Article IX.8): black canvas of its own,
  which is hardest case, since dark scene and no scene look alike. Check runs before any check
  leaning on reader does.

**Comet's band caught port's own defect rather than needing widening.** First port selected
horizon line through `nimSelectOnly`, which moves Nim's selection and leaves page's render
snapshot behind it, so overlay drew no marker and comet advanced only on harness's own two
reads: 1.35 px against 5-60 px band. Selecting through page's `selectOnly`, as every pick
path does, gives 33 px. Every check reading what page *drew* goes through page's own entry
for that reason.

**Aim tween moves what drag is reaching for.** Press starts glide of camera's pivot toward
drag, so anchor read at press names where object *was*; drags aimed there let go over empty
glass and build nothing. Two legs chase destination's live pixel each step for that reason,
and settle on it before releasing.

**TypeScript rather than Nim, and that is argued rather than assumed.** Playwright's surface
is about fifteen bindings — genuinely one page of glue, as `dance_ontology` found for its own
driver. What decided it is that harness's calls are overwhelmingly `page.evaluate` bodies
naming bridge's 157 exports, which `build/bridge.d.ts` types. Through Nim's foreign-function
glue each becomes unchecked string, and vocabulary pass renamed every one of those exports:
string version compiles clean and fails one check at time. Put to curator as issue 48, since
Article II.9 reads both ways here.
  `@types/node` is pinned for node's own globals. Its declarations clash with DOM lib, which
  `evaluate` bodies need, so lib check is skipped: that skips checking *inside* declaration
  files, never calls against them.
  Page-script names harness drives are hand-declared in `tools/drive/page.d.ts`, in three
  groups: page's own selection and chrome entries, exceedance window, and tree, rings and
  objects list. Bridge's exports are never hand-written; reach for one first, then for DOM.
  **Cost of that file is coupling**: it names page internals no export exposes, so renaming
  one breaks harness rather than page, and `tsc` is what says so. Accepted because checks it
  buys — that curve is distribution, that tick writes only rows that moved — cannot be asked
  any other way.

**Settling on stance alone cannot tell camera at rest from camera not started.** `settleCamera`
waited for two consecutive stances to agree. Nothing a check calls moves camera itself:
`nimSelectOnly` and its kin say what is picked, and `offerAim` inside `nimBuildFrame` turns that
into ease -- after `advance` has run for that frame. So both polls can land before ease begins,
agree, and hand check camera that never moved (repository issue 73).
  Fixed by asking ease rather than inferring from stance: `nimCameraCarrying` reports
  `goal.isSome and not is_arrived`, derived from tween rather than tracked beside it, and settle
  waits one draw first, since that draw is what arms ease.
  Read failure as *never moved*, not *moved wrongly*: runner reported `one pick ->
  0.00,0.00,1.00` where object sits at `-2.50,2.00,5.50`. `0,0,1` is opening pivot untouched.
  Curator's own reading was that one half lacked settle other half had. Both halves call it;
  what differs is that single pick is first action after `Home`, with camera fully at rest, so
  ease starts latest relative to polls.
  Second instance of this shape here, after `settleTurn` polled computed transform for two equal
  reads. Rule that comes out of both: **settle on what moves, not on what has stopped changing**.

*Checked.* Verified by running: 139 of 139 pass through `tools/build.nim drive` on assembled
page, in Chromium, software-rendered.
  Verified by breaking on purpose: with `settleCamera` returning at once, run drops to 131 of
  136 and every loss is framing -- orbit about pick, second pick coming in, plane to two fifths,
  anchor held in flight, tap clearing selection. That is what says these checks fail when settle
  returns early, and which ones.
  **Unverified until runner says so**: race does not reproduce on this machine, so passing run
  here says no regression rather than no race. Two green runs on runner are what settle it.
  Every section of prototype's own harness is ported.
That harness carries about 140 check sites — 125 reported directly and 15 through band
reader — and this one 151; neither figure is count of claims, since both carry guard reports
that fire only where check cannot be set up.
  **Runner reaches this layer, and both halves of it.** `driven` job drives page on every push
  since issue 47 was ruled, so green there is runner's word rather than someone's report. Desktop
  half was skipped there for want of SDL3 until `desktop` began fetching and building it, which
  repository issue 91 ruled: all 161 checks now answer for themselves on runner rather than 139
  of them.
  **Unmeasured**: figures above are this container's, software-rendered, and say more about
  swiftshader than about any GPU. Bands, not figures, are what checks assert.

Browser Front-End
---
**Page is one self-contained file.** It opens from `file://` or from an artefact host that
reaches no font host and no script host, which is why every face is inlined as base64 and
why every script is concatenated into `pages/shell.html` at its `@SCRIPT@` token.
`tools/build.nim web` does that assembly; `pages/shell.html` stays whole markup rather than
ending mid-`<script>` as prototype's did, since committed page that cannot parse alone is
page no checker can read.

**Scripts share one global scope rather than importing each other.** TypeScript 7 removed
`outFile`, so compiler no longer bundles, and page cannot resolve ES imports without server.
Files therefore carry no top-level `import` or `export`; compiler checks them as one program,
each emits its own script, and `SCRIPTS` in `tools/build.nim` is order they concatenate in.
That order is load-bearing, since `const` is not hoisted.
  Rejected: bundler, which is second toolchain for one concatenation this build already does;
  one file of five thousand lines, which loses every boundary sections already had.

**Article II.9 is boundary that matters.** Every join, meet, pick, drag and camera move is
computed by `src/browser/bridge.nim`, compiled from same modules desktop draws through;
TypeScript owns WebGL, DOM and pointer events alone. Each script argues for itself in its
header on phrase `not Nim because`, which `justification.nim` demands of gated kind.

**Bridge's declarations are derived, never kept beside it.** `tools/build.nim declare` reads
bridge's own `{.exportc.}` signatures and its three boundary records, and writes
`build/bridge.d.ts`. Hand-written copy of 157 signatures would be second home for each, free
to drift; this has one. Cost: type-checking needs `declare` run first, which `types` does.

**One verb holds every check that needs no browser.** `tools/build.nim types` is `declare`
and both type-checker configurations, and stops there: no `nim js`, no faces, no Chromium.
`web` and `drive` both call it, so neither writes those steps again.
  Written for runner to run, at curator's ask (repository issue 47): it reaches 10,676 lines
  of TypeScript and agreement between bridge's 157 `exportc` signatures and derived
  declarations, and it needs only Nim and npm, both already pinned.
  Verified by breaking it on purpose: renaming `nimSceneHandles` in `bridge.nim` without
  touching anything else fails `types` with `TS2304: Cannot find name 'nimSceneHandles'`,
  which is drift caught at build rather than at run time.
  Two configurations rather than one, since page's scripts target browser and harness targets
  node; `web` running harness's check too costs one `tsc` and keeps one verb honest.

**Type-checking runs under `strict`, `noUncheckedIndexedAccess` and
`exactOptionalPropertyTypes`**, which CONTRIBUTOR.md now requires of any TypeScript. Neither
extra flag proved unworkable against `lib.dom`, which is what issue 27 asked to be told about.
Indexing therefore reports
absence, and bridge's flat buffers are read through `flatAt` and `pointAt` rather than guarded
at each of hundred sites: buffers arrive carrying their own count and every walk is bounded by
it, so absence there is impossible and zero is what unwritten handle would mean.
  Element lookup splits in two for same reason: `elementById` fails loudly for markup this
  build ships, `elementIfPresent` reports absence for control that is genuinely optional.
  Losing that split would turn absent optional control into thrown error mid-frame.

**Node dependencies are pinned and their checkout is not committed**, as Atlas already does
for packages: `package.json` and `package-lock.json` are committed, `node_modules/` is
ignored, and `nim r tools/build.nim assets` fetches faces. Pins are `typescript` 7.0.2 and
`@playwright/test` 1.63.0, both from npm, both MIT. Lockfile npm generated for those two
passes form rules as generated: 437 lines, longest 123 runes, **0 findings** through
`koch tree`. Widest line carries one registry URL of 105 runes, which
unbreakable-token exemption covers, as curator's own measurement predicted. Committed unreformatted.
  Six faces from `@fontsource` on jsdelivr, all SIL Open Font License 1.1: Commit Mono,
  Noto Sans at 400 and 600, Noto Sans Math, Noto Sans Symbols 2, Noto Serif. Never committed,
  since audit cannot read them; licence notice travels with copies.

**System packages are declared as data in build driver, reached by verb.** `SYSTEM` in
`tools/build.nim` pairs each package with what it is for, and `system` prints those names one
per line for caller to install (CONTRIBUTOR.md, "System dependencies"). Declaration lives in
driver rather than in file of its own: `.nim` is kind audit already reads, output is
machine-readable so CI installs from this rather than from names written into workflow, and
registry admits no second build verb.
  Prints rather than installs: which package manager serves them varies by machine, while list
  is this project's. Reason stays in declaration rather than in output, which is what keeps
  output pipeable.
  No version is pinned and none is invented -- package's version is whatever machine carries.
  What *is* pinned is every byte fetched at build time, below.
  Asked as issue 60 before writing anything, since three homes I proposed were all wrong;
  ruling put it here.

**`drive` fetches faces; `web` refuses without them.** Split is deliberate rather than
inconsistent. `drive` is asked for answer -- run every check and report -- so it satisfies its own
precondition; `web` is asked to assemble page, and caller reaching for it directly is building
rather than being given, so absent face is their error to see by name.
  Cold checkout is what showed it. Runner restored Atlas, installed node packages, derived
  declarations and compiled bridge, then stopped at embedding with `Missing face ...; run
  `assets` first` -- every expensive step done and one cheap one missing (repository issue 47).
  Costs nothing warm, which is what makes it safe to chain: `assets` skips every face already
  carrying its pinned digest, so warm run fetches none.

**The digests left this project, and what stayed is which faces it draws with.** Two targets
drawing Article X.8's three families pinned four of the same files byte for byte, which is the
duplication Article II.9 names, and the curator built one store to hold them: `koch assets`
takes names, fetches what is missing into `~/.cache/koch/assets`, checks each against
`curator/audit/src/assets.nim`, and prints a path per file (repository issues 116 and 124).
  It is a store of *any* file fetched at build time rather than of faces — CONTRIBUTOR.md names
  that class already, and faces are its only instances today. This project's own `assets` verb
  and the repository's `assets` verb share a word and are different drivers: one asks the other.
  `assets` is a copy out of that store now rather than its own fetch-and-verify. Everything below
  about *why* each byte is pinned still holds — it is simply held once for the repository instead
  of once per project, and the paragraphs are kept because they are why the store exists.
  **What did not move is the choice.** Six `woff2` for the page and six faces for the desktop
  binary are this project's, and they differ from the other target's: this one draws maths and
  symbols, that one draws italic serif. The store says what bytes a name is; it never says which
  names a target wants.
  **`web` still reads the bytes twice, and now without holding a digest to read them against.**
  `assets` writes `build/fonts/store.list`, one line per face naming the store entry it was
  copied from, and `web` compares its input against that entry before embedding it. So the second
  reading survived adoption without this project knowing where the store lives or what digest
  names an entry — both of which are `assets.nim`'s to know.
  **Verified by breaking it, twice.** With `store.list` moved away, `web` refuses and names
  `assets`; with one byte appended to a copied face, it refuses and names both the copy and the
  store entry to compare it against. Re-running `assets` heals the second, copying one face and
  keeping eleven.
  **Verified by what did not change**, which is the point of the exercise: the page built from the
  store is byte for byte the page built from this project's own fetch — `6e0c41ec…` before and
  after, 3,911,946 bytes. The store was designed to hold the same bytes, and it does.
  **Cost**, measured end to end through this project's own verb rather than through the store's:
  `tools/build.nim assets` is **8.8 s** with both the store and `build/fonts` empty — twelve
  fetches plus compiling koch — and **0.36 s** warm, when it copies nothing. `koch assets` alone
  is 6.6 s cold and 0.18 s warm for the same twelve, and the store holds 4.1 MB.
  `curl` and `coreutils` stay declared because they are still needed — one level down, by the
  verb this asks on its behalf.

**Each face carries digest of bytes expected, and build refuses anything else.** Host serves
whatever it serves, and `web` embeds these bytes into artefact readers open, so wrong byte
fetched is wrong byte shipped. Every other external thing here is pinned -- compiler to commit,
packages to lock file, `pga` to commit -- and this fetch was sole exception (repository issue
47). Digest sits beside face in `FACES`, so pin and thing pinned cannot drift apart.
  **The package version sits beside it, and that is a second pin rather than decoration.** A
  digest says what bytes are right; it cannot make a host serve them. The fetch used an
  unversioned jsDelivr path, which serves whatever resolves — and one face was already past that
  when a curator sweep asked (repository issue 111). `@fontsource/noto-sans-math` 5.3.0 renamed
  this face's subset from `math` to `latin`, so 5.3.0 does not carry the file at all, and the
  unversioned URL kept working only because jsDelivr fell back to **5.2.8**, the newest version
  still holding what was asked for. Read from the response: `x-jsd-version: 5.2.8` against a
  `latest` of 5.3.0.
  So the build worked by an undocumented fallback, which is a build nobody can repeat. Each face
  now names its own version — five at 5.3.0 and the math face at 5.2.8 — and two of them
  differing is what pinning the *fetch* rather than the family looks like. Verified by refetching
  cold with `build/fonts` removed: six of six digests match at the versions named.
  Checked twice, at both places bytes matter: `assets` verifies what it fetched, and `web`
  verifies again before embedding, since `assets` may have run long ago and disk is not
  evidence. Mismatches across six are collected and reported together rather than first raising,
  since host republishing family moves several at once.
  `assets` leaves face already carrying its pinned digest alone, so verb is idempotent and
  second run fetches nothing. That is also cache key CI keys faces on, which is why pinning and
  caching arrive together.
  **`sha256sum` rather than anything in Nim, and deliberately.** No digest of that strength is
  in reach: curator recorded all three routes rejected on `curator/audit/src/provenance.nim` --
  `std/sha1` deprecated and warning on every build, `checksums` package nimble install in CI for
  one hash, `std/hashes` unstable across compiler versions. `assets` already shells out for
  `curl` and `web` for `base64`, so this adds no dependency either lacked. Deriving SHA-256 in
  Nim rejected outright: crypto primitive is last thing to hand-roll.
  **What cannot be pinned is said rather than implied.** Clone carries commit and apt package
  carries none that survives across distributions, so none is manufactured for one; same shape
  of honest limit `compilers.nim` already records for fetched compilers, trusted on TLS alone.

**Three faces, three roles, and nothing else picks between them.** The Architect's standard:
Noto Serif for titles, Noto Sans for body, Commit Mono for code and monospace. Both front-ends
draw it — the page through `--serif`, `--sans` and `--mono`, the desktop through `guiHeader` and
`guiMonoPush`/`guiMonoPop` — so a rule stated once is reached through two mechanisms rather than
asked to agree with itself.
  **What counts as a title was looked up rather than asserted**, since the answer decides where
  the serif goes. Material 3's type system separates *title* styles from *label* styles, and puts
  "text inside components" — buttons, tabs, chips — in the label role, drawn in the interface
  face rather than the display one. Butterick's rules for all caps (5–12% letterspacing, caps
  work at small sizes) cover the small uppercase group labels, which keep their 0.06em tracking
  and stay sans. And the guidance on monospace is that it is for code and for text whose columns
  carry meaning, with `font-variant-numeric: tabular-nums` on a proportional face preferred for
  ordinary figures.
  So the serif took the headings that name a section and the application's own name, and three
  things moved *out* of the mono face: the help tab strip and the two toggle-chip rules, which
  are labels inside components. The objects count sits inside a heading and would have inherited
  its serif, so it names the interface face outright and keeps its tabular figures.
  **Commit Mono splits its ligatures across two switches, and the page needed both.** Its GSUB,
  read out of the embedded `woff2` itself, carries `calt`, `cv01`–`cv11` and `ss01`–`ss05`. Most
  of the ligatures ride on `calt`, which browsers apply unasked, so those had been drawing all
  along. The arrows and comparisons do not: they come from the author's opt-in sets, named by his
  own feature sources — `ss01_less_equal.fea`, `ss02_arrows.fea` — and the page drew `=>` as two
  glyphs until it asked for them.
  Driven over four rows of sequences, each feature switched on and off by itself:

  | row | `calt` alone changes it | `ss01`+`ss02` change it |
  |---|---|---|
  | `=> -> <- <= >= != ===` | no | **yes** |
  | `>>= <<= \|> <\| ++ -- :: ...` | yes | yes |
  | `/* */ <> && \|\| ?? ?: \|=` | yes | no |
  | `=~ #{ www 0x ;; ## __ ~~` | yes | no |

  So the stylesheet does two things rather than one: `font-variant-ligatures: common-ligatures
  contextual` says outright what was working by default, since a reset writing `none` for
  crispness would take `calt` with it; and `font-feature-settings: "ss01" 1, "ss02" 1` asks for
  what was never on. No combination moves a column — 365 px on every reading — which is what a
  monospace ligature has to do.
  **This corrects a claim this record nearly carried.** The first reading said the face
  publishes no `calt` at all, on the strength of the author's own `otf` and variable builds,
  which genuinely carry none — and of a browser test that turned `calt` *on* twice and never
  once off. `contributor/sincopa/dance_ontology` said the opposite on repository issue 116 while
  this was being written, which is what sent it back to the file. Both readings were half right:
  the distributed `woff2` carries `calt` and the author's repository builds do not, so the page
  and the desktop are not drawing from the same feature table even where they draw the same
  letterforms.
  **Set at the root, and that is checked rather than assumed safe.** Noto Sans and Noto Serif
  publish no `ss01` or `ss02` at all (they carry `ss03`, `ss04`, `ss06`, `ss07`), but Noto Sans
  Math does publish an `ss01`, and the mono stack falls through to it for every operator. So the
  operators, stars and subscripts this project draws were rendered with the sets on and off and
  compared: identical. The one face that could have been disturbed was measured rather than
  reasoned about.
  **The serif ships at 600 alone, because 600 is the weight every title is set at.** It shipped
  at 400 before, and every title asks for 600 — so no title was drawn in the face the page
  shipped: CSS matches the nearest weight in the family and leaves the browser to make up the
  rest. A face nothing draws is weight carried for nothing, and a weight nothing ships is a face
  the reader's browser invents; Article X.8 refuses both. So 400 left and 600 arrived, 15 kB of
  it, and the page grew by 1,804 bytes on the swap.
  **The check written to hold that was wrong twice, and how it was wrong is worth more than the
  check.** It compared the live heading's width against canvas measuring the same string in each
  face. The heading carries `letter-spacing: 0.02em`, which canvas does not, so the live figure
  sat about 1.3 px above both — and that gap was read as evidence of a synthesised weight when it
  was only the tracking. Then, with the real 600 face in place, both faces measured `apply` at
  35.0 px, so width could not have parted them at all. It reads pixels now: the heading is shot
  as the page has it and again with the interface face forced onto it, and a face that never
  arrived makes one picture where there should be two. Nothing was loosened to make it pass.
  **The desktop draws the same three roles from the same three families.** `NotoSerif-SemiBold`
  matches the page's 600 rather than being merely serif, and `CommitMonoV142-400Regular` sets
  notation, figures and the message line. The mono face has both supplementary ranges merged into
  it, as the interface face does, because the rows it exists for are exactly the rows carrying
  wedges and subscripts; the title face has neither merged, since every heading here is a word
  this source writes.
  **Commit Mono comes from its author's own repository, which is a second host and says so.**
  `@fontsource` ships `woff2` and `woff` alone, and the desktop reads outlines through
  `stb_truetype`. What that repository publishes is `otf` with **CFF** outlines rather than
  TrueType, and whether Dear ImGui would take it was driven rather than assumed: pointing
  `RGA_FONT` at the file and running `--drive-keys` reported 3 of 3, and a 300-frame screenshot
  drew every glyph including the merged operators, with no `.notdef` box. Its file name says
  `V142` at tag `1.143`, which is what upstream ships; the digest pins the bytes either way.
  **One check outside this work gave two verdicts on the same code, and that is recorded rather
  than left.** `driveRendered` asks for at least 20 frames timed inside a 1,200 ms window. Running
  the whole repository's checks and a second driven run at once on this container, it read **19**
  and failed; alone on the same commit it reads **27** and passes. The floor is a fixed count
  against a fixed span, so what it really asserts is that the machine drew 20 frames in 1.2 s --
  about 17 fps -- rather than anything about this page. CONTRIBUTOR.md's rule is that a check
  gives the same verdict on the same code, and where it does not, the check is what is wrong. The
  cause here was load this session created, not the runner's, so nothing is changed today; the
  fix, when it comes, is to read the count against frames actually drawn rather than against a
  span of clock.

  **Ligatures cannot reach the desktop at all, and that is a limit rather than an omission.**
  Dear ImGui shapes no text — it maps codepoints to glyphs and advances — so no GSUB feature
  fires, `ss01` and `ss02` included. The two front-ends share the letterforms and do not share
  the ligatures. Nothing in the panel currently writes a sequence that would form one, so the
  difference is invisible today; it is written down because the day something does, this is why.

*Checked.* Verified by running cold: `clean` removes `build`, `bin` and `nimcache`, then `drive`
fetches six faces and reaches 139 of 139 with no step run by hand -- which is runner's own case.
Re-measured after `drive` gained desktop half, so cold run now builds and drives both front-ends
rather than page alone. Second run immediately after fetches none. `web` alone on same cold tree
still refuses by name, which is behaviour worth keeping rather than side effect.

*Checked.* Verified by breaking on purpose: one digit changed in one committed digest makes
`assets` re-fetch and refuse, and `web` refuse to embed, each naming face and both digests;
restored after. Verified by fetching: all six digests taken from fresh fetch of host, and each
matches copy already on disk, so pin is live fact rather than whatever was cached here. Verified
by running: page rebuilds byte for byte at 3,906,930 bytes with verification in place, and
`assets` run twice fetches six faces then none.

*Checked.* Verified by running: page was built and opened in Chromium, and looked at. Grid,
three world axes, plane's disc and rim, three points, chrome and scale ruler all draw; scene
reports five objects, canvas sizes to viewport, and console reports no error. Verified by
type-checker: every script clean under three flags above, with no `any` and no non-null
assertion used to silence them. Verified by running: three suites pass on pinned commit
through `koch tests`, unchanged at 323, 302 and 310 cases, which says conversion moved no rule
out of Nim.
  **Partly driven now**: held keys, wheel, mouse pan and touch are checked by harness; see
  Driven Checks for what it covers. Scene save and load remain **untested** in this
  repository: nothing drives file picker.
  **Unverified**: no human has driven this page.

Desktop Front-End
---
**Two libraries are bound rather than wrapped, and only where they are called.** SDL3 owns
window, input and OpenGL context; libGL owns driver. Both are external concerns this project
exists to look past (Article II.8), so `src/desktop/sdl3.nim` and `src/desktop/opengl.nim`
declare only symbols called, and each declares through library's own header, so C compiler
owns every struct layout and every prototype.
  Library flag sits in module needing it -- `{.passL: "-lSDL3".}`, `{.passL: "-lGL".}` -- never
  in configuration, so any binary importing one links without repeating anything.
  Cost is that development headers must be present to compile; see README's build section for
  which packages carry them.

**Mirrored constants are checked against header's own, by generated assertion.** SDL3's event
kinds, scancodes, modifier masks and window flags are mirrored as Nim constants so `case` can
bind them, and every mirrored value is paired with header's name for it in one table.
`CHECKS_MIRROR` walks that table and emits one C++ `static_assert` per pair, so binding that
went stale fails to compile rather than fails to work. Both sides of each check read from same
table, so mirror cannot drift from assertion guarding it.
  Verified by breaking it on purpose: moving `Scancode.Home` from 74 to 75 and changing
  nothing else fails compilation with `static assertion failed: SDL3 binding is stale:
  SDL_SCANCODE_HOME was renumbered.` Restored after.
  OpenGL enumerants are written as literals instead, and deliberately: their values are fixed
  by OpenGL specification and never renumbered, which is not true of any SDL constant.

**Dear ImGui is reached through C entry points, because there is no symbol to bind.** Its
interface is C++ with overloads, default arguments and namespaces, and Nim's `cpp` backend
imports none of those three -- so `src/desktop/gui_shim.cpp` flattens slice this visualiser
calls into plain C, and `src/desktop/gui.nim` binds that. This is Article II.9's first ground
in its plainest form, and shim's header says so: no glue reaches these widgets from Nim at any
price, since there is no symbol for glue to name.
  Facade rather than generated binding: it declares exactly widgets used, and every default
  relied on is written once here rather than repeated at every call site. Cost is that adding
  widget touches two files.
  Repository's first `.cpp`. Kind is registered *gated* (issue 26), so form rules reach it and
  `justification.nim` demands its header carry `not Nim because`. Whole 649-line file drew one
  finding on first check: `Supplemental mathematical operators A`, where checker read Unicode
  block's suffix as article. Corrected to block's real name, `Miscellaneous Mathematical
  Symbols-A`, which is what U+27C0..U+27EF is called -- comment was wrong as well as flagged.

**Dear ImGui is compiled into binary rather than linked, and pinned by commit.**
`fd13a1e8923a0a7077b404fc36fd063b25a0c0b5` of `ocornut/imgui`'s `docking` branch, MIT licence,
cloned into `deps/imgui` and never committed, as Atlas checkouts are. Four core translation
units and both of its own backends -- SDL3 and OpenGL 3, unmodified -- compile straight in, so
no prebuilt library has to be found at link time.
  `IMGUI_USE_WCHAR32` is set by compiler flag rather than by editing checkout's `imconfig.h`:
  notation carries Lengyel's bold operands (`𝐦`, U+1D426) and 16-bit `ImWchar` cannot express
  codepoint past U+FFFF, while edit to checkout would not survive reclone.
  Path is `--define:visualiser.path_imgui`, resolved against module's own directory, so
  checkout elsewhere needs no edit either.

**Renderer owns OpenGL names and draws `mesh`'s records through them, one program per record
kind.** Each record type has vertex shader widening it over static corner geometry, so CPU hands
over compact records and does no per-frame expansion. Buffers are reuploaded whole each frame
rather than tracked for changes: upload sits far below any frame's own reach, and nothing can be
stale after reader edits coefficient.
  Draw order is opaque first, translucent second, with depth writes off for translucent, so
  ribbons and points occlude each other correctly while plane veils occlude nothing and objects
  stay visible through them. Cost is that two veils crossing look order-dependent.
  Same records WebGL side already draws, which is what makes this cross-check rather than second
  implementation: one tessellation, two renderers, and disagreement between them is bug in one.
  That check cannot run until entry point drives both; nothing here has drawn yet.

**Panel lays out what reader edits scene and camera through, and holds only what GUI needs
between frames.** Which operands are picked, what open edit is staging, where to export;
everything else is read straight off scene and camera, so there is one source of truth and no
synchronisation step to go stale.

**Rename now covers uppercase constants, which word-boundary passes had missed.** Tasks 175-181
renamed by word, and no word boundary sits inside `ALPHA_WASH` or `WIDTH_SHAPE_WORD`, so eight
names survived in merged code, each spelling term GLOSSARY.md marks *Avoid*. Found by porting
panel, which had to reach one of them. Now: `ALPHA_VEIL` and `ALPHA_VEIL_SKY` (`mesh`,
`tessellate`), `WIDTH_KIND_WORD` (`scene`), `PREVIEW_EDIT`, `RADIUS_PREVIEW_EDIT`, `FLAT_PIVOT`
and `REVISION_PLACEMENT` (`bridge`), `PIXELS_RULER_WANTED` (`diagnostics.ts`).
  None crosses foreign-function boundary: no renamed name is `exportc` and none appears in any
  script, so derived `bridge.d.ts` is byte for byte what it was. Verified rather than assumed.
  **`GHOST` could not simply become `PREVIEW`.** Nim compares identifiers ignoring case after
  first letter and ignoring underscores, and type `Preview` already exists -- so `none(Preview)`
  silently resolved to renamed variable and compilation failed. Named `PREVIEW_EDIT` instead,
  which pairs with `PREVIEW_APPLY` already beside it: one is what open edit stages, other is what
  open apply control would build. Collision forced better name than intended one.
  Left alone, since each is different word rather than retired one: `ShapedMarker` and
  `MARKER_SHAPED` use *shape* as verb, which glossary's own Marker entry does too;
  `nimInkChoosableSlots` names palette position rather than object's handle; ring buffer's slot
  is genuinely slot; and Dear ImGui's `BeginTabItem` and DOM's `currentTarget` are foreign.
  `PIXELS_RULER_TARGET` named width bar aims for, which is neither Pivot nor Mark, so it became
  `PIXELS_RULER_WANTED` rather than being forced into glossary term it is not.

**Vocabulary rename reached these three modules through compiler rather than through reader.**
Renderer and panel both predate tasks 175-181, so they arrived saying `wash`, `slot`, `target`,
`Item` and `ghost`. Core says `veil`, `handle`, `pivot`, `Object` and `preview`, so unported file
does not compile at all -- and it named every miss. Two passes of word-boundary rename missed
compounds each time (`WashRuns`, `WashKind`, `drawWashRun`; then `ITEMS_MAX`, `describeShape`,
`shapeText`), and build reported each by name. That is stronger check than review, and it is why
these were taken before entry point, which imports everything.
  One `budget` in renderer was left alone deliberately: project renamed *budget* to *mark* for
  frame-time marks, and that use was ordinary English about cost rather than term of art.
  Reworded around instead, so retired word is simply absent.

**Entry point owns window, event loop and every headless run.** `src/desktop/main.nim`
assembles meshes from scene, draws markers and overlays, turns SDL events into camera and
interaction calls, and quits. Everything it draws is asked of shared core; nothing geometric
is derived beside it.
  It also carries run modes that exist so build can be checked without sitting in front of
  it: `--screenshot`, `--frames`, `--hidden`, `--storyboard`, `--timings`, `--novsync`,
  `--fill`, and `--drive-drag`, `--drive-keys`, `--drive-select`, `--drive-undo`,
  `--drive-sky`, `--drive-help`, `--drive-assert`. Each scripted mode pushes real events
  through SDL's own queue rather than calling handler, so what it exercises is wiring rather
  than function.
  These are desktop's answer to `tools/drive/`, and they are why this front-end is checkable
  headless at all. They are not yet run here; that is next stage's work.

**Desktop's compiler flags live in build driver, not in configuration beside entry point.**
`tools/build.nim`'s `desktop` verb passes `cpp` backend and output path; project carries no
`.nim.cfg` anywhere. Reader looking for how something is built reads driver that builds it,
rather than file they must know to look for beside source. Algebra and library path stay in
`nim.cfg`, since every target, test and front-end wants same two.
  Rejected: `main.nim.cfg` mirroring prototype's `visualiser.nim.cfg`. It works, and Nim picks
  it up automatically, which is exactly its cost -- it applies invisibly to any build of that
  file, including one run by hand, and it puts second place where flags live.
  Library flags stay in modules that need them (`-lSDL3`, `-lGL`, `-lz`), so test binary
  importing one links without repeating anything.
  No `-d:release`, unlike page: this binary is driven and read rather than shipped, and its
  `--drive-*` runs report through assertions release would remove.

**Neither SDL3 nor Dear ImGui arrives as package, so `desktop` fetches both at their pins.**
That is this repository's rule about anything fetched at build time, and here it is forced rather
than chosen: Ubuntu 24.04 carries `libsdl2-dev` and no SDL3 at all, so `apt-get install
libsdl3-dev` fails on it outright. SDL3 is cloned at its tag and built into `build/sdl3` -- a
prefix inside the tree, so no step needs root and `clean` removes it like any other product --
and `checkSdl3` reads what `pkg-config` reports there, and the commit the clone stands at,
before compiling anything, at `3.2.30`, zlib licence.
  **SDL3's own build dependencies are declared too, and the runner is what found them.** Its
  cmake refuses outright where it can find neither X11 nor Wayland development libraries, since
  a build that cannot open a window is not one anybody wanted. `libx11-dev` arrives beneath
  `libgl-dev` on this container and `libxext-dev` does not, so the first machine to try without
  it was the runner. Both are declared now rather than left to arrive under something else --
  the same lesson the faces taught, one layer down.
  Verified by removing it: with `libxext-dev` gone and `libx11-dev` still present, cmake reports
  `SDL_X11 (Wanted: ON): OFF` and exits 1, which is the runner's error exactly; restored, it
  reports `ON` and exits 0.
  Cost of that prefix is `-rpath`: the loader finds a library outside its search path only when
  the binary names it, so `desktop` passes an absolute path derived from the checkout. Derived
  rather than written down, which is the distinction CONTRIBUTOR.md draws -- a committed
  `/opt/...` builds on one machine, and `getCurrentDir()` builds on every one. Binary and prefix
  are both products under the same tree, so they move or are rebuilt together.
  Rejected: installing over `/usr/local`, which the README told a contributor to do and which
  needs root. A build needing root is a build CI cannot run without being granted it, and the
  runner is the machine this had to reach.
  Pinned exactly rather than as floor: floor would claim reach across releases nothing here has
  tried.
  **The pin is a release tag, and the commit that tag resolves to is what binds the bytes.**
  `release-` prefixed to `VERSION_SDL3` is the ref that fetches, and `COMMIT_SDL3` is what has
  to arrive: `f5e5f6588921eed3d7d048ce43d9eb1ff0da0ffc`, read from the remote and from the
  clone, which agree. The `README.md` and `checkSdl3` instructions still compose the ref from
  the version — one home, no second copy to drift.
  **What that replaced overclaimed, and this line said so.** A tag is mutable and a version
  string is self-reported, so neither bound a byte: a moved `release-3.2.30` would have fetched
  other sources and `pkg-config` would have answered `3.2.30` still, and nothing in the path
  called `rev-parse`. `checkSdl3` now reads `git rev-parse HEAD` against the commit, as
  `checkImgui` already did, and `checkCommit` is the one reading both go through (repository
  issue 126).
  Verified by pinning it wrong: with the prefix already built and `pkg-config` reporting
  `3.2.30`, a `COMMIT_SDL3` of zeroes is refused by name — which is exactly the case the version
  check passes and this one does not. Held on the warm tree as well as the cold one, since
  `sdl3` returns on the version alone where the prefix already reports it, and the clone it
  built from would otherwise never be looked at again. Held before cmake too, so a refused
  clone costs no minutes of building.
  The limit is stated rather than papered over: a machine carrying its own SDL3 has no clone to
  read, and the version is then all there is of it. That path says so aloud rather than passing
  as though it had checked. The tag is kept beside the commit because `--depth 1 --branch` needs
  a ref to fetch, and the commit is what that ref fetches — which is also why a shallow clone is
  safe here and is not for Dear ImGui, whose pin sits behind a branch head.
  **3.2.30 is the newest release of a series still maintained, not a stranded one.** A curator
  sweep asked whether the pin was behind, since `main` carries 3.5.0 and `release-3.4.x` the
  current stable series (repository issue 111). Read from the branches rather than a releases
  page: `release-3.2.x` is still active and its head is 3.2.31 in progress, one past the pin. So
  there is nothing to bump for currency, and following the series to 3.4.x would be a choice
  about what to build against rather than a fix. Recorded so the next sweep stops here.
  **An odd patch number names no tag, which is the trap this replaced.** That series releases on
  even numbers alone; 3.2.31 was the head of `release-3.2.x` and no ref fetched it, so the clone
  command this project published failed outright and `pkg-config` could not have told two such
  builds apart. Repository issue 90.
  **Moved by rebuilding, not by editing the line.** Verified 2026-09-09: SDL3 built from
  `release-3.2.30` and installed, then `bin/` and `nimcache/` removed and the desktop front-end
  compiled from cold against its headers, then all 13 scripted runs driven — 22 of 22 pass,
  29.9 s for the whole of it on this container, 4 cores, software GL. The mirrored event
  constants below assert against real headers at compile time, so a release that had moved them
  would have failed the build rather than the checks; it did not.
  Found by checking rather than by assuming: prototype's own `dependencies.list` named
  `libsdl3-dev`, and this port carried that name into `SYSTEM` -- where it would have failed
  runner's install step, since that step installs from this declaration. Package does not
  exist on distribution runner runs.

**Dear ImGui is pinned to commit, and build refuses any other.** `fd13a1e8`, i.e.
`v1.92.9b-docking-35-gfd13a1e`, MIT licence, docking branch. It is compiled from source into
binary rather than linked, so it is fetched at build time -- and this repository's rule is that
anything fetched at build time is pinned. `checkImgui` reads checkout's own `HEAD` and raises
by name, naming clone command that fixes it.
  Absent from `SYSTEM` deliberately, as SDL3 is: that list is packages a package manager
  installs, and neither of these is one of them. What stays there for their sake is `cmake` and
  `pkg-config`, which build and read SDL3, and `git`, which fetches both.
  Verified by breaking it both ways: with checkout moved aside, verb names it missing and gives
  clone command; with checkout one commit back, verb names commit wanted and commit found. Restored
  after.

*Checked.* Verified by running: both bindings compile and link against SDL3 3.2.30 and libGL
through `nim cpp`, and their assertions run against real headers. Shared core compiles and runs
under that same backend too, which nothing had shown before -- it had only ever been built
through C and JS.
  Verified by running headless: Dear ImGui starts over hidden SDL3 window with real OpenGL 3.3
  core context under Xvfb, draws one frame through both its backends, reports framerate above
  zero, and shuts down without error. `isFontLoaded` answered false for that run, correctly:
  no face was passed, which is exactly what it exists to report.
  Verified by breaking on purpose: mirrored `Scancode.Home` moved by one fails compilation with
  binding's own message; restored after.
  Verified by compiling: renderer builds against this core through `nim cpp`, which is what says
  vocabulary rename reached it -- core says `VeilRuns` and `veils`, and module naming them
  otherwise does not compile.
  Verified by compiling: renderer and panel both build against this core through `nim cpp`, which
  is what says vocabulary rename reached them.
  Verified by looking: `nim r tools/build.nim desktop` then one headless run under Xvfb writes
  1440x900 PNG, and that frame was opened and read. It carries grid, axes, ground plane's disc,
  four points, and panel with objects list, coefficients and every section header -- so both
  front-ends now draw same scene from same core.
  That look found defect reading never would: top bar carried `sameLine` and tooltip left by
  control neither front-end has, and they drew `scene file` label under its own path field.
  Removed; second frame confirms row.
  Screenshot needs frames enough for entrance animation to finish -- 60 under software GL is
  not, and scene looks empty at that count. 300 is.
  Vocabulary shows in that frame rather than only in source: panel says *objects (5 of 5040)*
  and *hold still over the pivot*.
  Verified by driving: every scripted run reaches its verdict, 22 checks over 13 runs, in 24
  seconds under software GL, 2026-09-09. See Desktop Driven Checks below.
  **Unverified**: frame times are unmeasured, and no human has seen this on real graphics
  hardware -- that run was software GL, which reported no multisampled visual, so thin lines
  alias.

Desktop Driven Checks
---
**Suites test rules and `tools/drive/` tests browser wiring; this tests desktop wiring.** Same
argument as browser's: rule wired to wrong SDL event is invisible to suite that calls rule
directly. Entry point carries five scripted runs -- `--drive-keys`, `--drive-sky`,
`--drive-undo`, `--drive-select`, `--drive-drag` -- plus `--drive-help:<tab>`, one per tab.
Each pushes real events through SDL's own queue rather than calling handler, so what it
exercises is wiring.
  41 checks over 15 runs -- 16 `report` sites, of which most fire in every run that reaches
  them. Held key slides view and keeps its height; drag across bare sky turns view and builds
  nothing; undo takes construction back *and* returns view to where it built from; choice menu
  does not swallow drag after it; every help tab opens with rows in it; a run whose face is
  missing still does its scripted work; every type role is drawn in a face of its own; a
  scene filled to capacity leaves what follows its list on the window; and menu opens with
  its groups in it, offering demo at every size `orrery` has.
  Counted by running rather than by reading, and twice now that reading was wrong: this said 19
  until 2026-09-09, which is sites plus tabs with the help site counted twice, and then 22 until
  2026-09-11, which stopped being true the day the type-role verdict began firing in every run
  with a face. `drive`'s own output is the count: `grep -c "^  ok"` over `driven`.
  **These 41 run wherever `drive` runs, which is what repository issue 91 ruled.** They ran here
  and nowhere else while `drive` skipped them for want of SDL3, and `0 finding(s)` over 161 checks
  and over 139 were two claims wearing one sentence. `desktop` now fetches and builds both
  libraries itself, so the skip is gone and an absent dependency fails by name.
  Two things had to move first, and both were found by a second machine finally trying. SDL3's pin
  named no ref `git clone` resolves (issue 90). And the front-end loaded four faces by absolute
  path under `/usr/share/fonts/truetype/noto/`, which nothing declared, so a machine without them
  aborted every run inside Dear ImGui rather than degrading. Both are answered: the abort is a
  finding now, and this project ships its own faces (issue 93).

**An absent face is a finding now, and it used to be an abort.** Dear ImGui asserts inside
`AddFontFromFileTTF` where it cannot open a path, and an assertion is SIGABRT rather than a
report. The shim already skipped a face whose path is empty and `main.nim` already carried a
warning line, so the graceful path existed on both sides and nothing joined them: whatever was
declared went straight to Dear ImGui, and the warning was unreachable. Measured 2026-09-09 on a
container carrying SDL3 and Dear ImGui but no Noto packages: **12 of 12 runs aborted**, exit 1.
  `faceAt` resolves each of the four to empty where the file is not there, and says which face is
  missing, which variable names it and which verb fetches it. The interface draws in what is left.
  **Locations come from the environment first**, `RGA_FONT` and its three siblings, falling back
  to the faces this build ships -- and that fallback is what lets the case be driven at all.
  Verified by driving, committed in that order: `driven` runs `--drive-keys` once with `RGA_FONT`
  naming a path no machine carries. Before the fix that run aborts and the verb reports
  `drive-keys without face`, exit 1; after it, the run reports the finding and passes, and gains a
  verdict of its own -- focus moved and the scene stands while Dear ImGui had no face, so the
  claim is that the scripted work happened rather than that nothing crashed.
  **This half ships the faces it draws with now, as the browser half does** (Article X.8). The
  four absolute paths are gone and no machine's layout is named in source: `DIR_FACES` is relative
  to the binary, resolved against `getAppDir()`, so `bin/` and `build/fonts/` move together.
  `fonts-noto-core` went out of `SYSTEM` with them -- the package it declared is no longer what
  the front-end draws in. Ruled by the Architect on repository issue 93.
  Faces come from the Noto project's own release repository rather than `@fontsource`, which
  ships `woff2` and `woff` alone while Dear ImGui reads TrueType. Each is pinned by family tag
  *and* digest: `NotoSans-v2.013` for the interface and label faces, `NotoSansMath-v2.539` and
  `NotoSansSymbols2-v2.006` for the two merged ranges. Per family rather than per repository,
  since three families move on their own and a commit would pin all three to whenever one of
  them last did.
  **Coverage was checked rather than assumed, since a face swap turns notation into boxes
  silently.** Read from each font's `cmap` against the ranges `gui_shim.cpp` declares, comparing
  what the distribution packages carried with what is now shipped: text 379 of 416 wanted, both;
  symbols 362 of 544, both; math 1,773 of 1,952, both, with U+2AAC lost and U+23B7 gained and
  neither appearing anywhere in this project. So nothing this front-end draws moved.
  Verified by rendering, 2026-09-10: a 300-frame run under Xvfb writes a frame whose operator
  rows read `m ∧ n`, `m ∨ n` and `n ∨ (m ∧ n☆)`, with subscripted basis names beneath them and
  no `.notdef` box anywhere.
  Costs about 2.5 MB fetched into `build/fonts`, against roughly 700 kB of `woff2` for the page.
  Uncompressed TrueType is what `stb_truetype` reads, so that is the price of the rule.

**Two defaults favoured silent pass, and both are gone.** This is what running them found, and
neither was reachable by reading.
  Scripted run had no frame bound of its own, and loop ends only on one, so `--drive-keys`
  alone drove its events and then sat in loop for ever. Run now supplies `FRAMES_DRIVEN` where
  caller gave none.
  Verdicts sat behind second flag, `--drive-assert`. Without it, run drove its events, printed
  *Drew 400 frames*, exited 0 and checked nothing -- so obvious invocation was one that always
  passed. Flag is retired: scripted run always ends in its verdict.
  Rejected: bound derived per drive from its own step count. Better number, and it wants every
  drive's steps lifted out of proc they are local to -- five refactors for run that already
  ends in seconds.

**`driven` verb runs all twelve and reports every failure, not first.** Run takes seconds, and
knowing which three broke beats knowing that one did. Verb asks binary which help tabs exist
(`--help-tabs`, which prints before SDL starts), so `help.HelpPath` stays their one home and
tab added there is driven without being listed twice (Article I.4).
  `drive` chains it, so one command drives both front-ends, and it no longer stops short of the
  desktop half. Absent SDL3 or Dear ImGui is now something `desktop` fixes rather than reports:
  it clones each at its pin and builds SDL3 into `build/sdl3`, so the only remaining failure is a
  machine lacking what `system` declares, and that fails by name.
  **What that costs, measured on this container, 4 cores, software GL, 2026-09-09.** Cold, with
  neither checkout present and nothing built: **1 m 27 s** for the whole of `driven` -- both
  clones, SDL3 configured, built and installed, the binary compiled, and twelve runs. Warm:
  **29.3 s**, since a prefix already reporting the pinned version is kept rather than rebuilt.
  **On the runner, measured rather than predicted**: the `driven` step went from **215 s** with
  the browser half alone (139 checks, run 34412019616) to **411 s** with both (157 checks then, run
  34414563854), so the desktop half costs about **3 m 15 s** there against 1 m 27 s here. One run
  against one run on the same image and the same day, which is a pair rather than a rate.
  Where that lands against the rest of the job is the curator's to weigh; repository issue 79
  carries what the job already spends.

*Checked.* Verified by running: 22 of 22 pass under Xvfb on software GL, 2026-09-09, from a tree
carrying neither checkout and no SDL3 anywhere on the machine -- `driven` fetched and built both
and drove them. Verified idempotent by running it twice: second run kept the prefix and rebuilt
nothing. Verified by
breaking on purpose: drag verdict inverted, and run reported ` FAIL  a drag from one object
onto another opens its choice menu`, `1 driven check(s) failed`, verb answered `Driven runs
failed; got 1 -- drive-drag`, exit 1; restored after.

Render Paths
---
**The directory a module sits in is which render path may reach it.**

| Directory | Reachable from | Holds |
|-----------|----------------|-------|
| `src/rga_visualiser` | Both | `objects`, `euclid`, `boundary`, `mesh`, `tessellate`, `camera`, |
|  |  | `scene`, `selection`, `picking`, `marker`, `framing`, `interaction`, |
|  |  | `storyboard`, `orrery`, `neighbourhood`, `starfield`, `history`, |
|  |  | `format`, `help`, `timings`, `ramp`, `lighting` |
| `src/desktop` | `main.nim` alone | `main`, `panel`, `renderer`, `gui`, `gui_shim.cpp`, |
|  |  | `opengl`, `sdl3`, `image`, `gif`, `arena` |
| `src/browser` | `bridge.nim` alone | `bridge.nim` and page's own scripts |

`pga` is dependency above all three and shared. Shared core imports nothing outside itself
and `pga`; `src/desktop` and `src/browser` each import that core and never each other,
readable from import paths (`../rga_visualiser/`). Both front-ends sit under `src/` beside
core they draw through, which is what `srcDir` in nimble file already claims; desktop sat at
repository root until this port and nothing but history put it there.
  Both are built by same driver: `web` assembles page, `desktop` compiles binary, and neither
  entry point carries configuration file of its own.
  `arena` sits in `src/desktop` despite being general-purpose: only PNG and GIF encoders and
  desktop draw loop reach it, and JS backend cannot carve typed slices from byte array at
  all.

A shared module reaching for something only one path has is a **compile error, not a
comment**: `toCstring`, `buildChars`, `appendInt`, `appendFixed`, `saveScene`/`loadScene`
and their `std/os` and `std/syncio` imports are guarded `when not defined(js)`.

Every binding into C, SDL, Dear ImGui, zlib and JavaScript carries `sideEffect`, so a `func`
reaching one fails to compile; without it the compiler assumes an imported body pure.

*Checked.* Verified: the guard is exercised rather than trusted, because the suite runs on
both backends (see Testing); the `sideEffect` marks are what turned 51 funcs back into procs
(see Style Guide). Assumed: nothing.


Scene Storage
---
`Scene` (`scene.nim`) is a fixed-capacity structure-of-arrays arena — geometries, labels,
inks, visibility, liveness, birth stamps, creation ordinals, placing stamps, anchor
overrides — addressed by a handle assigned once on `addObject` and never moved. Free handles
thread onto an intrusive singly-linked free list, so add and remove are O(1).
`OBJECTS_MAX` = 5040 and `LABEL_MAX` = 40, both `{.define.}`-overridable. Chosen over a
shift-on-delete array whose removal renumbers every held cross-frame index; the property
everything else relies on is that **a handle number stays valid until its object is removed**.

**`Scene.bound` is the highest handle ever occupied**, and every per-frame walk runs to it
rather than to capacity. It only rises, so walking to it is safe. Three walks legitimately
run to capacity — the free list and the two object-pool strips, whose subject is how much
room is left — and `bound`'s own doc names them. A walk to capacity over five live objects
cost 13.3 ms a frame on the JS backend; a driven pin crept 2.5 → 8.8 → 13.3 ms across
three capacity rises before that was found.

**`Scene.revision` counts edits, and every writer is inside `scene.nim`**: `addObject`,
`removeObject`, `setInk`, `setVisible`, `replayFrom`, `setGeometryAt`. There is no
`var`-returning geometry accessor — it was the hole through which a caller could write with
nothing recorded, and twenty-six of its twenty-nine callers were reading anyway. Whole-scene
replacement (undo, redo, clear, every load) goes through `restoreFrom`, which issues a
revision **newer than every revision ever handed out**, `max(live, snapshot) + 1`. Not the
snapshot's own count plus one — a number a state between the two had already worn, so a
placement cache keyed on it drew six objects of the previous demo over the new one.

**Placement is invalidated per handle.** `Scene.revisions_placing` stamps each handle at the
edit that last changed it, and `restoreFrom` stamps every live handle of the snapshot. The
browser's placement cache re-places only handles stamped after the revision it last filled at.
Re-placing the whole scene per edit cost a 42 ms frame at 5,038 objects; a restore still
re-places everything, correct and a whole placement pass per undo at that size. A per-handle
diff against the live scene would cut that and was not done.

**Creation order is recorded explicitly** (`orders`, `count_created`, `handlesCreated`), not
inferred. Handle order stops being creation order the moment anything is removed, since the
free list hands the most recently freed handle to the next arrival. Sorting by `born` was
rejected on three counts that all occur: two objects added in one frame share a clock
reading; a replayed object's `born` is stamped into the future; a reused handle's `born` is
stale until overwritten. `handlesCreated` is a heap sort, O(n log n); as an insertion sort at
5,038 objects it ran 12.7 million comparisons a call. The desktop panel caches its answer
against `scene.revision`, because sorting by `born` every frame was 98% of the desktop's CPU
frame at 5,038 objects.

**`LABEL_MAX` counts bytes, so a label is cut on a character boundary and says it was cut.**
`format.appendChars` copies a UTF-8 sequence only if all of it fits; `scene.toChars` rewinds
far enough to append `…`. A 3-byte operator glyph straddling the limit once left invalid
UTF-8, which the JS backend percent-escapes into a name (`%e2%8a`). Derived names still
compound (`b ^ ground⊖ ∧ b ∨ (o ∧ ground…`) and that is left: the full name is what the
object *is*.

`Object` is a handle, not an assembled copy, and under `nim js` it holds the `Scene` by value;
the per-frame loops use the by-handle accessors instead (see Browser Pipeline).

*Checked.* Verified by suite cases: handle stability across removal; `handlesCreated` on a
scrambled arena of hundreds; `revisionPlacingAt` stamping one handle per edit and every handle
after a restore; `restoreFrom` landing on a revision no earlier state carried; label
truncation never splitting a character at any buffer size. Verified by driven check: undo
while the frame is held redraws the current scene, not the previous one. The 13.3, 42 and
12.7-million figures were read while fixing and not re-measured since.


Memory And Allocation
---
The interactive render loop allocates nothing. `format.nim` wraps C `snprintf` so per-frame
number formatting writes into stack buffers. Button-driven message building still uses
`strformat`: once per click, and the result must become a `string` for `addObject` anyway.

`arena.nim`: a plain `array[N, byte]` carved by `push[T]` and reclaimed by `reset`. Three
instances in `visualiser.nim`:

| Arena | Capacity | Backs | Reset |
|---|---|---|---|
| permanent | `CAPACITY_ARENA_PERMANENT` 160 MiB | pixel readback, every GIF frame | never |
| frame | `CAPACITY_ARENA_FRAME` 64 MiB | one PNG's scanlines, one GIF frame's scratch | per unit |
| swap pair | `CAPACITY_ARENA_SWAP` 256 KiB × 2 | the draw loop's `DrawScratch` | per frame |

Permanent capacity is sized to the storyboard run's own `arena.used + bytes_needed`, not a
round number. The **swap pair** reclaims on the way *in*: what one frame assembled stays
readable through the next while the block being moved to starts empty. A separate pair
rather than a larger frame arena, because an export's scratch is tens of megabytes on a
keypress and a frame's is under 20 KiB (the ground grid's `LINES_GRID_MAX` chords, the
largest carver) sixty times a second. The storyboard's capture loop turns the pair over in
its own `renderAt`; without that, captured sub-frames stacked scratch until the fifth
overflowed.

**The undo timeline is the largest reservation the binary makes.** A `Scene` at 5040 handles
is 1.15 MiB as a C struct (1,204,616 bytes by `sizeof` on the release compiler), a `Step`
is a `Scene` beside a five-float `Camera`, and `CAPACITY_HISTORY` = 32 of them reserve
36.8 MiB (38,549,528 bytes) against 6.2 MiB for both mesh sets. In the browser the same
timeline is roughly 105 MB of JS heap; the live page measured 85 MB at load before the
per-handle placing stamps were added and has not been re-measured since. The depth is left at
32: an edit no longer costs anything per step (see Undo/Redo), so what remains is a flat
reservation, and the lever is linear — about 1.15 MiB of address space and 3.3 MB of JS heap
a step. `BYTES_MEMORY_TOTAL` counts it; a figure omitting its own largest term is worse than
none.

GIF's LZW dictionary is a fixed open-addressed hash table (`CAPACITY_DICT` 8192, Knuth
multiplicative hashing) rather than a third arena — random-access probing within a frame,
not bump-only append. **LZW early change**: the format widens the code size one symbol
earlier on decode than on encode; a from-scratch decoder in the suite round-trips a real
frame past the growth point.

*Checked.* Verified by suite cases: the swap pair keeps last frame's bytes; the GIF
round-trip. Verified by `sizeof`: the struct and timeline sizes. Assumed: the JS heap figure
per step, extrapolated from one measurement at the earlier stamp-less layout.


Colour Palette
---
Five assignable hues — `Rose, Copper, Olive, Jade, Cobalt` — plus `Backdrop`, `AxisX/Y/Z`,
`Grid`, `Guide`, `Outline` and `Invalid` in one `Ink` enum
(`mesh.lut_ink_to_rgba`).

**`Invalid` is a reserved magenta**: seeing it means an object is wrong. The drag band wears
it over a pair that makes nothing (see Interaction Model); nothing else does. It is never
leaned on alone — magenta reads as *blue* under deuteranopia — and the preview fails to appear
beside it. Reserving it cost three hues: `Violet` and `Cerise` measured CVD ΔE 10.2 and 8.3
from magenta, and `Cobalt`, 88° of hue away, measured **6.6** because blue and magenta
converge under deuteranopia. `Cobalt` was re-derived lighter and bluer (`#5b90c7`), which
reopens the pair to 14.4.

**Do not fill the remaining arc back up to eight.** A seven-hue set put `Olive` and a new
yellow-green at CVD ΔE 0.4 and two blues at normal-vision ΔE 5.6. The axis hues flank the
reserved arc on both sides, leaving one warm arc and one cool, 162° in total; five is what
fits.

**The structural slots are not offerable as an object's colour.** `mesh` names the boundary
once — `INK_CATEGORICAL_FIRST`, `COUNT_INK_CATEGORICAL`, `inkCategorical`,
`categoricalIndex` — and both pickers and `inkCycled` derive from it. Structural slots are
declared first and the categorical run last so it is one contiguous block; a
`static: doAssert` on the count enforces that, so appending a structural slot after `Cobalt`
fails the build.

Derived under floors `tools/check_palette` measures every run:

1. Every pair among the five clears normal-vision ΔE ≥ 15 and ≥ 20° of hue, so lightness can
   never stand in for a hue difference. `Jade`/`Copper` at CVD ΔE 7.6 sits inside the
   6–8 legal-with-secondary-encoding band; shape and screen position are that encoding.
   `Rose` sits at contrast 2.78 against the backdrop, under 3:1; its always-present row label
   is the relief.
2. Axis safety: each hue clears ≥ 20° and a lower ΔE floor (4.0) against `AxisX/Y/Z`, so a
   thin fixed line is never mistaken for a filled object. Loosened from the object floor on
   purpose — a thin line needs less separation than two adjacent fills — which is what freed
   most of the wheel; the sixteen-handle set that held everything to one floor crammed every
   hue into a teal/blue/violet arc and read as one colour.
3. Every assignable hue clears CVD ΔE ≥ 13 from `Invalid`: worst `Cobalt` 14.4, `Rose` 15.2.
4. Furniture against `Backdrop` ≥ 8.0: the axes land at 15.7–25.3.

**The one declared exception.** `Jade` and `Cobalt` separate by only **3.7 ΔE under
tritanopia**, carried rather than repainted: the pair clears 12.7 under red-green deficiency
and 15.8 to typical vision, tritanopia affects fewer than one reader in ten thousand, and
every object carries shape, position and label. It lives in `check_palette.nim`'s
`EXCEPTIONS` table with a floor of 3.5 pinned just under where it measures, and its reason
prints on every run.

`check_palette` measures under **Machado, Oliveira and Fernandes (2009) at severity 1.0**.
Viénot-1999 moves borderline pairs materially — it puts Jade/Cobalt at 0.9 ΔE where Machado
puts it at 12.7 — so the model is part of the standard, and changing it means remeasuring
every floor. Red-green (the minimum of protan and deutan) carries the floors; tritanopia is
measured separately.

**Axis colours are dimmed and desaturated at compile time** through `axisTinted` from
`MUTE_AXIS_TOWARD_GREY` = 0.45 and `SCALE_AXIS_LUMINANCE` = 0.50 — the constants are the
source, not documentation of hand-applied literals. Settled by the palette gate, not by
eye: 0.62 luminance read well and *failed*, dimming having walked the green and blue axes
onto `Rose`'s own luminance (3.5 and 3.3 ΔE under red-green against the 4.0 floor); further
down clears it, the axes landing below every categorical hue.

`Ink.Outline` is retained although nothing draws with it: removing a categorical-adjacent
entry shifts every later ordinal and corrupts the colours of a saved `.rgascene`. The
debug layer's `Ink.Algebra` *was* removed, with the file format going to version 6 to carry
the shift; see Save/Load Format.

**Seed hues.** `ground` keeps `INK_SEED_GROUND`'s olive and `o` keeps `INK_SEED_ORIGIN`'s
copper — the two seeds that are not arbitrary — and `a`, `b`, `c` take the three that are
left, so nothing collides.

*Checked.* Verified: every floor above, by `check_palette` on each run, and the seven-hue
and sixteen-handle failures by the same tool when those sets were tried. Verified by
rendering: the axis dimming, and that 0.55 grid alpha read as absent (see Geometry). Assumed:
the prevalence figure for tritanopia, taken from the literature.


Geometry And Drawing
---
**Plane.** A solid rim (`RingRecord`) plus a flat translucent fill (`DiscRecord`,
`ALPHA_WASH` = 0.16) bounded by it; no crosshair, no grid, no normal shaft. Flat rather than
fading because the rim already marks the boundary. Fixed radius `EXTENT_PLANE` = 8 world
units about the plane's anchor — not camera-scaled, which visibly resizes a plane as the
camera orbits. The radius is a rendering choice: it appears in `mesh` and `picking` and
nowhere else, and every construction path reads the full `Multivector`, so a meet lands
correctly arbitrarily far outside the drawn disc.

**A meet is read back as the point it names before anything signed is asked of it.** A
meet's weight carries the orientation of the crossing and `unitize` divides by the weight's
*norm*, so that sign survives; `depthAgainst` is linear in its point, so a meet passed as it
came reports its depth **negated** on every plane met from behind its normal. `rayPlaneHit`
did that for one release: a plane joined from three of the opening scene's points picked at
0 of 462 sampled pixels while the ground plane, whose normal faces the eye, hid the fault.
Held by a suite case from both sides of one plane and by a driven check that sweeps the
canvas for a pixel picking a plane the gesture itself built.

**Line.** Two segments meeting on the line at its support, each running out to one of the
line's two vanishing points `eye ± radius_horizon*axis`. A vanishing point is a property of
the *eye*, which forces this shape: an end anchored a fixed reach from the support stops
short of the vanishing point by roughly eye-to-line separation over reach (≈6.7° for a
support 40 units out). Each segment lies in the plane through the eye containing the line,
so the pair draws exactly over the true line's projection — measured at 1e-16 of screen
skew — while the far ends sit 6–17 world units off the line along the view ray, so occlusion
is approximate there. `picking` tests both halves, through `clipToEyeSide`, a by-hand
near-plane clip mirroring the GPU's, since a screen-space test divides by depth and this
reach puts an endpoint behind the eye.

**Horizon objects** are drawn as sky: a horizon point is a fixed star at
`eye + radius_horizon*heading`, a horizon line a great circle about the eye, a horizon plane
a full-sphere dome (`DomeRecord`, `ALPHA_WASH_SKY` = 0.22). All anchor to the eye every
frame — zero parallax on translation. A full sphere, not a hemisphere: an orbit view sits
elevated and tilted down, so a dome cut at the horizontal loses sky the camera sees. Grade 4
is one-dimensional in this algebra, so every horizon plane is the same universal object.

**Draw-order invariant.** Translucent veils blend in scene order with depth writes off, so
whichever is appended last wins. Both `visualiser.assembleMeshes` and
`bridge.nimBuildFrame` insert any visible horizon plane's dome **first** (via
`objects.isHorizonPlane`), so an ordinary plane's fill blends over the sky whatever handles
they occupy. Two ordinary veils crossing still look order-dependent; accepted.

**Muting.** `mesh.muted()` blends toward the colour's own luminance (`MUTE_DESATURATION`
0.6) rather than replacing it with `Ink.Grid`, which made a muted object indistinguishable
from the grid; `FRACTION_DIMMED_ALPHA` 0.55 so muted objects read as present context.

**Draw sizes** live in `mesh.nim`, not `renderer.nim`: `DIAMETER_POINT_LEAST` 6.0,
`WIDTH_LINE_OBJECT` 2.5, `WIDTH_LINE_FURNITURE` 1.5 px, with a `static: doAssert` that object
lines exceed furniture lines. `marker` derives every clearance from them and cannot import
`renderer`. A ribbon's width is measured in *framebuffer* pixels, so the bridge hands
`drawExtentFor` the framebuffer's height rather than the window's.

**Every point has a radius, in world units, and is drawn in perspective.** `Scene.radii` holds
one per handle (`radiusAt`/`setRadius`, `addObject(..., radius)`), `RADIUS_OBJECT_DEFAULT` = 0.08 —
what the old nine-pixel sprite spanned at the opening camera, 19 units over 900 px, so old
scenes and fresh constructions open looking as they did and only gain perspective. Both
editors carry a `size` field (`EditSession.radius`, `session_edit.radius`), bounded below at
`RADIUS_OBJECT_LEAST` 0.001 because the model refuses zero outright and would take the page down
with it; `RADIUS_OBJECT_MOST` 1e6 exists because ImGui's drag widget reads *no upper bound* as
*no bounds*. A point crosses the wire as one eight-float record (`Vertex`: centre, radius,
colour) and is drawn as an **instanced camera-facing quad**, four corners in strip order from
`mesh.pointCorners`, on both front-ends: the vertex shader takes `depth = (centre − eye) · forward`,
`world_per_pixel = 2·depth·tan(fov/2)/height`, `radius = max(own, ½·DIAMETER_POINT_LEAST·
world_per_pixel)` and steps the corner along the camera's `axis_right`/`axis_up` (new fields of
`DrawScale`, carried to browser scripts as `camera_right_*`/`camera_up_*`); the fragment stage
discards outside the unit circle and fades the last pixel of rim. The rule is stated once in
Nim as `radiusDrawnAt` and its pixel reading `radiusPixelsAt`, and the two shaders are its
sibling copies, named as such. So the size is *fixed in the world* and shrinks with distance
exactly as perspective says, floored at six pixels so a distant star stays a readable dot
rather than sub-pixel flicker — that floor is the one departure from pure perspective, and it
is what keeps 4,900 catalogue stars visible. Pick, marker, cull and framing follow the drawn
disc: the pick radius is `max(RADIUS_PICK_POINT, radiusPixelsAt(...))` so a sun a hundred
pixels across is picked anywhere on it (verified: clicking 150 px off Sol's centre from 1.2
units selects Sol on this build and the ecliptic behind it on the previous one); the marker
ring sits `GAP_MARKER` outside the drawn pixels; `isPointInView` widens its side bounds by the
point's own radius; `reachOf` adds the radius so the far clip holds the whole disc. The
`gl.POINTS`/`gl_PointSize` path is gone from both front-ends, and with it `uRound`/`as_point`.
  **What is under the pointer is what is picked.** The pick ranked points by pixel
distance to their centres within a reach of `RADIUS_PICK_POINT` or the drawn radius, so a
tap inside a planet's disc but nearer a background star's centre than the planet's selected
the star through the planet, and a star just past the rim won from inside it. Now, where the
cursor lies inside the drawn disc of some point, the nearest such disc to the eye wins over
every point the cursor is not inside, however near their centres; the pixel reach decides
only where the cursor is inside nothing (`picking.pickWalk`'s `consider`). Rival counting for
the touch crowd rule follows the finger rather than the eye: a point covered by a nearer disc
narrower than a fingertip is still a rival, since two overlapping dots are one blob to a
finger and whichever is in front the reader may have meant the other; a point covered by a
fingertip-wide body (`RADIUS_PICK_POINT` or wider) is not, a star behind a planet being no
ambiguity for a finger on the planet (`coverOf`). The discs under the cursor are gathered in
a fixed array of eight (`Hiders`, a planet and its moons at most; a ninth is dropped) as the
walk goes, so covered rivals are only known once it ends: a second, points-only walk runs
where a fingertip-wide disc lies under the cursor — the winner is already that disc, so no
line or plane needs meeting again — and the common case is one walk. Depth in the point
branch is read off the projection's homogeneous weight (`depthAlongSight`, held equal to the
dot product against `forward` by suite) and the drawn radius off that depth
(`radiusPixelsAtDepth`), so the branch builds nothing per point; the hover pick at 5,038
went from 3.5 to 2.2 ms median on this container with that. Rejected: a candidate list per
walk, an allocation per pointer event with dozens in reach on the star field; the rule
"the nearest disc under the cursor hides everything deeper", which made a six-pixel dot
under the finger hide the whole crowd behind it and turned the touch crowd rule's orbit into
a construction; and dropping covered points from the crowd outright, which did the same for
two overlapping dots. A point covered by a disc the cursor is *not* inside is left alone: it
is reachable from beside its cover, and knowing it covered would take every disc, not the
ones under the cursor. Verified: the suite pins a star behind a wider disc unpicked with one
rival, a moon in front of it picked with two, a star straight behind a moon unpicked but
counted, the planet winning from inside its rim over a star past it, and the star winning
from outside; the browser pin hovers forty-eight samples across Jupiter's disc and finds
nothing deeper than Jupiter.
  **Measured** on this container, largest demo, camera orbiting, before (sprites, branch head
in a worktree) and after (discs), two rounds each, 1200×900: every CPU phase is unchanged
within noise — cull off `build` 5.6–5.8 → 5.6–6.2 ms p50, `scene` 3.4–3.5 → 3.4–3.7; cull on
`build` 3.5–3.7 → 3.6–3.8, `scene` 1.6–1.7 → 1.7–1.8 — while the **whole frame under
SwiftShader** rose from 53–55 to 103–108 ms p50 with the cull off and 46–50 to 56–59 with it
on. Drawing the quad as a four-corner strip instead of six triangle vertices changed nothing
measurable (107 vs 105 ms), so the vertex count is not the cost; the hypothesis is
SwiftShader's per-instance overhead on 4,938 instances, which a hardware GPU does not have —
ribbons, discs and rings already draw instanced here. **Unmeasured on the device**; the
drawer's `render` row is where it would show.

**Points are shaded as spheres lit by their sun.** An object may *shine* (`Scene.are_shining`,
`shinesAt`/`setShining`, a `shines` checkbox in both editors, scene format version 5 with one
byte after the radius; older files read as nothing shining). `lighting.lightsFor` gives every
finite, non-shining point the unit direction toward its **nearest** shining point, or zero
where there is none; nearest rather than brightest because the catalogues carry no
luminosities and a system's own star is nearest to its planets by a hundred to one. The
directions depend on positions alone, so both front-ends recompute them only where the
scene's revision moved, beside the placements: 333 suns × 4,938 points once per edit at the
largest demo, never per frame. The record carries the direction (`Vertex.light_*`, eleven
floats per point now); the vertex shader turns it into the camera's basis (right, up, toward
the eye) and the fragment stage builds the sphere's normal from the disc's unit coordinates
(`(x, y, √(1−r²))`) and applies Lambert over an ambient floor `FRACTION_AMBIENT_SHADE` =
0.25 — a quarter, so the night side still reads as a body in its own hue rather than a hole
in the field. A zero direction draws flat: suns, previews, horizon stars, sunless scenes. The
demo's Sol and every neighbour star shine. Verified by looking: Jupiter's limb faces Sol and
its moons carry their own terminators at 1.2 units, the desktop draws the same frame, and the
suite pins nearest-sun choice, the sun's own darkness, a hidden sun shedding nothing, and the
placed and placing variants agreeing.

**Furniture** (ground grid, world axes) reaches `extent_furniture`, from the far clip
(`extentFurnitureFor`), and is drawn as **fog about the eye**, not a halo about the origin.
`fogFurnitureFor` solves two radii from `DrawExtent.eye`: full strength within
`FRACTION_GRID_FADE_START` = 0.06 × extent, gone by `FRACTION_GRID_FADE_END` = 0.20 ×
extent. Those are 1.14 and 3.8 orbit distances, so what the camera looks at sits inside the
solid core and the fog's edge is still a fifth of the far clip. Both came from rendering the
alternatives: at 0.03/0.12 the ground at the pivot read as absent, and a reach of 300
faded out at 36 units, inside the eye's own height above ground. Fog rather than a halo
because a halo makes the origin a place the reader may not leave — pan a hundred units away
and the ground was gone. The fade runs in the fragment shader against the fragment's own
world position and two fog-radius uniforms, exact along a record of any length, held to
`alphaGridFade` as its reference. A per-record `fog` flag (the sixteenth float) says who
fades, so fogged furniture and plain scene ribbons share one buffer in emission order.

`addGrid` lays lines on world multiples of the cell size inside the ground disc the fog
leaves — radius `sqrt(radius_gone² − height²)` about the point below the eye,
`mesh.radiusGroundFor` — one record per lattice line, with whole-line behind-eye cull at
placement (depth is linear along a straight segment, so two behind-eye endpoints put all of
it behind). The two lines through the origin are skipped, coinciding with the X/Y axes.

**The cell is `SIZE_CELL_GRID` = 10.0 at every reach a reader works at.** A cell that walks
with the reach re-scales the ground under a reader as they dolly; a fixed cell is a ruler.
Ten rather than a hundred, by rendering both: at the opening placement the reach is ≈72
units, so a hundred-unit cell put at most one line in view and the ground read as empty.
`CELLS_GRID_HALF_MAX` = 120 bounds the lines laid (`LINES_GRID_MAX` = 241 per family),
**spent on the cell, not on the reach**: `sizeCellGridFor` steps the cell by **decades** —
the smallest power of ten keeping the ground disc inside 120 cells — because decades nest,
so a step coarsens what is drawn without moving a line the reader was measuring against.
The first step is at 1,200 units of reach, orbit distance ≈316, by which point a ten-unit
cell is already the aliasing haze the fade end exists to cut. Cutting the *reach* at 120
cells instead left a camera past 1,200 units with the ground stopping short and past twice
that in a black void, axes included: grid vertices at orbit distance 300 / 1,000 / 5,000 /
10⁶ were 86,142 / 95,088 / 0 / 0 before and 86,142 / 28,392 / 13,818 / 28,392 after.

The grid is dimmed by `ALPHA_GRID` = 0.75 in `addGrid`, not on `Ink.Grid` (which is also
`INK_POOL_FREE`); 0.55 rendered a ground that read as absent.

**The world axes are reference and are drawn that way**: they fade and cut off on the grid's
own schedule, each drawn over the chord of the fog sphere it crosses, so all the furniture
ends at one horizon. Beyond the fog nothing marks the origin; accepted. Before this an axis
was the longest and brightest mark in any frame — no fade, 0.95 of the far clip at full
alpha — and readers took it for a drawn line.

**The scale bar**, bottom left, is what makes the ruled ground measurable: a span of ground
drawn at its true screen length with its distance written under it, and the cell size beside
that. Stepped 1-2-5 by decade (`STEPS_RULER`) to land near `PIXELS_RULER_TARGET` = 130 px,
as every map scale is; a bar tied to one cell ran 11,983 px at orbit distance 3 and 53 px at
120. Both numbers come from `nimGridMetrics`, which reads the same `sizeCellGridAt` that
`addGrid` lays the lattice with, and the bar is measured at the ground point below the eye,
where the reported cell is laid. In CSS pixels, since a bar is read in the pointer's pixels.
Hidden where no ground is drawn. **The drawer draws over it** (`z-index` 3 under the
drawer's 4) rather than displacing or hiding it: on a phone "aside" was off-screen, and a
bar a panel sits on can be read by closing the panel.

*Checked.* Verified by suite cases: a meet far outside the drawn disc; both halves of a line
pickable; the horizon plane's dome inserted first; the great circle's segment count after
the eye cut, computed rather than assumed; the fog radii at an eye inside its own fog.
Verified by driven checks: the plane pick from either side; the scale bar's length against
its label at two distances a decade apart; the bar unmoved and layered under the open
drawer. Verified by rendering: the fade fractions, the cell size, the grid alpha, the axis
dimming, an eye 1,000 units out standing on lit ground, and the far-orbit views before and
after the decade step. The 1e-16 skew and the 6.7° gap are suite-measured; the far-end
occlusion error is assumed to be tolerable, not measured.


Camera
---
`camera.nim` holds an orbit camera: pivot, distance, azimuth, elevation. `ELEVATION_LIMIT`
= π/2 − 0.02. The opening placement is `initCameraDefault`, read by both entry points and
by `home`.

**An orbit distance has a floor and no ceiling.** `DISTANCE_LIMIT_NEAR` = 0.05 is geometry:
at zero the eye coincides with its pivot and every direction `camera.frame` derives
collapses. `distanceHeld` is the one statement of it; construction, the dolly, both numeric
fields and `distanceFitting` pass through it. The 500-unit ceiling that stood beside it read
as the camera being bounded to a region — dolly out to look at something a kilometre across
and the view stopped. Nothing downstream needed it: the clip planes are fractions of the
distance and the grid bounds its own line count. What degrades far out is `Vertex`'s
float32 storage, past roughly 10⁶ units; wheeled out to 3 × 10¹⁹ the view empties to a
speck rather than breaking, and `home` returns.

**Clip planes follow orbit distance, and the far plane never comes inside the scene** —
`FACTOR_CLIP_NEAR` 1/400 of the orbit distance and `FACTOR_CLIP_FAR` 20 times it, or the eye's
distance to the origin plus the scene's reach (`Camera.reach_scene`, times `MARGIN_REACH_FAR`
1.05) where that is farther — derived, never stored. Not a stored pair set at construction — it
kept its value through every dolly, so dollying past the fixed far plane clipped the whole
scene away. Not twenty orbit distances alone either: once the starfield was 3,000 units across,
a zoom that carried the orbit distance down to a foreground star put the far plane a few
hundred units out and the field vanished behind it; six notches in at the demo's centre left 49
of 4,938 points drawn, and leave 367 now. The reach is the farthest visible finite object from
the origin, a disc's own extent included (`framing.reachOf`), measured once per scene change —
from the placement cache on the browser, by placing on the desktop — and stamped onto the
camera at every derivation point rather than kept in it, because `home` and every other path
that replaces the camera value would drop a stored one; the first cut did keep it, and the
undo-while-held check caught the drop. Near does not stay scaled: at
one four-hundredth of a 0.7-unit orbit against a far plane at the scene's reach the ratio
was 1.8 million, and a 24-bit depth buffer then resolves 3 units at a depth of 300 and 34 at
1,000 — on the device the points near the horizon striped against the discs seen edge-on and
distant stars faded behind the veils drawn over them, which read as the sky vanishing on a
pinch. `distanceNear` is now raised to hold the ratio at `RATIO_CLIP_MAX` = 100,000 (0.17
units resolved at 300), and never past half the orbit distance, so the pivot cannot clip
however far the scene reaches. A 16-bit depth buffer cannot hold this ratio; nothing here
detects one.

**The wheel zooms toward what the pointer is over** — the map reading of a zoom.
`picking.anchorZoomAt` solves the anchor in three answers, in order: the finite object under
the pointer, else the ground at `z = 0`, else the horizontal plane through the pivot; where
none answers (empty sky above the horizon) the wheel falls back to a centred dolly. **The
object or ground is taken only where its depth is within `FACTOR_ANCHOR_DEPTH` = 2 of the
orbit distance, either way**; otherwise the level through the pivot answers. The starfield
put some star under every pixel, and anchoring on one a thousand units off slid the eye 38%
of the way toward it per notch: six notches with the pointer off-centre carried the pivot
1,737 units, three opening distances, and the far plane then clipped the field away behind.
With the window the same six notches carry it 5 units here. Zooming onto a star being
framed still works, since it stands at the depth being looked at. A cursor toward the horizon
finds ground beyond the window and takes the level instead, which is what stops a zoom near
the horizon flying off across the ground; the suite holds both cases. The
object comes first because pointing at something means *that thing, at the depth it stands
at*: `positionOnObjectUnder` reads a point at its place, a plane where the sight ray crosses
it, a line at the point nearest the ray. Horizon objects are refused — drawn at
`radius_horizon` about the eye, they are not *at* any place, and a horizon plane matches
every ray. The price is the jump: two notches taken either side of an object's edge converge
on different depths. `camera.dollyToward` then moves the eye along its own line to the
anchor, leaving the angles alone, and scales the pivot toward the anchor by the same factor
(`pivot' = anchor + s·(pivot − anchor)`), so the orbit centre settles onto what is being
zoomed into. The scale applied is read back from `distanceHeld`, so a zoom stopped by the
floor moves the eye by exactly what it was allowed.

**A pinch stays centred**, and the exception is deliberate: the two-finger gesture already
pans by its midpoint's travel, so aiming the zoom there translates the view twice for one
gesture; measured, the midpoint-aimed pinch dragged the view 11.4 units where the centred
one holds it.

**A drag pan grabs the level under the pointer and carries it.** `interaction.panAcross`
meets both ends of the pointer's step with the horizontal plane through the pivot and
translates by the difference. It replaces a rate of `FRACTION_PAN_PIXEL` = 0.0016 of the
distance per pixel, which carried the scene 288 px for a 200 px drag and, sliding within the
plane *facing the eye*, took the pivot from z 1.00 to 6.40 one way and −2.24 the other, so
every later orbit swung about a point in mid-air. Both hold points lie on one level, so the
height cannot move: 1.000 to 1.000 driven, mouse and two-finger alike, through one rule. The
rate survives only where a ray misses the level — a drag on sky. **The hold point is
bounded at `FACTOR_PAN_REACH_MAX` = 4 orbit distances**, because a level meets a ray aimed
near the horizon a very long way off; the *point* is clamped rather than the movement, so
the rule stays continuous as the cursor crosses the bound, and each hold point is taken to
its foot on the level (`projectOrthogonal`) so the clamp's tilt cannot leak into the step.
Four rather than two: at the opening placement a ray a fifth of the way down the window
already reaches 2.7 distances.

**Keys move by shared rates per second** — `TURN_SECOND` 1.4, `RISE_SECOND` 1.1,
`SLIDE_SECOND` 1.2, `FACTOR_DOLLY_SECOND` 4.0, `FACTOR_HASTE` 4.0 under shift — applied
each frame scaled by elapsed time, so a hold covers the same ground at 60 Hz and 144 Hz; the
dolly compounds as `pow(factor, seconds)`. Drag rates differ per front-end for a real
reason: `visualiser.SPEED_ORBIT` (0.008) is radians per pixel and browser scripts works in
fractions of canvas width.

*Checked.* Verified by driven wheel events: an object under the pointer drifts 0.000 px
across a 3.2× zoom against 1.957 px with the pivot-level anchor, and wheeling back out
returns to distance 19.000 and pivot (0, 0, 1); eight notches over the ground carry the
pivot from z 1.00 to 0.32. Verified by driven drags: the pan figures above. Verified by
suite: `norm(eye − pivot)` equals the held distance after a floored dolly; the pan's height
invariance; the clamp's continuity. Verified by driven keys: 500 ms of `w` moved the pivot
12.8 units with z unchanged to four decimals, shift 49.3. Assumed: that no ceiling is wanted
by any reader, argued from the map reading rather than measured.


Records And Shaders
---
**Every line is a quad, never `GL_LINES`.** A line width is a hint most WebGL targets clamp
to one pixel, so `WIDTH_LINE_OBJECT` and `WIDTH_LINE_FURNITURE` meant nothing in the browser
until width became geometry. Each end is offset half a width along `directionAcross` —
the normal of the plane joining the segment with the eye — scaled by `worldPerPixelAt` at
*that end's own depth*, which is what keeps the on-screen width constant along a receding
line. **The near plane is clipped against first**: a depth clamped at the near plane breaks
the proportionality, and the first frame after the change drew a world axis twenty pixels
wide near the origin. An end behind the near plane moves up to it along the segment with its
tint blended by the same fraction; a segment entirely behind is dropped.

**The widening runs in the vertex shader on both front-ends.** One fifteen-float
`RibbonRecord` per segment (sixteen with the `fog` flag) crosses the wire against the
forty-two floats six CPU vertices cost, expanded by an instanced draw — GL 3.3 core on the
desktop, `ANGLE_instanced_arrays` on WebGL1. The across is derived per vertex as
`cross(head − tail, eye − tail)`, which for collinear pieces is the per-line hoist it
replaces. **Chain of custody**: the GLSL ships, `mesh.expandRibbon` is its reference in Nim
(sibling-marked with both shader sources), and the suite holds the reference to the
algebra — the near clip equal to `clipToEyeSide`, the across equal to the join
`directionNormal(tail ∧ head ∧ eye)`, sign included. The desktop captured the same frame
under the old CPU expansion and the instanced path: zero of 1,296,000 pixels differed.

**A plane's fill, its rim and the sky are one record each.** A 13-float `DiscRecord`
(centre, two radius-scaled arms, tint) fans over a static unit-circle corner buffer; an
8-float `DomeRecord` (centre, radius, tint) widens over a static unit sphere — a full sphere
has no orientation, so the record carries none; a 14-float `RingRecord` is a disc's thirteen
plus a width, one instance drawing the whole circle over `mesh.ringCorners`. The static
corner tables come from one generator each in `mesh` (`discCorners`, `domeCorners`,
`ringCorners`), read by the desktop directly and by the browser through `nim*Corners`, so
neither pivot holds a table that could drift from the references (`expandDiscVertex`,
`expandDomeVertex`, `expandRingVertex`), which the suite pins to the multivector sums they
replaced. `ribbonOfRing` derives the very `RibbonRecord` a rim segment would have been and
`expandRingVertex` is `expandRibbon` of it, so a rim is widened by the one rule every line
is. The rim steps off `UNIT_CIRCLE_RIM`, resolved at start-up with the runtime's own
`cos`/`sin` — not at compile time, whose evaluator need not agree with each backend's libm
in the last bit.

The rim was the last to move and it was 85% of the demo frame: `SEGMENTS_CIRCLE_HORIZON`
= 96 ribbon records per plane were 12,672 of 12,772 ribbon records (99.2% of ribbon traffic,
811 KB walked four times a frame) and 45 ms of a 53 ms frame on 132 planes. As a record the
demo's median frame went 239 → 84 ms under SwiftShader.

**Veil order is kept, not assumed away**: two translucent veils still blend in scene
order, so every append extends or opens a `VeilRun` and both render paths walk the runs in
sequence rather than drawing one whole array after the other. `markOverlay` seals the current
run. `RingMesh` carries its own `index_overlay`, or a selected plane's second rim would draw
depth-tested behind the fill it highlights. Rims are drawn straight after object lines
rather than interleaved; the only difference is blend order where two translucent strokes
overlap during a plane's fade-in.

**Capacities** are asserted in `scene.nim`, the one module that can see both sides, so
raising `OBJECTS_MAX` fails to *compile* rather than `doAssert` at draw time (a dead page):

| Cap | Value | Binding case |
|---|---|---|
| `VERTICES_MAX` | 10080 = 2 × `OBJECTS_MAX` | every handle a point, every one selected |
| `DISCS_MAX`, `DOMES_MAX`, `RINGS_MAX` | 10081 = 2 × `OBJECTS_MAX` + 1 | every handle a plane, |
|  |  | every one selected, plus a preview |
| `RIBBONS_MAX` | 20161 = 4 × `OBJECTS_MAX` + 1 | every handle a line, two segments, drawn twice |

The furniture set's own binding case is `LINES_GRID_MAX` lattice lines per family. The
desktop asks for a `SAMPLES_MULTISAMPLE` = 4 framebuffer and **falls back to none if no
visual offers it**: `llvmpipe` under `xvfb` refuses the window outright rather than
downgrading, and a visualiser that will not start is worse than one whose thinnest lines
alias. The browser context asks for `antialias: true`.

**The flat buffers are the page's own typed arrays, filled in place.** A `seq[float32]` on
the JS backend is an `Array` of boxed doubles, converted element by element into a staging
`Float32Array` — a fourth pass over bytes nothing else read. `FlatBuffer` is a `Float32Array`
behind three `importjs` lines, allocated once at its mesh's cap (about 1.4 MB in all) and
never grown; `flatten*Into` write into it unchanged and each frame hands back a `subarray`
view — one small object per buffer, seven a frame, no copy. `uploadBuffer` refuses anything
that is not a `Float32Array`. Measured at 0.1 ms a frame once the ring record had taken the
input from 204,352 floats to about 9,000; the win is the class, since the conversion scaled
with the scene.

Draw order in browser scripts mirrors `renderer.nim` and is kept in step by hand: furniture
ribbons, then scene ribbons and points, then rings, then veils with `depthMask(false)`.

*Checked.* Verified by suite: the widening reference against the algebra; every stepped disc,
dome and ring corner against the sum it replaced; all ninety-six rim segments on the plane
at its radius; the capacity assertions, by building the binding scenes. Verified by desktop
A/B under Xvfb: 0 pixels for the ribbon move, at most 38 of 1,296,000 per storyboard frame
(channel delta ≤ 12) for the disc and dome move, where the record narrows its arms to
float32. Verified by driven check: the demo's ribbon records under 64 against a ring count
over 120. Assumed: that the 0.1 ms flat-buffer figure holds at the current caps; it was
measured at 1,024 objects.


Algebra Boundary
---
The **algebra owns geometry** — what a thing is and where it stands: construction,
incidence, meets, joins, projections, nearest points, side tests; the world-space camera;
rays cast from the screen; the lattice lines and axes, which are lines; everything at the
horizon. The **picture owns representation** — how geometry becomes GPU primitives: a
plane's disc and rim, a ribbon's across-vector — built with whatever arithmetic is quickest.
A point has no picture to own: one vertex sized by a uniform.

**The boundary is enforced by the compiler.** `mesh.nim` imports `euclid.nim` and nothing
else, so `Multivector` is not a type it can name; `euclid` reaches `pga/algebra.nim` only;
`objects.nim` is the algebra's vocabulary and names no Euclidean type; `boundary.nim` is the
one module speaking both, so every lift and read-out is findable in one file; `tessellate`
is the geometry side of drawing and calls down into `mesh`.

**A PGA equation on the geometry side is never replaced with linear algebra.** The library
is what this project exists to exercise, so a cost it carries there is a finding, restructured
only in PGA's own terms (hoisting an invariant multivector, sharing one join across pieces
that provably share it). What may leave the algebra is the *picture*, and when it does the
algebra becomes the reference the shipped form is proved against: the across-vector cross
product is held equal to the triple join, every stepped disc point to the multivector sum.
The horizon shapes, the lattice lines and the axes stay in the algebra; the dense
16-coefficient `Multivector` copied by value through every operation (~1–2 µs an op on the
JS backend) stays, because changing its storage would change the thing being measured.

**The tessellation assembles before it emits.** Each loop resolves its places through the
algebra into a `DrawScratch` and emits afterwards; for the grid and axes the seam is between
two procs. `placeObject` answers what a drawable is and where — from the multivector alone,
so the answer holds while the camera moves — and `emitObject(placeObject(...))` is what
`addObject` is. Two steps stay on the placing side inside `emitObject` (a horizon marker's
stand-off, a line's two vanishing points) because the cut the panel reports is by kind of
work, not by proc. `tessellate` takes its scratch as a parameter: the desktop hands it swap
arena memory, the browser a fixed buffer.

**The debug layer is gone.** A "debug" switch once drew every multivector a frame
computed as what it is (a finite plane as a lattice over the whole plane, the sight axis,
the cursor's ray); it never helped resolve anything and was removed entirely with its two
modules, its palette slot, its `nimBuildFrame` flag, its diagnostics row and its four driven
checks. What it left behind on purpose: `addGridFamily` and `radiusOnPlaneFor` still lay a
lattice on any plane, since the ground is that case. Do not reintroduce it without being
asked.

*Checked.* Verified by suite: every moved form pinned to its algebraic reference. Assumed:
the µs per op figure, from one profile at 1,024 objects.


Selection And Markers
---
`selection.nim`, shared: an ordered fixed-capacity list of handles, a plain value type.
**Order is the whole point** — an operation reads its operands positionally, so the first
handle picked is `𝐦` and the second `𝐧`. `impliedArity` lives here too. `Selection.revision`
counts real changes (a clear of an empty selection is not one), so the frame record and the
desktop panel compare one integer instead of a 5,040-handle array every frame. Selection is
**not** part of `Scene`: never saved, never on the timeline, cleared outright by a
successful undo or redo, and `pruneDead` runs after a removal because a freed handle goes
straight back to the next add.

**A selected object is drawn over every other object.** One watermark per mesh
(`index_overlay`, an `Option[int]` — an index of zero legitimately means "all of it", so a
mesh nobody marked has to say *none*), set once per frame by `markOverlay`, then a second
pass over **every** primitive kind against a depth buffer cleared first. Cleared rather than
the depth test turned off: nothing unselected is left to reject against, so a selected
object still shows through whatever stands before it, while selected objects reject one
another by depth exactly as the main pass does. With the test off, emission order decided
among them — `SELECTION` in pick order — and a planet selected after its moon buried the
moon standing in front of it (verified on the browser: the pixel at Io's centre, Io in
front of Jupiter at the frame's middle, reads Io's colour with Io alone selected and with
Jupiter selected too; before, Jupiter's blue). Veils write no depth in this pass either,
as in the main one. A second pass rather than a tail on each kind: the tail left a selected
line tinted by a later veil. A watermark rather than a third `MeshSet`, because a set
reserves every cap up front for a run that is usually one object. On the desktop marks draw
on Dear ImGui's **background** list, beneath the panels, exactly as the object is; the drag
menu alone stays on the foreground list, since it is a control being steered.

"Just built" and "currently selected" are one mechanism: one marker per selected handle,
plain white, and every construction path replaces the selection with the handle it created.
Hover draws the identical marker at `ALPHA_MARKER_HOVER` 0.6 against `ALPHA_MARKER_SELECTED`
0.9; keyboard focus wears it too. Only a caller passing a time gets a pulse, so motion means
selected.

`marker.nim` shapes the outline to what it marks:

| Kind | Marker | How it fills |
|-------|--------|--------------|
| Point | Circle in screen space about the drawn point. | Sweeps clockwise from twelve. |
| Line | Two rails flanking its projection, one each side. | Runs out from its support. |
| Plane | A circle lying *on the plane*, outside its rim. | Opens from the disc's centre. |
| Horizon line | Two bands on the sky it circles. | Closes in from a quarter turn. |
| Horizon plane | The viewport's edge, inset by the gap. | Expands as a circle from the middle. |
| Horizon point | Circle about the fixed star it draws as. | Sweeps. |

All keep `GAP_MARKER` = 6.0 px between the object's drawn edge and the marker, measured out
from the drawn size: a point's ring radius is `radiusPixelsAt(radius, anchor, scale)` + gap,
so it hugs a sun and a dot alike (9 px + gap at the least size);
`OFFSET_MARKER_RAIL` = `WIDTH_LINE_OBJECT`/2 + gap = 7.25 px. `WIDTH_MARKER` 1.5 px, asserted
thinner than the line it marks — 2 px of pure white at an 11.5 px gap read as a second
object. Markers are stroked by each render path's foreground layer (`gui.overlayPolyline`,
SVG), never as scene geometry: a loop on a plane would z-fight its fill, and a marker the
object can occlude is not a marker. A 3D-modelling-style outline (oversized silhouette,
depth-write off, its own shader and mesh set) was built and deleted; do not reintroduce it
without being asked.

**A selected object wears its name above its marker.** The label is filled in the
object's own ink and outlined in the marker's stroke, so it reads as part of the marker
family; hover and focus wear none, as they carry no pulse. Where it sits is one more
decision `marker.nim` makes (`Marker.has_label`, `Marker.label_at`): centred `GAP_MARKER`
plus half `HEIGHT_MARKER_LABEL` (16 px) above the outline's top at the object's own place —
a ring's top (so a held marker's swell lifts the label with it), the bands' highest
projected point, a plane's circle and a line's own left as below —
and, for the sky's frame, just inside the top edge, since above a frame that is the
viewport is off screen. Placement with the marker rather than by each front-end so the two
agree by construction; each centres its own text on the point and keeps its own face (the
page's sans at the shared height, set by browser scripts from `nimOverlayMetrics`; on the desktop
a face of its own, below).

**A line's label keeps to the line's own left, beside its support clamped into view.**
"Above the line" cannot be continuous: which side of an unoriented line is up flips as the
line passes vertical on screen, and the old rule — above the upper rail where it passes the
support — hopped rail to rail there, overlapped a steep line, and vanished with the support.
The side of the line's *own* direction (`direction(geometry)`, fixed by the geometry, its
projection a continuous vector) is continuous, so `marker.placeLabelBesideLine` anchors the
label on the line and pushes it to that left: `Marker.is_label_beside` with `label_at` the
anchor and `label_away_x/y` the unit push, and each front-end, which alone measures its
text, sets the centre `clearanceBeside` along it — rail, gap, and the label's own box's
half-extent in that direction (`|away_x|·half_width + |away_y|·half_height`), so a wide name
beside a steep line still clears it where a fixed lift put letters across it (browser scripts
`appendLabel` measures with `getComputedTextLength`, the desktop with `guiLabelWidth` in
the label face). The anchor is the support's projection while it is in view, held
`MARGIN_LABEL_VIEW` = 40 px inside the edge along the line; past that it slides along the
visible stretch (the stretch in front of the eye through `clipToEyeSide`, then
`clipToView`, Liang–Barsky both ends), and a support behind the eye anchors at the
near-plane crossing, the nearest visible point to it. The label may sit below the line after
half a turn: the side is the line's, not the screen's, and that is what makes it continuous.
Chosen over four others on isolated animated mock-ups sharing one 24 s camera path (orbit,
near top-down turn through vertical twice, pan carrying the support off the view, near
end-on pass) with a hop counter — a step over 12 px that is also over twice the step before:
the old rule hopped five times; the upward side sliding through the line at vertical, the
oriented side at the visible midpoint, and text set along the line all ran without hops,
but the first overlaps at vertical, the second follows the viewport rather than a point of
the line, and the third flips its text. Verified by suite (a full orbit at two elevations
in 0.002 rad steps, the second carrying the line through vertical twice: no isolated step,
push direction turning under 0.05 per step, anchor always in view; the support twelve units
off the pivot lands the anchor on the line, in view, a margin from the edge; the clearance
pinned flat and vertical) and by driven check on the browser (402 frames over the same two
turns: 0 hops, 0 out of view, largest step 9.4 px). Both front-ends rendered and looked at.

**A plane's label stands on the disc's column at the height of its circle's true top.**
The top was the highest of the 64 projected vertices of the marker's circle, and as the
camera orbited the winning vertex changed, so the label hopped by a segment at a time.
`marker.topmostOnCircle` solves the top of the projected circle in closed form: clip y and
clip w are affine in (cos θ, sin θ), so screen y is monotone in `N/D` with `N = a·cos + b·sin
+ c` and `D = d·cos + e·sin + f`, stationary where `(b·d − a·e) + (c·d − a·f)·sin + (b·f −
c·e)·cos = 0`; the two roots `atan2(Q, R) ± arccos(−P/√(Q²+R²))` are the top and the
bottom, and the higher one in front of the eye is taken. Continuous in the camera, so the
label glides (where a thin oblique ellipse's top runs along its length it still moves
steadily). Its **height** alone is used; the label's x is the disc centre's column. That is
what makes the flip invisible: seen from just above the plane the top is the far rim, from
just below the near rim, and for a disc off the sight axis those two tops part in x at the
edge-on moment (the far one nearer the vanishing point) while both go to the plane's
horizon in y — so the centre's column, which is continuous, carries the label, and the
swap of rims happens at one pixel. Rejected: the top's own x, which popped by 3 px at the
flip on the opening scene's ground plane and would pop by hundreds for a disc to the side.
Where the true top is cut away behind the eye, or the centre stands behind it, the sampled
rule stands in. Verified by suite: over a full orbit in 0.002 rad steps the label never
takes a step more than twice the one before plus a pixel while the sampled top does; a
milliradian either side of the flip the labels stand under a pixel apart, disc on the axis
and off it; the closed form on a circle facing the camera gives the ring rule's answer.
**The halo is the backdrop's colour, not the marker's white.** Cartographic label
practice (Peterson, *Cartographer's Toolkit*; Dawson, *About label halos*; Esri, *Polishing
your halo*) is that a halo blends with the background so it knocks the surroundings out of
the letters, while a contrasting halo dominates them — which is what the white one did,
at 3 px and again at 1.5 px. Glanceable on-screen text reads better bigger, regular width,
never light (NN/g, *Typography for Glanceable Reading*; Microsoft's mixed-reality guidance
puts the comfortable floor at 14 px). So: `WIDTH_MARKER_LABEL_HALO` = 2 px of `Ink.Backdrop`
at `ALPHA_MARKER_LABEL_HALO` = 0.85, a 16 px face at weight 600 with 0.02 em of tracking
(14 px at 500 read small and light over the scene; sizes chosen by eye), the fill still the
object's ink; the marker keeps its white for itself. The desktop sets the label in a face of
its own, `PATH_FONT_LABEL` = Noto Sans Bold at `HEIGHT_MARKER_LABEL` (the only heavier weight
the system's Noto Sans package ships; there is no semibold), with the math and symbol faces
merged in at that size so a name like `G = L ∧ c` keeps its wedge — it drew as a box without
them — and falls back to the UI face where the file is missing. The browser stages
one SVG `<text>` per selected handle with `paint-order: stroke` and reads the ink colours
into a table once at start-up (`COLOUR_INK_CSS`, since `nimInkColor` builds a sequence per
call); the desktop has no stroked text, so `guiOverlayLabel` draws the text at the eight
one-pixel offsets in the halo colour beneath the fill, on the background list the markers
use. The label
position crosses the bridge through `nimSelectionLabelAt` over a
fixed buffer, reading the marker `nimSelectionMarker` just shaped. Verified: the suite pins
every kind's placement, the browser pin finds two labels for two selected objects in the
right ink and stroke above the anchor and none once cleared, and both front-ends were
rendered and looked at (storyboard step `02_join_plane` on the desktop).

**A plane's loop lies on the plane**, traced from the plane's frame about the same anchor
`addPlane` centres its disc on, so it is concentric with the drawn disc; its clearance is a
world distance sized through `worldPerPixelAt` at the disc's own depth, so the gap reads as
6 px where a reader judges it and foreshortens with the disc elsewhere. `worldPerPixel`
measures depth along the sight axis, not distance from the eye — the two differ by over a
percent even near the middle of the frame. The loop steps `euclid.unitRing`'s fixed table
through `onCircleAt` with the arms taken through the algebra once, as the bands do.

**A line's rails are two straight world-parallel lines, sized by the widest gap they will
show.** Each runs from an offset at the support to the two vanishing points all three share.
Along the half whose far point lies behind the eye, `clipToEyeSide` cuts it back to the near
plane where depth *falls*, so a world offset flares rather than converging. On the demo's
`a ∧ b`, gap from support to drawn end:

| camera (azimuth, elevation, distance) | one half | the other |
|---|---|---|
| 0.6, 0.2, 19 | 14.8 → 12.9 px | 14.8 → 16.5 px |
| 1.6, 0.9, 19 | 14.7 → **23.7 px** | 14.7 → 7.9 px |
| 0.2, 0.05, 12 | 15.3 → 11.3 px | 15.3 → 20.9 px |
| 2.4, 0.4, 30 | 14.5 → **45.6 px** | 14.5 → 0 px |

So `OFFSET_MARKER_RAIL` means **the widest the pair may read anywhere**: `markerRails` lays
the rails out, measures one rail against the other at every drawn end (`apartWidest`), and
narrows the world offset until the widest reading meets the ceiling; it only ever narrows.
After: 14.5 px at the widest and no flare on any half, 14.2 to 14.5 over a 45-camera sweep.
Three details, each of which cost a round: **settle, do not solve** (`PASSES_MARKER_RAIL` = 4;
one pass lands about five percent over, 15.2 against 14.5, because narrowing moves where
each rail leaves the viewport); **settle against the finished rail, then draw at the
progress asked for**, or the gap widens as a touch hold fills; **measure one rail against
the other, not either against the line between them** — all three meet at one vanishing
point, so a perpendicular from one lands further along the other. Two live traps: a ceiling
on the gap *at the support* caps where the flare is not, and its table swept camera
*distance* at one orientation, the one axis the flare does not lie along — **a marker's
worst case can lie along orientation, and sweeping distance is not sweeping**; a constant
*screen* offset bent every rail at its support (2.66°, 7.3 px of stray at azimuth 2.4). A
floor under the narrowing at four tenths let a 437 px splay through and was unfounded: a
ceiling on the widest reading is itself the guarantee of visibility. Driven over a 720-step
orbit, the largest change in the gap between neighbouring frames is 0.103 px.

**A rail's growth is measured against the edge of the view** (`fractionLeavingView`), not
its own length: the two vanishing points sit at wildly unequal screen distances (1,140,706 px
against 3,634 on the demo's `L = a ^ b`, a ratio of 314), so a fraction of each rail's length
finished one half 314 times sooner and put both off a 900 px screen within the first
percent. Bounded at the viewport, quarter progress reads 142 px against 100. Rails are
shortened **after projecting**, along the screen segment: scaling the world reach walks the
head toward the eye and spends almost the whole range within pixels of the vanishing point.

**The horizon plane's frame is an expanding circle that becomes the screen edge**: at each
angle the radius is `progress × half-diagonal` or the distance to the inset edge, whichever
is smaller, so it is a circle for as long as one fits and then becomes the edge piece by
piece, midpoints first and corners last. `SEGMENTS_MARKER_FRAME` = 64 even steps (a multiple
of four, so the midpoints are sampled exactly) plus `CORNERS_MARKER_FRAME` = 4 corner
directions merged in by angle, since a corner missed by a fraction of a step is a corner cut
off. Scaling a rectangle instead read as a shrunken copy of the screen. **A horizon line's
bands are cut to the viewport, not just to the eye**: uncut, a ring lapped 396,102 px
against the 1,490 on screen and a comet at a fixed screen pace was visible four frames in a
thousand. `markerBands` keeps the longest stretch inside the window, `fractionLeavingView`
placing each end at the edge; the lap is 832 px against a finite line's rails' 870 at the
suite's placement. Costs: a horizon line wholly off screen yields no marker; only the
longest stretch of each ring is kept; the anchor falls back to the arc's start when angle
zero is off screen, which for a horizon line is most of the time.

**On touch every marker swells clear of the finger** (`CLEARANCE_MARKER_TOUCH` = 54.5 px,
added not multiplied, taking a point's 10.5 px ring to a 130-pixel circle, about twice a
thumb's contact patch). Zero for a mouse. It was 24 px, sized against a 44 px minimum touch
target by a measurement that compared framebuffer pixels against a CSS-pixel target; see
Browser UI on the two pixel spaces. **The swell runs on its own clock in four phases**
(`interaction.swellHold`): grows over `SECONDS_SWELL_GROW` 0.12 s, sits at full through the
fill, **stays there for as long as the finger is down past maturity**, and settles over
`SECONDS_SWELL_SHRINK` 0.15 s once it lifts. A half sine over the fill put the marker back at
true size at the very moment the selection landed. `progressHold` starts *after* the grow,
so a press is 0.62 s end to end. The swollen marker is drawn even once its handle is selected
and the plain marker for that handle skipped, or the outline snaps at the moment the selection
lands; the browser retires the hold only once `isHoldSpent` says the settle is over, stated
against `swellHold` rather than the shrink duration a second time — subtracting two large
timestamps measured 0.14999999999997 against 0.15. `cancelHold` snaps away without settling:
that press stopped being one. On a Pixel 5 in CSS pixels: 10.5 → 58.2 → 65.0 through the
grow with the fill at 0, flat 65.0 across the fill and at 2 s and 10 s past maturity, then
64.9 → 17.3 → 10.5 through the settle.

**Orientation is a pulse travelling round the selection marker**, and the normal shaft is
gone (it marked every plane in the scene permanently to answer a question a reader asks
about one object at a time). `markerFor` runs a lit run of `SEGMENTS_MARKER_PULSE` = 16
points spanning `LENGTH_MARKER_COMET` = 64 px of the outline, tapering from
`WIDTH_MARKER_COMET` 3.5 px at its head down `FALLOFF_MARKER_COMET` 1.2 to `WIDTH_MARKER` at
its tail, so it merges into the line behind it and only the head is an edge; the constants
came from thirteen variants drawn side by side against 2.8 and 4.5 px heads and 1.6 and 2.4
falloffs. Fixed pixels, not a share of the outline, walked by arc length: a fraction
measured 96 px along a rail against 334 px round a plane's circle. `FRACTION_MARKER_PULSE`
0.35 survives as a cap for a marker smaller than the run. **Which way it travels is the
orientation**: nothing computes the sense, the projection decides a loop's order (+74,393
from above `ground`, −82,167 from below, as swept angle), a rail is walked as one path from
far horizon through the support to near, a band takes the great circle's normal. Two shapes
get none: a point, and a horizon plane, whose `frame`, `direction` and `directionNormal`
all report nothing and are unchanged by negation. One comet to a line, not one per drawn
half: the two rails take the phase measured on the first and stay within one comet's length.

**The travel is a distance in pixels from a view-independent anchor.** `PulseClock.travels`
advances by `SPEED_MARKER_PULSE` = 60 px/s × seconds with no camera quantity in the advance,
reduced into the current lap every frame (an unbounded travel read as `travelled mod lap`
amplifies a one-percent lap change by the laps accumulated). `PulseTrack` names the anchor
— a line's support, a ring's angle zero — and `originAfterCut` walks angle zero through an
eye cut. A speed rather than a lap time: one lap per 4.8 s ran 156 px/s along a rail against
348 round a circle; sixty is what the lap was chosen at over 300 px specimens. A gap longer
than `SECONDS_STEP_PULSE_MAX` = 0.1 s is an absence, not a frame (83 px in one frame before
the cap, 1 px after). The advance belongs to "this handle was drawn this frame": a bridge that
returned before advancing when a rails marker at phase 0 produced no run left lines with no
comet for a whole round while planes pulsed. The two exports share one shaped marker
(`MARKER_SHAPED`, boxed behind a `ref` — held by value the memo's own store and read
deep-copied the variant twice and measured as slow as the shaping it replaced). The desktop
fill needs a **fixed winding** (`gui_shim.guiOverlayRibbon` imposes it): Dear ImGui's fill
offsets each edge outward for one winding and inward for the other, and a ribbon handed the
wrong way came out with its whole fringe under the fill (a column stepped 16 to 248 with
nothing between).

**A drag band swells into its head** (`marker.cometFor`) — the same length, width and
`ribbonAlong` as the pulse, so one vocabulary for direction — because `a ∨ b` and `b ∨ a`
are different operations. Fixed pixels: driven at 61, 125, 200 and 277 px of drag the head
held its size. None where the cursor rests on its own source.

*Checked.* Verified by suite cases: the loop's points on the plane (1.1e-15 on the
antiscalar against 1.0 for a control point one unit off); the rails' straightness over an
orientation sweep and their widest reading on both sides; a growing rail starting where the
finished one does; the frame's 68 points at 296.8 px flat at half progress; the head sitting
exactly its carried travel from its anchor at 45 placements, within a pixel; a rails marker
at phase 0 reporting a positive lap; a matured hold taken once (a 1.62 s hold had selected
its object and lost it within 50 ms of lift). Verified on the shipped browser: the comet's
advance from its anchor at 62.4, 61.7, 62.5 and 63.3 px/s across four orbit rates; 178.3,
179.0 and 179.6 px over three seconds at 36, 60 and 144 fps against 180; the residual at the
two faster rates — a tenth of frames stepping 236–388 px/s, laps and clip transitions, not
drift — is **not explained** to the standard the medians are, and a theory that the shared
rail window shortened the lap was measured to change nothing. Verified on the desktop: the
selected line's pure-ink pixels 2,626 with the second pass against 1,106 with the tail;
marker pixels inside the panel's rectangle 3,453 → 3,059 on the background list. Verified by
driven check: two crossing planes selected change 15,668 canvas pixels against a 0-pixel
noise floor. Assumed: the "twice a thumb's contact patch" sizing, from a rule of thumb.


Picking
---
`picking.pickNearest`, shared: **point beats line beats plane, strictly**, regardless of
pixel distance once a shape's own radius is met. That priority is what makes generous radii
safe. `RADIUS_PICK_POINT` = 34, `RADIUS_PICK_LINE` = 24 CSS px, sized against a fingertip at
phone density; a plane's test is area-based. **Everything drawn is pickable, horizon
included**, ranked point, finite line, horizon line (tested against the great circle it
draws as, stepped off the same table), finite plane, horizon plane (matches every ray, so
last). A horizon point was silently unpickable while the extent was built fieldwise with its
multivector twins zero; the extent goes through `algebraFilled`, the one derivation point.

**The sky is a click and hold target, never a drag handle, and so is a plane that fills
the view.** With a horizon plane visible the cursor is over *something* almost everywhere,
and a press on empty space becomes an orbit precisely because nothing was hovered. A
finite plane whose disc spans the frame's longer side (`picking.coversView`, the disc's
`EXTENT_PLANE_F` radius in pixels at its own depth) leaves no empty glass at all, so a
press on it starting a construction drag left the view unmovable; `picking.isBackdropUnder`
folds both cases into one answer. `beginDrag` refuses the backdrop and `destinationOf`
refuses it; `interaction.is_hover_backdrop` carries the answer from `updateHover`.
Verified: the suite hovers the ground from half a unit (backdrop, drag refused) and from
forty (drag starts); the driven check drops the camera onto the ground plane and a
left-drag orbits without building. Clicking
empty space then selects the sky rather than clearing; a tap still treats it as empty space,
since tapping empty space is a finger's only way to dismiss a selection, and touch reaches
the sky by long-press. The selection menu follows the middle of the view for it.

**The pick runs once per frame, not per input event.** A pick walks every live handle, linear
in the scene (11.4 ms p50 over 1,024 objects, 0.2 over five, before the fixes below). Pointer
motion marks hover stale and the frame loop picks once after `nimDriveHeld`; the wheel sums
its notches and the loop applies one dolly, the same zoom since `exp(k·Σdelta)` is the
product of the notches (six notches a frame had cost 83.8 ms of picking). Three paths pick
inside their handler because they must answer before it returns: `pointerdown`, a touch-down
and `handleTap`.

**The pick ranks what was drawn.** It takes the frame's placements and dispatches on
`Placement.kind` rather than asking `position`, `direction`, `frame` and `spanPerpendicular`
again per handle; empty means derive per handle, the desktop path and every suite case. A finite
plane the algebra can span no frame for shares `PlaneEverywhere` with the sky and is not
pickable; a direction point is picked in the horizon, where the eye puts it. **The pick
rejects a plane before meeting it**: `isBeyondDisc` bounds the disc's screen extent by the
silhouette of the sphere containing it, conservative in the depth and off-axis terms — 20,000
random configurations with the centre up to three view-widths off screen and 300 surface
samples each found no silhouette point outside the bound. `geometryOf` hands back a `lent`
view, and the walk reads it inline — `lent` removes the copy only where the result is never
bound. `projectToScreen` is written out as three dot products in local floats (the 4×4
multiply with two typed arrays allocated per call was 43% of a 15.4 ms pick over 10,000
handles), and the point branch reads `pixelsFromCursor` rather than building a
`ScreenPosition` per handle.

**Handle-liveness guards.** Hovered, dragged, focused and selected handles are plain values
carried across frames, so any can name a removed object the frame after a delete: `nimAnchorScreen`
reports nothing for a dead handle; `endDrag` on both paths checks `isAlive` on source and
destination; removing an object clears the highlight on both paths.

*Checked.* Verified by suite: both boundaries of each radius and all three priority pairings;
a horizon point picked at a pixel where the line alone was first asserted picked; the disc
bound sampled from inside the view. Verified by handle-for-handle map: 4,914 cursor positions
across three cameras over the 1,024-object demo answered identically before and after the
placement and copy changes. Verified by driven checks on both builds: dragging bare sky
turns the view and builds nothing, clicking it selects it. Measured then, not since: one pick
11.4 → 3.9 ms p50 at 1,024; 15.4 → 4.7 ms at 10,000; a hover pick 0.7 / 1.6 / 3.5 ms at 60 /
360 / 5038.


Interaction Model
---
**Which button does what, stated once.** `interaction.revealsMenuOn` says whether a click
brings the floating selection menu (right yes, left and middle no); `armingOf` says whether
a drag opens the choice wheel. Both render paths and `help.nim` read them.

**The selection menu opens on the click, beside the pointer.** A click or tap that reveals
the menu puts its top-left corner `INSET_MENU_POINTER` = 8 px from the pointer (browser scripts
`positionSelectionMenuAt`, `panel.showSelectionMenuAt`), and from then on the menu remembers
its offset from the object's anchor (`offset_menu_selection`; `corner_menu_pointer` turned
into it on the desktop's first layout) so orbiting carries it with the object rather than
snapping it back to the centre, which the per-frame follow used to do. It need not wait for
the camera: a pointer pick keeps the picked object on its pixel while the camera comes in
(below), so nothing glides away from the pointer. Rejected: holding the menu back until the
ease settled, which the previous round did while a pick still centred the object — a menu
that appears a third of a second after the click reads as a missed click. A menu opened with
no pointer (objects list, keyboard, a matured hold) sits above the anchor as before, pinned
by its bottom middle on the desktop and lifted `LIFT_MENU_ANCHOR` = 60 px on the browser.
Verified by driven check: a right-click 6 px off a point's anchor has the menu up two frames
in with its corner 8 px from the pointer, and a pan then moves menu and anchor by the same
delta.

| Gesture | Does |
|---|---|
| left click | select just that one, dropping the rest |
| right click | the same, and open the menu |
| shift with either | add it, or drop it again if already picked |
| right click, selection standing, menu down | reveal the menu, selection untouched |

**A click has no time limit**: `isClick` is distance alone, `PIXELS_CLICK_SLOP` = 6 px
(not `PIXELS_TAP_SLOP`'s 12 — a mouse does not roll, and a finger's allowance would swallow
the short deliberate drags between two overlapping objects). A 0.35 s deadline once lost
every click held 600 ms. The stillness reading is latched and false until a press raises it.
A right press that never moved is a click too: the wheel only opens over a pivot *other*
than the source, so such a press never asked for one.

**The press target chooses the scheme; the button chooses whether you are asked.** Press an
object and you are constructing; press empty space and you are moving the camera (left
orbits, right pans, wheel zooms). Left takes the algebra's own answer on release; right opens
the four-way wheel. **A mouse never waits**: `MenuArming` is `Never` (left), `Always`
(right), `OnDwell` (no button — it belongs to touch, which has no second button and would
otherwise lose `meet`, `project` and `more…`). `SECONDS_DWELL_MENU` = 0.75 measures only a
finger, which pauses far more readily than a mouse, and sits above `SECONDS_LONG_PRESS`
= 0.50 so the two thresholds a stationary finger races are in the right order; timed through
CDP touch on a Pixel 5 profile at 0.93 s from the last movement to the wheel, the extra
0.18 s being the 50 ms poll and SwiftShader's frame latency. The dwell measures stillness:
`updateDrag` restarts it whenever the cursor moves further than `PIXELS_TAP_SLOP` from where
it last settled, since measuring presence opened the menu under a finger moving continuously
for 1.2 s. **Middle is unbound**: it once held `project`, behind hardware most trackpads
lack.

**A press that can construct never moves the camera, not even before its slop is crossed.**
A finger easing into its drag spent its first frames under the slop, fell through to the
orbit, latched the camera-dragging flag that suppresses hover, and then ran blind. browser scripts
decides at the press, in `is_touch_press_constructing`, the same question `beginDrag`
answers when the slop is crossed, refusal over the sky included.

**A finger over a crowd moves the view; it never builds.** In the demo the pick's 34 px
reach lands on some star almost anywhere, so a one-finger orbit kept becoming a construction
drag. `picking.pickAt` now reports, beside the winner, how many objects of the winner's rank *or
better* stood within `RADIUS_CROWD_TOUCH` = 72 px (`PickReport.count_rivals`; a point over a
plane is no rival to it, since rank already decides, but a point beside a picked line is,
since the finger may have meant it). The crowd reach is wider than the 34 px pick reach on
purpose: the question is not what the finger hit but whether it could have meant something
else, and at the pick reach alone the star field still turned orbits into drags. What is
*picked* stays at the pick reach. `updateHover` keeps the count as `count_hover_rivals`, and
`interaction.canConstructByTouch` is true only for a hovered, non-sky object with no rival.
`beginDrag` refuses `MenuArming.OnDwell` — touch alone — where that is false, and browser scripts
asks the same export (`nimCanTouchConstruct`) at the press so the pre-slop frames agree. The
rule is the reader's: where a gesture is ambiguous, movement wins, because the reader can
zoom in until it is not, whereas an unwanted object has to be undone. The mouse keeps its
drag over the same crowd: its hover ring showed it which one it had. The long-press select
is untouched — a still finger competes with nothing — and a driven check holds a 1.4 s press
over the same crowd and finds one object selected. Same-rank only, or every point on the
ground plane would have been a crowd. Held by suite cases on the count and the refusal, and
by a driven check that drags a finger from a point with a twin 0.05 units away and finds
the camera orbited and nothing built; the plane-pick check had to drop the four coincident
`b ∧ c` lines earlier gestures left, which are exactly the crowd the rule refuses.

**The turntable's pivot follows what the zoom lands on.** Every rate but orbit is scaled
by the orbit distance on purpose — pan grabs the ground, the slide keys move a fraction of
the distance per second, dolly is multiplicative — so a drag or a key hold moves the view by
the same fraction of what is seen at any zoom. What broke that was the pivot: a pinch
zoomed straight in with the pivot left on Sol, so a reader arriving at a planet had the
turntable still revolving about a point far behind it, and every orbit or pan swung the near
planet across the frame — the "speed changes when zooming" report. `picking.anchorZoomAt`
now says whether its anchor is where a point or line *stands* or a crossing of the sight ray
with a plane, the ground or the level (`AnchorZoom.is_standing`); `interaction.dollyAt`
re-pivots along the sight line to a standing anchor's depth after the zoom
(`camera.repivotToDepth`, which leaves the picture unchanged since eye and direction stay),
and the pinch goes through the same rule aimed at the middle of the frame (`dollyAtCentre`,
`nimCameraDollyCentred`) rather than a plain dolly. Crossings are followed by the map rule
alone, the pivot sliding toward the anchor as `dollyToward` always did. Rejected: following
the ground crossing too, which a reader zooming onto empty floor might expect. It moved the
pivot off its level with every notch, and five driven pins fell at once — the wheel round
trip, the pinch that must not slide, the two-finger pan, the pivot's height under pan, and
the zoom over ground — every one a rule pan, slide and the level anchor rely on. Rejected
second: following a plane. Its depth under the pointer is not its depth at the middle of
the frame, and the pivot lifted to it stood well off the plane being zoomed onto (the
opening scene's ground *is* a plane object, and the pivot rose from 1.0 to 2.6 units on the
first notch). Verified: the driven pins now state the rule that holds — the eye and the
pixel round-trip under a wheel notch each way, the pivot does not and is not meant to, and
a pinch that does not slide is one whose eye moves along its own sight line (`nimCameraEye`
exists for that reading and for nothing on the page). Measured on the demo: eight wheel
notches over Jupiter from 30 units hold its pixel exactly and bring the pivot from Sol to
0.09 units off Jupiter's plane at 1.5 units' distance; a centred pinch onto a planet lands
the pivot on it, a zoom over sky leaves the pivot's height alone, and one over ground
slides the pivot toward it by the map rule only, all pinned by suite.

**Two fingers are read once per frame, and zoom only past the tap slop.** Each finger's
move arrives as its own `pointermove`, so between the two events the separation and the
midpoint are one finger new and the other old; read there, every step of a pan carried
together was a zoom in by one finger's step and out again by the other's (ratios of 1.24
and 0.81 alternating on the driven pan), harmless while a dolly was a pure scale and a
pivot-moving re-pivot on every one of them once it was not. `glue.settleTwoFingers` reads
both fingers once per frame from the frame loop instead, after both have reported. On top
of that, two fingers carried together never hold their separation to the pixel, so a pinch
zooms only once the separation has changed by more than `interaction.PIXELS_TAP_SLOP`
since both came down, and the slop itself is not zoomed: the zoom starts from the separation
where the slop was crossed, without a jump. Verified by the driven two-finger pan: the pivot
moves across its level and the distance and height do not change at all.

**The edit preview is drawn at the session's own radius.** `Preview` carries a radius
(`previewStaging(geometry, radius)`), fed by `nimSetPreviewStaged(coefficients, radius)` on the
browser and the panel's staged session on the desktop; a derived preview takes
`RADIUS_OBJECT_DEFAULT`, what commit gives it. Before this the preview took the default, so
editing a moon of 0.03 drew a grey disc nearly three times its size over it.

**Edit from the selection menu waits for its row.** The objects list builds in time-bounded
slices, so a row far down it does not exist when `openPanelTo` runs; the old code queried
the row at once, found none and never scrolled, leaving the panel open on the top of the
list. Now `key_reveal_pending` names the row and `revealPendingRow` scrolls the moment it
stands, after each slice as well as at once, and the slice budget widens from 5 to 24 ms
while a reveal is pending (`MILLISECONDS_ROWS_SLICE_REVEAL`) — the reader is looking at
nothing until that row appears. Row signatures are also committed **per row** rather than at
the end of a pass: a refresh landing mid-build restarted the pass and, with the signatures
held back, rebuilt every row already standing, which with selection refreshes arriving was a
list that never finished. Measured on this container at 5,038 with the list unbuilt: the row
now lands in view after 15 frames rather than never. Pinned by a driven check that empties
the list, edits a deep handle and finds its form in view.

**The gesture clock is seconds**, on whichever monotonic clock the caller owns, and the
same reading `addObject` stamps a birth with. browser scripts divides once in its own `now()`. The
desktop's dwell once needed 450 *seconds* because the durations were named in milliseconds.

**What a drag builds is read off the operands, not the button.** `∧` adds grades and is
drawable when the sum ≤ 4; `∨` adds antigrades and is drawable when the sum ≥ 4. Over every
ordered pair of point, line and plane in general position (points off the moment curve
`(t, t², t³)`, where "no three collinear and no four coplanar" is a Vandermonde theorem):

| first → second | join `∧` | meet `∨` | project | plain release takes |
|---|---|---|---|---|
| point → point | line | — | point | join |
| point → line | plane | — | point | join |
| point → plane | — | — | point | project |
| line → point | plane | — | — | join |
| line → line | — | — | line | project |
| line → plane | — | point | line | meet |
| plane → point | — | — | — | **nothing** |
| plane → line | — | point | — | meet |
| plane → plane | — | line | plane | meet |

**At most one of join and meet is ever drawable**, so `proposalFor` is a priority order
(Join → Meet → Project) with no tie. `plane → point` offers nothing and a release refuses
rather than inventing; the table is asymmetric, so drag direction carries meaning. A first
measurement crossed a point lying *on* its paired line and read zeros from the fixture,
which is why `GENERAL_FIRST`/`GENERAL_SECOND` are separate from the random operand sets.

**The drag shows its answer before committing it**: `Interaction.preview` holds what a
release right now would build, drawn as a preview in `INK_PREVIEW` (= `Ink.Guide`) through the
same `addObject` an edit session's preview uses, at `preview_anchor` from the same
`creationAnchor` call the commit makes (or a previewed plane jumps to its anchor the instant
the release lands). It answers for the wedge being aimed at: `updateDrag` resolves through
`choosing()` where a wheel is open and `proposalFor` where none is, and `choosing` is the
one statement of which wedge the cursor is in, read by the preview, the release and both
highlights. **Three things a release can do, so three tints** (`ReleaseEffect`: `Nothing`,
`Refused`, `Builds`) — neutral `Ink.Guide`, `Ink.Invalid` magenta, the scene's next hue.
`Scene.index_ink` carries how far the cycle has walked (`inkNext`/`takeInk`/`skipInk`), and
**every released construction steps it**, built or not, so a colour the reader watched for
a whole drag is not offered again; a click does not step it, nor `More`; undo restores it;
loading sets it to the object count.

**Everything that meets an object on screen meets it where it is drawn.** `mesh.anchorFor`
reads the stored anchor as `addPlane` and `markerFor` do; the band's start, its comet's aim
and the selection menu's follow all go through it. The support stood 0.5, 2.7 and 3.7 units
from the drawn centre on the demo's planes — 13.7 px for `ground` at the home camera.
`pickNearest` still meets the ray against the support's disc; that divergence is left.

**The choice wheel.** Four wedges at fixed compass points — join north, meet east, project
south, `more…` west — unoffered ones greyed (`ALPHA_MENU_UNOFFERED` 0.45) rather than
packed out, because a menu whose objects move is one nobody learns. A wedge is the selection
menu's own button, moved: same surface, hairline, `ROUNDING_MENU_WEDGE` 8 px radius, 12-px
semibold face and `--accent` border on the one in force; the browser takes those from the
same CSS variables, the desktop copies the tones into `drawChoiceMenu` with the siblings
named. **A wedge says what the picker says**: `labelOf` returns `notationSymbolic` (`𝐦 ∧ 𝐧`,
`𝐦 ∨ 𝐧`, `𝐧 ∨ (𝐦 ∧ 𝐧☆)`) and `More` a bare `…`; the words survive in the drawer's legend
only. Symbols made the wheel **15 px narrower** on a 320 px phone (194.7 against 209.8),
because `more…` → `…` takes 31 px off the east–west axis that sets the width, while the
projection's 92 px sits at south, clear of anything. A release commits whatever is under the
cursor, resolved by `endDrag` through `choiceAt` so the two paths cannot disagree; the
centre (`PIXELS_MENU_DEADZONE` 26 px) commits nothing, which is why an unasked dwell wheel is
safe to open. The wheel **latches its destination** when it opens. **An open wheel lets go
when the cursor leaves it** past `PIXELS_MENU_DISENGAGE` = 150 px, sited off
`PIXELS_MENU_CORNER_FURTHEST` = 103.9 px (the furthest wedge corner, read off the drawn rects
over six pairs) leaving 46 px of clear air; travelling on to another object re-aims, never
chains, and a target just let go of is held at arm's length until hover leaves it. This
bounds the overshoot `choiceAt` once left unbounded; re-aiming was chosen, with the user.
**A wheel the reader summoned may veto the release; one that invited itself may not**: a
dwell wheel opens under a finger pausing to aim, and pausing before lifting is the common
touch release, so an *unentered* dwell wheel's centre release falls through to
`proposalFor`; `is_menu_entered` is set the first time the cursor stands in any wedge.
Flick-marks are impossible on this path — a construction drag has spent its direction
reaching the target — so the accelerator is the right button.

`more…` builds nothing and opens **the selection menu's own apply picker** over both
operands in drag order (`panel.openSelectionMenuPicker`, `glue.openApplyPickerOnOperands`),
already showing the operation last applied at that arity. Not the drawer's apply section:
answering a wheel under the cursor by throwing the hand to a side panel buried the two
objects just named. A degenerate construction is **refused**, the message naming what was
degenerate, and a construction on a full scene is refused the same way (the drag commits in
shared code with no panel between it and `addObject`'s assertion; one click on the demo
reached it).

**Touch.** A finger that presses an object constructs; one that presses empty space moves
the camera. Two fingers pinch and pan and cancel any construction. A long press selects; once
a selection exists a tap (`TAP_MAX_MS` 350, in JS because a tap timeout is local) toggles
another in or out; a tap on empty space clears. `pointercancel` cancels. `nimClearHover` runs
once the last finger lifts, or the last reading sits stale forever. Accepted cost: a finger
starting on the ground plane's disc constructs rather than orbiting — the same trade the
mouse makes. `SELECTION` (Nim) is the sole source of truth; browser scripts keeps only a render
snapshot refreshed when the selection changes.

**A picker offers symbols alone** (`notationSymbolic`), not the whole catalogue entry, and
**opens on what was last applied at its own arity** (`OperationMemory`, attitude for one
operand, wedge for two; per arity because the two lists are disjoint). **Every apply control
previews its answer while the reader is still choosing**: `scene.Preview` is the one statement
of a construction not yet committed (geometry, anchor, operand handles), built by
`previewApplying`, and the drag's own preview is the same type by the same call. Where a
session and a preview both stand, **the session wins** (`staged`, once per front-end). The
preview is **framed together with the operands it names** (`Preview.operands`,
`framing.watched`); an open edit session names none, since its staged geometry replaces the
object selected beside it.

**Selection menu** (both builds, one row, following its anchor every frame): `apply`
leftmost and never moving, opening a picker to its right via a `max-width` transition
(`width: auto` cannot animate); `edit` shown for exactly one selected, opening the drawer's
objects section onto a session; `hide`, `delete` on every selected handle; `✕` clears. `apply`
is hidden for 3+ selected, since this menu has no operand pickers. **Shown by the gestures
that pick and hidden by the ones that build**, not derived from the selection being
non-empty — every construction leaves its result selected and a menu over each new object
would sit in the way of the next drag. Placement `OFFSET_MENU_SELECTION` = 46 px **above** its
object: a Dear ImGui window makes `wantsMouse()` true wherever it sits, so a menu straddling
its object would swallow the next drag off it. Its screen position is kept between frames so
an object passing behind the camera leaves it where it was. The document-level tap-outside
listener excludes the canvas, the drawer and the chip row, and fires on `pointerdown`,
before the tap resolves.

*Checked.* Verified by suite: every cell of the drag table and the at-most-one property,
exhaustively; the click rule; the dwell restarting on movement and surviving a drift under
the slop; the preview's anchor equal to the created object's; the ink cycle stepping on release
and not on click. Verified by driven checks: the tint table at each wedge stop
(`nimDragTint` reading neutral `(0.286, 0.322, 0.400)`, magenta `(0.612, 0, 0.722)`, the
next hue); shift-clicks held 600 ms selecting; the sub-slop touch drag hovering 2 with the
azimuth unmoved; `more…` landing on `𝐦 ∧ 𝐧` with both operands selected on both builds; a
construction drag off the very object the selection menu follows (`--drive-select`); the
full-scene refusal. Verified by reading computed styles: the wedge's fill, stroke, radius,
font and label identical to the menu button's. Assumed: that 0.75 s is the right dwell for
any hand; it was set by one profile.


Undo/Redo
---
`history.nim`, shared. Scoped to scene-content edits: add, apply (drag and touch flow
included), remove, visibility, ink, and an edit session's `save`, which is the "edit
committed" moment the continuous widgets lacked. One fixed array plus one cursor, not two
stacks: an entry is a `Step {scene, camera}`, both plain value types, so recording is a copy
and `entries[cursor].scene` is exactly the live scene. `CAPACITY_HISTORY` = 32.

**The array is a ring.** `first` names the handle holding the oldest step, `handleOf` is the one
place a timeline position becomes an index, and retiring the oldest entry moves one integer.
Shifting every later entry down was 31 whole scene copies per edit past the thirty-second —
153.5 ms to toggle one object's visibility on the JS backend, scaling with the *capacity*
(26.4 ms at four deep, 39.9 at eight); as a ring one edit costs 11.3 ms and does not move
with the depth (10.7 at four, 11.7 at eight). What remains per edit is the one `Scene` copy
into the timeline, 1.15 MiB through `nimCopy` on the JS backend; not per frame. `initHistory`
fills a timeline the caller owns: returned by value it compiled to a `nimCopy` of thirty-two
whole scenes, 65% of the largest demo's load. `record` writes a `Step`'s fields rather than
assigning a literal, for the same reason.

**The camera rides along; an orbit is never a step of its own.** Each step records where the
view stood when *that step's* edit was made; undo reads it off the entry stepped away from,
redo off the entry arrived at. Restoring the camera of the state arrived at hands back
whatever view the *previous* edit was made from, so undoing the first construction of a
session teleported to the startup view. Not recording an orbit is the accepted cost of not
needing a gesture-settle rule, and **an accidental orbit is still not undoable on its own**.
Both front-ends abandon their camera tween on a successful step, or the standing aim drags
the view straight back off the placement just restored.

Seeded wherever the scene is (re)initialised, so undo never reaches past the moment
tracking began. A successful step clears the selection and any preview. Bound to Ctrl/Cmd+Z,
Ctrl/Cmd+Shift+Z and Ctrl+Y on both builds, through one function per build rather than the
button — routing through `button_undo.click()` depended on a `disabled` attribute refreshed
on the low-cadence tick.

*Checked.* Verified by suite: recording to capacity and past it, walking every retained step
forward and back and comparing each state (`scenesEqual`, since `Multivector`'s `==` is an
intentional compile error); camera restoration across two edits from two viewpoints.
Verified end to end: `--drive-undo` and the browser drive both build, orbit away, undo, and
hold the view where the construction was made. The 153.5 / 11.3 ms figures were measured on
the JS backend at 5,038 handles and not since.


Storyboard And Seeds
---
`storyboard.constructSeeds` builds five seeds: `a`, `b`, `c` (raised 2 units in z), `o`
(the origin), `ground` (a plane joined from three points at z = 0). `o` must stay off
`ground` — one step projects it onto that plane. `STEPS` is eleven derived steps; both entry
points compute the seed count from `scene.len`. One step (`a ^ ground`) is a grade-4 volume
and correctly reports "mixed grade, nothing to draw" — its documented purpose.

Both apps open on the seeds alone. `runStoryboard` distinguishes "reached" from "focal";
reached-but-not-focal draws muted rather than hidden. Horizon steps aim the capture via
`azimuthElevationFor(heading)`, a closed-form inverse of the orbit camera's forward
direction. `constructSeeds` deliberately does not stagger arrivals (`runStoryboard` sweeps
each step's animation on a clock of its own); the startup paths call `replayFrom` after it.
The GIF is `FRAMES_GIF_GROW` 6 + `FRAMES_GIF_HOLD` 4 frames a step at `STRIDE_GIF` 2
downsampling, `CENTISECONDS_GIF_DELAY` 8.

*Checked.* Verified by regenerating: the storyboard is byte-identical across changes that
should not touch it (the replay, the help-table measurement). Nothing assumed.


Creation-Anchored Plane Centring
---
A plane's rim and fill centre on `scene.creationAnchor(operation, m, n, derived)` rather
than on its closest-to-origin support, which reads wrong for a plane built from operands
that do not straddle the origin. `Wedge` of a line and a point centres at the midpoint
between the point and its projection onto the line; `ExpandWeight` of a point and a line
where the line meets the plane; the three-point ground seed on the centroid; everything else
falls back to the support. Computed at construction and stored (`anchor_overrides`, a
rendering hint excluded from save/load), since many operand sets produce an identical plane
`Multivector`. All anchor arithmetic is RGA-native — summing unit-weight points and reading
`position`, which divides by weight.

*Checked.* Verified by suite: each special case's anchor. Assumed: that no other operation
wants one; none has been asked for.


Save/Load Format (`.rgascene`)
---
Compact binary matching `Scene`'s layout, **little-endian throughout** — a free choice that
had to be *a* choice, because browser scripts reaches it through `DataView`, and little-endian
because every file already written contained it. The desktop converts through
`std/endians`.

| Bytes | Field |
|-------|-------|
| 4 | Magic `RGAS` |
| 1 | Format version (`VERSION_SCENE` = 6) |
| 1 | Basis count (16 under this build); must match |
| 4 | Object count, little-endian `uint32` |
| per object | Ink (1), visibility (1), label length in bytes (1) + UTF-8, one |
|  | little-endian `float` per basis term, the radius as one more `float`, then shines (1) |

`MAGIC_SCENE` and `VERSION_SCENE` are exported and reach browser scripts through
`nimSceneMagic`/`nimSceneVersion`, so there is no literal to drift; labels go through
`TextEncoder`/`TextDecoder`. Three defects of the same shape — a value derived in Nim and
copied by hand into JavaScript — once left the two builds unable to open each other's files
while the round-trip suite stayed green, because it only ever asked one build to read what
it wrote.

Only live objects are written, **in creation order** (`nimSceneHandlesCreated` on the browser
side; `nimSceneHandles` keeps handle order for the combo boxes indexed by position). That order
is the whole of what version 3 added; version 4 appended the radius after each object's
geometry and version 5 the shines byte after that, and which versions carry each is
`scene.hasRadius`/`hasShine`, reached by the browser parser through
`nimSceneHasRadius`/`nimSceneHasShine` rather than literals. Version 6 changed no byte: it
records that the palette lost its structural `Algebra` handle at ordinal 7, so every hue a
version-2-to-5 file wrote sits one past today's, and `upgradedFrom5` takes it down (a byte
naming the handle itself is refused, since no build assigned it to an object). The version-1
fold therefore lands in version 2's dialect, one past today's, and is taken down by the same
step — the suite pins both, ordinal by ordinal. Omitted on purpose: handle numbers, a per-object
ordinal, fixed-width label padding.

**A loaded scene replays its construction.** `born` is not written, but
`scene.bornReplaying(index, count, now)` stamps the `index`-th of `count` arrivals a beat
after the last, and `animationProgress` reads a `born` the clock has not reached as zero.
`SECONDS_REPLAY_STEP` = 0.12 is shorter than the 350 ms appear animation, so an object is
still growing as the next lands; `SECONDS_REPLAY_WHOLE` = 2.5 caps the whole arrival by
shortening the beat, or a full scene would take minutes. Every arrival a reader did not
build replays — a file, the demo, the opening scene — through one rule in both loaders and
`replayFrom` for callers that assemble first.

**Every version ever written is still readable.** `VERSION_SCENE_LEAST` = 1 and should stay
1: reading an old version costs a mapping func and a suite case, refusing one costs somebody
their scene. Reading is written once against `VERSION_SCENE`; each past version's difference
lives in one `upgradedFrom<n>`, and `objectUpgraded` walks an `ObjectSaved` up the chain one
step at a time. Version 4 costs suns: `upgradedFrom4` fills false, so nothing shines and
every point draws flat as it did. Version 3 costs sizes: `upgradedFrom3` fills
`RADIUS_OBJECT_DEFAULT`, the size version 3 drew everything at, whatever the parser had in the
field — and the chain refuses a
radius that is zero, negative or NaN as it refuses an unknown palette slot. Version 2 costs
nothing but the sequence guarantee (`upgradedFrom2` is an
explicit no-op kept so the question has an answer); version 1 costs colours only — its
ordinals name a palette that no longer exists, folded by the same cycle `inkCycled` walks,
bounded by `ORDINAL_INK_HIGH_V1` = 14 so a byte version 1 could never have written is
refused. The browser's own version-1-stamped version-2 files read one hue along; **a wrong
hue is recoverable, a refused scene is not**. `loadScene` parses into a staging scene and
replaces the caller's only on complete success; native-only.

*Checked.* Verified by cross-reading, not round-tripping: the sixteen-object demo saved,
reloaded and compared object for object in creation order — label, ink, visibility and all
sixteen coefficients, 304 scalar comparisons exactly equal; the desktop re-saving the
browser-written file byte-identical, all 2245 bytes; hand-built version-1 and version-2
files read the same by both parsers (version 1's ordinals 4/7/11/13 as
`Grid`/`Rose`/`Cobalt`/`Copper`); a file one version ahead refused by both; ordinal 15 in a
version-1 file refused. Verified by watching: seeds arriving over 0.480 s and the demo's
sixteen over 1.84 s in the browser; the desktop's frames 2/8/16/24/45 building the scene.
Verified by suite: the on-disk bytes of a known float. Assumed: the big-endian host path,
never exercised (see Known Limitations).


Demo: The Solar Neighbourhood
---
The demo preset is the build's own load case, in three sizes: `ScaleOrrery.Nearest` (60),
`Neighbourhood` (360, the default everywhere) and `Catalogue` (5038, two handles short of the
pool — the smallest margin that still proves the point of leaving one: add a point, then
join it to something). Every size is the same construction — Sol entire, then real stars
outward, then four objects in horizon — truncated at a different depth, so a cost can be read
as a slope. Measured on one page under SwiftShader: 60 / 360 / 5038 objects cost 1.3 / 1.7 /
3.0 s to build, a frame build 3.1 / 4.6 / 12.8 ms, an edit 9.1 / 8.5 / 8.0 ms — flat, the
ring timeline doing its job. The working rule: `Nearest` for a quick check, `Neighbourhood`
for a final one, `Catalogue` when the change could cost performance. **Each size lands on
its count exactly**: the star walk passes over a system too large for the room left and
keeps walking, so a nearer four-object system gives way to a further single star; the suite
bounds the slack (once a system needing `k` objects is passed over, at most `k − 1` stars can
follow it in). `orrery.showOrrery` is the one copy — arrangement, replayed arrival and camera
solve — reached by the bridge and by the desktop's `--demo`.

**Sol at the origin, its ecliptic flat in the ground grid's own plane**, every star, known
planet and major moon that fits at its real distance. `sol` is `1 𝐞₄`; `ecliptic sol` is
`−89.11 𝐞₄₁₂` and nothing else, the z = 0 plane; every planet has z exactly 0, Neptune at
12.000 units, the system radius its own scale claims. `SOL` names its bodies with real
distances in AU; `radiusOfSolBody` compresses them by a **logarithm**, lifted by `SHIFT_SOL`
= 1.0 so Mercury stands clear and normalised so Neptune sits at `SYSTEM_SOL.radius` = 12 —
the real order and the shape of the real spacing, a 77× range squashed to under 10×. The
tail indices are named constants (`INDEX_SOL_EARTH`, `INDEX_SOL_URANUS`,
`INDEX_SOL_NEPTUNE`, `INDEX_MOON_LUNA`) held to their bodies at compile time; positional
indices once put the ecliptic's furthest distance on a comet at 17.8 AU rather than Neptune
at 30.05 while the doc comment said otherwise. `TILT_MOON` = 0.0897 rad carries Luna's real
5.14° inclination, separate from the system's lean; the horizon plane is
`att(ecliptic) ∧ att(earth ∧ luna)` and exists only because the two differ. Moons map their
real semi-major axes (Phobos at 9,376 km to Nereid at 5.5 million, a range of 588) onto
`RADIUS_MOON_NEAREST` 0.08 to `RADIUS_MOON_FURTHEST` 0.32 by the same logarithm, **measured
from the parent's drawn rim**, not its centre; small because Venus and Earth stand 0.74 units
apart and a wider ring reaches the next orbit. From the rim because the planets now have one:
Io's ring measured from Jupiter's centre lay at 0.22 inside Jupiter's 0.19 disc.

**Every body is drawn at its real radius on a square-root scale** (`radiusDrawnOf`):
`RADIUS_SOL_DRAWN` = 0.6 × √(km / 695,700 km), with the real mean radii in `SOL` and `MOONS`
(`kilometres_radius`). Sol 0.6, Jupiter 0.19, Saturn 0.17, Earth 0.057, Luna 0.03, Phobos
0.0024 — order kept, the Sol-to-Earth ratio compressed from 109 to 10.4 so four sizes read as
four. **Rejected**: true scale, which at Mercury's seven units per AU puts Sol at 0.03 and
Earth at 0.0003, every body under the least dot from any camera that shows two of them — the
picture before sizes existed; linear scale anchored at Sol, which puts Earth at 0.006, still a
dot beside the sun. The anchor 0.6 is under a quarter of Mercury's ring (2.75) so the innermost
planet stands clear, and wider than the opening camera's least dot (8.7 px at 139 units) so
Sol reads as a sun among stars. Neighbour suns take Sol's radius and neighbour planets Earth's
(`RADIUS_NEIGHBOUR_SUN`, `RADIUS_NEIGHBOUR_PLANET`): neither catalogue carries radii, and one
figure for all is honest about that. No other spacing changed — the orbit rings were already
far wider than any body — and the suite pins order, ratio, every moon's ring clearing its
planet's disc and its own, and every body above `RADIUS_OBJECT_LEAST`. Verified by looking:
Sol at 14 units is a disc among dots, Jupiter's four moons are discs about its disc at 1.2
units, and the desktop draws the same frame as the browser.

**Two shipped catalogues, data only, generated.** `neighbourhood.nim` is a snapshot of the
NASA Exoplanet Archive taken 2026-08-31 from its TAP service (`select hostname, pl_name,
sy_dist, ra, dec, pl_orbsmax from ps where sy_dist < 35 and default_flag = 1`, fetched in
distance bands): 331 planet hosts out to 31.5 parsecs. This research has made use of the
NASA Exoplanet Archive, which is operated by the California Institute of Technology under
contract with NASA under the Exoplanet Exploration Program. `starfield.nim` is a snapshot of
SIMBAD, every star within the same 31.53 parsecs, with the query recorded in the file: 11,432
returned, 180 composite entries dropped in favour of their listed components, 11,252 kept.
Each planet host was matched to exactly one star **by sky position alone**, worst separation
161 arcseconds — Barnard's and Kapteyn's stars, the two highest proper motions known, are the
two worst matches, the mechanism confirming itself. Distance is not used to match because it
is what the two archives disagree about: the exoplanet archive puts GJ 411 at 5.676 parsecs
where the truth is 2.55. So the star layer supplies every position and distance and the
archive only which planets exist. **Nothing is generated**: a star with no known planet is a
star. Not claimed as data, and marked so at the code: each neighbour's disc orientation
(`lean`, `spin`) is spread from its coordinates so discs do not stack; 49 of 544 planets with
no recorded semi-major axis are placed by their order among siblings and stored as `0.0`.
**What is not checked is either table against its archive**: no tool re-derives them, so a
hand edit would pass; stated rather than papered over.

**`UNITS_PER_PARSEC` = 100.** At 18 the nearest neighbour stood 24 units out against systems
9 units wide, and thousands piled into one frame; Proxima now stands 130 units out (fourteen
neighbour widths) and the outermost catalogue star 3,153. `RADIUS_NEIGHBOUR` = 9 and Sol's 12
did not move with it, since what reads as clustered is the ratio of spacing to system size.
**The price lands on the opening camera**: `RADIUS_ORRERY` fits the view to Sol and
`FRAMED_ORRERY − 1` = 1 nearest neighbour, about 139 units against Sol's 12, so Sol is a
twenty-pixel smudge until a reader dollies in (it reads at a distance of 48). Fitted to four,
the camera stood 273 units off with a hundred and fifty systems on screen and nothing left to
go and find. The camera is pitched to `ELEVATION_ORRERY_SHOWN` = 0.95 rad (at the opening
0.42 every ring collapses to a line) and pulled back by `camera.distanceFitting`, the same
solve a framed selection uses, azimuth left where the reader had it, `INSET_ORRERY_SHOWN`
24 px. Planet radii use `AU_NEIGHBOUR_NEAREST` 0.01 to `AU_NEIGHBOUR_FURTHEST` 30 on the same
logarithm, clamped rather than extended. `FACTOR_ISOLATION_ORRERY` = 2.0 floors the tightest
pair's separation against their combined reach.

**Colour says what a thing is, not which system it belongs to.** `lut_role_to_ink` maps a
`Role` to an `Ink`: four kinds of body on four handles and everything derived on the fifth,
`Olive`, the darkest — on a body a moon was a smudge that could not be found against the sky.
With comets gone the palette's declared `Jade`/`Cobalt` exception is not in this scene: four
roles, four inks.

**Three suite properties a model of a real system has to get right**: the planets run
strictly outward in the table's order; the squash is real (outermost under ten times the
innermost, where the truth is 77); the horizon line is proportional to `attitude` of the
scene's own `ecliptic sol`. No point is a hub (lines and planes through any point ≤ 6, worst
`sun 1` at 4, where a star-centred layout scored 22); the one orbit line is `sol ∧ earth`,
asked geometrically rather than by label; three collinear points never wedge to nothing
(held by an assertion at construction and a suite case listing offenders).

*Checked.* Verified by suite at every size: every star at the distance its table gives it
(worst error under `TOLERANCE_SINGLE`), the table ordered outward, the count exact, the
camera solve, every object against the role table with four distinct body inks. Verified by
reading the built scene: the multivectors quoted above, the moons' order (Phobos 0.080,
Triton 0.217, Luna 0.219, Io 0.223, Titan 0.263, Callisto 0.279). Verified by looking, at
three shallow elevations (0.10, 0.25, 0.45 rad): the grid reads cleanly through the coplanar
ecliptic disc, no stipple. Verified by measuring: the page grew 2.17 → 3.64 MB for the star
catalogue (mostly names). Assumed: the archive snapshots themselves.


Operation Notation
---
**One table, `scene.lut_operation_to_notation`, read by both builds**, each entry Lengyel's
bold notation, two spaces, the English name (`𝐦⊖  attitude`); `notationSymbolic` and
`notationNamed` are its two halves. `notationSubstituted` swaps `𝐦`/`𝐧` for real operand
names through two sentinel passes, so an operand whose name contains a placeholder is never
re-touched and a template with `𝐧` twice substitutes both.

**Every glyph and its placement comes from that operator's own declaration doc comment in
`pga/operators.nim`/`pga/multivectors.nim`** — never from `pga.nim`'s summary table, whose
"Lengyel" column renders several unary operators in a functional shorthand the declarations
do not use, and which has carried prefix glyphs where the declaration says postfix. Verify by
extracting codepoints, not by eye; U+2212 minus is invisible against a hyphen. One deliberate
exception: `Attitude` reads prefix in its doc comment and is placed postfix (`𝐦⊖`) on explicit
request, for consistency with every other unary entry.

The five accented operands use **spacing modifier letters** (`ˆ` U+02C6, `ˍ` U+02CD, `¯`
U+00AF, `˜` U+02DC, `˷` U+02F7), not combining marks: Dear ImGui has no shaper, so a
combining form landed to the right of its operand, and antireverse's tilde-below read as
left complement's low line. Of the four compound operators only the `★` pair works infix;
`m ∧☆ n` must be written `` m.`∧ ☆`n ``.

*Checked.* Verified by rendering all 27 entries at once and reading them; by
`tools/check_atlas` on every run. Assumed: nothing.


Naming And Number Formatting
---
Basis elements are named exactly as the library's `$` names them (`𝟏`, `𝟙`, bold `𝐞` with
subscript digits); `lut_basis_to_name` **derives** them from the enum, and a suite case holds
each entry equal to what the library prints. Magnitudes read to **four significant digits**
(`DIGITS_SIGNIFICANT`): desktop `snprintf("%.4g")` into a stack buffer, browser
`format.formatMagnitude` in plain Nim behind `nimFormatNumber` — a decimal exponent by
`log10`, digits scaled, and **half-to-even** rounding, which C uses and Nim's `round` does not
(1012.5 reads `1012` in C and `1013` from `round`). `formatBiggestFloat` disagreed with itself
across backends on 1655 of 7000 values, so it is no primitive to build on. Both front-ends
print a multivector through one writer (`scene.multivectorText`) and a shape through one
(`scene.shapeText`). Diagnostics readings keep `%.*f` through `appendFixed`, since a live
number that changes width is harder to read.

Fixed char storage is read through `format.toText`, never `$toCstring`, which casts the
storage's *address* and yields an empty string on the JS backend.

*Checked.* Verified by suite on both backends: 17,001 values across 25 decades including every
exact eighth, zero disagreements against C's `%.4g` and zero between backends; the JS entry
point pins the tie cases' text directly. The C-only `magnitudesAgree` once stayed green while
330 of 7000 values differed between the front-ends, which is why the suite runs under `nim js`.


Animation
---
`ANIMATION_MILLISECONDS` = 350 and `easeOutCubic` are the one duration and one curve: a fresh
object grows in over them, the camera tween eases over them, and the browser reads them across
the bridge into `--anim`/`--ease` on `:root` (the CSS curve `cubic-bezier(0.215, 0.61, 0.355,
1)` is easeOutCubic exactly). One exception, marked as one: the opening hint is a timed
disclosure whose delay lives in browser scripts alone — a stylesheet `transition-delay` ran from the
class being added rather than from load, so the two stacked.

*Checked.* Assumed: that one duration suits every transition; nobody has asked otherwise.


Camera Aiming And Framing
---
`camera.aimIncluding(aim, geometry, scale)` folds one object into what the camera has been
asked to show: a horizon point contributes its direction, a horizon line the first axis
spanning perpendicular to its normal, a horizon plane nothing, and anything finite widens a
bounding sphere by `mesh.anchorFor`'s point. `CameraAim` is a **requirement**, a pure function
of the geometry, which is what lets the standing offer re-made every frame compare equal every
frame. **The sphere is over what has to fit** (`is_bound_by_fitted`): the first point or
finite plane folded in discards whatever lines contributed, since a line whose support stands
forty units off dragged the view off the point beside it (73.8 against a distance of 12). A
plane widens the sphere by its **whole disc** (`widened` merges balls, with the swallowing case
written out).

Both builds aim from **one rule**, `framing.offerAim`, once per frame: the open session's
staged multivector if there is one, else every selected object. **A standing offer** — the
tween keeps its goal after arriving (`is_arrived` stops `advance` writing); a camera the user
moves calls `abandon`, which keeps the goal and marks it done (`release` clears it, so the
offer is re-made next frame and the camera taken straight back — panning was dead while
anything stayed selected, on both builds); `release` belongs to the offer's own side. `goal`
and `destination` are separate fields: the goal depends on geometry alone, the destination is
a `CameraStance` resolved once against the camera as it stood. `advance` eases pivot and
angles linearly and **distance geometrically**. `runStoryboard` goes through the same rule and
calls `settle`.

**Framing** (`framing.nim`): on a new pick, **the orbit pivot comes to the middle of what
was picked** — `objects.centroidFolded`, a sum of unit-weight points read back through
`position`, over the same objects the bound is over, each yielded **once** by `watched` (a
middle is a tally where a bound is a set) — and the camera moves by the **least zoom and
orbit** on top of that which puts every selected object in view, where in view means the
centred box `camera.reachCentred` shapes: `FRACTION_VIEW_CENTRED` = 2/3 of the height, and
two thirds of the width **or the height, whichever is less**. The width cap because the field
of view is vertical: uncapped, the acceptance edge stood at 23.9° across a 1440×900 window
against 15.4° down, so picking an object on a desktop practically never moved the camera
while the same pick on a phone did; capped, 0.417 of the half-frame across, exactly
`2/3 × 900/1440`. One-sided, since on a tall frame the width is already the shorter side.
`reachCentred` is the one statement of the box, from which `picking` derives pixel margins
and `halfAngleCentred` the cone `distanceFitting` solves.

**Three readings, following what each shape is drawn at**: a point's dot fits inside the
centred box (inset `INSET_POINT_SHOWN`, half of `DIAMETER_POINT_LEAST` — the least dot, not
the point's own disc, or a sun filling half the frame would push the camera out to hold its
rim; deliberately not by the swelling marker); a line merely crosses it (drawn to
`radius_horizon`, it has no size to fit); a
plane's **centre** is in the centred box and its **rim** on screen — against the frame inset
by `INSET_RIM_SHOWN`, half the rim's stroke, 1.25 px, the entire price of letting a disc reach
the edge. Holding the rim to the box threw the camera from 19 to 29.9 on the ground plane
where 19 already showed the whole circle; rim on screen gives 19 → 19 from the home camera,
8 → 15.24 dollied in, 19 → 42.76 on a phone. Screen segments meet the box by Liang–Barsky
clipping. A plane is judged where its disc is drawn (the stored anchor), not at its support.

**The cut.** `stanceFor` first asks whether everything is already in view *where the
camera stands* — judged at the centred placement instead, every pick of something plainly
visible pulled the view about. Otherwise it builds the full placement (middle as pivot,
facing angles for horizon-only, bisected least distance: `ROUNDS_DISTANCE_FIT` = 8, the
closed form `radius / sin θ` as the upper bracket only) and searches the least fraction of
`camera.toward` satisfying `isShownAll`: `STEPS_PLACEMENT_LEAST` = 12 even steps then
`ROUNDS_PLACEMENT_LEAST` = 5 halvings, each candidate verified at its own placement. The
pivot is not part of the cut; distance grows, never shrinks; a finite pick never changes
azimuth or elevation, and a star is turned toward only when nothing finite was picked.

**A pointer pick keeps its object under the pointer and comes in to it.** The centring
rule above is for picks with no pointer (objects list, keyboard, a shift-added group). A
click or tap on a point or a line records a `framing.PointerPick` (handle and cursor;
`Panel.pointer_pick`, `POINTER_PICK` in the bridge, written by `nimPickByPointer` from
browser scripts's `pickByPointer` on click, tap and matured hold), which `offerAim` consumes on
the next frame. The destination is the wheel's own move (`stanceUnderPointer`): the eye
comes in along its line to where the object stands under the pointer
(`picking.positionUnderPointerOn`, shared with the zoom anchor and without its nearness
filter), the angles never change, and the pivot lands on the sight line at the object's
depth — so the object's pixel does not move and the turntable revolves at its depth, as
after a wheel zoom onto it. **How far in depends on the shape and on what the reader could
see**, sized on the frame's height by one formula, `camera.depthSpanning(diameter,
fraction)` = diameter / (2·fraction·tan(fov/2)), the depth at which a world diameter spans
that fraction of the frame (a disc's projected major axis is its diameter whatever its
tilt, so it serves the point's ball and the plane's disc alike). A point drawn at the floor dot
(`DIAMETER_POINT_LEAST`, its true radius under three pixels) is only a place, so the
camera comes in until its disc spans `FRACTION_HEIGHT_APPROACH_POINT` = 0.01 of the
frame's height (a sixth of the frame, the first setting, was too close: the object filled
the view with nothing about it, and a twentieth still was; both fractions were chosen by
eye). A point seen at its
size, and a line, come in no further than the orbit distance, so a reader at working
scale picking operands keeps that scale (the opening scene's 0.08-radius points from Home
are 9 px across, and a click slides in without zooming); and neither moves the eye further
off than the object already stands. A plane is framed **both ways**: its disc's centre
(`tessellate.anchorFor` with the stored anchor, the centre the disc is drawn about) is
brought to the depth where the disc's diameter `2·EXTENT_PLANE_F` spans
`FRACTION_HEIGHT_APPROACH_PLANE` = 0.40, in from afar and back from a plane filling the
view, while the crossing under the pointer stays the held anchor — moving the eye along
its line to the crossing by factor *s* puts the centre at depth d_c − d_a + s·d_a, so the
crossing ends at D − d_c + d_a, and where that is not positive (the centre further behind
the crossing than D) the pick falls back to `stanceFor`. Rejected: keeping the plane on
the centring rule, which never pulled in, so a plane picked from far was never brought to
be looked at. A group keeps the centring rule, since it has to fit, which holding one pixel
cannot promise. **The ease holds the
pixel too**: `CameraTween.anchor_held` switches `advance` from `toward` to
`towardHoldingAnchor`, where the eye's depth to the anchor moves geometrically along the
eye–anchor line; `toward`'s linear pivot and geometric distance take the eye off that
line mid-ease (from 168 to 10 the halfway eye sits at 41 by one curve and 89 by the
other), and the object swung off the pointer before swinging back. **A pick renews a held
goal**: the standing offer ignores a goal it already holds, so the same object picked
again after the wheel had taken the reader out went nowhere — the "sometimes it doesn't
zoom in" report, reproduced on the demo: from 30 units a pick of Jupiter flew to it, but
after a wheel out to 168 a pick of a moon moved the pivot onto it and left the distance
at 168. `aimAt`'s `is_renewed` re-arms the ease for a pointer pick whatever the tween
holds. Verified by suite (the pixel stays within 0.01 px through five steps of the ease
and the arrival distance equals the fit; a near point and a line keep the orbit distance;
a pair holds no anchor; a re-pick after `abandon` and a dolly re-arms) and by driven check
on the browser (from 45 units a right-click brings the eye to 19.3 with the anchor
drifting 0.00 px in flight and settled and the pivot at the object's depth; a second pick
after wheeling out past 100 comes in to 19.3 again; a right-click on the opening scene's
ground plane from Home settles its centre at 48.28, exactly the depth wanted for 0.40).
The suite pins the plane's arrival from 12 units and from 1, the crossing's pixel held
through both. Both front-ends rendered and looked at.

*Checked.* Verified on the shipped page, seven selections × nine starting orientations: worst
picked point outside the box 0.0 px (323.9 when watching one object); total pan over 63 trials
97.2 (277.9 when centring the selection); trials moving an in-view selection none; orbit turned
0.000 in all 63; distance 12.0–13.6 and never below. Verified by real touch events
(`verify_touch_pan.js`): pan unselected, pan selected (0.21 units against 4.40 with `release`),
a grab mid-ease, re-selecting after deselect. Verified by driven check: the preview framed with
its operands (the camera pulling from 9 to 13.39 with both landing inside the box). Verified
that it was not a mouse-path fault: identical camera readings under mouse and CDP touch at two
viewports. Assumed: nothing.


Hold Feedback, Help And Keys
---
**A touch hold shows itself**: `interaction` owns `SECONDS_LONG_PRESS`, a `Hold`, and
`progressHold`/`isHoldMature`, and the indicator is the marker itself drawn part-built (see
the fills table under Selection). Progress is **linear, never eased** — a clock being shown,
and an eased clock appears to stall just before it fires.

Both front-ends carry a `?` in the bottom-right corner, at least 44 px, opening the same
table `help.lut_help_entries`, which both render. Construct rows derive from `armingOf` and
`revealsMenuOn`; keyboard rows from `motionFor` and `actionFor`; the `operations` tab is
generated from the catalogue (`notationSymbolic` against `notationNamed`), so it cannot fall
behind. **Tabbed by how you are working**: `drag`, `select`, `menu`, `panel`, `camera`,
`keys`, `operations`. `ENTRIES_MAX_PATH` = 8 per tab (`ENTRIES_MAX_PATH_KEYS` = 12,
`ENTRIES_MAX_PATH_CATALOGUE` the operation count), asserted at compile time and in the suite,
a **proxy and named as one**: the real constraint is rendered height. Measured at 320×568 as
overflow of the rows box: `drag`, `select`, `menu`, `panel`, `camera` 0 (two after their
descriptions were cut, about 17 px each), **`keys` 129 px over**, left scrolling deliberately
— fitting it costs `enter`'s "hold shift to add it" on every screen to serve one with no
keyboard; stacking cells was worse (161 over) and regrouping keyboard rows onto other tabs
left `camera` 133 and `select` 66 over. Shift gets one row, not one per button: all four
combinations measured 125 px over. **Every row makes sense with the rows above covered up**;
what a two-column row cannot carry goes in `descriptionOf`, one sentence per tab, crossing as
`nimHelpDescriptions`. One word, one meaning: objects are **selected**, operations **chosen**.

The browser's two columns are one grid over the whole table (`.help-rows` the grid, each row
`display: contents`), so a column is one width down the table; a flat `44%` gave the actions
245 px they did not want. Both tracks carry a 122 px floor, measured: without the outcome
floor the actions took 208 of the 262 px a 320 px phone leaves; 150 px does not fit beside 122
and the 10 px gap; dropping the action track to bare `max-content` put `drag` 533 px over. The
panel is a flex column, capping its own height with `min-height: 0` on the rows box. Rows are
hidden by attribute, which needs `.help-row[hidden] { display: none }`. The desktop measures
its outcome column off the widest action, **only while the panel is open**: measuring every
frame changed which glyphs Dear ImGui rasterised into the atlas and moved single pixels of
panel text in the storyboard across three rounds (bisected: with the fix, two table sizes
give byte-identical storyboards). `guiChildHeightForRows` asks Dear ImGui for its own line
spacing rather than restating it. **The help stays open until it is closed**; the two
popovers keep their tap-outside dismissal.

**Keyboard.** `Escape` sheds what is in progress, innermost first, and on the desktop no longer
quits (`ctrl+Q` does). The view is one ordinary tab stop — **Tab is deliberately not rebound**,
which would trap (WCAG 2.1.2) — and traversal took the brackets:

| Key | Does | Kind |
|---|---|---|
| `w` `a` `s` `d` | slide the view across the ground | held |
| `q` / `e` | lower / raise it | held |
| arrows | orbit | held |
| `-` / `+` | dolly out / in | held |
| `shift` | multiply every rate by `FACTOR_HASTE` | held |
| `[` / `]` | focus the previous / next object | press |
| `enter` | select it, or add it where shift is held | press |
| `f` | frame whatever is selected | press |
| `home` | put the camera back where it started | press |

`motionFor` and `actionFor` split by **kind**: a motion runs every frame its key is down
(`driveHeld`), an action once at the press. The bindings follow Unity, Unreal, Godot and
Blender (WASD, Q/E, shift for faster, F to frame), with the one fork made the map's way:
the view *slides* across the ground and the height never changes. Both front-ends watch key
up as well as down; `releaseKeysAll` empties the held set on blur, on the tab being hidden,
and when a panel widget takes the keyboard (`gui.wantsKeys`: `WantTextInput` or
`IsAnyObjectFocused` — `WantCaptureKeyboard` is true from the first frame with navigation on).
Plain `s` moved to `ctrl+s`. Dear ImGui's keyboard navigation is enabled (`io.ConfigFlags`);
without it Tab reached nothing on the desktop at all.

**A camera move is not a hover** (`isMovingCamera`: each front-end's own drag flag, plus
`keys_held` through `motionFor`, so shift alone is not movement; a construction drag is
excluded). Raised by the movement, not by the press, or a click read a suppressed hover. The
latched flag is cleared on blur, on the tab being hidden, and at the start of any gesture
that finds no pointer down. **Focus is its own state** (`index_focus`), pruned against
liveness and drawn with the hover marker; the browser adds an inset `:focus-visible` ring.

*Checked.* Verified by `--drive-keys`: focus walked, enter selected, azimuth/elevation/distance
each moved by exactly their own constant. Verified by browser drive: real key events; Tab from
the canvas moving to the next control and back; a blur mid-hold moving the pivot 0.0000
further; the help table's per-tab overflow at 320×568; `[]-+` typed into a label reaching the
label. **Not demonstrated**: Tab landing on a Dear ImGui widget — a window that never takes
focus under `xvfb` gives ImGui nothing to move; `gui.isNavEnabled` reports the configuration,
not the behaviour.


Style Guide
---
Two documents at the project root. `CONSTITUTION.md` is the rule of law: eleven articles over
exposition, derivation, notation, build-time safety, naming, documentation, cost, honesty,
tests, form and the record, with a precedence clause and three gated mechanisms. `STYLE.md`
is the Nim expression guide: how each rule is spelled in Nim, and what each backend does with
a value.

**Every comment in the project has been reworked to the vendored `pga` library's prose
register**, against both documents: a one-line imperative summary ending in a period (types
open "Define …"), elaboration as a hanging outline one claim per line, stage comments with a
verb-first lead, trailing fragments on fields ending in a period, no articles, no history and
no figures (which moved here). `tools/check_prose` holds the whole of that mechanically —
article rule, summary form, stage form — in every authored language, and runs in `verify.sh`.

**The code was then refactored against both documents in seven passes**, each its own
commit, each verified by every build pivot, both suites and the driven checks before the
next began:

- **Separators** (STYLE §5): commas between parameters until one type repeats, across 256
  signatures.
- **Grouping** (X.5, X.6): related constants and module state under one keyword; bracket
  imports.
- **Naming** (V): the bridge's module state in screaming case; accessor funcs in
  lowerCamelCase; booleans on the sanctioned prefixes; `cam_`, `btn`, `diag-` and `coeff`
  spelled out across Nim, JS and CSS.
- **Safety** (IV.4, STYLE §2): in-range sentinels to `Option`; every assertion message ends
  by echoing its value; every enum pure and every member qualified.
- **Purity** (STYLE §1, §2): every proc that compiles as `func` demoted, 148 of them;
  `strictFuncs` in every module including the tools.
- **Form** (VI.1, X.2–X.4): every foreign binding documented; nesting past three deep split
  (option parsing, help tab, veil runs, renderer setup); multi-line constructors one field per
  line; banners and definitions spaced by tier.
- **Cost** (VII, STYLE §4): the six overlay exports asked per frame answer from module flat
  buffers.

**Foreign bindings are marked `sideEffect`, and that is what makes `func` mean anything
here.** Nim assumes an imported body is pure, so before the mark the demotion pass turned
every GL draw and every Dear ImGui layout into a `func` and the compiler agreed. With the
mark on all 130-odd bindings in `gui`, `opengl`, `sdl3`, `image` and the bridge's `importjs`
lines, 51 of those funcs failed to compile and went back to `proc`; the 66 that stayed `proc`
from the first pass are the ones touching module state or the clock. A `func` in this tree
now means the compiler checked it reaches no effect.

**Deliberately left as they are**, each against a rule the reader might expect to see
applied: the binding names in `opengl.nim` and `sdl3.nim` keep the foreign API's own verbs
(`getError`, `getString`, `getUniformLocation`), since a reader greps the SDL and GL
references by those names and V.3's bare-noun rule is for this project's own properties;
lookup tables at module scope stay lowercase `lut_…` per V.5, the one family V.1's
screaming case does not cover; `nimCameraPivot`, `nimOverlayMetrics`, `nimInkColor` and the
scene-listing exports still return sequences, being asked on the UI tick, on a redraw or once
rather than per frame; `visualiser.main`, `format.formatMagnitude` and the two tool `main`s
stay over sixty lines with the comment X.4 asks for, as one derivation or one report each.
Kept from earlier audits: the bridge's FFI-boundary cases translate through one `SLOT_NONE`
at each proc's return; the `when defined(js)` seams in `scene.nim` are backend necessities;
browser scripts and `shell.html` use snake_case for data bindings and camelCase for callables,
shader attribute strings untouched.

The vendored `pga` library was reviewed and left unmodified by request. Known deviations are
mechanical, plus one substantive: `pga.nim:28` asserts its own module doc is the source of
truth for names, which is what makes the notation trap easy to fall into.

*Checked.* Verified: `check_prose` and `check_columns` report zero complaints; every build
pivot, the three suites and both drives pass on the refactored tree; the demotion and the
revert were decided by the compiler, not by reading. Verified by reading the emitted JS: the
six per-frame exports allocate nothing (`nimDragTint` binds the ink, not the colour, since
`lent` bound to `let` copies; an array literal handed to an `openArray` parameter is a
`new Float32Array` per call, which is why the fills are templates). The gain from that pass
is **unmeasured**: no frame-time pair was taken, and the claim is the allocation count read
off the generated code, not a millisecond. **Unverified**: no human has read the result.


Dependencies / Vendoring
---
**The PGA library is a pinned dependency, never a copy.** It lives in
[replications][replications], which carries no nimble file and holds the library three
directories inside it, so the requirement in `rga_visualiser.nimble` names the repository by
URL and commit, `atlas.lock` records the resolved commit
`f8861e0b5ab6e868382126aa7b109503f2fe16d3`, and `nim.cfg` names the subdirectory Atlas
restores it to. `koch deps` replays that lock; nothing is committed (Article XI.3). Both
projects are Prosperity Public License 3.0.0.

Rejected: copying the library in, which Article XI.3 forbids and which would republish
another repository's tree; and a project verb that clones it, which cannot work because CI
runs `tree`, `deps` and `tests` and never a project's own build driver.

**This project tracks pga's head, and says so when it cannot.** Standing instruction from
the Architect: take the latest pga; when the latest does not work, pin the most recent commit
that does, record which and why, and move forward when it works again. Every pull request
states which pga commit it builds against and whether that is head, so a reader never has to
infer it.

Where that stands now: pinned at head, `295bafc5e97e8ee94943c6f4c7a92f215a74e5e7`. Head
costs two things, and the Architect's instruction is to pay both rather than trail behind.

**The compiler is pinned by commit, not by release.** Head spells its operators in prefix and
compound form (`☆m`, `m ∧☆ n`), needing seven Unicode operator characters Nim gained in pull
request 26074 — merged to `devel`, carried by no release. The pin is therefore
`requires "nim == 27763495bcfe265507ca98aedc1c7064bf1e0e4d"`, that commit, which
`toolchain.nim` accepts beside dotted versions and which CI builds from source and caches per
commit. Rejected: a `devel` label, a moving pivot recording nothing verified; and waiting for
a release, which is months of standing behind the library this project exists to exercise.

**Four projections are withdrawn at head, and `projections.nim` stands in until they return.**
`projectCentral`, `projectCentralAnti`, `projectOrthogonal` and `projectOrthogonalAnti` are
declared `{.error.}` while the library rebuilds them as compound operators (`∨∧★`, `∧∨★`,
`∨∧☆`, `∧∨☆`); this project calls two of them at eight sites, so head alone does not compile
here. Each stand-in is a template carrying the definition the library's own operator table
gives, in that table's notation — copied, never derived, so nothing about the algebra is
invented here (Article II.8).
  The module is a seam. `scene`, `tessellate`, `interaction` and the suite import it instead
  of `pga` and reach both; `export pga except` those four keeps the names from colliding; and
  importing both raises an ambiguous call rather than quietly answering from the wrong one.
  **The guard is what makes this transitional rather than a fork.** A `compiles` probe through
  a qualified call reads the library's own declaration, and an `{.error.}` refuses the build
  the day it gains a body, naming the module to delete and the imports to restore. The stand-in
  cannot outlive its cause, and cannot silently shadow the real thing.
  Rejected: holding the pin one commit back, which was the previous course and leaves the
  project trailing its own dependency; and reshaping the call sites around the missing
  operations, which would let the library's build state decide what the visualiser offers.

**The lexer change reached this project's own source too.** `boundary.directionNormal` wrote
`-☆(m)`, which lexed as unary minus applied to a call while `☆` was an identifier character
and lexes as the single operator `-☆` now. Spelled `-(☆m)`. Found by compiling, not by
reading — nothing in the library's own diff pointed at it.

**What moves the pin**: nothing pending. The pin follows head, so the next pga commit is taken
when it builds. The compiler pin moves to a release once one carries 26074, which costs CI its
bootstrap and nothing else.

*Checked.* Verified by running, on the pinned commit through `koch tests`: 323 cases on the C
backend, 302 on JS, 310 at reduced capacities, none failed — the same three counts the
previous pin produced, which is what says the stand-ins behave as the library's own did.
Verified: `deps/` was deleted, `atlas --noexec rep` cloned and checked out `295bafc`, `atlas
changed` exited 0, and the nimble file was byte-identical afterwards — the replay no longer
reverts the pin, because the lock's stored copy matches the committed file.
Verified by running that the guard fires: the restored `pga.nim` was patched to give
`projectOrthogonal` a body, and the build refused at `projections.nim(40, 10)` with the error
naming the module to delete and the four imports to restore; the tree was then restored clean.
Verified: the pinned compiler reports `git hash:
27763495bcfe265507ca98aedc1c7064bf1e0e4d`, which is what `toolchain.runningCompiler` reads,
and that commit fetches directly from `github.com/nim-lang/Nim`, which is where CI clones it.
Assumed: that no release carries 26074 — checked by asking for 2.2.12, 2.4.0 and 2.6.0 and
getting nothing, which dates rather than proves it.

**Two Atlas defects stand, and the workaround is manual.** `atlas pin` writes `"objects": {}`
for a repository carrying no nimble file, so the resolved commit is patched into `atlas.lock`
by hand; and `atlas` calls the nimble file "broken" because it cannot parse a commit where it
expects a version, which is cosmetic here since it resolves the dependency regardless. Both
were reproduced on the pinned toolchain, not recalled. The lock's stored nimble must equal the
committed one exactly or `rep` reverts the pin silently; reported as repository issue 25, and
the static pass now refuses the difference, so the hand-patch is checked rather than trusted.


Testing
---
One file, `tests/suites.nim`, from three thin entry points that `koch` runs through
testament:

| Entry point | Backend | Capacities | Why |
|-------------|---------|-----------|-----|
| `t4d.nim` | C | Default | The desktop build, as shipped |
| `t4d_browser.nim` | JS | Default | The browser build's own backend |
| `t4d_small.nim` | C | 12 objects, 12-char labels, 4 steps | Boundaries a test reaches |

The JS row is not a formality: a rule reached through two mechanisms is held together only
where both run. The reduced row makes any constant tuned to the default fail here;
`LABEL_MAX` at 12 is under several labels the suite constructs. Cases needing C — `snprintf`,
the encoders, the arena, save/load — guard themselves `when not defined(js)`. A case that
walked every pair of handles at 10,000 objects ran ten minutes without output and was killed;
it gathers the joiners once now.

The JS entry point declares `targets: "js"` rather than overriding testament's command. In
the tree this was ported from, its header named a command testament never ran — the JS suite
was compiled by a shell script instead — so the header was a claim nothing checked. Under
`pivots` testament compiles with the JS backend and runs the result through node, which is
what makes the row real.

**The suites test rules; a second layer drives events.** A rule bug earns a suite case; a
wiring bug earns a driven check, at the layer the bug lived at. That second layer is not in
this repository yet: the desktop drive modes and the browser page driver arrive with the
front-ends they drive. Three harness facts worth keeping for when they do: a driven check is
evidence only for the page just built, so one command must rebuild before it drives
(Article IX.6); a check that leaves state behind (a chip on, a section open) taxes every
check after it, and says so; and a fresh object starts its pulse at zero, so a comet check
waits for a head before timing. Timing-dependent quantities are asserted as **bands**, never
figures: identical code has measured 25.0 and 29.8 ms hours apart on a shared runner, a flat
±1 ms band failed one frame in a hundred and twenty, and a flaky check gets deleted rather
than fixed.

*Checked.* Verified on the pinned commit through `koch tests`: 323 cases on the C backend,
302 on JS, 310 at reduced capacities; the JS count is lower because the C-only cases skip
themselves. Verified on the runner as well as locally, which is what settles a question
local runs cannot: the C suites bind zlib for the PNG encoder, so their passing proves the
runner carries that library rather than only this machine. Assumed: nothing about the suite
itself.


Measurements
---
**Every figure below is unmeasured on this repository's compiler.** All were taken on a
2.3.1 devel build of Nim in the tree this project was ported from; this repository builds on a
2.3.1 devel build too, but at a different commit, and no figure has been re-taken since.
Article VII.6 makes them indicative and nothing more — they are kept because the constants
they justified are still in the code, and a reader deserves to know which number picked which
constant.

Desktop, release build, 4 cores at 2.8 GHz, 1440×900, headless Xvfb + Mesa `llvmpipe`, at 64
objects:

| Quantity | Cost |
|----------|------|
| Tessellate a 64-object scene | 61 µs (~0.95 µs/object) |
| Any catalogued operation | 80–170 ns |

Browser, SwiftShader: opening-scene frame build 21.9 ms released; demo at 5,038 orbiting,
scene walk 9.2 ms with the tally off; one hover pick 3.5 ms at 5,038. **No figure here has
been taken on real GPU hardware**, and a ">500 fps" pivot cannot be assessed in a software
rasteriser, where rasterisation dominates the frame entirely and none of it is this
project's code.

*Checked.* Verified: nothing in this section, on this compiler. Assumed: that the constants
these figures justified remain the right ones, which the ported code has not been re-profiled
to confirm.


Known Limitations
---
- No human has run either build. Every result here is software-rendered and machine-driven.
- Tab landing on a desktop widget is unverified (see Hold Feedback, Help And Keys).
- Two crossing translucent veils blend order-dependently.
- A camera move is not undoable on its own.
- The comet's residual steps at fast orbit rates are unexplained (see Selection And Markers).
- Neither catalogue is checked against its archive by any tool.
- The frame-time tail on real hardware is undiagnosed; this container cannot see it.
- Conformal metric (`IS_CONFORMAL`) is unfinished in the library; this build is rigid 4D.
- `.rgascene` is little-endian by rule, but only a little-endian host has ever written or
  read one; the byte-swapping path is unexercised.

## Re-audit, 2026-09-06

Merged carrying a stamp that three rules changes had moved under it, which reddened `main`
until re-stamped. Audited against each change, by a curator, who may write this file and no
other here:

- **Per-project compiler pin.** Already met: `requires "nim == 2.2.10"` is exact.
- **Curator reach and the regression rule.** No effect on this project's own work.
- **Repeatable verification.** Partly met, and the rest is yours. The *Checked* blocks already
  name how each claim was reached, which is more than most of this repository does. The rule
  now also asks that a claim nobody can repeat from a checkout name its **tool and its date**
  — "Verified by looking", "Verified by rendering", "Verified by driven check" and the
  unmeasured device figures each need one. Nothing was invented to fill those in: only the
  session that ran them knows when, and this curator does not.
- **Citations.** The mechanical half passes: `` `--drive-keys` `` and `` `sizeof` `` name a
  flag and an operator, not files, so `checkCitations` leaves both alone.
- **Gated languages.** Nothing to correct today: this project carries no `.ts`, `.cpp` or
  `.c` file yet. It binds the next pull request rather than this record. C++ and C are now
  registered kinds, so the ImGui shim of issue 26 may land; and every file of a gated kind —
  the TypeScript conversion of issue 27 included — must open with `not Nim because <reason>`,
  which the audit checks. The reason itself is what a curator reads, and a shim that only
  flattens overload sets is a different claim from one carrying logic.
- **The lock's stored nimble.** Already met, and by this project's own hand: `atlas.lock`
  here stores `requires "nim == 2.2.10"`, matching the committed file, after the hand-patch
  reported in issue 25. The check added for it passes on this project.
- **TypeScript and Node.** Nothing to correct today, and everything to read before the
  conversion: CONTRIBUTOR.md now carries the section answering issue 27. Four of the six
  points proposed there were already rules and are confirmed as such; the new rule is npm
  pinning by committed `package.json` and lockfile with each dependency recorded here; and
  the amendments are `noUncheckedIndexedAccess` and `exactOptionalPropertyTypes` beside
  `strict`, plus a `web` verb in `tools/build.nim`. A generated lockfile was measured against
  the form rules before the rule was written, so it may be committed as generated and must
  not be reformatted to fit.
- **Records compile nothing.** A change touching only this project's `README.md`,
  `PROVENANCE.md` or `GLOSSARY.md` now plans `[]`; a README change previously ran the whole
  suite, which for this project means its browser tests too. Nothing here needed correcting.
- **Published pages are linked.** This project publishes no page today, so nothing needed
  correcting; it binds the moment one does. Raised by `dance_ontology` as issue 42.
- **Compiler resolution.** Directly relevant here, since this project is the one pinning a
  commit: koch now resolves each pin itself, so a session holding only a release compiler can
  still run this project's suites — it builds the pinned commit once into
  `~/.cache/koch/nim/<commit>/` and reuses it. Driven on 2026-09-06: `koch ci` green as one
  command with 2.2.4 on `PATH`, this project on its commit and the other three on 2.2.4.
  Atlas now runs with that toolchain leading `PATH`, so the `environment mismatch` warning
  this project's lock produced is gone.
- **Draft pull requests.** Binds how your next pull request is opened rather than anything in
  this record: open it as a draft and mark it ready only when CI is green on the runner,
  every comment is answered, and you intend no further change. Nothing here needed
  correcting.

[replications]: https://gitlab.com/mraxilus/replications

## Re-audit, 2026-09-07, issue routing

Audited by a curator against the change that made the issue channel run both ways and gave each
session a queue. A session now reads the open issues labelled with its own role before any other
work; a curator who reads this project raises what they find as an issue rather than editing it,
since they may not; an issue labelled with a session's own role is that session's queue, work
decided and deferred where the next session here will see it rather than in a conversation that
ends; and a label is the role string exactly, copied and never composed, because applying a
label creates it and a misspelling makes a second label nobody filters on.

Nothing in this tree changes: the rule binds how the next session here starts. Two issues stand
open against this project today, 47 and 48, both now carrying its label, so that session finds
them by the filter rather than by being told.

One thing here needs care rather than correction. This record already carries *Not yet ported*
and several *Unverified* lines, which are the same shape as a queue. They stay where they are:
the record says what **is**, an issue says what is **queued**. Anything filed from them links
the section rather than restating its counts, since two copies of one count will disagree — as
the prototype's check count already did once.

## Re-audit, 2026-09-07, Article II.9 bound

Audited by a curator against the amendment to Article II.9, which this project's issue 48 asked
for. The article now bounds when target code may be hand-written: the source language by
default, the crossing kept narrow, and the target language only where the source cannot reach at
all or where crossing would forfeit what the target gives for free — a check its own compiler
makes over the bulk of a file, a cost the glue would add to a hot path — with the file's opening
comment saying which.

This is the only project the rule reaches: 45 TypeScript files, and every other project holds
none. **All 45 already comply, and nothing needed correcting.** Each was read. Most stand on the
first ground and say so — `src/browser/*.ts` on browser APIs Nim's JS backend does not express,
`keys.ts`, `pan.ts` and `gestures.ts` on Playwright's input API existing only in node,
`touch.ts` and `construct.ts` on Chrome's own protocol. Three stand on the second: `camera.ts`
("only TypeScript checks them against bridge's derived declarations"), `main.ts` ("glue that
would leave every browser-side expression unchecked string") and `page.d.ts` ("only TypeScript
can state them to type-checker").

That the corpus met a rule written after it is not luck. The `not Nim because` gate already
refused a file that argued nothing, so every argument existed; the amendment only requires that
the argument name which of two grounds it stands on, and arguments written honestly already did.
The rule codifies the practice rather than changing it.

What the amendment does decide, which the article as it stood did not: `exceedance.ts` and its
kind. 454 lines, 15 `evaluate` bodies, browser-side expressions that are not something the
target alone *can* do but something the target *checks* and Nim's glue would not. Before the
amendment that file leaned on a reading of "what the target alone can do" it did not quite fit.
It now has a clause of its own.

## Re-audit, 2026-09-07, type check on runner

Audited by a curator against the rule that a project carrying `package.json` beside its lock
carries a `types` verb in `tools/build.nim`, and that CI runs it: `koch types` restores node
tools and drives that verb, scoped to projects one change asks for.

**This is the only project the rule reaches today, and it already met it**: issue 47 asked for
the verb and pull request 56 landed it before this job existed. Nothing here needed correcting.

What changes is who runs it. The record's line under Driven Checks — *"green here is evidence
someone ran it rather than something runner confirms"* — is now true of `drive` alone. The type
check is the runner's: 10,676 lines of TypeScript across `src/browser/` and `tools/drive/`, and
the agreement between `bridge.nim`'s 157 `exportc` signatures and the derived `bridge.d.ts`.

The curator drove that agreement independently rather than taking this project's word for it:
renaming `nimSceneHandles` to `nimSceneSlots` in `bridge.nim` alone makes `koch types` report
one finding over `TS2304: Cannot find name 'nimSceneHandles'` at four sites in
`construct_section.ts`, and reverting returns 0. Same regression pull request 56 recorded,
reproduced through the runner's path.

**Not reached, and still this project's to run:** `drive` itself. That is held on the harness's
115 fixed sleeps against 3 waits on a condition the page reports, which is now the deciding
cost rather than the value — 135 checks made the value case. See issue 47.

## Re-audit, 2026-09-07, system dependencies

Audited by a curator against the rule that system dependencies — a library the compiler links
against, a tool the build shells out to, a browser a driven check drives, a source clone no
package manager carries — are declared as data in the project's own `tools/build.nim`, each
entry carrying its reason, and reached by a verb. A source clone carries its commit; a system
package carries no pin that survives across distributions, and the record says so rather than
implying one; anything fetched at build time carries a checksum the build verifies. No
machine's paths in committed source.

**This project is what rule was written for, and it does not comply yet.** It needs SDL3, libGL,
zlib, Xvfb and software GL on machine before it builds, clones Dear ImGui from source, and
fetches its faces from `cdn.jsdelivr.net` trusting whatever arrives. None of that is declared
anywhere: `README.md`'s build section names none of it, contrary to what issue 60 reported.

Two asks stand, both this project's own work, neither of which curator may do:
  Declare those packages and ImGui's commit as data in `tools/build.nim`, each carrying its
    reason, reached by verb (issue 60, ruled).
  Commit checksum per face and make `assets` fail on mismatch (issue 47, ruled by Architect).
    That is what keeps unpinned download out of merge process, and it is also what lets runner
    cache faces rather than refetch them.

Second ask is what browser job waits on. Once both land, `drive` reaches runner and this
record's *Unverified: CI does not reach this layer* stops being true.

## Re-audit, 2026-09-08, deterministic verdicts

Audited by a curator against the rule that a check gives the same verdict on the same code,
and that where it does not, the check is what is wrong. Retries, longer timeouts, quarantines
and skips are all refused as answers to variance.

The testament suites comply: `tests/suites.nim` seeds with `randomize(0)`, so the sampled
corpus is the same corpus on every run.

**The driven harness does not, and this project already knew it.** The section above records
a blank canvas readback on the runner, `[0,0,0]` where this machine reads `[44,6,24]`, with
its cause marked **Unexplained** — and the check that names blankness was added here for
exactly that reason. What the curator adds is a rate rather than a finding: across three
`push` runs on `main`, runs 147, 148 and 149 on effectively one tree, the readback was blank
**once in three**. That is the measurement the record could not take while CI did not reach
this layer, and it is now the thing the rule asks to be removed. Raised as issue 82 with the
evidence; the mechanism is this project's to choose, and if the cause proves to be the runner's
browser rather than this code, it becomes the curator's to carry.

**Answered.** Blank reading can no longer pass: every pixel check reads through compositor and
refuses reading carrying one colour, whichever colour, and that refusal is itself checked
against black *and* white canvas fixtures it stands up (see Driven Checks); white is second
because runner answered with sheet of it once black alone was refused. Rate above stands as
curator's measurement of what old reader did. Correction to finding: *four* checks had been
comparing one blank reading against another, not one -- `pool`'s reported hash 1426046701 is
exactly its own fold over all-zero 1200x900x4 buffer, which is what shows it. Cause on runner
stays **unexplained**; neither Chromium here reproduces it. Browser runner drove was unpinned
snap, and was raised for curator on issue 77; it is gone. Runner drives build lock pins since
#98, reader has been green on both, and that is evidence against snap having been cause.

**One driven check was still asking the machine rather than the code, and it is fixed.**
`driveRendered` slept 1200 ms and then required twenty timed frames, so its verdict was how
many frames that machine fitted into a fixed span. It drew 27 idle and **19 with a `koch ci`
running beside it** — same code, two verdicts, which is exactly what this rule says makes the
check wrong. It now waits *for frames* rather than for clock: it advances one
`requestAnimationFrame` at a time until twenty are timed, with a 20 s ceiling that only a page
drawing nothing reaches, and it reports the wait either way so a slow machine still says what
it cost. Driven with every core of this container pegged by busy loops: **20 frames timed in
780 ms**, passing. The ceiling is what remains for real failure, and reaching it means no
frames rather than slow ones.

## Re-audit, 2026-09-11, panel in line with page

Audited by a curator against the rules change that splits Article X.8's faces by element —
Noto Serif for headings and titles, Noto Sans for body and interface text, Commit Mono for
code with its ligatures enabled. This project already ships all three and pins every byte, so
the first clause is kept. Two things the split newly asks for: `--serif` is declared in
`pages/shell.html` and never used, so no heading takes it; and Commit Mono is set without
`calt`, so its ligatures — which are functional rather than decorative — do not render.
Repository issue 118 carries both.


## Re-audit, 2026-09-11, panel in line with page

Asked by the Architect: bring the desktop's text and layout in line with the page, drop text
that earns nothing, work the buttons, and keep a section's heading reachable while its list
scrolls.

**The top of the ImGui window was the last copy of something two front-ends used to disagree
about.** It opened with four lines of prose — one teaching drag, three tinting the wheel's
wedges, one about right-drag and touchscreens — above any control. Every one of those is in
help's drag tab, which `?` opens in the same corner of both front-ends, and `help.nim`'s own
header says it exists because *"desktop wrote this in its panel and browser in hint that
vanished after four seconds; two had drifted"*. The browser had since dropped its own
`.drawer-intro`; this was the remaining copy. It is gone, and the window opens on controls as
the drawer does.

**Removing it turned up something the page had already lost.** `interaction.nim` said in two
places that the wheel's words are *"taught once, in drawer's intro line"* — and that line no
longer existed, so **nothing in the browser taught them at all**. A reader met wedges wearing
`𝐦 ∧ 𝐧` and nothing anywhere said that one is `join`. Both comments now point at help, and
the words are taught in `descriptionOf(HelpPath.Drag)`, read from `wordOf` and `labelOf` rather
than written out, so a renamed or renotated wedge is renamed in the telling too. Both UIs
already render that line, so one edit served both. Held by a law in the shared suite — every
wheel word and its notation must appear in that description — which **fails without the fix**
(`Check failed: wordOf(choice) in described`).

**The buttons are the page's three groups, in the page's order.** `add`, `undo` and `redo` on
one row, as `.action-group` has them; `axes` and `grid` as the accent pill this project already
draws for `arity`, which is the same pill `.toggles` wears; then the scene file with `save` and
`load` beside it. The last is where text went as well as shape: a row whose field is named
`scene file` had `save scene` and `load scene` under it, so the noun was in the row three
times. The page's menu spells them the same way under its own headings.
  Checkboxes became pills deliberately. The worry against it is that a pill carries its state
  in colour where a checkbox carries it in a tick — but `guiButtonToggle` already carries fill,
  border *and* text colour together, it is what this panel draws for `arity`, and it is what
  the browser draws for the same two toggles. One control, one shape, across two front-ends.

**A long list no longer buries the rest of the panel, and its heading no longer scrolls away.**
The rule is one sentence — *the heading naming a section stays reachable while that section's
list moves* — and each front-end answers it in its own idiom.
  Desktop bounds the list in a region that hugs its own content until the window runs out and
  scrolls inside that bound after (`ImGuiChildFlags_AutoResizeY` under
  `SetNextWindowSizeConstraints`). The heading sits outside that region, so it cannot move.
  First attempt gave the region a fixed height and a threshold, and a five-object scene sat in
  a box of blank; hugging the content is what fixed that, and the first attempt is recorded
  rather than tidied away.
  Browser sticks the heading with `position: sticky` against `.drawer-scroll`. Its offset is
  `--drawer-clear`, which is the same number that already pushed the drawer's content below the
  floating chip row — named once now instead of written twice, since a heading stuck at `0`
  lands *behind* those controls rather than under them.
  Measured on both. Desktop, scene filled to capacity: **64 px left under the sections** where
  the unbounded list ran **319,899 px** past the window's bottom — which is the same verdict
  failing without the fix, driven by a new scripted run at capacity. Browser: the drawer is
  scrolled to its floor -- **307,775 px** -- and the heading, which sat at 1123 px, holds at
  62, where that scroller's own content begins. The scroll itself is asserted too, since a
  check that reads a stuck heading while nothing moved would pass on a page with no
  stickiness in it.


## Re-audit, 2026-09-11, one menu in two front-ends

Asked by the Architect, after the panel was brought in line: give the desktop the menu the
page has, and make the two as similar as possible.

**What the page had that the desktop did not.** Its `☰` opens a menu of three groups — *save*
(scene, image), *load* (scene), *demo* (one button per orrery size). The desktop had no menu,
kept save and load inline in its top bar, hid its PNG export at the bottom of the **view**
section, and **offered the demo nowhere at all** — `--demo` existed on the command line and
had no control in the window.

**All three groups are now on both.** The desktop's top bar is what the page's chip row is —
`add`, `undo`, `redo`, then `axes`, `grid`, then `☰` — and everything else went behind that
button. `☰` is U+2630, the very character the page's button carries: `RANGES_SYMBOL` already
merges U+2600–26FF into the interface face, so no face had to be pushed to draw it.

**The demo group is built rather than written.** It walks `orrery.ScaleOrrery` and labels each
button with `objectsOf`, exactly as the page builds its own from `nimDemoScales`; a size added
to `orrery` arrives in both menus with neither front-end touched. Loading one calls the same
`showOrrery` the browser calls, then resets selection, timeline and open session as
`bridge.nimLoadDemo` does, and says what the page's toast says.

**Two deliberate differences, both stated rather than smoothed over.**
  The desktop's menu carries `scene file` and `image file` fields above its groups. The page
  has no such fields because its save is a download and its load is a file picker; a desktop
  build writes to paths, and the path a button writes to belongs beside that button.
  The menu hangs from its own button rather than opening at the pointer, which is Dear
  ImGui's default. The page's menu hangs from its chip, and a menu that lands somewhere
  different each time is one the reader has to find twice.

**Checked headlessly, which needed a door.** A popup has no state a scripted run can set, so
`guiMenuBegin` takes `is_forced` and `--drive-menu` opens the menu with no pointer — the same
door `--drive-help` uses for tabs. The verdict reads what the menu laid out: **3 sizes
offered, 3 in `orrery`**. That makes 41 checks over 15 runs.
