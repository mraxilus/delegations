## Drive partner-work ontology from browser, as check on model.
##
##   Page is validator before it is toy: it shows frame couple
##     is in, every frame one primitive away, and every frame that is *not*,
##     with number of primitives it would take to get there.  Nothing
##     outside offered list can be clicked, so move ontology does not
##     derive cannot be danced.
##   Only rendering lives here.  Frames and moves come from
##     `dance_ontology`, unchanged, so page cannot quietly disagree with
##     tests.
##   Every change of state regenerates markup from session state,
##     rather than patching pieces that changed.
##     Cost of regenerating per interaction: element under reader's
##       finger is destroyed with rest and browser drops focus to
##       document, so keyboard standing has to be saved and restored by hand --
##       `holding` and `standAgain` pay it, and `paintStage` narrows move's
##       redraw so animation is not rebuilt out from under itself.
##   What model has to say about spreadsheet it was read from is not
##     here and should not be: it is finding about document rather than
##     fact about two bodies, it is true whether or not anyone is dancing, and
##     reader who wants it wants to read it rather than click through it.  It
##     lives in `doc/review.html`, which is written from same model, and in
##     `nimble audit`.

{.experimental: "strictFuncs".}

import std/[options, strutils]
import std/dom except Frame ## Exclude browser's own `Frame`, which is window.

import ../src/dance_ontology



#[ Session ]#

type
  View {.pure.} = enum ## Select what page is showing.
    Atlas,  ## Every frame there is, which is what ontology *is*.
    Dance,  ## One frame alone, and what can be done from it.
    Matrix  ## Every move there is, as one table.

  Drawing {.pure.} = enum ## Select how frame is drawn while dancing.
    Dynamic,  ## Frame in middle and every way out of it.
    Overview  ## Whole ontology, with couple somewhere in it.

  Filter = object ## Narrow list of frames to ones worth looking at.
    holds: Option[int]   ## Number of connections, where that is being asked for.
    lead: Option[Side]   ## Hand of lead that must be holding something.
    follow: Option[Site] ## Hand of follow that must be held.

  Step = object ## Hold one danced move, for history.
    phrase: string
    to: Frame


func startFrame(): Frame =
  ## Get frame dance begins in: `free`, nothing held.
  ##   Where couple starts, and one frame nothing has to lead up to.
  ##   Reader who opens Dance view without first picking frame in
  ##     atlas used to be put down in one-hand hold, in middle of
  ##     ontology, with no account of how they got there.
  ##   From here every way out is collect, which is ladder seen from
  ##     bottom of it.
  fromKey("--.").get


var
  origin = startFrame()
  current = startFrame()
  view = View.Atlas
  drawing = Drawing.Dynamic
  drawing_chosen = false        ## Whether reader has picked drawing themselves.
  filter = Filter()
  history: seq[Step] = @[]
  motion = Motion.Still     ## What drawings are doing at this instant.
  taken = none(Frame)       ## Frame being moved to, while couple are leaving.
  queued = none(Frame)      ## Second move of compound, waiting for first.
  generation = 0            ## Which move is in flight, so older one can be dropped.


func tempoOf(drawing: Drawing): Tempo =
  ## Get how long drawing on show takes to say move.
  ##   Page waits on whichever drawing dancer is actually watching.
  ##   Close drawing has to clear its ways out and build next lot;
  ##     map has every frame in place already and only has to move mark.
  ##   Making map keep close drawing's time would leave it finished and
  ##     waiting, which reads as page having stopped rather than as move
  ##     being made.
  case drawing
  of Drawing.Dynamic: CLOSE_TEMPO
  of Drawing.Overview: WIDE_TEMPO


proc holding(): string =
  ## Remember which control reader is standing on, before it is replaced.
  ##   Every change of state rewrites page, so element under
  ##     reader's finger is deleted and browser drops focus to document.
  ##   For pointer that costs nothing; for keyboard it means next key
  ##     does nothing at all, which on page whose whole claim is that what it
  ##     refuses is meaningful is refusal that means nothing.
  let on = document.activeElement
  if on == nil or on.getAttribute("data-action") == nil:
    return ""
  $on.getAttribute("data-action") & " " & $on.getAttribute("data-value")


proc standAgain(held: string) =
  ## Put reader back where they were standing, or on frame if it moved.
  if held.len == 0:
    return
  let
    parts = held.split(' ')
    sought = document.querySelector(cstring("[data-action=\"" & parts[0] &
      "\"][data-value=\"" & parts[1] & "\"]"))
  if sought != nil:
    sought.focus()
    return
  # Control is gone because taking it changed frame.  Land on frame
  # itself rather than on whatever move now sits where that button was: key
  # pressed again should not dance move nobody chose.
  let stage = document.getElementById("stage")
  if stage != nil:
    stage.focus()


proc say(sentence: string) =
  ## Tell reader who cannot see drawing what drawing now shows.
  ##   Live region lives outside part of page that is rewritten,
  ##     because live region that is itself replaced announces nothing:
  ##     browser has no old text to compare new text against.
  let voice = document.getElementById("said")
  if voice != nil:
    voice.textContent = cstring(sentence)


proc atOnce(): bool =
  ## Test whether reader has asked for no movement.
  ##   Reader who has turned animation off should not be made to wait out
  ##     animation that is not running: every phase collapses into one
  ##     change of state that phases were spelling out.
  window.matchMedia("(prefers-reduced-motion: reduce)").matches


proc roomForMap(): bool =
  ## Test whether screen has room to draw map at legible size.
  ##   Asked of stylesheet rather than answered here.
  ##     Which widths are wide is question about layout, and layout
  ##       is written there: answer is map's own least width plus
  ##       margins page is laid out with, and copy of that sum kept in
  ##       script would be second thing to change and second thing to
  ##       get wrong.
  ##   This is mirror of `motion.nim`, which owns times and writes them
  ##     out for stylesheet to spend.
  ($window.getComputedStyle(document.documentElement)
    .getPropertyValue("--wide")).strip() == "1"


proc setScrollLeft(e: Node; value: int) {.importcpp: "#.scrollLeft = #", nodecl.}
  ## Set how far scrolling box is scrolled; `std/dom` only reads it.


proc centreOnHeld() =
  ## Slide close drawing so frame being held is part you can see.
  ##   Drawing is cut to frame, and widest frame is wider than
  ##     phone: `free` fans four ways out and wants 728 pixels.
  ##   Left where browser puts scrolling box, narrow screen shows
  ##     left edge of that fan and not frame whole view is about.
  ##   Nothing is unreachable either way -- every way out is button in
  ##     list beside drawing -- so this is only about what you are looking
  ##     at when you arrive.
  let
    scroller = document.querySelector(".view-spokes .scroll")
    held = document.querySelector(".view-spokes .core")
  if scroller == nil or held == nil:
    return
  let
    room = scroller.getBoundingClientRect()
    on = held.getBoundingClientRect()
    off = (on.left + on.width / 2) - (room.left + room.width / 2)
  setScrollLeft(scroller, scroller.scrollLeft + int(off))


proc suitDrawing() =
  ## Open in whichever drawing screen has room for.
  ##   Map says more and only wants width; close drawing is one
  ##     that survives phone.
  ##   So page follows screen -- and stops once reader picks
  ##     drawing, because choice made is worth more than default, and
  ##     window dragged narrower should not take it back.
  if not drawing_chosen:
    drawing = if roomForMap(): Drawing.Overview else: Drawing.Dynamic



#[ Markup ]#

func esc(text: string): string =
  ## Escape text for placement in markup, quotes included.
  ##   Stricter than review page's `escape`: this one also feeds
  ##     attribute values, where bare quote ends attribute.
  text.multiReplace(("&", "&amp;"), ("<", "&lt;"), (">", "&gt;"), ("\"", "&quot;"))


func tag(name, attributes, body: string): string =
  ## Wrap body in one element, with attributes already formed.
  "<" & name & (if attributes.len > 0: " " & attributes else: "") & ">" & body &
    "</" & name & ">"


func inked(said: string): string =
  ## Say phrase with each hand it names drawn in that dancer's own ink.
  ##   `collect Left to left` joins two hands, and sentence already says
  ##     which two -- `Left` is lead's and `left` follow's, by case
  ##     alone.  Inking them apart draws connection words describe,
  ##     deep running into plain, same way picture beside them does.
  ##   Same reading graph's labels get, so move called one thing in
  ##     drawing is called it in same colours in list.
  ##   Escaped stretch by stretch: markup goes *between* stretches,
  ##     so escaping whole afterwards would escape markup too.
  ##   Only where markup can go.  Matrix cell says its phrase in `title`
  ##     attribute and `say` speaks it aloud, and neither can carry colour --
  ##     which is why `phrase` still hands back plain words and this is
  ##     second reading of them rather than change to what they are.
  for run in named(said):
    if run.lead.isNone and run.follow.isNone:
      result.add esc(run.text)
      continue
    let ink = if run.lead.isSome: armColour(run.lead.get)
              else: followColour(run.follow.get)
    result.add tag("span", "style=\"color: " & ink & "\"", esc(run.text))


func button(action, value, classes, body: string): string =
  ## Form button carrying action page should take when it is clicked.
  tag("button", "class=\"" & classes & "\" data-action=\"" & action &
    "\" data-value=\"" & esc(value) & "\"", body)



#[ Dance View ]#

func renderMoves(source: Frame): string =
  ## List what can be danced from here: every move, then every named compound.
  ##   Compound is offered as one button because lead leads it as one
  ##     thing, and taking it dances both of its moves in turn rather than
  ##     jumping frame in between.
  ##   It is grouped and counted apart from moves so that page never
  ##     says two things are one.
  let available = moves(source)
  var rows = ""
  var previous = ""
  for move in available:
    let helper = $move.helper
    if helper != previous:
      rows.add tag("h4", "", esc(helper.toLowerAscii) & " &mdash; " &
        esc(manner(move.helper)))
      previous = helper
    rows.add button("move", move.to.key, "move",
      tag("span", "class=\"phrase\"", inked(phrase(source, move))) &
      tag("span", "class=\"target\"", inked(move.to.describe)))
  var shortcuts = ""
  for target in FRAMES:
    let helper = compound(source, target)
    if helper.isNone:
      continue
    let steps = route(source, target)
    var spelled = ""
    for step in steps:
      if spelled.len > 0:
        spelled.add " &rarr; "
      spelled.add esc(step.helper.name)
    shortcuts.add button("compound", target.key, "move two",
      tag("span", "class=\"phrase\"", inked(compoundPhrase(source, target))) &
      tag("span", "class=\"target\"", inked(target.describe) & " &middot; " &
        spelled))
  if shortcuts.len > 0:
    shortcuts = tag("h4", "", "two moves, led as one") & shortcuts
  tag("section", "class=\"panel\"",
    tag("h3", "", "available now &middot; " & $available.len & " moves") &
    rows & shortcuts)


func renderElsewhere(source: Frame): string =
  ## List every frame that is not one primitive away, and way to it.
  ##   This half of panel is what makes page validator: frame here
  ##     can be seen but not danced, and route says exactly what is missing.
  ##   Named step by step, in words moves panel uses for same
  ##     move.
  ##     `collect, then collect` is shape of answer rather than
  ##       answer: from `free` it was what all three frames two moves away
  ##       said, so panel gave same seven words for three different
  ##       places, while four collects sat unlabelled above it -- two of which,
  ##       for any one of those places, lead away from it rather than towards
  ##       it.
  ##     Route always knew which two; it was throwing answer away and
  ##       printing only its shape.
  var rows = ""
  var count = 0
  for target in FRAMES:
    if target == source or classify(source, target).isSome or
        compound(source, target).isSome:
      continue
    inc count
    var detail = ""
    # Each step is named against frame it departs from, because that is
    # frame it is move out of.  It happens to read same named from here --
    # drop is only phrase that looks at frame it leaves, and no
    # shortest route drops hand it collected, so hand route drops was held
    # before route began.  `tests/ttransition.nim` holds both of those, so
    # this is written way it is true rather than way it is convenient.
    var standing = source
    for step in route(source, target):
      detail.add tag("span", "class=\"step\"",
        inked(phrase(standing, step)) & tag("i", "", inked(step.to.describe)))
      standing = step.to
    rows.add tag("div", "class=\"far\"",
      tag("span", "class=\"phrase\"", inked(target.describe)) &
      tag("span", "class=\"target\"", $route(source, target).len & " moves") &
      detail)
  tag("section", "class=\"panel muted\"",
    tag("h3", "", "not from here &middot; " & $count) & rows)


func renderHistory(danced: seq[Step]): string =
  ## Show sequence danced so far, with ways back out of it.
  var rows = ""
  for index in countdown(danced.high, 0):
    rows.add tag("li", "", inked(danced[index].phrase) & " &rarr; " &
      inked(danced[index].to.describe))
  tag("section", "class=\"panel\"",
    tag("h3", "", "danced &middot; " & $danced.len) &
    button("undo", "", "flat", "undo") & button("reset", "", "flat", "reset") &
    # Newest first, because that is end you are dancing from -- and numbered
    # from far end, so "1." is first move danced rather than last.
    tag("ol", "class=\"history\" reversed", rows))


func renderDrawingSwitch(drawing: Drawing): string =
  ## Show choice between two drawings.
  var tabs = ""
  for candidate in Drawing:
    let classes = if candidate == drawing: "tab on" else: "tab"
    tabs.add button("drawing", $candidate, classes, esc($candidate))
  tag("div", "class=\"tabs small\"", tabs)


func renderArms(): string =
  ## Say which ink is which arm, and how hand says whose it is.
  ##   Nothing in ontology says *whose* hand it means, because case
  ##     says it: `Left` is lead's and `left` is follow's, in frame's
  ##     name and in move's alike.
  ##   Reader who has not been told that once cannot read anything else on
  ##     page, so drawing tells them here.
  var swatches = ""
  for side in Side:
    # Words go inside one element of their own: swatch is flex row and
    # sets gap between its children, so inking word into span of its own
    # would otherwise push sentence apart at exactly word being read.
    swatches.add tag("span", "class=\"swatch\"",
      "<i class=\"arm-" & (if side == Side.Left: "left" else: "right") & "\"></i>" &
      tag("span", "", "the lead's " & inked(leadName(side)) & " arm"))
  # Said in two inks it is about, so sentence that explains
  # convention is itself instance of it, and taken from model rather
  # than spelled again here.
  swatches.add tag("span", "class=\"swatch aside\"",
    tag("span", "",
      "&ldquo;" & inked(leadName(Side.Left)) & "&rdquo; is the lead's hand, " &
      "&ldquo;" & inked(followName(Site.LeftHand)) & "&rdquo; the follow's"))
  tag("div", "class=\"legend\"", swatches)


func renderKey(): string =
  ## Say what picture of frame is picture of.
  ##   Every view is built on it, and nothing else anywhere says that it is
  ##     couple seen from above, which body is whose, or how to read
  ##     hand.
  ##   Reader who has not been told cannot read frames, names,
  ##     matrix or map -- so it is said once, next to first drawing
  ##     they meet, in fewest words that will do it.
  tag("p", "class=\"key\"",
    "Seen from above: two bodies, the lead at the bottom in squares and the " &
    "follow at the top in circles, each with a small chevron for the way " &
    "they face. A connection runs hand to hand, in its two hands' own " &
    "colours meeting at the middle, and goes round a body rather than " &
    "through one &mdash; so a crossed hold is drawn crossing. A hand nobody " &
    "holds is faded; a line with a gap in it passes under the other.")


func renderSpokesView(current: Frame; motion: Motion;
    taken: Option[Frame]): string =
  ## Draw where couple are and every way out, and nothing else.
  tag("div", "class=\"view-spokes\"",
    tag("div", "class=\"scroll\"", renderSpokes(current, motion, taken)) &
    tag("p", "class=\"note\"", "The frame in the middle is the one being held. " &
      "Every spoke is a way out of it and nothing else is drawn. A collect " &
      "takes a hand so it points up, a drop releases one so it points down, " &
      "and a compound is two moves so it goes out to the side, inked in both " &
      "the arms it hands a hand between. Each name says the hand of the follow " &
      "it takes or lets go of, in that hand's own colour, and the rest of it is " &
      "the lead's arm in the deeper shade. Take a spoke and it becomes the " &
      "middle."))


func renderMapView(current: Frame; motion: Motion; taken: Option[Frame]): string =
  ## Draw where couple stand in whole ontology.
  tag("div", "class=\"view-map\"",
    tag("div", "class=\"scroll\"", renderMap(some(current), motion, taken)) &
    tag("p", "class=\"note\"", "Each row holds one more connection than the row " &
      "below, so a line up the page is a collect and a line down is a drop. " &
      "A line you are standing on is named for the move away from you, which is " &
      "the one you could make; a line you are not is named for the move that " &
      "runs up it. Every name says the hand of the follow it takes or lets go " &
      "of, written in that hand's own colour, and the rest of the name is the " &
      "arm of the lead that does it, in the deeper shade &mdash; so a name " &
      "runs deep into plain exactly as the connection it makes does. Where a name " &
      "lies across its own line the line is cut for it, with a round end " &
      "either side, so the break reads as a name put there rather than as a " &
      "line stopping. A dashed curve is a compound, and is inked in both " &
      "arms because it hands a hand from one of them to the other: the ink at " &
      "each end is the arm that acts on the way to it. The frames you can " &
      "reach from where you stand come forward and the rest go quiet, and the " &
      "ring moves along the line you take. A frame ringed in a solid line is " &
      "one move away and a dashed one is a compound, two moves away; both can " &
      "be clicked, and a compound dances its two moves in turn."))


func renderStageBody(current: Frame; drawing: Drawing; motion: Motion;
    taken: Option[Frame]): string =
  ## Show frame couple hold, drawn way dancer has asked for.
  ##   Name shown is frame being *left* until move lands, because
  ##     drawing is still showing that frame: heading that changed before
  ##     picture did would name something nobody can see.
  let shown =
    case drawing
    of Drawing.Dynamic: renderSpokesView(current, motion, taken)
    of Drawing.Overview: renderMapView(current, motion, taken)
  tag("div", "class=\"stage-head\"",
    tag("h3", "", "frame") & tag("h2", "", inked(current.describe)) &
    renderDrawingSwitch(drawing) & renderArms()) &
    renderKey() & tag("div", "class=\"views\"", shown)


func renderDance(current: Frame; drawing: Drawing; motion: Motion;
    taken: Option[Frame]; danced: seq[Step]): string =
  ## Show current frame, what it allows, and what it does not.
  tag("div", "class=\"stage\"",
    tag("section", "class=\"panel wide\" id=\"stage\" tabindex=\"-1\"",
      renderStageBody(current, drawing, motion, taken)) &
    renderMoves(current) & renderElsewhere(current) & renderHistory(danced))



#[ Atlas View ]#

func admits(narrowing: Filter; target: Frame): bool =
  ## Test whether frame answers everything dancer has asked to see.
  ##
  ## Every question left unasked admits everything, and asked ones are read
  ## together: dancer looking for two-handed frame that uses lead's left
  ## wants both to be true of same frame.
  if narrowing.holds.isSome and target.countHolds != narrowing.holds.get:
    return false
  if narrowing.lead.isSome and not target.usesHand(narrowing.lead.get):
    return false
  if narrowing.follow.isSome and not target.isHeld(narrowing.follow.get):
    return false
  true


func chip(action, value, label: string; chosen: bool): string =
  ## Offer one answer to one question, marked when it is one in force.
  button(action, value, (if chosen: "chip on" else: "chip"), esc(label))


func renderFilters(narrowing: Filter): string =
  ## Ask three questions that narrow gallery: how many, whose, which.
  var holds = chip("holds", "any", "any", chosen = narrowing.holds.isNone)
  for count in 0 .. 2:
    holds.add chip("holds", $count, $count & (if count == 1: " hand" else: " hands"),
      narrowing.holds == some(count))
  var lead = chip("lead", "any", "either", chosen = narrowing.lead.isNone)
  for side in Side:
    lead.add chip("lead", $side, leadName(side), chosen = narrowing.lead == some(side))
  var follow = chip("follow", "any", "either", chosen = narrowing.follow.isNone)
  for site in Site:
    follow.add chip("follow", $site, followName(site), chosen = narrowing.follow == some(site))
  tag("div", "class=\"filters\"",
    tag("div", "class=\"question\"", tag("span", "class=\"asks\"", "connections") & holds) &
    tag("div", "class=\"question\"",
      tag("span", "class=\"asks\"", "lead's hand holds") & lead) &
    tag("div", "class=\"question\"",
      tag("span", "class=\"asks\"", "follow's hand held") & follow))


func renderGallery(narrowing: Filter): string =
  ## Show every frame as its own picture, and let one of them be started from.
  ##   Name is claim about frame; picture is frame.
  ##   Showing both means vocabulary can be read off drawing rather
  ##     than trusted, which is same reason review page carries
  ##     pictures too.
  var cards = ""
  var shown = 0
  for target in FRAMES:
    if not narrowing.admits(target):
      continue
    inc shown
    let ways = moves(target).len
    cards.add button("start", target.key, "card",
      renderFrame(target) &
      tag("span", "class=\"phrase\"", inked(target.describe)) &
      tag("span", "class=\"target\"", $ways & " moves &middot; " &
        $target.countHolds & (if target.countHolds == 1: " hand" else: " hands")))
  tag("div", "class=\"stage\"", tag("section", "class=\"panel wide\"",
    tag("h3", "", "every frame &middot; " & $shown & " of " & $FRAMES.len) &
    renderArms() & renderKey() &
    renderFilters(narrowing) &
    tag("p", "class=\"note\"", "Click a frame to begin the dance from it.") &
    (if shown == 0:
      tag("p", "class=\"note\"", "No frame holds all three of those at once.")
    else:
      tag("div", "class=\"gallery\"", cards))))



#[ Matrix View ]#

const
  HELPER_GLYPHS: array[Helper, string] = [
    Helper.Collect: "&uarr;",
    Helper.Drop: "&darr;",
  ] ## Point primitive way every other drawing points it.
    ##   Collect adds connection and drop takes one away, and both
    ##     map and close drawing say that by direction: up page for
    ##     collect, since collect builds frame up, and down for drop.
    ##   Cell that said `c` and `d` made reader learn same fact
    ##     second way.
  COMPOUND_GLYPHS: array[Compound, string] = [
    Compound.Place: "&#8644;",
    Compound.Cut: "&times;",
  ] ## Draw compound as what it does: place hands hand across, cut
    ## crosses one arm over other.


func toneOf(side: Side): string =
  ## Name custom property holding ink of one of lead's arms.
  ##   Deep shade, because cell is lead acting -- same reading
  ##     that inks line on map and acting word of every name.
  ##     Plain shade is follow's, and cell is never theirs.
  ##   Key directly above this table draws two arms deep, so plain
  ##     cell disagreed with legend it was being read under.
  if side == Side.Left: "var(--left-deep)" else: "var(--right-deep)"


func cell(classes, tone, told, body: string): string =
  ## Form one cell of matrix, inked and named for what it says.
  ##   Ink is carried as property rather than class because thing
  ##     cell varies by is which arm dances it, and that is one value, not
  ##     set of states stylesheet has to enumerate.
  tag("td", "class=\"" & classes & "\" style=\"--tone: " & tone & "\"" &
    (if told.len > 0: " title=\"" & esc(told) & "\"" else: ""), body)


func renderMark(kind, tone, glyph: string): string =
  ## Draw mark cell carries, in ink of arm that dances it.
  tag("span", "class=\"tile " & kind & "\" style=\"--tone: " & tone & "\"", glyph)


func renderMarks(): string =
  ## Show what each mark in matrix means, drawn as matrix draws it.
  ##   Old legend spelled four letters out in sentence, which asked
  ##     reader to hold code in their head while they read grid.
  ##   Drawn, legend and cell are same thing seen twice.
  var items = ""
  for helper in Helper:
    items.add tag("span", "class=\"swatch\"",
      renderMark("one", "var(--dim)", HELPER_GLYPHS[helper]) & helper.name)
  for named in Compound:
    items.add tag("span", "class=\"swatch\"",
      renderMark("two", "var(--dim)", COMPOUND_GLYPHS[named]) &
      ($named).toLowerAscii & ", two moves")
  tag("div", "class=\"legend\"", items)


func renderCrosshair(across: int): string =
  ## Write rules that light column under pointer.
  ##   Row lights itself, because row is one element; column is not, so
  ##     it takes one rule per column and count of them is fact about
  ##     model.
  ##   Written here it cannot fall out of step with how many frames there are,
  ##     and gridless table needs it: without lines to follow, whole
  ##     difficulty of eight-by-eight is knowing which column you are in.
  result = "<style>"
  for column in 2 .. across + 1:
    result.add ".matrix:has(td:nth-child(" & $column & "):hover) " &
      ":is(th, td):nth-child(" & $column & ") { background: var(--cross); }"
  result.add "</style>"


func renderMatrix(): string =
  ## Show every move there is, as one chart.
  ##   Its own view, because it answers different question from gallery.
  ##     Gallery is what frames *are*, one picture each, and is where
  ##       reader starts; matrix is what joins them, all sixty-four pairs
  ##       at once, and is what you consult once you know what frame is.
  ##     Under one heading table was wall below pictures that nobody
  ##       scrolled to.
  ##   Drawn rather than tabulated, for reason gallery is: frame's
  ##     name is claim about it and its picture is frame, so axes
  ##     carry pictures and reader can check vocabulary instead of
  ##     trusting it.
  ##     Cell carries move's direction as mark and lead's arm as
  ##       its ink, which is vocabulary map already uses, so same
  ##       three facts are said same way wherever page says them.
  ##   Every pair is answered.
  ##     Pair no primitive joins used to be blank, which is half of chart
  ##       saying nothing; it now carries how many moves apart two frames
  ##       are, which is question blank cell provokes.
  ##   Both axes run down tower, taking their order from drawing that
  ##     owns it, so that reading matrix top to bottom and reading map
  ##     top to bottom are same reading.
  ##     Down tower every collect runs from row to column *earlier*
  ##       than it and every drop other way, so two primitives fall
  ##       either side of diagonal and compounds -- which change what
  ##       is held without changing how much -- fall in blocks on it.
  ##     Structure is then in picture rather than in paragraph
  ##       under it.
  ##   What source spreadsheet has and has not got is not marked here.
  ##     Which cells its author has filled in is fact about document being
  ##       written, not about two bodies, and app is ontology:
  ##       `doc/review.html` says it, at length and in order, which is how it
  ##       wants to be read.
  let order = towerOrder()
  # Band opens wherever tower steps down row, and gap that marks it
  # has to fall in same place down rows as it does across columns.
  var opens: seq[bool] = @[]
  for index, target in order:
    opens.add index > 0 and order[index - 1].countHolds != target.countHolds
  var head = tag("th", "class=\"corner\"",
    tag("span", "class=\"axis\"", "to &rarr;") &
    tag("span", "class=\"axis\"", "from &darr;"))
  for index, target in order:
    head.add tag("th", "class=\"head" & (if opens[index]: " gap" else: "") &
      "\" title=\"" & esc(target.describe) & "\"",
      renderFrame(target) & tag("span", "class=\"who\"", inked(target.brief)))
  var body = ""
  for down, source in order:
    let step = if opens[down]: " top" else: ""
    # Same picture down side as across top, so reader following
    # row never has to count columns back to find out what they are reading.
    # It fits beside name now that name is short, and it is legible at
    # that size now that lead's hands are squares: whose row is whose is in
    # marks, where before it was only in captions too small to read.
    var row = tag("th", "class=\"row" & step & "\" title=\"" &
      esc(source.describe) & "\"",
      tag("span", "class=\"who\"", inked(source.brief)) & renderFrame(source))
    for across, target in order:
      let
        edge = (if opens[across]: " gap" else: "") & step
        helper = classify(source, target)
        named = compound(source, target)
      if source == target:
        row.add cell("self" & edge, "var(--rule-strong)", source.describe,
          tag("span", "class=\"tile here\"", ""))
      elif helper.isSome:
        let move = Move(helper: helper.get, to: target,
          side: actingSide(source, target))
        row.add cell("one" & edge, toneOf(move.side), phrase(source, move),
          tag("span", "class=\"tile one\"", HELPER_GLYPHS[move.helper]))
      elif named.isSome:
        row.add cell("two" & edge, toneOf(compoundSide(source, target).get),
          compoundPhrase(source, target),
          tag("span", "class=\"tile two\"", COMPOUND_GLYPHS[named.get]))
      else:
        let far = route(source, target).len
        row.add cell("away" & edge, "var(--faint)",
          (if far > 0: $far & " moves apart" else: ""),
          (if far > 0: $far else: ""))
    body.add tag("tr", "", row)
  tag("div", "class=\"stage\"",
    tag("section", "class=\"panel wide\"",
      tag("h3", "", "derived transition matrix") &
      renderMarks() & renderArms() & renderKey() &
      tag("div", "class=\"scroll\"", renderCrosshair(order.len) &
        tag("table", "class=\"matrix\"",
          tag("thead", "", tag("tr", "", head)) & tag("tbody", "", body))) &
      tag("p", "class=\"note\"", "A cell is the move from its row to its " &
        "column, inked in the arm of the lead that dances it. The frames are " &
        "ordered down the tower, the same way the map stacks them, so every " &
        "collect falls below the diagonal and every drop above it, and the " &
        "compounds &mdash; " &
        "which change what is held without changing how much &mdash; fall in " &
        "the blocks along it. A faded number is a pair no single move joins, " &
        "and is how far apart they are.")))



#[ Page ]#

func renderControls(view: View): string =
  ## Show view switches.
  var views = ""
  for candidate in View:
    let classes = if candidate == view: "tab on" else: "tab"
    views.add button("view", $candidate, classes, esc($candidate))
  tag("header", "", tag("h1", "", "dance ontology") & tag("div", "class=\"tabs\"", views))


proc paintStage() =
  ## Draw frame and its ways out again, and nothing else on page.
  ##   Move changes only drawing.
  ##   Leaving lists alone keeps button under pointer from being
  ##     rebuilt out from under it, and keeps page from being laid out
  ##     again in middle of animation.
  let stage = document.getElementById("stage")
  if stage == nil:
    return
  let held = holding()
  stage.innerHTML = cstring(renderStageBody(current, drawing, motion, taken))
  standAgain(held)
  centreOnHeld()


proc render() =
  ## Draw whole page from session state.
  let body =
    case view
    of View.Dance: renderDance(current, drawing, motion, taken, history)
    of View.Atlas: renderGallery(filter)
    of View.Matrix: renderMatrix()
  let held = holding()
  document.getElementById("app").innerHTML = cstring(renderControls(view) & body)
  standAgain(held)
  centreOnHeld()


proc arrive(target: Frame) =
  ## Stand in frame move reached, and remember way there.
  for move in moves(current):
    if move.to != target:
      continue
    history.add Step(phrase: phrase(current, move), to: move.to)
    current = move.to
    say(history[^1].phrase & ". Now " & current.describe & ", with " &
      $moves(current).len & " moves out of it.")
    return


proc dance(key: string)


proc leadOn() =
  ## Take second move of compound, if one is waiting on first.
  let next = queued
  queued = none(Frame)
  if next.isSome:
    dance(next.get.key)


proc dance(key: string) =
  ## Take one offered move, refusing anything that is not offered.
  ##   Guard is point of page: frame reached any other way would
  ##     be claim ontology does not make.
  ##   What follows guard is only telling of it: ways not taken
  ##     fold away, frame taken travels into middle, and ways out
  ##     of *it* grow.
  ##     Each phase is scheduled against times drawing itself declares,
  ##       so page never advances state out from under animation
  ##       that is still running.
  ##   Dancer who changes their mind while ways not taken are still
  ##     folding is taken at their word: state has not moved yet, so
  ##     fold begins again aimed at new frame.
  ##     Bumping generation is what drops first move's remaining
  ##       phases, and is same guard that stops compound finishing itself
  ##       after something else has been asked for.
  let target = fromKey(key)
  if target.isNone or classify(current, target.get).isNone:
    return
  if motion == Motion.Leaving and taken == target:
    return # Asked twice for same move, which is once.
  if atOnce():
    # Every phase collapses into change of state it was spelling out.  But
    # compound is two changes of state, and phase that would have taken its
    # second half has collapsed along with rest, so it is taken here instead
    # -- or page offers move and then does not make it, which is one
    # thing validator must never do.
    arrive(target.get)
    leadOn()
    render()
    return

  inc generation
  let
    mine = generation
    tempo = tempoOf(drawing)
  motion = Motion.Leaving
  taken = target
  paintStage()

  discard setTimeout(proc () =
    if generation != mine:
      return
    arrive(target.get)
    motion = Motion.Arriving
    taken = none(Frame)
    render(), tempo.leaveTime)

  discard setTimeout(proc () =
    if generation != mine:
      return
    leadOn(), tempo.leadOnTime)

  discard setTimeout(proc () =
    if generation != mine:
      return
    motion = Motion.Still, tempo.moveTime)


proc danceCompound(key: string) =
  ## Take named compound, move by move, so way through is danced.
  ##   Lead thinks of it as one thing and ontology knows it is two, so
  ##     page dances both: second is queued behind first rather
  ##     than timed against it, and it starts as frame between them lands.
  ##   Anything else dancer does in meantime is newer move, and drops
  ##     queue.
  let target = fromKey(key)
  if target.isNone or compound(current, target.get).isNone:
    return
  # Way vocabulary means, not any shortest way: cut can be led with
  # either arm and only one of those is one phrase on this very button
  # describes.  Dancing other would be doing one thing while saying another.
  let steps = compoundWay(current, target.get)
  if steps.len != 2:
    return
  queued = some(target.get)
  dance(steps[0].to.key)


proc rest() =
  ## Stop whatever was moving, for change of state that is not move.
  inc generation
  motion = Motion.Still
  taken = none(Frame)
  queued = none(Frame)


proc start(key: string) =
  ## Begin again from chosen frame.
  let target = fromKey(key)
  if target.isNone:
    return
  rest()
  origin = target.get
  current = origin
  history = @[]
  view = View.Dance


proc handle(event: Event) =
  ## Route one click to session change it asks for.
  let stepped = event.target.closest("g.node.reachable")
  if stepped != nil:
    dance($stepped.getAttribute("data-frame"))
    return
  let led = event.target.closest("g.node.two")
  if led != nil:
    danceCompound($led.getAttribute("data-frame"))
    return
  let node = event.target.closest("button")
  if node == nil:
    return
  let action = $node.getAttribute("data-action")
  let value = $node.getAttribute("data-value")
  case action
  of "move":
    dance(value)
    return
  of "compound":
    danceCompound(value)
    return
  of "start": start(value)
  of "view":
    for candidate in View:
      if $candidate == value:
        view = candidate
  of "drawing":
    for candidate in Drawing:
      if $candidate == value:
        drawing = candidate
        drawing_chosen = true
  of "holds":
    filter.holds = none(int)
    for count in 0 .. 2:
      if $count == value:
        filter.holds = some(count)
  of "lead":
    filter.lead = none(Side)
    for candidate in Side:
      if $candidate == value:
        filter.lead = some(candidate)
  of "follow":
    filter.follow = none(Site)
    for candidate in Site:
      if $candidate == value:
        filter.follow = some(candidate)
  of "undo":
    if history.len > 0:
      rest()
      discard history.pop()
      current = if history.len > 0: history[^1].to else: origin
  of "reset":
    rest()
    current = origin
    history = @[]
  else: return
  render()


proc reflow(event: Event) =
  ## Follow screen when it changes size, while reader has not chosen.
  ##   Only when drawing would actually change.
  ##     Event arrives on every pixel of drag, and rebuilding page on
  ##       each one would take focus ring off whatever reader was
  ##       standing on and tear any move that was halfway through being told.
  let showing = drawing
  suitDrawing()
  if drawing != showing:
    rest()
    render()


when isMainModule:
  document.addEventListener("click", handle)
  window.addEventListener("resize", reflow)
  suitDrawing()
  render()
