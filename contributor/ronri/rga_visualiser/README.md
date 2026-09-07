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
nim r tools/build.nim assets                     # this project: fetch the six faces, once
nim r tools/build.nim web                        # this project: build/rga_visualiser.html
nim r tools/build.nim drive                      # this project: build it, then drive it
```

Needs **Nim built from commit `27763495b`** on `PATH`, and git. No release will do: the
`pga` library spells its operators with seven characters Nim learned to lex in that commit,
and no release carries it yet. Build it with `git clone https://github.com/nim-lang/Nim &&
git checkout 27763495b && sh build_all.sh`; CI does the same and caches the result per
commit. The pin is exact and the audit enforces it: running the suites on any other compiler
is a finding, not a warning.

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
into `node_modules/`, which is never committed. `assets` fetches the faces the page embeds,
and needs the network once.

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
src/desktop/arena.nim         scratch arena the exporters write through
src/desktop/image.nim gif.nim PNG and GIF encoders, for storyboard frames
src/browser/bridge.nim        every value the page draws, compiled through the JS backend
src/browser/*.ts              DOM, WebGL and event wiring alone; gated file kind
pages/shell.html              committed markup, with tokens the build fills
tools/build.nim               the page's build driver: declare, web, assets, clean
tests/suites.nim              every law, over one seeded pool of objects
tests/t4d.nim t4d_small.nim   C backend, shipped and small capacities
tests/t4d_browser.nim         JS backend, same suite
deps/                         PGA library, restored by Atlas; never committed
```

## Status

Ported from a working prototype; see `PROVENANCE.md` for what is verified and what is
assumed, and for the open questions this port raised. The browser page is here and builds;
the desktop application is not, and arrives in a follow-up pull request. Its design record
travels with it.

Every law under test through testament on the pinned commit, in three configurations. The
page has been built and looked at, its type surface is checked, and a Playwright harness
drives seventeen checks over held keys, the wheel, mouse pan and touch. Drag, undo, save
and load remain untested and frame times unmeasured; no runner job reaches the harness,
so those checks are run by hand — see Driven Checks in `PROVENANCE.md`.

Unreviewed by a human: nothing here has been
read line by line, and no human has driven either front-end or seen it on real graphics
hardware.

[replications]: https://gitlab.com/mraxilus/replications
