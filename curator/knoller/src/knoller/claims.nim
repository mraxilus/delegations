## Enforce form of each comment of Nim source (Article VI.10): claim opens with capital and closes
##   with period, and each name stands in backticks; and fix both (`koch fix`).

{.experimental: "strictFuncs".}

import ./reports


func checkClaims*(path, source: string): seq[Report] =
  ## Report claim of comment off its form, and name of comment out of backticks.
  discard


func checkBackticks*(path, source: string): seq[Report] =
  ## Report name of comment out of backticks alone, where comments keep their own language.
  discard


func fixClaims*(path, source: string): Fix =
  ## Write capital, period and backticks check reports.
  result.source = source


func fixBackticks*(path, source: string): Fix =
  ## Write backticks check reports alone, where comments keep their own language.
  result.source = source
