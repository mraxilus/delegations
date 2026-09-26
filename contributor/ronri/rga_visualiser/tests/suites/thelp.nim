## Run `Help` suite: one module of shared suite, which `../suites.nim` imports in order.

import ./fixtures


suite "Help":
  test "every entry lands in exactly one tab, and the tabs account for the whole table":
    # What stops reflow that quietly drops row to make rest fit. `countOf` is what.
    #   both front-ends size tab from, so summing it is summing what is actually drawn.
    var total = 0
    for path in HelpPath: total += countOf(path)
    check total == len(lut_help_entries)


  test "no tab holds more than fits the smallest screen this help supports":
    # Asserted at compile time too, in `help.nim`'s own `static` block; stated here as well.
    #   because that assertion is invisible in passing run, and this is property
    #   whole tab split exists to hold.
    #   Two paths have bounds of their own. `keys` describes keyboard, and screen this
    #   bound is proxy for is phone; `operations` *is* catalogue, one row per
    #   operation, and only bound worth holding it to is that size exactly.
    for path in HelpPath:
      let entries_max =
        case path
        of HelpPath.Operations: ENTRIES_MAX_PATH_CATALOGUE
        of HelpPath.Keys: ENTRIES_MAX_PATH_KEYS
        else: ENTRIES_MAX_PATH
      check countOf(path) in 1 .. entries_max


  test "the help records every operation the build offers, by the name it offers it under":
    # Generated from catalogue rather than transcribed, so this cannot drift -- and.
    #   case is here to say that if anyone ever transcribes it, drift fails build.
    for operation in Operation:
      var is_listed = false
      for entry in lut_help_entries:
        if entry.path == HelpPath.Operations and entry.action == notationSymbolic(operation):
          check entry.outcome == notationNamed(operation)
          is_listed = true
      check is_listed
    check countOf(HelpPath.Operations) == COUNT_OPERATION


  test "the help names every wedge the drag wheel offers, and says which word it is":
    # Wedge wears notation alone, which names nothing until reader is told it is `join`.
    #   Desktop taught that above its sections and browser in line it has since dropped, so
    #   nothing taught it for while; help's drag tab is where it lives now, and this is
    #   what keeps it there. Wedge renamed with no telling fails here rather than quietly
    #   leaving reader with three symbols and no words.
    let described = descriptionOf(HelpPath.Drag)
    for choice in [DragChoice.Join, DragChoice.Meet, DragChoice.Project]:
      check wordOf(choice) in described
      check labelOf(choice) in described
    # `More` takes bare ellipsis, which needs no decoding; its row already says what it does.
    check wordOf(DragChoice.More) notin described


  test "the help records every key, every motion and every action the view answers":
    # What "up to date" has to mean if it is to stay true: binding added without row.
    #   fails build day it is added, rather than being noticed by reader who
    #   went looking for it and found nothing.
    let text = block:
      var joined = ""
      for entry in lut_help_entries: joined &= entry.action & " " & entry.outcome & " "
      joined
    for key in Key:
      check nameOf(key) in text
    # Every motion and action is *described* by some row; rows group them by job, so.
    #   this asks for words reader would look for rather than enum's own name.
    for phrase in [
      "slide the view", "raise or lower", "orbit", "further out", "faster", "roll",
      "twist",
      "previous or next object", "select", "back into view", "back where it started",
    ]:
      check phrase in text


  test "a tab's entries are contiguous, so neither UI renders one tab twice":
    var
      seen: set[HelpPath]
      path_last = none(HelpPath)
    for entry in lut_help_entries:
      if path_last == some(entry.path): continue
      check entry.path notin seen
      seen.incl(entry.path)
      path_last = some(entry.path)


  test "every action and outcome is written, so no row draws as a blank line":
    for entry in lut_help_entries:
      check len(entry.action) > 0
      check len(entry.outcome) > 0


  test "the menu tab names each button by the button's own key":
    # Row whose action is button is read from that button's key, so button renamed is
    #   renamed in its row; row written out again would have been copy that drifted.
    var actions: seq[string]
    for entry in lut_help_entries:
      if entry.path == HelpPath.Menu: actions.add(entry.action)
    check actions == [
      $wordingText(NamePickApply), $wordingText(NamePickEdit), $wordingText(NamePickHide),
      $wordingText(NamePickDelete), $wordingText(NamePickClose),
    ]


  test "an apply's outcome is one sentence, however it was applied":
    # Written at four sites before: drag's outcome in `interaction`, panel's apply, desktop's
    #   storyboard and bridge's apply, so one edit moved one of them.
    check derivedMessage("m ∧ n", "line") == "m ∧ n gave line."
    check len(derivedMessage("m ∧ n", "line")) < MESSAGE_MAX


  test "every tab says what it is about, so none opens on rows with no context":
    # Check line above rows, carrying what two-column row cannot.
    #   Which menu this is, what wedge is; path added without one would render that line
    #   blank, which reads as gap rather than as omission.
    for path in HelpPath:
      check len(descriptionOf(path)) > 0
      # Sentence, not label: tab strip already carries short form.
      check len(descriptionOf(path)) > len(titleOf(path))
