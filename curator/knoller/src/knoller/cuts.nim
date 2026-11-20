## Read words of each declared name in order of cut V.2 gives, where words decide it alone, and
##   rename name that breaks it at every use, through semantic pass (`rewrites.nim`).
##   Caller reads axis values and words of package (`axesDeclared`, `wordsDeclared`), and passes
##     them in (`NamesPackage`), since rule reads one file.
##   Reading, check and rename give nothing yet: rule 8 of #443 lands in its build.

{.experimental: "strictFuncs".}

import ./[names, reports]


func axesDeclared*(source: string): seq[string] =
  ## Read each axis value source declares: field of wrapper of V.7.
  discard


func wordsDeclared*(source: string): seq[string] =
  ## Read each word, in lowercase, of each name source declares.
  discard


func checkCuts*(path, source: string; axes, words: openArray[string]): seq[Report] =
  ## Report each declared name whose words break cut of V.2 where they decide it alone.
  discard


func renamesCut*(source: string; axes, words, exempt: openArray[string]): seq[CaseRename] =
  ## Read rename each declaration needs to put its words in order of cut.
  discard


func composed*(recased, cut: openArray[CaseRename]): seq[CaseRename] =
  ## Join case rename and cut rename one declaration asks into one rename.
  @recased
