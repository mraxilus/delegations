## Draw frame, once, for every place that shows one.
##
##   Picture is couple seen from above: two bodies as plain circles,
##     each with small chevron at its centre saying which way it faces,
##     lead at bottom facing up page.  Connection runs hand to hand
##     as taut string that goes **round** body rather than through one, so
##     hold that crosses is drawn crossing.
##     What this replaces is schematic: two rows of hands with dashed
##       midline between them, where whether connection crossed had to be
##       read off which side of line it passed.  Bodies are in
##       picture now, so crossing is thing you can see instead of
##       convention you have to know.
##   Lead's hands are squares and follow's are circles, so picture
##     drawn too small for word beside it still says which is whose.  Each
##     is in **its own side's colour** -- Left hand is blue whoever holds it
##     -- and in **its owner's shade**: lead's deep, follow's plain.
##     Connection carries both, meeting at its middle, so line itself
##     draws which named hands are joined.
##   Held hand is hollow outline, because hollow is what unsaid level
##     looks like and `Frame` says no level.  Free one is same outline
##     at half strength.  What is held is said by connection running out
##     of it, which is mark that survives being shrunk.
##   Where both connections cross they overlap, and one underneath is
##     drawn with break in it.
##     Cost of break: under connection really is cut -- stretch of its
##       ink is missing.  Accepted -- masking stroke has to know colour
##       of ground it sits on, and these pictures are also written out as
##       standalone files, to be shown on grounds this module cannot see.
##   Colours come through custom properties with fallbacks, for same
##     reason: inside page that defines `--left` and `--right` picture
##     follows page, including its light and dark themes.
##     Cost of fallback ink: on its own picture is tuned to neither
##       ground, only readable on either.  Accepted -- standalone file
##       cannot know ground it will be shown on.
##   None of drawing is here.  Marks were settled in mock-up
##     workbench and live in `draw/`, which workbench and app both
##     read, so two cannot drift; `draw/scene` builds every frame's
##     picture at compile time and this module is frame around it.

{.experimental: "strictFuncs".}

import ./frame
import ./rotation
import ./draw/scene



#[ Geometry ]#

const
  WIDTH = 100
  HEIGHT = 116
    ## Shape of frame picture's box, as everything laid out around one
    ## measures it: twenty-five wide to twenty-nine tall.
  VIEW = "-45 -52.2 90 104.4"
    ## And box itself, in drawing's own units, which are centred on
    ## couple's own middle.
    ##   Same twenty-five to twenty-nine, so nothing that places
    ##     picture has to move; sized to what drawing actually reaches,
    ##     which is 58.5 across by 98.2 down, measured over all sixteen
    ##     pictures with every stroke's cap counted in.
    ##   Taller than drawing is wide, and air is left at sides:
    ##     two bodies one above other make tall picture, and cropping
    ##     to it would make every node on every map tall and thin.



#[ Frames ]#

func frameBody(target: Frame; twist: HalfTurns): string =
  ## Draw contents of frame picture, without frame around them.
  ##   Two things reach drawing, and no more: whether follow faces, and
  ##     which way she turned if she does not.  Whole turn puts her back
  ##     where she was, so size of twist says nothing past its parity --
  ##     but its *sign* does, wherever turning makes two connections cross
  ##     and something has to say which of them is over (rule 14).
  ##   Arithmetic is done here because `scene` may not have `rotation`'s
  ##     words; it takes two plain flags.
  "<title>" & target.describe & "</title>" &
    sceneFor(target, isFacing(twist), clockwise = twist > 0)


func frameHeight*(width: int): int =
  ## Get how tall frame picture is when drawn to given width.
  (width * HEIGHT) div WIDTH


func renderFrame*(target: Frame; twist: HalfTurns = 0): string =
  ## Draw frame as picture that stands on its own.
  ##   Given twist it draws posture instead: same frame, seen with
  ##     follow turned as far as that twist has turned them.
  "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"" & VIEW &
    "\" class=\"frame\" role=\"img\">" & frameBody(target, twist) & "</svg>"


func renderFramePlaced*(target: Frame; x, y, width: int;
    twist: HalfTurns = 0): string =
  ## Draw frame picture at place inside larger drawing.
  ##   Same body, given its own viewport: nested picture keeps its own
  ##     coordinates, so drawing around it never has to know how frame
  ##     is made.
  "<svg x=\"" & $x & "\" y=\"" & $y & "\" width=\"" & $width & "\" height=\"" &
    $frameHeight(width) & "\" viewBox=\"" & VIEW &
    "\" class=\"frame\">" & frameBody(target, twist) & "</svg>"
