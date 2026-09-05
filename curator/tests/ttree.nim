discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Replicate Article IX.5 for git enumeration: real repository, real git, paths read back.

import std/[os, options, sequtils, unittest]
import ../src/tree
import ./fixtures


suite "Article IX":
  test "IX.5 git lists tracked and untracked files, never ignored ones":
    let root = tempRepo()
    defer: removeDir(root)
    root.writeInto(".gitignore", "bin/\n")
    root.writeInto("síncopa/alpha/src/x.nim", "discard\n")
    root.writeInto("bin/audit", "binary")
    root.writeInto("data.csv", "1,2\n")
    discard root.git("add .gitignore")
    check root.listPaths ==
      @[".gitignore", "data.csv", "síncopa/alpha/src/x.nim"]  # sorted, ignored absent, unquoted
    let entries = root.readTree
    check entries.mapIt(it.path) == root.listPaths  # same order
    check entries[2].kind.isSome and entries[2].content == "discard\n"  # registered kind read
    check entries[1].kind.isNone and entries[1].content.len == 0  # unregistered kind unread

  test "IX.5 changed paths and subjects since base":
    let root = tempRepo()
    defer: removeDir(root)
    root.writeInto("ronri/alpha/README.md", "# a\n")
    discard root.git("add -A")
    discard root.git("commit -q -m 'feat(alpha): add readme'")
    discard root.git("checkout -q -b ronri/alpha/work")
    root.writeInto("ronri/alpha/x.nim", "discard\n")
    root.writeInto("ronri/alpha/README.md", "# b\n")
    discard root.git("add -A")
    discard root.git("commit -q -m 'feat(alpha): add x'")
    discard root.git("mv ronri/alpha/x.nim ronri/alpha/y.nim")
    discard root.git("commit -q -m 'refactor(alpha): rename x'")
    check changedPaths(root, "main") ==
      @["ronri/alpha/README.md", "ronri/alpha/y.nim"]  # net change since base; x.nim never in main
    check subjects(root, "main") ==
      @["refactor(alpha): rename x", "feat(alpha): add x"]  # newest first, base excluded

  test "IX.5 git failure raises with output":
    expect IOError: discard gitFields("/nonexistent_delegations", ["status"])  # non-zero exit
