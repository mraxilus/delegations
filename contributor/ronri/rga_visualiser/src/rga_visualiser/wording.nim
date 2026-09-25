## Hold every word either front-end shows reader, once.
##
## Shown text was written where it is drawn, which put one sentence in two languages and let
## copies drift apart unseen: two front-ends worded point's radius differently, and window
## explained forty-one controls against page's eleven. No check could see any of it, because
## sentence in `panel.nim` and sentence in `objects_section.ts` are two literals that never
## meet (repository issue 145).
##
## **This is games' own answer to that problem, with one deliberate change.** String catalogue
## keyed by stable identifier, code naming key rather than words, one file translator edits and
## nobody else does -- that much is standard. Standard part also accepts *runtime* miss, because
## catalogue is data loaded after build and compiler cannot see it, so every such toolchain
## ships fallback for key with no text.
##   Here catalogue compiles in, so key is **enum** rather than string and table is
##   `array[Wording, string]` written with its keys. Missing entry is compile error; misspelt key
##   is compile error; row out of order cannot happen. There is no miss to fall back from, so
##   there is no fallback -- which is stronger than practice it adapts, and is
##   `CONSTITUTION.md`'s own "check gives same verdict on same code" moved to compile time.
##
## Page reaches this through `bridge.nimWording`, over generated TypeScript rather than by
## hand-copied ordinal: see `tools/build.nim`'s `declare`, which writes `Wording` out for page
## from this very enum, so key renamed here and not re-derived fails type check rather than at
## run time (repository issue 47's lesson, applied again).
##
## Page's own labels sit in markup rather than in script, so they are not assigned at load:
## `pages/shell.html` writes `@WORD:<Key>@` and `tools/build.nim` fills it from this table while
## assembling page. Reader therefore meets real words with first paint, and there is still only
## one copy of them.
##
## Outcome sentences and help rows are here too: row's cells are `Help` keys, tab's title is
## `NameTab` key and its line `NoteTab` key, and whatever is composed at run time -- count,
## label, button's name -- is composed by func below, so glue between parts is this file's
## as much as parts are. `help` keeps table's shape and `message` how long outcome stands;
## neither holds word reader sees.
##
## What is *not* here: text one front-end alone can reach, which has no copy to drift from.
## Window's `memory` and `total` headings, page's own diagnostic rows, and page's `dismiss` are
## each shown by one front-end and stay where they are. Nor is algebra's own vocabulary:
## operation names and notation come from `pga`'s declarations through `scene`, kind words
## from `objects`, key and button names from `interaction`, and help composes them through
## funcs here rather than carrying copy.
##
## Shared by desktop (`panel.nim`) and browser (`bridge.nim`, then its scripts).

{.experimental: "strictFuncs".}

import std/[math, strutils]

import ./format

const RUNES_LABEL_MOST* = 24
  ## Bound how long word on control may be, in runes.
  ##   Not layout limit but kind limit: it is what separates label from prose that wandered
  ##   into `Name` key. Longest today is "permanent arena", at fifteen.



#[ Keys ]#

type Wording* = enum
  ## Name one piece of shown text, by what it is and where reader meets it.
  ##   First word is kind: `Tip` for tooltip, `Name` for words control itself wears, `Note`
  ##   for sentence shown in place, `Help` for cell of help table, which is fragment reader
  ##   reads across row rather than sentence or label.
  ##   Second is panel area: `Head` for section heading, `Row` for object row, `Apply`, `View`,
  ##   `Diag` for diagnostics, `Pick` for menu over selection, `Menu` for top menu, `Chip` for
  ##   row of constant controls.
  ##   One key per control, not per word: two controls may honestly wear same word, and
  ##   translator may still need them apart. `NameRowHide` and `NamePickHide` both read "hide"
  ##   today and are not one key.
  ##   Adding value here without row below does not compile, which is whole point of enum key.
  TipRowSelect, TipRowCommit, TipRowEdit, TipRowDiscardNew, TipRowDiscardEdit,
  TipRowVisible, TipRowRemove, TipRowRadius,
  TipApplyArity, TipApplyOperation, TipApplyFirst, TipApplySecond,
  TipViewMotor, TipViewAzimuth, TipViewElevation, TipViewDistance, TipViewSpeed, TipViewLens,
  TipDiagFrames, TipDiagVsync, TipDiagPermanent, TipDiagFrame, TipDiagPool, TipDiagScene,
  TipPickApply, TipPickOperation, TipPickBack, TipPickEdit, TipPickVisible, TipPickDelete,
  TipPickClose,
  TipMenuSceneFile, TipMenuImageFile, TipMenuSaveScene, TipMenuSaveImage, TipMenuLoadScene,
  TipChipAdd, TipChipUndo, TipChipRedo, TipChipAxes, TipChipGrid

  NameHeadObjects, NameHeadApply, NameHeadView, NameHeadDiagnostics,
  NameRowCommit, NameRowEdit, NameRowDiscard, NameRowHide, NameRowShow, NameRowRemove,
  NameRowLabel, NameRowInk, NameRowSize, NameRowCoefficients,
  NameApplyArity, NameApplyUnary, NameApplyBinary, NameApplyOperation, NameApplyFirst,
  NameApplySecond, NameApplyAct,
  NameViewMotor, NameViewAzimuth, NameViewElevation, NameViewDistance, NameViewSpeed,
  NameViewLens,
  NameDiagFrame, NameDiagVsync, NameDiagMemory, NameDiagPermanent, NameDiagFrameArena,
  NameDiagPool, NameDiagTotal,
  NamePickApply, NamePickEdit, NamePickBack, NamePickHide, NamePickShow, NamePickDelete,
  NamePickClose,
  NameMenuSave, NameMenuSaveScene, NameMenuSaveImage, NameMenuLoad, NameMenuLoadScene,
  NameMenuDemo, NameMenuSceneFile, NameMenuImageFile, NameMenuShow,
  NameChipAdd, NameChipUndo, NameChipRedo, NameChipAxes, NameChipGrid, NameChipHelp,
  NameChipMenu, NameChipDrawer,
  NameTitle,

  NoteListEmpty, NoteCoefficientsNew, NoteCoefficientsEdit, NoteDiagnostics,
  NoteSaveByHold, NoteSaveBlocked, NameSaveDismiss,

  NameTabDrag, NameTabSelect, NameTabMenu, NameTabPanel, NameTabCamera, NameTabKeys,
  NameTabOperations,
  NoteTabDrag, NoteTabSelect, NoteTabMenu, NoteTabPanel, NoteTabCamera, NoteTabKeys,
  NoteTabOperations,

  HelpDragOnto, HelpBuildUnasked, HelpBuildOrPause, HelpOpenWheel, HelpDragAloneOnto,
  HelpBuildDefined, HelpPauseMidDrag, HelpOpenWheelNoButton, HelpHandToPicker,
  HelpClickObject, HelpSameAndMenu, HelpSelectJustOne, HelpHoldShiftClick, HelpAddOrDrop,
  HelpClickSelected, HelpMenuBack, HelpClickEmpty, HelpClearOrSky, HelpPressHold,
  HelpSelectFills, HelpTapAnother, HelpAddToSelection,
  HelpRunOperation, HelpChangeObject, HelpKeepStopDrawing, HelpRemoveSelection,
  HelpClearClose,
  HelpCreatePoint, HelpRunCatalogue, HelpEveryObject, HelpWriteRead, HelpFurniture,
  HelpDragEmpty, HelpOrbit, HelpSlideSideways, HelpWheel, HelpMoveToward,
  HelpDragEmptyOrCrowd, HelpPinch, HelpMoveCloser, HelpDragTwoFingers,
  HelpEscape, HelpBackOut, HelpUndoRedoKeys, HelpUndoRedo, HelpTab, HelpMoveFocus,
  HelpTravel, HelpRoll, HelpLowerRaise, HelpFurtherCloser, HelpBackIntoView,
  HelpHighlightPrevNext, HelpSelectHighlighted, HelpCameraHome



#[ Catalogue ]#

const lut_wording_to_text: array[Wording, cstring] = [
  # Object row, and edit session it opens.
  TipRowSelect: "Add this object to the selection, or drop it; the 3D view rings each one.",
  TipRowCommit: "Commit these values to the scene.",
  TipRowEdit: "Rename, recolour or reshape this object; nothing changes until you save.",
  TipRowDiscardNew: "Discard this new object.",
  TipRowDiscardEdit: "Discard these changes.",
  TipRowVisible: "Show or hide this object without removing it.",
  TipRowRemove: "Delete this object; its handle is reused by the next one you add.",
  # Page read better than window here, so page's sentence is one both now say.
  TipRowRadius: "Radius the point is drawn at, in world units; it shrinks with distance.",

  # Apply section: operation over one or two operands.
  TipApplyArity: "Whether to list operations reading one operand or two.",
  TipApplyOperation:
    "Library operation to apply below; its own notation names m and n, the operands picked " &
    "next.",
  TipApplyFirst: "First operand -- `m` in the notation above -- every operation reads.",
  TipApplySecond: "Second operand -- `n` above -- this operation combines with `m`.",

  # View section: where camera stands and what it sees.
  TipViewMotor:
    "Where the camera stands and faces, as one rigid motion; a typed value settles on the " &
    "motion it names.",
  TipViewAzimuth: "Which way the camera faces round world up, read off its motor.",
  TipViewElevation: "How far the camera looks above or below level, read off its motor.",
  TipViewDistance:
    "How far the camera stands from the middle of the selection; it stays far enough out to " &
    "fit it.",
  TipViewSpeed: "How fast the camera flies right now, as a multiple of the speed of light.",
  TipViewLens: "Lens angle; smaller looks through a telephoto, larger through a wide angle.",

  # Diagnostics: what this frame cost and what storage it stands in.
  TipDiagFrames:
    "Milliseconds per drawn frame, oldest at the left and most recent at the right. An fps " &
    "average can hide an occasional slow frame; a spike here cannot hide.",
  TipDiagVsync:
    "Uncheck to see this build's own uncapped cost rather than the display's own refresh " &
    "rate; the reading below settles over about a second after any change.",
  TipDiagPermanent:
    "Never freed until the process exits: the pixel-export buffer, sized for the largest " &
    "frame this build allows, and every frame of a storyboard's own GIF.",
  TipDiagFrame:
    "Reset after every PNG or GIF frame it backs, so it reads empty almost any time you " &
    "would look here; the bar instead holds the largest single expansion it has served.",
  TipDiagPool:
    "One cell per object handle, in the colour of whatever object holds it; dark means it's " &
    "free and will be handed to the next one you add, most recently freed first.",
  TipDiagScene:
    "Scene is one fixed block sized for every handle up front, not allocated one object at a " &
    "time: `allocated` is that whole block, `used` is however much of it carries an object.",

  # Menu that opens over whatever is picked.
  TipPickApply:
    "Pick an operation to apply to what you selected, then press this again to apply it.",
  TipPickOperation:
    "Library operation; its own notation names m and n, the objects you selected.",
  TipPickBack: "Leave the operation unapplied.",
  TipPickEdit: "Rename, recolour or reshape it; nothing changes until you save.",
  TipPickVisible: "Show or hide the whole selection, without removing any of it.",
  TipPickDelete: "Delete the whole selection; each handle is reused by the next add.",
  TipPickClose: "Clear the selection, and put this menu away.",

  # Top menu: everything reached for rarely.
  TipMenuSceneFile: "File `save scene` writes to and `load scene` reads from.",
  TipMenuImageFile: "File `save image` and the `S` key both write the current frame to.",
  TipMenuSaveScene: "Save this scene as a .rgascene file.",
  TipMenuSaveImage: "Save the current view as a PNG image.",
  TipMenuLoadScene: "Load a .rgascene file, replacing this scene.",

  # Row of constant controls, floating over scene.
  TipChipAdd:
    "Compose a new object in the Objects list below; nothing joins the scene until you save " &
    "it. Greyed out while another edit is open, so starting this cannot discard it.",
  TipChipUndo:
    "Step back through scene-content edits, view and all; an orbit on its own is not a step.",
  TipChipRedo: "Step forward again; a fresh edit discards whatever was ahead.",
  TipChipAxes: "Toggle the red/green/blue x/y/z axis lines through the origin.",
  TipChipGrid: "Rule a grid on each selected plane, or stop.",

  # Section headings.
  NameHeadObjects: "objects",
  NameHeadApply: "apply",
  NameHeadView: "view",
  NameHeadDiagnostics: "diagnostics",

  # Object row, and edit session it opens.
  NameRowCommit: "save",
  NameRowEdit: "edit",
  NameRowDiscard: "✕",
  NameRowHide: "hide",
  NameRowShow: "show",
  NameRowRemove: "remove",
  NameRowLabel: "label",
  NameRowInk: "colour",
  NameRowSize: "size",
  NameRowCoefficients: "coefficients",

  # Apply section.
  NameApplyArity: "arity",
  NameApplyUnary: "unary",
  NameApplyBinary: "binary",
  NameApplyOperation: "operation",
  NameApplyFirst: "operand m",
  NameApplySecond: "operand n",
  NameApplyAct: "apply",

  # View section.
  NameViewMotor: "motor",
  NameViewAzimuth: "azimuth",
  NameViewElevation: "elevation",
  NameViewDistance: "distance",
  NameViewSpeed: "speed",
  NameViewLens: "field of view",

  # Diagnostics.
  NameDiagFrame: "frame time",
  NameDiagVsync: "vsync",
  NameDiagMemory: "memory",
  NameDiagPermanent: "permanent arena",
  NameDiagFrameArena: "frame arena",
  NameDiagPool: "object pool",
  NameDiagTotal: "total",

  # Menu that opens over whatever is picked.
  NamePickApply: "apply",
  NamePickEdit: "edit",
  NamePickBack: "back",
  NamePickHide: "hide",
  NamePickShow: "show",
  NamePickDelete: "delete",
  NamePickClose: "✕",

  # Top menu.
  NameMenuSave: "save",
  NameMenuSaveScene: "scene",
  NameMenuSaveImage: "image",
  NameMenuLoad: "load",
  NameMenuLoadScene: "scene",
  NameMenuDemo: "demo",
  NameMenuSceneFile: "scene file",
  NameMenuImageFile: "image file",
  NameMenuShow: "show",

  # Row of constant controls, floating over scene.
  NameChipAdd: "add",
  NameChipUndo: "undo",
  NameChipRedo: "redo",
  NameChipAxes: "axes",
  NameChipGrid: "grid",
  # Window padded this word to size its button; button is sized as button now, and word is
  #   word both front-ends show.
  NameChipHelp: "?",
  NameChipMenu: "☰",
  # Page alone: window has no drawer to open, since its panel never leaves. Shown only
  #   where chip row is too narrow to carry product's name, in place of it.
  NameChipDrawer: "◧",

  NameTitle: "RGA Visualiser",

  # Sentences shown in place, where control has nothing to hover.
  NoteListEmpty: "Nothing here yet -- press `add` above, or drag between two objects.",
  # Window said more than page here: both draw graded grid, so both may say so.
  NoteCoefficientsNew:
    "The 16 numbers of the new multivector, in the library's basis order, stacked one row " &
    "per grade. A live preview draws as soon as any goes non-zero; nothing joins the scene " &
    "until you save.",
  NoteCoefficientsEdit:
    "The 16 numbers of this object's own multivector, in the library's basis order, " &
    "stacked one row per grade. The object itself only moves when you save.",
  NoteDiagnostics: "Live cost of this build, updated every frame.",
  # Sentence rather than fragment: it stands in its own line under link, not after it.
  NoteSaveByHold: "Or press and hold the image to save it.",
  NoteSaveBlocked:
    "If nothing arrives, this frame is blocking it -- open this page in its own browser " &
    "tab and save from there.",
  NameSaveDismiss: "dismiss",

  # Help: one tab per way of working, named as reader would say what they are doing.
  NameTabDrag: "drag",
  NameTabSelect: "select",
  NameTabMenu: "menu",
  NameTabPanel: "panel",
  NameTabCamera: "camera",
  NameTabKeys: "keys",
  NameTabOperations: "operations",

  # Help: line above each tab's rows, carrying what two-column row cannot.
  #   Drag's line goes on to teach wheel's words, through `wheelWordsTaught`.
  NoteTabDrag:
    "Drag one object onto another to build a new one. Some pairs open a wheel of choices, " &
    "which name themselves in notation.",
  NoteTabSelect: "Say which objects to work on. Whatever is selected wears a white outline.",
  NoteTabMenu: "The small menu that appears beside whatever you just selected.",
  NoteTabPanel: "The panel and the buttons above it.",
  NoteTabCamera: "Move your viewpoint. None of this changes the scene itself.",
  NoteTabKeys: "Keyboard shortcuts. The 3D view needs focus first — press tab until it has it.",
  NoteTabOperations:
    "Every operation the apply section and the selection menu offer, and what each is " &
    "called.",

  # Help rows: what reader does, and what happens. Cells, not sentences: read across row.
  #   Row naming button or key composes it through `withButton` and `keysNamed`, so cell
  #   holds words alone and button's own name comes from `interaction`.
  HelpDragOnto: "drag one object onto another",
  HelpBuildUnasked: "build the one object those two define, without ever asking",
  HelpBuildOrPause: "build that object, or pause on the pivot to be asked",
  HelpOpenWheel: "open the wheel, whatever the pair would have made on its own",
  HelpDragAloneOnto: "drag an object on its own onto another",
  HelpBuildDefined: "build the one object those two define",
  HelpPauseMidDrag: "pause on the pivot mid-drag",
  HelpOpenWheelNoButton: "open the wheel without needing a second button",
  HelpHandToPicker: "hand both objects to the apply picker, which lists every operation",
  HelpClickObject: "click an object",
  HelpSameAndMenu: "the same, and open its menu of actions",
  HelpSelectJustOne: "select just that one, dropping anything else",
  HelpHoldShiftClick: "hold shift as you click",
  HelpAddOrDrop: "add it, or drop it again if it is already picked",
  HelpClickSelected: "click with objects selected",
  HelpMenuBack: "bring their menu back, changing nothing",
  HelpClickEmpty: "click empty space",
  HelpClearOrSky: "clear the selection, or pick the sky if there is one",
  HelpPressHold: "press and hold an object",
  HelpSelectFills: "select it — its outline fills as you hold",
  HelpTapAnother: "tap another object while one is selected",
  HelpAddToSelection: "add it to the selection",
  HelpRunOperation: "run any operation on what you selected",
  HelpChangeObject: "change the selected object's name, colour or coordinates",
  HelpKeepStopDrawing: "keep the selection but stop drawing it",
  HelpRemoveSelection: "remove the selection from the scene",
  HelpClearClose: "clear the selection and close this menu",
  HelpCreatePoint: "create a point by typing its coordinates",
  HelpRunCatalogue: "run any operation in the catalogue on what you selected",
  HelpEveryObject: "every object in the scene, each with rename, hide and delete",
  HelpWriteRead: "write the whole scene to a file, or read one back",
  HelpFurniture: "show or hide the reference furniture, leaving the scene alone",
  HelpDragEmpty: "drag empty space",
  HelpOrbit: "turn the view, or orbit whatever is selected",
  HelpSlideSideways: "slide the view sideways and up or down",
  HelpWheel: "wheel",
  HelpMoveToward: "move toward or away from whatever you point at",
  HelpDragEmptyOrCrowd: "drag empty space, or a crowd of objects, with one finger",
  HelpPinch: "pinch",
  HelpMoveCloser: "move closer in or further out",
  HelpDragTwoFingers: "drag with two fingers",
  HelpEscape: "escape",
  HelpBackOut: "back out of whatever is part-way through, one step at a time",
  HelpUndoRedoKeys: "ctrl+z, ctrl+shift+z",
  HelpUndoRedo: "undo, then redo, the last change to the scene",
  HelpTab: "tab",
  HelpMoveFocus: "move focus between the controls and the 3D view",
  HelpTravel: "fly the view forward, back and sideways; hold shift to move faster",
  HelpRoll: "roll the view to either side",
  HelpLowerRaise: "lower or raise the view",
  HelpFurtherCloser: "move further out, or closer in",
  HelpBackIntoView: "bring whatever is selected back into view",
  HelpHighlightPrevNext: "move the highlight to the previous or next object",
  HelpSelectHighlighted: "select the highlighted object; hold shift to add it",
  HelpCameraHome: "put the camera back where it started",
]
  ## Hold text for every key, written with its key rather than by position.
  ##   Named form is deliberate: `[TipRowSelect: "...", ...]` cannot be knocked out of step by
  ##   inserted row, and leaves compiler to refuse key with no text.



#[ Reading ]#

func wordingText*(key: Wording): cstring =
  ## Report words `key` stands for.
  ##   Named for what it returns, as `lut_ink_to_name` and `nimBasisName` are. `wordingOf`
  ##   named key twice over, since key *is* wording.
  ##   Total by construction: table is indexed by enum and compiler refuses gap, so there is
  ##   no miss and no fallback for one.
  ##   `cstring` rather than `string`: tooltip is asked for once per control per frame, and
  ##   returning `string` would copy static text on every one of them. Const `cstring` points
  ##   at bytes already in binary and costs nothing to hand over.
  lut_wording_to_text[key]


func demoWording*(objects: int, is_default: bool): string =
  ## Report text for one demo size, which names size it loads.
  ##   Composed rather than stored, since sentence carries number only caller knows. Parts are
  ##   here so wording stays in one file; caller supplies figure alone.
  "Load the orrery at " & $objects & " objects: the real solar neighbourhood to scale, one " &
    "unit one astronomical unit, Sol at the origin, every drawable kind present. The same " &
    "arrangement at every size, reaching further into the star catalogue as it grows." &
    (if is_default: " The size everything opens on." else: "")


const NAME_AUTHORITY* = "Projective Geometric Algebra Illuminated"
  ## Name book this project replicates, as its author titled it.
  ##   Not catalogue row: it names no control and carries no sentence, and no translator
  ##   renames book.


func captionWindow*(): string =
  ## Report caption desktop window wears: authority it replicates, then application's name.
  ##   Composed rather than stored, as `demoWording` is: half is catalogue's and half is
  ##   this project's subject. Second copy of name is exactly what drifted -- window said
  ##   `RGA visualiser` where page said `RGA Visualiser`, and no sweep reached entry point
  ##   holding it.
  ##   Lives here rather than beside window so suite can hold it: `main` links SDL and GL,
  ##   which no test binary carries.
  NAME_AUTHORITY & " — " & $wordingText(NameTitle)


func namesControl*(key: Wording): bool =
  ## Report whether `key` names control rather than carrying prose.
  ##   Read from key's own first word, which enum's doc above fixes: key added without kind
  ##   in its name is caught by suite rather than classified wrongly in silence.
  ##   For suite, which holds prose to sentence's shape and label to label's: "add" is not
  ##   sentence and must not be asked to end like one.
  ($key).startsWith("Name")


func isHelpCell*(key: Wording): bool =
  ## Report whether `key` is cell of help table rather than sentence or label.
  ##   Read from key's first word, as `namesControl` is. Cell is fragment reader reads across
  ##   its row -- no capital opens it and no full stop closes it -- so suite holds it to
  ##   neither shape, and to its own.
  ($key).startsWith("Help")


func hasWords*(key: Wording): bool =
  ## Report whether `key` carries words worth showing.
  ##   For suite, which holds every key to it: empty entry would draw empty tooltip, which is
  ##   worse than none at all.
  len(strip($lut_wording_to_text[key])) > 0



#[ Help Composed ]#

func withButton*(button: string, key: Wording): string =
  ## Write help cell naming which button does it: `left-click an object`.
  ##   Button's name is `interaction`'s, read from its own enum; hyphen and cell are here.
  button & "-" & $wordingText(key)


func sectionNamed*(key: Wording): string =
  ## Write help cell naming panel section by heading it wears: `the apply section`.
  "the " & $wordingText(key) & " section"


func wedgeNamed*(label: string): string =
  ## Write help cell naming wheel wedge by label it wears: `the … wedge`.
  "the " & label & " wedge"


func namesJoined*(names: openArray[string]): string =
  ## Write help cell listing several keys or controls: `w, a, s, d`.
  names.join(", ")


func pathNamed*(keys: openArray[Wording]): string =
  ## Write help cell naming menu path by its buttons: `save scene`.
  var said: seq[string]
  for key in keys: said.add($wordingText(key))
  said.join(" ")


func wheelWordsTaught*(taught: openArray[tuple[notation, word: string]]): string =
  ## Say which notation each wheel wedge wears, and which word that notation is.
  ##   Notation first: reader arrives holding what wedge said and wants its name.
  ##   Sentence of its own, which `help` sets after `NoteTabDrag`.
  var said: seq[string]
  for (notation, word) in taught: said.add(notation & " is " & word)
  said[0 ..< said.len - 1].join(", ") & " and " & said[^1] & "."



#[ Outcomes ]#

func objectsCounted*(count: int): string =
  ## Name `count` objects, singular where there is one.
  ##   "1 object", never "1 object(s)": parenthesis is what writing says when it holds
  ##   count and will not spend word on it.
  if count == 1: "1 object" else: $count & " objects"


func deletedMessage*(count: int): string =
  ## Report whole selection leaving scene.
  "Deleted " & objectsCounted(count) & "."


func visibilityMessage*(count: int, is_shown: bool): string =
  ## Report whole selection being shown or hidden.
  ##   Reads way button that did it read, which is what selection would become.
  (if is_shown: "Showed " else: "Hid ") & objectsCounted(count) & "."


func addedMessage*(label: string): string =
  ## Report object joining scene under `label`.
  "Added `" & label & "`."


func savedMessage*(label: string): string =
  ## Report edit to object already in scene being committed.
  "Saved `" & label & "`."


func removedMessage*(label: string): string =
  ## Report one object leaving scene.
  "Removed `" & label & "`."


func derivedMessage*(label, kind: string): string =
  ## Report operation deriving object `label` of `kind`.
  ##   Was written at four sites, one per front-end and two in shared code, and one edit
  ##   would have moved one of them.
  label & " gave " & kind & "."


func fullMessage*(): string =
  ## Refuse action for want of free handle.
  "Scene is full."


func emptyMessage*(): string =
  ## Refuse apply for want of operand.
  ##   "object" is glossary's word for what scene holds; front-ends said "point" and
  ##   "multivector", and neither is it.
  "Scene is empty; add an object first."


func cancelledMessage*(): string =
  ## Report gesture reader called off before it landed.
  ##   Escape over drag in progress, on either build.
  "Cancelled."


func stepMessage*(is_undo: bool): string =
  ## Refuse step past end of timeline.
  ##   Step that lands says nothing: scene and view both move, and that is answer.
  if is_undo: "Nothing to undo." else: "Nothing to redo."


func orreryMessage*(count, capacity: int): string =
  ## Report demo scene replacing whatever stood before it.
  "Loaded the orrery: " & objectsCounted(count) & ", " & $(capacity - count) &
    " handles free."


func appendDegrees*(storage: var openArray[char], cursor: var int, radians: float) =
  ## Write angle panel reads off camera, in degrees, straight into `storage`.
  ##   Degrees rather than radians: reading is for eye, and nothing types it back.
  appendMagnitude(storage, cursor, radToDeg(radians))
  appendChars(storage, cursor, "°")


func appendSpeedLight*(storage: var openArray[char], cursor: var int, multiple: float) =
  ## Write speed panel reads, as multiple of speed of light, straight into `storage`.
  ##   Caller divides by `camera.SPEED_LIGHT`, which is this build's reporting unit.
  ##   Unit is glue this composer owns, as `objectsCounted` owns its noun.
  appendMagnitude(storage, cursor, multiple)
  appendChars(storage, cursor, " c")


func appendRuler*(storage: var openArray[char], cursor: var int, span: float) =
  ## Write length scale bar claims, in world units, straight into `storage`.
  ##   Noun is glue this composer owns, as `appendSpeedLight` owns its unit.
  ##   Singular at one, which 1-2-5 step lands on once in each ten decades.
  appendMagnitude(storage, cursor, span)
  appendChars(storage, cursor, if span == 1.0: " unit" else: " units")

