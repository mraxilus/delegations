# Provenance

_Who made this, from what, and how far it has been checked._

| Field   | Value |
|---------|-------|
| Harness | Claude Code |
| Author  | Claude Opus 5 and Claude Sonnet 5 |
| Date    | 2026-09-06 |
| Style   | CONSTITUTION.md and STYLE.md, followed. |
| Rules   | 874ef979b21fbc1e |
| Pruned  | ca56fd4f8b61f44d3b38f3533ba0f177c4cc27b8 |
| Review  | **Unreviewed.** Nothing here has been read line by line by a human. |

An interactive visualiser of rigid geometric algebra objects, built as a testbed for the `pga`
library. It holds geometry and a scene model shared by two front-ends, and the encoders that a
scripted storyboard writes its frames through.

This file records the **current** design by subsystem. It also records the reasoning behind
decisions that are not obvious from the code: what was chosen, what was rejected, and what the
choice costs. It is not a changelog.

A rejected alternative appears only where it is still a live trap, as a terse "not X, because Y". A
figure is kept beside the constant it justified, because the comments in the source carry no figures
(Article VII.5). What came out is in git, and the `Pruned` row names the last commit that still
carried the pruned text.

**What is here.** The render-path-independent core sits under `src/rga_visualiser`. The browser
front-end sits under `src/browser`, its page under `pages/`, and its harness under `tools/drive/`.
The desktop front-end sits under `src/desktop`, with the PNG and GIF encoders and the arena they
write through. There is one suite, run in three configurations. Every section below describes code
that this repository builds and drives.

**How claims are marked.** Each subsystem closes with a *Checked* block. *Verified* means that the
claim was established by a run of something, and it names what. *Assumed* means that it rests on
reasoning alone. A figure with no *Verified* line beside it was once read off a panel and not
measured again since, so treat it as indicative.

Six tools that the prototype carried are not in this repository. They are `check_palette`,
`check_atlas`, `check_prose`, `check_columns`, `verify.sh` and `verify_touch_pan.js`. A claim that
one of them held is marked as held by that tool then, and re-verified by nothing here.

**Verification practice, applies throughout.** Every change is rebuilt, and the full suite is run
again through `koch tests`. That runs on the C backend at two capacities, and on the JS backend.
Both front-ends are driven through `tools/build.nim drive`. **No human has driven either front-end,
clicked a button, or seen this on real GPU hardware.** Every figure in this file was
software-rendered.

## Vocabulary

**The terms are the Architect's, in `GLOSSARY.md`, and the code says them.** A rename here is never
a substitution. Every word named more than one thing, and only one sense moved, spared by an
explicit list rather than by a rule.

`slot` meant an address, an `Ink` palette position and a timing array position, and only the first
is `handle`. `target` meant five things: the orbit centre, the object a press points at, the DOM
event target, a render target, and a plain goal. Only the first is `pivot`. `budget` names real
allowances of time, pixels and segments, and the frame-rate lines are `mark`s, because nothing is
held to them.

**Three names could not be taken, and each says why in place.** `object` is reserved in Nim, so the
code-position `item` took a role instead. It is `one` where an object is reached through the
accessor, and `saved` where a record is read out of a file.

`handle` collides with `typedthreads.handle` of the standard library, which wins over an injected
local inside a template, so `picking` turns on `openSym`. `iterator items` keeps its name, because
it is the protocol of Nim itself.

**Two spec keys must never be renamed, and neither would fail loudly.** `targets: "js"` is a
testament key, and renamed, the browser suite runs on the wrong backend. `visualiser.items_max` is a
compile-time define named in the `matrix` of the small suite. That the constant and the define still
meet is checked by a compile against it.

**Uppercase constants sit outside word boundaries**, so a rename by word misses `ALPHA_WASH` and
`WIDTH_SHAPE_WORD`. The compiler names each miss.

**`GHOST` could not become `PREVIEW`.** Nim compares identifiers ignoring case after the first
letter, and ignoring underscores. The type `Preview` exists, so `none(Preview)` resolved to the
renamed variable. It is `PREVIEW_EDIT`, beside `PREVIEW_APPLY`.

**`horizon` stays the word of `pga`**, and has no entry here, because the vocabulary of the algebra
belongs to that library. An ideal object does not sit *at* the horizon. It lies *in* it, so the kind
words that a reader sees are `horizon point`, `horizon line` and `horizon plane`.

*Checked.* Verified after every rename. Every suite is unchanged, case for case, which is what says
that no behaviour moved. `tsc` is clean after `bridge.d.ts` is derived again. `koch tree` reports 0
findings. Both front-ends are built and driven.

## Wording catalogue

**Every word that either front-end shows has one name in `wording.nim`, and neither writes a
literal.** Shown text written where it is drawn puts one sentence in two places, and two places
drift. The window and the page had said different things about the same wedge, the same coefficient
grid and the same outcome. The catalogue is a `Wording` enum and a table indexed by it, so a key
renamed there fails to compile, rather than fails to match.

**The page fills its markup at build time, rather than at load.** Its labels live in markup, and not
in TypeScript: 44 static text nodes against 6 written from scripts. To strip an attribute and set it
from a script serves a tooltip. It would also empty 44 elements, invent 44 ids, and leave the page
blank until its scripts ran.

`tools/build.nim` already rewrites `shell.html` on the way out, for `@SCRIPT@` and `@EMBED:<face>@`.
`@WORD:<key>@` joins the same pass. The real text is therefore in the committed markup, so it reads
with the first paint, and with scripts refused. A token that names a key the catalogue does not
carry stops the build.

**The guard is total, rather than a list of forbidden strings.** `checkWording` refuses a quoted
literal at any of the fourteen panel calls that put text in front of a reader. It refuses one at
`.title`, `.textContent` and `.innerHTML` in every browser script. A hidden Dear ImGui id (`##name`)
and an empty label are allowed, because neither one is shown.

It also refuses the opposite defect: a catalogue row that no front-end names. The catalogue cannot
then grow words written for nobody.

`tools/build.nim` imports the catalogue rather than parses it. To read `wording.nim` as text to
recover the keys of the enum stops at the first blank line inside the enum. To walk `Wording` after
an import of it fails to compile when a key moves.

**One key for each control, and not one key for each word.** `NameRowHide` and `NamePickHide` both
read `hide`, and are two keys. Two buttons honestly wear one word, and a translator may still need
them apart.

The law that no two keys carry the same text therefore holds over **prose** keys alone. Those are
the tooltips and notes, where a repeated sentence is a copy. Labels carry their own law. Each one is
stripped, with no doubled space, no trailing full stop, and at most `RUNES_LABEL_MOST` runes.

**Every control that both front-ends have is explained on both, from one key.** The page hangs 34 of
the 40 `Tip` keys on its controls, set from scripts at load, because the markup carries no `title`.
The six it does not hang are the window's alone. Those are its two file-path fields, its vsync
switch, its two arenas, and its scene block. The page row of that block reads a count over a
capacity, rather than the bytes that the sentence names. A control that the page has, and the window
explains without the page explaining it, is a gap to close, and not a design choice.

**The application names itself once.** `NameTitle` reads `RGA Visualiser`, and both front-ends take
it. The caption of the window is `captionWindow()`, which reads the catalogue rather than spells the
name a second time. A law requires that name to be title case, and every other label to stay a word.

**Help rows and outcome sentences are the catalogue's too.** A help cell is a `Help` key, the title
of a tab is a `NameTab` key, and its line is a `NoteTab` key. `help.nim` holds which cell sits in
which row, and nothing that a reader sees.

A cell is neither label nor sentence, because it is read across its row. So it carries its own law:
no capital opens it, no full stop closes it, and no two say one thing.

A row that names a button or a key composes it through the funcs of the catalogue itself
(`withButton`, `namesJoined`, `sectionNamed`, `wheelWordsTaught`). The glue between the name of a
button and its words is the catalogue's, as much as the words are. The menu tab names each button by
the key of the button, so a renamed button is renamed in its row.

Outcome sentences are composed here as well, `derivedMessage` among them, which four sites had each
written out. `message.nim` keeps how long an outcome stands. The guard sweeps `help.nim` for any
quoted letter, because a word quoted there is a copy that the catalogue cannot see.

Not here: the words of the algebra itself. Those are operation names and notation from the
declarations of `pga`, kind words, and key and button names. Help composes with them, rather than
copies them.

*Checked.* Verified by build and by driven check. `declare` reports **173 wording keys**. A literal
put back at a label call is refused, which is how three page-only strings in `state.ts` were found.
A key named only inside the catalogue is refused as shown by nobody. A `@WORD:` token that names an
absent key fails the build, with the line that carries it.

## Driven checks

**Suites test rules, and this layer tests wiring.** Nothing in the suite presses a key, turns a
wheel, or puts two fingers on the canvas. So nothing in it catches a rule wired to the wrong event.
`tools/drive/` does, through Playwright, against the page that `tools/build.nim web` assembles.
`nim r tools/build.nim drive` runs both front-ends.

**Every check passes**, with one module for each section of what the page does. `drive` counts them,
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
| `demo`, `loaded`, `objects` | preset, culling, occlusion, a line through a point, loaded |
| `message`, `style`, `type`, `canvas` | outcome fade, declared CSS, faces in roles, blank refused |

**A timing-dependent quantity is asserted as a band, and never as a figure.** How far a held key
travels depends on the frames drawn while it was down. A band that will not settle is widened, with
its reason recorded. It is never deleted, and never narrowed to fit one lucky run.

**Accounting allows two frames of its sample to miss, as a count rather than a share.**
`ceil(0.995n)` equals `n` for every `n` under 200. So a share demanded every frame at the 49-frame
sample of `loaded`. There is now one definition, exported from `scenery` (repository issue 47).
Per-frame tolerances are untouched, because a real accounting fault misses on every frame.

**Count the mechanism that the claim names.** The cadence check of the panel counts `askSlowPass`,
which is the entry of the tick itself, where asks are `ceil(ticks/5)`. It does not count calls to
`drawExceedance`, which the axis switch and the gliding axis reach too. That gave 138 of 138 on one
run, and 137 on the next, from identical code. Verified by a break on purpose: four axis presses in
the window.

**Waits are conditions that the page reports, and not spans of clock.** Camera ease and settling
after a click are `waitForFunction` over what the page says: `settleCamera`, `settleCount`,
`settleSelection`, `settleDrawer`, `settleHelp`, `settleBranch` and `settleReading`. Pacing inside a
drag loop is `waitFrames`.

The 16 fixed waits that remain are measurement windows, and each one says so at its site.
`settleReading` waits on `ms_refresh_ui`, which is the clock of the tick itself. It never waits on a
row that the tick writes, or the wait would assert what the check goes on to ask.

**Settle on what moves, and not on what has stopped changing.** Two polls of an unmoving stance
agree before an ease has begun. So `settleCamera` asks the ease: `nimCameraCarrying` reports
`goal.isSome and not is_arrived`. It waits one draw first, because that draw arms it (repository
issue 73). Verified by a break on purpose: return at once, and every loss is framing.

**Pixels are read through the compositor, and a reading that carries no picture is refused.** The
context keeps no drawing buffer, and `gl.ts` says why. So `readPixels` is sound only from inside the
frame that drew. Checks that compare one such reading against another pass on a canvas that reads
back all zero.

The reading is `page.locator('#gl').screenshot()`, decoded in the page, through one
`tools/drive/canvas.ts`. It raises rather than reports, because a canvas that nobody can read is the
instrument lost.

**Refusal is of one colour, and not of black.** The runner has answered a sheet of white as readily
as one of zero, so the fixture drives both.

Every sibling of the canvas is hidden by `opacity` for the capture. The reading is taken again until
it carries a picture, up to ten times. To hide chrome forces a recomposite that a software
rasteriser does not finish inside one frame. It costs about 0.49 s for each reading, about 19 times
in a run.

**Unexplained**: why the runner read blank through `readPixels` and white through the compositor.
Neither Chromium here reproduces either.

**The harness resolves its own browser, and drives the pinned build of Playwright by default.** It
takes what `RGA_CHROMIUM` names, else the build that `package-lock.json` pins, else `chromium` on
`PATH`. On Ubuntu 24.04 that last one is the snap shim alone (repository issue 77).

The lock fixes `@playwright/test` at 1.63.0, and that fixes the browser revision. So this machine
and the runner drive one binary, and `check.yml` caches `~/.cache/ms-playwright` on that same lock.
The pin is a version and not a digest, because Playwright publishes no checksum.

**TypeScript rather than Nim, argued rather than assumed.** The calls of the harness are
overwhelmingly `page.evaluate` bodies that name the exports of the bridge, which `build/bridge.d.ts`
types. Through the foreign-function glue of Nim each one is an unchecked string (repository issue
48). Page-script names that the harness drives are hand-declared in `tools/drive/page.d.ts`, so to
rename one breaks the harness rather than the page.

**A dropped CSS declaration is invisible to the CSSOM, so the check reads authored text.** A parser
discards a declaration whose property it does not know. So a sweep over `cssRules` passes on the
very page the check exists for. `driveStyleDeclared` scans the `textContent` of the `<style>`
element itself, and asks the browser whether each property name is one it knows. A fixture asks
whether it can tell `align-items` from `align-objects`.

**The heading checks hold geometry, paint and shape separately.** `driveHeaderPinned` sweeps
`elementFromPoint` across the full band width, because the midline alone passed while rows showed in
a 28 px strip. `driveHeaderBanded` reads the computed fill *opacity* of every heading, at rest and
pinned, rather than a notation, because a `color-mix` fill computes to `color(srgb …)`.
`driveHeaderStyled` compares radius and border against `.toggles`. It does not compare against
`.brand`, which takes an accent border whenever the drawer is open.

**The list is held to a window, and never to a fill.** `driveListWindowed` shuts the objects section
and opens it again. It reads the rows standing before the click returns. They stand for every
object, and number no more than three screens of 40 px rows. That is loose where it must be, and
still tens against thousands.

It then scrolls to either end, and finds the row of that end on screen within the same bound. The
bound is stated in the check as well as in the page. A check that reads the window out of the page
passes whatever the page does.

Time is reported and never asserted: 3 ms here, with 27 rows standing for 5,040 objects. How long
tens of rows take is the business of the runner, and the count holds on every runner.

`driveEditFromMenu` opens the panel onto the 41st object created, near the far end of the list. It
reads that row as standing before the call returns. It also reads it as lying under the pinned
heading, with its whole form above the floor of the scroller.

**A touch id is never reused across gestures.** Every gesture starts by asking the page whether any
pointer is still down. The page keys live pointers by id. So an id reused from the gesture before
overwrites a finger left standing by a dropped or reordered lift, in silence. The pair that the page
reads is then not the pair the harness sent. That is the one mechanism found for a two-finger pan
reading as a pinch (repository issues 153 and 154).

A fresh id for each finger leaves a stale one standing where the guard names it. The check of the
gesture itself then fails on it.

The guard reads events that the browser delivered, through a listener that the harness installs on
`window`. It never reads the bookkeeping of the page itself. The surface of the page is not widened
for a test, and what is asserted is what the page received. It is silent when clean, and reports the
stale ids when not. One positive check stands before the pan, which follows a tap.

**The check of the chip row asserts reach beside fit.** `driveChipRowFits` requires exactly two
toggles wherever they stand alongside zero overflow. A row that fits because two controls were
dropped is broken more quietly. It sweeps 396, 395 and 394, because a rule written one pixel out
passes every sweep that never lands on it.

*Checked.* Verified by a run. Every check goes through `tools/build.nim drive`, on both front-ends,
software-rendered, here and on the runner. `driven` gates `audit`, so a green push run is the word
of the runner itself (repository issues 47 and 91).

**Unmeasured**: the figures are this container's, and say more about SwiftShader than about any GPU.
Bands are what the checks assert.

## Browser front-end

**The page is one self-contained file.** It opens from `file://`, or from an artefact host that
reaches no font host and no script host. That is why every face is inlined as base64, and every
script is concatenated into `pages/shell.html` at its `@SCRIPT@` token by `tools/build.nim web`.
`pages/shell.html` stays whole markup, rather than ends mid-`<script>`. A committed page that cannot
parse alone is a page that no checker can read.

**Scripts share one global scope, rather than import each other.** TypeScript 7 removed `outFile`,
so the compiler no longer bundles, and the page cannot resolve ES imports without a server. Files
carry no top-level `import` or `export`. `SCRIPTS` in `tools/build.nim` is the order they
concatenate in, which is load-bearing, because `const` is not hoisted. Rejected: a bundler, which is
a second toolchain for one concatenation this build already does.

**Article II.9 is the boundary that matters.** Every join, meet, pick, drag and camera move is
computed by `src/browser/bridge.nim`, compiled from the same modules that the desktop draws through.
TypeScript owns WebGL, DOM and pointer events alone. Each script argues for itself in its header, on
the phrase `not Nim because`, which `justification.nim` demands of a gated kind.

**The declarations of the bridge are derived, and never kept beside it.** `tools/build.nim declare`
reads the `{.exportc.}` signatures of the bridge itself, and writes `build/bridge.d.ts`. A
hand-written copy of those signatures would be a second home for each one. `types` is `declare` and
both type-checker configurations, and it stops there. `web` and `drive` both call it. Verified by a
break on purpose: to rename `nimSceneHandles` alone fails `types`.

**Type-checking runs under `strict`, `noUncheckedIndexedAccess` and `exactOptionalPropertyTypes`**,
as CONTRIBUTOR.md requires. Indexing therefore reports absence. The flat buffers of the bridge are
read through `flatAt` and `pointAt`. A buffer arrives carrying its own count, and every walk is
bounded by it. `elementById` fails loudly for markup that this build ships, and `elementIfPresent`
reports absence for an optional one.

**Node dependencies are pinned, and their checkout is not committed.** `package.json` and
`package-lock.json` are committed, and `node_modules/` is ignored. `typescript` 7.0.2 and
`@playwright/test` 1.63.0 are Microsoft's, both Apache-2.0. `@types/node` 22.20.2 is
DefinitelyTyped's, MIT, and it types the Node surface that `tools/build.nim` and the harness reach.
Each licence is read off the package rather than assumed.

**System packages are declared as data in the build driver.** `SYSTEM` in `tools/build.nim` pairs
each package with what it is for. `system` prints those names for the caller to install (repository
issue 60). No package version is pinned or invented.

**`drive` fetches faces, and `web` refuses without them.** A caller who reaches for `web` directly
is building, rather than being given.

**Faces come from the store of the repository, and which faces is this project's.** `koch assets`
holds any file fetched at build time: the names, the digests and the fetch, in
`curator/audit/src/assets.nim`. The `assets` verb of this project copies the faces of both
front-ends out of it (repository issues 116 and 124).

Those are the `@fontsource` `woff2` of the page, and the desktop's own, which `FACES_DESKTOP` names.
The page takes Commit Mono, Noto Sans at 400 and 600, Noto Sans Math, Noto Sans Symbols 2, and Noto
Serif. All are under the SIL Open Font License 1.1. Commit Mono is `otf` there, which is what its
author publishes, and `stb_truetype` reads its CFF outlines.

`assets` writes `build/fonts/store.list`, one line for each face, naming the store entry it was
copied from. `web` compares its input against that entry before it embeds. Verified by a break of
it, twice: `store.list` moved away, and one byte appended to a copied face.

**The math face is pinned one version behind its siblings**, which is the fetch pinned rather than
the family. 5.3.0 renamed its subset, and an unversioned path had kept working only by a fall back
to 5.2.8 (repository issue 111).

**Three faces, three roles, and nothing else picks between them.** The standard of the Architect is
Noto Serif for titles, Noto Sans for body, and Commit Mono for code and monospace. The page draws
them through `--serif`, `--sans` and `--mono`. The desktop draws them through `guiHeader` and
`guiMonoPush` with `guiMonoPop`.

What counts as a title is looked up. Material 3 puts text inside components in the label role. So
the help tab strip and the toggle chips stay sans. The serif takes the headings that name a section,
and the name of the application itself.

**Commit Mono splits its ligatures across two switches, and the page needs both.** The distributed
`woff2` carries `calt`, which browsers apply unasked, and which most ligatures ride on. The opt-in
sets are `ss01` to `ss05`, which the arrows and comparisons come from.

So the stylesheet says `font-variant-ligatures: common-ligatures contextual` outright, because a
reset that writes `none` takes `calt` with it. It says `font-feature-settings: "ss01" 1, "ss02" 1`
to ask for what is never on. No combination moves a column. Noto Sans Math publishes an `ss01` that
the mono stack falls through to, and the operators rendered identical either way.

**The serif ships at 600 alone, because 600 is the weight every title is set at.** A weight that
nothing ships is a face that the browser of the reader invents (Article X.8). The check reads
pixels, and not width. The heading shot as the page has it, and again with the interface face forced
onto it, makes one picture where there should be two. Width cannot part them.

**The desktop draws the same three roles.** `NotoSerif-SemiBold` matches the 600 of the page, and
`CommitMonoV142-400Regular` sets notation. The supplementary ranges are merged into the mono and
interface faces, because those rows carry wedges. Commit Mono comes from the repository of its
author, because `@fontsource` ships no TrueType.

**Ligatures cannot reach the desktop at all**, because Dear ImGui shapes no text, so no GSUB feature
fires.

**The chip row floats over the canvas, and its width budget is measured rather than assumed.** Six
controls ride it, and the row is flex. So where it stops fitting, what gives is the controls inside
it.

There are two breakpoints, each one swept a pixel at a time. Below **497 px** the brand draws
`NameChipDrawer` in place of its name, at 123 px wide at 497, and 34 at 496. Below **395 px**
`.toggles` moves into the menu popover, under its own `show` heading, at 1 px over at 394, and 75 at
320.

It is moved rather than copied. A second pair of buttons would be a second `on` state to keep in
step with the scene's own. `#top-menu-show[hidden]` spells out `display: none`, because an author
`display` beats the user-agent rule for the attribute.

**The heading of a section holds its place while the list of that section scrolls under it.** That
is `position: sticky; top: 0` against `.drawer-scroll`. The clearance that the floating row needs
sits on `.drawer`, outside what scrolls. A sticky offset is inset by the padding of its own
scroller.

The heading wears its pill at rest and pinned alike, so a list moving and a list still show one
heading. Rejected: a band only while pinned, watched through a sentinel and an
`IntersectionObserver`. A heading then changed its look between a list moving and one at rest, and
the bar of the desktop is filled throughout.

**A heading wears the pill that the controls of the chip row wear**, still or scrolling. It has the
same radius, the same 1 px `--border`, and the box that `.object-row.selected` already uses.

The fill is **opaque**, although the pills it borrows its shape from are `--surface` over a blur. A
heading asked to hide rows cannot be seen through. That fill is the ground of the drawer itself,
arrived at as the drawer does. It is `color-mix(in srgb, rgb(22 27 34) 82%, var(--bg))`, and `gl.ts`
writes `--bg` at runtime from the clear colour. A named tone drifts.

Rejected: a shadow, which made pinning read as *floating*. Rejected: a rule under a section. The
pills part sections by themselves, and a rule beside them stood as a residual line over the next
pill at rest.

The box is **square**, with `.section-header::before` drawing the pill over it. A radius clips the
fill it rounds, so a box that *was* the pill left four corners bare for rows. Rejected: a backing
inside it. `position: sticky` opens a stacking context whatever its `z-index`, so a negative child
paints over its own border. It takes `border: 0`, or the button's own stands.

**Only the rows near the viewport exist.** The list is a window over its keys. Two spacers stand in
for the rows above and below, at the heights those rows measured, or 61 px until they have. The
window covers the height of the scroller, plus one screen either side.

A scroll marks the window stale, and the frame loop settles it after the writes of the tick itself.
The cost then lands in the `ui` phase, and the layout that its reads force serves the tick too. A
refresh renders at once, so a caller that changed the scene finds its row standing before the call
returns.

Keys are rebuilt only when the revision of the scene, its count, or the composing row moves. A
refresh on selection alone then keeps five thousand keys as they stand. Heights are read by a
`ResizeObserver`, and never inside the scroll path, which also catches a row that changes size
without a rebuild.

Rejected: a time-sliced build of every row. At 5,038 objects that is 2,862 ms of list filling,
across 33 frames of 80 ms, with 45,813 elements standing after. The window opens in 3 ms with 27
rows, and the page then carries about 750 elements, 250 of them in the list.

To scroll it at 300 px a frame builds about five rows a frame, for 0.8 ms of the `ui` phase. The
frame itself moves from 59 to 62 ms. Rejected: `content-visibility: auto` over every row, which
skips their layout and not their building.

Cost: a row that leaves the window is built again on its return, at about 0.15 ms each. A row above
the viewport is an estimate until it is scrolled to, which the scroll anchoring of the browser
absorbs. The spacers are `overflow-anchor: none`, so the anchor is always a row. A jump to an
estimated offset, with nothing but a spacer in view, adjusts nothing.

**A comment may not quote a closing block-comment delimiter.** A comment that does ends itself on
the spot, and the prose after it parses as CSS. That was enough to swallow 141 of the 150 rules of
the page, with the page still drawing. Delimiters are named rather than quoted.

*Checked.* Verified by a cold run. `clean` removes `build`, `bin` and `nimcache`. Then `drive`
fetches every face, builds both front-ends, and drives them with no step run by hand, which is the
case of the runner itself. A second run fetches nothing.

Verified by type-checker: every script is clean under the three flags above, with no `any` and no
non-null assertion. Verified by driven check: `driveTypeRoles`, `driveTypeDrawn` and
`driveTypeLigatures`.

Scene save and load remain **untested** here, because nothing drives the file picker.
**Unverified**: no human has driven this page.

## Desktop front-end

**Two libraries are bound rather than wrapped, and only where they are called.** SDL3 owns the
window, the input and the OpenGL context, and libGL owns the driver. Both are external concerns
that this project exists to look past (Article II.8). So `src/desktop/sdl3.nim` and
`src/desktop/opengl.nim` declare only the symbols called, each one through the header of the
library itself. The library flag sits in the module that needs it, and never in configuration.

**Mirrored constants are checked against the header's own, by a generated assertion.** The event
kinds, scancodes, modifier masks and window flags of SDL3 are mirrored as Nim constants, so that
`case` can bind them. Each one is paired with the name of the header in one table, and
`CHECKS_MIRROR` emits one C++ `static_assert` for each pair. Verified by a break on purpose:
`Scancode.Home` moved by one fails with `SDL3 binding is stale`. OpenGL enumerants are literals,
and are never renumbered.

**Dear ImGui is reached through C entry points, because there is no symbol to bind.** Its
interface is C++ with overloads, default arguments and namespaces, and the `cpp` backend of Nim
imports none of the three. So `src/desktop/gui_shim.cpp` flattens the slice that this visualiser
calls into plain C, and `src/desktop/gui.nim` binds that. It is a facade that declares exactly
the widgets used. Cost: to add a widget touches two files. The kind is registered *gated*
(repository issue 26), so `justification.nim` demands that its header carry `not Nim because`.

**Dear ImGui is compiled into the binary rather than linked, and pinned by commit.** That is
`fd13a1e8923a0a7077b404fc36fd063b25a0c0b5` of the `docking` branch of `ocornut/imgui`, MIT
licence, cloned into `deps/imgui` and never committed.

`IMGUI_USE_WCHAR32` is set by a compiler flag, rather than by an edit to the `imconfig.h` of the
checkout. The notation carries bold operands past what a 16-bit `ImWchar` expresses, and an edit
to a checkout would not survive a reclone. `checkImgui` reads the `HEAD` of the checkout itself,
and refuses by name.

**Neither SDL3 nor Dear ImGui arrives as a package, so `desktop` fetches both at their pins.**
Ubuntu 24.04 carries no SDL3 at all. SDL3 is cloned at its tag, and built into `build/sdl3`,
which is a prefix inside the tree. No step then needs root, and `clean` removes it.

`checkSdl3` reads what `pkg-config` reports there, and the commit that the clone stands at,
before anything is compiled: `3.2.30`, zlib licence. Neither library is in `SYSTEM`. `cmake`,
`pkg-config` and `git` stay there for their sake.

**The pin is a release tag, and the commit that the tag resolves to is what binds the bytes.**
`release-` prefixed to `VERSION_SDL3` is the ref that fetches. `COMMIT_SDL3`, which is
`f5e5f6588921eed3d7d048ce43d9eb1ff0da0ffc`, is what has to arrive, read through `checkCommit`
(repository issue 126). A moved tag fetches other sources while `pkg-config` still answers
`3.2.30`.

It is held on the warm tree too, and before cmake. The tag stays because `--depth 1 --branch`
needs a ref. That is also why a shallow clone is safe here, and not for Dear ImGui, whose pin
sits behind a branch head.

**An odd patch number names no tag**, because the series releases on even numbers alone
(repository issue 90). 3.2.30 is the newest of a series still maintained (repository issue 111).

**The build dependencies of SDL3 itself are declared too.** `libxext-dev` arrives under nothing
else, and without it cmake reports `SDL_X11 (Wanted: ON): OFF` and exits 1. The cost of the
prefix is `-rpath`, derived from the checkout through `getCurrentDir()`, because a committed
`/opt/...` builds on one machine. Rejected: `/usr/local`, which needs a root that CI is not
granted.

**The renderer owns the OpenGL names, and draws the records of `mesh` through them, one program
for each record kind.** Each program has a vertex shader that widens compact records over static
corner geometry. Buffers are reuploaded whole each frame, rather than tracked for changes.
Upload sits far below the reach of any frame, and nothing can be stale after an edit. These are
the same records that the WebGL side draws, which is what makes this a cross-check rather than a
second implementation.

**The panel holds only what the GUI needs between frames.** Everything else is read straight off
the scene and the camera.

**The entry point owns the window, the event loop and every headless run.** The run modes are
`--screenshot`, `--frames`, `--hidden`, `--storyboard`, `--timings`, `--novsync`, `--fill`,
`--demo` and `--drive-*`. Each one pushes real events through the queue of SDL itself, rather
than calls a handler.

**The compiler flags of the desktop live in the build driver.** The `desktop` verb of
`tools/build.nim` passes the `cpp` backend and the output path. Rejected: `main.nim.cfg`, which
Nim picks up automatically, and applies invisibly to any build of that file. There is no
`-d:release`, because this binary is driven and read, and its `--drive-*` runs report through
assertions that release removes.

**The constant controls float in an overlay of their own, and not inside the panel window**,
where they went with it when it collapsed. They are one line in a `windowBeginPinned` overlay,
which is the door that `?` uses, top right, because the panel opens at the top left.

The menu hangs by its **right** edge. Anchored by its left it opened past the window and was
clipped, and no check caught it, because the verdict asks what the menu *offered*. A change that
alters what a window shows ends with a picture, for that reason.

**Both front-ends offer the same three menu groups, and the demo group is built rather than
written.** It walks `orrery.ScaleOrrery` and labels each button with `objectsOf`, as the page
builds its own from `nimDemoScales`. A size added to `orrery` then arrives in both.

There are two deliberate differences. The menu of the desktop carries `scene file` and
`image file` fields, because a desktop build writes to paths. The menu hangs from its own
button, and not from the pointer. A menu that lands in a different place each time is one that
the reader must find twice. `--drive-menu` opens it with no pointer, through the `is_forced` of
`guiMenuBegin`.

**A long list is bounded, rather than left to run past the window.** It hugs its own content
until the window runs out, and scrolls inside that bound after. That is
`ImGuiChildFlags_AutoResizeY` under `SetNextWindowSizeConstraints`, with the heading outside
that region so it cannot move. Rejected: a fixed height with a threshold, which put a
five-object scene in a box of blank.

**Toggles are pills on both front-ends**, and `guiButtonToggle` carries fill, border and text
colour together. The words of the wheel are taught in the drag tab of help, read from `wordOf`
and `labelOf`. A law in the shared suite holds that every wheel word appears there.

*Checked.* Verified by a run. Both bindings compile and link against SDL3 3.2.30 and libGL
through `nim cpp`, and their assertions run against real headers. Dear ImGui starts over a hidden
SDL3 window, with a real OpenGL 3.3 core context under Xvfb, and draws through both its backends.

Verified by looking. A 300-frame headless run writes a 1440x900 PNG that carries the grid, the
axes, the disc of the ground plane, the points and the panel. So both front-ends draw the same
scene from the same core. 60 frames is not enough for the entrance animation.

**Unverified**: no human has seen this on real graphics hardware. Software GL reports no
multisampled visual, so thin lines alias.

## Desktop driven checks

**The suites test the rules, `tools/drive/` tests the wiring of the browser, and this tests the
wiring of the desktop.** The entry point carries scripted runs: `--drive-keys`, `--drive-sky`,
`--drive-undo`, `--drive-select`, `--drive-drag`, `--drive-menu`, and `--drive-help:<tab>`, one
for each tab. Each one pushes real events through the queue of SDL. `driven` runs all of them
and reports every failure, and not the first. It asks the binary which help tabs exist
(`--help-tabs`), so `help.HelpPath` stays their one home (Article I.4). `drive` chains it, here
and on the runner (repository issue 91).

`driven` counts the scripted runs. They cover these cases:

- a held key slides the view and keeps its height;
- a drag across bare sky turns the view and builds nothing;
- undo takes a construction back, and returns the view to where it built from;
- the choice menu does not swallow the drag after it;
- every help tab opens with rows in it;
- a run whose face is missing still does its scripted work;
- every type role is drawn in a face of its own;
- a scene filled to capacity leaves what follows its list on the window;
- the menu opens and offers the demo at every size that `orrery` has.

**An absent face is a finding, and never an abort.** Dear ImGui asserts inside
`AddFontFromFileTTF` where it cannot open a path, and an assertion is SIGABRT rather than a
report. A declared path that does not resolve then aborts every scripted run. `faceAt` resolves
each face to empty where the file is not there. It says which face is missing, which variable
names it, and which verb fetches it. The interface draws in what is left.

Locations come from the environment first, with one `RGA_FONT…` name for each face. Where the
environment names none, they fall back to the faces that this build ships. That fallback is what
lets `driven` drive the case: it runs `--drive-keys` once with `RGA_FONT` naming a path that no
machine carries.

**This half ships the faces that it draws with** (Article X.8; repository issue 93). `DIR_FACES`
is relative to the binary through `getAppDir()`, so no source names the layout of any machine.
The faces come from the release repository of the Noto project. A tag and a digest pin each
family — `NotoSans-v2.013`, `NotoSansMath-v2.539`, `NotoSansSymbols2-v2.006` — because three
families move on their own.

A read of each font's `cmap` against the ranges that `gui_shim.cpp` declares gives the coverage:
math holds 1,773 of the 1,952 wanted. It costs about 2.5 MB fetched into `build/fonts`, because
`stb_truetype` reads uncompressed faces.

**No default favours a silent pass.** A scripted run supplies `FRAMES_DRIVEN` where the caller
gave no frame bound, because the loop ends only on one. Every scripted run ends in its verdict,
and there is no second flag to ask for it.

**What `driven` costs, on this container, on 4 cores and software GL.** Cold, with neither
checkout present and nothing built, it costs **1 m 27 s**. Warm, it costs **29.3 s**, because a
prefix that already reports the pinned version is kept. On the runner the `driven` step costs
about **3 m 15 s** more with the desktop half than without. That is 215 s against 411 s, one run
against one run. Repository issue 79 weighs that against the rest of the job.

*Checked.* Verified by a run. Every scripted run passes under Xvfb on software GL, from a tree
that carries neither checkout and with no SDL3 anywhere on the machine. A second run kept the
prefix and rebuilt nothing. Verified by a break on purpose: the drag verdict inverted reports
`FAIL  a drag from one object onto another opens its choice menu`, and the verb answers
`Driven runs failed; got 1 -- drive-drag`, with exit 1.

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

`pga` is the dependency above all three, and all three share it. The shared core imports nothing
outside itself and `pga`. `src/desktop` and `src/browser` each import that core, and never each
other, which the import paths show (`../rga_visualiser/`). One driver builds both: `web`
assembles the page, and `desktop` compiles the binary. Neither entry point carries a
configuration file of its own.

`arena` sits in `src/desktop` although it is general-purpose. Only the PNG and GIF encoders and
the draw loop of the desktop reach it. The JS backend cannot carve typed slices from a byte
array at all.

A shared module that reaches for something which only one path has is a **compile error, and not
a comment**. `toCstring`, `buildChars`, `appendInt`, `appendFixed`, `saveScene` and `loadScene`,
with their `std/os` and `std/syncio` imports, carry the guard `when not defined(js)`. Every
binding into C, SDL, Dear ImGui, zlib and JavaScript carries `sideEffect`, so a `func` that
reaches one fails to compile. Without that mark the compiler holds an imported body to be pure.

*Checked.* Verified: the suite runs on both backends, so it exercises the guard rather than
trusts it (see Testing). The `sideEffect` marks are what turned 51 funcs back into procs (see
Style guide). Assumed: nothing.

## Scene storage

`Scene` (`scene.nim`) is a fixed-capacity arena, held as a structure of arrays. The arrays are
geometries, labels, inks, visibility, liveness, birth stamps, creation ordinals, placing stamps,
anchor overrides and radii. A handle addresses each object. `addObject` assigns that handle once,
and nothing moves it after. Free handles thread onto an intrusive singly-linked free list, so an
add and a remove are both O(1). `OBJECTS_MAX` is 5040 and `LABEL_MAX` is 40, and `{.define.}`
overrides both.

This is not a shift-on-delete array. A removal from such an array renumbers every cross-frame
index that a caller holds. Here **a handle number stays valid until its object is removed**.

**`Scene.bound` is the highest handle that was ever occupied**, and every walk of a frame runs
to it rather than to capacity. It only rises, so a walk to it is safe. Three walks run to
capacity for good reason: the free list and the two object-pool strips, whose subject is how
much room is left. The doc comment of `bound` names those three. A walk to capacity over five
live objects costs 13.3 ms a frame on the JS backend.

**`Scene.revision` counts the edits, and every writer sits inside `scene.nim`.** There is no
geometry accessor that returns a `var`, which would be the hole through which a caller could
write with nothing recorded. Undo, redo, clear and every load replace the whole scene through
`restoreFrom`. That call issues a revision **newer than every revision it ever handed out**,
which is `max(live, snapshot) + 1`.

It is not the count of the snapshot plus one. A state between the two had already worn that
number. A placement cache keyed on it then drew six objects of the previous demo over the new
one.

**A placement falls out of date one handle at a time.** `Scene.revisions_placing` stamps each
handle at the edit that last changed it, and `restoreFrom` stamps every live handle of the
snapshot. The placement cache of the browser re-places only the handles that carry a stamp later
than the revision it last filled at. To re-place the whole scene for each edit costs a 42 ms
frame at 5,038 objects. A restore still re-places everything.

**The record of the creation order is explicit** (`orders`, `count_created`, `handlesCreated`),
and nothing infers it. Handle order stops being creation order as soon as anything is removed.
The free list hands the handle that it freed most recently to the next arrival.

A sort by `born` was rejected, because it fails on three counts that all occur. Two objects
added in one frame share a clock reading. The `born` of a replayed object is stamped into the
future. The `born` of a reused handle is stale until something overwrites it.

`handlesCreated` is a heap sort. As an insertion sort at 5,038 objects it ran 12.7 million
comparisons for each call. The panel of the desktop caches its answer against `scene.revision`.
A sort in every frame was 98% of the CPU frame of the desktop at 5,038.

**`LABEL_MAX` counts bytes, so a label is cut on a character boundary and says that it was cut.**
`format.appendChars` copies a UTF-8 sequence only where all of it fits, and `scene.toChars`
rewinds far enough to append `…`. A 3-byte operator glyph that straddles the limit leaves
invalid UTF-8 otherwise, which the JS backend percent-escapes into a name (`%e2%8a`).

`Object` is a handle, and not an assembled copy. Under `nim js` it holds the `Scene` by value,
so the loops that run for each frame use the accessors that take a handle instead.

*Checked.* Verified by `suites.nim`:

- handle stability across a removal;
- `handlesCreated` over a scrambled arena of hundreds;
- `revisionPlacingAt` stamps one handle for each edit, and every handle after a restore;
- `restoreFrom` lands on a revision that no earlier state carried;
- a label cut never splits a character, at any buffer size.

Verified by driven check: undo while the frame is held redraws the current scene, and not the
previous one. The figures 13.3 ms, 42 ms and 12.7 million were read during a fix, and nothing
has measured them again since.

## Memory and allocation

The interactive render loop allocates nothing. `format.nim` wraps the C `snprintf`, so the
number formatting of each frame writes into stack buffers. Message building that a button drives
still uses `strformat`. That happens once for each click, and the result must become a `string`
for `addObject` in any case.

`arena.nim` holds a plain `array[N, byte]`, which `push[T]` carves and `reset` reclaims. The
desktop entry point holds three instances:

| Arena | Capacity | Backs | Reset |
|---|---|---|---|
| permanent | `CAPACITY_ARENA_PERMANENT` 160 MiB | pixel readback, every GIF frame | never |
| frame | `CAPACITY_ARENA_FRAME` 64 MiB | one PNG's scanlines, one GIF frame's scratch | per unit |
| swap pair | `CAPACITY_ARENA_SWAP` 256 KiB × 2 | the draw loop's `DrawScratch` | per frame |

The storyboard run sizes the permanent capacity from its own `arena.used + bytes_needed`, and
not from a round number. The **swap pair** reclaims on the way *in*. What one frame assembled
stays readable through the next, while the block that it moves to starts empty.

A separate pair is better than a larger frame arena. The scratch of an export is tens of
megabytes on a keypress. The scratch of a frame is under 20 KiB sixty times a second. The
largest carver of a frame is the `LINES_GRID_MAX` chords of the ground grid. The capture loop of
the storyboard turns the pair over in its own `renderAt`. Without that, captured sub-frames stack
scratch until the fifth one overflows.

**The undo timeline is the largest reservation that the binary makes.** A `Scene` at 5040
handles is 1.15 MiB as a C struct, which `sizeof` reports as 1,204,616 bytes on the release
compiler. A `Step` is a `Scene` beside a `Camera` of five floats, and `CAPACITY_HISTORY` is 32 of
them. They reserve 36.8 MiB, which is 38,549,528 bytes, against 6.2 MiB for both mesh sets.

In the browser the same timeline is about 105 MB of JS heap. The live page measured 85 MB at
load, before the placing stamps for each handle were added, and nothing has measured it again
since. The depth stays at 32: an edit costs nothing for each step (see Undo/redo), so what
remains is a flat reservation. The lever is linear, at about 1.15 MiB of address space and 3.3 MB
of JS heap for each step. `BYTES_MEMORY_TOTAL` counts it, because a figure that leaves out its
own largest term is worse than no figure.

The LZW dictionary of GIF is a fixed open-addressed hash table, with `CAPACITY_DICT` at 8192 and
multiplicative hashing after Knuth. It is not a third arena, because it probes at random within a
frame rather than appends by bump alone. **LZW early change**: the format widens the code size
one symbol earlier on a decode than on an encode. A decoder written from scratch in the suite
round-trips a real frame past the point of growth.

*Checked.* Verified by `suites.nim`: the swap pair keeps the bytes of the last frame, and the GIF
round-trip holds. Verified by `sizeof`: the sizes of the struct and of the timeline. Assumed: the
JS heap figure for each step, which is extrapolated from one measurement of the earlier layout
without stamps.

## Colour palette

Five hues are assignable — `Rose, Copper, Olive, Jade, Cobalt` — beside `Backdrop`, `AxisX/Y/Z`,
`Grid`, `Guide`, `Outline` and `Invalid`. One `Ink` enum holds them all
(`mesh.lut_ink_to_rgba`).

**`Invalid` is a reserved magenta**, so a reader who sees it knows that an object is wrong. The
drag band wears it over a pair that makes nothing (see Interaction model), and nothing else does.
The interface never leans on it alone, because magenta reads as *blue* under deuteranopia, and
the preview also fails to appear beside it.

The reservation cost three hues. `Violet` and `Cerise` measured CVD ΔE 10.2 and 8.3 from magenta.
`Cobalt` sits 88° of hue away and still measured **6.6**, because blue and magenta converge under
deuteranopia. `Cobalt` is therefore derived lighter and bluer (`#5b90c7`), which reopens the pair
to 14.4.

**Do not fill the rest of the arc back up to eight.** A set of seven hues put `Olive` and a new
yellow-green at CVD ΔE 0.4, and two blues at normal-vision ΔE 5.6. The axis hues flank the
reserved arc on both sides, and leave one warm arc and one cool arc, 162° in total. Five hues are
what fits.

**A structural slot is never offered as the colour of an object.** `mesh` names the boundary
once — `INK_CATEGORICAL_FIRST`, `COUNT_INK_CATEGORICAL`, `inkCategorical`, `categoricalIndex` —
and both pickers and `inkCycled` derive from it. The structural slots are declared first and the
categorical run last, so the run is one contiguous block. A `static: doAssert` on the count holds
that.

The floors below were derived under the `check_palette` of the prototype, which measured them on
every run of that tree. Nothing in this repository measures them again, so a hue moved here is a
hue unchecked.

1. Every pair among the five clears normal-vision ΔE ≥ 15 and ≥ 20° of hue. Lightness can
   never stand in for a difference of hue. `Jade` against `Copper` at CVD ΔE 7.6 sits inside the
   band of 6 to 8, which is legal with a secondary encoding. Shape and screen position are that
   encoding. `Rose` sits at contrast 2.78 against the backdrop, which is under 3:1, and its row
   label is always present as the relief.
2. Axis safety. Each hue clears ≥ 20° and a lower floor of ΔE 4.0 against `AxisX/Y/Z`, so
   nothing mistakes a thin line for a filled object. That floor is looser than the object floor
   on purpose, and it is what freed most of the wheel. One floor for everything crammed every
   hue into an arc of teal, blue and violet.
3. Every assignable hue clears CVD ΔE ≥ 13 from `Invalid`. The worst are `Cobalt` at 14.4 and
   `Rose` at 15.2.
4. Furniture clears ΔE ≥ 8.0 against `Backdrop`. The axes land between 15.7 and 25.3.

**The one declared exception.** `Jade` and `Cobalt` separate by only **3.7 ΔE under
tritanopia**, and the project carries that rather than repaints. The pair clears 12.7 under
red-green deficiency and 15.8 to typical vision. Tritanopia affects fewer than one reader in ten
thousand, and every object carries shape, position and label.

The floors were measured under **Machado, Oliveira and Fernandes (2009) at severity 1.0**.
Viénot-1999 puts `Jade` against `Cobalt` at 0.9 ΔE where Machado puts it at 12.7, so the model is
part of the standard. Red-green deficiency carries the floors, as the minimum of protan and
deutan, and tritanopia is measured on its own.

**Axis colours are dimmed and desaturated at compile time** through `axisTinted`, from
`MUTE_AXIS_TOWARD_GREY` at 0.45 and `SCALE_AXIS_LUMINANCE` at 0.50. The constants are the source,
and not documentation of literals applied by hand. The floors settled them, and not the eye. A
luminance of 0.62 read well and *failed*, because the dimming had walked the green and blue axes
onto the luminance of `Rose`. That is 3.5 and 3.3 ΔE under red-green, against the floor of 4.0.

`Ink.Outline` is kept although nothing draws with it. To remove an entry next to the categorical
run shifts every later ordinal and corrupts the colours of a saved `.rgascene`. The `Ink.Algebra`
of the debug layer *was* removed, and the file format went to version 6 to carry the shift.

**Seed hues**: `ground` keeps the olive of `INK_SEED_GROUND`, and `o` keeps the copper of
`INK_SEED_ORIGIN`. Those two seeds are not arbitrary.

*Checked.* Verified then, by the `check_palette` of the prototype: every floor above, and the
failures of the seven-hue set and of the one floor. Verified by a render: the axis dimming, and
that a grid alpha of 0.55 read as absent (see Geometry and drawing). Assumed: the prevalence
figure for tritanopia, which comes from the literature. **Unverified here**: no tool in this
repository measures a floor again.

## Geometry and drawing

**Plane.** A solid rim (`RingRecord`) with a flat translucent fill (`DiscRecord`, `ALPHA_VEIL` at
0.16). There is no crosshair, no grid and no normal shaft. The radius is fixed at `EXTENT_PLANE`,
which is 8 world units about the anchor of the plane.

It does not scale with the camera, because that visibly resizes a plane as the camera orbits. The
fixed radius is a rendering choice in `mesh` and `picking` alone. Every construction path reads
the full `Multivector`, so a meet lands correctly far outside the drawn disc.

**A meet is read back as the point that it names before anything asks a signed question of it.**
The weight of a meet carries the orientation of the crossing, and `unitize` divides by the *norm*
of the weight, so that sign survives. `depthAgainst` is linear in its point. A meet passed on as
it came therefore reports its depth **negated** on every plane met from behind its normal. Such a
plane picks at 0 of 462 sampled pixels, while the ground plane hides the fault.

**Line.** Two segments meet on the line at its support. Each one runs out to one of the two
vanishing points of the line, `eye ± radius_horizon*axis`. A vanishing point is a property of the
*eye*, which forces this shape. An end anchored at a fixed reach from the support stops short of
it, by about 6.7° for a support 40 units out.

Each segment lies in the plane through the eye that contains the line. The pair therefore draws
over the true projection of the line, within 1e-16 of screen skew. That skew holds only while the
near-plane crossing is stepped from the end that it stands nearer (see Records and shaders).
Stepped from the far end, the two halves part on screen. The far ends sit off the line along the
view ray, so occlusion is approximate there. `picking` tests both halves through
`clipToEyeSide`, which is a near-plane clip written by hand, because this reach puts an endpoint
behind the eye.

**Horizon objects are drawn as sky.** A horizon point is a fixed star at
`eye + radius_horizon*heading`. A horizon line is a great circle about the eye. A horizon plane is
a full-sphere dome (`DomeRecord`, `ALPHA_VEIL_SKY` at 0.22). All three are anchored to the eye in
every frame.

It is a full sphere and not a hemisphere. An orbit view sits elevated and tilted down, so a dome
cut at the horizontal loses sky that the camera sees.

**Draw-order invariant.** Translucent veils blend in scene order with depth writes off. Both
`assembleMeshes` and `bridge.nimBuildFrame` therefore insert the dome of any visible horizon plane
**first**. The fill of an ordinary plane then blends over the sky, whatever handles they occupy.

**Muting.** `mesh.muted()` blends toward the luminance of the colour itself (`MUTE_DESATURATION`
0.6). It does not replace the colour with `Ink.Grid`, which made a muted object indistinguishable
from the grid. `FRACTION_DIMMED_ALPHA` is 0.55.

**Draw sizes live in `mesh.nim`, and not in `renderer.nim`.** They are `DIAMETER_POINT_LEAST` 6.0,
`WIDTH_LINE_OBJECT` 2.5 and `WIDTH_LINE_FURNITURE` 1.5 px, in *framebuffer* pixels. A
`static: doAssert` holds that object lines exceed furniture lines, and `marker` derives every
clearance from them.

**Every point has a radius in world units, and is drawn in perspective.** `Scene.radii` holds one
radius for each handle, and `RADIUS_OBJECT_DEFAULT` is 0.08. That is what a nine-pixel sprite
spans at the opening camera, so an old scene opens looking as it did. Both editors carry a `size`
field, bounded below at `RADIUS_OBJECT_LEAST` 10⁻⁹, because the model refuses zero outright.
`RADIUS_OBJECT_MOST` 1e6 exists because the drag widget of ImGui reads *no upper bound* as *no
bounds*.

A point crosses the wire as one record (`Vertex`), and both front-ends draw it as an **instanced
camera-facing quad** from `mesh.pointCorners`. The vertex shader takes
`radius = max(own, ½·DIAMETER_POINT_LEAST·world_per_pixel)` at the depth of the point, and the
fragment stage discards outside the unit circle. The rule is stated once in Nim, as
`radiusDrawnAt` and `radiusPixelsAt`, and the two shaders are sibling copies of it.

So the size is *fixed in the world* and shrinks with distance. A floor of six pixels keeps a
distant star a readable dot. That is the one departure from pure perspective, and it is what keeps
4,900 catalogue stars visible. Pick, marker, cull and framing all follow the drawn disc.

  **What is under the pointer is what is picked.** Take the cursor inside the drawn disc of some
  point. The nearest such disc to the eye then wins over every point that the cursor is not
  inside, however near their centres. That is the `consider` of `picking.pickWalk`. It is not
  distance to centres alone, which let a background star win through the disc of a planet.

  A point covered by a nearer disc that is narrower than a fingertip is still a rival to the crowd
  rule of touch. One covered by a body as wide as a fingertip is not (`coverOf`). The walk gathers
  the discs under the cursor into a fixed array of eight (`Hiders`) as it goes.

  Depth in the point branch is read off the homogeneous weight of the projection
  (`depthAlongSight`), so the branch builds nothing for each point. The hover pick at 5,038 went
  from 3.5 to 2.2 ms median.

  **Cost, under SwiftShader.** Every CPU phase is unchanged within noise against sprites. The
  whole frame at the largest demo rose from 53–55 to 103–108 ms p50 with the cull off. The
  hypothesis is per-instance overhead in the software rasteriser. **Unmeasured on a device**, and
  the `render` row of the drawer is where it shows.

**Every point is shaded as a sphere lit from world-up.** The light is `camera.UP_WORLD`, one
direction for every point. The vertex shader on both front-ends turns it into the basis of the
camera, as the z components of the three axes. The fragment stage applies Lambert over an ambient
floor, `FRACTION_AMBIENT_SHADE` at 0.25, a quarter. The underside then still reads as a body in
its own hue, rather than a hole in the field.

Nothing in the scene carries a light. Shading is presentation that gives a disc its sphere, and
not a property of any object. It is not a point that shines on the others. The scene format
carried such a point from version 5 to version 6, and the record kept it as a *sun*.

That was one more thing that the astronomy of the demo had written into a visualiser of an
algebra. Every point read the same under it but the sun itself, which drew flat. The cost is three
floats fewer for each point record, and no relighting pass for each edit.

**Furniture** (the ground grid and the world axes) reaches `extent_furniture`, which is
`FACTOR_CLIP_FAR` orbit distances. It is drawn as **fog about the eye**, and not as a halo about
the origin. It is not the far clip, which also reaches the farthest object of the scene. The demo
reaches millions of units. A grid sized to that put its cell at a hundred thousand, with no line
under any camera inside the system of Sol. Lines and the horizon still reach the far bound.

The fog holds full strength within `FRACTION_GRID_FADE_START` at 0.06 of the extent, and is gone
by `FRACTION_GRID_FADE_END` at 0.20 of the extent. Those are 1.14 and 3.8 orbit distances. At 0.03
and 0.12 the ground at the pivot read as absent. A halo makes the origin a place that the reader
may not leave.

The fade runs in the fragment shader against the own world position of the fragment, and holds to
`alphaGridFade` as its reference. A `fog` flag on each record says who fades, so furniture and
scene ribbons share one buffer. `addGrid` lays lines on world multiples of the cell size, inside
the ground disc that the fog leaves (`mesh.radiusGroundFor`). It lays one record for each lattice
line, and skips the two through the origin, which coincide with the axes.

**The cell is `SIZE_CELL_GRID` at 10.0, at every reach that a reader works at.** A cell that walks
with the reach re-scales the ground under a reader as they dolly, and a fixed cell is a ruler. Ten
rather than a hundred, by a render of both. At the opening reach of about 72 units, a hundred-unit
cell put at most one line in view.

`CELLS_GRID_HALF_MAX` at 120 bounds the lines laid, which is `LINES_GRID_MAX` at 241 for each
family. It is **spent on the cell, and not on the reach**: `sizeCellGridFor` steps the cell by
**decades**. Decades nest, so a step coarsens what is drawn without moving a line that the reader
was measuring against. The first step is at 1,200 units of reach.

To cut the *reach* instead leaves a camera past 1,200 units with the ground stopping short. Grid
vertices at orbit distance 300, 1,000, 5,000 and 10⁶ are 86,142, 28,392, 13,818 and 28,392 under
the decade step. Without it they are 86,142, 95,088, 0 and 0.

`addGrid` dims the grid by `ALPHA_GRID` at 0.75, and 0.55 read as absent. **The world axes are
reference**: they fade and cut off on the schedule of the grid itself, so all the furniture ends
at one horizon. An axis without that fade is the brightest mark in any frame, and readers took it
for a drawn line.

**The scale bar**, at the bottom left, is what makes the ruled ground measurable. It draws a span
of ground at its true screen length, with its distance written under it. It steps 1-2-5 by decade
(`STEPS_RULER`) to land near `PIXELS_RULER_WANTED` at 130 px, as every map scale does. A bar tied
to one cell ran 11,983 px at orbit distance 3. Both numbers come from `nimGridMetrics`, in CSS
pixels.

**The drawer draws over it** (`z-index` 3 under the 4 of the drawer), and does not hide it. A bar
that a panel sits on can be read once the reader closes the panel.

*Checked.* Verified by `suites.nim`:

- a meet far outside the drawn disc, from both sides of one plane;
- both halves of a line pickable;
- the dome of the horizon plane inserted first;
- the segment count of the great circle after the eye cut;
- the fog radii at an eye inside its own fog;
- a star behind a wider disc unpicked with one rival, and a moon in front of it picked with two.

Verified by driven check:

- the plane pick from either side, with a sweep of the canvas for a pixel that picks a plane which
  the gesture itself built;
- the length of the scale bar against its label at two distances a decade apart, layered under the
  open drawer;
- forty-eight hover samples across the disc of Jupiter, which find nothing deeper;
- the upper half of a wide disc brighter than its lower half on the page, which is world-up on
  screen from the opening camera.

Verified by a render: the fade fractions, the cell size, the grid alpha and the axis dimming. The
occlusion error at the far ends is assumed to be tolerable, and is not measured.

## Camera

`camera.nim` holds an orbit camera: pivot, distance, azimuth and elevation. `ELEVATION_LIMIT` is
π/2 − 0.02. The opening placement is `initCameraDefault`, which both entry points and `home` read.

**An orbit distance has a floor and no ceiling.** `DISTANCE_LIMIT_NEAR` at 10⁻⁹ is geometry: at
zero the eye coincides with its pivot, and every direction that `camera.frame` derives collapses.
`distanceHeld` is the one statement of it.

It is tiny rather than small. The moons of the demo ring their planets at thousandths of a unit,
and are millionths wide. A floor of a twentieth kept the camera outside every one of them. There
is no ceiling, which would read as a camera bounded to a region, and which nothing downstream
needs.

**Every record is stored about the origin of the frame.** `mesh.clearMeshes` takes that origin,
and both front-ends pass the pivot of the camera. Each of the five record writers subtracts it at
the float32 write. What the camera looks at is then exact wherever it stands. Take a moon a
thousandth of a unit from its planet, a million units out. Float32 about the world origin steps by
a sixteenth there, and loses the whole offset.

The transform of the GPU is `initMatrixViewProjection` about the same origin, with only its
translation column moved. Picking, hover and every marker keep the transform about the world.
`Matrix4` is double precision for the same reason: a float32 translation column carried tenths of
a unit that far out, into every pick.

It is not a moving world origin, which would rewrite every stored multivector for each frame.
Float32 degrades what stands past roughly 10⁶ units from the pivot, which is invisible at that
reach. Wheeled out to 3 × 10¹⁹ the view empties to a speck, and `home` returns.

**Clip planes follow the orbit distance, and nothing clips at the far bound.** `FACTOR_CLIP_NEAR`
is 1/400 of the orbit distance, and `FACTOR_CLIP_FAR` is 20 times it. Where the eye's distance to
the origin plus the reach of the scene is farther, that answers instead (`Camera.reach_scene`,
times `MARGIN_REACH_FAR` at 1.05). Both are derived, and never stored.

The projection has no far plane. Its depth climbs toward 1 − `SLACK_CLIP_FAR`, which is 1/1024,
and never reaches it.

It is not `(f + n)/(f − n)` with the far plane at the reach of the star field. The farthest stars
and the dome at 0.9 of it then sat within two float32 ulps of the far plane. The rounding of an
Android GPU clipped them, so points flickered as the camera moved, and the dome drew in patches
along its cells.

It is not twenty orbit distances alone. With the starfield 3,000 units across, six notches in at
the centre of the demo leave 49 of 4,938 points drawn that way. The reach leaves 367. The reach
(`framing.reachOf`) is stamped onto the camera at every derivation point, rather than kept in it.
`home` and every path that replaces the camera value would drop a stored one.

**Depth is logarithmic, and written for each fragment.** Every fragment shader on both front-ends
writes `camera.depthOf` of its own view depth, which is `log2(D / near) / log2(far / near)` scaled
to clip depth. It writes through `EXT_frag_depth` or through the `gl_FragDepth` of GL 3.3, so
resolution is a fixed fraction of distance at every distance.

It is not linear depth with the near plane raised to hold the ratio at 100,000. That spent nearly
every step inside the first orbit distances, and an Android GPU dropped the whole star field from
beside a far star. It is never written in the clip position. The clipper interpolates clip
coordinates linearly. It cut a corner behind the eye beside its front corner, and the disc ended
at a hard chord.

**The wheel zooms toward what the pointer is over**, which is the map reading of a zoom.
`picking.anchorZoomAt` solves the anchor in three answers, in order. They are the finite object
under the pointer, the ground at `z = 0`, and the level through the pivot. Where none answers, the
wheel falls back to a centred dolly.

**The object or the ground is taken only where its depth is within `FACTOR_ANCHOR_DEPTH` 2 of the
orbit distance, either way.** Otherwise the level through the pivot answers. An anchor on a star a
thousand units off slides the eye 38% of the way toward it for each notch. Six off-centre notches
carried the pivot 1,737 units, against 5 with the window.

A cursor toward the horizon finds ground beyond the window and takes the level. That is what stops
a zoom near the horizon flying off across the ground. The object comes first, because to point at
something means *that thing, at the depth it stands at*. Horizon objects are refused, because they
are at no place. The price is the jump: two notches taken either side of the edge of an object
converge on different depths.

`camera.dollyToward` moves the eye along its own line to the anchor, and scales the pivot toward
the anchor by the same factor. The orbit centre then settles onto what the reader zooms into. The
scale applied is read back from `distanceHeld`, so a zoom stopped by the floor moves the eye by
exactly what it was allowed. **A pinch stays centred**, because the two-finger gesture already
pans by the travel of its midpoint.

**A drag pan grabs the level under the pointer and carries it.** `interaction.panAcross` meets
both ends of the step of the pointer with the horizontal plane through the pivot, and translates
by the difference. It is not a rate for each pixel (`FRACTION_PAN_PIXEL` at 0.0016 of the
distance), which slid within the plane *facing the eye*. That took the pivot from z 1.00 to 6.40,
so every later orbit swung about a point in mid-air. The rate survives only where a ray misses the
level.

**The hold point is bounded at `FACTOR_PAN_REACH_MAX` 4 orbit distances**, because a level meets a
ray aimed near the horizon a long way off. The *point* is clamped rather than the movement, so the
rule stays continuous. Each hold point is taken to its foot on the level, so the tilt of the clamp
cannot leak into the step. Four rather than two: at the opening placement a ray a fifth of the way
down the window already reaches 2.7 distances.

**Keys move by shared rates for each second**: `TURN_SECOND` 1.4, `RISE_SECOND` 1.1,
`SLIDE_SECOND` 1.2, `FACTOR_DOLLY_SECOND` 4.0, and `FACTOR_HASTE` 4.0 under shift. Each frame
scales them by the elapsed time, so a hold covers the same ground at 60 Hz and at 144 Hz. The
dolly compounds as `pow(factor, seconds)`. Drag rates differ between the front-ends for a real
reason. The `SPEED_ORBIT` of the desktop (0.008) is radians for each pixel, and the browser
scripts work in fractions of the canvas width.

*Checked.* Verified by `suites.nim`:

- the logarithmic depth maps near to −1 and far to +1;
- it is monotone across every decade that the demo spans;
- it keeps Io before Jupiter, and a star before the dome, by more than a 16-bit step;
- the flattened float32 matrix keeps the farthest star and the dome half the slack inside the far
  plane, at four orbit distances;
- `norm(eye − pivot)` equals the held distance after a floored dolly;
- the pan holds its height, and the clamp stays continuous;
- the reach is stamped at every derivation point, which the undo-while-held check caught missing.

Verified by driven checks:

- the sky is drawn behind a far star;
- the disc of the ecliptic reaches under a camera 1.5 units off Sol, 0.3 and 0.0003 rad up;
- an object under the pointer drifts 0.000 px across a 3.2× zoom, against 1.957 px with the
  pivot-level anchor;
- a wheel back out returns to distance 19.000 and pivot (0, 0, 1);
- a drag holds 1.000 to 1.000 of height, by mouse and by two fingers alike;
- 500 ms of `w` moved the pivot 12.8 units with z unchanged to four decimals, and 49.3 under shift.

Assumed: that no reader wants a ceiling.

## Records and shaders

**Every line is a quad, and never `GL_LINES`.** A line width is a hint that most WebGL targets
clamp to one pixel. Each end is offset half a width along `directionAcross`, which is the normal
of the plane that joins the segment with the eye. `worldPerPixelAt` scales that offset at the own
depth of *that end*, which keeps the on-screen width constant along a receding line. **The near
plane is clipped against first.** A depth clamped at the near plane breaks the proportionality,
and draws a world axis twenty pixels wide near the origin.

**The crossing is stepped from the end that it stands nearer.** A line reaches its vanishing point
at `radius_horizon`, which the orrery puts 530,000 units out. A step from the far end is therefore
the difference of two places decades apart, and float32 cancels it. The crossing then carries tenths
of a unit, at a near plane whose own pixel spans billionths of one. At orbit distance 0.01 the page
drew `earth ∧ luna` 406 px off Earth, and 1,538 px off at 0.001. It rounded the crossing of
`sol ∧ earth` onto the pivot, so half of that line drew onto the dot of Earth itself.

**The widening runs in the vertex shader on both front-ends.** One `RibbonRecord` of fifteen
floats crosses the wire for each segment, or sixteen with the `fog` flag. Six CPU vertices cost
forty-two floats. An instanced draw expands it: GL 3.3 core on the desktop, and
`ANGLE_instanced_arrays` on WebGL1. Each vertex derives the across as
`cross(head − tail, eye − tail)`.

**Chain of custody.** The GLSL ships, `mesh.expandRibbon` is its reference in Nim, and it is
sibling-marked with both shader sources. The suite holds the reference to the algebra: the near
clip equals `clipToEyeSide`, and the across equals the join
`directionNormal(tail ∧ head ∧ eye)`, sign included.

**A fill of a plane, its rim and the sky are one record each.** A `DiscRecord` of 13 floats spans
the view box of its bounding sphere (`viewBoxOfDisc`), on the static corner buffer of the unit
circle. Every fragment casts its own ray at the plane, `hitDiscAlong`, so the disc is exact at any
grazing angle and agrees with `picking.rayPlaneHit`.

It is not a fan of corners on the plane. A corner of such a fan behind the eye left the clipper a
sliver. That sliver rasterised to nothing under a grazing camera, and the disc ended at a hard
chord.

A `DomeRecord` of 8 floats widens over a static unit sphere, which has no orientation. A
`RingRecord` of 14 floats is the thirteen of a disc plus a width, and one instance draws the whole
circle.

The static corner tables come from one generator each in `mesh`. The desktop reads them directly,
and the browser reads them through `nim*Corners`, so neither front-end holds a table that could
drift from the references. The suite pins those references to the multivector sums that they
replaced.

`ribbonOfRing` derives the very `RibbonRecord` that a rim segment would have been, so one rule
widens a rim and every line alike. The rim steps off `UNIT_CIRCLE_RIM`, resolved at start-up with
the `cos` and `sin` of the runtime itself. It is not resolved at compile time, because that
evaluator need not agree with the libm of each backend in the last bit.

The rim as one record is what the demo frame turns on. 96 ribbon records for each plane were 99.2%
of the ribbon traffic on 132 planes. The median frame of the demo went from 239 to 84 ms under
SwiftShader.

**Every position of a record is stored about the origin of the frame**, which is the pivot of the
camera (see Camera). The suite pins the five writers against an origin a million units off.

**Veil order is kept, and not assumed away.** Two translucent veils still blend in scene order, so
every append extends or opens a `VeilRun`, and both render paths walk the runs in sequence.
`markOverlay` seals the current run. `RingMesh` carries its own `index_overlay`, or the second rim
of a selected plane would draw depth-tested behind the fill that it highlights.

**Capacities are asserted in `scene.nim`**, the one module that can see both sides. To raise
`OBJECTS_MAX` then fails to *compile*, rather than to `doAssert` at draw time, which is a dead
page.

| Cap | Value | Binding case |
|---|---|---|
| `VERTICES_MAX` | 10080 = 2 × `OBJECTS_MAX` | every handle a point, every one selected |
| `DISCS_MAX`, `DOMES_MAX`, `RINGS_MAX` | 10081 = 2 × `OBJECTS_MAX` + 1 | every handle a plane, |
|  |  | every one selected, plus a preview |
| `RIBBONS_MAX` | 20161 = 4 × `OBJECTS_MAX` + 1 | every handle a line, two segments, drawn twice |

The desktop asks for a framebuffer at `SAMPLES_MULTISAMPLE` 4, and **falls back to none where no
visual offers it**. `llvmpipe` under `xvfb` refuses the window outright, rather than downgrades
it. A visualiser that will not start is worse than one whose thinnest lines alias. The browser
context asks for `antialias: true`.

**The flat buffers are the page's own typed arrays, filled in place.** A `seq[float32]` on the JS
backend is an `Array` of boxed doubles, converted element by element into a staging
`Float32Array`. That is a fourth pass over bytes that nothing else read. `FlatBuffer` is a
`Float32Array` behind three `importjs` lines, allocated once at the cap of its mesh and never
grown. Each frame hands back a `subarray` view, with no copy. It measured 0.1 ms a frame.

Draw order in the browser scripts mirrors `renderer.nim`, and a person keeps the two in step by
hand.

*Checked.* Verified by `suites.nim`:

- the widening reference against the algebra;
- the near crossing of a line within one pixel of where the ends of its own record put it, at a
  near plane a four-hundredth of a close-up on a moon;
- every stepped dome corner and ring corner against the sum it replaced;
- the box of the disc against the projection of its rim;
- the ray of the disc landing inside the rim and missing outside it;
- a hit under a grazing eye nearer than the near plane;
- all ninety-six rim segments on the plane at its radius;
- the capacity assertions, by a build of the binding scenes.

Verified by a desktop A/B under Xvfb: 0 of 1,296,000 pixels changed for the move of the ribbon. At
most 38 changed for each storyboard frame, at a channel delta of 12 or less, for the move of the
disc and dome. The record narrows its arms to float32 there. Verified by driven check: the ribbon
records of the demo under 64, against a ring count over 120. Both lines of the orrery cross a ring
of spots about the point that they join, opposite in pairs, with the camera 0.01 and then 0.001
units off it. Assumed: that the figure of 0.1 ms
for the flat buffer holds at the current caps, because it was measured at 1,024 objects.

## Algebra boundary

The **algebra owns geometry**, which is what a thing is and where it stands. That covers
construction, incidence, meets, joins, projections, nearest points and side tests. It covers the
world-space camera, and the rays cast from the screen. It covers the lattice lines and the axes,
which are lines, and everything at the horizon.

The **picture owns representation**, which is how geometry becomes GPU primitives. That covers the
disc and the rim of a plane, and the across-vector of a ribbon. The picture is built with whatever
arithmetic is quickest.

**The compiler enforces the boundary.** `mesh.nim` imports `euclid.nim` and nothing else, so it
cannot name `Multivector`. `euclid` reaches `pga/algebra.nim` alone. `objects.nim` is the
vocabulary of the algebra, and names no Euclidean type. `boundary.nim` is the one module that
speaks both, so every lift and read-out is findable in one file. `tessellate` is the geometry side
of drawing, and calls down into `mesh`.

**A PGA equation on the geometry side is never replaced with linear algebra.** The library is what
this project exists to exercise, so a cost that it carries there is a finding. It is restructured
in the terms of PGA alone: an invariant multivector hoisted, or one join shared across pieces that
provably share it.

What may leave the algebra is the *picture*. Where it does, the algebra becomes the reference that
the shipped form is proved against. The cross product of the across-vector is held equal to the
triple join, and every stepped disc point to the multivector sum.

The horizon shapes, the lattice lines and the axes stay in the algebra. The dense `Multivector` of
16 coefficients is copied by value through every operation, at about 1 to 2 µs on the JS backend.
It stays, because a change to its storage would change the thing that is measured.

**The tessellation assembles before it emits.** Each loop resolves its places through the algebra
into a `DrawScratch`, and emits after. For the grid and the axes the seam is between two procs.
`placeObject` answers what a drawable is and where, from the multivector alone, so the answer
holds while the camera moves. `emitObject(placeObject(...))` is what `addObject` is.

Two steps stay on the placing side inside `emitObject`: the stand-off of a horizon marker, and the
two vanishing points of a line. The cut that the panel reports is by kind of work, and not by
proc. `tessellate` takes its scratch as a parameter. The desktop hands it swap arena memory, and
the browser hands it a fixed buffer.

**There is no debug layer, and nobody is to reintroduce it without an instruction.** A switch that
drew every multivector a frame computed, as what it is, never helped to resolve anything. It is
gone with its two modules, its palette slot, its `nimBuildFrame` flag, its diagnostics row and its
four driven checks. `addGridFamily` and `radiusOnPlaneFor` still lay a lattice on any plane,
because the ground is that case.

*Checked.* Verified by `suites.nim`: every moved form is pinned to its algebraic reference.
Assumed: the figure of µs for each operation, which comes from one profile at 1,024 objects.

## Selection and markers

`selection.nim` is shared. It holds an ordered fixed-capacity list of handles, as a plain value
type. **Order is the whole point**, because an operation reads its operands positionally: the
first handle picked is `𝐦`, and the second is `𝐧`. `Selection.revision` counts real changes, so
the frame record and the desktop panel compare one integer rather than an array of 5,040 handles
in every frame.

Selection is **not** part of `Scene`. It is never saved and never on the timeline, and a
successful undo or redo clears it outright. `pruneDead` runs after a removal, because a freed
handle goes straight back to the next add.

**A selected object is drawn over every other object.** There is one watermark for each mesh
(`index_overlay`, an `Option[int]`, because an index of zero means "all of it"). Then a second
pass runs over **every** primitive kind, against a depth buffer cleared first. It is cleared
rather than the depth test turned off, so selected objects still reject one another by depth. With
the test off, a planet selected after its moon buried the moon in front of it.

It is not a tail on each kind, which left a selected line tinted by a later veil. It is not a
third `MeshSet`, which reserves every cap for a run that is usually one object. On the desktop the
marks draw on the **background** list of Dear ImGui, beneath the panels, and the drag menu alone
stays foreground.

"Just built" and "currently selected" are one mechanism. There is one marker for each selected
handle, in plain white, and every construction path replaces the selection with the handle that it
created. Hover draws the identical marker at `ALPHA_MARKER_HOVER` 0.6, against
`ALPHA_MARKER_SELECTED` 0.9, and keyboard focus wears it too. Only a caller that passes a time
gets a pulse, so motion means selected. `marker.nim` shapes the outline to what it marks:

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
`OFFSET_MARKER_RAIL` is `WIDTH_LINE_OBJECT`/2 plus the gap, which is 7.25 px. `WIDTH_MARKER` is
1.5 px, asserted thinner than the line that it marks.

Each render path strokes the markers in its foreground layer, and never as scene geometry. A loop
on a plane would z-fight its fill, and a marker that the object can occlude is not a marker. It is
not an outline in the style of 3D modelling, and nobody is to reintroduce that without an
instruction.

**A selected object wears its name above its marker**, filled in the own ink of the object and
outlined in the stroke of the marker. Hover and focus wear none. Where it sits is the decision of
`marker.nim`: centred, `GAP_MARKER` plus half of `HEIGHT_MARKER_LABEL` (16 px) above the top of
the outline. Each front-end centres its own text.

  **A label of a line keeps to the own left of the line, beside its support clamped into view.**
  "Above the line" cannot be continuous, because which side is up flips as the line passes
  vertical. The side of the line's *own* direction is continuous. So `marker.placeLabelBesideLine`
  pushes the label to that left, and each front-end sets the clearance along the push, because it
  alone measures its text.

  The anchor is the projection of the support while it is in view, held `MARGIN_LABEL_VIEW` 40 px
  inside the edge. Past that it slides along the visible stretch. It is not the upward side, which
  hopped five times on a camera path of 24 s where this hopped none.

  **The label of a horizon line stands above the leftmost point of either band**, which is its
  left-edge crossing. It is pushed `MARGIN_LABEL_HORIZON` 12 px in from the edge. The rule that
  pushes the label of a line off its rail also pushes it off the band.

  It is not the highest point, which on a level horizon hopped between the two side crossings,
  within a pixel in height. That was 46 swaps of 1,070 px in 97 frames at elevation 0.2. It is not
  flush against the edge, where the name read as cut off.

  **The label of the frame of the sky stands inside the bottom-left corner.** It stands
  `MARGIN_LABEL_HORIZON` in from the left edge of the frame, and `MARGIN_LABEL_FOOT` 40 px plus
  that margin up. That keeps it clear of the scale bar of the page, whose top is 33 px up. It is
  pushed rightward the same way. It is not centred inside the top edge under the chip row, and not
  in the corner itself.

  **Every label is then held wholly inside the view.** `labelInView` clamps the measured box
  `MARGIN_LABEL_EDGE` 4 px in from each edge, on both front-ends.

  **The label of a plane stands on the column of the disc, at the height of the true top of its
  circle.** `marker.topmostOnCircle` solves the top of the projected circle in closed form. Screen
  y is stationary where `(b·d − a·e) + (c·d − a·f)·sin + (b·f − c·e)·cos = 0`. It does not take
  the highest of 64 projected vertices, which hops a segment at a time.

  Its **height** alone is used, and the x of the label is the column of the centre of the disc.
  That is what makes the flip invisible. At the edge-on moment the tops of the far rim and the
  near rim part in x. Both go to the horizon of the plane in y. It is not the own x of the top,
  which pops at the flip.

  **The halo is the colour of the backdrop, and not the white of the marker.** A halo blends with
  the background to knock the surroundings out of the letters. A contrasting halo dominates them
  instead (Peterson, *Cartographer's Toolkit*; Dawson, *About label halos*). It is
  `WIDTH_MARKER_LABEL_HALO` 2 px of `Ink.Backdrop` at `ALPHA_MARKER_LABEL_HALO` 0.85, on a 16 px
  face at weight 600.

  The desktop sets the label in `PATH_FONT_LABEL`, with the math and symbol faces merged in, so
  `G = L ∧ c` keeps its wedge. It has no stroked text, so it draws the label at eight one-pixel
  offsets in the halo colour. The browser stages one SVG `<text>` for each selected handle, with
  `paint-order: stroke`.

**The loop of a plane lies on the plane.** It is traced from the frame of the plane, about the
same anchor that `addPlane` centres its disc on. Its clearance is a world distance, sized through
`worldPerPixelAt` at the own depth of the disc. The gap then reads as 6 px where a reader judges
it, and foreshortens with the disc elsewhere.

**The rails of a line are two straight world-parallel lines, sized by the widest gap that they
will show.** Along the half whose far point lies behind the eye, `clipToEyeSide` cuts it back to
the near plane, where depth *falls*. A world offset then flares: 45.6 px at one camera, against
14.5 at the support.

So `OFFSET_MARKER_RAIL` means **the widest that the pair may read anywhere**. `markerRails`
measures one rail against the other at every drawn end (`apartWidest`), and narrows the world
offset until the widest reading meets the ceiling. Three traps are live here:

- **Settle, do not solve** (`PASSES_MARKER_RAIL` 4), because narrowing moves where each rail
  leaves the viewport.
- **Settle against the finished rail, then draw at the progress asked for**, or the gap widens as
  a touch hold fills.
- **Measure one rail against the other, and not either against the line between them.**

The worst case of a marker lies along orientation, so a sweep of camera *distance* is not a sweep.
**The growth of a rail is measured against the edge of the view** (`fractionLeavingView`), and not
against its own length. The two vanishing points sit at screen distances in a ratio of 314. Rails
are shortened **after the projection**.

**The frame of the horizon plane is an expanding circle that becomes the screen edge.** At each
angle the radius is `progress × half-diagonal`, or the distance to the inset edge, whichever is
smaller. It runs over `SEGMENTS_MARKER_FRAME` 64 even steps, with `CORNERS_MARKER_FRAME` 4 corner
directions merged in by angle. A corner missed by a fraction of a step is a corner cut off.

**The bands of a horizon line are cut to the viewport, and not to the eye alone.** Uncut, a ring
laps 396,102 px against the 1,490 on screen. `markerBands` keeps the longest stretch inside the
window.

**On touch every marker swells clear of the finger** (`CLEARANCE_MARKER_TOUCH` 54.5 px, added and
not multiplied). That is about twice the contact patch of a thumb, and it is zero for a mouse. It
runs on its own clock in four phases (`interaction.swellHold`). It grows over `SECONDS_SWELL_GROW`
0.12 s. It sits at full through the fill, and while the finger is down past maturity. It settles
over `SECONDS_SWELL_SHRINK` 0.15 s once the finger lifts.

`isHoldSpent` is stated against `swellHold`, rather than against the duration a second time. A
subtraction of two large timestamps measured 0.14999999999997 against 0.15.

**Orientation is a pulse that travels round the selection marker.** There is no normal shaft,
which marked every plane permanently to answer a question that a reader asks about one object.
`markerFor` runs a lit run of `SEGMENTS_MARKER_PULSE` 16 points, spanning `LENGTH_MARKER_COMET`
64 px of the outline. It tapers from `WIDTH_MARKER_COMET` 3.5 px down `FALLOFF_MARKER_COMET` 1.2
to `WIDTH_MARKER`. Fixed pixels, and not a share of the outline, because a fraction measured 96 px
along a rail against 334 px round a circle.

**Which way it travels is the orientation.** Nothing computes the sense. The projection decides
the order of a loop. A rail is walked from the far horizon through the support to the near. A band
takes the normal of the great circle. A point and a horizon plane get none.

**The travel is a distance in pixels from a view-independent anchor.** `PulseClock.travels`
advances by `SPEED_MARKER_PULSE` 60 px/s times the seconds, with no camera quantity in the
advance. It is reduced into the current lap in every frame, because `travelled mod lap` amplifies
a one-percent lap change by the laps accumulated.

`PulseTrack` names the anchor, which is the support of a line or the angle zero of a ring.
`originAfterCut` walks angle zero through an eye cut. It is a speed rather than a lap time, which
ran 156 px/s along a rail against 348 round a circle. A gap longer than `SECONDS_STEP_PULSE_MAX`
0.1 s is an absence, and not a frame.

The desktop fill needs a **fixed winding**, which `gui_shim.guiOverlayRibbon` imposes. **A drag
band swells into its head** (`marker.cometFor`), because `a ∨ b` and `b ∨ a` are different
operations.

*Checked.* Verified by `suites.nim`:

- the points of the loop on the plane (1.1e-15 on the antiscalar);
- the straightness of the rails, and their widest reading over an orientation sweep;
- the 68 points of the frame at 296.8 px flat at half progress;
- the head sitting its carried travel at 45 placements;
- a matured hold taken once;
- a full orbit at two elevations in steps of 0.002 rad, with no isolated label step;
- two more orbits: the label of the horizon line on the leftmost band point in the left half;
- the label of the frame on its left edge at its foot;
- the label of a plane a milliradian either side of the flip, standing under a pixel apart.

Verified by driven check:

- 402 frames with 0 label hops;
- 48 frames at phone width with 0 side swaps, and none on the right;
- the label box of the frame in its corner above the scale bar;
- a 720-step orbit with the rail gap changing at most 0.103 px between frames;
- two crossing planes selected changing 15,668 canvas pixels, against a noise floor of 0 pixels.

Verified on the shipped browser: the advance of the comet at 62.4 to 63.3 px/s across four orbit
rates. The residual at faster rates is **not explained** to the standard that the medians are. A
tenth of frames step 236 to 388 px/s at laps and clip transitions. Verified on the desktop: the
pure-ink pixels of the selected line are 2,626 with the second pass, against 1,106 with the tail.

## Picking

`picking.pickNearest` is shared. **Point beats line beats plane, strictly**, whatever the pixel
distance, once the own radius of a shape is met. That priority is what makes generous radii safe.
`RADIUS_PICK_POINT` is 34 CSS px and `RADIUS_PICK_LINE` is 24, sized against a fingertip at phone
density. The test of a plane is area-based.

**Everything drawn is pickable, and the horizon is included.** The rank is point, finite line,
horizon line, finite plane, and horizon plane. The horizon line is tested against the great circle
that it draws as. The horizon plane matches every ray, so it comes last. The extent goes through
`algebraFilled`, which is the one derivation point. Built fieldwise, a horizon point was silently
unpickable with its multivector twins zero.

**The sky is a click and hold target, and never a drag handle. So is a plane that fills the
view.** With a horizon plane visible the cursor is over *something* almost everywhere. A press on
empty space becomes an orbit precisely because nothing was hovered. A finite plane whose disc
spans the longer side of the frame (`picking.coversView`) leaves no empty glass at all.

`isBackdropUnder` folds both cases into one answer, which `beginDrag`, `destinationOf` and
`interaction.is_hover_backdrop` read. A click on empty space selects the sky rather than clears
the selection. A tap still treats it as empty space. A tap on empty space is the only way a finger
has to dismiss a selection. Touch reaches the sky by a long press.

**The pick runs once for each frame, and not for each input event.** A pick walks every live
handle, which is linear in the scene. Pointer motion marks hover stale, and the frame loop picks
once after `nimDriveHeld`. The wheel sums its notches and the loop applies one dolly, which is the
same zoom, because `exp(k·Σdelta)` is the product of the notches. Six notches a frame cost 83.8 ms
of picking. Three paths pick inside their handler because they must answer before it returns:
`pointerdown`, a touch-down and `handleTap`.

**The pick ranks what was drawn.** It takes the placements of the frame and dispatches on
`Placement.kind`, rather than asks `position`, `direction`, `frame` and `spanPerpendicular` again
for each handle. Empty means derive for each handle, which is the desktop path and every suite
case.

**The pick rejects a plane before it meets it.** `isBeyondDisc` bounds the screen extent of the
disc by the silhouette of the sphere that contains it. It is conservative in the depth and
off-axis terms. 20,000 random configurations with 300 surface samples each found no silhouette
point outside the bound.

`geometryOf` hands back a `lent` view, and `projectToScreen` is three dot products in local
floats. The 4×4 multiply with two typed arrays allocated for each call was 43% of a 15.4 ms pick
over 10,000 handles.

**Handle-liveness guards.** Hovered, dragged, focused and selected handles are plain values
carried across frames. Any of them can name a removed object the frame after a delete.
`nimAnchorScreen` reports nothing for a dead handle. `endDrag` on both paths checks `isAlive` on
the source and the destination. A removal of an object clears the highlight on both paths.

*Checked.* Verified by `suites.nim`:

- both boundaries of each radius, and all three priority pairings;
- a horizon point picked;
- the disc bound sampled from inside the view;
- the ground hovered from half a unit (backdrop, drag refused) and from forty (drag starts).

Verified by a handle-for-handle map: 4,914 cursor positions across three cameras over the demo of
1,024 objects. They answered identically before and after the placement and copy changes. Verified
by driven checks on both builds: a drag of bare sky turns the view and builds nothing, and a click
on it selects it. The camera was dropped onto the ground plane, and a left-drag orbited without
building.

Measured then, and not since: one pick went from 11.4 to 3.9 ms p50 at 1,024, and from 15.4 to
4.7 ms at 10,000. A hover pick is 0.7, 1.6 and 3.5 ms at 60, 360 and 5,038.

## Interaction model

**Which button does what, stated once.** `interaction.revealsMenuOn` says whether a click brings
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
object. It is not held back until the ease settles: a menu a third of a second after the click
reads as a missed click. A menu opened with no pointer sits above the anchor.

**A click has no time limit.** `isClick` is distance alone, at `PIXELS_CLICK_SLOP` 6 px. It is not
the 12 px of `PIXELS_TAP_SLOP`. A mouse does not roll, and the allowance of a finger would swallow
the short deliberate drags between two overlapping objects. A deadline of 0.35 s lost every click
held 600 ms. A right press that never moved is a click too.

**The press target chooses the scheme, and the button chooses whether the reader is asked.** Press
an object and you construct. Press empty space and you move the camera: left orbits, right pans,
and the wheel zooms. Left takes the own answer of the algebra on release, and right opens the
four-way wheel.

**A mouse never waits.** `MenuArming` is `Never` for left, `Always` for right, and `OnDwell` for
no button. That last is touch, which has no second button and would otherwise lose `meet`,
`project` and `more…`. `SECONDS_DWELL_MENU` 0.75 sits above `SECONDS_LONG_PRESS` 0.50, so the two
thresholds that a stationary finger races are in the right order. The dwell measures stillness,
and restarts whenever the cursor moves further than `PIXELS_TAP_SLOP`. A dwell that measured
presence opened the menu under a finger that moved continuously.

**Middle is unbound.** **A press that can construct never moves the camera, not even before its
slop is crossed.** The browser decides at the press, in `is_touch_press_constructing`, which is
the same question that `beginDrag` answers when the slop is crossed.

**A finger over a crowd moves the view, and never builds.** In the demo the 34 px reach of the
pick lands on some star almost anywhere, so a one-finger orbit kept becoming a construction drag.
`picking.pickAt` reports how many objects of the rank of the winner *or better* stood within
`RADIUS_CROWD_TOUCH` 72 px. That is wider than the pick reach, because the question is whether the
finger could have meant something else.

`interaction.canConstructByTouch` is true only with no rival, and is asked at the press through
`nimCanTouchConstruct`. Where a gesture is ambiguous, movement wins, because the reader can zoom
in until it is not, while an unwanted object must be undone. It is same-rank only, or every point
on the ground would be a crowd.

**The pivot of the turntable follows what the zoom lands on.** Every rate but the orbit is scaled
by the orbit distance on purpose. A drag or a key hold then moves the view by the same fraction of
what is seen at any zoom. A pinch that zooms straight in, with the pivot left on Sol, leaves the
turntable revolving about a point far behind the planet arrived at.

So `picking.anchorZoomAt` says whether its anchor is where a point or a line *stands*, or a
crossing (`AnchorZoom.is_standing`). `interaction.dollyAt` re-pivots along the sight line to the
depth of a standing anchor after the zoom, through `camera.repivotToDepth`, which leaves the
picture unchanged. The pinch goes through the same rule, aimed at the middle of the frame.

Crossings are followed by the map rule alone. It is not the ground crossing too, which moves the
pivot off its level with every notch and fells five driven pins at once. It is not a plane, whose
depth under the pointer is not its depth at the middle of the frame.

Measured on the demo: eight wheel notches over Jupiter from 30 units hold its pixel exactly. They
bring the pivot from Sol to 0.09 units off the plane of Jupiter.

**Two fingers are read once for each frame, and zoom only past the tap slop.** The move of each
finger arrives as its own `pointermove`. Read there, every step of a pan carried together is a
zoom in by the step of one finger. It zooms out again by the step of the other. That was harmless
while a dolly was a pure scale, and became a pivot-moving re-pivot on every one once it was not.

`glue.settleTwoFingers` reads both fingers once for each frame, from the frame loop. Two fingers
carried together never hold their separation to the pixel. So a pinch zooms only once the
separation has changed by more than `PIXELS_TAP_SLOP`. It measures from the separation where the
slop was crossed, and without a jump.

**The edit preview is drawn at the own radius of the session.** Otherwise an edit of a moon of
0.03 draws a grey disc nearly three times its size over it.

**Edit from the selection menu scrolls to the offset of its row and renders the window there, in
one call.** The offset is the sum of the heights above it, which is an estimate where a row has
never stood. The row then lands inside the window, and one reading of where it actually stands
corrects the rest. It lands under the pinned heading, rather than at the own edge of the scroller,
which the heading covers.

**The gesture clock is seconds**, on whichever monotonic clock the caller owns. A dwell named in
milliseconds once needed 450 *seconds*.

**What a drag builds is read off the operands, and not off the button.** `∧` adds grades and is
drawable where the sum is 4 or less. `∨` adds antigrades and is drawable where the sum is 4 or
more. The table below covers every ordered pair of point, line and plane in general position.
Points lie off the moment curve `(t, t², t³)`, where "no three collinear and no four coplanar" is
a Vandermonde theorem.

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

**At most one of join and meet is ever drawable**, so `proposalFor` is a priority order (Join,
Meet, Project) with no tie. `plane → point` offers nothing, and a release refuses rather than
invents. The table is asymmetric, so the direction of a drag carries meaning. `GENERAL_FIRST` and
`GENERAL_SECOND` are separate from the random operand sets, because a point that lies *on* its
paired line reads zeros from the fixture.

**The drag shows its answer before it commits it.** `Interaction.preview` holds what a release
right now would build. It is drawn in `INK_PREVIEW`, through the same `addObject` that the preview
of an edit session uses. It stands at the same anchor that the commit makes. `choosing()` is the
one statement of which wedge the cursor is in.

**A release can do three things, so there are three tints** (`ReleaseEffect`: `Nothing`,
`Refused`, `Builds`). They are the neutral `Ink.Guide`, the magenta of `Ink.Invalid`, and the next
hue of the scene.

**Every released construction steps the ink cycle**, built or not, so a colour the reader watched
for a whole drag is not offered again. A click does not step it, and undo restores it. Where a
session and a preview both stand, **the session wins**. The preview is **framed together with the
operands that it names** (`Preview.operands`).

**The choice wheel.** Four wedges sit at fixed compass points: join north, meet east, project
south, and `more…` west. Unoffered ones are greyed (`ALPHA_MENU_UNOFFERED` 0.45) rather than
packed out, because a menu whose objects move is one that nobody learns. A wedge is the own button
of the selection menu, moved.

**A wedge says what the picker says.** `labelOf` returns `notationSymbolic` (`𝐦 ∧ 𝐧`, `𝐦 ∨ 𝐧`,
`𝐧 ∨ (𝐦 ∧ 𝐧☆)`), and `More` returns a bare `…`. A release commits whatever is under the cursor,
resolved by `endDrag` through `choiceAt`, so the two paths cannot disagree. The centre
(`PIXELS_MENU_DEADZONE` 26 px) commits nothing, which is why an unasked dwell wheel is safe to
open.

The wheel **latches its destination** when it opens, and **lets go when the cursor leaves it**
past `PIXELS_MENU_DISENGAGE` 150 px, sited off `PIXELS_MENU_CORNER_FURTHEST` 103.9 px. Travel on
to another object re-aims, and never chains.

**A wheel that the reader summoned may veto the release, and one that invited itself may not.** A
pause before the lift is the common touch release, so the centre release of an *unentered* dwell
wheel falls through to `proposalFor`.

`more…` builds nothing, and opens **the own apply picker of the selection menu** over both
operands in drag order. It is not the apply section of the drawer, which buried the two objects
just named. A degenerate construction is **refused**, with the message naming what was degenerate,
and so is one on a full scene.

**Touch.** A finger that presses an object constructs, and one that presses empty space moves the
camera. Two fingers pinch and pan, and cancel any construction. A long press selects.

Once a selection exists, a tap (`TAP_MAX_MS` 350) toggles another in or out, and a tap on empty
space clears. `nimClearHover` runs once the last finger lifts, or the last reading sits stale
forever. `SELECTION` in Nim is the sole source of truth, and the browser keeps a render snapshot.

**Selection menu.** It is one row on both builds, and follows its anchor in every frame. `apply`
is leftmost and never moves, and opens a picker to its right through a `max-width` transition,
because `width: auto` cannot animate. `edit` is shown for exactly one selected. `hide` and
`delete` act on every selected handle, and `✕` clears. `apply` is hidden for three or more
selected.

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
- the re-pivot rules under wheel, pinch and sky.

Verified by driven checks:

- the tint table at each wedge stop;
- shift-clicks held 600 ms selecting;
- the sub-slop touch drag hovering with the azimuth unmoved;
- a finger dragged from a point with a twin 0.05 units away, which orbits and builds nothing;
- `more…` landing on `𝐦 ∧ 𝐧` on both builds;
- the refusal on a full scene;
- a right-click 6 px off an anchor, with the menu up two frames in, and a pan moving menu and
  anchor by one delta;
- the two-finger pan moving the pivot across its level, with distance and height unchanged;
- an emptied list, a deep handle edited, and its form in view.

Assumed: that 0.75 s is the right dwell for any hand.

## Undo/redo

`history.nim` is shared. It is scoped to edits of scene content: add, apply, remove, visibility,
ink, and the `save` of an edit session. That save is the "edit committed" moment that the
continuous widgets lack. It is one fixed array plus one cursor, and not two stacks. An entry is a
`Step {scene, camera}`, and both are plain value types, so a record is a copy and
`entries[cursor].scene` is exactly the live scene. `CAPACITY_HISTORY` is 32.

**The array is a ring.** `first` names the handle that holds the oldest step, and `handleOf` is
the one place where a timeline position becomes an index. To retire the oldest entry moves one
integer. To shift every later entry down is 31 whole scene copies for each edit past the
thirty-second. That was 153.5 ms to toggle the visibility of one object on the JS backend, against
11.3 ms as a ring.

What remains for each edit is the one copy of a `Scene` into the timeline, which is 1.15 MiB
through `nimCopy`. It is not for each frame. `initHistory` fills a timeline that the caller owns.
Returned by value it compiles to a `nimCopy` of thirty-two whole scenes, which was 65% of the load
of the largest demo. `record` writes the fields of a `Step` rather than assigns a literal, for the
same reason.

**The camera rides along, and an orbit is never a step of its own.** Each step records where the
view stood when the edit of *that step* was made. Undo reads it off the entry stepped away from,
and redo off the entry arrived at.

To restore the camera of the state arrived at hands back the view that the *previous* edit was
made from. An undo of the first construction of a session then teleports to the startup view. Not
to record an orbit is the accepted cost of not needing a rule for a gesture to settle. **An
accidental orbit is still not undoable on its own.**

Both front-ends abandon their camera tween on a successful step. The timeline is seeded wherever
the scene is initialised or re-initialised, and a successful step clears the selection and any
preview. It is bound to Ctrl/Cmd+Z, Ctrl/Cmd+Shift+Z and Ctrl+Y on both builds, through one
function for each build rather than the button. The `disabled` attribute of that button is
refreshed on the low-cadence tick.

*Checked.* Verified by `suites.nim`:

- a record to capacity and past it, with a walk of every retained step forward and back;
- a comparison of each state by `scenesEqual`, because the `==` of `Multivector` is an intentional
  compile error;
- camera restoration across two edits from two viewpoints.

Verified end to end: `--drive-undo` and the browser drive both build, orbit away, undo, and hold
the view where the construction was made. The figures of 153.5 ms and 11.3 ms were measured on the
JS backend at 5,038 handles, and not since.

## Storyboard and seeds

`storyboard.constructSeeds` builds five seeds. They are `a`, `b`, `c` raised 2 units in z, `o` at
the origin, and `ground`, a plane joined from three points at `z = 0`. `o` must stay off `ground`,
because one step projects it onto that plane. `STEPS` is eleven derived steps, and both entry
points compute the seed count from `scene.len`. One step (`a ^ ground`) is a grade-4 volume, and
correctly reports "mixed grade, nothing to draw", which is its documented purpose.

Both apps open on the seeds alone. `runStoryboard` distinguishes "reached" from "focal", and
reached but not focal draws muted rather than hidden. Horizon steps aim the capture through
`azimuthElevationFor(heading)`, which is a closed-form inverse of the forward direction of the
orbit camera.

`constructSeeds` deliberately does not stagger the arrivals, because `runStoryboard` sweeps the
animation of each step on a clock of its own. The startup paths call `replayFrom` after it. The
GIF is `FRAMES_GIF_GROW` 6 plus `FRAMES_GIF_HOLD` 4 frames for each step, at `STRIDE_GIF` 2
downsampling and `CENTISECONDS_GIF_DELAY` 8.

*Checked.* Verified by a regeneration: the storyboard is byte-identical across changes that should
not touch it. Nothing assumed.

## Creation-anchored plane centring

The rim and the fill of a plane centre on `scene.creationAnchor(operation, m, n, derived)`, rather
than on its closest-to-origin support. That support reads wrong for a plane built from operands
that do not straddle the origin.

A `Wedge` of a line and a point centres at the midpoint between the point and its projection onto
the line. An `ExpandWeight` of a point and a line centres where the line meets the plane. The
three-point ground seed centres on the centroid. Everything else falls back to the support.

The anchor is computed at construction and stored (`anchor_overrides`, a rendering hint that save
and load exclude). Many operand sets produce an identical plane `Multivector`. All the anchor
arithmetic is RGA-native: it sums unit-weight points and reads `position`, which divides by
weight.

*Checked.* Verified by `suites.nim`: the anchor of each special case. Assumed: that no other
operation wants one, because nobody has asked for one.

## Save and load format (`.rgascene`)

Compact binary that matches the layout of `Scene`, **little-endian throughout**. That was a free
choice that had to be *a* choice, because the browser reaches it through `DataView`. It is
little-endian because every file already written contained it. The desktop converts through
`std/endians`.

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
`TextDecoder`. A value derived in Nim and copied by hand into JavaScript is a known shape of
defect. It leaves the two builds unable to open each other's files while a round-trip suite stays
green. That suite stays green because it only ever asks one build to read what it wrote.

Only live objects are written, **in creation order** (`nimSceneHandlesCreated`). That order is the
whole of what version 3 added. Version 4 appended the radius after the geometry of each object.
Version 5 appended a byte after that, which said whether the point shone. Version 7 dropped it, so
versions 5 and 6 alone carry one, read and skipped.

Which versions carry each is `scene.hasRadius` and `hasShine`, which the browser parser reaches
through `nimSceneHasRadius` and `nimSceneHasShine` rather than literals.

Version 6 changed no byte. It records that the palette lost its structural `Algebra` handle at
ordinal 7. Every hue that a file of version 2 to 5 wrote therefore sits one past today's, and
`upgradedFrom5` takes it down. Omitted on purpose: handle numbers, an ordinal for each object, and
fixed-width label padding.

**A loaded scene replays its construction.** `born` is not written, but
`scene.bornReplaying(index, count, now)` stamps the arrival at `index` of `count` a beat after the
last. `animationProgress` reads a `born` that the clock has not reached as zero.
`SECONDS_REPLAY_STEP` 0.12 is shorter than the appear animation of 350 ms, so an object is still
growing as the next lands. `SECONDS_REPLAY_WHOLE` 2.5 caps the whole arrival by shortening the
beat, or a full scene would take minutes.

Every arrival that a reader did not build replays: a file, the demo, and the opening scene. One
rule does it in both loaders.

**Every version ever written is still readable.** `VERSION_SCENE_LEAST` is 1, and should stay 1.
To read an old version costs a mapping func and a suite case, and to refuse one costs somebody
their scene. Reading is written once against `VERSION_SCENE`. The difference of each past version
lives in one `upgradedFrom<n>`, and `objectUpgraded` walks an `ObjectSaved` up the chain one step
at a time.

Version 3 costs sizes, with `upgradedFrom3` filling `RADIUS_OBJECT_DEFAULT`. The chain refuses a
radius that is zero, negative or NaN, as it refuses an unknown palette slot. Version 1 costs
colours alone: its ordinals name a palette that no longer exists, folded by the same cycle that
`inkCycled` walks. It is bounded by `ORDINAL_INK_HIGH_V1` 14, so a byte that version 1 could never
have written is refused.

**A wrong hue is recoverable, and a refused scene is not.** `loadScene` parses into a staging
scene, and replaces the caller's only on complete success. It is native-only.

*Checked.* Verified by a cross-read, and not by a round-trip:

- the sixteen-object demo saved, reloaded and compared object for object in creation order;
- the label, the ink, the visibility and all sixteen coefficients, 304 scalar comparisons, exactly
  equal;
- the desktop re-saving the browser-written file byte-identical, all 2245 bytes;
- hand-built files of version 1 and version 2 read the same by both parsers;
- a file one version ahead refused by both;
- ordinal 15 in a version-1 file refused;
- the version-6 fold pinned ordinal by ordinal.

Verified by watching: the seeds arrive over 0.480 s, and the sixteen of the demo over 1.84 s in
the browser. Verified by `suites.nim`: the on-disk bytes of a known float. Assumed: the big-endian
host path, which is never exercised (see Known limitations).

## Demo: the solar neighbourhood

The demo preset is the own load case of the build, in three sizes. They are `ScaleOrrery.Nearest`
at 60, `Neighbourhood` at 360, which is the default everywhere, and `Catalogue` at 5038. That last
is two handles short of the pool, which is the smallest margin that still proves the point of
leaving one.

Every size is the same construction truncated at a different depth, so a cost can be read as a
slope. 60, 360 and 5038 objects cost 1.3, 1.7 and 3.0 s to build. A frame build costs 3.1, 4.6 and
12.8 ms, and an edit costs 9.1, 8.5 and 8.0 ms under SwiftShader. **Each size lands on its count
exactly**: the star walk passes over a system too large for the room left, and keeps walking.

**To scale: one world unit is one astronomical unit.** `KILOMETRES_PER_AU` is 149,597,870.7, and a
parsec is `AU_PER_PARSEC` 206,264.806 of them. Every distance is the real one, and every drawn
radius is the real radius. `radiusDrawnOf` divides kilometres by the unit and does nothing else,
so Sol is 0.00465 units wide, Earth 0.0000426, and Phobos 0.000000074.

Sol stands at the origin, with its ecliptic flat in the own plane of the ground grid. `sol` is
`1 𝐞₄`, every planet has z exactly 0, Neptune is 30.05 units out, and Proxima is 268,000.

The price is that from the opening camera every body is the least dot, and the moons of Jupiter
lie inside its dot. The reader dollies in, and each body is its real size when the camera arrives.
`camera.DISTANCE_LIMIT_NEAR` and `mesh.RADIUS_OBJECT_LEAST`, both 10⁻⁹, and the pivot-relative
record (see Camera) are what let it do that.

**Every moon rings its planet in its real orbit plane.** `MOONS` carries the mean orbital elements
of JPL, fetched from https://ssd.jpl.nasa.gov/sats/elem/ on 2026-09-18. Each one is an inclination
and a node against the reference plane of the moon. A pole in J2000 right ascension and
declination names that plane. It is the ecliptic for Luna and Nereid, the equator of Uranus for
its five, and a local Laplace plane for the rest.

`normalOfMoon` turns the node of the equator about the pole by the node angle. It then turns the
pole about that line by the inclination. It then turns the whole into the ecliptic frame by the
J2000 obliquity of 23.4392911°.

The pole of Uranus is the spin pole (RA 77.311°, Dec 15.175°), which is the antipode of the IAU
north. The small inclinations of the elements then read prograde about it, as JPL states them.

Read off the built scene, the normal of Luna leans 5.16° from +z, and that of Io 2.2° from it. The
normal of Miranda has z = 0.155, and that of Triton has z = −0.646, a ring run backwards. The
horizon plane is `att(ecliptic) ∧ att(earth ∧ luna)`, and it exists only because the ring of Luna
leaves the ecliptic.

**Stated simplifications.** Planets ring Sol in the ecliptic itself, with the inclinations
dropped, of which Mercury's 7° is the largest. Earth in the spanned plane is what the horizon
block turns on. The place of a body on its ring is the golden angle, and not a date. Neighbour
systems lie flat.

**Two catalogues ship, as data alone, and both are generated.** `neighbourhood.nim` is a snapshot
of the NASA Exoplanet Archive, taken 2026-08-31 from its TAP service (`select hostname, pl_name,
sy_dist, ra, dec, pl_orbsmax from ps where sy_dist < 35 and default_flag = 1`). It holds 331
planet hosts out to 31.5 parsecs.

This research has made use of the NASA Exoplanet Archive, which is operated by the California
Institute of Technology under contract with NASA under the Exoplanet Exploration Program.

`starfield.nim` is a snapshot of SIMBAD, of every star within the same 31.53 parsecs, with the
query recorded in the file. It keeps 11,252 of 11,432.

Each planet host was matched to exactly one star **by sky position alone**, and the worst
separation is 161 arcseconds. The two worst matches are Barnard's and Kapteyn's stars, which have
the two highest proper motions known. Distance is not used to match, because it is what the two
archives disagree about. So the star layer supplies every position and distance, and the archive
supplies only which planets exist.

**Both catalogues are equatorial, and the scene is ecliptic.** `systemAt` turns the direction of
every star by the same obliquity that turns the moons. The star field and the planets of Sol then
share one frame. Read straight, every star stood 23° off against them.

**Nothing is generated.** A star with no known planet is a star. The 49 of 544 planets with no
recorded semi-major axis are left out, rather than placed by their order among siblings.
`placedOf` counts what a star places, and `objectsOf` folds it.

Neighbour suns and planets are drawn at `RADIUS_OBJECT_LEAST`, because neither catalogue carries
radii. The plane of a neighbour is joined as `star ∧ along ∧ across`, which is a point and two
directions. Three of its points a million units out cancel to noise, a tenth of the normal.

**The opening camera frames the system of Sol to Neptune.** `RADIUS_ORRERY` is the own semi-major
axis of Neptune, fitted by `camera.distanceFitting` at `ELEVATION_ORRERY_SHOWN` 0.95 rad, with
`INSET_ORRERY_SHOWN` 24 px. At 0.42 rad every ring collapses to a line. It is not the nearest
neighbour: Proxima stands nine thousand opening radii out, and a frame that held it shows one dot.

**Colour says what a thing is, and not which system it belongs to.** `lut_role_to_ink` maps a
`Role` to an `Ink`: four kinds of body on four handles, and everything derived on the fifth,
`Olive`, the darkest.

*Checked.* Verified by `suites.nim` at every size:

- every star at the distance that its table gives it, and in the direction that its coordinates
  give once turned into the ecliptic;
- the table ordered outward, and the count exact;
- the camera solve;
- every object against the role table, with four distinct body inks;
- every planet at its real axis with z exactly 0;
- every moon at its real axis perpendicular to `normalOfMoon`, with the leans quoted above pinned;
- every neighbour planet at its real axis at the height of its star;
- every planet without an axis absent, 49 counted from the table;
- the radius of every body the conversion of its kilometres;
- no point a hub, with lines and planes through any point at 6 or fewer;
- the difference of the two horizon points.

Verified by driven check: the demo button stands the camera back past 40 units. The occlusion
check stands its own camera by the real radius of Jupiter, for a sixty-pixel disc with Io in front
of it. Assumed: the archive snapshots themselves, and the JPL elements transcribed by hand. **No
table is checked against its source by any tool.**

## Operation notation

**One table, `scene.lut_operation_to_notation`, is read by both builds.** Each entry is the bold
notation of Lengyel, two spaces, then the English name (`𝐦⊖  attitude`). `notationSymbolic` and
`notationNamed` are its two halves.

`notationSubstituted` walks the template token by token, and inserts each operand name once. A name
that contains a placeholder is then never re-touched, and a template with `𝐧` twice substitutes
both.

A composite name is parenthesised where the template binds it tighter than its own outermost
operator. That is always under a postfix or a negation, and under a binary operator unless that is
its own associative one: `(a ∧ b)★`, `a ∧ b ∧ c`, `(a ∧ b) ∨ c`. It is not bare substitution,
which read `a ∧ b ∨ c`.

**Every glyph and its placement comes from the own declaration doc comment of that operator**, in
`pga/operators.nim` or `pga/multivectors.nim`. It never comes from the summary table of `pga.nim`.
The "Lengyel" column of that table renders several unary operators in a functional shorthand that
the declarations do not use. It has also carried prefix glyphs where the declaration says postfix.

Verify by codepoint, and not by eye: the U+2212 minus looks like a hyphen. There is one deliberate
exception. `Attitude` reads prefix in its doc comment, and is placed postfix (`𝐦⊖`) on explicit
request, for consistency with every other unary entry.

The five accented operands use **spacing modifier letters** (`ˆ` U+02C6, `ˍ` U+02CD, `¯` U+00AF,
`˜` U+02DC, `˷` U+02F7), and not combining marks. Dear ImGui has no shaper, so a combining form
landed to the right of its operand. The tilde-below of antireverse then read as the low line of
the left complement. Of the four compound operators only the `★` pair works infix, and `m ∧☆ n` must
be written `` m.`∧ ☆`n ``.

*Checked.* Verified by a render of all 27 entries at once, read by eye. Verified by suite: every
entry non-empty, the placeholder rules of the substitution, and every parenthesis case. Verified
by driven check: a join of joins flat, and a meet of joins parenthesised on the page. Nothing here
re-checks that every glyph is in the atlas.

## Naming and number formatting

Basis elements are named exactly as the `$` of the library names them: `𝟏`, `𝟙`, and a bold `𝐞`
with subscript digits. `lut_basis_to_name` **derives** them from the enum, and a suite case holds
each entry equal to what the library prints.

Magnitudes read to **four significant digits** (`DIGITS_SIGNIFICANT`). The desktop uses
`snprintf("%.4g")` into a stack buffer. The browser uses `format.formatMagnitude` in plain Nim
behind `nimFormatNumber`. That is a decimal exponent by `log10`, the digits scaled, and
**half-to-even** rounding. C uses half-to-even, and the `round` of Nim does not. 1012.5 reads
`1012` in C and `1013` from `round`.

`formatBiggestFloat` disagrees with itself across backends on 1655 of 7000 values, so it is no
primitive to build on. Both front-ends print a multivector through one writer
(`scene.multivectorText`), and a shape through one (`scene.shapeText`). Diagnostics readings keep
`%.*f` through `appendFixed`, because a live number that changes width is harder to read.

Fixed char storage is read through `format.toText`, and never through `$toCstring`. That casts the
*address* of the storage, and yields an empty string on the JS backend.

*Checked.* Verified by `suites.nim` on both backends: 17,001 values across 25 decades, including
every exact eighth. There were zero disagreements against the `%.4g` of C, and zero between
backends. The JS entry point pins the text of the tie cases directly. A C-only `magnitudesAgree`
stays green while 330 of 7000 values differ between the front-ends, which is why the suite runs
under `nim js`.

## Animation

`ANIMATION_MILLISECONDS` 350 and `easeOutCubic` are the one duration and the one curve. A fresh
object grows in over them, and the camera tween eases over them. The browser reads them across the
bridge into `--anim` and `--ease` on `:root`. The CSS curve `cubic-bezier(0.215, 0.61, 0.355, 1)`
is easeOutCubic exactly.

There is one exception, and it is marked as one. The opening hint is a timed disclosure whose
delay lives in the browser scripts alone. A stylesheet `transition-delay` runs from the moment the
class is added, rather than from load, so the two stack.

*Checked.* Assumed: that one duration suits every transition, because nobody has asked otherwise.

## Camera aiming and framing

`camera.aimIncluding(aim, geometry, scale)` folds one object into what the camera has been asked
to show. A horizon point contributes its direction. A horizon line contributes the first axis that
spans perpendicular to its normal. A horizon plane contributes nothing. Anything finite widens a
bounding sphere by the point of `mesh.anchorFor`.

`CameraAim` is a **requirement**, and a pure function of the geometry, so the standing offer
re-made in every frame compares equal. **The sphere is over what has to fit**
(`is_bound_by_fitted`). The first point or finite plane folded in discards whatever lines
contributed. A line whose support stands forty units off drags the view off the point beside
it. A plane widens the sphere by its **whole disc**.

Both builds aim from **one rule**, `framing.offerAim`, once for each frame. It takes the staged
multivector of an open session where there is one, and every selected object otherwise. **The
offer stands**: the tween keeps its goal after it arrives.

A camera that the user moves calls `abandon`, which keeps the goal and marks it done. `release`
instead clears it, so the offer is re-made the next frame and the camera is taken straight back. A
pan is dead while anything stays selected. `advance` eases the pivot and the angles linearly, and
the **distance geometrically**.

**Framing** (`framing.nim`). On a new pick **the orbit pivot comes to the middle of what was
picked**, by `objects.centroidFolded`. It runs over the same objects that the bound is over, with
each yielded **once** by `watched`. A middle is a tally where a bound is a set.

The camera then moves by the **least zoom and orbit** on top of that which puts every selected
object in view. In view means the centred box that `camera.reachCentred` shapes. That is
`FRACTION_VIEW_CENTRED` 2/3 of the height, and two thirds of the width **or the height, whichever
is less**.

The width is capped because the field of view is vertical. Uncapped, the acceptance edge stood at
23.9° across a 1440×900 window, against 15.4° down. A pick on a desktop then practically never
moved the camera, while the same pick on a phone did.

`reachCentred` is the one statement of the box. `picking` derives the pixel margins from it, and
`halfAngleCentred` derives the cone that `distanceFitting` solves.

**Three readings, each following what its shape is drawn at.** The dot of a point fits inside the
centred box, inset by half of `DIAMETER_POINT_LEAST`. That is the least dot, and not the own disc
of the point. A disc filling half the frame would otherwise push the camera out to hold its rim. A
line merely crosses the box. The **centre** of a plane is in the centred box, and its **rim** on
screen.

To hold the rim to the box threw the camera from 19 to 29.9 on the ground plane, where 19 already
showed the whole circle.

**The cut.** `stanceFor` first asks whether everything is already in view *where the camera
stands*. Judged at the centred placement, every pick of something plainly visible pulled the view
about. Otherwise it builds the full placement, a bisected least distance over
`ROUNDS_DISTANCE_FIT` 8, and searches the least fraction of `camera.toward` that satisfies
`isShownAll`. That search is `STEPS_PLACEMENT_LEAST` 12 even steps, then `ROUNDS_PLACEMENT_LEAST`
5 halvings. Distance grows and never shrinks, and a finite pick never changes azimuth or
elevation.

**A pointer pick keeps its object under the pointer, and comes in to it.** The centring rule above
is for picks with no pointer: the objects list, the keyboard, or a shift-added group. A click or a
tap on a point or a line records a `framing.PointerPick`, which `offerAim` consumes on the next
frame.

The destination is the own move of the wheel (`stanceUnderPointer`). The eye comes in along its
line to where the object stands under the pointer. The angles never change, and the pivot lands on
the sight line at the depth of the object.

**How far in depends on the shape, and on what the reader could see.** It is sized on the height
of the frame by `camera.depthSpanning(diameter, fraction)`. A point drawn at the floor dot is only
a place. The camera comes in until its disc spans `FRACTION_HEIGHT_APPROACH_POINT` 0.01 of the
height of the frame. A sixth was too close, and 0.01 was chosen by eye. A point seen at its size,
and a line, come in no further than the orbit distance.

A plane is framed **both ways**. The centre of its disc is brought to the depth where the diameter
of the disc spans `FRACTION_HEIGHT_APPROACH_PLANE` 0.40. The crossing under the pointer stays the
held anchor. It falls back to `stanceFor` where that has no positive solution. It is not the
centring rule for a plane, which never pulls in.

**The ease holds the pixel too.** `CameraTween.anchor_held` switches `advance` to
`towardHoldingAnchor`, where the depth of the eye to the anchor moves geometrically along the
eye-anchor line. `toward` takes the eye off that line mid-ease.

**A pick renews a held goal.** The `is_renewed` of `aimAt` re-arms the ease for a pointer pick
whatever the tween holds. Without it, the same object picked again, after the wheel had taken the
reader out, goes nowhere.

*Checked.* Verified by `suites.nim`:

- the pixel stays within 0.01 px through five steps of the ease, and the arrival distance equals
  the fit;
- a near point and a line keep the orbit distance;
- a re-pick after `abandon` and a dolly re-arms;
- the arrival of the plane from 12 units and from 1.

Verified by driven check:

- from 45 units a right-click brings the eye to 19.3, with the anchor drifting 0.00 px in flight
  and settled;
- a second pick after a wheel out past 100 comes in to 19.3 again;
- a right-click on the ground plane from Home settles its centre at 48.28, which is exactly the
  depth wanted for 0.40;
- the preview framed with its operands;
- a pan with a selection standing, through `driveTwoFingerPan` and `drivePan`.

Verified then, by the `verify_touch_pan.js` of the prototype: 63 trials with the orbit turned
0.000, and the distance never below 12.0. A pan with a selection standing moved 0.21 units,
against 4.40 with `release`.

## Hold feedback, help and keys

**A touch hold shows itself.** `interaction` owns `SECONDS_LONG_PRESS`, a `Hold`, and
`progressHold` with `isHoldMature`, and the indicator is the marker itself drawn part-built.
Progress is **linear, and never eased**. It is a clock being shown, and an eased clock appears to
stall just before it fires.

Both front-ends carry a `?` in the bottom-right corner, at least 44 px, which opens the same table
`help.lut_help_entries`. Both render that table. Construct rows derive from `armingOf` and
`revealsMenuOn`, and keyboard rows from `motionFor` and `actionFor`. The `operations` tab is
generated from the catalogue, so it cannot fall behind.

**Tabbed by how the reader is working**: `drag`, `select`, `menu`, `panel`, `camera`, `keys` and
`operations`. `ENTRIES_MAX_PATH` is 8 for each tab, with `ENTRIES_MAX_PATH_KEYS` at 12 and
`ENTRIES_MAX_PATH_CATALOGUE` at the operation count. It is asserted at compile time and in the
suite, and it is a **proxy, named as one**.

The real constraint is the rendered height, measured at 320×568 as the overflow of the rows box.
Every tab is 0 over, but **`keys` is 129 px over**, and that is left to scroll deliberately. To
fit it costs the "hold shift to add it" of `enter` on every screen, to serve one screen with no
keyboard. To stack the cells is worse, at 161 over, and to regroup the keyboard rows onto other
tabs leaves `camera` 133 over.

**Every row makes sense with the rows above covered up.** What a two-column row cannot carry goes
in `descriptionOf`, one sentence for each tab, which crosses as `nimHelpDescriptions`. One word,
one meaning: objects are **selected**, and operations **chosen**.

The two columns of the browser are one grid over the whole table: `.help-rows` is the grid, and
each row is `display: contents`. A column is then one width down the table. Both tracks carry a
122 px floor, measured. Without the outcome floor the actions took 208 of the 262 px that a 320 px
phone leaves. A drop of the action track to bare `max-content` put `drag` 533 px over.

Rows are hidden by attribute, which needs `.help-row[hidden] { display: none }`. The desktop
measures its outcome column off the widest action **only while the panel is open**. To measure
every frame changed which glyphs Dear ImGui rasterised into the atlas, and moved single pixels of
panel text in the storyboard. `guiChildHeightForRows` asks Dear ImGui for its own line spacing,
rather than restates it. **The help stays open until it is closed.**

**Keyboard.** `Escape` sheds what is in progress, innermost first, and on the desktop it does not
quit, because `ctrl+Q` does. The view is one ordinary tab stop, and **Tab is deliberately not
rebound**, because that would trap the reader (WCAG 2.1.2). Traversal took the brackets instead.

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

`motionFor` and `actionFor` split by **kind**. A motion runs in every frame that its key is down
(`driveHeld`), and an action runs once at the press. The bindings follow Unity, Unreal, Godot and
Blender: WASD, Q/E, shift for faster, and F to frame. The one fork is made the way of a map: the
view *slides* across the ground, and the height never changes.

`releaseKeysAll` empties the held set on a blur, on the tab being hidden, and when a panel widget
takes the keyboard (`gui.wantsKeys`). Plain `s` moved to `ctrl+s`. The keyboard navigation of Dear
ImGui is enabled, because without it Tab reaches nothing on the desktop.

**A camera move is not a hover.** `isMovingCamera` is the own drag flag of each front-end, plus
`keys_held` through `motionFor`. The movement raises it, and not the press, or a click reads a
suppressed hover. **Focus is its own state** (`index_focus`), pruned against liveness and drawn
with the hover marker.

*Checked.* Verified by `--drive-keys`: focus walked, enter selected, and azimuth, elevation and
distance each moved by exactly their own constant.

Verified by browser drive:

- real key events;
- Tab from the canvas moving to the next control and back;
- a blur mid-hold moving the pivot 0.0000 further;
- the overflow of the help table for each tab at 320×568;
- `[]-+` typed into a label reaching the label.

**Not demonstrated**: Tab landing on a Dear ImGui widget. A window that never takes focus under
`xvfb` gives ImGui nothing to move.

## Style guide

Two documents sit at the root of the repository. `CONSTITUTION.md` is the rule of law. It is
eleven articles over exposition, derivation, notation, build-time safety, naming, documentation,
cost, honesty, tests, form and the record. It carries a precedence clause and three gated
mechanisms. `STYLE.md` is the Nim expression guide.

Every comment is in the register of the `pga` library. That is a one-line imperative summary that
ends in a period, then elaboration as a hanging outline, one claim to a line. It carries no
articles, no history and no figures, and the history and the figures live here. `koch tree` holds
that register mechanically over every authored language.

**Foreign bindings are marked `sideEffect`, and that is what makes `func` mean anything here.**
Nim assumes that an imported body is pure, so without the mark every GL draw and every Dear ImGui
layout compiles as a `func`. The mark is on all 130-odd bindings in `gui`, `opengl`, `sdl3`,
`image` and the `importjs` lines of the bridge. Under it, 51 funcs failed to compile and went back
to `proc`. A `func` in this tree means the compiler checked that it reaches no effect.

**Deliberately left as they are**, each against a rule that the reader might expect to see
applied:

- the binding names in `opengl.nim` and `sdl3.nim` keep the own verbs of the foreign API. A reader
  greps the SDL and GL references by those names, and the bare-noun rule of V.3 is for this
  project's own properties;
- lookup tables at module scope stay lowercase `lut_…`, under V.5;
- `nimCameraPivot`, `nimOverlayMetrics`, `nimInkColor` and the scene-listing exports return
  sequences, because something asks them on the UI tick or once, rather than for each frame;
- the FFI-boundary cases of the bridge translate through one `SLOT_NONE` at the return of each
  proc;
- the browser scripts and `shell.html` use snake_case for data bindings and camelCase for
  callables.

The six per-frame overlay exports answer from module flat buffers. `nimDragTint` binds the ink,
and not the colour, because a `lent` bound to a `let` copies. An array literal handed to an
`openArray` parameter is a `new Float32Array` for each call, which is why the fills are templates.

The `pga` library is unmodified by request. There is one substantive deviation. `pga.nim:28`
asserts that its own module doc is the source of truth for names. That is what makes the notation
trap easy to fall into (see Operation notation).

*Checked.* Verified: `koch tree` reports 0 findings. The demotion and the revert were decided by
the compiler, and not by reading. The six per-frame exports allocate nothing, read off the emitted
JS, and the gain is **unmeasured**, an allocation count rather than a millisecond. **Unverified**:
no human has read the result.

## Dependencies and vendoring

**The PGA library is a pinned dependency, and never a copy.** It lives in
[replications][replications], which carries no nimble file and holds the library three directories
inside it. So the requirement in `rga_visualiser.nimble` names the repository by URL and commit.
`atlas.lock` records the resolved commit, and `nim.cfg` names the subdirectory that Atlas restores
it to.

`koch deps` replays that lock, and nothing is committed (Article XI.3). Both projects are under
the Prosperity Public License 3.0.0. It is not a project verb that clones it, because CI runs
`tree`, `deps` and `tests`, and never the own build driver of a project.

**This project tracks the head of pga, and says so when it cannot.** The standing instruction from
the Architect is this. Take the latest pga. Where the latest does not work, pin the most recent
commit that does, record which and why, and move forward when it works again.

Every pull request states which commit of pga it builds against, and whether that is head. The pin
stands at head, `295bafc5e97e8ee94943c6f4c7a92f215a74e5e7`, which costs two things. The
instruction is to pay both rather than trail behind.

**The compiler is pinned by commit, and not by release.** Head spells its operators in prefix and
compound form (`☆m`, `m ∧☆ n`), which needs seven Unicode operator characters that Nim gained in
pull request 26074. That was merged to `devel`, and carried by no release.

The pin is therefore `requires "nim == 27763495bcfe265507ca98aedc1c7064bf1e0e4d"`, which
`toolchain.nim` accepts beside dotted versions, and which koch fetches and builds once for each
machine. It is not a `devel` label, which is a moving pin that records nothing verified. It is not
a wait for a release, which is months of standing behind the library that this project exists to
exercise. The pin moves to a release once one carries 26074. The lexer change reaches the own
source of this project: `-☆(m)` lexes as the single operator `-☆`, and is spelled `-(☆m)`.

**Four projections are withdrawn at head, and `projections.nim` stands in until they return.**
`projectCentral`, `projectCentralAnti`, `projectOrthogonal` and `projectOrthogonalAnti` are
declared `{.error.}` while the library rebuilds them as compound operators (`∨∧★`, `∧∨★`, `∨∧☆`,
`∧∨☆`). This project calls two of them at eight sites, so head alone does not compile here.

Each stand-in is a template that carries the definition which the own operator table of the
library gives. It is copied, and never derived, so nothing about the algebra is invented here
(Article II.8).

The module is a seam. `scene`, `tessellate`, `interaction` and the suite import it instead of
`pga`. `export pga except` those four keeps the names from colliding, and an import of both raises
an ambiguous call rather than answers from the wrong one.

**The guard is what makes this transitional rather than a fork.** A `compiles` probe through a
qualified call reads the own declaration of the library. An `{.error.}` then refuses the build the
day it gains a body, and names the module to delete and the imports to restore.

It is not a hold of the pin one commit back, which leaves the project trailing its own dependency.
It is not a reshape of the call sites, which lets the build state of the library decide what the
visualiser offers.

**Two Atlas defects stand, and the workaround is manual.** `atlas pin` writes `"objects": {}` for
a repository that carries no nimble file, so the resolved commit is patched into `atlas.lock` by
hand. `atlas` also calls the nimble file "broken" because it cannot parse a commit where it
expects a version, which is cosmetic.

The stored nimble of the lock must equal the committed one exactly, or `rep` reverts the pin
silently (repository issue 25). The static pass refuses the difference, so the hand-patch is
checked rather than trusted.

*Checked.* Verified by a run on the pinned commit, through `koch tests`. It ran every suite on the
C backend, on JS, and at reduced capacities, at the same case counts that the previous pin
produced. That is what says the stand-ins behave as the own ones of the library did.

Verified: `deps/` was deleted, `atlas --noexec rep` clones and checks out `295bafc`,
`atlas changed` exits 0, and the nimble file is byte-identical afterwards.

Verified by a run that the guard fires. `pga.nim` patched to give `projectOrthogonal` a body
refuses the build at `projections.nim(40, 10)`, and names the module to delete and the four
imports to restore.

Verified: the pinned compiler reports `git hash: 27763495bcfe265507ca98aedc1c7064bf1e0e4d`, which
`toolchain.runningCompiler` reads. Assumed: that no release carries 26074. 2.2.12, 2.4.0 and 2.6.0
were asked and none does, which dates the claim rather than proves it.

## Testing

One file, `tests/suites.nim`, is run from three thin entry points that `koch` runs through
testament:

| Entry point | Backend | Capacities | Why |
|-------------|---------|-----------|-----|
| `t4d.nim` | C | Default | The desktop build, as shipped |
| `t4d_browser.nim` | JS | Default | The browser build's own backend |
| `t4d_small.nim` | C | 12 objects, 12-char labels, 4 steps | Boundaries a test reaches |

The JS row is not a formality: a rule reached through two mechanisms is held together only where
both run. The reduced row makes any constant tuned to the default fail here, and `LABEL_MAX` at 12
is under several labels that the suite constructs. Cases that need C — `snprintf`, the encoders,
the arena, and save and load — guard themselves with `when not defined(js)`.

A case that walks every pair of handles at 10,000 objects runs ten minutes without output, so the
suite gathers the joiners once instead. The JS entry point declares `targets: "js"`, rather than
overrides the command of testament. So under `koch tests` testament compiles with the JS backend
and runs the result through node. That is what makes the row real rather than a claim that nothing
checks.

**The suites test rules, and a second layer drives events.** A rule bug earns a suite case, and a
wiring bug earns a driven check, at the layer that the bug lived at. That is `tools/drive/` for
the page, and the `--drive-*` runs for the desktop.

A driven check is evidence only for the page just built, so one command rebuilds before it drives
(Article IX.6). A check that leaves state behind taxes every check after it, and says so.
Timing-dependent quantities are asserted as **bands**. Identical code has measured 25.0 and
29.8 ms hours apart on a shared runner. A flat ±1 ms band failed one frame in a hundred and
twenty.

*Checked.* Verified on the pinned commit through `koch tests`: every suite on the C backend, on JS
and at reduced capacities. The JS count is lower because the C-only cases skip themselves.
Verified on the runner as well as locally: the C suites bind zlib for the PNG encoder. Their
passing proves that the runner carries that library. Assumed: nothing about the suite itself.

## Known limitations

- Every result is software-rendered and machine-driven, and the page has run on one Android phone.
- Tab landing on a desktop widget is unverified (see Hold feedback, help and keys).
- Two crossing translucent veils blend order-dependently.
- A camera move is not undoable on its own.
- The residual steps of the comet at fast orbit rates are unexplained (see Selection and markers).
- Neither catalogue is checked against its archive by any tool.
- No tool in this repository measures the palette floors again (see Colour palette).
- The scope check of `koch ci` reads this project's own paths as out of scope where the branch and
  main share two merge bases. The warning of git joins the first path (repository issue 202).
- The frame-time tail on real hardware is undiagnosed, and this container cannot see it.
- The conformal metric (`IS_CONFORMAL`) is unfinished in the library, and this build is rigid 4D.
- `.rgascene` is little-endian by rule, but only a little-endian host has ever written or read
  one. The byte-swapping path is unexercised.
- A page whose WebGL lacks `EXT_frag_depth` keeps linear depth. It keeps the fault of the far
  field with it, and the disc of every plane at the depth of its centre.
- The planet inclinations, ring phases and neighbour planes of the demo are stated
  simplifications.

## Open questions

**The `backdrop-filter` of the drawer costs about 12 ms of every frame at the largest scene.** It
is the whole of what an open drawer costs. It was measured with the drawer open over 5,040
objects: 59 ms for each frame, against 47 ms with the filter forced off. The drawer closed is
47 ms, and the page carries about 860 elements. A scroll of the list at 300 px a frame holds
62 ms, with 0.8 ms of it in the `ui` phase.

The blur is what makes the drawer read as glass over a live 3D view, so it is not plainly the
wrong trade. The figure is recorded so that the question can be asked with it, rather than about
it. Software rendering inflates a blur far more than it inflates the rest, so the share is an
upper bound on hardware. The choices are to keep it, to drop it, or to drop it only while the
frame runs slow.

[replications]: https://gitlab.com/mraxilus/replications
