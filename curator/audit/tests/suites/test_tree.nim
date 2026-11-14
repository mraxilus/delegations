## Replicate git enumeration of `tree.nim` header: real repository, real git, paths read back.

{.experimental: "strictFuncs".}

import std/[options, os, sequtils, sets, strutils, tables, tempfiles, unittest]
import ../../src/[domains, tree]
import ./fixtures



suite "Tree":
  test "git lists tracked and untracked files, never ignored ones":
    let root = repoTemp()
    defer: removeDir(root)
    root.writeInto(".gitignore", "bin/\n")
    root.writeInto("contributor/sincopa/alpha/src/x.nim", "discard\n")
    root.writeInto("bin/audit", "binary")
    root.writeInto("data.csv", "1,2\n")
    discard root.git("add .gitignore")
    check root.listPaths ==
      @[".gitignore", "contributor/sincopa/alpha/src/x.nim", "data.csv"]  # sorted, unquoted
    let entries = root.readTree
    check entries.mapIt(it.path) == root.listPaths  # same order
    check entries[1].kind.isSome and entries[1].content == "discard\n"  # registered kind read
    check entries[2].kind.isNone and entries[2].content.len == 0  # unregistered kind unread


  test "changed paths and subjects since base":
    let root = repoTemp()
    defer: removeDir(root)
    root.writeInto(DIRECTORY_ALPHA & "/README.md", "# a\n")
    discard root.git("add -A")
    discard root.git("commit -q -m 'feat(alpha): add readme'")
    discard root.git("checkout -q -b contributor/ronri/alpha/work")
    root.writeInto(DIRECTORY_ALPHA & "/x.nim", "discard\n")
    root.writeInto(DIRECTORY_ALPHA & "/README.md", "# b\n")
    discard root.git("add -A")
    discard root.git("commit -q -m 'feat(alpha): add x'")
    discard root.git("mv " & DIRECTORY_ALPHA & "/x.nim " & DIRECTORY_ALPHA & "/y.nim")
    discard root.git("commit -q -m 'refactor(alpha): rename x'")
    check pathsChanged(root, "main") ==
      @[DIRECTORY_ALPHA & "/README.md", DIRECTORY_ALPHA & "/y.nim"]  # net change since base
    check subjects(root, "main") ==
      @["refactor(alpha): rename x", "feat(alpha): add x"]  # newest first, base excluded


  test "newest commit outside window, empty when none is that old":
    let root = repoTemp()
    defer: removeDir(root)
    let head = root.git("rev-parse HEAD").strip
    check root.revBefore(0) == head  # every commit lies before now
    check root.revBefore(3650) == ""  # nothing ten years old, so window holds whole history


  test "a warning git writes is never read as a field":
    # Two merge bases make git warn on `diff base...HEAD`, and warning ends in newline
    # rather than in NUL, so stream carrying both glues it to first path.
    let root = repoTemp()
    defer: removeDir(root)
    root.writeInto(DIRECTORY_ALPHA & "/README.md", "# a\n")
    discard root.git("add -A")
    discard root.git("commit -q -m 'feat(alpha): add readme'")
    discard root.git("checkout -q -b left")
    root.writeInto(DIRECTORY_ALPHA & "/left.nim", "discard\n")
    discard root.git("add -A")
    discard root.git("commit -q -m 'feat(alpha): add left'")
    let left = root.git("rev-parse HEAD").strip
    discard root.git("checkout -q main")
    discard root.git("checkout -q -b right")
    root.writeInto(DIRECTORY_ALPHA & "/right.nim", "discard\n")
    discard root.git("add -A")
    discard root.git("commit -q -m 'feat(alpha): add right'")
    let right = root.git("rev-parse HEAD").strip
    discard root.git("checkout -q left")
    discard root.git("merge -q --no-edit " & right)
    discard root.git("checkout -q right")
    discard root.git("merge -q --no-edit " & left)
    discard root.git("checkout -q left")
    root.writeInto(DIRECTORY_ALPHA & "/scoped.nim", "discard\n")
    discard root.git("add -A")
    discard root.git("commit -q -m 'feat(alpha): add scoped'")
    for path in pathsChanged(root, "right"):
      check not path.contains("warning")  # warning reaches no field
      check path.startsWith(DIRECTORY_ALPHA)  # every field is still path, and path alone
    check DIRECTORY_ALPHA & "/scoped.nim" in pathsChanged(root, "right")


  test "exact rename alone is move, and what base gained is read apart":
    let root = repoTemp()
    defer: removeDir(root)
    root.writeInto("a.nim", "discard 1\n")
    root.writeInto("b.nim", "discard 2\n")
    discard root.git("add -A")
    discard root.git("commit -q -m 'feat(x): add a and b'")
    discard root.git("checkout -q -b work")
    discard root.git("mv a.nim c.nim")
    discard root.git("mv b.nim d.nim")
    root.writeInto("d.nim", "discard 2\ndiscard 3\n")
    discard root.git("add -A")
    discard root.git("commit -q -m 'refactor(x): move a, move and edit b'")
    discard root.git("checkout -q main")
    root.writeInto("NEW.md", "# New\n")
    discard root.git("add -A")
    discard root.git("commit -q -m 'docs(x): add new'")
    discard root.git("checkout -q work")
    check pathsMoved(root, "main") == @["a.nim", "c.nim"]  # edited rename absent
    check pathsGained(root, "main") == @["NEW.md"]  # base's own commit, never branch's
    let changed = pathsChanged(root, "main")
    check changed == @["a.nim", "b.nim", "c.nim", "d.nim"]  # both sides of every rename
    check "NEW.md" notin changed  # base's gain is no change of branch


  test "lines each hunk of diff adds are read by path after change":
    # Body line opening `++` is content, never header of file.
    let diff = [
      "diff --git a.md a.md", "index 1111111..2222222 100644", "--- a.md", "+++ a.md",
      "@@ -3,0 +4,2 @@ heading", "+one", "+++ two", "@@ -9 +11 @@", "-old", "+new",
      "diff --git gone.md gone.md", "deleted file mode 100644", "--- gone.md", "+++ /dev/null",
      "@@ -1 +0,0 @@", "-gone",
    ].join("\n")
    let lines = diff.linesHunks
    check lines.len == 1  # deleted file adds none
    check lines["a.md"] == [4, 5, 11].toHashSet


  test "branch owns each line it changed, widened to opening of its prose block":
    let root = repoTemp()
    defer: removeDir(root)
    let readme = DIRECTORY_ALPHA & "/README.md"
    root.writeInto(readme, "# Alpha\n\nFirst line\nsecond line.\n\n- item\n")
    root.writeInto("a.nim", "discard 1\n")
    discard root.git("add -A")
    discard root.git("commit -q -m 'feat(alpha): add readme'")
    discard root.git("checkout -q -b curator/rules")
    discard root.git("mv a.nim b.nim")  # exact rename changes no line
    root.writeInto(readme, "# Alpha\n\nFirst line\nsecond line, longer.\n\n- item\n")  # unstaged
    let owned = linesOwned(root, root.readTree, "main")
    check owned.len == 1
    check owned[readme] == [3, 4].toHashSet  # paragraph opens on 3


  test "deletion owns lines beside it, and path holding space keeps its name":
    # Case as found: blank line deleted between two paragraphs joins them into one block,
    #   whose finding names line that block opens on.
    let diff = ["diff --git a b.md a b.md", "--- a b.md\t", "+++ a b.md\t", "@@ -5 +4,0 @@", "-"]
    check diff.join("\n").linesHunks.getOrDefault("a b.md") == [4, 5].toHashSet
    let root = repoTemp()
    defer: removeDir(root)
    let readme = DIRECTORY_ALPHA & "/README.md"
    root.writeInto(readme, "# Alpha\n\nOne.\nTwo.\n\nThree.\n")
    discard root.git("add -A")
    discard root.git("commit -q -m 'feat(alpha): add readme'")
    discard root.git("checkout -q -b curator/rules")
    root.writeInto(readme, "# Alpha\n\nOne.\nTwo.\nThree.\n")  # blank line deleted
    check 3 in linesOwned(root, root.readTree, "main").getOrDefault(readme)  # joined block


  test "git failure raises with output":
    expect IOError: discard fieldsGit("/nonexistent_delegations", ["status"])  # non-zero exit
    let root = repoTemp()
    defer: removeDir(root)
    try:
      discard fieldsGit(root, ["cat-file", "-p", "0123456789abcdef0123456789abcdef01234567"])
      check false  # unreachable: missing object exits non-zero
    except IOError as failure:
      check failure.msg.contains("Not a valid object name")  # git's own reason, from stderr


  test "directory of other repository holds no checkout of root (#380)":
    # Case as found: commit in scratch repository was held to branch of root, and refused while
    #   root sat on detached head.
    let
      root = repoTemp()
      other = repoTemp()
      plain = createTempDir("delegations_", "_plain")
      tree = root & "_worktree"
    defer: removeDir(root)
    defer: removeDir(other)
    defer: removeDir(plain)
    defer: removeDir(tree)
    root.writeInto("sub/x.nim", "discard\n")
    discard root.git("add -A")
    discard root.git("commit -q -m 'feat(curator): add x'")
    discard root.git("worktree add -q -b work " & tree.quoteShell)
    discard root.git("checkout -q --detach")
    check checkoutAt(root, other).isNone  # other repository keeps its own branch
    check checkoutAt(root, other / "unwritten" / "deeper").isNone  # read from nearest that exists
    # Domain: each checkout of this repository reads its own top, and no repository reads root.
    check checkoutAt(root, root) == some(root)
    check checkoutAt(root, root / "sub") == some(root)  # subdirectory reads top
    check checkoutAt(root, root / "sub" / "unwritten") == some(root)
    check checkoutAt(root, tree / "sub") == some(tree)  # worktree holds its own branch
    check checkoutAt(root, plain) == some(root)  # git fails, so root's rule still holds


  test "root reached through link reads by its real path where git fails too (#883)":
    # Case as found on #883: folder in no repository read as root spelt through link, while git
    #   names each other top by real path, and `pathReal` reads file by real path.
    let
      root = repoTemp()
      links = createTempDir("delegations_", "_links")
      plain = createTempDir("delegations_", "_plain")
    defer: removeDir(root)
    defer: removeDir(links)
    defer: removeDir(plain)
    createSymlink(root, links / "root")
    check checkoutAt(links / "root", plain) == some(root)  # git fails, so fallback reads root
    # Domain: git names real top through same link, and root spelt real reads as it is.
    check checkoutAt(links / "root", links / "root") == some(root)
    check checkoutAt(root, plain) == some(root)


  test "lock that moved with its project and follows its name is move":
    # Case held: `pathsMoved` read exact renames alone, so lock whose one line follows moved
    #   nimble file read as edit, and `check-scope` refused it (#631). Domain: that lock, and
    #   lock moved with second edit, which stays edit.
    let
      root = repoTemp()
      gamma = CONTRIBUTOR & "/ronri/gamma"
      nimble_gamma = TEXT_NIMBLE & "\nrequires \"jsony\"\nbin = @[\"gamma\"]\n"
    defer: removeDir(root)
    root.writeInto(DIRECTORY_ALPHA & "/atlas.lock", lockWith(TEXT_NIMBLE).replace("probe", "alpha"))
    root.writeInto(gamma & "/atlas.lock", lockWith(nimble_gamma).replace("probe", "gamma"))
    discard root.git("add -A")
    discard root.git("commit -q -m 'build(alpha): pin'")
    discard root.git("checkout -q -b curator/move")
    discard root.git("mv " & DIRECTORY_ALPHA & " " & CONTRIBUTOR & "/ronri/beta")
    discard root.git("mv " & gamma & " " & CONTRIBUTOR & "/ronri/delta")
    let
      beta = CONTRIBUTOR & "/ronri/beta/atlas.lock"
      delta = CONTRIBUTOR & "/ronri/delta/atlas.lock"
    root.writeInto(beta, readFile(root / beta).replace("alpha.nimble", "beta.nimble"))
    root.writeInto(
      delta,
      readFile(root / delta).replace("gamma.nimble", "delta.nimble").replace("jsony", "yaml"),
    )
    discard root.git("add -A")
    discard root.git("commit -q -m 'chore(curator): move alpha and gamma'")
    check pathsMoved(root, "main") == @[DIRECTORY_ALPHA & "/atlas.lock", beta]  # delta edited
