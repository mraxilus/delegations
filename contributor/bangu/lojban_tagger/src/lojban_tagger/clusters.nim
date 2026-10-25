## Classify Lojban letters and judge consonant clusters, as CLL chapter 3 defines them.
##
##   |--------------------------|--------------------------------------------|---------|
##   | Code                     | CLL                                        | Section |
##   |--------------------------|--------------------------------------------|---------|
##   | VOWELS                   | `a e i o u`, vowels outside `y`            | 3.1     |
##   | CONSONANTS               | seventeen consonants, apostrophe excluded  | 3.6     |
##   | CONSONANTS_VOICED        | voiced column of voicing table             | 3.6     |
##   | CONSONANTS_UNVOICED      | unvoiced column of voicing table           | 3.6     |
##   | CONSONANTS_SIBILANT      | set "c", "j", "s", "z" of rule 3           | 3.6     |
##   | PAIRS_FORBIDDEN          | "cx", "kx", "xc", "xk", "mz" of rule 4     | 3.6     |
##   | isPairPermissible        | permissible consonant pair, C/C            | 3.6     |
##   | PAIRS_INITIAL            | 48 permissible initial pairs, CC           | 3.7     |
##   | isPairInitial            | permissible initial consonant pair         | 3.7     |
##   | TRIPLES_FORBIDDEN        | "ndj", "ndz", "ntc", "nts"                 | 3.7     |
##   | isTriplePermissible      | medial consonant triple                    | 3.7     |
##   |--------------------------|--------------------------------------------|---------|
##
##   Rules are data, judgements derived: four rules of 3.6 build pair table at compile time,
##     so table cannot drift from rules; initial pairs are list CLL gives, since no rule
##     derives them.
##   Letters stay `char`, and tables index `'a' .. 'z'`; no distinct letter type, since every
##     caller already holds text and wrapper would prevent no realistic mistake (IV.2).
##   Cost: judgement of letter outside `'a' .. 'z'` is false by guard, never by table, so each
##     predicate pays one set test before lookup.

{.experimental: "strictFuncs".}


type
  PairsJudged = array['a' .. 'z', array['a' .. 'z', bool]]  ## Define judgement of each letter pair.


const
  VOWELS* = {'a', 'e', 'i', 'o', 'u'}  ## Vowels that make syllable, `y` aside (3.1).
  CONSONANTS* = {
    'b', 'c', 'd', 'f', 'g', 'j', 'k', 'l', 'm', 'n', 'p', 'r', 's', 't', 'v', 'x', 'z'
  }
    ## Seventeen consonants of 3.6; apostrophe is no consonant there.
  CONSONANTS_VOICED* = {'b', 'd', 'g', 'j', 'v', 'z'}  ## Voiced column of 3.6 table.
  CONSONANTS_UNVOICED* = {'c', 'f', 'k', 'p', 's', 't', 'x'}  ## Unvoiced column of 3.6 table.
  CONSONANTS_SIBILANT* = {'c', 'j', 's', 'z'}  ## Set no pair may draw both members from (rule 3).
  PAIRS_FORBIDDEN* = ["cx", "kx", "xc", "xk", "mz"]  ## Pairs rule 4 of 3.6 names one by one.
  PAIRS_INITIAL* = [
    "bl", "br",
    "cf", "ck", "cl", "cm", "cn", "cp", "cr", "ct",
    "dj", "dr", "dz",
    "fl", "fr",
    "gl", "gr",
    "jb", "jd", "jg", "jm", "jv",
    "kl", "kr",
    "ml", "mr",
    "pl", "pr",
    "sf", "sk", "sl", "sm", "sn", "sp", "sr", "st",
    "tc", "tr", "ts",
    "vl", "vr",
    "xl", "xr",
    "zb", "zd", "zg", "zm", "zv",
  ]
    ## Pairs that may begin word, as 3.7 lists them, one line per first consonant.
  TRIPLES_FORBIDDEN* = ["ndj", "ndz", "ntc", "nts"]  ## Triples 3.7 forbids by name.

  LUT_PERMISSIBLE_BY_PAIR = block:
    ## Judge every consonant pair by four rules of 3.6; pairs outside consonants stay false.
    var lut: PairsJudged
    for a in CONSONANTS:
      for b in CONSONANTS:
        let
          is_doubled = a == b  # Rule 1.
          is_voicing_mixed =  # Rule 2; `l`, `m`, `n`, `r` exempt by belonging to neither set.
              (a in CONSONANTS_VOICED and b in CONSONANTS_UNVOICED) or
              (a in CONSONANTS_UNVOICED and b in CONSONANTS_VOICED)
          is_sibilant_both = a in CONSONANTS_SIBILANT and b in CONSONANTS_SIBILANT  # Rule 3.
          is_named = a & b in PAIRS_FORBIDDEN  # Rule 4.
        lut[a][b] = not (is_doubled or is_voicing_mixed or is_sibilant_both or is_named)
    lut
  LUT_INITIAL_BY_PAIR = block:
    ## Judge every pair against list of 3.7.
    var lut: PairsJudged
    for pair in PAIRS_INITIAL: lut[pair[0]][pair[1]] = true
    lut

static:
  # Every initial pair is permissible pair, so 3.7 list never contradicts 3.6 rules.
  for pair in PAIRS_INITIAL:
    doAssert LUT_PERMISSIBLE_BY_PAIR[pair[0]][pair[1]],
      "Initial pair should be permissible pair (CLL 3.6, 3.7); got `" & pair & "`."
  doAssert PAIRS_INITIAL.len == 48, "CLL 3.7 lists 48 initial pairs; got `" &
      $PAIRS_INITIAL.len & "`."



#[ Letters ]#

func isVowel*(c: char): bool {.inline.} = c in VOWELS
  ## Test letter is vowel of 3.1, `y` excluded.

func isConsonant*(c: char): bool {.inline.} = c in CONSONANTS
  ## Test letter is one of seventeen consonants of 3.6.



#[ Clusters ]#

func isPairPermissible*(a, b: char): bool =
  ## Test consonants `a` then `b` form permissible pair, i.e. C/C of 3.6.
  a in CONSONANTS and b in CONSONANTS and LUT_PERMISSIBLE_BY_PAIR[a][b]

func isPairInitial*(a, b: char): bool =
  ## Test consonants `a` then `b` form permissible initial pair, i.e. CC of 3.7.
  a in CONSONANTS and b in CONSONANTS and LUT_INITIAL_BY_PAIR[a][b]

func isTriplePermissible*(a, b, c: char): bool =
  ## Test consonants form medial triple 3.7 permits.
  ##   First two permissible pair, last two initial pair, and triple not one of four named.
  isPairPermissible(a, b) and isPairInitial(b, c) and a & b & c notin TRIPLES_FORBIDDEN
