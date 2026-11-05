## Classify shapes of lojban words and rafsi, as CLL chapter 4 writes them in C and V.
##
##   |--------|----------|----------------------------------------------|-------------|
##   | Code   | CLL      | Meaning                                      | Section     |
##   |--------|----------|----------------------------------------------|-------------|
##   | Cvc    | CVC      | short rafsi, never final                     | 4.6         |
##   | Ccv    | CCV      | short rafsi, CC permissible initial          | 4.6         |
##   | Cvv    | CVV      | short rafsi; CV'V, or VV one of four         | 4.6         |
##   |        |          |   diphthongs `ai ei oi au`                   |             |
##   | Cvcc   | CVC/C    | 4-letter rafsi of CVCCV gismu, never final   | 4.6         |
##   | Ccvc   | CCVC     | 4-letter rafsi of CCVCV gismu, never final   | 4.6         |
##   | Cvccv  | CVC/CV   | gismu, or its 5-letter rafsi, final alone    | 4.4, 4.6    |
##   | Ccvcv  | CCVCV    | gismu, or its 5-letter rafsi, final alone    | 4.4, 4.6    |
##   |--------|----------|----------------------------------------------|-------------|
##
##   Sibling `lojban_tagger/src/lojban_tagger/forms.nim` holds earlier copy, without `Kind`,
##     `isCmavo`, `splitCompound`, `syllables`, and rules of cmene, fu'ivla and pauses, until
##     #809 drops it (II.9).
##   Notation of CLL is canonical spelling (Article III.1): C is consonant, V is vowel, `/`
##     marks medial pair that need only be permissible (3.6), adjacent CC at start must be
##     initial pair (3.7). Members are Pascal case of that notation (V.11).
##   CV'V and diphthong CVV share `Cvv`, since both take every position CVV takes; apostrophe
##     matters only to score (4.12), which reads it off letters.
##   Form judges letters alone, never dictionary: `dri` is `Ccv` whether or not list assigns
##     it, so morphology and vocabulary stay separable and each testable alone.
##   `Kind` sorts word into class of 4.1 by letters alone, as 4.2 to 4.8 give each class; list
##     gives meaning, never class.
##   Rules of cmene (4.8) and fu'ivla (4.7) that letters alone decide stand here: pairs of 3.6
##     for both, triples of 3.7 for fu'ivla alone, cluster opening fu'ivla, and `la` and `doi`
##     cmene may not hold.
##     Rules needing other words, combination and slinku'i test, stand in `fuhivla.nim`.
##   Pause rules of 4.9 that letters decide stand here too, so fu'ivla and stream share them;
##     stream adds stress.
##   Cmavo form (4.2) is optional consonant, then run of vowels: one vowel or diphthong, then
##     each further one after apostrophe. Ten on-glides 4.2 adds stand first, in cmavo opening
##     with vowel alone, as 3.4 keeps them to words standing alone. `Cy`, `y` and `y'y` are
##     letterals (4.2, 17.2).
##     Cost: run of three vowels or more is form 4.2 keeps for experiment, so it reads as cmavo
##       no list can hold.
##   Compound cmavo splits before each consonant and at each period (4.2, 3.3): cmavo holds
##     one consonant at most, first, and cmavo opening with vowel follows pause. So split is
##     unique, and each piece is cmavo of 4.2 or compound is none.
##   Cost: every rafsi text classified again where read, rather than form stored beside it;
##     text is at most five letters, so cost is constant (unmeasured).

{.experimental: "strictFuncs".}

import std/[options, strutils]

import ./clusters


type
  Form* {.pure.} = enum  ## Define shape of rafsi, in notation of CLL 4.6.
    Cvc, Ccv, Cvv, Cvcc, Ccvc, Cvccv, Ccvcv

  Kind* {.pure.} = enum  ## Define class of word, as 4.1 to 4.8 sort words by form.
    Cmavo  ## Structure word, no consonant pair (4.2).
    Gismu  ## Root brivla of five letters, CVC/CV or CCVCV (4.4).
    Lujvo  ## Brivla of two rafsi or more, joined as 4.11 joins them (4.5, 4.6).
    Fuhivla  ## Brivla neither gismu nor lujvo, nor any combination of words (4.7).
    Cmene  ## Name, ending in consonant (4.8).


const
  DIPHTHONGS* = ["ai", "ei", "oi", "au"]
    ## Vowel pairs VV stands for unbroken (4.1 rule 2): CVV rafsi (4.6) and cmavo (4.2) hold them.
  DIPHTHONGS_CMAVO* = ["ia", "ie", "ii", "io", "iu", "ua", "ue", "ui", "uo", "uu"]
    ## Ten diphthongs 4.2 adds for cmavo of VV form: on-glides 3.4 keeps to words standing alone.
  FORMS_SHORT* = {Form.Cvc, Form.Ccv, Form.Cvv}  ## Three-letter rafsi, apostrophe aside (4.6).
  FORMS_UNREDUCED* = {Form.Cvcc, Form.Ccvc}  ## 4-letter rafsi, gismu less final vowel (4.6).
  FORMS_GISMU* = {Form.Cvccv, Form.Ccvcv}  ## Shapes of gismu, and of 5-letter rafsi (4.4).
  FORMS_FINAL* = {Form.Ccv, Form.Cvv, Form.Cvccv, Form.Ccvcv}
    ## Forms lujvo may end with: those ending in vowel (4.6, 4.11 step 2).
  CMAVO_BEFORE_CMENE* = ["la", "lai", "la'i", "doi"]
    ## Cmavo cmene may follow with no pause between them (4.9 rule 4).
  SEQUENCES_BREAKUP* = ["la", "doi"]
    ## Letters cmene holds only after consonant, else it breaks up into words (4.8); `lai` and
    ##   `la'i` open with `la`, so ban on `la` holds them too.
  VOWELS_SYLLABLE = VOWELS + {'y'}  ## Letters each making syllable: five vowels, and `y` (3.4).



#[ Forms ]#

func form*(text: string): Option[Form] =
  ## Classify text as rafsi form of 4.6; `none` where letters fit no form.
  template c(i: int): bool = text[i].isConsonant
  template v(i: int): bool = text[i].isVowel

  case text.len
  of 3:
    if c(0) and v(1) and c(2): some(Form.Cvc)
    elif c(0) and c(1) and v(2) and isPairInitial(text[0], text[1]): some(Form.Ccv)
    elif c(0) and v(1) and v(2) and text[1 .. 2] in DIPHTHONGS: some(Form.Cvv)
    else: none(Form)
  of 4:
    if c(0) and v(1) and text[2] == '\'' and v(3): some(Form.Cvv)
    elif c(0) and v(1) and c(2) and c(3) and isPairPermissible(text[2], text[3]):
      some(Form.Cvcc)
    elif c(0) and c(1) and v(2) and c(3) and isPairInitial(text[0], text[1]): some(Form.Ccvc)
    else: none(Form)
  of 5:
    if c(0) and v(1) and c(2) and c(3) and v(4) and isPairPermissible(text[2], text[3]):
      some(Form.Cvccv)
    elif c(0) and c(1) and v(2) and c(3) and v(4) and isPairInitial(text[0], text[1]):
      some(Form.Ccvcv)
    else: none(Form)
  else: none(Form)


func isGismu*(text: string): bool =
  ## Test text has shape of gismu, i.e. CVC/CV or CCVCV (4.4); list membership not asked.
  let shape = text.form
  shape.isSome and shape.get in FORMS_GISMU


func isBrivla*(text: string): bool =
  ## Test written properties every brivla holds (4.3): final vowel, and consonant pair among
  ##   first five letters, `y` and apostrophe not counted.
  ##   Stress is third property; written text carries none, and penultimate stress is default.
  if text.len == 0 or not text[^1].isVowel: return false
  var letters: string
  for character in text:
    if character notin {'y', '\''}: letters.add character
    if letters.len == 5: break
  for i in 0 ..< letters.len - 1:
    if letters[i].isConsonant and letters[i + 1].isConsonant: return true
  false


func syllables*(text: string): int =
  ## Count syllables: each vowel, `y` included, is one, and diphthong of 4.1 joins two (3.4).
  for i, letter in text:
    if letter notin VOWELS_SYLLABLE: continue
    if i > 0 and text[i - 1 .. i] in DIPHTHONGS: continue
    inc result


func isCmavo*(text: string): bool =
  ## Test text is one cmavo by form of 4.2: V, VV, CV or CVV, or run of three vowels or more
  ##   that 4.2 keeps for experiment; or letteral `Cy`, `y` alone, or `y'y` (4.2, 17.2).
  ##   VV is diphthong or V'V (4.1 rule 2); in cmavo opening with vowel, first pair may also be
  ##     one of ten on-glides 4.2 adds. Each vowel past first pair follows apostrophe.
  ##   Pause before vowel goes unwritten here; period writing it is mark of stream (3.3).
  let
    start = (if text.len > 0 and text[0].isConsonant: 1 else: 0)
    rest = text[start .. ^1]
  if rest == "y": return true
  if rest == "y'y": return start == 0
  var at = 0
  while at < rest.len:
    if not rest[at].isVowel: return false
    let pair = rest[at .. min(at + 1, rest.high)]
    if pair in DIPHTHONGS or (at == 0 and start == 0 and pair in DIPHTHONGS_CMAVO): at += 2
    else: inc at
    if at == rest.len: return true
    if rest[at] != '\'': return false
    inc at
  false


func splitCompound*(text: string): seq[string] =
  ## Split cmavo run together into each cmavo, as 4.2 compounds them; empty where any piece is
  ##   no cmavo of 4.2. One cmavo splits into itself.
  ##   Piece ends before each consonant, since cmavo holds one consonant at most, first; and at
  ##     each period, which writes pause before cmavo opening with vowel (3.3).
  var piece = ""
  for letter in text:
    if letter == '.' or (letter.isConsonant and piece.len > 0):
      if piece.len > 0: result.add piece
      piece = ""
      if letter == '.': continue
    piece.add letter
  if piece.len > 0: result.add piece
  for one in result:
    if not one.isCmavo: return @[]



#[ Cmene, Fu'ivla and Pauses ]#

func pairForbidden*(text: string): Option[string] =
  ## Find first consonant pair of text that 3.6 forbids; none where each is permissible, as
  ##   cmene needs alone (4.8): `NEderlants` holds triple `nts`, and 4.8 calls it valid.
  for i in 0 ..< text.high:
    if not (text[i].isConsonant and text[i + 1].isConsonant): continue
    if not isPairPermissible(text[i], text[i + 1]): return some(text[i .. i + 1])
  none(string)


func clusterForbidden*(text: string): Option[string] =
  ## Find first consonant pair of text that 3.6 forbids, or triple that 3.7 forbids by name;
  ##   none where each is permissible, as fu'ivla needs (4.7): `lerndjamo` holds `ndj`.
  let pair = text.pairForbidden
  if pair.isSome: return pair
  for i in 0 ..< text.len - 2:
    if text[i .. i + 2] in TRIPLES_FORBIDDEN: return some(text[i .. i + 2])
  none(string)


func clusterOpeningForbidden*(text: string): Option[string] =
  ## Find consonant cluster opening text where some pair is no initial pair of 3.7, which 4.7
  ##   forbids fu'ivla; none where text opens with vowel, one consonant, or initial pairs alone.
  var finish = 0
  while finish < text.len and text[finish].isConsonant: inc finish
  for i in 0 ..< finish - 1:
    if not isPairInitial(text[i], text[i + 1]): return some(text[0 ..< finish])
  none(string)


func breakup*(text: string): Option[string] =
  ## Find `la` or `doi` text holds after no consonant, where cmene would break up into words
  ##   (4.8); none where each stands after consonant, or text holds neither.
  for sequence in SEQUENCES_BREAKUP:
    var at = text.find(sequence)
    while at >= 0:
      if at == 0 or not text[at - 1].isConsonant: return some(sequence)
      at = text.find(sequence, at + 1)
  none(string)


func isLetteral*(text: string): bool = text.len == 2 and text[0].isConsonant and text[1] == 'y'
  ## Test word is letteral `Cy`, which names consonant (4.2, 17.2).


func isPauseNeeded*(prior, next: string): bool =
  ## Test rule of 4.9 needs pause between two words by their letters alone, stress aside:
  ##   rule 2, word ending in consonant; rule 3, word opening with vowel, or `y` (4.2); rule 4,
  ##   cmene after word other than `la`, `lai`, `la'i` or `doi`; rule 6, `Cy` before word not
  ##   `Cy`; and pause after `y` (4.2).
  if prior[^1].isConsonant or next[0] in VOWELS_SYLLABLE: return true  # rules 2, 3; 4.2
  if next[^1].isConsonant and prior notin CMAVO_BEFORE_CMENE: return true  # rule 4
  prior == "y" or (prior.isLetteral and not next.isLetteral)  # 4.2; rule 6
