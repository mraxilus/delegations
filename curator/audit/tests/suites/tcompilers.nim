discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Replicate compiler acquisition of `compilers.nim` header: what is fetched, what is built.

import std/[os, strutils, tempfiles, unittest]
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

  test "digest is published beside tarball, at same address plus suffix":
    check digestUrl("2.2.12", "linux_x64") ==
      "https://nim-lang.org/download/nim-2.2.12-linux_x64.tar.xz.sha256"
    # Digest belongs to tarball, so it is only asked for where tarball is.
    check digestUrl("2.2.12", "linux_x64").startsWith(releaseUrl("2.2.12", "linux_x64"))
    check DIGEST == ".sha256"

  test "digest is read from sidecar, and anything that is not one reads as nothing":
    # What nim-lang.org serves, verbatim: `sha256sum` output, digest then two spaces.
    const REAL = "7df1611449a6842af69322aa2c1206942982650a5f6bc0d37bc8ec109932f638" &
      "  nim-2.2.12-linux_x64.tar.xz\n"
    check pinnedDigest(REAL) ==
      "7df1611449a6842af69322aa2c1206942982650a5f6bc0d37bc8ec109932f638"
    check pinnedDigest(REAL).len == 64
    # Proven by breaking it: text that is not digest reads as none rather than as digest
    #   that cannot match, since mismatch and nothing published are different reports.
    check pinnedDigest("").len == 0  # nothing served
    check pinnedDigest("<html><body>404</body></html>").len == 0  # error document
    check pinnedDigest("7df16114  nim.tar.xz").len == 0  # truncated digest
    check pinnedDigest("7DF1611449A6842AF69322AA2C1206942982650A5F6BC0D37BC8EC109932F638" &
      "  nim.tar.xz").len == 0  # upper case is not what sha256sum writes
    check pinnedDigest("zzz1611449a6842af69322aa2c1206942982650a5f6bc0d37bc8ec109932f638" &
      "  nim.tar.xz").len == 0  # right length, not hex

  test "digest of file changes when any byte of it does, which is what guard rests on":
    # Proven by breaking it rather than by fetch that happened to succeed: guard compares
    #   digest of what arrived against digest published for it, so what has to hold is that
    #   one byte of difference is one digest of difference.
    let (file, path) = createTempFile("koch_", ".tar.xz")
    defer: removeFile(path)
    file.write("nim tarball, or something standing for one")
    file.close
    let whole = path.digestOf
    check whole.len == 64  # `sha256sum` ran, and its output parsed
    check whole == pinnedDigest(whole & "  " & path)  # same reader as sidecar's
    writeFile(path, "nim tarball, or something standing for onf")  # one byte
    check path.digestOf != whole
    check path.digestOf.len == 64  # still digest, just not that one
    # Absent file is nothing rather than digest, so it reports instead of matching.
    check digestOf(path & ".absent").len == 0

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
