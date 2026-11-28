## zbasu lo cunselci'a poi vasru lo valsi poi galfi lo pu valsi
##   .i lo cipra pe lo mivyselci'a ge'u .e lo cipra pe lo nu jmina cu tcidu le selci'a
##   .i ki'u bo le selci'aste cu vasru so'u le valsi
##   .i le valsi cu vimcu gi'a sitna gi'a krasi ja fanmo lo selci'a poi selvau lo selci'a ku'o gi'a
##       fanmo le selci'a
##   .i lo sapyvla cu sruri le valsi
##   .i se ki'u bo le liste cu selci'a pa roi to `II.9` toi
##
## ni'o le zbasu cu cpacu le cupra be lo cunyna'u be'o pe le cipra noi dunda lo tsiju le cupra
##   .i se ki'u bo lo selci'a pe ro cipra cu selpra le cupra pe le cipra

{.experimental: "strictFuncs".}

import std/strutils


const  # lo valsi pe lo selci'a poi selzba
  WORDS_BUILT_MOST = 14  ## lo rairterkancu be lo valsi pe lo selci'a poi selzba
  WORDS_BUILT = [
    "mi", "do", "ko", "klama", "cadzu", "zarci", "broda", "le", "lo", "ku", "cu", "je", "bo", "nai",
    ".i", ".i", "ni'o", "si", "sa", "su", "zo", "lo'u", "le'u", "zoi", "gy", "la'o", "lu", "li'u",
    "to", "toi", "tu'e", "tu'u", "zei", "bu", "ba'e", "ui", "fa'o", "sa'a", "su'i", "xyz", "html",
  ]
    ## lo valsi poi lo selci'a poi selzba cu vasru ke'a
    ##   .i su'o le valsi cu galfi lo pu valsi gi'a krasi ja fanmo lo nu sitna .a lo selci'a poi
    ##       selvau lo selci'a ku'o gi'a fanmo le selci'a
    ##   .i su'o le valsi cu selkra lo lerfu be lo valsi poi go'i
    ##   .i lo sapyvla cu sruri le valsi



func textBuilt*[R](rng: var R): string =
  ## zbasu lo cunselci'a poi vasru lo valsi poi galfi lo pu valsi
  ##   .i pilno lo cupra be lo cunyna'u be'o poi `std/random` dunda ke'a le cipra
  mixin rand
  var words: seq[string]
  for k in 0 ..< rng.rand(1 .. WORDS_BUILT_MOST): words.add WORDS_BUILT[rng.rand(WORDS_BUILT.high)]
  words.join(" ")
