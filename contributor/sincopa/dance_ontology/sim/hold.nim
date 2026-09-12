## What couple is asked to do: which hands are joined, and what may stop turn.
##
##   Kept apart from anything that answers it, so question outlives whichever
##     engine answers.  Solver this project began with is gone; these words are
##     what survived it, and they are named for what dancer feels, not for how
##     engine is built.

{.experimental: "strictFuncs".}

import ./body


type
  Link* = object ## One connection: which two hands it joins.
    ends*: array[2, Hand]

  Stop* {.pure.} = enum ## What ends turn, one thing at once.
    None,     ## Nothing: it holds.
    Reach,    ## Hands drew apart with every joint still inside its range.
    Twist,    ## Upper arm turned about its own length as far as it goes.
    Elbow,    ## Elbow at its bend.
    Wrist,    ## Hand as far off forearm as it goes.
    Knuckle,  ## Fingers folded as far as they go.
    Swing,    ## Upper arm too far behind or across body.
    Through,  ## Arm against body.
    Arms      ## Arm against arm.


func says*(stop: Stop): string =
  ## What to tell reader when turn ends this way.
  case stop
  of Stop.None: "nothing gives"
  of Stop.Reach: "hands pull apart: arms are not long enough"
  of Stop.Twist: "shoulder twists no further"
  of Stop.Elbow: "elbow bends no further"
  of Stop.Wrist: "wrist bends no further"
  of Stop.Knuckle: "fingers fold no further"
  of Stop.Swing: "upper arm swings no further behind or across"
  of Stop.Through: "arm meets body"
  of Stop.Arms: "arm meets arm"
