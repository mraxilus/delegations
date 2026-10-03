discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
matrix: "-d:probe.modulus=4"
"""
## Run shared suite on ring of four steps.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

include "suites.nim"
