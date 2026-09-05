discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Test picture of whole ontology against ontology.
##
## Map is drawing, so most of it is matter of taste; what is tested is
## that it is drawing of *this* model, with every frame in it once, every move
## on it once, and nothing on it that model does not derive.

{.experimental: "strictFuncs".}

import std/[options, strutils, unittest]

import ../src/dance_ontology


func spoken(picture: string): string =
  ## Take ink back out of drawing, leaving only words it says.
  ##   Name is drawn in hands it names, so `drop left` is three elements
  ##     and not one, and test that asks what label *says* would otherwise
  ##     be asking how it is coloured as well.
  ##   How it is coloured is its own test, below.
  result = picture
  while true:
    let at = result.find("<tspan")
    if at < 0:
      break
    result = result[0 ..< at] & result[result.find('>', at) + 1 .. ^1]
  result = result.replace("</tspan>", "")


func attr(chunk, name: string): int =
  ## Read one number out of drawn element, for measuring what was drawn.
  let key = name & "=\""
  let at = chunk.find(key)
  if at < 0:
    return 0
  let rest = chunk[at + key.len .. ^1]
  parseInt(rest[0 ..< rest.find('"')])


suite "the layout":
  test "the drawing order names every frame exactly once":
    check NODE_ORDER.len == FRAMES.len
    var seen: seq[Frame] = @[]
    for key in NODE_ORDER:
      let target = fromKey(key)
      check target.isSome
      check target.get notin seen
      seen.add target.get
    for target in FRAMES:
      check target in seen

  test "no two frames are drawn in the same place":
    var places: seq[(int, int)] = @[]
    for target in FRAMES:
      let centre = centreOf(target)
      check centre notin places
      check centre[0] > 0 and centre[0] < MAP_WIDTH
      check centre[1] > 0 and centre[1] < MAP_HEIGHT
      places.add centre

  test "frames with the same number of connections share a row":
    for a in FRAMES:
      for b in FRAMES:
        check (centreOf(a)[1] == centreOf(b)[1]) == (a.countHolds == b.countHolds)

  test "a move always runs up the page, from fewer connections to more":
    # Which is whole of what rows buy: reader who knows which way is
    # up knows which primitive line is without reading its name.
    for source in FRAMES:
      for move in moves(source):
        let rising = move.helper == Helper.Collect
        check (centreOf(move.to)[1] < centreOf(source)[1]) == rising

  test "free is at the foot of the tower and the fullest frames at its head":
    for target in FRAMES:
      for other in FRAMES:
        if target.countHolds < other.countHolds:
          check centreOf(target)[1] > centreOf(other)[1]

  test "the order the tower stacks the frames is the order it draws them in":
    # Anything that puts frames in line -- matrix orders both its axes
    # this way -- takes order from here, so it cannot drift from drawing
    # and leave two saying opposite things about which way ladder runs.
    let order = towerOrder()
    check order.len == FRAMES.len
    for target in FRAMES:
      check target in order
    for index in 1 ..< order.len:
      check centreOf(order[index - 1])[1] <= centreOf(order[index])[1]


suite "the drawing":
  test "every move is one line and every compound is one curve":
    let picture = renderMap(none(Frame))
    var moved, joined = 0
    for source in FRAMES:
      moved += moves(source).len
      for target in FRAMES:
        if compound(source, target).isSome:
          inc joined
    # Each line stands for pair of moves that cross it.  Curve stands for
    # pair too, but is drawn in halves, because two moves it stands for
    # are led by different arms and each half is inked for its own.
    check picture.count("<line class=\"edge") == moved div 2
    check picture.count("<path class=\"arc") == joined
    # One group of ink and one of words for each, wearing same marks, so
    # that dimming and lighting still take them as one thing.
    check picture.count("<g class=\"join\"") + picture.count("<g class=\"join ") -
      picture.count("<g class=\"join naming") == joined div 2
    check picture.count("<g class=\"join naming") == joined div 2
    check picture.count("<g class=\"way naming") == moved div 2

  test "every line is drawn before any name is written":
    # Name carries plate to keep drawing out from under it, and plate
    # can only hide what is already there.  Written as each line was drawn,
    # name was struck through by next line to cross it, which is wrong
    # drawing rather than ugly one: reader is told wrong move.
    for standing in FRAMES:
      let picture = renderMap(some(standing))
      var last_ink = 0
      for mark in ["<line class=\"edge", "<path class=\"arc"]:
        last_ink = max(last_ink, picture.rfind(mark))
      var first_name = picture.len
      for mark in ["<g class=\"way naming", "<g class=\"join naming"]:
        first_name = min(first_name, picture.find(mark))
      check last_ink < first_name

  test "every frame is drawn, with its name":
    # Read past ink: frame is named in hands it names, so its name is
    # several elements and not one.  Asked of drawn name and not of
    # whole picture -- every node carries SVG `<title>` saying same
    # words, which would answer this whether name were drawn or not.
    let picture = renderMap(none(Frame)).spoken
    var names: seq[string] = @[]
    for chunk in picture.split("class=\"node-name\"")[1 .. ^1]:
      let said = chunk[0 ..< chunk.find("</text>")]
      names.add said[said.find('>') + 1 .. ^1]
    check names.len == FRAMES.len
    for target in FRAMES:
      check picture.contains("data-frame=\"" & target.key & "\"")
      check target.describe in names

  test "a map with nobody on it has no marker and lights nothing":
    let picture = renderMap(none(Frame))
    check not picture.contains("class=\"mark\"")
    check not picture.contains(" lit")
    check not picture.contains("reachable")

  test "one frame is marked, and the mark is the same ring the close drawing uses":
    for here in FRAMES:
      let picture = renderMap(some(here))
      check picture.count("class=\"mark\"") == 1
      # Both drawings ring frame held from same numbers, so that two
      # say *here* same way and neither says it twice.
      check picture.contains(markAt(centreOf(here)[0], centreOf(here)[1],
        NODE_WIDTH, " style=\"--mx: 0px; --my: 0px\""))
      check renderSpokes(here).count("class=\"mark\"") == 1

  test "the marker stands on the frame held and carries the way to the next":
    for here in FRAMES:
      # Standing still it goes nowhere; taking move, it carries exactly
      # distance along line to frame chosen, which is move itself.
      check renderMap(some(here)).contains("--mx: 0px; --my: 0px")
      for move in moves(here):
        let picture = renderMap(some(here), Motion.Leaving, some(move.to))
        check picture.contains("--mx: " & $(centreOf(move.to)[0] -
          centreOf(here)[0]) & "px; --my: " & $(centreOf(move.to)[1] -
          centreOf(here)[1]) & "px")

  test "only the frames one move away are offered":
    for here in FRAMES:
      let picture = renderMap(some(here))
      check picture.count("reachable") == moves(here).len

  test "a frame a compound away is offered, and marked as two moves":
    for here in FRAMES:
      var named = 0
      for target in FRAMES:
        if compound(here, target).isSome:
          inc named
      check renderMap(some(here)).count(" two\"") == named

  test "every line is named, and no name is drawn over anything else":
    # Naming only lines underfoot let rest of map go unread, and
    # meant names moved about every time couple did.  Naming all of them
    # is only useful if they can all be read at once, so drawing places each
    # one itself and this holds it to having found room.
    var moved, joined = 0
    for source in FRAMES:
      moved += moves(source).len
      for target in FRAMES:
        if compound(source, target).isSome:
          inc joined
    # In every state, not just unread map: name is read from where
    # couple stand, so words change as they dance and room they need
    # changes with them.
    var wheres = @[none(Frame)]
    for here in FRAMES:
      wheres.add some(here)
    for where in wheres:
      let picture = renderMap(where)
      var boxes: seq[Box] = @[]
      for chunk in picture.split("<rect class=\""):
        if not (chunk.startsWith("edge-plate") or chunk.startsWith("arc-plate")):
          continue
        let own = chunk[0 ..< chunk.find("/>")]
        boxes.add (own.attr("x"), own.attr("y"), own.attr("width"),
          own.attr("height"))
      check boxes.len == moved div 2 + joined div 2
      for index, box in boxes:
        for other in boxes[index + 1 .. ^1]:
          check not overlaps(box, other)
        for frame in frameBoxes():
          check not overlaps(box, frame)

  test "a line is named for the move away from where the couple stand":
    # Line is two moves, one each way.  Named for collect either way,
    # line leaving frame held upwards would be labelled with move that
    # comes back down it -- one thing reader cannot do from there.
    for here in FRAMES:
      let picture = renderMap(some(here))
      for move in moves(here):
        let naming = label(here, Move(helper: move.helper, side: move.side,
          to: move.to))
        for line in naming:
          check picture.spoken.contains(">" & line & "<")
      # And drop names hand it lets go of, as collect names hand it
      # takes.  It used to read bare `drop`, which left reader to work out
      # what was being released from ink word was written in.
      var drops = 0
      for move in moves(here):
        if move.helper != Helper.Drop:
          continue
        inc drops
        check picture.spoken.contains(
          ">drop " & followName(here.hold[move.side].get) & "<")
      check not picture.contains(">drop<")
      if here.countHolds > 0:
        check drops > 0

  test "a compound underfoot names the hand it moves, and one nobody stands on may not":
    # Stood on one end curve has direction like any other line.  Stood on
    # neither, cut carries whichever hand ends up on top -- other one going
    # other way -- so naming one of them would be wrong on half of readings.
    let idle = renderMap(none(Frame))
    check idle.contains(">cut<")
    for here in FRAMES:
      for target in FRAMES:
        if compound(here, target).isNone:
          continue
        let picture = renderMap(some(here))
        check picture.spoken.contains(">" & compoundName(here, target) & "<")

  test "a compound is inked in both the arms it hands a hand between":
    # Ordinary line has one ink because same arm acts whichever way it is
    # read.  Compound has two, and which one you see depends on which end you
    # are reading from, because that is what compound is.
    let picture = renderMap(none(Frame))
    for a in FRAMES:
      for b in FRAMES:
        if compound(a, b).isNone or frameIndex(a).get > frameIndex(b).get:
          continue
        let
          near = compoundSide(b, a)
          far = compoundSide(a, b)
        check near.isSome and far.isSome
        check near.get != far.get
        # Both inks are on drawing, and neither is quiet ink that would
        # say line belongs to no arm at all.
        for side in [near.get, far.get]:
          let ink = (if side == Side.Left: "var(--left" else: "var(--right")
          check picture.contains("class=\"arc\" d=\"M") and picture.contains(ink)

  test "every frame's name has a plate to keep the lines off it":
    # Lines leave frame from its middle, so they run out through words
    # above it.  Every other name in drawing has plate; so does this one.
    let picture = renderMap(none(Frame))
    check picture.count("class=\"name-plate\"") == FRAMES.len
    check renderSpokes(FRAMES[0]).count("class=\"name-plate\"") ==
      spokesOf(FRAMES[0]).len + 1
    for here in FRAMES:
      let (x, y, w, h) = nameBox(here, centreOf(here)[0], centreOf(here)[1], 74)
      check picture.contains("class=\"name-plate\" x=\"" & $x & "\" y=\"" & $y &
        "\" width=\"" & $w & "\" height=\"" & $h & "\"")

  test "the ink of a line is the acting arm, in the lead's own shade":
    # Once line is unlit two arms are told apart by colour alone, so every
    # line has to carry arm's ink and not quiet ink of background.
    # And *deep* shade of it: line is lead acting, and deep is theirs
    # wherever two dancers are told apart.
    #   Checked for deep shade by name rather than by hue alone, which
    #   is how plain one went unnoticed here for as long as it did:
    #   `var(--left` matches `var(--left-deep` just as happily.
    let picture = renderMap(none(Frame))
    var lines = 0
    for fragment in picture.split("<line class=\"edge"):
      if not fragment.startsWith("\"") and not fragment.startsWith(" lit"):
        continue
      inc lines
      let element = fragment[0 ..< fragment.find("/>")]
      check element.contains("var(--left-deep") or
        element.contains("var(--right-deep")
      check not element.contains("var(--left,")
      check not element.contains("var(--right,")
    var moved = 0
    for source in FRAMES:
      moved += moves(source).len
    check lines == moved div 2

  test "a name says the follow's hand in the follow's own ink":
    # Label is lead acting, so whole of it used to be lead's deep
    # shade -- including word for hand being taken, which is
    # *follow's*.  Picture beside it draws that connection deep running into
    # plain, and words now say it same way.
    #   Word alone is wrapped, and space before it left outside, so
    #   line still reads as one sentence rather than as row of chips.
    var named_hands = 0
    for here in FRAMES:
      let picture = renderMap(some(here))
      for move in moves(here):
        let hand = case move.helper
                   of Helper.Collect: move.to.hold[move.side]
                   of Helper.Drop: here.hold[move.side]
        if hand.isNone:
          continue
        inc named_hands
        check picture.contains("<tspan style=\"fill: " &
          followColour(hand.get) & "\">" & followName(hand.get) & "</tspan>")
        # Follow's plain shade, never lead's deep one.
        check not picture.contains("<tspan style=\"fill: " &
          armColour(move.side) & "\">" & followName(hand.get) & "</tspan>")
    check named_hands > 0

  test "a frame's name is drawn in the hands the frame joins":
    # Same law one step further out.  `Left to left` names two hands as
    # surely as `collect left` does, so two are inked one way and
    # reader who has learnt shades from line can read frame with them.
    #   Which is why wrapping lives in `text`, one helper every word on
    #   drawing goes through, rather than at each name in turn.
    let picture = renderMap(none(Frame))
    var named_frames = 0
    for target in FRAMES:
      if target.countHolds == 0:
        # `free` joins nothing and names nothing, so it stays one plain word.
        check picture.contains(">" & target.describe & "<")
        continue
      inc named_frames
      for side in Side:
        if target.hold[side].isNone:
          continue
        check picture.contains("<tspan style=\"fill: " & armColour(side) &
          "\">" & leadName(side) & "</tspan>")
        check picture.contains("<tspan style=\"fill: " &
          followColour(target.hold[side].get) & "\">" &
          followName(target.hold[side].get) & "</tspan>")
    check named_frames == FRAMES.len - 1
