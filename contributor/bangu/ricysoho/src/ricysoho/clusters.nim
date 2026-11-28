## ja'i `CLL 3` jdice lo klesi pe ro lerfu be la lojban. gi'e jdice lo du'u lo zunsna gunma cu
##     selcru
##
##   |-----------------------|--------------------------------------------------------|-----------|
##   | lo samtci cmene       | `CLL`                                                  | lo pagbu  |
##   |-----------------------|--------------------------------------------------------|-----------|
##   | `VOWELS`              | lo karsna po'u `a e i o u` noi na vasru `y`            | `CLL 3.1` |
##   | `CONSONANTS`          | le 17 zunsna noi na vasru zoi gy. ' .gy.             | `CLL 3.6` |
##   | `CONSONANTS_VOICED`   | lo voksa zunsna pe le vokste                      | `CLL 3.6` |
##   | `CONSONANTS_UNVOICED` | lo na'e voksa zunsna pe le vokste                 | `CLL 3.6` |
##   | `CONSONANTS_SIBILANT` | lo selcmi po'u `c, j, s, z` pe le cimoi javni          | `CLL 3.6` |
##   | `PAIRS_FORBIDDEN`     | `cx kx xc xk mz` pe le vomoi javni                     | `CLL 3.6` |
##   | `isPairPermissible`   | lo zunsna remei poi selcru gi'e selsni `C/C`       | `CLL 3.6` |
##   | `PAIRS_INITIAL`       | `CC` noi sinxa le 48 zunsna remei poi krasi lo valsi | `CLL 3.7` |
##   | `isPairInitial`       | lo zunsna remei poi ka'e krasi lo valsi                | `CLL 3.7` |
##   | `TRIPLES_FORBIDDEN`   | `ndj ndz ntc nts`                                      | `CLL 3.7` |
##   | `isTriplePermissible` | lo midju zunsna cimei                                  | `CLL 3.7` |
##   |-----------------------|--------------------------------------------------------|-----------|
##
## ni'o le samtci cu ralte lo javni ta'i lo datni
##   .i ro seljdi cu selkra le javni
##   .i le vo javni pe `CLL 3.6` zbasu lo liste be lo zunsna remei ca lo nu fanva
##   .i se ki'u bo le liste na ka'e frica le javni
##   .i lo zunsna remei poi ka'e krasi lo valsi cu selci'a ta'i lo liste poi `CLL` dunda ke'a ki'u
##       lo nu no javni cu zbasu le zunsna remei
##
## ni'o lo lerfu cu stali lo ka selkle `char`
##   .i lo lerfu po'u `'a' .. 'z'` judri lo cmima be le liste
##   .i no lerlei cu selzba ki'u lo nu ro pilno cu ralte lo selci'a kei .e lo nu lo klesi poi vasru
##       lo lerfu cu fanta no srera poi ka'e fasnu to `Article IV.2` toi
##   .i jdima fa lo nu lo seljdi be fi lo lerfu poi na cmima `'a' .. 'z'` cu jitfa ki'u lo bandu
##       gi'e no roi jitfa ki'u le liste
##   .i se ki'u bo ro fancu poi jdice cu cipra lo du'u lo lerfu cu cmima lo selcmi kei pa roi pu lo
##       nu sisku ne'i le liste

{.experimental: "strictFuncs".}


type  # lo klesi pe lo seljdi be lo lerfu remei
  PairsJudged = array['a' .. 'z', array['a' .. 'z', bool]]  ## lo seljdi be fi ro lerfu remei


const  # lo selcmi be lo lerfu pe `CLL 3`
  VOWELS* = {'a', 'e', 'i', 'o', 'u'}
    ## lo karsna poi zbasu lo slaka
    ##   .i `y` na cmima to `CLL 3.1` toi
  CONSONANTS* = {
    'b', 'c', 'd', 'f', 'g', 'j', 'k', 'l', 'm', 'n', 'p', 'r', 's', 't', 'v', 'x', 'z'
  }
    ## le 17 zunsna pe `CLL 3.6`
    ##   .i ne'i `CLL 3.6` zoi gy. ' .gy. na zunsna
  CONSONANTS_VOICED* = {'b', 'd', 'g', 'j', 'v', 'z'}  ## lo voksa zunsna pe le liste pe `CLL 3.6`
  CONSONANTS_UNVOICED* = {'c', 'f', 'k', 'p', 's', 't', 'x'}
    ## lo na'e voksa zunsna pe le liste pe `CLL 3.6`
  CONSONANTS_SIBILANT* = {'c', 'j', 's', 'z'}
    ## lo selcmi poi no zunsna remei poi selcru cu vasru re cmima be ke'a to le cimoi javni toi
  PAIRS_FORBIDDEN* = ["cx", "kx", "xc", "xk", "mz"]
    ## lo zunsna remei poi le vomoi javni pe `CLL 3.6` liste ke'a
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
    ## lo zunsna remei poi ka'e krasi lo valsi
    ##   .i le liste cu simsa le liste pe `CLL 3.7`
    ##   .i ro linji cu vasru lo zunsna remei poi selkra pa zunsna
  TRIPLES_FORBIDDEN* = ["ndj", "ndz", "ntc", "nts"]
    ## lo zunsna cimei poi `CLL 3.7` cusku ke'a gi'e to'e curmi ke'a

  # jdice ro zunsna remei ja'i le vo javni pe `CLL 3.6`
  #   .i lo seljdi be fi ro lerfu remei poi na zunsna remei cu stali lo ka jitfa
  LUT_PERMISSIBLE_BY_PAIR = block:
    var lut: PairsJudged
    for a in CONSONANTS:
      for b in CONSONANTS:
        let
          is_doubled = a == b  # le pamoi javni
          # le remoi javni
          #   .i `l` .e `m` .e `n` .e `r` cmima no le re selcmi
          #   .i se ki'u bo le javni na srana le vo lerfu
          is_voicing_mixed =
              (a in CONSONANTS_VOICED and b in CONSONANTS_UNVOICED) or
              (a in CONSONANTS_UNVOICED and b in CONSONANTS_VOICED)
          is_sibilant_both = a in CONSONANTS_SIBILANT and b in CONSONANTS_SIBILANT  # le cimoi javni
          is_named = a & b in PAIRS_FORBIDDEN  # le vomoi javni
        lut[a][b] = not (is_doubled or is_voicing_mixed or is_sibilant_both or is_named)
    lut

  # jdice ro boi remei ja'i le liste pe `CLL 3.7`
  LUT_INITIAL_BY_PAIR = block:
    var lut: PairsJudged
    for pair in PAIRS_INITIAL: lut[pair[0]][pair[1]] = true
    lut

static:
  # ro zunsna remei poi ka'e krasi lo valsi cu selcru
  #   .i se ki'u bo le liste pe `CLL 3.7` no roi natfe le javni pe `CLL 3.6`
  for pair in PAIRS_INITIAL:
    doAssert LUT_PERMISSIBLE_BY_PAIR[pair[0]][pair[1]],
      "Initial pair should be permissible pair (CLL 3.6, 3.7); got `" & pair & "`."
  doAssert PAIRS_INITIAL.len == 48, "CLL 3.7 lists 48 initial pairs; got `" &
      $PAIRS_INITIAL.len & "`."



#[ ni'o ni'o ni'o lo lerfu ]#

func isVowel*(c: char): bool {.inline.} = c in VOWELS
  ## jdice lo du'u le lerfu cu karsna ja'i `CLL 3.1` gi'e na du `y`

func isConsonant*(c: char): bool {.inline.} = c in CONSONANTS
  ## jdice lo du'u le lerfu cu cmima le 17 zunsna pe `CLL 3.6`



#[ ni'o ni'o ni'o lo zunsna gunma ]#

func isPairPermissible*(a, b: char): bool =
  ## jdice lo du'u lo zunsna remei po'u `a` ce'o `b` selcru
  ##   .i le remei cu du `C/C` pe `CLL 3.6`
  a in CONSONANTS and b in CONSONANTS and LUT_PERMISSIBLE_BY_PAIR[a][b]

func isPairInitial*(a, b: char): bool =
  ## jdice lo du'u lo zunsna remei po'u `a` ce'o `b` cu ka'e krasi lo valsi
  ##   .i le remei cu du `CC` pe `CLL 3.7`
  a in CONSONANTS and b in CONSONANTS and LUT_INITIAL_BY_PAIR[a][b]

func isTriplePermissible*(a, b, c: char): bool =
  ## jdice lo du'u le zunsna cu zbasu lo midju zunsna cimei poi `CLL 3.7` curmi ke'a
  ##   .i le re zunsna poi krasi cu zbasu lo zunsna remei poi selcru
  ##   .i le re zunsna poi fanmo cu zbasu lo zunsna remei poi ka'e krasi lo valsi
  ##   .i le zunsna cimei cu du no le vo zunsna cimei poi `CLL 3.7` cusku ke'a
  isPairPermissible(a, b) and isPairInitial(b, c) and a & b & c notin TRIPLES_FORBIDDEN
