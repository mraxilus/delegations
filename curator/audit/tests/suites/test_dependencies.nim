## Replicate nimble requirement reading of `dependencies.nim` header and CONTRIBUTOR.md.

{.experimental: "strictFuncs".}

import std/[json, options, os, sequtils, strutils, tempfiles, unittest]
import ../../src/[dependencies, findings, projects]
import ./fixtures


const
  LOCK = "curator/assayer/atlas.lock"  ## Lock of #947, which names knoller.
  COMMIT_LACKED = "0123456789abcdef0123456789abcdef01234567"
    ## Commit lock of #947 named, which clone of knoller lacked.
  COMMIT_FOUND = "c5670c44cd00b01f709da5bb05530b8042828c7c"
    ## Commit checkout of #947 stayed at, which `atlas changed` found.


func textLock(name, commit: string): string =
  ## Render lock naming one checkout under `$deps`, at commit, as Atlas writes its item.
  pretty(%*{"items": {name: {"dir": "$deps/" & name, "commit": commit}}}) & "\n"



suite "Dependencies":
  test "requirements skip nim and read every literal on requires lines":
    check requirements(TEXT_NIMBLE).len == 0  # nim only
    check requirements("requires \"Nim >= 2.0\"\n").len == 0  # case-insensitive
    check requirements("requires \"malebolgia\", \"sunny >= 1\"\n") ==
      @["malebolgia", "sunny >= 1"]  # several literals
    check requirements("version = \"1\"\nrequires \"a\"  # note\n") == @["a"]  # comment after
    check requirements("when defined(windows):\n  requires \"winim\"\n") == @["winim"]  # cost


  test "lock names its checkouts, each at its commit, deps placeholder resolved":
    check TEXT_LOCK.checkoutsLock == @[Checkout(
      name: "replications.example.invalid",
      directory: "deps/replications.example.invalid",
      commit: "0123456789abcdef",
    )]  # one item
    check checkoutsLock("{}").len == 0  # no items table
    check checkoutsLock("{\"items\": {}}").len == 0  # empty items
    check TEXT_LOCK.checkoutsLock("dependencies").mapIt(it.directory) ==
      @["dependencies/replications.example.invalid"]
    check checkoutsLock("{\"items\": {\"a\": {\"dir\": \"$deps/a\"}}}").mapIt(it.commit) ==
      @[""]  # item naming no commit reads empty, so each commit found differs
    check directoryDeps("{\"deps\": \"dependencies\"}") == "dependencies"  # V.9 name
    check directoryDeps("{\"deps\": \"\"}") == "deps"  # empty name takes default
    check directoryDeps("{}") == "deps"  # no key takes default


  test "checkout absent after restore is finding, and only finding of its item":
    # `atlas changed` exits 0 while warning `repo missing!`, so restore fetching nothing
    #   reports success. Measured on Atlas 0.9.0, 2026-09-06, and on 0.14.7, 2026-11-16.
    #   Absent checkout reads no commit, so its item gives no second finding.
    let root = createTempDir("delegations_", "_lock")
    defer: removeDir(root)
    root.writeInto("curator/probe/atlas.lock", TEXT_LOCK)
    check checkCheckouts(root, "curator/probe").mapIt(it.brief) ==
      @["checkout absent after restore; got `deps/replications.example.invalid`"]  # absent, once
    check checkCheckouts(root, "curator/probe").anyIt(it.rule == "koch.missing-checkout")
    let checkout = root / "curator/probe/deps/replications.example.invalid"
    createDir(checkout.parentDir)
    moveDir(repoTemp(), checkout)
    root.writeInto(
      "curator/probe/atlas.lock",
      textLock("replications.example.invalid", checkout.git("rev-parse HEAD").strip),
    )
    check checkCheckouts(root, "curator/probe").len == 0  # present, at commit of lock


  test "checkout at other commit than lock holds is finding, naming lock, item and both commits":
    # Case as found (#947): lock of assayer named commit that clone of knoller lacked, so `rep`
    #   left checkout at its own commit, and `atlas changed` exited 0 while it warned that
    #   commit differs (Atlas 0.14.7, 2026-11-16). `koch fetch-deps curator/assayer` gave no
    #   finding. Domain: checkout at other commit, at commit of lock, and at none git reads.
    let knoller = Checkout(
      name: "knoller", directory: "dependencies/knoller", commit: COMMIT_LACKED
    )
    check checkCommitCheckout(LOCK, knoller, some(COMMIT_FOUND)).mapIt(
      (it.path, it.line, it.brief)
    ) == @[(
      LOCK,
      0,
      "checkout of `knoller` stands at other commit than lock holds after restore; got `" &
        COMMIT_FOUND & "`; expect `" & COMMIT_LACKED & "`",
    )]  # case as found, both commits named
    check checkCommitCheckout(LOCK, knoller, some(COMMIT_LACKED)).len == 0  # at commit of lock
    check checkCommitCheckout(LOCK, knoller, none(string)).mapIt(it.brief) ==
      @["checkout holds no commit git reads after restore; got `dependencies/knoller`"]
    check checkCommitCheckout(LOCK, knoller, none(string)).anyIt(it.rule == "koch.checkout-commit")


  test "restore reads commit of each checkout through git, never of repository holding it":
    # Same case where mechanism runs: checkout at other commit, plain directory under
    #   repository whose commit lock names, and repository of no commit. Plain directory would
    #   read commit of repository holding it, which for knoller is package's own.
    let root = repoTemp()  # Project stands in repository, as each project here does.
    defer: removeDir(root)
    let checkout = root / "curator/probe/deps/knoller"
    createDir(checkout.parentDir)
    moveDir(repoTemp(), checkout)
    let
      commit_checkout = checkout.git("rev-parse HEAD").strip
      commit_root = root.git("rev-parse HEAD").strip
    root.writeInto("curator/probe/atlas.lock", textLock("knoller", COMMIT_LACKED))
    check checkCheckouts(root, "curator/probe").mapIt(it.brief) == @[
      "checkout of `knoller` stands at other commit than lock holds after restore; got `" &
        commit_checkout & "`; expect `" & COMMIT_LACKED & "`",
    ]  # other commit, read through git
    removeDir(checkout / ".git")
    root.writeInto("curator/probe/atlas.lock", textLock("knoller", commit_root))
    let unread = @["checkout holds no commit git reads after restore; got `deps/knoller`"]
    check checkCheckouts(root, "curator/probe").mapIt(it.brief) == unread  # plain directory
    discard checkout.git("init -q -b main")
    check checkCheckouts(root, "curator/probe").mapIt(it.brief) == unread  # no commit yet


  test "unreadable lock is finding, never crash":
    let root = createTempDir("delegations_", "_lock")
    defer: removeDir(root)
    root.writeInto("curator/probe/atlas.lock", "not json at all")
    check checkCheckouts(root, "curator/probe").len == 1


  test "checkouts `atlas changed` finds apart from lock are finding at lock, naming its exit":
    check differing("curator/probe", 1).mapIt((it.path, it.rule, it.brief)) == @[(
      "curator/probe/atlas.lock",
      "koch.dependency-restore",
      "checkouts differ from lock; got exit `1`",
    )]


  test "node restore without npm on `PATH` is finding at manifest, never skip":
    let path = getEnv("PATH")
    putEnv("PATH", "")
    defer: putEnv("PATH", path)
    let found = restoreNode(getTempDir(), Target(directory: "curator/probe"))
    check found.mapIt((it.rule, it.brief)) == @[(
      "koch.node-restore",
      "type check needs npm on `PATH`; help: install node, or drop this " &
        "project's manifest",
    )]


  test "projects without lock file need no atlas":
    let root = createTempDir("delegations_", "_deps")
    defer: removeDir(root)
    root.writeInto("curator/probe/probe.nimble", TEXT_NIMBLE)
    # Empty `bin` names PATH; project without lock runs no atlas either way.
    check restoreAll(root, [Target(directory: "curator/probe")]).len == 0


  test "lock stores copy of nimble, read back whole":
    check nimbleLock(lockWith(TEXT_NIMBLE)) == some(TEXT_NIMBLE)  # round trip
    check nimbleLock(TEXT_LOCK).isNone  # lock storing no copy names none


  test "stored nimble differing from committed one is finding, naming line about to be lost":
    # `atlas rep` writes lock's copy back over nimble file, so pin edited without
    #   regenerating lock is reverted silently; failure then surfaces as later finding on file
    #   contributor never touched.
    let
      stale = TEXT_NIMBLE.replace("nim == " & PIN, "nim >= " & PIN)
      found = checkNimbleLock("p/p.nimble", "p/atlas.lock", lockWith(stale), TEXT_NIMBLE)
    check found.len == 1
    check found[0].path == "p/p.nimble"  # file about to be overwritten, never lock
    check found[0].line == 6  # `requires` line of fixture
    check found[0].brief.endsWith(
      "got `requires \"nim == " & PIN & "\"`; help: regenerate lock, or make its stored copy match",
    )
    check found.anyIt(it.rule == "koch.lock-nimble")


  test "stored nimble matching committed one is clean, and absent copy compares nothing":
    let (path_nimble, path_lock) = ("p/p.nimble", "p/atlas.lock")
    check checkNimbleLock(path_nimble, path_lock, lockWith(TEXT_NIMBLE), TEXT_NIMBLE).len == 0
    check checkNimbleLock(path_nimble, path_lock, TEXT_LOCK, TEXT_NIMBLE).len == 0  # cost
    # Drift beyond pin is caught too, since lock stores whole file.
    let extra = TEXT_NIMBLE & "requires \"malebolgia\"\n"
    check checkNimbleLock(path_nimble, path_lock, lockWith(TEXT_NIMBLE), extra).len == 1


  test "unreadable lock is finding in static pass, not only at restore":
    let found = checkNimbleLock("p/p.nimble", "p/atlas.lock", "not json at all", TEXT_NIMBLE)
    check found.len == 1
    check found[0].path == "p/atlas.lock"  # fault is lock's, so finding points there
    check found[0].rule == "koch.unreadable-lock"


  test "lock names its nimble copy after nimble file of its project":
    # Case held: move of `rga_visualiser` to `pga_visualiser` left lock naming
    #   `rga_visualiser.nimble`, so `atlas rep` wrote stray copy beside `pga_visualiser.nimble`
    #   (#631). Domain: name that matches, name of other file, lock storing no name, and lock
    #   that will not parse, which `checkNimbleLock` reports once already.
    let lock = lockWith(TEXT_NIMBLE)  # Names `probe.nimble`.
    check checkNameNimble("probe/probe.nimble", "probe/atlas.lock", lock).len == 0  # matches
    let found = checkNameNimble("p/p.nimble", "p/atlas.lock", lock)
    check found.mapIt((it.path, it.line, it.brief)) == @[(
      "p/atlas.lock",
      4,
      "lock names nimble copy after nimble file of project, or `atlas rep` writes second " &
        "one beside it; got `probe.nimble`; expect `p.nimble`; help: regenerate lock",
    )]  # copy of other name, at its line
    check found[0].rule == "koch.lock-name"
    check checkNameNimble("p/p.nimble", "p/atlas.lock", TEXT_LOCK).len == 0  # no copy, no name
    check checkNameNimble("p/p.nimble", "p/atlas.lock", "not json at all").len == 0  # once
