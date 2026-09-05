discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Replicate nimble requirement reading of `dependencies.nim` header and CONTRIBUTOR.md.

import std/[os, tempfiles, unittest]
import ../src/dependencies
import ./fixtures


suite "Dependencies":
  test "package name ends at version, hash or space":
    check packageName("malebolgia") == "malebolgia"  # bare
    check packageName("malebolgia >= 1.0") == "malebolgia"  # version
    check packageName("pkg#head") == "pkg"  # hash
    check packageName("https://github.com/x/y@1.0") == "https://github.com/x/y"  # url at tag

  test "requirements skip nim and read every literal on requires lines":
    check requirements(NIMBLE_TEXT).len == 0  # nim only
    check requirements("requires \"Nim >= 2.0\"\n").len == 0  # case-insensitive
    check requirements("requires \"malebolgia\", \"sunny >= 1\"\n") ==
      @["malebolgia", "sunny >= 1"]  # several literals
    check requirements("version = \"1\"\nrequires \"a\"  # note\n") == @["a"]  # comment after
    check requirements("when defined(windows):\n  requires \"winim\"\n") == @["winim"]  # cost

  test "projects without lock file need no atlas":
    let root = createTempDir("delegations_", "_deps")
    defer: removeDir(root)
    root.writeInto("curator/probe/probe.nimble", NIMBLE_TEXT)
    check restoreAll(root, ["curator/probe"]).len == 0  # nothing run, nothing found
