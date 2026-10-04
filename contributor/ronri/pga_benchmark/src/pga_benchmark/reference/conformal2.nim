## Derive Lengyel's typed objects and hand-rolled operations of 2D conformal geometric algebra.
##   Reference every dense library operation is measured against at cga4d: each object holds
##   only components its grade can carry, and each operation spells only terms that survive.
##   Origin is e₃ and infinity e₄, as library's `Basis.origin` and `Basis.infinity` name them.
##   Scalar is `float`, as library's.
##
##   |------------|-------------------------------------------|-------------------------|
##   | Code       | Notation                                  | Library basis           |
##   |------------|-------------------------------------------|-------------------------|
##   | PointRound | 𝐚 = aˣe₁ + aʸe₂ + aʷe₃ + aᵘe₄             | E1 E2 E3 E4             |
##   | Dipole     | 𝐝 = carrier line 𝐠 + flat point 𝐩         | E23 E31 E12 E41 E42 E43 |
##   | Circle     | 𝐜 = cᵘe₃₂₁ + flat line (cˣ cʸ cʷ)         | E321 E423 E431 E412     |
##   | LineCarrier| 𝐠 = gˣe₂₃ + gʸe₃₁ + gʷe₁₂                 | E23 E31 E12             |
##   | PointFlat  | 𝐩 = pˣe₄₁ + pʸe₄₂ + pʷe₄₃                 | E41 E42 E43             |
##   | LineFlat   | 𝐥 = lˣe₄₂₃ + lʸe₄₃₁ + lʷe₄₁₂              | E423 E431 E412          |
##   | Antisc.    | t𝟙                                        | E1234                   |
##   |------------|-------------------------------------------|-------------------------|
##
##   Forms are derived, not transcribed: each one expands its definition in Lengyel's
##     exterior algebra, with metric e₁² = e₂² = 1 and e₃ ∙ e₄ = −1, on objects' components
##     alone. Expansion that derived them reproduced every product, complement, dual, part,
##     attitude, carrier, center, container and partner of library before any form was
##     read off. Terathon Math Library (MIT, Eric Lengyel) was read to cross-check layout;
##     nothing is copied from it.
##   Each operation's doc states multiply and add counts of its form, i.e. what optimal
##     code spends. No function calls another, so none fills result or checks error flag;
##     suite `Internal: Inspector` holds every reference function to that.
##   Cost: only round-object rows exist; flats are results of carriers, never operands.

{.experimental: "strictFuncs".}

import ./scalars

export scalars


type
  PointRound* = object
    ## Define round point 𝐚 with position x y, weight w and flat bulk u; grade 1.
    x*, y*, w*, u*: float
  LineCarrier* = object
    ## Define carrier line of dipole, i.e. its grade-2 part without e₄; normal x y, position w.
    x*, y*, w*: float
  PointFlat* = object  ## Define flat point 𝐩 with position x y and weight w; grade 2, contains e₄.
    x*, y*, w*: float
  Dipole* = object  ## Define dipole 𝐝 with carrier line g and flat part p; grade 2.
    g*: LineCarrier
    p*: PointFlat
  LineFlat* = object  ## Define flat line 𝐥 with normal x y and position w; grade 3, contains e₄.
    x*, y*, w*: float
  Circle* = object
    ## Define circle 𝐜 with carrier weight u, flat normal x y and flat position w; grade 3.
    u*, x*, y*, w*: float



#[ Exterior Products ]#

func wedge*(a, b: PointRound): Dipole {.inline.} =
  ## Join round points into dipole, i.e. 𝐚 ∧ 𝐛; 12 mul, 6 sub.
  Dipole(
    g: LineCarrier(x: a.y * b.w - a.w * b.y, y: a.w * b.x - a.x * b.w, w: a.x * b.y - a.y * b.x),
    p: PointFlat(x: a.u * b.x - a.x * b.u, y: a.u * b.y - a.y * b.u, w: a.u * b.w - a.w * b.u),
  )

func wedge*(d: Dipole, a: PointRound): Circle {.inline.} =
  ## Join dipole and round point into circle, i.e. 𝐝 ∧ 𝐚; 12 mul, 8 add.
  Circle(
    u: -(a.x * d.g.x) - a.y * d.g.y - a.w * d.g.w,
    x: a.u * d.g.x + a.w * d.p.y - a.y * d.p.w,
    y: a.u * d.g.y - a.w * d.p.x + a.x * d.p.w,
    w: a.u * d.g.w - a.x * d.p.y + a.y * d.p.x,
  )

func wedge*(a: PointRound, d: Dipole): Circle {.inline.} =
  ## Join round point and dipole, i.e. 𝐚 ∧ 𝐝 = 𝐝 ∧ 𝐚 since grades 1 and 2 commute; 12 mul, 8 add.
  Circle(
    u: -(d.g.x * a.x) - d.g.y * a.y - d.g.w * a.w,
    x: d.g.x * a.u + d.p.y * a.w - d.p.w * a.y,
    y: d.g.y * a.u - d.p.x * a.w + d.p.w * a.x,
    w: d.g.w * a.u - d.p.y * a.x + d.p.x * a.y,
  )

func wedge*(c: Circle, a: PointRound): Antiscalar {.inline.} =
  ## Join circle and round point in antiscalar measuring incidence, i.e. 𝐜 ∧ 𝐚; 4 mul, 3 add.
  Antiscalar(-(a.x * c.x) - a.y * c.y - a.w * c.w - a.u * c.u)

func wedge*(a: PointRound, c: Circle): Antiscalar {.inline.} =
  ## Join round point and circle, i.e. 𝐚 ∧ 𝐜 = −(𝐜 ∧ 𝐚); 4 mul, 3 add.
  Antiscalar(a.x * c.x + a.y * c.y + a.w * c.w + a.u * c.u)

func wedge*(d, f: Dipole): Antiscalar {.inline.} =
  ## Join dipoles in antiscalar measuring their crossing, i.e. 𝐝 ∧ 𝐟; 6 mul, 5 add.
  Antiscalar(
    -(d.g.x * f.p.x) - d.g.y * f.p.y - d.g.w * f.p.w - d.p.x * f.g.x - d.p.y * f.g.y -
        d.p.w * f.g.w,
  )

func wedgeAnti*(c, o: Circle): Dipole {.inline.} =
  ## Meet circles in dipole, i.e. 𝐜 ∨ 𝐨; 12 mul, 6 sub.
  Dipole(
    g: LineCarrier(x: c.x * o.u - c.u * o.x, y: c.y * o.u - c.u * o.y, w: c.w * o.u - c.u * o.w),
    p: PointFlat(x: c.w * o.y - c.y * o.w, y: c.x * o.w - c.w * o.x, w: c.y * o.x - c.x * o.y),
  )

func wedgeAnti*(c: Circle, d: Dipole): PointRound {.inline.} =
  ## Meet circle and dipole in round point, i.e. 𝐜 ∨ 𝐝; 12 mul, 8 add.
  PointRound(
    x: c.u * d.p.x + c.w * d.g.y - c.y * d.g.w,
    y: c.u * d.p.y - c.w * d.g.x + c.x * d.g.w,
    w: c.u * d.p.w - c.x * d.g.y + c.y * d.g.x,
    u: -(c.x * d.p.x) - c.y * d.p.y - c.w * d.p.w,
  )

func wedgeAnti*(d: Dipole, c: Circle): PointRound {.inline.} =
  ## Meet dipole and circle, i.e. 𝐝 ∨ 𝐜 = 𝐜 ∨ 𝐝 since antigrades 2 and 1 commute; 12 mul, 8 add.
  PointRound(
    x: d.p.x * c.u + d.g.y * c.w - d.g.w * c.y,
    y: d.p.y * c.u - d.g.x * c.w + d.g.w * c.x,
    w: d.p.w * c.u - d.g.y * c.x + d.g.x * c.y,
    u: -(d.p.x * c.x) - d.p.y * c.y - d.p.w * c.w,
  )

func wedgeAnti*(d, f: Dipole): float {.inline.} =
  ## Meet dipoles in scalar measuring their crossing, i.e. 𝐝 ∨ 𝐟; 6 mul, 5 add.
  -(d.g.x * f.p.x) - d.g.y * f.p.y - d.g.w * f.p.w - d.p.x * f.g.x - d.p.y * f.g.y -
      d.p.w * f.g.w

func wedgeAnti*(c: Circle, a: PointRound): float {.inline.} =
  ## Meet circle and round point in scalar measuring incidence, i.e. 𝐜 ∨ 𝐚; 4 mul, 3 add.
  -(a.x * c.x) - a.y * c.y - a.w * c.w - a.u * c.u

func wedgeAnti*(a: PointRound, c: Circle): float {.inline.} =
  ## Meet round point and circle, i.e. 𝐚 ∨ 𝐜 = −(𝐜 ∨ 𝐚); 4 mul, 3 add.
  a.x * c.x + a.y * c.y + a.w * c.w + a.u * c.u



#[ Inner Products ]#

func dot*(a, b: PointRound): float {.inline.} =
  ## Multiply round points through inner product, i.e. 𝐚 ∙ 𝐛; 4 mul, 3 add.
  a.x * b.x + a.y * b.y - a.w * b.u - a.u * b.w

func dot*(d, f: Dipole): float {.inline.} =
  ## Multiply dipoles through inner product, i.e. 𝐝 ∙ 𝐟; 6 mul, 5 add.
  d.g.w * f.g.w + d.g.x * f.p.y - d.g.y * f.p.x - d.p.w * f.p.w - d.p.x * f.g.y + d.p.y * f.g.x

func dot*(c, o: Circle): float {.inline.} =
  ## Multiply circles through inner product, i.e. 𝐜 ∙ 𝐨; 4 mul, 3 add.
  c.u * o.w + c.w * o.u - c.x * o.x - c.y * o.y

func dotAnti*(a, b: PointRound): Antiscalar {.inline.} =
  ## Multiply round points through inner antiproduct, i.e. 𝐚 ∘ 𝐛; 4 mul, 3 add.
  Antiscalar(a.u * b.w + a.w * b.u - a.x * b.x - a.y * b.y)

func dotAnti*(d, f: Dipole): Antiscalar {.inline.} =
  ## Multiply dipoles through inner antiproduct, i.e. 𝐝 ∘ 𝐟; 6 mul, 5 add.
  Antiscalar(
    d.p.w * f.p.w + d.p.x * f.g.y - d.p.y * f.g.x - d.g.w * f.g.w - d.g.x * f.p.y + d.g.y * f.p.x,
  )

func dotAnti*(c, o: Circle): Antiscalar {.inline.} =
  ## Multiply circles through inner antiproduct, i.e. 𝐜 ∘ 𝐨; 4 mul, 3 add.
  Antiscalar(c.x * o.x + c.y * o.y - c.u * o.w - c.w * o.u)



#[ Complements ]#

func complementRight*(a: PointRound): Circle {.inline.} =
  ## Get right complement 𝐚̅, i.e. same components read as circle; 0 mul.
  Circle(u: a.u, x: a.x, y: a.y, w: a.w)

func complementLeft*(a: PointRound): Circle {.inline.} =
  ## Get left complement 𝐚̲, i.e. components negated and read as circle; 0 mul.
  Circle(u: -a.u, x: -a.x, y: -a.y, w: -a.w)

func complementRight*(d: Dipole): Dipole {.inline.} =
  ## Get right complement 𝐝̅, i.e. carrier and flat parts swapped and negated; 0 mul.
  Dipole(
    g: LineCarrier(x: -d.p.x, y: -d.p.y, w: -d.p.w),
    p: PointFlat(x: -d.g.x, y: -d.g.y, w: -d.g.w),
  )

func complementLeft*(d: Dipole): Dipole {.inline.} =
  ## Get left complement 𝐝̲, equal to right one at grade 2 here; 0 mul.
  Dipole(
    g: LineCarrier(x: -d.p.x, y: -d.p.y, w: -d.p.w),
    p: PointFlat(x: -d.g.x, y: -d.g.y, w: -d.g.w),
  )

func complementRight*(c: Circle): PointRound {.inline.} =
  ## Get right complement 𝐜̅, i.e. components negated and read as round point; 0 mul.
  PointRound(x: -c.x, y: -c.y, w: -c.w, u: -c.u)

func complementLeft*(c: Circle): PointRound {.inline.} =
  ## Get left complement 𝐜̲, i.e. same components read as round point; 0 mul.
  PointRound(x: c.x, y: c.y, w: c.w, u: c.u)



#[ Reverses ]#

func reverse*(a: PointRound): PointRound {.inline.} =
  ## Get reverse 𝐚̃, i.e. round point unchanged at grade 1; 0 mul.
  PointRound(x: a.x, y: a.y, w: a.w, u: a.u)

func reverse*(d: Dipole): Dipole {.inline.} =
  ## Get reverse 𝐝̃, i.e. dipole negated at grade 2; 0 mul.
  Dipole(
    g: LineCarrier(x: -d.g.x, y: -d.g.y, w: -d.g.w),
    p: PointFlat(x: -d.p.x, y: -d.p.y, w: -d.p.w),
  )

func reverse*(c: Circle): Circle {.inline.} =
  ## Get reverse 𝐜̃, i.e. circle negated at grade 3; 0 mul.
  Circle(u: -c.u, x: -c.x, y: -c.y, w: -c.w)

func reverseAnti*(a: PointRound): PointRound {.inline.} =
  ## Get antireverse 𝐚̰, i.e. round point negated at antigrade 3; 0 mul.
  PointRound(x: -a.x, y: -a.y, w: -a.w, u: -a.u)

func reverseAnti*(d: Dipole): Dipole {.inline.} =
  ## Get antireverse 𝐝̰, i.e. dipole negated at antigrade 2; 0 mul.
  Dipole(
    g: LineCarrier(x: -d.g.x, y: -d.g.y, w: -d.g.w),
    p: PointFlat(x: -d.p.x, y: -d.p.y, w: -d.p.w),
  )

func reverseAnti*(c: Circle): Circle {.inline.} =
  ## Get antireverse 𝐜̰, i.e. circle unchanged at antigrade 1; 0 mul.
  Circle(u: c.u, x: c.x, y: c.y, w: c.w)



#[ Duals ]#

func dualBulk*(a: PointRound): Circle {.inline.} =
  ## Get bulk dual 𝐚★; 0 mul.
  Circle(u: -a.w, x: a.x, y: a.y, w: -a.u)

func dualWeight*(a: PointRound): Circle {.inline.} =
  ## Get weight dual 𝐚☆; 0 mul.
  Circle(u: a.w, x: -a.x, y: -a.y, w: a.u)

func dualBulk*(d: Dipole): Dipole {.inline.} =
  ## Get bulk dual 𝐝★; 0 mul.
  Dipole(
    g: LineCarrier(x: d.g.y, y: -d.g.x, w: d.p.w),
    p: PointFlat(x: -d.p.y, y: d.p.x, w: -d.g.w),
  )

func dualWeight*(d: Dipole): Dipole {.inline.} =
  ## Get weight dual 𝐝☆; 0 mul.
  Dipole(
    g: LineCarrier(x: -d.g.y, y: d.g.x, w: -d.p.w),
    p: PointFlat(x: d.p.y, y: -d.p.x, w: d.g.w),
  )

func dualBulk*(c: Circle): PointRound {.inline.} =
  ## Get bulk dual 𝐜★; 0 mul.
  PointRound(x: c.x, y: c.y, w: -c.u, u: -c.w)

func dualWeight*(c: Circle): PointRound {.inline.} =
  ## Get weight dual 𝐜☆; 0 mul.
  PointRound(x: -c.x, y: -c.y, w: c.u, u: c.w)



#[ Bulks and Weights ]#

func bulk*(a: PointRound): PointRound {.inline.} =
  ## Get round bulk 𝐚∙, i.e. position alone; 0 mul.
  PointRound(x: a.x, y: a.y, w: 0.0, u: 0.0)

func weight*(a: PointRound): PointRound {.inline.} =
  ## Get round weight 𝐚∘, i.e. weight alone; 0 mul.
  PointRound(x: 0.0, y: 0.0, w: a.w, u: 0.0)

func bulkFlat*(a: PointRound): PointRound {.inline.} =
  ## Get flat bulk 𝐚■, i.e. component on infinity alone; 0 mul.
  PointRound(x: 0.0, y: 0.0, w: 0.0, u: a.u)

func weightFlat*(a: PointRound): PointRound {.inline.} =
  ## Get flat weight 𝐚□, zero since no component holds both origin and infinity; 0 mul.
  PointRound(x: 0.0, y: 0.0, w: 0.0, u: 0.0)

func bulk*(d: Dipole): Dipole {.inline.} =
  ## Get round bulk 𝐝∙, i.e. carrier position alone; 0 mul.
  Dipole(g: LineCarrier(x: 0.0, y: 0.0, w: d.g.w), p: PointFlat(x: 0.0, y: 0.0, w: 0.0))

func weight*(d: Dipole): Dipole {.inline.} =
  ## Get round weight 𝐝∘, i.e. carrier normal alone; 0 mul.
  Dipole(g: LineCarrier(x: d.g.x, y: d.g.y, w: 0.0), p: PointFlat(x: 0.0, y: 0.0, w: 0.0))

func bulkFlat*(d: Dipole): Dipole {.inline.} =
  ## Get flat bulk 𝐝■, i.e. flat position alone; 0 mul.
  Dipole(g: LineCarrier(x: 0.0, y: 0.0, w: 0.0), p: PointFlat(x: d.p.x, y: d.p.y, w: 0.0))

func weightFlat*(d: Dipole): Dipole {.inline.} =
  ## Get flat weight 𝐝□, i.e. flat weight alone; 0 mul.
  Dipole(g: LineCarrier(x: 0.0, y: 0.0, w: 0.0), p: PointFlat(x: 0.0, y: 0.0, w: d.p.w))

func bulk*(c: Circle): Circle {.inline.} =
  ## Get round bulk 𝐜∙, zero since every component holds origin or infinity; 0 mul.
  Circle(u: 0.0, x: 0.0, y: 0.0, w: 0.0)

func weight*(c: Circle): Circle {.inline.} =
  ## Get round weight 𝐜∘, i.e. carrier weight alone; 0 mul.
  Circle(u: c.u, x: 0.0, y: 0.0, w: 0.0)

func bulkFlat*(c: Circle): Circle {.inline.} =
  ## Get flat bulk 𝐜■, i.e. flat position alone; 0 mul.
  Circle(u: 0.0, x: 0.0, y: 0.0, w: c.w)

func weightFlat*(c: Circle): Circle {.inline.} =
  ## Get flat weight 𝐜□, i.e. flat normal alone; 0 mul.
  Circle(u: 0.0, x: c.x, y: c.y, w: 0.0)



#[ Attitudes ]#

func attitude*(a: PointRound): float {.inline.} =
  ## Get attitude of round point, i.e. 𝐚 ∨ 𝐞̅₃, its weight as scalar; 0 mul.
  a.w

func attitude*(d: Dipole): PointRound {.inline.} =
  ## Get attitude of dipole, i.e. its direction and flat weight as round point; 0 mul.
  PointRound(x: d.g.y, y: -d.g.x, w: 0.0, u: -d.p.w)

func attitude*(c: Circle): Dipole {.inline.} =
  ## Get attitude of circle, i.e. its carrier weight and flat normal as dipole; 0 mul.
  Dipole(g: LineCarrier(x: 0.0, y: 0.0, w: -c.u), p: PointFlat(x: -c.y, y: c.x, w: 0.0))



#[ Carriers ]#

func carrier*(a: PointRound): PointFlat {.inline.} =
  ## Get carrier of round point, i.e. 𝐚 ∧ 𝐞₄, flat point at its position; 0 mul.
  PointFlat(x: -a.x, y: -a.y, w: -a.w)

func carrier*(d: Dipole): LineFlat {.inline.} =
  ## Get carrier of dipole, i.e. 𝐝 ∧ 𝐞₄, line through both its points; 0 mul.
  LineFlat(x: d.g.x, y: d.g.y, w: d.g.w)

func carrier*(c: Circle): Antiscalar {.inline.} =
  ## Get carrier of circle, i.e. 𝐜 ∧ 𝐞₄, whole plane scaled by carrier weight; 0 mul.
  Antiscalar(-c.u)

func carrierCo*(a: PointRound): Antiscalar {.inline.} =
  ## Get cocarrier of round point, i.e. 𝐚☆ ∧ 𝐞₄; 0 mul.
  Antiscalar(-a.w)

func carrierCo*(d: Dipole): LineFlat {.inline.} =
  ## Get cocarrier of dipole, i.e. 𝐝☆ ∧ 𝐞₄, line through center normal to carrier; 0 mul.
  LineFlat(x: -d.g.y, y: d.g.x, w: -d.p.w)

func carrierCo*(c: Circle): PointFlat {.inline.} =
  ## Get cocarrier of circle, i.e. 𝐜☆ ∧ 𝐞₄, flat point at its center; 0 mul.
  PointFlat(x: c.x, y: c.y, w: -c.u)



#[ Centers ]#

func center*(a: PointRound): PointRound {.inline.} =
  ## Get center of round point, i.e. 𝐚⊞ ∨ 𝐚, same point scaled by −w; 4 mul.
  PointRound(x: -(a.w * a.x), y: -(a.w * a.y), w: -(a.w * a.w), u: -(a.w * a.u))

func center*(d: Dipole): PointRound {.inline.} =
  ## Get center of dipole as round point with its radius; 9 mul, 5 add.
  PointRound(
    x: -(d.g.w * d.g.x) - d.g.y * d.p.w,
    y: d.g.x * d.p.w - d.g.w * d.g.y,
    w: d.g.x * d.g.x + d.g.y * d.g.y,
    u: d.p.w * d.p.w + d.g.y * d.p.x - d.g.x * d.p.y,
  )

func center*(c: Circle): PointRound {.inline.} =
  ## Get center of circle as round point with its radius; 6 mul, 2 add.
  PointRound(x: c.u * c.x, y: c.u * c.y, w: -(c.u * c.u), u: c.u * c.w - c.x * c.x - c.y * c.y)



#[ Containers ]#

func container*(a: PointRound): Circle {.inline.} =
  ## Get container of round point, i.e. 𝐚 ∧ (𝐚⊟)☆, circle of its radius; 6 mul, 2 add.
  Circle(u: -(a.w * a.w), x: a.w * a.x, y: a.w * a.y, w: a.u * a.w - a.x * a.x - a.y * a.y)

func container*(d: Dipole): Circle {.inline.} =
  ## Get container of dipole, i.e. circle on both its points about its center; 9 mul, 5 add.
  Circle(
    u: d.g.x * d.g.x + d.g.y * d.g.y,
    x: d.g.w * d.g.x + d.g.y * d.p.w,
    y: d.g.w * d.g.y - d.g.x * d.p.w,
    w: d.g.w * d.g.w + d.g.x * d.p.y - d.g.y * d.p.x,
  )

func container*(c: Circle): Circle {.inline.} =
  ## Get container of circle, i.e. same circle scaled by −u; 4 mul.
  Circle(u: -(c.u * c.u), x: -(c.u * c.x), y: -(c.u * c.y), w: -(c.u * c.w))



#[ Partners ]#

func partner*(a: PointRound): PointRound {.inline.} =
  ## Get partner of round point, i.e. same point with squared radius negated; 8 mul, 2 add.
  let w2 = a.w * a.w
  PointRound(x: a.x * w2, y: a.y * w2, w: a.w * w2, u: (a.x * a.x + a.y * a.y - a.u * a.w) * a.w)

func partner*(d: Dipole): Dipole {.inline.} =
  ## Get partner of dipole; 15 mul, 6 add.
  ##   Carrier and flat weight scale by ‖carrier normal‖²; flat position takes
  ##   f = gʷ² − pʷ² + gˣpʸ − gʸpˣ along normal and gʷpʷ across it.
  let
    s = d.g.x * d.g.x + d.g.y * d.g.y
    f = d.g.w * d.g.w - d.p.w * d.p.w + d.g.x * d.p.y - d.g.y * d.p.x
    h = d.g.w * d.p.w
  Dipole(
    g: LineCarrier(x: d.g.x * s, y: d.g.y * s, w: d.g.w * s),
    p: PointFlat(x: d.g.y * f - d.g.x * h, y: -(d.g.x * f) - d.g.y * h, w: d.p.w * s),
  )

func partner*(c: Circle): Circle {.inline.} =
  ## Get partner of circle, i.e. same circle with squared radius negated; 8 mul, 2 add.
  let u2 = c.u * c.u
  Circle(u: c.u * u2, x: c.x * u2, y: c.y * u2, w: (c.x * c.x + c.y * c.y - c.u * c.w) * c.u)
