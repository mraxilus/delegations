## Replicate pin reading of `pins.nim` header: exact version or full commit, nothing looser.

{.experimental: "strictFuncs".}

import std/[options, strutils, unittest]
import ../../src/knoller/pins


const
  PIN = "2.2.4"  ## Compiler version nimble text pins.
  COMMIT = "295bafc0d7e9a0c9a3ba0d9b39b5b0b6a4c1d2e3"
    ## Compiler commit, forty lowercase hex, standing where nimble text pins commit.
  TEXT_NIMBLE = "version = \"0.1.0\"\nsrcDir = \"src\"\n\nrequires \"nim == " & PIN & "\"\n"
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
    check namePackage("malebolgia") == "malebolgia"  # bare
    check namePackage("malebolgia >= 1.0") == "malebolgia"  # version
    check namePackage("pkg#head") == "pkg"  # hash
    check namePackage("https://github.com/x/y@1.0") == "https://github.com/x/y"  # url at tag


  test "pin is read only when exact":
    check TEXT_NIMBLE.pinNim == some(PIN)  # fixture pins exactly
    check pinNim("requires \"nim == 2.2.6\"\n") == some("2.2.6")  # spaced
    check pinNim("requires \"nim==2.2.6\"\n") == some("2.2.6")  # unspaced
    check pinNim("requires \"Nim == 2.2.6\"\n") == some("2.2.6")  # case-insensitive
    check pinNim("requires \"nim >= 2.2.4\"\n").isNone  # lower bound is not pin
    check pinNim("requires \"nim\"\n").isNone  # bare name names no version
    check pinNim("requires \"malebolgia\"\n").isNone  # no compiler requirement
    check pinNim("requires \"nim == " & COMMIT & "\"\n") == some(COMMIT)  # devel dependency
    check pinNim("requires \"nim == devel\"\n").isNone  # label, not pin


  test "commit pin reads as `nim == <commit>` or `nim#<commit>`, and nothing looser does":
    check pinNim("requires \"nim == 2.2.12\"\n") == some("2.2.12")  # release
    check pinNim("requires \"nim == " & COMMIT & "\"\n") == some(COMMIT)  # commit, exact form
    check pinNim("requires \"nim#" & COMMIT & "\"\n") == some(COMMIT)  # commit, as nimble writes
    check pinNim("requires \"Nim#" & COMMIT & "\"\n") == some(COMMIT)  # case-insensitive name
    check pinNim("requires \"nim >= 2.0\"\n").isNone  # lower bound
    check pinNim("requires \"nim >= 2.0 & < 3.0\"\n").isNone  # range
    check pinNim("requires \"nim#295bafc\"\n").isNone  # short commit names many
    check pinNim("requires \"nim == 295bafc\"\n").isNone  # short commit, exact form
    check pinNim("requires \"nim#devel\"\n").isNone  # branch moves
    check pinNim("requires \"nim#v2.2.12\"\n").isNone  # tag is no commit
    check pinNim("requires \"nim#" & COMMIT.toUpperAscii & "\"\n").isNone  # not as git writes


  test "requirement of compiler reads as written after `nim`, first one alone":
    check requirementNim("requires \"nim == 2.2.12\"\n") == some("== 2.2.12")
    check requirementNim("requires \"nim#" & COMMIT & "\"\n") == some("#" & COMMIT)
    check requirementNim("requires \"malebolgia\"\n").isNone  # no compiler named
    check requirementNim("requires \"nim >= 2.0\"\nrequires \"nim == 2.2.12\"\n") ==
        some(">= 2.0")  # first wins, as `pinNim` reads it
