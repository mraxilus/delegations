## Read which codepoints font face file maps, as browser reads its `cmap` (Article X.8).
##   One reader serves two callers: `font_stacks.nim`, which resolves characters of page for
##     every project through `koch resolve-font-faces`, and suite of `assets.nim`, which holds
##     each row of store to bytes of its file.
##   `woff2` keeps every table in one Brotli stream, and no Nim import decodes Brotli, so
##     `libbrotlidec` is loaded at run: codec is external concern (Article II.8). Loaded rather
##     than linked, so machine lacking it fails reader needing it, by name, rather than every
##     run of koch at start. `koch list-packages` declares `libbrotli1`.
##   Unicode subtable is platform `0` save encoding `5`, which maps variation sequences, and
##     platform `3` at encoding `1` or `10`. Formats `4` and `12` are read, which every font
##     face of store uses; other format raises rather than read short.
##   Codepoint counts as mapped where it reaches glyph other than `.notdef`, as browser draws
##     it. Control characters are left out, since none draws (`assets.nim` header).

{.experimental: "strictFuncs".}

import std/[dynlib, math, sequtils, strutils]


type DecodeBrotli = proc (
  size_encoded: csize_t, encoded: ptr uint8, size_decoded: ptr csize_t, decoded: ptr uint8
): cint {.cdecl, gcsafe.}
  ## Define `BrotliDecoderDecompress` of `libbrotlidec`: one-shot decode into sized buffer.


const
  LIBRARY_BROTLI = "libbrotlidec.so(|.1)"  ## Library `libbrotli1` installs, as `dynlib` names it.
  SIGNATURE_WOFF2 = "wOF2"  ## Bytes `woff2` file opens with; OpenType and TrueType open otherwise.
  FLAG_CMAP = 0  ## Known-tag index `woff2` directory gives `cmap`.
  FLAG_HMTX = 3  ## Known-tag index of `hmtx`, transformed at version `1`.
  FLAG_GLYF = 10  ## Known-tag index of `glyf`, transformed at version `0`.
  FLAG_LOCA = 11  ## Known-tag index of `loca`, transformed at version `0`.
  FLAG_ARBITRARY = 63  ## Index saying four-byte tag follows.
  CONTROL_MAX* = 0x1F
    ## Last control character below space; none draws, so codepoints read leave them out.
  CODEPOINT_COUNT = 0x110000  ## Codepoints Unicode defines, `0` to `10ffff`.


func uint16At(bytes: string, at: int): int =
  ## Read big-endian `uint16` at offset, as OpenType stores every integer.
  (bytes[at].ord shl 8) or bytes[at + 1].ord


func uint32At(bytes: string, at: int): int =
  ## Read big-endian `uint32` at offset.
  (bytes.uint16At(at) shl 16) or bytes.uint16At(at + 2)


proc decodeBrotli(encoded: string, size: int): string =
  ## Decode Brotli stream into exactly `size` bytes through `libbrotlidec`, loaded at run.
  let library = loadLibPattern(LIBRARY_BROTLI)
  if library.isNil:
    raise newException(
      IOError,
      "Reader decodes `woff2` through `libbrotlidec`; install `libbrotli1`; got `" &
        LIBRARY_BROTLI & "` unloadable.",
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


proc cmap*(bytes: string): string =
  ## Read `cmap` table out of OpenType, TrueType or `woff2` font face.

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
    raise newException(ValueError, "Font face holds no `cmap` table; got none.")

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
  raise newException(ValueError, "Font face holds no `cmap` table; got none.")


func codepoints*(cmap: string): seq[int] =
  ## Read every codepoint Unicode subtables of `cmap` map to glyph other than `.notdef`, sorted.
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
      # Segments: glyph is codepoint plus delta, or read through offset from its own place.
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
        "Font face maps Unicode through `cmap` format reader does not read; got `" &
          $cmap.uint16At(at) & "`.",
      )
  for codepoint in CONTROL_MAX + 1 ..< CODEPOINT_COUNT:
    if held[codepoint]: result.add codepoint
