## Hold each citation of section to section its document holds (CURATOR.md, duty 1).
##   TODO: Stub reports nothing until check lands; static pass calls it already.

{.experimental: "strictFuncs".}

import ./[findings, layout]


func checkCitationsSection*(tree: Tree): seq[Finding] =
  ## Report each citation of section that its document lacks, at line of citation (duty 1).
  discard
