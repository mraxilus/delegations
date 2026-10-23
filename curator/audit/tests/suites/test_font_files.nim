## Replicate `font_files.nim` header: `cmap` read out of table directory, and each codepoint its
##   Unicode subtables map past `.notdef`, with control characters left out.
##   Files are built here (`fixtures.nim`), so suite needs no network. `woff2` is held by suite
##     of `assets.nim`, against `woff2` files of store, since building one needs Brotli encoder.

{.experimental: "strictFuncs".}

import std/[strutils, unittest]
import ./fixtures
import ../../src/font_files


suite "Font files":
  test "format 12 maps each run from its first glyph, and glyph zero maps nothing":
    let read = fileFontFace([
      ("cmap", tableCmap([(3, 10, subtableFormat12([(0x41 .. 0x43, 1), (0x3A9 .. 0x3AA, 0)]))])),
    ]).cmap.codepoints
    check read == @[0x41, 0x42, 0x43, 0x3AA]  # `3a9` reaches glyph `0`, which is `.notdef`


  test "format 4 maps each segment through its delta, and closing segment maps nothing":
    let read = fileFontFace([
      ("cmap", tableCmap([(3, 1, subtableFormat4([(0x2190 .. 0x2192, 5)]))])),
    ]).cmap.codepoints
    check read == @[0x2190, 0x2191, 0x2192]  # `ffff` closes table and reaches glyph `0`


  test "control characters are left out, since none draws":
    check fileFontFace([0x0 .. 0x21]).cmap.codepoints == @[0x20, 0x21]
    check CONTROL_MAX == 0x1F


  test "subtable of platform that maps no Unicode is skipped":
    # Platform `1` is Macintosh, whose encodings map no Unicode; platform `0` at encoding `5`
    #   maps variation sequences rather than codepoints.
    let read = fileFontFace([
      ("cmap", tableCmap([
        (1, 0, subtableFormat12([(0x41 .. 0x41, 1)])),
        (0, 5, subtableFormat12([(0x42 .. 0x42, 1)])),
        (0, 3, subtableFormat12([(0x43 .. 0x43, 1)])),
      ])),
    ]).cmap.codepoints
    check read == @[0x43]


  test "table directory finds cmap among other tables":
    let read = fileFontFace([
      ("head", "\0".repeat(54)),
      ("cmap", tableCmap([(3, 10, subtableFormat12([(0x3B1 .. 0x3B1, 1)]))])),
    ]).cmap.codepoints
    check read == @[0x3B1]


  test "format reader does not read raises, rather than reads short":
    # Format 6 is trimmed table of one run; store maps none through it.
    let format6 = "\0\x06" & "\0".repeat(8)
    expect ValueError:
      discard fileFontFace([("cmap", tableCmap([(3, 1, format6)]))]).cmap.codepoints


  test "file holding no cmap raises, naming what it lacks":
    try:
      discard fileFontFace([("head", "\0".repeat(54))]).cmap
      check false  # never reached
    except ValueError:
      check "no `cmap` table" in getCurrentExceptionMsg()
