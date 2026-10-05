## Replicate compiler acquisition of `compilers.nim` header: what is fetched, what is built.

{.experimental: "strictFuncs".}

import std/[options, os, strutils, tempfiles, unittest]
from std/posix import nil
import ../../src/[compilers, toolchain]
import ./fixtures


proc streamsOf(action: proc ()): tuple[output, errors: string] =
  ## Run action with descriptors `1` and `2` written to files, so output of each child lands
  ##   there too, as it would on terminal; read both back.
  let directory = createTempDir("koch_", "_streams")
  defer: removeDir(directory)
  flushFile(stdout)
  flushFile(stderr)
  let
    saved = (posix.dup(1), posix.dup(2))
    files = (open(directory / "output", fmWrite), open(directory / "errors", fmWrite))
  discard posix.dup2(files[0].getFileHandle, 1)
  discard posix.dup2(files[1].getFileHandle, 2)
  action()
  flushFile(stdout)
  flushFile(stderr)
  discard posix.dup2(saved[0], 1)
  discard posix.dup2(saved[1], 2)
  discard posix.close(saved[0])
  discard posix.close(saved[1])
  files[0].close
  files[1].close
  (readFile(directory / "output"), readFile(directory / "errors"))



suite "Compilers":
  test "platform names tarball nim-lang.org publishes, or nothing":
    check platformOf("linux", "amd64") == "linux_x64"  # runner and owner's machine
    check platformOf("macosx", "amd64") == "macosx_x64"
    check platformOf("linux", "arm64").len == 0  # no published build; source instead
    check platformOf("windows", "amd64").len == 0  # zip, not tarball this reads


  test "release is fetched as tarball, and everything else is built":
    check releaseUrl("2.2.4", "linux_x64") ==
      "https://nim-lang.org/download/nim-2.2.4-linux_x64.tar.xz"
    check isBuilt(COMMIT, "linux_x64")  # commit is never published
    check isBuilt("2.2.4", "")  # unpublished platform builds from source
    check not isBuilt("2.2.4", "linux_x64")  # published release is fetched


  test "digest is published beside tarball, at same address plus suffix":
    check digestUrl("2.2.12", "linux_x64") ==
      "https://nim-lang.org/download/nim-2.2.12-linux_x64.tar.xz.sha256"
    # Digest belongs to tarball, so it is only asked for where tarball is.
    check digestUrl("2.2.12", "linux_x64").startsWith(releaseUrl("2.2.12", "linux_x64"))


  test "digest is read from sidecar, and anything that is not one reads as nothing":
    # What nim-lang.org serves, verbatim: `sha256sum` output, digest then two spaces.
    const served = "7df1611449a6842af69322aa2c1206942982650a5f6bc0d37bc8ec109932f638" &
      "  nim-2.2.12-linux_x64.tar.xz\n"
    check pinnedDigest(served) ==
      "7df1611449a6842af69322aa2c1206942982650a5f6bc0d37bc8ec109932f638"
    check pinnedDigest(served).len == 64
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


  test "resolution prints aside: its line and output of each tool it runs reach stderr alone":
    # Stub tools fail as unreachable network would, and print on both streams; real `sh` runs
    #   them through runner resolution uses (Article IX.5).
    let directory = createTempDir("koch_", "_aside")
    defer: removeDir(directory)
    for (tool, code) in [("curl", 22), ("git", 128)]:
      directory.writeInto(
        "tools/" & tool,
        "#!/bin/sh\necho \"" & tool & " stub ran\"\necho \"" & tool & " stub failed\" >&2\n" &
        "exit " & $code & "\n",
      )
      inclFilePermissions(directory / "tools" / tool, {fpUserExec})
    let path = getEnv("PATH")
    putEnv("PATH", directory / "tools" & PathSep & path)
    defer: putEnv("PATH", path)
    var bins: seq[Option[string]]
    let streams = streamsOf(proc () =
      for pin in [PIN, COMMIT]: bins.add resolve(pin, Compiler(), directory / "cache")
    )
    check bins == @[none(string), none(string)]  # stub serves neither
    check streams.output.len == 0  # stdout holds caller's product alone
    for pin in [PIN, COMMIT]: check ("== fetching Nim " & pin) in streams.errors
    check "git stub ran" in streams.errors and "git stub failed" in streams.errors  # commit builds
    if platformOf(hostOS, hostCPU).len > 0:
      check "curl stub ran" in streams.errors and "curl stub failed" in streams.errors  # fetch
