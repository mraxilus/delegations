## Replicate pin reading of `pins.nim` header: exact version or full commit, nothing looser.

{.experimental: "strictFuncs".}

import std/[options, unittest]
import ../../src/knoller/pins


const
  PIN = "2.2.4"  ## Compiler version nimble text pins.
  COMMIT = "295bafc0d7e9a0c9a3ba0d9b39b5b0b6a4c1d2e3"
    ## Compiler commit, forty lowercase hex, standing where nimble text pins commit.
  NIMBLE_TEXT = "version = \"0.1.0\"\nsrcDir = \"src\"\n\nrequires \"nim == " & PIN & "\"\n"
    ## Nimble text pinning compiler exactly and requiring no package.



suite "Pins":
  test "version is digit runs separated by single dots":
    check isVersion("2.2.4")  # release
    check isVersion("2")  # single part
    check not isVersion("")  # empty
    check not isVersion("2.2.4a")  # letter
    check not isVersion("2..4")  # empty part
    check not isVersion(".2.4")  # leading dot


  test "commit is forty lowercase hex, and nothing else":
    check isCommit("295bafc0d7e9a0c9a3ba0d9b39b5b0b6a4c1d2e3")  # forty hex
    check not isCommit("295bafc")  # short
    check not isCommit("295BAFC0D7E9A0C9A3BA0D9B39B5B0B6A4C1D2E3")  # uppercase
    check not isCommit("295bafc0d7e9a0c9a3ba0d9b39b5b0b6a4c1d2eg")  # not hex
    check not isCommit("2.2.4")  # version
    check isPin("2.2.4") and isPin(COMMIT)
    check not isPin("devel")  # moving target records nothing


  test "package name ends at version, hash or space":
    check packageName("malebolgia") == "malebolgia"  # bare
    check packageName("malebolgia >= 1.0") == "malebolgia"  # version
    check packageName("pkg#head") == "pkg"  # hash
    check packageName("https://github.com/x/y@1.0") == "https://github.com/x/y"  # url at tag


  test "pin is read only when exact":
    check NIMBLE_TEXT.nimPin == some(PIN)  # fixture pins exactly
    check nimPin("requires \"nim == 2.2.6\"\n") == some("2.2.6")  # spaced
    check nimPin("requires \"nim==2.2.6\"\n") == some("2.2.6")  # unspaced
    check nimPin("requires \"Nim == 2.2.6\"\n") == some("2.2.6")  # case-insensitive
    check nimPin("requires \"nim >= 2.2.4\"\n").isNone  # lower bound is not pin
    check nimPin("requires \"nim\"\n").isNone  # bare name names no version
    check nimPin("requires \"malebolgia\"\n").isNone  # no compiler requirement
    check nimPin("requires \"nim == " & COMMIT & "\"\n") == some(COMMIT)  # devel dependency
    check nimPin("requires \"nim == devel\"\n").isNone  # label, not pin
