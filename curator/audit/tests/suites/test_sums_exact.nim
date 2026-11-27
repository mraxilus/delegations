## Replicate exact sum of floats: rounding once to nearest float, as `math.fsum` of CPython rounds,
##   sum that takes no order, partials that share no bit, and each special value (#1049).
##   Each expected exact sum is case of `test_fsum` of `Lib/test/test_math.py` of CPython, whose
##     `math.fsum` rounds exact sum once, half to even, as `toFloat` does; Python 3 here gives each
##     to last bit.
##   Each special value takes policy of `sums_exact.nim` (Article IV.8): each pair against sum of
##     two floats in hardware, which rounds their exact sum once; each triple in each order; and
##     each sum past largest float against exact rationals of Python 3.13.18, computed apart on
##     2026-11-27, where `math.fsum` raises.

{.experimental: "strictFuncs".}

import std/[algorithm, bitops, math, random, sequtils, unittest]
import ../../src/sums_exact
import ./fixtures


const
  SAMPLES_SUM = 200  ## Random lists each law of exact sum reads.
  MAX = 1.7976931348623157e308  ## Largest float, `(2^53 − 1) × 2^971`.
  HALF = 9.9792015476736e291  ## Half of last bit of largest float, `2^970`.
  BIG = 8.98846567431158e307  ## Largest power of two that float holds, `2^1023`.
  TINY = 5e-324  ## Least float above zero, `2^-1074`.
  VALUES_SPECIAL = [NaN, Inf, -Inf, MAX, -MAX, BIG, -BIG, HALF, -HALF, 1.0, -1.0, TINY, -TINY, 0.0,
    -0.0]
    ## Values whose sums meet each policy: NaN, each infinity, overflow, its tie, and each zero.
  CASES_PAIR = VALUES_SPECIAL.len * VALUES_SPECIAL.len  ## Ordered pairs of `VALUES_SPECIAL`.
  CASES_TRIPLE = CASES_PAIR * VALUES_SPECIAL.len  ## Ordered triples of `VALUES_SPECIAL`.


func isSame(value, expected: float): bool =
  ## Whether floats agree to last bit, or both are NaN, whatever bits NaN carries.
  (value.isNaN and expected.isNaN) or value.bits == expected.bits


func bitLowest(value: float): float =
  ## Value of lowest bit that float sets: `value = fraction × 2^exponent`, and fraction holds
  ##   53 bits from 0.5.
  let
    (fraction, exponent) = frexp(abs(value))
    mantissa = uint64(fraction * pow(2.0, 53))
  pow(2.0, float(exponent - 53 + countTrailingZeroBits(mantissa)))



suite "exact sum":
  test "sum rounds once to nearest float, as `math.fsum` of CPython gives each case of its suite":
    let two = 2.0
    check toSumExact([]).toFloat.bits == 0.0.bits
    check toSumExact([0.0]).toFloat.bits == 0.0.bits
    check toSumExact([1e100, 1.0, -1e100, 1e-100, 1e50, -1.0, -1e50]).toFloat == 1e-100
    check toSumExact([two^53, -0.5, -pow(two, -54)]).toFloat == two^53 - 1
    check toSumExact([two^53, 1.0, pow(two, -100)]).toFloat == two^53 + 2  # tie breaks up
    check toSumExact([two^53 + 10, 1.0, pow(two, -100)]).toFloat == two^53 + 12
    check toSumExact([two^53 - 4, 0.5, pow(two, -54)]).toFloat == two^53 - 3
    check toSumExact(toSeq(1..1000).mapIt(1 / float(it))).toFloat == 7.485470860550345
    check toSumExact(toSeq(1..1000).mapIt(pow(-1.0, float(it)) / float(it))).toFloat ==
      -0.6926474305598203
    check toSumExact([1e16, 1.0, 1e-16]).toFloat == 10000000000000002.0
    check toSumExact([1e16 - 2, 1 - pow(two, -53), -(1e16 - 2), -(1 - pow(two, -53))]).toFloat == 0
    var values = toSeq(countup(-1074, 970, 2)).mapIt(
      pow(two, float(it)) - pow(two, float(it + 50)) + pow(two, float(it + 52)))
    values.add -pow(two, 1022)
    check toSumExact(values).toFloat == 1.3305602063564798e+292  # many partials at once
    check toSumExact(newSeqWith(10, 0.1)).toFloat == 1.0  # where naive sum gives 0.9999999999999999


  test "sum takes no order, and sum of two parts added equals sum of whole, to last bit":
    randomize(2026)
    for sample in 0 ..< SAMPLES_SUM:
      var values = newSeqWith(rand(1 .. 60), (rand(2.0) - 1) * pow(10.0, float(rand(-20 .. 20))))
      let
        whole = toSumExact(values).toFloat
        cut = rand(values.len)
      var joined = toSumExact(values[0 ..< cut])
      joined.add toSumExact(values[cut .. ^1])
      check joined.toFloat.bits == whole.bits
      values.shuffle
      check toSumExact(values).toFloat.bits == whole.bits


  test "partials share no bit, smallest first, and none is zero":
    randomize(2027)
    for sample in 0 ..< SAMPLES_SUM:
      let partials = toSumExact(newSeqWith(rand(1 .. 60), (rand(2.0) - 1) *
        pow(10.0, float(rand(-20 .. 20))))).partials
      for i, partial in partials:
        check partial != 0
        if i > 0: check abs(partials[i-1]) < partial.bitLowest  # below each bit partial sets



suite "special values":
  test "each value and each pair sum as hardware adds two floats, which rounds exact sum once":
    # Case as found on #1049: `[Inf, 1.0]` and `[1e308, 1e308]` gave NaN, where `math.fsum` gives
    #   `inf` and raises; Article IV.8. Domain: each pair of `VALUES_SPECIAL`. Exact zero is `0.0`,
    #   as `math.fsum` gives, where hardware gives `-0.0` for `-0.0 + -0.0`.
    var cases = 0
    for x in VALUES_SPECIAL:
      check toSumExact([x]).toFloat.isSame (if x == 0: 0.0 else: x)
      for y in VALUES_SPECIAL:
        inc cases
        check toSumExact([x, y]).toFloat.isSame (if x + y == 0: 0.0 else: x + y)
    check toSumExact([Inf, 1.0]).toFloat == Inf
    check toSumExact([1e308, 1e308]).toFloat == Inf
    check cases == CASES_PAIR


  test "each triple takes no order; NaN, or both infinities, give NaN, and one infinity itself":
    var cases = 0
    for x in VALUES_SPECIAL:
      for y in VALUES_SPECIAL:
        for z in VALUES_SPECIAL:
          inc cases
          let
            whole = toSumExact([x, y, z]).toFloat
            is_nan = [x, y, z].anyIt(it.isNaN)
            has_inf = [x, y, z].anyIt(it == Inf)
            has_inf_negative = [x, y, z].anyIt(it == -Inf)
          for order in [[x, z, y], [y, x, z], [y, z, x], [z, x, y], [z, y, x]]:
            check toSumExact(order).toFloat.isSame whole
          if is_nan or (has_inf and has_inf_negative): check whole.isNaN
          elif has_inf: check whole == Inf
          elif has_inf_negative: check whole == -Inf
          else: check not whole.isNaN  # finite values sum to float, or to infinity past range
    check cases == CASES_TRIPLE


  test "exact sum past largest float rounds to infinity of its sign, and comes back exactly":
    for (values, expected) in [
      (@[MAX, MAX, -MAX], MAX),
      (@[1e308, 1e308, -1e308], 1e308),
      (@[MAX, HALF, -TINY], MAX),  # below tie of largest float and `2^1024`
      (@[MAX, HALF / 2, HALF / 2], Inf),  # at that tie, which rounds to even
      (@[MAX, -HALF, TINY], MAX),
      (@[-MAX, -HALF, TINY], -MAX),
      (@[BIG, BIG, -BIG], BIG),
      (newSeqWith(1000, MAX) & newSeqWith(999, -MAX), MAX),
      (@[BIG, BIG, -MAX], 1.99584030953472e292),  # `2^971`
      (@[Inf, MAX, MAX], Inf),
      (@[-Inf, -MAX, -MAX], -Inf),
      (@[-MAX, -MAX, MAX, HALF], -1.7976931348623155e308),  # tie, to even
      (@[MAX, MAX, MAX, -MAX, -MAX, -HALF], 1.7976931348623155e308),
      (@[TINY, TINY, TINY], 1.5e-323),
    ]:
      check toSumExact(values).toFloat.isSame expected
      check toSumExact(values.reversed).toFloat.isSame expected


  test "partials of each sum read back as same sum, past largest float and at each special value":
    # Prior writes partials of each sum, and next roll adds to what it reads (#1049).
    for values in [@[MAX, MAX], @[MAX, MAX, MAX], @[MAX, HALF], @[Inf], @[-Inf], @[NaN],
        @[Inf, -Inf], @[1.0, NaN], @[-0.0], @[TINY, -TINY]]:
      let sum = toSumExact(values)
      check sum.partials.toSumExact.toFloat.isSame sum.toFloat
    var back = toSumExact([MAX, MAX]).partials.toSumExact
    back.add -MAX
    check back.toFloat == MAX  # sum past range stays exact through its partials
    # Sums of one value compare equal, as prior read back compares with prior written.
    check toSumExact([Inf, 1.0]) == toSumExact([Inf])
    check toSumExact([1.0, NaN, -Inf]) == toSumExact([NaN])
    check toSumExact([0.5, 0.25, -0.0]) == toSumExact([0.25, 0.5])
