# rga_visualiser

An interactive visualiser of rigid geometric algebra: points, lines and planes in a
four-dimensional projective algebra with a rigid (degenerate) metric, and the operations
that join, meet, project and expand them. Pick two objects, apply an operation, and the
object it derives is drawn where the algebra puts it — including at the horizon, where a
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
```

Needs Nim 2.2.6 and git. The `pga` library is restored by Atlas from `atlas.lock` into
`deps/` and is never committed; `nim r koch deps contributor/ronri/rga_visualiser` restores
it alone. The algebra every target builds against — four dimensions, rigid metric — is set
once in `nim.cfg`, so no entry point repeats it.

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
desktop/arena.nim             scratch arena the exporters write through
desktop/image.nim gif.nim     PNG and GIF encoders, for storyboard frames
tests/suites.nim              every law, over one seeded pool of objects
tests/t4d.nim t4d_small.nim   C backend, shipped and small capacities
tests/t4d_browser.nim         JS backend, same suite
deps/                         PGA library, restored by Atlas; never committed
```

## Status

Ported from a working prototype; see `PROVENANCE.md` for what is verified and what is
assumed, and for the open questions this port raised. The two front-ends — the browser page
and the desktop application — are not here yet: they are arriving in follow-up pull
requests, because each carries a file kind this repository does not yet read. Their design
record travels with them.

Every law under test through testament on Nim 2.2.6, in three configurations. Unreviewed by
a human: nothing here has been read line by line, and no human has driven either front-end
or seen it on real graphics hardware.

[replications]: https://gitlab.com/mraxilus/replications
