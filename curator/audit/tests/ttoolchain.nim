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

  test "commit is forty lowercase hex, and nothing else":
    check isCommit("295bafc0d7e9a0c9a3ba0d9b39b5b0b6a4c1d2e3")  # forty hex
    check not isCommit("295bafc")  # short
    check not isCommit("295BAFC0D7E9A0C9A3BA0D9B39B5B0B6A4C1D2E3")  # uppercase
    check not isCommit("295bafc0d7e9a0c9a3ba0d9b39b5b0b6a4c1d2eg")  # not hex
    check not isCommit("2.2.4")  # version
    check isPin("2.2.4") and isPin("295bafc0d7e9a0c9a3ba0d9b39b5b0b6a4c1d2e3")
    check not isPin("devel")  # moving target records nothing

  test "pin is read only when exact":
    check NIMBLE_TEXT.nimPin == some(PIN)  # fixture pins exactly
    check nimPin("requires \"nim == 2.2.6\"\n") == some("2.2.6")  # spaced
    check nimPin("requires \"nim==2.2.6\"\n") == some("2.2.6")  # unspaced
    check nimPin("requires \"Nim == 2.2.6\"\n") == some("2.2.6")  # case-insensitive
    check nimPin("requires \"nim >= 2.2.4\"\n").isNone  # lower bound is not pin
    check nimPin("requires \"nim\"\n").isNone  # bare name names no version
    check nimPin("requires \"malebolgia\"\n").isNone  # no compiler requirement
    check nimPin("requires \"nim == 295bafc0d7e9a0c9a3ba0d9b39b5b0b6a4c1d2e3\"\n") ==
      some("295bafc0d7e9a0c9a3ba0d9b39b5b0b6a4c1d2e3")  # commit, for devel dependency
    check nimPin("requires \"nim == devel\"\n").isNone  # label, not pin

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

  test "driver pins version, never commit":
    let commit = "295bafc0d7e9a0c9a3ba0d9b39b5b0b6a4c1d2e3"
    let found = checkDriver(WORKFLOW_TEXT, commit)
    check found.len == 1  # setup action installs releases; every job waits on driver
    check found[0].message.endsWith("got `" & commit & "`.")

  test "driver version must equal driver project pin":
    check checkDriver(WORKFLOW_TEXT, PIN).len == 0  # agreement
    check checkDriver(WORKFLOW_TEXT, "2.2.6").len == 1  # drift
    check checkDriver("name: check\n", PIN).len == 1  # unstated
    check checkDriver(WORKFLOW_TEXT, "2.2.6")[0].path == WORKFLOW_PATH  # points at workflow


  test "pin is served by commit for commit, by version otherwise":
    # Replaces `checkRunning`, which resolution retired: nothing called it once each pin got
    #   its own toolchain, and rule with no caller enforces nothing.
    let commit = "295bafc0d7e9a0c9a3ba0d9b39b5b0b6a4c1d2e3"
    let running = Compiler(version: PIN, commit: commit)
    check PIN.serves(running)  # version pin reads version
    check commit.serves(running)  # commit pin reads hash
    check not "2.2.6".serves(running)  # another version does not
    check not commit.serves(Compiler(version: PIN))  # compiler reporting no hash serves none
