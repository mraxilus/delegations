## Enforce Article I.6 and STYLE.md §5 on sibling markers: private symbol sibling reaches through
##   `{.all.}`, and its own module never uses, carries `{.used.}` and comment naming sibling;
##   `{.all.}` import reaches private symbol.
##   Check and fixer read uses caller passes (`Uses`), as semantic pass answered them.

{.experimental: "strictFuncs".}

import std/tables
import ./[edits, reports, symbols]


type
  UsePrivate* = object  ## Define where semantic pass finds private symbol used.
    siblings*: seq[string]
      ## File name of each sibling using it, outside `tests` of package, as `cayleys.nim`.
    is_own*: bool  ## Own module uses it, beyond its declaration.

  Uses* = object  ## Define what semantic pass tells marker rule of one file.
    reason*: string  ## Why pass resolved nothing for file; empty where it resolved.
    privates*: Table[(int, int), UsePrivate]
      ## Use of each private symbol file declares at top level, by one-based line and zero-based
      ##   byte column of its name; symbol no module of package imports with `{.all.}` is absent.
    imports*: Table[(int, int), bool]
      ## Whether each `{.all.}` import of module of package reaches private symbol, by line and
      ##   column of module it names; import of module outside package is absent.


func queryUses*(path, source: string): Query =
  ## Build what marker rule asks semantic pass of module: every use of each private symbol.
  result.path = path


func usesPackage*(
  files: openArray[(string, string)]; answers: openArray[Answer]
): Table[string, Uses] =
  ## Read uses of each file of package from answers of semantic pass, by path.
  discard


func checkMarkers*(path, source: string; uses: Uses): seq[Report] =
  ## Report each private symbol sibling reaches without its marker, and each `{.all.}` that
  ##   reaches none (STYLE.md §5).
  discard


func editsMarkers*(
  path, source: string; uses: Uses; fenced: openArray[int]; held: openArray[Edit] = []
): (seq[Edit], seq[Report]) =
  ## Read edits writing each marker and dropping each `{.all.}` check reports, and one report
  ##   per edit.
  discard
