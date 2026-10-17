# Provenance

_Who made this, from what, and how far it has been checked._

| Field   | Value |
|---------|-------|
| Harness | Claude Code |
| Author  | Claude Opus 5 and Claude Sonnet 5 |
| Date    | 2026-09-06 |
| Style   | CONSTITUTION.md and STYLE.md, followed. |
| Rules   | cbf4e2e739712a13 |
| Pruned  | 49b8f1c6ca50b0bb20472edd1cc819a6d7222045 |
| Review  | **Unreviewed.** Nothing here has been read line by line by a human. |

An interactive visualiser of rigid geometric algebra objects, built as a testbed for the `pga`
library. It holds geometry and a scene model shared by two front-ends, and the encoders that a
scripted storyboard writes its frames through.

This file records the **current** design by subsystem: what was chosen, what was rejected, and what
the choice costs. A rejected alternative appears only where it is still a live trap. A figure stays
beside the constant it justified, because the comments in the source carry no figures (Article
VII.5). The `Pruned` row names the last commit that carried the pruned text.

**What is here.** The render-path-independent core sits under `src/rga_visualiser`. The browser
front-end sits under `src/browser`, its page under `pages/`, and its harness under `tools/drive/`.
The desktop front-end sits under `src/desktop`, with the PNG and GIF encoders and the arena they
write through. The suite runs in the configurations that Testing lists.

**The two front-ends are one to one.** The same input does the same thing on the page and on the
desktop. A value that decides what an input does lives once, in the core, and both front-ends read
it. Where each front-end must hold a handler of its own, each handler names the other, so a change
to one reaches both (Article II.9). That is intended, and not yet held for every input: Known
limitations names each gap.

**How claims are marked.** Each subsystem closes with a *Checked* block. *Verified* names the run
that established the claim. *Assumed* means that the claim rests on reasoning alone. A figure with
no *Verified* line beside it is unmeasured, and reads only as an estimate.

These tools of the prototype are not in this repository: `check_palette`, `check_atlas`,
`check_prose`, `check_columns`, `verify.sh` and `verify_touch_pan.js`. A claim one held says so.

**Verification practice.** Every change is rebuilt, and `koch test` runs the suite again. Both
front-ends are driven by `tools/build.nim drive`. **No human has driven either front-end, clicked a
button, or seen this on real GPU hardware.** Every figure here was software-rendered.

## Vocabulary

**The terms are the Architect's, in `GLOSSARY.md`, and the code says them.** Each glossary term
names one sense of an older word, and the other senses keep that word. An explicit list spares them,
rather than a rule.

`handle` names the address of an object, and `slot` still names an `Ink` palette position and a
timing array position. `pivot` names the orbit centre. `target` still names the object a press
points at, the DOM event target, a render target and a plain goal. `budget` names real allowances of
time, pixels and segments. The frame-rate lines are `mark`s, because nothing is held to them.

**Three names could not be taken, and each says why in place.** `object` is reserved in Nim, so the
code-position `item` took a role instead. It is `one` where an object is reached through the
accessor, and `saved` where a record is read out of a file. `handle` collides with
`typedthreads.handle` of the standard library, which wins over an injected local inside a template,
so `picking` turns on `openSym`. `iterator items` keeps its name, the protocol of Nim itself.

**Two spec keys must never be renamed, and neither would fail loudly.** `targets: "js"` is a
testament key, and renamed, the browser suite runs on the wrong backend. `visualiser.objects_max` is
a compile-time define named in the `matrix` of the small suite. A compile against it checks that the
constant and the define still meet.

**Nim compares names without case after the first letter, and without underscores**, so a module
variable `PREVIEW` would shadow the type `Preview`. The variables are `PREVIEW_EDIT` and
`PREVIEW_APPLY`.

**`horizon` stays the word of `pga`**, and has no entry here, because the vocabulary of the algebra
belongs to that library. An ideal object does not sit *at* the horizon. It lies *in* it, so the kind
words that a reader sees are `horizon point`, `horizon line` and `horizon plane`.

*Checked.* Verified after every rename: every suite is unchanged, case for case, so no behaviour
moved. `tsc` is clean after `bridge.d.ts` is derived again. `koch check-files` reports 0 findings,
and both front-ends are built and driven.

## Wording catalogue

**Every word that either front-end shows has one name in `wording.nim`, and neither writes a
literal.** Shown text written where it is drawn puts one sentence in two places, and two places
drift. The catalogue is a `Wording` enum and a table indexed by it, so a renamed key fails to
compile, rather than fails to match.

**The page fills its markup at build time, and not at load.** Its labels live in markup, not
TypeScript: 44 static text nodes against 6 from scripts. A script sets each tooltip. To set each
label from a script would empty 44 elements, invent 44 ids, and blank the page until scripts ran.

`tools/build.nim` rewrites `shell.html` on the way out for `@SCRIPT@` and `@EMBED:<face>@`, and
`@WORD:<key>@` joins that pass. The real text is in the committed markup, and reads at first paint
and with scripts refused. A token that names a key the catalogue does not carry stops the build.

**The guard is total, rather than a list of forbidden strings.** `checkWording` refuses a quoted
literal at every panel call that puts text in front of a reader. It refuses one at `.title`,
`.textContent` and `.innerHTML` in every browser script. A hidden Dear ImGui id (`##name`) and an
empty label are allowed, because neither one is shown. It also refuses a catalogue row that no
front-end names, so the catalogue cannot grow words written for nobody.

**The driver reads the catalogue as text, and imports none of it** (`tools/catalogue.nim`). The type
check runs `tools/build.nim` on koch's compiler, never on the pin of this project, so the driver
compiles no project code (#385). The read takes the whole enum, past its blank lines, and each row
with its literals joined by `&`. A suite test on the pin holds the read to the compiled enum and
table, so a moved key fails there. Rejected: an import of the catalogue, which compiled
`wording.nim` and `format.nim` on koch's compiler.

**One key for each control, and not one key for each word.** `NameRowHide` and `NamePickHide` both
read `hide`, and are two keys, because a translator may need them apart. So the law that no two keys
carry the same text holds over **prose** keys alone. Those are the tooltips and notes, where a
repeated sentence is a copy. Each word on a control is stripped, with no doubled space, no trailing
full stop, and at most `RUNES_LABEL_MOST` runes.

**Every control that both front-ends have is explained on both, from one key.** The page hangs the
`Tip` key of each control it has, set from scripts at load, because the markup carries no `title`.
The keys it does not hang belong to the window alone: its two file-path fields, its vsync switch,
its two arenas, and its scene block. The page row of that block reads a count over a capacity,
rather than the bytes that the sentence names. A control that the window explains and the page does
not is a gap to close, and not a design choice.

**The application names itself once.** `NameTitle` reads `RGA Visualiser`, and both front-ends take
it. The caption of the window is `captionWindow()`, which reads the catalogue. A law requires that
name to be title case, and every other label to stay a word.

**Help rows and outcome sentences are the catalogue's too.** A help cell is a `Help` key, the title
of a tab is a `NameTab` key, and its line is a `NoteTab` key. `help.nim` holds which cell sits in
which row, and nothing that a reader sees. A cell is read across its row. So it carries its own law:
no capital opens it, no full stop closes it, and no two say one thing.

A row that names a button or a key composes it through the funcs of the catalogue (`withButton`,
`namesJoined`, `sectionNamed`, `wheelWordsTaught`). That glue is the catalogue's as much as the
words are. The menu tab names each button by the key of the button, so a renamed button is renamed
in its row. Outcome sentences are composed here as well, `derivedMessage` among them, and
`message.nim` keeps how long an outcome stands. The guard sweeps `help.nim` for any quoted letter,
because a word quoted there is a copy that the catalogue cannot see.

Not here: the words of the algebra itself. Those are the operation names and notation of `pga`, kind
words, and key and button names. Help composes with them, and copies none.

*Checked.* Verified by build and by driven check. `nim r tools/build.nim declare` reports how many
wording keys it reads. A literal put back at a label call is refused, and so is a key named only
inside the catalogue. A `@WORD:` token that names an absent key fails the build, and names its line.

Verified by `suites.nim`: the read of the catalogue as text names every key in order. It reads the
words of every row as the compiled catalogue holds them. On koch's compiler, `nim check` of the
driver reaches no module under `src/`.

## Driven checks

**Suites test rules, and this layer tests wiring.** Nothing in the suite presses a key, turns a
wheel, or puts two fingers on the canvas. So nothing in it catches a rule wired to the wrong event.
`tools/drive/` does, through Playwright, against the page that `tools/build.nim web` assembles. `nim
r tools/build.nim drive` runs both front-ends.

**Every check passes**, with one module for each section of what the page does. `drive` counts them,
and this file does not:

| Module | Covers |
|--------|--------|
| `keys`, `wheel`, `pan` | held keys, wheel zoom, mouse pan, what zoom settles onto |
| `touch`, `construct`, `finger` | pinch, long press, drag construction, crowd, paused drag |
| `apply`, `framing`, `label`, `view` | pickers, what picking does to camera, names, view section |
| `chrome`, `comet`, `ground` | hover during gesture, help, horizon comet, lattice's reach |
| `frame`, `classified`, `diagnostics`, `ramp` | frame's own clocks and counts, tree, colours |
| `exceedance`, `rings` | distribution curve, its axis, rings each reading is taken over |
| `scenery`, `pins`, `built`, `pool` | what scene costs, repaired faults, each frame built, drawer |
| `demo`, `loaded`, `objects` | preset, culling, occlusion, a line through a point, loaded |
| `message`, `style`, `type`, `canvas` | outcome fade, declared CSS, faces in roles, blank refused |
| `host`, `shade` | save through the artifact host, every point shaded from world-up |
| `surface` | no backdrop filter on the page, and the fill of every surface |
| `veil` | the veil of a plane over every spot its pick finds it at |
| `clock` | simulated time that correctness checks run on |

**Accounting allows two frames of its sample to miss, as a count rather than a share.**
`ceil(0.995n)` equals `n` for every `n` under 200, so a share demands every frame of the 49-frame
sample of `loaded`. One definition is exported from `scenery` (repository issue 47). The scenery
check takes the same allowance. Preemption inside its bracket and outside both halves missed one
frame of 109, of 126 and of 127. Per-frame tolerances stay as they are, because a real accounting
fault misses on every frame.

**Count the mechanism that the claim names.** The cadence check of the diagnostics section counts
`askSlowPass`, the entry of the tick, where asks are `ceil(ticks/5)`. It does not count calls to
`drawExceedance`, which the axis switch and the gliding axis reach too. Their count differs between
runs of the same code. Verified by a break on purpose, 2026-09-13: four axis presses in the window.

**The tick check of the diagnostics tree counts the writes that repeat the text of a row.**
`writeText` skips those writes, so a correct tick makes none, whatever the load. The check wants
none, the same row elements after the ticks as before, and one write at least. On the simulated
clock no timing row moves. So the check removes an object halfway through and undoes it after, which
moves the count of the pool row. Verified by a break on purpose: a `writeText` that writes on every
call fails, with 153 of 210 writes repeated.

The same check does not bound how many rows move in one tick. On the real clock that counts the
timing figures that changed in 200 ms, which moves with load and with what the page does. Rejected:
a bound of 20, which read 21 once from code equal to `main` (repository issue 304).

**Waits are conditions that the page reports, and not spans of clock.** Camera ease and settling
after a click are `waitUntil` over what the page says: `settleCamera`, `settleCount`,
`settleSelection`, `settleDrawer`, `settleHelp`, `settleBranch` and `settleReading`. Pacing inside a
drag loop is `waitFrames`. A span that is itself the measurement is `advance`, in the time of the
page, and it says so at its site. How long a finger rests is one such span, and how long an absence
is watched is another.

`settleReading` waits on `ms_refresh_ui`, the clock of the tick itself. It never waits on a row that
the tick writes, or the wait would assert what the check goes on to ask. A demo that loads is
settled when a frame reports every object grown in (`FrameData.is_grown`), because the load staggers
the births of its objects.

**Settle on what moves, and not on what has stopped changing.** Two polls of an unmoving stance
agree before an ease has begun. So `settleCamera` asks the ease: `nimCameraCarrying` reports
`goal.isSome and not is_arrived`. It waits one draw first, because that draw arms it (repository
issue 73). Verified by a break on purpose: return at once, and every loss is framing. The horizon
label check places only stances that the frame rule holds, and asserts that the eye stays.

**A step that has to land inside an ease is taken by the page, and not across the protocol.** The
group-turn check arms a watcher before the tap goes out, and the watcher turns in the first frame
whose ease carries. Its frame callback follows that of the page, so it reads the build that armed
the ease, before `advance` moves the pivot. Verified by a break on purpose: an `abandon` that stops
the ease outright fails, with the pivot 1.5000 from the middle (repository issue 315).

**Pixels are read through the compositor, and a reading that carries no picture is refused.** The
context keeps no drawing buffer, as `gl.ts` says, so `readPixels` is sound only inside the frame
that drew. Checks that compare two such readings pass on a canvas that reads all zero. The reading
is `page.locator('#gl').screenshot()`, decoded in the page by one `tools/drive/canvas.ts`. It raises
rather than reports: a canvas that nobody can read is the instrument lost.

**Refusal is of one colour, and not of black.** The runner has answered a sheet of white as readily
as one of zero, so the fixture drives both. Every sibling of the canvas is hidden by `opacity` for
the capture. The reading is taken again until it carries a picture, up to ten times. To hide chrome
forces a recomposite that a software rasteriser does not finish inside one frame. That costs about
0.49 s for each reading, and the veil check alone takes eight.

**Unexplained**: why the runner read blank through `readPixels` and white through the compositor,
which neither Chromium here reproduces.

**The veil check holds the veil of a plane to the pick of that plane.** `driveVeilCovers` hides
every object but the ground, and reads spots 15 px apart from four views: low, rolled, steep, and
from underneath. In each view the eye stands inside the radius of the disc, so only the vanishing
line can stop the box of the veil. Where the pick of the page finds the plane, the veil must change
the spot by 8 or more over red, green and blue. A spot counts only where the canvas without the
plane shows bare backdrop. A world axis in front of the veil hides it with no fault of the veil.

Rejected: spots of one reading compared with each other, which pass on a canvas with no veil. Cost:
eight readings, about 6 s of the drive. Verified by a break on purpose, 2026-10-04, on the page
without antialias. With the veil draws skipped, the low view read 4 of 1878 spots veiled. With the
floor of the box halfway between the vanishing line and the centre of the disc, it read 1677
of 1878. The steep view passed that break, because the line stands far off it.

**The disc check holds the disc of the ecliptic under a camera that stands inside it.**
`driveDiscUnderfoot` puts the eye 1.5 units off Sol over the largest demo, 0.3 rad up and then
0.0003 rad up. It reads one spot past Sol and three under the camera, with the ecliptic shown and
again hidden. Each spot under the camera must read within 3 of the spot past Sol in luminance, so
that the disc ends at no chord. Each spot must also change by `LIFT_LEAST` or more against the
canvas without the plane, so that the disc is drawn at all. Every other object stays shown, because
the spots stand clear of the dots and the axes of the demo.

The veil check reads no eye that grazes a plane, and no depth range as wide as that of the demo.
Rejected: the spots of one reading alone, which agree with each other where no disc is drawn.
Verified by a break on purpose, 2026-10-04, with the disc draws skipped in `gl.ts`: each spot moved
by 0, and both claims failed. The spots of one reading alone passed that break, each at a luminance
of 36.1. That is the dome of the horizon plane that the disc blends over. On the page as it is, the
disc moves each spot by 23.

Cost: two more readings. Timed alone on this machine, 2026-10-04, the check took 3.1 s and 5.0 s,
against 2.5 s and 3.1 s for one reading alone.

**The harness resolves its own browser, and drives the pinned build of Playwright by default.** It
takes what `RGA_CHROMIUM` names, else the build that `package-lock.json` pins, else `chromium` on
`PATH`. On Ubuntu 24.04 that last one is the snap shim alone (repository issue 77). The lock fixes
`@playwright/test` at 1.63.0, and that fixes the browser revision, so this machine and the runner
drive one binary. `check.yml` caches `~/.cache/ms-playwright` on that same lock. The pin is a
version and not a digest, because Playwright publishes no checksum.

**TypeScript rather than Nim, argued rather than assumed.** The calls of the harness are mostly
`page.evaluate` bodies that name the exports of the bridge, which `build/bridge.d.ts` types. Through
the foreign-function glue of Nim each one is an unchecked string (repository issue 48). Page-script
names that the harness drives are declared by hand in `tools/drive/page.d.ts`, so to rename one
breaks the harness rather than the page.

**A dropped CSS declaration is invisible to the CSSOM, so the check reads authored text.** A parser
discards a declaration whose property it does not know, so a sweep over `cssRules` passes on the
very page the check exists for. `driveStyleDeclared` scans the `textContent` of the `<style>`
element, and asks the browser whether it knows each property name. A fixture asks whether it can
tell `align-items` from `align-objects`.

**The heading checks hold geometry, paint and shape separately.** `driveHeaderPinned` sweeps
`elementFromPoint` across the full band width, because the midline alone passed while rows showed in
a 28 px strip. `driveHeaderBanded` reads the computed fill *opacity* of every heading, at rest and
pinned, rather than a notation, because a `color-mix` fill computes to `color(srgb …)`.
`driveHeaderStyled` compares radius and border against `.toggles`, and not against `.brand`, which
takes an accent border whenever the drawer is open.

**The list is held to a window, and never to a fill.** `driveListWindowed` shuts and opens the
objects section again. The rows standing before the click returns stand for every object, and number
no more than three screens of 40 px rows. That is loose where it must be, and still tens against
thousands. It then scrolls to either end, and finds that end's row on screen within the same bound.

The bound is stated in the check and in the page. A check that reads the window out of the page
passes whatever the page does. Time is never asserted, and on the simulated clock it reads 0 ms. The
count of rows standing, 27 for 5,040 objects, holds on every machine. `driveEditFromMenu` opens the
drawer onto the 41st object created, near the end of the list. It reads that row as standing before
the call returns, under the pinned heading, with its whole form above the floor of the scroller.

**A touch id is never reused across gestures.** Every gesture starts by asking the page whether any
pointer is still down. The page keys live pointers by id. So an id reused from the gesture before
silently overwrites a finger left standing by a dropped or reordered lift. The pair that the page
reads is then not the pair the harness sent. That is the one mechanism found for a two-finger pan
reading as a pinch (repository issues 153 and 154).

A fresh id for each finger leaves a stale one standing where the guard names it. The check of the
gesture then fails on it. The guard reads events that the browser delivered, through a listener that
the harness installs on `window`, and never the bookkeeping of the page. So the surface of the page
is not widened for a test, and what is asserted is what the page received. It is silent when clean,
and reports the stale ids when not. One positive check stands before the pan, which follows a tap.

**The check of the chip row asserts reach beside fit.** `driveChipRowFits` requires exactly two
toggles wherever they stand, beside zero overflow, because a row that fits by dropping two controls
is broken more quietly. It sweeps 396, 395 and 394, because a rule written one pixel out passes
every sweep that never lands on it.

*Checked.* Verified by a run. Every check goes through `tools/build.nim drive`, on both front-ends,
software-rendered, here and on the runner. `drive` gates `summarize`, so a green push run is the
word of the runner itself (repository issues 47 and 91). **Unmeasured**: the speed readings are
those of SwiftShader on these machines, and say nothing of any GPU.

## Clocks of the driven checks

**Correctness checks run on a simulated clock, and only speed and instrument checks read the real
one** (Article IX.12). `clock.ts` installs the clock of Playwright, paused, before the page loads.
Timers, animation frames, idle callbacks and `performance.now` then move only when a check moves
them. `advance` moves a span, `advanceFrames` moves frames, and `waitUntil` steps one frame at a
time until a condition holds. A slow machine takes longer in real time to reach a verdict, and never
reaches another one (repository issue 329).

**The host-save check runs on the simulated clock too, on a page of its own.** The stand-in host
must stand before the script of the page runs. `simulateClock` puts its page on the simulated clock,
and its waits are frames. Verified by a run, 2026-10-02: its checks pass on the simulated page, and
the page raises no error.

Three things that the clock does not reach are set on the simulated page:

- The style engine runs CSS transitions on real time. `hastenTransitions` runs its timeline 10,000
  times fast, so no check waits on real time to see a transition end.
- The idle callback of Playwright grants no time, so the slow pass of the diagnostics tree would
  wait for ever. The page is granted 50 ms, the longest idle period that a browser grants.
- A page function that waits on its timers runs through `evaluateOver`. The clock moves a fixed span
  that covers its waits, and yields to the page between timers, so each await resolves in order.

**The simulated page draws without antialias.** `driveSimulated` sets `should_antialias` to false by
an init script, before the page loads. `gl.ts` reads that switch before it asks for its context, and
asks to antialias wherever the switch is absent. So the page of the reader, the real-clock page and
the host page antialias, and the speed checks time what the reader runs. No verdict on the simulated
page reads the sample of an edge. `driveAntialias` reads what each context granted: false on the
simulated page, and true on the real-clock page.

Rejected: antialias off on every driven page, which would time a page that no reader runs. The bench
of Records and shaders measured the cost at the opening scene on 2026-10-04. Without antialias, GPU
work for each frame step fell from 18.1 to 10.0 ms, and from 18.0 to 12.1 ms. The simulated page is
bound by GPU work under SwiftShader, and a frame step costs whole display frames. So a saving shows
in the drive only where it takes a step under the next display frame. Records and shaders gives the
time of the browser drive and of each page.

**Speed checks, and checks of the timing readouts of the page, run on a second page, on the real
clock.** On the simulated clock every timing row reads zero, and arithmetic over zeros passes. So
`driveMeasured` holds them, on a page of its own. Its samples are counts of frames rather than spans
of time. Their size is then the same on every machine, and only the figures move with speed.

The heap row reads `NaN` on the simulated page, because the clock stands in for `performance`. So
`driveHeapUnit` reads that row on the second page too.

**Every wait on the real page is a count of frames, and never a span of time.** `waitUntil` steps
that page one frame at a time. `settleTurn` waits on the transitions that an element runs, as
`getAnimations` lists them. No limit on time then decides a verdict (Article IX.12). Rejected: a
limit of time as a fallback, which a loaded machine meets with no page fault. Verified by a run,
2026-10-02: the heap row and the tree checks pass on the real page with these waits.

**A speed bound is 1.5 times the slowest reading on a delegate, rounded up to two figures.** Runners
and delegates meet it, and each fault that a bound pins reads over it. A fault reads as `pins.ts`
recorded it on a delegate on 2026-09-07, under the figure that the check took then.

Delegate readings are from 20 or 21 runs of the drive on one delegate, from 2026-09-28 to
2026-09-30, alone and in the gate. The anchor readings are from 11 runs of the measured page up to
its pins, on 2026-09-30. The marker readings are from 11 such runs on 2026-10-04, with each outline
shaped once for each pair (Marker pulse). Runner readings are from one CI run of the change that set
each bound. The runner reading of the marker is from the drive job on `d305c68c`.

The still frame, the moving frame and the frame after an edit read a full build in every frame
(Render paths). Those rows are from 20 runs of the measured page on one delegate, on 2026-10-05, in
the lock of the gate. They carry no runner reading. One run of the 20 is left out. It read the
anchor at 23.5 µs and the loaded pick at 7.4 ms, each over its bound. That is load, not a fault.

In 10 runs of `a1702384` beside them, frames that held their scene read 0.4 to 0.5 ms still. After
an edit they read 1.5 to 2.4 ms.

| Check | Bound | Runner | Delegates | Fault |
|-------|-------|--------|-----------|-------|
| Still frame, median | 2.1 ms | | 0.7 to 1.4 | |
| Still frame, slowest tenth | 3.2 ms | | 1.0 to 2.1 | |
| Moving frame, median | 3 ms | | 1.3 to 2.0 | |
| Hover pick | 2.6 ms | 0.1 | 0.2 to 1.7 | 7.1 |
| Anchor lookup | 15 µs | 5.0 | 7.0 to 10.0 | 280 |
| Marker and its pulse, worst kind | 1.1 ms | 0.38 | 0.34 to 0.70 | 3.2 |
| Moving grid, median | 26 ms | 4.3 | 6.3 to 17.1 | 26.1 |
| CPU emit, median | 2 ms | 0.3 | 0.3 to 1.3 | 6.3 |
| Edit past the timeline capacity, at 5,038 | 9.6 ms | 1.7 | 1.7 to 6.4 | |
| Frame after an edit, at 5,038 | 31 ms | | 8.4 to 20.2 | |
| Hover pick, at 5,038 | 7.2 ms | 1.9 | 1.2 to 4.8 | |

The marker fault read 3.2 ms against 1.2 ms repaired, both with each outline shaped twice, so it
costs 2.7 times the repair. Assumed: the ratio holds where the check shapes each outline once. The
fault then reads 0.91 ms at least on a delegate, and 1.0 ms on the runner, both under the bound. So
the bound holds that fault only where the repair reads 0.42 ms or more: 9 of the 11 delegate runs.
The point count of the marker suite holds it on every run (Selection and markers).

The moving grid fault reads over its bound by 0.1 ms only. A check with no fault reading pins a
budget rather than a repair.

**A fault that reads close to its speed bound is pinned by a count too.** A count reads the same on
every machine, and load never moves it. The marker suite counts the points that each marker reads
out of the algebra (Selection and markers). `driveGround` counts the lines that the records of the
lattice lie on (Geometry and drawing). `driveMarkerShapedOnce` counts the outlines that the overlay
shapes for each marker it draws (Marker pulse).

Each bound stays at 1.5 times beside its count, so a slowdown that no count names still fails.
Rejected: bounds at 3 times beside the counts, which pass such a slowdown.

The slowest delegate reads 1.7 to 4.3 times the runner, by a factor that changes with the check. The
hover pick reads 17 times, because its runner reading is one 100 µs tick of the clock of the page. A
regression that stays under a bound on the runner shows first on a delegate, which runs the gate
before every push. Rejected: bounds scaled by a reference workload timed in the same run. The checks
scale unlike each other between machines, so no one reference normalises them all.

**A pin that times a call too short to time alone takes the median of batches, a frame apart.** The
clock of the page ticks in steps of 100 µs, so a call of a few microseconds is timed in hundreds.
One mean of 400 anchor lookups read 5.75 to 32 µs on one fresh page, and the first was dearest.
After an untimed batch, the median of 15 batches of 200 read 6.0 to 7.0 µs in 12 trials. A
collection or a preemption then spoils one batch, not the figure.

The marker takes the same figure. Its worst mean of 30 pairs read 0.46 to 1.67 ms over 4 pages. Its
worst median of 9 batches of 5 read 0.48 to 0.62 ms. Both were measured with each outline shaped
twice.

**Sustained load moves a median too.** On 2026-09-30, with three of four cores kept busy, 10 runs of
the measured page read the anchor at 7.0 to 14.5 µs. Each check but the marker stayed inside its
bound. Ten such runs on 2026-10-04, with each outline shaped once, read the marker at 0.34 to 0.78
ms, inside its bound. The gate runs projects one at a time, so no gate run puts that load beside the
drive. A delegate that shares its cores with other tenants can still.

**A delegate can read a speed check over its bound with no fault present.** With each outline shaped
twice, nine pages on a fresh delegate read the marker at 0.72 to 2.64 ms, over a bound of 1.7 ms.
They ran on 2026-10-01, and read the grid at 6.4 to 22.3 ms. Six pages ran the read tally of
`boundary`, and three ran the build without it, over the same range. The 2.64 ms was the first page
after a build. The counts hold each fault whatever the clock reads.

**The rendering step of the browser runs on real frames, so each simulated frame waits for one.**
Resize, scroll, media-query and resize-observer events fire in that step, whatever the clock says.
Without the wait, a viewport change reached the page at any point of the frames after it. The sweep
of the chip row read its toggles in the row at 394 px on one run, and in the menu on the next.
`runSpan` lets one real rendering step run before each simulated frame. What the last action or
frame set off then reaches the page first, in the same order on every machine.

**A touch is waited on until the page holds the fingers where the harness put them.** The protocol
answers before the page sees a touch move, which the browser holds for its next real frame. Without
the wait, the same pinch zoomed to 8.41 in four fresh pages and to 7.62 in the fifth. `touchAt` asks
the page where it holds each finger, and time moves only when the answer matches. It compares places
and not counts, because two fingers put down together arrive as two starts. The mouse of Playwright
waits already.

**A move inside the touch slop of the browser never arrives, so that wait ends after three real
rendering steps.** A move of 3, 8 or 14 px from where the finger went down was dropped, and one of
16 or 30 px arrived. Every move past the slop reached the page at the simulated moment it was sent,
in 3 runs of 3. The pinch then read 7.62 in 15 fresh pages of 15, 5 of them with three cores busy.

**Every window that the curve checks feed is drawn from a seeded generator**, Mulberry32 from
`SEED_WINDOW`. The reach of the curve and the extent of the axis are then the same on every run.

*Checked.* Verified by a run, 2026-09-30: two drives side by side on one delegate print the same
lines for the simulated page. Each loads the other, and the lines agree in every figure. Without the
rendering step, the touch wait and the seed, two runs of the same code differ in their figures, and
their verdicts agree.

## Browser front-end

**The page is one self-contained file.** It opens from `file://`, or from an artefact host that
reaches no font host and no script host. So every face is inlined as base64, and `tools/build.nim
web` concatenates every script into `pages/shell.html` at its `@SCRIPT@` token. `pages/shell.html`
stays whole markup, rather than ends mid-`<script>`, because a committed page that cannot parse
alone is a page that no checker can read.

**Scripts share one global scope, rather than import each other.** TypeScript 7 removed `outFile`,
so the compiler does not bundle, and the page cannot resolve ES imports without a server. Files
carry no top-level `import` or `export`. `SCRIPTS` in `tools/build.nim` is the order they
concatenate in, which is load-bearing, because `const` is not hoisted. Rejected: a bundler, which is
a second toolchain for one concatenation this build already does.

**Article II.9 is the boundary that matters.** `src/browser/bridge.nim` computes every join, meet,
pick, drag and camera move, compiled from the same modules that the desktop draws through.
TypeScript owns WebGL, DOM and pointer events alone. Each script argues for itself in its header, on
the phrase `not Nim because`, which `justification.nim` demands of a gated kind.

**The declarations of the bridge are derived, and never kept beside it.** `tools/declarations.nim`
reads the `{.exportc.}` signatures of the bridge, and `tools/build.nim declare` writes them to
`build/bridge.d.ts`, with every parameter required (Marker pulse). `types` is `declare` and both
type-checker configurations, and `web` and `drive` both call it. Verified by a break on purpose: to
rename `nimSceneHandles` alone fails `types`.

**A parameter with a literal default takes its type from the literal**, as `is_tally_skipped =
false` shows, because such a parameter states no type (Article X.12). A parameter that the reading
cannot type leaves no declaration, so each call to that export fails `types`. A declaration one
parameter short would let the page leave that argument out, and pass `undefined`. Verified by
`suites.nim`: every parameter reaches its declaration, one whose literal fixes its type included.

**Type-checking runs under `strict`, `noUncheckedIndexedAccess` and `exactOptionalPropertyTypes`**,
as CONTRIBUTOR.md requires, so indexing reports absence. The flat buffers of the bridge are read
through `flatAt` and `pointAt`, and every walk is bounded by the count of its buffer. `elementById`
fails loudly for markup this build ships, and `elementIfPresent` reports an optional one absent.

**Node dependencies are pinned, and their checkout is not committed.** `package.json` and
`package-lock.json` are committed, and `node_modules/` is ignored. `typescript` 7.0.2 and
`@playwright/test` 1.63.0 are Microsoft's, both Apache-2.0. `@types/node` 22.20.2 is
DefinitelyTyped's, MIT, and it types the Node surface that `tools/build.nim` and the harness reach.
Each licence is read off the package.

**System packages are declared as data in the build driver.** `PACKAGES_SYSTEM` in `tools/build.nim`
pairs each package with what it is for, and `system` prints those names for the caller to install
(repository issue 60). No package version is pinned or invented.

**The chip row floats over the canvas, and its width budget is measured.** Six controls ride the
flex row, so where it stops fitting, the controls inside it give. Each of two breakpoints is swept a
pixel at a time. Below **497 px** the brand draws `NameChipDrawer` in place of its name, at 123 px
wide at 497, and 34 at 496. Below **395 px** `.toggles` moves into the menu popover, under its own
`show` heading: 1 px over at 394, 75 at 320. It is moved rather than copied, because a second pair
of buttons is a second `on` state to keep in step with the scene.

`#top-menu-show[hidden]` spells out `display: none`, because an author `display` beats the
user-agent rule for the attribute.

**The heading of a section holds its place while the list of that section scrolls under it.** That
is `position: sticky; top: 0` against `.drawer-scroll`. The clearance that the floating row needs
sits on `.drawer`, outside what scrolls, because the padding of its own scroller insets a sticky
offset. The heading wears the pill of the chip row at rest and pinned alike, so a list moving and a
list still show one heading. That pill has the same radius, the same 1 px `--border`, and the box
that `.object-row.selected` uses. The desktop bar is filled throughout.

The fill of the heading is **opaque**, because a heading asked to hide rows cannot be seen through.
It is the ground of the drawer, `color-mix(in srgb, rgb(22 27 34) 88%, var(--bg))`, and `gl.ts`
writes `--bg` at runtime from the clear colour, since a named tone drifts. Rejected: a band only
while pinned, watched through a sentinel and an `IntersectionObserver`. Rejected: a shadow, which
made pinning read as floating. Rejected: a rule under a section, which stood as a residual line over
the next pill at rest.

The box is **square**, with `.section-header::before` drawing the pill over it. A radius clips the
fill it rounds, and leaves four corners bare for rows. The box takes `border: 0`, or the border of
the button stands. Rejected: a backing inside the box, because `position: sticky` opens a stacking
context whatever its `z-index`, so a negative child paints over its own border.

**Only the rows near the viewport exist.** The list is a window over its keys. Two spacers stand in
for the rows above and below, at the heights those rows measured, or 61 px until they have. The
window covers the height of the scroller, plus one screen either side.

A scroll marks the window stale, and the frame loop settles it after the writes of the tick. So the
cost lands in the `ui` phase, and the layout that its reads force serves the tick too. A refresh
renders at once, so a caller that changed the scene finds its row standing before the call returns.
Keys are rebuilt only when the revision of the scene, its count, or the composing row moves. A
refresh on selection alone then keeps five thousand keys as they stand.

A `ResizeObserver` reads heights, and never inside the scroll path, which also catches a row that
changes size without a rebuild. Cost: a row that leaves the window is built again on its return, at
about 0.15 ms each. A row above the viewport is an estimate until it is scrolled to, which the
scroll anchoring of the browser absorbs. The spacers are `overflow-anchor: none`, so the anchor is
always a row. A jump to an estimated offset, with nothing but a spacer in view, adjusts nothing.

The window opens in 3 ms with 27 rows, and the page then carries about 750 elements, 250 of them in
the list. To scroll it at 300 px a frame builds about five rows a frame, for 0.8 ms of the `ui`
phase. The frame moves from 59 to 62 ms. Rejected: a time-sliced build of every row, which at 5,038
objects is 2,862 ms across 33 frames of 80 ms, with 45,813 elements standing after. Rejected:
`content-visibility: auto` over every row, which skips their layout and not their building.

**The chrome over the scene is partly transparent, with no blur, by instruction of the Architect.**
The brand and toggle pills, the help button and the drawer each fill with `--surface`, which is
`rgba(22, 27, 34, 0.88)`. Detail of the scene behind a surface then shows at 12% of its contrast.
The headings and the search row of the drawer are opaque, and mix the same tone at the same weight
over `--bg`. The toggle segment of the desktop takes the same tone and alpha. Rejected: 0.82, or any
larger step, because the Architect asked for a fill a tiny bit more opaque than 0.82.

Rejected: a backdrop blur, which at 5,038 objects with the drawer open added one frame of the
display. Paced to the display, a frame took 50.0 ms with it and 33.3 ms without it, in each of four
rounds. That was Chromium with SwiftShader in the Claude Code cloud container, on 2026-10-04.

Verified by driven check: `driveSurfacesFilled` finds no backdrop filter on any rule or element, and
each surface computes alpha 0.88. It reads each opaque band over white, where one percent of weight
moves red by two levels. Each band must match the drawer's fill there, within half a level. Verified
by a break on purpose, 2026-10-05: a band at 87% fails, and so does a blur on `.toggles`.

Verified by eye in Chrome for Testing 153 with SwiftShader, 2026-10-05. The pictures show the drawer
over the largest demo and the opening scene, each at 0.82, 0.88 and 0.92. At 0.88 the lines of the
demo show faintly through the drawer, and every row stays legible. Nothing stands behind the pills
of the opening scene, so there 0.82 and 0.88 look the same. To take the pictures again, run `nim r
tools/build.nim web`, and open `build/rga_visualiser.html` at 1200 by 900 px. Then load the largest
demo from the menu, and open the drawer.

**A comment may not quote a closing block-comment delimiter.** A comment that does ends itself on
the spot, and the prose after it parses as CSS. That can swallow 141 of the 150 rules of the page,
with the page still drawing. Delimiters are named rather than quoted.

**On an artefact host, a file saves through the host's own save.** The claude.ai viewer never lets
frame code download directly, and offers `claude.use("downloads")` instead. `deliverFile` tries it
first where the host answered at load, and the reader confirms the file. A reader's "no", or a
prompt already open, ends the save, and any other refusal falls through to the page's own routes.

**A scene goes to the host as `scene.zip`, which holds `scene.rgascene` unchanged and stored.** The
host saves only the extensions on its list, and `.rgascene` is not one. Loading opens the first
`.rgascene` entry of a zip, stored or deflated. Rejected: a JSON scene, a second format to read.

*Checked.* Verified by a cold run. `clean` removes `build`, `binaries` and `nimcache`. Then `drive`
fetches every face, builds both front-ends, and drives them with no step run by hand, as the runner
does. A second run fetches nothing.

Verified by type-checker: every script is clean under the three flags above, with no `any` and no
non-null assertion. Verified by driven check: `driveTypeRoles`, `driveTypeDrawn` and
`driveTypeLigatures`.

Verified by driven check against a stand-in host: a scene saves as a zip and loads back, and a PNG
saves as itself. A declined save offers no link. Verified by `unzip -t`: the zip is sound.
**Untested**: the real host. **Unverified**: no human has driven this page.

## Faces

**`drive` fetches faces, and `web` refuses without them**, because a caller who reaches for `web`
directly is building, rather than being given.

**Faces come from the store of the repository, and which faces is this project's.** `koch
fetch-assets` holds any file fetched at build time: the names, the digests and the fetch, in
`curator/audit/src/assets.nim`. The `assets` verb of this project copies the faces of both
front-ends out of it (repository issues 116 and 124). It writes `build/fonts/store.list`, one line
for each face, naming the store entry it was copied from. `web` compares its input against that
entry before it embeds. Verified by a break of it, twice: `store.list` moved away, and one byte
appended to a copied face.

The page takes Commit Mono as the Latin `woff2` of `@fontsource`. It takes Noto Sans at 400 and 600,
Noto Sans Math, Noto Sans Symbols 2 and Noto Serif, as TrueType from their own releases. The desktop
takes its own list, `FACES_DESKTOP`, and the two lists share files. Commit Mono is `otf` there,
which is what its author publishes, and `stb_truetype` reads its CFF outlines. All are under the SIL
Open Font License 1.1.

**Three faces, three roles, and nothing else picks between them.** The standard of the Architect is
Noto Serif for titles, Noto Sans for body, and Commit Mono for code and monospace. The page draws
them through `--serif`, `--sans` and `--mono`, and the desktop through `guiHeader` and `guiMonoPush`
with `guiMonoPop`. Material 3 puts text inside components in the label role, so the help tab strip
and the toggle chips stay sans. The serif takes the headings that name a section, and the name of
the application itself.

**Commit Mono splits its ligatures across two switches, and the page needs both.** The distributed
`woff2` carries `calt`, which browsers apply unasked, and which most ligatures ride on. The opt-in
sets are `ss01` to `ss05`, which the arrows and comparisons come from. So the stylesheet says
`font-variant-ligatures: common-ligatures contextual`, because a reset that writes `none` takes
`calt` with it. It says `font-feature-settings: "ss01" 1, "ss02" 1` to ask for what is never on.

No combination moves a column. Noto Sans Math publishes an `ss01` that the mono stack falls through
to, and the operators render the same either way.

**Each Noto face of the page ships whole** (Article X.8, as the Architect ruled it on 2026-10-03). A
Latin subset leaves each character past its range to a face of the viewer's system. `ˍ` and `˷` of
the notation are two (repository issue 411). The cost is weight: the built page is 7,830,702 bytes,
against 4,271,072 with the subsets. Measured on 2026-10-03 with `ls -l build/rga_visualiser.html`,
at `main` and at this change. Rejected: a Noto Sans subset cut for the two accents, which no store
row hosts without a release.

**The maths and symbol faces each take a family of their own, after the text faces in every stack.**
Within one family, the faces that declare one weight form a set. The engine picks one set for the
weight asked, and asks only its faces. The order of a stack is then the precedence, as merge order
is in the desktop atlas. Rejected: those faces under "Noto Sans UI", whose set at 400 to 600 wins
both weights from the text faces. Liberation Sans then draws 1,156 glyphs of the open drawer.

Rejected: each of them declared again at 400 and at 600, which embeds each file twice, 1,744,560
bytes more on a page of 7,718,414.

**The maths and symbol faces are declared over 400 to 600.** Each ships one weight. Declared at 400
alone, they match no semibold text, so a selected label or chip at 600 takes its operators from the
system. Cost: regular operators beside semibold letters, which the desktop label also draws.

**Each face is held to its own load status**, by `driveTypeRoles`, because `document.fonts.check`
answers true where no face matches at all. Verified by a run, 2026-10-07, in Chrome for Testing 153:
all six faces load. A read of `CSS.getPlatformFontsForNode` over every element of the open drawer
finds no glyph from a face of the system. Noto Sans draws 946 glyphs and its semibold 204.

**Each element is held to the faces of the stack that the browser resolves for it**, by
`driveFacesCovered` (`CONTRIBUTOR.md`, Pages and assets). The check reads the computed `font-family`
and `font-weight` of each element, and holds its text to that stack, at that weight. The value and
the placeholder of a field count, and so does the text of `::before` and `::after`. A finding names
the page, the element, the weight and each codepoint that no face of the stack maps.

**Text that a script writes later is held to every stack in use, and to every stack that a rule
declares.** `nimCodepointsShown` gives the catalogue, the help, the notation and the units, as
`--drive-faces` reads them. The strings of the scripts and the text on the page join them. The check
holds each of these characters to each stack that an element resolves to, and to each stack that a
rule declares. It does so at each weight that an element resolves to, that a rule declares, and that
a face declares. A finding for a stack that no element resolves to names the rule by its selector,
as `rule .later-panel`.

**The check reads the declared stacks through the CSSOM, and the browser resolves each one.** It
walks every rule of every sheet, into `@media`, `@supports`, `@layer`, nested rules and imported
sheets, whether or not the rule matches now. The declarations of each rule go on a probe under a
hidden holder, so the browser itself resolves `var()` and the `font` shorthand. It resolves them
against the document as it stands, and again under the custom properties of each rule that declares
some. It leaves out an `@font-face` rule, which names a face and not a stack. It leaves out a family
of `inherit` or `unset`, which takes the stack of its parent.

Rejected: `var()` read from the custom properties of the root, which misses a value that a rule
under `@media` declares.

So each stack in use, and each stack that a rule declares, must map every character that the page
can write. That is why every stack names the maths and symbol families after its own faces. The cost
is that a stack for titles alone must map the operators too. A checkbox and a file field show no
text that the page writes, so they are not a stack in use. Both resolve to Arial, and the button of
a file field shows the words of the browser.

The check reads each `@font-face` rule of the shell, and the `cmap` of its file. Within a family, it
picks the set of faces that declare the weight asked, as the engine does. Where two sets hold that
weight, the pick is the engine's own. A character counts only where each set, or a family after it,
draws it, and the families of a stack are tried in order. Rejected: the three stacks read from the
text of the shell, which pass an element that takes a stack of its own. Rejected:
`CSS.getPlatformFontsForNode`, which answers only for text that has a layout box now.

Cost: a stack that no rule declares counts only where an element resolves to it at the check. Such a
stack is that of a form control, or a family that a script sets. A bare button resolves to Arial,
and a bare text area to monospace. Verified by a run, 2026-10-04, in Chrome for Testing 153: each
button and field that a script builds matches a rule that declares a stack. Verified by a read of
`src/browser` and the shell, the same day: no script sets a family.

*Checked.* Verified by a run of the check alone, 2026-10-04, in Chrome for Testing 153, with the
drawer and help open: both checks pass, with `missing none`. The stacks that the rules declare are
the stacks in use. Verified by breaks on purpose, the same day and the same way:

- `#button-menu span { font-family: "Commit Mono UI", monospace; }` fails with `missing
  rga_visualiser.html #button-menu span at 400: U+2630`, which the three stacks of the shell pass;
- `.later-panel { font-family: "Commit Mono UI", monospace; }` matches no element, and fails at 400,
  600 and 700 with `rule .later-panel` and each codepoint that Commit Mono does not map, U+2630
  among them. A check of the stacks in use alone passes it;
- a rule for `.later-panel` sets `font: 600 12px var(--later)` inside `@media (max-width: 10px)`.
  Inside `@media print`, `:root` declares `--later` as the same stack. The check fails it with the
  same finding.

With the maths and symbols declared at 400 alone, the check fails at 600, with U+2715 in
`button#selection-menu-close` and U+25B6 in `#drawer span.chev`. In every stack in use it names the
operators, the bold operands and the chip symbols. With them under "Noto Sans UI" at 400 to 600,
both checks fail at 400 and at 600, on 2026-10-07. They name the Latin text of each element in the
sans stack, as `button#button-add at 600: U+0061`. A model that asks each face that holds the weight
passes that shell. Verified by a run, 2026-10-03: the other page checks pass with the whole faces.

**The serif ships at 600 alone, because every title is set at 600.** A weight that nothing ships is
a face that the browser of the reader invents (Article X.8). The check reads pixels, and not width,
which cannot part the two faces. The heading shot as the page has it, and again with the interface
face forced onto it, must make two pictures.

**The desktop draws the same three roles.** `NotoSerif-SemiBold` matches the 600 of the page, and
`CommitMonoV142-400Regular` sets notation. The supplementary ranges are merged into the mono and
interface faces, because those rows carry wedges. Commit Mono comes from the repository of its
author, because `@fontsource` ships no TrueType. **Ligatures cannot reach the desktop**, because
Dear ImGui shapes no text, so no GSUB feature fires.

## Desktop front-end

**Two libraries are bound rather than wrapped, and only where they are called.** SDL3 owns the
window, the input and the OpenGL context, and libGL owns the driver. Both are external concerns that
this project exists to look past (Article II.8). So `src/desktop/sdl3.nim` and
`src/desktop/opengl.nim` declare only the symbols called, each through the header of the library
itself. The library flag sits in the module that needs it, and never in configuration.

**Mirrored constants are checked against the header's own, by a generated assertion.** The event
kinds, scancodes, modifier masks and window flags of SDL3 are mirrored as Nim constants, so that
`case` can bind them. One table pairs each with the name of the header, and `CHECKS_MIRROR` emits
one C++ `static_assert` for each pair. Verified by a break on purpose: `Scancode.Home` moved by one
fails with `SDL3 binding is stale`. OpenGL enumerants are literals, and are never renumbered.

**Dear ImGui is reached through C entry points, because there is no symbol to bind.** Its interface
is C++ with overloads, default arguments and namespaces, and the `cpp` backend of Nim imports none
of the three. So `src/desktop/gui_shim.cpp` flattens the slice that this visualiser calls into plain
C, and `src/desktop/gui.nim` binds that, as a facade that declares exactly the widgets used. Cost:
to add a widget touches two files. The kind is registered *gated* (repository issue 26), so
`justification.nim` demands that its header carry `not Nim because`.

**Dear ImGui is compiled in rather than linked, and pinned by commit.** That is
`fd13a1e8923a0a7077b404fc36fd063b25a0c0b5` of the `docking` branch of `ocornut/imgui`, MIT licence,
cloned into `dependencies/imgui` and never committed. A compiler flag sets `IMGUI_USE_WCHAR32`,
because the notation carries bold operands past a 16-bit `ImWchar`. An edit to `imconfig.h` would
not survive a reclone. `checkImgui` reads the `HEAD` of the checkout, and refuses by name.

**Neither SDL3 nor Dear ImGui arrives as a package, so `desktop` fetches both at their pins.**
Ubuntu 24.04 carries no SDL3 at all. SDL3 is cloned at its tag, and built into `build/sdl3`, a
prefix inside the tree, so no step needs root, and `clean` removes it. `checkSdl3` reads what
`pkg-config` reports there, and the commit that the clone stands at, before anything is compiled:
`3.2.30`, zlib licence. Neither library is in `PACKAGES_SYSTEM`, and `cmake`, `pkg-config` and `git`
stay there for their sake.

**The pin is a release tag, and the commit that the tag resolves to binds the bytes.** `release-`
prefixed to `VERSION_SDL3` is the ref that fetches. `COMMIT_SDL3`,
`f5e5f6588921eed3d7d048ce43d9eb1ff0da0ffc`, is what has to arrive, read through `checkCommit` on the
warm tree too, before cmake (repository issue 126). A moved tag fetches other sources while
`pkg-config` still answers `3.2.30`. The tag stays because `--depth 1 --branch` needs a ref. That is
also why a shallow clone is safe here, and not for Dear ImGui, whose pin sits behind a branch head.

**An odd patch number names no tag**, because the series releases on even numbers alone (repository
issue 90). 3.2.30 is the newest of a series still maintained (repository issue 111).

**The build dependencies of SDL3 itself are declared too.** `libxext-dev` arrives under nothing
else, and without it cmake reports `SDL_X11 (Wanted: ON): OFF` and exits 1. The cost of the prefix
is `-rpath`, derived from the checkout through `getCurrentDir()`, because a committed `/opt/...`
builds on one machine. Rejected: `/usr/local`, which needs a root that CI is not granted.

**The renderer owns the OpenGL names, and draws the records of `mesh` through them, one program for
each record kind.** Each program has a vertex shader that widens compact records over static corner
geometry. Buffers are uploaded whole each frame, rather than tracked for changes. Upload sits far
below the reach of any frame, and nothing can be stale after an edit. These are the records that the
WebGL side draws, which makes this a cross-check rather than a second implementation. The panel
holds only what the GUI needs between frames, and reads the rest off the scene and the camera.

**An edit stages doubles, as the scene holds them.** `EditSession` holds its sixteen coefficients
and its radius as `float`. `gui.dragDouble` binds `DragScalar` on `ImGuiDataType_Double`, and the
grid of an edit, the motor grid and the size field draw through it. An edit that opens and saves
unchanged then writes back every bit. Rejected: `float32`, which `DragFloat` writes, and which steps
an eighth of a unit two million units out. An unchanged save through it moves an object there by up
to 0.04 units, as the demo's HD 222237 b shows.

A drag never rounds to the four digits shown (`ImGuiSliderFlags_NoRoundToFormat`), since that
rounding would move such a coefficient hundreds of units. Verified by a read of `imgui_widgets.cpp`
alone, on 2026-10-05, and no check drags a coefficient.

**The proof of an unchanged edit is a driven run, and not a suite case.** The suite compiles no
`panel`, since `gui` needs a GL context, and a pure helper would prove a copy, and not the widget.
`--drive-edit` opens and saves through `beginSession` and `saveSession`, as the buttons of the row
do, and lays the grid out for five frames between them.

**The entry point owns the window, the event loop and every headless run.** The run modes are
`--screenshot`, `--frames`, `--hidden`, `--storyboard`, `--timings`, `--novsync`, `--fill`, `--demo`
and `--drive-*`. Each one pushes real events through the queue of SDL, rather than calls a handler.
`--drive-edit` alone calls the procs of the buttons of a row, which no pointer reaches.

**The compiler flags of the desktop live in the build driver.** The `desktop` verb of
`tools/build.nim` passes the `cpp` backend and the output path. Rejected: `main.nim.cfg`, which Nim
applies invisibly to any build of that file. There is no `-d:release`, because the `--drive-*` runs
report through assertions that release removes.

**The constant controls float in an overlay of their own, and not inside the panel window**, so they
stay when the panel collapses. They are one line in a `windowBeginPinned` overlay, which is the door
that `?` uses, top right, because the panel opens at the top left.

The menu hangs by its **right** edge, since anchored by its left it opens past the window. No check
sees that, because the verdict asks what the menu *offered*, so such a change ends with a picture.

**Both front-ends offer the same three menu groups, and the demo group is built rather than
written.** It walks `orrery.ScaleOrrery` and labels each button with `objectsOf`, as the page
builds its own from `nimDemoScales`. A size added to `orrery` then arrives in both.

There are two deliberate differences. The menu of the desktop carries `scene file` and `image file`
fields, because a desktop build writes to paths. The menu hangs from its own button, and not from
the pointer. A menu that lands in a different place each time is one that the reader must find
twice. `--drive-menu` opens it with no pointer, through the `is_forced` of `guiMenuBegin`.

**A long list is bounded, rather than left to run past the window.** It hugs its own content until
the window runs out, and scrolls inside that bound after. That is `ImGuiChildFlags_AutoResizeY`
under `SetNextWindowSizeConstraints`, with the heading outside that region so it cannot move.
Rejected: a fixed height with a threshold, which put a five-object scene in a box of blank.

**Toggles are pills on both front-ends**, and `guiButtonToggle` carries fill, border and text
colour together. The words of the wheel are taught in the drag tab of help, read from `wordOf`
and `labelOf`. A law in the shared suite holds that every wheel word appears there.

*Checked.* Verified by a run. Both bindings compile and link against SDL3 3.2.30 and libGL
through `nim cpp`, and their assertions run against real headers. Dear ImGui starts over a hidden
SDL3 window, with a real OpenGL 3.3 core context under Xvfb, and draws through both its backends.

Verified by looking, 2026-10-02, at the PNG that this command writes under Xvfb:

```sh
xvfb-run -a -s "-screen 0 1440x900x24" \
  binaries/rga_visualiser --hidden --frames:300 --screenshot:desktop.png
```

The PNG carries the axes, the scale bar, the disc of the ground plane, the points and the panel.
Both front-ends draw one scene from one core. With `--frames:60` the disc is not drawn yet, because
the entrance animation still runs. **Unverified**: no human has seen this on real graphics hardware.
Software GL reports no multisampled visual, so thin lines alias.

## Desktop driven checks

**The suites test the rules, `tools/drive/` tests the wiring of the browser, and this tests the
wiring of the desktop.** The entry point carries scripted runs: `--drive-keys`, `--drive-sky`,
`--drive-undo`, `--drive-select`, `--drive-drag`, `--drive-search`, `--drive-menu`, `--drive-faces`,
`--drive-edit`, `--drive-wheel`, and `--drive-help:<tab>`, one for each tab. Each pushes real
events through the queue of SDL, but `--drive-edit` calls the procs of the buttons (Desktop
front-end). `driven` runs all of them and reports every failure, and not the first. It asks the
binary which help tabs exist (`--help-tabs`), so `help.HelpPath` stays their one home (Article
I.4). `drive` chains it, here and on the runner (repository issue 91).

**A run that reaches a window of Dear ImGui names that window on its motion.** The SDL3 backend of
Dear ImGui drops motion that names no window of its own. `--drive-select` and `--drive-wheel` name
it, so Dear ImGui reads the pointer over the menu as it reads a hand. Verified by a run, 2026-10-11:
`--drive-wheel` with its motion unnamed reads the pointer off the menu, and fails.

`driven` counts the scripted runs. They cover these cases:

- a held key orbits about the pick, and leaves the pivot on it;
- a drag across bare sky turns the view and builds nothing;
- undo takes a construction back, and returns the view to where it built from;
- the choice menu does not swallow the drag after it;
- every help tab opens with rows in it;
- a run whose face is missing still does its scripted work;
- every type role is drawn in a face of its own;
- every codepoint that each role sets has a glyph in the face of that role;
- a scene filled to capacity leaves what follows its list on the window;
- the menu opens and offers the demo at every size that `orrery` has;
- an edit opened far out and saved unchanged keeps every coefficient and its radius to the bit;
- a wheel over the selection menu zooms the view about the pick, as on the page.

**An absent face is a finding, and never an abort.** Dear ImGui asserts inside `AddFontFromFileTTF`
where it cannot open a path, and an assertion is SIGABRT rather than a report. `faceAt` resolves
each face to empty where the file is not there. It says which face is missing, which variable names
it, and which verb fetches it. The interface draws in what is left.

Locations come from the environment first, with one `RGA_FONT…` name for each face, and fall back to
the faces that this build ships. `driven` drives the case by a run of `--drive-keys` with `RGA_FONT`
naming a path that no machine carries.

**This half ships the faces that it draws with** (Article X.8; repository issue 93).
`DIRECTORY_FACES` is relative to the binary through `getAppDir()`, so no source names the layout of
any machine. The faces come from the release repository of the Noto project. A tag and a digest pin
each family, because the families move on their own: `NotoSans-v2.013`, `NotoSansMath-v2.539` and
`NotoSansSymbols2-v2.006`. A read of each `cmap` against the ranges that `gui_shim.cpp` declares
gives the coverage: math holds 1,773 of the 1,952 wanted. The faces cost about 2.5 MB fetched into
`build/fonts`, because `stb_truetype` reads uncompressed faces.

**Every codepoint that the build writes is asked of the face that sets it** (Article X.8).
`shown.codepointsShown` gathers the text from where it is composed, for `--drive-faces` and for the
page alike. That is the wording catalogue, help, the notation of each operation, the basis names,
the wheel and the units. It adds printable ASCII, since a reader names objects in it. `gui.hasGlyph`
loads each codepoint through the face of each role, as drawing does, and reports each one that would
draw as `.notdef`. The title role is asked for the panel headings alone, because nothing is merged
into its face.

**Merge order is precedence, and the range lists bind only the legacy path.** From Dear ImGui 1.92,
a renderer that keeps textures of its own loads each glyph on demand. It takes the glyph from the
first merged face whose `cmap` holds it (`imgui_draw.cpp`, `ImFontBaked_BuildLoadGlyph`). So the
check does not read each `cmap` against the range lists, which asks what drawing does not ask.

**The mono role merges the interface face last.** Commit Mono, Noto Sans Math and Noto Sans Symbols
2 carry no glyph for `ˍ` (U+02CD) or `˷` (U+02F7). Those are the postfix accents of left complement
and antireverse, and Noto Sans carries both. It comes last, so it supplies only what the three faces
before it lack. The cost is that its two accents are proportional in a mono line.

**A scripted run keeps its own clock.** Each frame drawn advances it by `SECONDS_FRAME_DRIVEN`,
1/120 s, one frame at the least workable rate (Diagnostics). The opening scene is born at zero.
Animations, held keys and camera ease read that clock, so a scripted frame shows the same on any
machine. `--timings` keeps the real clock, since speed is what it measures.

**No default favours a silent pass.** A scripted run supplies `FRAMES_DRIVEN` where the caller gave
no frame bound, because the loop ends only on one. Every scripted run ends in its verdict. Its 400
frames are 3.3 s of the scripted clock, and every drive reaches its verdict inside them.

**What `driven` costs, on this container, on 4 cores and software GL.** Cold, with neither checkout
present and nothing built, it costs **1 m 27 s**. Warm, it costs **29.3 s**, because a prefix that
already reports the pinned version is kept. On the runner the `driven` step costs about **3 m 15 s**
more with the desktop half than without. That is 215 s against 411 s, one run against one run.
Repository issue 79 weighs that against the rest of the job.

*Checked.* Verified by a run. Every scripted run passes under Xvfb on software GL, from a tree that
carries neither checkout and with no SDL3 anywhere on the machine. A second run kept the prefix and
rebuilt nothing. `--drive-keys`, run three times, read azimuth 1.0094, elevation 0.5045 and distance
18.5660 each time. Verified by a break on purpose: with the drag verdict inverted, the run reports
`FAIL  a drag from one object onto another opens its choice menu`, and the verb names
`drive-drag`, with exit 1.

Verified by a run, 2026-10-02: without Noto Sans merged into the mono role, `--drive-faces` reports
`FAIL every codepoint the Mono face sets has a glyph` with `missing U+02CD, U+02F7`. With it, all
four roles pass. Verified by a read of each face's `cmap`, 2026-10-02, with a scratch reader: Noto
Sans holds both codepoints, and the other three faces hold neither.

Verified by looking, 2026-10-02, at the operations tab that this command draws. Both accents draw as
`�` without the merge, and as accents with it:

```sh
xvfb-run -a -s "-screen 0 1440x900x24" binaries/rga_visualiser \
  --hidden --drive-help:operations --frames:300 --screenshot:operations.png
```

## Diagnostics

**The least workable frame rate is 120 per second, and the goal above it is as fast as the machine
allows.** The Architect sets that floor (repository issue 346). `timings.RATE_FRAME_LEAST` states it
once, and the page reads it through `nimRateFrameLeast`. A scripted desktop run steps its clock one
frame at that rate. The frame-time plot of the window and the sparkline of the page floor their
range at 8.3 ms. A smooth run then does not zoom in on noise.

**The plots and the curve hold spans of time, sized at the floor.** The plot of each front-end holds
`timings.FRAMES_HISTORY` frames, four seconds at the floor, and the exceedance curve holds
`timings.FRAMES_EXCEEDANCE`, seventeen seconds. `timings.nim` derives each from its span and
`RATE_FRAME_LEAST`, and the page reads both through the bridge, so a new floor moves both windows. A
machine faster than the floor fills each in less time.

**The marks of the curve are 240, 120, 60, 30, 15, 10, 5 and 1 per second, and bound its colour
bands.** A frame under 4.2 ms is fast, under 8.3 ms good, under 16.7 ms fair, and slower poor. The
120 mark wears good, because a frame inside it meets the floor. The 240 mark,
`timings.RATE_FRAME_FAST`, is twice the rate of the floor, and nothing is held to it (`GLOSSARY.md`,
Mark). Rejected: 120 as fast and 60 as good, which names a rate under the floor good.

**A mark gives way where its labels would cover a slower mark.** The marks are walked slowest first,
so the one nearer the floor keeps its place. On an axis of 90 ms, the 240 line stands 17 px from the
120 line, and its labels would cover that line. The curve keeps its bands, since the list sets them,
and not what is drawn.

*Checked.* Verified by driven check:

- four marks on a fast window, each named as a rate and as a duration;
- on a window of 0 to 88.3 ms, the 15 fps mark drawn, and the 240 mark given way to the 120 mark;
- three of the four band colours on a mixed window, since its feed holds no frame under 4.2 ms.

Verified by a run: every scripted desktop run passes at 1/120 s, in 400 frames. Verified by a
render: the curve of the page and the plot of the window, before and after, in the pull request.

## PGA share

**The diagnostics show the PGA share, and the share of each side of the algebra boundary.** A
sampling profiler counts them on both front-ends, while the diagnostics section is open. One rule,
`share.nim`, names the owner of each sample: the side whose code the sample was running. That is the
owner of the innermost owned frame on its stack. The Architect set the PGA share on repository issue
553, and the four sides on pull request 574.

**PGA owns the time in its own operators, whoever called them.** PGA calls back into nothing of the
project, so a frame in `pga` is the innermost owned frame wherever it stands. The algebra side owns
`motors`, `projections` and `objects`, which compose the operators of PGA. The boundary owns
`boundary`, which lifts into the algebra and reads back out. The Euclidean side owns `euclid` and
`mesh`, which never name a multivector. A frame that no side owns, such as a copy in `system`,
belongs to the owned frame that called it.

Rejected: the highest owner on the stack, which counts the calls of `boundary` into `euclid` as the
time of the boundary. Rejected: a module that only composes PGA counted as PGA, which counts its own
copies and calls as PGA's. The other modules consume all four sides, and their own work is Rest.

**The share is pooled over 20 seconds, and the count of samples stands beside it.** One frame holds
few samples. The page samples every 10 ms at most, and the build of the opening scene gets about 4
samples each second. A window of 4 s then holds 11 to 17 samples, which read 35 to 64%. Only busy
samples count. A wait for vsync, or a sample with no page script on its stack, has no owner.

**The desktop samples its main thread on the CPU clock of that thread, and walks the frames of
Nim.** `sampler.nim` arms `timer_create` on `CLOCK_THREAD_CPUTIME_ID`, at 250 samples each busy
second. The handler allocates nothing. It walks out from the innermost frame to the first that
`share.ownerOfPath` names a side for, and adds one atomically. This runs on Linux alone, in a build
that keeps stack frames, and elsewhere the rows say why. Rejected: the own profiler of Nim, which
read 30 to 41% against 26% and made the frame 2.2 times slower.

**The walk of the frames of Nim reads low against native unwinding.** A sample that lands in the
push or pop of a small library proc, such as `[]`, misses its frame. On the same samples the walk
read 17.9% against 19.0% at the opening scene, and 21.5% against 26.4% at the largest demo. The
reference matched `backtrace()` stacks to the symbol table of the binary. Cost: none that a
measurement found, at 4.515 against 4.506 ms and 4.250 against 4.232 ms for each frame.

**The page samples with the own profiler of the browser, where the browser allows it.** Chromium
alone has one, and only on a page whose own response carries `Document-Policy: js-profiling`. A page
opened from a file is refused, and a `<meta>` copy of the policy changes nothing. The rows then say
why, and give no figure. The profiler gives no interval under 10 ms. Each window of 2 s stops and
hands in its trace, and the next starts at once, at a cost of 0.2 to 0.3 ms.

**The two front-ends read different shares, because their busy time holds different work.** The busy
time of the desktop holds the layout of its panel and the submission of its draws. The page leaves
both to the browser, outside its script. On the page, about a third of the samples of the boundary
are copies of the JS backend: 252 of 701 at the largest demo.

**The drive checks the figure of the page against the own profiler of the engine on every run.** It
serves the built page with the policy, at an address that a route answers. Both profilers sample the
largest demo until the page holds 350 busy samples, about 12 s. Both name owners through
`nimShareOwner`, and take the innermost owned frame. The bound is four standard errors of the two
counts, and 2 points of bias. The table gives each side at the largest demo, and its last row the
page less the engine over seven runs.

| Largest demo | PGA | Algebra side | Boundary | Euclidean side | Busy samples |
|--------------|-----|--------------|----------|----------------|--------------|
| Desktop, 2 runs | 13.9 to 14.1% | 4.0 to 5.3% | 0.8 to 1.0% | 0.4 to 0.5% | about 5,800 |
| Page, 7 runs | 22.3 to 31.4% | 0.8 to 2.0% | 4.8 to 8.9% | 1.5 to 3.4% | 355 to 404 |
| Page less engine | -2.5 to +4.3 | -0.9 to +0.4 | -2.7 to +1.6 | -1.3 to +0.5 | |

*Checked.* Verified by `suites.nim`: the rule names the owner of names from the built page and of
desktop paths. It names a stack by its innermost owned frame, and the ring pools 20 s. On Linux, the
sampler counts a loop of products as PGA's, at 82 to 85% of about 100 samples. Verified by driven
check: the page from a file says why it cannot sample, and the served page agrees with the engine on
each side. Verified on 2026-10-06 by `xvfb-run -a binaries/rga_visualiser --hidden --novsync
--timings --frames:300 --demo:5038`: the desktop figures above.

## Values crossing the boundary

**The diagnostics count the values that cross the algebra boundary in each frame, each way.**
`euclidean → algebra` counts positions, directions and motors that `boundary` lifts into
multivectors. `algebra → euclidean` counts multivectors that `boundary` reads back out as positions,
directions and motors. Each row shows a mean for each frame over the window of the PGA share, and
the frames it rests on. The Architect set this design and both labels on repository issue 581.

**`boundary` counts each value itself, behind one gate.** Each lift and each reader adds one to its
way while the gate is open. A read that refuses hands no value out, and adds nothing: a weightless
point has no place. Each front-end drains the tally once in each frame, and a drain counts a frame
only while the gate is open. Both open it while the diagnostics section is shown, and so does the
`--timings` run of the desktop. Shut, each crossing pays one load and one branch.

**The counts pool in the ring of the PGA share.** `share.RingShare` takes any array of counts, so
both figures keep one window and one rule. A frame drained while the gate was shut counts nothing,
so a mean never takes in frames that nobody read.

**Values alone, in `boundary` alone.** A motor counts as one value, as a direction does, though it
carries 8 coefficients against 3. Plain numbers are not counted, such as the depths and distances
that `objects` hands out. Nor are the coordinates that `camera` reads for its bearing, or the norms
that `framing` and `picking` read. `camera` reads its carried direction through
`boundary.directionFrom`, so that crossing counts.

**The arrow of each label comes from the maths face, so the label sets its own line height.** The
line box of that face stands taller than the box of the text face. With the line height of the text
face, the two crossing rows stand 5 px above the others.

| Front-end and scene | `euclidean → algebra` | `algebra → euclidean` |
|---------------------|-----------------------|-----------------------|
| Desktop, opening scene | 24.0 | 24.0 |
| Desktop, largest demo | 529.2 | 5,356.0 |
| Page, opening scene, still | 19.3 | 21.6 |
| Page, opening scene, orbiting | 36.9 | 33.4 |
| Page, largest demo, still | 367.7 | 5,269.1 |
| Page, largest demo, orbiting | 384.7 | 5,279.9 |

**At the largest demo, about 5,300 values leave the algebra in each frame, and placement reads most
of them.** It reads one position for each object on every frame, still or moving. The desktop counts
the same on every run, since a count does not move with load.

*Checked.* Verified by `suites.nim`: each lift and read counts once each way while the tally is
open, and a read that refuses counts nothing. The ring pools a mean for each frame. Verified by
driven check: the page counts values that enter the algebra, and at least one value leaving it for
each object. It stops once diagnostics close, and each crossing row stands as tall as the frame time
row. Verified on 2026-10-06 by `xvfb-run -a binaries/rga_visualiser --hidden --novsync --timings
--frames:300 --demo:5038`: the desktop figures above.

## Render paths

**The directory that a module sits in is the render path that may reach it.**

| Directory | Reachable from | Holds |
|-----------|----------------|-------|
| `src/rga_visualiser` | Both | `objects`, `euclid`, `boundary`, `mesh`, `tessellate`, `camera`, |
|  |  | `scene`, `selection`, `picking`, `marker`, `framing`, `interaction`, |
|  |  | `storyboard`, `orrery`, `neighbourhood`, `starfield`, `history`, |
|  |  | `format`, `help`, `message`, `wording`, `timings`, `ramp`, |
|  |  | `projections` |
| `src/desktop` | `main.nim` alone | `main`, `panel`, `renderer`, `gui`, `gui_shim.cpp`, |
|  |  | `opengl`, `sdl3`, `image`, `gif`, `arena` |
| `src/browser` | `bridge.nim` alone | `bridge.nim` and the page's own scripts |

`pga` is the dependency above all three, and the shared core imports nothing outside itself and
`pga`. `src/desktop` and `src/browser` each import that core, and never each other, which the import
paths show (`../rga_visualiser/`). One driver builds both: `web` assembles the page, and `desktop`
compiles the binary, and neither entry point carries a configuration file of its own. `arena` sits
in `src/desktop` although it is general-purpose, because only the encoders and the draw loop of the
desktop reach it. The JS backend cannot carve typed slices from a byte array at all.

A shared module that reaches for something which only one path has is a **compile error, and not a
comment**. `toCstring`, `buildChars`, `appendInt`, `appendFixed`, `saveScene` and `loadScene`, with
their `std/os` and `std/syncio` imports, carry the guard `when not defined(js)`. Every binding into
C, SDL, Dear ImGui, zlib and JavaScript carries `sideEffect`, so a `func` that reaches one fails to
compile. `format.snprintf` alone keeps `noSideEffect`, because it writes only the buffer that it is
handed, on the stack of its caller. Without the mark the compiler holds an imported body to be pure.

**Every frame builds, uploads and draws the whole scene, still or moving.** Both front-ends run one
pipeline for each frame. The ease moves the camera first, and `framing.placeEvery` places every live
object through the reference library. The reach of the scene is read off those placements. The view
origin moves to the eye, and the eye and frame come off one lift (Origins).

The near reach, the extent, the frustum and the aim read those, and the furniture and the scene
records are built from the placements. The records are flattened, uploaded and drawn, and the
overlay reads the extent of the frame. Nothing in the pipeline asks whether anything moved.

**Frame consistency over work savings: every frame does the same work, still or moving.** The page
is a stress test of the reference library, so as the library gets faster, the page gets faster.
Every frame runs the library for the whole scene, and no result of the library is kept across
frames. A kept result hides what the library costs.

The project adds no work beyond what the frame needs. Each library call runs once in a frame for
what needs it, and the own copies, conversions, allocations and glue stay lean. A speed-up of the
own code is welcome where every frame pays the overhead it removes, and one that skips library work
is rejected. Rejected: the scene hold, the furniture holds and the overlay hold. Each keeps the
records, the furniture or the extent of the overlay from an earlier frame where nothing moved. A
still frame then reads cheaper than the work it stands for.

The rule keeps sharing within one frame. The stance is read once and handed to every reader, each
object is placed once, and every reader of the frame reads that placement. `MARKER_SHAPED` hands a
marker to the pulse that follows it, and the overlay calls of a frame share one extent.

**Within a frame, the overlay takes the extent that the build derived.** Each frame build drops the
extent of the overlay and the marker that the frame before shaped (`SETTINGS_OVERLAY_FRAME`,
`MARKER_SHAPED`). The first overlay reader of a frame derives the extent again, and each reader at
the same camera and viewport shares it. Where the camera stands as the build left it, the overlay
takes the extent of the build at its own pixel height (`camera.atHeight`). So the stance is read,
and the algebra twins derived, once in the frame.

**A reader between two frames reads the placements of the last frame.** Pointer events land between
frames. After an edit that no frame has placed yet, `placeStamped` places only the handles that the
edit stamped (Scene storage). The next frame places every handle again, so no placement serves a
later frame as its answer. The desktop calls it in the middle of its frame too, after the selection
menu, which can edit.

**Each front-end places each object once in a frame, and no reader classifies it again.** The reach,
the near reach, the cull, the emission and the hover pick read the placements of the frame. So do
the marker, its pulse and its label, the anchor and the comet of the overlay, and the menu anchor.
So do the aim of the camera and the lattice of a selected plane, through `framing`. The wheel pick
of the desktop reads them after `placeEdited`. A caller with no frame, such as a preview, still
hands a multivector, and the reader places it first (`placementOf`).

Rejected: a placement again in `addObject` and in the pick, which placed each object twice and ran
`kindOf` three times for each. Rejected: a reader that classifies the multivector again, which
classifies each selected object on each call.

**The placements of a frame live in its frame arena.** The desktop carves them first from
`ARENAS_FRAME` at each turn (`turnFrame`), and draw scratch after them. The page turns two typed
blocks (`PLACEMENTS_FRAME`) as each build opens, because the JS backend cannot carve typed memory.
Both read the frame through `placements`, and the frame before through `placementsPrevious`, for
work across two frames. A handle dead or newly born in that frame holds nothing meaningful there.
The Architect set this design on repository issue 556.

The desktop turns its frame arenas after the events and before the frame places. So a handler
between two frames reads the placements of the last frame, which it picks against. Every path that
turns them places straight after, the capture of the storyboard included. Rejected: one fixed array,
which the next frame overwrites. Cost: a second block of placements on each front-end, 645,120 bytes
on the desktop (Memory and allocation).

**One frame classifies each live object once, its overlay included.** `kindInto` tallies each
classification while a reader counts (Algebra boundary). `driveClassifiedOnce` counts one frame of
the page, from its build to the placing of its menu, at the largest demo. It counts with nothing
selected, one object of each kind alone, every object, a hovered point, and a left drag that orbits.
Each frame must read 5,038, and the hover pick none. On `7ba32bda`, before this design, one point
selected read 5,045 to 5,048, every object 30,196 to 39,832, and the hover pick 4.

**Placing tests the horizon once for each object.** `placeInto` asks `isHorizon` once, and hands the
answer to each read that needs it. `positionAnchor`, `direction`, `directionHorizon`,
`directionNormalHorizon` and `directionNormal` each have a twin that takes it. A plane reads its
support once, and spans its frame about it. The cost of one test is unmeasured here.

**A placement is written into its slot field by field** (`tessellate.placeInto`). On the JS backend,
a placement or an `Option` built and assigned is one `nimCopy`, and a point placed that way costs
about ten. `kindInto` and `positionInto` classify a multivector and read a point the same way. The
two copies left for each point are inside `grade`, in the library. The diagnostics tree has a row
for placing, `objects placed`, so the prologue row stays what the camera and the aim cost.

**What the largest demo costs a frame, before and after.** Measured on 2026-10-06 on one delegate,
on the real clock, by a harness that is not kept, at 1200 by 900 px under SwiftShader. It reads the
median of `ms_build`, the build of a frame alone, `598e7fa1` first and then this design, and no
measured frame runs a pick. With every object selected, each of three pairs read 10 settled frames:
447.6 to 387.2 ms, 460.8 to 418.9 ms and 442.8 to 381.6 ms. The overlay of those frames took 11.5 to
11.7 s on both builds, which its SVG elements and labels spend.

With nothing selected, six pairs of 300 frames read 7.9 to 8.1 ms before and 7.9 to 8.4 ms after.
This design read 0.1 to 0.5 ms more in five pairs, and 0.2 ms less in one. The frame arenas alone,
`8271aab1`, read 8.0 to 8.1 ms beside them. The cause of that difference is unmeasured.

**What a frame costs, held and built.** Measured on 2026-10-05 on one delegate, under the lock of
the gate, by a harness that is not kept. It drives the page at 1200 by 900 px under SwiftShader,
with antialias, and times 6 s of frames for each scene. An orbit turns the camera 0.004 radians in
each frame. Three pairs ran in turn: `a1702384`, which held a still frame, then this design. The
figures are ranges over the three, in ms of the frame callback:

| Scene | Median, held | Median, built | Slowest tenth, held | Slowest tenth, built |
|-------|--------------|---------------|---------------------|----------------------|
| Opening scene, still | 0.7 to 0.8 | 0.9 to 1.0 | 1.0 to 1.2 | 1.4 to 1.6 |
| Opening scene, orbit | 0.9 to 1.0 | 0.9 to 1.0 | 1.4 to 1.7 | 1.3 to 1.4 |
| 5,038 objects, still | 1.0 to 1.2 | 9.4 to 12.7 | 1.4 to 1.7 | 14.8 to 17.6 |
| 5,038 objects, orbit | 1.9 to 2.1 | 10.1 to 15.3 | 3.2 to 3.4 | 15.8 to 17.4 |

At 5,038 objects a still frame and a moving frame cost the same. Most of either is the placing side
of the whole scene through the library, as the `objects placed` row shows. The held still frame read
1 ms because it did none of that work.

The desktop runs `--timings` for 300 frames, in three pairs, on the `desktop` build without
`-d:release`. It reads the median frame in ms, and the mean of placing and tessellating in µs:

| Scene | Frame, before | Frame, after | Placing and tessellating, before | And after |
|-------|---------------|--------------|----------------------------------|-----------|
| Opening scene | 4.66 to 5.01 | 4.63 to 5.63 | 42 to 44 | 73 to 80 |
| 5,038 objects | 83.6 to 83.9 | 68.3 to 71.5 | 14,994 to 15,079 | 7,030 to 7,353 |

At the opening scene the furniture is built in every frame, so tessellating costs more. At 5,038
objects the desktop places each object once, where it classified each one three times. So its frame
costs less, with the same 27,167 vertices.

*Checked.* Verified: the suite runs on both backends, so it exercises the guard rather than trusts
it (Testing). Verified by a compile, 2026-10-02: a `func` that calls `timings.nowMilliseconds` on
the JavaScript backend is refused as `can have side effects`, and compiles without the mark.

Verified by driven check:

- a still camera builds its scenery on every frame, the same each time, and a moved camera too;
- a still camera over a still scene builds its whole records on every frame;
- every edit reaches the canvas, and the frame after an undo draws the scene that it restored;
- a still frame under the largest demo copies fewer values of its own than the scene has objects;
- each frame build of the page lifts the motor once, still and while a drag orbits;
- one frame of the page classifies each live object once, in each state that it counts.

Verified by the measurements above, and by `suites.nim` on both backends: the placements that
`placeInto` writes give what `placeObject` gave. Verified by `suites.nim`: each exit of placing
tests the horizon of its object once at most. A line and a plane through the origin are among them,
and each lands where the reads alone land. Assumed: that no edit of the desktop lands between
`placeEdited` and the emission of its frame, which no check drives.

## Scene storage

`Scene` (`scene.nim`) is a fixed-capacity arena, held as a structure of arrays. They hold
geometries, labels, inks, visibility, liveness, birth stamps, creation ordinals, placing stamps,
anchor overrides and radii. A handle addresses each object, and `addObject` assigns it once, and
nothing moves it after. Free handles thread onto an intrusive singly-linked free list, so an add and
a remove are both O(1). The next add takes the handle freed last. `OBJECTS_MAX` is 5040 and
`LABEL_MAX` is 40, and `{.define.}` overrides both.

So **a handle number stays valid until its object is removed**. Rejected: a shift-on-delete array,
where a removal renumbers every cross-frame index that a caller holds.

**`Scene.bound` is the highest handle that was ever occupied**, and every walk of a frame runs to it
rather than to capacity. It only rises, so a walk to it is safe. Three walks run to capacity,
because their subject is how much room is left. They are the free list and the two object-pool
strips, which the doc comment of `bound` names.

A walk to capacity over the five objects of the opening scene costs less than the 0.1 ms that the
clock of the page resolves. With every walk run to capacity, the still frame read a median of 0.6 to
0.7 ms, as the build that walks to `bound` does. So no speed check can hold that fault.

**`Scene.revision` counts the edits, and every writer sits inside `scene.nim`.** No geometry
accessor returns a `var`, which would let a caller write with nothing recorded. Undo, redo, clear
and every load replace the whole scene through `restoreFrom`. That call issues a revision **newer
than every revision it ever handed out**, which is `max(live, snapshot) + 1`. Rejected: the count of
the snapshot plus one, which a state between the two already wore. A reader keyed on it then takes
the new scene for one that it read.

**A placement falls out of date one handle at a time.** `Scene.revisions_placing` stamps each handle
at the edit that last changed it, and `restoreFrom` stamps every live handle of the snapshot. Every
frame places every handle (Render paths). A reader between two frames, after an edit that the frame
has not placed, places only the handles stamped later (`placeStamped`).

**The record of the creation order is explicit** (`orders`, `count_created`, `handlesCreated`), and
nothing infers it. Handle order stops being creation order as soon as anything is removed. Rejected:
a sort by `born`, which fails on three counts that all occur. Two objects added in one frame share a
clock reading. The `born` of a replayed object is stamped into the future, and the `born` of a
reused handle is stale until something overwrites it.

`handlesCreated` is a heap sort. At 5,038 objects an insertion sort makes 12,688,203 comparisons
where handle order is the reverse of creation order, and the heap sort makes 104,039. A scene takes
that order where every handle is freed in rising order and then filled again. On the demo as it
loads, handle order is creation order, and the two sorts make 5,037 and 113,106 comparisons. The
panel of the desktop caches its answer against `scene.revision`. A sort in every frame was 98% of
the CPU frame of the desktop at 5,038.

**`LABEL_MAX` counts bytes, so a label is cut on a character boundary and says that it was cut.**
`format.appendChars` copies a UTF-8 sequence only where all of it fits, and `scene.toChars` rewinds
far enough to append `…`. Otherwise a 3-byte operator glyph that straddles the limit leaves invalid
UTF-8, which the JS backend percent-escapes into a name (`%e2%8a`).

`Object` is a handle, and not an assembled copy. Under `nim js` it holds the `Scene` by value, so
the loops that run for each frame use the accessors that take a handle instead.

*Checked.* Verified by `suites.nim`:

- handle stability across a removal, and the next add taking the handle freed last;
- `handlesCreated` over a scrambled arena of hundreds;
- `revisionPlacingAt` stamps one handle for each edit, and every handle after a restore;
- `restoreFrom` lands on a revision that no earlier state carried;
- a label cut never splits a character, at any buffer size.

Verified by driven check: the frame after an undo draws the current scene, and not the previous one.
Verified by measurement on one delegate on 2026-10-04, under the lock of the gate, by builds and a
counter that are not kept. A build that walks to capacity drove the measured page 3 times, and the
build without it 11 times. A count over the largest demo on the C backend gave the comparisons.

## Memory and allocation

The interactive render loop allocates nothing. `format.nim` wraps the C `snprintf`, so the number
formatting of each frame writes into stack buffers. Message building that a button drives still uses
`strformat`, once for each click, since the result must become a `string` for `addObject`.

`arena.nim` holds a plain `array[N, byte]`, which `push[T]` carves and `reset` reclaims. The desktop
holds its memory in three regions, which the Architect set on pull request 565:

| Region | Capacity | Backs | Reclaimed |
|---|---|---|---|
| program arena | `CAPACITY_ARENA_PROGRAM` 224 MiB | readback, GIF frames, export scratch | never |
| frame arenas | `CAPACITY_ARENA_FRAME` 886 KiB × 2 | placements, then `DrawScratch` | in turn |
| object pool | `sizeof(Scene)` 1.15 MiB | each object, by its handle | by handle |

**Every byte count that a reader sees is in KiB and MiB, as IEC 80000-13 names them.** Each one
divides by 1024 or by 1048576. That holds for the memory rows and the pool line of the window, and
for the heap row of the page. A `KB` or `MB` there reads as thousands, which the count is not. The
pool line puts its figure for each handle on a line of its own. The longer unit then stays inside
the panel at a full pool.

The storyboard run sizes the program capacity from its own `arena.used + bytes_needed`, and not from
a round number. The **frame arenas** reclaim on the way *in*. What one frame assembled stays
readable through the next, while the block that it moves to starts empty.

**The scratch of an export is one stretch of the program arena.** It is carved once, and each export
overwrites it from its start. At most one export runs in a frame, and each one finishes inside its
own call. Rejected: an arena for exports alone, which adds a fourth region for no gain. Rejected:
the scratch in the frame arenas, where each of the two would reserve it for a turn that an export
never uses. Cost: 64 MiB that the program arena holds for the whole run.

A frame carves 666,728 bytes sixty times a second: 645,120 of placements and 21,608 of
`DrawScratch`, as `sizeof` reads them. That is also the peak of each frame arena, since a frame
carves each once. The largest carver of `DrawScratch` is the `LINES_GRID_MAX` chords of one lattice
family. The capture loop of the storyboard turns the frame arenas over in its own `renderAt`. Each
frame arena is one placement for each handle and 256 KiB for the scratch, which is 907,264 bytes at
5040 handles. A static check holds that both fit, and that a placement holds no reference, since
carved memory is never traced.

The placements stand twice on both front-ends, for this frame and the frame before (Render paths).
That is 128 bytes for each of 5040 handles, or 645,120 bytes for each block. On the desktop both
blocks sit inside the frame arenas, and `BYTES_MEMORY_TOTAL` counts them there.

**The object pool is the arena of `Scene`, with a free list** (Scene storage). Cost: the whole pool,
1.15 MiB, at any count of objects, and a copy of it in each step of the undo timeline.

**The undo timeline is the largest reservation that the binary makes.** A `Scene` at 5040 handles is
1.15 MiB as a C struct, which `sizeof` reports as 1,204,616 bytes on the release compiler. A `Step`
is a `Scene` beside a `Camera` of twelve floats, eight of them the motor, and `CAPACITY_HISTORY` is
32 of them. They reserve 36.8 MiB, which is 38,549,528 bytes, against 6.2 MiB for both mesh sets.

In the browser the same timeline is about 105 MB of JS heap. The depth stays at 32, because an edit
costs nothing for each step (Undo/redo), so what remains is a flat reservation. The lever is linear,
at about 1.15 MiB of address space and 3.3 MB of JS heap for each step. `BYTES_MEMORY_TOTAL` counts
it, because a figure that leaves out its own largest term is worse than no figure.

The LZW dictionary of GIF is a fixed open-addressed hash table, with `CAPACITY_DICTIONARY` at 8192
and multiplicative hashing after Knuth. It is not an arena, because it probes at random within a
frame rather than appends by bump alone. **LZW early change**: the format widens the code size one
symbol earlier on a decode than on an encode. A decoder written from scratch in the suite
round-trips a real frame past the point of growth.

*Checked.* Verified on 2026-10-06 by `xvfb-run -a binaries/rga_visualiser --storyboard:<dir>`: 12
PNG frames and a GIF go through the export scratch in one process. With its overwrite taken out, the
ninth PNG asks for 70,010,991 bytes of 67,108,864, and the arena stops it. Verified by `suites.nim`:
the frame arenas keep the bytes of the last frame, and the GIF round-trip holds. Verified by
`sizeof`: the sizes of the struct and of the timeline, and on 2026-10-06, 128 bytes for a placement
and 21,608 for `DrawScratch`. Assumed: the JS heap figure, which extrapolates the 85 MB that the
live page measured at load on a layout without the placing stamps.

## Colour palette

Five hues are assignable, `Rose`, `Copper`, `Olive`, `Jade` and `Cobalt`, beside `Backdrop`,
`AxisX/Y/Z`, `Grid`, `Guide`, `Outline` and `Invalid`. One `Ink` enum holds them all
(`mesh.LUT_RGBA_BY_INK`).

**`Invalid` is a reserved magenta**, so a reader who sees it knows that an object is wrong. The drag
band wears it over a pair that makes nothing (Interaction model), and nothing else does. The
interface never leans on it alone, because magenta reads as *blue* under deuteranopia, and the
preview also fails to appear beside it.

The reservation cost three hues. `Violet` and `Cerise` measured CVD ΔE 10.2 and 8.3 from magenta.
`Cobalt` sits 88° of hue away and still measured **6.6**, because blue and magenta converge under
deuteranopia. So `Cobalt` is derived lighter and bluer (`#5b90c7`), which reopens the pair to 14.4.

**Do not fill the rest of the arc back up to eight.** A set of seven hues put `Olive` and a new
yellow-green at CVD ΔE 0.4, and two blues at normal-vision ΔE 5.6. The axis hues flank the reserved
arc on both sides, and leave one warm arc and one cool arc, 162° in total. Five hues are what fits.

**A structural slot is never offered as the colour of an object.** `mesh` names the boundary once,
in `INK_CATEGORICAL_FIRST`, `COUNT_INK_CATEGORICAL`, `inkCategorical` and `categoricalIndex`, and
both pickers and `inkCycled` derive from it. The structural slots are declared first and the
categorical run last, so the run is one block, which a `static: doAssert` on the count holds.

The floors below were derived under the `check_palette` of the prototype, which measured them on
every run there. Nothing here measures them again, so a hue moved here is a hue unchecked.

1. Every pair among the five clears normal-vision ΔE ≥ 15 and ≥ 20° of hue. Lightness can never
   stand in for a difference of hue. `Jade` against `Copper` at CVD ΔE 7.6 sits inside the band of 6
   to 8, which is legal with a secondary encoding. Shape and screen position are that encoding.
   `Rose` sits at contrast 2.78 against the backdrop, under 3:1, and its row label is always present
   as the relief.
2. Axis safety. Each hue clears ≥ 20° and a lower floor of ΔE 4.0 against `AxisX/Y/Z`, so nothing
   mistakes a thin line for a filled object. That floor is looser than the object floor on purpose,
   and it is what freed most of the wheel. One floor for everything crammed every hue into an arc of
   teal, blue and violet.
3. Every assignable hue clears CVD ΔE ≥ 13 from `Invalid`. The worst are `Cobalt` at 14.4 and `Rose`
   at 15.2.
4. Furniture clears ΔE ≥ 8.0 against `Backdrop`. The axes land between 15.7 and 25.3.

**The one declared exception.** `Jade` and `Cobalt` separate by only **3.7 ΔE under tritanopia**,
and the project carries that rather than repaints. The pair clears 12.7 under red-green deficiency
and 15.8 to typical vision. Tritanopia affects fewer than one reader in ten thousand, and every
object carries shape, position and label.

The floors were measured under **Machado, Oliveira and Fernandes (2009) at severity 1.0**.
Viénot-1999 puts `Jade` against `Cobalt` at 0.9 ΔE where Machado puts it at 12.7, so the model is
part of the standard. Red-green deficiency carries the floors, as the minimum of protan and deutan,
and tritanopia is measured on its own.

**Axis colours are dimmed and desaturated at compile time** through `axisTinted`, from
`MUTE_AXIS_TOWARD_GREY` at 0.45 and `SCALE_AXIS_LUMINANCE` at 0.50. The constants are the source,
and not documentation of literals applied by hand. The floors settled them, and not the eye. A
luminance of 0.62 read well and *failed*, because the dimming walked the green and blue axes onto
the luminance of `Rose`. That is 3.5 and 3.3 ΔE under red-green, against the floor of 4.0.

`Ink.Outline` is kept although nothing draws with it. To remove an entry next to the categorical run
shifts every later ordinal and corrupts the colours of a saved `.rgascene`. **Seed hues** are not
arbitrary: `ground` keeps the olive of `INK_SEED_GROUND`, and `o` the copper of `INK_SEED_ORIGIN`.

*Checked.* Verified then, by the `check_palette` of the prototype: every floor above, and the
failures of the seven-hue set and of the one floor. Verified by a render: the axis dimming, and that
a grid alpha of 0.55 read as absent (Geometry and drawing). Assumed: the prevalence figure for
tritanopia, which comes from the literature. **Unverified here**: no tool in this repository
measures a floor again.

## Geometry and drawing

**Plane.** A solid rim (`RingRecord`) with a flat translucent fill (`DiscRecord`, `ALPHA_VEIL` at
0.16), and no crosshair, no grid and no normal shaft. The radius is fixed at `EXTENT_PLANE`, 8 world
units about the anchor of the plane. It is a rendering choice in `mesh` and `picking` alone. Every
construction path reads the full `Multivector`, so a meet lands correctly far outside the drawn
disc. Rejected: a radius that scales with the camera, which resizes a plane as the camera orbits.

**A meet is read back as the point that it names before anything asks a signed question of it.** The
weight of a meet carries the orientation of the crossing, and `unitize` divides by the *norm* of the
weight, so that sign survives. `depthAgainst` is linear in its point. A meet passed on as it came
therefore reports its depth **negated** on every plane met from behind its normal. Such a plane
picks at 0 of 462 sampled pixels, while the ground plane hides the fault.

**Line.** Two segments meet on the line at its support, and each runs out to one of the two
vanishing points of the line, `eye ± radius_horizon*axis`. A vanishing point is a property of the
*eye*, which forces this shape. An end anchored at a fixed reach from the support stops short of it,
by about 6.7° for a support 40 units out.

Each segment lies in the plane through the eye that contains the line. The pair therefore draws over
the true projection of the line, within 1e-16 of screen skew. That skew holds only while the
near-plane crossing is stepped from the end that it stands nearer (Records and shaders). Stepped
from the far end, the two halves part on screen. The far ends sit off the line along the view ray,
so occlusion is approximate there. `picking` tests both halves through `clipToEyeSide`, a near-plane
clip written by hand, because this reach puts an endpoint behind the eye.

**Horizon objects are drawn as sky.** A horizon point is a fixed star at `eye +
radius_horizon*heading`. A horizon line is a great circle about the eye. A horizon plane is a
full-sphere dome (`DomeRecord`, `ALPHA_VEIL_SKY` at 0.22), and not a hemisphere. An orbit view sits
elevated and tilted down, so a dome cut at the horizontal loses sky that the camera sees. All three
are anchored to the eye in every frame.

**Draw-order invariant.** Translucent veils blend in scene order with depth writes off. So
`assembleMeshes` and `bridge.nimBuildFrame` insert the dome of any visible horizon plane **first**.
The fill of an ordinary plane then blends over the sky, whatever handles they occupy.

**Muting.** `mesh.muted()` blends toward the luminance of the colour itself (`MUTE_DESATURATION`
0.6), and `FRACTION_DIMMED_ALPHA` is 0.55. Rejected: `Ink.Grid` in place of the colour, which makes
a muted object read as the grid.

**Draw sizes live in `mesh.nim`, not `renderer.nim`.** They are `DIAMETER_POINT_LEAST` 6.0,
`WIDTH_LINE_OBJECT` 2.5 and `WIDTH_LINE_FURNITURE` 1.5, in *framebuffer* pixels. A `static:
doAssert` holds that object lines exceed furniture lines, and `marker` derives every clearance from
them.

**Every point has a radius in world units, and is drawn in perspective.** `Scene.radii` holds one
radius for each handle. `RADIUS_OBJECT_DEFAULT` is 0.08, what a nine-pixel sprite spans at the
opening camera, so an old scene opens looking as it did. Both editors carry a `size` field, bounded
below at `RADIUS_OBJECT_LEAST` 10⁻⁹, because the model refuses zero outright. `RADIUS_OBJECT_MOST`
1e6 exists because the drag widget of ImGui reads *no upper bound* as *no bounds*.

A point crosses the wire as one record (`Vertex`), and both front-ends draw it as an **instanced
camera-facing quad** from `mesh.pointCorners`. The vertex shader takes `radius = max(own,
½·DIAMETER_POINT_LEAST·world_per_pixel)` at the depth of the point, and the fragment stage discards
outside the unit circle. The rule is stated once in Nim, as `radiusDrawnAt` and `radiusPixelsAt`,
and the two shaders are sibling copies of it. So the size is *fixed in the world* and shrinks with
distance, and a floor of six pixels keeps a distant star a readable dot. That floor is the one
departure from pure perspective, and it keeps 4,900 catalogue stars visible. Pick, marker, cull and
framing all follow the drawn disc.

  **What is under the pointer is what is picked.** Take the cursor inside the drawn disc of some
  point. The nearest such disc to the eye then wins over every point that the cursor is not inside,
  however near their centres. That is the `consider` of `picking.pickWalk`. Rejected: distance to
  centres alone, which lets a background star win through the disc of a planet.

  A point covered by a nearer disc that is narrower than a fingertip is still a rival to the crowd
  rule of touch. One covered by a body as wide as a fingertip is not (`coverOf`). The walk gathers
  the discs under the cursor into a fixed array of eight (`Hiders`) as it goes. Depth in the point
  branch is read off the homogeneous weight of the projection (`depthAlongSight`), so the branch
  builds nothing for each point.

  **Cost, under SwiftShader.** Every CPU phase is unchanged within noise against sprites. With the
  cull off, the p50 of the whole frame at the largest demo rose. It went from a range of 53 to 55 ms
  to a range of 103 to 108 ms. The hypothesis is overhead for each instance in the software
  rasteriser. **Unmeasured on a device**, and the `render` row of the drawer is where it shows.

**Every point is shaded as a sphere lit from world-up.** The light is `camera.UP_WORLD`, one
direction for every point. The vertex shader on both front-ends turns it into the basis of the
camera, as the z components of the three axes. The fragment stage applies Lambert over an ambient
floor, `FRACTION_AMBIENT_SHADE` at 0.25. The underside then still reads as a body in its own hue,
rather than a hole in the field.

Nothing in the scene carries a light, because shading is presentation that gives a disc its sphere,
and not a property of any object. Rejected: a point that shines on the others, as format versions 5
and 6 carried, under which that point itself drew flat. The saving is three floats fewer for each
point record, and no relighting pass for each edit.

**Furniture**, the world axes and the lattice on each selected plane, reaches `extent_furniture`,
which is `FACTOR_CLIP_FAR` orbit distances. It is drawn as **fog about the eye**, not a halo about
the origin. A halo makes the origin a place the reader may not leave. It is not the far clip, which
also reaches the farthest object of the scene. The demo reaches millions of units. A lattice sized
to that puts its cell at a hundred thousand, with no line under any camera in the system of Sol.

**The world rules no ground.** Its origin is Sol, and no plane through it is anybody's floor.
`framing.addLatticesPicked` rules each visible finite plane that is selected, and the grid chip
turns those lattices on and off. `tessellate.addLattice` lays lines in the plane's own frame
(`boundary.frame`), on multiples of the cell from its anchor, the foot of the world origin. So a
plane whose normal is a world axis is ruled along the other two, and its lines stay where the world
puts them. Rejected: a grid on `z = 0`, which read as a floor in a scene that has none.

The fog holds full strength within `FRACTION_GRID_FADE_START` at 0.06 of the extent, and is gone by
`FRACTION_GRID_FADE_END` at 0.20. Those are 1.14 and 3.8 orbit distances. At 0.03 and 0.12 the
lattice at the pivot reads as absent.

The fade runs in the fragment shader against the own world position of the fragment, and holds to
`alphaGridFade` as its reference. A `fog` flag on each record says who fades, so furniture and scene
ribbons share one buffer. `addLattice` lays one record for each line, inside the disc that the fog
leaves on the plane (`radiusOnPlaneFor`). A lattice through the world origin skips its two lines
along the world axes, which coincide with the axes.

**`driveGround` counts the lines that the uploaded records lie on.** Two records lie on one line
where they run one way, at a sine under 0.001, and stand under 1 unit apart. That is a tenth of the
least cell. A line cut into pieces faded apart lays several records on one line. That fault read
26.1 ms of moving grid at 300, against a bound of 26 ms. Cut in two, it lays 482 records on 242
lines there, which the cap of 482 in `driveSceneryBound` allows.

**The cell is `SIZE_CELL_GRID` at 10.0, at every reach that a reader works at.** A cell that walks
with the reach re-scales the plane under a reader as they dolly, and a fixed cell is a ruler. Ten
rather than a hundred, by a render of both. At the opening reach of about 72 units, a hundred-unit
cell put at most one line in view.

`CELLS_GRID_HALF_MAX` at 120 bounds the lines laid, which is `LINES_GRID_MAX` at 241 for each
family. It is **spent on the cell, and not on the reach**: `sizeCellGridFor` steps the cell by
**decades**, from 1,200 units of reach. Decades nest, so a step coarsens what is drawn without
moving a line that the reader was measuring against. Rejected: a cut of the *reach*, which leaves a
camera past 1,200 units with the lattice stopping short.

In Chromium on 2026-10-01, `driveGround` on the first plane counts 382 records at orbit distance
300, and 127 at 1,000. It counts 62, 49 and 127 at 5,000, 40,000 and 10⁶, each on a line of its own.

`addLattice` dims the lattice by `ALPHA_GRID` at 0.75, because 0.55 read as absent. **The world axes
are reference**: they fade and cut off on the schedule of the lattice, so all the furniture ends at
one horizon. Unfaded, an axis is the brightest mark in any frame, and reads as a drawn line.

**The scale bar is the main instrument**, at the bottom left of both front-ends. It draws a length
of the world at its true screen length, with the length written under it. `camera.rulerFor` measures
at the depth of `scaleLocal`, which the frustum and the furniture read. `mesh.spanRulerFor` steps it
1-2-5 by decade to land at or under `PIXELS_RULER_WANTED` at 130 px, as a map scale does. Rejected:
the depth under the pointer, which changes the claim over a still view. Rejected: one grid cell,
which ran 11,983 px at orbit distance 3.

`wording.appendRuler` writes the label for both front-ends. The page reads the bar through
`nimRuler` and `nimRulerReading`, in CSS pixels, and the desktop draws it with lines of Dear ImGui.
**The drawer draws over it** (`z-index` 3 under the 4 of the drawer), and does not hide it. The bar
reads once the reader closes the panel.

*Checked.* Verified by `suites.nim`:

- a meet far outside the drawn disc, from both sides of one plane;
- both halves of a line pickable;
- the dome of the horizon plane inserted first;
- the segment count of the great circle after the eye cut;
- the fog radii at an eye inside its own fog;
- a star behind a wider disc unpicked with one rival, and a moon in front of it picked with two;
- a tilted plane's lattice lies in that plane, on multiples of the cell along its own axes;
- a horizon plane, a point and a hidden plane get no lattice, and a label reads "1 unit".

Verified by driven check:

- the plane pick from either side, with a canvas sweep for a pixel that picks the plane it built;
- the scale bar's length against its label at 19 and 4,000 units, layered under the open drawer;
- no lattice with nothing selected, and a selected plane ruled at every distance from 19 to 10⁶;
- one record for each lattice line at each of those distances, 382 on 382 at 300;
- forty-eight hover samples across the disc of Jupiter, which find nothing deeper;
- the upper half of a wide disc brighter than its lower half on the page, which is world-up on
  screen from the opening camera.

Assumed: the fade fractions, the cell size, the lattice alpha and the axis dimming. They were
chosen by eye on a render, and no check holds them. The occlusion error at the far ends is assumed
to be tolerable, and is unmeasured.

## Camera

`camera.nim` holds an orbit camera. The opening placement is `initCameraDefault`, which both entry
points and `home` read with the frame that they draw. Its eye stands along (10, 15, 6) from the
pivot at (0, 0, 1). A frame at least as wide as tall puts it at (10, 15, 7), 19 units out.

**A narrow frame opens farther out.** The field of view is vertical, so a frame narrower than tall
shows less across. The eye stands out along the same line until a sphere of `RADIUS_OPENING`, 8.6
about the pivot, spans `FRACTION_OPENING`, 0.92, of the width. The rim of the ground reaches 8.53 of
it, and the points stand within 5.6. An upright phone of 393 by 852 px opens 49.7 units out, and 768
by 1024 px opens 31.3 out. Height never decides, because the seed scene is flat and seen from above,
and fits at 19 units on every frame tried.

The frame is read at open and on `home`, and never between. Rejected: one farther eye for every
screen, which leaves the scene a quarter of the height of a desktop window.

**The stance is one rigid motion and one depth.** `Camera.motor` carries a reference stance to where
the camera stands, and holds where the eye is and which way it faces together. `depth_pivot` says
how far along the sight line the pivot stands. Everything else is read back: the eye, the three
axes, the pivot, and both orbit angles. A value stored beside the stance can go stale against it.

The dolly slides the eye and names the new separation, and the pivot follows. So `repivotToDepth` is
one assignment, and `travelToward` needs no pivot arithmetic.

The reference stance puts the eye at the world origin, with `RIGHT_REFERENCE` at +y, `UP_REFERENCE`
at +z and `FORWARD_REFERENCE` at −x. Rejected: the reference triple of OpenGL, which puts a fixed
120 degree turn in every construction for no gain. `initMatrixView` reads the axes, and never the
motor.

**An eye and a pivot name a stance, and no angle does.** `motorFacing` builds the motion as three
motions, and the first two turn about lines through the reference eye, so neither moves it:

- a turn about the line along +y, by the rise of the heading;
- a turn about the line along world up, by its bearing;
- a slide of the reference eye to the eye.

The heading is the difference of the two points, and its rise and bearing are read out of its inner
products with the reference axes. The stance is level, with its across axis horizontal. A heading
along world up has no bearing and turns by none, so the frame stays orthonormal, and nothing clamps.
`stanceFacing` adds the separation, which is `distanceBetween` the two points. Rejected: a stance
named by pivot, distance, azimuth and elevation, which carries no roll and collapses at the pole. It
needs a clamp, `ELEVATION_LIMIT`, that the motor never needs.

**The azimuth reads back in (−π, π].** It comes off the sight direction through `arctan2`, which
bounds it, and the reading of the panel wraps there too. The ease drives from stored stances rather
than from the camera (`CameraTween`), so the wrap does not reach it.

**The frame needs no clamp.** Three reference directions carried through a rigid motion stay
orthonormal and weightless, so no join can refuse and no antidual sign needs pinning. Rejected:
joins against world up, which collapse as the sight axis nears it.

**Every verb composes the motion, `orbit` included.** `orbit` turns about two lines through the
pivot, along the camera's own up and its own across. `look` turns about the same two through the
eye. A roll survives it.

The axis of each turn is the camera's own, so the orbit of a mouse reads as a trackball, not a
turntable. The azimuth is not linear in a horizontal drag off level. Two thousand steps of one angle
still compose to one turn of their sum, because a turn leaves its own axis standing.

**The motor is eight named floats, and not a `Multivector` field.** `Camera` crosses 55 by-value
parameters, and the JavaScript backend deep-copies every one through `nimCopy`. Eight floats in one
object cost what the three of a `Position` cost. `boundary.nim` lifts them where the algebra runs,
once for each frame, not for each object. `picking.pickWalk` derives the eye and frame before its
walk, and `drawExtentFor` hands every reader one extent, as `mesh.directionAcross` does.

**Each frame reads the eye and frame once, and hands both to every reader.** Each front-end calls
`moveOriginView` after the ease moves the camera. It moves the view origin to the eye, and reads the
eye and frame about it off the same lift (Origins). It hands both to the near reach, the extent, the
frustum and the transform, because each read of `eye` or `frame` lifts the motor again. A hold of
the aim can move the camera, so a front-end reads again only where the motor moved. Rejected: the
first read for the transform too, which draws where the camera stood before the hold.

**The overlay shares its extent within a frame by what the camera holds, and never by what it reads
out.** The browser's `SettingsOverlay` takes the view origin, the motor and the depth. Those are the
stance itself, so two readings that agree on them agree on the eye, every axis, the pivot and both
angles. Rejected: a key built from the pivot and the two angles, which derives the eye and the frame
for each field it reads. `ensureViewOverlay` runs for every overlay call, so such a key costs about
eighteen sandwiches to decide whether to skip four. `drivePinAnchor` allows an anchor lookup 15 µs.

**An orbit distance has a floor and no ceiling.** `DISTANCE_LIMIT_NEAR` at 10⁻¹³ is geometry: at
zero the eye coincides with its pivot, and every direction that `camera.frame` derives collapses.
`distanceHeld` is the one statement of it.

It is tiny rather than small: 1.5 cm, so an object a metre wide fills the frame. The stance, the
records and the transform are held about the view origin, near the eye. So doubles and float32 hold
that close-up wherever the eye stands (Origins). The near clip is a four-hundredth of the local
scale, and the logarithmic depth spans it out to a far bound millions of units off. There is no
ceiling, which would read as a camera bounded to a region, and which nothing downstream needs.

**One transform serves the GPU, the picks and markers, about the view origin.** Its translation is
the remainder of the eye about that origin, under half a world step. `Matrix4` stays in doubles,
since picking reads it on the CPU. Rejected: a moving world origin, which rewrites every stored
multivector each frame. Wheeled out to 3 × 10¹⁹ the view empties to a speck, and `home` returns.

**Clip planes follow the orbit distance, and nothing clips at the far bound.** `FACTOR_CLIP_NEAR` is
1/400 of the orbit distance, and `FACTOR_CLIP_FAR` is 20 times it. Where the distance of the eye to
the origin plus the reach of the scene is farther, that answers instead, times `MARGIN_REACH_FAR` at
1.05. Both are derived, and never stored. The projection has no far plane: its depth climbs toward 1
− `SLACK_CLIP_FAR`, which is 1/1024, and never reaches it.

Rejected: `(f + n)/(f − n)` with the far plane at the reach of the star field. It sat the farthest
stars and the dome within two float32 ulps of that plane. The rounding of an Android GPU clipped
them, so points flickered as the camera moved, and the dome drew in patches. Rejected: twenty orbit
distances alone. Six notches in at the centre of the demo, with the starfield 3,000 units across, it
draws 49 of 4,938 points. The reach draws 367.

**The reach of the scene is the caller's, and never the camera's.** Each front-end measures it on an
edit (`framing.reachOf`), and hands it to `drawExtentFor`, `viewBoundsFor` and the furniture key. A
field on the camera is dropped by `home`, and by every path that replaces the camera value.

**Depth is logarithmic, and written for each fragment.** Every fragment shader on both front-ends
writes `camera.depthOf` of its own view depth, which is `log2(D / near) / log2(far / near)` scaled
to clip depth. It writes through `EXT_frag_depth` or through the `gl_FragDepth` of GL 3.3, so
resolution is a fixed fraction of distance at every distance.

Rejected: linear depth with the near plane raised to hold the ratio at 100,000, which spends nearly
every step inside the first orbit distances. An Android GPU then dropped the whole star field from
beside a far star. Rejected: depth written in the clip position, which the clipper interpolates
linearly. It cut a corner behind the eye, and the disc ended at a hard chord.

**Keys move by shared rates for each second**: `TURN_SECOND` 1.4, `RISE_SECOND` 1.1, `ROLL_SECOND`
1.4, `FACTOR_DOLLY_SECOND` 4.0, and `FACTOR_HASTE` 4.0 under shift. Each frame scales them by the
elapsed time, so a hold covers the same ground at 60 Hz and 144 Hz. The dolly compounds as
`pow(factor, seconds)`. A drag has no rate: it carries what it holds one pixel for one (Drags).

**The panel holds the motor as the value.** Both front-ends show all sixteen coefficients of
`Camera.motor`, in the grid that objects use, and each can be typed. `motorRigid` settles what is
typed on the rigid motion it names. Odd grades drop, and the even part passes through the `unitize`,
`log` and `exp` of the library. `unitize` alone leaves a slide that the turn does not allow, which
carries the eye off an orthonormal frame.

Only the changed coefficient is written into the live motor. On the desktop, each field holds a
double, and never rounds to the four digits that it shows.

Azimuth and elevation stand beside it as readings in degrees, and are never typed, because two
numbers name no roll. The separation shows only with a selection, which the frame rule measures it
from. The speed of the ship shows only without one, as a multiple of `SPEED_LIGHT`
(`interaction.speedFlying`), whether a key is held or not.

*Checked.* Verified by `suites.nim`:

- a stance named by eye and pivot stands at the eye, faces the pivot, and is level and orthonormal.
  That holds over 416 stances, from 26 directions and over five decades, both poles among them;
- 2,000 orbit steps land where their sum says, and the pivot, separation and level horizon survive;
- the eight floats and the multivector say one motion, which reads unit;
- the logarithmic depth maps near to −1 and far to +1;
- it is monotone across every decade that the demo spans;
- it keeps Io before Jupiter, and a star before the dome, by more than a 16-bit step;
- the flattened float32 matrix keeps the farthest star and the dome half the slack inside the far
  plane, at four orbit distances;
- `norm(eye − pivot)` equals the held distance after a floored dolly;
- an object a metre wide two million units out fills the frame, with the near clip short of it. Its
  two sides stand more than a sixteen-bit step apart in depth;
- a typed motor settles on the rigid motion it names, with the frame orthonormal after any typed
  slide, and a weightless one refused;
- every seed object stands inside the opening frame, on six frames from upright phones to wide
  desktops. A frame wider than tall keeps 19 units;
- the far bound reaches the scene's reach that its caller passes, however close the orbit is;
- the extent, transform and view-origin move, given the camera alone, each lift its motor once;
- the readers of a frame, given its eye and frame, lift the motor no more.

Verified by driven checks:

- the sky is drawn behind a far star;
- the disc of the ecliptic reaches under a camera 1.5 units off Sol, 0.3 and 0.0003 rad up;
- an anchor lookup takes 3.750 µs, against 488.250 µs keyed on the read-out pivot and angles;
- the view section shows sixteen coefficients, and a typed one settles on a unit motor;
- it reads speed with nothing selected, and distance with a selection;
- each frame build of the page lifts the motor once, still or orbiting, against 11 on `4a478976`.

Verified by a probe in Chromium under SwiftShader on 2026-10-04, on an Intel Xeon at 2.10 GHz,
against `4a478976`. Over 80 frames, the records and the transform that each frame hands the GPU
match in both builds, bit for bit. Assumed: that no reader wants a ceiling on the separation.
Assumed: that the desktop hands its five readers one read of the stance, which no check counts.

## Zoom

**In free flight, the wheel zooms toward the object the pointer is over**, which is the map reading
of a zoom. `picking.anchorZoomAt` answers that object alone, at any depth, since the wheel refers to
the object under the pointer. Where none answers, the wheel does nothing, since it has nothing to
come in to (repository issue 535). A pinch is no zoom of its own: its two fingers hold what each
touched (Two fingers). Rejected: the ground at `z = 0`, which the world does not have, and the level
through the pivot, which names no place a reader points at.

**One notch zooms the same on both front-ends** (`interaction.factorWheel`). Each notch scales the
separation by `FACTOR_DOLLY_NOTCH` 1.12. The desktop reads whole notches from SDL. The page counts
`PIXELS_NOTCH` 100 px, or `LINES_NOTCH` 3 lines, as one notch (`bridge.nimNotchesWheel`). Both
counts are expected and not measured, since no real wheel reaches this container.

Rejected: a rate of its own on the page, `exp(0.0012 × travel)`, which drifted from the desktop by
2% over three notches. Verified by driven check: three notches of 100 px scale the separation by
0.711780248 on the page, and the desktop's `--drive-wheel` holds the same rule. Three lines scale
the page as one notch does. Verified by `suites.nim`: notches compose, so a frame that sums them
zooms as each notch would.

**With a selection, the wheel dollies about the pivot, wherever the pointer stands**
(`interaction.dollyAbout`). The pivot stands on what is picked, so the orbit stays on it however far
the wheel goes. Rejected: a zoom toward the object under the pointer, which slides the eye along its
own line to that object. The sight then leaves what is picked.

**With a selection, an object counts only where its depth is within `FACTOR_ANCHOR_DEPTH` 2 of the
orbit distance, either way.** The band holds for the floor of the wheel, and for what two fingers
hold. Horizon objects are refused, because they are at no place. Free flight takes no band, because
key flight keeps the separation, so a band about it would refuse every object after a flight.

**The zoom stops where a point fills the frame**, because nearer shows nothing more of it. There its
sphere reaches every corner, and the point is backdrop (Picking). `picking.depthFilling` solves that
depth, as the inverse of `isCoveringView`. Free flight floors at the point under the pointer, and a
selection at the point in the middle of the frame (`AnchorZoom.floor_reach`). `framing.holdFilled`
holds the fill for a point picked alone under every other move: a drag, a key and a pinch.

The fill is a depth along the sight, and free flight floors a reach. A move of the eye on its line
to the anchor scales both by one factor. So the floor is the fill times the reach over the depth.
Rejected: the fill as the reach, under which a point 17° off the middle stops 4% nearer than the
fill. The hold then carries the eye back off the line of the pointer. The point in the middle of the
frame stands on the sight, where its reach is its depth.

The hold takes a point picked alone. With more picked, the frame rule holds the group, and only the
wheel stops at the fill of a point. Rejected: the drawn radius as the floor of a point, under which
the wheel goes on past the fill to the surface.

**Flight goes on into a point**, by the Architect's ruling: the cap is on the zoom, and flight is
travel. Nothing is picked to hold, and the wheel and the pinch still stop at the fill. Rejected: a
floor on flight at the fill of the point ahead, which stops it at each point of a field.

*Checked.* Verified by `suites.nim`:

- 40 notches with a selection stop where the point in the middle fills the frame;
- with a selection, notches in over another object and out over sky keep the pivot on the point
  picked, and the sight unturned;
- 10 notches in, 20 out and 10 in again bring the distance back to where it began;
- in free flight, 40 notches onto a point off the middle stop at its fill, with the point 0.5 px or
  less from the pointer;
- a point picked alone is held at the fill from half of it, and left where it stands from 19.

Verified by driven checks:

- an object under the pointer drifts 0.000 px across a 3.2× zoom, against 1.957 px with the
  pivot-level anchor;
- a wheel back out returns to distance 19.000 and pivot (0, 0, 1);
- 40 notches onto a point picked alone stop at a depth of 0.115882196, against a fill of 0.115882251
  read through float32. Ten more notches move the eye 0;
- with `b` selected, 10 notches in over `c`, 20 out over sky and 10 in leave the pivot 0 off `b`,
  and the distance 19.000. A zoom toward the pointer leaves the pivot 6.07 units off, at a distance
  of 16.368.

## Free flight

**Two states, and the selection picks between them.** With nothing selected the camera flies:
`look`, `roll` and `travel` turn and slide about its own axes. With a selection it orbits.

**Flight turns about a line through the eye.** `turnedAboutEye` joins the eye with a carried axis
and turns about that line, so the eye stands where it stands and the frame stays orthonormal. `look`
reads the frame again between its two turns, because the across axis after a yaw is not the one
before it. A pitch about the stale one rolls the view.

`look` takes the two arguments that `orbit` takes, with the same signs, so one held key feeds either
verb as the selection comes and goes. The axes are the camera's own, so there is no pole and no
clamp. Eight pitches of a quarter radian compose to exactly two radians, past straight down.

**The speed climbs toward the speed of the ship and never reaches it.** `speedTravelling` is that
speed times `1 − e^(−t/τ)`, where τ is `SECONDS_SPEED_RISE`, 0.6 s: 63 percent of it at one τ, and
95 percent at three. `distanceTravelled` integrates that across a frame rather than sampling it. A
144 Hz reader and a 60 Hz one then cover the same ground over the same hold. It is the rule that
`FACTOR_DOLLY_SECOND` compounds under.

**The speed of the ship is the camera's own** (repository issue 535). `Interaction.speed_ship` is
the speed that key flight climbs toward, and neither the pointer nor the pivot sets it. It opens at
`camera.speedOpening`, the separation of the opening view for each second: 19 units on a wide frame.
`home` leaves it, as it leaves the lens. Held `+` and `-` scale it by `FACTOR_DOLLY_SECOND`, 4 for
each second, and nothing moves while they do. With a selection, they dolly instead.

Rejected: a cap of 1.2 depths under the pointer, with the separation over empty sky. It ran down
toward zero as flight spent the separation. Rejected: a speed read from the nearest object, because
a ship needs no other object to move.

`SPEED_CEILING` is 300 000 units for each second, which crosses the reach of the star field, about
6.5 million units, in about 22 seconds. `SPEED_FLOOR` is the near floor for each second, which keeps
the speed off zero, so `+` climbs back from it by a factor. `SPEED_LIGHT` is 1/499 units for each
second, because light crosses an astronomical unit in 499 seconds. It is a reporting unit and never
a cap, and the ceiling is about 1.5 × 10⁸ of it. A camera held to *c* would take two and a half
hours to cross the opening view of 19 units.

**The depth under the pointer is stamped in `updateHover`, while the camera stands.**
`Interaction.depth_pointer` is none where the pointer is over nothing, and a right drag in free
flight holds it as it begins. No speed reads it, so the pick does not run while a travel key is
held, as it does not run under a drag.

`seconds_travelling` is one age for the whole travel set, and not one for each key. So releasing `w`
and pressing `s` keeps the speed up, as a reader means by turning round mid-flight. `releaseKey`
zeroes it once the last travel key is up, so a flight resumed after a pause starts from rest.

**Flight carries the pivot along, in every direction.** `travel` slides the whole camera, so the
separation stays as it was. Rejected: flight ahead that holds the pivot and spends the separation,
which only runs the speed down.

**The frustum and the furniture read what stands ahead, not the separation.** `Camera.reach_near` is
the reach from the eye to the nearest drawn object ahead. `scaleLocal` hands it to the near clip,
the far clip, the depth mapping and the furniture's extent. So flying at a planet draws its near
clip in. The separation answers only where nothing is drawn ahead, as in an empty scene.

It is depth along the sight, and never distance, because what a reader turns away from is not drawn.
It is the middle of the object, with no drawn radius taken off. A camera at the surface of a planet
then reads its radius rather than zero. A near clip of one four-hundredth of that still holds the
whole planet. It is never the depth of the pointer, which would move the furniture and the depth
mapping at every pointer move of a still camera.

**It is read once for each frame, and never for each overlay call.** `reachNearOf` walks every
placement of the frame, and `ensureViewOverlay` runs many times over one frame: the anchor, each
marker, each pulse and the hover ring. An overlay call between frames reads the figure of the last
frame, as it reads the reach of the scene that frame measured.

**The wheel in free flight comes in to the object under the pointer, and does nothing without one**
(Zoom). `travelToward` carries the eye along its line to that object and holds it on its pixel. The
floor is the drawn radius of the object, so a run of notches stops at its surface. The floor of a
point is where its sphere fills the frame. Rejected: the ray of the pointer at the scale of the
separation where nothing stands there, which runs the separation down to its floor.

*Checked.* Verified by `suites.nim`:

- a look turns the sight about the camera's own axes and leaves the eye where it stands;
- eight quarter-radian pitches make two radians in `look` and `orbit`, past straight down;
- a look and an orbit swing the sight the same way, for both signs of the drag;
- a roll leaves the eye and the sight alone, and 64 steps of a whole turn return every axis;
- a travel step reads back along the rolled frame, to each of the three axes it was asked for;
- the speed is monotone and under its cap over 4 s, at 0.6321 and 0.9502 of it after one and three
  τ;
- 120 frames of one span cover what one frame of it covers, at three spans;
- flight steps at the ship's speed, whatever the pointer is over, at any separation;
- after its climb, a long flight at 19 covers 190.000 units in each 10 s span, and never stalls;
- `+` and `-` scale the ship's speed by 4 a second, in bounds, and dolly with a selection;
- the ship opens at the separation of the opening view, and `home` leaves its speed;
- a held `w` with nothing selected lies along the sight, and keeps the separation;
- a strafe leaves that separation alone;
- the wheel over empty sky with nothing selected does nothing over 200 notches, and a spread of two
  fingers there keeps the separation;
- free flight's wheel comes in to a point eight separations out, and the selection's dollies about
  the pivot instead;
- 40 notches onto a point stop where its sphere fills the frame, with the point held on its pixel;
- a travel toward three pixels holds what is under each within half a pixel, in and out;
- a travel in and back out returns the eye, and a factor of 1e-15 stops at the near floor;
- the frustum takes its scale from the nearest drawn object, and hands it back at zero;
- the far clip still reaches a scene 6.5 million units across, and both depth ends still land;
- the nearest reach is read ahead of the eye, never behind it, and never from a hidden object.

Verified by driven checks, in Chromium on 2026-10-07:

- 500 ms of `w` on the opening page moved the eye 3.012 units, 0.000000 across the sight line. The
  separation stayed at 19.0000;
- a second hold of 2 s flew 27.0067 units, as the first had;
- held `+` and `-` took the ship's speed from 19.000 to 37.790 and back, and moved the eye 0;
- twenty notches over empty sky, with nothing selected, moved the eye 0;
- eight notches low in the frame carried the separation from 19.00 to 4.14. They left the eye 2.063
  units off the sight axis, which a straight dolly cannot do;
- the opening page reads a local scale of 14.6842, not the separation of 19.000, and 3.012 units of
  flight drew it to 11.6727.

## Drags

**Every drag carries what it holds, one pixel for one, on both front-ends.** The left drag is
`interaction.turnFollowing` and the right is `panAcross`, and each picks its state inside itself.
Rejected: `orbit` for every drag, which swings the eye round the pivot where a reader means to turn.
Rejected: a rate, which turns the sight by an angle the screen does not show. On a phone a 60 by 40
px drag carries the picture of free aim 60.4 by 41.0 px. A rate carried it 542.4 by 411.8.

**A left drag turns about level axes, so it leaves no roll.** Turning about the camera's own axes
carries roll round with it. The roll that a closed loop leaves is the solid angle that loop
encloses. A loop of 0.3 radians leaves 0.0813, against 0.0822 enclosed: 4.7 degrees for each loop,
and 18.6 over four. That is the geometry of transport, not a fault, and `look` and `orbit` carry
exactly the same amount. Held keys keep it, with Q and E beside them.

A finger has no roll key beside it and wanders in curves, and both mice drag as a finger does. So
`turnFollowing` turns about world up and the level axis across the sight, and keeps any roll that a
twist or Q and E set. Each axis is the world axis nearest the camera's own, signed from the camera.
So the camera passes over the top, upside down on the far side, and the picture still follows the
drag. Rejected: the 0.008 radians for each pixel of the window about the camera's axes, since both
front-ends drag alike by the ruling of the Architect.

Rejected: the roll put back after each turn about the camera's own axes, which leaves the sight
sunk. On a 390 by 844 page in Chromium on 2026-09-24, over 2,000 turns of each, a free-aim turn took
0.45 to 0.48 ms. An orbit turn took 0.63 to 0.72 ms.

**`turnsCarrying` holds what a left drag took.** It pitches about the level axis until one direction
has the height of the other, then yaws about world up until their bearings meet. Of the two pitches
that reach that height, it takes the pair that turns least, so a drag that comes back brings the
camera back. Free aim holds the sky, and `lookCarrying` turns about the eye. Near the pole, a height
out of reach lets what the drag holds slip.

Orbit holds a point on a sphere about the pivot, since the pivot itself never moves under orbit.
`pointHeld` places it on the ray, on the near side of the sphere while the ray passes within
`radius/sqrt(2)` of the pivot. Beyond, a sheet of the same slope carries on, so a finger off the
sphere still turns the view. `radiusHeld` takes the reach of the selection from the pivot, which
`reachAimed` reads off the aim that framed it. It is no less than a third of the short side at the
depth of the pivot, and inside the separation of the eye.

**A right drag in free flight carries the depth it grabbed, one pixel for one.** `grabPan` takes
that depth at the press, while hover still reads what the pointer is over, or the depth of the pivot
over nothing. `panAcross` slides the camera square to the sight, by what one pixel spans at that
depth. A point at that depth then stays under the cursor, at any canvas height and field of view.
Rejected: a fixed share of the separation for each pixel, which matched the cursor at one canvas
height alone. It ran 1.74 times the cursor on 900 px at 45 degrees.

**A right drag with a selection turns across as a left drag along the row of the pivot.** The turn
goes first, through `turnFollowing`, for the same travel along that row. So the turn for each pixel
is that of the left drag, wherever the press lands. Rejected: a turn that carries the point the
press took. Near the top of the frame, it asks for a great yaw for each pixel across.

**Up and down stretches from the pivot.** `grabPan` takes the point that the orbit of a left drag
holds under the press. The dolly scales the height of that point over the row of the pivot as the
pointer's height scales, from where the turn left it. That is a pinch with one finger on the pivot,
so a drag away from the row zooms in either side of it. A vertical drag turns nothing and holds the
point exactly at the pointer's height, and a level drag zooms nothing. Rejected, by the Architect's
ruling: a zoom that keeps its direction wherever the press lands, which lets the point drift off.

**A vertical drag lets the point drift across.** The dolly spreads the point from the middle, so it
drifts toward the middle column or away as the zoom scales. Rejected: a turn that carries the point
back to the column of the pointer, which asks for the same great yaw.

**Heights are read no nearer the row of the pivot than `FRACTION_STRETCH_LEAST`, 5 percent of the
canvas height.** Nearer, one pixel asks for a zoom without bound. So one drag zooms at most tenfold
over half the height, on any canvas. Inside the band the vertical does nothing, and the point slips.

**The point is taken once, at the press.** Rejected: a point asked again at each step, which lies on
a sphere that the zoom resizes. The zoom then turns on the count of steps. On the middle column a
130 px drag ended at 11.73 in one step and 10.98 in twelve, and taken once at 11.73 in both.

A slant drag out and back returns the sight exactly, since each step turns as the row's left drag
does. Its separation keeps a trace of dollies read at two depths: the eye ends 0.0017 off at a
separation of 19. On the middle column the dolly moves alone, and returns exactly. Rejected: 0.006
radians and a factor of 1.004 for each pixel, which held the point under the cursor nowhere.

*Checked.* Verified by `suites.nim`:

- a left drag looks about the eye with nothing picked, and orbits the pivot with a pick;
- one loop of `look` or `orbit` leaves the solid angle it encloses, and four leave 0.324 radians;
- a drag's loop of pixels leaves none of it in either state, keeps the reader's roll, and closes;
- a finger's orbit keeps the point on its sphere under it, from three stances and two reaches;
- a finger's free aim keeps the sky it took under it, from three stances, in 1 step or 16;
- an orbit passes over the top and a look under its feet, and a drag goes through the pole;
- a right drag carries a point held at 2.5, 19 and 4,000 units to its pixel, within 0.01 px;
- a right drag takes the depth under the pointer, or the pivot's over nothing;
- a right drag with a selection turns as a left drag along the pivot's row, for the same travel. Its
  point's height scales as the pointer's does, within 0.01 px, on both sides of the row. A level
  drag zooms nothing, inside the band or outside it;
- a right drag with a selection keeps the point its press took. 12 slant steps turn as one left drag
  along the row, and leave the point within 0.5 px of the pointer's height. On the middle column 1
  step and 12 end alike, the sight stays, and out and back returns;
- a slant drag out and back returns the sight, and leaves the eye under 0.0025 off;
- a vertical right drag with a selection, out and in, 80 px off the middle column, leaves the sight
  and its up axis standing;
- a right drag with a selection down from the top, drifting across, turns at each of 24 steps as the
  row's left drag turns.

The window's drags call the same `turnFollowing` and `panAcross`, with the window's own pixels. No
drive reaches the window's mouse, so the suite holds that.

Verified by driven checks, in Chromium on 2026-09-26:

- a left drag with nothing picked turned the sight and moved the eye 0.000000 units;
- a left drag, and a finger with nothing picked, of 60 and 40 px carried the object beside them 59.1
  and 40.5 px;
- a 600 px finger swipe away and back brought the azimuth back to 0.9828 and elevation to 0.321289;
- a finger dragged down with an object picked carried the eye over the top, and the pivot 0.000000.

Verified by driven check, in Chromium on 2026-10-01: a right drag of 360.6 px over nothing carried
the pivot 360.6 px at its own depth. The fixed share of separation carried it 626.7 px.

Verified by driven check, in Chromium on 2026-10-02: three vertical right drags with one object
picked turned the view 0.000000. Each held its point 0.000 px off the cursor's height. The
separation went from 19.00 to 10.73, to 6.22, then out to 32.09. A drag down from the top, drifting
2 to 4 px across at each of 24 steps, turned at most 0.0166 radians in one step.

## Records and shaders

**Every line is a quad, and never `GL_LINES`**, because most WebGL targets clamp a line width to one
pixel. Each end is offset half a width along `directionAcross`, the normal of the plane that joins
the segment with the eye. `worldPerPixelAt` scales that offset at the own depth of *that end*, so
the screen width holds along a receding line. **The near plane is clipped against first.** A depth
clamped at the near plane breaks the proportion, and draws a world axis 20 px wide by the origin.

**The crossing is stepped from the end that it stands nearer.** A line reaches its vanishing point
at `radius_horizon`, which the orrery puts 530,000 units out. So a step from the far end is the
difference of two places decades apart, and float32 cancels it. The crossing then carries tenths of
a unit, at a near plane whose own pixel spans billionths of one: 1,538 px, 0.001 units off Earth.

**Every ribbon is then cut to a guard pyramid.** Its four sides pass through the eye, `FACTOR_GUARD`
of 8 half-views off the sight axis. Each cut steps from its nearer end, and a rim segment is cut as
a ribbon is. Uncut, a ribbon that crosses the near plane by the eye reaches far off screen: 1.15
million px for `sol ∧ earth`, 0.001 units off Earth. The GPU then interpolates its colour to
121/178/0 against an ink of 87/110/0, and its depth 55% too near or invalid. Rejected: one split of
the record, which moves the fault to the edge of the frame.

Verified by renders of 54 headings about Earth at 0.001 units: 11 pixels off ink uncut, and none
cut. The drawn line stands 0.466 px off exact either way, and the written depth within 0.02%.

**The widening runs in the vertex shader on both front-ends.** One `RibbonRecord` of fifteen floats
crosses the wire for each segment, or sixteen with the `fog` flag, where six CPU vertices cost 42
floats. An instanced draw expands it: GL 3.3 core on the desktop, and `ANGLE_instanced_arrays` on
WebGL1. Each vertex derives the across as `cross(head − tail, eye − tail)`.

**Chain of custody.** The GLSL ships, and `mesh.expandRibbon` is its reference in Nim,
sibling-marked with both shader sources. The suite holds the reference to the algebra. The near clip
and the four guard cuts equal `clipToEyeSide`, and the across equals the join `directionNormal(tail
∧ head ∧ eye)`, sign included.

**A fill of a plane, its rim and the sky are one record each.** A `DiscRecord` of 13 floats spans
one quad over a box on the view (`viewBoxOfDisc`), on the static corners of `discCorners`. Every
fragment casts its own ray at the plane, `hitDiscAlong`, so the disc is exact at any grazing angle
and agrees with `picking.rayPlaneHit`. Rejected: a fan of corners on the plane, where a corner
behind the eye left the clipper a sliver. Under a grazing camera, the disc ended at a hard chord.

**The box of a veil stops at the vanishing line of its plane.** The view turns about the sight axis
until the normal of the plane, signed toward the side of the eye, points up. The vanishing line,
where a sight ray runs along the plane, then runs across the turned view at any roll. Along each
turned axis the box bounds the sphere of the disc, or takes the whole turned view where that sphere
holds the eye. Its floor then rises to the vanishing line, and the quad turns back onto the view. No
ray below the line meets the plane in front of the eye, so the clip removes no pixel of the disc.

**Where the whole rim stands in front of the eye, the box tightens to the picture of the rim.** That
is where the depth of its centre is more than 1.001 times its depth swing (`FACTOR_RIM_AHEAD`). The
swing is how far the depth of the rim runs on each side of the depth of its centre. The picture of
the disc is then the convex hull of the picture of its rim. Along each turned axis the extremes of
the rim are the two roots of one quadratic in the slope. The box takes them with a pad of 0.002 of a
half extent (`MARGIN_BOX_RIM`), and never reaches past the box of the sphere.

Elsewhere the box keeps the bound of the sphere, because a rim that reaches behind the eye has a
picture without a bound. A `float32` emulation of the closed form over 1.5 million views set the
margin and the pad, on 2026-10-04, and it is not kept. At a margin of a thousandth its worst error
was under 1e-4 of a half extent, so the pad is twenty times that error. The pad is 0.9 px of a view
900 px tall. Rejected: a margin of a ten-millionth, where the worst error reached 1.1e-2 of a half
extent, five times the pad. Cost: each corner of the quad works out one quadratic for each turned
axis, beside the bound of the sphere.

Rejected: a box square to the view, which cannot stop at a slanted line. Rejected: a fan of 96
triangles over the box, which drew the ellipse through its corners. That ellipse ran past the box by
up to 41% of its half extent, and every fragment there was cast and discarded. Cost: each of the six
corners of the quad works out the box again, with a turn and a cross product.

Measured on 2026-10-04 under SwiftShader, at 1200 by 900 px with antialias, by a bench that is not
kept. It sums the `GPUTask` events of a Chromium trace over 100 simulated frame steps. Each change
has two pairs, before then after, in ms of GPU work for each step:

| View | Quad over the box | Floor at the vanishing line |
|------|-------------------|-----------------------------|
| Opening scene | 25.8 to 18.9, 21.5 to 18.1 | 18.9 to 19.8, 19.1 to 19.0 |
| Level and low over the ground | 24.4 to 20.8, 21.8 to 21.2 | 21.1 to 16.7, 20.4 to 15.9 |
| Steep over the ground | 36.5 to 26.7, 26.1 to 22.6 | 22.9 to 25.5, 23.0 to 24.0 |
| Level and low under the ground | 24.8 to 21.0, 23.1 to 21.3 | 21.0 to 18.7, 23.5 to 17.7 |

The same steps with the disc draws skipped read 5.5 to 9.2 ms, which is the spread of the bench. So
the floor changes the opening scene and the steep view by less than that spread. At the opening
scene the cost is the box of the sphere. From the opening stance the sphere of the ground spans 50°
of height, and its disc 21°.

The box of the rim was measured on 2026-10-04 by the same bench, without antialias, as the simulated
page draws. Each pair is `eecc2b5c`, then this design, in ms of GPU work for each step:

| View | Box of the rim, without antialias |
|------|-----------------------------------|
| Opening scene | 11.0 to 7.1, 13.0 to 7.2 |
| Level and low over the ground | 8.6 to 10.3, 10.5 to 9.5 |
| Steep over the ground | 13.7 to 14.9, 15.8 to 13.8 |
| Level and low under the ground | 8.3 to 8.5, 8.5 to 8.2 |

The same steps with the disc draws skipped read 2.2 to 3.2 ms. The opening scene falls by 3.9 and
5.8 ms, and the other views move by no more than two runs of one build do. In the level views the
rim reaches behind the eye, and in the steep view the disc covers nearly all of the view. With
antialias, as the page of the reader draws, the opening scene read 18.2 to 18.2 and 18.8 to 15.0 ms.
The two pairs disagree, so the gain with antialias is unmeasured.

The browser drive ran on 2026-10-04 in the lock of the gate, on each build in turn, twice each. It
is `build/drive/main.js` alone, timed from outside, and each page inside it. Every check passed:

| Build | Browser drive | Simulated page | Real-clock page |
|-------|---------------|----------------|-----------------|
| `eecc2b5c`, box of the sphere | 237.5 s, 235.0 s | 211.2 s, 208.6 s | 23.6 s, 23.9 s |
| Box of the rim | 215.3 s, 212.4 s | 190.1 s, 187.7 s | 22.5 s, 21.9 s |

A `DomeRecord` of 8 floats widens over a static unit sphere, which has no orientation. A
`RingRecord` of 14 floats is the thirteen of a disc plus a width, and one instance draws the circle.
The rim as one record is what the demo frame turns on. Rejected: 96 ribbon records for each plane:
99.2% of ribbon traffic on 132 planes, and a 239 ms median frame under SwiftShader, against 84 ms.

The static corner tables come from one generator each in `mesh`. The desktop reads them directly,
and the browser through `nim*Corners`, so neither front-end holds a table that could drift. The
suite pins those references to the multivector sums. `ribbonOfRing` derives the very `RibbonRecord`
that a rim segment would be, so one rule widens a rim and every line alike. The rim steps off
`UNIT_CIRCLE_RIM`, resolved at start-up with the `cos` and `sin` of the runtime. The compile-time
evaluator need not agree with the libm of each backend in the last bit.

**Every position of a record is stored about the view origin** (Origins). Emission reads each world
place about it once, and the five record writers store what they are handed. The suite pins a point,
a line, a plane and the sky, each through `tessellateObject`, against a view origin a million units
off.

**Veil order is kept, and not assumed away.** Two translucent veils still blend in scene order, so
every append extends or opens a `VeilRun`, and both render paths walk the runs in sequence.
`markOverlay` seals the current run. `RingMesh` carries its own `index_overlay`, or the second rim
of a selected plane would draw depth-tested behind the fill that it highlights.

**Capacities are asserted in `scene.nim`**, the one module that can see both sides. To raise
`OBJECTS_MAX` then fails to *compile*, rather than to `doAssert` at draw time, which is a dead page.

| Cap | Value | Binding case |
|---|---|---|
| `VERTICES_MAX` | 10080 = 2 × `OBJECTS_MAX` | every handle a point, every one selected |
| `DISCS_MAX`, `DOMES_MAX`, `RINGS_MAX` | 10081 = 2 × `OBJECTS_MAX` + 1 | every handle a plane, |
|  |  | every one selected, plus a preview |
| `RIBBONS_MAX` | 20161 = 4 × `OBJECTS_MAX` + 1 | every handle a line, two segments, drawn twice |

The desktop asks for a framebuffer at `SAMPLES_MULTISAMPLE` 4, and **falls back to none where no
visual offers it**. `llvmpipe` under `xvfb` refuses the window outright, rather than downgrades it.
A visualiser that will not start is worse than one whose thinnest lines alias. The browser context
asks for `antialias: true`, except on the simulated page (Clocks of the driven checks).

**The flat buffers are the page's own typed arrays, filled in place.** A `seq[float32]` on the JS
backend is an `Array` of boxed doubles, converted element by element into a staging `Float32Array`.
That is a fourth pass over bytes that nothing else read. `FlatBuffer` is a `Float32Array` behind
three `importjs` lines, allocated once at the cap of its mesh and never grown. Each frame hands back
a `subarray` view, with no copy, and it measured 0.1 ms a frame. Draw order in the browser scripts
mirrors `renderer.nim`, and a person keeps the two in step by hand.

*Checked.* Verified by `suites.nim`:

- the widening reference against the algebra;
- the near crossing of a line within a pixel of its recorded place, in a close-up on a moon;
- every stepped dome corner and ring corner against the sum it replaced;
- the static corners of the disc as two triangles that tile its box;
- the box of the disc against the projection of its rim, read in the turned fractions of the box;
- the quad of the disc on the side of the vanishing line where rays meet the plane, over seeded
  views at every attitude and roll;
- every spot of the disc that the view shows inside that quad, over the same views;
- the box of the disc around the picture of its rim, and within 0.002 of a half extent, where the
  whole rim stands ahead;
- under a grazing eye, the quad of the disc as the lower half of the view;
- the ray of the disc landing inside the rim and missing outside it;
- a hit under a grazing eye nearer than the near plane;
- all ninety-six rim segments on the plane at its radius;
- the capacity assertions, by a build of the binding scenes.

Verified by a desktop A/B under Xvfb: the widening in the vertex shader changed 0 of 1,296,000
pixels. The disc and dome as records changed at most 38 for each storyboard frame, at a channel
delta of 12 or less. There the record narrows its arms to float32. Verified by driven check: the
ribbon records of the demo under 64, against a ring count over 120. Both lines cross two rings, 100
and 80 px out, in opposite pairs, 0.01 and 0.001 units off, along two headings. Assumed: that the
0.1 ms of the flat buffer holds at current caps, as it was measured at 1,024 objects.

Verified under Xvfb on 2026-10-04, with frames written by `xvfb-run -a binaries/rga_visualiser
--storyboard:<directory>`. The quad and its floor changed 3 of 15,552,000 storyboard pixels against
`main`, and the box of the rim 10 against `eecc2b5c`. Each changed by 12 or less in any channel.
Verified by driven check: the veil of the ground over every spot its pick finds it at, from four
views. The whole rim stands ahead in the steep view alone, so that view holds the box of the rim, at
4758 of 4758 spots veiled.

## Algebra boundary

The **algebra owns geometry**: what a thing is and where it stands. That covers construction,
incidence, meets, joins, projections, nearest points and side tests. It covers the camera, the rays
cast from the screen, the lattice lines, the axes, and everything at the horizon. The **picture owns
representation**: how geometry becomes GPU primitives, such as the disc and the rim of a plane, and
the across-vector of a ribbon. The picture is built with whatever arithmetic is quickest.

**The compiler enforces the boundary.** `mesh.nim` imports `euclid.nim` and nothing else, so it
cannot name `Multivector`, and `euclid` reaches `pga/algebra.nim` alone. `objects.nim` is the
vocabulary of the algebra, and names no Euclidean type. `boundary.nim` is the one module that speaks
both, so every lift and read-out is findable in one file. `tessellate` is the geometry side of
drawing, and calls down into `mesh`.

**A PGA equation on the geometry side is never replaced with linear algebra.** The library is what
this project exists to exercise, so a cost that it carries there is a finding. It is restructured in
the terms of PGA alone: an invariant multivector hoisted, or one join shared across pieces that
provably share it. What may leave the algebra is the *picture*, and there the algebra is the
reference that the shipped form is proved against. The cross product of the across-vector is held
equal to the triple join, and every stepped disc point to the multivector sum.

The dense 16-coefficient `Multivector` stays, because a change to its storage changes what is
measured. On JS it is a 128-byte `Float64Array` that V8 allocates off its heap, at 1 µs each.

**The picture writes each value in place, one field at a time.** The six operators of `euclid.nim`
that return a `Position` or a `Direction` set `x`, `y` and `z` in turn. `addRing` and `addDisc`
write each field of their record into its slot, as `addMarker` writes its vertex. The JavaScript
backend copies an object constructor through `nimCopy` wherever it assigns one to `result` or to a
slot. A field write is a plain store.

Each write does the constructor's operations, in order, so each result is the same to the bit. On
the C backend `noinit` skips each operator's zero fill, so it emits the constructor's stores.

The copy matters most in `framing.reachNearOf`, which subtracts two positions for each object each
frame. Cost: one statement for each field, not one constructor. `fade` and `addRibbon` keep their
constructors, because their copies read 1.7% and 0.3% of a moving frame at 5,038 objects.

Measured on 2026-10-04 on one delegate, under the lock of the gate, by a harness that is not kept.
It drives the page at 1200 by 900 px under SwiftShader, with antialias. It times 6 s of frames for
each scene, then profiles 6 s more through the DevTools protocol of Chromium. An orbit turns the
camera 0.004 radians in each frame. Each pair is `c4e7e1fd`, then this design, run in turn, in ms of
the frame callback:

| Scene | Median | Slowest tenth |
|-------|--------|---------------|
| Opening scene, still | 0.9 to 0.7, 0.8 to 0.7, 0.7 to 0.8 | 1.3 to 1.1, 1.2 to 1.0, 1.1 to 1.1 |
| Opening scene, orbit | 0.9 to 0.9, 0.8 to 0.8, 0.8 to 0.9 | 1.5 to 1.3, 1.3 to 1.3, 1.3 to 1.3 |
| 5,038 objects, still | 1.7 to 1.0, 1.6 to 1.0, 1.5 to 1.0 | 2.4 to 1.4, 2.4 to 1.3, 2.3 to 1.5 |
| 5,038 objects, orbit | 2.6 to 2.2, 2.5 to 1.6, 2.3 to 1.8 | 3.9 to 2.9, 3.8 to 2.6, 3.1 to 2.7 |

At the opening scene the two builds overlap, as it holds five objects. At 5,038 objects the profile
puts `nimCopy` at 39% of the script of a still frame on `c4e7e1fd`, and at 10% in place. The
subtraction of `reachNearOf` alone is 31.5% of it. A moving frame reads 34% and 10%. With the
operators alone in place, the copies of `addRing` and `addDisc` read 2.6% and 2.7% of a moving
frame.

**A count holds the design, as it holds a fault close to its speed bound** (Clocks of the driven
checks). `driveCopiesStill` counts the outermost `nimCopy` calls over 3 still frames of the largest
demo, each of which places, builds and flattens the whole scene. The check fails at one copy of the
own code of the project for each object. Rejected: a reading of the emitted JavaScript for the six
operators alone, which passes a copy for each object at any other site.

A copy that a function of the reference library asks for is counted apart and reported, and never
bound. What the library costs is the library's (Render paths). The check names the maker of each
copy by the function that calls `nimCopy`, from the stack. Over 3 frames at 5,038 objects it reads
9,639 copies of the project and 30,663 of the library, 13,434 a frame in all. With each object
placed whole by `placeObject`, a counter that is not kept read 64,232 a frame, on 2026-10-05.

**A lift writes its coefficients, and a read-out reads them.** Geometry goes through the operators,
and the crossing is the coefficient table. A sum of blades made 23 arrays for a motor, and a write
makes one. **`sight` reads the stance once for each event**, off one lift and one antireverse.

**The geometry of the camera goes through the algebra, and what only sizes or clips the picture does
not.** The pitch of a finger carries its direction through the motor of `turnAbout`. The level axis
is the normal of the pencil that the sight and world up span. A held point stands on the ray of the
finger, a step short of the orthogonal projection of the pivot onto it. Depths along the sight are
heights over the plane through the eye, distances are `distanceBetween`, and sides are `innerOf`.
The near clip, the world size of a pixel and the culling of chords are the picture's.

**Readings and places go the same way.** The roll, the azimuth and the elevation are inner products
with the world axes, and every distance that the camera acts on is `distanceBetween`. The places and
frames of the orrery are the algebra's as well (Demo: the solar neighbourhood). Outside it stand
only the reading of catalogue angles into a direction, and the picture.

**The tessellation assembles before it emits.** Each loop resolves its places through the algebra
into a `DrawScratch`, and emits after. For the lattices and the axes the seam is between two procs.
`placeObject` answers what a drawable is and where, from the multivector alone, so the answer holds
while the camera moves. `tessellateObject(placeObject(...))` is what `addObject` is.

Two steps stay on the placing side inside `tessellateObject`: the stand-off of a horizon marker,
and the two vanishing points of a line. The cut that the panel reports is by kind of work, and not
by proc.
`tessellate` takes its scratch as a parameter: the desktop hands it swap arena memory, and the
browser a fixed buffer.

**A timed stretch is charged at its end, so nothing leaves it early.** `timed` reads the clock on
entry, and again as its last statement, so a stretch that leaves before that read is never charged.
So `timed` refuses at build time a `return`, and a `break` or `continue` that no loop or block
inside catches. `placeInto` times one call to `placeUntimed`, whose answers leave by `return` inside
its own body. That body is a pure function, so `placementOf` places an object for a `func` that
holds no frame, and charges no side. The aim of the camera does so for staged geometry.

Rejected: a `try`/`finally` bracket, which puts a `try` around the placing of every object, at a
cost that is not measured.

**`pointFrom` tallies each read while a reader counts.** `countPointsRead` opens the gate
`IS_COUNTING_POINTS_READ`, and only the suite opens it. Closed, a read costs one load and one branch
in the emitted JS. The tally is a write that `strictFuncs` counts as an effect, so a
`cast(noSideEffect)` covers it alone. Rejected: `pointFrom` as a `proc`, which makes each `func`
that reads a point a `proc`. Rejected: a build flag, since an instrument is gated on its reader
(STYLE.md).

**`toMultivector` tallies each lift of a motor the same way**, through `setCountingLifts`. The suite
opens it, and so does the driven check of the page, through the bridge (Camera). **`kindInto`
tallies each classification the same way**, through `setCountingKinds`, for the suite and for the
driven check of the page (Render paths).

**`isHorizon` tallies the tests of one multivector**, for the suite alone (`countHorizonTests`). It
matches that multivector coefficient for coefficient. A read can join a plane of its own, as
`spanPerpendicular` does. A test of the horizon of that plane is no test of the object.

**There is no debug layer, and nobody is to reintroduce it without an instruction.** A switch that
drew every multivector a frame computed, as what it is, never helped to resolve anything.

*Checked.* Verified by `suites.nim`: each moved form, lift, `sight`, depth and held point is pinned
to its reference. Verified by a 400-step camera trace: read-outs within 1e-13 of the vector forms on
both backends. Verified in Chromium at 390 by 844 on 2026-09-25 against the vector forms, in four
interleaved pairs, each the best of seven runs. A turn of a finger takes 223 to 251 µs in free aim,
against 144 to 158. It takes 247 to 283 in orbit, against 113 to 122.

A turn and a frame build take 0.93 to 0.94 ms, against 0.86 to 0.94.

Verified by `suites.nim`: placing charges the placing side on each of its seven exits, and a stretch
that leaves early fails to build. Verified by driven check: a still frame under the largest demo
copies fewer values than the scene has objects. Verified by a read of the emitted code on
2026-10-04: no `nimCopy` stands in the six operators, `addRing` or `addDisc` on the JavaScript
backend. On the C backend each operator is three field stores with no fill.

## Origins

**Three origins, as a GPU pipeline has three spaces.** The world origin is world space: the scene
stores each object about it, and stores nothing else. The view origin is view space: each frame is
reckoned about it, near the camera, through `camera.moveOriginView`. The model origin is model
space: an operation holds its operands about it, at a point of one of them, through `originModel`.

**Only the world origin is stored.** A GPU stores a vertex in model space and derives the others.
This scene stores in world space, and derives the view and model spaces inside the calculation that
uses each. Rounding grows with the distance from the origin a number is held about. So each
calculation is held about the origin nearest what it serves: a frame about the camera, an operation
about its operands. Storage keeps its step far out, a cost (Classification at any scale).

**The view origin follows the camera every frame.** It is the double nearest the eye, and each
front-end moves it there once for each frame, before anything reads the stance. `Camera.motor`
carries the reference stance to the eye about the view origin, so the eye keeps the remainder that
no world double can hold. The step between two origins is exact for nearby doubles, and the motor
slides back by it, so that remainder carries over exactly. The move reads the eye and frame off the
one lift that `sight` makes.

A still camera stands within half a world step of its origin. So a still frame leaves the origin and
the motor as they were, bit for bit.

Two million units out a double steps by 17 to 35 m. An eye held as a world double there wobbles an
orbit 150 m wide on that step. It cannot name an orbit a metre wide at all. Rejected: an origin held
in steps, which saves nothing, because every frame builds every record (Render paths).

**Every calculation of a frame reads about the view origin.** That covers the eye, the frame, the
pivot, the extent, the transform and the frustum. It covers picking rays and hits, markers and
labels, framing and aim, and the drags. Each world value enters the frame once, by a subtraction
(`euclid.toView`). A placement is read by its place, so a line or a plane slides by plain
translation of its support. It keeps its arms, and no slide runs for each object.

Where the algebra meets a world object with the eye or a ray, it builds the line or plane through
the place so read. So a world plane met with a ray far out lands on the world step.

The aim stays world's, because it has to compare equal frame to frame while the origin moves.
A destination stance is held about the place it lands on, and carries that origin
(`CameraStance.origin`). A pick or a framing stands its pivot on the world place of its object
(`camera.stanceRepivotedAt`). The slide that builds it composes onto the camera's motor, with the
view origin at the eye, so no number far out enters it. At progress 1, `toward` returns the
destination itself, so an ease lands on it bit for bit while the view origin moves under it.

Rejected: a destination held about the view origin of the eye it starts from. Far out, its pivot
rounds off the object, and an orbit then swings the object across the frame. Rejected: the screw at
progress 1, which rounds off the destination from millions of units away. The point that a right
drag holds carries its origin too.

**Records are float32 about the view origin, with no split into parts.** Emission reads each world
place about the view origin and hands it on, and the five record writers store what they are handed.
So the one subtraction for each object sits at that read. The furniture and the horizon are reckoned
about the view origin from the start. A lattice line a decimetre apart two million units out has no
world double to lift it back to.

The eye that the shaders take is the remainder, about zero at world scale, and so is the translation
of the transform. Dropping it would snap an orbit a metre wide to the world step.

**What stores or shows the stance converts at that edge.** History's steps and the panel's motor are
about the world origin (`stanceWorld`). So are the drive's readings of eye, pivot and anchor
(`eyeWorld`, `pivotWorld`). Cost: a stance that history restores far out lands on the world step.

*Checked.* Verified by `suites.nim`:

- an orbit 1 m and 150 m wide, 0.41, 2.1 and 4.7 million units out, holds its pivot over 2,000
  steps. It stays within a millionth of its separation, and lands where one turn of their sum lands;
- 10,000 moves of 0.3 m out and 10,000 back carry the remainder over exactly. The eye goes 3 km, and
  comes back to within a millionth of a move, and to within one world step as world reads it;
- a moved camera carries the view origin to its eye, and a still one leaves the origin and the motor
  bit for bit;
- a transform about the view origin agrees with the world one, and keeps the offset of a moon a
  million units out;
- every record of a point, line, plane and the sky stands about a view origin a million units off.

Verified by a probe that is not kept, on 2026-10-05, against `0fdcfcfc`. The 2,000 steps hold the
pivot to 1.9e-14 of 1 m, and to 2.8e-14 of 150 m. On `0fdcfcfc` the 150 m orbit moved its pivot 398
m, and 873 m at worst. There an orbit asked for at 1 m was floored to 150 m, and the 10,000 moves
out moved the eye 0 m. Here they move it 3,000 m, within 1.3e-11 of a move of their sum.

**Cost: none that the frame shows.** Each moving frame slides the motor once, and each object is
read about the view origin by one subtraction. Measured on 2026-10-05 on one delegate, under the
lock of the gate, in three interleaved pairs, `0fdcfcfc` first. The page runs at 1200 by 900 px
under SwiftShader, with antialias, and times 6 s of frames for each scene, as Algebra boundary
describes. Each figure is the median of the frame callback, in ms:

| Scene | `0fdcfcfc` | View origin |
|-------|------------|-------------|
| Opening scene, still | 0.8, 0.8, 0.9 | 0.9, 0.9, 1.0 |
| Opening scene, orbit | 1.1, 1.0, 1.1 | 1.0, 1.1, 1.1 |
| 5,038 objects, still | 1.1, 1.2, 1.1 | 1.1, 1.1, 1.1 |
| 5,038 objects, orbit | 2.3, 2.4, 2.2 | 2.3, 2.2, 2.2 |

The clock of the page resolves 0.1 ms, so every pair overlaps. The `--timings` of the desktop reads
300 frames. Its median frame read 5.29, 5.54 and 4.68 ms at the opening scene, against 5.10, 5.01
and 4.72 ms. At 5,038 objects it read 80.5, 84.9 and 85.5 ms, against 85.7, 85.9 and 84.1 ms. Its
tessellation read 14.7, 15.4 and 15.5 ms there, against 15.5, 15.4 and 15.4 ms.

Verified by driven check (`driveFarOrbit`), in Chromium on 2026-10-05. The farthest point of the
demo, 4.72 million units out, is picked and held at its fill, 217 m away. It stands 0.001 px off the
middle of the frame before and after a drag of 180 px that turns the view 0.450 rad. Against the
page of `0fdcfcfc`, the same check read 403 px off the middle, and the drag turned nothing.

## Classification at any scale

**An object is judged against its own scale, and never against an absolute tolerance.** One world
unit is one astronomical unit. A join of two points a metre apart, one unit out, carries
coefficients near 1e-12. The `TOLERANCE_ABS` of the library is an absolute 1e-9, so the library
alone reads that line as no object. So `objects.kindOf` reads the grade of a scale-free copy, which
`scaleFree` divides by its largest coefficient. A coefficient then counts where it is more than a
billionth of the largest one.

**The copy is skipped where it changes nothing.** Where the weight `E4` is one or more and the
library reads one grade, the largest coefficient is at least one. The threshold of the copy then
stands at or above that of the library. The copy then keeps a subset of the same coefficients, the
largest among them, and reads the same grade. Every unit-weight point takes this path.

**Horizon is weight against bulk.** `isHorizon` reads an object as horizon where its weight norm is
no more than a billionth of its bulk norm. That is an object more than a billion units out.
`boundary.position` weighs the weight of a point against its bulk in the same way, and
`motors.turnAbout` refuses an axis by the same rule. The library does not change (Algebra boundary).

**An assembled point is read by its weight alone.** `pointFrom` reads a point that a caller builds
as a unit point plus weightless directions. Its weight is exactly one, and its bulk says only how
far out it stands. So `pointFrom` tests the weight against zero, and not against the bulk.

The horizon stands at `FRACTION_HORIZON` 0.9 of the far bound from the eye, and a camera 5.6e7 out
puts it past a billion units. There a test against the bulk reads each point of the horizon as a
direction, and the assert in `pointFrom` stops the frame loop. The anchor and the pick of a star
build the same point, so a star past a billion units would have no place to pick. Rejected: a
ceiling on the separation, which no reader is assumed to want (Camera).

**A product that a caller builds on the spot is judged against its factors**, because rounding of
zero carries no scale of its own. `euclid.normalize` and the four direction readers of `boundary`
take a `scale`, and refuse a direction no more than `TOLERANCE_ABS` of it. A caller that wedges unit
directions passes one, so a parallel pair names no direction at 1e-9 radians. The default of zero
refuses only a direction with no length. The test of the ribbon stays in world units, as the tests
of its shaders do, since its segment is the picture's.

**A catalogue operation runs about a point near its operands.** `scene.applyOperation` slides its
operands to a local origin through the motor of the library (`motorSliding` and `carried`). It
applies the operation there, and slides the result back. About the world origin, the join of two
points a metre apart, one unit out, computes its moment `p × q` from products near one. That moment
cancels to about 1e-5 of itself, and both points stand hundreds of kilometres off the line.

Only the operations of `OPERATIONS_SLIDING` run so, the fifteen that commute with a slide. The other
twelve read the origin itself, as support, bulk and the central projection do. So they run about the
world origin, which is the origin they mean. The origin is the place of a point operand, the first
operand's first, because the cancellation is about the point that is joined. Else it is the anchor
of the first finite operand, its support, and else the world origin.

A slide back adds `t × d` to a small moment, and cancels nothing, so the rounding is `ε` of the
distance slid. That is 33 µm one unit out, and about a millimetre thirty units out. Each slide keeps
only the grades that its multivector occupies. A rigid slide keeps every grade, so a coefficient on
another grade is rounding of the sandwich. A join a metre across one unit out reads that rounding as
a mixed grade.

Measured on 2026-10-05 by a probe that is not kept, over 2,000 random pairs one unit out, beside the
earth of the demo. The line held both points within 47 µm, where about the world origin it stood 182
km off at the median. A plane joined from three such points held them within 0.45 mm, and a meet
with a crossing plane within 0.29 mm. Rejected: a pair of doubles for each coefficient, which the
dense `Multivector` of the library cannot carry.

**An operation answers zero for rounding of zero.** `scene.applyOperation` applies the operation
again to scale-free copies of its operands, as they stand about the local origin. Where the largest
coefficient of that second result is under `TOLERANCE_ROUNDING` times the scale of the point they
slid from, the result is zero. A sum is judged against its larger operand instead. Each operand
carries the rounding of where it stood, so the scale of that point keeps rounding far out at zero. A
point met on its own line then joins with it to nothing, near the origin and two million units out.

The drag and both apply pickers read it so. The marker judges an eye on its line against the line
and the eye in the same way.

**`TOLERANCE_ROUNDING` is `2^(2·4)·ε`, about 5.7e-14**, the worst rounding of one product of two
multivectors against its factors' scales. Within five units of the world origin, a point met on its
line joins it to about 2e-16 of its operands. Two million units out, at HD 222237 b of the demo, the
point stands up to 2e-8 off the line, against a bound of 1.2e-7. Points a metre apart join, about
either one, to 6.7e-12 of their operands. Measured on 2026-10-05 by a probe that is not kept.

**The panel prints a term against the largest one.** `scene.formatMultivector` prints a term over a
billionth of the largest coefficient. A metre-long line then prints its three terms, not `0 𝟏`.

**Rejected: an absolute tolerance of more places.** With `-d:pga.tolerance_places=12` the suite
passes, but the floor only moves. The smallest coefficient of a metre join one unit out, beside the
earth of the demo, is 1.04e-12, just above it. At 15 places, eight cases fail, because they compare
with zero through `=~`. Measured on `f779cec8` on 2026-10-05, by a probe that is not kept.

**Cost: rounding that stands alone reads as an object.** A stored object of pure rounding is drawn,
where the tolerance of the library refuses it. Only a caller that holds the factors can refuse it.

**Cost: storage far from the world origin still steps**, because each object is stored about the
world origin, and that is all that is stored. A double steps by half a millimetre at 30 units, and
by a metre at 60,000 units. Two million units out it steps by 17 to 35 m, as at HD 222237 b of the
demo. Two points a metre apart there are stored as one.

Rejected: an exact place stored with each object, because the origins of a calculation stay implicit
in that calculation. A join holds a metre wherever storage holds one. It runs about the point it
joins, so its rounding is `ε` of the distance of that point from the world origin.

**Cost: more work in each classification.** Measured on 2026-10-05 on one delegate, under the lock
of the gate. Each probe places the largest demo, and each pair is `0d47eab3`, then this design:

- release C, five pairs of the median of 41 runs: 0.48 to 0.55 ms, then 0.50 to 0.52 ms;
- release JS on Node 22, five pairs of the same probe: 26.2 to 29.6 ms, then 26.6 to 35.9 ms;
- tessellation that the debug desktop's `--timings` reads over 300 frames, three pairs: 12.5 to
  12.9 ms, then 14.4 to 14.6 ms;
- the frame at p50 from that same run: 79.6 to 80.3 ms, then 86.7 to 87.2 ms.

Both front-ends place every object in each frame (Render paths), and the desktop also asks
`isHorizon` of each row of its objects list. That second norm of `isHorizon`, and the second pass of
`formatMultivector`, are most of what the desktop frame gained. The list gives no frame figure for
the page, so the cost to the frame of the page is unmeasured.

**Cost: three slides for each catalogue operation.** Measured on 2026-10-05 on one delegate in the
lock of the gate: the median of 21 runs of 2,000 calls. Each pair is `7119f4cb`, then this design:

- debug C, a join or a meet: 5.1 to 5.4 µs, then 32 to 41 µs a call;
- release JS on Node 22, the same calls: 20 to 33 µs, then 85 to 177 µs a call.

A drag over an object calls it up to seven times an update: three proposals, one preview, and three
menu offers. The apply section calls it once a frame, and no path calls it for each object.

*Checked.* Verified by `suites.nim`:

- a join of two points a metre apart is a line, one unit out as near the origin;
- a line a metre long holds both its points, one unit out as near the origin, as placed;
- a plane a metre across holds its three points, and a line meets it where it crosses;
- points that coincide, and a point lying on its line, join to nothing, near and far;
- the catalogue's joins, meets and projections give what the library gives, near and far;
- the catalogue runs about a local origin exactly the operations that commute with a slide;
- a line a metre long prints the terms it carries, and no rounding beside them;
- an eye standing on the line has no side to flank it from;
- a line and a star drawn at a horizon of 4e9 land where the algebra puts them, and the star's
  anchor reads its place;
- a star stays pickable from a camera 1e8 out, whose horizon stands 1.8e9 off the eye.

Verified by a probe that is not kept, on 2026-10-08. The wheel over Sol in the largest demo carries
the separation to 6.8e9 with no page error. Under the bulk test, the page stops near 5.6e7.

## Motors

`motors.nim` holds the rigid motions that `pga` lacks. A motor is one value that carries a turn
about a line and a slide along that same line.

**The library has the parts, and not the whole.** It carries the geometric antiproduct (`⟑` for the
base form, `⟇` for this one), the antireverse (`~∘`), the weight and bulk split, and `unitize`. It
carries no motor type, no `exp` and no `log`.

The library names that gap twice as its own work. `multivectors.nim` asks for an even grade basis,
and names motors as the reason. `operators.nim` names motors beside the sandwich macro that it
leaves commented out. So this module stands in until the library returns, on the pattern of
`projections.nim`. A compile guard refuses the build once the pinned library carries its own `exp`.
Nothing here reimplements a library operation, which Article II.8 forbids.

**A motor lives in the algebra of the antiproduct, and not in that of the base product.** A probe
read the rows below off the pinned tree, and the suite pins every one of them.

- The identity is `𝟙` (`E1234`), because `⟇` is the product that motors compose through.
- The turn generator is the line direction (`E41`, `E42`, `E43`), which antisquares to `-𝟙`.
- The slide generator is the line moment (`E23`, `E31`, `E12`), which antisquares to zero.
- The sandwich is `Q ⟇ m ⟇ ~∘Q`. One form serves a point, a line and a plane alike.
- A turn by `+θ` about a unit line is `exp(-(θ/2)L)`, and `turnAbout` holds that sign.
- Motors compose right to left, so `m.carried(a).carried(b)` is `m.carried(b ⟇ a)`.

The base product is not this algebra. Under `⟑` the two halves swap roles: the moment squares to
`-1`, and the direction squares to zero. A sandwich built there turns about the line at infinity
rather than about the line meant, and both products compile.

**Neither `exp` nor `log` needs a degenerate branch.** Both read two series of the half-angle,
`sin(a)/a` and `(a*cos(a) - sin(a))/a³`, which are finite at zero, where they read 1 and `-1/3`. A
pure slide falls out of the same expression, because its direction is zero, and so does a pure turn.
No branch means no branch to get wrong.

`ANGLE_SERIES` at 1e-4 chooses the series over the closed form. `a*cos(a) - sin(a)` subtracts two
values near `a` to reach one near `a³/3`, so it loses about `3ε/a²` of its digits. At an `a` of 1e-6
the closed form keeps about four. The next term of the series is `a⁴/840`, under 1e-19 at that
crossing, so the two arms agree there.

**`log` takes the short way round.** A motor and its negation carry every point alike, so `log`
reads one with a negative antiscalar through its negation. The half-angle then stays at or under
`π/2`, where `sin(a)/a` stays above 0.63. Without this, `log` of a motor near a full turn divides by
zero, and a full turn names no axis to return. So `exp(log(Q))` is the same motion as `Q`, and the
same coefficients only where `Q` turns by less than a half turn.

**Normalisation is the library's `unitize`.** The weight norm of a unit motor reads 1, for a turn, a
slide and a screw alike. Nothing here normalises: a finding against `unitize` is the library's.

**The stance of the camera is the one caller.** `Camera.motor` is a motor, and `camera.nim` builds
it with `turnAbout` and `motorSliding`, composes it with `wedgeDotAnti`, and reads every direction
back with `carried`. Nothing else in the tree names a motor.

*Checked.* Verified by `suites.nim`:

- the antisquare of each generator, and the swap that the base product makes;
- a turn about the z axis against `cos` and `sin`, at six angles, the half turn included;
- a turn about a line off the origin, which carries the origin about that line;
- a horizon line, which names no axis and turns nothing;
- a slide that carries every point by one offset, in two terms and no more;
- `exp(log(Q))` against `Q`, and unit weight, over 64 seeded screws, one in seven of them
  at a half-angle below `ANGLE_SERIES`;
- the identity, the inverse through `~∘`, and the grade that survives a sandwich;
- the distance and the weight that a rigid motion keeps;
- the order of composition.

Assumed: that `unitize` is the motor norm for any unit motor. The suite reads it back for every
motor that `exp` builds. Nothing renormalises a composed stance. Natively on 2026-09-24, 10^6 turns
of up to 0.05 radians left its weight 8e-14 off unit and its pivot 5e-12 off.

Unmeasured: the cost of a sandwich, which is two dense antiproducts.

## Selection and markers

`selection.nim` is shared. It holds an ordered fixed-capacity list of handles, as a plain value
type. **Order is the whole point**, because an operation reads its operands by position: the first
handle picked is `𝐦`, and the second is `𝐧`. `Selection.revision` counts real changes, so the frame
record and the desktop panel compare one integer, and not 5,040 handles, in every frame.

Selection is **not** part of `Scene`. It is never saved and never on the timeline, and a step keeps
each pick that still names its object (Undo/redo). `pruneDead` runs after a removal, because a freed
handle goes straight back to the next add.

**The walks of a frame read one mark for each handle, and never the selection.** Both front-ends
mark each pick once in `MARKS_PICKED` before the walks, through `selection.markOnto`, and clear the
marks after them. `contains` walks the list, so a walk that asks it for each object costs the count
of objects times the count of picks. Rejected: a mark array inside `Selection`, which every copy of
a selection would then carry.

Measured 2026-10-02 on this container, an Intel Xeon at 2.80 GHz with 4 cores, by a scratch program.
It picks every handle of a `Selection` at `OBJECTS_MAX`, and times twenty frames of two walks each.
On C at `-d:release`, one frame costs 17.2 to 18.4 ms with `contains` and 0.012 ms with marks. On
JavaScript under Node 22, it costs 53.8 to 54.7 ms with `contains` and 0.50 to 0.56 ms with marks.
Each range is three runs.

**A selected object is drawn over every other object.** Each mesh has one watermark
(`index_overlay`, an `Option[int]`, because an index of zero means "all of it"). A second pass then
runs over **every** primitive kind, against a depth buffer cleared first, so selected objects still
reject one another by depth.

Rejected: the depth test turned off, under which a planet selected after its moon buried the moon in
front of it. Rejected: a tail on each kind, which left a selected line tinted by a later veil.
Rejected: a third `MeshSet`, which reserves every cap for a run that is usually one object. On the
desktop the marks draw on the **background** list of Dear ImGui, beneath the panels, and the drag
menu alone stays foreground.

"Just built" and "currently selected" are one mechanism. There is one marker for each selected
handle, in plain white, and every construction path replaces the selection with the handle that it
created. Hover draws the identical marker at `ALPHA_MARKER_HOVER` 0.6, against
`ALPHA_MARKER_SELECTED` 0.9, and keyboard focus wears it too. Only a caller that passes a time gets
a pulse, so motion means selected. `marker.nim` shapes the outline to what it marks:

| Kind | Marker | How it fills |
|-------|--------|--------------|
| Point | Circle in screen space about the drawn point. | Sweeps clockwise from twelve. |
| Line | Two rails flanking its projection, one each side. | Runs out from its support. |
| Plane | A circle lying *on the plane*, outside its rim. | Opens from the disc's centre. |
| Horizon line | Two bands on the sky it circles. | Closes in from a quarter turn. |
| Horizon plane | The viewport's edge, inset by the gap. | Expands as a circle from the middle. |
| Horizon point | Circle about the fixed star it draws as. | Sweeps. |

All of them keep `GAP_MARKER` 6.0 px between the drawn edge of the object and the marker, measured
out from the drawn size. A ring of a point then hugs a wide disc and a dot alike.
`OFFSET_MARKER_RAIL` is `WIDTH_LINE_OBJECT`/2 plus the gap, which is 7.25 px. `WIDTH_MARKER` is 1.5
px, asserted thinner than the line that it marks.

**A marker reads a fixed few points out of the algebra, and never one for each sample.** A loop and
a band step their samples off `UNIT_RING_LOOP` and `UNIT_RING_BANDS` through `onCircleAt`. The suite
holds each point of a loop to its multivector sum. Rails read 14 points: the base and both far ends
of each rail, in each of two layouts, and two ends for the label. Bands read their two centres, and
a ring, a loop and a frame read none. A loop that sums its 64 samples reads 64, and its count fails.

Each render path strokes the markers in its foreground layer, and never as scene geometry. A loop on
a plane would z-fight its fill, and a marker that the object can occlude is not a marker. It is not
an outline in the style of 3D modelling, and nobody is to reintroduce that without an instruction.

**A selected object wears its name above its marker**, filled in the own ink of the object and
outlined in the stroke of the marker. Hover and focus wear none. `marker.nim` decides where it sits:
centred, `GAP_MARKER` plus half of `HEIGHT_MARKER_LABEL` (16 px) above the top of the outline. Each
front-end centres its own text.

  **A label of a line keeps to its own left, beside its support clamped into view.** "Above the
  line" cannot be continuous, because which side is up flips as the line passes vertical. The side
  of the own *direction* of the line is continuous. So `marker.placeLabelBesideLine` pushes the
  label left, and each front-end, which alone measures its text, sets the clearance along the push.

  The anchor is the projection of the support while it is in view, held `MARGIN_LABEL_VIEW` 40 px
  inside the edge. Past that it slides along the visible stretch. Rejected: the upward side, which
  hopped five times on a camera path of 24 s where this hopped none.

  **The label of a horizon line stands above the leftmost point of either band**, its crossing of
  the left edge. It is pushed `MARGIN_LABEL_HORIZON` 12 px in from the edge. The rule that pushes
  the label of a line off its rail also pushes it off the band. Rejected: the highest point, which
  on a level horizon hopped between the two side crossings. Rejected: flush against the edge, where
  the name read as cut off.

  Its driven check orbits at rises of 0.15 and -0.15, 8.5° off the horizon, inside the frame rule's
  10.7° at 393 by 560 px. A label read during the ease back from 0.2 depends on frame time
  (repository issue 297).

  **The label of the frame of the sky stands inside the bottom-left corner.** It stands
  `MARGIN_LABEL_HORIZON` in from the left edge of the frame, and `MARGIN_LABEL_FOOT` 40 px plus that
  margin up. That keeps it clear of the page's scale bar, whose top is 33 px up, and it is pushed
  rightward the same way. Rejected: the top edge under the chip row, and the corner itself.

  **Every label is then held wholly inside the view.** `labelInView` clamps the measured box
  `MARGIN_LABEL_EDGE` 4 px in from each edge, on both front-ends. The page measures its text on the
  overlay layer, because text off the document has no length, and the hold then has no box.

  **The label of a plane stands on the column of the disc, at the height of the true top of its
  circle.** `marker.topmostOnCircle` solves the top of the projected circle in closed form: screen y
  is stationary where `(b·d − a·e) + (c·d − a·f)·sin + (b·f − c·e)·cos = 0`. Rejected: the highest
  of 64 projected vertices, which hops a segment at a time.

  Its **height** alone is used, and the label's x is the column of the disc's centre, which makes
  the flip invisible. At the edge-on moment the tops of the far rim and the near rim part in x. Both
  go to the horizon of the plane in y. Rejected: the own x of the top, which pops at the flip.

  **The halo is the backdrop colour, not the marker white.** A halo blends with the background to
  knock the surroundings out of the letters. A contrasting halo dominates them instead (Peterson,
  *Cartographer's Toolkit*; Dawson, *About label halos*). It is `WIDTH_MARKER_LABEL_HALO` 2 px of
  `Ink.Backdrop` at `ALPHA_MARKER_LABEL_HALO` 0.85, on a 16 px face at weight 600.

  The desktop sets the label in `FACE_FONT_LABEL`, with the math and symbol faces merged in, so `G =
  L ∧ c` keeps its wedge. It has no stroked text, so it draws the label at eight one-pixel offsets
  in the halo colour. The browser stages one SVG `<text>` for each selected handle, with
  `paint-order: stroke`.

**The loop of a plane lies on the plane.** It is traced from the frame of the plane, about the
anchor that `addPlane` centres its disc on. Its clearance is a world distance, sized through
`worldPerPixelAt` at the own depth of the disc. The gap then reads as 6 px where a reader judges it,
and foreshortens with the disc elsewhere.

**The rails of a line are two straight world-parallel lines, sized by the widest gap that they will
show.** Along the half whose far point lies behind the eye, `clipToEyeSide` cuts it back to the near
plane, where depth *falls*. A world offset then flares: 45.6 px at one camera, against 14.5 at the
support. So `OFFSET_MARKER_RAIL` means **the widest that the pair may read anywhere**. `markerRails`
measures one rail against the other at every drawn end (`apartWidest`), and narrows the world offset
until the widest reading meets the ceiling. Three traps are live here:

- **Settle, do not solve** (`PASSES_MARKER_RAIL` 4): narrowing moves where each rail leaves the
  view.
- **Settle against the finished rail, then draw at the progress asked for**, or the gap widens as a
  touch hold fills.
- **Measure one rail against the other, and not either against the line between them.**

The worst case of a marker lies along orientation, so a sweep of camera *distance* is not a sweep.
**The growth of a rail is measured against the edge of the view** (`fractionLeavingView`), and not
against its own length. The two vanishing points sit at screen distances in a ratio of 314. Rails
are shortened **after the projection**.

**The frame of the horizon plane is an expanding circle that becomes the screen edge.** At each
angle the radius is `progress × half-diagonal`, or the distance to the inset edge, whichever is
smaller. It runs over `SEGMENTS_MARKER_FRAME` 64 even steps, with `CORNERS_MARKER_FRAME` 4 corner
directions merged in by angle. A corner missed by a fraction of a step is a corner cut off.

**The bands of a horizon line are cut to the viewport, not the eye alone.** Uncut, a ring laps
396,102 px against the 1,490 on screen, so `markerBands` keeps the longest stretch in the window.

**On touch every marker swells clear of the finger** (`CLEARANCE_MARKER_TOUCH` 54.5 px, added and
not multiplied). That is about twice the contact patch of a thumb, and zero for a mouse. It runs on
its own clock in four phases (`interaction.swellHold`). It grows over `SECONDS_SWELL_GROW` 0.12 s,
and sits at full through the fill and while the finger is down past maturity. It settles over
`SECONDS_SWELL_SHRINK` 0.15 s once the finger lifts. `isHoldSpent` is stated against `swellHold`,
rather than against the duration a second time, because a subtraction of two large timestamps
measured 0.14999999999997 against 0.15.

*Checked.* Verified by `suites.nim`:

- the points of the loop on the plane (1.1e-15 on the antiscalar);
- each kind reading at most its fixed points out of the algebra, with a pulse and without;
- the straightness of the rails, and their widest reading over an orientation sweep;
- the 68 points of the frame at 296.8 px flat at half progress;
- a matured hold taken once;
- a line's label over two orbits of 1,257 steps each, with no isolated step;
- the push of that label turning at most 0.017 in one step, against the 0.05 its law allows;
- a plane's label over one such orbit, with no hop where its sampled top hops 29 times;
- two more orbits: the label of the horizon line on the leftmost band point in the left half;
- the label of the frame on its left edge at its foot;
- the label of a plane a milliradian either side of the flip, standing under a pixel apart.

Verified by driven check:

- 402 frames with 0 label hops;
- 96 frames at phone width, the eye still where it was placed, with 0 side swaps and none right;
- the label of the horizon line whole in its first frame at phone width, at four bearings;
- the label box of the frame in its corner above the scale bar;
- a 720-step orbit with the rail gap changing at most 0.103 px between frames;
- two crossing planes selected changing 15,668 canvas pixels, against a noise floor of 0 pixels.

On the desktop, the ink of the second pass is unmeasured.

## Marker pulse

**Orientation is a pulse that travels round the selection marker.** Rejected: a normal shaft, which
marked every plane permanently to answer a question that a reader asks about one object. `markerFor`
runs a lit run of `SEGMENTS_MARKER_PULSE` 16 points, spanning `LENGTH_MARKER_COMET` 64 px of the
outline. It tapers from `WIDTH_MARKER_COMET` 3.5 px down `FALLOFF_MARKER_COMET` 1.2 to
`WIDTH_MARKER`. It is fixed in pixels, and not a share of the outline. A share measured 96 px along
a rail against 334 px round a circle.

**Which way it travels is the orientation.** Nothing computes the sense, and the projection decides
the order of a loop. A rail is walked from the far horizon through the support to the near. A band
takes the normal of the great circle, and a point and a horizon plane get none.

**The travel is a distance in pixels from an anchor that does not depend on the view.**
`PulseClock.travels` advances by `SPEED_MARKER_PULSE` 60 px/s times the seconds, with no camera
quantity in the advance. It is reduced into the current lap in every frame, because `travelled mod
lap` amplifies a one-percent lap change by the laps accumulated. `PulseTrack` names the anchor, the
support of a line or the angle zero of a ring, and `originAfterCut` walks angle zero through an eye
cut. Rejected: a lap time rather than a speed, which ran 156 px/s along a rail against 348 round a
circle. A gap longer than `SECONDS_STEP_PULSE_MAX` 0.1 s is an absence, and not a frame.

The desktop fill needs a **fixed winding**, which `gui_shim.guiOverlayRibbon` imposes. **A drag band
swells into its head** (`marker.cometFor`), because `a ∨ b` and `b ∨ a` are different operations.

**The pulse and the label of a selected marker read the outline that the marker call shaped.** In
each frame the page asks the bridge three times for each selected object: `nimSelectionMarker`, then
`nimSelectionPulse`, then `nimSelectionLabelAt`. The marker call shapes the outline into
`BOX_MARKER`, from the placement of the frame, and `MARKER_SHAPED` keeps it beside every input that
shaped it. Those inputs are the handle, the view size, the progress, the touch flag, the swell, the
travel and the overlay settings. The pulse reads that entry where every input matches, and the label
where the handle and the view size match. A miss shapes the outline again and drops the entry, so
the label then shapes it a third time.

**A call from the page passes every argument, because a Nim default never reaches it.** Nim fills in
a default at the call site of a Nim caller alone. A JS call that leaves an argument out passes
`undefined`, which matches no stored value. So `tools/build.nim declare` makes each parameter of an
export required in `build/bridge.d.ts`, a parameter with a Nim default included. A call that leaves
an argument out then fails `types`, with `TS2554`.

*Checked.* Verified by `suites.nim`: the head sitting its carried travel at 45 placements. Verified
on the shipped browser: the advance of the comet at 62.4 to 63.3 px/s across four orbit rates. The
residual at faster rates is **not explained** to the standard that the medians are. A tenth of
frames step 236 to 388 px/s at laps and clip transitions.

Verified by driven check: `driveMarkerShapedOnce` selects a point, a line and a plane in turn. Each
reads 3 shapes for 3 markers over three frames. Without the swell in the pulse call, each read 9
for 3. Verified by a break on purpose, 2026-10-04: the pulse call without its swell fails `types`.

## Picking

`picking.pickNearest` is shared. **Point beats line beats plane, strictly**, whatever the pixel
distance, once the own radius of a shape is met. That priority is what makes generous radii safe.
`RADIUS_PICK_POINT` is 34 CSS px and `RADIUS_PICK_LINE` is 24, sized against a fingertip at phone
density, and the test of a plane is by area.

**Everything drawn is pickable, and the horizon is included.** The rank is point, finite line,
horizon line, finite plane, and horizon plane. The horizon line is tested against the great circle
that it draws as. The horizon plane matches every ray, so it comes last. The extent goes through
`algebraFilled`, the one derivation point, because built field by field, a horizon point is
unpickable with its multivector twins zero.

**The sky is a click and hold target, and never a drag handle, and so is a plane or a point that
fills the view.** With a horizon plane visible the cursor is over *something* almost everywhere. A
press on empty space becomes a camera move precisely because nothing was hovered. A finite plane
whose disc reaches every corner of the frame (`picking.isCoveringView`) leaves no empty glass at
all. Every corner is half the diagonal from the middle, 750 px on a 1200×900 frame. Rejected: the
longer side, 1200 px, under which a plane that covers the whole window still reads as a handle.

A point fills the frame as the zoom comes in to it, and its drawn sphere is held to the same corners
(`mesh.radiusDrawnAt`). Rejected: a point that is always a handle, which zoomed in until it covers
the frame leaves no glass to press. `SLACK_COVERED` 1e-9 lets a disc fall that fraction short of the
corners and still cover. An eye held at the fill stands one ulp short of it, and a bare `>=` reads
the point there as a handle.

`isBackdropUnder` folds every case into one answer, which `beginDrag`, `destinationOf` and
`interaction.is_hover_backdrop` read. A click on empty space selects the sky rather than clears the
selection. A tap still treats it as empty space, because a tap on empty space is the only way a
finger has to dismiss a selection. Touch reaches the sky by a long press.

**The pick runs once for each frame, and not for each input event.** A pick walks every live handle,
which is linear in the scene. Each pointer move marks hover stale, that of a mouse with no button
down included, and the frame loop picks once after `nimDriveHeld`. The wheel sums its notches and
the loop applies one dolly, the same zoom, because notches compose (`interaction.factorWheel`).
Rejected: a pick for each notch, at 83.8 ms of picking for six notches a frame. Three paths pick in
their handler, because they answer before it returns: `pointerdown`, a touch-down and `handleTap`.

**The pick ranks what was drawn.** It takes the placements of the frame and dispatches on
`Placement.kind`, rather than asks `position`, `direction`, `frame` and `spanPerpendicular` again
for each handle. Both front-ends hand them to the hover pick, and to the wheel pick. Empty means
derive for each handle, which a scripted drive of the desktop and every suite case do. The object
that a hover or a wheel names is read from its placement too, so the pick classifies nothing.

**The pick rejects a plane before it meets it.** `isBeyondDisc` bounds the screen extent of the disc
by the silhouette of the sphere that contains it, conservative in the depth and off-axis terms.
20,000 random configurations with 300 surface samples each found no silhouette point outside the
bound. `geometryOf` hands back a `lent` view, and `projectToScreen` is three dot products in local
floats. Rejected: a 4×4 multiply with two typed arrays allocated for each call, which was 43% of a
15.4 ms pick over 10,000 handles.

**A depth reads as in front down to the floor of the camera.** `isInFront`, and the two tests of a
pick that share it, take `camera.DISTANCE_LIMIT_NEAR` as the least depth ahead of the eye. No
separation that the camera holds then reads as behind it. Rejected: a fixed millionth of a unit. A
pointer pick of a star at least radius stands 2.4e-7 units off it. The ring, the label, the menu and
every pick then lose the star.

**A hit on an object reads as ahead by its own reach from the eye.** `positionOnObjectUnder` and
`rayPlaneHit` read a hit as behind where its depth is no more than a billionth of its distance from
the eye. Rejected: a fixed millionth of a unit. A camera can stand a hundredth of a millionth off a
plane. The plane under the middle of the frame is then neither picked nor found. A meet of the ray
with a plane reads none where the ray grazes the plane within a billionth of a radian.

**Handle-liveness guards.** Hovered, dragged, focused and selected handles are plain values carried
across frames. Any of them can name a removed object the frame after a delete. `nimAnchorScreen`
reports nothing for a dead handle. `endDrag` on both paths checks `isAlive` on the source and the
destination, and a removal of an object clears the highlight on both paths.

*Checked.* Verified by `suites.nim`:

- both boundaries of each radius, and all three priority pairings;
- a horizon point picked;
- the disc bound sampled from inside the view;
- the ground hovered from half a unit (backdrop, drag refused) and from forty (drag starts);
- a point reads as backdrop at 0.8 of its fill depth, as a handle at 1.25 of it and 1,000 units;
- a disc spanning 965.7 px read as backdrop and one spanning 724.3 px did not, against a corner 750
  px from the middle;
- a point ahead of the eye reads in front and is picked at each decade from 1e-8 to 1,000 units;
- a point as far behind the eye reads behind;
- a plane a camera stands millionths off is picked, and found under the pointer.

Verified by a handle-for-handle map: 4,914 cursor positions across three cameras over the demo of
1,024 objects. They answered identically before and after the placement and copy changes. Verified
by driven checks on both builds: a drag of bare sky turns the view and builds nothing, and a click
on it selects it. The camera was dropped onto the ground plane, and a left-drag orbited without
building. On the page, a point picked alone reads as backdrop at its fill, and as a handle one notch
out. A right drag of 180 px on it moves the view and builds nothing.

Verified by driven check on the page, through pointer events alone (`driveHoverFollowsMouse`). A
mouse moved onto an object with no button down hovers it, and moved off it hovers nothing.

Measured then, and not since: one pick went from 11.4 to 3.9 ms p50 at 1,024, and from 15.4 to 4.7
ms at 10,000. A hover pick is 0.7, 1.6 and 3.5 ms at 60, 360 and 5,038.

## Interaction model

**Which button does what, stated once.** `interaction.isMenuRevealedOn` says whether a click brings
the floating selection menu: right yes, left and middle no. `armingOf` says whether a drag opens
the choice wheel. Both render paths and `help.nim` read them.

| Gesture | Does |
|---|---|
| left click | select just that one, dropping the rest |
| right click | the same, and open the menu |
| shift with either | add it, or drop it again if already picked |
| right click, selection standing, menu down | reveal the menu, selection untouched |

**The selection menu opens on the click, beside the pointer**, `INSET_MENU_POINTER` 8 px from it.
It then remembers its offset from the anchor of the object, so an orbit carries it with the
object. A pick carries its object to the middle of the frame, so the menu rides in and settles
beside the middle. It is not held back until the ease settles: a menu a third of a second after
the click reads as a missed click. A menu opened with no pointer sits above the anchor.

**A wheel over the selection menu zooms the view on both front-ends**, as a wheel over the view
does. The menu scrolls nothing, so it hands its wheel on. On the page, the menu passes its wheel to
`sumWheel` in `pointer.ts`. On the desktop, the wheel goes on to the view while Dear ImGui reads the
pointer over the menu (`is_menu_selection_hovered`). Each handler names the other, so a change to
one reaches both (Article II.9).

Rejected: a menu that keeps its wheel. Under it, a pick clicked where the menu then lands leaves the
wheel dead until the pointer moves. That box spans 298 by 55 px, right of and below the middle.

**A click has no time limit.** `isClick` is distance alone, at `PIXELS_CLICK_SLOP` 6 px. It is not
the 12 px of `PIXELS_TAP_SLOP`. A mouse does not roll, and the allowance of a finger would swallow
the short deliberate drags between two overlapping objects. A deadline of 0.35 s lost every click
held 600 ms. A right press that never moved is a click too.

**The press target picks the scheme, and the button whether the reader is asked.** Press an object
and you construct. Press empty space and you move the camera: left turns, right slides, and the
wheel zooms. Left takes the algebra's own answer on release, and right opens the four-way wheel.

**A mouse never waits.** `MenuArming` is `Never` for left, `Always` for right, and `OnDwell` for no
button. That last is touch, which has no second button and would otherwise lose `meet`, `project`
and `more…`. `SECONDS_DWELL_MENU` 0.75 sits above `SECONDS_LONG_PRESS` 0.50, so the two thresholds
that a stationary finger races are in the right order. The dwell measures stillness, and restarts
whenever the cursor moves further than `PIXELS_TAP_SLOP`. Rejected: a dwell that measures presence,
which opens the menu under a finger that moves continuously.

**Middle is unbound.** **A press that can construct never moves the camera, not even before its slop
is crossed.** The browser decides at the press, in `is_touch_press_constructing`, which is the same
question that `beginDrag` answers when the slop is crossed.

**A finger over a crowd moves the view, and never builds.** In the demo the 34 px reach of the pick
lands on some star almost anywhere. A one-finger orbit would then become a construction drag.
`picking.pickAt` reports how many objects of the rank of the winner *or better* stood within
`RADIUS_CROWD_TOUCH` 72 px. That is wider than the pick reach, because the question is whether the
finger could have meant something else.

`interaction.isConstructibleByTouch` is true only with no rival, and is asked at the press through
`nimCanTouchConstruct`. Where a gesture is ambiguous, movement wins, because the reader can zoom in
until it is not, while an unwanted object must be undone. It is same-rank only, or every point on
the ground would be a crowd.

**The pivot of the turntable follows what the zoom lands on.** Every rate but the orbit is scaled by
the orbit distance on purpose. A drag or a key hold then moves the view by the same fraction of what
is seen at any zoom. A zoom straight in, with the pivot left on Sol, leaves the turntable revolving
about a point far behind the planet arrived at.

So `picking.anchorZoomAt` says whether its anchor is where a point or a line *stands*, or a crossing
(`AnchorZoom.is_standing`). `interaction.dollyAt` re-pivots along the sight line to the depth of a
standing anchor after the zoom, through `camera.repivotToDepth`, which leaves the picture unchanged.
A plane is a crossing, and the map rule alone follows it. Its depth under the pointer is not its
depth at the middle of the frame.

Measured on the demo: eight wheel notches over Jupiter from 30 units hold its pixel exactly. They
bring the pivot from Sol to 0.09 units off the plane of Jupiter.

**The edit preview is drawn at the own radius of the session.** Otherwise an edit of a moon of 0.03
draws a grey disc nearly three times its size over it.

**Edit from the selection menu scrolls to the offset of its row and renders the window there, in one
call.** The offset is the sum of the heights above it, an estimate where a row has never stood. So
the row lands inside the window, and one reading of where it stands corrects the rest. It lands
under the pinned heading, rather than at the own edge of the scroller, which the heading covers.

**The gesture clock is seconds**, on whichever monotonic clock the caller owns.

**What a drag builds is read off the operands, not the button.** `∧` adds grades and is drawable
where the sum is 4 or less. `∨` adds antigrades and is drawable where the sum is 4 or more. The
table covers every ordered pair of point, line and plane in general position. Points lie off the
moment curve `(t, t², t³)`, where "no three collinear and no four coplanar" is a Vandermonde
theorem.

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

**At most one of join and meet is ever drawable**, so `proposalFor` is a priority order (Join, Meet,
Project) with no tie. `plane → point` offers nothing, and a release refuses rather than invents. The
table is asymmetric, so the direction of a drag carries meaning. `GENERAL_FIRST` and
`GENERAL_SECOND` are separate from the random operand sets, because a point that lies *on* its
paired line reads zeros from the fixture.

**The drag shows its answer before it commits it.** `Interaction.preview` holds what a release right
now would build. It is drawn in `INK_PREVIEW`, through the same `addObject` that the preview of an
edit session uses, at the same anchor that the commit makes. `choosing()` is the one statement of
which wedge the cursor is in. **A release can do three things, so there are three tints**
(`ReleaseEffect`: `Nothing`, `Refused`, `Builds`). They are the neutral `Ink.Guide`, the magenta of
`Ink.Invalid`, and the next hue of the scene.

**Every released construction steps the ink cycle**, built or not, so a colour the reader watched
for a whole drag is not offered again. A click does not step it, and undo restores it. Where a
session and a preview both stand, **the session wins**. The preview is **framed together with the
operands that it names** (`Preview.operands`).

**The choice wheel.** Four wedges sit at fixed compass points: join north, meet east, project south,
and `more…` west. Unoffered ones are greyed (`ALPHA_MENU_UNOFFERED` 0.45) rather than packed out,
because a menu whose objects move is one that nobody learns. A wedge is the own button of the
selection menu, moved.

**A wedge says what the picker says.** `labelOf` returns `notationSymbolic` (`𝐦 ∧ 𝐧`, `𝐦 ∨ 𝐧`, `𝐧 ∨
(𝐦 ∧ 𝐧☆)`), and `More` returns a bare `…`. A release commits whatever is under the cursor, resolved
by `endDrag` through `choiceAt`, so the two paths cannot disagree. The centre
(`PIXELS_MENU_DEADZONE` 26 px) commits nothing, which is why an unasked dwell wheel is safe to open.
The wheel **latches its destination** when it opens, and **lets go when the cursor leaves it** past
`PIXELS_MENU_DISENGAGE` 150 px, sited off `PIXELS_MENU_CORNER_FURTHEST` 103.9 px. Travel on to
another object re-aims, and never chains.

**A wheel that the reader summoned may veto the release, and one that invited itself may not.** A
pause before the lift is the common touch release, so the centre release of an *unentered* dwell
wheel falls through to `proposalFor`.

`more…` builds nothing, and opens **the own apply picker of the selection menu** over both operands
in drag order. Rejected: the apply section of the drawer, which buried the two objects. A degenerate
construction, or one on a full scene, is **refused**, with a message that names why.

**Touch.** A finger on an object constructs, and one on empty space moves the camera. Two fingers
hold what each touched, and cancel any construction. A long press selects. Once a selection exists,
a tap (`TAP_MAX_MS` 350) toggles another in or out, and a tap on empty space clears.

`nimClearHover` runs once the last finger lifts, or the last reading sits stale for ever.
`SELECTION_PAGE` in Nim is the sole source of truth, and the browser keeps a render snapshot.

**Selection menu.** It is one row on both builds, and follows its anchor in every frame. `apply` is
leftmost and never moves, and opens a picker to its right through a `max-width` transition, because
`width: auto` cannot animate. `edit` is shown for exactly one selected. `hide` and `delete` act on
every selected handle, and `✕` clears. `apply` is hidden for three or more selected.

It is **shown by the gestures that pick, and hidden by the ones that build**. Every construction
leaves its result selected, and a menu over each new object would sit in the way of the next drag.
Placement is `OFFSET_MENU_SELECTION` 46 px **above** its object. A Dear ImGui window makes
`wantsMouse()` true wherever it sits, so a menu that straddled its object would swallow the next
drag off it. The listener for a tap outside excludes the canvas, the drawer and the chip row.

*Checked.* Verified by `suites.nim`:

- every cell of the drag table, and the at-most-one property, exhaustively;
- the click rule;
- the dwell restarting on movement;
- the anchor of the preview equal to that of the created object;
- the ink cycle stepping on release and not on click;
- the crowd count and the refusal;
- the re-pivot rules under the wheel and over sky.

Verified by driven checks:

- the tint table at each wedge stop;
- shift-clicks held 600 ms selecting;
- the sub-slop touch drag hovering with the azimuth unmoved;
- a finger dragged from a point with a twin 0.05 units away, which orbits and builds nothing;
- `more…` landing on `𝐦 ∧ 𝐧` on both builds;
- the refusal on a full scene;
- a right-click showing the menu two frames in, 14 by 12 px from the anchor, and so once settled;
- three notches over the menu of a settled pick of `b` zoom the view, with the pivot 0 off `b`. The
  distance goes from 18.097 to 11.749 on the page, and to 12.881 on the desktop;
- a pivot shift moving that anchor 84 px, with the menu holding the offset;
- an emptied list, a deep handle edited, and its form in view.

Assumed: that 0.75 s is the right dwell for any hand.

## Two fingers

**Two fingers hold what each touched, as the mouse holds what it grabs, less a slop** (repository
issue 592). As the second finger lands, `interaction.gripFingers` takes a place for each finger.
Each frame, `interaction.carryGrip` moves the camera so that both places stand at the pixels that
`interaction.fingersHeld` names.

**Zoom and twist wait for their slop.** The gap between the fingers must change by `PIXELS_TAP_SLOP`
12 px, and their angle by `RADIANS_TWIST_SLOP` 0.21, which is twelve degrees. Until then, the held
gap and angle stay as they landed, so two fingers carried together only slide. After that, each
counts from the edge of its slop, so crossing it jumps nothing at any frame rate.

Rejected: no slop. Two fingers carried together never hold their gap to a pixel or their angle to a
degree, and every wobble zooms and rolls the view. The cost is the slop's own. A finger slips off
its place by the slop's share of the gap, and by twelve degrees of arc about the middle.

**With nothing selected, four unknowns answer four pixel coordinates.** The camera slides across, up
and ahead, and rolls, so the sight keeps its direction. The solve is Levenberg-Marquardt from the
answer of the last frame, with finite derivatives. It starts from the stance the fingers landed on,
so its answer does not depend on the path the fingers took.

**With a selection, the orbit stays on what is picked.** The middle of the fingers orbits as the
drag of one finger does, and carries the point on the sphere about the pivot with it. A dolly then
brings the gap of the two places to the held gap, and a roll brings their angle. The dolly scales
about the pivot, so what the middle holds drifts toward the middle of the frame as the view zooms
out. Rejected: one solve of four unknowns against both places, which spends the turn on the gap,
because a turn foreshortens what it carries.

**A finger holds the place on its own ray, at the depth of the object under it.** That object is the
one a tap there selects: at any depth with nothing selected, and inside the depth band with a
selection. Rejected: the own point of the object, which the pick finds up to 34 px off the finger.
Two fingers on one star then held one point, and no spread could zoom.

**With nothing selected, a finger over nothing holds a place at a depth the view is about.** That
depth is the depth of the object of the other finger, where that finger stands on one. Otherwise it
is the depth of the object shown nearest the middle of the fingers, within `FACTOR_ANCHOR_DEPTH` 2
of the depth of the pivot. Otherwise it is the depth of the pivot itself. Rejected:

- the sky itself, which no slide moves, so with both fingers on sky no pinch moved anything;
- the nearest object ahead, which far out in the orrery is a star off to the side;
- the object shown nearest at any depth, which can be a star a thousand times deeper.

With a selection, a finger on empty space holds the point on the orbit's sphere, as a left drag
does.

**Once the fingers zoom, the pivot stands at the depth of the nearer place held**, as the wheel's
zoom lands it on an object. The next pinch then scales the same thing, so zoom out after zoom out
grows by the ratio of the fingers. A slide alone carries the pivot along at its own depth. Places
over nothing never draw the pivot in, so no pinch runs the separation down (repository issue 535).

**An unknown that no finger can move stays where it stands.** The damping holds it there, and a
correction counts only where it cuts the misses by more than a billionth of them
(`FRACTION_GRIP_GAIN`). Rejected: any cut at all, under which a spread that asked no roll rolled the
view by 1.3e-9 radians, on rounding alone.

**The floor of each place is a depth along the sight**, the fill where the wheel stops at that
object. Past it, the fingers slip. Rejected: a floor on the reach, which a place off the own ray of
the object never came near. The eye then went on past the fill.

**Both fingers are read once for each frame.** The move of each finger arrives as its own
`pointermove`. A solve read there chases the new place of one finger and the old place of the other.
`glue.settleTwoFingers` reads both from the frame loop instead. The grip is dropped as either finger
lifts, so a third finger lifting back to two takes no old grip.

*Checked.* Verified by `suites.nim`:

- two fingers on points at two depths hold both within 0.05 px, through a spread, a slide and a
  twist;
- the slop there costs its own share of the gap and the angle, and no more;
- two fingers carried together, wobbling 10 px and 0.15 inside the slop, slide, and neither zoom nor
  roll;
- half a pixel past the slop of the gap moves the places by that half pixel's share alone;
- a hundredth past the slop of the twist rolls the view by that hundredth alone;
- with nothing drawn, two fingers on empty sky hold places at the depth of the pivot;
- a spread there keeps the separation, and a twist about the middle rolls by what lies past the
  slop;
- places over nothing take the depth of the object shown nearest the fingers, near the pivot's
  depth;
- a nearer star aside, and a deeper star under the middle of the fingers, do not set that depth;
- five pinches in over empty sky each zoom out by more than 4, about the point drawn there;
- with a selection, the pivot moves less than 1e-9, and the gap and angle of both places hold within
  0.01 px and 1e-9;
- with a selection, a fivefold pinch off the middle zooms out by more than 3;
- a spread over one point stops the eye at its floor.

Verified by driven checks, in Chromium on 2026-10-08:

- fingers on `a` and `c`, over a spread of 1.3, a twist of 0.25 and a slide, held both 0.00 px off;
- two fingers carried together 316 px held both points 0.00 px off, and left the separation at
  19.000;
- a spread and a slide on empty sky came 10.819 in, turned nothing, and drew the separation from
  19.000 to 7.707;
- two fingers carried together, wobbling inside the slop, slid 2.288, came 5.0e-6 in and turned
  1.6e-7;
- a twist of 0.300 on empty sky about the middle turned the picture 0.0900, and moved the eye
  5.9e-6;
- four pinches in with nothing selected zoomed out by 3.25, 3.70, 3.83 and 3.87;
- with `o` selected, the pivot moved 2.2e-14 as the separation came from 19.000 to 13.763;
- with `o` selected, four pinches in zoomed out by 3.10 to 3.28;
- a pinch zooming with a selection standing, and the move not taken back.

## Undo/redo

`history.nim` is shared. It is scoped to edits of scene content: add, apply, remove, visibility,
ink, and the `save` of an edit session. That save is the "edit committed" moment that the continuous
widgets lack. It is one fixed array plus one cursor, and not two stacks. An entry is a `Step {scene,
stance}`, and both are plain value types, so a record is a copy and `entries[cursor].scene` is
exactly the live scene. `CAPACITY_HISTORY` is 32.

**The array is a ring.** `first` names the handle that holds the oldest step, and `handleOf` is the
one place where a timeline position becomes an index. To retire the oldest entry moves one integer.
Rejected: a shift of every later entry down, which is 31 whole scene copies for each edit past the
thirty-second. On the JS backend at 5,038 handles, that took 153.5 ms to toggle the visibility of
one object, against 11.3 ms as a ring.

What remains for each edit is the one copy of a `Scene` into the timeline, 1.15 MiB through
`nimCopy`, and not for each frame. `initHistory` fills a timeline that the caller owns. Returned by
value it compiles to a `nimCopy` of thirty-two whole scenes, which was 65% of the load of the
largest demo. `record` writes the fields of a `Step`, and assigns no literal, for that reason.

**The stance rides along, and an orbit is never a step of its own.** Each step records the
`CameraStance`, the motor and the separation, that the view stood at when the edit of *that step*
was made. It is read about the world origin, as the scene is stored (Origins). Undo reads it off the
entry left, and redo off the entry reached. Nothing else of the camera crosses a step.

Rejected: a whole `Camera` in each step, which puts the lens of the edit over the reader's own. Home
keeps the lens by the same rule.

To restore the camera of the state arrived at hands back the view that the *previous* edit was made
from. An undo of the first construction of a session then teleports to the startup view. Not to
record an orbit is the accepted cost of not needing a rule for a gesture to settle. **An accidental
orbit is still not undoable on its own.**

**A step keeps each pick that still names its object.** `selection.keepNaming` drops a handle that
the restored scene no longer holds, or holds as another object. A handle alone does not say, since a
freed handle is refilled by the next add, and the creation ordinal does. A step restores the count
with its objects, and an edit after undo truncates the future that held any ordinal it reuses.

**The frame rule alone moves the camera after a step.** Both front-ends call
`CameraTween.adoptNext`, which halts the ease and takes the next aim as delivered where the restored
stance stands. The aim that the restored scene reads can be new, and a new aim eases the camera
however it stands. A restored stance that breaks the rule eases back, as a resized window does.

The timeline is seeded wherever the scene is initialised or re-initialised, and a successful step
drops any open edit session and preview. It is bound to Ctrl or Cmd with Z, Ctrl or Cmd with Shift
and Z, and Ctrl with Y on both builds. Each build binds them through one function rather than the
button. The `disabled` attribute of that button is refreshed on the low-cadence tick.

*Checked.* Verified by `suites.nim`:

- a record to capacity and past it, with a walk of every retained step forward and back;
- a comparison of each state by `scenesEqual`, because the `==` of `Multivector` is an intentional
  compile error;
- camera restoration across two edits from two viewpoints;
- a step either way, which carries the stance across and leaves the field of view alone;
- a step keeps the picks it still names, in pick order, and drops one whose handle was refilled;
- Home, which keeps the field of view.

Verified end to end: `--drive-undo` and the browser drive both build, orbit away, undo, and hold the
view where the construction was made. The browser drive also undoes an edit to one object, and the
other stays selected.

## Storyboard and seeds

`storyboard.addSeeds` builds five seeds. They are `a`, `b`, `c` raised 2 units in z, `o` at
the origin, and `ground`, a plane joined from three points at `z = 0`. `o` must stay off `ground`,
because one step projects it onto that plane. `STEPS` is eleven derived steps, and both entry points
compute the seed count from `scene.len`. One step (`a ^ ground`) is a grade-4 volume, and correctly
reports "mixed grade, nothing to draw", which is its documented purpose.

Both apps open on the seeds alone. `runStoryboard` tells "reached" from "focal", and draws reached
but not focal muted rather than hidden. Horizon steps aim the capture through
`azimuthElevationFor(heading)`, a closed-form inverse of the forward direction of the orbit camera.

`addSeeds` does not stagger the arrivals, because `runStoryboard` sweeps the animation of each
step on a clock of its own. The startup paths call `replayFrom` after it. The GIF is
`FRAMES_GIF_GROW` 6 plus `FRAMES_GIF_HOLD` 4 frames for each step, at `STRIDE_GIF` 2 downsampling
and `CENTISECONDS_GIF_DELAY` 8.

*Checked.* Verified by a regeneration: the storyboard is byte-identical across changes that should
not touch it. Nothing assumed.

## Creation-anchored plane centring

The rim and the fill of a plane centre on `scene.creationAnchor(operation, m, n, derived)`, rather
than on its support closest to the origin. That support reads wrong for a plane built from operands
that do not straddle the origin. A `Wedge` of a line and a point centres at the midpoint between the
point and its projection onto the line. An `ExpandWeight` of a point and a line centres where the
line meets the plane. The ground seed centres on its centroid, and all else on the support.

The anchor is computed at construction and stored (`anchor_overrides`, a rendering hint that save
and load exclude). Many operand sets produce an identical plane `Multivector`. The anchor arithmetic
is native to RGA: it sums unit-weight points, and `position` divides by weight.

*Checked.* Verified by `suites.nim`: the anchor of each special case. Assumed: that no other
operation wants one, because nobody has asked for one.

## Save and load format (`.rgascene`)

Compact binary that matches the layout of `Scene`, **little-endian throughout**. The browser reaches
it through `DataView`, so the byte order had to be a choice. It is little-endian because every file
already written held it. The desktop converts through `std/endians`.

| Bytes | Field |
|-------|-------|
| 4 | Magic `RGAS` |
| 1 | Format version (`VERSION_SCENE` = 7) |
| 1 | Basis count (16 under this build); must match |
| 4 | Object count, little-endian `uint32` |
| per object | Ink (1), visibility (1), label length in bytes (1) + UTF-8, one |
|  | little-endian `float` per basis term, the radius as one more `float` |

`MAGIC_SCENE` and `VERSION_SCENE` are exported, and reach the browser through `nimSceneMagic` and
`nimSceneVersion`, so there is no literal to drift. Labels go through `TextEncoder` and
`TextDecoder`. A value derived in Nim and copied by hand into JavaScript leaves the two builds
unable to open each other's files. A round-trip suite stays green on it, because it only asks one
build to read what it wrote.

Only live objects are written, **in creation order** (`nimSceneHandlesCreated`). That order is the
whole of what version 3 added. Version 4 appended the radius after the geometry of each object.
Version 5 appended a byte after that, which said whether the point shone. Version 7 dropped it, so
versions 5 and 6 alone carry one, read and skipped. `scene.isCarryingRadius` and `isCarryingShine`
say which versions carry each, and the browser parser reaches them through `nimSceneHasRadius` and
`nimSceneHasShine` rather than literals.

Version 6 changed no byte. It records that the palette lost its structural `Algebra` handle at
ordinal 7. Every hue that a file of version 2 to 5 wrote therefore sits one past today's, and
`upgradedFrom5` takes it down. Omitted on purpose: handle numbers, an ordinal for each object, and
fixed-width label padding.

**A loaded scene replays its construction.** `born` is not written, and `scene.bornReplaying(index,
count, now)` stamps the arrival at `index` of `count` a beat after the last. `animationProgress`
reads a `born` that the clock has not reached as zero. `SECONDS_REPLAY_STEP` 0.12 is shorter than
the appear animation of 350 ms, so an object is still growing as the next lands.
`SECONDS_REPLAY_WHOLE` 2.5 caps the whole arrival by shortening the beat, or a full scene would take
minutes. Every arrival that a reader did not build replays, a file, the demo and the opening scene,
by one rule in both loaders.

**Every version ever written is still readable.** `VERSION_SCENE_LEAST` is 1, and should stay 1. To
read an old version costs a mapping func and a suite case, and to refuse one costs somebody their
scene. Reading is written once against `VERSION_SCENE`. The difference of each past version lives in
one `upgradedFrom<n>`, and `objectUpgraded` walks an `ObjectSaved` up the chain one step at a time.

Version 3 costs sizes, with `upgradedFrom3` filling `RADIUS_OBJECT_DEFAULT`. The chain refuses a
radius that is zero, negative or NaN, as it refuses an unknown palette slot. Version 1 costs colours
alone: its ordinals name a palette that no longer exists, folded by the same cycle that `inkCycled`
walks. It is bounded by `ORDINAL_INK_HIGH_V1` 14, so a byte that version 1 never wrote is refused.

**A wrong hue is recoverable, and a refused scene is not.** `loadScene` parses into a staging scene,
and replaces the caller's only on complete success. It is native-only.

*Checked.* Verified by a cross-read, and not by a round-trip:

- the sixteen-object demo saved, reloaded and compared object for object in creation order;
- the label, ink, visibility and all sixteen coefficients, 304 scalar comparisons, exactly equal;
- the desktop re-saving the browser-written file byte-identical, all 2245 bytes;
- hand-built files of version 1 and version 2 read the same by both parsers;
- a file one version ahead refused by both;
- ordinal 15 in a version-1 file refused;
- the version-6 fold pinned ordinal by ordinal.

Verified by watching: the seeds arrive over 0.480 s, and the sixteen of the demo over 1.84 s in the
browser. Verified by `suites.nim`: the on-disk bytes of a known float. Assumed: the big-endian host
path, which is never exercised (see Known limitations).

## Demo: the solar neighbourhood

The demo preset is the own load case of the build, in three sizes. They are `ScaleOrrery.Nearest` at
60, `Neighbourhood` at 360, which is the default everywhere, and `Catalogue` at 5038. That last is
two handles short of the pool, the smallest margin that still proves the point of leaving one.

Every size is the same construction truncated at a different depth, so a cost reads as a slope. 60,
360 and 5038 objects cost 1.3, 1.7 and 3.0 s to build. A frame build costs 3.1, 4.6 and 12.8 ms, and
an edit 9.1, 8.5 and 8.0 ms under SwiftShader. **Each size lands on its count exactly**: the star
walk passes over a system too large for the room left, and keeps walking.

**To scale: one world unit is one astronomical unit.** `KILOMETRES_PER_ASTRONOMICAL_UNIT` is
149,597,870.7, and a parsec is `ASTRONOMICAL_UNITS_PER_PARSEC` 206,264.806 of them. Every distance
is the real one, and every drawn radius is the real radius. `radiusDrawnOf` divides kilometres by
the unit and does nothing else, so Sol is 0.00465 units wide, Earth 0.0000426, and Phobos
0.000000074. Sol stands at the origin, with its ecliptic flat in the plane `z = 0`. `sol` is `1 𝐞₄`,
every planet has z exactly 0, Neptune is 30.05 units out, and Proxima is 268,000.

The price is that from the opening camera every body is the least dot, and the moons of Jupiter lie
inside its dot. The reader dollies in, and each body is its real size when the camera arrives.
`camera.DISTANCE_LIMIT_NEAR` at 10⁻¹³, `mesh.RADIUS_OBJECT_LEAST` at 10⁻⁹, and a camera and records
held about the view origin (Origins) let it do that.

**Every moon rings its planet in its real orbit plane.** `MOONS` carries the mean orbital elements
of JPL, fetched from https://ssd.jpl.nasa.gov/sats/elem/ on 2026-09-18. Each one is an inclination
and a node against the reference plane of the moon, which a pole in J2000 right ascension and
declination names. That plane is the ecliptic for Luna and Nereid, the equator of Uranus for its
five, and a local Laplace plane for the rest. The pole of Uranus is the spin pole (RA 77.311°, Dec
15.175°), the antipode of the IAU north. The small inclinations of the elements then read prograde
about it, as JPL states them.

**The algebra builds every place and every frame, because construction is its own** (Algebra
boundary). `normalOfMoon` meets the reference plane with the equator, and that line is the node of
the equator. A motor turns it about the pole by the node angle, and a second motor turns the pole
about that line by the inclination. A last motor turns the whole about the equinox by the J2000
obliquity of 23.4392911°, into the ecliptic frame. Only the reading of two catalogue angles into a
direction stays in closed form.

The ring of a moon starts at its ascending node, where its plane meets the ecliptic. A flat ring
starts at the bearing of its sun: the meet of the ground with the vertical plane through the
direction of the star. Each body is its node turned by its phase about the normal of its ring, then
`pointAlong` that direction from its parent. Each plane of a meet is a weight expansion of the
origin, which faces against its line, so only a meet of two is read.

**The turns that every star shares are built once, at compile time.** `TURN_ECLIPTIC` and the
quarter turn about world up are constants, with their antireverses, so a star pays one sandwich and
one point. A ring is spanned only for a star with a planet. Rejected: the closed forms, the cross
products and the sums of sines that placed the same objects outside the algebra. Over every object
of the three sizes, each coefficient matches them within 1.0e-14 of its object's largest.

**The price is build time on the JS backend, once for each load.** The Architect keeps it, by the
ruling on #459, so no star leaves the algebra. Each figure is the median of 15 builds of
`addOrrery`, in Node 22, and in C with `-d:release`. They ran in the Claude Code cloud
container on 2026-10-04, and each pair was taken twice:

| Size | JS before | JS after | C before | C after |
| --- | --- | --- | --- | --- |
| Nearest | 6.5, 5.5 ms | 7.9, 7.7 ms | 0.10, 0.11 ms | 0.13, 0.12 ms |
| Neighbourhood | 6.3, 8.3 ms | 14.9, 15.1 ms | 0.14, 0.16 ms | 0.30, 0.30 ms |
| Catalogue | 21.0, 21.0 ms | 159.8, 143.3 ms | 1.10, 1.13 ms | 2.68, 2.60 ms |

Rejected: a motor built for each star, which cost the Catalogue 1,058 ms, because building a motor
is most of what a turn costs. On JS, a turn built on the spot costs 52.5 µs a call, and a turn by a
held motor 24.4 µs. A bearing costs 21.3 µs, a point 9.8 µs, and the reading of two angles 0.7 µs.

Read off the built scene, the normal of Luna leans 5.16° from +z, and that of Io 2.2° from it. The
normal of Miranda has z = 0.155, and that of Triton z = −0.646, a ring run backwards. The horizon
plane is `att(ecliptic) ∧ att(earth ∧ luna)`, and exists only because the ring of Luna leaves the
ecliptic.

**Stated simplifications.** Planets ring Sol in the ecliptic, with the inclinations dropped, of
which the 7° of Mercury is the largest. Earth in the spanned plane is what the horizon block turns
on. The place of a body on its ring is the golden angle, not a date. Neighbour systems lie flat.

**Two catalogues ship, as data alone, and this repository keeps both as written.** A tool wrote each
one once, and that tool stays in the tree that this project came from, so no tool here writes them
again. `neighbourhood.nim` is a snapshot of the NASA Exoplanet Archive, taken 2026-08-31 from its
TAP service (`select hostname, pl_name, sy_dist, ra, dec, pl_orbsmax from ps where sy_dist < 35 and
default_flag = 1`). It holds 331 planet hosts out to 31.5 parsecs. The archive asks for this
acknowledgement, word for word:

> This research has made use of the NASA Exoplanet Archive, which is operated by the California
> Institute of Technology under contract with NASA under the Exoplanet Exploration Program.

`starfield.nim` is a snapshot of SIMBAD, of every star within the same 31.53 parsecs, with the query
recorded in the file. On 2026-08-31 the query returned 11,432 entries, and the table keeps 11,240 of
them. Each of the other 192 is a composite entry, for a double or multiple system as a whole. The
tool that wrote the table cut 180 of them, and 12 are cut by hand by its rule. The cut is not in the
query, so a run of the query alone returns them too.

**A composite entry comes out where the main star of its system has an entry of its own.** Kept, it
is one more point for its system, at a distance that SIMBAD often takes from an older measurement.
Of the 12 cut by hand, 10 stood 0.55 to 6.2 parsecs off their components. `* zet UMa` stood at 26.31
parsecs, where `* zet01 UMa` and `* zet02 UMa` stand at 24.87 and 24.83. The 12, none of which
carried a planet, are these:

- `* mu. Cyg`, `* zet Aqr`, `* zet UMa`, `2MASS J09153413+0422045`, `BD+32 4747`, `BD+49 2959`
- `BPM 14175`, `HD 40887`, `NAME BD-21 1074BC`, `Smethells 177`, `StM 162`, `StM 187`

**A composite entry stays where its main star has no entry, because it is the only point for that
star.** A star has no entry where SIMBAD gives it no parallax of its own. Five such entries stay: `*
zet Cnc`, `G 123-49`, `HIP 110922`, `LP 532-81` and `RX J0507.2+3731`. The main star of `HIP 110922`
is the pair `LP 876-26`, brighter by 0.6 in G than its companion. Rejected: a cut of these 5 too,
which takes their main stars out of the scene. Cost: each stands for its main star at the distance
of its system, up to 4.5 parsecs from its companion.

The rule is the tool's own. Of the 174 composite entries that it cut and that SIMBAD links to their
components, the table holds every component of 145. Of the other 29, it holds the main star alone.
It cut 4 more by name, each the name of its components without their letter. It kept 15 composite
entries whose only component in the table is a B or a C, by name. One is `HD 142`, with 3 planets.

Four entries that SIMBAD links to a companion in the table are stars, and stay: `* ksi UMa B`,
`BD+16 2708`, `HD 61606` and `HD 222237`. SIMBAD types each one as a star, and the table holds no
separate A component for any of them.

Verified by a run of the recorded query against the TAP service of SIMBAD, 2026-10-04. Two more
queries read its links (`h_link`), and the parallax and G magnitude of each component. The query
returns 11,430 entries, and its own bounds mean that the bound of 31.53 parsecs removes none. Every
star of the table is in the result at its distance, 17 of them under a new SIMBAD name. Each of the
other 190 is a composite entry whose main star stands in the table. Of the table, SIMBAD links only
the 5 and the 4 above to a component that the table holds.

Verified by `suites.nim`: the 12 are out of the table, and the 9 are in it, each beside a component
that the table holds.

**A fence keeps `koch fix` out of each table of the two catalogues (Article X.1).** A line `#!fix
off` stands before each `const` table, and a line `#!fix on` after its closing bracket. A fence that
crosses a bracket makes the fix leave the whole file as written, so each fence holds a whole table.
Each table stays as its tool wrote it, whatever rule the fix gains. The type headers stay outside
the fences, so the fix repairs their layout as it repairs any other line.

Verified by `nim r koch fix --dry-run contributor/ronri/rga_visualiser`, 2026-10-05, under the rules
of `8548c96d`: it prints `0 to fix.` for the project. Each fence warns of what breaks inside it:
nothing in `starfield.nim`, and one trailing comment in each table of `neighbourhood.nim`. With the
fences taken out, a dry run of the two files reports those two trailing comments and nothing else.

Each planet host was matched to exactly one star **by sky position alone**, and the worst separation
is 161 arcseconds. The two worst matches are Barnard's and Kapteyn's stars, the two highest proper
motions known. Distance is not used to match, because it is what the two archives disagree about. So
the star layer supplies every position and distance, and the archive only which planets exist.

**Both catalogues are equatorial, and the scene is ecliptic.** `systemAt` turns the direction of
every star by the obliquity that turns the moons. The star field and the planets of Sol then share
one frame. Unturned, every star stands 23° off against them.

**Nothing is generated.** A star with no known planet is a star. The 49 of 544 planets with no
recorded semi-major axis are left out, rather than placed by their order among siblings. `placedOf`
counts what a star places, and `objectsOf` folds it.

Neighbour suns and planets are drawn at `RADIUS_OBJECT_LEAST`, because neither catalogue carries
radii. The plane of a neighbour is joined as `star ∧ along ∧ across`, a point and two directions.
Three of its points a million units out cancel to noise, a tenth of the normal.

**The opening camera frames the system of Sol to Neptune.** `RADIUS_ORRERY` is the own semi-major
axis of Neptune, fitted by `camera.distanceFitting` with `INSET_ORRERY_SHOWN` 24 px. The eye stands
on the reader's own bearing, `RISE_ORRERY_SHOWN` 1.4 over its run, about 54 degrees up. At the 18
degrees of the opening every ring collapses to a line. Rejected: the nearest neighbour, because
Proxima stands nine thousand opening radii out, and a frame that held it shows one dot.

**Colour says what a thing is, not which system it belongs to.** `LUT_INK_BY_ROLE` maps `Role` to
`Ink`: four kinds of body on four handles, and all derived on the fifth, `Olive`, the darkest.

*Checked.* Verified by `suites.nim` at every size:

- every star at the distance that its table gives it, and in the direction that its coordinates give
  once turned into the ecliptic;
- the table ordered outward, and the count exact;
- the camera solve;
- every object against the role table, with four distinct body inks;
- every planet at its real axis with z exactly 0;
- every moon at its real axis perpendicular to `normalOfMoon`, with the leans quoted above pinned;
- the lean and the node of every moon read back off its normal, by vector arithmetic apart from the
  algebra that builds it;
- the ring of every moon started at its ascending node and turned about its normal, which a node of
  flipped sign fails for every moon;
- every body at its phase on its ring against a closed form, which a backward flat ring fails;
- every neighbour planet at its real axis at the height of its star;
- every planet without an axis absent, 49 counted from the table;
- the radius of every body the conversion of its kilometres;
- no point a hub, with lines and planes through any point at 6 or fewer;
- the difference of the two horizon points.

Verified by driven check: the demo button stands the camera back past 40 units. The occlusion check
stands its own camera by the real radius of Jupiter, for a sixty-pixel disc with Io in front of it.
Assumed: the archive snapshots themselves, apart from the count and the distances of the stars
verified above, and the JPL elements transcribed by hand. **No tool in this repository checks a
table against its source.**

## Operation notation

**One table, `scene.LUT_NOTATION_BY_OPERATION`, is read by both builds.** Each entry is the bold
notation of Lengyel, two spaces, then the English name (`𝐦⊖  attitude`). `notationSymbolic` and
`notationNamed` are its two halves.

`notationSubstituted` walks the template token by token, and inserts each operand name once. A name
that contains a placeholder is then never touched again, and a template with `𝐧` twice substitutes
both. A composite name is parenthesised where the template binds it tighter than its own outermost
operator. That is always under a postfix or a negation, and under a binary operator unless that is
its own associative one. So it reads `(a ∧ b)★`, `a ∧ b ∧ c` and `(a ∧ b) ∨ c`, where bare
substitution reads `a ∧ b ∨ c`.

**Every glyph and its placement comes from the declaration doc comment of its own operator**, in
`pga/operators.nim` or `pga/multivectors.nim`. It never comes from the summary table of `pga.nim`.
The "Lengyel" column of that table renders several unary operators in a functional shorthand that
the declarations do not use. It has also carried prefix glyphs where the declaration says postfix.

Verify by codepoint, and not by eye: the U+2212 minus looks like a hyphen. There is one deliberate
exception. `Attitude` reads prefix in its doc comment, and is placed postfix (`𝐦⊖`) on explicit
request, for consistency with every other unary entry.

The five accented operands use **spacing modifier letters** (`ˆ` U+02C6, `ˍ` U+02CD, `¯` U+00AF, `˜`
U+02DC, `˷` U+02F7), and not combining marks. Dear ImGui has no shaper, so a combining form lands to
the right of its operand. The tilde-below of antireverse then reads as the low line of the left
complement. Of the four compound operators only the `★` pair works infix, and `m ∧☆ n` must be
written `` m.`∧ ☆`n ``.

*Checked.* Verified by suite: every entry non-empty, the placeholder rules of the substitution, and
every parenthesis case. Verified by driven check: a join of joins flat, and a meet of joins
parenthesised on the page. Verified by driven check on the desktop: `--drive-faces` asks each face
for every codepoint of the notation (Desktop driven checks). On the page, `driveFacesCovered` asks
the faces that it ships (Faces).

## Naming and number formatting

Basis elements are named exactly as the `$` of the library names them: `𝟏`, `𝟙`, and a bold `𝐞` with
subscript digits. `LUT_NAME_BY_BASIS` **derives** them from the enum, and a suite case holds each
entry equal to what the library prints.

Magnitudes read to **four significant digits** (`DIGITS_SIGNIFICANT`). The desktop uses
`snprintf("%.4g")` into a stack buffer. The browser uses `format.formatMagnitude`, in Nim, behind
`nimFormatNumber`: a decimal exponent by `log10`, scaled digits, and **half-to-even** rounding. C
rounds half to even and Nim's `round` does not: 1012.5 reads `1012` in C, `1013` from `round`.

`formatBiggestFloat` disagrees with itself across backends on 1655 of 7000 values, so it is no
primitive to build on. Both front-ends print a multivector through one writer
(`scene.multivectorText`), and the kind of a multivector through one (`scene.kindText`). Diagnostics
readings keep `%.*f` through `appendFixed`, because a live number that changes width is harder to
read. Fixed char storage is read through `format.toText`, and never through `$toCstring`. That casts
the *address* of the storage, and yields an empty string on the JS backend.

*Checked.* Verified by `suites.nim` on both backends: 17,001 values across 25 decades, including
every exact eighth. There were zero disagreements against the `%.4g` of C, and zero between
backends. The JS entry point pins the text of the tie cases. A C-only `magnitudesAgree` stays green
while 330 of 7000 values differ between the front-ends, so the suite runs under `nim js`.

## Animation

`ANIMATION_MILLISECONDS` 350 and `easeOutCubic` are the one duration and the one curve. A fresh
object grows in over them, and the camera tween eases over them. The browser reads them across the
bridge into `--anim` and `--ease` on `:root`. The CSS curve `cubic-bezier(0.215, 0.61, 0.355, 1)` is
easeOutCubic exactly.

There is one exception, and it is marked as one. The opening hint is a timed disclosure whose delay
lives in the browser scripts alone. A stylesheet `transition-delay` runs from the moment the class
is added, rather than from load, so the two stack.

*Checked.* Assumed: that one duration suits every transition, because nobody has asked otherwise.

## Camera aiming

**The stance an ease carries is a motor and a depth**, the pair that `Camera` holds. Rejected: four
turntable numbers, which carry no roll and stand a rolled view upright.

`toward` eases that motor as one screw. It takes the motion that carries one stance to the other,
logs it, scales it by the progress, and puts it back on. `motors.log` flips the sign of a motion
whose antiscalar is negative, which is the same motion by the shorter arc. A destination just past
−π then stays next door to a camera short of +π, without being told to. The separation eases
geometrically beside it, because it is multiplicative.

**The separation eases from the floor of every separation.** `toward` holds both ends through
`distanceHeld` before it takes their logarithm, so an ease lands on the separation it was given. A
pointer pick of a star at least radius asks for 2.4e-7 units. Rejected: a fixed floor of a millionth
of a unit, which stood the pivot past the star. Each orbit then swung the star off the middle.
Verified by `suites.nim`: an ease lands on the separation of its destination at every decade from
1e-9 to 100, and reads their geometric mean halfway.

The separation is the own depth of the pivot along the sight, so writing it moves the pivot and
leaves the eye. A dolly calls `stanceDollied`, which moves the eye and holds the pivot.
`stanceRepivoted` is the other half: it slides the whole camera between two pivots, as far as the
rebuild moved the eye, and keeps the roll.

`camera.aimIncluding(aim, placed)` folds one placed object into what the camera has been asked to
show, from the placements of the frame. A horizon point contributes its direction, a horizon line
its normal, and a horizon plane nothing. Anything finite widens a bounding sphere about its place,
as `tessellate.anchorFor` reads it.

`CameraAim` is a **requirement**, and a pure function of the geometry, so the standing offer made
again in every frame compares equal. **The sphere is over what has to fit** (`is_bound_by_fitted`).
The first point or finite plane folded in discards what lines gave. A line with its support forty
units off drags the view off the point. A plane widens the sphere by its **whole disc**.

Both builds aim from **one rule**, `framing.offerAim`, once for each frame. It takes the staged
multivector of an open session where there is one, and every selected object otherwise. **The offer
stands**: the tween keeps its goal after it arrives. A camera that the user moves keeps the goal, so
the offer reads as answered. A move made while a selection stands is therefore never taken back.

`release` instead clears it, so the offer is made again the next frame and the camera is taken
straight back. `advance` eases the motion as one screw, and the **distance geometrically**.

**A move that turns lets the pivot finish, and a move that places the pivot stops the ease.** A
turn, roll, plain dolly or key calls `abandon`. The reader then owns the way round and the distance,
and `advance` carries the pivot the rest of its own path underneath. `slideOwed` reads the share of
each frame off `toward`, so the pivot lands where the ease would have put it.

Typed view fields call `halt`, which marks the ease done where it stands. Pan, wheel and two fingers
call `yieldOrHalt`. In free flight it calls `halt`, since each of those sets the pivot itself, and a
pivot still arriving would slide the camera off it. With a selection it calls `abandon`, so the
pivot still lands on what is picked (Framing). Undo and redo call `adoptNext` (Undo/redo).

## Framing

**On a new pick, the orbit pivot comes to the middle of what was picked** (`framing.nim`), by
`objects.centroidFolded`. It runs over the same objects that the bound is over, with each yielded
**once** by `watched`. A middle is a tally where a bound is a set.

The camera then moves by the **least zoom and orbit** on top of that which puts every selected
object in view. In view means the centred box that `camera.reachCentred` shapes. That is
`FRACTION_VIEW_CENTRED` 2/3 of the height, and two thirds of the width **or the height, whichever is
less**. The width is capped because the field of view is vertical. Uncapped, the acceptance edge
stands at 23.9° across a 1440×900 window, against 15.4° down. A pick on a desktop then practically
never moves the camera, while the same pick on a phone does.

`reachCentred` is the one statement of the box: `picking` derives the pixel margins from it, and
`halfAngleCentred` the cone that `distanceFitting` solves.

**Three readings, each following what its shape is drawn at.** The dot of a point fits inside the
centred box, inset by half of `DIAMETER_POINT_LEAST`, the least dot and not its own disc. A disc
that fills half the frame would otherwise push the camera out to hold its rim. A line merely crosses
the box. The **centre** of a plane is in the centred box, and its **rim** on screen. Rejected: the
rim held to the box, which throws the camera from 19 to 29.9 on the ground plane.

**The frame rule is a floor.** `stanceFor` pulls the eye back by the least step that carries it out
to the fitting reach, and never in. A reader who stands further out keeps their own framing. A
finite pick changes neither azimuth nor elevation, except a plane picked alone from a level view.

`camera.stepOutTo` solves `|v + r·u| = reach` for `r`, one quadratic. The positive root is always
the answer where the offset falls short. The term under the root is `along² − outside`, and
`outside` is negative exactly then, so the root is larger than `|along|`. It answers zero where the
eye already stands far enough, and that zero makes the rule a floor.

Rejected: a search, which bisects the separation and the fraction of the move at about 25
projections of every watched object for each pick. The move of the closed form is least by
construction. The pivot goes to the centroid, and the separation gives up exactly what the rule asks
for. `SLACK_FRAMED` 1e-9 is the one tolerance. A `>=` against a reach that `stepOutTo` lands on
exactly reports its own answer unframed, one ulp short of it.

**A plane picked alone from a level view lifts the view off it**, by the ruling of #454. Seen along
its own face, a plane draws as a sliver, and to centre a sliver shows nothing of it. `stanceLifted`
turns the stance about its pivot by the least turn that puts the sight `ANGLE_PLANE_LEAST`, 10°, off
the plane. The eye keeps its side of the plane, and a sight in the plane takes the side that world
up leans to. The pivot, the separation, the level direction of the sight and a level horizon stay.
That direction is the meet of the plane with the one that holds the sight and the normal.

This is the bound that a star gets: a star off screen turns the view, by the least turn. A sight 10°
or more off the plane turns nothing, and no other pick turns. The lift applies once, as the pick
lands. A goal that the tween already holds is the reader's own framing since, and the lift keeps it.
Rejected: a bound by the crossing of the frame, which brings the eye to about 15 units and still
draws a sliver. Rejected: a turn to face every picked plane, which swings the view up to 90°.

**The floor holds while the reader flies.** Where the reader moves the camera and breaks the rule,
`holdFramed` backs the eye out along its own sight. It uses the closed form that `stanceFor` pulls
back with, on a camera that `offerAim` takes by `var`. Nothing turns, so the camera slides along the
bound rather than stopping dead against it. The pivot is stamped again at the depth of the middle,
so the separation follows the eye. After any pick the middle stands on the sight line, so the pivot
is the middle itself.

Rejected: straight out from the centre of the sphere, the least move. That centre is not the middle
once three objects part them, so the push slides the view and the pivot sideways. Rejected: along
the own heading of the reader, which lands further out than the rule asks and needs that heading
threaded through every verb.

**A horizon object binds where it stands, and nothing more.** A star must be on screen, so the sight
falls within the half-angle of the centred box, which binds two degrees of freedom. A horizon line
must only cross the screen, so the sight falls within that half-angle of its own great circle, which
binds one. A horizon plane is always in view, and binds none. `isBounded` states all three.

`holdHorizon` turns about the sight crossed with what is asked for. That axis is the great circle
from one to the other, so a turn across the bound survives. A sight parallel to what is asked for,
straight down onto the normal of the ecliptic, spans no pencil. The camera's own across then stands
in. The angle is `arctan2` of the bulk norm of the pencil and the inner product. `arccos` of the
product alone reads 2e-8 rad off a parallel pair, twenty times `SLACK_FRAMED`.

**The finite object wins outright.** `isBounded` and `holdHorizon` both stand aside where anything
finite is asked for. A star behind the reader, beside a point in front of them, has no placement
that shows both. The finite selection is the one a reader works on.

**A horizon object already in view keeps the framing of the reader**, as a finite selection that
already fits does. `stanceFor` turns toward a star only where its own bound is broken. It stands the
level stance facing it about the pivot (`camera.stanceFacing`), because a least turn off a steep
sight leaves the view rolled. Without the floor, a pick of something already on screen pulls the
view about. The comet drifted 75.5 px against a band of 5 to 60.

**A pick renews a held goal.** The `is_renewed` of `aimAt` arms the ease again for a pointer pick
whatever the tween holds. Without it, the same object picked again after a wheel out goes nowhere.

**So does a broken frame, once the ease has arrived.** A still camera out of frame is eased back,
though the tween holds its goal. That is how a resized window and a restored stance correct
themselves. An ease still running is left to land, since to arm it again at each frame restarts it.

**A turn inside the ease still turns about the middle of what is picked.** A finger that adds an
object and turns at once lands inside the 0.35 s ease. `CameraTween.abandon` gives the turn to the
reader, and the pivot still arrives, 0.000 units from the middle. Rejected: a stop of the ease,
which left the pivot 23.2 px off the middle of two points on a 390 by 844 phone.

**A notch, a right drag or two fingers inside the ease, with a selection, still land the pivot on
what is picked.** Each turns, dollies or rolls about the pivot the camera already has, so each
yields as a turn does (`interaction.yieldOrHalt`). In free flight each places the pivot, and stops
the ease where the camera stands. Rejected: a halt in both states, which leaves the pivot off what
is picked. Every zoom and turn after it then goes about that point.

*Checked.* Verified by `suites.nim`:

- a re-pick after `abandon` and a dolly re-arms;
- the step out reaches its own distance, and answers zero from every stance already past it;
- the floor leaves a camera standing further out alone, and backs the near one out along its sight
  with its bearing held;
- a pinch past the floor, over three points whose middle is off their sphere's centre, backs out
  along the sight;
- the pivot stays on their middle there, and through sixty orbit steps after it;
- a turn at a fifth of the ease still lands the pivot on the middle of two points, and keeps the
  turn, as `settle` does;
- a pan mid-ease halts it, and the pivot stays where the reader put it;
- a notch or a right drag mid-ease with a selection still lands the pivot, and keeps the reader's
  distance;
- a frame narrowed to half its width asks for more room, and the same floor supplies it;
- a still camera that a resize leaves out of frame eases back, though it holds its goal;
- a stance that history restores stays while framed, and eases back where it is not;
- a horizon point is bound to the screen, a horizon line to crossing it, a horizon plane not at all;
- a plane picked alone from a level view lifts the sight to 10° off it, on the side of the eye;
- so does a plane seen from below, a sight in the plane, and an upright plane;
- the pivot, the separation, the level direction and a level horizon stay through that lift;
- a sight already 28° off the plane turns nothing, and a point picked turns nothing.

Verified by driven check:

- the preview framed with its operands;
- a move with a selection standing, through `driveTwoFingerPan` and `drivePan`;
- a finger adds a second point and turns as the ease is armed, with the pivot 1.500 short; it ends
  0.0000 from their middle;
- a comet in view, picked, still pacing the screen at 35.1 px against a band of 5 to 60;
- a notch and a right drag two frames into the ease of a right-click pick of `b` leave the pivot 0
  off it. A halt leaves it 4.80 off;
- a spread of two fingers at the same moment leaves it 0 off too, against 4.80 with a halt;
- a pick of the ground plane from 1.375° above lifts the elevation to 10.000°, and a pick from
  28.072° leaves it at 28.072° (`drivePlaneLifted`).

## Approach to a pick

**A pointer pick centres its object, and comes in to it.** A click or a tap on a point or a line
records a `framing.PointerPick`, which `offerAim` consumes on the next frame. The destination is
`stanceApproaching`, which puts the pivot on the own anchor of the object. Every pick therefore
centres, whether a pointer made it or the objects list did.

The camera slides and never turns, so the angles and roll survive. `stanceRepivoted` carries the
pivot onto the object, and `stanceDollied` sets the reach. Rejected: the object held under the pixel
clicked, which stands the pivot units off, so every orbit swings it round the screen.

**How far in depends on the shape, and on what the reader could see.** It is sized on the height of
the frame by `camera.depthSpanning(diameter, fraction)`. A point drawn at the floor dot is only a
place. The camera comes in until its disc spans `FRACTION_HEIGHT_APPROACH_POINT` 0.01 of the height
of the frame, chosen by eye, because a sixth was too close. A point seen at its size, and a line,
come in no further than the orbit distance.

A plane comes in until the diameter of its whole disc spans `FRACTION_HEIGHT_APPROACH_PLANE` 0.40,
the reach its own centre asks for, which no crossing enters. That is not the centring rule for a
plane, which never pulls in.

A star or a planet of the demo carries `RADIUS_OBJECT_LEAST`, so a pick of one comes in to 2.4e-7
units. The pivot lands on it there, and it reads in front (Camera aiming, Picking). An orbit there
keeps it mid-frame however far out it stands, and however far off the pick starts. The destination
is held about the place of the star itself, and the ease lands on it exactly (Origins).

**An object behind the reader is left to the frame rule.** To centre one would slide the camera back
past it rather than turn, which is a jump nobody asked for. `stanceApproaching` answers none there,
and `stanceFor` takes it by its own bound. Ahead is judged against the reach of the object from the
eye, as a pick judges a hit (Picking). Verified by `suites.nim`: a pointer pick of a small object up
close comes in to it, and one behind does not.

**A dot picked alone never lands nearer than its fit**, by the ruling of #535. The fit is the depth
that a pointer pick of the dot comes in to. The wheel over empty sky can take the separation to
9.4e-8 with no visible change. Without this floor, a star picked from the list keeps it, and draws
about 20 px across. `stanceFitted` dollies the destination of the frame rule out to the fit, once,
as a new goal lands. A separation past the fit stays, and so does a stance set after the pick.

A point seen at its size has no fit, so the working scale of the reader stays. The fit is capped at
the reach of the dot, so the eye never moves further off than the dot stands. A group, a line and a
plane keep the frame rule alone. `stanceFitted` reads the dot by its reach from the eye. Rejected:
its depth along the sight, which reads every dot behind the eye as seen at its size. Rejected: a fit
for every point, which takes a point at working scale out to 19.3 units.

Verified by `suites.nim`: a point picked from the list never lands nearer than its fit, and one
further out stays. Verified by a Playwright script that is not kept, in the Chromium of Playwright
under SwiftShader, on 2026-10-05. After 175 notches over empty sky in the demo of 5,038 objects, a
tick of HD 222237b settles at 2.414e-7 units. The star then draws 7.7 px across in a canvas 771 px
tall, against 19.9 px at 9.38e-8 without the floor.

*Checked.* Verified by `suites.nim`:

- a pointer pick lands the object within 0.01 px of the frame's middle, from every angle swept;
- a pick of a point at least radius lands on its fit, in front and picked, at 1 and 2.36e6 units;
- its pivot stays on it through an orbit, to a millionth of the separation;
- an orbit of 0.7 by 0.3 then leaves it there;
- a pointer pick and a pick from the list land on the star from 40 to 3.19e6 units off;
- their pivot stands on it to a millionth of the separation, and an orbit keeps it there;
- the arrival distance equals the fit, and the reach to the object equals it too;
- a near point and a line keep the orbit distance, and one behind the reader is refused;
- the arrival of the plane from 12 units and from 1.

That sweep, on the C build on 2026-10-17, reads the worst pivot 1.7e-8 of the separation off. A
destination held about the view origin of the starting eye read 7.0e-3 off in the same sweep.

Verified by driven check:

- a right-click 155 px off the middle settles the object 0.00 px from it, with the eye brought in
  from 45 units to 19.3;
- a second pick after a wheel out past 100 comes in to 19.3 again;
- a right-click on the ground plane from Home settles its centre at 48.28, which is exactly the
  depth wanted for 0.40;
- a first left-click on LSPM J0344+0741, 3.19 million units out, holds it within 0.01 px of the
  middle through four orbit drags (`driveFarPick`).

Verified by a Playwright script that is not kept, in Playwright's Chromium under SwiftShader, on
2026-10-04. A click on HD 222237b in the demo of 5,038 objects settles at 2.413e-7 units, with its
ring and label at the middle. A mouse drag of 215 px then turns the sight 13.4° about it.

## Objects search

**A search narrows the objects list to the objects that answer every word typed.** A word answers
where it stands in the label or in the kind word, with ASCII case folded. So `jup` finds `jupiter`,
and `horizon` finds each horizon object, whatever its label. `scene.isMatchingSearch` holds the rule
once, and `scene.handlesMatching` filters creation order by it. The page reaches both through
`nimSceneHandlesMatching`, and the window calls them itself.

**The selection and the row open for edit stay listed, whatever the search says.** A reader never
loses what they picked, or the row that they type into. A kept row stands in creation order among
the matches, where it stands with no search. Both are kept only while a word is typed, since a blank
search lists everything, and `scene.isSearching` says which, on both front-ends.

`scene.handlesMatching` counts the matches apart from the rows that it keeps. Where nothing matches,
the note heads the list, above the kept rows, so no kept row reads as a match. It marks each kept
handle once, because a scan of the whole selection for each handle costs 25 million comparisons at
capacity. While a word is typed, a change to the selection filters the list again.

**The search stays reachable while the list scrolls.** The page pins `.objects-search` under the
pinned heading, at the height that the heading measures. The window draws its field above the
scrolling region of its list, so one rule has two mechanisms, as the heading has. While a search
narrows the list, the field shows a count, such as `12 of 5038 shown`, and `select all`.
`wording.appendShownCounted` writes it for both, so `format.appendInt` branches on the backend.

**`select all` adds the rows shown to the selection, after the picks already made.** The rows shown
include the picks, so a replacement would reorder them, and operands `m` and `n` would move. New
rows join in the order shown, newest first, so two searches, each followed by `select all`, pick
both sets. `selection.addAll` makes one change for any count of rows, and none for no new row.

**`/` reaches the search from anywhere.** It opens the list and gives the field the keyboard. It is
an accelerator of the panel and not a key that the view answers, so it stands beside `ctrl+z` and
not in `interaction.Key`. Both front-ends read the character printed: the page reads `e.key`, and
the window the SDL keycode. Escape clears the field, and on an empty field it leaves it, which the
window gets from `ImGuiInputTextFlags_EscapeClearsAll`.

**Cost.** On the page at 5,038 objects, one filter costs 14 to 18 ms, against 5 ms for a blank
search. Most of it is the kind word of each object whose label misses the word. The handler, with
the reconcile of rows, measured 13 to 32 ms for each keystroke. Rejected: a second copy of the kind
vocabulary, to skip the kind word where no kind word could answer. It would save most of the cost on
the page, and it is a second home for the words that `describeKind` holds.

The window filters only when the scene, the search, the kept row or, while a word is typed, the
selection moves. One cache holds the result in creation order, so the window keeps no second order
cache. The fold is ASCII alone, so `é` does not find `É`. A search stays in force after an add, so a
new object that does not answer it is not listed. The count shows that a search narrows the list.

*Checked.* Verified by `suites.nim`, on both backends:

- each word in either place, folded, and a blank search that answers everything;
- creation order kept, each kept row where it stands, and the matches counted apart;
- `addAll` keeping earlier picks where they stand, and adding each new handle once, in order;
- the count reading the same on both builds.

Verified by browser drive (`driveListSearched`, at 5,038 objects):

- `/` with the drawer shut opens the list and focuses the field;
- a deep label that no other label holds leaves its row alone;
- `horizon` lists the 4 that the check counts again, and keeps the pick that it does not match;
- `select all` adds the rows shown after that pick, in the order shown;
- a search with no match shows its note, above the picks that it keeps;
- escape clears the field, and a second escape leaves it.

Verified by `--drive-search`: `/` and a typed label, posted as SDL events, narrow the list of the
window to the 1 match of 5. A pick made first stays listed, so 2 rows show. A break on purpose,
with `/` wired to nothing, fails it: nothing typed, 5 listed. A second, with the selection not kept,
fails it too: 1 row, and the pick is not listed.

## Hold feedback, help and keys

**A touch hold shows itself.** `interaction` owns `SECONDS_LONG_PRESS`, a `Hold`, and `progressHold`
with `isHoldMature`, and the indicator is the marker itself drawn part-built. Progress is **linear,
and never eased**: it shows a clock, and an eased clock seems to stall just before it fires.

Both front-ends carry a `?` in the bottom-right corner, at least 44 px, which opens the same table
`help.HELP_ENTRIES`, and both render that table. Construct rows derive from `armingOf` and
`isMenuRevealedOn`, and keyboard rows from `motionFor` and `actionFor`. The `operations` tab is
generated from the catalogue, so it cannot fall behind.

**Tabbed by how the reader is working**: `drag`, `select`, `menu`, `panel`, `camera`, `keys` and
`operations`. `ENTRIES_MAX_PATH` is 8 for each tab, with `ENTRIES_MAX_PATH_KEYS` at 13 and
`ENTRIES_MAX_PATH_CATALOGUE` at the operation count. It is asserted at compile time and in the
suite, and it is a **proxy, named as one**. The real constraint is the rendered height, measured as
the overflow of `.help-rows` for each tab. In Chromium at 320×568 on 2026-09-30, `drag` is 94 px
over, `select` 86, `panel` 11, `camera` 103 and `keys` 459. Those tabs are left to scroll on
purpose, on the one screen with no keyboard.

`camera` carries a row for the twist of two fingers, which rolls the view, and that row is 41 of
its 103. Rows say what an input does with a selection in one clause, to hold that cost down. **Every
row makes sense with the rows above covered up.** What a two-column row cannot carry goes in
`descriptionOf`, one sentence for each tab, which crosses as `nimHelpDescriptions`. One word, one
meaning: objects are **selected**, and operations **chosen**.

The two columns of the browser are one grid over the whole table. `.help-rows` is the grid, and each
row is `display: contents`, so a column is one width down the table. Both tracks carry a 122 px
floor, measured. Without the outcome floor the actions took 208 of the 262 px that a 320 px phone
leaves. Rejected: the action track at bare `max-content`, which put `drag` 533 px over.

Rows are hidden by attribute, which needs `.help-row[hidden] { display: none }`. The desktop
measures its outcome column off the widest action **only while the panel is open**. To measure every
frame changed which glyphs Dear ImGui rasterised into the atlas, and moved single pixels of panel
text in the storyboard. `guiChildHeightForRows` asks Dear ImGui for its own line spacing, rather
than restates it. **The help stays open until it is closed.**

**Keyboard.** `Escape` sheds what is in progress, innermost first, and on the desktop it does not
quit, because `ctrl+Q` does. The view is one ordinary tab stop, and **Tab is not rebound**, because
that would trap the reader (WCAG 2.1.2). Traversal is on the brackets.

| Key | Does | Kind |
|---|---|---|
| `w` `a` `s` `d` | fly the view, or orbit whatever is selected | held |
| `q` / `e` | roll to either side | held |
| `space` / `ctrl` | raise / lower it, or orbit whatever is selected | held |
| arrows | turn the view, or orbit whatever is selected | held |
| `-` / `+` | dolly out / in | held |
| `shift` | multiply every rate by `FACTOR_HASTE` | held |
| `[` / `]` | focus the previous / next object | press |
| `enter` | select it, or add it where shift is held | press |
| `f` | frame whatever is selected | press |
| `home` | put the camera back where it started | press |
| `/` | search the objects list, opening it where shut | press |

`motionFor` and `actionFor` split by **kind**. A motion runs in every frame that its key is down
(`driveHeld`), and an action runs once at the press. The bindings follow Unity, Unreal, Godot and
Blender: WASD, shift for faster, and F to frame.

**Every motion key reads by state, and an empty selection is what picks the state.** With nothing
selected the camera flies, and with a selection every motion orbits the sphere about it. `driveHeld`
takes the state as a parameter, because the selection belongs to each front-end and not to
`interaction`. Roll is the exception, and reaches either state. Q and E roll, the sixth degree of
freedom that free flight opens, because a hand already rests on those two keys.

Space and control raise and lower. Both control keys and both shift keys are bound, and the
accelerators read the modifier bitmask, so the binding takes nothing from them. `releaseKeysAll`
empties the held set on a blur, when the tab is hidden, and when a panel widget takes the keyboard
(`gui.wantsKeys`). Save is `ctrl+s`, because `s` flies. The keyboard navigation of Dear ImGui is
enabled, because without it Tab reaches nothing on the desktop.

**A camera move is not a hover.** `isMovingCamera` is the own drag flag of each front-end, plus
`keys_held` through `motionFor`. The movement raises it, not the press, or a click reads a
suppressed hover. **Focus is its own state** (`index_focus`), pruned by liveness and drawn as the
hover marker.

*Checked.* Verified by `--drive-keys`: focus walked, enter selected, and azimuth, elevation and
distance each moved by exactly their own constant.

Verified by browser drive:

- real key events;
- Tab from the canvas moving to the next control and back;
- a blur mid-hold moving the pivot 0.0000 further;
- `[]-+` typed into a label reaching the label.

**Not demonstrated**: Tab landing on a Dear ImGui widget. A window that never takes focus under
`xvfb` gives ImGui nothing to move.

## Style guide

Two documents sit at the root of the repository. `CONSTITUTION.md` is the coding constitution. Its
articles cover exposition, derivation, notation, build-time safety, naming, documentation, cost,
honesty, tests, form and the record. Its precedence clause names the gated mechanisms. `STYLE.md` is
the Nim expression guide.

Every comment is in the register of the `pga` library. That is a one-line imperative summary that
ends in a period, then elaboration as a hanging outline, one claim to a line. It carries no
articles, no history and no figures, and the history and the figures live here. `koch check-files`
holds that register mechanically over every authored language.

**Foreign bindings are marked `sideEffect`, and that is what makes `func` mean anything here.** Nim
assumes that an imported body is pure, so without the mark every GL draw and every Dear ImGui layout
compiles as a `func`. The mark is on every binding in `gui`, `opengl`, `sdl3`, `image` and
`timings`, and on the `importjs` lines of the bridge. `format.snprintf` alone keeps `noSideEffect`
(Render paths). A `func` in this tree means the compiler checked that it reaches no effect.

**A layman knows these acronyms, so they stay in names (V.9).** They are UI, RGB and RGBA, GIF and
PNG, FOV, GL, GUI, DOM and fps, which the root glossary lists. The unit symbols that the root
glossary names under `## Standards`, such as `ms`, `px` and `mib`, stay as well (V.6). Every other
acronym that a field or a library coined is spelled out in its name. So are the astronomical unit,
the cyclic redundancy check, Lempel–Ziv–Welch and model-view-projection.

**Left as they are on purpose**, each against a rule that the reader might expect to see applied:

- the binding names in `opengl.nim` and `sdl3.nim` keep the own verbs of the foreign API. A reader
  greps the SDL and GL references by those names, and the bare-noun rule of V.3 is for this
  project's own properties;
- `nimCameraPivot`, `nimOverlayMetrics`, `nimInkColor` and the scene-listing exports return
  sequences, because something asks them on the UI tick or once, rather than for each frame;
- the FFI-boundary cases of the bridge translate through one `SLOT_NONE` at the return of each proc;
- browser scripts and `shell.html` use snake_case for data bindings and camelCase for callables.

The six overlay exports for each frame answer from module flat buffers. `nimDragTint` binds the ink,
and not the colour, because a `lent` bound to a `let` copies. An array literal handed to an
`openArray` parameter is a `new Float32Array` for each call, which is why the fills are templates.

The `pga` library is unmodified by request. There is one substantive deviation. `pga.nim:28` asserts
that its own module doc is the source of truth for names, which makes the notation trap easy to fall
into (Operation notation).

*Checked.* Verified: `koch check-files` reports 0 findings. The compiler, and not a reading, decides
which funcs stay funcs. The six exports for each frame allocate nothing, read off the emitted JS,
and the gain is **unmeasured**, an allocation count rather than a millisecond. **Unverified**: no
human has read the result.

## Dependencies and vendoring

**The PGA library is a pinned dependency, and never a copy.** It lives in
[replications][replications], which carries no nimble file and holds the library three directories
inside it. So the requirement in `rga_visualiser.nimble` names the repository by URL and commit.
`atlas.lock` records the resolved commit, and `nim.cfg` names the subdirectory that Atlas restores
it to. `koch fetch-deps` replays that lock, and nothing is committed (Article XI.3).

Both projects are under the Prosperity Public License 3.0.0. Rejected: a project verb that clones
it, because CI runs `check-files`, `fetch-deps` and `test`, and never the build driver of a project.

**This project tracks the head of pga, and says so when it cannot.** The standing instruction of the
Architect is to take the latest pga. Where the latest does not work, pin the most recent commit that
does, record which and why, and move forward when it works again. Every pull request states which
commit of pga it builds against, and whether that is head. The pin stands at head,
`295bafc5e97e8ee94943c6f4c7a92f215a74e5e7`, which costs two things, and the instruction is to pay
both rather than trail behind.

**The compiler is pinned by commit, and not by release.** Head spells its operators in prefix and
compound form (`☆m`, `m ∧☆ n`), which needs seven Unicode operator characters that Nim gained in
pull request 26074. That was merged to `devel`, and carried by no release. So the pin is `requires
"nim == 27763495bcfe265507ca98aedc1c7064bf1e0e4d"`, which `toolchain.nim` accepts beside dotted
versions, and which koch fetches and builds once for each machine.

Rejected: a `devel` label, a moving pin that records nothing verified. Rejected: a wait for a
release, which is months of standing behind the library that this project exists to exercise. The
pin moves to a release once one carries 26074. The lexer change reaches the own source of this
project: `-☆(m)` lexes as the single operator `-☆`, and is spelled `-(☆m)`.

**Four projections are withdrawn at head, and `projections.nim` stands in until they return.**
`projectCentral`, `projectCentralAnti`, `projectOrthogonal` and `projectOrthogonalAnti` are declared
`{.error.}` while the library rebuilds them as compound operators (`∨∧★`, `∧∨★`, `∨∧☆`, `∧∨☆`). This
project calls two of them at eight sites, so head alone does not compile here. Each stand-in is a
template that carries the definition which the own operator table of the library gives. It is
copied, and never derived, so nothing about the algebra is invented here (Article II.8).

The module is a seam. `scene`, `tessellate`, `interaction` and the suite import it instead of `pga`,
and `export pga except` those four keeps the names from colliding. An import of both raises an
ambiguous call rather than answers from the wrong one. **The guard makes this transitional rather
than a fork.** A `compiles` probe through a qualified call reads the own declaration of the library.
An `{.error.}` then refuses the build the day it gains a body, and names the module to delete and
the imports to restore.

Rejected: a pin held one commit back, which leaves the project behind its own dependency. Rejected:
a reshape of the call sites, which lets the library's build state decide what the visualiser offers.

**Two Atlas defects stand, and the workaround is by hand.** `atlas pin` writes `"objects": {}` for a
repository that carries no nimble file, so the resolved commit is patched into `atlas.lock` by hand.
`atlas` also calls the nimble file "broken" because it cannot parse a commit where it expects a
version, which is cosmetic. The stored nimble of the lock must equal the committed one exactly, or
`rep` reverts the pin silently (repository issue 25). The static pass refuses the difference, so the
hand-patch is checked rather than trusted.

*Checked.* Verified by a run on the pinned commit, through `koch test`: every suite on the C
backend, on JS, and at reduced capacities. It ran at the same case counts that the previous pin
produced, which says the stand-ins behave as the own ones of the library did. Verified: with
`dependencies/` deleted, `atlas --noexec rep` clones and checks out `295bafc`, `atlas changed` exits
0, and the nimble file is byte-identical afterwards. Verified by a run that the guard fires.
`pga.nim` patched to give `projectOrthogonal` a body refuses the build at `projections.nim(40, 10)`,
and names the module to delete and the four imports to restore.

Verified: the pinned compiler reports `git hash: 27763495bcfe265507ca98aedc1c7064bf1e0e4d`, which
`toolchain.runningCompiler` reads. Assumed: that no release carries 26074. 2.2.12, 2.4.0 and 2.6.0
were asked and none does, which dates the claim rather than proves it.

## Testing

The suite runs from thin entry points that `koch` runs through testament:

| Entry point | Backend | Capacities | Why |
|-------------|---------|-----------|-----|
| `test_4d.nim` | C | Default | The desktop build, as shipped |
| `test_4d_browser.nim` | JS | Default, 4 history steps | The browser build's own backend |
| `test_4d_small.nim` | C | 12 objects, 12-char labels, 4 steps | Boundaries a test reaches |

The JS row is not a formality: a rule reached through two mechanisms is held together only where
both run. It keeps 4 history steps, because the History laws say nothing of the backend. Measured on
Node 22 on 2026-09-24, its run takes 48 s against 162 s at the default, and the orrery still runs.
The reduced row makes any constant tuned to the default fail, and `LABEL_MAX` at 12 is under several
labels that the suite constructs. Cases that need C, such as `snprintf`, the encoders, the arena,
and save and load, guard themselves with `when not defined(js)`.

A case that walks every pair of handles at 10,000 objects runs ten minutes without output, so the
suite gathers the joiners once instead. The JS entry point declares `targets: "js"` and no command
of its own. So `koch test` compiles it with the JS backend and runs the result through node. Its
file, `tests/suites.nim`, imports one module for each suite from `tests/suites/`. Top-level tests
compile into the init function of their module, so one module makes the suite one C function. Cold
on four cores, `gcc` took 122 s on that, and the split `test_4d` compiles in 12.6 s (2026-09-24).

**The suites test rules, and a second layer drives events** (Driven checks, Desktop driven checks).
A rule bug earns a suite case, and a wiring bug earns a driven check, at the layer that the bug
lived at. A driven check is evidence only for the page just built, so one command rebuilds before it
drives (Article IX.6). A check that leaves state behind taxes every check after it, and says so.

*Checked.* Verified on the pinned commit through `koch test`: every suite on the C backend, on JS
and at reduced capacities. The JS count is lower because the C-only cases skip themselves. Verified
on the runner as well as locally: the C suites bind zlib for the PNG encoder. Their passing proves
that the runner carries that library. Assumed: nothing about the suite itself.

## Known limitations

- Every result is software-rendered and machine-driven, and the page has run on one Android phone.
- Tab landing on a desktop widget is unverified (see Hold feedback, help and keys).
- Two crossing translucent veils blend order-dependently.
- A camera move is not undoable on its own.
- The residual steps of the comet at fast orbit rates are unexplained (Marker pulse).
- Neither catalogue is checked against its archive by any tool.
- No tool in this repository measures the palette floors again (Colour palette).
- The frame-time tail on real hardware is undiagnosed, and this container cannot see it.
- The conformal metric (`IS_CONFORMAL`) is unfinished in the library, and this build is rigid 4D.
- `.rgascene` is little-endian by rule, but only a little-endian host has ever written or read one,
  so the byte-swapping path is unexercised.
- A page whose WebGL lacks `EXT_frag_depth` keeps linear depth. It keeps the fault of the far field
  with it, and the disc of every plane at the depth of its centre.
- The planet inclinations, ring phases and neighbour planes of the demo are stated simplifications.
- Far from the world origin, storage steps: by 17 to 35 m two million units out, as at HD 222237 b
  of the demo. A stance that history restores, and the aim of several objects, step with it
  (Origins, Classification at any scale).
- A pick made from afar reads the place of its object about the view origin where the camera stands.
  So the pivot lands a world step or so off the object. A probe that is not kept read 176 m at 4.7
  million units, where doubles step by 139 m, on 2026-10-05. A second pick from near read 0.000 m.
- Far out in a dense field, each of two fingers holds the star that a tap there selects, at the own
  depth of that star. 1.0e7 units out over Sol, fingers 40 px either side of it held stars 1.43e7
  off. A spread of four then carried the eye past Sol (Two fingers).
- A line drawn with the camera inside the body that it frames stands a few pixels off the point that
  it joins. The error is 0.4 px at an orbit distance of 0.0001, and 3.2 px at 0.00001. Float32 holds
  about 0.06 of a unit at 530,000 units, and the record stores the vanishing point in it. The near
  crossing is not the cause (Records and shaders).
- The two front-ends still differ in these inputs. A read of the code on 2026-10-12 found them, and
  no run has checked them yet:
  - Escape clears or keeps a selection in another order on each front-end.
  - Undo and redo follow the printed key on the page, and the place of the key on the desktop.
  - With no pointer, the page hangs the selection menu from its corner, and the desktop centres it.
  - `more…` opens its picker at the cursor on the page alone.
  - Hide or delete of several objects takes one step of undo on the desktop, and one for each
    object on the page.
  - The field of view takes any value on the page, and 10 to 120 by drag on the desktop.
  - An empty distance field reads 0.1 on the page, and the near limit on the desktop.
  - Alt with a view key moves the camera on the desktop alone.
  - While the camera moves, the page keeps hover on what slid under a still pointer.
- Control does not descend while it is held, on either front-end. Its own key press carries the
  modifier that both guards refuse. The same read of the code found this, and no run has checked it.

[replications]: https://gitlab.com/mraxilus/replications
