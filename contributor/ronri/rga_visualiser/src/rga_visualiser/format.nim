## Format numbers into fixed char storage without touching heap.
##
## Nim's `$` and `strformat` produce heap-allocated `string`; C's `snprintf` writes into
## storage caller owns.
##   Every visible item's coefficients are redrawn once per item per frame, so difference
##   is allocator call per number against none.
## Sits beside `sdl3`, `opengl` and `image` as binding over something external, C
## runtime's formatter, rather than beside `scene` or `mesh`.
## `snprintf` is C entry point, so browser build cannot reach it.
##   What magnitude should *read* as is project's own rule, so `formatMagnitude` states it
##   in plain Nim for that build, and `magnitudesAgree` in suite holds two to same answer.
##
## Shared by desktop (`visualiser.nim`) and browser (`browser_bridge.nim`) render paths,
## transitively through `interaction`.

{.experimental: "strictFuncs".}

import std/[math, strutils]



#[ Binding Configuration ]#

const HEADER = "<stdio.h>"
  ## Name header C runtime's formatter is imported through.

# Import C runtime's formatter one-to-one; see its manual page.
#   Guarded rather than left to fail at run time: JS backend *compiles* `importc` it has no
#   definition for and throws only when call is reached, browser crash rather than build
#   error. Every appender needing it is guarded to match.
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


func formatMagnitude*(value: float): string =
  ## Format `value` to `DIGITS_SIGNIFICANT` significant digits without C runtime.
  ##   Same reading `appendMagnitude`'s `%.4g` gives; for browser build, which has no
  ##   `snprintf`.
  ##   Allocates, unlike everything else here.
  ##     Browser rebuilds number fields when grid changes, not per item per frame.
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

  if value != value: return "nan"
  if value == Inf: return "inf"
  if value == -Inf: return "-inf"
  if value == 0.0: return "0"

  let sign = if value < 0.0: "-" else: ""
  var exponent = int(floor(log10(abs(value))))

  func scaledTo(value: float, exponent: int): float =
    ## Carry `value`'s leading `DIGITS_SIGNIFICANT` digits into whole-number range.
    let shift = DIGITS_SIGNIFICANT - 1 - exponent
    if shift >= 0: abs(value)*pow(10.0, float(shift))
    else: abs(value)/pow(10.0, float(-shift))

  var scaled = roundHalfToEven(scaledTo(value, exponent))

  # Follow carry into another digit, 9999.6 to 10000, with exponent text is written around.
  if scaled >= pow(10.0, float(DIGITS_SIGNIFICANT)):
    exponent += 1
    scaled = roundHalfToEven(scaledTo(value, exponent))
  elif scaled < pow(10.0, float(DIGITS_SIGNIFICANT - 1)):
    exponent -= 1
    scaled = roundHalfToEven(scaledTo(value, exponent))

  let digits = $int(scaled)
  if exponent < -4 or exponent >= DIGITS_SIGNIFICANT:
    # Write at least two exponent digits, as C does; Nim writes as few as one.
    let
      magnitude = abs(exponent)
      sign_exponent = if exponent < 0: "-" else: "+"
      padding = if magnitude < 10: "0" else: ""
    sign & trimmed(digits[0 .. 0] & "." & digits[1 .. ^1]) &
      "e" & sign_exponent & padding & $magnitude
  elif exponent >= 0:
    let count_integer = exponent + 1
    sign & trimmed(digits[0 ..< count_integer] & "." & digits[count_integer .. ^1])
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
  elif value < 0xC0: 1 # Stray continuation byte; not lead, so not character start.
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
  ##     Same mismatch `.rgascene` label field had, other half of it.
  for offset in 0 ..< lengthFitting(text, len(storage) - 1 - cursor):
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
  ##     Desktop redraws sixteen coefficients per visible item per frame through C's
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


when not defined(js):
  func appendInt*(storage: var openArray[char], cursor: var int, value: int) =
    ## Format `value` as plain decimal integer straight into `storage`.
    ##   Every caller counts something small and bounded, so narrowing to `cint` never
    ##   truncates real value.
    ##   Desktop-only, with `appendFixed`: both serve diagnostics panel, which has no
    ##   browser counterpart.
    var buffer: array[24, char]
    let count =
      snprintf(cast[cstring](addr buffer[0]), csize_t(len(buffer)), "%d", cint(value))
    appendChars(storage, cursor, buffer.toOpenArray(0, int(count) - 1))


  func appendFixed*(
    storage: var openArray[char], cursor: var int, value: float, digits: int
  ) =
    ## Format `value` to fixed digits after point straight into `storage`.
    ##   Matches `strformat`'s `:.Nf`.
    ##   Desktop-only, with `appendInt`; see its doc comment.
    var buffer: array[32, char]
    let count = snprintf(
      cast[cstring](addr buffer[0]), csize_t(len(buffer)), "%.*f", cint(digits), value
    )
    appendChars(storage, cursor, buffer.toOpenArray(0, int(count) - 1))


func finishChars*(storage: var openArray[char], cursor: int) =
  ## Zero every byte from `cursor` onward.
  ##   Text longer previous write left behind never trails past what was written this time.
  for i in cursor ..< len(storage): storage[i] = '\0'



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
