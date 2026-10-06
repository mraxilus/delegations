## Replicate Article IX.6 for project runner: real testament, real exit codes.

{.experimental: "strictFuncs".}

import std/[os, strutils, tempfiles, unittest]
import ../../src/projects
import ./fixtures


const HEADER = "discard \"\"\"\naction: run\ncmd: \"nim c --hints:off $options $file\"\n\"\"\"\n"
  ## Testament header of fixture tests.



suite "Article IX":
  test "IX.6 processes run in directory and report exit code":
    let root = createTempDir("delegations_", "_run")
    defer: removeDir(root)
    check runIn(root, "true", []) == 0  # success
    check runIn(root, "false", []) == 1  # failure


  test "declared packages are read as lines, and only bare names count":
    # `system` verb's contract is one bare name per line. Only other thing reaching that
    #   stream is compiler complaining, which always spells position before its message, so
    #   line carrying whitespace is dropped rather than installed.
    let root = createTempDir("delegations_", "_lines")
    defer: removeDir(root)
    check linesIn(root, "printf", ["curl\ncoreutils\n"]) == @["curl", "coreutils"]
    check linesIn(root, "printf", ["curl\n\n\ncoreutils\n"]) == @["curl", "coreutils"]
    check linesIn(root, "printf", ["b.nim(3, 5) Warning: x\ncurl\n"]) == @["curl"]
    check linesIn(root, "printf", [""]).len == 0  # verb printing nothing declares nothing
    check linesIn(root, "false", []).len == 0  # verb that failed contributes nothing


  test "IX.6 testament drives each project and reports failures":
    let root = createTempDir("delegations_", "_projects")
    defer: removeDir(root)
    root.writeInto("contributor/ronri/pass/tests/tok.nim", HEADER & "doAssert 1 == 1\n")
    root.writeInto("contributor/ronri/fail/tests/tbad.nim", HEADER & "doAssert 1 == 2\n")
    # Empty `bin` names compiler on PATH, which is what CI already installs per job.
    let
      pass = Target(directory: "contributor/ronri/pass")
      fail = Target(directory: "contributor/ronri/fail")
      found = runTests(root, [pass, fail])
    check found.len == 1  # one finding: passing project clean
    check found[0].path == "contributor/ronri/fail/tests"  # failing named
    check found[0].message.endsWith("got exit `1`.")  # testament exits 1 on failure


  test "IX.6 project's own verb runs through its driver, and its exit becomes finding":
    # `head` stands for every verb koch reaches: driver compiled in project directory, verb
    #   as its one argument, and exit other than 0 named against driver.
    let root = createTempDir("delegations_", "_verb")
    defer: removeDir(root)
    root.writeInto(
      "contributor/ronri/lags/" & FILE_DRIVER,
      "import std/os\n" &
      "case paramStr(1)\n" &
      "of \"" & VERB_HEAD & "\": quit(\"pin `a` lags reference `b`\", 1)\n" &
      "else: quit(2)\n",
    )
    let found = runHead(root, [Target(directory: "contributor/ronri/lags")])
    check found.len == 1  # reference moved
    check found[0].path == "contributor/ronri/lags/" & FILE_DRIVER
    check found[0].message.endsWith("got exit `1`.")  # verb's own code, unchanged
    check runHead(root, newSeq[Target]()).len == 0  # no project carries verb


  test "IX.6 named toolchain is what runs, never whatever PATH holds":
    # Pin resolution hands each project its own compiler; runner must use it rather than
    #   falling back, or two projects on two pins would silently share one.
    check nimOf("") == findExe("nim")  # empty names PATH, as CI installs per job
    check nimOf("/c/2.2.6/bin") == "/c/2.2.6/bin" / "nim"
    check toolOf("/c/2.2.6/bin", "testament") == "/c/2.2.6/bin" / "testament"
    check toolOf("", "atlas") == "atlas"  # bare name, resolved through PATH
    # Absent tool falls back to PATH rather than raising: tools Nim's own `koch` builds move
    #   between versions, and PATH tool still works while announcing its own mismatch.
    check toolIn("/c/2.2.6/bin", "atlas") == "atlas"  # nothing at that path
    check toolIn("", "atlas") == "atlas"


  test "IX.6 toolchain leads child's PATH, since tools resolve each other through it":
    let root = createTempDir("delegations_", "_env")
    defer: removeDir(root)
    # Atlas reads `nim` from PATH rather than from beside itself, so naming binary alone
    #   leaves it reading whatever machine happens to hold.
    let bin = root / "bin"
    createDir(bin)
    writeFile(bin / "sh", "")  # any entry; PATH is read, not this file
    check runIn(root, "sh", ["-c", "case \"$PATH\" in " & bin & ":*) exit 0;; esac; exit 1"],
      bin) == 0  # toolchain leads
    check runIn(root, "sh", ["-c", "test -n \"$PATH\""]) == 0  # empty bin inherits
