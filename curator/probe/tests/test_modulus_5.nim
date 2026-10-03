discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
matrix: "-d:probe.modulus=5"
"""
## Run shared suite on ring of five steps.

{.experimental: "strictFuncs".}

include "suites.nim"
