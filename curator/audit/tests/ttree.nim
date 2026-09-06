discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Replicate Article IX.5 for git enumeration: real repository, real git, paths read back.

import std/[os, options, sequtils, strutils, unittest]
import ../src/tree
import ./fixtures


suite "Article IX":
  test "IX.5 git lists tracked and untracked files, never ignored ones":
    let root = tempRepo()
    defer: removeDir(root)
    root.writeInto(".gitignore", "bin/\n")
    root.writeInto("contributor/síncopa/alpha/src/x.nim", "discard\n")
    root.writeInto("bin/audit", "binary")
    root.writeInto("data.csv", "1,2\n")
    discard root.git("add .gitignore")
    check root.listPaths ==
      @[".gitignore", "contributor/síncopa/alpha/src/x.nim", "data.csv"]  # sorted, unquoted
    let entries = root.readTree
    check entries.mapIt(it.path) == root.listPaths  # same order
    check entries[1].kind.isSome and entries[1].content == "discard\n"  # registered kind read
    check entries[2].kind.isNone and entries[2].content.len == 0  # unregistered kind unread

  test "IX.5 changed paths and subjects since base":
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

  test "IX.5 newest commit outside window, empty when none is that old":
    let root = tempRepo()
    defer: removeDir(root)
    let head = root.git("rev-parse HEAD").strip
    check root.revBefore(0) == head  # every commit lies before now
    check root.revBefore(3650) == ""  # nothing ten years old, so window holds whole history

  test "IX.5 git failure raises with output":
    expect IOError: discard gitFields("/nonexistent_delegations", ["status"])  # non-zero exit
