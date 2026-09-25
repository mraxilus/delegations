## Run `Message` suite: one module of shared suite, which `../suites.nim` imports in order.

import ./fixtures


suite "Message":
  test "an outcome stands its time, fades, and reaches nothing at all":
    # Whole defect this module exists for. Window had no age on its message: line stood
    #   until something else replaced it, so scene carried outcome of action taken
    #   minutes ago as if it had just happened, and opened carrying "Ready.", which was
    #   outcome of nothing.
    #   Read as fraction still on screen, which is what drawing multiplies alpha by.
    check messageFade(0.0) == 1.0
    check messageFade(0.5*SECONDS_MESSAGE) == 1.0
    check messageFade(SECONDS_MESSAGE) == 1.0
    # Halfway through fade, half of it is left.
    check messageFade(SECONDS_MESSAGE + 0.5*SECONDS_MESSAGE_FADE) =~ 0.5
    # Exactly nothing by end of fade, and nothing ever after -- not merely small.
    check messageFade(SECONDS_MESSAGE + SECONDS_MESSAGE_FADE) == 0.0
    check messageFade(60.0) == 0.0
    # Never rises again, at any age.
    var previous = 1.0
    for step in 0 .. 200:
      let faded = messageFade(float(step)*0.05)
      check faded <= previous
      previous = faded


  test "a count says how many, in words that are not `object(s)`":
    # Page counted what it acted on and window named selection instead, for one press of
    #   one button; parenthesis was page's way of holding both numbers at once.
    check objectsCounted(1) == "1 object"
    check objectsCounted(2) == "2 objects"
    check objectsCounted(0) == "0 objects"
    for count in 0 .. 8:
      check "(s)" notin objectsCounted(count)


  test "every outcome both front-ends report is one sentence, said once":
    # Wording is pinned here rather than left to whichever front-end is read first: two
    #   copies is what drifted, and case that quotes sentence fails moment either side
    #   is edited on its own.
    check deletedMessage(3) == "Deleted 3 objects."
    check deletedMessage(1) == "Deleted 1 object."
    check visibilityMessage(2, is_shown = true) == "Showed 2 objects."
    check visibilityMessage(2, is_shown = false) == "Hid 2 objects."
    check addedMessage("m4") == "Added `m4`."
    check savedMessage("m4") == "Saved `m4`."
    check removedMessage("m4") == "Removed `m4`."
    check fullMessage() == "Scene is full."
    check cancelledMessage() == "Cancelled."
    check stepMessage(is_undo = true) == "Nothing to undo."
    check stepMessage(is_undo = false) == "Nothing to redo."
    check orreryMessage(33, 128) == "Loaded the orrery: 33 objects, 95 handles free."


  test "a refusal names what the scene holds by the word the glossary settled on":
    # One side asked for "point" and other for "multivector"; scene holds objects, and.
    #   kind is what point, line and plane are. Neither front-end said that.
    check emptyMessage() == "Scene is empty; add an object first."
    check "multivector" notin emptyMessage()
    check "point" notin emptyMessage()


  test "every sentence fits the storage window draws it through":
    # Window copies outcome into `MESSAGE_MAX` chars and marks truncation with ellipsis.
    #   Longest sentence here is orrery's at full pool, and case fails before reader sees
    #   sentence cut off mid-word.
    let longest = orreryMessage(OBJECTS_MAX, OBJECTS_MAX)
    check len(longest) < MESSAGE_MAX
    for text in [
      deletedMessage(OBJECTS_MAX), visibilityMessage(OBJECTS_MAX, is_shown = true),
      fullMessage(), emptyMessage(), stepMessage(is_undo = true),
    ]:
      check len(text) < MESSAGE_MAX
