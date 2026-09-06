discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Replicate nimble requirement reading of `dependencies.nim` header and CONTRIBUTOR.md.

import std/[options, os, strutils, tempfiles, unittest]
import ../src/[projects, dependencies]
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

  test "lock names its checkout directories, deps placeholder resolved":
    check LOCK_TEXT.lockDirs == @["deps/replications.example.invalid"]  # one item
    check lockDirs("{}").len == 0  # no items table
    check lockDirs("{\"items\": {}}").len == 0  # empty items

  test "checkout absent after restore is finding":
    # Regression: `atlas changed` exits 0 while warning `repo missing!`, so restore that
    #   fetched nothing reported success (Atlas 0.9.0, measured 2026-09-06).
    let root = createTempDir("delegations_", "_lock")
    defer: removeDir(root)
    root.writeInto("curator/probe/atlas.lock", LOCK_TEXT)
    check checkCheckouts(root, "curator/probe").len == 1  # directory absent
    createDir(root / "curator/probe/deps/replications.example.invalid")
    check checkCheckouts(root, "curator/probe").len == 0  # directory present

  test "unreadable lock is finding, never crash":
    let root = createTempDir("delegations_", "_lock")
    defer: removeDir(root)
    root.writeInto("curator/probe/atlas.lock", "not json at all")
    check checkCheckouts(root, "curator/probe").len == 1

  test "projects without lock file need no atlas":
    let root = createTempDir("delegations_", "_deps")
    defer: removeDir(root)
    root.writeInto("curator/probe/probe.nimble", NIMBLE_TEXT)
    # Empty `bin` names PATH; project without lock runs no atlas either way.
    check restoreAll(root, [Target(dir: "curator/probe")]).len == 0

  test "lock stores copy of nimble, read back whole":
    check lockNimble(lockWith(NIMBLE_TEXT)) == some(NIMBLE_TEXT)  # round trip
    check lockNimble(LOCK_TEXT).isNone  # lock storing no copy names none

  test "stored nimble differing from committed one is finding, naming line about to be lost":
    # Regression: `atlas rep` writes lock's copy back over nimble file, so pin edited without
    #   regenerating lock is reverted silently; failure then surfaces as later finding on file
    #   contributor never touched (reported by contributor/ronri/rga_visualiser, issue 25).
    let stale = NIMBLE_TEXT.replace("nim == " & PIN, "nim >= " & PIN)
    let found = checkLockNimble("p/p.nimble", "p/atlas.lock", lockWith(stale), NIMBLE_TEXT)
    check found.len == 1
    check found[0].path == "p/p.nimble"  # file about to be overwritten, never lock
    check found[0].line == 6  # `requires` line of fixture
    check found[0].message.endsWith("got `requires \"nim == " & PIN & "\"`.")

  test "stored nimble matching committed one is clean, and absent copy compares nothing":
    let (nimble_path, lock_path) = ("p/p.nimble", "p/atlas.lock")
    check checkLockNimble(nimble_path, lock_path, lockWith(NIMBLE_TEXT), NIMBLE_TEXT).len == 0
    check checkLockNimble(nimble_path, lock_path, LOCK_TEXT, NIMBLE_TEXT).len == 0  # cost
    # Drift beyond pin is caught too, since lock stores whole file.
    let extra = NIMBLE_TEXT & "requires \"malebolgia\"\n"
    check checkLockNimble(nimble_path, lock_path, lockWith(NIMBLE_TEXT), extra).len == 1

  test "unreadable lock is finding in static pass, not only at restore":
    let found = checkLockNimble("p/p.nimble", "p/atlas.lock", "not json at all", NIMBLE_TEXT)
    check found.len == 1
    check found[0].path == "p/atlas.lock"  # fault is lock's, so finding points there
