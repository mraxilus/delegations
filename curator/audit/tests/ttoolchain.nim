discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Replicate per-project pin and driver version rules of CURATOR.md duty 7.

import std/[options, strutils, unittest]
import ../src/toolchain
import ./fixtures


suite "Toolchain":
  test "version is digit runs separated by single dots":
    check isVersion("2.2.4")  # release
    check isVersion("2")  # single part
    check not isVersion("")  # empty
    check not isVersion("2.2.4a")  # letter
    check not isVersion("2..4")  # empty part
    check not isVersion(".2.4")  # leading dot

  test "pin is read only when exact":
    check NIMBLE_TEXT.nimPin == some(PIN)  # fixture pins exactly
    check nimPin("requires \"nim == 2.2.6\"\n") == some("2.2.6")  # spaced
    check nimPin("requires \"nim==2.2.6\"\n") == some("2.2.6")  # unspaced
    check nimPin("requires \"Nim == 2.2.6\"\n") == some("2.2.6")  # case-insensitive
    check nimPin("requires \"nim >= 2.2.4\"\n").isNone  # lower bound is not pin
    check nimPin("requires \"nim\"\n").isNone  # bare name names no version
    check nimPin("requires \"malebolgia\"\n").isNone  # no compiler requirement

  test "project without exact pin is finding, naming what it holds":
    check checkPin("p/p.nimble", NIMBLE_TEXT).len == 0  # exact pin passes
    let found = checkPin("p/p.nimble", "requires \"nim >= 2.2.4\"\n")
    check found.len == 1
    check found[0].path == "p/p.nimble"
    check found[0].message.endsWith("got `nim >= 2.2.4`.")  # Article IV.4 echoes value

  test "driver version is read from workflow, quotes either way":
    check WORKFLOW_TEXT.workflowVersion == some(PIN)  # single quotes
    check workflowVersion("  NIM_VERSION: \"2.2.6\"\n") == some("2.2.6")  # double quotes
    check workflowVersion("  NIM_VERSION: 2.2.6\n") == some("2.2.6")  # bare
    check workflowVersion("name: check\n").isNone  # absent

  test "driver version must equal driver project pin":
    check checkDriver(WORKFLOW_TEXT, PIN).len == 0  # agreement
    check checkDriver(WORKFLOW_TEXT, "2.2.6").len == 1  # drift
    check checkDriver("name: check\n", PIN).len == 1  # unstated
    check checkDriver(WORKFLOW_TEXT, "2.2.6")[0].path == WORKFLOW_PATH  # points at workflow

  test "compiler on path must equal project pin":
    check checkRunning("curator/probe", PIN, PIN).len == 0  # match
    let found = checkRunning("curator/probe", "2.2.6", PIN)
    check found.len == 1
    check found[0].path == "curator/probe"
    check found[0].message.endsWith("got `" & PIN & "`.")  # names compiler actually present
