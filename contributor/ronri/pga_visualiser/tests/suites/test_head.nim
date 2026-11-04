## Run `Head` suite: one module of shared suite, which `../suites.nim` imports in order.

{.experimental: "strictFuncs".}

import ./fixtures
import ../../tools/head


const
  LOCK = staticRead("../../atlas.lock")  ## Lock as committed, read at compile time.
  NIMBLE = staticRead("../../pga_visualiser.nimble")  ## Nimble file as committed.



suite "Head":
  test "a pin passes where the library's own tree is head's, whatever the repository commit":
    # Library sits inside larger repository, so commit elsewhere moves head and not tree.
    const pin = "3d9696edbaaa5dca655c3024174bd46fd156d7c6"
    check findingHead(pin, "tree1", pin, "tree1") == ""  # pin is head
    check findingHead(pin, "tree1", "ffffffffff", "tree1") == ""  # head moved, library did not
    let lag = findingHead(pin, "tree1", "ffffffffff", "tree2")
    check "Pin lags library head" in lag  # library moved
    check "`fffffff`" in lag and "`3d9696e`" in lag  # both commits named, shortened
    check findingHead(pin, "tree1", "", "").len > 0  # head unread is finding
    check findingHead(pin, "", pin, "").len > 0  # checkout unread is finding, never pass


  test "the pin is the commit the lock names, and the nimble file requires it":
    # Atlas writes lock, and its commit is patched in by hand (PROVENANCE.md, Dependencies
    #   and vendoring), so hand that moves pin is held here to nimble file's requirement.
    let pin = commitPinned(LOCK)
    check pin.len == 40
    check ("replications#" & pin[0..<7] & "\"") in NIMBLE
    check commitPinned("""{"items": {"r": {"dir": "d", "commit": "abc"}}}""") == "abc"
    check commitPinned("""{"items": {}}""") == ""  # lock naming none reads empty
