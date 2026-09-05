discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Replicate Article IX.6 for project runner: real make, real exit codes.

import std/[os, strutils, tempfiles, unittest]
import ../src/projects
import ./fixtures


suite "Article IX":
  test "IX.6 make check drives each project and reports failures":
    let root = createTempDir("delegations_", "_projects")
    defer: removeDir(root)
    root.writeInto("ronri/pass/Makefile", "check:\n\t@true\n")
    root.writeInto("ronri/fail/Makefile", "check:\n\t@exit 3\n")
    check runProjects(root, ["ronri/pass"]).len == 0  # exit 0 is clean
    let found = runProjects(root, ["ronri/pass", "ronri/fail"])
    check found.len == 1 and found[0].path == "ronri/fail/Makefile"  # failing project named
    check found[0].message.endsWith("got exit `2`.")  # make reports 2 for recipe failure
