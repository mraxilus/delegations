## Sum floats exactly, and round sum once to nearest float, as tallies of claims sum (#1049).
##   Sum is partials that share no bit, smallest first: each value added meets each partial as sum
##     and its error, both exact, and partial of error zero drops (Shewchuk, 1997; `msum` of
##     Python's `math.fsum`). So sum takes no order, and sum of two parts added equals sum of
##     whole, to last bit.
##   Sum rounds once, to nearest float, half to even, as `math.fsum` rounds partials.
##
##   Cost: each value added meets each of its partials, as few as bits of sum span allow; naive sum
##     would meet one.

{.experimental: "strictFuncs".}


type SumExact* = object  ## Define exact sum of floats: partials that share no bit, smallest first.
  partials*: seq[float]  ## Floats whose exact sum is sum.


func add*(sum: var SumExact, value: float) =
  ## Add value to exact sum: each partial meets value as sum and its error, both exact, and partial
  ##   of error zero drops (Shewchuk, 1997; `msum` of Python's `math.fsum`). Partials then share no
  ##   bit, smallest first; exact compare of floats is point of each step.
  var
    x = value
    kept = 0
  for i in 0 ..< sum.partials.len:
    var y = sum.partials[i]
    if abs(x) < abs(y): swap(x, y)
    let
      high = x + y
      low = y - (high - x)
    if low != 0:
      sum.partials[kept] = low
      inc kept
    x = high
  sum.partials.setLen(kept)
  if x != 0: sum.partials.add x


func add*(sum: var SumExact, other: SumExact) =
  ## Add each partial of other exact sum, so sum holds both exactly.
  for partial in other.partials: sum.add partial


func toSumExact*(values: openArray[float]): SumExact =
  ## Exact sum of values, added in order.
  for value in values: result.add value


func toFloat*(sum: SumExact): float =
  ## Round exact sum once, to nearest float, half to even, as Python's `math.fsum` rounds partials.
  ##   Sum runs down from largest partial until it turns inexact; partial below then breaks tie of
  ##     half way, as `fsum` gives `1e16 + 2` for `1e16`, `1` and `1e-16`.
  var at = sum.partials.len
  if at == 0: return 0
  dec at
  var
    high = sum.partials[at]
    low = 0.0
  while at > 0:
    let x = high
    dec at
    let y = sum.partials[at]
    high = x + y
    low = y - (high - x)
    if low != 0: break
  if at > 0 and ((low < 0 and sum.partials[at-1] < 0) or (low > 0 and sum.partials[at-1] > 0)):
    let
      y = low * 2
      x = high + y
    if y == x - high: high = x
  high
