## Encode sequence of framebuffer readbacks as short looping animated GIF.
##
## GIF is written out by hand, as PNG is in `image.nim`.
##   Container below compression is handful of length- or count-tagged blocks.
##   GIF's compression is LZW rather than deflate, so no system codec carries it.
##   Encoder below is small enough to write directly, on same "depend only where
##   genuinely external" line `image.nim` draws.
## Every frame is quantized to one fixed colour cube, six levels per channel.
##   One integer divide per channel, no per-pixel palette search.
##   Runs only for storyboard's diagnostic capture, never in draw loop.
##
##   |-----------------------|-------------------------------------------------------|
##   | Block                 | Carries                                                |
##   |-----------------------|-------------------------------------------------------|
##   | Logical Screen        | Canvas size and one global colour table.              |
##   | Application Extension | `NETSCAPE2.0` loop-forever marker.                    |
##   | Graphic Control (each) | This frame's hold time.                               |
##   | Image Descriptor      | This frame's LZW-compressed, quantized pixels.        |
##   |-----------------------|-------------------------------------------------------|
##
## Rows arrive bottom-up, as OpenGL reads them, and are flipped while being quantized.
##   As `image.nim` flips them while filtering, so no separate copy exists.
## Every scratch buffer comes from caller-owned frame arena, or is fixed-capacity table
## reset per call.
##   Quantized indices, LZW dictionary, packed output; nothing calls allocator.
##
## Desktop-only; unreachable from browser build. See `visualiser.nim`'s "Render Paths".

{.experimental: "strictFuncs".}

import std/[options, strformat, syncio]

import ./arena



#[ Encoder Configuration ]#

const
  CHANNELS = 3
    ## Fix channel count; frames arrive as same tightly packed RGB triples PNG takes.
  LEVELS_PER_CHANNEL {.define: "visualiser.gif_levels_per_channel".} = 6
    ## Set how many evenly spaced samples each channel is quantized to.
  BITS_CODE = 8
    ## Fix LZW's root code size at 8 bits.
    ##   Global colour table is then simplest legal size, 256, regardless of how few
    ##   entries colour cube fills.
  COUNT_TABLE = 1 shl BITS_CODE
  COUNT_PALETTE = LEVELS_PER_CHANNEL*LEVELS_PER_CHANNEL*LEVELS_PER_CHANNEL
  CODE_CLEAR = COUNT_TABLE
  CODE_END = CODE_CLEAR + 1
  CODE_MAX = 4096
    ## Bound LZW dictionary size to what 12-bit code can name, as GIF's spec fixes.
  CAPACITY_DICT = 8192
    ## Set fixed hash table's slot count.
    ##   Power of two, comfortably above `CODE_MAX`, so linear probing stays cheap at load
    ##   factor that ever occurs.

static:
  doAssert LEVELS_PER_CHANNEL in 2 .. 6,
    &"Colour cube needs 2 to 6 levels per channel to fit 256 entries; got " &
    &"`{LEVELS_PER_CHANNEL}`."
  doAssert COUNT_PALETTE <= COUNT_TABLE,
    &"Colour cube must fit the global colour table; {COUNT_PALETTE} used of {COUNT_TABLE}."
  doAssert (CAPACITY_DICT and (CAPACITY_DICT - 1)) == 0,
    &"Dictionary capacity must be a power of two; got `{CAPACITY_DICT}`."
  doAssert CAPACITY_DICT > CODE_MAX,
    &"Dictionary capacity must exceed {CODE_MAX} live entries; got `{CAPACITY_DICT}`."



#[ Colour Quantization ]#

func levelToByte(level: int): uint8 =
  ## Map quantized level to channel sample spanning full 0..255 range.
  ##   Level runs 0 up to but under `LEVELS_PER_CHANNEL`, evenly spaced as "web-safe" cube
  ##   is.
  uint8((level * 255) div (LEVELS_PER_CHANNEL - 1))


func byteToLevel(value: uint8): int =
  ## Snap channel sample to nearest of `LEVELS_PER_CHANNEL` evenly spaced levels.
  (int(value)*(LEVELS_PER_CHANNEL - 1) + 127) div 255


func paletteIndex*(red, green, blue: uint8): uint8 =
  ## Quantize one pixel straight to its index in fixed colour cube.
  ##   Exported so test can compute same index written frame quantized to, independent
  ##   of decoding LZW stream.
  uint8(
    (byteToLevel(red)*LEVELS_PER_CHANNEL + byteToLevel(green))*LEVELS_PER_CHANNEL +
      byteToLevel(blue)
  )


func globalColorTable(): array[COUNT_TABLE*3, uint8] =
  ## Build one colour cube every frame is quantized against.
  ##   Entries beyond cube's `COUNT_PALETTE` stay black, and quantization never produces
  ##   their index.
  for index in 0 ..< COUNT_PALETTE:
    let
      level_blue = index mod LEVELS_PER_CHANNEL
      level_green = (index div LEVELS_PER_CHANNEL) mod LEVELS_PER_CHANNEL
      level_red = index div (LEVELS_PER_CHANNEL*LEVELS_PER_CHANNEL)
    result[index*3] = levelToByte(level_red)
    result[index*3 + 1] = levelToByte(level_green)
    result[index*3 + 2] = levelToByte(level_blue)



#[ LZW Dictionary ]#

type LzwDict = object ## Define map from (prefix code, next byte) to code.
  ## Fixed open-addressed table rather than heap-backed `Table`.
  ##   Capacity is `CODE_MAX` at format's limit, known at compile time, so nothing grows.
  keys_prefix: array[CAPACITY_DICT, int]
  keys_byte: array[CAPACITY_DICT, uint8]
  values: array[CAPACITY_DICT, int]
  are_used: array[CAPACITY_DICT, bool]


func hashKey(prefix: int, value: uint8): int =
  ## Spread (prefix, value) pairs over table.
  ##   Multiplier is Knuth's constant for multiplicative hashing, folded through `uint64`
  ##   so it never overflows.
  let combined = uint64(prefix)*2654435761'u64 xor uint64(value)
  int(combined and uint64(CAPACITY_DICT - 1))


func clear(dict: var LzwDict) =
  ## Empty every slot, in place; table itself is never reallocated.
  for i in 0 ..< CAPACITY_DICT: dict.are_used[i] = false


func find(dict: LzwDict, prefix: int, value: uint8): Option[int] =
  ## Look up code (prefix, value) was assigned; none where it has none yet.
  var index = hashKey(prefix, value)
  while dict.are_used[index]:
    if dict.keys_prefix[index] == prefix and dict.keys_byte[index] == value:
      return some(dict.values[index])
    index = (index + 1) and (CAPACITY_DICT - 1)
  none(int)


func insert(dict: var LzwDict, prefix: int, value: uint8, code: int) =
  ## Assign (prefix, value) fresh code; caller has confirmed it has none.
  var index = hashKey(prefix, value)
  while dict.are_used[index]: index = (index + 1) and (CAPACITY_DICT - 1)
  dict.are_used[index] = true
  dict.keys_prefix[index] = prefix
  dict.keys_byte[index] = value
  dict.values[index] = code



#[ LZW Compression ]#

type BitWriter = object ## Define packer of variable-width codes into caller-owned storage.
  ## Least significant bit first, tracking only how much is in use.
  buffer: ptr UncheckedArray[uint8]
  capacity: int
  count: int
  pending: uint32
  count_pending: int


proc packCode(writer: var BitWriter; code, width: int) =
  ## Append `code`, `width` bits wide, as GIF's LZW packs them.
  writer.pending = writer.pending or (uint32(code) shl writer.count_pending)
  writer.count_pending += width
  while writer.count_pending >= 8:
    doAssert writer.count < writer.capacity,
      &"LZW output must fit its reservation of {writer.capacity} bytes; got `{writer.count}`."
    writer.buffer[writer.count] = uint8(writer.pending and 0xFF)
    inc writer.count
    writer.pending = writer.pending shr 8
    writer.count_pending -= 8


proc flushBits(writer: var BitWriter) =
  ## Emit whatever partial byte remains, padded with zero bits above it.
  if writer.count_pending > 0:
    doAssert writer.count < writer.capacity,
      &"LZW output must fit its reservation of {writer.capacity} bytes; got `{writer.count}`."
    writer.buffer[writer.count] = uint8(writer.pending and 0xFF)
    inc writer.count
    writer.pending = 0
    writer.count_pending = 0


proc lzwEncode(
  arena: var Arena, dict: var LzwDict, indices: openArray[uint8]
): BitWriter =
  ## Compress quantized pixel indices with GIF's variable-width LZW.
  ##   Root codes 0 ..< `COUNT_TABLE` are palette indices; clear and end codes follow, and
  ##   every invented code follows those.
  ##   Output is reserved at double input plus slack: LZW never expands data this
  ##   repetitive by more than occasional wider code.
  dict.clear()
  let capacity_output = 2*len(indices) + 256
  var
    writer = BitWriter(buffer: push[uint8](arena, capacity_output), capacity: capacity_output)
    next_code = CODE_END + 1
    width_code = BITS_CODE + 1
    code_current = none(int)

  writer.packCode(CODE_CLEAR, width_code)
  for value in indices:
    if code_current.isNone:
      code_current = some(int(value))
      continue
    let existing = dict.find(code_current.get, value)
    if existing.isSome:
      code_current = existing
      continue

    writer.packCode(code_current.get, width_code)
    if next_code < CODE_MAX:
      dict.insert(code_current.get, value, next_code)
      inc next_code
      # Widen one step later than naive "table is now full" reading.
      #   Code 2^width_code still fits current width, so only code after that forces
      #   growth.
      if next_code > (1 shl width_code) and width_code < 12: inc width_code
    else:
      writer.packCode(CODE_CLEAR, width_code)
      dict.clear()
      next_code = CODE_END + 1
      width_code = BITS_CODE + 1
    code_current = some(int(value))

  if code_current.isSome: writer.packCode(code_current.get, width_code)
  writer.packCode(CODE_END, width_code)
  writer.flushBits()
  writer



#[ Block Assembly ]#

func toLittleEndian16(value: uint16): array[2, uint8] =
  ## Split unsigned integer into GIF's byte order, least significant first.
  [uint8(value and 0xFF), uint8(value shr 8)]


proc writeSubBlocks(file: File, data: openArray[uint8]) =
  ## Write compressed stream as GIF's length-prefixed sub-blocks.
  ##   At most 255 bytes each, terminated by zero-length block.
  var offset = 0
  while offset < len(data):
    let count = min(255, len(data) - offset)
    file.write(char(count))
    discard file.writeBytes(data, offset, count)
    offset += count
  file.write(char(0))


proc writeFrame(
  file: File; arena: var Arena; dict: var LzwDict;
  width, height: int; row_bottom_up: openArray[uint8]; centiseconds_delay: int
) =
  ## Write one frame's Graphic Control Extension and Image Descriptor.
  ##   Every scratch buffer comes from `arena`; caller resets it once this returns.
  let delay = toLittleEndian16(uint16(centiseconds_delay))
  discard file.writeBytes([0x21'u8, 0xF9, 0x04, 0x00, delay[0], delay[1], 0x00, 0x00], 0, 8)

  let (w, h) = (toLittleEndian16(uint16(width)), toLittleEndian16(uint16(height)))
  discard file.writeBytes([0x2C'u8, 0, 0, 0, 0, w[0], w[1], h[0], h[1], 0x00], 0, 10)

  # Quantize while flipping, so no separate right-side-up copy of frame exists.
  let indices = push[uint8](arena, width*height)
  for row in 0 ..< height:
    let
      source = (height - 1 - row)*width*CHANNELS
      destination = row*width
    for column in 0 ..< width:
      let at = source + column*CHANNELS
      indices[destination + column] =
        paletteIndex(row_bottom_up[at], row_bottom_up[at + 1], row_bottom_up[at + 2])

  let compressed = lzwEncode(arena, dict, indices.toOpenArray(0, width*height - 1))
  file.write(char(BITS_CODE))
  file.writeSubBlocks(compressed.buffer.toOpenArray(0, compressed.count - 1))



#[ Animation Encoding ]#

proc writeGif*(
  arena: var Arena; path: string; width, height: int;
  frames_bottom_up: openArray[uint8]; count_frames: int; centiseconds_delay: int
) =
  ## Write `count_frames` frames as one looping animated GIF, flipping rows to read top-down.
  ##   `frames_bottom_up` holds every frame back to back, each same tightly packed RGB
  ##   triples `capturePixels` reads and `writePng` takes.
  ##   Every scratch buffer comes from `arena`; caller resets it once this returns.
  doAssert width > 0 and height > 0,
    &"Image must have positive extent; got `{width}x{height}`."
  doAssert count_frames > 0, "Animated GIF needs at least one frame."
  doAssert centiseconds_delay > 0,
    &"Hold time must be positive; got `{centiseconds_delay}` centiseconds."
  let frame_size = width*height*CHANNELS
  doAssert len(frames_bottom_up) >= count_frames*frame_size,
    &"Frames hold {len(frames_bottom_up)} bytes, short of {count_frames*frame_size}."

  let file = open(path, fmWrite)
  defer: file.close

  discard file.writeChars("GIF89a", 0, 6)
  let (w, h) = (toLittleEndian16(uint16(width)), toLittleEndian16(uint16(height)))
  discard file.writeBytes([w[0], w[1], h[0], h[1], 0xF7'u8, 0, 0], 0, 7)
  let table = globalColorTable()
  discard file.writeBytes(table, 0, len(table))

  # Loop forever through Application Extension, as still storyboard is poor animated one.
  discard file.writeChars("!\xFF\x0BNETSCAPE2.0\x03\x01\x00\x00\x00", 0, 19)

  var dict: LzwDict
  for index in 0 ..< count_frames:
    file.writeFrame(
      arena, dict, width, height,
      frames_bottom_up.toOpenArray(index*frame_size, (index + 1)*frame_size - 1),
      centiseconds_delay,
    )
    arena.reset()

  file.write(char(0x3B)) # Trailer.
