discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Replicate shared store of `assets.nim` header, i.e. one declaration, keyed by digest.

import std/[os, strutils, tempfiles, unittest]
import ../src/assets


suite "Assets":
  test "store lies outside repository, and override wins":
    check storeRoot("/tmp/assets") == "/tmp/assets"
    check storeRoot("").endsWith(ASSETS_DIR)
    # Audit reads untracked files, so store inside checkout would be audited.
    check not storeRoot("").startsWith(".")
    check ASSETS_DIR == ".cache/koch/assets"  # beside `~/.cache/koch/nim`

  test "asset is stored under its digest, never under its name":
    # Two projects asking for one face share one entry by construction, and moved pin is
    #   different entry rather than stale one.
    const FACE = "noto-sans-latin-400-normal.woff2"
    let digest = FACE.digestOf
    check digest.len == 64
    check pathOf("/s", FACE) == "/s" / digest
    check FACE notin pathOf("/s", FACE)  # name is nowhere in path
    check pathOf("/s", "not-a-face.woff2").len == 0  # undeclared face has no path

  test "address carries version, so bytes and version move together or neither":
    const FACE = "noto-serif-latin-600-normal.woff2"
    let address = FACE.addressOf
    check address.startsWith("https://")
    check address.endsWith(FACE)
    check "@fontsource/noto-serif@" in address  # package and its version, in address
    check addressOf("not-a-face.woff2").len == 0

  test "TrueType comes from Noto's own repository, since fontsource ships none":
    # Atlas reads TrueType and `@fontsource` packages `woff2` alone, so desktop faces have
    #   their own upstream; store holds both rather than one project holding each.
    check "notofonts" in "NotoSans-Regular.ttf".addressOf
    check "notofonts" in "NotoSansMath-Regular.ttf".addressOf
    check "commit-mono" in "CommitMonoV142-400Regular.otf".addressOf  # its author's own
    check "fontsource" in "noto-sans-latin-400-normal.woff2".addressOf

  test "every row is one file, one address and one digest of sixty-four hex digits":
    var files: seq[string]
    for (file, prefix, digest) in ASSETS:
      check file.len > 0
      check file notin files  # nothing declared twice, which is what store exists to stop
      files.add file
      check prefix.startsWith("https://")
      check prefix.endsWith("/")  # prefix is directory; file is appended to it
      check digest.len == 64
      for c in digest: check c in {'0' .. '9', 'a' .. 'f'}

  test "store holds what both projects pinned, including all four they shared":
    # Rows are union of two tables that agreed. These four were written twice, byte for
    #   byte, which is repository issue 116 and Article II.9's own test.
    for file in [
      "noto-serif-latin-600-normal.woff2", "noto-sans-latin-400-normal.woff2",
      "noto-sans-latin-600-normal.woff2", "commit-mono-latin-400-normal.woff2",
    ]:
      check file.digestOf.len == 64
    # And what only one of them wanted, so neither lost face by sharing one table.
    check "noto-serif-latin-400-italic.woff2".digestOf.len == 64  # dance_ontology alone
    check "noto-sans-math-math-400-normal.woff2".digestOf.len == 64  # rga_visualiser alone

  test "digest is read from file as `sha256sum` writes it":
    let (file, path) = createTempFile("face_", ".woff2")
    defer: removeFile(path)
    file.write("not really a face")
    file.close
    let read = path.readDigest
    check read.len == 64
    for c in read: check c in {'0' .. '9', 'a' .. 'f'}
    # One byte of difference is one digest of difference, which is what fetch rests on.
    writeFile(path, "not really a facf")
    check path.readDigest != read
    check readDigest(path & ".absent").len == 0  # absent file is nothing, never digest

  test "asset nobody declared is finding naming what was asked for":
    let found = unknown("fraunces-latin-400-normal.woff2")
    check found.len == 1
    check found[0].message.endsWith("got `fraunces-latin-400-normal.woff2`.")
    check "assets.nim" in found[0].path  # names table to add row to

  test "declaration publishes every row, so no consumer parses this source":
    # Issue 134: project held law that its faces are declared by reading `assets.nim` as
    #   text. Published rows are contract that read was standing in for.
    let rows = declaration().strip.splitLines
    check rows.len == ASSETS.len  # every row, none extra
    for row in rows:
      let parts = row.split(' ')
      check parts.len == 2  # neither column holds space, so `split` is enough
      check parts[1].len == 64  # digest, rendered whole
      check parts[1] == parts[0].digestOf  # column two is what store declares for column one
      check parts[0].addressOf.len > 0  # column one names row store knows
    # Ends in newline, so appending or piping row-wise needs no special case.
    check declaration().endsWith("\n")
    # Proven by asking for one that is there: consumer checks membership without parsing.
    check "noto-serif-latin-600-normal.woff2 " in declaration()

  test "no declared row can be read as a path, which both project builds rely on":
    # Verb prints paths when files are named and rows when none are. Both contributor
    #   builds tell them apart by shape -- one keeps lines that `fileExists`, other keeps
    #   lines starting `/` -- so row that looked like absolute path would be copied as
    #   face by one and counted as served by other. Neither project can check this; store
    #   owns row shape, so store holds law.
    for row in declaration().strip.splitLines:
      check not row.startsWith('/')  # never absolute path
      check not row.fileExists  # nor relative one that happens to resolve
