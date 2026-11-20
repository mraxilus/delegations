## Read what names of package tell rules of one file that its text cannot: axis values and words
##   of names package declares (V.2, `cuts.nim`), alias of each landmark index, those of library
##   it builds on among them (V.8, `landmarks.nim`), and calls of each constructor it declares
##   (STYLE.md §5, `constructors.nim`).
##   Each rule reads one file, as each rule of knoller does, so caller reads package and passes
##     its names in (`NamesPackage`), as it passes constants other modules export
##     (`staging.nim`). Names come from modules of package alone, and aliases from library too,
##     since library's word is no axis value, and its constructor is no call form of package.
##   Command line reads modules of run, by nimble file of their package, and library each package
##     builds on by `--path` of its `nim.cfg` (`command.nim`). `koch fix` passes names of each
##     project too (`fixes.nim` of `curator/audit`), so both callers read them alike; static pass
##     of `koch check` reads them at step 4 of #443.

{.experimental: "strictFuncs".}

import ./[constructors, cuts, landmarks]


type NamesPackage* = object
  ## Define what names of package tell rules of one file: axis values and words, landmarks and
  ##   constructor calls; empty where caller reads none, so those rules report nothing.
  axes*: seq[string]  ## Each axis value of wrapper package declares (V.7), in order read.
  words*: seq[string]  ## Each word, in lowercase, of each name package declares.
  landmarks*: seq[Landmark]  ## Each landmark index alias of package or of its library names.
  calls*: seq[Calls]  ## Calls of each constructor package declares, by form.


func namesPackage*(sources: openArray[string]; libraries: openArray[string] = []): NamesPackage =
  ## Read names of package from its modules (`sources`), and aliases from them and from modules of
  ##   library it builds on (`libraries`).
  for source in sources:
    for axis in source.axesDeclared:
      if axis notin result.axes: result.axes.add axis
    for word in source.wordsDeclared:
      if word notin result.words: result.words.add word
  result.landmarks = landmarksDeclared(@sources & @libraries)
  result.calls = callsConstructor(sources)
