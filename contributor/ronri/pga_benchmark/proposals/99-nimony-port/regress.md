# Regression program

This program prints each Cayley table and each operator of `pga` on fixed inputs, with each
coefficient as its raw bits. So the library under Nim 2.4.0 and the port under Nimony compare
byte for byte. The same source builds under both compilers.

It stands here as Markdown, and not as a module of the repository. Nimony refuses
`{.experimental: "strictFuncs".}`, which `STYLE.md` §2 asks of every module. To run it, save the
fence below as `regress.nim`. Then build it under each compiler, with `-d:pga.dimensions` and
`-d:pga.is_conformal` of each algebra, and compare the two outputs.

```nim
## Print each Cayley table and each operator of `pga` on fixed INPUTS, coefficients as raw
##   bits, so reference under Nim 2 and port under Nimony compare byte for byte.
##   Same source compiles under both; INPUTS come from xorshift, not `std/random`.

import std/[options, syncio]
import pga



#[ Output ]#

proc bits(c: Coefficient): string = $cast[int64](float64(c))
  ## Spell coefficient as its raw bits, i.e. exact.

proc show(name: string, m: Multivector) =
  ## Print multivector coefficients in `Basis` order.
  var line = name
  for b in Basis: line.add " " & bits(m[b])
  echo line

proc show(name: string, s: MultivectorScalars) =
  ## Print dual number coefficients.
  echo name, " ", bits(s[Basis.scalar]), " ", bits(s[Basis.scalarAnti])

proc show(name: string, cayley: Cayley1D) =
  ## Print each signed term of 1D table, in `Basis` order.
  var line = name
  for b in Basis:
    line.add " |"
    for t in cayley[b]: line.add " " & (if t.is_negated: "-" else: "+") & $ord(t.basis)
  echo line

proc show(name: string, cayley: Cayley2D) =
  ## Print each signed term of 2D table, row by row.
  for m in Basis:
    show(name & "[" & $ord(m) & "]", cayley[m])



#[ Inputs ]#

var STATE = 88172645463325252'u64  ## State of xorshift, so each run draws same INPUTS.

proc next(state: var uint64): Coefficient =
  ## Draw coefficient in -2..2 through xorshift64.
  ##   State passes as parameter: Nimony forbids unsynchronized global access in routine.
  state = state xor (state shl 13)
  state = state xor (state shr 7)
  state = state xor (state shl 17)
  Coefficient(float(state shr 11) / float(1'u64 shl 53) * 4.0 - 2.0)

proc sample(state: var uint64, grade = -1): Multivector =
  ## Draw multivector, of single grade where `grade` is given.
  result = default(Multivector)
  for b in Basis:
    if grade < 0 or int(b.grade) == grade: result[b] = next(state)

var INPUTS: seq[(string, Multivector)] = @[]  ## Named INPUTS every operator runs on.
for b in Basis: INPUTS.add ("b" & $ord(b), initElement(b))
for i in 0..<6: INPUTS.add ("r" & $i, sample(STATE))
for g in 0..DIMENSIONS:
  for i in 0..<2: INPUTS.add ("g" & $g & "_" & $i, sample(STATE, g))



#[ Cayley Tables ]#

show("COMPLEMENT.left", CAYLEYS_COMPLEMENT.left)
show("COMPLEMENT.right", CAYLEYS_COMPLEMENT.right)
show("PARTS.bulk.round", CAYLEYS_PARTS.bulk.round)
show("PARTS.weight.round", CAYLEYS_PARTS.weight.round)
when IS_CONFORMAL:
  show("PARTS.bulk.flat", CAYLEYS_PARTS.bulk.flat)
  show("PARTS.weight.flat", CAYLEYS_PARTS.weight.flat)
show("REVERSE.base", CAYLEYS_REVERSE.base)
show("REVERSE.anti", CAYLEYS_REVERSE.anti)
show("METRIC", CAYLEY_METRIC)
show("EXOMORPHISM_METRIC.base", CAYLEYS_EXOMORPHISM_METRIC.base)
show("EXOMORPHISM_METRIC.anti", CAYLEYS_EXOMORPHISM_METRIC.anti)
show("WEDGE.base", CAYLEYS_WEDGE.base)
show("WEDGE.anti", CAYLEYS_WEDGE.anti)
show("DUAL.base.left", CAYLEYS_DUAL.base.left)
show("DUAL.base.right", CAYLEYS_DUAL.base.right)
show("DUAL.anti.left", CAYLEYS_DUAL.anti.left)
show("DUAL.anti.right", CAYLEYS_DUAL.anti.right)
show("INTERIOR.base.bulk.left", CAYLEYS_INTERIOR.base.bulk.left)
show("INTERIOR.base.bulk.right", CAYLEYS_INTERIOR.base.bulk.right)
show("INTERIOR.base.weight.left", CAYLEYS_INTERIOR.base.weight.left)
show("INTERIOR.base.weight.right", CAYLEYS_INTERIOR.base.weight.right)
show("INTERIOR.anti.bulk.left", CAYLEYS_INTERIOR.anti.bulk.left)
show("INTERIOR.anti.bulk.right", CAYLEYS_INTERIOR.anti.bulk.right)
show("INTERIOR.anti.weight.left", CAYLEYS_INTERIOR.anti.weight.left)
show("INTERIOR.anti.weight.right", CAYLEYS_INTERIOR.anti.weight.right)
show("DOT.base", CAYLEYS_DOT.base)
show("DOT.anti", CAYLEYS_DOT.anti)
show("WEDGE_DOT.base", CAYLEYS_WEDGE_DOT.base)
show("WEDGE_DOT.anti", CAYLEYS_WEDGE_DOT.anti)
show("NORM_SQUARED.bulk.round", CAYLEYS_NORM_SQUARED.bulk.round)
show("NORM_SQUARED.weight.round", CAYLEYS_NORM_SQUARED.weight.round)
when IS_CONFORMAL:
  show("NORM_SQUARED.bulk.flat", CAYLEYS_NORM_SQUARED.bulk.flat)
  show("NORM_SQUARED.weight.flat", CAYLEYS_NORM_SQUARED.weight.flat)
  show("NORM_SQUARED_RADIUS", CAYLEYS_NORM_SQUARED_RADIUS)
  show("CARRIER", CAYLEY_CARRIER)
show("ATTITUDE", CAYLEY_ATTITUDE)



#[ Operators ]#

for (name, m) in INPUTS:
  # Extraction and unary operators.
  show("∙" & name, ∙m)
  show("∘" & name, ∘m)
  show("/" & name, /m)
  show("\\" & name, \m)
  show("~" & name, ~m)
  show("~∘" & name, ~∘m)
  show("★" & name, ★m)
  show("☆" & name, ☆m)
  show("-" & name, -m)
  show("⊖" & name, ⊖m)
  show("|∙²" & name, `|∙²`m)
  show("|∘²" & name, `|∘²`m)
  show("|∙" & name, |∙m)
  show("|∘" & name, |∘m)
  show("|" & name, |m)
  show("^∙" & name, ^∙m)
  show("^∘" & name, ^∘m)
  show("^" & name, ^m)
  show("selectElement" & name, initElement(Basis.scalar, m.selectElement(Basis.scalarAnti)))
  for g in 0..DIMENSIONS:
    show("{" & $g & "}" & name, m{Grade(g)})
    show("{anti" & $g & "}" & name, m{GradeAnti(g)})
    show("selectGrade" & $g & name, m.selectGrade(Grade(g)))
  when IS_RIGID:
    show("∩" & name, ∩m)
    show("∪" & name, ∪m)
    show("bulk" & name, m.bulk)
    show("weight" & name, m.weight)
    show("normBulk" & name, m.normBulk)
    show("normWeight" & name, m.normWeight)
    show("support" & name, m.support)
    show("supportAnti" & name, m.supportAnti)
  when IS_CONFORMAL:
    show("■" & name, ■m)
    show("□" & name, □m)
    show("|■²" & name, `|■²`m)
    show("|□²" & name, `|□²`m)
    show("|⊘²" & name, `|⊘²`m)
    show("|■" & name, |■m)
    show("|□" & name, |□m)
    show("|⊘" & name, |⊘m)
    show("⊟" & name, ⊟m)
    show("⊞" & name, ⊞m)
    show("⊙" & name, ⊙m)
    show("⊡" & name, ⊡m)
    if not m.isMixed: show("⊛" & name, ⊛m)
  show("complementLeft" & name, m.complementLeft)
  show("dualBulk" & name, m.dualBulk)
  show("reverseAnti" & name, m.reverseAnti)
  show("norm" & name, m.norm)
  show("unitize" & name, m.unitize)
  show("attitude" & name, m.attitude)
  show("toMultivectorScalars" & name, (|m).toMultivector.toMultivectorScalars)
  show("normalizeBulk" & name, m.normalizeBulk)
  show("normalizeWeight" & name, m.normalizeWeight)
  show("complementRight" & name, m.complementRight)
  show("dualWeight" & name, m.dualWeight)
  show("negate" & name, m.negate)
  show("reverse" & name, m.reverse)
  for g in 0..DIMENSIONS:
    show("selectGradeAnti" & $g & name, m.selectGradeAnti(GradeAnti(g)))
  when IS_CONFORMAL:
    show("bulkFlat" & name, m.bulkFlat)
    show("bulkRound" & name, m.bulkRound)
    show("weightFlat" & name, m.weightFlat)
    show("weightRound" & name, m.weightRound)
    show("normBulkRound" & name, m.normBulkRound)
    show("normWeightRound" & name, m.normWeightRound)
    show("normBulkFlat" & name, m.normBulkFlat)
    show("normWeightFlat" & name, m.normWeightFlat)
    show("normRadius" & name, m.normRadius)
    show("carrier" & name, m.carrier)
    show("carrierCo" & name, m.carrierCo)
    show("center" & name, m.center)
    show("container" & name, m.container)
    if not m.isMixed: show("partner" & name, m.partner)
  echo "$", name, " ", $m
  echo "grade", name, " ", (if m.grade.isSome: $int(m.grade.get) else: "none"),
    " ", (if m.gradeAnti.isSome: $int(m.gradeAnti.get) else: "none"), " ", m.isMixed
  echo "=~", name, " ", m =~ m, " ", m =~ 0.0, " ", 1.5 =~ m

  # Scalar products.
  let s = Coefficient(1.25)
  show("s∧" & name, s ∧ m)
  show("∧s" & name, m ∧ s)
  show("s*" & name, s * m)
  show("*s" & name, m * s)
  show("s+" & name, s + m)
  show("+s" & name, m + s)
  show("s-" & name, s - m)
  show("-s" & name, m - s)
  show("add(m,s)" & name, add(m, s))
  show("add(s,m)" & name, add(s, m))
  show("subtract(m,s)" & name, subtract(m, s))
  show("subtract(s,m)" & name, subtract(s, m))
  show("wedge(m,s)" & name, wedge(m, s))
  show("wedge(s,m)" & name, wedge(s, m))

for (a, m) in INPUTS:
  for (b, n) in INPUTS:
    let pair = a & "," & b
    show("+" & pair, m + n)
    show("-" & pair, m - n)
    show("∧" & pair, m ∧ n)
    show("∨" & pair, m ∨ n)
    show("∙" & pair, m ∙ n)
    show("∘" & pair, m ∘ n)
    show("⟑" & pair, m ⟑ n)
    show("⟇" & pair, m ⟇ n)
    show("∧★" & pair, m ∧★ n)
    show("∧☆" & pair, m ∧☆ n)
    show("∨★" & pair, m ∨★ n)
    show("∨☆" & pair, m ∨☆ n)
    show("projectCentral" & pair, projectCentral(m, n))
    show("projectCentralAnti" & pair, projectCentralAnti(m, n))
    show("projectOrthogonal" & pair, projectOrthogonal(m, n))
    show("projectOrthogonalAnti" & pair, projectOrthogonalAnti(m, n))

# Binary aliases, on full samples only: each is one-line wrapper of operator above.
for (a, m) in INPUTS:
  if a[0] != 'r': continue
  for (b, n) in INPUTS:
    if b[0] != 'r': continue
    let pair = a & "," & b
    show("add" & pair, add(m, n))
    show("dot" & pair, dot(m, n))
    show("dotAnti" & pair, dotAnti(m, n))
    show("subtract" & pair, subtract(m, n))
    show("wedge" & pair, wedge(m, n))
    show("wedgeAnti" & pair, wedgeAnti(m, n))
    show("wedgeDot" & pair, wedgeDot(m, n))
    show("wedgeDotAnti" & pair, wedgeDotAnti(m, n))
    show("contractBulk" & pair, contractBulk(m, n))
    show("contractWeight" & pair, contractWeight(m, n))
    show("expandBulk" & pair, expandBulk(m, n))
    show("expandWeight" & pair, expandWeight(m, n))



#[ Subsets ]#

proc fill[B: static Bases](s: var MultivectorOf[B], m: Multivector) =
  ## Copy coefficients of bases in `B` from full multivector, then double each in place.
  for b in Basis:
    if b in B:
      s[b] = m[b]
      s[b] *= Coefficient(2.0)

proc showSubset[B: static Bases](name: string, s: MultivectorOf[B]) =
  ## Print coefficients of bases in `B` through subset index, then as full multivector.
  var line = name
  for b in Basis:
    if b in B: line.add " " & bits(s[b])
  echo line
  show(name & ">full", s.toMultivector)

proc widen[A, B: static Bases](s: MultivectorOf[A], t: MultivectorOf[B]): MultivectorOf[B] =
  ## Convert `s` to form of `t`, which holds every basis of `s`.
  toMultivectorOf[A, B](s)

proc checkSubset[A, B: static Bases](
  label: string, s: var MultivectorOf[A], u: MultivectorOf[B], m: Multivector
) =
  ## Exercise subset form of `s` on `m`: index, sum, comparison, and widening to form of `u`.
  fill(s, m)
  showSubset(label, s)
  showSubset(label & "+", s + s)
  echo label, "=~ ", s =~ s, " ", s =~ (s + s)
  showSubset(label & ">wide", widen(s, u))

for (name, m) in INPUTS:
  var s0 = default(Multivector0)
  checkSubset("M0" & name, s0, default(MultivectorEven), m)
  var s1 = default(Multivector1)
  checkSubset("M1" & name, s1, default(MultivectorOdd), m)
  var s2 = default(Multivector2)
  checkSubset("M2" & name, s2, default(MultivectorEven), m)
  var even = default(MultivectorEven)
  checkSubset("Even" & name, even, default(Multivector), m)
  var odd = default(MultivectorOdd)
  checkSubset("Odd" & name, odd, default(Multivector), m)
  var scalars = default(MultivectorScalars)
  checkSubset("Scalars" & name, scalars, default(Multivector), m)

for g in 0..DIMENSIONS:
  let bases = LUT_BASES_BY_GRADE[Grade(g)]
  echo "LUT_BASES_BY_GRADE ", g, " ", ord(bases.a), " ", ord(bases.b)



#[ Formatting ]#

for x in [
  1e-5, 1.5e7, -0.0, 0.0, 2.0 * float(TOLERANCE_ABS), 0.5 * float(TOLERANCE_ABS), 123456.7,
  -1.0, 1e100,
]:
  echo "$scalar ", $initElement(Basis.scalar, Coefficient(x))
  echo "$e1 ", $initElement(Basis.scalar.succ, Coefficient(x))
  echo "$mixed ",
    $(initElement(Basis.scalar, Coefficient(x)) + initElement(Basis.scalarAnti, Coefficient(-x)))


# Constructors and subtypes.
show("e1", e1(Coefficient(1.5)))
show("e1lit", e1("1.5"))
show("e12", e12(Coefficient(-2.0)))
echo "sizes ", sizeof(Multivector) div sizeof(Coefficient), " ",
  sizeof(MultivectorScalars) div sizeof(Coefficient), " ",
  sizeof(Multivector0) div sizeof(Coefficient), " ",
  sizeof(Multivector1) div sizeof(Coefficient), " ",
  sizeof(Multivector2) div sizeof(Coefficient), " ",
  sizeof(MultivectorEven) div sizeof(Coefficient), " ",
  sizeof(MultivectorOdd) div sizeof(Coefficient)



#[ Generated API, Grades and Near Tolerance ]#

# Last section: output above stays line for line that of version without it.

echo "config ", DIMENSIONS, " ", IS_CONFORMAL, " ", IS_RIGID, " ", FLOAT_WIDTH, " ",
  FLOAT_TOLERANCE, " ", bits(TOLERANCE_ABS), " ", sizeof(Coefficient)
for b in Basis:
  echo "basis ", ord(b), " ", $b, " ", int(b.grade), " ", int(b.gradeAnti)
echo "aliases ", $Basis.origin, " ", $Basis.vectorLast, " ", $Basis.scalar, " ",
  $Basis.scalarAnti, " ", $Basis.low, " ", $Basis.high
when IS_CONFORMAL: echo "infinity ", $Basis.infinity

# Aliases, conversion, arithmetic and comparison of (anti)grades.
echo "grades ", int(Grade.low), " ", int(Grade.high), " ", int(GradeAnti.low), " ",
  int(GradeAnti.high), " ", int(Grade.scalar), " ", int(Grade.scalarAnti), " ",
  int(GradeAnti.scalar), " ", int(GradeAnti.scalarAnti), " ", int(Grade.vector), " ",
  int(Grade.vectorAnti), " ", int(GradeAnti.vector), " ", int(GradeAnti.vectorAnti)
for g in 0..DIMENSIONS:
  echo "toAnti ", g, " ", int(Grade(g).toAnti), " ", int(GradeAnti(g).toBase)
  for h in 0..DIMENSIONS:
    block:
      let (a, b) = (Grade(g), Grade(h))
      echo "Grade ", g, " ", h, " ", int(a - b), " ", int(a * b), " ", int(a + b), " ", a < b, " ",
        a <= b, " ", a == b, " ", a != b, " ", a > b, " ", a >= b
    block:
      let (a, b) = (GradeAnti(g), GradeAnti(h))
      echo "GradeAnti ", g, " ", h, " ", int(a - b), " ", int(a * b), " ", int(a + b), " ", a <
          b, " ",
        a <= b, " ", a == b, " ", a != b, " ", a > b, " ", a >= b

# Cells of tables: length, text, and terms by position.
proc showCells(name: string, cayley: Cayley1D) =
  ## Print length, `$` and each term by position of each cell.
  for b in Basis:
    var line = name & "[" & $b & "] " & $cayley[b].len & " " & $cayley[b]
    for i in 0..<cayley[b].len:
      line.add " " & $cayley[b][i].basis & (if cayley[b][i].is_negated: "-" else: "+")
    echo line

showCells("$METRIC", CAYLEY_METRIC)
showCells("$COMPLEMENT.left", CAYLEYS_COMPLEMENT.left)
block:
  let
    a = BasisSigned(basis: Basis.scalar)
    b = BasisSigned(basis: Basis.scalarAnti, is_negated: true)
  echo "BasisSigned ", $a, " ", $b, " ", a == b, " ", a == a
  let
    pair = Chiral[int](left: 1, right: 2)
    spatial = Spatial[int](base: 3, anti: 4)
    partial = Partial[int](bulk: 5, weight: 6)
  echo "containers ", pair.left, pair.right, spatial.base, spatial.anti, partial.bulk,
    partial.weight

# Compound assignment through `[]`, on full multivector and on subset.
block:
  var r = default(Multivector)
  for (name, m) in INPUTS:
    if name == "r0": r = m
  var m = r
  m[Basis.scalar] += Coefficient(0.5)
  m[Basis.scalarAnti] -= Coefficient(0.25)
  m[Basis.origin] /= Coefficient(3.0)
  m[Basis.scalar.succ] *= Coefficient(-7.0)
  for b in Basis: m[b] += r[b]
  show("compound", m)
  var s = default(MultivectorScalars)
  s[Basis.scalar] += Coefficient(1.5)
  s[Basis.scalarAnti] -= Coefficient(0.25)
  s[Basis.scalar] *= Coefficient(3.0)
  s[Basis.scalarAnti] /= Coefficient(8.0)
  showSubset("compound scalars", s)

# Each basis constructor, by coefficient and by literal; each call form once.
#   One line per basis: Nimony checks template body at definition, so it calls no parameter.
proc showNonzero(name: string, m: Multivector) =
  ## Print name and coefficient of each basis that is not zero.
  var line = name
  for b in Basis:
    if m[b] != Coefficient(0.0): line.add " " & $b & "=" & bits(m[b])
  echo line

showNonzero("e1", e1(Coefficient(1.5))); showNonzero("e1 lit", e1("-2.5"))
showNonzero("e2", e2(Coefficient(1.5))); showNonzero("e2 lit", e2("-2.5"))
showNonzero("e12", e12(Coefficient(1.5))); showNonzero("e12 lit", e12("-2.5"))
when DIMENSIONS >= 3:
  showNonzero("e3", e3(Coefficient(1.5))); showNonzero("e3 lit", e3("-2.5"))
  showNonzero("e23", e23(Coefficient(1.5))); showNonzero("e23 lit", e23("-2.5"))
  showNonzero("e31", e31(Coefficient(1.5))); showNonzero("e31 lit", e31("-2.5"))
  showNonzero("e321", e321(Coefficient(1.5))); showNonzero("e321 lit", e321("-2.5"))
when DIMENSIONS >= 4:
  showNonzero("e4", e4(Coefficient(1.5))); showNonzero("e4 lit", e4("-2.5"))
  showNonzero("e41", e41(Coefficient(1.5))); showNonzero("e41 lit", e41("-2.5"))
  showNonzero("e42", e42(Coefficient(1.5))); showNonzero("e42 lit", e42("-2.5"))
  showNonzero("e43", e43(Coefficient(1.5))); showNonzero("e43 lit", e43("-2.5"))
  showNonzero("e423", e423(Coefficient(1.5))); showNonzero("e423 lit", e423("-2.5"))
  showNonzero("e431", e431(Coefficient(1.5))); showNonzero("e431 lit", e431("-2.5"))
  showNonzero("e412", e412(Coefficient(1.5))); showNonzero("e412 lit", e412("-2.5"))
  showNonzero("e1234", e1234(Coefficient(1.5))); showNonzero("e1234 lit", e1234("-2.5"))
when DIMENSIONS >= 5:
  showNonzero("e5", e5(Coefficient(1.5))); showNonzero("e5 lit", e5("-2.5"))
  showNonzero("e15", e15(Coefficient(1.5))); showNonzero("e15 lit", e15("-2.5"))
  showNonzero("e25", e25(Coefficient(1.5))); showNonzero("e25 lit", e25("-2.5"))
  showNonzero("e35", e35(Coefficient(1.5))); showNonzero("e35 lit", e35("-2.5"))
  showNonzero("e45", e45(Coefficient(1.5))); showNonzero("e45 lit", e45("-2.5"))
  showNonzero("e415", e415(Coefficient(1.5))); showNonzero("e415 lit", e415("-2.5"))
  showNonzero("e425", e425(Coefficient(1.5))); showNonzero("e425 lit", e425("-2.5"))
  showNonzero("e435", e435(Coefficient(1.5))); showNonzero("e435 lit", e435("-2.5"))
  showNonzero("e235", e235(Coefficient(1.5))); showNonzero("e235 lit", e235("-2.5"))
  showNonzero("e315", e315(Coefficient(1.5))); showNonzero("e315 lit", e315("-2.5"))
  showNonzero("e125", e125(Coefficient(1.5))); showNonzero("e125 lit", e125("-2.5"))
  showNonzero("e4235", e4235(Coefficient(1.5))); showNonzero("e4235 lit", e4235("-2.5"))
  showNonzero("e4315", e4315(Coefficient(1.5))); showNonzero("e4315 lit", e4315("-2.5"))
  showNonzero("e4125", e4125(Coefficient(1.5))); showNonzero("e4125 lit", e4125("-2.5"))
  showNonzero("e3215", e3215(Coefficient(1.5))); showNonzero("e3215 lit", e3215("-2.5"))
  showNonzero("e12345", e12345(Coefficient(1.5))); showNonzero("e12345 lit", e12345("-2.5"))
when DIMENSIONS >= 6:
  showNonzero("e6", e6(Coefficient(1.5))); showNonzero("e6 lit", e6("-2.5"))
  showNonzero("e16", e16(Coefficient(1.5))); showNonzero("e16 lit", e16("-2.5"))
  showNonzero("e26", e26(Coefficient(1.5))); showNonzero("e26 lit", e26("-2.5"))
  showNonzero("e36", e36(Coefficient(1.5))); showNonzero("e36 lit", e36("-2.5"))
  showNonzero("e46", e46(Coefficient(1.5))); showNonzero("e46 lit", e46("-2.5"))
  showNonzero("e56", e56(Coefficient(1.5))); showNonzero("e56 lit", e56("-2.5"))
  showNonzero("e416", e416(Coefficient(1.5))); showNonzero("e416 lit", e416("-2.5"))
  showNonzero("e426", e426(Coefficient(1.5))); showNonzero("e426 lit", e426("-2.5"))
  showNonzero("e436", e436(Coefficient(1.5))); showNonzero("e436 lit", e436("-2.5"))
  showNonzero("e236", e236(Coefficient(1.5))); showNonzero("e236 lit", e236("-2.5"))
  showNonzero("e316", e316(Coefficient(1.5))); showNonzero("e316 lit", e316("-2.5"))
  showNonzero("e126", e126(Coefficient(1.5))); showNonzero("e126 lit", e126("-2.5"))
  showNonzero("e156", e156(Coefficient(1.5))); showNonzero("e156 lit", e156("-2.5"))
  showNonzero("e256", e256(Coefficient(1.5))); showNonzero("e256 lit", e256("-2.5"))
  showNonzero("e356", e356(Coefficient(1.5))); showNonzero("e356 lit", e356("-2.5"))
  showNonzero("e456", e456(Coefficient(1.5))); showNonzero("e456 lit", e456("-2.5"))
  showNonzero("e4236", e4236(Coefficient(1.5))); showNonzero("e4236 lit", e4236("-2.5"))
  showNonzero("e4316", e4316(Coefficient(1.5))); showNonzero("e4316 lit", e4316("-2.5"))
  showNonzero("e4126", e4126(Coefficient(1.5))); showNonzero("e4126 lit", e4126("-2.5"))
  showNonzero("e3216", e3216(Coefficient(1.5))); showNonzero("e3216 lit", e3216("-2.5"))
  showNonzero("e4156", e4156(Coefficient(1.5))); showNonzero("e4156 lit", e4156("-2.5"))
  showNonzero("e4256", e4256(Coefficient(1.5))); showNonzero("e4256 lit", e4256("-2.5"))
  showNonzero("e4356", e4356(Coefficient(1.5))); showNonzero("e4356 lit", e4356("-2.5"))
  showNonzero("e2356", e2356(Coefficient(1.5))); showNonzero("e2356 lit", e2356("-2.5"))
  showNonzero("e3156", e3156(Coefficient(1.5))); showNonzero("e3156 lit", e3156("-2.5"))
  showNonzero("e1256", e1256(Coefficient(1.5))); showNonzero("e1256 lit", e1256("-2.5"))
  showNonzero("e12346", e12346(Coefficient(1.5))); showNonzero("e12346 lit", e12346("-2.5"))
  showNonzero("e42356", e42356(Coefficient(1.5))); showNonzero("e42356 lit", e42356("-2.5"))
  showNonzero("e43156", e43156(Coefficient(1.5))); showNonzero("e43156 lit", e43156("-2.5"))
  showNonzero("e41256", e41256(Coefficient(1.5))); showNonzero("e41256 lit", e41256("-2.5"))
  showNonzero("e32156", e32156(Coefficient(1.5))); showNonzero("e32156 lit", e32156("-2.5"))
  showNonzero("e123456", e123456(Coefficient(1.5))); showNonzero("e123456 lit", e123456("-2.5"))
showNonzero("ufcs", Coefficient(0.75).e1)
showNonzero("lit ufcs", "0.375".e2)
showNonzero("lit raw", e12"-0.125")

# Subset of each grade above 2, and subset that importer defines.
type Custom = MultivectorOf[{Basis.S, Basis.E1, Basis.E12}]  ## Subset of mixed grades.

for (name, m) in INPUTS:
  if name[0] != 'r': continue
  when DIMENSIONS >= 3:
    var s3 = default(Multivector3)
    checkSubset("M3" & name, s3, default(MultivectorOdd), m)
  when DIMENSIONS >= 4:
    var s4 = default(Multivector4)
    checkSubset("M4" & name, s4, default(MultivectorEven), m)
  when DIMENSIONS >= 5:
    var s5 = default(Multivector5)
    checkSubset("M5" & name, s5, default(MultivectorOdd), m)
  when DIMENSIONS >= 6:
    var s6 = default(Multivector6)
    checkSubset("M6" & name, s6, default(MultivectorEven), m)
  var custom = default(Custom)
  checkSubset("Custom" & name, custom, default(Multivector), m)

block:
  var line = "sizes"
  when DIMENSIONS >= 3: line.add " " & $(sizeof(Multivector3) div sizeof(Coefficient))
  when DIMENSIONS >= 4: line.add " " & $(sizeof(Multivector4) div sizeof(Coefficient))
  when DIMENSIONS >= 5: line.add " " & $(sizeof(Multivector5) div sizeof(Coefficient))
  when DIMENSIONS >= 6: line.add " " & $(sizeof(Multivector6) div sizeof(Coefficient))
  line.add " " & $(sizeof(Custom) div sizeof(Coefficient))
  echo line

# Comparison near tolerance, which scales with magnitude, in each form.
block:
  var i = 0
  for x in [0.0, 1.0, -1.0, 1000.0, -1e6]:
    for k in [0.5, 0.999, 1.001, 2.0]:
      let n = initElement(Basis.scalar,
        Coefficient(x + k * max(1.0, abs(x)) * float(TOLERANCE_ABS)))
      let s = Coefficient(x)
      var
        a = default(MultivectorScalars)
        c = default(MultivectorScalars)
      a[Basis.scalar] = n[Basis.scalar]
      c[Basis.scalar] = s
      echo "=~ ", i, " ", n =~ s, " ", s =~ n, " ", n =~ initElement(Basis.scalar, s), " ", a =~ c
      i += 1
  for k in [0.5, 0.999, 1.001, 2.0]:
    let
      tiny = Coefficient(k * float(TOLERANCE_ABS))
      big = initElement(Basis.scalar, Coefficient(1e6))
    echo "=~ part ", i, " ", initElement(Basis.scalarAnti, tiny) =~ Coefficient(0.0), " ",
      (big + initElement(Basis.scalar.succ, tiny)) =~ Coefficient(1e6), " ",
      (big + initElement(Basis.scalar.succ, tiny)) =~ big
    i += 1

# Grade of near-zero multivectors.
block:
  let
    tiny = initElement(Basis.scalarAnti, Coefficient(0.5 * float(TOLERANCE_ABS)))
    zero = default(Multivector)
  for (name, m) in [("zero", zero), ("tiny", tiny), ("tiny+e", tiny + initElement(Basis.origin))]:
    echo "grade ", name, " ", (if m.grade.isSome: $int(m.grade.get) else: "none"), " ",
      (if m.gradeAnti.isSome: $int(m.gradeAnti.get) else: "none"), " ", m.isMixed, " ", $m

# Text of special and wide values.
block:
  let inf = Coefficient(1e300) * Coefficient(1e300) * Coefficient(1e300)
  for x in [Coefficient(1.0), Coefficient(-1.0), Coefficient(11.0), Coefficient(0.1),
      Coefficient(1e10), Coefficient(-1e-10), Coefficient(1e11), Coefficient(999999.0),
      Coefficient(1000000.0), Coefficient(999999.5), Coefficient(0.0001), Coefficient(
        0.00012345678,
      ),
      Coefficient(123456789.0), Coefficient(1e30), inf, -inf, inf - inf]:
    var m = default(Multivector)
    for b in Basis: m[b] = x
    echo "$all ", $m
    echo "$one ", $initElement(Basis.origin, x)

# Names that importer must not see.
echo "hidden BasisFlags ", declared(BasisFlags)
echo "hidden countSetBits ", declared(countSetBits)
echo "hidden toBasis ", declared(toBasis)
echo "hidden toBasisDigits ", declared(toBasisDigits)
echo "hidden toBasisFlags ", declared(toBasisFlags)
echo "hidden toDigits ", declared(toDigits)
echo "hidden toFlags ", declared(toFlags)
echo "hidden horizon ", declared(horizon)
echo "hidden constructAlgebra ", declared(constructAlgebra)
echo "hidden BasisDigits ", declared(BasisDigits)
echo "hidden Algebra ", declared(Algebra)
echo "hidden toBasisName ", declared(toBasisName)
echo "hidden applyConstant ", declared(applyConstant)
echo "hidden constructAnti ", declared(constructAnti)
echo "hidden constructComplement ", declared(constructComplement)
echo "hidden constructDual ", declared(constructDual)
echo "hidden constructExomorphismMetric ", declared(constructExomorphismMetric)
echo "hidden constructMetric ", declared(constructMetric)
echo "hidden constructNormsSquared ", declared(constructNormsSquared)
echo "hidden constructParts ", declared(constructParts)
echo "hidden constructProductExterior ", declared(constructProductExterior)
echo "hidden constructProductGeometric ", declared(constructProductGeometric)
echo "hidden constructProductInterior ", declared(constructProductInterior)
echo "hidden constructProductsTransitional ", declared(constructProductsTransitional)
echo "hidden constructReverse ", declared(constructReverse)
echo "hidden filterBases ", declared(filterBases)
echo "hidden filterGrades ", declared(filterGrades)
echo "hidden slice ", declared(slice)
echo "hidden toSigned ", declared(toSigned)
echo "hidden Chirality ", declared(Chirality)
echo "hidden Order ", declared(Order)
echo "hidden Partiality ", declared(Partiality)
echo "hidden Spatiality ", declared(Spatiality)
echo "hidden toBasesSigned ", declared(toBasesSigned)
echo "hidden constructProductTransitional ", declared(constructProductTransitional)
echo "hidden complement ", declared(complement)
echo "hidden multiplyExterior ", declared(multiplyExterior)
echo "hidden filterFactors ", declared(filterFactors)
echo "hidden merge ", declared(merge)
echo "hidden isNegatedFromOrderLexicographic ", declared(isNegatedFromOrderLexicographic)
echo "hidden isNegatedByJoinLexicographic ", declared(isNegatedByJoinLexicographic)
echo "hidden index ", declared(index)
echo "hidden defineBasis ", declared(defineBasis)
echo "hidden defineMultivectors ", declared(defineMultivectors)
echo "hidden defineBasisElementConstructors ", declared(defineBasisElementConstructors)
echo "hidden defineOperator ", declared(defineOperator)
echo "hidden emitEnumBasis ", declared(emitEnumBasis)
echo "hidden borrowOperationsGrade ", declared(borrowOperationsGrade)
echo "hidden emitFunc ", declared(emitFunc)
echo "hidden emitTypeDef ", declared(emitTypeDef)
echo "hidden emitSubscript ", declared(emitSubscript)
echo "hidden emitTerm ", declared(emitTerm)
echo "hidden emitMultivectorOf ", declared(emitMultivectorOf)
echo "hidden generateUpTo ", declared(generateUpTo)
echo "hidden toBinary ", declared(toBinary)
echo "hidden toAlgebra ", declared(toAlgebra)
echo "hidden toBasisNames ", declared(toBasisNames)
echo "hidden BASIS_NAMES ", declared(BASIS_NAMES)
echo "hidden parseFloat ", declared(parseFloat)
echo "hidden formatSigned ", declared(formatSigned)
echo "hidden constructLutKvector ", declared(constructLutKvector)
echo "hidden constructVectorParity ", declared(constructVectorParity)
echo "hidden sqrt ", declared(sqrt)
echo "hidden binom ", declared(binom)
echo "hidden mapIt ", declared(mapIt)
echo "hidden concat ", declared(concat)
echo "hidden Rune ", declared(Rune)
echo "hidden replace ", declared(replace)
echo "hidden pow ", declared(pow)
echo "hidden lut_grade_by_basis ", declared(lut_grade_by_basis)
echo "hidden bases_up_to ", declared(bases_up_to)
echo "hidden checked ", declared(checked)
```
