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
##   | splitLujvo        | inverse of `joinRafsi`                         | 4.5, 4.11      |
##   |-------------------|------------------------------------------------|----------------|
##
##   Split admits segmentation only where `joinRafsi` gives input back letter for letter, so
##     split then join is identity by construction. 4.11 forbids hyphen algorithm does not
##     require, so comparing with algorithm's own output is whole test of hyphens.
##     Rejected: checking each junction by local rule, which would restate algorithm twice.
##   Join follows 4.11 in right-to-left order that step 5 asks: steps 4a to 4c settle every
##     junction before tosmabru test reads them.
##   Forbidden triples: 4.11 step 4b names impermissible pairs alone, and CLL is silent on
##     junction forming `ndj`, `ndz`, `ntc` or `nts`, which 3.7 forbids medially. Join puts
##     `y` there too, so no lujvo it makes breaks 3.7.
##     Cost: one more rule than 4.11 states; `test_lujvo.nim` names convention where it bites.
##   Split asks no dictionary: candidate rafsi are judged by form alone (`forms.nim`), and
##     caller looks each up; morphology and vocabulary stay separable.
##   Cost: split tries every segmentation by recursion; lujvo of `n` rafsi has at most few
##     candidates per position, and words are short, so cost is small (unmeasured).
##   Cost model unread: no hot path; split and join run once per word read by shell tool.

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


func hyphensRafsi*(rafsi: openArray[string]): seq[Hyphen] =
  ## Settle hyphen after each rafsi but last, by steps 4 and 5 of 4.11.
  ##   Rafsi must fill positions steps 1 and 2 allow; `joinRafsi` asserts it.
  let
    count = rafsi.len
    forms = rafsi.mapIt(it.form.get)
  result = newSeq[Hyphen](count)

  # Step 4a: CVV first takes `r`, or `n` before `r`, unless two rafsi end in CCV.
  if forms[0] == Form.Cvv and (count > 2 or forms[1] != Form.Ccv):
    result[0] = (if rafsi[1][0] == 'r': Hyphen.N else: Hyphen.R)

  # Step 4b: `y` between consonants of impermissible pair; forbidden triple too (3.7).
  for i in 0 ..< count - 1:
    let (a, b) = (rafsi[i][^1], rafsi[i + 1][0])
    if result[i] != Hyphen.None or not (a.isConsonant and b.isConsonant): continue
    let is_triple_forbidden = rafsi[i + 1][1].isConsonant and
        not isTriplePermissible(a, b, rafsi[i + 1][1])  # Convention beyond 4.11; see header.
    if not isPairPermissible(a, b) or is_triple_forbidden: result[i] = Hyphen.Y

  # Step 4c: `y` after every 4-letter rafsi.
  for i in 0 ..< count - 1:
    if forms[i] in FORMS_UNREDUCED: result[i] = Hyphen.Y

  # Step 5: tosmabru test over leading run of CVC rafsi joined with no hyphen, then `X`.
  var length_run = 0
  while length_run < count - 1 and forms[length_run] == Form.Cvc and
      (length_run == 0 or result[length_run - 1] == Hyphen.None):
    inc length_run
  if length_run == 0: return
  let
    x = rafsi[length_run]
    is_attached_y = result[length_run - 1] == Hyphen.Y
    is_gismu_breaking = length_run == count - 1 and forms[length_run] == Form.Cvccv and
        isPairInitial(x[2], x[3])
  if not (is_attached_y or is_gismu_breaking): return
  var is_initial_all = true  # Step 5a: joints up to first `y`, or to end where none.
  for j in 0 ..< length_run - 1:
    is_initial_all = is_initial_all and isPairInitial(rafsi[j][^1], rafsi[j + 1][0])
  if not is_attached_y:
    is_initial_all = is_initial_all and isPairInitial(rafsi[length_run - 1][^1], x[0]) and
        isPairInitial(x[2], x[3])
  if is_initial_all: result[0] = Hyphen.Y  # Step 5c: `y` at first joint.


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

func score*(pieces: openArray[Piece]): int =
  ## Score lujvo spelled by pieces, i.e. `1000 L − 500 A + 100 H − 10 R − V` of 4.12.
  ##   Lowest score is form dictionary prefers; ties have no preference in 4.12.
  var (letters, apostrophes, hyphens, values, vowels) = (0, 0, 0, 0, 0)
  for piece in pieces:
    let spelled = piece.rafsi & LUT_LETTER_BY_HYPHEN[piece.hyphen]
    letters += spelled.len
    apostrophes += piece.rafsi.count('\'')
    hyphens += (if piece.hyphen == Hyphen.None: 0 else: 1)
    values += (if '\'' in piece.rafsi: 6 else: LUT_VALUE_BY_FORM[piece.form])
    vowels += piece.rafsi.countIt(it.isVowel)
  1000 * letters - 500 * apostrophes + 100 * hyphens - 10 * values - vowels


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
