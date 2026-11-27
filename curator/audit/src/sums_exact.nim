## Sum floats exactly, and round sum once to nearest float, as tallies of claims sum (#1049).
##   Sum of finite values is one integer in units of least float, `2^-1074`: 53 bits of each value
##     shift into limbs of 32 bits (`LIMBS_SUM`), so each adds exactly, and sum takes no order; sum
##     of two parts added equals sum of whole, to last bit.
##   Policy for each value of float (Article IV.8):
##     finite values: exact sum rounds once, to nearest float, half to even, as `math.fsum` and IEEE
##       754 round; sum at or past `2^1024 − 2^970` rounds to infinity of its sign, as IEEE 754
##       rounds value past largest float;
##     NaN, or infinity of each sign, gives NaN; infinity of one sign gives itself, whatever finite
##       values stand beside it;
##     exact zero gives `0.0`, as `math.fsum` gives, `-0.0` among values too.
##   Partials of sum, which prior writes, are canonical: nearest float of what remains, from whole
##     sum down, smallest first, and largest float for each part past range (`partials`). So sums
##     of same value write same partials, whatever order their values came in.
##
##   Rejected: raise of `math.fsum` at `-inf + inf` and at overflow of running sum, as for
##     `[1e308, 1e308, -1e308]`: figures would fail where sum has value, and sum would take order.
##   Rejected: partials of Shewchuk (1997), as `msum` of `math.fsum` keeps: two partials past range
##     sum to infinity, whose error is NaN.
##   Cost: each sum holds `LIMBS_SUM` limbs, 544 bytes, where partials of `math.fsum` hold few; each
##     value added touches three limbs and their carry, and each rounding walks each limb.
##   Cost: last limb is signed, so limbs hold exact sum of fewer than `2^100` largest floats;
##     intended bound, past count any log reaches.
##   Cost: `koch figures kind,effort,project,model` takes 0.024 to 0.027 s, where it took 0.023 to
##     0.024 s with partials of Shewchuk; mean of 5 runs of release build, taken twice, on 4 x86_64
##     cores, 2026-11-27, with same output to last character.

{.experimental: "strictFuncs".}

import std/[algorithm, bitops, math, sequtils]


const
  LIMBS_SUM = 68
    ## Limbs of integer of sum: lead bit of largest float stands at `BIT_TOP`, in limb 65, so limbs
    ##   66 and signed 67 hold carry.
  BITS_LIMB = 32  ## Bits of each limb but last.
  MASK_LIMB = (1'u64 shl BITS_LIMB) - 1  ## Bits of one limb.
  BITS_MANTISSA = 53  ## Bits of mantissa of float, lead bit counted.
  MASK_FRACTION = (1'u64 shl (BITS_MANTISSA - 1)) - 1  ## Bits of mantissa that float stores.
  MASK_EXPONENT = 0x7FF'u64  ## Bits of biased exponent of float, after its mantissa.
  EXPONENT_LEAST = -1074  ## Exponent of least float above zero, unit of integer of sum.
  EXPONENT_NORMAL = -1022  ## Least exponent of normal float.
  EXPONENT_MOST = 1023  ## Exponent of lead bit of largest float.
  BIAS = 1023  ## Bias of exponent that float stores.
  BIT_TOP = EXPONENT_MOST - EXPONENT_LEAST  ## Bit of integer that lead bit of largest float sets.
  MAX = 1.7976931348623157e308  ## Largest float, `(2^53 − 1) × 2^971`.
  TINY = 5e-324  ## Least float above zero, `2^-1074`.

type
  Special {.pure.} = enum  ## Define what non-finite values added sum to, by policy of header.
    None  ## No NaN and no infinity added.
    Infinity  ## Infinity added, and no NaN or negative infinity.
    InfinityNegative  ## Negative infinity added, and no NaN or infinity.
    Nan  ## NaN added, or infinity of each sign.

  SumExact* = object
    ## Define exact sum of floats: integer of finite values in units of `2^-1074`, and special
    ##   value apart; limbs hold zero where special value stands, so equal sums compare equal.
    limbs: array[LIMBS_SUM, int64]
      ## Limb `k` holds bits `32k` to `32k + 31`, each limb but last in `0 ..< 2^32`, last signed.
    special: Special  ## What non-finite values added sum to.


func carried(limbs: var array[LIMBS_SUM, int64], start, stop: int) =
  ## Carry each limb from start into next, through stop and on while carry stays, so each limb but
  ##   last lies in `0 ..< 2^32`.
  for i in start ..< LIMBS_SUM - 1:
    let carry = ashr(limbs[i], BITS_LIMB)
    limbs[i] = limbs[i] and int64(MASK_LIMB)
    limbs[i+1] += carry
    if carry == 0 and i >= stop: break


func joined(sum: var SumExact, special: Special) =
  ## Join special value into sum: same one stays, and two others give NaN; limbs then hold zero.
  sum.special = (if sum.special in {Special.None, special}: special else: Special.Nan)
  sum.limbs.reset


func add*(sum: var SumExact, value: float) =
  ## Add value to exact sum: 53 bits of finite value at its exponent, from `2^-1074`, or its special
  ##   value; zero of each sign adds none.
  case value.classify
  of fcNan: sum.joined Special.Nan
  of fcInf: sum.joined Special.Infinity
  of fcNegInf: sum.joined Special.InfinityNegative
  of fcZero, fcNegZero: discard
  of fcNormal, fcSubnormal:
    if sum.special != Special.None: return
    let
      bits = cast[uint64](value)
      biased = int((bits shr (BITS_MANTISSA - 1)) and MASK_EXPONENT)
      mantissa = (bits and MASK_FRACTION) or (if biased > 0: MASK_FRACTION + 1 else: 0)
      shift = max(biased - 1, 0)  # Normal value is mantissa × `2^(biased − 1075)`.
      (k, offset) = (shift div BITS_LIMB, shift mod BITS_LIMB)
      sign = (if value < 0: -1'i64 else: 1'i64)
    sum.limbs[k] += sign * int64((mantissa shl offset) and MASK_LIMB)
    sum.limbs[k+1] += sign * int64((mantissa shr (BITS_LIMB - offset)) and MASK_LIMB)
    if offset > 0: sum.limbs[k+2] += sign * int64(mantissa shr (2 * BITS_LIMB - offset))
    sum.limbs.carried(k, k + 2)


func add*(sum: var SumExact, other: SumExact) =
  ## Add other exact sum, so sum holds both exactly.
  if other.special != Special.None: sum.joined other.special
  if sum.special != Special.None: return
  for i in 0 ..< LIMBS_SUM: sum.limbs[i] += other.limbs[i]
  sum.limbs.carried(0, LIMBS_SUM - 2)


func toSumExact*(values: openArray[float]): SumExact =
  ## Exact sum of values.
  for value in values: result.add value


func bit(limbs: openArray[int64], at: int): uint64 =
  ## Bit `at` of integer whose limbs lie in `0 ..< 2^32`.
  uint64(limbs[at div BITS_LIMB] shr (at mod BITS_LIMB)) and 1


func isAnyBelow(limbs: openArray[int64], at: int): bool =
  ## Whether integer whose limbs lie in `0 ..< 2^32` sets any bit below bit `at`.
  for i in 0 ..< at div BITS_LIMB:
    if limbs[i] != 0: return true
  (limbs[at div BITS_LIMB] and ((1'i64 shl (at mod BITS_LIMB)) - 1)) != 0


func powerTwo(exponent: int): float =
  ## `2^exponent` from its bits, for exponent from `-1074` to `1023`: subnormal below `-1022`.
  if exponent >= EXPONENT_NORMAL: cast[float](uint64(exponent + BIAS) shl (BITS_MANTISSA - 1))
  else: cast[float](1'u64 shl (exponent - EXPONENT_LEAST))


func toFloat*(sum: SumExact): float =
  ## Round exact sum once, to nearest float, half to even, as policy of header gives it: 53 bits
  ##   from lead bit of integer, then bit below them, and any bit below that one, for tie.
  case sum.special
  of Special.Nan: return NaN
  of Special.Infinity: return Inf
  of Special.InfinityNegative: return -Inf
  of Special.None: discard
  let is_negative = sum.limbs[^1] < 0
  var magnitude = sum.limbs
  if is_negative:
    for limb in magnitude.mitems: limb = -limb
    magnitude.carried(0, LIMBS_SUM - 2)
  var top = LIMBS_SUM - 1
  while top >= 0 and magnitude[top] == 0: dec top
  if top < 0: return 0.0

  # Read lead bit; integer below 53 bits is float as it is, and past `BIT_TOP` is past range.
  let lead = BITS_LIMB * top + fastLog2(magnitude[top])
  var value: float
  if lead > BIT_TOP: value = Inf
  elif lead < BITS_MANTISSA:
    value = float(uint64(magnitude[0]) or (uint64(magnitude[1]) shl BITS_LIMB)) * TINY
  else:
    # Round 53 bits from lead bit, half to even; carry out of them moves lead bit up one.
    var
      mantissa = 0'u64
      at = lead
    for j in 0 ..< BITS_MANTISSA:
      mantissa = mantissa or (magnitude.bit(lead - j) shl (BITS_MANTISSA - 1 - j))
    let is_half = magnitude.bit(lead - BITS_MANTISSA) == 1
    if is_half and (magnitude.isAnyBelow(lead - BITS_MANTISSA) or (mantissa and 1) == 1):
      inc mantissa
      if mantissa == 1'u64 shl BITS_MANTISSA:
        mantissa = mantissa shr 1
        inc at
    # Product past range, as `2^52 × 2^972` where rounding carries past `BIT_TOP`, is infinity,
    #   as IEEE 754 rounds product past largest float.
    value = float(mantissa) * powerTwo(at - (BITS_MANTISSA - 1) + EXPONENT_LEAST)
  if is_negative: -value else: value


func isZero(sum: SumExact): bool =
  ## Whether sum is exact zero, with no special value.
  sum.special == Special.None and sum.limbs.allIt(it == 0)


func partials*(sum: SumExact): seq[float] =
  ## Canonical partials of sum, smallest first, whose exact sum is sum: nearest float of what
  ##   remains, from whole sum down, and largest float of its sign while what remains rounds past
  ##   range; one value for special value; none for zero. Partials in range share no bit.
  if sum.special != Special.None: return @[sum.toFloat]
  var rest = sum
  while not rest.isZero:
    var part = rest.toFloat
    if part.classify in {fcInf, fcNegInf}: part = (if part > 0: MAX else: -MAX)
    result.add part
    rest.add -part
  result.reverse
