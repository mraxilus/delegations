## zbasu lo cunso se ciska poi vasru lo valsi poi galfi lo pu valsi
##   .i lo cipra pe lo jmive se ciska ge'u .e lo cipra pe lo nu jmina cu tcidu le se ciska
##   .i ki'u bo le se ciska liste cu vasru so'u le valsi
##   .i le valsi cu vimcu gi'a sitna gi'a krasi ja fanmo lo se ciska poi se vasru lo se ciska ku'o
##     gi'a fanmo le se ciska
##   .i lo sampu valsi cu sruri le valsi
##   .i se ki'u bo le liste cu se ciska pa roi to `II.9` toi
##   .i le zbasu cu cpacu le cupra be lo cunso namcu be'o pe le cipra
##   .i le cipra cu dunda lo tsiju le cupra
##   .i se ki'u bo lo se ciska pe ro cipra cu se cupra le cupra pe le cipra

{.experimental: "strictFuncs".}

import std/strutils


const
  WORDS_BUILT_MOST = 14  ## lo traji te kancu be lo valsi pe lo se ciska poi se zbasu
  WORDS_BUILT = [
    "mi", "do", "ko", "klama", "cadzu", "zarci", "broda", "le", "lo", "ku", "cu", "je", "bo", "nai",
    ".i", ".i", "ni'o", "si", "sa", "su", "zo", "lo'u", "le'u", "zoi", "gy", "la'o", "lu", "li'u",
    "to", "toi", "tu'e", "tu'u", "zei", "bu", "ba'e", "ui", "fa'o", "sa'a", "su'i", "xyz", "1987",
  ]
    ## lo valsi poi lo se ciska poi se zbasu cu vasru ke'a
    ##   .i su'o le valsi cu galfi lo pu valsi gi'a krasi ja fanmo lo nu sitna .a lo se ciska poi se
    ##     vasru lo se ciska ku'o gi'a fanmo le se ciska
    ##   .i su'o le valsi cu se krasi lo lerfu be lo valsi poi go'i
    ##   .i lo sampu valsi cu sruri le valsi



func textBuilt*[R](rng: var R): string =
  ## zbasu lo cunso se ciska poi vasru lo valsi poi galfi lo pu valsi
  ##   .i le zbasu cu pilno lo cupra be lo cunso namcu be'o poi `std/random` cu dunda ke'a le cipra
  mixin rand
  var words: seq[string]
  for k in 0 ..< rng.rand(1 .. WORDS_BUILT_MOST): words.add WORDS_BUILT[rng.rand(WORDS_BUILT.high)]
  words.join(" ")
