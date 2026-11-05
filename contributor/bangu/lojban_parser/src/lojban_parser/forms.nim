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
##   Copied as `lojban_tagger/src/lojban_tagger/forms.nim` until #809 drops it (II.9).
##   Notation of CLL is canonical spelling (Article III.1): C is consonant, V is vowel, `/`
##     marks medial pair that need only be permissible (3.6), adjacent CC at start must be
##     initial pair (3.7). Members are Pascal case of that notation (V.11).
##   CV'V and diphthong CVV share `Cvv`, since both take every position CVV takes; apostrophe
##     matters only to score (4.12), which reads it off letters.
##   Form judges letters alone, never dictionary: `dri` is `Ccv` whether or not list assigns
##     it, so morphology and vocabulary stay separable and each testable alone.
##   `Kind` sorts word into class of 4.1 by letters alone, as 4.2 to 4.5 give each class; list
##     gives meaning, never class. Cmene (4.8) and fu'ivla (4.7) wait for #812.
##   Cmavo form (4.2) is optional consonant, then run of vowels: one vowel or diphthong, then
##     each further one after apostrophe. Ten on-glides 4.2 adds stand first, in cmavo opening
##     with vowel alone, as 3.4 keeps them to words standing alone. `Cy`, `y` and `y'y` are
##     letterals (4.2, 17.2).
##     Cost: run of three vowels or more is form 4.2 keeps for experiment, so it reads as cmavo
##       no list can hold.
##   Cost: every rafsi text classified again where read, rather than form stored beside it;
##     text is at most five letters, so cost is constant (unmeasured).

{.experimental: "strictFuncs".}

import std/options

import ./clusters


type
  Form* {.pure.} = enum  ## Define shape of rafsi, in notation of CLL 4.6.
    Cvc, Ccv, Cvv, Cvcc, Ccvc, Cvccv, Ccvcv

  Kind* {.pure.} = enum  ## Define class of word, as 4.1 to 4.5 sort words by form.
    Cmavo  ## Structure word, no consonant pair (4.2).
    Gismu  ## Root brivla of five letters, CVC/CV or CCVCV (4.4).
    Lujvo  ## Brivla of two rafsi or more, joined as 4.11 joins them (4.5, 4.6).


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
