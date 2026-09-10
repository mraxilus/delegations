# rga_visualiser

An interactive visualiser of rigid geometric algebra: points, lines and planes in a
four-dimensional projective algebra with a rigid (degenerate) metric, and the operations
that join, meet, project and expand them. Pick two objects, apply an operation, and the
object it derives is drawn where the algebra puts it — including in the horizon, where a
line's attitude and a plane's direction live.

It is a testbed rather than a replication. The algebra itself is the `pga` library, derived
from Eric Lengyel's *Projective Geometric Algebra Illuminated* and developed in
[replications][replications]; this project depends on that library and never reimplements
it (Article II.8). What is replicated here is nothing: the visualiser exists to make the
library's objects visible and its operations checkable by eye.

The same geometry code compiles to two front-ends — a desktop application and a browser
page — so that a rule stated once is reached through two mechanisms rather than asked to
agree with itself.

## Authority replicated

None directly. The `pga` library it depends on replicates Lengyel's book; this project
replicates no published source and derives no algebra of its own.

## Build and test

```sh
nim r koch ci                                    # repository root: audit, scope, commits
nim r koch tests contributor/ronri/rga_visualiser  # this project alone, three configurations
nim r tools/build.nim assets                     # this project: fetch the ten faces, once
nim r tools/build.nim web                        # this project: build/rga_visualiser.html
nim r tools/build.nim drive                      # this project: drive both front-ends
nim r tools/build.nim desktop                    # this project: bin/rga_visualiser
nim r tools/build.nim driven                     # this project: drive the desktop alone
nim r tools/build.nim system                     # this project: what to install first
```

Needs **Nim built from commit `27763495b`** on `PATH`, and git. No release will do: the
`pga` library spells its operators with seven characters Nim learned to lex in that commit,
and no release carries it yet. Build it with `git clone https://github.com/nim-lang/Nim &&
git checkout 27763495b && sh build_all.sh`; CI does the same and caches the result per
commit. The pin is exact and the audit enforces it: running the suites on any other compiler
is a finding, not a warning.

System packages are declared in `tools/build.nim` and printed by its `system` verb, so this
README names no list that could drift from the one the build reads (issue 60):

```sh
nim r tools/build.nim system | xargs sudo apt-get install -y
```

The browser front-end needs nothing beyond that compiler and Node. The **desktop** front-end
links against SDL3, OpenGL and zlib, and its headless runs need Xvfb and a software GL.

Two of its dependencies arrive as no package, so the build fetches both itself and refuses
either when its pin misses. **SDL3** has no `libsdl3-dev` on Ubuntu 24.04 — that release carries
SDL2 only — so `desktop` clones `release-3.2.30` into `deps/sdl3` and builds it into
`build/sdl3`, a prefix inside the tree that needs no root. **Dear ImGui** is compiled from source
into the binary rather than linked, and is cloned to `deps/imgui` at its pinned commit. Both are
kept locally and never committed, as the Atlas checkouts are.

Nothing has to be run by hand for either. Where a machine already carries SDL3 at the pinned
version, that one is used and nothing is built:

```sh
nim r tools/build.nim desktop
```

The `pga` library is restored by Atlas from `atlas.lock` into `deps/` and is never committed;
`nim r koch deps contributor/ronri/rga_visualiser` restores it alone. It is pinned at
`295bafc`, which is that library's head. Four projection operations are withdrawn at head
while the library rebuilds them, and `src/rga_visualiser/projections.nim` stands in for them
until they return — see Dependencies / Vendoring in `PROVENANCE.md`. The algebra every target
builds against — four dimensions, rigid metric — is set once in `nim.cfg`, so no entry point
repeats it.

The browser page is assembled by `tools/build.nim`, which compiles the bridge through the
JS backend, type-checks and emits the TypeScript glue, inlines the six font faces, and folds
all of it into one self-contained `build/rga_visualiser.html` that opens from `file://`.
That needs Node and npm alongside Nim: `npm ci` restores the two pinned dev dependencies
into `node_modules/`, which is never committed. `assets` fetches every face both front-ends
draw with — six `woff2` the page embeds and four TrueType the desktop binary loads — each
pinned by version and SHA-256, and needs the network once.

Tests run as three configurations of one shared suite: `t4d` at shipped capacities on the C
backend, `t4d_small` at capacities small enough that the suite's tests reach them, and
`t4d_browser` on the JS backend, which is the one that holds the two backends' formatting
to the same rule.

## Layout

```
src/rga_visualiser.nim        umbrella: bootstrap order, re-exports
src/rga_visualiser/           geometry and model, reachable from either front-end:
                              objects, euclid, boundary, mesh, tessellate, camera,
                              scene, selection, picking, marker, framing, interaction,
                              storyboard, orrery, neighbourhood, starfield, history,
                              format, help, timings, ramp, lighting
src/…/projections.nim         projections pga withdrew; deleted when they return
src/desktop/main.nim          desktop entry point: window, event loop, headless runs
src/desktop/sdl3.nim opengl.nim  bindings to the window system and to GL
src/desktop/gui.nim gui_shim.cpp  facade over Dear ImGui, and the C++ it needs
src/desktop/renderer.nim      the GL renderer: one program per record kind
src/desktop/panel.nim         the panel the reader edits scene and camera through
src/desktop/arena.nim         scratch arena the exporters write through
src/desktop/image.nim gif.nim PNG and GIF encoders, for storyboard frames
src/browser/bridge.nim        every value the page draws, compiled through the JS backend
src/browser/*.ts              DOM, WebGL and event wiring alone; gated file kind
pages/shell.html              committed markup, with tokens the build fills
tools/build.nim               the build driver: declare, types, web, drive, desktop,
                              assets, system, clean
tools/drive/                  the Playwright harness the drive verb runs
tests/suites.nim              every law, over one seeded pool of objects
tests/t4d.nim t4d_small.nim   C backend, shipped and small capacities
tests/t4d_browser.nim         JS backend, same suite
deps/                         PGA library, restored by Atlas; never committed
```

## Status

Ported from a working prototype; see `PROVENANCE.md` for what is verified and what is
assumed, and for the open questions this port raised. Both front-ends are here and build:
the browser page through `web`, the desktop application through `desktop`.

Every law under test through testament on the pinned commit, in three configurations. The
page has been built and looked at, its type surface is checked, and a Playwright harness
drives 139 checks over held keys, the wheel, mouse pan and touch — see Driven Checks in
`PROVENANCE.md`. The desktop application has been built, one frame of it looked at, and its own
thirteen scripted runs driven headless under Xvfb — 22 checks, all passing, one of them driven
with no face installed at all. SDL3 arrives as a source build rather than a package, and `drive`
fetches and builds it rather than skipping the runs that need it.

Unreviewed by a human: nothing here has been
read line by line, and no human has driven either front-end or seen it on real graphics
hardware.

[replications]: https://gitlab.com/mraxilus/replications
