discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Test laws of frame: validity, naming, keys and reflection.

{.experimental: "strictFuncs".}

import std/[options, strutils, unittest]

import ../src/dance_ontology/frame


suite "frames":
  test "every enumerated frame is valid and distinct":
    check FRAMES.len == 8
    for target in FRAMES:
      check target.isValid
    for index, target in FRAMES:
      check target.frameIndex == some(index)

  test "an arm order is recorded exactly where the forearms overlap":
    var overlapping = 0
    for target in FRAMES:
      check target.over.isSome == target.hasOverlap
      if target.hasOverlap:
        inc overlapping
    check overlapping == 2  # Left over Right, and Right over Left.

  test "only the same-named hands cross the midline":
    check isCrossed(Side.Left, Site.LeftHand)
    check isCrossed(Side.Right, Site.RightHand)
    check not isCrossed(Side.Left, Site.RightHand)
    check not isCrossed(Side.Right, Site.LeftHand)
    for side in Side:
      check parallelSite(side) != crossedSite(side)

  test "a frame survives a round trip through its key":
    var keys: seq[string] = @[]
    for target in FRAMES:
      check fromKey(target.key) == some(target)
      check target.key notin keys
      keys.add target.key

  test "a key that is not a valid frame is rejected":
    check fromKey("").isNone
    check fromKey("--").isNone
    check fromKey("zz.").isNone
    check fromKey("t-.").isNone  # Hand on body is not hand-to-hand frame.
    check fromKey("ll.").isNone  # One follow hand cannot be held twice.
    check fromKey("lr.").isNone  # Overlapping forearms need order.
    check fromKey("rlL").isNone  # Parallel pair has no order to record.

  test "reflection is an involution and permutes the frames":
    for target in FRAMES:
      check target.reflect.isValid
      check target.reflect.reflect == target
      check target.reflect.frameIndex.isSome
    var seen: seq[Frame] = @[]
    for target in FRAMES:
      check target.reflect notin seen
      seen.add target.reflect

  test "reflection exchanges the crossing orders and fixes the parallel pair":
    let over_left = fromKey("lrL").get
    check over_left.reflect == fromKey("lrR").get
    check fromKey("rl.").get.reflect == fromKey("rl.").get
    check fromKey("l-.").get.reflect == fromKey("-r.").get


suite "hands":
  test "the two readings of a connection agree with each other":
    for target in FRAMES:
      var held = 0
      for site in Site:
        check target.isHeld(site) == target.holder(site).isSome
        if target.isHeld(site):
          inc held
          check target.hold[target.holder(site).get] == some(site)
      var reaching = 0
      for side in Side:
        check target.usesHand(side) == target.hold[side].isSome
        if target.usesHand(side):
          inc reaching
      # Connection is one hand of each, so counting either end counts it.
      check held == target.countHolds
      check reaching == target.countHolds

  test "reflection swaps which hand is asked about":
    for target in FRAMES:
      for side in Side:
        check target.usesHand(side) == target.reflect.usesHand(other(side))
      check target.isHeld(Site.LeftHand) == target.reflect.isHeld(Site.RightHand)

  test "a hand of the follow is held by at most one hand of the lead":
    let both = fromKey("lrL").get
    check both.holder(Site.LeftHand) == some(Side.Left)
    check both.holder(Site.RightHand) == some(Side.Right)
    let free_frame = fromKey("--.").get
    for site in Site:
      check free_frame.holder(site).isNone
    for side in Side:
      check not free_frame.usesHand(side)


suite "naming":
  test "every frame is named":
    var names: seq[string] = @[]
    for target in FRAMES:
      check target.describe.len > 0
      check target.position.len > 0
      check target.describe notin names
      names.add target.describe
    check fromKey("--.").get.describe == "free"

  test "the workbook's names come out of the structure":
    check fromKey("l-.").get.describe == "Left to left"  # base: five of its nine rows follow
    check fromKey("r-.").get.describe == "Left to right"
    check fromKey("rl.").get.describe == "Left-to-right and Right-to-left"
    check fromKey("lrL").get.describe == "Left-to-left over Right-to-right"
    check fromKey("lrR").get.describe == "Right-to-right over Left-to-left"

  test "the two crossing orders are one position and two frames":
    let over_left = fromKey("lrL").get
    let over_right = fromKey("lrR").get
    check over_left != over_right
    check over_left.position == over_right.position
    check over_left.position == "Left-to-left and Right-to-right"

  test "the short name says everything the long one does, in fewer letters":
    # It is used where long name will not fit, so it has to name frame
    # on its own: two frames sharing short name would be two rows of
    # matrix reader could not tell apart.
    var briefly_named: seq[string] = @[]
    for target in FRAMES:
      check target.brief.len > 0
      check target.brief.len <= target.describe.len
      check target.brief notin briefly_named
      briefly_named.add target.brief

  test "a short name keeps the case that says whose hand it is":
    # Case is whole of how two dancers are told apart, and letter
    # has case: abbreviation that lost it would lose one thing
    # vocabulary cannot say any other way.
    for side in Side:
      check briefName(side) == leadName(side)[0 .. 0]
      check isUpperAscii(briefName(side)[0])
    for site in Site:
      check briefName(site) == followName(site)[0 .. 0]
      check isLowerAscii(briefName(site)[0])
    for target in FRAMES:
      if target.countHolds == 0:
        continue
      for side in Side:
        if target.hold[side].isSome:
          check target.brief.contains(briefName(side))
          check target.brief.contains(briefName(target.hold[side].get))
