## Replicate git enumeration of `tree.nim` header: real repository, real git, paths read back.

import std/[os, options, sequtils, strutils, unittest]
import ../../src/tree
import ./fixtures


suite "Tree":
  test "git lists tracked and untracked files, never ignored ones":
    let root = tempRepo()
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
    let root = tempRepo()
    defer: removeDir(root)
    root.writeInto(ALPHA_DIR & "/README.md", "# a\n")
    discard root.git("add -A")
    discard root.git("commit -q -m 'feat(alpha): add readme'")
    discard root.git("checkout -q -b contributor/ronri/alpha/work")
    root.writeInto(ALPHA_DIR & "/x.nim", "discard\n")
    root.writeInto(ALPHA_DIR & "/README.md", "# b\n")
    discard root.git("add -A")
    discard root.git("commit -q -m 'feat(alpha): add x'")
    discard root.git("mv " & ALPHA_DIR & "/x.nim " & ALPHA_DIR & "/y.nim")
    discard root.git("commit -q -m 'refactor(alpha): rename x'")
    check changedPaths(root, "main") ==
      @[ALPHA_DIR & "/README.md", ALPHA_DIR & "/y.nim"]  # net change since base
    check subjects(root, "main") ==
      @["refactor(alpha): rename x", "feat(alpha): add x"]  # newest first, base excluded

  test "newest commit outside window, empty when none is that old":
    let root = tempRepo()
    defer: removeDir(root)
    let head = root.git("rev-parse HEAD").strip
    check root.revBefore(0) == head  # every commit lies before now
    check root.revBefore(3650) == ""  # nothing ten years old, so window holds whole history

  test "a warning git writes is never read as a field":
    # Two merge bases make git warn on `diff base...HEAD`, and warning ends in newline
    # rather than in NUL, so stream carrying both glues it to first path.
    let root = tempRepo()
    defer: removeDir(root)
    root.writeInto(ALPHA_DIR & "/README.md", "# a\n")
    discard root.git("add -A")
    discard root.git("commit -q -m 'feat(alpha): add readme'")
    discard root.git("checkout -q -b left")
    root.writeInto(ALPHA_DIR & "/left.nim", "discard\n")
    discard root.git("add -A")
    discard root.git("commit -q -m 'feat(alpha): add left'")
    let left = root.git("rev-parse HEAD").strip
    discard root.git("checkout -q main")
    discard root.git("checkout -q -b right")
    root.writeInto(ALPHA_DIR & "/right.nim", "discard\n")
    discard root.git("add -A")
    discard root.git("commit -q -m 'feat(alpha): add right'")
    let right = root.git("rev-parse HEAD").strip
    discard root.git("checkout -q left")
    discard root.git("merge -q --no-edit " & right)
    discard root.git("checkout -q right")
    discard root.git("merge -q --no-edit " & left)
    discard root.git("checkout -q left")
    root.writeInto(ALPHA_DIR & "/scoped.nim", "discard\n")
    discard root.git("add -A")
    discard root.git("commit -q -m 'feat(alpha): add scoped'")
    for path in changedPaths(root, "right"):
      check not path.contains("warning")  # warning reaches no field
      check path.startsWith(ALPHA_DIR)  # every field is still path, and path alone
    check ALPHA_DIR & "/scoped.nim" in changedPaths(root, "right")

  test "exact rename alone is move, and what base gained is read apart":
    let root = tempRepo()
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
    check movedPaths(root, "main") == @["a.nim", "c.nim"]  # edited rename absent
    check gainedPaths(root, "main") == @["NEW.md"]  # base's own commit, never branch's
    let changed = changedPaths(root, "main")
    check changed == @["a.nim", "b.nim", "c.nim", "d.nim"]  # both sides of every rename
    check "NEW.md" notin changed  # base's gain is no change of branch

  test "git failure raises with output":
    expect IOError: discard gitFields("/nonexistent_delegations", ["status"])  # non-zero exit
    let root = tempRepo()
    defer: removeDir(root)
    try:
      discard gitFields(root, ["cat-file", "-p", "0123456789abcdef0123456789abcdef01234567"])
      check false  # unreachable: missing object exits non-zero
    except IOError as failure:
      check failure.msg.contains("Not a valid object name")  # git's own reason, from stderr
