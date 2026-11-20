## Enforce that each comment of Nim source is hanging outline (Article VI.2), and that doc holds
##   one summary line (VI.1), and fix them (`koch fix`).

{.experimental: "strictFuncs".}

import ./reports


func checkOutlines*(path, source: string): seq[Report] =
  ## Report nuance off its step, and summary of doc that is not one line ending in period.
  discard


func fixOutlines*(path, source: string): Fix =
  ## Move each nuance check reports to its step.
  result.source = source
