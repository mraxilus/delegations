## Say what every gesture, button and key in this visualiser does, once, for both UIs.
##
## Desktop wrote this in its panel and browser in hint that vanished after four seconds;
## two had drifted.
##   Both render this table, so control gaining binding is described in one place or in
##   neither.
## Entries name *user's* action and its outcome, in reader's words, not handler.
##   "Drag one object onto another", not "pointerdown then pointermove".
##   Words are `wording`'s: every cell, title and line is key there, and this module holds
##   which cell sits in which row. Cell naming button or key composes through `wording`'s
##   own funcs, so no word reader sees is written here.
##   Binding derived from rule stated elsewhere is read from there: `lut_help_entries`
##   builds construct rows out of `interaction.armingOf`, so rebinding button rewrites help.
## Every row has to make sense with rows above it covered up.
##   Reader opens one tab, finds line they need, leaves.
##   Three failures, found by reading rendered panel cold.
##     Circular: `drag one object onto another` → `make whatever the two of them make`.
##     Leaning on neighbour: `the same choice, without needing the other button`.
##     Naming internals reader never met: `the apply section`, `dolly`.
##   What row cannot carry (which menu, what wedge is) goes in `descriptionOf`.
## One word, one meaning: objects are *selected*, operations are *chosen*.
## Cut by how reader is working, not by what control is.
##   Reader opens this mid-task, and only that task's rows are of use.
##   `HelpPath` is axis, one tab per path; `ENTRIES_MAX_PATH` holds each tab to what fits
##   phone without scrolling, checked at compile time.
##     Cost: table that outgrows tab fails build until path is split or bound is raised.
##
## Shared between desktop (`visualiser.nim`) and browser (`bridge.nim`) render
## paths; see `visualiser.nim`'s "Render Paths" table.

{.experimental: "strictFuncs".}

import std/[options, strformat, strutils]

import ./[interaction, scene, wording]



#[ Type Definitions ]#

const
  ENTRIES_MAX_PATH_CATALOGUE* = COUNT_OPERATION
    ## Bound `operations` path at exactly size of catalogue it lists.
    ##   Not height: this tab *is* catalogue, one row per operation, and only bound worth
    ##   checking is that it holds every one.
    ##   Scrolls on any screen; reference list read by lookup.

  ENTRIES_MAX_PATH_KEYS* = 12
    ## Bound how many entries `keys` path may hold, checked at compile time.
    ##   Larger than other paths': keyboard tab describes what phone-sized viewport lacks, so
    ##   fitting it there is wrong trade; measurement in `PROVENANCE.md`.
    ##   Bound stays so tab cannot grow unnoticed; raising it is deliberate.

  ENTRIES_MAX_PATH* = 8
    ## Bound how many entries any other path may hold, checked at compile time.
    ##   Proxy: real constraint is *rendered height*, and count is what compile time checks.
    ##   Measured on 320x568 viewport, each tab asked how far its rows overflow box given;
    ##   figures in `PROVENANCE.md`.
    ##     `select` scrolls by one row; trade taken for two rows teaching bindings reader
    ##     cannot discover otherwise, after shortening recovered too little.
    ##     `keys` scrolls and is left scrolling; see `ENTRIES_MAX_PATH_KEYS`.
    ##     Other five fit exactly, two only after descriptions were cut.
    ##   Count of rows is not count of lines; path nearing cap prompts re-measurement, never
    ##   trust in number.
    ##   Cap forces question to be asked again, not promise nothing scrolls.
    ##     Splitting path is nearly always better than raising; not here, since regrouping
    ##     keyboard rows onto tabs whose work they do overflowed `camera` and `select`.

type
  HelpPath* {.pure.} = enum ## Define which way of working entries belong to.
    ## What reader is in middle of when opening help.
    ##   Ordered as reader meets them: drag is what visualiser is for, keys are accelerator.
    Drag, ## Building one object out of two by dragging between them.
    Select, ## Saying which objects to work on.
    Menu, ## What menu beside selection offers.
    Panel, ## Panel and buttons above it.
    Camera, ## Moving view.
    Keys, ## Keyboard.
    Operations, ## What every operation in catalogue is called.

  HelpEntry* = object ## Define one thing reader can do and what it does.
    path*: HelpPath ## Way of working it belongs to, and so tab it appears under.
    action*: string ## What reader does.
    outcome*: string ## What happens when they do it.
    is_touch*: bool ## Whether this is touch way rather than pointer way.
      ## Both always listed: laptop with touchscreen is one device, and hiding either
      ## behind guess about hardware leaves reader believing gesture does not exist.


func titleOf*(path: HelpPath): string =
  ## Name one tab as reader would say what they are doing.
  $wordingText(
    case path
    of HelpPath.Drag: NameTabDrag
    of HelpPath.Select: NameTabSelect
    of HelpPath.Menu: NameTabMenu
    of HelpPath.Panel: NameTabPanel
    of HelpPath.Camera: NameTabCamera
    of HelpPath.Keys: NameTabKeys
    of HelpPath.Operations: NameTabOperations
  )


func wheelPairs(): seq[tuple[notation, word: string]] =
  ## Pair each wheel wedge's notation with word it is, for `wording.wheelWordsTaught`.
  ##   `More` is left out -- its wedge is bare ellipsis, which needs no decoding, and row
  ##   in this tab already says what it hands over.
  for choice in [DragChoice.Join, DragChoice.Meet, DragChoice.Project]:
    result.add((labelOf(choice), wordOf(choice)))


func descriptionOf*(path: HelpPath): string =
  ## Say in one sentence what tab is about, for line above its rows.
  ##   Row stands on its own only so far: `the … wedge` and `the apply section` name
  ##   things met *inside* one way of working, and `menu` rows name five buttons without
  ##   saying which menu.
  ##   Context stated once, above rows, for reader who has just opened this tab.
  case path
  of HelpPath.Drag:
    # Teach three wedges their words here, where both UIs already read this line.
    #   Wedge wears notation alone (`interaction.labelOf`), which names nothing until
    #   reader is told which operation it is.
    #   Read from `wordOf` and `labelOf` rather than written out, so wedge renamed or
    #   renotated is renamed here too.
    $wordingText(NoteTabDrag) & " " & wheelWordsTaught(wheelPairs())
  of HelpPath.Select: $wordingText(NoteTabSelect)
  of HelpPath.Menu: $wordingText(NoteTabMenu)
  of HelpPath.Panel: $wordingText(NoteTabPanel)
  of HelpPath.Camera: $wordingText(NoteTabCamera)
  of HelpPath.Keys: $wordingText(NoteTabKeys)
  of HelpPath.Operations: $wordingText(NoteTabOperations)



#[ Entry Table ]#

func nameOf(button: PointerButton): string =
  ## Name mouse button as reader would say it.
  toLowerAscii($button)


const lut_help_entries* = block:
  ## Hold every entry two UIs render, grouped by path and in order reader meets them.
  ##   Fixed array with `count` asserted against length at compile time, so adding entry
  ##   without resizing fails build rather than leaving blank row.
  ##     Size is hand-written rows plus catalogue, which is generated.
  ##   Entries of one path are written together, asserted below: both front-ends walk this
  ##   once in order, so split path renders as two tabs of same name.
  ##   Every cell is `wording`'s key, or composed by `wording`'s func from one; row whose
  ##   action names button or key composes it, so button's name is `interaction`'s alone.
  var lut: array[41 + COUNT_OPERATION, HelpEntry]
  var count = 0
  proc add(path: HelpPath; action: string; outcome: Wording; is_touch = false) =
    lut[count] = HelpEntry(
      path: path,
      action: action,
      outcome: $wordingText(outcome),
      is_touch: is_touch,
    )
    inc count
  proc add(path: HelpPath; action, outcome: Wording; is_touch = false) =
    add(path, $wordingText(action), outcome, is_touch)

  # Ask `interaction.armingOf` which button asks and which decides.
  #   Walked in reading order rather than `PointerButton`'s physical left, middle, right.
  for button in [PointerButton.Left, PointerButton.Right, PointerButton.Middle]:
    let arming = armingOf(button)
    if arming.isNone: continue
    add(
      HelpPath.Drag, withButton(nameOf(button), HelpDragOnto),
      case arming.get
      of MenuArming.Never: HelpBuildUnasked
      of MenuArming.OnDwell: HelpBuildOrPause
      of MenuArming.Always: HelpOpenWheel,
    )
  # Say "on its own": finger over crowd moves view instead; see `interaction.canConstructByTouch`.
  add(HelpPath.Drag, HelpDragAloneOnto, HelpBuildDefined, is_touch = true)
  # Touch alone, now that mouse decides by button; see `MenuArming`.
  add(HelpPath.Drag, HelpPauseMidDrag, HelpOpenWheelNoButton, is_touch = true)
  add(HelpPath.Drag, wedgeNamed(labelOf(DragChoice.More)), HelpHandToPicker)

  # Ask `interaction.revealsMenuOn` which button brings menu, as drag rows ask `armingOf`.
  #   Shift gets one row, not one per button: shift means same thing whichever button,
  #   and four rows overflow phone.
  for button in [PointerButton.Left, PointerButton.Right]:
    add(
      HelpPath.Select, withButton(nameOf(button), HelpClickObject),
      if revealsMenuOn(button): HelpSameAndMenu else: HelpSelectJustOne,
    )
  add(HelpPath.Select, HelpHoldShiftClick, HelpAddOrDrop)
  add(
    HelpPath.Select, withButton(nameOf(PointerButton.Right), HelpClickSelected), HelpMenuBack
  )
  add(HelpPath.Select, HelpClickEmpty, HelpClearOrSky)
  add(HelpPath.Select, HelpPressHold, HelpSelectFills, is_touch = true)
  add(HelpPath.Select, HelpTapAnother, HelpAddToSelection, is_touch = true)
  # Give menu beside selection own tab rather than tail of `select`.
  #   Ten rows on phone wrap and scroll.
  #   Action is button's own key, so button renamed is renamed in its row.
  add(HelpPath.Menu, NamePickApply, HelpRunOperation)
  add(HelpPath.Menu, NamePickEdit, HelpChangeObject)
  add(HelpPath.Menu, NamePickHide, HelpKeepStopDrawing)
  add(HelpPath.Menu, NamePickDelete, HelpRemoveSelection)
  add(HelpPath.Menu, NamePickClose, HelpClearClose)

  # Name rows by button rather than by where it sits.
  #   `add` and toggles are in desktop's top bar and browser's chip row, so row naming
  #   place is false on one build.
  add(HelpPath.Panel, NameChipAdd, HelpCreatePoint)
  add(HelpPath.Panel, sectionNamed(NameHeadApply), HelpRunCatalogue)
  add(HelpPath.Panel, sectionNamed(NameHeadObjects), HelpEveryObject)
  add(
    HelpPath.Panel,
    namesJoined([
      pathNamed([NameMenuSave, NameMenuSaveScene]), pathNamed([NameMenuLoad, NameMenuLoadScene]),
    ]),
    HelpWriteRead,
  )
  add(
    HelpPath.Panel,
    namesJoined([$wordingText(NameChipAxes), $wordingText(NameChipGrid)]), HelpFurniture,
  )

  add(HelpPath.Camera, HelpDragEmpty, HelpOrbit)
  add(
    HelpPath.Camera, withButton(nameOf(PointerButton.Right), HelpDragEmpty), HelpSlideSideways
  )
  add(HelpPath.Camera, HelpWheel, HelpMoveToward)
  # Say `empty space or a crowd`, not just `with one finger`: finger starting on *lone*.
  #   object builds; over several it moves, and zooming in separates them.
  add(HelpPath.Camera, HelpDragEmptyOrCrowd, HelpOrbit, is_touch = true)
  add(HelpPath.Camera, HelpPinch, HelpMoveCloser, is_touch = true)
  add(HelpPath.Camera, HelpDragTwoFingers, HelpSlideSideways, is_touch = true)
  add(HelpPath.Camera, HelpTwistTwoFingers, HelpRoll, is_touch = true)

  add(HelpPath.Keys, HelpEscape, HelpBackOut)
  add(HelpPath.Keys, HelpUndoRedoKeys, HelpUndoRedo)
  add(HelpPath.Keys, HelpTab, HelpMoveFocus)
  # Name keys out of `interaction.nameOf`, so key renamed is renamed in its row.
  #   Grouped by job, since reader looks for job first.
  add(
    HelpPath.Keys,
    namesJoined([nameOf(Key.W), nameOf(Key.A), nameOf(Key.S), nameOf(Key.D)]),
    HelpTravel,
  )
  add(HelpPath.Keys, namesJoined([nameOf(Key.Q), nameOf(Key.E)]), HelpRoll)
  add(
    HelpPath.Keys, namesJoined([nameOf(Key.Space), nameOf(Key.Control)]), HelpRaiseLower
  )
  add(
    HelpPath.Keys,
    namesJoined([nameOf(Key.Left), nameOf(Key.Right), nameOf(Key.Up), nameOf(Key.Down)]),
    HelpOrbit,
  )
  add(HelpPath.Keys, namesJoined([nameOf(Key.Minus), nameOf(Key.Plus)]), HelpFurtherCloser)
  add(HelpPath.Keys, nameOf(Key.F), HelpBackIntoView)
  add(
    HelpPath.Keys, namesJoined([nameOf(Key.BracketLeft), nameOf(Key.BracketRight)]),
    HelpHighlightPrevNext,
  )
  add(HelpPath.Keys, nameOf(Key.Enter), HelpSelectHighlighted)
  add(HelpPath.Keys, nameOf(Key.Home), HelpCameraHome)
  # Generate whole catalogue: row per operation, named as every picker offers it.
  #   `scene.notationSymbolic`, `scene.notationNamed`; hand-written list falls behind.
  for operation in Operation:
    lut[count] = HelpEntry(
      path: HelpPath.Operations,
      action: notationSymbolic(operation),
      outcome: notationNamed(operation),
      is_touch: false,
    )
    inc count

  doAssert count == len(lut),
    &"Every help handle must be filled, adjust the array's size; got `{count}` of `{len(lut)}`."
  lut


func countOf*(path: HelpPath): int =
  ## Count entries one tab holds, for caller sizing or checking one.
  for entry in lut_help_entries:
    if entry.path == path: inc result


static:
  # Check two properties front-ends rely on and neither can check for itself.
  var seen: set[HelpPath]
  var path_last = none(HelpPath)
  for entry in lut_help_entries:
    if path_last != some(entry.path):
      doAssert entry.path notin seen,
        &"Entries of one help path must be written together, or it renders as two tabs; " &
          &"got `{entry.path}` again."
      seen.incl(entry.path)
      path_last = some(entry.path)
  for path in HelpPath:
    doAssert path in seen,
      &"Every help path must hold at least one entry; got none for `{titleOf(path)}`."
    let entries_max =
      case path
      of HelpPath.Operations: ENTRIES_MAX_PATH_CATALOGUE
      of HelpPath.Keys: ENTRIES_MAX_PATH_KEYS
      else: ENTRIES_MAX_PATH
    doAssert countOf(path) <= entries_max,
      &"Help path `{titleOf(path)}` must fit a phone, split it or raise its own bound " &
        &"deliberately; got `{countOf(path)}` over `{entries_max}`."
