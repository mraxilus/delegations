## Replicate shared store of `assets.nim` header, i.e. one declaration, keyed by digest.
##   Codepoints each face row carries are held to bytes of its file: suite reads `cmap` itself,
##     as browser reads it, i.e. codepoint maps to glyph other than `.notdef`. Reader is
##     suite's alone (Article IX.11), since static pass reads rows and never bytes.
##   Sibling: `cmapOf` of `contributor/ronri/rga_visualiser/tools/drive/faces.ts` reads same
##     tables for one page, in TypeScript and inside contributor project, which curator never
##     imports (Article II.9). Fix to either is finished once other is checked.
##   `woff2` keeps every table in one Brotli stream, and no Nim import decodes Brotli, so
##     `libbrotlidec` is loaded at run: codec is external concern (Article II.8). Loaded rather
##     than linked, so machine lacking it fails test needing it, by name, rather than every
##     suite at start. `koch list-packages` declares `libbrotli1`.
##   Cost: test fetches each face store lacks, so cold store needs network and about 6 MB.

{.experimental: "strictFuncs".}

import std/[dynlib, math, os, sequtils, strutils, unittest]
import ../../src/assets
from ../../../knoller/src/knoller import DIRECTORY_CACHE


type DecodeBrotli = proc (
  size_encoded: csize_t, encoded: ptr uint8, size_decoded: ptr csize_t, decoded: ptr uint8
): cint {.cdecl, gcsafe.}
  ## Define `BrotliDecoderDecompress` of `libbrotlidec`: one-shot decode into sized buffer.


const
  BROTLI_LIBRARY = "libbrotlidec.so(|.1)"  ## Library `libbrotli1` installs, as `dynlib` names it.
  SIGNATURE_WOFF2 = "wOF2"  ## Bytes `woff2` file opens with; OpenType and TrueType open otherwise.
  FLAG_CMAP = 0  ## Known-tag index `woff2` directory gives `cmap`.
  FLAG_HMTX = 3  ## Known-tag index of `hmtx`, transformed at version `1`.
  FLAG_GLYF = 10  ## Known-tag index of `glyf`, transformed at version `0`.
  FLAG_LOCA = 11  ## Known-tag index of `loca`, transformed at version `0`.
  FLAG_ARBITRARY = 63  ## Index saying four-byte tag follows.
  CONTROL_MAX = 0x1F  ## Last control character below space; none draws, so ranges leave them out.
  CODEPOINT_COUNT = 0x110000  ## Codepoints Unicode defines, `0` to `10ffff`.


func uint16At(bytes: string, at: int): int =
  ## Read big-endian `uint16` at offset, as OpenType stores every integer.
  (bytes[at].ord shl 8) or bytes[at + 1].ord


func uint32At(bytes: string, at: int): int =
  ## Read big-endian `uint32` at offset.
  (bytes.uint16At(at) shl 16) or bytes.uint16At(at + 2)


proc decodeBrotli(encoded: string, size: int): string =
  ## Decode Brotli stream into exactly `size` bytes through `libbrotlidec`, loaded at run.
  let library = loadLibPattern(BROTLI_LIBRARY)
  if library.isNil:
    raise newException(
      IOError,
      "Suite decodes `woff2` through `libbrotlidec`; install `libbrotli1`; got `" &
        BROTLI_LIBRARY & "` unloadable.",
    )
  defer: library.unloadLib
  let decode = cast[DecodeBrotli](library.symAddr("BrotliDecoderDecompress"))
  result = newString(size)
  var decoded = csize_t(size)
  let status = decode(
    csize_t(encoded.len),
    cast[ptr uint8](cstring(encoded)),
    decoded.addr,
    cast[ptr uint8](result[0].addr),
  )
  if status != 1 or int(decoded) != size:
    raise newException(
      IOError,
      "Brotli stream decodes short of size its directory declares; got `" & $decoded &
        "` bytes and status `" & $status & "`.",
    )


proc cmapOf(bytes: string): string =
  ## Read `cmap` table out of OpenType, TrueType or `woff2` face.

  func base128(bytes: string, at: var int): int =
    ## Read `UIntBase128` at offset, seven bits to byte while high bit is set, and step past it.
    for _ in 1 .. 5:
      let byte = bytes[at].ord
      inc at
      result = (result shl 7) or (byte and 0x7F)
      if (byte and 0x80) == 0: return
    raise newException(ValueError, "`UIntBase128` runs past five bytes; got `" & $result & "`.")

  # Table directory of OpenType and TrueType names offset and length of each table.
  if not bytes.startsWith(SIGNATURE_WOFF2):
    for i in 0 ..< bytes.uint16At(4):
      let record = 12 + 16 * i
      if bytes[record ..< record + 4] == "cmap":
        let at = bytes.uint32At(record + 8)
        return bytes[at ..< at + bytes.uint32At(record + 12)]
    raise newException(ValueError, "Face holds no `cmap` table; got none.")

  # `woff2` directory gives length each table takes in stream: transformed length where table
  #   is transformed, else its own. `cmap` never is, so its bytes stand in stream as stored.
  var
    at = 48
    tables: seq[tuple[is_cmap: bool, length: int]]
  for _ in 0 ..< bytes.uint16At(12):
    let
      flags = bytes[at].ord
      known = flags and 0x3F
    inc at
    var tag = ""
    if known == FLAG_ARBITRARY:
      tag = bytes[at ..< at + 4]
      at += 4
    let
      version = flags shr 6
      length = bytes.base128(at)
      is_transformed =
        (known in [FLAG_GLYF, FLAG_LOCA] and version == 0) or (known == FLAG_HMTX and version == 1)
      stored = if is_transformed: bytes.base128(at) else: length
    tables.add (known == FLAG_CMAP or tag == "cmap", stored)

  # Decode stream whole, since tables standing before `cmap` fix where it starts.
  let stream = bytes[at ..< at + bytes.uint32At(20)].decodeBrotli(tables.mapIt(it.length).sum)
  var offset = 0
  for table in tables:
    if table.is_cmap: return stream[offset ..< offset + table.length]
    offset += table.length
  raise newException(ValueError, "Face holds no `cmap` table; got none.")


func codepointsOf(cmap: string): seq[int] =
  ## Read every codepoint Unicode subtables of `cmap` map to glyph other than `.notdef`, sorted.
  ##   Unicode subtable is platform `0` save encoding `5`, which maps variation sequences, and
  ##   platform `3` at encoding `1` or `10`. Formats `4` and `12` are read, which every face of
  ##   store uses; other format raises rather than read short.
  ##   Control characters are left out, since none draws (`assets.nim` header).
  var held = newSeq[bool](CODEPOINT_COUNT)
  for i in 0 ..< cmap.uint16At(2):
    let
      record = 4 + 8 * i
      (platform, encoding) = (cmap.uint16At(record), cmap.uint16At(record + 2))
      at = cmap.uint32At(record + 4)
    if not ((platform == 0 and encoding != 5) or (platform == 3 and encoding in [1, 10])):
      continue
    case cmap.uint16At(at)
    of 4:
      # Segments: glyph is codepoint plus delta, or read through offset from its own slot.
      let
        count = cmap.uint16At(at + 6) div 2
        ends = at + 14
        starts = ends + 2 * count + 2
        deltas = starts + 2 * count
        offsets = deltas + 2 * count
      for segment in 0 ..< count:
        let
          start = cmap.uint16At(starts + 2 * segment)
          delta = cmap.uint16At(deltas + 2 * segment)
          offset = cmap.uint16At(offsets + 2 * segment)
        for codepoint in start .. cmap.uint16At(ends + 2 * segment):
          var glyph = (codepoint + delta) and 0xFFFF
          if offset != 0:
            glyph = cmap.uint16At(offsets + 2 * segment + offset + 2 * (codepoint - start))
            if glyph != 0: glyph = (glyph + delta) and 0xFFFF
          if glyph != 0: held[codepoint] = true
    of 12:
      # Groups: run of codepoints onto run of glyphs.
      for group in 0 ..< cmap.uint32At(at + 12):
        let
          entry = at + 16 + 12 * group
          start = cmap.uint32At(entry)
          glyph = cmap.uint32At(entry + 8)
        for codepoint in start .. cmap.uint32At(entry + 4):
          if glyph + codepoint - start != 0: held[codepoint] = true
    else:
      raise newException(
        ValueError,
        "Face maps Unicode through `cmap` format suite does not read; got `" &
          $cmap.uint16At(at) & "`.",
      )
  for codepoint in CONTROL_MAX + 1 ..< CODEPOINT_COUNT:
    if held[codepoint]: result.add codepoint


func toSlices(codepoints: seq[int]): seq[Slice[int]] =
  ## Merge sorted codepoints into runs, one slice each.
  for codepoint in codepoints:
    if result.len > 0 and result[^1].b + 1 == codepoint: result[^1].b = codepoint
    else: result.add codepoint .. codepoint


func toText(ranges: seq[Slice[int]]): string =
  ## Render ranges as row spells them: lowercase hex, `low-high` or lone `low`, space apart.

  func hexOf(codepoint: int): string =
    ## Render codepoint in lowercase hex, no leading zero.
    codepoint.toHex.strip(trailing = false, chars = {'0'}).toLowerAscii

  var tokens: seq[string]
  for bounds in ranges:
    tokens.add(
      if bounds.a == bounds.b: bounds.a.hexOf else: bounds.a.hexOf & "-" & bounds.b.hexOf
    )
  tokens.join(" ")



suite "Assets":
  test "store lies outside repository, and override wins":
    check storeRoot("/tmp/assets") == "/tmp/assets"
    check storeRoot("").endsWith(ASSETS_DIRECTORY)
    # Audit reads untracked files, so store inside checkout would be audited.
    check not storeRoot("").startsWith(".")
    check ASSETS_DIRECTORY.parentDir == ".cache/koch"  # store is koch's own
    check DIRECTORY_CACHE.parentDir == ".cache/knoller"  # compiler cache is knoller's, koch uses it


  test "asset is stored under its digest, never under its name":
    # Two projects asking for one face share one entry by construction, and moved pin is
    #   different entry rather than stale one.
    const face = "NotoSans-Regular.ttf"
    let digest = face.declaredDigest
    check pathOf("/s", face) == "/s" / digest
    check face notin pathOf("/s", face)  # name is nowhere in path
    check pathOf("/s", "not-a-face.woff2").len == 0  # undeclared face has no path


  test "address carries version, so bytes and version move together or neither":
    const face = "commit-mono-latin-700-normal.woff2"
    let address = face.addressOf
    check address.startsWith("https://")
    check address.endsWith(face)
    check "@fontsource/commit-mono@" in address  # package and its version, in address
    check addressOf("not-a-face.woff2").len == 0


  test "TrueType comes from Noto's own repository, since fontsource ships none":
    # Atlas reads TrueType and `@fontsource` packages `woff2` alone, so desktop faces have
    #   their own upstream; store holds both rather than one project holding each.
    check "notofonts" in "NotoSans-Regular.ttf".addressOf
    check "notofonts" in "NotoSansMath-Regular.ttf".addressOf
    check "commit-mono" in "CommitMonoV142-400Regular.otf".addressOf  # its author's own
    check "fontsource" in "commit-mono-latin-400-normal.woff2".addressOf


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
    # Projects wanting one face share its row, so one digest serves each of them, which is
    #   Article II.9's own test. These five are what every page project draws.
    for file in [
      "commit-mono-latin-400-normal.woff2", "NotoSans-Regular.ttf", "NotoSans-SemiBold.ttf",
      "NotoSansMath-Regular.ttf", "NotoSerif-SemiBold.ttf",
    ]:
      check file.declaredDigest.len == 64
    # And what only one of them wants, so none loses face by sharing one table.
    check "NotoSerif-Italic.ttf".declaredDigest.len == 64  # dance_ontology alone
    check "CommitMonoV142-400Regular.otf".declaredDigest.len == 64  # rga_visualiser alone


  test "each Noto face a page draws is declared whole (Article X.8)":
    # Noto was chosen so that no character of page falls outside its faces, and subset undoes
    #   that; so every Noto face pages draw has its whole TrueType file here.
    for file in [
      "NotoSans-Regular.ttf", "NotoSans-SemiBold.ttf", "NotoSansMath-Regular.ttf",
      "NotoSansSymbols2-Regular.ttf", "NotoSerif-Italic.ttf", "NotoSerif-Regular.ttf",
      "NotoSerif-SemiBold.ttf",
    ]:
      check file.declaredDigest.len == 64


  test "no row declares Noto subset, while Commit Mono keeps its own (Article X.8)":
    # Store declaring no Noto subset is what stops page shipping one: `fetch-assets` refuses
    #   any file no row declares. Commit Mono is no Noto, and pages draw its Latin subset.
    for (file, prefix, _, _) in ASSETS:
      if file.toLowerAscii.startsWith("noto"):
        check file.endsWith(".ttf")  # whole TrueType, never `woff2` subset (Article X.8)
        check "notofonts" in prefix  # Noto's own release, never `@fontsource` (Article X.8)
    for file in ["commit-mono-latin-400-normal.woff2", "commit-mono-latin-700-normal.woff2"]:
      check file.declaredDigest.len == 64  # X.8 binds Noto alone (Article X.8)


  test "asset nobody declared is finding naming what was asked for":
    let found = unknown("fraunces-latin-400-normal.woff2")
    check found.len == 1
    check found[0].message.endsWith("got `fraunces-latin-400-normal.woff2`.")
    check "assets.nim" in found[0].path  # names table to add row to


  test "declaration publishes every row, so no consumer parses this source":
    # Project holding law that its faces are declared reads these rows, never `assets.nim`
    #   as text: published rows are contract such read stands in for.
    let rows = declaration().strip.splitLines
    check rows.len == ASSETS.len  # every row, none extra
    for row in rows:
      let parts = row.split(' ')
      check parts.len == 2  # neither column holds space, so `split` is enough
      check parts[1].len == 64  # digest, rendered whole
      check parts[1] == parts[0].declaredDigest  # column two is what store declares for column one
      check parts[0].addressOf.len > 0  # column one names row store knows
    # Ends in newline, so appending or piping row-wise needs no special case.
    check declaration().endsWith("\n")
    # Proven by asking for one that is there: consumer checks membership without parsing.
    check "NotoSerif-SemiBold.ttf " in declaration()


  test "no declared row can be read as a path, which both project builds rely on":
    # Verb prints paths when files are named and rows when none are. Both contributor
    #   builds tell them apart by shape -- one keeps lines that `fileExists`, other keeps
    #   lines starting `/` -- so row that looked like absolute path would be copied as
    #   face by one and counted as served by other. Neither project can check this; store
    #   owns row shape, so store holds law.
    for row in declaration().strip.splitLines:
      check not row.startsWith('/')  # never absolute path
      check not row.fileExists  # nor relative one that happens to resolve


  test "each face row carries codepoints its file maps, read from its bytes (Article X.8)":
    # Coverage check reads rows and never bytes, so rows say what bytes hold. Face store lacks
    #   is fetched once; store keeps it under its digest, and later run reads it in place.
    let root = storeRoot(getEnv(ASSETS_KEY))
    for (file, _, _, ranges) in ASSETS:
      let path = assetIn(root, file)
      check path.len > 0  # fetched, and digest held
      if path.len == 0: continue
      let read = readFile(path).cmapOf.codepointsOf.toSlices.toText
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
