## Hold every word either front-end shows reader, once.
##
## Shown text was written where it is drawn, which put one sentence in two languages and let
## copies drift apart unseen: two front-ends worded point's radius differently, window told
## reader sun is drawn flat where page did not, and window explained forty-one controls
## against page's eleven. No check could see any of it, because
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
## What is *not* here: text one front-end alone can reach, which has no copy to drift from.
## Window's `memory` and `total` headings, page's own diagnostic rows, and page's `dismiss` are
## each shown by one front-end and stay where they are.
## Outcome sentences live in `message` and help rows in `help`; both are shared already, and
## both move here as stage three.
##
## Shared by desktop (`panel.nim`) and browser (`bridge.nim`, then its scripts).

{.experimental: "strictFuncs".}

import std/strutils

const RUNES_LABEL_MOST* = 24
  ## Bound how long word on control may be, in runes.
  ##   Not layout limit but kind limit: it is what separates label from prose that wandered
  ##   into `Name` key. Longest today is "permanent arena", at fifteen.



#[ Keys ]#

type Wording* = enum
  ## Name one piece of shown text, by what it is and where reader meets it.
  ##   First word is kind: `Tip` for tooltip, `Name` for words control itself wears, `Note`
  ##   for sentence shown in place.
  ##   Second is panel area: `Head` for section heading, `Row` for object row, `Apply`, `View`,
  ##   `Diag` for diagnostics, `Pick` for menu over selection, `Menu` for top menu, `Chip` for
  ##   row of constant controls.
  ##   One key per control, not per word: two controls may honestly wear same word, and
  ##   translator may still need them apart. `NameRowHide` and `NamePickHide` both read "hide"
  ##   today and are not one key.
  ##   Adding value here without row below does not compile, which is whole point of enum key.
  TipRowSelect, TipRowCommit, TipRowEdit, TipRowDiscardNew, TipRowDiscardEdit,
  TipRowVisible, TipRowRemove, TipRowRadius, TipRowShines,
  TipApplyArity, TipApplyOperation, TipApplyFirst, TipApplySecond,
  TipViewAzimuth, TipViewElevation, TipViewDistance, TipViewPivot, TipViewLens,
  TipDiagFrames, TipDiagVsync, TipDiagPermanent, TipDiagFrame, TipDiagPool, TipDiagScene,
  TipPickApply, TipPickOperation, TipPickBack, TipPickEdit, TipPickVisible, TipPickDelete,
  TipPickClose,
  TipMenuSceneFile, TipMenuImageFile, TipMenuSaveScene, TipMenuSaveImage, TipMenuLoadScene,
  TipChipAdd, TipChipUndo, TipChipRedo, TipChipAxes, TipChipGrid

  NameHeadObjects, NameHeadApply, NameHeadView, NameHeadDiagnostics,
  NameRowCommit, NameRowEdit, NameRowDiscard, NameRowHide, NameRowShow, NameRowRemove,
  NameRowLabel, NameRowInk, NameRowSize, NameRowShines, NameRowCoefficients,
  NameApplyArity, NameApplyUnary, NameApplyBinary, NameApplyOperation, NameApplyFirst,
  NameApplySecond, NameApplyAct,
  NameViewAzimuth, NameViewElevation, NameViewDistance, NameViewPivot, NameViewLens,
  NameDiagFrame, NameDiagVsync, NameDiagMemory, NameDiagPermanent, NameDiagFrameArena,
  NameDiagPool, NameDiagTotal,
  NamePickApply, NamePickEdit, NamePickBack, NamePickHide, NamePickShow, NamePickDelete,
  NamePickClose,
  NameMenuSave, NameMenuSaveScene, NameMenuSaveImage, NameMenuLoad, NameMenuLoadScene,
  NameMenuDemo, NameMenuSceneFile, NameMenuImageFile,
  NameChipAdd, NameChipUndo, NameChipRedo, NameChipAxes, NameChipGrid, NameChipHelp,
  NameChipMenu,
  NameTitle,

  NoteListEmpty, NoteCoefficientsNew, NoteCoefficientsEdit, NoteDiagnostics,
  NoteSaveByHold, NoteSaveBlocked, NameSaveDismiss



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
  # Window said more than page here -- "drawn flat" is fact about drawing page had lost.
  TipRowShines: "A sun: lights every other point from where it stands, and is drawn flat.",

  # Apply section: operation over one or two operands.
  TipApplyArity: "Whether to list operations reading one operand or two.",
  TipApplyOperation:
    "Library operation to apply below; its own notation names m and n, the operands picked " &
    "next.",
  TipApplyFirst: "First operand -- `m` in the notation above -- every operation reads.",
  TipApplySecond: "Second operand -- `n` above -- this operation combines with `m`.",

  # View section: where camera stands and what it sees.
  TipViewAzimuth: "Spin the camera around its pivot.",
  TipViewElevation: "Tilt the camera up or down; clamped short of looking straight up or down.",
  TipViewDistance: "Move the camera toward or away from its pivot.",
  TipViewPivot: "World point the camera looks at and orbits around.",
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
  TipChipGrid: "Toggle the reference grid at z = 0.",

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
  NameRowShines: "shines",
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
  NameViewAzimuth: "azimuth",
  NameViewElevation: "elevation",
  NameViewDistance: "distance",
  NameViewPivot: "pivot",
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
  "Load the orrery at " & $objects & " objects: the real solar neighbourhood, Sol at the " &
    "origin, every drawable kind present. The same arrangement at every size, reaching " &
    "further into the star catalogue as it grows." &
    (if is_default: " The size everything opens on." else: "")


func namesControl*(key: Wording): bool =
  ## Report whether `key` names control rather than carrying prose.
  ##   Read from key's own first word, which enum's doc above fixes: key added without kind
  ##   in its name is caught by suite rather than classified wrongly in silence.
  ##   For suite, which holds prose to sentence's shape and label to label's: "add" is not
  ##   sentence and must not be asked to end like one.
  ($key).startsWith("Name")


func hasWords*(key: Wording): bool =
  ## Report whether `key` carries words worth showing.
  ##   For suite, which holds every key to it: empty entry would draw empty tooltip, which is
  ##   worse than none at all.
  len(strip($lut_wording_to_text[key])) > 0
