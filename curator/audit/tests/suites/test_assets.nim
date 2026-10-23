## Replicate shared store of `assets.nim` header, i.e. one declaration, keyed by digest.
##   Codepoints each font face row carries are held to bytes of its file, read through
##     `font_files.nim` as browser reads them, i.e. codepoint maps to glyph other than `.notdef`.
##     Static pass reads rows and never bytes, so suite alone reads bytes of store.
##   Cost: test fetches each font face store lacks, so cold store needs network and about 6 MB.

{.experimental: "strictFuncs".}

import std/[os, strutils, unittest]
import ../../src/[assets, font_files]
from ../../../knoller/src/knoller import DIRECTORY_CACHE


func toSlices(codepoints: seq[int]): seq[Slice[int]] =
  ## Merge sorted codepoints into runs, one slice each.
  for codepoint in codepoints:
    if result.len > 0 and result[^1].b + 1 == codepoint: result[^1].b = codepoint
    else: result.add codepoint .. codepoint


func toText(ranges: seq[Slice[int]]): string =
  ## Render ranges as row spells them: lowercase hex, `low-high` or lone `low`, space apart.

  func toHexLower(codepoint: int): string =
    ## Render codepoint in lowercase hex, no leading zero.
    codepoint.toHex.strip(trailing = false, chars = {'0'}).toLowerAscii

  var tokens: seq[string]
  for bounds in ranges:
    tokens.add(
      if bounds.a == bounds.b: bounds.a.toHexLower
      else: bounds.a.toHexLower & "-" & bounds.b.toHexLower
    )
  tokens.join(" ")



suite "Assets":
  test "store lies outside repository, and override wins":
    check rootStore("/tmp/assets") == "/tmp/assets"
    check rootStore("").endsWith(DIRECTORY_ASSETS)
    # Audit reads untracked files, so store inside checkout would be audited.
    check not rootStore("").startsWith(".")
    check DIRECTORY_ASSETS.parentDir == ".cache/koch"  # store is koch's own
    check DIRECTORY_CACHE.parentDir == ".cache/knoller"  # compiler cache is knoller's, koch uses it


  test "asset is stored under its digest, never under its name":
    # Two projects asking for one font face share one entry by construction, and moved pin is
    #   different entry rather than stale one.
    const font_face = "NotoSans-Regular.ttf"
    let digest = font_face.digestDeclared
    check pathStore("/s", font_face) == "/s" / digest
    check font_face notin pathStore("/s", font_face)  # name is nowhere in path
    check pathStore("/s", "not-a-font-face.woff2").len == 0  # undeclared font face has no path


  test "address carries version, so bytes and version move together or neither":
    const font_face = "commit-mono-latin-700-normal.woff2"
    let address = font_face.address
    check address.startsWith("https://")
    check address.endsWith(font_face)
    check "@fontsource/commit-mono@" in address  # package and its version, in address
    check address("not-a-font-face.woff2").len == 0


  test "TrueType comes from Noto's own repository, since fontsource ships none":
    # Atlas reads TrueType and `@fontsource` packages `woff2` alone, so desktop font faces have
    #   their own upstream; store holds both rather than one project holding each.
    check "notofonts" in "NotoSans-Regular.ttf".address
    check "notofonts" in "NotoSansMath-Regular.ttf".address
    check "commit-mono" in "CommitMonoV142-400Regular.otf".address  # its author's own
    check "fontsource" in "commit-mono-latin-400-normal.woff2".address


  test "every row is one file, one address and one digest of sixty-four hex digits":
    var files: seq[string]
    for (file, prefix, digest, _) in ASSETS:
      check file.len > 0
      check file notin files  # nothing declared twice, which is what store exists to stop
      files.add file
      check prefix.startsWith("https://")
      check prefix.endsWith("/")  # prefix is directory; file is appended to it
      check digest.len == 64
      for c in digest: check c in {'0' .. '9', 'a' .. 'f'}


  test "store holds what projects share, once, and what one project alone wants":
    # Projects wanting one font face share its row, so one digest serves each of them, which is
    #   Article II.9's own test. These five are what every page project draws.
    for file in [
      "commit-mono-latin-400-normal.woff2", "NotoSans-Regular.ttf", "NotoSans-SemiBold.ttf",
      "NotoSansMath-Regular.ttf", "NotoSerif-SemiBold.ttf",
    ]:
      check file.digestDeclared.len == 64
    # And what only one of them wants, so none loses font face by sharing one table.
    check "NotoSerif-Italic.ttf".digestDeclared.len == 64  # dance_ontology alone
    check "CommitMonoV142-400Regular.otf".digestDeclared.len == 64  # pga_visualiser alone


  test "each Noto font face a page draws is declared whole (Article X.8)":
    # Noto was chosen so that no character of page falls outside its font faces, and subset undoes
    #   that; so every Noto font face pages draw has its whole TrueType file here.
    for file in [
      "NotoSans-Regular.ttf", "NotoSans-SemiBold.ttf", "NotoSansMath-Regular.ttf",
      "NotoSansSymbols2-Regular.ttf", "NotoSerif-Italic.ttf", "NotoSerif-Regular.ttf",
      "NotoSerif-SemiBold.ttf",
    ]:
      check file.digestDeclared.len == 64


  test "no row declares Noto subset, while Commit Mono keeps its own (Article X.8)":
    # Store declaring no Noto subset is what stops page shipping one: `fetch-assets` refuses
    #   any file no row declares. Commit Mono is no Noto, and pages draw its Latin subset.
    for (file, prefix, _, _) in ASSETS:
      if file.toLowerAscii.startsWith("noto"):
        check file.endsWith(".ttf")  # whole TrueType, never `woff2` subset (Article X.8)
        check "notofonts" in prefix  # Noto's own release, never `@fontsource` (Article X.8)
    for file in ["commit-mono-latin-400-normal.woff2", "commit-mono-latin-700-normal.woff2"]:
      check file.digestDeclared.len == 64  # X.8 binds Noto alone (Article X.8)


  test "asset nobody declared is finding naming what was asked for":
    let found = unknown("fraunces-latin-400-normal.woff2")
    check found.len == 1
    check found[0].message.endsWith("got `fraunces-latin-400-normal.woff2`.")
    check "assets.nim" in found[0].path  # names table to add row to


  test "declaration publishes every row, so no consumer parses this source":
    # Project holding law that its font faces are declared reads these rows, never `assets.nim`
    #   as text: published rows are contract such read stands in for.
    let rows = declaration().strip.splitLines
    check rows.len == ASSETS.len  # every row, none extra
    for row in rows:
      let parts = row.split(' ')
      check parts.len == 2  # neither column holds space, so `split` is enough
      check parts[1].len == 64  # digest, rendered whole
      check parts[1] == parts[0].digestDeclared  # column two is what store declares for column one
      check parts[0].address.len > 0  # column one names row store knows
    # Ends in newline, so appending or piping row-wise needs no special case.
    check declaration().endsWith("\n")
    # Proven by asking for one that is there: consumer checks membership without parsing.
    check "NotoSerif-SemiBold.ttf " in declaration()


  test "no declared row can be read as a path, which both project builds rely on":
    # Verb prints paths when files are named and rows when none are. Both contributor
    #   builds tell them apart by shape -- one keeps lines that `fileExists`, other keeps
    #   lines starting `/` -- so row that looked like absolute path would be copied as
    #   font face by one and counted as served by other. Neither project can check this; store
    #   owns row shape, so store holds law.
    for row in declaration().strip.splitLines:
      check not row.startsWith('/')  # never absolute path
      check not row.fileExists  # nor relative one that happens to resolve


  test "each font face row carries codepoints its file maps, read from its bytes (Article X.8)":
    # Coverage check reads rows and never bytes, so rows say what bytes hold. Font face store lacks
    #   is fetched once; store keeps it under its digest, and later run reads it in place.
    let root = rootStore(getEnv(KEY_ASSETS))
    for (file, _, _, ranges) in ASSETS:
      let path = assetIn(root, file)
      check path.len > 0  # fetched, and digest held
      if path.len == 0: continue
      let read = readFile(path).cmap.codepoints.toSlices.toText
      if read != ranges: checkpoint "Row of `" & file & "` spells what its bytes do not map."
      check read == ranges  # row spells what `cmap` maps; `read` is text row takes (Article X.8)


  test "ranges read as row spells them, sorted and apart, and render back to same text":
    check "20-7e a0 2190-2195".toRanges == @[0x20 .. 0x7E, 0xA0 .. 0xA0, 0x2190 .. 0x2195]
    for (_, _, _, ranges) in ASSETS:
      let read = ranges.toRanges
      check read.toText == ranges  # one spelling for each set
      check read[0].a > CONTROL_MAX  # no control character (`assets.nim` header)
      for i in 1 ..< read.len:
        check read[i - 1].b + 1 < read[i].a  # sorted, and runs merged
