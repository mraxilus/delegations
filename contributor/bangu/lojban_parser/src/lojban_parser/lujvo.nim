## ja'i `CLL 4.11` .e `CLL 4.12` cu jmina lo rafsi fo lo lujvo gi'e dunda lo namcu lo lujvo gi'e
##   fendi lo lujvo fi lo rafsi
##
##   |-----------------|-------------------------------------------------------|------------------|
##   | lo cmene        | `CLL`                                                 | lo ckupau        |
##   |-----------------|-------------------------------------------------------|------------------|
##   | `Hyphen.Y`      | lo lerfu jorne po'u `y`                               | `4.6, 4.11`      |
##   | `Hyphen.R`      | lo lerfu jorne po'u `r`                               | `4.6, 4.11 (4a)` |
##   | `Hyphen.N`      | lo lerfu jorne po'u `n` noi lidne `r` po'o            | `4.6, 4.11 (4a)` |
##   | `joinRafsi`     | `steps 3 to 5` pe lo tadji be lo nu zbasu lo lujvo    | `4.11`           |
##   | `hyphensRafsi`  | lo lerfu jorne poi `step 4` .e `step 5` cu punji ke'a | `4.11`           |
##   | `score`         | lo lujvo namcu tadji                                  | `4.12`           |
##   |                 | .i lo cmalu traji cu se nelci                         |                  |
##   | `scoreRafsi`    | lo pagbu be lo namcu be'o poi pa rafsi cu jmina ke'a  | `4.12`           |
##   | `scoreJunction` | lo pagbu poi pa te jorne cu jmina ja'i `step 5` ji'a  | `4.11, 4.12`     |
##   | `isRunOpen`     | lo du'u lo pamoi rafsi cu krasi lo porsi pe `step 5`  | `4.11 (5)`       |
##   | `splitLujvo`    | lo dukti be `joinRafsi`                               | `4.5, 4.11`      |
##   |-----------------|-------------------------------------------------------|------------------|
##
## ni'o `splitLujvo` cu ralte pa te fendi va'o lo nu `joinRafsi` cu jmina le te fendi fo lo valsi
##   poi mintu le se fendi ro lerfu kei po'o
##   .i se ki'u bo lo jalge be lo nu fendi gi'e ba bo jmina cu du le valsi ki'u lo tarmi be le
##     samtci
##   .i `CLL 4.11` cu to'e curmi lo lerfu jorne va'o lo nu le tadji cu na nitcu le lerfu jorne
##   .i se ki'u bo lo nu karbi le valsi lo jalge be le tadji cu cipra fi ro lerfu jorne
##   .i se to'e cuxna fa lo nu cipra ro te jorne ja'i lo javni pe lo lerfu poi jibni le te jorne
##   .i le javni cu rinka lo nu le samtci cu re roi cusku le tadji
##   .i lo nu jmina cu jersi `CLL 4.11` ta'i lo nu klama fi lo pritu fe lo zunle kei noi `step 5` cu
##     cpedu ke'a
##   .i `step 4a` bi'o `step 4c` cu jdice fi ro te jorne pu lo nu lo cipra pe `tosmabru` cu tcidu le
##     te jorne
##   .i `hyphenJunction` cu jdice fi ro te jorne ja'i le re rafsi poi jibni le te jorne
##   .i ne'i `carryRun` lo cipra pe `tosmabru` cu tcidu ro te jorne ta'i lo nu klama fi lo zunle fe
##     lo pritu kei sepi'o pa lanci noi cusku lo du'u xu kau le krasi porsi cu kalri
##   .i se ki'u bo lo namcu cu sumji lo pagbu pe ro rafsi lo pagbu pe ro te jorne
##   .i se ki'u bo lo nu ciska lo tanru ta'i lo lujvo cu sisku ta'i lo nu tcidu ro stuzi ta'i lo
##     porsi
##   .i jdima fa lo nu `step 5` cu tcidu ro te jorne ta'i lo nu sepli kei gi'e no roi tcidu le mulno
##     porsi
##   .i se ki'u bo `test_lujvo.nim` cu cipra lo du'u lo namcu pe ro lujvo cu sumji lo pagbu pe ro
##     rafsi lo pagbu pe ro te jorne
##   .i lo pagbu be lo namcu be'o .e lo pagbu be `step 5` be'o cu stali lo ka sivni
##   .i `tanru.nim` .e `test_lujvo.nim` cu cpacu ro sinxa `lujvo.nim` mu'i lo nu pilno le pagbu
##   .i se ki'u bo lo cmene poi le ralju samtci pagbu cu dunda ke'a cu stali to `#832` toi
##   .i `step 4b` pe `CLL 4.11` cu casnu po'o lo zunsna remei poi na se curmi
##   .i `CLL` na casnu lo te jorne poi zbasu lo zunsna cimei po'u `ndj` .a `ndz` .a `ntc` .a `nts`
##   .i `CLL 3.7` cu to'e curmi le vo zunsna cimei bu'u lo midju be lo valsi
##   .i `joinRafsi` cu punji `y` le te jorne ji'a
##   .i se ki'u bo ro lujvo poi `joinRafsi` cu zbasu ke'a cu mapti `CLL 3.7`
##   .i jdima fa lo nu `joinRafsi` cu pilno pa javni poi `CLL 4.11` na cusku ke'a
##   .i `test_lujvo.nim` cu cusku le javni bu'u lo mupli poi le javni cu galfi ke'a
##   .i `splitLujvo` cu retsku fi no vlaste
##   .i `splitLujvo` cu jdice fi lo cumki rafsi ja'i lo tarmi po'o sepi'o `forms.nim`
##   .i lo pilno cu retsku fi lo vlaste fo ro rafsi
##   .i se ki'u bo lo tarmi be lo valsi cu ka'e sepli lo vlaste
##   .i jdima fa lo nu `splitLujvo` cu cipra fi ro te fendi sepi'o lo fancu poi pilno vo'a
##   .i bu'u ro stuzi lo lujvo poi vasru vei ny. ve'o rafsi cu ponse su'e so'u cumki rafsi
##   .i lo valsi cu tordu
##   .i se ki'u bo le jdima cu cmalu
##   .i le jdima cu na se merli
##   .i lo jdima cu na se tcidu ki'u lo nu no glare pluta cu zvati
##   .i ca ro nu le tcidu cu tcidu pa valsi kei `splitLujvo` .e `joinRafsi` cu pa roi se pilno

{.experimental: "strictFuncs".}

import std/[options, sequtils, strutils]

import ./[clusters, forms]


type
  Hyphen* {.pure.} = enum  ## lo lerfu jorne poi lo rafsi cu lidne ke'a to `CLL 4.6` toi
    None, Y, R, N

  Piece* = object
    ## lo lerfu be pa rafsi pe lo lujvo be'o .e lo lerfu jorne poi le rafsi cu lidne ke'a
    rafsi*: string  ## lo lerfu be le rafsi to zoi gy. ' .gy. cu se vasru ji'a toi
    form*: Form  ## lo tarmi be le rafsi to `forms.nim` toi
    hyphen*: Hyphen
      ## lo lerfu jorne poi le rafsi cu lidne ke'a
      ##   .i lo romoi rafsi cu lidne `None`


const
  LUT_LETTER_BY_HYPHEN*: array[Hyphen, string] = ["", "y", "r", "n"]
    ## lo lerfu poi lo lerfu jorne cu ciska ke'a
  LUT_VALUE_BY_FORM: array[Form, int] = [
    Form.Cvc: 5,
    Form.Ccv: 7,
    Form.Cvv: 8,
    Form.Cvcc: 2,
    Form.Ccvc: 4,
    Form.Cvccv: 1,
    Form.Ccvcv: 3,
  ]
    ## lo namcu poi `step 4` pe `CLL 4.12` cu dunda ke'a lo tarmi
    ##   .i ku'i lo rafsi poi se tarmi la'o gy. CVV .gy. gi'e vasru zoi gy. ' .gy. cu cpacu li xa



#[ ni'o ni'o ni'o lo nu jmina ]#

func isPositionValid(forms: openArray[Form]): bool =
  ## jdice lo du'u xu kau `forms` cu mapti lo stuzi poi `step 1` .e `step 2` vu'o pe `CLL 4.11` cu
  ##   curmi ke'a
  ##   .i su'o re rafsi cu zvati
  ##   .i ro rafsi poi lidne le romoi rafsi cu cmalu gi'a vasru vo lerfu
  ##   .i le romoi rafsi cu se tarmi la'o gy. CVV .gy. .a la'o gy. CCV .gy. gi'a vasru mu lerfu
  if forms.len < 2 or forms[^1] notin FORMS_FINAL: return false
  for one in forms[0 .. ^2]:
    if one notin FORMS_SHORT + FORMS_UNREDUCED: return false
  true


func hyphenJunction(before, after: string; at, count: int): Hyphen =
  ## jdice fi lo lerfu jorne poi lidne `after` gi'e se lidne `before` ku'o ja'i `step 4a` bi'o
  ##   `step 4c` vu'o pe `CLL 4.11`
  ##   .i `before` cu zvati lo stuzi po'u `at`
  ##   .i `count` cu te kancu lo rafsi
  ##   .i ba bo `step 5` cu ka'e punji `y` lo pamoi te jorne ne'i `carryRun`
  let form_before = before.form.get

  # ja'i `step 4a` lo pamoi rafsi poi se tarmi la'o gy. CVV .gy. cu cpacu `r` .a `n` noi lidne `r`
  #   .i ku'i le rafsi cu cpacu no da va'o lo nu lo lujvo cu vasru re rafsi po'o gi'e se fanmo lo
  #     rafsi poi se tarmi la'o gy. CCV .gy.
  if at == 0 and form_before == Form.Cvv and (count > 2 or after.form.get != Form.Ccv):
    return (if after[0] == 'r': Hyphen.N else: Hyphen.R)

  # ja'i `step 4c` ro rafsi poi vasru vo lerfu cu lidne `y`
  #   .i lo du'u le rafsi cu lidne ma kau zunsna remei cu na vajni
  if form_before in FORMS_UNREDUCED: return Hyphen.Y

  # ja'i `step 4b` `y` cu zvati lo jbini be le re zunsna pe lo zunsna remei poi na se curmi
  #   .i ji'a `y` cu fendi lo zunsna cimei poi `CLL 3.7` cu to'e curmi ke'a
  let (a, b) = (before[^1], after[0])
  if not (a.isConsonant and b.isConsonant): return Hyphen.None
  # lo javni poi `CLL 4.11` na cusku ke'a
  #   .i le krasi pinka cu skicu le javni
  let is_triple_forbidden = after[1].isConsonant and
      not isTriplePermissible(a, b, after[1])
  if not isPairPermissible(a, b) or is_triple_forbidden: Hyphen.Y else: Hyphen.None


func isRunOpen(first: string): bool {.used.} =  # se pilno ne'i `tanru.nim` .e `test_lujvo.nim`
  ## jdice lo du'u xu kau le krasi porsi poi `step 5` pe `CLL 4.11` cu cipra fi ke'a cu kalri ba lo
  ##   nu tcidu le pamoi rafsi
  ##   .i go le porsi cu kalri gi le pamoi rafsi cu se tarmi la'o gy. CVC .gy.
  first.form.get == Form.Cvc


func carryRun(
  is_open: bool; before, after: string; hyphen: Hyphen; at, count: int
): tuple[is_open, is_breaking: bool] =
  ## bevri `step 5` pe `CLL 4.11` fu lo te jorne po'u `at` noi `step 4a` bi'o `step 4c` cu pu jdice
  ##   fi lo lerfu jorne pe ke'a
  ##   .i dunda lo du'u xu kau le krasi porsi cu stali lo ka kalri kei .e lo du'u xu kau `step 5` cu
  ##     punji `y` lo pamoi te jorne ca lo nu tcidu le te jorne
  ##   .i `step 5a` cu tcidu lo jorne remei pe le porsi pu lo pamoi be lo lerfu po'u `y`
  ##   .i le porsi cu stali lo ka kalri ca lo nu ro rafsi cu se tarmi la'o gy. CVC .gy. gi'e lidne
  ##     no lerfu jorne
  ##   .i `step 5b` cu nitcu lo nu ro jorne remei cu ka'e krasi lo valsi
  ##   .i se ki'u bo le porsi cu ganlo bu'u lo pamoi jorne remei poi na ka'e krasi lo valsi
  ##   .i va'o lo nu ro jorne remei cu ka'e krasi lo valsi kei le valsi cu se fendi ki'u lo nu `y`
  ##     cu se lidne le porsi to `step 5b` toi .a lo nu le romoi rafsi cu se tarmi la'o gy. CVCCV
  ##     .gy. gi'e vasru lo zunsna remei poi ka'e krasi lo valsi
  ##   .i `step 5c` cu punji `y` lo pamoi te jorne
  if not is_open: return (false, false)
  if hyphen == Hyphen.Y: return (false, true)
  let is_initial = hyphen == Hyphen.None and isPairInitial(before[^1], after[0])
  if after.form.get == Form.Cvc: return (is_initial, false)
  let is_gismu_breaking = at + 1 == count - 1 and after.form.get == Form.Cvccv and
      isPairInitial(after[2], after[3])
  (false, is_initial and is_gismu_breaking)


func hyphensRafsi*(rafsi: openArray[string]): seq[Hyphen] =
  ## jdice fi lo lerfu jorne poi lo rafsi poi na romoi cu lidne ke'a ku'o ja'i `step 4` .e `step 5`
  ##   vu'o pe `CLL 4.11`
  ##   .i lo rafsi cu bilga lo nu mapti lo stuzi poi `step 1` .e `step 2` cu curmi ke'a
  ##   .i `joinRafsi` cu xusra di'u
  let count = rafsi.len
  result = newSeq[Hyphen](count)

  # ja'i `step 4a` bi'o `step 4c` lo lerfu jorne pe ro te jorne cu se tcidu fi le re rafsi poi jibni
  #   le te jorne
  for at in 0 ..< count - 1: result[at] = hyphenJunction(rafsi[at], rafsi[at+1], at, count)

  # ja'i `step 5` lo cipra pe `tosmabru` cu tcidu le krasi porsi be lo rafsi poi se tarmi la'o gy.
  #   CVC .gy.
  #   .i le cipra cu tcidu ro te jorne ta'i lo nu sepli
  var is_open = rafsi[0].isRunOpen
  for at in 0 ..< count - 1:
    if not is_open: return
    let carried = carryRun(is_open, rafsi[at], rafsi[at+1], result[at], at, count)
    if carried.is_breaking: result[0] = Hyphen.Y  # ja'i `step 5c` `y` cu zvati lo pamoi te jorne
    is_open = carried.is_open


func joinRafsi*(rafsi: openArray[string]): string =
  ## jmina lo rafsi fo lo lujvo sepi'o lo lerfu jorne poi `CLL 4.11` cu nitcu ke'a ku'o ja'i
  ##   `step 3` bi'o `step 5`
  ##   .i ro rafsi cu bilga lo nu ponse lo tarmi to `forms.nim` toi gi'e mapti lo stuzi poi `step 1`
  ##     .e `step 2` vu'o pe `CLL 4.11` cu curmi ke'a
  assert rafsi.allIt(it.form.isSome) and isPositionValid(rafsi.mapIt(it.form.get)),
    "Rafsi should fill positions of 4.11 steps 1 and 2; got `" & rafsi.join(" ") & "`."
  let hyphens = hyphensRafsi(rafsi)
  for i, one in rafsi:
    result.add one
    result.add LUT_LETTER_BY_HYPHEN[hyphens[i]]



#[ ni'o ni'o ni'o lo nu dunda lo namcu ]#

func scoreRafsi(rafsi: string, form: Form): int {.used.} =  # se pilno ne'i `tanru.nim` .e lo cipra
  ## dunda lo pagbu be lo namcu pe `CLL 4.12` be'o poi lo rafsi poi se tarmi `form` cu jmina ke'a
  ##   .i le pagbu cu du `1000 L − 500 A − 10 R − V`
  ##   .i lo lerfu jorne cu na se kancu
  let value = (if '\'' in rafsi: 6 else: LUT_VALUE_BY_FORM[form])
  1000 * rafsi.len - 500 * rafsi.count('\'') - 10 * value - rafsi.countIt(it.isVowel)


func scoreHyphen(hyphen: Hyphen): int =
  ## dunda lo pagbu be lo namcu pe `CLL 4.12` be'o poi pa lerfu jorne cu jmina ke'a
  ##   .i le pagbu cu du `1000 L + 100 H`
  1000 * LUT_LETTER_BY_HYPHEN[hyphen].len + (if hyphen == Hyphen.None: 0 else: 100)


func scoreJunction(
  is_open: bool; before, after: string; at, count: int
): tuple[score: int, is_open: bool] {.used.} =  # se pilno ne'i `tanru.nim` .e lo cipra
  ## dunda lo pagbu be lo namcu pe `CLL 4.12` be'o poi lo te jorne po'u `at` cu jmina ke'a
  ##   .i le te jorne cu zvati lo jbini be `before` jo'u `after`
  ##   .i `count` cu te kancu lo rafsi
  ##   .i ji'a dunda lo du'u xu kau le krasi porsi cu stali lo ka kalri ba le te jorne to `step 5`
  ##     pe `CLL 4.11` toi
  ##   .i va'o lo nu `step 5` cu punji `y` lo pamoi te jorne kei le namcu cu ralte lo pagbu pe `y`
  ##     bu'u le te jorne po'u `at`
  ##   .i le te jorne cu pamoi
  ##   .i ja le pamoi te jorne cu se dunda lo namcu pe `None` ki'u lo nu lo kalri porsi cu vasru no
  ##     lerfu jorne
  let
    hyphen = hyphenJunction(before, after, at, count)
    carried = carryRun(is_open, before, after, hyphen, at, count)
    # lo lerfu jorne pe le pamoi te jorne pu lo nu `step 5` cu se pilno
    hyphen_first = (if at == 0: hyphen else: Hyphen.None)
    added = (if carried.is_breaking: scoreHyphen(Hyphen.Y) - scoreHyphen(hyphen_first) else: 0)
  (scoreHyphen(hyphen) + added, carried.is_open)


func score*(pieces: openArray[Piece]): int =
  ## dunda lo namcu lo lujvo poi `pieces` cu ciska ke'a
  ##   .i le namcu cu du `1000 L − 500 A + 100 H − 10 R − V` pe `CLL 4.12`
  ##   .i lo tarmi poi lo namcu pe ke'a cu traji lo ka cmalu ku'o cu se nelci lo vlaste
  ##   .i va'o lo nu su'o re tarmi cu ponse lo mintu namcu kei `CLL 4.12` cu nelci no le tarmi
  ##   .i le namcu cu sumji lo pagbu pe ro rafsi lo pagbu pe ro lerfu jorne ki'u lo nu `CLL 4.12` cu
  ##     kancu ro pagbu ta'i lo nu sepli
  for piece in pieces: result += scoreRafsi(piece.rafsi, piece.form) + piece.hyphen.scoreHyphen


func toPieces*(rafsi: openArray[string]): seq[Piece] =
  ## ciska lo rafsi ta'i lo me `Piece` poi vasru lo lerfu jorne poi `joinRafsi` cu punji ke'a
  let hyphens = hyphensRafsi(rafsi)
  for i, one in rafsi: result.add Piece(rafsi: one, form: one.form.get, hyphen: hyphens[i])



#[ ni'o ni'o ni'o lo nu fendi ]#

func segmentations(word: string, at: int, so_far: seq[Piece]): seq[seq[Piece]] =
  ## jmina lo rafsi lo te fendi bu'u lo stuzi po'u `at` ta'i ro tadji poi lo tarmi cu curmi ke'a
  ##   .i lo lerfu jorne cu pu'o te jdice
  if at == word.len:
    if so_far.len >= 2 and so_far[^1].form in FORMS_FINAL: result.add so_far
    return
  for length in 3 .. 5:
    if at + length > word.len: break
    let shape = word[at ..< at + length].form
    if shape.isNone: continue
    let next = at + length
    var piece = Piece(rafsi: word[at ..< next], form: shape.get)
    case piece.form
    of Form.Cvccv, Form.Ccvcv:
      if next == word.len: result.add segmentations(word, next, so_far & piece)
    of Form.Cvcc, Form.Ccvc:
      if next < word.len and word[next] == 'y':
        piece.hyphen = Hyphen.Y
        result.add segmentations(word, next + 1, so_far & piece)
    of Form.Cvc, Form.Ccv, Form.Cvv:
      result.add segmentations(word, next, so_far & piece)
      if next < word.len and word[next] == 'y' and piece.form == Form.Cvc:
        piece.hyphen = Hyphen.Y
        result.add segmentations(word, next + 1, so_far & piece)
      if next < word.len and word[next] in {'r', 'n'} and piece.form == Form.Cvv and
          so_far.len == 0:
        piece.hyphen = (if word[next] == 'r': Hyphen.R else: Hyphen.N)
        result.add segmentations(word, next + 1, so_far & piece)


func segmentLujvo*(word: string): seq[seq[Piece]] =
  ## fendi lo valsi fi lo rafsi ja'i lo tarmi .e lo stuzi gi'e na pilno lo drata
  ##   .i lo lerfu jorne cu stali ta'i lo nu se ciska
  ##   .i le nu fendi cu jdice fi no lerfu jorne
  ##   .i le tcidu cu pilno le fancu va'o lo nu `splitLujvo` cu facki no da kei mu'i lo nu cusku lo
  ##     tarmi poi `CLL 4.11` cu dunda ke'a
  for candidate in segmentations(word, 0, @[]):
    if isPositionValid(candidate.mapIt(it.form)): result.add candidate


func splitLujvo*(word: string): seq[seq[Piece]] =
  ## fendi lo valsi fi ro porsi be lo rafsi be'o poi `joinRafsi` cu jmina ke'a fo le valsi ta'i lo
  ##   nu satci
  ##   .i lo jalge cu kunti va'o lo nu no porsi cu mapti
  ##   .i lo nu le valsi cu na lujvo .a lo nu le valsi cu vasru lo lerfu jorne poi `CLL 4.11` na
  ##     nitcu ke'a cu rinka la'e di'u
  ##   .i lo rafsi cu te jdice ja'i lo tarmi po'o
  ##   .i lo pilno cu retsku lo du'u ro rafsi cu sinxa ma kau poi valsi kei lo vlaste
  for candidate in segmentLujvo(word):
    if joinRafsi(candidate.mapIt(it.rafsi)) == word: result.add candidate
