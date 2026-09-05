discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Test laws of transition relation over every pair of frames.
##
## State space is small enough to check exhaustively, so nothing here is
## sample: each law is asserted for all 64 ordered pairs.

{.experimental: "strictFuncs".}

import std/[options, strutils, unittest]

import ../src/dance_ontology/frame
import ../src/dance_ontology/transition


suite "the relation":
  test "no frame reaches itself":
    for target in FRAMES:
      check classify(target, target).isNone

  test "every primitive reverses, so the relation is symmetric":
    for source in FRAMES:
      for destination in FRAMES:
        let forward = classify(source, destination)
        let backward = classify(destination, source)
        check forward.isSome == backward.isSome  # law `transition.nim`'s header states
        if forward.isSome:
          check backward.get == forward.get.inverse

  test "reflection is a symmetry of the relation":
    for source in FRAMES:
      for destination in FRAMES:
        check classify(source, destination) ==
          classify(source.reflect, destination.reflect)

  test "the relation is not empty and not everything":
    var edges = 0
    for source in FRAMES:
      for destination in FRAMES:
        if classify(source, destination).isSome:
          inc edges
    check edges == 20
    check edges < FRAMES.len * (FRAMES.len - 1)


suite "the primitives":
  test "collect and drop change the number of connections by one":
    for source in FRAMES:
      for destination in FRAMES:
        let helper = classify(source, destination)
        if helper.isNone:
          continue
        let change = destination.countHolds - source.countHolds
        case helper.get
        of Helper.Collect: check change == 1
        of Helper.Drop: check change == -1

  test "one hand cannot travel from one hand of the follow to the other":
    # That move is trace, and there is nothing between follow's hands to
    # trace along. It becomes move when arms and body are places to hold.
    for side in Side:
      var source = Frame()
      var destination = Frame()
      source.hold[side] = some(Site.LeftHand)
      destination.hold[side] = some(Site.RightHand)
      check classify(source, destination).isNone
      check route(source, destination).len == 2

  test "one hand cannot take what the other already holds":
    # Only remaining way for both hands to change at once is hand-off, and
    # hand-off is two moves: `place` keeps contact by overlapping on way
    # past, which needs frame this model does not carry, and `cut` lets go.
    for source in FRAMES:
      for destination in FRAMES:
        if source.countHolds != 1 or destination.countHolds != 1:
          continue
        if source.hold == destination.hold:
          continue
        check classify(source, destination).isNone


suite "the compounds":
  test "a compound is exactly two primitives, and no primitive is one":
    for source in FRAMES:
      for destination in FRAMES:
        let named = compound(source, destination)
        if named.isNone:
          continue
        check classify(source, destination).isNone
        check route(source, destination).len == 2
        check compoundPhrase(source, destination).len > 0

  test "every compound reverses, and undoes itself":
    for source in FRAMES:
      for destination in FRAMES:
        check compound(source, destination) == compound(destination, source)

  test "a cut exchanges the arm order and nothing else":
    for source in FRAMES:
      for destination in FRAMES:
        if compound(source, destination) != some(Compound.Cut):
          continue
        check source.hold == destination.hold
        check source.hasOverlap and destination.hasOverlap
        check source.over != destination.over

  test "a place keeps the hand held and changes the hand holding it":
    for source in FRAMES:
      for destination in FRAMES:
        if compound(source, destination) != some(Compound.Place):
          continue
        check source.countHolds == 1 and destination.countHolds == 1
        for side in Side:
          check source.hold[side] == destination.hold[other(side)]

  test "the two crossing orders are two moves apart, and only by a cut":
    let over_left = fromKey("lrL").get
    let over_right = fromKey("lrR").get
    check compound(over_left, over_right) == some(Compound.Cut)
    check route(over_left, over_right).len == 2
    # Frame in between is whichever hand stays held while other re-takes.
    let between = route(over_left, over_right)[0].to
    check between.countHolds == 1

  test "a hand-off passes through the free frame":
    # Which is why missing `free` row costs workbook four cells.
    for source in FRAMES:
      for destination in FRAMES:
        if compound(source, destination) != some(Compound.Place):
          continue
        check route(source, destination)[0].to == fromKey("--.").get


suite "moves":
  test "the offered moves are exactly the frames one primitive away":
    for source in FRAMES:
      var offered: seq[Frame] = @[]
      for move in moves(source):
        check classify(source, move.to) == some(move.helper)
        check move.to notin offered
        check phrase(source, move).len > 0
        offered.add move.to
      for destination in FRAMES:
        if classify(source, destination).isSome:
          check destination in offered

  test "the free frame is where every dance starts and ends":
    let free = fromKey("--.").get
    check free.countHolds == 0
    check moves(free).len == 4
    for move in moves(free):
      check move.helper == Helper.Collect


suite "the way a compound is led":
  test "it is two primitives, and they land where the compound says":
    for source in FRAMES:
      for destination in FRAMES:
        let way = compoundWay(source, destination)
        if compound(source, destination).isNone:
          check way.len == 0
          continue
        check way.len == 2
        check classify(source, way[0].to) == some(way[0].helper)
        check classify(way[0].to, destination) == some(way[1].helper)
        check way[1].to == destination
        check way[0].helper == Helper.Drop
        check way[1].helper == Helper.Collect

  test "the arm it is danced with is the arm the phrase names":
    # Cut can be led with either arm and graph offers both, so page that
    # danced whichever search happened to find first would be doing one
    # thing while its own words said another.  This is what stops that.
    for source in FRAMES:
      for destination in FRAMES:
        let way = compoundWay(source, destination)
        if way.len == 0:
          continue
        let
          side = compoundSide(source, destination).get
          said = compoundPhrase(source, destination)
        check way[1].side == side
        case compound(source, destination).get
        of Compound.Cut:
          # One arm lets go and comes back over other, so it does both.
          check way[0].side == side
          check said.contains("drop " & leadName(side))
        of Compound.Place:
          # One arm lets go and other takes, so they are not same arm.
          check way[0].side == other(side)
          check said.contains("from " & leadName(other(side)) & " into " &
            leadName(side))

  test "the two arms of a compound are always the two different arms":
    for source in FRAMES:
      for destination in FRAMES:
        if compound(source, destination).isNone:
          continue
        let
          there = compoundSide(source, destination)
          back = compoundSide(destination, source)
        check there.isSome and back.isSome
        check there.get != back.get


suite "routes":
  test "every frame reaches every other, and a route is a chain of moves":
    for source in FRAMES:
      for destination in FRAMES:
        if source == destination:
          check route(source, destination).len == 0
          continue
        let steps = route(source, destination)
        check steps.len > 0
        var current = source
        for step in steps:
          check classify(current, step.to) == some(step.helper)
          current = step.to
        check current == destination

  test "every step of a route is a move the frame it leaves is offering":
    # Stronger than chain above, which only checks primitive.  Step
    # also names hand of lead that acts, and anything reading route
    # back to dancer -- as page does, step by step -- is naming that
    # hand.  Step whose side disagreed with offered move would be
    # sentence telling them to use wrong arm.
    for source in FRAMES:
      for destination in FRAMES:
        var current = source
        for step in route(source, destination):
          check step in moves(current)
          current = step.to

  test "a shortest route never drops a hand it has just collected":
    # Taking hand and then letting it go is wasted work, and wasted work is
    # what makes route longer than it has to be.  Other order is ordinary
    # -- letting hand go and taking it somewhere else is how hand moves --
    # so this is not symmetric.
    for source in FRAMES:
      for destination in FRAMES:
        var collected: seq[Side] = @[]
        for step in route(source, destination):
          case step.helper
          of Helper.Collect: collected.add step.side
          of Helper.Drop: check step.side notin collected

  test "a step of a route reads the same from anywhere along it":
    # Which is what lets page name every step of route in same words
    # move panel names that move in.  It follows from law above rather
    # than from anything about phrasing: drop is only phrase that reads
    # frame it leaves, and by that law hand that route drops is one that was
    # held before route began, at site it was held.  Checked because
    # page leans on it, and it would be odd thing to have to rediscover.
    for source in FRAMES:
      for destination in FRAMES:
        var current = source
        for step in route(source, destination):
          check phrase(current, step) == phrase(source, step)
          current = step.to

  test "no frame is more than four moves from any other":
    var longest = 0
    for source in FRAMES:
      for destination in FRAMES:
        longest = max(longest, route(source, destination).len)
    check longest == 4

  test "a route is one move long exactly where a primitive exists":
    for source in FRAMES:
      for destination in FRAMES:
        if source == destination:
          continue
        let steps = route(source, destination)
        check (steps.len == 1) == classify(source, destination).isSome


suite "the vocabulary":
  test "no two moves share a mark, a name or a change":
    var marks: seq[char] = @[]
    var names, changes: seq[string] = @[]
    for helper in Helper:
      check HELPER_MARKS[helper] notin marks
      check helper.name notin names
      check HELPER_CHANGES[helper] notin changes
      check helper.manner.startsWith(helper.name)
      marks.add HELPER_MARKS[helper]
      names.add helper.name
      changes.add HELPER_CHANGES[helper]
    for named in Compound:
      check COMPOUND_MARKS[named] notin marks
      check COMPOUND_CHANGES[named] notin changes
      marks.add COMPOUND_MARKS[named]
      changes.add COMPOUND_CHANGES[named]

  test "a primitive with another word says so, and one without does not":
    check HELPER_SYNONYMS[Helper.Drop].len > 0
    check Helper.Drop.manner.contains("flick")  # vocabulary: drop led with momentum
    check HELPER_SYNONYMS[Helper.Collect].len == 0
    check Helper.Collect.manner == "collect"
