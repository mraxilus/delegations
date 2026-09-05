## Say when drawing moves, so picture and page agree about it.
##
##   Move is no instant.  It is something drawing does, and every drawing
##     says it same way at heart: mark that says *you are here* leaves frame
##     being held and arrives at frame chosen.
##     That much is shared, and is what makes two drawings of one ontology
##     read as two views of one movement.
##   How much else drawing has to do around that is its own business, and
##     differs by how much it is showing.  Drawing of one frame and its ways
##     out has to clear ways not taken before mark can move and grow new ones
##     after it has, and needs time to do it; drawing of whole ontology has
##     every frame already in place and nothing to build -- mark moves, what
##     is within reach changes, and that is whole of it.  So each drawing
##     carries its own `Tempo` rather than sharing one schedule.
##     Cost of tempo per drawing: page can assume nothing about timing -- it
##       must read each drawing's own numbers.  Accepted -- one shared
##       schedule makes whole-ontology drawing wait out clauses it has
##       nothing to say.
##   `Tempo` is what drawing tells page: when mark moves, and when drawing
##     has finished saying what it has to say.  Page needs that to know when
##     state may move, and stylesheet needs same numbers to run animation.
##     Cost of writing times onto drawing as custom properties: stylesheet
##       cannot be read alone -- its numbers arrive with markup.  Accepted --
##       written once onto drawing, page and stylesheet cannot drift from
##       each other.
##   Whole of move is told in one drawing.  Page replaces drawing exactly
##     once, at end, at one instant when what is on screen and what would
##     replace it are same picture.
##     Cost of swapping only at seam: page holds old drawing through whole
##       telling, however long that takes.  Accepted -- swap made there
##       cannot be seen, which is why it is made there and nowhere else.

{.experimental: "strictFuncs".}



#[ Phases ]#

type Motion* {.pure.} = enum ## Name what drawing is doing at one instant.
  Still,    ## Nothing is moving; drawing shows frame couple hold.
  Leaving,  ## Move is chosen, and drawing is telling whole of it.
  Arriving  ## Frame reached is held, and its own ways are growing.


func phase*(motion: Motion): string =
  ## Name phase for stylesheet, which is what selects animation.
  case motion
  of Motion.Still: "still"
  of Motion.Leaving: "leaving"
  of Motion.Arriving: "arriving"



#[ Tempo ]#

type Tempo* = object ## Say when drawing moves, and for how long.
  pass_at*: int  ## When mark leaves frame held, from move being asked for.
  pass*: int     ## How long mark takes to reach frame chosen.
  settle*: int   ## How long after that before drawing may be replaced.
  grown*: int    ## How long after *that* before drawing has finished moving.


func leaveTime*(tempo: Tempo): int = tempo.pass_at + tempo.pass + tempo.settle
  ## Get when page may replace drawing and let state move with it.


func moveTime*(tempo: Tempo): int = tempo.leaveTime + tempo.grown
  ## Get when everything one move set going has finished.


func leadOnTime*(tempo: Tempo): int = tempo.moveTime
  ## Get when second move of compound may start.
  ##   Not before first has finished being told.  Lead thinks of two as one
  ##     thing, but ontology knows frame between them is real, and drawing
  ##     that began unsaying it before it had finished saying it would be
  ##     claiming couple were never there.


func passStyle*(tempo: Tempo): string =
  ## Write shared times onto drawing, for stylesheet to spend.
  "--pass-at: " & $tempo.pass_at & "ms; --pass: " & $tempo.pass & "ms"


const SEAM_MARGIN* = 60
  ## Room every drawing leaves between its last movement ending and page
  ## replacing it.
  ##   Animation's clock starts when browser first draws element, frame or
  ##     two after page asked for phase, so anything timed to end exactly
  ##     when drawing is replaced is in fact still running then, and is cut
  ##     off wherever it had got to.
  ##   Nothing is moving during margin, so it costs reader nothing.
