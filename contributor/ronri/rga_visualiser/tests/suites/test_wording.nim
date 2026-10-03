## Run `Wording` suite: one module of shared suite, which `../suites.nim` imports in order.

{.experimental: "strictFuncs".}

import ./fixtures
import ../../tools/catalogue


suite "Wording":
  test "every key carries text, and no two prose keys carry the same text":
    # Empty entry would draw empty tooltip, which reads as broken rather than as silent.
    #   Compiler already refuses key with no row; this refuses row with no words in it.
    #   Two prose keys sharing text is copy-paste: one control took another's key, and both
    #   then move together when only one should.
    #   Labels are held to no such rule, and deliberately: `NameRowHide` and `NamePickHide`
    #   both read "hide" because two buttons honestly wear one word, and translator may
    #   still need them apart. Key names control, not word.
    var seen: Table[string, Wording]
    for key in Wording:
      check isCarryingWords(key)
      if key.isNamingControl: continue
      let text = $wordingText(key)
      if text in seen:
        checkpoint(&"`{key}` says what `{seen[text]}` says: {text}")
        fail()
      seen[text] = key


  test "every piece of prose reads as one finished sentence":
    # Tooltip and note are prose reader reads, not labels. Each stops at full stop, carries
    #   no stray space, and starts with capital -- three things eye notices and no reviewer
    #   reliably does.
    for key in Wording:
      if key.isNamingControl or key.isHelpCell: continue
      let text = $wordingText(key)
      check text == strip(text)
      check "  " notin text
      check text.endsWith(".")
      check text[0].isUpperAscii


  test "every help cell reads as a fragment, across its row":
    # Cell is neither label nor sentence: reader reads action and outcome across one row,
    #   so capital opening cell or full stop closing it breaks that reading. Held to
    #   fragment's own shape, and to prose's rule that no two say one thing.
    for key in Wording:
      if not key.isHelpCell: continue
      let text = $wordingText(key)
      check text == strip(text)
      check "  " notin text
      check not text.endsWith(".")
      check not text[0].isUpperAscii


  test "every label stays a label":
    # Label is word on control, and holding it to sentence's shape would be wrong check:
    #   "add" ends in no full stop and begins in no capital, and both are right.
    #   What label may not be is padded, doubled-spaced, or long enough to be prose --
    #   window padded `?` to size its button once, and that put layout in catalogue.
    for key in Wording:
      if not key.isNamingControl: continue
      let text = $wordingText(key)
      check text == strip(text)
      check "  " notin text
      check not text.endsWith(".")
      check runeLen(text) <= RUNES_LABEL_MOST


  test "the three that had drifted now read one way, and keep what each side knew":
    # Page and window each said these differently before one catalogue held them.
    #   Pinned here because surviving wording is decision rather than accident: where one
    #   side knew more, fuller sentence won.
    # Window worded radius tersely; page's prose won.
    check $wordingText(TipRowRadius) ==
      "Radius the point is drawn at, in world units; it shrinks with distance."
    # Page named picking alone; window said why view rings what is picked.
    check "rings each one" in $wordingText(TipRowSelect)


  test "the application names itself as a name, and every other label stays a word":
    # Label is word on control and stays lower case. This one is proper noun both front-ends
    #   show, window's own caption included, and it was written half one way: `RGA` carried
    #   its capital where second word did not.
    for word in strutils.splitWhitespace($wordingText(NameTitle)):
      check word[0].isUpperAscii
    for key in Wording:
      if not key.isNamingControl or key == NameTitle: continue
      let text = $wordingText(key)
      check not text[0].isUpperAscii


  test "the window's caption reads the catalogue rather than spelling the name again":
    # Window carried its own copy of product's name, which no sweep reached. Title-casing
    #   catalogue alone would have left one build spelling its own name two ways.
    #   Held here rather than beside window because `main` links SDL and GL, which no test
    #   binary carries; composition lives in catalogue for exactly that reason.
    check captionWindow().endsWith($wordingText(NameTitle))
    check captionWindow().startsWith(NAME_AUTHORITY)
    check captionWindow().count($wordingText(NameTitle)) == 1


  test "a demo size names itself, and only the opening size says so":
    # Sentence carries figure no catalogue row can hold, so it is composed from parts
    #   catalogue does hold -- and composing is held to here rather than in two front-ends
    #   writing it out.
    let told = demoWording(33, is_default = false)
    check "33 objects" in told
    check "The size everything opens on." notin told
    check demoWording(33, is_default = true).endsWith("The size everything opens on.")
    check told.endsWith(".")


  test "the view's readings write degrees and multiples of light, as both builds show them":
    var
      line: array[32, char]
      cursor = 0
    appendDegrees(line, cursor, PI/3.0)
    finishChars(line, cursor)
    check toText(line) == "60°"
    cursor = 0
    appendSpeedLight(line, cursor, 3712.84)
    finishChars(line, cursor)
    check toText(line) == "3713 c"
    cursor = 0
    appendSpeedLight(line, cursor, 0.0)
    finishChars(line, cursor)
    check toText(line) == "0 c"
    # Scale bar's claim, singular at one.
    for (span, text) in [(1.0, "1 unit"), (2.0, "2 units"), (500.0, "500 units")]:
      cursor = 0
      appendRuler(line, cursor, span)
      finishChars(line, cursor)
      check toText(line) == text


  test "a search says how many objects it shows, of how many the scene holds":
    # Same line on both builds: window writes it every frame and page reads it through bridge,.
    #   so integer formatting has branch per backend and this holds them to one answer.
    var
      line: array[32, char]
      cursor = 0
    appendShownCounted(line, cursor, 12, 5038)
    finishChars(line, cursor)
    check toText(line) == "12 of 5038 shown"


  test "the driver's reading of the catalogue as text holds every key and every row":
    # Driver reads `wording.nim` as text and imports none of it, so type check compiles no
    #   project code on koch's compiler (#385). Here, on pin, reading meets compiled enum
    #   and table: key moved or row written in form reading cannot follow fails here.
    const SOURCE = staticRead("../../src/rga_visualiser/wording.nim")
    let (keys, words) = (keysOf(SOURCE), wordsOf(SOURCE))
    check keys.len == ord(high(Wording)) + 1
    check words.len == keys.len
    for key in Wording:
      check keys[ord(key)] == $key
      check words.getOrDefault($key, "") == $wordingText(key)
