## Decide which docket rows search box shows; shared by page script and suites.
##   Row shows while its words hold every word typed, so more words narrow, never widen.
##   Case folds in ASCII alone, as row words do (`docket.nim`), so both sides fold alike.

{.experimental: "strictFuncs".}

import std/strutils


func isFound*(words_row, typed: string): bool =
  ## Decide whether row shows: its words hold every word typed, case folded in ASCII.
  for word in typed.toLowerAscii.splitWhitespace:
    if word notin words_row: return false
  true
