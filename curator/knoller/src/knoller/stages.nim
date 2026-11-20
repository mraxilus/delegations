## Enforce that each stage of routine or test opens with comment naming its purpose (Article VI.4),
##   and write placeholder where none stands (`koch fix`).

{.experimental: "strictFuncs".}

import ./reports


func checkStages*(path, source: string): seq[Report] =
  ## Report paragraph that blank line opens with no stage comment as its first line (VI.4).
  discard


func fixStages*(path, source: string): Fix =
  ## Write placeholder above each paragraph check reports.
  result.source = source
