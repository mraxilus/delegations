## Format numbers into fixed char storage without touching heap.
##
## Nim's `$` and `strformat` produce heap-allocated `string`; C's `snprintf` writes into
## storage caller owns.
##   Every visible object's coefficients are redrawn once per object per frame, so difference
##   is allocator call per number against none.
## Sits beside `sdl3`, `opengl` and `image` as binding over something external, C
## runtime's formatter, rather than beside `scene` or `mesh`.
## `snprintf` is C entry point, so browser build cannot reach it.
##   What magnitude should *read* as is project's own rule, so `formatMagnitude` states it
##   in plain Nim for that build, and `magnitudesAgree` in suite holds two to same answer.
##
## Shared by desktop (`main.nim`) and browser (`bridge.nim`) render paths,
## transitively through `interaction`.

{.experimental: "strictFuncs".}

import std/[math, strutils]



#[ Binding Configuration ]#

const HEADER = "<stdio.h>"  ## Name header C runtime's formatter is imported through.

# Import C runtime's formatter one-to-one; see its manual page.
#   Guarded rather than left to fail at run time: JS backend *compiles* `importc` it has no
#   definition for and throws only when call is reached, browser crash rather than build
#   error. Every appender needing it is guarded to match.
#   `noSideEffect`, sole binding without `sideEffect`: formatter writes only buffer it is
#   handed, and every caller hands one on its own stack, so `func` formatting through it
#   stays pure. Suite holds both backends to one answer (`magnitudesAgree`).
when not defined(js):
  proc snprintf(buffer: cstring, size: csize_t, format: cstring): cint
    {.importc: "snprintf", header: HEADER, varargs, discardable, noSideEffect.}



#[ Significant Digits Without C ]#

const DIGITS_SIGNIFICANT* = 4
  ## Fix significant digits shown for magnitude, wherever one is shown.
  ##   Enough to tell coefficients apart, few enough that sixteen fit panel.

func roundHalfToEven(value: float): float =
  ## Round to nearest whole number, breaking exact half toward even one.
  ##   Rule C's formatter rounds decimal digits by.
  ##   Nim's `round` breaks half away from zero, so two differ on every exact tie: 1012.5
  ##   to 1012 here against 1013 there.
  let
    whole = floor(value)
    fraction = value - whole
  if fraction > 0.5: whole + 1.0
  elif fraction < 0.5: whole
  elif whole mod 2.0 == 0.0: whole
  else: whole + 1.0


func roundedExact(value: float): tuple[whole: float, exponent: int] =
  ## Round `|value|` to `DIGITS_SIGNIFICANT` digits off its exact decimal digits, as whole
  ##   number with decimal exponent of its first digit, breaking exact half toward even.
  ##   Rule C's formatter rounds by, read exactly where product of value and power of ten
  ##     cannot say which side of tie value stands on (repository issue 1053).
  ##   Module scope, not nested in `formatMagnitude`, whose derivation of `%g` runs past
  ##     sixty lines already.
  ##   Tuple, not `var` exponent: JS backend boxes `var` local in array, and box would then
  ##     stand in each call of `formatMagnitude`, near tie or not.
  func digitsExact(value: float, exponent: var int): seq[int] =
    ## Write each decimal digit of `|value|` exactly, most significant first, and decimal
    ##   exponent of first digit into `exponent`.
    ##   Whole mantissa times power of two is read off by halving and doubling, each exact.
    ##     Power is then carried into limbs of base 10^4 by 2^13 or 5^6 at time: each
    ##     product stands under 2^28, which either backend holds exactly.
    ##   Up to 767 digits, for subnormal value.
    func multiply(limbs: var seq[int], factor: int) =
      ## Multiply whole number that `limbs` hold by `factor`, under 2^15.
      var carry = 0
      for limb in limbs.mitems:
        let product = limb * factor + carry
        limb = product mod 10000
        carry = product div 10000
      while carry > 0:
        limbs.add carry mod 10000
        carry = carry div 10000

    var
      mantissa = abs(value)
      power = 0
    while mantissa >= 9007199254740992.0:
      mantissa *= 0.5
      inc power
    while mantissa != floor(mantissa):
      mantissa *= 2.0
      dec power
    var limbs: seq[int]  # Least significant first.
    while mantissa > 0.0:
      let limb = mantissa mod 10000.0
      limbs.add int(limb)
      mantissa = (mantissa - limb) / 10000.0
    # Value is `m · 2^power`, which is `m · 5^-power · 10^power` where power is negative.
    let (chunk, factor_chunk, base) = if power >= 0: (13, 8192, 2) else: (6, 15625, 5)
    var count = abs(power)
    while count >= chunk:
      limbs.multiply(factor_chunk)
      count -= chunk
    if count > 0: limbs.multiply(base ^ count)
    for i in countdown(limbs.high, 0):
      let text = if i == limbs.high: $limbs[i] else: align($limbs[i], 4, '0')
      for ch in text: result.add(ord(ch) - ord('0'))
    exponent = result.len - 1 - (if power < 0: -power else: 0)

  var exponent = 0
  let digits = digitsExact(value, exponent)
  var whole = 0
  for i in 0..<DIGITS_SIGNIFICANT:
    whole = 10 * whole + (if i < digits.len: digits[i] else: 0)
  let next = if digits.len > DIGITS_SIGNIFICANT: digits[DIGITS_SIGNIFICANT] else: 0
  var is_past_half = next > 5
  if next == 5:
    for i in (DIGITS_SIGNIFICANT + 1)..<digits.len:
      if digits[i] != 0:
        is_past_half = true
        break
  if is_past_half or (next == 5 and whole mod 2 == 1): inc whole
  if whole == 10 ^ DIGITS_SIGNIFICANT:
    whole = 10 ^ (DIGITS_SIGNIFICANT - 1)
    inc exponent
  (float(whole), exponent)


const MARGIN_TIE = 1.0 / 1099511627776.0
  ## Bound, as fraction of product, within which `formatMagnitude` reads side of tie off
  ##   exact digits: `2^-40`.
  ##   Product carries few ulps of error, from `pow` and up to three roundings: margin holds
  ##     2^12 of them, so value outside it rounds off product to same digits.


func formatMagnitude*(value: float): string =
  ## Format `value` to `DIGITS_SIGNIFICANT` significant digits without C runtime.
  ##   Same reading `appendMagnitude`'s `%.4g` gives; for browser build, which has no
  ##   `snprintf`.
  ##   Allocates, unlike everything else here.
  ##     Browser rebuilds number fields when grid changes, not per object per frame.
  ##     Never call from desktop's draw loop.
  ##   `%g`'s rule, from C standard: take exponent value rounds to at this precision,
  ##   write scientifically where it falls outside [-4, DIGITS_SIGNIFICANT), fixed
  ##   otherwise; trailing zeros go.
  ##   Kept whole past sixty lines: one derivation of `%g`, whose rounding, exponent and
  ##   trimming steps read as one rule.
  ##   Derives own digits rather than asking runtime.
  ##     `formatBiggestFloat` lands on whatever conversion backend has, and two disagree on
  ##     ties: C rounds tie to even and JavaScript away from zero.
  ##     Same value must read same in both.
  ##   Scales by *multiplying* by positive power of ten wherever it can.
  ##     10^k is exact as double for k in 0 .. 22, 10^-k never is, and inexact divisor
  ##     moves true tie off half.

  func trimmed(text: string): string =
    ## Drop trailing zeros, and point left bare by dropping them.
    if '.' notin text: return text
    result = text.strip(leading = false, trailing = true, chars = {'0'})
    result = result.strip(leading = false, trailing = true, chars = {'.'})

  func isNearTie(product, scaled: float): bool =
    ## Report whether `product` stands within `MARGIN_TIE` of half beside `scaled`, its
    ##   rounding.
    let
      offset = product - scaled
      margin = MARGIN_TIE * product
    offset >= 0.5 - margin or offset <= margin - 0.5

  if value != value: return "nan"
  if value == Inf: return "inf"
  if value == -Inf: return "-inf"
  if value == 0.0: return "0"

  let sign = if value < 0.0: "-" else: ""
  var exponent = int(floor(log10(abs(value))))

  const shift_largest = 308
    ## Bound shift one power of ten carries: `10^309` overflows to infinity.

  func scaledTo(value: float, exponent: int): float =
    ## Carry `value`'s leading `DIGITS_SIGNIFICANT` digits into whole-number range.
    ##   Shift past `shift_largest`, which magnitude under 1e-305 takes, goes in two steps:
    ##     `1e308`, then power of ten left, at most `10^20`, which is exact.
    let shift = DIGITS_SIGNIFICANT - 1 - exponent
    if shift > shift_largest: abs(value) * 1.0e308 * pow(10.0, float(shift - shift_largest))
    elif shift >= 0: abs(value) * pow(10.0, float(shift))
    else: abs(value) / pow(10.0, float(-shift))

  var
    product = scaledTo(value, exponent)
    scaled = roundHalfToEven(product)
    is_ambiguous = isNearTie(product, scaled)

  # Follow carry into another digit, 9999.6 to 10000, with exponent text is written around.
  #   Margin is read before carry too: tie at 9999.5 stands at 999.95 past it, where no
  #   test sees it.
  if not is_ambiguous:
    if scaled >= pow(10.0, float(DIGITS_SIGNIFICANT)):
      exponent += 1
      product = scaledTo(value, exponent)
      scaled = roundHalfToEven(product)
      is_ambiguous = isNearTie(product, scaled)
    elif scaled < pow(10.0, float(DIGITS_SIGNIFICANT - 1)):
      exponent -= 1
      product = scaledTo(value, exponent)
      scaled = roundHalfToEven(product)
      is_ambiguous = isNearTie(product, scaled)

  # Product within `MARGIN_TIE` of tie reads its side, and its exponent, off exact digits.
  if is_ambiguous:
    let exact = roundedExact(value)
    scaled = exact.whole
    exponent = exact.exponent

  let digits = $int(scaled)
  if exponent < -4 or exponent >= DIGITS_SIGNIFICANT:
    # Write at least two exponent digits, as C does; Nim writes as few as one.
    let
      magnitude = abs(exponent)
      sign_exponent = if exponent < 0: "-" else: "+"
      padding = if magnitude < 10: "0" else: ""
    sign & trimmed(digits[0..0] & "." & digits[1 .. ^1]) &
        "e" & sign_exponent & padding & $magnitude
  elif exponent >= 0:
    let count_integer = exponent + 1
    sign & trimmed(digits[0..<count_integer] & "." & digits[count_integer .. ^1])
  else:
    sign & trimmed("0." & repeat('0', -exponent - 1) & digits)



#[ Fixed Text Buffers ]#

func bytesCharacter*(lead: char): int =
  ## Say how many bytes UTF-8 character starting with this byte occupies.
  ##   One for ASCII and for any byte that is not valid lead, so buffer holding something
  ##   not UTF-8 still advances byte at time.
  ##   Three multi-byte widths are what project writes: operator notation (`∧`, `∨`, `⊖`),
  ##   subscripts, ellipsis.
  let value = uint8(lead)
  if value < 0x80: 1
  elif value < 0xC0: 1  # Stray continuation byte; not lead, so not character start.
  elif value < 0xE0: 2
  elif value < 0xF0: 3
  else: 4


func lengthFitting*(text: openArray[char], capacity: int): int =
  ## Measure how many leading bytes of `text` fit in `capacity` without splitting character.
  ##   Separate from copy below so boundary rule is stated once: `toChars` needs same
  ##   answer against smaller capacity, to leave room for mark it adds.
  let bound = min(capacity, len(text))
  while result < len(text):
    let width = bytesCharacter(text[result])
    if result + width > bound: break
    result += width


func appendChars*(storage: var openArray[char], cursor: var int, text: openArray[char]) =
  ## Copy as much of `text` as still fits after `cursor`, advancing it.
  ##   Silently truncates rather than overrunning `storage`, as `toChars` does.
  ##     Storage is display only, and GUI must never write past own buffer.
  ##   Truncates whole characters, never part of one.
  ##     Byte-wise copy cut three-byte operator in half, and invalid tail reached browser
  ##     as literal `%e2%8a`: Nim's JS backend percent-escapes what it cannot decode.
  ##     Same mismatch scene file's label field had, other half of it.
  for offset in 0..<lengthFitting(text, len(storage) - 1 - cursor):
    storage[cursor] = text[offset]
    inc cursor


func toText*(storage: openArray[char]): string =
  ## Read fixed char storage back into string, stopping at terminator.
  ##   Inverse of `scene.toChars`, and only reading answering same on both render paths.
  ##     `$scene.toCstring` reads storage's *address*, which JS backend has no notion of,
  ##     and yields empty string there.
  ##     Suite runs on both backends, so regression to that pattern fails test.
  for ch in storage:
    if ch == '\0': return
    result.add(ch)


func appendMagnitude*(storage: var openArray[char], cursor: var int, value: float) =
  ## Format `value` to `DIGITS_SIGNIFICANT` significant digits straight into `storage`.
  ##   Significant digits, not decimal places, and no `#` flag: 3.5 reads `3.5` rather
  ##   than `3.5000`, and 1664 keeps integer part.
  ##   Shared, so both render paths print coefficient identically, each through what costs
  ##   least.
  ##     Desktop redraws sixteen coefficients per visible object per frame through C's
  ##     formatter, touching no heap.
  ##     Browser has no C runtime and states same rule in `formatMagnitude` at cost of
  ##     one string.
  ##     Suite's `magnitudesAgree` holds them to same answer.
  when defined(js):
    appendChars(storage, cursor, formatMagnitude(value))
  else:
    var buffer: array[32, char]
    let count = snprintf(
      cast[cstring](addr buffer[0]), csize_t(len(buffer)),
      cstring("%." & $DIGITS_SIGNIFICANT & "g"), value
    )
    appendChars(storage, cursor, buffer.toOpenArray(0, int(count) - 1))


func appendInt*(storage: var openArray[char], cursor: var int, value: int) =
  ## Format `value` as plain decimal integer straight into `storage`.
  ##   Every caller counts something small and bounded, so narrowing to `cint` never
  ##   truncates real value.
  ##   Shared, as `appendMagnitude` is: objects list says how many search shows on both
  ##   render paths, through `wording.appendShownCounted`.
  ##     Desktop formats through C, touching no heap; browser has no C runtime and pays one
  ##     string.
  when defined(js):
    appendChars(storage, cursor, $value)
  else:
    var buffer: array[24, char]
    let count =
      snprintf(cast[cstring](addr buffer[0]), csize_t(len(buffer)), "%d", cint(value))
    appendChars(storage, cursor, buffer.toOpenArray(0, int(count) - 1))


when not defined(js):
  func appendFixed*(storage: var openArray[char], cursor: var int, value: float, digits: int) =
    ## Format `value` to fixed digits after point straight into `storage`.
    ##   Matches `strformat`'s `:.Nf`.
    ##   Desktop-only: it serves diagnostics panel, which has no browser counterpart.
    var buffer: array[32, char]
    let count = snprintf(
      cast[cstring](addr buffer[0]), csize_t(len(buffer)), "%.*f", cint(digits), value
    )
    appendChars(storage, cursor, buffer.toOpenArray(0, int(count) - 1))


func finishChars*(storage: var openArray[char], cursor: int) =
  ## Zero every byte from `cursor` onward.
  ##   Text longer previous write left behind never trails past what was written this time.
  for i in cursor..<len(storage): storage[i] = '\0'



#[ One-Line Assembly ]#

when not defined(js):
  template buildChars*(storage: var openArray[char], body: untyped): cstring =
    ## Build one line into `storage` from `append*` calls in `body`, and hand back its address.
    ##   Zeroes fresh injected `cursor`, runs `body`, then terminates, so building one line
    ##   costs only calls that vary between sites.
    ##   Desktop-only, as `scene.toCstring` is.
    ##     Hands back address, which Dear ImGui takes and JS backend has no notion of.
    ##     Browser caller wants `toText` on storage.
    block:
      var cursor {.inject.} = 0
      body
      finishChars(storage, cursor)
      cast[cstring](unsafeAddr storage[0])
