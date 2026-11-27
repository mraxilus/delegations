## Replicate exact sum of floats: rounding once to nearest float, as `math.fsum` of CPython rounds,
##   sum that takes no order, and partials that share no bit (#1049).
##   Each expected exact sum is case of `test_fsum` of `Lib/test/test_math.py` of CPython, whose
##     `math.fsum` rounds partials as `toFloat` does; Python 3 here gives each to last bit.

{.experimental: "strictFuncs".}

import std/[bitops, math, random, sequtils, unittest]
import ../../src/sums_exact
import ./fixtures


const SAMPLES_SUM = 200  ## Random lists each law of exact sum reads.


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
