## Run `Image` suite: one module of shared suite, which `../suites.nim` imports in order.

import ./fixtures


# PNG and GIF encoding, and arena backing both, are desktop-only: each binds C.
#   entry point JS backend has none of, so these run on that backend alone.
when not defined(js):
  suite "Image":
    var buffer_arena: array[1024*1024, byte]

    test "written file is a PNG carrying the size it was given":
      const (WIDTH, HEIGHT) = (37, 21)
      var pixels = newSeq[uint8](WIDTH*HEIGHT*3)
      for i in 0 ..< len(pixels): pixels[i] = uint8((i*7) mod 256)

      var test_arena = initArena(buffer_arena)
      let path = getTempDir() / "visualiser_suite.png"
      writePng(test_arena, path, WIDTH, HEIGHT, pixels)
      defer: removeFile(path)
      let document = readFile(path)

      check len(document) > 8
      check document[0 .. 7] == "\x89PNG\r\n\x1A\n"
      check document[12 .. 15] == "IHDR"
      check document[16 .. 19] == "\0\0\0" & char(WIDTH)
      check document[20 .. 23] == "\0\0\0" & char(HEIGHT)
      check document[24] == char(8) # Bit depth.
      check document[25] == char(2) # Colour type: truecolour.
      check document.find("IDAT") > 0
      check document[^8 .. ^5] == "IEND"


    test "chunk lengths and checksums agree end to end":
      const (WIDTH, HEIGHT) = (16, 9)
      var pixels = newSeq[uint8](WIDTH*HEIGHT*3)
      var test_arena = initArena(buffer_arena)
      let path = getTempDir() / "visualiser_suite_chunks.png"
      writePng(test_arena, path, WIDTH, HEIGHT, pixels)
      defer: removeFile(path)
      let document = readFile(path)

      # Walk chunks by their own lengths; landing exactly on end proves each is sound.
      var
        offset = 8
        names: seq[string]
      while offset < len(document):
        var length = 0
        for i in 0 .. 3: length = length*256 + int(uint8(document[offset + i]))
        names.add(document[offset + 4 .. offset + 7])
        offset += 12 + length
      check offset == len(document)
      check names == @["IHDR", "IDAT", "IEND"]



  suite "Gif":
    var buffer_arena: array[1024*1024, byte]

    test "written file carries the size and frame count it was given":
      const (WIDTH, HEIGHT) = (12, 8)
      var frames = newSeq[uint8](3*WIDTH*HEIGHT*3)
      var test_arena = initArena(buffer_arena)
      let path = getTempDir() / "visualiser_suite.gif"
      writeGif(test_arena, path, WIDTH, HEIGHT, frames, 3, 8)
      defer: removeFile(path)
      let document = readFile(path)

      check document[0 .. 5] == "GIF89a"
      check uint8(document[6]) == uint8(WIDTH) and uint8(document[7]) == 0
      check uint8(document[8]) == uint8(HEIGHT) and uint8(document[9]) == 0
      check document[^1] == char(0x3B)

      # Walk every frame's own blocks by their own lengths, landing exactly on.
      #   trailer proves each frame's sub-blocks are sound, exactly as PNG test does.
      # Signature, logical screen, colour table, application extension.
      const HEADER_LEN = 6 + 7 + 256*3 + 19
      var
        offset = HEADER_LEN
        count_frames = 0
      while document[offset] == '\x21':
        offset += 8 # Graphic Control Extension is fixed length.
        check document[offset] == '\x2C' # Image Descriptor.
        offset += 10 + 1 # Image Descriptor fields, then LZW minimum code size byte.
        while true:
          let length = int(uint8(document[offset]))
          offset += 1
          if length == 0: break
          offset += length
        inc count_frames
      check count_frames == 3
      check offset == len(document) - 1
      check document[offset] == char(0x3B)


    proc decodeGifFrame(data: seq[uint8]): seq[uint8] =
      ## Decode one frame's own LZW sub-block stream back to palette indices.
      ##   By exactly algorithm any GIF89a reader implements, mirroring `gif.nim`'s
      ##   encoder, not calling into it, so this stands as independent check of what it
      ##   wrote.
      ##   Widens its own code width one step earlier than encoder does.
      ##     GIF's LZW is asymmetric here by design ("early change"), since decoder's
      ##     dictionary always trails encoder's by one entry it has not yet been told
      ##     about.
      const
        BITS_CODE = 8
        COUNT_TABLE = 1 shl BITS_CODE
        CODE_CLEAR = COUNT_TABLE
        CODE_END = CODE_CLEAR + 1
        CODE_MAX = 4096
      var
        pos_bit = 0
        dict: Table[int, seq[uint8]]
        next_code = CODE_END + 1
        width = BITS_CODE + 1
        prev: seq[uint8]
        has_prev = false

      proc readCode(width: int): int =
        for i in 0 ..< width:
          let (byte_index, bit_index) = ((pos_bit + i) div 8, (pos_bit + i) mod 8)
          if byte_index < len(data):
            result = result or (int((data[byte_index].int shr bit_index) and 1) shl i)
        pos_bit += width

      while true:
        let code = readCode(width)
        if code == CODE_CLEAR:
          dict.clear()
          next_code = CODE_END + 1
          width = BITS_CODE + 1
          has_prev = false
          continue
        if code == CODE_END: break

        var entry: seq[uint8]
        if code < COUNT_TABLE: entry = @[uint8(code)]
        elif dict.hasKey(code): entry = dict[code]
        elif code == next_code and has_prev: entry = prev & @[prev[0]]
        else: doAssert false, &"Bad LZW code {code}."
        result.add(entry)
        if has_prev and next_code < CODE_MAX:
          dict[next_code] = prev & @[entry[0]]
          inc next_code
          if next_code >= (1 shl width) and width < 12: inc width
        prev = entry
        has_prev = true


    test "written frame decodes back to what it was quantized to, past a code-width growth":
      ## Guard against growing LZW code width one symbol too early.
      ##   Packs bits real reader disagrees with, corrupting every code from there on.
      ##   Flat or small image never reaches dictionary sizes where that bites, so this
      ##   drives enough distinct colour pairs to grow code width at least once.
      const (WIDTH, HEIGHT) = (64, 64)
      var frame = newSeq[uint8](WIDTH*HEIGHT*3)
      for i in 0 ..< WIDTH*HEIGHT:
        frame[i*3] = uint8((i*173) mod 256)
        frame[i*3 + 1] = uint8((i*97) mod 256)
        frame[i*3 + 2] = uint8((i*211) mod 256)

      # `writeGif` takes rows bottom-up and writes them top-down, exactly as `writePng`.
      #   does; build expected indices in that same written order, not source's.
      var expected: seq[uint8]
      for row_top in 0 ..< HEIGHT:
        let row_source = HEIGHT - 1 - row_top
        for column in 0 ..< WIDTH:
          let at = (row_source*WIDTH + column)*3
          expected.add(paletteIndex(frame[at], frame[at + 1], frame[at + 2]))

      var test_arena = initArena(buffer_arena)
      let path = getTempDir() / "visualiser_suite_growth.gif"
      writeGif(test_arena, path, WIDTH, HEIGHT, frame, 1, 8)
      defer: removeFile(path)
      let document = readFile(path)

      const HEADER_LEN = 6 + 7 + 256*3 + 19
      var offset = HEADER_LEN + 8 + 10 # Past Graphic Control Extension and Image Descriptor.
      let width_code = uint8(document[offset])
      check width_code == 8
      offset += 1

      var sub_blocks: seq[uint8]
      while true:
        let length = int(uint8(document[offset]))
        offset += 1
        if length == 0: break
        for i in 0 ..< length: sub_blocks.add(uint8(document[offset + i]))
        offset += length

      let decoded = decodeGifFrame(sub_blocks)
      check len(decoded) == WIDTH*HEIGHT
      check decoded == expected
