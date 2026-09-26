discard """
action: run
cmd: "nim c --hints:off -d:testing $options $file"
"""
## Run every suite that needs neither engine nor browser, as one binary (STYLE.md §6).
##
##   Each suite under `suites/` was its own binary, and each paid its own compile of
##     standard library and of whatever it imports.  Nineteen binaries took 62.4 s under
##     testament, measured on this container; this one took 18.5 s, 11.1 s of it compile.
##     Each suite still runs as it did, at import, under its own `suite` name.
##   No `-d:nimUnittestAbortOnError:on`: failing check does not stop run, so every failure
##     of every suite shows in one run.
##   Debug build, since compile is most of cold run and runner keeps no cache.  Cold, on
##     four cores on 2026-09-24, debug took 14.1 s to 16.4 s and `-d:release` 20.8 s.
##     Release keeps `doAssert`, `assert`, bounds and overflow checks too, so this choice
##     is about time alone.  `tasks` and `tlimb` were `-d:danger`, which drops bounds,
##     overflow and `assert`; built here they keep all three.
##   Suites that link engine's C archive (`tengine`, `tread`, `trigid`) cannot share this
##     binary, and `tsaid` is compiled to JavaScript, so those stay binaries of their own.

import
  ./suites/[tasks, taxle, tdiagram, tdrawn, tfaces, tframe, tglossary, tlimb, tmap,
            tmarks, tplain, treadme, treview, trotation, troute, tspokes, ttransition,
            twords, tworkbook]
