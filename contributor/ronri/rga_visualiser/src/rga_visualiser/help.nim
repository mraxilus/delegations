## Say what every gesture, button and key in this visualiser does, once, for both UIs.
##
## Desktop wrote this in its panel and browser in hint that vanished after four seconds;
## two had drifted.
##   Both render this table, so control gaining binding is described in one place or in
##   neither.
## Entries name *user's* action and its outcome, in reader's words, not handler.
##   "Drag one object onto another", not "pointerdown then pointermove".
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
## Shared between desktop (`visualiser.nim`) and browser (`browser_bridge.nim`) render
## paths; see `visualiser.nim`'s "Render Paths" table.

{.experimental: "strictFuncs".}

import std/[options, strformat, strutils]

import ./[interaction, scene]



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
  case path
  of HelpPath.Drag: "drag"
  of HelpPath.Select: "select"
  of HelpPath.Menu: "menu"
  of HelpPath.Panel: "panel"
  of HelpPath.Camera: "camera"
  of HelpPath.Keys: "keys"
  of HelpPath.Operations: "operations"


func descriptionOf*(path: HelpPath): string =
  ## Say in one sentence what tab is about, for line above its rows.
  ##   Row stands on its own only so far: `the … wedge` and `the apply section` name
  ##   things met *inside* one way of working, and `menu` rows name five buttons without
  ##   saying which menu.
  ##   Context stated once, above rows, for reader who has just opened this tab.
  case path
  of HelpPath.Drag:
    "Drag one object onto another to build a new one. Some pairs open a wheel of choices."
  of HelpPath.Select:
    "Say which objects to work on. Whatever is selected wears a white outline."
  of HelpPath.Menu:
    "The small menu that appears beside whatever you just selected."
  of HelpPath.Panel:
    "The panel and the buttons above it."
  of HelpPath.Camera:
    "Move your viewpoint. None of this changes the scene itself."
  of HelpPath.Keys:
    "Keyboard shortcuts. The 3D view needs focus first — press tab until it has it."
  of HelpPath.Operations:
    "Every operation the apply section and the selection menu offer, and what each is " &
    "called."



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
  var lut: array[39 + COUNT_OPERATION, HelpEntry]
  var count = 0
  proc add(path: HelpPath; action, outcome: string; is_touch = false) =
    lut[count] = HelpEntry(
      path: path,
      action: action,
      outcome: outcome,
      is_touch: is_touch,
    )
    inc count

  # Ask `interaction.armingOf` which button asks and which decides.
  #   Walked in reading order rather than `PointerButton`'s physical left, middle, right.
  for button in [PointerButton.Left, PointerButton.Right, PointerButton.Middle]:
    let arming = armingOf(button)
    if arming.isNone: continue
    add(
      HelpPath.Drag, nameOf(button) & "-drag one object onto another",
      case arming.get
      of MenuArming.Never: "build the one object those two define, without ever asking"
      of MenuArming.OnDwell: "build that object, or pause on the target to be asked"
      of MenuArming.Always: "open the wheel, whatever the pair would have made on its own",
    )
  # Say "on its own": finger over crowd moves view instead; see `interaction.canConstructByTouch`.
  add(
    HelpPath.Drag, "drag an object on its own onto another",
    "build the one object those two define", is_touch = true,
  )
  # Touch alone, now that mouse decides by button; see `MenuArming`.
  add(
    HelpPath.Drag, "pause on the target mid-drag",
    "open the wheel without needing a second button", is_touch = true,
  )
  add(
    HelpPath.Drag, "the … wedge",
    "hand both objects to the apply picker, which lists every operation",
  )

  # Ask `interaction.revealsMenuOn` which button brings menu, as drag rows ask `armingOf`.
  #   Shift gets one row, not one per button: shift means same thing whichever button,
  #   and four rows overflow phone.
  for button in [PointerButton.Left, PointerButton.Right]:
    add(
      HelpPath.Select, nameOf(button) & "-click an object",
      if revealsMenuOn(button): "the same, and open its menu of actions"
      else: "select just that one, dropping anything else",
    )
  add(
    HelpPath.Select, "hold shift as you click",
    "add it, or drop it again if it is already picked",
  )
  add(
    HelpPath.Select, nameOf(PointerButton.Right) & "-click with objects selected",
    "bring their menu back, changing nothing",
  )
  add(
    HelpPath.Select, "click empty space",
    "clear the selection, or pick the sky if there is one",
  )
  add(
    HelpPath.Select, "press and hold an object",
    "select it — its outline fills as you hold", is_touch = true,
  )
  add(
    HelpPath.Select, "tap another object while one is selected",
    "add it to the selection", is_touch = true,
  )
  # Give menu beside selection own tab rather than tail of `select`.
  #   Ten rows on phone wrap and scroll.
  add(HelpPath.Menu, "apply", "run any operation on what you selected")
  add(HelpPath.Menu, "edit", "change the selected object's name, colour or coordinates")
  add(HelpPath.Menu, "hide", "keep the selection but stop drawing it")
  add(HelpPath.Menu, "delete", "remove the selection from the scene")
  add(HelpPath.Menu, "✕", "clear the selection and close this menu")

  # Name rows by button rather than by where it sits.
  #   `add` and toggles are in desktop's top bar and browser's chip row, so row naming
  #   place is false on one build.
  add(HelpPath.Panel, "add", "create a point by typing its coordinates")
  add(
    HelpPath.Panel, "the apply section",
    "run any operation in the catalogue on what you selected",
  )
  add(
    HelpPath.Panel, "the objects section",
    "every object in the scene, each with rename, hide and delete",
  )
  add(
    HelpPath.Panel, "save scene, load scene",
    "write the whole scene to a file, or read one back",
  )
  add(
    HelpPath.Panel, "axes, grid",
    "show or hide the reference furniture, leaving the scene alone",
  )

  add(HelpPath.Camera, "drag empty space", "orbit the view around what you are looking at")
  add(HelpPath.Camera, "right-drag empty space", "slide the view sideways and up or down")
  add(HelpPath.Camera, "wheel", "move toward or away from whatever you point at")
  # Say `empty space or a crowd`, not just `with one finger`: finger starting on *lone*.
  #   object builds; over several it moves, and zooming in separates them.
  add(
    HelpPath.Camera, "drag empty space, or a crowd of objects, with one finger",
    "orbit the view around what you are looking at", is_touch = true,
  )
  add(HelpPath.Camera, "pinch", "move closer in or further out", is_touch = true)
  add(
    HelpPath.Camera, "drag with two fingers",
    "slide the view sideways and up or down", is_touch = true,
  )

  add(
    HelpPath.Keys, "escape", "back out of whatever is part-way through, one step at a time"
  )
  add(HelpPath.Keys, "ctrl+z, ctrl+shift+z", "undo, then redo, the last change to the scene")
  add(HelpPath.Keys, "tab", "move focus between the controls and the 3D view")
  # Read keys out of `interaction.motionFor` and `actionFor`, so rebinding rewrites row.
  #   Grouped by job, since reader looks for job first; names come from `nameOf`.
  add(
    HelpPath.Keys,
    nameOf(Key.W) & ", " & nameOf(Key.A) & ", " & nameOf(Key.S) & ", " & nameOf(Key.D),
    "slide the view across the ground; hold " & nameOf(Key.Shift) & " to move faster",
  )
  add(HelpPath.Keys, nameOf(Key.Q) & ", " & nameOf(Key.E), "lower or raise the view")
  add(
    HelpPath.Keys,
    nameOf(Key.Left) & ", " & nameOf(Key.Right) & ", " &
      nameOf(Key.Up) & ", " & nameOf(Key.Down),
    "orbit the view around what you are looking at",
  )
  add(
    HelpPath.Keys, nameOf(Key.Minus) & ", " & nameOf(Key.Plus), "move further out, or closer in"
  )
  add(HelpPath.Keys, nameOf(Key.F), "bring whatever is selected back into view")

  add(
    HelpPath.Keys, nameOf(Key.BracketLeft) & ", " & nameOf(Key.BracketRight),
    "move the highlight to the previous or next object",
  )
  add(
    HelpPath.Keys, nameOf(Key.Enter),
    "select the highlighted object; hold shift to add it",
  )
  add(HelpPath.Keys, nameOf(Key.Home), "put the camera back where it started")
  # Generate whole catalogue: row per operation, named as every picker offers it.
  #   `scene.notationSymbolic`, `scene.notationNamed`; hand-written list falls behind.
  for operation in Operation:
    add(HelpPath.Operations, notationSymbolic(operation), notationNamed(operation))

  doAssert count == len(lut),
    &"Every help slot must be filled, adjust the array's size; got `{count}` of `{len(lut)}`."
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
