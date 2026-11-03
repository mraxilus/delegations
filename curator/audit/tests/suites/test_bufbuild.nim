## Replicate store of `buf` that `bufbuild.nim` header describes, i.e. pin, digest, store.
##   Binary present is read without fetch; pinned binary, fetched where store lacks it, reports
##     its version, so fetch, digest check and unpack are held on cold store.
##   Cost: cold store fetches about 33 MB, and needs network, `curl`, `sha512sum` and `tar`;
##     runner caches no store, so each run of suite there fetches it.

{.experimental: "strictFuncs".}

import std/[options, os, osproc, strutils, unittest]
import ../../src/bufbuild



suite "Bufbuild":
  test "store lies outside repository, and override wins":
    check rootBufbuild("/tmp/buf") == "/tmp/buf"
    check rootBufbuild("").endsWith(DIRECTORY_BUFBUILD)
    # Audit reads untracked files, so store inside checkout would be audited.
    check not rootBufbuild("").startsWith(".")
    check DIRECTORY_BUFBUILD.parentDir == ".cache/koch"  # store is koch's own, beside assets


  test "binary is named by its pin, and digest is SHA-512":
    check pathBufbuild("/s") == "/s" / VERSION_BUFBUILD / "buf"  # moved pin is new path
    check DIGEST_BUFBUILD.len == 128 and DIGEST_BUFBUILD.allCharsInSet(HexDigits)


  test "binary present is trusted, and never fetched again":
    let store = getTempDir() / "test_bufbuild_" & $getCurrentProcessId()
    defer: removeDir(store)
    createDir(pathBufbuild(store).parentDir)
    writeFile(pathBufbuild(store), "")
    check bufbuildIn(store) == some(pathBufbuild(store))
    check getFileSize(pathBufbuild(store)) == 0  # empty file stands, so no fetch ran


  test "pinned binary reports its version":
    let path = bufbuildIn(rootBufbuild(getEnv(KEY_BUFBUILD)))
    check path.isSome
    let (output, code) = execCmdEx(quoteShellCommand([path.get, "--version"]))
    check code == 0 and output.strip == VERSION_BUFBUILD
