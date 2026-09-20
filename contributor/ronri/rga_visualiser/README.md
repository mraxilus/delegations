# rga_visualiser

An interactive visualiser of rigid geometric algebra. It holds points, lines and planes in a
four-dimensional projective algebra with a rigid, degenerate metric. It holds the operations that
join, meet, project and expand them. Pick two objects and apply an operation, and the object it
derives is drawn where the algebra puts it. That includes the horizon, where the attitude of a line
and the direction of a plane live.

It is a testbed rather than a replication. The algebra itself is the `pga` library, derived from
*Projective Geometric Algebra Illuminated* by Eric Lengyel, and developed in
[replications][replications]. This project depends on that library, and never reimplements it
(Article II.8). Nothing is replicated here. The visualiser exists to make the objects of the
library visible, and its operations checkable by eye.

The same geometry code compiles to two front-ends: a desktop application and a browser page. A rule
stated once is then reached through two mechanisms, rather than asked to agree with itself.

## Authority replicated

None directly. The `pga` library that it depends on replicates the book of Lengyel. This project
replicates no published source, and derives no algebra of its own.

## Build and test

```sh
nim r koch ci                                    # repository root: every check but deps, scoped
nim r koch tests contributor/ronri/rga_visualiser  # this project alone, three configurations
nim r tools/build.nim assets                     # this project: fetch every face, once
nim r tools/build.nim web                        # this project: build/rga_visualiser.html
nim r tools/build.nim drive                      # this project: drive both front-ends
nim r tools/build.nim desktop                    # this project: bin/rga_visualiser
nim r tools/build.nim driven                     # this project: drive the desktop alone
nim r tools/build.nim system                     # this project: what to install first
```

It builds on **Nim at commit `27763495b`**, and nothing has to be installed for it. Koch resolves
the pin itself. It takes the compiler on `PATH` where that one already serves. Else it takes one
cached under `~/.cache/koch/nim/<pin>/`, or a clone of `nim-lang/Nim` built at that commit and
cached. That is paid once for each machine (`GUIDE.md`, Toolchain). CI resolves the same pin the
same way.

No release will do. The `pga` library spells its operators with seven characters that Nim learned to
lex in that commit, and no release carries it yet. The pin is exact. A pin that nothing can serve is
a finding, which names the pin and the cache tried, and never a fallback to another compiler.

System packages are declared in `tools/build.nim`, and printed by its `system` verb. So this README
names no list that could drift from the one the build reads (issue 60):

```sh
nim r tools/build.nim system | xargs sudo apt-get install -y
```

The browser front-end needs nothing beyond that compiler and Node. The **desktop** front-end links
against SDL3, OpenGL and zlib. Its headless runs need Xvfb and a software GL.

Two of its dependencies arrive as no package. So the build fetches both itself, and refuses either
one when its pin misses.

**SDL3** has no `libsdl3-dev` on Ubuntu 24.04, because that release carries SDL2 only. So `desktop`
clones `release-3.2.30` into `deps/sdl3`, and holds it at the commit that the tag names. It builds
it into `build/sdl3`, which is a prefix inside the tree that needs no root.

**Dear ImGui** is compiled from source into the binary, rather than linked. It is cloned to
`deps/imgui` at its pinned commit. Both are held at a commit rather than at a name that could move.
Both are kept locally and never committed, as the Atlas checkouts are.

Nothing has to be run by hand for either one. Where a machine already carries SDL3 at the pinned
version, that one is used and nothing is built:

```sh
nim r tools/build.nim desktop
```

Atlas restores the `pga` library from `atlas.lock` into `deps/`, and it is never committed.
`nim r koch deps contributor/ronri/rga_visualiser` restores it alone. It is pinned at `295bafc`,
which is the head of that library.

Four projection operations are withdrawn at head while the library rebuilds them.
`src/rga_visualiser/projections.nim` stands in for them until they return. See Dependencies and
vendoring in `PROVENANCE.md`. The algebra that every target builds against is four dimensions with a
rigid metric. It is set once in `nim.cfg`, so no entry point repeats it.

`tools/build.nim` assembles the browser page. It compiles the bridge through the JS backend,
type-checks and emits the TypeScript glue, and inlines the font faces. It folds all of it into one
self-contained `build/rga_visualiser.html` that opens from `file://`.

That needs Node and npm alongside Nim. `npm ci` restores the pinned dev dependencies into
`node_modules/`, which is never committed.

`assets` copies every face that the two front-ends draw with out of the shared asset store of the
repository. Those are the faces the page embeds, and the faces the desktop binary loads.
`koch assets` fills that store, and checks it against `curator/audit/src/assets.nim`. Which faces
this project wants is in `tools/build.nim`, and what bytes each one is belongs to the store.

Both front-ends draw three roles from three families. **Noto Serif** takes titles, **Noto Sans**
takes body and controls, and **Commit Mono** takes code and any text whose columns carry meaning.

Two Noto faces supply the operators and symbols that neither of the other two carries. They are
merged by unicode-range in the page, and into one atlas on the desktop.

Commit Mono splits its ligatures. Most ride on `calt` and draw unasked. The arrows and comparisons
come from `ss01` and `ss02`, which the page asks for by name. The desktop draws none of them,
because Dear ImGui shapes no text. See Type roles in `PROVENANCE.md`.

Tests run as three configurations of one shared suite. `t4d` runs at shipped capacities on the C
backend. `t4d_small` runs at capacities small enough that the tests of the suite reach them.
`t4d_browser` runs on the JS backend, and it is the one that holds the formatting of the two
backends to the same rule.

## Layout

```
src/rga_visualiser.nim        umbrella: bootstrap order, re-exports
src/rga_visualiser/           geometry and model, reachable from either front-end:
                              objects, euclid, boundary, mesh, tessellate, camera,
                              scene, selection, picking, marker, framing, interaction,
                              storyboard, orrery, neighbourhood, starfield, history,
                              format, help, message, wording, timings, ramp
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

## Published

The browser front-end is published, so it can be opened rather than rebuilt. Publish it again from
`build/rga_visualiser.html` after any change that alters what the page shows. Put the URL in the
pull request, and in the message that says the work is ready.

| built file, under `build/` | published at |
| --- | --- |
| rga_visualiser.html | https://claude.ai/code/artifact/a523f27b-d74e-4987-9b6e-7b1680e469a6 |

The URL is written here because it was written nowhere. The page existed, and three changes to it
merged without a republish, because nobody who read this repository could find where it was
published.

The desktop front-end has no entry. It is a binary, and Article XI.3 keeps binaries out of the tree,
so it is shown as a screenshot instead.

## Status

Ported from a working prototype. See `PROVENANCE.md` for what is verified and what is assumed, and
for the open questions this port raised. Both front-ends are here and build: the browser page
through `web`, and the desktop application through `desktop`.

Every law is under test through testament, on the pinned commit, in three configurations.

The page has been built and looked at, and its type surface is checked. A Playwright harness drives
its checks over held keys, the wheel, mouse pan and touch. See Driven checks in `PROVENANCE.md`.

The desktop application has been built, and one frame of it looked at. Its own scripted runs are
driven headless under Xvfb, and all pass. One of them is driven with no face installed at all, and
one with the scene filled to capacity. SDL3 arrives as a source build rather than a package, and
`drive` fetches and builds it rather than skips the runs that need it.

Unreviewed by a human. Nothing here has been read line by line. No human has driven either
front-end, or seen it on real graphics hardware.

[replications]: https://gitlab.com/mraxilus/replications
