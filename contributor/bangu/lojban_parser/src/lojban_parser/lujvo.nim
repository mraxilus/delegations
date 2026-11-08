## Join rafsi into lujvo, score lujvo, and split lujvo back into rafsi, as CLL 4.11 and 4.12 do.
##
##   |-------------------|------------------------------------------------|----------------|
##   | Code              | CLL                                            | Section        |
##   |-------------------|------------------------------------------------|----------------|
##   | Hyphen.Y          | `y`-hyphen                                     | 4.6, 4.11      |
##   | Hyphen.R          | `r`-hyphen                                     | 4.6, 4.11 (4a) |
##   | Hyphen.N          | `n`-hyphen, before rafsi starting `r` alone    | 4.6, 4.11 (4a) |
##   | joinRafsi         | lujvo-making algorithm, steps 3 to 5           | 4.11           |
##   | hyphensRafsi      | hyphen letters steps 4 and 5 install           | 4.11           |
##   | score             | lujvo scoring algorithm, lowest preferred      | 4.12           |
##   | scoreRafsi        | part of score one rafsi adds                   | 4.12           |
##   | scoreJunction     | part one junction adds, step 5 included        | 4.11, 4.12     |
##   | isRunOpen         | first rafsi opens run step 5 tests             | 4.11 (5)       |
##   | splitLujvo        | inverse of `joinRafsi`                         | 4.5, 4.11      |
##   |-------------------|------------------------------------------------|----------------|
##
##   Split admits segmentation only where `joinRafsi` gives input back letter for letter, so
##     split then join is identity by construction. 4.11 forbids hyphen algorithm does not
##     require, so comparing with algorithm's own output is whole test of hyphens.
##     Rejected: checking each junction by local rule, which would restate algorithm twice.
##   Join follows 4.11 in right-to-left order that step 5 asks: steps 4a to 4c settle every
##     junction before tosmabru test reads them.
##   Each junction is settled by two rafsi beside it (`hyphenJunction`), and tosmabru test reads
##     junctions left to right with one flag, whether leading run is open (`carryRun`). So
##     score sums over rafsi and junctions, and render of tanru searches position by position.
##     Cost: step 5 is read junction by junction, never as whole run, so `test_lujvo.nim` holds
##       score of each lujvo to its sum over junctions.
##   Parts of score and of step 5 stay private: `tanru.nim` and `test_lujvo.nim` reach them by
##     import of all symbols, so surface umbrella exports stays as it was (#832).
##   Forbidden triples: 4.11 step 4b names impermissible pairs alone, and CLL is silent on
##     junction forming `ndj`, `ndz`, `ntc` or `nts`, which 3.7 forbids medially. Join puts
##     `y` there too, so no lujvo it makes breaks 3.7.
##     Cost: one more rule than 4.11 states; `test_lujvo.nim` names convention where it bites.
##   Split asks no dictionary: candidate rafsi are judged by form alone (`forms.nim`), and
##     caller looks each up; morphology and vocabulary stay separable.
##   Cost: split tries every segmentation by recursion; lujvo of `n` rafsi has at most few
##     candidates per position, and words are short, so cost is small (unmeasured).
##   Cost model unread: no hot path; split and join run once for each word reader reads.

{.experimental: "strictFuncs".}

import std/[options, sequtils, strutils]

import ./[clusters, forms]


type
  Hyphen* {.pure.} = enum  ## Define hyphen letter joined after rafsi (4.6).
    None, Y, R, N

  Piece* = object  ## Define one rafsi of lujvo as spelled, with hyphen that follows it.
    rafsi*: string  ## Rafsi letters, apostrophe included.
    form*: Form  ## Shape of rafsi (`forms.nim`).
    hyphen*: Hyphen  ## Hyphen after rafsi; `None` after last.


const
  LUT_LETTER_BY_HYPHEN*: array[Hyphen, string] = ["", "y", "r", "n"]
    ## Letters each hyphen writes.
  LUT_VALUE_BY_FORM: array[Form, int] = [
    Form.Cvc: 5,
    Form.Ccv: 7,
    Form.Cvv: 8,
    Form.Cvcc: 2,
    Form.Ccvc: 4,
    Form.Cvccv: 1,
    Form.Ccvcv: 3,
  ]
    ## Value step 4 of 4.12 gives each form; CVV with apostrophe takes 6 instead.



#[ Joining ]#

func isPositionValid(forms: openArray[Form]): bool =
  ## Test forms fill positions 4.11 steps 1 and 2 allow: at least two rafsi, short or 4-letter
  ##   before last, and CVV, CCV or 5-letter last.
  if forms.len < 2 or forms[^1] notin FORMS_FINAL: return false
  for one in forms[0 .. ^2]:
    if one notin FORMS_SHORT + FORMS_UNREDUCED: return false
  true


func hyphenJunction(before, after: string; at, count: int): Hyphen =
  ## Settle hyphen after rafsi `before` at index `at` of `count`, `after` next, by steps 4a to 4c
  ##   of 4.11; step 5 may yet put `y` at first junction (`carryRun`).
  let form_before = before.form.get

  # Step 4a: CVV first takes `r`, or `n` before `r`, unless two rafsi end in CCV.
  if at == 0 and form_before == Form.Cvv and (count > 2 or after.form.get != Form.Ccv):
    return (if after[0] == 'r': Hyphen.N else: Hyphen.R)

  # Step 4c: `y` after every 4-letter rafsi, whatever pair follows.
  if form_before in FORMS_UNREDUCED: return Hyphen.Y

  # Step 4b: `y` between consonants of impermissible pair; forbidden triple too (3.7).
  let (a, b) = (before[^1], after[0])
  if not (a.isConsonant and b.isConsonant): return Hyphen.None
  let is_triple_forbidden = after[1].isConsonant and
      not isTriplePermissible(a, b, after[1])  # Convention beyond 4.11; see header.
  if not isPairPermissible(a, b) or is_triple_forbidden: Hyphen.Y else: Hyphen.None


func isRunOpen(first: string): bool {.used.} =  # Used in `tanru.nim` and `test_lujvo.nim`.
  ## Test leading run step 5 of 4.11 tests is open after first rafsi: CVC alone opens it.
  first.form.get == Form.Cvc


func carryRun(
  is_open: bool; before, after: string; hyphen: Hyphen; at, count: int
): tuple[is_open, is_breaking: bool] =
  ## Carry step 5 of 4.11 across junction `at`, whose hyphen steps 4a to 4c settled: whether
  ##   leading run stays open, and whether step 5 puts `y` at first junction here.
  ##   Joints step 5a reads run up to first `y`: run stays open while each rafsi is CVC joined
  ##     with no hyphen, and closes at first joint no initial pair makes, which 5b needs.
  ##   Where each joint is initial pair, `y` after run breaks word (5b), and so does last rafsi
  ##     of form CVCCV whose last two consonants make initial pair; 5c puts `y` at first junction.
  if not is_open: return (false, false)
  if hyphen == Hyphen.Y: return (false, true)
  let is_initial = hyphen == Hyphen.None and isPairInitial(before[^1], after[0])
  if after.form.get == Form.Cvc: return (is_initial, false)
  let is_gismu_breaking = at + 1 == count - 1 and after.form.get == Form.Cvccv and
      isPairInitial(after[2], after[3])
  (false, is_initial and is_gismu_breaking)


func hyphensRafsi*(rafsi: openArray[string]): seq[Hyphen] =
  ## Settle hyphen after each rafsi but last, by steps 4 and 5 of 4.11.
  ##   Rafsi must fill positions steps 1 and 2 allow; `joinRafsi` asserts it.
  let count = rafsi.len
  result = newSeq[Hyphen](count)

  # Steps 4a to 4c: hyphen of each junction, read from two rafsi beside it.
  for at in 0 ..< count - 1: result[at] = hyphenJunction(rafsi[at], rafsi[at+1], at, count)

  # Step 5: tosmabru test over leading run of CVC rafsi, junction by junction.
  var is_open = rafsi[0].isRunOpen
  for at in 0 ..< count - 1:
    if not is_open: return
    let carried = carryRun(is_open, rafsi[at], rafsi[at+1], result[at], at, count)
    if carried.is_breaking: result[0] = Hyphen.Y  # Step 5c: `y` at first junction.
    is_open = carried.is_open


func joinRafsi*(rafsi: openArray[string]): string =
  ## Join rafsi into lujvo with hyphens 4.11 requires, i.e. steps 3 to 5.
  ##   Each rafsi must have form (`forms.nim`) and fill position 4.11 steps 1 and 2 allow.
  assert rafsi.allIt(it.form.isSome) and isPositionValid(rafsi.mapIt(it.form.get)),
    "Rafsi should fill positions of 4.11 steps 1 and 2; got `" & rafsi.join(" ") & "`."
  let hyphens = hyphensRafsi(rafsi)
  for i, one in rafsi:
    result.add one
    result.add LUT_LETTER_BY_HYPHEN[hyphens[i]]



#[ Scoring ]#

func scoreRafsi(rafsi: string, form: Form): int {.used.} =  # Used in `tanru.nim`, `test_lujvo.nim`.
  ## Score part of 4.12 rafsi of `form` adds, i.e. `1000 L − 500 A − 10 R − V`; hyphen aside.
  let value = (if '\'' in rafsi: 6 else: LUT_VALUE_BY_FORM[form])
  1000 * rafsi.len - 500 * rafsi.count('\'') - 10 * value - rafsi.countIt(it.isVowel)


func scoreHyphen(hyphen: Hyphen): int =
  ## Score part of 4.12 one hyphen adds, i.e. `1000 L + 100 H`.
  1000 * LUT_LETTER_BY_HYPHEN[hyphen].len + (if hyphen == Hyphen.None: 0 else: 100)


func scoreJunction(
  is_open: bool; before, after: string; at, count: int
): tuple[score: int, is_open: bool] {.used.} =  # Used in `tanru.nim` and `test_lujvo.nim`.
  ## Score part of 4.12 junction `at` adds, between rafsi `before` and `after` of `count`, and
  ##   tell whether leading run stays open past it (4.11 step 5).
  ##   Where step 5 puts `y` at first junction, score holds it here: junction `at` is first, or
  ##     first junction scored no hyphen, since open run holds none.
  let
    hyphen = hyphenJunction(before, after, at, count)
    carried = carryRun(is_open, before, after, hyphen, at, count)
    hyphen_first = (if at == 0: hyphen else: Hyphen.None)  # Hyphen there before step 5.
    added = (if carried.is_breaking: scoreHyphen(Hyphen.Y) - scoreHyphen(hyphen_first) else: 0)
  (scoreHyphen(hyphen) + added, carried.is_open)


func score*(pieces: openArray[Piece]): int =
  ## Score lujvo spelled by pieces, i.e. `1000 L − 500 A + 100 H − 10 R − V` of 4.12.
  ##   Lowest score is form dictionary prefers; ties have no preference in 4.12.
  ##   Sum of part each rafsi adds and part each hyphen adds, since 4.12 counts each alone.
  for piece in pieces: result += scoreRafsi(piece.rafsi, piece.form) + piece.hyphen.scoreHyphen


func toPieces*(rafsi: openArray[string]): seq[Piece] =
  ## Spell rafsi as pieces with hyphens `joinRafsi` installs.
  let hyphens = hyphensRafsi(rafsi)
  for i, one in rafsi: result.add Piece(rafsi: one, form: one.form.get, hyphen: hyphens[i])



#[ Splitting ]#

func segmentations(word: string, at: int, so_far: seq[Piece]): seq[seq[Piece]] =
  ## Extend segmentation from letter `at` in every way forms allow; hyphens unjudged yet.
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
  ## Segment word into rafsi by form and position alone, hyphens as written, never judged.
  ##   Reader takes it where `splitLujvo` finds nothing, to name form 4.11 would give.
  for candidate in segmentations(word, 0, @[]):
    if isPositionValid(candidate.mapIt(it.form)): result.add candidate


func splitLujvo*(word: string): seq[seq[Piece]] =
  ## Split word into every rafsi sequence that `joinRafsi` joins back into word exactly.
  ##   Empty where none does: word is no lujvo, or carries hyphen 4.11 does not require.
  ##   Rafsi are judged by form alone; caller asks dictionary which word each one names.
  for candidate in segmentLujvo(word):
    if joinRafsi(candidate.mapIt(it.rafsi)) == word: result.add candidate
