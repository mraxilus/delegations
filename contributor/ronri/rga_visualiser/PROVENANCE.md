# Provenance

_Who made this, from what, and how far it has been checked._

| Field   | Value |
|---------|-------|
| Harness | Claude Code |
| Author  | Claude Opus 5 and Claude Sonnet 5 |
| Date    | 2026-09-06 |
| Style   | CONSTITUTION.md and STYLE.md, followed. |
| Rules   | 6e80b1a8de3ee978 |
| Pruned  | ca56fd4f8b61f44d3b38f3533ba0f177c4cc27b8 |
| Review  | **Unreviewed.** Nothing here has been read line by line by a human. |

An interactive visualiser of rigid geometric algebra objects, built as a testbed for the
`pga` library: geometry and a scene model shared by two front-ends, plus the encoders a
scripted storyboard writes its frames through.

This file records the **current** design by subsystem and the reasoning behind decisions
that are not obvious from the code: what was chosen, what was rejected, and what the choice
costs. It is not a changelog. A rejected alternative appears only where it is still a live
trap, as a terse "not X — Y"; a figure is kept beside the constant it justified, because
the comments in the source carry no figures (Art. VII.5). What came out is in git: the
`Pruned` row names the last commit that still carried the pruned text.

**What is here.** The render-path-independent core under `src/rga_visualiser`; the browser
front-end under `src/browser`, its page under `pages/` and its harness under `tools/drive/`;
the desktop front-end under `src/desktop`, with the PNG and GIF encoders and the arena they
write through; and one suite run in three configurations. Every section below describes
code this repository builds and drives.

**How claims are marked.** Each subsystem closes with a *Checked* block. *Verified* means
the claim was established by running something and names what; *Assumed* means it rests on
reasoning alone. A figure without a *Verified* line beside it was once read off a panel and
not re-measured since; treat it as indicative. Six tools the prototype carried —
`check_palette`, `check_atlas`, `check_prose`, `check_columns`, `verify.sh` and
`verify_touch_pan.js` — are not in this repository; a claim one of them held is marked as
held by that tool then and re-verified by nothing here.

**Verification practice, applies throughout.** Every change is rebuilt and the full suite
rerun through `koch tests`, on the C backend at two capacities and on the JS backend, and
both front-ends are driven through `tools/build.nim drive`. **No human has driven either
front-end, clicked a button, or seen this on real GPU hardware**; every figure in this file
was software-rendered.

## Vocabulary

**The terms are the Architect's, in `GLOSSARY.md`, and the code says them.** A rename here is
never a substitution, since every word named more than one thing and only one sense moved, spared
by an explicit list rather than by a rule: `slot` meant an address, an `Ink` palette position and
a timing array position, and only the first is `handle`; `target` meant the orbit centre, the
object a press points at, the DOM event target, a render target and a plain goal, and only the
first is `pivot`; `budget` names real allowances of time, pixels and segments, where the
frame-rate lines are `mark`s because nothing is held to them.

**Three names could not be taken, and each says why in place.** `object` is reserved in Nim,
so code-position `item` took a role instead — `one` where an object is reached through the
accessor, `saved` where a record is read out of a file. `handle` collides with std's
`typedthreads.handle`, which wins over an injected local inside a template, so `picking`
turns on `openSym`. `iterator items` keeps its name because it is Nim's own protocol.

**Two spec keys must never be renamed, and neither would fail loudly.** `targets: "js"` is a
testament key; renamed, the browser suite runs on the wrong backend. `visualiser.items_max`
is a compile-time define named in the small suite's `matrix`; that the constant and the
define still meet is checked by compiling against it.

**Uppercase constants sit outside word boundaries**, so a rename by word misses `ALPHA_WASH`
and `WIDTH_SHAPE_WORD`; the compiler names each miss. **`GHOST` could not become
`PREVIEW`**: Nim compares identifiers ignoring case after the first letter and ignoring
underscores, and type `Preview` exists, so `none(Preview)` resolved to the renamed variable.
It is `PREVIEW_EDIT`, beside `PREVIEW_APPLY`.

**`horizon` stays `pga`'s word** and has no entry here: the algebra's vocabulary belongs to
that library. An ideal object does not sit *at* the horizon, it lies *in* it, so the kind
words a reader sees are `horizon point`, `horizon line` and `horizon plane`.

*Checked.* Verified after every rename: every suite unchanged, case for case,
which is what says no behaviour moved; `tsc` clean after `bridge.d.ts` is re-derived;
`koch tree` at 0 findings; both front-ends built and driven.

## Wording Catalogue

**Every word either front-end shows has one name in `wording.nim`, and neither writes a
literal.** Shown text written where it is drawn puts one sentence in two places, and two places
drift: the window and the page had said different things about the same wedge, the same
coefficient grid and the same outcome. The catalogue is a `Wording` enum and a table indexed by
it, so a key renamed there fails to compile rather than failing to match.

**The page fills its markup at build time rather than at load.** Its labels live in markup, not
in TypeScript — 44 static text nodes against 6 written from scripts — so stripping an attribute
and setting it from a script, which serves a tooltip, would empty 44 elements, invent 44 ids and
leave the page blank until its scripts ran. `tools/build.nim` already rewrites `shell.html` on
the way out for `@SCRIPT@` and `@EMBED:<face>@`; `@WORD:<key>@` joins the same pass. The real
text is therefore in the committed markup, so it reads with the first paint and with scripts
refused. A token naming a key the catalogue does not carry stops the build.

**The guard is total rather than a list of forbidden strings.** `checkWording` refuses a quoted
literal at any of the fourteen panel calls that put text in front of a reader, and at `.title`,
`.textContent` and `.innerHTML` in every browser script; a hidden Dear ImGui id (`##name`) and
an empty label are allowed, since neither is shown. It also refuses the opposite defect — a
catalogue row no front-end names — so the catalogue cannot grow words written for nobody.
  `tools/build.nim` imports the catalogue rather than parsing it: reading `wording.nim` as text
  to recover the enum's keys stops at the first blank line inside the enum, where walking
  `Wording` after importing it fails to compile when a key moves.

**One key per control, not one key per word.** `NameRowHide` and `NamePickHide` both read `hide`
and are two keys, because two buttons honestly wear one word and a translator may still need
them apart. The law that no two keys carry the same text therefore holds over **prose** keys
alone — the tooltips and notes, where a repeated sentence is a copy-paste. Labels carry their
own law: stripped, no doubled space, no trailing full stop, at most `RUNES_LABEL_MOST` runes.

**Every control both front-ends have is explained on both, from one key.** The page hangs
34 of the 40 `Tip` keys on its controls, set from scripts at load since the markup carries no
`title`; the six it does not are the window's alone — its two file-path fields, its vsync
switch, its two arenas, and its scene block, whose page row reads a count over a capacity
rather than the bytes the sentence names. A control the page has and the window explains
without the page explaining it is a gap to close, not a design choice.

**The application names itself once.** `NameTitle` reads `RGA Visualiser` and both front-ends
take it; the window's caption is `captionWindow()`, which reads the catalogue rather than
spelling the name a second time. A law requires that name to be title case and every other label
to stay a word.

**Help rows and outcome sentences are the catalogue's too.** A help cell is a `Help` key, a
tab's title a `NameTab` key and its line a `NoteTab` key; `help.nim` holds which cell sits in
which row and nothing a reader sees. A cell is neither label nor sentence — it is read across
its row — so it carries its own law: no capital opens it, no full stop closes it, and no two
say one thing. A row naming a button or a key composes it through the catalogue's own funcs
(`withButton`, `namesJoined`, `sectionNamed`, `wheelWordsTaught`), so the glue between a
button's name and its words is the catalogue's as much as the words are, and the menu tab
names each button by the button's own key, so a renamed button is renamed in its row. Outcome
sentences are composed here as well, `derivedMessage` among them, which four sites had each
written out; `message.nim` keeps how long an outcome stands. The guard sweeps `help.nim` for
any quoted letter, since a word quoted there is a copy the catalogue cannot see. Not here: the
algebra's own words — operation names and notation from `pga`'s declarations, kind words, key
and button names — which help composes with rather than copies.

*Checked.* Verified by build and by driven check: `declare` reports **173 wording keys**; a
literal put back at a label call is refused, which is how three page-only strings in `state.ts`
were found; a key named only inside the catalogue is refused as shown by nobody; and a `@WORD:`
token naming an absent key fails the build with the line that carries it.

## Driven Checks

**Suites test rules; this layer tests wiring.** Nothing in the suite presses a key, turns a
wheel or puts two fingers on the canvas, so nothing in it catches a rule wired to the wrong
event. `tools/drive/` does, through Playwright, against the page `tools/build.nim web`
assembles; `nim r tools/build.nim drive` runs both front-ends.

**Every check passes**, one module per section of what the page does. `drive` counts them
and this file does not:

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
| `message`, `style`, `type`, `canvas` | outcome fade, declared CSS, faces in roles, blank refused |

**Timing-dependent quantities are asserted as bands, never figures.** How far a held key
travels depends on frames drawn while it was down. A band that will not settle is widened
with its reason recorded, never deleted and never narrowed to fit one lucky run.

**Accounting allows two frames of its sample to miss, as a count rather than a share.**
`ceil(0.995n)` equals `n` for every `n` under 200, so a share demanded every frame at
`loaded`'s 49-frame sample; one definition, exported from `scenery` (repository issue 47).
Per-frame tolerances are untouched: a real accounting fault misses on every frame.

**Count the mechanism the claim names.** The panel's cadence check counts `askSlowPass`,
the tick's own entry (asks are `ceil(ticks/5)`), not calls to `drawExceedance`, which the
axis switch and the gliding axis reach too — 138 of 138 on one run, 137 on the next,
identical code. Verified by breaking on purpose: four axis presses in the window.

**Waits are conditions the page reports, not spans of clock.** Camera ease and settling
after a click are `waitForFunction` over what the page says (`settleCamera`, `settleCount`,
`settleSelection`, `settleDrawer`, `settleHelp`, `settleBranch`, `settleReading`); pacing
inside drag loops is `waitFrames`. The 16 fixed waits that remain are measurement windows,
each saying so at its site. `settleReading` waits on `ms_refresh_ui`, the tick's own clock,
never on a row that tick writes, or the wait would assert what the check goes on to ask.

**Settle on what moves, not on what has stopped changing.** Two polls of an unmoving stance
agree before an ease has begun, so `settleCamera` asks the ease — `nimCameraCarrying`
reports `goal.isSome and not is_arrived` — and waits one draw first, since that draw arms it
(repository issue 73). Verified by breaking on purpose: returning at once, every loss is
framing.

**Pixels are read through the compositor, and a reading carrying no picture is refused.**
The context keeps no drawing buffer (`gl.ts` says why), so `readPixels` is sound only from
inside the frame that drew, and checks comparing one such reading against another pass on
a canvas reading back all zero. The reading is `page.locator('#gl').screenshot()`, decoded
in the page, through one `tools/drive/canvas.ts`; it raises rather than reports, since a
canvas nobody can read is the instrument lost. **Refusal is of one colour, not of black**:
the runner has answered a sheet of white as readily as one of zero, so the fixture drives
both. Every sibling of the canvas is hidden by `opacity` for the capture, and the reading
is taken again until it carries a picture, up to ten times, since hiding chrome forces a
recomposite a software rasteriser does not finish inside one frame. Costs about 0.49 s per
reading, about 19 times a run. **Unexplained**: why the runner read blank through
`readPixels` and white through the compositor; neither Chromium here reproduces either.

**The harness resolves its own browser, and drives Playwright's pinned build by default.**
What `RGA_CHROMIUM` names, else the build `package-lock.json` pins, else `chromium` on
`PATH`, which on Ubuntu 24.04 is the snap shim alone (repository issue 77). The lock fixes
`@playwright/test` at 1.63.0 and that fixes the browser revision, so this machine and the
runner drive one binary, and `check.yml` caches `~/.cache/ms-playwright` on that same lock.
The pin is a version, not a digest: Playwright publishes no checksum.

**TypeScript rather than Nim, argued rather than assumed.** The harness's calls are
overwhelmingly `page.evaluate` bodies naming the bridge's exports, which
`build/bridge.d.ts` types; through Nim's foreign-function glue each is an unchecked string
(repository issue 48). Page-script names the harness drives are hand-declared in
`tools/drive/page.d.ts`, so renaming one breaks the harness rather than the page.

**A dropped CSS declaration is invisible to the CSSOM, so the check reads authored text.**
A parser discards a declaration whose property it does not know, so a sweep over `cssRules`
passes on the very page the check exists for. `driveStyleDeclared` scans the `<style>`
element's own `textContent` and asks the browser whether each property name is one it
knows, with a fixture asking whether it can tell `align-items` from `align-objects`.

**The heading checks hold geometry, paint and shape separately.** `driveHeaderPinned` sweeps
`elementFromPoint` across the full band width, since the midline alone passed while rows showed in a
28 px strip. `driveHeaderBanded` reads every heading's computed fill *opacity* at rest and pinned
rather than a notation, since a `color-mix` fill computes to `color(srgb …)`. `driveHeaderStyled`
compares radius and border against `.toggles`; not `.brand`, which takes an accent border whenever
the drawer is open.

**The list is held to a window, never to a fill.** `driveListWindowed` shuts the objects
section and opens it again, and reads the rows standing before the click returns: they stand
for every object and number no more than three screens of 40 px rows, which is loose where it
must be and still tens against thousands. It then scrolls to either end and finds that end's
row on screen within the same bound. The bound is stated in the check as well as in the page,
since a check reading the window out of the page passes whatever the page does. Time is
reported and never asserted — 3 ms here, with 27 rows standing for 5,040 objects —
since how long tens of rows take is the runner's business, and the count holds on every
runner. `driveEditFromMenu` opens the panel onto the 41st object created, near the far end of
the list, and reads its row as standing before the call returns and as lying under the pinned
heading with its whole form above the scroller's floor.

**A touch id is never reused across gestures, and every gesture starts by asking the page
whether any pointer is still down.** The page keys live pointers by id, so an id reused
from the gesture before overwrites a finger left standing by a dropped or reordered lift in
silence, and the pair the page reads is not the pair the harness sent — which is the one
mechanism found for a two-finger pan reading as a pinch (repository issues 153 and 154). A
fresh id per finger leaves a stale one standing where the guard names it and the gesture's
own check fails on it. The guard reads events the browser delivered, through a listener the
harness installs on `window`, never the page's own bookkeeping: the page's surface is not
widened for a test, and what is asserted is what the page received. It is silent when
clean and reports the stale ids when not, and one positive check stands before the pan,
which follows a tap.

**The chip row's check asserts reach beside fit.** `driveChipRowFits` requires exactly two
toggles wherever they stand alongside zero overflow, since a row that fits because two
controls were dropped is broken more quietly, and sweeps 396, 395 and 394, because a rule
written one pixel out passes every sweep that never lands on it.

*Checked.* Verified by running: every check through `tools/build.nim drive`, both front-ends,
software-rendered, here and on the runner — `driven` gates `audit`, so a green push run is
the runner's own word (repository issues 47 and 91). **Unmeasured**: the figures are this
container's and say more about SwiftShader than about any GPU; bands are what the checks
assert.

## Browser Front-End

**The page is one self-contained file.** It opens from `file://` or from an artefact host
that reaches no font host and no script host, which is why every face is inlined as base64
and every script is concatenated into `pages/shell.html` at its `@SCRIPT@` token by
`tools/build.nim web`. `pages/shell.html` stays whole markup rather than ending
mid-`<script>`, since a committed page that cannot parse alone is a page no checker can read.

**Scripts share one global scope rather than importing each other.** TypeScript 7 removed
`outFile`, so the compiler no longer bundles, and the page cannot resolve ES imports without
a server. Files carry no top-level `import` or `export`, and `SCRIPTS` in `tools/build.nim`
is the order they concatenate in, load-bearing since `const` is not hoisted. Not a bundler,
a second toolchain for one concatenation this build already does.

**Article II.9 is the boundary that matters.** Every join, meet, pick, drag and camera move is
computed by `src/browser/bridge.nim`, compiled from the same modules the desktop draws
through; TypeScript owns WebGL, DOM and pointer events alone. Each script argues for itself in
its header on the phrase `not Nim because`, which `justification.nim` demands of a gated kind.

**The bridge's declarations are derived, never kept beside it.** `tools/build.nim declare`
reads the bridge's own `{.exportc.}` signatures and writes `build/bridge.d.ts`; a
hand-written copy of those signatures would be a second home for each. `types` is `declare`
and both type-checker configurations and stops there; `web` and `drive` both call it.
Verified by breaking on purpose: renaming `nimSceneHandles` alone fails `types`.

**Type-checking runs under `strict`, `noUncheckedIndexedAccess` and
`exactOptionalPropertyTypes`**, as CONTRIBUTOR.md requires. Indexing therefore reports
absence, and the bridge's flat buffers are read through `flatAt` and `pointAt`, since
buffers arrive carrying their own count and every walk is bounded by it. `elementById` fails
loudly for markup this build ships; `elementIfPresent` reports absence for an optional one.

**Node dependencies are pinned and their checkout is not committed**: `package.json` and
`package-lock.json` are committed, `node_modules/` is ignored. `typescript` 7.0.2 and
`@playwright/test` 1.63.0 are Microsoft's, both Apache-2.0; `@types/node` 22.20.2 is
DefinitelyTyped's, MIT, and types the Node surface `tools/build.nim` and the harness reach. Each
licence is read off the package rather than assumed. **System packages are declared as data in
the build driver**: `SYSTEM` in `tools/build.nim` pairs each package with what it is for, and
`system` prints those names for the caller to install (repository issue 60); no package version
is pinned or invented. **`drive` fetches faces; `web` refuses without them**, since a caller
reaching for `web` directly is building rather than being given.

**Faces come from the repository's store; which faces is this project's.** `koch assets` holds
any file fetched at build time — names, digests and the fetch in `curator/audit/src/assets.nim` —
and this project's `assets` verb copies both front-ends' faces out of it (repository issues 116
and 124): the page's `@fontsource` `woff2` (Commit Mono, Noto Sans at 400 and 600, Noto Sans
Math, Noto Sans Symbols 2, Noto Serif; SIL Open Font License 1.1) and the desktop's own, which
`FACES_DESKTOP` names. Commit Mono is `otf` there, which is what its author publishes;
`stb_truetype` reads its CFF outlines. `assets` writes `build/fonts/store.list`, one line per
face naming the store entry it was copied from, and `web` compares its input against that entry
before embedding. Verified by breaking it, twice: `store.list` moved away, and one byte appended
to a copied face. **The math face is pinned one version behind its siblings**, which is the fetch
pinned rather than the family: 5.3.0 renamed its subset, and an unversioned path had kept working
only by falling back to 5.2.8 (repository issue 111).

**Three faces, three roles, and nothing else picks between them.** The Architect's standard:
Noto Serif for titles, Noto Sans for body, Commit Mono for code and monospace, drawn by the
page through `--serif`, `--sans` and `--mono` and by the desktop through `guiHeader` and
`guiMonoPush`/`guiMonoPop`. What counts as a title is looked up: Material 3 puts text inside
components in the label role, so the help tab strip and the toggle chips stay sans and the
serif takes the headings that name a section and the application's own name.
  **Commit Mono splits its ligatures across two switches, and the page needs both.** The
  distributed `woff2` carries `calt`, which browsers apply unasked and most ligatures ride
  on, and the opt-in sets `ss01`–`ss05`, which the arrows and comparisons come from. So the
  stylesheet says `font-variant-ligatures: common-ligatures contextual` outright, since a
  reset writing `none` takes `calt` with it, and `font-feature-settings: "ss01" 1, "ss02" 1`
  asks for what is never on; no combination moves a column. Noto Sans Math publishes an
  `ss01` the mono stack falls through to, and the operators rendered identical either way.
  **The serif ships at 600 alone, because 600 is the weight every title is set at**; a
  weight nothing ships is a face the reader's browser invents (Article X.8). The check reads
  pixels, not width: the heading shot as the page has it and again with the interface face
  forced onto it makes one picture where there should be two, where width cannot part them.
  **The desktop draws the same three roles**: `NotoSerif-SemiBold` matches the page's 600
  and `CommitMonoV142-400Regular` sets notation, with the supplementary ranges merged into
  the mono and interface faces, since those rows carry wedges. Commit Mono comes from its
  author's own repository, since `@fontsource` ships no TrueType. **Ligatures cannot reach
  the desktop at all**: Dear ImGui shapes no text, so no GSUB feature fires.

**The chip row floats over the canvas, and its width budget is measured rather than assumed.**
Six controls ride it and the row is flex, so where it stops fitting what gives is the
controls inside it. Two breakpoints, each swept a pixel at a time: below **497 px** the
brand draws `NameChipDrawer` in place of its name (123 px wide at 497, 34 at 496); below
**395 px** `.toggles` moves into the menu popover under its own `show` heading (1 px over
at 394, 75 at 320). Moved rather than copied: a second pair of buttons would be a second
`on` state to keep in step with the scene's own. `#top-menu-show[hidden]` spells out
`display: none`, since an author `display` beats the user-agent rule for the attribute.

**A section's heading holds its place while that section's list scrolls under it.** `position:
sticky; top: 0` against `.drawer-scroll`, with the clearance the floating row needs sitting on
`.drawer`, outside what scrolls, since a sticky offset is inset by its scroller's own padding. The
heading wears its pill at rest and pinned alike, so a list moving and a list still show one heading.
Not a band only while pinned, watched through a sentinel and an `IntersectionObserver`: a heading
then changed its look between a list moving and one at rest, and the desktop's bar is filled
throughout.

**A heading wears the pill the chip row's own controls wear**, still or scrolling. Same radius, same
1 px `--border`, and the box `.object-row.selected` already uses. The fill is **opaque**, although
the pills it borrows its shape from are `--surface` over a blur: a heading asked to hide rows cannot
be seen through. That fill is the drawer's own ground, arrived at as the drawer does — `color-mix(in
srgb, rgb(22 27 34) 82%, var(--bg))`, where `--bg` is written at runtime by `gl.ts` from the clear
colour — where a named tone drifts. Not a shadow, which made pinning read as *floating*. No rule
under a section: the pills part sections by themselves, and a rule beside them stood as a residual
line over the next pill at rest. The box is **square**, with `.section-header::before` drawing the
pill over it: a radius clips the fill it rounds, so a box that *was* the pill left four corners bare
for rows. Not a backing inside it — `position: sticky` opens a stacking context whatever its
`z-index`, so a negative child paints over its own border. `border: 0`, or the button's own stands.

**Only the rows near the viewport exist.** The list is a window over its keys: two spacers stand
in for the rows above and below at the heights those rows measured, or 61 px until they have, and
the window covers the scroller's height plus one screen either side. A scroll marks the window
stale and the frame loop settles it after the tick's own writes, so the cost lands in the `ui`
phase and the layout its reads force serves the tick too; a refresh renders at once, so a caller
that changed the scene finds its row standing before the call returns. Keys are rebuilt only when
the scene's revision, its count or the composing row moves, so a refresh on selection alone keeps
five thousand keys as they stand. Heights are read by a `ResizeObserver`, never inside the scroll
path, which also catches a row that changes size without rebuilding. Not time-sliced building of
every row, which at 5,038 objects is 2,862 ms of list filling across 33 frames of 80 ms and
45,813 elements standing after; the window opens in 3 ms with 27 rows, and the page then carries
about 750 elements, 250 of them in the list. Scrolling it at 300 px a frame builds about five
rows a frame for 0.8 ms of the `ui` phase, and the frame itself moves from 59 to 62 ms. Not
`content-visibility: auto` over every row, which skips their layout and not their building. Cost:
a row leaving the window is built again on its return, about 0.15 ms each; and a row above the
viewport is an estimate until scrolled to, which the browser's own scroll anchoring absorbs — the
spacers are `overflow-anchor: none`, so the anchor is always a row, and a jump to an estimated
offset with nothing but a spacer in view adjusts nothing.

**A comment may not quote a closing block-comment delimiter.** A comment that does ends itself
on the spot, and the prose after it parses as CSS — enough to swallow 141 of the page's 150
rules with the page still drawing. Delimiters are named rather than quoted.

*Checked.* Verified by running cold: `clean` removes `build`, `bin` and `nimcache`, then
`drive` fetches every face, builds both front-ends and drives them with no step run by
hand, which is the runner's own case; a second run fetches nothing. Verified by
type-checker: every script clean under the three flags above, with no `any` and no non-null
assertion. Verified by driven check: `driveTypeRoles`, `driveTypeDrawn` and
`driveTypeLigatures`. Scene save and load remain **untested** here: nothing drives the file
picker. **Unverified**: no human has driven this page.

## Desktop Front-End

**Two libraries are bound rather than wrapped, and only where they are called.** SDL3 owns
the window, input and the OpenGL context; libGL owns the driver. Both are external concerns
this project exists to look past (Article II.8), so `src/desktop/sdl3.nim` and
`src/desktop/opengl.nim` declare only the symbols called, each through the library's own
header. The library flag sits in the module needing it, never in configuration.

**Mirrored constants are checked against the header's own, by generated assertion.** SDL3's
event kinds, scancodes, modifier masks and window flags are mirrored as Nim constants so
`case` can bind them, each paired with the header's name in one table; `CHECKS_MIRROR` emits
one C++ `static_assert` per pair. Verified by breaking on purpose: `Scancode.Home` moved by
one fails with `SDL3 binding is stale`. OpenGL enumerants are literals, never renumbered.

**Dear ImGui is reached through C entry points, because there is no symbol to bind.** Its
interface is C++ with overloads, default arguments and namespaces, and Nim's `cpp` backend
imports none of the three, so `src/desktop/gui_shim.cpp` flattens the slice this visualiser
calls into plain C and `src/desktop/gui.nim` binds that — a facade declaring exactly the
widgets used. Cost: adding a widget touches two files. The kind is registered *gated*
(repository issue 26), so `justification.nim` demands its header carry `not Nim because`.

**Dear ImGui is compiled into the binary rather than linked, and pinned by commit.**
`fd13a1e8923a0a7077b404fc36fd063b25a0c0b5` of `ocornut/imgui`'s `docking` branch, MIT
licence, cloned into `deps/imgui` and never committed. `IMGUI_USE_WCHAR32` is set by compiler
flag rather than by editing the checkout's `imconfig.h`, since the notation carries bold
operands past what a 16-bit `ImWchar` expresses, and an edit to a checkout would not survive
a reclone. `checkImgui` reads the checkout's own `HEAD` and refuses by name.

**Neither SDL3 nor Dear ImGui arrives as a package, so `desktop` fetches both at their pins.**
Ubuntu 24.04 carries no SDL3 at all. SDL3 is cloned at its tag and built into `build/sdl3`,
a prefix inside the tree, so no step needs root and `clean` removes it; `checkSdl3` reads
what `pkg-config` reports there and the commit the clone stands at, before compiling
anything: `3.2.30`, zlib licence. Neither library is in `SYSTEM`; `cmake`, `pkg-config` and
`git` stay there for their sake.
  **The pin is a release tag, and the commit that tag resolves to is what binds the bytes.**
  `release-` prefixed to `VERSION_SDL3` is the ref that fetches, and `COMMIT_SDL3`
  (`f5e5f6588921eed3d7d048ce43d9eb1ff0da0ffc`) is what has to arrive, read through
  `checkCommit` (repository issue 126): a moved tag fetches other sources while `pkg-config`
  still answers `3.2.30`. Held on the warm tree too, and before cmake. The tag stays because
  `--depth 1 --branch` needs a ref, which is also why a shallow clone is safe here and not
  for Dear ImGui, whose pin sits behind a branch head. **An odd patch number names no tag**:
  the series releases on even numbers alone (repository issue 90); 3.2.30 is the newest of a
  series still maintained (repository issue 111).
  **SDL3's own build dependencies are declared too**: `libxext-dev` arrives under nothing
  else, and without it cmake reports `SDL_X11 (Wanted: ON): OFF` and exits 1. Cost of the
  prefix is `-rpath`, derived from the checkout through `getCurrentDir()`, since a committed
  `/opt/...` builds on one machine; not `/usr/local`, which needs root CI is not granted.

**The renderer owns OpenGL names and draws `mesh`'s records through them, one program per
record kind**, each with a vertex shader widening compact records over static corner
geometry. Buffers are reuploaded whole each frame rather than tracked for changes: upload
sits far below any frame's own reach, and nothing can be stale after an edit. The same
records the WebGL side draws, which is what makes this a cross-check rather than a second
implementation. **The panel holds only what the GUI needs between frames**; everything
else is read straight off scene and camera. **The entry point owns the window, the event
loop and every headless run**, with run modes — `--screenshot`, `--frames`, `--hidden`,
`--storyboard`, `--timings`, `--novsync`, `--fill`, `--demo`, `--drive-*` — each pushing
real events through SDL's own queue rather than calling a handler.

**The desktop's compiler flags live in the build driver.** `tools/build.nim`'s `desktop` verb
passes the `cpp` backend and the output path; not `main.nim.cfg`, which Nim picks up
automatically and applies invisibly to any build of that file. No `-d:release`: this binary
is driven and read, and its `--drive-*` runs report through assertions release removes.

**The constant controls float in an overlay of their own, not inside the panel window**,
where they went with it when it collapsed: one line in a `windowBeginPinned` overlay, the
door `?` uses, top right since the panel opens at the top left. The menu hangs by its
**right** edge: anchored by its left it opened past the window and was clipped, and no check
caught it, since the verdict asks what the menu *offered*. A change that alters what a
window shows ends with a picture for that reason.

**Both front-ends offer the same three menu groups, and the demo group is built rather than
written.** It walks `orrery.ScaleOrrery` and labels each button with `objectsOf`, as the
page builds its own from `nimDemoScales`, so a size added to `orrery` arrives in both. Two
deliberate differences: the desktop's menu carries `scene file` and `image file` fields,
because a desktop build writes to paths; and the menu hangs from its own button rather than
from the pointer, since a menu landing somewhere different each time is one the reader has
to find twice. `--drive-menu` opens it with no pointer through `guiMenuBegin`'s `is_forced`.

**A long list is bounded rather than left to run past the window.** It hugs its own content
until the window runs out and scrolls inside that bound after (`ImGuiChildFlags_AutoResizeY`
under `SetNextWindowSizeConstraints`), with the heading outside that region so it cannot
move; not a fixed height with a threshold, which put a five-object scene in a box of blank.
**Toggles are pills on both front-ends**, `guiButtonToggle` carrying fill, border and text
colour together. The wheel's words are taught in help's drag tab, read from `wordOf` and
`labelOf`; a law in the shared suite holds that every wheel word appears there.

*Checked.* Verified by running: both bindings compile and link against SDL3 3.2.30 and libGL
through `nim cpp`, and their assertions run against real headers; Dear ImGui starts over a
hidden SDL3 window with a real OpenGL 3.3 core context under Xvfb and draws through both its
backends. Verified by looking: a 300-frame headless run writes a 1440×900 PNG carrying grid,
axes, the ground plane's disc, the points and the panel, so both front-ends draw the same
scene from the same core; 60 frames is not enough for the entrance animation. **Unverified**:
no human has seen this on real graphics hardware; software GL reports no multisampled
visual, so thin lines alias.

## Desktop Driven Checks

**Suites test rules and `tools/drive/` tests browser wiring; this tests desktop wiring.** The
entry point carries scripted runs — `--drive-keys`, `--drive-sky`, `--drive-undo`,
`--drive-select`, `--drive-drag`, `--drive-menu`, and `--drive-help:<tab>`, one per tab —
each pushing real events through SDL's own queue. `driven` runs all of them and reports
every failure, not the first, asking the binary which help tabs exist (`--help-tabs`) so
`help.HelpPath` stays their one home (Article I.4). `drive` chains it, here and on the
runner (repository issue 91). `driven` counts them; what they cover: a held key slides
the view and keeps its height; a drag across bare sky turns the view and builds nothing;
undo takes a construction back *and* returns the view to where it built from; the choice
menu does not swallow the drag after it; every help tab opens with rows in it; a run whose
face is missing still does its scripted work; every type role is drawn in a face of its
own; a scene filled to capacity leaves what follows its list on the window; the menu opens
offering the demo at every size `orrery` has.

**An absent face is a finding, never an abort.** Dear ImGui asserts inside
`AddFontFromFileTTF` where it cannot open a path, and an assertion is SIGABRT rather than a
report: a declared path that does not resolve aborts every scripted run. `faceAt` resolves
each face to empty where the file is not there, and says which face is missing, which
variable names it and which verb fetches it; the interface draws in what is left.
Locations come from the environment first — one `RGA_FONT…` name per face — falling
back to the faces this build ships, and that fallback is what lets the case be driven:
`driven` runs `--drive-keys` once with `RGA_FONT` naming a path no machine carries.
**This half ships the faces it draws with** (Article X.8; repository issue 93): `DIR_FACES`
is relative to the binary through `getAppDir()`, so no machine's layout is named in source.
Faces come from the Noto project's own release repository, pinned by family tag *and*
digest — `NotoSans-v2.013`, `NotoSansMath-v2.539`, `NotoSansSymbols2-v2.006` — per family,
since three families move on their own; coverage was read from each font's `cmap` against
the ranges `gui_shim.cpp` declares (math 1,773 of 1,952 wanted). Costs about 2.5 MB fetched
into `build/fonts`: uncompressed faces are what `stb_truetype` reads.

**No default favours a silent pass.** A scripted run supplies `FRAMES_DRIVEN` where the
caller gave no frame bound, since the loop ends only on one; and every scripted run ends in
its verdict, with no second flag to ask for it.

**What `driven` costs, on this container, 4 cores, software GL.** Cold, with neither
checkout present and nothing built: **1 m 27 s**. Warm: **29.3 s**, since a prefix already
reporting the pinned version is kept. On the runner the `driven` step costs about
**3 m 15 s** more with the desktop half than without (215 s → 411 s, one run against one
run), which repository issue 79 weighs against the rest of the job.

*Checked.* Verified by running: every run passes under Xvfb on software GL from a tree
carrying neither checkout and no SDL3 anywhere on the machine, and a second run kept the
prefix and rebuilt nothing. Verified by breaking on purpose: the drag verdict inverted
reports `FAIL  a drag from one object onto another opens its choice menu`, and the verb
answers `Driven runs failed; got 1 -- drive-drag`, exit 1.

## Render Paths

**The directory a module sits in is which render path may reach it.**

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

`pga` is the dependency above all three and shared. The shared core imports nothing outside
itself and `pga`; `src/desktop` and `src/browser` each import that core and never each
other, readable from import paths (`../rga_visualiser/`). Both are built by one driver:
`web` assembles the page, `desktop` compiles the binary, and neither entry point carries a
configuration file of its own. `arena` sits in `src/desktop` despite being general-purpose:
only the PNG and GIF encoders and the desktop draw loop reach it, and the JS backend cannot
carve typed slices from a byte array at all.

A shared module reaching for something only one path has is a **compile error, not a
comment**: `toCstring`, `buildChars`, `appendInt`, `appendFixed`, `saveScene`/`loadScene`
and their `std/os` and `std/syncio` imports are guarded `when not defined(js)`. Every
binding into C, SDL, Dear ImGui, zlib and JavaScript carries `sideEffect`, so a `func`
reaching one fails to compile; without it the compiler assumes an imported body pure.

*Checked.* Verified: the guard is exercised rather than trusted, because the suite runs on
both backends (see Testing); the `sideEffect` marks are what turned 51 funcs back into procs
(see Style Guide). Assumed: nothing.

## Scene Storage

`Scene` (`scene.nim`) is a fixed-capacity structure-of-arrays arena — geometries, labels,
inks, visibility, liveness, birth stamps, creation ordinals, placing stamps, anchor
overrides, radii — addressed by a handle assigned once on `addObject` and never
moved. Free handles thread onto an intrusive singly-linked free list, so add and remove are
O(1). `OBJECTS_MAX` = 5040 and `LABEL_MAX` = 40, both `{.define.}`-overridable. Not a
shift-on-delete array, whose removal renumbers every held cross-frame index: **a handle
number stays valid until its object is removed**.

**`Scene.bound` is the highest handle ever occupied**, and every per-frame walk runs to it
rather than to capacity; it only rises, so walking to it is safe. Three walks legitimately
run to capacity — the free list and the two object-pool strips, whose subject is how much
room is left — and `bound`'s own doc names them. A walk to capacity over five live objects
costs 13.3 ms a frame on the JS backend.

**`Scene.revision` counts edits, and every writer is inside `scene.nim`**; there is no
`var`-returning geometry accessor, the hole through which a caller could write with nothing
recorded. Whole-scene replacement (undo, redo, clear, every load) goes through
`restoreFrom`, which issues a revision **newer than every revision ever handed out**,
`max(live, snapshot) + 1`. Not the snapshot's own count plus one — a number a state between
the two had already worn, so a placement cache keyed on it drew six objects of the previous
demo over the new one.

**Placement is invalidated per handle.** `Scene.revisions_placing` stamps each handle at the
edit that last changed it, and `restoreFrom` stamps every live handle of the snapshot; the
browser's placement cache re-places only handles stamped after the revision it last filled
at. Re-placing the whole scene per edit costs a 42 ms frame at 5,038 objects; a restore
still re-places everything.

**Creation order is recorded explicitly** (`orders`, `count_created`, `handlesCreated`), not
inferred: handle order stops being creation order the moment anything is removed, since the
free list hands the most recently freed handle to the next arrival. Not sorting by `born`,
which fails on three counts that all occur: two objects added in one frame share a clock
reading; a replayed object's `born` is stamped into the future; a reused handle's `born` is
stale until overwritten. `handlesCreated` is a heap sort; as an insertion sort at 5,038
objects it ran 12.7 million comparisons a call. The desktop panel caches its answer against
`scene.revision`, because sorting every frame was 98% of the desktop's CPU frame at 5,038.

**`LABEL_MAX` counts bytes, so a label is cut on a character boundary and says it was cut.**
`format.appendChars` copies a UTF-8 sequence only if all of it fits; `scene.toChars` rewinds
far enough to append `…`. A 3-byte operator glyph straddling the limit leaves invalid UTF-8
otherwise, which the JS backend percent-escapes into a name (`%e2%8a`). `Object` is a
handle, not an assembled copy, and under `nim js` it holds the `Scene` by value; the
per-frame loops use the by-handle accessors instead.

*Checked.* Verified by `suites.nim`: handle stability across removal; `handlesCreated` on a
scrambled arena of hundreds; `revisionPlacingAt` stamping one handle per edit and every handle
after a restore; `restoreFrom` landing on a revision no earlier state carried; label
truncation never splitting a character at any buffer size. Verified by driven check: undo
while the frame is held redraws the current scene, not the previous one. The 13.3, 42 and
12.7-million figures were read while fixing and not re-measured since.

## Memory And Allocation

The interactive render loop allocates nothing. `format.nim` wraps C `snprintf` so per-frame
number formatting writes into stack buffers. Button-driven message building still uses
`strformat`: once per click, and the result must become a `string` for `addObject` anyway.

`arena.nim`: a plain `array[N, byte]` carved by `push[T]` and reclaimed by `reset`. Three
instances in the desktop entry point:

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
its own `renderAt`; without that, captured sub-frames stack scratch until the fifth overflows.

**The undo timeline is the largest reservation the binary makes.** A `Scene` at 5040 handles
is 1.15 MiB as a C struct (1,204,616 bytes by `sizeof` on the release compiler), a `Step`
is a `Scene` beside a five-float `Camera`, and `CAPACITY_HISTORY` = 32 of them reserve
36.8 MiB (38,549,528 bytes) against 6.2 MiB for both mesh sets. In the browser the same
timeline is roughly 105 MB of JS heap; the live page measured 85 MB at load before the
per-handle placing stamps were added and has not been re-measured since. The depth is left at
32: an edit costs nothing per step (see Undo/Redo), so what remains is a flat reservation,
and the lever is linear — about 1.15 MiB of address space and 3.3 MB of JS heap a step.
`BYTES_MEMORY_TOTAL` counts it; a figure omitting its own largest term is worse than none.

GIF's LZW dictionary is a fixed open-addressed hash table (`CAPACITY_DICT` 8192, Knuth
multiplicative hashing) rather than a third arena — random-access probing within a frame,
not bump-only append. **LZW early change**: the format widens the code size one symbol
earlier on decode than on encode; a from-scratch decoder in the suite round-trips a real
frame past the growth point.

*Checked.* Verified by `suites.nim`: the swap pair keeps last frame's bytes; the GIF
round-trip. Verified by `sizeof`: the struct and timeline sizes. Assumed: the JS heap figure
per step, extrapolated from one measurement at the earlier stamp-less layout.

## Colour Palette

Five assignable hues — `Rose, Copper, Olive, Jade, Cobalt` — plus `Backdrop`, `AxisX/Y/Z`,
`Grid`, `Guide`, `Outline` and `Invalid` in one `Ink` enum (`mesh.lut_ink_to_rgba`).

**`Invalid` is a reserved magenta**: seeing it means an object is wrong. The drag band wears
it over a pair that makes nothing (see Interaction Model); nothing else does. It is never
leaned on alone — magenta reads as *blue* under deuteranopia — and the preview fails to appear
beside it. Reserving it cost three hues: `Violet` and `Cerise` measured CVD ΔE 10.2 and 8.3
from magenta, and `Cobalt`, 88° of hue away, measured **6.6** because blue and magenta
converge under deuteranopia; `Cobalt` is derived lighter and bluer (`#5b90c7`), which
reopens the pair to 14.4.

**Do not fill the remaining arc back up to eight.** A seven-hue set put `Olive` and a new
yellow-green at CVD ΔE 0.4 and two blues at normal-vision ΔE 5.6. The axis hues flank the
reserved arc on both sides, leaving one warm arc and one cool, 162° in total; five is what
fits.

**The structural slots are not offerable as an object's colour.** `mesh` names the boundary
once — `INK_CATEGORICAL_FIRST`, `COUNT_INK_CATEGORICAL`, `inkCategorical`,
`categoricalIndex` — and both pickers and `inkCycled` derive from it. Structural slots are
declared first and the categorical run last so it is one contiguous block; a
`static: doAssert` on the count enforces that.

Derived under floors the prototype's `check_palette` measured on every run of that tree;
nothing in this repository re-measures them, so a hue moved here is a hue unchecked:

1. Every pair among the five clears normal-vision ΔE ≥ 15 and ≥ 20° of hue, so lightness can
   never stand in for a hue difference. `Jade`/`Copper` at CVD ΔE 7.6 sits inside the
   6–8 legal-with-secondary-encoding band; shape and screen position are that encoding.
   `Rose` sits at contrast 2.78 against the backdrop, under 3:1; its always-present row label
   is the relief.
2. Axis safety: each hue clears ≥ 20° and a lower ΔE floor (4.0) against `AxisX/Y/Z`, so a
   thin fixed line is never mistaken for a filled object. Loosened from the object floor on
   purpose, which is what freed most of the wheel; one floor for everything crammed every
   hue into a teal/blue/violet arc.
3. Every assignable hue clears CVD ΔE ≥ 13 from `Invalid`: worst `Cobalt` 14.4, `Rose` 15.2.
4. Furniture against `Backdrop` ≥ 8.0: the axes land at 15.7–25.3.

**The one declared exception.** `Jade` and `Cobalt` separate by only **3.7 ΔE under
tritanopia**, carried rather than repainted: the pair clears 12.7 under red-green deficiency
and 15.8 to typical vision, tritanopia affects fewer than one reader in ten thousand, and
every object carries shape, position and label. The floors were measured under **Machado,
Oliveira and Fernandes (2009) at severity 1.0**; Viénot-1999 puts Jade/Cobalt at 0.9 ΔE
where Machado puts it at 12.7, so the model is part of the standard. Red-green (the minimum
of protan and deutan) carries the floors; tritanopia is measured separately.

**Axis colours are dimmed and desaturated at compile time** through `axisTinted` from
`MUTE_AXIS_TOWARD_GREY` = 0.45 and `SCALE_AXIS_LUMINANCE` = 0.50 — the constants are the
source, not documentation of hand-applied literals. Settled by the floors, not by eye: 0.62
luminance read well and *failed*, dimming having walked the green and blue axes onto
`Rose`'s own luminance (3.5 and 3.3 ΔE under red-green against the 4.0 floor).

`Ink.Outline` is retained although nothing draws with it: removing a categorical-adjacent
entry shifts every later ordinal and corrupts the colours of a saved `.rgascene`; the debug
layer's `Ink.Algebra` *was* removed, with the file format going to version 6 to carry the
shift. **Seed hues**: `ground` keeps `INK_SEED_GROUND`'s olive and `o` keeps
`INK_SEED_ORIGIN`'s copper, the two seeds that are not arbitrary.

*Checked.* Verified then, by the prototype's `check_palette`: every floor above, and the
seven-hue and one-floor failures. Verified by rendering: the axis dimming, and that 0.55
grid alpha read as absent (see Geometry). Assumed: the prevalence figure for tritanopia,
from the literature. **Unverified here**: no tool in this repository re-measures a floor.

## Geometry And Drawing

**Plane.** A solid rim (`RingRecord`) plus a flat translucent fill (`DiscRecord`,
`ALPHA_VEIL` = 0.16); no crosshair, no grid, no normal shaft. Fixed radius `EXTENT_PLANE` =
8 world units about the plane's anchor — not camera-scaled, which visibly resizes a plane as
the camera orbits — a rendering choice in `mesh` and `picking` alone: every construction
path reads the full `Multivector`, so a meet lands correctly far outside the drawn disc.

**A meet is read back as the point it names before anything signed is asked of it.** A
meet's weight carries the orientation of the crossing and `unitize` divides by the weight's
*norm*, so that sign survives, and `depthAgainst` is linear in its point, so a meet passed as
it came reports its depth **negated** on every plane met from behind its normal: such a
plane picks at 0 of 462 sampled pixels while the ground plane hides the fault.

**Line.** Two segments meeting on the line at its support, each running out to one of the
line's two vanishing points `eye ± radius_horizon*axis`. A vanishing point is a property of
the *eye*, which forces this shape: an end anchored a fixed reach from the support stops
short of it (≈6.7° for a support 40 units out). Each segment lies in the plane through the
eye containing the line, so the pair draws over the true line's projection (1e-16 of
screen skew) while the far ends sit off the line along the view ray, so occlusion is
approximate there. `picking` tests both halves through `clipToEyeSide`, a by-hand
near-plane clip, since this reach puts an endpoint behind the eye.

**Horizon objects** are drawn as sky: a horizon point is a fixed star at
`eye + radius_horizon*heading`, a horizon line a great circle about the eye, a horizon plane
a full-sphere dome (`DomeRecord`, `ALPHA_VEIL_SKY` = 0.22), all anchored to the eye every
frame. A full sphere, not a hemisphere: an orbit view sits elevated and tilted down, so a
dome cut at the horizontal loses sky the camera sees.

**Draw-order invariant.** Translucent veils blend in scene order with depth writes off, so
both `assembleMeshes` and `bridge.nimBuildFrame` insert any visible horizon plane's dome
**first**, so an ordinary plane's fill blends over the sky whatever handles they occupy.
**Muting**: `mesh.muted()` blends toward the colour's own luminance (`MUTE_DESATURATION`
0.6) rather than replacing it with `Ink.Grid`, which made a muted object indistinguishable
from the grid; `FRACTION_DIMMED_ALPHA` 0.55. **Draw sizes** live in `mesh.nim`, not
`renderer.nim`: `DIAMETER_POINT_LEAST` 6.0, `WIDTH_LINE_OBJECT` 2.5, `WIDTH_LINE_FURNITURE`
1.5 px, in *framebuffer* pixels, with a `static: doAssert` that object lines exceed
furniture lines; `marker` derives every clearance from them.

**Every point has a radius, in world units, and is drawn in perspective.** `Scene.radii`
holds one per handle, `RADIUS_OBJECT_DEFAULT` = 0.08 — what a nine-pixel sprite spans at the
opening camera, so old scenes open looking as they did. Both editors carry a `size` field,
bounded below at `RADIUS_OBJECT_LEAST` 10⁻⁹ because the model refuses zero outright;
`RADIUS_OBJECT_MOST` 1e6 exists because ImGui's drag widget reads *no upper bound* as *no
bounds*. A point crosses the wire as one record (`Vertex`) and is drawn as an **instanced
camera-facing quad** from `mesh.pointCorners` on both front-ends: the vertex shader takes
`radius = max(own, ½·DIAMETER_POINT_LEAST·world_per_pixel)` at the point's depth, and the
fragment stage discards outside the unit circle. The rule is stated once in Nim as
`radiusDrawnAt` and `radiusPixelsAt`, the two shaders its sibling copies. So the size is
*fixed in the world* and shrinks with distance, floored at six pixels so a distant star
stays a readable dot — the one departure from pure perspective, and what keeps 4,900
catalogue stars visible. Pick, marker, cull and framing follow the drawn disc.
  **What is under the pointer is what is picked.** Where the cursor lies inside the drawn
  disc of some point, the nearest such disc to the eye wins over every point the cursor is
  not inside, however near their centres (`picking.pickWalk`'s `consider`); not distance to
  centres alone, which let a background star win through a planet's disc. A point covered
  by a nearer disc narrower than a fingertip is still a rival to the touch crowd rule, one
  covered by a fingertip-wide body is not (`coverOf`); the discs under the cursor are
  gathered in a fixed array of eight (`Hiders`) as the walk goes. Depth in the point branch
  is read off the projection's homogeneous weight (`depthAlongSight`), so the branch builds
  nothing per point: the hover pick at 5,038 went from 3.5 to 2.2 ms median.
  **Cost, under SwiftShader**: every CPU phase unchanged within noise against sprites, while
  the whole frame at the largest demo rose from 53–55 to 103–108 ms p50 with the cull off —
  per-instance overhead in the software rasteriser, by hypothesis. **Unmeasured on a
  device**; the drawer's `render` row is where it shows.

**Every point is shaded as a sphere lit from world-up.** The light is `camera.UP_WORLD`, one
direction for every point, turned into the camera's basis in the vertex shader on both front-ends
as the three axes' own z components; the fragment stage applies Lambert over an ambient floor
`FRACTION_AMBIENT_SHADE` = 0.25, a quarter, so the underside still reads as a body in its own hue
rather than a hole in the field. Nothing in the scene carries a light: shading is presentation
that gives a disc its sphere, not a property of any object. Not a point that shines on the
others, which the scene format carried from version 5 to 6 and the record kept as a *sun*: it was
one more thing the demo's astronomy had written into a visualiser of an algebra, and every point
read the same under it but the sun itself, which drew flat. Cost: three floats fewer per point
record, and no per-edit relighting pass.

**Furniture** (ground grid, world axes) reaches `extent_furniture`, `FACTOR_CLIP_FAR` orbit
distances, and is drawn as **fog about the eye**, not a halo about the origin. Not the far clip,
which also reaches the scene's farthest object: the demo reaches millions of units, and a grid sized
to that put its cell at a hundred thousand with no line under any camera inside Sol's system. Lines
and the horizon still reach the far bound. The fog holds full strength within
`FRACTION_GRID_FADE_START` = 0.06 × extent, gone by `FRACTION_GRID_FADE_END` = 0.20 × extent — 1.14
and 3.8 orbit distances; at 0.03/0.12 the ground at the pivot read as absent. A halo makes the
origin a place the reader may not leave. The fade runs in the fragment shader against the fragment's
own world position, held to `alphaGridFade` as its reference; a per-record `fog` flag says who
fades, so furniture and scene ribbons share one buffer. `addGrid` lays lines on world multiples of
the cell size inside the ground disc the fog leaves (`mesh.radiusGroundFor`), one record per lattice
line, skipping the two through the origin, which coincide with the axes.

**The cell is `SIZE_CELL_GRID` = 10.0 at every reach a reader works at.** A cell that walks
with the reach re-scales the ground under a reader as they dolly; a fixed cell is a ruler.
Ten rather than a hundred, by rendering both: at the opening reach of ≈72 units a
hundred-unit cell put at most one line in view. `CELLS_GRID_HALF_MAX` = 120 bounds the lines
laid (`LINES_GRID_MAX` = 241 per family), **spent on the cell, not on the reach**:
`sizeCellGridFor` steps the cell by **decades**, because decades nest, so a step coarsens
what is drawn without moving a line the reader was measuring against; the first step is at
1,200 units of reach. Cutting the *reach* instead leaves a camera past 1,200 units with the
ground stopping short: grid vertices at orbit distance 300 / 1,000 / 5,000 / 10⁶ are 86,142
/ 28,392 / 13,818 / 28,392 under the decade step against 86,142 / 95,088 / 0 / 0. The grid
is dimmed by `ALPHA_GRID` = 0.75 in `addGrid`; 0.55 read as absent. **The world axes are
reference**: they fade and cut off on the grid's own schedule, so all the furniture ends at
one horizon; an axis without that fade is the brightest mark in any frame, and readers took
it for a drawn line.

**The scale bar**, bottom left, is what makes the ruled ground measurable: a span of ground
drawn at its true screen length with its distance written under it. Stepped 1-2-5 by decade
(`STEPS_RULER`) to land near `PIXELS_RULER_WANTED` = 130 px, as every map scale is; a bar
tied to one cell ran 11,983 px at orbit distance 3. Both numbers come from `nimGridMetrics`,
in CSS pixels. **The drawer draws over it** (`z-index` 3 under the drawer's 4) rather than
hiding it: a bar a panel sits on can be read by closing the panel.

*Checked.* Verified by `suites.nim`: a meet far outside the drawn disc, from both sides of one
plane; both halves of a line pickable; the horizon plane's dome inserted first; the great
circle's segment count after the eye cut; the fog radii at an eye inside its own fog; a star
behind a wider disc unpicked with one rival and a moon in front of it picked with two.
Verified by driven checks: the plane pick
from either side, sweeping the canvas for a pixel picking a plane the gesture itself built;
the scale bar's length against its label at two distances a decade apart, layered under the
open drawer; forty-eight hover samples across Jupiter's disc finding nothing deeper.
Verified by rendering: the fade fractions, the cell size, the grid alpha, the axis dimming.
Verified by driven check: a wide disc's upper half brighter than its lower on the page, which
is world-up on screen from the opening camera. The far-end occlusion error is assumed to
be tolerable, not measured.

## Camera

`camera.nim` holds an orbit camera: pivot, distance, azimuth, elevation. `ELEVATION_LIMIT`
= π/2 − 0.02. The opening placement is `initCameraDefault`, read by both entry points and
by `home`.

**An orbit distance has a floor and no ceiling.** `DISTANCE_LIMIT_NEAR` = 10⁻⁹ is geometry:
at zero the eye coincides with its pivot and every direction `camera.frame` derives
collapses; `distanceHeld` is the one statement of it. Tiny rather than small, because the
demo's moons ring their planets at thousandths of a unit and are millionths wide, and a
floor of a twentieth kept the camera outside every one of them. Not a ceiling, which reads
as the camera being bounded to a region and which nothing downstream needs.

**Every record is stored about the pivot.** `mesh.clearMeshes` takes the frame's origin, both
front-ends pass the camera's pivot, and each of the five record writers subtracts it at the float32
write, so what the camera looks at is exact wherever it stands: a moon a thousandth of a unit from
its planet a million units out, where float32 about the world origin steps by a sixteenth and loses
the whole offset. The GPU's transform is `initMatrixViewProjection` about the same origin, only its
translation column moved; picking, hover and every marker keep the transform about the world.
`Matrix4` is double precision for the same reason: a float32 translation column carried tenths of a
unit that far out, into every pick. Not a moving world origin, which would rewrite every stored
multivector per frame. Float32 degrades what stands past roughly 10⁶ units from the pivot, invisible
at that reach; wheeled out to 3 × 10¹⁹ the view empties to a speck and `home` returns.

**Clip planes follow orbit distance, and nothing clips at the far bound** — `FACTOR_CLIP_NEAR` 1/400
of the orbit distance and `FACTOR_CLIP_FAR` 20 times it, or the eye's distance to the origin plus
the scene's reach (`Camera.reach_scene`, times `MARGIN_REACH_FAR` 1.05) where that is farther —
derived, never stored. The projection has no far plane: its depth climbs toward 1 − `SLACK_CLIP_FAR`
(1/1024) and never reaches it. Not `(f + n)/(f − n)` with the far plane at the star field's reach:
the farthest stars and the dome at 0.9 of it then sat within two float32 ulps of the far plane, and
an Android GPU's rounding clipped them, points flickering as the camera moved and the dome drawn in
patches along its cells. Not twenty orbit distances alone: with the starfield 3,000 units across,
six notches in at the demo's centre leave 49 of 4,938 points drawn that way, and 367 with the reach.
The reach (`framing.reachOf`) is stamped onto the camera at every derivation point rather than kept
in it, because `home` and every path that replaces the camera value would drop a stored one.

**Depth is logarithmic, written per fragment.** Every fragment shader on both front-ends writes
`camera.depthOf` of its own view depth, `log2(D / near) / log2(far / near)` scaled to clip depth,
through `EXT_frag_depth` or GL 3.3's `gl_FragDepth`, so resolution is a fixed fraction of distance
at every distance. Not linear depth with the near plane raised to hold the ratio at 100,000: that
spent nearly every step inside the first orbit distances, and an Android GPU dropped the whole star
field from beside a far star. Never in the clip position: the clipper interpolates clip coordinates
linearly and cut a corner behind the eye beside its front corner, the disc ending at a hard chord.

**The wheel zooms toward what the pointer is over** — the map reading of a zoom.
`picking.anchorZoomAt` solves the anchor in three answers, in order: the finite object under
the pointer, else the ground at `z = 0`, else the horizontal plane through the pivot; where
none answers the wheel falls back to a centred dolly. **The object or ground is taken only
where its depth is within `FACTOR_ANCHOR_DEPTH` = 2 of the orbit distance, either way**;
otherwise the level through the pivot answers: anchoring on a star a thousand units off
slides the eye 38% of the way toward it per notch, and six off-centre notches carried the
pivot 1,737 units against 5 with the window. A cursor toward the horizon finds ground
beyond the window and takes the level, which is what stops a zoom near the horizon flying
off across the ground. The object comes first because pointing at something means *that
thing, at the depth it stands at*; horizon objects are refused, being at no place. The
price is the jump: two notches taken either side of an object's edge converge on different
depths. `camera.dollyToward` moves the eye along its own line to the anchor and scales the
pivot toward the anchor by the same factor, so the orbit centre settles onto what is being
zoomed into; the scale applied is read back from `distanceHeld`, so a zoom stopped by the
floor moves the eye by exactly what it was allowed. **A pinch stays centred**: the
two-finger gesture already pans by its midpoint's travel.

**A drag pan grabs the level under the pointer and carries it.** `interaction.panAcross`
meets both ends of the pointer's step with the horizontal plane through the pivot and
translates by the difference. Not a rate per pixel (`FRACTION_PAN_PIXEL` = 0.0016 of the
distance), which slid within the plane *facing the eye* and took the pivot from z 1.00 to
6.40, so every later orbit swung about a point in mid-air; the rate survives only where a
ray misses the level. **The hold point is bounded at `FACTOR_PAN_REACH_MAX` = 4 orbit
distances**, since a level meets a ray aimed near the horizon a very long way off; the
*point* is clamped rather than the movement, so the rule stays continuous, and each hold
point is taken to its foot on the level so the clamp's tilt cannot leak into the step. Four
rather than two: at the opening placement a ray a fifth of the way down the window already
reaches 2.7 distances.

**Keys move by shared rates per second** — `TURN_SECOND` 1.4, `RISE_SECOND` 1.1,
`SLIDE_SECOND` 1.2, `FACTOR_DOLLY_SECOND` 4.0, `FACTOR_HASTE` 4.0 under shift — applied
each frame scaled by elapsed time, so a hold covers the same ground at 60 Hz and 144 Hz; the
dolly compounds as `pow(factor, seconds)`. Drag rates differ per front-end for a real
reason: the desktop's `SPEED_ORBIT` (0.008) is radians per pixel and the browser scripts
work in fractions of canvas width.

*Checked.* Verified by `suites.nim`: the logarithmic depth maps near to −1 and far to +1, is
monotone across every decade the demo spans, and keeps Io before Jupiter and a star before the dome
by more than a 16-bit step; the flattened float32 matrix keeps the farthest star and the dome half
the slack inside the far plane at four orbit distances. Verified by driven checks: the sky is drawn
behind a far star, and the ecliptic's disc reaches under a camera 1.5 units off Sol, 0.3 and 0.0003
rad up. Verified by driven wheel events: an object under the pointer drifts 0.000 px across a 3.2×
zoom against 1.957 px with the pivot-level anchor, and wheeling back out returns to distance 19.000
and pivot (0, 0, 1). Verified by driven drags: 1.000 to 1.000 of height, mouse and two-finger alike.
Verified by `suites.nim`: `norm(eye − pivot)` equals the held distance after a floored dolly; the
pan's height invariance; the clamp's continuity; the reach stamped at every derivation point, which
the undo-while-held check caught missing. Verified by driven keys: 500 ms of `w` moved the pivot
12.8 units with z unchanged to four decimals, shift 49.3. Assumed: that no ceiling is wanted by any
reader.

## Records And Shaders

**Every line is a quad, never `GL_LINES`.** A line width is a hint most WebGL targets clamp
to one pixel. Each end is offset half a width along `directionAcross` — the normal of the
plane joining the segment with the eye — scaled by `worldPerPixelAt` at *that end's own
depth*, which keeps the on-screen width constant along a receding line. **The near plane is
clipped against first**: a depth clamped at the near plane breaks the proportionality and
draws a world axis twenty pixels wide near the origin.

**The widening runs in the vertex shader on both front-ends.** One fifteen-float
`RibbonRecord` per segment (sixteen with the `fog` flag) crosses the wire against the
forty-two floats six CPU vertices cost, expanded by an instanced draw — GL 3.3 core on the
desktop, `ANGLE_instanced_arrays` on WebGL1 — the across derived per vertex as
`cross(head − tail, eye − tail)`. **Chain of custody**: the GLSL ships, `mesh.expandRibbon`
is its reference in Nim (sibling-marked with both shader sources), and the suite holds the
reference to the algebra — the near clip equal to `clipToEyeSide`, the across equal to the
join `directionNormal(tail ∧ head ∧ eye)`, sign included.

**A plane's fill, its rim and the sky are one record each.** A 13-float `DiscRecord` is spanned over
the view box of its bounding sphere, `viewBoxOfDisc`, on the static unit-circle corner buffer, and
every fragment casts its own ray at the plane, `hitDiscAlong`, so the disc is exact at any grazing
angle and agrees with `picking.rayPlaneHit`. Not a fan of corners on the plane: a corner behind the
eye left the clipper a sliver that rasterised to nothing under a camera within 0.06° of the plane,
and the disc ended at a hard chord. An 8-float `DomeRecord` widens over a static unit sphere, which
has no orientation; a 14-float `RingRecord` is a disc's thirteen plus a width, one instance drawing
the whole circle. The static corner tables come from one generator each in `mesh`, read by the
desktop directly and by the browser through `nim*Corners`, so neither front-end holds a table that
could drift from the references, which the suite pins to the multivector sums they replaced.
`ribbonOfRing` derives the very `RibbonRecord` a rim segment would have been, so a rim is widened by
the one rule every line is. The rim steps off `UNIT_CIRCLE_RIM`, resolved at start-up with the
runtime's own `cos`/`sin`, not at compile time, whose evaluator need not agree with each backend's
libm in the last bit. The rim as one record is what the demo frame turns on: 96 ribbon records per
plane were 99.2% of ribbon traffic on 132 planes, and the demo's median frame went 239 → 84 ms under
SwiftShader.

**Every record's position is stored about the frame's origin**, the camera's pivot (see
Camera); the suite pins the five writers against an origin a million units off.

**Veil order is kept, not assumed away**: two translucent veils still blend in scene
order, so every append extends or opens a `VeilRun` and both render paths walk the runs in
sequence. `markOverlay` seals the current run. `RingMesh` carries its own `index_overlay`,
or a selected plane's second rim would draw depth-tested behind the fill it highlights.

**Capacities** are asserted in `scene.nim`, the one module that can see both sides, so
raising `OBJECTS_MAX` fails to *compile* rather than `doAssert` at draw time (a dead page):

| Cap | Value | Binding case |
|---|---|---|
| `VERTICES_MAX` | 10080 = 2 × `OBJECTS_MAX` | every handle a point, every one selected |
| `DISCS_MAX`, `DOMES_MAX`, `RINGS_MAX` | 10081 = 2 × `OBJECTS_MAX` + 1 | every handle a plane, |
|  |  | every one selected, plus a preview |
| `RIBBONS_MAX` | 20161 = 4 × `OBJECTS_MAX` + 1 | every handle a line, two segments, drawn twice |

The desktop asks for a `SAMPLES_MULTISAMPLE` = 4 framebuffer and **falls back to none if no
visual offers it**: `llvmpipe` under `xvfb` refuses the window outright rather than
downgrading, and a visualiser that will not start is worse than one whose thinnest lines
alias. The browser context asks for `antialias: true`.

**The flat buffers are the page's own typed arrays, filled in place.** A `seq[float32]` on
the JS backend is an `Array` of boxed doubles converted element by element into a staging
`Float32Array`, a fourth pass over bytes nothing else read. `FlatBuffer` is a `Float32Array`
behind three `importjs` lines, allocated once at its mesh's cap and never grown; each frame
hands back a `subarray` view, no copy. Measured at 0.1 ms a frame. Draw order in the
browser scripts mirrors `renderer.nim` and is kept in step by hand.

*Checked.* Verified by `suites.nim`: the widening reference against the algebra; every stepped dome
and ring corner against the sum it replaced; the disc's box against its rim's projection, its ray
landing inside the rim and missing outside it, and a hit under a grazing eye nearer than the near
plane; all ninety-six rim segments on the plane at its radius; the capacity assertions, by building
the binding scenes. Verified by desktop
A/B under Xvfb: 0 of 1,296,000 pixels for the ribbon move, at most 38 per storyboard frame
(channel delta ≤ 12) for the disc and dome move, where the record narrows its arms to
float32. Verified by driven check: the demo's ribbon records under 64 against a ring count
over 120. Assumed: that the 0.1 ms flat-buffer figure holds at the current caps; it was
measured at 1,024 objects.

## Algebra Boundary

The **algebra owns geometry** — what a thing is and where it stands: construction,
incidence, meets, joins, projections, nearest points, side tests; the world-space camera;
rays cast from the screen; the lattice lines and axes, which are lines; everything at the
horizon. The **picture owns representation** — how geometry becomes GPU primitives: a
plane's disc and rim, a ribbon's across-vector — built with whatever arithmetic is quickest.

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

**There is no debug layer, and it is not to be reintroduced without being asked.** A
switch drawing every multivector a frame computed as what it is never helped resolve
anything and is gone with its two modules, its palette slot, its `nimBuildFrame` flag, its
diagnostics row and its four driven checks. `addGridFamily` and `radiusOnPlaneFor` still
lay a lattice on any plane, since the ground is that case.

*Checked.* Verified by `suites.nim`: every moved form pinned to its algebraic reference. Assumed:
the µs per op figure, from one profile at 1,024 objects.

## Selection And Markers

`selection.nim`, shared: an ordered fixed-capacity list of handles, a plain value type.
**Order is the whole point** — an operation reads its operands positionally, so the first
handle picked is `𝐦` and the second `𝐧`. `Selection.revision` counts real changes, so the
frame record and the desktop panel compare one integer instead of a 5,040-handle array
every frame. Selection is **not** part of `Scene`: never saved, never on the timeline,
cleared outright by a successful undo or redo, and `pruneDead` runs after a removal because
a freed handle goes straight back to the next add.

**A selected object is drawn over every other object.** One watermark per mesh
(`index_overlay`, an `Option[int]`, since an index of zero means "all of it"), then a second
pass over **every** primitive kind against a depth buffer cleared first — cleared rather
than the depth test turned off, so selected objects still reject one another by depth; with
the test off, a planet selected after its moon buried the moon in front of it. Not a tail on
each kind, which left a selected line tinted by a later veil; not a third `MeshSet`, which
reserves every cap for a run that is usually one object. On the desktop marks draw on Dear
ImGui's **background** list, beneath the panels; the drag menu alone stays foreground.

"Just built" and "currently selected" are one mechanism: one marker per selected handle,
plain white, and every construction path replaces the selection with the handle it created.
Hover draws the identical marker at `ALPHA_MARKER_HOVER` 0.6 against `ALPHA_MARKER_SELECTED`
0.9; keyboard focus wears it too. Only a caller passing a time gets a pulse, so motion means
selected. `marker.nim` shapes the outline to what it marks:

| Kind | Marker | How it fills |
|-------|--------|--------------|
| Point | Circle in screen space about the drawn point. | Sweeps clockwise from twelve. |
| Line | Two rails flanking its projection, one each side. | Runs out from its support. |
| Plane | A circle lying *on the plane*, outside its rim. | Opens from the disc's centre. |
| Horizon line | Two bands on the sky it circles. | Closes in from a quarter turn. |
| Horizon plane | The viewport's edge, inset by the gap. | Expands as a circle from the middle. |
| Horizon point | Circle about the fixed star it draws as. | Sweeps. |

All keep `GAP_MARKER` = 6.0 px between the object's drawn edge and the marker, measured out
from the drawn size, so a point's ring hugs a wide disc and a dot alike; `OFFSET_MARKER_RAIL` =
`WIDTH_LINE_OBJECT`/2 + gap = 7.25 px; `WIDTH_MARKER` 1.5 px, asserted thinner than the line
it marks. Markers are stroked by each render path's foreground layer, never as scene
geometry: a loop on a plane would z-fight its fill, and a marker the object can occlude is
not a marker. Not a 3D-modelling-style outline; do not reintroduce it without being asked.

**A selected object wears its name above its marker**, filled in the object's own ink and
outlined in the marker's stroke; hover and focus wear none. Where it sits is `marker.nim`'s
decision: centred `GAP_MARKER` plus half `HEIGHT_MARKER_LABEL` (16 px) above the outline's
top; each front-end centres its own text.
  **A line's label keeps to the line's own left, beside its support clamped into view.**
  "Above the line" cannot be continuous, since which side is up flips as the line passes
  vertical; the side of the line's *own* direction is. So `marker.placeLabelBesideLine`
  pushes the label to that left, and each front-end, which alone measures its text, sets
  the clearance along the push. The anchor is the support's projection while in view, held
  `MARGIN_LABEL_VIEW` = 40 px inside the edge; past that it slides along the visible stretch.
  Not the upward side, which hopped five times on a 24 s camera path where this hopped none.
  **The horizon line's label stands above the leftmost point of either band**, its left-edge
  crossing, pushed `MARGIN_LABEL_HORIZON` = 12 px in from the edge and off the band by the rule a
  line's label is pushed off its rail; not the highest point, which on a level horizon hopped
  between the two side crossings, within a pixel in height: 46 swaps of 1,070 px in 97 frames at
  elevation 0.2; not flush against the edge, where the name read as cut off. **The sky's frame's
  label stands inside the bottom-left corner**, `MARGIN_LABEL_HORIZON` in from the frame's left edge
  and `MARGIN_LABEL_FOOT` = 40 px and that margin up, clear of the page's scale bar (top 33 px up),
  pushed rightward the same way; not centred inside the top edge, under the chip row, nor in the
  corner itself. **Every label is then held wholly inside the view**: `labelInView` clamps the
  measured box `MARGIN_LABEL_EDGE` = 4 px in from each edge on both front-ends.
  **A plane's label stands on the disc's column at the height of its circle's true top.**
  `marker.topmostOnCircle` solves the top of the projected circle in closed form (screen y
  is stationary where `(b·d − a·e) + (c·d − a·f)·sin + (b·f − c·e)·cos = 0`) rather than
  taking the highest of 64 projected vertices, which hops a segment at a time. Its
  **height** alone is used and the label's x is the disc centre's column, which is what
  makes the flip invisible: at the edge-on moment the far and near rims' tops part in x
  while both go to the plane's horizon in y. Not the top's own x, which pops at the flip.
  **The halo is the backdrop's colour, not the marker's white**, since a halo blends with
  the background to knock the surroundings out of the letters while a contrasting halo
  dominates them (Peterson, *Cartographer's Toolkit*; Dawson, *About label halos*):
  `WIDTH_MARKER_LABEL_HALO` = 2 px of `Ink.Backdrop` at `ALPHA_MARKER_LABEL_HALO` = 0.85, a
  16 px face at weight 600. The desktop sets the label in `PATH_FONT_LABEL` with the math
  and symbol faces merged in, so `G = L ∧ c` keeps its wedge, and draws it at eight
  one-pixel offsets in the halo colour, having no stroked text; the browser stages one SVG
  `<text>` per selected handle with `paint-order: stroke`.

**A plane's loop lies on the plane**, traced from the plane's frame about the same anchor
`addPlane` centres its disc on; its clearance is a world distance sized through
`worldPerPixelAt` at the disc's own depth, so the gap reads as 6 px where a reader judges it
and foreshortens with the disc elsewhere.

**A line's rails are two straight world-parallel lines, sized by the widest gap they will
show.** Along the half whose far point lies behind the eye, `clipToEyeSide` cuts it back to
the near plane where depth *falls*, so a world offset flares — 45.6 px at one camera against
14.5 at the support. So `OFFSET_MARKER_RAIL` means **the widest the pair may read anywhere**:
`markerRails` measures one rail against the other at every drawn end (`apartWidest`) and
narrows the world offset until the widest reading meets the ceiling. Three live traps:
**settle, do not solve** (`PASSES_MARKER_RAIL` = 4, since narrowing moves where each rail
leaves the viewport); **settle against the finished rail, then draw at the progress asked
for**, or the gap widens as a touch hold fills; **measure one rail against the other, not
either against the line between them**. A marker's worst case lies along orientation, so
sweeping camera *distance* is not sweeping. **A rail's growth is measured against the edge
of the view** (`fractionLeavingView`), not its own length, since the two vanishing points
sit at screen distances in a ratio of 314; rails are shortened **after projecting**.

**The horizon plane's frame is an expanding circle that becomes the screen edge**: at each
angle the radius is `progress × half-diagonal` or the distance to the inset edge, whichever
is smaller, over `SEGMENTS_MARKER_FRAME` = 64 even steps plus `CORNERS_MARKER_FRAME` = 4
corner directions merged in by angle, since a corner missed by a fraction of a step is a
corner cut off. **A horizon line's bands are cut to the viewport, not just to the eye**:
uncut, a ring laps 396,102 px against the 1,490 on screen. `markerBands` keeps the longest
stretch inside the window.

**On touch every marker swells clear of the finger** (`CLEARANCE_MARKER_TOUCH` = 54.5 px,
added not multiplied, about twice a thumb's contact patch; zero for a mouse), on its own
clock in four phases (`interaction.swellHold`): grows over `SECONDS_SWELL_GROW` 0.12 s, sits
at full through the fill and while the finger is down past maturity, and settles over
`SECONDS_SWELL_SHRINK` 0.15 s once it lifts. `isHoldSpent` is stated against `swellHold`
rather than the duration a second time, since subtracting two large timestamps measured
0.14999999999997 against 0.15.

**Orientation is a pulse travelling round the selection marker**; there is no normal shaft,
which marked every plane permanently to answer a question a reader asks about one object.
`markerFor` runs a lit run of `SEGMENTS_MARKER_PULSE` = 16 points spanning
`LENGTH_MARKER_COMET` = 64 px of the outline, tapering from `WIDTH_MARKER_COMET` 3.5 px down
`FALLOFF_MARKER_COMET` 1.2 to `WIDTH_MARKER`. Fixed pixels, not a share of the outline, since
a fraction measured 96 px along a rail against 334 px round a circle. **Which way it travels
is the orientation**: nothing computes the sense; the projection decides a loop's order, a
rail is walked from far horizon through the support to near, a band takes the great
circle's normal. A point and a horizon plane get none.

**The travel is a distance in pixels from a view-independent anchor.** `PulseClock.travels`
advances by `SPEED_MARKER_PULSE` = 60 px/s × seconds with no camera quantity in the advance,
reduced into the current lap every frame, since `travelled mod lap` amplifies a one-percent
lap change by the laps accumulated. `PulseTrack` names the anchor — a line's support, a
ring's angle zero — and `originAfterCut` walks angle zero through an eye cut. A speed
rather than a lap time, which ran 156 px/s along a rail against 348 round a circle. A gap
longer than `SECONDS_STEP_PULSE_MAX` = 0.1 s is an absence, not a frame. The desktop fill
needs a **fixed winding** (`gui_shim.guiOverlayRibbon` imposes it). **A drag band swells
into its head** (`marker.cometFor`), because `a ∨ b` and `b ∨ a` are different operations.

*Checked.* Verified by `suites.nim`: the loop's points on the plane (1.1e-15 on the antiscalar); the
rails' straightness and widest reading over an orientation sweep; the frame's 68 points at 296.8 px
flat at half progress; the head sitting its carried travel at 45 placements; a matured hold taken
once; a full orbit at two elevations in 0.002 rad steps with no isolated label step, two more with
the horizon line's label on the leftmost band point in the left half, the frame's label on its left
edge at its foot, and a plane's label a milliradian either side of the flip standing under a pixel
apart. Verified by driven check: 402 frames with 0 label hops, 48 at phone width with 0 side swaps
and none on the right, the frame's label box in its corner above the scale bar; a 720-step orbit
with the rail gap changing at most 0.103 px between frames; two crossing planes selected changing
15,668 canvas pixels against a 0-pixel noise floor. Verified on the shipped browser: the comet's
advance at 62.4 to 63.3 px/s across four orbit rates — the residual at faster rates, a tenth of
frames stepping 236–388 px/s at laps and clip transitions, is **not explained** to the standard the
medians are. Verified on the desktop: the selected line's pure-ink pixels 2,626 with the second pass
against 1,106 with the tail.

## Picking

`picking.pickNearest`, shared: **point beats line beats plane, strictly**, regardless of
pixel distance once a shape's own radius is met; that priority is what makes generous radii
safe. `RADIUS_PICK_POINT` = 34, `RADIUS_PICK_LINE` = 24 CSS px, sized against a fingertip at
phone density; a plane's test is area-based. **Everything drawn is pickable, horizon
included**, ranked point, finite line, horizon line (tested against the great circle it
draws as), finite plane, horizon plane (matches every ray, so last). The extent goes through
`algebraFilled`, the one derivation point; built fieldwise, a horizon point was silently
unpickable with its multivector twins zero.

**The sky is a click and hold target, never a drag handle, and so is a plane that fills the
view.** With a horizon plane visible the cursor is over *something* almost everywhere, and a
press on empty space becomes an orbit precisely because nothing was hovered; a finite plane
whose disc spans the frame's longer side (`picking.coversView`) leaves no empty glass at all.
`isBackdropUnder` folds both cases into one answer, which `beginDrag`, `destinationOf` and
`interaction.is_hover_backdrop` read. Clicking empty space selects the sky rather than
clearing; a tap still treats it as empty space, since tapping empty space is a finger's only
way to dismiss a selection, and touch reaches the sky by long-press.

**The pick runs once per frame, not per input event.** A pick walks every live handle,
linear in the scene. Pointer motion marks hover stale and the frame loop picks once after
`nimDriveHeld`; the wheel sums its notches and the loop applies one dolly, the same zoom
since `exp(k·Σdelta)` is the product of the notches (six notches a frame cost 83.8 ms of
picking). Three paths pick inside their handler because they must answer before it returns:
`pointerdown`, a touch-down and `handleTap`.

**The pick ranks what was drawn.** It takes the frame's placements and dispatches on
`Placement.kind` rather than asking `position`, `direction`, `frame` and `spanPerpendicular`
again per handle; empty means derive per handle, the desktop path and every suite case.
**The pick rejects a plane before meeting it**: `isBeyondDisc` bounds the disc's screen
extent by the silhouette of the sphere containing it, conservative in the depth and
off-axis terms — 20,000 random configurations with 300 surface samples each found no
silhouette point outside the bound. `geometryOf` hands back a `lent` view, and
`projectToScreen` is three dot products in local floats: the 4×4 multiply with two typed
arrays allocated per call was 43% of a 15.4 ms pick over 10,000 handles.

**Handle-liveness guards.** Hovered, dragged, focused and selected handles are plain values
carried across frames, so any can name a removed object the frame after a delete:
`nimAnchorScreen` reports nothing for a dead handle; `endDrag` on both paths checks
`isAlive` on source and destination; removing an object clears the highlight on both paths.

*Checked.* Verified by `suites.nim`: both boundaries of each radius and all three priority pairings;
a horizon point picked; the disc bound sampled from inside the view; the ground hovered from
half a unit (backdrop, drag refused) and from forty (drag starts). Verified by
handle-for-handle map: 4,914 cursor positions across three cameras over the 1,024-object
demo answered identically before and after the placement and copy changes. Verified by
driven checks on both builds: dragging bare sky turns the view and builds nothing, clicking
it selects it; the camera dropped onto the ground plane and a left-drag orbiting without
building. Measured then, not since: one pick 11.4 → 3.9 ms p50 at 1,024; 15.4 → 4.7 ms at
10,000; a hover pick 0.7 / 1.6 / 3.5 ms at 60 / 360 / 5038.

## Interaction Model

**Which button does what, stated once.** `interaction.revealsMenuOn` says whether a click
brings the floating selection menu (right yes, left and middle no); `armingOf` says whether
a drag opens the choice wheel. Both render paths and `help.nim` read them.

| Gesture | Does |
|---|---|
| left click | select just that one, dropping the rest |
| right click | the same, and open the menu |
| shift with either | add it, or drop it again if already picked |
| right click, selection standing, menu down | reveal the menu, selection untouched |

**The selection menu opens on the click, beside the pointer**, `INSET_MENU_POINTER` = 8 px
from it, and then remembers its offset from the object's anchor so orbiting carries it with
the object. Not held back until the ease settles: a menu a third of a second after the
click reads as a missed click. A menu opened with no pointer sits above the anchor.

**A click has no time limit**: `isClick` is distance alone, `PIXELS_CLICK_SLOP` = 6 px (not
`PIXELS_TAP_SLOP`'s 12 — a mouse does not roll, and a finger's allowance would swallow the
short deliberate drags between two overlapping objects). A 0.35 s deadline lost every click
held 600 ms. A right press that never moved is a click too.

**The press target chooses the scheme; the button chooses whether you are asked.** Press an
object and you are constructing; press empty space and you are moving the camera (left
orbits, right pans, wheel zooms). Left takes the algebra's own answer on release; right opens
the four-way wheel. **A mouse never waits**: `MenuArming` is `Never` (left), `Always`
(right), `OnDwell` (no button — touch, which has no second button and would otherwise lose
`meet`, `project` and `more…`). `SECONDS_DWELL_MENU` = 0.75 sits above `SECONDS_LONG_PRESS`
= 0.50, so the two thresholds a stationary finger races are in the right order; the dwell
measures stillness, restarting whenever the cursor moves further than `PIXELS_TAP_SLOP`,
since measuring presence opened the menu under a finger moving continuously. **Middle is
unbound**. **A press that can construct never moves the camera, not even before its slop is
crossed**: the browser decides at the press, in `is_touch_press_constructing`, the same
question `beginDrag` answers when the slop is crossed.

**A finger over a crowd moves the view; it never builds.** In the demo the pick's 34 px
reach lands on some star almost anywhere, so a one-finger orbit kept becoming a construction
drag. `picking.pickAt` reports how many objects of the winner's rank *or better* stood within
`RADIUS_CROWD_TOUCH` = 72 px — wider than the pick reach, since the question is whether the
finger could have meant something else — and `interaction.canConstructByTouch` is true only
with no rival, asked at the press through `nimCanTouchConstruct`. Where a gesture is
ambiguous, movement wins, because the reader can zoom in until it is not, whereas an
unwanted object has to be undone. Same-rank only, or every point on the ground would be a
crowd.

**The turntable's pivot follows what the zoom lands on.** Every rate but orbit is scaled by
the orbit distance on purpose, so a drag or a key hold moves the view by the same fraction
of what is seen at any zoom; a pinch that zooms straight in with the pivot left on Sol
leaves the turntable revolving about a point far behind the planet arrived at. So
`picking.anchorZoomAt` says whether its anchor is where a point or line *stands* or a
crossing (`AnchorZoom.is_standing`); `interaction.dollyAt` re-pivots along the sight line to
a standing anchor's depth after the zoom (`camera.repivotToDepth`, which leaves the picture
unchanged), and the pinch goes through the same rule aimed at the middle of the frame.
Crossings are followed by the map rule alone: not the ground crossing too, which moves the
pivot off its level with every notch and fells five driven pins at once; not a plane, whose
depth under the pointer is not its depth at the middle of the frame. Measured on the demo:
eight wheel notches over Jupiter from 30 units hold its pixel exactly and bring the pivot
from Sol to 0.09 units off Jupiter's plane.

**Two fingers are read once per frame, and zoom only past the tap slop.** Each finger's move
arrives as its own `pointermove`, so read there every step of a pan carried together is a
zoom in by one finger's step and out again by the other's — harmless while a dolly was a
pure scale, a pivot-moving re-pivot on every one once it was not. `glue.settleTwoFingers`
reads both fingers once per frame from the frame loop. Two fingers carried together never
hold their separation to the pixel, so a pinch zooms only once the separation has changed by
more than `PIXELS_TAP_SLOP`, from the separation where the slop was crossed, without a jump.

**The edit preview is drawn at the session's own radius**, or editing a moon of 0.03 draws a
grey disc nearly three times its size over it. **Edit from the selection menu scrolls to its
row's offset and renders the window there**, in one call: the offset is the sum of the
heights above it, an estimate where a row has never stood, so the row lands inside the
window and one reading of where it actually stands corrects the rest. It lands under the
pinned heading rather than at the scroller's own edge, which the heading covers. **The
gesture clock is seconds**, on whichever monotonic clock the caller owns; a dwell named in
milliseconds once needed 450 *seconds*.

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
rather than inventing; the table is asymmetric, so drag direction carries meaning.
`GENERAL_FIRST`/`GENERAL_SECOND` are separate from the random operand sets because a point
lying *on* its paired line reads zeros from the fixture.

**The drag shows its answer before committing it**: `Interaction.preview` holds what a
release right now would build, drawn in `INK_PREVIEW` through the same `addObject` an edit
session's preview uses, at the same anchor the commit makes. `choosing()` is the one
statement of which wedge the cursor is in. **Three things a release can do, so three tints**
(`ReleaseEffect`: `Nothing`, `Refused`, `Builds`) — neutral `Ink.Guide`, `Ink.Invalid`
magenta, the scene's next hue. **Every released construction steps the ink cycle**, built or
not, so a colour the reader watched for a whole drag is not offered again; a click does not
step it, undo restores it. Where a session and a preview both stand, **the session wins**;
the preview is **framed together with the operands it names** (`Preview.operands`).

**The choice wheel.** Four wedges at fixed compass points — join north, meet east, project
south, `more…` west — unoffered ones greyed (`ALPHA_MENU_UNOFFERED` 0.45) rather than packed
out, because a menu whose objects move is one nobody learns. A wedge is the selection menu's
own button, moved. **A wedge says what the picker says**: `labelOf` returns
`notationSymbolic` (`𝐦 ∧ 𝐧`, `𝐦 ∨ 𝐧`, `𝐧 ∨ (𝐦 ∧ 𝐧☆)`) and `More` a bare `…`. A release
commits whatever is under the cursor, resolved by `endDrag` through `choiceAt` so the two
paths cannot disagree; the centre (`PIXELS_MENU_DEADZONE` 26 px) commits nothing, which is
why an unasked dwell wheel is safe to open. The wheel **latches its destination** when it
opens, and **lets go when the cursor leaves it** past `PIXELS_MENU_DISENGAGE` = 150 px,
sited off `PIXELS_MENU_CORNER_FURTHEST` = 103.9 px; travelling on to another object
re-aims, never chains. **A wheel the reader summoned may veto the release; one that invited
itself may not**: pausing before lifting is the common touch release, so an *unentered*
dwell wheel's centre release falls through to `proposalFor`. `more…` builds nothing and
opens **the selection menu's own apply picker** over both operands in drag order; not the
drawer's apply section, which buried the two objects just named. A degenerate construction
is **refused**, the message naming what was degenerate, as is one on a full scene.

**Touch.** A finger that presses an object constructs; one that presses empty space moves
the camera. Two fingers pinch and pan and cancel any construction. A long press selects; once
a selection exists a tap (`TAP_MAX_MS` 350) toggles another in or out; a tap on empty space
clears. `nimClearHover` runs once the last finger lifts, or the last reading sits stale
forever. `SELECTION` (Nim) is the sole source of truth; the browser keeps a render snapshot.

**Selection menu** (both builds, one row, following its anchor every frame): `apply`
leftmost and never moving, opening a picker to its right via a `max-width` transition
(`width: auto` cannot animate); `edit` shown for exactly one selected; `hide`, `delete` on
every selected handle; `✕` clears; `apply` hidden for 3+ selected. **Shown by the gestures
that pick and hidden by the ones that build**, since every construction leaves its result
selected and a menu over each new object would sit in the way of the next drag. Placement
`OFFSET_MENU_SELECTION` = 46 px **above** its object: a Dear ImGui window makes
`wantsMouse()` true wherever it sits, so a menu straddling its object would swallow the next
drag off it. The tap-outside listener excludes the canvas, the drawer and the chip row.

*Checked.* Verified by `suites.nim`: every cell of the drag table and the at-most-one property,
exhaustively; the click rule; the dwell restarting on movement; the preview's anchor equal
to the created object's; the ink cycle stepping on release and not on click; the crowd
count and the refusal; the re-pivot rules under wheel, pinch and sky. Verified by driven
checks: the tint table at each wedge stop; shift-clicks held 600 ms selecting; the sub-slop
touch drag hovering with the azimuth unmoved; a finger dragged from a point with a twin 0.05
units away orbiting and building nothing; `more…` landing on `𝐦 ∧ 𝐧` on both builds; the
full-scene refusal; a right-click 6 px off an anchor having the menu up two frames in and a
pan moving menu and anchor by one delta; the two-finger pan moving the pivot across its
level with distance and height unchanged; an emptied list, a deep handle edited, and its
form in view. Assumed: that 0.75 s is the right dwell for any hand.

## Undo/Redo

`history.nim`, shared. Scoped to scene-content edits: add, apply, remove, visibility, ink,
and an edit session's `save`, which is the "edit committed" moment the continuous widgets
lack. One fixed array plus one cursor, not two stacks: an entry is a `Step {scene, camera}`,
both plain value types, so recording is a copy and `entries[cursor].scene` is exactly the
live scene. `CAPACITY_HISTORY` = 32.

**The array is a ring.** `first` names the handle holding the oldest step, `handleOf` is the
one place a timeline position becomes an index, and retiring the oldest entry moves one
integer; shifting every later entry down is 31 whole scene copies per edit past the
thirty-second — 153.5 ms to toggle one object's visibility on the JS backend, against
11.3 ms as a ring. What remains per edit is the one `Scene` copy into the timeline, 1.15 MiB
through `nimCopy`; not per frame. `initHistory` fills a timeline the caller owns: returned
by value it compiles to a `nimCopy` of thirty-two whole scenes, 65% of the largest demo's
load. `record` writes a `Step`'s fields rather than assigning a literal, for the same reason.

**The camera rides along; an orbit is never a step of its own.** Each step records where the
view stood when *that step's* edit was made; undo reads it off the entry stepped away from,
redo off the entry arrived at — restoring the camera of the state arrived at hands back the
view the *previous* edit was made from, so undoing the first construction of a session
teleports to the startup view. Not recording an orbit is the accepted cost of not needing a
gesture-settle rule, and **an accidental orbit is still not undoable on its own**. Both
front-ends abandon their camera tween on a successful step. Seeded wherever the scene is
(re)initialised; a successful step clears the selection and any preview. Bound to Ctrl/Cmd+Z,
Ctrl/Cmd+Shift+Z and Ctrl+Y on both builds, through one function per build rather than the
button, whose `disabled` attribute is refreshed on the low-cadence tick.

*Checked.* Verified by `suites.nim`: recording to capacity and past it, walking every retained step
forward and back and comparing each state (`scenesEqual`, since `Multivector`'s `==` is an
intentional compile error); camera restoration across two edits from two viewpoints.
Verified end to end: `--drive-undo` and the browser drive both build, orbit away, undo, and
hold the view where the construction was made. The 153.5 / 11.3 ms figures were measured on
the JS backend at 5,038 handles and not since.

## Storyboard And Seeds

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
should not touch it. Nothing assumed.

## Creation-Anchored Plane Centring

A plane's rim and fill centre on `scene.creationAnchor(operation, m, n, derived)` rather
than on its closest-to-origin support, which reads wrong for a plane built from operands
that do not straddle the origin. `Wedge` of a line and a point centres at the midpoint
between the point and its projection onto the line; `ExpandWeight` of a point and a line
where the line meets the plane; the three-point ground seed on the centroid; everything else
falls back to the support. Computed at construction and stored (`anchor_overrides`, a
rendering hint excluded from save/load), since many operand sets produce an identical plane
`Multivector`. All anchor arithmetic is RGA-native — summing unit-weight points and reading
`position`, which divides by weight.

*Checked.* Verified by `suites.nim`: each special case's anchor. Assumed: that no other operation
wants one; none has been asked for.

## Save/Load Format (`.rgascene`)

Compact binary matching `Scene`'s layout, **little-endian throughout** — a free choice that
had to be *a* choice, because the browser reaches it through `DataView`, and little-endian
because every file already written contained it. The desktop converts through
`std/endians`.

| Bytes | Field |
|-------|-------|
| 4 | Magic `RGAS` |
| 1 | Format version (`VERSION_SCENE` = 7) |
| 1 | Basis count (16 under this build); must match |
| 4 | Object count, little-endian `uint32` |
| per object | Ink (1), visibility (1), label length in bytes (1) + UTF-8, one |
|  | little-endian `float` per basis term, the radius as one more `float` |

`MAGIC_SCENE` and `VERSION_SCENE` are exported and reach the browser through
`nimSceneMagic`/`nimSceneVersion`, so there is no literal to drift; labels go through
`TextEncoder`/`TextDecoder`. A value derived in Nim and copied by hand into JavaScript is
the shape of defect that leaves the two builds unable to open each other's files while a
round-trip suite stays green, because it only ever asks one build to read what it wrote.

Only live objects are written, **in creation order** (`nimSceneHandlesCreated`). That order is
the whole of what version 3 added; version 4 appended the radius after each object's geometry;
version 5 appended a byte after that saying whether the point shone, and version 7 dropped it, so
versions 5 and 6 alone carry one, read and skipped. Which versions carry each is
`scene.hasRadius`/`hasShine`, reached by the browser parser through `nimSceneHasRadius` and
`nimSceneHasShine` rather than literals. Version 6 changed no byte: it records that the palette
lost its structural `Algebra` handle at ordinal 7, so every hue a version-2-to-5 file wrote sits
one past today's, and `upgradedFrom5` takes it down. Omitted on purpose: handle numbers, a
per-object ordinal, fixed-width label padding.

**A loaded scene replays its construction.** `born` is not written, but
`scene.bornReplaying(index, count, now)` stamps the `index`-th of `count` arrivals a beat
after the last, and `animationProgress` reads a `born` the clock has not reached as zero.
`SECONDS_REPLAY_STEP` = 0.12 is shorter than the 350 ms appear animation, so an object is
still growing as the next lands; `SECONDS_REPLAY_WHOLE` = 2.5 caps the whole arrival by
shortening the beat, or a full scene would take minutes. Every arrival a reader did not
build replays — a file, the demo, the opening scene — through one rule in both loaders.

**Every version ever written is still readable.** `VERSION_SCENE_LEAST` = 1 and should stay
1: reading an old version costs a mapping func and a suite case, refusing one costs somebody
their scene. Reading is written once against `VERSION_SCENE`; each past version's difference
lives in one `upgradedFrom<n>`, and `objectUpgraded` walks an `ObjectSaved` up the chain one
step at a time. Version 3 costs sizes, `upgradedFrom3` filling
`RADIUS_OBJECT_DEFAULT`, and the chain refuses a radius that is zero, negative or NaN as it
refuses an unknown palette slot; version 1 costs colours only — its ordinals name a palette
that no longer exists, folded by the same cycle `inkCycled` walks, bounded by
`ORDINAL_INK_HIGH_V1` = 14 so a byte version 1 could never have written is refused. **A
wrong hue is recoverable, a refused scene is not**. `loadScene` parses into a staging scene
and replaces the caller's only on complete success; native-only.

*Checked.* Verified by cross-reading, not round-tripping: the sixteen-object demo saved,
reloaded and compared object for object in creation order — label, ink, visibility and all
sixteen coefficients, 304 scalar comparisons exactly equal; the desktop re-saving the
browser-written file byte-identical, all 2245 bytes; hand-built version-1 and version-2
files read the same by both parsers; a file one version ahead refused by both; ordinal 15
in a version-1 file refused; the version-6 fold pinned ordinal by ordinal. Verified by
watching: seeds arriving over 0.480 s and the demo's sixteen over 1.84 s in the browser.
Verified by `suites.nim`: the on-disk bytes of a known float. Assumed: the big-endian host path,
never exercised (see Known Limitations).

## Demo: The Solar Neighbourhood

The demo preset is the build's own load case, in three sizes: `ScaleOrrery.Nearest` (60),
`Neighbourhood` (360, the default everywhere) and `Catalogue` (5038, two handles short of the pool,
the smallest margin that still proves the point of leaving one). Every size is the same construction
truncated at a different depth, so a cost can be read as a slope: 60 / 360 / 5038 objects cost 1.3 /
1.7 / 3.0 s to build, a frame build 3.1 / 4.6 / 12.8 ms, an edit 9.1 / 8.5 / 8.0 ms under
SwiftShader. **Each size lands on its count exactly**: the star walk passes over a system too large
for the room left and keeps walking.

**To scale: one world unit is one astronomical unit**, `KILOMETRES_PER_AU` = 149,597,870.7, and a
parsec is `AU_PER_PARSEC` = 206,264.806 of them. Every distance is the real one and every drawn
radius the real radius: `radiusDrawnOf` divides kilometres by the unit and does nothing else, so Sol
is 0.00465 units wide, Earth 0.0000426, Phobos 0.000000074. Sol stands at the origin with its
ecliptic flat in the ground grid's own plane; `sol` is `1 𝐞₄`, every planet has z exactly 0, Neptune
30.05 units out, and Proxima 268,000. The price is that from the opening camera every body is the
least dot and Jupiter's moons lie inside its dot; the reader dollies in, and each body is its real
size when the camera arrives, which `camera.DISTANCE_LIMIT_NEAR` and `mesh.RADIUS_OBJECT_LEAST`,
both 10⁻⁹, and the pivot-relative record (see Camera) let it do.

**Every moon rings its planet in its real orbit plane.** `MOONS` carries JPL's mean orbital
elements, fetched 2026-09-18 from https://ssd.jpl.nasa.gov/sats/elem/: an inclination and a node
against the moon's reference plane, named by its pole in J2000 right ascension and declination — the
ecliptic for Luna and Nereid, Uranus's equator for its five, a local Laplace plane for the rest.
`normalOfMoon` turns the equator's node about the pole by the node angle, the pole about that line
by the inclination, then the whole into the ecliptic frame by the J2000 obliquity 23.4392911°.
Uranus's pole is the spin pole (RA 77.311°, Dec 15.175°), the antipode of the IAU north, so the
elements' small inclinations read prograde about it as JPL states them. Read off the built scene:
Luna's normal leans 5.16° from +z, Io's 2.2°, Miranda's has z = 0.155 and Triton's z = −0.646, a
ring run backwards. The horizon plane is `att(ecliptic) ∧ att(earth ∧ luna)` and exists only because
Luna's ring leaves the ecliptic. **Stated simplifications**: planets ring Sol in the ecliptic
itself, inclinations dropped (Mercury's 7° the largest), since Earth in the spanned plane is what
the horizon block turns on; a body's place on its ring is the golden angle, not a date; neighbour
systems lie flat.

**Two shipped catalogues, data only, generated.** `neighbourhood.nim` is a snapshot of the NASA
Exoplanet Archive taken 2026-08-31 from its TAP service (`select hostname, pl_name, sy_dist, ra,
dec, pl_orbsmax from ps where sy_dist < 35 and default_flag = 1`): 331 planet hosts out to 31.5
parsecs. This research has made use of the NASA Exoplanet Archive, which is operated by the
California Institute of Technology under contract with NASA under the Exoplanet Exploration Program.
`starfield.nim` is a snapshot of SIMBAD, every star within the same 31.53 parsecs, with the query
recorded in the file: 11,252 kept of 11,432. Each planet host was matched to exactly one star **by
sky position alone**, worst separation 161 arcseconds — Barnard's and Kapteyn's stars, the two
highest proper motions known, are the two worst matches. Distance is not used to match because it is
what the two archives disagree about, so the star layer supplies every position and distance and the
archive only which planets exist. **Both catalogues are equatorial and the scene is ecliptic**:
`systemAt` turns every star's direction by the same obliquity the moons are turned by, so the star
field and Sol's planets share one frame; read straight, every star stood 23° off against them.
**Nothing is generated**: a star with no known planet is a star, and the 49 of 544 planets with no
recorded semi-major axis are left out rather than placed by their order among siblings, `placedOf`
counting what a star places and `objectsOf` folding it. Neighbour suns and planets are drawn at
`RADIUS_OBJECT_LEAST`, a dot claiming no size, since neither catalogue carries radii. A neighbour's
plane is joined as `star ∧ along ∧ across`, a point and two directions: three of its points a
million units out cancel to noise, a tenth of the normal.

**The opening camera frames Sol's system to Neptune**: `RADIUS_ORRERY` is Neptune's own semi-major
axis, fitted by `camera.distanceFitting` at `ELEVATION_ORRERY_SHOWN` = 0.95 rad (at 0.42 every ring
collapses to a line) with `INSET_ORRERY_SHOWN` = 24 px. Not the nearest neighbour: Proxima stands
nine thousand opening radii out, and a frame holding it shows one dot. **Colour says what a thing
is, not which system it belongs to**: `lut_role_to_ink` maps a `Role` to an `Ink`, four kinds of
body on four handles and everything derived on the fifth, `Olive`, the darkest.

*Checked.* Verified by `suites.nim` at every size: every star at the distance its table gives it and
in the direction its coordinates give once turned into the ecliptic, the table ordered outward, the
count exact, the camera solve, every object against the role table with four distinct body inks;
every planet at its real axis with z = 0, every moon at its real axis perpendicular to
`normalOfMoon` with the leans quoted above pinned; every neighbour planet at its real axis at its
star's height and every planet without an axis absent, 49 counted from the table; every body's
radius the conversion of its kilometres; no point a hub (lines and planes through any point ≤ 6);
the two horizon points' difference. Verified by reading the built scene: the normals quoted above.
Verified by driven check: the demo button stands the camera back past 40 units, and the occlusion
check stands its own camera by Jupiter's real radius for a sixty-pixel disc with Io in front of it.
Assumed: the archive snapshots themselves, and the JPL elements transcribed by hand. **No table is
checked against its source by any tool.**
## Operation Notation

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

*Checked.* Verified by rendering all 27 entries at once and reading them; by suite, every
entry non-empty and the substitution's placeholder rules. Verified then, by the prototype's
`check_atlas`, that every glyph is in the atlas; nothing here re-checks it.

## Naming And Number Formatting

Basis elements are named exactly as the library's `$` names them (`𝟏`, `𝟙`, bold `𝐞` with
subscript digits); `lut_basis_to_name` **derives** them from the enum, and a suite case holds
each entry equal to what the library prints. Magnitudes read to **four significant digits**
(`DIGITS_SIGNIFICANT`): desktop `snprintf("%.4g")` into a stack buffer, browser
`format.formatMagnitude` in plain Nim behind `nimFormatNumber` — a decimal exponent by
`log10`, digits scaled, and **half-to-even** rounding, which C uses and Nim's `round` does not
(1012.5 reads `1012` in C and `1013` from `round`). `formatBiggestFloat` disagrees with itself
across backends on 1655 of 7000 values, so it is no primitive to build on. Both front-ends
print a multivector through one writer (`scene.multivectorText`) and a shape through one
(`scene.shapeText`). Diagnostics readings keep `%.*f` through `appendFixed`, since a live
number that changes width is harder to read.

Fixed char storage is read through `format.toText`, never `$toCstring`, which casts the
storage's *address* and yields an empty string on the JS backend.

*Checked.* Verified by `suites.nim` on both backends: 17,001 values across 25 decades including
every exact eighth, zero disagreements against C's `%.4g` and zero between backends; the JS entry
point pins the tie cases' text directly. A C-only `magnitudesAgree` stays green while 330 of 7000
values differ between the front-ends, which is why the suite runs under `nim js`.

## Animation

`ANIMATION_MILLISECONDS` = 350 and `easeOutCubic` are the one duration and one curve: a fresh
object grows in over them, the camera tween eases over them, and the browser reads them across
the bridge into `--anim`/`--ease` on `:root` (the CSS curve `cubic-bezier(0.215, 0.61, 0.355,
1)` is easeOutCubic exactly). One exception, marked as one: the opening hint is a timed
disclosure whose delay lives in the browser scripts alone — a stylesheet `transition-delay`
runs from the class being added rather than from load, so the two stack.

*Checked.* Assumed: that one duration suits every transition; nobody has asked otherwise.

## Camera Aiming And Framing

`camera.aimIncluding(aim, geometry, scale)` folds one object into what the camera has been
asked to show: a horizon point contributes its direction, a horizon line the first axis
spanning perpendicular to its normal, a horizon plane nothing, and anything finite widens a
bounding sphere by `mesh.anchorFor`'s point. `CameraAim` is a **requirement**, a pure function
of the geometry, so the standing offer re-made every frame compares equal. **The sphere is
over what has to fit** (`is_bound_by_fitted`): the first point or finite plane folded in
discards whatever lines contributed, since a line whose support stands forty units off
drags the view off the point beside it. A plane widens the sphere by its **whole disc**.

Both builds aim from **one rule**, `framing.offerAim`, once per frame: the open session's
staged multivector if there is one, else every selected object. **A standing offer** — the
tween keeps its goal after arriving; a camera the user moves calls `abandon`, which keeps the
goal and marks it done, where `release` clears it so the offer is re-made next frame and the
camera taken straight back, and panning is dead while anything stays selected. `advance`
eases pivot and angles linearly and **distance geometrically**.

**Framing** (`framing.nim`): on a new pick, **the orbit pivot comes to the middle of what
was picked** — `objects.centroidFolded`, over the same objects the bound is over, each
yielded **once** by `watched` (a middle is a tally where a bound is a set) — and the camera
moves by the **least zoom and orbit** on top of that which puts every selected object in
view, where in view means the centred box `camera.reachCentred` shapes:
`FRACTION_VIEW_CENTRED` = 2/3 of the height, and two thirds of the width **or the height,
whichever is less**. The width cap because the field of view is vertical: uncapped, the
acceptance edge stood at 23.9° across a 1440×900 window against 15.4° down, so a pick on a
desktop practically never moved the camera while the same pick on a phone did.
`reachCentred` is the one statement of the box, from which `picking` derives pixel margins
and `halfAngleCentred` the cone `distanceFitting` solves.

**Three readings, following what each shape is drawn at**: a point's dot fits inside the
centred box (inset by half of `DIAMETER_POINT_LEAST` — the least dot, not the point's own
disc, or a disc filling half the frame would push the camera out to hold its rim); a line
merely crosses it; a plane's **centre** is in the centred box and its **rim** on screen —
holding the rim to the box threw the camera from 19 to 29.9 on the ground plane where 19
already showed the whole circle. **The cut**: `stanceFor` first asks whether everything is
already in view *where the camera stands*, since judged at the centred placement every pick
of something plainly visible pulled the view about; otherwise it builds the full placement
(bisected least distance, `ROUNDS_DISTANCE_FIT` = 8) and searches the least fraction of
`camera.toward` satisfying `isShownAll`, `STEPS_PLACEMENT_LEAST` = 12 even steps then
`ROUNDS_PLACEMENT_LEAST` = 5 halvings. Distance grows, never shrinks; a finite pick never
changes azimuth or elevation.

**A pointer pick keeps its object under the pointer and comes in to it.** The centring rule
above is for picks with no pointer (objects list, keyboard, a shift-added group). A click or
tap on a point or a line records a `framing.PointerPick`, which `offerAim` consumes on the
next frame. The destination is the wheel's own move (`stanceUnderPointer`): the eye comes in
along its line to where the object stands under the pointer, the angles never change, and
the pivot lands on the sight line at the object's depth. **How far in depends on the shape
and on what the reader could see**, sized on the frame's height by
`camera.depthSpanning(diameter, fraction)`: a point drawn at the floor dot is only a place,
so the camera comes in until its disc spans `FRACTION_HEIGHT_APPROACH_POINT` = 0.01 of the
frame's height (a sixth was too close; chosen by eye); a point seen at its size, and a line,
come in no further than the orbit distance; a plane is framed **both ways**, its disc's
centre brought to the depth where the disc's diameter spans
`FRACTION_HEIGHT_APPROACH_PLANE` = 0.40 while the crossing under the pointer stays the held
anchor, falling back to `stanceFor` where that has no positive solution. Not the centring
rule for a plane, which never pulls in. **The ease holds the pixel too**:
`CameraTween.anchor_held` switches `advance` to `towardHoldingAnchor`, where the eye's depth
to the anchor moves geometrically along the eye–anchor line, since `toward` takes the eye off
that line mid-ease. **A pick renews a held goal**: `aimAt`'s `is_renewed` re-arms the ease
for a pointer pick whatever the tween holds, or the same object picked again after the
wheel had taken the reader out goes nowhere.

*Checked.* Verified by `suites.nim`: the pixel stays within 0.01 px through five steps of the ease
and the arrival distance equals the fit; a near point and a line keep the orbit distance; a
re-pick after `abandon` and a dolly re-arms; the plane's arrival from 12 units and from 1.
Verified by driven check: from 45 units a right-click brings the eye to 19.3 with the anchor
drifting 0.00 px in flight and settled; a second pick after wheeling out past 100 comes in
to 19.3 again; a right-click on the ground plane from Home settles its centre at 48.28,
exactly the depth wanted for 0.40; the preview framed with its operands; a pan with a
selection standing, through `driveTwoFingerPan` and `drivePan`. Verified then, by the
prototype's `verify_touch_pan.js`: 63 trials with the orbit turned 0.000 and distance never
below 12.0; a pan with a selection standing 0.21 units against 4.40 with `release`.

## Hold Feedback, Help And Keys

**A touch hold shows itself**: `interaction` owns `SECONDS_LONG_PRESS`, a `Hold`, and
`progressHold`/`isHoldMature`, and the indicator is the marker itself drawn part-built.
Progress is **linear, never eased** — a clock being shown, and an eased clock appears to
stall just before it fires.

Both front-ends carry a `?` in the bottom-right corner, at least 44 px, opening the same
table `help.lut_help_entries`, which both render. Construct rows derive from `armingOf` and
`revealsMenuOn`; keyboard rows from `motionFor` and `actionFor`; the `operations` tab is
generated from the catalogue, so it cannot fall behind. **Tabbed by how you are working**:
`drag`, `select`, `menu`, `panel`, `camera`, `keys`, `operations`. `ENTRIES_MAX_PATH` = 8
per tab (`ENTRIES_MAX_PATH_KEYS` = 12, `ENTRIES_MAX_PATH_CATALOGUE` the operation count),
asserted at compile time and in the suite, a **proxy and named as one**: the real constraint
is rendered height, measured at 320×568 as overflow of the rows box — every tab 0 but
**`keys` 129 px over**, left scrolling deliberately, since fitting it costs `enter`'s "hold
shift to add it" on every screen to serve one with no keyboard, stacking cells is worse
(161 over) and regrouping keyboard rows onto other tabs leaves `camera` 133 over. **Every
row makes sense with the rows above covered up**; what a two-column row cannot carry goes
in `descriptionOf`, one sentence per tab, crossing as `nimHelpDescriptions`. One word, one
meaning: objects are **selected**, operations **chosen**.

The browser's two columns are one grid over the whole table (`.help-rows` the grid, each row
`display: contents`), so a column is one width down the table. Both tracks carry a 122 px
floor, measured: without the outcome floor the actions took 208 of the 262 px a 320 px phone
leaves, and dropping the action track to bare `max-content` put `drag` 533 px over. Rows are
hidden by attribute, which needs `.help-row[hidden] { display: none }`. The desktop measures
its outcome column off the widest action **only while the panel is open**: measuring every
frame changed which glyphs Dear ImGui rasterised into the atlas and moved single pixels of
panel text in the storyboard. `guiChildHeightForRows` asks Dear ImGui for its own line
spacing rather than restating it. **The help stays open until it is closed**.

**Keyboard.** `Escape` sheds what is in progress, innermost first, and on the desktop does not
quit (`ctrl+Q` does). The view is one ordinary tab stop — **Tab is deliberately not rebound**,
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
Blender (WASD, Q/E, shift for faster, F to frame), with the one fork made the map's way: the
view *slides* across the ground and the height never changes. `releaseKeysAll` empties the
held set on blur, on the tab being hidden, and when a panel widget takes the keyboard
(`gui.wantsKeys`). Plain `s` moved to `ctrl+s`. Dear ImGui's keyboard navigation is enabled;
without it Tab reaches nothing on the desktop. **A camera move is not a hover**
(`isMovingCamera`: each front-end's own drag flag plus `keys_held` through `motionFor`),
raised by the movement, not by the press, or a click reads a suppressed hover. **Focus is
its own state** (`index_focus`), pruned against liveness and drawn with the hover marker.

*Checked.* Verified by `--drive-keys`: focus walked, enter selected, azimuth/elevation/distance
each moved by exactly their own constant. Verified by browser drive: real key events; Tab from
the canvas moving to the next control and back; a blur mid-hold moving the pivot 0.0000
further; the help table's per-tab overflow at 320×568; `[]-+` typed into a label reaching the
label. **Not demonstrated**: Tab landing on a Dear ImGui widget — a window that never takes
focus under `xvfb` gives ImGui nothing to move.

## Style Guide

Two documents at the repository root. `CONSTITUTION.md` is the rule of law: eleven articles over
exposition, derivation, notation, build-time safety, naming, documentation, cost, honesty,
tests, form and the record, with a precedence clause and three gated mechanisms. `STYLE.md`
is the Nim expression guide. Every comment is in the `pga` library's register — a
one-line imperative summary ending in a period, elaboration as a hanging outline one claim
per line, no articles, no history and no figures, which live here — and `koch tree` holds
that mechanically over every authored language.

**Foreign bindings are marked `sideEffect`, and that is what makes `func` mean anything
here.** Nim assumes an imported body is pure, so without the mark every GL draw and every
Dear ImGui layout compiles as a `func`. With it on all 130-odd bindings in `gui`, `opengl`,
`sdl3`, `image` and the bridge's `importjs` lines, 51 funcs failed to compile and went back
to `proc`; a `func` in this tree means the compiler checked it reaches no effect.

**Deliberately left as they are**, each against a rule the reader might expect to see
applied: the binding names in `opengl.nim` and `sdl3.nim` keep the foreign API's own verbs,
since a reader greps the SDL and GL references by those names and V.3's bare-noun rule is
for this project's own properties; lookup tables at module scope stay lowercase `lut_…` per
V.5; `nimCameraPivot`, `nimOverlayMetrics`, `nimInkColor` and the scene-listing exports
return sequences, being asked on the UI tick or once rather than per frame; the bridge's
FFI-boundary cases translate through one `SLOT_NONE` at each proc's return; the browser
scripts and `shell.html` use snake_case for data bindings and camelCase for callables. The
six per-frame overlay exports answer from module flat buffers: `nimDragTint` binds the ink,
not the colour, since `lent` bound to `let` copies, and an array literal handed to an
`openArray` parameter is a `new Float32Array` per call, which is why the fills are templates.

The `pga` library is unmodified by request. One substantive deviation: `pga.nim:28`
asserts its own module doc is the source of truth for names, which is what makes the
notation trap easy to fall into (see Operation Notation).

*Checked.* Verified: `koch tree` at 0 findings; the demotion and the revert were decided by
the compiler, not by reading; the six per-frame exports allocate nothing, read off the
emitted JS — the gain is **unmeasured**, an allocation count rather than a millisecond.
**Unverified**: no human has read the result.

## Dependencies / Vendoring

**The PGA library is a pinned dependency, never a copy.** It lives in
[replications][replications], which carries no nimble file and holds the library three
directories inside it, so the requirement in `rga_visualiser.nimble` names the repository by
URL and commit, `atlas.lock` records the resolved commit, and `nim.cfg` names the
subdirectory Atlas restores it to. `koch deps` replays that lock; nothing is committed
(Article XI.3). Both projects are Prosperity Public License 3.0.0. Not a project verb that
clones it, since CI runs `tree`, `deps` and `tests` and never a project's own build driver.

**This project tracks pga's head, and says so when it cannot.** Standing instruction from
the Architect: take the latest pga; when the latest does not work, pin the most recent commit
that does, record which and why, and move forward when it works again. Every pull request
states which pga commit it builds against and whether that is head. The pin stands at head,
`295bafc5e97e8ee94943c6f4c7a92f215a74e5e7`, which costs two things, and the instruction is
to pay both rather than trail behind.

**The compiler is pinned by commit, not by release.** Head spells its operators in prefix and
compound form (`☆m`, `m ∧☆ n`), needing seven Unicode operator characters Nim gained in pull
request 26074 — merged to `devel`, carried by no release. The pin is therefore
`requires "nim == 27763495bcfe265507ca98aedc1c7064bf1e0e4d"`, which `toolchain.nim` accepts
beside dotted versions and which koch fetches and builds once per machine. Not a `devel`
label, a moving pin recording nothing verified; not waiting for a release, which is months
of standing behind the library this project exists to exercise. The pin moves to a release
once one carries 26074. The lexer change reaches this project's own source: `-☆(m)` lexes
as the single operator `-☆` and is spelled `-(☆m)`.

**Four projections are withdrawn at head, and `projections.nim` stands in until they
return.** `projectCentral`, `projectCentralAnti`, `projectOrthogonal` and
`projectOrthogonalAnti` are declared `{.error.}` while the library rebuilds them as compound
operators (`∨∧★`, `∧∨★`, `∨∧☆`, `∧∨☆`); this project calls two of them at eight sites, so
head alone does not compile here. Each stand-in is a template carrying the definition the
library's own operator table gives — copied, never derived, so nothing about the algebra is
invented here (Article II.8). The module is a seam: `scene`, `tessellate`, `interaction`
and the suite import it instead of `pga`; `export pga except` those four keeps the names
from colliding, and importing both raises an ambiguous call rather than quietly answering
from the wrong one. **The guard is what makes this transitional rather than a fork**: a
`compiles` probe through a qualified call reads the library's own declaration, and an
`{.error.}` refuses the build the day it gains a body, naming the module to delete and the
imports to restore. Not holding the pin one commit back, which leaves the project trailing
its own dependency; not reshaping the call sites, which lets the library's build state
decide what the visualiser offers.

**Two Atlas defects stand, and the workaround is manual.** `atlas pin` writes `"objects": {}`
for a repository carrying no nimble file, so the resolved commit is patched into `atlas.lock`
by hand; and `atlas` calls the nimble file "broken" because it cannot parse a commit where it
expects a version, which is cosmetic. The lock's stored nimble must equal the committed one
exactly or `rep` reverts the pin silently (repository issue 25); the static pass refuses the
difference, so the hand-patch is checked rather than trusted.

*Checked.* Verified by running, on the pinned commit through `koch tests`: every suite on the
C backend, on JS and at reduced capacities, at the same case counts the previous pin
produced, which is what says the stand-ins behave as the library's own did. Verified:
`deps/` deleted, `atlas --noexec rep` clones and checks out `295bafc`, `atlas changed` exits
0, and the nimble file is byte-identical afterwards. Verified by running that the guard
fires: `pga.nim` patched to give `projectOrthogonal` a body refuses the build at
`projections.nim(40, 10)` naming the module to delete and the four imports to restore.
Verified: the pinned compiler reports `git hash: 27763495bcfe265507ca98aedc1c7064bf1e0e4d`,
which `toolchain.runningCompiler` reads. Assumed: that no release carries 26074 — 2.2.12,
2.4.0 and 2.6.0 were asked and none does, which dates rather than proves it.

## Testing

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
walks every pair of handles at 10,000 objects runs ten minutes without output; the suite
gathers the joiners once instead. The JS entry point declares `targets: "js"` rather than
overriding testament's command, so under `koch tests` testament compiles with the JS backend
and runs the result through node, which is what makes the row real rather than a claim
nothing checks.

**The suites test rules; a second layer drives events.** A rule bug earns a suite case; a
wiring bug earns a driven check, at the layer the bug lived at — `tools/drive/` for the
page, the `--drive-*` runs for the desktop. A driven check is evidence only for the page
just built, so one command rebuilds before it drives (Article IX.6); a check that leaves
state behind taxes every check after it, and says so. Timing-dependent quantities are
asserted as **bands**: identical code has measured 25.0 and 29.8 ms hours apart on a shared
runner, and a flat ±1 ms band failed one frame in a hundred and twenty.

*Checked.* Verified on the pinned commit through `koch tests`: every suite on the C backend,
on JS and at reduced capacities; the JS count is lower because the C-only cases skip
themselves. Verified on the runner as well as locally: the C suites bind zlib for the PNG
encoder, so their passing proves the runner carries that library. Assumed: nothing about
the suite itself.

## Known Limitations

- Every result is software-rendered and machine-driven; the page has run on one Android phone.
- Tab landing on a desktop widget is unverified (see Hold Feedback, Help And Keys).
- Two crossing translucent veils blend order-dependently.
- A camera move is not undoable on its own.
- The comet's residual steps at fast orbit rates are unexplained (see Selection And Markers).
- Neither catalogue is checked against its archive by any tool.
- No tool in this repository re-measures the palette floors (see Colour Palette).
- The frame-time tail on real hardware is undiagnosed; this container cannot see it.
- Conformal metric (`IS_CONFORMAL`) is unfinished in the library; this build is rigid 4D.
- `.rgascene` is little-endian by rule, but only a little-endian host has ever written or
  read one; the byte-swapping path is unexercised.
- A page whose WebGL lacks `EXT_frag_depth` keeps linear depth, the far field's fault with it,
  and every plane's disc at its centre's depth.
- The demo's planet inclinations, ring phases and neighbour planes are stated simplifications.

## Open questions

**The drawer's `backdrop-filter` costs about 12 ms of every frame at the largest scene, and is
the whole of what an open drawer costs.** Measured with the drawer open over 5,040 objects: 59 ms
per frame against 47 ms with the filter forced off, where the drawer closed is 47 ms and the page
carries about 860 elements; scrolling the list at 300 px a frame holds 62 ms, 0.8 ms of it in the
`ui` phase. The blur is what makes the drawer read as glass over a live 3D view, so it is not
plainly the wrong trade; the figure is recorded so the question can be asked with it rather than
about it. Software rendering inflates a blur far more than it inflates the rest, so the share is
an upper bound on hardware. The choices are to keep it, to drop it, or to drop it only while the
frame runs slow.

[replications]: https://gitlab.com/mraxilus/replications
