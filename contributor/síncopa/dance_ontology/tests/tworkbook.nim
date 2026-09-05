discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Test model against workbook it was read from.
##
## Workbook is independent reference: it was written by hand, before
## model existed.  Every filled cell of `base` sheet that holds between two
## hand-to-hand frames must agree with primitive model derives for
## same pair, and cells that wait for place on body are pinned here so
## that size of what is deferred stays visible.

{.experimental: "strictFuncs".}

import std/[options, unittest]

import ../src/dance_ontology


suite "the base sheet":
  test "seven of the sheet's nine states read as distinct valid frames":
    var seen: seq[Frame] = @[]
    for name in WORKBOOK_STATES:
      if name.isDeferred:
        check workbookFrame(name).isNone
        continue
      let target = workbookFrame(name)
      check target.isSome
      check target.get.isValid
      check target.get notin seen
      check workbookName(target.get) == some(name)
      seen.add target.get
    check seen.len == 7  # base: nine states, two of them deferred
    check workbookFrame("shine").isNone

  test "the two deferred states are the ones that rest on the body":
    check DEFERRED_STATES == ["closed", "half-closed"]  # base: its first two rows
    check countDeferredCells() == 9  # base: nine cells touch "closed" or "half-closed"
    check CELLS.len - countDeferredCells() == 18  # base: hand-to-hand remainder

  test "each of the 27 filled cells names a known pair of states, once":
    check CELLS.len == 27  # base: 27 filled cells, read row by row
    for index, cell in CELLS:
      check cell.source in WORKBOOK_STATES
      check cell.destination in WORKBOOK_STATES
      check cell.source != cell.destination
      check cellText(cell.source, cell.destination) == some(cell.text)
      for other in CELLS[index + 1 .. ^1]:
        check not (other.source == cell.source and
          other.destination == cell.destination)

  test "every cell naming a slide reaches a deferred state":
    # Slide travels along body, so it needs place on body to reach.
    for cell in CELLS:
      if "slide" notin readCell(cell.text):
        continue
      check cell.source.isDeferred or cell.destination.isDeferred  # base: three "slide" cells

  test "the helper words of the ontology are read, including its synonyms":
    check readHelper("collect") == some(Helper.Collect)
    check readHelper("drop") == readHelper("flick")  # vocabulary: "flick", drop with momentum
    check readHelper("pass").isNone
    check readHelper("slide").isNone
    check readHelper("dip").isNone
    check readCompound(" cut ") == some(Compound.Cut)
    check readCompound("pass") == readCompound("place")  # base: writes both words
    check readCompound("collect").isNone
    check readCell("place, drop, collect").len == 3  # base: its longest cell, into "half-closed"


suite "the audit of the base sheet":
  test "every checkable cell is exactly the move the model derives":
    var primitives, compounds = 0
    for cell in CELLS:
      if cell.source.isDeferred or cell.destination.isDeferred:
        continue
      let
        source = workbookFrame(cell.source).get
        destination = workbookFrame(cell.destination).get
        named = readCompound(cell.text)
      if named.isSome:
        inc compounds
        check compound(source, destination) == named
        check route(source, destination).len == 2
        continue
      inc primitives
      check classify(source, destination) == readHelper(cell.text)
      check readHelper(cell.text).isSome
    check primitives == 12  # base: six "collect" and six "drop" cells
    check compounds == 6  # base: four "pass" cells and two "cut" cells
    check primitives + compounds == 18

  test "the checkable cells are every move between the states they name":
    var derived = 0
    for source in WORKBOOK_STATES:
      for destination in WORKBOOK_STATES:
        if source.isDeferred or destination.isDeferred:
          continue
        let
          a = workbookFrame(source).get
          b = workbookFrame(destination).get
        if classify(a, b).isSome or compound(a, b).isSome:
          inc derived
    check derived == 18  # base: matches its 18 hand-to-hand cells, none over

  test "nothing in the hand-to-hand part of the sheet disagrees":
    for finding in audit():
      check finding.kind notin {
        FindingKind.EdgeAbsent,
        FindingKind.ReverseAbsent,
        FindingKind.EdgeCompound,
        FindingKind.HelperDiffers,
        FindingKind.EdgeUnsupported,
      }

  test "what is left is two deferred states and one missing frame":
    var counted: array[FindingKind, int]
    for finding in audit():
      inc counted[finding.kind]
    check counted[FindingKind.StateDeferred] == 2  # base: "closed" and "half-closed"
    check counted[FindingKind.FrameAbsent] == 1  # base: no row for free frame
    check audit().len == 3

  test "the missing frame is the one where nobody is holding on":
    for finding in audit():
      if finding.kind != FindingKind.FrameAbsent:
        continue
      check finding.subject == "free"  # base: sheet has no such row
