discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Replicate compiler acquisition of `compilers.nim` header: what is fetched, what is built.

import std/[strutils, unittest]
import ../src/[toolchain, compilers]
import ./fixtures


suite "Compilers":
  test "platform names tarball nim-lang.org publishes, or nothing":
    check platformOf("linux", "amd64") == "linux_x64"  # runner and owner's machine
    check platformOf("macosx", "amd64") == "macosx_x64"
    check platformOf("linux", "arm64").len == 0  # no published build; source instead
    check platformOf("windows", "amd64").len == 0  # zip, not tarball this reads

  test "release is fetched as tarball, and everything else is built":
    check releaseUrl("2.2.4", "linux_x64") ==
      "https://nim-lang.org/download/nim-2.2.4-linux_x64.tar.xz"
    let commit = "295bafc0d7e9a0c9a3ba0d9b39b5b0b6a4c1d2e3"
    check isBuilt(commit, "linux_x64")  # commit is never published
    check isBuilt("2.2.4", "")  # unpublished platform builds from source
    check not isBuilt("2.2.4", "linux_x64")  # published release is fetched

  test "cache lies outside repository, keyed by pin":
    let root = cacheRoot("/home/x/.cache/koch/nim")
    check root == "/home/x/.cache/koch/nim"
    check binOf(root, PIN) == "/home/x/.cache/koch/nim/2.2.4/bin"
    # Audit reads untracked files, so toolchain inside checkout would be audited.
    check not binOf(root, PIN).startsWith(".")

  test "unresolved pin is finding naming where koch looked":
    let found = missing("curator/probe", "2.2.6", "/c/2.2.6/bin")
    check found.len == 1
    check found[0].path == "curator/probe"
    check found[0].message.endsWith("got `2.2.6`.")
    check "/c/2.2.6/bin" in found[0].message  # names cache it tried
