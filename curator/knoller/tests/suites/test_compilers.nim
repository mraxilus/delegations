## Replicate compiler acquisition of `compilers.nim` header: what is fetched, what is built, and
##   what serves pin.

{.experimental: "strictFuncs".}

import std/[options, os, strutils, tempfiles, unittest]
from std/posix import nil
import ../../src/knoller/[compilers, proofs]


const
  PIN = "2.2.4"  ## Compiler version suite resolves.
  COMMIT = "295bafc0d7e9a0c9a3ba0d9b39b5b0b6a4c1d2e3"
    ## Compiler commit, forty lowercase hex, standing where suite resolves commit, not version.
  NIM = getCurrentCompilerExe()  ## Compiler building suite, whose parser fake toolchain runs.
  GROUPED = "let s = @(x) + @(x[0])\n"  ## Source holding group parser proves, and group it refuses.


proc streamsOf(action: proc ()): tuple[output, errors: string] =
  ## Run action with descriptors `1` and `2` written to files, so output of each child lands
  ##   there too, as it would on terminal; read both back.
  let directory = createTempDir("knoller_", "_streams")
  defer: removeDir(directory)
  flushFile(stdout)
  flushFile(stderr)
  let
    saved = (posix.dup(1), posix.dup(2))
    files = (open(directory / "output", fmWrite), open(directory / "errors", fmWrite))
  # File handle is descriptor of C library on every platform, though typed `int` on Windows.
  discard posix.dup2(cint(files[0].getFileHandle), 1)
  discard posix.dup2(cint(files[1].getFileHandle), 2)
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


proc writeTools(directory: string) =
  ## Write `curl` and `git` failing as unreachable network would, each printing on both streams.
  createDir(directory)
  for (tool, code) in [("curl", 22), ("git", 128)]:
    writeFile(
      directory / tool,
      "#!/bin/sh\necho \"" & tool & " stub ran\"\necho \"" & tool & " stub failed\" >&2\n" &
      "exit " & $code & "\n",
    )
    inclFilePermissions(directory / tool, {fpUserExec})


proc writeToolchain(root, pin: string) =
  ## Write toolchain of pin under cache root: its `nim` names pin as version, and runs compiler
  ##   building suite for every other command.
  createDir(root / pin / "bin")
  writeFile(
    root / pin / "bin" / "nim",
    "#!/bin/sh\nif [ \"$1\" = --version ]; then echo \"Nim Compiler Version " & pin &
    " [Linux: amd64]\"; exit 0; fi\nexec " & NIM.quoteShell & " \"$@\"\n",
  )
  inclFilePermissions(root / pin / "bin" / "nim", {fpUserExec})



suite "Compilers":
  test "platform names tarball nim-lang.org publishes, or nothing":
    check platformOf("linux", "amd64") == "linux_x64"  # runner and owner's machine
    check platformOf("macosx", "amd64") == "macosx_x64"
    check platformOf("linux", "arm64").len == 0  # no published build; source instead
    check platformOf("windows", "amd64").len == 0  # zip, not tarball this reads


  test "release is fetched as tarball, and everything else is built":
    check urlRelease("2.2.4", "linux_x64") ==
        "https://nim-lang.org/download/nim-2.2.4-linux_x64.tar.xz"
    check isBuilt(COMMIT, "linux_x64")  # commit is never published
    check isBuilt("2.2.4", "")  # unpublished platform builds from source
    check not isBuilt("2.2.4", "linux_x64")  # published release is fetched


  test "digest is published beside tarball, at same address plus suffix":
    check urlDigest("2.2.12", "linux_x64") ==
        "https://nim-lang.org/download/nim-2.2.12-linux_x64.tar.xz.sha256"
    # Digest belongs to tarball, so it is only asked for where tarball is.
    check urlDigest("2.2.12", "linux_x64").startsWith(urlRelease("2.2.12", "linux_x64"))


  test "digest is read from sidecar, and anything that is not one reads as nothing":
    # What nim-lang.org serves, verbatim: `sha256sum` output, digest then two spaces.
    const served = "7df1611449a6842af69322aa2c1206942982650a5f6bc0d37bc8ec109932f638" &
        "  nim-2.2.12-linux_x64.tar.xz\n"
    check digestPinned(served) ==
        "7df1611449a6842af69322aa2c1206942982650a5f6bc0d37bc8ec109932f638"
    check digestPinned(served).len == 64
    # Proven by breaking it: text that is not digest reads as none rather than as digest
    #   that cannot match, since mismatch and nothing published are different reports.
    check digestPinned("").len == 0  # nothing served
    check digestPinned("<html><body>404</body></html>").len == 0  # error document
    check digestPinned("7df16114  nim.tar.xz").len == 0  # truncated digest
    check digestPinned("7DF1611449A6842AF69322AA2C1206942982650A5F6BC0D37BC8EC109932F638" &
      "  nim.tar.xz").len == 0  # upper case is not what sha256sum writes
    check digestPinned("zzz1611449a6842af69322aa2c1206942982650a5f6bc0d37bc8ec109932f638" &
      "  nim.tar.xz").len == 0  # right length, not hex


  test "digest of file changes when any byte of it does, which is what guard rests on":
    when defined(windows):
      # Gap: `sha256sum` is no tool of Windows, and fetch it guards never runs there
      #   (`resolve`), so digest is read on POSIX alone.
      skip()
    else:
      # Proven by breaking it rather than by fetch that happened to succeed: guard compares
      #   digest of what arrived against digest published for it, so what has to hold is that
      #   one byte of difference is one digest of difference.
      let (file, path) = createTempFile("knoller_", ".tar.xz")
      defer: removeFile(path)
      file.write("nim tarball, or something standing for one")
      file.close
      let whole = path.digestOf
      check whole.len == 64  # `sha256sum` ran, and its output parsed
      check whole == digestPinned(whole & "  " & path)  # same reader as sidecar's
      writeFile(path, "nim tarball, or something standing for onf")  # one byte
      check path.digestOf != whole
      check path.digestOf.len == 64  # still digest, just not that one
      # Absent file is nothing rather than digest, so it reports instead of matching.
      check digestOf(path & ".absent").len == 0


  test "cache lies outside repository, keyed by pin":
    let root = rootCache("/h/.cache/knoller/nim")
    check root == "/h/.cache/knoller/nim"
    check binOf(root, PIN) == "/h/.cache/knoller/nim" / "2.2.4" / "bin"  # joined natively
    # Audit reads untracked files, so toolchain inside checkout would be audited.
    check not binOf(root, PIN).startsWith(".")


  test "cache is knoller's, under home, and `$KNOLLER_NIM_DIR` moves it for koch too":
    check rootCache("") == getHomeDir() / ".cache/knoller/nim"  # one cache, whichever tool asks
    let (is_set, moved) = (existsEnv(KEY_CACHE), getEnv(KEY_CACHE))
    defer:
      if is_set: putEnv(KEY_CACHE, moved) else: delEnv(KEY_CACHE)
    putEnv(KEY_CACHE, "/h/toolchains")
    check KEY_CACHE == "KNOLLER_NIM_DIR"
    check initToolchains().root == "/h/toolchains"  # table koch and knoller hold reads it
    putEnv(KEY_CACHE, "")
    check initToolchains().root == getHomeDir() / ".cache/knoller/nim"  # empty moves nothing


  test "pin is served by commit for commit, by version otherwise":
    let running = Compiler(version: PIN, commit: COMMIT)
    check PIN.isServedBy(running)  # version pin reads version
    check COMMIT.isServedBy(running)  # commit pin reads hash
    check not "2.2.6".isServedBy(running)  # another version does not
    check not COMMIT.isServedBy(Compiler(version: PIN))  # compiler reporting no hash serves none


  test "resolution prints aside: its line and output of each tool it runs reach stderr alone":
    # Stub tools fail as unreachable network would, and print on both streams; real `sh` runs
    #   them through runner resolution uses (Article IX.5).
    let directory = createTempDir("knoller_", "_aside")
    defer: removeDir(directory)
    writeTools(directory / "tools")
    let path = getEnv("PATH")
    putEnv("PATH", directory / "tools" & PathSep & path)
    defer: putEnv("PATH", path)
    var bins: seq[Option[string]]
    let streams = streamsOf(proc () =
      for pin in [PIN, COMMIT]: bins.add resolve(pin, Compiler(), directory / "cache")
    )
    check bins == @[none(string), none(string)]  # stub serves neither
    check streams.output.len == 0  # stdout holds caller's product alone
    when defined(windows):
      # Nothing is fetched or built there, and one line names both places tried.
      for pin in [PIN, COMMIT]: check ("No toolchain serves Nim " & pin) in streams.errors
      check "stub ran" notin streams.errors
    else:
      for pin in [PIN, COMMIT]: check ("== fetching Nim " & pin) in streams.errors
      check "git stub ran" in streams.errors and "git stub failed" in streams.errors  # build
      if platformOf(hostOS, hostCPU).len > 0:
        check "curl stub ran" in streams.errors and "curl stub failed" in streams.errors


  test "toolchains resolve each pin once: PATH where it serves, cache next, and failure held":
    when defined(windows):
      # Gap: stub toolchain is `sh` script, which Windows runs nowhere, so serving pin from
      #   cache is proven on POSIX alone.
      skip()
    else:
      let directory = createTempDir("knoller_", "_toolchains")
      defer: removeDir(directory)
      writeTools(directory / "tools")
      writeToolchain(directory / "cache", "9.9.9")
      let path = getEnv("PATH")
      putEnv("PATH", directory / "tools" & PathSep & path)
      defer: putEnv("PATH", path)
      var
        toolchains = initToolchains(directory / "cache", some(Compiler(version: "9.9.8")))
        bins: seq[Option[string]]
      let streams = streamsOf(proc () =
        for pin in ["9.9.8", "9.9.9", "0.0.1", "0.0.1"]: bins.add toolchains.binFor(pin)
      )
      check bins[0] == some("")  # compiler on PATH serves its own version
      check bins[1] == some(directory / "cache" / "9.9.9" / "bin")  # cache serves, no fetch
      check bins[2..3] == @[none(string), none(string)]  # nothing serves
      check streams.errors.count("== fetching Nim ") == 1  # failure held, never tried again
      check streams.output.len == 0


  test "prover of pin is parser of compiler serving it; pin nothing serves names itself":
    when defined(windows):
      # Gap: stub toolchain is `sh` script, which Windows runs nowhere, so prover of pin is
      #   proven on POSIX alone; prover of `nim` on PATH runs there (`test_command.nim`).
      skip()
    else:
      let directory = createTempDir("knoller_", "_provers")
      defer: removeDir(directory)
      writeTools(directory / "tools")
      writeToolchain(directory / "cache", "9.9.9")
      let path = getEnv("PATH")
      putEnv("PATH", directory / "tools" & PathSep & path)
      defer: putEnv("PATH", path)
      let provers =
        proversPin(initToolchains(directory / "cache", some(Compiler(version: "9.9.8"))))
      var provings: seq[Proving]
      let streams = streamsOf(proc () =
        for pin in ["9.9.9", "0.0.1"]: provings.add provers(pin)(@[GROUPED])
      )
      check provings[0].failure.len == 0 and provings[0].answers == @[@[9]]  # `@(x[0])` stays
      check provings[1].answers == @[newSeq[int]()]  # nothing proven
      check provings[1].failure ==
          "Parser proved no removal, since no compiler serves pin; got `0.0.1`."
      check streams.output.len == 0
