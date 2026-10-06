## Replicate per-project pin and driver version rules of CURATOR.md duty 8.

{.experimental: "strictFuncs".}

import std/[options, strutils, unittest]
import ../../src/toolchain
import ./fixtures


const OTHER_PATH = ".github/workflows/role.yml"
  ## Second workflow installing compiler; driver's own is `WORKFLOW_PATH`.



suite "Toolchain":
  test "project without exact pin is finding, naming what it holds":
    check checkPin("p/p.nimble", TEXT_NIMBLE).len == 0  # exact pin passes
    let found = checkPin("p/p.nimble", "requires \"nim >= 2.2.4\"\n")
    check found.len == 1
    check found[0].path == "p/p.nimble"
    check found[0].message.endsWith("got `nim >= 2.2.4`.")  # Article IV.4 echoes value


  test "pin is written `nim == <pin>` alone, though knoller reads `nim#<commit>` too":
    check checkPin("p/p.nimble", "requires \"nim == " & COMMIT & "\"\n").len == 0  # duty 8
    let found = checkPin("p/p.nimble", "requires \"nim#" & COMMIT & "\"\n")
    check found.len == 1  # one form, which `.claude/hooks.sh` reads as text
    check found[0].message.endsWith("got `nim#" & COMMIT & "`.")
    check checkPin("p/p.nimble", "requires \"Nim#" & COMMIT & "\"\n").len == 1  # any case


  test "driver version is read from workflow, quotes either way":
    check WORKFLOW_TEXT.workflowVersion == some(PIN)  # single quotes
    check workflowVersion("  NIM_VERSION: \"2.2.6\"\n") == some("2.2.6")  # double quotes
    check workflowVersion("  NIM_VERSION: 2.2.6\n") == some("2.2.6")  # bare
    check workflowVersion("name: check\n").isNone  # absent


  test "driver pins version, never commit":
    let found = checkDriver(WORKFLOW_PATH, WORKFLOW_TEXT, COMMIT)
    check found.len == 1  # setup action installs releases; every job waits on driver
    check found[0].message.endsWith("got `" & COMMIT & "`.")
    check checkDriver(OTHER_PATH, WORKFLOW_TEXT, COMMIT).len == 0  # named once, not per file


  test "every workflow stating version must equal driver project pin":
    for path in [WORKFLOW_PATH, OTHER_PATH]:  # driver's own, and second installing compiler
      check checkDriver(path, WORKFLOW_TEXT, PIN).len == 0  # agreement
      let drifted = checkDriver(path, WORKFLOW_TEXT, "2.2.6")
      check drifted.len == 1  # drift
      check drifted[0].path == path  # points at file that drifted
    # Absent key: driver's own must state version; workflow installing no compiler states none.
    check checkDriver(WORKFLOW_PATH, "name: check\n", PIN).len == 1  # unstated
    check checkDriver(OTHER_PATH, "name: role\n", PIN).len == 0  # left alone


  test "knoller pins driver version, since koch compiles it":
    const path = KNOLLER_DIRECTORY & "/knoller.nimble"
    check checkKnoller(path, some(PIN), some(PIN)).len == 0  # agreement
    let drifted = checkKnoller(path, some("2.2.6"), some(PIN))
    check drifted.len == 1  # drift
    check drifted[0].path == path  # points at knoller's nimble file
    check drifted[0].message.endsWith("got `2.2.6`.")  # Article IV.4 echoes value
    check checkKnoller(path, none(string), some(PIN)).len == 0  # absent is layout's finding
    check checkKnoller(path, some(PIN), none(string)).len == 0  # driver unpinned, same
