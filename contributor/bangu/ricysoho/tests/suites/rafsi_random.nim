## zbasu lo cunrafsi lo lerfu sepi'o ro tarmi pe `CLL 4.6`
##   .iju lo liste cu dunda le rafsi lo valsi
##   .i lo cipra pe le tcidu ge'u .e lo cipra pe lo lujvo cu pilno lo fancu pe le vi datnyvei
##   .i se ki'u bo lo rafsi poi na selcpa fi lo liste cu selzba ne'i pa datnyvei po'o to `II.9` toi
##
## ni'o lo tsiju poi lo pilno cu cusku ke'a jdice ro mupli ta'i `randomize(0)`
##   .i se ki'u bo no lo nu cuncu'a kei poi fasnu pu le mupli cu galfi le mupli
##   .i lo nu zbasu lo rafsi cu se rapli va'o lo nu lo lerfu pe le rafsi cu na mapti lo tarmi be le
##       rafsi ja'i lo zunsna remei javni pe `CLL 3.6` jo'u `CLL 3.7`
##   .i lo nu lo rafsi poi seltai `CVV` seltai `CV'V` cu cunso fi li pa fi'u re lo'o to `CLL 4.6`
##       toi

{.experimental: "strictFuncs".}

import std/[options, random, strutils]

import ../../src/ricysoho/forms


const
  ORDER_CONSONANTS = "bcdfgjklmnprstvxz"
    ## lo paze zunsna poi `C` sinxa ke'a ja'i `CLL 4.1 rule 3`
  ORDER_VOWELS = "aeiou"
    ## lo mu karsna poi `V` sinxa ke'a ja'i `CLL 4.1 rule 1`
    ##   .i `y` na cmima le mu karsna
  FORMS_BEFORE_LAST* = [Form.Cvc, Form.Ccv, Form.Cvv, Form.Cvcc, Form.Ccvc]
    ## lo tarmi poi `CLL 4.11 step 1` curmi ke'a bu'u lo stuzi poi na romoi
    ##   .i ro le tarmi cu vasru ci lerfu .a vo lerfu
  FORMS_AS_LAST* = [Form.Ccv, Form.Cvv, Form.Cvccv, Form.Ccvcv]
    ## lo tarmi poi `CLL 4.11 step 2` curmi ke'a bu'u lo romoi stuzi
    ##   .i ro le tarmi cu du `CVV` .a `CCV` .a lo tarmi poi vasru mu lerfu


proc drawRafsiLetters*(shape: Form): string =
  ## zbasu lo rafsi be fi `shape` be'o lo lerfu
  ##   .iju lo liste cu dunda le rafsi lo valsi
  ##   .i ro `C` pe lo sinxa be le tarmi cu se basti pa zunsna
  ##   .i ro `V` se basti pa karsna
  while true:
    var text = ""
    for symbol in ($shape).toLowerAscii:
      text.add(if symbol == 'c': ORDER_CONSONANTS.sample else: ORDER_VOWELS.sample)
    if shape == Form.Cvv and rand(1) == 0: text = text[0 .. 1] & "'" & text[2]
    if text.form == some(shape): return text


proc drawSequencesLetters*(count: int, lengths: Slice[int], seed: int64): seq[seq[string]] =
  ## zbasu lo porsi be lo rafsi
  ##   .i lo te kancu be le porsi cu du `count`
  ##   .i lo te kancu be lo rafsi pe ro porsi cu cmima `lengths`
  ##
  ## ni'o ro rafsi cu selzba lo lerfu ja'i pa tarmi poi `CLL 4.11 step 1` .e `CLL 4.11 step 2` curmi
  ##     ke'a bu'u le stuzi be le rafsi
  ##   .i lo tarmi cu selcu'a pu lo nu cuxna lo lerfu
  ##   .i se ki'u bo lo tarmi poi rirci cu so'i roi selpli
  randomize(seed)
  result = newSeqOfCap[seq[string]](count)
  for _ in 1 .. count:
    let length = rand(lengths)
    var rafsi = newSeqOfCap[string](length)
    for i in 1 .. length:
      let shape = (if i == length: FORMS_AS_LAST.sample else: FORMS_BEFORE_LAST.sample)
      rafsi.add drawRafsiLetters(shape)
    result.add rafsi
