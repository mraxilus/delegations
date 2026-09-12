## Say what last action did, in words both front-ends use and for time both hold it.
##
## Outcome of action is reported same way by either build: one short sentence, over scene,
## gone again by itself.
##   Sentence was written twice, once per front-end, and two copies drifted. One press of
##   `delete` counted what it removed on page and named whole selection instead in window;
##   apply over empty scene asked for "point" on one side and "multivector" on other, and
##   glossary calls it neither -- it is object.
##   Life was written twice as well: `3200` in `state.ts`, against nothing at all in window,
##   whose line simply stood until something replaced it, seeded with "Ready." that was
##   outcome of no action at all.
## Only what *both* builds say lives here. Outcome one build alone can reach -- page's
## download routes, window's image export, its own scene file -- stays where it is said.
## Sentences allocate, unlike `format`'s appenders: one is built per action reader takes,
## never per object per frame.
##
## Shared by desktop (`panel.nim`) and browser (`bridge.nim`, then `state.ts`).

{.experimental: "strictFuncs".}



#[ How Long It Stands ]#

const
  MESSAGE_MAX* = 96
    ## Bound length of outcome reported after action.
    ##   Window copies sentence into storage this wide and marks anything longer with
    ##   ellipsis; suite holds every sentence here under it, so none is ever cut off.

  SECONDS_MESSAGE* = 3.2
    ## Hold outcome on screen this long, then take it away.
    ##   Long enough to read short sentence twice; short enough to be gone before next
    ##   action wants to say its own.
    ##   Read by page through `nimMessageSeconds` rather than written there again.

  SECONDS_MESSAGE_FADE* = 0.35
    ## Fade outcome out over this long once it has stood its time.
    ##   Same 350 ms `--anim` gives every other transition on page.



func messageFade*(age: float): float =
  ## Report how much of outcome is still on screen `age` seconds after it was said.
  ##   One while it stands, falling to nothing across `SECONDS_MESSAGE_FADE`, and nothing
  ##   after that -- which is whole point: window's own line had no age at all and stood
  ##   until something else replaced it, so scene carried outcome of action taken minutes
  ##   ago as if it had just happened.
  ##   Stated here rather than in `panel.nim` so it can be held to by suite, which cannot
  ##   reach drawing.
  if age <= SECONDS_MESSAGE: 1.0
  elif age >= SECONDS_MESSAGE + SECONDS_MESSAGE_FADE: 0.0
  else: 1.0 - (age - SECONDS_MESSAGE)/SECONDS_MESSAGE_FADE



#[ What It Says ]#

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
