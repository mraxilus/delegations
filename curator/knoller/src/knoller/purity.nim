## Enforce STYLE.md §1 on pure routines: routine with no effect beyond its parameters is `func`,
##   and `proc` stays for effect or randomness; compiler proves each, and fixer writes `func`.
##   Check and fixer read sites caller passes (`Pures`), as compiler answered them.

{.experimental: "strictFuncs".}

import std/tables
import ./[edits, reports]


type Pures* = object  ## Define what compiler tells pure routine rule of one file.
  reason*: string  ## Why compiler proved nothing for file; empty where it proved.
  sites*: seq[(int, int)]
    ## One-based line and zero-based byte column of `proc` of each routine compiler checks as
    ##   `func`.


func candidatesPure*(files: openArray[(string, string)]): Table[string, seq[(int, int)]] =
  ## Read site of `proc` of each routine of files whose body shows no effect, by path.
  discard


proc provenPure*(
  source: string;
  sites: openArray[(int, int)];
  directory, nim: string;
  configurations: openArray[seq[string]];
  prefix = "";
  suffix = "",
): Pures =
  ## Ask compiler `nim` to check source in directory with each candidate at `sites` as `func`.
  Pures()


func checkPure*(path, source: string; pures: Pures): seq[Report] =
  ## Report each `proc` compiler checks as `func` (STYLE.md §1).
  discard


func editsPure*(
  path, source: string; pures: Pures; fenced: openArray[int]; held: openArray[Edit] = []
): (seq[Edit], seq[Report]) =
  ## Read edits writing `func` for each `proc` check reports, and one report per routine.
  discard
