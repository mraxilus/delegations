## Build texts of words that reach back, at random, which suites of live text and of merge read,
##   since corpora hold few of them: words that erase, quote, open or close text inside text, or
##   end input, among plain words. So list is written once (II.9).
##   Builder takes generator of suite, which seeds it, so each suite reads texts it read before.

{.experimental: "strictFuncs".}

import std/strutils


const
  WORDS_BUILT_MOST = 14  ## Words of text built, at most.
  WORDS_BUILT = [
    "mi", "do", "ko", "klama", "cadzu", "zarci", "broda", "le", "lo", "ku", "cu", "je", "bo", "nai",
    ".i", ".i", "ni'o", "si", "sa", "su", "zo", "lo'u", "le'u", "zoi", "gy", "la'o", "lu", "li'u",
    "to", "toi", "tu'e", "tu'u", "zei", "bu", "ba'e", "ui", "fa'o", "sa'a", "su'i", "xyz", "1987",
  ]
    ## Words texts built hold: words that reach back, open or close quotation or text inside
    ##   text, end input, or start with words that do; and plain words around them.



func textBuilt*[R](rng: var R): string =
  ## Build text of words that reach back, at random, from generator `std/random` gives suite.
  mixin rand
  var words: seq[string]
  for k in 0 ..< rng.rand(1 .. WORDS_BUILT_MOST): words.add WORDS_BUILT[rng.rand(WORDS_BUILT.high)]
  words.join(" ")
