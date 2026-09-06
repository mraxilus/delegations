discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Replicate Article IX.6 for project runner: real testament, real exit codes.

import std/[os, strutils, tempfiles, unittest]
import ../src/projects
import ./fixtures


const HEADER = "discard \"\"\"\naction: run\ncmd: \"nim c --hints:off $options $file\"\n\"\"\"\n"
  ## Testament header of fixture tests.


suite "Article IX":
  test "IX.6 processes run in directory and report exit code":
    let root = createTempDir("delegations_", "_run")
    defer: removeDir(root)
    check runIn(root, "true", []) == 0  # success
    check runIn(root, "false", []) == 1  # failure

  test "IX.6 testament drives each project and reports failures":
    let root = createTempDir("delegations_", "_projects")
    defer: removeDir(root)
    root.writeInto("contributor/ronri/pass/tests/tok.nim", HEADER & "doAssert 1 == 1\n")
    root.writeInto("contributor/ronri/fail/tests/tbad.nim", HEADER & "doAssert 1 == 2\n")
    # Empty `bin` names compiler on PATH, which is what CI already installs per job.
    let pass = Target(dir: "contributor/ronri/pass")
    let fail = Target(dir: "contributor/ronri/fail")
    check runTests(root, [pass]).len == 0  # passing project is clean
    let found = runTests(root, [pass, fail])
    check found.len == 1 and found[0].path == "contributor/ronri/fail/tests"  # failing named
    check found[0].message.endsWith("got exit `1`.")  # testament exits 1 on failure

  test "IX.6 named toolchain is what runs, never whatever PATH holds":
    # Pin resolution hands each project its own compiler; runner must use it rather than
    #   falling back, or two projects on two pins would silently share one.
    check nimOf("") == findExe("nim")  # empty names PATH, as CI installs per job
    check nimOf("/c/2.2.6/bin") == "/c/2.2.6/bin" / "nim"
    check toolOf("/c/2.2.6/bin", "testament") == "/c/2.2.6/bin" / "testament"
    check toolOf("", "atlas") == "atlas"  # bare name, resolved through PATH
    # Absent tool falls back to PATH rather than raising: `koch tools` set moves between
    #   versions, and PATH tool still works while announcing its own mismatch.
    check toolIn("/c/2.2.6/bin", "atlas") == "atlas"  # nothing at that path
    check toolIn("", "atlas") == "atlas"
