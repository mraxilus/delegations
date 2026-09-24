discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: false
"""
## Run every suite that needs neither engine nor browser, as one binary.
##
##   Each suite under `joined/` was its own binary, and each paid its own compile of
##     standard library and of whatever it imports.  Nineteen binaries took 62.4 s under
##     testament, measured on this container; this one took 18.5 s, 11.1 s of it compile.
##     Each suite still runs as it did, at import, under its own `suite` name.
##   Debug build, as sixteen of them were: `doAssert` gates of workbench are check
##     (Article IX.6).  `tasks` and `tlimb` were `-d:danger`, which drops bounds, overflow
##     and `assert`; built here they keep all three, which is stricter, and they run in
##     under 1 s either way.
##   Suites that link engine's C archive (`tengine`, `tread`, `trigid`) cannot share this
##     binary, and `tsaid` is compiled to JavaScript, so those stay binaries of their own.

import
  ./joined/[tasks, taxle, tdiagram, tdrawn, tfaces, tframe, tglossary, tlimb, tmap,
            tmarks, tplain, treadme, treview, trotation, troute, tspokes, ttransition,
            twords, tworkbook]
