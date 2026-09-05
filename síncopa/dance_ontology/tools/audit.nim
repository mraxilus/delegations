## Print derived ontology and everything it has to say about workbook.
##
##   Reading tool for model: frame list, transition matrix and audit, printed for
##     person rather than asserted for machine.
##   Everything is said in terms workbook uses, so sheet and model can be compared by
##     eye as well as by test.
##     Cost of speaking workbook's language: workbook cannot name everything model
##       derives, so frame it has no row for and move it has no cell for are carried
##       under `*` mark instead of name.
##     Cost of comparing by eye: nothing here fails when two drift;
##       agreement is enforced by `tests/tworkbook.nim`, and this only makes it
##       readable.

{.experimental: "strictFuncs".}

import std/[options, strutils]

import ../src/dance_ontology


proc printFrames() =
  ## List every frame, with its name and number of moves it carries.
  echo "frames (", FRAMES.len, "):"
  for target in FRAMES:
    let known = if workbookName(target).isSome: "  " else: "* "
    echo "  ", known, target.key, "  ", target.describe.alignLeft(38),
      $moves(target).len, " moves"
  echo "  (* marks a frame the workbook has no row for)"


proc printMatrix() =
  ## Print every derived move, grouped by frame it starts from.
  echo "\nderived transitions, with the compounds beneath the moves:"
  for source in FRAMES:
    echo "  from ", source.describe, "  [", source.key, "]"
    for move in moves(source):
      let cell = cellText(workbookName(source).get(""), workbookName(move.to).get(""))
      let mark = if cell.isSome: "  " else: "* "
      echo "    ", mark, move.helper.name.alignLeft(9),
        move.to.describe.alignLeft(36), phrase(source, move)
    for target in FRAMES:
      let named = compound(source, target)
      if named.isNone:
        continue
      let cell = cellText(workbookName(source).get(""), workbookName(target).get(""))
      let mark = if cell.isSome: "  " else: "* "
      echo "    ", mark, ($named.get).toLowerAscii.alignLeft(9),
        target.describe.alignLeft(36), compoundPhrase(source, target)


proc printAudit() =
  ## Report what model says about workbook, grouped by kind.
  let findings = audit()
  echo "\naudit of the base sheet (", findings.len, " findings, ",
    CELLS.len - countDeferredCells(), " of ", CELLS.len, " cells checkable):"
  for kind in FindingKind:
    var shown = false
    for finding in findings:
      if finding.kind != kind:
        continue
      if not shown:
        echo "\n  ", kind, ":"
        shown = true
      echo "    ", finding.subject
      echo "      ", finding.detail


when isMainModule:
  printFrames()
  printMatrix()
  printAudit()
