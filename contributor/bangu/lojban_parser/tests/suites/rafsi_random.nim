## Draw random rafsi from letters of each form of 4.6, whether list assigns them or not.
##   Suites of reader and of lujvo read same draw, so domain past list is spelled once (II.9).
##   Each pool seeds generator from seed caller names, as `randomize(0)` does, so it never
##     follows draws made before it.
##   Rafsi is drawn again until its letters fit its form, as pair rules of 3.6 and 3.7 ask;
##     CV'V takes apostrophe one time in two (4.6).

{.experimental: "strictFuncs".}

import std/[options, random, strutils]

import ../../src/lojban_parser/forms


const
  ORDER_CONSONANTS = "bcdfgjklmnprstvxz"  ## Seventeen consonants C stands for (4.1 rule 3).
  ORDER_VOWELS = "aeiou"  ## Five vowels V stands for, `y` excluded (4.1 rule 1).
  FORMS_BEFORE_LAST* = [Form.Cvc, Form.Ccv, Form.Cvv, Form.Cvcc, Form.Ccvc]
    ## Forms 4.11 step 1 allows before last rafsi: 3-letter or 4-letter.
  FORMS_AS_LAST* = [Form.Ccv, Form.Cvv, Form.Cvccv, Form.Ccvcv]
    ## Forms 4.11 step 2 allows last: CVV, CCV or 5-letter.


proc drawRafsiLetters*(shape: Form): string =
  ## Draw rafsi of `shape` from C and V of its notation, whether list assigns it or not.
  while true:
    var text = ""
    for symbol in ($shape).toLowerAscii:
      text.add(if symbol == 'c': ORDER_CONSONANTS.sample else: ORDER_VOWELS.sample)
    if shape == Form.Cvv and rand(1) == 0: text = text[0 .. 1] & "'" & text[2]
    if text.form == some(shape): return text


proc drawSequencesLetters*(count: int, lengths: Slice[int], seed: int64): seq[seq[string]] =
  ## Draw `count` rafsi sequences, each of `lengths` rafsi, each rafsi from letters of form
  ##   4.11 steps 1 and 2 allow at its position; form is drawn first, so rare forms come often.
  randomize(seed)
  result = newSeqOfCap[seq[string]](count)
  for _ in 1 .. count:
    let length = rand(lengths)
    var rafsi = newSeqOfCap[string](length)
    for i in 1 .. length:
      let shape = (if i == length: FORMS_AS_LAST.sample else: FORMS_BEFORE_LAST.sample)
      rafsi.add drawRafsiLetters(shape)
    result.add rafsi
