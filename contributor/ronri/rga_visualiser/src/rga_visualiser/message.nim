## Hold how long outcome of last action stands, for time both front-ends hold it.
##
## Outcome of action is reported same way by either build: one short sentence, over scene,
## gone again by itself. Sentence is `wording`'s, with every other word reader sees; what
## stays here is its life.
##   Life was written twice: `3200` in `state.ts`, against nothing at all in window, whose
##   line simply stood until something replaced it, seeded with "Ready." that was outcome of
##   no action at all.
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
