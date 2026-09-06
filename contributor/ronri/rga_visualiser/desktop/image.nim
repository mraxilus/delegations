## Encode framebuffer readback as PNG file.
##
## PNG is written out by hand rather than pulled in as image library.
##   Format below compression is four length-tagged chunks.
##   Deflate and CRC come from zlib, codec worth depending on, already present wherever
##   OpenGL is.
##
##   |----------|---------------------------------------------------------------|
##   | Chunk    | Carries                                                       |
##   |----------|---------------------------------------------------------------|
##   | IHDR     | Width, height, 8 bits per channel, truecolour, no interlace.   |
##   | IDAT     | Zlib stream of scanlines, each prefixed by filter byte 0.      |
##   | IEND     | Nothing; marks end of file.                                   |
##   |----------|---------------------------------------------------------------|
##
## Rows arrive bottom-up, as OpenGL reads them, and are flipped while being filtered.
##   No separate copy of image exists.
## Two buffers proportional to image are carved from caller's frame arena per call.
##   Reclaimed when it is next reset.
##   Arena carving costs same fixed bound (`writePng` asserts instead of growing) in one
##   place caller owns.
##
## Desktop-only; unreachable from browser build. See `visualiser.nim`'s "Render Paths".

{.experimental: "strictFuncs".}

import std/[strformat, syncio]

import ./arena



#[ Binding Configuration ]#

const HEADER_ZLIB = "<zlib.h>"
  ## Name header compression and checksum are imported through.

# Link zlib here rather than in project config.
#   Every binary importing this module then links it, tests included.
{.passL: "-lz".}

type
  Byte = uint8 ## Mirror `Bytef`.
  Ulong = culong ## Mirror `uLong` and `uLongf`.
  Uint = cuint ## Mirror `uInt`.

# Import zlib entry points one to one; see zlib manual for each.
# Mark every binding `sideEffect`.
#   Compiler assumes imported body is pure, so `func` calling one would compile; marked,
#   only `proc` may reach effects, which is what makes `func` mean anything here.
proc compressBound(source_length: Ulong): Ulong
  {.importc: "compressBound", header: HEADER_ZLIB.}
  ## Report largest size `compress2` can produce for `source_length` bytes.

proc compress2(
  destination: ptr Byte, destination_length: ptr Ulong,
  source: ptr Byte, source_length: Ulong, level: cint
): cint {.importc: "compress2", header: HEADER_ZLIB, sideEffect.}
  ## Deflate `source_length` bytes into `destination` at `level`, writing size back.

proc crc32(crc: Ulong, buffer: ptr Byte, length: Uint): Ulong
  {.importc: "crc32", header: HEADER_ZLIB.}
  ## Fold `length` bytes at `buffer` into running CRC.



#[ Encoder Configuration ]#

const
  CHANNELS = 3
    ## Fix channel count, as encoder writes truecolour without alpha.
  LEVEL_COMPRESSION* {.define: "visualiser.level_compression".} = 6
    ## Set deflate effort, from 0 for stored to 9 for smallest.
  SIGNATURE_PNG = [137'u8, 80, 78, 71, 13, 10, 26, 10]
    ## Fix PNG's opening bytes, which identify format and catch mangled transfers.

static:
  doAssert LEVEL_COMPRESSION in 0 .. 9,
    &"Compression level must be in range 0..9; got `{LEVEL_COMPRESSION}`."



#[ Chunk Assembly ]#

func toBigEndian(value: uint32): array[4, uint8] =
  ## Split unsigned integer into PNG's byte order, most significant first.
  [uint8(value shr 24), uint8(value shr 16), uint8(value shr 8), uint8(value)]


proc writeChunk(file: File, name: string, payload: openArray[uint8]) =
  ## Write one length-tagged chunk, with checksum over name and payload.
  doAssert len(name) == 4, &"Chunk name must be 4 characters; got `{name}`."
  discard file.writeBytes(toBigEndian(uint32(len(payload))), 0, 4)
  discard file.writeChars(name, 0, 4)
  if len(payload) > 0:
    discard file.writeBytes(payload, 0, len(payload))

  # Checksum name and payload together, never length.
  var checksum = crc32(0, nil, 0)
  checksum = crc32(checksum, cast[ptr Byte](unsafeAddr name[0]), 4)
  if len(payload) > 0:
    checksum = crc32(checksum, unsafeAddr payload[0], Uint(len(payload)))
  discard file.writeBytes(toBigEndian(uint32(checksum)), 0, 4)



#[ Image Encoding ]#

proc writePng*(
  arena: var Arena; path: string; width, height: int; rows_bottom_up: openArray[uint8]
) =
  ## Write pixels as PNG file, flipping rows so image reads top-down.
  ##   `rows_bottom_up` holds tightly packed RGB triples, first row nearest bottom.
  ##   Both scratch buffers come from `arena`; caller resets it once this returns.
  doAssert width > 0 and height > 0,
    &"Image must have positive extent; got `{width}x{height}`."
  doAssert len(rows_bottom_up) >= width*height*CHANNELS,
    &"Readback holds {len(rows_bottom_up)} bytes, short of {width*height*CHANNELS}."

  # Filter every scanline with filter 0, which stores bytes as they stand.
  #   Cheapest, and deflate still finds most redundancy in flat-shaded frame.
  let
    stride = width*CHANNELS
    count_filtered = (stride + 1)*height
    filtered = push[uint8](arena, count_filtered)
  for row in 0 ..< height:
    let
      source = (height - 1 - row)*stride
      destination = row*(stride + 1) + 1
    for i in 0 ..< stride:
      filtered[destination + i] = rows_bottom_up[source + i]

  # Deflate whole filtered image in one call, since it is wholly in memory.
  let
    count_compressed_max = int(compressBound(Ulong(count_filtered)))
    compressed = push[uint8](arena, count_compressed_max)
  var count_compressed = Ulong(count_compressed_max)
  let status = compress2(
    addr compressed[0], addr count_compressed,
    addr filtered[0], Ulong(count_filtered), cint(LEVEL_COMPRESSION),
  )
  doAssert status == 0,
    &"Deflate of {count_filtered} bytes must succeed; got zlib status `{status}`."

  var header: array[13, uint8]
  header[0 .. 3] = toBigEndian(uint32(width))
  header[4 .. 7] = toBigEndian(uint32(height))
  header[8] = 8 # Bit depth.
  header[9] = 2 # Colour type: truecolour.

  let file = open(path, fmWrite)
  defer: file.close
  discard file.writeBytes(SIGNATURE_PNG, 0, len(SIGNATURE_PNG))
  file.writeChunk("IHDR", header)
  file.writeChunk("IDAT", compressed.toOpenArray(0, int(count_compressed) - 1))
  file.writeChunk("IEND", [])
