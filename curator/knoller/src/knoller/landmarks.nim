## Write each landmark index as alias its type declares, as V.8 gives (`Grade.vector`, never
##   `Grade(1)`), and fix it (`koch fix`); caller reads aliases of package and of library it
##   builds on (`landmarksDeclared`), and passes them in (`NamesPackage`).
##   Reading, check and edits give nothing yet: rule 9 of #443 lands in its build.

{.experimental: "strictFuncs".}

import ./[edits, reports]


type Landmark* = object  ## Define landmark index of type, and each alias naming it.
  name*: string  ## Type, as `Grade`.
  index*: string  ## Index as body spells it, with no whitespace, as `DIMENSIONS-1`.
  aliases*: seq[string]  ## Each alias naming index, in order read.


func landmarksDeclared*(sources: openArray[string]): seq[Landmark] =
  ## Read each landmark index aliases of sources name, with each alias naming it, in order read.
  discard


func checkLandmarks*(path, source: string; landmarks: openArray[Landmark]): seq[Report] =
  ## Report each landmark index written bare where alias of its type names it (V.8).
  discard


func editsLandmark*(
  path, source: string;
  landmarks: openArray[Landmark];
  fenced: openArray[int];
  held: openArray[Edit] = [],
): (seq[Edit], seq[Report]) =
  ## Read edits writing alias of each landmark index check reports, and one report for each.
  discard
